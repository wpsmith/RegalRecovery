// internal/domain/actingin/insights_test.go
package actingin

import (
	"testing"
	"time"
)

func makeCheckIn(daysAgo int, behaviors []CheckedBehavior) CheckIn {
	return CheckIn{
		CheckInID:     "aic_test",
		Timestamp:     time.Now().UTC().AddDate(0, 0, -daysAgo),
		BehaviorCount: len(behaviors),
		Behaviors:     behaviors,
	}
}

// TestInsights_AC_AIB_030_FrequencyDashboard_BarChart verifies correct counting
// of behavior occurrences sorted by frequency.
//
// AC-AIB-030: Bar chart displays each behavior's occurrence count, sorted most frequent first.
func TestInsights_AC_AIB_030_FrequencyDashboard_BarChart(t *testing.T) {
	checkIns := []CheckIn{
		makeCheckIn(1, []CheckedBehavior{
			{BehaviorID: "beh_default_stonewall", BehaviorName: "Stonewall"},
			{BehaviorID: "beh_default_avoid", BehaviorName: "Avoid"},
		}),
		makeCheckIn(2, []CheckedBehavior{
			{BehaviorID: "beh_default_stonewall", BehaviorName: "Stonewall"},
		}),
		makeCheckIn(3, []CheckedBehavior{
			{BehaviorID: "beh_default_stonewall", BehaviorName: "Stonewall"},
			{BehaviorID: "beh_default_avoid", BehaviorName: "Avoid"},
			{BehaviorID: "beh_default_hide", BehaviorName: "Hide"},
		}),
	}

	insights := CalculateFrequencyInsights(checkIns, Range7d)

	if len(insights.Behaviors) != 3 {
		t.Fatalf("expected 3 behaviors, got %d", len(insights.Behaviors))
	}

	// Most frequent first.
	if insights.Behaviors[0].BehaviorID != "beh_default_stonewall" {
		t.Errorf("expected Stonewall first, got %s", insights.Behaviors[0].BehaviorID)
	}
	if insights.Behaviors[0].Count != 3 {
		t.Errorf("expected Stonewall count 3, got %d", insights.Behaviors[0].Count)
	}
	if insights.TotalCheckIns != 3 {
		t.Errorf("expected 3 total check-ins, got %d", insights.TotalCheckIns)
	}
	if insights.TotalBehaviorsLogged != 6 {
		t.Errorf("expected 6 total behaviors logged, got %d", insights.TotalBehaviorsLogged)
	}
}

// TestInsights_AC_AIB_031_TimeRangeViews verifies that 7d, 30d, 90d ranges
// return correctly scoped data.
//
// AC-AIB-031: Time range views update to reflect selected range.
func TestInsights_AC_AIB_031_TimeRangeViews(t *testing.T) {
	checkIns := []CheckIn{
		makeCheckIn(1, []CheckedBehavior{{BehaviorID: "beh_default_blame", BehaviorName: "Blame"}}),
		makeCheckIn(10, []CheckedBehavior{{BehaviorID: "beh_default_blame", BehaviorName: "Blame"}}),
		makeCheckIn(50, []CheckedBehavior{{BehaviorID: "beh_default_blame", BehaviorName: "Blame"}}),
	}

	insights7d := CalculateFrequencyInsights(checkIns, Range7d)
	insights30d := CalculateFrequencyInsights(checkIns, Range30d)
	insights90d := CalculateFrequencyInsights(checkIns, Range90d)

	if insights7d.TotalCheckIns != 1 {
		t.Errorf("7d: expected 1 check-in, got %d", insights7d.TotalCheckIns)
	}
	if insights30d.TotalCheckIns != 2 {
		t.Errorf("30d: expected 2 check-ins, got %d", insights30d.TotalCheckIns)
	}
	if insights90d.TotalCheckIns != 3 {
		t.Errorf("90d: expected 3 check-ins, got %d", insights90d.TotalCheckIns)
	}
}

