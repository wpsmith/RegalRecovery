import Foundation
import SwiftUI

// MARK: - Gratitude Category

enum GratitudeCategory: String, Codable, CaseIterable, Identifiable {
    case faithGod = "Faith / God"
    case family = "Family"
    case relationships = "Relationships"
    case health = "Health"
    case recovery = "Recovery"
    case workCareer = "Work / Career"
    case natureBeauty = "Nature / Beauty"
    case smallMoments = "Small Moments"
    case growthProgress = "Growth / Progress"
    case custom = "Custom"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .faithGod: return "cross.fill"
        case .family: return "house.fill"
        case .relationships: return "person.2.fill"
        case .health: return "heart.fill"
        case .recovery: return "arrow.trianglehead.counterclockwise.rotate.90"
        case .workCareer: return "briefcase.fill"
        case .natureBeauty: return "leaf.fill"
        case .smallMoments: return "sparkle"
        case .growthProgress: return "chart.line.uptrend.xyaxis"
        case .custom: return "tag.fill"
        }
    }

    var color: Color {
        switch self {
        case .faithGod: return .rrPrimary
        case .family: return .rrDestructive
        case .relationships: return .rrSecondary
        case .health: return .rrSuccess
        case .recovery: return .rrPrimary
        case .workCareer: return .blue
        case .natureBeauty: return .green
        case .smallMoments: return .yellow
        case .growthProgress: return .purple
        case .custom: return .rrTextSecondary
        }
    }
}

// MARK: - Mood Icon

/// SF Symbol-based mood icons (no unicode emoji — avoids AppleColorEmoji font issues).
enum MoodIcon {
    static func symbolName(for score: Int) -> String {
        switch score {
        case 1: return "cloud.heavyrain.fill"
        case 2: return "cloud.fill"
        case 3: return "cloud.sun.fill"
        case 4: return "sun.max.fill"
        case 5: return "sun.max.trianglebadge.exclamationmark"  // radiant
        default: return "cloud.sun.fill"
        }
    }

    static func color(for score: Int) -> Color {
        switch score {
        case 1: return .rrDestructive
        case 2: return .orange
        case 3: return .rrTextSecondary
        case 4: return .rrSecondary
        case 5: return .rrSuccess
        default: return .rrTextSecondary
        }
    }

    static func label(for score: Int) -> String {
        switch score {
        case 1: return String(localized: "Very Low")
        case 2: return String(localized: "Low")
        case 3: return String(localized: "Neutral")
        case 4: return String(localized: "Good")
        case 5: return String(localized: "Great")
        default: return String(localized: "Neutral")
        }
    }
}

// MARK: - Gratitude Item

struct GratitudeItem: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var text: String
    var category: GratitudeCategory?
    var isFavorite: Bool = false
    var sortOrder: Int
}
