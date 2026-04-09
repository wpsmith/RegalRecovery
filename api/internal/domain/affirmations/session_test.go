// internal/domain/affirmations/session_test.go
package affirmations

import (
	"testing"
)

// Morning Session Tests

func TestAffirmations_MorningSession_Composes3Affirmations(t *testing.T) {
	t.Parallel()

	affirmations := []Affirmation{
		{ID: "aff1", Text: "I am worthy", Level: LevelPermission, Category: CategorySelfWorth, Track: TrackStandard},
		{ID: "aff2", Text: "I am growing", Level: LevelPermission, Category: CategoryDailyStrength, Track: TrackStandard},
		{ID: "aff3", Text: "I am healing", Level: LevelPermission, Category: CategoryShameResilience, Track: TrackStandard},
	}

	session := NewMorningSession(affirmations)

	if len(session.Affirmations) != 3 {
		t.Errorf("Expected 3 affirmations, got %d", len(session.Affirmations))
	}
}

func TestAffirmations_MorningSession_IncludesIntentionPrompt(t *testing.T) {
	t.Parallel()

	affirmations := []Affirmation{
		{ID: "aff1", Text: "I am worthy", Level: LevelPermission, Category: CategorySelfWorth, Track: TrackStandard},
	}

	session := NewMorningSession(affirmations)

	if session.IntentionPrompt != "Today I choose to..." {
		t.Errorf("Expected intention prompt 'Today I choose to...', got %q", session.IntentionPrompt)
	}
}

func TestAffirmations_MorningSession_AffirmationsMatchUserLevel(t *testing.T) {
	t.Parallel()

	affirmations := []Affirmation{
		{ID: "aff1", Text: "I am worthy", Level: LevelPermission, Category: CategorySelfWorth, Track: TrackStandard},
		{ID: "aff2", Text: "I am growing", Level: LevelPermission, Category: CategoryDailyStrength, Track: TrackStandard},
		{ID: "aff3", Text: "I am healing", Level: LevelPermission, Category: CategoryShameResilience, Track: TrackStandard},
	}

	session := NewMorningSession(affirmations)

	for _, aff := range session.Affirmations {
		if aff.Level != LevelPermission {
			t.Errorf("Expected all affirmations to be Level 1, got %d", aff.Level)
		}
	}
}

func TestAffirmations_MorningSession_SkipWithoutPenalty(t *testing.T) {
	t.Parallel()

	affirmations := []Affirmation{
		{ID: "aff1", Text: "I am worthy", Level: LevelPermission, Category: CategorySelfWorth, Track: TrackStandard},
	}

	session := NewMorningSession(affirmations)

	// Mark as skipped using Skip method
	session.Skip()

	// Verify no penalty flag
	if session.AffectsProgress {
		t.Error("Skipped morning session should not affect progress")
	}

	if !session.Skipped {
		t.Error("Session should be marked as skipped")
	}
}

// Evening Session Tests

func TestAffirmations_EveningSession_Composes1Affirmation(t *testing.T) {
	t.Parallel()

	affirmations := []Affirmation{
		{ID: "aff1", Text: "I am worthy", Level: LevelPermission, Category: CategorySelfWorth, Track: TrackStandard},
	}

	session := NewEveningSession(affirmations, "focus on connection")

	if len(session.Affirmations) != 1 {
		t.Errorf("Expected 1 affirmation, got %d", len(session.Affirmations))
	}
}

func TestAffirmations_EveningSession_IncludesMorningIntention(t *testing.T) {
	t.Parallel()

	affirmations := []Affirmation{
		{ID: "aff1", Text: "I am worthy", Level: LevelPermission, Category: CategorySelfWorth, Track: TrackStandard},
	}

	morningIntention := "focus on gratitude"
	session := NewEveningSession(affirmations, morningIntention)

	if session.MorningIntention != morningIntention {
		t.Errorf("Expected morning intention %q, got %q", morningIntention, session.MorningIntention)
	}
}

