import CoreHaptics
import UIKit

// MARK: - Haptic Engine Manager

/// Manages Core Haptics for Morse code playback
/// Builds haptic patterns from Morse sequences and plays them with precise timing
final class HapticEngine {

    // MARK: - Properties

    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?
    private var isEngineRunning = false

    /// Whether the device supports haptics
    var supportsHaptics: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    // MARK: - Lifecycle

    init() {
        prepareEngine()
    }

    deinit {
        stop()
        engine = nil
    }

    // MARK: - Engine Setup

    private func prepareEngine() {
        guard supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()

            engine?.stoppedHandler = { [weak self] reason in
                self?.isEngineRunning = false
            }

            engine?.resetHandler = { [weak self] in
                do {
                    try self?.engine?.start()
                    self?.isEngineRunning = true
                } catch {
                    print("HapticEngine: Failed to restart: \(error)")
                }
            }

            try engine?.start()
            isEngineRunning = true
        } catch {
            print("HapticEngine: Failed to create engine: \(error)")
        }
    }

    private func ensureEngineRunning() throws {
        guard let engine = engine else {
            throw HapticError.engineNotAvailable
        }

        if !isEngineRunning {
            try engine.start()
            isEngineRunning = true
        }
    }

    // MARK: - Pattern Building

    /// Build a complete haptic pattern from a Morse sequence
    func buildPattern(from sequence: MorseSequence) throws -> CHHapticPattern {
        var events: [CHHapticEvent] = []

        for element in sequence.elements {
            guard element.signal.isAudible else { continue }

            let intensity = CHHapticEventParameter(
                parameterID: .hapticIntensity,
                value: element.signal.hapticIntensity
            )
            let sharpness = CHHapticEventParameter(
                parameterID: .hapticSharpness,
                value: element.signal.hapticSharpness
            )

            switch element.signal {
            case .dot:
                // Dot: a transient tap followed by a very short continuous
                let tap = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: element.startTime
                )
                events.append(tap)

                // Add a short continuous to give it body
                if element.duration > 0.02 {
                    let softIntensity = CHHapticEventParameter(
                        parameterID: .hapticIntensity,
                        value: element.signal.hapticIntensity * 0.6
                    )
                    let softSharpness = CHHapticEventParameter(
                        parameterID: .hapticSharpness,
                        value: element.signal.hapticSharpness * 0.5
                    )
                    let sustain = CHHapticEvent(
                        eventType: .hapticContinuous,
                        parameters: [softIntensity, softSharpness],
                        relativeTime: element.startTime,
                        duration: element.duration
                    )
                    events.append(sustain)
                }

            case .dash:
                // Dash: continuous haptic for the full duration with a transient at the start
                let tap = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: element.startTime
                )
                events.append(tap)

                let continuous = CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [intensity, sharpness],
                    relativeTime: element.startTime + 0.01,
                    duration: element.duration - 0.01
                )
                events.append(continuous)

            default:
                break
            }
        }

        // Add subtle "breath" haptics during word gaps to maintain presence
        for element in sequence.elements where element.signal == .wordGap {
            let breathIntensity = CHHapticEventParameter(
                parameterID: .hapticIntensity,
                value: 0.08
            )
            let breathSharpness = CHHapticEventParameter(
                parameterID: .hapticSharpness,
                value: 0.1
            )

            // Gentle pulse in the middle of the word gap
            let midPoint = element.startTime + element.duration * 0.5
            let breathEvent = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [breathIntensity, breathSharpness],
                relativeTime: midPoint
            )
            events.append(breathEvent)
        }

        guard !events.isEmpty else {
            throw HapticError.emptyPattern
        }

        return try CHHapticPattern(events: events, parameters: [])
    }

    // MARK: - Playback

    /// Play a Morse sequence as haptics
    func play(sequence: MorseSequence) throws {
        try ensureEngineRunning()

        // Stop existing player
        try? player?.stop(atTime: CHHapticTimeImmediate)

        let pattern = try buildPattern(from: sequence)
        player = try engine?.makeAdvancedPlayer(with: pattern)

        // Auto-stop callback
        player?.completionHandler = { [weak self] error in
            self?.player = nil
        }

        try player?.start(atTime: CHHapticTimeImmediate)
    }

    /// Pause haptic playback
    func pause() {
        try? player?.pause(atTime: CHHapticTimeImmediate)
    }

    /// Resume haptic playback
    func resume() {
        try? player?.resume(atTime: CHHapticTimeImmediate)
    }

    /// Stop haptic playback
    func stop() {
        try? player?.stop(atTime: CHHapticTimeImmediate)
        player = nil
    }

    // MARK: - Single Haptic Feedback

    /// Play a single dot haptic
    func playDotFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Play a single dash haptic
    func playDashFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Errors

enum HapticError: Error, LocalizedError {
    case engineNotAvailable
    case emptyPattern

    var errorDescription: String? {
        switch self {
        case .engineNotAvailable:
            return "Haptic engine is not available on this device"
        case .emptyPattern:
            return "Cannot create an empty haptic pattern"
        }
    }
}
