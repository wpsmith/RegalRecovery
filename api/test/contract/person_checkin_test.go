// test/contract/person_checkin_test.go
package contract

import (
	"encoding/json"
	"testing"

	"github.com/regalrecovery/api/internal/domain/personcheckin"
)

// These contract tests validate that our Go types conform to the OpenAPI spec.
// They verify serialization/deserialization matches the spec's expected shapes.

func TestContract_PersonCheckIn_CreateRequest_MatchesSpec(t *testing.T) {
	// Spec: CreatePersonCheckInRequest requires checkInType and method.
	jsonStr := `{
		"checkInType": "spouse",
		"method": "in-person",
		"timestamp": "2026-03-28T18:30:00Z",
		"contactName": "Sarah",
		"durationMinutes": 30,
		"qualityRating": 4,
		"topicsDiscussed": ["relationships-marriage", "emotions-feelings", "accountability"],
		"notes": "Had a really honest conversation.",
		"followUpItems": ["Schedule a date night for Friday"]
	}`

	var req personcheckin.CreatePersonCheckInRequest
	if err := json.Unmarshal([]byte(jsonStr), &req); err != nil {
		t.Fatalf("failed to unmarshal create request: %v", err)
	}

	if req.CheckInType != personcheckin.CheckInTypeSpouse {
		t.Fatalf("expected spouse, got %s", req.CheckInType)
	}
	if req.Method != personcheckin.MethodInPerson {
		t.Fatalf("expected in-person, got %s", req.Method)
	}
	if len(req.TopicsDiscussed) != 3 {
		t.Fatalf("expected 3 topics, got %d", len(req.TopicsDiscussed))
	}
	if len(req.FollowUpItems) != 1 {
		t.Fatalf("expected 1 follow-up item, got %d", len(req.FollowUpItems))
	}
}

func TestContract_PersonCheckIn_CreateResponse_MatchesSpec(t *testing.T) {
	// Spec: PersonCheckInResponse has data, meta envelope.
	resp := personcheckin.PersonCheckInResponse{
		Data: personcheckin.PersonCheckIn{
			CheckInID:   "pci_11111",
			CheckInType: personcheckin.CheckInTypeSpouse,
			Method:      personcheckin.MethodInPerson,
		},
		Meta: map[string]interface{}{
			"createdAt":     "2026-03-28T18:30:00Z",
			"streakUpdated": true,
			"currentStreak": 5,
			"encouragement": "Showing up for that conversation took courage.",
		},
	}

	data, err := json.Marshal(resp)
	if err != nil {
		t.Fatalf("failed to marshal response: %v", err)
	}

	var decoded map[string]interface{}
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("failed to unmarshal response: %v", err)
	}

	if _, ok := decoded["data"]; !ok {
		t.Fatal("response missing 'data' envelope")
	}
	if _, ok := decoded["meta"]; !ok {
		t.Fatal("response missing 'meta' envelope")
	}
}

func TestContract_PersonCheckIn_ListResponse_MatchesSpec(t *testing.T) {
	resp := personcheckin.PersonCheckInListResponse{
		Data: []personcheckin.PersonCheckIn{
			{CheckInID: "pci_1", CheckInType: personcheckin.CheckInTypeSpouse},
		},
		Links: personcheckin.PaginationLinks{
			Self: "/activities/person-check-ins?limit=25",
		},
		Meta: map[string]interface{}{
			"page": personcheckin.PageMetadata{Limit: 25},
		},
	}

	data, err := json.Marshal(resp)
	if err != nil {
		t.Fatalf("failed to marshal list response: %v", err)
	}

	var decoded map[string]interface{}
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("failed to unmarshal list response: %v", err)
	}

	if _, ok := decoded["data"]; !ok {
		t.Fatal("list response missing 'data'")
	}
	if _, ok := decoded["links"]; !ok {
		t.Fatal("list response missing 'links'")
	}
	if _, ok := decoded["meta"]; !ok {
		t.Fatal("list response missing 'meta'")
	}
}

