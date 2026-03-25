import Foundation
import Combine

// MARK: - Timer State

/// The discrete states of the timer state machine.
enum TimerState: Sendable {
    /// No session in progress.
    case idle
    /// Timer is actively ticking.
    case running
    /// Session was started but is temporarily paused.
    case paused
    /// Countdown reached zero (not used for countup mode).
    case completed
}

// MARK: - Timer Model

/// Central timer engine. All mutations happen on the main actor.
@MainActor
final class TimerModel: ObservableObject {

    // MARK: Published state

    @Published private(set) var timeRemaining: Int = 0
    @Published private(set) var totalTime: Int      = 0
    @Published private(set) var isRunning: Bool     = false
    @Published private(set) var isPaused: Bool      = false
    @Published private(set) var timerState: TimerState = .idle
    @Published var mode: TimerMode                  = .countdown
    @Published var currentPreset: TimerPreset       = .focus

    // MARK: Private

    private var timerCancellable: AnyCancellable?
    /// Accumulated seconds elapsed (used for countup and progress calculation).
    private(set) var elapsed: Int = 0

    // MARK: - Computed properties

    /// Fraction of total time elapsed, in [0, 1]. Always 0 for countup mode.
    var progress: Double {
        guard mode == .countdown, totalTime > 0 else { return 0 }
        return Double(totalTime - timeRemaining) / Double(totalTime)
    }

    /// Human-readable time string (`MM:SS` or `H:MM:SS`).
    var formattedTime: String {
        TimeFormatter.format(displaySeconds)
    }

    /// Alias for `formattedTime` — used by views expecting `timeString`.
    var timeString: String { formattedTime }

    /// Human-readable status label matching the current `timerState`.
    var statusLabel: String {
        switch timerState {
        case .idle:      return "Idle"
        case .running:   return "Running"
        case .paused:    return "Paused"
        case .completed: return "Completed"
        }
    }

    /// `true` when less than `warningThreshold` of total time remains.
    var isInWarningZone: Bool {
        guard mode == .countdown, totalTime > 0 else { return false }
        return progress >= (1.0 - AppConstants.Timer.warningThreshold)
    }

    // MARK: - Public API

    /// Alias for `load(preset:)` — used by views expecting `apply(preset:)`.
    func apply(preset: TimerPreset) { load(preset: preset) }

    /// Load a preset and reset the timer to idle.
    func load(preset: TimerPreset) {
        stop()
        currentPreset = preset
        let duration = preset.isCustom ? totalTime : preset.duration
        configure(duration: duration)
    }

    /// Set a specific duration (seconds) without changing the preset.
    func setDuration(_ seconds: Int) {
        guard seconds > 0 else { return }
        stop()
        configure(duration: seconds)
    }

    /// Start a fresh session from the current `totalTime` / mode.
    func start() {
        guard timerState == .idle else { return }
        elapsed = 0
        if mode == .countdown {
            timeRemaining = totalTime
        } else {
            timeRemaining = 0
        }
        isRunning = true
        isPaused  = false
        timerState = .running
        scheduleTicks()
    }

    /// Pause a running session.
    func pause() {
        guard timerState == .running else { return }
        isRunning  = false
        isPaused   = true
        timerState = .paused
        cancelTicks()
    }

    /// Resume a paused session.
    func resume() {
        guard timerState == .paused else { return }
        isRunning  = true
        isPaused   = false
        timerState = .running
        scheduleTicks()
    }

    /// Reset to idle without changing the current preset or total time.
    func reset() {
        stop()
        configure(duration: totalTime)
    }

    /// Convenience: start if idle/completed, pause if running, resume if paused.
    func toggle() {
        switch timerState {
        case .idle, .completed:
            reset()
            start()
        case .running:
            pause()
        case .paused:
            resume()
        }
    }

    // MARK: - Private helpers

    private func configure(duration: Int) {
        totalTime     = duration
        timeRemaining = mode == .countdown ? duration : 0
        elapsed       = 0
        timerState    = .idle
        isRunning     = false
        isPaused      = false
    }

    private func stop() {
        cancelTicks()
        isRunning  = false
        isPaused   = false
    }

    private func scheduleTicks() {
        timerCancellable = Timer.publish(
            every: AppConstants.Timer.tickInterval,
            on: .main,
            in: .common
        )
        .autoconnect()
        .sink { [weak self] _ in
            // Timer fires on the main run loop; assume isolation is safe.
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
    }

    private func cancelTicks() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func tick() {
        guard timerState == .running else { return }
        elapsed += 1

        switch mode {
        case .countdown:
            if timeRemaining > 0 {
                timeRemaining -= 1
            }
            if timeRemaining == 0 {
                complete()
            }

        case .countup:
            timeRemaining += 1
        }
    }

    private func complete() {
        cancelTicks()
        timerState = .completed
        isRunning  = false
        isPaused   = false
        NotificationCenter.default.post(
            name: AppConstants.Timer.completionNotification,
            object: self
        )
        NotificationService.sendTimerComplete(taskName: currentPreset.name)
        NotificationService.showCompletionAlert(taskName: currentPreset.name)
    }

    /// The seconds value shown to the user.
    private var displaySeconds: Int {
        switch mode {
        case .countdown: return timeRemaining
        case .countup:   return elapsed
        }
    }
}

// MARK: - Convenience initialiser

extension TimerModel {
    /// Creates a model pre-loaded with the given preset (defaults to Focus).
    convenience init(preset: TimerPreset = .focus, mode: TimerMode = .countdown) {
        self.init()
        self.mode = mode
        configure(duration: preset.isCustom ? 0 : preset.duration)
        currentPreset = preset
    }
}
