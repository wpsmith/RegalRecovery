import Foundation
import SwiftUI

// MARK: - Work Tile Category

enum WorkTileCategory: String, CaseIterable {
    case foundationTools = "Foundation Tools"
    case activities = "Activities"
    case tools = "Tools"
    case assessments = "Assessments"

    var displayName: String {
        switch self {
        case .foundationTools: return String(localized: "Foundation Tools")
        case .activities: return String(localized: "Activities")
        case .tools: return String(localized: "Tools")
        case .assessments: return String(localized: "Assessments")
        }
    }

    var icon: String {
        switch self {
        case .foundationTools: return "building.columns.fill"
        case .activities: return "figure.mind.and.body"
        case .tools: return "wrench.and.screwdriver.fill"
        case .assessments: return "clipboard.fill"
        }
    }
}

// MARK: - Work Tile Item

struct WorkTileItem: Identifiable {
    let id: String
    let title: String
    let icon: String
    let iconColor: Color
    let category: WorkTileCategory
    let featureFlagKey: String?
    let implemented: Bool
    /// Maps to an activity type string for navigation and status lookup
    let activityTypeKey: String?

    var isEnabled: Bool {
        guard implemented, let flagKey = featureFlagKey else { return implemented }
        return FeatureFlagStore.shared.isEnabled(flagKey)
    }
}

// MARK: - Tile Status

enum TileStatus {
    case completed
    case hasEntries(String)
    case none

    var checkmarkVisible: Bool {
        if case .completed = self { return true }
        return false
    }

    var subtitle: String? {
        switch self {
        case .completed: return nil
        case .hasEntries(let s): return s
        case .none: return nil
        }
    }
}

// MARK: - View Model

@Observable
class RecoveryWorkViewModel {

    // MARK: - All Work Tiles

