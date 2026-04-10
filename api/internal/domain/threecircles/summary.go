// internal/domain/threecircles/summary.go
package threecircles

import (
	"context"
	"fmt"
	"time"
)

// SummaryEngine generates weekly and monthly summaries of Three Circles data.
type SummaryEngine struct {
	insightEngine *InsightEngine
}

// NewSummaryEngine creates a new SummaryEngine instance.
func NewSummaryEngine() *SummaryEngine {
	return &SummaryEngine{
		insightEngine: NewInsightEngine(),
	}
}

// GenerateWeeklySummary creates a weekly summary for the specified week.
// weekStart should be a Monday (ISO 8601 week start).
func (se *SummaryEngine) GenerateWeeklySummary(
	ctx context.Context,
	entries []TimelineEntry,
	weekStart time.Time,
	currentTime time.Time,
) (WeeklySummary, error) {
	// Ensure weekStart is a Monday
	if weekStart.Weekday() != time.Monday {
		weekStart = se.getMonday(weekStart)
	}

	weekEnd := weekStart.AddDate(0, 0, 6) // Sunday

	// Filter entries for the week
	weekEntries := se.filterEntriesByWeek(entries, weekStart, weekEnd)

	// Calculate circle distribution
	circleDistribution := se.calculateCircleDistribution(weekEntries)

	// Generate insights for the week
	insights, _ := se.insightEngine.GenerateInsights(ctx, weekEntries, currentTime)
	topInsights := se.insightEngine.selectTopInsights(insights, MaxInsightsReturned)

	// Calculate mood trend
	moodTrend := se.calculateMoodTrend(weekEntries)

	// Generate framing message
	framingMessage := se.generateWeeklyFramingMessage(circleDistribution, moodTrend)

	summary := WeeklySummary{
		WeekStart:          formatDate(weekStart),
		WeekEnd:            formatDate(weekEnd),
		CircleDistribution: circleDistribution,
		TopInsights:        topInsights,
		MoodTrend:          string(moodTrend),
		FramingMessage:     framingMessage,
	}

	return summary, nil
}

// GenerateMonthlySummary creates a monthly summary for the specified month.
func (se *SummaryEngine) GenerateMonthlySummary(
	ctx context.Context,
	entries []TimelineEntry,
	year int,
	month time.Month,
	currentTime time.Time,
) (MonthlySummary, error) {
	// Calculate month boundaries
	monthStart := time.Date(year, month, 1, 0, 0, 0, 0, time.UTC)
	monthEnd := monthStart.AddDate(0, 1, -1) // Last day of month

	// Filter entries for the month
	monthEntries := se.filterEntriesByMonth(entries, monthStart, monthEnd)

	// Calculate circle distribution
	circleDistribution := se.calculateCircleDistribution(monthEntries)

	// Generate insights for the month
	insights, _ := se.insightEngine.GenerateInsights(ctx, monthEntries, currentTime)
	topInsights := se.insightEngine.selectTopInsights(insights, MaxInsightsReturned)

	// Calculate mood trend
	moodTrend := se.calculateMoodTrend(monthEntries)

	// Generate framing message
	framingMessage := se.generateMonthlyFramingMessage(circleDistribution, moodTrend, month)

	summary := MonthlySummary{
		MonthStart:         formatDate(monthStart),
		MonthEnd:           formatDate(monthEnd),
		CircleDistribution: circleDistribution,
		TopInsights:        topInsights,
		MoodTrend:          string(moodTrend),
		FramingMessage:     framingMessage,
	}

	return summary, nil
}

// getMonday returns the Monday of the week containing the given date.
func (se *SummaryEngine) getMonday(date time.Time) time.Time {
	offset := int(time.Monday - date.Weekday())
	if offset > 0 {
		offset = -6 // Go to previous Monday
	}
	return date.AddDate(0, 0, offset)
}

// filterEntriesByWeek filters entries within the specified week.
func (se *SummaryEngine) filterEntriesByWeek(entries []TimelineEntry, weekStart, weekEnd time.Time) []TimelineEntry {
	filtered := make([]TimelineEntry, 0)

	for _, entry := range entries {
		entryDate, err := time.Parse("2006-01-02", entry.Date)
		if err != nil {
			continue
		}

		if (entryDate.Equal(weekStart) || entryDate.After(weekStart)) &&
			(entryDate.Equal(weekEnd) || entryDate.Before(weekEnd)) {
			filtered = append(filtered, entry)
		}
	}

	return filtered
}

