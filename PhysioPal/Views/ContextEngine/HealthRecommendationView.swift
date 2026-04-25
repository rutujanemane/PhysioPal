import SwiftUI

struct HealthRecommendationView: View {
    @ObservedObject var viewModel: ContextEngineViewModel
    let onStartExercise: (ExerciseRoutine) -> Void

    @State private var showContent = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            if viewModel.isLoading {
                loadingState
            } else if let readiness = viewModel.readiness, let routine = viewModel.routine {
                readyState(readiness: readiness, routine: routine)
            }
        }
        .task {
            await viewModel.loadHealthAndBuildRoutine()
        }
    }

    private var loadingState: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.text.clipboard.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppColors.primary)
                .symbolEffect(.pulse, options: .repeating)

            Text("Checking how you're feeling today...")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppLayout.screenPadding)
    }

    private func readyState(readiness: HealthReadiness, routine: ExerciseRoutine) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 8)

                greetingSection

                DoctorsNoteCard(readiness: readiness, routine: routine)

                if let sleep = readiness.sleepHours {
                    healthStatRow(
                        icon: "bed.double.fill",
                        label: "Sleep last night",
                        value: String(format: "%.1f hours", sleep),
                        color: sleep < HealthThresholds.lowSleepHours ? AppColors.secondary : AppColors.success
                    )
                }

                if let energy = readiness.activeEnergyKcal {
                    healthStatRow(
                        icon: "flame.fill",
                        label: "Active energy today",
                        value: String(format: "%.0f kcal", energy),
                        color: energy < HealthThresholds.lowEnergyKcal ? AppColors.secondary : AppColors.success
                    )
                }

                Spacer().frame(height: 8)

                startButton(routine: routine)
            }
            .padding(.horizontal, AppLayout.screenPadding)
        }
        .opacity(showContent ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: AppAnimation.screenTransition).delay(0.2)) {
                showContent = true
            }
        }
    }

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greetingText)
                .font(AppFonts.title)
                .foregroundStyle(AppColors.textPrimary)

            Text("Here's your personalized routine for today.")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func healthStatRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                Text(value)
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
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

    private func startButton(routine: ExerciseRoutine) -> some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onStartExercise(routine)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "figure.run")
                    .font(.system(size: 24))
                Text("Start My Routine")
                    .font(AppFonts.button)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: AppLayout.buttonHeight)
            .background(AppColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
            .shadow(color: AppColors.primary.opacity(0.3), radius: 8, y: 4)
        }
        .accessibilityLabel("Start your exercise routine")
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
}
