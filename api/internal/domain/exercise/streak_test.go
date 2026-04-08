// internal/domain/exercise/streak_test.go
package exercise

import (
	"testing"
	"time"
)

func TestExerciseStreak_FR_EX_4_3_ConsecutiveDays_CalculatesCorrectly(t *testing.T) {
	tz := time.UTC
	today := time.Date(2026, 3, 28, 10, 0, 0, 0, tz)

	// Exercise on March 24-27 (4 consecutive days, not including today)
	dates := []time.Time{
		time.Date(2026, 3, 24, 7, 0, 0, 0, tz),
		time.Date(2026, 3, 25, 8, 0, 0, 0, tz),
		time.Date(2026, 3, 26, 6, 30, 0, 0, tz),
		time.Date(2026, 3, 27, 7, 0, 0, 0, tz),
	}

	streak := CalculateStreak(dates, today, tz)
	if streak.CurrentDays != 4 {
		t.Errorf("expected current streak of 4, got %d", streak.CurrentDays)
	}
}

func TestExerciseStreak_FR_EX_4_3_GapInDays_ResetsStreak(t *testing.T) {
	tz := time.UTC
	today := time.Date(2026, 3, 28, 10, 0, 0, 0, tz)

	// Exercise on March 24-25 then gap, then March 27
	dates := []time.Time{
		time.Date(2026, 3, 24, 7, 0, 0, 0, tz),
		time.Date(2026, 3, 25, 8, 0, 0, 0, tz),
		time.Date(2026, 3, 27, 7, 0, 0, 0, tz),
	}

	streak := CalculateStreak(dates, today, tz)
	if streak.CurrentDays != 1 {
		t.Errorf("expected current streak of 1 (only March 27), got %d", streak.CurrentDays)
	}
}

func TestExerciseStreak_FR_EX_4_3_MultipleWorkoutsPerDay_CountsAsOneDay(t *testing.T) {
	tz := time.UTC
	today := time.Date(2026, 3, 28, 10, 0, 0, 0, tz)

	// Two workouts on March 27
	dates := []time.Time{
		time.Date(2026, 3, 26, 7, 0, 0, 0, tz),
		time.Date(2026, 3, 27, 7, 0, 0, 0, tz),
		time.Date(2026, 3, 27, 18, 0, 0, 0, tz),
	}

	streak := CalculateStreak(dates, today, tz)
	if streak.CurrentDays != 2 {
		t.Errorf("expected current streak of 2 (two calendar days), got %d", streak.CurrentDays)
	}
}

func TestExerciseStreak_FR_EX_4_3_NoExerciseToday_ExcludesToday(t *testing.T) {
	tz := time.UTC
	today := time.Date(2026, 3, 28, 10, 0, 0, 0, tz)

	// Exercise only on March 25-26 (not yesterday or today)
	dates := []time.Time{
		time.Date(2026, 3, 25, 7, 0, 0, 0, tz),
		time.Date(2026, 3, 26, 8, 0, 0, 0, tz),
	}

	streak := CalculateStreak(dates, today, tz)
	// Yesterday (27th) was not exercised, so current streak is 0
	if streak.CurrentDays != 0 {
		t.Errorf("expected current streak of 0 (gap on March 27), got %d", streak.CurrentDays)
	}
}

func TestExerciseStreak_FR_EX_4_3_LongestStreak_PreservedAcrossGaps(t *testing.T) {
	tz := time.UTC
	today := time.Date(2026, 3, 28, 10, 0, 0, 0, tz)

	// Longest streak was 5 days (March 10-14), current streak is 2 days (March 26-27)
	dates := []time.Time{
		time.Date(2026, 3, 10, 7, 0, 0, 0, tz),
		time.Date(2026, 3, 11, 7, 0, 0, 0, tz),
		time.Date(2026, 3, 12, 7, 0, 0, 0, tz),
		time.Date(2026, 3, 13, 7, 0, 0, 0, tz),
		time.Date(2026, 3, 14, 7, 0, 0, 0, tz),
		time.Date(2026, 3, 26, 7, 0, 0, 0, tz),
		time.Date(2026, 3, 27, 7, 0, 0, 0, tz),
	}

	streak := CalculateStreak(dates, today, tz)
	if streak.LongestDays != 5 {
		t.Errorf("expected longest streak of 5, got %d", streak.LongestDays)
	}
	if streak.CurrentDays != 2 {
		t.Errorf("expected current streak of 2, got %d", streak.CurrentDays)
	}
}

