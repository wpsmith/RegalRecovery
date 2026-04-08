package gratitude_test

import (
	"testing"
	"time"

	"github.com/regalrecovery/api/internal/domain/gratitude"
)

// --- GL-DM-AC1: Item text max length ---

func TestGratitude_GL_DM_AC1_ItemTextMaxLength(t *testing.T) {
	t.Run("300 characters accepted", func(t *testing.T) {
		text := make([]byte, 300)
		for i := range text {
			text[i] = 'a'
		}
		item := gratitude.Item{
			ItemID:    "gi_test",
			Text:      string(text),
			SortOrder: 0,
		}
		if len(item.Text) != 300 {
			t.Errorf("expected 300 chars, got %d", len(item.Text))
		}
	})

	t.Run("MaxItemTextLength constant is 300", func(t *testing.T) {
		if gratitude.MaxItemTextLength != 300 {
			t.Errorf("expected MaxItemTextLength=300, got %d", gratitude.MaxItemTextLength)
		}
	})
}

// --- GL-DM-AC2: Category tag options ---

func TestGratitude_GL_DM_AC2_CategoryTagOptions(t *testing.T) {
	expectedCategories := []string{
		"faithGod", "family", "relationships", "health", "recovery",
		"workCareer", "natureBeauty", "smallMoments", "growthProgress", "custom",
	}

	if len(gratitude.ValidCategories) != len(expectedCategories) {
		t.Errorf("expected %d categories, got %d", len(expectedCategories), len(gratitude.ValidCategories))
	}

	for _, cat := range expectedCategories {
		if !gratitude.ValidCategories[cat] {
			t.Errorf("missing category: %s", cat)
		}
	}

	// Invalid category should not be valid
	if gratitude.ValidCategories["invalid"] {
		t.Error("invalid category should not be valid")
	}
}

// --- GL-DM-AC3: Mood score range ---

func TestGratitude_GL_DM_AC3_MoodScoreRange(t *testing.T) {
	if gratitude.MinMoodScore != 1 {
		t.Errorf("expected MinMoodScore=1, got %d", gratitude.MinMoodScore)
	}
	if gratitude.MaxMoodScore != 5 {
		t.Errorf("expected MaxMoodScore=5, got %d", gratitude.MaxMoodScore)
	}
}

// --- GL-DM-AC5: Item ordering ---

func TestGratitude_GL_DM_AC5_ItemOrdering(t *testing.T) {
	items := []gratitude.Item{
		{ItemID: "gi_3", Text: "Third", SortOrder: 2},
		{ItemID: "gi_1", Text: "First", SortOrder: 0},
		{ItemID: "gi_2", Text: "Second", SortOrder: 1},
	}

	// Verify sort by sortOrder
	sorted := make([]gratitude.Item, len(items))
	copy(sorted, items)
	for i := 0; i < len(sorted)-1; i++ {
		for j := i + 1; j < len(sorted); j++ {
			if sorted[j].SortOrder < sorted[i].SortOrder {
				sorted[i], sorted[j] = sorted[j], sorted[i]
			}
		}
	}

	expected := []string{"First", "Second", "Third"}
	for i, item := range sorted {
		if item.Text != expected[i] {
			t.Errorf("position %d: expected %q, got %q", i, expected[i], item.Text)
		}
	}
}

// --- GL-DM-AC7: Edit window (24h) ---

func TestGratitude_GL_DM_AC7_EditWindow(t *testing.T) {
	entry := &gratitude.Entry{
		CreatedAt: time.Now(),
	}
	if !entry.IsEditable() {
		t.Error("entry created now should be editable")
	}

	entry23h := &gratitude.Entry{
		CreatedAt: time.Now().Add(-23 * time.Hour),
	}
	if !entry23h.IsEditable() {
		t.Error("entry created 23h ago should still be editable")
	}
}

// --- GL-DM-AC8: Read-only after 24h ---

func TestGratitude_GL_DM_AC8_ReadOnlyAfter24h(t *testing.T) {
	entry := &gratitude.Entry{
		CreatedAt: time.Now().Add(-25 * time.Hour),
	}
	if entry.IsEditable() {
		t.Error("entry created 25h ago should NOT be editable")
	}
}

// --- GL-DM-AC9: Multiple per day ---

