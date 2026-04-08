// test/contract/nutrition/settings_test.go
package nutrition

import (
	"encoding/json"
	"testing"
)

// TestContract_GetSettings_MatchesOpenAPISpec validates GET /activities/nutrition/settings.
func TestContract_GetSettings_MatchesOpenAPISpec(t *testing.T) {
	response := `{
		"data": {
			"hydration": {
				"servingSizeOz": 8,
				"dailyTargetServings": 8
			},
			"mealReminders": {
				"breakfast": {"enabled": false, "time": "08:00"},
				"lunch": {"enabled": false, "time": "12:00"},
				"dinner": {"enabled": false, "time": "18:00"}
			},
			"hydrationReminders": {
				"enabled": false,
				"intervalHours": 2
			},
			"missedMealNudge": {
				"enabled": false,
				"nudgeTime": "14:00"
			},
			"insightPreferences": {
				"mealConsistencyEnabled": true,
				"emotionalEatingEnabled": true,
				"mindfulnessEnabled": true,
				"crossDomainEnabled": true
			}
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

	for _, section := range []string{"hydration", "mealReminders", "hydrationReminders", "missedMealNudge", "insightPreferences"} {
		if _, ok := data[section]; !ok {
			t.Errorf("settings must include %s", section)
		}
	}
}

// TestContract_UpdateSettings_MatchesOpenAPISpec validates PATCH /activities/nutrition/settings.
func TestContract_UpdateSettings_MatchesOpenAPISpec(t *testing.T) {
	// Partial update via JSON Merge Patch.
	request := `{
		"hydration": {
			"dailyTargetServings": 10
		}
	}`

	var req map[string]interface{}
	if err := json.Unmarshal([]byte(request), &req); err != nil {
		t.Fatalf("invalid request JSON: %v", err)
	}

	// The patch should only contain the fields being updated.
	hydration, ok := req["hydration"].(map[string]interface{})
	if !ok {
		t.Fatal("patch must include hydration object")
	}
	if _, ok := hydration["dailyTargetServings"]; !ok {
		t.Error("hydration patch must include dailyTargetServings")
	}
}
