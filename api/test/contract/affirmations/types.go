// api/test/contract/affirmations/types.go
package affirmations

import "time"

// ────────────────────────────────────────────────────────────────────────────
// Enums
// ────────────────────────────────────────────────────────────────────────────

// AffirmationCategory represents content categories for affirmations.
type AffirmationCategory string

const (
	CategorySelfWorth            AffirmationCategory = "self-worth"
	CategoryShameResilience      AffirmationCategory = "shame-resilience"
	CategoryHealthyRelationships AffirmationCategory = "healthy-relationships"
	CategoryConnection           AffirmationCategory = "connection"
	CategoryEmotionalRegulation  AffirmationCategory = "emotional-regulation"
	CategoryPurposeMeaning       AffirmationCategory = "purpose-meaning"
	CategoryIntegrityHonesty     AffirmationCategory = "integrity-honesty"
	CategoryDailyStrength        AffirmationCategory = "daily-strength"
	CategoryHealthySexuality     AffirmationCategory = "healthy-sexuality"
	CategorySOSCrisis            AffirmationCategory = "sos-crisis"
)

// Track represents content track selection (standard or faith-based).
type Track string

const (
	TrackStandard   Track = "standard"
	TrackFaithBased Track = "faith-based"
)

// RecoveryStage represents recovery stage classification.
type RecoveryStage string

const (
	StageEarly       RecoveryStage = "early"
	StageMiddle      RecoveryStage = "middle"
	StageEstablished RecoveryStage = "established"
)

// BackgroundMusic represents ambient background music presets.
type BackgroundMusic string

const (
	MusicNature    BackgroundMusic = "nature"
	MusicOcean     BackgroundMusic = "ocean"
	MusicRain      BackgroundMusic = "rain"
	MusicSoftTones BackgroundMusic = "soft-tones"
	MusicSilence   BackgroundMusic = "silence"
)

// SessionType represents the type of affirmation session.
type SessionType string

const (
	SessionTypeMorning SessionType = "morning"
	SessionTypeEvening SessionType = "evening"
	SessionTypeSOS     SessionType = "sos"
)

// LevelName represents human-readable level names.
type LevelName string

const (
	LevelPermission       LevelName = "permission"
	LevelProcess          LevelName = "process"
	LevelTemperedIdentity LevelName = "tempered-identity"
	LevelFullIdentity     LevelName = "full-identity"
)

// LevelDirection represents the direction of a level change.
type LevelDirection string

const (
	DirectionUpgrade   LevelDirection = "upgrade"
	DirectionDowngrade LevelDirection = "downgrade"
)

// LevelTrigger represents what triggered a level change.
type LevelTrigger string

const (
	TriggerAuto             LevelTrigger = "auto"
	TriggerManualUpgrade    LevelTrigger = "manual-upgrade"
	TriggerManualDowngrade  LevelTrigger = "manual-downgrade"
	TriggerRelapseReset     LevelTrigger = "relapse-reset"
)

// MilestoneType represents milestone categories.
type MilestoneType string

const (
	MilestoneSessionCount MilestoneType = "session-count"
	MilestoneFirstCustom  MilestoneType = "first-custom"
	MilestoneFirstAudio   MilestoneType = "first-audio"
	MilestoneFirstSOS     MilestoneType = "first-sos"
)

// ────────────────────────────────────────────────────────────────────────────
// Core Domain Types
// ────────────────────────────────────────────────────────────────────────────

// Affirmation represents a single affirmation from the curated library.
type Affirmation struct {
	ID            string              `json:"id"`
	Text          string              `json:"text"`
	Level         int                 `json:"level"` // 1-4
	CoreBeliefs   []int               `json:"coreBeliefs"`
	Category      AffirmationCategory `json:"category"`
	Track         Track               `json:"track"`
	RecoveryStage RecoveryStage       `json:"recoveryStage"`
	IsFavorite    bool                `json:"isFavorite"`
	HasAudio      bool                `json:"hasAudio"`
}

// CustomAffirmation represents a user-created custom affirmation.
type CustomAffirmation struct {
	CustomID          string    `json:"customId"`
	Text              string    `json:"text"`
	IncludeInRotation bool      `json:"includeInRotation"`
	IsEditable        bool      `json:"isEditable"`
	EditableUntil     time.Time `json:"editableUntil"`
	IsFavorite        bool      `json:"isFavorite"`
	IsHidden          bool      `json:"isHidden"`
	HasAudio          bool      `json:"hasAudio"`
	CreatedAt         time.Time `json:"createdAt"`
	ModifiedAt        time.Time `json:"modifiedAt"`
}

