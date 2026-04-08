// internal/domain/postmortem/validation_test.go
package postmortem

import (
	"errors"
	"strings"
	"testing"
)

// TestPostMortem_PM_AC1_2_DayBeforeSection_MoodRatingRange verifies mood rating validation.
// Acceptance Criterion (PM-AC1.2): moodRating must be 1-10.
func TestPostMortem_PM_AC1_2_DayBeforeSection_MoodRatingRange(t *testing.T) {
	tests := []struct {
		name    string
		rating  int
		wantErr bool
	}{
		{"valid min", 1, false},
		{"valid max", 10, false},
		{"valid mid", 5, false},
		{"too low", 0, true},
		{"too high", 11, true},
		{"negative", -1, true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateMoodRating(&tt.rating)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidateMoodRating(%d) error = %v, wantErr %v", tt.rating, err, tt.wantErr)
			}
			if tt.wantErr && err != nil && !errors.Is(err, ErrMoodRatingOutOfRange) {
				t.Errorf("expected ErrMoodRatingOutOfRange, got %v", err)
			}
		})
	}
}

// TestPostMortem_PM_AC1_2_DayBeforeSection_AcceptsFreeText verifies text within limit is accepted.
// Acceptance Criterion (PM-AC1.2): Free-text input max 5000 chars.
func TestPostMortem_PM_AC1_2_DayBeforeSection_AcceptsFreeText(t *testing.T) {
	text := strings.Repeat("a", 5000)
	err := ValidateTextLength(text, MaxTextLength)
	if err != nil {
		t.Errorf("expected text of exactly 5000 chars to be accepted, got error: %v", err)
	}
}

// TestPostMortem_PM_AC1_2_DayBeforeSection_RejectsExcessiveText verifies text beyond limit is rejected.
func TestPostMortem_PM_AC1_2_DayBeforeSection_RejectsExcessiveText(t *testing.T) {
	text := strings.Repeat("a", 5001)
	err := ValidateTextLength(text, MaxTextLength)
	if err == nil {
		t.Error("expected error for text exceeding 5000 chars")
	}
	if !errors.Is(err, ErrTextTooLong) {
		t.Errorf("expected ErrTextTooLong, got %v", err)
	}
}

// TestPostMortem_PM_AC1_4_ThroughoutTheDay_TimeBlockValidation verifies valid periods are accepted.
// Acceptance Criterion (PM-AC1.4): Guided time-block prompts (morning, midday, afternoon, evening).
func TestPostMortem_PM_AC1_4_ThroughoutTheDay_TimeBlockValidation(t *testing.T) {
	for _, period := range []string{"morning", "midday", "afternoon", "evening"} {
		err := ValidateTimePeriod(period)
		if err != nil {
			t.Errorf("ValidateTimePeriod(%s) unexpected error: %v", period, err)
		}
	}
}

// TestPostMortem_PM_AC1_4_ThroughoutTheDay_InvalidPeriodRejected verifies invalid periods are rejected.
func TestPostMortem_PM_AC1_4_ThroughoutTheDay_InvalidPeriodRejected(t *testing.T) {
	err := ValidateTimePeriod("night")
	if err == nil {
		t.Error("expected error for invalid period 'night'")
	}
	if !errors.Is(err, ErrInvalidTimePeriod) {
		t.Errorf("expected ErrInvalidTimePeriod, got %v", err)
	}
}

// TestPostMortem_PM_AC1_6_BuildUp_TriggerCategories verifies valid trigger categories are accepted.
// Acceptance Criterion (PM-AC1.6): Trigger categories from Urge Logging set.
func TestPostMortem_PM_AC1_6_BuildUp_TriggerCategories(t *testing.T) {
	validCategories := []string{"emotional", "environmental", "relational", "physical", "digital", "spiritual"}
	for _, cat := range validCategories {
		err := ValidateTriggerCategory(cat)
		if err != nil {
			t.Errorf("ValidateTriggerCategory(%s) unexpected error: %v", cat, err)
		}
	}
}

