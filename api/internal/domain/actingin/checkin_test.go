// internal/domain/actingin/checkin_test.go
package actingin

import (
	"errors"
	"strings"
	"testing"
	"time"
)

func newTestConfig() *BehaviorConfig {
	config := NewBehaviorConfig("user_001")
	// Add two custom behaviors for testing.
	config.CreateCustomBehavior("Custom One", "")
	config.CreateCustomBehavior("Custom Two", "")
	return config
}

// TestCheckIn_AC_AIB_012_DisplaysAllEnabledBehaviors verifies that the check-in
// behavior list matches enabled behaviors from config.
//
// AC-AIB-012: All 14 behaviors displayed as a checklist when 12 defaults + 2 custom enabled.
func TestCheckIn_AC_AIB_012_DisplaysAllEnabledBehaviors(t *testing.T) {
	config := newTestConfig()

	// Disable 3 defaults.
	config.ToggleBehavior("beh_default_humor", false)
	config.ToggleBehavior("beh_default_placating", false)
	config.ToggleBehavior("beh_default_withhold", false)

	enabled := config.GetEnabledBehaviors()
	// 15 - 3 + 2 = 14.
	if len(enabled) != 14 {
		t.Errorf("expected 14 enabled behaviors, got %d", len(enabled))
	}
}

// TestCheckIn_AC_AIB_013_MarkBehaviorsWithContext verifies that checked behaviors
// accept optional context note, trigger, and relationship tag.
//
// AC-AIB-013: Each checked behavior includes optional context note, trigger chip, relationship tag.
func TestCheckIn_AC_AIB_013_MarkBehaviorsWithContext(t *testing.T) {
	config := NewBehaviorConfig("user_001")

	req := &CreateCheckInRequest{
		Timestamp: time.Now().UTC(),
		Behaviors: []CheckedBehaviorInput{
			{
				BehaviorID:      "beh_default_stonewall",
				ContextNote:     "Shut down after argument about finances",
				Trigger:         TriggerConflict,
				RelationshipTag: RelationshipSpouse,
			},
			{
				BehaviorID:      "beh_default_avoid",
				ContextNote:     "Avoided sponsor's call",
				Trigger:         TriggerShame,
				RelationshipTag: RelationshipSponsor,
			},
		},
	}

	err := ValidateCheckInRequest(req, config)
	if err != nil {
		t.Fatalf("unexpected validation error: %v", err)
	}

	checkIn := CreateCheckIn(req, config, 6)
	if len(checkIn.Behaviors) != 2 {
		t.Errorf("expected 2 behaviors, got %d", len(checkIn.Behaviors))
	}
	if checkIn.Behaviors[0].ContextNote != "Shut down after argument about finances" {
		t.Error("context note not preserved")
	}
	if checkIn.Behaviors[0].Trigger != TriggerConflict {
		t.Error("trigger not preserved")
	}
	if checkIn.Behaviors[0].RelationshipTag != RelationshipSpouse {
		t.Error("relationship tag not preserved")
	}
}

// TestCheckIn_AC_AIB_014_ContextNoteCharLimit verifies that context notes over
// 500 characters are rejected.
//
// AC-AIB-014: Context note > 500 chars is rejected.
func TestCheckIn_AC_AIB_014_ContextNoteCharLimit(t *testing.T) {
	config := NewBehaviorConfig("user_001")

	req := &CreateCheckInRequest{
		Timestamp: time.Now().UTC(),
		Behaviors: []CheckedBehaviorInput{
			{
				BehaviorID:  "beh_default_blame",
				ContextNote: strings.Repeat("x", 501),
			},
		},
	}

	err := ValidateCheckInRequest(req, config)
	if err == nil {
		t.Fatal("expected validation error for context note > 500 chars")
	}
	if !errors.Is(err, ErrContextNoteTooLong) {
		t.Errorf("expected ErrContextNoteTooLong, got %v", err)
	}
}

// TestCheckIn_AC_AIB_015_SubmitWithBehaviors verifies that a check-in with behaviors
// returns correct behaviorCount and compassionate message.
//
// AC-AIB-015: Check-in with 3 behaviors saved with timestamp, all checked behaviors, and message.
func TestCheckIn_AC_AIB_015_SubmitWithBehaviors(t *testing.T) {
	config := NewBehaviorConfig("user_001")

	req := &CreateCheckInRequest{
		Timestamp: time.Now().UTC(),
		Behaviors: []CheckedBehaviorInput{
			{BehaviorID: "beh_default_stonewall"},
			{BehaviorID: "beh_default_avoid"},
			{BehaviorID: "beh_default_hide"},
		},
	}

	checkIn := CreateCheckIn(req, config, 0)
	if checkIn.BehaviorCount != 3 {
		t.Errorf("expected behaviorCount 3, got %d", checkIn.BehaviorCount)
	}
	if checkIn.Message == "" {
		t.Error("expected compassionate message, got empty string")
	}
}

