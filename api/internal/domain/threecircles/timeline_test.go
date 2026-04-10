// internal/domain/threecircles/timeline_test.go
package threecircles

import (
	"context"
	"testing"
	"time"
)

// TestThreeCircles_Timeline_ComputesTimeline_7DayPeriod verifies timeline computation for 7-day period.
// Acceptance Criterion: Timeline supports 7d, 30d, 90d, 1y, all periods with correct date filtering.
func TestThreeCircles_Timeline_ComputesTimeline_7DayPeriod(t *testing.T) {
	t.Run("filters_entries_within_7_day_window", func(t *testing.T) {
		// Given
		engine := NewTimelineEngine()
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

		entries := []TimelineEntry{
			{Date: "2026-04-08", DominantCircle: CircleOuter, SetID: "set1"},
			{Date: "2026-04-07", DominantCircle: CircleOuter, SetID: "set2"},
			{Date: "2026-04-06", DominantCircle: CircleMiddle, SetID: "set3"},
			{Date: "2026-04-05", DominantCircle: CircleOuter, SetID: "set4"},
			{Date: "2026-04-04", DominantCircle: CircleOuter, SetID: "set5"},
			{Date: "2026-04-03", DominantCircle: CircleOuter, SetID: "set6"},
			{Date: "2026-04-02", DominantCircle: CircleOuter, SetID: "set7"}, // 7th day (04-02 to 04-08 = 7 days)
			{Date: "2026-04-01", DominantCircle: CircleMiddle, SetID: "set8"}, // Outside window
			{Date: "2026-03-31", DominantCircle: CircleOuter, SetID: "set9"},  // Outside window
			{Date: "2026-03-30", DominantCircle: CircleInner, SetID: "set10"}, // Outside window
		}

		// When
		filteredEntries, summary, err := engine.ComputeTimeline(context.Background(), entries, Period7D, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if len(filteredEntries) != 7 {
			t.Errorf("expected 7 entries in 7-day window, got %d", len(filteredEntries))
		}

		if summary.Period != "7d" {
			t.Errorf("expected period '7d', got '%s'", summary.Period)
		}

		if summary.OuterDays != 6 {
			t.Errorf("expected 6 outer days, got %d", summary.OuterDays)
		}

		if summary.MiddleDays != 1 {
			t.Errorf("expected 1 middle day, got %d", summary.MiddleDays)
		}
	})
}

// TestThreeCircles_Timeline_ComputesSummaryStats verifies summary statistics calculation.
// Acceptance Criterion: Summary includes circle distribution, consecutive outer days, framing message.
func TestThreeCircles_Timeline_ComputesSummaryStats(t *testing.T) {
	t.Run("calculates_consecutive_outer_days", func(t *testing.T) {
		// Given
		engine := NewTimelineEngine()
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

		entries := []TimelineEntry{
			{Date: "2026-04-08", DominantCircle: CircleOuter, SetID: "set1"},
			{Date: "2026-04-07", DominantCircle: CircleOuter, SetID: "set2"},
			{Date: "2026-04-06", DominantCircle: CircleOuter, SetID: "set3"},
			{Date: "2026-04-05", DominantCircle: CircleMiddle, SetID: "set4"}, // Breaks streak
			{Date: "2026-04-04", DominantCircle: CircleOuter, SetID: "set5"},
		}

		// When
		_, summary, err := engine.ComputeTimeline(context.Background(), entries, Period7D, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if summary.CurrentConsecutiveOuterDays != 3 {
			t.Errorf("expected 3 consecutive outer days, got %d", summary.CurrentConsecutiveOuterDays)
		}
	})

	t.Run("generates_descriptive_framing_message", func(t *testing.T) {
		// Given
		engine := NewTimelineEngine()
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

		entries := []TimelineEntry{
			{Date: "2026-04-08", DominantCircle: CircleOuter, SetID: "set1"},
			{Date: "2026-04-07", DominantCircle: CircleOuter, SetID: "set2"},
			{Date: "2026-04-06", DominantCircle: CircleMiddle, SetID: "set3"},
			{Date: "2026-04-05", DominantCircle: CircleInner, SetID: "set4"},
		}

		// When
		_, summary, err := engine.ComputeTimeline(context.Background(), entries, Period7D, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if summary.FramingMessage == "" {
			t.Error("expected non-empty framing message")
		}

		// Verify message is descriptive, not grading
		if len(summary.FramingMessage) < 20 {
			t.Errorf("framing message too short: %s", summary.FramingMessage)
		}

		t.Logf("Framing message: %s", summary.FramingMessage)
	})

	t.Run("counts_no_checkin_days", func(t *testing.T) {
		// Given
		engine := NewTimelineEngine()
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

		entries := []TimelineEntry{
			{Date: "2026-04-08", DominantCircle: CircleOuter, SetID: "set1", CheckinID: "checkin1"},
			{Date: "2026-04-07", DominantCircle: CircleOuter, SetID: "set2", CheckinID: ""},
			{Date: "2026-04-06", DominantCircle: CircleMiddle, SetID: "set3", CheckinID: "checkin2"},
			{Date: "2026-04-05", DominantCircle: CircleOuter, SetID: "set4", CheckinID: ""},
		}

		// When
		_, summary, err := engine.ComputeTimeline(context.Background(), entries, Period7D, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if summary.NoCheckinDays != 2 {
			t.Errorf("expected 2 no-checkin days, got %d", summary.NoCheckinDays)
		}
	})
}

// TestThreeCircles_Timeline_Handles30DayPeriod verifies 30-day period handling.
func TestThreeCircles_Timeline_Handles30DayPeriod(t *testing.T) {
	t.Run("filters_entries_within_30_day_window", func(t *testing.T) {
		// Given
		engine := NewTimelineEngine()
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

		entries := make([]TimelineEntry, 0)
		for i := 0; i < 35; i++ {
			date := currentTime.AddDate(0, 0, -i)
			entries = append(entries, TimelineEntry{
				Date:           date.Format("2006-01-02"),
				DominantCircle: CircleOuter,
				SetID:          "set",
			})
		}

		// When
		filteredEntries, summary, err := engine.ComputeTimeline(context.Background(), entries, Period30D, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if len(filteredEntries) != 30 { // 30 days total
			t.Errorf("expected 30 entries in 30-day window, got %d", len(filteredEntries))
		}

		if summary.Period != "30d" {
			t.Errorf("expected period '30d', got '%s'", summary.Period)
		}
	})
}

// TestThreeCircles_Timeline_HandlesAllPeriod verifies "all" period returns all entries.
func TestThreeCircles_Timeline_HandlesAllPeriod(t *testing.T) {
	t.Run("returns_all_entries_for_all_period", func(t *testing.T) {
		// Given
		engine := NewTimelineEngine()
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

		entries := []TimelineEntry{
			{Date: "2026-04-08", DominantCircle: CircleOuter, SetID: "set1"},
			{Date: "2025-01-01", DominantCircle: CircleOuter, SetID: "set2"},
			{Date: "2024-06-15", DominantCircle: CircleMiddle, SetID: "set3"},
		}

		// When
		filteredEntries, summary, err := engine.ComputeTimeline(context.Background(), entries, PeriodAll, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if len(filteredEntries) != 3 {
			t.Errorf("expected 3 entries for 'all' period, got %d", len(filteredEntries))
		}

		if summary.Period != "all" {
			t.Errorf("expected period 'all', got '%s'", summary.Period)
		}
	})
}

// TestThreeCircles_Timeline_RejectsInvalidPeriod verifies invalid period handling.
func TestThreeCircles_Timeline_RejectsInvalidPeriod(t *testing.T) {
	t.Run("returns_error_for_invalid_period", func(t *testing.T) {
		// Given
		engine := NewTimelineEngine()
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

		entries := []TimelineEntry{
			{Date: "2026-04-08", DominantCircle: CircleOuter, SetID: "set1"},
		}

		// When
		_, _, err := engine.ComputeTimeline(context.Background(), entries, Period("invalid"), currentTime)

		// Then
		if err != ErrInvalidPeriod {
			t.Errorf("expected ErrInvalidPeriod, got %v", err)
		}
	})
}

// TestThreeCircles_Timeline_HandlesEmptyEntries verifies empty entry handling.
func TestThreeCircles_Timeline_HandlesEmptyEntries(t *testing.T) {
	t.Run("returns_empty_summary_for_no_entries", func(t *testing.T) {
		// Given
		engine := NewTimelineEngine()
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

		// When
		filteredEntries, summary, err := engine.ComputeTimeline(context.Background(), []TimelineEntry{}, Period7D, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if len(filteredEntries) != 0 {
			t.Errorf("expected 0 entries, got %d", len(filteredEntries))
		}

		if summary.FramingMessage != "" {
			t.Errorf("expected empty framing message for no entries")
		}
	})
}

// TestThreeCircles_Timeline_Handles1YearPeriod verifies 1-year period handling.
func TestThreeCircles_Timeline_Handles1YearPeriod(t *testing.T) {
	t.Run("filters_entries_within_1_year_window", func(t *testing.T) {
		// Given
		engine := NewTimelineEngine()
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

		entries := []TimelineEntry{
			{Date: "2026-04-08", DominantCircle: CircleOuter, SetID: "set1"},
			{Date: "2025-04-09", DominantCircle: CircleOuter, SetID: "set2"},  // Within 1 year
			{Date: "2025-04-07", DominantCircle: CircleMiddle, SetID: "set3"}, // Outside 1 year
		}

		// When
		filteredEntries, summary, err := engine.ComputeTimeline(context.Background(), entries, Period1Y, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if len(filteredEntries) != 2 {
			t.Errorf("expected 2 entries in 1-year window, got %d", len(filteredEntries))
		}

		if summary.Period != "1y" {
			t.Errorf("expected period '1y', got '%s'", summary.Period)
		}
	})
}
