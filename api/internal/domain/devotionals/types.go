// internal/domain/devotionals/types.go
package devotionals

import "time"

// Feature flag key for devotionals.
const FeatureFlagKey = "activity.devotionals"

// ContentTier represents the access tier of a devotional.
type ContentTier string

const (
	TierFree    ContentTier = "free"
	TierPremium ContentTier = "premium"
)

// Topic represents a devotional topic/theme.
type Topic string

const (
	TopicShame       Topic = "shame"
	TopicTemptation  Topic = "temptation"
	TopicIdentity    Topic = "identity"
	TopicMarriage    Topic = "marriage"
	TopicForgiveness Topic = "forgiveness"
	TopicSurrender   Topic = "surrender"
	TopicGratitude   Topic = "gratitude"
	TopicRestoration Topic = "restoration"
	TopicFear        Topic = "fear"
	TopicHope        Topic = "hope"
)

// ValidTopics is the set of valid topic values.
var ValidTopics = map[Topic]bool{
	TopicShame: true, TopicTemptation: true, TopicIdentity: true,
	TopicMarriage: true, TopicForgiveness: true, TopicSurrender: true,
	TopicGratitude: true, TopicRestoration: true, TopicFear: true, TopicHope: true,
}

// MoodTag represents how the user feels after reading.
type MoodTag string

const (
	MoodGrateful    MoodTag = "grateful"
	MoodHopeful     MoodTag = "hopeful"
	MoodPeaceful    MoodTag = "peaceful"
	MoodConvicted   MoodTag = "convicted"
	MoodChallenged  MoodTag = "challenged"
	MoodComforted   MoodTag = "comforted"
	MoodAnxious     MoodTag = "anxious"
	MoodStruggling  MoodTag = "struggling"
	MoodNumb        MoodTag = "numb"
)

// ValidMoodTags is the set of valid mood tag values.
var ValidMoodTags = map[MoodTag]bool{
	MoodGrateful: true, MoodHopeful: true, MoodPeaceful: true,
	MoodConvicted: true, MoodChallenged: true, MoodComforted: true,
	MoodAnxious: true, MoodStruggling: true, MoodNumb: true,
}

// BibleTranslation represents supported Bible translations.
type BibleTranslation string

const (
	TranslationNIV     BibleTranslation = "NIV"
	TranslationESV     BibleTranslation = "ESV"
	TranslationNLT     BibleTranslation = "NLT"
	TranslationKJV     BibleTranslation = "KJV"
	TranslationRVR1960 BibleTranslation = "RVR1960"
	TranslationNVI     BibleTranslation = "NVI"
)

// Language represents supported languages.
type Language string

const (
	LangEN Language = "en"
	LangES Language = "es"
)

// SeriesStatus represents the user's status with a devotional series.
type SeriesStatus string

const (
	SeriesNotStarted SeriesStatus = "not_started"
	SeriesActive     SeriesStatus = "active"
	SeriesPaused     SeriesStatus = "paused"
	SeriesCompleted  SeriesStatus = "completed"
)

// SeriesCategory represents a devotional series category.
type SeriesCategory string

const (
	CategoryRecovery        SeriesCategory = "recovery"
	CategoryMarriage        SeriesCategory = "marriage"
	CategoryIdentity        SeriesCategory = "identity"
	CategorySpiritualGrowth SeriesCategory = "spiritual-growth"
)

// ShareType represents the type of share action.
type ShareType string

const (
	ShareContact ShareType = "contact"
	ShareLink    ShareType = "link"
	ShareImage   ShareType = "image"
)

// FreemiumRotationSize is the number of devotionals in the free rotation.
const FreemiumRotationSize = 30

// --- Domain Models ---

// Devotional represents full devotional content.
type Devotional struct {
	ID                 string            `json:"id"`
	Title              string            `json:"title"`
	ScriptureReference string            `json:"scriptureReference"`
	ScriptureText      string            `json:"scriptureText"`
	BibleTranslation   BibleTranslation  `json:"bibleTranslation"`
	Reading            string            `json:"reading"`
	RecoveryConnection string            `json:"recoveryConnection"`
	ReflectionQuestion string            `json:"reflectionQuestion"`
	Prayer             string            `json:"prayer"`
	AuthorName         *string           `json:"authorName"`
	AuthorBio          *string           `json:"authorBio"`
	Date               string            `json:"date"`
	Topic              Topic             `json:"topic"`
	SeriesID           *string           `json:"seriesId"`
	SeriesDay          *int              `json:"seriesDay"`
	SeriesTotalDays    *int              `json:"seriesTotalDays"`
	Tier               ContentTier       `json:"tier"`
	Language           Language          `json:"language"`
	IsCompleted        bool              `json:"isCompleted"`
	IsFavorite         bool              `json:"isFavorite"`
	Links              map[string]string `json:"links,omitempty"`
}

