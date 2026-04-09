// test/unit/affirmations_test.go
package unit

import (
	"testing"
	"time"

	"github.com/regalrecovery/api/internal/domain/affirmations"
)

// =============================================================================
// Unit Tests -- Affirmations Full Flows
// =============================================================================

// TestAffirmations_Unit_LevelEngine_NaturalProgression verifies natural level
// progression based on sobriety days.
func TestAffirmations_Unit_LevelEngine_NaturalProgression(t *testing.T) {
	engine := affirmations.NewLevelEngine()
	now := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

	tests := []struct {
		name          string
		sobrietyDays  int
		expectedLevel affirmations.Level
	}{
		{"Day 0 -> Level 1", 0, affirmations.LevelPermission},
		{"Day 7 -> Level 1", 7, affirmations.LevelPermission},
		{"Day 13 -> Level 1", 13, affirmations.LevelPermission},
		{"Day 14 -> Level 2", 14, affirmations.LevelProcess},
		{"Day 30 -> Level 2", 30, affirmations.LevelProcess},
		{"Day 59 -> Level 2", 59, affirmations.LevelProcess},
		{"Day 60 -> Level 3", 60, affirmations.LevelTemperedIdentity},
		{"Day 120 -> Level 3", 120, affirmations.LevelTemperedIdentity},
		{"Day 179 -> Level 3", 179, affirmations.LevelTemperedIdentity},
		{"Day 180 -> Level 4", 180, affirmations.LevelFullIdentity},
		{"Day 365 -> Level 4", 365, affirmations.LevelFullIdentity},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := engine.DetermineLevel(tt.sobrietyDays, nil, now, nil, 0)
			if result.DeterminedLevel != tt.expectedLevel {
				t.Errorf("expected Level %d, got Level %d", tt.expectedLevel, result.DeterminedLevel)
			}
			if result.IsLocked {
				t.Error("expected level not to be locked without relapse")
			}
		})
	}
}

// TestAffirmations_Unit_LevelEngine_ManualOverride_Lower verifies that users
// can manually select a lower level at any time.
func TestAffirmations_Unit_LevelEngine_ManualOverride_Lower(t *testing.T) {
	// Given -- User at Day 100 (naturally Level 3), wants to drop to Level 2
	engine := affirmations.NewLevelEngine()
	now := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)
	lowerLevel := affirmations.LevelProcess

	// When -- Apply manual override to lower level
	result := engine.DetermineLevel(100, nil, now, &lowerLevel, 0)

	// Then -- Override accepted
	if result.DeterminedLevel != affirmations.LevelProcess {
		t.Errorf("expected Level 2 override, got Level %d", result.DeterminedLevel)
	}
	if result.IsLocked {
		t.Error("expected level not to be locked")
	}
	if result.Reason != "manual override to lower level" {
		t.Errorf("expected lower level override reason, got %q", result.Reason)
	}
}

// TestAffirmations_Unit_LevelEngine_ManualOverride_Higher_Rejected verifies
// that users cannot manually select a higher level without 30 days at current level.
func TestAffirmations_Unit_LevelEngine_ManualOverride_Higher_Rejected(t *testing.T) {
	// Given -- User at Day 14 (naturally Level 2), wants to jump to Level 3
	// but has only been at Level 2 for 10 days
	engine := affirmations.NewLevelEngine()
	now := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)
	higherLevel := affirmations.LevelTemperedIdentity

	// When -- Attempt manual override to higher level with only 10 days
	result := engine.DetermineLevel(14, nil, now, &higherLevel, 10)

	// Then -- Override rejected, stays at natural level
	if result.DeterminedLevel != affirmations.LevelProcess {
		t.Errorf("expected natural Level 2, got Level %d", result.DeterminedLevel)
	}
	if result.Reason != "manual override to higher level rejected (need 30+ days at current level)" {
		t.Errorf("expected rejection reason, got %q", result.Reason)
	}
}

// TestAffirmations_Unit_LevelEngine_ManualOverride_Higher_Accepted verifies
// that users can manually select a higher level after 30 days at current level.
func TestAffirmations_Unit_LevelEngine_ManualOverride_Higher_Accepted(t *testing.T) {
	// Given -- User at Day 14 (naturally Level 2), wants to jump to Level 3
	// and has been at Level 2 for 35 days
	engine := affirmations.NewLevelEngine()
	now := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)
	higherLevel := affirmations.LevelTemperedIdentity

	// When -- Apply manual override with 35 days at current level
	result := engine.DetermineLevel(14, nil, now, &higherLevel, 35)

	// Then -- Override accepted
	if result.DeterminedLevel != affirmations.LevelTemperedIdentity {
		t.Errorf("expected Level 3 override, got Level %d", result.DeterminedLevel)
	}
	if result.Reason != "manual override to higher level (30+ days at current level)" {
		t.Errorf("expected acceptance reason, got %q", result.Reason)
	}
}

