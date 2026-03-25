import UserNotifications
import AppKit

/// Manages local notifications and audio feedback for timer events.
enum NotificationService {
    private static let completionIDPrefix = "MotionTimer.complete"

    // MARK: - Permissions

    /// Request notification authorization from the user.
    /// Safe to call on every launch — skips the prompt if already decided.
    static func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        do {
            try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            // Silently ignore — notifications are a nice-to-have, not critical.
        }
    }

    // MARK: - Notifications

    /// Deliver an immediate local notification announcing timer completion.
    /// Also plays a system sound for in-app feedback.
    ///
    /// - Parameter taskName: Name of the completed task shown in the notification body.
    ///   Pass an empty string for a generic message.
    static func sendTimerComplete(taskName: String) {
        playCompletionSound()

        let content = UNMutableNotificationContent()
        content.title = "Timer Complete"
        content.body = taskName.isEmpty
            ? "Your timer has finished."
            : "\"\(taskName)\" is done."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "\(completionIDPrefix).\(UUID().uuidString)",
            content: content,
            trigger: nil  // nil trigger = deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[NotificationService] Failed to deliver notification: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Alert

    /// Show a modal NSAlert announcing timer completion.
    /// Also plays the Glass sound. Blocks until the user dismisses.
    @MainActor
    static func showCompletionAlert(taskName: String) {
        playCompletionSound()

        let alert = NSAlert()
        alert.messageText = "Timer Complete"
        alert.informativeText = taskName.isEmpty
            ? "Your timer has finished."
            : "\"\(taskName)\" is done."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    // MARK: - Private

    private static func playCompletionSound() {
        NSSound(named: NSSound.Name("Glass"))?.play()
    }
}
