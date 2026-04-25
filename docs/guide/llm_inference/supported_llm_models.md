Supported LLM Models
List of supported large language models for on-device inference with Melange.

Melange supports a growing list of large language models for on-device inference. Models are validated weekly as new architectures are added.

Available Models
Model	Hugging Face ID	Parameters
Google Gemma 3 4B Instruct	google/gemma-3-4b-it	4B
LiquidAI LFM2.5 1.2B Instruct	LiquidAI/LFM2.5-1.2B-Instruct	1.2B
For the most up-to-date list of supported models, visit the Melange Dashboard Use Cases page.

Using Pre-Built Models
Select a model from the Melange Dashboard and use the provided model key directly in your application:


val model = ZeticMLangeLLMModel(
    context = context,
    personalKey = PERSONAL_KEY,
    name = "pre-built-model-key",
    modelMode = LLMModelMode.RUN_AUTO,
)
Using Hugging Face Models
You can also use models directly from Hugging Face by providing the repository ID:


val model = ZeticMLangeLLMModel(
    context = context,
    personalKey = PERSONAL_KEY,
    name = "google/gemma-3-4b-it",
    modelMode = LLMModelMode.RUN_AUTO,
)
Currently supports public repositories with permissive open-source licenses. Private repository authentication is on the roadmap.

Model Compatibility Notes
Models must have an architecture supported by the Melange LLM engine.
Very large models (>7B parameters) may require devices with sufficient RAM.
Quantized variants are automatically selected based on your inference mode settings.
Requesting New Models
If you need a specific model that is not yet supported:

Contact contact@zetic.ai with the model name and Hugging Face repository link.
Join the Discord community to discuss model requests.