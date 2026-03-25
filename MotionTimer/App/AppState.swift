import SwiftUI

/// Global observable state shared across the entire app.
/// Owns the shared TimerModel instance and controls window visibility.
@MainActor
final class AppState: ObservableObject {
    @Published var showTimerWindow: Bool = false
    @Published var showSettings: Bool = false

    let timerModel = TimerModel()

    init() {}

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
