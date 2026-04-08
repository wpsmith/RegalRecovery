// internal/domain/nutrition/meal_validator_test.go
package nutrition

import (
	"errors"
	"strings"
	"testing"
	"time"
)

// TestMealLog_FR_NUT_1_1_MealTypeRequired verifies that mealType is required.
func TestMealLog_FR_NUT_1_1_MealTypeRequired(t *testing.T) {
	req := &CreateMealLogRequest{
		Description: "Some food",
	}
	err := ValidateCreateMealLog(req)
	if err == nil {
		t.Fatal("expected validation error for missing mealType")
	}
	var ve *ValidationError
	if !errors.As(err, &ve) {
		t.Fatal("expected ValidationError type")
	}
	if ve.Code != ErrCodeMealTypeRequired {
		t.Errorf("expected error code %s, got %s", ErrCodeMealTypeRequired, ve.Code)
	}
}

// TestMealLog_FR_NUT_1_2_StandardMealTypesAccepted verifies standard meal types pass validation.
func TestMealLog_FR_NUT_1_2_StandardMealTypesAccepted(t *testing.T) {
	for _, mt := range []MealType{MealTypeBreakfast, MealTypeLunch, MealTypeDinner, MealTypeSnack} {
		req := &CreateMealLogRequest{
			MealType:    mt,
			Description: "Some food",
		}
		err := ValidateCreateMealLog(req)
		if err != nil {
			t.Errorf("unexpected validation error for mealType %s: %v", mt, err)
		}
	}
}

// TestMealLog_FR_NUT_1_2_OtherMealTypeRequiresCustomLabel verifies that mealType "other" requires customMealLabel.
func TestMealLog_FR_NUT_1_2_OtherMealTypeRequiresCustomLabel(t *testing.T) {
	req := &CreateMealLogRequest{
		MealType:    MealTypeOther,
		Description: "Some food",
	}
	err := ValidateCreateMealLog(req)
	if err == nil {
		t.Fatal("expected validation error for mealType=other without customMealLabel")
	}
	var ve *ValidationError
	if !errors.As(err, &ve) {
		t.Fatal("expected ValidationError type")
	}
	if ve.Code != ErrCodeCustomLabelRequired {
		t.Errorf("expected error code %s, got %s", ErrCodeCustomLabelRequired, ve.Code)
	}
}

// TestMealLog_FR_NUT_1_2_OtherMealTypeWithLabel verifies that mealType "other" with a label passes.
func TestMealLog_FR_NUT_1_2_OtherMealTypeWithLabel(t *testing.T) {
	label := "post-workout shake"
	req := &CreateMealLogRequest{
		MealType:        MealTypeOther,
		CustomMealLabel: &label,
		Description:     "Protein shake with banana",
	}
	err := ValidateCreateMealLog(req)
	if err != nil {
		t.Errorf("unexpected validation error: %v", err)
	}
}

// TestMealLog_FR_NUT_1_3_DescriptionRequired verifies that description is required.
func TestMealLog_FR_NUT_1_3_DescriptionRequired(t *testing.T) {
	req := &CreateMealLogRequest{
		MealType: MealTypeBreakfast,
	}
	err := ValidateCreateMealLog(req)
	if err == nil {
		t.Fatal("expected validation error for missing description")
	}
	var ve *ValidationError
	if !errors.As(err, &ve) {
		t.Fatal("expected ValidationError type")
	}
	if ve.Code != ErrCodeDescriptionRequired {
		t.Errorf("expected error code %s, got %s", ErrCodeDescriptionRequired, ve.Code)
	}
}

// TestMealLog_FR_NUT_1_4_DescriptionMaxLength verifies the 300-character limit.
func TestMealLog_FR_NUT_1_4_DescriptionMaxLength(t *testing.T) {
	req := &CreateMealLogRequest{
		MealType:    MealTypeBreakfast,
		Description: strings.Repeat("a", 301),
	}
	err := ValidateCreateMealLog(req)
	if err == nil {
		t.Fatal("expected validation error for description exceeding 300 chars")
	}
	var ve *ValidationError
	if !errors.As(err, &ve) {
		t.Fatal("expected ValidationError type")
	}
	if ve.Code != ErrCodeDescriptionTooLong {
		t.Errorf("expected error code %s, got %s", ErrCodeDescriptionTooLong, ve.Code)
	}
}

// TestMealLog_FR_NUT_1_7_EatingContextValidValues verifies eating context validation.
func TestMealLog_FR_NUT_1_7_EatingContextValidValues(t *testing.T) {
	// Valid value.
	ctx := EatingContextHomemade
	req := &CreateMealLogRequest{
		MealType:      MealTypeBreakfast,
		Description:   "Eggs",
		EatingContext: &ctx,
	}
	err := ValidateCreateMealLog(req)
	if err != nil {
		t.Errorf("unexpected error for valid eatingContext: %v", err)
	}

	// Invalid value.
	invalidCtx := EatingContext("invalid_value")
	req.EatingContext = &invalidCtx
	err = ValidateCreateMealLog(req)
	if err == nil {
		t.Fatal("expected validation error for invalid eatingContext")
	}
}

// TestMealLog_FR_NUT_1_8_MoodBeforeRange verifies moodBefore must be 1-5.
func TestMealLog_FR_NUT_1_8_MoodBeforeRange(t *testing.T) {
	tests := []struct {
		name    string
		mood    int
		wantErr bool
	}{
		{"too low (0)", 0, true},
		{"too high (6)", 6, true},
		{"valid (3)", 3, false},
		{"valid min (1)", 1, false},
		{"valid max (5)", 5, false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := &CreateMealLogRequest{
				MealType:    MealTypeBreakfast,
				Description: "Eggs",
				MoodBefore:  &tt.mood,
			}
			err := ValidateCreateMealLog(req)
			if tt.wantErr && err == nil {
				t.Error("expected validation error")
			}
			if !tt.wantErr && err != nil {
				t.Errorf("unexpected validation error: %v", err)
			}
		})
	}
}

