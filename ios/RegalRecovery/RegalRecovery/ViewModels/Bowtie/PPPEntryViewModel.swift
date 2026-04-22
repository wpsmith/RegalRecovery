import Foundation
import SwiftData
import UserNotifications

@Observable
class PPPEntryViewModel {
    var prayer: String = ""
    var selectedContactIds: Set<UUID> = []
    var planBefore: String = ""
    var planDuring: String = ""
    var planAfter: String = ""
    var reminderEnabled: Bool = false
    var reminderMinutesBefore: Int = 60 // 30, 60, 180

    var followUpOutcome: PPPOutcome?
    var followUpReflection: String = ""

    var canSave: Bool {
        !prayer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !selectedContactIds.isEmpty ||
        !planBefore.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !planDuring.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !planAfter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save(marker: RRBowtieMarker, context: ModelContext) {
        let entry = RRPPPEntry(
            prayer: prayer.isEmpty ? nil : prayer,
            peopleContactIds: selectedContactIds.isEmpty ? nil : Array(selectedContactIds),
            planBefore: planBefore.isEmpty ? nil : planBefore,
            planDuring: planDuring.isEmpty ? nil : planDuring,
            planAfter: planAfter.isEmpty ? nil : planAfter
        )
        entry.marker = marker
        context.insert(entry)

        if reminderEnabled, let session = marker.session {
            let anticipatedDate = session.referenceTimestamp.addingTimeInterval(
                TimeInterval(marker.timeIntervalHours * 3600)
            )
            let reminderDate = anticipatedDate.addingTimeInterval(
                -TimeInterval(reminderMinutesBefore * 60)
            )
            entry.reminderTime = reminderDate
            scheduleReminder(id: entry.id, at: reminderDate)
        }
    }

    func scheduleReminder(id: UUID, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Reminder")
        content.body = String(localized: "Your plan is ready.")
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "ppp-\(id.uuidString)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func cancelReminder(id: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["ppp-\(id.uuidString)"]
        )
    }

    func recordFollowUp(entry: RRPPPEntry, outcome: PPPOutcome, reflection: String?) {
        entry.outcome = outcome
        entry.followUpReflection = reflection?.isEmpty == true ? nil : reflection
    }

    func loadFromExisting(_ entry: RRPPPEntry) {
        prayer = entry.prayer ?? ""
        selectedContactIds = Set(entry.peopleContactIds ?? [])
        planBefore = entry.planBefore ?? ""
        planDuring = entry.planDuring ?? ""
        planAfter = entry.planAfter ?? ""
        reminderEnabled = entry.reminderTime != nil
        followUpOutcome = entry.outcome
        followUpReflection = entry.followUpReflection ?? ""
    }
}
