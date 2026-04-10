import Foundation
import SwiftData
import OSLog

// MARK: - SwiftData Models for Offline Cache

/// Cached circle set for offline viewing and editing.
/// Stores the active circle set with all items as JSON for SwiftData compatibility.
@Model
final class RRCachedCircleSet {

    @Attribute(.unique) var setId: String
    var userId: String
    var name: String
    var recoveryArea: String
    var frameworkPreference: String?
    var status: String
    var innerCircleJSON: String
    var middleCircleJSON: String
    var outerCircleJSON: String
    var versionNumber: Int
    var createdAt: Date
    var modifiedAt: Date
    var committedAt: Date?
    var cachedAt: Date

    init(
        setId: String,
        userId: String,
        name: String,
        recoveryArea: String,
        frameworkPreference: String? = nil,
        status: String,
        innerCircleJSON: String,
        middleCircleJSON: String,
        outerCircleJSON: String,
        versionNumber: Int,
        createdAt: Date,
        modifiedAt: Date,
        committedAt: Date? = nil,
        cachedAt: Date = Date()
    ) {
        self.setId = setId
        self.userId = userId
        self.name = name
        self.recoveryArea = recoveryArea
        self.frameworkPreference = frameworkPreference
        self.status = status
        self.innerCircleJSON = innerCircleJSON
        self.middleCircleJSON = middleCircleJSON
        self.outerCircleJSON = outerCircleJSON
        self.versionNumber = versionNumber
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.committedAt = committedAt
        self.cachedAt = cachedAt
    }

    /// Decode inner circle items from JSON storage.
    var innerCircle: [CircleItem] {
        Self.decodeItems(innerCircleJSON)
    }

    /// Decode middle circle items from JSON storage.
    var middleCircle: [CircleItem] {
        Self.decodeItems(middleCircleJSON)
    }

    /// Decode outer circle items from JSON storage.
    var outerCircle: [CircleItem] {
        Self.decodeItems(outerCircleJSON)
    }

    /// Convert to the API model type.
    func toCircleSet() -> CircleSet? {
        guard let area = RecoveryArea(rawValue: recoveryArea),
              let setStatus = CircleSetStatus(rawValue: status) else {
            return nil
        }

        let framework = frameworkPreference.flatMap { FrameworkPreference(rawValue: $0) }

        return CircleSet(
            setId: setId,
            userId: userId,
            name: name,
            recoveryArea: area,
            frameworkPreference: framework,
            status: setStatus,
            innerCircle: innerCircle,
            middleCircle: middleCircle,
            outerCircle: outerCircle,
            versionNumber: versionNumber,
            createdAt: createdAt,
            modifiedAt: modifiedAt,
            committedAt: committedAt
        )
    }

    /// Create a cached set from an API model.
    static func from(_ circleSet: CircleSet) -> RRCachedCircleSet {
        return RRCachedCircleSet(
            setId: circleSet.setId,
            userId: circleSet.userId,
            name: circleSet.name,
            recoveryArea: circleSet.recoveryArea.rawValue,
            frameworkPreference: circleSet.frameworkPreference?.rawValue,
            status: circleSet.status.rawValue,
            innerCircleJSON: encodeItems(circleSet.innerCircle),
            middleCircleJSON: encodeItems(circleSet.middleCircle),
            outerCircleJSON: encodeItems(circleSet.outerCircle),
            versionNumber: circleSet.versionNumber ?? 1,
            createdAt: circleSet.createdAt,
            modifiedAt: circleSet.modifiedAt,
            committedAt: circleSet.committedAt
        )
    }

    // MARK: - JSON Helpers

    private static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private static func decodeItems(_ json: String) -> [CircleItem] {
        guard let data = json.data(using: .utf8),
              let items = try? jsonDecoder.decode([CircleItem].self, from: data) else {
            return []
        }
        return items
    }

    private static func encodeItems(_ items: [CircleItem]) -> String {
        guard let data = try? jsonEncoder.encode(items),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }
}

// MARK: - Offline Mutation Queue

/// Queued offline circle mutation, synced when connectivity returns.
/// Each mutation records the endpoint, method, and request body to replay.
@Model
final class RROfflineCircleMutation {

    @Attribute(.unique) var id: String
    /// The mutation type for dispatch (e.g., "createSet", "addItem", "moveItem").
    var mutationType: String
    /// The target set ID (if applicable).
    var setId: String?
    /// The target item ID (if applicable).
    var itemId: String?
    /// Serialized request body JSON.
    var requestBodyJSON: String
    var createdAt: Date
    var retryCount: Int
    var lastAttemptAt: Date?

