import Foundation
import SwiftUI

// MARK: - Work Tile Category

enum WorkTileCategory: String, CaseIterable {
    case foundationTools = "Foundation Tools"
    case activities = "Activities"
    case tools = "Tools"
    case assessments = "Assessments"

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
                title: "3 Circles",
                icon: "circles.hexagongrid.fill",
                iconColor: .rrDestructive,
                category: .foundationTools,
                featureFlagKey: "feature.3circles",
                implemented: true,
                activityTypeKey: "threeCircles"
            ),
            WorkTileItem(
                id: "foundation.relapse-prevention",
                title: "Relapse Prevention",
                icon: "doc.text.magnifyingglass",
                iconColor: .orange,
                category: .foundationTools,
                featureFlagKey: nil,
                implemented: false,
                activityTypeKey: nil
            ),
            WorkTileItem(
                id: "foundation.backbone",
                title: "Backbone",
                icon: "shield.checkered",
                iconColor: .rrPrimary,
                category: .foundationTools,
                featureFlagKey: nil,
                implemented: false,
                activityTypeKey: nil
            ),
            WorkTileItem(
                id: "foundation.vision",
                title: "Vision Statement",
                icon: "eye.fill",
                iconColor: .rrSecondary,
                category: .foundationTools,
                featureFlagKey: nil,
                implemented: false,
                activityTypeKey: nil
            ),
        ])

        // ── Activities ──
        tiles.append(contentsOf: [
            WorkTileItem(
                id: "activity.sobriety-commitment",
                title: "Sobriety Commitment",
                icon: "sun.max.fill",
                iconColor: .rrSecondary,
                category: .activities,
                featureFlagKey: "activity.sobriety-commitment",
                implemented: true,
                activityTypeKey: ActivityType.sobrietyCommitment.rawValue
            ),
            WorkTileItem(
                id: "activity.affirmations",
                title: "Affirmations",
                icon: "text.quote",
                iconColor: .rrPrimary,
                category: .activities,
                featureFlagKey: "activity.affirmations",
                implemented: true,
                activityTypeKey: ActivityType.affirmationLog.rawValue
            ),
            WorkTileItem(
                id: "activity.urge-logging",
                title: "Urge Logging",
                icon: "exclamationmark.triangle.fill",
                iconColor: .orange,
                category: .activities,
                featureFlagKey: "activity.urge-logging",
                implemented: true,
                activityTypeKey: ActivityType.urgeLog.rawValue
            ),
            WorkTileItem(
                id: "activity.journaling",
                title: "Journaling",
                icon: "note.text",
                iconColor: .purple,
                category: .activities,
                featureFlagKey: "activity.journaling",
                implemented: true,
                activityTypeKey: ActivityType.journal.rawValue
            ),
            WorkTileItem(
                id: "activity.faster-scale",
                title: "FASTER Scale",
                icon: "gauge.with.needle",
                iconColor: .rrSuccess,
                category: .activities,
                featureFlagKey: "activity.faster-scale",
                implemented: true,
                activityTypeKey: ActivityType.fasterScale.rawValue
            ),
            WorkTileItem(
                id: "activity.check-ins",
                title: "Recovery Check-in",
                icon: "heart.text.clipboard",
                iconColor: .rrPrimary,
                category: .activities,
                featureFlagKey: "activity.check-ins",
                implemented: true,
                activityTypeKey: ActivityType.recoveryCheckIn.rawValue
            ),
            WorkTileItem(
                id: "activity.emotional-journaling",
                title: "Emotional Journal",
                icon: "heart.circle.fill",
                iconColor: .purple,
                category: .activities,
                featureFlagKey: "activity.emotional-journaling",
                implemented: true,
                activityTypeKey: ActivityType.emotionalJournal.rawValue
            ),
            WorkTileItem(
                id: "activity.time-journal",
                title: "Time Journal",
                icon: "clock.fill",
                iconColor: .purple,
                category: .activities,
                featureFlagKey: "activity.time-journal",
                implemented: true,
                activityTypeKey: ActivityType.timeJournal.rawValue
            ),
            WorkTileItem(
                id: "activity.spouse-checkin-prep",
                title: "Spouse Check-in",
                icon: "heart.fill",
                iconColor: .pink,
                category: .activities,
                featureFlagKey: "activity.spouse-checkin-prep",
                implemented: true,
                activityTypeKey: ActivityType.spouseCheckIn.rawValue
            ),
            WorkTileItem(
                id: "activity.person-check-ins",
                title: "Person Check-ins",
                icon: "person.fill.checkmark",
                iconColor: .rrPrimary,
                category: .activities,
                featureFlagKey: "activity.person-check-ins",
                implemented: true,
                activityTypeKey: "personCheckInSpouse"
            ),
            WorkTileItem(
                id: "activity.meetings",
                title: "Meetings",
                icon: "person.3.fill",
                iconColor: .rrPrimary,
                category: .activities,
                featureFlagKey: "activity.meetings",
                implemented: true,
                activityTypeKey: ActivityType.meetingsAttended.rawValue
            ),
            WorkTileItem(
                id: "activity.post-mortem",
                title: "Post-Mortem",
                icon: "magnifyingglass.circle",
                iconColor: .rrDestructive,
                category: .tools,
                featureFlagKey: nil,
                implemented: false,
                activityTypeKey: nil
            ),
            WorkTileItem(
                id: "activity.step-work",
                title: "12-Step Work",
                icon: "stairs",
                iconColor: .rrPrimary,
                category: .tools,
                featureFlagKey: "activity.step-work",
                implemented: true,
                activityTypeKey: ActivityType.stepWork.rawValue
            ),
            WorkTileItem(
                id: "activity.goals",
                title: "Goals",
                icon: "target",
                iconColor: .rrSecondary,
                category: .activities,
                featureFlagKey: "activity.goals",
                implemented: true,
                activityTypeKey: ActivityType.weeklyGoals.rawValue
            ),
            WorkTileItem(
                id: "activity.devotionals",
                title: "Devotional",
                icon: "book.fill",
                iconColor: .brown,
                category: .activities,
                featureFlagKey: "activity.devotionals",
                implemented: true,
                activityTypeKey: "devotional"
            ),
            WorkTileItem(
                id: "activity.exercise",
                title: "Exercise",
                icon: "figure.run",
                iconColor: .rrSuccess,
                category: .activities,
                featureFlagKey: "activity.exercise",
                implemented: true,
                activityTypeKey: ActivityType.exercise.rawValue
            ),
            WorkTileItem(
                id: "activity.mood",
                title: "Mood Rating",
                icon: "face.smiling",
                iconColor: .yellow,
                category: .activities,
                featureFlagKey: "activity.mood",
                implemented: true,
                activityTypeKey: ActivityType.mood.rawValue
            ),
            WorkTileItem(
                id: "activity.gratitude",
                title: "Gratitude",
                icon: "leaf.fill",
                iconColor: .rrSuccess,
                category: .activities,
                featureFlagKey: "activity.gratitude",
                implemented: true,
                activityTypeKey: ActivityType.gratitude.rawValue
            ),
            WorkTileItem(
                id: "activity.phone-calls",
                title: "Phone Calls",
                icon: "phone.fill",
                iconColor: .rrPrimary,
                category: .activities,
                featureFlagKey: "activity.phone-calls",
                implemented: true,
                activityTypeKey: ActivityType.phoneCalls.rawValue
            ),
            WorkTileItem(
                id: "activity.prayer",
                title: "Prayer",
                icon: "hands.and.sparkles.fill",
                iconColor: .rrSecondary,
                category: .activities,
                featureFlagKey: "activity.prayer",
                implemented: true,
                activityTypeKey: ActivityType.prayer.rawValue
            ),
            WorkTileItem(
                id: "activity.integrity-inventory",
                title: "Integrity Inventory",
                icon: "checkmark.shield.fill",
                iconColor: .rrPrimary,
                category: .activities,
                featureFlagKey: "activity.integrity-inventory",
                implemented: true,
                activityTypeKey: "integrityInventory"
            ),
            WorkTileItem(
                id: "activity.memory-verse",
                title: "Memory Verse",
                icon: "text.book.closed.fill",
                iconColor: .brown,
                category: .tools,
                featureFlagKey: "activity.memory-verse",
                implemented: true,
                activityTypeKey: "memoryVerseReview"
            ),
            WorkTileItem(
                id: "activity.pci",
                title: "PCI",
                icon: "checklist",
                iconColor: .rrDestructive,
                category: .activities,
                featureFlagKey: nil,
                implemented: false,
                activityTypeKey: nil
            ),
            WorkTileItem(
                id: "activity.nutrition",
                title: "Nutrition",
                icon: "fork.knife",
                iconColor: .green,
                category: .activities,
                featureFlagKey: nil,
                implemented: false,
                activityTypeKey: nil
            ),
            WorkTileItem(
                id: "activity.acting-in-behaviors",
                title: "Acting In Behaviors",
                icon: "shield.lefthalf.filled",
                iconColor: .orange,
                category: .activities,
                featureFlagKey: nil,
                implemented: false,
                activityTypeKey: nil
            ),
            WorkTileItem(
                id: "activity.voice-journal",
                title: "Voice Journal",
                icon: "mic.fill",
                iconColor: .purple,
                category: .activities,
                featureFlagKey: nil,
                implemented: false,
                activityTypeKey: nil
            ),
            WorkTileItem(
                id: "activity.book-reading",
                title: "Book Reading",
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
                title: "Urge Surfing Timer",
                icon: "timer",
                iconColor: .orange,
                category: .tools,
                featureFlagKey: "feature.urge-surfing-timer",
                implemented: true,
                activityTypeKey: "urgeSurfingTimer"
            ),
            WorkTileItem(
                id: "tool.meeting-finder",
                title: "Meeting Finder",
                icon: "map.fill",
                iconColor: .rrPrimary,
                category: .tools,
                featureFlagKey: "feature.meeting-finder",
                implemented: true,
                activityTypeKey: "meetingFinder"
            ),
        ])

        // ── Assessments ──
        tiles.append(contentsOf: [
            WorkTileItem(
                id: "assessment.sast-r",
                title: "SAST-R",
                icon: "clipboard.fill",
                iconColor: .purple,
                category: .assessments,
                featureFlagKey: nil,
                implemented: false,
                activityTypeKey: nil
            ),
            WorkTileItem(
                id: "assessment.family-impact",
                title: "Family Impact",
                icon: "house.fill",
                iconColor: .rrPrimary,
                category: .assessments,
                featureFlagKey: nil,
                implemented: false,
                activityTypeKey: nil
            ),
            WorkTileItem(
                id: "assessment.denial",
                title: "Denial Assessment",
                icon: "eye.slash.fill",
                iconColor: .orange,
                category: .assessments,
                featureFlagKey: nil,
                implemented: false,
                activityTypeKey: nil
            ),
            WorkTileItem(
                id: "assessment.addiction-severity",
                title: "Addiction Severity",
                icon: "waveform.path.ecg",
                iconColor: .rrDestructive,
                category: .assessments,
                featureFlagKey: nil,
                implemented: false,
                activityTypeKey: nil
            ),
            WorkTileItem(
                id: "assessment.relationship-health",
                title: "Relationship Health",
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
        checkIns: [RRCheckIn],
        journals: [RRJournalEntry],
        emotionalJournals: [RREmotionalJournal],
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

        case ActivityType.recoveryCheckIn.rawValue:
            if let c = checkIns.first(where: { cal.isDateInToday($0.date) }) {
                return .hasEntries("\(c.score)")
            }
            return .none

        case ActivityType.emotionalJournal.rawValue:
            let todayCount = emotionalJournals.filter { cal.isDateInToday($0.date) }.count
            if todayCount > 0 { return .hasEntries("\(todayCount)") }
            return .none

        case ActivityType.timeJournal.rawValue:
            let todayCount = timeBlocks.filter { cal.isDateInToday($0.date) }.count
            if todayCount > 0 { return .hasEntries("\(todayCount)") }
            return .none

        case ActivityType.spouseCheckIn.rawValue:
            if spouseCheckIns.first(where: { cal.isDateInToday($0.date) }) != nil {
                return .completed
            }
            return .none

        case "personCheckInSpouse":
            // Person check-ins use spouse check-in data
            if spouseCheckIns.first(where: { cal.isDateInToday($0.date) }) != nil {
                return .hasEntries("1")
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
            if let p = prayerLogs.first(where: { cal.isDateInToday($0.date) }) {
                return .hasEntries("\(p.durationMinutes)m")
            }
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
                    return "\(timeJournalFilledCount) of \(timeJournalTotalSlots) slots filled today"
                case .overdue:
                    return "Some time slots have passed without entries"
                case .completed:
                    return "All time slots filled for today"
                }
            }()

            timeJournalItems.append(RecoveryWorkItem(
                activityType: "timeJournal",
                title: "Time Journal",
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
                title: "3 Circles Review",
                triggerReason: "Last reviewed 62 days ago -- quarterly review recommended",
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
                title: "Backbone Review",
                triggerReason: "Monthly recovery foundation check-in due",
                dueDate: backboneDueDate,
                priority: .medium,
                status: .notStarted,
                icon: "shield.checkered",
                iconColor: .rrPrimary
            ),
            RecoveryWorkItem(
                activityType: "assessment.sast-r",
                title: "SAST-R Assessment",
                triggerReason: "90-day periodic assessment -- track your progress",
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
                title: "Relapse Prevention Plan Review",
                triggerReason: "Quarterly review helps keep your plan current",
                dueDate: rppDueDate,
                priority: .low,
                status: .notStarted,
                icon: "doc.text.magnifyingglass",
                iconColor: .orange
            ),
            RecoveryWorkItem(
                activityType: "visionStatement",
                title: "Vision Statement Refresh",
                triggerReason: "Revisit your recovery vision and values quarterly",
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
                title: "Post-Mortem Analysis",
                triggerReason: "Completed after slip on day 45",
                dueDate: calendar.date(byAdding: .day, value: -225, to: now),
                priority: .high,
                status: .completed,
                icon: "magnifyingglass.circle",
                iconColor: .rrDestructive
            ),
            RecoveryWorkItem(
                activityType: "threeCirclesReview",
                title: "3 Circles Review",
                triggerReason: "Initial setup during onboarding",
                dueDate: calendar.date(byAdding: .day, value: -270, to: now),
                priority: .medium,
                status: .completed,
                icon: "circles.hexagongrid.fill",
                iconColor: .rrDestructive
            ),
            RecoveryWorkItem(
                activityType: "assessment.sast-r",
                title: "SAST-R Assessment",
                triggerReason: "Intake assessment completed",
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
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .overdue: return "Overdue"
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
