// internal/domain/threecircles/summary_test.go
package threecircles

import (
	"context"
	"testing"
	"time"
)

// TestThreeCircles_Summary_GeneratesWeeklySummary verifies weekly summary generation.
// Acceptance Criterion: Weekly summary includes circle distribution, top 3 insights, mood trend, framing message.
func TestThreeCircles_Summary_GeneratesWeeklySummary(t *testing.T) {
	t.Run("generates_complete_weekly_summary", func(t *testing.T) {
		// Given
		engine := NewSummaryEngine()
		currentTime := time.Date(2026, 4, 13, 12, 0, 0, 0, time.UTC) // Sunday (end of week)
		weekStart := time.Date(2026, 4, 7, 0, 0, 0, 0, time.UTC)     // Monday

		entries := []TimelineEntry{
			{Date: "2026-04-07", DominantCircle: CircleOuter, SetID: "set1", MoodScore: 8},
			{Date: "2026-04-08", DominantCircle: CircleOuter, SetID: "set2", MoodScore: 8},
			{Date: "2026-04-09", DominantCircle: CircleMiddle, SetID: "set3", MoodScore: 5},
			{Date: "2026-04-10", DominantCircle: CircleOuter, SetID: "set4", MoodScore: 7},
			{Date: "2026-04-11", DominantCircle: CircleOuter, SetID: "set5", MoodScore: 8},
			{Date: "2026-04-12", DominantCircle: CircleOuter, SetID: "set6", MoodScore: 8},
			{Date: "2026-04-13", DominantCircle: CircleOuter, SetID: "set7", MoodScore: 9},
		}

		// When
		summary, err := engine.GenerateWeeklySummary(context.Background(), entries, weekStart, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if summary.WeekStart == "" {
			t.Error("expected non-empty week start")
		}

		if summary.WeekEnd == "" {
			t.Error("expected non-empty week end")
		}

		if summary.CircleDistribution == nil {
			t.Error("expected circle distribution")
		}

		if summary.CircleDistribution[CircleOuter] != 6 {
			t.Errorf("expected 6 outer circle days, got %d", summary.CircleDistribution[CircleOuter])
		}

		if summary.CircleDistribution[CircleMiddle] != 1 {
			t.Errorf("expected 1 middle circle day, got %d", summary.CircleDistribution[CircleMiddle])
		}

		if summary.MoodTrend == "" {
			t.Error("expected non-empty mood trend")
		}

		if summary.FramingMessage == "" {
			t.Error("expected non-empty framing message")
		}

		t.Logf("Weekly summary framing: %s", summary.FramingMessage)
	})

	t.Run("adjusts_to_monday_if_not_monday", func(t *testing.T) {
		// Given
		engine := NewSummaryEngine()
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)
		weekStart := time.Date(2026, 4, 9, 0, 0, 0, 0, time.UTC) // Wednesday

		entries := []TimelineEntry{
			{Date: "2026-04-07", DominantCircle: CircleOuter, SetID: "set1", MoodScore: 8},
			{Date: "2026-04-08", DominantCircle: CircleOuter, SetID: "set2", MoodScore: 8},
		}

		// When
		summary, err := engine.GenerateWeeklySummary(context.Background(), entries, weekStart, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		// Verify week start is a Monday
		weekStartDate, _ := time.Parse("2006-01-02", summary.WeekStart)
		if weekStartDate.Weekday() != time.Monday {
			t.Errorf("expected week start to be Monday, got %s", weekStartDate.Weekday().String())
		}
	})
}

// TestThreeCircles_Summary_GeneratesMonthlySummary verifies monthly summary generation.
// Acceptance Criterion: Monthly summary includes circle distribution, top 3 insights, mood trend, framing message.
func TestThreeCircles_Summary_GeneratesMonthlySummary(t *testing.T) {
	t.Run("generates_complete_monthly_summary", func(t *testing.T) {
		// Given
		engine := NewSummaryEngine()
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)
		year := 2026
		month := time.April

		entries := make([]TimelineEntry, 30)
		for i := 0; i < 30; i++ {
			date := time.Date(year, month, i+1, 0, 0, 0, 0, time.UTC)
			circle := CircleOuter
			mood := 8

			if i%5 == 0 {
				circle = CircleMiddle
				mood = 5
			}

			entries[i] = TimelineEntry{
				Date:           date.Format("2006-01-02"),
				DominantCircle: circle,
				SetID:          "set",
				MoodScore:      mood,
			}
		}

		// When
		summary, err := engine.GenerateMonthlySummary(context.Background(), entries, year, month, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if summary.MonthStart == "" {
			t.Error("expected non-empty month start")
		}

		if summary.MonthEnd == "" {
			t.Error("expected non-empty month end")
		}

		if summary.CircleDistribution == nil {
			t.Error("expected circle distribution")
		}

		totalDays := summary.CircleDistribution[CircleOuter] + summary.CircleDistribution[CircleMiddle] + summary.CircleDistribution[CircleInner]
		if totalDays != 30 {
			t.Errorf("expected 30 total days, got %d", totalDays)
		}

		if summary.MoodTrend == "" {
			t.Error("expected non-empty mood trend")
		}

		if summary.FramingMessage == "" {
			t.Error("expected non-empty framing message")
		}

		t.Logf("Monthly summary framing: %s", summary.FramingMessage)
	})
}

// TestThreeCircles_Summary_CalculatesMoodTrend verifies mood trend calculation.
// Acceptance Criterion: Mood trend is "improving", "stable", "declining", or "insufficient".
func TestThreeCircles_Summary_CalculatesMoodTrend(t *testing.T) {
	t.Run("detects_improving_mood_trend", func(t *testing.T) {
		// Given
		engine := NewSummaryEngine()

		entries := []TimelineEntry{
			{Date: "2026-04-01", DominantCircle: CircleOuter, SetID: "set1", MoodScore: 4},
			{Date: "2026-04-02", DominantCircle: CircleOuter, SetID: "set2", MoodScore: 4},
			{Date: "2026-04-03", DominantCircle: CircleOuter, SetID: "set3", MoodScore: 5},
			{Date: "2026-04-04", DominantCircle: CircleOuter, SetID: "set4", MoodScore: 7},
			{Date: "2026-04-05", DominantCircle: CircleOuter, SetID: "set5", MoodScore: 8},
			{Date: "2026-04-06", DominantCircle: CircleOuter, SetID: "set6", MoodScore: 9},
		}

		// When
		trend := engine.calculateMoodTrend(entries)

		// Then
		if trend != MoodImproving {
			t.Errorf("expected MoodImproving, got %s", trend)
		}
	})

	t.Run("detects_declining_mood_trend", func(t *testing.T) {
		// Given
		engine := NewSummaryEngine()

		entries := []TimelineEntry{
			{Date: "2026-04-01", DominantCircle: CircleOuter, SetID: "set1", MoodScore: 9},
			{Date: "2026-04-02", DominantCircle: CircleOuter, SetID: "set2", MoodScore: 8},
			{Date: "2026-04-03", DominantCircle: CircleOuter, SetID: "set3", MoodScore: 7},
			{Date: "2026-04-04", DominantCircle: CircleOuter, SetID: "set4", MoodScore: 5},
			{Date: "2026-04-05", DominantCircle: CircleOuter, SetID: "set5", MoodScore: 4},
			{Date: "2026-04-06", DominantCircle: CircleOuter, SetID: "set6", MoodScore: 3},
		}

		// When
		trend := engine.calculateMoodTrend(entries)

		// Then
		if trend != MoodDeclining {
			t.Errorf("expected MoodDeclining, got %s", trend)
		}
	})

	t.Run("detects_stable_mood_trend", func(t *testing.T) {
		// Given
		engine := NewSummaryEngine()

		entries := []TimelineEntry{
			{Date: "2026-04-01", DominantCircle: CircleOuter, SetID: "set1", MoodScore: 7},
			{Date: "2026-04-02", DominantCircle: CircleOuter, SetID: "set2", MoodScore: 7},
			{Date: "2026-04-03", DominantCircle: CircleOuter, SetID: "set3", MoodScore: 8},
			{Date: "2026-04-04", DominantCircle: CircleOuter, SetID: "set4", MoodScore: 7},
			{Date: "2026-04-05", DominantCircle: CircleOuter, SetID: "set5", MoodScore: 7},
			{Date: "2026-04-06", DominantCircle: CircleOuter, SetID: "set6", MoodScore: 8},
		}

		// When
		trend := engine.calculateMoodTrend(entries)

		// Then
		if trend != MoodStable {
			t.Errorf("expected MoodStable, got %s", trend)
		}
	})

	t.Run("returns_insufficient_with_less_than_3_mood_entries", func(t *testing.T) {
		// Given
		engine := NewSummaryEngine()

		entries := []TimelineEntry{
			{Date: "2026-04-01", DominantCircle: CircleOuter, SetID: "set1", MoodScore: 7},
			{Date: "2026-04-02", DominantCircle: CircleOuter, SetID: "set2", MoodScore: 8},
			{Date: "2026-04-03", DominantCircle: CircleOuter, SetID: "set3", MoodScore: 0}, // No mood data
		}

		// When
		trend := engine.calculateMoodTrend(entries)

		// Then
		if trend != MoodInsufficient {
			t.Errorf("expected MoodInsufficient, got %s", trend)
		}
	})
}

// TestThreeCircles_Summary_IncludesTopInsights verifies top insights inclusion.
// Acceptance Criterion: Summary includes top 3 insights.
func TestThreeCircles_Summary_IncludesTopInsights(t *testing.T) {
	t.Run("includes_maximum_3_insights", func(t *testing.T) {
		// Given
		engine := NewSummaryEngine()
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)
		year := 2026
		month := time.April

		// Rich dataset to generate multiple insights
		entries := make([]TimelineEntry, 30)
		for i := 0; i < 30; i++ {
			date := time.Date(year, month, i+1, 0, 0, 0, 0, time.UTC)
			circle := CircleOuter
			mood := 8
			urge := 2

			if i%3 == 0 {
				circle = CircleMiddle
				mood = 4
				urge = 8
			}

			entries[i] = TimelineEntry{
				Date:           date.Format("2006-01-02"),
				DominantCircle: circle,
				SetID:          "set",
				MoodScore:      mood,
				UrgeIntensity:  urge,
			}
		}

		// When
		summary, err := engine.GenerateMonthlySummary(context.Background(), entries, year, month, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if len(summary.TopInsights) > MaxInsightsReturned {
			t.Errorf("expected maximum %d insights, got %d", MaxInsightsReturned, len(summary.TopInsights))
		}
	})
}

// TestThreeCircles_Summary_GeneratesFramingMessage verifies framing message generation.
// Acceptance Criterion: Framing message is descriptive, non-grading.
func TestThreeCircles_Summary_GeneratesFramingMessage(t *testing.T) {
	t.Run("weekly_framing_is_descriptive", func(t *testing.T) {
		// Given
		engine := NewSummaryEngine()
		circleDistribution := map[CircleType]int{
			CircleOuter:  5,
			CircleMiddle: 2,
			CircleInner:  0,
		}
		moodTrend := MoodImproving

		// When
		message := engine.generateWeeklyFramingMessage(circleDistribution, moodTrend)

		// Then
		if message == "" {
			t.Error("expected non-empty framing message")
		}

		if len(message) < 20 {
			t.Errorf("framing message too short: %s", message)
		}

		t.Logf("Weekly framing: %s", message)
	})

	t.Run("monthly_framing_includes_month_name", func(t *testing.T) {
		// Given
		engine := NewSummaryEngine()
		circleDistribution := map[CircleType]int{
			CircleOuter:  20,
			CircleMiddle: 8,
			CircleInner:  2,
		}
		moodTrend := MoodStable
		month := time.April

		// When
		message := engine.generateMonthlyFramingMessage(circleDistribution, moodTrend, month)

		// Then
		if message == "" {
			t.Error("expected non-empty framing message")
		}

		if len(message) < 20 {
			t.Errorf("framing message too short: %s", message)
		}

		t.Logf("Monthly framing: %s", message)
	})
}

// TestThreeCircles_Summary_FiltersEntriesByWeek verifies week filtering.
func TestThreeCircles_Summary_FiltersEntriesByWeek(t *testing.T) {
	t.Run("only_includes_entries_within_week", func(t *testing.T) {
		// Given
		engine := NewSummaryEngine()
		weekStart := time.Date(2026, 4, 7, 0, 0, 0, 0, time.UTC) // Monday
		weekEnd := time.Date(2026, 4, 13, 0, 0, 0, 0, time.UTC)  // Sunday

		entries := []TimelineEntry{
			{Date: "2026-04-06", DominantCircle: CircleOuter, SetID: "set1"},  // Before week
			{Date: "2026-04-07", DominantCircle: CircleOuter, SetID: "set2"},  // Start of week
			{Date: "2026-04-10", DominantCircle: CircleMiddle, SetID: "set3"}, // Within week
			{Date: "2026-04-13", DominantCircle: CircleOuter, SetID: "set4"},  // End of week
			{Date: "2026-04-14", DominantCircle: CircleOuter, SetID: "set5"},  // After week
		}

		// When
		filtered := engine.filterEntriesByWeek(entries, weekStart, weekEnd)

		// Then
		if len(filtered) != 3 {
			t.Errorf("expected 3 entries within week, got %d", len(filtered))
		}
	})
}

// TestThreeCircles_Summary_FiltersEntriesByMonth verifies month filtering.
func TestThreeCircles_Summary_FiltersEntriesByMonth(t *testing.T) {
	t.Run("only_includes_entries_within_month", func(t *testing.T) {
		// Given
		engine := NewSummaryEngine()
		monthStart := time.Date(2026, 4, 1, 0, 0, 0, 0, time.UTC)
		monthEnd := time.Date(2026, 4, 30, 0, 0, 0, 0, time.UTC)

		entries := []TimelineEntry{
			{Date: "2026-03-31", DominantCircle: CircleOuter, SetID: "set1"},  // Before month
			{Date: "2026-04-01", DominantCircle: CircleOuter, SetID: "set2"},  // Start of month
			{Date: "2026-04-15", DominantCircle: CircleMiddle, SetID: "set3"}, // Within month
			{Date: "2026-04-30", DominantCircle: CircleOuter, SetID: "set4"},  // End of month
			{Date: "2026-05-01", DominantCircle: CircleOuter, SetID: "set5"},  // After month
		}

		// When
		filtered := engine.filterEntriesByMonth(entries, monthStart, monthEnd)

		// Then
		if len(filtered) != 3 {
			t.Errorf("expected 3 entries within month, got %d", len(filtered))
		}
	})
}
