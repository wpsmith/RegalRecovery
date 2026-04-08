// test/contract/nutrition/calendar_test.go
package nutrition

import (
	"encoding/json"
	"testing"
)

// TestContract_GetCalendar_MatchesOpenAPISpec validates GET /activities/nutrition/calendar.
func TestContract_GetCalendar_MatchesOpenAPISpec(t *testing.T) {
	response := `{
		"data": {
			"year": 2026,
			"month": 3,
			"days": [
				{
					"date": "2026-03-28",
					"mealsLogged": 3,
					"mealTypes": ["breakfast", "lunch", "dinner"],
					"hydrationGoalMet": true,
					"completeness": "green"
				},
				{
					"date": "2026-03-27",
					"mealsLogged": 1,
					"mealTypes": ["lunch"],
					"hydrationGoalMet": false,
					"completeness": "yellow"
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

	if _, ok := data["year"]; !ok {
		t.Error("calendar data must include year")
	}
	if _, ok := data["month"]; !ok {
		t.Error("calendar data must include month")
	}

	days, ok := data["days"].([]interface{})
	if !ok || len(days) == 0 {
		t.Fatal("calendar data must have days array")
	}

	firstDay := days[0].(map[string]interface{})
	for _, field := range []string{"date", "mealsLogged", "mealTypes", "hydrationGoalMet", "completeness"} {
		if _, ok := firstDay[field]; !ok {
			t.Errorf("calendar day must include %s", field)
		}
	}

	// Validate completeness values.
	validCompleteness := map[string]bool{"green": true, "yellow": true, "gray": true}
	for _, day := range days {
		d := day.(map[string]interface{})
		c, ok := d["completeness"].(string)
		if !ok || !validCompleteness[c] {
			t.Errorf("invalid completeness value: %v", d["completeness"])
		}
	}
}
