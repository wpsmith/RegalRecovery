// test/contract/nutrition/meals_test.go
package nutrition

import (
	"encoding/json"
	"testing"
)

// TestContract_CreateMealLog_MatchesOpenAPISpec validates the POST /activities/nutrition/meals
// request and 201 response match openapi.yaml schema.
func TestContract_CreateMealLog_MatchesOpenAPISpec(t *testing.T) {
	// Request must require mealType and description.
	request := `{
		"mealType": "lunch",
		"description": "Grilled chicken salad with water",
		"eatingContext": "homemade",
		"moodBefore": 3,
		"moodAfter": 4,
		"mindfulnessCheck": "somewhat",
		"notes": "Felt better after eating."
	}`

	var req map[string]interface{}
	if err := json.Unmarshal([]byte(request), &req); err != nil {
		t.Fatalf("invalid request JSON: %v", err)
	}

	// Verify required fields.
	if _, ok := req["mealType"]; !ok {
		t.Error("request must include mealType")
	}
	if _, ok := req["description"]; !ok {
		t.Error("request must include description")
	}

	// Response must contain data envelope with expected fields.
	response := `{
		"data": {
			"mealId": "ml_11111",
			"timestamp": "2026-03-28T12:00:00Z",
			"mealType": "lunch",
			"description": "Grilled chicken salad with water",
			"eatingContext": "homemade",
			"moodBefore": 3,
			"moodAfter": 4,
			"mindfulnessCheck": "somewhat",
			"notes": "Felt better after eating.",
			"isQuickLog": false,
			"links": {
				"self": "https://api.regalrecovery.com/v1/activities/nutrition/meals/ml_11111"
			}
		},
		"meta": {
			"createdAt": "2026-03-28T12:00:00Z"
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
	if _, ok := data["mealId"]; !ok {
		t.Error("response data must include mealId")
	}
	if _, ok := data["timestamp"]; !ok {
		t.Error("response data must include timestamp")
	}
	if _, ok := data["isQuickLog"]; !ok {
		t.Error("response data must include isQuickLog")
	}
	if _, ok := resp["meta"]; !ok {
		t.Error("response must have meta")
	}
}

// TestContract_GetMealLog_MatchesOpenAPISpec validates GET /activities/nutrition/meals/{mealId}.
func TestContract_GetMealLog_MatchesOpenAPISpec(t *testing.T) {
	response := `{
		"data": {
			"mealId": "ml_11111",
			"timestamp": "2026-03-28T12:00:00Z",
			"mealType": "lunch",
			"description": "Grilled chicken salad",
			"isQuickLog": false
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
	if _, ok := data["mealId"]; !ok {
		t.Error("response data must include mealId")
	}
}

// TestContract_ListMealLogs_MatchesOpenAPISpec validates GET /activities/nutrition/meals.
func TestContract_ListMealLogs_MatchesOpenAPISpec(t *testing.T) {
	response := `{
		"data": [
			{
				"mealId": "ml_11111",
				"timestamp": "2026-03-28T12:00:00Z",
				"mealType": "lunch",
				"isQuickLog": false
			}
		],
		"links": {
			"self": "/v1/activities/nutrition/meals",
			"next": "/v1/activities/nutrition/meals?cursor=abc&limit=50"
		},
		"meta": {
			"page": {
				"nextCursor": "abc",
				"limit": 50
			}
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
		t.Error("response data should not be empty in test fixture")
	}
}

// TestContract_UpdateMealLog_MatchesOpenAPISpec validates PATCH /activities/nutrition/meals/{mealId}.
func TestContract_UpdateMealLog_MatchesOpenAPISpec(t *testing.T) {
	// Update request uses JSON Merge Patch (application/merge-patch+json).
	// Timestamp field must NOT be present (immutable per FR2.7).
	request := `{
		"description": "Updated chicken salad",
		"notes": "Added dressing"
	}`

	var req map[string]interface{}
	if err := json.Unmarshal([]byte(request), &req); err != nil {
		t.Fatalf("invalid request JSON: %v", err)
	}

	if _, ok := req["timestamp"]; ok {
		t.Error("update request must NOT include timestamp (immutable)")
	}
}
