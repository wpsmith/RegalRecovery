import SwiftUI

// MARK: - Bowtie Status

enum BowtieStatus: String, Codable, CaseIterable {
    case draft
    case complete

    var displayName: String {
        switch self {
        case .draft: return String(localized: "Draft")
        case .complete: return String(localized: "Complete")
        }
    }

    var icon: String {
        switch self {
        case .draft: return "pencil.circle"
        case .complete: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Bowtie Side

enum BowtieSide: String, Codable, CaseIterable {
    case past
    case future

    var displayName: String {
        switch self {
        case .past: return String(localized: "Past 48 Hours")
        case .future: return String(localized: "Next 48 Hours")
        }
    }

    static let timeIntervals: [Int] = [1, 3, 6, 12, 24, 36, 48]

    func labelForInterval(_ hours: Int) -> String {
        switch self {
        case .past: return String(localized: "\(hours)h ago")
        case .future: return String(localized: "In \(hours)h")
        }
    }
}

// MARK: - Three I's

enum ThreeIType: String, Codable, CaseIterable, Identifiable {
    case insignificance
    case incompetence
    case impotence

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .insignificance: return String(localized: "Insignificance")
        case .incompetence: return String(localized: "Incompetence")
        case .impotence: return String(localized: "Impotence")
        }
    }

    var diagnosticQuestion: String {
        switch self {
        case .insignificance: return String(localized: "Do I matter?")
        case .incompetence: return String(localized: "Do I have what it takes?")
        case .impotence: return String(localized: "Do I have any control?")
        }
    }

    var color: Color {
        switch self {
        case .insignificance: return .blue
        case .incompetence: return .orange
        case .impotence: return .purple
        }
    }

    var icon: String {
        switch self {
        case .insignificance: return "person.slash"
        case .incompetence: return "xmark.shield"
        case .impotence: return "lock.fill"
        }
    }
}

// MARK: - Big Ticket Emotions

enum BigTicketEmotion: String, Codable, CaseIterable, Identifiable {
    case abandonment
    case loneliness
    case rejection
    case sorrow
    case neglect

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .abandonment: return String(localized: "Abandonment")
        case .loneliness: return String(localized: "Loneliness")
        case .rejection: return String(localized: "Rejection")
        case .sorrow: return String(localized: "Sorrow")
        case .neglect: return String(localized: "Neglect")
        }
    }

    var color: Color {
        switch self {
        case .abandonment: return .red
        case .loneliness: return .indigo
        case .rejection: return .blue
        case .sorrow: return .teal
        case .neglect: return .brown
        }
    }

    var icon: String {
        switch self {
        case .abandonment: return "figure.walk.departure"
        case .loneliness: return "person.slash"
        case .rejection: return "hand.raised.slash"
        case .sorrow: return "cloud.rain"
        case .neglect: return "eye.slash"
        }
    }

    var defaultIMapping: ThreeIType {
        switch self {
        case .abandonment: return .insignificance
        case .loneliness: return .insignificance
        case .rejection: return .insignificance
        case .sorrow: return .impotence
        case .neglect: return .insignificance
        }
    }
}

// MARK: - Emotion Vocabulary Mode

enum EmotionVocabulary: String, Codable, CaseIterable {
    case threeIs
    case bigTicket
    case combined

    var displayName: String {
        switch self {
        case .threeIs: return String(localized: "Three I's")
        case .bigTicket: return String(localized: "Big Ticket Emotions")
        case .combined: return String(localized: "Combined")
        }
    }
}

// MARK: - Entry Path

enum BowtieEntryPath: String, Codable {
    case activities
    case postRelapse
    case fasterScale
    case checkIn
}

// MARK: - Session Mode

enum BowtieSessionMode: String, Codable, CaseIterable {
    case guided
    case freeform

    var displayName: String {
        switch self {
        case .guided: return String(localized: "Guided")
        case .freeform: return String(localized: "Freeform")
        }
    }
}

// MARK: - Intimacy Category

enum IntimacyCategory: String, Codable, CaseIterable {
    case god
    case self_
    case others

