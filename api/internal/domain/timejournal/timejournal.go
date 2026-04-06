// Package timejournal implements the Time Journal (T-30/T-60) domain logic
// for structured accountability journaling in recovery.
//
// This file contains type definitions and function stubs. Implementations
// will be added during the GREEN phase of TDD.
package timejournal

import (
	"fmt"
	"time"
)

// TimeJournalMode represents the journaling interval (T-30 or T-60).
type TimeJournalMode string

const (
	ModeT30 TimeJournalMode = "t30"
	ModeT60 TimeJournalMode = "t60"
)

// DayStatus represents the current status of a day's journal.
type DayStatus string

const (
	StatusInProgress DayStatus = "inProgress"
	StatusOverdue    DayStatus = "overdue"
	StatusCompleted  DayStatus = "completed"
)

// Emotion represents an emotion entry with intensity rating.
type Emotion struct {
	Name      string `json:"name"`
	Intensity int    `json:"intensity"`
}

// TimeJournalEntry represents a single time slot entry.
type TimeJournalEntry struct {
	SlotIndex            int       `json:"slotIndex"`
	SlotStart            string    `json:"slotStart"`  // HH:MM:SS format
	SlotEnd              string    `json:"slotEnd"`     // HH:MM:SS format
	Activity             string    `json:"activity"`
	Location             string    `json:"location"`
	PeoplePresent        []string  `json:"peoplePresent"`
	Emotions             []Emotion `json:"emotions"`
	Retroactive          bool      `json:"retroactive"`
	RetroactiveTimestamp *time.Time `json:"retroactiveTimestamp,omitempty"`
	CreatedAt            time.Time `json:"createdAt"`
}

// TimeJournalDay represents a single day's journal with completion info.
type TimeJournalDay struct {
	Date             string  `json:"date"` // YYYY-MM-DD
	CompletionPct    float64 `json:"completionPct"`
}

// SlotEndFromStart calculates the slot end time given a start time and mode.
// For T-60, adds 60 minutes. For T-30, adds 30 minutes.
func SlotEndFromStart(slotStart string, mode TimeJournalMode) string {
	// TODO: implement in GREEN phase
	_ = slotStart
	_ = mode
	return ""
}

// EvaluateDayStatus determines the current status of a day's journal based on
// entries filled, mode, and current time.
func EvaluateDayStatus(entries []TimeJournalEntry, mode TimeJournalMode, now time.Time) DayStatus {
	// TODO: implement in GREEN phase
	_ = entries
	_ = mode
	_ = now
	return ""
}

// CalculateStreak computes the current and longest streak of consecutive days
// with >= 80% completion.
func CalculateStreak(days []TimeJournalDay) (currentStreak int, longestStreak int) {
	// TODO: implement in GREEN phase
	_ = days
	return 0, 0
}

// IsRetroactive determines whether a time slot entry is retroactive (entered
// after the slot's end time has passed).
func IsRetroactive(slotEnd string, date string, now time.Time) bool {
	// TODO: implement in GREEN phase
	_ = slotEnd
	_ = date
	_ = now
	return false
}

// ValidateEmotionIntensity checks that the intensity is within the valid range [1, 10].
func ValidateEmotionIntensity(intensity int) error {
	// TODO: implement in GREEN phase
	_ = intensity
	return fmt.Errorf("not implemented")
}

// IsEditWindowOpen checks whether an entry can still be edited (within 24-hour window).
func IsEditWindowOpen(createdAt time.Time, now time.Time) bool {
	// TODO: implement in GREEN phase
	_ = createdAt
	_ = now
	return false
}
