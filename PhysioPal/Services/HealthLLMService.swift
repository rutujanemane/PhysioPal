import Combine
import Foundation

#if canImport(ZeticMLange)
import ZeticMLange
#endif

struct LLMRoutineResult {
    let exercises: [LLMExerciseDecision]
    let note: String
}

struct LLMExerciseDecision {
    let exerciseID: String
    let reps: Int
}

@MainActor
final class HealthLLMService: ObservableObject {
    static let shared = HealthLLMService()

    @Published var downloadProgress: Float = 0
    @Published var isModelReady = false

    #if canImport(ZeticMLange)
    private nonisolated(unsafe) var model: ZeticMLangeLLMModel?
    #endif

    private let inferenceQueue = DispatchQueue(label: "com.physiopal.llm.inference", qos: .userInitiated)
    private var isInitializing = false

    private static let crashGuardKey = "llm_init_in_progress"
    private static let crashCountKey = "llm_init_crash_count"
    private static let crashModelKey = "llm_init_model_name"
    private static let maxCrashRetries = 2

    private init() {}

    private var shouldSkipDueToCrashHistory: Bool {
        let previousModel = UserDefaults.standard.string(forKey: Self.crashModelKey) ?? ""
        let currentModel = MelangeConfig.llmModelName
        if previousModel != currentModel {
            UserDefaults.standard.set(0, forKey: Self.crashCountKey)
            UserDefaults.standard.set(false, forKey: Self.crashGuardKey)
            return false
        }
        let crashCount = UserDefaults.standard.integer(forKey: Self.crashCountKey)
        if crashCount >= Self.maxCrashRetries { return true }
        if UserDefaults.standard.bool(forKey: Self.crashGuardKey) {
            let newCount = crashCount + 1
            UserDefaults.standard.set(newCount, forKey: Self.crashCountKey)
            UserDefaults.standard.set(false, forKey: Self.crashGuardKey)
            if newCount >= Self.maxCrashRetries { return true }
        }
        return false
    }

    func initializeModel() async {
        guard !isModelReady, !isInitializing else { return }
        if shouldSkipDueToCrashHistory { return }
        isInitializing = true

        #if canImport(ZeticMLange)
        let key = MelangeConfig.llmPersonalKey
        let modelName = MelangeConfig.llmModelName
        let modelVersion = MelangeConfig.llmModelVersion
        let queue = inferenceQueue

        UserDefaults.standard.set(true, forKey: Self.crashGuardKey)
        UserDefaults.standard.set(modelName, forKey: Self.crashModelKey)
        UserDefaults.standard.synchronize()

        let llmModel: ZeticMLangeLLMModel? = await withCheckedContinuation { [weak self] continuation in
            var hasResumed = false
            let lock = NSLock()

            func resumeOnce(_ value: ZeticMLangeLLMModel?) {
                lock.lock()
                defer { lock.unlock() }
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(returning: value)
            }

            var lastProgressTime = DispatchTime.now()
            func scheduleStallCheck() {
                DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
                    lock.lock()
                    let done = hasResumed
                    lock.unlock()
                    guard !done else { return }
                    let elapsed = Double(DispatchTime.now().uptimeNanoseconds - lastProgressTime.uptimeNanoseconds) / 1_000_000_000
                    if elapsed > 30 {
                        print("[HealthLLM] Download stalled — timing out")
                        resumeOnce(nil)
                    } else {
                        scheduleStallCheck()
                    }
                }
            }
            scheduleStallCheck()

            queue.async {
                print("[HealthLLM] Loading model: \(modelName) v\(modelVersion)")
                do {
                    let initOption = LLMInitOption(nCtx: 1024)
                    let m = try ZeticMLangeLLMModel(
                        personalKey: key,
                        name: modelName,
                        version: modelVersion,
                        modelMode: .RUN_AUTO,
                        initOption: initOption,
                        onDownload: { progress in
                            lastProgressTime = DispatchTime.now()
                            print("[HealthLLM] Download: \(Int(progress * 100))%")
                            Task { @MainActor [weak self] in
                                self?.downloadProgress = progress
                            }
                        }
                    )
                    print("[HealthLLM] Model loaded successfully")
                    resumeOnce(m)
                } catch {
                    print("[HealthLLM] Model init failed: \(error)")
                    resumeOnce(nil)
                }
            }
        }

        UserDefaults.standard.set(false, forKey: Self.crashGuardKey)
        UserDefaults.standard.set(0, forKey: Self.crashCountKey)

        if let llmModel {
            self.model = llmModel
            self.isModelReady = true
        }
        #endif

