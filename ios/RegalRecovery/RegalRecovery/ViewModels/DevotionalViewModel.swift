import Foundation
import Observation

@Observable
class DevotionalViewModel {
    var days: [DevotionalDay] = []
    var currentDay: Int = 24
    var completedDays: Int = 23

    func load() async {
        days = MockData.devotionalDays
        completedDays = days.filter(\.isComplete).count
        currentDay = completedDays + 1
    }

    func markComplete(day: Int) async throws {
        guard let index = days.firstIndex(where: { $0.day == day }) else { return }

        let existing = days[index]
        days[index] = DevotionalDay(
            day: existing.day,
            title: existing.title,
            scripture: existing.scripture,
            scriptureText: existing.scriptureText,
            reflection: existing.reflection,
            isComplete: true
        )

        completedDays = days.filter(\.isComplete).count
        currentDay = min(completedDays + 1, days.count)
    }

    func getDayDetail(day: Int) -> DevotionalDay? {
        days.first(where: { $0.day == day })
    }
}
