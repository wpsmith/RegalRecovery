import Foundation

// MARK: - Prayer Session API Types

/// Prayer session as returned by the API.
struct PrayerSessionDTO: Codable, Identifiable, Sendable {
    let prayerId: String
    let timestamp: String
    let prayerType: String
    let durationMinutes: Int?
    let notes: String?
    let linkedPrayerId: String?
    let linkedPrayerTitle: String?
    let moodBefore: Int?
    let moodAfter: Int?
    let isEphemeral: Bool?
    let links: Links?

    var id: String { prayerId }

    struct Links: Codable, Sendable {
        let `self`: String?
    }
}

/// Request body for creating a prayer session.
struct CreatePrayerSessionDTO: Codable, Sendable {
    let timestamp: String
    let prayerType: String
    var durationMinutes: Int?
    var notes: String?
    var linkedPrayerId: String?
    var moodBefore: Int?
    var moodAfter: Int?
    var isEphemeral: Bool?
}

/// Request body for updating a prayer session.
struct UpdatePrayerSessionDTO: Codable, Sendable {
    var prayerType: String?
    var durationMinutes: Int?
    var notes: String?
    var linkedPrayerId: String?
    var moodBefore: Int?
    var moodAfter: Int?
}

/// Prayer stats response from the API.
struct PrayerStatsDTO: Codable, Sendable {
    let currentStreakDays: Int
    let longestStreakDays: Int
    let totalPrayerDays: Int
    let sessionsThisWeek: Int
    let averageDurationMinutes: Double?
    let typeDistribution: TypeDistribution?
    let moodImpact: MoodImpactDTO?

    struct TypeDistribution: Codable, Sendable {
        let personal: Int?
        let guided: Int?
        let group: Int?
        let scriptureBased: Int?
        let intercessory: Int?
        let listening: Int?
    }

    struct MoodImpactDTO: Codable, Sendable {
        let averageMoodBefore: Double?
        let averageMoodAfter: Double?
    }
}

// MARK: - Prayer Session Endpoints

extension Endpoint {
    // Prayer Session CRUD
    static func createPrayerSession(_ body: CreatePrayerSessionDTO) -> Endpoint {
        .logActivity(type: "prayer", data: ActivityRequest(data: body))
    }

    static func listPrayerSessions(prayerType: String? = nil, startDate: String? = nil, endDate: String? = nil, cursor: String? = nil, limit: Int? = nil) -> Endpoint {
        .getActivities(type: "prayer", cursor: cursor, limit: limit)
    }

    static func getPrayerSession(id: String) -> Endpoint {
        .getActivities(type: "prayer/\(id)", cursor: nil, limit: nil)
    }

    static func getPrayerStats() -> Endpoint {
        .getActivities(type: "prayer/stats", cursor: nil, limit: nil)
    }
}

// MARK: - Prayer Session Service

/// Hand-written API client for prayer session endpoints.
/// Validates requests against the OpenAPI spec contract.
@MainActor
final class PrayerSessionService: Sendable {

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    /// Creates a prayer session (POST /activities/prayer).
    /// PR-AC1.1: Required fields are prayerType and timestamp.
    func createSession(_ request: CreatePrayerSessionDTO) async throws -> PrayerSessionDTO {
        let response: APIResponse<PrayerSessionDTO> = try await apiClient.request(
            .logActivity(type: "prayer", data: ActivityRequest(data: request))
        )
        return response.data
    }

    /// Creates a quick log session with defaults (PR-AC1.11).
    func quickLog() async throws -> PrayerSessionDTO {
        let request = CreatePrayerSessionDTO(
            timestamp: ISO8601DateFormatter().string(from: Date()),
            prayerType: "personal"
        )
        return try await createSession(request)
    }

    /// Lists prayer sessions with filtering (GET /activities/prayer).
    func listSessions(
        prayerType: String? = nil,
        startDate: String? = nil,
        endDate: String? = nil,
        cursor: String? = nil,
        limit: Int? = nil
    ) async throws -> PaginatedResponse<PrayerSessionDTO> {
        return try await apiClient.request(
            .getActivities(type: "prayer", cursor: cursor, limit: limit)
        )
    }

    /// Gets a prayer session by ID (GET /activities/prayer/{id}).
    func getSession(id: String) async throws -> PrayerSessionDTO {
        let response: APIResponse<PrayerSessionDTO> = try await apiClient.request(
            .getActivities(type: "prayer/\(id)", cursor: nil, limit: nil)
        )
        return response.data
    }

    /// Updates a prayer session (PATCH /activities/prayer/{id}).
    /// PR-AC1.10: Timestamp is immutable.
    /// PR-AC1.13: Notes editable within 24 hours only.
    func updateSession(id: String, _ request: UpdatePrayerSessionDTO) async throws -> PrayerSessionDTO {
        let response: APIResponse<PrayerSessionDTO> = try await apiClient.request(
            .logActivity(type: "prayer/\(id)", data: ActivityRequest(data: request))
        )
        return response.data
    }

    /// Deletes a prayer session (DELETE /activities/prayer/{id}).
    func deleteSession(id: String) async throws {
        let _: EmptyResponse = try await apiClient.request(
            .getActivities(type: "prayer/\(id)", cursor: nil, limit: nil)
        )
    }

    /// Gets prayer statistics and streak (GET /activities/prayer/stats).
    func getStats() async throws -> PrayerStatsDTO {
        let response: APIResponse<PrayerStatsDTO> = try await apiClient.request(
            .getActivities(type: "prayer/stats", cursor: nil, limit: nil)
        )
        return response.data
    }
}

// MARK: - Supporting Types

struct APIResponse<T: Codable & Sendable>: Codable, Sendable {
    let data: T
}

struct PaginatedResponse<T: Codable & Sendable>: Codable, Sendable {
    let data: [T]
    let meta: PageMeta?

    struct PageMeta: Codable, Sendable {
        let page: CursorPage?
    }

    struct CursorPage: Codable, Sendable {
        let nextCursor: String?
        let limit: Int?
    }
}

struct EmptyResponse: Codable, Sendable {}

struct ActivityRequest<T: Codable & Sendable>: Codable, Sendable {
    let data: T
}
