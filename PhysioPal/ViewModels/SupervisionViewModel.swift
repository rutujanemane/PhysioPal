import Combine
import AVFoundation
import Foundation

@MainActor
final class SupervisionViewModel: ObservableObject {
    @Published private(set) var routineExercises: [RoutineExercise]
    @Published private(set) var currentExerciseIndex: Int = 0
    @Published private(set) var currentPoseFrame: PoseFrame?
    @Published private(set) var highlightedJoints: Set<JointID> = []
    @Published private(set) var feedbackMessage: String?
    @Published private(set) var repPulseToken: Int = 0
    @Published private(set) var activePoseSource: PoseSourceMode = .melange
    @Published private(set) var activeCameraPosition: AVCaptureDevice.Position = .back
    @Published private(set) var fallRiskDetected = false
    @Published private(set) var escalationRequestToken: Int = 0
    @Published private(set) var isSafetyEscalating = false

    private let poseProvider: PoseProviderProtocol
    private let evaluator = ExerciseEvaluator(requiredConsecutiveFrames: 2)
    private let poseSmoothing = PoseSmoothing(alpha: 0.4, windowSize: 5)
    private let sessionStartTime = Date()

    private var lastEvaluationCorrect = true
    private var completionSent = false
    private var repViolationFrames = 0
    private var repTotalDownFrames = 0
    private var repSawTrustedDownFrame = false
    private var lastVoiceCue: String?
    private var lastVoiceCueAt: TimeInterval = 0
    private var escalationLockedExerciseIndex: Int?
    private var trustedDownFrameStreak = 0
    private var trustedUpFrameStreak = 0
    private var lowConfidenceFrameStreak = 0
    private var isAdvancingExercise = false
    private var repDetectionResumeAt: TimeInterval = 0
    private var lastProcessedFrameAt: TimeInterval = 0
    private var lastRepAt: TimeInterval = 0
    private let squatRepDetector = SquatRepDetector()
    private let verticalKneeRepDetector = VerticalKneeHysteresisRepDetector()
    private let armRaiseRepDetector = ArmRaiseRepDetector()
    private let targetProcessingInterval: TimeInterval = 1.0 / 15.0
    private let voiceCueCooldown: TimeInterval = 1.8
    private let minRepInterval: TimeInterval = 0.35
    private let exerciseTransitionPauseNanos: UInt64 = 2_500_000_000
    private var lastHipCenterY: CGFloat?
    private var lastHipTimestamp: TimeInterval?
    private var fallCooldownUntil: TimeInterval = 0
    private var lowPostureStartedAt: TimeInterval?
    private var baselineHipY: CGFloat?
    private var baselineShoulderY: CGFloat?
    private var hipYWindow: [(y: CGFloat, t: TimeInterval)] = []
    private var shoulderYWindow: [(y: CGFloat, t: TimeInterval)] = []
    private let fallWindowDuration: TimeInterval = 0.8
    private var stablePoseFrameStreak = 0
    private var lostStablePoseFrameStreak = 0
    private var trackingDegradeWindowRemaining = 0
    private var preDegradeHipY: CGFloat?
    private var trackingLossConditionStartedAt: TimeInterval?
    private let trackingLossConfirmationSeconds: TimeInterval = 2.5

    init(routine: ExerciseRoutine, poseProvider: PoseProviderProtocol = TestingPoseProvider(defaultSource: .melange)) {
        self.routineExercises = routine.exercises
        self.poseProvider = poseProvider
        if let switchable = poseProvider as? SwitchablePoseProvider {
            activePoseSource = switchable.activeSource
        }
        activeCameraPosition = poseProvider.activeCameraPosition
    }

    var previewSession: AVCaptureSession? {
        poseProvider.previewSession
    }

    var currentExercise: RoutineExercise? {
        guard routineExercises.indices.contains(currentExerciseIndex) else { return nil }
        return routineExercises[currentExerciseIndex]
    }

    var overallRepCount: Int {
        routineExercises.reduce(0) { $0 + $1.completedReps }
    }

    var isSessionComplete: Bool {
        currentExerciseIndex >= routineExercises.count
    }

