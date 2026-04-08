// internal/domain/phonecalls/validator_test.go
package phonecalls

import (
	"errors"
	"strings"
	"testing"
	"time"
)

// --- Call Log Validation Tests ---

func TestPhoneCall_AC_PC_1_CreateWithRequiredFields(t *testing.T) {
	req := &CreatePhoneCallRequest{
		Direction:   DirectionMade,
		ContactType: ContactTypeSponsor,
		Connected:   true,
	}
	if err := ValidateCreateRequest(req); err != nil {
		t.Errorf("expected valid request with required fields, got error: %v", err)
	}
}

func TestPhoneCall_AC_PC_2_DirectionValidation_Made(t *testing.T) {
	if err := ValidateDirection(DirectionMade); err != nil {
		t.Errorf("expected 'made' to be valid, got error: %v", err)
	}
}

func TestPhoneCall_AC_PC_2_DirectionValidation_Received(t *testing.T) {
	if err := ValidateDirection(DirectionReceived); err != nil {
		t.Errorf("expected 'received' to be valid, got error: %v", err)
	}
}

func TestPhoneCall_AC_PC_2_DirectionValidation_InvalidValue_RejectsRequest(t *testing.T) {
	err := ValidateDirection(Direction("invalid"))
	if err == nil {
		t.Error("expected error for invalid direction, got nil")
	}
	if !errors.Is(err, ErrInvalidDirection) {
		t.Errorf("expected ErrInvalidDirection, got: %v", err)
	}
}

func TestPhoneCall_AC_PC_3_ContactTypeValidation_AllValidValues(t *testing.T) {
	validTypes := []ContactType{
		ContactTypeSponsor,
		ContactTypeAccountabilityPartner,
		ContactTypeCounselor,
		ContactTypeCoach,
		ContactTypeSupportPerson,
		ContactTypeCustom,
	}
	for _, ct := range validTypes {
		t.Run(string(ct), func(t *testing.T) {
			if err := ValidateContactType(ct); err != nil {
				t.Errorf("expected %q to be valid, got error: %v", ct, err)
			}
		})
	}
}

func TestPhoneCall_AC_PC_3_ContactTypeValidation_InvalidValue_RejectsRequest(t *testing.T) {
	err := ValidateContactType(ContactType("friend"))
	if err == nil {
		t.Error("expected error for invalid contact type, got nil")
	}
	if !errors.Is(err, ErrInvalidContactType) {
		t.Errorf("expected ErrInvalidContactType, got: %v", err)
	}
}

func TestPhoneCall_AC_PC_4_CustomContactType_RequiresLabel(t *testing.T) {
	req := &CreatePhoneCallRequest{
		Direction:   DirectionMade,
		ContactType: ContactTypeCustom,
		Connected:   true,
	}
	err := ValidateCreateRequest(req)
	if err == nil {
		t.Error("expected error when custom contactType has no label, got nil")
	}
	if !errors.Is(err, ErrCustomLabelRequired) {
		t.Errorf("expected ErrCustomLabelRequired, got: %v", err)
	}
}

func TestPhoneCall_AC_PC_4_CustomContactType_WithLabel_Succeeds(t *testing.T) {
	label := "Church Friend"
	req := &CreatePhoneCallRequest{
		Direction:          DirectionMade,
		ContactType:        ContactTypeCustom,
		CustomContactLabel: &label,
		Connected:          true,
	}
	if err := ValidateCreateRequest(req); err != nil {
		t.Errorf("expected valid request with custom label, got error: %v", err)
	}
}

func TestPhoneCall_AC_PC_5_ConnectedStatus_True(t *testing.T) {
	req := &CreatePhoneCallRequest{
		Direction:   DirectionMade,
		ContactType: ContactTypeSponsor,
		Connected:   true,
	}
	if err := ValidateCreateRequest(req); err != nil {
		t.Errorf("expected valid request with connected=true, got error: %v", err)
	}
}

func TestPhoneCall_AC_PC_5_ConnectedStatus_False(t *testing.T) {
	req := &CreatePhoneCallRequest{
		Direction:   DirectionMade,
		ContactType: ContactTypeSponsor,
		Connected:   false,
	}
	if err := ValidateCreateRequest(req); err != nil {
		t.Errorf("expected valid request with connected=false, got error: %v", err)
	}
}

