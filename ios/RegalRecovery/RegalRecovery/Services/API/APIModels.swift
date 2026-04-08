import Foundation

// MARK: - Siemens Response Envelope

/// Generic Siemens response envelope [101.2].
/// `data` contains the primary payload; `links` and `meta` provide hypermedia and metadata.
struct SiemensResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let data: T
    let links: ResourceLinks?
    let meta: ResponseMeta?

    struct ResourceLinks: Decodable, Sendable {
        let `self`: String?
        let next: String?
        let prev: String?
        let first: String?
        let last: String?
        let profile: String?
        let settings: String?
        let addictions: String?
        let streaks: String?
        let milestones: String?
        let calendar: String?
        let postMortem: String?
        let newStreak: String?
        let detail: String?
        let streak: String?

        // Accept unknown keys gracefully
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: DynamicCodingKey.self)
            self.`self` = try container.decodeIfPresent(String.self, forKey: .init(stringValue: "self"))
            self.next = try container.decodeIfPresent(String.self, forKey: .init(stringValue: "next"))
            self.prev = try container.decodeIfPresent(String.self, forKey: .init(stringValue: "prev"))
            self.first = try container.decodeIfPresent(String.self, forKey: .init(stringValue: "first"))
            self.last = try container.decodeIfPresent(String.self, forKey: .init(stringValue: "last"))
            self.profile = try container.decodeIfPresent(String.self, forKey: .init(stringValue: "profile"))
            self.settings = try container.decodeIfPresent(String.self, forKey: .init(stringValue: "settings"))
            self.addictions = try container.decodeIfPresent(String.self, forKey: .init(stringValue: "addictions"))
            self.streaks = try container.decodeIfPresent(String.self, forKey: .init(stringValue: "streaks"))
            self.milestones = try container.decodeIfPresent(String.self, forKey: .init(stringValue: "milestones"))
            self.calendar = try container.decodeIfPresent(String.self, forKey: .init(stringValue: "calendar"))
            self.postMortem = try container.decodeIfPresent(String.self, forKey: .init(stringValue: "postMortem"))
            self.newStreak = try container.decodeIfPresent(String.self, forKey: .init(stringValue: "newStreak"))
            self.detail = try container.decodeIfPresent(String.self, forKey: .init(stringValue: "detail"))
            self.streak = try container.decodeIfPresent(String.self, forKey: .init(stringValue: "streak"))
        }
    }

    struct ResponseMeta: Decodable, Sendable {
        let createdAt: String?
        let modifiedAt: String?
        let version: String?
        let lastLoginAt: String?
        let message: String?
        let evaluatedAt: String?
        let totalAddictions: Int?
        let totalSoberDays: Int?
        let retrievedAt: String?
        let totalAchieved: Int?
        let totalUpcoming: Int?
        let totalDays: Int?
        let cleanDays: Int?
        let urgeCount: Int?
        let checkInCompletionRate: Double?
        let totalSessions: Int?
        let totalFlags: Int?
        let page: PageMeta?

        struct PageMeta: Decodable, Sendable {
            let nextCursor: String?
            let prevCursor: String?
            let limit: Int?
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: DynamicCodingKey.self)
            self.createdAt = try container.decodeIfPresent(String.self, forKey: .init(stringValue: "createdAt"))
            self.modifiedAt = try container.decodeIfPresent(String.self, forKey: .init(stringValue: "modifiedAt"))
            self.version = try container.decodeIfPresent(String.self, forKey: .init(stringValue: "version"))
            self.lastLoginAt = try container.decodeIfPresent(String.self, forKey: .init(stringValue: "lastLoginAt"))
            self.message = try container.decodeIfPresent(String.self, forKey: .init(stringValue: "message"))
            self.evaluatedAt = try container.decodeIfPresent(String.self, forKey: .init(stringValue: "evaluatedAt"))
            self.totalAddictions = try container.decodeIfPresent(Int.self, forKey: .init(stringValue: "totalAddictions"))
            self.totalSoberDays = try container.decodeIfPresent(Int.self, forKey: .init(stringValue: "totalSoberDays"))
            self.retrievedAt = try container.decodeIfPresent(String.self, forKey: .init(stringValue: "retrievedAt"))
            self.totalAchieved = try container.decodeIfPresent(Int.self, forKey: .init(stringValue: "totalAchieved"))
            self.totalUpcoming = try container.decodeIfPresent(Int.self, forKey: .init(stringValue: "totalUpcoming"))
            self.totalDays = try container.decodeIfPresent(Int.self, forKey: .init(stringValue: "totalDays"))
            self.cleanDays = try container.decodeIfPresent(Int.self, forKey: .init(stringValue: "cleanDays"))
            self.urgeCount = try container.decodeIfPresent(Int.self, forKey: .init(stringValue: "urgeCount"))
            self.checkInCompletionRate = try container.decodeIfPresent(Double.self, forKey: .init(stringValue: "checkInCompletionRate"))
            self.totalSessions = try container.decodeIfPresent(Int.self, forKey: .init(stringValue: "totalSessions"))
            self.totalFlags = try container.decodeIfPresent(Int.self, forKey: .init(stringValue: "totalFlags"))
            self.page = try container.decodeIfPresent(PageMeta.self, forKey: .init(stringValue: "page"))
        }
    }
}

