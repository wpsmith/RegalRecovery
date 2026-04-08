// internal/domain/actingin/types.go
package actingin

import "time"

// Feature flag key for acting-in behaviors activity.
const FeatureFlagKey = "activity.acting-in-behaviors"

// Trigger represents what prompted an acting-in behavior.
type Trigger string

const (
	TriggerStress      Trigger = "stress"
	TriggerConflict    Trigger = "conflict"
	TriggerFear        Trigger = "fear"
	TriggerShame       Trigger = "shame"
	TriggerExhaustion  Trigger = "exhaustion"
	TriggerLoneliness  Trigger = "loneliness"
	TriggerOther       Trigger = "other"
)

// ValidTriggers is the set of valid trigger values.
var ValidTriggers = map[Trigger]bool{
	TriggerStress:     true,
	TriggerConflict:   true,
	TriggerFear:       true,
	TriggerShame:      true,
	TriggerExhaustion: true,
	TriggerLoneliness: true,
	TriggerOther:      true,
}

// RelationshipTag represents who was affected by an acting-in behavior.
type RelationshipTag string

const (
	RelationshipSpouse   RelationshipTag = "spouse"
	RelationshipChild    RelationshipTag = "child"
	RelationshipCoworker RelationshipTag = "coworker"
	RelationshipFriend   RelationshipTag = "friend"
	RelationshipSponsor  RelationshipTag = "sponsor"
	RelationshipSelf     RelationshipTag = "self"
	RelationshipOther    RelationshipTag = "other"
)

// ValidRelationshipTags is the set of valid relationship tag values.
var ValidRelationshipTags = map[RelationshipTag]bool{
	RelationshipSpouse:   true,
	RelationshipChild:    true,
	RelationshipCoworker: true,
	RelationshipFriend:   true,
	RelationshipSponsor:  true,
	RelationshipSelf:     true,
	RelationshipOther:    true,
}

// Frequency represents the check-in cadence.
type Frequency string

const (
	FrequencyDaily  Frequency = "daily"
	FrequencyWeekly Frequency = "weekly"
)

// ValidFrequencies is the set of valid frequency values.
var ValidFrequencies = map[Frequency]bool{
	FrequencyDaily:  true,
	FrequencyWeekly: true,
}

// Trend indicates the direction of a behavior pattern.
type Trend string

const (
	TrendIncreasing Trend = "increasing"
	TrendStable     Trend = "stable"
	TrendDecreasing Trend = "decreasing"
)

// InsightsRange represents a time range for insights queries.
type InsightsRange string

const (
	Range7d  InsightsRange = "7d"
	Range30d InsightsRange = "30d"
	Range90d InsightsRange = "90d"
)

// ValidInsightsRanges is the set of valid insights range values.
var ValidInsightsRanges = map[InsightsRange]bool{
	Range7d:  true,
	Range30d: true,
	Range90d: true,
}

// ValidHeatmapRanges is the set of valid heatmap range values (no 7d).
var ValidHeatmapRanges = map[InsightsRange]bool{
	Range30d: true,
	Range90d: true,
}

// RangeToDays converts an InsightsRange to a number of days.
func RangeToDays(r InsightsRange) int {
	switch r {
	case Range7d:
		return 7
	case Range30d:
		return 30
	case Range90d:
		return 90
	default:
		return 30
	}
}

// Weekday represents a day of the week for weekly reminder scheduling.
type Weekday string

const (
	WeekdaySunday    Weekday = "sunday"
	WeekdayMonday    Weekday = "monday"
	WeekdayTuesday   Weekday = "tuesday"
	WeekdayWednesday Weekday = "wednesday"
	WeekdayThursday  Weekday = "thursday"
	WeekdayFriday    Weekday = "friday"
	WeekdaySaturday  Weekday = "saturday"
)

// ValidWeekdays is the set of valid weekday values.
var ValidWeekdays = map[Weekday]bool{
	WeekdaySunday:    true,
	WeekdayMonday:    true,
	WeekdayTuesday:   true,
	WeekdayWednesday: true,
	WeekdayThursday:  true,
	WeekdayFriday:    true,
	WeekdaySaturday:  true,
}

// DefaultBehavior represents a system-provided default acting-in behavior.
type DefaultBehavior struct {
	BehaviorID  string
	Name        string
	Description string
	SortOrder   int
}