    func start() {
        repDetectionResumeAt = Date().timeIntervalSince1970 + 0.8
        poseProvider.start { [weak self] frame in
            Task { @MainActor in
                self?.process(frame: frame)
            }
        }
    }

    func stop() {
        poseProvider.stop()
        VoiceGuidanceService.shared.stop()
    }

    func switchPoseSourceForTesting(_ source: PoseSourceMode) {
        guard let switchable = poseProvider as? SwitchablePoseProvider else { return }
        switchable.switchSource(to: source)
        activePoseSource = switchable.activeSource
        print("[SupervisionViewModel][H8] switched source to \(activePoseSource.rawValue)")
    }

    func toggleCameraPosition() {
        let next: AVCaptureDevice.Position = activeCameraPosition == .back ? .front : .back
        poseProvider.switchCamera(position: next)
        activeCameraPosition = poseProvider.activeCameraPosition
    }

    func markEscalationHandled() {
        if let idx = activeExerciseIndex {
            routineExercises[idx].consecutiveFailures = 0
            escalationLockedExerciseIndex = idx
        }
    }

    func shouldEscalate() -> Bool {
        guard !isSessionComplete else { return false }
        guard let idx = activeExerciseIndex else { return false }
        guard escalationLockedExerciseIndex != idx else { return false }
        return routineExercises[idx].consecutiveFailures >= HealthThresholds.consecutiveFailuresForEscalation
    }

    func consumeFallRiskEvent() -> Bool {
        guard fallRiskDetected else { return false }
        fallRiskDetected = false
        return true
    }

    func triggerFallRiskForDemo() {
        requestImmediateEscalation(
            message: "Let's get help right away.",
            speech: "Let's get help right away."
        )
    }

    func buildSummary() -> SessionSummary {
        SessionSummary(
            exercises: routineExercises,
            totalDuration: Date().timeIntervalSince(sessionStartTime),
            startTime: sessionStartTime
        )
    }

    func canSendCompletion() -> Bool {
        guard isSessionComplete, !completionSent else { return false }
        completionSent = true
        return true
    }

    private var activeExerciseIndex: Int? {
        routineExercises.indices.contains(currentExerciseIndex) ? currentExerciseIndex : nil
    }

