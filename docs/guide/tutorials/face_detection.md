Face Detection
Run MediaPipe Face Detection on-device with ZETIC Melange.

Build an on-device face detection application using Google's MediaPipe Face Detection model with ZETIC Melange. This tutorial covers converting the model, deploying it, and running inference on Android and iOS.

We provide Face Detection demo application source code for both Android and iOS.

What You Will Build
A real-time face detection application that identifies face locations in camera frames using the MediaPipe Face Detection model, accelerated on-device with NPU hardware.

Prerequisites
A ZETIC Melange account with a Personal Key (sign up at melange.zetic.ai)
Python 3.8+ with tf2onnx installed
The Face Detection TFLite model (face_detection_short_range.tflite)
Android Studio or Xcode for mobile deployment
What is Face Detection?
The Face Detection model in Google's MediaPipe is a high-performance machine learning model designed for real-time face detection in images and video streams.

Official documentation: Face Detector - Google AI
Step 1: Convert the Model to ONNX
We prepared a pre-built model for you — you can skip Steps 1–2 and jump straight to Step 3 using google/MediaPipe-Face-Detection from the Melange Dashboard.

Prepare the Face Detection model and convert it from TFLite to ONNX format:


pip install tf2onnx
python -m tf2onnx.convert --tflite face_detection_short_range.tflite --output face_detection_short_range.onnx --opset 13
Step 2: Generate Melange Model
Upload the model and inputs via the Melange Dashboard:

Model file: face_detection_short_range.onnx
Input: faces.npy
Step 3: Implement ZeticMLangeModel
Android (Kotlin)
iOS (Swift)
For detailed application setup, please follow the Android Integration Guide guide.


val model = ZeticMLangeModel(this, PERSONAL_KEY, "google/MediaPipe-Face-Detection")
val pixels: FloatArray = preprocess(bitmap)
val inputs = arrayOf(
    Tensor.of(
        data = pixels,
        dataType = DataType.Float32,
        shape = intArrayOf(1, 128, 128, 3),
    )
)
val outputs = model.run(inputs)
Step 4: Use the Face Detection Wrapper
We provide a Face Detection feature extractor as an Android and iOS module.

The Face Detection feature extractor extension will be released as an open-source repository soon.

Android (Kotlin)
iOS (Swift)

// (0) Initialize Face Detection wrapper
val feature = FaceDetectionWrapper()
// (1) Preprocess bitmap and get processed float array
val inputs = feature.preprocess(bitmap)
// ... run model ...
// (2) Postprocess to bitmap
val resultBitmap = feature.postprocess(outputs)
Complete Face Detection Implementation
Android (Kotlin)
iOS (Swift)

// (0) Initialize model and feature
val model = ZeticMLangeModel(this, PERSONAL_KEY, "google/MediaPipe-Face-Detection")
val faceDetection = FaceDetectionWrapper()
// (1) Preprocess image
val faceDetectionInputs = faceDetection.preprocess(imagePtr)
// (2) Process model
val faceDetectionOutputs = model.run(faceDetectionInputs)
// (3) Postprocess model run result
val faceDetectionPostprocessed = faceDetection.postprocess(faceDetectionOutputs)
Conclusion
With ZETIC Melange, building on-device face detection applications with NPU acceleration is straightforward. We have developed a custom OpenCV module and an ML application pipeline, making the implementation remarkably simple and efficient.

We are continually uploading new models to our examples and HuggingFace page.

