// internal/domain/exercise/types.go
package exercise

import "time"

// Feature flag key for exercise activity.
const FeatureFlagKey = "activity.exercise"

// ActivityType constants matching OpenAPI enum.
const (
	ActivityTypeWalking      = "walking"
	ActivityTypeRunning      = "running"
	ActivityTypeGym          = "gym"
	ActivityTypeYoga         = "yoga"
	ActivityTypeSwimming     = "swimming"
	ActivityTypeCycling      = "cycling"
	ActivityTypeSports       = "sports"
	ActivityTypeHiking       = "hiking"
	ActivityTypeDance        = "dance"
	ActivityTypeMartialArts  = "martial-arts"
	ActivityTypeGroupFitness = "group-fitness"
	ActivityTypeHomeWorkout  = "home-workout"
	ActivityTypeYardwork     = "yardwork"
	ActivityTypeOther        = "other"
)

// ValidActivityTypes is the set of all valid activity types.
var ValidActivityTypes = map[string]bool{
	ActivityTypeWalking:      true,
	ActivityTypeRunning:      true,
	ActivityTypeGym:          true,
	ActivityTypeYoga:         true,
	ActivityTypeSwimming:     true,
	ActivityTypeCycling:      true,
	ActivityTypeSports:       true,
	ActivityTypeHiking:       true,
	ActivityTypeDance:        true,
	ActivityTypeMartialArts:  true,
	ActivityTypeGroupFitness: true,
	ActivityTypeHomeWorkout:  true,
	ActivityTypeYardwork:     true,
	ActivityTypeOther:        true,
}

// IntensityLevel constants matching OpenAPI enum.
const (
	IntensityLight    = "light"
	IntensityModerate = "moderate"
	IntensityVigorous = "vigorous"
)

// ValidIntensityLevels is the set of valid intensity levels.
var ValidIntensityLevels = map[string]bool{
	IntensityLight:    true,
	IntensityModerate: true,
	IntensityVigorous: true,
}

// Source constants matching OpenAPI enum.
const (
	SourceManual      = "manual"
	SourceAppleHealth = "apple-health"
	SourceGoogleFit   = "google-fit"
)

// ValidSources is the set of valid data sources.
var ValidSources = map[string]bool{
	SourceManual:      true,
	SourceAppleHealth: true,
	SourceGoogleFit:   true,
}

// ExerciseLog represents a single exercise log entry.
type ExerciseLog struct {
	ExerciseID      string
	UserID          string
	TenantID        string
	Timestamp       time.Time
	ActivityType    string
	CustomTypeLabel *string
	DurationMinutes int
	Intensity       *string
	Notes           *string
	MoodBefore      *int
	MoodAfter       *int
	Source          string
	ExternalID      *string
	CreatedAt       time.Time
	ModifiedAt      time.Time
}

// ExerciseFavorite represents a saved favorite activity for quick logging.
type ExerciseFavorite struct {
	FavoriteID             string
	UserID                 string
	TenantID               string
	ActivityType           string
	CustomTypeLabel        *string
	DefaultDurationMinutes int
	DefaultIntensity       *string
	Label                  string
	SortOrder              int
	CreatedAt              time.Time
	ModifiedAt             time.Time
}

// ExerciseGoal represents the user's weekly exercise goal.
type ExerciseGoal struct {
	UserID              string
	TenantID            string
	TargetActiveMinutes *int
	TargetSessions      *int
	CreatedAt           time.Time
	ModifiedAt          time.Time
}

// ExerciseStreak represents computed exercise streak data.
type ExerciseStreak struct {
	CurrentDays      int
	LongestDays      int
	LastExerciseDate *string
	NextMilestone    *MilestoneInfo
}

// MilestoneInfo represents the next streak milestone.
type MilestoneInfo struct {
	Days          int
	DaysRemaining int
	Label         string
}

// ExerciseStats represents exercise statistics for a period.
type ExerciseStats struct {
	Period                   string
	ReferenceDate            string
	TotalActiveMinutes       int
	SessionCount             int
	MostCommonActivityType   *string
	ComparisonToPrevious     *PeriodComparison
	Streak                   ExerciseStreak
	ActivityTypeDistribution []ActivityTypeCount
	IntensityDistribution    []IntensityCount
}

// PeriodComparison holds comparison data to the previous period.
type PeriodComparison struct {
	ActiveMinutesDelta         int
	ActiveMinutesPercentChange float64
	SessionCountDelta          int
}

// ActivityTypeCount represents activity type distribution data.
type ActivityTypeCount struct {
	ActivityType string
	Count        int
	TotalMinutes int
}

// IntensityCount represents intensity distribution data.
type IntensityCount struct {
	Intensity string
	Count     int
}

// CorrelationInsights represents exercise-recovery correlation data.
type CorrelationInsights struct {
	SufficientData bool
	Insights       []Insight
}

// Insight represents a single correlation insight.
type Insight struct {
	Type              string
	Message           string
	PercentDelta      *float64
	PointsDelta       *float64
	DaysSinceExercise *int
}

// GoalProgress represents current progress toward a weekly goal.
type GoalProgress struct {
	TargetActiveMinutes *int
	TargetSessions      *int
	CurrentActiveMinutes int
	CurrentSessions      int
	ProgressPercent      float64
	WeekStartDate        string
	IsGoalMet            bool
}

// WidgetData represents compact exercise data for the dashboard widget.
type WidgetData struct {
	ExercisedToday     bool
	TodayActiveMinutes int
	TodaySessions      int
	Streak             StreakSummary
	WeeklyGoal         *WeeklyGoalSummary
}

// StreakSummary is the minimal streak data for the widget.
type StreakSummary struct {
	CurrentDays int
}

// WeeklyGoalSummary is the minimal goal data for the widget.
type WeeklyGoalSummary struct {
	TargetActiveMinutes  int
	CurrentActiveMinutes int
	ProgressPercent      float64
	IsGoalMet            bool
}

// ListOptions represents pagination and filtering options for listing exercise logs.
type ListOptions struct {
	ActivityType *string
	Intensity    *string
	StartDate    *time.Time
	EndDate      *time.Time
	Search       *string
	Cursor       *string
	Limit        int
	Sort         string
}

// CreateExerciseLogRequest represents the request to create an exercise log.
type CreateExerciseLogRequest struct {
	Timestamp       time.Time
	ActivityType    string
	CustomTypeLabel *string
	DurationMinutes int
	Intensity       *string
	Notes           *string
	MoodBefore      *int
	MoodAfter       *int
	Source          string
	ExternalID      *string
}

// UpdateExerciseLogRequest represents the request to update an exercise log.
// Only mutable fields are included.
type UpdateExerciseLogRequest struct {
	Intensity       *string
	Notes           *string
	MoodBefore      *int
	MoodAfter       *int
	CustomTypeLabel *string
}

// ImmutableFields are fields that cannot be changed after creation (FR2.7).
var ImmutableFields = []string{"timestamp", "createdAt", "activityType", "durationMinutes", "source"}
