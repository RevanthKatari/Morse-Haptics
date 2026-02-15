import SwiftUI

// MARK: - Morse Text Display

/// Displays the Morse code string representation with styling
struct MorseTextView: View {
    let morseString: String
    let isPlaying: Bool

    @State private var appeared = false

    var body: some View {
        if morseString.isEmpty {
            Text("· − · ·   · − −   − · −")
                .font(.system(size: 18, weight: .light, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.12))
                .animation(.easeInOut, value: morseString)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(Array(morseString.enumerated()), id: \.offset) { index, char in
                        Text(String(char))
                            .font(.system(size: 20, weight: charWeight(char), design: .monospaced))
                            .foregroundStyle(charColor(char))
                            .opacity(appeared ? 1 : 0)
                            .animation(
                                .easeOut(duration: 0.3).delay(Double(index) * 0.015),
                                value: appeared
                            )
                    }
                }
                .padding(.horizontal, 20)
            }
            .onAppear {
                appeared = true
            }
            .onChange(of: morseString) { _, _ in
                appeared = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    appeared = true
                }
            }
        }
    }

    private func charWeight(_ char: Character) -> Font.Weight {
        switch char {
        case "−": return .bold
        case "·": return .medium
        default: return .light
        }
    }

    private func charColor(_ char: Character) -> Color {
        switch char {
        case "−": return .orange.opacity(0.9)
        case "·": return .cyan.opacity(0.9)
        case "/": return .white.opacity(0.2)
        default: return .white.opacity(0.3)
        }
    }
}

// MARK: - Character Label

/// Shows the current character being played
struct ActiveCharacterView: View {
    let character: Character?
    let isPlaying: Bool

    var body: some View {
        Text(character.map { String($0) } ?? " ")
            .font(.system(size: 48, weight: .ultraLight, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [.white.opacity(0.9), .white.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 70, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isPlaying ? 0.06 : 0.03))
                    .blur(radius: 1)
            )
            .scaleEffect(isPlaying && character != nil ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: character)
            .animation(.easeInOut(duration: 0.2), value: isPlaying)
    }
}
