PyTorch Export
Export PyTorch models for ZETIC Melange using Exported Program.

This guide covers how to export PyTorch models for use with ZETIC Melange.

PyTorch Exported Program (.pt2)
PyTorch 2.0+ introduces the torch.export API, which produces a fully serialized computation graph. This is the recommended format for Melange.

PyTorch Exported Program requires PyTorch >= 2.9. Earlier versions may produce incompatible graphs or fail during export. Verify your version with python -c "import torch; print(torch.__version__)".


import torch
import numpy as np
# Load your model
torch_model = YourModel()  # Replace with your model class
torch_model.eval()
# Prepare sample inputs
sample_input = torch.randn(1, 3, 224, 224)  # Match your model's input shape
# (1) Export the model
exported_program = torch.export.export(torch_model, (sample_input,))
torch.export.save(exported_program, "model.pt2")
# (2) Save your sample inputs for Melange
np_input = sample_input.detach().numpy()
np.save("input.npy", np_input)
For more details, refer to the torch.export documentation.

Saving Inputs
Both export methods require saving sample inputs as NumPy .npy files. These inputs serve two purposes:

Shape definition: They tell Melange the exact tensor dimensions to compile for.
Validation: They are used during the compilation process to verify correctness.
If your model has multiple inputs, save each one separately:


np.save("input_0.npy", input_tensor_0.detach().numpy())
np.save("input_1.npy", input_tensor_1.detach().numpy())
The order of inputs matters. See Supported Formats for details on input ordering.

Next Steps
Supported Formats: Verify input order and shapes
Web Dashboard: Upload your exported model