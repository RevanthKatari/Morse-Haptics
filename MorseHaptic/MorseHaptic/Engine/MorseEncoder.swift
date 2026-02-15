import Foundation

// MARK: - Morse Encoder

/// Pure function encoder that converts text to Morse code sequences
final class MorseEncoder {

    // MARK: - Morse Code Table

    static let morseTable: [Character: [MorseSignal]] = [
        "A": [.dot, .dash],
        "B": [.dash, .dot, .dot, .dot],
        "C": [.dash, .dot, .dash, .dot],
        "D": [.dash, .dot, .dot],
        "E": [.dot],
        "F": [.dot, .dot, .dash, .dot],
        "G": [.dash, .dash, .dot],
        "H": [.dot, .dot, .dot, .dot],
        "I": [.dot, .dot],
        "J": [.dot, .dash, .dash, .dash],
        "K": [.dash, .dot, .dash],
        "L": [.dot, .dash, .dot, .dot],
        "M": [.dash, .dash],
        "N": [.dash, .dot],
        "O": [.dash, .dash, .dash],
        "P": [.dot, .dash, .dash, .dot],
        "Q": [.dash, .dash, .dot, .dash],
        "R": [.dot, .dash, .dot],
        "S": [.dot, .dot, .dot],
        "T": [.dash],
        "U": [.dot, .dot, .dash],
        "V": [.dot, .dot, .dot, .dash],
        "W": [.dot, .dash, .dash],
        "X": [.dash, .dot, .dot, .dash],
        "Y": [.dash, .dot, .dash, .dash],
        "Z": [.dash, .dash, .dot, .dot],
        "0": [.dash, .dash, .dash, .dash, .dash],
        "1": [.dot, .dash, .dash, .dash, .dash],
        "2": [.dot, .dot, .dash, .dash, .dash],
        "3": [.dot, .dot, .dot, .dash, .dash],
        "4": [.dot, .dot, .dot, .dot, .dash],
        "5": [.dot, .dot, .dot, .dot, .dot],
        "6": [.dash, .dot, .dot, .dot, .dot],
        "7": [.dash, .dash, .dot, .dot, .dot],
        "8": [.dash, .dash, .dash, .dot, .dot],
        "9": [.dash, .dash, .dash, .dash, .dot],
        ".": [.dot, .dash, .dot, .dash, .dot, .dash],
        ",": [.dash, .dash, .dot, .dot, .dash, .dash],
        "?": [.dot, .dot, .dash, .dash, .dot, .dot],
        "'": [.dot, .dash, .dash, .dash, .dash, .dot],
        "!": [.dash, .dot, .dash, .dot, .dash, .dash],
        "/": [.dash, .dot, .dot, .dash, .dot],
        "(": [.dash, .dot, .dash, .dash, .dot],
        ")": [.dash, .dot, .dash, .dash, .dot, .dash],
        "&": [.dot, .dash, .dot, .dot, .dot],
        ":": [.dash, .dash, .dash, .dot, .dot, .dot],
        ";": [.dash, .dot, .dash, .dot, .dash, .dot],
        "=": [.dash, .dot, .dot, .dot, .dash],
        "+": [.dot, .dash, .dot, .dash, .dot],
        "-": [.dash, .dot, .dot, .dot, .dot, .dash],
        "\"": [.dot, .dash, .dot, .dot, .dash, .dot],
        "@": [.dot, .dash, .dash, .dot, .dash, .dot],
    ]

    // MARK: - Encoding

    /// Convert a string to a Morse code representation string (dots and dashes)
    static func toMorseString(_ text: String) -> String {
        let uppercased = text.uppercased()
        var result: [String] = []

        for char in uppercased {
            if char == " " {
                result.append("/")
            } else if let signals = morseTable[char] {
                let morseChar = signals.map { signal -> String in
                    switch signal {
                    case .dot: return "·"
                    case .dash: return "−"
                    default: return ""
                    }
                }.joined()
                result.append(morseChar)
            }
        }

        return result.joined(separator: " ")
    }

    /// Convert text to a timed Morse sequence
    static func encode(_ text: String, config: MorseTimingConfig) -> MorseSequence {
        let uppercased = text.uppercased()
        guard !uppercased.isEmpty else { return .empty }

        var elements: [TimedMorseElement] = []
        var currentTime: Double = 0
        var charIndex = 0

        let words = uppercased.split(separator: " ", omittingEmptySubsequences: false)

        for (wordIdx, word) in words.enumerated() {
            for (letterIdx, char) in word.enumerated() {
                guard let signals = morseTable[char] else { continue }

                for (signalIdx, signal) in signals.enumerated() {
                    let duration = config.duration(for: signal)
                    elements.append(TimedMorseElement(
                        signal: signal,
                        startTime: currentTime,
                        duration: duration,
                        character: char,
                        characterIndex: charIndex
                    ))
                    currentTime += duration

                    // Add element gap between signals within a letter
                    if signalIdx < signals.count - 1 {
                        let gapDuration = config.elementGapDuration
                        elements.append(TimedMorseElement(
                            signal: .elementGap,
                            startTime: currentTime,
                            duration: gapDuration,
                            character: char,
                            characterIndex: charIndex
                        ))
                        currentTime += gapDuration
                    }
                }

                charIndex += 1

                // Add letter gap between characters
                if letterIdx < word.count - 1 {
                    let gapDuration = config.letterGapDuration
                    elements.append(TimedMorseElement(
                        signal: .letterGap,
                        startTime: currentTime,
                        duration: gapDuration,
                        characterIndex: charIndex
                    ))
                    currentTime += gapDuration
                }
            }

            // Add word gap between words
            if wordIdx < words.count - 1 {
                charIndex += 1 // for the space
                let gapDuration = config.wordGapDuration
                elements.append(TimedMorseElement(
                    signal: .wordGap,
                    startTime: currentTime,
                    duration: gapDuration,
                    characterIndex: charIndex
                ))
                currentTime += gapDuration
            }
        }

        return MorseSequence(
            elements: elements,
            totalDuration: currentTime,
            sourceText: text
        )
    }

    /// Get the Morse code pattern for a single character
    static func signals(for character: Character) -> [MorseSignal]? {
        return morseTable[Character(character.uppercased())]
    }
}
