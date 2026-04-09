import Foundation

// MARK: - Affirmation Level

/// Clinical progression level (1-4) based on Patrick Carnes' core belief model.
///
/// - Level 1: Permission (Day 0+)
/// - Level 2: Process (Day 14+)
/// - Level 3: Tempered Identity (Day 60+)
/// - Level 4: Full Identity (Day 180+)
enum AffirmationLevel: Int, Codable, Sendable, CaseIterable {
    case permission = 1
    case process = 2
    case temperedIdentity = 3
    case fullIdentity = 4

    var displayName: String {
        switch self {
        case .permission: return "Permission"
        case .process: return "Process"
        case .temperedIdentity: return "Tempered Identity"
        case .fullIdentity: return "Full Identity"
        }
    }

    /// The API-level string name used in level info responses.
    var apiName: String {
        switch self {
        case .permission: return "permission"
        case .process: return "process"
        case .temperedIdentity: return "tempered-identity"
        case .fullIdentity: return "full-identity"
        }
    }
}

// MARK: - Affirmation Category

/// Content categories based on Patrick Carnes' core belief model and clinical recovery domains.
enum AffirmationCategory: String, Codable, Sendable, CaseIterable {
    case selfWorth = "self-worth"
    case shameResilience = "shame-resilience"
    case healthyRelationships = "healthy-relationships"
    case connection = "connection"
    case emotionalRegulation = "emotional-regulation"
    case purposeMeaning = "purpose-meaning"
    case integrityHonesty = "integrity-honesty"
    case dailyStrength = "daily-strength"
    case healthySexuality = "healthy-sexuality"
    case sosCrisis = "sos-crisis"

    var displayName: String {
        switch self {
        case .selfWorth: return "Self-Worth"
        case .shameResilience: return "Shame Resilience"
        case .healthyRelationships: return "Healthy Relationships"
        case .connection: return "Connection"
        case .emotionalRegulation: return "Emotional Regulation"
        case .purposeMeaning: return "Purpose & Meaning"
        case .integrityHonesty: return "Integrity & Honesty"
        case .dailyStrength: return "Daily Strength"
        case .healthySexuality: return "Healthy Sexuality"
        case .sosCrisis: return "SOS / Crisis"
        }
    }
}

// MARK: - Affirmation Track

/// Content track selection.
enum AffirmationTrack: String, Codable, Sendable, CaseIterable {
    case standard
    case faithBased = "faith-based"

    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .faithBased: return "Faith-Based"
        }
    }
}

// MARK: - Recovery Stage

/// Recovery stage classification.
enum AffirmationRecoveryStage: String, Codable, Sendable {
    case early
    case middle
    case established
}

// MARK: - Background Music

/// Ambient background music preset for audio recordings.
enum AffirmationBackgroundMusic: String, Codable, Sendable, CaseIterable {
    case nature
    case ocean
    case rain
    case softTones = "soft-tones"
    case silence

    var displayName: String {
        switch self {
        case .nature: return "Nature"
        case .ocean: return "Ocean"
        case .rain: return "Rain"
        case .softTones: return "Soft Tones"
        case .silence: return "Silence"
        }
    }
}

// MARK: - Session Type

/// Types of affirmation sessions.
enum AffirmationSessionType: String, Codable, Sendable {
    case morning
    case evening
    case sos
}

// MARK: - Core Models

/// A single affirmation from the curated library.
struct AffirmationItem: Codable, Sendable, Identifiable, Hashable {
    let id: String
    let text: String
    let level: Int
    let coreBeliefs: [Int]
    let category: AffirmationCategory
    let track: AffirmationTrack
    let recoveryStage: AffirmationRecoveryStage
    var isFavorite: Bool?
    var hasAudio: Bool?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AffirmationItem, rhs: AffirmationItem) -> Bool {
        lhs.id == rhs.id
    }
}

/// A user-created custom affirmation.
struct CustomAffirmation: Codable, Sendable, Identifiable {
    let customId: String
    let text: String
    let includeInRotation: Bool
    let isEditable: Bool?
    let editableUntil: Date?
    var isFavorite: Bool?
    var isHidden: Bool?
    var hasAudio: Bool?
    let createdAt: Date
    let modifiedAt: Date?

    var id: String { customId }
}

/// Metadata for an own-voice audio recording.
struct AudioRecordingMeta: Codable, Sendable, Identifiable {
    let recordingId: String
    let affirmationId: String
    let format: String
    let durationSeconds: Double
    let backgroundMusic: AffirmationBackgroundMusic
    let sizeBytes: Int?
    let playbackUrl: String?
    let cloudSynced: Bool?
    let createdAt: Date?

