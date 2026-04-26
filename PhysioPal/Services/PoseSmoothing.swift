import CoreGraphics
import Foundation

final class PoseSmoothing {
    private var history: [JointID: [CGPoint]] = [:]
    private let windowSize: Int
    private let alpha: CGFloat

    init(windowSize: Int = 5, alpha: CGFloat = 0.4) {
        self.windowSize = windowSize
        self.alpha = alpha
    }

    func smooth(frame: PoseFrame) -> PoseFrame {
        var smoothedLandmarks: [JointID: PoseLandmark] = [:]

        for (joint, landmark) in frame.landmarks {
            var buffer = history[joint] ?? []
            buffer.append(landmark.position)
            if buffer.count > windowSize {
                buffer.removeFirst(buffer.count - windowSize)
            }
            history[joint] = buffer

            let smoothedPosition: CGPoint
            if buffer.count < 2 {
                smoothedPosition = landmark.position
            } else {
                smoothedPosition = exponentialMovingAverage(buffer)
            }

            smoothedLandmarks[joint] = PoseLandmark(
                joint: joint,
                position: smoothedPosition,
                confidence: landmark.confidence
            )
        }

        return PoseFrame(landmarks: smoothedLandmarks, timestamp: frame.timestamp)
    }

    func reset() {
        history.removeAll()
    }

    private func exponentialMovingAverage(_ points: [CGPoint]) -> CGPoint {
        guard let first = points.first else { return .zero }
        var emaX = first.x
        var emaY = first.y

        for point in points.dropFirst() {
            emaX = alpha * point.x + (1 - alpha) * emaX
            emaY = alpha * point.y + (1 - alpha) * emaY
        }

        return CGPoint(x: emaX, y: emaY)
    }
}
