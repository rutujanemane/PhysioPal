import Foundation

struct ExerciseEvaluator {
    func evaluate(frame: PoseFrame, exercise: Exercise) -> FormEvaluation {
        var violations: [FormViolation] = []

        for rule in exercise.formRules {
            let (a, v, c) = rule.jointTriplet
            guard let angle = frame.angleBetween(a, v, c) else { continue }
            if !rule.acceptableRange.contains(angle) {
                violations.append(
                    FormViolation(rule: rule, actualAngle: angle, joint: v)
                )
            }
        }

        return FormEvaluation(isCorrect: violations.isEmpty, violations: violations)
    }
}
