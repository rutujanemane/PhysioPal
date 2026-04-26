import AVFoundation
import Foundation

final class TestingPoseProvider: SwitchablePoseProvider {
    private let melangeProvider = MelangePoseProvider()
    private let visionProvider = VisionPoseProvider()
    private var onFrame: ((PoseFrame) -> Void)?
    private(set) var activeSource: PoseSourceMode
    private(set) var activeCameraPosition: AVCaptureDevice.Position = .back

    init(defaultSource: PoseSourceMode = .melange) {
        self.activeSource = defaultSource
    }

    var previewSession: AVCaptureSession? {
        switch activeSource {
        case .melange:
            return melangeProvider.previewSession
        case .vision:
            return visionProvider.previewSession
        }
    }

    func start(onFrame: @escaping (PoseFrame) -> Void) {
        self.onFrame = onFrame
        print("[TestingPoseProvider][H9] start source=\(activeSource.rawValue)")
        activeProvider.start(onFrame: onFrame)
    }

    func stop() {
        print("[TestingPoseProvider][H9] stop source=\(activeSource.rawValue)")
        activeProvider.stop()
    }

    func switchSource(to source: PoseSourceMode) {
        guard source != activeSource else { return }
        print("[TestingPoseProvider][H9] switch \(activeSource.rawValue) -> \(source.rawValue)")
        activeProvider.stop()
        activeSource = source
        if let onFrame {
            activeProvider.start(onFrame: onFrame)
        }
    }

    func switchCamera(position: AVCaptureDevice.Position) {
        activeCameraPosition = position
        melangeProvider.switchCamera(position: position)
        visionProvider.switchCamera(position: position)
    }

    private var activeProvider: PoseProviderProtocol {
        switch activeSource {
        case .melange:
            return melangeProvider
        case .vision:
            return visionProvider
        }
    }
}
