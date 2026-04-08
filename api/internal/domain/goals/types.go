// internal/domain/goals/types.go
package goals

import "time"

// Dynamic represents one of the five dynamics of holistic recovery.
type Dynamic string

const (
	DynamicSpiritual    Dynamic = "spiritual"
	DynamicPhysical     Dynamic = "physical"
	DynamicEmotional    Dynamic = "emotional"
	DynamicIntellectual Dynamic = "intellectual"
	DynamicRelational   Dynamic = "relational"
)

// AllDynamics is the canonical list of all five dynamics.
var AllDynamics = []Dynamic{
	DynamicSpiritual,
	DynamicPhysical,
	DynamicEmotional,
	DynamicIntellectual,
	DynamicRelational,
}

// IsValidDynamic checks whether a string is a valid dynamic.
func IsValidDynamic(s string) bool {
	switch Dynamic(s) {
	case DynamicSpiritual, DynamicPhysical, DynamicEmotional,
		DynamicIntellectual, DynamicRelational:
		return true
	}
	return false
}

// GoalScope represents whether a goal is daily or weekly.
type GoalScope string

const (
	ScopeDaily  GoalScope = "daily"
	ScopeWeekly GoalScope = "weekly"
)

// GoalRecurrence represents the recurrence pattern of a goal.
type GoalRecurrence string

const (
	RecurrenceOneTime      GoalRecurrence = "one-time"
	RecurrenceDaily        GoalRecurrence = "daily"
	RecurrenceSpecificDays GoalRecurrence = "specific-days"
	RecurrenceWeekly       GoalRecurrence = "weekly"
)

// GoalPriority represents goal priority.
type GoalPriority string

const (
	PriorityHigh   GoalPriority = "high"
	PriorityMedium GoalPriority = "medium"
	PriorityLow    GoalPriority = "low"
)

// PriorityRank returns a numeric rank for sorting (lower = higher priority).
func PriorityRank(p GoalPriority) int {
	switch p {
	case PriorityHigh:
		return 0
	case PriorityMedium:
		return 1
	case PriorityLow:
		return 2
	default:
		return 3
	}
}

// GoalInstanceStatus represents the status of a materialized goal instance.
type GoalInstanceStatus string

const (
	StatusPending   GoalInstanceStatus = "pending"
	StatusCompleted GoalInstanceStatus = "completed"
	StatusSkipped   GoalInstanceStatus = "skipped"
	StatusDismissed GoalInstanceStatus = "dismissed"
	StatusCarried   GoalInstanceStatus = "carried"
)

// DayOfWeek represents a day of the week.
type DayOfWeek string

const (
	Monday    DayOfWeek = "monday"
	Tuesday   DayOfWeek = "tuesday"
	Wednesday DayOfWeek = "wednesday"
	Thursday  DayOfWeek = "thursday"
	Friday    DayOfWeek = "friday"
	Saturday  DayOfWeek = "saturday"
	Sunday    DayOfWeek = "sunday"
)

// DayOfWeekFromTime converts a time.Weekday to our DayOfWeek.
func DayOfWeekFromTime(wd time.Weekday) DayOfWeek {
	switch wd {
	case time.Monday:
		return Monday
	case time.Tuesday:
		return Tuesday
	case time.Wednesday:
		return Wednesday
	case time.Thursday:
		return Thursday
	case time.Friday:
		return Friday
	case time.Saturday:
		return Saturday
	case time.Sunday:
		return Sunday
	default:
		return Sunday
	}
}

// DispositionAction represents what happens to an uncompleted goal at end-of-day.
type DispositionAction string

const (
	ActionCarryToTomorrow  DispositionAction = "carry-to-tomorrow"
	ActionSkipped          DispositionAction = "skipped"
	ActionNoLongerRelevant DispositionAction = "no-longer-relevant"
)

// GoalSource represents the origin of an auto-populated goal.
type GoalSource string

const (
	SourceCommitment GoalSource = "commitment"
	SourceActivity   GoalSource = "activity"
	SourcePostMortem GoalSource = "post-mortem"
)

// --- Domain types ---

