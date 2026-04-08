// internal/domain/prayer/streak.go
package prayer

import (
	"sort"
	"time"
)

// CalculatePrayerStreak computes prayer streak data from a list of session timestamps.
// Timestamps should be the prayer session timestamps (not createdAt).
// The userLocation is used for timezone-aware day boundary calculation (PR-AC5, timezone handling).
func CalculatePrayerStreak(timestamps []time.Time, now time.Time, userLocation *time.Location) *PrayerStats {
	if userLocation == nil {
		userLocation = time.UTC
	}

	if len(timestamps) == 0 {
		return &PrayerStats{
			CurrentStreakDays:      0,
			LongestStreakDays:      0,
			TotalPrayerDays:       0,
			SessionsThisWeek:      0,
			AverageDurationMinutes: nil,
			TypeDistribution:      defaultTypeDistribution(),
			MoodImpact:            nil,
		}
	}

	// Normalize all timestamps to the user's local date (day only).
	daySet := make(map[string]bool)
	for _, ts := range timestamps {
		localDate := ts.In(userLocation).Format("2006-01-02")
		daySet[localDate] = true
	}

	// Sort unique days in descending order.
	days := make([]string, 0, len(daySet))
	for d := range daySet {
		days = append(days, d)
	}
	sort.Sort(sort.Reverse(sort.StringSlice(days)))

	// PR-AC5.5: Total prayer days = distinct days.
	totalPrayerDays := len(days)

	// PR-AC5.1: Calculate current streak (consecutive days from today backwards).
	today := now.In(userLocation).Format("2006-01-02")
	currentStreak := calculateCurrentStreak(days, today, userLocation)

	// PR-AC5.3: Calculate longest streak ever.
	longestStreak := calculateLongestStreak(days, userLocation)

	// PR-AC5.3: Longest streak is at least the current streak.
	if currentStreak > longestStreak {
		longestStreak = currentStreak
	}

	// Calculate sessions this week.
	weekStart := startOfWeek(now, userLocation)
	sessionsThisWeek := 0
	for _, ts := range timestamps {
		if !ts.Before(weekStart) {
			sessionsThisWeek++
		}
	}

	return &PrayerStats{
		CurrentStreakDays: currentStreak,
		LongestStreakDays: longestStreak,
		TotalPrayerDays:  totalPrayerDays,
		SessionsThisWeek: sessionsThisWeek,
		TypeDistribution: defaultTypeDistribution(),
	}
}

// calculateCurrentStreak counts consecutive days with prayer from today backwards.
// PR-AC5.1: Streak starts from today (or yesterday if no prayer today yet).
func calculateCurrentStreak(sortedDaysDesc []string, today string, loc *time.Location) int {
	if len(sortedDaysDesc) == 0 {
		return 0
	}

	// Check if user has prayed today or yesterday (streak includes today or starts from yesterday).
	yesterday := parseDate(today, loc).AddDate(0, 0, -1).Format("2006-01-02")

	startDay := ""
	if sortedDaysDesc[0] == today {
		startDay = today
	} else if sortedDaysDesc[0] == yesterday {
		startDay = yesterday
	} else {
		// No prayer today or yesterday -- streak is broken.
		return 0
	}

	daySetForLookup := make(map[string]bool, len(sortedDaysDesc))
	for _, d := range sortedDaysDesc {
		daySetForLookup[d] = true
	}

	streak := 0
	current := parseDate(startDay, loc)
	for {
		dateStr := current.Format("2006-01-02")
		if !daySetForLookup[dateStr] {
			break
		}
		streak++
		current = current.AddDate(0, 0, -1)
	}

	return streak
}

