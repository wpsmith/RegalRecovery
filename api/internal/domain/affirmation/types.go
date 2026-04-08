// internal/domain/affirmation/types.go
package affirmation

import "time"

// AffirmationCategory represents the category of an affirmation.
type AffirmationCategory string

const (
	CategoryIdentity         AffirmationCategory = "identity"
	CategoryStrength         AffirmationCategory = "strength"
	CategoryRecovery         AffirmationCategory = "recovery"
	CategoryPurity           AffirmationCategory = "purity"
	CategoryFreedom          AffirmationCategory = "freedom"
	CategorySurrender        AffirmationCategory = "surrender"
	CategoryCourage          AffirmationCategory = "courage"
	CategoryHope             AffirmationCategory = "hope"
	CategoryFamily           AffirmationCategory = "family"
	CategoryHealthySexuality AffirmationCategory = "healthySexuality"
)

// ValidCategories returns all valid affirmation categories.
func ValidCategories() []AffirmationCategory {
	return []AffirmationCategory{
		CategoryIdentity, CategoryStrength, CategoryRecovery, CategoryPurity,
		CategoryFreedom, CategorySurrender, CategoryCourage, CategoryHope,
		CategoryFamily, CategoryHealthySexuality,
	}
}

// CustomAllowedCategories returns categories allowed for custom affirmations.
// healthySexuality is excluded from custom creation.
func CustomAllowedCategories() []AffirmationCategory {
	return []AffirmationCategory{
		CategoryIdentity, CategoryStrength, CategoryRecovery, CategoryPurity,
		CategoryFreedom, CategorySurrender, CategoryCourage, CategoryHope,
		CategoryFamily,
	}
}

// IsValidCategory returns true if the category is a valid AffirmationCategory.
func IsValidCategory(c string) bool {
	for _, valid := range ValidCategories() {
		if string(valid) == c {
			return true
		}
	}
	return false
}

// IsCustomAllowedCategory returns true if the category is allowed for custom affirmations.
func IsCustomAllowedCategory(c string) bool {
	for _, valid := range CustomAllowedCategories() {
		if string(valid) == c {
			return true
		}
	}
	return false
}

// SelectionMode represents how the daily affirmation is selected.
type SelectionMode string

const (
	ModeIndividuallyChosen SelectionMode = "individuallyChosen"
	ModeRandomAutomatic    SelectionMode = "randomAutomatic"
	ModePermanentPackage   SelectionMode = "permanentPackage"
	ModeDayOfWeekPackage   SelectionMode = "dayOfWeekPackage"
)

// Schedule represents the delivery schedule for custom affirmations.
type Schedule string

const (
	ScheduleDaily    Schedule = "daily"
	ScheduleWeekdays Schedule = "weekdays"
	ScheduleWeekends Schedule = "weekends"
	ScheduleCustom   Schedule = "custom"
)

// ReadSource indicates how/why an affirmation was read.
type ReadSource string

const (
	SourceDaily          ReadSource = "daily"
	SourceTriggerOverride ReadSource = "triggerOverride"
	SourceManualChoice   ReadSource = "manualChoice"
	SourcePackageCycle   ReadSource = "packageCycle"
	SourceDayOfWeek      ReadSource = "dayOfWeek"
)

// TriggerCategory represents urge trigger categories for contextual delivery.
type TriggerCategory string

const (
	TriggerEmotional    TriggerCategory = "emotional"
	TriggerEnvironmental TriggerCategory = "environmental"
	TriggerRelational   TriggerCategory = "relational"
	TriggerPhysical     TriggerCategory = "physical"
	TriggerDigital      TriggerCategory = "digital"
	TriggerSpiritual    TriggerCategory = "spiritual"
)

