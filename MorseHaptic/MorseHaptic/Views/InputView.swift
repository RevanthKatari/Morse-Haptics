import SwiftUI

// MARK: - Input View

/// Text input field with Morse preview, styled for dark mode
struct InputView: View {
    @Binding var text: String
    let morseString: String
    @FocusState.Binding var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Text field
            textField

            // Morse text preview
            MorseTextView(morseString: morseString, isPlaying: false)
                .frame(height: 30)
        }
    }

    // MARK: - Text Field

    private var textField: some View {
        HStack(spacing: 12) {
            TextField("", text: $text, prompt: promptText)
                .font(.system(size: 22, weight: .light, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.95))
                .tint(.cyan)
                .focused($isInputFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit {
                    isInputFocused = false
                }

            // Clear button
            if !text.isEmpty {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        text = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.white.opacity(0.25))
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isInputFocused
                                ? Color.cyan.opacity(0.3)
                                : Color.white.opacity(0.06),
                            lineWidth: 1
                        )
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isInputFocused)
        .padding(.horizontal, 20)
    }

    private var promptText: Text {
        Text("Type something...")
            .font(.system(size: 22, weight: .light, design: .rounded))
            .foregroundColor(.white.opacity(0.2))
    }
}
