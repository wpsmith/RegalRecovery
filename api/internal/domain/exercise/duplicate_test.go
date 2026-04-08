// internal/domain/exercise/duplicate_test.go
package exercise

import (
	"testing"
	"time"
)

func TestDuplicate_FR_EX_8_3_SameTypeWithin30Min_DetectedAsDuplicate(t *testing.T) {
	existing := ExerciseLog{
		ActivityType: ActivityTypeRunning,
		Timestamp:    time.Date(2026, 3, 28, 7, 0, 0, 0, time.UTC),
	}
	newLog := CreateExerciseLogRequest{
		ActivityType: ActivityTypeRunning,
		Timestamp:    time.Date(2026, 3, 28, 7, 5, 0, 0, time.UTC),
	}

	if !IsDuplicate(existing, newLog) {
		t.Error("expected duplicate for same type within 30 minutes")
	}
}

func TestDuplicate_FR_EX_8_3_SameTypeOutside30Min_NotDuplicate(t *testing.T) {
	existing := ExerciseLog{
		ActivityType: ActivityTypeRunning,
		Timestamp:    time.Date(2026, 3, 28, 7, 0, 0, 0, time.UTC),
	}
	newLog := CreateExerciseLogRequest{
		ActivityType: ActivityTypeRunning,
		Timestamp:    time.Date(2026, 3, 28, 8, 0, 0, 0, time.UTC),
	}

	if IsDuplicate(existing, newLog) {
		t.Error("expected no duplicate for same type outside 30 minutes")
	}
}

func TestDuplicate_FR_EX_8_3_DifferentType_NotDuplicate(t *testing.T) {
	existing := ExerciseLog{
		ActivityType: ActivityTypeRunning,
		Timestamp:    time.Date(2026, 3, 28, 7, 0, 0, 0, time.UTC),
	}
	newLog := CreateExerciseLogRequest{
		ActivityType: ActivityTypeYoga,
		Timestamp:    time.Date(2026, 3, 28, 7, 5, 0, 0, time.UTC),
	}

	if IsDuplicate(existing, newLog) {
		t.Error("expected no duplicate for different activity types")
	}
}

func TestDuplicate_FR_EX_8_3_ExternalIdMatch_DetectedAsDuplicate(t *testing.T) {
	extID := "apple-health-123"
	existing := ExerciseLog{
		ActivityType: ActivityTypeRunning,
		Timestamp:    time.Date(2026, 3, 28, 7, 0, 0, 0, time.UTC),
		ExternalID:   &extID,
	}
	newLog := CreateExerciseLogRequest{
		ActivityType: ActivityTypeRunning,
		Timestamp:    time.Date(2026, 3, 28, 9, 0, 0, 0, time.UTC), // 2 hours later
		ExternalID:   &extID,
	}

	if !IsDuplicate(existing, newLog) {
		t.Error("expected duplicate for matching external ID")
	}
}

func TestDuplicate_FR_EX_8_3_NullExternalId_FallsBackToTimeWindow(t *testing.T) {
	extID := "apple-health-123"
	existing := ExerciseLog{
		ActivityType: ActivityTypeRunning,
		Timestamp:    time.Date(2026, 3, 28, 7, 0, 0, 0, time.UTC),
		ExternalID:   &extID,
	}
	newLog := CreateExerciseLogRequest{
		ActivityType: ActivityTypeRunning,
		Timestamp:    time.Date(2026, 3, 28, 7, 10, 0, 0, time.UTC),
		ExternalID:   nil, // null external ID
	}

	// When new log has nil external ID, should fall back to time window check
	if !IsDuplicate(existing, newLog) {
		t.Error("expected duplicate via time window fallback when external ID is nil")
	}
}

func TestFindDuplicates_ReturnsAllMatches(t *testing.T) {
	existing := []ExerciseLog{
		{
			ExerciseID:   "ex_1",
			ActivityType: ActivityTypeRunning,
			Timestamp:    time.Date(2026, 3, 28, 7, 0, 0, 0, time.UTC),
		},
		{
			ExerciseID:   "ex_2",
			ActivityType: ActivityTypeYoga,
			Timestamp:    time.Date(2026, 3, 28, 7, 5, 0, 0, time.UTC),
		},
		{
			ExerciseID:   "ex_3",
			ActivityType: ActivityTypeRunning,
			Timestamp:    time.Date(2026, 3, 28, 7, 10, 0, 0, time.UTC),
		},
	}

	newLog := CreateExerciseLogRequest{
		ActivityType: ActivityTypeRunning,
		Timestamp:    time.Date(2026, 3, 28, 7, 5, 0, 0, time.UTC),
	}

	dups := FindDuplicates(existing, newLog)
	if len(dups) != 2 {
		t.Errorf("expected 2 duplicates (running within 30 min), got %d", len(dups))
	}
}
