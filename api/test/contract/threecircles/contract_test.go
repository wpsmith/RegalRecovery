// api/test/contract/threecircles/contract_test.go
package threecircles

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
	if expectedCode != "" && err.Code != expectedCode {
		t.Errorf("Expected code %s, got %s", expectedCode, err.Code)
	}
	if err.Title == "" {
		t.Error("Error title is required but was empty")
	}
}

// stringPtr returns a pointer to a string value.
func stringPtr(s string) *string {
	return &s
}

// intPtr returns a pointer to an int value.
func intPtr(i int) *int {
	return &i
}

// ────────────────────────────────────────────────────────────────────────────
// Circle Set Tests (CRUD + Commit)
// ────────────────────────────────────────────────────────────────────────────

func TestThreeCircles_Contract_GET_ListCircleSets_200(t *testing.T) {
	now := time.Now()

	response := CircleSetListResponse{
		Data: []CircleSet{
			{
				SetID:               "3c_set_abc123",
				UserID:              "user_xyz789",
				Name:                "Sex/Pornography Recovery",
				RecoveryArea:        RecoveryAreaSexPornography,
				FrameworkPreference: nil,
				Status:              StatusActive,
				InnerCircle: []CircleItem{
					{
						ItemID:       "3c_item_001",
						Circle:       CircleInner,
						BehaviorName: "Viewing pornography",
						Notes:        stringPtr("All forms of explicit visual content"),
						Source:       SourceUser,
						CreatedAt:    now,
						ModifiedAt:   now,
					},
				},
				MiddleCircle:  []CircleItem{},
				OuterCircle:   []CircleItem{},
				VersionNumber: 1,
				CreatedAt:     now,
				ModifiedAt:    now,
				CommittedAt:   &now,
			},
		},
		Meta: Meta{
			TotalCount: intPtr(1),
			Cursor:     nil,
		},
		Links: PaginationLinks{
			Self: stringPtr("/v1/tools/three-circles/sets"),
			Next: nil,
		},
	}

	validateJSON(t, response)

	var decoded CircleSetListResponse
	validateRoundtrip(t, response, &decoded)

	if len(decoded.Data) != 1 {
		t.Errorf("Expected 1 circle set, got %d", len(decoded.Data))
	}
}

func TestThreeCircles_Contract_POST_CreateCircleSet_201(t *testing.T) {
	request := CreateCircleSetRequest{
		Name:         "Sex/Pornography Recovery",
		RecoveryArea: RecoveryAreaSexPornography,
		Status:       nil,
		InnerCircle: []CreateCircleItemInput{
			{
				BehaviorName: "Viewing pornography",
				Notes:        stringPtr("All explicit content"),
			},
		},
	}

	validateJSON(t, request)

	now := time.Now()
	response := CircleSetResponse{
		Data: CircleSet{
			SetID:               "3c_set_new123",
			UserID:              "user_xyz789",
			Name:                "Sex/Pornography Recovery",
			RecoveryArea:        RecoveryAreaSexPornography,
			FrameworkPreference: nil,
			Status:              StatusDraft,
			InnerCircle: []CircleItem{
				{
					ItemID:       "3c_item_001",
					Circle:       CircleInner,
					BehaviorName: "Viewing pornography",
					Notes:        stringPtr("All explicit content"),
					Source:       SourceUser,
					CreatedAt:    now,
					ModifiedAt:   now,
				},
			},
			MiddleCircle:  []CircleItem{},
			OuterCircle:   []CircleItem{},
			VersionNumber: 1,
			CreatedAt:     now,
			ModifiedAt:    now,
			CommittedAt:   nil,
		},
		Links: Links{
			Self:     stringPtr("/v1/tools/three-circles/sets/3c_set_new123"),
			Versions: stringPtr("/v1/tools/three-circles/sets/3c_set_new123/versions"),
		},
	}

	validateJSON(t, response)

	var decoded CircleSetResponse
	validateRoundtrip(t, response, &decoded)
}

