// internal/domain/meetings/validation_test.go
package meetings

import (
	"errors"
	"testing"
	"time"
)

// TestValidation_MeetingType_SAA_Rejected verifies that SAA is explicitly
// rejected as an invalid meeting type.
func TestValidation_MeetingType_SAA_Rejected(t *testing.T) {
	err := validateMeetingType("SAA", nil)
	if err == nil {
		t.Error("expected SAA to be rejected")
	}
	if !errors.Is(err, ErrInvalidMeetingType) {
		t.Errorf("expected ErrInvalidMeetingType, got %v", err)
	}
}

// TestValidation_MeetingType_AllValid verifies all valid meeting types pass validation.
func TestValidation_MeetingType_AllValid(t *testing.T) {
	validTypes := []MeetingType{
		MeetingTypeSA, MeetingTypeCR, MeetingTypeAA,
		MeetingTypeTherapy, MeetingTypeGroupCounseling,
		MeetingTypeChurch,
	}

	for _, mt := range validTypes {
		err := validateMeetingType(mt, nil)
		if err != nil {
			t.Errorf("expected meeting type '%s' to be valid, got error: %v", mt, err)
		}
	}
}

// TestValidation_CustomType_MissingLabel verifies that custom type requires a label.
func TestValidation_CustomType_MissingLabel(t *testing.T) {
	err := validateMeetingType(MeetingTypeCustom, nil)
	if err == nil {
		t.Error("expected error when custom type has no label")
	}
	if !errors.Is(err, ErrCustomTypeLabelRequired) {
		t.Errorf("expected ErrCustomTypeLabelRequired, got %v", err)
	}
}

// TestValidation_CustomType_EmptyLabel verifies that custom type with empty string label is rejected.
func TestValidation_CustomType_EmptyLabel(t *testing.T) {
	empty := ""
	err := validateMeetingType(MeetingTypeCustom, &empty)
	if err == nil {
		t.Error("expected error when custom type has empty label")
	}
}

// TestValidation_CustomType_WithLabel verifies that custom type with a valid label passes.
func TestValidation_CustomType_WithLabel(t *testing.T) {
	label := "Men's Group"
	err := validateMeetingType(MeetingTypeCustom, &label)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
}

// TestValidation_Schedule_InvalidDay verifies that invalid day of week is rejected.
func TestValidation_Schedule_InvalidDay(t *testing.T) {
	schedule := &MeetingSchedule{
		DayOfWeek: "invalid",
		Time:      "19:00",
		TimeZone:  "America/New_York",
	}
	err := validateSchedule(schedule)
	if err == nil {
		t.Error("expected error for invalid day of week")
	}
}

// TestValidation_Schedule_InvalidTime verifies that invalid time format is rejected.
func TestValidation_Schedule_InvalidTime(t *testing.T) {
	schedule := &MeetingSchedule{
		DayOfWeek: DayTuesday,
		Time:      "7pm",
		TimeZone:  "America/New_York",
	}
	err := validateSchedule(schedule)
	if err == nil {
		t.Error("expected error for invalid time format")
	}
}

// TestValidation_Schedule_MissingTimeZone verifies that missing timezone is rejected.
func TestValidation_Schedule_MissingTimeZone(t *testing.T) {
	schedule := &MeetingSchedule{
		DayOfWeek: DayTuesday,
		Time:      "19:00",
		TimeZone:  "",
	}
	err := validateSchedule(schedule)
	if err == nil {
		t.Error("expected error for missing timezone")
	}
}

// TestValidation_Schedule_Valid verifies that a valid schedule passes.
func TestValidation_Schedule_Valid(t *testing.T) {
	schedule := &MeetingSchedule{
		DayOfWeek: DayTuesday,
		Time:      "19:00",
		TimeZone:  "America/New_York",
	}
	err := validateSchedule(schedule)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
}

// TestValidation_ReminderMinutes_Valid verifies valid reminder values.
func TestValidation_ReminderMinutes_Valid(t *testing.T) {
	valid := []int{15, 30, 60}
	for _, v := range valid {
		if !validReminderMinutes[v] {
			t.Errorf("expected %d to be a valid reminder duration", v)
		}
	}
}

// TestValidation_ReminderMinutes_Invalid verifies invalid reminder values.
func TestValidation_ReminderMinutes_Invalid(t *testing.T) {
	invalid := []int{0, 10, 20, 45, 90, 120}
	for _, v := range invalid {
		if validReminderMinutes[v] {
			t.Errorf("expected %d to be an invalid reminder duration", v)
		}
	}
}

// TestValidation_CreateMeetingLog_MissingTimestamp verifies that missing timestamp is rejected.
func TestValidation_CreateMeetingLog_MissingTimestamp(t *testing.T) {
	req := &CreateMeetingLogRequest{
		MeetingType: MeetingTypeSA,
	}
	err := ValidateCreateMeetingLogRequest(req)
	if err == nil {
		t.Error("expected error for missing timestamp")
	}
}

// TestValidation_CreateMeetingLog_MissingMeetingType verifies that missing meeting type is rejected.
func TestValidation_CreateMeetingLog_MissingMeetingType(t *testing.T) {
	req := &CreateMeetingLogRequest{
		Timestamp: time.Now().UTC(),
	}
	err := ValidateCreateMeetingLogRequest(req)
	if err == nil {
		t.Error("expected error for missing meeting type")
	}
}

// TestValidation_CreateMeetingLog_LocationMaxLength verifies location max length.
func TestValidation_CreateMeetingLog_LocationMaxLength(t *testing.T) {
	longLoc := make([]byte, 301)
	for i := range longLoc {
		longLoc[i] = 'a'
	}
	loc := string(longLoc)

	req := &CreateMeetingLogRequest{
		Timestamp:   time.Now().UTC(),
		MeetingType: MeetingTypeSA,
		Location:    &loc,
	}
	err := ValidateCreateMeetingLogRequest(req)
	if err == nil {
		t.Error("expected error for location exceeding 300 characters")
	}
}

// TestValidation_UpdateMeetingLog_InvalidStatus verifies that invalid status is rejected.
func TestValidation_UpdateMeetingLog_InvalidStatus(t *testing.T) {
	badStatus := MeetingStatus("invalid")
	req := &UpdateMeetingLogRequest{
		Status: &badStatus,
	}
	err := ValidateUpdateMeetingLogRequest(req)
	if err == nil {
		t.Error("expected error for invalid status")
	}
}

// TestValidation_MeetingStatus_Valid verifies valid statuses.
func TestValidation_MeetingStatus_Valid(t *testing.T) {
	if !IsValidMeetingStatus(MeetingStatusAttended) {
		t.Error("expected 'attended' to be valid")
	}
	if !IsValidMeetingStatus(MeetingStatusCanceled) {
		t.Error("expected 'canceled' to be valid")
	}
}

// TestValidation_MeetingStatus_Invalid verifies invalid statuses.
func TestValidation_MeetingStatus_Invalid(t *testing.T) {
	if IsValidMeetingStatus("absent") {
		t.Error("expected 'absent' to be invalid")
	}
	if IsValidMeetingStatus("") {
		t.Error("expected empty string to be invalid")
	}
}
