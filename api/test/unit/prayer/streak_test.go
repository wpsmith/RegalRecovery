// test/unit/prayer/streak_test.go
package prayer_test

import (
	"testing"
	"time"

	"github.com/regalrecovery/api/internal/domain/prayer"
)

func daysAgo(n int) time.Time {
	return time.Now().UTC().AddDate(0, 0, -n).Truncate(24 * time.Hour).Add(6 * time.Hour)
}

// TestPrayerStreak_PR_AC5_1_CalculatesConsecutiveDays verifies streak calculation
// for consecutive daily prayer sessions.
//
// Acceptance Criterion (PR-AC5.1): Consecutive days with at least one prayer session.
func TestPrayerStreak_PR_AC5_1_CalculatesConsecutiveDays(t *testing.T) {
	// Given prayer sessions on each of the last 14 consecutive days.
	timestamps := make([]time.Time, 14)
	for i := 0; i < 14; i++ {
		timestamps[i] = daysAgo(i)
	}

	now := time.Now().UTC()
	stats := prayer.CalculatePrayerStreak(timestamps, now, time.UTC)

	if stats.CurrentStreakDays != 14 {
		t.Errorf("expected currentStreakDays=14, got %d", stats.CurrentStreakDays)
	}
}

// TestPrayerStreak_PR_AC5_1_StreakBreaksOnMissedDay verifies streak breaks when a day is missed.
//
// Acceptance Criterion (PR-AC5.1): Missing a day resets the current streak.
func TestPrayerStreak_PR_AC5_1_StreakBreaksOnMissedDay(t *testing.T) {
	// Given sessions on days 0-2 and 4-13 (day 3 missing from today).
	// Today = day 0, yesterday = day 1, etc.
	// Sessions: today, yesterday, 2 days ago, then 4-13 days ago (gap on day 3).
	var timestamps []time.Time
	for i := 0; i < 3; i++ {
		timestamps = append(timestamps, daysAgo(i))
	}
	// Skip day 3.
	for i := 4; i < 14; i++ {
		timestamps = append(timestamps, daysAgo(i))
	}

	now := time.Now().UTC()
	stats := prayer.CalculatePrayerStreak(timestamps, now, time.UTC)

	// Current streak should be 3 (days 0, 1, 2).
	if stats.CurrentStreakDays != 3 {
		t.Errorf("expected currentStreakDays=3 (gap on day 3), got %d", stats.CurrentStreakDays)
	}
}

// TestPrayerStreak_PR_AC5_2_MultipleSameDay_CountsAsOneDay verifies multiple sessions
// on the same day count as one day.
//
// Acceptance Criterion (PR-AC5.2): Multiple sessions in one day count as one day for streak.
func TestPrayerStreak_PR_AC5_2_MultipleSameDay_CountsAsOneDay(t *testing.T) {
	// Given 3 prayer sessions on today.
	today := time.Now().UTC().Truncate(24 * time.Hour)
	timestamps := []time.Time{
		today.Add(6 * time.Hour),
		today.Add(12 * time.Hour),
		today.Add(20 * time.Hour),
	}

	now := time.Now().UTC()
	stats := prayer.CalculatePrayerStreak(timestamps, now, time.UTC)

	// Total prayer days should be 1.
	if stats.TotalPrayerDays != 1 {
		t.Errorf("expected totalPrayerDays=1, got %d", stats.TotalPrayerDays)
	}
}

// TestPrayerStreak_PR_AC5_3_LongestStreakUpdated verifies longest streak updates.
//
// Acceptance Criterion (PR-AC5.3): longestStreakDays updates when current exceeds it.
func TestPrayerStreak_PR_AC5_3_LongestStreakUpdated(t *testing.T) {
	// Given an active streak of 31 consecutive days.
	timestamps := make([]time.Time, 31)
	for i := 0; i < 31; i++ {
		timestamps[i] = daysAgo(i)
	}

	now := time.Now().UTC()
	stats := prayer.CalculatePrayerStreak(timestamps, now, time.UTC)

	if stats.LongestStreakDays < 31 {
		t.Errorf("expected longestStreakDays >= 31, got %d", stats.LongestStreakDays)
	}
}

