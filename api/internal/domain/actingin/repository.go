// internal/domain/actingin/repository.go
package actingin

import (
	"context"
	"time"
)

// ActingInRepository defines the interface for acting-in data persistence.
type ActingInRepository interface {
	// GetBehaviorConfig retrieves the user's behavior configuration.
	// Returns nil if no configuration exists (new user).
	GetBehaviorConfig(ctx context.Context, userID string) (*BehaviorConfig, error)

	// SaveBehaviorConfig creates or updates the user's behavior configuration.
	SaveBehaviorConfig(ctx context.Context, config *BehaviorConfig) error

	// GetSettings retrieves the user's acting-in settings.
	// Returns nil if no settings exist (new user).
	GetSettings(ctx context.Context, userID string) (*Settings, error)

	// SaveSettings creates or updates the user's acting-in settings.
	SaveSettings(ctx context.Context, settings *Settings) error

	// CreateCheckIn persists a new check-in record.
	CreateCheckIn(ctx context.Context, checkIn *CheckIn) error

	// GetCheckIn retrieves a specific check-in by ID.
	GetCheckIn(ctx context.Context, userID, checkInID string) (*CheckIn, error)

	// ListCheckIns retrieves check-ins with cursor-based pagination and optional filters.
	ListCheckIns(ctx context.Context, userID string, filters CheckInFilters, cursor string, limit int) ([]CheckIn, string, error)

	// GetCheckInsByDateRange retrieves all check-ins in a date range.
	GetCheckInsByDateRange(ctx context.Context, userID string, start, end time.Time) ([]CheckIn, error)

	// GetCheckInDates retrieves the timestamps of all check-ins for streak calculation.
	GetCheckInDates(ctx context.Context, userID string) ([]time.Time, error)

	// CreateCalendarActivity writes the dual-write calendar activity entry.
	CreateCalendarActivity(ctx context.Context, userID string, checkIn *CheckIn) error
}

// CheckInFilters represents optional filters for listing check-ins.
type CheckInFilters struct {
	StartDate       *time.Time
	EndDate         *time.Time
	BehaviorID      string
	Trigger         Trigger
	RelationshipTag RelationshipTag
}

// CrossToolDataProvider defines the interface for fetching cross-tool data.
// Each tool's repository implements this so we can query them for correlations.
type CrossToolDataProvider interface {
	// GetPciData retrieves PCI scores for the given user and date range.
	GetPciData(ctx context.Context, userID string, start, end time.Time) ([]PciDayData, error)

	// GetFasterData retrieves FASTER Scale entries for the given user and date range.
	GetFasterData(ctx context.Context, userID string, start, end time.Time) ([]FasterEntry, error)

	// GetPostMortemData retrieves post-mortem entries for the given user.
	GetPostMortemData(ctx context.Context, userID string) ([]PostMortemEntry, error)
}

// InsightsCacheProvider defines the interface for insights caching (Valkey).
type InsightsCacheProvider interface {
	// GetCachedInsights retrieves cached insights for the given user and range.
	GetCachedInsights(ctx context.Context, userID string, r InsightsRange, target interface{}) error

	// SetCachedInsights stores insights in the cache with a TTL.
	SetCachedInsights(ctx context.Context, userID string, r InsightsRange, data interface{}, ttl time.Duration) error

	// InvalidateInsightsCache invalidates all cached insights for the user.
	InvalidateInsightsCache(ctx context.Context, userID string) error
}
