// internal/domain/tracking/types.go
package tracking

import "time"

// StreakData represents current streak information for an addiction.
type StreakData struct {
	StreakID              string
	AddictionID           string
	AddictionType         string
	CurrentStreakDays     int
	LongestStreakDays     int
	SobrietyStartDate     time.Time
	LastRelapseDate       *time.Time
	TotalSoberDaysLast30  int
	TotalSoberDaysLast90  int
	TotalSoberDaysLast365 int
	NextMilestone         *MilestoneInfo
}

// MilestoneInfo represents the next milestone information.
type MilestoneInfo struct {
	Days          int
	DaysRemaining int
	Label         string
}

// Milestone represents an achieved or upcoming milestone.
type Milestone struct {
	MilestoneID   string
	AddictionID   string
	AddictionType string
	Days          int
	Label         string
	AchievedAt    *time.Time
	DaysRemaining *int
	Celebrated    bool
	Scripture     string
}

// Relapse represents a relapse event.
type Relapse struct {
	RelapseID          string
	AddictionID        string
	UserID             string
	Timestamp          time.Time
	PreviousStreakDays int
	Notes              string
	PostMortemPrompted bool
	CreatedAt          time.Time
}

// CalendarEntry represents a single day in the calendar view.
type CalendarEntry struct {
	Date             time.Time
	SobrietyStatus   string // "clean", "relapse", "no-data"
	CheckInCompleted bool
	CheckInScore     *int
	UrgeCount        int
	Activities       map[string]bool
	HeatmapValue     int
}

// StreakResponse is the response envelope for streak data.
type StreakResponse struct {
	Data  StreakData             `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
}

// StreaksListResponse is the response envelope for multiple streaks.
type StreaksListResponse struct {
	Data []StreakData           `json:"data"`
	Meta map[string]interface{} `json:"meta"`
}

// MilestoneResponse is the response envelope for milestone data.
type MilestoneResponse struct {
	Data  Milestone              `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
}

// MilestonesListResponse is the response envelope for multiple milestones.
type MilestonesListResponse struct {
	Data []Milestone            `json:"data"`
	Meta map[string]interface{} `json:"meta"`
}

// RelapseResponse is the response envelope for relapse data.
type RelapseResponse struct {
	Data  Relapse                `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta"`
}

// CalendarResponse is the response envelope for calendar data.
type CalendarResponse struct {
	Data CalendarData           `json:"data"`
	Meta map[string]interface{} `json:"meta"`
}

// CalendarData contains the calendar month and daily entries.
type CalendarData struct {
	Month string          `json:"month"`
	Days  []CalendarEntry `json:"days"`
}

// CalendarDayResponse is the response envelope for detailed day view.
type CalendarDayResponse struct {
	Data  CalendarDayData   `json:"data"`
	Links map[string]string `json:"links,omitempty"`
}

// CalendarDayData contains detailed information for a single day.
type CalendarDayData struct {
	Date           time.Time
	SobrietyStatus string
	CheckIns       []CheckInSummary
	Urges          []UrgeSummary
	Activities     []ActivitySummary
}

// CheckInSummary represents a check-in entry.
type CheckInSummary struct {
	CheckInID string
	Type      string
	Score     int
	Timestamp time.Time
}

// UrgeSummary represents an urge entry.
type UrgeSummary struct {
	UrgeID             string
	Intensity          int
	Timestamp          time.Time
	SobrietyMaintained bool
}

// ActivitySummary represents an activity entry.
type ActivitySummary struct {
	ActivityType string
	Timestamp    time.Time
}
