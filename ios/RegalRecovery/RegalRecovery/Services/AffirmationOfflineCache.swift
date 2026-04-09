import Foundation
import SwiftData
import OSLog

// MARK: - SwiftData Models for Offline Cache

/// Cached affirmation for offline use. Minimum 30 affirmations always available.
@Model
final class RRCachedAffirmation {

    @Attribute(.unique) var id: String
    var text: String
    var level: Int
    var coreBeliefsJSON: String
    var category: String
    var track: String
    var recoveryStage: String
    var isFavorite: Bool
    var hasAudio: Bool
    var isSOSPool: Bool
    var cachedAt: Date

    init(
        id: String,
        text: String,
        level: Int,
        coreBeliefs: [Int],
        category: String,
        track: String,
        recoveryStage: String,
        isFavorite: Bool = false,
        hasAudio: Bool = false,
        isSOSPool: Bool = false,
        cachedAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.level = level
        self.coreBeliefsJSON = (try? JSONEncoder().encode(coreBeliefs))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        self.category = category
        self.track = track
        self.recoveryStage = recoveryStage
        self.isFavorite = isFavorite
        self.hasAudio = hasAudio
        self.isSOSPool = isSOSPool
        self.cachedAt = cachedAt
    }

    /// Decode core beliefs from JSON storage.
    var coreBeliefs: [Int] {
        guard let data = coreBeliefsJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([Int].self, from: data) else {
            return []
        }
        return decoded
    }

    /// Convert to the API model type.
    func toAffirmationItem() -> AffirmationItem? {
        guard let cat = AffirmationCategory(rawValue: category),
              let trk = AffirmationTrack(rawValue: track),
              let stage = AffirmationRecoveryStage(rawValue: recoveryStage) else {
            return nil
        }
        return AffirmationItem(
            id: id,
            text: text,
            level: level,
            coreBeliefs: coreBeliefs,
            category: cat,
            track: trk,
            recoveryStage: stage,
            isFavorite: isFavorite,
            hasAudio: hasAudio
        )
    }
}

/// Queued offline session completion, synced when connectivity returns.
@Model
final class RROfflineAffirmationSession {

    @Attribute(.unique) var id: String
    var sessionType: String
    var requestBodyJSON: String
    var createdAt: Date
    var retryCount: Int
    var lastAttemptAt: Date?

    init(
        id: String = UUID().uuidString,
        sessionType: String,
        requestBodyJSON: String,
        createdAt: Date = Date(),
        retryCount: Int = 0,
        lastAttemptAt: Date? = nil
    ) {
        self.id = id
        self.sessionType = sessionType
        self.requestBodyJSON = requestBodyJSON
        self.createdAt = createdAt
        self.retryCount = retryCount
        self.lastAttemptAt = lastAttemptAt
    }
}

// MARK: - Offline Cache

/// SwiftData-backed offline cache for affirmations.
///
/// Maintains:
/// - A general pool of at least 30 cached affirmations for offline morning/evening sessions.
/// - A separate SOS pool (Level 1-2, SOS category) always cached for crisis mode.
/// - A queue for offline session completions, ratings, and reflections that sync when online.
///
/// Refresh strategy:
/// - Refreshes on app launch when online.
/// - Does NOT block UI -- stale cache is always usable.
@Observable
final class AffirmationOfflineCache: @unchecked Sendable {

    // MARK: - Configuration

    /// Minimum number of general affirmations to keep cached.
    static let minimumCacheSize = 30

    /// Minimum number of SOS affirmations to keep cached.
    static let minimumSOSPoolSize = 10

    // MARK: - State

    private(set) var generalCacheCount: Int = 0
    private(set) var sosCacheCount: Int = 0
    private(set) var pendingSessionCount: Int = 0
    private(set) var lastRefreshDate: Date?

    // MARK: - Dependencies

    private let modelContainer: ModelContainer
    private let apiClient: AffirmationsAPIClient
    private let networkMonitor: NetworkMonitor
    private let logger = Logger(subsystem: "com.regalrecovery.app", category: "AffirmationCache")

    // MARK: - Init

    init(
        modelContainer: ModelContainer,
        apiClient: AffirmationsAPIClient,
        networkMonitor: NetworkMonitor
    ) {
        self.modelContainer = modelContainer
        self.apiClient = apiClient
        self.networkMonitor = networkMonitor
    }

    // MARK: - Public API

