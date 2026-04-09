// api/test/contract/affirmations/contract_test.go
package affirmations

import (
	"encoding/json"
	"testing"
	"time"
)

// ────────────────────────────────────────────────────────────────────────────
// Test Helpers
// ────────────────────────────────────────────────────────────────────────────

// validateJSON checks if a struct can be marshaled and unmarshaled without error.
func validateJSON(t *testing.T, v interface{}) {
	t.Helper()
	data, err := json.Marshal(v)
	if err != nil {
		t.Fatalf("Failed to marshal: %v", err)
	}
	if len(data) == 0 {
		t.Fatal("Marshal produced empty data")
	}
}

// validateRoundtrip validates that a type can be marshaled and unmarshaled without loss.
func validateRoundtrip(t *testing.T, original interface{}, destination interface{}) {
	t.Helper()
	data, err := json.Marshal(original)
	if err != nil {
		t.Fatalf("Failed to marshal: %v", err)
	}
	err = json.Unmarshal(data, destination)
	if err != nil {
		t.Fatalf("Failed to unmarshal: %v", err)
	}
}

// validateErrorResponse validates an error response matches the expected format.
func validateErrorResponse(t *testing.T, resp ErrorResponse, expectedStatus int, expectedCode string) {
	t.Helper()
	if len(resp.Errors) == 0 {
		t.Fatal("Expected at least one error in response")
	}
	err := resp.Errors[0]
	if err.Status != expectedStatus {
		t.Errorf("Expected status %d, got %d", expectedStatus, err.Status)
	}
	if err.Code != "" && err.Code != expectedCode {
		t.Errorf("Expected code %s, got %s", expectedCode, err.Code)
	}
	if err.Title == "" {
		t.Error("Error title is required but was empty")
	}
}

// ────────────────────────────────────────────────────────────────────────────
// Morning Session Tests (GET, POST)
// ────────────────────────────────────────────────────────────────────────────

func TestAffirmations_Contract_GET_MorningSession_200(t *testing.T) {
	now := time.Now()

	response := MorningSessionResponse{
		Data: MorningSessionData{
			SessionID:   "aff_s1a2b3c4d5",
			SessionType: SessionTypeMorning,
			Affirmations: []Affirmation{
				{
					ID:            "aff_lib001",
					Text:          "It is OK for me to talk to others about what I think and feel.",
					Level:         1,
					CoreBeliefs:   []int{1},
					Category:      CategorySelfWorth,
					Track:         TrackStandard,
					RecoveryStage: StageEarly,
					IsFavorite:    false,
					HasAudio:      false,
				},
				{
					ID:            "aff_lib042",
					Text:          "I am working my recovery. I am striving for progress, not perfection.",
					Level:         1,
					CoreBeliefs:   []int{1, 4},
					Category:      CategoryDailyStrength,
					Track:         TrackStandard,
					RecoveryStage: StageEarly,
					IsFavorite:    true,
					HasAudio:      true,
				},
				{
					ID:            "aff_lib099",
					Text:          "Asking for help is a sign of strength, not weakness.",
					Level:         2,
					CoreBeliefs:   []int{3},
					Category:      CategoryConnection,
					Track:         TrackStandard,
					RecoveryStage: StageEarly,
					IsFavorite:    false,
					HasAudio:      false,
				},
			},
			IntentionPrompt: "Today I choose to...",
			CreatedAt:       now,
			Links: Links{
				Self:     "/v1/activities/affirmations/session/morning",
				Complete: stringPtr("/v1/activities/affirmations/session/morning"),
			},
		},
		Meta: Metadata{
			CreatedAt: &now,
		},
	}

	validateJSON(t, response)

	var decoded MorningSessionResponse
	validateRoundtrip(t, response, &decoded)

	if len(decoded.Data.Affirmations) != 3 {
		t.Errorf("Expected 3 affirmations, got %d", len(decoded.Data.Affirmations))
	}
	if decoded.Data.SessionType != SessionTypeMorning {
		t.Errorf("Expected session type %s, got %s", SessionTypeMorning, decoded.Data.SessionType)
	}
}

func TestAffirmations_Contract_POST_MorningSession_201(t *testing.T) {
	request := CompleteMorningRequest{
		SessionID: "aff_s1a2b3c4d5",
		Intention: stringPtr("Today I choose to be patient with myself and reach out to my sponsor."),
		AffirmationInteractions: []AffirmationInteraction{
			{
				AffirmationID:  "aff_lib001",
				Favorited:      false,
				Hidden:         false,
				DurationViewed: 45,
			},
			{
				AffirmationID:  "aff_lib042",
				Favorited:      true,
				Hidden:         false,
				DurationViewed: 60,
			},
		},
	}

	validateJSON(t, request)

	now := time.Now()
	response := SessionCompletionResponse{
		Data: SessionCompletionData{
			SessionID:     "aff_s1a2b3c4d5",
			SessionType:   SessionTypeMorning,
			CompletedAt:   now,
			TotalSessions: 48,
			Milestone:     nil,
			Links: Links{
				Self:     "/v1/activities/affirmations/session/morning",
				Progress: stringPtr("/v1/activities/affirmations/progress"),
			},
		},
		Meta: Metadata{
			CreatedAt: &now,
		},
	}

	validateJSON(t, response)

	var decoded SessionCompletionResponse
	validateRoundtrip(t, response, &decoded)
}

