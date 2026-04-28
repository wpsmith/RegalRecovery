import SwiftUI

enum QuadrantWeeklyReviewType: String, Codable, CaseIterable, Identifiable {
    case body = "body"
    case mind = "mind"
    case heart = "heart"
    case spirit = "spirit"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .body: return String(localized: "Body")
        case .mind: return String(localized: "Mind")
        case .heart: return String(localized: "Heart")
        case .spirit: return String(localized: "Spirit")
        }
    }

    var subtitle: String {
        switch self {
        case .body: return String(localized: "Physical Stewardship")
        case .mind: return String(localized: "Mental Renewal")
        case .heart: return String(localized: "Relational Connection")
        case .spirit: return String(localized: "Spiritual Vitality")
        }
    }

    var icon: String {
        switch self {
        case .body: return "figure.walk"
        case .mind: return "brain.head.profile"
        case .heart: return "heart.circle"
        case .spirit: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .body: return Color(.systemGreen)
        case .mind: return Color(.systemBlue)
        case .heart: return Color(.systemOrange)
        case .spirit: return Color(.systemPurple)
        }
    }

    var scriptureReference: String {
        switch self {
        case .body: return "1 Corinthians 6:19-20"
        case .mind: return "Romans 12:2"
        case .heart: return "Galatians 6:2"
        case .spirit: return "Psalm 42:1"
        }
    }

    var scriptureText: String {
        switch self {
        case .body:
            return String(localized: "Do you not know that your bodies are temples of the Holy Spirit, who is in you, whom you have received from God? You are not your own; you were bought at a price. Therefore honor God with your bodies.")
        case .mind:
            return String(localized: "Do not conform to the pattern of this world, but be transformed by the renewing of your mind. Then you will be able to test and approve what God's will is — his good, pleasing and perfect will.")
        case .heart:
            return String(localized: "Carry each other's burdens, and in this way you will fulfill the law of Christ.")
        case .spirit:
            return String(localized: "As the deer pants for streams of water, so my soul pants for you, my God. My soul thirsts for God, for the living God.")
        }
    }

    var description: String {
        switch self {
        case .body:
            return String(localized: "Honoring God by caring for your body — the temple of the Holy Spirit. Physical health, rest, nutrition, and energy.")
        case .mind:
            return String(localized: "Renewing your mind through learning, reflection, and emotional awareness. Mental health, clarity, and cognitive engagement.")
        case .heart:
            return String(localized: "Carrying each other's burdens through authentic relationship. Connection with others, accountability, and emotional honesty.")
        case .spirit:
            return String(localized: "Your soul thirsting for God. Prayer, scripture, worship, and awareness of God's presence in your recovery.")
        }
    }

    var behavioralIndicators: [String] {
        switch self {
        case .body:
            return [
                String(localized: "Exercised 3+ times this week"),
                String(localized: "Slept 7+ hours most nights"),
                String(localized: "Ate regular, balanced meals"),
                String(localized: "Took prescribed medications"),
                String(localized: "Felt physically energized"),
            ]
        case .mind:
            return [
                String(localized: "Engaged in learning or reading"),
                String(localized: "Managed stress without avoidance"),
                String(localized: "Processed emotions constructively"),
                String(localized: "Attended therapy or did therapeutic homework"),
                String(localized: "Felt mentally clear and focused"),
            ]
        case .heart:
            return [
                String(localized: "Talked honestly with sponsor or AP"),
                String(localized: "Attended a meeting or support group"),
                String(localized: "Had meaningful time with family"),
                String(localized: "Reached out to a friend"),
                String(localized: "Felt connected rather than isolated"),
            ]
        case .spirit:
            return [
                String(localized: "Prayed or had devotional time daily"),
                String(localized: "Read scripture this week"),
                String(localized: "Attended church or worship"),
                String(localized: "Practiced gratitude"),
                String(localized: "Felt God's presence or guidance"),
            ]
        }
    }

    var recommendedActivities: [(key: String, label: String)] {
        switch self {
        case .body:
            return [
                (key: "exercise", label: String(localized: "Exercise")),
                (key: "nutrition", label: String(localized: "Nutrition Check-in")),
            ]
        case .mind:
            return [
                (key: "journal", label: String(localized: "Journaling")),
                (key: "stepWork", label: String(localized: "Step Work")),
            ]
        case .heart:
            return [
                (key: "phoneCalls", label: String(localized: "Phone Calls")),
                (key: "fanos", label: String(localized: "FANOS Check-in")),
            ]
        case .spirit:
            return [
                (key: "prayer", label: String(localized: "Prayer")),
                (key: "affirmations", label: String(localized: "Declarations of Truth")),
            ]
        }
    }
}

enum WellnessLevel: String, Codable, CaseIterable {
    case flourishing = "flourishing"
    case growing = "growing"
    case rebuilding = "rebuilding"
    case struggling = "struggling"

    var displayName: String {
        switch self {
        case .flourishing: return String(localized: "Flourishing")
        case .growing: return String(localized: "Growing")
        case .rebuilding: return String(localized: "Rebuilding")
        case .struggling: return String(localized: "Struggling")
        }
    }

    var description: String {
        switch self {
        case .flourishing: return String(localized: "Your recovery is thriving across all dimensions. Keep nurturing each area.")
        case .growing: return String(localized: "You are making steady progress. Watch for areas that may need more attention.")
        case .rebuilding: return String(localized: "Some areas need strengthening. Focus on the recommendations below.")
        case .struggling: return String(localized: "Multiple areas need attention. Consider reaching out to your support network.")
        }
    }

    var color: Color {
        switch self {
        case .flourishing: return Color(.systemGreen)
        case .growing: return Color(.systemBlue)
        case .rebuilding: return Color(.systemOrange)
        case .struggling: return Color(.systemRed)
        }
    }
}
