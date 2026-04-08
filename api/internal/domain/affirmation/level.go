// internal/domain/affirmation/level.go
package affirmation

import "time"

const (
	// Level thresholds based on CUMULATIVE sobriety days (not streak).
	// Clinical requirement: no streak-based gamification.
	Level1Threshold = 0  // Available from day 0
	Level2Threshold = 30 // 30+ cumulative sobriety days
	Level3Threshold = 90 // 90+ cumulative sobriety days

	// Post-relapse restriction: Level 1 only for 24 hours after sobriety reset.
	PostRelapseRestrictionHours = 24

	// Healthy Sexuality requires 60+ cumulative days AND explicit opt-in.
	HealthySexualityMinDays = 60
)

// GetMaxLevel returns the maximum affirmation level based on cumulative sobriety days.
// Uses cumulative days (total lifetime sober days), NOT current streak.
func GetMaxLevel(cumulativeDays int) int {
	switch {
	case cumulativeDays >= Level3Threshold:
		return 3
	case cumulativeDays >= Level2Threshold:
		return 2
	default:
		return 1
	}
}

// GetEffectiveMaxLevel applies additional restrictions on top of the base level:
// - Post-relapse: Level 1 only for 24 hours after sobriety reset
// - SOS mode: Never above Level 2
func GetEffectiveMaxLevel(cumulativeDays int, sobrietyResetAt *time.Time, sosMode bool) int {
	baseLevel := GetMaxLevel(cumulativeDays)

	// Post-relapse restriction: Level 1 only for 24 hours
	if sobrietyResetAt != nil {
		hoursSinceReset := time.Since(*sobrietyResetAt).Hours()
		if hoursSinceReset < PostRelapseRestrictionHours {
			return 1
		}
	}

	// SOS mode: never above Level 2
	if sosMode && baseLevel > 2 {
		return 2
	}

	return baseLevel
}

// IsHealthySexualityAccessible returns whether the Healthy Sexuality category
// is available to the user. Requires BOTH:
// 1. 60+ cumulative sobriety days
// 2. Explicit user opt-in
func IsHealthySexualityAccessible(cumulativeDays int, optedIn bool) bool {
	return cumulativeDays >= HealthySexualityMinDays && optedIn
}

// FilterByLevel filters affirmations to only those at or below the given max level.
// If hsAccessible is false, healthySexuality category affirmations are excluded.
func FilterByLevel(affirmations []Affirmation, maxLevel int, hsAccessible bool) []Affirmation {
	var filtered []Affirmation
	for _, a := range affirmations {
		if a.Level > maxLevel {
			continue
		}
		if a.Category == CategoryHealthySexuality && !hsAccessible {
			continue
		}
		filtered = append(filtered, a)
	}
	return filtered
}
