// internal/domain/devotionals/series.go
package devotionals

import (
	"context"
	"errors"
	"fmt"
	"time"
)

var (
	// ErrSeriesNotFound indicates the devotional series was not found.
	ErrSeriesNotFound = errors.New("series not found")

	// ErrSeriesNotOwned indicates the user has not purchased the premium series.
	ErrSeriesNotOwned = errors.New("series not purchased")
)

// SeriesProgressionService manages series progression and activation.
type SeriesProgressionService struct {
	progressRepo SeriesProgressRepository
	seriesRepo   DevotionalSeriesRepository
}

// NewSeriesProgressionService creates a new SeriesProgressionService.
func NewSeriesProgressionService(progressRepo SeriesProgressRepository, seriesRepo DevotionalSeriesRepository) *SeriesProgressionService {
	return &SeriesProgressionService{
		progressRepo: progressRepo,
		seriesRepo:   seriesRepo,
	}
}

// AdvanceSeriesDay increments the current day for the user's active series
// after a devotional completion. Does NOT auto-advance on missed days.
func (s *SeriesProgressionService) AdvanceSeriesDay(ctx context.Context, userID, seriesID string) (*SeriesProgressDoc, error) {
	progress, err := s.progressRepo.Get(ctx, userID, seriesID)
	if err != nil {
		return nil, fmt.Errorf("getting series progress: %w", err)
	}
	if progress == nil {
		return nil, ErrSeriesNotFound
	}

	series, err := s.seriesRepo.GetByID(ctx, seriesID)
	if err != nil || series == nil {
		return nil, ErrSeriesNotFound
	}

	now := time.Now().UTC()
	progress.CompletedDays++
	progress.LastCompletedAt = &now
	progress.ModifiedAt = now

	// Advance to next day if not at the end
	if progress.CurrentDay < series.TotalDays {
		progress.CurrentDay++
	} else {
		// Series completed
		progress.Status = SeriesCompleted
	}

	if err := s.progressRepo.Upsert(ctx, userID, progress); err != nil {
		return nil, fmt.Errorf("updating series progress: %w", err)
	}

	return progress, nil
}

// ActivateSeries sets a series as the user's active reading plan.
// If the user has another active series, it is paused at its current position.
func (s *SeriesProgressionService) ActivateSeries(ctx context.Context, userID, seriesID string, isOwned bool) (*ActivateSeriesResponse, error) {
	// Verify series exists
	series, err := s.seriesRepo.GetByID(ctx, seriesID)
	if err != nil || series == nil {
		return nil, ErrSeriesNotFound
	}

	// Check ownership for premium series
	if series.Tier == TierPremium && !isOwned {
		return nil, ErrSeriesNotOwned
	}

	var pausedSeries *PausedSeries
	now := time.Now().UTC()

	// Pause any currently active series
	active, err := s.progressRepo.GetActive(ctx, userID)
	if err == nil && active != nil && active.SeriesID != seriesID {
		active.Status = SeriesPaused
		active.PausedAt = &now
		active.ModifiedAt = now
		if err := s.progressRepo.Upsert(ctx, userID, active); err != nil {
			return nil, fmt.Errorf("pausing active series: %w", err)
		}
		pausedSeries = &PausedSeries{
			SeriesID:    active.SeriesID,
			PausedAtDay: active.CurrentDay,
		}
	}

	// Get or create progress for the target series
	progress, err := s.progressRepo.Get(ctx, userID, seriesID)
	if err != nil || progress == nil {
		// First time starting this series
		progress = &SeriesProgressDoc{
			PK:            fmt.Sprintf("USER#%s", userID),
			SK:            fmt.Sprintf("DEVSERIES#%s", seriesID),
			EntityType:    "DEVOTIONAL_SERIES_PROGRESS",
			TenantID:      "DEFAULT",
			CreatedAt:     now,
			SeriesID:      seriesID,
			CurrentDay:    1,
			CompletedDays: 0,
			Status:        SeriesActive,
			StartedAt:     &now,
		}
	} else {
		// Resume paused series at its current position
		progress.Status = SeriesActive
		progress.PausedAt = nil
	}
	progress.ModifiedAt = now

	if err := s.progressRepo.Upsert(ctx, userID, progress); err != nil {
		return nil, fmt.Errorf("activating series: %w", err)
	}

	resp := &ActivateSeriesResponse{}
	resp.Data.ActiveSeriesID = seriesID
	resp.Data.CurrentDay = progress.CurrentDay
	resp.Data.TotalDays = series.TotalDays
	resp.Data.PausedSeries = pausedSeries

	return resp, nil
}

// GetSeriesProgress retrieves progress for a specific series.
func (s *SeriesProgressionService) GetSeriesProgress(ctx context.Context, userID, seriesID string) (*SeriesProgressDoc, error) {
	return s.progressRepo.Get(ctx, userID, seriesID)
}

// GetNextSeriesDevotionalDay returns the day number the user should read next.
// Missed days do NOT auto-advance (AC-DEV-SERIES-02).
func GetNextSeriesDevotionalDay(progress *SeriesProgressDoc) int {
	if progress == nil {
		return 1
	}
	return progress.CurrentDay
}
