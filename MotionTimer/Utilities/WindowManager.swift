import AppKit
import SwiftUI

// MARK: - WindowManager

/// Creates and manages the floating always-on-top timer panel.
@MainActor
final class WindowManager {
    static let shared = WindowManager()

    private var panel: TimerPanel?

    private init() {}

    /// Show the floating timer panel, creating it if needed.
    func showPanel(appState: AppState) {
        if panel == nil {
            let newPanel = TimerPanel()
            newPanel.contentView = makeContentView(appState: appState)
            panel = newPanel
        }
        panel?.orderFrontRegardless()
    }

    /// Hide the floating timer panel.
    func hidePanel() {
        panel?.orderOut(nil)
    }

    /// Toggle panel visibility.
    func toggle(appState: AppState) {
        if panel?.isVisible == true {
            hidePanel()
        } else {
            showPanel(appState: appState)
        }
    }

    // MARK: - Private

    private func makeContentView(appState: AppState) -> NSView {
        let effectView = NSVisualEffectView()
        effectView.material = .hudWindow
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = 16
        effectView.layer?.masksToBounds = true

        let hostingView = NSHostingView(
            rootView: TimerView(model: appState.timerModel)
                .environmentObject(appState)
        )
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        effectView.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: effectView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: effectView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: effectView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: effectView.bottomAnchor),
        ])
        return effectView
    }
}

// MARK: - TimerPanel

/// Floating, borderless, non-activating panel.
/// Stays above all other windows, is draggable, and persists its position.
final class TimerPanel: NSPanel {
    private static let positionKey = "MotionTimer.panelOrigin"

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 260),
            styleMask: [.borderless, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )
        configure()
    }

    private func configure() {
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = true
        // Show on all Spaces and above fullscreen apps
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        animationBehavior = .utilityWindow

        restorePosition()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(persistPosition),
            name: NSWindow.didMoveNotification,
            object: self
        )
    }

    // MARK: - Position persistence

    private func restorePosition() {
        if let saved = UserDefaults.standard.string(forKey: Self.positionKey) {
            setFrameOrigin(NSPointFromString(saved))
        } else {
            center()
        }
    }

    @objc private func persistPosition() {
        UserDefaults.standard.set(
            NSStringFromPoint(frame.origin),
            forKey: Self.positionKey
        )
    }

    // MARK: - NSPanel overrides

    /// Allow the panel to receive keyboard events (e.g. space to pause timer).
    override var canBecomeKey: Bool { true }

    /// Do not become main window — keeps focus with the user's active app.
    override var canBecomeMain: Bool { false }
}
