// internal/domain/affirmations/content_selector_test.go
package affirmations

import (
	"testing"
	"time"
)

// =============================================================================
// Content Selector Tests — Affirmations Feature
// =============================================================================

// Helper function to create test affirmations
func createTestAffirmation(id string, level Level, category Category, track Track, coreBeliefs []CoreBelief) Affirmation {
	return Affirmation{
		ID:            id,
		Text:          "Test affirmation " + id,
		Level:         level,
		CoreBeliefs:   coreBeliefs,
		Category:      category,
		Track:         track,
		RecoveryStage: RecoveryStageEarly,
		IsFavorite:    false,
		IsHidden:      false,
		CreatedAt:     time.Now(),
		ModifiedAt:    time.Now(),
	}
}

// TestAffirmations_ContentSelector_80PercentCurrentLevel verifies that
// 80% of selected affirmations are from the user's current level.
//
// Acceptance Criterion: Session structure serves 80% same-level affirmations.
func TestAffirmations_ContentSelector_80PercentCurrentLevel(t *testing.T) {
	t.Run("selects_80_percent_current_level", func(t *testing.T) {
		// Given
		selector := NewContentSelector()

		// Create a pool with 10 affirmations at each level
		var pool []Affirmation
		for i := 1; i <= 10; i++ {
			pool = append(pool, createTestAffirmation("L2-"+string(rune(i)), LevelProcess, CategorySelfWorth, TrackStandard, []CoreBelief{CoreBelief1}))
			pool = append(pool, createTestAffirmation("L3-"+string(rune(i)), LevelTemperedIdentity, CategorySelfWorth, TrackStandard, []CoreBelief{CoreBelief1}))
		}

		ctx := SessionContext{
			UserID:               "user1",
			SobrietyDays:         30, // Level 2
			CurrentTime:          time.Now(),
			Track:                TrackStandard,
			SessionType:          SessionTypeMorning,
		}

		// When - request 10 affirmations
		result, err := selector.SelectContent(pool, ctx, 10)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		level2Count := 0
		level3Count := 0
		for _, aff := range result.Affirmations {
			if aff.Level == LevelProcess {
				level2Count++
			} else if aff.Level == LevelTemperedIdentity {
				level3Count++
			}
		}

		// Expect ~8 from Level 2, ~2 from Level 3
		if level2Count < 7 || level2Count > 9 {
			t.Errorf("expected 7-9 Level 2 affirmations (80%% of 10), got %d", level2Count)
		}
		if level3Count < 1 || level3Count > 3 {
			t.Errorf("expected 1-3 Level 3 affirmations (20%% of 10), got %d", level3Count)
		}
	})
}

// TestAffirmations_ContentSelector_20PercentNextLevel verifies that
// 20% of selected affirmations are from one level above current.
//
// Acceptance Criterion: Session structure serves 20% one level above.
func TestAffirmations_ContentSelector_20PercentNextLevel(t *testing.T) {
	t.Run("selects_20_percent_next_level", func(t *testing.T) {
		// Given
		selector := NewContentSelector()

		// Create a pool with affirmations at Level 1 and Level 2
		var pool []Affirmation
		for i := 1; i <= 20; i++ {
			pool = append(pool, createTestAffirmation("L1-"+string(rune(i)), LevelPermission, CategorySelfWorth, TrackStandard, []CoreBelief{CoreBelief1}))
			pool = append(pool, createTestAffirmation("L2-"+string(rune(i)), LevelProcess, CategorySelfWorth, TrackStandard, []CoreBelief{CoreBelief1}))
		}

		ctx := SessionContext{
			UserID:       "user1",
			SobrietyDays: 5, // Level 1
			CurrentTime:  time.Now(),
			Track:        TrackStandard,
			SessionType:  SessionTypeMorning,
		}

		// When - request 10 affirmations
		result, err := selector.SelectContent(pool, ctx, 10)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		level1Count := 0
		level2Count := 0
		for _, aff := range result.Affirmations {
			if aff.Level == LevelPermission {
				level1Count++
			} else if aff.Level == LevelProcess {
				level2Count++
			}
		}

		// Expect ~8 from Level 1, ~2 from Level 2
		if level1Count < 7 || level1Count > 9 {
			t.Errorf("expected 7-9 Level 1 affirmations (80%% of 10), got %d", level1Count)
		}
		if level2Count < 1 || level2Count > 3 {
			t.Errorf("expected 1-3 Level 2 affirmations (20%% of 10), got %d", level2Count)
		}
	})
}

