// internal/domain/mood/repository.go
package mood

import (
	"context"
	"time"
)

// MoodRepository defines the interface for mood data persistence.
// All methods enforce tenant isolation through the context (userID and tenantID).
type MoodRepository interface {
	// Create persists a new mood entry and writes the calendar activity dual-write.
	Create(ctx context.Context, entry *MoodEntry) error

	// GetByID retrieves a single mood entry by its moodId.
	GetByID(ctx context.Context, moodID string) (*MoodEntry, error)

	// ListByDateRange retrieves mood entries within a date range with cursor-based pagination.
	// Returns entries, next cursor, and error.
	ListByDateRange(ctx context.Context, userID string, start, end time.Time, cursor string, limit int) ([]MoodEntry, string, error)

	// ListByFilters retrieves mood entries matching the given filters.
	ListByFilters(ctx context.Context, userID string, filters MoodFilters, cursor string, limit int) ([]MoodEntry, string, error)

	// Update updates a mood entry (must be within 24h of creation).
	// Returns the updated entry or an error.
	Update(ctx context.Context, moodID string, req UpdateMoodEntryRequest) (*MoodEntry, error)

	// Delete removes a mood entry (must be within 24h of creation).
	Delete(ctx context.Context, moodID string) error

	// GetDailySummaries retrieves aggregated daily summaries for a date range.
	GetDailySummaries(ctx context.Context, userID string, start, end string) ([]DailySummary, error)

	// GetHourlyHeatmap retrieves average mood by hour for a given period.
	GetHourlyHeatmap(ctx context.Context, userID string, start, end time.Time) ([]HourBucket, error)

	// GetDayOfWeekAverages retrieves average mood by day of week.
	GetDayOfWeekAverages(ctx context.Context, userID string, start, end time.Time) ([]DayBucket, error)

	// GetEmotionLabelFrequency retrieves emotion label frequency counts.
	GetEmotionLabelFrequency(ctx context.Context, userID string, start, end time.Time) ([]LabelCount, error)

	// GetTodayEntries retrieves all mood entries for today.
	GetTodayEntries(ctx context.Context, userID string, datePartition string) ([]MoodEntry, error)

	// SearchByKeyword searches mood entries by keyword in context notes.
	SearchByKeyword(ctx context.Context, userID string, keyword string, cursor string, limit int) ([]MoodEntry, string, error)

	// CountConsecutiveLowDays counts consecutive days where the daily average is <= 2.0.
	CountConsecutiveLowDays(ctx context.Context, userID string) (int, error)

	// GetDistinctEntryDates returns distinct datePartition values for a user.
	GetDistinctEntryDates(ctx context.Context, userID string) ([]string, error)

	// GetLastCrisisEntry retrieves the most recent crisis-level entry.
	GetLastCrisisEntry(ctx context.Context, userID string) (*MoodEntry, error)
}

// MoodFilters holds optional filter parameters for listing mood entries.
type MoodFilters struct {
	Ratings       []int
	EmotionLabel  string
	TimeOfDay     string // morning, afternoon, evening, night
	Search        string
	StartDate     *time.Time
	EndDate       *time.Time
}
