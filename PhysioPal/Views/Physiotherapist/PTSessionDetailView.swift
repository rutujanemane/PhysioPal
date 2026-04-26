import SwiftUI

private enum PTDetailColors {
    static let accent = Color(hex: "3D5A80")
    static let background = Color(hex: "F0F2F5")
    static let cardBackground = Color.white
}

struct PTSessionDetailView: View {
    let session: ExerciseSession

    var body: some View {
        ZStack {
            PTDetailColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Spacer().frame(height: 8)

                    summaryHeader
                    exerciseList
                    overallCard

                    Spacer().frame(height: 24)
                }
                .padding(.horizontal, AppLayout.screenPadding)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(PTDetailColors.accent)
                    Text("Session Details")
                        .font(AppFonts.bodyBold)
                        .foregroundStyle(PTDetailColors.accent)
                }
            }
        }
    }

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.formattedDate)
                        .font(AppFonts.title)
                        .foregroundStyle(AppColors.textPrimary)

                    Text("Session at \(session.formattedTime)")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                VStack(spacing: 4) {
                    Image(systemName: session.readinessLevel.iconName)
                        .font(.system(size: 28))
                        .foregroundStyle(readinessColor)

                    Text(session.readinessLevel.displayLabel)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(readinessColor)
                }
            }

            HStack(spacing: 24) {
                statPill(icon: "clock.fill", value: session.formattedDuration, label: "Duration")
                statPill(icon: "repeat", value: "\(session.totalReps)", label: "Total Reps")
                statPill(icon: "target", value: String(format: "%.0f%%", session.overallAccuracy), label: "Accuracy")
            }
        }
        .padding(AppLayout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .fill(PTDetailColors.cardBackground)
                .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
        )
    }

    private func statPill(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(PTDetailColors.accent)

            Text(value)
                .font(AppFonts.bodyBold)
                .foregroundStyle(AppColors.textPrimary)

            Text(label)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var exerciseList: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "figure.strengthtraining.functional")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(PTDetailColors.accent)
                Text("Exercises")
                    .font(AppFonts.heading)
                    .foregroundStyle(PTDetailColors.accent)
            }

            ForEach(session.exercises) { exercise in
                exerciseRow(exercise)
            }
        }
    }

    private func exerciseRow(_ exercise: CompletedExercise) -> some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(accuracyColor(exercise.formAccuracy))
                .frame(width: 5)
                .padding(.vertical, 12)
                .padding(.leading, 4)

            VStack(spacing: 12) {
                HStack(spacing: 14) {
                    Image(systemName: exercise.iconName)
                        .font(.system(size: AppLayout.iconSize))
                        .foregroundStyle(PTDetailColors.accent)
                        .frame(width: 44, height: 44)
                        .background(PTDetailColors.accent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.exerciseName)
                            .font(AppFonts.bodyBold)
                            .foregroundStyle(AppColors.textPrimary)

                        Text("\(exercise.completedReps)/\(exercise.targetReps) reps completed")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Spacer()

                    Text(String(format: "%.0f%%", exercise.formAccuracy))
                        .font(AppFonts.bodyBold)
                        .foregroundStyle(accuracyColor(exercise.formAccuracy))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(PTDetailColors.background)
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(accuracyColor(exercise.formAccuracy))
                            .frame(width: geo.size.width * exercise.formAccuracy / 100, height: 6)
                    }
                }
                .frame(height: 6)
            }
            .padding(AppLayout.cardPadding)
        }
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .fill(PTDetailColors.cardBackground)
                .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
    }

    private var overallCard: some View {
        HStack(spacing: 14) {
            Image(systemName: session.overallAccuracy >= 85 ? "hand.thumbsup.fill" : "info.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(accuracyColor(session.overallAccuracy))

            VStack(alignment: .leading, spacing: 4) {
                Text(session.overallAccuracy >= 85 ? "Good session" : "Form needs improvement")
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)

                Text(session.overallAccuracy >= 85
                    ? "Patient maintained good form throughout this session."
                    : "Consider reviewing exercise technique at the next appointment.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
            }
        }
        .padding(AppLayout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .fill(accuracyColor(session.overallAccuracy).opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .stroke(accuracyColor(session.overallAccuracy).opacity(0.2), lineWidth: 1)
        )
    }

    private var readinessColor: Color {
        switch session.readinessLevel {
        case .normal: return AppColors.success
        case .moderate: return AppColors.accent
        case .low: return AppColors.secondary
        }
    }

    private func accuracyColor(_ accuracy: Double) -> Color {
        if accuracy >= 85 { return AppColors.success }
        if accuracy >= 70 { return AppColors.accent }
        return AppColors.secondary
    }
}
