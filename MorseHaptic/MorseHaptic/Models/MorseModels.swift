import Foundation

// MARK: - Morse Signal Element

/// Represents a single element in a Morse code sequence
enum MorseSignal: Equatable, Hashable, Identifiable {
    case dot
    case dash
    case elementGap      // Gap between dots/dashes within a letter
    case letterGap       // Gap between letters
    case wordGap         // Gap between words

    var id: String {
        switch self {
        case .dot: return "dot"
        case .dash: return "dash"
        case .elementGap: return "elementGap"
        case .letterGap: return "letterGap"
        case .wordGap: return "wordGap"
        }
    }

    var isAudible: Bool {
        switch self {
        case .dot, .dash: return true
        default: return false
        }
    }

    var isGap: Bool { !isAudible }

    /// Duration in units (1 unit = dot duration)
    var unitDuration: Double {
        switch self {
        case .dot: return 1.0
        case .dash: return 3.0
        case .elementGap: return 1.0
        case .letterGap: return 3.0
        case .wordGap: return 7.0
        }
    }

    /// Haptic intensity (0..1)
    var hapticIntensity: Float {
        switch self {
        case .dot: return 0.5
        case .dash: return 1.0
        default: return 0.0
        }
    }

    /// Haptic sharpness (0..1)
    var hapticSharpness: Float {
        switch self {
        case .dot: return 0.4
        case .dash: return 0.7
        default: return 0.0
        }
    }
}

// MARK: - Morse Element with Timing

/// A signal element positioned in time
struct TimedMorseElement: Identifiable, Equatable {
    let id: UUID
    let signal: MorseSignal
    let startTime: Double      // In seconds from the beginning
    let duration: Double       // In seconds
    let character: Character?  // The source character this belongs to
    let characterIndex: Int    // Index in the flattened character array

    init(signal: MorseSignal, startTime: Double, duration: Double, character: Character? = nil, characterIndex: Int = 0) {
        self.id = UUID()
        self.signal = signal
        self.startTime = startTime
        self.duration = duration
        self.character = character
        self.characterIndex = characterIndex
    }

    var endTime: Double { startTime + duration }
}

// MARK: - Morse Sequence

/// A complete Morse code sequence with timing information
struct MorseSequence: Equatable {
    let elements: [TimedMorseElement]
    let totalDuration: Double
    let sourceText: String

    /// Only the visible (non-gap) elements for display
    var visibleElements: [TimedMorseElement] {
        elements.filter { $0.signal.isAudible }
    }

    static let empty = MorseSequence(elements: [], totalDuration: 0, sourceText: "")
}

// MARK: - Playback State

enum PlaybackState: Equatable {
    case idle
    case playing
    case paused
    case finished
}

// MARK: - Speed Configuration

struct MorseTimingConfig: Equatable {
    /// Words per minute
    var wpm: Double

    /// Base unit duration in seconds (derived from WPM)
    /// Standard "PARIS" = 50 units, so unit = 60 / (50 * WPM)
    var unitDuration: Double {
        60.0 / (50.0 * wpm)
    }

    /// Duration for a dot signal in seconds
    var dotDuration: Double { unitDuration }

    /// Duration for a dash signal in seconds
    var dashDuration: Double { unitDuration * 3.0 }

    /// Gap between elements (dots/dashes) in a character
    var elementGapDuration: Double { unitDuration }

    /// Gap between characters
    var letterGapDuration: Double { unitDuration * 3.0 }

    /// Gap between words
    var wordGapDuration: Double { unitDuration * 7.0 }

    /// Duration for a given signal type
    func duration(for signal: MorseSignal) -> Double {
        switch signal {
        case .dot: return dotDuration
        case .dash: return dashDuration
        case .elementGap: return elementGapDuration
        case .letterGap: return letterGapDuration
        case .wordGap: return wordGapDuration
        }
    }

    static let slow = MorseTimingConfig(wpm: 5)
    static let medium = MorseTimingConfig(wpm: 12)
    static let fast = MorseTimingConfig(wpm: 20)
    static let `default` = MorseTimingConfig(wpm: 10)
}
