// internal/domain/nutrition/insights.go
package nutrition

import "github.com/google/uuid"

// GenerateInsights creates all applicable insights from trend data.
// Insights use recovery-positive language. No food judgment (FR-NUT-11.3).
func GenerateInsights(meals []MealLog, hydrationLogs []HydrationLog, totalDays int, settings *NutritionSettings) []Insight {
	var insights []Insight

	// Gap detection insights (FR-NUT-7.3).
	if settings == nil || settings.InsightPreferences.MealConsistencyEnabled {
		gapInsights := DetectMealGaps(meals, totalDays)
		insights = append(insights, gapInsights...)
	}

	// Emotional eating insights (FR-NUT-8.2).
	if settings == nil || settings.InsightPreferences.EmotionalEatingEnabled {
		emotionalInsights := AnalyzeMoodToContextCorrelation(meals)
		insights = append(insights, emotionalInsights...)
	}

	// Mindfulness insights.
	if settings == nil || settings.InsightPreferences.MindfulnessEnabled {
		mindfulInsights := generateMindfulnessInsights(meals)
		insights = append(insights, mindfulInsights...)
	}

	// Hydration insights.
	hydrationInsights := generateHydrationInsights(hydrationLogs, totalDays)
	insights = append(insights, hydrationInsights...)

	// Assign IDs to all insights.
	for i := range insights {
		insights[i].InsightID = "ins_" + uuid.New().String()[:8]
	}

	return insights
}

func generateMindfulnessInsights(meals []MealLog) []Insight {
	var insights []Insight

	mindfulCount := 0
	totalWithData := 0
	for _, meal := range meals {
		if meal.MindfulnessCheck != nil {
			totalWithData++
			if *meal.MindfulnessCheck == MindfulnessYes {
				mindfulCount++
			}
		}
	}

	if totalWithData >= 10 {
		mindfulPct := float64(mindfulCount) / float64(totalWithData) * 100
		if mindfulPct >= 70 {
			insights = append(insights, Insight{
				Type:     InsightTypeMindfulness,
				Message:  "You've been eating mindfully at most of your meals. Staying present during meals supports your overall recovery.",
				Severity: InsightSeverityInfo,
			})
		} else if mindfulPct < 30 {
			insights = append(insights, Insight{
				Type:     InsightTypeMindfulness,
				Message:  "Most of your meals have been while distracted. Taking a moment to be present during meals can be a small but powerful recovery practice.",
				Severity: InsightSeverityAttention,
			})
		}
	}

	return insights
}

func generateHydrationInsights(logs []HydrationLog, totalDays int) []Insight {
	var insights []Insight

	if totalDays < 7 || len(logs) == 0 {
		return insights
	}

	goalMetDays := 0
	for _, log := range logs {
		if log.GoalMet {
			goalMetDays++
		}
	}

	goalMetRate := float64(goalMetDays) / float64(totalDays) * 100
	if goalMetRate >= 80 {
		insights = append(insights, Insight{
			Type:     InsightTypeHydration,
			Message:  "You've been consistently meeting your hydration goal. Your body thanks you for staying hydrated.",
			Severity: InsightSeverityInfo,
		})
	} else if goalMetRate < 30 {
		insights = append(insights, Insight{
			Type:     InsightTypeHydration,
			Message:  "Your hydration has been below your goal most days. Staying hydrated supports your energy and focus in recovery.",
			Severity: InsightSeverityAttention,
		})
	}

	return insights
}