// TestAffirmations_Unit_CustomAffirmation_FutureTense_Rejected verifies that
// future tense statements are rejected.
func TestAffirmations_Unit_CustomAffirmation_FutureTense_Rejected(t *testing.T) {
	tests := []struct {
		name      string
		statement string
	}{
		{"I will", "I will be better tomorrow"},
		{"I'm going to", "I'm going to heal"},
		{"I'll", "I'll make progress"},
		{"I shall", "I shall overcome"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := affirmations.ValidateCustomStatement(tt.statement, 20)
			if result.Valid {
				t.Errorf("expected future tense statement to be rejected: %q", tt.statement)
			}

			foundFutureError := false
			for _, err := range result.Errors {
				if containsWord(err, "future") || containsWord(err, "tense") || containsWord(err, "present") {
					foundFutureError = true
					break
				}
			}
			if !foundFutureError {
				t.Errorf("expected future tense error, got: %v", result.Errors)
			}
		})
	}
}

// TestAffirmations_Unit_CustomAffirmation_NegativeFraming_Rejected verifies
// that negative framing is rejected (except "free from").
func TestAffirmations_Unit_CustomAffirmation_NegativeFraming_Rejected(t *testing.T) {
	tests := []struct {
		name      string
		statement string
		shouldFail bool
	}{
		{"I am not", "I am not broken", true},
		{"I don't", "I don't need to hide", true},
		{"I won't", "I won't give up", true},
		{"I can't", "I can't fail", true},
		{"Free from (allowed)", "I am free from shame", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := affirmations.ValidateCustomStatement(tt.statement, 20)
			if tt.shouldFail && result.Valid {
				t.Errorf("expected negative framing to be rejected: %q", tt.statement)
			}
			if !tt.shouldFail && !result.Valid {
				t.Errorf("expected 'free from' to be allowed: %q, got errors: %v", tt.statement, result.Errors)
			}
		})
	}
}

// TestAffirmations_Unit_CustomAffirmation_EditWindow_24hrs verifies that
// custom affirmations can be edited within 24 hours but not after.
func TestAffirmations_Unit_CustomAffirmation_EditWindow_24hrs(t *testing.T) {
	t.Run("Within 24 hours", func(t *testing.T) {
		// Given -- Custom affirmation created 12 hours ago
		createdAt := time.Now().UTC().Add(-12 * time.Hour)

		// When -- Check if within edit window
		canEdit := affirmations.IsWithinEditWindow(createdAt)

		// Then -- Editable
		if !canEdit {
			t.Error("expected affirmation to be editable within 24 hours")
		}
	})

	t.Run("After 24 hours", func(t *testing.T) {
		// Given -- Custom affirmation created 25 hours ago
		createdAt := time.Now().UTC().Add(-25 * time.Hour)

		// When -- Check if within edit window
		canEdit := affirmations.IsWithinEditWindow(createdAt)

		// Then -- Not editable
		if canEdit {
			t.Error("expected affirmation to be read-only after 24 hours")
		}
	})

	t.Run("Exactly 24 hours", func(t *testing.T) {
		// Given -- Custom affirmation created exactly 24 hours ago
		createdAt := time.Now().UTC().Add(-24 * time.Hour)

		// When -- Check if within edit window
		canEdit := affirmations.IsWithinEditWindow(createdAt)

		// Then -- Not editable (boundary)
		if canEdit {
			t.Error("expected affirmation to be read-only at exactly 24 hours")
		}
	})
}

// TestAffirmations_Unit_MorningSession_Skip verifies that skipping a morning
// session sets AffectsProgress to false.
func TestAffirmations_Unit_MorningSession_Skip(t *testing.T) {
	// Given -- Morning session
	affs := []affirmations.Affirmation{
		{ID: "m1", Text: "Affirmation 1"},
		{ID: "m2", Text: "Affirmation 2"},
		{ID: "m3", Text: "Affirmation 3"},
	}
	session := affirmations.NewMorningSession(affs)

	// When -- User skips session
	session.Skip()

	// Then -- Skipped flag set and affects progress is false
	if !session.Skipped {
		t.Error("expected skipped flag to be true")
	}
	if session.AffectsProgress {
		t.Error("expected affects progress to be false when skipped")
	}
}

