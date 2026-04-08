// internal/domain/exercise/duplicate.go
package exercise

import (
	"math"
	"time"
)

// DuplicateWindowMinutes is the time window in minutes for detecting duplicates.
const DuplicateWindowMinutes = 30

// IsDuplicate checks whether a new exercise log is a duplicate of an existing one.
// A duplicate is detected when:
//  1. The external ID matches (if both are non-nil), OR
//  2. The external ID is nil and the activity type matches within a 30-minute time window.
func IsDuplicate(existing ExerciseLog, newLog CreateExerciseLogRequest) bool {
	// Check external ID match first.
	if existing.ExternalID != nil && newLog.ExternalID != nil {
		if *existing.ExternalID == *newLog.ExternalID {
			return true
		}
	}

	// If new log has no external ID, fall back to time window check.
	if newLog.ExternalID == nil {
		if existing.ActivityType == newLog.ActivityType {
			diffMinutes := math.Abs(existing.Timestamp.Sub(newLog.Timestamp).Minutes())
			return diffMinutes <= DuplicateWindowMinutes
		}
	}

	return false
}

// FindDuplicates checks a list of existing logs for potential duplicates.
func FindDuplicates(existingLogs []ExerciseLog, newLog CreateExerciseLogRequest) []ExerciseLog {
	var duplicates []ExerciseLog
	for _, existing := range existingLogs {
		if IsDuplicate(existing, newLog) {
			duplicates = append(duplicates, existing)
		}
	}
	return duplicates
}

// DuplicateSearchWindow returns the time range to search for potential duplicates.
func DuplicateSearchWindow(timestamp time.Time) (start, end time.Time) {
	window := time.Duration(DuplicateWindowMinutes) * time.Minute
	return timestamp.Add(-window), timestamp.Add(window)
}
