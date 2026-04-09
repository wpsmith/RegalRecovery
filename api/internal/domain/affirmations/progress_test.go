// internal/domain/affirmations/progress_test.go
package affirmations

import (
	"fmt"
	"strings"
	"testing"
	"time"
)

// Progress Tests (CRITICAL: cumulative only, NEVER streaks)

func TestAffirmations_Progress_CumulativeSessionCount_NeverStreakBased(t *testing.T) {
	t.Parallel()

	// Sessions with gaps (NO streaks)
	sessions := []SessionCompletion{
		{CompletedAt: parseTime("2025-01-01T09:00:00Z")},
		{CompletedAt: parseTime("2025-01-02T09:00:00Z")},
		// 5-day gap
		{CompletedAt: parseTime("2025-01-07T09:00:00Z")},
		{CompletedAt: parseTime("2025-01-08T09:00:00Z")},
	}

	progress := CalculateProgress(sessions, 0, 0, 0)

	// Total sessions = 4, regardless of gaps
	if progress.TotalSessions != 4 {
		t.Errorf("Expected 4 total sessions (cumulative), got %d", progress.TotalSessions)
	}

	// Verify NO streak field exists
	if hasStreakField(progress) {
		t.Error("Progress must NOT contain any streak-related fields")
	}
}

func TestAffirmations_Progress_CumulativeAffirmationCount(t *testing.T) {
	t.Parallel()

	// Morning sessions: 3 affirmations each
	// Evening sessions: 1 affirmation each
	// SOS sessions: 3 affirmations each
	sessions := []SessionCompletion{
		{SessionType: SessionTypeMorning, AffirmationCount: 3},
		{SessionType: SessionTypeEvening, AffirmationCount: 1},
		{SessionType: SessionTypeSOS, AffirmationCount: 3},
	}

	progress := CalculateProgress(sessions, 0, 0, 0)

	expectedTotal := 3 + 1 + 3
	if progress.TotalAffirmations != expectedTotal {
		t.Errorf("Expected %d total affirmations (cumulative), got %d", expectedTotal, progress.TotalAffirmations)
	}
}

func TestAffirmations_Progress_NoStreakCounterAnywhere(t *testing.T) {
	t.Parallel()

	sessions := []SessionCompletion{
		{CompletedAt: parseTime("2025-01-01T09:00:00Z")},
		{CompletedAt: parseTime("2025-01-02T09:00:00Z")},
		{CompletedAt: parseTime("2025-01-03T09:00:00Z")},
	}

	progress := CalculateProgress(sessions, 0, 0, 0)

	// Verify progress struct has NO streak field
	progressJSON := structToString(progress)
	if strings.Contains(strings.ToLower(progressJSON), "streak") {
		t.Errorf("Progress struct must NOT contain 'streak' anywhere. Found: %s", progressJSON)
	}
}

func TestAffirmations_Progress_MilestoneDetection_1_10_25_50_100_250(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name              string
		sessionCount      int
		expectedMilestone bool
		milestoneType     string
	}{
		{"First session", 1, true, "1_sessions"},
		{"Ten sessions", 10, true, "10_sessions"},
		{"Twenty-five sessions", 25, true, "25_sessions"},
		{"Fifty sessions", 50, true, "50_sessions"},
		{"One hundred sessions", 100, true, "100_sessions"},
		{"Two hundred fifty sessions", 250, true, "250_sessions"},
		{"Non-milestone", 15, false, ""},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			sessions := make([]SessionCompletion, tt.sessionCount)
			for i := range sessions {
				sessions[i] = SessionCompletion{CompletedAt: parseTime("2025-01-01T09:00:00Z")}
			}

			progress := CalculateProgress(sessions, 0, 0, 0)
			milestone := DetectMilestone(progress, sessions, 0, 0, 0)

			if tt.expectedMilestone && milestone == nil {
				t.Errorf("Expected milestone at %d sessions, got nil", tt.sessionCount)
			}

			if !tt.expectedMilestone && milestone != nil {
				t.Errorf("Expected no milestone at %d sessions, got %v", tt.sessionCount, milestone)
			}

			if tt.expectedMilestone && milestone != nil && milestone.Type != tt.milestoneType {
				t.Errorf("Expected milestone type %q, got %q", tt.milestoneType, milestone.Type)
			}
		})
	}
}

func TestAffirmations_Progress_MilestoneDetection_FirstCustomCreated(t *testing.T) {
	t.Parallel()

	sessions := []SessionCompletion{}
	customCount := 1 // First custom affirmation

	progress := CalculateProgress(sessions, customCount, 0, 0)
	milestone := DetectMilestone(progress, sessions, customCount, 0, 0)

	if milestone == nil {
		t.Error("Expected milestone for first custom affirmation")
	}

	if milestone != nil && milestone.Type != "first_custom" {
		t.Errorf("Expected milestone type 'first_custom', got %q", milestone.Type)
	}
}

func TestAffirmations_Progress_MilestoneDetection_FirstAudioSaved(t *testing.T) {
	t.Parallel()

	sessions := []SessionCompletion{}
	audioCount := 1 // First audio recording

	progress := CalculateProgress(sessions, 0, audioCount, 0)
	milestone := DetectMilestone(progress, sessions, 0, audioCount, 0)

	if milestone == nil {
		t.Error("Expected milestone for first audio recording")
	}

	if milestone != nil && milestone.Type != "first_audio" {
		t.Errorf("Expected milestone type 'first_audio', got %q", milestone.Type)
	}
}

func TestAffirmations_Progress_MilestoneDetection_FirstSOSCompleted(t *testing.T) {
	t.Parallel()

	sessions := []SessionCompletion{
		{SessionType: SessionTypeSOS},
	}

	progress := CalculateProgress(sessions, 0, 0, 1)
	milestone := DetectMilestone(progress, sessions, 0, 0, 1)

	if milestone == nil {
		t.Error("Expected milestone for first SOS session")
	}

	if milestone != nil && milestone.Type != "first_sos" {
		t.Errorf("Expected milestone type 'first_sos', got %q", milestone.Type)
	}
}

// Helper functions

func parseTime(s string) time.Time {
	t, _ := time.Parse(time.RFC3339, s)
	return t
}

func hasStreakField(progress AffirmationProgress) bool {
	// Check if struct contains any field with "streak" in its name
	progressStr := structToString(progress)
	return strings.Contains(strings.ToLower(progressStr), "streak")
}

func structToString(v interface{}) string {
	// Simple string representation for field checking
	return strings.ToLower(fmt.Sprintf("%+v", v))
}
