// internal/domain/nutrition/trends_emotional.go
package nutrition

// CalculateEmotionalEatingTrend computes mood before/after comparison.
// FR-NUT-8.1: Average mood before vs. after eating.
// FR-NUT-8.2: Mood-to-meal correlation insights.
func CalculateEmotionalEatingTrend(meals []MealLog) *EmotionalEatingTrend {
	var totalBefore, totalAfter float64
	var countBefore, countAfter, improvements int

	for _, meal := range meals {
		if meal.MoodBefore != nil {
			totalBefore += float64(*meal.MoodBefore)
			countBefore++
		}
		if meal.MoodAfter != nil {
			totalAfter += float64(*meal.MoodAfter)
			countAfter++
		}
		if meal.MoodBefore != nil && meal.MoodAfter != nil {
			if *meal.MoodAfter > *meal.MoodBefore {
				improvements++
			}
		}
	}

	trend := &EmotionalEatingTrend{}

	if countBefore > 0 {
		avg := totalBefore / float64(countBefore)
		trend.AverageMoodBefore = &avg
	}

	if countAfter > 0 {
		avg := totalAfter / float64(countAfter)
		trend.AverageMoodAfter = &avg
	}

	if countBefore > 0 && countAfter > 0 {
		// Count meals with both mood data for improvement percent.
		bothCount := 0
		for _, meal := range meals {
			if meal.MoodBefore != nil && meal.MoodAfter != nil {
				bothCount++
			}
		}
		if bothCount > 0 {
			pct := float64(improvements) / float64(bothCount) * 100
			trend.MoodImprovementPercent = &pct
		}
	}

	return trend
}

// AnalyzeMoodToContextCorrelation identifies correlations between mood and eating context.
// FR-NUT-8.2: "On days when pre-meal mood is below 3, you're more likely to eat fast food."
func AnalyzeMoodToContextCorrelation(meals []MealLog) []Insight {
	var insights []Insight

	// Count context distribution for low-mood meals (moodBefore <= 2).
	lowMoodContexts := make(map[EatingContext]int)
	lowMoodCount := 0

	for _, meal := range meals {
		if meal.MoodBefore != nil && *meal.MoodBefore <= 2 && meal.EatingContext != nil {
			lowMoodContexts[*meal.EatingContext]++
			lowMoodCount++
		}
	}

	if lowMoodCount >= 5 {
		// Find the most common context for low-mood meals.
		maxCount := 0
		var topContext EatingContext
		for ctx, count := range lowMoodContexts {
			if count > maxCount {
				maxCount = count
				topContext = ctx
			}
		}

		if maxCount > 0 {
			pct := float64(maxCount) / float64(lowMoodCount) * 100
			if pct >= 40 {
				insights = append(insights, Insight{
					Type:     InsightTypeEmotionalEating,
					Message:  "On days when you're feeling low before eating, your most common eating context is " + string(topContext) + ". Noticing this pattern can help you make intentional choices.",
					Severity: InsightSeverityAttention,
				})
			}
		}
	}

	return insights
}
