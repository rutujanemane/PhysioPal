Face Landmark Detection
Detect facial landmarks using a two-model pipeline with ZETIC Melange.

Build an on-device face landmark detection application using a two-model pipeline with ZETIC Melange. This tutorial demonstrates how to chain Face Detection and Face Landmark models together for accurate facial landmark extraction on Android and iOS.

We provide Face Landmark demo application source code for both Android and iOS.

What You Will Build
A real-time face landmark detection application that first detects faces, then extracts detailed facial landmarks from each detected face region. This two-step pipeline ensures accurate landmark placement by feeding properly cropped face images to the landmark model.

Prerequisites
A ZETIC Melange account with a Personal Key (sign up at melange.zetic.ai)
Python 3.8+ with tf2onnx installed
The Face Detection and Face Landmark TFLite models
Android Studio or Xcode for mobile deployment
What is Face Landmark?
The Face Landmark model in Google's MediaPipe is a highly efficient machine learning model used for real-time face detection and landmark extraction.

Official documentation: Face Landmarker - Google AI
Model Pipelining
For accurate use of the face landmark model, it is necessary to pass an image of the correct facial area to the model. To accomplish this, we construct a pipeline with the Face Detection model:

Face Detection: Use the Face Detection model to accurately detect face regions in the image. Extract that part of the original image using the detected face region information.
Face Landmark: Input the extracted face image into the Face Landmark model to analyze facial landmarks.
Step 1: Convert the Models to ONNX
We prepared pre-built models for you — you can skip Steps 1–2 and jump straight to Step 3 using these models from the Melange Dashboard:

google/MediaPipe-Face-Detection
google/MediaPipe-Face-Landmark
Prepare both models from GitHub and convert them to ONNX format.

Face Detection model:


pip install tf2onnx
python -m tf2onnx.convert --tflite face_detection_short_range.tflite --output face_detection_short_range.onnx --opset 13
Face Landmark model:


python -m tf2onnx.convert --tflite face_landmark.tflite --output face_landmark.onnx --opset 13
Step 2: Generate Melange Models
Upload both models and their inputs via the Melange Dashboard:

face_detection_short_range.onnx with input input.npy
face_landmark.onnx with input input.npy
Step 3: Implement ZeticMLangeModel
The Face Detection model feeds cropped face regions into this model; see Face Detection for its own code.

Android (Kotlin)
iOS (Swift)
For detailed application setup, please follow the Android Integration Guide guide.


val faceLandmarkModel = ZeticMLangeModel(this, PERSONAL_KEY, "google/MediaPipe-Face-Landmark")
val pixels: FloatArray = preprocess(croppedFaceBitmap)
val inputs = arrayOf(
    Tensor.of(
        data = pixels,
        dataType = DataType.Float32,
        shape = intArrayOf(1, 192, 192, 3),
    )
)
val outputs = faceLandmarkModel.run(inputs)
Step 4: Use the Face Landmark Wrapper
We provide a Face Landmark feature extractor as an Android and iOS module.

The Face Landmark feature extractor extension will be released as an open-source repository soon.

Android (Kotlin)
iOS (Swift)

// (0) Initialize Face Landmark wrapper
val feature = FaceLandmarkWrapper()
// (1) Preprocess bitmap and get processed float array
val inputs = feature.preprocess(bitmap)
// ... run model ...
// (2) Postprocess to bitmap
val resultBitmap = feature.postprocess(outputs)
Complete Face Landmark Pipeline Implementation
The complete implementation requires pipelining two models: Face Detection followed by Face Landmark.

Android (Kotlin)
iOS (Swift)
Step 1: Face Detection


// (0) Initialize face detection model
val faceDetectionModel = ZeticMLangeModel(this, PERSONAL_KEY, "google/MediaPipe-Face-Detection")
val faceDetection = FaceDetectionWrapper()
// (1) Preprocess image
val faceDetectionInputs = faceDetection.preprocess(bitmap)
// (2) Run face detection model
val faceDetectionOutputs = faceDetectionModel.run(faceDetectionInputs)
// (3) Postprocess to get face regions
val faceDetectionPostprocessed = faceDetection.postprocess(faceDetectionOutputs)
Step 2: Face Landmark


// (0) Initialize face landmark model
val faceLandmarkModel = ZeticMLangeModel(this, PERSONAL_KEY, "google/MediaPipe-Face-Landmark")
val faceLandmark = FaceLandmarkWrapper()
// (1) Preprocess with detected face regions
val faceLandmarkInputs = faceLandmark.preprocess(bitmap, faceDetectionPostprocessed)
// (2) Run face landmark model
val faceLandmarkOutputs = faceLandmarkModel.run(faceLandmarkInputs)
// (3) Postprocess to get landmarks
val faceLandmarkPostprocessed = faceLandmark.postprocess(faceLandmarkOutputs)
Conclusion
With ZETIC Melange, building multi-model pipelines for on-device AI is straightforward. The Face Detection to Face Landmark pipeline demonstrates how you can chain models together for accurate, real-time facial analysis with NPU acceleration.