// AudioRecordingMetadata represents metadata for an own-voice audio recording.
type AudioRecordingMetadata struct {
	RecordingID     string          `json:"recordingId"`
	AffirmationID   string          `json:"affirmationId"`
	Format          string          `json:"format"` // "m4a"
	DurationSeconds float64         `json:"durationSeconds"`
	BackgroundMusic BackgroundMusic `json:"backgroundMusic"`
	SizeBytes       int             `json:"sizeBytes"`
	PlaybackURL     string          `json:"playbackUrl,omitempty"`
	CloudSynced     bool            `json:"cloudSynced"`
	CreatedAt       time.Time       `json:"createdAt"`
}

// BreathingExercise represents the 4-7-8 breathing pattern.
type BreathingExercise struct {
	Pattern         string `json:"pattern"`         // "4-7-8"
	InhaleSeconds   int    `json:"inhaleSeconds"`   // 4
	HoldSeconds     int    `json:"holdSeconds"`     // 7
	ExhaleSeconds   int    `json:"exhaleSeconds"`   // 8
	Cycles          int    `json:"cycles"`          // 3
	DurationSeconds int    `json:"durationSeconds"` // 57
}

// DayConsistency represents session counts for a single day in the 30-day calendar.
type DayConsistency struct {
	Date     string `json:"date"`     // "2026-04-08"
	Sessions int    `json:"sessions"` // 0-N
}

// Milestone represents a progress milestone achieved.
type Milestone struct {
	Type       MilestoneType `json:"type"`
	Threshold  int           `json:"threshold,omitempty"`
	Message    string        `json:"message,omitempty"`
	AchievedAt time.Time     `json:"achievedAt"`
}

// AffirmationProgress represents cumulative progress metrics.
type AffirmationProgress struct {
	TotalSessions              int              `json:"totalSessions"`
	TotalMorningSessions       int              `json:"totalMorningSessions"`
	TotalEveningSessions       int              `json:"totalEveningSessions"`
	TotalSOSSessions           int              `json:"totalSOSSessions"`
	TotalAffirmationsPracticed int              `json:"totalAffirmationsPracticed"`
	TotalCustomCreated         int              `json:"totalCustomCreated"`
	TotalAudioRecordings       int              `json:"totalAudioRecordings"`
	TotalFavorites             int              `json:"totalFavorites"`
	TotalHidden                int              `json:"totalHidden"`
	Consistency30d             []DayConsistency `json:"consistency30d"`
	Milestones                 []Milestone      `json:"milestones"`
}

// AffirmationSettings represents user affirmation feature settings.
type AffirmationSettings struct {
	MorningTime             string                `json:"morningTime"` // "HH:MM"
	EveningTime             string                `json:"eveningTime"` // "HH:MM"
	Track                   Track                 `json:"track"`
	LevelOverride           *int                  `json:"levelOverride"` // nullable
	EnabledCategories       []AffirmationCategory `json:"enabledCategories"`
	HealthySexualityEnabled bool                  `json:"healthySexualityEnabled"`
	AudioAutoPlay           bool                  `json:"audioAutoPlay"`
	CloudAudioSync          bool                  `json:"cloudAudioSync"`
}

// LevelHistoryEntry represents a single level change in history.
type LevelHistoryEntry struct {
	Level     int          `json:"level"`
	StartedAt time.Time    `json:"startedAt"`
	EndedAt   *time.Time   `json:"endedAt"` // nullable
	Trigger   LevelTrigger `json:"trigger"`
}

// LevelInfo represents current affirmation level information.
type LevelInfo struct {
	CurrentLevel           int                 `json:"currentLevel"`
	LevelName              LevelName           `json:"levelName"`
	DaysAtLevel            int                 `json:"daysAtLevel"`
	DaysInRecovery         int                 `json:"daysInRecovery"`
	NextLevelEligible      bool                `json:"nextLevelEligible"`
	NextLevelName          *string             `json:"nextLevelName"` // nullable
	NextLevelAutoUnlockDay *int                `json:"nextLevelAutoUnlockDay"` // nullable
	CanRequestUpgrade      bool                `json:"canRequestUpgrade"`
	UpgradeEligibleAt      *time.Time          `json:"upgradeEligibleAt"` // nullable
	LevelHistory           []LevelHistoryEntry `json:"levelHistory"`
}

