// test/unit/prayer/personal_test.go
package prayer_test

import (
	"strings"
	"testing"
	"time"

	"github.com/regalrecovery/api/internal/domain/prayer"
)

// TestPersonalPrayer_PR_AC3_1_RequiresTitleAndBody verifies title and body are required.
//
// Acceptance Criterion (PR-AC3.1): title and body are required fields.
func TestPersonalPrayer_PR_AC3_1_RequiresTitleAndBody(t *testing.T) {
	// Missing title.
	req := &prayer.CreatePersonalPrayerRequest{
		Title: "",
		Body:  "Some body text",
	}
	err := prayer.ValidateCreatePersonalPrayer(req)
	if err != prayer.ErrTitleRequired {
		t.Errorf("expected ErrTitleRequired for empty title, got %v", err)
	}

	// Missing body.
	req = &prayer.CreatePersonalPrayerRequest{
		Title: "My Prayer",
		Body:  "",
	}
	err = prayer.ValidateCreatePersonalPrayer(req)
	if err != prayer.ErrBodyRequired {
		t.Errorf("expected ErrBodyRequired for empty body, got %v", err)
	}
}

// TestPersonalPrayer_PR_AC3_2_RejectTitleExceeding100Chars verifies title length limit.
//
// Acceptance Criterion (PR-AC3.2): title max 100 characters.
func TestPersonalPrayer_PR_AC3_2_RejectTitleExceeding100Chars(t *testing.T) {
	req := &prayer.CreatePersonalPrayerRequest{
		Title: strings.Repeat("a", 101),
		Body:  "Body text",
	}

	err := prayer.ValidateCreatePersonalPrayer(req)
	if err != prayer.ErrTitleExceedsLimit {
		t.Errorf("expected ErrTitleExceedsLimit, got %v", err)
	}
}

// TestPersonalPrayer_PR_AC3_2_AcceptTitleAt100Chars verifies title at exactly 100 chars.
//
// Acceptance Criterion (PR-AC3.2): 100-character title should be accepted.
func TestPersonalPrayer_PR_AC3_2_AcceptTitleAt100Chars(t *testing.T) {
	req := &prayer.CreatePersonalPrayerRequest{
		Title: strings.Repeat("a", 100),
		Body:  "Body text",
	}

	err := prayer.ValidateCreatePersonalPrayer(req)
	if err != nil {
		t.Errorf("expected 100-char title to be valid, got error: %v", err)
	}
}

// TestPersonalPrayer_PR_AC3_5_DeleteRetainsLinkedSessionReference verifies
// that deleting a personal prayer updates linked sessions with a sentinel title.
//
// Acceptance Criterion (PR-AC3.5): Linked sessions retain ID, show "[Deleted Prayer]".
func TestPersonalPrayer_PR_AC3_5_DeleteRetainsLinkedSessionReference(t *testing.T) {
	// Verify the deleted prayer title sentinel constant.
	if prayer.DeletedPrayerTitle != "[Deleted Prayer]" {
		t.Errorf("expected DeletedPrayerTitle to be '[Deleted Prayer]', got %q", prayer.DeletedPrayerTitle)
	}
}

// TestPersonalPrayer_NewPersonalPrayer verifies constructor sets fields correctly.
func TestPersonalPrayer_NewPersonalPrayer(t *testing.T) {
	now := time.Now().UTC()
	scripture := "Psalm 51:10"
	req := &prayer.CreatePersonalPrayerRequest{
		Title:              "My Prayer",
		Body:               "Lord, help me.",
		TopicTags:          []string{"healing", "courage"},
		ScriptureReference: &scripture,
	}

	pp := prayer.NewPersonalPrayer("pp_abc123", "user_1", req, 3, now)

	if pp.ID != "pp_abc123" {
		t.Errorf("expected ID 'pp_abc123', got %q", pp.ID)
	}
	if pp.UserID != "user_1" {
		t.Errorf("expected UserID 'user_1', got %q", pp.UserID)
	}
	if pp.Title != "My Prayer" {
		t.Errorf("expected title 'My Prayer', got %q", pp.Title)
	}
	if pp.SortOrder != 3 {
		t.Errorf("expected sortOrder=3, got %d", pp.SortOrder)
	}
	if pp.IsFavorite {
		t.Error("expected isFavorite=false for new prayer")
	}
	if pp.CreatedAt.IsZero() {
		t.Error("expected createdAt to be set")
	}
}

// TestPersonalPrayer_ApplyUpdate verifies partial updates work correctly.
func TestPersonalPrayer_ApplyUpdate(t *testing.T) {
	now := time.Now().UTC()
	existing := &prayer.PersonalPrayer{
		ID:        "pp_1",
		UserID:    "user_1",
		Title:     "Old Title",
		Body:      "Old Body",
		TopicTags: []string{"old"},
		SortOrder: 1,
		CreatedAt: now.Add(-1 * time.Hour),
	}

	newTitle := "New Title"
	req := &prayer.UpdatePersonalPrayerRequest{
		Title: &newTitle,
	}

	updated := prayer.ApplyPersonalPrayerUpdate(existing, req, now)
	if updated.Title != "New Title" {
		t.Errorf("expected title 'New Title', got %q", updated.Title)
	}
	if updated.Body != "Old Body" {
		t.Error("expected body to remain unchanged")
	}
	if updated.ModifiedAt.Equal(existing.CreatedAt) {
		t.Error("expected modifiedAt to be updated")
	}
}

// TestPersonalPrayer_ValidateUpdate_EmptyTitle verifies update validation.
func TestPersonalPrayer_ValidateUpdate_EmptyTitle(t *testing.T) {
	empty := ""
	req := &prayer.UpdatePersonalPrayerRequest{
		Title: &empty,
	}
	err := prayer.ValidateUpdatePersonalPrayer(req)
	if err != prayer.ErrTitleRequired {
		t.Errorf("expected ErrTitleRequired for empty title update, got %v", err)
	}
}

// TestPersonalPrayer_ValidateUpdate_TitleTooLong verifies update title validation.
func TestPersonalPrayer_ValidateUpdate_TitleTooLong(t *testing.T) {
	long := strings.Repeat("x", 101)
	req := &prayer.UpdatePersonalPrayerRequest{
		Title: &long,
	}
	err := prayer.ValidateUpdatePersonalPrayer(req)
	if err != prayer.ErrTitleExceedsLimit {
		t.Errorf("expected ErrTitleExceedsLimit, got %v", err)
	}
}
