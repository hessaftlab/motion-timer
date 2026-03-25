import SwiftUI

/// Global observable state shared across the entire app.
/// Owns the shared TimerModel and MotionTaskPoller instances.
@MainActor
final class AppState: ObservableObject {
    @Published var showTimerWindow: Bool = false
    @Published var showSettings: Bool = false

    let timerModel: TimerModel
    let motionPoller: MotionTaskPoller

    init() {
        let model = TimerModel()
        timerModel = model
        motionPoller = MotionTaskPoller(timerModel: model)

        UserDefaults.standard.register(defaults: [
            "motionAPIKey": "zN942dZXP+YMQc9s4KurWyYXXhiVAXYfHYWTDBoz2uU=",
            "motionSyncEnabled": true,
            "motionPollingInterval": 60
        ])

        motionPoller.startPolling()

        // Auto-show the floating timer panel on launch
        showTimerWindow = true
        WindowManager.shared.showPanel(appState: self)
    }

    /// Toggle the floating timer panel. Delegates to WindowManager.
    func toggleTimerWindow() {
        if showTimerWindow {
            WindowManager.shared.hidePanel()
        } else {
            WindowManager.shared.showPanel(appState: self)
        }
        showTimerWindow.toggle()
    }
}