// DefaultBehaviors contains all 15 system default acting-in behaviors.
var DefaultBehaviors = []DefaultBehavior{
	{BehaviorID: "beh_default_blame", Name: "Blame", Description: "Shifting responsibility onto others instead of owning your part", SortOrder: 1},
	{BehaviorID: "beh_default_shame", Name: "Shame", Description: "Using shame (toward self or others) as a weapon or control mechanism", SortOrder: 2},
	{BehaviorID: "beh_default_criticism", Name: "Criticism", Description: "Harsh, contemptuous, or demeaning comments toward others", SortOrder: 3},
	{BehaviorID: "beh_default_stonewall", Name: "Stonewall", Description: "Shutting down emotionally, refusing to engage or communicate", SortOrder: 4},
	{BehaviorID: "beh_default_avoid", Name: "Avoid", Description: "Dodging difficult conversations, people, or responsibilities", SortOrder: 5},
	{BehaviorID: "beh_default_hide", Name: "Hide", Description: "Concealing information, activities, or feelings from others", SortOrder: 6},
	{BehaviorID: "beh_default_lie", Name: "Lie", Description: "Telling outright falsehoods or lies of omission", SortOrder: 7},
	{BehaviorID: "beh_default_excuse", Name: "Excuse", Description: "Rationalizing or minimizing harmful behavior", SortOrder: 8},
	{BehaviorID: "beh_default_manipulate", Name: "Manipulate", Description: "Using emotional tactics to control outcomes or other people", SortOrder: 9},
	{BehaviorID: "beh_default_control_anger", Name: "Control with Anger", Description: "Using rage, intimidation, or explosive emotion to dominate", SortOrder: 10},
	{BehaviorID: "beh_default_passivity", Name: "Passivity", Description: "Withdrawing from engagement, letting others carry the weight", SortOrder: 11},
	{BehaviorID: "beh_default_humor", Name: "Humor", Description: "Using jokes or sarcasm to deflect from serious topics or real feelings", SortOrder: 12},
	{BehaviorID: "beh_default_placating", Name: "Placating", Description: "People-pleasing or false agreement to avoid conflict", SortOrder: 13},
	{BehaviorID: "beh_default_withhold", Name: "Withhold Love/Sex", Description: "Punishing or controlling through emotional or physical withdrawal", SortOrder: 14},
	{BehaviorID: "beh_default_hyperspiritualize", Name: "HyperSpiritualize", Description: "Using scripture, prayer, or faith language to avoid accountability or shut down valid concerns", SortOrder: 15},
}

// DefaultBehaviorMap provides O(1) lookup by behaviorId for system defaults.
var DefaultBehaviorMap = func() map[string]DefaultBehavior {
	m := make(map[string]DefaultBehavior, len(DefaultBehaviors))
	for _, b := range DefaultBehaviors {
		m[b.BehaviorID] = b
	}
	return m
}()

// Behavior represents a behavior in the user's catalog (default or custom).
type Behavior struct {
	BehaviorID  string `json:"behaviorId"`
	Name        string `json:"name"`
	Description string `json:"description,omitempty"`
	IsDefault   bool   `json:"isDefault"`
	Enabled     bool   `json:"enabled"`
	SortOrder   int    `json:"sortOrder"`
}

// CustomBehavior represents a user-defined custom behavior.
type CustomBehavior struct {
	BehaviorID  string    `json:"behaviorId"`
	Name        string    `json:"name"`
	Description string    `json:"description,omitempty"`
	Enabled     bool      `json:"enabled"`
	SortOrder   int       `json:"sortOrder"`
	CreatedAt   time.Time `json:"createdAt"`
}

// BehaviorConfig holds a user's complete behavior configuration.
type BehaviorConfig struct {
	UserID          string                   `json:"userId"`
	Defaults        map[string]DefaultState  `json:"defaults"`
	CustomBehaviors []CustomBehavior         `json:"customBehaviors"`
	CreatedAt       time.Time                `json:"createdAt"`
	ModifiedAt      time.Time                `json:"modifiedAt"`
}

// DefaultState represents the enabled/disabled state of a default behavior.
type DefaultState struct {
	Enabled   bool `json:"enabled"`
	SortOrder int  `json:"sortOrder"`
}

// CheckedBehavior represents a single behavior logged during a check-in.
type CheckedBehavior struct {
	BehaviorID      string          `json:"behaviorId"`
	BehaviorName    string          `json:"behaviorName"`
	ContextNote     string          `json:"contextNote,omitempty"`
	Trigger         Trigger         `json:"trigger,omitempty"`
	RelationshipTag RelationshipTag `json:"relationshipTag,omitempty"`
}

// CheckIn represents a single acting-in behaviors check-in.
type CheckIn struct {
	CheckInID           string            `json:"checkInId"`
	UserID              string            `json:"userId"`
	Timestamp           time.Time         `json:"timestamp"`
	BehaviorCount       int               `json:"behaviorCount"`
	Behaviors           []CheckedBehavior `json:"behaviors"`
	Triggers            []Trigger         `json:"triggers,omitempty"`
	RelationshipTags    []RelationshipTag `json:"relationshipTags,omitempty"`
	ConsecutiveCheckIns int               `json:"consecutiveCheckIns"`
	Message             string            `json:"message"`
	CreatedAt           time.Time         `json:"createdAt"`
	ModifiedAt          time.Time         `json:"modifiedAt"`
}