    static let allTiles: [WorkTileItem] = {
        var tiles: [WorkTileItem] = []

        // ── Foundation Tools ──
        tiles.append(contentsOf: [
            WorkTileItem(
                id: "foundation.3circles",
                title: String(localized: "3 Circles"),
                icon: "circles.hexagongrid.fill",
                iconColor: .rrDestructive,
                category: .foundationTools,
                featureFlagKey: "feature.3circles",
                implemented: true,
                activityTypeKey: "threeCircles"
            ),
            WorkTileItem(
                id: "foundation.relapse-prevention",
                title: String(localized: "Relapse Prevention"),
                icon: "doc.text.magnifyingglass",
                iconColor: .orange,
                category: .foundationTools,
                featureFlagKey: nil,
                implemented: false,
                activityTypeKey: nil
            ),
            WorkTileItem(
                id: "foundation.vision",
                title: String(localized: "Vision Statement"),
                icon: "eye.fill",
                iconColor: .rrSecondary,
                category: .foundationTools,
                featureFlagKey: "feature.vision",
                implemented: true,
                activityTypeKey: "visionStatement"
            ),
            WorkTileItem(
                id: "foundation.support-network",
                title: String(localized: "Support Network"),
                icon: "person.2.fill",
                iconColor: .rrPrimary,
                category: .foundationTools,
                featureFlagKey: nil,
                implemented: true,
                activityTypeKey: "supportNetwork"
            ),
            WorkTileItem(
                id: "foundation.recovery-plan",
                title: String(localized: "My Recovery Plan"),
                icon: "calendar.badge.clock",
                iconColor: .rrSecondary,
                category: .foundationTools,
                featureFlagKey: nil,
                implemented: true,
                activityTypeKey: "recoveryPlan"
            ),
            WorkTileItem(
                id: "foundation.lbi",
                title: String(localized: "Life Balance"),
                icon: "checklist",
                iconColor: .orange,
                category: .foundationTools,
                featureFlagKey: "feature.lbi",
                implemented: true,
                activityTypeKey: "lbiFoundation"
            ),
        ])

        // ── Activities ──
        tiles.append(contentsOf: [
            WorkTileItem(
                id: "activity.backbone",
                title: String(localized: "Backbone"),
                icon: "shield.checkered",
                iconColor: .rrPrimary,
                category: .activities,
                featureFlagKey: nil,
                implemented: false,
                activityTypeKey: nil
            ),
            WorkTileItem(
                id: "activity.sobriety-commitment",
                title: String(localized: "Sobriety Commitment"),
                icon: "sun.max.fill",
                iconColor: .rrSecondary,
                category: .activities,
                featureFlagKey: "activity.sobriety-commitment",
                implemented: true,
                activityTypeKey: ActivityType.sobrietyCommitment.rawValue
            ),
            WorkTileItem(
                id: "activity.affirmations",
                title: String(localized: "Affirmations"),
                icon: "text.quote",
                iconColor: .rrPrimary,
                category: .activities,
                featureFlagKey: "activity.affirmations",
                implemented: true,
                activityTypeKey: ActivityType.affirmationLog.rawValue
            ),
            WorkTileItem(
                id: "activity.urge-logging",
                title: String(localized: "Urge Logging"),
                icon: "exclamationmark.triangle.fill",
                iconColor: .orange,
                category: .activities,
                featureFlagKey: "activity.urge-logging",
                implemented: true,
                activityTypeKey: ActivityType.urgeLog.rawValue
            ),
            WorkTileItem(
                id: "activity.journaling",
                title: String(localized: "Journaling"),
                icon: "note.text",
                iconColor: .purple,
                category: .activities,
                featureFlagKey: "activity.journaling",
                implemented: true,
                activityTypeKey: ActivityType.journal.rawValue
            ),
            WorkTileItem(
                id: "activity.emotional-journal",
                title: String(localized: "Emotional Journal"),
                icon: "heart.text.square.fill",
                iconColor: .pink,
                category: .activities,
                featureFlagKey: "activity.emotional-journal",
                implemented: true,
                activityTypeKey: "emotionalJournal"
            ),
            WorkTileItem(
                id: "activity.faster-scale",
                title: String(localized: "FASTER Scale"),
                icon: "gauge.with.needle",
                iconColor: .rrSuccess,
                category: .activities,
                featureFlagKey: "activity.faster-scale",
                implemented: true,
                activityTypeKey: ActivityType.fasterScale.rawValue
            ),
            WorkTileItem(
                id: "activity.time-journal",
                title: String(localized: "Time Journal"),
                icon: "clock.fill",
                iconColor: .purple,
                category: .activities,
                featureFlagKey: "activity.time-journal",
                implemented: true,
                activityTypeKey: ActivityType.timeJournal.rawValue
            ),
            WorkTileItem(
                id: "activity.fanos",
                title: String(localized: "FANOS"),
                icon: "heart.fill",
                iconColor: .pink,
                category: .activities,
                featureFlagKey: "activity.fanos",
                implemented: true,
                activityTypeKey: "fanos"
            ),
            WorkTileItem(
                id: "activity.fitnap",
                title: String(localized: "FITNAP"),
                icon: "heart.text.clipboard",
                iconColor: .pink,
                category: .activities,
                featureFlagKey: "activity.fitnap",
                implemented: true,
                activityTypeKey: "fitnap"
            ),
            WorkTileItem(
                id: "activity.lbi",
                title: String(localized: "Life Balance Check-In"),
                icon: "checklist.checked",
                iconColor: .orange,
                category: .activities,
                featureFlagKey: "feature.lbi",
                implemented: true,
                activityTypeKey: "lbi"
            ),
            WorkTileItem(
                id: "activity.meetings",
                title: String(localized: "Meetings"),
                icon: "person.3.fill",
                iconColor: .rrPrimary,
                category: .activities,
                featureFlagKey: "activity.meetings",
                implemented: true,
                activityTypeKey: ActivityType.meetingsAttended.rawValue
            ),
            WorkTileItem(
                id: "activity.post-mortem",
                title: String(localized: "Post-Mortem"),
                icon: "magnifyingglass.circle",
                iconColor: .rrDestructive,
                category: .tools,
                featureFlagKey: nil,
                implemented: false,
                activityTypeKey: nil
            ),
            WorkTileItem(
                id: "activity.step-work",
                title: String(localized: "12-Step Work"),
                icon: "stairs",
                iconColor: .rrPrimary,
                category: .tools,
                featureFlagKey: "activity.step-work",
                implemented: true,
                activityTypeKey: ActivityType.stepWork.rawValue
            ),
            WorkTileItem(
                id: "activity.goals",
                title: String(localized: "Weekly Goals"),
                icon: "target",
                iconColor: .rrSecondary,
                category: .activities,
                featureFlagKey: "activity.goals",
                implemented: true,
                activityTypeKey: ActivityType.weeklyGoals.rawValue
            ),
            WorkTileItem(
                id: "activity.devotionals",
                title: String(localized: "Devotional"),
                icon: "book.fill",
                iconColor: .brown,
                category: .activities,
                featureFlagKey: "activity.devotionals",
                implemented: true,
                activityTypeKey: "devotional"
            ),
            WorkTileItem(
                id: "activity.exercise",
                title: String(localized: "Exercise"),
                icon: "figure.run",
                iconColor: .rrSuccess,
                category: .activities,
                featureFlagKey: "activity.exercise",
                implemented: true,
                activityTypeKey: ActivityType.exercise.rawValue
            ),
            WorkTileItem(
                id: "activity.mood",
                title: String(localized: "Mood Rating"),
                icon: "face.smiling",
                iconColor: .yellow,
                category: .activities,
                featureFlagKey: "activity.mood",
                implemented: true,
                activityTypeKey: ActivityType.mood.rawValue
            ),
            WorkTileItem(
                id: "activity.gratitude",
                title: String(localized: "Gratitude"),
                icon: "leaf.fill",
                iconColor: .rrSuccess,
                category: .activities,
                featureFlagKey: "activity.gratitude",
                implemented: true,
                activityTypeKey: ActivityType.gratitude.rawValue
            ),
            WorkTileItem(
                id: "activity.phone-calls",
                title: String(localized: "Phone Calls"),
                icon: "phone.fill",
                iconColor: .rrPrimary,
                category: .activities,
                featureFlagKey: "activity.phone-calls",
                implemented: true,
                activityTypeKey: ActivityType.phoneCalls.rawValue
            ),
            WorkTileItem(
                id: "activity.prayer",
                title: String(localized: "Prayer"),
                icon: "hands.and.sparkles.fill",
                iconColor: .rrSecondary,
                category: .activities,
                featureFlagKey: "activity.prayer",
                implemented: true,
                activityTypeKey: ActivityType.prayer.rawValue
            ),
            WorkTileItem(
                id: "activity.integrity-inventory",
                title: String(localized: "Integrity Inventory"),
                icon: "checkmark.shield.fill",
                iconColor: .rrPrimary,
                category: .activities,
                featureFlagKey: "activity.integrity-inventory",
                implemented: true,
                activityTypeKey: "integrityInventory"
            ),
            WorkTileItem(
                id: "activity.memory-verse",
                title: String(localized: "Memory Verse"),
                icon: "text.book.closed.fill",
                iconColor: .brown,
                category: .tools,
                featureFlagKey: "activity.memory-verse",
                implemented: true,
                activityTypeKey: "memoryVerseReview"
            ),
            WorkTileItem(
                id: "activity.nutrition",
                title: String(localized: "Nutrition"),
                icon: "fork.knife",
                iconColor: .green,
                category: .activities,
                featureFlagKey: nil,
                implemented: false,
                activityTypeKey: nil
            ),
            WorkTileItem(
                id: "activity.acting-in-behaviors",
                title: String(localized: "Acting In Behaviors"),
                icon: "shield.lefthalf.filled",
                iconColor: .orange,
                category: .foundationTools,
                featureFlagKey: nil,
                implemented: false,
                activityTypeKey: nil
            ),
            WorkTileItem(
                id: "activity.book-reading",
                title: String(localized: "Recovery Reading"),
                icon: "book.fill",
                iconColor: .brown,
                category: .activities,
                featureFlagKey: nil,
                implemented: false,
                activityTypeKey: nil
            ),
        ])

        // ── Tools ──
        tiles.append(contentsOf: [
            WorkTileItem(
                id: "tool.urge-surfing",
                title: String(localized: "Urge Surfing Timer"),
                icon: "timer",
                iconColor: .orange,
                category: .tools,
                featureFlagKey: "feature.urge-surfing-timer",
                implemented: true,
                activityTypeKey: "urgeSurfingTimer"
            ),
            WorkTileItem(
                id: "tool.meeting-finder",
                title: String(localized: "Meeting Finder"),
                icon: "map.fill",
                iconColor: .rrPrimary,
                category: .tools,
                featureFlagKey: nil,
                implemented: false,
                activityTypeKey: nil
            ),
        ])

        // ── Assessments ──
        tiles.append(contentsOf: [
            WorkTileItem(
                id: "assessment.sast-r",
                title: String(localized: "SAST-R"),
                icon: "clipboard.fill",
                iconColor: .purple,
                category: .assessments,
                featureFlagKey: nil,
                implemented: false,
                activityTypeKey: nil
            ),
            WorkTileItem(
                id: "assessment.family-impact",
                title: String(localized: "Family Impact"),
                icon: "house.fill",
                iconColor: .rrPrimary,
                category: .assessments,
                featureFlagKey: nil,
                implemented: false,
                activityTypeKey: nil
            ),
            WorkTileItem(
                id: "assessment.denial",
                title: String(localized: "Denial Assessment"),
                icon: "eye.slash.fill",
                iconColor: .orange,
                category: .assessments,
                featureFlagKey: nil,
                implemented: false,
                activityTypeKey: nil
            ),
            WorkTileItem(
                id: "assessment.addiction-severity",
                title: String(localized: "Addiction Severity"),
                icon: "waveform.path.ecg",
                iconColor: .rrDestructive,
                category: .assessments,
                featureFlagKey: nil,
                implemented: false,
                activityTypeKey: nil
            ),
            WorkTileItem(
                id: "assessment.relationship-health",
                title: String(localized: "Relationship Health"),
                icon: "heart.circle.fill",
                iconColor: .pink,
                category: .assessments,
                featureFlagKey: nil,
                implemented: false,
                activityTypeKey: nil
            ),
        ])

        return tiles
    }()

