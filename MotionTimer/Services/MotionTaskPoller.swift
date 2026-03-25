import Foundation

/// Polls the Motion API on a recurring interval and auto-updates the TimerModel
/// when a new active task is detected.
@MainActor
final class MotionTaskPoller: ObservableObject {

    @Published var currentTask: MotionTask?
    @Published var isPolling: Bool = false
    @Published var lastError: String?

    private let timerModel: TimerModel
    private var pollTimer: Timer?

    private let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    init(timerModel: TimerModel) {
        self.timerModel = timerModel
    }

    // MARK: - Control

    func startPolling() {
        guard !isPolling else { return }
        isPolling = true

        // Fire an immediate poll, then schedule repeating
        Task { await poll() }

        let rawInterval = UserDefaults.standard.integer(forKey: "motionPollingInterval")
        let interval: TimeInterval = rawInterval > 0
            ? TimeInterval(min(max(30, rawInterval), 300))
            : 60

        pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.poll()
            }
        }
    }

    func stopPolling() {
        isPolling = false
        pollTimer?.invalidate()
        pollTimer = nil
        currentTask = nil
    }

    // MARK: - Polling

    private func poll() async {
        guard UserDefaults.standard.bool(forKey: "motionSyncEnabled") else { return }

        do {
            let task = try await MotionAPIService.shared.fetchCurrentTask()
            let previousID = currentTask?.id
            currentTask = task
            lastError = nil

            if let task, task.id != previousID {
                updateTimer(with: task)
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Timer Update

    private func updateTimer(with task: MotionTask) {
        Task {
            // Use the active chunk's duration (checks chunks first, falls back to top-level)
            let minutes = await MotionAPIService.shared.activeChunkDuration(for: task)

            let durationSeconds: Int
            if let m = minutes, m > 0 {
                durationSeconds = m * 60
            } else if let startStr = task.scheduledStart,
                      let endStr = task.scheduledEnd,
                      let start = isoFormatter.date(from: startStr),
                      let end = isoFormatter.date(from: endStr) {
                durationSeconds = max(60, Int(end.timeIntervalSince(start)))
            } else {
                return
            }

            timerModel.setDuration(durationSeconds)
            timerModel.start()
        }
    }
}