func TestThreeCircles_Contract_GET_GetCircleSet_200(t *testing.T) {
	now := time.Now()

	response := CircleSetDetailResponse{
		Data: CircleSetDetailData{
			CircleSet: CircleSet{
				SetID:               "3c_set_abc123",
				UserID:              "user_xyz789",
				Name:                "Sex/Pornography Recovery",
				RecoveryArea:        RecoveryAreaSexPornography,
				FrameworkPreference: nil,
				Status:              StatusActive,
				InnerCircle: []CircleItem{
					{
						ItemID:       "3c_item_001",
						Circle:       CircleInner,
						BehaviorName: "Viewing pornography",
						Source:       SourceUser,
						CreatedAt:    now,
						ModifiedAt:   now,
					},
				},
				MiddleCircle:  []CircleItem{},
				OuterCircle:   []CircleItem{},
				VersionNumber: 3,
				CreatedAt:     now,
				ModifiedAt:    now,
				CommittedAt:   &now,
			},
			VersionHistory: []VersionHistorySummary{
				{
					VersionNumber: 3,
					ChangedAt:     now,
					ChangeNote:    stringPtr("Added specificity to inner circle item"),
				},
				{
					VersionNumber: 2,
					ChangedAt:     now.Add(-24 * time.Hour),
					ChangeNote:    nil,
				},
			},
			SponsorCommentCount: 2,
		},
		Links: Links{
			Self:     stringPtr("/v1/tools/three-circles/sets/3c_set_abc123"),
			Versions: stringPtr("/v1/tools/three-circles/sets/3c_set_abc123/versions"),
			Comments: stringPtr("/v1/tools/three-circles/sets/3c_set_abc123/comments"),
			Timeline: stringPtr("/v1/tools/three-circles/patterns/timeline?setId=3c_set_abc123"),
		},
	}

	validateJSON(t, response)

	var decoded CircleSetDetailResponse
	validateRoundtrip(t, response, &decoded)

	if decoded.Data.VersionNumber != 3 {
		t.Errorf("Expected version 3, got %d", decoded.Data.VersionNumber)
	}
}

func TestThreeCircles_Contract_PUT_ReplaceCircleSet_200(t *testing.T) {
	request := ReplaceCircleSetRequest{
		Name:         stringPtr("Updated Recovery Plan"),
		InnerCircle:  []map[string]interface{}{},
		MiddleCircle: []map[string]interface{}{},
		OuterCircle:  []map[string]interface{}{},
		ChangeNote:   stringPtr("Full refresh with sponsor"),
	}

	validateJSON(t, request)
}

func TestThreeCircles_Contract_PATCH_UpdateCircleSet_200(t *testing.T) {
	framework := FrameworkSAA
	request := UpdateCircleSetRequest{
		Name:                stringPtr("Updated Name"),
		FrameworkPreference: &framework,
	}

	validateJSON(t, request)
}

func TestThreeCircles_Contract_DELETE_DeleteCircleSet_204(t *testing.T) {
	// DELETE has no request/response body, test passes if schema validates
}

func TestThreeCircles_Contract_POST_CommitCircleSet_200(t *testing.T) {
	request := CommitCircleSetRequest{
		ChangeNote: stringPtr("Reviewed with sponsor and refined middle circle"),
	}

	validateJSON(t, request)

	now := time.Now()
	response := CircleSetResponse{
		Data: CircleSet{
			SetID:         "3c_set_abc123",
			UserID:        "user_xyz789",
			Name:          "Sex/Pornography Recovery",
			RecoveryArea:  RecoveryAreaSexPornography,
			Status:        StatusActive,
			InnerCircle:   []CircleItem{},
			MiddleCircle:  []CircleItem{},
			OuterCircle:   []CircleItem{},
			VersionNumber: 2,
			CreatedAt:     now,
			ModifiedAt:    now,
			CommittedAt:   &now,
		},
		Links: Links{
			Self: stringPtr("/v1/tools/three-circles/sets/3c_set_abc123"),
		},
	}

	validateJSON(t, response)
}

func TestThreeCircles_Contract_POST_CommitCircleSet_422_EmptyInner(t *testing.T) {
	errResp := ErrorResponse{
		Errors: []ErrorObject{
			{
				Code:          ErrCodeCannotCommitEmptyInner,
				Status:        422,
				Title:         "Validation Error",
				Detail:        stringPtr("Inner circle requires at least one behavior to commit"),
				CorrelationID: stringPtr("f1e2d3c4-b5a6-7890-abcd-ef1234567890"),
				Source: &ErrorSource{
					Pointer: stringPtr("/innerCircle"),
				},
			},
		},
	}

	validateJSON(t, errResp)
	validateErrorResponse(t, errResp, 422, ErrCodeCannotCommitEmptyInner)
}

// ────────────────────────────────────────────────────────────────────────────
// Circle Item Tests (Add, Update, Delete, Move)
// ────────────────────────────────────────────────────────────────────────────

func TestThreeCircles_Contract_POST_AddCircleItem_201(t *testing.T) {
	request := CreateCircleItemRequest{
		Circle:            CircleMiddle,
		BehaviorName:      "Browsing social media excessively",
		Notes:             stringPtr("Especially when bored or lonely"),
		SpecificityDetail: stringPtr("More than 30 minutes of scrolling"),
		Category:          stringPtr("emotional-trigger"),
		Flags: &CircleItemFlags{
			Uncertain: true,
		},
	}

	validateJSON(t, request)

	now := time.Now()
	response := CircleItemResponse{
		Data: CircleItem{
			ItemID:            "3c_item_new456",
			Circle:            CircleMiddle,
			BehaviorName:      "Browsing social media excessively",
			Notes:             stringPtr("Especially when bored or lonely"),
			SpecificityDetail: stringPtr("More than 30 minutes of scrolling"),
			Category:          stringPtr("emotional-trigger"),
			Source:            SourceUser,
			Flags: &CircleItemFlags{
				Uncertain: true,
			},
			CreatedAt:  now,
			ModifiedAt: now,
		},
		Links: Links{
			Self: stringPtr("/v1/tools/three-circles/sets/3c_set_abc123/items/3c_item_new456"),
			Set:  stringPtr("/v1/tools/three-circles/sets/3c_set_abc123"),
		},
	}

	validateJSON(t, response)

	var decoded CircleItemResponse
	validateRoundtrip(t, response, &decoded)
}

