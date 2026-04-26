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

    private func buildRoutine(for readiness: HealthReadiness) -> ExerciseRoutine? {
        let store = RoutineStore.shared
        guard store.hasAssignedRoutine else { return nil }

        let shouldReduce = readiness.level.shouldReduceRoutine
        var routineExercises: [RoutineExercise] = []
        var addedExerciseIDs = Set<String>()

        for item in store.assignedExercises {
            guard let baseExercise = Exercise.find(byID: item.exerciseID) else { continue }

            let exercise: Exercise
            let reps: Int

            if shouldReduce, let variantID = baseExercise.easierVariantID,
               let variant = Exercise.find(byID: variantID) {
                exercise = variant
                reps = min(item.targetReps, variant.reducedReps)
            } else if shouldReduce {
                exercise = baseExercise
                reps = min(item.targetReps, baseExercise.reducedReps)
            } else {
                exercise = baseExercise
                reps = item.targetReps
            }

            // Reduced routines can map multiple base exercises to one easier variant.
            // Keep routine exercises unique to avoid duplicate cards like chair-squats twice.
            guard !addedExerciseIDs.contains(exercise.id) else { continue }
            addedExerciseIDs.insert(exercise.id)

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
