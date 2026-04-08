// internal/domain/postmortem/action_plan.go
package postmortem

import (
	"fmt"

	"github.com/google/uuid"
)

// GenerateActionID creates a new unique action item ID.
func GenerateActionID() string {
	return "ap_" + uuid.New().String()[:8]
}

// AssignActionIDs ensures all action items have IDs.
// Items without IDs get new ones generated; items with IDs keep them.
func AssignActionIDs(items []ActionPlanItem) []ActionPlanItem {
	for i := range items {
		if items[i].ActionID == "" {
			items[i].ActionID = GenerateActionID()
		}
	}
	return items
}

// FindActionItem finds an action item by ID within a post-mortem.
func FindActionItem(analysis *PostMortemAnalysis, actionID string) (*ActionPlanItem, int, error) {
	for i, item := range analysis.ActionPlan {
		if item.ActionID == actionID {
			return &analysis.ActionPlan[i], i, nil
		}
	}
	return nil, -1, fmt.Errorf("action item %s not found", actionID)
}

// MarkActionConverted updates an action item with its conversion reference.
func MarkActionConverted(item *ActionPlanItem, targetType, createdEntityID string) {
	switch targetType {
	case "commitment":
		item.ConvertedToCommitmentID = &createdEntityID
	case "goal":
		item.ConvertedToGoalID = &createdEntityID
	}
}

// ValidateConvertRequest validates a convert action item request.
func ValidateConvertRequest(req ConvertActionItemRequest) error {
	if req.TargetType != "commitment" && req.TargetType != "goal" {
		return fmt.Errorf("targetType must be 'commitment' or 'goal', got '%s'", req.TargetType)
	}
	if req.Title == "" {
		return fmt.Errorf("title is required")
	}
	if len(req.Title) > 200 {
		return fmt.Errorf("title must be 200 characters or less")
	}
	return nil
}
