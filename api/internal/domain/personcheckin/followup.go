// internal/domain/personcheckin/followup.go
package personcheckin

// ValidateFollowUpIndex checks if the follow-up index is valid for the given check-in.
func ValidateFollowUpIndex(checkIn *PersonCheckIn, index int) error {
	if index < 0 || index >= len(checkIn.FollowUpItems) {
		return ErrFollowUpIndexOutOfRange
	}
	return nil
}

// IsFollowUpAlreadyConverted checks if a follow-up item has already been converted to a goal.
func IsFollowUpAlreadyConverted(checkIn *PersonCheckIn, index int) bool {
	if index < 0 || index >= len(checkIn.FollowUpItems) {
		return false
	}
	return checkIn.FollowUpItems[index].GoalID != nil
}

// LinkGoalToFollowUp updates a follow-up item with the created goal's ID.
func LinkGoalToFollowUp(checkIn *PersonCheckIn, index int, goalID string) {
	if index >= 0 && index < len(checkIn.FollowUpItems) {
		checkIn.FollowUpItems[index].GoalID = &goalID
	}
}

// FollowUpItemsFromStrings converts string follow-up items to FollowUpItem structs.
func FollowUpItemsFromStrings(items []string) []FollowUpItem {
	result := make([]FollowUpItem, len(items))
	for i, text := range items {
		result[i] = FollowUpItem{
			Text:   text,
			GoalID: nil,
		}
	}
	return result
}
