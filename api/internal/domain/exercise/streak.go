// internal/domain/exercise/streak.go
package exercise

import (
	"sort"
	"time"
)

// StreakMilestones defines the exercise streak milestone progression.
var StreakMilestones = []int{3, 7, 14, 21, 30, 60, 90}

// MilestoneLabels maps milestone days to display labels.
var MilestoneLabels = map[int]string{
	3:  "3 Days",
	7:  "1 Week",
	14: "2 Weeks",
	21: "3 Weeks",
	30: "1 Month",
	60: "2 Months",
	90: "3 Months",
}

// CalculateStreak computes the exercise streak from a list of exercise log dates.
// Dates should be in the user's local timezone for correct day boundary calculation.
// The 'today' parameter represents the current date in the user's timezone.
// Today is excluded from the streak (only completed days count per FR-EX-4.3).
func CalculateStreak(exerciseDates []time.Time, today time.Time, tz *time.Location) ExerciseStreak {
	if len(exerciseDates) == 0 {
		return ExerciseStreak{
			CurrentDays:      0,
			LongestDays:      0,
			LastExerciseDate: nil,
			NextMilestone:    nextMilestoneInfo(0),
		}
	}

	if tz == nil {
		tz = time.UTC
	}

	// Normalize all dates to calendar days in the user's timezone.
	daySet := make(map[string]bool)
	for _, d := range exerciseDates {
		local := d.In(tz)
		dayKey := local.Format("2006-01-02")
		daySet[dayKey] = true
	}

	// Sort unique days descending.
	days := make([]string, 0, len(daySet))
	for d := range daySet {
		days = append(days, d)
	}
	sort.Sort(sort.Reverse(sort.StringSlice(days)))

	// Parse today as a calendar day in the user's timezone.
	todayLocal := today.In(tz)
	todayKey := todayLocal.Format("2006-01-02")

	// Get the last exercise date.
	lastExerciseDate := days[0]

	// Calculate current streak working backward from yesterday.
	// Today is excluded per FR-EX-4.3: "only completed days count."
	yesterdayKey := todayLocal.AddDate(0, 0, -1).Format("2006-01-02")

	currentStreak := 0
	checkDate := yesterdayKey

	// If the user exercised today, start counting from today and include it.
	// But per the spec, today is excluded. We check from yesterday backward.
	if daySet[todayKey] {
		// Today counts if the user also exercised yesterday (continuous streak from yesterday).
		// But today itself is excluded from the "completed days" count.
		// We start from yesterday.
	}

	for daySet[checkDate] {
		currentStreak++
		d, _ := time.Parse("2006-01-02", checkDate)
		checkDate = d.AddDate(0, 0, -1).Format("2006-01-02")
	}

	// Calculate longest streak across all days.
	longestStreak := calculateLongestStreak(days)

	// Ensure longest >= current.
	if currentStreak > longestStreak {
		longestStreak = currentStreak
	}

	return ExerciseStreak{
		CurrentDays:      currentStreak,
		LongestDays:      longestStreak,
		LastExerciseDate: &lastExerciseDate,
		NextMilestone:    nextMilestoneInfo(currentStreak),
	}
}

// calculateLongestStreak finds the longest run of consecutive calendar days.
func calculateLongestStreak(sortedDaysDesc []string) int {
	if len(sortedDaysDesc) == 0 {
		return 0
	}

	// Sort ascending for easier consecutive day detection.
	ascending := make([]string, len(sortedDaysDesc))
	copy(ascending, sortedDaysDesc)
	sort.Strings(ascending)

	longest := 1
	current := 1

	for i := 1; i < len(ascending); i++ {
		prevDate, _ := time.Parse("2006-01-02", ascending[i-1])
		currDate, _ := time.Parse("2006-01-02", ascending[i])

		if currDate.Sub(prevDate).Hours() == 24 {
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

// nextMilestoneInfo returns the next milestone info for the given streak.
func nextMilestoneInfo(currentDays int) *MilestoneInfo {
	for _, milestone := range StreakMilestones {
		if milestone > currentDays {
			label, ok := MilestoneLabels[milestone]
			if !ok {
				label = ""
			}
			return &MilestoneInfo{
				Days:          milestone,
				DaysRemaining: milestone - currentDays,
				Label:         label,
			}
		}
	}
	return nil
}

// NextExerciseMilestone returns the next milestone day count for a given streak.
func NextExerciseMilestone(currentStreak int) int {
	for _, m := range StreakMilestones {
		if m > currentStreak {
			return m
		}
	}
	return 0
}
