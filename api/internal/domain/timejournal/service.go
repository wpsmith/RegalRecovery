// internal/domain/timejournal/service.go
package timejournal

import (
	"context"
	"errors"
	"fmt"
	"time"
)

var (
	// ErrEntryNotFound indicates the time journal entry does not exist.
	ErrEntryNotFound = errors.New("time journal entry not found")

	// ErrDayNotFound indicates no day summary exists for the given date.
	ErrDayNotFound = errors.New("time journal day not found")

	// ErrInvalidInput indicates invalid request data.
	ErrInvalidInput = errors.New("invalid input data")

	// ErrEditWindowExpired indicates the 24-hour edit window has passed.
	ErrEditWindowExpired = errors.New("edit window expired: entries can only be edited within 24 hours of creation")

	// ErrDuplicateSlot indicates a slot with the same start time already exists.
	ErrDuplicateSlot = errors.New("duplicate slot: entry already exists for this time slot")
)

// editWindowDuration is the maximum time after creation that an entry can be edited.
const editWindowDuration = 24 * time.Hour

// streakThresholdPercent is the minimum completion percentage for a day to count toward a streak.
const streakThresholdPercent = 80

// TimeJournalRepository defines the persistence interface for time journal data.
type TimeJournalRepository interface {
	// CreateEntry persists a new time journal entry.
	CreateEntry(ctx context.Context, entry *TimeJournalEntry) error

	// GetEntry retrieves a single entry by ID.
	GetEntry(ctx context.Context, entryID string) (*TimeJournalEntry, error)

	// UpdateEntry applies a merge-patch update and returns the updated entry.
	UpdateEntry(ctx context.Context, entryID string, req *UpdateTimeJournalEntryRequest) (*TimeJournalEntry, error)

	// GetEntriesForDate retrieves all entries for a user on a specific date.
	GetEntriesForDate(ctx context.Context, userID string, date string, mode TimeJournalMode) ([]TimeJournalEntry, error)

	// GetDaySummary retrieves the aggregated day summary for a date.
	GetDaySummary(ctx context.Context, userID string, date string) (*TimeJournalDay, error)

	// GetDaySummaries retrieves paginated day summaries within a date range.
	// Returns summaries, next cursor, and error.
	GetDaySummaries(ctx context.Context, userID string, startDate string, endDate string, mode *TimeJournalMode, cursor string, limit int) ([]TimeJournalDay, string, error)

	// GetStreak retrieves the computed streak data for a user.
	GetStreak(ctx context.Context, userID string) (*TimeJournalStreak, error)

	// UpsertDayAggregate recalculates and upserts the daily aggregate for a given date.
	UpsertDayAggregate(ctx context.Context, userID string, date string, mode TimeJournalMode) error
}

// TimeJournalService contains business logic for the time journal feature.
type TimeJournalService struct {
	repo TimeJournalRepository
}

// NewTimeJournalService creates a new service with the given repository.
func NewTimeJournalService(repo TimeJournalRepository) *TimeJournalService {
	return &TimeJournalService{repo: repo}
}

// CreateEntry creates a new time journal entry, auto-populating SlotEnd and
// flagging retroactive entries.
func (s *TimeJournalService) CreateEntry(ctx context.Context, userID string, req *CreateTimeJournalEntryRequest) (*TimeJournalEntry, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required: %w", ErrInvalidInput)
	}
	if req.Date == "" || req.SlotStart == "" {
		return nil, fmt.Errorf("date and slotStart are required: %w", ErrInvalidInput)
	}
	if req.Mode != ModeT30 && req.Mode != ModeT60 {
		return nil, fmt.Errorf("mode must be T30 or T60: %w", ErrInvalidInput)
	}

	now := time.Now().UTC()

	// Calculate SlotEnd from SlotStart + mode duration.
	slotEnd, err := calculateSlotEnd(req.SlotStart, req.Mode)
	if err != nil {
		return nil, fmt.Errorf("calculating slot end: %w", err)
	}

	// Determine if entry is retroactive (slot has already elapsed).
	retroactive := isRetroactive(req.Date, req.SlotStart, req.Mode, now)
	var retroactiveTimestamp *time.Time
	if retroactive {
		retroactiveTimestamp = &now
	}

	entry := &TimeJournalEntry{
		ID:                   generateEntryID(),
		UserID:               userID,
		Date:                 req.Date,
		SlotStart:            req.SlotStart,
		SlotEnd:              slotEnd,
		Mode:                 req.Mode,
		Location:             req.Location,
		GPSLatitude:          req.GPSLatitude,
		GPSLongitude:         req.GPSLongitude,
		GPSAddress:           req.GPSAddress,
		Activity:             req.Activity,
		People:               req.People,
		Emotions:             req.Emotions,
		Extras:               req.Extras,
		SleepFlag:            req.SleepFlag,
		Retroactive:          retroactive,
		RetroactiveTimestamp: retroactiveTimestamp,
		AutoFilled:           false,
		RedlineNote:          req.RedlineNote,
		CreatedAt:            now,
		ModifiedAt:           now,
	}

	if err := s.repo.CreateEntry(ctx, entry); err != nil {
		return nil, fmt.Errorf("creating entry: %w", err)
	}

	// Recalculate daily aggregate.
	if err := s.repo.UpsertDayAggregate(ctx, userID, req.Date, req.Mode); err != nil {
		return nil, fmt.Errorf("upserting day aggregate: %w", err)
	}

	return entry, nil
}

