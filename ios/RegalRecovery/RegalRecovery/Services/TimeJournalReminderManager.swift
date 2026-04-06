import Foundation
import UserNotifications

/// Manages local notifications for Time Journal slot reminders, gap alerts, and end-of-day reviews.
class TimeJournalReminderManager {

    static let shared = TimeJournalReminderManager()

    private let center = UNUserNotificationCenter.current()

    /// Notification identifier prefixes for targeted removal.
    private enum IDPrefix {
        static let slotReminder = "tj-slot-"
        static let gapAlert = "tj-gap-alert"
        static let endOfDayReview = "tj-eod-review"
        static let category = "TIME_JOURNAL_REMINDER"
    }

    // MARK: - TJ-036: Schedule Slot Reminders

    /// Schedule reminders at each interval boundary during waking hours.
    ///
    /// Removes all existing time journal reminders first, then schedules one repeating
    /// notification per slot boundary within the waking window.
    ///
    /// - Parameters:
    ///   - mode: The journal mode (.t30 or .t60) determining interval size.
    ///   - wakingHoursStart: Hour when reminders begin (default 6 = 6:00 AM).
    ///   - wakingHoursEnd: Hour when reminders stop (default 23 = 11:00 PM).
    func scheduleSlotReminders(
        mode: TimeJournalMode,
        wakingHoursStart: Int = 6,
        wakingHoursEnd: Int = 23
    ) async {
        // Remove existing slot reminders
        await removeRemindersWithPrefix(IDPrefix.slotReminder)

        let intervalMinutes = mode.intervalMinutes

        // Calculate the first slot index at or after wakingHoursStart
        let startMinute = wakingHoursStart * 60
        let endMinute = wakingHoursEnd * 60

        var currentMinute = startMinute
        var slotCounter = 0

        while currentMinute < endMinute {
            let hour = currentMinute / 60
            let minute = currentMinute % 60

            let content = UNMutableNotificationContent()
            content.title = "Time Journal"
            content.body = "Time to log your Time Journal \u{2014} what have you been doing?"
            content.sound = .default
            content.categoryIdentifier = IDPrefix.category
            content.interruptionLevel = .passive

            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let identifier = "\(IDPrefix.slotReminder)\(hour)-\(minute)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            try? await center.add(request)

            currentMinute += intervalMinutes
            slotCounter += 1
        }
    }

    // MARK: - TJ-037: DND Mode Support

    /// Creates notification content with appropriate interruption level.
    ///
    /// Overdue reminders use `.timeSensitive` to break through Focus/DND,
    /// while regular reminders use `.passive` so they don't interrupt.
    ///
    /// - Parameter isOverdue: Whether this reminder is for an overdue slot.
    /// - Returns: Configured notification content.
    func makeReminderContent(isOverdue: Bool) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.categoryIdentifier = IDPrefix.category
        content.sound = .default

        if isOverdue {
            content.title = "Time Journal \u{2014} Overdue"
            content.body = "You have unfilled slots in your Time Journal. Tap to catch up."
            content.interruptionLevel = .timeSensitive
        } else {
            content.title = "Time Journal"
            content.body = "Time to log your Time Journal \u{2014} what have you been doing?"
            content.interruptionLevel = .passive
        }

        return content
    }

    // MARK: - TJ-038: Smart Dampening

    /// Evaluates recent completion rates and recommends a journal mode adjustment.
    ///
    /// Rules:
    /// - If the user has filled >90% for the last 7 days, suggest switching to T60 (reduce frequency).
    /// - If the user has filled <70% for the last 3 days, suggest switching to T30 (increase frequency).
    /// - Otherwise, keep the current mode.
    ///
    /// - Parameters:
    ///   - recentCompletionRates: Array of daily completion rates (0.0-1.0), most recent first.
    ///   - currentMode: The user's current journaling mode.
    /// - Returns: The recommended mode (may be the same as current).
    func adjustFrequency(
        recentCompletionRates: [Double],
        currentMode: TimeJournalMode
    ) -> TimeJournalMode {
        // Need at least 3 days of data to make any recommendation
        guard recentCompletionRates.count >= 3 else { return currentMode }

        // Check for consistent high completion (>90% for 7+ days) -> suggest T60
        if recentCompletionRates.count >= 7 {
            let last7 = Array(recentCompletionRates.prefix(7))
            let allAbove90 = last7.allSatisfy { $0 > 0.90 }
            if allAbove90 && currentMode == .t30 {
                return .t60
            }
        }

        // Check for poor completion (<70% for last 3 days) -> suggest T30
        let last3 = Array(recentCompletionRates.prefix(3))
        let allBelow70 = last3.allSatisfy { $0 < 0.70 }
        if allBelow70 && currentMode == .t60 {
            return .t30
        }

        return currentMode
    }

    // MARK: - TJ-039: End-of-Day Review Reminder

    /// Schedule a nightly reminder to review unfilled journal slots.
    ///
    /// - Parameters:
    ///   - hour: Hour for the reminder (default 22 = 10:00 PM).
    ///   - minute: Minute for the reminder (default 0).
    func scheduleEndOfDayReview(hour: Int = 22, minute: Int = 0) async {
        // Remove existing EOD review
        center.removePendingNotificationRequests(withIdentifiers: [IDPrefix.endOfDayReview])

        let content = UNMutableNotificationContent()
        content.title = "Review Your Day"
        content.body = "Review your Time Journal \u{2014} any unfilled slots from today?"
        content.sound = .default
        content.categoryIdentifier = IDPrefix.category
        content.interruptionLevel = .active

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: IDPrefix.endOfDayReview,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    // MARK: - TJ-033: Gap Alert

    /// Schedule a repeating gap alert that fires every 90 minutes during waking hours.
    ///
    /// This serves as a background nudge when the user hasn't made an entry
    /// for an extended period. The notification text is gentle per recovery-app
    /// conventions ("gentle reminder" rather than "you missed").
    func scheduleGapAlert() async {
        // Remove existing gap alert
        center.removePendingNotificationRequests(withIdentifiers: [IDPrefix.gapAlert])

        let content = UNMutableNotificationContent()
        content.title = "Time Journal"
        content.body = "Gentle reminder \u{2014} it\u{2019}s been a while since your last Time Journal entry."
        content.sound = .default
        content.categoryIdentifier = IDPrefix.category
        content.interruptionLevel = .passive

        // 90 minutes = 5400 seconds
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5400, repeats: true)
        let request = UNNotificationRequest(
            identifier: IDPrefix.gapAlert,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    // MARK: - Cancel All

    /// Remove all pending Time Journal notifications.
    func cancelAllReminders() async {
        let pending = await center.pendingNotificationRequests()
        let tjIdentifiers = pending
            .map(\.identifier)
            .filter {
                $0.hasPrefix(IDPrefix.slotReminder)
                    || $0 == IDPrefix.gapAlert
                    || $0 == IDPrefix.endOfDayReview
            }
        center.removePendingNotificationRequests(withIdentifiers: tjIdentifiers)
    }

    // MARK: - Helpers

    /// Remove all pending notifications whose identifier starts with the given prefix.
    private func removeRemindersWithPrefix(_ prefix: String) async {
        let pending = await center.pendingNotificationRequests()
        let matching = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: matching)
    }
}
