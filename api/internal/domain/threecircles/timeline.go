// internal/domain/threecircles/timeline.go
package threecircles

import (
	"context"
	"fmt"
	"time"
)

// TimelineEngine computes timeline queries and summary statistics.
type TimelineEngine struct{}

// NewTimelineEngine creates a new TimelineEngine instance.
func NewTimelineEngine() *TimelineEngine {
	return &TimelineEngine{}
}

// ComputeTimeline generates a timeline for the specified period.
// Period must be one of: 7d, 30d, 90d, 1y, all.
func (te *TimelineEngine) ComputeTimeline(
	ctx context.Context,
	entries []TimelineEntry,
	period Period,
	currentTime time.Time,
) ([]TimelineEntry, TimelineSummary, error) {
	if !period.IsValid() {
		return nil, TimelineSummary{}, ErrInvalidPeriod
	}

	if len(entries) == 0 {
		return []TimelineEntry{}, TimelineSummary{}, nil
	}

	// Calculate date range based on period
	startDate, endDate := te.calculateDateRange(period, currentTime)

	// Filter entries within date range
	filteredEntries := te.filterEntriesByDateRange(entries, startDate, endDate)

	// Compute summary statistics
	summary := te.computeSummary(filteredEntries, period, startDate, endDate)

	return filteredEntries, summary, nil
}

// calculateDateRange determines the start and end date for the given period.
func (te *TimelineEngine) calculateDateRange(period Period, currentTime time.Time) (time.Time, time.Time) {
	endDate := currentTime

	var startDate time.Time
	switch period {
	case Period7D:
		startDate = currentTime.AddDate(0, 0, -6) // 7 days total including current day
	case Period30D:
		startDate = currentTime.AddDate(0, 0, -29) // 30 days total including current day
	case Period90D:
		startDate = currentTime.AddDate(0, 0, -89) // 90 days total including current day
	case Period1Y:
		startDate = currentTime.AddDate(-1, 0, 0)
	case PeriodAll:
		startDate = time.Time{} // Zero time (beginning of time)
	}

	return startDate, endDate
}

// filterEntriesByDateRange filters entries within the specified date range.
func (te *TimelineEngine) filterEntriesByDateRange(entries []TimelineEntry, startDate, endDate time.Time) []TimelineEntry {
	filtered := make([]TimelineEntry, 0)

	for _, entry := range entries {
		entryDate, err := time.Parse("2006-01-02", entry.Date)
		if err != nil {
			continue // Skip invalid dates
		}

		// Check if entry is within range (inclusive)
		if (startDate.IsZero() || entryDate.After(startDate) || entryDate.Equal(startDate)) &&
			(entryDate.Before(endDate) || entryDate.Equal(endDate)) {
			filtered = append(filtered, entry)
		}
	}

	return filtered
}

// computeSummary calculates summary statistics for the timeline.
func (te *TimelineEngine) computeSummary(
	entries []TimelineEntry,
	period Period,
	startDate, endDate time.Time,
) TimelineSummary {
	summary := TimelineSummary{
		Period:                      string(period),
		StartDate:                   formatDate(startDate),
		EndDate:                     formatDate(endDate),
		OuterDays:                   0,
		MiddleDays:                  0,
		InnerDays:                   0,
		NoCheckinDays:               0,
		CurrentConsecutiveOuterDays: 0,
	}

	// Count circle distribution
	for _, entry := range entries {
		switch entry.DominantCircle {
		case CircleOuter:
			summary.OuterDays++
		case CircleMiddle:
			summary.MiddleDays++
		case CircleInner:
			summary.InnerDays++
		}

		if entry.CheckinID == "" {
			summary.NoCheckinDays++
		}
	}

	// Calculate current consecutive outer days (from most recent backward)
	summary.CurrentConsecutiveOuterDays = te.calculateConsecutiveOuterDays(entries)

	// Generate framing message (descriptive, no percentages)
	summary.FramingMessage = te.generateFramingMessage(summary)

	return summary
}

// calculateConsecutiveOuterDays counts consecutive outer circle days from most recent backward.
func (te *TimelineEngine) calculateConsecutiveOuterDays(entries []TimelineEntry) int {
	if len(entries) == 0 {
		return 0
	}

	// Entries are assumed to be sorted by date descending (most recent first)
	consecutiveDays := 0
	for _, entry := range entries {
		if entry.DominantCircle == CircleOuter {
			consecutiveDays++
		} else {
			break
		}
	}

	return consecutiveDays
}

// generateFramingMessage creates a descriptive, non-judgmental framing message.
func (te *TimelineEngine) generateFramingMessage(summary TimelineSummary) string {
	totalDays := summary.OuterDays + summary.MiddleDays + summary.InnerDays

	if totalDays == 0 {
		return "No Three Circles data available for this period."
	}

	// Build descriptive message
	msg := fmt.Sprintf("You logged %d outer circle days, %d middle circle days",
		summary.OuterDays, summary.MiddleDays)

	if summary.InnerDays > 0 {
		msg += fmt.Sprintf(", and %d inner circle days", summary.InnerDays)
	}

	msg += " during this period."

	if summary.CurrentConsecutiveOuterDays > 0 {
		msg += fmt.Sprintf(" You're currently on a %d-day outer circle streak.", summary.CurrentConsecutiveOuterDays)
	}

	return msg
}

// formatDate formats a time.Time to ISO 8601 date string (YYYY-MM-DD).
func formatDate(t time.Time) string {
	if t.IsZero() {
		return ""
	}
	return t.Format("2006-01-02")
}