/// Paginated list response with cursor-based pagination [601.1].
struct PaginatedResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let data: [T]
    let nextCursor: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        self.data = try container.decode([T].self, forKey: .init(stringValue: "data"))

        // nextCursor can live in meta.page.nextCursor or links.next
        if let meta = try? container.nestedContainer(
            keyedBy: DynamicCodingKey.self, forKey: .init(stringValue: "meta")
        ),
           let page = try? meta.nestedContainer(
               keyedBy: DynamicCodingKey.self, forKey: .init(stringValue: "page")
           ) {
            self.nextCursor = try page.decodeIfPresent(String.self, forKey: .init(stringValue: "nextCursor"))
        } else {
            self.nextCursor = nil
        }
    }
}

/// Dynamic coding key for flexible JSON parsing.
struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

// MARK: - Auth Models

struct RegisterRequest: Codable, Sendable {
    let email: String
    let password: String
    let displayName: String
    let primaryAddiction: String
    let sobrietyStartDate: String
    let preferredLanguage: String?
    let timeZone: String?
}

struct LoginRequest: Codable, Sendable {
    let email: String
    let password: String
    let deviceId: String?
    let deviceName: String?
}

struct RefreshTokenRequest: Codable, Sendable {
    let refreshToken: String
}

struct LogoutRequest: Codable, Sendable {
    let refreshToken: String?
}

/// Returned from both register and login; contains tokens for immediate auth.
struct AuthTokenData: Codable, Sendable {
    let userId: String?
    let email: String?
    let displayName: String?
    let emailVerified: Bool?
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
    let sessionId: String?
}

/// Returned from /auth/refresh.
struct RefreshTokenData: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
}

/// Session object from /auth/sessions.
struct SessionData: Codable, Sendable {
    let sessionId: String
    let deviceId: String?
    let deviceName: String?
    let deviceType: String?
    let ipAddress: String?
    let location: SessionLocation?
    let createdAt: String?
    let lastActivityAt: String?
    let expiresAt: String?
    let isCurrent: Bool?

    struct SessionLocation: Codable, Sendable {
        let city: String?
        let region: String?
        let country: String?
    }
}

// MARK: - User Models

struct UserProfileData: Codable, Sendable {
    let userId: String
    let email: String?
    let displayName: String?
    let role: String?
    let primaryAddictionId: String?
    let preferredLanguage: String?
    let preferredBibleVersion: String?
    let emailVerified: Bool?
    let biometricEnabled: Bool?
    let birthYear: Int?
    let gender: String?
    let maritalStatus: String?
    let timeZone: String?
}

struct UpdateProfileRequest: Codable, Sendable {
    let displayName: String?
    let preferredLanguage: String?
    let preferredBibleVersion: String?
    let birthYear: Int?
    let gender: String?
    let maritalStatus: String?
    let timeZone: String?

    init(
        displayName: String? = nil,
        preferredLanguage: String? = nil,
        preferredBibleVersion: String? = nil,
        birthYear: Int? = nil,
        gender: String? = nil,
        maritalStatus: String? = nil,
        timeZone: String? = nil
    ) {
        self.displayName = displayName
        self.preferredLanguage = preferredLanguage
        self.preferredBibleVersion = preferredBibleVersion
        self.birthYear = birthYear
        self.gender = gender
        self.maritalStatus = maritalStatus
        self.timeZone = timeZone
    }
}

