Object Detection (YOLOv8 / YOLOv11)
Build on-device object detection with YOLOv8/YOLOv11 using ZETIC Melange.

Build a real-time on-device object detection application using YOLOv8 or YOLOv11 with ZETIC Melange. This tutorial walks you through exporting the model, deploying it to Melange, and running inference on Android and iOS.

We provide the source code for the YOLOv11 demo application for both Android and iOS. If the input model key is changed to YOLOv8, you can experience YOLOv8 as well.

What You Will Build
An on-device object detection application that identifies and localizes objects in real-time camera frames using YOLOv8 or YOLOv11 models accelerated by NPU hardware.

Prerequisites
A ZETIC Melange account with a Personal Key (sign up at melange.zetic.ai)
Python 3.8+ with ultralytics, opencv-python, and numpy installed
Android Studio or Xcode for mobile deployment
What is YOLOv11?
YOLOv11 is the latest version of the acclaimed real-time object detection and image segmentation model by Ultralytics.

Official documentation: YOLOv11 Docs
Currently, only detector mode is supported. Additional features will be supported later.
Step 1: Export the Model
We prepared pre-built models for you — you can skip the export step and jump straight to Step 3:

YOLOv11: Steve/YOLOv11_comparison
YOLOv8: Ultralytics/YOLOv8n — browse on the Melange Dashboard
Export the YOLOv11 model to ONNX format. You will get yolo11n.onnx after running this script:


from ultralytics import YOLO
import torch
model = YOLO("yolo11n.pt")
model.export(format="onnx", opset=12, simplify=True, dynamic=False, imgsz=640)
Step 2: Prepare Input Sample
Prepare your input from an image file:


import cv2
import numpy as np
def preprocess_image(image_path, target_size=(640, 640)):
    img = cv2.imread(image_path)
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img = cv2.resize(img, target_size)
    img = img.astype(np.float32) / 255.0
    img = np.transpose(img, (2, 0, 1))
    img = np.expand_dims(img, axis=0)
    return img
Step 3: Generate Melange Model
Upload the model and inputs via the Melange Dashboard:

Model file: yolo11n.onnx
Input: images.npy
Step 4: Implement ZeticMLangeModel
Initialize the Melange model in your mobile application and run inference.

Android (Kotlin)
iOS (Swift)
For detailed application setup, please follow the Android Integration Guide guide.


val model = ZeticMLangeModel(this, PERSONAL_KEY, MODEL_NAME)
val pixels: FloatArray = preprocess(bitmap)
val inputs = arrayOf(
    Tensor.of(
        data = pixels,
        dataType = DataType.Float32,
        shape = intArrayOf(1, 3, 640, 640),
    )
)
val outputs = model.run(inputs)
Step 5: Use the YOLOv8 Pipeline
We provide a YOLOv8 feature extractor as an Android and iOS module. This feature extractor works with both YOLOv8 and YOLOv11 models.

We are using the Melange extension module here.

Android (Kotlin)
iOS (Swift)

val model = ZeticMLangeModelWrapper(this, PERSONAL_KEY, MODEL_NAME)
val pipeline = ZeticMLangePipeline(
    feature = YOLOv8(this, model = model),
    inputSource = CameraSource(this, preview.holder, preferredSize),
)
pipeline.loop { result ->
    // visualize YOLO result here
}
Conclusion
With ZETIC Melange, you can build on-device AI object detection applications with NPU acceleration in minutes. We continuously upload models to our examples and HuggingFace page.

