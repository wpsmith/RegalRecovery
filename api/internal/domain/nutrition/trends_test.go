// internal/domain/nutrition/trends_test.go
package nutrition

import (
	"testing"
	"time"
)

// TestTrends_FR_NUT_7_1_MealsPerDay verifies daily meal count calculation.
func TestTrends_FR_NUT_7_1_MealsPerDay(t *testing.T) {
	meals := []MealLog{
		{Timestamp: time.Date(2026, 3, 22, 8, 0, 0, 0, time.UTC), MealType: MealTypeBreakfast},
		{Timestamp: time.Date(2026, 3, 22, 12, 0, 0, 0, time.UTC), MealType: MealTypeLunch},
		{Timestamp: time.Date(2026, 3, 22, 18, 0, 0, 0, time.UTC), MealType: MealTypeDinner},
		{Timestamp: time.Date(2026, 3, 23, 8, 0, 0, 0, time.UTC), MealType: MealTypeBreakfast},
		{Timestamp: time.Date(2026, 3, 23, 12, 0, 0, 0, time.UTC), MealType: MealTypeLunch},
		{Timestamp: time.Date(2026, 3, 24, 18, 0, 0, 0, time.UTC), MealType: MealTypeDinner},
		{Timestamp: time.Date(2026, 3, 25, 10, 0, 0, 0, time.UTC), MealType: MealTypeSnack},
	}

	trend := CalculateMealConsistency(meals, "2026-03-22", "2026-03-28")
	if len(trend.DailyMealCounts) != 4 {
		t.Errorf("expected 4 days with data, got %d", len(trend.DailyMealCounts))
	}
	if trend.AverageMealsPerDay != 1.0 {
		t.Errorf("expected 1.0 avg meals/day (7 meals / 7 days), got %f", trend.AverageMealsPerDay)
	}
}

// TestTrends_FR_NUT_7_2_MealRegularity verifies meal type percentage calculation.
func TestTrends_FR_NUT_7_2_MealRegularity(t *testing.T) {
	meals := make([]MealLog, 0)
	// 20 days of breakfast over a 30-day period.
	for i := 0; i < 20; i++ {
		meals = append(meals, MealLog{
			Timestamp: time.Date(2026, 3, 1+i, 8, 0, 0, 0, time.UTC),
			MealType:  MealTypeBreakfast,
		})
	}

	trend := CalculateMealConsistency(meals, "2026-03-01", "2026-03-30")
	breakfastPct := trend.MealTypePercentages["breakfast"]
	// 20 days out of 30 = 66.67%.
	if breakfastPct < 66 || breakfastPct > 67 {
		t.Errorf("expected breakfast percentage ~66.7%%, got %f%%", breakfastPct)
	}
}

// TestTrends_FR_NUT_7_3_GapDetection verifies gap detection for skipped meals.
func TestTrends_FR_NUT_7_3_GapDetection(t *testing.T) {
	meals := []MealLog{
		// Only 2 breakfasts in 7 days → skipped 5/7 = 71%.
		{Timestamp: time.Date(2026, 3, 22, 8, 0, 0, 0, time.UTC), MealType: MealTypeBreakfast},
		{Timestamp: time.Date(2026, 3, 25, 8, 0, 0, 0, time.UTC), MealType: MealTypeBreakfast},
		// Lunches every day.
		{Timestamp: time.Date(2026, 3, 22, 12, 0, 0, 0, time.UTC), MealType: MealTypeLunch},
		{Timestamp: time.Date(2026, 3, 23, 12, 0, 0, 0, time.UTC), MealType: MealTypeLunch},
		{Timestamp: time.Date(2026, 3, 24, 12, 0, 0, 0, time.UTC), MealType: MealTypeLunch},
		{Timestamp: time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC), MealType: MealTypeLunch},
		{Timestamp: time.Date(2026, 3, 26, 12, 0, 0, 0, time.UTC), MealType: MealTypeLunch},
		{Timestamp: time.Date(2026, 3, 27, 12, 0, 0, 0, time.UTC), MealType: MealTypeLunch},
		{Timestamp: time.Date(2026, 3, 28, 12, 0, 0, 0, time.UTC), MealType: MealTypeLunch},
	}

	insights := DetectMealGaps(meals, 7)

	found := false
	for _, ins := range insights {
		if ins.Type == InsightTypeGapDetection {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected gap-detection insight for skipped breakfasts")
	}
}

// TestTrends_FR_NUT_8_1_MoodBeforeAfterComparison verifies mood comparison.
func TestTrends_FR_NUT_8_1_MoodBeforeAfterComparison(t *testing.T) {
	meals := make([]MealLog, 0, 15)
	for i := 0; i < 15; i++ {
		before := 2 + (i % 2)  // alternates between 2 and 3.
		after := 3 + (i % 3)   // alternates between 3, 4, 5.
		meals = append(meals, MealLog{
			MoodBefore: &before,
			MoodAfter:  &after,
		})
	}

	trend := CalculateEmotionalEatingTrend(meals)

	if trend.AverageMoodBefore == nil {
		t.Fatal("expected averageMoodBefore to be set")
	}
	if *trend.AverageMoodBefore < 2 || *trend.AverageMoodBefore > 3 {
		t.Errorf("expected averageMoodBefore ~2.5, got %f", *trend.AverageMoodBefore)
	}
	if trend.AverageMoodAfter == nil {
		t.Fatal("expected averageMoodAfter to be set")
	}
	if trend.MoodImprovementPercent == nil {
		t.Fatal("expected moodImprovementPercent to be set")
	}
}

