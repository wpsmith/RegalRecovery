import Foundation
import SwiftData
import OSLog

// MARK: - Sync Status

/// Observable sync state for UI indicators (e.g., "Syncing...", "Offline", "Up to date").
@Observable
final class SyncStatus: @unchecked Sendable {
    enum State: String, Sendable {
        case idle = "Up to date"
        case syncing = "Syncing..."
        case offline = "Offline"
        case error = "Sync error"
    }

    private(set) var state: State = .idle
    private(set) var pendingCount: Int = 0
    private(set) var lastSyncDate: Date?
    private(set) var lastError: String?

    func update(state: State, pendingCount: Int? = nil, error: String? = nil) {
        self.state = state
        if let pendingCount { self.pendingCount = pendingCount }
        if state == .idle { self.lastSyncDate = Date() }
        self.lastError = error
    }
}

// MARK: - Conflict Strategy

/// Domain-specific conflict resolution strategies.
enum ConflictStrategy: String, Sendable {
    /// Keep both local and server records (relapse logs, urge logs).
    case union = "union"
    /// Use the earliest date (sobriety start dates -- most conservative).
    case earliestDate = "earliest-date"
    /// Server accepts the latest write (profile updates, settings).
    case lastWriteWins = "last-write-wins"

    /// Determine strategy based on the endpoint path.
    static func forEndpoint(_ path: String) -> ConflictStrategy {
        if path.contains("/relapses") || path.contains("/urges") {
            return .union
        }
        if path.contains("/streaks") || path.contains("/sobriety") {
            return .earliestDate
        }
        return .lastWriteWins
    }
}

// MARK: - Sync Engine

/// Offline-first sync engine that queues writes when offline and replays them when connectivity returns.
///
/// Design:
/// - Writes are always persisted to the local SwiftData queue first.
/// - When online, the queue is drained in FIFO order.
/// - On connectivity change (offline -> online), the queue replays automatically.
/// - Background sync fires on app foreground and on a configurable interval.
/// - Conflict resolution is domain-specific (union, earliest-date, last-write-wins).
final class SyncEngine: @unchecked Sendable {

    // MARK: - Dependencies

    private let apiClient: APIClient
    private let networkMonitor: NetworkMonitor
    private let modelContainer: ModelContainer
    let status: SyncStatus

    // MARK: - Configuration

    /// Minimum interval between automatic sync attempts.
    var syncInterval: TimeInterval = 300 // 5 minutes

    // MARK: - State

    private let logger = Logger(subsystem: "com.regalrecovery.app", category: "SyncEngine")
    private var syncTask: Task<Void, Never>?
    private var periodicTask: Task<Void, Never>?
    private let syncLock = NSLock()
    private var isSyncing = false

    // MARK: - Init

    init(
        apiClient: APIClient,
        networkMonitor: NetworkMonitor,
        modelContainer: ModelContainer
    ) {
        self.apiClient = apiClient
        self.networkMonitor = networkMonitor
        self.modelContainer = modelContainer
        self.status = SyncStatus()
    }

    // MARK: - Lifecycle

    /// Start the sync engine. Call on app launch.
    func start() {
        // Listen for connectivity changes
        networkMonitor.onConnectivityChanged = { [weak self] isConnected in
            guard let self else { return }
            if isConnected {
                self.triggerSync()
            } else {
                Task { @MainActor in
                    self.status.update(state: .offline)
                }
            }
        }

        // Start periodic sync
        startPeriodicSync()

        // Initial sync if online
        if networkMonitor.isConnected {
            triggerSync()
        } else {
            Task { @MainActor in
                status.update(state: .offline)
            }
        }

        logger.info("SyncEngine started (interval: \(self.syncInterval)s)")
    }

    /// Stop the sync engine. Call on app termination or sign-out.
    func stop() {
        syncTask?.cancel()
        syncTask = nil
        periodicTask?.cancel()
        periodicTask = nil
        networkMonitor.onConnectivityChanged = nil
        logger.info("SyncEngine stopped")
    }

    /// Trigger an immediate sync attempt. Safe to call from any context.
    func triggerSync() {
        syncTask?.cancel()
        syncTask = Task { [weak self] in
            await self?.drainQueue()
        }
    }

    /// Called on app foreground (e.g., from ScenePhase.active).
    func onAppForeground() {
        triggerSync()
    }

    // MARK: - Enqueue

