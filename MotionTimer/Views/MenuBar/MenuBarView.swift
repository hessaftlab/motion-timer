import SwiftUI

/// Popover content that appears when the user clicks the menu bar icon.
@MainActor
struct MenuBarView: View {
    @ObservedObject var model: TimerModel
    @EnvironmentObject var appState: AppState
    @State private var customMinutes: Int = 25
    @AppStorage("motionSyncEnabled") private var motionSyncEnabled: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            statusSection
            Divider()
            motionSection
            Divider()
            presetsSection
            Divider()
            bottomRow
        }
        .frame(width: 280)
        .background(.ultraThinMaterial)
    }

    // MARK: - Status + quick toggle

    private var statusSection: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.formattedTime)
                        .font(.system(size: 28, weight: .light, design: .monospaced))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Label(model.statusLabel, systemImage: model.mode.iconName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    // Mode toggle
                    Button {
                        model.mode = model.mode == .countdown ? .countup : .countdown
                    } label: {
                        Image(systemName: model.mode.iconName)
                            .imageScale(.medium)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                    .buttonStyle(.plain)
                    .help(model.mode == .countdown ? "Switch to Count Up" : "Switch to Countdown")

                    // Reset
                    Button {
                        model.reset()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .imageScale(.medium)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                    .buttonStyle(.plain)
                    .help("Reset")

                    // Play / Pause
                    Button {
                        model.toggle()
                    } label: {
                        Image(systemName: model.isRunning ? "pause.fill" : "play.fill")
                            .imageScale(.large)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Motion sync section

    private var motionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Motion Sync")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                Spacer()

                Toggle("", isOn: $motionSyncEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .onChange(of: motionSyncEnabled) { _, enabled in
                        if enabled {
                            appState.motionPoller.startPolling()
                        } else {
                            appState.motionPoller.stopPolling()
                        }
                    }
            }

            motionStatusRow
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var motionStatusRow: some View {
        let poller = appState.motionPoller

        if !motionSyncEnabled {
            Label("Sync disabled", systemImage: "moon.zzz")
                .font(.caption)
                .foregroundStyle(.tertiary)
        } else if let task = poller.currentTask {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .imageScale(.small)
                VStack(alignment: .leading, spacing: 1) {
                    Text(task.name)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(model.timeString + " remaining")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        } else if let error = poller.lastError {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .imageScale(.small)
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        } else if poller.isPolling {
            Label("Polling…", systemImage: "arrow.clockwise")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Label("No active task", systemImage: "clock")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Preset quick-launch buttons

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Quick Start")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
                .tracking(0.8)
                .padding(.horizontal, 16)
                .padding(.top, 10)

            ForEach(TimerPreset.all) { preset in
                presetRow(preset)
            }

            if model.currentPreset.isCustom {
                customDurationRow
            }
        }
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func presetRow(_ preset: TimerPreset) -> some View {
        let isActive = model.currentPreset == preset
        Button {
            model.apply(preset: preset)
            if !preset.isCustom {
                model.start()
            }
        } label: {
            HStack {
                Text(preset.name)
                    .font(.callout)
                Spacer()
                if isActive {
                    Image(systemName: "checkmark")
                        .imageScale(.small)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
        }
        .buttonStyle(.plain)
        .background(isActive ? Color.accentColor.opacity(0.12) : Color.clear)
    }

    // MARK: - Custom duration

    private var customDurationRow: some View {
        HStack {
            Text("Minutes:")
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            Stepper(
                "\(customMinutes) min",
                value: $customMinutes,
                in: 1...240,
                step: 1
            )
            .labelsHidden()
            .onChange(of: customMinutes) { _, newValue in
                model.setDuration(newValue * 60)
            }
            Text("\(customMinutes) min")
                .font(.callout)
                .monospacedDigit()
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    // MARK: - Show/Hide Timer + Quit

    private var bottomRow: some View {
        VStack(spacing: 0) {
            Button {
                appState.toggleTimerWindow()
            } label: {
                Label(
                    appState.showTimerWindow ? "Hide Timer" : "Show Timer",
                    systemImage: appState.showTimerWindow ? "eye.slash" : "eye"
                )
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            Divider()

            Button(role: .destructive) {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit MotionTimer", systemImage: "power")
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
    }
}