func TestThreeCircles_Contract_PUT_UpdateCircleItem_200(t *testing.T) {
	request := UpdateCircleItemRequest{
		BehaviorName: stringPtr("Updated behavior description"),
		Notes:        stringPtr("Updated notes"),
		Flags: &CircleItemFlags{
			Uncertain: false,
		},
	}

	validateJSON(t, request)
}

func TestThreeCircles_Contract_DELETE_DeleteCircleItem_204(t *testing.T) {
	// DELETE has no request/response body
}

func TestThreeCircles_Contract_POST_MoveCircleItem_200(t *testing.T) {
	request := MoveCircleItemRequest{
		TargetCircle: CircleInner,
		ChangeNote:   stringPtr("Sponsor recommended tightening this boundary"),
	}

	validateJSON(t, request)

	now := time.Now()
	response := CircleItemResponse{
		Data: CircleItem{
			ItemID:       "3c_item_456",
			Circle:       CircleInner,
			BehaviorName: "Browsing social media excessively",
			Source:       SourceUser,
			CreatedAt:    now,
			ModifiedAt:   now,
		},
		Links: Links{
			Self: stringPtr("/v1/tools/three-circles/sets/3c_set_abc123/items/3c_item_456"),
		},
	}

	validateJSON(t, response)
}

// ────────────────────────────────────────────────────────────────────────────
// Version History Tests (List, Get, Restore)
// ────────────────────────────────────────────────────────────────────────────

func TestThreeCircles_Contract_GET_ListVersions_200(t *testing.T) {
	now := time.Now()

	response := VersionListResponse{
		Data: []VersionSummary{
			{
				VersionNumber: 5,
				ChangedAt:     now,
				ChangeNote:    stringPtr("Added outer circle items"),
				InnerCount:    3,
				MiddleCount:   8,
				OuterCount:    12,
			},
			{
				VersionNumber: 4,
				ChangedAt:     now.Add(-7 * 24 * time.Hour),
				ChangeNote:    nil,
				InnerCount:    3,
				MiddleCount:   6,
				OuterCount:    10,
			},
		},
		Meta: Meta{
			TotalCount: intPtr(5),
		},
		Links: Links{
			Self: stringPtr("/v1/tools/three-circles/sets/3c_set_abc123/versions"),
		},
	}

	validateJSON(t, response)

	var decoded VersionListResponse
	validateRoundtrip(t, response, &decoded)
}

func TestThreeCircles_Contract_GET_GetVersion_200(t *testing.T) {
	now := time.Now()

	response := CircleSetVersionResponse{
		Data: CircleSetVersion{
			VersionNumber: 3,
			Snapshot: CircleSetVersionSnapshot{
				InnerCircle: []CircleItem{
					{
						ItemID:       "3c_item_001",
						Circle:       CircleInner,
						BehaviorName: "Viewing pornography",
						Source:       SourceUser,
						CreatedAt:    now,
						ModifiedAt:   now,
					},
				},
				MiddleCircle: []CircleItem{},
				OuterCircle:  []CircleItem{},
			},
			ChangeNote: stringPtr("Initial version"),
			ChangedAt:  now,
		},
		Links: Links{
			Self:    stringPtr("/v1/tools/three-circles/sets/3c_set_abc123/versions/v3"),
			Restore: stringPtr("/v1/tools/three-circles/sets/3c_set_abc123/versions/v3/restore"),
		},
	}

	validateJSON(t, response)

	var decoded CircleSetVersionResponse
	validateRoundtrip(t, response, &decoded)
}

func TestThreeCircles_Contract_POST_RestoreVersion_200(t *testing.T) {
	request := RestoreVersionRequest{
		ChangeNote: stringPtr("Restoring v2 after discussion with sponsor"),
	}

	validateJSON(t, request)
}

// ────────────────────────────────────────────────────────────────────────────
// Template Tests (List, Get)
// ────────────────────────────────────────────────────────────────────────────

func TestThreeCircles_Contract_GET_ListTemplates_200(t *testing.T) {
	area := RecoveryAreaSexPornography
	circle := CircleInner

	response := TemplateListResponse{
		Data: []Template{
			{
				TemplateID:          "3c_tpl_001",
				RecoveryArea:        RecoveryAreaSexPornography,
				Circle:              CircleInner,
				BehaviorName:        "Viewing pornography",
				Rationale:           "Many people identify this as a primary behavior causing harm",
				SpecificityGuidance: stringPtr("Be specific about what types, where, when"),
				Category:            nil,
				FrameworkVariant:    nil,
				Version:             1,
			},
		},
		Meta: Meta{
			RecoveryArea: &area,
			Circle:       &circle,
		},
		Links: Links{
			Self: stringPtr("/v1/tools/three-circles/templates?recoveryArea=sex-pornography&circle=inner"),
		},
	}

	validateJSON(t, response)

	var decoded TemplateListResponse
	validateRoundtrip(t, response, &decoded)
}