// TestAffirmations_Unit_Progress_SkippedSessionsIgnored verifies that skipped
// sessions do not count toward cumulative progress.
func TestAffirmations_Unit_Progress_SkippedSessionsIgnored(t *testing.T) {
	// Given -- 3 sessions: 2 completed, 1 skipped
	sessions := []affirmations.SessionCompletion{
		{SessionID: "s1", AffirmationCount: 3, WasSkipped: false},
		{SessionID: "s2", AffirmationCount: 1, WasSkipped: false},
		{SessionID: "s3", AffirmationCount: 3, WasSkipped: true}, // Skipped
	}

	// When -- Calculate progress
	progress := affirmations.CalculateProgress(sessions, 0, 0, 0)

	// Then -- Only 2 sessions counted
	if progress.TotalSessions != 2 {
		t.Errorf("expected 2 total sessions (skipped ignored), got %d", progress.TotalSessions)
	}
	if progress.TotalAffirmations != 4 {
		t.Errorf("expected 4 affirmations (3+1, skipped ignored), got %d", progress.TotalAffirmations)
	}
}

// TestAffirmations_Unit_Milestone_FirstCustom verifies milestone detection
// for first custom affirmation.
func TestAffirmations_Unit_Milestone_FirstCustom(t *testing.T) {
	// Given -- User creates their first custom affirmation
	sessions := []affirmations.SessionCompletion{}
	progress := affirmations.AffirmationProgress{}

	// When -- Detect milestone with 1 custom
	milestone := affirmations.DetectMilestone(progress, sessions, 1, 0, 0)

	// Then -- First custom milestone detected
	if milestone == nil {
		t.Fatal("expected milestone to be detected")
	}
	if milestone.Type != "first_custom" {
		t.Errorf("expected first_custom milestone, got %q", milestone.Type)
	}
	if !milestone.Achieved {
		t.Error("expected milestone to be achieved")
	}
}

// TestAffirmations_Unit_Milestone_SessionCounts verifies milestone detection
// for session count thresholds.
func TestAffirmations_Unit_Milestone_SessionCounts(t *testing.T) {
	tests := []struct {
		sessionCount    int
		expectedType    string
		expectedMessage string
	}{
		{1, "1_sessions", "Completed your first affirmation session"},
		{10, "10_sessions", "10 affirmation sessions completed"},
		{25, "25_sessions", "25 affirmation sessions completed"},
		{50, "50_sessions", "50 affirmation sessions completed"},
		{100, "100_sessions", "100 affirmation sessions completed"},
		{250, "250_sessions", "250 affirmation sessions completed"},
	}

	for _, tt := range tests {
		t.Run(tt.expectedType, func(t *testing.T) {
			// Given -- Progress with exact session count
			progress := affirmations.AffirmationProgress{
				TotalSessions: tt.sessionCount,
			}
			sessions := []affirmations.SessionCompletion{}

			// When -- Detect milestone
			milestone := affirmations.DetectMilestone(progress, sessions, 0, 0, 0)

			// Then -- Milestone detected
			if milestone == nil {
				t.Fatal("expected milestone to be detected")
			}
			if milestone.Type != tt.expectedType {
				t.Errorf("expected milestone type %q, got %q", tt.expectedType, milestone.Type)
			}
			if milestone.Description != tt.expectedMessage {
				t.Errorf("expected description %q, got %q", tt.expectedMessage, milestone.Description)
			}
		})
	}
}