// TestInsights_AC_AIB_032_TrendArrows_Increasing verifies that a behavior with
// higher recent count shows "increasing".
//
// AC-AIB-032: Trend increasing when current > prior by > 15%.
func TestInsights_AC_AIB_032_TrendArrows_Increasing(t *testing.T) {
	trend := CalculateTrend(10, 5)
	if trend != TrendIncreasing {
		t.Errorf("expected increasing, got %s", trend)
	}
}

// TestInsights_AC_AIB_032_TrendArrows_Decreasing verifies that a behavior with
// lower recent count shows "decreasing".
//
// AC-AIB-032: Trend decreasing when current < prior by > 15%.
func TestInsights_AC_AIB_032_TrendArrows_Decreasing(t *testing.T) {
	trend := CalculateTrend(5, 10)
	if trend != TrendDecreasing {
		t.Errorf("expected decreasing, got %s", trend)
	}
}

// TestInsights_AC_AIB_032_TrendArrows_Stable verifies that similar counts show "stable".
//
// AC-AIB-032: Trend stable when current ~= prior.
func TestInsights_AC_AIB_032_TrendArrows_Stable(t *testing.T) {
	trend := CalculateTrend(10, 10)
	if trend != TrendStable {
		t.Errorf("expected stable, got %s", trend)
	}
}

// TestInsights_AC_AIB_033_TriggerAnalysis verifies that triggers are ranked
// by frequency with correct counts.
//
// AC-AIB-033: Most common triggers ranked by frequency.
func TestInsights_AC_AIB_033_TriggerAnalysis(t *testing.T) {
	checkIns := []CheckIn{
		makeCheckIn(1, []CheckedBehavior{
			{BehaviorID: "beh_default_stonewall", BehaviorName: "Stonewall", Trigger: TriggerStress},
			{BehaviorID: "beh_default_avoid", BehaviorName: "Avoid", Trigger: TriggerStress},
		}),
		makeCheckIn(2, []CheckedBehavior{
			{BehaviorID: "beh_default_blame", BehaviorName: "Blame", Trigger: TriggerConflict},
		}),
	}

	insights := CalculateTriggerInsights(checkIns, Range7d)

	if len(insights.Triggers) != 2 {
		t.Fatalf("expected 2 triggers, got %d", len(insights.Triggers))
	}
	if insights.Triggers[0].Trigger != TriggerStress {
		t.Errorf("expected stress as top trigger, got %s", insights.Triggers[0].Trigger)
	}
	if insights.Triggers[0].Count != 2 {
		t.Errorf("expected stress count 2, got %d", insights.Triggers[0].Count)
	}
}

// TestInsights_AC_AIB_033_TriggerBehaviorCorrelation verifies trigger-to-behavior
// mapping returns correct top behaviors and narrative.
//
// AC-AIB-033: Trigger-to-behavior correlations.
func TestInsights_AC_AIB_033_TriggerBehaviorCorrelation(t *testing.T) {
	checkIns := []CheckIn{
		makeCheckIn(1, []CheckedBehavior{
			{BehaviorID: "beh_default_stonewall", BehaviorName: "Stonewall", Trigger: TriggerStress},
			{BehaviorID: "beh_default_avoid", BehaviorName: "Avoid", Trigger: TriggerStress},
		}),
		makeCheckIn(2, []CheckedBehavior{
			{BehaviorID: "beh_default_stonewall", BehaviorName: "Stonewall", Trigger: TriggerStress},
		}),
	}

	insights := CalculateTriggerInsights(checkIns, Range7d)

	if len(insights.Correlations) != 1 {
		t.Fatalf("expected 1 correlation, got %d", len(insights.Correlations))
	}

	corr := insights.Correlations[0]
	if corr.Trigger != TriggerStress {
		t.Errorf("expected stress trigger correlation, got %s", corr.Trigger)
	}
	if len(corr.TopBehaviors) != 2 {
		t.Errorf("expected 2 top behaviors, got %d", len(corr.TopBehaviors))
	}
	if corr.TopBehaviors[0].BehaviorName != "Stonewall" {
		t.Errorf("expected Stonewall as top behavior, got %s", corr.TopBehaviors[0].BehaviorName)
	}
	if corr.Narrative == "" {
		t.Error("expected narrative to be non-empty")
	}
}

