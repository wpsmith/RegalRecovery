import Foundation
import OSLog

/// Hand-written API client for all 11 mood endpoints.
/// Conforms to the OpenAPI spec at docs/prd/specific-features/Mood/specs/openapi.yaml.
/// Feature-flagged behind `activity.mood`.
final class MoodAPIClient: Sendable {

    private let apiClient: APIClient
    private let logger = Logger(subsystem: "com.regalrecovery.app", category: "MoodAPIClient")

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - CRUD Endpoints

    /// POST /activities/mood - Create a mood entry.
    /// Returns the created entry with crisisPrompted flag.
    func createMoodEntry(_ request: CreateMoodEntryRequest) async throws -> SiemensResponse<MoodEntryData> {
        return try await apiClient.post(.createMoodEntry(request))
    }

    /// GET /activities/mood - List mood entries with filters and pagination.
    func listMoodEntries(
        startDate: String? = nil,
        endDate: String? = nil,
        rating: [Int]? = nil,
        emotionLabel: String? = nil,
        timeOfDay: String? = nil,
        search: String? = nil,
        cursor: String? = nil,
        limit: Int? = nil
    ) async throws -> PaginatedResponse<MoodEntryData> {
        let ratingStr = rating.map { $0.map(String.init).joined(separator: ",") }
        return try await apiClient.getList(
            .listMoodEntries(
                startDate: startDate,
                endDate: endDate,
                rating: ratingStr,
                emotionLabel: emotionLabel,
                timeOfDay: timeOfDay,
                search: search,
                cursor: cursor,
                limit: limit
            )
        )
    }

    /// GET /activities/mood/{moodId} - Get a single mood entry.
    func getMoodEntry(moodId: String) async throws -> SiemensResponse<MoodEntryData> {
        return try await apiClient.get(.getMoodEntry(moodId: moodId))
    }

    /// PATCH /activities/mood/{moodId} - Update a mood entry (within 24h).
    func updateMoodEntry(moodId: String, request: UpdateMoodEntryRequest) async throws -> SiemensResponse<MoodEntryData> {
        return try await apiClient.patch(.updateMoodEntry(moodId: moodId, request))
    }

    /// DELETE /activities/mood/{moodId} - Delete a mood entry (within 24h).
    func deleteMoodEntry(moodId: String) async throws {
        try await apiClient.delete(.deleteMoodEntry(moodId: moodId))
    }

    // MARK: - Summary Endpoints

    /// GET /activities/mood/today - Get today's mood summary.
    func getMoodToday() async throws -> SiemensResponse<MoodTodayData> {
        return try await apiClient.get(.getMoodToday)
    }

    /// GET /activities/mood/daily-summaries - Get daily summaries for calendar.
    func getDailySummaries(
        startDate: String,
        endDate: String,
        cursor: String? = nil,
        limit: Int? = nil
    ) async throws -> PaginatedResponse<MoodDailySummaryData> {
        return try await apiClient.getList(
            .getMoodDailySummaries(startDate: startDate, endDate: endDate, cursor: cursor, limit: limit)
        )
    }

    /// GET /activities/mood/streak - Get mood tracking streak.
    func getMoodStreak() async throws -> SiemensResponse<MoodStreakData> {
        return try await apiClient.get(.getMoodStreak)
    }

    // MARK: - Trends Endpoints

    /// GET /activities/mood/trends - Get mood trends and insights.
    /// period: "7d", "30d", or "90d"
    func getMoodTrends(period: String) async throws -> SiemensResponse<MoodTrendsData> {
        return try await apiClient.get(.getMoodTrends(period: period))
    }

    /// GET /activities/mood/correlations - Get mood correlations.
    /// period: "30d" or "90d"
    func getMoodCorrelations(period: String) async throws -> SiemensResponse<MoodCorrelationsData> {
        return try await apiClient.get(.getMoodCorrelations(period: period))
    }

    // MARK: - Alerts Endpoint

    /// GET /activities/mood/alerts/status - Get current mood alert status.
    func getMoodAlertStatus() async throws -> SiemensResponse<MoodAlertStatusData> {
        return try await apiClient.get(.getMoodAlertStatus)
    }
}

// MARK: - Display Mode Preference

extension MoodAPIClient {
    /// Display mode preference key in UserDefaults.
    private static let displayModeKey = "mood_display_mode"

    /// Get the current display mode (emoji or numeric). Defaults to emoji.
    static var displayMode: MoodDisplayMode {
        let raw = UserDefaults.standard.string(forKey: displayModeKey) ?? MoodDisplayMode.emoji.rawValue
        return MoodDisplayMode(rawValue: raw) ?? .emoji
    }

    /// Set the display mode preference. This is local-only, no API call needed.
    static func setDisplayMode(_ mode: MoodDisplayMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: displayModeKey)
    }
}
