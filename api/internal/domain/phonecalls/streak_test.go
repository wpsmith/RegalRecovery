// internal/domain/phonecalls/streak_test.go
package phonecalls

import (
	"testing"
	"time"
)

// helper to create a call at a specific date.
func callAt(t time.Time, connected bool) PhoneCall {
	return PhoneCall{
		CallID:    "pc_test",
		Timestamp: t,
		Direction: DirectionMade,
		Connected: connected,
	}
}

// helper to create a call at a specific date string (YYYY-MM-DD).
func callOnDate(dateStr string, connected bool) PhoneCall {
	t, _ := time.Parse("2006-01-02", dateStr)
	t = t.Add(12 * time.Hour) // noon
	return PhoneCall{
		CallID:    "pc_test",
		Timestamp: t,
		Direction: DirectionMade,
		Connected: connected,
	}
}

func TestCallStreak_AC_PC_50_AttemptedCallCountsTowardStreak(t *testing.T) {
	// Given a call that was attempted but not connected
	today := time.Now().UTC().Truncate(24 * time.Hour).Add(12 * time.Hour)
	calls := []PhoneCall{
		callAt(today, false), // attempted, not connected
	}

	// When streak is calculated
	streak := CalculateStreak(calls, time.UTC)

	// Then the day counts toward the streak
	if streak.CurrentStreakDays != 1 {
		t.Errorf("expected current streak 1 for attempted call, got %d", streak.CurrentStreakDays)
	}
}

func TestCallStreak_AC_PC_50_ConnectedCallCountsTowardStreak(t *testing.T) {
	// Given a call that was connected
	today := time.Now().UTC().Truncate(24 * time.Hour).Add(12 * time.Hour)
	calls := []PhoneCall{
		callAt(today, true),
	}

	// When streak is calculated
	streak := CalculateStreak(calls, time.UTC)

	// Then the day counts toward the streak
	if streak.CurrentStreakDays != 1 {
		t.Errorf("expected current streak 1 for connected call, got %d", streak.CurrentStreakDays)
	}
}

func TestCallStreak_AC_PC_51_FirstCallOfDay_IncrementsStreak(t *testing.T) {
	// Given user had no calls today
	today := time.Now().UTC().Truncate(24 * time.Hour).Add(12 * time.Hour)
	yesterday := today.AddDate(0, 0, -1)
	calls := []PhoneCall{
		callAt(yesterday, true),
		callAt(today, true), // first call today
	}

	// When streak is calculated
	streak := CalculateStreak(calls, time.UTC)

	// Then streak increments to include today
	if streak.CurrentStreakDays != 2 {
		t.Errorf("expected current streak 2, got %d", streak.CurrentStreakDays)
	}
}

func TestCallStreak_AC_PC_52_SecondCallSameDay_NoDoubleCount(t *testing.T) {
	// Given user already logged a call today
	today := time.Now().UTC().Truncate(24 * time.Hour)
	calls := []PhoneCall{
		callAt(today.Add(9*time.Hour), true),  // morning call
		callAt(today.Add(14*time.Hour), true), // afternoon call
	}

	// When streak is calculated
	streak := CalculateStreak(calls, time.UTC)

	// Then streak stays at 1 day (not 2)
	if streak.CurrentStreakDays != 1 {
		t.Errorf("expected current streak 1 (no double count), got %d", streak.CurrentStreakDays)
	}
}

func TestCallStreak_AC_PC_53_BackdatedCall_RecalculatesStreak(t *testing.T) {
	// Given user has calls on days 1 and 3 (gap on day 2)
	today := time.Now().UTC().Truncate(24 * time.Hour).Add(12 * time.Hour)
	day1 := today.AddDate(0, 0, -2)
	day3 := today // today

	calls := []PhoneCall{
		callAt(day1, true),
		callAt(day3, true),
	}

	// Streak should be 1 (only today, because yesterday has no call)
	streak := CalculateStreak(calls, time.UTC)
	if streak.CurrentStreakDays != 1 {
		t.Errorf("expected streak 1 with gap, got %d", streak.CurrentStreakDays)
	}
}

func TestCallStreak_AC_PC_53_BackdatedCall_FillsGap_ExtendsStreak(t *testing.T) {
	// Given user adds a backdated call for the gap day
	today := time.Now().UTC().Truncate(24 * time.Hour).Add(12 * time.Hour)
	day1 := today.AddDate(0, 0, -2)
	day2 := today.AddDate(0, 0, -1)
	day3 := today

	calls := []PhoneCall{
		callAt(day1, true),
		callAt(day2, true), // gap filled
		callAt(day3, true),
	}

	// When streak is recalculated
	streak := CalculateStreak(calls, time.UTC)

	// Then streak extends to 3
	if streak.CurrentStreakDays != 3 {
		t.Errorf("expected streak 3 after filling gap, got %d", streak.CurrentStreakDays)
	}
}

func TestCallStreak_NoCalls_ZeroStreak(t *testing.T) {
	calls := []PhoneCall{}

	streak := CalculateStreak(calls, time.UTC)

	if streak.CurrentStreakDays != 0 {
		t.Errorf("expected 0 streak for no calls, got %d", streak.CurrentStreakDays)
	}
	if streak.LongestStreakDays != 0 {
		t.Errorf("expected 0 longest streak for no calls, got %d", streak.LongestStreakDays)
	}
	if streak.LastCallDate != nil {
		t.Error("expected nil last call date for no calls")
	}
	if streak.TotalCallsAllTime != 0 {
		t.Errorf("expected 0 total calls, got %d", streak.TotalCallsAllTime)
	}
}