func TestPhoneCall_AC_PC_6_OptionalFields_AllOmitted_Succeeds(t *testing.T) {
	req := &CreatePhoneCallRequest{
		Direction:   DirectionMade,
		ContactType: ContactTypeSponsor,
		Connected:   true,
		// contactName, durationMinutes, notes all omitted
	}
	if err := ValidateCreateRequest(req); err != nil {
		t.Errorf("expected valid request with all optional fields omitted, got error: %v", err)
	}
}

func TestPhoneCall_AC_PC_7_ContactName_ExceedsMaxLength_Rejects(t *testing.T) {
	longName := strings.Repeat("a", 51)
	req := &CreatePhoneCallRequest{
		Direction:   DirectionMade,
		ContactType: ContactTypeSponsor,
		Connected:   true,
		ContactName: &longName,
	}
	err := ValidateCreateRequest(req)
	if err == nil {
		t.Error("expected error for contact name exceeding 50 chars, got nil")
	}
	if !errors.Is(err, ErrContactNameTooLong) {
		t.Errorf("expected ErrContactNameTooLong, got: %v", err)
	}
}

func TestPhoneCall_AC_PC_7_ContactName_AtMaxLength_Accepts(t *testing.T) {
	exactName := strings.Repeat("a", 50)
	req := &CreatePhoneCallRequest{
		Direction:   DirectionMade,
		ContactType: ContactTypeSponsor,
		Connected:   true,
		ContactName: &exactName,
	}
	if err := ValidateCreateRequest(req); err != nil {
		t.Errorf("expected valid request with 50-char name, got error: %v", err)
	}
}

func TestPhoneCall_AC_PC_8_Notes_ExceedsMaxLength_Rejects(t *testing.T) {
	longNotes := strings.Repeat("a", 501)
	req := &CreatePhoneCallRequest{
		Direction:   DirectionMade,
		ContactType: ContactTypeSponsor,
		Connected:   true,
		Notes:       &longNotes,
	}
	err := ValidateCreateRequest(req)
	if err == nil {
		t.Error("expected error for notes exceeding 500 chars, got nil")
	}
	if !errors.Is(err, ErrNotesTooLong) {
		t.Errorf("expected ErrNotesTooLong, got: %v", err)
	}
}

func TestPhoneCall_AC_PC_8_Notes_AtMaxLength_Accepts(t *testing.T) {
	exactNotes := strings.Repeat("a", 500)
	req := &CreatePhoneCallRequest{
		Direction:   DirectionMade,
		ContactType: ContactTypeSponsor,
		Connected:   true,
		Notes:       &exactNotes,
	}
	if err := ValidateCreateRequest(req); err != nil {
		t.Errorf("expected valid request with 500-char notes, got error: %v", err)
	}
}

func TestPhoneCall_AC_PC_9_Duration_ZeroIsValid(t *testing.T) {
	zero := 0
	req := &CreatePhoneCallRequest{
		Direction:       DirectionMade,
		ContactType:     ContactTypeSponsor,
		Connected:       true,
		DurationMinutes: &zero,
	}
	if err := ValidateCreateRequest(req); err != nil {
		t.Errorf("expected zero duration to be valid, got error: %v", err)
	}
}

func TestPhoneCall_AC_PC_9_Duration_NegativeIsRejected(t *testing.T) {
	negative := -1
	req := &CreatePhoneCallRequest{
		Direction:       DirectionMade,
		ContactType:     ContactTypeSponsor,
		Connected:       true,
		DurationMinutes: &negative,
	}
	err := ValidateCreateRequest(req)
	if err == nil {
		t.Error("expected error for negative duration, got nil")
	}
	if !errors.Is(err, ErrNegativeDuration) {
		t.Errorf("expected ErrNegativeDuration, got: %v", err)
	}
}

func TestPhoneCall_AC_PC_9_Duration_NullIsValid(t *testing.T) {
	req := &CreatePhoneCallRequest{
		Direction:   DirectionMade,
		ContactType: ContactTypeSponsor,
		Connected:   true,
		// DurationMinutes omitted (nil)
	}
	if err := ValidateCreateRequest(req); err != nil {
		t.Errorf("expected nil duration to be valid, got error: %v", err)
	}
}