// calculateLongestStreak finds the longest consecutive-day run in all prayer history.
func calculateLongestStreak(sortedDaysDesc []string, loc *time.Location) int {
	if len(sortedDaysDesc) == 0 {
		return 0
	}

	// Sort ascending for forward scanning.
	ascending := make([]string, len(sortedDaysDesc))
	copy(ascending, sortedDaysDesc)
	sort.Strings(ascending)

	longest := 1
	current := 1
	for i := 1; i < len(ascending); i++ {
		prevDate := parseDate(ascending[i-1], loc)
		currDate := parseDate(ascending[i], loc)
		diff := currDate.Sub(prevDate).Hours() / 24
		if diff == 1 {
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

// CalculateTypeDistribution counts sessions per prayer type.
// PR-AC5.6: Type distribution contains a count per prayer type.
func CalculateTypeDistribution(sessions []PrayerSession) map[string]int {
	dist := defaultTypeDistribution()
	for _, s := range sessions {
		dist[s.PrayerType]++
	}
	return dist
}

// CalculateAverageDuration computes average duration across sessions with non-nil duration.
func CalculateAverageDuration(sessions []PrayerSession) *float64 {
	total := 0
	count := 0
	for _, s := range sessions {
		if s.DurationMinutes != nil {
			total += *s.DurationMinutes
			count++
		}
	}
	if count == 0 {
		return nil
	}
	avg := float64(total) / float64(count)
	return &avg
}

// CalculateMoodImpact computes average mood before and after across sessions.
func CalculateMoodImpact(sessions []PrayerSession) *MoodImpact {
	var totalBefore, totalAfter float64
	var countBefore, countAfter int

	for _, s := range sessions {
		if s.MoodBefore != nil {
			totalBefore += float64(*s.MoodBefore)
			countBefore++
		}
		if s.MoodAfter != nil {
			totalAfter += float64(*s.MoodAfter)
			countAfter++
		}
	}

	if countBefore == 0 && countAfter == 0 {
		return nil
	}

	impact := &MoodImpact{}
	if countBefore > 0 {
		avg := totalBefore / float64(countBefore)
		impact.AverageMoodBefore = &avg
	}
	if countAfter > 0 {
		avg := totalAfter / float64(countAfter)
		impact.AverageMoodAfter = &avg
	}
	return impact
}

// CalculateFullStats computes full PrayerStats from a list of sessions.
func CalculateFullStats(sessions []PrayerSession, now time.Time, userLocation *time.Location) *PrayerStats {
	timestamps := make([]time.Time, len(sessions))
	for i, s := range sessions {
		timestamps[i] = s.Timestamp
	}

	stats := CalculatePrayerStreak(timestamps, now, userLocation)
	stats.TypeDistribution = CalculateTypeDistribution(sessions)
	stats.AverageDurationMinutes = CalculateAverageDuration(sessions)
	stats.MoodImpact = CalculateMoodImpact(sessions)

	return stats
}

// TimeOfDay classifies a timestamp into morning/midday/evening/lateNight.
func TimeOfDay(ts time.Time, loc *time.Location) string {
	hour := ts.In(loc).Hour()
	switch {
	case hour >= 5 && hour < 12:
		return "morning"
	case hour >= 12 && hour < 17:
		return "midday"
	case hour >= 17 && hour < 21:
		return "evening"
	default:
		return "lateNight"
	}
}

// defaultTypeDistribution returns a map with all prayer types set to 0.
func defaultTypeDistribution() map[string]int {
	return map[string]int{
		PrayerTypePersonal:       0,
		PrayerTypeGuided:         0,
		PrayerTypeGroup:          0,
		PrayerTypeScriptureBased: 0,
		PrayerTypeIntercessory:   0,
		PrayerTypeListening:      0,
	}
}

// parseDate parses a "2006-01-02" date string in the given location.
func parseDate(dateStr string, loc *time.Location) time.Time {
	t, _ := time.ParseInLocation("2006-01-02", dateStr, loc)
	return t
}

// startOfWeek returns the start of the ISO week (Monday) for the given time.
func startOfWeek(t time.Time, loc *time.Location) time.Time {
	local := t.In(loc)
	weekday := local.Weekday()
	if weekday == time.Sunday {
		weekday = 7
	}
	daysBack := int(weekday) - int(time.Monday)
	start := local.AddDate(0, 0, -daysBack)
	return time.Date(start.Year(), start.Month(), start.Day(), 0, 0, 0, 0, loc)
}
