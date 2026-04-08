// internal/domain/actingin/behavior_config_test.go
package actingin

import (
	"strings"
	"testing"
)

// TestBehaviorConfig_AC_AIB_001_DefaultBehaviorsAvailableOnFirstUse verifies
// that a new user config contains all 15 defaults enabled.
//
// AC-AIB-001: Given a user enables the Acting In Behaviors activity for the first time,
// all 15 default behaviors are listed and enabled by default.
func TestBehaviorConfig_AC_AIB_001_DefaultBehaviorsAvailableOnFirstUse(t *testing.T) {
	config := NewBehaviorConfig("user_001")

	all := config.GetAllBehaviors()
	if len(all) != 15 {
		t.Errorf("expected 15 default behaviors, got %d", len(all))
	}

	for _, b := range all {
		if !b.IsDefault {
			t.Errorf("expected all behaviors to be defaults on first use, got custom: %s", b.BehaviorID)
		}
		if !b.Enabled {
			t.Errorf("expected all defaults to be enabled on first use, %s is disabled", b.BehaviorID)
		}
	}

	// Verify specific behaviors exist.
	expectedNames := []string{"Blame", "Shame", "Criticism", "Stonewall", "Avoid", "Hide",
		"Lie", "Excuse", "Manipulate", "Control with Anger", "Passivity", "Humor",
		"Placating", "Withhold Love/Sex", "HyperSpiritualize"}
	names := make(map[string]bool)
	for _, b := range all {
		names[b.Name] = true
	}
	for _, expected := range expectedNames {
		if !names[expected] {
			t.Errorf("expected default behavior %q not found", expected)
		}
	}
}

// TestBehaviorConfig_AC_AIB_002_DisableDefaultBehavior verifies that toggling off
// a default sets enabled=false and preserves behavior in config.
//
// AC-AIB-002: Toggling off "Humor" hides it from check-in flow, preserves historical data.
func TestBehaviorConfig_AC_AIB_002_DisableDefaultBehavior(t *testing.T) {
	config := NewBehaviorConfig("user_001")

	behavior, err := config.ToggleBehavior("beh_default_humor", false)
	if err != nil {
		t.Fatalf("unexpected error toggling behavior: %v", err)
	}
	if behavior.Enabled {
		t.Error("expected Humor to be disabled after toggle")
	}

	// Verify Humor no longer in enabled list.
	enabled := config.GetEnabledBehaviors()
	for _, b := range enabled {
		if b.BehaviorID == "beh_default_humor" {
			t.Error("expected Humor to not be in enabled behaviors list")
		}
	}

	// Verify it still exists in the full list.
	all := config.GetAllBehaviors()
	found := false
	for _, b := range all {
		if b.BehaviorID == "beh_default_humor" {
			found = true
			if b.Enabled {
				t.Error("Humor should be disabled in full list")
			}
		}
	}
	if !found {
		t.Error("Humor should still exist in full list after disable")
	}
}

// TestBehaviorConfig_AC_AIB_003_ReEnableDefaultBehavior verifies that re-enabling
// a previously disabled default restores it to the check-in flow.
//
// AC-AIB-003: Re-enabling "Humor" reappears in check-in flow with all prior historical data accessible.
func TestBehaviorConfig_AC_AIB_003_ReEnableDefaultBehavior(t *testing.T) {
	config := NewBehaviorConfig("user_001")

	// Disable then re-enable.
	_, _ = config.ToggleBehavior("beh_default_humor", false)
	behavior, err := config.ToggleBehavior("beh_default_humor", true)
	if err != nil {
		t.Fatalf("unexpected error re-enabling behavior: %v", err)
	}
	if !behavior.Enabled {
		t.Error("expected Humor to be enabled after re-toggle")
	}

	// Verify it's back in the enabled list.
	enabled := config.GetEnabledBehaviors()
	found := false
	for _, b := range enabled {
		if b.BehaviorID == "beh_default_humor" {
			found = true
		}
	}
	if !found {
		t.Error("Humor should be in enabled list after re-enable")
	}
}

