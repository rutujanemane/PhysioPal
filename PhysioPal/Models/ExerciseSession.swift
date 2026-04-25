import Foundation

struct ExerciseSession: Identifiable {
    let id: UUID
    let date: Date
    let exercises: [CompletedExercise]
    let totalDuration: TimeInterval
    let overallAccuracy: Double
    let readinessLevel: ReadinessLevel

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    var formattedDuration: String {
        let minutes = Int(totalDuration) / 60
        let seconds = Int(totalDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var totalReps: Int { exercises.reduce(0) { $0 + $1.completedReps } }

    static func from(summary: SessionSummary, readiness: HealthReadiness) -> ExerciseSession {
        ExerciseSession(
            id: UUID(),
            date: summary.startTime,
            exercises: summary.exercises.map { exercise in
                CompletedExercise(
                    id: UUID(),
                    exerciseName: exercise.exercise.name,
                    iconName: exercise.exercise.iconName,
                    targetReps: exercise.targetReps,
                    completedReps: exercise.completedReps,
                    correctFormReps: exercise.correctFormReps
                )
            },
            totalDuration: summary.totalDuration,
            overallAccuracy: summary.overallAccuracy,
            readinessLevel: readiness.level
        )
    }
}

struct CompletedExercise: Identifiable {
    let id: UUID
    let exerciseName: String
    let iconName: String
    let targetReps: Int
    let completedReps: Int
    let correctFormReps: Int

    var formAccuracy: Double {
        guard completedReps > 0 else { return 0 }
        return Double(correctFormReps) / Double(completedReps) * 100
    }
}