// TestAffirmations_ContentSelector_NoRepeatWithin7Days verifies that
// affirmations shown in the last 7 days are not repeated (except favorites).
//
// Acceptance Criterion: No repeat within 7 days (except favorites).
func TestAffirmations_ContentSelector_NoRepeatWithin7Days(t *testing.T) {
	t.Run("excludes_recently_shown_affirmations", func(t *testing.T) {
		// Given
		selector := NewContentSelector()

		var pool []Affirmation
		for i := 1; i <= 20; i++ {
			pool = append(pool, createTestAffirmation("L2-"+string(rune(i)), LevelProcess, CategorySelfWorth, TrackStandard, []CoreBelief{CoreBelief1}))
		}

		recentIDs := []string{"L2-\x01", "L2-\x02", "L2-\x03"}

		ctx := SessionContext{
			UserID:               "user1",
			SobrietyDays:         30, // Level 2
			CurrentTime:          time.Now(),
			Track:                TrackStandard,
			RecentAffirmationIDs: recentIDs,
			SessionType:          SessionTypeMorning,
		}

		// When
		result, err := selector.SelectContent(pool, ctx, 5)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		for _, aff := range result.Affirmations {
			for _, recentID := range recentIDs {
				if aff.ID == recentID {
					t.Errorf("affirmation %s was recently shown and should be excluded", aff.ID)
				}
			}
		}
	})
}

// TestAffirmations_ContentSelector_FavoritesPrioritized verifies that
// favorite affirmations are prioritized in selection and can repeat within 7 days.
//
// Acceptance Criterion: Favorites prioritized and can repeat.
func TestAffirmations_ContentSelector_FavoritesPrioritized(t *testing.T) {
	t.Run("prioritizes_favorites", func(t *testing.T) {
		// Given
		selector := NewContentSelector()

		var pool []Affirmation
		for i := 1; i <= 10; i++ {
			aff := createTestAffirmation("L2-"+string(rune(i)), LevelProcess, CategorySelfWorth, TrackStandard, []CoreBelief{CoreBelief1})
			if i <= 3 {
				aff.IsFavorite = true
			}
			pool = append(pool, aff)
		}

		favoriteIDs := []string{"L2-\x01", "L2-\x02", "L2-\x03"}

		ctx := SessionContext{
			UserID:       "user1",
			SobrietyDays: 30, // Level 2
			CurrentTime:  time.Now(),
			Track:        TrackStandard,
			FavoriteIDs:  favoriteIDs,
			SessionType:  SessionTypeMorning,
		}

		// When
		result, err := selector.SelectContent(pool, ctx, 5)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		favoriteCount := 0
		for _, aff := range result.Affirmations {
			if aff.IsFavorite {
				favoriteCount++
			}
		}

		// Expect at least some favorites in the selection
		if favoriteCount == 0 {
			t.Error("expected at least one favorite in selection")
		}
	})

	t.Run("favorites_can_repeat_within_7_days", func(t *testing.T) {
		// Given
		selector := NewContentSelector()

		var pool []Affirmation
		for i := 1; i <= 10; i++ {
			aff := createTestAffirmation("L2-"+string(rune(i)), LevelProcess, CategorySelfWorth, TrackStandard, []CoreBelief{CoreBelief1})
			if i == 1 {
				aff.IsFavorite = true
			}
			pool = append(pool, aff)
		}

		favoriteID := "L2-\x01"

		ctx := SessionContext{
			UserID:               "user1",
			SobrietyDays:         30, // Level 2
			CurrentTime:          time.Now(),
			Track:                TrackStandard,
			FavoriteIDs:          []string{favoriteID},
			RecentAffirmationIDs: []string{favoriteID}, // was shown recently
			SessionType:          SessionTypeMorning,
		}

		// When
		result, err := selector.SelectContent(pool, ctx, 3)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		// Favorite can appear even though it's in recent list
		foundFavorite := false
		for _, aff := range result.Affirmations {
			if aff.ID == favoriteID {
				foundFavorite = true
			}
		}

		if !foundFavorite {
			t.Error("expected favorite to be included despite being in recent list")
		}
	})
}

