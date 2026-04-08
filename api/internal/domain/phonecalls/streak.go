// internal/domain/phonecalls/streak.go
package phonecalls

import (
	"sort"
	"time"
)

// StreakMilestones defines the milestone day counts that trigger celebrations.
var StreakMilestones = []int{7, 14, 21, 30, 60, 90}

// CalculateStreak computes the current consecutive-day call streak from a list of calls.
// A day counts if at least one call (connected or attempted) was logged.
// Days are calculated in the user's local timezone.
//
// Both connected=true and connected=false count toward the streak because the effort
// of reaching out is the behavior being reinforced, not just the outcome.
func CalculateStreak(calls []PhoneCall, timezone *time.Location) PhoneCallStreak {
	if timezone == nil {
		timezone = time.UTC
	}

	if len(calls) == 0 {
		return PhoneCallStreak{
			CurrentStreakDays:   0,
			LongestStreakDays:   0,
			LastCallDate:        nil,
			TotalCallsAllTime:   0,
			TotalConnectedCalls: 0,
		}
	}

	// Collect unique dates and stats.
	dateSet := make(map[string]bool)
	totalConnected := 0

	for _, call := range calls {
		localTime := call.Timestamp.In(timezone)
		dateStr := localTime.Format("2006-01-02")
		dateSet[dateStr] = true
		if call.Connected {
			totalConnected++
		}
	}

	// Sort dates descending.
	dates := make([]string, 0, len(dateSet))
	for d := range dateSet {
		dates = append(dates, d)
	}
	sort.Sort(sort.Reverse(sort.StringSlice(dates)))

	// Find the last call date.
	lastCallDate := dates[0]

	// Calculate current streak: count consecutive days backward from today.
	today := time.Now().In(timezone).Format("2006-01-02")
	currentStreak := calculateConsecutiveDays(dates, today)

	// Calculate longest streak: find max consecutive run in all dates.
	longestStreak := calculateLongestStreak(dates)

	if currentStreak > longestStreak {
		longestStreak = currentStreak
	}

	return PhoneCallStreak{
		CurrentStreakDays:   currentStreak,
		LongestStreakDays:   longestStreak,
		LastCallDate:        &lastCallDate,
		TotalCallsAllTime:   len(calls),
		TotalConnectedCalls: totalConnected,
	}
}

// calculateConsecutiveDays counts consecutive days backward from the given reference date.
// The dates slice must be sorted descending.
func calculateConsecutiveDays(sortedDatesDesc []string, referenceDate string) int {
	if len(sortedDatesDesc) == 0 {
		return 0
	}

	// The most recent call date must be today or yesterday to have a current streak.
	refDate, err := time.Parse("2006-01-02", referenceDate)
	if err != nil {
		return 0
	}

	// Build a set for O(1) lookup.
	dateSet := make(map[string]bool, len(sortedDatesDesc))
	for _, d := range sortedDatesDesc {
		dateSet[d] = true
	}

	// Check if today has a call. If not, check yesterday as the start point.
	checkDate := refDate
	if !dateSet[checkDate.Format("2006-01-02")] {
		checkDate = refDate.AddDate(0, 0, -1)
		if !dateSet[checkDate.Format("2006-01-02")] {
			return 0
		}
	}

	// Count consecutive days backward.
	streak := 0
	for {
		dateStr := checkDate.Format("2006-01-02")
		if !dateSet[dateStr] {
			break
		}
		streak++
		checkDate = checkDate.AddDate(0, 0, -1)
	}

	return streak
}

// calculateLongestStreak finds the longest consecutive day run in a set of dates.
func calculateLongestStreak(sortedDatesDesc []string) int {
	if len(sortedDatesDesc) == 0 {
		return 0
	}

	// Sort ascending for easier consecutive checking.
	ascending := make([]string, len(sortedDatesDesc))
	copy(ascending, sortedDatesDesc)
	sort.Strings(ascending)

	longest := 1
	current := 1

	for i := 1; i < len(ascending); i++ {
		prevDate, _ := time.Parse("2006-01-02", ascending[i-1])
		currDate, _ := time.Parse("2006-01-02", ascending[i])

		dayDiff := currDate.Sub(prevDate).Hours() / 24
		if dayDiff == 1 {
			current++
			if current > longest {
				longest = current
			}
		} else {
			current = 1
		}
	}

	return longest
}

// IsStreakMilestone checks if a given streak day count is a milestone.
func IsStreakMilestone(days int) bool {
	for _, m := range StreakMilestones {
		if days == m {
			return true
		}
	}
	return false
}
