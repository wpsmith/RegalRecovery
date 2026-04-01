import Foundation

struct ExerciseEntry: Identifiable {
    let id: UUID
    let date: Date
    let durationMinutes: Int
    let activityType: String
    let notes: String

    init(id: UUID = UUID(), date: Date = Date(), durationMinutes: Int, activityType: String, notes: String = "") {
        self.id = id
        self.date = date
        self.durationMinutes = durationMinutes
        self.activityType = activityType
        self.notes = notes
    }
}

@Observable
class ExerciseViewModel {

    // MARK: - State

    var history: [ExerciseEntry] = []
    var isLoading = false
    var error: String?

    // Entry state
    var duration: Int = 30
    var activityType: String = "Run"
    var notes: String = ""

    static let activityTypes = ["Run", "Walk", "Weights", "Yoga", "Swimming", "Other"]

    // MARK: - Computed

    var totalMinutesThisWeek: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return history
            .filter { $0.date >= weekAgo }
            .reduce(0) { $0 + $1.durationMinutes }
    }

    var sessionsThisWeek: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return history.filter { $0.date >= weekAgo }.count
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
                ExerciseEntry(date: MockData.yesterday(hour: 6, minute: 30), durationMinutes: 30, activityType: "Run", notes: "Felt strong, good pace"),
                ExerciseEntry(date: MockData.daysAgo(2), durationMinutes: 45, activityType: "Weights", notes: "Upper body day"),
                ExerciseEntry(date: MockData.daysAgo(3), durationMinutes: 30, activityType: "Run", notes: "Easy morning jog"),
                ExerciseEntry(date: MockData.daysAgo(5), durationMinutes: 60, activityType: "Yoga", notes: "Great stretch session"),
                ExerciseEntry(date: MockData.daysAgo(6), durationMinutes: 35, activityType: "Run", notes: "Interval training"),
            ]
            self.error = error.localizedDescription
        }
    }

    // MARK: - Submit

    func submit() async throws {
        guard duration > 0 else {
            throw ActivityError.validationFailed("Duration must be greater than zero.")
        }

        let entry = ExerciseEntry(
            durationMinutes: duration,
            activityType: activityType,
            notes: notes
        )

        // TODO: Replace with repository save
        history.insert(entry, at: 0)
        resetForm()
    }

    // MARK: - Private

    private func resetForm() {
        duration = 30
        activityType = "Run"
        notes = ""
    }

    private func loadFromStorage() async throws -> [ExerciseEntry] {
        throw ActivityError.notImplemented
    }
}
