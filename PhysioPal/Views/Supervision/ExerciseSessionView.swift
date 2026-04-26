import AVFoundation
import SwiftUI
import Combine

struct ExerciseSessionView: View {
    let routine: ExerciseRoutine
    let onComplete: (SessionSummary) -> Void
    let onEscalate: (SessionSummary, Int) -> Void
    let onBack: () -> Void

    @StateObject private var viewModel: SupervisionViewModel
    @StateObject private var recorder = SessionVideoRecorder()
    @State private var captureSession = AVCaptureSession()
    @State private var previewSessionToken: Int = 0
    @State private var repScale: CGFloat = 1.0
    @State private var hasExited = false
    @State private var showCameraPreview = true
    @State private var shouldRecordVideos = false
    @State private var recordingExerciseIndex: Int?
    @State private var lastKnownExerciseIndex = 0

    init(
        routine: ExerciseRoutine,
        onComplete: @escaping (SessionSummary) -> Void,
        onEscalate: @escaping (SessionSummary, Int) -> Void,
        onBack: @escaping () -> Void
    ) {
        self.routine = routine
        self.onComplete = onComplete
        self.onEscalate = onEscalate
        self.onBack = onBack
        _viewModel = StateObject(
            wrappedValue: SupervisionViewModel(routine: routine)
        )
    }

    var body: some View {
        let cameraSession = viewModel.previewSession ?? captureSession
        ZStack {
            Group {
                if showCameraPreview {
                    CameraPreviewView(session: cameraSession)
                        .id(previewSessionToken)
                } else {
                    Color.black
                }
            }
            .ignoresSafeArea()

            PoseOverlayView(
                frame: viewModel.currentPoseFrame,
                highlightedJoints: viewModel.highlightedJoints
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                LinearGradient(
                    colors: [.black.opacity(0.5), .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 120)
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.6)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 260)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        endSession(exit: .back)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                            Text("Back")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 44)
                        .background(.ultraThinMaterial, in: Capsule())
                    }
                    .accessibilityLabel("Back to previous screen")

                    Spacer()

                    if let current = viewModel.currentExercise {
                        Text(current.exercise.name)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .padding(.horizontal, 16)
                            .frame(height: 44)
                            .background(.ultraThinMaterial, in: Capsule())
                    }

                    Spacer()

                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        viewModel.toggleCameraPosition()
                        previewSessionToken += 1
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("Switch camera")
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                FeedbackOverlayView(message: viewModel.feedbackMessage)
                    .padding(.top, 12)

                Spacer()

