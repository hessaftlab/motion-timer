import Foundation

/// A named timer configuration with a fixed duration in seconds.
/// A `duration` of `0` indicates a user-defined (Custom) preset.
struct TimerPreset: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    let name: String
    /// Duration in seconds. `0` means the user supplies a custom value.
    let duration: Int

    init(id: UUID = UUID(), name: String, duration: Int) {
        self.id = id
        self.name = name
        self.duration = duration
    }

    var isCustom: Bool { duration == 0 }

    // MARK: - Built-in presets

    static let focus     = TimerPreset(name: "Focus",       duration: 25 * 60)
    static let deepWork  = TimerPreset(name: "Deep Work",   duration: 50 * 60)
    static let shortBreak = TimerPreset(name: "Short Break", duration:  5 * 60)
    static let custom    = TimerPreset(name: "Custom",      duration: 0)

    static let defaults: [TimerPreset] = [.focus, .deepWork, .shortBreak, .custom]
    /// Alias for `defaults` — used by views expecting `TimerPreset.all`.
    static var all: [TimerPreset] { defaults }
}
