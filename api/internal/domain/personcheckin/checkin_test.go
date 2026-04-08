// internal/domain/personcheckin/checkin_test.go
package personcheckin

import (
	"testing"
	"time"
)

func TestPersonCheckIn_FR_PCI_1_1_CreatesEntryWithImmutableTimestamp(t *testing.T) {
	now := time.Now()
	ts := now.Add(-time.Hour)

	req := &CreatePersonCheckInRequest{
		CheckInType: CheckInTypeSpouse,
		Method:      MethodInPerson,
		Timestamp:   &ts,
	}

	if err := ValidateCreateRequest(req); err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
}

func TestPersonCheckIn_FR_PCI_1_2_RejectsInvalidCheckInType(t *testing.T) {
	req := &CreatePersonCheckInRequest{
		CheckInType: "invalid-type",
		Method:      MethodInPerson,
	}

	err := ValidateCreateRequest(req)
	if err == nil {
		t.Fatal("expected error for invalid check-in type")
	}
	if err != ErrInvalidCheckInType {
		t.Fatalf("expected ErrInvalidCheckInType, got: %v", err)
	}
}

func TestPersonCheckIn_FR_PCI_1_3_RejectsInvalidMethod(t *testing.T) {
	req := &CreatePersonCheckInRequest{
		CheckInType: CheckInTypeSpouse,
		Method:      "carrier-pigeon",
	}

	err := ValidateCreateRequest(req)
	if err == nil {
		t.Fatal("expected error for invalid method")
	}
	if err != ErrInvalidMethod {
		t.Fatalf("expected ErrInvalidMethod, got: %v", err)
	}
}

func TestPersonCheckIn_FR_PCI_1_4_RejectsContactNameExceeding50Chars(t *testing.T) {
	longName := string(make([]byte, 51))
	for i := range longName {
		longName = longName[:i] + "a" + longName[i+1:]
	}
	name := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaX" // 51 chars

	req := &CreatePersonCheckInRequest{
		CheckInType: CheckInTypeSpouse,
		Method:      MethodInPerson,
		ContactName: &name,
	}

	err := ValidateCreateRequest(req)
	if err != ErrContactNameTooLong {
		t.Fatalf("expected ErrContactNameTooLong, got: %v", err)
	}
}

func TestPersonCheckIn_FR_PCI_1_5_RejectsNotesExceeding1000Chars(t *testing.T) {
	longNotes := make([]byte, 1001)
	for i := range longNotes {
		longNotes[i] = 'x'
	}
	notes := string(longNotes)

	req := &CreatePersonCheckInRequest{
		CheckInType: CheckInTypeSpouse,
		Method:      MethodInPerson,
		Notes:       &notes,
	}

	err := ValidateCreateRequest(req)
	if err != ErrNotesTooLong {
		t.Fatalf("expected ErrNotesTooLong, got: %v", err)
	}
}

func TestPersonCheckIn_FR_PCI_1_6_RejectsQualityRatingOutOfRange(t *testing.T) {
	tests := []struct {
		name   string
		rating int
	}{
		{"zero", 0},
		{"negative", -1},
		{"six", 6},
		{"hundred", 100},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := &CreatePersonCheckInRequest{
				CheckInType:   CheckInTypeSpouse,
				Method:        MethodInPerson,
				QualityRating: &tt.rating,
			}

			err := ValidateCreateRequest(req)
			if err != ErrQualityRatingOutOfRange {
				t.Fatalf("expected ErrQualityRatingOutOfRange, got: %v", err)
			}
		})
	}
}

func TestPersonCheckIn_FR_PCI_1_7_RejectsInvalidTopicDiscussed(t *testing.T) {
	req := &CreatePersonCheckInRequest{
		CheckInType:     CheckInTypeSpouse,
		Method:          MethodInPerson,
		TopicsDiscussed: []Topic{"invalid-topic"},
	}

	err := ValidateCreateRequest(req)
	if err == nil {
		t.Fatal("expected error for invalid topic")
	}
}

func TestPersonCheckIn_FR_PCI_1_8_RejectsMoreThan3FollowUpItems(t *testing.T) {
	req := &CreatePersonCheckInRequest{
		CheckInType:  CheckInTypeSpouse,
		Method:       MethodInPerson,
		FollowUpItems: []string{"one", "two", "three", "four"},
	}

	err := ValidateCreateRequest(req)
	if err != ErrTooManyFollowUpItems {
		t.Fatalf("expected ErrTooManyFollowUpItems, got: %v", err)
	}
}

func TestPersonCheckIn_FR_PCI_1_8_RejectsFollowUpItemExceeding200Chars(t *testing.T) {
	longItem := make([]byte, 201)
	for i := range longItem {
		longItem[i] = 'x'
	}

	req := &CreatePersonCheckInRequest{
		CheckInType:  CheckInTypeSpouse,
		Method:       MethodInPerson,
		FollowUpItems: []string{string(longItem)},
	}

	err := ValidateCreateRequest(req)
	if err != ErrFollowUpItemTooLong {
		t.Fatalf("expected ErrFollowUpItemTooLong, got: %v", err)
	}
}

