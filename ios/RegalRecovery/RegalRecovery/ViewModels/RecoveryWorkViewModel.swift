import Foundation
import SwiftUI

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

// MARK: - View Model

@Observable
class RecoveryWorkViewModel {
    var dueNow: [RecoveryWorkItem] = []
    var thisWeek: [RecoveryWorkItem] = []
    var thisMonth: [RecoveryWorkItem] = []
    var completed: [RecoveryWorkItem] = []

    private let calendar = Calendar.current

    // MARK: - Feature Flag Gating

    private static let activityFlagMap: [String: String] = [
        "threeCirclesReview": "feature.3circles",
        "backboneReview": "feature.partners.redemptiveliving.backbone",
        "visionStatement": "feature.vision",
        "relapsePreventionPlan": "feature.relapse-prevention-plan",
        "postMortem": "feature.post-mortem",
        "assessment.sast-r": "assessment.sast-r",
    ]

    private func isWorkItemEnabled(_ item: RecoveryWorkItem) -> Bool {
        guard let flagKey = Self.activityFlagMap[item.activityType] else { return true }
        return FeatureFlagStore.shared.isEnabled(flagKey)
    }

    func load() {
        let now = Date()

        // Alex hasn't relapsed recently, so Post-Mortem is not due
        // 3 Circles Review is due (last reviewed >60 days ago)
        // SAST-R Assessment approaching (90-day mark)
        // Relapse Prevention Plan review due this month

        let threeCirclesLastReview = calendar.date(byAdding: .day, value: -62, to: now)!
        let sastRDueDate = calendar.date(byAdding: .day, value: 7, to: now)!
        let rppDueDate = calendar.date(byAdding: .day, value: 14, to: now)!
        let backboneDueDate = calendar.date(byAdding: .day, value: 5, to: now)!

        // Due Now: 3 Circles Review (overdue by days criteria)
        dueNow = [
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

        // This Week: Backbone review and SAST-R
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

        // This Month: RPP review, Vision Statement
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

        // Apply feature flag gating
        dueNow = dueNow.filter { isWorkItemEnabled($0) }
        thisWeek = thisWeek.filter { isWorkItemEnabled($0) }
        thisMonth = thisMonth.filter { isWorkItemEnabled($0) }

        // Completed: Sample completed items
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

    // MARK: - Private

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
