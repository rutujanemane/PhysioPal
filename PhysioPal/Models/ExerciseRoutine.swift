import Foundation

struct ExerciseRoutine: Identifiable {
    let id = UUID()
    let exercises: [RoutineExercise]
    let isReduced: Bool
    let readinessReason: String?
}

struct RoutineExercise: Identifiable {
    let id = UUID()
    let exercise: Exercise
    let targetReps: Int
    var completedReps: Int = 0
    var correctFormReps: Int = 0
    var consecutiveFailures: Int = 0
    var isComplete: Bool { completedReps >= targetReps }

    var formAccuracy: Double {
        guard completedReps > 0 else { return 0 }
        return Double(correctFormReps) / Double(completedReps) * 100
    }
}

struct SessionSummary {
    let exercises: [RoutineExercise]
    let totalDuration: TimeInterval
    let startTime: Date

    var totalReps: Int { exercises.reduce(0) { $0 + $1.completedReps } }
    var totalCorrectReps: Int { exercises.reduce(0) { $0 + $1.correctFormReps } }

    var overallAccuracy: Double {
        guard totalReps > 0 else { return 0 }
        return Double(totalCorrectReps) / Double(totalReps) * 100
    }

    var isPerfect: Bool { overallAccuracy >= 99.9 }

    var formattedDuration: String {
        let minutes = Int(totalDuration) / 60
        let seconds = Int(totalDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
