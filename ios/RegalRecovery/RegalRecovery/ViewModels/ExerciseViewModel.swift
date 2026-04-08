import Foundation

// MARK: - Exercise Types (matching OpenAPI spec)

/// Activity types matching the OpenAPI ActivityType enum.
enum ExerciseActivityType: String, CaseIterable, Identifiable, Sendable {
    case walking
    case running
    case gym
    case yoga
    case swimming
    case cycling
    case sports
    case hiking
    case dance
    case martialArts = "martial-arts"
    case groupFitness = "group-fitness"
    case homeWorkout = "home-workout"
    case yardwork
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .walking: return "Walking"
        case .running: return "Running"
        case .gym: return "Gym"
        case .yoga: return "Yoga"
        case .swimming: return "Swimming"
        case .cycling: return "Cycling"
        case .sports: return "Sports"
        case .hiking: return "Hiking"
        case .dance: return "Dance"
        case .martialArts: return "Martial Arts"
        case .groupFitness: return "Group Fitness"
        case .homeWorkout: return "Home Workout"
        case .yardwork: return "Yardwork"
        case .other: return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .gym: return "dumbbell.fill"
        case .yoga: return "figure.yoga"
        case .swimming: return "figure.pool.swim"
        case .cycling: return "figure.outdoor.cycle"
        case .sports: return "sportscourt.fill"
        case .hiking: return "figure.hiking"
        case .dance: return "figure.dance"
        case .martialArts: return "figure.martial.arts"
        case .groupFitness: return "figure.mixed.cardio"
        case .homeWorkout: return "house.fill"
        case .yardwork: return "leaf.fill"
        case .other: return "figure.mixed.cardio"
        }
    }
}

/// Intensity levels matching the OpenAPI IntensityLevel enum.
enum ExerciseIntensity: String, CaseIterable, Identifiable, Sendable {
    case light
    case moderate
    case vigorous

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .moderate: return "Moderate"
        case .vigorous: return "Vigorous"
        }
    }

    var helperText: String {
        switch self {
        case .light: return "Easy conversation possible"
        case .moderate: return "Can talk but not sing"
        case .vigorous: return "Can only say a few words"
        }
    }
}

/// Data source for exercise entries.
enum ExerciseSource: String, Sendable {
    case manual
    case appleHealth = "apple-health"
    case googleFit = "google-fit"
}

// MARK: - Exercise Entry

struct ExerciseEntry: Identifiable, Sendable {
    let id: UUID
    let exerciseId: String
    let date: Date
    let activityType: ExerciseActivityType
    let customTypeLabel: String?
    let durationMinutes: Int
    let intensity: ExerciseIntensity?
    let notes: String
    let moodBefore: Int?
    let moodAfter: Int?
    let source: ExerciseSource
    let externalId: String?

    init(
        id: UUID = UUID(),
        exerciseId: String = "",
        date: Date = Date(),
        activityType: ExerciseActivityType = .running,
        customTypeLabel: String? = nil,
        durationMinutes: Int = 30,
        intensity: ExerciseIntensity? = nil,
        notes: String = "",
        moodBefore: Int? = nil,
        moodAfter: Int? = nil,
        source: ExerciseSource = .manual,
        externalId: String? = nil
    ) {
        self.id = id
        self.exerciseId = exerciseId.isEmpty ? "ex_\(id.uuidString.prefix(8))" : exerciseId
        self.date = date
        self.activityType = activityType
        self.customTypeLabel = customTypeLabel
        self.durationMinutes = durationMinutes
        self.intensity = intensity
        self.notes = notes
        self.moodBefore = moodBefore
        self.moodAfter = moodAfter
        self.source = source
        self.externalId = externalId
    }
}

// MARK: - Exercise Favorite

struct ExerciseFavoriteItem: Identifiable, Sendable {
    let id: UUID
    let favoriteId: String
    let activityType: ExerciseActivityType
    let customTypeLabel: String?
    let defaultDurationMinutes: Int
    let defaultIntensity: ExerciseIntensity?
    let label: String
}

// MARK: - Exercise Streak

struct ExerciseStreakData: Sendable {
    let currentDays: Int
    let longestDays: Int
    let lastExerciseDate: String?
    let nextMilestone: ExerciseMilestone?
}

struct ExerciseMilestone: Sendable {
    let days: Int
    let daysRemaining: Int
    let label: String
}

// MARK: - Weekly Goal

struct ExerciseWeeklyGoal: Sendable {
    let targetActiveMinutes: Int?
    let targetSessions: Int?
    let currentActiveMinutes: Int
    let currentSessions: Int
    let progressPercent: Double
    let weekStartDate: String
    let isGoalMet: Bool
}

// MARK: - Widget Data

struct ExerciseWidgetData: Sendable {
    let exercisedToday: Bool
    let todayActiveMinutes: Int
    let todaySessions: Int
    let streakCurrentDays: Int
    let weeklyGoal: ExerciseWeeklyGoal?
}

// MARK: - View Model

@Observable
class ExerciseViewModel {

    // MARK: - Feature Flag
    static let featureFlagKey = "activity.exercise"

    // MARK: - State