// TestPrayerStreak_PR_AC5_3_LongestStreakPreservedOnBreak verifies longest streak
// is preserved when current streak is broken.
//
// Acceptance Criterion (PR-AC5.3): Longest streak is historical, not current.
func TestPrayerStreak_PR_AC5_3_LongestStreakPreservedOnBreak(t *testing.T) {
	// Given: a 30-day streak in the past (days 40-11), then a gap, then a 5-day current streak.
	var timestamps []time.Time
	// Old 30-day streak (days 40 through 11 ago).
	for i := 11; i <= 40; i++ {
		timestamps = append(timestamps, daysAgo(i))
	}
	// Current 5-day streak (days 0-4).
	for i := 0; i < 5; i++ {
		timestamps = append(timestamps, daysAgo(i))
	}

	now := time.Now().UTC()
	stats := prayer.CalculatePrayerStreak(timestamps, now, time.UTC)

	if stats.CurrentStreakDays != 5 {
		t.Errorf("expected currentStreakDays=5, got %d", stats.CurrentStreakDays)
	}
	if stats.LongestStreakDays != 30 {
		t.Errorf("expected longestStreakDays=30, got %d", stats.LongestStreakDays)
	}
}

// TestPrayerStreak_PR_AC5_5_TotalPrayerDaysCountsDistinctDays verifies total prayer
// days counts distinct days.
//
// Acceptance Criterion (PR-AC5.5): totalPrayerDays counts distinct calendar days.
func TestPrayerStreak_PR_AC5_5_TotalPrayerDaysCountsDistinctDays(t *testing.T) {
	// Given 50 sessions across 30 distinct days (some days have multiple sessions).
	var timestamps []time.Time
	for i := 0; i < 30; i++ {
		ts := daysAgo(i)
		timestamps = append(timestamps, ts)
		// Add second session on every other day.
		if i%2 == 0 {
			timestamps = append(timestamps, ts.Add(4*time.Hour))
		}
	}

	now := time.Now().UTC()
	stats := prayer.CalculatePrayerStreak(timestamps, now, time.UTC)

	if stats.TotalPrayerDays != 30 {
		t.Errorf("expected totalPrayerDays=30, got %d", stats.TotalPrayerDays)
	}
}

// TestPrayerStreak_PR_AC5_6_TypeDistribution verifies type distribution calculation.
//
// Acceptance Criterion (PR-AC5.6): Count per prayer type.
func TestPrayerStreak_PR_AC5_6_TypeDistribution(t *testing.T) {
	sessions := []prayer.PrayerSession{
		{PrayerType: "personal"}, {PrayerType: "personal"}, {PrayerType: "personal"},
		{PrayerType: "personal"}, {PrayerType: "personal"}, {PrayerType: "personal"},
		{PrayerType: "personal"}, {PrayerType: "personal"}, {PrayerType: "personal"},
		{PrayerType: "personal"},
		{PrayerType: "guided"}, {PrayerType: "guided"}, {PrayerType: "guided"},
		{PrayerType: "guided"}, {PrayerType: "guided"},
		{PrayerType: "group"}, {PrayerType: "group"}, {PrayerType: "group"},
	}

	dist := prayer.CalculateTypeDistribution(sessions)

	expected := map[string]int{
		"personal":       10,
		"guided":         5,
		"group":          3,
		"scriptureBased": 0,
		"intercessory":   0,
		"listening":      0,
	}

	for pt, count := range expected {
		if dist[pt] != count {
			t.Errorf("expected %s=%d, got %d", pt, count, dist[pt])
		}
	}
}

// TestPrayerStreak_TimezoneHandling_UsesUserTimezone verifies timezone-aware day boundaries.
func TestPrayerStreak_TimezoneHandling_UsesUserTimezone(t *testing.T) {
	la, err := time.LoadLocation("America/Los_Angeles")
	if err != nil {
		t.Fatalf("failed to load LA timezone: %v", err)
	}

	// Session at 11:30 PM PST on March 28 = next day in UTC.
	sessionTime := time.Date(2026, 3, 28, 23, 30, 0, 0, la)
	now := time.Date(2026, 3, 28, 23, 59, 0, 0, la)

	timestamps := []time.Time{sessionTime}
	stats := prayer.CalculatePrayerStreak(timestamps, now, la)

	// Should count as today (March 28 in LA timezone), so streak = 1.
	if stats.CurrentStreakDays != 1 {
		t.Errorf("expected currentStreakDays=1 (same day in user TZ), got %d", stats.CurrentStreakDays)
	}
}

