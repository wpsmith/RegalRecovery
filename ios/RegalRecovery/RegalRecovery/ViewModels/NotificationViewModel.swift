import Foundation
import Observation
import SwiftData
import UserNotifications

@Observable
class NotificationViewModel {
    var planItems: [RRDailyPlanItem] = []
    var userName: String = ""
    var allNotificationsEnabled: Bool = true
    var disabledTimeBlocks: Set<String> = []

    private let scheduler = PlanNotificationScheduler()

    /// Grouped plan items by time block for display.
    var timeBlockGroups: [(block: String, hour: Int, minute: Int, items: [RRDailyPlanItem])] {
        let enabled = planItems.filter(\.isEnabled)
        let grouped = Dictionary(grouping: enabled) { item in
            "\(item.scheduledHour):\(item.scheduledMinute)"
        }

        return grouped
            .sorted { lhs, rhs in
                guard let l = lhs.value.first, let r = rhs.value.first else { return false }
                return (l.scheduledHour, l.scheduledMinute) < (r.scheduledHour, r.scheduledMinute)
            }
            .map { (_, items) in
                let first = items[0]
                let block = scheduler.timeBlockName(hour: first.scheduledHour)
                return (block: block, hour: first.scheduledHour, minute: first.scheduledMinute, items: items)
            }
    }

    /// Load plan items from SwiftData.
    func load(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<RRRecoveryPlan>(
            predicate: #Predicate { $0.isActive == true }
        )
        guard let plan = try? modelContext.fetch(descriptor).first,
              let items = plan.items else {
            planItems = []
            return
        }

        planItems = items.sorted {
            ($0.scheduledHour, $0.scheduledMinute) < ($1.scheduledHour, $1.scheduledMinute)
        }

        // Load user name
        let userDescriptor = FetchDescriptor<RRUser>()
        if let user = try? modelContext.fetch(userDescriptor).first {
            userName = user.name.components(separatedBy: " ").first ?? user.name
        }
    }

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            return false
        }
    }

    /// Toggle all notifications on or off.
    func toggleAll(enabled: Bool) async {
        allNotificationsEnabled = enabled

        if enabled {
            disabledTimeBlocks.removeAll()
            await scheduleFromPlan()
        } else {
            let center = UNUserNotificationCenter.current()
            center.removeAllPendingNotificationRequests()
        }
    }

    /// Toggle notifications for a specific time block.
    func toggleTimeBlock(_ key: String, enabled: Bool) async {
        if enabled {
            disabledTimeBlocks.remove(key)
        } else {
            disabledTimeBlocks.insert(key)
        }
        await scheduleFromPlan()
    }

    /// Schedule notifications based on the current plan, respecting disabled time blocks.
    func scheduleFromPlan() async {
        guard allNotificationsEnabled else { return }

        // Filter out items in disabled time blocks
        let activeItems = planItems.filter { item in
            let key = "\(item.scheduledHour):\(item.scheduledMinute)"
            return !disabledTimeBlocks.contains(key)
        }

        await scheduler.scheduleFromPlan(items: activeItems, userName: userName)
    }

    /// Trigger a completion acknowledgment notification for the daily score.
    func scheduleCompletionAcknowledgment(score: Int) async {
        guard allNotificationsEnabled else { return }
        await scheduler.scheduleCompletionAcknowledgment(score: score, userName: userName)
    }

    /// Generate preview text for a time block batch.
    func previewText(for items: [RRDailyPlanItem]) -> (title: String, body: String) {
        scheduler.previewText(for: items, userName: userName.isEmpty ? "friend" : userName)
    }

    /// Formatted time string for display.
    func formattedTime(hour: Int, minute: Int) -> String {
        scheduler.formattedTime(hour: hour, minute: minute)
    }
}
