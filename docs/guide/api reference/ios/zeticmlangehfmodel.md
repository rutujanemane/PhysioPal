ZeticMLangeHFModel
API reference for loading Hugging Face models on iOS with ZeticMLangeHFModel.

This page reflects ZeticMLange iOS 1.6.0.

The ZeticMLangeHFModel class allows you to load and run models directly from Hugging Face repositories. No personal key or model key is needed: just the repository ID.

Import

import ZeticMLange
Initializer

init(_ repoId: String) async throws
Parameter	Type	Description
repoId	String	The Hugging Face repository ID (e.g., "zetic-ai/yolov11n").

let model = try await ZeticMLangeHFModel("zetic-ai/yolov11n")
The initializer is asynchronous (async) because it downloads, compiles, and caches the model on first use. Subsequent initializations use the cached binary and are fast. Must be called within an async context.

Methods
run(inputs:)
Executes inference on the loaded model.


func run(inputs: [Tensor]) throws -> [Tensor]
Parameter	Type	Description
inputs	[Tensor]	Input tensors matching the model's expected shapes.
Returns: [Tensor]: The model's output tensors.

Throws: An error if input shapes do not match or inference fails.


let outputs = try model.run(inputs: [inputTensor])
Full Working Example

import ZeticMLange
class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            do {
                // Initialize from Hugging Face (downloads on first use)
                let model = try await ZeticMLangeHFModel("zetic-ai/yolov11n")
                // Prepare inputs
                let inputs: [Tensor] = [imageTensor] // Your preprocessed input
                // Run inference
                let outputs = try model.run(inputs: inputs)
                // Process outputs
                for output in outputs {
                    // Handle each output tensor
                }
            } catch {
                print("Melange error: \(error)")
            }
        }
    }
}
Comparison with ZeticMLangeModel
Feature	ZeticMLangeHFModel	ZeticMLangeModel
Authentication	No keys needed	Requires Personal Key
Model source	Hugging Face repo ID	Melange Dashboard
Initialization	async (download + compile)	Synchronous (pre-compiled)
First-run speed	Slower (download + compile)	Faster (pre-compiled)
Best for	Prototyping, public models	Production, custom models