    var id: String { recordingId }
}

/// Cumulative progress metrics (never streak-based).
struct AffirmationProgress: Codable, Sendable {
    let totalSessions: Int?
    let totalMorningSessions: Int?
    let totalEveningSessions: Int?
    let totalSOSSessions: Int?
    let totalAffirmationsPracticed: Int?
    let totalCustomCreated: Int?
    let totalAudioRecordings: Int?
    let totalFavorites: Int?
    let totalHidden: Int?
    let consistency30d: [DayConsistency]?
    let milestones: [AffirmationMilestone]?
}

/// A single day in the 30-day consistency calendar.
struct DayConsistency: Codable, Sendable {
    let date: String
    let sessions: Int
}

/// A progress milestone achieved.
struct AffirmationMilestone: Codable, Sendable {
    let type: String
    let threshold: Int?
    let message: String?
    let achievedAt: Date?
}

/// User affirmation feature settings.
struct AffirmationSettings: Codable, Sendable {
    let morningTime: String?
    let eveningTime: String?
    let track: AffirmationTrack?
    let levelOverride: Int?
    let enabledCategories: [AffirmationCategory]?
    let healthySexualityEnabled: Bool?
    let audioAutoPlay: Bool?
    let cloudAudioSync: Bool?
}

/// Current affirmation level information.
struct LevelInfo: Codable, Sendable {
    let currentLevel: Int
    let levelName: String?
    let daysAtLevel: Int?
    let daysInRecovery: Int?
    let nextLevelEligible: Bool?
    let nextLevelName: String?
    let nextLevelAutoUnlockDay: Int?
    let canRequestUpgrade: Bool?
    let upgradeEligibleAt: Date?
    let levelHistory: [LevelHistoryEntry]?
}

/// A single entry in the level change history.
struct LevelHistoryEntry: Codable, Sendable {
    let level: Int
    let startedAt: Date?
    let endedAt: Date?
    let trigger: String?
}

// MARK: - Breathing Exercise

/// Breathing exercise configuration for SOS sessions.
struct BreathingExercise: Codable, Sendable {
    let pattern: String
    let inhaleSeconds: Int
    let holdSeconds: Int
    let exhaleSeconds: Int
    let cycles: Int
    let durationSeconds: Int
}

// MARK: - Interaction Models

/// Per-affirmation interaction during a session.
struct AffirmationInteraction: Codable, Sendable {
    let affirmationId: String
    var favorited: Bool?
    var hidden: Bool?
    var durationViewed: Int?
}

// MARK: - Request Models

/// Request body for completing a morning session.
struct CompleteMorningRequest: Codable, Sendable {
    let sessionId: String
    let intention: String?
    let affirmationInteractions: [AffirmationInteraction]?
}

/// Request body for completing an evening session.
struct CompleteEveningRequest: Codable, Sendable {
    let sessionId: String
    let dayRating: Int
    let reflection: String?
}

/// Request body for completing an SOS session.
struct CompleteSOSRequest: Codable, Sendable {
    let breathingCompleted: Bool?
    let reachedOut: Bool?
    let postCheckInRating: Int?
}

/// Request body for creating a custom affirmation.
struct CreateCustomAffirmationRequest: Codable, Sendable {
    let text: String
    let includeInRotation: Bool?
}

/// Request body for updating a custom affirmation.
struct UpdateCustomAffirmationRequest: Codable, Sendable {
    let text: String?
    let includeInRotation: Bool?
}

/// Request body for a level override.
struct LevelOverrideRequest: Codable, Sendable {
    let targetLevel: Int
    let direction: String
}

/// Request body for updating affirmation settings.
struct UpdateAffirmationSettingsRequest: Codable, Sendable {
    let morningTime: String?
    let eveningTime: String?
    let track: AffirmationTrack?
    let levelOverride: Int?
    let enabledCategories: [AffirmationCategory]?
    let healthySexualityEnabled: Bool?
    let audioAutoPlay: Bool?
    let cloudAudioSync: Bool?

    init(
        morningTime: String? = nil,
        eveningTime: String? = nil,
        track: AffirmationTrack? = nil,
        levelOverride: Int? = nil,
        enabledCategories: [AffirmationCategory]? = nil,
        healthySexualityEnabled: Bool? = nil,
        audioAutoPlay: Bool? = nil,
        cloudAudioSync: Bool? = nil
    ) {
        self.morningTime = morningTime
        self.eveningTime = eveningTime
        self.track = track
        self.levelOverride = levelOverride
        self.enabledCategories = enabledCategories
        self.healthySexualityEnabled = healthySexualityEnabled
        self.audioAutoPlay = audioAutoPlay
        self.cloudAudioSync = cloudAudioSync
    }
}