                VStack(spacing: 14) {
                    Text(currentExerciseRepDisplay)
                        .font(AppFonts.repCounter)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.4), radius: 6, y: 2)
                        .scaleEffect(repScale)
                        .onChange(of: viewModel.repPulseToken) { _ in
                            withAnimation(.interpolatingSpring(stiffness: 200, damping: 15)) {
                                repScale = 1.18
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    repScale = 1.0
                                }
                            }
                        }

                    if let current = viewModel.currentExercise {
                        Text("\(current.completedReps) of \(current.targetReps) reps")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    VStack(spacing: 10) {
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            endSession(exit: .manualStop)
                        } label: {
                            Text("Stop Session")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: AppLayout.buttonHeight)
                                .background(AppColors.secondary, in: RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                        }
                        .accessibilityLabel("Stop exercise session")

                        HStack(spacing: 10) {
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                shouldRecordVideos.toggle()
                                if shouldRecordVideos {
                                    startCurrentExerciseRecordingIfNeeded()
                                } else {
                                    stopAndSaveCurrentRecording()
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: shouldRecordVideos ? "record.circle.fill" : "record.circle")
                                        .font(.system(size: 20, weight: .semibold))
                                    Text(shouldRecordVideos ? "Recording" : "Record")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                }
                                .foregroundStyle(shouldRecordVideos ? AppColors.secondary : .white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                            }
                            .accessibilityLabel(shouldRecordVideos ? "Stop recording" : "Start recording")

                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                viewModel.triggerFallRiskForDemo()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "cross.case.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                    Text("I Need Help")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(AppColors.secondary.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
                            }
                            .accessibilityLabel("I need help — call physiotherapist")
                        }
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            showCameraPreview = true
            viewModel.start()
            lastKnownExerciseIndex = viewModel.currentExerciseIndex
            announceCurrentExercise()
        }
        .onDisappear {
            if !hasExited {
                viewModel.stop()
            }
        }
        .onChange(of: viewModel.currentExerciseIndex) { _ in
            handleExerciseTransition()
            if viewModel.isSessionComplete, viewModel.canSendCompletion() {
                endSession(exit: .complete)
            }
        }
        .onReceive(viewModel.$routineExercises) { _ in
            guard !viewModel.isSessionComplete else { return }
            if viewModel.shouldEscalate() {
                viewModel.markEscalationHandled()
                endSession(exit: .escalation)
            }
        }
        .onReceive(viewModel.$fallRiskDetected) { detected in
            guard detected else { return }
            guard viewModel.consumeFallRiskEvent() else { return }
            endSession(exit: .escalation)
        }
        .onReceive(viewModel.$escalationRequestToken.dropFirst()) { _ in
            endSession(exit: .escalation)
        }
    }

    private enum ExitMode {
        case complete
        case escalation
        case manualStop
        case back
    }

    private func startRecordingIfNeeded() {
        guard !recorder.isRecording else { return }
        let session = viewModel.previewSession ?? captureSession
        recorder.startRecording(session: session)
    }

    private func startCurrentExerciseRecordingIfNeeded() {
        guard shouldRecordVideos else { return }
        guard !viewModel.isSessionComplete else { return }
        guard recordingExerciseIndex == nil else { return }
        guard viewModel.currentExercise != nil else { return }
        let idx = viewModel.currentExerciseIndex
        recordingExerciseIndex = idx
        startRecordingIfNeeded()
    }

    private func stopAndSaveCurrentRecording(
        markShared: Bool = false,
        completion: (() -> Void)? = nil
    ) {
        guard let idx = recordingExerciseIndex else {
            completion?()
            return
        }
        recordingExerciseIndex = nil
        let summary = viewModel.buildSummary()
        let exerciseName = exerciseName(for: idx)
        recorder.stopRecording { url in
            if let url {
                SessionVideoStore.shared.saveVideo(
                    tempURL: url,
                    summary: summary,
                    exerciseName: exerciseName,
                    markShared: markShared
                )
            }
            completion?()
        }
    }

    private func handleExerciseTransition() {
        let newIndex = viewModel.currentExerciseIndex
        let movedForward = newIndex > lastKnownExerciseIndex
        // #region agent log
        DebugProbe.log(
            runId: "pre-fix",
            hypothesisId: "H3_transition_view",
            location: "ExerciseSessionView.handleExerciseTransition",
            message: "transition_observed",
            data: [
                "oldIndex": "\(lastKnownExerciseIndex)",
                "newIndex": "\(newIndex)",
                "movedForward": movedForward ? "true" : "false",
                "recordingEnabled": shouldRecordVideos ? "true" : "false"
            ]
        )
        // #endregion
        lastKnownExerciseIndex = newIndex
        if movedForward {
            announceCurrentExercise()
        }
        if movedForward, shouldRecordVideos, !viewModel.isSessionComplete {
            stopAndSaveCurrentRecording {
                startCurrentExerciseRecordingIfNeeded()
            }
        }
    }

    private func announceCurrentExercise() {
        guard let current = viewModel.currentExercise else { return }
        // #region agent log
        DebugProbe.log(
            runId: "pre-fix",
            hypothesisId: "H4_announce_missing",
            location: "ExerciseSessionView.announceCurrentExercise",
            message: "announce_exercise",
            data: [
                "exerciseIndex": "\(viewModel.currentExerciseIndex)",
                "exerciseName": current.exercise.name,
                "targetReps": "\(current.targetReps)"
            ]
        )
        // #endregion
        VoiceGuidanceService.shared.speak(
            "Now starting \(current.exercise.name). Begin at zero of \(current.targetReps) reps."
        )
    }

    private func exerciseName(for index: Int) -> String? {
        guard index >= 0, index < viewModel.routineExercises.count else { return nil }
        return viewModel.routineExercises[index].exercise.name
    }

    private var currentExerciseRepDisplay: String {
        guard let current = viewModel.currentExercise else { return "0/0" }
        return "\(current.completedReps)/\(current.targetReps)"
    }

    private func endSession(exit: ExitMode) {
        guard !hasExited else { return }
        hasExited = true
        let summary = viewModel.buildSummary()
        let markShared = exit == .escalation
        let finalize: () -> Void = {
            showCameraPreview = false
            var sharedCount = 0
            if exit == .escalation {
                sharedCount = SessionVideoStore.shared.markVideosShared(forSessionStartTime: summary.startTime)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                viewModel.stop()
                switch exit {
                case .complete, .manualStop:
                    onComplete(summary)
                case .escalation:
                    onEscalate(summary, sharedCount)
                case .back:
                    onBack()
                }
            }
        }

        if shouldRecordVideos {
            stopAndSaveCurrentRecording(markShared: markShared) {
                finalize()
            }
        } else {
            finalize()
        }
    }

}