// TestPostMortem_PM_AC1_6_BuildUp_InvalidTriggerCategoryRejected verifies unknown categories are rejected.
func TestPostMortem_PM_AC1_6_BuildUp_InvalidTriggerCategoryRejected(t *testing.T) {
	err := ValidateTriggerCategory("financial")
	if err == nil {
		t.Error("expected error for invalid trigger category 'financial'")
	}
	if !errors.Is(err, ErrInvalidTriggerCategory) {
		t.Errorf("expected ErrInvalidTriggerCategory, got %v", err)
	}
}

// TestPostMortem_PM_AC1_7_ActingOut_DurationMinutesPositive verifies duration must be positive.
// Acceptance Criterion (PM-AC1.7): Duration in minutes.
func TestPostMortem_PM_AC1_7_ActingOut_DurationMinutesPositive(t *testing.T) {
	tests := []struct {
		name     string
		duration int
		wantErr  bool
	}{
		{"positive", 45, false},
		{"zero", 0, true},
		{"negative", -5, true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateDurationMinutes(&tt.duration)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidateDurationMinutes(%d) error = %v, wantErr %v", tt.duration, err, tt.wantErr)
			}
		})
	}
}

// TestPostMortem_PM_AC5_1_InvalidStageRejected verifies invalid FASTER stages are rejected.
// Acceptance Criterion (PM-AC5.1): Valid stages only.
func TestPostMortem_PM_AC5_1_InvalidStageRejected(t *testing.T) {
	err := ValidateFASTERStage("invalid-stage")
	if err == nil {
		t.Error("expected error for invalid FASTER stage")
	}
	if !errors.Is(err, ErrInvalidFASTERStage) {
		t.Errorf("expected ErrInvalidFASTERStage, got %v", err)
	}
}

// TestPostMortem_PM_AC5_1_StageMapping verifies valid FASTER stages are accepted.
// Acceptance Criterion (PM-AC5.1): Stage mapping to timeline.
func TestPostMortem_PM_AC5_1_StageMapping(t *testing.T) {
	stages := []string{"restoration", "forgetting-priorities", "anxiety", "speeding-up", "ticked-off", "exhausted", "relapse"}
	for _, stage := range stages {
		err := ValidateFASTERStage(stage)
		if err != nil {
			t.Errorf("ValidateFASTERStage(%s) unexpected error: %v", stage, err)
		}
	}
}

// TestPostMortem_PM_AC6_1_StructuredActionItem verifies valid action categories are accepted.
// Acceptance Criterion (PM-AC6.1): Category tagging.
func TestPostMortem_PM_AC6_1_StructuredActionItem(t *testing.T) {
	categories := []string{"spiritual", "relational", "emotional", "physical", "practical"}
	for _, cat := range categories {
		err := ValidateActionCategory(cat)
		if err != nil {
			t.Errorf("ValidateActionCategory(%s) unexpected error: %v", cat, err)
		}
	}
}

// TestPostMortem_PM_AC6_1_InvalidCategoryRejected verifies invalid action categories are rejected.
func TestPostMortem_PM_AC6_1_InvalidCategoryRejected(t *testing.T) {
	err := ValidateActionCategory("financial")
	if err == nil {
		t.Error("expected error for invalid action category 'financial'")
	}
	if !errors.Is(err, ErrInvalidActionCategory) {
		t.Errorf("expected ErrInvalidActionCategory, got %v", err)
	}
}

// TestPostMortem_PM_AC6_2_MinimumOneActionItem verifies completion requires at least 1 action item.
// Acceptance Criterion (PM-AC6.2): Minimum 1 action item.
func TestPostMortem_PM_AC6_2_MinimumOneActionItem(t *testing.T) {
	err := ValidateActionPlanCount(0)
	if err == nil {
		t.Error("expected error for 0 action items")
	}
	if !errors.Is(err, ErrActionItemLimit) {
		t.Errorf("expected ErrActionItemLimit, got %v", err)
	}
}