    private func process(frame: PoseFrame) {
        guard !isSafetyEscalating else { return }
        guard !isAdvancingExercise else { return }
        let now = Date().timeIntervalSince1970
        if now - lastProcessedFrameAt < targetProcessingInterval {
            return
        }
        lastProcessedFrameAt = now
        let smoothedFrame = poseSmoothing.smooth(frame: frame)
        guard let idx = activeExerciseIndex else { return }
        let exerciseIndexAtFrameStart = idx
        let requiredForForm: [JointID] = [.leftShoulder, .leftHip, .leftKnee, .leftAnkle]
        let hasFormJoints = requiredForForm.allSatisfy { smoothedFrame.landmark(for: $0) != nil }
        let formConfidence = meanConfidence(smoothedFrame, joints: requiredForForm)
        let poseTrustedForForm = hasFormJoints && formConfidence >= 0.35
        currentPoseFrame = smoothedFrame
        let kneeY = bestKneeY(from: smoothedFrame) ?? 0.5
        let exercise = routineExercises[idx].exercise
        let useSquatAngleReps = Self.usesSquatStyleRepCounting(exercise)
        let kneeAngle = bestKneeAngleDegrees(from: smoothedFrame)
        let repConfidence = meanConfidence(
            smoothedFrame,
            joints: [.leftHip, .leftKnee, .leftAnkle, .rightHip, .rightKnee, .rightAnkle]
        )
        let hasRepSignal = kneeAngle != nil || bestKneeY(from: smoothedFrame) != nil
        let poseTrustedForRep = hasRepSignal && repConfidence >= 0.2
        let trackingConfidence = meanConfidence(
            smoothedFrame,
            joints: [.leftShoulder, .rightShoulder, .leftHip, .rightHip, .leftKnee, .rightKnee]
        )
        let hasCoreJoints = [.leftShoulder, .rightShoulder, .leftHip, .rightHip, .leftKnee, .rightKnee]
            .allSatisfy { smoothedFrame.landmark(for: $0) != nil }
        let stablePoseForSafety = hasCoreJoints && trackingConfidence >= 0.35
        if now < repDetectionResumeAt {
            highlightedJoints = []
            feedbackMessage = nil
            return
        }
        updateSafetyEscalationSignals(
            frame: smoothedFrame,
            stablePose: stablePoseForSafety
        )
        if shouldEscalateForTrackingLoss(now: now) {
            requestImmediateEscalation(
                message: "We're having trouble tracking safely. Let's get support.",
                speech: "We're having trouble tracking safely. Let's get support."
            )
            return
        }
        let isDownForForm: Bool = {
            if useSquatAngleReps, let a = kneeAngle {
                return a < 140
            }
            return kneeY > 0.62
        }()
        let shouldEvaluateForm = poseTrustedForForm && (useSquatAngleReps ? isDownForForm : true)

        if shouldEvaluateForm {
            repSawTrustedDownFrame = true
            repTotalDownFrames += 1
            let evaluation = evaluator.evaluate(frame: smoothedFrame, exercise: exercise)
            highlightedJoints = Set(evaluation.violations.map(\.joint))
            lastEvaluationCorrect = evaluation.isCorrect

            if evaluation.isCorrect {
                feedbackMessage = nil
                lastVoiceCue = nil
            } else {
                repViolationFrames += 1
                let msg = evaluation.violations.first?.rule.correctionMessage
                    ?? "Let's make a small posture adjustment."
                let canSpeakCue = msg != lastVoiceCue || (now - lastVoiceCueAt >= voiceCueCooldown)
                if canSpeakCue {
                    lastVoiceCue = msg
                    lastVoiceCueAt = now
                    // #region agent log
                    DebugProbe.log(
                        runId: "pre-fix",
                        hypothesisId: "H1_voice_interrupt",
                        location: "SupervisionViewModel.process",
                        message: "speak_correction",
                        data: [
                            "exerciseIndex": "\(idx)",
                            "exerciseId": exercise.id,
                            "message": msg,
                            "cooldownSec": String(format: "%.2f", voiceCueCooldown)
                        ]
                    )
                    // #endregion
                    VoiceGuidanceService.shared.speak(msg)
                }
                feedbackMessage = msg
            }
        } else {
            highlightedJoints = []
            feedbackMessage = nil
            if !poseTrustedForForm {
                lastEvaluationCorrect = true
            }
        }

        if poseTrustedForRep {
            lowConfidenceFrameStreak = 0
            if isDownForForm {
                trustedDownFrameStreak += 1
                trustedUpFrameStreak = 0
            } else {
                trustedUpFrameStreak += 1
                trustedDownFrameStreak = 0
            }
        } else {
            lowConfidenceFrameStreak += 1
            trustedDownFrameStreak = 0
            trustedUpFrameStreak = 0
            if lowConfidenceFrameStreak >= 5 {
                squatRepDetector.reset()
                verticalKneeRepDetector.reset()
                armRaiseRepDetector.reset()
            }
        }

        let repCompleted: Bool = {
            let canUpdateDetector = poseTrustedForRep && (
                isDownForForm ? trustedDownFrameStreak >= 2 : trustedUpFrameStreak >= 2
            )
            guard canUpdateDetector else { return false }
            if useSquatAngleReps, let a = kneeAngle {
                return squatRepDetector.update(kneeAngle: a)
            }
            if Self.usesArmRaiseRepCounting(exercise),
               let wristY = smoothedFrame.landmark(for: .leftWrist)?.position.y {
                return armRaiseRepDetector.update(wristY: wristY)
            }
            return verticalKneeRepDetector.update(kneeY: kneeY)
        }()

        if repCompleted {
            guard exerciseIndexAtFrameStart == currentExerciseIndex else { return }
            guard now - lastRepAt >= minRepInterval else { return }
            lastRepAt = now
            registerRep(for: idx)
        }
        evaluateFallRisk(frame: smoothedFrame, now: now)
    }

