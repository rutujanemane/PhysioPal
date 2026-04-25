import Combine
import Foundation
import SwiftUI

@MainActor
final class ContextEngineViewModel: ObservableObject {
    @Published var readiness: HealthReadiness?
    @Published var routine: ExerciseRoutine?
    @Published var isLoading = false
    @Published var hasCompleted = false

    private let healthKit = HealthKitManager.shared

    func loadHealthAndBuildRoutine() async {
        isLoading = true

        let assessment = await healthKit.assessReadiness()
        readiness = assessment

        routine = buildRoutine(for: assessment)

        withAnimation(.easeInOut(duration: AppAnimation.screenTransition)) {
            isLoading = false
            hasCompleted = true
        }
    }

    private func buildRoutine(for readiness: HealthReadiness) -> ExerciseRoutine {
        let shouldReduce = readiness.level.shouldReduceRoutine
        var routineExercises: [RoutineExercise] = []

        for baseExercise in Exercise.library {
            let exercise: Exercise
            let reps: Int

            if shouldReduce, let variantID = baseExercise.easierVariantID,
               let variant = Exercise.find(byID: variantID) {
                exercise = variant
                reps = variant.reducedReps
            } else if shouldReduce {
                exercise = baseExercise
                reps = baseExercise.reducedReps
            } else {
                exercise = baseExercise
                reps = baseExercise.standardReps
            }

            routineExercises.append(
                RoutineExercise(exercise: exercise, targetReps: reps)
            )
        }

        return ExerciseRoutine(
            exercises: routineExercises,
            isReduced: shouldReduce,
            readinessReason: readiness.explanation
        )
    }
}
