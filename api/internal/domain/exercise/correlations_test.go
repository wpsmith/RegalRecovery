// internal/domain/exercise/correlations_test.go
package exercise

import (
	"testing"
)

func TestCorrelations_FR_EX_4_4_InsufficientData_ReturnsSufficientDataFalse(t *testing.T) {
	data := CorrelationData{
		TotalDataDays: 13,
	}
	result := CalculateCorrelations(data)
	if result.SufficientData {
		t.Error("expected sufficientData=false for < 14 days")
	}
	if len(result.Insights) != 0 {
		t.Errorf("expected 0 insights, got %d", len(result.Insights))
	}
}

func TestCorrelations_FR_EX_4_4_UrgeFrequency_CalculatesPercentDelta(t *testing.T) {
	data := CorrelationData{
		TotalDataDays:       30,
		ActiveDaysCount:     15,
		InactiveDaysCount:   15,
		UrgesOnActiveDays:   3,
		UrgesOnInactiveDays: 5,
	}
	result := CalculateCorrelations(data)
	if !result.SufficientData {
		t.Fatal("expected sufficientData=true")
	}

	found := false
	for _, insight := range result.Insights {
		if insight.Type == "urge-frequency" {
			found = true
			if insight.PercentDelta == nil {
				t.Fatal("expected non-nil percentDelta")
			}
			// Active rate: 3/15 = 0.2, Inactive rate: 5/15 = 0.333
			// Delta: (0.2 - 0.333) / 0.333 * 100 = -40%
			if *insight.PercentDelta > -39.0 || *insight.PercentDelta < -41.0 {
				t.Errorf("expected ~-40%% delta, got %.1f%%", *insight.PercentDelta)
			}
		}
	}
	if !found {
		t.Error("expected urge-frequency insight")
	}
}

func TestCorrelations_FR_EX_4_4_CheckInScore_CalculatesPointsDelta(t *testing.T) {
	activeAvg := 80.0
	inactiveAvg := 68.0
	data := CorrelationData{
		TotalDataDays:           30,
		ActiveDaysCount:         15,
		InactiveDaysCount:       15,
		CheckInScoreActiveAvg:   &activeAvg,
		CheckInScoreInactiveAvg: &inactiveAvg,
	}
	result := CalculateCorrelations(data)

	found := false
	for _, insight := range result.Insights {
		if insight.Type == "checkin-score" {
			found = true
			if insight.PointsDelta == nil {
				t.Fatal("expected non-nil pointsDelta")
			}
			if *insight.PointsDelta != 12.0 {
				t.Errorf("expected 12.0 points delta, got %.1f", *insight.PointsDelta)
			}
		}
	}
	if !found {
		t.Error("expected checkin-score insight")
	}
}

func TestCorrelations_FR_EX_4_4_MoodImprovement_CalculatesAverage(t *testing.T) {
	data := CorrelationData{
		TotalDataDays:   30,
		ActiveDaysCount: 10,
		MoodBeforeAfterPairs: []MoodPair{
			{Before: 3, After: 5},
			{Before: 2, After: 4},
			{Before: 3, After: 4},
		},
	}
	result := CalculateCorrelations(data)

	found := false
	for _, insight := range result.Insights {
		if insight.Type == "mood-improvement" {
			found = true
			if insight.PointsDelta == nil {
				t.Fatal("expected non-nil pointsDelta")
			}
			// Avg improvement: (2 + 2 + 1) / 3 = 1.666... -> 1.7
			if *insight.PointsDelta < 1.6 || *insight.PointsDelta > 1.8 {
				t.Errorf("expected ~1.7 points improvement, got %.1f", *insight.PointsDelta)
			}
		}
	}
	if !found {
		t.Error("expected mood-improvement insight")
	}
}

func TestCorrelations_FR_EX_4_4_InactivityRisk_CalculatesDaysSinceExercise(t *testing.T) {
	data := CorrelationData{
		TotalDataDays:         30,
		DaysSinceLastExercise: 4,
	}
	result := CalculateCorrelations(data)

	found := false
	for _, insight := range result.Insights {
		if insight.Type == "inactivity-risk" {
			found = true
			if insight.DaysSinceExercise == nil {
				t.Fatal("expected non-nil daysSinceExercise")
			}
			if *insight.DaysSinceExercise != 4 {
				t.Errorf("expected 4 days since exercise, got %d", *insight.DaysSinceExercise)
			}
		}
	}
	if !found {
		t.Error("expected inactivity-risk insight")
	}
}

func TestCorrelations_FR_EX_4_4_NoUrgeData_SkipsUrgeInsight(t *testing.T) {
	data := CorrelationData{
		TotalDataDays:   30,
		ActiveDaysCount: 0, // No active days -> no urge comparison possible
	}
	result := CalculateCorrelations(data)

	for _, insight := range result.Insights {
		if insight.Type == "urge-frequency" {
			t.Error("expected no urge-frequency insight when no active days")
		}
	}
}

func TestCorrelations_FR_EX_4_4_NoCheckInData_SkipsCheckInInsight(t *testing.T) {
	data := CorrelationData{
		TotalDataDays:   30,
		ActiveDaysCount: 10,
		// CheckInScoreActiveAvg and CheckInScoreInactiveAvg are nil
	}
	result := CalculateCorrelations(data)

	for _, insight := range result.Insights {
		if insight.Type == "checkin-score" {
			t.Error("expected no checkin-score insight when no check-in data")
		}
	}
}

func TestCorrelations_FR_EX_4_4_NoMoodData_SkipsMoodInsight(t *testing.T) {
	data := CorrelationData{
		TotalDataDays:        30,
		ActiveDaysCount:      10,
		MoodBeforeAfterPairs: nil,
	}
	result := CalculateCorrelations(data)

	for _, insight := range result.Insights {
		if insight.Type == "mood-improvement" {
			t.Error("expected no mood-improvement insight when no mood data")
		}
	}
}
