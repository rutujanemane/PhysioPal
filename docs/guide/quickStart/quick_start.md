Quick Start: Your First Inference in 5 Minutes
Get your first on-device AI inference running in 5 minutes with ZETIC Melange.

Get a working on-device AI inference running on your phone in under 5 minutes. No account required for the demo.

What You'll Build
By the end of this guide, you will have a working app that runs YOLOv11 object detection directly on your device's NPU. The model runs entirely on-device with zero cloud dependency.

No Account Required

We provide a pre-configured demo model key Steve/YOLOv11_comparison so you can try Melange immediately. No sign-up, no dashboard, no waiting.

Prerequisites
Android (Kotlin)
iOS (Swift)
Android Studio Arctic Fox or later
A physical Android device (emulators do not have NPU hardware)
Minimum SDK 24 (Android 7.0)
Option A: Run the Demo Model (Recommended)
Use the pre-configured YOLOv11 model to get started immediately.

Add the SDK
Android (Kotlin)
iOS (Swift)
Add the Melange dependency to your app-level build.gradle:


// build.gradle (app level)
android {
    ...
    packagingOptions {
        jniLibs {
            useLegacyPackaging true
        }
    }
}
dependencies {
    implementation("com.zeticai.mlange:mlange:1.6.1+")
}
The useLegacyPackaging true setting is required. Without it, the native NPU drivers will not load correctly and you will get a JNI library loading error.

Initialize and Run Inference
Android (Kotlin)
iOS (Swift)

// MainActivity.kt
val model = ZeticMLangeModel(this, PERSONAL_KEY, "Steve/YOLOv11_comparison")
val outputs = model.run(inputs)
Replace PERSONAL_KEY with any string for the demo (e.g., "demo"), and prepare your inputs as an Array<Tensor> matching the model's expected input shape.

Build and Run
Build the project and run it on your physical device. The first launch will download and cache the optimized model binary for your specific hardware. Subsequent launches will be instant.

Option B: Use Your Own Model
Ready to deploy your own model? Follow these steps:

Prepare your model
Export to ONNX or PyTorch Exported Program format. See Model Preparation.

Upload and compile
Use the Melange Dashboard to upload your model and get your keys.

Integrate
Replace the demo model name with your own MODEL_NAME and PERSONAL_KEY.

What Just Happened?
When you ran the code above, Melange executed a three-step workflow behind the scenes:

Model Download: The SDK fetched the pre-compiled, hardware-optimized model binary from the Melange CDN. This binary was already compiled for your specific device's NPU during the model preparation phase.

NPU Context Creation: Melange initialized the appropriate hardware accelerator (Qualcomm HTP, MediaTek APU, Samsung DSP, or Apple Neural Engine) and loaded the model into NPU memory using zero-copy memory mapping.

Inference Execution: Your input tensor was processed through the NPU-accelerated computation graph, and the output tensor was returned. No data left the device.