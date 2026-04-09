// internal/domain/affirmations/reengagement.go
package affirmations

import (
	"time"
)

// ReengagementStrategy represents the type of re-engagement approach.
type ReengagementStrategy string

const (
	ReengagementStrategyNone  ReengagementStrategy = "none"
	ReengagementStrategy3Day  ReengagementStrategy = "3day"
	ReengagementStrategy7Day  ReengagementStrategy = "7day"
	ReengagementStrategy14Day ReengagementStrategy = "14day"
)

// ReengagementResult holds the re-engagement strategy and message.
type ReengagementResult struct {
	Strategy                  ReengagementStrategy `json:"strategy"`
	Message                   string               `json:"message"`
	AffirmationCount          int                  `json:"affirmationCount"`          // Number of affirmations to show
	ResetToLevel1             bool                 `json:"resetToLevel1"`             // Offer fresh Level 1 session
	SuggestTherapistReconnect bool                 `json:"suggestTherapistReconnect"` // Suggest reconnecting with support
}

// DetermineReengagementStrategy determines the appropriate re-engagement approach
// based on the gap since last session.
//
// Gap thresholds:
// - 3 days: Single affirmation with gentle prompt
// - 7 days: Fresh Level 1 session option with courage-focused message
// - 14+ days: Therapist/partner reconnect prompt
//
// ALL messages use compassionate language, NEVER shame-based.
func DetermineReengagementStrategy(lastSessionTime time.Time, currentTime time.Time) ReengagementResult {
	daysSinceLastSession := int(currentTime.Sub(lastSessionTime).Hours() / 24)

	// 14+ day gap
	if daysSinceLastSession >= 14 {
		return ReengagementResult{
			Strategy:                  ReengagementStrategy14Day,
			Message:                   "Welcome back. Recovery is a journey with many paths. Would you like to reconnect with your support network?",
			AffirmationCount:          3,
			ResetToLevel1:             true,
			SuggestTherapistReconnect: true,
		}
	}

	// 7-13 day gap
	if daysSinceLastSession >= 7 {
		return ReengagementResult{
			Strategy:         ReengagementStrategy7Day,
			Message:          "Coming back is an act of courage. Would you like to start fresh with a Level 1 session?",
			AffirmationCount: 3,
			ResetToLevel1:    true,
		}
	}

	// 3-6 day gap
	if daysSinceLastSession >= 3 {
		return ReengagementResult{
			Strategy:         ReengagementStrategy3Day,
			Message:          "Ready when you are.",
			AffirmationCount: 1,
		}
	}

	// Less than 3 days: no special strategy
	return ReengagementResult{
		Strategy: ReengagementStrategyNone,
	}
}
