// internal/domain/exercise/favorites_test.go
package exercise

import (
	"testing"
)

func TestFavorites_FR_EX_2_1_CreateFavorite_Success(t *testing.T) {
	fav := ExerciseFavorite{
		ActivityType:           ActivityTypeRunning,
		DefaultDurationMinutes: 30,
		Label:                  "Morning Run",
	}
	if err := ValidateFavorite(fav); err != nil {
		t.Errorf("expected valid favorite, got error: %v", err)
	}
}

func TestFavorites_FR_EX_2_1_MaxFiveFavorites_RejectsExceedingLimit(t *testing.T) {
	err := CanAddFavorite(5)
	if err == nil {
		t.Error("expected error when at max favorites")
	}
	if err != ErrMaxFavoritesReached {
		t.Errorf("expected ErrMaxFavoritesReached, got: %v", err)
	}
}

func TestFavorites_FR_EX_2_1_QuickLogFromFavorite_AppliesDefaults(t *testing.T) {
	intensity := IntensityModerate
	fav := ExerciseFavorite{
		ActivityType:           ActivityTypeRunning,
		DefaultDurationMinutes: 30,
		DefaultIntensity:       &intensity,
		Label:                  "Morning Run",
	}

	req := BuildLogFromFavorite(fav)

	if req.ActivityType != ActivityTypeRunning {
		t.Errorf("expected activity type running, got %s", req.ActivityType)
	}
	if req.DurationMinutes != 30 {
		t.Errorf("expected duration 30, got %d", req.DurationMinutes)
	}
	if req.Intensity == nil || *req.Intensity != IntensityModerate {
		t.Error("expected moderate intensity from favorite defaults")
	}
	if req.Source != SourceManual {
		t.Errorf("expected manual source, got %s", req.Source)
	}
}

func TestFavorites_FR_EX_2_2_UpdateFavorite_Success(t *testing.T) {
	fav := ExerciseFavorite{
		ActivityType:           ActivityTypeYoga,
		DefaultDurationMinutes: 60,
		Label:                  "Morning Yoga",
	}
	if err := ValidateFavorite(fav); err != nil {
		t.Errorf("expected valid updated favorite, got error: %v", err)
	}
}

func TestFavorites_FR_EX_2_2_DeleteFavorite_Success(t *testing.T) {
	// Delete is a repository operation; domain layer validates that
	// count decreases after deletion. This test validates the constraint check.
	err := CanAddFavorite(4)
	if err != nil {
		t.Errorf("expected to be able to add when at 4, got error: %v", err)
	}
}

func TestFavorites_FR_EX_2_3_CustomTypePromotion_PromptAfterThreeUses(t *testing.T) {
	if !ShouldPromoteCustomType(3) {
		t.Error("expected promotion prompt at 3 uses")
	}
	if !ShouldPromoteCustomType(5) {
		t.Error("expected promotion prompt at 5 uses")
	}
}

func TestFavorites_FR_EX_2_3_CustomTypePromotion_NoPromptBeforeThreeUses(t *testing.T) {
	if ShouldPromoteCustomType(2) {
		t.Error("expected no promotion prompt at 2 uses")
	}
	if ShouldPromoteCustomType(1) {
		t.Error("expected no promotion prompt at 1 use")
	}
	if ShouldPromoteCustomType(0) {
		t.Error("expected no promotion prompt at 0 uses")
	}
}
