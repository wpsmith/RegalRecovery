// internal/domain/postmortem/types.go
package postmortem

import "time"

// Status constants for post-mortem lifecycle.
const (
	StatusDraft    = "draft"
	StatusComplete = "complete"
)

// EventType constants for the type of event being analyzed.
const (
	EventTypeRelapse  = "relapse"
	EventTypeNearMiss = "near-miss"
	EventTypeCombined = "combined"
)

// TriggerCategory constants matching Urge Logging categories.
const (
	TriggerCategoryEmotional     = "emotional"
	TriggerCategoryEnvironmental = "environmental"
	TriggerCategoryRelational    = "relational"
	TriggerCategoryPhysical      = "physical"
	TriggerCategoryDigital       = "digital"
	TriggerCategorySpiritual     = "spiritual"
)

// FASTERStage constants for the FASTER Scale stages.
const (
	FASTERStageRestoration        = "restoration"
	FASTERStageForgettingPriority = "forgetting-priorities"
	FASTERStageAnxiety            = "anxiety"
	FASTERStageSpeedingUp         = "speeding-up"
	FASTERStageTickedOff          = "ticked-off"
	FASTERStageExhausted          = "exhausted"
	FASTERStageRelapse            = "relapse"
)

// ActionCategory constants for action plan items.
const (
	ActionCategorySpiritual  = "spiritual"
	ActionCategoryRelational = "relational"
	ActionCategoryEmotional  = "emotional"
	ActionCategoryPhysical   = "physical"
	ActionCategoryPractical  = "practical"
)

// ShareType constants for sharing visibility.
const (
	ShareTypeFull    = "full"
	ShareTypeSummary = "summary"
)

// TimePeriod constants for time block periods.
const (
	TimePeriodMorning   = "morning"
	TimePeriodMidday    = "midday"
	TimePeriodAfternoon = "afternoon"
	TimePeriodEvening   = "evening"
)

// Section name constants for the six walkthrough sections.
const (
	SectionDayBefore        = "dayBefore"
	SectionMorning          = "morning"
	SectionThroughoutTheDay = "throughoutTheDay"
	SectionBuildUp          = "buildUp"
	SectionActingOut        = "actingOut"
	SectionImmediatelyAfter = "immediatelyAfter"
)

// AllSections lists all six required sections.
var AllSections = []string{
	SectionDayBefore,
	SectionMorning,
	SectionThroughoutTheDay,
	SectionBuildUp,
	SectionActingOut,
	SectionImmediatelyAfter,
}

// ValidTriggerCategories is the set of allowed trigger categories.
var ValidTriggerCategories = map[string]bool{
	TriggerCategoryEmotional:     true,
	TriggerCategoryEnvironmental: true,
	TriggerCategoryRelational:    true,
	TriggerCategoryPhysical:      true,
	TriggerCategoryDigital:       true,
	TriggerCategorySpiritual:     true,
}

// ValidFASTERStages is the set of allowed FASTER Scale stages.
var ValidFASTERStages = map[string]bool{
	FASTERStageRestoration:        true,
	FASTERStageForgettingPriority: true,
	FASTERStageAnxiety:            true,
	FASTERStageSpeedingUp:         true,
	FASTERStageTickedOff:          true,
	FASTERStageExhausted:          true,
	FASTERStageRelapse:            true,
}

// ValidActionCategories is the set of allowed action plan categories.
var ValidActionCategories = map[string]bool{
	ActionCategorySpiritual:  true,
	ActionCategoryRelational: true,
	ActionCategoryEmotional:  true,
	ActionCategoryPhysical:   true,
	ActionCategoryPractical:  true,
}

// ValidEventTypes is the set of allowed event types.
var ValidEventTypes = map[string]bool{
	EventTypeRelapse:  true,
	EventTypeNearMiss: true,
	EventTypeCombined: true,
}