// TestPrayerStreak_EmptyHistory verifies zero state.
func TestPrayerStreak_EmptyHistory(t *testing.T) {
	now := time.Now().UTC()
	stats := prayer.CalculatePrayerStreak(nil, now, time.UTC)

	if stats.CurrentStreakDays != 0 {
		t.Errorf("expected currentStreakDays=0, got %d", stats.CurrentStreakDays)
	}
	if stats.LongestStreakDays != 0 {
		t.Errorf("expected longestStreakDays=0, got %d", stats.LongestStreakDays)
	}
	if stats.TotalPrayerDays != 0 {
		t.Errorf("expected totalPrayerDays=0, got %d", stats.TotalPrayerDays)
	}
}

// TestPrayerStreak_AverageDuration verifies average duration calculation.
func TestPrayerStreak_AverageDuration(t *testing.T) {
	sessions := []prayer.PrayerSession{
		{DurationMinutes: intPtr(10)},
		{DurationMinutes: intPtr(20)},
		{DurationMinutes: nil}, // No duration.
		{DurationMinutes: intPtr(30)},
	}

	avg := prayer.CalculateAverageDuration(sessions)
	if avg == nil {
		t.Fatal("expected non-nil average duration")
	}
	// (10 + 20 + 30) / 3 = 20.0
	if *avg != 20.0 {
		t.Errorf("expected averageDuration=20.0, got %f", *avg)
	}
}

// TestPrayerStreak_AverageDuration_AllNil verifies nil when no durations.
func TestPrayerStreak_AverageDuration_AllNil(t *testing.T) {
	sessions := []prayer.PrayerSession{
		{DurationMinutes: nil},
		{DurationMinutes: nil},
	}

	avg := prayer.CalculateAverageDuration(sessions)
	if avg != nil {
		t.Errorf("expected nil average when all durations nil, got %f", *avg)
	}
}

// TestPrayerStreak_MoodImpact verifies mood impact calculation.
func TestPrayerStreak_MoodImpact(t *testing.T) {
	sessions := []prayer.PrayerSession{
		{MoodBefore: intPtr(2), MoodAfter: intPtr(4)},
		{MoodBefore: intPtr(3), MoodAfter: intPtr(5)},
		{MoodBefore: intPtr(4), MoodAfter: intPtr(3)},
	}

	impact := prayer.CalculateMoodImpact(sessions)
	if impact == nil {
		t.Fatal("expected non-nil mood impact")
	}
	if impact.AverageMoodBefore == nil {
		t.Fatal("expected non-nil average mood before")
	}
	if impact.AverageMoodAfter == nil {
		t.Fatal("expected non-nil average mood after")
	}
	// (2+3+4)/3 = 3.0
	if *impact.AverageMoodBefore != 3.0 {
		t.Errorf("expected averageMoodBefore=3.0, got %f", *impact.AverageMoodBefore)
	}
	// (4+5+3)/3 = 4.0
	if *impact.AverageMoodAfter != 4.0 {
		t.Errorf("expected averageMoodAfter=4.0, got %f", *impact.AverageMoodAfter)
	}
}

// TestTimeOfDay verifies time-of-day classification.
func TestTimeOfDay(t *testing.T) {
	loc := time.UTC

	tests := []struct {
		hour     int
		expected string
	}{
		{5, "morning"},
		{11, "morning"},
		{12, "midday"},
		{16, "midday"},
		{17, "evening"},
		{20, "evening"},
		{21, "lateNight"},
		{3, "lateNight"},
	}

	for _, tt := range tests {
		ts := time.Date(2026, 3, 28, tt.hour, 0, 0, 0, loc)
		result := prayer.TimeOfDay(ts, loc)
		if result != tt.expected {
			t.Errorf("hour %d: expected %q, got %q", tt.hour, tt.expected, result)
		}
	}
}
