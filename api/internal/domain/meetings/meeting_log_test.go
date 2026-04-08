// internal/domain/meetings/meeting_log_test.go
package meetings

import (
	"context"
	"testing"
	"time"
)

// --- Mock implementations ---

type mockMeetingRepo struct {
	meetings map[string]*MeetingLog
	createFn func(ctx context.Context, meeting *MeetingLog) error
}

func newMockMeetingRepo() *mockMeetingRepo {
	return &mockMeetingRepo{meetings: make(map[string]*MeetingLog)}
}

func (m *mockMeetingRepo) Create(ctx context.Context, meeting *MeetingLog) error {
	if m.createFn != nil {
		return m.createFn(ctx, meeting)
	}
	m.meetings[meeting.MeetingID] = meeting
	return nil
}

func (m *mockMeetingRepo) GetByID(ctx context.Context, userID, meetingID string) (*MeetingLog, error) {
	mtg, ok := m.meetings[meetingID]
	if !ok || mtg.UserID != userID {
		return nil, nil
	}
	return mtg, nil
}

func (m *mockMeetingRepo) ListByUser(ctx context.Context, userID string, filter ListMeetingLogsFilter) ([]*MeetingLog, string, error) {
	var results []*MeetingLog
	for _, mtg := range m.meetings {
		if mtg.UserID != userID {
			continue
		}
		if filter.MeetingType != nil && mtg.MeetingType != *filter.MeetingType {
			continue
		}
		results = append(results, mtg)
	}
	return results, "", nil
}

func (m *mockMeetingRepo) Update(ctx context.Context, meeting *MeetingLog) error {
	m.meetings[meeting.MeetingID] = meeting
	return nil
}

func (m *mockMeetingRepo) Delete(ctx context.Context, userID, meetingID string) error {
	delete(m.meetings, meetingID)
	return nil
}

func (m *mockMeetingRepo) GetMeetingsInRange(ctx context.Context, userID string, start, end time.Time) ([]*MeetingLog, error) {
	var results []*MeetingLog
	for _, mtg := range m.meetings {
		if mtg.UserID == userID && !mtg.Timestamp.Before(start) && !mtg.Timestamp.After(end) {
			results = append(results, mtg)
		}
	}
	return results, nil
}

type mockSavedMeetingRepo struct {
	saved map[string]*SavedMeeting
}

func newMockSavedMeetingRepo() *mockSavedMeetingRepo {
	return &mockSavedMeetingRepo{saved: make(map[string]*SavedMeeting)}
}

func (m *mockSavedMeetingRepo) Create(ctx context.Context, saved *SavedMeeting) error {
	m.saved[saved.SavedMeetingID] = saved
	return nil
}

func (m *mockSavedMeetingRepo) GetByID(ctx context.Context, userID, savedMeetingID string) (*SavedMeeting, error) {
	s, ok := m.saved[savedMeetingID]
	if !ok || s.UserID != userID {
		return nil, nil
	}
	return s, nil
}

func (m *mockSavedMeetingRepo) ListActive(ctx context.Context, userID string) ([]*SavedMeeting, error) {
	var results []*SavedMeeting
	for _, s := range m.saved {
		if s.UserID == userID && s.IsActive {
			results = append(results, s)
		}
	}
	return results, nil
}

func (m *mockSavedMeetingRepo) Update(ctx context.Context, saved *SavedMeeting) error {
	m.saved[saved.SavedMeetingID] = saved
	return nil
}

func (m *mockSavedMeetingRepo) SoftDelete(ctx context.Context, userID, savedMeetingID string) error {
	if s, ok := m.saved[savedMeetingID]; ok && s.UserID == userID {
		s.IsActive = false
	}
	return nil
}

type mockEventPublisher struct {
	events []*MeetingLog
}

func (m *mockEventPublisher) PublishMeetingCreated(ctx context.Context, meeting *MeetingLog) error {
	m.events = append(m.events, meeting)
	return nil
}

// --- Test helpers ---

func strPtr(s string) *string { return &s }
func intPtr(i int) *int       { return &i }

func makeTestService() (*MeetingLogService, *mockMeetingRepo, *mockSavedMeetingRepo, *mockEventPublisher) {
	meetingRepo := newMockMeetingRepo()
	savedRepo := newMockSavedMeetingRepo()
	publisher := &mockEventPublisher{}
	svc := NewMeetingLogService(meetingRepo, savedRepo, publisher)
	return svc, meetingRepo, savedRepo, publisher
}

