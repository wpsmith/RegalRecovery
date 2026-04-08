import Foundation

// MARK: - Enums

enum MealType: String, Codable, CaseIterable, Sendable {
    case breakfast
    case lunch
    case dinner
    case snack
    case other
}

enum EatingContext: String, Codable, CaseIterable, Sendable {
    case homemade
    case takeout
    case onTheGo = "on-the-go"
    case mealPrepped = "meal-prepped"
    case skipped
    case social
    case alone
}

enum MindfulnessCheck: String, Codable, CaseIterable, Sendable {
    case yes
    case somewhat
    case no
}

enum NutritionCompleteness: String, Codable, Sendable {
    case green
    case yellow
    case gray
}

enum HydrationAction: String, Codable, Sendable {
    case add
    case remove
}

enum TrendDirection: String, Codable, Sendable {
    case improving
    case stable
    case declining
}

enum InsightType: String, Codable, Sendable {
    case gapDetection = "gap-detection"
    case mealConsistency = "meal-consistency"
    case emotionalEating = "emotional-eating"
    case mindfulness
    case hydration
    case crossDomain = "cross-domain"
}

enum InsightSeverity: String, Codable, Sendable {
    case info
    case attention
}

// MARK: - Meal Log

struct MealLog: Codable, Identifiable, Sendable {
    let mealId: String
    let timestamp: Date
    let mealType: MealType
    let customMealLabel: String?
    let description: String?
    let eatingContext: EatingContext?
    let moodBefore: Int?
    let moodAfter: Int?
    let mindfulnessCheck: MindfulnessCheck?
    let notes: String?
    let isQuickLog: Bool
    let links: [String: String]?

    var id: String { mealId }
}

struct CreateMealLogRequest: Codable, Sendable {
    let timestamp: Date?
    let mealType: MealType
    let customMealLabel: String?
    let description: String
    let eatingContext: EatingContext?
    let moodBefore: Int?
    let moodAfter: Int?
    let mindfulnessCheck: MindfulnessCheck?
    let notes: String?
}

struct UpdateMealLogRequest: Codable, Sendable {
    let description: String?
    let eatingContext: EatingContext?
    let moodBefore: Int?
    let moodAfter: Int?
    let mindfulnessCheck: MindfulnessCheck?
    let notes: String?
}

struct CreateQuickMealLogRequest: Codable, Sendable {
    let mealType: MealType
    let customMealLabel: String?
}

// MARK: - Hydration

struct HydrationStatus: Codable, Sendable {
    let date: String
    let servingsLogged: Int
    let totalOunces: Double
    let servingSizeOz: Double
    let dailyTargetServings: Int
    let dailyTargetOunces: Double?
    let goalMet: Bool
    let goalProgressPercent: Int
}

struct LogHydrationRequest: Codable, Sendable {
    let action: HydrationAction
    let servings: Int
    let timestamp: Date?
}

struct HydrationDay: Codable, Sendable {
    let date: String
    let servingsLogged: Int
    let totalOunces: Double
    let goalMet: Bool
    let servingSizeOz: Double
}

// MARK: - Calendar

struct NutritionCalendarDay: Codable, Sendable {
    let date: String
    let mealsLogged: Int
    let mealTypes: [MealType]
    let hydrationGoalMet: Bool
    let completeness: NutritionCompleteness
}

struct NutritionCalendarData: Codable, Sendable {
    let year: Int
    let month: Int
    let days: [NutritionCalendarDay]
}

// MARK: - Trends

struct MealConsistencyTrend: Codable, Sendable {
    let dailyMealCounts: [DailyMealCount]?
    let averageMealsPerDay: Double
    let mealTypePercentages: [String: Double]?
}

struct DailyMealCount: Codable, Sendable {
    let date: String
    let total: Int
    let breakfast: Int?
    let lunch: Int?
    let dinner: Int?
    let snack: Int?
    let other: Int?
}

