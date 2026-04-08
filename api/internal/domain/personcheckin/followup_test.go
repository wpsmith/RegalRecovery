// internal/domain/personcheckin/followup_test.go
package personcheckin

import "testing"

func TestPersonCheckInFollowUp_FR_PCI_7_1_FollowUpItemsStoredWithCheckIn(t *testing.T) {
	items := FollowUpItemsFromStrings([]string{
		"Schedule date night",
		"Follow up on apology",
	})

	if len(items) != 2 {
		t.Fatalf("expected 2 items, got %d", len(items))
	}
	if items[0].Text != "Schedule date night" {
		t.Fatalf("expected 'Schedule date night', got '%s'", items[0].Text)
	}
	if items[0].GoalID != nil {
		t.Fatal("expected nil goalId for new follow-up item")
	}
}

func TestPersonCheckInFollowUp_FR_PCI_7_2_ConvertToGoal_CreatesGoalEntity(t *testing.T) {
	checkIn := &PersonCheckIn{
		CheckInID: "pci_test",
		FollowUpItems: []FollowUpItem{
			{Text: "Write resentment list", GoalID: nil},
		},
	}

	err := ValidateFollowUpIndex(checkIn, 0)
	if err != nil {
		t.Fatalf("expected valid index, got: %v", err)
	}

	if IsFollowUpAlreadyConverted(checkIn, 0) {
		t.Fatal("expected not already converted")
	}
}

func TestPersonCheckInFollowUp_FR_PCI_7_2_ConvertToGoal_LinksGoalIdBack(t *testing.T) {
	checkIn := &PersonCheckIn{
		CheckInID: "pci_test",
		FollowUpItems: []FollowUpItem{
			{Text: "Write resentment list", GoalID: nil},
		},
	}

	LinkGoalToFollowUp(checkIn, 0, "goal_12345")

	if checkIn.FollowUpItems[0].GoalID == nil {
		t.Fatal("expected goalId to be linked")
	}
	if *checkIn.FollowUpItems[0].GoalID != "goal_12345" {
		t.Fatalf("expected goal_12345, got %s", *checkIn.FollowUpItems[0].GoalID)
	}
}

func TestPersonCheckInFollowUp_ConvertToGoal_InvalidIndex_Returns404(t *testing.T) {
	checkIn := &PersonCheckIn{
		CheckInID: "pci_test",
		FollowUpItems: []FollowUpItem{
			{Text: "Item 1"},
		},
	}

	err := ValidateFollowUpIndex(checkIn, 5)
	if err != ErrFollowUpIndexOutOfRange {
		t.Fatalf("expected ErrFollowUpIndexOutOfRange, got: %v", err)
	}

	err = ValidateFollowUpIndex(checkIn, -1)
	if err != ErrFollowUpIndexOutOfRange {
		t.Fatalf("expected ErrFollowUpIndexOutOfRange for negative index, got: %v", err)
	}
}

func TestPersonCheckInFollowUp_ConvertToGoal_AlreadyConverted_Returns409(t *testing.T) {
	goalID := "goal_existing"
	checkIn := &PersonCheckIn{
		CheckInID: "pci_test",
		FollowUpItems: []FollowUpItem{
			{Text: "Already converted", GoalID: &goalID},
		},
	}

	if !IsFollowUpAlreadyConverted(checkIn, 0) {
		t.Fatal("expected already converted to return true")
	}
}
