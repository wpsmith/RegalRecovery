// internal/domain/mood/summary_test.go
package mood

import (
	"testing"
	"time"
)

func TestMood_AC008_TodaySummary_CalculatesAverage(t *testing.T) {
	// Given: 3 entries today with ratings 3, 4, 5
	entries := []MoodEntry{
		{Rating: 3, Timestamp: time.Now().UTC()},
		{Rating: 4, Timestamp: time.Now().UTC()},
		{Rating: 5, Timestamp: time.Now().UTC()},
	}

	// When: ComputeTodaySummary is called
	summary := ComputeTodaySummary(entries)

	// Then: averageRating = 4.0, highestRating = 5, lowestRating = 3, entryCount = 3
	if summary == nil {
		t.Fatal("expected non-nil summary")
	}
	if summary.AverageRating != 4.0 {
		t.Errorf("expected averageRating 4.0, got %f", summary.AverageRating)
	}
	if summary.HighestRating != 5 {
		t.Errorf("expected highestRating 5, got %d", summary.HighestRating)
	}
	if summary.LowestRating != 3 {
		t.Errorf("expected lowestRating 3, got %d", summary.LowestRating)
	}
	if summary.EntryCount != 3 {
		t.Errorf("expected entryCount 3, got %d", summary.EntryCount)
	}
}

func TestMood_AC008_TodaySummary_NoEntries(t *testing.T) {
	// Given: no entries today
	entries := []MoodEntry{}

	// When: ComputeTodaySummary is called
	summary := ComputeTodaySummary(entries)

	// Then: nil summary
	if summary != nil {
		t.Error("expected nil summary for no entries")
	}
}

func TestMood_AC012_DailySummary_ColorCode_Green(t *testing.T) {
	// Given: daily average = 4.5
	entries := []MoodEntry{
		{Rating: 4}, {Rating: 5},
	}
	summary := ComputeDailySummary("2026-04-07", entries)

	// Then: colorCode = "green"
	if summary.ColorCode != "green" {
		t.Errorf("expected colorCode 'green' for avg 4.5, got '%s'", summary.ColorCode)
	}
}

func TestMood_AC012_DailySummary_ColorCode_Yellow(t *testing.T) {
	// Given: daily average = 3.0
	entries := []MoodEntry{
		{Rating: 3},
	}
	summary := ComputeDailySummary("2026-04-07", entries)

	// Then: colorCode = "yellow"
	if summary.ColorCode != "yellow" {
		t.Errorf("expected colorCode 'yellow' for avg 3.0, got '%s'", summary.ColorCode)
	}
}

func TestMood_AC012_DailySummary_ColorCode_Orange(t *testing.T) {
	// Given: daily average = 2.5
	entries := []MoodEntry{
		{Rating: 2}, {Rating: 3},
	}
	summary := ComputeDailySummary("2026-04-07", entries)

	// Then: colorCode = "orange"
	if summary.ColorCode != "orange" {
		t.Errorf("expected colorCode 'orange' for avg 2.5, got '%s'", summary.ColorCode)
	}
}

func TestMood_AC012_DailySummary_ColorCode_Red(t *testing.T) {
	// Given: daily average = 1.5
	entries := []MoodEntry{
		{Rating: 1}, {Rating: 2},
	}
	summary := ComputeDailySummary("2026-04-07", entries)

	// Then: colorCode = "red"
	if summary.ColorCode != "red" {
		t.Errorf("expected colorCode 'red' for avg 1.5, got '%s'", summary.ColorCode)
	}
}

func TestMood_AC012_DailySummary_ColorCode_Gray(t *testing.T) {
	// Given: no entries for this day
	entries := []MoodEntry{}
	summary := ComputeDailySummary("2026-04-07", entries)

	// Then: colorCode = "gray"
	if summary.ColorCode != "gray" {
		t.Errorf("expected colorCode 'gray' for no entries, got '%s'", summary.ColorCode)
	}
}

func TestMood_DailySummary_ColorCode_BoundaryExactly4(t *testing.T) {
	// Given: daily average = 4.0 exactly
	entries := []MoodEntry{
		{Rating: 4},
	}
	summary := ComputeDailySummary("2026-04-07", entries)

	// Then: colorCode = "green" (4.0-5.0 is green)
	if summary.ColorCode != "green" {
		t.Errorf("expected colorCode 'green' for avg 4.0, got '%s'", summary.ColorCode)
	}
}

func TestMood_DailySummary_ColorCode_BoundaryExactly3(t *testing.T) {
	// Given: daily average = 3.0 exactly
	entries := []MoodEntry{
		{Rating: 3},
	}
	summary := ComputeDailySummary("2026-04-07", entries)

	// Then: colorCode = "yellow" (3.0-3.9 is yellow)
	if summary.ColorCode != "yellow" {
		t.Errorf("expected colorCode 'yellow' for avg 3.0, got '%s'", summary.ColorCode)
	}
}

func TestMood_DailySummary_ColorCode_BoundaryExactly2(t *testing.T) {
	// Given: daily average = 2.0 exactly
	entries := []MoodEntry{
		{Rating: 2},
	}
	summary := ComputeDailySummary("2026-04-07", entries)

	// Then: colorCode = "orange" (2.0-2.9 is orange)
	if summary.ColorCode != "orange" {
		t.Errorf("expected colorCode 'orange' for avg 2.0, got '%s'", summary.ColorCode)
	}
}

func TestMood_DailySummary_ColorCode_BoundaryExactly1(t *testing.T) {
	// Given: daily average = 1.0 exactly
	entries := []MoodEntry{
		{Rating: 1},
	}
	summary := ComputeDailySummary("2026-04-07", entries)

	// Then: colorCode = "red" (1.0-1.9 is red)
	if summary.ColorCode != "red" {
		t.Errorf("expected colorCode 'red' for avg 1.0, got '%s'", summary.ColorCode)
	}
}

func TestMood_EC003_HighVolumeEntries_UseDailyAverage(t *testing.T) {
	// Given: 20+ entries in a single day
	entries := make([]MoodEntry, 25)
	for i := range entries {
		entries[i] = MoodEntry{Rating: 3}
	}

	// When: daily summary is computed
	summary := ComputeDailySummary("2026-04-07", entries)

	// Then: all entries are used; no cap imposed
	if summary.EntryCount != 25 {
		t.Errorf("expected entryCount 25, got %d", summary.EntryCount)
	}
	if summary.AverageRating != 3.0 {
		t.Errorf("expected averageRating 3.0, got %f", summary.AverageRating)
	}
}
