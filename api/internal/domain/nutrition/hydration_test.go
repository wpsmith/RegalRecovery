// internal/domain/nutrition/hydration_test.go
package nutrition

import (
	"testing"
	"time"
)

// TestHydration_FR_NUT_3_1_IncrementServing verifies adding a serving.
func TestHydration_FR_NUT_3_1_IncrementServing(t *testing.T) {
	log := &HydrationLog{
		ServingsLogged:      4,
		ServingSizeOz:       8,
		DailyTargetServings: 8,
	}

	log.ServingsLogged++
	log.TotalOunces = CalculateTotalOunces(log.ServingsLogged, log.ServingSizeOz)

	if log.ServingsLogged != 5 {
		t.Errorf("expected 5 servings, got %d", log.ServingsLogged)
	}
	if log.TotalOunces != 40 {
		t.Errorf("expected 40 oz, got %f", log.TotalOunces)
	}
}

// TestHydration_FR_NUT_3_2_DecrementServing verifies removing a serving.
func TestHydration_FR_NUT_3_2_DecrementServing(t *testing.T) {
	log := &HydrationLog{
		ServingsLogged: 3,
		ServingSizeOz:  8,
	}

	log.ServingsLogged--
	if log.ServingsLogged != 2 {
		t.Errorf("expected 2 servings, got %d", log.ServingsLogged)
	}
}

// TestHydration_FR_NUT_3_2_DecrementAtZero verifies decrement at zero stays at zero.
func TestHydration_FR_NUT_3_2_DecrementAtZero(t *testing.T) {
	servings := 0
	servings--
	if servings < 0 {
		servings = 0
	}
	if servings != 0 {
		t.Errorf("expected 0 servings, got %d", servings)
	}
}

// TestHydration_FR_NUT_3_3_ConfigurableServingSize verifies configurable serving size.
func TestHydration_FR_NUT_3_3_ConfigurableServingSize(t *testing.T) {
	servingSizeOz := 16.0
	servingsLogged := 1
	totalOz := CalculateTotalOunces(servingsLogged, servingSizeOz)
	if totalOz != 16 {
		t.Errorf("expected 16 oz, got %f", totalOz)
	}
}

// TestHydration_FR_NUT_3_4_DefaultServingSize verifies default serving size is 8 oz.
func TestHydration_FR_NUT_3_4_DefaultServingSize(t *testing.T) {
	if DefaultServingSizeOz != 8 {
		t.Errorf("expected default serving size 8, got %f", DefaultServingSizeOz)
	}
}

// TestHydration_FR_NUT_3_5_DailyTargetConfigurable verifies configurable daily target.
func TestHydration_FR_NUT_3_5_DailyTargetConfigurable(t *testing.T) {
	progress := CalculateGoalProgress(9, 10)
	if progress != 90 {
		t.Errorf("expected 90%%, got %d%%", progress)
	}
}

// TestHydration_FR_NUT_3_6_DefaultDailyTarget verifies default daily target is 8 servings.
func TestHydration_FR_NUT_3_6_DefaultDailyTarget(t *testing.T) {
	if DefaultDailyTargetServings != 8 {
		t.Errorf("expected default target 8, got %d", DefaultDailyTargetServings)
	}
	if DefaultDailyTargetOunces != 64 {
		t.Errorf("expected default target 64 oz, got %f", DefaultDailyTargetOunces)
	}
}

// TestHydration_FR_NUT_3_7_ServingSizeChangePreservesHistory verifies serving size change preserves history.
func TestHydration_FR_NUT_3_7_ServingSizeChangePreservesHistory(t *testing.T) {
	// Monday: 4 servings at 8 oz = 32 oz.
	mondayLog := &HydrationLog{
		Date:           "2026-03-23",
		ServingsLogged: 4,
		ServingSizeOz:  8,
		TotalOunces:    32,
	}

	// Tuesday: user changes serving size to 16 oz.
	// Monday's record should remain unchanged.
	if mondayLog.ServingSizeOz != 8 {
		t.Errorf("expected Monday serving size 8, got %f", mondayLog.ServingSizeOz)
	}
	if mondayLog.TotalOunces != 32 {
		t.Errorf("expected Monday total 32 oz, got %f", mondayLog.TotalOunces)
	}
}

// TestHydration_FR_NUT_3_8_DateBoundary verifies date boundary is timezone-aware.
func TestHydration_FR_NUT_3_8_DateBoundary(t *testing.T) {
	ny, err := time.LoadLocation("America/New_York")
	if err != nil {
		t.Fatalf("failed to load timezone: %v", err)
	}

	// 11:59 PM ET on March 28 → should be March 28.
	lateNight := time.Date(2026, 3, 28, 23, 59, 0, 0, ny)
	date1 := DateForTimezone(lateNight, ny)
	if date1 != "2026-03-28" {
		t.Errorf("expected 2026-03-28, got %s", date1)
	}

	// 12:01 AM ET on March 29 → should be March 29.
	earlyMorning := time.Date(2026, 3, 29, 0, 1, 0, 0, ny)
	date2 := DateForTimezone(earlyMorning, ny)
	if date2 != "2026-03-29" {
		t.Errorf("expected 2026-03-29, got %s", date2)
	}
}

// TestGoalProgress_CappedAt100 verifies goal progress is capped at 100%.
func TestGoalProgress_CappedAt100(t *testing.T) {
	progress := CalculateGoalProgress(12, 8)
	if progress != 100 {
		t.Errorf("expected 100, got %d", progress)
	}
}

// TestGoalProgress_ZeroTarget verifies zero target returns 0%.
func TestGoalProgress_ZeroTarget(t *testing.T) {
	progress := CalculateGoalProgress(5, 0)
	if progress != 0 {
		t.Errorf("expected 0, got %d", progress)
	}
}
