import Foundation
import OSLog

/// Phone call offline sync handler.
///
/// Enqueues phone call operations when offline and syncs them when connectivity
/// is restored. Uses union merge conflict resolution: both local and server
/// versions are preserved per project conventions.
final class PhoneCallOfflineSync: @unchecked Sendable {

    private let syncEngine: SyncEngine
    private let logger = Logger(subsystem: "com.regalrecovery.app", category: "PhoneCallOfflineSync")

    init(syncEngine: SyncEngine) {
        self.syncEngine = syncEngine
    }

    // MARK: - Enqueue Operations

    /// Enqueue a phone call creation for sync.
    @MainActor
    func enqueueCreate(_ request: CreatePhoneCallRequest) throws -> String {
        let itemId = try syncEngine.enqueue(
            endpointPath: "/activities/phone-calls",
            httpMethod: "POST",
            body: request,
            conflictStrategy: .union // Phone call logs use union merge
        )
        logger.debug("Enqueued phone call creation for sync: \(itemId)")
        return itemId
    }

    /// Enqueue a phone call update for sync.
    @MainActor
    func enqueueUpdate(callId: String, _ request: UpdatePhoneCallRequest) throws -> String {
        let itemId = try syncEngine.enqueue(
            endpointPath: "/activities/phone-calls/\(callId)",
            httpMethod: "PATCH",
            body: request,
            conflictStrategy: .lastWriteWins
        )
        logger.debug("Enqueued phone call update for sync: \(itemId)")
        return itemId
    }

    /// Enqueue a phone call deletion for sync.
    @MainActor
    func enqueueDelete(callId: String) throws -> String {
        let itemId = try syncEngine.enqueue(
            endpointPath: "/activities/phone-calls/\(callId)",
            httpMethod: "DELETE",
            conflictStrategy: .lastWriteWins
        )
        logger.debug("Enqueued phone call deletion for sync: \(itemId)")
        return itemId
    }

    /// Enqueue a saved contact creation for sync.
    @MainActor
    func enqueueCreateSavedContact(_ request: CreateSavedContactAPIRequest) throws -> String {
        let itemId = try syncEngine.enqueue(
            endpointPath: "/activities/phone-calls/saved-contacts",
            httpMethod: "POST",
            body: request,
            conflictStrategy: .lastWriteWins // Saved contacts use LWW
        )
        logger.debug("Enqueued saved contact creation for sync: \(itemId)")
        return itemId
    }

    /// Enqueue a saved contact deletion for sync.
    @MainActor
    func enqueueDeleteSavedContact(savedContactId: String) throws -> String {
        let itemId = try syncEngine.enqueue(
            endpointPath: "/activities/phone-calls/saved-contacts/\(savedContactId)",
            httpMethod: "DELETE",
            conflictStrategy: .lastWriteWins
        )
        logger.debug("Enqueued saved contact deletion for sync: \(itemId)")
        return itemId
    }
}
