// DevotionalOfflineManager.swift
// Regal Recovery
//
// Offline cache and sync manager for Devotionals.
// Caches current day + 7 days ahead (AC-DEV-OFFLINE-01).
// Queues offline completions for sync on reconnection (AC-DEV-OFFLINE-02).

import Foundation
import SwiftData

/// Manages offline caching of devotional content and queuing of offline completions.
@MainActor
final class DevotionalOfflineManager {
    private let modelContainer: ModelContainer
    private let apiClient: DevotionalAPIClient

    /// Number of days to cache ahead of the current day.
    static let cacheAheadDays = 7

    init(modelContainer: ModelContainer, apiClient: DevotionalAPIClient) {
        self.modelContainer = modelContainer
        self.apiClient = apiClient
    }

    // MARK: - Cache Devotional Content (AC-DEV-OFFLINE-01)

    /// Pre-loads the current day's devotional plus the next 7 days into SwiftData.
    func cacheUpcomingDevotionals() async {
        do {
            // Cache today's devotional
            let today = try await apiClient.getTodayDevotional()
            let context = modelContainer.mainContext
            let cached = CachedDevotional(from: today)
            context.insert(cached)

            // Cache next 7 days via list endpoint
            // The API returns devotionals in sequence when browsing by series or rotation
            let list = try await apiClient.listDevotionals(limit: Self.cacheAheadDays)
            for summary in list.data {
                // Fetch full content for each
                do {
                    let full = try await apiClient.getDevotional(id: summary.id)
                    let cachedFull = CachedDevotional(from: full)
                    context.insert(cachedFull)
                } catch {
                    // Skip individual failures -- best-effort caching
                    continue
                }
            }

            try context.save()
        } catch {
            // Cache failures are non-fatal -- the app works without cache
        }
    }

    /// Retrieves a cached devotional by ID. Returns nil if not cached.
    func getCachedDevotional(devotionalId: String) -> CachedDevotional? {
        let context = modelContainer.mainContext
        let predicate = #Predicate<CachedDevotional> { $0.devotionalId == devotionalId }
        let descriptor = FetchDescriptor<CachedDevotional>(predicate: predicate)
        return try? context.fetch(descriptor).first
    }

    // MARK: - Offline Completion Queue (AC-DEV-OFFLINE-02)

    /// Saves a completion locally when offline. Will be synced when connection restores.
    func queueOfflineCompletion(
        devotionalId: String,
        timestamp: Date,
        reflection: String?,
        moodTag: DevotionalMoodTag?
    ) {
        let context = modelContainer.mainContext
        let pending = PendingDevotionalCompletion(
            devotionalId: devotionalId,
            timestamp: timestamp,
            reflection: reflection,
            moodTag: moodTag
        )
        context.insert(pending)
        try? context.save()
    }

    /// Syncs all pending offline completions to the server.
    /// Uses union merge strategy: keeps both records, deduplicates by devotionalId + date.
    func syncPendingCompletions() async -> Int {
        let context = modelContainer.mainContext
        let predicate = #Predicate<PendingDevotionalCompletion> { $0.isSynced == false }
        let descriptor = FetchDescriptor<PendingDevotionalCompletion>(predicate: predicate)

        guard let pending = try? context.fetch(descriptor), !pending.isEmpty else {
            return 0
        }

        var syncedCount = 0
        for completion in pending {
            do {
                _ = try await apiClient.createCompletion(
                    devotionalId: completion.devotionalId,
                    timestamp: completion.timestamp,
                    reflection: completion.reflection,
                    moodTag: completion.moodTag.flatMap { DevotionalMoodTag(rawValue: $0) }
                )
                completion.isSynced = true
                syncedCount += 1
            } catch {
                // 409 Conflict means already completed -- mark as synced
                if case DevotionalAPIError.conflict = error {
                    completion.isSynced = true
                    syncedCount += 1
                }
                // Other errors: leave unsynced for next attempt
            }
        }

        try? context.save()
        return syncedCount
    }

    // MARK: - Cache Cleanup

    /// Removes cached devotionals older than the specified number of days.
    func cleanupOldCache(olderThanDays: Int = 14) {
        let context = modelContainer.mainContext
        let cutoff = Calendar.current.date(byAdding: .day, value: -olderThanDays, to: Date())!
        let predicate = #Predicate<CachedDevotional> { $0.cachedAt < cutoff }
        let descriptor = FetchDescriptor<CachedDevotional>(predicate: predicate)

        if let old = try? context.fetch(descriptor) {
            for item in old {
                context.delete(item)
            }
            try? context.save()
        }
    }
}