    func tiles(for category: WorkTileCategory) -> [WorkTileItem] {
        Self.allTiles.filter { $0.category == category }
    }

    // MARK: - Today's Status

    /// Computes today's status for a tile given the queried data collections.
    static func todayStatus(
        for tile: WorkTileItem,
        commitments: [RRCommitment],
        journals: [RRJournalEntry],
        timeBlocks: [RRTimeBlock],
        fasterEntries: [RRFASTEREntry],
        urgeLogs: [RRUrgeLog],
        moodEntries: [RRMoodEntry],
        gratitudeEntries: [RRGratitudeEntry],
        prayerLogs: [RRPrayerLog],
        exerciseLogs: [RRExerciseLog],
        phoneCallLogs: [RRPhoneCallLog],
        meetingLogs: [RRMeetingLog],
        spouseCheckIns: [RRSpouseCheckIn],
        stepWork: [RRStepWork],
        goals: [RRGoal],
        affirmationSessions: [RRActivity] = []
    ) -> TileStatus {
        guard tile.implemented, tile.isEnabled else { return .none }

        let cal = Calendar.current

        switch tile.activityTypeKey {
        case ActivityType.sobrietyCommitment.rawValue:
            if commitments.contains(where: { $0.type == "morning" && cal.isDateInToday($0.date) }) {
                return .completed
            }
            return .none

        case ActivityType.affirmationLog.rawValue:
            let todayCount = affirmationSessions.filter { cal.isDateInToday($0.date) }.count
            if todayCount > 0 { return .completed }
            return .none

        case ActivityType.urgeLog.rawValue:
            let todayCount = urgeLogs.filter { cal.isDateInToday($0.date) }.count
            if todayCount > 0 { return .hasEntries("\(todayCount)") }
            return .none

        case ActivityType.journal.rawValue:
            let todayCount = journals.filter { cal.isDateInToday($0.date) }.count
            if todayCount > 0 { return .hasEntries("\(todayCount)") }
            return .none

        case ActivityType.fasterScale.rawValue:
            if let e = fasterEntries.first(where: { cal.isDateInToday($0.date) }) {
                let stage = FASTERStage(rawValue: e.stage) ?? .restoration
                return .hasEntries(stage.shortName)
            }
            return .none

        case ActivityType.timeJournal.rawValue:
            let todayCount = timeBlocks.filter { cal.isDateInToday($0.date) }.count
            if todayCount > 0 { return .hasEntries("\(todayCount)") }
            return .none

        case "fanos":
            if spouseCheckIns.first(where: { cal.isDateInToday($0.date) && $0.framework == "FANOS" }) != nil {
                return .completed
            }
            return .none

        case "fitnap":
            if spouseCheckIns.first(where: { cal.isDateInToday($0.date) && $0.framework == "FITNAP" }) != nil {
                return .completed
            }
            return .none

        case ActivityType.meetingsAttended.rawValue:
            let todayCount = meetingLogs.filter { cal.isDateInToday($0.date) }.count
            if todayCount > 0 { return .hasEntries("\(todayCount)") }
            return .none

        case ActivityType.stepWork.rawValue:
            if let inProgress = stepWork.first(where: { $0.status == "inProgress" }) {
                return .hasEntries("S\(inProgress.stepNumber)")
            }
            return .none

        case ActivityType.weeklyGoals.rawValue:
            let completed = goals.filter { $0.isComplete }.count
            if completed > 0 { return .hasEntries("\(completed)/\(goals.count)") }
            return .none

        case ActivityType.exercise.rawValue:
            if exerciseLogs.first(where: { cal.isDateInToday($0.date) }) != nil {
                return .completed
            }
            return .none

        case ActivityType.mood.rawValue:
            if let m = moodEntries.first(where: { cal.isDateInToday($0.date) }) {
                return .hasEntries("\(m.score)")
            }
            return .none

        case ActivityType.gratitude.rawValue:
            if let g = gratitudeEntries.first(where: { cal.isDateInToday($0.date) }) {
                return .hasEntries("\(g.items.count)")
            }
            return .none

        case ActivityType.phoneCalls.rawValue:
            let todayCount = phoneCallLogs.filter { cal.isDateInToday($0.date) }.count
            if todayCount > 0 { return .hasEntries("\(todayCount)") }
            return .none

        case ActivityType.prayer.rawValue:
            let todayPrayers = prayerLogs.filter { cal.isDateInToday($0.date) }.count
            if todayPrayers > 0 { return .hasEntries("\(todayPrayers)") }
            return .none

        case "emotionalJournal":
            return .none

        case ActivityType.postMortem.rawValue:
            return .none

        default:
            return .none
        }
    }

