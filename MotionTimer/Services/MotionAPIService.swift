import Foundation

// MARK: - MotionTask

/// A task from the Motion.ai scheduling API.
/// TODO: Phase 2 — extend with project, priority, and status fields per Motion API spec.
struct MotionTask: Sendable, Codable, Identifiable {
    let id: String
    let name: String
    /// Scheduled start time (nil if the task has no explicit start).
    let scheduledStart: Date?
    /// Scheduled end time (nil if the task has no explicit end).
    let scheduledEnd: Date?
    /// Planned duration in seconds.
    let duration: TimeInterval

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case scheduledStart
        case scheduledEnd
        case duration
    }
}

// MARK: - MotionAPIService

/// Phase 2 placeholder: async REST client for the Motion.ai API.
///
/// Usage:
/// ```swift
/// await MotionAPIService.shared.apiKey = "your-key"
/// let task = try await MotionAPIService.shared.fetchCurrentTask()
/// ```
///
/// TODO: Phase 2 — remove this placeholder and implement full endpoints.
/// TODO: Phase 2 — migrate API key storage from UserDefaults to macOS Keychain.
/// TODO: Phase 2 — wire into MotionTaskPoller for automatic task polling.
actor MotionAPIService {
    static let shared = MotionAPIService()

    private let session: URLSession
    private let baseURL = "https://api.usemotion.com/v1"
    private let decoder: JSONDecoder

    // TODO: Phase 2 — replace UserDefaults with Keychain (SecItemAdd / SecItemCopyMatching).
    private let apiKeyDefaultsKey = "MotionTimer.motionAPIKey"

    private init() {
        session = URLSession.shared
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - API Key

    /// The Motion API key.
    /// TODO: Phase 2 — store in the macOS Keychain instead of UserDefaults.
    var apiKey: String? {
        get { UserDefaults.standard.string(forKey: apiKeyDefaultsKey) }
        set { UserDefaults.standard.set(newValue, forKey: apiKeyDefaultsKey) }
    }

    // MARK: - Endpoints

    /// Fetch the currently active or next scheduled Motion task.
    ///
    /// TODO: Phase 2 — implement using `GET /tasks?status=active`.
    func fetchCurrentTask() async throws -> MotionTask? {
        // TODO: Phase 2 — replace with real implementation.
        // let request = try makeRequest(path: "/tasks?status=active&limit=1")
        // let response: TaskListResponse = try await perform(request)
        // return response.tasks.first
        throw MotionAPIError.notImplemented
    }

    /// Fetch upcoming scheduled tasks.
    ///
    /// TODO: Phase 2 — implement using `GET /tasks?status=upcoming`.
    func fetchUpcomingTasks() async throws -> [MotionTask] {
        // TODO: Phase 2 — replace with real implementation.
        // let request = try makeRequest(path: "/tasks?status=upcoming")
        // let response: TaskListResponse = try await perform(request)
        // return response.tasks
        throw MotionAPIError.notImplemented
    }

    // MARK: - Private helpers

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
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MotionAPIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw MotionAPIError.httpError(statusCode: httpResponse.statusCode)
        }
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - MotionAPIError

enum MotionAPIError: LocalizedError, Sendable {
    case notImplemented
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "This feature is not yet implemented (Phase 2)."
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
