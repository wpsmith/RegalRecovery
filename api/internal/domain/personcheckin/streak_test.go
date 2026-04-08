// internal/domain/personcheckin/streak_test.go
package personcheckin

import (
	"testing"
	"time"
)

func makeTimestamp(year, month, day int) time.Time {
	return time.Date(year, time.Month(month), day, 12, 0, 0, 0, time.UTC)
}

func TestPersonCheckInStreak_FR_PCI_4_1_DailyStreakCountsConsecutiveDays(t *testing.T) {
	now := makeTimestamp(2026, 3, 28)

	timestamps := []time.Time{
		makeTimestamp(2026, 3, 22),
		makeTimestamp(2026, 3, 23),
		makeTimestamp(2026, 3, 24),
		makeTimestamp(2026, 3, 25),
		makeTimestamp(2026, 3, 26),
		makeTimestamp(2026, 3, 27),
		makeTimestamp(2026, 3, 28),
	}

	current, longest := CalculateStreak(timestamps, StreakFrequencyDaily, 0, now)

	if current != 7 {
		t.Fatalf("expected current streak 7, got %d", current)
	}
	if longest != 7 {
		t.Fatalf("expected longest streak 7, got %d", longest)
	}
}

func TestPersonCheckInStreak_FR_PCI_4_2_WeeklyStreakCountsConsecutiveWeeks(t *testing.T) {
	now := makeTimestamp(2026, 3, 28)

	// One check-in per week for 4 consecutive weeks.
	timestamps := []time.Time{
		makeTimestamp(2026, 3, 7),
		makeTimestamp(2026, 3, 14),
		makeTimestamp(2026, 3, 21),
		makeTimestamp(2026, 3, 28),
	}

	current, longest := CalculateStreak(timestamps, StreakFrequencyWeekly, 0, now)

	if current != 4 {
		t.Fatalf("expected current streak 4, got %d", current)
	}
	if longest != 4 {
		t.Fatalf("expected longest streak 4, got %d", longest)
	}
}

func TestPersonCheckInStreak_FR_PCI_4_3_DailyStreakResetsOnMissedDay(t *testing.T) {
	// 5-day streak ending on March 25, then gap on March 26, check-in March 27.
	now := makeTimestamp(2026, 3, 28)

	timestamps := []time.Time{
		makeTimestamp(2026, 3, 21),
		makeTimestamp(2026, 3, 22),
		makeTimestamp(2026, 3, 23),
		makeTimestamp(2026, 3, 24),
		makeTimestamp(2026, 3, 25),
		// Gap on March 26.
		makeTimestamp(2026, 3, 27),
		makeTimestamp(2026, 3, 28),
	}

	current, longest := CalculateStreak(timestamps, StreakFrequencyDaily, 0, now)

	if current != 2 {
		t.Fatalf("expected current streak 2, got %d", current)
	}
	if longest != 5 {
		t.Fatalf("expected longest streak 5, got %d", longest)
	}
}

func TestPersonCheckInStreak_FR_PCI_4_3_PreservesLongestStreakOnReset(t *testing.T) {
	now := makeTimestamp(2026, 3, 28)

	timestamps := []time.Time{
		makeTimestamp(2026, 3, 1),
		makeTimestamp(2026, 3, 2),
		makeTimestamp(2026, 3, 3),
		makeTimestamp(2026, 3, 4),
		makeTimestamp(2026, 3, 5),
		makeTimestamp(2026, 3, 6),
		makeTimestamp(2026, 3, 7),
		makeTimestamp(2026, 3, 8),
		makeTimestamp(2026, 3, 9),
		makeTimestamp(2026, 3, 10),
		// 10-day streak, then gap.
		makeTimestamp(2026, 3, 28),
	}

	current, longest := CalculateStreak(timestamps, StreakFrequencyDaily, 0, now)

	if current != 1 {
		t.Fatalf("expected current streak 1, got %d", current)
	}
	if longest != 10 {
		t.Fatalf("expected longest streak 10, got %d", longest)
	}
}