// DevotionalSummary is an abbreviated devotional for list views.
type DevotionalSummary struct {
	ID                 string            `json:"id"`
	Title              string            `json:"title"`
	ScriptureReference string            `json:"scriptureReference"`
	Topic              Topic             `json:"topic"`
	AuthorName         *string           `json:"authorName"`
	Date               string            `json:"date"`
	SeriesID           *string           `json:"seriesId"`
	Tier               ContentTier       `json:"tier"`
	IsLocked           bool              `json:"isLocked"`
	IsCompleted        bool              `json:"isCompleted"`
	IsFavorite         bool              `json:"isFavorite"`
	Language           Language          `json:"language"`
	Links              map[string]string `json:"links,omitempty"`
}

// DevotionalCompletion represents a recorded devotional completion.
type DevotionalCompletion struct {
	CompletionID       string            `json:"completionId"`
	DevotionalID       string            `json:"devotionalId"`
	DevotionalTitle    string            `json:"devotionalTitle"`
	ScriptureReference string            `json:"scriptureReference"`
	Timestamp          time.Time         `json:"timestamp"`
	Reflection         *string           `json:"reflection"`
	MoodTag            *MoodTag          `json:"moodTag"`
	SeriesID           *string           `json:"seriesId"`
	SeriesDay          *int              `json:"seriesDay"`
	DevotionalStreak   *DevotionalStreak `json:"devotionalStreak,omitempty"`
	Links              map[string]string `json:"links,omitempty"`
}

// DevotionalSeries represents a devotional series with user progress.
type DevotionalSeries struct {
	SeriesID      string            `json:"seriesId"`
	Name          string            `json:"name"`
	Description   string            `json:"description"`
	AuthorName    *string           `json:"authorName"`
	TotalDays     int               `json:"totalDays"`
	Tier          ContentTier       `json:"tier"`
	Price         *float64          `json:"price"`
	Currency      *string           `json:"currency"`
	IsOwned       bool              `json:"isOwned"`
	IsActive      bool              `json:"isActive"`
	CurrentDay    *int              `json:"currentDay"`
	CompletedDays int               `json:"completedDays"`
	Status        SeriesStatus      `json:"status"`
	Category      SeriesCategory    `json:"category"`
	Language      Language          `json:"language"`
	ThumbnailURL  *string           `json:"thumbnailUrl"`
	Links         map[string]string `json:"links,omitempty"`
}

// DevotionalStreak represents the user's devotional reading streak.
type DevotionalStreak struct {
	CurrentDays       int     `json:"currentDays"`
	LongestDays       int     `json:"longestDays"`
	LastCompletedDate *string `json:"lastCompletedDate"`
}

// --- Request Types ---

// CompletionRequest is the payload for creating a devotional completion.
type CompletionRequest struct {
	Timestamp  time.Time `json:"timestamp"`
	Reflection *string   `json:"reflection"`
	MoodTag    *MoodTag  `json:"moodTag"`
}

// CompletionUpdateRequest is the merge-patch payload for updating a completion.
type CompletionUpdateRequest struct {
	Reflection *string  `json:"reflection,omitempty"`
	MoodTag    *MoodTag `json:"moodTag,omitempty"`
}

// ShareRequest is the payload for sharing a devotional.
type ShareRequest struct {
	ShareType ShareType `json:"shareType"`
	ContactID *string   `json:"contactId,omitempty"`
}

// ExportRequest is the payload for exporting devotional history.
type ExportRequest struct {
	StartDate          *string `json:"startDate,omitempty"`
	EndDate            *string `json:"endDate,omitempty"`
	IncludeReflections *bool   `json:"includeReflections,omitempty"`
}

