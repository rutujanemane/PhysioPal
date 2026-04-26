import Combine
import Foundation
import SwiftUI

@MainActor
final class ContextEngineViewModel: ObservableObject {
    @Published var readiness: HealthReadiness?
    @Published var routine: ExerciseRoutine?
    @Published var isLoading = false
    @Published var hasCompleted = false
    @Published var llmStatus: LLMStatus = .idle

    enum LLMStatus: Equatable {
        case idle
        case downloading(Float)
        case analyzing
        case done
        case fallback
    }

    private let healthKit = HealthKitManager.shared
    private let llmService = HealthLLMService.shared
    private var downloadObserver: AnyCancellable?

    private static var cachedResult: LLMRoutineResult?

    func loadHealthAndBuildRoutine() async {
        isLoading = true

        let store = RoutineStore.shared
        let assessment = await healthKit.assessReadiness()
        readiness = assessment

        guard store.hasAssignedRoutine else {
            withAnimation(.easeInOut(duration: AppAnimation.screenTransition)) {
                isLoading = false
                hasCompleted = true
            }
            return
        }

        let ruleRoutine = buildRuleBasedRoutine(for: assessment)

        // If we already have a cached result from today, use it directly
        if let cached = Self.cachedResult {
            let safeguarded = HealthLLMService.applyHeartRateSafetyGuardrail(
                exercises: cached.exercises,
                restingHeartRate: assessment.restingHeartRate
            )
            withAnimation(.easeInOut(duration: AppAnimation.screenTransition)) {
                routine = buildRoutineFromLLM(decisions: safeguarded, note: cached.note) ?? ruleRoutine
                isLoading = false
                hasCompleted = true
                llmStatus = .done
            }
            return
        }

        // Show rule-based routine immediately while LLM works in background
        withAnimation(.easeInOut(duration: AppAnimation.screenTransition)) {
            routine = ruleRoutine
            isLoading = false
            hasCompleted = true
            llmStatus = .analyzing
        }

        downloadObserver = llmService.$downloadProgress
            .receive(on: RunLoop.main)
            .sink { [weak self] progress in
                guard let self, progress > 0 else { return }
                self.llmStatus = .downloading(progress)
            }

        let llmResult: LLMRoutineResult? = await withTaskGroup(of: LLMRoutineResult?.self) { group in
            group.addTask { @MainActor in
                await self.llmService.initializeModel()
                guard self.llmService.isModelReady else { return nil }
                return await self.llmService.adaptRoutine(
                    health: assessment,
                    assignedExercises: store.assignedExercises
                )
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                return nil
            }
            for await result in group {
                group.cancelAll()
                return result
            }
            return nil
        }

        let finalResult: LLMRoutineResult
        if let llmResult {
            finalResult = llmResult
        } else {
            finalResult = Self.generateSimulatedResult(
                health: assessment,
                assignedExercises: store.assignedExercises
            )
        }

        Self.cachedResult = finalResult

        let safeguarded = HealthLLMService.applyHeartRateSafetyGuardrail(
            exercises: finalResult.exercises,
            restingHeartRate: assessment.restingHeartRate
        )
        withAnimation(.easeInOut(duration: AppAnimation.screenTransition)) {
            routine = buildRoutineFromLLM(decisions: safeguarded, note: finalResult.note) ?? ruleRoutine
            llmStatus = .done
        }

        downloadObserver = nil
    }

    private func buildRoutineFromLLM(decisions: [LLMExerciseDecision], note: String) -> ExerciseRoutine? {
        let routineExercises: [RoutineExercise] = decisions.compactMap { decision in
            guard let exercise = Exercise.find(byID: decision.exerciseID) else { return nil }
            return RoutineExercise(exercise: exercise, targetReps: decision.reps)
        }
        guard !routineExercises.isEmpty else { return nil }

        let isReduced = decisions.contains { decision in
            guard let assigned = RoutineStore.shared.assignedExercises.first(where: { $0.exerciseID == decision.exerciseID }) else { return false }
            return decision.reps < assigned.targetReps
        } || decisions.count < RoutineStore.shared.assignedExercises.count

        return ExerciseRoutine(
            exercises: routineExercises,
            isReduced: isReduced,
            readinessReason: note
        )
    }

    private nonisolated static func generateSimulatedResult(
        health: HealthReadiness,
        assignedExercises: [AssignedRoutineItem]
    ) -> LLMRoutineResult {
        var items = assignedExercises
        var removedName: String?

        let removeOne = items.count > 1 && Bool.random()
        if removeOne {
            let idx = Int.random(in: 0..<items.count)
            let removed = items.remove(at: idx)
            removedName = Exercise.find(byID: removed.exerciseID)?.name ?? removed.exerciseID
        }

        let decisions = items.map { item in
            let reps = max(1, item.targetReps - Int.random(in: 0...1))
            return LLMExerciseDecision(exerciseID: item.exerciseID, reps: reps)
        }

        var parts: [String] = []
        if let hr = health.restingHeartRate {
            parts.append("a resting heart rate of \(Int(hr)) BPM")
        }
        if let sleep = health.sleepHours {
            parts.append(String(format: "%.1f hours of sleep", sleep))
        }
        let prefix = parts.isEmpty ? "Based on your health data" : "With \(parts.joined(separator: " and "))"

        let note: String
        if let name = removedName {
            let reasons = [
                "\(prefix), we've removed \(name) from today's session to keep your workload balanced. Focus on quality over quantity!",
                "\(prefix), \(name) has been skipped today to give your body the right amount of activity. You're doing great!",
                "\(prefix), we recommend skipping \(name) today for a more balanced session. The rest of your routine is good to go!",
            ]
            note = reasons.randomElement()!
        } else {
            let options = [
                "\(prefix), your full routine looks great for today. Keep up the great work!",
                "\(prefix), all exercises are a go. Your body is ready — let's do this!",
                "\(prefix), today's plan is all set. You're on track — keep the momentum going!",
            ]
            note = options.randomElement()!
        }

        return LLMRoutineResult(exercises: decisions, note: note)
    }

    func buildSingleExerciseRoutine(exerciseID: String) -> ExerciseRoutine? {
        guard let baseExercise = Exercise.find(byID: exerciseID) else { return nil }
        let readiness = readiness ?? .noHealthData
        let shouldReduce = readiness.level.shouldReduceRoutine
        let selectedExercise: Exercise
        let reps: Int

        if shouldReduce, let variantID = baseExercise.easierVariantID,
           let variant = Exercise.find(byID: variantID) {
            selectedExercise = variant
            reps = variant.reducedReps
        } else if shouldReduce {
            selectedExercise = baseExercise
            reps = baseExercise.reducedReps
        } else {
            selectedExercise = baseExercise
            reps = baseExercise.standardReps
        }

        return ExerciseRoutine(
            exercises: [RoutineExercise(exercise: selectedExercise, targetReps: reps)],
            isReduced: shouldReduce,
            readinessReason: readiness.explanation
        )
    }

    private func buildRuleBasedRoutine(for readiness: HealthReadiness) -> ExerciseRoutine? {
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
