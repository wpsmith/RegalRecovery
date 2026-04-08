import Foundation
import SwiftUI

/// ViewModel for the Weekly/Daily Goals feature.
/// Feature flag: `activity.weekly-daily-goals`
@Observable
class WeeklyDailyGoalsViewModel {

    // MARK: - State

    var dailyGoals: [GoalInstance] = []
    var weeklyGoals: [GoalInstance] = []
    var dailySummary: DailyGoalsSummary?
    var weeklySummary: WeeklyGoalsSummary?
    var nudges: [DynamicNudge] = []
    var trendsData: GoalTrendsData?
    var settings: GoalSettings?

    var selectedDate: Date = .now
    var selectedWeekOf: Date = .now
    var isLoading = false
    var error: String?

    // New goal form state
    var newGoalText = ""
    var newGoalDynamics: Set<RecoveryDynamic> = []
    var newGoalScope: GoalScope = .daily
    var newGoalRecurrence: GoalRecurrence = .oneTime
    var newGoalPriority: GoalPriority = .medium
    var newGoalSelectedDays: Set<GoalDayOfWeek> = []
    var newGoalNotes = ""

    // Review state
    var dispositions: [String: DispositionAction] = [:]
    var reviewReflection = ""

    // MARK: - Computed

    var dailyCompletedCount: Int { dailyGoals.filter(\.isCompleted).count }
    var dailyTotalCount: Int { dailyGoals.filter { $0.status != .dismissed }.count }

    var dailyCompletionPercentage: Double {
        guard dailyTotalCount > 0 else { return 0 }
        return Double(dailyCompletedCount) / Double(dailyTotalCount)
    }

    var weeklyCompletedCount: Int { weeklyGoals.filter(\.isCompleted).count }
    var weeklyTotalCount: Int { weeklyGoals.filter { $0.status != .dismissed }.count }

    var weeklyCompletionPercentage: Double {
        guard weeklyTotalCount > 0 else { return 0 }
        return Double(weeklyCompletedCount) / Double(weeklyTotalCount)
    }

    /// Goals grouped by dynamic for the daily view (AC-DV-1).
    var goalsByDynamic: [(dynamic: RecoveryDynamic, goals: [GoalInstance])] {
        var grouped: [RecoveryDynamic: [GoalInstance]] = [:]
        for goal in dailyGoals where goal.status != .dismissed {
            for dynamic in goal.dynamics {
                grouped[dynamic, default: []].append(goal)
            }
        }
        return RecoveryDynamic.allCases.compactMap { dynamic in
            guard let goals = grouped[dynamic], !goals.isEmpty else { return nil }
            let sorted = goals.sorted { GoalPriority.sortOrder($0.priority) < GoalPriority.sortOrder($1.priority) }
            return (dynamic: dynamic, goals: sorted)
        }
    }

    var uncompletedGoals: [GoalInstance] {
        dailyGoals.filter { $0.status == .pending }
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }

    // MARK: - Load Daily Goals

    func loadDailyGoals() async {
        isLoading = true
        defer { isLoading = false }

        // TODO: Replace with API call via GoalsAPIClient when backend is ready.
        // For now, load from mock data.
        dailyGoals = MockGoalData.dailyGoals
        dailySummary = DailyGoalsSummary(
            totalGoals: dailyGoals.filter { $0.status != .dismissed }.count,
            completedGoals: dailyGoals.filter(\.isCompleted).count,
            dynamicBalance: MockGoalData.sampleBalance
        )
        nudges = MockGoalData.sampleNudges
    }

    // MARK: - Load Weekly Goals

    func loadWeeklyGoals() async {
        isLoading = true
        defer { isLoading = false }

        // TODO: Replace with API call.
        weeklyGoals = MockGoalData.weeklyGoals
    }

    // MARK: - Toggle Completion (AC-DV-4, AC-DV-5)

    func toggleGoal(_ goal: GoalInstance) async {
        guard let index = dailyGoals.firstIndex(where: { $0.id == goal.id }) else { return }

        if dailyGoals[index].isCompleted {
            // Uncomplete (AC-DV-5)
            dailyGoals[index].status = .pending
            dailyGoals[index].completedAt = nil
        } else {
            // Complete (AC-DV-4)
            dailyGoals[index].status = .completed
            dailyGoals[index].completedAt = Date()
        }

        // TODO: Call API: completeInstance / uncompleteInstance
    }

    // MARK: - Dismiss Auto-Populated Goal (AC-AP-4)

    func dismissGoal(_ goal: GoalInstance) async {
        guard let index = dailyGoals.firstIndex(where: { $0.id == goal.id }) else { return }
        dailyGoals[index].status = .dismissed

        // TODO: Call API: dismissInstance
    }

    // MARK: - Dismiss Nudge (AC-DN-2)

    func dismissNudge(_ nudge: DynamicNudge) async {
        nudges.removeAll { $0.dynamic == nudge.dynamic }

        // TODO: Call API: dismissNudge
    }

    // MARK: - Add Goal (AC-GC-1)

    func addGoal() async throws {
        let trimmed = newGoalText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ActivityError.validationFailed("Goal text is required.")
        }
        guard trimmed.count <= 200 else {
            throw ActivityError.validationFailed("Goal text must be 200 characters or fewer.")
        }
        guard !newGoalDynamics.isEmpty else {
            throw ActivityError.validationFailed("At least one dynamic is required.")
        }

