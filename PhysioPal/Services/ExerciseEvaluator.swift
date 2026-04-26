import Foundation

final class ExerciseEvaluator {
    private let requiredConsecutiveFrames: Int
    private var violationStreaks: [String: Int] = [:]

    init(requiredConsecutiveFrames: Int = 2) {
        self.requiredConsecutiveFrames = requiredConsecutiveFrames
    }

    func evaluate(frame: PoseFrame, exercise: Exercise) -> FormEvaluation {
        var violations: [FormViolation] = []
        var activeRuleKeys: Set<String> = []

        for rule in exercise.formRules {
            let (a, v, c) = rule.jointTriplet
            guard let angle = frame.angleBetween(a, v, c) else { continue }

            let key = "\(a.rawValue)-\(v.rawValue)-\(c.rawValue)"
            activeRuleKeys.insert(key)

            if rule.acceptableRange.contains(angle) {
                violationStreaks[key] = 0
            } else {
                let streak = (violationStreaks[key] ?? 0) + 1
                violationStreaks[key] = streak
                guard streak >= requiredConsecutiveFrames else { continue }
                violations.append(
                    FormViolation(rule: rule, actualAngle: angle, joint: v)
                )
            }
        }

        for key in violationStreaks.keys where !activeRuleKeys.contains(key) {
            violationStreaks[key] = 0
        }

        return FormEvaluation(isCorrect: violations.isEmpty, violations: violations)
    }

    func reset() {
        violationStreaks.removeAll()
    }
}