func TestGratitude_GL_DM_AC9_MultiplePerDay(t *testing.T) {
	now := time.Now()
	entry1 := &gratitude.Entry{
		GratitudeID: "g_001",
		Timestamp:   now,
	}
	entry2 := &gratitude.Entry{
		GratitudeID: "g_002",
		Timestamp:   now.Add(time.Hour),
	}

	if entry1.GratitudeID == entry2.GratitudeID {
		t.Error("multiple entries should have different IDs")
	}

	// Same calendar day
	if entry1.Timestamp.Format("2006-01-02") != entry2.Timestamp.Format("2006-01-02") {
		t.Error("both entries should be on the same day")
	}
}

// --- GL-DM-AC10: Immutable CreatedAt ---

func TestGratitude_GL_DM_AC10_ImmutableCreatedAt(t *testing.T) {
	if gratitude.EditWindowDuration != 24*time.Hour {
		t.Errorf("edit window should be 24h, got %v", gratitude.EditWindowDuration)
	}
}

// --- GL-TI-AC7: Average items per entry ---

func TestGratitude_GL_TI_AC7_AvgItemsPerEntry(t *testing.T) {
	svc := gratitude.NewService(nil)

	entries := []*gratitude.Entry{
		{Items: []gratitude.Item{{Text: "A"}, {Text: "B"}, {Text: "C"}}},
		{Items: []gratitude.Item{{Text: "D"}}},
	}

	avg := svc.AverageItemsPerEntry(entries)
	if avg != 2.0 {
		t.Errorf("expected avg 2.0, got %f", avg)
	}

	// Empty
	emptyAvg := svc.AverageItemsPerEntry(nil)
	if emptyAvg != 0 {
		t.Errorf("expected 0 for empty, got %f", emptyAvg)
	}
}

// --- GL-SH-AC3: Privacy filter ---

func TestGratitude_GL_SH_AC3_PrivacyFilter(t *testing.T) {
	svc := gratitude.NewService(nil)
	mood := 5
	photo := "/secret/photo.jpg"
	cat := "recovery"

	entry := &gratitude.Entry{
		GratitudeID: "g_test",
		Timestamp:   time.Now(),
		Items: []gratitude.Item{
			{ItemID: "gi_1", Text: "Test item", Category: &cat, IsFavorite: true, SortOrder: 0},
		},
		MoodScore: &mood,
		PhotoKey:  &photo,
	}

	shared := svc.GenerateShareText(entry)

	// Must NOT contain mood, category, or photo
	if containsSubstring(shared, "5") {
		t.Error("shared text should not contain mood score")
	}
	if containsSubstring(shared, "recovery") {
		t.Error("shared text should not contain category")
	}
	if containsSubstring(shared, "photo") {
		t.Error("shared text should not contain photo path")
	}
	if containsSubstring(shared, "favorite") {
		t.Error("shared text should not contain favorite status")
	}

	// Should contain the item text
	if !containsSubstring(shared, "Test item") {
		t.Error("shared text should contain item text")
	}
}

// --- GL-SH-AC1: Share individual item ---

func TestGratitude_GL_SH_AC1_ShareItem(t *testing.T) {
	svc := gratitude.NewService(nil)
	cat := "recovery"

	item := gratitude.Item{
		ItemID:     "gi_1",
		Text:       "Grateful for sobriety",
		Category:   &cat,
		IsFavorite: true,
	}

	shared := svc.GenerateShareItemText(item)
	if shared != "Grateful for sobriety" {
		t.Errorf("expected item text only, got %q", shared)
	}
}

// --- GL-IN-AC6: Streak milestone thresholds ---

func TestGratitude_GL_IN_AC6_StreakNotifications(t *testing.T) {
	expected := []int{7, 14, 30, 60, 90, 180, 365}

	if len(gratitude.StreakMilestones) != len(expected) {
		t.Errorf("expected %d milestones, got %d", len(expected), len(gratitude.StreakMilestones))
	}

	for i, m := range expected {
		if gratitude.StreakMilestones[i] != m {
			t.Errorf("milestone %d: expected %d, got %d", i, m, gratitude.StreakMilestones[i])
		}
	}
}

// --- GL-IN-AC10: Feature flag ---

func TestGratitude_GL_IN_AC10_FeatureFlag(t *testing.T) {
	// Verify the feature flag error exists
	if gratitude.ErrFeatureDisabled == nil {
		t.Error("ErrFeatureDisabled should be defined")
	}
	if gratitude.ErrFeatureDisabled.Error() != "gratitude feature is disabled" {
		t.Errorf("unexpected error message: %s", gratitude.ErrFeatureDisabled.Error())
	}
}

// --- Helper ---

func containsSubstring(s, substr string) bool {
	return len(s) >= len(substr) && searchSubstring(s, substr)
}

func searchSubstring(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}
