import Foundation
import CoreGraphics

struct PoseLandmark {
    let joint: JointID
    let position: CGPoint
    let confidence: Float
}

struct PoseFrame {
    let landmarks: [JointID: PoseLandmark]
    let timestamp: TimeInterval

    func landmark(for joint: JointID) -> PoseLandmark? {
        landmarks[joint]
    }

    func angleBetween(_ a: JointID, _ vertex: JointID, _ c: JointID) -> Double? {
        guard let pointA = landmarks[a]?.position,
              let pointV = landmarks[vertex]?.position,
              let pointC = landmarks[c]?.position else {
            return nil
        }
        return AngleCalculator.angle(pointA: pointA, vertex: pointV, pointC: pointC)
    }
}

struct FormEvaluation {
    let isCorrect: Bool
    let violations: [FormViolation]
}

struct FormViolation {
    let rule: Exercise.FormRule
    let actualAngle: Double
    let joint: JointID
}