struct EatingContextTrend: Codable, Sendable {
    let distribution: [String: Double]?
    let socialEatingCount: Int?
}

struct EmotionalEatingTrend: Codable, Sendable {
    let averageMoodBefore: Double?
    let averageMoodAfter: Double?
    let moodImprovementPercent: Double?
}

struct MindfulnessTrend: Codable, Sendable {
    let mindfulPercent: Double
    let somewhatPercent: Double
    let distractedPercent: Double
    let trendDirection: TrendDirection?
}

struct HydrationTrend: Codable, Sendable {
    let averageDailyOunces: Double
    let daysGoalMet: Int
    let totalDays: Int
    let dailyIntake: [DailyHydrationIntake]?
}

struct DailyHydrationIntake: Codable, Sendable {
    let date: String
    let totalOunces: Double
    let goalMet: Bool
}

struct Insight: Codable, Identifiable, Sendable {
    let insightId: String
    let type: InsightType
    let message: String
    let severity: InsightSeverity

    var id: String { insightId }
}

struct NutritionTrendsData: Codable, Sendable {
    let period: String
    let mealConsistency: MealConsistencyTrend?
    let eatingContext: EatingContextTrend?
    let emotionalEating: EmotionalEatingTrend?
    let mindfulness: MindfulnessTrend?
    let hydration: HydrationTrend?
    let insights: [Insight]?
}

// MARK: - Weekly Summary

struct WeekSummary: Codable, Sendable {
    let mealsLogged: Int
    let averageMealsPerDay: Double
    let hydrationGoalMetDays: Int
    let mostCommonContext: String?
    let mindfulMealPercent: Double
}

struct WeeklyComparison: Codable, Sendable {
    let mealsLoggedDelta: Int
    let hydrationDelta: Int
    let direction: TrendDirection
}

struct WeeklySummaryData: Codable, Sendable {
    let currentWeek: WeekSummary
    let previousWeek: WeekSummary
    let comparison: WeeklyComparison
}

// MARK: - Settings

struct MealReminderSetting: Codable, Sendable {
    var enabled: Bool
    var time: String
}

struct NutritionSettings: Codable, Sendable {
    var hydration: HydrationSettings
    var mealReminders: MealReminders
    var hydrationReminders: HydrationReminderSettings
    var missedMealNudge: MissedMealNudgeSetting
    var insightPreferences: InsightPreferences

    struct HydrationSettings: Codable, Sendable {
        var servingSizeOz: Double
        var dailyTargetServings: Int
    }

    struct MealReminders: Codable, Sendable {
        var breakfast: MealReminderSetting
        var lunch: MealReminderSetting
        var dinner: MealReminderSetting
    }

    struct HydrationReminderSettings: Codable, Sendable {
        var enabled: Bool
        var intervalHours: Int
    }

    struct MissedMealNudgeSetting: Codable, Sendable {
        var enabled: Bool
        var nudgeTime: String
    }

    struct InsightPreferences: Codable, Sendable {
        var mealConsistencyEnabled: Bool
        var emotionalEatingEnabled: Bool
        var mindfulnessEnabled: Bool
        var crossDomainEnabled: Bool
    }

    static var defaults: NutritionSettings {
        NutritionSettings(
            hydration: .init(servingSizeOz: 8, dailyTargetServings: 8),
            mealReminders: .init(
                breakfast: .init(enabled: false, time: "08:00"),
                lunch: .init(enabled: false, time: "12:00"),
                dinner: .init(enabled: false, time: "18:00")
            ),
            hydrationReminders: .init(enabled: false, intervalHours: 2),
            missedMealNudge: .init(enabled: false, nudgeTime: "14:00"),
            insightPreferences: .init(
                mealConsistencyEnabled: true,
                emotionalEatingEnabled: true,
                mindfulnessEnabled: true,
                crossDomainEnabled: true
            )
        )
    }
}
