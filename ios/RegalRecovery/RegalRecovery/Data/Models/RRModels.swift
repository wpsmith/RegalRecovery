import Foundation
import SwiftData
import UIKit

// MARK: - Codable Helpers

/// Flexible JSON storage for per-entity structured data (check-in answers, step-work responses, etc.)
struct JSONPayload: Codable, Equatable {
    let data: [String: AnyCodableValue]

    init(_ data: [String: AnyCodableValue] = [:]) {
        self.data = data
    }

    init(_ dict: [String: Any]) {
        self.data = dict.compactMapValues { AnyCodableValue(from: $0) }
    }
}

/// Type-erased Codable value for flexible JSON payloads.
enum AnyCodableValue: Codable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([AnyCodableValue])
    case dictionary([String: AnyCodableValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let v = try? container.decode(Bool.self) {
            self = .bool(v)
        } else if let v = try? container.decode(Int.self) {
            self = .int(v)
        } else if let v = try? container.decode(Double.self) {
            self = .double(v)
        } else if let v = try? container.decode(String.self) {
            self = .string(v)
        } else if let v = try? container.decode([AnyCodableValue].self) {
            self = .array(v)
        } else if let v = try? container.decode([String: AnyCodableValue].self) {
            self = .dictionary(v)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .int(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        case .bool(let v): try container.encode(v)
        case .array(let v): try container.encode(v)
        case .dictionary(let v): try container.encode(v)
        case .null: try container.encodeNil()
        }
    }

    init?(from any: Any) {
        switch any {
        case let v as String: self = .string(v)
        case let v as Int: self = .int(v)
        case let v as Double: self = .double(v)
        case let v as Bool: self = .bool(v)
        default: return nil
        }
    }

    var boolValue: Bool? {
        if case .bool(let v) = self { return v }
        return nil
    }

    var intValue: Int? {
        if case .int(let v) = self { return v }
        return nil
    }

    var stringValue: String? {
        if case .string(let v) = self { return v }
        return nil
    }
}

// MARK: - User

@Model
final class RRUser {

    @Attribute(.unique) var id: UUID
    var name: String
    var email: String
    var birthYear: Int
    var gender: String
    var timezone: String
    var bibleVersion: String
    var motivations: [String]
    var avatarInitial: String
    var createdAt: Date
    var modifiedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \RRAddiction.user)
    var addictions: [RRAddiction] = []

    @Relationship(deleteRule: .cascade, inverse: \RRSupportContact.user)
    var supportContacts: [RRSupportContact] = []

    init(
        id: UUID = UUID(),
        name: String,
        email: String,
        birthYear: Int,
        gender: String,
        timezone: String,
        bibleVersion: String,
        motivations: [String] = [],
        avatarInitial: String,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.birthYear = birthYear
        self.gender = gender
        self.timezone = timezone
        self.bibleVersion = bibleVersion
        self.motivations = motivations
        self.avatarInitial = avatarInitial
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Addiction

@Model
final class RRAddiction {
    @Attribute(.unique) var id: UUID
    var name: String
    var sobrietyDate: Date
    var userId: UUID
    var sortOrder: Int = 0
    var createdAt: Date
    var modifiedAt: Date

    var user: RRUser?

    @Relationship(deleteRule: .cascade, inverse: \RRStreak.addiction)
    var streaks: [RRStreak] = []

    @Relationship(deleteRule: .cascade, inverse: \RRMilestone.addiction)
    var milestones: [RRMilestone] = []

    @Relationship(deleteRule: .cascade, inverse: \RRRelapse.addiction)
    var relapses: [RRRelapse] = []

    init(
        id: UUID = UUID(),
        name: String,
        sobrietyDate: Date,
        userId: UUID,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.sobrietyDate = sobrietyDate
        self.userId = userId
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Streak

@Model
final class RRStreak {
    @Attribute(.unique) var id: UUID
    var addictionId: UUID
    var longestStreak: Int
    var totalRelapses: Int
    var createdAt: Date
    var modifiedAt: Date

    var addiction: RRAddiction?

    /// Current days sober, computed from the addiction's sobriety date.
    var currentDays: Int {
        guard let addiction else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: addiction.sobrietyDate, to: Date()).day ?? 0)
    }

    init(
        id: UUID = UUID(),
        addictionId: UUID,
        longestStreak: Int = 0,
        totalRelapses: Int = 0,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.addictionId = addictionId
        self.longestStreak = longestStreak
        self.totalRelapses = totalRelapses
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Milestone

@Model
final class RRMilestone {

    @Attribute(.unique) var id: UUID
    var addictionId: UUID
    var days: Int
    var dateEarned: Date
    var scripture: String
    var createdAt: Date
    var modifiedAt: Date

    var addiction: RRAddiction?

    init(
        id: UUID = UUID(),
        addictionId: UUID,
        days: Int,
        dateEarned: Date,
        scripture: String,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.addictionId = addictionId
        self.days = days
        self.dateEarned = dateEarned
        self.scripture = scripture
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Relapse

@Model
final class RRRelapse {

    @Attribute(.unique) var id: UUID
    var addictionId: UUID
    var date: Date
    var notes: String
    var triggers: [String]
    var createdAt: Date
    var modifiedAt: Date

    var addiction: RRAddiction?

    init(
        id: UUID = UUID(),
        addictionId: UUID,
        date: Date,
        notes: String = "",
        triggers: [String] = [],
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.addictionId = addictionId
        self.date = date
        self.notes = notes
        self.triggers = triggers
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Activity (Calendar)

@Model
final class RRActivity {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var activityType: String
    var date: Date
    var timestamp: Date
    var data: JSONPayload
    var synced: Bool
    var createdAt: Date
    var modifiedAt: Date

    /// Sort key for calendar day queries: "yyyy-MM-dd"
    var daySortKey: String {
        let formatter = RRActivity.dayFormatter
        return formatter.string(from: date)
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    init(
        id: UUID = UUID(),
        userId: UUID,
        activityType: String,
        date: Date,
        timestamp: Date = Date(),
        data: JSONPayload = JSONPayload(),
        synced: Bool = false,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.activityType = activityType
        self.date = date
        self.timestamp = timestamp
        self.data = data
        self.synced = synced
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Check-In

@Model
final class RRCheckIn {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var date: Date
    var score: Int
    var answers: JSONPayload
    var synced: Bool
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        date: Date,
        score: Int,
        answers: JSONPayload = JSONPayload(),
        synced: Bool = false,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.score = score
        self.answers = answers
        self.synced = synced
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Journal Entry

@Model
final class RRJournalEntry {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var date: Date
    var mode: String  // "jotting", "freeform", "prompted", "structured"
    var content: String
    var richContent: String?
    var prompt: String?
    var isEphemeral: Bool
    var ephemeralExpiresAt: Date?
    var sourceBookId: String?
    var sourceChapterId: String?
    var sourceParagraphIndex: Int?
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        date: Date,
        mode: String,
        content: String,
        richContent: String? = nil,
        prompt: String? = nil,
        isEphemeral: Bool = false,
        ephemeralExpiresAt: Date? = nil,
        sourceBookId: String? = nil,
        sourceChapterId: String? = nil,
        sourceParagraphIndex: Int? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.mode = mode
        self.content = content
        self.richContent = richContent
        self.prompt = prompt
        self.isEphemeral = isEphemeral
        self.ephemeralExpiresAt = ephemeralExpiresAt
        self.sourceBookId = sourceBookId
        self.sourceChapterId = sourceChapterId
        self.sourceParagraphIndex = sourceParagraphIndex
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

extension RRJournalEntry {
    var attributedContent: NSAttributedString? {
        guard let data = richContent?.data(using: .utf8) else { return nil }
        return try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        )
    }

    func setRichContent(from attributedString: NSAttributedString) {
        let range = NSRange(location: 0, length: attributedString.length)
        if let rtfData = try? attributedString.data(from: range, documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]) {
            richContent = String(data: rtfData, encoding: .utf8)
        }
        content = attributedString.string
    }
}

// MARK: - Emotional Journal

@Model
final class RREmotionalJournal {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var date: Date
    var emotion: String
    var emotionColor: String
    var intensity: Int
    var activity: String
    var location: String
    var latitude: Double?
    var longitude: Double?
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        date: Date,
        emotion: String,
        emotionColor: String,
        intensity: Int,
        activity: String,
        location: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.emotion = emotion
        self.emotionColor = emotionColor
        self.intensity = intensity
        self.activity = activity
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Time Block

@Model
final class RRTimeBlock {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var date: Date
    var startHour: Int
    var startMinute: Int
    var durationMinutes: Int
    var activity: String
    var need: String
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        date: Date,
        startHour: Int,
        startMinute: Int,
        durationMinutes: Int,
        activity: String,
        need: String,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.startHour = startHour
        self.startMinute = startMinute
        self.durationMinutes = durationMinutes
        self.activity = activity
        self.need = need
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Urge Log

@Model
final class RRUrgeLog {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var date: Date
    var intensity: Int
    var addictionId: UUID?
    var triggers: [String]
    var notes: String
    var resolution: String
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        date: Date,
        intensity: Int,
        addictionId: UUID? = nil,
        triggers: [String] = [],
        notes: String = "",
        resolution: String = "",
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.intensity = intensity
        self.addictionId = addictionId
        self.triggers = triggers
        self.notes = notes
        self.resolution = resolution
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - FASTER Entry

@Model
final class RRFASTEREntry {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var date: Date
    var stage: Int  // -1 to 5 mapping to FASTERStage
    var moodScore: Int?  // 1-5 from mood prompt (optional for migration compatibility)
    var selectedIndicatorsJSON: String?  // JSON-encoded [String: [String]] (stage name → indicator labels)
    var journalInsight: String?  // "Ah-ha" field
    var journalWarning: String?  // "Uh-oh" field
    var journalFreeText: String?  // Optional free-text
    var createdAt: Date
    var modifiedAt: Date

    /// Decoded selected indicators from JSON storage.
    var selectedIndicators: [String] {
        get {
            guard let json = selectedIndicatorsJSON,
                  let data = json.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                selectedIndicatorsJSON = json
            }
        }
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        date: Date,
        stage: Int,
        moodScore: Int? = nil,
        selectedIndicatorsJSON: String? = nil,
        journalInsight: String? = nil,
        journalWarning: String? = nil,
        journalFreeText: String? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.stage = stage
        self.moodScore = moodScore
        self.selectedIndicatorsJSON = selectedIndicatorsJSON
        self.journalInsight = journalInsight
        self.journalWarning = journalWarning
        self.journalFreeText = journalFreeText
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt

        // Encode selectedIndicators to JSON
        if let data = try? JSONEncoder().encode(selectedIndicators),
           let json = String(data: data, encoding: .utf8) {
            self.selectedIndicatorsJSON = json
        } else {
            self.selectedIndicatorsJSON = "[]"
        }
    }
}

// MARK: - Mood Entry

@Model
final class RRMoodEntry {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var date: Date

    // Layer 1: Primary mood (required) — maps to MoodPrimary enum rawValue
    var primaryMood: String

    // Layer 2: Secondary emotion (optional)
    var secondaryEmotion: String?

    // Layer 3: Intensity, urge, context tags (optional)
    var intensity: Int?
    var urgeToActOut: Int?
    var contextTagsJSON: String?

    // Layer 4: Journal prompt response (optional)
    var journalPrompt: String?
    var journalResponse: String?

    // Kept for backward compat with score-based consumers
    var score: Int

    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        date: Date,
        primaryMood: String,
        secondaryEmotion: String? = nil,
        intensity: Int? = nil,
        urgeToActOut: Int? = nil,
        contextTagsJSON: String? = nil,
        journalPrompt: String? = nil,
        journalResponse: String? = nil,
        score: Int = 5,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.primaryMood = primaryMood
        self.secondaryEmotion = secondaryEmotion
        self.intensity = intensity
        self.urgeToActOut = urgeToActOut
        self.contextTagsJSON = contextTagsJSON
        self.journalPrompt = journalPrompt
        self.journalResponse = journalResponse
        self.score = score
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    var contextTags: [String] {
        guard let json = contextTagsJSON,
              let data = json.data(using: .utf8),
              let tags = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return tags
    }
}

// MARK: - Gratitude Entry

@Model
final class RRGratitudeEntry {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var date: Date
    var items: [GratitudeItem]
    var moodScore: Int?
    var photoLocalPath: String?
    var promptUsed: String?
    var isFavorite: Bool
    var createdAt: Date
    var modifiedAt: Date

    /// Entry is editable within 24 hours of creation.
    var isEditable: Bool {
        Date().timeIntervalSince(createdAt) < 86_400
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        date: Date,
        items: [GratitudeItem] = [],
        moodScore: Int? = nil,
        photoLocalPath: String? = nil,
        promptUsed: String? = nil,
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.items = items
        self.moodScore = moodScore
        self.photoLocalPath = photoLocalPath
        self.promptUsed = promptUsed
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Prayer Log

@Model
final class RRPrayerLog {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var date: Date
    var durationMinutes: Int
    var prayerType: String
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        date: Date,
        durationMinutes: Int,
        prayerType: String,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.durationMinutes = durationMinutes
        self.prayerType = prayerType
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Exercise Log

@Model
final class RRExerciseLog {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var date: Date
    var durationMinutes: Int
    var exerciseType: String
    var notes: String
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        date: Date,
        durationMinutes: Int,
        exerciseType: String,
        notes: String = "",
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.durationMinutes = durationMinutes
        self.exerciseType = exerciseType
        self.notes = notes
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Phone Call Log

@Model
final class RRPhoneCallLog {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var date: Date
    var contactName: String
    var contactRole: String
    var durationMinutes: Int
    var notes: String
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        date: Date,
        contactName: String,
        contactRole: String,
        durationMinutes: Int,
        notes: String = "",
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.contactName = contactName
        self.contactRole = contactRole
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Meeting Log

@Model
final class RRMeetingLog {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var date: Date
    var meetingName: String
    var durationMinutes: Int
    var notes: String
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        date: Date,
        meetingName: String,
        durationMinutes: Int,
        notes: String = "",
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.meetingName = meetingName
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Spouse Check-In

@Model
final class RRSpouseCheckIn {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var date: Date
    var framework: String  // "FANOS" or "FITNAP"
    var sections: JSONPayload
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        date: Date,
        framework: String,
        sections: JSONPayload = JSONPayload(),
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.framework = framework
        self.sections = sections
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Step Work

@Model
final class RRStepWork {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var stepNumber: Int
    var status: String  // "complete", "inProgress", "locked"
    var answers: JSONPayload
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        stepNumber: Int,
        status: String,
        answers: JSONPayload = JSONPayload(),
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.stepNumber = stepNumber
        self.status = status
        self.answers = answers
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Goal

@Model
final class RRGoal {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var title: String
    var dynamic: String  // "Spiritual", "Physical", "Emotional", "Intellectual", "Relational"
    var isComplete: Bool
    var weekStartDate: Date
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        title: String,
        dynamic: String,
        isComplete: Bool = false,
        weekStartDate: Date,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.dynamic = dynamic
        self.isComplete = isComplete
        self.weekStartDate = weekStartDate
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Commitment

@Model
final class RRCommitment {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var date: Date
    var type: String  // "morning" or "evening"
    var completedAt: Date?
    var answers: JSONPayload
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        date: Date,
        type: String,
        completedAt: Date? = nil,
        answers: JSONPayload = JSONPayload(),
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.type = type
        self.completedAt = completedAt
        self.answers = answers
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Support Contact

@Model
final class RRSupportContact {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var name: String
    var role: String  // "sponsor", "counselor", "spouse", "accountabilityPartner"
    var phone: String
    var addiction: String?
    var linkedDate: Date
    var createdAt: Date
    var modifiedAt: Date

    var user: RRUser?

    init(
        id: UUID = UUID(),
        userId: UUID,
        name: String,
        role: String,
        phone: String,
        addiction: String? = nil,
        linkedDate: Date,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.role = role
        self.phone = phone
        self.addiction = addiction
        self.linkedDate = linkedDate
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Feature Flag

@Model
final class RRFeatureFlag {

    @Attribute(.unique) var id: UUID
    var key: String
    var enabled: Bool
    var rolloutPercent: Double
    var flagDescription: String
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        key: String,
        enabled: Bool,
        rolloutPercent: Double = 100.0,
        flagDescription: String = "",
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.key = key
        self.enabled = enabled
        self.rolloutPercent = rolloutPercent
        self.flagDescription = flagDescription
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Affirmation Favorite

@Model
final class RRAffirmationFavorite {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var affirmationText: String
    var scripture: String
    var packName: String
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        affirmationText: String,
        scripture: String,
        packName: String,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.affirmationText = affirmationText
        self.scripture = scripture
        self.packName = packName
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Devotional Progress

@Model
final class RRDevotionalProgress {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var day: Int
    var completedAt: Date?
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        day: Int,
        completedAt: Date? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.day = day
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Sync Queue Item

@Model
final class RRSyncQueueItem {

    @Attribute(.unique) var id: String
    var entityType: String
    var entityId: UUID
    var action: String  // "create", "update", "delete"
    var payload: Data
    var retryCount: Int
    var createdAt: Date
    var modifiedAt: Date

    // Networking fields (used by SyncEngine for HTTP replay)
    var endpointPath: String
    var httpMethod: String
    var bodyData: Data?
    var conflictStrategy: String // "union", "earliest-date", "last-write-wins"
    var lastAttemptAt: Date?

    /// Init for repository-level sync queue items (entity-based).
    init(
        id: UUID = UUID(),
        entityType: String,
        entityId: UUID,
        action: String,
        payload: Data = Data(),
        retryCount: Int = 0,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id.uuidString
        self.entityType = entityType
        self.entityId = entityId
        self.action = action
        self.payload = payload
        self.retryCount = retryCount
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.endpointPath = ""
        self.httpMethod = "POST"
        self.bodyData = nil
        self.conflictStrategy = "last-write-wins"
        self.lastAttemptAt = nil
    }

    /// Init for network-level sync queue items (endpoint-based).
    init(
        endpointPath: String,
        httpMethod: String,
        bodyData: Data?,
        conflictStrategy: String
    ) {
        self.id = UUID().uuidString
        self.entityType = ""
        self.entityId = UUID()
        self.action = httpMethod
        self.payload = bodyData ?? Data()
        self.retryCount = 0
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.endpointPath = endpointPath
        self.httpMethod = httpMethod
        self.bodyData = bodyData
        self.conflictStrategy = conflictStrategy
        self.lastAttemptAt = nil
    }
}

// MARK: - Recovery Plan

@Model
final class RRRecoveryPlan {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var isActive: Bool
    var isPaused: Bool
    var pauseEndDate: Date?

    @Relationship(deleteRule: .cascade, inverse: \RRDailyPlanItem.plan)
    var items: [RRDailyPlanItem]?

    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        isActive: Bool = true,
        isPaused: Bool = false,
        pauseEndDate: Date? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.isActive = isActive
        self.isPaused = isPaused
        self.pauseEndDate = pauseEndDate
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Daily Plan Item

@Model
final class RRDailyPlanItem {

    @Attribute(.unique) var id: UUID
    var planId: UUID
    var activityType: String
    var scheduledHour: Int
    var scheduledMinute: Int
    var instanceIndex: Int
    var daysOfWeek: [Int]
    var isEnabled: Bool
    var sortOrder: Int = 0
    var createdAt: Date
    var modifiedAt: Date

    var plan: RRRecoveryPlan?

    init(
        id: UUID = UUID(),
        planId: UUID,
        activityType: String,
        scheduledHour: Int,
        scheduledMinute: Int,
        instanceIndex: Int = 0,
        daysOfWeek: [Int] = [],
        isEnabled: Bool = true,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.planId = planId
        self.activityType = activityType
        self.scheduledHour = scheduledHour
        self.scheduledMinute = scheduledMinute
        self.instanceIndex = instanceIndex
        self.daysOfWeek = daysOfWeek
        self.isEnabled = isEnabled
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Daily Score

@Model
final class RRDailyScore {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var date: Date
    var score: Int
    var totalPlanned: Int
    var totalCompleted: Int
    var morningCommitmentCompleted: Bool
    var breakdown: JSONPayload
    var createdAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        date: Date,
        score: Int,
        totalPlanned: Int,
        totalCompleted: Int,
        morningCommitmentCompleted: Bool,
        breakdown: JSONPayload = JSONPayload(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.score = score
        self.totalPlanned = totalPlanned
        self.totalCompleted = totalCompleted
        self.morningCommitmentCompleted = morningCommitmentCompleted
        self.breakdown = breakdown
        self.createdAt = createdAt
    }
}

// MARK: - Vision Statement

@Model
final class RRVisionStatement {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var identityStatement: String
    var visionBody: String
    var coreValues: [String]
    var scriptureReference: String?
    var scriptureText: String?
    var promptResponsesJSON: String?
    var version: Int
    var isCurrent: Bool
    var createdAt: Date
    var modifiedAt: Date

    var promptResponses: [String: String] {
        get {
            guard let json = promptResponsesJSON,
                  let data = json.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
                return [:]
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                promptResponsesJSON = json
            }
        }
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        identityStatement: String,
        visionBody: String = "",
        coreValues: [String] = [],
        scriptureReference: String? = nil,
        scriptureText: String? = nil,
        promptResponsesJSON: String? = nil,
        version: Int = 1,
        isCurrent: Bool = true,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.identityStatement = identityStatement
        self.visionBody = visionBody
        self.coreValues = coreValues
        self.scriptureReference = scriptureReference
        self.scriptureText = scriptureText
        self.promptResponsesJSON = promptResponsesJSON
        self.version = version
        self.isCurrent = isCurrent
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Model Container Configuration

enum RRModelConfiguration {
    static let allModels: [any PersistentModel.Type] = [
        RRUser.self,
        RRAddiction.self,
        RRStreak.self,
        RRMilestone.self,
        RRRelapse.self,
        RRActivity.self,
        RRCheckIn.self,
        RRJournalEntry.self,
        RREmotionalJournal.self,
        RRTimeBlock.self,
        RRTimeJournalEntry.self,
        RRUrgeLog.self,
        RRFASTEREntry.self,
        RRMoodEntry.self,
        RRGratitudeEntry.self,
        RRPrayerLog.self,
        RRExerciseLog.self,
        RRPhoneCallLog.self,
        RRMeetingLog.self,
        RRSpouseCheckIn.self,
        RRStepWork.self,
        RRGoal.self,
        RRCommitment.self,
        RRSupportContact.self,
        RRFeatureFlag.self,
        RRAffirmationFavorite.self,
        RRDevotionalProgress.self,
        RRSyncQueueItem.self,
        RRRecoveryPlan.self,
        RRDailyPlanItem.self,
        RRDailyScore.self,
        RRVisionStatement.self,
    ]

    static var schema: Schema {
        Schema(allModels)
    }

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let config = ModelConfiguration(
            "RegalRecovery",
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            allowsSave: true
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Schema migration failed (e.g., GratitudeEntry items type changed).
            // Delete the store and recreate — old data is lost but app doesn't crash.
            if !inMemory {
                let fm = FileManager.default
                let storePath = config.url.path()
                for suffix in ["", "-wal", "-shm"] {
                    try? fm.removeItem(atPath: storePath + suffix)
                }
            }
            return try ModelContainer(for: schema, configurations: [config])
        }
    }
}
