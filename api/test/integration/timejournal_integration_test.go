// test/integration/timejournal_integration_test.go
package integration

import (
	"context"
	"fmt"
	"os"
	"testing"
	"time"

	tj "github.com/regalrecovery/api/internal/domain/timejournal"
	"github.com/regalrecovery/api/internal/repository"
)

// setupTimeJournal creates a MongoClient, repo, and service for integration tests.
// It skips the test if MONGODB_URI is not set.
func setupTimeJournal(t *testing.T) (context.Context, *tj.TimeJournalService, *repository.MongoClient, func()) {
	t.Helper()

	uri := os.Getenv("MONGODB_URI")
	if uri == "" {
		t.Skip("MONGODB_URI not set; skipping integration test (requires local MongoDB)")
	}

	ctx := context.Background()
	dbName := fmt.Sprintf("rr_test_%d", time.Now().UnixNano())

	client, err := repository.NewMongoClient(ctx, uri, dbName)
	if err != nil {
		t.Fatalf("failed to connect to MongoDB: %v", err)
	}

	// Ensure indexes are created for the test database.
	if err := client.EnsureIndexes(ctx); err != nil {
		t.Fatalf("failed to create indexes: %v", err)
	}

	repo := repository.NewTimeJournalRepo(client)
	service := tj.NewTimeJournalService(repo)

	cleanup := func() {
		_ = client.Disconnect(ctx)
	}

	return ctx, service, client, cleanup
}

func TestTimeJournal_Integration_CreateAndRetrieveEntry(t *testing.T) {
	ctx, service, _, cleanup := setupTimeJournal(t)
	defer cleanup()

	userID := "u_inttest_create"
	today := time.Now().UTC().Format("2006-01-02")

	// Create entry for the current hour slot.
	now := time.Now().UTC()
	slotStart := fmt.Sprintf("%02d:00:00", now.Hour())

	activity := "Integration test activity"
	req := &tj.CreateTimeJournalEntryRequest{
		Date:      today,
		SlotStart: slotStart,
		Mode:      tj.ModeT60,
		Activity:  &activity,
		SleepFlag: false,
	}

	entry, err := service.CreateEntry(ctx, userID, req)
	if err != nil {
		t.Fatalf("CreateEntry failed: %v", err)
	}

	if entry.ID == "" {
		t.Fatal("expected entry to have a non-empty ID")
	}
	if entry.UserID != userID {
		t.Errorf("expected userID %q, got %q", userID, entry.UserID)
	}
	if entry.Date != today {
		t.Errorf("expected date %q, got %q", today, entry.Date)
	}
	if entry.SlotStart != slotStart {
		t.Errorf("expected slotStart %q, got %q", slotStart, entry.SlotStart)
	}
	if entry.SlotEnd == "" {
		t.Error("expected slotEnd to be computed, got empty")
	}

	// Retrieve the entry back.
	retrieved, err := service.GetEntry(ctx, userID, entry.ID)
	if err != nil {
		t.Fatalf("GetEntry failed: %v", err)
	}
	if retrieved.ID != entry.ID {
		t.Errorf("expected retrieved ID %q, got %q", entry.ID, retrieved.ID)
	}
	if *retrieved.Activity != activity {
		t.Errorf("expected activity %q, got %q", activity, *retrieved.Activity)
	}

	// Verify ownership check: different user should get not found.
	_, err = service.GetEntry(ctx, "u_other_user", entry.ID)
	if err == nil {
		t.Error("expected error when retrieving entry with wrong user, got nil")
	}
}