struct UserSettingsData: Codable, Sendable {
    let notifications: NotificationSettings?
    let content: ContentSettings?
    let ui: UISettings?
    let privacy: PrivacyPreferences?

    struct NotificationSettings: Codable, Sendable {
        let dailyReminder: Bool?
        let dailyReminderTime: String?
        let eveningCheckIn: Bool?
        let eveningCheckInTime: String?
        let milestoneAlerts: Bool?
        let urgeFollowUp: Bool?
        let supportNetworkUpdates: Bool?
        let pushEnabled: Bool?
        let emailEnabled: Bool?
        let smsEnabled: Bool?
    }

    struct ContentSettings: Codable, Sendable {
        let preferredBibleVersion: String?
        let contentLanguage: String?
        let devotionalFrequency: String?
        let affirmationFrequency: String?
    }

    struct UISettings: Codable, Sendable {
        let theme: String?
        let colorScheme: String?
        let compactMode: Bool?
        let showCalendarHeatmap: Bool?
    }

    struct PrivacyPreferences: Codable, Sendable {
        let profileVisibility: String?
        let allowMilestoneSharing: Bool?
        let shareLocationForMeetings: Bool?
    }
}

struct PrivacySettingsData: Codable, Sendable {
    let profileVisibility: String?
    let allowMilestoneSharing: Bool?
    let shareLocationForMeetings: Bool?
    let allowAnonymousStorySubmission: Bool?
    let dataRetention: DataRetention?

    struct DataRetention: Codable, Sendable {
        let ephemeralJournalDays: Int?
        let autoDeleteUrges: Bool?
    }
}

struct AddictionData: Codable, Sendable {
    let addictionId: String
    let type: String
    let sobrietyStartDate: String
    let isPrimary: Bool?
    let currentStreakDays: Int?
}

struct AddAddictionRequest: Codable, Sendable {
    let type: String
    let sobrietyStartDate: String
    let isPrimary: Bool?
}

// MARK: - Tracking Models

struct StreakData_API: Codable, Sendable {
    let streakId: String?
    let addictionId: String?
    let addictionType: String?
    let currentStreakDays: Int
    let longestStreakDays: Int?
    let sobrietyStartDate: String?
    let lastRelapseDate: String?
    let totalSoberDaysLast30: Int?
    let totalSoberDaysLast90: Int?
    let totalSoberDaysLast365: Int?
    let nextMilestone: NextMilestone?

    struct NextMilestone: Codable, Sendable {
        let days: Int
        let daysRemaining: Int
        let label: String
    }
}

struct MilestoneData: Codable, Sendable {
    let milestoneId: String
    let addictionId: String?
    let addictionType: String?
    let days: Int
    let label: String?
    let achievedAt: String?
    let daysRemaining: Int?
    let celebrated: Bool?
}

struct RelapseRequest: Codable, Sendable {
    let addictionId: String
    let timestamp: String
    let notes: String?
}

struct RelapseData: Codable, Sendable {
    let relapseId: String
    let addictionId: String
    let timestamp: String
    let previousStreakDays: Int?
    let notes: String?
    let postMortemPrompted: Bool?
}

struct CalendarData: Codable, Sendable {
    let month: String?
    let days: [CalendarDayData]?
}

struct CalendarDayData: Codable, Sendable {
    let date: String
    let sobrietyStatus: String?
    let checkInCompleted: Bool?
    let checkInScore: Int?
    let urgeCount: Int?
    let activities: DayActivities?
    let heatmapValue: Int?

    struct DayActivities: Codable, Sendable {
        let commitment: Bool?
        let journal: Bool?
        let devotional: Bool?
        let meeting: Bool?
        let exercise: Bool?
    }
}

struct HistoryPeriod: Codable, Sendable {
    let periodStart: String
    let periodEnd: String?
    let streakDays: Int
    let status: String
    let endedReason: String?
    let milestones: [Int]?
}

// MARK: - Activity Models

/// Generic activity request body. The schema varies per activity type;
/// this captures the common superset. Callers populate only the relevant fields.
struct ActivityRequest: Codable, Sendable {
    // Commitments
    let commitmentType: String? // "morning" | "evening"
    let items: [String]?

    // Journals
    let title: String?
    let content: String?
    let journalType: String?
    let emotion: String?
    let intensity: Int?

    // Check-ins
    let checkInType: String?
    let score: Int?
    let answers: [String: Int]?

