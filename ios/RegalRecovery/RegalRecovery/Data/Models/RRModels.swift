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
    var colorHex: String?
    var createdAt: Date
    var modifiedAt: Date

    var user: RRUser?

    @Relationship(deleteRule: .cascade, inverse: \RRStreak.addiction)
    var streaks: [RRStreak] = []

    @Relationship(deleteRule: .cascade, inverse: \RRMilestone.addiction)
    var milestones: [RRMilestone] = []

    @Relationship(deleteRule: .cascade, inverse: \RRRelapse.addiction)
    var relapses: [RRRelapse] = []

    static let defaultColors: [String] = [
        "#3B82F6", "#8B5CF6", "#F97316", "#EC4899", "#14B8A6", "#34D399",
        "#EF4444", "#F59E0B", "#6366F1", "#10B981", "#06B6D4", "#A855F7",
    ]

    init(
        id: UUID = UUID(),
        name: String,
        sobrietyDate: Date,
        userId: UUID,
        sortOrder: Int = 0,
        colorHex: String? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.sobrietyDate = sobrietyDate
        self.userId = userId
        self.sortOrder = sortOrder
        self.colorHex = colorHex
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
    var addictionId: UUID?  // Kept for backward compat (single addiction)
    var addictionIdsJSON: String?  // JSON-encoded [String] of UUID strings
    var triggers: [String]
    var notes: String
    var resolution: String
    var createdAt: Date
    var modifiedAt: Date

    /// Decoded addiction IDs from JSON storage. Falls back to single `addictionId` if JSON is absent.
    var addictionIds: [UUID] {
        get {
            if let json = addictionIdsJSON,
               let data = json.data(using: .utf8),
               let decoded = try? JSONDecoder().decode([String].self, from: data) {
                return decoded.compactMap { UUID(uuidString: $0) }
            }
            // Backward compat: fall back to single addictionId
            if let single = addictionId {
                return [single]
            }
            return []
        }
        set {
            let strings = newValue.map { $0.uuidString }
            if let data = try? JSONEncoder().encode(strings),
               let json = String(data: data, encoding: .utf8) {
                addictionIdsJSON = json
            }
            // Also keep addictionId in sync for backward compat
            addictionId = newValue.first
        }
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        date: Date,
        intensity: Int,
        addictionId: UUID? = nil,
        addictionIds: [UUID] = [],
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
        self.triggers = triggers
        self.notes = notes
        self.resolution = resolution
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt

        // If addictionIds provided, use them; otherwise fall back to single addictionId
        if !addictionIds.isEmpty {
            self.addictionId = addictionIds.first
            let strings = addictionIds.map { $0.uuidString }
            if let data = try? JSONEncoder().encode(strings),
               let json = String(data: data, encoding: .utf8) {
                self.addictionIdsJSON = json
            }
        } else {
            self.addictionId = addictionId
            if let single = addictionId {
                let strings = [single.uuidString]
                if let data = try? JSONEncoder().encode(strings),
                   let json = String(data: data, encoding: .utf8) {
                    self.addictionIdsJSON = json
                }
            }
        }
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

// MARK: - Quick Action Item

@Model
final class RRQuickActionItem {

    @Attribute(.unique) var id: UUID
    var activityType: String
    var sortOrder: Int
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        activityType: String,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.activityType = activityType
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - LBI Profile

@Model
final class RRLBIProfile {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var isActive: Bool
    var createdAt: Date
    var modifiedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \RRLBIProfileVersion.profile)
    var versions: [RRLBIProfileVersion] = []

    init(
        id: UUID = UUID(),
        userId: UUID,
        isActive: Bool = true,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.isActive = isActive
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - LBI Profile Version

@Model
final class RRLBIProfileVersion {

    @Attribute(.unique) var id: UUID
    var profileId: UUID
    var versionNumber: Int
    var effectiveFrom: Date
    var dimensionsJSON: String
    var criticalItemsJSON: String
    var createdAt: Date

    var profile: RRLBIProfile?

    /// Decoded dimensions from JSON storage.
    var dimensions: [LBIDimension] {
        get {
            guard let data = dimensionsJSON.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([LBIDimension].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                dimensionsJSON = json
            }
        }
    }

    /// Decoded critical items from JSON storage.
    var criticalItems: [LBICriticalItem] {
        get {
            guard let data = criticalItemsJSON.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([LBICriticalItem].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                criticalItemsJSON = json
            }
        }
    }

    init(
        id: UUID = UUID(),
        profileId: UUID,
        versionNumber: Int,
        dimensionsJSON: String = "[]",
        criticalItemsJSON: String = "[]",
        effectiveFrom: Date = Date(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.profileId = profileId
        self.versionNumber = versionNumber
        self.dimensionsJSON = dimensionsJSON
        self.criticalItemsJSON = criticalItemsJSON
        self.effectiveFrom = effectiveFrom
        self.createdAt = createdAt
    }
}

// MARK: - LBI Daily Entry

@Model
final class RRLBIDailyEntry {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var date: Date
    var profileVersionId: UUID
    var scoresJSON: String
    var totalScore: Int
    var isMissedDay: Bool
    var createdAt: Date
    var modifiedAt: Date

    /// Decoded scores from JSON storage. Maps indicator ID to Bool (pass/fail).
    var scores: [String: Bool] {
        get {
            guard let data = scoresJSON.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([String: Bool].self, from: data) else {
                return [:]
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                scoresJSON = json
            }
        }
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        date: Date,
        profileVersionId: UUID,
        scoresJSON: String = "{}",
        totalScore: Int = 0,
        isMissedDay: Bool = false,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = Calendar.current.startOfDay(for: date)
        self.profileVersionId = profileVersionId
        self.scoresJSON = scoresJSON
        self.totalScore = totalScore
        self.isMissedDay = isMissedDay
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Bowtie: User Roles

@Model
final class RRUserRole {
    @Attribute(.unique) var id: UUID
    var label: String
    var sortOrder: Int
    var isArchived: Bool
    var parentRoleId: UUID?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        label: String,
        sortOrder: Int,
        parentRoleId: UUID? = nil,
        isArchived: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.label = label
        self.sortOrder = sortOrder
        self.parentRoleId = parentRoleId
        self.isArchived = isArchived
        self.createdAt = createdAt
    }
}

// MARK: - Bowtie: Known Emotional Trigger

@Model
final class RRKnownEmotionalTrigger {
    @Attribute(.unique) var id: UUID
    var label: String
    var mappedITypeRaw: String?
    var createdAt: Date

    var mappedIType: ThreeIType? {
        get { mappedITypeRaw.flatMap { ThreeIType(rawValue: $0) } }
        set { mappedITypeRaw = newValue?.rawValue }
    }

    init(
        id: UUID = UUID(),
        label: String,
        mappedIType: ThreeIType? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.label = label
        self.mappedITypeRaw = mappedIType?.rawValue
        self.createdAt = createdAt
    }
}

// MARK: - Bowtie: Session

@Model
final class RRBowtieSession {
    @Attribute(.unique) var id: UUID
    var status: String
    var selectedRoleIds: [UUID]
    var emotionVocabularyRaw: String
    var entryPathRaw: String
    var sessionModeRaw: String
    var referenceTimestamp: Date
    var createdAt: Date
    var modifiedAt: Date
    var completedAt: Date?

    // Tallies
    var pastInsignificanceTotal: Int
    var pastIncompetenceTotal: Int
    var pastImpotenceTotal: Int
    var futureInsignificanceTotal: Int
    var futureIncompetenceTotal: Int
    var futureImpotenceTotal: Int

    @Relationship(deleteRule: .cascade, inverse: \RRBowtieMarker.session)
    var markers: [RRBowtieMarker] = []

    var vocabulary: EmotionVocabulary {
        get { EmotionVocabulary(rawValue: emotionVocabularyRaw) ?? .threeIs }
        set { emotionVocabularyRaw = newValue.rawValue }
    }

    var mode: BowtieSessionMode {
        get { BowtieSessionMode(rawValue: sessionModeRaw) ?? .guided }
        set { sessionModeRaw = newValue.rawValue }
    }

    var bowtieStatus: BowtieStatus {
        get { BowtieStatus(rawValue: status) ?? .draft }
        set { status = newValue.rawValue }
    }

    var pastMarkers: [RRBowtieMarker] {
        markers.filter { $0.side == BowtieSide.past.rawValue }
            .sorted { $0.timeIntervalHours > $1.timeIntervalHours }
    }

    var futureMarkers: [RRBowtieMarker] {
        markers.filter { $0.side == BowtieSide.future.rawValue }
            .sorted { $0.timeIntervalHours < $1.timeIntervalHours }
    }

    var processedMarkerCount: Int {
        markers.filter(\.isProcessed).count
    }

    init(
        id: UUID = UUID(),
        selectedRoleIds: [UUID] = [],
        emotionVocabulary: EmotionVocabulary = .threeIs,
        entryPath: BowtieEntryPath = .activities,
        sessionMode: BowtieSessionMode = .guided,
        referenceTimestamp: Date = Date(),
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.status = BowtieStatus.draft.rawValue
        self.selectedRoleIds = selectedRoleIds
        self.emotionVocabularyRaw = emotionVocabulary.rawValue
        self.entryPathRaw = entryPath.rawValue
        self.sessionModeRaw = sessionMode.rawValue
        self.referenceTimestamp = referenceTimestamp
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.pastInsignificanceTotal = 0
        self.pastIncompetenceTotal = 0
        self.pastImpotenceTotal = 0
        self.futureInsignificanceTotal = 0
        self.futureIncompetenceTotal = 0
        self.futureImpotenceTotal = 0
    }
}

// MARK: - Bowtie: Marker

@Model
final class RRBowtieMarker {
    @Attribute(.unique) var id: UUID
    var side: String
    var timeIntervalHours: Int
    var roleId: UUID
    var iActivations: [IActivation]
    var bigTicketEmotions: [BigTicketActivation]?
    var customEmotions: [String]?
    var knownTriggerIds: [UUID]?
    var briefDescription: String?
    var isProcessed: Bool
    var createdAt: Date

    var session: RRBowtieSession?

    var bowtieSide: BowtieSide {
        get { BowtieSide(rawValue: side) ?? .past }
        set { side = newValue.rawValue }
    }

    var totalIntensity: Int {
        iActivations.reduce(0) { $0 + $1.intensity } +
        (bigTicketEmotions ?? []).reduce(0) { $0 + $1.intensity }
    }

    init(
        id: UUID = UUID(),
        side: BowtieSide,
        timeIntervalHours: Int,
        roleId: UUID,
        iActivations: [IActivation] = [],
        bigTicketEmotions: [BigTicketActivation]? = nil,
        customEmotions: [String]? = nil,
        knownTriggerIds: [UUID]? = nil,
        briefDescription: String? = nil,
        isProcessed: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.side = side.rawValue
        self.timeIntervalHours = timeIntervalHours
        self.roleId = roleId
        self.iActivations = iActivations
        self.bigTicketEmotions = bigTicketEmotions
        self.customEmotions = customEmotions
        self.knownTriggerIds = knownTriggerIds
        self.briefDescription = briefDescription
        self.isProcessed = isProcessed
        self.createdAt = createdAt
    }
}

// MARK: - Bowtie: Backbone Processing

@Model
final class RRBackboneProcessing {
    @Attribute(.unique) var id: UUID
    var lifeSituation: String
    var emotions: [String]
    var threeIs: [IActivation]
    var emotionalNeeds: [String]
    var intimacyActions: [IntimacyAction]
    var spiritualReflection: String?
    var createdAt: Date

    var marker: RRBowtieMarker?

    init(
        id: UUID = UUID(),
        lifeSituation: String,
        emotions: [String] = [],
        threeIs: [IActivation] = [],
        emotionalNeeds: [String] = [],
        intimacyActions: [IntimacyAction] = [],
        spiritualReflection: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.lifeSituation = lifeSituation
        self.emotions = emotions
        self.threeIs = threeIs
        self.emotionalNeeds = emotionalNeeds
        self.intimacyActions = intimacyActions
        self.spiritualReflection = spiritualReflection
        self.createdAt = createdAt
    }
}

// MARK: - Bowtie: PPP Entry

@Model
final class RRPPPEntry {
    @Attribute(.unique) var id: UUID
    var prayer: String?
    var peopleContactIds: [UUID]?
    var planBefore: String?
    var planDuring: String?
    var planAfter: String?
    var reminderTime: Date?
    var outcome: PPPOutcome?
    var followUpReflection: String?
    var createdAt: Date

    var marker: RRBowtieMarker?

    init(
        id: UUID = UUID(),
        prayer: String? = nil,
        peopleContactIds: [UUID]? = nil,
        planBefore: String? = nil,
        planDuring: String? = nil,
        planAfter: String? = nil,
        reminderTime: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.prayer = prayer
        self.peopleContactIds = peopleContactIds
        self.planBefore = planBefore
        self.planDuring = planDuring
        self.planAfter = planAfter
        self.reminderTime = reminderTime
        self.createdAt = createdAt
    }
}

// MARK: - Post-Mortem Analysis

@Model
final class RRPostMortem {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var analysisId: String
    var timestamp: Date
    var modifiedAt: Date
    var createdAt: Date

    var status: String
    var eventType: String
    var relapseId: String?
    var addictionId: String?

    var triggerSummary: [String]
    var sectionsCompleted: [String]
    var sectionsRemaining: [String]
    var actionItemCount: Int

    var completedAt: Date?
    var synced: Bool

    // JSON-encoded complex types
    var sectionsData: Data?
    var triggerDetailsData: Data?
    var actionPlanData: Data?
    var sharingData: Data?
    var linkedEntitiesData: Data?

    var sections: PostMortemSectionsPayload? {
        get {
            guard let data = sectionsData else { return nil }
            return try? JSONDecoder().decode(PostMortemSectionsPayload.self, from: data)
        }
        set {
            sectionsData = try? JSONEncoder().encode(newValue)
        }
    }

    var triggerDetails: [TriggerDetailPayload] {
        get {
            guard let data = triggerDetailsData else { return [] }
            return (try? JSONDecoder().decode([TriggerDetailPayload].self, from: data)) ?? []
        }
        set {
            triggerDetailsData = try? JSONEncoder().encode(newValue)
        }
    }

    var actionPlan: [ActionPlanItemPayload] {
        get {
            guard let data = actionPlanData else { return [] }
            return (try? JSONDecoder().decode([ActionPlanItemPayload].self, from: data)) ?? []
        }
        set {
            actionPlanData = try? JSONEncoder().encode(newValue)
        }
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        analysisId: String,
        timestamp: Date,
        eventType: String,
        relapseId: String? = nil,
        addictionId: String? = nil,
        status: String = "draft",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.analysisId = analysisId
        self.timestamp = timestamp
        self.eventType = eventType
        self.relapseId = relapseId
        self.addictionId = addictionId
        self.status = status
        self.triggerSummary = []
        self.sectionsCompleted = []
        self.sectionsRemaining = []
        self.actionItemCount = 0
        self.synced = false
        self.createdAt = createdAt
        self.modifiedAt = createdAt
    }
}

// MARK: - Recovery Quadrant Assessment

@Model
final class RRQuadrantAssessment {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var weekStartDate: Date
    var isoWeekNumber: Int
    var isoYear: Int
    var bodyScore: Int
    var mindScore: Int
    var heartScore: Int
    var spiritScore: Int
    var balanceScore: Double
    var wellnessLevel: String
    var bodyIndicatorsJSON: String
    var mindIndicatorsJSON: String
    var heartIndicatorsJSON: String
    var spiritIndicatorsJSON: String
    var bodyReflection: String?
    var mindReflection: String?
    var heartReflection: String?
    var spiritReflection: String?
    var imbalancedQuadrantsJSON: String
    var createdAt: Date
    var modifiedAt: Date
    var needsSync: Bool

    init(userId: UUID, weekStartDate: Date) {
        self.id = UUID()
        self.userId = userId
        self.weekStartDate = weekStartDate
        let calendar = Calendar(identifier: .iso8601)
        let components = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: weekStartDate)
        self.isoWeekNumber = components.weekOfYear ?? 0
        self.isoYear = components.yearForWeekOfYear ?? 0
        self.bodyScore = 5
        self.mindScore = 5
        self.heartScore = 5
        self.spiritScore = 5
        self.balanceScore = 0
        self.wellnessLevel = WellnessLevel.growing.rawValue
        self.bodyIndicatorsJSON = "[]"
        self.mindIndicatorsJSON = "[]"
        self.heartIndicatorsJSON = "[]"
        self.spiritIndicatorsJSON = "[]"
        self.imbalancedQuadrantsJSON = "[]"
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.needsSync = true
    }

    var bodyIndicators: [String] {
        get { (try? JSONDecoder().decode([String].self, from: Data(bodyIndicatorsJSON.utf8))) ?? [] }
        set { bodyIndicatorsJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]" }
    }
    var mindIndicators: [String] {
        get { (try? JSONDecoder().decode([String].self, from: Data(mindIndicatorsJSON.utf8))) ?? [] }
        set { mindIndicatorsJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]" }
    }
    var heartIndicators: [String] {
        get { (try? JSONDecoder().decode([String].self, from: Data(heartIndicatorsJSON.utf8))) ?? [] }
        set { heartIndicatorsJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]" }
    }
    var spiritIndicators: [String] {
        get { (try? JSONDecoder().decode([String].self, from: Data(spiritIndicatorsJSON.utf8))) ?? [] }
        set { spiritIndicatorsJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]" }
    }
    var imbalancedQuadrants: [QuadrantType] {
        get {
            let raw = (try? JSONDecoder().decode([String].self, from: Data(imbalancedQuadrantsJSON.utf8))) ?? []
            return raw.compactMap { QuadrantType(rawValue: $0) }
        }
        set { imbalancedQuadrantsJSON = (try? String(data: JSONEncoder().encode(newValue.map(\.rawValue)), encoding: .utf8)) ?? "[]" }
    }
    var wellnessLevelEnum: WellnessLevel {
        WellnessLevel(rawValue: wellnessLevel) ?? .growing
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
        RRQuickActionItem.self,
        RRLBIProfile.self,
        RRLBIProfileVersion.self,
        RRLBIDailyEntry.self,
        RRMotivation.self,
        RRMotivationHistory.self,
        RRUserRole.self,
        RRKnownEmotionalTrigger.self,
        RRBowtieSession.self,
        RRBowtieMarker.self,
        RRBackboneProcessing.self,
        RRPPPEntry.self,
        RRTriggerDefinition.self,
        RRTriggerLogEntry.self,
        RRPostMortem.self,
        RRQuadrantAssessment.self,
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
            // Schema migration failed — delete the store and recreate.
            if !inMemory {
                let fm = FileManager.default
                let storePath = config.url.path()
                for suffix in ["", "-wal", "-shm"] {
                    try? fm.removeItem(atPath: storePath + suffix)
                }
                UserDefaults.standard.removeObject(forKey: SeedData.seedKey)
                UserDefaults.standard.removeObject(forKey: "com.regalrecovery.flagsSeeded")
            }
            return try ModelContainer(for: schema, configurations: [config])
        }
    }
}
