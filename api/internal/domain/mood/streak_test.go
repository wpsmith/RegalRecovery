// internal/domain/mood/streak_test.go
package mood

import "testing"

func TestMood_AC041_Streak_ConsecutiveDays(t *testing.T) {
	// Given: entries on April 5, 6, 7 (3 consecutive days)
	entryDates := []string{"2026-04-05", "2026-04-06", "2026-04-07"}
	today := "2026-04-07"

	// When: streak is calculated
	streak := CalculateStreak(entryDates, today)

	// Then: currentStreakDays = 3
	if streak.CurrentStreakDays != 3 {
		t.Errorf("expected currentStreakDays = 3, got %d", streak.CurrentStreakDays)
	}
}

func TestMood_AC041_Streak_GapBreaks(t *testing.T) {
	// Given: entries on April 3, 5, 6, 7 (gap on April 4)
	entryDates := []string{"2026-04-03", "2026-04-05", "2026-04-06", "2026-04-07"}
	today := "2026-04-07"

	// When: streak is calculated
	streak := CalculateStreak(entryDates, today)

	// Then: currentStreakDays = 3 (from April 5)
	if streak.CurrentStreakDays != 3 {
		t.Errorf("expected currentStreakDays = 3, got %d", streak.CurrentStreakDays)
	}
}

func TestMood_AC041_Streak_MultipleEntriesSameDay(t *testing.T) {
	// Given: multiple entries on same days (duplicates in date list)
	entryDates := []string{"2026-04-06", "2026-04-07", "2026-04-07", "2026-04-07", "2026-04-07", "2026-04-07"}
	today := "2026-04-07"

	// When: streak is calculated
	streak := CalculateStreak(entryDates, today)

	// Then: currentStreakDays = 2 (multiple same-day entries count as one day)
	if streak.CurrentStreakDays != 2 {
		t.Errorf("expected currentStreakDays = 2, got %d", streak.CurrentStreakDays)
	}
}

func TestMood_Streak_NoDates(t *testing.T) {
	// Given: no entry dates
	streak := CalculateStreak([]string{}, "2026-04-07")

	// Then: all zeros
	if streak.CurrentStreakDays != 0 {
		t.Errorf("expected currentStreakDays = 0, got %d", streak.CurrentStreakDays)
	}
	if streak.LongestStreakDays != 0 {
		t.Errorf("expected longestStreakDays = 0, got %d", streak.LongestStreakDays)
	}
}

func TestMood_Streak_LongestStreak(t *testing.T) {
	// Given: 5 consecutive days, gap, then 3 consecutive days (current)
	entryDates := []string{
		"2026-03-20", "2026-03-21", "2026-03-22", "2026-03-23", "2026-03-24",
		// gap
		"2026-04-05", "2026-04-06", "2026-04-07",
	}
	today := "2026-04-07"

	// When: streak is calculated
	streak := CalculateStreak(entryDates, today)

	// Then: current = 3, longest = 5
	if streak.CurrentStreakDays != 3 {
		t.Errorf("expected currentStreakDays = 3, got %d", streak.CurrentStreakDays)
	}
	if streak.LongestStreakDays != 5 {
		t.Errorf("expected longestStreakDays = 5, got %d", streak.LongestStreakDays)
	}
}

func TestMood_Streak_LastEntryYesterday(t *testing.T) {
	// Given: last entry was yesterday
	entryDates := []string{"2026-04-05", "2026-04-06"}
	today := "2026-04-07"

	// When: streak is calculated
	streak := CalculateStreak(entryDates, today)

	// Then: current streak still counts (yesterday is within 1 day)
	if streak.CurrentStreakDays != 2 {
		t.Errorf("expected currentStreakDays = 2, got %d", streak.CurrentStreakDays)
	}
}

func TestMood_Streak_LastEntryTwoDaysAgo(t *testing.T) {
	// Given: last entry was 2 days ago
	entryDates := []string{"2026-04-04", "2026-04-05"}
	today := "2026-04-07"

	// When: streak is calculated
	streak := CalculateStreak(entryDates, today)

	// Then: current streak = 0 (broken)
	if streak.CurrentStreakDays != 0 {
		t.Errorf("expected currentStreakDays = 0, got %d", streak.CurrentStreakDays)
	}
	// But longest streak preserved
	if streak.LongestStreakDays != 2 {
		t.Errorf("expected longestStreakDays = 2, got %d", streak.LongestStreakDays)
	}
}

func TestMood_Streak_LastEntryDate(t *testing.T) {
	// Given: entries on specific dates
	entryDates := []string{"2026-04-05", "2026-04-06", "2026-04-07"}
	today := "2026-04-07"

	// When: streak is calculated
	streak := CalculateStreak(entryDates, today)

	// Then: lastEntryDate is the most recent
	if streak.LastEntryDate != "2026-04-07" {
		t.Errorf("expected lastEntryDate = '2026-04-07', got '%s'", streak.LastEntryDate)
	}
}
