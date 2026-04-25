import SwiftUI

struct HomeView: View {
    @State private var showHealthCheck = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    Spacer().frame(height: 20)

                    heroSection
                    featureCards
                    privacyBadge
                    startButton

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, AppLayout.screenPadding)
            }
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: AppAnimation.screenTransition)) {
                    appeared = true
                }
            }
        }
    }

    private var heroSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.walk.motion")
                .font(.system(size: 72))
                .foregroundStyle(AppColors.primary)
                .symbolEffect(.bounce, options: .nonRepeating)

            Text("PhysioPal")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)

            Text("Your recovery companion")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.vertical, 12)
    }

    private var featureCards: some View {
        VStack(spacing: AppLayout.elementSpacing) {
            featureRow(
                icon: "heart.text.clipboard.fill",
                title: "Smart Health Check",
                subtitle: "Adapts your routine based on how you slept and your energy today",
                color: AppColors.secondary
            )
            featureRow(
                icon: "eye.fill",
                title: "Real-Time Guidance",
                subtitle: "Watches your form and gives you gentle corrections as you exercise",
                color: AppColors.primary
            )
            featureRow(
                icon: "lock.shield.fill",
                title: "Completely Private",
                subtitle: "Everything stays on your phone — your camera never connects to the internet",
                color: AppColors.success
            )
        }
    }

    private func featureRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundStyle(color)
                .frame(width: 48, height: 48)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
                Text(subtitle)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
            }

            Spacer()
        }
        .padding(AppLayout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .fill(AppColors.cardWhite)
                .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
        )
    }

    private var privacyBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 20))
                .foregroundStyle(AppColors.success)
            Text("All data stays on your device")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(
            Capsule()
                .fill(AppColors.success.opacity(0.08))
        )
    }

    private var startButton: some View {
        NavigationLink {
            AppFlowView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.system(size: 22))
                Text("Begin Today's Session")
                    .font(AppFonts.button)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: AppLayout.buttonHeight)
            .background(AppColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
            .shadow(color: AppColors.primary.opacity(0.3), radius: 8, y: 4)
        }
        .accessibilityLabel("Begin today's exercise session")
        .simultaneousGesture(TapGesture().onEnded {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        })
    }
}