func TestTimeJournal_Integration_DaySummaryCalculation(t *testing.T) {
	ctx, service, _, cleanup := setupTimeJournal(t)
	defer cleanup()

	userID := "u_inttest_day"
	today := time.Now().UTC().Format("2006-01-02")

	// Create 3 entries for today.
	for i := 0; i < 3; i++ {
		slotStart := fmt.Sprintf("%02d:00:00", i)
		activity := fmt.Sprintf("Test activity %d", i)
		req := &tj.CreateTimeJournalEntryRequest{
			Date:      today,
			SlotStart: slotStart,
			Mode:      tj.ModeT60,
			Activity:  &activity,
			SleepFlag: i < 2, // first 2 are sleep
		}
		_, err := service.CreateEntry(ctx, userID, req)
		if err != nil {
			t.Fatalf("CreateEntry[%d] failed: %v", i, err)
		}
	}

	// Retrieve day summary.
	day, err := service.GetDaySummary(ctx, userID, today)
	if err != nil {
		t.Fatalf("GetDaySummary failed: %v", err)
	}

	if day.Date != today {
		t.Errorf("expected date %q, got %q", today, day.Date)
	}
	if day.TotalSlots != 24 {
		t.Errorf("expected totalSlots 24, got %d", day.TotalSlots)
	}
	if day.FilledSlots != 3 {
		t.Errorf("expected filledSlots 3, got %d", day.FilledSlots)
	}
	expectedScore := 3.0 / 24.0
	if day.CompletionScore < expectedScore-0.01 || day.CompletionScore > expectedScore+0.01 {
		t.Errorf("expected completionScore ~%.4f, got %.4f", expectedScore, day.CompletionScore)
	}
}

func TestTimeJournal_Integration_StatusEngineEndToEnd(t *testing.T) {
	ctx, service, _, cleanup := setupTimeJournal(t)
	defer cleanup()

	userID := "u_inttest_status"

	// Get status with no entries. Should be in-progress with 0 filled.
	status, err := service.GetTodayStatus(ctx, userID, tj.ModeT60)
	if err != nil {
		t.Fatalf("GetTodayStatus failed: %v", err)
	}

	if status.TotalSlots != 24 {
		t.Errorf("expected totalSlots 24, got %d", status.TotalSlots)
	}
	if status.FilledSlots != 0 {
		t.Errorf("expected filledSlots 0, got %d", status.FilledSlots)
	}

	// The status depends on whether any elapsed slots exist.
	// At any time of day > 01:00, there should be overdue slots if nothing is filled.
	now := time.Now().UTC()
	if now.Hour() >= 1 {
		if status.Status != tj.StatusOverdue {
			t.Errorf("expected status 'overdue' when elapsed slots are unfilled, got %q", status.Status)
		}
		if status.OverdueSlots == 0 {
			t.Error("expected overdueSlots > 0 when there are elapsed unfilled slots")
		}
	}

	// Create an entry for the current slot.
	today := now.Format("2006-01-02")
	slotStart := fmt.Sprintf("%02d:00:00", now.Hour())
	activity := "Status test"
	req := &tj.CreateTimeJournalEntryRequest{
		Date:      today,
		SlotStart: slotStart,
		Mode:      tj.ModeT60,
		Activity:  &activity,
	}
	_, err = service.CreateEntry(ctx, userID, req)
	if err != nil {
		t.Fatalf("CreateEntry failed: %v", err)
	}

	// Re-check status: should now have 1 filled slot.
	status2, err := service.GetTodayStatus(ctx, userID, tj.ModeT60)
	if err != nil {
		t.Fatalf("GetTodayStatus after create failed: %v", err)
	}
	if status2.FilledSlots != 1 {
		t.Errorf("expected filledSlots 1 after creating entry, got %d", status2.FilledSlots)
	}
}