    private func updateSafetyEscalationSignals(frame: PoseFrame, stablePose: Bool) {
        if stablePose {
            stablePoseFrameStreak += 1
            lostStablePoseFrameStreak = 0
            if stablePoseFrameStreak >= 6 {
                trackingDegradeWindowRemaining = 0
                preDegradeHipY = averageHipY(from: frame)
            }
            return
        }

        stablePoseFrameStreak = 0
        lostStablePoseFrameStreak += 1
        if trackingDegradeWindowRemaining == 0 {
            trackingDegradeWindowRemaining = 12
            preDegradeHipY = averageHipY(from: frame)
        } else {
            trackingDegradeWindowRemaining = max(0, trackingDegradeWindowRemaining - 1)
        }
    }

    private func shouldEscalateForTrackingLoss(now: TimeInterval) -> Bool {
        guard !isSessionComplete else { return false }
        guard fallRiskDetected == false else { return false }
        guard let frame = currentPoseFrame else { return false }

        let lostStablePoseTooLong = lostStablePoseFrameStreak >= 14
        let currentHipY = averageHipY(from: frame)
        let rapidTrackingDegradeWithDrop: Bool = {
            guard trackingDegradeWindowRemaining > 0,
                  let before = preDegradeHipY,
                  let current = currentHipY else { return false }
            return (current - before) > 0.10
        }()

        let conditionActive = lostStablePoseTooLong || rapidTrackingDegradeWithDrop
        if conditionActive {
            if trackingLossConditionStartedAt == nil {
                trackingLossConditionStartedAt = now
            }
            let heldFor = now - (trackingLossConditionStartedAt ?? now)
            return heldFor >= trackingLossConfirmationSeconds
        }

        trackingLossConditionStartedAt = nil
        return false
    }

    private func averageHipY(from frame: PoseFrame) -> CGFloat? {
        let hips = [frame.landmark(for: .leftHip), frame.landmark(for: .rightHip)].compactMap { $0 }
        guard !hips.isEmpty else { return nil }
        return hips.map(\.position.y).reduce(0, +) / CGFloat(hips.count)
    }

    private static func usesSquatStyleRepCounting(_ exercise: Exercise) -> Bool {
        ["deep-squat", "chair-squat", "standing-hamstring-curl", "sit-to-stand"].contains(exercise.id)
    }

    private static func usesArmRaiseRepCounting(_ exercise: Exercise) -> Bool {
        exercise.id == "seated-shoulder-flexion"
    }

    private func bestKneeAngleDegrees(from frame: PoseFrame) -> Double? {
        let left = frame.angleBetween(.leftHip, .leftKnee, .leftAnkle)
        let right = frame.angleBetween(.rightHip, .rightKnee, .rightAnkle)
        let lc = meanConfidence(frame, joints: [.leftHip, .leftKnee, .leftAnkle])
        let rc = meanConfidence(frame, joints: [.rightHip, .rightKnee, .rightAnkle])
        switch (left, right) {
        case let (l?, r?):
            return lc >= rc ? l : r
        case let (l?, nil):
            return l
        case let (nil, r?):
            return r
        default:
            return nil
        }
    }

    private func bestKneeY(from frame: PoseFrame) -> CGFloat? {
        let left = frame.landmark(for: .leftKnee)
        let right = frame.landmark(for: .rightKnee)
        switch (left, right) {
        case let (l?, r?):
            return l.confidence >= r.confidence ? l.position.y : r.position.y
        case let (l?, nil):
            return l.position.y
        case let (nil, r?):
            return r.position.y
        default:
            return nil
        }
    }

    private func meanConfidence(_ frame: PoseFrame, joints: [JointID]) -> Float {
        let vals = joints.compactMap { frame.landmark(for: $0)?.confidence }
        guard !vals.isEmpty else { return 0 }
        return vals.reduce(0, +) / Float(vals.count)
    }

