import Foundation
import Observation
import OSLog

/// ViewModel managing a single circle set: loading, item CRUD, version history,
/// sponsor share generation, and comment management.
@Observable
final class CircleSetDetailViewModel {

    // MARK: - Published State

    /// The loaded circle set detail (includes version history summary and comment count).
    var circleSetDetail: CircleSetDetail?

    /// Items grouped by circle for the Items tab.
    var innerItems: [CircleItem] { circleSetDetail?.innerCircle ?? [] }
    var middleItems: [CircleItem] { circleSetDetail?.middleCircle ?? [] }
    var outerItems: [CircleItem] { circleSetDetail?.outerCircle ?? [] }

    /// Version history list.
    var versions: [VersionListItem] = []

    /// Full version snapshot when viewing a single version.
    var selectedVersionSnapshot: CircleSetVersion?

    /// Sponsor share data.
    var shareData: ShareLinkData?

    /// Sponsor comments.
    var comments: [SponsorComment] = []

    /// Unread comment count (comments newer than last viewed).
    var unreadCommentCount: Int = 0

    /// Loading / error state.
    var isLoading = false
    var isPerformingAction = false
    var error: String?
    var actionError: String?

    /// Confirmation dialogs.
    var showDeleteItemConfirmation = false
    var showRestoreConfirmation = false
    var showArchiveConfirmation = false
    var showInnerCircleAdvisory = false

    /// Item pending deletion (for confirmation flow).
    var itemPendingDeletion: CircleItem?

    /// Version pending restore.
    var versionPendingRestore: VersionListItem?

    // MARK: - Dependencies

    private let apiClient: ThreeCirclesAPIClient
    private let setId: String
    private let logger = Logger(subsystem: "com.regalrecovery.app", category: "CircleSetDetail")

    // MARK: - Init

    init(apiClient: ThreeCirclesAPIClient, setId: String) {
        self.apiClient = apiClient
        self.setId = setId
    }

    // MARK: - Load Circle Set

