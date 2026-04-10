// internal/domain/threecircles/types.go
package threecircles

import (
	"errors"
	"time"
)

// Sentinel errors for circle set and item management.
var (
	ErrInvalidCircleType        = errors.New("invalid circle type")
	ErrInvalidStatus            = errors.New("invalid circle set status")
	ErrInvalidRecoveryArea      = errors.New("invalid recovery area")
	ErrInvalidFramework         = errors.New("invalid framework preference")
	ErrInvalidSource            = errors.New("invalid circle item source")
	ErrInvalidChangeType        = errors.New("invalid change type")
	ErrSetNameTooLong           = errors.New("set name exceeds 100 characters")
	ErrSetNameEmpty             = errors.New("set name cannot be empty")
	ErrBehaviorNameTooLong      = errors.New("behavior name exceeds 200 characters")
	ErrBehaviorNameEmpty        = errors.New("behavior name cannot be empty")
	ErrNotesTooLong             = errors.New("notes exceed 1000 characters")
	ErrSpecificityDetailTooLong = errors.New("specificity detail exceeds 500 characters")
	ErrCategoryTooLong          = errors.New("category exceeds 50 characters")
	ErrInnerCircleFull          = errors.New("inner circle is full (max 20 items)")
	ErrMiddleCircleFull         = errors.New("middle circle is full (max 50 items)")
	ErrOuterCircleFull          = errors.New("outer circle is full (max 50 items)")
	ErrInnerCircleEmpty         = errors.New("inner circle must have at least 1 item to commit")
	ErrCannotCommitActive       = errors.New("circle set is already active")
	ErrCannotCommitArchived     = errors.New("circle set is archived and cannot be committed")
	ErrItemNotFound             = errors.New("circle item not found")
	ErrSameCircleMove           = errors.New("item is already in the target circle")
	ErrChangeNoteTooLong        = errors.New("change note exceeds 500 characters")
)

// Sentinel errors for pattern visualization.
var (
	ErrInvalidPeriod         = errors.New("invalid period")
	ErrInsufficientData      = errors.New("insufficient data for analysis")
	ErrInvalidDateRange      = errors.New("invalid date range")
	ErrInvalidInsightType    = errors.New("invalid insight type")
	ErrInvalidWindowSize     = errors.New("invalid window size for drift detection")
	ErrSetNotFound           = errors.New("three circles set not found")
	ErrAlertAlreadyDismissed = errors.New("alert already dismissed")
)

// CircleType represents the three circles classification.
type CircleType string

const (
	CircleInner  CircleType = "inner"
	CircleMiddle CircleType = "middle"
	CircleOuter  CircleType = "outer"

	// Aliases used by some modules.
	CircleTypeInner  = CircleInner
	CircleTypeMiddle = CircleMiddle
	CircleTypeOuter  = CircleOuter
)

// IsValid returns true if the circle type is recognized.
func (ct CircleType) IsValid() bool {
	return ct == CircleInner || ct == CircleMiddle || ct == CircleOuter
}

// TimelineEntry represents a single day's Three Circles data.
type TimelineEntry struct {
	Date           string     `json:"date"`           // ISO 8601 date string (YYYY-MM-DD)
	SetID          string     `json:"setId"`          // Three Circles set ID for this date
	DominantCircle CircleType `json:"dominantCircle"` // Most significant circle contacted
	InnerContact   bool       `json:"innerContact"`   // Did user contact inner circle?
	MiddleContact  bool       `json:"middleContact"`  // Did user contact middle circle?
	OuterContact   bool       `json:"outerContact"`   // Did user contact outer circle?
	MoodScore      int        `json:"moodScore"`      // 1-10, 0 if no check-in
	UrgeIntensity  int        `json:"urgeIntensity"`  // Max urge intensity for day, 0 if none
	CheckinID      string     `json:"checkinId"`      // Daily check-in ID if exists
}

