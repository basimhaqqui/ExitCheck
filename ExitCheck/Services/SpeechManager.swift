import Foundation
import AVFoundation

@MainActor
final class SpeechManager: NSObject, ObservableObject {
    static let shared = SpeechManager()

    private let synthesizer = AVSpeechSynthesizer()

    @Published var isSpeaking = false
    @Published var availableVoices: [AVSpeechSynthesisVoice] = []

    private override init() {
        super.init()
        synthesizer.delegate = self
        loadAvailableVoices()
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }

    private func loadAvailableVoices() {
        availableVoices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.starts(with: "en") }
            .sorted { $0.name < $1.name }
    }

    func speakChecklistItems(_ items: [ChecklistItem], rate: Float = 0.5, voiceIdentifier: String? = nil) {
        guard !items.isEmpty else { return }

        stop()

        let itemNames = items.map { $0.title }.joined(separator: ", ")
        let text = "Leaving home checklist: \(itemNames)"

        speak(text, rate: rate, voiceIdentifier: voiceIdentifier)
    }

    func speak(_ text: String, rate: Float = 0.5, voiceIdentifier: String? = nil) {
        stop()

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        if let identifier = voiceIdentifier,
           let voice = AVSpeechSynthesisVoice(identifier: identifier) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }

        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to activate audio session: \(error)")
        }

        synthesizer.speak(utterance)
        isSpeaking = true
    }

    func speakSuccessMessage(_ message: String) {
        speak(message, rate: 0.52)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }

    func pause() {
        synthesizer.pauseSpeaking(at: .word)
    }

    func resume() {
        synthesizer.continueSpeaking()
    }
}

extension SpeechManager: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}
