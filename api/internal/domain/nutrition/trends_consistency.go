// internal/domain/nutrition/trends_consistency.go
package nutrition

// CalculateMealConsistency computes meal consistency trends from daily meal data.
// FR-NUT-7.1: Meals per day with breakdown by type.
// FR-NUT-7.2: Percentage of days each meal type is logged.
func CalculateMealConsistency(meals []MealLog, startDate, endDate string) *MealConsistencyTrend {
	if len(meals) == 0 {
		return &MealConsistencyTrend{
			DailyMealCounts:     []DailyMealCount{},
			AverageMealsPerDay:  0,
			MealTypePercentages: map[string]float64{},
		}
	}

	// Group meals by date.
	dailyMap := make(map[string]*DailyMealCount)
	for _, meal := range meals {
		date := meal.Timestamp.Format("2006-01-02")
		if _, ok := dailyMap[date]; !ok {
			dailyMap[date] = &DailyMealCount{Date: date}
		}
		dc := dailyMap[date]
		dc.Total++
		switch meal.MealType {
		case MealTypeBreakfast:
			dc.Breakfast++
		case MealTypeLunch:
			dc.Lunch++
		case MealTypeDinner:
			dc.Dinner++
		case MealTypeSnack:
			dc.Snack++
		case MealTypeOther:
			dc.Other++
		}
	}

	// Convert to sorted slice.
	dailyCounts := make([]DailyMealCount, 0, len(dailyMap))
	for _, dc := range dailyMap {
		dailyCounts = append(dailyCounts, *dc)
	}

	// Calculate total days in range for averages.
	start, _ := ParseDate(startDate)
	end, _ := ParseDate(endDate)
	totalDays := int(end.Sub(start).Hours()/24) + 1
	if totalDays <= 0 {
		totalDays = 1
	}

	totalMeals := len(meals)
	avgMeals := float64(totalMeals) / float64(totalDays)

	// Calculate meal type percentages (percentage of days the type is logged).
	typeDays := map[string]int{
		"breakfast": 0,
		"lunch":     0,
		"dinner":    0,
		"snack":     0,
	}
	for _, dc := range dailyMap {
		if dc.Breakfast > 0 {
			typeDays["breakfast"]++
		}
		if dc.Lunch > 0 {
			typeDays["lunch"]++
		}
		if dc.Dinner > 0 {
			typeDays["dinner"]++
		}
		if dc.Snack > 0 {
			typeDays["snack"]++
		}
	}

	percentages := make(map[string]float64)
	for k, v := range typeDays {
		percentages[k] = float64(v) / float64(totalDays) * 100
	}

	return &MealConsistencyTrend{
		DailyMealCounts:     dailyCounts,
		AverageMealsPerDay:  avgMeals,
		MealTypePercentages: percentages,
	}
}
