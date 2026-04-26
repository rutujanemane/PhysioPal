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
        if now < repDetectionResumeAt {
            highlightedJoints = []
            feedbackMessage = nil
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
        let hipY = hips.map(\.position.y).reduce(0, +) / CGFloat(hips.count)
        let shoulderY = shoulders.map(\.position.y).reduce(0, +) / CGFloat(shoulders.count)

        defer {
            lastHipCenterY = hipY
            lastHipTimestamp = now
        }

        guard let previousHipY = lastHipCenterY, let previousTimestamp = lastHipTimestamp else {
            return
        }

        let deltaTime = now - previousTimestamp
        let deltaY = hipY - previousHipY
        let suddenDrop = deltaTime > 0.05 && deltaTime < 0.45 && deltaY > 0.18
        let lowPosture = hipY > 0.76 && shoulderY > 0.56
        guard suddenDrop && lowPosture else { return }

        fallRiskDetected = true
        feedbackMessage = "It looks like you may need support. Let's get help."
        VoiceGuidanceService.shared.speak("It looks like you may need support. Let's get help.")
        fallCooldownUntil = now + 8
    }

    private func registerRep(for idx: Int) {
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
    }
}
