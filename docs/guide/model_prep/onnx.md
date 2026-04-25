
ONNX Models
Convert TensorFlow, Keras, and scikit-learn models to ONNX for ZETIC Melange.

ONNX (Open Neural Network Exchange) is a widely supported format that enables you to use models from PyTorch, TensorFlow, Keras, scikit-learn, and other frameworks with ZETIC Melange.

PyTorch (Recommended)
When starting from a torch.nn.Module, exporting directly with torch.onnx produces the cleanest ONNX graph for Melange. Prefer this path over multi-step conversions (for example, PyTorch → TensorFlow → ONNX), which often introduce extra ops and shape mismatches.

If you're going from PyTorch straight to Melange and don't need ONNX for other tooling, the PyTorch Exported Program (.pt2) path is simpler. Use ONNX when you specifically need ONNX.


import torch
# Load your model
torch_model = YourModel()  # Replace with your model class
torch_model.eval()
# Prepare a sample input that matches your model's expected shape
sample_input = torch.randn(1, 3, 224, 224)
# Export to ONNX
torch.onnx.export(
    torch_model,
    (sample_input,),
    "model.onnx",
)
For more details, see the torch.onnx documentation.

TensorFlow / Keras
Use tf2onnx to convert TensorFlow and Keras models to ONNX format.

Installation

pip install tf2onnx
From a SavedModel Directory

python -m tf2onnx.convert --saved-model saved_model_dir --output model.onnx --opset 13
From a Keras Model (Python API)

import tensorflow as tf
import tf2onnx
# Load your model
model = tf.keras.models.load_model("my_model.h5")
# Convert to ONNX
spec = (tf.TensorSpec((1, 224, 224, 3), tf.float32, name="input"),)
output_path = "model.onnx"
model_proto, _ = tf2onnx.convert.from_keras(model, input_signature=spec, output_path=output_path)
From a TFLite Model

python -m tf2onnx.convert --tflite model.tflite --output model.onnx --opset 13
We recommend using opset 12 or higher for the best compatibility with Melange's compiler.

Scikit-Learn
Use skl2onnx to convert scikit-learn models to ONNX format.

Installation

pip install skl2onnx
Conversion

from skl2onnx import convert_sklearn
from skl2onnx.common.data_types import FloatTensorType
initial_type = [('float_input', FloatTensorType([None, 4]))]
onx = convert_sklearn(model, initial_types=initial_type)
with open("model.onnx", "wb") as f:
    f.write(onx.SerializeToString())
Saving Sample Inputs
After converting your model, save sample inputs as NumPy files for upload:


import numpy as np
# Create a sample input matching your model's expected shape
sample_input = np.random.randn(1, 224, 224, 3).astype(np.float32)
np.save("input.npy", sample_input)
Simplifying ONNX Models
If you encounter conversion issues, use onnx-simplifier to reduce complex subgraphs:


pip install onnxsim
onnxsim input_model.onnx output_model.onnx
Simplifying your ONNX model can resolve many compilation issues by removing redundant operations and folding constant expressions.

Other Frameworks
For other frameworks that support ONNX export, refer to the ONNX Tutorials.

Next Steps