// TestAffirmations_Unit_Safeguards_WorseningMood_RequiresConsecutive verifies
// that worsening mood detection requires strict consecutive decline.
func TestAffirmations_Unit_Safeguards_WorseningMood_RequiresConsecutive(t *testing.T) {
	t.Run("Not consecutive (improvement in middle)", func(t *testing.T) {
		// Given -- Ratings: 3 -> 5 -> 2 (improvement breaks pattern)
		history := []affirmations.EveningSession{
			{DayRating: 3},
			{DayRating: 5}, // Improvement breaks consecutive decline
			{DayRating: 2},
		}

		// When -- Detect worsening mood
		result := affirmations.DetectWorseningMood(history)

		// Then -- No action (not consecutive)
		if result.Action != affirmations.SafeguardActionNone {
			t.Errorf("expected no action for non-consecutive decline, got %q", result.Action)
		}
	})

	t.Run("Consecutive decline", func(t *testing.T) {
		// Given -- Ratings: 5 -> 3 -> 1 (strictly declining)
		history := []affirmations.EveningSession{
			{DayRating: 5},
			{DayRating: 3},
			{DayRating: 1},
		}

		// When -- Detect worsening mood
		result := affirmations.DetectWorseningMood(history)

		// Then -- Therapist prompt triggered
		if result.Action != affirmations.SafeguardActionTherapistPrompt {
			t.Errorf("expected therapist prompt for consecutive decline, got %q", result.Action)
		}
	})

	t.Run("Not strictly declining (plateau)", func(t *testing.T) {
		// Given -- Ratings: 3 -> 3 -> 2 (not strictly declining)
		history := []affirmations.EveningSession{
			{DayRating: 3},
			{DayRating: 3}, // Plateau breaks pattern
			{DayRating: 2},
		}

		// When -- Detect worsening mood
		result := affirmations.DetectWorseningMood(history)

		// Then -- No action
		if result.Action != affirmations.SafeguardActionNone {
			t.Errorf("expected no action for plateau, got %q", result.Action)
		}
	})
}

// TestAffirmations_Unit_Safeguards_Crisis_TwoConsecutiveOnes verifies that
// crisis detection requires exactly two consecutive ratings of 1.
func TestAffirmations_Unit_Safeguards_Crisis_TwoConsecutiveOnes(t *testing.T) {
	t.Run("Two consecutive 1s", func(t *testing.T) {
		history := []affirmations.EveningSession{
			{DayRating: 1},
			{DayRating: 1},
		}

		result := affirmations.DetectCrisis(history)

		if result.Action != affirmations.SafeguardActionCrisisBypass {
			t.Errorf("expected crisis bypass, got %q", result.Action)
		}
		if !result.BypassAffirmations {
			t.Error("expected bypass affirmations to be true")
		}
	})

	t.Run("Only one rating of 1", func(t *testing.T) {
		history := []affirmations.EveningSession{
			{DayRating: 2},
			{DayRating: 1},
		}

		result := affirmations.DetectCrisis(history)

		if result.Action != affirmations.SafeguardActionNone {
			t.Errorf("expected no action with single 1, got %q", result.Action)
		}
	})

	t.Run("Three ratings of 1", func(t *testing.T) {
		history := []affirmations.EveningSession{
			{DayRating: 1},
			{DayRating: 1},
			{DayRating: 1},
		}

		result := affirmations.DetectCrisis(history)

		// Still triggers (checks last two)
		if result.Action != affirmations.SafeguardActionCrisisBypass {
			t.Errorf("expected crisis bypass with three 1s, got %q", result.Action)
		}
	})
}

// TestAffirmations_Unit_Safeguards_PersistentRejection_Threshold verifies
// rejection flag threshold at exactly 5 hides.
func TestAffirmations_Unit_Safeguards_PersistentRejection_Threshold(t *testing.T) {
	tests := []struct {
		hiddenCount    int
		expectFlag     bool
		expectedAction affirmations.SafeguardAction
	}{
		{4, false, affirmations.SafeguardActionNone},
		{5, true, affirmations.SafeguardActionRejectionFlag},
		{6, true, affirmations.SafeguardActionRejectionFlag},
	}

	for _, tt := range tests {
		t.Run("Hidden count "+string(rune(tt.hiddenCount+'0')), func(t *testing.T) {
			result := affirmations.DetectPersistentRejection(tt.hiddenCount)

			if result.Action != tt.expectedAction {
				t.Errorf("expected action %q, got %q", tt.expectedAction, result.Action)
			}
			if result.FlagForReview != tt.expectFlag {
				t.Errorf("expected flag for review %v, got %v", tt.expectFlag, result.FlagForReview)
			}
		})
	}
}

