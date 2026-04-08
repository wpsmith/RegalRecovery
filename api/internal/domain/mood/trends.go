// internal/domain/mood/trends.go
package mood

import "math"

// TrendDirection represents the overall mood trend direction.
type TrendDirection string

const (
	TrendImproving TrendDirection = "improving"
	TrendStable    TrendDirection = "stable"
	TrendDeclining TrendDirection = "declining"
)

// TrendSlopeThreshold is the minimum absolute slope to consider a trend
// non-stable. A slope magnitude below this is classified as "stable."
const TrendSlopeThreshold = 0.05

// HourBucket holds aggregated mood data for a single hour.
type HourBucket struct {
	Hour          int     `json:"hour"`
	AverageRating float64 `json:"averageRating"`
	EntryCount    int     `json:"entryCount"`
}

// DayBucket holds aggregated mood data for a day of the week.
type DayBucket struct {
	DayOfWeek     int     `json:"dayOfWeek"`
	DayName       string  `json:"dayName"`
	AverageRating float64 `json:"averageRating"`
}

// LabelCount holds the frequency count for an emotion label.
type LabelCount struct {
	Label            string  `json:"label"`
	Count            int     `json:"count"`
	PercentageChange float64 `json:"percentageChange"`
}

// WeeklySummary holds aggregated data for a week.
type WeeklySummary struct {
	AverageThisWeek  float64  `json:"averageThisWeek"`
	AverageLastWeek  float64  `json:"averageLastWeek"`
	BestDay          string   `json:"bestDay"`
	MostChallengingDay string `json:"mostChallengingDay"`
	TopEmotionLabels []string `json:"topEmotionLabels"`
	EntryCount       int      `json:"entryCount"`
}

// MonthlySummary holds aggregated data for a month.
type MonthlySummary struct {
	AverageThisMonth      float64             `json:"averageThisMonth"`
	Distribution          RatingDistribution  `json:"distribution"`
	ComparedToPreviousMonth float64           `json:"comparedToPreviousMonth"`
}

// RatingDistribution holds the percentage breakdown by rating.
type RatingDistribution struct {
	Great      float64 `json:"great"`
	Good       float64 `json:"good"`
	Okay       float64 `json:"okay"`
	Struggling float64 `json:"struggling"`
	Crisis     float64 `json:"crisis"`
}

// DailyAverage holds the average and count for a single date.
type DailyAverage struct {
	Date          string  `json:"date"`
	AverageRating float64 `json:"averageRating"`
	EntryCount    int     `json:"entryCount"`
}

// CalculateTrendDirection computes the trend direction from daily averages using
// simple linear regression. The dailyAverages should be in chronological order
// (oldest first).
func CalculateTrendDirection(dailyAverages []float64) TrendDirection {
	n := len(dailyAverages)
	if n < 2 {
		return TrendStable
	}

	// Simple linear regression: y = mx + b
	// x is the day index (0, 1, 2, ...), y is the daily average.
	sumX := 0.0
	sumY := 0.0
	sumXY := 0.0
	sumX2 := 0.0

	for i, y := range dailyAverages {
		x := float64(i)
		sumX += x
		sumY += y
		sumXY += x * y
		sumX2 += x * x
	}

	nf := float64(n)
	denominator := nf*sumX2 - sumX*sumX
	if denominator == 0 {
		return TrendStable
	}

	slope := (nf*sumXY - sumX*sumY) / denominator

	if math.Abs(slope) < TrendSlopeThreshold {
		return TrendStable
	}
	if slope > 0 {
		return TrendImproving
	}
	return TrendDeclining
}

// ComputeRatingDistribution computes the percentage breakdown by rating.
func ComputeRatingDistribution(entries []MoodEntry) RatingDistribution {
	if len(entries) == 0 {
		return RatingDistribution{}
	}

	counts := map[int]int{1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
	for _, e := range entries {
		counts[e.Rating]++
	}

	total := float64(len(entries))
	return RatingDistribution{
		Great:      float64(counts[5]) / total * 100,
		Good:       float64(counts[4]) / total * 100,
		Okay:       float64(counts[3]) / total * 100,
		Struggling: float64(counts[2]) / total * 100,
		Crisis:     float64(counts[1]) / total * 100,
	}
}

// DayOfWeekName maps a day-of-week integer to its name (0=Sunday).
func DayOfWeekName(dow int) string {
	names := []string{"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}
	if dow < 0 || dow > 6 {
		return ""
	}
	return names[dow]
}