    init(
        id: String = UUID().uuidString,
        mutationType: String,
        setId: String? = nil,
        itemId: String? = nil,
        requestBodyJSON: String,
        createdAt: Date = Date(),
        retryCount: Int = 0,
        lastAttemptAt: Date? = nil
    ) {
        self.id = id
        self.mutationType = mutationType
        self.setId = setId
        self.itemId = itemId
        self.requestBodyJSON = requestBodyJSON
        self.createdAt = createdAt
        self.retryCount = retryCount
        self.lastAttemptAt = lastAttemptAt
    }
}

// MARK: - Offline Cache

/// SwiftData-backed offline cache for Three Circles.
///
/// Maintains:
/// - Active circle sets cached for offline viewing and editing.
/// - A queue of offline mutations that replay when connectivity returns.
///
/// Refresh strategy:
/// - Refreshes on app launch when online.
/// - Does NOT block UI -- stale cache is always usable.
@Observable
final class ThreeCirclesOfflineCache: @unchecked Sendable {

    // MARK: - State

    private(set) var cachedSetCount: Int = 0
    private(set) var pendingMutationCount: Int = 0
    private(set) var lastRefreshDate: Date?

    // MARK: - Dependencies

    private let modelContainer: ModelContainer
    private let apiClient: ThreeCirclesAPIClient
    private let networkMonitor: NetworkMonitor
    private let logger = Logger(subsystem: "com.regalrecovery.app", category: "ThreeCirclesCache")

    // MARK: - Init

    init(
        modelContainer: ModelContainer,
        apiClient: ThreeCirclesAPIClient,
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
            logger.debug("Offline -- skipping Three Circles cache refresh")
            await updateCounts()
            return
        }

        logger.info("Refreshing Three Circles offline cache")

        do {
            try await refreshActiveSets()
            lastRefreshDate = Date()
            await updateCounts()
            logger.info("Three Circles cache refresh complete: \(self.cachedSetCount) sets cached")
        } catch {
            logger.error("Three Circles cache refresh failed: \(error.localizedDescription)")
            await updateCounts()
        }

