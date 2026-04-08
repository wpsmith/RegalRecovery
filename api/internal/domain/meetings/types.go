// internal/domain/meetings/types.go
package meetings

import "time"

// MeetingType represents the type of recovery meeting.
type MeetingType string

const (
	MeetingTypeSA              MeetingType = "SA"
	MeetingTypeCR              MeetingType = "CR"
	MeetingTypeAA              MeetingType = "AA"
	MeetingTypeTherapy         MeetingType = "therapy"
	MeetingTypeGroupCounseling MeetingType = "group-counseling"
	MeetingTypeChurch          MeetingType = "church"
	MeetingTypeCustom          MeetingType = "custom"
)

// validMeetingTypes contains all valid meeting types.
var validMeetingTypes = map[MeetingType]bool{
	MeetingTypeSA:              true,
	MeetingTypeCR:              true,
	MeetingTypeAA:              true,
	MeetingTypeTherapy:         true,
	MeetingTypeGroupCounseling: true,
	MeetingTypeChurch:          true,
	MeetingTypeCustom:          true,
}

// IsValidMeetingType returns true if the meeting type is valid.
// SAA is explicitly excluded per project requirements.
func IsValidMeetingType(mt MeetingType) bool {
	return validMeetingTypes[mt]
}

// MeetingStatus represents whether a meeting was attended or canceled.
type MeetingStatus string

const (
	MeetingStatusAttended MeetingStatus = "attended"
	MeetingStatusCanceled MeetingStatus = "canceled"
)

// IsValidMeetingStatus returns true if the status is valid.
func IsValidMeetingStatus(ms MeetingStatus) bool {
	return ms == MeetingStatusAttended || ms == MeetingStatusCanceled
}

// DayOfWeek represents a day of the week for scheduling.
type DayOfWeek string

const (
	DayMonday    DayOfWeek = "monday"
	DayTuesday   DayOfWeek = "tuesday"
	DayWednesday DayOfWeek = "wednesday"
	DayThursday  DayOfWeek = "thursday"
	DayFriday    DayOfWeek = "friday"
	DaySaturday  DayOfWeek = "saturday"
	DaySunday    DayOfWeek = "sunday"
)

// validDays contains all valid days of the week.
var validDays = map[DayOfWeek]bool{
	DayMonday: true, DayTuesday: true, DayWednesday: true,
	DayThursday: true, DayFriday: true, DaySaturday: true, DaySunday: true,
}

// SummaryPeriod represents the time period for attendance summaries.
type SummaryPeriod string

const (
	PeriodWeek    SummaryPeriod = "week"
	PeriodMonth   SummaryPeriod = "month"
	PeriodQuarter SummaryPeriod = "quarter"
	PeriodYear    SummaryPeriod = "year"
)

// IsValidSummaryPeriod returns true if the period is valid.
func IsValidSummaryPeriod(p SummaryPeriod) bool {
	return p == PeriodWeek || p == PeriodMonth || p == PeriodQuarter || p == PeriodYear
}

// MeetingLog represents a single meeting attendance log entry.
type MeetingLog struct {
	MeetingID       string        `json:"meetingId"`
	UserID          string        `json:"-"`
	TenantID        string        `json:"-"`
	Timestamp       time.Time     `json:"timestamp"`
	MeetingType     MeetingType   `json:"meetingType"`
	CustomTypeLabel *string       `json:"customTypeLabel"`
	Name            *string       `json:"name"`
	Location        *string       `json:"location"`
	DurationMinutes *int          `json:"durationMinutes"`
	Notes           *string       `json:"notes"`
	Status          MeetingStatus `json:"status"`
	SavedMeetingID  *string       `json:"savedMeetingId"`
	CreatedAt       time.Time     `json:"createdAt"`
	ModifiedAt      time.Time     `json:"modifiedAt"`
}

// MeetingSchedule represents a recurring meeting schedule.
type MeetingSchedule struct {
	DayOfWeek DayOfWeek `json:"dayOfWeek"`
	Time      string    `json:"time"`     // HH:mm format
	TimeZone  string    `json:"timeZone"` // IANA timezone
}

// SavedMeeting represents a saved meeting template for one-tap logging.
type SavedMeeting struct {
	SavedMeetingID       string           `json:"savedMeetingId"`
	UserID               string           `json:"-"`
	TenantID             string           `json:"-"`
	Name                 string           `json:"name"`
	MeetingType          MeetingType      `json:"meetingType"`
	CustomTypeLabel      *string          `json:"customTypeLabel"`
	Location             *string          `json:"location"`
	Schedule             *MeetingSchedule `json:"schedule"`
	ReminderMinutesBefore *int            `json:"reminderMinutesBefore"`
	IsActive             bool             `json:"isActive"`
	CreatedAt            time.Time        `json:"createdAt"`
	ModifiedAt           time.Time        `json:"modifiedAt"`
}

// AttendanceSummary represents meeting attendance statistics for a period.
type AttendanceSummary struct {
	Period        SummaryPeriod  `json:"period"`
	StartDate     string         `json:"startDate"` // YYYY-MM-DD
	EndDate       string         `json:"endDate"`   // YYYY-MM-DD
	TotalCount    int            `json:"totalCount"`
	CanceledCount int            `json:"canceledCount"`
	ByType        map[string]int `json:"byType"`
}

