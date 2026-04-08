// internal/domain/nutrition/types.go
package nutrition

import "time"

// MealType represents the type of meal.
type MealType string

const (
	MealTypeBreakfast MealType = "breakfast"
	MealTypeLunch     MealType = "lunch"
	MealTypeDinner    MealType = "dinner"
	MealTypeSnack     MealType = "snack"
	MealTypeOther     MealType = "other"
)

// ValidMealTypes contains all accepted meal type values.
var ValidMealTypes = map[MealType]bool{
	MealTypeBreakfast: true,
	MealTypeLunch:     true,
	MealTypeDinner:    true,
	MealTypeSnack:     true,
	MealTypeOther:     true,
}

// EatingContext represents the context in which a meal was eaten.
type EatingContext string

const (
	EatingContextHomemade   EatingContext = "homemade"
	EatingContextTakeout    EatingContext = "takeout"
	EatingContextOnTheGo    EatingContext = "on-the-go"
	EatingContextMealPrepped EatingContext = "meal-prepped"
	EatingContextSkipped    EatingContext = "skipped"
	EatingContextSocial     EatingContext = "social"
	EatingContextAlone      EatingContext = "alone"
)

// ValidEatingContexts contains all accepted eating context values.
var ValidEatingContexts = map[EatingContext]bool{
	EatingContextHomemade:    true,
	EatingContextTakeout:     true,
	EatingContextOnTheGo:     true,
	EatingContextMealPrepped: true,
	EatingContextSkipped:     true,
	EatingContextSocial:      true,
	EatingContextAlone:       true,
}

// MindfulnessCheck represents the user's mindfulness during a meal.
type MindfulnessCheck string

const (
	MindfulnessYes      MindfulnessCheck = "yes"
	MindfulnessSomewhat MindfulnessCheck = "somewhat"
	MindfulnessNo       MindfulnessCheck = "no"
)

// ValidMindfulnessChecks contains all accepted mindfulness check values.
var ValidMindfulnessChecks = map[MindfulnessCheck]bool{
	MindfulnessYes:      true,
	MindfulnessSomewhat: true,
	MindfulnessNo:       true,
}

// Completeness represents the calendar day completeness indicator.
type Completeness string

const (
	CompletenessGreen  Completeness = "green"
	CompletenessYellow Completeness = "yellow"
	CompletenessGray   Completeness = "gray"
)

// TrendDirection represents the direction of a trend.
type TrendDirection string

const (
	TrendDirectionImproving TrendDirection = "improving"
	TrendDirectionStable    TrendDirection = "stable"
	TrendDirectionDeclining TrendDirection = "declining"
)

// InsightType represents the category of an insight.
type InsightType string

const (
	InsightTypeGapDetection    InsightType = "gap-detection"
	InsightTypeMealConsistency InsightType = "meal-consistency"
	InsightTypeEmotionalEating InsightType = "emotional-eating"
	InsightTypeMindfulness     InsightType = "mindfulness"
	InsightTypeHydration       InsightType = "hydration"
	InsightTypeCrossDomain     InsightType = "cross-domain"
)

// InsightSeverity represents the severity of an insight.
type InsightSeverity string

const (
	InsightSeverityInfo      InsightSeverity = "info"
	InsightSeverityAttention InsightSeverity = "attention"
)

// HydrationAction represents the action type for hydration logging.
type HydrationAction string

const (
	HydrationActionAdd    HydrationAction = "add"
	HydrationActionRemove HydrationAction = "remove"
)

