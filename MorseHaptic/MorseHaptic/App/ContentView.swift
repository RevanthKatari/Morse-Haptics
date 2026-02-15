import SwiftUI

// MARK: - Content View

/// Main app view: text input → visual timeline → playback controls
struct ContentView: View {
    @StateObject private var coordinator = PlaybackCoordinator()
    @FocusState private var isInputFocused: Bool
    @State private var showRadialView = false

    var body: some View {
        ZStack {
            // Background
            backgroundGradient

            // Main content
            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.top, 8)

                Spacer()
                    .frame(height: 24)

                // Text input
                InputView(
                    text: $coordinator.inputText,
                    morseString: coordinator.morseString,
                    isInputFocused: $isInputFocused
                )

                Spacer()
                    .frame(height: 20)

                // Active character display
                activeCharacterSection

                Spacer()
                    .frame(height: 8)

                // Visual timeline
                visualizationSection

                Spacer()

                // Speed control
                SpeedControlView(wpm: Binding(
                    get: { coordinator.wpm },
                    set: { coordinator.wpm = $0 }
                ))
                .padding(.bottom, 20)

                // Playback controls
                PlaybackControlsView(coordinator: coordinator)
                    .padding(.bottom, 16)
            }
            .padding(.top, 4)
        }
        .preferredColorScheme(.dark)
        .onTapGesture {
            isInputFocused = false
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            Color.black

            // Subtle gradient overlay
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.03, blue: 0.08),
                    Color.black,
                    Color(red: 0.02, green: 0.02, blue: 0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Ambient glow when playing
            if coordinator.isPlaying {
                RadialGradient(
                    colors: [
                        Color.cyan.opacity(0.03),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 100,
                    endRadius: 400
                )
                .animation(.easeInOut(duration: 1), value: coordinator.isPlaying)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("MORSE")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .tracking(4)

                // Subtle status indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 5, height: 5)
                        .shadow(color: statusColor.opacity(0.6), radius: 3)

                    Text(statusText)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.25))
                        .textCase(.uppercase)
                        .tracking(1)
                }
            }

            Spacer()

            // View mode toggle
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showRadialView.toggle()
                }
            } label: {
                Image(systemName: showRadialView ? "waveform.path" : "circle.dotted")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.35))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.04))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
    }

    private var statusColor: Color {
        switch coordinator.playbackState {
        case .idle: return .white.opacity(0.3)
        case .playing: return .cyan
        case .paused: return .orange
        case .finished: return .green.opacity(0.7)
        }
    }

    private var statusText: String {
        switch coordinator.playbackState {
        case .idle: return "Ready"
        case .playing: return "Playing"
        case .paused: return "Paused"
        case .finished: return "Complete"
        }
    }

    // MARK: - Active Character

    private var activeCharacterSection: some View {
        Group {
            if coordinator.isPlaying || coordinator.playbackState == .paused {
                let activeElement = coordinator.activeElementIndex.flatMap { idx in
                    idx < coordinator.sequence.elements.count ? coordinator.sequence.elements[idx] : nil
                }

                ActiveCharacterView(
                    character: activeElement?.character,
                    isPlaying: coordinator.isPlaying
                )
                .transition(.scale.combined(with: .opacity))
            } else {
                // Placeholder to maintain layout
                Color.clear
                    .frame(width: 70, height: 70)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: coordinator.playbackState)
    }

    // MARK: - Visualization

    private var visualizationSection: some View {
        Group {
            if showRadialView {
                RadialMorseView(coordinator: coordinator)
                    .frame(height: 200)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            } else {
                MorseTimelineView(coordinator: coordinator)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showRadialView)
    }
}

// MARK: - Previews

#Preview {
    ContentView()
}