// UpdateEntry applies a merge-patch update to an existing entry, enforcing the
// 24-hour edit window.
func (s *TimeJournalService) UpdateEntry(ctx context.Context, userID string, entryID string, req *UpdateTimeJournalEntryRequest) (*TimeJournalEntry, error) {
	if entryID == "" {
		return nil, fmt.Errorf("entry ID is required: %w", ErrInvalidInput)
	}

	// Fetch existing entry to check ownership and edit window.
	existing, err := s.repo.GetEntry(ctx, entryID)
	if err != nil {
		return nil, fmt.Errorf("retrieving entry: %w", err)
	}
	if existing == nil {
		return nil, ErrEntryNotFound
	}
	if existing.UserID != userID {
		return nil, ErrEntryNotFound // hide existence from non-owners
	}

	// Enforce 24-hour edit window.
	if time.Since(existing.CreatedAt) > editWindowDuration {
		return nil, ErrEditWindowExpired
	}

	updated, err := s.repo.UpdateEntry(ctx, entryID, req)
	if err != nil {
		return nil, fmt.Errorf("updating entry: %w", err)
	}

	// Recalculate daily aggregate.
	if err := s.repo.UpsertDayAggregate(ctx, userID, existing.Date, existing.Mode); err != nil {
		return nil, fmt.Errorf("upserting day aggregate: %w", err)
	}

	return updated, nil
}

// GetEntry retrieves a single entry, verifying ownership.
func (s *TimeJournalService) GetEntry(ctx context.Context, userID string, entryID string) (*TimeJournalEntry, error) {
	entry, err := s.repo.GetEntry(ctx, entryID)
	if err != nil {
		return nil, fmt.Errorf("retrieving entry: %w", err)
	}
	if entry == nil || entry.UserID != userID {
		return nil, ErrEntryNotFound
	}
	return entry, nil
}

// GetEntriesForDate retrieves all entries for a user on a given date.
func (s *TimeJournalService) GetEntriesForDate(ctx context.Context, userID string, date string, mode TimeJournalMode) ([]TimeJournalEntry, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required: %w", ErrInvalidInput)
	}
	return s.repo.GetEntriesForDate(ctx, userID, date, mode)
}

// GetDaySummary retrieves the aggregated day summary for a date.
func (s *TimeJournalService) GetDaySummary(ctx context.Context, userID string, date string) (*TimeJournalDay, error) {
	if userID == "" || date == "" {
		return nil, fmt.Errorf("user ID and date are required: %w", ErrInvalidInput)
	}
	day, err := s.repo.GetDaySummary(ctx, userID, date)
	if err != nil {
		return nil, fmt.Errorf("retrieving day summary: %w", err)
	}
	if day == nil {
		return nil, ErrDayNotFound
	}
	return day, nil
}

// GetDaySummaries retrieves paginated day summaries.
func (s *TimeJournalService) GetDaySummaries(ctx context.Context, userID string, startDate string, endDate string, mode *TimeJournalMode, cursor string, limit int) ([]TimeJournalDay, string, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}
	return s.repo.GetDaySummaries(ctx, userID, startDate, endDate, mode, cursor, limit)
}