    // MARK: - Legacy (RecoveryWorkCardView compatibility)

    var dueNow: [RecoveryWorkItem] = []
    var thisWeek: [RecoveryWorkItem] = []
    var thisMonth: [RecoveryWorkItem] = []
    var completed: [RecoveryWorkItem] = []

    var timeJournalFilledCount: Int = 0
    var timeJournalTotalSlots: Int = 24
    var timeJournalDayStatus: TimeJournalDayStatus = .inProgress
    var timeJournalLastUpdated: Date? = nil
    var timeJournalInPlan: Bool = false

    private let calendar = Calendar.current

    private static let activityFlagMap: [String: String] = [
        "threeCirclesReview": "feature.3circles",
        "backboneReview": "feature.partners.redemptiveliving.backbone",
        "visionStatement": "feature.vision",
        "relapsePreventionPlan": "feature.relapse-prevention-plan",
        "postMortem": "feature.post-mortem",
        "assessment.sast-r": "assessment.sast-r",
        "timeJournal": "activity.time-journal",
    ]

    private func isWorkItemEnabled(_ item: RecoveryWorkItem) -> Bool {
        guard let flagKey = Self.activityFlagMap[item.activityType] else { return true }
        return FeatureFlagStore.shared.isEnabled(flagKey)
    }

