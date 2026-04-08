import Foundation

// MARK: - API Models

struct PersonCheckInAPIResponse: Codable {
    let data: PersonCheckInDTO
    let meta: PersonCheckInMeta?
}

struct PersonCheckInListAPIResponse: Codable {
    let data: [PersonCheckInDTO]
    let links: PaginationLinksDTO?
    let meta: ListMetaDTO?
}

struct PersonCheckInDTO: Codable, Identifiable {
    let checkInId: String
    let checkInType: String
    let method: String
    let timestamp: String
    let contactName: String?
    let durationMinutes: Int?
    let qualityRating: Int?
    let topicsDiscussed: [String]?
    let notes: String?
    let followUpItems: [FollowUpItemDTO]?
    let counselorSubCategory: String?
    let links: SelfLinkDTO?

    var id: String { checkInId }
}

struct FollowUpItemDTO: Codable {
    let text: String
    let goalId: String?
}

struct PersonCheckInMeta: Codable {
    let createdAt: String?
    let streakUpdated: Bool?
    let currentStreak: Int?
    let encouragement: String?
}

struct PaginationLinksDTO: Codable {
    let selfLink: String?
    let next: String?
    let prev: String?

    enum CodingKeys: String, CodingKey {
        case selfLink = "self"
        case next
        case prev
    }
}

struct ListMetaDTO: Codable {
    let page: PageMetaDTO?
}

struct PageMetaDTO: Codable {
    let nextCursor: String?
    let prevCursor: String?
    let limit: Int?
}

struct SelfLinkDTO: Codable {
    let selfLink: String?

    enum CodingKeys: String, CodingKey {
        case selfLink = "self"
    }
}

struct PersonCheckInStreaksAPIResponse: Codable {
    let data: StreaksDataDTO
    let links: SelfLinkDTO?
    let meta: [String: String]?
}

struct StreaksDataDTO: Codable {
    let streaks: [StreakDTO]
    let combined: CombinedStreakDTO
}

struct StreakDTO: Codable {
    let checkInType: String
    let currentStreak: Int
    let longestStreak: Int
    let streakUnit: String
    let checkInsThisWeek: Int
    let checkInsThisMonth: Int
    let averagePerWeek: Double
}

struct CombinedStreakDTO: Codable {
    let totalCheckInsThisWeek: Int
    let totalCheckInsThisMonth: Int
}

struct PersonCheckInSettingsAPIResponse: Codable {
    let data: SettingsDataDTO
}

struct SettingsDataDTO: Codable {
    let spouse: SubTypeSettingsDTO?
    let sponsor: SubTypeSettingsDTO?
    let counselorCoach: SubTypeSettingsDTO?
}

struct SubTypeSettingsDTO: Codable {
    let contactName: String?
    let streakFrequency: String?
    let requiredCountPerWeek: Int?
    let inactivityAlertDays: Int?
    let reminderEnabled: Bool?
    let reminderTime: String?
    let reminderFrequency: String?
}

struct PersonCheckInCalendarAPIResponse: Codable {
    let data: CalendarDataDTO
}

struct CalendarDataDTO: Codable {
    let month: String
    let days: [CalendarDayDTO]
}

struct CalendarDayDTO: Codable {
    let date: String
    let checkIns: [CalendarDayCheckInDTO]
}

struct CalendarDayCheckInDTO: Codable {
    let checkInType: String
    let count: Int
}

// MARK: - Request Models

struct CreatePersonCheckInRequestDTO: Codable {
    let checkInType: String
    let method: String
    let timestamp: String?
    let contactName: String?
    let durationMinutes: Int?
    let qualityRating: Int?
    let topicsDiscussed: [String]?
    let notes: String?
    let followUpItems: [String]?
    let counselorSubCategory: String?
}

struct QuickLogPersonCheckInRequestDTO: Codable {
    let checkInType: String
    let method: String?
}