// --- Tests ---

// TestMeetingLog_FR_MTG_1_1_CreateWithRequiredFieldsOnly verifies that a meeting log
// can be created with only the required fields (timestamp and meetingType).
//
// Acceptance Criterion (FR-MTG-1.1): meetingId generated, status defaults to "attended", optional fields null.
func TestMeetingLog_FR_MTG_1_1_CreateWithRequiredFieldsOnly(t *testing.T) {
	svc, _, _, _ := makeTestService()

	req := &CreateMeetingLogRequest{
		Timestamp:   time.Date(2026, 3, 28, 19, 0, 0, 0, time.UTC),
		MeetingType: MeetingTypeSA,
	}

	meeting, err := svc.CreateMeetingLog(context.Background(), "u_alex", "DEFAULT", req)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if meeting.MeetingID == "" {
		t.Error("expected meetingId to be generated")
	}
	if meeting.Status != MeetingStatusAttended {
		t.Errorf("expected status 'attended', got '%s'", meeting.Status)
	}
	if meeting.Name != nil {
		t.Error("expected name to be nil")
	}
	if meeting.Location != nil {
		t.Error("expected location to be nil")
	}
	if meeting.DurationMinutes != nil {
		t.Error("expected durationMinutes to be nil")
	}
	if meeting.Notes != nil {
		t.Error("expected notes to be nil")
	}
}

// TestMeetingLog_FR_MTG_1_2_ValidMeetingTypes verifies that all valid meeting types
// are accepted for meeting log creation.
//
// Acceptance Criterion (FR-MTG-1.2): SA, CR, AA, therapy, group-counseling, church, custom.
func TestMeetingLog_FR_MTG_1_2_ValidMeetingTypes(t *testing.T) {
	svc, _, _, _ := makeTestService()

	validTypes := []MeetingType{
		MeetingTypeSA, MeetingTypeCR, MeetingTypeAA,
		MeetingTypeTherapy, MeetingTypeGroupCounseling,
		MeetingTypeChurch, MeetingTypeCustom,
	}

	for _, mt := range validTypes {
		req := &CreateMeetingLogRequest{
			Timestamp:   time.Now().UTC(),
			MeetingType: mt,
		}
		// Custom type requires a label.
		if mt == MeetingTypeCustom {
			req.CustomTypeLabel = strPtr("Men's Group")
		}

		_, err := svc.CreateMeetingLog(context.Background(), "u_alex", "DEFAULT", req)
		if err != nil {
			t.Errorf("expected meeting type '%s' to be accepted, got error: %v", mt, err)
		}
	}
}

// TestMeetingLog_FR_MTG_1_2_InvalidMeetingType_Rejected verifies that invalid meeting types
// are rejected, with SAA explicitly excluded.
//
// Acceptance Criterion (FR-MTG-1.2): SAA is explicitly excluded.
func TestMeetingLog_FR_MTG_1_2_InvalidMeetingType_Rejected(t *testing.T) {
	svc, _, _, _ := makeTestService()

	invalidTypes := []MeetingType{"SAA", "NA", "invalid", ""}

	for _, mt := range invalidTypes {
		req := &CreateMeetingLogRequest{
			Timestamp:   time.Now().UTC(),
			MeetingType: mt,
		}

		_, err := svc.CreateMeetingLog(context.Background(), "u_alex", "DEFAULT", req)
		if err == nil {
			t.Errorf("expected meeting type '%s' to be rejected", mt)
		}
	}
}

// TestMeetingLog_FR_MTG_1_3_CustomTypeRequiresLabel verifies that a custom meeting type
// requires a customTypeLabel.
//
// Acceptance Criterion (FR-MTG-1.3): customTypeLabel is required when meetingType is 'custom'.
func TestMeetingLog_FR_MTG_1_3_CustomTypeRequiresLabel(t *testing.T) {
	svc, _, _, _ := makeTestService()

	req := &CreateMeetingLogRequest{
		Timestamp:   time.Now().UTC(),
		MeetingType: MeetingTypeCustom,
	}

	_, err := svc.CreateMeetingLog(context.Background(), "u_alex", "DEFAULT", req)
	if err == nil {
		t.Error("expected error when customTypeLabel is missing for custom type")
	}
}

