// internal/domain/exercise/stats.go
package exercise

import (
	"sort"
	"time"
)

// CalculateStats computes exercise statistics for a given period and reference date.
// currentLogs are logs within the current period; previousLogs are logs within the
// previous period of the same length (for comparison).
func CalculateStats(
	currentLogs []ExerciseLog,
	previousLogs []ExerciseLog,
	streak ExerciseStreak,
	period string,
	referenceDate string,
) ExerciseStats {
	totalMinutes := 0
	sessionCount := len(currentLogs)

	typeCount := make(map[string]int)
	typeMinutes := make(map[string]int)
	intensityCount := make(map[string]int)

	for _, log := range currentLogs {
		totalMinutes += log.DurationMinutes
		typeCount[log.ActivityType]++
		typeMinutes[log.ActivityType] += log.DurationMinutes
		if log.Intensity != nil {
			intensityCount[*log.Intensity]++
		}
	}

	// Most common activity type.
	var mostCommon *string
	maxCount := 0
	for at, count := range typeCount {
		if count > maxCount {
			maxCount = count
			t := at
			mostCommon = &t
		}
	}

	// Activity type distribution.
	activityDist := make([]ActivityTypeCount, 0, len(typeCount))
	for at, count := range typeCount {
		activityDist = append(activityDist, ActivityTypeCount{
			ActivityType: at,
			Count:        count,
			TotalMinutes: typeMinutes[at],
		})
	}
	sort.Slice(activityDist, func(i, j int) bool {
		return activityDist[i].Count > activityDist[j].Count
	})

	// Intensity distribution.
	intensityDist := make([]IntensityCount, 0, len(intensityCount))
	for intensity, count := range intensityCount {
		intensityDist = append(intensityDist, IntensityCount{
			Intensity: intensity,
			Count:     count,
		})
	}
	sort.Slice(intensityDist, func(i, j int) bool {
		return intensityDist[i].Count > intensityDist[j].Count
	})

	// Comparison to previous period.
	var comparison *PeriodComparison
	if len(previousLogs) > 0 || len(currentLogs) > 0 {
		prevMinutes := 0
		for _, log := range previousLogs {
			prevMinutes += log.DurationMinutes
		}
		prevSessions := len(previousLogs)

		minutesDelta := totalMinutes - prevMinutes
		var percentChange float64
		if prevMinutes > 0 {
			percentChange = float64(minutesDelta) / float64(prevMinutes) * 100.0
		}

		comparison = &PeriodComparison{
			ActiveMinutesDelta:         minutesDelta,
			ActiveMinutesPercentChange: percentChange,
			SessionCountDelta:          sessionCount - prevSessions,
		}
	}

	return ExerciseStats{
		Period:                   period,
		ReferenceDate:            referenceDate,
		TotalActiveMinutes:       totalMinutes,
		SessionCount:             sessionCount,
		MostCommonActivityType:   mostCommon,
		ComparisonToPrevious:     comparison,
		Streak:                   streak,
		ActivityTypeDistribution: activityDist,
		IntensityDistribution:    intensityDist,
	}
}

// PeriodDateRange returns the start and end dates for a given period and reference date.
func PeriodDateRange(period string, referenceDate time.Time) (start, end time.Time) {
	switch period {
	case "week":
		// Week starts on Monday.
		weekday := referenceDate.Weekday()
		if weekday == time.Sunday {
			weekday = 7
		}
		daysFromMonday := int(weekday) - int(time.Monday)
		start = referenceDate.AddDate(0, 0, -daysFromMonday)
		end = start.AddDate(0, 0, 6)
	case "month":
		start = time.Date(referenceDate.Year(), referenceDate.Month(), 1, 0, 0, 0, 0, referenceDate.Location())
		end = start.AddDate(0, 1, -1)
	case "90-day":
		end = referenceDate
		start = referenceDate.AddDate(0, 0, -89)
	default:
		// Default to week.
		return PeriodDateRange("week", referenceDate)
	}
	return start, end
}

// PreviousPeriodDateRange returns the start and end dates for the period before
// the given period. Used for comparison calculations.
func PreviousPeriodDateRange(period string, referenceDate time.Time) (start, end time.Time) {
	switch period {
	case "week":
		currentStart, _ := PeriodDateRange("week", referenceDate)
		end = currentStart.AddDate(0, 0, -1)
		start = end.AddDate(0, 0, -6)
	case "month":
		currentStart, _ := PeriodDateRange("month", referenceDate)
		end = currentStart.AddDate(0, 0, -1)
		start = time.Date(end.Year(), end.Month(), 1, 0, 0, 0, 0, end.Location())
	case "90-day":
		currentStart, _ := PeriodDateRange("90-day", referenceDate)
		end = currentStart.AddDate(0, 0, -1)
		start = end.AddDate(0, 0, -89)
	default:
		return PreviousPeriodDateRange("week", referenceDate)
	}
	return start, end
}
