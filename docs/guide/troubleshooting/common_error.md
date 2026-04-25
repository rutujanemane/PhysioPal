Common Errors
Solutions to the most common ZETIC Melange integration errors.

This page covers the most frequently encountered errors when integrating ZETIC Melange, along with their causes and solutions.

1. Model Key Not Found / Authentication Failure
Symptoms:

RuntimeException: Model not found (Android)
Error: Failed to download model (iOS)
HTTP 401 or 403 errors in logs
Cause: The model key or personal key is invalid, expired, or does not match.

Solutions:

Verify that your personal key is correct. Copy it directly from the Melange Dashboard.
Verify that your model key matches an existing compiled model. The key format is typically Username/ModelName (e.g., Steve/YOLOv11_comparison).
Ensure the model compilation has completed successfully on the dashboard before attempting to use the key.
Check that your device has network connectivity. The SDK needs to download the model binary on first use.
The Melange Dashboard provides ready-to-use source code with your keys already pre-filled. Use the copy button to avoid typos.

2. Input Shape Mismatch
Symptoms:

RuntimeException: Input shape mismatch (Android)
Runtime crash or unexpected output values
Model returns all zeros or NaN values
Cause: The input tensor dimensions or data type do not match what the model expects.

Solutions:

Check the model's expected input shape on the Melange Dashboard or in the model's documentation.
Ensure your input tensor has the correct number of dimensions. For example, YOLOv11 expects [1, 3, 640, 640] (batch, channels, height, width).
Verify the data type matches (typically Float32).
Make sure pixel values are normalized correctly (usually 0.0 to 1.0 for vision models).

// Common mistake: forgetting to add the batch dimension
// Wrong: shape [3, 640, 640]
// Correct: shape [1, 3, 640, 640]
Different models expect different input formats. Some models use NCHW layout (batch, channels, height, width) while others use NHWC (batch, height, width, channels). Check your model's specification.

3. JNI / Library Loading Failure (Android)
Symptoms:

java.lang.UnsatisfiedLinkError: dlopen failed
java.lang.UnsatisfiedLinkError: couldn't find native library
App crashes immediately on ZeticMLangeModel initialization
Cause: The native C++ NPU driver libraries are not being extracted correctly from the APK. This happens when the useLegacyPackaging flag is missing from your Gradle configuration.

Solution:

Add the following to your app-level build.gradle:

Groovy
Kotlin DSL

android {
    ...
    packagingOptions {
        jniLibs {
            useLegacyPackaging true
        }
    }
}
After adding this, perform a clean build (Build then Clean Project, then Rebuild Project).

This setting tells the Android build system to extract native libraries from the APK instead of loading them compressed. Melange's NPU drivers require this to function correctly.

4. NPU Not Available / Falls Back to CPU
Symptoms:

Inference works but is slower than expected
Log messages indicating CPU fallback: "NPU not available, falling back to CPU"
No performance improvement compared to standard frameworks
Cause: The device's NPU is either not supported, not available, or the model was not compiled with NPU targets for the device's chipset.

Solutions:

Check device compatibility. Not all Android devices have accessible NPUs. Melange supports Qualcomm Snapdragon (HTP/DSP), MediaTek (APU), Samsung Exynos (DSP), and Apple Neural Engine. Older or budget devices may not have NPU hardware.
Verify the model was compiled with NPU targets. On the Melange Dashboard, check that your model's compilation includes NPU-optimized binaries for your target device's chipset.
Use a physical device. Emulators and simulators do not have NPU hardware. Always test on a real device.
Check for driver availability. Some devices require specific system library versions for NPU access. Ensure your device's firmware is up to date.
Even when the NPU is not available, Melange will still run inference using CPU fallback. Your app will work correctly, just without the NPU performance boost.

5. Model Conversion Failure (Unsupported Operations)
Symptoms:

Model upload fails on the Melange Dashboard
Dashboard reports: "Unsupported operation" or "Conversion failed"
Compilation completes but produces incorrect results
Cause: The model contains operations that are not yet supported by the Melange compiler or cannot be mapped to NPU instructions.

Solutions:

Check supported formats. Melange supports:
PyTorch Exported Program (.pt2)
ONNX Model (.onnx)
Simplify the ONNX model. Use onnx-simplifier to reduce complex subgraphs:

pip install onnxsim
onnxsim input_model.onnx output_model.onnx
Check the ONNX opset version. Export with a commonly supported opset (opset 12 is recommended):

model.export(format="onnx", opset=12, simplify=True)
Avoid dynamic shapes. Export with static input dimensions:

model.export(format="onnx", dynamic=False, imgsz=640)
Contact support. If you encounter unsupported operations, reach out to contact@zetic.ai with your model file. The team is continuously expanding operation support.
For the most reliable conversion, export your model to ONNX format with opset=12, simplify=True, and dynamic=False.

Still Having Issues?
If your issue is not listed above:

Check the platform-specific troubleshooting guides: Android Issues and iOS Issues
See the full list of Error Codes for detailed error descriptions
Visit the FAQ for general questions
Join the Discord community for real-time help
Email contact@zetic.ai for technical support