// internal/domain/personcheckin/quick_log_test.go
package personcheckin

import (
	"testing"
	"time"
)

func TestPersonCheckIn_FR_PCI_2_1_QuickLogCreatesWithMinimalFields(t *testing.T) {
	settings := DefaultSettings("u_test", "DEFAULT")

	req := &QuickLogPersonCheckInRequest{
		CheckInType: CheckInTypeSponsor,
	}

	checkIn := BuildQuickLogCheckIn(req, settings, "pci_test", "u_test", "DEFAULT")

	if checkIn.CheckInType != CheckInTypeSponsor {
		t.Fatalf("expected sponsor, got %s", checkIn.CheckInType)
	}
	if checkIn.QualityRating != nil {
		t.Fatal("expected nil quality rating for quick log")
	}
	if checkIn.Notes != nil {
		t.Fatal("expected nil notes for quick log")
	}
	if len(checkIn.TopicsDiscussed) != 0 {
		t.Fatal("expected empty topics for quick log")
	}
}

func TestPersonCheckIn_FR_PCI_2_1_QuickLogDefaultsMethodToLastUsed(t *testing.T) {
	settings := DefaultSettings("u_test", "DEFAULT")
	phoneCall := MethodPhoneCall
	settings.Sponsor.LastUsedMethod = &phoneCall

	req := &QuickLogPersonCheckInRequest{
		CheckInType: CheckInTypeSponsor,
	}

	checkIn := BuildQuickLogCheckIn(req, settings, "pci_test", "u_test", "DEFAULT")

	if checkIn.Method != MethodPhoneCall {
		t.Fatalf("expected phone-call (last used), got %s", checkIn.Method)
	}
}

func TestPersonCheckIn_FR_PCI_2_1_QuickLogDefaultsMethodToInPersonWhenNoHistory(t *testing.T) {
	settings := DefaultSettings("u_test", "DEFAULT")

	req := &QuickLogPersonCheckInRequest{
		CheckInType: CheckInTypeSponsor,
	}

	checkIn := BuildQuickLogCheckIn(req, settings, "pci_test", "u_test", "DEFAULT")

	if checkIn.Method != MethodInPerson {
		t.Fatalf("expected in-person (default), got %s", checkIn.Method)
	}
}

func TestPersonCheckIn_FR_PCI_2_2_QuickLogEntryExpandableViaPatch(t *testing.T) {
	now := time.Now()
	checkIn := &PersonCheckIn{
		CheckInID:   "pci_test",
		CheckInType: CheckInTypeSponsor,
		Method:      MethodPhoneCall,
		Timestamp:   now,
		CreatedAt:   now,
		ModifiedAt:  now,
	}

	rating := 4
	notes := "Great conversation about Step 4"
	topics := []Topic{TopicStepWork, TopicAccountability}

	req := &UpdatePersonCheckInRequest{
		QualityRating:   &rating,
		Notes:           &notes,
		TopicsDiscussed: topics,
		FollowUpItems:   []string{"Write resentment list"},
	}

	ApplyUpdate(checkIn, req)

	if checkIn.QualityRating == nil || *checkIn.QualityRating != 4 {
		t.Fatal("expected quality rating 4 after patch")
	}
	if checkIn.Notes == nil || *checkIn.Notes != "Great conversation about Step 4" {
		t.Fatal("expected notes to be set after patch")
	}
	if len(checkIn.TopicsDiscussed) != 2 {
		t.Fatalf("expected 2 topics after patch, got %d", len(checkIn.TopicsDiscussed))
	}
	if len(checkIn.FollowUpItems) != 1 {
		t.Fatalf("expected 1 follow-up item, got %d", len(checkIn.FollowUpItems))
	}
}

func TestPersonCheckIn_FR_PCI_2_2_PatchUpdatesModifiedAtNotCreatedAt(t *testing.T) {
	originalCreated := time.Date(2026, 3, 28, 12, 0, 0, 0, time.UTC)
	originalModified := time.Date(2026, 3, 28, 12, 0, 0, 0, time.UTC)

	checkIn := &PersonCheckIn{
		CheckInID:   "pci_test",
		CheckInType: CheckInTypeSponsor,
		Method:      MethodPhoneCall,
		CreatedAt:   originalCreated,
		ModifiedAt:  originalModified,
	}

	// Wait briefly to ensure time difference.
	time.Sleep(time.Millisecond)

	rating := 3
	req := &UpdatePersonCheckInRequest{
		QualityRating: &rating,
	}

	ApplyUpdate(checkIn, req)

	if checkIn.CreatedAt != originalCreated {
		t.Fatal("CreatedAt was modified — it must be immutable")
	}
	if !checkIn.ModifiedAt.After(originalModified) {
		t.Fatal("ModifiedAt should have been updated to a later time")
	}
}
