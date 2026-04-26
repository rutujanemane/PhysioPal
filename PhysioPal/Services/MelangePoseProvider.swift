import AVFoundation
import CoreGraphics
import Foundation
import CoreImage

#if canImport(ZeticMLange)
import ZeticMLange

final class MelangePoseProvider: NSObject, PoseProviderProtocol, AVCaptureVideoDataOutputSampleBufferDelegate {
    var previewSession: AVCaptureSession? {
        isFallbackActive ? fallbackProvider.previewSession : captureSession
    }

    private var onFrame: ((PoseFrame) -> Void)?
    private let modelQueue = DispatchQueue(label: "com.physiopal.melange.model", qos: .userInitiated)
    private let captureQueue = DispatchQueue(label: "com.physiopal.melange.capture", qos: .userInitiated)
    private let inferenceQueue = DispatchQueue(label: "com.physiopal.melange.inference", qos: .userInitiated)

    private var model: ZeticMLangeModel?
    private var isModelReady = false
    private var melangeInferenceDisabled = false
    private var isFallbackActive = false
    private var hasLoggedOutputShape = false
    private var hasLoggedLandmarkStats = false
    private var hasLoggedDecodeMode = false
    private var hasLoggedHeatmapStats = false
    private var hasLoggedHeatmapJoints = false
    private var hasLoggedEmittedFrame = false
    private var inferenceFailureCount = 0
    private var successfulFrameCount = 0
    private var hasLoggedByteRemap = false

    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var isCaptureConfigured = false

    private let fallbackProvider = VisionPoseProvider()
    private let ciContext = CIContext(options: nil)
    private let targetWidth = 256
    private let targetHeight = 256
    private lazy var resizeAttrs: [CFString: Any] = [
        kCVPixelBufferCGImageCompatibilityKey: true,
        kCVPixelBufferCGBitmapContextCompatibilityKey: true,
        kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
        kCVPixelBufferWidthKey: targetWidth,
        kCVPixelBufferHeightKey: targetHeight
    ]

    func start(onFrame: @escaping (PoseFrame) -> Void) {
        self.onFrame = onFrame
        stop()

        modelQueue.async { [weak self] in
            self?.initializeModelIfNeeded()
            self?.startCapturePipeline()
        }
    }