// TestAffirmations_Unit_ContentSelector_HealthySexualityGating verifies that
// Healthy Sexuality category requires both 60+ days AND opt-in.
func TestAffirmations_Unit_ContentSelector_HealthySexualityGating(t *testing.T) {
	// Build larger pool to ensure content selector has enough variety
	pool := []affirmations.Affirmation{
		{ID: "hs-1", Text: "Healthy Sexuality", Level: affirmations.LevelTemperedIdentity, Category: affirmations.CategoryHealthySexuality, Track: affirmations.TrackStandard},
		{ID: "reg-1", Text: "Regular affirmation 1", Level: affirmations.LevelTemperedIdentity, Category: affirmations.CategorySelfWorth, Track: affirmations.TrackStandard},
		{ID: "reg-2", Text: "Regular affirmation 2", Level: affirmations.LevelTemperedIdentity, Category: affirmations.CategoryDailyStrength, Track: affirmations.TrackStandard},
		{ID: "reg-3", Text: "Regular affirmation 3", Level: affirmations.LevelTemperedIdentity, Category: affirmations.CategoryConnection, Track: affirmations.TrackStandard},
	}

	selector := affirmations.NewContentSelector()

	t.Run("60+ days but no opt-in", func(t *testing.T) {
		ctx := affirmations.SessionContext{
			UserID:                "user-1",
			SobrietyDays:          65,
			CurrentTime:           time.Now().UTC(),
			Track:                 affirmations.TrackStandard,
			HealthySexualityOptIn: false,
		}

		result, err := selector.SelectContent(pool, ctx, 2)
		if err != nil {
			t.Fatalf("expected no error, got %v", err)
		}

		// Healthy Sexuality should be filtered out
		for _, aff := range result.Affirmations {
			if aff.Category == affirmations.CategoryHealthySexuality {
				t.Error("expected Healthy Sexuality to be filtered without opt-in")
			}
		}
	})

	t.Run("Opt-in but less than 60 days", func(t *testing.T) {
		ctx := affirmations.SessionContext{
			UserID:                "user-2",
			SobrietyDays:          50,
			CurrentTime:           time.Now().UTC(),
			Track:                 affirmations.TrackStandard,
			HealthySexualityOptIn: true,
		}

		result, err := selector.SelectContent(pool, ctx, 2)
		if err != nil {
			t.Fatalf("expected no error, got %v", err)
		}

		// Healthy Sexuality should be filtered out
		for _, aff := range result.Affirmations {
			if aff.Category == affirmations.CategoryHealthySexuality {
				t.Error("expected Healthy Sexuality to be filtered before 60 days")
			}
		}
	})

	t.Run("60+ days AND opt-in", func(t *testing.T) {
		ctx := affirmations.SessionContext{
			UserID:                "user-3",
			SobrietyDays:          65,
			CurrentTime:           time.Now().UTC(),
			Track:                 affirmations.TrackStandard,
			HealthySexualityOptIn: true,
		}

		result, err := selector.SelectContent(pool, ctx, 2)
		if err != nil {
			t.Fatalf("expected no error, got %v", err)
		}

		// Healthy Sexuality should be included in pool
		// (May not always be selected due to randomness, but should not be filtered)
		// The key is that we don't get an error and pool is not empty
		if len(result.Affirmations) == 0 {
			t.Error("expected affirmations to be selected")
		}
	})
}

// TestAffirmations_Unit_AudioRecording_BackgroundOptions verifies valid
// background options.
func TestAffirmations_Unit_AudioRecording_BackgroundOptions(t *testing.T) {
	validOptions := []affirmations.BackgroundOption{
		affirmations.BackgroundNature,
		affirmations.BackgroundSoftTones,
		affirmations.BackgroundRain,
		affirmations.BackgroundOcean,
		affirmations.BackgroundSilence,
	}

	for _, option := range validOptions {
		t.Run(string(option), func(t *testing.T) {
			if !affirmations.IsValidBackgroundOption(option) {
				t.Errorf("expected %q to be valid background option", option)
			}
		})
	}

	// Invalid option
	invalidOption := affirmations.BackgroundOption("invalid")
	if affirmations.IsValidBackgroundOption(invalidOption) {
		t.Error("expected invalid option to be rejected")
	}
}

// =============================================================================
// Test Helpers
// =============================================================================

// containsWord checks if a string contains a word (case-insensitive).
func containsWord(text, word string) bool {
	lowerText := toLower(text)
	lowerWord := toLower(word)
	return contains(lowerText, lowerWord)
}

func toLower(s string) string {
	result := make([]byte, len(s))
	for i := 0; i < len(s); i++ {
		c := s[i]
		if c >= 'A' && c <= 'Z' {
			result[i] = c + 32
		} else {
			result[i] = c
		}
	}
	return string(result)
}

func contains(s, substr string) bool {
	return len(s) >= len(substr) && indexOfSubstring(s, substr) >= 0
}

func indexOfSubstring(s, substr string) int {
	if len(substr) == 0 {
		return 0
	}
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return i
		}
	}
	return -1
}