    private func evaluateFallRisk(frame: PoseFrame, now: TimeInterval) {
        guard now >= fallCooldownUntil else { return }
        let hips = [frame.landmark(for: .leftHip), frame.landmark(for: .rightHip)].compactMap { $0 }
        let shoulders = [frame.landmark(for: .leftShoulder), frame.landmark(for: .rightShoulder)].compactMap { $0 }
        guard !hips.isEmpty, !shoulders.isEmpty else { return }
        let conf = (hips.map(\.confidence).reduce(0, +) + shoulders.map(\.confidence).reduce(0, +))
            / Float(hips.count + shoulders.count)
        guard conf >= 0.18 else { return }

        let hipY = hips.map(\.position.y).reduce(0, +) / CGFloat(hips.count)
        let shoulderY = shoulders.map(\.position.y).reduce(0, +) / CGFloat(shoulders.count)

        if let baselineHipY {
            self.baselineHipY = baselineHipY * 0.92 + hipY * 0.08
        } else {
            baselineHipY = hipY
        }
        if let baselineShoulderY {
            self.baselineShoulderY = baselineShoulderY * 0.92 + shoulderY * 0.08
        } else {
            baselineShoulderY = shoulderY
        }

        hipYWindow.append((y: hipY, t: now))
        shoulderYWindow.append((y: shoulderY, t: now))
        hipYWindow.removeAll { now - $0.t > fallWindowDuration }
        shoulderYWindow.removeAll { now - $0.t > fallWindowDuration }

        defer {
            lastHipCenterY = hipY
            lastHipTimestamp = now
        }

        guard hipYWindow.count >= 3 else { return }

        // Signal 1: Peak-to-current hip drop over the sliding window
        let peakHipY = hipYWindow.map(\.y).min()!
        let windowHipDrop = hipY - peakHipY
        let peakShoulderY = shoulderYWindow.map(\.y).min()!
        let windowShoulderDrop = shoulderY - peakShoulderY
        let windowSpan = now - hipYWindow.first!.t
        let rapidDrop = windowHipDrop > 0.14 && windowSpan > 0.08 && windowSpan <= fallWindowDuration

        // Signal 2: Coordinated body drop (both hip and shoulder falling together)
        let coordinatedDrop = windowHipDrop > 0.10 && windowShoulderDrop > 0.07

        // Signal 3: Sustained low posture
        let lowPosture = hipY > 0.65 && shoulderY > 0.48
        if lowPosture {
            if lowPostureStartedAt == nil { lowPostureStartedAt = now }
        } else {
            lowPostureStartedAt = nil
        }
        let sustainedLow = (lowPostureStartedAt.map { now - $0 } ?? 0) > 1.0

        // Signal 4: Torso collapse (shoulder-hip gap shrinks, person crumpling)
        let torsoGap = hipY - shoulderY
        let torsoCollapse = torsoGap < 0.06 && hipY > 0.55

        // Signal 5: Frame-to-frame sudden drop (keep as supplementary)
        let frameDrop: Bool = {
            guard let prevY = lastHipCenterY, let prevT = lastHipTimestamp else { return false }
            let dt = now - prevT
            let dy = hipY - prevY
            return dt > 0.04 && dt < 0.5 && dy > 0.15
        }()

        // Signal 6: Strong relative drop from baseline
        let relHipDrop = hipY - (baselineHipY ?? hipY)
        let relShoulderDrop = shoulderY - (baselineShoulderY ?? shoulderY)
        let strongRelativeDrop = relHipDrop > 0.12 && relShoulderDrop > 0.08

        // Trigger: require multiple confirming signals
        let triggered =
            (rapidDrop && (lowPosture || coordinatedDrop || strongRelativeDrop))
            || (frameDrop && (lowPosture || coordinatedDrop))
            || (sustainedLow && (torsoCollapse || coordinatedDrop))
            || (rapidDrop && torsoCollapse)

        guard triggered else { return }

        print("[FallDetection] TRIGGERED — hipDrop=\(String(format: "%.3f", windowHipDrop)) shoulderDrop=\(String(format: "%.3f", windowShoulderDrop)) hipY=\(String(format: "%.3f", hipY)) shoulderY=\(String(format: "%.3f", shoulderY)) torsoGap=\(String(format: "%.3f", torsoGap)) sustainedLow=\(sustainedLow) frameDrop=\(frameDrop)")

        requestImmediateEscalation(
            message: "It looks like you may need support. Let's get help.",
            speech: "It looks like you may need support. Let's get help."
        )
        fallCooldownUntil = now + 8
        lowPostureStartedAt = nil
    }

