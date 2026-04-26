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
            description: "Stand tall and start with your right side leading. Lower slowly like sitting back into a chair, then rise with control.",
            iconName: "figure.strengthtraining.traditional",
            standardReps: 15,
            reducedReps: 10,
            easierVariantID: "chair-squat",
            formRules: [
                FormRule(
                    jointTriplet: (.leftHip, .leftKnee, .leftAnkle),
                    acceptableRange: 55...130,
                    correctionMessage: "Great effort. Let's bend a little deeper through the knees."
                ),
                FormRule(
                    jointTriplet: (.leftShoulder, .leftHip, .leftKnee),
                    acceptableRange: 45...120,
                    correctionMessage: "Let's keep your chest a bit taller as you go down."
                )
            ]
        ),
        Exercise(
            id: "chair-squat",
            name: "Chair-Assisted Squats",
            description: "Sit and stand with a chair behind you. Start gently and press up through your legs at a steady pace.",
            iconName: "chair.fill",
            standardReps: 10,
            reducedReps: 6,
            easierVariantID: nil,
            formRules: [
                FormRule(
                    jointTriplet: (.leftHip, .leftKnee, .leftAnkle),
                    acceptableRange: 60...140,
                    correctionMessage: "Nice work. Let's line up the knee and ankle a little better."
                )
            ]
        ),
        Exercise(
            id: "standing-hip-abduction",
            name: "Standing Hip Abduction",
            description: "Hold a chair for balance. Start with your right leg and move it out to the side, then return slowly.",
            iconName: "figure.cooldown",
            standardReps: 12,
            reducedReps: 8,
            easierVariantID: nil,
            formRules: [
                FormRule(
                    jointTriplet: (.leftHip, .leftKnee, .leftAnkle),
                    acceptableRange: 135...180,
                    correctionMessage: "Let's keep the moving leg straighter as it lifts."
                ),
                FormRule(
                    jointTriplet: (.leftShoulder, .leftHip, .leftKnee),
                    acceptableRange: 125...180,
                    correctionMessage: "You're doing well. Keep your body upright and avoid leaning."
                )
            ]
        ),
        Exercise(
            id: "seated-knee-extension",
            name: "Seated Knee Extensions",
            description: "Sit tall in a chair. Start with your right leg and gently straighten your knee, then lower with control.",
            iconName: "figure.seated.side",
            standardReps: 12,
            reducedReps: 8,
            easierVariantID: nil,
            formRules: [
                FormRule(
                    jointTriplet: (.leftHip, .leftKnee, .leftAnkle),
                    acceptableRange: 130...180,
                    correctionMessage: "Nice pace. Try straightening the kicking leg a little more."
                ),
                FormRule(
                    jointTriplet: (.leftShoulder, .leftHip, .leftAnkle),
                    acceptableRange: 60...125,
                    correctionMessage: "Let's stay tall in the chair and keep your posture relaxed."
                )
            ]
        )
    ]

    static func find(byID id: String) -> Exercise? {
        library.first { $0.id == id }
    }
}
