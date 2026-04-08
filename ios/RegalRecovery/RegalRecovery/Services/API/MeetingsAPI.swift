import Foundation

// MARK: - Meeting Types

/// Meeting type matching the OpenAPI MeetingType enum.
/// SA = Sexaholics Anonymous, CR = Celebrate Recovery.
/// SAA is explicitly excluded per project requirements.
enum MeetingType: String, Codable, Sendable, CaseIterable {
    case sa = "SA"
    case cr = "CR"
    case aa = "AA"
    case therapy
    case groupCounseling = "group-counseling"
    case church
    case custom
}

/// Meeting attendance status.
enum MeetingStatus: String, Codable, Sendable {
    case attended
    case canceled
}

/// Day of the week for recurring meeting schedules.
enum MeetingDayOfWeek: String, Codable, Sendable, CaseIterable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
}

/// Summary period for attendance statistics.
enum MeetingSummaryPeriod: String, Codable, Sendable {
    case week, month, quarter, year
}

// MARK: - Meeting Log Models

/// Meeting log data matching the OpenAPI MeetingLog schema.
struct MeetingLogData: Codable, Sendable, Identifiable {
    let meetingId: String
    let timestamp: Date
    let meetingType: MeetingType
    let customTypeLabel: String?
    let name: String?
    let location: String?
    let durationMinutes: Int?
    let notes: String?
    let status: MeetingStatus
    let savedMeetingId: String?
    let links: MeetingLinks?

    var id: String { meetingId }

    struct MeetingLinks: Codable, Sendable {
        let `self`: String?
    }
}

/// Request body for creating a meeting log.
struct CreateMeetingLogRequest: Codable, Sendable {
    let timestamp: String // ISO 8601
    let meetingType: MeetingType
    let customTypeLabel: String?
    let name: String?
    let location: String?
    let durationMinutes: Int?
    let notes: String?
    let savedMeetingId: String?

    init(
        timestamp: Date,
        meetingType: MeetingType,
        customTypeLabel: String? = nil,
        name: String? = nil,
        location: String? = nil,
        durationMinutes: Int? = nil,
        notes: String? = nil,
        savedMeetingId: String? = nil
    ) {
        let formatter = ISO8601DateFormatter()
        self.timestamp = formatter.string(from: timestamp)
        self.meetingType = meetingType
        self.customTypeLabel = customTypeLabel
        self.name = name
        self.location = location
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.savedMeetingId = savedMeetingId
    }
}

/// Request body for updating a meeting log.
/// Timestamp is intentionally omitted because it is immutable (FR2.7).
struct UpdateMeetingLogRequest: Codable, Sendable {
    let meetingType: MeetingType?
    let customTypeLabel: String?
    let name: String?
    let location: String?
    let durationMinutes: Int?
    let notes: String?
    let status: MeetingStatus?

    init(
        meetingType: MeetingType? = nil,
        customTypeLabel: String? = nil,
        name: String? = nil,
        location: String? = nil,
        durationMinutes: Int? = nil,
        notes: String? = nil,
        status: MeetingStatus? = nil
    ) {
        self.meetingType = meetingType
        self.customTypeLabel = customTypeLabel
        self.name = name
        self.location = location
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.status = status
    }
}

// MARK: - Saved Meeting Models

/// Meeting schedule for recurring meetings.
struct MeetingScheduleData: Codable, Sendable {
    let dayOfWeek: MeetingDayOfWeek
    let time: String // HH:mm
    let timeZone: String // IANA timezone

    init(dayOfWeek: MeetingDayOfWeek, time: String, timeZone: String) {
        self.dayOfWeek = dayOfWeek
        self.time = time
        self.timeZone = timeZone
    }
}

/// Saved meeting template data matching the OpenAPI SavedMeeting schema.
struct SavedMeetingData: Codable, Sendable, Identifiable {
    let savedMeetingId: String
    let name: String
    let meetingType: MeetingType
    let customTypeLabel: String?
    let location: String?
    let schedule: MeetingScheduleData?
    let reminderMinutesBefore: Int?
    let isActive: Bool
    let links: SavedMeetingLinks?

    var id: String { savedMeetingId }

    struct SavedMeetingLinks: Codable, Sendable {
        let `self`: String?
    }
}

/// Request body for creating a saved meeting template.
struct CreateSavedMeetingRequest: Codable, Sendable {
    let name: String
    let meetingType: MeetingType
    let customTypeLabel: String?
    let location: String?
    let schedule: MeetingScheduleData?
    let reminderMinutesBefore: Int?

    init(
        name: String,
        meetingType: MeetingType,
        customTypeLabel: String? = nil,
        location: String? = nil,
        schedule: MeetingScheduleData? = nil,
        reminderMinutesBefore: Int? = nil
    ) {
        self.name = name
        self.meetingType = meetingType
        self.customTypeLabel = customTypeLabel
        self.location = location
        self.schedule = schedule
        self.reminderMinutesBefore = reminderMinutesBefore
    }
}

/// Request body for updating a saved meeting template.
struct UpdateSavedMeetingRequest: Codable, Sendable {
    let name: String?
    let meetingType: MeetingType?
    let customTypeLabel: String?
    let location: String?
    let schedule: MeetingScheduleData?
    let reminderMinutesBefore: Int?

    init(
        name: String? = nil,
        meetingType: MeetingType? = nil,
        customTypeLabel: String? = nil,
        location: String? = nil,
        schedule: MeetingScheduleData? = nil,
        reminderMinutesBefore: Int? = nil
    ) {
        self.name = name
        self.meetingType = meetingType
        self.customTypeLabel = customTypeLabel
        self.location = location
        self.schedule = schedule
        self.reminderMinutesBefore = reminderMinutesBefore
    }
}

// MARK: - Attendance Summary

/// Attendance summary data matching the OpenAPI AttendanceSummary schema.
struct AttendanceSummaryData: Codable, Sendable {
    let period: MeetingSummaryPeriod
    let startDate: String // YYYY-MM-DD
    let endDate: String   // YYYY-MM-DD
    let totalCount: Int
    let canceledCount: Int
    let byType: [String: Int]
}