    private func requestImmediateEscalation(message: String, speech: String) {
        guard !isSafetyEscalating else { return }
        isSafetyEscalating = true
        VoiceGuidanceService.shared.stop()
        fallRiskDetected = true
        feedbackMessage = message
        VoiceGuidanceService.shared.speak(speech)
        escalationRequestToken += 1
    }

    private func registerRep(for idx: Int) {
        guard !isSafetyEscalating else { return }
        routineExercises[idx].completedReps += 1
        // #region agent log
        DebugProbe.log(
            runId: "pre-fix",
            hypothesisId: "H2_transition_timing",
            location: "SupervisionViewModel.registerRep",
            message: "rep_registered",
            data: [
                "exerciseIndex": "\(idx)",
                "exerciseId": routineExercises[idx].exercise.id,
                "completed": "\(routineExercises[idx].completedReps)",
                "target": "\(routineExercises[idx].targetReps)"
            ]
        )
        // #endregion
        VoiceGuidanceService.shared.speak("Nice work. Rep completed.")
        let shouldScoreForm = repSawTrustedDownFrame
        let violationRatio = repTotalDownFrames > 0
            ? Double(repViolationFrames) / Double(repTotalDownFrames)
            : 0
        let shouldMarkViolation = violationRatio > 0.4
        if shouldScoreForm && !shouldMarkViolation && lastEvaluationCorrect {
            routineExercises[idx].correctFormReps += 1
            routineExercises[idx].consecutiveFailures = 0
            repPulseToken += 1
        } else if shouldScoreForm {
            routineExercises[idx].consecutiveFailures += 1
        }
        repViolationFrames = 0
        repTotalDownFrames = 0
        repSawTrustedDownFrame = false

        if routineExercises[idx].isComplete {
            isAdvancingExercise = true
            feedbackMessage = "Great work. Taking a short pause."
            // #region agent log
            DebugProbe.log(
                runId: "pre-fix",
                hypothesisId: "H2_transition_timing",
                location: "SupervisionViewModel.registerRep",
                message: "exercise_complete_pause_start",
                data: [
                    "exerciseIndex": "\(idx)",
                    "nextExerciseIndex": "\(idx + 1)",
                    "pauseSec": "2.5"
                ]
            )
            // #endregion
            VoiceGuidanceService.shared.speak("Great work. Short pause before the next exercise.")
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: exerciseTransitionPauseNanos)
                guard currentExerciseIndex == idx else { return }
                advanceToNextExercise()
            }
        }
    }

    private func advanceToNextExercise() {
        currentExerciseIndex += 1
        repDetectionResumeAt = Date().timeIntervalSince1970 + 1.6
        // #region agent log
        DebugProbe.log(
            runId: "pre-fix",
            hypothesisId: "H2_transition_timing",
            location: "SupervisionViewModel.advanceToNextExercise",
            message: "advanced_to_next",
            data: ["currentExerciseIndex": "\(currentExerciseIndex)"]
        )
        // #endregion
        highlightedJoints = []
        feedbackMessage = nil
        lastEvaluationCorrect = true
        repViolationFrames = 0
        repTotalDownFrames = 0
        repSawTrustedDownFrame = false
        trustedDownFrameStreak = 0
        trustedUpFrameStreak = 0
        lowConfidenceFrameStreak = 0
        lastVoiceCue = nil
        lastVoiceCueAt = 0
        squatRepDetector.reset()
        verticalKneeRepDetector.reset()
        armRaiseRepDetector.reset()
        evaluator.reset()
        poseSmoothing.reset()
        escalationLockedExerciseIndex = nil
        isAdvancingExercise = false
        lastHipCenterY = nil
        lastHipTimestamp = nil
        lowPostureStartedAt = nil
        baselineHipY = nil
        baselineShoulderY = nil
        hipYWindow = []
        shoulderYWindow = []
        stablePoseFrameStreak = 0
        lostStablePoseFrameStreak = 0
        trackingDegradeWindowRemaining = 0
        preDegradeHipY = nil
        trackingLossConditionStartedAt = nil
        isSafetyEscalating = false
    }
}