    func load() {
        let now = Date()

        let threeCirclesLastReview = calendar.date(byAdding: .day, value: -62, to: now)!
        let sastRDueDate = calendar.date(byAdding: .day, value: 7, to: now)!
        let rppDueDate = calendar.date(byAdding: .day, value: 14, to: now)!
        let backboneDueDate = calendar.date(byAdding: .day, value: 5, to: now)!

        var timeJournalItems: [RecoveryWorkItem] = []
        if timeJournalInPlan {
            let timeJournalTriggerReason: String = {
                switch timeJournalDayStatus {
                case .inProgress:
                    return String(localized: "\(timeJournalFilledCount) of \(timeJournalTotalSlots) slots filled today")
                case .overdue:
                    return String(localized: "Some time slots have passed without entries")
                case .completed:
                    return String(localized: "All time slots filled for today")
                }
            }()

            timeJournalItems.append(RecoveryWorkItem(
                activityType: "timeJournal",
                title: String(localized: "Time Journal"),
                triggerReason: timeJournalTriggerReason,
                dueDate: calendar.startOfDay(for: now).addingTimeInterval(24 * 60 * 60 - 1),
                priority: .high,
                status: timeJournalDayStatus.workStatus,
                icon: "clock.fill",
                iconColor: .purple
            ))
        }

        dueNow = timeJournalItems + [
            RecoveryWorkItem(
                activityType: "threeCirclesReview",
                title: String(localized: "3 Circles Review"),
                triggerReason: String(localized: "Last reviewed 62 days ago -- quarterly review recommended"),
                dueDate: threeCirclesLastReview,
                priority: .high,
                status: .overdue,
                icon: "circles.hexagongrid.fill",
                iconColor: .rrDestructive
            ),
        ]

        thisWeek = [
            RecoveryWorkItem(
                activityType: "backboneReview",
                title: String(localized: "Backbone Review"),
                triggerReason: String(localized: "Monthly recovery foundation check-in due"),
                dueDate: backboneDueDate,
                priority: .medium,
                status: .notStarted,
                icon: "shield.checkered",
                iconColor: .rrPrimary
            ),
            RecoveryWorkItem(
                activityType: "assessment.sast-r",
                title: String(localized: "SAST-R Assessment"),
                triggerReason: String(localized: "90-day periodic assessment -- track your progress"),
                dueDate: sastRDueDate,
                priority: .medium,
                status: .notStarted,
                icon: "clipboard.fill",
                iconColor: .purple
            ),
        ]

        thisMonth = [
            RecoveryWorkItem(
                activityType: "relapsePreventionPlan",
                title: String(localized: "Relapse Prevention Plan Review"),
                triggerReason: String(localized: "Quarterly review helps keep your plan current"),
                dueDate: rppDueDate,
                priority: .low,
                status: .notStarted,
                icon: "doc.text.magnifyingglass",
                iconColor: .orange
            ),
            RecoveryWorkItem(
                activityType: "visionStatement",
                title: String(localized: "Vision Statement Refresh"),
                triggerReason: String(localized: "Revisit your recovery vision and values quarterly"),
                dueDate: calendar.date(byAdding: .day, value: 21, to: now),
                priority: .low,
                status: .notStarted,
                icon: "eye.fill",
                iconColor: .rrSecondary
            ),
        ]

        dueNow = dueNow.filter { isWorkItemEnabled($0) }
        thisWeek = thisWeek.filter { isWorkItemEnabled($0) }
        thisMonth = thisMonth.filter { isWorkItemEnabled($0) }

        completed = [
            RecoveryWorkItem(
                activityType: "postMortem",
                title: String(localized: "Post-Mortem Analysis"),
                triggerReason: String(localized: "Completed after slip on day 45"),
                dueDate: calendar.date(byAdding: .day, value: -225, to: now),
                priority: .high,
                status: .completed,
                icon: "magnifyingglass.circle",
                iconColor: .rrDestructive
            ),
            RecoveryWorkItem(
                activityType: "threeCirclesReview",
                title: String(localized: "3 Circles Review"),
                triggerReason: String(localized: "Initial setup during onboarding"),
                dueDate: calendar.date(byAdding: .day, value: -270, to: now),
                priority: .medium,
                status: .completed,
                icon: "circles.hexagongrid.fill",
                iconColor: .rrDestructive
            ),
            RecoveryWorkItem(
                activityType: "assessment.sast-r",
                title: String(localized: "SAST-R Assessment"),
                triggerReason: String(localized: "Intake assessment completed"),
                dueDate: calendar.date(byAdding: .day, value: -270, to: now),
                priority: .medium,
                status: .completed,
                icon: "clipboard.fill",
                iconColor: .purple
            ),
        ]

        completed = completed.filter { isWorkItemEnabled($0) }
    }

