import SwiftUI

// MARK: - Speed Control View

/// Elegant speed slider with WPM display
struct SpeedControlView: View {
    @Binding var wpm: Double

    private let minWPM: Double = 3
    private let maxWPM: Double = 25

    var body: some View {
        VStack(spacing: 10) {
            // WPM display
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(wpm))")
                    .font(.system(size: 28, weight: .light, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .contentTransition(.numericText())
                    .animation(.snappy, value: Int(wpm))

                Text("WPM")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.35))
                    .textCase(.uppercase)
                    .tracking(1.5)
            }

            // Custom slider
            GeometryReader { geo in
                let width = geo.size.width
                let normalizedValue = (wpm - minWPM) / (maxWPM - minWPM)
                let xPosition = normalizedValue * width

                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 4)

                    // Filled track
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.cyan.opacity(0.6), .orange.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(4, xPosition), height: 4)

                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                        .shadow(color: .white.opacity(0.2), radius: 6)
                        .offset(x: max(0, min(xPosition - 10, width - 20)))
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let fraction = max(0, min(1, value.location.x / width))
                            wpm = minWPM + fraction * (maxWPM - minWPM)
                        }
                )
            }
            .frame(height: 20)

            // Labels
            HStack {
                Text("Slow")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.2))

                Spacer()

                Text("Fast")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.2))
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Loop Toggle

struct LoopToggleView: View {
    @Binding var isLooping: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isLooping.toggle()
            }
        } label: {
            Image(systemName: "repeat")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isLooping ? Color.cyan : Color.white.opacity(0.35))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isLooping ? Color.cyan.opacity(0.15) : Color.white.opacity(0.04))
                )
                .overlay(
                    Circle()
                        .stroke(isLooping ? Color.cyan.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
