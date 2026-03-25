/// Determines whether the timer counts down to zero or up from zero.
enum TimerMode: String, CaseIterable, Sendable, Codable {
    case countdown
    case countup
}
