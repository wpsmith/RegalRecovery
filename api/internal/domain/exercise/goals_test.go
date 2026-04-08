// internal/domain/exercise/goals_test.go
package exercise

import (
	"testing"
	"time"
)

func TestGoal_FR_EX_6_1_SetGoal_ValidMinutesAndSessions(t *testing.T) {
	minutes := 150
	sessions := 4
	goal := ExerciseGoal{
		TargetActiveMinutes: &minutes,
		TargetSessions:      &sessions,
	}
	if err := ValidateGoal(goal); err != nil {
		t.Errorf("expected valid goal, got error: %v", err)
	}
}

func TestGoal_FR_EX_6_1_SetGoal_OnlyMinutes_Valid(t *testing.T) {
	minutes := 150
	goal := ExerciseGoal{
		TargetActiveMinutes: &minutes,
	}
	if err := ValidateGoal(goal); err != nil {
		t.Errorf("expected valid goal with only minutes, got error: %v", err)
	}
}

func TestGoal_FR_EX_6_1_SetGoal_OnlySessions_Valid(t *testing.T) {
	sessions := 4
	goal := ExerciseGoal{
		TargetSessions: &sessions,
	}
	if err := ValidateGoal(goal); err != nil {
		t.Errorf("expected valid goal with only sessions, got error: %v", err)
	}
}

func TestGoal_FR_EX_6_1_SetGoal_NeitherMinutesNorSessions_RejectsEmpty(t *testing.T) {
	goal := ExerciseGoal{}
	err := ValidateGoal(goal)
	if err == nil {
		t.Error("expected error for empty goal")
	}
	if err != ErrGoalEmpty {
		t.Errorf("expected ErrGoalEmpty, got: %v", err)
	}
}

func TestGoal_FR_EX_6_2_ProgressCalculation_ActiveMinutesPercent(t *testing.T) {
	minutes := 150
	goal := ExerciseGoal{TargetActiveMinutes: &minutes}
	logs := []ExerciseLog{
		{DurationMinutes: 30},
		{DurationMinutes: 45},
		{DurationMinutes: 45},
	}
	weekStart := time.Date(2026, 3, 23, 0, 0, 0, 0, time.UTC)

	progress := CalculateGoalProgress(goal, logs, weekStart)
	// 120/150 = 80%
	if progress.ProgressPercent != 80.0 {
		t.Errorf("expected 80.0%%, got %.1f%%", progress.ProgressPercent)
	}
	if progress.CurrentActiveMinutes != 120 {
		t.Errorf("expected 120 current minutes, got %d", progress.CurrentActiveMinutes)
	}
}

func TestGoal_FR_EX_6_2_ProgressCalculation_SessionsPercent(t *testing.T) {
	sessions := 4
	goal := ExerciseGoal{TargetSessions: &sessions}
	logs := []ExerciseLog{
		{DurationMinutes: 30},
		{DurationMinutes: 30},
		{DurationMinutes: 30},
	}
	weekStart := time.Date(2026, 3, 23, 0, 0, 0, 0, time.UTC)

	progress := CalculateGoalProgress(goal, logs, weekStart)
	// 3/4 = 75%
	if progress.ProgressPercent != 75.0 {
		t.Errorf("expected 75.0%%, got %.1f%%", progress.ProgressPercent)
	}
}

func TestGoal_FR_EX_6_2_ProgressCalculation_UsesHigherPercent(t *testing.T) {
	minutes := 200
	sessions := 3
	goal := ExerciseGoal{
		TargetActiveMinutes: &minutes,
		TargetSessions:      &sessions,
	}
	logs := []ExerciseLog{
		{DurationMinutes: 60},
		{DurationMinutes: 60},
		{DurationMinutes: 60},
	}
	weekStart := time.Date(2026, 3, 23, 0, 0, 0, 0, time.UTC)

	progress := CalculateGoalProgress(goal, logs, weekStart)
	// Minutes: 180/200 = 90%, Sessions: 3/3 = 100%
	// Higher is 100%
	if progress.ProgressPercent != 100.0 {
		t.Errorf("expected 100.0%% (higher of 90%% and 100%%), got %.1f%%", progress.ProgressPercent)
	}
}

