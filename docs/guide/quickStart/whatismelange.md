What is Melange?
Learn what ZETIC Melange is, who it's for, and how it automates on-device AI deployment.

ZETIC Melange is the essential software infrastructure for automated on-device AI deployment. It bridges the gap between high-level AI development and low-level hardware complexity, making NPU utilization accessible to every developer.

The Problem
Deploying AI models to mobile devices with NPU acceleration is notoriously difficult:

Manual NPU optimization: Each chipset vendor (Qualcomm, MediaTek, Samsung, Apple) requires different SDKs, toolchains, and optimization strategies.
Cross-platform fragmentation: Android and iOS have fundamentally different hardware architectures, and even within Android, the NPU landscape is fragmented across hundreds of device models.
Months of engineering effort: Getting a model to run efficiently on a single NPU can take weeks. Supporting all target devices multiplies that effort.
The Solution: 3-Step Workflow
Melange reduces on-device AI deployment to three steps:

Upload
Provide your trained model in a supported format (ONNX or PyTorch Exported Program) along with sample input tensors. Upload via the web dashboard.

Benchmark
Melange automatically compiles your model for multiple NPU targets and runs it on a farm of 200+ physical devices. The system measures real latency, throughput, and accuracy to determine the optimal binary for every device model.

Deploy
Integrate the Melange SDK into your Android or iOS application. At runtime, the SDK automatically downloads and executes the best-performing model binary for the end user's specific device.

Who is Melange For?
Mobile AI engineers who need NPU acceleration without vendor-specific SDK expertise
ML teams shipping models to production mobile applications
Product teams that want on-device AI for privacy, latency, or cost reasons
Enterprises deploying AI across a diverse fleet of Android and iOS devices
Core Value Propositions
⚡
Automated NPU Acceleration
Abstracts the complexity of NPU execution. Delivers hardware-accelerated throughput without managing vendor-specific SDKs (Qualcomm QNN, MediaTek NeuroPilot, Samsung ENN, Apple Core ML).

🔄
End-to-End Deployment Pipeline
A single pipeline for all edge targets. Handles the complete lifecycle from graph optimization and quantization to on-device runtime execution.

🔗
Cross-Platform Hardware Abstraction
Write once, run optimally everywhere. Provides a unified API layer across fragmented mobile architectures including Snapdragon, MediaTek, Exynos, and Apple Neural Engine.

🚀
Production-Ready in Hours
Eliminates months of manual tuning. Replaces bespoke hardware integration with an automated compilation workflow that gets your model running on NPUs in hours, not months.