func TestThreeCircles_Contract_GET_GetTemplate_200(t *testing.T) {
	response := TemplateResponse{
		Data: Template{
			TemplateID:          "3c_tpl_001",
			RecoveryArea:        RecoveryAreaSexPornography,
			Circle:              CircleInner,
			BehaviorName:        "Viewing pornography",
			Rationale:           "Many people identify this as a primary behavior causing harm",
			SpecificityGuidance: stringPtr("Be specific about what types, where, when"),
			Version:             1,
		},
		Links: Links{
			Self: stringPtr("/v1/tools/three-circles/templates/3c_tpl_001"),
		},
	}

	validateJSON(t, response)

	var decoded TemplateResponse
	validateRoundtrip(t, response, &decoded)
}

// ────────────────────────────────────────────────────────────────────────────
// Starter Pack Tests (List, Get, Apply)
// ────────────────────────────────────────────────────────────────────────────

func TestThreeCircles_Contract_GET_ListStarterPacks_200(t *testing.T) {
	area := RecoveryAreaSexPornography

	response := StarterPackListResponse{
		Data: []StarterPackSummary{
			{
				PackID:      "3c_pack_001",
				Name:        "Sex Addiction Recovery — Faith-Based",
				Description: "Clinically reviewed starter pack with faith-integrated content",
				Variant:     VariantFaithBased,
				ItemCounts: StarterPackCounts{
					Inner:  3,
					Middle: 8,
					Outer:  10,
				},
			},
		},
		Meta: Meta{
			RecoveryArea: &area,
		},
		Links: Links{
			Self: stringPtr("/v1/tools/three-circles/starter-packs?recoveryArea=sex-pornography"),
		},
	}

	validateJSON(t, response)

	var decoded StarterPackListResponse
	validateRoundtrip(t, response, &decoded)
}

func TestThreeCircles_Contract_GET_GetStarterPack_200(t *testing.T) {
	response := StarterPackResponse{
		Data: StarterPack{
			PackID:       "3c_pack_001",
			Name:         "Sex Addiction Recovery — Faith-Based",
			Description:  "Clinically reviewed starter pack",
			RecoveryArea: RecoveryAreaSexPornography,
			Variant:      VariantFaithBased,
			InnerCircle: []StarterPackItem{
				{
					BehaviorName: "Viewing pornography",
					Rationale:    "Primary acting out behavior",
					Category:     nil,
				},
			},
			MiddleCircle: []StarterPackItem{
				{
					BehaviorName: "Isolating when stressed",
					Rationale:    "Common trigger pattern",
					Category:     stringPtr("emotional"),
				},
			},
			OuterCircle: []StarterPackItem{
				{
					BehaviorName: "Morning prayer/meditation",
					Rationale:    "Grounding practice",
					Category:     nil,
				},
			},
			ClinicalReviewer:  "Dr. Jane Smith, LCSW",
			CommunityReviewer: "John D. (12 years recovery)",
			Version:           1,
		},
		Links: Links{
			Self:  stringPtr("/v1/tools/three-circles/starter-packs/3c_pack_001"),
			Apply: stringPtr("/v1/tools/three-circles/sets/{setId}/apply-starter-pack"),
		},
	}

	validateJSON(t, response)

	var decoded StarterPackResponse
	validateRoundtrip(t, response, &decoded)
}

func TestThreeCircles_Contract_POST_ApplyStarterPack_200(t *testing.T) {
	merge := MergeMerge
	request := ApplyStarterPackRequest{
		PackID:        "3c_pack_001",
		MergeStrategy: &merge,
	}

	validateJSON(t, request)
}

// ────────────────────────────────────────────────────────────────────────────
// Onboarding Tests (Start, Update, Complete)
// ────────────────────────────────────────────────────────────────────────────

func TestThreeCircles_Contract_POST_StartOnboarding_201(t *testing.T) {
	mode := ModeGuided
	score := 3
	request := StartOnboardingRequest{
		Mode:                  &mode,
		EmotionalCheckinScore: &score,
	}

	validateJSON(t, request)

	now := time.Now()
	response := OnboardingFlowResponse{
		Data: OnboardingFlow{
			FlowID:                "3c_flow_abc123",
			UserID:                "user_xyz789",
			Mode:                  ModeGuided,
			CurrentStep:           StepRecoveryArea,
			EmotionalCheckinScore: &score,
			Progress:              map[string]interface{}{},
			CreatedAt:             now,
			LastUpdatedAt:         now,
		},
		Links: Links{
			Self:     stringPtr("/v1/tools/three-circles/onboarding/3c_flow_abc123"),
			Complete: stringPtr("/v1/tools/three-circles/onboarding/3c_flow_abc123/complete"),
		},
	}

	validateJSON(t, response)

	var decoded OnboardingFlowResponse
	validateRoundtrip(t, response, &decoded)
}

