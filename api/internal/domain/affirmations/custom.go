// internal/domain/affirmations/custom.go
package affirmations

import (
	"errors"
	"regexp"
	"strings"
	"time"
)

// Sentinel errors for custom affirmations.
var (
	ErrInsufficientSobrietyDays = errors.New("custom affirmations require 14 days of sobriety")
	ErrStatementTooLong         = errors.New("statement exceeds 500 characters")
	ErrStatementEmpty           = errors.New("statement cannot be empty")
	ErrFutureTense              = errors.New("statement must be in present tense, not future")
	ErrNegativeFraming          = errors.New("statement must use positive framing")
	ErrNotWithinEditWindow      = errors.New("affirmation is read-only after 24 hours")
)

const (
	// MinSobrietyDaysForCustom is the minimum sobriety days required for custom affirmations.
	MinSobrietyDaysForCustom = 14
	// MaxStatementLength is the maximum character count for custom affirmations.
	MaxStatementLength = 500
	// EditWindowHours is the number of hours after creation that editing is allowed.
	EditWindowHours = 24
)

// CustomAffirmation represents a user-created affirmation.
type CustomAffirmation struct {
	ID                string    `json:"id"`
	UserID            string    `json:"userId"`
	Statement         string    `json:"statement"`
	CreatedAt         time.Time `json:"createdAt"`
	ModifiedAt        time.Time `json:"modifiedAt"`
	IncludeInRotation bool      `json:"includeInRotation"`
	IsActive          bool      `json:"isActive"`
}

// ValidationResult holds the result of statement validation.
type ValidationResult struct {
	Valid  bool     `json:"valid"`
	Errors []string `json:"errors,omitempty"`
}

// Regular expressions for validation.
var (
	// Future tense patterns.
	futureTenseRegex = regexp.MustCompile(`(?i)\b(I\s+will|I'm\s+going\s+to|I'll|I\s+shall)\b`)

	// Negative framing patterns (excluding acceptable "free from").
	negativeFramingRegex = regexp.MustCompile(`(?i)\b(I\s+am\s+not|I\s+don't|I\s+won't|I\s+can't|I\s+never)\b`)

	// Acceptable negation pattern.
	acceptableNegationRegex = regexp.MustCompile(`(?i)\b(free\s+from)\b`)
)

// ValidateCustomAffirmationEligibility checks if the user has sufficient sobriety days.
func ValidateCustomAffirmationEligibility(sobrietyDays int) error {
	if sobrietyDays < MinSobrietyDaysForCustom {
		return ErrInsufficientSobrietyDays
	}
	return nil
}

// ValidateCustomStatement validates a custom affirmation statement.
// It checks sobriety eligibility, length, tense, and framing.
func ValidateCustomStatement(statement string, sobrietyDays int) *ValidationResult {
	result := &ValidationResult{
		Valid:  true,
		Errors: []string{},
	}

	// Check sobriety eligibility.
	if err := ValidateCustomAffirmationEligibility(sobrietyDays); err != nil {
		result.Valid = false
		result.Errors = append(result.Errors, err.Error())
	}

	// Trim and check for empty statement.
	trimmed := strings.TrimSpace(statement)
	if trimmed == "" {
		result.Valid = false
		result.Errors = append(result.Errors, ErrStatementEmpty.Error())
		return result
	}

	// Check length.
	if len(statement) > MaxStatementLength {
		result.Valid = false
		result.Errors = append(result.Errors, ErrStatementTooLong.Error())
	}

	// Check for future tense.
	if futureTenseRegex.MatchString(statement) {
		result.Valid = false
		result.Errors = append(result.Errors, ErrFutureTense.Error())
	}

	// Check for negative framing, excluding acceptable "free from" pattern.
	if negativeFramingRegex.MatchString(statement) {
		// Allow if it contains "free from" pattern.
		if !acceptableNegationRegex.MatchString(statement) {
			result.Valid = false
			result.Errors = append(result.Errors, ErrNegativeFraming.Error())
		}
	}

	return result
}

// IsWithinEditWindow checks if an affirmation is still within the 24-hour edit window.
func IsWithinEditWindow(createdAt time.Time) bool {
	now := time.Now().UTC()
	editDeadline := createdAt.Add(EditWindowHours * time.Hour)
	return now.Before(editDeadline)
}

// CanEdit checks if a custom affirmation can be edited based on its creation time.
func (c *CustomAffirmation) CanEdit() bool {
	return IsWithinEditWindow(c.CreatedAt)
}

// Update updates the affirmation statement if within the edit window.
func (c *CustomAffirmation) Update(newStatement string, sobrietyDays int) error {
	if !c.CanEdit() {
		return ErrNotWithinEditWindow
	}

	// Validate the new statement.
	result := ValidateCustomStatement(newStatement, sobrietyDays)
	if !result.Valid {
		return errors.New(strings.Join(result.Errors, "; "))
	}

	c.Statement = newStatement
	c.ModifiedAt = time.Now().UTC()
	return nil
}