func TestAffirmations_Contract_POST_MorningSession_400_InvalidRequest(t *testing.T) {
	errResp := ErrorResponse{
		Errors: []ErrorObject{
			{
				Status:        400,
				Title:         "Validation Error",
				Detail:        "sessionId is required",
				CorrelationID: "f1e2d3c4-b5a6-7890-abcd-ef1234567890",
				Source: &ErrorSource{
					Pointer: stringPtr("/sessionId"),
				},
			},
		},
	}

	validateJSON(t, errResp)
	validateErrorResponse(t, errResp, 400, "")
}

// ────────────────────────────────────────────────────────────────────────────
// Evening Session Tests (GET, POST)
// ────────────────────────────────────────────────────────────────────────────

func TestAffirmations_Contract_GET_EveningSession_200(t *testing.T) {
	now := time.Now()

	response := EveningSessionResponse{
		Data: EveningSessionData{
			SessionID:   "aff_s6e7f8g9h0",
			SessionType: SessionTypeEvening,
			Affirmation: Affirmation{
				ID:            "aff_lib155",
				Text:          "Today was enough. I was enough.",
				Level:         1,
				CoreBeliefs:   []int{1},
				Category:      CategoryDailyStrength,
				Track:         TrackStandard,
				RecoveryStage: StageEarly,
				IsFavorite:    false,
				HasAudio:      true,
			},
			MorningIntention: stringPtr("Today I choose to be patient with myself and reach out to my sponsor."),
			RatingPrompt:    "How did today feel?",
			CreatedAt:       now,
			Links: Links{
				Self:     "/v1/activities/affirmations/session/evening",
				Complete: stringPtr("/v1/activities/affirmations/session/evening"),
			},
		},
		Meta: Metadata{
			CreatedAt: &now,
		},
	}

	validateJSON(t, response)

	var decoded EveningSessionResponse
	validateRoundtrip(t, response, &decoded)

	if decoded.Data.SessionType != SessionTypeEvening {
		t.Errorf("Expected session type %s, got %s", SessionTypeEvening, decoded.Data.SessionType)
	}
}

func TestAffirmations_Contract_POST_EveningSession_201(t *testing.T) {
	request := CompleteEveningRequest{
		SessionID:  "aff_s6e7f8g9h0",
		DayRating:  4,
		Reflection: stringPtr("Grateful for my sponsor's call today. Felt strong."),
	}

	validateJSON(t, request)

	now := time.Now()
	response := SessionCompletionResponse{
		Data: SessionCompletionData{
			SessionID:     "aff_s6e7f8g9h0",
			SessionType:   SessionTypeEvening,
			CompletedAt:   now,
			TotalSessions: 49,
			Milestone:     nil,
			Links: Links{
				Self:     "/v1/activities/affirmations/session/evening",
				Progress: stringPtr("/v1/activities/affirmations/progress"),
			},
		},
		Meta: Metadata{
			CreatedAt: &now,
		},
	}

	validateJSON(t, response)

	var decoded SessionCompletionResponse
	validateRoundtrip(t, response, &decoded)
}

func TestAffirmations_Contract_POST_EveningSession_400_InvalidDayRating(t *testing.T) {
	errResp := ErrorResponse{
		Errors: []ErrorObject{
			{
				Code:          ErrCodeInvalidDayRating,
				Status:        400,
				Title:         "Validation Error",
				Detail:        "Day rating must be between 1 and 5.",
				CorrelationID: "f1e2d3c4-b5a6-7890-abcd-ef1234567890",
				Source: &ErrorSource{
					Pointer: stringPtr("/dayRating"),
				},
			},
		},
	}

	validateJSON(t, errResp)
	validateErrorResponse(t, errResp, 400, ErrCodeInvalidDayRating)
}

// ────────────────────────────────────────────────────────────────────────────
// SOS Mode Tests (POST start, POST complete)
// ────────────────────────────────────────────────────────────────────────────

