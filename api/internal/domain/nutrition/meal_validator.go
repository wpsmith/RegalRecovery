// internal/domain/nutrition/meal_validator.go
package nutrition

import (
	"errors"
	"fmt"
)

// Validation error codes per Siemens error format.
const (
	ErrCodeMealTypeRequired    = "rr:0x00040001"
	ErrCodeTimestampImmutable  = "rr:0x00040002"
	ErrCodeInvalidMealType     = "rr:0x00040003"
	ErrCodeDescriptionRequired = "rr:0x00040004"
	ErrCodeDescriptionTooLong  = "rr:0x00040005"
	ErrCodeNotesTooLong        = "rr:0x00040006"
	ErrCodeInvalidMoodRange    = "rr:0x00040007"
	ErrCodeInvalidContext      = "rr:0x00040008"
	ErrCodeInvalidMindfulness  = "rr:0x00040009"
	ErrCodeCustomLabelRequired = "rr:0x0004000A"
	ErrCodeCustomLabelTooLong  = "rr:0x0004000B"
	ErrCodeInvalidHydration    = "rr:0x0004000C"
)

// Domain errors.
var (
	ErrMealTypeRequired       = errors.New("mealType is required")
	ErrTimestampImmutable     = errors.New("timestamp is immutable")
	ErrInvalidMealType        = errors.New("invalid mealType")
	ErrDescriptionRequired    = errors.New("description is required")
	ErrDescriptionTooLong     = errors.New("description exceeds 300 character limit")
	ErrNotesTooLong           = errors.New("notes exceeds 500 character limit")
	ErrInvalidMoodRange       = errors.New("mood must be between 1 and 5")
	ErrInvalidEatingContext   = errors.New("invalid eatingContext")
	ErrInvalidMindfulness     = errors.New("invalid mindfulnessCheck")
	ErrCustomLabelRequired    = errors.New("customMealLabel required when mealType is other")
	ErrCustomLabelTooLong     = errors.New("customMealLabel exceeds 50 character limit")
	ErrMealNotFound           = errors.New("meal log not found")
	ErrSettingsNotFound       = errors.New("nutrition settings not found")
	ErrInvalidHydrationAction = errors.New("invalid hydration action")
)

const (
	maxDescriptionLength  = 300
	maxNotesLength        = 500
	maxCustomLabelLength  = 50
	minMoodValue          = 1
	maxMoodValue          = 5
)

// ValidationError wraps a domain error with an error code for API responses.
type ValidationError struct {
	Code    string
	Message string
	Err     error
}

func (e *ValidationError) Error() string {
	return e.Message
}

func (e *ValidationError) Unwrap() error {
	return e.Err
}

// ValidateCreateMealLog validates a meal log creation request.
func ValidateCreateMealLog(req *CreateMealLogRequest) error {
	// FR-NUT-1.1: mealType is required.
	if req.MealType == "" {
		return &ValidationError{
			Code:    ErrCodeMealTypeRequired,
			Message: ErrMealTypeRequired.Error(),
			Err:     ErrMealTypeRequired,
		}
	}

	// FR-NUT-1.2: mealType must be valid.
	if !ValidMealTypes[req.MealType] {
		return &ValidationError{
			Code:    ErrCodeInvalidMealType,
			Message: fmt.Sprintf("mealType '%s' is not valid", req.MealType),
			Err:     ErrInvalidMealType,
		}
	}

	// FR-NUT-1.2: when mealType is "other", customMealLabel is required.
	if req.MealType == MealTypeOther {
		if req.CustomMealLabel == nil || *req.CustomMealLabel == "" {
			return &ValidationError{
				Code:    ErrCodeCustomLabelRequired,
				Message: ErrCustomLabelRequired.Error(),
				Err:     ErrCustomLabelRequired,
			}
		}
		if len(*req.CustomMealLabel) > maxCustomLabelLength {
			return &ValidationError{
				Code:    ErrCodeCustomLabelTooLong,
				Message: ErrCustomLabelTooLong.Error(),
				Err:     ErrCustomLabelTooLong,
			}
		}
	}

	// FR-NUT-1.3: description is required.
	if req.Description == "" {
		return &ValidationError{
			Code:    ErrCodeDescriptionRequired,
			Message: ErrDescriptionRequired.Error(),
			Err:     ErrDescriptionRequired,
		}
	}

	// FR-NUT-1.4: description length limit.
	if len(req.Description) > maxDescriptionLength {
		return &ValidationError{
			Code:    ErrCodeDescriptionTooLong,
			Message: ErrDescriptionTooLong.Error(),
			Err:     ErrDescriptionTooLong,
		}
	}

	// FR-NUT-1.7: eating context must be valid if provided.
	if req.EatingContext != nil {
		if !ValidEatingContexts[*req.EatingContext] {
			return &ValidationError{
				Code:    ErrCodeInvalidContext,
				Message: fmt.Sprintf("eatingContext '%s' is not valid", *req.EatingContext),
				Err:     ErrInvalidEatingContext,
			}
		}
	}

	// FR-NUT-1.8: moodBefore range.
	if req.MoodBefore != nil {
		if *req.MoodBefore < minMoodValue || *req.MoodBefore > maxMoodValue {
			return &ValidationError{
				Code:    ErrCodeInvalidMoodRange,
				Message: "moodBefore must be between 1 and 5",
				Err:     ErrInvalidMoodRange,
			}
		}
	}

	// FR-NUT-1.9: moodAfter range.
	if req.MoodAfter != nil {
		if *req.MoodAfter < minMoodValue || *req.MoodAfter > maxMoodValue {
			return &ValidationError{
				Code:    ErrCodeInvalidMoodRange,
				Message: "moodAfter must be between 1 and 5",
				Err:     ErrInvalidMoodRange,
			}
		}
	}

	// FR-NUT-1.10: mindfulness check must be valid if provided.
	if req.MindfulnessCheck != nil {
		if !ValidMindfulnessChecks[*req.MindfulnessCheck] {
			return &ValidationError{
				Code:    ErrCodeInvalidMindfulness,
				Message: fmt.Sprintf("mindfulnessCheck '%s' is not valid", *req.MindfulnessCheck),
				Err:     ErrInvalidMindfulness,
			}
		}
	}

	// FR-NUT-1.11: notes length limit.
	if req.Notes != nil && len(*req.Notes) > maxNotesLength {
		return &ValidationError{
			Code:    ErrCodeNotesTooLong,
			Message: ErrNotesTooLong.Error(),
			Err:     ErrNotesTooLong,
		}
	}

	return nil
}

