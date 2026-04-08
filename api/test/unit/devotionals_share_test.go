// test/unit/devotionals_share_test.go
package unit

import (
	"errors"
	"testing"

	"github.com/regalrecovery/api/internal/domain/devotionals"
)

// =============================================================================
// Devotional Sharing Tests
// Location: internal/domain/devotionals/share_test.go (spec)
// =============================================================================

// TestShare_AC_DEV_SHARE_01_ExcludesPersonalReflection verifies that shared
// content does not include the user's personal reflection.
func TestShare_AC_DEV_SHARE_01_ExcludesPersonalReflection(t *testing.T) {
	// Given: devotional content with all fields
	content := &devotionals.DevotionalContent{
		Title:              "Strength in Surrender",
		ScriptureReference: "2 Corinthians 12:9",
		ScriptureText: map[devotionals.BibleTranslation]string{
			devotionals.TranslationNIV: "My grace is sufficient for you",
		},
		Reading: map[devotionals.Language]string{
			devotionals.LangEN: "In our recovery journey...",
		},
		Prayer: map[devotionals.Language]string{
			devotionals.LangEN: "Lord, I confess...",
		},
	}

	// When: building shareable content
	shared := devotionals.BuildShareableContent(content, devotionals.LangEN, devotionals.TranslationNIV)

	// Then: shared content includes title, scripture, reading, prayer
	if shared["title"] != "Strength in Surrender" {
		t.Errorf("expected title in shared content, got %q", shared["title"])
	}
	if shared["scriptureReference"] != "2 Corinthians 12:9" {
		t.Errorf("expected scripture reference in shared content")
	}
	if shared["scriptureText"] != "My grace is sufficient for you" {
		t.Errorf("expected scripture text in shared content")
	}
	if shared["reading"] != "In our recovery journey..." {
		t.Errorf("expected reading in shared content")
	}
	if shared["prayer"] != "Lord, I confess..." {
		t.Errorf("expected prayer in shared content")
	}

	// And: no reflection key exists
	if _, exists := shared["reflection"]; exists {
		t.Error("shared content must NOT include user's personal reflection")
	}
}

// TestShare_ToContact_ValidatesContactExists verifies that sharing to a
// non-existent contact returns an error.
func TestShare_ToContact_ValidatesContactExists(t *testing.T) {
	// Given
	svc := devotionals.NewShareService(nil) // content repo not needed for this test
	contactID := "c_nonexistent"
	req := &devotionals.ShareRequest{
		ShareType: devotionals.ShareContact,
		ContactID: &contactID,
	}

	// When: contact does not exist
	_, err := svc.ShareDevotional("dev_x", req, func(id string) bool {
		return false // contact not found
	})

	// Then
	if !errors.Is(err, devotionals.ErrContactNotFound) {
		t.Errorf("expected ErrContactNotFound, got %v", err)
	}
}

// TestShare_ToContact_RequiresContactID verifies that contact sharing requires
// a contact ID.
func TestShare_ToContact_RequiresContactID(t *testing.T) {
	svc := devotionals.NewShareService(nil)
	req := &devotionals.ShareRequest{
		ShareType: devotionals.ShareContact,
		ContactID: nil,
	}

	_, err := svc.ShareDevotional("dev_x", req, func(id string) bool { return true })

	if !errors.Is(err, devotionals.ErrContactRequired) {
		t.Errorf("expected ErrContactRequired, got %v", err)
	}
}

// TestShare_GeneratesShareLink verifies that link sharing returns a URL.
func TestShare_GeneratesShareLink(t *testing.T) {
	// Given
	svc := devotionals.NewShareService(nil)
	req := &devotionals.ShareRequest{
		ShareType: devotionals.ShareLink,
	}

	// When
	resp, err := svc.ShareDevotional("dev_abc123", req, func(id string) bool { return true })

	// Then
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if resp.Data.ShareURL == nil {
		t.Fatal("expected shareUrl to be set for link sharing")
	}
	if *resp.Data.ShareURL != "https://app.regalrecovery.com/devotionals/dev_abc123" {
		t.Errorf("unexpected shareUrl: %s", *resp.Data.ShareURL)
	}
}

// TestShare_InvalidShareType verifies rejection of invalid share types.
func TestShare_InvalidShareType(t *testing.T) {
	svc := devotionals.NewShareService(nil)
	req := &devotionals.ShareRequest{
		ShareType: "invalid",
	}

	_, err := svc.ShareDevotional("dev_x", req, func(id string) bool { return true })

	if !errors.Is(err, devotionals.ErrInvalidShareType) {
		t.Errorf("expected ErrInvalidShareType, got %v", err)
	}
}
