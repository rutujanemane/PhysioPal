import Combine
import Foundation
import SwiftUI

@MainActor
final class SessionStore: ObservableObject {
    static let shared = SessionStore()

    @Published private(set) var sessions: [ExerciseSession] = []
    @Published private(set) var latestReadiness: HealthReadiness?

    private init() { }

    func record(summary: SessionSummary, readiness: HealthReadiness) {
        let session = ExerciseSession.from(summary: summary, readiness: readiness)
        sessions.insert(session, at: 0)
        latestReadiness = readiness
    }

    var totalSessionCount: Int { sessions.count }

    var averageAccuracy: Double {
        guard !sessions.isEmpty else { return 0 }
        return sessions.reduce(0) { $0 + $1.overallAccuracy } / Double(sessions.count)
    }

    var recentSessions: [ExerciseSession] {
        Array(sessions.prefix(7))
    }

    var sessionsThisWeek: Int {
        let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return sessions.filter { $0.date >= startOfWeek }.count
    }

    var accuracyTrend: String {
        guard sessions.count >= 2 else { return "Just getting started" }
        let recent = Array(sessions.prefix(3))
        let older = Array(sessions.dropFirst(3).prefix(3))
        guard !older.isEmpty else { return "Building momentum" }
        let recentAvg = recent.reduce(0) { $0 + $1.overallAccuracy } / Double(recent.count)
        let olderAvg = older.reduce(0) { $0 + $1.overallAccuracy } / Double(older.count)
        if recentAvg > olderAvg + 3 { return "Improving" }
        if recentAvg < olderAvg - 3 { return "Needs attention" }
        return "Steady"
    }

    var trendIcon: String {
        switch accuracyTrend {
        case "Improving": return "arrow.up.right"
        case "Needs attention": return "arrow.down.right"
        case "Steady": return "arrow.right"
        default: return "sparkles"
        }
    }

    var trendColor: Color {
        switch accuracyTrend {
        case "Improving": return AppColors.success
        case "Needs attention": return AppColors.secondary
        default: return AppColors.primary
        }
    }
}
