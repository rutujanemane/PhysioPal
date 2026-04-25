LLM Inference Overview
Run large language models on-device with ZETIC Melange.

Examples on this page reflect ZeticMLange Android 1.6.1 and ZeticMLange iOS 1.6.0.

Melange exposes two ways to initialize ZeticMLangeLLMModel:

Automatic selection by LLMModelMode
Explicit selection by LLMTarget, LLMQuantType, and APType
Use automatic selection first. Use explicit selection when you need fixed GGUF selection or processor control.

Model Inputs
Pre-built Models: Select a ready-to-use model from the Melange Dashboard.
Hugging Face Repository ID: Use models like google/gemma-3-4b-it or LiquidAI/LFM2.5-1.2B-Instruct.
Currently supports public repositories with permissive open-source licenses. Private repository authentication is on the roadmap.

Automatic Selection
This is the recommended entry point for most apps.

By default, automatic selection uses LLMModelMode.RUN_AUTO. You can still pass initOption when you need custom KV-cache or context settings.

Android (Kotlin)
iOS (Swift)

val model = ZeticMLangeLLMModel(context, PERSONAL_KEY, MODEL_NAME)
model.run("What is on-device AI?")
val sb = StringBuilder()
while (true) {
    val result = model.waitForNextToken()
    if (result.generatedTokens == 0) break
    sb.append(result.token)
}
val output = sb.toString()
Explicit Runtime Selection
Use this path when you want to choose the runtime, quantization, and processor type directly.

Android (Kotlin)
iOS (Swift)

val model = ZeticMLangeLLMModel(
    context = context,
    personalKey = PERSONAL_KEY,
    name = MODEL_NAME,
    target = LLMTarget.LLAMA_CPP,
    quantType = LLMQuantType.GGUF_QUANT_Q4_K_M,
    apType = APType.GPU,
    initOption = LLMInitOption(
        kvCacheCleanupPolicy = LLMKVCacheCleanupPolicy.DO_NOT_CLEAN_UP,
        nCtx = 4096,
    ),
)
Automatic selection also accepts initOption. Only apType is limited to the explicit constructor path.

APType Support Matrix
Platform / runtime	Supported apType
Android Qualcomm + LLAMA_CPP	CPU, GPU, NPU
Android non-Qualcomm + LLAMA_CPP	CPU
iOS Apple + LLAMA_CPP	CPU, GPU
initOption
initOption now owns the LLM runtime settings that used to be split across separate parameters.

Field	Description
kvCacheCleanupPolicy	Conversation KV-cache policy during generation.
nCtx	Requested context length.
nCtx is a requested value. The runtime can normalize it internally depending on the model, backend, or device.

Do not confuse cacheHandlingPolicy with kvCacheCleanupPolicy. cacheHandlingPolicy manages downloaded files on disk. kvCacheCleanupPolicy manages the in-memory conversation cache.

Detailed managed cache behavior is currently TBD. See Cache Management.

Quick Start Templates
Build a complete chat app with just your PERSONAL_KEY and MODEL_NAME:

Android (Kotlin)
iOS (Swift)
Flutter
React Native
Check each repository's README for detailed setup instructions.

Next Steps