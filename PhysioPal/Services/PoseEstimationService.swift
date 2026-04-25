import AVFoundation
import CoreGraphics
import Foundation

protocol PoseProviderProtocol: AnyObject {
    var previewSession: AVCaptureSession? { get }
    func start(onFrame: @escaping (PoseFrame) -> Void)
    func stop()
}

enum PoseSourceMode: String {
    case melange = "Melange"
    case vision = "Vision"
}

protocol SwitchablePoseProvider: PoseProviderProtocol {
    var activeSource: PoseSourceMode { get }
    func switchSource(to source: PoseSourceMode)
}

extension PoseProviderProtocol {
    var previewSession: AVCaptureSession? { nil }
}

enum PoseScenario {
    case goodForm
    case needsCorrection
    case escalation
}

final class PoseEstimationService: PoseProviderProtocol {
    private var timer: Timer?
    private var onFrame: ((PoseFrame) -> Void)?
    private var frameIndex = 0
    private let scenario: PoseScenario

    init(scenario: PoseScenario = .goodForm) {
        self.scenario = scenario
    }

    func start(onFrame: @escaping (PoseFrame) -> Void) {
        self.onFrame = onFrame
        stop()
        frameIndex = 0

        timer = Timer.scheduledTimer(withTimeInterval: 0.18, repeats: true) { [weak self] _ in
            self?.emitFrame()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func emitFrame() {
        frameIndex += 1
        let isDown = frameIndex % 2 == 0

        let isViolation: Bool
        switch scenario {
        case .goodForm:
            isViolation = false
        case .needsCorrection:
            isViolation = frameIndex % 5 == 0
        case .escalation:
            isViolation = true
        }

        let leftShoulder: CGPoint
        let leftHip: CGPoint
        let leftKnee: CGPoint
        let leftAnkle: CGPoint

        if isDown {
            if isViolation {
                // Intentionally poor squat geometry (too straight / leaning) to trigger corrections.
                leftShoulder = .init(x: 0.44, y: 0.30)
                leftHip = .init(x: 0.45, y: 0.54)
                leftKnee = .init(x: 0.47, y: 0.73)
                leftAnkle = .init(x: 0.48, y: 0.88)
            } else {
                // Tuned to satisfy deep squat form rules in the shared model:
                // - Hip-Knee-Ankle around 90 degrees
                // - Shoulder-Hip-Knee around 75-85 degrees
                leftShoulder = .init(x: 0.45, y: 0.32)
                leftHip = .init(x: 0.37, y: 0.72)
                leftKnee = .init(x: 0.47, y: 0.72)
                leftAnkle = .init(x: 0.47, y: 0.88)
            }
        } else {
            // Standing phase.
            leftShoulder = .init(x: 0.45, y: 0.30)
            leftHip = .init(x: 0.45, y: 0.54)
            leftKnee = .init(x: 0.46, y: 0.45)
            leftAnkle = .init(x: 0.47, y: 0.88)
        }

        let rightShoulder = CGPoint(x: 1.0 - leftShoulder.x, y: leftShoulder.y)
        let rightHip = CGPoint(x: 1.0 - leftHip.x, y: leftHip.y)
        let rightKnee = CGPoint(x: 1.0 - leftKnee.x, y: leftKnee.y)
        let rightAnkle = CGPoint(x: 1.0 - leftAnkle.x, y: leftAnkle.y)

        let landmarks: [JointID: PoseLandmark] = [
            .leftShoulder: .init(joint: .leftShoulder, position: leftShoulder, confidence: 0.95),
            .rightShoulder: .init(joint: .rightShoulder, position: rightShoulder, confidence: 0.95),
            .leftHip: .init(joint: .leftHip, position: leftHip, confidence: 0.95),
            .rightHip: .init(joint: .rightHip, position: rightHip, confidence: 0.95),
            .leftKnee: .init(joint: .leftKnee, position: leftKnee, confidence: 0.95),
            .rightKnee: .init(joint: .rightKnee, position: rightKnee, confidence: 0.95),
            .leftAnkle: .init(joint: .leftAnkle, position: leftAnkle, confidence: 0.95),
            .rightAnkle: .init(joint: .rightAnkle, position: rightAnkle, confidence: 0.95)
        ]

        onFrame?(
            PoseFrame(
                landmarks: landmarks,
                timestamp: Date().timeIntervalSince1970
            )
        )
    }
}
