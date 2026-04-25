import Combine
import Foundation
import SwiftUI

@MainActor
final class SessionStore: ObservableObject {
    static let shared = SessionStore()

    @Published private(set) var sessions: [ExerciseSession] = []
    @Published private(set) var latestReadiness: HealthReadiness?

    private init() {
        loadMockData()
    }

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

    private func loadMockData() {
        let exerciseNames = [
            ("Chair-Assisted Squats", "chair.fill"),
            ("Standing Leg Raises", "figure.walk"),
            ("Wall Push-Ups", "figure.strengthtraining.functional"),
            ("Deep Squats", "figure.squat")
        ]

        for dayOffset in 1...6 {
            guard let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let sessionDate = Calendar.current.date(bySettingHour: 9, minute: Int.random(in: 0...45), second: 0, of: date)!

            let exerciseCount = Int.random(in: 3...4)
            let selectedExercises = exerciseNames.shuffled().prefix(exerciseCount)
            let accuracy = Double.random(in: 72...96)
            let readinessOptions: [ReadinessLevel] = [.normal, .normal, .moderate, .normal, .low, .normal]

            let exercises = selectedExercises.map { name, icon in
                let target = Int.random(in: 8...15)
                let completed = Int.random(in: (target - 2)...target)
                let correct = Int(Double(completed) * (accuracy / 100.0 + Double.random(in: -0.05...0.05)))
                return CompletedExercise(
                    id: UUID(),
                    exerciseName: name,
                    iconName: icon,
                    targetReps: target,
                    completedReps: completed,
                    correctFormReps: min(max(correct, 0), completed)
                )
            }

            sessions.append(ExerciseSession(
                id: UUID(),
                date: sessionDate,
                exercises: Array(exercises),
                totalDuration: TimeInterval(Int.random(in: 180...360)),
                overallAccuracy: accuracy,
                readinessLevel: readinessOptions[dayOffset - 1]
            ))
        }

        sessions.sort { $0.date > $1.date }
    }
}
