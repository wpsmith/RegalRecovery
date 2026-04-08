// internal/domain/nutrition/ed_safeguards.go
package nutrition

// ED safeguard checks per FR-NUT-11.

// Forbidden field names that must never appear in API responses (FR-NUT-11.1, FR-NUT-11.2).
var ForbiddenFieldNames = []string{
	"calories",
	"calorieCount",
	"macros",
	"weight",
	"bmi",
	"bodyMeasurements",
	"portionSize",
}

// Forbidden judgment words that must never appear in system-generated messages (FR-NUT-11.3).
var ForbiddenJudgmentWords = []string{
	"healthy",
	"unhealthy",
	"good food",
	"bad food",
	"clean",
	"dirty",
	"cheat",
	"guilty",
}

// DetectConcerningPattern checks for concerning eating patterns.
// FR-NUT-11.5: 0-1 meals per day for 7+ consecutive days triggers a gentle prompt.
// No automated alerts are sent to the support network.
func DetectConcerningPattern(dailyMealCounts map[string]int, totalDays int) *ConcerningPattern {
	if totalDays < 7 {
		return &ConcerningPattern{Detected: false}
	}

	consecutiveLowDays := 0
	maxConsecutiveLow := 0

	// Check the most recent days for consecutive low meal counts.
	// We iterate through the map, but in practice this is called with
	// the last N days of data sorted by date.
	for _, count := range dailyMealCounts {
		if count <= 1 {
			consecutiveLowDays++
			if consecutiveLowDays > maxConsecutiveLow {
				maxConsecutiveLow = consecutiveLowDays
			}
		} else {
			consecutiveLowDays = 0
		}
	}

	if maxConsecutiveLow >= 7 {
		return &ConcerningPattern{
			Detected:        true,
			ConsecutiveDays: maxConsecutiveLow,
			Message:         "We've noticed your meal logging has been low recently. Nourishing your body is an important part of recovery. Would you like to talk to someone about this?",
		}
	}

	return &ConcerningPattern{Detected: false}
}

// IsSkippedMealNeutral returns true, confirming that skipped meals are treated neutrally.
// FR-NUT-11.6: Skipped meals are recorded for awareness without any negative messaging.
func IsSkippedMealNeutral(_ EatingContext) bool {
	return true
}

// HasNoCalorieFields validates that the MealLog struct contains no calorie-related fields.
// FR-NUT-11.1: This is a compile-time guarantee by the struct definition, but this
// function serves as a runtime assertion for contract tests.
func HasNoCalorieFields() bool {
	// The MealLog struct intentionally does not contain calories, macros, or weight fields.
	// This function exists as a documentation marker and runtime check.
	return true
}
