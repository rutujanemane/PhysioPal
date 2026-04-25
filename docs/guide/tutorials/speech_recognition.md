Speech Recognition (Whisper)
Run OpenAI Whisper speech-to-text on-device with ZETIC Melange.

Build an on-device speech recognition application using OpenAI's Whisper model with ZETIC Melange. This tutorial covers splitting Whisper into encoder and decoder components, deploying them to Melange, and running the full speech-to-text pipeline on Android and iOS.

What You Will Build
An on-device speech-to-text application that processes audio through Whisper's three-component architecture (Feature Extractor, Encoder, Decoder) with NPU acceleration for real-time transcription.

Prerequisites
A ZETIC Melange account with a Personal Key (sign up at melange.zetic.ai)

Python 3.10+ with the required Python packages installed:


pip install torch transformers numpy
Android Studio or Xcode for mobile deployment

What is Whisper?
Whisper is a state-of-the-art speech recognition model developed by OpenAI that offers:

Multilingual support: Recognizes speech in multiple languages
Multiple capabilities: Performs speech recognition, language detection, and translation
Open source: Available through Hugging Face
Architecture Overview
The Whisper implementation consists of three main components:

Feature Extractor: Processes raw audio into Mel Spectrogram features
Encoder: Processes Mel Spectrogram to generate audio embeddings
Decoder: Generates text tokens from the audio embeddings
Step 1: Prepare Sample Inputs for Exporting
We provide pre-built models for you — you can skip Steps 1–5 and jump straight to Step 6 using these models from the Melange Dashboard:

OpenAI/whisper-tiny-encoder
OpenAI/whisper-tiny-decoder
To convert the model for deployment, we need to export the PyTorch model with sample inputs that match the expected tensor shapes.


import numpy as np
import torch
from transformers import WhisperForConditionalGeneration
model_name = "openai/whisper-tiny"
model = WhisperForConditionalGeneration.from_pretrained(model_name)
# Whisper expects 30 s of 80-bin log-mel features: (batch, 80, 3000).
# Exporting only needs the right shape/dtype — the values don't matter.
input_features = torch.randn(1, 80, 3000)
MAX_TOKEN_LENGTH = model.config.max_target_positions
dummy_decoder_input_ids = torch.tensor([[0 for _ in range(MAX_TOKEN_LENGTH)]])
dummy_encoder_hidden_states = torch.randn(1, 1500, model.config.d_model).float()
dummy_decoder_attention_mask = torch.ones_like(dummy_decoder_input_ids)
Step 2: Export Encoder to Exported Program
Wrap and export the Whisper encoder:


from transformers import WhisperModel
import torch.nn as nn
class WhisperEncoderWrapper(nn.Module):
    def __init__(self, whisper_model):
        super().__init__()
        self.enc = whisper_model.model.encoder
    def forward(self, input_features):
        return self.enc(input_features=input_features, return_dict=False)[0]
with torch.no_grad():
    encoder = WhisperEncoderWrapper(model).eval()
    exported_encoder = torch.export.export(encoder, (input_features,))
    torch.export.save(exported_encoder, "whisper_encoder.pt2")
Step 3: Export Decoder to Exported Program
Wrap and export the Whisper decoder:


class WhisperDecoderWrapper(nn.Module):
    def __init__(self, whisper_model):
        super().__init__()
        self.decoder = whisper_model.model.decoder
        self.proj_out = whisper_model.proj_out
    def forward(self, input_ids, encoder_hidden_states, decoder_attention_mask):
        hidden = self.decoder(
            input_ids=input_ids,
            encoder_hidden_states=encoder_hidden_states,
            attention_mask=decoder_attention_mask,
            use_cache=False,
            return_dict=False,
        )[0]
        return self.proj_out(hidden)
with torch.no_grad():
    decoder = WhisperDecoderWrapper(model).eval()
    exported_decoder = torch.export.export(
        decoder,
        (dummy_decoder_input_ids, dummy_encoder_hidden_states, dummy_decoder_attention_mask),
    )
    torch.export.save(exported_decoder, "whisper_decoder.pt2")
Step 4: Save Input Samples
Save all input tensors as .npy files for model upload:


import numpy as np
# Save encoder inputs
np.save("whisper_input_features.npy", input_features.cpu().numpy())
# Save decoder inputs
np.save(
    "whisper_decoder_input_ids.npy",
    dummy_decoder_input_ids.cpu().numpy().astype(np.int64),
)
np.save(
    "whisper_encoder_hidden_states.npy",
    dummy_encoder_hidden_states.cpu().numpy().astype(np.float32),
)
np.save(
    "whisper_decoder_attention_mask.npy",
    dummy_decoder_attention_mask.cpu().numpy().astype(np.int64),
)
Step 5: Generate Melange Models
Upload both models and their inputs via the Melange Dashboard:

Encoder model whisper_encoder.pt2 with input whisper_input_features.npy
Decoder model whisper_decoder.pt2 with inputs (in order): whisper_decoder_input_ids.npy, whisper_encoder_hidden_states.npy, whisper_decoder_attention_mask.npy
The decoder model requires three input files. Make sure to provide them in the correct order as shown above. See Supported Formats for details on input ordering.

Step 6: Implement ZeticMLangeModel
Android (Kotlin)
iOS (Swift)
For detailed application setup, please follow the Android Integration Guide guide.


val encoderModel = ZeticMLangeModel(this, PERSONAL_KEY, "OpenAI/whisper-tiny-encoder")
val decoderModel = ZeticMLangeModel(this, PERSONAL_KEY, "OpenAI/whisper-tiny-decoder")
val inputFeatures: FloatArray = whisper.melSpectrogram(audioData)
val encoderInputs = arrayOf(
    Tensor.of(inputFeatures, DataType.Float32, intArrayOf(1, 80, 3000))
)
val encoderOutputs = encoderModel.run(encoderInputs)
val encoderHidden = encoderOutputs[0]
val inputIds = LongArray(1 * 448)
val attnMask = LongArray(1 * 448) { 1L }
val decoderInputs = arrayOf(
    Tensor.of(inputIds, DataType.Int64, intArrayOf(1, 448)),
    encoderHidden,
    Tensor.of(attnMask, DataType.Int64, intArrayOf(1, 448)),
)
val decoderOutputs = decoderModel.run(decoderInputs)
Step 7: Use the Whisper Feature Wrapper
The WhisperFeatureWrapper handles audio-to-Mel-Spectrogram conversion and token decoding.

You can find WhisperDecoder and WhisperEncoder implementations in ZETIC Melange apps.

Complete Speech Recognition Implementation
Android (Kotlin)
iOS (Swift)

// Initialize components
val whisper = WhisperFeatureWrapper()
val encoder = ZeticMLangeModel(this, PERSONAL_KEY, "OpenAI/whisper-tiny-encoder")
val decoder = ZeticMLangeModel(this, PERSONAL_KEY, "OpenAI/whisper-tiny-decoder")
// Process audio
val features = whisper.process(audioData)
// Run encoder
encoder.process(features)
// Generate tokens using decoder
val generatedIds = decoder.generateTokens(outputs)
// Convert tokens to text
val text = whisper.decodeToken(generatedIds.toIntArray(), true)
Conclusion
With ZETIC Melange, implementing on-device speech recognition with NPU acceleration is straightforward and efficient. Whisper provides robust multilingual speech recognition and translation capabilities. The three-component pipeline (Feature Extractor, Encoder, Decoder) is cleanly abstracted through the Melange SDK.

We are continuously adding new models to our examples and HuggingFace page.