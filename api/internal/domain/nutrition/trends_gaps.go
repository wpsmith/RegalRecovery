// internal/domain/nutrition/trends_gaps.go
package nutrition

import "fmt"

// DetectMealGaps identifies patterns of skipped meal types.
// FR-NUT-7.3: Gap detection for specific meal types.
func DetectMealGaps(meals []MealLog, totalDays int) []Insight {
	if totalDays < 7 {
		return nil
	}

	var insights []Insight

	// Count days with each meal type.
	typeDays := map[MealType]map[string]bool{
		MealTypeBreakfast: {},
		MealTypeLunch:     {},
		MealTypeDinner:    {},
	}

	for _, meal := range meals {
		date := meal.Timestamp.Format("2006-01-02")
		if days, ok := typeDays[meal.MealType]; ok {
			days[date] = true
		}
	}

	for mealType, days := range typeDays {
		skippedDays := totalDays - len(days)
		if skippedDays > 0 {
			skipRate := float64(skippedDays) / float64(totalDays)
			// Trigger insight if skipped more than 60% of days.
			if skipRate >= 0.6 {
				insights = append(insights, Insight{
					Type: InsightTypeGapDetection,
					Message: fmt.Sprintf(
						"You've skipped %s %d of the last %d days. Consistent meals support your recovery journey.",
						mealType, skippedDays, totalDays,
					),
					Severity: InsightSeverityAttention,
				})
			}
		}
	}

	return insights
}
