import SwiftUI

struct RewardAnimationView: View {
    let summary: SessionSummary
    let onDone: () -> Void

    @StateObject private var viewModel: RewardViewModel
    @State private var animate = false

    init(summary: SessionSummary, onDone: @escaping () -> Void) {
        self.summary = summary
        self.onDone = onDone
        _viewModel = StateObject(wrappedValue: RewardViewModel(summary: summary))
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    HStack(spacing: 14) {
                        ForEach(0..<5, id: \.self) { idx in
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundStyle(AppColors.primary.opacity(0.6))
                                .rotationEffect(.degrees(animate ? (idx.isMultiple(of: 2) ? 5 : -5) : 0))
                                .scaleEffect(animate ? 1.03 : 0.97)
                                .animation(
                                    .interpolatingSpring(stiffness: AppAnimation.springStiffness, damping: AppAnimation.springDamping)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(idx) * 0.05),
                                    value: animate
                                )
                        }
                    }
                    .padding(.bottom, 220)

                    ExerciseSummaryView(viewModel: viewModel)
                }

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onDone()
                } label: {
                    Text("Back to Home")
                        .font(AppFonts.button)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppLayout.buttonHeight)
                        .background(AppColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                }
                .padding(.horizontal, AppLayout.screenPadding)
            }
            .padding(.top, 40)
        }
        .onAppear { animate = true }
    }
}
