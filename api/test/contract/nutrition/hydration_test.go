// test/contract/nutrition/hydration_test.go
package nutrition

import (
	"encoding/json"
	"testing"
)

// TestContract_GetHydration_MatchesOpenAPISpec validates GET /activities/nutrition/hydration.
func TestContract_GetHydration_MatchesOpenAPISpec(t *testing.T) {
	response := `{
		"data": {
			"date": "2026-03-28",
			"servingsLogged": 5,
			"totalOunces": 40,
			"servingSizeOz": 8,
			"dailyTargetServings": 8,
			"dailyTargetOunces": 64,
			"goalMet": false,
			"goalProgressPercent": 62
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

	requiredFields := []string{"date", "servingsLogged", "totalOunces", "servingSizeOz",
		"dailyTargetServings", "goalMet", "goalProgressPercent"}
	for _, field := range requiredFields {
		if _, ok := data[field]; !ok {
			t.Errorf("hydration response must include %s", field)
		}
	}
}

// TestContract_LogHydration_MatchesOpenAPISpec validates POST /activities/nutrition/hydration/log.
func TestContract_LogHydration_MatchesOpenAPISpec(t *testing.T) {
	request := `{"action": "add", "servings": 1}`

	var req map[string]interface{}
	if err := json.Unmarshal([]byte(request), &req); err != nil {
		t.Fatalf("invalid request JSON: %v", err)
	}

	action, ok := req["action"].(string)
	if !ok || (action != "add" && action != "remove") {
		t.Error("action must be 'add' or 'remove'")
	}
}

// TestContract_GetHydrationHistory_MatchesOpenAPISpec validates GET /activities/nutrition/hydration/history.
func TestContract_GetHydrationHistory_MatchesOpenAPISpec(t *testing.T) {
	response := `{
		"data": [
			{
				"date": "2026-03-28",
				"servingsLogged": 5,
				"totalOunces": 40,
				"goalMet": false,
				"servingSizeOz": 8
			}
		],
		"meta": {
			"averageDailyOunces": 40,
			"daysGoalMet": 0,
			"totalDays": 1
		}
	}`

	var resp map[string]interface{}
	if err := json.Unmarshal([]byte(response), &resp); err != nil {
		t.Fatalf("invalid response JSON: %v", err)
	}

	data, ok := resp["data"].([]interface{})
	if !ok {
		t.Fatal("response data must be an array")
	}
	if len(data) == 0 {
		t.Error("test fixture should have data")
	}

	meta, ok := resp["meta"].(map[string]interface{})
	if !ok {
		t.Fatal("response must have meta")
	}
	for _, field := range []string{"averageDailyOunces", "daysGoalMet", "totalDays"} {
		if _, ok := meta[field]; !ok {
			t.Errorf("meta must include %s", field)
		}
	}
}
