import Foundation
import Observation
import UserNotifications

@Observable
class NotificationViewModel {
    var settings: [NotificationSetting] = []

    func load() {
        settings = MockData.notificationSettings
    }

    func toggle(id: UUID, enabled: Bool) async throws {
        guard let index = settings.firstIndex(where: { $0.id == id }) else { return }
        settings[index].isEnabled = enabled

        if enabled {
            await scheduleNotifications()
        } else {
            removeNotification(for: settings[index])
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

    func scheduleNotifications() async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for setting in settings where setting.isEnabled {
            let content = UNMutableNotificationContent()
            content.title = "Regal Recovery"
            content.body = notificationBody(for: setting.title)
            content.sound = .default

            guard let components = dateComponents(from: setting.time) else { continue }

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: setting.id.uuidString,
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
            } catch {
                // Notification scheduling failed — silently continue for other settings
            }
        }
    }

    // MARK: - Private

    private func removeNotification(for setting: NotificationSetting) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [setting.id.uuidString])
    }

    private func notificationBody(for title: String) -> String {
        switch title {
        case "Morning Commitment":
            return "Start your day with a sobriety commitment."
        case "Evening Review":
            return "Take a moment to review your day."
        case "Daily Affirmation":
            return "Your daily affirmation is ready."
        case "Meeting Reminders":
            return "You have a meeting coming up."
        default:
            return "Time for \(title)."
        }
    }

    private func dateComponents(from timeString: String) -> DateComponents? {
        // Parse times like "6:00 AM", "9:00 PM"
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        guard let date = formatter.date(from: timeString) else { return nil }

        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = calendar.component(.hour, from: date)
        components.minute = calendar.component(.minute, from: date)
        return components
    }
}
