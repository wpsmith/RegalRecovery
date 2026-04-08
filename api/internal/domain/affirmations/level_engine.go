// internal/domain/affirmations/level_engine.go
package affirmations

import (
	"time"
)

// LevelEngine determines the appropriate affirmation level for a user based on
// sobriety days, relapse history, and manual overrides.
type LevelEngine struct{}

// NewLevelEngine creates a new LevelEngine instance.
func NewLevelEngine() *LevelEngine {
	return &LevelEngine{}
}

// DetermineLevel computes the affirmation level based on sobriety days, relapse timing,
// and manual override preferences.
//
// Level gates:
// - Level 1 (Permission): Days 0-13
// - Level 2 (Process): Days 14-59
// - Level 3 (TemperedIdentity): Days 60-179
// - Level 4 (FullIdentity): Days 180+
//
// Post-relapse lock: If lastRelapseTimestamp is within 24 hours of currentTime,
// lock to Level 1 regardless of sobriety days.
//
// Manual override: Users can manually select a lower level at any time.
// To manually select a higher level, they must have been at their current natural level
// for at least 30 days (daysSinceLastLevelChange >= 30).
func (le *LevelEngine) DetermineLevel(
	sobrietyDays int,
	lastRelapseTimestamp *time.Time,
	currentTime time.Time,
	manualOverride *Level,
	daysSinceLastLevelChange int,
) LevelDeterminationResult {
	// Check for post-relapse lock (within 24 hours)
	if lastRelapseTimestamp != nil {
		hoursSinceRelapse := currentTime.Sub(*lastRelapseTimestamp).Hours()
		if hoursSinceRelapse < 24 {
			return LevelDeterminationResult{
				DeterminedLevel: LevelPermission,
				Reason:          "post-relapse lock (within 24h)",
				IsLocked:        true,
			}
		}
	}

	// Determine natural level based on sobriety days
	naturalLevel := le.naturalLevelFromSobrietyDays(sobrietyDays)

	// If no manual override, return natural level
	if manualOverride == nil {
		return LevelDeterminationResult{
			DeterminedLevel: naturalLevel,
			Reason:          "natural progression based on sobriety days",
			IsLocked:        false,
		}
	}

	// Manual override provided
	overrideLevel := *manualOverride

	// If override is lower than natural level, always allow it
	if overrideLevel < naturalLevel {
		return LevelDeterminationResult{
			DeterminedLevel: overrideLevel,
			Reason:          "manual override to lower level",
			IsLocked:        false,
		}
	}

	// If override is same as natural level, allow it
	if overrideLevel == naturalLevel {
		return LevelDeterminationResult{
			DeterminedLevel: overrideLevel,
			Reason:          "manual override matches natural level",
			IsLocked:        false,
		}
	}

	// Override is higher than natural level
	// Require at least 30 days at current level
	if daysSinceLastLevelChange >= 30 {
		return LevelDeterminationResult{
			DeterminedLevel: overrideLevel,
			Reason:          "manual override to higher level (30+ days at current level)",
			IsLocked:        false,
		}
	}

	// Override rejected: not enough time at current level
	return LevelDeterminationResult{
		DeterminedLevel: naturalLevel,
		Reason:          "manual override to higher level rejected (need 30+ days at current level)",
		IsLocked:        false,
	}
}

// naturalLevelFromSobrietyDays returns the natural level based on sobriety days.
func (le *LevelEngine) naturalLevelFromSobrietyDays(sobrietyDays int) Level {
	switch {
	case sobrietyDays >= 180:
		return LevelFullIdentity
	case sobrietyDays >= 60:
		return LevelTemperedIdentity
	case sobrietyDays >= 14:
		return LevelProcess
	default:
		return LevelPermission
	}
}