        let notes: String? = newGoalNotes.isEmpty ? nil : newGoalNotes

        // TODO: Replace with API call via GoalsAPIClient.
        let instance = GoalInstance(
            goalInstanceId: "gi_\(Int(Date().timeIntervalSince1970))",
            goalId: nil,
            text: trimmed,
            dynamics: Array(newGoalDynamics),
            scope: newGoalScope,
            priority: newGoalPriority,
            status: .pending,
            completedAt: nil,
            source: nil,
            sourceId: nil,
            carriedFrom: nil,
            notes: notes,
            date: dateFormatter.string(from: selectedDate),
            dueDay: nil
        )

        dailyGoals.append(instance)
        resetNewGoalForm()
    }

    // MARK: - Submit Daily Review (AC-ED-2 through AC-ED-5)

    func submitDailyReview() async throws {
        let goalDispositions = dispositions.map { (instanceId, action) in
            GoalDisposition(goalInstanceId: instanceId, action: action)
        }

        let reflection: String? = reviewReflection.isEmpty ? nil : reviewReflection

        _ = SubmitDailyReviewRequest(
            date: dateFormatter.string(from: selectedDate),
            dispositions: goalDispositions,
            reflection: reflection
        )

        // TODO: Call API: submitDailyReview

        // Process locally for now.
        for (instanceId, action) in dispositions {
            guard let index = dailyGoals.firstIndex(where: { $0.id == instanceId }) else { continue }
            switch action {
            case .carryToTomorrow:
                dailyGoals[index].status = .carried
            case .skipped, .noLongerRelevant:
                dailyGoals[index].status = .skipped
            }
        }

        dispositions = [:]
        reviewReflection = ""
    }

    // MARK: - Load Trends

    func loadTrends(period: String = "30d") async {
        isLoading = true
        defer { isLoading = false }

        // TODO: Replace with API call.
        trendsData = nil
    }

    // MARK: - Private

    private func resetNewGoalForm() {
        newGoalText = ""
        newGoalDynamics = []
        newGoalScope = .daily
        newGoalRecurrence = .oneTime
        newGoalPriority = .medium
        newGoalSelectedDays = []
        newGoalNotes = ""
    }
}

// MARK: - GoalPriority Sort Helper

private extension GoalPriority {
    static func sortOrder(_ priority: GoalPriority) -> Int {
        priority.sortOrder
    }
}

// MARK: - Mock Data

enum MockGoalData {
    static let dailyGoals: [GoalInstance] = [
        GoalInstance(
            goalInstanceId: "gi_mock_1",
            goalId: "wdg_1",
            text: "Morning prayer and scripture reading",
            dynamics: [.spiritual],
            scope: .daily,
            priority: .high,
            status: .completed,
            completedAt: Date(),
            source: nil,
            sourceId: nil,
            carriedFrom: nil,
            notes: "Read Psalm 51",
            date: "2026-04-07",
            dueDay: nil
        ),
        GoalInstance(
            goalInstanceId: "gi_mock_2",
            goalId: "wdg_2",
            text: "30 minutes of exercise",
            dynamics: [.physical],
            scope: .daily,
            priority: .medium,
            status: .pending,
            completedAt: nil,
            source: nil,
            sourceId: nil,
            carriedFrom: nil,
            notes: nil,
            date: "2026-04-07",
            dueDay: nil
        ),
        GoalInstance(
            goalInstanceId: "gi_mock_3",
            goalId: nil,
            text: "Call sponsor",
            dynamics: [.relational],
            scope: .daily,
            priority: .medium,
            status: .pending,
            completedAt: nil,
            source: .commitment,
            sourceId: "cm_77777",
            carriedFrom: nil,
            notes: nil,
            date: "2026-04-07",
            dueDay: nil
        ),
        GoalInstance(
            goalInstanceId: "gi_mock_4",
            goalId: "wdg_3",
            text: "Journal about emotions",
            dynamics: [.emotional],
            scope: .daily,
            priority: .medium,
            status: .completed,
            completedAt: Date(),
            source: nil,
            sourceId: nil,
            carriedFrom: nil,
            notes: nil,
            date: "2026-04-07",
            dueDay: nil
        ),
    ]

    static let weeklyGoals: [GoalInstance] = [
        GoalInstance(
            goalInstanceId: "gi_mock_w1",
            goalId: "wdg_w1",
            text: "Attend 3 meetings this week",
            dynamics: [.relational, .spiritual],
            scope: .weekly,
            priority: .high,
            status: .pending,
            completedAt: nil,
            source: nil,
            sourceId: nil,
            carriedFrom: nil,
            notes: nil,
            date: "2026-04-07",
            dueDay: nil
        ),
    ]

    static let sampleBalance = DynamicBalance(
        spiritual: DynamicCompletionCount(total: 1, completed: 1),
        physical: DynamicCompletionCount(total: 1, completed: 0),
        emotional: DynamicCompletionCount(total: 1, completed: 1),
        intellectual: DynamicCompletionCount(total: 0, completed: 0),
        relational: DynamicCompletionCount(total: 1, completed: 0)
    )

    static let sampleNudges = [
        DynamicNudge(
            dynamic: .intellectual,
            message: "You don't have any intellectual goals today. Would you like to add one?",
            dismissed: false
        ),
    ]
}