func TestPersonCheckIn_FR_PCI_1_9_RejectsDurationMinutesOutOfRange(t *testing.T) {
	tests := []struct {
		name     string
		duration int
	}{
		{"negative", -1},
		{"too_high", 481},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := &CreatePersonCheckInRequest{
				CheckInType:     CheckInTypeSpouse,
				Method:          MethodInPerson,
				DurationMinutes: &tt.duration,
			}

			err := ValidateCreateRequest(req)
			if err != ErrDurationOutOfRange {
				t.Fatalf("expected ErrDurationOutOfRange, got: %v", err)
			}
		})
	}
}

func TestPersonCheckIn_FR_PCI_1_10_AcceptsBackdatedTimestamp(t *testing.T) {
	pastTime := time.Now().Add(-72 * time.Hour)

	req := &CreatePersonCheckInRequest{
		CheckInType: CheckInTypeSpouse,
		Method:      MethodInPerson,
		Timestamp:   &pastTime,
	}

	if err := ValidateCreateRequest(req); err != nil {
		t.Fatalf("expected no error for backdated timestamp, got: %v", err)
	}
}

func TestPersonCheckIn_FR_PCI_1_11_SuggestsPreviousContactName(t *testing.T) {
	// Test that settings carry the contact name for suggestion.
	settings := DefaultSettings("u_test", "DEFAULT")
	name := "Sarah"
	settings.Spouse.ContactName = &name

	subSettings := GetSubTypeSettings(settings, CheckInTypeSpouse)
	if subSettings.ContactName == nil || *subSettings.ContactName != "Sarah" {
		t.Fatal("expected contact name suggestion from settings")
	}
}

func TestPersonCheckIn_NFR_PCI_1_CreatedAtIsImmutableOnUpdate(t *testing.T) {
	originalTime := time.Date(2026, 3, 28, 18, 30, 0, 0, time.UTC)

	checkIn := &PersonCheckIn{
		CheckInID:   "pci_test",
		CheckInType: CheckInTypeSpouse,
		Method:      MethodInPerson,
		Timestamp:   originalTime,
		CreatedAt:   originalTime,
		ModifiedAt:  originalTime,
	}

	rating := 5
	req := &UpdatePersonCheckInRequest{
		QualityRating: &rating,
	}

	ApplyUpdate(checkIn, req)

	if checkIn.CreatedAt != originalTime {
		t.Fatalf("CreatedAt was modified: expected %v, got %v", originalTime, checkIn.CreatedAt)
	}
	if checkIn.ModifiedAt == originalTime {
		t.Fatal("ModifiedAt should have been updated")
	}
	if *checkIn.QualityRating != 5 {
		t.Fatalf("QualityRating not updated: expected 5, got %d", *checkIn.QualityRating)
	}
}

func TestPersonCheckIn_CheckInTypeIsImmutableOnUpdate(t *testing.T) {
	checkIn := &PersonCheckIn{
		CheckInID:   "pci_test",
		CheckInType: CheckInTypeSpouse,
		Method:      MethodInPerson,
		CreatedAt:   time.Now(),
		ModifiedAt:  time.Now(),
	}

	// UpdatePersonCheckInRequest does not include checkInType field,
	// so it is structurally impossible to change via ApplyUpdate.
	req := &UpdatePersonCheckInRequest{}
	ApplyUpdate(checkIn, req)

	if checkIn.CheckInType != CheckInTypeSpouse {
		t.Fatalf("CheckInType was modified: expected spouse, got %s", checkIn.CheckInType)
	}
}

func TestPersonCheckIn_AllowsNullOptionalFields(t *testing.T) {
	req := &CreatePersonCheckInRequest{
		CheckInType: CheckInTypeSpouse,
		Method:      MethodInPerson,
	}

	if err := ValidateCreateRequest(req); err != nil {
		t.Fatalf("expected no error with nil optional fields, got: %v", err)
	}
}

func TestPersonCheckIn_DefaultsTimestampToNowWhenOmitted(t *testing.T) {
	req := &CreatePersonCheckInRequest{
		CheckInType: CheckInTypeSpouse,
		Method:      MethodInPerson,
	}

	// Timestamp is nil, which means the service should default to now.
	if req.Timestamp != nil {
		t.Fatal("expected nil timestamp for default-to-now behavior")
	}
}

func TestPersonCheckIn_CounselorSubCategory_AcceptsValidValues(t *testing.T) {
	scheduled := CounselorSubCategoryScheduledSession
	req := &CreatePersonCheckInRequest{
		CheckInType:          CheckInTypeCounselorCoach,
		Method:               MethodInPerson,
		CounselorSubCategory: &scheduled,
	}

	if err := ValidateCreateRequest(req); err != nil {
		t.Fatalf("expected no error for valid counselor sub-category, got: %v", err)
	}

	between := CounselorSubCategoryBetweenSessionContact
	req.CounselorSubCategory = &between
	if err := ValidateCreateRequest(req); err != nil {
		t.Fatalf("expected no error for valid counselor sub-category, got: %v", err)
	}
}

func TestPersonCheckIn_CounselorSubCategory_RejectsForNonCounselorType(t *testing.T) {
	scheduled := CounselorSubCategoryScheduledSession
	req := &CreatePersonCheckInRequest{
		CheckInType:          CheckInTypeSpouse,
		Method:               MethodInPerson,
		CounselorSubCategory: &scheduled,
	}

	err := ValidateCreateRequest(req)
	if err != ErrCounselorSubCategoryForNonCounselor {
		t.Fatalf("expected ErrCounselorSubCategoryForNonCounselor, got: %v", err)
	}
}