    /// Loads the circle set detail from the API.
    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let response = try await apiClient.getCircleSet(setId: setId)
            circleSetDetail = response.data
        } catch {
            logger.error("Failed to load circle set: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
    }

    // MARK: - Item Management

    /// Add a new item to a circle.
    func addItem(request: CreateCircleItemRequest) async {
        isPerformingAction = true
        actionError = nil
        defer { isPerformingAction = false }

        do {
            _ = try await apiClient.addCircleItem(setId: setId, request: request)
            await load()
        } catch {
            logger.error("Failed to add item: \(error.localizedDescription)")
            actionError = error.localizedDescription
        }
    }

    /// Update an existing item.
    func updateItem(itemId: String, request: UpdateCircleItemRequest) async {
        isPerformingAction = true
        actionError = nil
        defer { isPerformingAction = false }

        do {
            _ = try await apiClient.updateCircleItem(setId: setId, itemId: itemId, request: request)
            await load()
        } catch {
            logger.error("Failed to update item: \(error.localizedDescription)")
            actionError = error.localizedDescription
        }
    }

    /// Delete an item. For inner circle items, requires extra confirmation.
    func deleteItem(_ item: CircleItem) async {
        isPerformingAction = true
        actionError = nil
        defer { isPerformingAction = false }

        do {
            try await apiClient.deleteCircleItem(setId: setId, itemId: item.itemId)
            await load()
        } catch {
            logger.error("Failed to delete item: \(error.localizedDescription)")
            actionError = error.localizedDescription
        }
    }

    /// Confirm deletion of the pending item.
    func confirmDeleteItem() async {
        guard let item = itemPendingDeletion else { return }
        await deleteItem(item)
        itemPendingDeletion = nil
    }

    /// Request deletion with confirmation for inner circle items.
    func requestDeleteItem(_ item: CircleItem) {
        itemPendingDeletion = item
        showDeleteItemConfirmation = true
    }

    /// Move an item to a different circle.
    func moveItem(itemId: String, to targetCircle: CircleType, changeNote: String? = nil) async {
        isPerformingAction = true
        actionError = nil
        defer { isPerformingAction = false }

        do {
            let request = MoveItemRequest(targetCircle: targetCircle, changeNote: changeNote)
            _ = try await apiClient.moveCircleItem(setId: setId, itemId: itemId, request: request)
            await load()
        } catch {
            logger.error("Failed to move item: \(error.localizedDescription)")
            actionError = error.localizedDescription
        }
    }

    // MARK: - Circle Set Actions

    /// Archive the circle set (soft delete).
    func archive() async {
        isPerformingAction = true
        actionError = nil
        defer { isPerformingAction = false }

        do {
            try await apiClient.deleteCircleSet(setId: setId)
            await load()
        } catch {
            logger.error("Failed to archive circle set: \(error.localizedDescription)")
            actionError = error.localizedDescription
        }
    }

    /// Update circle set metadata (name, status, framework).
    func updateSet(request: UpdateCircleSetRequest) async {
        isPerformingAction = true
        actionError = nil
        defer { isPerformingAction = false }

        do {
            _ = try await apiClient.updateCircleSet(setId: setId, request: request)
            await load()
        } catch {
            logger.error("Failed to update circle set: \(error.localizedDescription)")
            actionError = error.localizedDescription
        }
    }

    /// Commit a draft circle set to active.
    func commit(changeNote: String? = nil) async {
        isPerformingAction = true
        actionError = nil
        defer { isPerformingAction = false }

        do {
            let request = CommitCircleSetRequest(changeNote: changeNote)
            _ = try await apiClient.commitCircleSet(setId: setId, request: request)
            await load()
        } catch {
            logger.error("Failed to commit circle set: \(error.localizedDescription)")
            actionError = error.localizedDescription
        }
    }

    // MARK: - Version History

    /// Load the version history list.
    func loadVersions() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let response = try await apiClient.listVersions(setId: setId)
            versions = response.data
        } catch {
            logger.error("Failed to load versions: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
    }

    /// Load a specific version snapshot.
    func loadVersionSnapshot(versionNumber: Int) async {
        isPerformingAction = true
        actionError = nil
        defer { isPerformingAction = false }

        do {
            let response = try await apiClient.getVersion(setId: setId, versionId: String(versionNumber))
            selectedVersionSnapshot = response.data
        } catch {
            logger.error("Failed to load version snapshot: \(error.localizedDescription)")
            actionError = error.localizedDescription
        }
    }

    /// Restore to a specific version.
    func restoreVersion(_ version: VersionListItem, changeNote: String? = nil) async {
        isPerformingAction = true
        actionError = nil
        defer { isPerformingAction = false }

        do {
            let request = RestoreVersionRequest(changeNote: changeNote)
            _ = try await apiClient.restoreVersion(
                setId: setId,
                versionId: String(version.versionNumber),
                request: request
            )
            await load()
            await loadVersions()
        } catch {
            logger.error("Failed to restore version: \(error.localizedDescription)")
            actionError = error.localizedDescription
        }
    }

    /// Request version restore with confirmation.
    func requestRestoreVersion(_ version: VersionListItem) {
        versionPendingRestore = version
        showRestoreConfirmation = true
    }

    /// Confirm the pending version restore.
    func confirmRestoreVersion() async {
        guard let version = versionPendingRestore else { return }
        await restoreVersion(version)
        versionPendingRestore = nil
    }

    // MARK: - Sponsor Share

    /// Generate a share link for sponsor review.
    func generateShareLink(
        expiresIn: ShareExpiry? = nil,
        permissions: [SharePermission]? = nil
    ) async {
        isPerformingAction = true
        actionError = nil
        defer { isPerformingAction = false }

        do {
            let request = CreateShareLinkRequest(expiresIn: expiresIn, permissions: permissions)
            let response = try await apiClient.shareCircleSet(setId: setId, request: request)
            shareData = response.data
        } catch {
            logger.error("Failed to generate share link: \(error.localizedDescription)")
            actionError = error.localizedDescription
        }
    }

    // MARK: - Comments

    /// Load sponsor/therapist comments.
    func loadComments() async {
        do {
            let response = try await apiClient.getComments(setId: setId)
            comments = response.data
            updateUnreadCount()
        } catch {
            logger.error("Failed to load comments: \(error.localizedDescription)")
        }
    }

    /// Update the unread comment count based on last-viewed timestamp.
    private func updateUnreadCount() {
        let lastViewedKey = "lastViewedComments_\(setId)"
        let lastViewed = UserDefaults.standard.object(forKey: lastViewedKey) as? Date ?? .distantPast
        unreadCommentCount = comments.filter { $0.createdAt > lastViewed }.count
    }

    /// Mark all comments as read.
    func markCommentsAsRead() {
        let lastViewedKey = "lastViewedComments_\(setId)"
        UserDefaults.standard.set(Date(), forKey: lastViewedKey)
        unreadCommentCount = 0
    }

    // MARK: - Guardrail Checks

    /// Returns true if the inner circle has at least one item (required for commit).
    var canCommit: Bool {
        !innerItems.isEmpty
    }

    /// Total item count across all circles.
    var totalItemCount: Int {
        innerItems.count + middleItems.count + outerItems.count
    }

    /// Whether adding to the inner circle requires an advisory.
    var isAddingToInnerCircle: Bool {
        showInnerCircleAdvisory
    }

    // MARK: - Helpers

    /// Find an item by ID across all circles.
    func findItem(by itemId: String) -> CircleItem? {
        let allItems = innerItems + middleItems + outerItems
        return allItems.first { $0.itemId == itemId }
    }

    /// Determine which circle an item belongs to.
    func circleForItem(_ itemId: String) -> CircleType? {
        if innerItems.contains(where: { $0.itemId == itemId }) { return .inner }
        if middleItems.contains(where: { $0.itemId == itemId }) { return .middle }
        if outerItems.contains(where: { $0.itemId == itemId }) { return .outer }
        return nil
    }
}