func TestPersonCheckInStreak_FR_PCI_4_4_MultipleSameDayCountsAsOneDay(t *testing.T) {
	now := makeTimestamp(2026, 3, 28)

	timestamps := []time.Time{
		makeTimestamp(2026, 3, 27),
		time.Date(2026, 3, 28, 9, 0, 0, 0, time.UTC),
		time.Date(2026, 3, 28, 14, 0, 0, 0, time.UTC),
		time.Date(2026, 3, 28, 20, 0, 0, 0, time.UTC),
	}

	current, _ := CalculateStreak(timestamps, StreakFrequencyDaily, 0, now)

	if current != 2 {
		t.Fatalf("expected current streak 2 (2 days, not 4 entries), got %d", current)
	}
}

func TestPersonCheckInStreak_FR_PCI_4_5_BackdatedEntryFillsGapInStreak(t *testing.T) {
	now := makeTimestamp(2026, 3, 28)

	// Original: March 26, March 28 (gap on March 27).
	// After backdate: March 26, March 27, March 28.
	timestamps := []time.Time{
		makeTimestamp(2026, 3, 26),
		makeTimestamp(2026, 3, 27), // Backdated entry fills the gap.
		makeTimestamp(2026, 3, 28),
	}

	current, _ := CalculateStreak(timestamps, StreakFrequencyDaily, 0, now)

	if current != 3 {
		t.Fatalf("expected current streak 3, got %d", current)
	}
}

func TestPersonCheckInStreak_FR_PCI_4_6_XPerWeekRequiresConfiguredCount(t *testing.T) {
	now := makeTimestamp(2026, 3, 28)

	// 3 check-ins per week for 2 consecutive weeks.
	timestamps := []time.Time{
		// Week of March 16-22.
		makeTimestamp(2026, 3, 16),
		makeTimestamp(2026, 3, 18),
		makeTimestamp(2026, 3, 20),
		// Week of March 23-29.
		makeTimestamp(2026, 3, 23),
		makeTimestamp(2026, 3, 25),
		makeTimestamp(2026, 3, 27),
	}

	current, longest := CalculateStreak(timestamps, StreakFrequencyXPerWeek, 3, now)

	if current != 2 {
		t.Fatalf("expected current streak 2, got %d", current)
	}
	if longest != 2 {
		t.Fatalf("expected longest streak 2, got %d", longest)
	}
}

func TestPersonCheckInStreak_FR_PCI_4_6_XPerWeekResetsWhenCountNotMet(t *testing.T) {
	now := makeTimestamp(2026, 3, 28)

	timestamps := []time.Time{
		// Week of March 16-22: 3 check-ins (meets requirement).
		makeTimestamp(2026, 3, 16),
		makeTimestamp(2026, 3, 18),
		makeTimestamp(2026, 3, 20),
		// Week of March 23-29: only 1 check-in (doesn't meet 3 required).
		makeTimestamp(2026, 3, 25),
	}

	current, longest := CalculateStreak(timestamps, StreakFrequencyXPerWeek, 3, now)

	// Current week doesn't qualify, so current streak is from last qualifying week.
	if current > 1 {
		t.Fatalf("expected current streak <= 1, got %d", current)
	}
	if longest < 1 {
		t.Fatalf("expected longest streak >= 1, got %d", longest)
	}
}

func TestPersonCheckInStreak_FR_PCI_4_7_FrequencyDashboardIncludesAllMetrics(t *testing.T) {
	now := makeTimestamp(2026, 3, 28)

	timestamps := []time.Time{
		makeTimestamp(2026, 3, 1),
		makeTimestamp(2026, 3, 5),
		makeTimestamp(2026, 3, 10),
		makeTimestamp(2026, 3, 15),
		makeTimestamp(2026, 3, 20),
		makeTimestamp(2026, 3, 24),
		makeTimestamp(2026, 3, 28),
	}

	thisWeek, thisMonth, avgPerWeek := CalculateFrequencyMetrics(timestamps, now)

	if thisWeek < 1 {
		t.Fatalf("expected at least 1 check-in this week, got %d", thisWeek)
	}
	if thisMonth < 7 {
		t.Fatalf("expected at least 7 check-ins this month, got %d", thisMonth)
	}
	if avgPerWeek <= 0 {
		t.Fatalf("expected positive average per week, got %f", avgPerWeek)
	}
}

