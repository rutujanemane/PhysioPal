1. pose-detection-overview.md - Architecture & Setup
text
# Pose Detection Integration with Zetic Melange

## Overview
Integrate real-time human pose estimation into your physiotherapy app using Zetic Melange's optimized MediaPipe Pose model running on-device NPU.

## Model Details
- **Model Name**: `ZETIC-ai/mediapipe-pose-estimation`
- **Framework**: MediaPipe BlazePose GHUM 3D
- **Output**: 33 3D body landmarks + visibility scores
- **Performance**: 30+ FPS on modern iPhones
- **Deployment**: On-device only (zero cloud dependency)

## Key Advantages
1. **Privacy-First**: All processing on-device, no data sent to servers
2. **Real-time**: NPU-accelerated inference on Apple Neural Engine
3. **Lightweight**: ~4MB model size
4. **Cross-platform**: Same implementation across iOS versions (15.0+)

## System Requirements
- iOS 15.0 or later
- Physical iPhone 8 or newer (with Neural Engine)
- Xcode 14 or later
- Internet for initial model download (cached locally after)
2. zetic-melange-ios-setup.md - SDK Installation
text
# Zetic Melange iOS SDK Setup

## 1. Prerequisites
- Xcode 14 or later
- Physical iOS device (iPhone 8+)
- iOS 15.0+
- Personal Key from [Melange Dashboard](https://mlange.zetic.ai)

## 2. Add Melange Package via SPM

```swift
// In Xcode:
// File → Add Package Dependencies
// Enter: https://github.com/zetic-ai/ZeticMLangeiOS
// Set version to: 1.6.0 (exact)
// Click Add Package
```

## 3. Link Accelerate Framework
Select Target → General → Frameworks, Libraries, and Embedded Content
Click + → Search "Accelerate.framework" → Add

text

## 4. Verify Setup

```swift
import ZeticMLange

// Quick test
do {
    let model = try ZeticMLangeModel(
        personalKey: "YOUR_PERSONAL_KEY",
        name: "Steve/YOLOv11_comparison"  // Demo model
    )
    print("Melange SDK initialized successfully")
} catch {
    print("Setup error: \(error)")
}
```

## 5. Model Keys
- **Personal Key**: Your secure credential (keep private)
- **Model Key**: `ZETIC-ai/mediapipe-pose-estimation`
- Get both from [Melange Dashboard](https://mlange.zetic.ai)
3. mediapipe-pose-33-landmarks.md - Landmark Reference
text
# MediaPipe Pose: 33 Landmarks Reference

## Complete Landmark List (Index 0-32)

### Face Region (0-9)
| Index | Landmark | Side |
|-------|----------|------|
| 0 | Nose | - |
| 1-3 | Eye Inner, Eye, Eye Outer | Left |
| 4-6 | Eye Inner, Eye, Eye Outer | Right |
| 7-8 | Ear | Left, Right |

### Mouth (9-10)
| Index | Landmark |
|-------|----------|
| 9 | Mouth Left |
| 10 | Mouth Right |

### Upper Body (11-16)
| Index | Landmark | Side |
|-------|----------|------|
| 11-12 | Shoulder | Left, Right |
| 13-14 | Elbow | Left, Right |
| 15-16 | Wrist | Left, Right |

### Hands (17-22)
| Index | Landmark | Side |
|-------|----------|------|
| 17-18 | Pinky (MCP) | Left, Right |
| 19-20 | Index (MCP) | Left, Right |
| 21-22 | Thumb (IP) | Left, Right |

### Lower Body (23-28)
| Index | Landmark | Side |
|-------|----------|------|
| 23-24 | Hip | Left, Right |
| 25-26 | Knee | Left, Right |
| 27-28 | Ankle | Left, Right |

### Feet (29-32)
| Index | Landmark | Side |
|-------|----------|------|
| 29-30 | Heel | Left, Right |
| 31-32 | Foot Index | Left, Right |

## Landmark Properties
Each landmark contains:
- **x, y**: Normalized image coordinates (0.0-1.0)
- **z**: Depth coordinate (relative to hip midpoint)
- **visibility**: Confidence score (0.0-1.0)
- **presence**: Probability landmark is in frame (0.0-1.0)

## Therapeutic Use Cases
- **Posture Analysis**: Track shoulder/spine alignment via landmarks 11-16, 23
- **Range of Motion**: Measure angles between elbow-shoulder-wrist (13-11-15)
- **Movement Tracking**: Monitor hip-knee-ankle alignment (23-25-27)
- **Balance Assessment**: Hip position stability (23-24 center)
4. pose-detection-inference.md - Implementation
text
# Running Pose Detection with Zetic Melange

## Step 1: Load the Model

```swift
import ZeticMLange
import ARKit

class PoseDetectionViewController: UIViewController {
    var poseModel: ZeticMLangeModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadPoseModel()
    }
    
    func loadPoseModel() {
        do {
            poseModel = try ZeticMLangeModel(
                personalKey: "YOUR_PERSONAL_KEY",
                name: "ZETIC-ai/mediapipe-pose-estimation"
            )
            print("Pose model loaded successfully")
        } catch {
            print("Failed to load pose model: \(error)")
        }
    }
}
```

## Step 2: Capture Video Frames

```swift
import AVFoundation

extension PoseDetectionViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, 
                      didOutput sampleBuffer: CMSampleBuffer, 
                      from connection: AVCaptureConnection) {
        // Convert CMSampleBuffer to image
        guard let image = imageFromSampleBuffer(sampleBuffer) else { return }
        
        // Prepare tensor input
        runPoseDetection(on: image)
    }
    
    private func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}
```

## Step 3: Prepare Input Tensor

```swift
func prepareInputTensor(from image: UIImage) -> Tensor? {
    // Resize to model input size (typically 256x256)
    guard let resized = image.resized(to: CGSize(width: 256, height: 256)) else {
        return nil
    }
    
    // Convert to RGB data
    guard let rgbData = resized.toRGBData() else {
        return nil
    }
    
    // Create Float32 tensor
    return try? Tensor(
        data: rgbData,
        shape: [1, 256, 256, 3],
        dtype: .float32
    )
}
```

## Step 4: Run Inference

```swift
func runPoseDetection(on image: UIImage) {
    guard let model = poseModel else { return }
    
    do {
        // Prepare input
        guard let inputTensor = prepareInputTensor(from: image) else {
            return
        }
        
        // Run inference
        let outputs = try model.run(inputs: [inputTensor])
        
        // Parse results
        parsePoseOutput(outputs, imageSize: image.size)
    } catch {
        print("Inference error: \(error)")
    }
}
```

## Step 5: Parse Output

```swift
struct PoseLandmark {
    let index: Int
    let name: String
    let x: Float  // normalized 0.0-1.0
    let y: Float  // normalized 0.0-1.0
    let z: Float  // depth
    let visibility: Float
    let presence: Float
}

func parsePoseOutput(_ outputs: [Tensor], imageSize: CGSize) {
    guard !outputs.isEmpty else { return }
    
    let outputTensor = outputs
    let data = outputTensor.data
    
    // Output format: 33 landmarks × 5 values (x, y, z, visibility, presence)
    let stride = 5
    var landmarks: [PoseLandmark] = []
    
    for i in 0..<33 {
        let offset = i * stride
        let x = Float(data[offset])
        let y = Float(data[offset + 1])
        let z = Float(data[offset + 2])
        let visibility = Float(data[offset + 3])
        let presence = Float(data[offset + 4])
        
        landmarks.append(PoseLandmark(
            index: i,
            name: landmarkName(for: i),
            x: x,
            y: y,
            z: z,
            visibility: visibility,
            presence: presence
        ))
    }
    
    processPoseResults(landmarks, imageSize: imageSize)
}

func landmarkName(for index: Int) -> String {
    let names = [
        "Nose",
        "L Eye Inner", "L Eye", "L Eye Outer",
        "R Eye Inner", "R Eye", "R Eye Outer",
        "L Ear", "R Ear",
        "Mouth L", "Mouth R",
        "L Shoulder", "R Shoulder",
        "L Elbow", "R Elbow",
        "L Wrist", "R Wrist",
        "L Pinky", "R Pinky",
        "L Index", "R Index",
        "L Thumb", "R Thumb",
        "L Hip", "R Hip",
        "L Knee", "R Knee",
        "L Ankle", "R Ankle",
        "L Heel", "R Heel",
        "L Foot Index", "R Foot Index"
    ]
    return index < names.count ? names[index] : "Unknown"
}
```

## Step 6: Apply Pose Analysis

```swift
func processPoseResults(_ landmarks: [PoseLandmark], imageSize: CGSize) {
    // Convert normalized to pixel coordinates
    let pixelLandmarks = landmarks.map { landmark in
        return CGPoint(
            x: landmark.x * imageSize.width,
            y: landmark.y * imageSize.height
        )
    }
    
    // Example: Calculate angles for physiotherapy analysis
    let shoulderAngle = calculateAngle(
        a: pixelLandmarks,  // L Shoulder
        b: pixelLandmarks,  // L Elbow
        c: pixelLandmarks   // L Wrist
    )
    
    print("Left shoulder-elbow-wrist angle: \(shoulderAngle)°")
    
    // Display on screen
    updatePoseVisualization(landmarks, imageSize: imageSize)
}

func calculateAngle(a: CGPoint, b: CGPoint, c: CGPoint) -> CGFloat {
    let ab = CGVector(dx: b.x - a.x, dy: b.y - a.y)
    let cb = CGVector(dx: b.x - c.x, dy: b.y - c.y)
    
    let dot = ab.dx * cb.dx + ab.dy * cb.dy
    let det = ab.dx * cb.dy - ab.dy * cb.dx
    
    let radians = atan2(det, dot)
    return abs(radians) * 180 / CGFloat.pi
}
```

## Performance Tips
1. **Frame Sampling**: Process every 3rd frame to reduce compute load
2. **Resolution**: Input 256×256 for balance between speed & accuracy
3. **Threading**: Run inference on background queue
4. **Caching**: Model loads from cache after first download

## Error Handling
```swift
do {
    let outputs = try model.run(inputs: [inputTensor])
} catch ZeticMLangeError.inputShapeMismatch {
    print("Input tensor shape doesn't match model requirements")
} catch ZeticMLangeError.modelNotFound {
    print("Model failed to download or load")
} catch {
    print("Unknown inference error: \(error)")
}
```
5. pose-physiotherapy-use-cases.md - Application
text
# Pose Detection for Physiotherapy App

## Key Analysis Points for PhysioPal

### 1. Posture Assessment
**Landmarks to Track**: 11, 12 (shoulders), 23, 24 (hips), 0 (nose)

```swift
func assessPosture(_ landmarks: [PoseLandmark]) -> PostureScore {
    let leftShoulder = landmarks
    let rightShoulder = landmarks
    let leftHip = landmarks
    let rightHip = landmarks
    
    // Check shoulder alignment (should be level)
    let shoulderDifference = abs(leftShoulder.y - rightShoulder.y)
    
    // Check hip alignment
    let hipDifference = abs(leftHip.y - rightHip.y)
    
    return PostureScore(
        shoulderAlignment: 1.0 - min(shoulderDifference / 0.2, 1.0),
        hipAlignment: 1.0 - min(hipDifference / 0.2, 1.0)
    )
}
```

### 2. Range of Motion (ROM) Tracking
**For shoulder abduction**:
- Landmarks: 12 (R Shoulder), 14 (R Elbow), 16 (R Wrist)

```swift
func calculateShoulderROM(_ landmarks: [PoseLandmark]) -> Float {
    let shoulder = landmarks
    let elbow = landmarks
    let wrist = landmarks
    
    // Vector from shoulder to elbow
    let upper = CGVector(
        dx: elbow.x - shoulder.x,
        dy: elbow.y - shoulder.y
    )
    
    // Magnitude = arm length estimate
    let armLength = sqrt(upper