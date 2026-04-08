// internal/domain/prayer/types.go
package prayer

import "time"

// Prayer type constants matching OpenAPI spec enum.
const (
	PrayerTypePersonal       = "personal"
	PrayerTypeGuided         = "guided"
	PrayerTypeGroup          = "group"
	PrayerTypeScriptureBased = "scriptureBased"
	PrayerTypeIntercessory   = "intercessory"
	PrayerTypeListening      = "listening"
)

// ValidPrayerTypes is the exhaustive set of valid prayer types.
var ValidPrayerTypes = map[string]bool{
	PrayerTypePersonal:       true,
	PrayerTypeGuided:         true,
	PrayerTypeGroup:          true,
	PrayerTypeScriptureBased: true,
	PrayerTypeIntercessory:   true,
	PrayerTypeListening:      true,
}

// Content tier constants.
const (
	TierFree    = "free"
	TierPremium = "premium"
)

// PrayerSession represents a single prayer session log entry.
type PrayerSession struct {
	PrayerID          string
	UserID            string
	Timestamp         time.Time
	PrayerType        string
	DurationMinutes   *int
	Notes             *string
	LinkedPrayerID    *string
	LinkedPrayerTitle *string
	MoodBefore        *int
	MoodAfter         *int
	IsEphemeral       bool
	NotesEditableUntil time.Time
	CreatedAt         time.Time
	ModifiedAt        time.Time
}

// PersonalPrayer represents a user-created prayer.
type PersonalPrayer struct {
	ID                 string
	UserID             string
	Title              string
	Body               string
	TopicTags          []string
	ScriptureReference *string
	IsFavorite         bool
	SortOrder          int
	CreatedAt          time.Time
	ModifiedAt         time.Time
}

// PrayerFavorite represents a favorited prayer link.
type PrayerFavorite struct {
	UserID       string
	PrayerID     string
	PrayerSource string // "library" or "personal"
	Title        string
	PackID       *string
	CreatedAt    time.Time
}

// LibraryPrayer represents a curated prayer from the content library.
type LibraryPrayer struct {
	ID                  string
	Title               string
	Body                string
	TopicTags           []string
	SourceAttribution   string
	ScriptureConnection *string
	PackID              string
	PackName            string
	StepNumber          *int
	Tier                string
	IsLocked            bool
	IsFavorite          bool
	Language            string
}

// PrayerStats represents computed prayer statistics.
type PrayerStats struct {
	CurrentStreakDays      int
	LongestStreakDays      int
	TotalPrayerDays       int
	SessionsThisWeek      int
	AverageDurationMinutes *float64
	TypeDistribution      map[string]int
	MoodImpact            *MoodImpact
}

// MoodImpact represents aggregated mood before/after data.
type MoodImpact struct {
	AverageMoodBefore *float64
	AverageMoodAfter  *float64
}

// DailySessionCount represents prayer sessions for a single day in trend data.
type DailySessionCount struct {
	Date                  string
	Count                 int
	TotalDurationMinutes  *int
}

// PrayerTrends represents time-series prayer trend data.
type PrayerTrends struct {
	Period                 string
	DailySessions          []DailySessionCount
	TypeDistribution       map[string]int
	TimeOfDayDistribution  map[string]int
}

// CreatePrayerSessionRequest represents the request to create a prayer session.
type CreatePrayerSessionRequest struct {
	Timestamp       time.Time
	PrayerType      string
	DurationMinutes *int
	Notes           *string
	LinkedPrayerID  *string
	MoodBefore      *int
	MoodAfter       *int
	IsEphemeral     bool
}

// UpdatePrayerSessionRequest represents the request to update a prayer session.
type UpdatePrayerSessionRequest struct {
	PrayerType      *string
	DurationMinutes *int
	Notes           *string
	LinkedPrayerID  *string
	MoodBefore      *int
	MoodAfter       *int
	Timestamp       *time.Time // included to detect immutability violations
}

// CreatePersonalPrayerRequest represents the request to create a personal prayer.
type CreatePersonalPrayerRequest struct {
	Title              string
	Body               string
	TopicTags          []string
	ScriptureReference *string
}

// UpdatePersonalPrayerRequest represents the request to update a personal prayer.
type UpdatePersonalPrayerRequest struct {
	Title              *string
	Body               *string
	TopicTags          []string
	ScriptureReference *string
}

// ReorderPersonalPrayersRequest represents the request to reorder personal prayers.
type ReorderPersonalPrayersRequest struct {
	PrayerIDs []string
}

// PrayerSessionResponse is the API response envelope for a prayer session.
type PrayerSessionResponse struct {
	Data  PrayerSession          `json:"data"`
	Meta  map[string]interface{} `json:"meta"`
}

// PrayerSessionListResponse is the API response for listing prayer sessions.
type PrayerSessionListResponse struct {
	Data  []PrayerSession        `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta"`
}

// PrayerStatsResponse is the API response for prayer stats.
type PrayerStatsResponse struct {
	Data PrayerStats `json:"data"`
}

// PrayerTrendsResponse is the API response for prayer trends.
type PrayerTrendsResponse struct {
	Data PrayerTrends `json:"data"`
}

// PersonalPrayerResponse is the API response for a personal prayer.
type PersonalPrayerResponse struct {
	Data  PersonalPrayer         `json:"data"`
	Meta  map[string]interface{} `json:"meta"`
}

// PersonalPrayerListResponse is the API response for listing personal prayers.
type PersonalPrayerListResponse struct {
	Data  []PersonalPrayer       `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta"`
}

// LibraryPrayerResponse is the API response for a library prayer.
type LibraryPrayerResponse struct {
	Data LibraryPrayer `json:"data"`
}

// LibraryPrayerListResponse is the API response for listing library prayers.
type LibraryPrayerListResponse struct {
	Data  []LibraryPrayer        `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta"`
}
