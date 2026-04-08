// internal/domain/postmortem/faster_mapping_test.go
package postmortem

import "testing"

// TestPostMortem_PM_AC5_2_PrePopulatedSuggestions verifies keyword-based FASTER stage suggestions.
// Acceptance Criterion (PM-AC5.2): "skipping meetings" maps to "forgetting-priorities".
func TestPostMortem_PM_AC5_2_PrePopulatedSuggestions(t *testing.T) {
	analysis := &PostMortemAnalysis{
		Sections: Sections{
			ThroughoutTheDay: &ThroughoutTheDaySection{
				TimeBlocks: []TimeBlock{
					{
						Period:    "morning",
						StartTime: "08:00",
						EndTime:   "12:00",
						Thoughts:  "I've been skipping meetings lately",
						Feelings:  "disconnected",
					},
				},
			},
		},
	}

	suggestions := SuggestFASTERStages(analysis)
	if len(suggestions) == 0 {
		t.Fatal("expected at least one suggestion")
	}

	found := false
	for _, s := range suggestions {
		if s.Stage == FASTERStageForgettingPriority {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected 'forgetting-priorities' to be suggested for 'skipping meetings'")
	}
}

// TestPostMortem_PM_AC5_2_AnxietyKeywordsSuggested verifies anxiety keywords produce suggestions.
func TestPostMortem_PM_AC5_2_AnxietyKeywordsSuggested(t *testing.T) {
	analysis := &PostMortemAnalysis{
		Sections: Sections{
			ThroughoutTheDay: &ThroughoutTheDaySection{
				TimeBlocks: []TimeBlock{
					{
						Period:    "midday",
						StartTime: "12:00",
						EndTime:   "14:00",
						Thoughts:  "Feeling anxious about the conversation",
						Feelings:  "worried and restless",
					},
				},
			},
		},
	}

	suggestions := SuggestFASTERStages(analysis)
	found := false
	for _, s := range suggestions {
		if s.Stage == FASTERStageAnxiety {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected 'anxiety' to be suggested for 'anxious' keyword")
	}
}

// TestPostMortem_PM_AC5_2_WarningSigns_DirectStageReference verifies warning signs as stage references.
func TestPostMortem_PM_AC5_2_WarningSigns_DirectStageReference(t *testing.T) {
	analysis := &PostMortemAnalysis{
		Sections: Sections{
			ThroughoutTheDay: &ThroughoutTheDaySection{
				TimeBlocks: []TimeBlock{
					{
						Period:       "afternoon",
						StartTime:    "14:00",
						EndTime:      "18:00",
						Thoughts:     "Normal day",
						WarningSigns: []string{"ticked-off", "exhausted"},
					},
				},
			},
		},
	}

	suggestions := SuggestFASTERStages(analysis)
	stages := make(map[string]bool)
	for _, s := range suggestions {
		stages[s.Stage] = true
	}

	if !stages[FASTERStageTickedOff] {
		t.Error("expected 'ticked-off' from warning signs")
	}
	if !stages[FASTERStageExhausted] {
		t.Error("expected 'exhausted' from warning signs")
	}
}

// TestPostMortem_PM_AC5_2_DayBeforeTextScanned verifies day before text is scanned.
func TestPostMortem_PM_AC5_2_DayBeforeTextScanned(t *testing.T) {
	analysis := &PostMortemAnalysis{
		Sections: Sections{
			DayBefore: &DayBeforeSection{
				Text: "I was skipping meetings and felt disconnected",
			},
		},
	}

	suggestions := SuggestFASTERStages(analysis)
	found := false
	for _, s := range suggestions {
		if s.Stage == FASTERStageForgettingPriority {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected 'forgetting-priorities' from day before text")
	}
}

// TestPostMortem_PM_AC5_2_EmptyAnalysis verifies no suggestions for empty analysis.
func TestPostMortem_PM_AC5_2_EmptyAnalysis(t *testing.T) {
	analysis := &PostMortemAnalysis{}
	suggestions := SuggestFASTERStages(analysis)
	if len(suggestions) != 0 {
		t.Errorf("expected 0 suggestions for empty analysis, got %d", len(suggestions))
	}
}
