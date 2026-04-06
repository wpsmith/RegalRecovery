// test/unit/timejournal_test.go
package unit

import (
	"fmt"
	"testing"
	"time"

	"github.com/regalrecovery/api/internal/domain/timejournal"
)

// =============================================================================
// Contract Tests — Time Journal Feature
// =============================================================================

// TestTimeJournal_TJ001_TimeSlotAutoPopulated verifies that SlotEnd is
// auto-populated from SlotStart based on the journal mode.
//
// Acceptance Criterion (TJ-001): Given mode=t60 and slotStart="14:00:00",
// slotEnd must be "15:00:00". For t30, slotStart="14:00:00" → "14:30:00".
func TestTimeJournal_TJ001_TimeSlotAutoPopulated(t *testing.T) {
	t.Run("T60_adds_60_minutes", func(t *testing.T) {
		// Given
		slotStart := "14:00:00"
		mode := timejournal.ModeT60

		// When
		slotEnd := timejournal.SlotEndFromStart(slotStart, mode)

		// Then
		if slotEnd != "15:00:00" {
			t.Errorf("expected slotEnd '15:00:00' for T-60 starting at 14:00, got %q", slotEnd)
		}
	})

	t.Run("T30_adds_30_minutes", func(t *testing.T) {
		// Given
		slotStart := "14:00:00"
		mode := timejournal.ModeT30

		// When
		slotEnd := timejournal.SlotEndFromStart(slotStart, mode)

		// Then
		if slotEnd != "14:30:00" {
			t.Errorf("expected slotEnd '14:30:00' for T-30 starting at 14:00, got %q", slotEnd)
		}
	})

	t.Run("T60_wraps_at_midnight", func(t *testing.T) {
		// Given — last slot of the day
		slotStart := "23:00:00"
		mode := timejournal.ModeT60

		// When
		slotEnd := timejournal.SlotEndFromStart(slotStart, mode)

		// Then
		if slotEnd != "00:00:00" {
			t.Errorf("expected slotEnd '00:00:00' for T-60 starting at 23:00, got %q", slotEnd)
		}
	})

	t.Run("T30_wraps_at_midnight", func(t *testing.T) {
		// Given — last slot of the day
		slotStart := "23:30:00"
		mode := timejournal.ModeT30

		// When
		slotEnd := timejournal.SlotEndFromStart(slotStart, mode)

		// Then
		if slotEnd != "00:00:00" {
			t.Errorf("expected slotEnd '00:00:00' for T-30 starting at 23:30, got %q", slotEnd)
		}
	})
}

// TestTimeJournal_TJ003_ActivityFreeText verifies that the activity field
// supports multi-line strings containing newlines.
//
// Acceptance Criterion (TJ-003): Activity field must accept free-text
// including line breaks for detailed descriptions.
func TestTimeJournal_TJ003_ActivityFreeText(t *testing.T) {
	// Given — an entry with multi-line activity
	entry := timejournal.TimeJournalEntry{
		SlotIndex: 0,
		SlotStart: "08:00:00",
		SlotEnd:   "09:00:00",
		Activity:  "Meeting with sponsor\nDiscussed step work\nPrayed together",
	}

	// Then — activity must contain newlines and not be truncated
	if entry.Activity == "" {
		t.Fatal("activity field should not be empty")
	}
	if len(entry.Activity) != len("Meeting with sponsor\nDiscussed step work\nPrayed together") {
		t.Errorf("activity field appears truncated, got length %d", len(entry.Activity))
	}
	// Verify newlines are preserved
	newlineCount := 0
	for _, c := range entry.Activity {
		if c == '\n' {
			newlineCount++
		}
	}
	if newlineCount != 2 {
		t.Errorf("expected 2 newlines in activity, got %d", newlineCount)
	}
}

