import Foundation
import Observation

@Observable
class MeetingFinderViewModel {
    var meetings: [Meeting] = []
    var savedMeetings: [Meeting] = []
    var activeFilters: Set<String> = []

    var filteredMeetings: [Meeting] {
        guard !activeFilters.isEmpty else { return meetings }

        return meetings.filter { meeting in
            for filter in activeFilters {
                switch filter.lowercased() {
                case "sa", "cr":
                    if meeting.fellowship.lowercased() != filter.lowercased() {
                        return false
                    }
                case "virtual":
                    if !meeting.isVirtual { return false }
                case "in-person":
                    if meeting.isVirtual { return false }
                case "saved":
                    if !meeting.isSaved { return false }
                default:
                    // Day-of-week filter
                    if meeting.day.lowercased() != filter.lowercased()
                        && meeting.day.lowercased() != "daily" {
                        return false
                    }
                }
            }
            return true
        }
    }

    func load() async {
        meetings = MockData.meetings
        savedMeetings = meetings.filter(\.isSaved)
    }

    func toggleSaved(_ meeting: Meeting) async throws {
        guard let index = meetings.firstIndex(where: { $0.id == meeting.id }) else { return }

        let existing = meetings[index]
        let toggled = Meeting(
            name: existing.name,
            fellowship: existing.fellowship,
            day: existing.day,
            time: existing.time,
            distance: existing.distance,
            location: existing.location,
            isVirtual: existing.isVirtual,
            isSaved: !existing.isSaved,
            latitude: existing.latitude,
            longitude: existing.longitude
        )
        meetings[index] = toggled
        savedMeetings = meetings.filter(\.isSaved)
    }

    func toggleFilter(_ filter: String) {
        if activeFilters.contains(filter) {
            activeFilters.remove(filter)
        } else {
            activeFilters.insert(filter)
        }
    }

    func logAttendance(_ meeting: Meeting) async throws {
        // In production this would create an ActivityEntry for meetings attended
        // and persist it via SwiftData. For now this is a placeholder.
        _ = meeting
    }
}