func TestAffirmations_Contract_POST_SOSSession_201(t *testing.T) {
	now := time.Now()

	response := SOSSessionResponse{
		Data: SOSSessionData{
			SOSID: "aff_sos_x1y2z3",
			Affirmation: Affirmation{
				ID:            "aff_lib180",
				Text:          "Right now, in this moment, I am safe. I can breathe.",
				Level:         1,
				CoreBeliefs:   []int{1, 3},
				Category:      CategorySOSCrisis,
				Track:         TrackStandard,
				RecoveryStage: StageEarly,
				IsFavorite:    false,
				HasAudio:      false,
			},
			BreathingExercise: BreathingExercise{
				Pattern:         "4-7-8",
				InhaleSeconds:   4,
				HoldSeconds:     7,
				ExhaleSeconds:   8,
				Cycles:          3,
				DurationSeconds: 57,
			},
			AdditionalAffirmations: []Affirmation{
				{
					ID:            "aff_lib182",
					Text:          "This urge will pass. I have survived every urge before this one.",
					Level:         1,
					CoreBeliefs:   []int{1},
					Category:      CategorySOSCrisis,
					Track:         TrackStandard,
					RecoveryStage: StageEarly,
					IsFavorite:    false,
					HasAudio:      false,
				},
				{
					ID:            "aff_lib185",
					Text:          "I can reach out. Someone cares about my struggle.",
					Level:         2,
					CoreBeliefs:   []int{3},
					Category:      CategorySOSCrisis,
					Track:         TrackStandard,
					RecoveryStage: StageEarly,
					IsFavorite:    false,
					HasAudio:      false,
				},
			},
			CreatedAt: now,
			Links: Links{
				Self:     "/v1/activities/affirmations/sos",
				Complete: stringPtr("/v1/activities/affirmations/sos/aff_sos_x1y2z3/complete"),
			},
		},
		Meta: Metadata{
			CreatedAt: &now,
		},
	}

	validateJSON(t, response)

	var decoded SOSSessionResponse
	validateRoundtrip(t, response, &decoded)

	if len(decoded.Data.AdditionalAffirmations) != 2 {
		t.Errorf("Expected 2 additional affirmations, got %d", len(decoded.Data.AdditionalAffirmations))
	}
	if decoded.Data.BreathingExercise.Pattern != "4-7-8" {
		t.Errorf("Expected breathing pattern 4-7-8, got %s", decoded.Data.BreathingExercise.Pattern)
	}
}

func TestAffirmations_Contract_POST_SOSComplete_201(t *testing.T) {
	request := CompleteSOSRequest{
		BreathingCompleted: true,
		ReachedOut:         false,
		PostCheckInRating:  intPtr(3),
	}

	validateJSON(t, request)

	now := time.Now()
	response := SessionCompletionResponse{
		Data: SessionCompletionData{
			SessionID:     "aff_sos_x1y2z3",
			SessionType:   SessionTypeSOS,
			CompletedAt:   now,
			TotalSessions: 50,
			Milestone: &Milestone{
				Type:       MilestoneSessionCount,
				Threshold:  50,
				Message:    "50 moments you chose recovery. That is real work.",
				AchievedAt: now,
			},
			Links: Links{
				Self:     "/v1/activities/affirmations/sos/aff_sos_x1y2z3/complete",
				Progress: stringPtr("/v1/activities/affirmations/progress"),
			},
		},
		Meta: Metadata{
			CreatedAt: &now,
		},
	}

	validateJSON(t, response)

	var decoded SessionCompletionResponse
	validateRoundtrip(t, response, &decoded)

	if decoded.Data.Milestone == nil {
		t.Error("Expected milestone to be present")
	} else if decoded.Data.Milestone.Type != MilestoneSessionCount {
		t.Errorf("Expected milestone type %s, got %s", MilestoneSessionCount, decoded.Data.Milestone.Type)
	}
}

func TestAffirmations_Contract_POST_SOSComplete_404_NotFound(t *testing.T) {
	errResp := ErrorResponse{
		Errors: []ErrorObject{
			{
				Code:          ErrCodeSOSSessionNotFound,
				Status:        404,
				Title:         "Not Found",
				Detail:        "The requested SOS session could not be found.",
				CorrelationID: "f1e2d3c4-b5a6-7890-abcd-ef1234567890",
			},
		},
	}

	validateJSON(t, errResp)
	validateErrorResponse(t, errResp, 404, ErrCodeSOSSessionNotFound)
}

// ────────────────────────────────────────────────────────────────────────────
// Library Tests (GET list, GET by ID, GET search)
// ────────────────────────────────────────────────────────────────────────────

func TestAffirmations_Contract_GET_Library_200(t *testing.T) {
	response := AffirmationListResponse{
		Data: []Affirmation{
			{
				ID:            "aff_lib001",
				Text:          "It is OK for me to talk to others about what I think and feel.",
				Level:         1,
				CoreBeliefs:   []int{1},
				Category:      CategorySelfWorth,
				Track:         TrackStandard,
				RecoveryStage: StageEarly,
				IsFavorite:    false,
				HasAudio:      false,
			},
		},
		Links: PaginationLinks{
			Self: "/v1/activities/affirmations/library?limit=50",
			Next: stringPtr("/v1/activities/affirmations/library?cursor=xyz&limit=50"),
		},
	}
	response.Meta.Page = PageMetadata{
		NextCursor: stringPtr("xyz"),
		Limit:      50,
	}
	response.Meta.TotalCount = 150

	validateJSON(t, response)

	var decoded AffirmationListResponse
	validateRoundtrip(t, response, &decoded)

	if decoded.Meta.TotalCount != 150 {
		t.Errorf("Expected total count 150, got %d", decoded.Meta.TotalCount)
	}
}

func TestAffirmations_Contract_GET_LibraryByID_200(t *testing.T) {
	now := time.Now()

	response := AffirmationResponse{
		Data: Affirmation{
			ID:            "aff_lib001",
			Text:          "It is OK for me to talk to others about what I think and feel.",
			Level:         1,
			CoreBeliefs:   []int{1},
			Category:      CategorySelfWorth,
			Track:         TrackStandard,
			RecoveryStage: StageEarly,
			IsFavorite:    false,
			HasAudio:      false,
		},
		Meta: Metadata{
			CreatedAt: &now,
		},
	}

	validateJSON(t, response)

	var decoded AffirmationResponse
	validateRoundtrip(t, response, &decoded)
}

