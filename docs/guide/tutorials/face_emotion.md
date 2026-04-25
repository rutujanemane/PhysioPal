Face Emotion Recognition
Classify facial emotions on-device using EMO-AffectNet with ZETIC Melange.

Build an on-device face emotion recognition application using a two-model pipeline with ZETIC Melange. This tutorial chains Face Detection with the EMO-AffectNet (ResNet-50) model to classify facial emotions in real time on Android and iOS.

We provide the source code for the Face Emotion Recognition demo application for both Android and iOS.

What You Will Build
A real-time emotion classification application that first detects faces, then classifies each detected face into one of seven emotion categories using the EMO-AffectNet model, all running on-device with NPU acceleration.

Prerequisites
A ZETIC Melange account with a Personal Key (sign up at melange.zetic.ai)
Python 3.8+ with torch, tf2onnx, and numpy installed
The Face Detection TFLite model
The EMO-AffectNet model weights
Android Studio or Xcode for mobile deployment
What is EMO-AffectNet?
EMO-AffectNet is a ResNet-50 based deep convolutional neural network trained for facial emotion recognition. It classifies faces into 7 emotion categories: Angry, Disgust, Fear, Happy, Neutral, Sad, and Surprise.

Model on Hugging Face: face_emotion_recognition
Model Pipelining
For accurate emotion recognition, we need to first detect the face region and then pass the cropped face image to the emotion model. The pipeline consists of:

Face Detection: Use the Face Detection model to accurately detect face regions in the image. Extract the face area from the original image.
Face Emotion Recognition: Input the extracted face image into the EMO-AffectNet model to classify the emotion.
Step 1: Prepare the Models
We prepared pre-built models for you — you can skip Steps 1–2 and jump straight to Step 3 using these models from the Melange Dashboard:

google/MediaPipe-Face-Detection
ElenaRyumina/FaceEmotionRecognition
Face Detection Model
Convert the Face Detection TFLite model to ONNX format:


pip install tf2onnx
python -m tf2onnx.convert --tflite face_detection_short_range.tflite --output face_detection_short_range.onnx --opset 13
Face Emotion Recognition Model
Export the EMO-AffectNet model using PyTorch Exported Program. You can find the ResNet50 class here.


import torch
import torch.nn as nn
import numpy as np
emo_affectnet = ResNet50(7, channels=3)
emo_affectnet.load_state_dict(torch.load('FER_static_ResNet50_AffectNet.pt'))
emo_affectnet.eval()
model_cpu = emo_affectnet.cpu()
exported_model = torch.export.export(model_cpu, (cur_face,))
np_cur_face = cur_face.detach().numpy()
np.save("data/cur_face.npy", np_cur_face)
output_model_path = "models/FER_static_ResNet50_AffectNet.pt2"
torch.export.save(exported_model, output_model_path)
Step 2: Generate Melange Model Keys
Upload both models and their inputs via the Melange Dashboard:

Face detection model face_detection_short_range.onnx with input input.npy
Emotion recognition model FER_static_ResNet50_AffectNet.pt2 with input input.npy
Step 3: Implement ZeticMLangeModel
Android (Kotlin)
iOS (Swift)
For detailed application setup, please follow the Android Integration Guide guide.


val faceEmotionRecognitionModel = ZeticMLangeModel(this, PERSONAL_KEY, "ElenaRyumina/FaceEmotionRecognition")
val pixels: FloatArray = preprocess(croppedFaceBitmap)
val inputs = arrayOf(
    Tensor.of(
        data = pixels,
        dataType = DataType.Float32,
        shape = intArrayOf(1, 3, 224, 224),
    )
)
val outputs = faceEmotionRecognitionModel.run(inputs)
Step 4: Use the Feature Extractors
We provide Face Detection and Face Emotion Recognition feature extractors as Android and iOS modules.

The Face Emotion Recognition feature extractor extension will be released as an open-source repository soon.

Android (Kotlin)
iOS (Swift)

// (0) Initialize Face Emotion Recognition wrapper
val feature = FaceEmotionRecognitionWrapper()
// (1) Preprocess bitmap and get processed float array
val inputs = feature.preprocess(bitmap)
// ... run model ...
// (2) Postprocess to bitmap
val resultBitmap = feature.postprocess(outputs)
Complete Face Emotion Recognition Pipeline Implementation
The complete implementation requires pipelining two models: Face Detection followed by Face Emotion Recognition.

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
Step 2: Face Emotion Recognition


// (0) Initialize face emotion recognition model
val faceEmotionRecognitionModel = ZeticMLangeModel(this, PERSONAL_KEY, "ElenaRyumina/FaceEmotionRecognition")
val faceEmotionRecognition = FaceEmotionRecognitionWrapper()
// (1) Preprocess with detected face regions
val faceEmotionRecognitionInputs = faceEmotionRecognition.preprocess(bitmap, faceDetectionPostprocessed)
// (2) Run face emotion recognition model
val faceEmotionRecognitionOutputs = faceEmotionRecognitionModel.run(faceEmotionRecognitionInputs)
// (3) Postprocess to get emotions
val faceEmotionRecognitionPostprocessed = faceEmotionRecognition.postprocess(faceEmotionRecognitionOutputs)
Conclusion
With ZETIC Melange, building multi-model pipelines for on-device AI is simple and efficient. The Face Detection to Face Emotion Recognition pipeline demonstrates how you can construct straightforward model chains for real-time facial analysis with NPU acceleration.

We are continually uploading new models to our examples and HuggingFace page.