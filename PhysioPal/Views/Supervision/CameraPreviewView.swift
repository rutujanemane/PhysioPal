import AVFoundation
import SwiftUI

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraContainerView {
        let view = CameraContainerView()
        view.videoLayer.videoGravity = .resizeAspectFill
        view.videoLayer.session = session
        return view
    }

    func updateUIView(_ uiView: CameraContainerView, context: Context) {
        uiView.videoLayer.session = session
    }
}

final class CameraContainerView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var videoLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
