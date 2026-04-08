// internal/domain/personcheckin/streak.go
package personcheckin

import (
	"sort"
	"time"
)

// CalculateStreak computes the current and longest streaks from a list of check-in timestamps.
// The calculation depends on the configured streak frequency.
func CalculateStreak(timestamps []time.Time, frequency StreakFrequency, requiredCountPerWeek int, now time.Time) (currentStreak int, longestStreak int) {
	if len(timestamps) == 0 {
		return 0, 0
	}

	switch frequency {
	case StreakFrequencyDaily:
		return calculateDailyStreak(timestamps, now)
	case StreakFrequencyWeekly:
		return calculateWeeklyStreak(timestamps, now)
	case StreakFrequencyXPerWeek:
		return calculateXPerWeekStreak(timestamps, requiredCountPerWeek, now)
	default:
		return calculateDailyStreak(timestamps, now)
	}
}

// calculateDailyStreak calculates streak based on consecutive days with at least one check-in.
func calculateDailyStreak(timestamps []time.Time, now time.Time) (currentStreak int, longestStreak int) {
	days := uniqueDays(timestamps)
	if len(days) == 0 {
		return 0, 0
	}

	sort.Strings(days)

	// Calculate today's date string.
	today := dateString(now)
	yesterday := dateString(now.AddDate(0, 0, -1))

	// Calculate all consecutive runs.
	longest := 1
	current := 1

	for i := len(days) - 1; i > 0; i-- {
		prevDate := parseDate(days[i-1])
		currDate := parseDate(days[i])

		diff := currDate.Sub(prevDate)
		if diff == 24*time.Hour {
			current++
			if current > longest {
				longest = current
			}
		} else {
			current = 1
		}
	}

	// Recalculate longest from forward pass.
	longest = 1
	run := 1
	for i := 1; i < len(days); i++ {
		prevDate := parseDate(days[i-1])
		currDate := parseDate(days[i])
		if currDate.Sub(prevDate) == 24*time.Hour {
			run++
			if run > longest {
				longest = run
			}
		} else {
			run = 1
		}
	}

	// Current streak: count from the latest day backward.
	lastDay := days[len(days)-1]
	if lastDay != today && lastDay != yesterday {
		// Streak is broken: last check-in was before yesterday.
		return 0, longest
	}

	currentRun := 1
	for i := len(days) - 1; i > 0; i-- {
		prevDate := parseDate(days[i-1])
		currDate := parseDate(days[i])
		if currDate.Sub(prevDate) == 24*time.Hour {
			currentRun++
		} else {
			break
		}
	}

	if currentRun > longest {
		longest = currentRun
	}

	return currentRun, longest
}

// calculateWeeklyStreak calculates streak based on consecutive calendar weeks
// with at least one check-in.
func calculateWeeklyStreak(timestamps []time.Time, now time.Time) (currentStreak int, longestStreak int) {
	weeks := uniqueWeeks(timestamps)
	if len(weeks) == 0 {
		return 0, 0
	}

	sort.Strings(weeks)

	// Calculate current week identifier.
	currentWeek := weekString(now)
	lastWeek := weekString(now.AddDate(0, 0, -7))

	// Calculate longest run.
	longest := 1
	run := 1
	for i := 1; i < len(weeks); i++ {
		if areConsecutiveWeeks(weeks[i-1], weeks[i]) {
			run++
			if run > longest {
				longest = run
			}
		} else {
			run = 1
		}
	}

	// Current streak.
	lastRecordedWeek := weeks[len(weeks)-1]
	if lastRecordedWeek != currentWeek && lastRecordedWeek != lastWeek {
		return 0, longest
	}

	currentRun := 1
	for i := len(weeks) - 1; i > 0; i-- {
		if areConsecutiveWeeks(weeks[i-1], weeks[i]) {
			currentRun++
		} else {
			break
		}
	}

	if currentRun > longest {
		longest = currentRun
	}

	return currentRun, longest
}

// calculateXPerWeekStreak calculates streak based on having requiredCount check-ins
// per rolling 7-day window. Each window that meets the requirement counts as one week.
func calculateXPerWeekStreak(timestamps []time.Time, requiredCount int, now time.Time) (currentStreak int, longestStreak int) {
	if requiredCount <= 0 {
		requiredCount = 1
	}

	weeks := uniqueWeeks(timestamps)
	if len(weeks) == 0 {
		return 0, 0
	}

	sort.Strings(weeks)

	// Count check-ins per week.
	weekCounts := make(map[string]int)
	for _, ts := range timestamps {
		w := weekString(ts)
		weekCounts[w]++
	}

	// Build list of qualifying weeks.
	var qualifyingWeeks []string
	for _, w := range weeks {
		if weekCounts[w] >= requiredCount {
			qualifyingWeeks = append(qualifyingWeeks, w)
		}
	}

	if len(qualifyingWeeks) == 0 {
		return 0, 0
	}

	sort.Strings(qualifyingWeeks)

	// Calculate longest run of consecutive qualifying weeks.
	longest := 1
	run := 1
	for i := 1; i < len(qualifyingWeeks); i++ {
		if areConsecutiveWeeks(qualifyingWeeks[i-1], qualifyingWeeks[i]) {
			run++
			if run > longest {
				longest = run
			}
		} else {
			run = 1
		}
	}

	// Current streak.
	currentWeek := weekString(now)
	lastWeek := weekString(now.AddDate(0, 0, -7))
	lastQualifying := qualifyingWeeks[len(qualifyingWeeks)-1]

	if lastQualifying != currentWeek && lastQualifying != lastWeek {
		return 0, longest
	}

	currentRun := 1
	for i := len(qualifyingWeeks) - 1; i > 0; i-- {
		if areConsecutiveWeeks(qualifyingWeeks[i-1], qualifyingWeeks[i]) {
			currentRun++
		} else {
			break
		}
	}

	if currentRun > longest {
		longest = currentRun
	}

	return currentRun, longest
}

