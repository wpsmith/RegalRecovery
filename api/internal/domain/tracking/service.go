// internal/domain/tracking/service.go
package tracking

import (
	"context"
	"errors"
	"fmt"
	"time"
)

var (
	// ErrStreakNotFound indicates streak does not exist.
	ErrStreakNotFound = errors.New("streak not found")

	// ErrMilestoneNotFound indicates milestone does not exist.
	ErrMilestoneNotFound = errors.New("milestone not found")

	// ErrInvalidInput indicates invalid input data.
	ErrInvalidInput = errors.New("invalid input data")

	// ErrRelapseNotFound indicates relapse record does not exist.
	ErrRelapseNotFound = errors.New("relapse not found")
)

// TrackingService handles sobriety tracking business logic.
type TrackingService struct {
	streakRepo    StreakRepository
	milestoneRepo MilestoneRepository
	relapseRepo   RelapseRepository
	calendarRepo  CalendarRepository
	cache         StreakCache
	events        EventPublisher
}

// NewTrackingService creates a new TrackingService with required dependencies.
func NewTrackingService(
	streakRepo StreakRepository,
	milestoneRepo MilestoneRepository,
	relapseRepo RelapseRepository,
	calendarRepo CalendarRepository,
	cache StreakCache,
	events EventPublisher,
) *TrackingService {
	return &TrackingService{
		streakRepo:    streakRepo,
		milestoneRepo: milestoneRepo,
		relapseRepo:   relapseRepo,
		calendarRepo:  calendarRepo,
		cache:         cache,
		events:        events,
	}
}

// GetStreak retrieves current streak data for an addiction.
// Uses cache-aside pattern for performance.
func (s *TrackingService) GetStreak(ctx context.Context, addictionID string) (*StreakData, error) {
	if addictionID == "" {
		return nil, fmt.Errorf("addiction ID is required: %w", ErrInvalidInput)
	}

	// Try cache first.
	streak, err := s.cache.Get(ctx, addictionID)
	if err != nil || streak == nil {
		// Cache miss, fetch from repository.
		streak, err = s.streakRepo.GetStreak(ctx, addictionID)
		if err != nil {
			return nil, fmt.Errorf("retrieving streak: %w", err)
		}
		if streak == nil {
			return nil, ErrStreakNotFound
		}

		// Calculate current streak days.
		now := time.Now()
		streak.CurrentStreakDays = CalculateStreakDays(streak.SobrietyStartDate, now)

		// Calculate next milestone.
		nextMilestone := NextMilestone(streak.CurrentStreakDays)
		if nextMilestone > 0 {
			streak.NextMilestone = &MilestoneInfo{
				Days:          nextMilestone,
				DaysRemaining: nextMilestone - streak.CurrentStreakDays,
				Label:         MilestoneLabel(nextMilestone),
			}
		}

		// Store in cache with 60-second TTL.
		_ = s.cache.Set(ctx, addictionID, streak, 60)
	}

	return streak, nil
}

// RecordRelapse records a relapse event and resets the streak.
// Returns updated streak data with compassionate messaging.
func (s *TrackingService) RecordRelapse(ctx context.Context, userID, addictionID string, timestamp time.Time, notes string) (*StreakData, string, error) {
	if userID == "" {
		return nil, "", fmt.Errorf("user ID is required: %w", ErrInvalidInput)
	}
	if addictionID == "" {
		return nil, "", fmt.Errorf("addiction ID is required: %w", ErrInvalidInput)
	}
	if timestamp.IsZero() {
		timestamp = time.Now()
	}

	// Get current streak to preserve previous streak days.
	currentStreak, err := s.GetStreak(ctx, addictionID)
	if err != nil {
		return nil, "", fmt.Errorf("retrieving current streak: %w", err)
	}

	// Create relapse record.
	relapse := &Relapse{
		AddictionID:        addictionID,
		UserID:             userID,
		Timestamp:          timestamp,
		PreviousStreakDays: currentStreak.CurrentStreakDays,
		Notes:              notes,
		PostMortemPrompted: true,
		CreatedAt:          time.Now(),
	}

	if err := s.relapseRepo.CreateRelapse(ctx, relapse); err != nil {
		return nil, "", fmt.Errorf("creating relapse record: %w", err)
	}

	// Reset streak.
	if err := s.streakRepo.ResetStreak(ctx, addictionID, timestamp); err != nil {
		return nil, "", fmt.Errorf("resetting streak: %w", err)
	}

	// Invalidate cache.
	_ = s.cache.Invalidate(ctx, addictionID)

	// Publish relapse event.
	_ = s.events.PublishRelapseEvent(ctx, relapse)

	// Get updated streak.
	updatedStreak, err := s.GetStreak(ctx, addictionID)
	if err != nil {
		return nil, "", fmt.Errorf("retrieving updated streak: %w", err)
	}

	// Generate compassionate message.
	message := s.generateCompassionateMessage(currentStreak)

	return updatedStreak, message, nil
}