// GetStreak retrieves the user's time journal streak data.
func (s *TimeJournalService) GetStreak(ctx context.Context, userID string) (*TimeJournalStreak, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required: %w", ErrInvalidInput)
	}
	streak, err := s.repo.GetStreak(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("retrieving streak: %w", err)
	}
	return streak, nil
}

// GetTodayStatus computes the real-time status for today's journal entries.
func (s *TimeJournalService) GetTodayStatus(ctx context.Context, userID string, mode TimeJournalMode) (*TimeJournalStatus, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required: %w", ErrInvalidInput)
	}

	today := time.Now().UTC().Format("2006-01-02")
	entries, err := s.repo.GetEntriesForDate(ctx, userID, today, mode)
	if err != nil {
		return nil, fmt.Errorf("retrieving today's entries: %w", err)
	}

	now := time.Now().UTC()
	status := EvaluateDayStatus(entries, mode, now)
	totalSlots := mode.TotalSlots()
	filledSlots := len(entries)
	overdueSlots := countOverdueSlots(entries, mode, now)
	completionPercent := 0.0
	if totalSlots > 0 {
		completionPercent = float64(filledSlots) / float64(totalSlots) * 100
	}

	triggerReason := buildTriggerReason(status, overdueSlots)

	return &TimeJournalStatus{
		Status:           status,
		FilledSlots:      filledSlots,
		TotalSlots:       totalSlots,
		OverdueSlots:     overdueSlots,
		CompletionPercent: completionPercent,
		LastUpdatedAt:    now,
		TriggerReason:    triggerReason,
	}, nil
}

// EvaluateDayStatus determines the day's status based on entries and current time.
// Implements the status engine (TJ-060-064):
//   - Parse each entry's SlotStart to get slot boundaries
//   - A slot is elapsed when current time >= slot end time
//   - If any elapsed slot is unfilled -> StatusOverdue
//   - All slots filled AND final slot elapsed -> StatusCompleted
//   - Otherwise -> StatusInProgress
func EvaluateDayStatus(entries []TimeJournalEntry, mode TimeJournalMode, now time.Time) DayStatus {
	totalSlots := mode.TotalSlots()
	durationMinutes := mode.SlotDurationMinutes()

	// Build a set of filled slot start times.
	filledSlots := make(map[string]bool, len(entries))
	for _, e := range entries {
		filledSlots[e.SlotStart] = true
	}

	// Determine the date to evaluate. Use the entries' date if available,
	// otherwise fall back to now's date. This ensures that when evaluating
	// a past day (e.g., yesterday) with now being the next day, slot
	// boundaries are computed correctly relative to the entries' date.
	dateStr := now.Format("2006-01-02")
	for _, e := range entries {
		if e.Date != "" {
			dateStr = e.Date
			break
		}
	}

	hasOverdue := false
	allElapsed := true

	for i := range totalSlots {
		hour := (i * durationMinutes) / 60
		minute := (i * durationMinutes) % 60
		slotStart := fmt.Sprintf("%02d:%02d:00", hour, minute)
		slotEndTime := parseSlotTime(dateStr, slotStart).Add(time.Duration(durationMinutes) * time.Minute)

		elapsed := now.After(slotEndTime) || now.Equal(slotEndTime)
		if !elapsed {
			allElapsed = false
			continue
		}

		if !filledSlots[slotStart] {
			hasOverdue = true
		}
	}

	if hasOverdue {
		return StatusOverdue
	}
	if allElapsed && len(filledSlots) == totalSlots {
		return StatusCompleted
	}
	return StatusInProgress
}

// CalculateStreak computes current and longest streak from sorted day summaries.
// A day counts toward a streak if its CompletionScore >= streakThresholdPercent%.
// Days must be sorted descending by date (most recent first).
func CalculateStreak(days []TimeJournalDay) (currentStreak int, longestStreak int) {
	if len(days) == 0 {
		return 0, 0
	}

	threshold := float64(streakThresholdPercent) / 100.0
	streak := 0
	currentFound := false

	for i, day := range days {
		eligible := day.CompletionScore >= threshold

		if i == 0 && !eligible {
			// Most recent day not eligible: current streak is 0.
			currentFound = true
		}

		if eligible {
			streak++
		} else {
			if !currentFound {
				currentStreak = streak
				currentFound = true
			}
			if streak > longestStreak {
				longestStreak = streak
			}
			streak = 0
		}
	}

	// Handle end of list.
	if !currentFound {
		currentStreak = streak
	}
	if streak > longestStreak {
		longestStreak = streak
	}
	if currentStreak > longestStreak {
		longestStreak = currentStreak
	}

	return currentStreak, longestStreak
}

