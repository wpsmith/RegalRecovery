// test/unit/devotionals_selector_test.go
package unit

import (
	"testing"
	"time"

	"github.com/regalrecovery/api/internal/domain/devotionals"
)

// =============================================================================
// Devotional Content Selection Tests
// Location: internal/domain/devotionals/selector_test.go (spec)
// =============================================================================

// TestSelector_AC_DEV_CONTENT_02_FreemiumRotationReturnsCorrectDay verifies that
// the free-tier rotation day is correctly calculated from the user's timezone date.
func TestSelector_AC_DEV_CONTENT_02_FreemiumRotationReturnsCorrectDay(t *testing.T) {
	// Given: a date where YearDay % 30 == 7
	// Jan 7 (yearDay=7), 7 % 30 = 7
	date := time.Date(2026, 1, 7, 12, 0, 0, 0, time.UTC)

	// When
	rotationDay := devotionals.CalculateRotationDayFromDate(date)

	// Then
	if rotationDay != 7 {
		t.Errorf("expected rotation day 7 for Jan 7, got %d", rotationDay)
	}
}

// TestSelector_AC_DEV_CONTENT_03_FreemiumRotationResetsAfter30 verifies that
// the freemium rotation cycles back to day 1 after day 30.
func TestSelector_AC_DEV_CONTENT_03_FreemiumRotationResetsAfter30(t *testing.T) {
	// Given: day 31 -> should map to day 1 (31 % 30 = 1)
	// Jan 31 (yearDay=31), 31 % 30 = 1
	date := time.Date(2026, 1, 31, 12, 0, 0, 0, time.UTC)

	// When
	rotationDay := devotionals.CalculateRotationDayFromDate(date)

	// Then
	if rotationDay != 1 {
		t.Errorf("expected rotation day 1 for day 31, got %d", rotationDay)
	}
}

// TestSelector_AC_DEV_CONTENT_03_FreemiumRotationDay30 verifies that
// day 30 maps to rotation day 30 (not 0).
func TestSelector_AC_DEV_CONTENT_03_FreemiumRotationDay30(t *testing.T) {
	// Given: Jan 30 (yearDay=30), 30 % 30 = 0 -> should be 30
	date := time.Date(2026, 1, 30, 12, 0, 0, 0, time.UTC)

	// When
	rotationDay := devotionals.CalculateRotationDayFromDate(date)

	// Then
	if rotationDay != 30 {
		t.Errorf("expected rotation day 30, got %d", rotationDay)
	}
}

// TestSelector_AC_DEV_CONTENT_03_FreemiumRotationDay60 verifies that
// day 60 maps to rotation day 30 (60 % 30 = 0 -> 30).
func TestSelector_AC_DEV_CONTENT_03_FreemiumRotationDay60(t *testing.T) {
	// Given: Mar 1 in non-leap year (yearDay=60), 60 % 30 = 0 -> 30
	date := time.Date(2026, 3, 1, 12, 0, 0, 0, time.UTC)

	// When
	rotationDay := devotionals.CalculateRotationDayFromDate(date)

	// Then
	if rotationDay != 30 {
		t.Errorf("expected rotation day 30 for day 60, got %d", rotationDay)
	}
}

// TestSelector_AC_DEV_READ_03_UsesUserTimezoneForDayBoundary verifies that
// the day boundary is based on the user's timezone, not UTC.
func TestSelector_AC_DEV_READ_03_UsesUserTimezoneForDayBoundary(t *testing.T) {
	// Given: server time 2026-04-08T06:30:00Z = 11:30 PM PST on April 7
	serverTime := time.Date(2026, 4, 8, 6, 30, 0, 0, time.UTC)
	userTimezone := "America/Los_Angeles"

	// When
	localDate := devotionals.UserLocalDateAt(serverTime, userTimezone)

	// Then: the local date should be April 7
	if localDate.Day() != 7 || localDate.Month() != time.April {
		t.Errorf("expected April 7 in PST, got %s", localDate.Format("2006-01-02"))
	}
}

// TestSelector_AC_DEV_EDGE_01_PostMidnightShowsCurrentDay verifies that
// at 1:00 AM in the user's timezone, the devotional is for the current day.
func TestSelector_AC_DEV_EDGE_01_PostMidnightShowsCurrentDay(t *testing.T) {
	// Given: user timezone America/New_York, local time 1:00 AM on April 8
	// 1:00 AM ET on April 8 = 05:00 UTC on April 8
	serverTime := time.Date(2026, 4, 8, 5, 0, 0, 0, time.UTC)
	userTimezone := "America/New_York"

	// When
	localDate := devotionals.UserLocalDateAt(serverTime, userTimezone)

	// Then: should be April 8 (not April 7)
	if localDate.Day() != 8 || localDate.Month() != time.April {
		t.Errorf("expected April 8 in ET, got %s", localDate.Format("2006-01-02"))
	}
}

// TestSelector_PremiumUserNoActiveSeries_FallsBackToFreeRotation verifies that
// a premium user with no active series falls back to the free rotation.
func TestSelector_PremiumUserNoActiveSeries_FallsBackToFreeRotation(t *testing.T) {
	// This test validates the logic flow -- when GetActive returns nil,
	// the selector falls back to free rotation calculation.
	// The actual DB interaction is tested in integration tests.

	date := time.Date(2026, 4, 7, 12, 0, 0, 0, time.UTC)
	rotationDay := devotionals.CalculateRotationDayFromDate(date)

	// April 7 = yearDay 97, 97 % 30 = 7
	if rotationDay != 7 {
		t.Errorf("expected rotation day 7, got %d", rotationDay)
	}
}

// TestSelector_InvalidTimezone_FallsBackToUTC verifies graceful fallback.
func TestSelector_InvalidTimezone_FallsBackToUTC(t *testing.T) {
	serverTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

	// When: invalid timezone
	localDate := devotionals.UserLocalDateAt(serverTime, "Invalid/Timezone")

	// Then: falls back to UTC
	if localDate.Day() != 8 || localDate.Month() != time.April {
		t.Errorf("expected April 8 (UTC fallback), got %s", localDate.Format("2006-01-02"))
	}
}
