import Foundation

@Observable
class GratitudeViewModel {

    // MARK: - State

    var todayItems: [String] = ["", "", ""]
    var history: [(date: Date, items: [String])] = []
    var isLoading = false
    var error: String?

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let data = try await loadFromStorage()
            todayItems = data.today
            history = data.history
        } catch {
            // Fallback to mock data
            todayItems = [
                "Morning quiet time with God",
                "Rachel's patience and love",
                "Progress in Step 8 work"
            ]
            let calendar = Calendar.current
            let today = Date()
            history = [
                (date: calendar.date(byAdding: .day, value: -1, to: today)!,
                 items: ["A good night's sleep", "Coffee with Mike", "Rachel's encouragement"]),
                (date: calendar.date(byAdding: .day, value: -2, to: today)!,
                 items: ["Sponsor call with James", "Beautiful weather", "Progress at work"]),
                (date: calendar.date(byAdding: .day, value: -3, to: today)!,
                 items: ["Morning prayer time", "Step study insights", "Kids' laughter"]),
                (date: calendar.date(byAdding: .day, value: -4, to: today)!,
                 items: ["SA meeting fellowship", "Honest conversation with Rachel", "Exercise endorphins"]),
                (date: calendar.date(byAdding: .day, value: -5, to: today)!,
                 items: ["God's grace", "Recovery community", "A new day"]),
            ]
            self.error = error.localizedDescription
        }
    }

    // MARK: - Submit

    func submit(items: [String]) async throws {
        let nonEmpty = items.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !nonEmpty.isEmpty else {
            throw ActivityError.validationFailed("Please enter at least one thing you are grateful for.")
        }

        // TODO: Replace with repository save
        let entry = (date: Date(), items: nonEmpty)
        history.insert(entry, at: 0)
        todayItems = ["", "", ""]
    }

    // MARK: - Computed

    var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()

        for entry in history.sorted(by: { $0.date > $1.date }) {
            if calendar.isDate(entry.date, inSameDayAs: checkDate) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }

        return streak
    }

    // MARK: - Private

    private func loadFromStorage() async throws -> (today: [String], history: [(date: Date, items: [String])]) {
        throw ActivityError.notImplemented
    }
}
