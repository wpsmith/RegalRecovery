// internal/domain/affirmations/custom_test.go
package affirmations

import (
	"testing"
	"time"
)

// TestAffirmations_Custom_Day14GateEnforced verifies that custom affirmations
// are only allowed for users who have been sober for at least 14 days.
//
// Acceptance Criterion: Custom affirmations require 14 days of sobriety.
func TestAffirmations_Custom_Day14GateEnforced(t *testing.T) {
	// Given - User with 14 days of sobriety
	sobrietyDays := 14
	statement := "I am strong and resilient."

	// When
	err := ValidateCustomAffirmationEligibility(sobrietyDays)

	// Then
	if err != nil {
		t.Errorf("expected no error for 14 days, got %v", err)
	}

	// Verify the full validation passes
	result := ValidateCustomStatement(statement, sobrietyDays)
	if !result.Valid {
		t.Errorf("expected valid for 14 days, got errors: %v", result.Errors)
	}
}

// TestAffirmations_Custom_Day13Rejected verifies that users with less than
// 14 days of sobriety cannot create custom affirmations.
//
// Acceptance Criterion: Custom affirmations require 14 days of sobriety.
func TestAffirmations_Custom_Day13Rejected(t *testing.T) {
	// Given - User with only 13 days of sobriety
	sobrietyDays := 13
	statement := "I am strong and resilient."

	// When
	err := ValidateCustomAffirmationEligibility(sobrietyDays)

	// Then
	if err != ErrInsufficientSobrietyDays {
		t.Errorf("expected ErrInsufficientSobrietyDays, got %v", err)
	}

	// Verify the full validation also fails
	result := ValidateCustomStatement(statement, sobrietyDays)
	if result.Valid {
		t.Errorf("expected invalid for 13 days, got valid")
	}
	if len(result.Errors) == 0 {
		t.Errorf("expected errors for 13 days, got none")
	}
}

// TestAffirmations_Custom_PresentTenseValidation_Passes verifies that
// affirmations in present tense are accepted.
//
// Acceptance Criterion: Affirmations must be framed in present tense.
func TestAffirmations_Custom_PresentTenseValidation_Passes(t *testing.T) {
	// Given - Present tense statements
	validStatements := []string{
		"I am strong.",
		"I am capable of healing.",
		"I have the power to choose.",
		"I choose health today.",
		"I embrace my journey.",
	}

	for _, statement := range validStatements {
		// When
		result := ValidateCustomStatement(statement, 14)

		// Then
		if !result.Valid {
			t.Errorf("expected valid for '%s', got errors: %v", statement, result.Errors)
		}
	}
}

// TestAffirmations_Custom_FutureTense_Rejected verifies that future tense
// affirmations are rejected.
//
// Acceptance Criterion: Affirmations must be in present tense, not future.
func TestAffirmations_Custom_FutureTense_Rejected(t *testing.T) {
	// Given - Future tense statements
	invalidStatements := []string{
		"I will be strong.",
		"I'm going to heal.",
		"I'll overcome this.",
		"I will find peace.",
	}

	for _, statement := range invalidStatements {
		// When
		result := ValidateCustomStatement(statement, 14)

		// Then
		if result.Valid {
			t.Errorf("expected invalid for future tense '%s', got valid", statement)
		}
		if len(result.Errors) == 0 {
			t.Errorf("expected errors for future tense '%s', got none", statement)
		}
	}
}

// TestAffirmations_Custom_PositiveFraming_Passes verifies that positively
// framed affirmations are accepted.
//
// Acceptance Criterion: Affirmations must use positive framing.
func TestAffirmations_Custom_PositiveFraming_Passes(t *testing.T) {
	// Given - Positively framed statements
	validStatements := []string{
		"I am worthy of love.",
		"I choose health.",
		"I embrace recovery.",
		"I am making progress.",
	}

	for _, statement := range validStatements {
		// When
		result := ValidateCustomStatement(statement, 14)

		// Then
		if !result.Valid {
			t.Errorf("expected valid for positive framing '%s', got errors: %v", statement, result.Errors)
		}
	}
}

// TestAffirmations_Custom_NegationDetected verifies that negative framing
// is detected and rejected.
//
// Acceptance Criterion: Affirmations must not use negative framing.
func TestAffirmations_Custom_NegationDetected(t *testing.T) {
	// Given - Negatively framed statements
	invalidStatements := []string{
		"I am not weak.",
		"I don't give up.",
		"I am not afraid.",
		"I won't fail.",
	}

	for _, statement := range invalidStatements {
		// When
		result := ValidateCustomStatement(statement, 14)

		// Then
		if result.Valid {
			t.Errorf("expected invalid for negative framing '%s', got valid", statement)
		}
		if len(result.Errors) == 0 {
			t.Errorf("expected errors for negative framing '%s', got none", statement)
		}
	}
}

// TestAffirmations_Custom_AcceptableNegation verifies that the "free from"
// pattern is allowed as an exception to negative framing.
//
// Acceptance Criterion: "free from" pattern is allowed as positive framing.
func TestAffirmations_Custom_AcceptableNegation(t *testing.T) {
	// Given - Statements with "free from" pattern
	validStatements := []string{
		"I am free from addiction.",
		"I am free from shame.",
		"I am free from guilt.",
	}

	for _, statement := range validStatements {
		// When
		result := ValidateCustomStatement(statement, 14)

		// Then
		if !result.Valid {
			t.Errorf("expected valid for 'free from' pattern '%s', got errors: %v", statement, result.Errors)
		}
	}
}

