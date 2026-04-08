// internal/domain/nutrition/calendar_completeness.go
package nutrition

// CalculateCompleteness determines the completeness indicator for a calendar day.
// FR-NUT-5.2: Green = 3+ meals AND hydration goal met.
// FR-NUT-5.3: Yellow = 1-2 meals OR hydration goal partially met (>50%).
// FR-NUT-5.4: Gray = 0 meals logged.
func CalculateCompleteness(mealsLogged int, hydrationGoalMet bool, hydrationProgressPercent int) Completeness {
	if mealsLogged >= 3 && hydrationGoalMet {
		return CompletenessGreen
	}

	if mealsLogged > 0 || hydrationProgressPercent > 50 {
		return CompletenessYellow
	}

	return CompletenessGray
}
