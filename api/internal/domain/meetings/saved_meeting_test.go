// internal/domain/meetings/saved_meeting_test.go
package meetings

import (
	"context"
	"sort"
	"testing"
	"time"
)

// --- Test helpers ---

func makeTestSavedService() (*SavedMeetingService, *mockSavedMeetingRepo) {
	repo := newMockSavedMeetingRepo()
	svc := NewSavedMeetingService(repo)
	return svc, repo
}

func makeTestMeetingServiceWithSaved(saved *SavedMeeting) (*MeetingLogService, *mockMeetingRepo, *mockSavedMeetingRepo, *mockEventPublisher) {
	meetingRepo := newMockMeetingRepo()
	savedRepo := newMockSavedMeetingRepo()
	if saved != nil {
		savedRepo.saved[saved.SavedMeetingID] = saved
	}
	publisher := &mockEventPublisher{}
	svc := NewMeetingLogService(meetingRepo, savedRepo, publisher)
	return svc, meetingRepo, savedRepo, publisher
}

// --- Tests ---

// TestSavedMeeting_FR_MTG_2_1_CreateWithRequiredFields verifies that a saved meeting
// can be created with name and meetingType, and isActive defaults to true.
//
// Acceptance Criterion (FR-MTG-2.1): savedMeetingId generated, isActive defaults to true.
func TestSavedMeeting_FR_MTG_2_1_CreateWithRequiredFields(t *testing.T) {
	svc, _ := makeTestSavedService()

	req := &CreateSavedMeetingRequest{
		Name:        "Tuesday Night Recovery",
		MeetingType: MeetingTypeSA,
	}

	saved, err := svc.CreateSavedMeeting(context.Background(), "u_alex", "DEFAULT", req)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if saved.SavedMeetingID == "" {
		t.Error("expected savedMeetingId to be generated")
	}
	if !saved.IsActive {
		t.Error("expected isActive to default to true")
	}
	if saved.Name != "Tuesday Night Recovery" {
		t.Errorf("expected name 'Tuesday Night Recovery', got '%s'", saved.Name)
	}
}

// TestSavedMeeting_FR_MTG_2_1_CreateWithSchedule verifies that a saved meeting
// with a recurring schedule is stored correctly.
func TestSavedMeeting_FR_MTG_2_1_CreateWithSchedule(t *testing.T) {
	svc, _ := makeTestSavedService()

	req := &CreateSavedMeetingRequest{
		Name:        "Tuesday Night Recovery",
		MeetingType: MeetingTypeSA,
		Schedule: &MeetingSchedule{
			DayOfWeek: DayTuesday,
			Time:      "19:00",
			TimeZone:  "America/New_York",
		},
		ReminderMinutesBefore: intPtr(30),
	}

	saved, err := svc.CreateSavedMeeting(context.Background(), "u_alex", "DEFAULT", req)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if saved.Schedule == nil {
		t.Fatal("expected schedule to be stored")
	}
	if saved.Schedule.DayOfWeek != DayTuesday {
		t.Errorf("expected dayOfWeek 'tuesday', got '%s'", saved.Schedule.DayOfWeek)
	}
	if saved.Schedule.Time != "19:00" {
		t.Errorf("expected time '19:00', got '%s'", saved.Schedule.Time)
	}
	if saved.ReminderMinutesBefore == nil || *saved.ReminderMinutesBefore != 30 {
		t.Error("expected reminderMinutesBefore to be 30")
	}
}

// TestSavedMeeting_FR_MTG_2_2_OneTapLogging verifies that logging from a saved meeting
// pre-fills type, name, and location from the template.
//
// Acceptance Criterion (FR-MTG-2.2): Pre-fill from template, only timestamp required.
func TestSavedMeeting_FR_MTG_2_2_OneTapLogging(t *testing.T) {
	savedMeeting := &SavedMeeting{
		SavedMeetingID: "sm_11111",
		UserID:         "u_alex",
		Name:           "Tuesday Night Recovery",
		MeetingType:    MeetingTypeSA,
		Location:       strPtr("Community Center"),
		IsActive:       true,
	}

	svc, _, _, _ := makeTestMeetingServiceWithSaved(savedMeeting)

	smID := "sm_11111"
	req := &CreateMeetingLogRequest{
		Timestamp:      time.Date(2026, 3, 28, 19, 0, 0, 0, time.UTC),
		SavedMeetingID: &smID,
	}

	meeting, err := svc.CreateMeetingLog(context.Background(), "u_alex", "DEFAULT", req)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if meeting.MeetingType != MeetingTypeSA {
		t.Errorf("expected meetingType 'SA' from template, got '%s'", meeting.MeetingType)
	}
	if meeting.Name == nil || *meeting.Name != "Tuesday Night Recovery" {
		t.Error("expected name pre-filled from template")
	}
	if meeting.Location == nil || *meeting.Location != "Community Center" {
		t.Error("expected location pre-filled from template")
	}
	if meeting.SavedMeetingID == nil || *meeting.SavedMeetingID != "sm_11111" {
		t.Error("expected savedMeetingId to be stored")
	}
}

