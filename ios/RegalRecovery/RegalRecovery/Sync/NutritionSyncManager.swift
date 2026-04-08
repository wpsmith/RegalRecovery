import Foundation

/// Manages offline sync for nutrition data.
/// Meal logs use union merge (both entries kept on conflict).
/// Hydration uses last-writer-wins at the daily document level.
/// FR-NUT-14.1: Offline meal logging.
/// FR-NUT-14.2: Offline hydration logging.
final class NutritionSyncManager: @unchecked Sendable {

    private let syncEngine: SyncEngine

    init(syncEngine: SyncEngine) {
        self.syncEngine = syncEngine
    }

    /// Enqueue a meal log creation for offline sync.
    /// FR-NUT-14.1: Entry saved locally and synced when connection is restored.
    @MainActor
    func enqueueMealLog(_ meal: CreateMealLogRequest) throws {
        try syncEngine.enqueue(
            endpointPath: "/activities/nutrition/meals",
            httpMethod: "POST",
            body: meal,
            conflictStrategy: .union // FR-NUT-14.3: Union merge for meal logs.
        )
    }

    /// Enqueue a quick meal log for offline sync.
    @MainActor
    func enqueueQuickLog(_ request: CreateQuickMealLogRequest) throws {
        try syncEngine.enqueue(
            endpointPath: "/activities/nutrition/meals/quick",
            httpMethod: "POST",
            body: request,
            conflictStrategy: .union
        )
    }

    /// Enqueue a meal log update for offline sync.
    @MainActor
    func enqueueMealUpdate(mealId: String, _ request: UpdateMealLogRequest) throws {
        try syncEngine.enqueue(
            endpointPath: "/activities/nutrition/meals/\(mealId)",
            httpMethod: "PATCH",
            body: request,
            conflictStrategy: .lastWriteWins
        )
    }

    /// Enqueue a hydration log for offline sync.
    /// FR-NUT-14.2: Hydration count incremented locally and synced.
    @MainActor
    func enqueueHydrationLog(_ request: LogHydrationRequest) throws {
        try syncEngine.enqueue(
            endpointPath: "/activities/nutrition/hydration/log",
            httpMethod: "POST",
            body: request,
            conflictStrategy: .lastWriteWins // Hydration uses LWW at daily level.
        )
    }

    /// Enqueue a settings update for offline sync.
    @MainActor
    func enqueueSettingsUpdate(_ body: [String: Any]) throws {
        // Settings always use last-writer-wins.
        try syncEngine.enqueue(
            endpointPath: "/activities/nutrition/settings",
            httpMethod: "PATCH",
            conflictStrategy: .lastWriteWins
        )
    }
}