// TestBehaviorConfig_AC_AIB_004_CreateCustomBehavior verifies that adding a custom
// behavior with valid name and description succeeds.
//
// AC-AIB-004: Adding custom behavior appears alongside enabled defaults in check-in flow.
func TestBehaviorConfig_AC_AIB_004_CreateCustomBehavior(t *testing.T) {
	config := NewBehaviorConfig("user_001")

	behavior, err := config.CreateCustomBehavior("Sarcasm Deflection", "Using sharp humor to avoid vulnerability")
	if err != nil {
		t.Fatalf("unexpected error creating custom behavior: %v", err)
	}

	if behavior.Name != "Sarcasm Deflection" {
		t.Errorf("expected name 'Sarcasm Deflection', got %q", behavior.Name)
	}
	if behavior.IsDefault {
		t.Error("expected custom behavior to not be a default")
	}
	if !behavior.Enabled {
		t.Error("expected custom behavior to be enabled by default")
	}
	if behavior.SortOrder != 16 {
		t.Errorf("expected sortOrder 16, got %d", behavior.SortOrder)
	}

	// Verify it appears in enabled behaviors.
	enabled := config.GetEnabledBehaviors()
	found := false
	for _, b := range enabled {
		if b.Name == "Sarcasm Deflection" {
			found = true
		}
	}
	if !found {
		t.Error("custom behavior should appear in enabled list")
	}
}

// TestBehaviorConfig_AC_AIB_005_CustomBehaviorNameValidation_TooLong verifies that
// a name exceeding 100 characters returns a validation error.
//
// AC-AIB-005: Name > 100 chars returns validation error.
func TestBehaviorConfig_AC_AIB_005_CustomBehaviorNameValidation_TooLong(t *testing.T) {
	config := NewBehaviorConfig("user_001")

	longName := strings.Repeat("a", 101)
	_, err := config.CreateCustomBehavior(longName, "")
	if err == nil {
		t.Fatal("expected validation error for name > 100 chars")
	}
	if err != ErrNameTooLong {
		t.Errorf("expected ErrNameTooLong, got %v", err)
	}
}

// TestBehaviorConfig_AC_AIB_005_CustomBehaviorNameValidation_Empty verifies that
// an empty name returns a validation error.
//
// AC-AIB-005: Empty name returns validation error.
func TestBehaviorConfig_AC_AIB_005_CustomBehaviorNameValidation_Empty(t *testing.T) {
	config := NewBehaviorConfig("user_001")

	_, err := config.CreateCustomBehavior("", "Some description")
	if err == nil {
		t.Fatal("expected validation error for empty name")
	}
	if err != ErrNameEmpty {
		t.Errorf("expected ErrNameEmpty, got %v", err)
	}
}

// TestBehaviorConfig_AC_AIB_006_EditCustomBehavior verifies that editing the name
// and description of an existing custom behavior succeeds.
//
// AC-AIB-006: Updated name is reflected in future check-ins.
func TestBehaviorConfig_AC_AIB_006_EditCustomBehavior(t *testing.T) {
	config := NewBehaviorConfig("user_001")

	created, _ := config.CreateCustomBehavior("Sarcasm Deflection", "Using sharp humor to avoid vulnerability")

	newName := "Deflecting with Humor"
	updated, err := config.UpdateCustomBehavior(created.BehaviorID, &newName, nil)
	if err != nil {
		t.Fatalf("unexpected error updating custom behavior: %v", err)
	}
	if updated.Name != "Deflecting with Humor" {
		t.Errorf("expected updated name 'Deflecting with Humor', got %q", updated.Name)
	}
	if updated.Description != "Using sharp humor to avoid vulnerability" {
		t.Error("description should be preserved when only name is updated")
	}
}

// TestBehaviorConfig_AC_AIB_006_EditDefaultBehavior_Rejected verifies that
// attempting to edit a default behavior returns an error.
//
// AC-AIB-006: Default behaviors cannot be edited.
func TestBehaviorConfig_AC_AIB_006_EditDefaultBehavior_Rejected(t *testing.T) {
	config := NewBehaviorConfig("user_001")

	newName := "Modified Blame"
	_, err := config.UpdateCustomBehavior("beh_default_blame", &newName, nil)
	if err == nil {
		t.Fatal("expected error when editing default behavior")
	}
	if err != ErrCannotEditDefault {
		t.Errorf("expected ErrCannotEditDefault, got %v", err)
	}
}