// TestPostMortem_PM_AC6_2_MaximumTenActionItems verifies maximum 10 action items.
func TestPostMortem_PM_AC6_2_MaximumTenActionItems(t *testing.T) {
	err := ValidateActionPlanCount(11)
	if err == nil {
		t.Error("expected error for 11 action items")
	}
	if !errors.Is(err, ErrActionItemLimit) {
		t.Errorf("expected ErrActionItemLimit, got %v", err)
	}
}

// TestPostMortem_PM_AC7_2_FullVsSummaryShare verifies valid share types.
// Acceptance Criterion (PM-AC7.2): full or summary share types.
func TestPostMortem_PM_AC7_2_FullVsSummaryShare(t *testing.T) {
	for _, st := range []string{"full", "summary"} {
		err := ValidateShareType(st)
		if err != nil {
			t.Errorf("ValidateShareType(%s) unexpected error: %v", st, err)
		}
	}
}

// TestPostMortem_PM_AC7_2_InvalidShareTypeRejected verifies invalid share types are rejected.
func TestPostMortem_PM_AC7_2_InvalidShareTypeRejected(t *testing.T) {
	err := ValidateShareType("partial")
	if err == nil {
		t.Error("expected error for invalid share type")
	}
	if !errors.Is(err, ErrInvalidShareType) {
		t.Errorf("expected ErrInvalidShareType, got %v", err)
	}
}

// TestPostMortem_PM_AC1_1_SixSectionStructure verifies the six required sections.
// Acceptance Criterion (PM-AC1.1): Six sequential sections.
func TestPostMortem_PM_AC1_1_SixSectionStructure(t *testing.T) {
	expected := []string{"dayBefore", "morning", "throughoutTheDay", "buildUp", "actingOut", "immediatelyAfter"}
	if len(AllSections) != 6 {
		t.Fatalf("expected 6 sections, got %d", len(AllSections))
	}
	for i, section := range expected {
		if AllSections[i] != section {
			t.Errorf("section[%d] = %s, want %s", i, AllSections[i], section)
		}
	}
}

// TestPostMortem_PM_AC2_3_IncompleteCannotBeCompleted verifies incomplete post-mortems fail completion.
// Acceptance Criterion (PM-AC2.3): All six sections and action plan required.
func TestPostMortem_PM_AC2_3_IncompleteCannotBeCompleted(t *testing.T) {
	pm := &PostMortemAnalysis{
		Sections: Sections{
			DayBefore: &DayBeforeSection{Text: "test"},
			Morning:   &MorningSection{Text: "test"},
			// Missing throughoutTheDay, buildUp, actingOut, immediatelyAfter.
		},
		ActionPlan: []ActionPlanItem{
			{ActionID: "ap_001", Action: "test", Category: ActionCategorySpiritual},
		},
	}

	missing, err := ValidateCompleteness(pm)
	if err == nil {
		t.Error("expected error for incomplete post-mortem")
	}
	if !errors.Is(err, ErrIncompletePostMortem) {
		t.Errorf("expected ErrIncompletePostMortem, got %v", err)
	}
	if len(missing) != 4 {
		t.Errorf("expected 4 missing sections, got %d: %v", len(missing), missing)
	}
}

// TestPostMortem_PM_AC11_2_CombinedEventType verifies combined event type is valid.
// Acceptance Criterion (PM-AC11.2): Combined analysis for multiple events.
func TestPostMortem_PM_AC11_2_CombinedEventType(t *testing.T) {
	err := ValidateEventType("combined")
	if err != nil {
		t.Errorf("expected combined event type to be valid, got error: %v", err)
	}
}