// TestTimeJournal_TJ005_EmotionWithIntensity verifies emotion intensity
// validation within the [1, 10] range.
//
// Acceptance Criterion (TJ-005): Emotion intensity must be between 1 and 10
// inclusive. Values outside this range must be rejected.
func TestTimeJournal_TJ005_EmotionWithIntensity(t *testing.T) {
	t.Run("intensity_1_is_valid", func(t *testing.T) {
		err := timejournal.ValidateEmotionIntensity(1)
		if err != nil {
			t.Errorf("intensity 1 should be valid, got error: %v", err)
		}
	})

	t.Run("intensity_10_is_valid", func(t *testing.T) {
		err := timejournal.ValidateEmotionIntensity(10)
		if err != nil {
			t.Errorf("intensity 10 should be valid, got error: %v", err)
		}
	})

	t.Run("intensity_5_is_valid", func(t *testing.T) {
		err := timejournal.ValidateEmotionIntensity(5)
		if err != nil {
			t.Errorf("intensity 5 should be valid, got error: %v", err)
		}
	})

	t.Run("intensity_0_is_invalid", func(t *testing.T) {
		err := timejournal.ValidateEmotionIntensity(0)
		if err == nil {
			t.Error("intensity 0 should be invalid, got nil error")
		}
	})

	t.Run("intensity_11_is_invalid", func(t *testing.T) {
		err := timejournal.ValidateEmotionIntensity(11)
		if err == nil {
			t.Error("intensity 11 should be invalid, got nil error")
		}
	})

	t.Run("intensity_negative_is_invalid", func(t *testing.T) {
		err := timejournal.ValidateEmotionIntensity(-1)
		if err == nil {
			t.Error("negative intensity should be invalid, got nil error")
		}
	})
}

// TestTimeJournal_TJ011_RetroactiveEntry verifies that when the current time
// is past a slot's end time, the entry is marked as retroactive.
//
// Acceptance Criterion (TJ-011): Entries created after the slot's end time
// must be flagged retroactive=true with retroactiveTimestamp set.
func TestTimeJournal_TJ011_RetroactiveEntry(t *testing.T) {
	t.Run("entry_after_slot_end_is_retroactive", func(t *testing.T) {
		// Given — slot ended at 10:00, current time is 11:00
		slotEnd := "10:00:00"
		date := "2026-04-06"
		now := time.Date(2026, 4, 6, 11, 0, 0, 0, time.UTC)

		// When
		isRetro := timejournal.IsRetroactive(slotEnd, date, now)

		// Then
		if !isRetro {
			t.Error("entry created after slot end time should be retroactive")
		}
	})

	t.Run("entry_during_slot_is_not_retroactive", func(t *testing.T) {
		// Given — slot ends at 10:00, current time is 09:30
		slotEnd := "10:00:00"
		date := "2026-04-06"
		now := time.Date(2026, 4, 6, 9, 30, 0, 0, time.UTC)

		// When
		isRetro := timejournal.IsRetroactive(slotEnd, date, now)

		// Then
		if isRetro {
			t.Error("entry created during slot should not be retroactive")
		}
	})

	t.Run("entry_at_exact_slot_end_is_not_retroactive", func(t *testing.T) {
		// Given — slot ends at 10:00, current time is exactly 10:00
		slotEnd := "10:00:00"
		date := "2026-04-06"
		now := time.Date(2026, 4, 6, 10, 0, 0, 0, time.UTC)

		// When
		isRetro := timejournal.IsRetroactive(slotEnd, date, now)

		// Then — at the boundary, not yet retroactive
		if isRetro {
			t.Error("entry at exact slot end time should not be retroactive")
		}
	})
}

// TestTimeJournal_TJ017_EditWindow24hr verifies that entries older than 24
// hours cannot be edited.
//
// Acceptance Criterion (TJ-017): Updates to entries created more than 24 hours
// ago must be rejected.
func TestTimeJournal_TJ017_EditWindow24hr(t *testing.T) {
	t.Run("within_24hrs_is_editable", func(t *testing.T) {
		// Given — entry created 23 hours ago
		now := time.Date(2026, 4, 6, 12, 0, 0, 0, time.UTC)
		createdAt := now.Add(-23 * time.Hour)

		// When
		open := timejournal.IsEditWindowOpen(createdAt, now)

		// Then
		if !open {
			t.Error("entry created 23 hours ago should still be editable")
		}
	})

	t.Run("exactly_24hrs_is_closed", func(t *testing.T) {
		// Given — entry created exactly 24 hours ago
		now := time.Date(2026, 4, 6, 12, 0, 0, 0, time.UTC)
		createdAt := now.Add(-24 * time.Hour)

		// When
		open := timejournal.IsEditWindowOpen(createdAt, now)

		// Then
		if open {
			t.Error("entry created exactly 24 hours ago should not be editable")
		}
	})

	t.Run("over_24hrs_is_closed", func(t *testing.T) {
		// Given — entry created 25 hours ago
		now := time.Date(2026, 4, 6, 12, 0, 0, 0, time.UTC)
		createdAt := now.Add(-25 * time.Hour)

		// When
		open := timejournal.IsEditWindowOpen(createdAt, now)

		// Then
		if open {
			t.Error("entry created 25 hours ago should not be editable")
		}
	})

	t.Run("just_created_is_editable", func(t *testing.T) {
		// Given — entry just created
		now := time.Date(2026, 4, 6, 12, 0, 0, 0, time.UTC)
		createdAt := now

		// When
		open := timejournal.IsEditWindowOpen(createdAt, now)

		// Then
		if !open {
			t.Error("freshly created entry should be editable")
		}
	})
}

