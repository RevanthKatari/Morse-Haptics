import Foundation
import Combine
import SwiftUI

// MARK: - Playback Coordinator

/// Orchestrates the synchronized playback of haptics and visual timeline
/// Acts as the single source of truth for playback state
@MainActor
final class PlaybackCoordinator: ObservableObject {

    // MARK: - Published State

    @Published var inputText: String = "" {
        didSet {
            if inputText != oldValue {
                updateMorseSequence()
            }
        }
    }

    @Published private(set) var morseString: String = ""
    @Published private(set) var sequence: MorseSequence = .empty
    @Published private(set) var playbackState: PlaybackState = .idle
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var activeElementIndex: Int? = nil
    @Published var timingConfig: MorseTimingConfig = .default {
        didSet {
            if timingConfig != oldValue {
                updateMorseSequence()
            }
        }
    }
    @Published var isLooping: Bool = false

    // MARK: - Speed Control

    var wpm: Double {
        get { timingConfig.wpm }
        set {
            timingConfig = MorseTimingConfig(wpm: newValue)
        }
    }

    // MARK: - Private

    private let hapticEngine = HapticEngine()
    private var displayLink: CADisplayLink?
    private var playbackStartTime: CFTimeInterval = 0
    private var pausedTime: Double = 0
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed

    var progress: Double {
        guard sequence.totalDuration > 0 else { return 0 }
        return min(currentTime / sequence.totalDuration, 1.0)
    }

    var canPlay: Bool {
        !sequence.elements.isEmpty
    }

    var isPlaying: Bool {
        playbackState == .playing
    }

    // MARK: - Init

    init() {}

    // MARK: - Morse Encoding

    private func updateMorseSequence() {
        let wasPlaying = playbackState == .playing
        if wasPlaying {
            stopPlayback()
        }

        morseString = MorseEncoder.toMorseString(inputText)
        sequence = MorseEncoder.encode(inputText, config: timingConfig)
        currentTime = 0
        activeElementIndex = nil
    }

    // MARK: - Playback Controls

    func play() {
        guard canPlay else { return }

        switch playbackState {
        case .idle, .finished:
            startPlayback(from: 0)
        case .paused:
            resumePlayback()
        case .playing:
            break
        }
    }

    func pause() {
        guard playbackState == .playing else { return }
        pausedTime = currentTime
        playbackState = .paused
        stopDisplayLink()
        hapticEngine.pause()
    }

    func stop() {
        stopPlayback()
    }

    func togglePlayPause() {
        if playbackState == .playing {
            pause()
        } else {
            play()
        }
    }

    // MARK: - Internal Playback

    private func startPlayback(from time: Double) {
        currentTime = time
        pausedTime = time
        playbackState = .playing

        // Start haptics
        if hapticEngine.supportsHaptics {
            do {
                // If starting from the beginning, play the full sequence
                if time == 0 {
                    try hapticEngine.play(sequence: sequence)
                }
            } catch {
                print("PlaybackCoordinator: Haptic play error: \(error)")
            }
        }

        // Start visual sync via display link
        startDisplayLink()
    }

    private func resumePlayback() {
        playbackState = .playing
        hapticEngine.resume()
        startDisplayLink()
    }

    private func stopPlayback() {
        playbackState = .idle
        stopDisplayLink()
        hapticEngine.stop()
        currentTime = 0
        pausedTime = 0
        activeElementIndex = nil
    }

    // MARK: - Display Link (Frame-Accurate Timing)

    private func startDisplayLink() {
        stopDisplayLink()
        playbackStartTime = CACurrentMediaTime() - pausedTime

        let link = CADisplayLink(target: DisplayLinkTarget { [weak self] in
            self?.displayLinkFired()
        }, selector: #selector(DisplayLinkTarget.handleDisplayLink))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    private func displayLinkFired() {
        guard playbackState == .playing else { return }

        let elapsed = CACurrentMediaTime() - playbackStartTime
        currentTime = elapsed

        // Update active element
        updateActiveElement()

        // Check if playback finished
        if elapsed >= sequence.totalDuration {
            if isLooping {
                // Reset and restart
                hapticEngine.stop()
                startPlayback(from: 0)
            } else {
                playbackState = .finished
                stopDisplayLink()
                hapticEngine.stop()
                activeElementIndex = nil
            }
        }
    }

    private func updateActiveElement() {
        let time = currentTime
        activeElementIndex = sequence.elements.firstIndex { element in
            time >= element.startTime && time < element.endTime
        }
    }
}

// MARK: - DisplayLink Target (avoid retain cycle)

private class DisplayLinkTarget {
    let callback: () -> Void

    init(callback: @escaping () -> Void) {
        self.callback = callback
    }

    @objc func handleDisplayLink() {
        callback()
    }
}