// ────────────────────────────────────────────────────────────────────────────
// Request Types
// ────────────────────────────────────────────────────────────────────────────

// AffirmationInteraction represents per-affirmation interactions during a session.
type AffirmationInteraction struct {
	AffirmationID  string `json:"affirmationId"`
	Favorited      bool   `json:"favorited"`
	Hidden         bool   `json:"hidden"`
	DurationViewed int    `json:"durationViewed"` // seconds
}

// CompleteMorningRequest represents the request to complete a morning session.
type CompleteMorningRequest struct {
	SessionID               string                   `json:"sessionId"`
	Intention               *string                  `json:"intention"` // nullable
	AffirmationInteractions []AffirmationInteraction `json:"affirmationInteractions"`
}

// CompleteEveningRequest represents the request to complete an evening session.
type CompleteEveningRequest struct {
	SessionID  string  `json:"sessionId"`
	DayRating  int     `json:"dayRating"` // 1-5
	Reflection *string `json:"reflection"` // nullable
}

// CompleteSOSRequest represents the request to complete an SOS session.
type CompleteSOSRequest struct {
	BreathingCompleted bool `json:"breathingCompleted"`
	ReachedOut         bool `json:"reachedOut"`
	PostCheckInRating  *int `json:"postCheckInRating"` // nullable, 1-5
}

// CreateCustomAffirmationRequest represents the request to create a custom affirmation.
type CreateCustomAffirmationRequest struct {
	Text              string `json:"text"`
	IncludeInRotation bool   `json:"includeInRotation"`
}

// UpdateCustomAffirmationRequest represents the request to update a custom affirmation (PATCH).
type UpdateCustomAffirmationRequest struct {
	Text              *string `json:"text,omitempty"`
	IncludeInRotation *bool   `json:"includeInRotation,omitempty"`
}

// LevelOverrideRequest represents a request for a manual level change.
type LevelOverrideRequest struct {
	TargetLevel int            `json:"targetLevel"` // 1-4
	Direction   LevelDirection `json:"direction"`   // upgrade | downgrade
}

// UpdateAffirmationSettingsRequest represents a PATCH request to update settings.
type UpdateAffirmationSettingsRequest struct {
	MorningTime             *string                `json:"morningTime,omitempty"`
	EveningTime             *string                `json:"eveningTime,omitempty"`
	Track                   *Track                 `json:"track,omitempty"`
	LevelOverride           *int                   `json:"levelOverride,omitempty"`
	EnabledCategories       []AffirmationCategory  `json:"enabledCategories,omitempty"`
	HealthySexualityEnabled *bool                  `json:"healthySexualityEnabled,omitempty"`
	AudioAutoPlay           *bool                  `json:"audioAutoPlay,omitempty"`
	CloudAudioSync          *bool                  `json:"cloudAudioSync,omitempty"`
}

// AddFavoriteRequest represents the request to add an affirmation to favorites.
type AddFavoriteRequest struct {
	AffirmationID string `json:"affirmationId"`
}

// HideAffirmationRequest represents the request to hide an affirmation.
type HideAffirmationRequest struct {
	AffirmationID string  `json:"affirmationId"`
	SessionID     *string `json:"sessionId,omitempty"` // nullable
}

// ────────────────────────────────────────────────────────────────────────────
// Response Envelopes
// ────────────────────────────────────────────────────────────────────────────

// Links represents common hypermedia links.
type Links struct {
	Self     string  `json:"self"`
	Complete *string `json:"complete,omitempty"`
	Progress *string `json:"progress,omitempty"`
	Override *string `json:"override,omitempty"`
	Playback *string `json:"playback,omitempty"`
}

// PaginationLinks represents pagination hypermedia links.
type PaginationLinks struct {
	Self  string  `json:"self"`
	Next  *string `json:"next,omitempty"`
	Prev  *string `json:"prev,omitempty"`
	First *string `json:"first,omitempty"`
	Last  *string `json:"last,omitempty"`
}

// PageMetadata represents pagination metadata.
type PageMetadata struct {
	NextCursor *string `json:"nextCursor"`
	PrevCursor *string `json:"prevCursor"`
	Limit      int     `json:"limit"`
}

// Metadata represents common metadata fields.
type Metadata struct {
	CreatedAt   *time.Time `json:"createdAt,omitempty"`
	ModifiedAt  *time.Time `json:"modifiedAt,omitempty"`
	GeneratedAt *time.Time `json:"generatedAt,omitempty"`
	EvaluatedAt *time.Time `json:"evaluatedAt,omitempty"`
}