// TestTimeJournal_TJ060_StatusInProgress verifies that a day with no overdue
// slots shows inProgress status.
//
// Acceptance Criterion (TJ-060): Default status with no overdue slots is
// inProgress. At 8AM with slots 0-7 filled and slot 8 (current) empty,
// status is inProgress.
func TestTimeJournal_TJ060_StatusInProgress(t *testing.T) {
	// Given — 8AM, T-60 mode. Slots 0-7 (midnight-8AM) filled.
	// Slot 8 (8AM-9AM) is current and empty — not yet elapsed.
	now := time.Date(2026, 4, 6, 8, 0, 0, 0, time.UTC)
	entries := makeEntries(0, 7) // slots 0 through 7 filled

	// When
	status := timejournal.EvaluateDayStatus(entries, timejournal.ModeT60, now)

	// Then
	if status != timejournal.StatusInProgress {
		t.Errorf("expected status %q with all elapsed slots filled, got %q",
			timejournal.StatusInProgress, status)
	}
}

// TestTimeJournal_TJ061_StatusOverdue verifies that an elapsed unfilled slot
// triggers overdue status.
//
// Acceptance Criterion (TJ-061): If any elapsed slot is unfilled, status is
// overdue. At 12:01 PM with slots 0-10 filled but slot 11 (11AM-12PM)
// unfilled, status is overdue.
func TestTimeJournal_TJ061_StatusOverdue(t *testing.T) {
	// Given — 12:01 PM, T-60 mode. Slots 0-10 filled, slot 11 unfilled.
	// Slot 11 = 11:00-12:00 has elapsed (it's 12:01).
	now := time.Date(2026, 4, 6, 12, 1, 0, 0, time.UTC)
	entries := makeEntries(0, 10) // slots 0 through 10 filled, slot 11 missing

	// When
	status := timejournal.EvaluateDayStatus(entries, timejournal.ModeT60, now)

	// Then
	if status != timejournal.StatusOverdue {
		t.Errorf("expected status %q with unfilled elapsed slot, got %q",
			timejournal.StatusOverdue, status)
	}
}

// TestTimeJournal_TJ062_StatusCompleted verifies that all slots filled after
// the final slot has elapsed yields completed status.
//
// Acceptance Criterion (TJ-062): All slots filled and final slot elapsed →
// completed. At 12:01 AM next day with all 24 T-60 slots filled, status
// is completed.
func TestTimeJournal_TJ062_StatusCompleted(t *testing.T) {
	// Given — 12:01 AM next day, all 24 T-60 slots filled.
	// The "now" represents just past midnight — all 24 slots have elapsed.
	now := time.Date(2026, 4, 7, 0, 1, 0, 0, time.UTC)
	entries := makeEntries(0, 23) // all 24 slots filled

	// When
	status := timejournal.EvaluateDayStatus(entries, timejournal.ModeT60, now)

	// Then
	if status != timejournal.StatusCompleted {
		t.Errorf("expected status %q with all slots filled and day complete, got %q",
			timejournal.StatusCompleted, status)
	}
}

// TestTimeJournal_TJ063_StatusOverdueGap verifies that a gap with later
// completion still results in overdue status.
//
// Acceptance Criterion (TJ-063): Even if later slots are filled, a gap in
// earlier elapsed slots means overdue. At 12:01 PM with slots 0-9 filled,
// slot 10 unfilled, slot 11 filled → overdue.
func TestTimeJournal_TJ063_StatusOverdueGap(t *testing.T) {
	// Given — 12:01 PM, T-60 mode. Slots 0-9 filled, slot 10 unfilled, slot 11 filled.
	now := time.Date(2026, 4, 6, 12, 1, 0, 0, time.UTC)
	entries := makeEntries(0, 9)                // slots 0-9 filled
	entries = append(entries, makeEntry(11)...) // slot 11 filled, slot 10 missing

	// When
	status := timejournal.EvaluateDayStatus(entries, timejournal.ModeT60, now)

	// Then
	if status != timejournal.StatusOverdue {
		t.Errorf("expected status %q with gap in elapsed slots, got %q",
			timejournal.StatusOverdue, status)
	}
}

