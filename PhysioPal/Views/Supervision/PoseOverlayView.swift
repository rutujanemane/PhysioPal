import SwiftUI

struct PoseOverlayView: View {
    let frame: PoseFrame?
    let highlightedJoints: Set<JointID>

    var body: some View {
        GeometryReader { geo in
            if let frame {
                ZStack {
                    Path { path in
                        for pair in skeletonPairs {
                            guard
                                let a = frame.landmark(for: pair.0)?.position,
                                let b = frame.landmark(for: pair.1)?.position
                            else { continue }

                            path.move(to: CGPoint(x: a.x * geo.size.width, y: a.y * geo.size.height))
                            path.addLine(to: CGPoint(x: b.x * geo.size.width, y: b.y * geo.size.height))
                        }
                    }
                    .stroke(AppColors.primary, lineWidth: 4)

                    ForEach(Array(frame.landmarks.keys), id: \.self) { joint in
                        if let landmark = frame.landmark(for: joint) {
                            Circle()
                                .fill(highlightedJoints.contains(joint) ? AppColors.error : AppColors.primary)
                                .frame(width: 12, height: 12)
                                .position(
                                    x: landmark.position.x * geo.size.width,
                                    y: landmark.position.y * geo.size.height
                                )
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private var skeletonPairs: [(JointID, JointID)] {
        [
            (.leftShoulder, .rightShoulder),
            (.leftShoulder, .leftHip),
            (.rightShoulder, .rightHip),
            (.leftHip, .rightHip),
            (.leftHip, .leftKnee),
            (.rightHip, .rightKnee),
            (.leftKnee, .leftAnkle),
            (.rightKnee, .rightAnkle)
        ]
    }
}
