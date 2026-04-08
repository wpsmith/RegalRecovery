// test/unit/prayer/session_test.go
package prayer_test

import (
	"strings"
	"testing"
	"time"

	"github.com/regalrecovery/api/internal/domain/prayer"
)

func intPtr(v int) *int       { return &v }
func strPtr(v string) *string { return &v }
func timePtr(v time.Time) *time.Time { return &v }

// TestPrayerSession_PR_AC1_2_RejectInvalidPrayerType verifies that an invalid
// prayer type is rejected with the correct error.
//
// Acceptance Criterion (PR-AC1.2): prayerType must be one of the allowed enum values.
func TestPrayerSession_PR_AC1_2_RejectInvalidPrayerType(t *testing.T) {
	now := time.Now().UTC()
	req := &prayer.CreatePrayerSessionRequest{
		Timestamp:  now,
		PrayerType: "meditation",
	}

	err := prayer.ValidateCreateSession(req, now)
	if err != prayer.ErrInvalidPrayerType {
		t.Errorf("expected ErrInvalidPrayerType, got %v", err)
	}
}

// TestPrayerSession_PR_AC1_2_AcceptAllValidPrayerTypes verifies all valid prayer
// types are accepted.
//
// Acceptance Criterion (PR-AC1.2): Each of the 6 prayer types should be valid.
func TestPrayerSession_PR_AC1_2_AcceptAllValidPrayerTypes(t *testing.T) {
	now := time.Now().UTC()
	types := []string{"personal", "guided", "group", "scriptureBased", "intercessory", "listening"}

	for _, pt := range types {
		req := &prayer.CreatePrayerSessionRequest{
			Timestamp:  now,
			PrayerType: pt,
		}
		err := prayer.ValidateCreateSession(req, now)
		if err != nil {
			t.Errorf("expected prayerType %q to be valid, got error: %v", pt, err)
		}
	}
}

// TestPrayerSession_PR_AC1_3_DurationIsOptional verifies that duration can be nil.
//
// Acceptance Criterion (PR-AC1.3): durationMinutes is optional and null is valid.
func TestPrayerSession_PR_AC1_3_DurationIsOptional(t *testing.T) {
	now := time.Now().UTC()
	req := &prayer.CreatePrayerSessionRequest{
		Timestamp:       now,
		PrayerType:      "personal",
		DurationMinutes: nil,
	}

	err := prayer.ValidateCreateSession(req, now)
	if err != nil {
		t.Errorf("expected nil duration to be valid, got error: %v", err)
	}

	session := prayer.NewPrayerSession("ps_test", "user1", req, now)
	if session.DurationMinutes != nil {
		t.Error("expected DurationMinutes to be nil")
	}
}

// TestPrayerSession_PR_AC1_4_RejectNotesExceeding1000Chars verifies the notes
// character limit.
//
// Acceptance Criterion (PR-AC1.4): Notes exceeding 1000 characters are rejected.
func TestPrayerSession_PR_AC1_4_RejectNotesExceeding1000Chars(t *testing.T) {
	now := time.Now().UTC()
	longNotes := strings.Repeat("a", 1001)
	req := &prayer.CreatePrayerSessionRequest{
		Timestamp:  now,
		PrayerType: "personal",
		Notes:      &longNotes,
	}

	err := prayer.ValidateCreateSession(req, now)
	if err != prayer.ErrNotesExceedLimit {
		t.Errorf("expected ErrNotesExceedLimit, got %v", err)
	}
}

// TestPrayerSession_PR_AC1_4_AcceptNotesAt1000Chars verifies notes at exactly
// the limit are accepted.
//
// Acceptance Criterion (PR-AC1.4): Notes at exactly 1000 characters are valid.
func TestPrayerSession_PR_AC1_4_AcceptNotesAt1000Chars(t *testing.T) {
	now := time.Now().UTC()
	notes := strings.Repeat("a", 1000)
	req := &prayer.CreatePrayerSessionRequest{
		Timestamp:  now,
		PrayerType: "personal",
		Notes:      &notes,
	}

	err := prayer.ValidateCreateSession(req, now)
	if err != nil {
		t.Errorf("expected 1000-char notes to be valid, got error: %v", err)
	}
}

