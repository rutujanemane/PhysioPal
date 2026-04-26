import AVFoundation
import SwiftUI

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraContainerView {
        let view = CameraContainerView()
        view.videoLayer.videoGravity = .resizeAspectFill
        view.setSession(session)
        return view
    }

    func updateUIView(_ uiView: CameraContainerView, context: Context) {
        uiView.setSession(session)
    }

    static func dismantleUIView(_ uiView: CameraContainerView, coordinator: ()) {
        uiView.clearSession()
    }
}

final class CameraContainerView: UIView {
    private weak var currentSession: AVCaptureSession?

    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var videoLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    func setSession(_ session: AVCaptureSession) {
        guard currentSession !== session else { return }
        videoLayer.session = nil
        currentSession = session
        videoLayer.session = session
    }

    func clearSession() {
        currentSession = nil
        videoLayer.session = nil
    }
}
