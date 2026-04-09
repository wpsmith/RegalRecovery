import AVFoundation
import Foundation
import OSLog

// MARK: - Audio Session State

/// Observable state for the affirmation audio session.
enum AffirmationAudioState: Sendable {
    /// No audio session is active.
    case idle
    /// Configured for recording own-voice affirmations.
    case recording
    /// Configured for playback of affirmation audio.
    case playing
    /// Playback was paused (manually or due to headphone disconnect).
    case paused
    /// An error occurred during audio session configuration.
    case error(String)
}

// MARK: - Audio Session Manager

/// Manages AVAudioSession for affirmation recording and playback.
///
/// **Key safety feature:** Immediately pauses playback when headphones are disconnected
/// (`.oldDeviceUnavailable` route change). This is a non-negotiable privacy requirement
/// to prevent affirmation audio from playing through external speakers unexpectedly.
///
/// Background music plays at 60% volume relative to voice by default.
/// Volume is user-adjustable.
@Observable
final class AffirmationAudioSessionManager: @unchecked Sendable {

    // MARK: - Published State

    private(set) var state: AffirmationAudioState = .idle
    private(set) var isHeadphonesConnected: Bool = false

    /// Volume for voice playback (0.0 to 1.0). Defaults to 1.0.
    var voiceVolume: Float = 1.0

    /// Volume for background music relative to voice. Defaults to 0.6 (60%).
    var backgroundMusicVolume: Float = 0.6

    // MARK: - Callbacks

    /// Called when headphones are disconnected during playback.
    /// The view model should respond by pausing the audio player.
    var onHeadphoneDisconnect: (@Sendable () -> Void)?

    /// Called when the audio session is interrupted (e.g., phone call).
    var onInterruption: (@Sendable (Bool) -> Void)?

    // MARK: - Internals

    private let audioSession = AVAudioSession.sharedInstance()
    private let logger = Logger(subsystem: "com.regalrecovery.app", category: "AffirmationAudio")
    private var isObserving = false

    // MARK: - Lifecycle

    init() {}

    deinit {
        stopObserving()
    }

    /// Start observing audio route changes and interruptions.
    /// Call this when the affirmation feature becomes active.
    func startObserving() {
        guard !isObserving else { return }
        isObserving = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: audioSession
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: audioSession
        )

        updateHeadphoneStatus()
        logger.info("AffirmationAudioSessionManager started observing")
    }

    /// Stop observing audio notifications.
    /// Call this when the affirmation feature is dismissed.
    func stopObserving() {
        guard isObserving else { return }
        isObserving = false

        NotificationCenter.default.removeObserver(
            self,
            name: AVAudioSession.routeChangeNotification,
            object: audioSession
        )
        NotificationCenter.default.removeObserver(
            self,
            name: AVAudioSession.interruptionNotification,
            object: audioSession
        )

        logger.info("AffirmationAudioSessionManager stopped observing")
    }

    // MARK: - Session Configuration

    /// Configure the audio session for recording own-voice affirmations.
    ///
    /// Uses `.playAndRecord` category so the user can hear ambient background
    /// music while recording their voice.
    func configureForRecording() throws {
        do {
            try audioSession.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetooth]
            )
            try audioSession.setActive(true)

            DispatchQueue.main.async { [weak self] in
                self?.state = .recording
            }

            updateHeadphoneStatus()
            logger.info("Audio session configured for recording")
        } catch {
            let message = "Failed to configure recording session: \(error.localizedDescription)"
            logger.error("\(message)")
            DispatchQueue.main.async { [weak self] in
                self?.state = .error(message)
            }
            throw error
        }
    }

    /// Configure the audio session for affirmation playback.
    ///
    /// Uses `.playback` category for best audio quality. Supports background
    /// audio mixing when ambient music is enabled.
    func configureForPlayback() throws {
        do {
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.allowBluetooth]
            )
            try audioSession.setActive(true)

            DispatchQueue.main.async { [weak self] in
                self?.state = .playing
            }

            updateHeadphoneStatus()
            logger.info("Audio session configured for playback")
        } catch {
            let message = "Failed to configure playback session: \(error.localizedDescription)"
            logger.error("\(message)")
            DispatchQueue.main.async { [weak self] in
                self?.state = .error(message)
            }
            throw error
        }
    }

    /// Deactivate the audio session and return to idle state.
    func deactivate() {
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            DispatchQueue.main.async { [weak self] in
                self?.state = .idle
            }
            logger.info("Audio session deactivated")
        } catch {
            logger.warning("Failed to deactivate audio session: \(error.localizedDescription)")
            DispatchQueue.main.async { [weak self] in
                self?.state = .idle
            }
        }
    }

    /// Mark the session as paused (e.g., user manually paused or headphones disconnected).
    func markPaused() {
        DispatchQueue.main.async { [weak self] in
            self?.state = .paused
        }
    }

    /// Mark the session as playing (e.g., user resumed playback).
    func markPlaying() {
        DispatchQueue.main.async { [weak self] in
            self?.state = .playing
        }
    }

    // MARK: - Volume Helpers

    /// Calculate the absolute volume for background music based on the voice volume.
    /// Background music plays at `backgroundMusicVolume` (default 60%) relative to voice.
    var absoluteBackgroundMusicVolume: Float {
        return voiceVolume * backgroundMusicVolume
    }

    // MARK: - Route Change Handling

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        switch reason {
        case .oldDeviceUnavailable:
            // CRITICAL: Headphones were disconnected. Immediately pause to prevent
            // affirmation audio from playing through external speakers.
            // This is a non-negotiable safety/privacy feature.
            logger.warning("Headphones disconnected - immediately pausing playback")

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.isHeadphonesConnected = false

                if case .playing = self.state {
                    self.state = .paused
                    self.onHeadphoneDisconnect?()
                }
            }

        case .newDeviceAvailable:
            logger.info("New audio device available")
            DispatchQueue.main.async { [weak self] in
                self?.updateHeadphoneStatus()
            }

        case .categoryChange:
            logger.debug("Audio category changed")

        default:
            logger.debug("Audio route change reason: \(reasonValue)")
            DispatchQueue.main.async { [weak self] in
                self?.updateHeadphoneStatus()
            }
        }
    }

    // MARK: - Interruption Handling

    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            logger.info("Audio session interrupted (began)")
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if case .playing = self.state {
                    self.state = .paused
                }
                self.onInterruption?(true)
            }

        case .ended:
            let shouldResume: Bool
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                shouldResume = options.contains(.shouldResume)
            } else {
                shouldResume = false
            }

            logger.info("Audio session interruption ended (shouldResume: \(shouldResume))")
            DispatchQueue.main.async { [weak self] in
                self?.onInterruption?(false)
            }

        @unknown default:
            logger.debug("Unknown audio interruption type: \(typeValue)")
        }
    }

    // MARK: - Headphone Detection

    private func updateHeadphoneStatus() {
        let currentRoute = audioSession.currentRoute
        let hasHeadphones = currentRoute.outputs.contains { output in
            switch output.portType {
            case .headphones, .bluetoothA2DP, .bluetoothHFP, .bluetoothLE, .airPlay:
                return true
            default:
                return false
            }
        }

        DispatchQueue.main.async { [weak self] in
            self?.isHeadphonesConnected = hasHeadphones
        }
    }
}