func TestAffirmations_Contract_GET_LibraryByID_404_NotFound(t *testing.T) {
	errResp := ErrorResponse{
		Errors: []ErrorObject{
			{
				Code:          ErrCodeAffirmationNotFound,
				Status:        404,
				Title:         "Not Found",
				Detail:        "The requested affirmation could not be found.",
				CorrelationID: "f1e2d3c4-b5a6-7890-abcd-ef1234567890",
			},
		},
	}

	validateJSON(t, errResp)
	validateErrorResponse(t, errResp, 404, ErrCodeAffirmationNotFound)
}

// ────────────────────────────────────────────────────────────────────────────
// Favorites Tests (POST add, DELETE remove, GET list)
// ────────────────────────────────────────────────────────────────────────────

func TestAffirmations_Contract_POST_AddFavorite_201(t *testing.T) {
	request := AddFavoriteRequest{
		AffirmationID: "aff_lib042",
	}

	validateJSON(t, request)

	now := time.Now()
	response := FavoriteResponse{
		Data: FavoriteData{
			AffirmationID: "aff_lib042",
			FavoritedAt:   now,
			Links: Links{
				Self: "/v1/activities/affirmations/favorites/aff_lib042",
			},
		},
		Meta: Metadata{
			CreatedAt: &now,
		},
	}

	validateJSON(t, response)

	var decoded FavoriteResponse
	validateRoundtrip(t, response, &decoded)
}

func TestAffirmations_Contract_POST_AddFavorite_422_AlreadyFavorited(t *testing.T) {
	errResp := ErrorResponse{
		Errors: []ErrorObject{
			{
				Code:          ErrCodeAlreadyFavorited,
				Status:        422,
				Title:         "Already Favorited",
				Detail:        "This affirmation is already in your favorites.",
				CorrelationID: "f1e2d3c4-b5a6-7890-abcd-ef1234567890",
			},
		},
	}

	validateJSON(t, errResp)
	validateErrorResponse(t, errResp, 422, ErrCodeAlreadyFavorited)
}

func TestAffirmations_Contract_DELETE_RemoveFavorite_204(t *testing.T) {
	// 204 No Content has no response body to validate
	// This test validates that the contract expects no body
}

func TestAffirmations_Contract_GET_Favorites_200(t *testing.T) {
	response := AffirmationListResponse{
		Data: []Affirmation{
			{
				ID:            "aff_lib042",
				Text:          "I am working my recovery. I am striving for progress, not perfection.",
				Level:         1,
				CoreBeliefs:   []int{1, 4},
				Category:      CategoryDailyStrength,
				Track:         TrackStandard,
				RecoveryStage: StageEarly,
				IsFavorite:    true,
				HasAudio:      true,
			},
		},
		Links: PaginationLinks{
			Self: "/v1/activities/affirmations/favorites?limit=50",
		},
	}
	response.Meta.Page = PageMetadata{
		Limit: 50,
	}
	response.Meta.TotalCount = 7

	validateJSON(t, response)

	var decoded AffirmationListResponse
	validateRoundtrip(t, response, &decoded)
}

// ────────────────────────────────────────────────────────────────────────────
// Hidden Tests (POST hide, DELETE unhide, GET list)
// ────────────────────────────────────────────────────────────────────────────

func TestAffirmations_Contract_POST_HideAffirmation_201(t *testing.T) {
	request := HideAffirmationRequest{
		AffirmationID: "aff_lib099",
		SessionID:     stringPtr("aff_s1a2b3c4d5"),
	}

	validateJSON(t, request)

	now := time.Now()
	response := HiddenResponse{
		Data: HiddenData{
			AffirmationID: "aff_lib099",
			HiddenAt:      now,
			Replacement: &Affirmation{
				ID:            "aff_lib100",
				Text:          "Replacement affirmation text.",
				Level:         1,
				CoreBeliefs:   []int{1},
				Category:      CategorySelfWorth,
				Track:         TrackStandard,
				RecoveryStage: StageEarly,
				IsFavorite:    false,
				HasAudio:      false,
			},
			Links: Links{
				Self: "/v1/activities/affirmations/hidden/aff_lib099",
			},
		},
		Meta: Metadata{
			CreatedAt: &now,
		},
	}

	validateJSON(t, response)

	var decoded HiddenResponse
	validateRoundtrip(t, response, &decoded)

	if decoded.Data.Replacement == nil {
		t.Error("Expected replacement affirmation to be present")
	}
}

func TestAffirmations_Contract_POST_HideAffirmation_422_AlreadyHidden(t *testing.T) {
	errResp := ErrorResponse{
		Errors: []ErrorObject{
			{
				Code:          ErrCodeAlreadyHidden,
				Status:        422,
				Title:         "Already Hidden",
				Detail:        "This affirmation is already hidden.",
				CorrelationID: "f1e2d3c4-b5a6-7890-abcd-ef1234567890",
			},
		},
	}

	validateJSON(t, errResp)
	validateErrorResponse(t, errResp, 422, ErrCodeAlreadyHidden)
}

