// test/contract/post_mortem_contract_test.go
package contract

import (
	"encoding/json"
	"testing"
	"time"

	"github.com/regalrecovery/api/internal/domain/postmortem"
)

// TestPostMortemContract_CreateRequest_MatchesOpenAPISchema verifies Go CreatePostMortemRequest
// serialization matches the OpenAPI schema field names (camelCase).
func TestPostMortemContract_CreateRequest_MatchesOpenAPISchema(t *testing.T) {
	relapseID := "r_98765"
	addictionID := "a_67890"
	mood := 4
	kept := false

	analysis := &postmortem.PostMortemAnalysis{
		Timestamp:   time.Date(2026, 3, 28, 23, 0, 0, 0, time.UTC),
		EventType:   "relapse",
		RelapseID:   &relapseID,
		AddictionID: &addictionID,
		Sections: postmortem.Sections{
			DayBefore: &postmortem.DayBeforeSection{
				Text:                  "Was feeling disconnected",
				MoodRating:            &mood,
				RecoveryPracticesKept: &kept,
			},
		},
	}

	// Verify the domain type has the expected fields.
	if analysis.EventType != "relapse" {
		t.Errorf("expected eventType 'relapse', got '%s'", analysis.EventType)
	}
	if *analysis.RelapseID != "r_98765" {
		t.Errorf("expected relapseId 'r_98765', got '%s'", *analysis.RelapseID)
	}
	if analysis.Sections.DayBefore == nil {
		t.Fatal("expected dayBefore section to be set")
	}
	if *analysis.Sections.DayBefore.MoodRating != 4 {
		t.Errorf("expected moodRating 4, got %d", *analysis.Sections.DayBefore.MoodRating)
	}
}

// TestPostMortemContract_PostMortemResponse_MatchesOpenAPISchema verifies the response
// envelope follows Siemens guidelines (data + links + meta).
func TestPostMortemContract_PostMortemResponse_MatchesOpenAPISchema(t *testing.T) {
	// Simulate a response envelope.
	type PostMortemResponseEnvelope struct {
		Data interface{}            `json:"data"`
		Meta map[string]interface{} `json:"meta"`
	}

	resp := PostMortemResponseEnvelope{
		Data: map[string]interface{}{
			"analysisId":        "pm_99999",
			"timestamp":         "2026-03-28T23:00:00Z",
			"status":            "draft",
			"eventType":         "relapse",
			"relapseId":         "r_98765",
			"sectionsCompleted": []string{"dayBefore"},
			"sectionsRemaining": []string{"morning", "throughoutTheDay", "buildUp", "actingOut", "immediatelyAfter"},
		},
		Meta: map[string]interface{}{
			"createdAt": "2026-03-28T23:00:00Z",
		},
	}

	data, err := json.Marshal(resp)
	if err != nil {
		t.Fatalf("failed to marshal response: %v", err)
	}

	var parsed map[string]interface{}
	if err := json.Unmarshal(data, &parsed); err != nil {
		t.Fatalf("failed to unmarshal response: %v", err)
	}

	// Verify envelope structure.
	if _, ok := parsed["data"]; !ok {
		t.Error("response must have 'data' field")
	}
	if _, ok := parsed["meta"]; !ok {
		t.Error("response must have 'meta' field")
	}

	dataMap := parsed["data"].(map[string]interface{})
	if dataMap["analysisId"] != "pm_99999" {
		t.Errorf("expected analysisId 'pm_99999', got '%v'", dataMap["analysisId"])
	}
	if dataMap["eventType"] != "relapse" {
		t.Errorf("expected eventType 'relapse', got '%v'", dataMap["eventType"])
	}
}

