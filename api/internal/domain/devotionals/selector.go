// internal/domain/devotionals/selector.go
package devotionals

import (
	"context"
	"fmt"
	"time"
)

// DevotionalSelector determines which devotional to show for "today"
// based on user tier, active series, and timezone.
type DevotionalSelector struct {
	contentRepo DevotionalContentRepository
	seriesRepo  SeriesProgressRepository
}

// NewDevotionalSelector creates a new DevotionalSelector.
func NewDevotionalSelector(contentRepo DevotionalContentRepository, seriesRepo SeriesProgressRepository) *DevotionalSelector {
	return &DevotionalSelector{
		contentRepo: contentRepo,
		seriesRepo:  seriesRepo,
	}
}

// GetTodayDevotional returns today's devotional for the user.
// For premium users with an active series, it returns the next unread day.
// For free-tier users (or premium without active series), it returns from the 30-day rotation.
func (s *DevotionalSelector) GetTodayDevotional(ctx context.Context, userID string, userTimezone string, isPremium bool) (*DevotionalContent, error) {
	if isPremium {
		// Check for active series
		progress, err := s.seriesRepo.GetActive(ctx, userID)
		if err == nil && progress != nil {
			// Return the devotional for the user's current day in their active series
			content, err := s.contentRepo.GetBySeriesAndDay(ctx, progress.SeriesID, progress.CurrentDay)
			if err == nil && content != nil {
				return content, nil
			}
			// If series devotional not found, fall back to free rotation
		}
	}

	// Free-tier or no active series: use 30-day rotation
	rotationDay := CalculateFreemiumRotationDay(userTimezone)
	content, err := s.contentRepo.GetByFreemiumDay(ctx, rotationDay)
	if err != nil {
		return nil, fmt.Errorf("getting freemium devotional for day %d: %w", rotationDay, err)
	}
	return content, nil
}

// CalculateFreemiumRotationDay computes the rotation day (1-30) based on the user's
// local date. The rotation cycles: day 31 maps to day 1, day 32 to day 2, etc.
func CalculateFreemiumRotationDay(userTimezone string) int {
	userDate := UserLocalDate(userTimezone)
	return CalculateRotationDayFromDate(userDate)
}

// CalculateRotationDayFromDate computes the rotation day (1-30) from a date.
// Uses the day-of-year modulo 30, with 0 mapping to 30.
func CalculateRotationDayFromDate(date time.Time) int {
	dayOfYear := date.YearDay()
	rotationDay := dayOfYear % FreemiumRotationSize
	if rotationDay == 0 {
		rotationDay = FreemiumRotationSize
	}
	return rotationDay
}

// UserLocalDate returns the current date in the user's timezone.
// Falls back to UTC if the timezone is invalid.
func UserLocalDate(timezone string) time.Time {
	loc, err := time.LoadLocation(timezone)
	if err != nil {
		loc = time.UTC
	}
	return time.Now().In(loc)
}

// UserLocalDateAt returns the date at a given time in the user's timezone.
// This is useful for testing with deterministic times.
func UserLocalDateAt(t time.Time, timezone string) time.Time {
	loc, err := time.LoadLocation(timezone)
	if err != nil {
		loc = time.UTC
	}
	return t.In(loc)
}
