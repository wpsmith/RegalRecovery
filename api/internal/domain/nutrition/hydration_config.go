// internal/domain/nutrition/hydration_config.go
package nutrition

// Default hydration configuration values.
const (
	// DefaultServingSizeOz is the default serving size in ounces (FR-NUT-3.4).
	DefaultServingSizeOz = 8.0

	// DefaultDailyTargetServings is the default daily hydration target (FR-NUT-3.6).
	DefaultDailyTargetServings = 8

	// DefaultDailyTargetOunces is DefaultServingSizeOz * DefaultDailyTargetServings.
	DefaultDailyTargetOunces = 64.0
)

// CalculateGoalProgress returns the percentage progress toward the daily goal.
// Capped at 100%.
func CalculateGoalProgress(servingsLogged, dailyTarget int) int {
	if dailyTarget <= 0 {
		return 0
	}
	progress := (servingsLogged * 100) / dailyTarget
	if progress > 100 {
		progress = 100
	}
	if progress < 0 {
		progress = 0
	}
	return progress
}

// CalculateTotalOunces computes total ounces from servings and serving size.
func CalculateTotalOunces(servingsLogged int, servingSizeOz float64) float64 {
	return float64(servingsLogged) * servingSizeOz
}