// MARK: - Response Data Models

/// Morning session data (the inner `data` envelope content).
struct MorningSessionData: Codable, Sendable {
    let sessionId: String
    let sessionType: AffirmationSessionType?
    let affirmations: [AffirmationItem]
    let intentionPrompt: String?
    let createdAt: Date?
}

/// Evening session data.
struct EveningSessionData: Codable, Sendable {
    let sessionId: String
    let sessionType: AffirmationSessionType?
    let affirmation: AffirmationItem
    let morningIntention: String?
    let ratingPrompt: String?
    let createdAt: Date?
}

/// SOS session data.
struct SOSSessionData: Codable, Sendable {
    let sosId: String
    let affirmation: AffirmationItem
    let breathingExercise: BreathingExercise
    let additionalAffirmations: [AffirmationItem]
    let createdAt: Date?
}

/// Session completion confirmation data.
struct SessionCompletionData: Codable, Sendable {
    let sessionId: String
    let sessionType: AffirmationSessionType?
    let completedAt: Date?
    let totalSessions: Int?
    let milestone: AffirmationMilestone?
}

/// Favorite action confirmation data.
struct FavoriteActionData: Codable, Sendable {
    let affirmationId: String
    let favoritedAt: Date?
}

/// Hide action confirmation data.
struct HideActionData: Codable, Sendable {
    let affirmationId: String
    let hiddenAt: Date?
    let replacement: AffirmationItem?
}

/// Sharing summary data (privacy-safe, counts only).
struct SharingSummaryData: Codable, Sendable {
    let sessionsThisWeek: Int?
    let sessionsThisMonth: Int?
    let totalSessions: Int?
    let lastSessionAt: Date?
}

// MARK: - Response Envelopes

/// Generic data response envelope matching Siemens pattern.
struct AffirmationDataResponse<T: Codable & Sendable>: Codable, Sendable {
    let data: T
    let meta: AffirmationResponseMeta?
}

/// Paginated list response with cursor-based pagination.
struct AffirmationListResponse<T: Codable & Sendable>: Codable, Sendable {
    let data: [T]
    let links: AffirmationPaginationLinks?
    let meta: AffirmationListMeta?
}

/// Pagination links.
struct AffirmationPaginationLinks: Codable, Sendable {
    let `self`: String?
    let next: String?
    let prev: String?
    let first: String?
    let last: String?

    enum CodingKeys: String, CodingKey {
        case `self`
        case next
        case prev
        case first
        case last
    }
}

/// Metadata for list responses.
struct AffirmationListMeta: Codable, Sendable {
    let page: AffirmationPageMeta?
    let totalCount: Int?
}

/// Page metadata for cursor-based pagination.
struct AffirmationPageMeta: Codable, Sendable {
    let nextCursor: String?
    let prevCursor: String?
    let limit: Int?
}

/// Generic response metadata.
struct AffirmationResponseMeta: Codable, Sendable {
    let createdAt: Date?
    let modifiedAt: Date?
    let generatedAt: Date?
    let evaluatedAt: Date?
}

/// Error response envelope.
struct AffirmationErrorResponse: Codable, Sendable {
    let errors: [AffirmationErrorObject]
}

/// Individual error object conforming to rr:0x000Axxxx codes.
struct AffirmationErrorObject: Codable, Sendable {
    let id: String?
    let code: String?
    let status: Int
    let title: String
    let detail: String?
    let correlationId: String?
    let source: AffirmationErrorSource?

    struct AffirmationErrorSource: Codable, Sendable {
        let pointer: String?
        let parameter: String?
    }
}

// MARK: - Level Override Direction

/// Direction for level override requests.
enum LevelOverrideDirection: String, Codable, Sendable {
    case upgrade
    case downgrade
}

// MARK: - Milestone Type

/// Known milestone categories.
enum AffirmationMilestoneType: String, Codable, Sendable {
    case sessionCount = "session-count"
    case firstCustom = "first-custom"
    case firstAudio = "first-audio"
    case firstSOS = "first-sos"
}

// MARK: - Level Change Trigger

/// What triggered a level change.
enum LevelChangeTrigger: String, Codable, Sendable {
    case auto
    case manualUpgrade = "manual-upgrade"
    case manualDowngrade = "manual-downgrade"
    case relapseReset = "relapse-reset"
}