// MorningSessionData represents the data section of a morning session response.
type MorningSessionData struct {
	SessionID       string        `json:"sessionId"`
	SessionType     SessionType   `json:"sessionType"` // "morning"
	Affirmations    []Affirmation `json:"affirmations"`
	IntentionPrompt string        `json:"intentionPrompt"`
	CreatedAt       time.Time     `json:"createdAt"`
	Links           Links         `json:"links"`
}

// MorningSessionResponse represents the GET morning session response.
type MorningSessionResponse struct {
	Data MorningSessionData `json:"data"`
	Meta Metadata           `json:"meta"`
}

// EveningSessionData represents the data section of an evening session response.
type EveningSessionData struct {
	SessionID       string      `json:"sessionId"`
	SessionType     SessionType `json:"sessionType"` // "evening"
	Affirmation     Affirmation `json:"affirmation"`
	MorningIntention *string    `json:"morningIntention"` // nullable
	RatingPrompt    string      `json:"ratingPrompt"`
	CreatedAt       time.Time   `json:"createdAt"`
	Links           Links       `json:"links"`
}

// EveningSessionResponse represents the GET evening session response.
type EveningSessionResponse struct {
	Data EveningSessionData `json:"data"`
	Meta Metadata           `json:"meta"`
}

// SOSSessionData represents the data section of an SOS session response.
type SOSSessionData struct {
	SOSID                  string             `json:"sosId"`
	Affirmation            Affirmation        `json:"affirmation"`
	BreathingExercise      BreathingExercise  `json:"breathingExercise"`
	AdditionalAffirmations []Affirmation      `json:"additionalAffirmations"`
	CreatedAt              time.Time          `json:"createdAt"`
	Links                  Links              `json:"links"`
}

// SOSSessionResponse represents the POST SOS session response.
type SOSSessionResponse struct {
	Data SOSSessionData `json:"data"`
	Meta Metadata       `json:"meta"`
}

// SessionCompletionData represents the data section of a session completion response.
type SessionCompletionData struct {
	SessionID     string       `json:"sessionId"`
	SessionType   SessionType  `json:"sessionType"`
	CompletedAt   time.Time    `json:"completedAt"`
	TotalSessions int          `json:"totalSessions"`
	Milestone     *Milestone   `json:"milestone"` // nullable
	Links         Links        `json:"links"`
}

// SessionCompletionResponse represents the 201 response after completing any session.
type SessionCompletionResponse struct {
	Data SessionCompletionData `json:"data"`
	Meta Metadata              `json:"meta"`
}

// AffirmationResponse represents a single affirmation response.
type AffirmationResponse struct {
	Data Affirmation `json:"data"`
	Meta Metadata    `json:"meta"`
}

// AffirmationListResponse represents a paginated list of affirmations.
type AffirmationListResponse struct {
	Data  []Affirmation   `json:"data"`
	Links PaginationLinks `json:"links"`
	Meta  struct {
		Page       PageMetadata `json:"page"`
		TotalCount int          `json:"totalCount"`
	} `json:"meta"`
}

// CustomAffirmationResponse represents a single custom affirmation response.
type CustomAffirmationResponse struct {
	Data CustomAffirmation `json:"data"`
	Meta Metadata          `json:"meta"`
}

// CustomAffirmationListResponse represents a paginated list of custom affirmations.
type CustomAffirmationListResponse struct {
	Data  []CustomAffirmation `json:"data"`
	Links PaginationLinks     `json:"links"`
	Meta  struct {
		Page PageMetadata `json:"page"`
	} `json:"meta"`
}

// AudioRecordingResponse represents an audio recording metadata response.
type AudioRecordingResponse struct {
	Data AudioRecordingMetadata `json:"data"`
	Meta Metadata               `json:"meta"`
}

// AffirmationProgressResponse represents the progress metrics response.
type AffirmationProgressResponse struct {
	Data AffirmationProgress `json:"data"`
	Meta struct {
		GeneratedAt time.Time `json:"generatedAt"`
	} `json:"meta"`
}

// AffirmationSettingsResponse represents the settings response.
type AffirmationSettingsResponse struct {
	Data AffirmationSettings `json:"data"`
	Meta struct {
		ModifiedAt time.Time `json:"modifiedAt"`
	} `json:"meta"`
}

