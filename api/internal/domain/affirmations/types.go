// internal/domain/affirmations/types.go
package affirmations

import (
	"errors"
	"time"
)

// Sentinel errors
var (
	ErrInvalidLevel              = errors.New("invalid affirmation level")
	ErrInvalidCategory           = errors.New("invalid category")
	ErrInvalidCoreBelief         = errors.New("invalid core belief number")
	ErrInvalidTrack              = errors.New("invalid track")
	ErrInvalidRecoveryStage      = errors.New("invalid recovery stage")
	ErrInsufficientSobriety      = errors.New("insufficient sobriety days for level increase")
	ErrHealthySexualityNotGated  = errors.New("healthy sexuality category requires 60+ days and opt-in")
	ErrNoContentAvailable        = errors.New("no content available matching criteria")
	ErrInvalidIntensity          = errors.New("intensity must be between 1 and 10")
)

// Level represents the progressive affirmation framework levels (1-4).
// Level determines the type of affirmation language users receive based on their recovery stage.
type Level int

const (
	// LevelPermission (Level 1) - "It is OK for me to..." statements
	// Days 0-13; post-relapse; onboarding
	LevelPermission Level = 1

	// LevelProcess (Level 2) - "I am working my recovery..." statements
	// Days 14-59; stable early recovery
	LevelProcess Level = 2

	// LevelTemperedIdentity (Level 3) - "I have done bad things, but I am not a bad person" statements
	// Days 60-179; consistent engagement
	LevelTemperedIdentity Level = 3

	// LevelFullIdentity (Level 4) - "I am worthy of love..." statements
	// Days 180+; established recovery
	LevelFullIdentity Level = 4
)

// String returns the string representation of the Level.
func (l Level) String() string {
	switch l {
	case LevelPermission:
		return "permission"
	case LevelProcess:
		return "process"
	case LevelTemperedIdentity:
		return "temperedIdentity"
	case LevelFullIdentity:
		return "fullIdentity"
	default:
		return "unknown"
	}
}

// IsValid returns true if the level is within the valid range [1, 4].
func (l Level) IsValid() bool {
	return l >= LevelPermission && l <= LevelFullIdentity
}

// Category represents affirmation content categories.
type Category string

const (
	CategorySelfWorth         Category = "selfWorth"
	CategoryShameResilience   Category = "shameResilience"
	CategoryHealthyRelationships Category = "healthyRelationships"
	CategoryConnection        Category = "connection"
	CategoryEmotionalRegulation Category = "emotionalRegulation"
	CategoryPurpose           Category = "purpose"
	CategoryIntegrity         Category = "integrity"
	CategoryDailyStrength     Category = "dailyStrength"
	CategoryHealthySexuality  Category = "healthySexuality"
	CategorySOSCrisis         Category = "sosCrisis"
)

// IsValid returns true if the category is recognized.
func (c Category) IsValid() bool {
	switch c {
	case CategorySelfWorth, CategoryShameResilience, CategoryHealthyRelationships,
		CategoryConnection, CategoryEmotionalRegulation, CategoryPurpose,
		CategoryIntegrity, CategoryDailyStrength, CategoryHealthySexuality,
		CategorySOSCrisis:
		return true
	default:
		return false
	}
}

// CoreBelief represents one of Carnes' four distorted core beliefs.
// Every affirmation must map to at least one core belief.
type CoreBelief int

const (
	// CoreBelief1 - "I am basically a bad, unworthy person"
	CoreBelief1 CoreBelief = 1

	// CoreBelief2 - "No one would love me as I am"
	CoreBelief2 CoreBelief = 2

	// CoreBelief3 - "My needs are never met by depending on others"
	CoreBelief3 CoreBelief = 3

	// CoreBelief4 - "Sex is my most important need"
	CoreBelief4 CoreBelief = 4
)

