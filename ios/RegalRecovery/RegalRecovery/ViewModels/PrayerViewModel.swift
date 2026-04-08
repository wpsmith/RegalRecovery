import Foundation

// MARK: - Prayer Types (matches OpenAPI enum)

enum PrayerType: String, CaseIterable, Sendable {
    case personal
    case guided
    case group
    case scriptureBased
    case intercessory
    case listening

    var displayName: String {
        switch self {
        case .personal: return "Personal"
        case .guided: return "Guided"
        case .group: return "Group"
        case .scriptureBased: return "Scripture-Based"
        case .intercessory: return "Intercessory"
        case .listening: return "Listening"
        }
    }

    var icon: String {
        switch self {
        case .personal: return "person.fill"
        case .guided: return "book.fill"
        case .group: return "person.3.fill"
        case .scriptureBased: return "text.book.closed.fill"
        case .intercessory: return "hands.sparkles.fill"
        case .listening: return "ear.fill"
        }
    }
}

// MARK: - Prayer Entry (local model)

struct PrayerEntry: Identifiable {
    let id: UUID
    let prayerId: String
    let date: Date
    let durationMinutes: Int?
    let prayerType: PrayerType
    let notes: String?
    let linkedPrayerTitle: String?
    let moodBefore: Int?
    let moodAfter: Int?

    init(
        id: UUID = UUID(),
        prayerId: String = "",
        date: Date = Date(),
        durationMinutes: Int? = nil,
        prayerType: PrayerType = .personal,
        notes: String? = nil,
        linkedPrayerTitle: String? = nil,
        moodBefore: Int? = nil,
        moodAfter: Int? = nil
    ) {
        self.id = id
        self.prayerId = prayerId
        self.date = date
        self.durationMinutes = durationMinutes
        self.prayerType = prayerType
        self.notes = notes
        self.linkedPrayerTitle = linkedPrayerTitle
        self.moodBefore = moodBefore
        self.moodAfter = moodAfter
    }
}

// MARK: - Prayer Stats (local model)

struct PrayerStatsLocal {
    var currentStreakDays: Int = 0
    var longestStreakDays: Int = 0
    var totalPrayerDays: Int = 0
    var sessionsThisWeek: Int = 0
    var averageDurationMinutes: Double? = nil
}

// MARK: - Prayer ViewModel

@Observable
class PrayerViewModel {

    // MARK: - State

    var history: [PrayerEntry] = []
    var stats: PrayerStatsLocal = PrayerStatsLocal()
    var isLoading = false
    var error: String?

    // Entry form state.
    var duration: Int? = nil
    var prayerType: PrayerType = .personal
    var notes: String = ""
    var moodBefore: Int? = nil
    var moodAfter: Int? = nil

    // Streak break compassion message (PR-AC5.4).
    var compassionMessage: String?

    // MARK: - Computed

    var totalMinutesThisWeek: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return history
            .filter { $0.date >= weekAgo }
            .compactMap { $0.durationMinutes }
            .reduce(0, +)
    }

    var hasStreakBreak: Bool {
        stats.currentStreakDays == 0 && stats.totalPrayerDays > 0
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            history = try await loadFromStorage()
        } catch {
            // Fallback to mock data.
            history = [
                PrayerEntry(date: MockData.today(hour: 6), durationMinutes: 12, prayerType: .personal),
                PrayerEntry(date: MockData.yesterday(hour: 6, minute: 15), durationMinutes: 15, prayerType: .guided, linkedPrayerTitle: "Step 4 Prayer"),
                PrayerEntry(date: MockData.yesterday(hour: 21), durationMinutes: 8, prayerType: .listening),
                PrayerEntry(date: MockData.daysAgo(2), durationMinutes: 10, prayerType: .personal),
                PrayerEntry(date: MockData.daysAgo(3), durationMinutes: 20, prayerType: .scriptureBased, moodBefore: 2, moodAfter: 4),
            ]
            stats = PrayerStatsLocal(
                currentStreakDays: 4,
                longestStreakDays: 14,
                totalPrayerDays: 87,
                sessionsThisWeek: 5,
                averageDurationMinutes: 12.0
            )
            self.error = error.localizedDescription
        }

        // PR-AC5.4: Show compassion message if streak is broken.
        if hasStreakBreak {
            compassionMessage = "Every conversation with God is a fresh start. Welcome back."
        } else {
            compassionMessage = nil
        }
    }

    // MARK: - Submit (PR-AC1.1)

    func submit() async throws {
        let entry = PrayerEntry(
            prayerId: "ps_\(UUID().uuidString.prefix(8))",
            durationMinutes: duration,
            prayerType: prayerType,
            notes: notes.isEmpty ? nil : notes,
            moodBefore: moodBefore,
            moodAfter: moodAfter
        )

        // TODO: Replace with API call via PrayerSessionService.
        history.insert(entry, at: 0)
        resetForm()
    }

    // MARK: - Quick Log (PR-AC1.11)

    func quickLog() async throws {
        let entry = PrayerEntry(
            prayerId: "ps_\(UUID().uuidString.prefix(8))",
            durationMinutes: nil,
            prayerType: .personal
        )

        // TODO: Replace with API call via PrayerSessionService.quickLog().
        history.insert(entry, at: 0)
    }

    // MARK: - Private

    private func resetForm() {
        duration = nil
        prayerType = .personal
        notes = ""
        moodBefore = nil
        moodAfter = nil
    }

    private func loadFromStorage() async throws -> [PrayerEntry] {
        throw ActivityError.notImplemented
    }
}
