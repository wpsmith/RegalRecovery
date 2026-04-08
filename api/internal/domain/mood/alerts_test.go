// internal/domain/mood/alerts_test.go
package mood

import "testing"

func TestMood_AC025_SustainedLowMood_ThreeDays(t *testing.T) {
	// Given: daily averages of [2.0, 1.5, 1.8] for last 3 days (most recent first)
	dailyAverages := []float64{2.0, 1.5, 1.8}

	// When: alert check is evaluated
	consecutiveLow, sustained := EvaluateSustainedLowMood(dailyAverages)

	// Then: sustainedLowMood = true, consecutiveLowDays = 3
	if !sustained {
		t.Error("expected sustainedLowMood = true")
	}
	if consecutiveLow != 3 {
		t.Errorf("expected consecutiveLowDays = 3, got %d", consecutiveLow)
	}
}

func TestMood_AC025_SustainedLowMood_TwoDays(t *testing.T) {
	// Given: daily averages of [2.0, 1.5] for last 2 days (threshold not met)
	dailyAverages := []float64{2.0, 1.5}

	// When: alert check is evaluated
	consecutiveLow, sustained := EvaluateSustainedLowMood(dailyAverages)

	// Then: sustainedLowMood = false, consecutiveLowDays = 2
	if sustained {
		t.Error("expected sustainedLowMood = false for only 2 days")
	}
	if consecutiveLow != 2 {
		t.Errorf("expected consecutiveLowDays = 2, got %d", consecutiveLow)
	}
}

func TestMood_AC025_SustainedLowMood_BrokenByOkayDay(t *testing.T) {
	// Given: daily averages of [1.8, 3.0, 1.5] (most recent first, broken by 3.0)
	// The 1.8 is most recent, then 3.0 breaks it
	dailyAverages := []float64{1.8, 3.0, 1.5}

	// When: alert check is evaluated
	consecutiveLow, sustained := EvaluateSustainedLowMood(dailyAverages)

	// Then: sustainedLowMood = false, consecutiveLowDays = 1
	if sustained {
		t.Error("expected sustainedLowMood = false when broken by okay day")
	}
	if consecutiveLow != 1 {
		t.Errorf("expected consecutiveLowDays = 1, got %d", consecutiveLow)
	}
}

func TestMood_AC027_SustainedLowMood_NoAutoShare(t *testing.T) {
	// Given: sustained low mood detected AND user has NOT enabled sharing
	sustainedLowMood := true
	sharingEnabled := false

	// When: sharing decision is evaluated
	shouldShare := ShouldShareAlert(sustainedLowMood, sharingEnabled)

	// Then: alertSharedWithNetwork = false
	if shouldShare {
		t.Error("expected alertSharedWithNetwork = false when sharing is disabled")
	}
}

func TestMood_AC026_SustainedLowMood_ShareEnabled(t *testing.T) {
	// Given: sustained low mood detected AND user HAS enabled low mood alert sharing
	sustainedLowMood := true
	sharingEnabled := true

	// When: sharing decision is evaluated
	shouldShare := ShouldShareAlert(sustainedLowMood, sharingEnabled)

	// Then: alertSharedWithNetwork = true
	if !shouldShare {
		t.Error("expected alertSharedWithNetwork = true when sharing is enabled")
	}
}

func TestMood_AC029_CrisisEntry_NoAutoNotification(t *testing.T) {
	// Given: crisis entry (rating = 1)
	// Then: ShouldShareAlert is false regardless of sharing settings
	// because crisis does NOT trigger sustained low mood
	shouldShare := ShouldShareAlert(false, true)
	if shouldShare {
		t.Error("expected no auto-share for single crisis entry (not sustained)")
	}
}

func TestMood_CrisisDetection(t *testing.T) {
	// Crisis is rating 1
	if !IsCrisisEntry(1) {
		t.Error("expected IsCrisisEntry(1) to be true")
	}
	if IsCrisisEntry(2) {
		t.Error("expected IsCrisisEntry(2) to be false")
	}
	if IsCrisisEntry(5) {
		t.Error("expected IsCrisisEntry(5) to be false")
	}
}

func TestMood_SustainedLowMood_EmptyDays(t *testing.T) {
	// Given: no daily averages
	dailyAverages := []float64{}

	// When: alert check is evaluated
	consecutiveLow, sustained := EvaluateSustainedLowMood(dailyAverages)

	// Then: no alert
	if sustained {
		t.Error("expected no sustained low mood for empty data")
	}
	if consecutiveLow != 0 {
		t.Errorf("expected 0 consecutive low days, got %d", consecutiveLow)
	}
}

func TestMood_SustainedLowMood_ExactThreshold(t *testing.T) {
	// Given: daily averages exactly at 2.0 for 3 days
	dailyAverages := []float64{2.0, 2.0, 2.0}

	// When: alert check is evaluated
	consecutiveLow, sustained := EvaluateSustainedLowMood(dailyAverages)

	// Then: sustained = true (threshold is <=2.0)
	if !sustained {
		t.Error("expected sustained low mood at exactly 2.0 threshold")
	}
	if consecutiveLow != 3 {
		t.Errorf("expected 3 consecutive low days, got %d", consecutiveLow)
	}
}

func TestMood_SustainedLowMood_JustAboveThreshold(t *testing.T) {
	// Given: daily averages at 2.1 (just above threshold)
	dailyAverages := []float64{2.1, 2.1, 2.1}

	// When: alert check is evaluated
	consecutiveLow, sustained := EvaluateSustainedLowMood(dailyAverages)

	// Then: not sustained (2.1 > 2.0)
	if sustained {
		t.Error("expected no sustained low mood at 2.1 (above threshold)")
	}
	if consecutiveLow != 0 {
		t.Errorf("expected 0 consecutive low days, got %d", consecutiveLow)
	}
}
