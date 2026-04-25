Benchmarks
Real-world performance benchmarks for ZETIC Melange across 200+ devices.

Melange delivers hardware-accelerated inference by automatically selecting the optimal backend (CPU, GPU, or NPU) for each device. The benchmarks on this page demonstrate the real-world performance gains achieved through this approach.

Benchmark Methodology
All benchmarks are measured on a physical device farm of 200+ real devices, not emulators or simulators. This ensures the numbers reflect actual production performance, accounting for real-world factors like driver fragmentation, thermal throttling, and memory constraints.

Each model is profiled across CPU, GPU, and NPU backends on every device. Melange then selects the fastest backend automatically at runtime.

For a deeper look at how Melange profiles and selects the optimal model binary per device, see Performance-Adaptive Deployment.

YOLOv11 Object Detection
The following table shows inference latency for YOLOv11 across a representative set of devices. The Speedup column compares the fastest accelerated backend (GPU or NPU) against the CPU baseline.

Device	SoC	CPU	GPU	NPU	Speedup
Galaxy A34	MediaTek	172.08 ms	96.38 ms	249.41 ms	x1.79
Galaxy S22 5G	Qualcomm	79.76 ms	36.99 ms	8 ms	x9.97
Galaxy S23	Qualcomm	89.56 ms	27.5 ms	5.24 ms	x17.09
Galaxy S24+	Qualcomm	60.43 ms	21.46 ms	3.92 ms	x15.42
Galaxy S25	Qualcomm	53.69 ms	17.22 ms	3.72 ms	x14.43
iPhone 12	Apple	123.12 ms	22.73 ms	3.51 ms	x35.08
iPhone 14	Apple	111.29 ms	15.75 ms	3.75 ms	x29.68
iPhone 15 Pro Max	Apple	96.36 ms	7.72 ms	2.05 ms	x47.00
iPhone 16	Apple	102.09 ms	7.9 ms	1.9 ms	x53.73
On some devices (e.g., Galaxy A34 with MediaTek SoC), the NPU backend is slower than GPU due to limited NPU driver support. Melange detects this automatically and routes inference to the faster backend.

Key Takeaways
NPU acceleration delivers up to 53x speedup over CPU on supported devices (iPhone 16).
Apple Neural Engine consistently outperforms all other NPU implementations, achieving sub-2ms inference on recent iPhones.
Qualcomm NPU shows strong performance on flagship devices (Galaxy S22 and later), with 8ms or faster inference.
MediaTek NPU support varies: Melange automatically falls back to GPU when NPU is slower, as seen on the Galaxy A34.
Full Benchmark Report
The complete benchmark report with additional devices, models, and detailed profiling data is available on the Melange Dashboard:

View YOLOv11 Benchmark Report

How to Read These Numbers
CPU: Inference using standard CPU execution. This is the baseline that any mobile device can run.
GPU: Inference using the device's GPU compute capabilities (Metal on iOS, OpenCL/Vulkan on Android).
NPU: Inference using the dedicated Neural Processing Unit (Neural Engine on iOS, Hexagon/APU on Android).
Speedup: Ratio of CPU latency to the fastest accelerated backend latency. Higher is better.
You can profile your own models across the full device farm by deploying through the Melange Dashboard. Melange automatically benchmarks and selects the optimal backend for each target device.