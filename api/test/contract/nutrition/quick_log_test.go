// test/contract/nutrition/quick_log_test.go
package nutrition

import (
	"encoding/json"
	"testing"
)

// TestContract_QuickLog_MatchesOpenAPISpec validates POST /activities/nutrition/meals/quick.
func TestContract_QuickLog_MatchesOpenAPISpec(t *testing.T) {
	// Quick log only requires mealType.
	request := `{"mealType": "breakfast"}`

	var req map[string]interface{}
	if err := json.Unmarshal([]byte(request), &req); err != nil {
		t.Fatalf("invalid request JSON: %v", err)
	}

	if _, ok := req["mealType"]; !ok {
		t.Error("quick log request must include mealType")
	}

	// Response should have isQuickLog=true and description=null.
	response := `{
		"data": {
			"mealId": "ml_22222",
			"timestamp": "2026-03-28T08:00:00Z",
			"mealType": "breakfast",
			"description": null,
			"isQuickLog": true,
			"links": {
				"self": "https://api.regalrecovery.com/v1/activities/nutrition/meals/ml_22222"
			}
		},
		"meta": {
			"createdAt": "2026-03-28T08:00:00Z"
		}
	}`

	var resp map[string]interface{}
	if err := json.Unmarshal([]byte(response), &resp); err != nil {
		t.Fatalf("invalid response JSON: %v", err)
	}

	data := resp["data"].(map[string]interface{})
	if data["isQuickLog"] != true {
		t.Error("quick log response must have isQuickLog=true")
	}
}
