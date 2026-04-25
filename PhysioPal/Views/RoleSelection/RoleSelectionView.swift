import SwiftUI

struct RoleSelectionView: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    Spacer().frame(height: 24)

                    heroSection

                    NavigationLink {
                        HomeView()
                    } label: {
                        roleCard(
                            icon: "figure.walk.motion",
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
                            icon: "stethoscope",
                            title: "I'm a Physiotherapist",
                            subtitle: "View patient health data, exercise history, and progress",
                            accentColor: AppColors.secondary
                        )
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    })

                    privacyBadge

                    Spacer().frame(height: 24)
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
        .navigationBarHidden(true)
    }

    private var heroSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.walk.motion")
                .font(.system(size: 64))
                .foregroundStyle(AppColors.primary)
                .symbolEffect(.bounce, options: .nonRepeating)

            Text("PhysioPal")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)

            Text("Your recovery companion")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.bottom, 8)
    }

    private func roleCard(icon: String, title: String, subtitle: String, accentColor: Color) -> some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 72, height: 72)

                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(AppFonts.heading)
                    .foregroundStyle(AppColors.textPrimary)

                Text(subtitle)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(accentColor.opacity(0.5))
        }
        .padding(AppLayout.cardPadding + 4)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .fill(AppColors.cardWhite)
                .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .stroke(accentColor.opacity(0.15), lineWidth: 1.5)
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
