// test/unit/affirmation_validation_test.go
package unit

import (
	"strings"
	"testing"

	"github.com/regalrecovery/api/internal/domain/affirmation"
)

// TestAffirmation_AFF_DM_AC1_AffirmationStructure verifies that a fully populated
// affirmation passes validation.
//
// Acceptance Criterion (AFF-DM-AC1): Each affirmation must contain statement,
// scriptureReference, category, and level.
func TestAffirmation_AFF_DM_AC1_AffirmationStructure(t *testing.T) {
	a := &affirmation.Affirmation{
		Statement:    "I am fearfully and wonderfully made.",
		ScriptureRef: "Psalm 139:14",
		Category:     affirmation.CategoryIdentity,
		Level:        1,
	}
	if err := affirmation.ValidateAffirmation(a); err != nil {
		t.Errorf("expected valid affirmation, got error: %v", err)
	}
}

// TestAffirmation_AFF_DM_AC1_AffirmationStructure_MissingStatement verifies that
// an affirmation with an empty statement fails validation.
func TestAffirmation_AFF_DM_AC1_AffirmationStructure_MissingStatement(t *testing.T) {
	a := &affirmation.Affirmation{
		Statement:    "",
		ScriptureRef: "Psalm 139:14",
		Category:     affirmation.CategoryIdentity,
		Level:        1,
	}
	err := affirmation.ValidateAffirmation(a)
	if err == nil {
		t.Error("expected validation error for empty statement, got nil")
	}
}

// TestAffirmation_AFF_DM_AC2_StatementMaxLength verifies that a statement
// at exactly 500 characters passes validation.
func TestAffirmation_AFF_DM_AC2_StatementMaxLength(t *testing.T) {
	a := &affirmation.Affirmation{
		Statement:    strings.Repeat("a", 500),
		ScriptureRef: "Psalm 139:14",
		Category:     affirmation.CategoryIdentity,
		Level:        1,
	}
	if err := affirmation.ValidateAffirmation(a); err != nil {
		t.Errorf("expected 500 chars to pass, got error: %v", err)
	}
}

// TestAffirmation_AFF_DM_AC2_StatementMaxLength_Exceeds verifies that a statement
// of 501 characters is rejected.
func TestAffirmation_AFF_DM_AC2_StatementMaxLength_Exceeds(t *testing.T) {
	a := &affirmation.Affirmation{
		Statement:    strings.Repeat("a", 501),
		ScriptureRef: "Psalm 139:14",
		Category:     affirmation.CategoryIdentity,
		Level:        1,
	}
	err := affirmation.ValidateAffirmation(a)
	if err == nil {
		t.Error("expected validation error for 501 chars, got nil")
	}
}

// TestAffirmation_AFF_DM_AC3_CategoryEnum_Valid verifies all valid categories pass.
func TestAffirmation_AFF_DM_AC3_CategoryEnum_Valid(t *testing.T) {
	categories := affirmation.ValidCategories()
	for _, cat := range categories {
		t.Run(string(cat), func(t *testing.T) {
			a := &affirmation.Affirmation{
				Statement:    "Test statement",
				ScriptureRef: "Test 1:1",
				Category:     cat,
				Level:        1,
			}
			if err := affirmation.ValidateAffirmation(a); err != nil {
				t.Errorf("expected category %s to be valid, got error: %v", cat, err)
			}
		})
	}
}

// TestAffirmation_AFF_DM_AC3_CategoryEnum_Invalid verifies invalid categories are rejected.
func TestAffirmation_AFF_DM_AC3_CategoryEnum_Invalid(t *testing.T) {
	a := &affirmation.Affirmation{
		Statement:    "Test statement",
		ScriptureRef: "Test 1:1",
		Category:     "invalid-category",
		Level:        1,
	}
	err := affirmation.ValidateAffirmation(a)
	if err == nil {
		t.Error("expected validation error for invalid category, got nil")
	}
}