func TestContract_PersonCheckIn_StreaksResponse_MatchesSpec(t *testing.T) {
	resp := personcheckin.PersonCheckInStreaksResponse{
		Data: personcheckin.StreaksResponseData{
			Streaks: []personcheckin.PersonCheckInStreak{
				{CheckInType: personcheckin.CheckInTypeSpouse, CurrentStreak: 5, LongestStreak: 21, StreakUnit: "days"},
			},
			Combined: personcheckin.CombinedStreakData{TotalCheckInsThisWeek: 8, TotalCheckInsThisMonth: 36},
		},
		Links: personcheckin.Links{Self: "/activities/person-check-ins/streaks"},
		Meta:  map[string]interface{}{"retrievedAt": "2026-03-28T20:00:00Z"},
	}

	data, err := json.Marshal(resp)
	if err != nil {
		t.Fatalf("failed to marshal streaks response: %v", err)
	}

	var decoded map[string]interface{}
	json.Unmarshal(data, &decoded)

	dataObj := decoded["data"].(map[string]interface{})
	if _, ok := dataObj["streaks"]; !ok {
		t.Fatal("streaks response missing 'data.streaks'")
	}
	if _, ok := dataObj["combined"]; !ok {
		t.Fatal("streaks response missing 'data.combined'")
	}
}

func TestContract_PersonCheckIn_SettingsResponse_MatchesSpec(t *testing.T) {
	settings := personcheckin.DefaultSettings("u_test", "DEFAULT")
	resp := personcheckin.PersonCheckInSettingsResponse{
		Data:  *settings,
		Links: personcheckin.Links{Self: "/activities/person-check-ins/settings"},
		Meta:  map[string]interface{}{},
	}

	data, err := json.Marshal(resp)
	if err != nil {
		t.Fatalf("failed to marshal settings response: %v", err)
	}

	var decoded map[string]interface{}
	json.Unmarshal(data, &decoded)

	dataObj := decoded["data"].(map[string]interface{})
	if _, ok := dataObj["spouse"]; !ok {
		t.Fatal("settings response missing 'data.spouse'")
	}
	if _, ok := dataObj["sponsor"]; !ok {
		t.Fatal("settings response missing 'data.sponsor'")
	}
	if _, ok := dataObj["counselorCoach"]; !ok {
		t.Fatal("settings response missing 'data.counselorCoach'")
	}
}

func TestContract_PersonCheckIn_TrendsResponse_MatchesSpec(t *testing.T) {
	resp := personcheckin.PersonCheckInTrendsResponse{
		Data: personcheckin.TrendsData{
			Frequency:          []personcheckin.FrequencyDataPoint{},
			MethodDistribution: map[string]map[string]int{},
			QualityTrends:      map[string]personcheckin.QualityTrendData{},
			TopicFrequency:     []personcheckin.TopicFrequency{},
			Balance:            personcheckin.BalanceData{Gaps: []personcheckin.BalanceGap{}},
		},
		Links: personcheckin.Links{Self: "/activities/person-check-ins/trends?period=30d"},
		Meta:  map[string]interface{}{"period": "30d"},
	}

	data, err := json.Marshal(resp)
	if err != nil {
		t.Fatalf("failed to marshal trends response: %v", err)
	}

	var decoded map[string]interface{}
	json.Unmarshal(data, &decoded)

	dataObj := decoded["data"].(map[string]interface{})
	requiredFields := []string{"frequency", "methodDistribution", "qualityTrends", "topicFrequency", "balance"}
	for _, field := range requiredFields {
		if _, ok := dataObj[field]; !ok {
			t.Fatalf("trends response missing 'data.%s'", field)
		}
	}
}