// TestPrayerSession_PR_AC1_7_AcceptMoodInRange verifies mood values within 1-5 are accepted.
//
// Acceptance Criterion (PR-AC1.7): Mood ratings between 1 and 5 inclusive are valid.
func TestPrayerSession_PR_AC1_7_AcceptMoodInRange(t *testing.T) {
	now := time.Now().UTC()
	req := &prayer.CreatePrayerSessionRequest{
		Timestamp:  now,
		PrayerType: "personal",
		MoodBefore: intPtr(1),
		MoodAfter:  intPtr(5),
	}

	err := prayer.ValidateCreateSession(req, now)
	if err != nil {
		t.Errorf("expected mood 1-5 to be valid, got error: %v", err)
	}
}

// TestPrayerSession_PR_AC1_8_RejectMoodOutOfRange verifies mood values outside 1-5.
//
// Acceptance Criterion (PR-AC1.8): Mood ratings outside 1-5 are rejected.
func TestPrayerSession_PR_AC1_8_RejectMoodOutOfRange(t *testing.T) {
	now := time.Now().UTC()

	tests := []struct {
		name   string
		before *int
		after  *int
	}{
		{"moodBefore=0", intPtr(0), nil},
		{"moodAfter=6", nil, intPtr(6)},
		{"moodBefore=-1", intPtr(-1), nil},
		{"moodAfter=10", nil, intPtr(10)},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := &prayer.CreatePrayerSessionRequest{
				Timestamp:  now,
				PrayerType: "personal",
				MoodBefore: tt.before,
				MoodAfter:  tt.after,
			}
			err := prayer.ValidateCreateSession(req, now)
			if err != prayer.ErrMoodOutOfRange {
				t.Errorf("expected ErrMoodOutOfRange, got %v", err)
			}
		})
	}
}

// TestPrayerSession_PR_AC1_9_AllowBackdatingWithin7Days verifies backdating within 7 days.
//
// Acceptance Criterion (PR-AC1.9): Timestamps up to 7 days in the past are allowed.
func TestPrayerSession_PR_AC1_9_AllowBackdatingWithin7Days(t *testing.T) {
	now := time.Now().UTC()
	fiveDaysAgo := now.AddDate(0, 0, -5)
	req := &prayer.CreatePrayerSessionRequest{
		Timestamp:  fiveDaysAgo,
		PrayerType: "personal",
	}

	err := prayer.ValidateCreateSession(req, now)
	if err != nil {
		t.Errorf("expected 5-day backdate to be valid, got error: %v", err)
	}
}

// TestPrayerSession_PR_AC1_9_RejectBackdatingBeyond7Days verifies rejection beyond 7 days.
//
// Acceptance Criterion (PR-AC1.9): Timestamps more than 7 days ago are rejected.
func TestPrayerSession_PR_AC1_9_RejectBackdatingBeyond7Days(t *testing.T) {
	now := time.Now().UTC()
	eightDaysAgo := now.AddDate(0, 0, -8)
	req := &prayer.CreatePrayerSessionRequest{
		Timestamp:  eightDaysAgo,
		PrayerType: "personal",
	}

	err := prayer.ValidateCreateSession(req, now)
	if err != prayer.ErrBackdatingTooFar {
		t.Errorf("expected ErrBackdatingTooFar, got %v", err)
	}
}

// TestPrayerSession_PR_AC1_10_TimestampIsImmutable verifies timestamp cannot be updated.
//
// Acceptance Criterion (PR-AC1.10): Timestamp is immutable per FR2.7.
func TestPrayerSession_PR_AC1_10_TimestampIsImmutable(t *testing.T) {
	now := time.Now().UTC()
	existing := &prayer.PrayerSession{
		PrayerID:           "ps_test",
		Timestamp:          now.Add(-1 * time.Hour),
		PrayerType:         "personal",
		NotesEditableUntil: now.Add(23 * time.Hour),
		CreatedAt:          now.Add(-1 * time.Hour),
	}

	newTS := now
	req := &prayer.UpdatePrayerSessionRequest{
		Timestamp: &newTS,
	}

	err := prayer.ValidateUpdateSession(req, existing, now)
	if err != prayer.ErrTimestampImmutable {
		t.Errorf("expected ErrTimestampImmutable, got %v", err)
	}
}

