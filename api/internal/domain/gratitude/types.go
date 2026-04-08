// Package gratitude implements the Gratitude List domain logic.
//
// Spec: docs/prd/specific-features/GratitudeList/specs/openapi.yaml
// Feature flag: activity.gratitude
package gratitude

import "time"

// Category constants matching the GratitudeCategory enum in the OpenAPI spec.
const (
	CategoryFaithGod       = "faithGod"
	CategoryFamily         = "family"
	CategoryRelationships  = "relationships"
	CategoryHealth         = "health"
	CategoryRecovery       = "recovery"
	CategoryWorkCareer     = "workCareer"
	CategoryNatureBeauty   = "natureBeauty"
	CategorySmallMoments   = "smallMoments"
	CategoryGrowthProgress = "growthProgress"
	CategoryCustom         = "custom"
)

// ValidCategories is the set of valid category values.
var ValidCategories = map[string]bool{
	CategoryFaithGod:       true,
	CategoryFamily:         true,
	CategoryRelationships:  true,
	CategoryHealth:         true,
	CategoryRecovery:       true,
	CategoryWorkCareer:     true,
	CategoryNatureBeauty:   true,
	CategorySmallMoments:   true,
	CategoryGrowthProgress: true,
	CategoryCustom:         true,
}

// MaxItemTextLength is the maximum character length for a gratitude item (GL-DM-AC1).
const MaxItemTextLength = 300

// MinMoodScore is the minimum valid mood score (GL-DM-AC3).
const MinMoodScore = 1

// MaxMoodScore is the maximum valid mood score (GL-DM-AC3).
const MaxMoodScore = 5

// EditWindowDuration is the 24-hour edit window after creation (GL-DM-AC7, GL-DM-AC8).
const EditWindowDuration = 24 * time.Hour

// StreakMilestones are the notification thresholds (GL-IN-AC6).
var StreakMilestones = []int{7, 14, 30, 60, 90, 180, 365}

// Entry represents a gratitude list entry (maps to GratitudeEntry in OpenAPI spec).
type Entry struct {
	GratitudeID string    `json:"gratitudeId" bson:"gratitudeId"`
	UserID      string    `json:"userId" bson:"userId"`
	TenantID    string    `json:"tenantId" bson:"tenantId"`
	Timestamp   time.Time `json:"timestamp" bson:"timestamp"`
	Items       []Item    `json:"items" bson:"items"`
	MoodScore   *int      `json:"moodScore,omitempty" bson:"moodScore,omitempty"`
	PhotoKey    *string   `json:"photoKey,omitempty" bson:"photoKey,omitempty"`
	PromptUsed  *string   `json:"promptUsed,omitempty" bson:"promptUsed,omitempty"`
	IsFavorite  bool      `json:"isFavorite" bson:"isFavorite"`
	CreatedAt   time.Time `json:"createdAt" bson:"createdAt"`
	ModifiedAt  time.Time `json:"modifiedAt" bson:"modifiedAt"`
}

// IsEditable returns true if the entry is within the 24-hour edit window (GL-DM-AC7).
func (e *Entry) IsEditable() bool {
	return time.Since(e.CreatedAt) < EditWindowDuration
}

// Item represents a single gratitude item within an entry.
type Item struct {
	ItemID     string  `json:"itemId" bson:"itemId"`
	Text       string  `json:"text" bson:"text"`
	Category   *string `json:"category,omitempty" bson:"category,omitempty"`
	IsFavorite bool    `json:"isFavorite" bson:"isFavorite"`
	SortOrder  int     `json:"sortOrder" bson:"sortOrder"`
}

// CreateEntryRequest is the request payload for creating a gratitude entry.
type CreateEntryRequest struct {
	Timestamp  time.Time        `json:"timestamp"`
	Items      []ItemInput      `json:"items"`
	MoodScore  *int             `json:"moodScore,omitempty"`
	PhotoKey   *string          `json:"photoKey,omitempty"`
	PromptUsed *string          `json:"promptUsed,omitempty"`
}

// UpdateEntryRequest is the request payload for updating a gratitude entry.
type UpdateEntryRequest struct {
	Items      []ItemInput `json:"items"`
	MoodScore  *int        `json:"moodScore,omitempty"`
	PhotoKey   *string     `json:"photoKey,omitempty"`
	PromptUsed *string     `json:"promptUsed,omitempty"`
}

// ItemInput is the input for creating/updating a gratitude item.
type ItemInput struct {
	Text       string  `json:"text"`
	Category   *string `json:"category,omitempty"`
	SortOrder  int     `json:"sortOrder"`
	IsFavorite bool    `json:"isFavorite"`
}

// StreakData holds computed streak information (GL-TI-AC1 through GL-TI-AC4).
type StreakData struct {
	CurrentStreak       int `json:"currentStreak"`
	LongestStreak       int `json:"longestStreak"`
	TotalDaysWithEntries int `json:"totalDaysWithEntries"`
}

// CategoryBreakdownItem holds category distribution data (GL-TI-AC5).
type CategoryBreakdownItem struct {
	Category   string  `json:"category"`
	Count      int     `json:"count"`
	Percentage float64 `json:"percentage"`
}

// Prompt represents a gratitude prompt from the curated library.
type Prompt struct {
	PromptID string `json:"promptId"`
	Text     string `json:"text"`
	Category string `json:"category"`
}

// WidgetData holds the compact data for the Today screen widget (GL-IN-AC3).
type WidgetData struct {
	CompletedToday bool        `json:"completedToday"`
	CurrentStreak  int         `json:"currentStreak"`
	RandomPastItem *RandomItem `json:"randomPastItem,omitempty"`
}

// RandomItem represents a random past gratitude item for display.
type RandomItem struct {
	Text string `json:"text"`
	Date string `json:"date"`
}

// CalendarDay represents a day with gratitude entries for the calendar view.
type CalendarDay struct {
	Date       string `json:"date"`
	EntryCount int    `json:"entryCount"`
}

// ShareRequest represents a request to share gratitude content.
type ShareRequest struct {
	ShareType      string   `json:"shareType"`      // "entry" or "item"
	ItemID         *string  `json:"itemId,omitempty"`
	Target         string   `json:"target"`          // "supportNetwork", "clipboard", "styledGraphic"
	ContactIDs     []string `json:"contactIds,omitempty"`
}

// ShareResponse represents shared gratitude content.
type ShareResponse struct {
	SharedText string  `json:"sharedText"`
	SharedDate string  `json:"sharedDate"`
	GraphicURL *string `json:"graphicUrl,omitempty"`
	SentTo     []string `json:"sentTo,omitempty"`
}

// EntryResponse is the API response envelope for a single entry.
type EntryResponse struct {
	Data  Entry                  `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta"`
}

// EntryListResponse is the API response envelope for multiple entries.
type EntryListResponse struct {
	Data  []EntrySummary         `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta"`
}

// EntrySummary is the compact entry view for list responses (GL-HS-AC2).
type EntrySummary struct {
	GratitudeID string   `json:"gratitudeId"`
	Timestamp   string   `json:"timestamp"`
	ItemCount   int      `json:"itemCount"`
	PreviewItems []string `json:"previewItems"`
	Categories  []string `json:"categories"`
	MoodScore   *int     `json:"moodScore,omitempty"`
	HasPhoto    bool     `json:"hasPhoto"`
	IsEditable  bool     `json:"isEditable"`
}
