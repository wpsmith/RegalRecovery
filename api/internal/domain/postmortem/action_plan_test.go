// internal/domain/postmortem/action_plan_test.go
package postmortem

import (
	"testing"
)

// TestPostMortem_PM_AC6_3_ConvertToCommitment verifies action item conversion.
// Acceptance Criterion (PM-AC6.3): Convert to commitment with sourcePostMortemId.
func TestPostMortem_PM_AC6_3_ConvertToCommitment(t *testing.T) {
	item := &ActionPlanItem{
		ActionID:      "ap_001",
		TimelinePoint: "15:00",
		Action:        "Call sponsor when I first notice isolation",
		Category:      ActionCategoryRelational,
	}

	MarkActionConverted(item, "commitment", "cm_88888")

	if item.ConvertedToCommitmentID == nil || *item.ConvertedToCommitmentID != "cm_88888" {
		t.Error("expected convertedToCommitmentId to be set to 'cm_88888'")
	}
	if item.ConvertedToGoalID != nil {
		t.Error("expected convertedToGoalId to remain nil")
	}
}

// TestPostMortem_PM_AC6_3_ConvertToGoal verifies action item conversion to goal.
func TestPostMortem_PM_AC6_3_ConvertToGoal(t *testing.T) {
	item := &ActionPlanItem{
		ActionID: "ap_002",
		Action:   "Phone charges outside bedroom by 9pm",
		Category: ActionCategoryPractical,
	}

	MarkActionConverted(item, "goal", "goal_55555")

	if item.ConvertedToGoalID == nil || *item.ConvertedToGoalID != "goal_55555" {
		t.Error("expected convertedToGoalId to be set to 'goal_55555'")
	}
	if item.ConvertedToCommitmentID != nil {
		t.Error("expected convertedToCommitmentId to remain nil")
	}
}

// TestPostMortem_AssignActionIDs verifies action IDs are generated for items without IDs.
func TestPostMortem_AssignActionIDs(t *testing.T) {
	items := []ActionPlanItem{
		{Action: "First action", Category: ActionCategorySpiritual},
		{ActionID: "ap_existing", Action: "Second action", Category: ActionCategoryRelational},
		{Action: "Third action", Category: ActionCategoryPhysical},
	}

	result := AssignActionIDs(items)

	if result[0].ActionID == "" {
		t.Error("expected first item to get an assigned ID")
	}
	if result[1].ActionID != "ap_existing" {
		t.Errorf("expected second item to keep 'ap_existing', got '%s'", result[1].ActionID)
	}
	if result[2].ActionID == "" {
		t.Error("expected third item to get an assigned ID")
	}
	// IDs should have ap_ prefix.
	if result[0].ActionID[:3] != "ap_" {
		t.Errorf("expected ID to start with 'ap_', got '%s'", result[0].ActionID)
	}
}

// TestPostMortem_FindActionItem verifies finding an action item by ID.
func TestPostMortem_FindActionItem(t *testing.T) {
	analysis := &PostMortemAnalysis{
		ActionPlan: []ActionPlanItem{
			{ActionID: "ap_001", Action: "First"},
			{ActionID: "ap_002", Action: "Second"},
			{ActionID: "ap_003", Action: "Third"},
		},
	}

	item, idx, err := FindActionItem(analysis, "ap_002")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if idx != 1 {
		t.Errorf("expected index 1, got %d", idx)
	}
	if item.Action != "Second" {
		t.Errorf("expected 'Second', got '%s'", item.Action)
	}
}

// TestPostMortem_FindActionItem_NotFound verifies error for missing action item.
func TestPostMortem_FindActionItem_NotFound(t *testing.T) {
	analysis := &PostMortemAnalysis{
		ActionPlan: []ActionPlanItem{
			{ActionID: "ap_001", Action: "First"},
		},
	}

	_, _, err := FindActionItem(analysis, "ap_999")
	if err == nil {
		t.Error("expected error for missing action item")
	}
}

// TestPostMortem_ValidateConvertRequest verifies convert request validation.
func TestPostMortem_ValidateConvertRequest(t *testing.T) {
	tests := []struct {
		name    string
		req     ConvertActionItemRequest
		wantErr bool
	}{
		{"valid commitment", ConvertActionItemRequest{TargetType: "commitment", Title: "Call sponsor"}, false},
		{"valid goal", ConvertActionItemRequest{TargetType: "goal", Title: "Exercise daily"}, false},
		{"invalid type", ConvertActionItemRequest{TargetType: "task", Title: "Test"}, true},
		{"empty title", ConvertActionItemRequest{TargetType: "commitment", Title: ""}, true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateConvertRequest(tt.req)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidateConvertRequest() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
