import SwiftUI

/// Popover content that appears when the user clicks the menu bar icon.
@MainActor
struct MenuBarView: View {
    @ObservedObject var model: TimerModel

    var body: some View {
        VStack(spacing: 0) {
            statusSection
            Divider()
            presetsSection
            Divider()
            quitRow
        }
        .frame(width: 240)
        .background(.ultraThinMaterial)
    }

    // MARK: - Status + quick toggle

    private var statusSection: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.timeString)
                        .font(.system(size: 32, weight: .light, design: .monospaced))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.spring(duration: 0.3), value: model.timeString)

                    Label(model.statusLabel, systemImage: model.mode.iconName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

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
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
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
        }
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func presetRow(_ preset: TimerPreset) -> some View {
        let isActive = model.currentPreset == preset
        Button {
            model.apply(preset: preset)
            model.start()
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

    // MARK: - Quit

    private var quitRow: some View {
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

