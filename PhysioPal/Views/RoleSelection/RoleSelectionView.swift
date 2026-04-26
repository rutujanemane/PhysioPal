import SwiftUI

struct RoleSelectionView: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                heroSection
                    .padding(.bottom, 44)

                VStack(spacing: 16) {
                    NavigationLink {
                        HomeView()
                    } label: {
                        roleCard(
                            icon: "figure.strengthtraining.traditional",
                            title: "I'm a Patient",
                            subtitle: "Start your exercise session with real-time guidance",
                            accentColor: AppColors.primary
                        )
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    })

                    NavigationLink {
                        PTDashboardView()
                    } label: {
                        roleCard(
                            icon: "stethoscope.circle.fill",
                            title: "I'm a Physiotherapist",
                            subtitle: "View patient health data, exercise history, and progress",
                            accentColor: AppColors.secondary
                        )
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    })
                }
                .padding(.horizontal, AppLayout.screenPadding)

                Spacer()

                privacyBadge
                    .padding(.bottom, 32)
            }
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: AppAnimation.screenTransition)) {
                    appeared = true
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var heroSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary.opacity(0.15), AppColors.primary.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)

                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppColors.primary)
                    .symbolEffect(.bounce, options: .nonRepeating)
            }

            Text("PhysioPal")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)

            Text("Your recovery companion")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private func roleCard(icon: String, title: String, subtitle: String, accentColor: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(accentColor)
                .frame(width: 52, height: 52)
                .background(accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))

            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(accentColor.opacity(0.4))
        }
        .padding(20)
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
        .background(Capsule().fill(AppColors.success.opacity(0.08)))
    }
}