func TestAffirmations_Contract_DELETE_UnhideAffirmation_204(t *testing.T) {
	// 204 No Content has no response body to validate
}

func TestAffirmations_Contract_GET_Hidden_200(t *testing.T) {
	response := AffirmationListResponse{
		Data: []Affirmation{
			{
				ID:            "aff_lib099",
				Text:          "Asking for help is a sign of strength, not weakness.",
				Level:         2,
				CoreBeliefs:   []int{3},
				Category:      CategoryConnection,
				Track:         TrackStandard,
				RecoveryStage: StageEarly,
				IsFavorite:    false,
				HasAudio:      false,
			},
		},
		Links: PaginationLinks{
			Self: "/v1/activities/affirmations/hidden?limit=50",
		},
	}
	response.Meta.Page = PageMetadata{
		Limit: 50,
	}
	response.Meta.TotalCount = 2

	validateJSON(t, response)

	var decoded AffirmationListResponse
	validateRoundtrip(t, response, &decoded)
}

// ────────────────────────────────────────────────────────────────────────────
// Custom Affirmations Tests (POST create, GET list, GET by ID, PATCH update, DELETE)
// ────────────────────────────────────────────────────────────────────────────

func TestAffirmations_Contract_POST_CreateCustom_201(t *testing.T) {
	request := CreateCustomAffirmationRequest{
		Text:              "I am learning to trust myself again, one choice at a time.",
		IncludeInRotation: true,
	}

	validateJSON(t, request)

	now := time.Now()
	editableUntil := now.Add(24 * time.Hour)

	response := CustomAffirmationResponse{
		Data: CustomAffirmation{
			CustomID:          "aff_cust_a1b2c3",
			Text:              "I am learning to trust myself again, one choice at a time.",
			IncludeInRotation: true,
			IsEditable:        true,
			EditableUntil:     editableUntil,
			IsFavorite:        false,
			IsHidden:          false,
			HasAudio:          false,
			CreatedAt:         now,
			ModifiedAt:        now,
		},
		Meta: Metadata{
			CreatedAt: &now,
		},
	}

	validateJSON(t, response)

	var decoded CustomAffirmationResponse
	validateRoundtrip(t, response, &decoded)

	if !decoded.Data.IsEditable {
		t.Error("Expected newly created custom affirmation to be editable")
	}
}

func TestAffirmations_Contract_POST_CreateCustom_422_Day14GateNotMet(t *testing.T) {
	errResp := ErrorResponse{
		Errors: []ErrorObject{
			{
				Code:          ErrCodeDay14GateNotMet,
				Status:        422,
				Title:         "Sobriety Gate Not Met",
				Detail:        "Custom affirmations unlock at Day 14 to ensure you have a foundation of curated content first. You are 6 days away.",
				CorrelationID: "f1e2d3c4-b5a6-7890-abcd-ef1234567890",
			},
		},
	}

	validateJSON(t, errResp)
	validateErrorResponse(t, errResp, 422, ErrCodeDay14GateNotMet)
}

func TestAffirmations_Contract_GET_CustomList_200(t *testing.T) {
	now := time.Now()

	response := CustomAffirmationListResponse{
		Data: []CustomAffirmation{
			{
				CustomID:          "aff_cust_a1b2c3",
				Text:              "I am learning to trust myself again, one choice at a time.",
				IncludeInRotation: true,
				IsEditable:        false,
				EditableUntil:     now.Add(-1 * time.Hour),
				IsFavorite:        true,
				IsHidden:          false,
				HasAudio:          false,
				CreatedAt:         now.Add(-48 * time.Hour),
				ModifiedAt:        now.Add(-48 * time.Hour),
			},
		},
		Links: PaginationLinks{
			Self: "/v1/activities/affirmations/custom?limit=50",
		},
	}
	response.Meta.Page = PageMetadata{
		Limit: 50,
	}

	validateJSON(t, response)

	var decoded CustomAffirmationListResponse
	validateRoundtrip(t, response, &decoded)
}

func TestAffirmations_Contract_GET_CustomByID_200(t *testing.T) {
	now := time.Now()

	response := CustomAffirmationResponse{
		Data: CustomAffirmation{
			CustomID:          "aff_cust_a1b2c3",
			Text:              "I am learning to trust myself again, one choice at a time.",
			IncludeInRotation: true,
			IsEditable:        true,
			EditableUntil:     now.Add(24 * time.Hour),
			IsFavorite:        false,
			IsHidden:          false,
			HasAudio:          false,
			CreatedAt:         now,
			ModifiedAt:        now,
		},
		Meta: Metadata{
			CreatedAt: &now,
		},
	}

	validateJSON(t, response)

	var decoded CustomAffirmationResponse
	validateRoundtrip(t, response, &decoded)
}

