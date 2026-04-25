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
    private let evaluator = ExerciseEvaluator()
    private let sessionStartTime = Date()

    private var wasDownPhase = false
    private var lastEvaluationCorrect = true
    private var completionSent = false
    private var repHasViolation = false

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
        // #region agent log
        print("[SupervisionViewModel][H8] start with provider=\(String(describing: type(of: poseProvider)))")
        // #endregion
        poseProvider.start { [weak self] frame in
            Task { @MainActor in
                self?.process(frame: frame)
            }
        }
    }

    func stop() {
        poseProvider.stop()
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
        }
    }

    func shouldEscalate() -> Bool {
        guard let idx = activeExerciseIndex else { return false }
        let should = routineExercises[idx].consecutiveFailures >= HealthThresholds.consecutiveFailuresForEscalation
        if should {
            // #region agent log
            print("[SupervisionViewModel][H7] shouldEscalate=true exerciseIndex=\(idx) failures=\(routineExercises[idx].consecutiveFailures)")
            // #endregion
        }
        return should
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
        guard let idx = activeExerciseIndex else { return }
        let requiredForForm: [JointID] = [.leftShoulder, .leftHip, .leftKnee, .leftAnkle]
        let hasFormJoints = requiredForForm.allSatisfy { frame.landmark(for: $0) != nil }
        currentPoseFrame = frame
        let kneeY = frame.landmark(for: .leftKnee)?.position.y ?? 0.5
        let isDown = kneeY > 0.62

        // Evaluate form only during the active squat/down phase.
        // Standing frames should not count as posture failures.
        if isDown, hasFormJoints {
            let exercise = routineExercises[idx].exercise
            let evaluation = evaluator.evaluate(frame: frame, exercise: exercise)
            highlightedJoints = Set(evaluation.violations.map(\.joint))
            lastEvaluationCorrect = evaluation.isCorrect

            if evaluation.isCorrect {
                feedbackMessage = nil
            } else {
                feedbackMessage = evaluation.violations.first?.rule.correctionMessage
                    ?? "Let's make a small posture adjustment."
                repHasViolation = true
            }
        } else {
            highlightedJoints = []
            feedbackMessage = nil
            if !hasFormJoints {
                lastEvaluationCorrect = true
            }
        }

        if hasFormJoints {
            if isDown {
                wasDownPhase = true
            } else if wasDownPhase {
                wasDownPhase = false
                registerRep(for: idx)
            }
        } else {
            wasDownPhase = false
        }
    }

    private func registerRep(for idx: Int) {
        routineExercises[idx].completedReps += 1
        let needed: [JointID] = [.leftShoulder, .leftHip, .leftKnee, .leftAnkle]
        let available = currentPoseFrame.map { frame in
            needed.filter { frame.landmark(for: $0) != nil }.map(\.rawValue)
        } ?? []
        // #region agent log
        print("[SupervisionViewModel][H7] rep registered exerciseIndex=\(idx) completed=\(routineExercises[idx].completedReps)/\(routineExercises[idx].targetReps) hasViolation=\(repHasViolation) lastEvalCorrect=\(lastEvaluationCorrect) requiredJointsPresent=\(available)")
        // #endregion
        if !repHasViolation && lastEvaluationCorrect {
            routineExercises[idx].correctFormReps += 1
            routineExercises[idx].consecutiveFailures = 0
            repPulseToken += 1
        } else {
            routineExercises[idx].consecutiveFailures += 1
        }
        repHasViolation = false

        if routineExercises[idx].isComplete {
            // #region agent log
            print("[SupervisionViewModel][H7] exercise complete index=\(idx) movingTo=\(currentExerciseIndex + 1)")
            // #endregion
            currentExerciseIndex += 1
            highlightedJoints = []
            feedbackMessage = nil
            wasDownPhase = false
            lastEvaluationCorrect = true
            repHasViolation = false
        }
    }
}
