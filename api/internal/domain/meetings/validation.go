// internal/domain/meetings/validation.go
package meetings

import (
	"errors"
	"fmt"
	"regexp"
)

var (
	// ErrMeetingNotFound indicates a meeting log does not exist.
	ErrMeetingNotFound = errors.New("meeting not found")

	// ErrSavedMeetingNotFound indicates a saved meeting template does not exist.
	ErrSavedMeetingNotFound = errors.New("saved meeting not found")

	// ErrInvalidInput indicates invalid input data.
	ErrInvalidInput = errors.New("invalid input data")

	// ErrTimestampImmutable indicates an attempt to modify an immutable timestamp.
	ErrTimestampImmutable = errors.New("timestamp is immutable")

	// ErrInvalidMeetingType indicates an invalid meeting type (SAA explicitly excluded).
	ErrInvalidMeetingType = errors.New("invalid meeting type")

	// ErrCustomTypeLabelRequired indicates customTypeLabel is required when meetingType is "custom".
	ErrCustomTypeLabelRequired = errors.New("customTypeLabel is required when meetingType is 'custom'")

	// ErrInvalidReminderMinutes indicates an invalid reminder duration.
	ErrInvalidReminderMinutes = errors.New("reminderMinutesBefore must be 15, 30, or 60")

	// ErrPermissionDenied indicates the caller lacks permission to view the resource.
	ErrPermissionDenied = errors.New("permission denied")

	// ErrFeatureDisabled indicates the feature flag is disabled.
	ErrFeatureDisabled = errors.New("feature disabled")
)

// validReminderMinutes contains allowed reminder durations.
var validReminderMinutes = map[int]bool{15: true, 30: true, 60: true}

// timeRegex validates HH:mm format.
var timeRegex = regexp.MustCompile(`^\d{2}:\d{2}$`)

// ValidateCreateMeetingLogRequest validates a create meeting log request.
func ValidateCreateMeetingLogRequest(req *CreateMeetingLogRequest) error {
	if req.Timestamp.IsZero() {
		return fmt.Errorf("timestamp is required: %w", ErrInvalidInput)
	}

	if err := validateMeetingType(req.MeetingType, req.CustomTypeLabel); err != nil {
		return err
	}

	if req.Name != nil && len(*req.Name) > 200 {
		return fmt.Errorf("name must not exceed 200 characters: %w", ErrInvalidInput)
	}

	if req.Location != nil && len(*req.Location) > 300 {
		return fmt.Errorf("location must not exceed 300 characters: %w", ErrInvalidInput)
	}

	if req.DurationMinutes != nil && *req.DurationMinutes < 0 {
		return fmt.Errorf("durationMinutes must be >= 0: %w", ErrInvalidInput)
	}

	if req.Notes != nil && len(*req.Notes) > 2000 {
		return fmt.Errorf("notes must not exceed 2000 characters: %w", ErrInvalidInput)
	}

	if req.CustomTypeLabel != nil && len(*req.CustomTypeLabel) > 100 {
		return fmt.Errorf("customTypeLabel must not exceed 100 characters: %w", ErrInvalidInput)
	}

	return nil
}

// ValidateUpdateMeetingLogRequest validates an update meeting log request.
func ValidateUpdateMeetingLogRequest(req *UpdateMeetingLogRequest) error {
	if req.MeetingType != nil {
		label := req.CustomTypeLabel
		if err := validateMeetingType(*req.MeetingType, label); err != nil {
			return err
		}
	}

	if req.Name != nil && len(*req.Name) > 200 {
		return fmt.Errorf("name must not exceed 200 characters: %w", ErrInvalidInput)
	}

	if req.Location != nil && len(*req.Location) > 300 {
		return fmt.Errorf("location must not exceed 300 characters: %w", ErrInvalidInput)
	}

	if req.DurationMinutes != nil && *req.DurationMinutes < 0 {
		return fmt.Errorf("durationMinutes must be >= 0: %w", ErrInvalidInput)
	}

	if req.Notes != nil && len(*req.Notes) > 2000 {
		return fmt.Errorf("notes must not exceed 2000 characters: %w", ErrInvalidInput)
	}

	if req.CustomTypeLabel != nil && len(*req.CustomTypeLabel) > 100 {
		return fmt.Errorf("customTypeLabel must not exceed 100 characters: %w", ErrInvalidInput)
	}

	if req.Status != nil && !IsValidMeetingStatus(*req.Status) {
		return fmt.Errorf("invalid meeting status: %w", ErrInvalidInput)
	}

	return nil
}

