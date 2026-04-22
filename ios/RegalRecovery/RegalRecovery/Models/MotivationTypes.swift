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

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .spiritual: return String(localized: "Spiritual")
        case .relational: return String(localized: "Relational")
        case .health: return String(localized: "Health")
        case .professional: return String(localized: "Professional")
        case .personalGrowth: return String(localized: "Personal Growth")
        case .financial: return String(localized: "Financial")
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
    case miracleQuestion
    case valuesSelection
    case concretePrompts
    case summary

    var title: String {
        switch self {
        case .intro: return String(localized: "Welcome")
        case .miracleQuestion: return String(localized: "Imagine")
        case .valuesSelection: return String(localized: "Values")
        case .concretePrompts: return String(localized: "Your Why")
        case .summary: return String(localized: "Review")
        }
    }

    static let totalSteps = 5

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
        case .urgeLog, .sosFlow: return [.relational, .spiritual]
        case .moodCheckIn: return [.spiritual, .health]
        case .fasterScale: return [.personalGrowth, .spiritual]
        case .milestone: return []
        case .sobrietyReset: return [.spiritual, .relational]
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
    static let maxValuesSelection = 5
    static let surfacingCooldownHours = 24
    static let freeLibraryLimit = 10
}