// WeeklyDailyGoal is a goal definition (template) with recurrence rules.
type WeeklyDailyGoal struct {
	GoalID     string         `json:"goalId"`
	UserID     string         `json:"-"` // internal only
	TenantID   string         `json:"-"` // internal only
	Text       string         `json:"text"`
	Dynamics   []Dynamic      `json:"dynamics"`
	Scope      GoalScope      `json:"scope"`
	Recurrence GoalRecurrence `json:"recurrence"`
	DaysOfWeek []DayOfWeek    `json:"daysOfWeek,omitempty"`
	DayOfWeek  *DayOfWeek     `json:"dayOfWeek,omitempty"`
	Priority   GoalPriority   `json:"priority"`
	Notes      *string        `json:"notes,omitempty"`
	IsActive   bool           `json:"isActive"`
	CreatedAt  time.Time      `json:"createdAt"`
	ModifiedAt time.Time      `json:"-"`
	Links      map[string]string `json:"links,omitempty"`
}

// GoalInstance is a materialized goal for a specific date.
type GoalInstance struct {
	GoalInstanceID string             `json:"goalInstanceId"`
	GoalID         *string            `json:"goalId"`
	UserID         string             `json:"-"`
	TenantID       string             `json:"-"`
	Date           string             `json:"date"` // YYYY-MM-DD
	Text           string             `json:"text"`
	Dynamics       []Dynamic          `json:"dynamics"`
	Scope          GoalScope          `json:"scope"`
	Priority       GoalPriority       `json:"priority"`
	Status         GoalInstanceStatus `json:"status"`
	CompletedAt    *time.Time         `json:"completedAt"`
	Source         *GoalSource        `json:"source"`
	SourceID       *string            `json:"sourceId"`
	CarriedFrom    *string            `json:"carriedFrom,omitempty"`
	Notes          *string            `json:"notes,omitempty"`
	DueDay         *DayOfWeek         `json:"dueDay,omitempty"`
	CreatedAt      time.Time          `json:"-"`
	ModifiedAt     time.Time          `json:"-"`
	Links          map[string]string  `json:"links,omitempty"`
}

// GoalReview stores end-of-day or end-of-week review data.
type GoalReview struct {
	ReviewID    string        `json:"reviewId"`
	UserID      string        `json:"-"`
	TenantID    string        `json:"-"`
	Type        string        `json:"type"` // "daily" or "weekly"
	Date        string        `json:"date"` // date or weekStart
	Dispositions []Disposition `json:"dispositions,omitempty"`
	Reflection  *string       `json:"reflection,omitempty"`
	Reflections *WeeklyReflections `json:"reflections,omitempty"`
	Summary     *ReviewSummary     `json:"summary,omitempty"`
	Stats       *WeeklyStats       `json:"stats,omitempty"`
	CreatedAt   time.Time          `json:"-"`
}

// Disposition records what happened to an uncompleted goal.
type Disposition struct {
	GoalInstanceID string            `json:"goalInstanceId"`
	Action         DispositionAction `json:"action"`
}

// WeeklyReflections stores end-of-week reflection data.
type WeeklyReflections struct {
	BiggestWin              *string  `json:"biggestWin,omitempty"`
	DynamicNeedingAttention *Dynamic `json:"dynamicNeedingAttention,omitempty"`
	FreeText                *string  `json:"freeText,omitempty"`
}

// ReviewSummary captures daily review summary statistics.
type ReviewSummary struct {
	TotalGoals     int            `json:"totalGoals"`
	CompletedGoals int            `json:"completedGoals"`
	CarriedGoals   int            `json:"carriedGoals"`
	SkippedGoals   int            `json:"skippedGoals"`
	DynamicBalance DynamicBalance `json:"dynamicBalance"`
}

// WeeklyStats captures end-of-week statistics.
type WeeklyStats struct {
	TotalGoals                 int            `json:"totalGoals"`
	CompletedGoals             int            `json:"completedGoals"`
	CompletionRate             float64        `json:"completionRate"`
	StrongestDynamic           Dynamic        `json:"strongestDynamic"`
	WeakestDynamic             Dynamic        `json:"weakestDynamic"`
	PreviousWeekCompletionRate float64        `json:"previousWeekCompletionRate"`
	Change                     float64        `json:"change"`
	DynamicBalance             DynamicBalance `json:"dynamicBalance"`
}