    /// Enqueue a write operation for sync. Persists to SwiftData immediately.
    /// Returns the queue item ID for tracking.
    @discardableResult
    @MainActor
    func enqueue(
        endpointPath: String,
        httpMethod: String,
        body: (any Encodable & Sendable)? = nil,
        conflictStrategy: ConflictStrategy? = nil
    ) throws -> String {
        let strategy = conflictStrategy ?? .forEndpoint(endpointPath)

        var bodyData: Data?
        if let body {
            let encoder = JSONEncoder()
            bodyData = try encoder.encode(AnyEncodableSync(body))
        }

        let item = RRSyncQueueItem(
            endpointPath: endpointPath,
            httpMethod: httpMethod,
            bodyData: bodyData,
            conflictStrategy: strategy.rawValue
        )

        let context = modelContainer.mainContext
        context.insert(item)
        try context.save()

        status.update(state: networkMonitor.isConnected ? status.state : .offline, pendingCount: status.pendingCount + 1)

        logger.debug("Enqueued sync item: \(httpMethod) \(endpointPath) [strategy: \(strategy.rawValue)]")

        // Attempt immediate sync if online
        if networkMonitor.isConnected {
            triggerSync()
        }

        return item.id
    }

    // MARK: - Queue Drain

    @MainActor
    private func drainQueue() async {
        guard !isSyncing else {
            logger.debug("Sync already in progress, skipping")
            return
        }
        guard networkMonitor.isConnected else {
            status.update(state: .offline)
            return
        }

        isSyncing = true
        status.update(state: .syncing)

        do {
            let context = modelContainer.mainContext
            let descriptor = FetchDescriptor<RRSyncQueueItem>(
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            let items = try context.fetch(descriptor)

            if items.isEmpty {
                status.update(state: .idle, pendingCount: 0)
                isSyncing = false
                return
            }

            logger.info("Draining sync queue: \(items.count) items")
            var processedCount = 0

            for item in items {
                guard !Task.isCancelled else { break }
                guard networkMonitor.isConnected else {
                    status.update(state: .offline, pendingCount: items.count - processedCount)
                    isSyncing = false
                    return
                }

                do {
                    try await replayItem(item)
                    context.delete(item)
                    try context.save()
                    processedCount += 1
                    status.update(state: .syncing, pendingCount: items.count - processedCount)
                } catch let error as APIError {
                    item.retryCount += 1
                    item.lastAttemptAt = Date()

                    if !error.isRetryable || item.retryCount > 5 {
                        // Permanent failure: remove from queue and log
                        logger.error("Sync item permanently failed after \(item.retryCount) attempts: \(item.httpMethod) \(item.endpointPath) - \(error.localizedDescription)")
                        context.delete(item)
                        try? context.save()
                        processedCount += 1
                    } else {
                        logger.warning("Sync item failed (attempt \(item.retryCount)): \(item.httpMethod) \(item.endpointPath) - \(error.localizedDescription)")
                        try? context.save()
                        // Stop draining on transient failure; will retry on next trigger
                        break
                    }
                }
            }

            let remaining = try context.fetchCount(FetchDescriptor<RRSyncQueueItem>())
            status.update(state: remaining == 0 ? .idle : .syncing, pendingCount: remaining)

        } catch {
            logger.error("Failed to drain sync queue: \(error.localizedDescription)")
            status.update(state: .error, error: error.localizedDescription)
        }

        isSyncing = false
    }

    // MARK: - Replay

    private func replayItem(_ item: RRSyncQueueItem) async throws {
        // Build a raw URLRequest from the queued data
        let url = apiClient.configuration.baseURL.appendingPathComponent(item.endpointPath)
        var request = URLRequest(url: url)
        request.httpMethod = item.httpMethod
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Correlation-Id")

        // Add conflict strategy header so server can resolve
        request.setValue(item.conflictStrategy, forHTTPHeaderField: "X-Conflict-Strategy")

        if let bodyData = item.bodyData {
            request.httpBody = bodyData
        }

        // We use the APIClient's convenience endpoint methods where possible,
        // but for queued items we replay the raw request through URLSession
        // with the current auth token.
        if let authProvider = apiClient.authProvider,
           let token = await authProvider.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        // 2xx is success; 409 with union strategy is acceptable (server handles merge)
        if (200..<300).contains(httpResponse.statusCode) {
            return
        }

        if httpResponse.statusCode == 409, item.conflictStrategy == ConflictStrategy.union.rawValue {
            // Union merge: server keeps both -- treat as success
            logger.info("409 Conflict with union strategy for \(item.endpointPath) -- server merged")
            return
        }

        // Map to APIError for retry logic
        throw APIError.serverError(statusCode: httpResponse.statusCode, message: "Sync replay failed with \(httpResponse.statusCode)")
    }

    // MARK: - Periodic Sync

    private func startPeriodicSync() {
        periodicTask?.cancel()
        periodicTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64((self?.syncInterval ?? 300) * 1_000_000_000))
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    self?.triggerSync()
                }
            }
        }
    }
}

// MARK: - Type-Erased Encodable for Sync

private struct AnyEncodableSync: Encodable {
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
