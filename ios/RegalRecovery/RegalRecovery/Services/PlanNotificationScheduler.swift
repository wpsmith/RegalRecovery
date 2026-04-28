import UserNotifications

class PlanNotificationScheduler {

    /// Schedule notifications for all plan items, batching activities at the same time.
    func scheduleFromPlan(items: [RRDailyPlanItem], userName: String) async {
        let center = UNUserNotificationCenter.current()

        // Remove all existing plan notifications (plan-* and morning-commitment IDs)
        let pending = await center.pendingNotificationRequests()
        let planIDs = pending
            .map(\.identifier)
            .filter { $0.hasPrefix("plan-") || $0 == "morning-commitment" }
        center.removePendingNotificationRequests(withIdentifiers: planIDs)

        // Group enabled items by (hour, minute) to batch them
        let grouped = Dictionary(grouping: items.filter(\.isEnabled)) { item in
            "\(item.scheduledHour):\(item.scheduledMinute)"
        }

        for (_, batchItems) in grouped {
            guard let first = batchItems.first else { continue }

            let content = UNMutableNotificationContent()
            content.sound = .default

            let timeBlock = timeBlockName(hour: first.scheduledHour)
            let activityNames = batchItems.map { displayName(for: $0.activityType) }

            if batchItems.count == 1 {
                content.title = String(localized: "Time for \(activityNames[0])")
                content.body = String(localized: "Your \(timeBlock.lowercased()) recovery activity is ready.")
            } else {
                content.title = String(localized: "\(timeBlock) recovery time")
                let list = activityNames.joined(separator: ", ")
                content.body = String(localized: "Good \(timeBlock.lowercased()), \(userName). Your \(list) are ready.")
            }

            // Schedule at the configured time, repeating daily
            var dateComponents = DateComponents()
            dateComponents.hour = first.scheduledHour
            dateComponents.minute = first.scheduledMinute
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

            let id = "plan-\(first.scheduledHour)-\(first.scheduledMinute)"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

            try? await center.add(request)
        }
    }

    /// Schedule a completion acknowledgment notification
    func scheduleCompletionAcknowledgment(score: Int, userName: String) async {
        let content = UNMutableNotificationContent()
        content.sound = .default

        switch score {
        case 90...100:
            content.title = String(localized: "100% today!")
            content.body = String(localized: "Every single one, \(userName). That's what recovery looks like.")
        case 70...89:
            content.title = String(localized: "Strong day, \(userName)")
            content.body = String(localized: "You showed up for your recovery today. Keep going.")
        case 50...69:
            content.title = String(localized: "Good effort today")
            content.body = String(localized: "Every activity you completed matters. Tomorrow is another opportunity.")
        default:
            // No notification for low scores — avoid shame
            return
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "daily-completion", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    /// Schedule the morning commitment reminder (always present if notifications enabled)
    func scheduleMorningCommitmentReminder(userName: String) async {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Good morning, \(userName)")
        content.body = String(localized: "Start your day with a sobriety commitment.")
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 6
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "morning-commitment",
            content: content,
            trigger: trigger
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    func scheduleQuadrantReminder(hasAssessedThisWeek: Bool) async {
        let center = UNUserNotificationCenter.current()
        let id = "quadrant-weekly-reminder"

        center.removePendingNotificationRequests(withIdentifiers: [id])

        guard !hasAssessedThisWeek else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Weekly Quadrant Review")
        content.body = String(localized: "How are your Body, Mind, Heart, and Spirit this week? Take 3 minutes for your Weekly Quadrant Review.")
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = 1
        dateComponents.hour = 19
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await center.add(request)
    }

    // MARK: - Notification Preview

    /// Generate a preview string for a batch of plan items at the same time slot.
    func previewText(for items: [RRDailyPlanItem], userName: String) -> (title: String, body: String) {
        guard let first = items.first else { return ("", "") }

        let timeBlock = timeBlockName(hour: first.scheduledHour)
        let activityNames = items.map { displayName(for: $0.activityType) }

        if items.count == 1 {
            return (
                String(localized: "Time for \(activityNames[0])"),
                String(localized: "Your \(timeBlock.lowercased()) recovery activity is ready.")
            )
        } else {
            let list = activityNames.joined(separator: ", ")
            return (
                String(localized: "\(timeBlock) recovery time"),
                String(localized: "Good \(timeBlock.lowercased()), \(userName). Your \(list) are ready.")
            )
        }
    }

    // MARK: - Helpers

    func timeBlockName(hour: Int) -> String {
        switch hour {
        case 5...11: return String(localized: "Morning")
        case 12...13: return String(localized: "Midday")
        case 14...17: return String(localized: "Afternoon")
        case 18...23: return String(localized: "Evening")
        default: return String(localized: "Recovery")
        }
    }

    func displayName(for activityType: String) -> String {
        DailyEligibleActivity.all.first { $0.activityType == activityType }?.displayName ?? activityType
    }

    func formattedTime(hour: Int, minute: Int) -> String {
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }
}