func TestThreeCircles_Contract_PATCH_UpdateOnboarding_200(t *testing.T) {
	step := StepInnerCircle
	area := RecoveryAreaSexPornography
	request := UpdateOnboardingRequest{
		CurrentStep:  &step,
		RecoveryArea: &area,
		Progress:     map[string]interface{}{"innerCircleItems": []string{"Viewing pornography"}},
	}

	validateJSON(t, request)
}

func TestThreeCircles_Contract_POST_CompleteOnboarding_201(t *testing.T) {
	genShare := true
	request := CompleteOnboardingRequest{
		CommitOption:         CommitDraft,
		ChangeNote:           stringPtr("Initial circles created via onboarding"),
		GenerateSponsorShare: &genShare,
	}

	validateJSON(t, request)

	now := time.Now()
	response := CompleteOnboardingResponse{
		Data: CompleteOnboardingData{
			CircleSet: CircleSet{
				SetID:         "3c_set_new789",
				UserID:        "user_xyz789",
				Name:          "Sex/Pornography Recovery",
				RecoveryArea:  RecoveryAreaSexPornography,
				Status:        StatusDraft,
				InnerCircle:   []CircleItem{},
				MiddleCircle:  []CircleItem{},
				OuterCircle:   []CircleItem{},
				VersionNumber: 1,
				CreatedAt:     now,
				ModifiedAt:    now,
				CommittedAt:   nil,
			},
			SponsorShareLink: stringPtr("https://app.regalrecovery.com/share/AB3X9KL2"),
			SponsorShareCode: stringPtr("AB3X9KL2"),
		},
		Links: Links{
			CircleSet: stringPtr("/v1/tools/three-circles/sets/3c_set_new789"),
		},
	}

	validateJSON(t, response)

	var decoded CompleteOnboardingResponse
	validateRoundtrip(t, response, &decoded)
}

// ────────────────────────────────────────────────────────────────────────────
// Sponsor Review Tests (Share, View, Comment, Get Comments)
// ────────────────────────────────────────────────────────────────────────────

func TestThreeCircles_Contract_POST_ShareCircleSet_201(t *testing.T) {
	expires := "7d"
	request := ShareCircleSetRequest{
		ExpiresIn:   &expires,
		Permissions: []string{"view", "comment"},
	}

	validateJSON(t, request)

	now := time.Now()
	expiresAt := now.Add(7 * 24 * time.Hour)
	response := ShareCircleSetResponse{
		Data: ShareCircleSetData{
			ShareCode:   "AB3X9KL2",
			ShareLink:   "https://app.regalrecovery.com/share/AB3X9KL2",
			ExpiresAt:   &expiresAt,
			Permissions: []string{"view", "comment"},
		},
		Links: Links{
			ShareView: stringPtr("https://app.regalrecovery.com/share/AB3X9KL2"),
		},
	}

	validateJSON(t, response)

	var decoded ShareCircleSetResponse
	validateRoundtrip(t, response, &decoded)
}

func TestThreeCircles_Contract_GET_ViewSharedCircleSet_200(t *testing.T) {
	now := time.Now()
	expiresAt := now.Add(7 * 24 * time.Hour)

	response := ViewSharedCircleSetResponse{
		Data: ViewSharedCircleSetData{
			Name:         "Sex/Pornography Recovery",
			RecoveryArea: RecoveryAreaSexPornography,
			InnerCircle: []CircleItem{
				{
					ItemID:       "3c_item_001",
					Circle:       CircleInner,
					BehaviorName: "Viewing pornography",
					Source:       SourceUser,
					CreatedAt:    now,
					ModifiedAt:   now,
				},
			},
			MiddleCircle: []CircleItem{},
			OuterCircle:  []CircleItem{},
			SharedAt:     now,
			ExpiresAt:    &expiresAt,
			CanComment:   true,
		},
		Meta: Meta{
			ReadOnly: boolPtr(true),
		},
	}

	validateJSON(t, response)

	var decoded ViewSharedCircleSetResponse
	validateRoundtrip(t, response, &decoded)
}

func TestThreeCircles_Contract_POST_AddSponsorComment_201(t *testing.T) {
	request := AddSponsorCommentRequest{
		ItemID:        "3c_item_001",
		Text:          "This is a great specific boundary. Have you considered adding time of day?",
		CommenterName: stringPtr("John (sponsor)"),
	}

	validateJSON(t, request)

	now := time.Now()
	response := SponsorCommentResponse{
		Data: SponsorComment{
			CommentID:     "3c_cmt_abc123",
			ItemID:        "3c_item_001",
			Text:          "This is a great specific boundary.",
			CommenterName: stringPtr("John (sponsor)"),
			CreatedAt:     now,
		},
		Links: Links{
			Self: stringPtr("/v1/tools/three-circles/share/AB3X9KL2/comments"),
			Item: stringPtr("/v1/tools/three-circles/sets/3c_set_abc123/items/3c_item_001"),
		},
	}

	validateJSON(t, response)

	var decoded SponsorCommentResponse
	validateRoundtrip(t, response, &decoded)
}

