Streaming Token Generation
Stream LLM tokens in real-time on Android and iOS with ZETIC Melange.

Melange streams generated tokens incrementally, so you can render output while the model is still decoding.

How Streaming Works
Call run(prompt) to start the generation context.
Call waitForNextToken() in a loop to receive tokens one at a time.
Stop when generation completes.
Basic Streaming
Android (Kotlin)
iOS (Swift)

val model = ZeticMLangeLLMModel(context, PERSONAL_KEY, MODEL_NAME)
model.run(userPrompt)
val sb = StringBuilder()
while (true) {
    val result = model.waitForNextToken()
    if (result.generatedTokens == 0) break
    if (result.token.isNotEmpty()) sb.append(result.token)
}
val output = sb.toString()
Streaming to the UI
For a chat UI, update the screen every time a new token arrives.

Android (Kotlin)
iOS (Swift)

lifecycleScope.launch(Dispatchers.IO) {
    val model = ZeticMLangeLLMModel(context, PERSONAL_KEY, MODEL_NAME)
    model.run(userPrompt)
    while (true) {
        val result = model.waitForNextToken()
        if (result.generatedTokens == 0) break
        withContext(Dispatchers.Main) {
            textView.append(result.token)
        }
    }
}
Conversation Reset
If you want a fresh conversation, call cleanUp().

Android (Kotlin)
iOS (Swift)

model.cleanUp()
model.run("Start a new conversation")
Keeping Context Between Turns
Use LLMInitOption.kvCacheCleanupPolicy to control what happens when the KV cache fills up.

CLEAN_UP_ON_FULL: Clears the conversation context automatically.
DO_NOT_CLEAN_UP: Keeps the existing context. You must manually call cleanUp() before starting a new conversation.
When you use DO_NOT_CLEAN_UP, do not call run() again for a new conversation until you have called cleanUp().

Releasing the Model
When the model instance is no longer needed:

Android (Kotlin)
iOS (Swift)

model.deinit()