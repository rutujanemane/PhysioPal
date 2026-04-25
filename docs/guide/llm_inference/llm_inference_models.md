LLM Inference Modes
Configure LLM inference modes for speed or accuracy with ZETIC Melange.

LLMModelMode controls the automatic selection path of ZeticMLangeLLMModel.

If you use the explicit constructor with target, quantType, and apType, LLMModelMode is bypassed.

Available Modes
RUN_AUTO
Default mode. Lets the runtime choose a reasonable target model from metadata.

RUN_SPEED
Prioritizes lower latency.

RUN_ACCURACY
Prioritizes better score or lower loss. Pair it with LLMDataSetType when you want to bias selection toward a particular benchmark.

API Usage
Android (Kotlin)
iOS (Swift)

val modelAuto = ZeticMLangeLLMModel(
    context = context,
    personalKey = PERSONAL_KEY,
    name = MODEL_NAME,
    modelMode = LLMModelMode.RUN_AUTO,
)
val modelSpeed = ZeticMLangeLLMModel(
    context = context,
    personalKey = PERSONAL_KEY,
    name = MODEL_NAME,
    modelMode = LLMModelMode.RUN_SPEED,
)
val modelAccurate = ZeticMLangeLLMModel(
    context = context,
    personalKey = PERSONAL_KEY,
    name = MODEL_NAME,
    modelMode = LLMModelMode.RUN_ACCURACY,
)
val modelAccurateMmlu = ZeticMLangeLLMModel(
    context = context,
    personalKey = PERSONAL_KEY,
    name = MODEL_NAME,
    modelMode = LLMModelMode.RUN_ACCURACY,
    dataSetType = LLMDataSetType.MMLU,
)
Dataset Hints
LLMDataSetType is optional.

Use dataSetType only when you want RUN_ACCURACY to bias selection toward a specific benchmark such as MMLU, TRUTHFULQA, CNN_DAILYMAIL, or GSM8K.

Forcing GPU or NPU
LLMModelMode does not expose apType. If you need to force GPU or NPU, switch to the explicit constructor:

Android (Kotlin)
iOS (Swift)

val model = ZeticMLangeLLMModel(
    context = context,
    personalKey = PERSONAL_KEY,
    name = MODEL_NAME,
    target = LLMTarget.LLAMA_CPP,
    quantType = LLMQuantType.GGUF_QUANT_Q4_K_M,
    apType = APType.GPU,
)