func TestTimeJournal_Integration_StreakAcrossDays(t *testing.T) {
	ctx, service, _, cleanup := setupTimeJournal(t)
	defer cleanup()

	userID := "u_inttest_streak"

	// Create entries for 3 consecutive past days with >= 80% completion (20+ of 24 slots).
	now := time.Now().UTC()
	for dayOffset := 3; dayOffset >= 1; dayOffset-- {
		date := now.AddDate(0, 0, -dayOffset).Format("2006-01-02")
		// Fill 20 of 24 slots (83.3% > 80% threshold).
		for h := 0; h < 20; h++ {
			slotStart := fmt.Sprintf("%02d:00:00", h)
			activity := "Streak test"
			req := &tj.CreateTimeJournalEntryRequest{
				Date:      date,
				SlotStart: slotStart,
				Mode:      tj.ModeT60,
				Activity:  &activity,
				SleepFlag: h < 6,
			}
			_, err := service.CreateEntry(ctx, userID, req)
			if err != nil {
				t.Fatalf("CreateEntry day-%d slot-%d failed: %v", dayOffset, h, err)
			}
		}
	}

	// Check streak.
	streak, err := service.GetStreak(ctx, userID)
	if err != nil {
		t.Fatalf("GetStreak failed: %v", err)
	}

	// All 3 days should be streak-eligible (>= 80%).
	if streak.CurrentStreakDays < 3 {
		t.Errorf("expected currentStreakDays >= 3, got %d", streak.CurrentStreakDays)
	}
	if streak.LongestStreakDays < 3 {
		t.Errorf("expected longestStreakDays >= 3, got %d", streak.LongestStreakDays)
	}
	if streak.TotalJournalDays < 3 {
		t.Errorf("expected totalJournalDays >= 3, got %d", streak.TotalJournalDays)
	}
	if streak.ThresholdPercent != 80 {
		t.Errorf("expected thresholdPercent 80, got %d", streak.ThresholdPercent)
	}

	// Next milestone should be 7 days.
	if streak.NextMilestone == nil {
		t.Error("expected nextMilestone to be set")
	} else if streak.NextMilestone.Days != 7 {
		t.Errorf("expected nextMilestone.Days 7, got %d", streak.NextMilestone.Days)
	}
}

func TestTimeJournal_Integration_EditWindowEnforcement(t *testing.T) {
	ctx, service, _, cleanup := setupTimeJournal(t)
	defer cleanup()

	userID := "u_inttest_edit"
	today := time.Now().UTC().Format("2006-01-02")
	now := time.Now().UTC()
	slotStart := fmt.Sprintf("%02d:00:00", now.Hour())

	// Create an entry.
	activity := "Edit window test"
	req := &tj.CreateTimeJournalEntryRequest{
		Date:      today,
		SlotStart: slotStart,
		Mode:      tj.ModeT60,
		Activity:  &activity,
	}
	entry, err := service.CreateEntry(ctx, userID, req)
	if err != nil {
		t.Fatalf("CreateEntry failed: %v", err)
	}

	// Update within the edit window should succeed.
	newActivity := "Updated activity"
	updateReq := &tj.UpdateTimeJournalEntryRequest{
		Activity: &newActivity,
	}
	updated, err := service.UpdateEntry(ctx, userID, entry.ID, updateReq)
	if err != nil {
		t.Fatalf("UpdateEntry within window failed: %v", err)
	}
	if *updated.Activity != newActivity {
		t.Errorf("expected updated activity %q, got %q", newActivity, *updated.Activity)
	}

	// Verify that the update was persisted.
	retrieved, err := service.GetEntry(ctx, userID, entry.ID)
	if err != nil {
		t.Fatalf("GetEntry after update failed: %v", err)
	}
	if *retrieved.Activity != newActivity {
		t.Errorf("expected persisted activity %q, got %q", newActivity, *retrieved.Activity)
	}

	// Test duplicate slot rejection.
	dupReq := &tj.CreateTimeJournalEntryRequest{
		Date:      today,
		SlotStart: slotStart,
		Mode:      tj.ModeT60,
		Activity:  &activity,
	}
	_, err = service.CreateEntry(ctx, userID, dupReq)
	if err == nil {
		t.Error("expected error for duplicate slot, got nil")
	}
}
