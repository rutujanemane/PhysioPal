import SwiftUI

struct EscalationView: View {
    @StateObject private var viewModel = EscalationViewModel()
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 20)

                    heroSection
                    messageSection
                    actionButtons

                    if viewModel.callState == .connected {
                        connectedConfirmation
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
    }

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.secondary.opacity(0.12))
                    .frame(width: 120, height: 120)

                Image(systemName: "person.2.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppColors.secondary)
                    .symbolEffect(.pulse, options: .repeating.speed(0.3))
            }
        }
    }

    private var messageSection: some View {
        VStack(spacing: 12) {
            Text("Let's get some help")
                .font(AppFonts.title)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text("It looks like you could use a hand with this exercise. Your physiotherapist can guide you through it — no worries at all.")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

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

            Button {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
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
    }

    private var connectedConfirmation: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(AppColors.success)

            Text("Call placed — your physiotherapist should ring shortly.")
                .font(AppFonts.bodyBold)
                .foregroundStyle(AppColors.success)
        }
        .padding(AppLayout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .fill(AppColors.success.opacity(0.1))
        )
        .transition(.scale.combined(with: .opacity))
    }

    private var callButtonLabel: String {
        switch viewModel.callState {
        case .idle: return "Call My Physiotherapist"
        case .calling: return "Connecting..."
        case .connected: return "Call Placed"
        case .failed: return "Try Again"
        }
    }
}
