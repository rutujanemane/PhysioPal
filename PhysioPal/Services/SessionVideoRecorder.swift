import AVFoundation
import Combine
import Foundation

@MainActor
final class SessionVideoRecorder: NSObject, ObservableObject {
    @Published private(set) var isRecording = false

    private let output = AVCaptureMovieFileOutput()
    private var completion: ((URL?) -> Void)?
    private weak var attachedSession: AVCaptureSession?

    func startRecording(session: AVCaptureSession) {
        guard !isRecording else { return }
        if attachedSession !== session {
            if let attachedSession, attachedSession.outputs.contains(output) {
                attachedSession.removeOutput(output)
            }
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            attachedSession = session
        }
        guard output.connection(with: .video) != nil else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("session-\(UUID().uuidString).mov")
        output.startRecording(to: url, recordingDelegate: self)
        isRecording = true
    }

    func stopRecording(completion: @escaping (URL?) -> Void) {
        guard isRecording else {
            completion(nil)
            return
        }
        self.completion = completion
        output.stopRecording()
    }
}

extension SessionVideoRecorder: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        Task { @MainActor in
            self.isRecording = false
            let callback = self.completion
            self.completion = nil
            callback?(error == nil ? outputFileURL : nil)
        }
    }
}
