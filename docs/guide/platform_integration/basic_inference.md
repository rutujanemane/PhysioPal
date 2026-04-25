Basic Inference
Run your first AI model inference on iOS with ZETIC Melange.

This guide shows how to run inference on iOS after completing the SDK setup.

Prerequisites
Melange SDK added to your project (iOS Setup)
A compiled model on the Melange Dashboard
Your Personal Key and Model Key
Running Inference

import ZeticMLange
// (1) Load model
// This handles model download (if needed) and Neural Engine context creation
let model = try ZeticMLangeModel(personalKey: PERSONAL_KEY, name: MODEL_NAME)
// (2) Prepare model inputs
// Ensure input shapes match your model's requirement (e.g., Float32 arrays)
let inputs: [Tensor] = [] // Prepare your inputs
// (3) Run Inference
// Executes the fully automated hardware graph.
// No manual delegate configuration or memory syncing required.
let outputs = try model.run(inputs: inputs)
Understanding the Flow
Model Download: On first use, the SDK downloads the pre-compiled, hardware-optimized model binary from the Melange CDN. This binary is optimized for Apple Neural Engine.
Neural Engine Context Creation: Melange initializes the Neural Engine and loads the model into NPU memory using zero-copy memory mapping.
Inference Execution: Your input tensor is processed through the NPU-accelerated computation graph, and the output tensor is returned. No data leaves the device.
Always ensure your input tensor shapes exactly match what the model expects. A shape mismatch will throw an error. Check the model's input specification on the Melange Dashboard.

Full Working Example

import ZeticMLange
class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            // Load model
            let model = try ZeticMLangeModel(personalKey: PERSONAL_KEY, name: "Steve/YOLOv11_comparison")
            // Prepare inputs
            let inputs: [Tensor] = [] // Prepare your inputs
            // Run inference
            let outputs = try model.run(inputs: inputs)
            // Process outputs
            for output in outputs {
                // Process each output tensor
            }
        } catch {
            print("Melange error: \(error)")
        }
    }
}