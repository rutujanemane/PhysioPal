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
    private let evaluator = ExerciseEvaluator(requiredConsecutiveFrames: 4)
    private let poseSmoothing = PoseSmoothing(windowSize: 5, alpha: 0.4)
    private let sessionStartTime = Date()

    private var lastEvaluationCorrect = true
    private var completionSent = false
    private var repViolationFrames = 0
    private var repTotalDownFrames = 0
    private var repSawTrustedDownFrame = false
    private var lastVoiceCue: String?
    private var escalationLockedExerciseIndex: Int?
    private var trustedDownFrameStreak = 0
    private var trustedUpFrameStreak = 0
    private var lowConfidenceFrameStreak = 0
    private let squatRepDetector = SquatRepDetector()
    private let verticalKneeRepDetector = VerticalKneeHysteresisRepDetector()

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
        guard !isSessionComplete else {
            // #region agent log
            AgentDebugLog.append(
                hypothesisId: "H_esc",
                location: "SupervisionViewModel.shouldEscalate",
                message: "blocked_session_complete",
                data: ["sessionComplete": "true"]
            )
            // #endregion
            return false
        }
        guard let idx = activeExerciseIndex else { return false }
        if escalationLockedExerciseIndex == idx {
            // #region agent log
            AgentDebugLog.append(
                hypothesisId: "H_esc_lock",
                location: "SupervisionViewModel.shouldEscalate",
                message: "blocked_lock_same_exercise",
                data: ["exerciseIndex": "\(idx)"]
            )
            // #endregion
            return false
        }
        let should = routineExercises[idx].consecutiveFailures >= HealthThresholds.consecutiveFailuresForEscalation
        // #region agent log
        AgentDebugLog.append(
            hypothesisId: "H_esc",
            location: "SupervisionViewModel.shouldEscalate",
            message: "check",
            data: [
                "result": should ? "true" : "false",
                "exerciseIndex": "\(idx)",
                "failures": "\(routineExercises[idx].consecutiveFailures)",
                "threshold": "\(HealthThresholds.consecutiveFailuresForEscalation)"
            ]
        )
        if should {
            print("[SupervisionViewModel][H7] shouldEscalate=true exerciseIndex=\(idx) failures=\(routineExercises[idx].consecutiveFailures)")
        }
        // #endregion
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
        let smoothedFrame = poseSmoothing.smooth(frame: frame)
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

        if isDownForForm, poseTrustedForForm {
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
                AgentDebugLog.append(
                    hypothesisId: "H_voice",
                    location: "SupervisionViewModel.process",
                    message: "feedback_violation",
                    data: [
                        "message": msg,
                        "sameAsLastCue": (msg == lastVoiceCue) ? "true" : "false",
                        "violationCount": "\(evaluation.violations.count)"
                    ],
                    runId: "pre-fix"
                )
                if msg != lastVoiceCue {
                    lastVoiceCue = msg
                    AgentDebugLog.append(
                        hypothesisId: "H_voice",
                        location: "SupervisionViewModel.process",
                        message: "voice_speak",
                        data: ["message": msg],
                        runId: "pre-fix"
                    )
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
                // Drop stale detector state after sustained noisy tracking.
                squatRepDetector.reset()
                verticalKneeRepDetector.reset()
            }
        }

        guard hasFormJoints else { return }
        // #region agent log
        AgentDebugLog.append(
            hypothesisId: "H_pose_quality",
            location: "SupervisionViewModel.process",
            message: "frame_gate",
            data: [
                "trusted": poseTrustedForForm ? "true" : "false",
                "confidence": String(format: "%.3f", formConfidence),
                "isDown": isDownForForm ? "true" : "false",
                "exerciseId": exercise.id
            ]
        )
        // #endregion

        let repCompleted: Bool = {
            let canUpdateDetector = poseTrustedForForm && (
                isDownForForm ? trustedDownFrameStreak >= 2 : trustedUpFrameStreak >= 2
            )
            AgentDebugLog.append(
                hypothesisId: "H_rep_gate",
                location: "SupervisionViewModel.process",
                message: "detector_gate",
                data: [
                    "trusted": poseTrustedForForm ? "true" : "false",
                    "canUpdate": canUpdateDetector ? "true" : "false",
                    "downStreak": "\(trustedDownFrameStreak)",
                    "upStreak": "\(trustedUpFrameStreak)",
                    "lowConfidenceStreak": "\(lowConfidenceFrameStreak)"
                ]
            )
            guard canUpdateDetector else { return false }
            if useSquatAngleReps, let a = kneeAngle {
                return squatRepDetector.update(kneeAngle: a)
            }
            return verticalKneeRepDetector.update(kneeY: kneeY)
        }()

        if repCompleted {
            registerRep(for: idx)
        }
    }

    private static func usesSquatStyleRepCounting(_ exercise: Exercise) -> Bool {
        exercise.id == "deep-squat" || exercise.id == "chair-squat"
    }

    /// Prefer the leg side with stronger landmark confidence (workout-buddy picks a visible knee).
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
        let failuresBeforeScoring = routineExercises[idx].consecutiveFailures
        routineExercises[idx].completedReps += 1

        let violationRatio = repTotalDownFrames > 0
            ? Double(repViolationFrames) / Double(repTotalDownFrames)
            : 0.0
        let repHadBadForm = violationRatio > 0.4

        print("[SupervisionViewModel][H7] rep registered exerciseIndex=\(idx) completed=\(routineExercises[idx].completedReps)/\(routineExercises[idx].targetReps) violationRatio=\(String(format: "%.2f", violationRatio)) badForm=\(repHadBadForm)")
        AgentDebugLog.append(
            hypothesisId: "H_rep",
            location: "SupervisionViewModel.registerRep",
            message: "rep_registered",
            data: [
                "exerciseIndex": "\(idx)",
                "exerciseId": routineExercises[idx].exercise.id,
                "completed": "\(routineExercises[idx].completedReps)",
                "target": "\(routineExercises[idx].targetReps)",
                "violationFrames": "\(repViolationFrames)",
                "totalDownFrames": "\(repTotalDownFrames)",
                "violationRatio": String(format: "%.2f", violationRatio),
                "failuresBeforeScoring": "\(failuresBeforeScoring)",
                "exerciseJustFinished": "\(routineExercises[idx].isComplete)"
            ],
            runId: "pre-fix"
        )

        let shouldScoreForm = repSawTrustedDownFrame
        if shouldScoreForm && !repHadBadForm {
            routineExercises[idx].correctFormReps += 1
            routineExercises[idx].consecutiveFailures = 0
            repPulseToken += 1
        } else if shouldScoreForm {
            routineExercises[idx].consecutiveFailures += 1
        }
        AgentDebugLog.append(
            hypothesisId: "H_form_score",
            location: "SupervisionViewModel.registerRep",
            message: "form_scoring",
            data: [
                "shouldScoreForm": shouldScoreForm ? "true" : "false",
                "hadBadForm": repHadBadForm ? "true" : "false",
                "violationRatio": String(format: "%.2f", violationRatio),
                "failuresAfter": "\(routineExercises[idx].consecutiveFailures)"
            ],
            runId: "pre-fix"
        )

        repViolationFrames = 0
        repTotalDownFrames = 0
        repSawTrustedDownFrame = false

        if routineExercises[idx].isComplete {
            // #region agent log
            print("[SupervisionViewModel][H7] exercise complete index=\(idx) movingTo=\(currentExerciseIndex + 1)")
            // #endregion
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
            squatRepDetector.reset()
            verticalKneeRepDetector.reset()
            evaluator.reset()
            poseSmoothing.reset()
            escalationLockedExerciseIndex = nil
        }
    }
}