func TestGoal_FR_EX_6_3_GoalMet_DetectsThresholdCrossing(t *testing.T) {
	minutes := 100
	goal := ExerciseGoal{TargetActiveMinutes: &minutes}
	logs := []ExerciseLog{
		{DurationMinutes: 50},
		{DurationMinutes: 50},
	}
	weekStart := time.Date(2026, 3, 23, 0, 0, 0, 0, time.UTC)

	progress := CalculateGoalProgress(goal, logs, weekStart)
	if !progress.IsGoalMet {
		t.Error("expected goal to be met at exactly 100/100 minutes")
	}
}

func TestGoal_FR_EX_6_3_GoalNotMet_DoesNotTrigger(t *testing.T) {
	minutes := 150
	goal := ExerciseGoal{TargetActiveMinutes: &minutes}
	logs := []ExerciseLog{
		{DurationMinutes: 30},
	}
	weekStart := time.Date(2026, 3, 23, 0, 0, 0, 0, time.UTC)

	progress := CalculateGoalProgress(goal, logs, weekStart)
	if progress.IsGoalMet {
		t.Error("expected goal to NOT be met at 30/150 minutes")
	}
}

func TestGoal_FR_EX_6_3_GoalExceeded_ReportsOver100Percent(t *testing.T) {
	minutes := 100
	goal := ExerciseGoal{TargetActiveMinutes: &minutes}
	logs := []ExerciseLog{
		{DurationMinutes: 80},
		{DurationMinutes: 80},
	}
	weekStart := time.Date(2026, 3, 23, 0, 0, 0, 0, time.UTC)

	progress := CalculateGoalProgress(goal, logs, weekStart)
	// 160/100 = 160%
	if progress.ProgressPercent != 160.0 {
		t.Errorf("expected 160.0%%, got %.1f%%", progress.ProgressPercent)
	}
	if !progress.IsGoalMet {
		t.Error("expected goal to be met when exceeded")
	}
}

func TestGoal_FR_EX_6_4_DynamicGoalIntegration_AutoChecksPhysicalGoal(t *testing.T) {
	// This test verifies the domain logic for detecting when a log
	// should trigger a physical dynamic goal auto-check.
	// The actual auto-check is handled by the event handler; here we verify
	// that goal met detection works correctly.
	sessions := 1
	goal := ExerciseGoal{TargetSessions: &sessions}
	logs := []ExerciseLog{
		{DurationMinutes: 30},
	}
	weekStart := time.Date(2026, 3, 23, 0, 0, 0, 0, time.UTC)

	progress := CalculateGoalProgress(goal, logs, weekStart)
	if !progress.IsGoalMet {
		t.Error("expected goal met for 1/1 session (triggers dynamic goal auto-check)")
	}
}

func TestWeekStartDate_ReturnsMonday(t *testing.T) {
	// 2026-03-28 is a Saturday
	date := time.Date(2026, 3, 28, 10, 0, 0, 0, time.UTC)
	weekStart := WeekStartDate(date)
	if weekStart.Weekday() != time.Monday {
		t.Errorf("expected Monday, got %s", weekStart.Weekday())
	}
	if weekStart.Day() != 23 {
		t.Errorf("expected March 23, got March %d", weekStart.Day())
	}
}

func TestWeekStartDate_Sunday_ReturnsPreviousMonday(t *testing.T) {
	// 2026-03-29 is a Sunday
	date := time.Date(2026, 3, 29, 10, 0, 0, 0, time.UTC)
	weekStart := WeekStartDate(date)
	if weekStart.Weekday() != time.Monday {
		t.Errorf("expected Monday, got %s", weekStart.Weekday())
	}
	if weekStart.Day() != 23 {
		t.Errorf("expected March 23, got March %d", weekStart.Day())
	}
}
