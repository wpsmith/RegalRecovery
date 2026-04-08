// internal/domain/exercise/correlations.go
package exercise

import (
	"fmt"
	"math"
	"time"
)

// MinCorrelationDataDays is the minimum number of days of combined data required.
const MinCorrelationDataDays = 14

// CorrelationData holds the raw data needed to compute correlation insights.
type CorrelationData struct {
	ExerciseDates          []time.Time // all exercise log timestamps
	UrgesOnActiveDays      int         // urge count on days with exercise
	UrgesOnInactiveDays    int         // urge count on days without exercise
	ActiveDaysCount        int         // number of days with exercise
	InactiveDaysCount      int         // number of days without exercise
	CheckInScoreActiveAvg  *float64    // average check-in score on active days
	CheckInScoreInactiveAvg *float64   // average check-in score on inactive days
	MoodBeforeAfterPairs   []MoodPair  // mood before/after pairs from exercise logs
	DaysSinceLastExercise  int         // days since last exercise
	TotalDataDays          int         // total days of data
}

// MoodPair holds a before/after mood pair from an exercise log.
type MoodPair struct {
	Before int
	After  int
}

// CalculateCorrelations computes correlation insights from the given data.
func CalculateCorrelations(data CorrelationData) CorrelationInsights {
	if data.TotalDataDays < MinCorrelationDataDays {
		return CorrelationInsights{
			SufficientData: false,
			Insights:       nil,
		}
	}

	insights := make([]Insight, 0, 4)

	// Urge frequency insight.
	if data.ActiveDaysCount > 0 && data.InactiveDaysCount > 0 {
		urgeRateActive := float64(data.UrgesOnActiveDays) / float64(data.ActiveDaysCount)
		urgeRateInactive := float64(data.UrgesOnInactiveDays) / float64(data.InactiveDaysCount)

		if urgeRateInactive > 0 {
			percentDelta := ((urgeRateActive - urgeRateInactive) / urgeRateInactive) * 100.0
			percentDelta = math.Round(percentDelta*10) / 10

			var message string
			if percentDelta < 0 {
				message = fmt.Sprintf("On days you exercise, your urge frequency is %.0f%% lower", math.Abs(percentDelta))
			} else {
				message = fmt.Sprintf("On days you exercise, your urge frequency is %.0f%% higher", percentDelta)
			}

			insights = append(insights, Insight{
				Type:         "urge-frequency",
				Message:      message,
				PercentDelta: &percentDelta,
			})
		}
	}

	// Check-in score insight.
	if data.CheckInScoreActiveAvg != nil && data.CheckInScoreInactiveAvg != nil {
		delta := *data.CheckInScoreActiveAvg - *data.CheckInScoreInactiveAvg
		delta = math.Round(delta*10) / 10

		message := fmt.Sprintf("Your average check-in score is %.0f points higher on active days", delta)
		insights = append(insights, Insight{
			Type:        "checkin-score",
			Message:     message,
			PointsDelta: &delta,
		})
	}

	// Mood improvement insight.
	if len(data.MoodBeforeAfterPairs) > 0 {
		totalDelta := 0.0
		for _, pair := range data.MoodBeforeAfterPairs {
			totalDelta += float64(pair.After - pair.Before)
		}
		avgImprovement := totalDelta / float64(len(data.MoodBeforeAfterPairs))
		avgImprovement = math.Round(avgImprovement*10) / 10

		message := fmt.Sprintf("Your post-exercise mood averages %.1f points higher than pre-exercise", avgImprovement)
		insights = append(insights, Insight{
			Type:        "mood-improvement",
			Message:     message,
			PointsDelta: &avgImprovement,
		})
	}

	// Inactivity risk insight.
	if data.DaysSinceLastExercise > 0 {
		message := fmt.Sprintf("You haven't exercised in %d days -- your last 3 relapses followed similar gaps", data.DaysSinceLastExercise)
		insights = append(insights, Insight{
			Type:              "inactivity-risk",
			Message:           message,
			DaysSinceExercise: &data.DaysSinceLastExercise,
		})
	}

	return CorrelationInsights{
		SufficientData: true,
		Insights:       insights,
	}
}
