import Foundation
import SwiftUI

// MARK: - Motivation Category

enum MotivationCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case spiritual = "Spiritual"
    case relational = "Relational"
    case health = "Health"
    case professional = "Professional"
    case personalGrowth = "Personal Growth"
    case financial = "Financial"
    case community = "Community"
    case parenting = "Parenting"
    case identity = "Identity"
    case freedom = "Freedom"
    case legacy = "Legacy"
    case education = "Education"
    case service = "Service"
    case sexuality = "Sexuality"
    case creativity = "Creativity"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .spiritual: return String(localized: "Spiritual")
        case .relational: return String(localized: "Relational")
        case .health: return String(localized: "Health")
        case .professional: return String(localized: "Professional")
        case .personalGrowth: return String(localized: "Personal Growth")
        case .financial: return String(localized: "Financial")
        case .community: return String(localized: "Community")
        case .parenting: return String(localized: "Parenting")
        case .identity: return String(localized: "Identity")
        case .freedom: return String(localized: "Freedom")
        case .legacy: return String(localized: "Legacy")
        case .education: return String(localized: "Education")
        case .service: return String(localized: "Service")
        case .sexuality: return String(localized: "Sexuality")
        case .creativity: return String(localized: "Creativity")
        }
    }

    var icon: String {
        switch self {
        case .spiritual: return "hands.and.sparkles"
        case .relational: return "heart.fill"
        case .health: return "figure.walk"
        case .professional: return "briefcase.fill"
        case .personalGrowth: return "leaf.fill"
        case .financial: return "banknote.fill"
        case .community: return "person.3.fill"
        case .parenting: return "figure.and.child.holdinghands"
        case .identity: return "person.fill"
        case .freedom: return "bird.fill"
        case .legacy: return "tree.fill"
        case .education: return "book.fill"
        case .service: return "hand.raised.fill"
        case .sexuality: return "heart.circle.fill"
        case .creativity: return "paintbrush.fill"
        }
    }

    var color: Color {
        switch self {
        case .spiritual: return .rrPrimary
        case .relational: return .rrDestructive
        case .health: return .rrSuccess
        case .professional: return .blue
        case .personalGrowth: return .purple
        case .financial: return .green
        case .community: return .teal
        case .parenting: return .pink
        case .identity: return .indigo
        case .freedom: return .cyan
        case .legacy: return .brown
        case .education: return .mint
        case .service: return .yellow
        case .sexuality: return Color(red: 0.831, green: 0.220, blue: 0.353)
        case .creativity: return Color(red: 0.976, green: 0.733, blue: 0.176)
        }
    }
}

// MARK: - Motivation Source

enum MotivationSource: String, Codable, Sendable {
    case discovery
    case manual
}

// MARK: - Importance Labels

enum MotivationImportance {
    static let labels: [Int: String] = [
        1: String(localized: "Meaningful"),
        2: String(localized: "Important"),
        3: String(localized: "Very Important"),
        4: String(localized: "Core to My Recovery"),
        5: String(localized: "Non-Negotiable"),
    ]

    static let defaultRating: Int = 3
    static let range: ClosedRange<Int> = 1...5

    static func label(for rating: Int) -> String {
        labels[rating] ?? labels[3]!
    }
}

// MARK: - Discovery Steps

enum MotivationDiscoveryStep: Int, CaseIterable {
    case intro = 0
    case valuesSelection
    case concretePrompts
    case summary

    var title: String {
        switch self {
        case .intro: return String(localized: "Welcome")
        case .valuesSelection: return String(localized: "Values")
        case .concretePrompts: return String(localized: "Your Why")
        case .summary: return String(localized: "Review")
        }
    }

    static let totalSteps = 4

    var progressFraction: Double {
        Double(rawValue + 1) / Double(Self.totalSteps)
    }
}

// MARK: - Surfacing Context

enum SurfacingContext: String, Codable, Sendable {
    case urgeLog
    case sosFlow
    case moodCheckIn
    case fasterScale
    case eveningReview
    case milestone
    case sobrietyReset
    case morningCommitment
    case postMortem

    var prioritizedCategories: [MotivationCategory] {
        switch self {
        case .urgeLog, .sosFlow: return [.relational, .spiritual, .parenting, .freedom]
        case .moodCheckIn: return [.spiritual, .health, .identity]
        case .fasterScale: return [.personalGrowth, .spiritual, .identity, .freedom]
        case .milestone: return []
        case .sobrietyReset: return [.spiritual, .relational, .freedom]
        case .morningCommitment, .eveningReview, .postMortem: return []
        }
    }
}

// MARK: - Motivation Change Type

enum MotivationChangeType: String, Codable, Sendable {
    case created
    case textEdited
    case importanceChanged
    case categoryChanged
    case scriptureChanged
    case archived
    case restored
    case deleted
}

// MARK: - Limits

enum MotivationLimits {
    static let maxTextLength = 500
    static let maxScriptureLength = 200
    static let surfacingCooldownHours = 24
    static let freeLibraryLimit = 10
}
