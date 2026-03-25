import SwiftUI

/// Floating timer window: task label, progress ring, time digits.
/// Controls live in the menu bar popover only. This view is clean and minimal.
@MainActor
struct TimerView: View {
    @ObservedObject var model: TimerModel
    @EnvironmentObject var appState: AppState
    @State private var isHovering = false

    private var displayTaskName: String {
        appState.motionPoller.currentTask?.name ?? model.currentPreset.name
    }

    var body: some View {
        GeometryReader { geo in
            let ringSize = min(geo.size.width, geo.size.height) * 0.7
            let fontSize = ringSize * 0.22

            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    Text(displayTaskName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.top, 16)

                    ZStack {
                        TimerProgressRing(
                            progress: model.progress,
                            arcOpacity: model.timerState == .idle ? 0.3 : 1.0
                        )
                        .frame(width: ringSize, height: ringSize)

                        VStack(spacing: 2) {
                            Text(model.formattedTime)
                                .font(.system(size: fontSize, weight: .light, design: .monospaced))
                                .monospacedDigit()
                                .foregroundStyle(.primary)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)

                            Text(model.statusLabel)
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                                .textCase(.uppercase)
                                .tracking(1)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                if isHovering {
                    Button {
                        appState.toggleTimerWindow()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(minWidth: 200, minHeight: 220)
        .onHover { isHovering = $0 }
    }
}