// CalculateFrequencyMetrics computes check-ins this week, this month, and 30-day rolling average.
func CalculateFrequencyMetrics(timestamps []time.Time, now time.Time) (thisWeek, thisMonth int, avgPerWeek float64) {
	weekStart := startOfWeek(now)
	monthStart := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())
	thirtyDaysAgo := now.AddDate(0, 0, -30)

	var last30Count int

	for _, ts := range timestamps {
		if !ts.Before(weekStart) {
			thisWeek++
		}
		if !ts.Before(monthStart) {
			thisMonth++
		}
		if !ts.Before(thirtyDaysAgo) {
			last30Count++
		}
	}

	// Average per week over 30 days (approximately 4.28 weeks).
	if last30Count > 0 {
		avgPerWeek = float64(last30Count) / (30.0 / 7.0)
	}

	return thisWeek, thisMonth, avgPerWeek
}

// StreakUnitForFrequency returns the streak unit string based on frequency.
func StreakUnitForFrequency(freq StreakFrequency) string {
	switch freq {
	case StreakFrequencyDaily:
		return "days"
	case StreakFrequencyWeekly, StreakFrequencyXPerWeek:
		return "weeks"
	default:
		return "days"
	}
}

// --- Helper functions ---

func uniqueDays(timestamps []time.Time) []string {
	daySet := make(map[string]struct{})
	for _, ts := range timestamps {
		daySet[dateString(ts)] = struct{}{}
	}
	days := make([]string, 0, len(daySet))
	for d := range daySet {
		days = append(days, d)
	}
	return days
}

func uniqueWeeks(timestamps []time.Time) []string {
	weekSet := make(map[string]struct{})
	for _, ts := range timestamps {
		weekSet[weekString(ts)] = struct{}{}
	}
	weeks := make([]string, 0, len(weekSet))
	for w := range weekSet {
		weeks = append(weeks, w)
	}
	return weeks
}

func dateString(t time.Time) string {
	return t.Format("2006-01-02")
}

func parseDate(s string) time.Time {
	t, _ := time.Parse("2006-01-02", s)
	return t
}

func weekString(t time.Time) string {
	year, week := t.ISOWeek()
	return time.Date(year, 1, 1, 0, 0, 0, 0, t.Location()).Format("2006") + "-W" + padWeek(week)
}

func padWeek(w int) string {
	if w < 10 {
		return "0" + string(rune('0'+w))
	}
	return string(rune('0'+w/10)) + string(rune('0'+w%10))
}

func areConsecutiveWeeks(w1, w2 string) bool {
	// Parse ISO week strings and check if they are consecutive.
	t1 := parseWeekString(w1)
	t2 := parseWeekString(w2)
	diff := t2.Sub(t1)
	return diff >= 6*24*time.Hour && diff <= 8*24*time.Hour
}

func parseWeekString(w string) time.Time {
	// Format: "YYYY-WNN"
	if len(w) < 8 {
		return time.Time{}
	}
	// Use time.Parse with a Monday in that ISO week.
	// Simple approach: parse year and week number.
	var year, week int
	n, _ := parseYearWeek(w)
	year = n / 100
	week = n % 100

	// January 4th is always in week 1 of its year (ISO 8601).
	jan4 := time.Date(year, 1, 4, 0, 0, 0, 0, time.UTC)
	// Find the Monday of week 1.
	weekday := jan4.Weekday()
	if weekday == 0 {
		weekday = 7
	}
	week1Monday := jan4.AddDate(0, 0, -int(weekday-1))
	// Add weeks.
	return week1Monday.AddDate(0, 0, (week-1)*7)
}

func parseYearWeek(w string) (int, error) {
	// "2026-W05" -> 202605
	if len(w) < 8 {
		return 0, ErrInvalidInput
	}
	year := 0
	for i := 0; i < 4; i++ {
		year = year*10 + int(w[i]-'0')
	}
	week := int(w[6]-'0')*10 + int(w[7]-'0')
	return year*100 + week, nil
}

func startOfWeek(t time.Time) time.Time {
	weekday := t.Weekday()
	if weekday == 0 {
		weekday = 7
	}
	return time.Date(t.Year(), t.Month(), t.Day()-int(weekday-1), 0, 0, 0, 0, t.Location())
}