    var displayName: String {
        switch self {
        case .god: return String(localized: "Intimacy with God")
        case .self_: return String(localized: "Intimacy with Self")
        case .others: return String(localized: "Intimacy with Others")
        }
    }

    var suggestedActions: [String] {
        switch self {
        case .god: return ["Prayer", "Scripture Reading", "Sermons", "Worship Music", "Read a Book"]
        case .self_: return ["Journal", "Exercise", "Speak Truth Over Yourself", "Make a Plan", "Quadrant Work", "Complete Bowtie"]
        case .others: return ["Connect with Wife/Partner", "Connect with Accountability Partner", "Text Your Group"]
        }
    }
}

// MARK: - PPP Outcome

enum PPPOutcome: String, Codable, CaseIterable {
    case better
    case expected
    case harder
    case reflectLater

    var displayName: String {
        switch self {
        case .better: return String(localized: "Better than expected")
        case .expected: return String(localized: "About what I anticipated")
        case .harder: return String(localized: "Harder than expected")
        case .reflectLater: return String(localized: "I'll reflect later")
        }
    }

    var icon: String {
        switch self {
        case .better: return "sun.max.fill"
        case .expected: return "equal.circle"
        case .harder: return "cloud.heavyrain"
        case .reflectLater: return "clock"
        }
    }
}

// MARK: - Embedded Codable Structs

struct IActivation: Codable, Hashable, Identifiable {
    var id: String { iType.rawValue }
    let iType: ThreeIType
    var intensity: Int
}

struct BigTicketActivation: Codable, Hashable, Identifiable {
    var id: String { emotion.rawValue }
    let emotion: BigTicketEmotion
    var intensity: Int
}

struct IntimacyAction: Codable, Hashable, Identifiable {
    var id: String { "\(category.rawValue)-\(label)" }
    let category: IntimacyCategory
    let label: String
    let isCustom: Bool
}

// MARK: - Backbone Emotions Vocabulary

enum BackboneEmotion: String, CaseIterable, Identifiable {
    case sad, frustrated, disappointed, rejected, devalued
    case anxious, overwhelmed, angry, lonely, ashamed
    case hopeless, fearful, embarrassed, helpless, invisible
    case defensive, numb

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Emotional Needs Vocabulary

enum EmotionalNeed: String, CaseIterable, Identifiable {
    case acceptance, affirmation, agency, belonging, comfort
    case compassion, connection, empathy, encouragement, forgiveness
    case grace, hope, love, peace, reassurance
    case respect, safety, security, understanding, validation

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Bowtie Completion Messages

enum BowtieCompletionMessages {
    static let messages: [String] = [
        String(localized: "You just practiced seeing yourself honestly. That's a recovery skill most people never develop."),
        String(localized: "The more you do this, the less the addiction can surprise you."),
        String(localized: "Knowing what's stirring in your heart is the beginning of freedom."),
        String(localized: "You've moved from reacting to understanding. That matters."),
        String(localized: "Self-intimacy is the antidote. You just practiced it."),
    ]

    static func random() -> String {
        messages.randomElement() ?? messages[0]
    }
}

// MARK: - Role Suggestions

enum RoleSuggestions {
    static let defaults: [String] = [
        "Christian", "Person of Faith",
        "Husband", "Wife", "Partner",
        "Father", "Mother", "Parent",
        "Son", "Daughter",
        "Brother", "Sister", "Sibling",
        "Friend",
        "Man in Recovery", "Woman in Recovery",
        "Coworker", "Employee",
        "Neighbor",
        "Coach", "Mentor",
        "Church Member",
        "Student",
    ]
}

// MARK: - Known Trigger Suggestions

enum KnownTriggerSuggestions {
    static let defaults: [String] = [
        "Rejection", "Failure", "Embarrassment",
        "Feeling Bullied", "Overwhelm", "Loneliness",
        "Being Controlled", "Feeling Stupid",
        "Being Overlooked", "Abandonment",
        "Conflict", "Criticism", "Disappointment",
    ]
}