// ValidateUpdateMealLog validates a meal log update request.
// FR-NUT-1.14: timestamp is immutable.
func ValidateUpdateMealLog(req *UpdateMealLogRequest) error {
	if req.Timestamp != nil {
		return &ValidationError{
			Code:    ErrCodeTimestampImmutable,
			Message: ErrTimestampImmutable.Error(),
			Err:     ErrTimestampImmutable,
		}
	}

	if req.Description != nil && len(*req.Description) > maxDescriptionLength {
		return &ValidationError{
			Code:    ErrCodeDescriptionTooLong,
			Message: ErrDescriptionTooLong.Error(),
			Err:     ErrDescriptionTooLong,
		}
	}

	if req.EatingContext != nil {
		if !ValidEatingContexts[*req.EatingContext] {
			return &ValidationError{
				Code:    ErrCodeInvalidContext,
				Message: fmt.Sprintf("eatingContext '%s' is not valid", *req.EatingContext),
				Err:     ErrInvalidEatingContext,
			}
		}
	}

	if req.MoodBefore != nil {
		if *req.MoodBefore < minMoodValue || *req.MoodBefore > maxMoodValue {
			return &ValidationError{
				Code:    ErrCodeInvalidMoodRange,
				Message: "moodBefore must be between 1 and 5",
				Err:     ErrInvalidMoodRange,
			}
		}
	}

	if req.MoodAfter != nil {
		if *req.MoodAfter < minMoodValue || *req.MoodAfter > maxMoodValue {
			return &ValidationError{
				Code:    ErrCodeInvalidMoodRange,
				Message: "moodAfter must be between 1 and 5",
				Err:     ErrInvalidMoodRange,
			}
		}
	}

	if req.MindfulnessCheck != nil {
		if !ValidMindfulnessChecks[*req.MindfulnessCheck] {
			return &ValidationError{
				Code:    ErrCodeInvalidMindfulness,
				Message: fmt.Sprintf("mindfulnessCheck '%s' is not valid", *req.MindfulnessCheck),
				Err:     ErrInvalidMindfulness,
			}
		}
	}

	if req.Notes != nil && len(*req.Notes) > maxNotesLength {
		return &ValidationError{
			Code:    ErrCodeNotesTooLong,
			Message: ErrNotesTooLong.Error(),
			Err:     ErrNotesTooLong,
		}
	}

	return nil
}

// ValidateQuickMealLog validates a quick meal log creation request.
func ValidateQuickMealLog(req *CreateQuickMealLogRequest) error {
	if req.MealType == "" {
		return &ValidationError{
			Code:    ErrCodeMealTypeRequired,
			Message: ErrMealTypeRequired.Error(),
			Err:     ErrMealTypeRequired,
		}
	}

	if !ValidMealTypes[req.MealType] {
		return &ValidationError{
			Code:    ErrCodeInvalidMealType,
			Message: fmt.Sprintf("mealType '%s' is not valid", req.MealType),
			Err:     ErrInvalidMealType,
		}
	}

	if req.MealType == MealTypeOther {
		if req.CustomMealLabel == nil || *req.CustomMealLabel == "" {
			return &ValidationError{
				Code:    ErrCodeCustomLabelRequired,
				Message: ErrCustomLabelRequired.Error(),
				Err:     ErrCustomLabelRequired,
			}
		}
		if len(*req.CustomMealLabel) > maxCustomLabelLength {
			return &ValidationError{
				Code:    ErrCodeCustomLabelTooLong,
				Message: ErrCustomLabelTooLong.Error(),
				Err:     ErrCustomLabelTooLong,
			}
		}
	}

	return nil
}

// ValidateHydrationLog validates a hydration log request.
func ValidateHydrationLog(req *LogHydrationRequest) error {
	if req.Action != HydrationActionAdd && req.Action != HydrationActionRemove {
		return &ValidationError{
			Code:    ErrCodeInvalidHydration,
			Message: "action must be 'add' or 'remove'",
			Err:     ErrInvalidHydrationAction,
		}
	}

	if req.Servings < 1 || req.Servings > 10 {
		return &ValidationError{
			Code:    ErrCodeInvalidHydration,
			Message: "servings must be between 1 and 10",
			Err:     ErrInvalidHydrationAction,
		}
	}

	return nil
}
