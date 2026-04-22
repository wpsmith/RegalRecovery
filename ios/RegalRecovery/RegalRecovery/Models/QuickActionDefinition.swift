import SwiftUI

struct QuickActionDefinition: Identifiable, Equatable {
    let id: String
    let displayName: String
    let shortTitle: String
    let icon: String
    let iconColor: Color
    let section: ActivitySection
    let featureFlagKey: String
    let presentationStyle: PresentationStyle

    enum PresentationStyle: Equatable {
        case navigationLink
        case fullScreenCover
    }

    private static let shortTitles: [String: String] = [
        ActivityType.sobrietyCommitment.rawValue: "Commit",
        ActivityType.affirmationLog.rawValue: "Affirm",
        ActivityType.journal.rawValue: "Journal",
        "devotional": "Devotional",
        ActivityType.prayer.rawValue: "Pray",
        "memoryVerseReview": "Verse",
        ActivityType.mood.rawValue: "Mood",
        ActivityType.gratitude.rawValue: "Gratitude",
        ActivityType.phoneCalls.rawValue: "Calls",
        ActivityType.exercise.rawValue: "Exercise",
        ActivityType.meetingsAttended.rawValue: "Meetings",
        "personCheckInSpouse": "Spouse",
        ActivityType.fanos.rawValue: "FANOS",
        ActivityType.fitnap.rawValue: "FITNAP",
        ActivityType.fasterScale.rawValue: "FASTER",
        "pci": "PCI",
        ActivityType.weeklyGoals.rawValue: "Goals",
        "nutrition": "Nutrition",
        ActivityType.timeJournal.rawValue: "T30/60",
        "actingInBehaviors": "Acting In",
        "voiceJournal": "Voice",
        "bookReading": "Reading",
        ActivityType.urgeLog.rawValue: "Log Urge",
        ActivityType.postMortem.rawValue: "Post-Mortem",
        ActivityType.stepWork.rawValue: "12-Step",
        "emotionalJournal": "EmoJournal",
    ]
}

// MARK: - Catalog

extension QuickActionDefinition {

    static var all: [QuickActionDefinition] {
        var definitions = DailyEligibleActivity.all.map { activity in
            let color = ActivityType(rawValue: activity.activityType)?.iconColor ?? .rrPrimary
            return QuickActionDefinition(
                id: activity.activityType,
                displayName: activity.displayName,
                shortTitle: shortTitles[activity.activityType] ?? activity.displayName,
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
                shortTitle: original.shortTitle,
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
                shortTitle: shortTitles[ActivityType.urgeLog.rawValue] ?? "Log Urge",
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
                shortTitle: shortTitles[ActivityType.postMortem.rawValue] ?? "Post-Mortem",
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
                shortTitle: shortTitles[ActivityType.stepWork.rawValue] ?? "12-Step",
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
                shortTitle: shortTitles["emotionalJournal"] ?? "EmoJournal",
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