// ValidateCreateSavedMeetingRequest validates a create saved meeting request.
func ValidateCreateSavedMeetingRequest(req *CreateSavedMeetingRequest) error {
	if req.Name == "" {
		return fmt.Errorf("name is required: %w", ErrInvalidInput)
	}

	if len(req.Name) > 200 {
		return fmt.Errorf("name must not exceed 200 characters: %w", ErrInvalidInput)
	}

	if err := validateMeetingType(req.MeetingType, req.CustomTypeLabel); err != nil {
		return err
	}

	if req.Location != nil && len(*req.Location) > 300 {
		return fmt.Errorf("location must not exceed 300 characters: %w", ErrInvalidInput)
	}

	if req.Schedule != nil {
		if err := validateSchedule(req.Schedule); err != nil {
			return err
		}
	}

	if req.ReminderMinutesBefore != nil {
		if !validReminderMinutes[*req.ReminderMinutesBefore] {
			return ErrInvalidReminderMinutes
		}
	}

	if req.CustomTypeLabel != nil && len(*req.CustomTypeLabel) > 100 {
		return fmt.Errorf("customTypeLabel must not exceed 100 characters: %w", ErrInvalidInput)
	}

	return nil
}

// ValidateUpdateSavedMeetingRequest validates an update saved meeting request.
func ValidateUpdateSavedMeetingRequest(req *UpdateSavedMeetingRequest) error {
	if req.Name != nil && *req.Name == "" {
		return fmt.Errorf("name must not be empty: %w", ErrInvalidInput)
	}

	if req.Name != nil && len(*req.Name) > 200 {
		return fmt.Errorf("name must not exceed 200 characters: %w", ErrInvalidInput)
	}

	if req.MeetingType != nil {
		label := req.CustomTypeLabel
		if err := validateMeetingType(*req.MeetingType, label); err != nil {
			return err
		}
	}

	if req.Location != nil && len(*req.Location) > 300 {
		return fmt.Errorf("location must not exceed 300 characters: %w", ErrInvalidInput)
	}

	if req.Schedule != nil {
		if err := validateSchedule(req.Schedule); err != nil {
			return err
		}
	}

	if req.ReminderMinutesBefore != nil {
		if !validReminderMinutes[*req.ReminderMinutesBefore] {
			return ErrInvalidReminderMinutes
		}
	}

	if req.CustomTypeLabel != nil && len(*req.CustomTypeLabel) > 100 {
		return fmt.Errorf("customTypeLabel must not exceed 100 characters: %w", ErrInvalidInput)
	}

	return nil
}

// validateMeetingType validates a meeting type and its associated custom label.
func validateMeetingType(mt MeetingType, customLabel *string) error {
	if !IsValidMeetingType(mt) {
		return fmt.Errorf("meeting type '%s' is not valid: %w", mt, ErrInvalidMeetingType)
	}

	if mt == MeetingTypeCustom {
		if customLabel == nil || *customLabel == "" {
			return ErrCustomTypeLabelRequired
		}
	}

	return nil
}

// validateSchedule validates a meeting schedule.
func validateSchedule(schedule *MeetingSchedule) error {
	if !validDays[schedule.DayOfWeek] {
		return fmt.Errorf("invalid dayOfWeek: %w", ErrInvalidInput)
	}

	if !timeRegex.MatchString(schedule.Time) {
		return fmt.Errorf("time must be in HH:mm format: %w", ErrInvalidInput)
	}

	if schedule.TimeZone == "" {
		return fmt.Errorf("timeZone is required when schedule is provided: %w", ErrInvalidInput)
	}

	return nil
}
