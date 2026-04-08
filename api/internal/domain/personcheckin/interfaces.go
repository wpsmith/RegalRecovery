// internal/domain/personcheckin/interfaces.go
package personcheckin

import (
	"context"
	"time"
)

// CheckInRepository defines the interface for person check-in data persistence.
type CheckInRepository interface {
	// Create persists a new person check-in and dual-writes to calendar activities.
	Create(ctx context.Context, checkIn *PersonCheckIn) error

	// GetByID retrieves a single check-in by its ID for a user.
	GetByID(ctx context.Context, userID, checkInID string) (*PersonCheckIn, error)

	// List retrieves check-ins for a user with filtering, sorting, and pagination.
	List(ctx context.Context, userID string, params ListCheckInsParams) ([]PersonCheckIn, string, error)

	// Update partially updates a check-in (immutable fields are protected).
	Update(ctx context.Context, checkIn *PersonCheckIn) error

	// Delete removes a check-in and its calendar activity entry.
	Delete(ctx context.Context, userID, checkInID string) error

	// GetByUserAndType retrieves check-ins for a user filtered by sub-type.
	GetByUserAndType(ctx context.Context, userID string, checkInType CheckInType, startDate, endDate time.Time) ([]PersonCheckIn, error)

	// GetCalendarMonth retrieves calendar data for a month.
	GetCalendarMonth(ctx context.Context, userID string, month string) ([]CalendarDay, error)
}

// StreakRepository defines the interface for person check-in streak persistence.
type StreakRepository interface {
	// GetAllStreaks retrieves all sub-type streaks for a user.
	GetAllStreaks(ctx context.Context, userID string) ([]PersonCheckInStreak, error)

	// GetStreakByType retrieves a single sub-type streak for a user.
	GetStreakByType(ctx context.Context, userID string, checkInType CheckInType) (*PersonCheckInStreak, error)

	// SaveStreak creates or updates a streak record.
	SaveStreak(ctx context.Context, userID string, streak *PersonCheckInStreak) error
}

// SettingsRepository defines the interface for person check-in settings persistence.
type SettingsRepository interface {
	// Get retrieves settings for a user, returning defaults if none exist.
	Get(ctx context.Context, userID string) (*PersonCheckInSettings, error)

	// Save creates or updates settings for a user.
	Save(ctx context.Context, settings *PersonCheckInSettings) error
}

// StreakCache defines the interface for caching streak data.
type StreakCache interface {
	// Get retrieves cached streak data for a user and sub-type.
	Get(ctx context.Context, userID string, checkInType CheckInType) (*PersonCheckInStreak, error)

	// Set caches streak data with TTL in seconds.
	Set(ctx context.Context, userID string, checkInType CheckInType, streak *PersonCheckInStreak, ttlSeconds int) error

	// Invalidate removes cached streak data for a user and sub-type.
	Invalidate(ctx context.Context, userID string, checkInType CheckInType) error

	// InvalidateAll removes all cached streak data for a user.
	InvalidateAll(ctx context.Context, userID string) error
}

// EventPublisher defines the interface for publishing domain events.
type EventPublisher interface {
	// PublishCheckInCreated publishes a check-in created event.
	PublishCheckInCreated(ctx context.Context, checkIn *PersonCheckIn) error

	// PublishCheckInDeleted publishes a check-in deleted event.
	PublishCheckInDeleted(ctx context.Context, userID, checkInID string, checkInType CheckInType) error

	// PublishStreakMilestone publishes a streak milestone event.
	PublishStreakMilestone(ctx context.Context, userID string, checkInType CheckInType, streak int) error

	// PublishInactivityAlert publishes an inactivity alert event.
	PublishInactivityAlert(ctx context.Context, alert *InactivityAlert) error
}

// GoalService defines the interface for creating goals from follow-up items.
type GoalService interface {
	// CreateGoalFromFollowUp creates a goal entity from a follow-up item text.
	CreateGoalFromFollowUp(ctx context.Context, userID, followUpText string) (string, error)
}

// PermissionChecker defines the interface for checking data access permissions.
type PermissionChecker interface {
	// HasPermission checks if a viewer has permission to see a user's person check-in data.
	HasPermission(ctx context.Context, ownerUserID, viewerUserID, dataCategory string) (bool, error)

	// GetViewerRole returns the role of the viewer (spouse, sponsor, counselor, etc.).
	GetViewerRole(ctx context.Context, ownerUserID, viewerUserID string) (string, error)
}
