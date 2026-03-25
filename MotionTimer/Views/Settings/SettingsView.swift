import SwiftUI

/// App preferences panel. Values persist via @AppStorage (UserDefaults).
@MainActor
struct SettingsView: View {
    // Default timer duration in minutes
    @AppStorage("defaultDurationMinutes") private var defaultDurationMinutes: Int    = 25
    // Window behaviour
    @AppStorage("alwaysOnTop")            private var alwaysOnTop: Bool              = true
    // Notifications
    @AppStorage("soundOnComplete")        private var soundOnComplete: Bool          = true
    @AppStorage("notifyOnComplete")       private var notifyOnComplete: Bool         = true

    var body: some View {
        Form {
            timerSection
            windowSection
            notificationsSection
        }
        .formStyle(.grouped)
        .frame(width: 360)
        .padding()
    }

    // MARK: - Timer defaults

    private var timerSection: some View {
        Section("Timer") {
            Stepper(
                value: $defaultDurationMinutes,
                in: 1...240,
                step: 5
            ) {
                LabeledContent("Default Duration") {
                    Text("\(defaultDurationMinutes) min")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Window behaviour

    private var windowSection: some View {
        Section("Window") {
            Toggle("Always on Top", isOn: $alwaysOnTop)
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle("Play Sound on Complete", isOn: $soundOnComplete)
            Toggle("Show Notification on Complete", isOn: $notifyOnComplete)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
