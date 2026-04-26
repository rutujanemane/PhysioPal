import SwiftUI

enum AppFlowStep {
    case healthCheck
    case exercise(ExerciseRoutine)
    case reward(SessionSummary)
    case escalation
}

struct AppFlowView: View {
    @StateObject private var contextVM = ContextEngineViewModel()
    @State private var currentStep: AppFlowStep = .healthCheck
    @State private var activeRoutine: ExerciseRoutine?

    var body: some View {
        Group {
            switch currentStep {
            case .healthCheck:
                HealthRecommendationView(viewModel: contextVM) { routine in
                    activeRoutine = routine
                    // #region agent log
                    print("[AppFlowView][H6] transition healthCheck -> exercise")
                    // #endregion
                    withAnimation(.easeInOut(duration: AppAnimation.screenTransition)) {
                        currentStep = .exercise(routine)
                    }
                }

            case .exercise(let routine):
                ExerciseSessionView(
                    routine: routine,
                    onComplete: { summary in
                        // #region agent log
                        print("[AppFlowView][H6] transition exercise -> reward")
                        // #endregion
                        SessionStore.shared.record(
                            summary: summary,
                            readiness: contextVM.readiness ?? .noHealthData
                        )
                        withAnimation(.easeInOut(duration: AppAnimation.screenTransition)) {
                            currentStep = .reward(summary)
                        }
                    },
                    onEscalate: {
                        // #region agent log
                        print("[AppFlowView][H6] transition exercise -> escalation")
                        // #endregion
                        withAnimation(.easeInOut(duration: AppAnimation.screenTransition)) {
                            currentStep = .escalation
                        }
                    },
                    onBack: {
                        withAnimation(.easeInOut(duration: AppAnimation.screenTransition)) {
                            currentStep = .healthCheck
                        }
                    }
                )

            case .reward(let summary):
                RewardAnimationView(summary: summary) {
                    // #region agent log
                    print("[AppFlowView][H6] transition reward -> healthCheck")
                    // #endregion
                    withAnimation(.easeInOut(duration: AppAnimation.screenTransition)) {
                        currentStep = .healthCheck
                    }
                }

            case .escalation:
                EscalationView {
                    // #region agent log
                    print("[AppFlowView][H6] transition escalation -> exercise/healthCheck")
                    // #endregion
                    withAnimation(.easeInOut(duration: AppAnimation.screenTransition)) {
                        if let routine = activeRoutine ?? contextVM.routine {
                            currentStep = .exercise(routine)
                        } else {
                            currentStep = .healthCheck
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if case .healthCheck = currentStep {
                    BackButton()
                }
            }
        }
    }
}

struct BackButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            dismiss()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                Text("Back")
                    .font(AppFonts.bodyBold)
            }
            .foregroundStyle(AppColors.primary)
        }
        .accessibilityLabel("Go back to home screen")
    }
}

// MARK: - Placeholders for Rutuja's screens

struct ExerciseSessionPlaceholder: View {
    let routine: ExerciseRoutine
    let onComplete: (SessionSummary) -> Void
    let onEscalate: () -> Void

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 64))
                    .foregroundStyle(AppColors.primary)

                Text("Exercise Session")
                    .font(AppFonts.title)
                    .foregroundStyle(AppColors.textPrimary)

                Text("Camera supervision will appear here.\nThis screen is assigned to Rutuja.")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: AppLayout.elementSpacing) {
                    Button {
                        let summary = SessionSummary(
                            exercises: routine.exercises,
                            totalDuration: 180,
                            startTime: Date()
                        )
                        onComplete(summary)
                    } label: {
                        Text("Simulate Completion")
                            .font(AppFonts.button)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: AppLayout.buttonHeight)
                            .background(AppColors.success)
                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                    }

                    Button {
                        onEscalate()
                    } label: {
                        Text("Simulate Escalation")
                            .font(AppFonts.button)
                            .foregroundStyle(AppColors.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: AppLayout.buttonHeight)
                            .background(
                                RoundedRectangle(cornerRadius: AppLayout.buttonRadius)
                                    .stroke(AppColors.secondary, lineWidth: 2)
                            )
                    }
                }
                .padding(.horizontal, AppLayout.screenPadding)
            }
            .padding(AppLayout.screenPadding)
        }
    }
}

struct RewardPlaceholder: View {
    let summary: SessionSummary
    let onDone: () -> Void

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(AppColors.accent)

                Text("Session Complete!")
                    .font(AppFonts.title)
                    .foregroundStyle(AppColors.textPrimary)

                Text("Reward animation will appear here.\nThis screen is assigned to Rutuja.")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onDone()
                } label: {
                    Text("Done")
                        .font(AppFonts.button)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppLayout.buttonHeight)
                        .background(AppColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                }
                .padding(.horizontal, AppLayout.screenPadding)
            }
            .padding(AppLayout.screenPadding)
        }
    }
}
