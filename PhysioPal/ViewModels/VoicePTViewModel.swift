import AVFoundation
import Combine
import Foundation
import Speech

@MainActor
final class VoicePTViewModel: ObservableObject {
    @Published var transcript: String = ""
    @Published var responseText: String = "Tap the microphone and tell me how you're feeling."
    @Published var isListening = false
    @Published var isAnalyzing = false
    @Published var suggestedExerciseID: String?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func toggleListening() {
        isListening ? stopListening() : startListening()
    }

    func startListening() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            guard let self else { return }
            guard granted else {
                Task { @MainActor in
                    self.responseText = "Please allow microphone access in Settings."
                }
                return
            }
            Task { @MainActor in
                self.requestSpeechAuthorizationAndStart()
            }
        }
    }

    private func requestSpeechAuthorizationAndStart() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard let self else { return }
            guard status == .authorized else {
                Task { @MainActor in
                    self.responseText = "Please allow speech recognition in Settings."
                }
                return
            }
            Task { @MainActor in
                self.startAudioCapture()
            }
        }
    }

    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        isListening = false
        if !transcript.isEmpty {
            analyzeIntent(transcript)
        }
    }

    private func startAudioCapture() {
        task?.cancel()
        task = nil
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request else { return }
        request.shouldReportPartialResults = true

        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord,
                mode: .measurement,
                options: [.duckOthers, .defaultToSpeaker, .allowBluetooth]
            )
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            responseText = "Microphone setup failed. Please try again."
            isListening = false
            return
        }

        let input = audioEngine.inputNode
        let format = input.inputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            responseText = "Microphone input is unavailable right now. Please try again."
            isListening = false
            return
        }
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isListening = true
            transcript = ""
            responseText = "Listening..."
        } catch {
            responseText = "I couldn't start listening. Please try again."
            isListening = false
            return
        }

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                Task { @MainActor in
                    self.transcript = result.bestTranscription.formattedString
                    if result.isFinal {
                        self.stopListening()
                    }
                }
            } else if error != nil {
                Task { @MainActor in
                    self.stopListening()
                }
            }
        }
    }

    private func analyzeIntent(_ phrase: String) {
        isAnalyzing = true
        suggestedExerciseID = nil
        responseText = "Analyzing your symptoms with AI..."

        let normalized = phrase.lowercased()
        let (exerciseID, message): (String, String) = {
            if normalized.contains("knee") {
                return ("chair-squat", "For knee pain, let's begin with Chair-Assisted Squats. We'll keep it gentle and controlled.")
            }
            if normalized.contains("hip") {
                return ("standing-hip-abduction", "For hip discomfort, Standing Hip Abduction is a good start. Hold support and move slowly.")
            }
            if normalized.contains("shoulder") || normalized.contains("arm") {
                return ("seated-shoulder-flexion", "Let's start with Seated Shoulder Flexion so your shoulder can warm up gradually.")
            }
            if normalized.contains("back") {
                return ("sit-to-stand", "We'll begin with Sit-to-Stand at a calm pace to build safe control.")
            }
            return ("seated-knee-extension", "Thank you. Let's start with Seated Knee Extensions as a gentle first movement.")
        }()

        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            isAnalyzing = false
            suggestedExerciseID = exerciseID
            responseText = message
        }
    }
}