// --- Helper functions ---

// calculateSlotEnd computes the end time from a start time and mode.
func calculateSlotEnd(slotStart string, mode TimeJournalMode) (string, error) {
	t, err := time.Parse("15:04:05", slotStart)
	if err != nil {
		return "", fmt.Errorf("parsing slot start %q: %w", slotStart, err)
	}
	t = t.Add(time.Duration(mode.SlotDurationMinutes()) * time.Minute)
	return t.Format("15:04:05"), nil
}

// isRetroactive returns true if the slot's full time period has elapsed at the given time.
// A slot is retroactive when now > slotEnd (not slotStart), consistent with TJ-011.
func isRetroactive(date string, slotStart string, mode TimeJournalMode, now time.Time) bool {
	slotStartTime := parseSlotTime(date, slotStart)
	slotEndTime := slotStartTime.Add(time.Duration(mode.SlotDurationMinutes()) * time.Minute)
	return now.After(slotEndTime)
}

// parseSlotTime parses date + slotStart into a time.Time in UTC.
func parseSlotTime(date string, slotStart string) time.Time {
	t, err := time.Parse("2006-01-02 15:04:05", date+" "+slotStart)
	if err != nil {
		return time.Time{}
	}
	return t.UTC()
}

// countOverdueSlots counts elapsed but unfilled slots.
func countOverdueSlots(entries []TimeJournalEntry, mode TimeJournalMode, now time.Time) int {
	totalSlots := mode.TotalSlots()
	durationMinutes := mode.SlotDurationMinutes()

	filledSlots := make(map[string]bool, len(entries))
	for _, e := range entries {
		filledSlots[e.SlotStart] = true
	}

	todayStr := now.Format("2006-01-02")
	overdue := 0

	for i := range totalSlots {
		hour := (i * durationMinutes) / 60
		minute := (i * durationMinutes) % 60
		slotStart := fmt.Sprintf("%02d:%02d:00", hour, minute)
		slotEndTime := parseSlotTime(todayStr, slotStart).Add(time.Duration(durationMinutes) * time.Minute)

		elapsed := now.After(slotEndTime) || now.Equal(slotEndTime)
		if elapsed && !filledSlots[slotStart] {
			overdue++
		}
	}

	return overdue
}

// buildTriggerReason builds a human-readable reason for the current status.
func buildTriggerReason(status DayStatus, overdueSlots int) string {
	switch status {
	case StatusCompleted:
		return "All slots filled for today"
	case StatusOverdue:
		return fmt.Sprintf("%d elapsed slot(s) unfilled", overdueSlots)
	default:
		return "Day in progress"
	}
}

// generateEntryID creates a new entry ID with the tj_ prefix.
func generateEntryID() string {
	return fmt.Sprintf("tj_%d", time.Now().UnixNano())
}

// generateDayID creates a day aggregate ID with the tjd_ prefix.
func generateDayID() string {
	return fmt.Sprintf("tjd_%d", time.Now().UnixNano())
}

// SlotEndFromStart calculates the slot end time given a start time and mode.
// This is the public API for slot end computation.
func SlotEndFromStart(slotStart string, mode TimeJournalMode) string {
	end, err := calculateSlotEnd(slotStart, mode)
	if err != nil {
		return ""
	}
	return end
}

// IsRetroactive determines whether a time slot entry is retroactive (entered
// after the slot's end time has passed).
func IsRetroactive(slotEnd string, date string, now time.Time) bool {
	endTime := parseSlotTime(date, slotEnd)
	if endTime.IsZero() {
		return false
	}
	return now.After(endTime)
}

// IsEditWindowOpen checks whether an entry can still be edited (within 24-hour window).
func IsEditWindowOpen(createdAt time.Time, now time.Time) bool {
	return now.Sub(createdAt) < editWindowDuration
}

// ValidateEmotionIntensity checks that the intensity is within the valid range [1, 10].
func ValidateEmotionIntensity(intensity int) error {
	if intensity < 1 || intensity > 10 {
		return fmt.Errorf("emotion intensity must be between 1 and 10, got %d: %w", intensity, ErrInvalidInput)
	}
	return nil
}
