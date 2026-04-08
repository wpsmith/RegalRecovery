// test/unit/affirmation_level_test.go
package unit

import (
	"testing"
	"time"

	"github.com/regalrecovery/api/internal/domain/affirmation"
)

// TestAffirmation_AFF_LV_AC1_Level1Access verifies Level 1 is available from day 0.
//
// Acceptance Criterion (AFF-LV-AC1): Level 1 affirmations available to all users from day 0.
func TestAffirmation_AFF_LV_AC1_Level1Access(t *testing.T) {
	level := affirmation.GetMaxLevel(0)
	if level != 1 {
		t.Errorf("expected level 1 for 0 days, got %d", level)
	}
}

// TestAffirmation_AFF_LV_AC2_Level2Unlock verifies Level 2 unlocks at 30+ cumulative days.
//
// Acceptance Criterion (AFF-LV-AC2): Level 2 requires 30+ cumulative sobriety days.
func TestAffirmation_AFF_LV_AC2_Level2Unlock(t *testing.T) {
	level := affirmation.GetMaxLevel(30)
	if level != 2 {
		t.Errorf("expected level 2 for 30 days, got %d", level)
	}
}

// TestAffirmation_AFF_LV_AC2_Level2Unlock_Below verifies 29 days is still Level 1.
func TestAffirmation_AFF_LV_AC2_Level2Unlock_Below(t *testing.T) {
	level := affirmation.GetMaxLevel(29)
	if level != 1 {
		t.Errorf("expected level 1 for 29 days, got %d", level)
	}
}

// TestAffirmation_AFF_LV_AC3_Level3Unlock verifies Level 3 unlocks at 90+ cumulative days.
//
// Acceptance Criterion (AFF-LV-AC3): Level 3 requires 90+ cumulative sobriety days.
func TestAffirmation_AFF_LV_AC3_Level3Unlock(t *testing.T) {
	level := affirmation.GetMaxLevel(90)
	if level != 3 {
		t.Errorf("expected level 3 for 90 days, got %d", level)
	}
}

// TestAffirmation_AFF_LV_AC3_Level3Unlock_Below verifies 89 days is still Level 2.
func TestAffirmation_AFF_LV_AC3_Level3Unlock_Below(t *testing.T) {
	level := affirmation.GetMaxLevel(89)
	if level != 2 {
		t.Errorf("expected level 2 for 89 days, got %d", level)
	}
}

// TestAffirmation_AFF_LV_AC4_PostRelapseLevel1Only verifies post-relapse restriction.
//
// Acceptance Criterion (AFF-LV-AC4): Post-relapse, only Level 1 for 24 hours.
func TestAffirmation_AFF_LV_AC4_PostRelapseLevel1Only(t *testing.T) {
	resetAt := time.Now().Add(-12 * time.Hour) // 12 hours ago
	level := affirmation.GetEffectiveMaxLevel(120, &resetAt, false)
	if level != 1 {
		t.Errorf("expected level 1 within 24h of relapse, got %d", level)
	}
}

// TestAffirmation_AFF_LV_AC4_PostRelapseLevel1Only_After24h verifies restriction lifts after 24h.
func TestAffirmation_AFF_LV_AC4_PostRelapseLevel1Only_After24h(t *testing.T) {
	resetAt := time.Now().Add(-25 * time.Hour) // 25 hours ago
	level := affirmation.GetEffectiveMaxLevel(120, &resetAt, false)
	if level != 3 {
		t.Errorf("expected level 3 after 24h post-relapse, got %d", level)
	}
}

// TestAffirmation_AFF_LV_AC5_SOSModeMaxLevel2 verifies SOS mode caps at Level 2.
//
// Acceptance Criterion (AFF-LV-AC5): SOS mode never above Level 2.
func TestAffirmation_AFF_LV_AC5_SOSModeMaxLevel2(t *testing.T) {
	level := affirmation.GetEffectiveMaxLevel(120, nil, true)
	if level != 2 {
		t.Errorf("expected level 2 in SOS mode with 120 days, got %d", level)
	}
}