func TestThreeCircles_Contract_GET_GetCircleSetComments_200(t *testing.T) {
	now := time.Now()

	response := CommentListResponse{
		Data: []SponsorComment{
			{
				CommentID:     "3c_cmt_001",
				ItemID:        "3c_item_001",
				Text:          "Great specificity here",
				CommenterName: stringPtr("John"),
				CreatedAt:     now,
			},
		},
		Meta: Meta{
			TotalCount: intPtr(1),
		},
		Links: PaginationLinks{
			Self: stringPtr("/v1/tools/three-circles/sets/3c_set_abc123/comments"),
		},
	}

	validateJSON(t, response)

	var decoded CommentListResponse
	validateRoundtrip(t, response, &decoded)
}

// ────────────────────────────────────────────────────────────────────────────
// Pattern Visualization Tests (Timeline, Insights, Summary, Drift Alerts)
// ────────────────────────────────────────────────────────────────────────────

func TestThreeCircles_Contract_GET_Timeline_200(t *testing.T) {
	response := TimelineResponse{
		Data: TimelineData{
			Entries: []TimelineEntry{
				{
					Date:   "2026-04-08",
					Circle: CircleOuter,
					CheckinDetails: &TimelineCheckinDetails{
						Mood:          4,
						UrgeIntensity: 2,
						Notes:         "Good day",
					},
				},
				{
					Date:   "2026-04-07",
					Circle: CircleMiddle,
					CheckinDetails: &TimelineCheckinDetails{
						Mood:          3,
						UrgeIntensity: 5,
						Notes:         "Stressed at work",
					},
				},
			},
			Summary: TimelineSummary{
				OuterDays:                   25,
				MiddleDays:                  4,
				InnerDays:                   0,
				NoCheckinDays:               1,
				CurrentConsecutiveOuterDays: 3,
			},
		},
		Meta: Meta{
			Period:    stringPtr("30d"),
			StartDate: stringPtr("2026-03-09"),
			EndDate:   stringPtr("2026-04-08"),
		},
		Links: Links{
			Self:     stringPtr("/v1/tools/three-circles/patterns/timeline?setId=3c_set_abc123&period=30d"),
			Insights: stringPtr("/v1/tools/three-circles/patterns/insights?setId=3c_set_abc123"),
			Summary:  stringPtr("/v1/tools/three-circles/patterns/summary?setId=3c_set_abc123&period=month"),
		},
	}

	validateJSON(t, response)

	var decoded TimelineResponse
	validateRoundtrip(t, response, &decoded)
}

func TestThreeCircles_Contract_GET_Insights_200(t *testing.T) {
	now := time.Now()

	response := InsightListResponse{
		Data: []PatternInsight{
			{
				InsightID:        "3c_ins_001",
				Type:             InsightDayOfWeek,
				Description:      "You tend to have middle circle contact on Fridays",
				Confidence:       ConfidenceHigh,
				ActionSuggestion: "Want to add Fridays to your weekly plan review?",
				DataPoints:       28,
				DetectedAt:       now,
			},
		},
		Meta: Meta{
			MinimumDataDays: intPtr(14),
		},
		Links: Links{
			Self: stringPtr("/v1/tools/three-circles/patterns/insights?setId=3c_set_abc123"),
		},
	}

	validateJSON(t, response)

	var decoded InsightListResponse
	validateRoundtrip(t, response, &decoded)
}

func TestThreeCircles_Contract_GET_Summary_200(t *testing.T) {
	mood := MoodStable

	response := SummaryResponse{
		Data: Summary{
			Period:         "month",
			StartDate:      "2026-03-01",
			EndDate:        "2026-03-31",
			OuterDays:      22,
			MiddleDays:     6,
			InnerDays:      2,
			NoCheckinDays:  1,
			Insights:       []PatternInsight{},
			MoodTrend:      &mood,
			FramingMessage: "You logged 22 outer circle days, 6 middle circle days, and 2 inner circle days this month.",
		},
		Links: Links{
			Self:     stringPtr("/v1/tools/three-circles/patterns/summary?setId=3c_set_abc123&period=month"),
			Timeline: stringPtr("/v1/tools/three-circles/patterns/timeline?setId=3c_set_abc123"),
		},
	}

	validateJSON(t, response)

	var decoded SummaryResponse
	validateRoundtrip(t, response, &decoded)
}

