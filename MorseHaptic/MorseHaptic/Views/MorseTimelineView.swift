import SwiftUI

// MARK: - Morse Timeline View

/// Animated horizontal timeline showing dots and dashes
/// Scrolls to keep the active element centered during playback
struct MorseTimelineView: View {
    @ObservedObject var coordinator: PlaybackCoordinator

    @State private var scrollProxy: ScrollViewProxy?
    @Namespace private var timelineNamespace

    private let elementSpacing: CGFloat = 8
    private let letterSpacing: CGFloat = 16
    private let wordSpacing: CGFloat = 28

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            progressBar
                .padding(.bottom, 12)

            // Timeline
            if coordinator.sequence.visibleElements.isEmpty {
                emptyState
            } else {
                timelineContent
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 3)

                // Fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.cyan, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, geo.size.width * coordinator.progress), height: 3)
                    .animation(.linear(duration: 0.05), value: coordinator.progress)
            }
        }
        .frame(height: 3)
        .padding(.horizontal, 20)
    }

    // MARK: - Timeline Content

    private var timelineContent: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    // Leading spacer for centering
                    Spacer()
                        .frame(width: 40)

                    ForEach(Array(coordinator.sequence.elements.enumerated()), id: \.element.id) { index, element in
                        elementView(for: element, at: index)
                            .id(element.id)
                    }

                    // Trailing spacer
                    Spacer()
                        .frame(width: 40)
                }
                .padding(.vertical, 20)
            }
            .onAppear {
                scrollProxy = proxy
            }
            .onChange(of: coordinator.activeElementIndex) { _, newIndex in
                guard let newIndex = newIndex else { return }
                let element = coordinator.sequence.elements[newIndex]
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(element.id, anchor: .center)
                }
            }
        }
        .frame(height: 60)
    }

    // MARK: - Element Views

    @ViewBuilder
    private func elementView(for element: TimedMorseElement, at index: Int) -> some View {
        let isActive = coordinator.activeElementIndex == index
        let isPast = coordinator.isPlaying && coordinator.currentTime > element.endTime

        switch element.signal {
        case .dot, .dash:
            SignalElementView(element: element, isActive: isActive, isPast: isPast)
                .padding(.horizontal, elementSpacing / 2)

        case .elementGap:
            Spacer()
                .frame(width: elementSpacing)

        case .letterGap:
            letterGapView(isActive: isActive)

        case .wordGap:
            wordGapView(isActive: isActive)
        }
    }

    private func letterGapView(isActive: Bool) -> some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: letterSpacing)
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(isActive ? 0.15 : 0.04))
                    .frame(width: 1, height: 20)
            )
    }

    private func wordGapView(isActive: Bool) -> some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: wordSpacing)
            .overlay(
                WordGapView(isActive: isActive)
            )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 8, height: 8)
            }
            Capsule()
                .fill(Color.white.opacity(0.08))
                .frame(width: 24, height: 8)
            ForEach(0..<2, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 8, height: 8)
            }
        }
        .frame(height: 60)
    }
}

// MARK: - Radial Morse Visualization

/// An alternative radial/circular Morse visualization
struct RadialMorseView: View {
    @ObservedObject var coordinator: PlaybackCoordinator

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 - 20
            let elements = coordinator.sequence.visibleElements

            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.06), lineWidth: 2)
                    .frame(width: radius * 2, height: radius * 2)

                // Progress arc
                if coordinator.isPlaying || coordinator.playbackState == .paused {
                    Circle()
                        .trim(from: 0, to: coordinator.progress)
                        .stroke(
                            AngularGradient(
                                colors: [.cyan.opacity(0.5), .orange.opacity(0.5)],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        .frame(width: radius * 2, height: radius * 2)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.05), value: coordinator.progress)
                }

                // Signal elements around the ring
                ForEach(Array(elements.enumerated()), id: \.element.id) { index, element in
                    let angle = angleForElement(index: index, total: elements.count)
                    let elementIsActive = isElementActive(element)
                    let elementIsPast = isElementPast(element)

                    signalDot(for: element, isActive: elementIsActive, isPast: elementIsPast)
                        .position(
                            x: center.x + radius * cos(angle),
                            y: center.y + radius * sin(angle)
                        )
                }

                // Center indicator
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                coordinator.isPlaying ? Color.cyan.opacity(0.3) : Color.white.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 60, height: 60)
                    .animation(.easeInOut(duration: 0.5), value: coordinator.isPlaying)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func angleForElement(index: Int, total: Int) -> CGFloat {
        guard total > 0 else { return 0 }
        let fraction = CGFloat(index) / CGFloat(total)
        return fraction * 2 * .pi - .pi / 2 // Start from top
    }

    private func isElementActive(_ element: TimedMorseElement) -> Bool {
        coordinator.currentTime >= element.startTime && coordinator.currentTime < element.endTime
    }

    private func isElementPast(_ element: TimedMorseElement) -> Bool {
        coordinator.currentTime > element.endTime
    }

    @ViewBuilder
    private func signalDot(for element: TimedMorseElement, isActive: Bool, isPast: Bool) -> some View {
        let size: CGFloat = element.signal == .dot ? 6 : 10

        Group {
            if element.signal == .dot {
                Circle()
                    .fill(isActive ? Color.cyan : (isPast ? Color.cyan.opacity(0.2) : Color.cyan.opacity(0.5)))
            } else {
                Capsule()
                    .fill(isActive ? Color.orange : (isPast ? Color.orange.opacity(0.2) : Color.orange.opacity(0.5)))
            }
        }
        .frame(width: size, height: element.signal == .dot ? size : 6)
        .shadow(color: isActive ? (element.signal == .dot ? .cyan : .orange).opacity(0.8) : .clear, radius: isActive ? 8 : 0)
        .scaleEffect(isActive ? 1.8 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isActive)
    }
}
