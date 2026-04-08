// internal/domain/mood/entry_test.go
package mood

import (
	"testing"
	"time"
)

func TestMood_AC001_CreateMoodEntry_RatingOnly(t *testing.T) {
	// Given: valid rating (1-5) and timestamp
	req := CreateMoodEntryRequest{
		Timestamp: time.Now().UTC(),
		Rating:    4,
	}

	// When: NewMoodEntry is called
	entry, err := NewMoodEntry("u_alex", "DEFAULT", req)

	// Then: entry created with auto-generated moodId, rating saved, createdAt set
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if entry.MoodID == "" {
		t.Error("expected auto-generated moodId")
	}
	if entry.Rating != 4 {
		t.Errorf("expected rating 4, got %d", entry.Rating)
	}
	if entry.CreatedAt.IsZero() {
		t.Error("expected createdAt to be set")
	}
	if entry.RatingLabel != "Good" {
		t.Errorf("expected ratingLabel Good, got %s", entry.RatingLabel)
	}
	if entry.Source != "direct" {
		t.Errorf("expected default source 'direct', got %s", entry.Source)
	}
}

func TestMood_AC001_CreateMoodEntry_InvalidRating_Zero(t *testing.T) {
	// Given: rating = 0
	req := CreateMoodEntryRequest{
		Timestamp: time.Now().UTC(),
		Rating:    0,
	}

	// When: NewMoodEntry is called
	_, err := NewMoodEntry("u_alex", "DEFAULT", req)

	// Then: validation error returned
	if err == nil {
		t.Fatal("expected error for rating 0")
	}
}

func TestMood_AC001_CreateMoodEntry_InvalidRating_Six(t *testing.T) {
	// Given: rating = 6
	req := CreateMoodEntryRequest{
		Timestamp: time.Now().UTC(),
		Rating:    6,
	}

	// When: NewMoodEntry is called
	_, err := NewMoodEntry("u_alex", "DEFAULT", req)

	// Then: validation error returned
	if err == nil {
		t.Fatal("expected error for rating 6")
	}
}

func TestMood_AC002_CreateMoodEntry_WithContextNote(t *testing.T) {
	// Given: rating = 4 and contextNote = "Feeling good after prayer"
	req := CreateMoodEntryRequest{
		Timestamp:   time.Now().UTC(),
		Rating:      4,
		ContextNote: "Feeling good after prayer",
	}

	// When: NewMoodEntry is called
	entry, err := NewMoodEntry("u_alex", "DEFAULT", req)

	// Then: entry created with contextNote saved
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if entry.ContextNote != "Feeling good after prayer" {
		t.Errorf("expected context note 'Feeling good after prayer', got '%s'", entry.ContextNote)
	}
}

func TestMood_AC007_CreateMoodEntry_ContextNoteTooLong(t *testing.T) {
	// Given: contextNote with 201 characters
	note := make([]rune, 201)
	for i := range note {
		note[i] = 'a'
	}
	req := CreateMoodEntryRequest{
		Timestamp:   time.Now().UTC(),
		Rating:      3,
		ContextNote: string(note),
	}

	// When: NewMoodEntry is called
	_, err := NewMoodEntry("u_alex", "DEFAULT", req)

	// Then: validation error returned
	if err == nil {
		t.Fatal("expected error for context note > 200 chars")
	}
}

func TestMood_AC003_CreateMoodEntry_WithEmotionLabels(t *testing.T) {
	// Given: rating = 3, emotionLabels = ["Anxious", "Lonely"]
	req := CreateMoodEntryRequest{
		Timestamp:     time.Now().UTC(),
		Rating:        3,
		EmotionLabels: []string{"Anxious", "Lonely"},
	}

	// When: NewMoodEntry is called
	entry, err := NewMoodEntry("u_alex", "DEFAULT", req)

	// Then: entry created with both emotion labels saved
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if len(entry.EmotionLabels) != 2 {
		t.Errorf("expected 2 emotion labels, got %d", len(entry.EmotionLabels))
	}
}

func TestMood_AC003_CreateMoodEntry_InvalidEmotionLabel(t *testing.T) {
	// Given: emotionLabels = ["Happy"] (not in predefined list)
	req := CreateMoodEntryRequest{
		Timestamp:     time.Now().UTC(),
		Rating:        3,
		EmotionLabels: []string{"Happy"},
	}

	// When: NewMoodEntry is called
	_, err := NewMoodEntry("u_alex", "DEFAULT", req)

	// Then: validation error returned
	if err == nil {
		t.Fatal("expected error for invalid emotion label 'Happy'")
	}
}