// GetMilestones retrieves earned and upcoming milestones for an addiction.
func (s *TrackingService) GetMilestones(ctx context.Context, addictionID string) ([]*Milestone, error) {
	if addictionID == "" {
		return nil, fmt.Errorf("addiction ID is required: %w", ErrInvalidInput)
	}

	milestones, err := s.milestoneRepo.GetAddictionMilestones(ctx, addictionID)
	if err != nil {
		return nil, fmt.Errorf("retrieving milestones: %w", err)
	}

	return milestones, nil
}

// CheckAndAwardMilestone checks if current streak matches a milestone threshold
// and creates a milestone achievement if so.
func (s *TrackingService) CheckAndAwardMilestone(ctx context.Context, addictionID string, streak *StreakData) (*Milestone, error) {
	if !IsMilestone(streak.CurrentStreakDays) {
		return nil, nil
	}

	// Check if milestone already awarded.
	milestones, err := s.milestoneRepo.GetAddictionMilestones(ctx, addictionID)
	if err != nil {
		return nil, fmt.Errorf("retrieving milestones: %w", err)
	}

	for _, m := range milestones {
		if m.Days == streak.CurrentStreakDays && m.AchievedAt != nil {
			// Already awarded.
			return m, nil
		}
	}

	// Award new milestone.
	now := time.Now()
	milestone := &Milestone{
		AddictionID:   addictionID,
		AddictionType: streak.AddictionType,
		Days:          streak.CurrentStreakDays,
		Label:         MilestoneLabel(streak.CurrentStreakDays),
		AchievedAt:    &now,
		Celebrated:    false,
		Scripture:     MilestoneScripture(streak.CurrentStreakDays),
	}

	if err := s.milestoneRepo.CreateMilestone(ctx, milestone); err != nil {
		return nil, fmt.Errorf("creating milestone: %w", err)
	}

	// Publish milestone event.
	_ = s.events.PublishMilestoneEvent(ctx, milestone)

	return milestone, nil
}

// GetCalendar retrieves calendar view for a month.
func (s *TrackingService) GetCalendar(ctx context.Context, userID string, month time.Time) ([]CalendarEntry, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required: %w", ErrInvalidInput)
	}

	entries, err := s.calendarRepo.GetCalendarMonth(ctx, userID, month)
	if err != nil {
		return nil, fmt.Errorf("retrieving calendar: %w", err)
	}

	return entries, nil
}

// GetCalendarRange retrieves calendar view for a custom date range.
func (s *TrackingService) GetCalendarRange(ctx context.Context, userID string, startDate, endDate time.Time) ([]CalendarEntry, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required: %w", ErrInvalidInput)
	}

	entries, err := s.calendarRepo.GetCalendarRange(ctx, userID, startDate, endDate)
	if err != nil {
		return nil, fmt.Errorf("retrieving calendar range: %w", err)
	}

	return entries, nil
}

// GetCalendarDay retrieves detailed information for a specific day.
func (s *TrackingService) GetCalendarDay(ctx context.Context, userID string, date time.Time) (*CalendarDayData, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required: %w", ErrInvalidInput)
	}

	dayData, err := s.calendarRepo.GetCalendarDay(ctx, userID, date)
	if err != nil {
		return nil, fmt.Errorf("retrieving calendar day: %w", err)
	}

	return dayData, nil
}

// generateCompassionateMessage generates an encouraging message after relapse.
func (s *TrackingService) generateCompassionateMessage(streak *StreakData) string {
	return fmt.Sprintf(
		"Your %d-day streak has been preserved in your history. You were sober %d out of the last %d days — that matters.",
		streak.CurrentStreakDays,
		streak.TotalSoberDaysLast365,
		365,
	)
}