// IsValid returns true if the core belief is within [1, 4].
func (cb CoreBelief) IsValid() bool {
	return cb >= CoreBelief1 && cb <= CoreBelief4
}

// Track represents the content track (standard or faith-based).
type Track string

const (
	TrackStandard   Track = "standard"
	TrackFaithBased Track = "faithBased"
)

// IsValid returns true if the track is recognized.
func (t Track) IsValid() bool {
	return t == TrackStandard || t == TrackFaithBased
}

// RecoveryStage represents the user's recovery stage for content filtering.
type RecoveryStage string

const (
	RecoveryStageEarly       RecoveryStage = "early"
	RecoveryStageMiddle      RecoveryStage = "middle"
	RecoveryStageEstablished RecoveryStage = "established"
)

// IsValid returns true if the recovery stage is recognized.
func (rs RecoveryStage) IsValid() bool {
	return rs == RecoveryStageEarly || rs == RecoveryStageMiddle || rs == RecoveryStageEstablished
}

// Affirmation represents a single affirmation with all metadata.
type Affirmation struct {
	ID            string        `json:"affirmationId"`
	Text          string        `json:"text"`
	Level         Level         `json:"level"`
	CoreBeliefs   []CoreBelief  `json:"coreBeliefs"`    // Which Carnes beliefs this counters
	Category      Category      `json:"category"`
	Track         Track         `json:"track"`
	RecoveryStage RecoveryStage `json:"recoveryStage"`
	IsFavorite    bool          `json:"isFavorite"`
	IsHidden      bool          `json:"isHidden"`
	CreatedAt     time.Time     `json:"createdAt"`
	ModifiedAt    time.Time     `json:"modifiedAt"`
}

// UserAffirmationPreferences contains user-specific affirmation preferences.
type UserAffirmationPreferences struct {
	UserID                   string    `json:"userId"`
	PreferredTrack           Track     `json:"preferredTrack"`           // standard or faithBased
	ManualLevelOverride      *Level    `json:"manualLevelOverride,omitempty"` // User can manually select lower level
	HealthySexualityOptIn    bool      `json:"healthySexualityOptIn"`    // Explicit opt-in required for Healthy Sexuality category
	FavoriteAffirmationIDs   []string  `json:"favoriteAffirmationIds"`
	HiddenAffirmationIDs     []string  `json:"hiddenAffirmationIds"`
	LastLevelChangeTimestamp time.Time `json:"lastLevelChangeTimestamp"` // Tracks last automatic level increase
}

// SessionContext provides context for content selection in a given session.
type SessionContext struct {
	UserID                 string
	SobrietyDays           int
	LastRelapseTimestamp   *time.Time
	CurrentTime            time.Time
	Track                  Track
	ManualLevelOverride    *Level
	HealthySexualityOptIn  bool
	FavoriteIDs            []string
	HiddenIDs              []string
	RecentAffirmationIDs   []string // IDs shown in last 7 days (for no-repeat logic)
	SessionType            SessionType
}

// SessionType indicates the type of affirmation session.
type SessionType string

const (
	SessionTypeMorning  SessionType = "morning"
	SessionTypeEvening  SessionType = "evening"
	SessionTypeSOS      SessionType = "sos"
	SessionTypeBrowse   SessionType = "browse"
)

// LevelDeterminationResult holds the result of level engine computation.
type LevelDeterminationResult struct {
	DeterminedLevel Level
	Reason          string
	IsLocked        bool // true if locked due to post-relapse window
}

// ContentSelectionRequest represents a request for affirmation content.
type ContentSelectionRequest struct {
	Context         SessionContext
	RequestedCount  int
	AllowedLevels   []Level // if empty, use default 80/20 split
}

// ContentSelectionResult holds the selected affirmations and metadata.
type ContentSelectionResult struct {
	Affirmations []Affirmation          `json:"affirmations"`
	Meta         map[string]interface{} `json:"meta,omitempty"`
}
