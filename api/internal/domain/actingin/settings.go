// internal/domain/actingin/settings.go
package actingin

import (
	"errors"
	"regexp"
	"time"
)

var (
	// ErrInvalidFrequency indicates the frequency value is not valid.
	ErrInvalidFrequency = errors.New("frequency must be 'daily' or 'weekly'")

	// ErrInvalidReminderTime indicates the reminder time format is invalid.
	ErrInvalidReminderTime = errors.New("reminder time must be in HH:mm format (e.g., '21:00')")

	// ErrInvalidReminderDay indicates the reminder day is not a valid weekday.
	ErrInvalidReminderDay = errors.New("reminder day must be a valid weekday (e.g., 'sunday')")
)

// reminderTimePattern validates HH:mm format.
var reminderTimePattern = regexp.MustCompile(`^([01]\d|2[0-3]):[0-5]\d$`)

// DefaultSettings returns the default settings for a new user.
func DefaultSettings(userID string) *Settings {
	now := time.Now().UTC()
	return &Settings{
		UserID:            userID,
		Frequency:         FrequencyDaily,
		ReminderTime:      "21:00",
		ReminderDay:       WeekdaySunday,
		FirstUseCompleted: false,
		StreakCount:        0,
		LastCheckInAt:     nil,
		CreatedAt:         now,
		ModifiedAt:        now,
	}
}

// ValidateSettings validates the settings values.
func ValidateSettings(settings *Settings) error {
	if !ValidFrequencies[settings.Frequency] {
		return ErrInvalidFrequency
	}
	if !reminderTimePattern.MatchString(settings.ReminderTime) {
		return ErrInvalidReminderTime
	}
	if !ValidWeekdays[settings.ReminderDay] {
		return ErrInvalidReminderDay
	}
	return nil
}

// ApplySettingsUpdate merges an update request into existing settings.
// Returns true if the frequency changed (streak recalculation needed).
func ApplySettingsUpdate(settings *Settings, req *UpdateSettingsRequest) (frequencyChanged bool, err error) {
	if req.Frequency != nil {
		if !ValidFrequencies[*req.Frequency] {
			return false, ErrInvalidFrequency
		}
		if *req.Frequency != settings.Frequency {
			frequencyChanged = true
			settings.Frequency = *req.Frequency
		}
	}
	if req.ReminderTime != nil {
		if !reminderTimePattern.MatchString(*req.ReminderTime) {
			return false, ErrInvalidReminderTime
		}
		settings.ReminderTime = *req.ReminderTime
	}
	if req.ReminderDay != nil {
		if !ValidWeekdays[*req.ReminderDay] {
			return false, ErrInvalidReminderDay
		}
		settings.ReminderDay = *req.ReminderDay
	}
	settings.ModifiedAt = time.Now().UTC()
	return frequencyChanged, nil
}
