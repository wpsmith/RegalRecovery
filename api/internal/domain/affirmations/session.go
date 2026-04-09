// internal/domain/affirmations/session.go
package affirmations

import (
	"errors"
	"time"
)

var (
	// ErrSOSSessionLevelRestriction indicates an affirmation level exceeds SOS session limits.
	ErrSOSSessionLevelRestriction = errors.New("SOS sessions restricted to Level 1-2 only")
)

// MorningSession represents a morning affirmation session.
type MorningSession struct {
	Affirmations    []Affirmation `json:"affirmations"`    // 3 affirmations
	IntentionPrompt string        `json:"intentionPrompt"` // "Today I choose to..."
	DailyIntention  string        `json:"dailyIntention"`  // User's response to prompt
	Skipped         bool          `json:"skipped"`         // True if user skipped
	AffectsProgress bool          `json:"affectsProgress"` // False when skipped
	CompletedAt     time.Time     `json:"completedAt"`
}

// NewMorningSession creates a new morning session with 3 affirmations.
func NewMorningSession(affirmations []Affirmation) *MorningSession {
	return &MorningSession{
		Affirmations:    affirmations,
		IntentionPrompt: "Today I choose to...",
		AffectsProgress: true,  // True by default
		Skipped:         false, // Not skipped by default
	}
}

// Skip marks the session as skipped and sets AffectsProgress to false.
func (m *MorningSession) Skip() {
	m.Skipped = true
	m.AffectsProgress = false
}

// EveningSession represents an evening affirmation session.
type EveningSession struct {
	Affirmations     []Affirmation `json:"affirmations"`     // 1 affirmation
	MorningIntention string        `json:"morningIntention"` // Recall of morning intention
	DayRating        int           `json:"dayRating"`        // 1-5 scale
	Reflection       string        `json:"reflection"`       // Optional free text
	CompletedAt      time.Time     `json:"completedAt"`
}

// NewEveningSession creates a new evening session with 1 affirmation.
func NewEveningSession(affirmations []Affirmation, morningIntention string) *EveningSession {
	return &EveningSession{
		Affirmations:     affirmations,
		MorningIntention: morningIntention,
	}
}

// SOSSession represents a crisis/SOS affirmation session.
// Restricted to Level 1-2 only, regardless of user's normal progress level.
type SOSSession struct {
	Affirmations                        []Affirmation      `json:"affirmations"` // 3 affirmations (Level 1-2 only)
	BreathingExercise                   *BreathingExercise `json:"breathingExercise"`
	OffersAccountabilityPartnerReachOut bool               `json:"offersAccountabilityPartnerReachOut"`
	CompletedAt                         time.Time          `json:"completedAt"`
}

// BreathingExercise represents a guided breathing exercise for crisis moments.
type BreathingExercise struct {
	Name         string `json:"name"`         // "4-7-8 Breathing"
	InhaleSecs   int    `json:"inhaleSecs"`   // 4 seconds
	HoldSecs     int    `json:"holdSecs"`     // 7 seconds
	ExhaleSecs   int    `json:"exhaleSecs"`   // 8 seconds
	Repetitions  int    `json:"repetitions"`  // 3-4 cycles
	Instructions string `json:"instructions"` // Step-by-step guidance
}

// NewSOSSession creates a new SOS session with Level 1-2 affirmations only.
// Returns error if any affirmation exceeds Level 2.
func NewSOSSession(affirmations []Affirmation) (*SOSSession, error) {
	// Validate all affirmations are Level 1 or 2
	for _, aff := range affirmations {
		if aff.Level > LevelProcess {
			return nil, ErrSOSSessionLevelRestriction
		}
	}

	return &SOSSession{
		Affirmations: affirmations,
		BreathingExercise: &BreathingExercise{
			Name:         "4-7-8 Breathing",
			InhaleSecs:   4,
			HoldSecs:     7,
			ExhaleSecs:   8,
			Repetitions:  4,
			Instructions: "Find a comfortable position. Inhale quietly through your nose for 4 seconds. Hold your breath for 7 seconds. Exhale completely through your mouth for 8 seconds. Repeat 4 times.",
		},
		OffersAccountabilityPartnerReachOut: true,
	}, nil
}

// SessionCompletion represents a completed session for progress tracking.
type SessionCompletion struct {
	SessionID        string      `json:"sessionId"`
	SessionType      SessionType `json:"sessionType"`
	AffirmationCount int         `json:"affirmationCount"`
	CompletedAt      time.Time   `json:"completedAt"`
	WasSkipped       bool        `json:"wasSkipped"`
}