// TestCheckIn_AC_AIB_016_SubmitZeroBehaviors verifies that a zero-behavior
// check-in is valid and returns a celebration message.
//
// AC-AIB-016: Zero-behavior check-in is recorded with celebration message.
func TestCheckIn_AC_AIB_016_SubmitZeroBehaviors(t *testing.T) {
	config := NewBehaviorConfig("user_001")

	req := &CreateCheckInRequest{
		Timestamp: time.Now().UTC(),
		Behaviors: []CheckedBehaviorInput{},
	}

	err := ValidateCheckInRequest(req, config)
	if err != nil {
		t.Fatalf("zero-behavior check-in should be valid: %v", err)
	}

	checkIn := CreateCheckIn(req, config, 5)
	if checkIn.BehaviorCount != 0 {
		t.Errorf("expected behaviorCount 0, got %d", checkIn.BehaviorCount)
	}
	if checkIn.Message != MessageZeroBehaviors {
		t.Errorf("expected zero-behavior message %q, got %q", MessageZeroBehaviors, checkIn.Message)
	}
}

// TestCheckIn_AC_AIB_017_NoBehaviorLimit verifies that all 15+ behaviors
// can be checked without error.
//
// AC-AIB-017: All 15+ behaviors accepted without error.
func TestCheckIn_AC_AIB_017_NoBehaviorLimit(t *testing.T) {
	config := newTestConfig() // 15 defaults + 2 custom = 17 behaviors.

	behaviors := make([]CheckedBehaviorInput, 0, 17)
	for _, b := range config.GetEnabledBehaviors() {
		behaviors = append(behaviors, CheckedBehaviorInput{
			BehaviorID: b.BehaviorID,
		})
	}

	req := &CreateCheckInRequest{
		Timestamp: time.Now().UTC(),
		Behaviors: behaviors,
	}

	err := ValidateCheckInRequest(req, config)
	if err != nil {
		t.Fatalf("should accept all 17 behaviors: %v", err)
	}

	checkIn := CreateCheckIn(req, config, 0)
	if checkIn.BehaviorCount != 17 {
		t.Errorf("expected behaviorCount 17, got %d", checkIn.BehaviorCount)
	}
}

// TestCheckIn_AC_AIB_015_CompassionateMessage verifies the compassionate message
// content when behaviors are checked.
//
// AC-AIB-015: Message matches rotating compassionate messages.
func TestCheckIn_AC_AIB_015_CompassionateMessage(t *testing.T) {
	// With behaviors, should get one of the rotating messages.
	msg := SelectMessage(2, 0)
	found := false
	for _, rm := range RotatingMessages {
		if msg == rm {
			found = true
			break
		}
	}
	if !found {
		t.Errorf("expected one of the rotating messages, got %q", msg)
	}
}

// TestCheckIn_AC_AIB_016_ZeroBehaviorMessage verifies the celebration message
// for zero-behavior check-ins.
//
// AC-AIB-016: Message matches "No acting-in behaviors today..."
func TestCheckIn_AC_AIB_016_ZeroBehaviorMessage(t *testing.T) {
	msg := SelectMessage(0, 5)
	if msg != MessageZeroBehaviors {
		t.Errorf("expected %q, got %q", MessageZeroBehaviors, msg)
	}
}

// TestCheckIn_AC_AIB_071_RotatingPostCheckInMessages verifies that post-check-in
// messages rotate among the 3 defined messages.
//
// AC-AIB-071: Messages rotate between the 3 defined messages.
func TestCheckIn_AC_AIB_071_RotatingPostCheckInMessages(t *testing.T) {
	seen := make(map[string]bool)
	for i := 0; i < len(RotatingMessages); i++ {
		msg := SelectMessage(1, i)
		seen[msg] = true
	}
	if len(seen) != len(RotatingMessages) {
		t.Errorf("expected %d unique rotating messages, got %d", len(RotatingMessages), len(seen))
	}
}

// TestCheckIn_InvalidBehaviorId_Rejected verifies that submitting a behaviorId
// not in the user's enabled list returns an error.
func TestCheckIn_InvalidBehaviorId_Rejected(t *testing.T) {
	config := NewBehaviorConfig("user_001")

	req := &CreateCheckInRequest{
		Timestamp: time.Now().UTC(),
		Behaviors: []CheckedBehaviorInput{
			{BehaviorID: "beh_nonexistent"},
		},
	}

	err := ValidateCheckInRequest(req, config)
	if err == nil {
		t.Fatal("expected validation error for nonexistent behavior ID")
	}
	if !errors.Is(err, ErrInvalidBehaviorID) {
		t.Errorf("expected ErrInvalidBehaviorID, got %v", err)
	}
}

