// internal/domain/affirmations/level_test.go
package affirmations

import (
	"testing"
	"time"
)

// =============================================================================
// Level Engine Tests — Affirmations Feature
// =============================================================================

// TestAffirmations_LevelEngine_DeterminesLevel1_Days0to13 verifies Level 1 (Permission)
// is assigned for Days 0-13 of sobriety.
//
// Acceptance Criterion: Users in Days 0-13 receive Level 1 affirmations.
func TestAffirmations_LevelEngine_DeterminesLevel1_Days0to13(t *testing.T) {
	t.Run("day_0_returns_level_1", func(t *testing.T) {
		// Given
		engine := NewLevelEngine()
		sobrietyDays := 0
		lastRelapseTimestamp := time.Now().Add(-1 * time.Hour)
		currentTime := time.Now()
		manualOverride := (*Level)(nil)
		daysSinceLastLevelChange := 0

		// When
		result := engine.DetermineLevel(sobrietyDays, &lastRelapseTimestamp, currentTime, manualOverride, daysSinceLastLevelChange)

		// Then
		if result.DeterminedLevel != LevelPermission {
			t.Errorf("expected Level 1 (Permission) for day 0, got Level %d", result.DeterminedLevel)
		}
	})

	t.Run("day_7_returns_level_1", func(t *testing.T) {
		// Given
		engine := NewLevelEngine()
		sobrietyDays := 7
		var lastRelapseTimestamp *time.Time = nil
		currentTime := time.Now()
		manualOverride := (*Level)(nil)
		daysSinceLastLevelChange := 0

		// When
		result := engine.DetermineLevel(sobrietyDays, lastRelapseTimestamp, currentTime, manualOverride, daysSinceLastLevelChange)

		// Then
		if result.DeterminedLevel != LevelPermission {
			t.Errorf("expected Level 1 (Permission) for day 7, got Level %d", result.DeterminedLevel)
		}
	})

	t.Run("day_13_returns_level_1", func(t *testing.T) {
		// Given
		engine := NewLevelEngine()
		sobrietyDays := 13
		var lastRelapseTimestamp *time.Time = nil
		currentTime := time.Now()
		manualOverride := (*Level)(nil)
		daysSinceLastLevelChange := 0

		// When
		result := engine.DetermineLevel(sobrietyDays, lastRelapseTimestamp, currentTime, manualOverride, daysSinceLastLevelChange)

		// Then
		if result.DeterminedLevel != LevelPermission {
			t.Errorf("expected Level 1 (Permission) for day 13, got Level %d", result.DeterminedLevel)
		}
	})
}

// TestAffirmations_LevelEngine_DeterminesLevel2_Days14to59 verifies Level 2 (Process)
// is assigned for Days 14-59 of sobriety.
//
// Acceptance Criterion: Users in Days 14-59 receive Level 2 affirmations.
func TestAffirmations_LevelEngine_DeterminesLevel2_Days14to59(t *testing.T) {
	t.Run("day_14_returns_level_2", func(t *testing.T) {
		// Given
		engine := NewLevelEngine()
		sobrietyDays := 14
		var lastRelapseTimestamp *time.Time = nil
		currentTime := time.Now()
		manualOverride := (*Level)(nil)
		daysSinceLastLevelChange := 0

		// When
		result := engine.DetermineLevel(sobrietyDays, lastRelapseTimestamp, currentTime, manualOverride, daysSinceLastLevelChange)

		// Then
		if result.DeterminedLevel != LevelProcess {
			t.Errorf("expected Level 2 (Process) for day 14, got Level %d", result.DeterminedLevel)
		}
	})

	t.Run("day_30_returns_level_2", func(t *testing.T) {
		// Given
		engine := NewLevelEngine()
		sobrietyDays := 30
		var lastRelapseTimestamp *time.Time = nil
		currentTime := time.Now()
		manualOverride := (*Level)(nil)
		daysSinceLastLevelChange := 0

		// When
		result := engine.DetermineLevel(sobrietyDays, lastRelapseTimestamp, currentTime, manualOverride, daysSinceLastLevelChange)

		// Then
		if result.DeterminedLevel != LevelProcess {
			t.Errorf("expected Level 2 (Process) for day 30, got Level %d", result.DeterminedLevel)
		}
	})

	t.Run("day_59_returns_level_2", func(t *testing.T) {
		// Given
		engine := NewLevelEngine()
		sobrietyDays := 59
		var lastRelapseTimestamp *time.Time = nil
		currentTime := time.Now()
		manualOverride := (*Level)(nil)
		daysSinceLastLevelChange := 0

		// When
		result := engine.DetermineLevel(sobrietyDays, lastRelapseTimestamp, currentTime, manualOverride, daysSinceLastLevelChange)

		// Then
		if result.DeterminedLevel != LevelProcess {
			t.Errorf("expected Level 2 (Process) for day 59, got Level %d", result.DeterminedLevel)
		}
	})
}

