ZeticMLangeLLMModel
API reference for running LLM inference on iOS with ZeticMLangeLLMModel.

This page reflects ZeticMLange iOS 1.7.0-beta.1.

ZeticMLangeLLMModel is the iOS entry point for on-device LLM inference. The current API has two initializer families:

Automatic selection by LLMModelMode
Explicit selection by LLMTarget, LLMQuantType, and APType
Use the automatic initializer first. Use the explicit initializer when you need a fixed GGUF quantization or want to force Apple CPU or GPU.

Import

import ZeticMLange
Initializers
Automatic Selection (Recommended)
This initializer selects the runtime and quantization automatically from model metadata.


init(
    personalKey: String,
    name: String,
    version: Int? = nil,
    modelMode: LLMModelMode = .RUN_AUTO,
    dataSetType: LLMDataSetType? = nil,
    cacheHandlingPolicy: ZeticMLangeCacheHandlingPolicy = .REMOVE_OVERLAPPING,
    initOption: LLMInitOption = LLMInitOption(),
    onDownload: ((Float) -> Void)? = nil
) throws
Parameter	Type	Default	Description
personalKey	String	-	Personal key. See Personal Key.
name	String	-	Pre-built model key or Hugging Face repository ID.
version	Int?	nil	Model version. nil loads the latest version.
modelMode	LLMModelMode	.RUN_AUTO	Automatic selection strategy.
dataSetType	LLMDataSetType?	nil	Optional dataset hint for accuracy-oriented selection.
cacheHandlingPolicy	ZeticMLangeCacheHandlingPolicy	.REMOVE_OVERLAPPING	Managed artifact cache policy.
initOption	LLMInitOption	LLMInitOption()	LLM initialization options such as KV-cache cleanup and requested context length.
onDownload	((Float) -> Void)?	nil	Download progress callback from 0.0 to 1.0.
Detailed cacheHandlingPolicy behavior and ModelCacheManager usage are currently TBD. See Cache Management.


let model = try ZeticMLangeLLMModel(
    personalKey: PERSONAL_KEY,
    name: "google/gemma-3-4b-it",
    modelMode: .RUN_AUTO,
    initOption: LLMInitOption(
        kvCacheCleanupPolicy: .CLEAN_UP_ON_FULL,
        nCtx: 4096
    )
)
Automatic selection also accepts initOption. If you need to force Apple GPU, switch to the explicit initializer below because apType is not configurable in this path.

Explicit Runtime Selection
Use this initializer when you want to choose the runtime family, GGUF quantization, and processor type directly.


init(
    personalKey: String,
    name: String,
    version: Int? = nil,
    target: LLMTarget,
    quantType: LLMQuantType,
    apType: APType = .CPU,
    cacheHandlingPolicy: ZeticMLangeCacheHandlingPolicy = .REMOVE_OVERLAPPING,
    initOption: LLMInitOption = LLMInitOption(),
    onDownload: ((Float) -> Void)? = nil
) throws
Parameter	Type	Default	Description
personalKey	String	-	Personal key. See Personal Key.
name	String	-	Pre-built model key or Hugging Face repository ID.
version	Int?	nil	Model version. nil loads the latest version.
target	LLMTarget	-	Runtime family to load. Use .LLAMA_CPP.
quantType	LLMQuantType	-	GGUF quantization to load.
apType	APType	.CPU	Processor type for the selected runtime.
cacheHandlingPolicy	ZeticMLangeCacheHandlingPolicy	.REMOVE_OVERLAPPING	Managed artifact cache policy.
initOption	LLMInitOption	LLMInitOption()	LLM initialization options such as KV-cache cleanup and requested context length.
onDownload	((Float) -> Void)?	nil	Download progress callback from 0.0 to 1.0.
Detailed cacheHandlingPolicy behavior and ModelCacheManager usage are currently TBD. See Cache Management.


let model = try ZeticMLangeLLMModel(
    personalKey: PERSONAL_KEY,
    name: "google/gemma-3-4b-it",
    target: .LLAMA_CPP,
    quantType: .GGUF_QUANT_Q4_K_M,
    apType: .GPU,
    initOption: LLMInitOption(
        kvCacheCleanupPolicy: .DO_NOT_CLEAN_UP,
        nCtx: 4096
    )
)
initOption
initOption now contains LLM runtime initialization settings.


public struct LLMInitOption {
    public let kvCacheCleanupPolicy: LLMKVCacheCleanupPolicy
    public let nCtx: Int
}
Field	Type	Default	Description
kvCacheCleanupPolicy	LLMKVCacheCleanupPolicy	.CLEAN_UP_ON_FULL	Conversation KV-cache policy.
nCtx	Int	2048	Requested context length.
cacheHandlingPolicy and initOption.kvCacheCleanupPolicy are different settings. cacheHandlingPolicy controls downloaded model artifacts on disk. kvCacheCleanupPolicy controls the in-memory conversation KV cache during generation.

More detailed managed cache behavior is documented as TBD in Cache Management.

nCtx is a requested value, not an exact guarantee. The runtime can normalize it internally depending on the model, backend, or device.

apType Support
apType is relevant when you use the explicit initializer and choose target = .LLAMA_CPP.

