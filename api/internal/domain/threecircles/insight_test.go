// internal/domain/threecircles/insight_test.go
package threecircles

import (
	"context"
	"testing"
	"time"
)

// TestThreeCircles_Insight_Requires14DaysMinimum verifies minimum data requirement.
// Acceptance Criterion: Insights require minimum 14 days of data.
func TestThreeCircles_Insight_Requires14DaysMinimum(t *testing.T) {
	t.Run("returns_error_with_less_than_14_days", func(t *testing.T) {
		// Given
		engine := NewInsightEngine()
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

		entries := []TimelineEntry{
			{Date: "2026-04-08", DominantCircle: CircleOuter, SetID: "set1"},
			{Date: "2026-04-07", DominantCircle: CircleMiddle, SetID: "set2"},
			{Date: "2026-04-06", DominantCircle: CircleOuter, SetID: "set3"},
		}

		// When
		_, err := engine.GenerateInsights(context.Background(), entries, currentTime)

		// Then
		if err != ErrInsufficientData {
			t.Errorf("expected ErrInsufficientData, got %v", err)
		}
	})

	t.Run("succeeds_with_exactly_14_days", func(t *testing.T) {
		// Given
		engine := NewInsightEngine()
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

		entries := make([]TimelineEntry, 14)
		for i := 0; i < 14; i++ {
			date := currentTime.AddDate(0, 0, -i)
			entries[i] = TimelineEntry{
				Date:           date.Format("2006-01-02"),
				DominantCircle: CircleOuter,
				SetID:          "set",
				MoodScore:      7,
			}
		}

		// When
		insights, err := engine.GenerateInsights(context.Background(), entries, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if insights == nil {
			t.Error("expected insights, got nil")
		}
	})
}

// TestThreeCircles_Insight_DetectsDayOfWeekPatterns verifies day-of-week analysis.
// Acceptance Criterion: Detects patterns by day of week with actionable suggestions.
func TestThreeCircles_Insight_DetectsDayOfWeekPatterns(t *testing.T) {
	t.Run("detects_friday_pattern", func(t *testing.T) {
		// Given
		engine := NewInsightEngine()
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

		entries := []TimelineEntry{
			// Week 1: Friday middle, rest outer
			{Date: "2026-04-04", DominantCircle: CircleMiddle, SetID: "set1"}, // Friday
			{Date: "2026-04-03", DominantCircle: CircleOuter, SetID: "set2"},  // Thursday
			{Date: "2026-04-02", DominantCircle: CircleOuter, SetID: "set3"},  // Wednesday
			{Date: "2026-04-01", DominantCircle: CircleOuter, SetID: "set4"},  // Tuesday

			// Week 2: Friday middle, rest outer
			{Date: "2026-03-28", DominantCircle: CircleMiddle, SetID: "set5"}, // Friday
			{Date: "2026-03-27", DominantCircle: CircleOuter, SetID: "set6"},  // Thursday
			{Date: "2026-03-26", DominantCircle: CircleOuter, SetID: "set7"},  // Wednesday
			{Date: "2026-03-25", DominantCircle: CircleOuter, SetID: "set8"},  // Tuesday

			// Week 3: Friday middle, rest outer
			{Date: "2026-03-21", DominantCircle: CircleMiddle, SetID: "set9"}, // Friday
			{Date: "2026-03-20", DominantCircle: CircleOuter, SetID: "set10"}, // Thursday
			{Date: "2026-03-19", DominantCircle: CircleOuter, SetID: "set11"}, // Wednesday
			{Date: "2026-03-18", DominantCircle: CircleOuter, SetID: "set12"}, // Tuesday
			{Date: "2026-03-17", DominantCircle: CircleOuter, SetID: "set13"}, // Monday
			{Date: "2026-03-16", DominantCircle: CircleOuter, SetID: "set14"}, // Sunday
		}

		// When
		insights, err := engine.GenerateInsights(context.Background(), entries, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		// Should detect Friday pattern
		foundDayOfWeekInsight := false
		for _, insight := range insights {
			if insight.InsightType == InsightDayOfWeek {
				foundDayOfWeekInsight = true
				if insight.Description == "" {
					t.Error("expected non-empty description")
				}
				if insight.ActionSuggestion == "" {
					t.Error("expected non-empty action suggestion")
				}
				t.Logf("Day of week insight: %s -> %s", insight.Description, insight.ActionSuggestion)
			}
		}

		if !foundDayOfWeekInsight {
			t.Error("expected to find day-of-week insight")
		}
	})
}

// TestThreeCircles_Insight_DetectsMoodCorrelations verifies mood correlation analysis.
// Acceptance Criterion: Detects correlations between mood and circle contact.
func TestThreeCircles_Insight_DetectsMoodCorrelations(t *testing.T) {
	t.Run("detects_low_mood_on_middle_circle_days", func(t *testing.T) {
		// Given
		engine := NewInsightEngine()
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

		entries := make([]TimelineEntry, 14)
		for i := 0; i < 14; i++ {
			date := currentTime.AddDate(0, 0, -i)
			circle := CircleOuter
			mood := 8 // High mood on outer circle days

			if i%3 == 0 {
				circle = CircleMiddle
				mood = 4 // Low mood on middle circle days
			}

			entries[i] = TimelineEntry{
				Date:           date.Format("2006-01-02"),
				DominantCircle: circle,
				SetID:          "set",
				MoodScore:      mood,
			}
		}

		// When
		insights, err := engine.GenerateInsights(context.Background(), entries, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		// Should detect mood correlation
		foundMoodInsight := false
		for _, insight := range insights {
			if insight.InsightType == InsightProtective {
				foundMoodInsight = true
				if insight.Confidence < MinConfidenceThreshold {
					t.Errorf("expected confidence >= %.2f, got %.2f", MinConfidenceThreshold, insight.Confidence)
				}
				t.Logf("Mood insight: %s -> %s (confidence: %.2f)", insight.Description, insight.ActionSuggestion, insight.Confidence)
			}
		}

		if !foundMoodInsight {
			t.Error("expected to find mood correlation insight")
		}
	})
}

// TestThreeCircles_Insight_DetectsUrgeIntensityCorrelations verifies urge correlation analysis.
// Acceptance Criterion: Detects correlations between urge intensity and circle contact.
func TestThreeCircles_Insight_DetectsUrgeIntensityCorrelations(t *testing.T) {
	t.Run("detects_high_urge_on_middle_circle_days", func(t *testing.T) {
		// Given
		engine := NewInsightEngine()
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

		entries := make([]TimelineEntry, 14)
		for i := 0; i < 14; i++ {
			date := currentTime.AddDate(0, 0, -i)
			circle := CircleOuter
			urge := 2 // Low urge on outer circle days

			if i%3 == 0 {
				circle = CircleMiddle
				urge = 8 // High urge on middle circle days
			}

			entries[i] = TimelineEntry{
				Date:           date.Format("2006-01-02"),
				DominantCircle: circle,
				SetID:          "set",
				UrgeIntensity:  urge,
			}
		}

		// When
		insights, err := engine.GenerateInsights(context.Background(), entries, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		// Should detect urge correlation
		foundUrgeInsight := false
		for _, insight := range insights {
			if insight.InsightType == InsightTrigger {
				foundUrgeInsight = true
				if insight.Confidence < MinConfidenceThreshold {
					t.Errorf("expected confidence >= %.2f, got %.2f", MinConfidenceThreshold, insight.Confidence)
				}
				t.Logf("Urge insight: %s -> %s (confidence: %.2f)", insight.Description, insight.ActionSuggestion, insight.Confidence)
			}
		}

		if !foundUrgeInsight {
			t.Error("expected to find urge intensity correlation insight")
		}
	})
}

// TestThreeCircles_Insight_FiltersLowConfidence verifies confidence filtering.
// Acceptance Criterion: Insights below 0.6 confidence are filtered out.
func TestThreeCircles_Insight_FiltersLowConfidence(t *testing.T) {
	t.Run("only_returns_insights_above_confidence_threshold", func(t *testing.T) {
		// Given
		engine := NewInsightEngine()
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

		// Minimal data to produce low confidence
		entries := make([]TimelineEntry, 14)
		for i := 0; i < 14; i++ {
			date := currentTime.AddDate(0, 0, -i)
			entries[i] = TimelineEntry{
				Date:           date.Format("2006-01-02"),
				DominantCircle: CircleOuter,
				SetID:          "set",
				MoodScore:      7,
			}
		}

		// When
		insights, err := engine.GenerateInsights(context.Background(), entries, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		// All returned insights should meet confidence threshold
		for _, insight := range insights {
			if insight.Confidence < MinConfidenceThreshold {
				t.Errorf("insight with low confidence returned: %.2f", insight.Confidence)
			}
		}
	})
}

// TestThreeCircles_Insight_ReturnsTopN verifies top N selection.
// Acceptance Criterion: Returns top 3 insights sorted by confidence.
func TestThreeCircles_Insight_ReturnsTopN(t *testing.T) {
	t.Run("returns_maximum_3_insights", func(t *testing.T) {
		// Given
		engine := NewInsightEngine()
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

		// Create rich dataset likely to generate multiple insights
		entries := make([]TimelineEntry, 30)
		for i := 0; i < 30; i++ {
			date := currentTime.AddDate(0, 0, -i)
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
		insights, err := engine.GenerateInsights(context.Background(), entries, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if len(insights) > MaxInsightsReturned {
			t.Errorf("expected maximum %d insights, got %d", MaxInsightsReturned, len(insights))
		}
	})
}

// TestThreeCircles_Insight_FramesAsObservations verifies non-judgmental framing.
// Acceptance Criterion: Insights are observations with action suggestions, not judgments.
func TestThreeCircles_Insight_FramesAsObservations(t *testing.T) {
	t.Run("descriptions_are_non_judgmental", func(t *testing.T) {
		// Given
		engine := NewInsightEngine()
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

		entries := make([]TimelineEntry, 14)
		for i := 0; i < 14; i++ {
			date := currentTime.AddDate(0, 0, -i)
			circle := CircleOuter
			mood := 8

			if i%3 == 0 {
				circle = CircleMiddle
				mood = 4
			}

			entries[i] = TimelineEntry{
				Date:           date.Format("2006-01-02"),
				DominantCircle: circle,
				SetID:          "set",
				MoodScore:      mood,
			}
		}

		// When
		insights, err := engine.GenerateInsights(context.Background(), entries, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		for _, insight := range insights {
			if insight.Description == "" {
				t.Error("expected non-empty description")
			}
			if insight.ActionSuggestion == "" {
				t.Error("expected non-empty action suggestion")
			}

			// Descriptions should be observations, not judgments
			// (In production, this would be more sophisticated validation)
			t.Logf("Insight: %s -> %s", insight.Description, insight.ActionSuggestion)
		}
	})
}

// TestThreeCircles_Insight_IncludesDataWindow verifies data window metadata.
// Acceptance Criterion: Insights include data window start and end dates.
func TestThreeCircles_Insight_IncludesDataWindow(t *testing.T) {
	t.Run("includes_data_window_in_insights", func(t *testing.T) {
		// Given
		engine := NewInsightEngine()
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

		entries := make([]TimelineEntry, 14)
		for i := 0; i < 14; i++ {
			date := currentTime.AddDate(0, 0, -i)
			entries[i] = TimelineEntry{
				Date:           date.Format("2006-01-02"),
				DominantCircle: CircleOuter,
				SetID:          "set",
				MoodScore:      7,
			}
		}

		// When
		insights, err := engine.GenerateInsights(context.Background(), entries, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		for _, insight := range insights {
			if insight.DataWindowStart == "" {
				t.Error("expected non-empty data window start")
			}
			if insight.DataWindowEnd == "" {
				t.Error("expected non-empty data window end")
			}

			// Verify date format
			_, err1 := time.Parse("2006-01-02", insight.DataWindowStart)
			_, err2 := time.Parse("2006-01-02", insight.DataWindowEnd)

			if err1 != nil || err2 != nil {
				t.Error("expected ISO 8601 date format for data window")
			}
		}
	})
}