// ValidShareTypes is the set of allowed share types.
var ValidShareTypes = map[string]bool{
	ShareTypeFull:    true,
	ShareTypeSummary: true,
}

// ValidTimePeriods is the set of allowed time block periods.
var ValidTimePeriods = map[string]bool{
	TimePeriodMorning:   true,
	TimePeriodMidday:    true,
	TimePeriodAfternoon: true,
	TimePeriodEvening:   true,
}

// Compassionate messages per PM-AC9.
const (
	OpeningMessage = "A relapse is painful, but it is also an opportunity to learn. This process will help you understand what happened so you can build a stronger foundation going forward."
	ClosingMessage = "Thank you for your honesty and courage. Every insight you have gained here is a step toward lasting freedom."
)

// MaxTextLength is the maximum character length for free-text fields.
const MaxTextLength = 5000

// MaxShortTextLength is the maximum length for shorter text fields.
const MaxShortTextLength = 2000

// MaxActionItems is the maximum number of action items.
const MaxActionItems = 10

// MinActionItems is the minimum number of action items for completion.
const MinActionItems = 1

// MinMoodRating is the minimum mood rating value.
const MinMoodRating = 1

// MaxMoodRating is the maximum mood rating value.
const MaxMoodRating = 10

// PostMortemAnalysis is the core domain model for a post-mortem analysis.
type PostMortemAnalysis struct {
	AnalysisID  string
	UserID      string
	TenantID    string
	Status      string
	EventType   string
	RelapseID   *string
	AddictionID *string
	Timestamp   time.Time

	Sections       Sections
	TriggerSummary []string
	TriggerDetails []TriggerDetail
	FasterMapping  []FasterMappingEntry
	ActionPlan     []ActionPlanItem
	Sharing        SharingStatus
	LinkedEntities LinkedEntities

	CreatedAt   time.Time
	ModifiedAt  time.Time
	CompletedAt *time.Time
}

// Sections holds the six walkthrough sections.
type Sections struct {
	DayBefore        *DayBeforeSection
	Morning          *MorningSection
	ThroughoutTheDay *ThroughoutTheDaySection
	BuildUp          *BuildUpSection
	ActingOut        *ActingOutSection
	ImmediatelyAfter *ImmediatelyAfterSection
}

// DayBeforeSection captures the emotional/spiritual state of the day before.
type DayBeforeSection struct {
	Text                  string
	MoodRating            *int
	RecoveryPracticesKept *bool
	UnresolvedConflicts   string
}

// MorningSection captures how the day started.
type MorningSection struct {
	Text                       string
	MoodRating                 *int
	MorningCommitmentCompleted *bool
	AffirmationViewed          *bool
	AutoPopulated              *AutoPopulatedData
}

// AutoPopulatedData holds auto-populated data from recovery records.
type AutoPopulatedData struct {
	MorningCommitmentCompleted *bool
	MoodRating                 *int
	AffirmationViewed          *bool
}

// ThroughoutTheDaySection captures events throughout the day.
type ThroughoutTheDaySection struct {
	TimeBlocks      []TimeBlock
	FreeFormEntries []FreeFormEntry
}

// TimeBlock is a guided time-block entry.
type TimeBlock struct {
	Period       string
	StartTime    string
	EndTime      string
	Activity     string
	Location     string
	Company      string
	Thoughts     string
	Feelings     string
	WarningSigns []string
}

// FreeFormEntry is a free-form hour-by-hour entry.
type FreeFormEntry struct {
	Time string
	Text string
}

// BuildUpSection captures the build-up to the event.
type BuildUpSection struct {
	FirstNoticed            string
	Triggers                []TriggerDetail
	ResponseToWarnings      string
	MissedHelpOpportunities []MissedHelpOpportunity
	DecisionPoints          []DecisionPoint
}

// MissedHelpOpportunity captures a moment where help was considered but not sought.
type MissedHelpOpportunity struct {
	Description string
	Reason      string
}