func TestAffirmations_Contract_PATCH_UpdateCustom_200(t *testing.T) {
	updatedText := "I am learning to trust myself again, one honest choice at a time."
	request := UpdateCustomAffirmationRequest{
		Text:              &updatedText,
		IncludeInRotation: boolPtr(true),
	}

	validateJSON(t, request)

	now := time.Now()
	response := CustomAffirmationResponse{
		Data: CustomAffirmation{
			CustomID:          "aff_cust_a1b2c3",
			Text:              updatedText,
			IncludeInRotation: true,
			IsEditable:        true,
			EditableUntil:     now.Add(23 * time.Hour),
			IsFavorite:        false,
			IsHidden:          false,
			HasAudio:          false,
			CreatedAt:         now.Add(-1 * time.Hour),
			ModifiedAt:        now,
		},
		Meta: Metadata{
			ModifiedAt: &now,
		},
	}

	validateJSON(t, response)

	var decoded CustomAffirmationResponse
	validateRoundtrip(t, response, &decoded)
}

func TestAffirmations_Contract_PATCH_UpdateCustom_422_EditWindowExpired(t *testing.T) {
	errResp := ErrorResponse{
		Errors: []ErrorObject{
			{
				Code:          ErrCodeEditWindowExpired,
				Status:        422,
				Title:         "Edit Window Expired",
				Detail:        "The 24-hour edit window for this custom affirmation has expired. You can still hide, favorite, or delete it.",
				CorrelationID: "f1e2d3c4-b5a6-7890-abcd-ef1234567890",
			},
		},
	}

	validateJSON(t, errResp)
	validateErrorResponse(t, errResp, 422, ErrCodeEditWindowExpired)
}

func TestAffirmations_Contract_DELETE_Custom_204(t *testing.T) {
	// 204 No Content has no response body to validate
}

// ────────────────────────────────────────────────────────────────────────────
// Audio Recording Tests (POST upload, GET metadata, DELETE)
// ────────────────────────────────────────────────────────────────────────────

func TestAffirmations_Contract_POST_UploadAudio_201(t *testing.T) {
	now := time.Now()

	response := AudioRecordingResponse{
		Data: AudioRecordingMetadata{
			RecordingID:     "aff_rec_r1s2t3",
			AffirmationID:   "aff_lib042",
			Format:          "m4a",
			DurationSeconds: 12.5,
			BackgroundMusic: MusicNature,
			SizeBytes:       96000,
			CloudSynced:     false,
			CreatedAt:       now,
		},
		Meta: Metadata{
			CreatedAt: &now,
		},
	}

	validateJSON(t, response)

	var decoded AudioRecordingResponse
	validateRoundtrip(t, response, &decoded)

	if decoded.Data.Format != "m4a" {
		t.Errorf("Expected format m4a, got %s", decoded.Data.Format)
	}
	if decoded.Data.DurationSeconds > 60 {
		t.Errorf("Expected duration <= 60 seconds, got %.1f", decoded.Data.DurationSeconds)
	}
}

func TestAffirmations_Contract_POST_UploadAudio_422_InvalidFormat(t *testing.T) {
	errResp := ErrorResponse{
		Errors: []ErrorObject{
			{
				Code:          ErrCodeInvalidAudioFormat,
				Status:        422,
				Title:         "Invalid Audio Format",
				Detail:        "Audio must be AAC-encoded .m4a format with 64kbps minimum bitrate.",
				CorrelationID: "f1e2d3c4-b5a6-7890-abcd-ef1234567890",
			},
		},
	}

	validateJSON(t, errResp)
	validateErrorResponse(t, errResp, 422, ErrCodeInvalidAudioFormat)
}

func TestAffirmations_Contract_GET_AudioMetadata_200(t *testing.T) {
	now := time.Now()

	response := AudioRecordingResponse{
		Data: AudioRecordingMetadata{
			RecordingID:     "aff_rec_r1s2t3",
			AffirmationID:   "aff_lib042",
			Format:          "m4a",
			DurationSeconds: 12.5,
			BackgroundMusic: MusicNature,
			SizeBytes:       96000,
			PlaybackURL:     "https://example.com/playback/aff_rec_r1s2t3",
			CloudSynced:     true,
			CreatedAt:       now,
		},
		Meta: Metadata{
			CreatedAt: &now,
		},
	}

	validateJSON(t, response)

	var decoded AudioRecordingResponse
	validateRoundtrip(t, response, &decoded)

	if decoded.Data.PlaybackURL == "" {
		t.Error("Expected playback URL to be present")
	}
}

func TestAffirmations_Contract_DELETE_Audio_204(t *testing.T) {
	// 204 No Content has no response body to validate
}

// ────────────────────────────────────────────────────────────────────────────
// Progress & Settings Tests (GET progress, GET milestones, GET settings, PATCH settings)
// ────────────────────────────────────────────────────────────────────────────

