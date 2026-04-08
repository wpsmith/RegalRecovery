// internal/domain/postmortem/insights_test.go
package postmortem

import (
	"testing"
	"time"
)

// TestPostMortem_PM_AC8_3_CommonTriggers verifies triggers are ranked by frequency.
// Acceptance Criterion (PM-AC8.3): Common triggers across all post-mortems.
func TestPostMortem_PM_AC8_3_CommonTriggers(t *testing.T) {
	analyses := []*PostMortemAnalysis{
		{TriggerSummary: []string{"emotional", "digital"}},
		{TriggerSummary: []string{"digital", "relational"}},
		{TriggerSummary: []string{"digital", "emotional", "physical"}},
	}

	insights := ComputeInsights(analyses)
	if insights.TotalAnalyses != 3 {
		t.Errorf("expected 3 analyses, got %d", insights.TotalAnalyses)
	}
	if len(insights.CommonTriggers) == 0 {
		t.Fatal("expected common triggers")
	}
	// Digital appears in all 3.
	if insights.CommonTriggers[0].Category != "digital" {
		t.Errorf("expected 'digital' as most common trigger, got '%s'", insights.CommonTriggers[0].Category)
	}
	if insights.CommonTriggers[0].Frequency != 3 {
		t.Errorf("expected frequency 3 for digital, got %d", insights.CommonTriggers[0].Frequency)
	}
	if insights.CommonTriggers[0].Percentage != 100.0 {
		t.Errorf("expected 100%% for digital, got %.1f%%", insights.CommonTriggers[0].Percentage)
	}
}

// TestPostMortem_PM_AC8_4_FasterStageAtPointOfNoReturn verifies FASTER stage analysis.
// Acceptance Criterion (PM-AC8.4): Most frequent stage at point of no return.
func TestPostMortem_PM_AC8_4_FasterStageAtPointOfNoReturn(t *testing.T) {
	analyses := []*PostMortemAnalysis{
		{FasterMapping: []FasterMappingEntry{
			{TimeOfDay: "08:00", Stage: "forgetting-priorities"},
			{TimeOfDay: "18:00", Stage: "exhausted"},
			{TimeOfDay: "22:00", Stage: "relapse"},
		}},
		{FasterMapping: []FasterMappingEntry{
			{TimeOfDay: "12:00", Stage: "anxiety"},
			{TimeOfDay: "20:00", Stage: "exhausted"},
			{TimeOfDay: "23:00", Stage: "relapse"},
		}},
		{FasterMapping: []FasterMappingEntry{
			{TimeOfDay: "10:00", Stage: "anxiety"},
			{TimeOfDay: "16:00", Stage: "ticked-off"},
			{TimeOfDay: "21:00", Stage: "relapse"},
		}},
	}

	insights := ComputeInsights(analyses)
	if insights.CommonFasterStageAtBreak == nil {
		t.Fatal("expected FASTER stage at break point")
	}
	// exhausted appears 2x before relapse, ticked-off 1x.
	if insights.CommonFasterStageAtBreak.Stage != "exhausted" {
		t.Errorf("expected 'exhausted' as most common stage before relapse, got '%s'", insights.CommonFasterStageAtBreak.Stage)
	}
	if insights.CommonFasterStageAtBreak.Frequency != 2 {
		t.Errorf("expected frequency 2, got %d", insights.CommonFasterStageAtBreak.Frequency)
	}
}

// TestPostMortem_PM_AC8_5_CommonTimeOfDay verifies time of day analysis.
// Acceptance Criterion (PM-AC8.5): Most common time of day for acting out.
func TestPostMortem_PM_AC8_5_CommonTimeOfDay(t *testing.T) {
	dur := 30
	analyses := []*PostMortemAnalysis{
		{
			Timestamp: time.Date(2026, 3, 28, 22, 0, 0, 0, time.UTC),
			Sections:  Sections{ActingOut: &ActingOutSection{Description: "test", DurationMinutes: &dur}},
			FasterMapping: []FasterMappingEntry{
				{TimeOfDay: "22:00", Stage: "relapse"},
			},
		},
		{
			Timestamp: time.Date(2026, 3, 20, 21, 0, 0, 0, time.UTC),
			Sections:  Sections{ActingOut: &ActingOutSection{Description: "test", DurationMinutes: &dur}},
			FasterMapping: []FasterMappingEntry{
				{TimeOfDay: "21:00", Stage: "relapse"},
			},
		},
		{
			Timestamp: time.Date(2026, 3, 15, 14, 0, 0, 0, time.UTC),
			Sections:  Sections{ActingOut: &ActingOutSection{Description: "test", DurationMinutes: &dur}},
			FasterMapping: []FasterMappingEntry{
				{TimeOfDay: "14:00", Stage: "relapse"},
			},
		},
	}

	insights := ComputeInsights(analyses)
	if insights.CommonTimeOfDay == nil {
		t.Fatal("expected common time of day")
	}
	// 22:00 and 21:00 are both evening, 14:00 is afternoon.
	if insights.CommonTimeOfDay.Period != "evening" {
		t.Errorf("expected 'evening' as most common period, got '%s'", insights.CommonTimeOfDay.Period)
	}
	if insights.CommonTimeOfDay.Frequency != 2 {
		t.Errorf("expected frequency 2 for evening, got %d", insights.CommonTimeOfDay.Frequency)
	}
}

