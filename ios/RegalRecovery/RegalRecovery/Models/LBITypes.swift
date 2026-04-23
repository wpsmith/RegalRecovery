import SwiftUI

// MARK: - LBI Dimension Type

enum LBIDimensionType: String, Codable, CaseIterable, Identifiable {
    case physicalHealth = "physical_health"
    case environment = "environment"
    case work = "work"
    case interests = "interests"
    case socialLife = "social_life"
    case familyAndSignificantOthers = "family_significant_others"
    case finances = "finances"
    case spiritualLife = "spiritual_life"
    case compulsiveBehaviors = "compulsive_behaviors"
    case recoveryPractice = "recovery_practice"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .physicalHealth: return String(localized: "Physical Health")
        case .environment: return String(localized: "Environment")
        case .work: return String(localized: "Work")
        case .interests: return String(localized: "Interests")
        case .socialLife: return String(localized: "Social Life")
        case .familyAndSignificantOthers: return String(localized: "Family, Relationships & Significant Others")
        case .finances: return String(localized: "Finances")
        case .spiritualLife: return String(localized: "Spiritual Life & Personal Reflection")
        case .compulsiveBehaviors: return String(localized: "Other Compulsive/Symptomatic Behaviors")
        case .recoveryPractice: return String(localized: "Recovery Practice & Therapeutic Self-Care")
        }
    }

    var shortName: String {
        switch self {
        case .physicalHealth: return String(localized: "Physical")
        case .environment: return String(localized: "Environment")
        case .work: return String(localized: "Work")
        case .interests: return String(localized: "Interests")
        case .socialLife: return String(localized: "Social")
        case .familyAndSignificantOthers: return String(localized: "Family")
        case .finances: return String(localized: "Finances")
        case .spiritualLife: return String(localized: "Spiritual")
        case .compulsiveBehaviors: return String(localized: "Compulsive")
        case .recoveryPractice: return String(localized: "Recovery")
        }
    }

    var icon: String {
        switch self {
        case .physicalHealth: return "heart.fill"
        case .environment: return "house.fill"
        case .work: return "briefcase.fill"
        case .interests: return "star.fill"
        case .socialLife: return "person.2.fill"
        case .familyAndSignificantOthers: return "figure.2.and.child"
        case .finances: return "dollarsign.circle.fill"
        case .spiritualLife: return "book.closed.fill"
        case .compulsiveBehaviors: return "exclamationmark.triangle.fill"
        case .recoveryPractice: return "cross.fill"
        }
    }

    var sortOrder: Int {
        switch self {
        case .physicalHealth: return 0
        case .environment: return 1
        case .work: return 2
        case .interests: return 3
        case .socialLife: return 4
        case .familyAndSignificantOthers: return 5
        case .finances: return 6
        case .spiritualLife: return 7
        case .compulsiveBehaviors: return 8
        case .recoveryPractice: return 9
        }
    }

    var isPositiveCategory: Bool { self == .interests }
}

// MARK: - LBI Risk Level

enum LBIRiskLevel: String, Codable, CaseIterable {
    case optimalHealth = "optimal_health"
    case stableSolidity = "stable_solidity"
    case mediumRisk = "medium_risk"
    case highRisk = "high_risk"
    case veryHighRisk = "very_high_risk"

    static func from(weeklyScore: Int) -> LBIRiskLevel {
        switch weeklyScore {
        case 0...9: return .optimalHealth
        case 10...19: return .stableSolidity
        case 20...29: return .mediumRisk
        case 30...39: return .highRisk
        default: return .veryHighRisk
        }
    }

    var displayName: String {
        switch self {
        case .optimalHealth: return String(localized: "Optimal Health")
        case .stableSolidity: return String(localized: "Stable Solidity")
        case .mediumRisk: return String(localized: "Medium Risk")
        case .highRisk: return String(localized: "High Risk")
        case .veryHighRisk: return String(localized: "Very High Risk")
        }
    }

    var color: Color {
        switch self {
        case .optimalHealth: return Color(red: 52/255, green: 199/255, blue: 89/255)
        case .stableSolidity: return Color(red: 0, green: 122/255, blue: 255/255)
        case .mediumRisk: return Color(red: 255/255, green: 149/255, blue: 0)
        case .highRisk: return Color(red: 255/255, green: 107/255, blue: 53/255)
        case .veryHighRisk: return Color(red: 255/255, green: 59/255, blue: 48/255)
        }
    }

    var description: String {
        switch self {
        case .optimalHealth: return String(localized: "Very resilient. Clear priorities, congruent with values, balanced and orderly.")
        case .stableSolidity: return String(localized: "Resilient. Recognizes limits, maintains boundaries, typically feels competent.")
        case .mediumRisk: return String(localized: "Often rushed, no emotional margin for crisis, vulnerable to old patterns.")
        case .highRisk: return String(localized: "Living in extremes, relationships strained, constantly catching up.")
        case .veryHighRisk: return String(localized: "Self-destructive patterns active, rarely following through, high relapse risk.")
        }
    }

    var scoreRange: ClosedRange<Int> {
        switch self {
        case .optimalHealth: return 0...9
        case .stableSolidity: return 10...19
        case .mediumRisk: return 20...29
        case .highRisk: return 30...39
        case .veryHighRisk: return 40...49
        }
    }
}

// MARK: - LBI Codable Types (stored as JSON in profile versions)

struct LBIDimension: Codable, Identifiable {
    var id: UUID
    var dimensionType: LBIDimensionType
    var indicators: [LBIIndicator]

    init(id: UUID = UUID(), dimensionType: LBIDimensionType, indicators: [LBIIndicator] = []) {
        self.id = id
        self.dimensionType = dimensionType
        self.indicators = indicators
    }
}

struct LBIIndicator: Codable, Identifiable {
    var id: UUID
    var text: String
    var isPositive: Bool

    init(id: UUID = UUID(), text: String, isPositive: Bool = false) {
        self.id = id
        self.text = text
        self.isPositive = isPositive
    }
}

struct LBICriticalItem: Codable, Identifiable {
    var id: UUID
    var dimensionType: LBIDimensionType
    var displayText: String
    var originalText: String
    var sortOrder: Int

    init(id: UUID = UUID(), dimensionType: LBIDimensionType, displayText: String, originalText: String, sortOrder: Int = 0) {
        self.id = id
        self.dimensionType = dimensionType
        self.displayText = displayText
        self.originalText = originalText
        self.sortOrder = sortOrder
    }
}