    func stop() {
        fallbackProvider.stop()
        captureQueue.async { [weak self] in
            guard let self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }

    private func initializeModelIfNeeded() {
        guard !isModelReady else { return }
        guard let key = MelangeConfig.personalKey else {
            print("[MelangePoseProvider] Missing MELANGE_PERSONAL_KEY.")
            return
        }

        do {
            model = try ZeticMLangeModel(
                personalKey: key,
                name: MelangeConfig.poseModelKey,
                version: MelangeConfig.poseModelVersion,
                modelMode: .RUN_AUTO
            )
            isModelReady = true
            print("[MelangePoseProvider] Pose model ready.")
        } catch {
            print("[MelangePoseProvider] Model init failed: \(error)")
            isModelReady = false
        }
    }

    private func startCapturePipeline() {
        #if targetEnvironment(simulator)
        print("[MelangePoseProvider] Simulator detected; using Vision/mock fallback.")
        activateFallback()
        return
        #endif

        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            configureAndStartCapture()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }
                if granted {
                    self.configureAndStartCapture()
                } else {
                    print("[MelangePoseProvider] Camera access not granted.")
                    self.activateFallback()
                }
            }
        case .restricted, .denied:
            print("[MelangePoseProvider] Camera access is restricted or denied.")
            activateFallback()
        @unknown default:
            activateFallback()
        }
    }

    private func configureAndStartCapture() {
        captureQueue.async { [weak self] in
            guard let self else { return }
            if !self.isCaptureConfigured {
                self.configureCaptureSession()
            }
            guard self.isCaptureConfigured else {
                self.activateFallback()
                return
            }
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
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: camera),
            captureSession.canAddInput(input)
        else {
            print("[MelangePoseProvider] Failed to configure camera input.")
            return
        }
        captureSession.addInput(input)

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.setSampleBufferDelegate(self, queue: inferenceQueue)
        guard captureSession.canAddOutput(videoOutput) else {
            print("[MelangePoseProvider] Failed to add camera output.")
            return
        }
        captureSession.addOutput(videoOutput)
        if let connection = videoOutput.connection(with: .video) {
            connection.videoRotationAngle = 90
        }
        isCaptureConfigured = true
    }

    private func runInference(pixelBuffer: CVPixelBuffer) {
        guard !melangeInferenceDisabled else {
            activateFallback()
            return
        }
        guard isModelReady, let model else {
            if !isFallbackActive {
                activateFallback()
            }
            return
        }

        modelQueue.async { [weak self] in
            guard let self else { return }
            do {
                let inputTensor = try self.makeInputTensor(from: pixelBuffer)
                let outputs = try self.runModelWithCompatibleInputs(model, primaryInput: inputTensor)
                if !self.hasLoggedOutputShape {
                    self.hasLoggedOutputShape = true
                    let shapes = outputs.map { $0.shape.description }.joined(separator: ", ")
                    print("[MelangePoseProvider] Output tensor shapes: \(shapes)")
                    for (idx, out) in outputs.enumerated() {
                        let expectedElements = out.shape.reduce(1, *)
                        let dataTypeSize = out.dataType.size
                        let expectedBytes = expectedElements * dataTypeSize
                        print(
                            "[MelangePoseProvider][DEBUG] output[\(idx)] " +
                            "shape=\(out.shape) dataType=\(out.dataType) " +
                            "typeSize=\(dataTypeSize) bytes=\(out.data.count) " +
                            "expectedElements=\(expectedElements) expectedBytes=\(expectedBytes)"
                        )
                    }
                    // #region agent log
                    self.debugLog(
                        hypothesisId: "H1",
                        location: "MelangePoseProvider.swift:runInference",
                        message: "Output tensor shapes",
                        data: ["runId": "pre-fix", "shapes": shapes]
                    )
                    // #endregion
                }
                if let frame = self.parsePoseFrame(from: outputs) {
                    guard self.isPlausiblePoseFrame(frame) else {
                        self.inferenceFailureCount += 1
                        if self.inferenceFailureCount == 1 {
                            print("[MelangePoseProvider] Parsed landmarks are implausible on screen.")
                            // #region agent log
                            self.debugLog(
                                hypothesisId: "H5",
                                location: "MelangePoseProvider.swift:runInference",
                                message: "Implausible Melange frame detected",
                                data: [
                                    "runId": "pre-fix",
                                    "nose": self.debugPoint(frame.landmarks[.nose]?.position),
                                    "leftShoulder": self.debugPoint(frame.landmarks[.leftShoulder]?.position),
                                    "rightShoulder": self.debugPoint(frame.landmarks[.rightShoulder]?.position),
                                    "leftHip": self.debugPoint(frame.landmarks[.leftHip]?.position),
                                    "rightHip": self.debugPoint(frame.landmarks[.rightHip]?.position)
                                ]
                            )
                            // #endregion
                        }
                        if self.inferenceFailureCount >= 20 {
                            print("[MelangePoseProvider] Implausible Melange frames persisted. Switching to Vision fallback.")
                            self.activateFallback()
                        } else {
                            print("[MelangePoseProvider][DEBUG] implausible Melange frame #\(self.inferenceFailureCount)")
                        }
                        return
                    }
                    self.inferenceFailureCount = 0
                    self.successfulFrameCount += 1
                    if self.isFallbackActive {
                        self.isFallbackActive = false
                        self.fallbackProvider.stop()
                    }
                    DispatchQueue.main.async {
                        self.onFrame?(frame)
                    }
                    if !self.hasLoggedEmittedFrame {
                        self.hasLoggedEmittedFrame = true
                        // #region agent log
                        self.debugLog(
                            hypothesisId: "H4",
                            location: "MelangePoseProvider.swift:runInference",
                            message: "First frame emitted",
                            data: [
                                "runId": "pre-fix",
                                "landmarkCount": frame.landmarks.count,
                                "nose": self.debugPoint(frame.landmarks[.nose]?.position),
                                "leftShoulder": self.debugPoint(frame.landmarks[.leftShoulder]?.position),
                                "rightShoulder": self.debugPoint(frame.landmarks[.rightShoulder]?.position)
                            ]
                        )
                        // #endregion
                    }
                } else {
                    self.inferenceFailureCount += 1
                    // Avoid bouncing to fallback too aggressively for transient frames.
                    // Only switch if we fail repeatedly before producing any usable frame.
                    if self.successfulFrameCount == 0, self.inferenceFailureCount >= 30 {
                        print("[MelangePoseProvider] Landmark parse unavailable for extended warmup. Switching to Vision fallback.")
                        self.activateFallback()
                    }
                }
            } catch {
                self.inferenceFailureCount += 1
                print("[MelangePoseProvider] Inference failed: \(error)")
                let message = error.localizedDescription
                if message.contains("Feature input_1 is required but not specified")
                    || message.contains("Data size mismatch") {
                    self.melangeInferenceDisabled = true
                    print("[MelangePoseProvider] Disabled Melange inference due to input signature mismatch.")
                }
                if self.successfulFrameCount == 0, self.inferenceFailureCount >= 12 {
                    print("[MelangePoseProvider] Repeated inference errors. Switching to Vision fallback.")
                    self.activateFallback()
                }
            }
        }
    }

    private func runModelWithCompatibleInputs(_ model: ZeticMLangeModel, primaryInput: Tensor) throws -> [Tensor] {
        do {
            return try model.run(inputs: [primaryInput])
        } catch {
            // Some builds expose an additional required feature named input_1,
            // so we retry with two tensors to satisfy positional mapping.
            let secondaryInput = primaryInput
            return try model.run(inputs: [primaryInput, secondaryInput])
        }
    }

    private func makeInputTensor(from pixelBuffer: CVPixelBuffer) throws -> Tensor {
        var resizedBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            targetWidth,
            targetHeight,
            kCVPixelFormatType_32BGRA,
            resizeAttrs as CFDictionary,
            &resizedBuffer
        )
        guard status == kCVReturnSuccess, let resizedBuffer else {
            throw NSError(domain: "MelangePoseProvider", code: -101, userInfo: [NSLocalizedDescriptionKey: "Failed to create resize buffer"])
        }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let sx = CGFloat(targetWidth) / ciImage.extent.width
        let sy = CGFloat(targetHeight) / ciImage.extent.height
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: sx, y: sy))
        ciContext.render(scaled, to: resizedBuffer)

        CVPixelBufferLockBaseAddress(resizedBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(resizedBuffer, .readOnly) }
        guard let baseAddress = CVPixelBufferGetBaseAddress(resizedBuffer) else {
            throw NSError(domain: "MelangePoseProvider", code: -102, userInfo: [NSLocalizedDescriptionKey: "Failed to read resize buffer"])
        }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(resizedBuffer)
        var nhwc = [Float](repeating: 0, count: targetWidth * targetHeight * 3)
        let ptr = baseAddress.assumingMemoryBound(to: UInt8.self)
        for y in 0..<targetHeight {
            let row = ptr.advanced(by: y * bytesPerRow)
            for x in 0..<targetWidth {
                let px = row.advanced(by: x * 4)
                let b = Float(px[0]) / 255.0
                let g = Float(px[1]) / 255.0
                let r = Float(px[2]) / 255.0
                let base = (y * targetWidth + x) * 3
                nhwc[base] = r
                nhwc[base + 1] = g
                nhwc[base + 2] = b
            }
        }

        let data = nhwc.withUnsafeBufferPointer { Data(buffer: $0) }
        return Tensor(data: data, dataType: BuiltinDataType.float32, shape: [1, 256, 256, 3])
    }

    private func parsePoseFrame(from outputs: [Tensor]) -> PoseFrame? {
        if let heatmapFrame = parsePoseFrameFromHeatmap(outputs: outputs) {
            if !hasLoggedDecodeMode {
                hasLoggedDecodeMode = true
                print("[MelangePoseProvider][DEBUG] decode path: heatmap")
            }
            return heatmapFrame
        }

        guard let tensor = selectLandmarkTensor(from: outputs) else { return nil }
        let floats: [Float] = tensor.data.withUnsafeBytes { raw in
            let bound = raw.bindMemory(to: Float.self)
            return Array(bound)
        }
        let landmarkCount = min(floats.count / 5, 39)
        guard landmarkCount >= 33 else { return nil }

        // Inspect coordinate range once to adapt normalization robustly.
        var rawXs: [CGFloat] = []
        var rawYs: [CGFloat] = []
        rawXs.reserveCapacity(33)
        rawYs.reserveCapacity(33)
        for idx in 0..<33 {
            let base = idx * 5
            rawXs.append(CGFloat(floats[base]))
            rawYs.append(CGFloat(floats[base + 1]))
        }
        let minX = rawXs.min() ?? 0
        let maxX = rawXs.max() ?? 1
        let minY = rawYs.min() ?? 0
        let maxY = rawYs.max() ?? 1

        if !hasLoggedLandmarkStats {
            hasLoggedLandmarkStats = true
            print("[MelangePoseProvider] Landmark raw range x:[\(minX), \(maxX)] y:[\(minY), \(maxY)]")
            // #region agent log
            debugLog(
                hypothesisId: "H3",
                location: "MelangePoseProvider.swift:parsePoseFrame",
                message: "Landmark raw range",
                data: [
                    "runId": "pre-fix",
                    "minX": minX,
                    "maxX": maxX,
                    "minY": minY,
                    "maxY": maxY
                ]
            )
            // #endregion
        }

        enum CoordMode {
            case normalized01
            case normalizedSigned
            case pixelSpace
            case centeredPixel
            case centeredPixelRelative
        }
        let coordMode: CoordMode
        if min(minX, minY) >= -1.1, max(maxX, maxY) <= 1.1, min(minX, minY) < 0 {
            coordMode = .normalizedSigned
        } else if max(maxX, maxY) <= 0, min(minX, minY) < -2.0 {
            // Some BlazePose exports emit coordinates centered around image midpoint.
            // Example ranges can look like x:[-50, -5], y:[-53, -6] for 256x256 input.
            // If the range is very tight, absolute mapping bunches points near center;
            // normalize within the observed range to recover body-relative geometry.
            let spanX = maxX - minX
            let spanY = maxY - minY
            coordMode = (spanX < 140 || spanY < 140) ? .centeredPixelRelative : .centeredPixel
        } else if max(maxX, maxY) > 2.0 {
            coordMode = .pixelSpace
        } else {
            coordMode = .normalized01
        }
        if !hasLoggedDecodeMode {
            hasLoggedDecodeMode = true
            print("[MelangePoseProvider][DEBUG] decode path: landmark tensor, mode=\(coordMode)")
        }

        func landmarkAt(_ index: Int) -> (x: CGFloat, y: CGFloat, visibility: Float) {
            let offset = index * 5
            let rawX = CGFloat(floats[offset])
            let rawY = CGFloat(floats[offset + 1])
            let normX: CGFloat
            let normY: CGFloat
            switch coordMode {
            case .normalizedSigned:
                normX = ((rawX + 1.0) * 0.5).clamped01
                normY = ((rawY + 1.0) * 0.5).clamped01
            case .centeredPixelRelative:
                let spanX = Swift.max(maxX - minX, 1e-5)
                let spanY = Swift.max(maxY - minY, 1e-5)
                let pad: CGFloat = 0.10
                let relX = ((rawX - minX) / spanX).clamped01
                let relY = ((rawY - minY) / spanY).clamped01
                normX = (pad + relX * (1.0 - 2.0 * pad)).clamped01
                normY = (pad + relY * (1.0 - 2.0 * pad)).clamped01
            case .centeredPixel:
                normX = ((rawX + CGFloat(targetWidth) * 0.5) / CGFloat(targetWidth)).clamped01
                normY = ((rawY + CGFloat(targetHeight) * 0.5) / CGFloat(targetHeight)).clamped01
            case .pixelSpace:
                normX = (rawX / CGFloat(targetWidth)).clamped01
                normY = (rawY / CGFloat(targetHeight)).clamped01
            case .normalized01:
                normX = rawX.clamped01
                normY = rawY.clamped01
            }
            // Overlay uses top-left origin.
            let y = 1.0 - normY
            let visibility = floats[offset + 3]
            return (normX, y, visibility)
        }

        let map: [(JointID, Int)] = [
            (.nose, 0),
            (.leftShoulder, 11), (.rightShoulder, 12),
            (.leftElbow, 13), (.rightElbow, 14),
            (.leftWrist, 15), (.rightWrist, 16),
            (.leftHip, 23), (.rightHip, 24),
            (.leftKnee, 25), (.rightKnee, 26),
            (.leftAnkle, 27), (.rightAnkle, 28)
        ]

        var landmarks: [JointID: PoseLandmark] = [:]
        for (joint, idx) in map {
            let sample = landmarkAt(idx)
            landmarks[joint] = PoseLandmark(
                joint: joint,
                position: CGPoint(x: sample.x, y: sample.y),
                confidence: sample.visibility
            )
        }

        return PoseFrame(landmarks: landmarks, timestamp: Date().timeIntervalSince1970)
    }

    private func parsePoseFrameFromHeatmap(outputs: [Tensor]) -> PoseFrame? {
        guard let tensor = selectHeatmapTensor(from: outputs) else { return nil }
        let h = 64
        let w = 64
        let c = 39

        let expectedCount = h * w * c
        let values: [Float]
        if tensor.data.count == expectedCount * MemoryLayout<Float>.size {
            values = tensor.data.withUnsafeBytes { raw in
                let bound = raw.bindMemory(to: Float.self)
                return Array(bound)
            }
        } else if tensor.data.count == expectedCount * MemoryLayout<UInt8>.size {
            let u8s: [UInt8] = tensor.data.withUnsafeBytes { raw in
                let bound = raw.bindMemory(to: UInt8.self)
                return Array(bound)
            }
            values = u8s.map { Float($0) / 255.0 }
        } else {
            print("[MelangePoseProvider][DEBUG] unsupported heatmap byte-size=\(tensor.data.count), expectedElements=\(expectedCount)")
            return nil
        }
        guard values.count == expectedCount else { return nil }
        if !hasLoggedHeatmapStats {
            hasLoggedHeatmapStats = true
            // #region agent log
            debugLog(
                hypothesisId: "H1",
                location: "MelangePoseProvider.swift:parsePoseFrameFromHeatmap",
                message: "Heatmap stats",
                data: [
                    "runId": "pre-fix",
                    "shape": "[1,64,64,39]",
                    "min": values.min() ?? 0,
                    "max": values.max() ?? 0
                ]
            )
            // #endregion
            print("[MelangePoseProvider][DEBUG] heatmap shape=[1,64,64,39] min=\(values.min() ?? 0) max=\(values.max() ?? 0) bytes=\(tensor.data.count)")
        }

        let map: [(JointID, Int)] = [
            (.nose, 0),
            (.leftShoulder, 11), (.rightShoulder, 12),
            (.leftElbow, 13), (.rightElbow, 14),
            (.leftWrist, 15), (.rightWrist, 16),
            (.leftHip, 23), (.rightHip, 24),
            (.leftKnee, 25), (.rightKnee, 26),
            (.leftAnkle, 27), (.rightAnkle, 28)
        ]

        var landmarks: [JointID: PoseLandmark] = [:]
        for (joint, ch) in map where ch < c {
            var bestValue: Float = -.greatestFiniteMagnitude
            var bestX = 0
            var bestY = 0
            for y in 0..<h {
                for x in 0..<w {
                    let idx = ((y * w + x) * c) + ch
                    let v = values[idx]
                    if v > bestValue {
                        bestValue = v
                        bestX = x
                        bestY = y
                    }
                }
            }

            let normX = CGFloat(bestX) / CGFloat(max(w - 1, 1))
            let normY = CGFloat(bestY) / CGFloat(max(h - 1, 1))
            let conf = max(0.0, min(1.0, (bestValue + 1.0) * 0.5))
            landmarks[joint] = PoseLandmark(
                joint: joint,
                position: CGPoint(x: normX, y: normY),
                confidence: conf
            )
        }
        if !hasLoggedHeatmapJoints {
            hasLoggedHeatmapJoints = true
            // #region agent log
            debugLog(
                hypothesisId: "H2",
                location: "MelangePoseProvider.swift:parsePoseFrameFromHeatmap",
                message: "Heatmap joint positions",
                data: [
                    "runId": "pre-fix",
                    "nose": debugPoint(landmarks[.nose]?.position),
                    "leftShoulder": debugPoint(landmarks[.leftShoulder]?.position),
                    "rightShoulder": debugPoint(landmarks[.rightShoulder]?.position),
                    "leftHip": debugPoint(landmarks[.leftHip]?.position),
                    "rightHip": debugPoint(landmarks[.rightHip]?.position)
                ]
            )
            // #endregion
            print("[MelangePoseProvider][DEBUG] heatmap joints nose=\(debugPoint(landmarks[.nose]?.position)) lShoulder=\(debugPoint(landmarks[.leftShoulder]?.position)) rShoulder=\(debugPoint(landmarks[.rightShoulder]?.position)) lHip=\(debugPoint(landmarks[.leftHip]?.position)) rHip=\(debugPoint(landmarks[.rightHip]?.position))")
        }

        guard !landmarks.isEmpty else { return nil }
        return PoseFrame(landmarks: landmarks, timestamp: Date().timeIntervalSince1970)
    }

    private func selectLandmarkTensor(from outputs: [Tensor]) -> Tensor? {
        // Runtime evidence: output metadata order may not match tensor data.
        // Use byte-size signature to find 195 float32 values (780 bytes).
        let targetBytes = 195 * MemoryLayout<Float>.size
        let match = outputs.first(where: { $0.data.count == targetBytes })
        if let match, !hasLoggedByteRemap {
            hasLoggedByteRemap = true
            print("[MelangePoseProvider][DEBUG] byte-remap active: landmark tensor selected by bytes=\(targetBytes)")
        }
        return match
    }

    private func selectHeatmapTensor(from outputs: [Tensor]) -> Tensor? {
        // Runtime evidence: heatmap is 64*64*39 float32 = 638,976 bytes.
        let targetBytes = 64 * 64 * 39 * MemoryLayout<Float>.size
        return outputs.first(where: { $0.data.count == targetBytes })
    }

    private func flattenCount(of shape: [Int]) -> Int {
        shape.reduce(1, *)
    }

    private func activateFallback() {
        guard !isFallbackActive, let onFrame else { return }
        isFallbackActive = true
        // #region agent log
        print("[MelangePoseProvider][H1] activating Vision fallback. melangeSessionRunning=\(captureSession.isRunning)")
        // #endregion
        captureQueue.async { [weak self] in
            self?.captureSession.stopRunning()
        }
        fallbackProvider.start(onFrame: onFrame)
    }

    private func isPlausiblePoseFrame(_ frame: PoseFrame) -> Bool {
        let points = frame.landmarks.values.map(\.position)
        guard points.count >= 6 else { return false }
        let xs = points.map(\.x)
        let ys = points.map(\.y)
        guard let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max() else {
            return false
        }
        let spanX = maxX - minX
        let spanY = maxY - minY

        // If decoded joints collapse into a tiny corner cluster, they are not usable for overlay.
        if spanX < 0.15 || spanY < 0.18 { return false }
        if maxX < 0.30 || minX > 0.90 || maxY < 0.20 || minY > 0.95 { return false }
        return true
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        runInference(pixelBuffer: pixelBuffer)
    }
}