// Affirmation represents a single affirmation in the system.
type Affirmation struct {
	AffirmationID    string              `json:"affirmationId"`
	Statement        string              `json:"statement"`
	ScriptureRef     string              `json:"scriptureReference"`
	ScriptureText    *string             `json:"scriptureText,omitempty"`
	Expansion        *string             `json:"expansion,omitempty"`
	Prayer           *string             `json:"prayer,omitempty"`
	Category         AffirmationCategory `json:"category"`
	Level            int                 `json:"level"`
	PackID           string              `json:"packId,omitempty"`
	PackName         string              `json:"packName,omitempty"`
	IsFavorite       bool                `json:"isFavorite"`
	IsCustom         bool                `json:"isCustom"`
	Language         string              `json:"language"`
	Tags             []string            `json:"tags,omitempty"`
	SortOrder        int                 `json:"sortOrder"`
	CreatedAt        time.Time           `json:"-"`
	ModifiedAt       time.Time           `json:"-"`
}

// AffirmationPack represents a collection of affirmations.
type AffirmationPack struct {
	PackID           string              `json:"packId"`
	Name             string              `json:"name"`
	Description      string              `json:"description"`
	Tier             string              `json:"tier"` // "free" or "premium"
	Price            *float64            `json:"price,omitempty"`
	AffirmationCount int                 `json:"affirmationCount"`
	Categories       []string            `json:"categories"`
	IsOwned          bool                `json:"isOwned"`
	Language         string              `json:"language"`
	Version          int                 `json:"version"`
	CreatedAt        time.Time           `json:"-"`
	ModifiedAt       time.Time           `json:"-"`
}

// CustomAffirmation extends Affirmation with user-specific scheduling.
type CustomAffirmation struct {
	Affirmation
	Schedule           Schedule `json:"schedule"`
	CustomScheduleDays []string `json:"customScheduleDays,omitempty"`
	IsActive           bool     `json:"isActive"`
}

// RotationState tracks the user's affirmation selection configuration.
type RotationState struct {
	SelectionMode        SelectionMode      `json:"selectionMode"`
	ActivePackID         *string            `json:"activePackId,omitempty"`
	DayOfWeekAssignments map[string]string  `json:"dayOfWeekAssignments,omitempty"`
	ChosenAffirmationID  *string            `json:"chosenAffirmationId,omitempty"`
	RotationCycleShown   []string           `json:"-"`
	LastDeliveredID      *string            `json:"lastDeliveredId,omitempty"`
	LastDeliveredDate    *string            `json:"lastDeliveredDate,omitempty"`
	HealthySexualityOptIn bool             `json:"healthySexualityOptIn"`
	HealthySexualityOptInDate *time.Time   `json:"-"`
	ModifiedAt           time.Time          `json:"-"`
}

// AffirmationRead records a single read event.
type AffirmationRead struct {
	AffirmationID string     `json:"affirmationId"`
	Statement     string     `json:"statement,omitempty"` // truncated preview
	Category      string     `json:"category,omitempty"`
	CalendarDate  string     `json:"calendarDate"`
	Source        ReadSource `json:"source"`
	CreatedAt     time.Time  `json:"createdAt"`
}

// AffirmationProgress tracks cumulative progress (no streak metrics).
type AffirmationProgress struct {
	TotalRead          int            `json:"totalRead"`
	TotalFavorites     int            `json:"totalFavorites"`
	TotalCustomCreated int            `json:"totalCustomCreated"`
	CategoryBreakdown  map[string]int `json:"categoryBreakdown"`
	LevelBreakdown     map[string]int `json:"levelBreakdown"`
}

// SelectionContext provides all data needed for affirmation selection.
type SelectionContext struct {
	UserID           string
	Date             time.Time
	CumulativeDays   int
	SobrietyResetAt  *time.Time
	SOSMode          bool
	OwnedPackIDs     []string
	Favorites        []string
	RecentTriggers   []string
	RotationState    *RotationState
	CustomScheduled  []CustomAffirmation
}

// WeightedAffirmation holds an affirmation with its selection weight.
type WeightedAffirmation struct {
	Affirmation Affirmation
	Weight      float64
}

