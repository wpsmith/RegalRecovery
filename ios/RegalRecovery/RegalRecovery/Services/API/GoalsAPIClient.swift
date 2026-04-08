import Foundation

/// Hand-written API client for the Weekly/Daily Goals endpoints.
/// Conforms to the OpenAPI spec at docs/prd/specific-features/WeeklyGoals/specs/openapi.yaml.
/// Feature flag: `activity.weekly-daily-goals`
actor GoalsAPIClient {

    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL = URL(string: "http://localhost:8080/v1")!, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - Daily / Weekly Views

    /// GET /activities/weekly-daily-goals/daily
    func getDailyGoals(date: String? = nil) async throws -> DailyGoalsData {
        var components = URLComponents(url: baseURL.appendingPathComponent("activities/weekly-daily-goals/daily"), resolvingAgainstBaseURL: false)!
        if let date {
            components.queryItems = [URLQueryItem(name: "date", value: date)]
        }
        let data = try await performRequest(url: components.url!)
        let wrapper = try JSONDecoder.apiDecoder.decode(DataWrapper<DailyGoalsData>.self, from: data)
        return wrapper.data
    }

    /// GET /activities/weekly-daily-goals/weekly
    func getWeeklyGoals(weekOf: String? = nil) async throws -> WeeklyGoalsData {
        var components = URLComponents(url: baseURL.appendingPathComponent("activities/weekly-daily-goals/weekly"), resolvingAgainstBaseURL: false)!
        if let weekOf {
            components.queryItems = [URLQueryItem(name: "weekOf", value: weekOf)]
        }
        let data = try await performRequest(url: components.url!)
        let wrapper = try JSONDecoder.apiDecoder.decode(DataWrapper<WeeklyGoalsData>.self, from: data)
        return wrapper.data
    }

    // MARK: - Goal CRUD

    /// POST /activities/weekly-daily-goals
    func createGoal(_ request: CreateGoalRequest) async throws -> WeeklyDailyGoalDefinition {
        let url = baseURL.appendingPathComponent("activities/weekly-daily-goals")
        let body = try JSONEncoder.apiEncoder.encode(request)
        let data = try await performRequest(url: url, method: "POST", body: body)
        let wrapper = try JSONDecoder.apiDecoder.decode(DataWrapper<WeeklyDailyGoalDefinition>.self, from: data)
        return wrapper.data
    }

    /// GET /activities/weekly-daily-goals
    func listGoals(scope: GoalScope? = nil, dynamic: RecoveryDynamic? = nil, isActive: Bool? = nil) async throws -> [WeeklyDailyGoalDefinition] {
        var components = URLComponents(url: baseURL.appendingPathComponent("activities/weekly-daily-goals"), resolvingAgainstBaseURL: false)!
        var items = [URLQueryItem]()
        if let scope { items.append(URLQueryItem(name: "scope", value: scope.rawValue)) }
        if let dynamic { items.append(URLQueryItem(name: "dynamic", value: dynamic.rawValue)) }
        if let isActive { items.append(URLQueryItem(name: "isActive", value: String(isActive))) }
        if !items.isEmpty { components.queryItems = items }
        let data = try await performRequest(url: components.url!)
        let wrapper = try JSONDecoder.apiDecoder.decode(DataArrayWrapper<WeeklyDailyGoalDefinition>.self, from: data)
        return wrapper.data
    }

    /// DELETE /activities/weekly-daily-goals/{goalId}
    func deleteGoal(goalId: String) async throws {
        let url = baseURL.appendingPathComponent("activities/weekly-daily-goals/\(goalId)")
        _ = try await performRequest(url: url, method: "DELETE")
    }

    // MARK: - Instance Actions

    /// POST /activities/weekly-daily-goals/instances/{goalInstanceId}/complete
    func completeInstance(goalInstanceId: String) async throws -> GoalInstance {
        let url = baseURL.appendingPathComponent("activities/weekly-daily-goals/instances/\(goalInstanceId)/complete")
        let data = try await performRequest(url: url, method: "POST")
        let wrapper = try JSONDecoder.apiDecoder.decode(DataWrapper<GoalInstance>.self, from: data)
        return wrapper.data
    }

    /// POST /activities/weekly-daily-goals/instances/{goalInstanceId}/uncomplete
    func uncompleteInstance(goalInstanceId: String) async throws -> GoalInstance {
        let url = baseURL.appendingPathComponent("activities/weekly-daily-goals/instances/\(goalInstanceId)/uncomplete")
        let data = try await performRequest(url: url, method: "POST")
        let wrapper = try JSONDecoder.apiDecoder.decode(DataWrapper<GoalInstance>.self, from: data)
        return wrapper.data
    }

    /// POST /activities/weekly-daily-goals/instances/{goalInstanceId}/dismiss
    func dismissInstance(goalInstanceId: String) async throws -> GoalInstance {
        let url = baseURL.appendingPathComponent("activities/weekly-daily-goals/instances/\(goalInstanceId)/dismiss")
        let data = try await performRequest(url: url, method: "POST")
        let wrapper = try JSONDecoder.apiDecoder.decode(DataWrapper<GoalInstance>.self, from: data)
        return wrapper.data
    }

    // MARK: - Nudge Dismissal

    /// POST /activities/weekly-daily-goals/nudges/{dynamic}/dismiss
    func dismissNudge(dynamic: RecoveryDynamic, date: String) async throws {
        let url = baseURL.appendingPathComponent("activities/weekly-daily-goals/nudges/\(dynamic.rawValue)/dismiss")
        let body = try JSONEncoder.apiEncoder.encode(["date": date])
        _ = try await performRequest(url: url, method: "POST", body: body)
    }

    // MARK: - Reviews

    /// POST /activities/weekly-daily-goals/reviews/daily
    func submitDailyReview(_ request: SubmitDailyReviewRequest) async throws {
        let url = baseURL.appendingPathComponent("activities/weekly-daily-goals/reviews/daily")
        let body = try JSONEncoder.apiEncoder.encode(request)
        _ = try await performRequest(url: url, method: "POST", body: body)
    }

    // MARK: - Trends

    /// GET /activities/weekly-daily-goals/trends
    func getTrends(period: String = "30d", dynamic: RecoveryDynamic? = nil) async throws -> GoalTrendsData {
        var components = URLComponents(url: baseURL.appendingPathComponent("activities/weekly-daily-goals/trends"), resolvingAgainstBaseURL: false)!
        var items = [URLQueryItem(name: "period", value: period)]
        if let dynamic { items.append(URLQueryItem(name: "dynamic", value: dynamic.rawValue)) }
        components.queryItems = items
        let data = try await performRequest(url: components.url!)
        let wrapper = try JSONDecoder.apiDecoder.decode(DataWrapper<GoalTrendsData>.self, from: data)
        return wrapper.data
    }

    // MARK: - Settings

    /// GET /activities/weekly-daily-goals/settings
    func getSettings() async throws -> GoalSettings {
        let url = baseURL.appendingPathComponent("activities/weekly-daily-goals/settings")
        let data = try await performRequest(url: url)
        let wrapper = try JSONDecoder.apiDecoder.decode(DataWrapper<GoalSettings>.self, from: data)
        return wrapper.data
    }

    // MARK: - Networking

    private func performRequest(url: URL, method: String = "GET", body: Data? = nil) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer dev-token", forHTTPHeaderField: "Authorization")
        if let body { request.httpBody = body }
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoalsAPIError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw GoalsAPIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        return data
    }
}

// MARK: - Response Wrappers

private struct DataWrapper<T: Decodable>: Decodable {
    let data: T
}

private struct DataArrayWrapper<T: Decodable>: Decodable {
    let data: [T]
}

// MARK: - Errors

enum GoalsAPIError: Error, LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int, data: Data)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code, _):
            return "Server error (HTTP \(code))"
        }
    }
}

// MARK: - JSON Coding Helpers

private extension JSONDecoder {
    static let apiDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

private extension JSONEncoder {
    static let apiEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}
