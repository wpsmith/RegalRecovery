// internal/domain/nutrition/trends_mindfulness.go
package nutrition

// CalculateMindfulnessTrend computes mindfulness distribution and trend direction.
func CalculateMindfulnessTrend(meals []MealLog, previousMindfulPercent *float64) *MindfulnessTrend {
	var mindful, somewhat, distracted int

	for _, meal := range meals {
		if meal.MindfulnessCheck == nil {
			continue
		}
		switch *meal.MindfulnessCheck {
		case MindfulnessYes:
			mindful++
		case MindfulnessSomewhat:
			somewhat++
		case MindfulnessNo:
			distracted++
		}
	}

	total := mindful + somewhat + distracted
	if total == 0 {
		return &MindfulnessTrend{
			MindfulPercent:   0,
			SomewhatPercent:  0,
			DistractedPercent: 0,
			TrendDirection:   nil,
		}
	}

	mindfulPct := float64(mindful) / float64(total) * 100
	somewhatPct := float64(somewhat) / float64(total) * 100
	distractedPct := float64(distracted) / float64(total) * 100

	var direction *TrendDirection
	if previousMindfulPercent != nil {
		d := CalculateTrendDirection(mindfulPct, *previousMindfulPercent)
		direction = &d
	}

	return &MindfulnessTrend{
		MindfulPercent:   mindfulPct,
		SomewhatPercent:  somewhatPct,
		DistractedPercent: distractedPct,
		TrendDirection:   direction,
	}
}

// CalculateTrendDirection determines the direction based on current vs previous period.
func CalculateTrendDirection(current, previous float64) TrendDirection {
	delta := current - previous
	if delta > 5 {
		return TrendDirectionImproving
	}
	if delta < -5 {
		return TrendDirectionDeclining
	}
	return TrendDirectionStable
}