// TestAffirmations_LevelEngine_DeterminesLevel3_Days60to179 verifies Level 3 (TemperedIdentity)
// is assigned for Days 60-179 of sobriety.
//
// Acceptance Criterion: Users in Days 60-179 receive Level 3 affirmations.
func TestAffirmations_LevelEngine_DeterminesLevel3_Days60to179(t *testing.T) {
	t.Run("day_60_returns_level_3", func(t *testing.T) {
		// Given
		engine := NewLevelEngine()
		sobrietyDays := 60
		var lastRelapseTimestamp *time.Time = nil
		currentTime := time.Now()
		manualOverride := (*Level)(nil)
		daysSinceLastLevelChange := 0

		// When
		result := engine.DetermineLevel(sobrietyDays, lastRelapseTimestamp, currentTime, manualOverride, daysSinceLastLevelChange)

		// Then
		if result.DeterminedLevel != LevelTemperedIdentity {
			t.Errorf("expected Level 3 (TemperedIdentity) for day 60, got Level %d", result.DeterminedLevel)
		}
	})

	t.Run("day_120_returns_level_3", func(t *testing.T) {
		// Given
		engine := NewLevelEngine()
		sobrietyDays := 120
		var lastRelapseTimestamp *time.Time = nil
		currentTime := time.Now()
		manualOverride := (*Level)(nil)
		daysSinceLastLevelChange := 0

		// When
		result := engine.DetermineLevel(sobrietyDays, lastRelapseTimestamp, currentTime, manualOverride, daysSinceLastLevelChange)

		// Then
		if result.DeterminedLevel != LevelTemperedIdentity {
			t.Errorf("expected Level 3 (TemperedIdentity) for day 120, got Level %d", result.DeterminedLevel)
		}
	})

	t.Run("day_179_returns_level_3", func(t *testing.T) {
		// Given
		engine := NewLevelEngine()
		sobrietyDays := 179
		var lastRelapseTimestamp *time.Time = nil
		currentTime := time.Now()
		manualOverride := (*Level)(nil)
		daysSinceLastLevelChange := 0

		// When
		result := engine.DetermineLevel(sobrietyDays, lastRelapseTimestamp, currentTime, manualOverride, daysSinceLastLevelChange)

		// Then
		if result.DeterminedLevel != LevelTemperedIdentity {
			t.Errorf("expected Level 3 (TemperedIdentity) for day 179, got Level %d", result.DeterminedLevel)
		}
	})
}

// TestAffirmations_LevelEngine_DeterminesLevel4_Days180Plus verifies Level 4 (FullIdentity)
// is assigned for Days 180+ of sobriety.
//
// Acceptance Criterion: Users at Days 180+ receive Level 4 affirmations.
func TestAffirmations_LevelEngine_DeterminesLevel4_Days180Plus(t *testing.T) {
	t.Run("day_180_returns_level_4", func(t *testing.T) {
		// Given
		engine := NewLevelEngine()
		sobrietyDays := 180
		var lastRelapseTimestamp *time.Time = nil
		currentTime := time.Now()
		manualOverride := (*Level)(nil)
		daysSinceLastLevelChange := 0

		// When
		result := engine.DetermineLevel(sobrietyDays, lastRelapseTimestamp, currentTime, manualOverride, daysSinceLastLevelChange)

		// Then
		if result.DeterminedLevel != LevelFullIdentity {
			t.Errorf("expected Level 4 (FullIdentity) for day 180, got Level %d", result.DeterminedLevel)
		}
	})

	t.Run("day_365_returns_level_4", func(t *testing.T) {
		// Given
		engine := NewLevelEngine()
		sobrietyDays := 365
		var lastRelapseTimestamp *time.Time = nil
		currentTime := time.Now()
		manualOverride := (*Level)(nil)
		daysSinceLastLevelChange := 0

		// When
		result := engine.DetermineLevel(sobrietyDays, lastRelapseTimestamp, currentTime, manualOverride, daysSinceLastLevelChange)

		// Then
		if result.DeterminedLevel != LevelFullIdentity {
			t.Errorf("expected Level 4 (FullIdentity) for day 365, got Level %d", result.DeterminedLevel)
		}
	})
}