// --- Request types ---

// CreateCustomAffirmationRequest is the request body for creating a custom affirmation.
type CreateCustomAffirmationRequest struct {
	Statement          string   `json:"statement"`
	ScriptureReference *string  `json:"scriptureReference,omitempty"`
	Category           string   `json:"category"`
	Schedule           string   `json:"schedule"`
	CustomScheduleDays []string `json:"customScheduleDays,omitempty"`
}

// UpdateCustomAffirmationRequest is the request body for updating a custom affirmation.
type UpdateCustomAffirmationRequest struct {
	Statement          *string  `json:"statement,omitempty"`
	ScriptureReference *string  `json:"scriptureReference,omitempty"`
	Category           *string  `json:"category,omitempty"`
	Schedule           *string  `json:"schedule,omitempty"`
	CustomScheduleDays []string `json:"customScheduleDays,omitempty"`
	IsActive           *bool    `json:"isActive,omitempty"`
}

// UpdateRotationStateRequest is the request body for updating rotation settings.
type UpdateRotationStateRequest struct {
	SelectionMode        string            `json:"selectionMode"`
	ActivePackID         *string           `json:"activePackId,omitempty"`
	DayOfWeekAssignments map[string]string `json:"dayOfWeekAssignments,omitempty"`
	ChosenAffirmationID  *string           `json:"chosenAffirmationId,omitempty"`
}

// ShareAffirmationRequest is the request body for generating shareable content.
type ShareAffirmationRequest struct {
	Format string `json:"format"` // "text" or "styledGraphic"
}

// --- Response envelope types ---

// AffirmationResponse is the response envelope for a single affirmation.
type AffirmationResponse struct {
	Data  Affirmation            `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
}

// AffirmationsListResponse is the response envelope for multiple affirmations.
type AffirmationsListResponse struct {
	Data  []Affirmation          `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta"`
}

// CustomAffirmationResponse is the response envelope for a custom affirmation.
type CustomAffirmationResponse struct {
	Data  CustomAffirmation      `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
}

// CustomAffirmationsListResponse is the response envelope for multiple custom affirmations.
type CustomAffirmationsListResponse struct {
	Data  []CustomAffirmation    `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
}

// RotationStateResponse is the response envelope for rotation state.
type RotationStateResponse struct {
	Data  RotationState          `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
}

// AffirmationProgressResponse is the response envelope for progress data.
type AffirmationProgressResponse struct {
	Data  AffirmationProgress    `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
}

// AffirmationWidgetData holds the dashboard widget data.
type AffirmationWidgetData struct {
	TodayStatement    string `json:"todayStatement"`
	TodayAffirmationID string `json:"todayAffirmationId"`
	TodayCategory     string `json:"todayCategory"`
	TotalRead         int    `json:"totalRead"`
	TotalFavorites    int    `json:"totalFavorites"`
	HasReadToday      bool   `json:"hasReadToday"`
}

// AffirmationWidgetResponse is the response envelope for widget data.
type AffirmationWidgetResponse struct {
	Data  AffirmationWidgetData  `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
}

// ShareableContent holds generated content for sharing.
type ShareableContent struct {
	Text       string  `json:"text,omitempty"`
	GraphicURL *string `json:"graphicUrl,omitempty"`
}

// ShareAffirmationResponse is the response envelope for shareable content.
type ShareAffirmationResponse struct {
	Data  ShareableContent       `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
}

// PacksListResponse is the response envelope for affirmation packs.
type PacksListResponse struct {
	Data  []AffirmationPack      `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
}

// ErrorDetail represents a single error in the errors array.
type ErrorDetail struct {
	Code   string `json:"code"`   // rr:0x000Axxxx format
	Status int    `json:"status"`
	Title  string `json:"title"`
	Detail string `json:"detail"`
}

// ErrorResponse is the error response envelope.
type ErrorResponse struct {
	Errors []ErrorDetail `json:"errors"`
}
