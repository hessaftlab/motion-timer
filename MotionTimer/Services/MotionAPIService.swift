import Foundation

// MARK: - MotionTask

struct MotionTask: Decodable, Sendable, Identifiable {
    let id: String
    let name: String
    /// Duration in minutes. Nil when the API returns "NONE", "REMINDER", or the field is absent.
    let duration: Int?
    /// ISO 8601 datetime string, e.g. "2026-03-25T08:15:00.000Z"
    let scheduledStart: String?
    /// ISO 8601 datetime string, e.g. "2026-03-25T09:10:00.000Z"
    let scheduledEnd: String?
    let completed: Bool
    let status: MotionTaskStatus?

    struct MotionTaskStatus: Codable, Sendable {
        let name: String
        let isDefaultStatus: Bool
    }

    enum CodingKeys: String, CodingKey {
        case id, name, duration, scheduledStart, scheduledEnd, completed, status
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        scheduledStart = try c.decodeIfPresent(String.self, forKey: .scheduledStart)
        scheduledEnd = try c.decodeIfPresent(String.self, forKey: .scheduledEnd)
        completed = (try? c.decodeIfPresent(Bool.self, forKey: .completed)) ?? false
        status = try? c.decodeIfPresent(MotionTaskStatus.self, forKey: .status)
        // duration can be an Int (minutes), "NONE", "REMINDER", or absent — treat non-Int as nil
        duration = try? c.decode(Int.self, forKey: .duration)
    }
}

// MARK: - MotionAPIService

actor MotionAPIService {
    static let shared = MotionAPIService()

    private let session = URLSession.shared
    private let baseURL = "https://api.usemotion.com/v1"
    private let decoder = JSONDecoder()
    private let apiKeyDefaultsKey = "motionAPIKey"

    // Rate limiting
    private var lastFetchTime: Date?
    private var cachedTasks: [MotionTask]?
    private let cooldown: TimeInterval = 30

    private let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private init() {}

    // MARK: - API Key

    var apiKey: String? {
        get { UserDefaults.standard.string(forKey: apiKeyDefaultsKey) }
        set { UserDefaults.standard.set(newValue, forKey: apiKeyDefaultsKey) }
    }

    // MARK: - Public Endpoints

    /// Fetch the first page of tasks from GET /v1/tasks.
    func fetchTasks() async throws -> [MotionTask] {
        let (tasks, _) = try await fetchPage(cursor: nil)
        return tasks
    }

    /// Find the currently active task (scheduledStart ≤ now ≤ scheduledEnd).
    /// Paginates up to 3 pages. Returns a cached result if called within the 30-second cooldown.
    func fetchCurrentTask() async throws -> MotionTask? {
        let now = Date()

        // Serve from cache if within cooldown window
        if let last = lastFetchTime,
           now.timeIntervalSince(last) < cooldown,
           let cached = cachedTasks {
            return findActiveTask(in: cached, at: now)
        }

        var cursor: String? = nil
        var allTasks: [MotionTask] = []

        for _ in 0..<3 {
            let (tasks, nextCursor) = try await fetchPage(cursor: cursor)
            allTasks.append(contentsOf: tasks)

            if let active = findActiveTask(in: tasks, at: now) {
                lastFetchTime = now
                cachedTasks = allTasks
                return active
            }

            guard let next = nextCursor else { break }
            cursor = next
        }

        lastFetchTime = now
        cachedTasks = allTasks
        return nil
    }

    // MARK: - Private Helpers

    private struct TaskListResponse: Decodable {
        struct Meta: Decodable {
            let pageSize: Int
            let nextCursor: String?
        }
        let meta: Meta
        let tasks: [MotionTask]
    }

    private func fetchPage(cursor: String?) async throws -> ([MotionTask], String?) {
        var path = "/tasks"
        if let cursor {
            path += "?cursor=\(cursor)"
        }
        let request = try makeRequest(path: path)
        let response: TaskListResponse = try await perform(request)
        return (response.tasks, response.meta.nextCursor)
    }

    private func findActiveTask(in tasks: [MotionTask], at date: Date) -> MotionTask? {
        tasks.first { task in
            guard !task.completed,
                  let startStr = task.scheduledStart,
                  let endStr = task.scheduledEnd,
                  let start = isoFormatter.date(from: startStr),
                  let end = isoFormatter.date(from: endStr) else { return false }
            return start <= date && date <= end
        }
    }

    private func makeRequest(path: String) throws -> URLRequest {
        guard let key = apiKey, !key.isEmpty else {
            throw MotionAPIError.missingAPIKey
        }
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw MotionAPIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue(key, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw MotionAPIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw MotionAPIError.httpError(statusCode: http.statusCode)
        }
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - MotionAPIError

enum MotionAPIError: LocalizedError, Sendable {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Motion API key is not configured."
        case .invalidURL:
            return "Invalid Motion API URL."
        case .invalidResponse:
            return "Received an invalid response from the Motion API."
        case .httpError(let code):
            return "Motion API returned HTTP \(code)."
        }
    }
}
