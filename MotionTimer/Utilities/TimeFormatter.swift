import Foundation

/// Static helpers for converting a raw second count into display strings.
enum TimeFormatter {

    /// Returns an `H:MM:SS` string (hours omitted when zero).
    /// - Parameter seconds: Total elapsed or remaining seconds (clamped to ≥ 0).
    static func format(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let hours   = s / 3600
        let minutes = (s % 3600) / 60
        let secs    = s % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }

    /// Compact representation for the menu-bar icon (always `MM:SS`, capped at `99:59`).
    static func formatCompact(_ seconds: Int) -> String {
        let s = min(max(0, seconds), 99 * 60 + 59)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
}
