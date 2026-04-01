import Foundation

struct PhoneCallEntry: Identifiable {
    let id: UUID
    let date: Date
    let contactName: String
    let contactRole: String
    let durationMinutes: Int
    let notes: String

    init(id: UUID = UUID(), date: Date = Date(), contactName: String, contactRole: String, durationMinutes: Int, notes: String = "") {
        self.id = id
        self.date = date
        self.contactName = contactName
        self.contactRole = contactRole
        self.durationMinutes = durationMinutes
        self.notes = notes
    }
}

@Observable
class PhoneCallViewModel {

    // MARK: - State

    var history: [PhoneCallEntry] = []
    var isLoading = false
    var error: String?

    // Entry state
    var selectedContactIndex: Int = 0
    var durationMinutes: Int = 15
    var notes: String = ""

    // MARK: - Computed

    var availableContacts: [SupportContact] {
        MockData.supportNetwork
    }

    var callsThisWeek: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return history.filter { $0.date >= weekAgo }.count
    }

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
                PhoneCallEntry(date: MockData.daysAgo(2), contactName: "James", contactRole: "Sponsor", durationMinutes: 18, notes: "Discussed Step 8 amends list"),
                PhoneCallEntry(date: MockData.daysAgo(4), contactName: "Mike", contactRole: "Accountability Partner", durationMinutes: 12, notes: "Accountability check-in"),
                PhoneCallEntry(date: MockData.daysAgo(5), contactName: "James", contactRole: "Sponsor", durationMinutes: 25, notes: "Weekly sponsor call"),
                PhoneCallEntry(date: MockData.daysAgo(7), contactName: "Dr. Sarah", contactRole: "Counselor (CSAT)", durationMinutes: 50, notes: "Therapy session follow-up"),
                PhoneCallEntry(date: MockData.daysAgo(7), contactName: "Mike", contactRole: "Accountability Partner", durationMinutes: 10, notes: "Quick encouragement call"),
            ]
            self.error = error.localizedDescription
        }
    }

    // MARK: - Submit

    func submit() async throws {
        guard durationMinutes > 0 else {
            throw ActivityError.validationFailed("Duration must be greater than zero.")
        }
        guard selectedContactIndex >= 0, selectedContactIndex < availableContacts.count else {
            throw ActivityError.validationFailed("Please select a contact.")
        }

        let contact = availableContacts[selectedContactIndex]
        let entry = PhoneCallEntry(
            contactName: contact.name,
            contactRole: contact.role.rawValue,
            durationMinutes: durationMinutes,
            notes: notes
        )

        // TODO: Replace with repository save
        history.insert(entry, at: 0)
        resetForm()
    }

    // MARK: - Private

    private func resetForm() {
        selectedContactIndex = 0
        durationMinutes = 15
        notes = ""
    }

    private func loadFromStorage() async throws -> [PhoneCallEntry] {
        throw ActivityError.notImplemented
    }
}
