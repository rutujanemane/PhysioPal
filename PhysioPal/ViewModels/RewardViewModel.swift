import Combine
import Foundation

@MainActor
final class RewardViewModel: ObservableObject {
    let summary: SessionSummary

    init(summary: SessionSummary) {
        self.summary = summary
    }

    var title: String {
        summary.isPerfect ? "Perfect Form Session!" : "Great Session Complete!"
    }

    var subtitle: String {
        "You are making steady progress with every routine."
    }

    var totalRepsText: String {
        "\(summary.totalReps)"
    }

    var accuracyText: String {
        "\(Int(summary.overallAccuracy.rounded()))%"
    }

    var durationText: String {
        summary.formattedDuration
    }
}
