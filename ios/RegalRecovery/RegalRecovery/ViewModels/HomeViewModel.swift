import SwiftUI
import SwiftData

@Observable
class HomeViewModel {
    var streak: StreakData?
    var commitmentStatus: CommitmentStatus?
    var recentActivity: [RecentActivity] = []
    var milestones: [Milestone] = []
    var motivations: [String] = []
    var isLoading = false
    var error: String?

    // MARK: - Loading

    /// Load home data from a SwiftData ModelContext.
    func load(context: ModelContext) async {
        isLoading = true
        error = nil

        do {
            try await loadFromSwiftData(context: context)
        } catch {
            self.error = "Unable to load home data. Please try again."
        }

        isLoading = false
    }

    func refreshStreak(context: ModelContext) async {
        let descriptor = FetchDescriptor<RRStreak>()
        guard let rrStreak = try? context.fetch(descriptor).first else { return }
        let currentDays = rrStreak.currentDays
        let sobrietyDate = rrStreak.addiction?.sobrietyDate ?? Date()
        let nextMilestone = StreakViewModel.milestoneThresholds.first(where: { $0 > currentDays }) ?? ((currentDays / 365) + 1) * 365

        let milestoneDescriptor = FetchDescriptor<RRMilestone>(sortBy: [SortDescriptor(\.days)])
        let rrMilestones = (try? context.fetch(milestoneDescriptor)) ?? []

        streak = StreakData(
            currentDays: currentDays,
            sobrietyDate: sobrietyDate,
            longestStreak: rrStreak.longestStreak,
            totalRelapses: rrStreak.totalRelapses,
            nextMilestoneDays: nextMilestone,
            milestones: rrMilestones.map { Milestone(days: $0.days, dateEarned: $0.dateEarned, scripture: $0.scripture) }
        )
    }

    // MARK: - Private

    private func loadFromSwiftData(context: ModelContext) async throws {
        // User
        let userDescriptor = FetchDescriptor<RRUser>()
        let user = try context.fetch(userDescriptor).first
        motivations = user?.motivations ?? []

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
            milestones = streak?.milestones ?? []
        }

        // Commitments for today
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart)!
        let commitmentDescriptor = FetchDescriptor<RRCommitment>(
            predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrowStart }
        )
        let todayCommitments = (try? context.fetch(commitmentDescriptor)) ?? []
        let morning = todayCommitments.first(where: { $0.type == "morning" })
        let evening = todayCommitments.first(where: { $0.type == "evening" })
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        commitmentStatus = CommitmentStatus(
            morningComplete: morning?.completedAt != nil,
            morningTime: morning?.completedAt.map { timeFormatter.string(from: $0) },
            eveningComplete: evening?.completedAt != nil,
            eveningTime: evening?.completedAt.map { timeFormatter.string(from: $0) }
        )

        // Recent activity
        let activityDescriptor = FetchDescriptor<RRActivity>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let allActivities = try context.fetch(activityDescriptor)
        let relFormatter = RelativeDateTimeFormatter()
        relFormatter.unitsStyle = .short
        recentActivity = Array(allActivities.prefix(10)).map { activity in
            let activityType = ActivityType(rawValue: activity.activityType)
            let summary: String = {
                if case .string(let s) = activity.data.data["summary"] { return s }
                return ""
            }()
            return RecentActivity(
                title: activityType?.rawValue ?? activity.activityType.capitalized,
                detail: summary,
                time: relFormatter.localizedString(for: activity.timestamp, relativeTo: Date()),
                icon: activityType?.icon ?? "circle.fill",
                iconColor: activityType?.iconColor ?? .rrPrimary
            )
        }
    }
}
