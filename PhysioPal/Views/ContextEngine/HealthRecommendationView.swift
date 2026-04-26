import SwiftUI

struct HealthRecommendationView: View {
    @ObservedObject var viewModel: ContextEngineViewModel
    let onStartExercise: (ExerciseRoutine) -> Void

    @State private var showContent = false
    @StateObject private var voicePTVM = VoicePTViewModel()

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            if viewModel.isLoading {
                loadingState
            } else if let readiness = viewModel.readiness, let routine = viewModel.routine {
                readyState(readiness: readiness, routine: routine)
            } else if viewModel.readiness != nil && viewModel.routine == nil {
                noRoutineState
            }
        }
        .task {
            await viewModel.loadHealthAndBuildRoutine()
        }
    }

    private var loadingState: some View {
        VStack(spacing: 24) {
            Image(systemName: loadingIcon)
                .font(.system(size: 64))
                .foregroundStyle(AppColors.primary)
                .symbolEffect(.pulse, options: .repeating)

            Text(loadingMessage)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            if case .downloading(let progress) = viewModel.llmStatus {
                VStack(spacing: 8) {
                    ProgressView(value: progress)
                        .tint(AppColors.primary)
                        .frame(maxWidth: 220)

                    Text("Downloading health model... \(Int(progress * 100))%")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .padding(AppLayout.screenPadding)
    }

    private var loadingIcon: String {
        switch viewModel.llmStatus {
        case .analyzing: return "brain"
        case .downloading: return "arrow.down.circle.fill"
        default: return "heart.text.clipboard.fill"
        }
    }

    private var loadingMessage: String {
        switch viewModel.llmStatus {
        case .analyzing: return "Analyzing your health data..."
        case .downloading: return "Preparing your health assistant..."
        default: return "Checking how you're feeling today..."
        }
    }

    private var noRoutineState: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 40)

                Image(systemName: "list.clipboard")
                    .font(.system(size: 72))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.4))

                VStack(spacing: 12) {
                    Text("No Routine Assigned Yet")
                        .font(AppFonts.title)
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Your physiotherapist hasn't created a routine for you yet. Once they assign exercises, they'll appear here.")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                }

                if let readiness = viewModel.readiness {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: readiness.level.iconName)
                                .font(.system(size: 24))
                                .foregroundStyle(readinessColor(readiness.level))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Your Health Today")
                                    .font(AppFonts.bodyBold)
                                    .foregroundStyle(AppColors.textPrimary)
                                Text(readiness.level.displayLabel)
                                    .font(AppFonts.caption)
                                    .foregroundStyle(readinessColor(readiness.level))
                            }
                            Spacer()
                        }

                        Text(readiness.explanation)
                            .font(AppFonts.doctorsNote)
                            .foregroundStyle(AppColors.textPrimary)
                            .lineSpacing(6)
                    }
                    .padding(AppLayout.cardPadding)
                    .background(
                        RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                            .fill(AppColors.cardWhite)
                            .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
                    )
                }

                Spacer()
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

    private func readyState(readiness: HealthReadiness, routine: ExerciseRoutine) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 8)

                greetingSection

                if isLLMInProgress {
                    llmUpdatingBanner
                }

                voiceConversationCard

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

                if let hr = readiness.restingHeartRate {
                    healthStatRow(
                        icon: "heart.fill",
                        label: "Resting heart rate",
                        value: String(format: "%.0f BPM", hr),
                        color: hr > HealthThresholds.elevatedHeartRate ? AppColors.secondary : AppColors.success
                    )
                }

                if let steps = readiness.stepCount {
                    let formatter = NumberFormatter()
                    let _ = formatter.numberStyle = .decimal
                    healthStatRow(
                        icon: "figure.walk",
                        label: "Steps today",
                        value: formatter.string(from: NSNumber(value: Int(steps))) ?? "\(Int(steps))",
                        color: steps < 2000 ? AppColors.secondary : AppColors.success
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

    private var voiceConversationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(AppColors.primary)
                Text("Talk to your digital PT")
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
            }

            if voicePTVM.isAnalyzing {
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(AppColors.primary)
                    Text(voicePTVM.responseText)
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.primary.opacity(0.08))
                )
            } else {
                Text(voicePTVM.responseText)
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineSpacing(6)
            }

            if !voicePTVM.transcript.isEmpty {
                Text("You said: \"\(voicePTVM.transcript)\"")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(4)
            }

            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                voicePTVM.toggleListening()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: voicePTVM.isListening ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 26))
                    Text(voicePTVM.isListening ? "Stop Listening" : "Describe My Pain")
                        .font(AppFonts.button)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AppLayout.buttonHeight)
                .background(voicePTVM.isListening ? AppColors.secondary : AppColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
            }

            if let exerciseID = voicePTVM.suggestedExerciseID,
               let exercise = Exercise.find(byID: exerciseID) {
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    if let customRoutine = viewModel.buildSingleExerciseRoutine(exerciseID: exerciseID) {
                        onStartExercise(customRoutine)
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: exercise.iconName)
                            .font(.system(size: 24))
                        Text("Begin \(exercise.name)")
                            .font(AppFonts.button)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppLayout.buttonHeight)
                    .background(AppColors.success)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                }
                .accessibilityLabel("Begin recommended exercise")
            }
        }
        .padding(AppLayout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .fill(AppColors.cardWhite)
                .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
        )
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

    private func readinessColor(_ level: ReadinessLevel) -> Color {
        switch level {
        case .normal: return AppColors.success
        case .moderate: return AppColors.accent
        case .low: return AppColors.secondary
        }
    }

    private var isLLMInProgress: Bool {
        switch viewModel.llmStatus {
        case .downloading, .analyzing: return true
        case .idle, .done, .fallback: return false
        }
    }

    private var llmUpdatingBanner: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(AppColors.primary)

            Text(llmBannerMessage)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)

            Spacer()
        }
        .padding(AppLayout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .fill(AppColors.primary.opacity(0.08))
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var llmBannerMessage: String {
        switch viewModel.llmStatus {
        case .downloading(let p) where p > 0:
            return "Downloading health model... \(Int(p * 100))%"
        case .analyzing:
            return "Personalizing your routine with AI..."
        default:
            return "Preparing your health assistant..."
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good morning"
        }
    }
}