// TestAffirmations_ContentSelector_HiddenExcluded verifies that
// hidden affirmations are never surfaced.
//
// Acceptance Criterion: Hidden affirmations excluded from selection.
func TestAffirmations_ContentSelector_HiddenExcluded(t *testing.T) {
	t.Run("excludes_hidden_affirmations", func(t *testing.T) {
		// Given
		selector := NewContentSelector()

		var pool []Affirmation
		for i := 1; i <= 10; i++ {
			aff := createTestAffirmation("L2-"+string(rune(i)), LevelProcess, CategorySelfWorth, TrackStandard, []CoreBelief{CoreBelief1})
			if i <= 3 {
				aff.IsHidden = true
			}
			pool = append(pool, aff)
		}

		hiddenIDs := []string{"L2-\x01", "L2-\x02", "L2-\x03"}

		ctx := SessionContext{
			UserID:       "user1",
			SobrietyDays: 30, // Level 2
			CurrentTime:  time.Now(),
			Track:        TrackStandard,
			HiddenIDs:    hiddenIDs,
			SessionType:  SessionTypeMorning,
		}

		// When
		result, err := selector.SelectContent(pool, ctx, 5)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		for _, aff := range result.Affirmations {
			for _, hiddenID := range hiddenIDs {
				if aff.ID == hiddenID {
					t.Errorf("hidden affirmation %s should never be selected", aff.ID)
				}
			}
		}
	})
}

// TestAffirmations_ContentSelector_HealthySexualityGated_Under60Days verifies that
// Healthy Sexuality category is not surfaced for users under 60 days.
//
// Acceptance Criterion: Healthy Sexuality gated until 60+ days.
func TestAffirmations_ContentSelector_HealthySexualityGated_Under60Days(t *testing.T) {
	t.Run("excludes_healthy_sexuality_under_60_days", func(t *testing.T) {
		// Given
		selector := NewContentSelector()

		var pool []Affirmation
		pool = append(pool, createTestAffirmation("HS1", LevelProcess, CategoryHealthySexuality, TrackStandard, []CoreBelief{CoreBelief4}))
		pool = append(pool, createTestAffirmation("SW1", LevelProcess, CategorySelfWorth, TrackStandard, []CoreBelief{CoreBelief1}))
		pool = append(pool, createTestAffirmation("SW2", LevelProcess, CategorySelfWorth, TrackStandard, []CoreBelief{CoreBelief1}))

		ctx := SessionContext{
			UserID:                "user1",
			SobrietyDays:          30, // under 60 days
			CurrentTime:           time.Now(),
			Track:                 TrackStandard,
			HealthySexualityOptIn: true, // even with opt-in, should be blocked
			SessionType:           SessionTypeMorning,
		}

		// When
		result, err := selector.SelectContent(pool, ctx, 2)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		for _, aff := range result.Affirmations {
			if aff.Category == CategoryHealthySexuality {
				t.Error("Healthy Sexuality should not be selected for users under 60 days")
			}
		}
	})
}

// TestAffirmations_ContentSelector_HealthySexualityGated_NoOptIn verifies that
// Healthy Sexuality category requires explicit opt-in.
//
// Acceptance Criterion: Healthy Sexuality requires opt-in even at 60+ days.
func TestAffirmations_ContentSelector_HealthySexualityGated_NoOptIn(t *testing.T) {
	t.Run("excludes_healthy_sexuality_without_optin", func(t *testing.T) {
		// Given
		selector := NewContentSelector()

		var pool []Affirmation
		pool = append(pool, createTestAffirmation("HS1", LevelTemperedIdentity, CategoryHealthySexuality, TrackStandard, []CoreBelief{CoreBelief4}))
		pool = append(pool, createTestAffirmation("SW1", LevelTemperedIdentity, CategorySelfWorth, TrackStandard, []CoreBelief{CoreBelief1}))
		pool = append(pool, createTestAffirmation("SW2", LevelTemperedIdentity, CategorySelfWorth, TrackStandard, []CoreBelief{CoreBelief1}))

		ctx := SessionContext{
			UserID:                "user1",
			SobrietyDays:          90, // 60+ days
			CurrentTime:           time.Now(),
			Track:                 TrackStandard,
			HealthySexualityOptIn: false, // no opt-in
			SessionType:           SessionTypeMorning,
		}

		// When
		result, err := selector.SelectContent(pool, ctx, 2)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		for _, aff := range result.Affirmations {
			if aff.Category == CategoryHealthySexuality {
				t.Error("Healthy Sexuality should not be selected without opt-in")
			}
		}
	})
}

