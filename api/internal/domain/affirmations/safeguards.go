// internal/domain/affirmations/safeguards.go
package affirmations

import (
	"time"
)

// SafeguardAction represents the action to take based on clinical safeguard detection.
type SafeguardAction string

const (
	SafeguardActionNone               SafeguardAction = "none"
	SafeguardActionTherapistPrompt    SafeguardAction = "therapistPrompt"
	SafeguardActionCrisisBypass       SafeguardAction = "crisisBypass"
	SafeguardActionRejectionFlag      SafeguardAction = "rejectionFlag"
	SafeguardActionPostRelapseSupport SafeguardAction = "postRelapseSupport"
)

// SafeguardResult holds the result of clinical safeguard detection.
type SafeguardResult struct {
	Action             SafeguardAction `json:"action"`
	Message            string          `json:"message"`
	BypassAffirmations bool            `json:"bypassAffirmations"` // True for crisis bypass
	FlagForReview      bool            `json:"flagForReview"`      // True for persistent rejection
	MaxLevel           Level           `json:"maxLevel,omitempty"` // For post-relapse lock
}

// DetectWorseningMood detects 3+ consecutive declining mood ratings.
// Triggers therapist prompt when detected.
// "Consecutive" means the last 3 sessions show uninterrupted decline with NO improvements
// in the immediate history leading up to them.
func DetectWorseningMood(history []EveningSession) SafeguardResult {
	if len(history) < 3 {
		return SafeguardResult{Action: SafeguardActionNone}
	}

	// Check last 3 sessions for strictly declining trend
	lastThree := history[len(history)-3:]

	// Verify last 3 are strictly declining: session[0] > session[1] > session[2]
	if !(lastThree[0].DayRating > lastThree[1].DayRating &&
		lastThree[1].DayRating > lastThree[2].DayRating) {
		return SafeguardResult{Action: SafeguardActionNone}
	}

	// Check if there was any improvement in the session immediately before the last 3
	// This breaks the "consecutive" pattern
	if len(history) > 3 {
		// Check the transition into the declining window
		fourthFromEnd := history[len(history)-4]
		if lastThree[0].DayRating > fourthFromEnd.DayRating {
			// There was an improvement (4th < 3rd from end), pattern is broken
			return SafeguardResult{Action: SafeguardActionNone}
		}
	}

	// Found 3 consecutive declining sessions with no recent improvement
	return SafeguardResult{
		Action: SafeguardActionTherapistPrompt,
		Message: "We've noticed your mood has been declining over the past few days. " +
			"Would you like to connect with your therapist or accountability partner? " +
			"You don't have to navigate this alone.",
	}
}

// DetectCrisis detects crisis state (two consecutive ratings of 1/5).
// Routes directly to crisis resources, bypassing affirmations.
func DetectCrisis(history []EveningSession) SafeguardResult {
	if len(history) < 2 {
		return SafeguardResult{Action: SafeguardActionNone}
	}

	// Check last two sessions
	lastTwo := history[len(history)-2:]
	if lastTwo[0].DayRating == 1 && lastTwo[1].DayRating == 1 {
		return SafeguardResult{
			Action:             SafeguardActionCrisisBypass,
			Message:            "We're here for you. Let's connect you with immediate support resources.",
			BypassAffirmations: true,
		}
	}

	return SafeguardResult{Action: SafeguardActionNone}
}

// DetectPersistentRejection detects when a user hides 5+ affirmations in a single session.
// Flags for clinical review when threshold exceeded.
func DetectPersistentRejection(hiddenCountInSession int) SafeguardResult {
	if hiddenCountInSession >= 5 {
		return SafeguardResult{
			Action:        SafeguardActionRejectionFlag,
			Message:       "You've hidden several affirmations. Would you like to adjust your content preferences or talk to someone about what's not resonating?",
			FlagForReview: true,
		}
	}

	return SafeguardResult{Action: SafeguardActionNone}
}

// DetectPostRelapse detects post-relapse state (within 24 hours of relapse).
// Locks to Level 1 and provides compassionate grounding message.
func DetectPostRelapse(lastRelapseTimestamp *time.Time, currentTime time.Time) SafeguardResult {
	if lastRelapseTimestamp == nil {
		return SafeguardResult{Action: SafeguardActionNone}
	}

	hoursSinceRelapse := currentTime.Sub(*lastRelapseTimestamp).Hours()
	if hoursSinceRelapse < 24 {
		return SafeguardResult{
			Action: SafeguardActionPostRelapseSupport,
			Message: "Recovery is not about perfection. It takes courage and strength to continue. " +
				"You are worthy of healing, and we're here to support you through this moment.",
			MaxLevel: LevelPermission,
		}
	}

	return SafeguardResult{Action: SafeguardActionNone}
}