    func startItem(_ item: RecoveryWorkItem) {
        updateStatus(for: item.id, to: .inProgress)
    }

    func dismissItem(_ item: RecoveryWorkItem) {
        removeItem(item.id)
    }

    func completeItem(_ item: RecoveryWorkItem) {
        var updated = item
        updated.status = .completed
        removeItem(item.id)
        completed.insert(updated, at: 0)
    }

    private func updateStatus(for id: UUID, to status: WorkStatus) {
        if let index = dueNow.firstIndex(where: { $0.id == id }) {
            dueNow[index].status = status
        } else if let index = thisWeek.firstIndex(where: { $0.id == id }) {
            thisWeek[index].status = status
        } else if let index = thisMonth.firstIndex(where: { $0.id == id }) {
            thisMonth[index].status = status
        }
    }

    private func removeItem(_ id: UUID) {
        dueNow.removeAll { $0.id == id }
        thisWeek.removeAll { $0.id == id }
        thisMonth.removeAll { $0.id == id }
    }
}

// MARK: - FASTER Stage Short Name

extension FASTERStage {
    var shortName: String {
        switch self {
        case .restoration: return "R"
        case .forgettingPriorities: return "F"
        case .anxiety: return "A"
        case .speedingUp: return "S"
        case .tickedOff: return "T"
        case .exhausted: return "E"
        case .relapse: return "R!"
        }
    }
}

