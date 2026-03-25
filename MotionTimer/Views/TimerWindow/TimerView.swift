import SwiftUI

/// Main floating timer window: task label · progress ring · time digits · controls.
///
/// Designed as a compact, chrome-free panel (~280×320 pt) with frosted-glass material.
@MainActor
struct TimerView: View {
    @ObservedObject var model: TimerModel

    /// Phase 2: replaced by the active Motion task name.
    private let taskName = "Focus Time"

    var body: some View {
        VStack(spacing: 0) {
            taskLabel

            ringWithDigits
                .padding(.vertical, 24)

            TimerControlsView(model: model)
                .padding(.bottom, 20)
        }
        .frame(width: 280, height: 320)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 8)
    }

    // MARK: - Task label

    private var taskLabel: some View {
        Text(taskName)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.top, 20)
    }

    // MARK: - Ring + digits

    private var ringWithDigits: some View {
        ZStack {
            TimerProgressRing(progress: model.progress)
                .frame(width: 180, height: 180)

            VStack(spacing: 2) {
                Text(model.timeString)
                    .font(.system(size: 42, weight: .light, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.3), value: model.timeString)

                Text(model.statusLabel)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
                    .tracking(1.2)
            }
        }
    }
}

