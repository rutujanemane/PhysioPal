Audio Classification (YAMNet)
Classify 521 audio event types on-device using YAMNet with ZETIC Melange.

Build an on-device audio classification application using YAMNet with ZETIC Melange. This tutorial walks you through converting the TensorFlow model, deploying it to Melange, and running inference on Android and iOS.

What You Will Build
An on-device audio classification application that identifies audio events from 521 categories in real time, using YAMNet accelerated by NPU hardware.

Prerequisites
A ZETIC Melange account with a Personal Key (sign up at melange.zetic.ai)
Python 3.8+ with tensorflow, tensorflow_hub, tf2onnx, and numpy installed
Android Studio or Xcode for mobile deployment
What is YAMNet?
YAMNet is a deep neural network that predicts audio events from the AudioSet-YouTube corpus.

Trained on the AudioSet dataset with 521 audio event classes
Model on TensorFlow Hub: YAMNet
Step 1: Convert YAMNet to ONNX
We provide a pre-built model for you — you can skip Steps 1–3 and jump straight to Step 4 using google/Sound Classification(YAMNET) from the Melange Dashboard.

Load the YAMNet model from TensorFlow Hub and convert it to ONNX format:


import tensorflow as tf
import tensorflow_hub as hub
import tf2onnx
import numpy as np
model = hub.load('https://tfhub.dev/google/yamnet/1')
concrete_func = model.signatures['serving_default']
input_shape = [1, 16000]
sample_input = np.random.randn(*input_shape).astype(np.float32)
input_tensor = tf.convert_to_tensor(waveform, dtype=tf.float32)
tf.saved_model.save(model, "yamnet_saved_model", signatures=concrete_func)
# python -m tf2onnx.convert --saved-model yamnet_saved_model --output yamnet.onnx --opset 13
Step 2: Prepare Sample Input
Generate a sample audio waveform to use as input for model deployment:


import numpy as np
sample_rate = 16000
duration = 1
waveform = np.sin(2 * np.pi * 440 * np.linspace(0, duration, sample_rate))
waveform = waveform.astype(np.float32)
waveform = np.expand_dims(waveform, axis=0)
np.save('waveform.npy', waveform)
Step 3: Generate Melange Model
Upload the model and inputs via the Melange Dashboard:

Model file: yamnet.onnx
Input: waveform.npy
Step 4: Implement ZeticMLangeModel
Android (Kotlin)
iOS (Swift)
For detailed application setup, please follow the Android Integration Guide guide.


val yamnetModel = ZeticMLangeModel(this, PERSONAL_KEY, "google/Sound Classification(YAMNET)")
val waveform: FloatArray = preprocess(audioData)
val inputs = arrayOf(
    Tensor.of(
        data = waveform,
        dataType = DataType.Float32,
        shape = intArrayOf(1, 16000),
    )
)
val outputs = yamnetModel.run(inputs)
Step 5: Preprocess and Postprocess Audio
We provide an audio feature extractor as an Android and iOS module for handling audio preprocessing and result interpretation.

Android (Kotlin)
iOS (Swift)

// (1) Preprocess audio data and get processed float array
val inputs = preprocess(audioData)
// ... run model ...
// (2) Postprocess model outputs
val results = postprocess(outputs)
Complete Audio Classification Implementation
Android (Kotlin)
iOS (Swift)

// (0) Initialize model
val yamnetModel = ZeticMLangeModel(this, PERSONAL_KEY, "google/Sound Classification(YAMNET)")
// (1) Preprocess audio
val inputs = preprocess(audioData)
// (2) Run model
val outputs = yamnetModel.run(inputs)
// (3) Postprocess results
val predictions = postprocess(outputs)
Conclusion
With ZETIC Melange, implementing on-device audio classification with NPU acceleration is straightforward and efficient. YAMNet provides robust audio event detection capabilities across 521 categories. The simple pipeline of audio preprocessing and classification makes it easy to integrate into your applications.

We are continuously adding new models to our examples and HuggingFace page.