func TestMood_AC003_CreateMoodEntry_EmptyEmotionLabels(t *testing.T) {
	// Given: emotionLabels = []
	req := CreateMoodEntryRequest{
		Timestamp:     time.Now().UTC(),
		Rating:        3,
		EmotionLabels: []string{},
	}

	// When: NewMoodEntry is called
	entry, err := NewMoodEntry("u_alex", "DEFAULT", req)

	// Then: entry created successfully with empty emotion labels array
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if entry.EmotionLabels == nil {
		t.Error("expected non-nil empty emotion labels array")
	}
}

func TestMood_AC028_CrisisEntry_SetsCrisisPromptedTrue(t *testing.T) {
	// Given: rating = 1 (Crisis)
	req := CreateMoodEntryRequest{
		Timestamp: time.Now().UTC(),
		Rating:    1,
	}

	// When: NewMoodEntry is called
	entry, err := NewMoodEntry("u_alex", "DEFAULT", req)

	// Then: response includes crisisPrompted = true
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if !entry.CrisisPrompted {
		t.Error("expected crisisPrompted = true for rating 1")
	}
}

func TestMood_AC028_NonCrisisEntry_SetsCrisisPromptedFalse(t *testing.T) {
	// Given: rating = 3 (Okay)
	req := CreateMoodEntryRequest{
		Timestamp: time.Now().UTC(),
		Rating:    3,
	}

	// When: NewMoodEntry is called
	entry, err := NewMoodEntry("u_alex", "DEFAULT", req)

	// Then: response includes crisisPrompted = false
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if entry.CrisisPrompted {
		t.Error("expected crisisPrompted = false for rating 3")
	}
}

func TestMood_FR001_RatingScale_MapsCorrectLabel(t *testing.T) {
	// Given: each rating 1-5
	// When: label is computed
	// Then: correct mapping
	tests := []struct {
		rating int
		label  string
	}{
		{1, "Crisis"},
		{2, "Struggling"},
		{3, "Okay"},
		{4, "Good"},
		{5, "Great"},
	}

	for _, tt := range tests {
		label := LabelForRating(tt.rating)
		if label != tt.label {
			t.Errorf("rating %d: expected label '%s', got '%s'", tt.rating, tt.label, label)
		}
	}
}

func TestMood_AC032_UpdateEntry_WithinWindow(t *testing.T) {
	// Given: entry created 1 hour ago
	now := time.Now().UTC()
	entry := &MoodEntry{
		MoodID:    "mood_test123",
		Rating:    4,
		CreatedAt: now.Add(-1 * time.Hour),
	}

	newRating := 3
	req := UpdateMoodEntryRequest{Rating: &newRating}

	// When: ApplyUpdate is called
	err := entry.ApplyUpdate(req, now)

	// Then: rating updated, modifiedAt changed, createdAt unchanged
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if entry.Rating != 3 {
		t.Errorf("expected rating 3, got %d", entry.Rating)
	}
	if entry.ModifiedAt != now {
		t.Error("expected modifiedAt to be updated")
	}
}

func TestMood_AC034_UpdateEntry_OutsideWindow(t *testing.T) {
	// Given: entry created 25 hours ago
	now := time.Now().UTC()
	entry := &MoodEntry{
		MoodID:    "mood_test123",
		Rating:    4,
		CreatedAt: now.Add(-25 * time.Hour),
	}

	newRating := 3
	req := UpdateMoodEntryRequest{Rating: &newRating}

	// When: ApplyUpdate is called
	err := entry.ApplyUpdate(req, now)

	// Then: error returned
	if err == nil {
		t.Fatal("expected ErrEntryLocked for entry older than 24 hours")
	}
	if err != ErrEntryLocked {
		t.Errorf("expected ErrEntryLocked, got: %v", err)
	}
}

