import SwiftUI
import AppKit

// MARK: - App Entry Point

@main
struct MotionTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        // Menu bar icon + popover — no Dock icon
        MenuBarExtra("MotionTimer", systemImage: "timer") {
            MenuBarView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - AppDelegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Accessory policy: no Dock icon, no menu bar app menu
        NSApp.setActivationPolicy(.accessory)

        // Request notification permission on first launch (non-blocking)
        Task {
            await NotificationService.requestPermission()
        }
    }

    /// Keep the app alive even when all windows are closed.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