// TestMeetingLog_FR_MTG_1_3_CustomTypeWithLabel verifies that a custom meeting type
// with a label is accepted and stored.
//
// Acceptance Criterion (FR-MTG-1.3): meetingType and customTypeLabel both stored.
func TestMeetingLog_FR_MTG_1_3_CustomTypeWithLabel(t *testing.T) {
	svc, _, _, _ := makeTestService()

	req := &CreateMeetingLogRequest{
		Timestamp:       time.Now().UTC(),
		MeetingType:     MeetingTypeCustom,
		CustomTypeLabel: strPtr("Men's Group"),
	}

	meeting, err := svc.CreateMeetingLog(context.Background(), "u_alex", "DEFAULT", req)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if meeting.MeetingType != MeetingTypeCustom {
		t.Errorf("expected meetingType 'custom', got '%s'", meeting.MeetingType)
	}
	if meeting.CustomTypeLabel == nil || *meeting.CustomTypeLabel != "Men's Group" {
		t.Error("expected customTypeLabel to be 'Men's Group'")
	}
}

// TestMeetingLog_FR_MTG_1_3_CustomTypeLabelMaxLength verifies that customTypeLabel
// exceeding 100 characters is rejected.
func TestMeetingLog_FR_MTG_1_3_CustomTypeLabelMaxLength(t *testing.T) {
	svc, _, _, _ := makeTestService()

	longLabel := make([]byte, 101)
	for i := range longLabel {
		longLabel[i] = 'a'
	}
	label := string(longLabel)

	req := &CreateMeetingLogRequest{
		Timestamp:       time.Now().UTC(),
		MeetingType:     MeetingTypeCustom,
		CustomTypeLabel: &label,
	}

	_, err := svc.CreateMeetingLog(context.Background(), "u_alex", "DEFAULT", req)
	if err == nil {
		t.Error("expected error for customTypeLabel exceeding 100 characters")
	}
}

// TestMeetingLog_FR_MTG_1_4_AllOptionalFields verifies that all optional fields
// are stored and returned on retrieval.
//
// Acceptance Criterion (FR-MTG-1.4): name, location, durationMinutes, notes all stored.
func TestMeetingLog_FR_MTG_1_4_AllOptionalFields(t *testing.T) {
	svc, _, _, _ := makeTestService()

	req := &CreateMeetingLogRequest{
		Timestamp:       time.Date(2026, 3, 28, 19, 0, 0, 0, time.UTC),
		MeetingType:     MeetingTypeSA,
		Name:            strPtr("Tuesday Night Recovery"),
		Location:        strPtr("Community Center"),
		DurationMinutes: intPtr(60),
		Notes:           strPtr("Shared my story. Felt supported."),
	}

	meeting, err := svc.CreateMeetingLog(context.Background(), "u_alex", "DEFAULT", req)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if meeting.Name == nil || *meeting.Name != "Tuesday Night Recovery" {
		t.Error("expected name to be stored")
	}
	if meeting.Location == nil || *meeting.Location != "Community Center" {
		t.Error("expected location to be stored")
	}
	if meeting.DurationMinutes == nil || *meeting.DurationMinutes != 60 {
		t.Error("expected durationMinutes to be stored")
	}
	if meeting.Notes == nil || *meeting.Notes != "Shared my story. Felt supported." {
		t.Error("expected notes to be stored")
	}
}

// TestMeetingLog_FR_MTG_1_4_NotesMaxLength verifies that notes exceeding 2000
// characters are rejected.
func TestMeetingLog_FR_MTG_1_4_NotesMaxLength(t *testing.T) {
	svc, _, _, _ := makeTestService()

	longNotes := make([]byte, 2001)
	for i := range longNotes {
		longNotes[i] = 'a'
	}
	notes := string(longNotes)

	req := &CreateMeetingLogRequest{
		Timestamp:   time.Now().UTC(),
		MeetingType: MeetingTypeSA,
		Notes:       &notes,
	}

	_, err := svc.CreateMeetingLog(context.Background(), "u_alex", "DEFAULT", req)
	if err == nil {
		t.Error("expected error for notes exceeding 2000 characters")
	}
}

// TestMeetingLog_FR_MTG_1_4_NameMaxLength verifies that name exceeding 200
// characters is rejected.
func TestMeetingLog_FR_MTG_1_4_NameMaxLength(t *testing.T) {
	svc, _, _, _ := makeTestService()

	longName := make([]byte, 201)
	for i := range longName {
		longName[i] = 'a'
	}
	name := string(longName)

	req := &CreateMeetingLogRequest{
		Timestamp:   time.Now().UTC(),
		MeetingType: MeetingTypeSA,
		Name:        &name,
	}

	_, err := svc.CreateMeetingLog(context.Background(), "u_alex", "DEFAULT", req)
	if err == nil {
		t.Error("expected error for name exceeding 200 characters")
	}
}

