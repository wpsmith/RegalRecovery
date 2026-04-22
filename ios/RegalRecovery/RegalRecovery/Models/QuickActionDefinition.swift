import SwiftUI

struct QuickActionDefinition: Identifiable, Equatable {
    let id: String
    let displayName: String
    let icon: String
    let iconColor: Color
    let section: ActivitySection
    let featureFlagKey: String
    let presentationStyle: PresentationStyle

    enum PresentationStyle: Equatable {
        case navigationLink
        case fullScreenCover
    }
}

// MARK: - Catalog

extension QuickActionDefinition {

    static var all: [QuickActionDefinition] {
        var definitions = DailyEligibleActivity.all.map { activity in
            let color = ActivityType(rawValue: activity.activityType)?.iconColor ?? .rrPrimary
            return QuickActionDefinition(
                id: activity.activityType,
                displayName: activity.displayName,
                icon: activity.icon,
                iconColor: color,
                section: activity.section,
                featureFlagKey: activity.featureFlagKey,
                presentationStyle: .navigationLink
            )
        }

        // Override: FASTER Scale uses full-screen cover
        if let idx = definitions.firstIndex(where: { $0.id == ActivityType.fasterScale.rawValue }) {
            let original = definitions[idx]
            definitions[idx] = QuickActionDefinition(
                id: original.id,
                displayName: original.displayName,
                icon: original.icon,
                iconColor: original.iconColor,
                section: original.section,
                featureFlagKey: original.featureFlagKey,
                presentationStyle: .fullScreenCover
            )
        }

        // Activities not in DailyEligibleActivity but routable via ActivityDestinationView
        definitions.append(
            QuickActionDefinition(
                id: ActivityType.urgeLog.rawValue,
                displayName: String(localized: "Urge Log"),
                icon: "exclamationmark.triangle.fill",
                iconColor: .orange,
                section: .sobrietyCommitment,
                featureFlagKey: "activity.urge-logging",
                presentationStyle: .navigationLink
            )
        )

        definitions.append(
            QuickActionDefinition(
                id: ActivityType.postMortem.rawValue,
                displayName: String(localized: "Post-Mortem"),
                icon: "magnifyingglass.circle.fill",
                iconColor: .rrDestructive,
                section: .sobrietyCommitment,
                featureFlagKey: "activity.post-mortem",
                presentationStyle: .navigationLink
            )
        )

        definitions.append(
            QuickActionDefinition(
                id: ActivityType.stepWork.rawValue,
                displayName: String(localized: "12-Step Work"),
                icon: "list.number",
                iconColor: .rrSecondary,
                section: .growth,
                featureFlagKey: "activity.step-work",
                presentationStyle: .navigationLink
            )
        )

        definitions.append(
            QuickActionDefinition(
                id: "emotionalJournal",
                displayName: String(localized: "EmoJournal"),
                icon: "heart.text.square.fill",
                iconColor: .pink,
                section: .journalingReflection,
                featureFlagKey: "activity.emotional-journal",
                presentationStyle: .navigationLink
            )
        )

        return definitions
    }

    static var enabled: [QuickActionDefinition] {
        all.filter { FeatureFlagStore.shared.isEnabled($0.featureFlagKey) }
    }

    static var defaults: [QuickActionDefinition] {
        let defaultIds = [
            ActivityType.fasterScale.rawValue,
            ActivityType.urgeLog.rawValue,
            ActivityType.journal.rawValue,
            "emotionalJournal",
            ActivityType.prayer.rawValue,
            ActivityType.mood.rawValue,
            ActivityType.gratitude.rawValue,
        ]
        return defaultIds.compactMap { id in all.first(where: { $0.id == id }) }
    }

    static func find(_ id: String) -> QuickActionDefinition? {
        all.first(where: { $0.id == id })
    }
}