// Settings holds the user's acting-in behavior check-in preferences.
type Settings struct {
	UserID            string    `json:"userId"`
	Frequency         Frequency `json:"frequency"`
	ReminderTime      string    `json:"reminderTime"`
	ReminderDay       Weekday   `json:"reminderDay"`
	FirstUseCompleted bool      `json:"firstUseCompleted"`
	StreakCount        int       `json:"streakCount"`
	LastCheckInAt     *time.Time `json:"lastCheckInAt,omitempty"`
	CreatedAt         time.Time `json:"createdAt"`
	ModifiedAt        time.Time `json:"modifiedAt"`
}

// BehaviorFrequency represents frequency data for a single behavior in insights.
type BehaviorFrequency struct {
	BehaviorID          string  `json:"behaviorId"`
	BehaviorName        string  `json:"behaviorName"`
	Count               int     `json:"count"`
	Trend               Trend   `json:"trend"`
	PercentageOfCheckIns float64 `json:"percentageOfCheckIns"`
}

// FrequencyInsights contains aggregated frequency data for a time range.
type FrequencyInsights struct {
	Range               InsightsRange       `json:"range"`
	Behaviors           []BehaviorFrequency `json:"behaviors"`
	TotalCheckIns       int                 `json:"totalCheckIns"`
	TotalBehaviorsLogged int                `json:"totalBehaviorsLogged"`
}

// TriggerInsight represents aggregated trigger data.
type TriggerInsight struct {
	Trigger          Trigger `json:"trigger"`
	Count            int     `json:"count"`
	PercentageOfTotal float64 `json:"percentageOfTotal"`
}

// TriggerBehaviorCorrelation represents a trigger-to-behavior mapping.
type TriggerBehaviorCorrelation struct {
	Trigger      Trigger              `json:"trigger"`
	TopBehaviors []BehaviorCountEntry `json:"topBehaviors"`
	Narrative    string               `json:"narrative"`
}

// BehaviorCountEntry represents a behavior with a count.
type BehaviorCountEntry struct {
	BehaviorID   string `json:"behaviorId"`
	BehaviorName string `json:"behaviorName"`
	Count        int    `json:"count"`
}

// TriggerInsights contains aggregated trigger analysis data.
type TriggerInsights struct {
	Range        InsightsRange                `json:"range"`
	Triggers     []TriggerInsight             `json:"triggers"`
	Correlations []TriggerBehaviorCorrelation `json:"correlations"`
}

// RelationshipInsight represents aggregated relationship impact data.
type RelationshipInsight struct {
	RelationshipTag RelationshipTag `json:"relationshipTag"`
	Count           int             `json:"count"`
	Trend           Trend           `json:"trend"`
	Narrative       string          `json:"narrative"`
}

// RelationshipInsights contains aggregated relationship impact data.
type RelationshipInsights struct {
	Range         InsightsRange         `json:"range"`
	Relationships []RelationshipInsight `json:"relationships"`
}

// HeatmapCell represents a single cell in the day-of-week x hour-of-day heatmap.
type HeatmapCell struct {
	DayOfWeek int     `json:"dayOfWeek"` // 0=Sunday, 6=Saturday
	HourOfDay int     `json:"hourOfDay"` // 0-23
	Count     int     `json:"count"`
	Intensity float64 `json:"intensity"` // 0.0-1.0 normalized
}

// HeatmapInsights contains the heatmap data.
type HeatmapInsights struct {
	Range InsightsRange `json:"range"`
	Cells []HeatmapCell `json:"cells"`
}

// PciCorrelation contains PCI cross-tool correlation data.
type PciCorrelation struct {
	CorrelationFound bool   `json:"correlationFound"`
	PciElevatedDays  int    `json:"pciElevatedDays,omitempty"`
	Narrative        string `json:"narrative,omitempty"`
}

// FasterStageBreakdown represents acting-in counts per FASTER stage.
type FasterStageBreakdown struct {
	Stage         string `json:"stage"`
	ActingInCount int    `json:"actingInCount"`
}

// FasterCorrelation contains FASTER Scale cross-tool correlation data.
type FasterCorrelation struct {
	CorrelationFound bool                   `json:"correlationFound"`
	StageBreakdown   []FasterStageBreakdown `json:"stageBreakdown,omitempty"`
	Narrative        string                 `json:"narrative,omitempty"`
}