// TimelineSummary represents aggregated stats for a time period.
type TimelineSummary struct {
	Period                      string `json:"period"`                      // "7d", "30d", "90d", "1y", "all"
	StartDate                   string `json:"startDate"`                   // ISO 8601 date
	EndDate                     string `json:"endDate"`                     // ISO 8601 date
	OuterDays                   int    `json:"outerDays"`                   // Days with outer circle as dominant
	MiddleDays                  int    `json:"middleDays"`                  // Days with middle circle as dominant
	InnerDays                   int    `json:"innerDays"`                   // Days with inner circle as dominant
	NoCheckinDays               int    `json:"noCheckinDays"`               // Days without check-in
	CurrentConsecutiveOuterDays int    `json:"currentConsecutiveOuterDays"` // Current streak of outer circle days
	FramingMessage              string `json:"framingMessage"`              // Descriptive, non-grading message
}

// InsightType represents the type of pattern insight.
type InsightType string

const (
	InsightDayOfWeek  InsightType = "dayOfWeek"  // Patterns by day of week
	InsightTimeOfDay  InsightType = "timeOfDay"  // Patterns by time of day
	InsightTrigger    InsightType = "trigger"    // Correlations with triggers
	InsightProtective InsightType = "protective" // Correlations with protective factors
	InsightSleep      InsightType = "sleep"      // Sleep correlations
	InsightSEEDS      InsightType = "seeds"      // SEEDS correlations
)

// IsValid returns true if the insight type is recognized.
func (it InsightType) IsValid() bool {
	switch it {
	case InsightDayOfWeek, InsightTimeOfDay, InsightTrigger, InsightProtective, InsightSleep, InsightSEEDS:
		return true
	default:
		return false
	}
}

// PatternInsight represents an observed pattern with actionable suggestion.
type PatternInsight struct {
	ID               string      `json:"id"`
	InsightType      InsightType `json:"insightType"`
	Description      string      `json:"description"`      // Observation without judgment
	ActionSuggestion string      `json:"actionSuggestion"` // Constructive next step
	Confidence       float64     `json:"confidence"`       // 0.0-1.0
	DataWindowStart  string      `json:"dataWindowStart"`  // ISO 8601 date
	DataWindowEnd    string      `json:"dataWindowEnd"`    // ISO 8601 date
	Dismissed        bool        `json:"dismissed"`
}

// DriftAlert represents a drift detection alert when user contacts middle circle frequently.
type DriftAlert struct {
	ID               string     `json:"id"`
	SetID            string     `json:"setId"` // Most recent set ID in window
	UserID           string     `json:"userId"`
	WindowStart      string     `json:"windowStart"`      // ISO 8601 date
	WindowEnd        string     `json:"windowEnd"`        // ISO 8601 date
	MiddleCircleDays int        `json:"middleCircleDays"` // Number of middle circle days in window
	Message          string     `json:"message"`          // Gentle, non-punitive message
	Dismissed        bool       `json:"dismissed"`
	DismissedAt      *time.Time `json:"dismissedAt,omitempty"`
	ActionTaken      string     `json:"actionTaken,omitempty"` // User's response
	CreatedAt        time.Time  `json:"createdAt"`
}

// WeeklySummary represents a weekly summary of Three Circles data.
type WeeklySummary struct {
	WeekStart          string             `json:"weekStart"`          // ISO 8601 date (Monday)
	WeekEnd            string             `json:"weekEnd"`            // ISO 8601 date (Sunday)
	CircleDistribution map[CircleType]int `json:"circleDistribution"` // Count per circle
	TopInsights        []PatternInsight   `json:"topInsights"`        // Top 3 insights
	MoodTrend          string             `json:"moodTrend"`          // "improving", "stable", "declining", "insufficient"
	FramingMessage     string             `json:"framingMessage"`     // Weekly framing message
}

// MonthlySummary represents a monthly summary of Three Circles data.
type MonthlySummary struct {
	MonthStart         string             `json:"monthStart"`         // ISO 8601 date (first day of month)
	MonthEnd           string             `json:"monthEnd"`           // ISO 8601 date (last day of month)
	CircleDistribution map[CircleType]int `json:"circleDistribution"` // Count per circle
	TopInsights        []PatternInsight   `json:"topInsights"`        // Top 3 insights
	MoodTrend          string             `json:"moodTrend"`          // "improving", "stable", "declining", "insufficient"
	FramingMessage     string             `json:"framingMessage"`     // Monthly framing message
}

// Period represents valid time periods for timeline queries.
type Period string

const (
	Period7D  Period = "7d"
	Period30D Period = "30d"
	Period90D Period = "90d"
	Period1Y  Period = "1y"
	PeriodAll Period = "all"
)