// TestBehaviorConfig_AC_AIB_007_DeleteCustomBehavior verifies that deleting a
// custom behavior removes it from config but preserves historical data.
//
// AC-AIB-007: Deleted custom behavior removed from check-in flow, historical entries preserved.
func TestBehaviorConfig_AC_AIB_007_DeleteCustomBehavior(t *testing.T) {
	config := NewBehaviorConfig("user_001")

	created, _ := config.CreateCustomBehavior("Sarcasm Deflection", "")
	err := config.DeleteCustomBehavior(created.BehaviorID)
	if err != nil {
		t.Fatalf("unexpected error deleting custom behavior: %v", err)
	}

	// Verify it no longer appears.
	all := config.GetAllBehaviors()
	for _, b := range all {
		if b.BehaviorID == created.BehaviorID {
			t.Error("deleted custom behavior should not appear in behavior list")
		}
	}
}

// TestBehaviorConfig_AC_AIB_007_DeleteDefaultBehavior_Rejected verifies that
// attempting to delete a default behavior returns an error.
//
// AC-AIB-007: Cannot delete default behaviors.
func TestBehaviorConfig_AC_AIB_007_DeleteDefaultBehavior_Rejected(t *testing.T) {
	config := NewBehaviorConfig("user_001")

	err := config.DeleteCustomBehavior("beh_default_blame")
	if err == nil {
		t.Fatal("expected error when deleting default behavior")
	}
	if err != ErrCannotDeleteDefault {
		t.Errorf("expected ErrCannotDeleteDefault, got %v", err)
	}
}

// TestBehaviorConfig_GetEnabledBehaviors_ReturnsOnlyEnabled verifies that the helper
// returns only enabled behaviors (defaults + custom) sorted by sortOrder.
func TestBehaviorConfig_GetEnabledBehaviors_ReturnsOnlyEnabled(t *testing.T) {
	config := NewBehaviorConfig("user_001")

	// Disable two defaults.
	_, _ = config.ToggleBehavior("beh_default_humor", false)
	_, _ = config.ToggleBehavior("beh_default_placating", false)

	// Add a custom behavior.
	_, _ = config.CreateCustomBehavior("Custom One", "")

	enabled := config.GetEnabledBehaviors()

	// Expect 15 - 2 + 1 = 14 enabled behaviors.
	if len(enabled) != 14 {
		t.Errorf("expected 14 enabled behaviors, got %d", len(enabled))
	}

	// Verify sort order is maintained.
	for i := 1; i < len(enabled); i++ {
		if enabled[i].SortOrder < enabled[i-1].SortOrder {
			t.Errorf("behaviors not sorted by sortOrder: %d < %d at index %d",
				enabled[i].SortOrder, enabled[i-1].SortOrder, i)
		}
	}
}

// TestBehaviorConfig_DescriptionValidation_TooLong verifies that a description
// exceeding 500 characters is rejected.
func TestBehaviorConfig_DescriptionValidation_TooLong(t *testing.T) {
	config := NewBehaviorConfig("user_001")

	longDesc := strings.Repeat("x", 501)
	_, err := config.CreateCustomBehavior("Valid Name", longDesc)
	if err == nil {
		t.Fatal("expected validation error for description > 500 chars")
	}
	if err != ErrDescriptionTooLong {
		t.Errorf("expected ErrDescriptionTooLong, got %v", err)
	}
}

// TestBehaviorConfig_NameAt100Chars_Succeeds verifies that exactly 100 chars is accepted.
func TestBehaviorConfig_NameAt100Chars_Succeeds(t *testing.T) {
	config := NewBehaviorConfig("user_001")

	name := strings.Repeat("a", 100)
	behavior, err := config.CreateCustomBehavior(name, "")
	if err != nil {
		t.Fatalf("unexpected error for 100-char name: %v", err)
	}
	if behavior.Name != name {
		t.Error("name should be accepted at exactly 100 characters")
	}
}