    // FASTER Scale
    let stage: String?
    let notes: String?

    // Urges
    let urgeIntensity: Int?
    let sobrietyMaintained: Bool?
    let copingStrategiesUsed: [String]?

    // Mood
    let moodRating: Int?
    let moodLabel: String?

    // Generic timestamp override
    let timestamp: String?

    // Ephemeral flag
    let ephemeral: Bool?

    init(
        commitmentType: String? = nil,
        items: [String]? = nil,
        title: String? = nil,
        content: String? = nil,
        journalType: String? = nil,
        emotion: String? = nil,
        intensity: Int? = nil,
        checkInType: String? = nil,
        score: Int? = nil,
        answers: [String: Int]? = nil,
        stage: String? = nil,
        notes: String? = nil,
        urgeIntensity: Int? = nil,
        sobrietyMaintained: Bool? = nil,
        copingStrategiesUsed: [String]? = nil,
        moodRating: Int? = nil,
        moodLabel: String? = nil,
        timestamp: String? = nil,
        ephemeral: Bool? = nil
    ) {
        self.commitmentType = commitmentType
        self.items = items
        self.title = title
        self.content = content
        self.journalType = journalType
        self.emotion = emotion
        self.intensity = intensity
        self.checkInType = checkInType
        self.score = score
        self.answers = answers
        self.stage = stage
        self.notes = notes
        self.urgeIntensity = urgeIntensity
        self.sobrietyMaintained = sobrietyMaintained
        self.copingStrategiesUsed = copingStrategiesUsed
        self.moodRating = moodRating
        self.moodLabel = moodLabel
        self.timestamp = timestamp
        self.ephemeral = ephemeral
    }
}

/// Generic activity response for any activity type.
struct ActivityData: Codable, Sendable {
    let activityId: String?
    let activityType: String?
    let timestamp: String?
    let createdAt: String?

    // The rest is opaque per-type payload
    let payload: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case activityId, activityType, timestamp, createdAt, payload
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        self.activityId = try container.decodeIfPresent(String.self, forKey: .init(stringValue: "activityId"))
        self.activityType = try container.decodeIfPresent(String.self, forKey: .init(stringValue: "activityType"))
        self.timestamp = try container.decodeIfPresent(String.self, forKey: .init(stringValue: "timestamp"))
        self.createdAt = try container.decodeIfPresent(String.self, forKey: .init(stringValue: "createdAt"))
        // Capture all remaining keys as the opaque payload
        var payloadDict: [String: AnyCodable] = [:]
        let knownKeys: Set<String> = ["activityId", "activityType", "timestamp", "createdAt", "links"]
        for key in container.allKeys where !knownKeys.contains(key.stringValue) {
            if let value = try? container.decode(AnyCodable.self, forKey: key) {
                payloadDict[key.stringValue] = value
            }
        }
        self.payload = payloadDict.isEmpty ? nil : payloadDict
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        try container.encodeIfPresent(activityId, forKey: .init(stringValue: "activityId"))
        try container.encodeIfPresent(activityType, forKey: .init(stringValue: "activityType"))
        try container.encodeIfPresent(timestamp, forKey: .init(stringValue: "timestamp"))
        try container.encodeIfPresent(createdAt, forKey: .init(stringValue: "createdAt"))
        if let payload {
            for (key, value) in payload {
                try container.encode(value, forKey: .init(stringValue: key))
            }
        }
    }
}

// MARK: - Content Models

struct AffirmationData: Codable, Sendable {
    let id: String
    let text: String
    let category: String?
    let packId: String?
    let packName: String?
    let isFavorite: Bool?
    let language: String?
}

struct DevotionalData: Codable, Sendable {
    let id: String
    let title: String?
    let scripture: String?
    let scriptureText: String?
    let reflection: String?
    let prayerPrompt: String?
    let date: String?
}

struct PrayerData: Codable, Sendable {
    let id: String
    let title: String?
    let text: String?
    let theme: String?
    let packId: String?
    let packName: String?
    let language: String?
}

struct ResourceData: Codable, Sendable {
    let id: String
    let title: String?
    let description: String?
    let type: String?
    let category: String?
    let url: String?
    let thumbnailUrl: String?
    let duration: Int?
    let author: String?
    let publishedAt: String?
}