// TestPostMortem_PM_AC11_4_NearMissEventType verifies near-miss event type is valid.
// Acceptance Criterion (PM-AC11.4): Near-miss post-mortem without relapse link.
func TestPostMortem_PM_AC11_4_NearMissEventType(t *testing.T) {
	err := ValidateEventType("near-miss")
	if err != nil {
		t.Errorf("expected near-miss event type to be valid, got error: %v", err)
	}
	// No relapse ID is fine.
	err = ValidateEventTypeRelapseLink("near-miss", nil)
	if err != nil {
		t.Errorf("expected near-miss without relapseId to be valid, got error: %v", err)
	}
}

// TestPostMortem_PM_AC11_4_NearMissWithRelapseIdRejected verifies near-miss cannot link relapse.
func TestPostMortem_PM_AC11_4_NearMissWithRelapseIdRejected(t *testing.T) {
	relapseID := "r_98765"
	err := ValidateEventTypeRelapseLink("near-miss", &relapseID)
	if err == nil {
		t.Error("expected error for near-miss with relapseId")
	}
	if !errors.Is(err, ErrNearMissCannotLink) {
		t.Errorf("expected ErrNearMissCannotLink, got %v", err)
	}
}

// TestPostMortem_InvalidEventTypeRejected verifies invalid event types are rejected.
func TestPostMortem_PM_AC1_InvalidEventTypeRejected(t *testing.T) {
	err := ValidateEventType("unknown")
	if err == nil {
		t.Error("expected error for invalid event type")
	}
	if !errors.Is(err, ErrInvalidEventType) {
		t.Errorf("expected ErrInvalidEventType, got %v", err)
	}
}

// TestPostMortem_CompletedSections verifies completed sections are identified correctly.
func TestPostMortem_CompletedSections(t *testing.T) {
	sections := &Sections{
		DayBefore: &DayBeforeSection{Text: "test"},
		Morning:   &MorningSection{Text: "test"},
	}
	completed := CompletedSections(sections)
	if len(completed) != 2 {
		t.Errorf("expected 2 completed sections, got %d", len(completed))
	}
	remaining := RemainingSections(sections)
	if len(remaining) != 4 {
		t.Errorf("expected 4 remaining sections, got %d", len(remaining))
	}
}

// TestPostMortem_ValidateNilMoodRating verifies nil mood rating is accepted.
func TestPostMortem_ValidateNilMoodRating(t *testing.T) {
	err := ValidateMoodRating(nil)
	if err != nil {
		t.Errorf("expected nil mood rating to be valid, got error: %v", err)
	}
}

// TestPostMortem_ValidateSections_NilSections verifies nil sections are accepted.
func TestPostMortem_ValidateSections_NilSections(t *testing.T) {
	err := ValidateSections(nil)
	if err != nil {
		t.Errorf("expected nil sections to be valid, got error: %v", err)
	}
}

// TestPostMortem_ValidateThroughoutTheDay_WithValidBlocks verifies valid time blocks pass.
func TestPostMortem_ValidateThroughoutTheDay_WithValidBlocks(t *testing.T) {
	section := &ThroughoutTheDaySection{
		TimeBlocks: []TimeBlock{
			{Period: "morning", StartTime: "08:00", EndTime: "12:00"},
			{Period: "midday", StartTime: "12:00", EndTime: "14:00"},
			{Period: "afternoon", StartTime: "14:00", EndTime: "18:00"},
			{Period: "evening", StartTime: "18:00", EndTime: "22:00"},
		},
	}
	err := ValidateThroughoutTheDaySection(section)
	if err != nil {
		t.Errorf("expected valid time blocks to pass, got error: %v", err)
	}
}

// TestPostMortem_ValidateBuildUp_WithValidTriggers verifies valid triggers pass.
func TestPostMortem_ValidateBuildUp_WithValidTriggers(t *testing.T) {
	section := &BuildUpSection{
		Triggers: []TriggerDetail{
			{Category: "emotional", Surface: "Boredom"},
			{Category: "digital", Surface: "Phone access"},
		},
	}
	err := ValidateBuildUpSection(section)
	if err != nil {
		t.Errorf("expected valid triggers to pass, got error: %v", err)
	}
}
