// internal/domain/exercise/stats_test.go
package exercise

import (
	"testing"
	"time"
)

func TestExerciseStats_FR_EX_4_1_WeeklySummary_TotalActiveMinutes(t *testing.T) {
	logs := []ExerciseLog{
		{DurationMinutes: 30, ActivityType: ActivityTypeRunning},
		{DurationMinutes: 45, ActivityType: ActivityTypeYoga},
		{DurationMinutes: 60, ActivityType: ActivityTypeGym},
	}

	stats := CalculateStats(logs, nil, ExerciseStreak{}, "week", "2026-03-28")
	if stats.TotalActiveMinutes != 135 {
		t.Errorf("expected 135 active minutes, got %d", stats.TotalActiveMinutes)
	}
}

func TestExerciseStats_FR_EX_4_1_WeeklySummary_SessionCount(t *testing.T) {
	logs := []ExerciseLog{
		{DurationMinutes: 30},
		{DurationMinutes: 45},
		{DurationMinutes: 60},
	}

	stats := CalculateStats(logs, nil, ExerciseStreak{}, "week", "2026-03-28")
	if stats.SessionCount != 3 {
		t.Errorf("expected 3 sessions, got %d", stats.SessionCount)
	}
}

func TestExerciseStats_FR_EX_4_1_WeeklySummary_MostCommonActivityType(t *testing.T) {
	logs := []ExerciseLog{
		{ActivityType: ActivityTypeRunning, DurationMinutes: 30},
		{ActivityType: ActivityTypeRunning, DurationMinutes: 30},
		{ActivityType: ActivityTypeYoga, DurationMinutes: 60},
	}

	stats := CalculateStats(logs, nil, ExerciseStreak{}, "week", "2026-03-28")
	if stats.MostCommonActivityType == nil {
		t.Fatal("expected non-nil most common activity type")
	}
	if *stats.MostCommonActivityType != ActivityTypeRunning {
		t.Errorf("expected running as most common, got %s", *stats.MostCommonActivityType)
	}
}

func TestExerciseStats_FR_EX_4_1_WeeklySummary_ComparisonToPreviousWeek(t *testing.T) {
	currentLogs := []ExerciseLog{
		{DurationMinutes: 30, ActivityType: ActivityTypeRunning},
		{DurationMinutes: 45, ActivityType: ActivityTypeYoga},
	}
	previousLogs := []ExerciseLog{
		{DurationMinutes: 20, ActivityType: ActivityTypeWalking},
	}

	stats := CalculateStats(currentLogs, previousLogs, ExerciseStreak{}, "week", "2026-03-28")
	if stats.ComparisonToPrevious == nil {
		t.Fatal("expected non-nil comparison")
	}
	if stats.ComparisonToPrevious.ActiveMinutesDelta != 55 {
		t.Errorf("expected +55 minutes delta, got %d", stats.ComparisonToPrevious.ActiveMinutesDelta)
	}
	if stats.ComparisonToPrevious.SessionCountDelta != 1 {
		t.Errorf("expected +1 session delta, got %d", stats.ComparisonToPrevious.SessionCountDelta)
	}
}

func TestExerciseStats_FR_EX_4_1_WeeklySummary_EmptyWeek_ReturnsZeros(t *testing.T) {
	stats := CalculateStats(nil, nil, ExerciseStreak{}, "week", "2026-03-28")
	if stats.TotalActiveMinutes != 0 {
		t.Errorf("expected 0 active minutes, got %d", stats.TotalActiveMinutes)
	}
	if stats.SessionCount != 0 {
		t.Errorf("expected 0 sessions, got %d", stats.SessionCount)
	}
	if stats.MostCommonActivityType != nil {
		t.Errorf("expected nil most common type, got %v", *stats.MostCommonActivityType)
	}
}

func TestExerciseStats_FR_EX_4_2_ActivityTypeDistribution_CorrectCounts(t *testing.T) {
	intensity := IntensityModerate
	logs := []ExerciseLog{
		{ActivityType: ActivityTypeRunning, DurationMinutes: 30, Intensity: &intensity},
		{ActivityType: ActivityTypeRunning, DurationMinutes: 30, Intensity: &intensity},
		{ActivityType: ActivityTypeYoga, DurationMinutes: 60, Intensity: &intensity},
	}

	stats := CalculateStats(logs, nil, ExerciseStreak{}, "week", "2026-03-28")
	if len(stats.ActivityTypeDistribution) != 2 {
		t.Fatalf("expected 2 activity types, got %d", len(stats.ActivityTypeDistribution))
	}
	// Sorted by count descending.
	if stats.ActivityTypeDistribution[0].ActivityType != ActivityTypeRunning {
		t.Errorf("expected running first, got %s", stats.ActivityTypeDistribution[0].ActivityType)
	}
	if stats.ActivityTypeDistribution[0].Count != 2 {
		t.Errorf("expected running count 2, got %d", stats.ActivityTypeDistribution[0].Count)
	}
	if stats.ActivityTypeDistribution[0].TotalMinutes != 60 {
		t.Errorf("expected running total 60 min, got %d", stats.ActivityTypeDistribution[0].TotalMinutes)
	}
}

func TestExerciseStats_FR_EX_4_2_IntensityDistribution_CorrectCounts(t *testing.T) {
	light := IntensityLight
	moderate := IntensityModerate
	logs := []ExerciseLog{
		{ActivityType: ActivityTypeRunning, DurationMinutes: 30, Intensity: &moderate},
		{ActivityType: ActivityTypeRunning, DurationMinutes: 30, Intensity: &moderate},
		{ActivityType: ActivityTypeYoga, DurationMinutes: 60, Intensity: &light},
	}

	stats := CalculateStats(logs, nil, ExerciseStreak{}, "week", "2026-03-28")
	if len(stats.IntensityDistribution) != 2 {
		t.Fatalf("expected 2 intensity levels, got %d", len(stats.IntensityDistribution))
	}
}

func TestExerciseStats_FR_EX_4_2_MonthlyView_AggregatesCorrectly(t *testing.T) {
	logs := []ExerciseLog{
		{DurationMinutes: 30, ActivityType: ActivityTypeRunning},
		{DurationMinutes: 45, ActivityType: ActivityTypeYoga},
	}

	stats := CalculateStats(logs, nil, ExerciseStreak{}, "month", "2026-03-28")
	if stats.Period != "month" {
		t.Errorf("expected period 'month', got %s", stats.Period)
	}
	if stats.TotalActiveMinutes != 75 {
		t.Errorf("expected 75 active minutes, got %d", stats.TotalActiveMinutes)
	}
}

func TestExerciseStats_FR_EX_4_2_NinetyDayView_AggregatesCorrectly(t *testing.T) {
	logs := []ExerciseLog{
		{DurationMinutes: 30, ActivityType: ActivityTypeRunning},
	}

	stats := CalculateStats(logs, nil, ExerciseStreak{}, "90-day", "2026-03-28")
	if stats.Period != "90-day" {
		t.Errorf("expected period '90-day', got %s", stats.Period)
	}
}

func TestPeriodDateRange_Week_StartsMonday(t *testing.T) {
	// 2026-03-28 is a Saturday
	ref := time.Date(2026, 3, 28, 0, 0, 0, 0, time.UTC)
	start, end := PeriodDateRange("week", ref)

	if start.Weekday() != time.Monday {
		t.Errorf("expected week to start on Monday, got %s", start.Weekday())
	}
	if end.Weekday() != time.Sunday {
		t.Errorf("expected week to end on Sunday, got %s", end.Weekday())
	}
}