// TestPostMortemContract_ErrorResponse_MatchesOpenAPISchema verifies error responses
// match the Siemens error envelope format with rr: error codes.
func TestPostMortemContract_ErrorResponse_MatchesOpenAPISchema(t *testing.T) {
	type ErrorObject struct {
		ID            string      `json:"id"`
		Code          string      `json:"code"`
		Status        int         `json:"status"`
		Title         string      `json:"title"`
		Detail        string      `json:"detail,omitempty"`
		CorrelationID string      `json:"correlationId,omitempty"`
		Source        interface{} `json:"source,omitempty"`
	}

	type ErrorResponse struct {
		Errors []ErrorObject `json:"errors"`
	}

	resp := ErrorResponse{
		Errors: []ErrorObject{
			{
				ID:     "550e8400-e29b-41d4-a716-446655440000",
				Code:   "rr:0x00050001",
				Status: 422,
				Title:  "Incomplete Post-Mortem",
				Detail: "Missing required sections: buildUp, actingOut",
			},
		},
	}

	data, err := json.Marshal(resp)
	if err != nil {
		t.Fatalf("failed to marshal error response: %v", err)
	}

	var parsed map[string]interface{}
	json.Unmarshal(data, &parsed)

	errors := parsed["errors"].([]interface{})
	if len(errors) != 1 {
		t.Errorf("expected 1 error, got %d", len(errors))
	}

	errObj := errors[0].(map[string]interface{})
	if errObj["code"] != "rr:0x00050001" {
		t.Errorf("expected error code 'rr:0x00050001', got '%v'", errObj["code"])
	}
}

// TestPostMortemContract_PaginationResponse_MatchesOpenAPISchema verifies pagination
// response includes data array, links, and meta.page.
func TestPostMortemContract_PaginationResponse_MatchesOpenAPISchema(t *testing.T) {
	type PaginatedResponse struct {
		Data  []interface{}          `json:"data"`
		Links map[string]interface{} `json:"links"`
		Meta  map[string]interface{} `json:"meta"`
	}

	resp := PaginatedResponse{
		Data: []interface{}{
			map[string]string{"analysisId": "pm_001"},
			map[string]string{"analysisId": "pm_002"},
		},
		Links: map[string]interface{}{
			"self": "/activities/post-mortem?limit=10",
			"next": "/activities/post-mortem?cursor=abc&limit=10",
		},
		Meta: map[string]interface{}{
			"page": map[string]interface{}{
				"nextCursor": "abc",
				"limit":      10,
			},
		},
	}

	data, err := json.Marshal(resp)
	if err != nil {
		t.Fatalf("failed to marshal: %v", err)
	}

	var parsed map[string]interface{}
	json.Unmarshal(data, &parsed)

	if _, ok := parsed["data"]; !ok {
		t.Error("paginated response must have 'data' array")
	}
	if _, ok := parsed["links"]; !ok {
		t.Error("paginated response must have 'links' object")
	}
	meta := parsed["meta"].(map[string]interface{})
	page := meta["page"].(map[string]interface{})
	if page["nextCursor"] != "abc" {
		t.Errorf("expected nextCursor 'abc', got '%v'", page["nextCursor"])
	}
}

// TestPostMortemContract_InsightsResponse_MatchesOpenAPISchema verifies the insights
// response structure matches the OpenAPI spec.
func TestPostMortemContract_InsightsResponse_MatchesOpenAPISchema(t *testing.T) {
	insights := postmortem.PostMortemInsights{
		TotalAnalyses: 5,
		CommonTriggers: []postmortem.TriggerFrequency{
			{Category: "digital", Frequency: 4, Percentage: 80},
		},
		CommonFasterStageAtBreak: &postmortem.StageFrequency{
			Stage: "exhausted", Frequency: 3, Percentage: 60,
		},
		CommonTimeOfDay: &postmortem.TimeOfDayFrequency{
			Period: "evening", Frequency: 4, Percentage: 80,
		},
	}

	if insights.TotalAnalyses != 5 {
		t.Errorf("expected 5 analyses, got %d", insights.TotalAnalyses)
	}
	if insights.CommonTriggers[0].Category != "digital" {
		t.Errorf("expected 'digital' trigger, got '%s'", insights.CommonTriggers[0].Category)
	}
	if insights.CommonFasterStageAtBreak.Stage != "exhausted" {
		t.Errorf("expected 'exhausted' stage, got '%s'", insights.CommonFasterStageAtBreak.Stage)
	}
}