// ListDevotionalsParams holds query parameters for listing devotionals.
type ListDevotionalsParams struct {
	Cursor   string
	Limit    int
	Topic    *Topic
	Author   *string
	SeriesID *string
	Tier     *ContentTier
	Language *Language
	Search   *string
}

// ListHistoryParams holds query parameters for listing devotional history.
type ListHistoryParams struct {
	Cursor            string
	Limit             int
	SeriesID          *string
	Topic             *Topic
	Author            *string
	StartDate         *string
	EndDate           *string
	SearchReflections *string
	Sort              string
}

// --- Response Envelope Types ---

// DevotionalResponse wraps a single Devotional.
type DevotionalResponse struct {
	Data  Devotional        `json:"data"`
	Links map[string]string `json:"links,omitempty"`
}

// DevotionalListResponse wraps a list of DevotionalSummary items.
type DevotionalListResponse struct {
	Data  []DevotionalSummary    `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
}

// CompletionResponse wraps a single DevotionalCompletion.
type CompletionResponse struct {
	Data DevotionalCompletion   `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}

// HistoryResponse wraps a list of completions for history.
type HistoryResponse struct {
	Data  []DevotionalCompletion `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
}

// FavoritesResponse wraps a list of favorite devotionals.
type FavoritesResponse struct {
	Data  []DevotionalSummary    `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
}