// TestInsights_AC_AIB_034_RelationshipImpact verifies relationship tags are
// ranked by frequency with trend lines.
//
// AC-AIB-034: Relationship impact view with trends.
func TestInsights_AC_AIB_034_RelationshipImpact(t *testing.T) {
	checkIns := []CheckIn{
		makeCheckIn(1, []CheckedBehavior{
			{BehaviorID: "beh_default_stonewall", BehaviorName: "Stonewall", RelationshipTag: RelationshipSpouse},
		}),
		makeCheckIn(2, []CheckedBehavior{
			{BehaviorID: "beh_default_avoid", BehaviorName: "Avoid", RelationshipTag: RelationshipSpouse},
		}),
		makeCheckIn(3, []CheckedBehavior{
			{BehaviorID: "beh_default_blame", BehaviorName: "Blame", RelationshipTag: RelationshipSelf},
		}),
	}

	insights := CalculateRelationshipInsights(checkIns, Range7d)

	if len(insights.Relationships) != 2 {
		t.Fatalf("expected 2 relationships, got %d", len(insights.Relationships))
	}
	if insights.Relationships[0].RelationshipTag != RelationshipSpouse {
		t.Errorf("expected spouse as most affected, got %s", insights.Relationships[0].RelationshipTag)
	}
	if insights.Relationships[0].Count != 2 {
		t.Errorf("expected spouse count 2, got %d", insights.Relationships[0].Count)
	}
}

// TestInsights_AC_AIB_035_HeatmapCalculation verifies correct day-of-week and
// hour-of-day bucketing.
//
// AC-AIB-035: Heatmap showing when acting-in behaviors are most common.
func TestInsights_AC_AIB_035_HeatmapCalculation(t *testing.T) {
	// Create check-ins at specific times.
	now := time.Now().UTC()
	checkIns := []CheckIn{
		{
			Timestamp:     now.AddDate(0, 0, -1),
			BehaviorCount: 2,
			Behaviors:     []CheckedBehavior{{BehaviorID: "a"}, {BehaviorID: "b"}},
		},
		{
			Timestamp:     now.AddDate(0, 0, -2),
			BehaviorCount: 1,
			Behaviors:     []CheckedBehavior{{BehaviorID: "a"}},
		},
	}

	heatmap := CalculateHeatmap(checkIns, Range30d, time.UTC)

	if len(heatmap.Cells) == 0 {
		t.Error("expected at least one heatmap cell")
	}

	// Verify intensity normalization.
	for _, cell := range heatmap.Cells {
		if cell.Intensity < 0 || cell.Intensity > 1 {
			t.Errorf("intensity %f out of range [0, 1]", cell.Intensity)
		}
	}
}

// TestInsights_InsufficientData_ReturnsEmpty verifies that less than 7 days of
// data returns empty insights, not an error.
func TestInsights_InsufficientData_ReturnsEmpty(t *testing.T) {
	insights := CalculateFrequencyInsights([]CheckIn{}, Range7d)

	if insights.TotalCheckIns != 0 {
		t.Errorf("expected 0 check-ins, got %d", insights.TotalCheckIns)
	}
	if len(insights.Behaviors) != 0 {
		t.Errorf("expected 0 behaviors, got %d", len(insights.Behaviors))
	}
}

// TestInsights_TrendCalculation_EqualPeriodComparison verifies that trend
// compares current period vs prior equal-length period.
func TestInsights_TrendCalculation_EqualPeriodComparison(t *testing.T) {
	// Both periods zero.
	if CalculateTrend(0, 0) != TrendStable {
		t.Error("expected stable for 0 vs 0")
	}

	// Prior zero, current non-zero.
	if CalculateTrend(5, 0) != TrendIncreasing {
		t.Error("expected increasing for 5 vs 0")
	}

	// Within 15% tolerance.
	if CalculateTrend(9, 10) != TrendStable {
		t.Error("expected stable for 9 vs 10 (within 15%)")
	}
}