// TestTrends_FR_NUT_8_2_MoodToMealCorrelation verifies correlation detection.
func TestTrends_FR_NUT_8_2_MoodToMealCorrelation(t *testing.T) {
	meals := make([]MealLog, 0)
	takeout := EatingContext("takeout")
	// 8 low-mood meals all with takeout context.
	for i := 0; i < 8; i++ {
		before := 1
		meals = append(meals, MealLog{
			MoodBefore:    &before,
			EatingContext: &takeout,
		})
	}

	insights := AnalyzeMoodToContextCorrelation(meals)
	if len(insights) == 0 {
		t.Error("expected correlation insight for low-mood + takeout")
	}
}

// TestMindfulness_Trend_Direction verifies mindfulness trend direction.
func TestMindfulness_Trend_Direction(t *testing.T) {
	yes := MindfulnessYes
	no := MindfulnessNo

	meals := make([]MealLog, 0, 20)
	for i := 0; i < 13; i++ {
		meals = append(meals, MealLog{MindfulnessCheck: &yes})
	}
	for i := 0; i < 7; i++ {
		meals = append(meals, MealLog{MindfulnessCheck: &no})
	}

	prevPct := 50.0
	trend := CalculateMindfulnessTrend(meals, &prevPct)

	// 65% mindful this period vs 50% last period → improving.
	if trend.MindfulPercent != 65 {
		t.Errorf("expected 65%%, got %f%%", trend.MindfulPercent)
	}
	if trend.TrendDirection == nil || *trend.TrendDirection != TrendDirectionImproving {
		t.Error("expected trend direction 'improving'")
	}
}

// TestCalendar_FR_NUT_5_2_GreenCompleteness verifies green indicator.
func TestCalendar_FR_NUT_5_2_GreenCompleteness(t *testing.T) {
	c := CalculateCompleteness(3, true, 100)
	if c != CompletenessGreen {
		t.Errorf("expected green, got %s", c)
	}
}

// TestCalendar_FR_NUT_5_3_YellowCompleteness_FewMeals verifies yellow for 1-2 meals.
func TestCalendar_FR_NUT_5_3_YellowCompleteness_FewMeals(t *testing.T) {
	c := CalculateCompleteness(2, false, 30)
	if c != CompletenessYellow {
		t.Errorf("expected yellow, got %s", c)
	}
}

// TestCalendar_FR_NUT_5_3_YellowCompleteness_PartialHydration verifies yellow for partial hydration.
func TestCalendar_FR_NUT_5_3_YellowCompleteness_PartialHydration(t *testing.T) {
	c := CalculateCompleteness(0, false, 60)
	if c != CompletenessYellow {
		t.Errorf("expected yellow, got %s", c)
	}
}

// TestCalendar_FR_NUT_5_4_GrayCompleteness verifies gray for no meals and no hydration.
func TestCalendar_FR_NUT_5_4_GrayCompleteness(t *testing.T) {
	c := CalculateCompleteness(0, false, 0)
	if c != CompletenessGray {
		t.Errorf("expected gray, got %s", c)
	}
}

// TestEDSafeguard_FR_NUT_11_1_NoCalorieFields verifies no calorie fields exist.
func TestEDSafeguard_FR_NUT_11_1_NoCalorieFields(t *testing.T) {
	if !HasNoCalorieFields() {
		t.Error("MealLog must not contain calorie fields")
	}
}

// TestEDSafeguard_FR_NUT_11_5_ConcerningPatternDetection verifies concerning pattern detection.
func TestEDSafeguard_FR_NUT_11_5_ConcerningPatternDetection(t *testing.T) {
	// 7 consecutive days with 0-1 meals.
	daily := map[string]int{
		"2026-03-22": 1,
		"2026-03-23": 0,
		"2026-03-24": 1,
		"2026-03-25": 0,
		"2026-03-26": 1,
		"2026-03-27": 0,
		"2026-03-28": 1,
	}

	pattern := DetectConcerningPattern(daily, 7)
	if !pattern.Detected {
		t.Error("expected concerning pattern to be detected")
	}
	if pattern.Message == "" {
		t.Error("expected gentle prompt message")
	}
}

// TestEDSafeguard_FR_NUT_11_6_SkippedMealsNeutral verifies skipped meals are treated neutrally.
func TestEDSafeguard_FR_NUT_11_6_SkippedMealsNeutral(t *testing.T) {
	if !IsSkippedMealNeutral(EatingContextSkipped) {
		t.Error("skipped meals should be treated neutrally")
	}
}
