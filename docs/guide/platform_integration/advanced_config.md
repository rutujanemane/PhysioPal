Advanced Configuration
Advanced Melange configuration options for iOS.

This guide covers advanced configuration options available in the Melange iOS SDK.

Inference Mode Selection
Melange supports multiple inference modes to balance speed and accuracy. By default, the SDK uses RUN_AUTO, which selects the fastest configuration while maintaining high-quality results (SNR > 20dB).


// Default (Auto): balanced speed and accuracy
let modelDefault = try ZeticMLangeModel(
    personalKey: PERSONAL_KEY,
    name: MODEL_NAME,
    modelMode: .RUN_AUTO
)
// Speed-first: minimum latency
let modelFast = try ZeticMLangeModel(
    personalKey: PERSONAL_KEY,
    name: MODEL_NAME,
    modelMode: .RUN_SPEED
)
// Accuracy-first: maximum precision
let modelAccurate = try ZeticMLangeModel(
    personalKey: PERSONAL_KEY,
    name: MODEL_NAME,
    modelMode: .RUN_ACCURACY
)
For a detailed explanation of each mode, see Inference Mode Selection.

Model Version Pinning
By default, the SDK loads the latest model version. You can pin to a specific version for production stability:


let model = try ZeticMLangeModel(
    personalKey: PERSONAL_KEY,
    name: MODEL_NAME,
    version: 2  // Pin to a specific version
)
Multi-Model Pipelines
For applications that chain multiple models, initialize each model separately and pass outputs as inputs:


// Initialize pipeline models
let detectionModel = try ZeticMLangeModel(personalKey: PERSONAL_KEY, name: "detection_model")
let classificationModel = try ZeticMLangeModel(personalKey: PERSONAL_KEY, name: "classification_model")
// Run pipeline
let detectionOutputs = try detectionModel.run(inputs: inputs)
// Process detection outputs and prepare classification inputs
let classificationOutputs = try classificationModel.run(inputs: classificationInputs)
For a complete pipeline example, see Multi-Model Pipelines.

Error Handling
Wrap model operations in do-catch blocks to handle initialization and inference errors gracefully:


do {
    let model = try ZeticMLangeModel(personalKey: PERSONAL_KEY, name: MODEL_NAME)
    let outputs = try model.run(inputs: inputs)
} catch {
    print("Melange error: \(error)")
    // Handle error: network failure, invalid key, shape mismatch, etc.
}