func TestCallStreak_GapInDays_StreakResets(t *testing.T) {
	// Given calls 5 days ago and today (4-day gap)
	today := time.Now().UTC().Truncate(24 * time.Hour).Add(12 * time.Hour)
	fiveDaysAgo := today.AddDate(0, 0, -5)

	calls := []PhoneCall{
		callAt(fiveDaysAgo, true),
		callAt(today, true),
	}

	streak := CalculateStreak(calls, time.UTC)

	// Current streak should be 1 (only today)
	if streak.CurrentStreakDays != 1 {
		t.Errorf("expected current streak 1 after gap, got %d", streak.CurrentStreakDays)
	}
}

func TestCallStreak_ConsecutiveDays_CorrectCount(t *testing.T) {
	today := time.Now().UTC().Truncate(24 * time.Hour).Add(12 * time.Hour)
	calls := make([]PhoneCall, 0, 7)
	for i := 6; i >= 0; i-- {
		calls = append(calls, callAt(today.AddDate(0, 0, -i), true))
	}

	streak := CalculateStreak(calls, time.UTC)

	if streak.CurrentStreakDays != 7 {
		t.Errorf("expected 7-day streak, got %d", streak.CurrentStreakDays)
	}
}

func TestCallStreak_DeleteCall_RecalculatesStreak(t *testing.T) {
	// Given 3 consecutive days of calls
	today := time.Now().UTC().Truncate(24 * time.Hour).Add(12 * time.Hour)
	calls := []PhoneCall{
		callAt(today.AddDate(0, 0, -2), true),
		// day -1 removed (simulating delete)
		callAt(today, true),
	}

	// When streak is calculated after deletion
	streak := CalculateStreak(calls, time.UTC)

	// Then streak reflects the gap
	if streak.CurrentStreakDays != 1 {
		t.Errorf("expected streak 1 after deleting middle day, got %d", streak.CurrentStreakDays)
	}
}

func TestCallStreak_DeleteLastCallOfDay_BreaksStreak(t *testing.T) {
	// Given today's only call is deleted, but yesterday has calls
	today := time.Now().UTC().Truncate(24 * time.Hour).Add(12 * time.Hour)
	calls := []PhoneCall{
		callAt(today.AddDate(0, 0, -1), true),
		// today's call deleted
	}

	streak := CalculateStreak(calls, time.UTC)

	// Current streak should be 1 (yesterday only, if "today" check falls through to yesterday)
	if streak.CurrentStreakDays != 1 {
		t.Errorf("expected streak 1 with yesterday call only, got %d", streak.CurrentStreakDays)
	}
}

func TestCallStreak_TotalCalls_CountsAll(t *testing.T) {
	today := time.Now().UTC().Truncate(24 * time.Hour).Add(12 * time.Hour)
	calls := []PhoneCall{
		callAt(today, true),
		callAt(today.Add(time.Hour), false),
		callAt(today.Add(2*time.Hour), true),
	}

	streak := CalculateStreak(calls, time.UTC)

	if streak.TotalCallsAllTime != 3 {
		t.Errorf("expected 3 total calls, got %d", streak.TotalCallsAllTime)
	}
	if streak.TotalConnectedCalls != 2 {
		t.Errorf("expected 2 connected calls, got %d", streak.TotalConnectedCalls)
	}
}

func TestCallStreak_LongestStreak_TracksHistorical(t *testing.T) {
	// 5-day streak in the past, then a gap, then 2-day current streak
	today := time.Now().UTC().Truncate(24 * time.Hour).Add(12 * time.Hour)

	calls := []PhoneCall{
		// 5-day past streak (10 to 6 days ago)
		callAt(today.AddDate(0, 0, -10), true),
		callAt(today.AddDate(0, 0, -9), true),
		callAt(today.AddDate(0, 0, -8), true),
		callAt(today.AddDate(0, 0, -7), true),
		callAt(today.AddDate(0, 0, -6), true),
		// gap on day -5 through -2
		// 2-day current streak
		callAt(today.AddDate(0, 0, -1), true),
		callAt(today, true),
	}

	streak := CalculateStreak(calls, time.UTC)

	if streak.CurrentStreakDays != 2 {
		t.Errorf("expected current streak 2, got %d", streak.CurrentStreakDays)
	}
	if streak.LongestStreakDays != 5 {
		t.Errorf("expected longest streak 5, got %d", streak.LongestStreakDays)
	}
}

func TestIsStreakMilestone(t *testing.T) {
	tests := []struct {
		days     int
		expected bool
	}{
		{7, true},
		{14, true},
		{21, true},
		{30, true},
		{60, true},
		{90, true},
		{1, false},
		{10, false},
		{100, false},
	}

	for _, tc := range tests {
		result := IsStreakMilestone(tc.days)
		if result != tc.expected {
			t.Errorf("IsStreakMilestone(%d) = %v, expected %v", tc.days, result, tc.expected)
		}
	}
}
