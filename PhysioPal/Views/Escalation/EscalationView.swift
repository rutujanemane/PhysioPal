import SwiftUI
import AVKit

struct EscalationView: View {
    @StateObject private var viewModel = EscalationViewModel()
    @ObservedObject private var videoStore = SessionVideoStore.shared
    let onDismiss: () -> Void

    @State private var appeared = false
    @State private var showVideoPlayer = false
    @State private var showSharedToast = false
    @State private var showDeleteConfirm = false
    @State private var startedAutoCall = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 20)

                    heroSection
                    messageSection

                    if viewModel.callState == .ptResponded, let action = viewModel.ptAction {
                        ptResponseCard(action: action)
                    } else if viewModel.callState == .connected || viewModel.callState == .ringing {
                        waitingForPTCard
                    } else if viewModel.callState == .completed {
                        callCompletedCard
                    } else {
                        actionButtons
                    }

                    if videoStore.latestVideo != nil {
                        videoActionsCard
                    }

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, AppLayout.screenPadding)
            }
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.95)
            .onAppear {
                withAnimation(.easeOut(duration: AppAnimation.screenTransition)) {
                    appeared = true
                }
                guard !startedAutoCall else { return }
                startedAutoCall = true
                Task {
                    await viewModel.callPhysiotherapist(
                        contextMessage: "Urgent incident detected. Please check incidents of the patient."
                    )
                }
            }
        }
        .alert("Couldn't connect the call", isPresented: $viewModel.showError) {
            Button("Try Again") {
                Task { await viewModel.callPhysiotherapist() }
            }
            Button("Go Back", role: .cancel) {
                onDismiss()
            }
        } message: {
            Text("Don't worry — you can also try the video call option. \(viewModel.errorMessage)")
        }
        .alert("Delete latest video?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                SessionVideoStore.shared.deleteLatestSessionVideos()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently remove the latest session video from this device.")
        }
        .sheet(isPresented: $showVideoPlayer) {
            if let url = videoStore.latestVideo?.fileURL {
                VideoPlayer(player: AVPlayer(url: url))
                    .ignoresSafeArea()
            }
        }
        .overlay(alignment: .top) {
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
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(heroColor.opacity(0.12))
                    .frame(width: 120, height: 120)

                Image(systemName: heroIcon)
                    .font(.system(size: 48))
                    .foregroundStyle(heroColor)
                    .symbolEffect(.pulse, options: .repeating.speed(0.3))
            }
        }
    }

    private var heroColor: Color {
        switch viewModel.callState {
        case .ptResponded: return AppColors.success
        case .connected, .ringing: return AppColors.primary
        case .completed: return AppColors.accent
        default: return AppColors.secondary
        }
    }

    private var heroIcon: String {
        switch viewModel.callState {
        case .ptResponded: return viewModel.ptAction?.icon ?? "checkmark.circle.fill"
        case .connected, .ringing: return "phone.connection.fill"
        case .completed: return "checkmark.circle.fill"
        default: return "person.2.fill"
        }
    }

    // MARK: - Message

    private var messageSection: some View {
        VStack(spacing: 12) {
            Text(titleText)
                .font(AppFonts.title)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(subtitleText)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var titleText: String {
        switch viewModel.callState {
        case .ptResponded: return "Your physiotherapist responded"
        case .connected, .ringing: return "Calling your physiotherapist..."
        case .completed: return "Call completed"
        case .calling: return "Placing your call..."
        default: return "Let's get some help"
        }
    }

    private var subtitleText: String {
        switch viewModel.callState {
        case .ptResponded:
            return viewModel.ptAction?.displayMessage ?? ""
        case .ringing:
            return "Their phone is ringing — hang tight."
        case .connected:
            return "The call has been placed. Waiting for a response..."
        case .completed:
            return "Your physiotherapist has been notified. They may call you back."
        case .calling:
            return "Just a moment..."
        default:
            return "It looks like you could use a hand with this exercise. Your physiotherapist can guide you through it — no worries at all."
        }
    }

    // MARK: - PT Response Card

    private func ptResponseCard(action: PTAction) -> some View {
        VStack(spacing: 20) {
            HStack(spacing: 14) {
                Image(systemName: action.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(actionColor(action))

                VStack(alignment: .leading, spacing: 4) {
                    Text(actionTitle(action))
                        .font(AppFonts.bodyBold)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(action.displayMessage)
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(AppLayout.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                    .fill(actionColor(action).opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                    .stroke(actionColor(action).opacity(0.2), lineWidth: 1.5)
            )

            if action == .videocall, viewModel.meetingURL != nil {
                Button {
                    viewModel.joinMeeting()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 22))
                        Text("Join Video Call")
                            .font(AppFonts.button)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppLayout.buttonHeight)
                    .background(AppColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                    .shadow(color: AppColors.primary.opacity(0.3), radius: 8, y: 4)
                }
                .accessibilityLabel("Join video call with your physiotherapist")
            }

            goBackButton
        }
        .transition(.scale.combined(with: .opacity))
    }

    private func actionColor(_ action: PTAction) -> Color {
        switch action {
        case .callback: return AppColors.primary
        case .encouragement: return AppColors.accent
        case .videocall: return AppColors.primary
        case .dismissed: return AppColors.success
        case .unknown: return AppColors.textSecondary
        }
    }

    private func actionTitle(_ action: PTAction) -> String {
        switch action {
        case .callback: return "Callback coming"
        case .encouragement: return "Encouragement received"
        case .videocall: return "Video call ready"
        case .dismissed: return "Alert acknowledged"
        case .unknown: return "Reached"
        }
    }

    // MARK: - Waiting Card

    private var waitingForPTCard: some View {
        VStack(spacing: 20) {
            HStack(spacing: 14) {
                ProgressView()
                    .tint(AppColors.primary)
                    .scaleEffect(1.2)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Waiting for response...")
                        .font(AppFonts.bodyBold)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("Your physiotherapist can press a key to respond.")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()
            }
            .padding(AppLayout.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                    .fill(AppColors.primary.opacity(0.06))
            )

            goBackButton
        }
    }

    // MARK: - Call Completed

    private var callCompletedCard: some View {
        VStack(spacing: 20) {
            HStack(spacing: 14) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppColors.success)

                Text("Call completed — your physiotherapist has been notified.")
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.success)
            }
            .padding(AppLayout.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                    .fill(AppColors.success.opacity(0.08))
            )

            goBackButton
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Action Buttons (idle state)

    private var actionButtons: some View {
        VStack(spacing: AppLayout.elementSpacing) {
            Button {
                Task { await viewModel.callPhysiotherapist() }
            } label: {
                HStack(spacing: 12) {
                    if viewModel.callState == .calling {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 22))
                    }
                    Text(callButtonLabel)
                        .font(AppFonts.button)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AppLayout.buttonHeight)
                .background(AppColors.secondary)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                .shadow(color: AppColors.secondary.opacity(0.3), radius: 8, y: 4)
            }
            .disabled(viewModel.callState == .calling)
            .accessibilityLabel("Call your physiotherapist")

            Button {
                viewModel.startVideoCall()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 22))
                    Text("Start Video Call")
                        .font(AppFonts.button)
                }
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity)
                .frame(height: AppLayout.buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: AppLayout.buttonRadius)
                        .stroke(AppColors.primary, lineWidth: 2)
                )
            }
            .accessibilityLabel("Start a video call with your physiotherapist")

            goBackButton
        }
    }

    // MARK: - Shared

    private var goBackButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            viewModel.reset()
            onDismiss()
        } label: {
            Text("Go back to exercises")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: AppLayout.minTouchTarget)
        }
        .accessibilityLabel("Return to your exercise session")
    }

    private var callButtonLabel: String {
        switch viewModel.callState {
        case .idle: return "Call My Physiotherapist"
        case .calling: return "Connecting..."
        case .failed: return "Try Again"
        default: return "Call My Physiotherapist"
        }
    }

    private var videoActionsCard: some View {
        VStack(spacing: AppLayout.elementSpacing) {
            Button {
                showVideoPlayer = true
            } label: {
                Text("View Latest Session Video")
                    .font(AppFonts.button)
                    .foregroundStyle(AppColors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppLayout.buttonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: AppLayout.buttonRadius)
                            .stroke(AppColors.primary, lineWidth: 2)
                    )
            }

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
        }
    }
}
