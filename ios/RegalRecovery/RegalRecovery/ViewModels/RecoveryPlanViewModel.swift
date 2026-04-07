import SwiftUI
import SwiftData

// MARK: - Plan Item State

struct PlanItemState: Identifiable, Equatable, Hashable {
    let id: UUID
    let activity: DailyEligibleActivity
    var isEnabled: Bool
    var scheduledHour: Int
    var scheduledMinute: Int
    var instanceIndex: Int
    var daysOfWeek: Set<Int> // Empty = every day; 1=Sun..7=Sat
    var customTitle: String = "" // User-defined custom name

    static func == (lhs: PlanItemState, rhs: PlanItemState) -> Bool {
        lhs.id == rhs.id
            && lhs.isEnabled == rhs.isEnabled
            && lhs.scheduledHour == rhs.scheduledHour
            && lhs.scheduledMinute == rhs.scheduledMinute
            && lhs.instanceIndex == rhs.instanceIndex
            && lhs.daysOfWeek == rhs.daysOfWeek
            && lhs.customTitle == rhs.customTitle
    }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    var scheduledTime: Date {
        get {
            Calendar.current.date(from: DateComponents(hour: scheduledHour, minute: scheduledMinute)) ?? Date()
        }
        set {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            scheduledHour = comps.hour ?? scheduledHour
            scheduledMinute = comps.minute ?? scheduledMinute
        }
    }

    /// Display name: "Prayer: My Custom Title" or "Prayer #2" or just "Prayer"
    func displayName(siblingCount: Int) -> String {
        let base = activity.displayName
        let suffix = siblingCount > 1 ? " #\(instanceIndex + 1)" : ""
        if !customTitle.isEmpty {
            return "\(base)\(suffix): \(customTitle)"
        }
        return "\(base)\(suffix)"
    }

    /// Short label for compact display: custom title or "#N" or empty
    var shortLabel: String {
        if !customTitle.isEmpty { return customTitle }
        return ""
    }
}

// MARK: - View Model

@Observable
class RecoveryPlanViewModel {
    var planItems: [PlanItemState] = []
    var isSaving = false
    var saveError: String?
    var didSave = false
    var hasUnsavedChanges = false
    private var originalSnapshot: [PlanItemState] = []

    var enabledCount: Int { planItems.count }
    var showOverloadWarning: Bool { enabledCount > 20 }

    var availableActivities: [DailyEligibleActivity] {
        let countByType = Dictionary(grouping: planItems, by: \.activity.activityType)
            .mapValues(\.count)
        return DailyEligibleActivity.enabled.filter { activity in
            let currentCount = countByType[activity.activityType] ?? 0
            if activity.multiplePerDay {
                return currentCount < activity.maxPerDay
            } else {
                return currentCount == 0
            }
        }
    }

    func siblingCount(for activityType: String) -> Int {
        planItems.filter { $0.activity.activityType == activityType }.count
    }

    private func markChanged() { hasUnsavedChanges = true }

    /// Compares current planItems against the loaded snapshot to detect edits
    /// made via bindings (day toggles, time changes, custom title).
    func checkForChanges() {
        hasUnsavedChanges = planItems != originalSnapshot
    }

    // MARK: - Load

    func load(context: ModelContext) {
        let descriptor = FetchDescriptor<RRRecoveryPlan>(
            predicate: #Predicate { $0.isActive == true }
        )
        let plans = (try? context.fetch(descriptor)) ?? []
        let activePlan = plans.first
        let existingItems: [RRDailyPlanItem] = (activePlan?.items ?? []).sorted { $0.sortOrder < $1.sortOrder }

        var items: [PlanItemState] = []

        for item in existingItems where item.isEnabled {
            let activity = DailyEligibleActivity.enabled.first(where: { $0.activityType == item.activityType })
            guard let activity else { continue }
            items.append(PlanItemState(
                id: item.id,
                activity: activity,
                isEnabled: true,
                scheduledHour: item.scheduledHour,
                scheduledMinute: item.scheduledMinute,
                instanceIndex: item.instanceIndex,
                daysOfWeek: Set(item.daysOfWeek)
            ))
        }

        if activePlan == nil {
            for activity in DailyEligibleActivity.enabled where activity.defaultEnabled {
                items.append(PlanItemState(
                    id: UUID(),
                    activity: activity,
                    isEnabled: true,
                    scheduledHour: activity.typicalHour,
                    scheduledMinute: activity.typicalMinute,
                    instanceIndex: 0,
                    daysOfWeek: []
                ))
            }
        }

        planItems = items
        originalSnapshot = items
        hasUnsavedChanges = false
    }

    // MARK: - Add / Remove / Move

