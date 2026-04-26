import Foundation

final class ExerciseEvaluator {
    private var violationStreaks: [String: Int] = [:]
    private let requiredConsecutiveFrames: Int

    init(requiredConsecutiveFrames: Int = 4) {
        self.requiredConsecutiveFrames = requiredConsecutiveFrames
    }

    func evaluate(frame: PoseFrame, exercise: Exercise) -> FormEvaluation {
        var rawViolations: [FormViolation] = []
        var activeRuleKeys: Set<String> = []

        for rule in exercise.formRules {
            let (a, v, c) = rule.jointTriplet
            guard let angle = frame.angleBetween(a, v, c) else { continue }

            let ruleKey = "\(a.rawValue)-\(v.rawValue)-\(c.rawValue)"
            activeRuleKeys.insert(ruleKey)

            if !rule.acceptableRange.contains(angle) {
                let streak = (violationStreaks[ruleKey] ?? 0) + 1
                violationStreaks[ruleKey] = streak

                if streak >= requiredConsecutiveFrames {
                    rawViolations.append(
                        FormViolation(rule: rule, actualAngle: angle, joint: v)
                    )
                }
            } else {
                violationStreaks[ruleKey] = 0
            }
        }

        for key in violationStreaks.keys where !activeRuleKeys.contains(key) {
            violationStreaks[key] = 0
        }

        return FormEvaluation(isCorrect: rawViolations.isEmpty, violations: rawViolations)
    }

    func reset() {
        violationStreaks.removeAll()
    }
}
