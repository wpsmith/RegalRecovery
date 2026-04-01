import Foundation

@Observable
class GoalViewModel {

    // MARK: - State

    var goals: [WeeklyGoal] = []
    var isLoading = false
    var error: String?

    // New goal state
    var newGoalTitle: String = ""
    var newGoalDynamic: String = "Spiritual"

    static let dynamics = ["Spiritual", "Physical", "Emotional", "Intellectual", "Relational"]

    // MARK: - Computed

    var completionCount: Int { goals.filter(\.isComplete).count }
    var totalCount: Int { goals.count }

    var completionPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completionCount) / Double(totalCount)
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            goals = try await loadFromStorage()
        } catch {
            goals = MockData.weeklyGoals
            self.error = error.localizedDescription
        }
    }

    // MARK: - Toggle

    func toggleGoal(_ goal: WeeklyGoal) async throws {
        guard let index = goals.firstIndex(where: { $0.id == goal.id }) else {
            throw ActivityError.validationFailed("Goal not found.")
        }

        // TODO: Replace with repository save
        let current = goals[index]
        let toggled = WeeklyGoal(
            title: current.title,
            dynamic: current.dynamic,
            isComplete: !current.isComplete
        )
        goals[index] = toggled
    }

    // MARK: - Add Goal

    func addGoal(title: String, dynamic: String) async throws {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ActivityError.validationFailed("Goal title is required.")
        }

        let goal = WeeklyGoal(
            title: title,
            dynamic: dynamic,
            isComplete: false
        )

        // TODO: Replace with repository save
        goals.append(goal)
        newGoalTitle = ""
        newGoalDynamic = "Spiritual"
    }

    // MARK: - Private

    private func loadFromStorage() async throws -> [WeeklyGoal] {
        throw ActivityError.notImplemented
    }
}