// TestPrayerSession_PR_AC1_13_NotesEditableWithin24Hours verifies notes can be edited
// within the 24-hour window.
//
// Acceptance Criterion (PR-AC1.13): Notes editable within 24 hours of creation.
func TestPrayerSession_PR_AC1_13_NotesEditableWithin24Hours(t *testing.T) {
	createdAt := time.Now().UTC().Add(-23 * time.Hour)
	now := time.Now().UTC()
	existing := &prayer.PrayerSession{
		PrayerID:           "ps_test",
		Timestamp:          createdAt,
		PrayerType:         "personal",
		NotesEditableUntil: createdAt.Add(24 * time.Hour),
		CreatedAt:          createdAt,
	}

	newNotes := "Updated notes"
	req := &prayer.UpdatePrayerSessionRequest{
		Notes: &newNotes,
	}

	err := prayer.ValidateUpdateSession(req, existing, now)
	if err != nil {
		t.Errorf("expected notes update within 24h to succeed, got error: %v", err)
	}
}

// TestPrayerSession_PR_AC1_13_NotesReadOnlyAfter24Hours verifies notes become read-only
// after the 24-hour window.
//
// Acceptance Criterion (PR-AC1.13): Notes are read-only after 24 hours.
func TestPrayerSession_PR_AC1_13_NotesReadOnlyAfter24Hours(t *testing.T) {
	createdAt := time.Now().UTC().Add(-25 * time.Hour)
	now := time.Now().UTC()
	existing := &prayer.PrayerSession{
		PrayerID:           "ps_test",
		Timestamp:          createdAt,
		PrayerType:         "personal",
		NotesEditableUntil: createdAt.Add(24 * time.Hour),
		CreatedAt:          createdAt,
	}

	newNotes := "Too late to edit"
	req := &prayer.UpdatePrayerSessionRequest{
		Notes: &newNotes,
	}

	err := prayer.ValidateUpdateSession(req, existing, now)
	if err != prayer.ErrNotesReadOnly {
		t.Errorf("expected ErrNotesReadOnly, got %v", err)
	}
}

// TestPrayerTypeMapping_PRDToAPI_AllTypesRepresented verifies the enum has exactly 6 types.
func TestPrayerTypeMapping_PRDToAPI_AllTypesRepresented(t *testing.T) {
	expected := []string{"personal", "guided", "group", "scriptureBased", "intercessory", "listening"}

	if len(prayer.ValidPrayerTypes) != len(expected) {
		t.Errorf("expected %d prayer types, got %d", len(expected), len(prayer.ValidPrayerTypes))
	}

	for _, pt := range expected {
		if !prayer.ValidPrayerTypes[pt] {
			t.Errorf("expected prayer type %q to be valid", pt)
		}
	}
}

// TestPrayerTypeMapping_QuickLog_DefaultsToPersonal verifies quick log defaults.
//
// Acceptance Criterion (PR-AC1.11): Quick log defaults to prayerType=personal.
func TestPrayerTypeMapping_QuickLog_DefaultsToPersonal(t *testing.T) {
	now := time.Now().UTC()
	req := prayer.DefaultQuickLogRequest(now)

	if req.PrayerType != "personal" {
		t.Errorf("expected quick log prayerType to be 'personal', got %q", req.PrayerType)
	}
	if !req.Timestamp.Equal(now) {
		t.Error("expected quick log timestamp to be now")
	}
	if req.DurationMinutes != nil {
		t.Error("expected quick log duration to be nil")
	}
	if req.Notes != nil {
		t.Error("expected quick log notes to be nil")
	}
}

// TestPrayerSession_PR_AC1_1_ManualEntry verifies creating a session with required fields.
//
// Acceptance Criterion (PR-AC1.1): Valid prayerType and timestamp create a session.
func TestPrayerSession_PR_AC1_1_ManualEntry(t *testing.T) {
	now := time.Now().UTC()
	req := &prayer.CreatePrayerSessionRequest{
		Timestamp:       now,
		PrayerType:      "personal",
		DurationMinutes: intPtr(15),
		MoodBefore:      intPtr(3),
		MoodAfter:       intPtr(4),
	}

	err := prayer.ValidateCreateSession(req, now)
	if err != nil {
		t.Fatalf("expected valid request, got error: %v", err)
	}

	session := prayer.NewPrayerSession("ps_abc123", "user_1", req, now)
	if session.PrayerID != "ps_abc123" {
		t.Errorf("expected prayerID 'ps_abc123', got %q", session.PrayerID)
	}
	if session.PrayerType != "personal" {
		t.Errorf("expected prayerType 'personal', got %q", session.PrayerType)
	}
	if session.CreatedAt.IsZero() {
		t.Error("expected createdAt to be set")
	}
	if session.NotesEditableUntil.IsZero() {
		t.Error("expected notesEditableUntil to be set")
	}
}