// TestAffirmations_ContentSelector_HealthySexualityGated_OptInAfter60Days verifies that
// Healthy Sexuality category is available with opt-in after 60 days.
//
// Acceptance Criterion: Healthy Sexuality available with 60+ days AND opt-in.
func TestAffirmations_ContentSelector_HealthySexualityGated_OptInAfter60Days(t *testing.T) {
	t.Run("includes_healthy_sexuality_with_optin_and_60plus_days", func(t *testing.T) {
		// Given
		selector := NewContentSelector()

		var pool []Affirmation
		for i := 1; i <= 5; i++ {
			pool = append(pool, createTestAffirmation("HS"+string(rune(i)), LevelTemperedIdentity, CategoryHealthySexuality, TrackStandard, []CoreBelief{CoreBelief4}))
		}

		ctx := SessionContext{
			UserID:                "user1",
			SobrietyDays:          90, // 60+ days
			CurrentTime:           time.Now(),
			Track:                 TrackStandard,
			HealthySexualityOptIn: true, // opt-in enabled
			SessionType:           SessionTypeMorning,
		}

		// When
		result, err := selector.SelectContent(pool, ctx, 3)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if len(result.Affirmations) == 0 {
			t.Error("expected Healthy Sexuality affirmations to be selected with opt-in and 60+ days")
		}

		for _, aff := range result.Affirmations {
			if aff.Category != CategoryHealthySexuality {
				t.Error("expected only Healthy Sexuality affirmations in this pool")
			}
		}
	})
}

// TestAffirmations_ContentSelector_FaithBasedTrackFiltering verifies that
// faith-based track users receive faith-based content.
//
// Acceptance Criterion: Track filtering matches user preference.
func TestAffirmations_ContentSelector_FaithBasedTrackFiltering(t *testing.T) {
	t.Run("selects_only_faith_based_content", func(t *testing.T) {
		// Given
		selector := NewContentSelector()

		var pool []Affirmation
		for i := 1; i <= 5; i++ {
			pool = append(pool, createTestAffirmation("FB"+string(rune(i)), LevelProcess, CategorySelfWorth, TrackFaithBased, []CoreBelief{CoreBelief1}))
			pool = append(pool, createTestAffirmation("ST"+string(rune(i)), LevelProcess, CategorySelfWorth, TrackStandard, []CoreBelief{CoreBelief1}))
		}

		ctx := SessionContext{
			UserID:       "user1",
			SobrietyDays: 30, // Level 2
			CurrentTime:  time.Now(),
			Track:        TrackFaithBased,
			SessionType:  SessionTypeMorning,
		}

		// When
		result, err := selector.SelectContent(pool, ctx, 3)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		for _, aff := range result.Affirmations {
			if aff.Track != TrackFaithBased {
				t.Errorf("expected faith-based track, got %s", aff.Track)
			}
		}
	})
}

// TestAffirmations_ContentSelector_StandardTrackFiltering verifies that
// standard track users receive standard content.
//
// Acceptance Criterion: Track filtering matches user preference.
func TestAffirmations_ContentSelector_StandardTrackFiltering(t *testing.T) {
	t.Run("selects_only_standard_content", func(t *testing.T) {
		// Given
		selector := NewContentSelector()

		var pool []Affirmation
		for i := 1; i <= 5; i++ {
			pool = append(pool, createTestAffirmation("ST"+string(rune(i)), LevelProcess, CategorySelfWorth, TrackStandard, []CoreBelief{CoreBelief1}))
			pool = append(pool, createTestAffirmation("FB"+string(rune(i)), LevelProcess, CategorySelfWorth, TrackFaithBased, []CoreBelief{CoreBelief1}))
		}

		ctx := SessionContext{
			UserID:       "user1",
			SobrietyDays: 30, // Level 2
			CurrentTime:  time.Now(),
			Track:        TrackStandard,
			SessionType:  SessionTypeMorning,
		}

		// When
		result, err := selector.SelectContent(pool, ctx, 3)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		for _, aff := range result.Affirmations {
			if aff.Track != TrackStandard {
				t.Errorf("expected standard track, got %s", aff.Track)
			}
		}
	})
}

