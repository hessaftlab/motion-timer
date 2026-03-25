import SwiftUI

/// Horizontal control bar: preset picker · mode toggle · play/pause · reset.
@MainActor
struct TimerControlsView: View {
    @ObservedObject var model: TimerModel

    var body: some View {
        HStack(spacing: 16) {
            presetMenu
            Spacer()
            modeToggle
            playPauseButton
            resetButton
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Preset Menu

    private var presetMenu: some View {
        Menu {
            ForEach(TimerPreset.all) { preset in
                Button(preset.name) {
                    model.apply(preset: preset)
                }
            }
            Divider()
            Button("Custom…") {
                // Phase 2: open duration picker
            }
        } label: {
            Label(
                model.currentPreset.name,
                systemImage: "clock"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        Button {
            let next: TimerMode = model.mode == .countdown ? .countup : .countdown
            model.mode = next
        } label: {
            Image(systemName: model.mode.iconName)
                .imageScale(.medium)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .help(model.mode == .countdown ? "Switch to Count Up" : "Switch to Countdown")
    }

    // MARK: - Play / Pause

    private var playPauseButton: some View {
        Button {
            model.toggle()
        } label: {
            Image(systemName: model.isRunning ? "pause.fill" : "play.fill")
                .imageScale(.large)
                .foregroundStyle(.primary)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                )
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.space, modifiers: [])
        .help(model.isRunning ? "Pause" : (model.isPaused ? "Resume" : "Start"))
    }

    // MARK: - Reset

    private var resetButton: some View {
        Button {
            model.reset()
        } label: {
            Image(systemName: "arrow.counterclockwise")
                .imageScale(.medium)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .help("Reset")
    }
}

