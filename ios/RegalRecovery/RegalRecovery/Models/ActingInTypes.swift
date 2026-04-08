import Foundation
import SwiftData

// MARK: - Acting-In Behavior Types

/// Trigger types for acting-in behaviors.
enum ActingInTrigger: String, Codable, CaseIterable, Identifiable {
    case stress
    case conflict
    case fear
    case shame
    case exhaustion
    case loneliness
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .stress: return "Stress"
        case .conflict: return "Conflict"
        case .fear: return "Fear"
        case .shame: return "Shame"
        case .exhaustion: return "Exhaustion"
        case .loneliness: return "Loneliness"
        case .other: return "Other"
        }
    }
}

/// Relationship tags for who was affected.
enum ActingInRelationshipTag: String, Codable, CaseIterable, Identifiable {
    case spouse
    case child
    case coworker
    case friend
    case sponsor
    case selfTag = "self"
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .spouse: return "Spouse"
        case .child: return "Child"
        case .coworker: return "Coworker"
        case .friend: return "Friend"
        case .sponsor: return "Sponsor"
        case .selfTag: return "Self"
        case .other: return "Other"
        }
    }
}

/// Check-in frequency.
enum ActingInFrequency: String, Codable {
    case daily
    case weekly
}

/// Trend direction for insights.
enum ActingInTrend: String, Codable {
    case increasing
    case stable
    case decreasing
}

// MARK: - SwiftData Models

/// A single checked behavior within a check-in.
struct ActingInCheckedBehavior: Codable, Identifiable {
    var id: String { behaviorId }
    let behaviorId: String
    let behaviorName: String
    var contextNote: String?
    var trigger: ActingInTrigger?
    var relationshipTag: ActingInRelationshipTag?
}

/// Persistent model for an acting-in behavior (default or custom).
@Model
final class RRActingInBehavior {
    @Attribute(.unique) var behaviorId: String
    var name: String
    var behaviorDescription: String
    var isDefault: Bool
    var enabled: Bool
    var sortOrder: Int

    init(behaviorId: String, name: String, description: String = "",
         isDefault: Bool = true, enabled: Bool = true, sortOrder: Int = 0) {
        self.behaviorId = behaviorId
        self.name = name
        self.behaviorDescription = description
        self.isDefault = isDefault
        self.enabled = enabled
        self.sortOrder = sortOrder
    }
}

/// Persistent model for an acting-in check-in entry.
@Model
final class RRActingInCheckIn {
    @Attribute(.unique) var checkInId: String
    var userId: String
    var timestamp: Date
    var behaviorCount: Int
    var behaviorsData: Data? // JSON-encoded [ActingInCheckedBehavior]
    var consecutiveCheckIns: Int
    var message: String
    var synced: Bool
    var createdAt: Date

    init(checkInId: String = UUID().uuidString, userId: String, timestamp: Date = Date(),
         behaviorCount: Int = 0, behaviorsData: Data? = nil, consecutiveCheckIns: Int = 0,
         message: String = "", synced: Bool = false) {
        self.checkInId = checkInId
        self.userId = userId
        self.timestamp = timestamp
        self.behaviorCount = behaviorCount
        self.behaviorsData = behaviorsData
        self.consecutiveCheckIns = consecutiveCheckIns
        self.message = message
        self.synced = synced
        self.createdAt = Date()
    }

    var behaviors: [ActingInCheckedBehavior] {
        guard let data = behaviorsData else { return [] }
        return (try? JSONDecoder().decode([ActingInCheckedBehavior].self, from: data)) ?? []
    }
}

/// Persistent model for acting-in settings.
@Model
final class RRActingInSettings {
    @Attribute(.unique) var userId: String
    var frequency: String // "daily" or "weekly"
    var reminderTime: String // "HH:mm"
    var reminderDay: String // "sunday", "monday", etc.
    var firstUseCompleted: Bool
    var streakCount: Int
    var lastCheckInAt: Date?

    init(userId: String, frequency: String = "daily", reminderTime: String = "21:00",
         reminderDay: String = "sunday", firstUseCompleted: Bool = false,
         streakCount: Int = 0) {
        self.userId = userId
        self.frequency = frequency
        self.reminderTime = reminderTime
        self.reminderDay = reminderDay
        self.firstUseCompleted = firstUseCompleted
        self.streakCount = streakCount
    }
}

// MARK: - Default Behaviors

struct ActingInDefaults {
    static let behaviors: [(id: String, name: String, description: String)] = [
        ("beh_default_blame", "Blame", "Shifting responsibility onto others instead of owning your part"),
        ("beh_default_shame", "Shame", "Using shame (toward self or others) as a weapon or control mechanism"),
        ("beh_default_criticism", "Criticism", "Harsh, contemptuous, or demeaning comments toward others"),
        ("beh_default_stonewall", "Stonewall", "Shutting down emotionally, refusing to engage or communicate"),
        ("beh_default_avoid", "Avoid", "Dodging difficult conversations, people, or responsibilities"),
        ("beh_default_hide", "Hide", "Concealing information, activities, or feelings from others"),
        ("beh_default_lie", "Lie", "Telling outright falsehoods or lies of omission"),
        ("beh_default_excuse", "Excuse", "Rationalizing or minimizing harmful behavior"),
        ("beh_default_manipulate", "Manipulate", "Using emotional tactics to control outcomes or other people"),
        ("beh_default_control_anger", "Control with Anger", "Using rage, intimidation, or explosive emotion to dominate"),
        ("beh_default_passivity", "Passivity", "Withdrawing from engagement, letting others carry the weight"),
        ("beh_default_humor", "Humor", "Using jokes or sarcasm to deflect from serious topics or real feelings"),
        ("beh_default_placating", "Placating", "People-pleasing or false agreement to avoid conflict"),
        ("beh_default_withhold", "Withhold Love/Sex", "Punishing or controlling through emotional or physical withdrawal"),
        ("beh_default_hyperspiritualize", "HyperSpiritualize", "Using scripture, prayer, or faith language to avoid accountability or shut down valid concerns"),
    ]
}

// MARK: - Compassionate Messages

struct ActingInMessages {
    static let firstUseHelper = "Acting-in behaviors are the subtle ways addiction affects our relationships -- even when we're sober. Tracking them helps you see the full picture of your recovery, not just the absence of acting out."

    static let zeroBehaviors = "No acting-in behaviors today. That's growth worth noticing."

    static let rotatingMessages = [
        "Sobriety is more than not acting out. The work you're doing here is building real character.",
        "Noticing these patterns takes courage. You're becoming someone new.",
        "Every behavior you name loses a little power over you.",
    ]

    static func messageForCheckIn(behaviorCount: Int, streakCount: Int) -> String {
        if behaviorCount == 0 {
            return zeroBehaviors
        }
        let idx = streakCount % rotatingMessages.count
        return rotatingMessages[idx]
    }
}