// TestMealLog_FR_NUT_1_9_MoodAfterRange verifies moodAfter must be 1-5.
func TestMealLog_FR_NUT_1_9_MoodAfterRange(t *testing.T) {
	// Invalid.
	mood := 0
	req := &CreateMealLogRequest{
		MealType:    MealTypeBreakfast,
		Description: "Eggs",
		MoodAfter:   &mood,
	}
	err := ValidateCreateMealLog(req)
	if err == nil {
		t.Fatal("expected validation error for moodAfter=0")
	}

	// Valid.
	mood = 5
	req.MoodAfter = &mood
	err = ValidateCreateMealLog(req)
	if err != nil {
		t.Errorf("unexpected error for moodAfter=5: %v", err)
	}
}

// TestMealLog_FR_NUT_1_10_MindfulnessCheckValues verifies valid mindfulness check values.
func TestMealLog_FR_NUT_1_10_MindfulnessCheckValues(t *testing.T) {
	// Valid.
	mc := MindfulnessYes
	req := &CreateMealLogRequest{
		MealType:         MealTypeBreakfast,
		Description:      "Eggs",
		MindfulnessCheck: &mc,
	}
	err := ValidateCreateMealLog(req)
	if err != nil {
		t.Errorf("unexpected error for mindfulnessCheck=yes: %v", err)
	}

	// Invalid.
	invalid := MindfulnessCheck("invalid")
	req.MindfulnessCheck = &invalid
	err = ValidateCreateMealLog(req)
	if err == nil {
		t.Fatal("expected validation error for invalid mindfulnessCheck")
	}
}

// TestMealLog_FR_NUT_1_11_NotesMaxLength verifies the 500-character notes limit.
func TestMealLog_FR_NUT_1_11_NotesMaxLength(t *testing.T) {
	longNotes := strings.Repeat("n", 501)
	req := &CreateMealLogRequest{
		MealType:    MealTypeBreakfast,
		Description: "Eggs",
		Notes:       &longNotes,
	}
	err := ValidateCreateMealLog(req)
	if err == nil {
		t.Fatal("expected validation error for notes exceeding 500 chars")
	}
}

// TestMealLog_FR_NUT_1_13_MinimalValidEntry verifies that only mealType and description are needed.
func TestMealLog_FR_NUT_1_13_MinimalValidEntry(t *testing.T) {
	req := &CreateMealLogRequest{
		MealType:    MealTypeLunch,
		Description: "Sandwich",
	}
	err := ValidateCreateMealLog(req)
	if err != nil {
		t.Errorf("unexpected validation error for minimal entry: %v", err)
	}
}

// TestMealLog_FR_NUT_1_14_TimestampImmutable verifies timestamp cannot be changed on update.
func TestMealLog_FR_NUT_1_14_TimestampImmutable(t *testing.T) {
	ts := time.Now()
	req := &UpdateMealLogRequest{
		Timestamp: &ts,
	}
	err := ValidateUpdateMealLog(req)
	if err == nil {
		t.Fatal("expected validation error for timestamp in update request")
	}
	var ve *ValidationError
	if !errors.As(err, &ve) {
		t.Fatal("expected ValidationError type")
	}
	if ve.Code != ErrCodeTimestampImmutable {
		t.Errorf("expected error code %s, got %s", ErrCodeTimestampImmutable, ve.Code)
	}
}

// TestMealLog_FR_NUT_1_14_OtherFieldsUpdatable verifies non-timestamp fields can be updated.
func TestMealLog_FR_NUT_1_14_OtherFieldsUpdatable(t *testing.T) {
	desc := "Updated meal"
	notes := "New notes"
	req := &UpdateMealLogRequest{
		Description: &desc,
		Notes:       &notes,
	}
	err := ValidateUpdateMealLog(req)
	if err != nil {
		t.Errorf("unexpected validation error for updating description and notes: %v", err)
	}
}

// TestQuickLog_FR_NUT_2_1_OnlyMealTypeRequired verifies quick log only needs mealType.
func TestQuickLog_FR_NUT_2_1_OnlyMealTypeRequired(t *testing.T) {
	req := &CreateQuickMealLogRequest{
		MealType: MealTypeBreakfast,
	}
	err := ValidateQuickMealLog(req)
	if err != nil {
		t.Errorf("unexpected validation error for quick log: %v", err)
	}
}

// TestHydrationLog_ValidateAction verifies hydration log action validation.
func TestHydrationLog_ValidateAction(t *testing.T) {
	// Valid add.
	req := &LogHydrationRequest{Action: HydrationActionAdd, Servings: 1}
	if err := ValidateHydrationLog(req); err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Valid remove.
	req = &LogHydrationRequest{Action: HydrationActionRemove, Servings: 1}
	if err := ValidateHydrationLog(req); err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Invalid action.
	req = &LogHydrationRequest{Action: "invalid", Servings: 1}
	if err := ValidateHydrationLog(req); err == nil {
		t.Fatal("expected validation error for invalid action")
	}

	// Invalid servings (0).
	req = &LogHydrationRequest{Action: HydrationActionAdd, Servings: 0}
	if err := ValidateHydrationLog(req); err == nil {
		t.Fatal("expected validation error for servings=0")
	}

	// Invalid servings (11).
	req = &LogHydrationRequest{Action: HydrationActionAdd, Servings: 11}
	if err := ValidateHydrationLog(req); err == nil {
		t.Fatal("expected validation error for servings=11")
	}
}