func TestContract_PersonCheckIn_CalendarResponse_MatchesSpec(t *testing.T) {
	resp := personcheckin.PersonCheckInCalendarResponse{
		Data: personcheckin.CalendarData{
			Month: "2026-03",
			Days:  []personcheckin.CalendarDay{},
		},
		Links: personcheckin.Links{Self: "/activities/person-check-ins/calendar?month=2026-03"},
		Meta:  map[string]interface{}{"totalCheckIns": 0},
	}

	data, err := json.Marshal(resp)
	if err != nil {
		t.Fatalf("failed to marshal calendar response: %v", err)
	}

	var decoded map[string]interface{}
	json.Unmarshal(data, &decoded)

	dataObj := decoded["data"].(map[string]interface{})
	if _, ok := dataObj["month"]; !ok {
		t.Fatal("calendar response missing 'data.month'")
	}
	if _, ok := dataObj["days"]; !ok {
		t.Fatal("calendar response missing 'data.days'")
	}
}

func TestContract_PersonCheckIn_ErrorResponse_MatchesSpec(t *testing.T) {
	// Spec: ErrorResponse has errors array with status, code, title.
	errResp := struct {
		Errors []struct {
			Status int    `json:"status"`
			Code   string `json:"code"`
			Title  string `json:"title"`
		} `json:"errors"`
	}{
		Errors: []struct {
			Status int    `json:"status"`
			Code   string `json:"code"`
			Title  string `json:"title"`
		}{
			{Status: 422, Code: "rr:0x42210001", Title: "Validation error"},
		},
	}

	data, err := json.Marshal(errResp)
	if err != nil {
		t.Fatalf("failed to marshal error response: %v", err)
	}

	var decoded map[string]interface{}
	json.Unmarshal(data, &decoded)

	errors := decoded["errors"].([]interface{})
	if len(errors) != 1 {
		t.Fatalf("expected 1 error, got %d", len(errors))
	}

	errObj := errors[0].(map[string]interface{})
	if errObj["code"].(string)[:3] != "rr:" {
		t.Fatal("error code must start with 'rr:'")
	}
}

func TestContract_PersonCheckIn_PaginationLinks_MatchesSpec(t *testing.T) {
	next := "/activities/person-check-ins?cursor=abc&limit=25"
	links := personcheckin.PaginationLinks{
		Self: "/activities/person-check-ins?limit=25",
		Next: &next,
	}

	data, err := json.Marshal(links)
	if err != nil {
		t.Fatalf("failed to marshal pagination links: %v", err)
	}

	var decoded map[string]interface{}
	json.Unmarshal(data, &decoded)

	if _, ok := decoded["self"]; !ok {
		t.Fatal("pagination links missing 'self'")
	}
	if _, ok := decoded["next"]; !ok {
		t.Fatal("pagination links missing 'next'")
	}
}

func TestContract_PersonCheckIn_QuickLogRequest_MatchesSpec(t *testing.T) {
	jsonStr := `{"checkInType": "sponsor"}`

	var req personcheckin.QuickLogPersonCheckInRequest
	if err := json.Unmarshal([]byte(jsonStr), &req); err != nil {
		t.Fatalf("failed to unmarshal quick-log request: %v", err)
	}

	if req.CheckInType != personcheckin.CheckInTypeSponsor {
		t.Fatalf("expected sponsor, got %s", req.CheckInType)
	}
	if req.Method != nil {
		t.Fatal("expected nil method for quick-log")
	}
}

func TestContract_PersonCheckIn_UpdateRequest_ContentType_MergePatch(t *testing.T) {
	// The spec specifies content type: application/merge-patch+json.
	// This test validates that partial updates work correctly.
	jsonStr := `{
		"qualityRating": 4,
		"topicsDiscussed": ["sobriety-recovery", "step-work"],
		"notes": "Great conversation about Step 4 progress."
	}`

	var req personcheckin.UpdatePersonCheckInRequest
	if err := json.Unmarshal([]byte(jsonStr), &req); err != nil {
		t.Fatalf("failed to unmarshal update request: %v", err)
	}

	if req.QualityRating == nil || *req.QualityRating != 4 {
		t.Fatal("expected qualityRating 4")
	}
	if req.Method != nil {
		t.Fatal("unset fields should be nil in merge patch")
	}
	if req.ContactName != nil {
		t.Fatal("unset fields should be nil in merge patch")
	}
}