// TestAffirmations_ContentSelector_CoreBeliefCoverageAcrossSessions verifies that
// over multiple sessions, all 4 Carnes core beliefs are addressed.
//
// Acceptance Criterion: Core belief coverage across sessions.
func TestAffirmations_ContentSelector_CoreBeliefCoverageAcrossSessions(t *testing.T) {
	t.Run("covers_all_core_beliefs_over_sessions", func(t *testing.T) {
		// Given
		selector := NewContentSelector()

		var pool []Affirmation
		pool = append(pool, createTestAffirmation("CB1", LevelProcess, CategorySelfWorth, TrackStandard, []CoreBelief{CoreBelief1}))
		pool = append(pool, createTestAffirmation("CB2", LevelProcess, CategoryHealthyRelationships, TrackStandard, []CoreBelief{CoreBelief2}))
		pool = append(pool, createTestAffirmation("CB3", LevelProcess, CategoryConnection, TrackStandard, []CoreBelief{CoreBelief3}))
		pool = append(pool, createTestAffirmation("CB4", LevelProcess, CategoryPurpose, TrackStandard, []CoreBelief{CoreBelief4}))

		ctx := SessionContext{
			UserID:       "user1",
			SobrietyDays: 30,
			CurrentTime:  time.Now(),
			Track:        TrackStandard,
			SessionType:  SessionTypeMorning,
		}

		// When - simulate multiple sessions
		coreBeliefsSeen := make(map[CoreBelief]bool)
		for session := 0; session < 10; session++ {
			result, err := selector.SelectContent(pool, ctx, 1)
			if err != nil {
				t.Fatalf("unexpected error in session %d: %v", session, err)
			}
			for _, aff := range result.Affirmations {
				for _, cb := range aff.CoreBeliefs {
					coreBeliefsSeen[cb] = true
				}
			}
		}

		// Then - all 4 core beliefs should be seen
		if len(coreBeliefsSeen) < 4 {
			t.Errorf("expected all 4 core beliefs to be covered, got %d", len(coreBeliefsSeen))
		}
	})
}

// TestAffirmations_ContentSelector_CategoryVarietyInSession verifies that
// affirmations in a single session span multiple categories when possible.
//
// Acceptance Criterion: Category variety within session.
func TestAffirmations_ContentSelector_CategoryVarietyInSession(t *testing.T) {
	t.Run("includes_variety_of_categories", func(t *testing.T) {
		// Given
		selector := NewContentSelector()

		var pool []Affirmation
		pool = append(pool, createTestAffirmation("SW1", LevelProcess, CategorySelfWorth, TrackStandard, []CoreBelief{CoreBelief1}))
		pool = append(pool, createTestAffirmation("SR1", LevelProcess, CategoryShameResilience, TrackStandard, []CoreBelief{CoreBelief1}))
		pool = append(pool, createTestAffirmation("CN1", LevelProcess, CategoryConnection, TrackStandard, []CoreBelief{CoreBelief3}))
		pool = append(pool, createTestAffirmation("DS1", LevelProcess, CategoryDailyStrength, TrackStandard, []CoreBelief{CoreBelief1}))

		ctx := SessionContext{
			UserID:       "user1",
			SobrietyDays: 30,
			CurrentTime:  time.Now(),
			Track:        TrackStandard,
			SessionType:  SessionTypeMorning,
		}

		// When
		result, err := selector.SelectContent(pool, ctx, 3)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		categorySeen := make(map[Category]bool)
		for _, aff := range result.Affirmations {
			categorySeen[aff.Category] = true
		}

		// Expect at least 2 different categories in 3 affirmations
		if len(categorySeen) < 2 {
			t.Errorf("expected variety (2+ categories), got %d", len(categorySeen))
		}
	})
}
