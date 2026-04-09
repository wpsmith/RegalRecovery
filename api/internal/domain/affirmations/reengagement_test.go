// internal/domain/affirmations/reengagement_test.go
package affirmations

import (
	"strings"
	"testing"
	"time"
)

// Re-engagement Tests

func TestAffirmations_Reengagement_3DayGap_SingleAffirmationPrompt(t *testing.T) {
	t.Parallel()

	lastSession := time.Now().Add(-72 * time.Hour) // 3 days ago
	currentTime := time.Now()

	result := DetermineReengagementStrategy(lastSession, currentTime)

	if result.Strategy != ReengagementStrategy3Day {
		t.Errorf("Expected 3-day strategy, got %s", result.Strategy)
	}

	if !strings.Contains(result.Message, "Ready when you are") {
		t.Errorf("Expected message containing 'Ready when you are', got %q", result.Message)
	}

	if result.AffirmationCount != 1 {
		t.Errorf("Expected 1 affirmation for 3-day gap, got %d", result.AffirmationCount)
	}
}

func TestAffirmations_Reengagement_7DayGap_FreshLevel1SessionOption(t *testing.T) {
	t.Parallel()

	lastSession := time.Now().Add(-7 * 24 * time.Hour) // 7 days ago
	currentTime := time.Now()

	result := DetermineReengagementStrategy(lastSession, currentTime)

	if result.Strategy != ReengagementStrategy7Day {
		t.Errorf("Expected 7-day strategy, got %s", result.Strategy)
	}

	if !strings.Contains(result.Message, "Coming back is an act of courage") {
		t.Errorf("Expected message containing 'Coming back is an act of courage', got %q", result.Message)
	}

	if result.ResetToLevel1 != true {
		t.Error("7-day gap should offer fresh Level 1 session option")
	}
}

func TestAffirmations_Reengagement_14DayGap_TherapistReconnectPrompt(t *testing.T) {
	t.Parallel()

	lastSession := time.Now().Add(-14 * 24 * time.Hour) // 14 days ago
	currentTime := time.Now()

	result := DetermineReengagementStrategy(lastSession, currentTime)

	if result.Strategy != ReengagementStrategy14Day {
		t.Errorf("Expected 14-day strategy, got %s", result.Strategy)
	}

	if !result.SuggestTherapistReconnect {
		t.Error("14+ day gap should suggest therapist reconnect")
	}

	if result.Message == "" {
		t.Error("Expected message for 14-day re-engagement")
	}
}

func TestAffirmations_Reengagement_NeverShameBased(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name       string
		daysAgo    int
		checkWords []string
	}{
		{"3 days", 3, []string{"should", "must", "failed", "disappointed", "shame", "guilt"}},
		{"7 days", 7, []string{"should", "must", "failed", "disappointed", "shame", "guilt"}},
		{"14 days", 14, []string{"should", "must", "failed", "disappointed", "shame", "guilt"}},
		{"30 days", 30, []string{"should", "must", "failed", "disappointed", "shame", "guilt"}},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			lastSession := time.Now().Add(-time.Duration(tt.daysAgo) * 24 * time.Hour)
			currentTime := time.Now()

			result := DetermineReengagementStrategy(lastSession, currentTime)

			message := strings.ToLower(result.Message)

			for _, word := range tt.checkWords {
				if strings.Contains(message, word) {
					t.Errorf("Message should not contain shame-based word %q, got message: %q", word, result.Message)
				}
			}
		})
	}
}

func TestAffirmations_Reengagement_2DayGap_NoSpecialStrategy(t *testing.T) {
	t.Parallel()

	lastSession := time.Now().Add(-48 * time.Hour) // 2 days ago
	currentTime := time.Now()

	result := DetermineReengagementStrategy(lastSession, currentTime)

	if result.Strategy != ReengagementStrategyNone {
		t.Errorf("Expected no special strategy for 2-day gap, got %s", result.Strategy)
	}
}

func TestAffirmations_Reengagement_1DayGap_NoSpecialStrategy(t *testing.T) {
	t.Parallel()

	lastSession := time.Now().Add(-24 * time.Hour) // 1 day ago
	currentTime := time.Now()

	result := DetermineReengagementStrategy(lastSession, currentTime)

	if result.Strategy != ReengagementStrategyNone {
		t.Errorf("Expected no special strategy for 1-day gap, got %s", result.Strategy)
	}
}

func TestAffirmations_Reengagement_30DayGap_ExtendedStrategy(t *testing.T) {
	t.Parallel()

	lastSession := time.Now().Add(-30 * 24 * time.Hour) // 30 days ago
	currentTime := time.Now()

	result := DetermineReengagementStrategy(lastSession, currentTime)

	// 30 days should use 14+ day strategy (therapist reconnect)
	if result.Strategy != ReengagementStrategy14Day {
		t.Errorf("Expected 14+ day strategy for 30-day gap, got %s", result.Strategy)
	}

	if !result.SuggestTherapistReconnect {
		t.Error("30-day gap should suggest therapist reconnect")
	}
}

func TestAffirmations_Reengagement_Messages_UseCompassionateLanguage(t *testing.T) {
	t.Parallel()

	gaps := []int{3, 7, 14}

	for _, days := range gaps {
		lastSession := time.Now().Add(-time.Duration(days) * 24 * time.Hour)
		currentTime := time.Now()

		result := DetermineReengagementStrategy(lastSession, currentTime)

		// All messages should contain at least one compassionate word
		compassionateWords := []string{"ready", "courage", "support", "here", "welcome", "strength"}
		found := false
		message := strings.ToLower(result.Message)

		for _, word := range compassionateWords {
			if strings.Contains(message, word) {
				found = true
				break
			}
		}

		if !found {
			t.Errorf("Message for %d-day gap should contain compassionate language, got: %q", days, result.Message)
		}
	}
}