// MealLog represents a meal log entry.
type MealLog struct {
	MealID           string            `json:"mealId"`
	UserID           string            `json:"userId,omitempty"`
	TenantID         string            `json:"tenantId,omitempty"`
	Timestamp        time.Time         `json:"timestamp"`
	MealType         MealType          `json:"mealType"`
	CustomMealLabel  *string           `json:"customMealLabel,omitempty"`
	Description      *string           `json:"description,omitempty"`
	EatingContext    *EatingContext     `json:"eatingContext,omitempty"`
	MoodBefore       *int              `json:"moodBefore,omitempty"`
	MoodAfter        *int              `json:"moodAfter,omitempty"`
	MindfulnessCheck *MindfulnessCheck `json:"mindfulnessCheck,omitempty"`
	Notes            *string           `json:"notes,omitempty"`
	IsQuickLog       bool              `json:"isQuickLog"`
	CreatedAt        time.Time         `json:"createdAt"`
	ModifiedAt       time.Time         `json:"modifiedAt"`
	Links            map[string]string `json:"links,omitempty"`
}

// CreateMealLogRequest represents a request to create a meal log.
type CreateMealLogRequest struct {
	Timestamp       *time.Time        `json:"timestamp,omitempty"`
	MealType        MealType          `json:"mealType"`
	CustomMealLabel *string           `json:"customMealLabel,omitempty"`
	Description     string            `json:"description"`
	EatingContext   *EatingContext     `json:"eatingContext,omitempty"`
	MoodBefore      *int              `json:"moodBefore,omitempty"`
	MoodAfter       *int              `json:"moodAfter,omitempty"`
	MindfulnessCheck *MindfulnessCheck `json:"mindfulnessCheck,omitempty"`
	Notes           *string           `json:"notes,omitempty"`
}

// UpdateMealLogRequest represents a request to update a meal log (JSON Merge Patch).
type UpdateMealLogRequest struct {
	Timestamp        *time.Time        `json:"timestamp,omitempty"`
	Description      *string           `json:"description,omitempty"`
	EatingContext    *EatingContext     `json:"eatingContext,omitempty"`
	MoodBefore       *int              `json:"moodBefore,omitempty"`
	MoodAfter        *int              `json:"moodAfter,omitempty"`
	MindfulnessCheck *MindfulnessCheck `json:"mindfulnessCheck,omitempty"`
	Notes            *string           `json:"notes,omitempty"`
}

// CreateQuickMealLogRequest represents a request to create a quick meal log.
type CreateQuickMealLogRequest struct {
	MealType        MealType `json:"mealType"`
	CustomMealLabel *string  `json:"customMealLabel,omitempty"`
}

// HydrationEntry represents a single hydration log action.
type HydrationEntry struct {
	Timestamp time.Time       `json:"timestamp"`
	Servings  int             `json:"servings"`
	Action    HydrationAction `json:"action"`
}

// HydrationLog represents a daily hydration record.
type HydrationLog struct {
	UserID              string           `json:"userId,omitempty"`
	TenantID            string           `json:"tenantId,omitempty"`
	Date                string           `json:"date"` // YYYY-MM-DD
	ServingsLogged      int              `json:"servingsLogged"`
	ServingSizeOz       float64          `json:"servingSizeOz"`
	TotalOunces         float64          `json:"totalOunces"`
	DailyTargetServings int              `json:"dailyTargetServings"`
	GoalMet             bool             `json:"goalMet"`
	GoalProgressPercent int              `json:"goalProgressPercent"`
	Entries             []HydrationEntry `json:"entries"`
	CreatedAt           time.Time        `json:"createdAt"`
	ModifiedAt          time.Time        `json:"modifiedAt"`
}

// LogHydrationRequest represents a request to log water intake.
type LogHydrationRequest struct {
	Action    HydrationAction `json:"action"`
	Servings  int             `json:"servings"`
	Timestamp *time.Time      `json:"timestamp,omitempty"`
}

// NutritionCalendarDay represents a single day in the nutrition calendar.
type NutritionCalendarDay struct {
	Date             string       `json:"date"`
	MealsLogged      int          `json:"mealsLogged"`
	MealTypes        []MealType   `json:"mealTypes"`
	HydrationGoalMet bool         `json:"hydrationGoalMet"`
	Completeness     Completeness `json:"completeness"`
}

