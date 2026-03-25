import SwiftUI

/// Circular progress ring that animates smoothly as `progress` changes.
///
/// - Background track: subtle gray ring
/// - Foreground arc: blue → purple gradient, rounded line caps
/// - `progress`: 0.0 (empty) → 1.0 (full)
@MainActor
struct TimerProgressRing: View {
    let progress: Double

    private let strokeWidth: CGFloat   = 8
    private let trackOpacity: Double   = 0.15
    private let ringGradient = AngularGradient(
        gradient: Gradient(colors: [
            Color(red: 0.40, green: 0.60, blue: 1.00),  // soft blue
            Color(red: 0.65, green: 0.35, blue: 1.00),  // purple
            Color(red: 0.40, green: 0.60, blue: 1.00)   // back to blue (seamless)
        ]),
        center: .center,
        startAngle: .degrees(-90),
        endAngle:   .degrees(270)
    )

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.white.opacity(trackOpacity), lineWidth: strokeWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(ringGradient, style: StrokeStyle(
                    lineWidth: strokeWidth,
                    lineCap:  .round
                ))
                .rotationEffect(.degrees(-90))  // start from 12 o'clock
                .animation(.linear(duration: 1), value: progress)
        }
    }
}

