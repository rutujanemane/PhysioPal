rerequisites
What you need before getting started with ZETIC Melange.

Before you start building with ZETIC Melange, make sure you have the following tools and requirements ready.

Development Environment
Android (Kotlin)
iOS (Swift)
Requirement	Details
IDE	Android Studio Arctic Fox or later
Physical device	Required: emulators do not have NPU hardware
Minimum SDK	API 24 (Android 7.0)
Build system	Gradle with Groovy or Kotlin DSL
Language	Kotlin (recommended) or Java
Melange Account
Sign up at melange.zetic.ai using your Google or GitHub account. It is free and requires no credit card.
Generate a Personal Key from the Dashboard under Settings then Personal Key.
For the quick start demo, you can skip account setup and use the pre-configured demo model key Steve/YOLOv11_comparison.

Model Preparation (Optional)
If you plan to deploy your own model, you will also need:

A trained model in a supported format: .pt2 (recommended) or .onnx
Sample inputs saved as NumPy .npy files
Network Access
The Melange SDK requires internet access for:

Initial model download: The optimized model binary is downloaded on first use and cached locally.
Dashboard access: For model management and key generation.
After the initial download, inference runs entirely offline on-device.