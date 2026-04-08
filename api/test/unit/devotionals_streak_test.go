// test/unit/devotionals_streak_test.go
package unit

import (
	"testing"

	"github.com/regalrecovery/api/internal/domain/devotionals"
)

// =============================================================================
// Devotional Streak Calculation Tests
// Location: internal/domain/devotionals/streak_test.go (spec)
// =============================================================================

// TestStreak_AC_DEV_NOTIFY_04_ConsecutiveDaysIncrement verifies that
// consecutive days increment the streak.
func TestStreak_AC_DEV_NOTIFY_04_ConsecutiveDaysIncrement(t *testing.T) {
	// Given: user completed devotionals on days 1-14 (current streak = 14)
	lastDate := "2026-04-14"

	// When: completion recorded for day 15
	result := devotionals.CalculateStreak(14, 14, &lastDate, "2026-04-15", "America/New_York")

	// Then
	if result.CurrentDays != 15 {
		t.Errorf("expected currentDays=15, got %d", result.CurrentDays)
	}
	if result.LongestDays != 15 {
		t.Errorf("expected longestDays=15, got %d", result.LongestDays)
	}
}

// TestStreak_MissedDay_ResetsToOne verifies that missing a day resets the
// current streak to 1 (the new completion).
func TestStreak_MissedDay_ResetsToOne(t *testing.T) {
	// Given: user completed devotionals on days 1-14, missed day 15
	lastDate := "2026-04-14"

	// When: completion recorded for day 16 (skipped day 15)
	result := devotionals.CalculateStreak(14, 14, &lastDate, "2026-04-16", "America/New_York")

	// Then
	if result.CurrentDays != 1 {
		t.Errorf("expected currentDays=1 after missed day, got %d", result.CurrentDays)
	}
	if result.LongestDays != 14 {
		t.Errorf("expected longestDays=14 (preserved), got %d", result.LongestDays)
	}
}

// TestStreak_LongestStreakPreserved verifies that the longest streak is
// preserved even when the current streak is broken and rebuilt.
func TestStreak_LongestStreakPreserved(t *testing.T) {
	// Given: longest streak was 23, current streak broken (now 5)
	lastDate := "2026-04-20"

	// When: new completion extends current streak to 6
	result := devotionals.CalculateStreak(5, 23, &lastDate, "2026-04-21", "America/New_York")

	// Then
	if result.CurrentDays != 6 {
		t.Errorf("expected currentDays=6, got %d", result.CurrentDays)
	}
	if result.LongestDays != 23 {
		t.Errorf("expected longestDays=23 (preserved), got %d", result.LongestDays)
	}
}

// TestStreak_FirstCompletion_StartsAtOne verifies that the first devotional
// completion starts the streak at 1.
func TestStreak_FirstCompletion_StartsAtOne(t *testing.T) {
	// Given: no previous completions
	// When: first completion
	result := devotionals.CalculateStreak(0, 0, nil, "2026-04-07", "America/New_York")

	// Then
	if result.CurrentDays != 1 {
		t.Errorf("expected currentDays=1 for first completion, got %d", result.CurrentDays)
	}
	if result.LongestDays != 1 {
		t.Errorf("expected longestDays=1 for first completion, got %d", result.LongestDays)
	}
}

// TestStreak_SameDay_NoIncrement verifies that completing a second devotional
// on the same day does not increment the streak.
func TestStreak_SameDay_NoIncrement(t *testing.T) {
	// Given: already completed today
	lastDate := "2026-04-07"

	// When: another completion on the same day
	result := devotionals.CalculateStreak(5, 10, &lastDate, "2026-04-07", "America/New_York")

	// Then
	if result.CurrentDays != 5 {
		t.Errorf("expected currentDays=5 (unchanged), got %d", result.CurrentDays)
	}
	if result.LongestDays != 10 {
		t.Errorf("expected longestDays=10 (unchanged), got %d", result.LongestDays)
	}
}

// TestStreak_NewLongestStreak verifies that when current exceeds longest,
// longest is updated.
func TestStreak_NewLongestStreak(t *testing.T) {
	// Given: current=9, longest=9, last completed yesterday
	lastDate := "2026-04-06"

	// When: completion today makes it 10
	result := devotionals.CalculateStreak(9, 9, &lastDate, "2026-04-07", "America/New_York")

	// Then
	if result.CurrentDays != 10 {
		t.Errorf("expected currentDays=10, got %d", result.CurrentDays)
	}
	if result.LongestDays != 10 {
		t.Errorf("expected longestDays=10, got %d", result.LongestDays)
	}
}

// TestStreak_MissedMultipleDays_ResetsToOne verifies that missing multiple days
// still resets the streak to 1.
func TestStreak_MissedMultipleDays_ResetsToOne(t *testing.T) {
	// Given: last completed 5 days ago
	lastDate := "2026-04-02"

	// When: completion today
	result := devotionals.CalculateStreak(10, 15, &lastDate, "2026-04-07", "America/New_York")

	// Then
	if result.CurrentDays != 1 {
		t.Errorf("expected currentDays=1, got %d", result.CurrentDays)
	}
	if result.LongestDays != 15 {
		t.Errorf("expected longestDays=15 (preserved), got %d", result.LongestDays)
	}
}

// TestStreak_EmptyLastDate_StartsAtOne verifies graceful handling of empty
// last completed date.
func TestStreak_EmptyLastDate_StartsAtOne(t *testing.T) {
	emptyDate := ""
	result := devotionals.CalculateStreak(0, 0, &emptyDate, "2026-04-07", "America/New_York")

	if result.CurrentDays != 1 {
		t.Errorf("expected currentDays=1, got %d", result.CurrentDays)
	}
}
