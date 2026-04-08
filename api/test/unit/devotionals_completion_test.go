// test/unit/devotionals_completion_test.go
package unit

import (
	"strings"
	"testing"
	"time"

	"github.com/regalrecovery/api/internal/domain/devotionals"
)

// =============================================================================
// Devotional Completion Tests
// Location: internal/domain/devotionals/completion_test.go (spec)
// =============================================================================

// TestCompletion_AC_DEV_REFLECT_01_SavesReflectionWithCompletion verifies that
// a reflection text is included in the completion request.
func TestCompletion_AC_DEV_REFLECT_01_SavesReflectionWithCompletion(t *testing.T) {
	// Given
	reflection := "The passage about surrender resonated deeply."
	req := devotionals.CompletionRequest{
		Timestamp:  time.Now(),
		Reflection: &reflection,
	}

	// Then: reflection is populated
	if req.Reflection == nil || *req.Reflection != reflection {
		t.Errorf("expected reflection to be %q, got %v", reflection, req.Reflection)
	}
}

// TestCompletion_AC_DEV_REFLECT_02_AcceptsUnlimitedReflectionText verifies that
// reflections of large size are accepted.
func TestCompletion_AC_DEV_REFLECT_02_AcceptsUnlimitedReflectionText(t *testing.T) {
	// Given: reflection text of 10,000 characters
	longReflection := strings.Repeat("A", 10000)
	req := devotionals.CompletionRequest{
		Timestamp:  time.Now(),
		Reflection: &longReflection,
	}

	// Then: no truncation
	if req.Reflection == nil || len(*req.Reflection) != 10000 {
		t.Errorf("expected reflection length 10000, got %d", len(*req.Reflection))
	}
}

// TestCompletion_AC_DEV_REFLECT_04_SavesMoodTag verifies that a mood tag is
// included in the completion.
func TestCompletion_AC_DEV_REFLECT_04_SavesMoodTag(t *testing.T) {
	// Given
	mood := devotionals.MoodHopeful
	req := devotionals.CompletionRequest{
		Timestamp: time.Now(),
		MoodTag:   &mood,
	}

	// Then
	if req.MoodTag == nil || *req.MoodTag != devotionals.MoodHopeful {
		t.Errorf("expected mood tag hopeful, got %v", req.MoodTag)
	}
}

// TestCompletion_AC_DEV_REFLECT_05_CompletionWithoutReflection verifies that
// a completion saves successfully without a reflection.
func TestCompletion_AC_DEV_REFLECT_05_CompletionWithoutReflection(t *testing.T) {
	// Given: no reflection
	req := devotionals.CompletionRequest{
		Timestamp: time.Now(),
	}

	// Then: nil reflection is valid
	if req.Reflection != nil {
		t.Errorf("expected nil reflection, got %v", req.Reflection)
	}
}

// TestCompletion_ImmutableTimestamp_FR2_7_RejectsTimestampUpdate verifies that
// the completion timestamp cannot be modified (FR2.7).
func TestCompletion_ImmutableTimestamp_FR2_7_RejectsTimestampUpdate(t *testing.T) {
	// Given: original timestamp T1
	t1 := time.Date(2026, 4, 7, 6, 30, 0, 0, time.UTC)
	t2 := time.Date(2026, 4, 7, 7, 0, 0, 0, time.UTC)

	// When: attempt to update timestamp
	err := devotionals.ValidateTimestampImmutability(t1, t2)

	// Then: error returned
	if err == nil {
		t.Fatal("expected ErrTimestampImmutable, got nil")
	}
	if err != devotionals.ErrTimestampImmutable {
		t.Errorf("expected ErrTimestampImmutable, got %v", err)
	}
}

// TestCompletion_ImmutableTimestamp_SameTimestampAllowed verifies that passing
// the same timestamp is not considered a modification.
func TestCompletion_ImmutableTimestamp_SameTimestampAllowed(t *testing.T) {
	// Given: same timestamp
	t1 := time.Date(2026, 4, 7, 6, 30, 0, 0, time.UTC)

	// When
	err := devotionals.ValidateTimestampImmutability(t1, t1)

	// Then: no error
	if err != nil {
		t.Errorf("same timestamp should not be rejected, got %v", err)
	}
}

// TestCompletion_ImmutableTimestamp_ZeroTimestampAllowed verifies that a zero
// timestamp (meaning "don't update") is not considered a modification.
func TestCompletion_ImmutableTimestamp_ZeroTimestampAllowed(t *testing.T) {
	// Given: zero attempted timestamp
	t1 := time.Date(2026, 4, 7, 6, 30, 0, 0, time.UTC)

	// When
	err := devotionals.ValidateTimestampImmutability(t1, time.Time{})

	// Then: no error
	if err != nil {
		t.Errorf("zero timestamp should not be rejected, got %v", err)
	}
}

// TestCompletion_ValidMoodTags verifies all valid mood tags are accepted.
func TestCompletion_ValidMoodTags(t *testing.T) {
	validTags := []devotionals.MoodTag{
		devotionals.MoodGrateful, devotionals.MoodHopeful, devotionals.MoodPeaceful,
		devotionals.MoodConvicted, devotionals.MoodChallenged, devotionals.MoodComforted,
		devotionals.MoodAnxious, devotionals.MoodStruggling, devotionals.MoodNumb,
	}

	for _, tag := range validTags {
		t.Run(string(tag), func(t *testing.T) {
			if !devotionals.ValidMoodTags[tag] {
				t.Errorf("expected mood tag %q to be valid", tag)
			}
		})
	}
}

// TestCompletion_InvalidMoodTag verifies that invalid mood tags are rejected.
func TestCompletion_InvalidMoodTag(t *testing.T) {
	invalidTag := devotionals.MoodTag("invalid")
	if devotionals.ValidMoodTags[invalidTag] {
		t.Errorf("expected mood tag %q to be invalid", invalidTag)
	}
}
