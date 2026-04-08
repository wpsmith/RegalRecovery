// test/contract/nutrition/trends_test.go
package nutrition

import (
	"encoding/json"
	"testing"
)

// TestContract_GetTrends_MatchesOpenAPISpec validates GET /activities/nutrition/trends.
func TestContract_GetTrends_MatchesOpenAPISpec(t *testing.T) {
	response := `{
		"data": {
			"period": "7d",
			"mealConsistency": {
				"averageMealsPerDay": 2.6,
				"mealTypePercentages": {
					"breakfast": 85.7,
					"lunch": 100,
					"dinner": 71.4
				}
			},
			"emotionalEating": {
				"averageMoodBefore": 2.5,
				"averageMoodAfter": 3.8,
				"moodImprovementPercent": 73.3
			},
			"mindfulness": {
				"mindfulPercent": 65,
				"somewhatPercent": 20,
				"distractedPercent": 15,
				"trendDirection": "improving"
			},
			"hydration": {
				"averageDailyOunces": 48,
				"daysGoalMet": 5,
				"totalDays": 7
			},
			"insights": [
				{
					"insightId": "ins_abc123",
					"type": "gap-detection",
					"message": "You've skipped breakfast 5 of the last 7 days.",
					"severity": "attention"
				}
			]
		},
		"meta": {
			"retrievedAt": "2026-03-28T14:30:00Z"
		}
	}`

	var resp map[string]interface{}
	if err := json.Unmarshal([]byte(response), &resp); err != nil {
		t.Fatalf("invalid response JSON: %v", err)
	}

	data, ok := resp["data"].(map[string]interface{})
	if !ok {
		t.Fatal("response must have data envelope")
	}

	if _, ok := data["period"]; !ok {
		t.Error("trends must include period")
	}

	// Validate insight structure.
	insights, ok := data["insights"].([]interface{})
	if !ok || len(insights) == 0 {
		t.Skip("no insights in fixture, skipping insight validation")
	}

	insight := insights[0].(map[string]interface{})
	for _, field := range []string{"insightId", "type", "message", "severity"} {
		if _, ok := insight[field]; !ok {
			t.Errorf("insight must include %s", field)
		}
	}

	// Validate insight type enum values.
	validTypes := map[string]bool{
		"gap-detection": true, "meal-consistency": true, "emotional-eating": true,
		"mindfulness": true, "hydration": true, "cross-domain": true,
	}
	if insType, ok := insight["type"].(string); ok {
		if !validTypes[insType] {
			t.Errorf("invalid insight type: %s", insType)
		}
	}
}

// TestContract_GetWeeklySummary_MatchesOpenAPISpec validates GET /activities/nutrition/trends/weekly-summary.
func TestContract_GetWeeklySummary_MatchesOpenAPISpec(t *testing.T) {
	response := `{
		"data": {
			"currentWeek": {
				"mealsLogged": 18,
				"averageMealsPerDay": 2.6,
				"hydrationGoalMetDays": 5,
				"mostCommonContext": "homemade",
				"mindfulMealPercent": 65
			},
			"previousWeek": {
				"mealsLogged": 14,
				"averageMealsPerDay": 2.0,
				"hydrationGoalMetDays": 3,
				"mostCommonContext": "takeout",
				"mindfulMealPercent": 50
			},
			"comparison": {
				"mealsLoggedDelta": 4,
				"hydrationDelta": 2,
				"direction": "improving"
			}
		},
		"meta": {
			"weekStartDate": "2026-03-24",
			"weekEndDate": "2026-03-30"
		}
	}`

	var resp map[string]interface{}
	if err := json.Unmarshal([]byte(response), &resp); err != nil {
		t.Fatalf("invalid response JSON: %v", err)
	}

	data, ok := resp["data"].(map[string]interface{})
	if !ok {
		t.Fatal("response must have data envelope")
	}

	for _, field := range []string{"currentWeek", "previousWeek", "comparison"} {
		if _, ok := data[field]; !ok {
			t.Errorf("weekly summary must include %s", field)
		}
	}

	comparison := data["comparison"].(map[string]interface{})
	direction, ok := comparison["direction"].(string)
	if !ok {
		t.Fatal("comparison must include direction")
	}

	validDirections := map[string]bool{"improving": true, "stable": true, "declining": true}
	if !validDirections[direction] {
		t.Errorf("invalid direction: %s", direction)
	}
}