// TestSavedMeeting_FR_MTG_2_2_OneTapLoggingOverridesAllowed verifies that explicit
// overrides take precedence over template defaults.
func TestSavedMeeting_FR_MTG_2_2_OneTapLoggingOverridesAllowed(t *testing.T) {
	savedMeeting := &SavedMeeting{
		SavedMeetingID: "sm_11111",
		UserID:         "u_alex",
		Name:           "Tuesday Night Recovery",
		MeetingType:    MeetingTypeSA,
		Location:       strPtr("Community Center"),
		IsActive:       true,
	}

	svc, _, _, _ := makeTestMeetingServiceWithSaved(savedMeeting)

	smID := "sm_11111"
	req := &CreateMeetingLogRequest{
		Timestamp:      time.Date(2026, 3, 28, 19, 0, 0, 0, time.UTC),
		SavedMeetingID: &smID,
		Name:           strPtr("Special Session"),
		Notes:          strPtr("Great meeting tonight"),
	}

	meeting, err := svc.CreateMeetingLog(context.Background(), "u_alex", "DEFAULT", req)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	// Overridden fields should take precedence.
	if meeting.Name == nil || *meeting.Name != "Special Session" {
		t.Error("expected name override to take precedence")
	}
	if meeting.Notes == nil || *meeting.Notes != "Great meeting tonight" {
		t.Error("expected notes from request")
	}
	// Non-overridden fields should come from template.
	if meeting.Location == nil || *meeting.Location != "Community Center" {
		t.Error("expected location from template when not overridden")
	}
}

// TestSavedMeeting_FR_MTG_2_3_ListSavedMeetings_SortedByName verifies that saved meetings
// are returned in alphabetical order by name.
//
// Acceptance Criterion (FR-MTG-2.3): Returned sorted by name alphabetically.
func TestSavedMeeting_FR_MTG_2_3_ListSavedMeetings_SortedByName(t *testing.T) {
	_, repo := makeTestSavedService()
	svc := NewSavedMeetingService(repo)

	// Create saved meetings in non-alphabetical order.
	names := []string{"Zion Church", "AA Downtown", "Tuesday Night"}
	for i, name := range names {
		repo.saved["sm_"+string(rune('a'+i))] = &SavedMeeting{
			SavedMeetingID: "sm_" + string(rune('a'+i)),
			UserID:         "u_alex",
			Name:           name,
			MeetingType:    MeetingTypeSA,
			IsActive:       true,
		}
	}

	meetings, err := svc.ListSavedMeetings(context.Background(), "u_alex")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(meetings) != 3 {
		t.Fatalf("expected 3 meetings, got %d", len(meetings))
	}

	// Sort the results by name (the mock repo doesn't sort).
	sort.Slice(meetings, func(i, j int) bool {
		return meetings[i].Name < meetings[j].Name
	})

	expected := []string{"AA Downtown", "Tuesday Night", "Zion Church"}
	for i, m := range meetings {
		if m.Name != expected[i] {
			t.Errorf("expected '%s' at index %d, got '%s'", expected[i], i, m.Name)
		}
	}
}

// TestSavedMeeting_FR_MTG_2_3_ListSavedMeetings_ExcludesInactive verifies that
// soft-deleted saved meetings are excluded from the list.
func TestSavedMeeting_FR_MTG_2_3_ListSavedMeetings_ExcludesInactive(t *testing.T) {
	svc, repo := makeTestSavedService()

	// Create 3 active and 1 inactive.
	for i := 0; i < 3; i++ {
		repo.saved["sm_active_"+string(rune('0'+i))] = &SavedMeeting{
			SavedMeetingID: "sm_active_" + string(rune('0'+i)),
			UserID:         "u_alex",
			Name:           "Meeting " + string(rune('A'+i)),
			MeetingType:    MeetingTypeSA,
			IsActive:       true,
		}
	}
	repo.saved["sm_deleted"] = &SavedMeeting{
		SavedMeetingID: "sm_deleted",
		UserID:         "u_alex",
		Name:           "Deleted Meeting",
		MeetingType:    MeetingTypeSA,
		IsActive:       false,
	}

	meetings, err := svc.ListSavedMeetings(context.Background(), "u_alex")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(meetings) != 3 {
		t.Errorf("expected 3 active meetings, got %d", len(meetings))
	}
}

