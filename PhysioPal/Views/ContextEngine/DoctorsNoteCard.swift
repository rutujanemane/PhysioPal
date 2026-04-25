import SwiftUI

struct DoctorsNoteCard: View {
    let readiness: HealthReadiness
    let routine: ExerciseRoutine

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerSection
            Divider().background(AppColors.surface)
            explanationSection
            routineSummarySection
        }
        .padding(AppLayout.cardPadding + 4)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .fill(AppColors.cardWhite)
                .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .stroke(AppColors.surface, lineWidth: 1)
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: AppAnimation.screenTransition)) {
                appeared = true
            }
        }
    }

    private var headerSection: some View {
        HStack(spacing: 14) {
            Image(systemName: readiness.level.iconName)
                .font(.system(size: 32))
                .foregroundStyle(iconColor)
                .symbolEffect(.pulse, options: .repeating.speed(0.5))

            VStack(alignment: .leading, spacing: 4) {
                Text("Today's Note")
                    .font(AppFonts.heading)
                    .foregroundStyle(AppColors.textPrimary)
                Text(readiness.level.displayLabel)
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(iconColor)
            }
        }
    }

    private var explanationSection: some View {
        Text(readiness.explanation)
            .font(AppFonts.doctorsNote)
            .foregroundStyle(AppColors.textPrimary)
            .lineSpacing(8)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var routineSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your routine today")
                .font(AppFonts.bodyBold)
                .foregroundStyle(AppColors.textSecondary)

            ForEach(routine.exercises) { item in
                HStack(spacing: 14) {
                    Image(systemName: item.exercise.iconName)
                        .font(.system(size: AppLayout.iconSize))
                        .foregroundStyle(AppColors.primary)
                        .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.exercise.name)
                            .font(AppFonts.bodyBold)
                            .foregroundStyle(AppColors.textPrimary)
                        Text("\(item.targetReps) reps")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var iconColor: Color {
        switch readiness.level {
        case .normal: return AppColors.success
        case .moderate: return AppColors.accent
        case .low: return AppColors.secondary
        }
    }
}