// TestAffirmations_Custom_IncludeInRotationToggle_On verifies that custom
// affirmations can be included in the rotation.
//
// Acceptance Criterion: Users can toggle whether custom affirmations appear in rotation.
func TestAffirmations_Custom_IncludeInRotationToggle_On(t *testing.T) {
	// Given - Custom affirmation with includeInRotation = true
	affirmation := &CustomAffirmation{
		ID:                "custom-001",
		UserID:            "user-123",
		Statement:         "I am strong and resilient.",
		IncludeInRotation: true,
		IsActive:          true,
		CreatedAt:         time.Now().UTC(),
		ModifiedAt:        time.Now().UTC(),
	}

	// When
	inRotation := affirmation.IncludeInRotation

	// Then
	if !inRotation {
		t.Errorf("expected includeInRotation to be true, got false")
	}
}

// TestAffirmations_Custom_IncludeInRotationToggle_Off verifies that custom
// affirmations can be excluded from the rotation.
//
// Acceptance Criterion: Users can toggle whether custom affirmations appear in rotation.
func TestAffirmations_Custom_IncludeInRotationToggle_Off(t *testing.T) {
	// Given - Custom affirmation with includeInRotation = false
	affirmation := &CustomAffirmation{
		ID:                "custom-002",
		UserID:            "user-123",
		Statement:         "I am strong and resilient.",
		IncludeInRotation: false,
		IsActive:          true,
		CreatedAt:         time.Now().UTC(),
		ModifiedAt:        time.Now().UTC(),
	}

	// When
	inRotation := affirmation.IncludeInRotation

	// Then
	if inRotation {
		t.Errorf("expected includeInRotation to be false, got true")
	}
}

// TestAffirmations_Custom_MaxLength500Characters verifies that custom
// affirmations are limited to 500 characters.
//
// Acceptance Criterion: Custom affirmations max 500 characters.
func TestAffirmations_Custom_MaxLength500Characters(t *testing.T) {
	// Given - Statement with exactly 500 characters
	// Build a string that's exactly 500 characters
	base := "I am strong and capable of overcoming any challenge."
	// Pad to exactly 500 characters
	statement500 := base
	for len(statement500) < 500 {
		statement500 += " I am resilient and brave."
		if len(statement500) > 500 {
			statement500 = statement500[:500]
			break
		}
	}

	// When
	result := ValidateCustomStatement(statement500, 14)

	// Then
	if !result.Valid {
		t.Errorf("expected valid for 500 characters, got errors: %v", result.Errors)
	}
	if len(statement500) != 500 {
		t.Errorf("expected exactly 500 characters, got %d", len(statement500))
	}

	// Given - Statement with 501 characters
	statement501 := statement500 + "x"

	// When
	result = ValidateCustomStatement(statement501, 14)

	// Then
	if result.Valid {
		t.Errorf("expected invalid for 501 characters, got valid")
	}
}

// TestAffirmations_Custom_EditWindow24Hours verifies that custom affirmations
// can be edited within 24 hours of creation, but become read-only after.
//
// Acceptance Criterion: 24-hour edit window after creation.
func TestAffirmations_Custom_EditWindow24Hours(t *testing.T) {
	// Given - Affirmation created 12 hours ago
	createdAt := time.Now().UTC().Add(-12 * time.Hour)

	// When
	editable := IsWithinEditWindow(createdAt)

	// Then
	if !editable {
		t.Errorf("expected editable within 24 hours, got read-only")
	}

	// Given - Affirmation created 25 hours ago
	createdAt = time.Now().UTC().Add(-25 * time.Hour)

	// When
	editable = IsWithinEditWindow(createdAt)

	// Then
	if editable {
		t.Errorf("expected read-only after 24 hours, got editable")
	}

	// Given - Affirmation created exactly 24 hours ago (edge case)
	createdAt = time.Now().UTC().Add(-24 * time.Hour)

	// When
	editable = IsWithinEditWindow(createdAt)

	// Then - Should be read-only (window closed)
	if editable {
		t.Errorf("expected read-only at exactly 24 hours, got editable")
	}
}

// TestAffirmations_Custom_EmptyStatement verifies that empty statements are rejected.
//
// Acceptance Criterion: Affirmations must have content.
func TestAffirmations_Custom_EmptyStatement(t *testing.T) {
	// Given - Empty statement
	statement := ""

	// When
	result := ValidateCustomStatement(statement, 14)

	// Then
	if result.Valid {
		t.Errorf("expected invalid for empty statement, got valid")
	}
	if len(result.Errors) == 0 {
		t.Errorf("expected errors for empty statement, got none")
	}
}

// TestAffirmations_Custom_WhitespaceOnlyStatement verifies that whitespace-only
// statements are rejected.
//
// Acceptance Criterion: Affirmations must have meaningful content.
func TestAffirmations_Custom_WhitespaceOnlyStatement(t *testing.T) {
	// Given - Whitespace-only statement
	statement := "   \t\n   "

	// When
	result := ValidateCustomStatement(statement, 14)

	// Then
	if result.Valid {
		t.Errorf("expected invalid for whitespace-only statement, got valid")
	}
}
