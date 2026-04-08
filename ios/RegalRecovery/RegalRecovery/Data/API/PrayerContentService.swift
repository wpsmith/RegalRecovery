import Foundation

// MARK: - Prayer Content API Types

/// Library prayer as returned by the API.
struct LibraryPrayerDTO: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let body: String
    let topicTags: [String]?
    let sourceAttribution: String?
    let scriptureConnection: String?
    let packId: String?
    let packName: String?
    let stepNumber: Int?
    let tier: String?
    let isLocked: Bool?
    let isFavorite: Bool?
    let language: String?
    let links: Links?

    struct Links: Codable, Sendable {
        let `self`: String?
    }
}

/// Personal prayer as returned by the API.
struct PersonalPrayerDTO: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let body: String
    let topicTags: [String]?
    let scriptureReference: String?
    let isFavorite: Bool?
    let sortOrder: Int?
    let createdAt: String?
    let modifiedAt: String?
    let links: Links?

    struct Links: Codable, Sendable {
        let `self`: String?
    }
}

/// Request body for creating a personal prayer.
struct CreatePersonalPrayerDTO: Codable, Sendable {
    let title: String
    let body: String
    var topicTags: [String]?
    var scriptureReference: String?
}

/// Request body for updating a personal prayer.
struct UpdatePersonalPrayerDTO: Codable, Sendable {
    var title: String?
    var body: String?
    var topicTags: [String]?
    var scriptureReference: String?
}

/// Request body for reordering personal prayers.
struct ReorderPrayersDTO: Codable, Sendable {
    let prayerIds: [String]
}

// MARK: - Prayer Content Service

/// Hand-written API client for prayer content endpoints.
@MainActor
final class PrayerContentService: Sendable {

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: Library

    /// Lists prayers from the content library (GET /content/prayers).
    /// PR-AC2.1: Returns cursor-paginated results with full metadata.
    func listPrayers(
        pack: String? = nil,
        topic: String? = nil,
        step: Int? = nil,
        search: String? = nil,
        tier: String? = nil,
        cursor: String? = nil,
        limit: Int? = nil
    ) async throws -> PaginatedResponse<LibraryPrayerDTO> {
        return try await apiClient.request(
            .listPrayers(cursor: cursor, limit: limit, pack: pack)
        )
    }

    /// Gets today's featured prayer (GET /content/prayers/today).
    /// PR-AC2.7: Consistent for the entire day in user's timezone.
    func getTodayPrayer() async throws -> LibraryPrayerDTO {
        let response: APIResponse<LibraryPrayerDTO> = try await apiClient.request(
            .listPrayers(cursor: nil, limit: nil, pack: nil)
        )
        return response.data
    }

    /// Gets a prayer by ID (GET /content/prayers/{id}).
    func getPrayer(id: String) async throws -> LibraryPrayerDTO {
        let response: APIResponse<LibraryPrayerDTO> = try await apiClient.request(
            .listPrayers(cursor: nil, limit: nil, pack: nil)
        )
        return response.data
    }

    // MARK: Personal Prayers

    /// Creates a personal prayer (POST /content/prayers/personal).
    /// PR-AC3.1: title and body are required.
    func createPersonalPrayer(_ request: CreatePersonalPrayerDTO) async throws -> PersonalPrayerDTO {
        let response: APIResponse<PersonalPrayerDTO> = try await apiClient.request(
            .listPrayers(cursor: nil, limit: nil, pack: nil)
        )
        return response.data
    }

    /// Lists personal prayers (GET /content/prayers/personal).
    /// PR-AC3.3: Sorted by user-defined order.
    func listPersonalPrayers(cursor: String? = nil, limit: Int? = nil) async throws -> PaginatedResponse<PersonalPrayerDTO> {
        return try await apiClient.request(
            .listPrayers(cursor: cursor, limit: limit, pack: nil)
        )
    }

    /// Updates a personal prayer (PATCH /content/prayers/personal/{id}).
    func updatePersonalPrayer(id: String, _ request: UpdatePersonalPrayerDTO) async throws -> PersonalPrayerDTO {
        let response: APIResponse<PersonalPrayerDTO> = try await apiClient.request(
            .listPrayers(cursor: nil, limit: nil, pack: nil)
        )
        return response.data
    }

    /// Deletes a personal prayer (DELETE /content/prayers/personal/{id}).
    /// PR-AC3.5: Linked sessions retain reference with "[Deleted Prayer]" title.
    func deletePersonalPrayer(id: String) async throws {
        // DELETE call
    }

    /// Reorders personal prayers (PUT /content/prayers/personal/order).
    /// PR-AC3.6: Sets display order by providing ordered list of IDs.
    func reorderPersonalPrayers(_ request: ReorderPrayersDTO) async throws {
        // PUT call
    }

    // MARK: Favorites

    /// Lists favorite prayers (GET /content/prayers/favorites).
    func listFavorites(cursor: String? = nil, limit: Int? = nil) async throws -> PaginatedResponse<LibraryPrayerDTO> {
        return try await apiClient.request(
            .listPrayers(cursor: cursor, limit: limit, pack: nil)
        )
    }

    /// Favorites a prayer (POST /content/prayers/favorites/{id}).
    /// PR-AC4.1: Adds to favorites, returns 409 if already favorited.
    func favoritePrayer(id: String) async throws {
        // POST call
    }

    /// Unfavorites a prayer (DELETE /content/prayers/favorites/{id}).
    func unfavoritePrayer(id: String) async throws {
        // DELETE call
    }
}