Device / runtime	Supported apType
Apple + .LLAMA_CPP	.CPU, .GPU
Apple LLaMA.cpp does not support .NPU. Use .CPU or .GPU.

Methods
run(_:)
Starts generation for a prompt.


func run(_ text: String) throws -> LLMRunResult
Parameter	Type	Description
text	String	Prompt text to start generation with.
Returns: LLMRunResult

Property	Type	Description
promptTokens	Int	Number of prompt tokens consumed.
waitForNextToken()
Blocks until the next token is available.


func waitForNextToken() -> LLMNextTokenResult
Returns: LLMNextTokenResult

Property	Type	Description
token	String	Generated token text.
generatedTokens	Int	Number of generated tokens so far.
code	Int	Native status code.
cleanUp()
Resets the current conversation state without destroying the model instance.


func cleanUp() throws
If you use .DO_NOT_CLEAN_UP, call cleanUp() before starting the next conversation.

forceDeinit()
Fully releases the underlying target model.


func forceDeinit()
Multimodal (Beta)
Multimodal embedding injection is Beta in ZeticMLange iOS 1.7.0-beta.1. See LLM Inference: Multimodal for design background and the Audio Understanding tutorial for an end-to-end example.

These methods are supported only when the loaded target is the llama.cpp backend. They throw with a clear message on other backends.

runWithEmbeddings(_:)
Prefill the decoder with a flat embedding sequence (e.g. audio encoder output, or a chat template assembled by the SDK layer). Positions continue from the current KV-cache length, so this composes with prior run(_:) / runWithEmbeddings(_:) turns.


func runWithEmbeddings(_ embeddings: [Float]) throws -> LLMRunResult
Parameter	Type	Description
embeddings	[Float]	Flat embedding buffer. Length must be a multiple of the model's embedding dimension; the SDK validates and rejects mismatched buffers.
Returns: LLMRunResult. After this call returns, the embedding batch is queued. Drive token decode + sampling with waitForNextToken() as you would for run(_:).

Throws: A ZeticMLangeError with the LLMTargetModelErrorDomain domain when the loaded target is not LLaMACppTargetModel.

tokenize(_:parseSpecial:)
Tokenize text using the model's vocabulary. With parseSpecial = true, special tokens (e.g. <|audio_bos|>, <|im_start|>) in the input are recognized as single tokens rather than split by BPE.


func tokenize(_ text: String, parseSpecial: Bool) throws -> [Int32]
Parameter	Type	Description
text	String	Text to tokenize.
parseSpecial	Bool	When true, recognize special-token literal forms in the input.
Returns: [Int32] of token ids. Empty on failure. Throws on non-llama.cpp backends.

tokenEmbeddings(_:)
Look up per-token embedding vectors from the model's tok_embd tensor and return them concatenated into a flat [tokenIds.count * n_embd] buffer. Quantized rows are dequantized to Float.


func tokenEmbeddings(_ tokenIds: [Int32]) throws -> [Float]
Parameter	Type	Description
tokenIds	[Int32]	Token ids to look up.
Returns: [Float] of length tokenIds.count * n_embd. Empty on failure. Throws on non-llama.cpp backends.

specialTokenId(_:)
Resolve a special token by its surface form (e.g. "<|audio_bos|>") to its vocabulary id.


func specialTokenId(_ name: String) throws -> Int32
Parameter	Type	Description
name	String	Special token surface form.
Returns: Token id, or -1 if the string does not resolve to a single special token in this model's vocab. Throws on non-llama.cpp backends.

Multimodal Helpers
The SDK ships supporting types in the ZeticMLange module:

Symbol	Purpose
MultimodalProfile	Declares required special tokens for a multimodal model (e.g. MultimodalProfile.qwenOmniAudio).
ZeticMLangeLLMModel.validate(profile:)	Init-time check that the loaded model carries every required token. Throws with a clear message naming missing markers.
QwenOmniAudioChatTemplate	Builds a flat audio-prompt embedding buffer ready for runWithEmbeddings(_:).
See the Multimodal page for usage examples.

Full Examples
Automatic Selection

import ZeticMLange
let model = try ZeticMLangeLLMModel(
    personalKey: PERSONAL_KEY,
    name: "google/gemma-3-4b-it",
    modelMode: .RUN_AUTO,
    initOption: LLMInitOption(
        kvCacheCleanupPolicy: .CLEAN_UP_ON_FULL,
        nCtx: 4096
    )
)
try model.run("Explain on-device AI in one paragraph.")
var output = ""
while true {
    let result = model.waitForNextToken()
    if result.generatedTokens == 0 { break }
    output.append(result.token)
}
try model.cleanUp()
model.forceDeinit()
Explicit Apple GPU Selection

import ZeticMLange
let model = try ZeticMLangeLLMModel(
    personalKey: PERSONAL_KEY,
    name: "google/gemma-3-4b-it",
    target: .LLAMA_CPP,
    quantType: .GGUF_QUANT_Q4_K_M,
    apType: .GPU,
    initOption: LLMInitOption(
        kvCacheCleanupPolicy: .DO_NOT_CLEAN_UP,
        nCtx: 4096
    )
)
Notes
The initializer can download model artifacts on first use. Create the model off the main thread if you want to avoid blocking the UI.

See Also