// SeriesListResponse wraps a list of devotional series.
type SeriesListResponse struct {
	Data  []DevotionalSeries     `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
}

// SeriesResponse wraps a single DevotionalSeries.
type SeriesResponse struct {
	Data DevotionalSeries `json:"data"`
}

// ActivateSeriesResponse is the response for activating a series.
type ActivateSeriesResponse struct {
	Data struct {
		ActiveSeriesID string        `json:"activeSeriesId"`
		CurrentDay     int           `json:"currentDay"`
		TotalDays      int           `json:"totalDays"`
		PausedSeries   *PausedSeries `json:"pausedSeries"`
	} `json:"data"`
}

// PausedSeries represents a previously active series that was paused.
type PausedSeries struct {
	SeriesID    string `json:"seriesId"`
	PausedAtDay int    `json:"pausedAtDay"`
}

// ShareResponse is the response for sharing a devotional.
type ShareResponse struct {
	Data struct {
		ShareURL          *string `json:"shareUrl"`
		SharedToContactID *string `json:"sharedToContactId"`
		Message           string  `json:"message"`
	} `json:"data"`
}

// StreakResponse wraps the devotional streak.
type StreakResponse struct {
	Data DevotionalStreak `json:"data"`
}

// ExportResponse is the response for initiating an export.
type ExportResponse struct {
	Data struct {
		ExportID string            `json:"exportId"`
		Status   string            `json:"status"`
		Links    map[string]string `json:"links,omitempty"`
	} `json:"data"`
}

// --- Internal Storage Models ---

// DevotionalContent is the internal storage model for devotional content.
type DevotionalContent struct {
	DevotionalID       string                       `bson:"devotionalId"`
	EntityType         string                       `bson:"entityType"`
	TenantID           string                       `bson:"tenantId"`
	CreatedAt          time.Time                    `bson:"createdAt"`
	ModifiedAt         time.Time                    `bson:"modifiedAt"`
	Title              string                       `bson:"title"`
	ScriptureReference string                       `bson:"scriptureReference"`
	ScriptureText      map[BibleTranslation]string  `bson:"scriptureText"`
	Reading            map[Language]string           `bson:"reading"`
	RecoveryConnection map[Language]string           `bson:"recoveryConnection"`
	ReflectionQuestion map[Language]string           `bson:"reflectionQuestion"`
	Prayer             map[Language]string           `bson:"prayer"`
	AuthorName         *string                      `bson:"authorName"`
	AuthorBio          map[Language]string           `bson:"authorBio"`
	Topic              Topic                        `bson:"topic"`
	SeriesID           *string                      `bson:"seriesId"`
	SeriesDay          *int                         `bson:"seriesDay"`
	Tier               ContentTier                  `bson:"tier"`
	FreemiumRotationDay *int                        `bson:"freemiumRotationDay"`
	WordCount          int                          `bson:"wordCount"`
	IsPublished        bool                         `bson:"isPublished"`
	PublishedAt        *time.Time                   `bson:"publishedAt"`
}

// SeriesContent is the internal storage model for series metadata.
type SeriesContent struct {
	SeriesID    string             `bson:"seriesId"`
	EntityType  string             `bson:"entityType"`
	TenantID    string             `bson:"tenantId"`
	CreatedAt   time.Time          `bson:"createdAt"`
	ModifiedAt  time.Time          `bson:"modifiedAt"`
	Name        map[Language]string `bson:"name"`
	Description map[Language]string `bson:"description"`
	AuthorName  *string            `bson:"authorName"`
	TotalDays   int                `bson:"totalDays"`
	Tier        ContentTier        `bson:"tier"`
	Price       *float64           `bson:"price"`
	Currency    *string            `bson:"currency"`
	Category    SeriesCategory     `bson:"category"`
	Language    Language           `bson:"language"`
	ThumbnailURL *string           `bson:"thumbnailUrl"`
	IsPublished bool               `bson:"isPublished"`
	PublishedAt *time.Time         `bson:"publishedAt"`
}

// CompletionDoc is the internal storage model for a devotional completion.
type CompletionDoc struct {
	PK                 string    `bson:"PK"`
	SK                 string    `bson:"SK"`
	EntityType         string    `bson:"EntityType"`
	TenantID           string    `bson:"TenantId"`
	CreatedAt          time.Time `bson:"CreatedAt"`
	ModifiedAt         time.Time `bson:"ModifiedAt"`
	CompletionID       string    `bson:"completionId"`
	DevotionalID       string    `bson:"devotionalId"`
	DevotionalTitle    string    `bson:"devotionalTitle"`
	ScriptureReference string    `bson:"scriptureReference"`
	Reflection         *string   `bson:"reflection"`
	MoodTag            *MoodTag  `bson:"moodTag"`
	SeriesID           *string   `bson:"seriesId"`
	SeriesDay          *int      `bson:"seriesDay"`
	Topic              Topic     `bson:"topic"`
}

// FavoriteDoc is the internal storage model for a devotional favorite.
type FavoriteDoc struct {
	PK                 string    `bson:"PK"`
	SK                 string    `bson:"SK"`
	EntityType         string    `bson:"EntityType"`
	TenantID           string    `bson:"TenantId"`
	CreatedAt          time.Time `bson:"CreatedAt"`
	ModifiedAt         time.Time `bson:"ModifiedAt"`
	DevotionalID       string    `bson:"devotionalId"`
	DevotionalTitle    string    `bson:"devotionalTitle"`
	ScriptureReference string    `bson:"scriptureReference"`
	Topic              Topic     `bson:"topic"`
}

// SeriesProgressDoc is the internal storage model for series progress.
type SeriesProgressDoc struct {
	PK              string     `bson:"PK"`
	SK              string     `bson:"SK"`
	EntityType      string     `bson:"EntityType"`
	TenantID        string     `bson:"TenantId"`
	CreatedAt       time.Time  `bson:"CreatedAt"`
	ModifiedAt      time.Time  `bson:"ModifiedAt"`
	SeriesID        string     `bson:"seriesId"`
	CurrentDay      int        `bson:"currentDay"`
	CompletedDays   int        `bson:"completedDays"`
	Status          SeriesStatus `bson:"status"`
	StartedAt       *time.Time `bson:"startedAt"`
	LastCompletedAt *time.Time `bson:"lastCompletedAt"`
	PausedAt        *time.Time `bson:"pausedAt"`
}

// StreakDoc is the internal storage model for the devotional streak.
type StreakDoc struct {
	PK                string    `bson:"PK"`
	SK                string    `bson:"SK"`
	EntityType        string    `bson:"EntityType"`
	TenantID          string    `bson:"TenantId"`
	CreatedAt         time.Time `bson:"CreatedAt"`
	ModifiedAt        time.Time `bson:"ModifiedAt"`
	CurrentDays       int       `bson:"currentDays"`
	LongestDays       int       `bson:"longestDays"`
	LastCompletedDate *string   `bson:"lastCompletedDate"`
}

// CursorPage represents cursor-based pagination metadata.
type CursorPage struct {
	NextCursor *string `json:"nextCursor"`
	PrevCursor *string `json:"prevCursor"`
	Limit      int     `json:"limit"`
}
