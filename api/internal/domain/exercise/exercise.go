// internal/domain/exercise/exercise.go
package exercise

import (
	"errors"
	"fmt"
	"time"
)

var (
	// ErrInvalidInput indicates invalid input data.
	ErrInvalidInput = errors.New("invalid input data")

	// ErrInvalidActivityType indicates an invalid activity type.
	ErrInvalidActivityType = errors.New("invalid activity type")

	// ErrInvalidIntensity indicates an invalid intensity level.
	ErrInvalidIntensity = errors.New("invalid intensity level")

	// ErrInvalidSource indicates an invalid data source.
	ErrInvalidSource = errors.New("invalid data source")

	// ErrInvalidDuration indicates the duration is out of range.
	ErrInvalidDuration = errors.New("duration must be between 1 and 1440 minutes")

	// ErrInvalidMood indicates the mood value is out of range.
	ErrInvalidMood = errors.New("mood must be between 1 and 5")

	// ErrNotesTooLong indicates notes exceed the character limit.
	ErrNotesTooLong = errors.New("notes must be 500 characters or fewer")

	// ErrTimestampTooFarFuture indicates the timestamp is too far in the future.
	ErrTimestampTooFarFuture = errors.New("timestamp cannot be more than 24 hours in the future")

	// ErrCustomLabelRequired indicates a custom label is required for activity type "other".
	ErrCustomLabelRequired = errors.New("custom type label is required when activity type is other")

	// ErrCustomLabelTooLong indicates the custom label exceeds the character limit.
	ErrCustomLabelTooLong = errors.New("custom type label must be 50 characters or fewer")

	// ErrImmutableField indicates an attempt to modify an immutable field.
	ErrImmutableField = errors.New("field is immutable after creation")

	// ErrExerciseNotFound indicates the exercise log was not found.
	ErrExerciseNotFound = errors.New("exercise log not found")

	// ErrFavoriteNotFound indicates the favorite was not found.
	ErrFavoriteNotFound = errors.New("exercise favorite not found")

	// ErrGoalNotFound indicates no weekly goal is configured.
	ErrGoalNotFound = errors.New("no weekly goal configured")

	// ErrMaxFavoritesReached indicates the user has reached the maximum favorites.
	ErrMaxFavoritesReached = errors.New("maximum of 5 favorites reached")

	// ErrGoalEmpty indicates at least one goal target is required.
	ErrGoalEmpty = errors.New("at least one of target active minutes or target sessions is required")

	// ErrDuplicateDetected indicates a potential duplicate exercise log.
	ErrDuplicateDetected = errors.New("potential duplicate exercise log detected")
)

// MaxFavorites is the maximum number of favorites per user.
const MaxFavorites = 5

// MaxNotesLength is the maximum character count for notes.
const MaxNotesLength = 500

// MaxCustomLabelLength is the maximum character count for custom type labels.
const MaxCustomLabelLength = 50

// MaxDuration is the maximum duration in minutes.
const MaxDuration = 1440

// FutureTimestampLimit is the maximum allowed future offset for timestamps.
const FutureTimestampLimit = 24 * time.Hour

// ValidateCreateRequest validates a CreateExerciseLogRequest.
func ValidateCreateRequest(req CreateExerciseLogRequest, now time.Time) error {
	// Activity type validation
	if !ValidActivityTypes[req.ActivityType] {
		return fmt.Errorf("%w: %s", ErrInvalidActivityType, req.ActivityType)
	}

	// Custom label required for "other"
	if req.ActivityType == ActivityTypeOther {
		if req.CustomTypeLabel == nil || *req.CustomTypeLabel == "" {
			return ErrCustomLabelRequired
		}
	}

	// Custom label length
	if req.CustomTypeLabel != nil && len(*req.CustomTypeLabel) > MaxCustomLabelLength {
		return ErrCustomLabelTooLong
	}

	// Duration validation
	if req.DurationMinutes < 1 || req.DurationMinutes > MaxDuration {
		return ErrInvalidDuration
	}

	// Intensity validation (optional)
	if req.Intensity != nil {
		if !ValidIntensityLevels[*req.Intensity] {
			return fmt.Errorf("%w: %s", ErrInvalidIntensity, *req.Intensity)
		}
	}

	// Source validation
	if req.Source == "" {
		req.Source = SourceManual
	}
	if !ValidSources[req.Source] {
		return fmt.Errorf("%w: %s", ErrInvalidSource, req.Source)
	}

	// Notes length
	if req.Notes != nil && len(*req.Notes) > MaxNotesLength {
		return ErrNotesTooLong
	}

	// Mood before validation (optional)
	if req.MoodBefore != nil {
		if *req.MoodBefore < 1 || *req.MoodBefore > 5 {
			return fmt.Errorf("mood before: %w", ErrInvalidMood)
		}
	}

	// Mood after validation (optional)
	if req.MoodAfter != nil {
		if *req.MoodAfter < 1 || *req.MoodAfter > 5 {
			return fmt.Errorf("mood after: %w", ErrInvalidMood)
		}
	}

	// Timestamp validation: no future > 24h
	if req.Timestamp.After(now.Add(FutureTimestampLimit)) {
		return ErrTimestampTooFarFuture
	}

	return nil
}

// ValidateUpdateRequest validates an UpdateExerciseLogRequest and returns
// only the mutable fields that should be updated.
func ValidateUpdateRequest(req UpdateExerciseLogRequest) (map[string]interface{}, error) {
	updates := make(map[string]interface{})

	if req.Intensity != nil {
		if !ValidIntensityLevels[*req.Intensity] {
			return nil, fmt.Errorf("%w: %s", ErrInvalidIntensity, *req.Intensity)
		}
		updates["intensity"] = *req.Intensity
	}

	if req.Notes != nil {
		if len(*req.Notes) > MaxNotesLength {
			return nil, ErrNotesTooLong
		}
		updates["notes"] = *req.Notes
	}

	if req.MoodBefore != nil {
		if *req.MoodBefore < 1 || *req.MoodBefore > 5 {
			return nil, fmt.Errorf("mood before: %w", ErrInvalidMood)
		}
		updates["moodBefore"] = *req.MoodBefore
	}

	if req.MoodAfter != nil {
		if *req.MoodAfter < 1 || *req.MoodAfter > 5 {
			return nil, fmt.Errorf("mood after: %w", ErrInvalidMood)
		}
		updates["moodAfter"] = *req.MoodAfter
	}

	if req.CustomTypeLabel != nil {
		if len(*req.CustomTypeLabel) > MaxCustomLabelLength {
			return nil, ErrCustomLabelTooLong
		}
		updates["customTypeLabel"] = *req.CustomTypeLabel
	}

	return updates, nil
}

// CheckImmutableFieldViolation checks whether a raw update map attempts to
// modify immutable fields (timestamp, createdAt, activityType, durationMinutes, source).
func CheckImmutableFieldViolation(rawUpdates map[string]interface{}) error {
	for _, field := range ImmutableFields {
		if _, exists := rawUpdates[field]; exists {
			return fmt.Errorf("%s: %w", field, ErrImmutableField)
		}
	}
	return nil
}
