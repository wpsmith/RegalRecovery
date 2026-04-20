import AVFoundation

@Observable
final class TextToSpeechService: NSObject, AVSpeechSynthesizerDelegate {

    // MARK: - Types

    enum PlaybackState {
        case stopped, playing, paused
    }

    struct RatePreset: Identifiable {
        let id: String
        let label: String
        let utteranceRate: Float

        static let presets: [RatePreset] = [
            RatePreset(id: "0.5x", label: "0.5x", utteranceRate: 0.35),
            RatePreset(id: "0.75x", label: "0.75x", utteranceRate: 0.42),
            RatePreset(id: "1x", label: "1x", utteranceRate: 0.5),
            RatePreset(id: "1.25x", label: "1.25x", utteranceRate: 0.55),
            RatePreset(id: "1.5x", label: "1.5x", utteranceRate: 0.6),
            RatePreset(id: "2x", label: "2x", utteranceRate: 0.65),
        ]

        static let defaultPreset = presets[2] // 1x
    }

    // MARK: - Observable State

    var state: PlaybackState = .stopped
    var currentParagraphIndex: Int = 0
    var rate: Float
    var rateLabel: String

    // MARK: - Private

    private let synthesizer = AVSpeechSynthesizer()
    private var paragraphs: [String] = []
    private var language: String = "en-US"

    private static let rateDefaultsKey = "books.ttsRate"

    // MARK: - Init

    override init() {
        let savedRateId = UserDefaults.standard.string(forKey: Self.rateDefaultsKey)
        let preset = RatePreset.presets.first(where: { $0.id == savedRateId }) ?? RatePreset.defaultPreset
        self.rate = preset.utteranceRate
        self.rateLabel = preset.label
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Public API

    func load(paragraphs: [String], language: String) {
        stop()
        self.paragraphs = paragraphs
        self.language = language
        currentParagraphIndex = 0
    }

    func play() {
        guard !paragraphs.isEmpty else { return }
        configureAudioSession()
        speakParagraph(at: currentParagraphIndex)
    }

    func pause() {
        guard state == .playing else { return }
        synthesizer.pauseSpeaking(at: .immediate)
        state = .paused
    }

    func resume() {
        guard state == .paused else { return }
        synthesizer.continueSpeaking()
        state = .playing
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        state = .stopped
        currentParagraphIndex = 0
    }

    func skipForward() {
        guard currentParagraphIndex < paragraphs.count - 1 else {
            stop()
            return
        }
        synthesizer.stopSpeaking(at: .immediate)
        currentParagraphIndex += 1
        speakParagraph(at: currentParagraphIndex)
    }

    func skipBackward() {
        synthesizer.stopSpeaking(at: .immediate)
        currentParagraphIndex = max(currentParagraphIndex - 1, 0)
        speakParagraph(at: currentParagraphIndex)
    }

    func setRate(_ preset: RatePreset) {
        rate = preset.utteranceRate
        rateLabel = preset.label
        UserDefaults.standard.set(preset.id, forKey: Self.rateDefaultsKey)

        // If currently speaking, restart the current paragraph at new rate
        if state == .playing {
            synthesizer.stopSpeaking(at: .immediate)
            speakParagraph(at: currentParagraphIndex)
        }
    }

    func playFrom(paragraphIndex: Int) {
        guard paragraphIndex >= 0, paragraphIndex < paragraphs.count else { return }
        synthesizer.stopSpeaking(at: .immediate)
        currentParagraphIndex = paragraphIndex
        configureAudioSession()
        speakParagraph(at: paragraphIndex)
    }

    // MARK: - Language Resolution

    static func resolveLanguage() -> String {
        let lang = BookLanguageManager.shared.currentLanguage
        switch lang {
        case "fr": return "fr-FR"
        case "es": return "es-ES"
        default: return "en-US"
        }
    }

    // MARK: - Private Helpers

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Audio session configuration failed; speech may still work
        }
    }

    private func speakParagraph(at index: Int) {
        guard index >= 0, index < paragraphs.count else {
            state = .stopped
            return
        }

        let utterance = AVSpeechUtterance(string: paragraphs[index])
        utterance.rate = rate
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.2

        currentParagraphIndex = index
        state = .playing
        synthesizer.speak(utterance)
    }

    // MARK: - AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Auto-advance to next paragraph
        let nextIndex = currentParagraphIndex + 1
        if nextIndex < paragraphs.count {
            speakParagraph(at: nextIndex)
        } else {
            state = .stopped
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        // Cancellation is handled by the caller (skip, stop, rate change)
        // State is set explicitly in those methods, so nothing to do here
    }
}
