/// Determines whether the timer counts down to zero or up from zero.
enum TimerMode: String, CaseIterable, Sendable, Codable {
    case countdown
    case countup

    /// SF Symbol name representing this mode.
    var iconName: String {
        switch self {
        case .countdown: return "timer"
        case .countup:   return "stopwatch"
        }
    }
}
