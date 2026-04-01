// test/unit/tracking_test.go
package unit

import (
	"testing"
	"time"

	"github.com/regalrecovery/api/internal/domain/tracking"
)

// TestStreak_FR2_2_CalculatesCurrentStreakInRealTime verifies that the streak
// calculator correctly computes the number of days between sobriety date and current date.
//
// Acceptance Criterion (FR2.2): The system must calculate streak days in real-time
// based on the user's sobriety start date and current date in their timezone.
func TestStreak_FR2_2_CalculatesCurrentStreakInRealTime(t *testing.T) {
	// Given - Sobriety date 270 days ago
	now := time.Now().UTC()
	sobrietyDate := now.AddDate(0, 0, -270)

	// When
	streak := tracking.CalculateStreakDays(sobrietyDate, now)

	// Then
	if streak != 270 {
		t.Errorf("expected streak of 270 days, got %d", streak)
	}
}

// TestStreak_FR2_2_HandlesTimezoneTransitions verifies that streak calculation
// respects the user's timezone when determining day boundaries.
//
// Acceptance Criterion (FR2.2): Timezone transitions must be handled correctly
// so that a day change in the user's local time increments the streak appropriately.
func TestStreak_FR2_2_HandlesTimezoneTransitions(t *testing.T) {
	// Given - User in Los Angeles (UTC-8)
	la, err := time.LoadLocation("America/Los_Angeles")
	if err != nil {
		t.Fatalf("failed to load LA timezone: %v", err)
	}

	// Sobriety started on March 1, 2026 at midnight LA time
	sobrietyDate := time.Date(2026, 3, 1, 0, 0, 0, 0, la)

	// Current time: March 29, 2026 at 11 PM LA time
	currentDate := time.Date(2026, 3, 29, 23, 0, 0, 0, la)

	// When
	streak := tracking.CalculateStreakDays(sobrietyDate, currentDate)

	// Then - 27 days (March 1 to March 29 = 27 complete days)
	// The calculation normalizes to start of day, so the difference is the days between
	if streak != 27 {
		t.Errorf("expected streak of 27 days with LA timezone, got %d", streak)
	}
}

// TestStreak_FR2_2_ZeroDaysIfSobrietyDateIsToday verifies edge case where
// sobriety starts today.
//
// Acceptance Criterion (FR2.2): On the sobriety start date itself, the streak should be 0.
func TestStreak_FR2_2_ZeroDaysIfSobrietyDateIsToday(t *testing.T) {
	// Given - Sobriety started today
	now := time.Now().UTC()
	sobrietyDate := now

	// When
	streak := tracking.CalculateStreakDays(sobrietyDate, now)

	// Then
	if streak != 0 {
		t.Errorf("expected streak of 0 days when sobriety date is today, got %d", streak)
	}
}

// TestStreak_FR2_2_NegativeDaysNotPossible verifies that a sobriety date in the
// future returns 0 days instead of a negative value.
//
// Acceptance Criterion (FR2.2): Future dates are invalid; streak should be 0.
func TestStreak_FR2_2_NegativeDaysNotPossible(t *testing.T) {
	// Given - Sobriety date set to tomorrow (invalid input)
	now := time.Now().UTC()
	sobrietyDate := now.AddDate(0, 0, 1)

	// When
	streak := tracking.CalculateStreakDays(sobrietyDate, now)

	// Then - Should return 0, not negative
	if streak != 0 {
		t.Errorf("expected streak of 0 days for future sobriety date, got %d", streak)
	}
}

// TestStreak_NextMilestone_Returns365For270Days verifies that the next milestone
// is correctly identified when the user has 270 days.
//
// Acceptance Criterion (Feature 3 - Milestones): Milestone progression includes
// 1, 3, 7, 14, 21, 30, 60, 90, 120, 180, 270, 365 days.
func TestStreak_NextMilestone_Returns365For270Days(t *testing.T) {
	// Given - User at 270 days
	currentStreak := 270

	// When
	nextMilestone := tracking.NextMilestone(currentStreak)

	// Then
	if nextMilestone != 365 {
		t.Errorf("expected next milestone 365 for 270-day streak, got %d", nextMilestone)
	}
}

// TestStreak_NextMilestone_Returns180For120Days verifies that after 120 days,
// the next milestone is 180 (6 months).
func TestStreak_NextMilestone_Returns180For120Days(t *testing.T) {
	// Given - User at 120 days
	currentStreak := 120

	// When
	nextMilestone := tracking.NextMilestone(currentStreak)

	// Then
	if nextMilestone != 180 {
		t.Errorf("expected next milestone 180 for 120-day streak, got %d", nextMilestone)
	}
}

// TestStreak_NextMilestone_Returns1For0Days verifies that a brand new user
// sees the first milestone at 1 day.
func TestStreak_NextMilestone_Returns1For0Days(t *testing.T) {
	// Given - User just starting (day 0)
	currentStreak := 0

	// When
	nextMilestone := tracking.NextMilestone(currentStreak)

	// Then
	if nextMilestone != 1 {
		t.Errorf("expected next milestone 1 for 0-day streak, got %d", nextMilestone)
	}
}

// TestStreak_MilestoneScripture_HasScriptureForAllMilestones verifies that every
// milestone has an associated scripture reference.
//
// Acceptance Criterion (Feature 3): Each milestone displays a relevant Bible verse.
func TestStreak_MilestoneScripture_HasScriptureForAllMilestones(t *testing.T) {
	// Given - All defined milestones
	milestones := tracking.GetAllMilestones()

	// When/Then - Each milestone must have a non-empty scripture
	for _, milestone := range milestones {
		scripture := tracking.MilestoneScripture(milestone)
		if scripture == "" {
			t.Errorf("milestone %d missing scripture reference", milestone)
		}
	}
}
