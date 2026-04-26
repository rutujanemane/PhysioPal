import AVFoundation
import SwiftUI
import Combine

struct ExerciseSessionView: View {
    let routine: ExerciseRoutine
    let onComplete: (SessionSummary) -> Void
    let onEscalate: () -> Void
    let onBack: () -> Void

    @StateObject private var viewModel: SupervisionViewModel
    @StateObject private var recorder = SessionVideoRecorder()
    @State private var captureSession = AVCaptureSession()
    @State private var previewSessionToken: Int = 0
    @State private var repScale: CGFloat = 1.0
    @State private var hasExited = false
    @State private var shouldRecordVideos = false
    @State private var recordingExerciseIndex: Int?
    @State private var lastKnownExerciseIndex = 0

    init(
        routine: ExerciseRoutine,
        onComplete: @escaping (SessionSummary) -> Void,
        onEscalate: @escaping () -> Void,
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
        GeometryReader { geo in
            let cameraSession = viewModel.previewSession ?? captureSession
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(spacing: 16) {
                    HStack {
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            endSession(exit: .back)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 22, weight: .semibold))
                                Text("Back")
                                    .font(AppFonts.button)
                            }
                            .foregroundStyle(AppColors.primary)
                            .padding(.horizontal, 16)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white)
                                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                            )
                        }
                        .accessibilityLabel("Back to previous screen")

                        Spacer()
                    }
                    .padding(.horizontal, AppLayout.screenPadding)
                    .padding(.top, 12)

                    ZStack(alignment: .top) {
                        CameraPreviewView(session: cameraSession)
                            .id(previewSessionToken)
                            .overlay(AppColors.textPrimary.opacity(0.08))

                        PoseOverlayView(
                            frame: viewModel.currentPoseFrame,
                            highlightedJoints: viewModel.highlightedJoints
                        )

                        FeedbackOverlayView(message: viewModel.feedbackMessage)
                    }
                    .frame(height: geo.size.height * 0.60)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                    .overlay(alignment: .bottomTrailing) {
                        Text(currentExerciseRepDisplay)
                            .font(AppFonts.repCounter)
                            .foregroundStyle(.white)
                            .scaleEffect(repScale)
                            .padding(16)
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
                    }
                    .overlay(alignment: .topTrailing) {
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            viewModel.toggleCameraPosition()
                            previewSessionToken += 1
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                                .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 54, height: 54)
                            .background(Color.black.opacity(0.55))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(12)
                        .accessibilityLabel("Switch camera between front and back")
                    }
                    .padding(.horizontal, AppLayout.screenPadding)
                    .padding(.top, 0)

                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        endSession(exit: .manualStop)
                    } label: {
                        Text("Stop Session")
                            .font(AppFonts.button)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: AppLayout.buttonHeight)
                            .background(AppColors.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                    }
                    .padding(.horizontal, AppLayout.screenPadding)

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        shouldRecordVideos.toggle()
                        if shouldRecordVideos {
                            startCurrentExerciseRecordingIfNeeded()
                        } else {
                            stopAndSaveCurrentRecording()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: shouldRecordVideos ? "record.circle.fill" : "record.circle")
                                .font(.system(size: 22, weight: .semibold))
                            Text(shouldRecordVideos ? "Recording Enabled" : "Record Exercise Videos")
                                .font(AppFonts.button)
                        }
                        .foregroundStyle(shouldRecordVideos ? .white : AppColors.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppLayout.buttonHeight)
                        .background(
                            shouldRecordVideos
                            ? AnyView(RoundedRectangle(cornerRadius: AppLayout.buttonRadius).fill(AppColors.primary))
                            : AnyView(RoundedRectangle(cornerRadius: AppLayout.buttonRadius).stroke(AppColors.primary, lineWidth: 2))
                        )
                    }
                    .padding(.horizontal, AppLayout.screenPadding)

                    VStack(spacing: 8) {
                        Text(viewModel.currentExercise?.exercise.name ?? "Session Complete")
                            .font(AppFonts.heading)
                            .foregroundStyle(AppColors.textPrimary)
                            .multilineTextAlignment(.center)

                        if let current = viewModel.currentExercise {
                            Text("Reps: \(current.completedReps) / \(current.targetReps)")
                                .font(AppFonts.body)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                    .padding(.horizontal, AppLayout.screenPadding)

                    Spacer()
                }
            }
        }
        .onAppear {
            viewModel.start()
            lastKnownExerciseIndex = viewModel.currentExerciseIndex
            announceCurrentExercise()
        }
        .onDisappear {
            viewModel.stop()
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
        if movedForward, shouldRecordVideos {
            stopAndSaveCurrentRecording {
                guard !viewModel.isSessionComplete else { return }
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
        if shouldRecordVideos {
            stopAndSaveCurrentRecording(markShared: false)
        }
        switch exit {
        case .complete, .manualStop:
            onComplete(summary)
        case .escalation:
            onEscalate()
        case .back:
            onBack()
        }
    }

}
