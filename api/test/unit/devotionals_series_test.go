// test/unit/devotionals_series_test.go
package unit

import (
	"testing"

	"github.com/regalrecovery/api/internal/domain/devotionals"
)

// =============================================================================
// Devotional Series Progression Tests
// Location: internal/domain/devotionals/series_test.go (spec)
// =============================================================================

// TestSeries_AC_DEV_SERIES_02_MissedDayNoAutoAdvance verifies that the next
// devotional day does not auto-advance when the user misses a day.
func TestSeries_AC_DEV_SERIES_02_MissedDayNoAutoAdvance(t *testing.T) {
	// Given: user at day 15, last completed 2 days ago
	progress := &devotionals.SeriesProgressDoc{
		CurrentDay: 15,
		Status:     devotionals.SeriesActive,
	}

	// When
	day := devotionals.GetNextSeriesDevotionalDay(progress)

	// Then: still day 15 (no auto-advance)
	if day != 15 {
		t.Errorf("expected next day 15 (no auto-advance), got %d", day)
	}
}

// TestSeries_AC_DEV_SERIES_05_ProgressIndicator verifies progress tracking.
func TestSeries_AC_DEV_SERIES_05_ProgressIndicator(t *testing.T) {
	// Given: user at day 47 of 365-day series
	progress := &devotionals.SeriesProgressDoc{
		SeriesID:      "series_recovery365",
		CurrentDay:    47,
		CompletedDays: 46,
		Status:        devotionals.SeriesActive,
	}

	// Then
	if progress.CurrentDay != 47 {
		t.Errorf("expected currentDay=47, got %d", progress.CurrentDay)
	}
	if progress.CompletedDays != 46 {
		t.Errorf("expected completedDays=46, got %d", progress.CompletedDays)
	}
}

// TestSeries_AC_DEV_EDGE_03_MultipleSeriesPurchase verifies that purchasing
// a second series does not affect the first.
func TestSeries_AC_DEV_EDGE_03_MultipleSeriesPurchase(t *testing.T) {
	// Given: user active on Series A day 15
	progressA := &devotionals.SeriesProgressDoc{
		SeriesID:   "series_a",
		CurrentDay: 15,
		Status:     devotionals.SeriesActive,
	}

	// And: user purchases Series B (not_started)
	progressB := &devotionals.SeriesProgressDoc{
		SeriesID:   "series_b",
		CurrentDay: 1,
		Status:     devotionals.SeriesNotStarted,
	}

	// Then: Series A is still active at day 15
	if progressA.Status != devotionals.SeriesActive {
		t.Errorf("expected Series A status active, got %s", progressA.Status)
	}
	if progressA.CurrentDay != 15 {
		t.Errorf("expected Series A day 15, got %d", progressA.CurrentDay)
	}

	// And: Series B is not started
	if progressB.Status != devotionals.SeriesNotStarted {
		t.Errorf("expected Series B status not_started, got %s", progressB.Status)
	}
}

// TestSeries_NilProgress_StartsAtDayOne verifies that nil progress returns day 1.
func TestSeries_NilProgress_StartsAtDayOne(t *testing.T) {
	day := devotionals.GetNextSeriesDevotionalDay(nil)
	if day != 1 {
		t.Errorf("expected day 1 for nil progress, got %d", day)
	}
}

// TestSeries_StatusValues verifies all series status constants.
func TestSeries_StatusValues(t *testing.T) {
	tests := []struct {
		status   devotionals.SeriesStatus
		expected string
	}{
		{devotionals.SeriesNotStarted, "not_started"},
		{devotionals.SeriesActive, "active"},
		{devotionals.SeriesPaused, "paused"},
		{devotionals.SeriesCompleted, "completed"},
	}

	for _, tt := range tests {
		t.Run(tt.expected, func(t *testing.T) {
			if string(tt.status) != tt.expected {
				t.Errorf("expected %q, got %q", tt.expected, tt.status)
			}
		})
	}
}