// MARK: - Work Priority

enum WorkPriority: String {
    case high
    case medium
    case low
}

// MARK: - Work Status

enum WorkStatus: String {
    case notStarted
    case inProgress
    case completed
    case overdue

    var label: String {
        switch self {
        case .notStarted: return String(localized: "Not Started")
        case .inProgress: return String(localized: "In Progress")
        case .completed: return String(localized: "Completed")
        case .overdue: return String(localized: "Overdue")
        }
    }

    var color: Color {
        switch self {
        case .notStarted: return .gray
        case .inProgress: return .blue
        case .completed: return .rrSuccess
        case .overdue: return .orange
        }
    }
}

// MARK: - Recovery Work Item

struct RecoveryWorkItem: Identifiable {
    let id: UUID
    let activityType: String
    let title: String
    let triggerReason: String
    let dueDate: Date?
    let priority: WorkPriority
    var status: WorkStatus
    let icon: String
    let iconColor: Color

    init(
        id: UUID = UUID(),
        activityType: String,
        title: String,
        triggerReason: String,
        dueDate: Date? = nil,
        priority: WorkPriority,
        status: WorkStatus,
        icon: String,
        iconColor: Color
    ) {
        self.id = id
        self.activityType = activityType
        self.title = title
        self.triggerReason = triggerReason
        self.dueDate = dueDate
        self.priority = priority
        self.status = status
        self.icon = icon
        self.iconColor = iconColor
    }
}
