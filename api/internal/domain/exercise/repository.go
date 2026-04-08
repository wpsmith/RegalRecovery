// internal/domain/exercise/repository.go
package exercise

import (
	"context"
	"time"
)

// ExerciseRepository defines the interface for exercise log data persistence.
type ExerciseRepository interface {
	// Create stores a new exercise log entry.
	Create(ctx context.Context, log ExerciseLog) error

	// GetByID retrieves a single exercise log by user ID and exercise ID.
	GetByID(ctx context.Context, userID, exerciseID string) (*ExerciseLog, error)

	// List retrieves exercise logs for a user with pagination and filtering.
	// Returns logs, next cursor, and error.
	List(ctx context.Context, userID string, opts ListOptions) ([]ExerciseLog, string, error)

	// Update modifies mutable fields of an exercise log.
	Update(ctx context.Context, userID, exerciseID string, updates map[string]interface{}) error

	// Delete removes an exercise log.
	Delete(ctx context.Context, userID, exerciseID string) error

	// GetByDateRange retrieves exercise logs within a date range.
	GetByDateRange(ctx context.Context, userID string, start, end time.Time) ([]ExerciseLog, error)

	// CountInWeek returns the number of exercise sessions in a given week.
	CountInWeek(ctx context.Context, userID string, weekStart time.Time) (int, error)

	// FindDuplicates searches for potential duplicate logs by activity type + time window or external ID.
	FindDuplicates(ctx context.Context, userID string, activityType string, timestamp time.Time, externalID *string) ([]ExerciseLog, error)
}

// FavoriteRepository defines the interface for exercise favorite data persistence.
type FavoriteRepository interface {
	// Create stores a new exercise favorite.
	Create(ctx context.Context, fav ExerciseFavorite) error

	// List retrieves all favorites for a user.
	List(ctx context.Context, userID string) ([]ExerciseFavorite, error)

	// Update replaces a favorite.
	Update(ctx context.Context, userID, favoriteID string, fav ExerciseFavorite) error

	// Delete removes a favorite.
	Delete(ctx context.Context, userID, favoriteID string) error

	// Count returns the number of favorites for a user.
	Count(ctx context.Context, userID string) (int, error)
}

// GoalRepository defines the interface for exercise goal data persistence.
type GoalRepository interface {
	// Get retrieves the weekly goal for a user.
	Get(ctx context.Context, userID string) (*ExerciseGoal, error)

	// Upsert creates or replaces the weekly goal for a user.
	Upsert(ctx context.Context, userID string, goal ExerciseGoal) error

	// Delete removes the weekly goal for a user.
	Delete(ctx context.Context, userID string) error
}