// NutritionCalendarResponse is the response for calendar data.
type NutritionCalendarResponse struct {
	Data struct {
		Year  int                    `json:"year"`
		Month int                    `json:"month"`
		Days  []NutritionCalendarDay `json:"days"`
	} `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}

// MealConsistencyTrend represents meal consistency trend data.
type MealConsistencyTrend struct {
	DailyMealCounts     []DailyMealCount  `json:"dailyMealCounts"`
	AverageMealsPerDay  float64           `json:"averageMealsPerDay"`
	MealTypePercentages map[string]float64 `json:"mealTypePercentages"`
}

// DailyMealCount represents meal counts for a single day.
type DailyMealCount struct {
	Date      string `json:"date"`
	Total     int    `json:"total"`
	Breakfast int    `json:"breakfast"`
	Lunch     int    `json:"lunch"`
	Dinner    int    `json:"dinner"`
	Snack     int    `json:"snack"`
	Other     int    `json:"other"`
}

// EatingContextTrend represents eating context distribution.
type EatingContextTrend struct {
	Distribution     map[string]float64 `json:"distribution"`
	SocialEatingCount int               `json:"socialEatingCount"`
}

// EmotionalEatingTrend represents emotional eating pattern data.
type EmotionalEatingTrend struct {
	AverageMoodBefore       *float64 `json:"averageMoodBefore"`
	AverageMoodAfter        *float64 `json:"averageMoodAfter"`
	MoodImprovementPercent  *float64 `json:"moodImprovementPercent"`
}

// MindfulnessTrend represents mindfulness trend data.
type MindfulnessTrend struct {
	MindfulPercent   float64         `json:"mindfulPercent"`
	SomewhatPercent  float64         `json:"somewhatPercent"`
	DistractedPercent float64        `json:"distractedPercent"`
	TrendDirection   *TrendDirection `json:"trendDirection"`
}

// HydrationTrend represents hydration trend data.
type HydrationTrend struct {
	AverageDailyOunces float64              `json:"averageDailyOunces"`
	DaysGoalMet        int                  `json:"daysGoalMet"`
	TotalDays          int                  `json:"totalDays"`
	DailyIntake        []DailyHydration     `json:"dailyIntake"`
}

// DailyHydration represents hydration data for a single day.
type DailyHydration struct {
	Date        string  `json:"date"`
	TotalOunces float64 `json:"totalOunces"`
	GoalMet     bool    `json:"goalMet"`
}

// Insight represents a generated insight about the user's nutrition patterns.
type Insight struct {
	InsightID string          `json:"insightId"`
	Type      InsightType     `json:"type"`
	Message   string          `json:"message"`
	Severity  InsightSeverity `json:"severity"`
}

// NutritionTrendsData contains all trend data for a period.
type NutritionTrendsData struct {
	Period          string                `json:"period"`
	MealConsistency *MealConsistencyTrend `json:"mealConsistency"`
	EatingContext   *EatingContextTrend   `json:"eatingContext"`
	EmotionalEating *EmotionalEatingTrend `json:"emotionalEating"`
	Mindfulness     *MindfulnessTrend     `json:"mindfulness"`
	Hydration       *HydrationTrend       `json:"hydration"`
	Insights        []Insight             `json:"insights"`
}

// WeekSummary represents summary data for a single week.
type WeekSummary struct {
	MealsLogged         int      `json:"mealsLogged"`
	AverageMealsPerDay  float64  `json:"averageMealsPerDay"`
	HydrationGoalMetDays int     `json:"hydrationGoalMetDays"`
	MostCommonContext   *string  `json:"mostCommonContext"`
	MindfulMealPercent  float64  `json:"mindfulMealPercent"`
}

// WeeklyComparison represents comparison data between two weeks.
type WeeklyComparison struct {
	MealsLoggedDelta int            `json:"mealsLoggedDelta"`
	HydrationDelta   int            `json:"hydrationDelta"`
	Direction        TrendDirection `json:"direction"`
}

// WeeklySummaryData contains the full weekly summary response data.
type WeeklySummaryData struct {
	CurrentWeek  WeekSummary      `json:"currentWeek"`
	PreviousWeek WeekSummary      `json:"previousWeek"`
	Comparison   WeeklyComparison `json:"comparison"`
}

// MealReminderSetting represents a meal reminder configuration.
type MealReminderSetting struct {
	Enabled bool   `json:"enabled"`
	Time    string `json:"time"` // HH:MM
}

// NutritionSettings represents the user's nutrition configuration.
type NutritionSettings struct {
	UserID   string `json:"userId,omitempty"`
	TenantID string `json:"tenantId,omitempty"`
	Hydration struct {
		ServingSizeOz       float64 `json:"servingSizeOz"`
		DailyTargetServings int     `json:"dailyTargetServings"`
	} `json:"hydration"`
	MealReminders struct {
		Breakfast MealReminderSetting `json:"breakfast"`
		Lunch     MealReminderSetting `json:"lunch"`
		Dinner    MealReminderSetting `json:"dinner"`
	} `json:"mealReminders"`
	HydrationReminders struct {
		Enabled       bool `json:"enabled"`
		IntervalHours int  `json:"intervalHours"`
	} `json:"hydrationReminders"`
	MissedMealNudge struct {
		Enabled   bool   `json:"enabled"`
		NudgeTime string `json:"nudgeTime"`
	} `json:"missedMealNudge"`
	InsightPreferences struct {
		MealConsistencyEnabled bool `json:"mealConsistencyEnabled"`
		EmotionalEatingEnabled bool `json:"emotionalEatingEnabled"`
		MindfulnessEnabled     bool `json:"mindfulnessEnabled"`
		CrossDomainEnabled     bool `json:"crossDomainEnabled"`
	} `json:"insightPreferences"`
	CreatedAt  time.Time `json:"createdAt"`
	ModifiedAt time.Time `json:"modifiedAt"`
}

// CalendarActivity represents a calendar dual-write entry.
type CalendarActivity struct {
	UserID       string `json:"userId"`
	Date         string `json:"date"` // YYYY-MM-DD
	ActivityType string `json:"activityType"`
	Summary      struct {
		MealType       MealType `json:"mealType"`
		MealID         string   `json:"mealId"`
		HasDescription bool     `json:"hasDescription"`
	} `json:"summary"`
	SourceKey string `json:"sourceKey"`
}

// ConcerningPattern represents a detected concerning eating pattern.
type ConcerningPattern struct {
	Detected     bool   `json:"detected"`
	ConsecutiveDays int `json:"consecutiveDays"`
	Message      string `json:"message"`
}

// --- Response Envelope Types ---

// MealLogResponse wraps a single MealLog.
type MealLogResponse struct {
	Data MealLog                `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}

// MealLogListResponse wraps a list of MealLog items.
type MealLogListResponse struct {
	Data  []MealLog              `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
}

// HydrationStatusResponse wraps hydration status data.
type HydrationStatusResponse struct {
	Data HydrationLog           `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}

// HydrationHistoryResponse wraps hydration history data.
type HydrationHistoryResponse struct {
	Data []HydrationLog         `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}

// NutritionTrendsResponse wraps trend data.
type NutritionTrendsResponse struct {
	Data NutritionTrendsData    `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}

// WeeklySummaryResponse wraps weekly summary data.
type WeeklySummaryResponse struct {
	Data WeeklySummaryData      `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}

// NutritionSettingsResponse wraps settings data.
type NutritionSettingsResponse struct {
	Data NutritionSettings      `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}

// MealListFilter contains filter parameters for listing meals.
type MealListFilter struct {
	MealType         *string
	EatingContext    *string
	MoodBefore       *string
	MoodAfter        *string
	MindfulnessCheck *string
	StartDate        *string
	EndDate          *string
	Search           *string
	Sort             string
	Cursor           string
	Limit            int
}