struct UpdatePersonCheckInRequestDTO: Codable {
    let method: String?
    let contactName: String?
    let durationMinutes: Int?
    let qualityRating: Int?
    let topicsDiscussed: [String]?
    let notes: String?
    let followUpItems: [String]?
    let counselorSubCategory: String?
}

// MARK: - API Client

actor PersonCheckInAPIClient {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL = URL(string: "http://localhost:8080/v1")!, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - Create

    func createCheckIn(_ request: CreatePersonCheckInRequestDTO, token: String) async throws -> PersonCheckInAPIResponse {
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent("activities/person-check-ins"))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await session.data(for: urlRequest)
        try validateResponse(response)
        return try JSONDecoder().decode(PersonCheckInAPIResponse.self, from: data)
    }

    // MARK: - Quick Log

    func quickLogCheckIn(_ request: QuickLogPersonCheckInRequestDTO, token: String) async throws -> PersonCheckInAPIResponse {
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent("activities/person-check-ins/quick"))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await session.data(for: urlRequest)
        try validateResponse(response)
        return try JSONDecoder().decode(PersonCheckInAPIResponse.self, from: data)
    }

    // MARK: - List

    func listCheckIns(checkInType: String? = nil, cursor: String? = nil, limit: Int = 25, token: String) async throws -> PersonCheckInListAPIResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("activities/person-check-ins"), resolvingAgainstBaseURL: false)!
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "limit", value: "\(limit)")]
        if let checkInType { queryItems.append(URLQueryItem(name: "checkInType", value: checkInType)) }
        if let cursor { queryItems.append(URLQueryItem(name: "cursor", value: cursor)) }
        components.queryItems = queryItems

        var urlRequest = URLRequest(url: components.url!)
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: urlRequest)
        try validateResponse(response)
        return try JSONDecoder().decode(PersonCheckInListAPIResponse.self, from: data)
    }

    // MARK: - Get by ID

    func getCheckIn(id: String, token: String) async throws -> PersonCheckInAPIResponse {
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent("activities/person-check-ins/\(id)"))
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: urlRequest)
        try validateResponse(response)
        return try JSONDecoder().decode(PersonCheckInAPIResponse.self, from: data)
    }

    // MARK: - Update

    func updateCheckIn(id: String, request: UpdatePersonCheckInRequestDTO, token: String) async throws -> PersonCheckInAPIResponse {
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent("activities/person-check-ins/\(id)"))
        urlRequest.httpMethod = "PATCH"
        urlRequest.setValue("application/merge-patch+json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await session.data(for: urlRequest)
        try validateResponse(response)
        return try JSONDecoder().decode(PersonCheckInAPIResponse.self, from: data)
    }

    // MARK: - Delete

    func deleteCheckIn(id: String, token: String) async throws {
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent("activities/person-check-ins/\(id)"))
        urlRequest.httpMethod = "DELETE"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await session.data(for: urlRequest)
        try validateResponse(response)
    }

    // MARK: - Streaks

    func getStreaks(token: String) async throws -> PersonCheckInStreaksAPIResponse {
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent("activities/person-check-ins/streaks"))
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: urlRequest)
        try validateResponse(response)
        return try JSONDecoder().decode(PersonCheckInStreaksAPIResponse.self, from: data)
    }

    // MARK: - Calendar

    func getCalendar(month: String, token: String) async throws -> PersonCheckInCalendarAPIResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("activities/person-check-ins/calendar"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "month", value: month)]

        var urlRequest = URLRequest(url: components.url!)
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: urlRequest)
        try validateResponse(response)
        return try JSONDecoder().decode(PersonCheckInCalendarAPIResponse.self, from: data)
    }

    // MARK: - Validation

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PersonCheckInAPIError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw PersonCheckInAPIError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}

enum PersonCheckInAPIError: Error, LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid server response"
        case .httpError(let code): return "Server error: \(code)"
        case .decodingError: return "Failed to decode response"
        }
    }
}