func TestMood_AC032_UpdateEntry_TimestampImmutable(t *testing.T) {
	// Given: entry created 1 hour ago
	now := time.Now().UTC()
	originalCreatedAt := now.Add(-1 * time.Hour)
	entry := &MoodEntry{
		MoodID:    "mood_test123",
		Rating:    4,
		CreatedAt: originalCreatedAt,
		Timestamp: originalCreatedAt,
	}

	newRating := 3
	req := UpdateMoodEntryRequest{Rating: &newRating}

	// When: ApplyUpdate is called
	err := entry.ApplyUpdate(req, now)

	// Then: createdAt and timestamp remain unchanged
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if !entry.CreatedAt.Equal(originalCreatedAt) {
		t.Error("expected createdAt to remain unchanged")
	}
	if !entry.Timestamp.Equal(originalCreatedAt) {
		t.Error("expected timestamp to remain unchanged")
	}
}

func TestMood_NFR001_UpdateEntry_CreatedAtNeverChanges(t *testing.T) {
	// Given: entry created 1 hour ago
	now := time.Now().UTC()
	originalCreatedAt := now.Add(-1 * time.Hour)
	entry := &MoodEntry{
		MoodID:    "mood_test123",
		Rating:    4,
		CreatedAt: originalCreatedAt,
	}

	newRating := 5
	req := UpdateMoodEntryRequest{Rating: &newRating}

	// When: ApplyUpdate is called
	err := entry.ApplyUpdate(req, now)

	// Then: createdAt remains exactly the original value
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if !entry.CreatedAt.Equal(originalCreatedAt) {
		t.Errorf("expected createdAt to be %v, got %v", originalCreatedAt, entry.CreatedAt)
	}
}

func TestMood_AC033_DeleteEntry_WithinWindow(t *testing.T) {
	// Given: entry created 30 minutes ago
	now := time.Now().UTC()
	entry := &MoodEntry{
		MoodID:    "mood_test123",
		CreatedAt: now.Add(-30 * time.Minute),
	}

	// When: CanDelete is called
	err := entry.CanDelete(now)

	// Then: no error (deletion allowed)
	if err != nil {
		t.Fatalf("expected no error for delete within 24 hours, got: %v", err)
	}
}

func TestMood_AC035_DeleteEntry_OutsideWindow(t *testing.T) {
	// Given: entry created 25 hours ago
	now := time.Now().UTC()
	entry := &MoodEntry{
		MoodID:    "mood_test123",
		CreatedAt: now.Add(-25 * time.Hour),
	}

	// When: CanDelete is called
	err := entry.CanDelete(now)

	// Then: error returned
	if err == nil {
		t.Fatal("expected ErrEntryPermanent for entry older than 24 hours")
	}
	if err != ErrEntryPermanent {
		t.Errorf("expected ErrEntryPermanent, got: %v", err)
	}
}

func TestMood_AC006_MultipleEntriesSavedIndependently(t *testing.T) {
	// Given: two mood entries created for the same user
	req1 := CreateMoodEntryRequest{
		Timestamp: time.Now().UTC(),
		Rating:    4,
	}
	req2 := CreateMoodEntryRequest{
		Timestamp: time.Now().UTC().Add(2 * time.Hour),
		Rating:    2,
	}

	// When: NewMoodEntry is called for each
	entry1, err1 := NewMoodEntry("u_alex", "DEFAULT", req1)
	entry2, err2 := NewMoodEntry("u_alex", "DEFAULT", req2)

	// Then: both entries are independent with different IDs
	if err1 != nil || err2 != nil {
		t.Fatalf("expected no errors, got: %v, %v", err1, err2)
	}
	if entry1.MoodID == entry2.MoodID {
		t.Error("expected different moodIds for independent entries")
	}
}

func TestMood_SourceValidation(t *testing.T) {
	// Valid sources
	validSources := []string{"direct", "widget", "post-activity", "notification"}
	for _, src := range validSources {
		req := CreateMoodEntryRequest{
			Timestamp: time.Now().UTC(),
			Rating:    3,
			Source:    src,
		}
		_, err := NewMoodEntry("u_alex", "DEFAULT", req)
		if err != nil {
			t.Errorf("expected source '%s' to be valid, got error: %v", src, err)
		}
	}

	// Invalid source
	req := CreateMoodEntryRequest{
		Timestamp: time.Now().UTC(),
		Rating:    3,
		Source:    "invalid-source",
	}
	_, err := NewMoodEntry("u_alex", "DEFAULT", req)
	if err == nil {
		t.Error("expected error for invalid source")
	}
}