        // Also drain any pending offline mutations
        await drainOfflineMutationQueue()
    }

    /// Get all cached circle sets for offline display.
    @MainActor
    func getCachedCircleSets() -> [CircleSet] {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<RRCachedCircleSet>(
            sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]
        )

        guard let cached = try? context.fetch(descriptor) else { return [] }
        return cached.compactMap { $0.toCircleSet() }
    }

    /// Get a specific cached circle set by ID.
    @MainActor
    func getCachedCircleSet(setId: String) -> CircleSet? {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<RRCachedCircleSet>(
            predicate: #Predicate { $0.setId == setId }
        )

        guard let cached = try? context.fetch(descriptor),
              let first = cached.first else { return nil }
        return first.toCircleSet()
    }

    /// Cache a circle set (insert or update).
    @MainActor
    func cacheCircleSet(_ circleSet: CircleSet) throws {
        let context = modelContainer.mainContext

        // Remove existing if present
        let existingDescriptor = FetchDescriptor<RRCachedCircleSet>(
            predicate: #Predicate { $0.setId == circleSet.setId }
        )
        if let existing = try? context.fetch(existingDescriptor) {
            for item in existing {
                context.delete(item)
            }
        }

        let cached = RRCachedCircleSet.from(circleSet)
        context.insert(cached)
        try context.save()

        cachedSetCount += 1
    }

    /// Remove a cached circle set.
    @MainActor
    func removeCachedCircleSet(setId: String) async throws {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<RRCachedCircleSet>(
            predicate: #Predicate { $0.setId == setId }
        )

        guard let existing = try? context.fetch(descriptor) else { return }
        for item in existing {
            context.delete(item)
        }
        try context.save()

        await updateCounts()
    }

    // MARK: - Offline Mutation Queue

    /// Queue a mutation for sync when online.
    @MainActor
    func queueOfflineMutation(
        mutationType: String,
        setId: String? = nil,
        itemId: String? = nil,
        requestBody: any Encodable & Sendable
    ) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let bodyData = try encoder.encode(ThreeCirclesOfflineEncodable(requestBody))
        let bodyJSON = String(data: bodyData, encoding: .utf8) ?? "{}"

        let mutation = RROfflineCircleMutation(
            mutationType: mutationType,
            setId: setId,
            itemId: itemId,
            requestBodyJSON: bodyJSON
        )

        let context = modelContainer.mainContext
        context.insert(mutation)
        try context.save()

        pendingMutationCount += 1
    }

    /// Get count of pending offline mutations.
    @MainActor
    func getPendingMutationCount() -> Int {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<RROfflineCircleMutation>()
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Internal

    /// Refresh active sets from server.
    @MainActor
    private func refreshActiveSets() async throws {
        let response = try await apiClient.listCircleSets(status: .active)
        let context = modelContainer.mainContext

        // Clear all existing cached sets
        let existingDescriptor = FetchDescriptor<RRCachedCircleSet>()
        if let existing = try? context.fetch(existingDescriptor) {
            for item in existing {
                context.delete(item)
            }
        }

        // Cache all active sets
        for circleSet in response.data {
            let cached = RRCachedCircleSet.from(circleSet)
            context.insert(cached)
        }

        // Also cache draft sets
        let draftsResponse = try await apiClient.listCircleSets(status: .draft)
        for circleSet in draftsResponse.data {
            let cached = RRCachedCircleSet.from(circleSet)
            context.insert(cached)
        }

        try context.save()
    }

    /// Drain pending offline mutations by replaying them against the API.
    @MainActor
    private func drainOfflineMutationQueue() async {
        guard networkMonitor.isConnected else { return }

        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<RROfflineCircleMutation>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )

        guard let mutations = try? context.fetch(descriptor), !mutations.isEmpty else { return }

        logger.info("Draining \(mutations.count) offline Three Circles mutations")

        for mutation in mutations {
            do {
                try await replayMutation(mutation)
                context.delete(mutation)
                try context.save()
                pendingMutationCount = max(0, pendingMutationCount - 1)
            } catch {
                logger.warning("Offline mutation replay failed (\(mutation.mutationType)): \(error.localizedDescription)")
                mutation.retryCount += 1
                mutation.lastAttemptAt = Date()

                // Drop mutations that have failed too many times
                if mutation.retryCount >= 5 {
                    logger.error("Dropping mutation \(mutation.id) after \(mutation.retryCount) retries")
                    context.delete(mutation)
                    pendingMutationCount = max(0, pendingMutationCount - 1)
                }

                try? context.save()
            }
        }
    }

    /// Replay a single queued mutation against the API.
    private func replayMutation(_ mutation: RROfflineCircleMutation) async throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let bodyData = mutation.requestBodyJSON.data(using: .utf8) else { return }

        switch mutation.mutationType {
        case "addItem":
            guard let setId = mutation.setId else { return }
            let request = try decoder.decode(CreateCircleItemRequest.self, from: bodyData)
            _ = try await apiClient.addCircleItem(setId: setId, request: request)

        case "updateItem":
            guard let setId = mutation.setId, let itemId = mutation.itemId else { return }
            let request = try decoder.decode(UpdateCircleItemRequest.self, from: bodyData)
            _ = try await apiClient.updateCircleItem(setId: setId, itemId: itemId, request: request)

        case "deleteItem":
            guard let setId = mutation.setId, let itemId = mutation.itemId else { return }
            try await apiClient.deleteCircleItem(setId: setId, itemId: itemId)

        case "moveItem":
            guard let setId = mutation.setId, let itemId = mutation.itemId else { return }
            let request = try decoder.decode(MoveItemRequest.self, from: bodyData)
            _ = try await apiClient.moveCircleItem(setId: setId, itemId: itemId, request: request)

        case "updateSet":
            guard let setId = mutation.setId else { return }
            let request = try decoder.decode(UpdateCircleSetRequest.self, from: bodyData)
            _ = try await apiClient.updateCircleSet(setId: setId, request: request)

        case "commitSet":
            guard let setId = mutation.setId else { return }
            let request = try decoder.decode(CommitCircleSetRequest.self, from: bodyData)
            _ = try await apiClient.commitCircleSet(setId: setId, request: request)

        case "deleteSet":
            guard let setId = mutation.setId else { return }
            try await apiClient.deleteCircleSet(setId: setId)

        default:
            logger.warning("Unknown mutation type: \(mutation.mutationType)")
        }
    }

    /// Update observable counts from SwiftData.
    @MainActor
    private func updateCounts() async {
        let context = modelContainer.mainContext

        let setDescriptor = FetchDescriptor<RRCachedCircleSet>()
        cachedSetCount = (try? context.fetchCount(setDescriptor)) ?? 0

        let mutationDescriptor = FetchDescriptor<RROfflineCircleMutation>()
        pendingMutationCount = (try? context.fetchCount(mutationDescriptor)) ?? 0
    }
}

// MARK: - Type-Erased Encodable Wrapper (Offline)

private struct ThreeCirclesOfflineEncodable: Encodable {
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

/// SwiftData model types for Three Circles offline cache.
/// Register with your ModelContainer configuration.
enum ThreeCirclesModelRegistration {
    static let modelTypes: [any PersistentModel.Type] = [
        RRCachedCircleSet.self,
        RROfflineCircleMutation.self
    ]
}
