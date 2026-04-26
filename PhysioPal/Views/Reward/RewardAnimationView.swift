import SwiftUI
import AVKit

struct RewardAnimationView: View {
    let summary: SessionSummary
    let onDone: () -> Void

    @StateObject private var viewModel: RewardViewModel
    @ObservedObject private var videoStore = SessionVideoStore.shared
    @State private var animate = false
    @State private var showVideoPlayer = false
    @State private var showSharedToast = false
    @State private var showDeleteConfirm = false

    init(summary: SessionSummary, onDone: @escaping () -> Void) {
        self.summary = summary
        self.onDone = onDone
        _viewModel = StateObject(wrappedValue: RewardViewModel(summary: summary))
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    HStack(spacing: 14) {
                        ForEach(0..<5, id: \.self) { idx in
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundStyle(AppColors.primary.opacity(0.6))
                                .rotationEffect(.degrees(animate ? (idx.isMultiple(of: 2) ? 5 : -5) : 0))
                                .scaleEffect(animate ? 1.03 : 0.97)
                                .animation(
                                    .interpolatingSpring(stiffness: AppAnimation.springStiffness, damping: AppAnimation.springDamping)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(idx) * 0.05),
                                    value: animate
                                )
                        }
                    }
                    .padding(.bottom, 220)

                    ExerciseSummaryView(viewModel: viewModel)
                }

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onDone()
                } label: {
                    Text("Back to Home")
                        .font(AppFonts.button)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppLayout.buttonHeight)
                        .background(AppColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                }
                .padding(.horizontal, AppLayout.screenPadding)

                if videoStore.latestVideo != nil {
                    Button {
                        showVideoPlayer = true
                    } label: {
                        Text("View My Session Video")
                            .font(AppFonts.button)
                            .foregroundStyle(AppColors.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: AppLayout.buttonHeight)
                            .background(
                                RoundedRectangle(cornerRadius: AppLayout.buttonRadius)
                                    .stroke(AppColors.primary, lineWidth: 2)
                            )
                    }
                    .padding(.horizontal, AppLayout.screenPadding)

                    Button {
                        SessionVideoStore.shared.markLatestSessionVideosAsShared()
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showSharedToast = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showSharedToast = false
                            }
                        }
                    } label: {
                        Text("Send Video to Physiotherapist")
                            .font(AppFonts.button)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: AppLayout.buttonHeight)
                            .background(AppColors.success)
                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                    }
                    .padding(.horizontal, AppLayout.screenPadding)

                    Button {
                        SessionVideoStore.shared.unshareLatestSessionVideos()
                    } label: {
                        Text("Unshare Latest Video")
                            .font(AppFonts.button)
                            .foregroundStyle(AppColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: AppLayout.buttonHeight)
                            .background(
                                RoundedRectangle(cornerRadius: AppLayout.buttonRadius)
                                    .fill(AppColors.surface)
                            )
                    }
                    .padding(.horizontal, AppLayout.screenPadding)

                    Button {
                        showDeleteConfirm = true
                    } label: {
                        Text("Delete Latest Video")
                            .font(AppFonts.button)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: AppLayout.buttonHeight)
                            .background(AppColors.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                    }
                    .padding(.horizontal, AppLayout.screenPadding)
                }
            }
            .padding(.top, 40)

            if showSharedToast {
                Text("Video shared with physiotherapist")
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(AppColors.success)
                    )
                    .padding(.top, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .onAppear { animate = true }
        .sheet(isPresented: $showVideoPlayer) {
            if let url = videoStore.latestVideo?.fileURL {
                VideoPlayer(player: AVPlayer(url: url))
                    .ignoresSafeArea()
            }
        }
        .alert("Delete latest video?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                SessionVideoStore.shared.deleteLatestSessionVideos()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently remove the latest session video from this device.")
        }
    }
}
