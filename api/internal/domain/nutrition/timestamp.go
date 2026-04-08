// internal/domain/nutrition/timestamp.go
package nutrition

import "time"

// IsTimestampImmutable checks whether a meal log's timestamp should be considered immutable.
// Per FR2.7, timestamps on recovery data are immutable once recorded.
func IsTimestampImmutable(meal *MealLog) bool {
	return !meal.CreatedAt.IsZero()
}

// EnforceTimestampImmutability returns an error if the update attempts to change the timestamp.
func EnforceTimestampImmutability(existing *MealLog, update *UpdateMealLogRequest) error {
	if update.Timestamp != nil {
		return &ValidationError{
			Code:    ErrCodeTimestampImmutable,
			Message: ErrTimestampImmutable.Error(),
			Err:     ErrTimestampImmutable,
		}
	}
	return nil
}

// DefaultTimestamp returns the current UTC time if no timestamp is provided.
// FR-NUT-1.5: Timestamp defaults to server time if omitted.
func DefaultTimestamp(provided *time.Time) time.Time {
	if provided != nil {
		return *provided
	}
	return time.Now().UTC()
}