// IsValid returns true if the period is recognized.
func (p Period) IsValid() bool {
	switch p {
	case Period7D, Period30D, Period90D, Period1Y, PeriodAll:
		return true
	default:
		return false
	}
}

// MoodTrend represents mood trend classification.
type MoodTrend string

const (
	MoodImproving    MoodTrend = "improving"
	MoodStable       MoodTrend = "stable"
	MoodDeclining    MoodTrend = "declining"
	MoodInsufficient MoodTrend = "insufficient"
)

// ── Circle Set and Item Management Types ──

// CircleSetStatus represents the lifecycle status of a circle set.
type CircleSetStatus string

const (
	StatusDraft    CircleSetStatus = "draft"
	StatusActive   CircleSetStatus = "active"
	StatusArchived CircleSetStatus = "archived"
)

// IsValid returns true if the status is recognized.
func (cs CircleSetStatus) IsValid() bool {
	switch cs {
	case StatusDraft, StatusActive, StatusArchived:
		return true
	default:
		return false
	}
}

// CircleItemSource represents the origin of a circle item.
type CircleItemSource string

const (
	SourceUser        CircleItemSource = "user"
	SourceTemplate    CircleItemSource = "template"
	SourceStarterPack CircleItemSource = "starterPack"
)

// IsValid returns true if the source is recognized.
func (cis CircleItemSource) IsValid() bool {
	switch cis {
	case SourceUser, SourceTemplate, SourceStarterPack:
		return true
	default:
		return false
	}
}

// ChangeType represents the type of change made to a circle set.
type ChangeType string

const (
	ChangeItemAdded          ChangeType = "itemAdded"
	ChangeItemUpdated        ChangeType = "itemUpdated"
	ChangeItemDeleted        ChangeType = "itemDeleted"
	ChangeItemMoved          ChangeType = "itemMoved"
	ChangeSetCommitted       ChangeType = "setCommitted"
	ChangeSetRestored        ChangeType = "setRestored"
	ChangeStarterPackApplied ChangeType = "starterPackApplied"
	ChangeBulkReplace        ChangeType = "bulkReplace"
	ChangeReviewChange       ChangeType = "reviewChange"
)

// IsValid returns true if the change type is recognized.
func (ct ChangeType) IsValid() bool {
	switch ct {
	case ChangeItemAdded, ChangeItemUpdated, ChangeItemDeleted, ChangeItemMoved,
		ChangeSetCommitted, ChangeSetRestored, ChangeStarterPackApplied,
		ChangeBulkReplace, ChangeReviewChange:
		return true
	default:
		return false
	}
}

// CircleItem represents a single item within a circle.
type CircleItem struct {
	ItemID            string           `json:"itemId"`
	BehaviorName      string           `json:"behaviorName"`
	Notes             string           `json:"notes,omitempty"`
	SpecificityDetail string           `json:"specificityDetail,omitempty"`
	Category          string           `json:"category,omitempty"`
	Source            CircleItemSource `json:"source"`
	SourceTemplateID  string           `json:"sourceTemplateId,omitempty"`
	Uncertain         bool             `json:"uncertain"`
	SortOrder         int              `json:"sortOrder"`
	CreatedAt         time.Time        `json:"createdAt"`
	ModifiedAt        time.Time        `json:"modifiedAt"`
}

// CircleSet represents a user's Three Circles configuration.
type CircleSet struct {
	ID                  string               `json:"setId"`
	UserID              string               `json:"userId"`
	TenantID            string               `json:"tenantId"`
	Name                string               `json:"name"`
	RecoveryArea        RecoveryArea         `json:"recoveryArea"`
	FrameworkPreference *FrameworkPreference `json:"frameworkPreference,omitempty"`
	Status              CircleSetStatus      `json:"status"`
	InnerCircle         []CircleItem         `json:"innerCircle"`
	MiddleCircle        []CircleItem         `json:"middleCircle"`
	OuterCircle         []CircleItem         `json:"outerCircle"`
	CurrentVersion      int                  `json:"versionNumber"`
	CommittedAt         *time.Time           `json:"committedAt,omitempty"`
	CreatedAt           time.Time            `json:"createdAt"`
	ModifiedAt          time.Time            `json:"modifiedAt"`
}