    func addActivity(_ activity: DailyEligibleActivity) {
        let existingSiblings = planItems.filter { $0.activity.activityType == activity.activityType }
        let nextIndex = existingSiblings.count
        let baseHour = activity.typicalHour
        let offsetHour = (baseHour + nextIndex * 4) % 24

        let newItem = PlanItemState(
            id: UUID(),
            activity: activity,
            isEnabled: true,
            scheduledHour: offsetHour,
            scheduledMinute: activity.typicalMinute,
            instanceIndex: nextIndex,
            daysOfWeek: []
        )
        planItems.append(newItem)
        markChanged()
    }

    func removeActivity(at index: Int) {
        guard planItems.indices.contains(index) else { return }
        planItems.remove(at: index)
        markChanged()
    }

    func moveActivity(from source: IndexSet, to destination: Int) {
        planItems.move(fromOffsets: source, toOffset: destination)
        markChanged()
    }

    // MARK: - Save

    func save(context: ModelContext) {
        isSaving = true
        saveError = nil

        do {
            let descriptor = FetchDescriptor<RRRecoveryPlan>(
                predicate: #Predicate { $0.isActive == true }
            )
            let plans = (try? context.fetch(descriptor)) ?? []
            let plan: RRRecoveryPlan

            if let existing = plans.first {
                plan = existing
                plan.modifiedAt = Date()
                let oldItems = existing.items ?? []
                for item in oldItems { context.delete(item) }
            } else {
                let userDescriptor = FetchDescriptor<RRUser>()
                let users = (try? context.fetch(userDescriptor)) ?? []
                let userId = users.first?.id ?? UUID()
                plan = RRRecoveryPlan(userId: userId)
                context.insert(plan)
            }

            // Reassign instanceIndex per activityType in current order
            var indexCounters: [String: Int] = [:]
            for (sortOrder, item) in planItems.enumerated() {
                let idx = indexCounters[item.activity.activityType] ?? 0
                indexCounters[item.activity.activityType] = idx + 1

                let planItem = RRDailyPlanItem(
                    planId: plan.id,
                    activityType: item.activity.activityType,
                    scheduledHour: item.scheduledHour,
                    scheduledMinute: item.scheduledMinute,
                    instanceIndex: idx,
                    daysOfWeek: Array(item.daysOfWeek),
                    isEnabled: true,
                    sortOrder: sortOrder
                )
                planItem.plan = plan
                context.insert(planItem)
            }

            try context.save()
            hasUnsavedChanges = false
            didSave = true
        } catch {
            saveError = "Failed to save recovery plan. Please try again."
        }

        isSaving = false
    }

    // MARK: - Score Preview

    func scorePreview() -> String {
        guard !planItems.isEmpty else {
            return "Add activities to build your daily recovery score."
        }

        let hasMorning = planItems.contains { $0.activity.activityType == ActivityType.sobrietyCommitment.rawValue }
        let otherCount = hasMorning ? planItems.count - 1 : planItems.count

        if hasMorning && otherCount > 0 {
            let eachPercent = 80.0 / Double(otherCount)
            return "Morning Commitment = 20%, \(otherCount) other\(otherCount == 1 ? "" : "s") = \(String(format: "%.1f", eachPercent))% each"
        } else if hasMorning {
            return "Morning Commitment = 100%"
        } else {
            let eachPercent = 100.0 / Double(otherCount)
            return "\(otherCount) activit\(otherCount == 1 ? "y" : "ies") = \(String(format: "%.1f", eachPercent))% each"
        }
    }

    // MARK: - Debug: Score Algorithm

    func scoreAlgorithmDebug() -> String {
        guard !planItems.isEmpty else { return "No items" }
        let hasMorning = planItems.contains { $0.activity.activityType == ActivityType.sobrietyCommitment.rawValue }
        let otherCount = hasMorning ? planItems.count - 1 : planItems.count
        var lines: [String] = ["Score Algorithm Debug:", ""]

        if hasMorning {
            lines.append("Morning Commitment: 20% (fixed weight)")
        }

        let eachWeight = otherCount > 0 ? (hasMorning ? 80.0 : 100.0) / Double(otherCount) : 0
        for (i, item) in planItems.enumerated() {
            if item.activity.activityType == ActivityType.sobrietyCommitment.rawValue { continue }
            let name = item.displayName(siblingCount: siblingCount(for: item.activity.activityType))
            lines.append("  [\(i)] \(name): \(String(format: "%.2f", eachWeight))%")
        }

        lines.append("")
        lines.append("Formula: score = (morning ? 20 : 0) + (completed_others / \(otherCount)) × \(hasMorning ? 80 : 100)")
        lines.append("Total items: \(planItems.count)")
        return lines.joined(separator: "\n")
    }
}