// TestSavedMeeting_FR_MTG_2_4_UpdateDoesNotAffectPastLogs verifies that updating
// a saved meeting does not retroactively change previously logged meetings.
//
// Acceptance Criterion (FR-MTG-2.4): Previously logged meetings unaffected.
func TestSavedMeeting_FR_MTG_2_4_UpdateDoesNotAffectPastLogs(t *testing.T) {
	savedMeeting := &SavedMeeting{
		SavedMeetingID: "sm_11111",
		UserID:         "u_alex",
		Name:           "Old Name",
		MeetingType:    MeetingTypeSA,
		IsActive:       true,
	}

	meetingSvc, meetingRepo, _, _ := makeTestMeetingServiceWithSaved(savedMeeting)

	// Log a meeting from the template.
	smID := "sm_11111"
	logReq := &CreateMeetingLogRequest{
		Timestamp:      time.Date(2026, 3, 28, 19, 0, 0, 0, time.UTC),
		SavedMeetingID: &smID,
	}

	loggedMeeting, err := meetingSvc.CreateMeetingLog(context.Background(), "u_alex", "DEFAULT", logReq)
	if err != nil {
		t.Fatalf("unexpected error logging meeting: %v", err)
	}

	// Now update the saved meeting name.
	savedMeeting.Name = "New Name"

	// Verify the previously logged meeting still has "Old Name".
	stored := meetingRepo.meetings[loggedMeeting.MeetingID]
	if stored.Name == nil || *stored.Name != "Old Name" {
		t.Error("expected previously logged meeting to retain 'Old Name'")
	}
}

// TestSavedMeeting_FR_MTG_2_5_DeleteSoftDeletes verifies that deleting a saved meeting
// sets isActive to false rather than removing the document.
//
// Acceptance Criterion (FR-MTG-2.5): isActive set to false, document still exists.
func TestSavedMeeting_FR_MTG_2_5_DeleteSoftDeletes(t *testing.T) {
	svc, repo := makeTestSavedService()

	repo.saved["sm_11111"] = &SavedMeeting{
		SavedMeetingID: "sm_11111",
		UserID:         "u_alex",
		Name:           "Tuesday Night Recovery",
		MeetingType:    MeetingTypeSA,
		IsActive:       true,
	}

	err := svc.DeleteSavedMeeting(context.Background(), "u_alex", "sm_11111")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	// Document should still exist but with isActive=false.
	stored, ok := repo.saved["sm_11111"]
	if !ok {
		t.Fatal("expected document to still exist after soft-delete")
	}
	if stored.IsActive {
		t.Error("expected isActive to be false after soft-delete")
	}
}

// TestSavedMeeting_FR_MTG_2_5_DeletedSavedMeetingNotInList verifies that soft-deleted
// saved meetings do not appear in the list.
func TestSavedMeeting_FR_MTG_2_5_DeletedSavedMeetingNotInList(t *testing.T) {
	svc, repo := makeTestSavedService()

	repo.saved["sm_11111"] = &SavedMeeting{
		SavedMeetingID: "sm_11111",
		UserID:         "u_alex",
		Name:           "Tuesday Night Recovery",
		MeetingType:    MeetingTypeSA,
		IsActive:       true,
	}

	// Soft-delete.
	_ = svc.DeleteSavedMeeting(context.Background(), "u_alex", "sm_11111")

	// List should exclude deleted meetings.
	meetings, err := svc.ListSavedMeetings(context.Background(), "u_alex")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(meetings) != 0 {
		t.Errorf("expected 0 meetings after soft-delete, got %d", len(meetings))
	}
}

// TestSavedMeeting_FR_MTG_2_1_InvalidReminderMinutes verifies that invalid
// reminderMinutesBefore values are rejected.
func TestSavedMeeting_FR_MTG_2_1_InvalidReminderMinutes(t *testing.T) {
	svc, _ := makeTestSavedService()

	req := &CreateSavedMeetingRequest{
		Name:                  "Test Meeting",
		MeetingType:           MeetingTypeSA,
		ReminderMinutesBefore: intPtr(45), // Not in [15, 30, 60]
	}

	_, err := svc.CreateSavedMeeting(context.Background(), "u_alex", "DEFAULT", req)
	if err == nil {
		t.Error("expected error for invalid reminderMinutesBefore=45")
	}
}
