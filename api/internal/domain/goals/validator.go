// internal/domain/goals/validator.go
package goals

import (
	"errors"
	"fmt"
)

// Validation error codes per acceptance criteria.
const (
	ErrCodeTextInvalid     = "rr:0x00800001"
	ErrCodeDynamicsInvalid = "rr:0x00800002"
)

var (
	// ErrTextEmpty indicates empty goal text (AC-GC-2).
	ErrTextEmpty = errors.New("goal text is required and must be 1-200 characters")

	// ErrTextTooLong indicates goal text exceeds 200 characters (AC-GC-2).
	ErrTextTooLong = errors.New("goal text must not exceed 200 characters")

	// ErrDynamicsRequired indicates no dynamics provided (AC-GC-3).
	ErrDynamicsRequired = errors.New("at least one dynamic tag is required")

	// ErrNotesTooLong indicates notes exceed 500 characters (AC-GC-7).
	ErrNotesTooLong = errors.New("notes must not exceed 500 characters")

	// ErrReflectionTooLong indicates reflection exceeds 2000 characters.
	ErrReflectionTooLong = errors.New("reflection must not exceed 2000 characters")

	// ErrInvalidRecurrence indicates an invalid recurrence configuration.
	ErrInvalidRecurrence = errors.New("invalid recurrence configuration")

	// ErrInvalidDisposition indicates an invalid disposition action.
	ErrInvalidDisposition = errors.New("invalid disposition action")
)

// ValidationError wraps a validation error with an error code.
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

// ValidateCreateGoalRequest validates a create goal request (AC-GC-1 through AC-GC-8).
func ValidateCreateGoalRequest(req *CreateWeeklyDailyGoalRequest) error {
	// AC-GC-2: text validation
	if len(req.Text) == 0 {
		return &ValidationError{
			Code:    ErrCodeTextInvalid,
			Message: ErrTextEmpty.Error(),
			Err:     ErrTextEmpty,
		}
	}
	if len(req.Text) > 200 {
		return &ValidationError{
			Code:    ErrCodeTextInvalid,
			Message: ErrTextTooLong.Error(),
			Err:     ErrTextTooLong,
		}
	}

	// AC-GC-3: dynamics validation
	if len(req.Dynamics) == 0 {
		return &ValidationError{
			Code:    ErrCodeDynamicsInvalid,
			Message: ErrDynamicsRequired.Error(),
			Err:     ErrDynamicsRequired,
		}
	}
	for _, d := range req.Dynamics {
		if !IsValidDynamic(string(d)) {
			return &ValidationError{
				Code:    ErrCodeDynamicsInvalid,
				Message: fmt.Sprintf("invalid dynamic: %s", d),
				Err:     ErrDynamicsRequired,
			}
		}
	}

	// AC-GC-7: notes validation
	if req.Notes != nil && len(*req.Notes) > 500 {
		return &ValidationError{
			Code:    ErrCodeTextInvalid,
			Message: ErrNotesTooLong.Error(),
			Err:     ErrNotesTooLong,
		}
	}

	// AC-GC-5: recurrence validation
	if req.Recurrence != nil {
		if err := validateRecurrence(*req.Recurrence, req.DaysOfWeek, req.DayOfWeek); err != nil {
			return err
		}
	}

	return nil
}

// ValidateUpdateGoalRequest validates an update goal request.
func ValidateUpdateGoalRequest(req *UpdateWeeklyDailyGoalRequest) error {
	if req.Text != nil {
		if len(*req.Text) == 0 {
			return &ValidationError{
				Code:    ErrCodeTextInvalid,
				Message: ErrTextEmpty.Error(),
				Err:     ErrTextEmpty,
			}
		}
		if len(*req.Text) > 200 {
			return &ValidationError{
				Code:    ErrCodeTextInvalid,
				Message: ErrTextTooLong.Error(),
				Err:     ErrTextTooLong,
			}
		}
	}

	if len(req.Dynamics) > 0 {
		for _, d := range req.Dynamics {
			if !IsValidDynamic(string(d)) {
				return &ValidationError{
					Code:    ErrCodeDynamicsInvalid,
					Message: fmt.Sprintf("invalid dynamic: %s", d),
					Err:     ErrDynamicsRequired,
				}
			}
		}
	}

	if req.Notes != nil && len(*req.Notes) > 500 {
		return &ValidationError{
			Code:    ErrCodeTextInvalid,
			Message: ErrNotesTooLong.Error(),
			Err:     ErrNotesTooLong,
		}
	}

	if req.Recurrence != nil {
		if err := validateRecurrence(*req.Recurrence, req.DaysOfWeek, req.DayOfWeek); err != nil {
			return err
		}
	}

	return nil
}

// ValidateDailyReviewRequest validates a submit daily review request.
func ValidateDailyReviewRequest(req *SubmitDailyReviewRequest) error {
	if req.Date == "" {
		return &ValidationError{
			Code:    ErrCodeTextInvalid,
			Message: "date is required",
			Err:     ErrTextEmpty,
		}
	}

	for _, d := range req.Dispositions {
		if d.GoalInstanceID == "" {
			return &ValidationError{
				Code:    ErrCodeTextInvalid,
				Message: "goalInstanceId is required for each disposition",
				Err:     ErrInvalidDisposition,
			}
		}
		switch d.Action {
		case ActionCarryToTomorrow, ActionSkipped, ActionNoLongerRelevant:
			// valid
		default:
			return &ValidationError{
				Code:    ErrCodeTextInvalid,
				Message: fmt.Sprintf("invalid disposition action: %s", d.Action),
				Err:     ErrInvalidDisposition,
			}
		}
	}

	if req.Reflection != nil && len(*req.Reflection) > 2000 {
		return &ValidationError{
			Code:    ErrCodeTextInvalid,
			Message: ErrReflectionTooLong.Error(),
			Err:     ErrReflectionTooLong,
		}
	}

	return nil
}

// validateRecurrence checks recurrence-specific constraints.
func validateRecurrence(recurrence GoalRecurrence, daysOfWeek []DayOfWeek, dayOfWeek *DayOfWeek) error {
	switch recurrence {
	case RecurrenceOneTime, RecurrenceDaily:
		// no additional fields required
	case RecurrenceSpecificDays:
		if len(daysOfWeek) == 0 {
			return &ValidationError{
				Code:    ErrCodeTextInvalid,
				Message: "daysOfWeek is required when recurrence is specific-days",
				Err:     ErrInvalidRecurrence,
			}
		}
	case RecurrenceWeekly:
		if dayOfWeek == nil {
			return &ValidationError{
				Code:    ErrCodeTextInvalid,
				Message: "dayOfWeek is required when recurrence is weekly",
				Err:     ErrInvalidRecurrence,
			}
		}
	default:
		return &ValidationError{
			Code:    ErrCodeTextInvalid,
			Message: fmt.Sprintf("invalid recurrence: %s", recurrence),
			Err:     ErrInvalidRecurrence,
		}
	}
	return nil
}
