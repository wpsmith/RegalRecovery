// internal/domain/affirmation/progress.go
package affirmation

import (
	"fmt"
	"time"
)

// ProgressRepository defines the interface for affirmation progress storage.
type ProgressRepository interface {
	RecordRead(userID string, read *AffirmationRead) error
	GetProgress(userID string) (*AffirmationProgress, error)
	IncrementProgress(userID string, category string, level int) error
	GetReadHistory(userID, startDate, endDate string) ([]AffirmationRead, error)
	HasReadToday(userID, calendarDate string) (bool, error)
}

// ProgressService tracks cumulative affirmation progress.
// No streak-based metrics -- only total counts (clinical requirement).
type ProgressService struct {
	repo ProgressRepository
}

// NewProgressService creates a new ProgressService.
func NewProgressService(repo ProgressRepository) *ProgressService {
	return &ProgressService{repo: repo}
}

// RecordRead records that a user has read an affirmation and updates cumulative progress.
func (s *ProgressService) RecordRead(userID string, aff *Affirmation, source ReadSource) error {
	now := time.Now().UTC()
	calendarDate := now.Format("2006-01-02")

	// Truncate statement for preview (100 chars)
	preview := aff.Statement
	if len(preview) > 100 {
		preview = preview[:97] + "..."
	}

	read := &AffirmationRead{
		AffirmationID: aff.AffirmationID,
		Statement:     preview,
		Category:      string(aff.Category),
		CalendarDate:  calendarDate,
		Source:        source,
		CreatedAt:     now,
	}

	if err := s.repo.RecordRead(userID, read); err != nil {
		return fmt.Errorf("failed to record read: %w", err)
	}

	if err := s.repo.IncrementProgress(userID, string(aff.Category), aff.Level); err != nil {
		return fmt.Errorf("failed to increment progress: %w", err)
	}

	return nil
}

// GetProgress returns the cumulative progress for a user.
func (s *ProgressService) GetProgress(userID string) (*AffirmationProgress, error) {
	return s.repo.GetProgress(userID)
}

// GetReadHistory returns paginated read history for a date range.
func (s *ProgressService) GetReadHistory(userID, startDate, endDate string) ([]AffirmationRead, error) {
	return s.repo.GetReadHistory(userID, startDate, endDate)
}

// HasReadToday returns whether the user has read an affirmation today.
func (s *ProgressService) HasReadToday(userID string) (bool, error) {
	calendarDate := time.Now().UTC().Format("2006-01-02")
	return s.repo.HasReadToday(userID, calendarDate)
}