// TestAffirmation_AFF_LV_AC5_SOSModeMaxLevel2_Level1User verifies SOS does not upgrade level.
func TestAffirmation_AFF_LV_AC5_SOSModeMaxLevel2_Level1User(t *testing.T) {
	level := affirmation.GetEffectiveMaxLevel(10, nil, true)
	if level != 1 {
		t.Errorf("expected level 1 in SOS mode with 10 days, got %d", level)
	}
}

// TestAffirmation_AFF_LV_AC6_CumulativeNotStreak verifies cumulative days, not streak, determine level.
//
// Acceptance Criterion (AFF-LV-AC6): Level unlocks use cumulative days, NOT streak-based.
func TestAffirmation_AFF_LV_AC6_CumulativeNotStreak(t *testing.T) {
	// User has 45 cumulative days across multiple streaks (20 + 15 + 10)
	// Current streak is only 10, but cumulative is 45
	level := affirmation.GetMaxLevel(45)
	if level != 2 {
		t.Errorf("expected level 2 for 45 cumulative days, got %d", level)
	}
}

// TestAffirmation_AFF_LV_AC7_HealthySexualityOptIn_NotOptedIn verifies HS is inaccessible without opt-in.
//
// Acceptance Criterion (AFF-LV-AC7): Healthy Sexuality requires explicit opt-in.
func TestAffirmation_AFF_LV_AC7_HealthySexualityOptIn_NotOptedIn(t *testing.T) {
	accessible := affirmation.IsHealthySexualityAccessible(90, false)
	if accessible {
		t.Error("expected HS to be inaccessible without opt-in")
	}
}

// TestAffirmation_AFF_LV_AC7_HealthySexualityOptIn_OptedIn verifies HS is accessible with opt-in and 60+ days.
func TestAffirmation_AFF_LV_AC7_HealthySexualityOptIn_OptedIn(t *testing.T) {
	accessible := affirmation.IsHealthySexualityAccessible(90, true)
	if !accessible {
		t.Error("expected HS to be accessible with 90 days and opt-in")
	}
}

// TestAffirmation_AFF_LV_AC7_HealthySexualityOptIn_InsufficientDays verifies HS is inaccessible below 60 days.
func TestAffirmation_AFF_LV_AC7_HealthySexualityOptIn_InsufficientDays(t *testing.T) {
	accessible := affirmation.IsHealthySexualityAccessible(55, true)
	if accessible {
		t.Error("expected HS to be inaccessible with only 55 days even with opt-in")
	}
}

// TestAffirmation_AFF_DM_AC8_HealthySexualityGating verifies HS category is excluded from filtering.
//
// Acceptance Criterion (AFF-DM-AC8): healthySexuality category OFF by default.
func TestAffirmation_AFF_DM_AC8_HealthySexualityGating(t *testing.T) {
	affirmations := []affirmation.Affirmation{
		{AffirmationID: "aff_001", Category: affirmation.CategoryIdentity, Level: 1},
		{AffirmationID: "aff_002", Category: affirmation.CategoryRecovery, Level: 1},
		{AffirmationID: "aff_051", Category: affirmation.CategoryHealthySexuality, Level: 3},
	}

	filtered := affirmation.FilterByLevel(affirmations, 3, false)
	for _, a := range filtered {
		if a.Category == affirmation.CategoryHealthySexuality {
			t.Error("expected healthySexuality to be excluded when hsAccessible=false")
		}
	}
	if len(filtered) != 2 {
		t.Errorf("expected 2 affirmations after filtering, got %d", len(filtered))
	}
}

// TestAffirmation_AFF_DM_AC8_HealthySexualityGating_Accessible verifies HS is included when accessible.
func TestAffirmation_AFF_DM_AC8_HealthySexualityGating_Accessible(t *testing.T) {
	affirmations := []affirmation.Affirmation{
		{AffirmationID: "aff_001", Category: affirmation.CategoryIdentity, Level: 1},
		{AffirmationID: "aff_051", Category: affirmation.CategoryHealthySexuality, Level: 3},
	}

	filtered := affirmation.FilterByLevel(affirmations, 3, true)
	if len(filtered) != 2 {
		t.Errorf("expected 2 affirmations when HS accessible, got %d", len(filtered))
	}
}
