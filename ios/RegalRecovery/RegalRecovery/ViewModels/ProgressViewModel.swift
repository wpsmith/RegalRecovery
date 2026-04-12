import SwiftUI
import SwiftData

@Observable
class ProgressViewModel {
    var streak: StreakData?
    var fasterScaleMode: String = "Green"
    var moodAverage: Double = 0
    var weeklyActivityCount: Int = 0
    var activityStreaks: [(name: String, days: Int, completion: Double)] = []
    var monthlyStats: [(name: String, count: Int, trend: String)] = []
    var stepProgress: (current: Int, total: Int) = (0, 12)
    var isLoading = false
    var error: String?

    // MARK: - Loading

    func load(context: ModelContext) async {
        isLoading = true
        error = nil

        do {
            try await loadFromSwiftData(context: context)
        } catch {
            self.error = "Unable to load progress data. Please try again."
        }

        isLoading = false
    }

    // MARK: - Private

    private func loadFromSwiftData(context: ModelContext) async throws {
        // Streak
        let streakDescriptor = FetchDescriptor<RRStreak>()
        if let rrStreak = try context.fetch(streakDescriptor).first {
            let currentDays = rrStreak.currentDays
            let sobrietyDate = rrStreak.addiction?.sobrietyDate ?? Date()
            let nextMilestone = StreakViewModel.milestoneThresholds.first(where: { $0 > currentDays }) ?? ((currentDays / 365) + 1) * 365

            let milestoneDescriptor = FetchDescriptor<RRMilestone>(sortBy: [SortDescriptor(\.days)])
            let rrMilestones = try context.fetch(milestoneDescriptor)

            streak = StreakData(
                currentDays: currentDays,
                sobrietyDate: sobrietyDate,
                longestStreak: rrStreak.longestStreak,
                totalRelapses: rrStreak.totalRelapses,
                nextMilestoneDays: nextMilestone,
                milestones: rrMilestones.map { Milestone(days: $0.days, dateEarned: $0.dateEarned, scripture: $0.scripture) }
            )
        }

        // FASTER Scale mode (latest entry)
        let fasterDescriptor = FetchDescriptor<RRFASTEREntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let fasterEntries = try context.fetch(fasterDescriptor)
        if let latest = fasterEntries.first {
            switch latest.stage {
            case -1, 0:
                fasterScaleMode = "Green"
            case 1, 2:
                fasterScaleMode = "Yellow"
            default:
                fasterScaleMode = "Red"
            }
        }

        // Weekly activity count
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let activityDescriptor = FetchDescriptor<RRActivity>(
            predicate: #Predicate { $0.timestamp >= weekAgo },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let weekActivities = try context.fetch(activityDescriptor)
        weeklyActivityCount = weekActivities.count

        // Step progress
        let stepDescriptor = FetchDescriptor<RRStepWork>()
        let steps = try context.fetch(stepDescriptor)
        let completedSteps = steps.filter { $0.status == "complete" }.count
        stepProgress = (current: completedSteps, total: 12)
    }
}
