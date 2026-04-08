import Foundation

// MARK: - Mood Rating Scale

/// Mood rating values 1-5, matching the OpenAPI spec.
enum MoodRating: Int, Codable, Sendable, CaseIterable {
    case crisis = 1
    case struggling = 2
    case okay = 3
    case good = 4
    case great = 5

    var label: String {
        switch self {
        case .crisis: return "Crisis"
        case .struggling: return "Struggling"
        case .okay: return "Okay"
        case .good: return "Good"
        case .great: return "Great"
        }
    }

    var emoji: String {
        switch self {
        case .crisis: return "\u{1F630}"     // anxious with sweat
        case .struggling: return "\u{1F61F}" // worried
        case .okay: return "\u{1F610}"       // neutral
        case .good: return "\u{1F642}"       // slightly smiling
        case .great: return "\u{1F604}"      // grinning
        }
    }
}

// MARK: - Emotion Labels

/// Predefined emotion labels matching the OpenAPI enum.
enum EmotionLabel: String, Codable, Sendable, CaseIterable {
    // Positive cluster
    case peaceful = "Peaceful"
    case grateful = "Grateful"
    case hopeful = "Hopeful"
    case confident = "Confident"
    case connected = "Connected"
    // Anxious cluster
    case anxious = "Anxious"
    case lonely = "Lonely"
    case angry = "Angry"
    case ashamed = "Ashamed"
    case overwhelmed = "Overwhelmed"
    // Low cluster
    case sad = "Sad"
    case numb = "Numb"
    case restless = "Restless"
    case afraid = "Afraid"
    case frustrated = "Frustrated"
}

// MARK: - Entry Source

/// Source of the mood entry, matching the OpenAPI enum.
enum MoodEntrySource: String, Codable, Sendable {
    case direct = "direct"
    case widget = "widget"
    case postActivity = "post-activity"
    case notification = "notification"
}

// MARK: - Request Models

/// Request body for POST /activities/mood (createMoodEntry).
struct CreateMoodEntryRequest: Codable, Sendable {
    let timestamp: Date
    let rating: Int
    let emotionLabels: [String]?
    let contextNote: String?
    let source: String?
}

/// Request body for PATCH /activities/mood/{moodId} (updateMoodEntry).
struct UpdateMoodEntryRequest: Codable, Sendable {
    let rating: Int?
    let emotionLabels: [String]?
    let contextNote: String?
}

// MARK: - Response Models

/// Single mood entry data, matching MoodEntry schema.
struct MoodEntryData: Codable, Sendable {
    let moodId: String
    let timestamp: Date
    let rating: Int
    let ratingLabel: String
    let emotionLabels: [String]?
    let contextNote: String?
    let source: String?
    let crisisPrompted: Bool?
    let links: MoodLinks?

    struct MoodLinks: Codable, Sendable {
        let `self`: String?
    }
}

/// Today's mood data, matching MoodTodayResponse.
struct MoodTodayData: Codable, Sendable {
    let entries: [MoodEntryData]
    let summary: MoodDaySummaryData?
    let yesterdayComparison: YesterdayComparisonData?
}

/// Daily summary statistics.
struct MoodDaySummaryData: Codable, Sendable {
    let averageRating: Double
    let averageLabel: String?
    let highestRating: Int
    let lowestRating: Int
    let entryCount: Int
}

/// Yesterday comparison for today's view.
struct YesterdayComparisonData: Codable, Sendable {
    let averageRating: Double?
    let timeOfDayRating: Int?
    let timeOfDayLabel: String?
}

/// Daily summary for calendar view.
struct MoodDailySummaryData: Codable, Sendable {
    let date: String
    let averageRating: Double
    let colorCode: String
    let entryCount: Int
    let highestRating: Int
    let lowestRating: Int
}

/// Calendar color codes.
enum MoodColorCode: String, Codable, Sendable {
    case green
    case yellow
    case orange
    case red
    case gray
}

/// Mood trends response data.
struct MoodTrendsData: Codable, Sendable {
    let dailyAverages: [DailyAverageData]?
    let trendDirection: String?
    let weeklySummary: WeeklySummaryData?
    let monthlySummary: MonthlySummaryData?
    let timeOfDayHeatmap: [HourBucketData]?
    let dayOfWeekPatterns: [DayBucketData]?
    let emotionLabelTrends: [LabelCountData]?
}

struct DailyAverageData: Codable, Sendable {
    let date: String
    let averageRating: Double
    let entryCount: Int
}

struct WeeklySummaryData: Codable, Sendable {
    let averageThisWeek: Double?
    let averageLastWeek: Double?
    let bestDay: String?
    let mostChallengingDay: String?
    let topEmotionLabels: [String]?
    let entryCount: Int?
}

struct MonthlySummaryData: Codable, Sendable {
    let averageThisMonth: Double?
    let distribution: RatingDistributionData?
    let comparedToPreviousMonth: Double?
}

struct RatingDistributionData: Codable, Sendable {
    let great: Double?
    let good: Double?
    let okay: Double?
    let struggling: Double?
    let crisis: Double?
}

struct HourBucketData: Codable, Sendable {
    let hour: Int
    let averageRating: Double
    let entryCount: Int
}

struct DayBucketData: Codable, Sendable {
    let dayOfWeek: Int
    let dayName: String?
    let averageRating: Double
}

struct LabelCountData: Codable, Sendable {
    let label: String
    let count: Int
    let percentageChange: Double?
}

/// Mood correlations response data.
struct MoodCorrelationsData: Codable, Sendable {
    let activities: [ActivityCorrelationData]?
    let urgeCorrelation: UrgeCorrelationData?
}

struct ActivityCorrelationData: Codable, Sendable {
    let activityType: String
    let moodDelta: Double
    let insight: String?
    let dataPoints: Int
}

struct UrgeCorrelationData: Codable, Sendable {
    let averageMoodBeforeUrge: Double?
    let consecutiveLowDayUrgeIncrease: String?
    let insight: String?
}

/// Mood alert status response data.
struct MoodAlertStatusData: Codable, Sendable {
    let sustainedLowMood: Bool
    let consecutiveLowDays: Int
    let lastCrisisEntry: CrisisEntryData?
    let alertSharedWithNetwork: Bool
}

struct CrisisEntryData: Codable, Sendable {
    let moodId: String
    let timestamp: Date
}

/// Mood streak response data.
struct MoodStreakData: Codable, Sendable {
    let currentStreakDays: Int
    let longestStreakDays: Int
    let lastEntryDate: String?
}

// MARK: - Display Mode

/// User preference for mood display: emoji or numeric.
/// Stored locally in UserDefaults, not synced to API.
enum MoodDisplayMode: String, Sendable {
    case emoji
    case numeric
}