// TestAffirmations_LevelEngine_PostRelapse_LocksToLevel1_Within24h verifies that
// if a relapse occurred within 24 hours, the level is locked to Level 1.
//
// Acceptance Criterion: Post-relapse within 24h locks to Level 1.
func TestAffirmations_LevelEngine_PostRelapse_LocksToLevel1_Within24h(t *testing.T) {
	t.Run("relapse_1_hour_ago_locks_to_level_1", func(t *testing.T) {
		// Given
		engine := NewLevelEngine()
		sobrietyDays := 60 // normally Level 3
		currentTime := time.Now()
		lastRelapseTimestamp := currentTime.Add(-1 * time.Hour)
		manualOverride := (*Level)(nil)
		daysSinceLastLevelChange := 0

		// When
		result := engine.DetermineLevel(sobrietyDays, &lastRelapseTimestamp, currentTime, manualOverride, daysSinceLastLevelChange)

		// Then
		if result.DeterminedLevel != LevelPermission {
			t.Errorf("expected Level 1 (locked post-relapse), got Level %d", result.DeterminedLevel)
		}
		if !result.IsLocked {
			t.Error("expected IsLocked=true for post-relapse within 24h")
		}
	})

	t.Run("relapse_23_hours_ago_locks_to_level_1", func(t *testing.T) {
		// Given
		engine := NewLevelEngine()
		sobrietyDays := 180 // normally Level 4
		currentTime := time.Now()
		lastRelapseTimestamp := currentTime.Add(-23 * time.Hour)
		manualOverride := (*Level)(nil)
		daysSinceLastLevelChange := 0

		// When
		result := engine.DetermineLevel(sobrietyDays, &lastRelapseTimestamp, currentTime, manualOverride, daysSinceLastLevelChange)

		// Then
		if result.DeterminedLevel != LevelPermission {
			t.Errorf("expected Level 1 (locked post-relapse), got Level %d", result.DeterminedLevel)
		}
		if !result.IsLocked {
			t.Error("expected IsLocked=true for post-relapse within 24h")
		}
	})
}

// TestAffirmations_LevelEngine_PostRelapse_UnlocksAfter24h verifies that
// after 24 hours post-relapse, normal level determination resumes.
//
// Acceptance Criterion: Post-relapse lock expires after 24h.
func TestAffirmations_LevelEngine_PostRelapse_UnlocksAfter24h(t *testing.T) {
	t.Run("relapse_25_hours_ago_unlocks", func(t *testing.T) {
		// Given
		engine := NewLevelEngine()
		sobrietyDays := 60 // should return Level 3
		currentTime := time.Now()
		lastRelapseTimestamp := currentTime.Add(-25 * time.Hour)
		manualOverride := (*Level)(nil)
		daysSinceLastLevelChange := 0

		// When
		result := engine.DetermineLevel(sobrietyDays, &lastRelapseTimestamp, currentTime, manualOverride, daysSinceLastLevelChange)

		// Then
		if result.DeterminedLevel != LevelTemperedIdentity {
			t.Errorf("expected Level 3 after 24h post-relapse, got Level %d", result.DeterminedLevel)
		}
		if result.IsLocked {
			t.Error("expected IsLocked=false after 24h post-relapse")
		}
	})

	t.Run("relapse_48_hours_ago_unlocks", func(t *testing.T) {
		// Given
		engine := NewLevelEngine()
		sobrietyDays := 180 // should return Level 4
		currentTime := time.Now()
		lastRelapseTimestamp := currentTime.Add(-48 * time.Hour)
		manualOverride := (*Level)(nil)
		daysSinceLastLevelChange := 0

		// When
		result := engine.DetermineLevel(sobrietyDays, &lastRelapseTimestamp, currentTime, manualOverride, daysSinceLastLevelChange)

		// Then
		if result.DeterminedLevel != LevelFullIdentity {
			t.Errorf("expected Level 4 after 48h post-relapse, got Level %d", result.DeterminedLevel)
		}
		if result.IsLocked {
			t.Error("expected IsLocked=false after 48h post-relapse")
		}
	})
}

