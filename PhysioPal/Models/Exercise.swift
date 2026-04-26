import Foundation

struct Exercise: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let iconName: String
    let standardReps: Int
    let reducedReps: Int
    let easierVariantID: String?
    let formRules: [FormRule]

    struct FormRule: Hashable {
        let jointTriplet: (JointID, JointID, JointID)
        let acceptableRange: ClosedRange<Double>
        let correctionMessage: String

        static func == (lhs: FormRule, rhs: FormRule) -> Bool {
            lhs.jointTriplet.0 == rhs.jointTriplet.0 &&
            lhs.jointTriplet.1 == rhs.jointTriplet.1 &&
            lhs.jointTriplet.2 == rhs.jointTriplet.2 &&
            lhs.acceptableRange == rhs.acceptableRange
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(jointTriplet.0)
            hasher.combine(jointTriplet.1)
            hasher.combine(jointTriplet.2)
            hasher.combine(acceptableRange.lowerBound)
            hasher.combine(acceptableRange.upperBound)
        }
    }
}

enum JointID: String, Hashable, CaseIterable {
    case leftShoulder, rightShoulder
    case leftElbow, rightElbow
    case leftWrist, rightWrist
    case leftHip, rightHip
    case leftKnee, rightKnee
    case leftAnkle, rightAnkle
    case nose
}

extension Exercise {
    static let library: [Exercise] = [
        Exercise(
            id: "deep-squat",
            name: "Deep Squats",
            description: "Stand with feet shoulder-width apart, lower your hips until thighs are parallel to the ground.",
            iconName: "figure.strengthtraining.traditional",
            standardReps: 15,
            reducedReps: 10,
            easierVariantID: "chair-squat",
            formRules: [
                FormRule(
                    jointTriplet: (.leftHip, .leftKnee, .leftAnkle),
                    acceptableRange: 55...130,
                    correctionMessage: "Let's adjust your knee bend — aim for a right angle"
                ),
                FormRule(
                    jointTriplet: (.leftShoulder, .leftHip, .leftKnee),
                    acceptableRange: 45...120,
                    correctionMessage: "Try keeping your back a bit more upright"
                )
            ]
        ),
        Exercise(
            id: "chair-squat",
            name: "Chair-Assisted Squats",
            description: "Using a chair for support, gently lower yourself and stand back up.",
            iconName: "chair.fill",
            standardReps: 10,
            reducedReps: 6,
            easierVariantID: nil,
            formRules: [
                FormRule(
                    jointTriplet: (.leftHip, .leftKnee, .leftAnkle),
                    acceptableRange: 60...140,
                    correctionMessage: "Let's adjust your knee angle a little"
                )
            ]
        ),
        Exercise(
            id: "standing-leg-raise",
            name: "Standing Leg Raises",
            description: "Stand tall and slowly raise one leg to the side, then lower it back down.",
            iconName: "figure.walk",
            standardReps: 12,
            reducedReps: 8,
            easierVariantID: nil,
            formRules: [
                FormRule(
                    jointTriplet: (.leftHip, .leftKnee, .leftAnkle),
                    acceptableRange: 135...180,
                    correctionMessage: "Try to keep your raised leg a bit straighter"
                ),
                FormRule(
                    jointTriplet: (.leftShoulder, .leftHip, .leftKnee),
                    acceptableRange: 125...180,
                    correctionMessage: "Keep your torso upright — try not to lean"
                )
            ]
        ),
        Exercise(
            id: "wall-pushup",
            name: "Wall Push-Ups",
            description: "Place hands on a wall at shoulder height, lower your chest toward the wall, then push back.",
            iconName: "figure.strengthtraining.functional",
            standardReps: 12,
            reducedReps: 8,
            easierVariantID: nil,
            formRules: [
                FormRule(
                    jointTriplet: (.leftShoulder, .leftElbow, .leftWrist),
                    acceptableRange: 55...140,
                    correctionMessage: "Let's adjust your elbow angle — bend a little more"
                ),
                FormRule(
                    jointTriplet: (.leftShoulder, .leftHip, .leftAnkle),
                    acceptableRange: 145...180,
                    correctionMessage: "Try keeping your body in a straight line"
                )
            ]
        )
    ]

    static func find(byID id: String) -> Exercise? {
        library.first { $0.id == id }
    }
}
