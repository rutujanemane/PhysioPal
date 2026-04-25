import AVFoundation
import CoreGraphics
import Foundation
import Vision

final class VisionPoseProvider: NSObject, PoseProviderProtocol {
    var previewSession: AVCaptureSession? { captureSession }

    private let captureSession = AVCaptureSession()
    private let cameraQueue = DispatchQueue(label: "com.physiopal.vision.camera", qos: .userInitiated)
    private let visionQueue = DispatchQueue(label: "com.physiopal.vision.inference", qos: .userInitiated)
    private let videoOutput = AVCaptureVideoDataOutput()
    private var isConfigured = false
    private var onFrame: ((PoseFrame) -> Void)?
    private let fallbackProvider = PoseEstimationService(scenario: .goodForm)
    private var lastLandmarks: [JointID: PoseLandmark] = [:]
    private var sampleBufferCount = 0
    private var emittedFrameCount = 0

    private let poseRequest = VNDetectHumanBodyPoseRequest()

    func start(onFrame: @escaping (PoseFrame) -> Void) {
        self.onFrame = onFrame
        // #region agent log
        print("[VisionPoseProvider][H2] start called")
        // #endregion
        #if targetEnvironment(simulator)
        print("[VisionPoseProvider] Simulator detected; using mock fallback frames.")
        fallbackProvider.start(onFrame: onFrame)
        return
        #endif

        let status = AVCaptureDevice.authorizationStatus(for: .video)
        // #region agent log
        print("[VisionPoseProvider][H2] camera authorization status=\(status.rawValue)")
        // #endregion
        switch status {
        case .authorized:
            startCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }
                if granted {
                    self.startCaptureSession()
                } else {
                    print("[VisionPoseProvider] Camera access not granted.")
                    self.startFallbackIfPossible()
                }
            }
        case .restricted, .denied:
            print("[VisionPoseProvider] Camera access is restricted or denied.")
            startFallbackIfPossible()
        @unknown default:
            print("[VisionPoseProvider] Unknown camera permission state.")
            startFallbackIfPossible()
        }
    }

    func stop() {
        fallbackProvider.stop()
        // #region agent log
        print("[VisionPoseProvider][H1] stop called")
        // #endregion
        cameraQueue.async { [weak self] in
            guard let self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }

    private func startCaptureSession() {
        cameraQueue.async { [weak self] in
            guard let self else { return }
            if !self.isConfigured {
                self.configureCaptureSession()
            }
            guard self.isConfigured else { return }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }

    private func configureCaptureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high

        defer { captureSession.commitConfiguration() }

        guard
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: camera),
            captureSession.canAddInput(input)
        else {
            print("[VisionPoseProvider] Failed to configure back camera input.")
            // #region agent log
            print("[VisionPoseProvider][H1] camera input setup failed")
            // #endregion
            startFallbackIfPossible()
            return
        }
        captureSession.addInput(input)

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.setSampleBufferDelegate(self, queue: visionQueue)

        guard captureSession.canAddOutput(videoOutput) else {
            print("[VisionPoseProvider] Failed to add video output.")
            // #region agent log
            print("[VisionPoseProvider][H1] camera output setup failed")
            // #endregion
            startFallbackIfPossible()
            return
        }
        captureSession.addOutput(videoOutput)
        if let connection = videoOutput.connection(with: .video) {
            connection.videoRotationAngle = 90
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }
        // #region agent log
        print("[VisionPoseProvider][H1] capture configured. sessionRunning=\(captureSession.isRunning)")
        // #endregion

        isConfigured = true
    }

    private func makePoseFrame(from observation: VNHumanBodyPoseObservation) -> PoseFrame? {
        let mapping: [(JointID, VNHumanBodyPoseObservation.JointName)] = [
            (.nose, .nose),
            (.leftShoulder, .leftShoulder), (.rightShoulder, .rightShoulder),
            (.leftElbow, .leftElbow), (.rightElbow, .rightElbow),
            (.leftWrist, .leftWrist), (.rightWrist, .rightWrist),
            (.leftHip, .leftHip), (.rightHip, .rightHip),
            (.leftKnee, .leftKnee), (.rightKnee, .rightKnee),
            (.leftAnkle, .leftAnkle), (.rightAnkle, .rightAnkle)
        ]

        var landmarks: [JointID: PoseLandmark] = [:]
        for (jointID, visionJointName) in mapping {
            guard let point = try? observation.recognizedPoint(visionJointName),
                  point.confidence >= 0.1
            else { continue }

            // Runtime evidence in this app shows a 90-degree mismatch if we use (x, 1-y).
            // Rotate Vision coordinates into this preview's orientation.
            let normalizedPoint = CGPoint(x: point.y, y: point.x)
            landmarks[jointID] = PoseLandmark(
                joint: jointID,
                position: normalizedPoint,
                confidence: point.confidence
            )
        }

        for joint in JointID.allCases where landmarks[joint] == nil {
            if let cached = lastLandmarks[joint], cached.confidence >= 0.15 {
                landmarks[joint] = cached
            }
        }

        guard !landmarks.isEmpty else { return nil }
        lastLandmarks = landmarks
        emittedFrameCount += 1
        if emittedFrameCount <= 2 {
            // #region agent log
            let nose = landmarks[.nose]?.position
            let lShoulder = landmarks[.leftShoulder]?.position
            let rShoulder = landmarks[.rightShoulder]?.position
            print("[VisionPoseProvider][H3] emitted frame \(emittedFrameCount) landmarks=\(landmarks.count) nose=\(String(describing: nose)) lS=\(String(describing: lShoulder)) rS=\(String(describing: rShoulder))")
            // #endregion
        }
        return PoseFrame(landmarks: landmarks, timestamp: Date().timeIntervalSince1970)
    }

    private func startFallbackIfPossible() {
        guard let onFrame else { return }
        fallbackProvider.start(onFrame: onFrame)
    }
}

extension VisionPoseProvider: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        sampleBufferCount += 1
        if sampleBufferCount <= 3 {
            // #region agent log
            print("[VisionPoseProvider][H2] sampleBuffer received #\(sampleBufferCount)")
            // #endregion
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([poseRequest])
            guard let observation = poseRequest.results?.first,
                  let frame = makePoseFrame(from: observation) else {
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.onFrame?(frame)
            }
        } catch {
            print("[VisionPoseProvider] Pose request failed: \(error.localizedDescription)")
        }
    }
}
