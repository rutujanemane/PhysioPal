import AVFoundation
import Foundation

/// On-device spoken cues (same pattern as workout-buddy `SpeechCoach` — `AVSpeechSynthesizer`, no network).
final class VoiceGuidanceService: NSObject, @unchecked Sendable {
    static let shared = VoiceGuidanceService()

    private let synthesizer = AVSpeechSynthesizer()

    private override init() {
        super.init()
        configureSession()
    }

    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .voicePrompt,
                options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[VoiceGuidance] Audio session: \(error.localizedDescription)")
        }
    }

    func speak(_ text: String, rate: Float = 0.48) {
        guard !text.isEmpty else { return }
        synthesizer.stopSpeaking(at: .word)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.pitchMultiplier = 1.04
        utterance.preUtteranceDelay = 0.12
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
