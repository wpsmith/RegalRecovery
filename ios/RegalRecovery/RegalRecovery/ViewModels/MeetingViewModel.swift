import Foundation

struct MeetingAttendance: Identifiable {
    let id: UUID
    let date: Date
    let meetingName: String
    let location: String
    let durationMinutes: Int
    let notes: String

    init(id: UUID = UUID(), date: Date = Date(), meetingName: String, location: String, durationMinutes: Int, notes: String = "") {
        self.id = id
        self.date = date
        self.meetingName = meetingName
        self.location = location
        self.durationMinutes = durationMinutes
        self.notes = notes
    }
}

@Observable
class MeetingViewModel {

    // MARK: - State

    var attendanceHistory: [MeetingAttendance] = []
    var isLoading = false
    var error: String?

    // Entry state
    var selectedMeetingIndex: Int = 0
    var meetingDate: Date = Date()
    var duration: Int = 60
    var notes: String = ""

    // MARK: - Computed

    var availableMeetings: [Meeting] {
        MockData.meetings
    }

    var savedMeetings: [Meeting] {
        MockData.meetings.filter(\.isSaved)
    }

    var meetingsThisWeek: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return attendanceHistory.filter { $0.date >= weekAgo }.count
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            attendanceHistory = try await loadFromStorage()
        } catch {
            // Fallback to mock data
            attendanceHistory = [
                MeetingAttendance(date: MockData.daysAgo(0), meetingName: "SA Home Group", location: "First Baptist Church, Austin TX", durationMinutes: 75),
                MeetingAttendance(date: MockData.daysAgo(2), meetingName: "SA Step Study", location: "Zoom", durationMinutes: 60),
                MeetingAttendance(date: MockData.daysAgo(7), meetingName: "SA Home Group", location: "First Baptist Church, Austin TX", durationMinutes: 70),
                MeetingAttendance(date: MockData.daysAgo(9), meetingName: "SA Men's Meeting", location: "Community Center, Austin TX", durationMinutes: 65),
                MeetingAttendance(date: MockData.daysAgo(9), meetingName: "SA Step Study", location: "Zoom", durationMinutes: 55),
            ]
            self.error = error.localizedDescription
        }
    }

    // MARK: - Submit

    func submit() async throws {
        guard selectedMeetingIndex >= 0, selectedMeetingIndex < availableMeetings.count else {
            throw ActivityError.validationFailed("Please select a meeting.")
        }
        guard duration > 0 else {
            throw ActivityError.validationFailed("Duration must be greater than zero.")
        }

        let meeting = availableMeetings[selectedMeetingIndex]
        let entry = MeetingAttendance(
            date: meetingDate,
            meetingName: meeting.name,
            location: meeting.location,
            durationMinutes: duration,
            notes: notes
        )

        // TODO: Replace with repository save
        attendanceHistory.insert(entry, at: 0)
        resetForm()
    }

    // MARK: - Private

    private func resetForm() {
        selectedMeetingIndex = 0
        meetingDate = Date()
        duration = 60
        notes = ""
    }

    private func loadFromStorage() async throws -> [MeetingAttendance] {
        throw ActivityError.notImplemented
    }
}
