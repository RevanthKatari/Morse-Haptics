import SwiftUI

// MARK: - Signal Element View

/// Renders a single dot or dash with animated state
struct SignalElementView: View {
    let element: TimedMorseElement
    let isActive: Bool
    let isPast: Bool

    // Animation state
    @State private var appeared = false

    private var dotSize: CGFloat { 10 }
    private var dashWidth: CGFloat { 32 }
    private var elementHeight: CGFloat { 10 }
    private var cornerRadius: CGFloat { 5 }

    var body: some View {
        Group {
            switch element.signal {
            case .dot:
                dotView
            case .dash:
                dashView
            default:
                EmptyView()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                appeared = true
            }
        }
    }

    // MARK: - Dot

    private var dotView: some View {
        Circle()
            .fill(dotFill)
            .frame(width: dotSize, height: dotSize)
            .shadow(color: isActive ? activeColor.opacity(0.8) : .clear, radius: isActive ? 12 : 0)
            .scaleEffect(isActive ? 1.6 : (appeared ? 1.0 : 0.3))
            .opacity(opacity)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: isActive)
    }

    // MARK: - Dash

    private var dashView: some View {
        Capsule()
            .fill(dashFill)
            .frame(width: dashWidth, height: elementHeight)
            .shadow(color: isActive ? activeColor.opacity(0.8) : .clear, radius: isActive ? 14 : 0)
            .scaleEffect(x: isActive ? 1.1 : (appeared ? 1.0 : 0.3), y: isActive ? 1.5 : (appeared ? 1.0 : 0.3))
            .opacity(opacity)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: isActive)
    }

    // MARK: - Colors

    private var activeColor: Color {
        element.signal == .dot ? Color.cyan : Color.orange
    }

    private var baseColor: Color {
        element.signal == .dot
            ? Color.cyan.opacity(0.7)
            : Color.orange.opacity(0.7)
    }

    private var pastColor: Color {
        element.signal == .dot
            ? Color.cyan.opacity(0.25)
            : Color.orange.opacity(0.25)
    }

    private var dotFill: some ShapeStyle {
        if isActive {
            return AnyShapeStyle(
                RadialGradient(
                    colors: [activeColor, activeColor.opacity(0.6)],
                    center: .center,
                    startRadius: 0,
                    endRadius: dotSize
                )
            )
        } else if isPast {
            return AnyShapeStyle(pastColor)
        } else {
            return AnyShapeStyle(baseColor)
        }
    }

    private var dashFill: some ShapeStyle {
        if isActive {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [activeColor.opacity(0.8), activeColor],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        } else if isPast {
            return AnyShapeStyle(pastColor)
        } else {
            return AnyShapeStyle(baseColor)
        }
    }

    private var opacity: Double {
        if isActive { return 1.0 }
        if isPast { return 0.5 }
        return appeared ? 0.85 : 0
    }
}

// MARK: - Word Gap Indicator

struct WordGapView: View {
    let isActive: Bool

    var body: some View {
        VStack(spacing: 2) {
            Circle()
                .fill(Color.white.opacity(isActive ? 0.3 : 0.1))
                .frame(width: 3, height: 3)
            Circle()
                .fill(Color.white.opacity(isActive ? 0.3 : 0.1))
                .frame(width: 3, height: 3)
        }
        .padding(.horizontal, 4)
        .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}