func TestPhoneCall_AC_PC_10_BackdatedTimestamp_Accepted(t *testing.T) {
	yesterday := time.Now().AddDate(0, 0, -1)
	req := &CreatePhoneCallRequest{
		Timestamp:   &yesterday,
		Direction:   DirectionMade,
		ContactType: ContactTypeSponsor,
		Connected:   true,
	}
	if err := ValidateCreateRequest(req); err != nil {
		t.Errorf("expected backdated timestamp to be accepted, got error: %v", err)
	}
}

func TestPhoneCall_AC_PC_11_TimestampImmutable_UpdateRejectsTimestampChange(t *testing.T) {
	now := time.Now()
	req := &UpdatePhoneCallRequest{
		Timestamp: &now,
	}
	err := ValidateUpdateRequest(req)
	if err == nil {
		t.Error("expected error when updating timestamp, got nil")
	}
	if !errors.Is(err, ErrTimestampImmutable) {
		t.Errorf("expected ErrTimestampImmutable, got: %v", err)
	}
}

func TestPhoneCall_AC_PC_11_TimestampImmutable_OtherFieldsUpdateSuccessfully(t *testing.T) {
	name := "Mike S."
	duration := 20
	notes := "Great conversation"
	req := &UpdatePhoneCallRequest{
		ContactName:     &name,
		DurationMinutes: &duration,
		Notes:           &notes,
	}
	if err := ValidateUpdateRequest(req); err != nil {
		t.Errorf("expected valid update without timestamp, got error: %v", err)
	}
}

// --- Saved Contact Validation Tests ---

func TestSavedContact_AC_PC_30_CreateWithNameAndType(t *testing.T) {
	req := &CreateSavedContactRequest{
		ContactName: "Mike S.",
		ContactType: ContactTypeSponsor,
	}
	if err := ValidateCreateSavedContactRequest(req); err != nil {
		t.Errorf("expected valid request, got error: %v", err)
	}
}

func TestSavedContact_AC_PC_31_MaxTenContacts_RejectsEleventh(t *testing.T) {
	err := ValidateCanAddSavedContact(10)
	if err == nil {
		t.Error("expected error when at max contacts, got nil")
	}
	if !errors.Is(err, ErrMaxSavedContacts) {
		t.Errorf("expected ErrMaxSavedContacts, got: %v", err)
	}
}

func TestSavedContact_AC_PC_31_MaxTenContacts_AcceptsTenth(t *testing.T) {
	err := ValidateCanAddSavedContact(9)
	if err != nil {
		t.Errorf("expected 10th contact to be allowed, got error: %v", err)
	}
}

func TestSavedContact_AC_PC_32_PhoneNumberOptional_CreatesWithout(t *testing.T) {
	req := &CreateSavedContactRequest{
		ContactName: "Mike S.",
		ContactType: ContactTypeSponsor,
		// PhoneNumber omitted
	}
	if err := ValidateCreateSavedContactRequest(req); err != nil {
		t.Errorf("expected valid request without phone number, got error: %v", err)
	}
}

func TestSavedContact_AC_PC_32_PhoneNumberPresent_ValidE164(t *testing.T) {
	phone := "+15551234567"
	req := &CreateSavedContactRequest{
		ContactName: "Mike S.",
		ContactType: ContactTypeSponsor,
		PhoneNumber: &phone,
	}
	if err := ValidateCreateSavedContactRequest(req); err != nil {
		t.Errorf("expected valid request with E.164 phone, got error: %v", err)
	}
}

func TestSavedContact_PhoneNumber_InvalidFormat_Rejects(t *testing.T) {
	phone := "555-123-4567"
	req := &CreateSavedContactRequest{
		ContactName: "Mike S.",
		ContactType: ContactTypeSponsor,
		PhoneNumber: &phone,
	}
	err := ValidateCreateSavedContactRequest(req)
	if err == nil {
		t.Error("expected error for non-E.164 phone number, got nil")
	}
	if !errors.Is(err, ErrInvalidPhoneNumber) {
		t.Errorf("expected ErrInvalidPhoneNumber, got: %v", err)
	}
}

func TestSavedContact_EmptyName_Rejects(t *testing.T) {
	req := &CreateSavedContactRequest{
		ContactName: "",
		ContactType: ContactTypeSponsor,
	}
	err := ValidateCreateSavedContactRequest(req)
	if err == nil {
		t.Error("expected error for empty contact name, got nil")
	}
	if !errors.Is(err, ErrSavedContactNameRequired) {
		t.Errorf("expected ErrSavedContactNameRequired, got: %v", err)
	}
}