// TestPostMortem_PM_AC8_6_RecurringDecisionPoints verifies decision point theme identification.
// Acceptance Criterion (PM-AC8.6): Recurring missed decision points.
func TestPostMortem_PM_AC8_6_RecurringDecisionPoints(t *testing.T) {
	analyses := []*PostMortemAnalysis{
		{Sections: Sections{BuildUp: &BuildUpSection{DecisionPoints: []DecisionPoint{
			{CouldHaveDone: "Called my sponsor", InsteadDid: "Kept scrolling"},
			{CouldHaveDone: "Gone to bed early", InsteadDid: "Stayed up late"},
		}}}},
		{Sections: Sections{BuildUp: &BuildUpSection{DecisionPoints: []DecisionPoint{
			{CouldHaveDone: "Called my sponsor", InsteadDid: "Ignored the feeling"},
		}}}},
		{Sections: Sections{BuildUp: &BuildUpSection{DecisionPoints: []DecisionPoint{
			{CouldHaveDone: "Put the phone away", InsteadDid: "Kept browsing"},
			{CouldHaveDone: "called my sponsor", InsteadDid: "Pretended I was fine"},
		}}}},
	}

	insights := ComputeInsights(analyses)
	if len(insights.RecurringDecisionPoints) == 0 {
		t.Fatal("expected recurring decision points")
	}

	found := false
	for _, dp := range insights.RecurringDecisionPoints {
		if dp.Theme == "called my sponsor" && dp.Frequency >= 3 {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected 'called my sponsor' theme with frequency >= 3")
	}
}

// TestPostMortem_Insights_InsufficientData verifies insufficient data handling.
func TestPostMortem_Insights_InsufficientData(t *testing.T) {
	analyses := []*PostMortemAnalysis{
		{TriggerSummary: []string{"emotional"}},
	}

	insights := ComputeInsights(analyses)
	if insights.TotalAnalyses != 1 {
		t.Errorf("expected 1 analysis, got %d", insights.TotalAnalyses)
	}
	if len(insights.CommonTriggers) != 0 {
		t.Error("expected no triggers for insufficient data")
	}
}

// TestPostMortem_Insights_DeepTriggerPatterns verifies deep trigger pattern detection.
func TestPostMortem_Insights_DeepTriggerPatterns(t *testing.T) {
	underlying := "Loneliness"
	coreWound := "Fear of being unlovable"

	analyses := []*PostMortemAnalysis{
		{TriggerSummary: []string{"emotional"}, TriggerDetails: []TriggerDetail{
			{Category: "emotional", Surface: "Boredom", Underlying: &underlying, CoreWound: &coreWound},
		}},
		{TriggerSummary: []string{"emotional"}, TriggerDetails: []TriggerDetail{
			{Category: "emotional", Surface: "Boredom", Underlying: &underlying, CoreWound: &coreWound},
		}},
		{TriggerSummary: []string{"digital"}, TriggerDetails: []TriggerDetail{
			{Category: "digital", Surface: "Phone access"},
		}},
	}

	insights := ComputeInsights(analyses)
	if len(insights.DeepTriggerPatterns) == 0 {
		t.Fatal("expected deep trigger patterns")
	}
	if insights.DeepTriggerPatterns[0].Surface != "Boredom" {
		t.Errorf("expected 'Boredom' pattern, got '%s'", insights.DeepTriggerPatterns[0].Surface)
	}
}
