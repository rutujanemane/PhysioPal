import CoreGraphics
import Foundation

/// Smooths pose landmarks to reduce frame-level jitter while preserving movement.
final class PoseSmoothing {
    private let alpha: CGFloat
    private let windowSize: Int
    private var history: [JointID: [PoseLandmark]] = [:]

    init(alpha: CGFloat = 0.4, windowSize: Int = 5) {
        self.alpha = alpha
        self.windowSize = windowSize
    }

    func smooth(frame: PoseFrame) -> PoseFrame {
        var smoothed: [JointID: PoseLandmark] = [:]

        for (joint, landmark) in frame.landmarks {
            var buffer = history[joint] ?? []
            buffer.append(landmark)
            if buffer.count > windowSize {
                buffer.removeFirst(buffer.count - windowSize)
            }
            history[joint] = buffer

            var ema = buffer[0].position
            if buffer.count > 1 {
                for sample in buffer.dropFirst() {
                    ema = CGPoint(
                        x: alpha * sample.position.x + (1 - alpha) * ema.x,
                        y: alpha * sample.position.y + (1 - alpha) * ema.y
                    )
                }
            }

            smoothed[joint] = PoseLandmark(
                joint: landmark.joint,
                position: ema,
                confidence: landmark.confidence
            )
        }

        return PoseFrame(landmarks: smoothed, timestamp: frame.timestamp)
    }

    func reset() {
        history.removeAll()
    }
}