#else

final class MelangePoseProvider: PoseProviderProtocol {
    private let fallback = VisionPoseProvider()

    func start(onFrame: @escaping (PoseFrame) -> Void) {
        fallback.start(onFrame: onFrame)
    }

    func stop() {
        fallback.stop()
    }
}

#endif

private extension CGFloat {
    var clamped01: CGFloat { Swift.min(Swift.max(self, 0), 1) }
}

private extension MelangePoseProvider {
    func debugPoint(_ point: CGPoint?) -> String {
        guard let point else { return "nil" }
        return String(format: "%.3f,%.3f", point.x, point.y)
    }

    func debugLog(hypothesisId: String, location: String, message: String, data: [String: Any]) {
        let payload: [String: Any] = [
            "sessionId": "998d56",
            "runId": data["runId"] as? String ?? "pre-fix",
            "hypothesisId": hypothesisId,
            "location": location,
            "message": message,
            "data": data,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let line = String(data: jsonData, encoding: .utf8) else { return }
        let path = "/Users/rutujanemane/Documents/SJSU/PhysioPal/.cursor/debug-998d56.log"
        let dir = "/Users/rutujanemane/Documents/SJSU/PhysioPal/.cursor"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)

        if let handle = FileHandle(forWritingAtPath: path) {
            defer { try? handle.close() }
            try? handle.seekToEnd()
            if let out = (line + "\n").data(using: .utf8) {
                try? handle.write(contentsOf: out)
            }
            return
        }
        try? (line + "\n").write(toFile: path, atomically: true, encoding: .utf8)
    }
}