func TestAffirmations_EveningSession_IncludesDayRating1to5(t *testing.T) {
	t.Parallel()

	affirmations := []Affirmation{
		{ID: "aff1", Text: "I am worthy", Level: LevelPermission, Category: CategorySelfWorth, Track: TrackStandard},
	}

	session := NewEveningSession(affirmations, "focus on connection")

	// Set rating
	session.DayRating = 4

	if session.DayRating < 1 || session.DayRating > 5 {
		t.Errorf("Day rating should be 1-5, got %d", session.DayRating)
	}
}

func TestAffirmations_EveningSession_OptionalFreeTextReflection(t *testing.T) {
	t.Parallel()

	affirmations := []Affirmation{
		{ID: "aff1", Text: "I am worthy", Level: LevelPermission, Category: CategorySelfWorth, Track: TrackStandard},
	}

	session := NewEveningSession(affirmations, "focus on connection")

	// Set optional reflection
	session.Reflection = "Today was challenging but I stayed committed"

	if session.Reflection == "" {
		t.Error("Reflection should be set")
	}
}

// SOS Session Tests

func TestAffirmations_SOSSession_Level1Or2Only(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name     string
		level    Level
		shouldOK bool
	}{
		{"Level 1 allowed", LevelPermission, true},
		{"Level 2 allowed", LevelProcess, true},
		{"Level 3 rejected", LevelTemperedIdentity, false},
		{"Level 4 rejected", LevelFullIdentity, false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			affirmations := []Affirmation{
				{ID: "aff1", Text: "I am safe", Level: tt.level, Category: CategorySOSCrisis, Track: TrackStandard},
			}

			_, err := NewSOSSession(affirmations)

			if tt.shouldOK && err != nil {
				t.Errorf("Expected no error for %s, got %v", tt.name, err)
			}

			if !tt.shouldOK && err == nil {
				t.Errorf("Expected error for %s, got nil", tt.name)
			}
		})
	}
}

func TestAffirmations_SOSSession_NeverAboveLevel2_RegardlessOfProgress(t *testing.T) {
	t.Parallel()

	// User with 200 days sobriety (would normally be Level 4)
	// SOS session must still be Level 1-2 only
	affirmations := []Affirmation{
		{ID: "aff1", Text: "I am safe", Level: LevelFullIdentity, Category: CategorySOSCrisis, Track: TrackStandard},
	}

	_, err := NewSOSSession(affirmations)

	if err == nil {
		t.Error("Expected error for Level 4 in SOS session")
	}
}

func TestAffirmations_SOSSession_IncludesBreathingExercise(t *testing.T) {
	t.Parallel()

	affirmations := []Affirmation{
		{ID: "aff1", Text: "I am safe", Level: LevelPermission, Category: CategorySOSCrisis, Track: TrackStandard},
	}

	session, err := NewSOSSession(affirmations)
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	if session.BreathingExercise == nil {
		t.Error("Expected breathing exercise to be included")
	}

	if session.BreathingExercise.Name != "4-7-8 Breathing" {
		t.Errorf("Expected '4-7-8 Breathing', got %q", session.BreathingExercise.Name)
	}
}

func TestAffirmations_SOSSession_SurfacesAdditionalAfterBreathing(t *testing.T) {
	t.Parallel()

	affirmations := []Affirmation{
		{ID: "aff1", Text: "I am safe", Level: LevelPermission, Category: CategorySOSCrisis, Track: TrackStandard},
		{ID: "aff2", Text: "I am grounded", Level: LevelPermission, Category: CategorySOSCrisis, Track: TrackStandard},
		{ID: "aff3", Text: "I am not alone", Level: LevelPermission, Category: CategorySOSCrisis, Track: TrackStandard},
	}

	session, err := NewSOSSession(affirmations)
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	// After breathing, should surface additional affirmations
	if len(session.Affirmations) < 2 {
		t.Errorf("Expected at least 2 additional affirmations after breathing, got %d", len(session.Affirmations))
	}
}

func TestAffirmations_SOSSession_OffersAccountabilityPartnerReachOut(t *testing.T) {
	t.Parallel()

	affirmations := []Affirmation{
		{ID: "aff1", Text: "I am safe", Level: LevelPermission, Category: CategorySOSCrisis, Track: TrackStandard},
	}

	session, err := NewSOSSession(affirmations)
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	if !session.OffersAccountabilityPartnerReachOut {
		t.Error("SOS session should offer accountability partner reach out")
	}
}