// filterEntriesByMonth filters entries within the specified month.
func (se *SummaryEngine) filterEntriesByMonth(entries []TimelineEntry, monthStart, monthEnd time.Time) []TimelineEntry {
	filtered := make([]TimelineEntry, 0)

	for _, entry := range entries {
		entryDate, err := time.Parse("2006-01-02", entry.Date)
		if err != nil {
			continue
		}

		if (entryDate.Equal(monthStart) || entryDate.After(monthStart)) &&
			(entryDate.Equal(monthEnd) || entryDate.Before(monthEnd)) {
			filtered = append(filtered, entry)
		}
	}

	return filtered
}

// calculateCircleDistribution counts entries per circle type.
func (se *SummaryEngine) calculateCircleDistribution(entries []TimelineEntry) map[CircleType]int {
	distribution := make(map[CircleType]int)
	distribution[CircleInner] = 0
	distribution[CircleMiddle] = 0
	distribution[CircleOuter] = 0

	for _, entry := range entries {
		if entry.DominantCircle.IsValid() {
			distribution[entry.DominantCircle]++
		}
	}

	return distribution
}

// calculateMoodTrend determines the mood trend for the period.
func (se *SummaryEngine) calculateMoodTrend(entries []TimelineEntry) MoodTrend {
	moodEntries := make([]struct {
		date  time.Time
		score int
	}, 0)

	for _, entry := range entries {
		if entry.MoodScore == 0 {
			continue // No mood data
		}

		date, err := time.Parse("2006-01-02", entry.Date)
		if err != nil {
			continue
		}

		moodEntries = append(moodEntries, struct {
			date  time.Time
			score int
		}{date: date, score: entry.MoodScore})
	}

	if len(moodEntries) < 3 {
		return MoodInsufficient
	}

	// Sort by date ascending
	for i := 0; i < len(moodEntries)-1; i++ {
		for j := i + 1; j < len(moodEntries); j++ {
			if moodEntries[i].date.After(moodEntries[j].date) {
				moodEntries[i], moodEntries[j] = moodEntries[j], moodEntries[i]
			}
		}
	}

	// Calculate trend: compare first half average vs. second half average
	midpoint := len(moodEntries) / 2
	firstHalfSum := 0
	secondHalfSum := 0

	for i := 0; i < midpoint; i++ {
		firstHalfSum += moodEntries[i].score
	}
	for i := midpoint; i < len(moodEntries); i++ {
		secondHalfSum += moodEntries[i].score
	}

	firstHalfAvg := float64(firstHalfSum) / float64(midpoint)
	secondHalfAvg := float64(secondHalfSum) / float64(len(moodEntries)-midpoint)

	diff := secondHalfAvg - firstHalfAvg

	if diff > 1.0 {
		return MoodImproving
	} else if diff < -1.0 {
		return MoodDeclining
	}

	return MoodStable
}

// generateWeeklyFramingMessage creates a weekly framing message.
func (se *SummaryEngine) generateWeeklyFramingMessage(circleDistribution map[CircleType]int, moodTrend MoodTrend) string {
	outerDays := circleDistribution[CircleOuter]
	middleDays := circleDistribution[CircleMiddle]
	innerDays := circleDistribution[CircleInner]

	msg := fmt.Sprintf("This week you logged %d outer circle days", outerDays)

	if middleDays > 0 {
		msg += fmt.Sprintf(", %d middle circle days", middleDays)
	}

	if innerDays > 0 {
		msg += fmt.Sprintf(", and %d inner circle days", innerDays)
	}

	msg += ". "

	switch moodTrend {
	case MoodImproving:
		msg += "Your mood has been improving."
	case MoodStable:
		msg += "Your mood has been stable."
	case MoodDeclining:
		msg += "Your mood has been declining—consider reaching out to support."
	case MoodInsufficient:
		msg += "Not enough mood data to determine trend."
	}

	return msg
}

// generateMonthlyFramingMessage creates a monthly framing message.
func (se *SummaryEngine) generateMonthlyFramingMessage(circleDistribution map[CircleType]int, moodTrend MoodTrend, month time.Month) string {
	outerDays := circleDistribution[CircleOuter]
	middleDays := circleDistribution[CircleMiddle]
	innerDays := circleDistribution[CircleInner]

	msg := fmt.Sprintf("In %s you logged %d outer circle days", month.String(), outerDays)

	if middleDays > 0 {
		msg += fmt.Sprintf(", %d middle circle days", middleDays)
	}

	if innerDays > 0 {
		msg += fmt.Sprintf(", and %d inner circle days", innerDays)
	}

	msg += ". "

	switch moodTrend {
	case MoodImproving:
		msg += "Your overall mood trend is improving."
	case MoodStable:
		msg += "Your overall mood has been stable."
	case MoodDeclining:
		msg += "Your overall mood trend is declining—this might be a good time to check in with your support network."
	case MoodInsufficient:
		msg += "Not enough mood data to determine trend."
	}

	return msg
}
