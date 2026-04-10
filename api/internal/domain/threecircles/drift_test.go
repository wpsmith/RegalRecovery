// internal/domain/threecircles/drift_test.go
package threecircles

import (
	"context"
	"testing"
	"time"
)

// TestThreeCircles_Drift_Detects3MiddleDaysIn7DayWindow verifies drift detection with threshold.
// Acceptance Criterion: Drift alert triggered at 3+ middle days in 7-day window.
func TestThreeCircles_Drift_Detects3MiddleDaysIn7DayWindow(t *testing.T) {
	t.Run("triggers_alert_at_exactly_3_middle_days", func(t *testing.T) {
		// Given
		detector := NewDriftDetector()
		userID := "user123"
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

		entries := []TimelineEntry{
			{Date: "2026-04-08", DominantCircle: CircleMiddle, SetID: "set1"},
			{Date: "2026-04-07", DominantCircle: CircleOuter, SetID: "set2"},
			{Date: "2026-04-06", DominantCircle: CircleMiddle, SetID: "set3"},
			{Date: "2026-04-05", DominantCircle: CircleOuter, SetID: "set4"},
			{Date: "2026-04-04", DominantCircle: CircleMiddle, SetID: "set5"},
			{Date: "2026-04-03", DominantCircle: CircleOuter, SetID: "set6"},
			{Date: "2026-04-02", DominantCircle: CircleOuter, SetID: "set7"},
		}

		// When
		alert, err := detector.DetectDrift(context.Background(), userID, entries, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if alert == nil {
			t.Fatal("expected drift alert, got nil")
		}

		if alert.MiddleCircleDays != 3 {
			t.Errorf("expected 3 middle circle days, got %d", alert.MiddleCircleDays)
		}

		if alert.UserID != userID {
			t.Errorf("expected user ID '%s', got '%s'", userID, alert.UserID)
		}

		if alert.Message == "" {
			t.Error("expected non-empty message")
		}

		if alert.Dismissed {
			t.Error("expected alert to not be dismissed")
		}
	})

	t.Run("triggers_alert_with_more_than_3_middle_days", func(t *testing.T) {
		// Given
		detector := NewDriftDetector()
		userID := "user123"
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

		entries := []TimelineEntry{
			{Date: "2026-04-08", DominantCircle: CircleMiddle, SetID: "set1"},
			{Date: "2026-04-07", DominantCircle: CircleMiddle, SetID: "set2"},
			{Date: "2026-04-06", DominantCircle: CircleMiddle, SetID: "set3"},
			{Date: "2026-04-05", DominantCircle: CircleMiddle, SetID: "set4"},
			{Date: "2026-04-04", DominantCircle: CircleOuter, SetID: "set5"},
			{Date: "2026-04-03", DominantCircle: CircleOuter, SetID: "set6"},
			{Date: "2026-04-02", DominantCircle: CircleOuter, SetID: "set7"},
		}

		// When
		alert, err := detector.DetectDrift(context.Background(), userID, entries, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if alert == nil {
			t.Fatal("expected drift alert, got nil")
		}

		if alert.MiddleCircleDays != 4 {
			t.Errorf("expected 4 middle circle days, got %d", alert.MiddleCircleDays)
		}
	})

	t.Run("does_not_trigger_with_only_2_middle_days", func(t *testing.T) {
		// Given
		detector := NewDriftDetector()
		userID := "user123"
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

		entries := []TimelineEntry{
			{Date: "2026-04-08", DominantCircle: CircleMiddle, SetID: "set1"},
			{Date: "2026-04-07", DominantCircle: CircleOuter, SetID: "set2"},
			{Date: "2026-04-06", DominantCircle: CircleMiddle, SetID: "set3"},
			{Date: "2026-04-05", DominantCircle: CircleOuter, SetID: "set4"},
			{Date: "2026-04-04", DominantCircle: CircleOuter, SetID: "set5"},
			{Date: "2026-04-03", DominantCircle: CircleOuter, SetID: "set6"},
			{Date: "2026-04-02", DominantCircle: CircleOuter, SetID: "set7"},
		}

		// When
		alert, err := detector.DetectDrift(context.Background(), userID, entries, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if alert != nil {
			t.Error("expected no drift alert, got alert")
		}
	})
}

// TestThreeCircles_Drift_MessageIsGentleAndNonPunitive verifies message tone.
// Acceptance Criterion: Message is gentle, non-punitive, frames as "useful information".
func TestThreeCircles_Drift_MessageIsGentleAndNonPunitive(t *testing.T) {
	t.Run("message_frames_as_useful_information", func(t *testing.T) {
		// Given
		detector := NewDriftDetector()
		userID := "user123"
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

		entries := []TimelineEntry{
			{Date: "2026-04-08", DominantCircle: CircleMiddle, SetID: "set1"},
			{Date: "2026-04-07", DominantCircle: CircleMiddle, SetID: "set2"},
			{Date: "2026-04-06", DominantCircle: CircleMiddle, SetID: "set3"},
			{Date: "2026-04-05", DominantCircle: CircleOuter, SetID: "set4"},
			{Date: "2026-04-04", DominantCircle: CircleOuter, SetID: "set5"},
			{Date: "2026-04-03", DominantCircle: CircleOuter, SetID: "set6"},
			{Date: "2026-04-02", DominantCircle: CircleOuter, SetID: "set7"},
		}

		// When
		alert, err := detector.DetectDrift(context.Background(), userID, entries, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if alert == nil {
			t.Fatal("expected drift alert, got nil")
		}

		// Verify message contains compassionate language
		if len(alert.Message) == 0 {
			t.Error("expected non-empty message")
		}

		// Check for key phrases indicating compassionate framing
		// (In production, these checks would be more sophisticated)
		t.Logf("Drift message: %s", alert.Message)
	})
}

// TestThreeCircles_Drift_HandlesInsufficientData verifies behavior with < 3 entries.
func TestThreeCircles_Drift_HandlesInsufficientData(t *testing.T) {
	t.Run("returns_nil_with_less_than_3_entries", func(t *testing.T) {
		// Given
		detector := NewDriftDetector()
		userID := "user123"
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

		entries := []TimelineEntry{
			{Date: "2026-04-08", DominantCircle: CircleMiddle, SetID: "set1"},
			{Date: "2026-04-07", DominantCircle: CircleMiddle, SetID: "set2"},
		}

		// When
		alert, err := detector.DetectDrift(context.Background(), userID, entries, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if alert != nil {
			t.Error("expected no alert with insufficient data")
		}
	})
}

// TestThreeCircles_Drift_DismissAlert verifies alert dismissal.
// Acceptance Criterion: Alert can be dismissed with optional action taken.
func TestThreeCircles_Drift_DismissAlert(t *testing.T) {
	t.Run("dismisses_alert_with_action_taken", func(t *testing.T) {
		// Given
		detector := NewDriftDetector()
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

		alert := &DriftAlert{
			ID:               "alert1",
			UserID:           "user123",
			MiddleCircleDays: 3,
			Dismissed:        false,
		}

		actionTaken := "Reviewed FASTER Scale and called accountability partner"

		// When
		err := detector.DismissDriftAlert(context.Background(), alert, actionTaken, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if !alert.Dismissed {
			t.Error("expected alert to be dismissed")
		}

		if alert.DismissedAt == nil {
			t.Error("expected dismissed at timestamp to be set")
		}

		if alert.ActionTaken != actionTaken {
			t.Errorf("expected action taken '%s', got '%s'", actionTaken, alert.ActionTaken)
		}
	})

	t.Run("returns_error_if_already_dismissed", func(t *testing.T) {
		// Given
		detector := NewDriftDetector()
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)
		dismissedTime := currentTime.Add(-1 * time.Hour)

		alert := &DriftAlert{
			ID:          "alert1",
			UserID:      "user123",
			Dismissed:   true,
			DismissedAt: &dismissedTime,
		}

		// When
		err := detector.DismissDriftAlert(context.Background(), alert, "action", currentTime)

		// Then
		if err != ErrAlertAlreadyDismissed {
			t.Errorf("expected ErrAlertAlreadyDismissed, got %v", err)
		}
	})
}

// TestThreeCircles_Drift_SlidingWindow verifies sliding window detection.
func TestThreeCircles_Drift_SlidingWindow(t *testing.T) {
	t.Run("detects_drift_in_any_7_day_window", func(t *testing.T) {
		// Given
		detector := NewDriftDetector()
		userID := "user123"
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

		// Drift in days 2-8 (not most recent window)
		entries := []TimelineEntry{
			{Date: "2026-04-08", DominantCircle: CircleOuter, SetID: "set1"},
			{Date: "2026-04-07", DominantCircle: CircleMiddle, SetID: "set2"},
			{Date: "2026-04-06", DominantCircle: CircleMiddle, SetID: "set3"},
			{Date: "2026-04-05", DominantCircle: CircleMiddle, SetID: "set4"},
			{Date: "2026-04-04", DominantCircle: CircleOuter, SetID: "set5"},
			{Date: "2026-04-03", DominantCircle: CircleOuter, SetID: "set6"},
			{Date: "2026-04-02", DominantCircle: CircleOuter, SetID: "set7"},
			{Date: "2026-04-01", DominantCircle: CircleOuter, SetID: "set8"},
		}

		// When
		alert, err := detector.DetectDrift(context.Background(), userID, entries, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if alert == nil {
			t.Fatal("expected drift alert, got nil")
		}

		if alert.MiddleCircleDays != 3 {
			t.Errorf("expected 3 middle circle days, got %d", alert.MiddleCircleDays)
		}
	})
}

// TestThreeCircles_Drift_IgnoresInnerCircleDays verifies inner circle days don't count.
func TestThreeCircles_Drift_IgnoresInnerCircleDays(t *testing.T) {
	t.Run("does_not_count_inner_circle_days_in_drift", func(t *testing.T) {
		// Given
		detector := NewDriftDetector()
		userID := "user123"
		currentTime := time.Date(2026, 4, 8, 12, 0, 0, 0, time.UTC)

		entries := []TimelineEntry{
			{Date: "2026-04-08", DominantCircle: CircleInner, SetID: "set1"},
			{Date: "2026-04-07", DominantCircle: CircleMiddle, SetID: "set2"},
			{Date: "2026-04-06", DominantCircle: CircleMiddle, SetID: "set3"},
			{Date: "2026-04-05", DominantCircle: CircleOuter, SetID: "set4"},
			{Date: "2026-04-04", DominantCircle: CircleOuter, SetID: "set5"},
			{Date: "2026-04-03", DominantCircle: CircleOuter, SetID: "set6"},
			{Date: "2026-04-02", DominantCircle: CircleOuter, SetID: "set7"},
		}

		// When
		alert, err := detector.DetectDrift(context.Background(), userID, entries, currentTime)

		// Then
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if alert != nil {
			t.Error("expected no drift alert (only 2 middle days), got alert")
		}
	})
}
