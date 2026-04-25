Upload Your Model
Upload and deploy your own AI model with ZETIC Melange.

Ready to deploy your own model? This guide walks you through preparing and uploading your custom model to Melange.

Step 1: Prepare Your Model
Export your model to a supported format:

PyTorch Exported Program (.pt2): Recommended
ONNX (.onnx): Supported
Save sample inputs as NumPy .npy files alongside your model.

For detailed export instructions, see Model Preparation.

Step 2: Upload Your Model
Log in to the Melange Dashboard.
Create a new repository by clicking the + button.
Click Upload and provide your model file and input files.
Wait for the model to compile. Status will progress from Converting to Optimizing to Ready.
For details, see Web Dashboard.

Ensure your input tensor shapes exactly match the shapes of the .npy files you upload. Melange compiles models with fixed input shapes for NPU optimization.