struct ContentPackData: Codable, Sendable {
    let id: String
    let name: String?
    let description: String?
    let price: Double?
    let currency: String?
    let itemCount: Int?
    let thumbnailUrl: String?
    let isOwned: Bool?
    let purchasedAt: String?
}

struct PurchaseRequest: Codable, Sendable {
    let receiptData: String
    let platform: String
}

struct PurchaseResultData: Codable, Sendable {
    let packId: String?
    let transactionId: String?
    let purchasedAt: String?
    let status: String?
}

// MARK: - Exercise API Models (matching OpenAPI spec)

/// Request to create an exercise log entry.
struct CreateExerciseLogRequest: Codable, Sendable {
    let timestamp: String
    let activityType: String
    let customTypeLabel: String?
    let durationMinutes: Int
    let intensity: String?
    let notes: String?
    let moodBefore: Int?
    let moodAfter: Int?
    let source: String?
    let externalId: String?
}

/// Request to update an exercise log (merge patch -- mutable fields only).
struct UpdateExerciseLogRequest: Codable, Sendable {
    let intensity: String?
    let notes: String?
    let moodBefore: Int?
    let moodAfter: Int?
    let customTypeLabel: String?
}

/// Request to create or update an exercise favorite.
struct CreateExerciseFavoriteRequest: Codable, Sendable {
    let activityType: String
    let customTypeLabel: String?
    let defaultDurationMinutes: Int
    let defaultIntensity: String?
    let label: String
}

/// Request to set a weekly exercise goal.
struct SetExerciseGoalRequest: Codable, Sendable {
    let targetActiveMinutes: Int?
    let targetSessions: Int?
}

/// Exercise log data from API response.
struct ExerciseLogData: Codable, Sendable {
    let exerciseId: String
    let timestamp: String
    let activityType: String
    let customTypeLabel: String?
    let durationMinutes: Int
    let intensity: String?
    let notes: String?
    let moodBefore: Int?
    let moodAfter: Int?
    let source: String
    let externalId: String?
    let exerciseStreak: ExerciseStreakResponse?
}

/// Exercise streak from API response.
struct ExerciseStreakResponse: Codable, Sendable {
    let currentDays: Int
    let longestDays: Int
    let lastExerciseDate: String?
    let nextMilestone: ExerciseMilestoneResponse?
}

struct ExerciseMilestoneResponse: Codable, Sendable {
    let days: Int
    let daysRemaining: Int
    let label: String
}

/// Exercise favorite from API response.
struct ExerciseFavoriteData: Codable, Sendable {
    let favoriteId: String
    let activityType: String
    let customTypeLabel: String?
    let defaultDurationMinutes: Int
    let defaultIntensity: String?
    let label: String
}

/// Exercise goal progress from API response.
struct ExerciseGoalData: Codable, Sendable {
    let targetActiveMinutes: Int?
    let targetSessions: Int?
    let currentActiveMinutes: Int
    let currentSessions: Int
    let progressPercent: Double
    let weekStartDate: String
    let isGoalMet: Bool
}

/// Exercise widget data from API response.
struct ExerciseWidgetApiData: Codable, Sendable {
    let exercisedToday: Bool
    let todayActiveMinutes: Int
    let todaySessions: Int
    let streak: ExerciseWidgetStreak
    let weeklyGoal: ExerciseWidgetGoal?
}

struct ExerciseWidgetStreak: Codable, Sendable {
    let currentDays: Int
}

struct ExerciseWidgetGoal: Codable, Sendable {
    let targetActiveMinutes: Int
    let currentActiveMinutes: Int
    let progressPercent: Double
    let isGoalMet: Bool
}

// MARK: - Siemens Error Response

struct SiemensErrorResponse: Decodable, Sendable {
    let errors: [SiemensError]
}

struct SiemensError: Decodable, Sendable {
    let id: String?
    let code: String?
    let status: Int?
    let title: String?
    let detail: String?
    let correlationId: String?
}

// MARK: - Feature Flag Models

struct EvaluatedFlagData: Codable, Sendable {
    let key: String
    let enabled: Bool
}

// MARK: - Type-Erased Codable

/// A type-erased Codable wrapper for heterogeneous JSON payloads.
struct AnyCodable: Codable, Sendable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map(\.value)
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            self.value = dict.mapValues(\.value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable cannot decode value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, .init(codingPath: encoder.codingPath, debugDescription: "AnyCodable cannot encode value"))
        }
    }
}