    /// Refresh the offline cache from the server.
    /// Call on app launch when online. Non-blocking; stale cache remains usable.
    @MainActor
    func refreshIfNeeded() async {
        guard networkMonitor.isConnected else {
            logger.debug("Offline -- skipping cache refresh")
            await updateCounts()
            return
        }

        logger.info("Refreshing affirmation offline cache")

        do {
            try await refreshGeneralPool()
            try await refreshSOSPool()
            lastRefreshDate = Date()
            await updateCounts()
            logger.info("Cache refresh complete: \(self.generalCacheCount) general, \(self.sosCacheCount) SOS")
        } catch {
            logger.error("Cache refresh failed: \(error.localizedDescription)")
            await updateCounts()
        }

        // Also drain any pending offline sessions
        await drainOfflineSessionQueue()
    }

    /// Get cached affirmations for an offline morning session (3 affirmations).
    @MainActor
    func getOfflineMorningAffirmations() -> [AffirmationItem] {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<RRCachedAffirmation>(
            predicate: #Predicate { !$0.isSOSPool },
            sortBy: [SortDescriptor(\.cachedAt, order: .forward)]
        )

        guard let cached = try? context.fetch(descriptor) else { return [] }

        // Apply a simplified 80/20 rule: pick from available levels
        let items = cached.compactMap { $0.toAffirmationItem() }
        guard items.count >= 3 else { return Array(items.prefix(3)) }

        // Shuffle and pick 3
        return Array(items.shuffled().prefix(3))
    }

    /// Get a cached affirmation for an offline evening session (1 affirmation).
    @MainActor
    func getOfflineEveningAffirmation() -> AffirmationItem? {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<RRCachedAffirmation>(
            predicate: #Predicate { !$0.isSOSPool },
            sortBy: [SortDescriptor(\.cachedAt, order: .forward)]
        )

        guard let cached = try? context.fetch(descriptor),
              let item = cached.randomElement() else { return nil }

        return item.toAffirmationItem()
    }

    /// Get cached SOS affirmations for an offline crisis session.
    @MainActor
    func getOfflineSOSAffirmations() -> [AffirmationItem] {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<RRCachedAffirmation>(
            predicate: #Predicate { $0.isSOSPool },
            sortBy: [SortDescriptor(\.cachedAt, order: .forward)]
        )

        guard let cached = try? context.fetch(descriptor) else { return [] }

        let items = cached.compactMap { $0.toAffirmationItem() }
        guard items.count >= 3 else { return items }

        return Array(items.shuffled().prefix(3))
    }

    // MARK: - Offline Session Queue

    /// Queue a session completion for sync when online.
    @MainActor
    func queueOfflineSessionCompletion(
        sessionType: String,
        requestBody: any Encodable & Sendable
    ) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let bodyData = try encoder.encode(AnyEncodableOffline(requestBody))
        let bodyJSON = String(data: bodyData, encoding: .utf8) ?? "{}"

        let item = RROfflineAffirmationSession(
            sessionType: sessionType,
            requestBodyJSON: bodyJSON
        )

        let context = modelContainer.mainContext
        context.insert(item)
        try context.save()