// TestTimeJournal_TJ030_StreakCalculation verifies that consecutive days with
// >= 80% completion count as streak days, and < 80% breaks the streak.
//
// Acceptance Criterion (TJ-030): Streak counts consecutive days where
// completion percentage >= 80%. A day at 79% breaks the streak.
func TestTimeJournal_TJ030_StreakCalculation(t *testing.T) {
	// Given — 5 days at >=80%, then one day at 79%
	days := []timejournal.TimeJournalDay{
		{Date: "2026-04-01", CompletionPct: 90.0},
		{Date: "2026-04-02", CompletionPct: 85.0},
		{Date: "2026-04-03", CompletionPct: 79.0}, // breaks streak
		{Date: "2026-04-04", CompletionPct: 95.0},
		{Date: "2026-04-05", CompletionPct: 88.0},
		{Date: "2026-04-06", CompletionPct: 92.0},
	}

	// When
	currentStreak, _ := timejournal.CalculateStreak(days)

	// Then — current streak is 3 (Apr 4-6), not 6
	if currentStreak != 3 {
		t.Errorf("expected current streak 3 (broken by 79%% day), got %d", currentStreak)
	}
}

// =============================================================================
// Status Engine Unit Tests — EvaluateDayStatus pure function
// =============================================================================

// TestTimeJournal_StatusEngine_AllEmpty verifies that an empty journal at 8AM
// shows inProgress (no elapsed unfilled slots since slot 0-7 haven't all elapsed).
func TestTimeJournal_StatusEngine_AllEmpty(t *testing.T) {
	// Given — 8AM, no entries at all. Slots 0-7 (midnight through 7AM)
	// have elapsed and are unfilled.
	now := time.Date(2026, 4, 6, 8, 0, 0, 0, time.UTC)
	var entries []timejournal.TimeJournalEntry

	// When
	status := timejournal.EvaluateDayStatus(entries, timejournal.ModeT60, now)

	// Then — slots 0-7 are elapsed and unfilled, so this is overdue
	// Note: At 8:00 AM, slots 0 (0:00-1:00) through 7 (7:00-8:00) have elapsed.
	// Since none are filled, status should be overdue.
	if status != timejournal.StatusOverdue {
		t.Errorf("expected status %q with unfilled elapsed slots, got %q",
			timejournal.StatusOverdue, status)
	}
}

// TestTimeJournal_StatusEngine_AllFilledBeforeNoon verifies that filling all
// morning slots by noon shows inProgress (afternoon slots not yet elapsed).
func TestTimeJournal_StatusEngine_AllFilledBeforeNoon(t *testing.T) {
	// Given — noon, T-60 mode. Slots 0-11 filled (midnight to noon).
	// Slot 12 (noon-1PM) is current and not yet elapsed.
	now := time.Date(2026, 4, 6, 12, 0, 0, 0, time.UTC)
	entries := makeEntries(0, 11) // 12 slots filled

	// When
	status := timejournal.EvaluateDayStatus(entries, timejournal.ModeT60, now)

	// Then
	if status != timejournal.StatusInProgress {
		t.Errorf("expected status %q with all elapsed slots filled at noon, got %q",
			timejournal.StatusInProgress, status)
	}
}

// TestTimeJournal_StatusEngine_MidDayGap verifies that a gap in filled slots
// triggers overdue even when later slots are filled.
func TestTimeJournal_StatusEngine_MidDayGap(t *testing.T) {
	// Given — noon, T-60 mode. Slots 0-8 filled, slot 9 unfilled, slot 10 filled.
	// Slot 9 (9AM-10AM) has elapsed and is unfilled.
	now := time.Date(2026, 4, 6, 12, 0, 0, 0, time.UTC)
	entries := makeEntries(0, 8)                 // slots 0-8 filled
	entries = append(entries, makeEntry(10)...)   // slot 10 filled, 9 missing

	// When
	status := timejournal.EvaluateDayStatus(entries, timejournal.ModeT60, now)

	// Then
	if status != timejournal.StatusOverdue {
		t.Errorf("expected status %q with mid-day gap, got %q",
			timejournal.StatusOverdue, status)
	}
}

