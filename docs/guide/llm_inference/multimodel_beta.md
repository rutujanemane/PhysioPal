Multimodal (Beta)
Feed pre-computed embeddings (e.g. audio encoder output) directly into the LLM decoder via runWithEmbeddings.

Multimodal embedding injection is Beta in ZeticMLange 1.7.0-beta.1. The API is stable for the audio path covered in the Qwen2.5-Omni tutorial but may evolve before general availability. Multimodal APIs throw on non-llama.cpp backends.

Why Embedding Injection?
Standard LLM inference takes text in (run(text)) and produces text out. For multimodal use cases — describing audio, answering questions about an image, reasoning over interleaved modalities — the input is not text. You instead have:

A modality-specific encoder (audio encoder, vision encoder, …) that outputs an [N, hidden_size] embedding sequence.
A standard LLM decoder (e.g. Qwen2.5-Omni 3B) that decodes a flat embedding sequence into text tokens.
The piece that connects the two is embedding injection: you build a flat embedding buffer that interleaves text-token embeddings (for the chat template, role markers, and any text portion of the user turn) with the encoder's modality embeddings, then submit that buffer to the decoder via runWithEmbeddings(...).

Core API
The multimodal API lives on ZeticMLangeLLMModel and is implemented only on the llama.cpp backend. Calling these methods on a different target throws a clear error.

Method	Purpose
runWithEmbeddings(embeddings)	Decode a flat embedding sequence. Buffer length must be a multiple of the model's embedding dimension; positions continue from the current KV cache so this composes with prior run() / runWithEmbeddings() turns.
tokenize(text, parseSpecial)	Tokenize text using the model's vocabulary. With parseSpecial = true, special tokens (e.g. <|audio_bos|>, <|im_start|>) become single tokens rather than being split by BPE.
tokenEmbeddings(tokenIds)	Look up per-token embeddings from the model's tok_embd tensor and return a flat [tokenIds.size * n_embd] buffer. Quantized rows are dequantized to float32.
specialTokenId(name)	Resolve a special-token surface form (e.g. "<|audio_bos|>") to its vocabulary id. Returns -1 if the model does not carry that token.
See the platform API references for exact signatures:

Android ZeticMLangeLLMModel
iOS ZeticMLangeLLMModel
The llm Variable
All code samples on this page assume llm is a loaded ZeticMLangeLLMModel instance, constructed once near app startup as you would for normal text inference. Replace the model name with the multimodal-capable checkpoint you want to drive (e.g. the Qwen2.5-Omni decoder for the audio path).

Android (Kotlin)
iOS (Swift)

import android.content.Context
import com.zeticai.mlange.core.model.llm.LLMModelMode
import com.zeticai.mlange.core.model.llm.ZeticMLangeLLMModel
val llm = ZeticMLangeLLMModel(
    context = context,
    personalKey = PERSONAL_KEY,
    name = "zetic/QWEN_2.5_omni_3b_decoder",
    modelMode = LLMModelMode.RUN_AUTO,
)
The full constructor surface (other init paths, init options, cache policy) is documented on the platform ZeticMLangeLLMModel reference pages linked above; the snippets below focus on the multimodal-specific calls only.

Compatibility — MultimodalProfile
A MultimodalProfile declares the special tokens a particular multimodal model is expected to carry. Validate the loaded LLM against the right profile during initialization to fail fast on incompatible checkpoints — instead of silently producing wrong output later in decode.

Fields
MultimodalProfile is a plain data type with two fields:

Field	Type (Android / iOS)	Description
name	String / String	Human-readable identifier used in error messages (e.g. "qwen2.5-omni-audio").
requiredSpecialTokens	List<String> / [String]	Surface forms (e.g. <|audio_bos|>) that must each tokenize to exactly one special-token id in the loaded model's vocab.
ZeticMLangeLLMModel.validate(profile) (Android) / validate(profile:) (iOS) tokenizes every entry with parseSpecial = true, collects the names that did not resolve, and throws a single error listing every missing marker.

Predefined Profiles
The SDK currently ships one predefined profile — the Qwen2.5-Omni audio path. Image / video profiles are not bundled yet; declare them yourself as shown below.

Profile	Required special tokens	Intended for
MultimodalProfile.QWEN_OMNI_AUDIO (Android) / MultimodalProfile.qwenOmniAudio (iOS)	<|audio_bos|>, <|audio_eos|>, <|im_start|>, <|im_end|>	Qwen2.5-Omni 3B audio decoder paired with the matching audio encoder.
Validating the Predefined Profile
Android (Kotlin)
iOS (Swift)

import com.zeticai.mlange.core.model.multimodal.MultimodalProfile
import com.zeticai.mlange.core.model.multimodal.validate
llm.validate(MultimodalProfile.QWEN_OMNI_AUDIO)
Declaring a Custom Profile
MultimodalProfile is plain data — declare your own when validating a custom checkpoint or when the SDK has not yet shipped a built-in profile for your model:

Android (Kotlin)
iOS (Swift)

val myProfile = MultimodalProfile(
    name = "my-vision-llm",
    requiredSpecialTokens = listOf("<|image_bos|>", "<|image_eos|>"),
)
llm.validate(myProfile)
Chat Template Helper — QwenOmniAudioChatTemplate
For the Qwen2.5-Omni audio path, the SDK provides a ready-to-use chat template assembler. It tokenizes the chat prefix and suffix with parseSpecial = true, looks up their per-token embeddings, and concatenates them with the encoder's audio embeddings into one flat buffer.

The output buffer is the concatenation A ++ B ++ C of three segments:

Segment	Content	Source
A (prefix)	<|im_start|>system\n{systemPrompt}<|im_end|>\n<|im_start|>user\n<|audio_bos|>	tokenize(parseSpecial = true) → tokenEmbeddings
B (audio)	[numAudioTokens × n_embd] floats	Audio encoder output (already float)
C (suffix)	<|audio_eos|>{userText}<|im_end|>\n<|im_start|>assistant\n	tokenize(parseSpecial = true) → tokenEmbeddings
Android (Kotlin)
iOS (Swift)

import com.zeticai.mlange.core.model.multimodal.QwenOmniAudioChatTemplate
val merged = QwenOmniAudioChatTemplate().build(
    llm = llm,
    audioEmbeddings = audioEmbeddings,
    userText = "What do you hear in this audio?",
)
llm.runWithEmbeddings(merged)
For non-Qwen models, build your own helper using tokenize + tokenEmbeddings and concatenate the float buffers in the order your model expects.

Multi-Turn and Multi-Block
runWithEmbeddings does not wipe the KV cache or message history on entry. You can freely interleave run(text) and runWithEmbeddings(...) turns; positions continue from the current KV-cache length so prior context is preserved.

Inside a single user turn, you can place multiple embedding blocks (e.g. two audio clips, or text-then-image-then-text) by concatenating them in the desired order on the SDK side and submitting the result as one runWithEmbeddings call.

Re-prefilling the entire conversation as a flat embedding sequence each turn is correct but not efficient — long dialogs pay an O(total tokens) prefill cost per turn. KV-cache incremental reuse for multimodal sessions is tracked as future work.

Backend Restriction
These methods only work on the llama.cpp backend. On other backends they throw with a message naming the unsupported target. The ZeticMLangeMultimodalCapable capability interface (Android) is the type-level signal of this restriction; iOS performs the same check internally and throws if the loaded ZeticMLangeLLMTargetModel is not LLaMACppTargetModel.

See Also