// LevelInfoResponse represents the level information response.
type LevelInfoResponse struct {
	Data LevelInfo `json:"data"`
	Meta struct {
		EvaluatedAt time.Time `json:"evaluatedAt"`
	} `json:"meta"`
}

// SharingSummaryData represents privacy-safe sharing summary data.
type SharingSummaryData struct {
	SessionsThisWeek  int        `json:"sessionsThisWeek"`
	SessionsThisMonth int        `json:"sessionsThisMonth"`
	TotalSessions     int        `json:"totalSessions"`
	LastSessionAt     *time.Time `json:"lastSessionAt"` // nullable
	Links             Links      `json:"links"`
}

// SharingSummaryResponse represents the sharing summary response.
type SharingSummaryResponse struct {
	Data SharingSummaryData `json:"data"`
	Meta struct {
		GeneratedAt time.Time `json:"generatedAt"`
	} `json:"meta"`
}

// FavoriteData represents the response data when adding a favorite.
type FavoriteData struct {
	AffirmationID string    `json:"affirmationId"`
	FavoritedAt   time.Time `json:"favoritedAt"`
	Links         Links     `json:"links"`
}

// FavoriteResponse represents the response when adding a favorite.
type FavoriteResponse struct {
	Data FavoriteData `json:"data"`
	Meta Metadata     `json:"meta"`
}

// HiddenData represents the response data when hiding an affirmation.
type HiddenData struct {
	AffirmationID string       `json:"affirmationId"`
	HiddenAt      time.Time    `json:"hiddenAt"`
	Replacement   *Affirmation `json:"replacement,omitempty"` // nullable
	Links         Links        `json:"links"`
}

// HiddenResponse represents the response when hiding an affirmation.
type HiddenResponse struct {
	Data HiddenData `json:"data"`
	Meta Metadata   `json:"meta"`
}

// ────────────────────────────────────────────────────────────────────────────
// Error Response Types
// ────────────────────────────────────────────────────────────────────────────

// ErrorSource represents the source of an error in the request.
type ErrorSource struct {
	Pointer   *string `json:"pointer,omitempty"`
	Parameter *string `json:"parameter,omitempty"`
}

// ErrorObject represents a single error in the errors array.
type ErrorObject struct {
	ID            string       `json:"id,omitempty"`
	Code          string       `json:"code,omitempty"` // "rr:0x000Axxxx"
	Status        int          `json:"status"`
	Title         string       `json:"title"`
	Detail        string       `json:"detail,omitempty"`
	CorrelationID string       `json:"correlationId,omitempty"`
	Source        *ErrorSource `json:"source,omitempty"`
	Links         *struct {
		About string `json:"about,omitempty"`
	} `json:"links,omitempty"`
}

// ErrorResponse represents the error response envelope.
type ErrorResponse struct {
	Errors []ErrorObject `json:"errors"`
}

// ────────────────────────────────────────────────────────────────────────────
// Known Error Codes (0x000A = affirmation domain)
// ────────────────────────────────────────────────────────────────────────────
const (
	ErrCodeFeatureFlagDisabled        = "rr:0x000A0001"
	ErrCodeAffirmationNotFound        = "rr:0x000A0002"
	ErrCodeSOSSessionNotFound         = "rr:0x000A0003"
	ErrCodeCustomAffirmationNotFound  = "rr:0x000A0004"
	ErrCodeAudioRecordingNotFound     = "rr:0x000A0005"
	ErrCodeDay14GateNotMet            = "rr:0x000A0010"
	ErrCodeEditWindowExpired          = "rr:0x000A0011"
	ErrCode30DayMinimumNotMet         = "rr:0x000A0012"
	ErrCodeHealthySexualityRequires60 = "rr:0x000A0013"
	ErrCodeCannotUpgradeBeyondLevel4  = "rr:0x000A0014"
	ErrCodeCannotDowngradeBelowLevel1 = "rr:0x000A0015"
	ErrCodeInvalidAudioFormat         = "rr:0x000A0020"
	ErrCodeAudioExceeds60Seconds      = "rr:0x000A0021"
	ErrCodeAudioFileTooLarge          = "rr:0x000A0022"
	ErrCodeInvalidDayRating           = "rr:0x000A0030"
	ErrCodeAlreadyFavorited           = "rr:0x000A0031"
	ErrCodeAlreadyHidden              = "rr:0x000A0032"
	ErrCodeNotInFavorites             = "rr:0x000A0033"
	ErrCodeNotHidden                  = "rr:0x000A0034"
	ErrCodeInternalError              = "rr:0x000A00FF"
)