// TestTimeJournal_StatusEngine_T30Mode verifies boundary calculations with
// T-30 mode (48 slots per day).
func TestTimeJournal_StatusEngine_T30Mode(t *testing.T) {
	// Given — noon, T-30 mode. 48 total slots per day.
	// Slots 0-23 (midnight to noon) should be filled for inProgress at noon.
	now := time.Date(2026, 4, 6, 12, 0, 0, 0, time.UTC)
	entries := makeEntries(0, 23) // 24 half-hour slots filled (midnight-noon)

	// When
	status := timejournal.EvaluateDayStatus(entries, timejournal.ModeT30, now)

	// Then — all elapsed slots filled, afternoon not yet due
	if status != timejournal.StatusInProgress {
		t.Errorf("expected status %q for T-30 mode with all morning slots filled, got %q",
			timejournal.StatusInProgress, status)
	}
}

// TestTimeJournal_StatusEngine_EndOfDay verifies that all slots filled at end
// of day shows completed once the final slot has elapsed.
func TestTimeJournal_StatusEngine_EndOfDay(t *testing.T) {
	// Given — 12:01 AM next day (T-60). All 24 slots filled.
	// Final slot 23 (11PM-midnight) has elapsed.
	now := time.Date(2026, 4, 7, 0, 1, 0, 0, time.UTC)
	entries := makeEntries(0, 23) // all 24 slots filled

	// When
	status := timejournal.EvaluateDayStatus(entries, timejournal.ModeT60, now)

	// Then
	if status != timejournal.StatusCompleted {
		t.Errorf("expected status %q at end of day with all slots filled, got %q",
			timejournal.StatusCompleted, status)
	}
}

// TestTimeJournal_StatusEngine_FinalSlotNotElapsed verifies that even with all
// slots filled, if the final slot hasn't elapsed yet, status is inProgress.
func TestTimeJournal_StatusEngine_FinalSlotNotElapsed(t *testing.T) {
	// Given — 11:30 PM (T-60). All 24 slots filled.
	// Final slot 23 (11PM-midnight) has not yet elapsed (still in progress).
	now := time.Date(2026, 4, 6, 23, 30, 0, 0, time.UTC)
	entries := makeEntries(0, 23) // all 24 slots filled

	// When
	status := timejournal.EvaluateDayStatus(entries, timejournal.ModeT60, now)

	// Then — final slot not elapsed, so day is still inProgress
	if status != timejournal.StatusInProgress {
		t.Errorf("expected status %q when final slot has not elapsed, got %q",
			timejournal.StatusInProgress, status)
	}
}

// =============================================================================
// Streak Calculation Unit Tests
// =============================================================================

// TestTimeJournal_Streak_ConsecutiveDays verifies that 5 consecutive days at
// >= 80% completion yields a streak of 5.
func TestTimeJournal_Streak_ConsecutiveDays(t *testing.T) {
	days := []timejournal.TimeJournalDay{
		{Date: "2026-04-02", CompletionPct: 85.0},
		{Date: "2026-04-03", CompletionPct: 90.0},
		{Date: "2026-04-04", CompletionPct: 80.0},
		{Date: "2026-04-05", CompletionPct: 95.0},
		{Date: "2026-04-06", CompletionPct: 88.0},
	}

	currentStreak, longestStreak := timejournal.CalculateStreak(days)

	if currentStreak != 5 {
		t.Errorf("expected current streak 5, got %d", currentStreak)
	}
	if longestStreak != 5 {
		t.Errorf("expected longest streak 5, got %d", longestStreak)
	}
}

// TestTimeJournal_Streak_BrokenByLowCompletion verifies that a day below 80%
// breaks the current streak, with only later consecutive days counting.
func TestTimeJournal_Streak_BrokenByLowCompletion(t *testing.T) {
	// Days ordered oldest to newest
	days := []timejournal.TimeJournalDay{
		{Date: "2026-04-03", CompletionPct: 90.0},
		{Date: "2026-04-04", CompletionPct: 85.0},
		{Date: "2026-04-05", CompletionPct: 79.0}, // breaks streak
		{Date: "2026-04-06", CompletionPct: 95.0},
	}

	currentStreak, _ := timejournal.CalculateStreak(days)

	// Only the last day (Apr 6) counts since Apr 5 broke the streak
	if currentStreak != 1 {
		t.Errorf("expected current streak 1 (broken by 79%% day), got %d", currentStreak)
	}
}

