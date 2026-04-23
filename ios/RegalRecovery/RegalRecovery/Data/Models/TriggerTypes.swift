import SwiftUI

// MARK: - Trigger Category

enum TriggerCategory: String, CaseIterable, Codable, Identifiable {
    case threeIs
    case emotional
    case physical
    case environmental
    case relational
    case cognitive
    case spiritual
    case situational

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .threeIs: return String(localized: "The 3 I's")
        case .emotional: return String(localized: "Emotional")
        case .physical: return String(localized: "Physical")
        case .environmental: return String(localized: "Environmental")
        case .relational: return String(localized: "Relational")
        case .cognitive: return String(localized: "Cognitive")
        case .spiritual: return String(localized: "Spiritual")
        case .situational: return String(localized: "Situational")
        }
    }

    var icon: String {
        switch self {
        case .threeIs: return "exclamationmark.3"
        case .emotional: return "heart.fill"
        case .physical: return "figure.stand"
        case .environmental: return "mappin.and.ellipse"
        case .relational: return "person.2.fill"
        case .cognitive: return "brain.head.profile"
        case .spiritual: return "cross.fill"
        case .situational: return "calendar"
        }
    }

    var color: Color {
        switch self {
        case .threeIs: return Color(red: 0.698, green: 0.133, blue: 0.133)
        case .emotional: return Color(red: 0.345, green: 0.337, blue: 0.839)
        case .physical: return Color(red: 0.180, green: 0.573, blue: 0.545)
        case .environmental: return Color(red: 0.204, green: 0.580, blue: 0.353)
        case .relational: return Color(red: 0.878, green: 0.510, blue: 0.204)
        case .cognitive: return Color(red: 0.573, green: 0.318, blue: 0.710)
        case .spiritual: return Color(red: 0.804, green: 0.678, blue: 0.271)
        case .situational: return Color(red: 0.416, green: 0.478, blue: 0.588)
        }
    }

    var itemCount: Int {
        switch self {
        case .threeIs: return 3
        case .emotional: return 24
        case .physical: return 13
        case .environmental: return 17
        case .relational: return 18
        case .cognitive: return 17
        case .spiritual: return 13
        case .situational: return 18
        }
    }
}

// MARK: - Time of Day Slot

enum TimeOfDaySlot: String, CaseIterable, Codable, Identifiable {
    case earlyMorning
    case morning
    case afternoon
    case evening
    case lateNight

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .earlyMorning: return String(localized: "Early Morning")
        case .morning: return String(localized: "Morning")
        case .afternoon: return String(localized: "Afternoon")
        case .evening: return String(localized: "Evening")
        case .lateNight: return String(localized: "Late Night")
        }
    }

    var shortName: String {
        switch self {
        case .earlyMorning: return String(localized: "Early AM")
        case .morning: return String(localized: "AM")
        case .afternoon: return String(localized: "PM")
        case .evening: return String(localized: "Eve")
        case .lateNight: return String(localized: "Late")
        }
    }

    static func from(hour: Int) -> TimeOfDaySlot {
        switch hour {
        case 5..<8: return .earlyMorning
        case 8..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<22: return .evening
        default: return .lateNight
        }
    }
}

// MARK: - Risk Level

enum RiskLevel: String, CaseIterable, Codable, Identifiable {
    case low
    case moderate
    case high

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low: return String(localized: "Low")
        case .moderate: return String(localized: "Moderate")
        case .high: return String(localized: "High")
        }
    }

    var color: Color {
        switch self {
        case .low: return .rrSuccess
        case .moderate: return .orange
        case .high: return .rrDestructive
        }
    }

    static func from(intensity: Int) -> RiskLevel {
        switch intensity {
        case 1...3: return .low
        case 4...6: return .moderate
        case 7...10: return .high
        default: return .low
        }
    }
}

// MARK: - Log Depth

enum LogDepth: String, CaseIterable, Codable, Identifiable {
    case quick
    case standard
    case deep

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .quick: return String(localized: "Quick")
        case .standard: return String(localized: "Standard")
        case .deep: return String(localized: "Deep")
        }
    }
}

// MARK: - Social Context

enum SocialContext: String, CaseIterable, Codable, Identifiable {
    case alone
    case spouse
    case family
    case friends
    case coworkers
    case strangers
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .alone: return String(localized: "Alone")
        case .spouse: return String(localized: "Spouse")
        case .family: return String(localized: "Family")
        case .friends: return String(localized: "Friends")
        case .coworkers: return String(localized: "Coworkers")
        case .strangers: return String(localized: "Strangers")
        case .other: return String(localized: "Other")
        }
    }
}

// MARK: - Location Category

enum LocationCategory: String, CaseIterable, Codable, Identifiable {
    case home
    case work
    case car
    case hotel
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .home: return String(localized: "Home")
        case .work: return String(localized: "Work")
        case .car: return String(localized: "Car")
        case .hotel: return String(localized: "Hotel")
        case .other: return String(localized: "Other")
        }
    }
}

// MARK: - Unmet Need

enum UnmetNeed: String, CaseIterable, Codable, Identifiable {
    case toBeHeard
    case toBeAffirmed
    case toBeBlessed
    case toBeSafe
    case toBeTouched
    case toBeChosen
    case toBeIncluded

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .toBeHeard: return String(localized: "To Be Heard")
        case .toBeAffirmed: return String(localized: "To Be Affirmed")
        case .toBeBlessed: return String(localized: "To Be Blessed")
        case .toBeSafe: return String(localized: "To Be Safe")
        case .toBeTouched: return String(localized: "To Be Touched")
        case .toBeChosen: return String(localized: "To Be Chosen")
        case .toBeIncluded: return String(localized: "To Be Included")
        }
    }

    var icon: String {
        switch self {
        case .toBeHeard: return "ear.fill"
        case .toBeAffirmed: return "hand.thumbsup.fill"
        case .toBeBlessed: return "sparkles"
        case .toBeSafe: return "shield.fill"
        case .toBeTouched: return "hand.raised.fill"
        case .toBeChosen: return "star.fill"
        case .toBeIncluded: return "person.3.fill"
        }
    }
}