// GoalSettings stores user preferences for goals.
type GoalSettings struct {
	UserID                    string    `json:"-"`
	AutoPopulateCommitments   bool      `json:"autoPopulateCommitments"`
	AutoPopulateActivities    bool      `json:"autoPopulateActivities"`
	AutoPopulateCommitmentIDs []string  `json:"autoPopulateCommitmentIds"`
	AutoPopulateActivityTypes []string  `json:"autoPopulateActivityTypes"`
	NudgesEnabled             bool      `json:"nudgesEnabled"`
	NudgesDisabledDynamics    []Dynamic `json:"nudgesDisabledDynamics"`
	Notifications             NotificationSettings `json:"notifications"`
	Links                     map[string]string    `json:"links,omitempty"`
}

// NotificationSettings holds goal notification preferences.
type NotificationSettings struct {
	MorningEnabled    bool      `json:"morningEnabled"`
	MorningTime       string    `json:"morningTime"`
	MiddayEnabled     bool      `json:"middayEnabled"`
	EveningEnabled    bool      `json:"eveningEnabled"`
	EveningTime       string    `json:"eveningTime"`
	WeeklyEnabled     bool      `json:"weeklyEnabled"`
	WeeklyReviewDay   DayOfWeek `json:"weeklyReviewDay"`
	DynamicGapEnabled bool      `json:"dynamicGapEnabled"`
}

// DefaultGoalSettings returns the default settings for a new user.
func DefaultGoalSettings(userID string) *GoalSettings {
	return &GoalSettings{
		UserID:                    userID,
		AutoPopulateCommitments:   false,
		AutoPopulateActivities:    false,
		AutoPopulateCommitmentIDs: []string{},
		AutoPopulateActivityTypes: []string{},
		NudgesEnabled:             true,
		NudgesDisabledDynamics:    []Dynamic{},
		Notifications: NotificationSettings{
			MorningEnabled:    true,
			MorningTime:       "07:00",
			MiddayEnabled:     false,
			EveningEnabled:    true,
			EveningTime:       "21:00",
			WeeklyEnabled:     true,
			WeeklyReviewDay:   Sunday,
			DynamicGapEnabled: true,
		},
	}
}

// --- Balance / Nudge types ---

// DynamicCompletionCount tracks total and completed counts for a dynamic.
type DynamicCompletionCount struct {
	Total          int     `json:"total"`
	Completed      int     `json:"completed"`
	CompletionRate float64 `json:"completionRate,omitempty"`
}

// DynamicBalance maps each dynamic to its completion counts.
type DynamicBalance struct {
	Spiritual    DynamicCompletionCount `json:"spiritual"`
	Physical     DynamicCompletionCount `json:"physical"`
	Emotional    DynamicCompletionCount `json:"emotional"`
	Intellectual DynamicCompletionCount `json:"intellectual"`
	Relational   DynamicCompletionCount `json:"relational"`
}

// DynamicNudge represents a suggestion for an empty dynamic.
type DynamicNudge struct {
	Dynamic   Dynamic `json:"dynamic"`
	Message   string  `json:"message"`
	Dismissed bool    `json:"dismissed"`
}

// --- Trends types ---

// DailyCompletionRate holds completion stats for a single day.
type DailyCompletionRate struct {
	Date           string  `json:"date"`
	CompletionRate float64 `json:"completionRate"`
	TotalGoals     int     `json:"totalGoals"`
	CompletedGoals int     `json:"completedGoals"`
}

// GoalTrends holds the computed trends data.
type GoalTrends struct {
	Period               string                          `json:"period"`
	DailyCompletionRates []DailyCompletionRate           `json:"dailyCompletionRates"`
	DynamicTrends        map[string][]DailyCompletionRate `json:"dynamicTrends"`
	ConsistencyScore     float64                         `json:"consistencyScore"`
	Streaks              GoalStreaks                     `json:"streaks"`
	CorrelationInsights  []CorrelationInsight            `json:"correlationInsights"`
	DynamicBalanceHistory []WeeklyDynamicBalance         `json:"dynamicBalanceHistory"`
}

// GoalStreaks holds streak data for goals.
type GoalStreaks struct {
	AllGoalsCompleted   int `json:"allGoalsCompleted"`
	WeeklyEightyPercent int `json:"weeklyEightyPercent"`
}

// CorrelationInsight represents a computed pattern.
type CorrelationInsight struct {
	Insight    string  `json:"insight"`
	Confidence float64 `json:"confidence"`
}