    var history: [ExerciseEntry] = []
    var favorites: [ExerciseFavoriteItem] = []
    var streak: ExerciseStreakData = ExerciseStreakData(currentDays: 0, longestDays: 0, lastExerciseDate: nil, nextMilestone: nil)
    var weeklyGoal: ExerciseWeeklyGoal?
    var widgetData: ExerciseWidgetData?
    var isLoading = false
    var error: String?

    // Entry form state
    var selectedActivityType: ExerciseActivityType = .running
    var customTypeLabel: String = ""
    var duration: Int = 30
    var selectedIntensity: ExerciseIntensity? = nil
    var notes: String = ""
    var moodBefore: Int? = nil
    var moodAfter: Int? = nil
    var entryDate: Date = Date()

    // Quick-select duration options
    static let quickDurations = [15, 30, 45, 60, 90]

    // Post-log rotating messages (per PRD Tone & Messaging)
    static let postLogMessages = [
        "Great work. Moving your body is an act of self-care.",
        "Exercise isn't punishment -- it's freedom. You showed up for yourself today.",
        "Your body carried you through today. That's worth celebrating."
    ]

    // First-use helper text (per PRD)
    static let firstUseHelperText = "Physical activity is one of the most powerful tools in recovery. It reduces stress, improves mood, and rebuilds your connection with your body. Every minute counts."

    // Notes placeholder prompts (rotating per PRD)
    static let notesPlaceholders = [
        "How did you feel before and after?",
        "Did this help with stress or urges today?",
        "What motivated you to move today?"
    ]

    // MARK: - Computed

    var totalMinutesThisWeek: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return history
            .filter { $0.date >= weekAgo }
            .reduce(0) { $0 + $1.durationMinutes }
    }

    var sessionsThisWeek: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return history.filter { $0.date >= weekAgo }.count
    }

    var exercisedToday: Bool {
        let calendar = Calendar.current
        return history.contains { calendar.isDateInToday($0.date) }
    }

    var requiresCustomLabel: Bool {
        selectedActivityType == .other
    }

    // MARK: - Validation

    var isFormValid: Bool {
        guard duration >= 1, duration <= 1440 else { return false }
        if selectedActivityType == .other, customTypeLabel.trimmingCharacters(in: .whitespaces).isEmpty {
            return false
        }
        if let mb = moodBefore, (mb < 1 || mb > 5) { return false }
        if let ma = moodAfter, (ma < 1 || ma > 5) { return false }
        if notes.count > 500 { return false }
        return true
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            history = try await loadFromStorage()
        } catch {
            // Fallback to mock data
            history = [
                ExerciseEntry(date: daysAgo(1, hour: 6, minute: 30), activityType: .running, durationMinutes: 30, intensity: .moderate, notes: "Morning jog in the park. Felt great after.", moodBefore: 3, moodAfter: 5),
                ExerciseEntry(date: daysAgo(2), activityType: .gym, durationMinutes: 45, intensity: .vigorous, notes: "Upper body day"),
                ExerciseEntry(date: daysAgo(3), activityType: .running, durationMinutes: 30, intensity: .moderate, notes: "Easy morning jog"),
                ExerciseEntry(date: daysAgo(5), activityType: .yoga, durationMinutes: 60, intensity: .light, notes: "Great stretch session"),
                ExerciseEntry(date: daysAgo(6), activityType: .running, durationMinutes: 35, intensity: .vigorous, notes: "Interval training"),
            ]
            self.error = error.localizedDescription
        }
    }

    // MARK: - Submit

    func submit() async throws {
        guard isFormValid else {
            throw ActivityError.validationFailed("Please check your entries and try again.")
        }

        let entry = ExerciseEntry(
            date: entryDate,
            activityType: selectedActivityType,
            customTypeLabel: selectedActivityType == .other ? customTypeLabel : nil,
            durationMinutes: duration,
            intensity: selectedIntensity,
            notes: notes,
            moodBefore: moodBefore,
            moodAfter: moodAfter,
            source: .manual
        )

        // TODO: Replace with API client call + SwiftData persistence
        history.insert(entry, at: 0)
        resetForm()
    }

    // MARK: - Quick Log from Favorite

    func quickLog(from favorite: ExerciseFavoriteItem) async throws {
        let entry = ExerciseEntry(
            date: Date(),
            activityType: favorite.activityType,
            customTypeLabel: favorite.customTypeLabel,
            durationMinutes: favorite.defaultDurationMinutes,
            intensity: favorite.defaultIntensity,
            source: .manual
        )

        // TODO: Replace with API client call
        history.insert(entry, at: 0)
    }

    // MARK: - Private

    private func resetForm() {
        selectedActivityType = .running
        customTypeLabel = ""
        duration = 30
        selectedIntensity = nil
        notes = ""
        moodBefore = nil
        moodAfter = nil
        entryDate = Date()
    }

    private func loadFromStorage() async throws -> [ExerciseEntry] {
        throw ActivityError.notImplemented
    }

    private func daysAgo(_ days: Int, hour: Int = 7, minute: Int = 0) -> Date {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -days, to: Date())!
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)!
    }
}
