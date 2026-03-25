// MARK: - Temporary compilation stubs
// These placeholder types allow Views to compile before the Models target is merged.
// DELETE this file once TimerModel.swift, TimerMode.swift, TimerPreset.swift are added.

import Foundation
import Combine

// MARK: TimerMode

enum TimerMode: String, CaseIterable {
    case countdown = "Countdown"
    case countup   = "Count Up"

    var iconName: String {
        switch self {
        case .countdown: return "timer"
        case .countup:   return "stopwatch"
        }
    }
}

// MARK: TimerPreset

struct TimerPreset: Identifiable, Hashable {
    let id: UUID
    let name: String
    let duration: TimeInterval

    static let focus     = TimerPreset(id: UUID(), name: "Focus 25 min",    duration: 25 * 60)
    static let deepWork  = TimerPreset(id: UUID(), name: "Deep Work 50 min", duration: 50 * 60)
    static let shortBreak = TimerPreset(id: UUID(), name: "Break 5 min",    duration:  5 * 60)

    static let all: [TimerPreset] = [.focus, .deepWork, .shortBreak]
}

// MARK: TimerModel

@MainActor
final class TimerModel: ObservableObject {
    @Published var isRunning: Bool   = false
    @Published var isPaused:  Bool   = false
    @Published var mode: TimerMode   = .countdown
    @Published var currentPreset: TimerPreset? = .focus

    /// Elapsed time in seconds (countup) or remaining time in seconds (countdown).
    @Published var elapsed:  TimeInterval = 0
    @Published var duration: TimeInterval = 25 * 60

    /// 0.0 (not started) → 1.0 (complete). For countup, wraps at duration if set.
    var progress: Double {
        guard duration > 0 else { return 0 }
        switch mode {
        case .countdown: return max(0, min(1, 1 - (elapsed / duration)))
        case .countup:   return max(0, min(1,       elapsed / duration))
        }
    }

    /// Remaining / elapsed seconds, formatted as MM:SS or HH:MM:SS.
    var timeString: String {
        let seconds: TimeInterval
        switch mode {
        case .countdown: seconds = max(0, duration - elapsed)
        case .countup:   seconds = elapsed
        }
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }

    var statusLabel: String {
        if isRunning  { return "Running" }
        if isPaused   { return "Paused"  }
        return "Idle"
    }

    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?

    func start() {
        isRunning = true
        isPaused  = false
        scheduleTick()
    }

    func pause() {
        isRunning = false
        isPaused  = true
        timerCancellable?.cancel()
    }

    func resume() {
        isRunning = true
        isPaused  = false
        scheduleTick()
    }

    func reset() {
        timerCancellable?.cancel()
        isRunning = false
        isPaused  = false
        elapsed   = 0
    }

    func toggle() {
        if isRunning { pause() } else if isPaused { resume() } else { start() }
    }

    func apply(preset: TimerPreset) {
        reset()
        currentPreset = preset
        duration      = preset.duration
    }

    private func scheduleTick() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in self.tick() }
            }
    }

    private func tick() {
        elapsed += 1
        if mode == .countdown, elapsed >= duration {
            elapsed   = duration
            isRunning = false
            isPaused  = false
            timerCancellable?.cancel()
        }
    }
}