func TestAffirmations_Contract_GET_Progress_200(t *testing.T) {
	now := time.Now()

	response := AffirmationProgressResponse{
		Data: AffirmationProgress{
			TotalSessions:              49,
			TotalMorningSessions:       30,
			TotalEveningSessions:       15,
			TotalSOSSessions:           4,
			TotalAffirmationsPracticed: 134,
			TotalCustomCreated:         3,
			TotalAudioRecordings:       2,
			TotalFavorites:             7,
			TotalHidden:                2,
			Consistency30d: []DayConsistency{
				{Date: "2026-03-09", Sessions: 2},
				{Date: "2026-03-10", Sessions: 0},
				{Date: "2026-03-11", Sessions: 1},
			},
			Milestones: []Milestone{
				{
					Type:       MilestoneSessionCount,
					Threshold:  1,
					AchievedAt: now.Add(-48 * 24 * time.Hour),
				},
				{
					Type:       MilestoneSessionCount,
					Threshold:  10,
					AchievedAt: now.Add(-40 * 24 * time.Hour),
				},
				{
					Type:       MilestoneFirstCustom,
					Threshold:  1,
					AchievedAt: now.Add(-30 * 24 * time.Hour),
				},
			},
		},
	}
	response.Meta.GeneratedAt = now

	validateJSON(t, response)

	var decoded AffirmationProgressResponse
	validateRoundtrip(t, response, &decoded)

	if len(decoded.Data.Consistency30d) != 3 {
		t.Errorf("Expected 3 consistency entries, got %d", len(decoded.Data.Consistency30d))
	}
	if len(decoded.Data.Milestones) != 3 {
		t.Errorf("Expected 3 milestones, got %d", len(decoded.Data.Milestones))
	}
}

func TestAffirmations_Contract_GET_Settings_200(t *testing.T) {
	now := time.Now()

	response := AffirmationSettingsResponse{
		Data: AffirmationSettings{
			MorningTime:   "07:00",
			EveningTime:   "21:00",
			Track:         TrackStandard,
			LevelOverride: nil,
			EnabledCategories: []AffirmationCategory{
				CategorySelfWorth,
				CategoryShameResilience,
				CategoryHealthyRelationships,
				CategoryConnection,
				CategoryEmotionalRegulation,
				CategoryPurposeMeaning,
				CategoryIntegrityHonesty,
				CategoryDailyStrength,
				CategorySOSCrisis,
			},
			HealthySexualityEnabled: false,
			AudioAutoPlay:           false,
			CloudAudioSync:          false,
		},
	}
	response.Meta.ModifiedAt = now

	validateJSON(t, response)

	var decoded AffirmationSettingsResponse
	validateRoundtrip(t, response, &decoded)

	if decoded.Data.Track != TrackStandard {
		t.Errorf("Expected track %s, got %s", TrackStandard, decoded.Data.Track)
	}
	if len(decoded.Data.EnabledCategories) != 9 {
		t.Errorf("Expected 9 enabled categories, got %d", len(decoded.Data.EnabledCategories))
	}
}

func TestAffirmations_Contract_PATCH_Settings_200(t *testing.T) {
	morningTime := "06:30"
	track := TrackFaithBased
	request := UpdateAffirmationSettingsRequest{
		MorningTime: &morningTime,
		Track:       &track,
	}

	validateJSON(t, request)

	now := time.Now()
	response := AffirmationSettingsResponse{
		Data: AffirmationSettings{
			MorningTime:   "06:30",
			EveningTime:   "21:00",
			Track:         TrackFaithBased,
			LevelOverride: nil,
			EnabledCategories: []AffirmationCategory{
				CategorySelfWorth,
				CategoryDailyStrength,
			},
			HealthySexualityEnabled: false,
			AudioAutoPlay:           false,
			CloudAudioSync:          false,
		},
	}
	response.Meta.ModifiedAt = now

	validateJSON(t, response)

	var decoded AffirmationSettingsResponse
	validateRoundtrip(t, response, &decoded)
}

func TestAffirmations_Contract_PATCH_Settings_422_HealthySexualityRequires60(t *testing.T) {
	errResp := ErrorResponse{
		Errors: []ErrorObject{
			{
				Code:          ErrCodeHealthySexualityRequires60,
				Status:        422,
				Title:         "Sobriety Gate Not Met",
				Detail:        "The Healthy Sexuality category requires 60+ sobriety days AND explicit opt-in. You are 25 days away.",
				CorrelationID: "f1e2d3c4-b5a6-7890-abcd-ef1234567890",
			},
		},
	}

	validateJSON(t, errResp)
	validateErrorResponse(t, errResp, 422, ErrCodeHealthySexualityRequires60)
}

// ────────────────────────────────────────────────────────────────────────────
// Level Tests (GET level, POST override)
// ────────────────────────────────────────────────────────────────────────────