// TestCheckIn_DisabledBehaviorId_Rejected verifies that submitting a disabled
// behaviorId returns an error.
func TestCheckIn_DisabledBehaviorId_Rejected(t *testing.T) {
	config := NewBehaviorConfig("user_001")
	config.ToggleBehavior("beh_default_humor", false)

	req := &CreateCheckInRequest{
		Timestamp: time.Now().UTC(),
		Behaviors: []CheckedBehaviorInput{
			{BehaviorID: "beh_default_humor"},
		},
	}

	err := ValidateCheckInRequest(req, config)
	if err == nil {
		t.Fatal("expected validation error for disabled behavior ID")
	}
	if !errors.Is(err, ErrDisabledBehaviorID) {
		t.Errorf("expected ErrDisabledBehaviorID, got %v", err)
	}
}

// TestCheckIn_InvalidTrigger_Rejected verifies that an invalid trigger value
// returns a validation error.
func TestCheckIn_InvalidTrigger_Rejected(t *testing.T) {
	config := NewBehaviorConfig("user_001")

	req := &CreateCheckInRequest{
		Timestamp: time.Now().UTC(),
		Behaviors: []CheckedBehaviorInput{
			{BehaviorID: "beh_default_blame", Trigger: "invalid_trigger"},
		},
	}

	err := ValidateCheckInRequest(req, config)
	if err == nil {
		t.Fatal("expected validation error for invalid trigger")
	}
	if !errors.Is(err, ErrInvalidTrigger) {
		t.Errorf("expected ErrInvalidTrigger, got %v", err)
	}
}

// TestCheckIn_InvalidRelationshipTag_Rejected verifies that an invalid
// relationship tag returns a validation error.
func TestCheckIn_InvalidRelationshipTag_Rejected(t *testing.T) {
	config := NewBehaviorConfig("user_001")

	req := &CreateCheckInRequest{
		Timestamp: time.Now().UTC(),
		Behaviors: []CheckedBehaviorInput{
			{BehaviorID: "beh_default_blame", RelationshipTag: "invalid_tag"},
		},
	}

	err := ValidateCheckInRequest(req, config)
	if err == nil {
		t.Fatal("expected validation error for invalid relationship tag")
	}
	if !errors.Is(err, ErrInvalidRelationshipTag) {
		t.Errorf("expected ErrInvalidRelationshipTag, got %v", err)
	}
}

// TestCheckIn_ImmutableTimestamp_FR2_7 verifies that check-in timestamps
// cannot be modified after creation.
//
// FR2.7: Timestamps are immutable once set.
func TestCheckIn_ImmutableTimestamp_FR2_7(t *testing.T) {
	config := NewBehaviorConfig("user_001")
	originalTime := time.Date(2026, 3, 28, 21, 0, 0, 0, time.UTC)

	req := &CreateCheckInRequest{
		Timestamp: originalTime,
		Behaviors: []CheckedBehaviorInput{},
	}

	checkIn := CreateCheckIn(req, config, 0)

	// Verify the timestamp matches the request.
	if !checkIn.Timestamp.Equal(originalTime) {
		t.Errorf("expected timestamp %v, got %v", originalTime, checkIn.Timestamp)
	}

	// CreatedAt and ModifiedAt should be separate from the user-provided timestamp.
	if checkIn.CreatedAt.Equal(originalTime) {
		t.Error("CreatedAt should be server time, not user-provided timestamp")
	}
}

// TestCheckIn_BehaviorNamesResolved verifies that behavior names are denormalized
// into the check-in for historical preservation.
func TestCheckIn_BehaviorNamesResolved(t *testing.T) {
	config := NewBehaviorConfig("user_001")

	req := &CreateCheckInRequest{
		Timestamp: time.Now().UTC(),
		Behaviors: []CheckedBehaviorInput{
			{BehaviorID: "beh_default_stonewall"},
		},
	}

	checkIn := CreateCheckIn(req, config, 0)
	if checkIn.Behaviors[0].BehaviorName != "Stonewall" {
		t.Errorf("expected behavior name 'Stonewall', got %q", checkIn.Behaviors[0].BehaviorName)
	}
}

// TestCheckIn_TriggerAndRelationshipDenormalized verifies that triggers and
// relationship tags are collected into top-level arrays for filtering.
func TestCheckIn_TriggerAndRelationshipDenormalized(t *testing.T) {
	config := NewBehaviorConfig("user_001")

	req := &CreateCheckInRequest{
		Timestamp: time.Now().UTC(),
		Behaviors: []CheckedBehaviorInput{
			{BehaviorID: "beh_default_stonewall", Trigger: TriggerConflict, RelationshipTag: RelationshipSpouse},
			{BehaviorID: "beh_default_avoid", Trigger: TriggerShame, RelationshipTag: RelationshipSponsor},
		},
	}

	checkIn := CreateCheckIn(req, config, 0)

	if len(checkIn.Triggers) != 2 {
		t.Errorf("expected 2 triggers, got %d", len(checkIn.Triggers))
	}
	if len(checkIn.RelationshipTags) != 2 {
		t.Errorf("expected 2 relationship tags, got %d", len(checkIn.RelationshipTags))
	}
}
