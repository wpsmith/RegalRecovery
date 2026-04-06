// internal/domain/timejournal/types.go
package timejournal

import "time"

// TimeJournalMode represents the journaling interval mode.
type TimeJournalMode string

const (
	// ModeT30 is the 30-minute interval mode (48 slots per day).
	ModeT30 TimeJournalMode = "T30"
	// ModeT60 is the 60-minute interval mode (24 slots per day).
	ModeT60 TimeJournalMode = "T60"
)

// TotalSlots returns the number of slots per day for the mode.
func (m TimeJournalMode) TotalSlots() int {
	switch m {
	case ModeT30:
		return 48
	case ModeT60:
		return 24
	default:
		return 24
	}
}

// SlotDurationMinutes returns the slot duration in minutes.
func (m TimeJournalMode) SlotDurationMinutes() int {
	switch m {
	case ModeT30:
		return 30
	case ModeT60:
		return 60
	default:
		return 60
	}
}

// DayStatus represents the completion status of a journal day.
type DayStatus string

const (
	// StatusInProgress means the day is still active with future slots remaining.
	StatusInProgress DayStatus = "in-progress"
	// StatusOverdue means one or more elapsed slots are unfilled.
	StatusOverdue DayStatus = "overdue"
	// StatusCompleted means all slots are filled and the final slot has elapsed.
	StatusCompleted DayStatus = "completed"
)

// PersonPresent represents a person recorded in a time slot.
type PersonPresent struct {
	Name   string  `json:"name"`
	Gender *string `json:"gender,omitempty"`
}

// Emotion represents an emotional state recorded in a time slot.
type Emotion struct {
	Name      string  `json:"name"`
	Intensity int     `json:"intensity"` // 1-10
	Why       *string `json:"why,omitempty"`
}

// TimeJournalEntry represents a single time journal slot entry.
type TimeJournalEntry struct {
	ID                   string                 `json:"entryId"`
	UserID               string                 `json:"userId"`
	Date                 string                 `json:"date"`                           // YYYY-MM-DD
	SlotStart            string                 `json:"slotStart"`                      // HH:MM:SS
	SlotEnd              string                 `json:"slotEnd"`                        // HH:MM:SS
	Mode                 TimeJournalMode        `json:"mode"`                           // T30 or T60
	Location             *string                `json:"location,omitempty"`             // free-text location
	GPSLatitude          *float64               `json:"gpsLatitude,omitempty"`          // GPS latitude
	GPSLongitude         *float64               `json:"gpsLongitude,omitempty"`         // GPS longitude
	GPSAddress           *string                `json:"gpsAddress,omitempty"`           // reverse-geocoded address
	Activity             *string                `json:"activity,omitempty"`             // what the user was doing
	People               []PersonPresent        `json:"people,omitempty"`               // who was present
	Emotions             []Emotion              `json:"emotions,omitempty"`             // emotions felt
	Extras               map[string]interface{} `json:"extras,omitempty"`               // extensible key-value data
	SleepFlag            bool                   `json:"sleepFlag"`                      // true if user was asleep
	Retroactive          bool                   `json:"retroactive"`                    // true if filled after the slot elapsed
	RetroactiveTimestamp *time.Time             `json:"retroactiveTimestamp,omitempty"` // when the retroactive entry was created
	AutoFilled           bool                   `json:"autoFilled"`                     // true if auto-populated
	AutoFillSource       *string                `json:"autoFillSource,omitempty"`       // source of auto-fill data
	RedlineNote          *string                `json:"redlineNote,omitempty"`          // high-risk annotation
	CreatedAt            time.Time              `json:"createdAt"`
	ModifiedAt           time.Time              `json:"modifiedAt"`
	Links                map[string]string      `json:"links,omitempty"`
}

// TimeJournalDay represents an aggregated summary for a single journal day.
type TimeJournalDay struct {
	Date             string            `json:"date"`             // YYYY-MM-DD
	Mode             TimeJournalMode   `json:"mode"`             // T30 or T60
	TotalSlots       int               `json:"totalSlots"`       // 24 or 48
	FilledSlots      int               `json:"filledSlots"`      // number of completed slots
	CompletionScore  float64           `json:"completionScore"`  // filledSlots / totalSlots
	Status           DayStatus         `json:"status"`           // in-progress, overdue, completed
	OverdueSlotCount int               `json:"overdueSlotCount"` // number of elapsed but unfilled slots
	LastUpdatedAt    time.Time         `json:"lastUpdatedAt"`
	Links            map[string]string `json:"links,omitempty"`
}