// PostMortemPattern represents acting-in behaviors in a relapse build-up.
type PostMortemPattern struct {
	PostMortemID     string   `json:"postMortemId"`
	RelapseDate      string   `json:"relapseDate"`
	BuildUpBehaviors []string `json:"buildUpBehaviors"`
}

// CrossToolInsights contains cross-tool correlation data.
type CrossToolInsights struct {
	Range             InsightsRange       `json:"range"`
	PciCorrelation    PciCorrelation      `json:"pciCorrelation"`
	FasterCorrelation FasterCorrelation   `json:"fasterCorrelation"`
	PostMortemPatterns []PostMortemPattern `json:"postMortemPatterns"`
}

// --- Request types ---

// CreateCheckInRequest represents a request to submit an acting-in check-in.
type CreateCheckInRequest struct {
	Timestamp time.Time              `json:"timestamp"`
	Behaviors []CheckedBehaviorInput `json:"behaviors"`
}

// CheckedBehaviorInput represents input for a checked behavior in a check-in request.
type CheckedBehaviorInput struct {
	BehaviorID      string          `json:"behaviorId"`
	ContextNote     string          `json:"contextNote,omitempty"`
	Trigger         Trigger         `json:"trigger,omitempty"`
	RelationshipTag RelationshipTag `json:"relationshipTag,omitempty"`
}

// CreateCustomBehaviorRequest represents a request to create a custom behavior.
type CreateCustomBehaviorRequest struct {
	Name        string `json:"name"`
	Description string `json:"description,omitempty"`
}

// UpdateCustomBehaviorRequest represents a request to update a custom behavior.
type UpdateCustomBehaviorRequest struct {
	Name        *string `json:"name,omitempty"`
	Description *string `json:"description,omitempty"`
}

// ToggleBehaviorRequest represents a request to toggle a behavior's enabled state.
type ToggleBehaviorRequest struct {
	Enabled bool `json:"enabled"`
}

// UpdateSettingsRequest represents a request to update acting-in settings.
type UpdateSettingsRequest struct {
	Frequency    *Frequency `json:"frequency,omitempty"`
	ReminderTime *string    `json:"reminderTime,omitempty"`
	ReminderDay  *Weekday   `json:"reminderDay,omitempty"`
}

// --- Response envelope types ---

// BehaviorsResponse wraps the behavior list response.
type BehaviorsResponse struct {
	Data []Behavior             `json:"data"`
	Meta map[string]interface{} `json:"meta"`
}

// BehaviorResponse wraps a single behavior response.
type BehaviorResponse struct {
	Data Behavior               `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}

// CheckInResponse wraps a single check-in response.
type CheckInResponse struct {
	Data CheckIn                `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}

// CheckInsListResponse wraps a paginated list of check-ins.
type CheckInsListResponse struct {
	Data  []CheckIn              `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
}

// FrequencyInsightsResponse wraps frequency insights.
type FrequencyInsightsResponse struct {
	Data FrequencyInsights      `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}

// TriggerInsightsResponse wraps trigger insights.
type TriggerInsightsResponse struct {
	Data TriggerInsights        `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}

// RelationshipInsightsResponse wraps relationship insights.
type RelationshipInsightsResponse struct {
	Data RelationshipInsights   `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}

// HeatmapInsightsResponse wraps heatmap data.
type HeatmapInsightsResponse struct {
	Data HeatmapInsights        `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}

// CrossToolInsightsResponse wraps cross-tool correlation data.
type CrossToolInsightsResponse struct {
	Data CrossToolInsights      `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}

// SettingsResponse wraps settings data.
type SettingsResponse struct {
	Data Settings               `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}

// Compassionate confirmation messages.
var (
	// MessageBehaviorsChecked is the default message when one or more behaviors are checked.
	MessageBehaviorsChecked = "Awareness is the first step toward change. Thank you for being honest."

	// MessageZeroBehaviors is the message when no behaviors are checked.
	MessageZeroBehaviors = "No acting-in behaviors today. That's growth worth noticing."

	// RotatingMessages are post-check-in messages that rotate for variety.
	RotatingMessages = []string{
		"Sobriety is more than not acting out. The work you're doing here is building real character.",
		"Noticing these patterns takes courage. You're becoming someone new.",
		"Every behavior you name loses a little power over you.",
	}

	// FirstUseHelperText is displayed when the user first opens the feature.
	FirstUseHelperText = "Acting-in behaviors are the subtle ways addiction affects our relationships -- even when we're sober. Tracking them helps you see the full picture of your recovery, not just the absence of acting out."

	// ReEngagementMessage is sent when the user misses check-ins.
	ReEngagementMessage = "It's been a few days since your last acting-in check. Picking it back up is always worthwhile."
)
