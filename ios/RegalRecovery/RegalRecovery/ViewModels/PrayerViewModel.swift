import Foundation

struct PrayerEntry: Identifiable {
    let id: UUID
    let date: Date
    let durationMinutes: Int
    let prayerType: String

    init(id: UUID = UUID(), date: Date = Date(), durationMinutes: Int, prayerType: String) {
        self.id = id
        self.date = date
        self.durationMinutes = durationMinutes
        self.prayerType = prayerType
    }
}

@Observable
class PrayerViewModel {

    // MARK: - State

    var history: [PrayerEntry] = []
    var isLoading = false
    var error: String?

    // Entry state
    var duration: Int = 12
    var prayerType: String = "Morning"

    static let prayerTypes = ["Morning", "Evening", "Intercessory", "Meditative", "Free"]

    // MARK: - Computed

    var totalMinutesThisWeek: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return history
            .filter { $0.date >= weekAgo }
            .reduce(0) { $0 + $1.durationMinutes }
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            history = try await loadFromStorage()
        } catch {
            // Fallback to mock data
            history = [
                PrayerEntry(date: MockData.today(hour: 6), durationMinutes: 12, prayerType: "Morning"),
                PrayerEntry(date: MockData.yesterday(hour: 6, minute: 15), durationMinutes: 15, prayerType: "Morning"),
                PrayerEntry(date: MockData.yesterday(hour: 21), durationMinutes: 8, prayerType: "Evening"),
                PrayerEntry(date: MockData.daysAgo(2), durationMinutes: 10, prayerType: "Morning"),
                PrayerEntry(date: MockData.daysAgo(3), durationMinutes: 20, prayerType: "Meditative"),
            ]
            self.error = error.localizedDescription
        }
    }

    // MARK: - Submit

    func submit() async throws {
        guard duration > 0 else {
            throw ActivityError.validationFailed("Duration must be greater than zero.")
        }

        let entry = PrayerEntry(
            durationMinutes: duration,
            prayerType: prayerType
        )

        // TODO: Replace with repository save
        history.insert(entry, at: 0)
        resetForm()
    }

    // MARK: - Private

    private func resetForm() {
        duration = 12
        prayerType = "Morning"
    }

    private func loadFromStorage() async throws -> [PrayerEntry] {
        throw ActivityError.notImplemented
    }
}
