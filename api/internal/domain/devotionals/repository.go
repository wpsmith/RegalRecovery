// internal/domain/devotionals/repository.go
package devotionals

import "context"

// DevotionalContentRepository defines the persistence interface for devotional content.
type DevotionalContentRepository interface {
	// GetByID retrieves a devotional by its ID.
	GetByID(ctx context.Context, devotionalID string) (*DevotionalContent, error)

	// GetByFreemiumDay retrieves the devotional for a given day in the 30-day free rotation.
	GetByFreemiumDay(ctx context.Context, day int) (*DevotionalContent, error)

	// GetBySeriesAndDay retrieves a devotional for a specific series and day.
	GetBySeriesAndDay(ctx context.Context, seriesID string, day int) (*DevotionalContent, error)

	// List retrieves paginated devotionals with optional filters.
	List(ctx context.Context, params ListDevotionalsParams) ([]DevotionalContent, string, error)

	// Search performs full-text search across devotional content.
	Search(ctx context.Context, query string, limit int) ([]DevotionalContent, error)
}

// DevotionalCompletionRepository defines the persistence interface for completions.
type DevotionalCompletionRepository interface {
	// Save persists a new devotional completion and writes the calendar activity entry.
	Save(ctx context.Context, userID string, completion *CompletionDoc) error

	// GetByID retrieves a completion by its ID.
	GetByID(ctx context.Context, userID, completionID string) (*CompletionDoc, error)

	// Update updates the mutable fields (reflection, moodTag) of a completion.
	Update(ctx context.Context, userID string, completion *CompletionDoc) error

	// GetByDevotionalAndDate checks if a completion already exists for a devotional on a given date.
	GetByDevotionalAndDate(ctx context.Context, userID, devotionalID, date string) (*CompletionDoc, error)

	// ListByDateRange retrieves completions within a date range, sorted by timestamp.
	ListByDateRange(ctx context.Context, userID string, params ListHistoryParams) ([]CompletionDoc, string, error)
}

// DevotionalFavoriteRepository defines the persistence interface for favorites.
type DevotionalFavoriteRepository interface {
	// Add adds a devotional to favorites. Idempotent (no error on duplicate).
	Add(ctx context.Context, userID string, favorite *FavoriteDoc) error

	// Remove removes a devotional from favorites.
	Remove(ctx context.Context, userID, devotionalID string) error

	// List retrieves the user's favorite devotionals.
	List(ctx context.Context, userID, cursor string, limit int) ([]FavoriteDoc, string, error)

	// IsFavorite checks if a devotional is in the user's favorites.
	IsFavorite(ctx context.Context, userID, devotionalID string) (bool, error)
}

// SeriesProgressRepository defines the persistence interface for series progress.
type SeriesProgressRepository interface {
	// Get retrieves the user's progress for a specific series.
	Get(ctx context.Context, userID, seriesID string) (*SeriesProgressDoc, error)

	// GetActive retrieves the user's currently active series progress.
	GetActive(ctx context.Context, userID string) (*SeriesProgressDoc, error)

	// Upsert creates or updates series progress.
	Upsert(ctx context.Context, userID string, progress *SeriesProgressDoc) error

	// ListAll retrieves all series progress for a user.
	ListAll(ctx context.Context, userID string) ([]SeriesProgressDoc, error)
}

// DevotionalSeriesRepository defines the persistence interface for series metadata.
type DevotionalSeriesRepository interface {
	// GetByID retrieves a series by its ID.
	GetByID(ctx context.Context, seriesID string) (*SeriesContent, error)

	// List retrieves available series with optional tier filter.
	List(ctx context.Context, tier *ContentTier, cursor string, limit int) ([]SeriesContent, string, error)
}

// DevotionalStreakRepository defines the persistence interface for streak data.
type DevotionalStreakRepository interface {
	// Get retrieves the user's devotional streak.
	Get(ctx context.Context, userID string) (*StreakDoc, error)

	// Upsert creates or updates the streak record.
	Upsert(ctx context.Context, userID string, streak *StreakDoc) error
}
