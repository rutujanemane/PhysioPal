import AVFoundation
import SwiftUI
import Combine

struct ExerciseSessionView: View {
    let routine: ExerciseRoutine
    let onComplete: (SessionSummary) -> Void
    let onEscalate: () -> Void

    @StateObject private var viewModel: SupervisionViewModel
    @State private var captureSession = AVCaptureSession()
    @State private var activePreviewSession: AVCaptureSession?
    @State private var previewSessionToken: Int = 0
    @State private var repScale: CGFloat = 1.0

    init(
        routine: ExerciseRoutine,
        onComplete: @escaping (SessionSummary) -> Void,
        onEscalate: @escaping () -> Void
    ) {
        self.routine = routine
        self.onComplete = onComplete
        self.onEscalate = onEscalate
        _viewModel = StateObject(
            wrappedValue: SupervisionViewModel(routine: routine)
        )
    }

    var body: some View {
        GeometryReader { geo in
            let cameraSession = activePreviewSession ?? viewModel.previewSession ?? captureSession
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(spacing: 16) {
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
                        Text("\(viewModel.overallRepCount)")
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
                    .padding(.horizontal, AppLayout.screenPadding)
                    .padding(.top, 12)

                    HStack(spacing: 10) {
                        Button {
                            viewModel.switchPoseSourceForTesting(.melange)
                            activePreviewSession = viewModel.previewSession ?? captureSession
                            previewSessionToken += 1
                        } label: {
                            Text("Melange")
                                .font(AppFonts.bodyBold)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(viewModel.activePoseSource == .melange ? AppColors.primary : AppColors.textPrimary.opacity(0.2))
                                )
                                .foregroundStyle(.white)
                        }

                        Button {
                            viewModel.switchPoseSourceForTesting(.vision)
                            activePreviewSession = viewModel.previewSession ?? captureSession
                            previewSessionToken += 1
                        } label: {
                            Text("Vision")
                                .font(AppFonts.bodyBold)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(viewModel.activePoseSource == .vision ? AppColors.primary : AppColors.textPrimary.opacity(0.2))
                                )
                                .foregroundStyle(.white)
                        }
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
            if activePreviewSession == nil {
                activePreviewSession = viewModel.previewSession ?? captureSession
                previewSessionToken += 1
            }
            if viewModel.previewSession == nil {
                configureCaptureSessionIfPossible()
            }
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
            if viewModel.previewSession == nil {
                DispatchQueue.global(qos: .userInitiated).async {
                    captureSession.stopRunning()
                }
            }
        }
        .onChange(of: viewModel.currentExerciseIndex) { _ in
            if viewModel.isSessionComplete, viewModel.canSendCompletion() {
                onComplete(viewModel.buildSummary())
            }
        }
        .onReceive(viewModel.$routineExercises) { _ in
            guard !viewModel.isSessionComplete else { return }
            if viewModel.shouldEscalate() {
                viewModel.markEscalationHandled()
                onEscalate()
            }
        }
    }

    private func configureCaptureSessionIfPossible() {
        #if targetEnvironment(simulator)
        // Keep simulator path simple; we still render overlays over a neutral camera layer.
        #else
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera),
              captureSession.canAddInput(input) else { return }
        captureSession.beginConfiguration()
        captureSession.addInput(input)
        captureSession.commitConfiguration()
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
        #endif
    }
}
