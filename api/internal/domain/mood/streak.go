// internal/domain/mood/streak.go
package mood

import (
	"sort"
	"time"
)

// StreakInfo holds mood tracking streak data.
type StreakInfo struct {
	CurrentStreakDays int    `json:"currentStreakDays"`
	LongestStreakDays int    `json:"longestStreakDays"`
	LastEntryDate     string `json:"lastEntryDate"`
}

// CalculateStreak computes the current and longest mood tracking streaks
// from a list of distinct date strings (YYYY-MM-DD) when entries were logged.
// today is the current date string to anchor the streak.
func CalculateStreak(entryDates []string, today string) StreakInfo {
	if len(entryDates) == 0 {
		return StreakInfo{}
	}

	// Sort dates in ascending order.
	sorted := make([]string, len(entryDates))
	copy(sorted, entryDates)
	sort.Strings(sorted)

	// Deduplicate.
	unique := []string{sorted[0]}
	for i := 1; i < len(sorted); i++ {
		if sorted[i] != sorted[i-1] {
			unique = append(unique, sorted[i])
		}
	}

	lastEntryDate := unique[len(unique)-1]

	// Parse dates.
	parsedDates := make([]time.Time, 0, len(unique))
	for _, ds := range unique {
		t, err := time.Parse("2006-01-02", ds)
		if err != nil {
			continue
		}
		parsedDates = append(parsedDates, t)
	}

	if len(parsedDates) == 0 {
		return StreakInfo{LastEntryDate: lastEntryDate}
	}

	// Calculate current streak: count consecutive days backward from the last entry date.
	// The streak is only current if the last entry is today or yesterday.
	todayParsed, _ := time.Parse("2006-01-02", today)
	lastParsed := parsedDates[len(parsedDates)-1]

	daysSinceLastEntry := int(todayParsed.Sub(lastParsed).Hours() / 24)

	currentStreak := 0
	if daysSinceLastEntry <= 1 {
		// Walk backward from the last date.
		currentStreak = 1
		for i := len(parsedDates) - 2; i >= 0; i-- {
			diff := parsedDates[i+1].Sub(parsedDates[i])
			if diff.Hours() == 24 {
				currentStreak++
			} else {
				break
			}
		}
	}

	// Calculate longest streak.
	longestStreak := 1
	currentRun := 1
	for i := 1; i < len(parsedDates); i++ {
		diff := parsedDates[i].Sub(parsedDates[i-1])
		if diff.Hours() == 24 {
			currentRun++
		} else {
			currentRun = 1
		}
		if currentRun > longestStreak {
			longestStreak = currentRun
		}
	}

	return StreakInfo{
		CurrentStreakDays: currentStreak,
		LongestStreakDays: longestStreak,
		LastEntryDate:     lastEntryDate,
	}
}