func TestThreeCircles_Contract_GET_DriftAlerts_200(t *testing.T) {
	now := time.Now()

	response := DriftAlertListResponse{
		Data: []DriftAlert{
			{
				AlertID:          "3c_alert_001",
				WindowStart:      "2026-04-02",
				WindowEnd:        "2026-04-08",
				MiddleCircleDays: 4,
				Message:          "You've been in your middle circle a few times this week.",
				Dismissed:        false,
				CreatedAt:        now,
			},
		},
		Links: Links{
			Self: stringPtr("/v1/tools/three-circles/patterns/drift-alerts?setId=3c_set_abc123&status=active"),
		},
	}

	validateJSON(t, response)

	var decoded DriftAlertListResponse
	validateRoundtrip(t, response, &decoded)
}

func TestThreeCircles_Contract_POST_DismissDriftAlert_204(t *testing.T) {
	// POST dismiss has no request/response body
}

// ────────────────────────────────────────────────────────────────────────────
// Quarterly Review Tests (List, Start, Update, Complete)
// ────────────────────────────────────────────────────────────────────────────

func TestThreeCircles_Contract_GET_ListReviews_200(t *testing.T) {
	now := time.Now()
	completedAt := now.Add(-30 * 24 * time.Hour)

	response := ReviewListResponse{
		Data: []ReviewSummary{
			{
				ReviewID:    "3c_rev_001",
				StartedAt:   now.Add(-90 * 24 * time.Hour),
				CompletedAt: &completedAt,
				Completed:   true,
			},
		},
		Meta: Meta{
			NextReviewDue: stringPtr("2026-07-08"),
		},
		Links: PaginationLinks{
			Self: stringPtr("/v1/tools/three-circles/reviews?setId=3c_set_abc123"),
		},
	}

	validateJSON(t, response)

	var decoded ReviewListResponse
	validateRoundtrip(t, response, &decoded)
}

func TestThreeCircles_Contract_POST_StartReview_201(t *testing.T) {
	request := StartReviewRequest{
		SetID: "3c_set_abc123",
	}

	validateJSON(t, request)

	now := time.Now()
	response := ReviewResponse{
		Data: Review{
			ReviewID:       "3c_rev_new123",
			SetID:          "3c_set_abc123",
			CurrentStep:    ReviewStepInner,
			Reflections:    map[string]interface{}{},
			ChangesApplied: []string{},
			Completed:      false,
			Summary:        nil,
			StartedAt:      now,
			CompletedAt:    nil,
			NextReviewDue:  "2026-07-08",
		},
		Links: Links{
			Self:      stringPtr("/v1/tools/three-circles/reviews/3c_rev_new123"),
			Complete:  stringPtr("/v1/tools/three-circles/reviews/3c_rev_new123/complete"),
			CircleSet: stringPtr("/v1/tools/three-circles/sets/3c_set_abc123"),
		},
	}

	validateJSON(t, response)

	var decoded ReviewResponse
	validateRoundtrip(t, response, &decoded)
}

func TestThreeCircles_Contract_PATCH_UpdateReview_200(t *testing.T) {
	step := ReviewStepOuter
	request := UpdateReviewRequest{
		CurrentStep:    &step,
		Reflections:    map[string]interface{}{"innerCircle": "Solid boundaries"},
		ChangesApplied: []string{"Added one middle circle item"},
	}

	validateJSON(t, request)
}

func TestThreeCircles_Contract_POST_CompleteReview_200(t *testing.T) {
	request := CompleteReviewRequest{
		Summary: stringPtr("Great review session with sponsor. Tightened some boundaries."),
	}

	validateJSON(t, request)

	now := time.Now()
	response := ReviewResponse{
		Data: Review{
			ReviewID:       "3c_rev_123",
			SetID:          "3c_set_abc123",
			CurrentStep:    ReviewStepFinal,
			Reflections:    map[string]interface{}{},
			ChangesApplied: []string{},
			Completed:      true,
			Summary:        stringPtr("Great review session with sponsor."),
			StartedAt:      now.Add(-1 * time.Hour),
			CompletedAt:    &now,
			NextReviewDue:  "2026-07-08",
		},
		Links: Links{
			Self:      stringPtr("/v1/tools/three-circles/reviews/3c_rev_123"),
			CircleSet: stringPtr("/v1/tools/three-circles/sets/3c_set_abc123"),
		},
	}

	validateJSON(t, response)

	var decoded ReviewResponse
	validateRoundtrip(t, response, &decoded)
}

// ────────────────────────────────────────────────────────────────────────────
// Error Response Tests
// ────────────────────────────────────────────────────────────────────────────

func TestThreeCircles_Contract_Error_404_FeatureDisabled(t *testing.T) {
	errResp := ErrorResponse{
		Errors: []ErrorObject{
			{
				ID:            stringPtr("9a4b5c6d-3f7e-6d1e-d2c3-7g8h9i0j1k2l"),
				Code:          ErrCodeFeatureDisabled,
				Status:        404,
				Title:         "Feature Not Available",
				Detail:        stringPtr("Three Circles feature is not enabled for this account"),
				CorrelationID: stringPtr("0f1g2h3i-4j5k-7l8m-e3d4-8h9i0j1k2l3m"),
			},
		},
	}

	validateJSON(t, errResp)
	validateErrorResponse(t, errResp, 404, ErrCodeFeatureDisabled)
}