// NextMilestone represents the next streak milestone target.
type NextMilestone struct {
	Days          int    `json:"days"`
	DaysRemaining int    `json:"daysRemaining"`
	Label         string `json:"label"`
}

// TimeJournalStreak represents streak data for time journal completion.
type TimeJournalStreak struct {
	CurrentStreakDays  int               `json:"currentStreakDays"`
	LongestStreakDays  int               `json:"longestStreakDays"`
	ThresholdPercent   int               `json:"thresholdPercent"`  // e.g. 80
	TotalJournalDays   int               `json:"totalJournalDays"`  // total days with any entries
	NextMilestone      *NextMilestone    `json:"nextMilestone,omitempty"`
	Links              map[string]string `json:"links,omitempty"`
}

// TimeJournalStatus represents the real-time status of today's journaling.
type TimeJournalStatus struct {
	Status           DayStatus         `json:"status"`
	FilledSlots      int               `json:"filledSlots"`
	TotalSlots       int               `json:"totalSlots"`
	OverdueSlots     int               `json:"overdueSlots"`
	CompletionPercent float64           `json:"completionPercent"`
	LastUpdatedAt    time.Time         `json:"lastUpdatedAt"`
	TriggerReason    string            `json:"triggerReason"`
	Links            map[string]string `json:"links,omitempty"`
}

// --- Request types ---

// CreateTimeJournalEntryRequest is the payload for creating a new time journal entry.
type CreateTimeJournalEntryRequest struct {
	Date        string                 `json:"date"`      // YYYY-MM-DD, required
	SlotStart   string                 `json:"slotStart"` // HH:MM:SS, required
	Mode        TimeJournalMode        `json:"mode"`      // T30 or T60, required
	Location    *string                `json:"location,omitempty"`
	GPSLatitude *float64               `json:"gpsLatitude,omitempty"`
	GPSLongitude *float64              `json:"gpsLongitude,omitempty"`
	GPSAddress  *string                `json:"gpsAddress,omitempty"`
	Activity    *string                `json:"activity,omitempty"`
	People      []PersonPresent        `json:"people,omitempty"`
	Emotions    []Emotion              `json:"emotions,omitempty"`
	Extras      map[string]interface{} `json:"extras,omitempty"`
	SleepFlag   bool                   `json:"sleepFlag"`
	RedlineNote *string                `json:"redlineNote,omitempty"`
}

// UpdateTimeJournalEntryRequest is the merge-patch payload for updating an entry.
// All fields are optional pointers to support partial updates.
type UpdateTimeJournalEntryRequest struct {
	Location    *string                `json:"location,omitempty"`
	GPSLatitude *float64               `json:"gpsLatitude,omitempty"`
	GPSLongitude *float64              `json:"gpsLongitude,omitempty"`
	GPSAddress  *string                `json:"gpsAddress,omitempty"`
	Activity    *string                `json:"activity,omitempty"`
	People      *[]PersonPresent       `json:"people,omitempty"`
	Emotions    *[]Emotion             `json:"emotions,omitempty"`
	Extras      map[string]interface{} `json:"extras,omitempty"`
	SleepFlag   *bool                  `json:"sleepFlag,omitempty"`
	RedlineNote *string                `json:"redlineNote,omitempty"`
}

// --- Response envelope types ---

// EntryResponse wraps a single TimeJournalEntry.
type EntryResponse struct {
	Data TimeJournalEntry       `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}

// EntriesResponse wraps a list of TimeJournalEntry items.
type EntriesResponse struct {
	Data  []TimeJournalEntry     `json:"data"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
	Links map[string]string      `json:"links,omitempty"`
}

// DayResponse wraps a single TimeJournalDay.
type DayResponse struct {
	Data TimeJournalDay         `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}

// DaysResponse wraps a list of TimeJournalDay items.
type DaysResponse struct {
	Data  []TimeJournalDay       `json:"data"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
	Links map[string]string      `json:"links,omitempty"`
}

// StreakResponse wraps TimeJournalStreak.
type StreakResponse struct {
	Data TimeJournalStreak      `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}

// StatusResponse wraps TimeJournalStatus.
type StatusResponse struct {
	Data TimeJournalStatus      `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}
