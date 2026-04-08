import Foundation

// MARK: - Five Dynamics

enum RecoveryDynamic: String, Codable, CaseIterable, Identifiable {
    case spiritual
    case physical
    case emotional
    case intellectual
    case relational

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .spiritual: return "hands.and.sparkles.fill"
        case .physical: return "figure.run"
        case .emotional: return "heart.circle.fill"
        case .intellectual: return "brain.head.profile"
        case .relational: return "person.2.fill"
        }
    }
}

// MARK: - Goal Scope & Recurrence

enum GoalScope: String, Codable {
    case daily
    case weekly
}

enum GoalRecurrence: String, Codable {
    case oneTime = "one-time"
    case daily
    case specificDays = "specific-days"
    case weekly
}

enum GoalPriority: String, Codable, CaseIterable {
    case high
    case medium
    case low

    var sortOrder: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }
}

enum GoalInstanceStatus: String, Codable {
    case pending
    case completed
    case skipped
    case dismissed
    case carried
}

enum GoalDayOfWeek: String, Codable, CaseIterable, Identifiable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
    var shortName: String { String(rawValue.prefix(3)).capitalized }
}

enum DispositionAction: String, Codable {
    case carryToTomorrow = "carry-to-tomorrow"
    case skipped
    case noLongerRelevant = "no-longer-relevant"
}

enum GoalSource: String, Codable {
    case commitment
    case activity
    case postMortem = "post-mortem"
}

// MARK: - Goal Definition (Template)

struct WeeklyDailyGoalDefinition: Identifiable, Codable {
    let goalId: String
    let text: String
    let dynamics: [RecoveryDynamic]
    let scope: GoalScope
    let recurrence: GoalRecurrence
    let daysOfWeek: [GoalDayOfWeek]?
    let dayOfWeek: GoalDayOfWeek?
    let priority: GoalPriority
    let notes: String?
    let isActive: Bool
    let createdAt: Date
    var links: [String: String]?

    var id: String { goalId }
}

// MARK: - Goal Instance (Materialized for a date)

struct GoalInstance: Identifiable, Codable {
    let goalInstanceId: String
    let goalId: String?
    let text: String
    let dynamics: [RecoveryDynamic]
    let scope: GoalScope
    let priority: GoalPriority
    var status: GoalInstanceStatus
    var completedAt: Date?
    let source: GoalSource?
    let sourceId: String?
    let carriedFrom: String?
    let notes: String?
    let date: String
    let dueDay: GoalDayOfWeek?
    var links: [String: String]?

    var id: String { goalInstanceId }

    var isAutoPopulated: Bool { source != nil }
    var isCompleted: Bool { status == .completed }
    var isPending: Bool { status == .pending }
}

// MARK: - Dynamic Balance

struct DynamicCompletionCount: Codable {
    let total: Int
    let completed: Int
    var completionRate: Double?
}

struct DynamicBalance: Codable {
    let spiritual: DynamicCompletionCount
    let physical: DynamicCompletionCount
    let emotional: DynamicCompletionCount
    let intellectual: DynamicCompletionCount
    let relational: DynamicCompletionCount

    func count(for dynamic: RecoveryDynamic) -> DynamicCompletionCount {
        switch dynamic {
        case .spiritual: return spiritual
        case .physical: return physical
        case .emotional: return emotional
        case .intellectual: return intellectual
        case .relational: return relational
        }
    }
}

// MARK: - Nudge

struct DynamicNudge: Identifiable, Codable {
    let dynamic: RecoveryDynamic
    let message: String
    let dismissed: Bool

    var id: String { dynamic.rawValue }
}

// MARK: - Daily Goals Response

struct DailyGoalsSummary: Codable {
    let totalGoals: Int
    let completedGoals: Int
    let dynamicBalance: DynamicBalance
}

struct DailyGoalsData: Codable {
    let date: String
    let goals: [GoalInstance]
    let summary: DailyGoalsSummary
    let nudges: [DynamicNudge]?
}

// MARK: - Weekly Goals Response

struct WeeklyGoalsSummary: Codable {
    let totalGoals: Int
    let completedGoals: Int
    let completionRate: Double
    let dynamicBalance: DynamicBalance
}

struct WeeklyGoalsData: Codable {
    let weekStart: String
    let weekEnd: String
    let goals: [GoalInstance]
    let summary: WeeklyGoalsSummary
}

// MARK: - Review Types

struct GoalDisposition: Codable {
    let goalInstanceId: String
    let action: DispositionAction
}

struct DailyReviewSummary: Codable {
    let totalGoals: Int
    let completedGoals: Int
    let carriedGoals: Int
    let skippedGoals: Int
    let dynamicBalance: DynamicBalance
}

// MARK: - Goal Settings

struct GoalNotificationSettings: Codable {
    var morningEnabled: Bool
    var morningTime: String
    var middayEnabled: Bool
    var eveningEnabled: Bool
    var eveningTime: String
    var weeklyEnabled: Bool
    var weeklyReviewDay: GoalDayOfWeek
    var dynamicGapEnabled: Bool
}

struct GoalSettings: Codable {
    var autoPopulateCommitments: Bool
    var autoPopulateActivities: Bool
    var autoPopulateCommitmentIds: [String]
    var autoPopulateActivityTypes: [String]
    var nudgesEnabled: Bool
    var nudgesDisabledDynamics: [RecoveryDynamic]
    var notifications: GoalNotificationSettings
}

// MARK: - Trends

struct DailyCompletionRate: Codable, Identifiable {
    let date: String
    let completionRate: Double
    let totalGoals: Int?
    let completedGoals: Int?

    var id: String { date }
}

struct GoalStreaks: Codable {
    let allGoalsCompleted: Int
    let weeklyEightyPercent: Int
}

struct GoalTrendsData: Codable {
    let period: String
    let dailyCompletionRates: [DailyCompletionRate]
    let dynamicTrends: [String: [DailyCompletionRate]]?
    let consistencyScore: Double
    let streaks: GoalStreaks
}

// MARK: - Create/Update Requests

struct CreateGoalRequest: Codable {
    let text: String
    let dynamics: [RecoveryDynamic]
    var scope: GoalScope = .daily
    var recurrence: GoalRecurrence = .oneTime
    var daysOfWeek: [GoalDayOfWeek]?
    var dayOfWeek: GoalDayOfWeek?
    var priority: GoalPriority = .medium
    var notes: String?
}

struct SubmitDailyReviewRequest: Codable {
    let date: String
    let dispositions: [GoalDisposition]
    var reflection: String?
}