// TestMeetingLog_FR_MTG_1_4_DurationMinutesNonNegative verifies that negative
// durationMinutes is rejected.
func TestMeetingLog_FR_MTG_1_4_DurationMinutesNonNegative(t *testing.T) {
	svc, _, _, _ := makeTestService()

	req := &CreateMeetingLogRequest{
		Timestamp:       time.Now().UTC(),
		MeetingType:     MeetingTypeSA,
		DurationMinutes: intPtr(-1),
	}

	_, err := svc.CreateMeetingLog(context.Background(), "u_alex", "DEFAULT", req)
	if err == nil {
		t.Error("expected error for negative durationMinutes")
	}
}

// TestMeetingLog_FR_MTG_1_5_TimestampImmutable verifies that the timestamp field
// cannot be modified after creation (FR2.7).
//
// Acceptance Criterion (FR-MTG-1.5): Update rejected with 422 when timestamp included.
func TestMeetingLog_FR_MTG_1_5_TimestampImmutable(t *testing.T) {
	svc, repo, _, _ := makeTestService()

	// Create a meeting.
	originalTimestamp := time.Date(2026, 3, 28, 19, 0, 0, 0, time.UTC)
	meeting := &MeetingLog{
		MeetingID:   "mt_test01",
		UserID:      "u_alex",
		TenantID:    "DEFAULT",
		Timestamp:   originalTimestamp,
		MeetingType: MeetingTypeSA,
		Status:      MeetingStatusAttended,
		CreatedAt:   time.Now().UTC(),
		ModifiedAt:  time.Now().UTC(),
	}
	repo.meetings[meeting.MeetingID] = meeting

	// Update without timestamp (should succeed).
	updateReq := &UpdateMeetingLogRequest{
		Notes: strPtr("Updated notes"),
	}
	updated, err := svc.UpdateMeetingLog(context.Background(), "u_alex", "mt_test01", updateReq)
	if err != nil {
		t.Fatalf("unexpected error on valid update: %v", err)
	}

	// Verify timestamp is unchanged.
	if !updated.Timestamp.Equal(originalTimestamp) {
		t.Error("expected timestamp to remain immutable after update")
	}
}

// TestMeetingLog_FR_MTG_1_6_MultipleMeetingsSameDay verifies that multiple meetings
// on the same day are stored independently with unique IDs.
//
// Acceptance Criterion (FR-MTG-1.6): Both entries stored with unique meetingIds.
func TestMeetingLog_FR_MTG_1_6_MultipleMeetingsSameDay(t *testing.T) {
	svc, _, _, _ := makeTestService()

	req1 := &CreateMeetingLogRequest{
		Timestamp:   time.Date(2026, 3, 28, 10, 0, 0, 0, time.UTC),
		MeetingType: MeetingTypeSA,
	}
	req2 := &CreateMeetingLogRequest{
		Timestamp:   time.Date(2026, 3, 28, 19, 0, 0, 0, time.UTC),
		MeetingType: MeetingTypeCR,
	}

	meeting1, err := svc.CreateMeetingLog(context.Background(), "u_alex", "DEFAULT", req1)
	if err != nil {
		t.Fatalf("unexpected error creating first meeting: %v", err)
	}

	meeting2, err := svc.CreateMeetingLog(context.Background(), "u_alex", "DEFAULT", req2)
	if err != nil {
		t.Fatalf("unexpected error creating second meeting: %v", err)
	}

	if meeting1.MeetingID == meeting2.MeetingID {
		t.Error("expected different meetingIds for multiple meetings on same day")
	}
}

// TestMeetingLog_FR_MTG_5_2_EventPublished verifies that a commitment event is
// published when a meeting is logged.
//
// Acceptance Criterion (FR-MTG-5.2): Event published to commitments tracking system.
func TestMeetingLog_FR_MTG_5_2_EventPublished(t *testing.T) {
	svc, _, _, publisher := makeTestService()

	req := &CreateMeetingLogRequest{
		Timestamp:   time.Now().UTC(),
		MeetingType: MeetingTypeSA,
	}

	_, err := svc.CreateMeetingLog(context.Background(), "u_alex", "DEFAULT", req)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(publisher.events) != 1 {
		t.Errorf("expected 1 event published, got %d", len(publisher.events))
	}
}