// VersionSnapshot represents a historical snapshot of a circle set.
type VersionSnapshot struct {
	VersionNumber int        `json:"versionNumber"`
	SetID         string     `json:"setId"`
	UserID        string     `json:"userId"`
	Snapshot      CircleSet  `json:"snapshot"`
	ChangeNote    string     `json:"changeNote,omitempty"`
	ChangeType    ChangeType `json:"changeType"`
	ChangedItems  []string   `json:"changedItems,omitempty"`
	InnerCount    int        `json:"innerCount"`
	MiddleCount   int        `json:"middleCount"`
	OuterCount    int        `json:"outerCount"`
	ChangedAt     time.Time  `json:"changedAt"`
}

// Request types for circle set operations.

// CreateCircleSetRequest represents a request to create a new circle set.
type CreateCircleSetRequest struct {
	Name                string               `json:"name"`
	RecoveryArea        RecoveryArea         `json:"recoveryArea"`
	FrameworkPreference *FrameworkPreference `json:"frameworkPreference,omitempty"`
	CommitImmediately   bool                 `json:"commitImmediately"`
}

// UpdateCircleSetRequest represents a request to update a circle set (merge patch).
type UpdateCircleSetRequest struct {
	Name                *string              `json:"name,omitempty"`
	FrameworkPreference *FrameworkPreference `json:"frameworkPreference,omitempty"`
}

// ReplaceCircleSetRequest represents a request to fully replace a circle set.
type ReplaceCircleSetRequest struct {
	Name         string       `json:"name"`
	InnerCircle  []CircleItem `json:"innerCircle"`
	MiddleCircle []CircleItem `json:"middleCircle"`
	OuterCircle  []CircleItem `json:"outerCircle"`
	ChangeNote   string       `json:"changeNote,omitempty"`
}

// CreateCircleItemRequest represents a request to add a circle item.
type CreateCircleItemRequest struct {
	Circle            CircleType       `json:"circle"`
	BehaviorName      string           `json:"behaviorName"`
	Notes             string           `json:"notes,omitempty"`
	SpecificityDetail string           `json:"specificityDetail,omitempty"`
	Category          string           `json:"category,omitempty"`
	Source            CircleItemSource `json:"source"`
	SourceTemplateID  string           `json:"sourceTemplateId,omitempty"`
	Uncertain         bool             `json:"uncertain"`
}

// UpdateCircleItemRequest represents a request to update a circle item.
type UpdateCircleItemRequest struct {
	BehaviorName      string `json:"behaviorName,omitempty"`
	Notes             string `json:"notes,omitempty"`
	SpecificityDetail string `json:"specificityDetail,omitempty"`
	Category          string `json:"category,omitempty"`
	Uncertain         *bool  `json:"uncertain,omitempty"`
}

// MoveCircleItemRequest represents a request to move an item between circles.
type MoveCircleItemRequest struct {
	TargetCircle CircleType `json:"targetCircle"`
	ChangeNote   string     `json:"changeNote,omitempty"`
}

// CommitCircleSetRequest represents a request to commit a draft circle set.
type CommitCircleSetRequest struct {
	ChangeNote string `json:"changeNote,omitempty"`
}

// Response envelope types.

// CircleSetResponse wraps a single CircleSet.
type CircleSetResponse struct {
	Data  CircleSet              `json:"data"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
	Links map[string]string      `json:"links,omitempty"`
}

// CircleSetListResponse wraps a list of CircleSet items.
type CircleSetListResponse struct {
	Data  []CircleSet            `json:"data"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
	Links map[string]string      `json:"links,omitempty"`
}

// CircleItemResponse wraps a single CircleItem.
type CircleItemResponse struct {
	Data  CircleItem             `json:"data"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
	Links map[string]string      `json:"links,omitempty"`
}

// VersionSnapshotResponse wraps a single VersionSnapshot.
type VersionSnapshotResponse struct {
	Data  VersionSnapshot        `json:"data"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
	Links map[string]string      `json:"links,omitempty"`
}

// VersionHistoryResponse wraps a list of VersionSnapshot items.
type VersionHistoryResponse struct {
	Data  []VersionSnapshot      `json:"data"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
	Links map[string]string      `json:"links,omitempty"`
}