// DecisionPoint captures a specific decision moment.
type DecisionPoint struct {
	TimeOfDay    string
	Description  string
	CouldHaveDone string
	InsteadDid   string
}

// ActingOutSection captures what happened during the event.
type ActingOutSection struct {
	Description     string
	AddictionID     string
	DurationMinutes *int
	LinkedRelapseID *string
}

// ImmediatelyAfterSection captures the immediate aftermath.
type ImmediatelyAfterSection struct {
	Feelings               []string
	FeelingsWheelSelections []string
	WhatDidNext            string
	ReachedOut             *bool
	ReachedOutTo           *string
	WishDoneDifferently    string
}

// TriggerDetail represents a trigger with optional deep exploration.
type TriggerDetail struct {
	Category   string
	Surface    string
	Underlying *string
	CoreWound  *string
}

// FasterMappingEntry assigns a FASTER stage to a timeline point.
type FasterMappingEntry struct {
	TimeOfDay string
	Stage     string
}

// ActionPlanItem is a structured action item in the action plan.
type ActionPlanItem struct {
	ActionID                string
	TimelinePoint           string
	Action                  string
	Category                string
	ConvertedToCommitmentID *string
	ConvertedToGoalID       *string
}

// SharingStatus tracks sharing configuration for a post-mortem.
type SharingStatus struct {
	IsShared   bool
	SharedWith []SharedWithEntry
}

// SharedWithEntry tracks a single sharing relationship.
type SharedWithEntry struct {
	ContactID string
	ShareType string
	SharedAt  time.Time
}

// LinkedEntities holds references to related recovery data.
type LinkedEntities struct {
	RelapseID      *string
	UrgeLogIDs     []string
	FasterEntryIDs []string
	CheckInIDs     []string
}

// ListFilter holds filter criteria for listing post-mortems.
type ListFilter struct {
	StartDate   *time.Time
	EndDate     *time.Time
	AddictionID *string
	Status      *string
	EventType   *string
	Cursor      string
	Limit       int
}

// PaginatedResult holds paginated results from a list query.
type PaginatedResult struct {
	Analyses   []*PostMortemAnalysis
	NextCursor string
	TotalComplete int
	TotalDrafts   int
}

// InsightsFilter holds filter criteria for insights queries.
type InsightsFilter struct {
	AddictionID *string
}

// PostMortemInsights holds cross-analysis pattern data.
type PostMortemInsights struct {
	TotalAnalyses          int
	CommonTriggers         []TriggerFrequency
	CommonFasterStageAtBreak *StageFrequency
	CommonTimeOfDay        *TimeOfDayFrequency
	RecurringDecisionPoints []DecisionPointTheme
	DeepTriggerPatterns    []TriggerDetail
}

// TriggerFrequency tracks how often a trigger category appears.
type TriggerFrequency struct {
	Category   string
	Frequency  int
	Percentage float64
}

// StageFrequency tracks the most frequent FASTER stage at break point.
type StageFrequency struct {
	Stage      string
	Frequency  int
	Percentage float64
}

// TimeOfDayFrequency tracks the most common time of day for events.
type TimeOfDayFrequency struct {
	Period     string
	Frequency  int
	Percentage float64
}

// DecisionPointTheme tracks recurring decision point themes.
type DecisionPointTheme struct {
	Theme     string
	Frequency int
}

// ConvertActionItemRequest is the request to convert an action item.
type ConvertActionItemRequest struct {
	TargetType string
	Title      string
	Frequency  *string
	TargetDate *string
}

// CalendarActivityEntry represents the dual-write to calendarActivities.
type CalendarActivityEntry struct {
	UserID       string
	Date         string
	ActivityType string
	Timestamp    time.Time
	Summary      CalendarActivitySummary
	SourceKey    string
}

// CalendarActivitySummary holds summary data for the calendar activity.
type CalendarActivitySummary struct {
	AnalysisID      string
	EventType       string
	Status          string
	TriggerCount    int
	ActionItemCount int
}