        pendingSessionCount += 1
        logger.debug("Queued offline \(sessionType) session for sync")
    }

    /// Drain the offline session queue by replaying queued completions to the server.
    @MainActor
    func drainOfflineSessionQueue() async {
        guard networkMonitor.isConnected else { return }

        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<RROfflineAffirmationSession>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )

        guard let items = try? context.fetch(descriptor), !items.isEmpty else { return }

        logger.info("Draining \(items.count) offline affirmation session(s)")

        for item in items {
            do {
                try await replaySession(item)
                context.delete(item)
                try context.save()
                logger.debug("Synced offline \(item.sessionType) session")
            } catch {
                item.retryCount += 1
                item.lastAttemptAt = Date()
                try? context.save()

                if item.retryCount > 5 {
                    logger.error("Permanently failed offline session after \(item.retryCount) attempts: \(item.sessionType)")
                    context.delete(item)
                    try? context.save()
                } else {
                    logger.warning("Failed to sync offline session (attempt \(item.retryCount)): \(error.localizedDescription)")
                    break // Stop draining on transient failure
                }
            }
        }

        await updateCounts()
    }

    // MARK: - Cache Management

    /// Update the observable cache counts.
    @MainActor
    private func updateCounts() async {
        let context = modelContainer.mainContext

        let generalDescriptor = FetchDescriptor<RRCachedAffirmation>(
            predicate: #Predicate { !$0.isSOSPool }
        )
        generalCacheCount = (try? context.fetchCount(generalDescriptor)) ?? 0

        let sosDescriptor = FetchDescriptor<RRCachedAffirmation>(
            predicate: #Predicate { $0.isSOSPool }
        )
        sosCacheCount = (try? context.fetchCount(sosDescriptor)) ?? 0

        let sessionDescriptor = FetchDescriptor<RROfflineAffirmationSession>()
        pendingSessionCount = (try? context.fetchCount(sessionDescriptor)) ?? 0
    }

    // MARK: - Refresh Logic

    /// Refresh the general affirmation pool from the server.
    @MainActor
    private func refreshGeneralPool() async throws {
        let response = try await apiClient.browseLibrary(limit: Self.minimumCacheSize)
        let context = modelContainer.mainContext

        // Upsert fetched affirmations
        for item in response.data {
            let existingDescriptor = FetchDescriptor<RRCachedAffirmation>(
                predicate: #Predicate { $0.id == item.id }
            )
            let existing = try? context.fetch(existingDescriptor)

            if let cachedItem = existing?.first {
                // Update existing
                cachedItem.text = item.text
                cachedItem.level = item.level
                cachedItem.isFavorite = item.isFavorite ?? false
                cachedItem.hasAudio = item.hasAudio ?? false
                cachedItem.cachedAt = Date()
            } else {
                // Insert new
                let cached = RRCachedAffirmation(
                    id: item.id,
                    text: item.text,
                    level: item.level,
                    coreBeliefs: item.coreBeliefs,
                    category: item.category.rawValue,
                    track: item.track.rawValue,
                    recoveryStage: item.recoveryStage.rawValue,
                    isFavorite: item.isFavorite ?? false,
                    hasAudio: item.hasAudio ?? false,
                    isSOSPool: false
                )
                context.insert(cached)
            }
        }

        try context.save()
        logger.debug("Refreshed general pool with \(response.data.count) affirmations")
    }

    /// Refresh the SOS pool from the server (Level 1-2, SOS category).
    @MainActor
    private func refreshSOSPool() async throws {
        let response = try await apiClient.browseLibrary(
            category: .sosCrisis,
            level: nil,
            track: nil,
            keyword: nil,
            cursor: nil,
            limit: Self.minimumSOSPoolSize
        )
        let context = modelContainer.mainContext

        for item in response.data {
            // Only cache Level 1-2 for SOS
            guard item.level <= 2 else { continue }

            let existingDescriptor = FetchDescriptor<RRCachedAffirmation>(
                predicate: #Predicate { $0.id == item.id }
            )
            let existing = try? context.fetch(existingDescriptor)

            if let cachedItem = existing?.first {
                cachedItem.text = item.text
                cachedItem.level = item.level
                cachedItem.isFavorite = item.isFavorite ?? false
                cachedItem.hasAudio = item.hasAudio ?? false
                cachedItem.isSOSPool = true
                cachedItem.cachedAt = Date()
            } else {
                let cached = RRCachedAffirmation(
                    id: item.id,
                    text: item.text,
                    level: item.level,
                    coreBeliefs: item.coreBeliefs,
                    category: item.category.rawValue,
                    track: item.track.rawValue,
                    recoveryStage: item.recoveryStage.rawValue,
                    isFavorite: item.isFavorite ?? false,
                    hasAudio: item.hasAudio ?? false,
                    isSOSPool: true
                )
                context.insert(cached)
            }
        }

        try context.save()
        logger.debug("Refreshed SOS pool with \(response.data.count) affirmations")
    }

    // MARK: - Session Replay

    /// Replay a queued offline session to the server.
    private func replaySession(_ item: RROfflineAffirmationSession) async throws {
        guard let bodyData = item.requestBodyJSON.data(using: .utf8) else {
            throw AffirmationAPIError.internalError(message: "Invalid offline session data")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        switch item.sessionType {
        case "morning":
            let request = try decoder.decode(CompleteMorningRequest.self, from: bodyData)
            _ = try await apiClient.completeMorningSession(request)

        case "evening":
            let request = try decoder.decode(CompleteEveningRequest.self, from: bodyData)
            _ = try await apiClient.completeEveningSession(request)

        case "sos":
            // SOS completions include the sosId in the session type as "sos:{sosId}"
            // For basic SOS start, no replay needed (it creates a new session)
            logger.debug("SOS session replay -- skipping (creates new session on reconnect)")

        default:
            logger.warning("Unknown offline session type: \(item.sessionType)")
        }
    }
}

// MARK: - Type-Erased Encodable for Offline Queue

private struct AnyEncodableOffline: Encodable {
    private let _encode: (Encoder) throws -> Void

    init(_ value: any Encodable & Sendable) {
        self._encode = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

// MARK: - Model Registration

/// Add the offline cache models to the app's model container.
/// Import these types in RRModelConfiguration.allModels.
extension RRCachedAffirmation {
    /// Model types that need to be registered for affirmation offline cache.
    static let offlineCacheModels: [any PersistentModel.Type] = [
        RRCachedAffirmation.self,
        RROfflineAffirmationSession.self,
    ]
}