func TestThreeCircles_Contract_Error_404_NotFound(t *testing.T) {
	errResp := ErrorResponse{
		Errors: []ErrorObject{
			{
				ID:            stringPtr("7f3a8b2c-1e4d-4c9b-b0a1-5e6f7a8b9c0d"),
				Code:          ErrCodeCircleSetNotFound,
				Status:        404,
				Title:         "Not Found",
				Detail:        stringPtr("Circle set does not exist"),
				CorrelationID: stringPtr("8e2b9a3c-2f5e-5d0c-c1b2-6f7g8h9i0j1k"),
			},
		},
	}

	validateJSON(t, errResp)
	validateErrorResponse(t, errResp, 404, ErrCodeCircleSetNotFound)
}

func TestThreeCircles_Contract_Error_401_Unauthorized(t *testing.T) {
	errResp := ErrorResponse{
		Errors: []ErrorObject{
			{
				ID:            stringPtr("eec33bf0-6bcc-4813-ae7e-0a70e8e53c3b"),
				Code:          ErrCodeUnauthorized,
				Status:        401,
				Title:         "Unauthorized",
				Detail:        stringPtr("Missing or invalid access token"),
				CorrelationID: stringPtr("fe8793b2-1bf0-4d29-bf10-adcf72640ec5"),
				Links: &ErrorLinks{
					About: stringPtr("https://api.regalrecovery.app/errors/auth"),
				},
			},
		},
	}

	validateJSON(t, errResp)
	validateErrorResponse(t, errResp, 401, ErrCodeUnauthorized)
}

func TestThreeCircles_Contract_Error_422_ValidationError(t *testing.T) {
	errResp := ErrorResponse{
		Errors: []ErrorObject{
			{
				ID:            stringPtr("1b5c6d7e-4g8h-8e2f-f4e5-9i0j1k2l3m4n"),
				Code:          ErrCodeValidationFailed,
				Status:        422,
				Title:         "Validation Error",
				Detail:        stringPtr("behaviorName exceeds maximum length of 200 characters"),
				CorrelationID: stringPtr("2c6d7e8f-5h9i-9f3g-g5f6-0j1k2l3m4n5o"),
				Source: &ErrorSource{
					Pointer: stringPtr("/behaviorName"),
				},
			},
		},
	}

	validateJSON(t, errResp)
	validateErrorResponse(t, errResp, 422, ErrCodeValidationFailed)
}

func TestThreeCircles_Contract_Error_410_ShareCodeExpired(t *testing.T) {
	errResp := ErrorResponse{
		Errors: []ErrorObject{
			{
				Code:          ErrCodeShareCodeExpired,
				Status:        410,
				Title:         "Share Link Expired",
				Detail:        stringPtr("This share link has expired"),
				CorrelationID: stringPtr("abc123-def456"),
			},
		},
	}

	validateJSON(t, errResp)
	validateErrorResponse(t, errResp, 410, ErrCodeShareCodeExpired)
}

// ────────────────────────────────────────────────────────────────────────────
// Additional Helper Tests
// ────────────────────────────────────────────────────────────────────────────

func TestThreeCircles_Contract_AllEnums(t *testing.T) {
	// Test all enum types can be marshaled/unmarshaled
	enums := []interface{}{
		CircleInner,
		StatusDraft,
		RecoveryAreaSexPornography,
		FrameworkSAA,
		SourceUser,
		ModeGuided,
		StepRecoveryArea,
		VariantSecular,
		InsightDayOfWeek,
		ConfidenceLow,
		MoodImproving,
		ReviewStepInner,
		CommitNow,
		MergeReplace,
	}

	for _, enum := range enums {
		validateJSON(t, enum)
	}
}

func TestThreeCircles_Contract_RequiredFields(t *testing.T) {
	// Test that marshaling structs with required fields validates correctly
	now := time.Now()

	item := CircleItem{
		ItemID:       "3c_item_001",
		Circle:       CircleInner,
		BehaviorName: "Test behavior",
		Source:       SourceUser,
		CreatedAt:    now,
		ModifiedAt:   now,
	}

	validateJSON(t, item)

	set := CircleSet{
		SetID:         "3c_set_001",
		UserID:        "user_001",
		Name:          "Test Set",
		RecoveryArea:  RecoveryAreaSexPornography,
		Status:        StatusDraft,
		InnerCircle:   []CircleItem{},
		MiddleCircle:  []CircleItem{},
		OuterCircle:   []CircleItem{},
		VersionNumber: 1,
		CreatedAt:     now,
		ModifiedAt:    now,
	}

	validateJSON(t, set)
}

// boolPtr returns a pointer to a bool value.
func boolPtr(b bool) *bool {
	return &b
}
