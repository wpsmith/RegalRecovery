// internal/domain/activities/repository.go
package activities

import (
	"context"
	"time"
)

// ActivityRepository defines the interface for activity data persistence.
type ActivityRepository interface {
	// CreateActivity creates a new activity log entry.
	CreateActivity(ctx context.Context, activity *Activity) error

	// GetActivity retrieves a specific activity by ID.
	GetActivity(ctx context.Context, activityID string) (*Activity, error)

	// GetUserActivities retrieves activities for a user with pagination.
	// Returns activities and the next cursor for pagination.
	GetUserActivities(ctx context.Context, userID string, activityType string, cursor string, limit int) ([]*Activity, string, error)

	// GetUserActivitiesByDate retrieves all activities for a user on a specific date.
	GetUserActivitiesByDate(ctx context.Context, userID string, date time.Time) ([]*Activity, error)

	// GetUserActivitiesInRange retrieves activities for a user within a date range.
	GetUserActivitiesInRange(ctx context.Context, userID string, startDate, endDate time.Time, activityType string) ([]*Activity, error)

	// DeleteActivity deletes an activity (admin only or ephemeral cleanup).
	DeleteActivity(ctx context.Context, activityID string) error

	// DeleteEphemeralActivities deletes ephemeral activities older than the retention period.
	DeleteEphemeralActivities(ctx context.Context, olderThan time.Time) error
}
