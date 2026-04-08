import Foundation
import Observation

/// ViewModel for the Devotionals activity feature.
/// Feature flag: activity.devotionals
@Observable
class DevotionalViewModel {
    // MARK: - Published State

    var todayDevotional: DevotionalDTO?
    var devotionalList: [DevotionalSummaryDTO] = []
    var completionHistory: [DevotionalCompletionDTO] = []
    var favorites: [DevotionalSummaryDTO] = []
    var seriesList: [DevotionalSeriesDTO] = []
    var currentStreak: DevotionalStreakDTO?

    var isLoading = false
    var errorMessage: String?

    // Legacy compatibility
    var days: [DevotionalDay] = []
    var currentDay: Int = 24
    var completedDays: Int = 23

    // MARK: - API Client

    private let apiClient: DevotionalAPIClient?

    init(apiClient: DevotionalAPIClient? = nil) {
        self.apiClient = apiClient
    }

    // MARK: - Load Today's Devotional

    func loadToday() async {
        guard let client = apiClient else {
            await loadLegacy()
            return
        }
        isLoading = true
        errorMessage = nil

        do {
            todayDevotional = try await client.getTodayDevotional()
            currentStreak = try await client.getStreak()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Complete Devotional

    func completeDevotional(
        devotionalId: String,
        reflection: String? = nil,
        moodTag: DevotionalMoodTag? = nil
    ) async throws -> DevotionalCompletionDTO? {
        guard let client = apiClient else {
            try await markCompleteLegacy(devotionalId: devotionalId)
            return nil
        }
        let completion = try await client.createCompletion(
            devotionalId: devotionalId,
            timestamp: Date(),
            reflection: reflection,
            moodTag: moodTag
        )
        // Update streak from completion response
        if let streakData = completion.devotionalStreak {
            currentStreak = streakData
        }
        return completion
    }

    // MARK: - Update Reflection (after completion)

    func updateReflection(
        completionId: String,
        reflection: String?,
        moodTag: DevotionalMoodTag? = nil
    ) async throws -> DevotionalCompletionDTO? {
        guard let client = apiClient else { return nil }
        return try await client.updateCompletion(
            completionId: completionId,
            reflection: reflection,
            moodTag: moodTag
        )
    }

    // MARK: - Favorites

    func loadFavorites() async {
        guard let client = apiClient else { return }
        do {
            let response = try await client.listFavorites()
            favorites = response.data
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleFavorite(devotionalId: String, isFavorite: Bool) async {
        guard let client = apiClient else { return }
        do {
            if isFavorite {
                try await client.removeFavorite(devotionalId: devotionalId)
            } else {
                try await client.addFavorite(devotionalId: devotionalId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - History

    func loadHistory(startDate: String? = nil, endDate: String? = nil) async {
        guard let client = apiClient else { return }
        do {
            let response = try await client.listHistory(startDate: startDate, endDate: endDate)
            completionHistory = response.data
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func exportHistory(
        startDate: String? = nil,
        endDate: String? = nil,
        includeReflections: Bool = true
    ) async -> DevotionalExportResponseDTO? {
        guard let client = apiClient else { return nil }
        do {
            return try await client.exportHistory(
                startDate: startDate,
                endDate: endDate,
                includeReflections: includeReflections
            )
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    // MARK: - Series

    func loadSeries() async {
        guard let client = apiClient else { return }
        do {
            let response = try await client.listSeries()
            seriesList = response.data
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func activateSeries(seriesId: String) async -> ActivateSeriesResponseDTO? {
        guard let client = apiClient else { return nil }
        do {
            return try await client.activateSeries(seriesId: seriesId)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    // MARK: - Sharing

    func shareDevotional(
        devotionalId: String,
        shareType: DevotionalShareType,
        contactId: String? = nil
    ) async -> DevotionalShareResponseDTO? {
        guard let client = apiClient else { return nil }
        do {
            return try await client.shareDevotional(
                devotionalId: devotionalId,
                shareType: shareType,
                contactId: contactId
            )
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    // MARK: - Streak

    func loadStreak() async {
        guard let client = apiClient else { return }
        do {
            currentStreak = try await client.getStreak()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Legacy Compatibility

    func load() async {
        days = MockData.devotionalDays
        completedDays = days.filter(\.isComplete).count
        currentDay = completedDays + 1
    }

    func markComplete(day: Int) async throws {
        guard let index = days.firstIndex(where: { $0.day == day }) else { return }

        let existing = days[index]
        days[index] = DevotionalDay(
            day: existing.day,
            title: existing.title,
            scripture: existing.scripture,
            scriptureText: existing.scriptureText,
            reflection: existing.reflection,
            isComplete: true
        )

        completedDays = days.filter(\.isComplete).count
        currentDay = min(completedDays + 1, days.count)
    }

    func getDayDetail(day: Int) -> DevotionalDay? {
        days.first(where: { $0.day == day })
    }

    private func loadLegacy() async {
        await load()
    }

    private func markCompleteLegacy(devotionalId: String) async throws {
        if let dayNum = Int(devotionalId.replacingOccurrences(of: "dev_", with: "")) {
            try await markComplete(day: dayNum)
        }
    }
}
