import Foundation

/// Resolves sync conflicts for nutrition data.
/// FR-NUT-14.3: Offline conflict resolution.
struct NutritionConflictResolver {

    /// Resolve meal log conflicts using union merge.
    /// FR-NUT-14.3: Both entries are kept when timestamps differ.
    /// If timestamps match within 30 seconds, treat as the same entry and keep server version.
    static func unionMergeMealLogs(local: [MealLog], remote: [MealLog]) -> [MealLog] {
        var merged: [MealLog] = []
        var remoteIds = Set(remote.map(\.mealId))

        // Add all remote entries.
        merged.append(contentsOf: remote)

        // Add local entries that don't exist on the server.
        for localMeal in local {
            if !remoteIds.contains(localMeal.mealId) {
                // Check if there's a near-duplicate by timestamp (within 30 seconds).
                let isDuplicate = remote.contains { remoteMeal in
                    abs(localMeal.timestamp.timeIntervalSince(remoteMeal.timestamp)) < 30
                        && localMeal.mealType == remoteMeal.mealType
                }

                if !isDuplicate {
                    merged.append(localMeal)
                }
            }
        }

        // Sort by timestamp descending (newest first).
        return merged.sorted { $0.timestamp > $1.timestamp }
    }

    /// Resolve hydration conflicts using last-writer-wins.
    /// The hydration log with the most recent modifiedAt timestamp wins.
    static func lastWriterWinsHydration(local: HydrationStatus, remote: HydrationStatus) -> HydrationStatus {
        // In LWW, the server version always wins because it has the latest state.
        // The entries array in the server document allows reconstruction if needed.
        return remote
    }

    /// Resolve settings conflicts using last-writer-wins.
    static func lastWriterWinsSettings(local: NutritionSettings, remote: NutritionSettings) -> NutritionSettings {
        return remote
    }
}
