import SwiftUI

struct FeedbackOverlayView: View {
    let message: String?

    var body: some View {
        Group {
            if let message, !message.isEmpty {
                Text(message)
                    .font(AppFonts.feedbackText)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.black.opacity(0.7), in: Capsule())
                    .padding(.top, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: AppAnimation.micro), value: message)
    }
}
