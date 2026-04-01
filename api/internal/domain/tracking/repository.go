// internal/domain/tracking/repository.go
package tracking

import (
	"context"
	"time"
)

// StreakRepository defines the interface for streak data persistence.
type StreakRepository interface {
	// GetStreak retrieves streak data for a specific addiction.
	GetStreak(ctx context.Context, addictionID string) (*StreakData, error)

	// GetUserStreaks retrieves all streaks for a user.
	GetUserStreaks(ctx context.Context, userID string) ([]*StreakData, error)

	// UpdateStreak updates streak data.
	UpdateStreak(ctx context.Context, streak *StreakData) error

	// ResetStreak resets a streak after a relapse.
	ResetStreak(ctx context.Context, addictionID string, relapseDate time.Time) error
}

// MilestoneRepository defines the interface for milestone data persistence.
type MilestoneRepository interface {
	// GetMilestone retrieves a specific milestone.
	GetMilestone(ctx context.Context, milestoneID string) (*Milestone, error)

	// GetAddictionMilestones retrieves all milestones for an addiction.
	GetAddictionMilestones(ctx context.Context, addictionID string) ([]*Milestone, error)

	// GetUserMilestones retrieves all milestones for a user.
	GetUserMilestones(ctx context.Context, userID string) ([]*Milestone, error)

	// CreateMilestone creates a new milestone achievement.
	CreateMilestone(ctx context.Context, milestone *Milestone) error

	// UpdateMilestone updates milestone information.
	UpdateMilestone(ctx context.Context, milestone *Milestone) error
}

// RelapseRepository defines the interface for relapse data persistence.
type RelapseRepository interface {
	// GetRelapse retrieves a specific relapse record.
	GetRelapse(ctx context.Context, relapseID string) (*Relapse, error)

	// GetAddictionRelapses retrieves all relapses for an addiction.
	GetAddictionRelapses(ctx context.Context, addictionID string, startDate, endDate time.Time) ([]*Relapse, error)

	// GetUserRelapses retrieves all relapses for a user.
	GetUserRelapses(ctx context.Context, userID string, startDate, endDate time.Time) ([]*Relapse, error)

	// CreateRelapse creates a new relapse record.
	CreateRelapse(ctx context.Context, relapse *Relapse) error
}

// CalendarRepository defines the interface for calendar data.
type CalendarRepository interface {
	// GetCalendarMonth retrieves calendar data for a month.
	GetCalendarMonth(ctx context.Context, userID string, month time.Time) ([]CalendarEntry, error)

	// GetCalendarRange retrieves calendar data for a date range.
	GetCalendarRange(ctx context.Context, userID string, startDate, endDate time.Time) ([]CalendarEntry, error)

	// GetCalendarDay retrieves detailed data for a specific day.
	GetCalendarDay(ctx context.Context, userID string, date time.Time) (*CalendarDayData, error)
}

// StreakCache defines the interface for streak caching.
type StreakCache interface {
	// Get retrieves streak data from cache.
	Get(ctx context.Context, addictionID string) (*StreakData, error)

	// Set stores streak data in cache with TTL.
	Set(ctx context.Context, addictionID string, streak *StreakData, ttl int) error

	// Invalidate removes streak data from cache.
	Invalidate(ctx context.Context, addictionID string) error
}

// EventPublisher defines the interface for publishing domain events.
type EventPublisher interface {
	// PublishRelapseEvent publishes a relapse event.
	PublishRelapseEvent(ctx context.Context, relapse *Relapse) error

	// PublishMilestoneEvent publishes a milestone achievement event.
	PublishMilestoneEvent(ctx context.Context, milestone *Milestone) error

	// PublishStreakResetEvent publishes a streak reset event.
	PublishStreakResetEvent(ctx context.Context, addictionID string, previousDays int) error
}
