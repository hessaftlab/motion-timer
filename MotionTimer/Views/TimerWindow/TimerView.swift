import SwiftUI

/// Floating timer window: task label · progress ring · time digits only.
/// Controls live in the menu bar popover. Window is resizable by dragging edges.
@MainActor
struct TimerView: View {
    @ObservedObject var model: TimerModel
    @EnvironmentObject var appState: AppState
    @State private var isHovering = false

    /// Shows the active Motion task name, falling back to the current preset name.
    private var displayTaskName: String {
        appState.motionPoller.currentTask?.name ?? model.currentPreset.name
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                taskLabel

                ringWithDigits
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 16)
            }

            if isHovering {
                closeButton
            }
        }
        .frame(minWidth: 160, minHeight: 180)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 8)
        .onHover { isHovering = $0 }
    }

    // MARK: - Task label

    private var taskLabel: some View {
        Text(displayTaskName)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.top, 20)
            .padding(.horizontal, 16)
    }

    // MARK: - Ring + digits

    private var ringWithDigits: some View {
        ZStack {
            TimerProgressRing(
                progress: model.progress,
                arcOpacity: model.timerState == .idle ? 0.3 : 1.0
            )
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

    // MARK: - Close button

    private var closeButton: some View {
        Button {
            appState.toggleTimerWindow()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .imageScale(.medium)
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)
        }
        .buttonStyle(.plain)
        .padding(10)
    }
}
