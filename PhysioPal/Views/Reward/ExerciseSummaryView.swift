import SwiftUI

struct ExerciseSummaryView: View {
    @ObservedObject var viewModel: RewardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(viewModel.title)
                .font(AppFonts.title)
                .foregroundStyle(AppColors.textPrimary)

            Text(viewModel.subtitle)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)

            statRow("Total Reps", viewModel.totalRepsText)
            statRow("Form Accuracy", viewModel.accuracyText)
            statRow("Duration", viewModel.durationText)
        }
        .padding(AppLayout.cardPadding)
        .background(AppColors.cardWhite, in: RoundedRectangle(cornerRadius: AppLayout.cardRadius))
        .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
    }

    private func statRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(AppFonts.bodyBold)
                .foregroundStyle(AppColors.textPrimary)
        }
    }
}
