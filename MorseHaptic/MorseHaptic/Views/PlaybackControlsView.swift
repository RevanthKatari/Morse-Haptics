import SwiftUI

// MARK: - Playback Controls

/// Play / Pause / Stop controls with elegant animated buttons
struct PlaybackControlsView: View {
    @ObservedObject var coordinator: PlaybackCoordinator

    var body: some View {
        HStack(spacing: 32) {
            // Stop button
            stopButton

            // Play/Pause button (primary)
            playPauseButton

            // Loop toggle
            LoopToggleView(isLooping: $coordinator.isLooping)
        }
    }

    // MARK: - Play / Pause

    private var playPauseButton: some View {
        Button {
            coordinator.togglePlayPause()
        } label: {
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                buttonAccentColor.opacity(coordinator.isPlaying ? 0.2 : 0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 45
                        )
                    )
                    .frame(width: 90, height: 90)

                // Button background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                buttonAccentColor.opacity(0.25),
                                buttonAccentColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle()
                            .stroke(buttonAccentColor.opacity(0.3), lineWidth: 1.5)
                    )

                // Icon
                Image(systemName: coordinator.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.95))
                    .offset(x: coordinator.isPlaying ? 0 : 2) // Optical alignment for play icon
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!coordinator.canPlay)
        .opacity(coordinator.canPlay ? 1.0 : 0.3)
        .animation(.easeInOut(duration: 0.2), value: coordinator.canPlay)
    }

    private var buttonAccentColor: Color {
        coordinator.isPlaying ? .orange : .cyan
    }

    // MARK: - Stop

    private var stopButton: some View {
        Button {
            coordinator.stop()
        } label: {
            Image(systemName: "stop.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.white.opacity(stopOpacity))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.04))
                )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(coordinator.playbackState == .idle)
    }

    private var stopOpacity: Double {
        coordinator.playbackState == .idle ? 0.15 : 0.5
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
