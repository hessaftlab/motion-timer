import SwiftUI
import AppKit

// MARK: - App Entry Point

@main
struct MotionTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()

    init() {
        let state = AppState()
        _appState = StateObject(wrappedValue: state)
        // Make appState available to AppDelegate for panel launch
        AppDelegate.sharedAppState = state
    }

    var body: some Scene {
        // Menu bar icon + popover — no Dock icon
        MenuBarExtra("MotionTimer", systemImage: "timer") {
            MenuBarView(model: appState.timerModel)
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - AppDelegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Reference to appState, set from the App struct's onAppear
    static var sharedAppState: AppState?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Accessory policy: no Dock icon, no menu bar app menu
        NSApp.setActivationPolicy(.accessory)

        // Request notification permission on first launch (non-blocking)
        Task {
            await NotificationService.requestPermission()
        }

        // Show floating panel after a short delay to let SwiftUI finish setup
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            Self.sharedAppState?.showPanelOnLaunch()
        }
    }

    /// Keep the app alive even when all windows are closed.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
