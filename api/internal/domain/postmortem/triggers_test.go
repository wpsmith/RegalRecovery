// internal/domain/postmortem/triggers_test.go
package postmortem

import (
	"testing"
	"time"
)

// TestPostMortem_PM_AC4_1_QuickSelectTriggers verifies trigger category set.
// Acceptance Criterion (PM-AC4.1): Six categories from Urge Logging.
func TestPostMortem_PM_AC4_1_QuickSelectTriggers(t *testing.T) {
	expected := []string{"emotional", "environmental", "relational", "physical", "digital", "spiritual"}
	for _, cat := range expected {
		if !ValidTriggerCategories[cat] {
			t.Errorf("expected '%s' to be a valid trigger category", cat)
		}
	}
	if len(ValidTriggerCategories) != 6 {
		t.Errorf("expected exactly 6 trigger categories, got %d", len(ValidTriggerCategories))
	}
}

// TestPostMortem_PM_AC4_2_DeepTriggerExploration verifies three-layer trigger storage.
// Acceptance Criterion (PM-AC4.2): Surface -> Underlying -> Core Wound.
func TestPostMortem_PM_AC4_2_DeepTriggerExploration(t *testing.T) {
	underlying := "Loneliness"
	coreWound := "Fear of being unlovable"
	trigger := TriggerDetail{
		Category:   "emotional",
		Surface:    "Boredom",
		Underlying: &underlying,
		CoreWound:  &coreWound,
	}

	err := ValidateTriggerExploration(trigger)
	if err != nil {
		t.Errorf("expected valid three-layer trigger, got error: %v", err)
	}
}

// TestPostMortem_PM_AC4_2_DeepTriggerExploration_PartialLayers verifies partial exploration is OK.
func TestPostMortem_PM_AC4_2_DeepTriggerExploration_PartialLayers(t *testing.T) {
	trigger := TriggerDetail{
		Category:   "digital",
		Surface:    "Phone access",
		Underlying: nil,
		CoreWound:  nil,
	}

	err := ValidateTriggerExploration(trigger)
	if err != nil {
		t.Errorf("expected partial trigger exploration to be valid, got error: %v", err)
	}
}

// TestPostMortem_ExtractTriggerSummary verifies trigger summary extraction.
func TestPostMortem_ExtractTriggerSummary(t *testing.T) {
	details := []TriggerDetail{
		{Category: "emotional", Surface: "Boredom"},
		{Category: "digital", Surface: "Phone access"},
		{Category: "emotional", Surface: "Loneliness"}, // Duplicate category.
	}

	summary := ExtractTriggerSummary(details)
	if len(summary) != 2 {
		t.Errorf("expected 2 unique categories, got %d: %v", len(summary), summary)
	}
}

// TestPostMortem_PM_AC4_3_CrossAnalysisPatternLinking verifies cross-analysis trigger matching.
// Acceptance Criterion (PM-AC4.3): "This trigger also appeared in your post-mortem from [date]."
func TestPostMortem_PM_AC4_3_CrossAnalysisPatternLinking(t *testing.T) {
	current := []TriggerDetail{
		{Category: "digital", Surface: "Unrestricted phone access"},
	}

	previous := []*PostMortemAnalysis{
		{
			Timestamp: time.Date(2026, 3, 15, 0, 0, 0, 0, time.UTC),
			TriggerDetails: []TriggerDetail{
				{Category: "digital", Surface: "Unrestricted phone access"},
			},
		},
		{
			Timestamp: time.Date(2026, 3, 20, 0, 0, 0, 0, time.UTC),
			TriggerDetails: []TriggerDetail{
				{Category: "emotional", Surface: "Stress"},
			},
		},
	}

	matches := FindMatchingTriggers(current, previous)
	if len(matches) == 0 {
		t.Fatal("expected at least one trigger match")
	}

	dates, found := matches["unrestricted phone access"]
	if !found {
		t.Fatal("expected 'unrestricted phone access' match")
	}
	if len(dates) != 1 || dates[0] != "2026-03-15" {
		t.Errorf("expected match on 2026-03-15, got: %v", dates)
	}
}

// TestPostMortem_MatchTriggerPattern verifies pattern matching.
func TestPostMortem_MatchTriggerPattern(t *testing.T) {
	current := TriggerDetail{Category: "emotional", Surface: "Boredom"}
	previous := TriggerDetail{Category: "emotional", Surface: "boredom"}

	if !MatchTriggerPattern(current, previous) {
		t.Error("expected case-insensitive match")
	}

	different := TriggerDetail{Category: "digital", Surface: "Boredom"}
	if MatchTriggerPattern(current, different) {
		t.Error("expected no match for different categories")
	}
}