// WeeklyDynamicBalance holds a week's dynamic balance snapshot.
type WeeklyDynamicBalance struct {
	WeekStart      string         `json:"weekStart"`
	DynamicBalance DynamicBalance `json:"dynamicBalance"`
}

// UserGoalSummary represents the sponsor-visible goal summary.
type UserGoalSummary struct {
	UserID                string                    `json:"userId"`
	Period                string                    `json:"period"`
	CompletionRate        float64                   `json:"completionRate"`
	DynamicBalance        DynamicBalance            `json:"dynamicBalance"`
	ConsistencyScore      float64                   `json:"consistencyScore"`
	WeeklyCompletionRates []WeeklyCompletionRate    `json:"weeklyCompletionRates"`
	StrongestDynamic      Dynamic                   `json:"strongestDynamic"`
	WeakestDynamic        Dynamic                   `json:"weakestDynamic"`
}

// WeeklyCompletionRate is a week-level completion stat.
type WeeklyCompletionRate struct {
	WeekStart      string  `json:"weekStart"`
	CompletionRate float64 `json:"completionRate"`
}

// --- Request types ---

// CreateWeeklyDailyGoalRequest is the payload for creating a goal.
type CreateWeeklyDailyGoalRequest struct {
	Text       string         `json:"text"`
	Dynamics   []Dynamic      `json:"dynamics"`
	Scope      *GoalScope     `json:"scope,omitempty"`
	Recurrence *GoalRecurrence `json:"recurrence,omitempty"`
	DaysOfWeek []DayOfWeek    `json:"daysOfWeek,omitempty"`
	DayOfWeek  *DayOfWeek     `json:"dayOfWeek,omitempty"`
	Priority   *GoalPriority  `json:"priority,omitempty"`
	Notes      *string        `json:"notes,omitempty"`
}

// UpdateWeeklyDailyGoalRequest is the merge-patch payload for updating a goal.
type UpdateWeeklyDailyGoalRequest struct {
	Text       *string         `json:"text,omitempty"`
	Dynamics   []Dynamic       `json:"dynamics,omitempty"`
	Scope      *GoalScope      `json:"scope,omitempty"`
	Recurrence *GoalRecurrence `json:"recurrence,omitempty"`
	DaysOfWeek []DayOfWeek     `json:"daysOfWeek,omitempty"`
	DayOfWeek  *DayOfWeek      `json:"dayOfWeek,omitempty"`
	Priority   *GoalPriority   `json:"priority,omitempty"`
	Notes      *string         `json:"notes,omitempty"`
	IsActive   *bool           `json:"isActive,omitempty"`
}

// SubmitDailyReviewRequest is the payload for submitting a daily review.
type SubmitDailyReviewRequest struct {
	Date         string        `json:"date"`
	Dispositions []Disposition `json:"dispositions"`
	Reflection   *string       `json:"reflection,omitempty"`
}

// SubmitWeeklyReviewRequest is the payload for submitting a weekly review.
type SubmitWeeklyReviewRequest struct {
	WeekOf      string              `json:"weekOf"`
	Reflections *WeeklyReflections  `json:"reflections,omitempty"`
}

// UpdateGoalSettingsRequest is the merge-patch payload for settings.
type UpdateGoalSettingsRequest struct {
	AutoPopulateCommitments   *bool      `json:"autoPopulateCommitments,omitempty"`
	AutoPopulateActivities    *bool      `json:"autoPopulateActivities,omitempty"`
	AutoPopulateCommitmentIDs []string   `json:"autoPopulateCommitmentIds,omitempty"`
	AutoPopulateActivityTypes []string   `json:"autoPopulateActivityTypes,omitempty"`
	NudgesEnabled             *bool      `json:"nudgesEnabled,omitempty"`
	NudgesDisabledDynamics    []Dynamic  `json:"nudgesDisabledDynamics,omitempty"`
	Notifications             *NotificationSettings `json:"notifications,omitempty"`
}

// ExportGoalHistoryRequest is the payload for exporting goal history.
type ExportGoalHistoryRequest struct {
	Format    string   `json:"format"` // "csv" or "pdf"
	StartDate *string  `json:"startDate,omitempty"`
	EndDate   *string  `json:"endDate,omitempty"`
	Dynamic   *Dynamic `json:"dynamic,omitempty"`
}