// TestAffirmations_LevelEngine_ManualOverride_LowerLevel verifies that users
// can manually select a lower level than their sobriety days would suggest.
//
// Acceptance Criterion: Manual override to lower level is always allowed.
func TestAffirmations_LevelEngine_ManualOverride_LowerLevel(t *testing.T) {
	t.Run("day_60_manual_override_to_level_1", func(t *testing.T) {
		// Given
		engine := NewLevelEngine()
		sobrietyDays := 60 // normally Level 3
		var lastRelapseTimestamp *time.Time = nil
		currentTime := time.Now()
		override := LevelPermission
		manualOverride := &override
		daysSinceLastLevelChange := 0

		// When
		result := engine.DetermineLevel(sobrietyDays, lastRelapseTimestamp, currentTime, manualOverride, daysSinceLastLevelChange)

		// Then
		if result.DeterminedLevel != LevelPermission {
			t.Errorf("expected Level 1 via manual override, got Level %d", result.DeterminedLevel)
		}
	})

	t.Run("day_180_manual_override_to_level_2", func(t *testing.T) {
		// Given
		engine := NewLevelEngine()
		sobrietyDays := 180 // normally Level 4
		var lastRelapseTimestamp *time.Time = nil
		currentTime := time.Now()
		override := LevelProcess
		manualOverride := &override
		daysSinceLastLevelChange := 0

		// When
		result := engine.DetermineLevel(sobrietyDays, lastRelapseTimestamp, currentTime, manualOverride, daysSinceLastLevelChange)

		// Then
		if result.DeterminedLevel != LevelProcess {
			t.Errorf("expected Level 2 via manual override, got Level %d", result.DeterminedLevel)
		}
	})
}

// TestAffirmations_LevelEngine_ManualOverride_RejectsHigherWithout30Days verifies that
// manual override to a higher level requires at least 30 days at current level.
//
// Acceptance Criterion: Manual increase to higher level rejected without 30 days at current level.
func TestAffirmations_LevelEngine_ManualOverride_RejectsHigherWithout30Days(t *testing.T) {
	t.Run("day_60_level_3_override_to_level_4_with_29_days_rejected", func(t *testing.T) {
		// Given
		engine := NewLevelEngine()
		sobrietyDays := 60 // natural level is 3
		var lastRelapseTimestamp *time.Time = nil
		currentTime := time.Now()
		override := LevelFullIdentity
		manualOverride := &override
		daysSinceLastLevelChange := 29 // not yet 30 days

		// When
		result := engine.DetermineLevel(sobrietyDays, lastRelapseTimestamp, currentTime, manualOverride, daysSinceLastLevelChange)

		// Then
		// Should fall back to natural level (Level 3)
		if result.DeterminedLevel != LevelTemperedIdentity {
			t.Errorf("expected Level 3 (manual override rejected), got Level %d", result.DeterminedLevel)
		}
	})

	t.Run("day_60_level_3_override_to_level_4_with_30_days_accepted", func(t *testing.T) {
		// Given
		engine := NewLevelEngine()
		sobrietyDays := 60 // natural level is 3
		var lastRelapseTimestamp *time.Time = nil
		currentTime := time.Now()
		override := LevelFullIdentity
		manualOverride := &override
		daysSinceLastLevelChange := 30 // exactly 30 days

		// When
		result := engine.DetermineLevel(sobrietyDays, lastRelapseTimestamp, currentTime, manualOverride, daysSinceLastLevelChange)

		// Then
		// Should accept manual override to Level 4
		if result.DeterminedLevel != LevelFullIdentity {
			t.Errorf("expected Level 4 (manual override accepted), got Level %d", result.DeterminedLevel)
		}
	})

	t.Run("day_20_level_2_override_to_level_3_with_5_days_rejected", func(t *testing.T) {
		// Given
		engine := NewLevelEngine()
		sobrietyDays := 20 // natural level is 2
		var lastRelapseTimestamp *time.Time = nil
		currentTime := time.Now()
		override := LevelTemperedIdentity
		manualOverride := &override
		daysSinceLastLevelChange := 5

		// When
		result := engine.DetermineLevel(sobrietyDays, lastRelapseTimestamp, currentTime, manualOverride, daysSinceLastLevelChange)

		// Then
		// Should fall back to natural level (Level 2)
		if result.DeterminedLevel != LevelProcess {
			t.Errorf("expected Level 2 (manual override rejected), got Level %d", result.DeterminedLevel)
		}
	})
}