func TestExerciseStreak_FR_EX_4_3_BackdatedEntry_ExtendsStreakForOriginalDate(t *testing.T) {
	tz := time.UTC
	today := time.Date(2026, 3, 28, 10, 0, 0, 0, tz)

	// Backdated entry for March 25 logged today; continuous from 25-27
	dates := []time.Time{
		time.Date(2026, 3, 25, 7, 0, 0, 0, tz),
		time.Date(2026, 3, 26, 7, 0, 0, 0, tz),
		time.Date(2026, 3, 27, 7, 0, 0, 0, tz),
	}

	streak := CalculateStreak(dates, today, tz)
	if streak.CurrentDays != 3 {
		t.Errorf("expected current streak of 3 (backdated extends), got %d", streak.CurrentDays)
	}
}

func TestExerciseStreak_FR_EX_4_3_EmptyHistory_ReturnsZero(t *testing.T) {
	tz := time.UTC
	today := time.Now().In(tz)

	streak := CalculateStreak(nil, today, tz)
	if streak.CurrentDays != 0 {
		t.Errorf("expected current streak of 0, got %d", streak.CurrentDays)
	}
	if streak.LongestDays != 0 {
		t.Errorf("expected longest streak of 0, got %d", streak.LongestDays)
	}
	if streak.LastExerciseDate != nil {
		t.Errorf("expected nil last exercise date, got %v", *streak.LastExerciseDate)
	}
}

func TestExerciseStreak_FR_EX_4_3_SingleDay_ReturnsOne(t *testing.T) {
	tz := time.UTC
	today := time.Date(2026, 3, 28, 10, 0, 0, 0, tz)

	// Exercise yesterday only
	dates := []time.Time{
		time.Date(2026, 3, 27, 7, 0, 0, 0, tz),
	}

	streak := CalculateStreak(dates, today, tz)
	if streak.CurrentDays != 1 {
		t.Errorf("expected current streak of 1, got %d", streak.CurrentDays)
	}
}

func TestExerciseStreak_FR_EX_4_3_TimezoneHandling_UsesUserTimezone(t *testing.T) {
	la, _ := time.LoadLocation("America/Los_Angeles")
	today := time.Date(2026, 3, 28, 23, 0, 0, 0, la)

	// Exercise at 11 PM LA time on March 27 and 28 (but March 28 is today)
	dates := []time.Time{
		time.Date(2026, 3, 26, 23, 0, 0, 0, la),
		time.Date(2026, 3, 27, 23, 0, 0, 0, la),
	}

	streak := CalculateStreak(dates, today, la)
	if streak.CurrentDays != 2 {
		t.Errorf("expected current streak of 2 in LA timezone, got %d", streak.CurrentDays)
	}
}

func TestExerciseStreak_FR_EX_4_3_NextMilestone_CalculatesCorrectly(t *testing.T) {
	tz := time.UTC
	today := time.Date(2026, 3, 28, 10, 0, 0, 0, tz)

	// 5-day streak
	dates := make([]time.Time, 5)
	for i := 0; i < 5; i++ {
		dates[i] = today.AddDate(0, 0, -(i + 1))
	}

	streak := CalculateStreak(dates, today, tz)
	if streak.NextMilestone == nil {
		t.Fatal("expected non-nil next milestone")
	}
	if streak.NextMilestone.Days != 7 {
		t.Errorf("expected next milestone at 7 days, got %d", streak.NextMilestone.Days)
	}
	if streak.NextMilestone.DaysRemaining != 2 {
		t.Errorf("expected 2 days remaining, got %d", streak.NextMilestone.DaysRemaining)
	}
}

func TestExerciseStreak_FR_EX_4_3_NextMilestone_AtMilestone_ReturnsNext(t *testing.T) {
	tz := time.UTC
	today := time.Date(2026, 3, 28, 10, 0, 0, 0, tz)

	// 7-day streak (at the 1 Week milestone)
	dates := make([]time.Time, 7)
	for i := 0; i < 7; i++ {
		dates[i] = today.AddDate(0, 0, -(i + 1))
	}

	streak := CalculateStreak(dates, today, tz)
	if streak.NextMilestone == nil {
		t.Fatal("expected non-nil next milestone")
	}
	if streak.NextMilestone.Days != 14 {
		t.Errorf("expected next milestone at 14 days (after 7), got %d", streak.NextMilestone.Days)
	}
}