// --- Request types ---

// CreateMeetingLogRequest represents a request to log meeting attendance.
type CreateMeetingLogRequest struct {
	Timestamp       time.Time   `json:"timestamp"`
	MeetingType     MeetingType `json:"meetingType"`
	CustomTypeLabel *string     `json:"customTypeLabel"`
	Name            *string     `json:"name"`
	Location        *string     `json:"location"`
	DurationMinutes *int        `json:"durationMinutes"`
	Notes           *string     `json:"notes"`
	SavedMeetingID  *string     `json:"savedMeetingId"`
}

// UpdateMeetingLogRequest represents a partial update to a meeting log.
// The timestamp field is intentionally omitted because it is immutable (FR2.7).
type UpdateMeetingLogRequest struct {
	MeetingType     *MeetingType   `json:"meetingType"`
	CustomTypeLabel *string        `json:"customTypeLabel"`
	Name            *string        `json:"name"`
	Location        *string        `json:"location"`
	DurationMinutes *int           `json:"durationMinutes"`
	Notes           *string        `json:"notes"`
	Status          *MeetingStatus `json:"status"`
}

// CreateSavedMeetingRequest represents a request to create a saved meeting template.
type CreateSavedMeetingRequest struct {
	Name                  string           `json:"name"`
	MeetingType           MeetingType      `json:"meetingType"`
	CustomTypeLabel       *string          `json:"customTypeLabel"`
	Location              *string          `json:"location"`
	Schedule              *MeetingSchedule `json:"schedule"`
	ReminderMinutesBefore *int             `json:"reminderMinutesBefore"`
}

// UpdateSavedMeetingRequest represents a partial update to a saved meeting template.
type UpdateSavedMeetingRequest struct {
	Name                  *string          `json:"name"`
	MeetingType           *MeetingType     `json:"meetingType"`
	CustomTypeLabel       *string          `json:"customTypeLabel"`
	Location              *string          `json:"location"`
	Schedule              *MeetingSchedule `json:"schedule"`
	ReminderMinutesBefore *int             `json:"reminderMinutesBefore"`
}

// ListMeetingLogsFilter holds query parameters for listing meeting logs.
type ListMeetingLogsFilter struct {
	MeetingType *MeetingType
	StartDate   *time.Time
	EndDate     *time.Time
	Cursor      string
	Limit       int
	Sort        string // "-timestamp" (desc, default) or "timestamp" (asc)
}

// --- Response envelope types ---

// MeetingLogLinks contains HATEOAS links for a meeting log.
type MeetingLogLinks struct {
	Self string `json:"self"`
}

// MeetingLogResponse is the Siemens-envelope response for a single meeting log.
type MeetingLogResponse struct {
	Data MeetingLogData         `json:"data"`
	Meta map[string]interface{} `json:"meta"`
}

// MeetingLogData is the data payload for a meeting log response, including links.
type MeetingLogData struct {
	MeetingID       string         `json:"meetingId"`
	Timestamp       time.Time      `json:"timestamp"`
	MeetingType     MeetingType    `json:"meetingType"`
	CustomTypeLabel *string        `json:"customTypeLabel,omitempty"`
	Name            *string        `json:"name,omitempty"`
	Location        *string        `json:"location,omitempty"`
	DurationMinutes *int           `json:"durationMinutes,omitempty"`
	Notes           *string        `json:"notes,omitempty"`
	Status          MeetingStatus  `json:"status"`
	SavedMeetingID  *string        `json:"savedMeetingId,omitempty"`
	Links           MeetingLogLinks `json:"links"`
}

// MeetingLogListResponse is the paginated list response for meeting logs.
type MeetingLogListResponse struct {
	Data  []MeetingLogData       `json:"data"`
	Links map[string]interface{} `json:"links"`
	Meta  map[string]interface{} `json:"meta"`
}

// SavedMeetingLinks contains HATEOAS links for a saved meeting.
type SavedMeetingLinks struct {
	Self string `json:"self"`
}

// SavedMeetingData is the data payload for a saved meeting response.
type SavedMeetingData struct {
	SavedMeetingID       string            `json:"savedMeetingId"`
	Name                 string            `json:"name"`
	MeetingType          MeetingType       `json:"meetingType"`
	CustomTypeLabel      *string           `json:"customTypeLabel,omitempty"`
	Location             *string           `json:"location,omitempty"`
	Schedule             *MeetingSchedule  `json:"schedule,omitempty"`
	ReminderMinutesBefore *int             `json:"reminderMinutesBefore,omitempty"`
	IsActive             bool              `json:"isActive"`
	Links                SavedMeetingLinks `json:"links"`
}

// SavedMeetingResponse is the Siemens-envelope response for a single saved meeting.
type SavedMeetingResponse struct {
	Data SavedMeetingData       `json:"data"`
	Meta map[string]interface{} `json:"meta"`
}

// SavedMeetingListResponse is the response for listing saved meetings.
type SavedMeetingListResponse struct {
	Data []SavedMeetingData     `json:"data"`
	Meta map[string]interface{} `json:"meta"`
}

// AttendanceSummaryResponse is the Siemens-envelope response for attendance summary.
type AttendanceSummaryResponse struct {
	Data AttendanceSummary      `json:"data"`
	Meta map[string]interface{} `json:"meta"`
}