// TestAffirmation_AFF_DM_AC4_LevelRange_Valid verifies levels 1, 2, 3 pass.
func TestAffirmation_AFF_DM_AC4_LevelRange_Valid(t *testing.T) {
	for _, level := range []int{1, 2, 3} {
		t.Run(strings.Repeat("L", level), func(t *testing.T) {
			a := &affirmation.Affirmation{
				Statement:    "Test statement",
				ScriptureRef: "Test 1:1",
				Category:     affirmation.CategoryIdentity,
				Level:        level,
			}
			if err := affirmation.ValidateAffirmation(a); err != nil {
				t.Errorf("expected level %d to be valid, got error: %v", level, err)
			}
		})
	}
}

// TestAffirmation_AFF_DM_AC4_LevelRange_Invalid verifies out-of-range levels are rejected.
func TestAffirmation_AFF_DM_AC4_LevelRange_Invalid(t *testing.T) {
	invalidLevels := []int{0, 4, -1, 100}
	for _, level := range invalidLevels {
		t.Run("", func(t *testing.T) {
			a := &affirmation.Affirmation{
				Statement:    "Test statement",
				ScriptureRef: "Test 1:1",
				Category:     affirmation.CategoryIdentity,
				Level:        level,
			}
			err := affirmation.ValidateAffirmation(a)
			if err == nil {
				t.Errorf("expected validation error for level %d, got nil", level)
			}
		})
	}
}

// TestAffirmation_AFF_DM_AC5_IdPattern_SystemAffirmation verifies system ID pattern.
func TestAffirmation_AFF_DM_AC5_IdPattern_SystemAffirmation(t *testing.T) {
	if !affirmation.ValidateSystemID("aff_abc123") {
		t.Error("expected aff_abc123 to match system ID pattern")
	}
}

// TestAffirmation_AFF_DM_AC5_IdPattern_CustomAffirmation verifies custom ID pattern.
func TestAffirmation_AFF_DM_AC5_IdPattern_CustomAffirmation(t *testing.T) {
	if !affirmation.ValidateCustomID("caff_abc123") {
		t.Error("expected caff_abc123 to match custom ID pattern")
	}
}

// TestAffirmation_AFF_DM_AC5_IdPattern_Invalid verifies invalid ID is rejected.
func TestAffirmation_AFF_DM_AC5_IdPattern_Invalid(t *testing.T) {
	if affirmation.ValidateAnyID("invalid_123") {
		t.Error("expected invalid_123 to not match any ID pattern")
	}
}

// TestAffirmation_AFF_CU_AC1_CreateCustom_ValidSchedules verifies schedule validation.
func TestAffirmation_AFF_CU_AC1_CreateCustom_ValidSchedules(t *testing.T) {
	tests := []struct {
		name     string
		schedule string
		days     []string
	}{
		{"daily", "daily", nil},
		{"weekdays", "weekdays", nil},
		{"weekends", "weekends", nil},
		{"custom", "custom", []string{"monday", "wednesday", "friday"}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := &affirmation.CreateCustomAffirmationRequest{
				Statement:          "My custom affirmation",
				Category:           "identity",
				Schedule:           tt.schedule,
				CustomScheduleDays: tt.days,
			}
			if err := affirmation.ValidateCreateCustomRequest(req); err != nil {
				t.Errorf("expected valid schedule %s, got error: %v", tt.schedule, err)
			}
		})
	}
}

// TestAffirmation_AFF_DM_AC8_HealthySexualityNotAllowedForCustom verifies
// healthySexuality category is rejected for custom affirmations.
func TestAffirmation_AFF_DM_AC8_HealthySexualityNotAllowedForCustom(t *testing.T) {
	req := &affirmation.CreateCustomAffirmationRequest{
		Statement: "Custom HS affirmation",
		Category:  "healthySexuality",
		Schedule:  "daily",
	}
	err := affirmation.ValidateCreateCustomRequest(req)
	if err == nil {
		t.Error("expected validation error for healthySexuality in custom, got nil")
	}
}
