package gratitude

import (
	"context"
	"time"
)

// Repository defines the interface for gratitude data persistence.
type Repository interface {
	// CreateEntry creates a new gratitude entry.
	CreateEntry(ctx context.Context, entry *Entry) error

	// GetEntry retrieves a gratitude entry by ID.
	GetEntry(ctx context.Context, gratitudeID string) (*Entry, error)

	// UpdateEntry updates an existing gratitude entry.
	// Returns ErrEditWindowExpired if the entry is past the 24-hour window.
	UpdateEntry(ctx context.Context, entry *Entry) error

	// DeleteEntry deletes a gratitude entry.
	// Returns ErrEditWindowExpired if the entry is past the 24-hour window.
	DeleteEntry(ctx context.Context, gratitudeID string) error

	// ListEntries retrieves entries for a user with filtering and pagination.
	ListEntries(ctx context.Context, userID string, filters ListFilters, cursor string, limit int) ([]*Entry, string, error)

	// GetEntriesForDate retrieves all entries for a user on a specific date.
	GetEntriesForDate(ctx context.Context, userID string, date time.Time) ([]*Entry, error)

	// GetCalendarDays returns dates with entry counts for a given month.
	GetCalendarDays(ctx context.Context, userID string, year int, month int) ([]CalendarDay, error)

	// SearchEntries performs full-text search across gratitude item text fields.
	SearchEntries(ctx context.Context, userID string, query string, cursor string, limit int) ([]*Entry, string, int, error)

	// GetFavoriteItems retrieves all individually favorited items across all entries.
	GetFavoriteItems(ctx context.Context, userID string, cursor string, limit int) ([]FavoriteItemResult, string, error)

	// ToggleItemFavorite updates the isFavorite flag on a specific item.
	ToggleItemFavorite(ctx context.Context, gratitudeID string, itemID string, isFavorite bool) error

	// CountUserEntries returns the total number of entries for a user.
	CountUserEntries(ctx context.Context, userID string) (int, error)

	// GetAllEntryDates retrieves all unique dates with entries for streak computation.
	GetAllEntryDates(ctx context.Context, userID string) ([]time.Time, error)
}

// ListFilters holds filter parameters for listing entries.
type ListFilters struct {
	StartDate *time.Time
	EndDate   *time.Time
	Category  *string
	MoodScore *int
	HasPhoto  *bool
}

// FavoriteItemResult wraps a favorited item with its parent entry context.
type FavoriteItemResult struct {
	Item            Item      `json:"item"`
	ParentGratitudeID string `json:"parentGratitudeId"`
	ParentDate      time.Time `json:"parentDate"`
}