        isInitializing = false
    }

    func adaptRoutine(
        health: HealthReadiness,
        assignedExercises: [AssignedRoutineItem]
    ) async -> LLMRoutineResult? {
        #if canImport(ZeticMLange)
        guard let model else { return nil }

        let prompt = Self.buildPrompt(health: health, assignedExercises: assignedExercises)
        let capturedModel = model
        let capturedExercises = assignedExercises
        let queue = inferenceQueue

        print("[HealthLLM] Prompt: \(prompt)")

        return await withCheckedContinuation { continuation in
            queue.async {
                do {
                    let startTime = CFAbsoluteTimeGetCurrent()
                    _ = try capturedModel.run(prompt)

                    // Prompt ends with {"exercises":[ — prepend to buffer
                    var buffer = "{\"exercises\":["
                    var tokenCount = 0
                    let maxTokens = 400
                    var thinkingDetected = false
                    while tokenCount < maxTokens {
                        let result = capturedModel.waitForNextToken()
                        if result.isFinished || result.generatedTokens == 0 { break }
                        let tok = result.token
                        if tok.contains("<|im_end|>") || tok.contains("<|endoftext|>") { break }

                        // If model starts thinking despite <think></think>, skip until we see JSON
                        if tokenCount < 5 && (tok.lowercased().contains("think") || tok.contains("**") || tok.contains("1.")) {
                            thinkingDetected = true
                        }
                        if thinkingDetected {
                            if tok.contains("{") {
                                thinkingDetected = false
                                buffer = tok
                            }
                            tokenCount += 1
                            continue
                        }

                        buffer.append(tok)
                        tokenCount += 1
                        let openCount = buffer.filter({ $0 == "{" }).count
                        let closeCount = buffer.filter({ $0 == "}" }).count
                        if openCount > 0 && openCount == closeCount { break }
                    }
                    let elapsed = CFAbsoluteTimeGetCurrent() - startTime
                    print("[HealthLLM] Generated \(tokenCount) tokens in \(String(format: "%.1f", elapsed))s\(thinkingDetected ? " (thinking detected, no JSON found)" : "")")
                    print("[HealthLLM] Raw output: \(buffer)")

                    let parsed = parseLLMResponse(buffer, assignedExercises: capturedExercises)
                    continuation.resume(returning: parsed)
                } catch {
                    print("[HealthLLM] Inference failed: \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
        #else
        return nil
        #endif
    }

    private nonisolated static func buildPrompt(health: HealthReadiness, assignedExercises: [AssignedRoutineItem]) -> String {
        var hrStatus = "normal"
        var hrVal = 70.0
        if let hr = health.restingHeartRate {
            hrVal = hr
            if hr > 85 { hrStatus = "elevated" }
        }
        var sleepStatus = ""
        if let sleep = health.sleepHours {
            sleepStatus = ", sleep \(String(format: "%.1f", sleep))h"
            if sleep < 5 { sleepStatus += " (poor)" }
        }

        let items = assignedExercises.compactMap { item -> String? in
            guard Exercise.find(byID: item.exerciseID) != nil else { return nil }
            return "{\"id\":\"\(item.exerciseID)\",\"reps\":\(item.targetReps)}"
        }

        return """
        <|im_start|>system
        You are a JSON API. Respond with only valid JSON, nothing else.<|im_end|>
        <|im_start|>user
        HR: \(String(format: "%.0f", hrVal))bpm (\(hrStatus))\(sleepStatus). Exercises: [\(items.joined(separator: ","))]. If health is poor or HR elevated, reduce reps. Otherwise keep same. Output: {"exercises":[...],"note":"reason"}<|im_end|>
        <|im_start|>assistant
        <think>
        </think>
        {"exercises":[
        """
    }

    static func applyHeartRateSafetyGuardrail(
        exercises: [LLMExerciseDecision],
        restingHeartRate: Double?
    ) -> [LLMExerciseDecision] {
        guard let hr = restingHeartRate, hr > 95 else { return exercises }
        return exercises.filter { Exercise.intensityLevel(for: $0.exerciseID) != "high" }
    }

    static func resetCrashGuard() {
        UserDefaults.standard.set(false, forKey: crashGuardKey)
        UserDefaults.standard.set(0, forKey: crashCountKey)
    }
}

private func parseLLMResponse(_ raw: String, assignedExercises: [AssignedRoutineItem]) -> LLMRoutineResult? {
    var text = raw
    // Strip Qwen3 thinking blocks (both XML-style and plain-text)
    text = text.replacingOccurrences(of: "<think>[\\s\\S]*?</think>", with: "", options: .regularExpression)
    text = text.replacingOccurrences(of: "<\\|im_end\\|>", with: "", options: .regularExpression)
    text = text.replacingOccurrences(of: "<\\|im_start\\|>\\w*", with: "", options: .regularExpression)
    text = text.replacingOccurrences(of: "```json", with: "")
    text = text.replacingOccurrences(of: "```", with: "")
    // Jump straight to the first '{' — discard any thinking/reasoning text before it
    if let jsonStart = text.firstIndex(of: "{") {
        text = String(text[jsonStart...])
    }
    text = text.trimmingCharacters(in: .whitespacesAndNewlines)

    // Find JSON object with brace matching
    guard let start = text.firstIndex(of: "{") else {
        print("[HealthLLM] PARSE FAIL: no '{' found in: \(raw.prefix(200))")
        return nil
    }

    var depth = 0
    var end: String.Index?
    for i in text.indices[start...] {
        if text[i] == "{" { depth += 1 }
        else if text[i] == "}" { depth -= 1; if depth == 0 { end = i; break } }
    }

    guard let jsonEnd = end else {
        print("[HealthLLM] PARSE FAIL: unmatched braces in: \(raw.prefix(200))")
        return nil
    }

    let jsonStr = String(text[start...jsonEnd])
    print("[HealthLLM] Extracted JSON: \(jsonStr)")

    // Try strict decode first
    if let result = decodeResponse(jsonStr, assignedExercises: assignedExercises) {
        return result
    }

    // Try fixing common LLM quirks: single quotes, trailing commas
    var fixed = jsonStr
        .replacingOccurrences(of: "'", with: "\"")
    // Remove trailing commas before } or ]
    fixed = fixed.replacingOccurrences(of: ",\\s*}", with: "}", options: .regularExpression)
    fixed = fixed.replacingOccurrences(of: ",\\s*]", with: "]", options: .regularExpression)

    if let result = decodeResponse(fixed, assignedExercises: assignedExercises) {
        return result
    }

    print("[HealthLLM] PARSE FAIL: could not decode JSON: \(jsonStr.prefix(300))")
    return nil
}

private func decodeResponse(_ jsonStr: String, assignedExercises: [AssignedRoutineItem]) -> LLMRoutineResult? {
    guard let data = jsonStr.data(using: .utf8) else { return nil }

    // Flexible decode — handle reps as Int or String
    struct Resp: Decodable {
        let exercises: [Ex]
        let note: String?
        let reason: String?
        let message: String?
    }
    struct Ex: Decodable {
        let id: String
        let reps: FlexInt

        enum CodingKeys: String, CodingKey {
            case id, reps, name, exercise_id
        }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.id = (try? c.decode(String.self, forKey: .id))
                ?? (try? c.decode(String.self, forKey: .exercise_id))
                ?? (try? c.decode(String.self, forKey: .name))
                ?? ""
            self.reps = (try? c.decode(FlexInt.self, forKey: .reps)) ?? FlexInt(value: 0)
        }
    }
    struct FlexInt: Decodable {
        let value: Int
        init(value: Int) { self.value = value }
        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let i = try? c.decode(Int.self) { value = i }
            else if let s = try? c.decode(String.self), let i = Int(s) { value = i }
            else if let d = try? c.decode(Double.self) { value = Int(d) }
            else { value = 0 }
        }
    }

    guard let resp = try? JSONDecoder().decode(Resp.self, from: data) else { return nil }

    let assignedMap = Dictionary(uniqueKeysWithValues: assignedExercises.map { ($0.exerciseID, $0.targetReps) })

    let validated = resp.exercises.compactMap { ex -> LLMExerciseDecision? in
        // Try exact match first, then fuzzy match
        let matchedID: String?
        if assignedMap[ex.id] != nil {
            matchedID = ex.id
        } else {
            matchedID = assignedMap.keys.first { key in
                key.lowercased() == ex.id.lowercased() ||
                key.replacingOccurrences(of: "-", with: "_") == ex.id ||
                key.replacingOccurrences(of: "-", with: " ") == ex.id.lowercased()
            }
        }

        guard let id = matchedID, let maxReps = assignedMap[id] else {
            print("[HealthLLM] Skipping unknown exercise ID: '\(ex.id)'")
            return nil
        }
        let safeReps = max(1, min(ex.reps.value, maxReps))
        return LLMExerciseDecision(exerciseID: id, reps: safeReps)
    }

    guard !validated.isEmpty else {
        print("[HealthLLM] No exercises matched. LLM IDs: \(resp.exercises.map(\.id)), assigned: \(Array(assignedMap.keys))")
        return nil
    }

    let note = resp.note ?? resp.reason ?? resp.message ?? "Your routine has been adjusted based on how you're feeling today."
    print("[HealthLLM] Parsed \(validated.count) exercises successfully")
    return LLMRoutineResult(exercises: validated, note: note)
}
