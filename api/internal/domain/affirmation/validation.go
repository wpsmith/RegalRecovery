// internal/domain/affirmation/validation.go
package affirmation

import (
	"fmt"
	"regexp"
	"strings"
)

const (
	MaxStatementLength     = 500
	MaxCustomAffirmations  = 50
)

var (
	systemIDPattern = regexp.MustCompile(`^aff_[a-zA-Z0-9]+$`)
	customIDPattern = regexp.MustCompile(`^caff_[a-zA-Z0-9]+$`)
	anyIDPattern    = regexp.MustCompile(`^(aff|caff)_[a-zA-Z0-9]+$`)
)

// ValidateAffirmation validates a system affirmation's required fields.
func ValidateAffirmation(a *Affirmation) error {
	if strings.TrimSpace(a.Statement) == "" {
		return fmt.Errorf("statement is required")
	}
	if len(a.Statement) > MaxStatementLength {
		return fmt.Errorf("statement exceeds %d character maximum", MaxStatementLength)
	}
	if strings.TrimSpace(a.ScriptureRef) == "" {
		return fmt.Errorf("scriptureReference is required")
	}
	if !IsValidCategory(string(a.Category)) {
		return fmt.Errorf("invalid category: %s", a.Category)
	}
	if a.Level < 1 || a.Level > 3 {
		return fmt.Errorf("level must be 1, 2, or 3")
	}
	return nil
}

// ValidateCreateCustomRequest validates a create custom affirmation request.
func ValidateCreateCustomRequest(req *CreateCustomAffirmationRequest) error {
	if strings.TrimSpace(req.Statement) == "" {
		return fmt.Errorf("statement is required")
	}
	if len(req.Statement) > MaxStatementLength {
		return fmt.Errorf("statement exceeds %d character maximum", MaxStatementLength)
	}
	if !IsCustomAllowedCategory(req.Category) {
		if req.Category == string(CategoryHealthySexuality) {
			return fmt.Errorf("healthySexuality category is not allowed for custom affirmations")
		}
		return fmt.Errorf("invalid category: %s", req.Category)
	}
	if err := validateSchedule(req.Schedule, req.CustomScheduleDays); err != nil {
		return err
	}
	return nil
}

// ValidateUpdateCustomRequest validates an update custom affirmation request.
func ValidateUpdateCustomRequest(req *UpdateCustomAffirmationRequest) error {
	if req.Statement != nil {
		if strings.TrimSpace(*req.Statement) == "" {
			return fmt.Errorf("statement cannot be empty")
		}
		if len(*req.Statement) > MaxStatementLength {
			return fmt.Errorf("statement exceeds %d character maximum", MaxStatementLength)
		}
	}
	if req.Category != nil {
		if !IsCustomAllowedCategory(*req.Category) {
			if *req.Category == string(CategoryHealthySexuality) {
				return fmt.Errorf("healthySexuality category is not allowed for custom affirmations")
			}
			return fmt.Errorf("invalid category: %s", *req.Category)
		}
	}
	if req.Schedule != nil {
		if err := validateSchedule(*req.Schedule, req.CustomScheduleDays); err != nil {
			return err
		}
	}
	return nil
}

// ValidateUpdateRotationRequest validates a rotation state update request.
func ValidateUpdateRotationRequest(req *UpdateRotationStateRequest) error {
	switch SelectionMode(req.SelectionMode) {
	case ModeIndividuallyChosen:
		if req.ChosenAffirmationID == nil || *req.ChosenAffirmationID == "" {
			return fmt.Errorf("chosenAffirmationId is required for individuallyChosen mode")
		}
	case ModeRandomAutomatic:
		// No additional fields required
	case ModePermanentPackage:
		if req.ActivePackID == nil || *req.ActivePackID == "" {
			return fmt.Errorf("activePackId is required for permanentPackage mode")
		}
	case ModeDayOfWeekPackage:
		if req.DayOfWeekAssignments == nil || len(req.DayOfWeekAssignments) == 0 {
			return fmt.Errorf("dayOfWeekAssignments is required for dayOfWeekPackage mode")
		}
		validDays := map[string]bool{
			"monday": true, "tuesday": true, "wednesday": true,
			"thursday": true, "friday": true, "saturday": true, "sunday": true,
		}
		for day := range req.DayOfWeekAssignments {
			if !validDays[day] {
				return fmt.Errorf("invalid day of week: %s", day)
			}
		}
	default:
		return fmt.Errorf("invalid selection mode: %s", req.SelectionMode)
	}
	return nil
}

// ValidateSystemID validates a system affirmation ID format.
func ValidateSystemID(id string) bool {
	return systemIDPattern.MatchString(id)
}

// ValidateCustomID validates a custom affirmation ID format.
func ValidateCustomID(id string) bool {
	return customIDPattern.MatchString(id)
}

// ValidateAnyID validates either system or custom affirmation ID format.
func ValidateAnyID(id string) bool {
	return anyIDPattern.MatchString(id)
}

func validateSchedule(schedule string, customDays []string) error {
	switch Schedule(schedule) {
	case ScheduleDaily, ScheduleWeekdays, ScheduleWeekends:
		return nil
	case ScheduleCustom:
		if len(customDays) == 0 {
			return fmt.Errorf("customScheduleDays is required when schedule is 'custom'")
		}
		validDays := map[string]bool{
			"monday": true, "tuesday": true, "wednesday": true,
			"thursday": true, "friday": true, "saturday": true, "sunday": true,
		}
		for _, day := range customDays {
			if !validDays[day] {
				return fmt.Errorf("invalid day: %s", day)
			}
		}
		return nil
	default:
		return fmt.Errorf("invalid schedule: %s", schedule)
	}
}