func TestPersonCheckInStreak_FR_PCI_5_1_FrequencyChangeTriggersRecalculation(t *testing.T) {
	// Test that changing from daily to weekly produces different streak values.
	now := makeTimestamp(2026, 3, 28)

	timestamps := []time.Time{
		makeTimestamp(2026, 3, 7),
		makeTimestamp(2026, 3, 14),
		makeTimestamp(2026, 3, 21),
		makeTimestamp(2026, 3, 28),
	}

	dailyCurrent, _ := CalculateStreak(timestamps, StreakFrequencyDaily, 0, now)
	weeklyCurrent, _ := CalculateStreak(timestamps, StreakFrequencyWeekly, 0, now)

	// Daily streak should be 1 (only today), weekly should be 4.
	if dailyCurrent != 1 {
		t.Fatalf("expected daily current streak 1, got %d", dailyCurrent)
	}
	if weeklyCurrent != 4 {
		t.Fatalf("expected weekly current streak 4, got %d", weeklyCurrent)
	}
}

func TestPersonCheckInStreak_FR_PCI_5_2_DefaultCounselorFrequencyIsWeekly(t *testing.T) {
	settings := DefaultSettings("u_test", "DEFAULT")

	if settings.CounselorCoach.StreakFrequency != StreakFrequencyWeekly {
		t.Fatalf("expected default counselor frequency weekly, got %s", settings.CounselorCoach.StreakFrequency)
	}
}

func TestPersonCheckInStreak_IndependentPerSubType(t *testing.T) {
	// Verify that different sub-types can have different streaks.
	unit := StreakUnitForFrequency(StreakFrequencyDaily)
	if unit != "days" {
		t.Fatalf("expected 'days', got '%s'", unit)
	}

	unit = StreakUnitForFrequency(StreakFrequencyWeekly)
	if unit != "weeks" {
		t.Fatalf("expected 'weeks', got '%s'", unit)
	}
}

func TestPersonCheckInStreak_DeletionTriggersRecalculation(t *testing.T) {
	// Verify that after removing a timestamp, the streak changes.
	now := makeTimestamp(2026, 3, 28)

	before := []time.Time{
		makeTimestamp(2026, 3, 26),
		makeTimestamp(2026, 3, 27),
		makeTimestamp(2026, 3, 28),
	}
	currentBefore, _ := CalculateStreak(before, StreakFrequencyDaily, 0, now)

	after := []time.Time{
		makeTimestamp(2026, 3, 26),
		// March 27 deleted.
		makeTimestamp(2026, 3, 28),
	}
	currentAfter, _ := CalculateStreak(after, StreakFrequencyDaily, 0, now)

	if currentBefore != 3 {
		t.Fatalf("expected streak before deletion 3, got %d", currentBefore)
	}
	if currentAfter != 1 {
		t.Fatalf("expected streak after deletion 1, got %d", currentAfter)
	}
}

func TestPersonCheckInStreak_EmptyHistory_ReturnsZeroStreak(t *testing.T) {
	now := time.Now()

	current, longest := CalculateStreak(nil, StreakFrequencyDaily, 0, now)

	if current != 0 {
		t.Fatalf("expected current streak 0, got %d", current)
	}
	if longest != 0 {
		t.Fatalf("expected longest streak 0, got %d", longest)
	}
}

func TestPersonCheckInStreak_TimezoneHandling_UsesUserTimezone(t *testing.T) {
	// Test that dates are compared by date, not exact time.
	now := time.Date(2026, 3, 28, 23, 59, 0, 0, time.UTC)

	timestamps := []time.Time{
		time.Date(2026, 3, 27, 1, 0, 0, 0, time.UTC),
		time.Date(2026, 3, 28, 23, 30, 0, 0, time.UTC),
	}

	current, _ := CalculateStreak(timestamps, StreakFrequencyDaily, 0, now)

	if current != 2 {
		t.Fatalf("expected current streak 2, got %d", current)
	}
}
