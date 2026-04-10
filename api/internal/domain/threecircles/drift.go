// internal/domain/threecircles/drift.go
package threecircles

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
)

const (
	// DriftWindowDays is the sliding window size for drift detection (7 days).
	DriftWindowDays = 7

	// DriftThreshold is the minimum number of middle circle days in the window to trigger an alert (3).
	DriftThreshold = 3
)

// DriftDetector detects drift patterns when user contacts middle circle frequently.
type DriftDetector struct{}

// NewDriftDetector creates a new DriftDetector instance.
func NewDriftDetector() *DriftDetector {
	return &DriftDetector{}
}

// DetectDrift analyzes timeline entries for drift patterns.
// Triggers when 3+ middle circle days occur within a 7-day window.
// Returns a drift alert if pattern detected, nil otherwise.
func (dd *DriftDetector) DetectDrift(
	ctx context.Context,
	userID string,
	entries []TimelineEntry,
	currentTime time.Time,
) (*DriftAlert, error) {
	if len(entries) < DriftThreshold {
		return nil, nil // Not enough data
	}

	// Sort entries by date descending (most recent first)
	sortedEntries := sortEntriesByDate(entries, true)

	// Use sliding window to detect drift
	for i := 0; i <= len(sortedEntries)-DriftWindowDays; i++ {
		windowEntries := sortedEntries[i : i+DriftWindowDays]
		middleCircleDays := countMiddleCircleDays(windowEntries)

		if middleCircleDays >= DriftThreshold {
			// Drift detected
			windowStart, _ := time.Parse("2006-01-02", windowEntries[len(windowEntries)-1].Date)
			windowEnd, _ := time.Parse("2006-01-02", windowEntries[0].Date)
			mostRecentSetID := windowEntries[0].SetID

			alert := &DriftAlert{
				ID:               uuid.New().String(),
				SetID:            mostRecentSetID,
				UserID:           userID,
				WindowStart:      formatDate(windowStart),
				WindowEnd:        formatDate(windowEnd),
				MiddleCircleDays: middleCircleDays,
				Message:          dd.generateDriftMessage(middleCircleDays),
				Dismissed:        false,
				CreatedAt:        currentTime,
			}

			return alert, nil
		}
	}

	return nil, nil // No drift detected
}

// countMiddleCircleDays counts the number of middle circle days in the window.
func countMiddleCircleDays(entries []TimelineEntry) int {
	count := 0
	for _, entry := range entries {
		if entry.DominantCircle == CircleMiddle {
			count++
		}
	}
	return count
}

// generateDriftMessage creates a gentle, non-punitive drift alert message.
func (dd *DriftDetector) generateDriftMessage(middleCircleDays int) string {
	msg := fmt.Sprintf("You've been in your middle circle %d times this week. That's useful information. ", middleCircleDays)
	msg += "Middle circle behaviors can be a signal that something needs attention. "
	msg += "Consider reviewing your FASTER Scale or talking with your accountability partner."
	return msg
}

// sortEntriesByDate sorts timeline entries by date.
// If descending is true, sorts newest first; otherwise, oldest first.
func sortEntriesByDate(entries []TimelineEntry, descending bool) []TimelineEntry {
	sorted := make([]TimelineEntry, len(entries))
	copy(sorted, entries)

	// Simple bubble sort (good enough for typical dataset size)
	for i := 0; i < len(sorted)-1; i++ {
		for j := i + 1; j < len(sorted); j++ {
			date1, _ := time.Parse("2006-01-02", sorted[i].Date)
			date2, _ := time.Parse("2006-01-02", sorted[j].Date)

			shouldSwap := false
			if descending {
				shouldSwap = date1.Before(date2)
			} else {
				shouldSwap = date1.After(date2)
			}

			if shouldSwap {
				sorted[i], sorted[j] = sorted[j], sorted[i]
			}
		}
	}

	return sorted
}

// DismissDriftAlert marks a drift alert as dismissed with optional action taken.
func (dd *DriftDetector) DismissDriftAlert(
	ctx context.Context,
	alert *DriftAlert,
	actionTaken string,
	currentTime time.Time,
) error {
	if alert.Dismissed {
		return ErrAlertAlreadyDismissed
	}

	alert.Dismissed = true
	alert.DismissedAt = &currentTime
	alert.ActionTaken = actionTaken

	return nil
}
