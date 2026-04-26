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
    private var lastProcessedFrameAt: TimeInterval = 0
    private var lastRepAt: TimeInterval = 0
    private let squatRepDetector = SquatRepDetector()
    private let verticalKneeRepDetector = VerticalKneeHysteresisRepDetector()
    private let targetProcessingInterval: TimeInterval = 1.0 / 15.0
    private let voiceCueCooldown: TimeInterval = 1.8
    private let minRepInterval: TimeInterval = 0.35

    init(routine: ExerciseRoutine, poseProvider: PoseProviderProtocol = TestingPoseProvider(defaultSource: .melange)) {
        self.routineExercises = routine.exercises
        self.poseProvider = poseProvider
        if let switchable = poseProvider as? SwitchablePoseProvider {
            activePoseSource = switchable.activeSource
        }
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
        let kneeY = smoothedFrame.landmark(for: .leftKnee)?.position.y ?? 0.5
        let exercise = routineExercises[idx].exercise
        let useSquatAngleReps = Self.usesSquatStyleRepCounting(exercise)
        let kneeAngle = bestKneeAngleDegrees(from: smoothedFrame)
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

        if poseTrustedForForm {
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
            }
        }

        guard hasFormJoints else { return }

        let repCompleted: Bool = {
            let canUpdateDetector = poseTrustedForForm && (
                isDownForForm ? trustedDownFrameStreak >= 2 : trustedUpFrameStreak >= 2
            )
            guard canUpdateDetector else { return false }
            if useSquatAngleReps, let a = kneeAngle {
                return squatRepDetector.update(kneeAngle: a)
            }
            return verticalKneeRepDetector.update(kneeY: kneeY)
        }()

        if repCompleted {
            guard exerciseIndexAtFrameStart == currentExerciseIndex else { return }
            guard now - lastRepAt >= minRepInterval else { return }
            lastRepAt = now
            registerRep(for: idx)
        }
    }

    private static func usesSquatStyleRepCounting(_ exercise: Exercise) -> Bool {
        exercise.id == "deep-squat" || exercise.id == "chair-squat"
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

    private func meanConfidence(_ frame: PoseFrame, joints: [JointID]) -> Float {
        let vals = joints.compactMap { frame.landmark(for: $0)?.confidence }
        guard !vals.isEmpty else { return 0 }
        return vals.reduce(0, +) / Float(vals.count)
    }

    private func registerRep(for idx: Int) {
        routineExercises[idx].completedReps += 1
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
            currentExerciseIndex += 1
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
            evaluator.reset()
            poseSmoothing.reset()
            escalationLockedExerciseIndex = nil
            isAdvancingExercise = false
        }
    }
}