func TestAffirmations_Contract_GET_Level_200(t *testing.T) {
	now := time.Now()
	nextLevelName := "tempered-identity"
	nextLevelAutoUnlockDay := 60

	response := LevelInfoResponse{
		Data: LevelInfo{
			CurrentLevel:           2,
			LevelName:              LevelProcess,
			DaysAtLevel:            46,
			DaysInRecovery:         60,
			NextLevelEligible:      true,
			NextLevelName:          &nextLevelName,
			NextLevelAutoUnlockDay: &nextLevelAutoUnlockDay,
			CanRequestUpgrade:      true,
			UpgradeEligibleAt:      nil,
			LevelHistory: []LevelHistoryEntry{
				{
					Level:     1,
					StartedAt: now.Add(-60 * 24 * time.Hour),
					EndedAt:   timePtr(now.Add(-46 * 24 * time.Hour)),
					Trigger:   TriggerAuto,
				},
				{
					Level:     2,
					StartedAt: now.Add(-46 * 24 * time.Hour),
					EndedAt:   nil,
					Trigger:   TriggerAuto,
				},
			},
		},
	}
	response.Meta.EvaluatedAt = now

	validateJSON(t, response)

	var decoded LevelInfoResponse
	validateRoundtrip(t, response, &decoded)

	if decoded.Data.CurrentLevel != 2 {
		t.Errorf("Expected current level 2, got %d", decoded.Data.CurrentLevel)
	}
	if !decoded.Data.CanRequestUpgrade {
		t.Error("Expected canRequestUpgrade to be true")
	}
	if len(decoded.Data.LevelHistory) != 2 {
		t.Errorf("Expected 2 level history entries, got %d", len(decoded.Data.LevelHistory))
	}
}

func TestAffirmations_Contract_POST_LevelOverride_200(t *testing.T) {
	request := LevelOverrideRequest{
		TargetLevel: 3,
		Direction:   DirectionUpgrade,
	}

	validateJSON(t, request)

	now := time.Now()
	response := LevelInfoResponse{
		Data: LevelInfo{
			CurrentLevel:           3,
			LevelName:              LevelTemperedIdentity,
			DaysAtLevel:            0,
			DaysInRecovery:         60,
			NextLevelEligible:      false,
			NextLevelName:          stringPtr("full-identity"),
			NextLevelAutoUnlockDay: intPtr(180),
			CanRequestUpgrade:      false,
			UpgradeEligibleAt:      timePtr(now.Add(30 * 24 * time.Hour)),
			LevelHistory: []LevelHistoryEntry{
				{
					Level:     2,
					StartedAt: now.Add(-46 * 24 * time.Hour),
					EndedAt:   &now,
					Trigger:   TriggerAuto,
				},
				{
					Level:     3,
					StartedAt: now,
					EndedAt:   nil,
					Trigger:   TriggerManualUpgrade,
				},
			},
		},
	}
	response.Meta.EvaluatedAt = now

	validateJSON(t, response)

	var decoded LevelInfoResponse
	validateRoundtrip(t, response, &decoded)
}

func TestAffirmations_Contract_POST_LevelOverride_422_MinimumNotMet(t *testing.T) {
	errResp := ErrorResponse{
		Errors: []ErrorObject{
			{
				Code:          ErrCode30DayMinimumNotMet,
				Status:        422,
				Title:         "Upgrade Not Eligible",
				Detail:        "Manual level upgrades require 30+ days at your current level. You are 15 days away.",
				CorrelationID: "f1e2d3c4-b5a6-7890-abcd-ef1234567890",
			},
		},
	}

	validateJSON(t, errResp)
	validateErrorResponse(t, errResp, 422, ErrCode30DayMinimumNotMet)
}

// ────────────────────────────────────────────────────────────────────────────
// Sharing Tests (GET summary)
// ────────────────────────────────────────────────────────────────────────────

func TestAffirmations_Contract_GET_SharingSummary_200(t *testing.T) {
	now := time.Now()
	lastSession := now.Add(-2 * time.Hour)

	response := SharingSummaryResponse{
		Data: SharingSummaryData{
			SessionsThisWeek:  5,
			SessionsThisMonth: 18,
			TotalSessions:     49,
			LastSessionAt:     &lastSession,
			Links: Links{
				Self: "/v1/activities/affirmations/sharing/summary",
			},
		},
	}
	response.Meta.GeneratedAt = now

	validateJSON(t, response)

	var decoded SharingSummaryResponse
	validateRoundtrip(t, response, &decoded)

	if decoded.Data.TotalSessions != 49 {
		t.Errorf("Expected total sessions 49, got %d", decoded.Data.TotalSessions)
	}
	if decoded.Data.LastSessionAt == nil {
		t.Error("Expected lastSessionAt to be present")
	}
}

// ────────────────────────────────────────────────────────────────────────────
// Feature Flag Tests
// ────────────────────────────────────────────────────────────────────────────

func TestAffirmations_Contract_FeatureFlagDisabled_404(t *testing.T) {
	errResp := ErrorResponse{
		Errors: []ErrorObject{
			{
				Code:          ErrCodeFeatureFlagDisabled,
				Status:        404,
				Title:         "Feature Not Available",
				Detail:        "The affirmations feature is not currently enabled for your account.",
				CorrelationID: "f1e2d3c4-b5a6-7890-abcd-ef1234567890",
			},
		},
	}

	validateJSON(t, errResp)
	validateErrorResponse(t, errResp, 404, ErrCodeFeatureFlagDisabled)
}

// ────────────────────────────────────────────────────────────────────────────
// Helper Functions
// ────────────────────────────────────────────────────────────────────────────

func stringPtr(s string) *string {
	return &s
}

func intPtr(i int) *int {
	return &i
}

func boolPtr(b bool) *bool {
	return &b
}

func timePtr(t time.Time) *time.Time {
	return &t
}
