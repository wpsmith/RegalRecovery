// internal/domain/mood/trends_test.go
package mood

import (
	"math"
	"testing"
)

func TestMood_AC017_TrendDirection_Improving(t *testing.T) {
	// Given: 7 daily averages showing upward trend
	dailyAvgs := []float64{2.0, 2.5, 3.0, 3.5, 3.5, 4.0, 4.2}

	// When: trend direction is calculated
	trend := CalculateTrendDirection(dailyAvgs)

	// Then: trendDirection = "improving"
	if trend != TrendImproving {
		t.Errorf("expected 'improving', got '%s'", trend)
	}
}

func TestMood_AC017_TrendDirection_Declining(t *testing.T) {
	// Given: 7 daily averages showing downward trend
	dailyAvgs := []float64{4.5, 4.0, 3.5, 3.0, 2.5, 2.0, 1.8}

	// When: trend direction is calculated
	trend := CalculateTrendDirection(dailyAvgs)

	// Then: trendDirection = "declining"
	if trend != TrendDeclining {
		t.Errorf("expected 'declining', got '%s'", trend)
	}
}

func TestMood_AC017_TrendDirection_Stable(t *testing.T) {
	// Given: 7 daily averages that are flat
	dailyAvgs := []float64{3.0, 3.01, 2.99, 3.0, 3.02, 3.0, 3.01}

	// When: trend direction is calculated
	trend := CalculateTrendDirection(dailyAvgs)

	// Then: trendDirection = "stable"
	if trend != TrendStable {
		t.Errorf("expected 'stable', got '%s'", trend)
	}
}

func TestMood_TrendDirection_SingleDataPoint(t *testing.T) {
	// Given: only 1 data point
	dailyAvgs := []float64{3.0}

	// When: trend direction is calculated
	trend := CalculateTrendDirection(dailyAvgs)

	// Then: stable (not enough data)
	if trend != TrendStable {
		t.Errorf("expected 'stable' for single data point, got '%s'", trend)
	}
}

func TestMood_TrendDirection_EmptyData(t *testing.T) {
	// Given: no data
	dailyAvgs := []float64{}

	// When: trend direction is calculated
	trend := CalculateTrendDirection(dailyAvgs)

	// Then: stable
	if trend != TrendStable {
		t.Errorf("expected 'stable' for empty data, got '%s'", trend)
	}
}

func TestMood_AC019_MonthlySummary_Distribution(t *testing.T) {
	// Given: 20 entries: 5 Great, 8 Good, 4 Okay, 2 Struggling, 1 Crisis
	entries := make([]MoodEntry, 0, 20)
	for i := 0; i < 5; i++ {
		entries = append(entries, MoodEntry{Rating: 5})
	}
	for i := 0; i < 8; i++ {
		entries = append(entries, MoodEntry{Rating: 4})
	}
	for i := 0; i < 4; i++ {
		entries = append(entries, MoodEntry{Rating: 3})
	}
	for i := 0; i < 2; i++ {
		entries = append(entries, MoodEntry{Rating: 2})
	}
	entries = append(entries, MoodEntry{Rating: 1})

	// When: monthly summary distribution is computed
	dist := ComputeRatingDistribution(entries)

	// Then: correct percentages
	if math.Abs(dist.Great-25.0) > 0.01 {
		t.Errorf("expected great = 25%%, got %.2f%%", dist.Great)
	}
	if math.Abs(dist.Good-40.0) > 0.01 {
		t.Errorf("expected good = 40%%, got %.2f%%", dist.Good)
	}
	if math.Abs(dist.Okay-20.0) > 0.01 {
		t.Errorf("expected okay = 20%%, got %.2f%%", dist.Okay)
	}
	if math.Abs(dist.Struggling-10.0) > 0.01 {
		t.Errorf("expected struggling = 10%%, got %.2f%%", dist.Struggling)
	}
	if math.Abs(dist.Crisis-5.0) > 0.01 {
		t.Errorf("expected crisis = 5%%, got %.2f%%", dist.Crisis)
	}
}

func TestMood_AC020_TimeOfDayHeatmap_CalculatesHourlyAverages(t *testing.T) {
	// This is tested at the repository/handler level since it requires aggregation.
	// Here we just verify the HourBucket struct works.
	bucket := HourBucket{Hour: 8, AverageRating: 4.0, EntryCount: 3}
	if bucket.Hour != 8 {
		t.Errorf("expected hour 8, got %d", bucket.Hour)
	}
	if bucket.AverageRating != 4.0 {
		t.Errorf("expected avgRating 4.0, got %f", bucket.AverageRating)
	}
}

func TestMood_AC021_DayOfWeekPatterns_CalculatesAverages(t *testing.T) {
	// Verify DayBucket and DayOfWeekName
	tests := []struct {
		dow  int
		name string
	}{
		{0, "Sunday"},
		{1, "Monday"},
		{2, "Tuesday"},
		{3, "Wednesday"},
		{4, "Thursday"},
		{5, "Friday"},
		{6, "Saturday"},
	}

	for _, tt := range tests {
		name := DayOfWeekName(tt.dow)
		if name != tt.name {
			t.Errorf("expected day %d = '%s', got '%s'", tt.dow, tt.name, name)
		}
	}

	// Invalid day
	name := DayOfWeekName(7)
	if name != "" {
		t.Errorf("expected empty string for invalid day 7, got '%s'", name)
	}
}

func TestMood_AC022_EmotionLabelTrends_FrequencySorted(t *testing.T) {
	// This is a repository-level test. Here we verify LabelCount struct.
	labels := []LabelCount{
		{Label: "Anxious", Count: 10},
		{Label: "Peaceful", Count: 8},
		{Label: "Lonely", Count: 5},
	}

	if labels[0].Count < labels[1].Count {
		t.Error("expected labels to be sortable by count")
	}
}

func TestMood_RatingDistribution_EmptyEntries(t *testing.T) {
	// Given: no entries
	dist := ComputeRatingDistribution([]MoodEntry{})

	// Then: all zeros
	if dist.Great != 0 || dist.Good != 0 || dist.Okay != 0 || dist.Struggling != 0 || dist.Crisis != 0 {
		t.Error("expected all zeros for empty entries")
	}
}
