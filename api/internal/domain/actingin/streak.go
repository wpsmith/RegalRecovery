// internal/domain/actingin/streak.go
package actingin

import "time"

// CalculateStreak computes the consecutive check-in count based on
// the user's frequency and their check-in history dates.
// The dates slice must be sorted in descending order (newest first).
func CalculateStreak(frequency Frequency, dates []time.Time, timezone *time.Location) int {
	if len(dates) == 0 {
		return 0
	}

	if timezone == nil {
		timezone = time.UTC
	}

	streak := 1
	switch frequency {
	case FrequencyDaily:
		return calculateDailyStreak(dates, timezone)
	case FrequencyWeekly:
		return calculateWeeklyStreak(dates, timezone)
	default:
		return streak
	}
}

// calculateDailyStreak counts consecutive days with at least one check-in.
func calculateDailyStreak(dates []time.Time, tz *time.Location) int {
	if len(dates) == 0 {
		return 0
	}

	// Normalize to date-only in user's timezone.
	daySet := make(map[string]bool)
	for _, d := range dates {
		local := d.In(tz)
		key := local.Format("2006-01-02")
		daySet[key] = true
	}

	// Start from today and walk backwards.
	today := time.Now().In(tz)
	todayKey := today.Format("2006-01-02")

	// If no check-in today, start from the most recent date.
	if !daySet[todayKey] {
		// Check if the most recent is yesterday.
		yesterday := today.AddDate(0, 0, -1).Format("2006-01-02")
		if !daySet[yesterday] {
			return 0
		}
		// Start counting from yesterday.
		today = today.AddDate(0, 0, -1)
	}

	streak := 0
	current := today
	for {
		key := current.In(tz).Format("2006-01-02")
		if !daySet[key] {
			break
		}
		streak++
		current = current.AddDate(0, 0, -1)
	}

	return streak
}

// calculateWeeklyStreak counts consecutive weeks with at least one check-in.
func calculateWeeklyStreak(dates []time.Time, tz *time.Location) int {
	if len(dates) == 0 {
		return 0
	}

	// Build a set of ISO week numbers (year-week).
	weekSet := make(map[string]bool)
	for _, d := range dates {
		local := d.In(tz)
		year, week := local.ISOWeek()
		key := weekKey(year, week)
		weekSet[key] = true
	}

	// Start from current week and walk backwards.
	now := time.Now().In(tz)
	year, week := now.ISOWeek()

	streak := 0
	for {
		key := weekKey(year, week)
		if !weekSet[key] {
			break
		}
		streak++
		// Move to previous week.
		prevDate := isoWeekToDate(year, week).AddDate(0, 0, -7)
		year, week = prevDate.ISOWeek()
	}

	return streak
}

// weekKey returns a string key for a year-week combination.
func weekKey(year, week int) string {
	return time.Date(year, 1, 1, 0, 0, 0, 0, time.UTC).Format("2006") + "-W" + padWeek(week)
}

func padWeek(w int) string {
	if w < 10 {
		return "0" + string(rune('0'+w))
	}
	return string(rune('0'+w/10)) + string(rune('0'+w%10))
}

// isoWeekToDate returns the Monday of the given ISO week.
func isoWeekToDate(year, week int) time.Time {
	// Start from January 4 of the year (always in week 1).
	jan4 := time.Date(year, 1, 4, 0, 0, 0, 0, time.UTC)
	// Find the Monday of week 1.
	weekday := jan4.Weekday()
	offset := int(time.Monday - weekday)
	if offset > 0 {
		offset -= 7
	}
	mondayW1 := jan4.AddDate(0, 0, offset)
	// Add the number of weeks.
	return mondayW1.AddDate(0, 0, (week-1)*7)
}

// RecalculateStreakOnFrequencyChange recalculates the streak when the user
// changes their check-in frequency. Historical data is preserved.
func RecalculateStreakOnFrequencyChange(newFrequency Frequency, checkInDates []time.Time, timezone *time.Location) int {
	return CalculateStreak(newFrequency, checkInDates, timezone)
}