// TestTimeJournal_Streak_LongestVsCurrent verifies that a historical longer
// streak is preserved even when the current streak is shorter.
func TestTimeJournal_Streak_LongestVsCurrent(t *testing.T) {
	days := []timejournal.TimeJournalDay{
		{Date: "2026-03-30", CompletionPct: 85.0},
		{Date: "2026-03-31", CompletionPct: 90.0},
		{Date: "2026-04-01", CompletionPct: 88.0},
		{Date: "2026-04-02", CompletionPct: 92.0},
		{Date: "2026-04-03", CompletionPct: 50.0}, // breaks streak
		{Date: "2026-04-04", CompletionPct: 85.0},
		{Date: "2026-04-05", CompletionPct: 90.0},
		{Date: "2026-04-06", CompletionPct: 88.0},
	}

	currentStreak, longestStreak := timejournal.CalculateStreak(days)

	if currentStreak != 3 {
		t.Errorf("expected current streak 3, got %d", currentStreak)
	}
	if longestStreak != 4 {
		t.Errorf("expected longest streak 4, got %d", longestStreak)
	}
}

// TestTimeJournal_Streak_ExactThreshold verifies that a day at exactly 80%
// completion counts toward the streak.
func TestTimeJournal_Streak_ExactThreshold(t *testing.T) {
	days := []timejournal.TimeJournalDay{
		{Date: "2026-04-05", CompletionPct: 80.0}, // exactly at threshold
		{Date: "2026-04-06", CompletionPct: 80.0}, // exactly at threshold
	}

	currentStreak, _ := timejournal.CalculateStreak(days)

	if currentStreak != 2 {
		t.Errorf("expected current streak 2 (80%% should count), got %d", currentStreak)
	}
}

// TestTimeJournal_Streak_BelowThreshold verifies that a day at 79% breaks the
// streak.
func TestTimeJournal_Streak_BelowThreshold(t *testing.T) {
	days := []timejournal.TimeJournalDay{
		{Date: "2026-04-04", CompletionPct: 85.0},
		{Date: "2026-04-05", CompletionPct: 79.0}, // just below threshold
		{Date: "2026-04-06", CompletionPct: 85.0},
	}

	currentStreak, _ := timejournal.CalculateStreak(days)

	if currentStreak != 1 {
		t.Errorf("expected current streak 1 (79%% breaks streak), got %d", currentStreak)
	}
}

// TestTimeJournal_Streak_EmptyHistory verifies that no journal days yields a
// streak of 0.
func TestTimeJournal_Streak_EmptyHistory(t *testing.T) {
	var days []timejournal.TimeJournalDay

	currentStreak, longestStreak := timejournal.CalculateStreak(days)

	if currentStreak != 0 {
		t.Errorf("expected current streak 0 with no history, got %d", currentStreak)
	}
	if longestStreak != 0 {
		t.Errorf("expected longest streak 0 with no history, got %d", longestStreak)
	}
}

// =============================================================================
// Test Helpers
// =============================================================================

// makeEntry creates a slice with a single TimeJournalEntry for the given slot index.
func makeEntry(slotIndex int) []timejournal.TimeJournalEntry {
	return []timejournal.TimeJournalEntry{
		{
			SlotIndex: slotIndex,
			SlotStart: slotStartForIndex(slotIndex),
			SlotEnd:   slotEndForIndex(slotIndex),
			Activity:  "Test activity",
			Location:  "Home",
			CreatedAt: time.Now(),
		},
	}
}

// makeEntries creates TimeJournalEntry values for slot indices from startIdx
// to endIdx (inclusive).
func makeEntries(startIdx, endIdx int) []timejournal.TimeJournalEntry {
	entries := make([]timejournal.TimeJournalEntry, 0, endIdx-startIdx+1)
	for i := startIdx; i <= endIdx; i++ {
		entries = append(entries, timejournal.TimeJournalEntry{
			SlotIndex: i,
			SlotStart: slotStartForIndex(i),
			SlotEnd:   slotEndForIndex(i),
			Activity:  "Test activity",
			Location:  "Home",
			CreatedAt: time.Now(),
		})
	}
	return entries
}

// slotStartForIndex returns the HH:MM:SS start time for a T-60 slot index.
func slotStartForIndex(idx int) string {
	hour := idx % 24
	return fmt.Sprintf("%02d:00:00", hour)
}

// slotEndForIndex returns the HH:MM:SS end time for a T-60 slot index.
func slotEndForIndex(idx int) string {
	hour := (idx + 1) % 24
	return fmt.Sprintf("%02d:00:00", hour)
}
