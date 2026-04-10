// api/test/contract/threecircles/types.go
package threecircles

import "time"

// ────────────────────────────────────────────────────────────────────────────
// Enums
// ────────────────────────────────────────────────────────────────────────────

// CircleType represents the three circle types in the Three Circles model.
type CircleType string

const (
	CircleInner  CircleType = "inner"
	CircleMiddle CircleType = "middle"
	CircleOuter  CircleType = "outer"
)

// CircleSetStatus represents the lifecycle status of a circle set.
type CircleSetStatus string

const (
	StatusDraft    CircleSetStatus = "draft"
	StatusActive   CircleSetStatus = "active"
	StatusArchived CircleSetStatus = "archived"
)

// RecoveryArea represents the primary recovery area addressed by a circle set.
type RecoveryArea string

const (
	RecoveryAreaSexPornography   RecoveryArea = "sex-pornography"
	RecoveryAreaAlcohol          RecoveryArea = "alcohol"
	RecoveryAreaDrugs            RecoveryArea = "drugs"
	RecoveryAreaGambling         RecoveryArea = "gambling"
	RecoveryAreaFoodEating       RecoveryArea = "food-eating"
	RecoveryAreaInternetTech     RecoveryArea = "internet-technology"
	RecoveryAreaWork             RecoveryArea = "work"
	RecoveryAreaShoppingDebt     RecoveryArea = "shopping-debt"
	RecoveryAreaLoveRelationship RecoveryArea = "love-relationships"
	RecoveryAreaOther            RecoveryArea = "other"
)

// FrameworkPreference represents recovery fellowship or framework preference.
type FrameworkPreference string

const (
	FrameworkSAA   FrameworkPreference = "SAA"
	FrameworkSLAA  FrameworkPreference = "SLAA"
	FrameworkAA    FrameworkPreference = "AA"
	FrameworkNA    FrameworkPreference = "NA"
	FrameworkSMART FrameworkPreference = "SMART"
	FrameworkOA    FrameworkPreference = "OA"
	FrameworkGA    FrameworkPreference = "GA"
	FrameworkDA    FrameworkPreference = "DA"
	FrameworkCoDA  FrameworkPreference = "CoDA"
	FrameworkITAA  FrameworkPreference = "ITAA"
	FrameworkWA    FrameworkPreference = "WA"
	FrameworkOther FrameworkPreference = "other"
	FrameworkNone  FrameworkPreference = "none"
)

// CircleItemSource represents the origin of a circle item.
type CircleItemSource string

const (
	SourceUser        CircleItemSource = "user"
	SourceTemplate    CircleItemSource = "template"
	SourceStarterPack CircleItemSource = "starterPack"
)

// OnboardingMode represents the onboarding flow mode.
type OnboardingMode string

const (
	ModeGuided      OnboardingMode = "guided"
	ModeStarterPack OnboardingMode = "starterPack"
	ModeExpress     OnboardingMode = "express"
)

// OnboardingStep represents the current step in onboarding flow.
type OnboardingStep string

const (
	StepRecoveryArea OnboardingStep = "recoveryArea"
	StepFramework    OnboardingStep = "framework"
	StepInnerCircle  OnboardingStep = "innerCircle"
	StepOuterCircle  OnboardingStep = "outerCircle"
	StepMiddleCircle OnboardingStep = "middleCircle"
	StepReview       OnboardingStep = "review"
)

// StarterPackVariant represents the variant of a starter pack.
type StarterPackVariant string

const (
	VariantSecular        StarterPackVariant = "secular"
	VariantFaithBased     StarterPackVariant = "faith-based"
	VariantLGBTQAffirming StarterPackVariant = "lgbtq-affirming"
)

// InsightType represents the category of a pattern insight.
type InsightType string

const (
	InsightDayOfWeek  InsightType = "dayOfWeek"
	InsightTime       InsightType = "time"
	InsightTrigger    InsightType = "trigger"
	InsightProtective InsightType = "protective"
	InsightSleep      InsightType = "sleep"
	InsightSEEDS      InsightType = "seeds"
)

// InsightConfidence represents the strength of a pattern correlation.
type InsightConfidence string

const (
	ConfidenceLow    InsightConfidence = "low"
	ConfidenceMedium InsightConfidence = "medium"
	ConfidenceHigh   InsightConfidence = "high"
)

// MoodTrend represents mood trend direction for summaries.
type MoodTrend string

const (
	MoodImproving        MoodTrend = "improving"
	MoodStable           MoodTrend = "stable"
	MoodDeclining        MoodTrend = "declining"
	MoodInsufficientData MoodTrend = "insufficient-data"
)

// ReviewStep represents the current step in quarterly review flow.
type ReviewStep string

const (
	ReviewStepInner  ReviewStep = "innerReview"
	ReviewStepOuter  ReviewStep = "outerReview"
	ReviewStepMiddle ReviewStep = "middleReview"
	ReviewStepFinal  ReviewStep = "finalReview"
)

// CommitOption represents how to commit an onboarding flow.
type CommitOption string

const (
	CommitNow          CommitOption = "commitNow"
	CommitDraft        CommitOption = "draft"
	CommitDraftNoShare CommitOption = "draftNoShare"
)

// MergeStrategy represents how to apply a starter pack.
type MergeStrategy string

const (
	MergeReplace MergeStrategy = "replace"
	MergeMerge   MergeStrategy = "merge"
)

// ────────────────────────────────────────────────────────────────────────────
// Core Domain Types
// ────────────────────────────────────────────────────────────────────────────

// CircleItem represents a single behavior, warning sign, or practice within a circle.
type CircleItem struct {
	ItemID            string           `json:"itemId"`
	Circle            CircleType       `json:"circle"`
	BehaviorName      string           `json:"behaviorName"`
	Notes             *string          `json:"notes"`
	SpecificityDetail *string          `json:"specificityDetail"`
	Category          *string          `json:"category"`
	Source            CircleItemSource `json:"source"`
	Flags             *CircleItemFlags `json:"flags,omitempty"`
	CreatedAt         time.Time        `json:"createdAt"`
	ModifiedAt        time.Time        `json:"modifiedAt"`
}

// CircleItemFlags represents user-defined flags on a circle item.
type CircleItemFlags struct {
	Uncertain bool `json:"uncertain"`
}

// CircleSet represents a complete Three Circles set with all items.
type CircleSet struct {
	SetID               string               `json:"setId"`
	UserID              string               `json:"userId"`
	Name                string               `json:"name"`
	RecoveryArea        RecoveryArea         `json:"recoveryArea"`
	FrameworkPreference *FrameworkPreference `json:"frameworkPreference,omitempty"`
	Status              CircleSetStatus      `json:"status"`
	InnerCircle         []CircleItem         `json:"innerCircle"`
	MiddleCircle        []CircleItem         `json:"middleCircle"`
	OuterCircle         []CircleItem         `json:"outerCircle"`
	VersionNumber       int                  `json:"versionNumber"`
	CreatedAt           time.Time            `json:"createdAt"`
	ModifiedAt          time.Time            `json:"modifiedAt"`
	CommittedAt         *time.Time           `json:"committedAt"`
}

// CircleSetVersion represents a version snapshot of a circle set.
type CircleSetVersion struct {
	VersionNumber int                      `json:"versionNumber"`
	Snapshot      CircleSetVersionSnapshot `json:"snapshot"`
	ChangeNote    *string                  `json:"changeNote"`
	ChangedAt     time.Time                `json:"changedAt"`
}

// CircleSetVersionSnapshot represents the snapshot data for a specific version.
type CircleSetVersionSnapshot struct {
	InnerCircle  []CircleItem `json:"innerCircle"`
	MiddleCircle []CircleItem `json:"middleCircle"`
	OuterCircle  []CircleItem `json:"outerCircle"`
}

// Template represents a single template suggestion for a circle item.
type Template struct {
	TemplateID          string       `json:"templateId"`
	RecoveryArea        RecoveryArea `json:"recoveryArea"`
	Circle              CircleType   `json:"circle"`
	BehaviorName        string       `json:"behaviorName"`
	Rationale           string       `json:"rationale"`
	SpecificityGuidance *string      `json:"specificityGuidance"`
	Category            *string      `json:"category"`
	FrameworkVariant    *string      `json:"frameworkVariant"`
	Version             int          `json:"version"`
}

// StarterPackItem represents a single item in a starter pack.
type StarterPackItem struct {
	BehaviorName string  `json:"behaviorName"`
	Rationale    string  `json:"rationale"`
	Category     *string `json:"category"`
}

// StarterPack represents a pre-built complete circle set.
type StarterPack struct {
	PackID            string             `json:"packId"`
	Name              string             `json:"name"`
	Description       string             `json:"description"`
	RecoveryArea      RecoveryArea       `json:"recoveryArea"`
	Variant           StarterPackVariant `json:"variant"`
	InnerCircle       []StarterPackItem  `json:"innerCircle"`
	MiddleCircle      []StarterPackItem  `json:"middleCircle"`
	OuterCircle       []StarterPackItem  `json:"outerCircle"`
	ClinicalReviewer  string             `json:"clinicalReviewer"`
	CommunityReviewer string             `json:"communityReviewer"`
	Version           int                `json:"version"`
}

// OnboardingFlow represents a guided onboarding session state.
type OnboardingFlow struct {
	FlowID                string                 `json:"flowId"`
	UserID                string                 `json:"userId"`
	Mode                  OnboardingMode         `json:"mode"`
	CurrentStep           OnboardingStep         `json:"currentStep"`
	RecoveryArea          *RecoveryArea          `json:"recoveryArea,omitempty"`
	FrameworkPreference   *FrameworkPreference   `json:"frameworkPreference,omitempty"`
	EmotionalCheckinScore *int                   `json:"emotionalCheckinScore,omitempty"`
	Progress              map[string]interface{} `json:"progress"`
	CreatedAt             time.Time              `json:"createdAt"`
	LastUpdatedAt         time.Time              `json:"lastUpdatedAt"`
}

// SponsorComment represents a comment from a sponsor or therapist on a circle item.
type SponsorComment struct {
	CommentID     string    `json:"commentId"`
	ItemID        string    `json:"itemId"`
	Text          string    `json:"text"`
	CommenterName *string   `json:"commenterName"`
	CreatedAt     time.Time `json:"createdAt"`
}

// TimelineEntry represents a single day entry in the circle timeline.
type TimelineEntry struct {
	Date           string                  `json:"date"`
	Circle         CircleType              `json:"circle"`
	CheckinDetails *TimelineCheckinDetails `json:"checkinDetails"`
}

// TimelineCheckinDetails represents check-in details within a timeline entry.
type TimelineCheckinDetails struct {
	Mood          int    `json:"mood"`
	UrgeIntensity int    `json:"urgeIntensity"`
	Notes         string `json:"notes"`
}

// TimelineSummary represents summary statistics for a timeline period.
type TimelineSummary struct {
	OuterDays                   int `json:"outerDays"`
	MiddleDays                  int `json:"middleDays"`
	InnerDays                   int `json:"innerDays"`
	NoCheckinDays               int `json:"noCheckinDays"`
	CurrentConsecutiveOuterDays int `json:"currentConsecutiveOuterDays"`
}

// PatternInsight represents an auto-generated pattern insight card.
type PatternInsight struct {
	InsightID        string            `json:"insightId"`
	Type             InsightType       `json:"type"`
	Description      string            `json:"description"`
	Confidence       InsightConfidence `json:"confidence"`
	ActionSuggestion string            `json:"actionSuggestion"`
	DataPoints       int               `json:"dataPoints"`
	DetectedAt       time.Time         `json:"detectedAt"`
}

// DriftAlert represents a middle circle drift alert.
type DriftAlert struct {
	AlertID          string    `json:"alertId"`
	WindowStart      string    `json:"windowStart"`
	WindowEnd        string    `json:"windowEnd"`
	MiddleCircleDays int       `json:"middleCircleDays"`
	Message          string    `json:"message"`
	Dismissed        bool      `json:"dismissed"`
	CreatedAt        time.Time `json:"createdAt"`
}

// Summary represents a weekly/monthly circle distribution summary.
type Summary struct {
	Period         string           `json:"period"`
	StartDate      string           `json:"startDate"`
	EndDate        string           `json:"endDate"`
	OuterDays      int              `json:"outerDays"`
	MiddleDays     int              `json:"middleDays"`
	InnerDays      int              `json:"innerDays"`
	NoCheckinDays  int              `json:"noCheckinDays"`
	Insights       []PatternInsight `json:"insights"`
	MoodTrend      *MoodTrend       `json:"moodTrend"`
	FramingMessage string           `json:"framingMessage"`
}

// Review represents a quarterly circle review session.
type Review struct {
	ReviewID       string                 `json:"reviewId"`
	SetID          string                 `json:"setId"`
	CurrentStep    ReviewStep             `json:"currentStep"`
	Reflections    map[string]interface{} `json:"reflections"`
	ChangesApplied []string               `json:"changesApplied"`
	Completed      bool                   `json:"completed"`
	Summary        *string                `json:"summary"`
	StartedAt      time.Time              `json:"startedAt"`
	CompletedAt    *time.Time             `json:"completedAt"`
	NextReviewDue  string                 `json:"nextReviewDue"`
}

// ────────────────────────────────────────────────────────────────────────────
// Request Types
// ────────────────────────────────────────────────────────────────────────────

// CreateCircleItemInput represents input for creating a circle item within a request.
type CreateCircleItemInput struct {
	BehaviorName      string  `json:"behaviorName"`
	Notes             *string `json:"notes,omitempty"`
	SpecificityDetail *string `json:"specificityDetail,omitempty"`
}

// CreateMiddleCircleItemInput represents input for creating a middle circle item.
type CreateMiddleCircleItemInput struct {
	BehaviorName string  `json:"behaviorName"`
	Notes        *string `json:"notes,omitempty"`
	Category     *string `json:"category,omitempty"`
}

// CreateOuterCircleItemInput represents input for creating an outer circle item.
type CreateOuterCircleItemInput struct {
	BehaviorName string  `json:"behaviorName"`
	Notes        *string `json:"notes,omitempty"`
}

// CreateCircleSetRequest represents the request to create a new circle set.
type CreateCircleSetRequest struct {
	Name                string                        `json:"name"`
	RecoveryArea        RecoveryArea                  `json:"recoveryArea"`
	FrameworkPreference *FrameworkPreference          `json:"frameworkPreference,omitempty"`
	Status              *CircleSetStatus              `json:"status,omitempty"`
	InnerCircle         []CreateCircleItemInput       `json:"innerCircle,omitempty"`
	MiddleCircle        []CreateMiddleCircleItemInput `json:"middleCircle,omitempty"`
	OuterCircle         []CreateOuterCircleItemInput  `json:"outerCircle,omitempty"`
}

// ReplaceCircleSetRequest represents the request to replace an entire circle set (PUT).
type ReplaceCircleSetRequest struct {
	Name                *string                  `json:"name,omitempty"`
	FrameworkPreference *FrameworkPreference     `json:"frameworkPreference,omitempty"`
	InnerCircle         []map[string]interface{} `json:"innerCircle"`
	MiddleCircle        []map[string]interface{} `json:"middleCircle"`
	OuterCircle         []map[string]interface{} `json:"outerCircle"`
	ChangeNote          *string                  `json:"changeNote,omitempty"`
}

// UpdateCircleSetRequest represents the request to partially update a circle set (PATCH).
type UpdateCircleSetRequest struct {
	Name                *string              `json:"name,omitempty"`
	FrameworkPreference *FrameworkPreference `json:"frameworkPreference,omitempty"`
	Status              *CircleSetStatus     `json:"status,omitempty"`
}

// CommitCircleSetRequest represents the request to commit a draft circle set.
type CommitCircleSetRequest struct {
	ChangeNote *string `json:"changeNote,omitempty"`
}

// CreateCircleItemRequest represents the request to add a new item to a circle.
type CreateCircleItemRequest struct {
	Circle            CircleType       `json:"circle"`
	BehaviorName      string           `json:"behaviorName"`
	Notes             *string          `json:"notes,omitempty"`
	SpecificityDetail *string          `json:"specificityDetail,omitempty"`
	Category          *string          `json:"category,omitempty"`
	Flags             *CircleItemFlags `json:"flags,omitempty"`
}

// UpdateCircleItemRequest represents the request to update a circle item (PUT).
type UpdateCircleItemRequest struct {
	BehaviorName      *string          `json:"behaviorName,omitempty"`
	Notes             *string          `json:"notes,omitempty"`
	SpecificityDetail *string          `json:"specificityDetail,omitempty"`
	Category          *string          `json:"category,omitempty"`
	Flags             *CircleItemFlags `json:"flags,omitempty"`
}

// MoveCircleItemRequest represents the request to move an item between circles.
type MoveCircleItemRequest struct {
	TargetCircle CircleType `json:"targetCircle"`
	ChangeNote   *string    `json:"changeNote,omitempty"`
}

// RestoreVersionRequest represents the request to restore a previous version.
type RestoreVersionRequest struct {
	ChangeNote *string `json:"changeNote,omitempty"`
}

// ApplyStarterPackRequest represents the request to apply a starter pack to a set.
type ApplyStarterPackRequest struct {
	PackID        string         `json:"packId"`
	MergeStrategy *MergeStrategy `json:"mergeStrategy,omitempty"`
}

// StartOnboardingRequest represents the request to start onboarding flow.
type StartOnboardingRequest struct {
	Mode                  *OnboardingMode `json:"mode,omitempty"`
	EmotionalCheckinScore *int            `json:"emotionalCheckinScore,omitempty"`
}

// UpdateOnboardingRequest represents the request to update onboarding progress (PATCH).
type UpdateOnboardingRequest struct {
	CurrentStep         *OnboardingStep        `json:"currentStep,omitempty"`
	RecoveryArea        *RecoveryArea          `json:"recoveryArea,omitempty"`
	FrameworkPreference *FrameworkPreference   `json:"frameworkPreference,omitempty"`
	Progress            map[string]interface{} `json:"progress,omitempty"`
	Mode                *OnboardingMode        `json:"mode,omitempty"`
}

// CompleteOnboardingRequest represents the request to complete onboarding flow.
type CompleteOnboardingRequest struct {
	CommitOption         CommitOption `json:"commitOption"`
	ChangeNote           *string      `json:"changeNote,omitempty"`
	GenerateSponsorShare *bool        `json:"generateSponsorShare,omitempty"`
}

// ShareCircleSetRequest represents the request to generate a share link.
type ShareCircleSetRequest struct {
	ExpiresIn   *string  `json:"expiresIn,omitempty"`
	Permissions []string `json:"permissions,omitempty"`
}

// AddSponsorCommentRequest represents the request to add a sponsor comment.
type AddSponsorCommentRequest struct {
	ItemID        string  `json:"itemId"`
	Text          string  `json:"text"`
	CommenterName *string `json:"commenterName,omitempty"`
}

// StartReviewRequest represents the request to start a quarterly review.
type StartReviewRequest struct {
	SetID string `json:"setId"`
}

// UpdateReviewRequest represents the request to update review progress (PATCH).
type UpdateReviewRequest struct {
	CurrentStep    *ReviewStep            `json:"currentStep,omitempty"`
	Reflections    map[string]interface{} `json:"reflections,omitempty"`
	ChangesApplied []string               `json:"changesApplied,omitempty"`
}

// CompleteReviewRequest represents the request to complete a quarterly review.
type CompleteReviewRequest struct {
	Summary *string `json:"summary,omitempty"`
}

// ────────────────────────────────────────────────────────────────────────────
// Response Envelopes
// ────────────────────────────────────────────────────────────────────────────

// Links represents common hypermedia links.
type Links struct {
	Self      *string `json:"self,omitempty"`
	Versions  *string `json:"versions,omitempty"`
	Share     *string `json:"share,omitempty"`
	Timeline  *string `json:"timeline,omitempty"`
	Comments  *string `json:"comments,omitempty"`
	Set       *string `json:"set,omitempty"`
	Restore   *string `json:"restore,omitempty"`
	Apply     *string `json:"apply,omitempty"`
	Complete  *string `json:"complete,omitempty"`
	ShareView *string `json:"shareView,omitempty"`
	Item      *string `json:"item,omitempty"`
	Insights  *string `json:"insights,omitempty"`
	Summary   *string `json:"summary,omitempty"`
	CircleSet *string `json:"circleSet,omitempty"`
}

// Meta represents common metadata fields.
type Meta struct {
	TotalCount      *int          `json:"totalCount,omitempty"`
	Cursor          *string       `json:"cursor,omitempty"`
	RecoveryArea    *RecoveryArea `json:"recoveryArea,omitempty"`
	Circle          *CircleType   `json:"circle,omitempty"`
	Period          *string       `json:"period,omitempty"`
	StartDate       *string       `json:"startDate,omitempty"`
	EndDate         *string       `json:"endDate,omitempty"`
	MinimumDataDays *int          `json:"minimumDataDays,omitempty"`
	NextReviewDue   *string       `json:"nextReviewDue,omitempty"`
	ReadOnly        *bool         `json:"readOnly,omitempty"`
}

// PaginationLinks represents pagination hypermedia links.
type PaginationLinks struct {
	Self *string `json:"self,omitempty"`
	Next *string `json:"next,omitempty"`
}

// CircleSetListResponse represents the list of circle sets response.
type CircleSetListResponse struct {
	Data  []CircleSet     `json:"data"`
	Meta  Meta            `json:"meta"`
	Links PaginationLinks `json:"links"`
}

// CircleSetResponse represents a single circle set response.
type CircleSetResponse struct {
	Data  CircleSet `json:"data"`
	Links Links     `json:"links"`
}

// VersionHistorySummary represents a summary version entry.
type VersionHistorySummary struct {
	VersionNumber int       `json:"versionNumber"`
	ChangedAt     time.Time `json:"changedAt"`
	ChangeNote    *string   `json:"changeNote"`
}

// CircleSetDetailData represents extended circle set data with history.
type CircleSetDetailData struct {
	CircleSet
	VersionHistory      []VersionHistorySummary `json:"versionHistory"`
	SponsorCommentCount int                     `json:"sponsorCommentCount"`
}

// CircleSetDetailResponse represents the detailed circle set response.
type CircleSetDetailResponse struct {
	Data  CircleSetDetailData `json:"data"`
	Links Links               `json:"links"`
}

// CircleItemResponse represents a single circle item response.
type CircleItemResponse struct {
	Data  CircleItem `json:"data"`
	Links Links      `json:"links"`
}

// VersionSummary represents a summary entry in version list.
type VersionSummary struct {
	VersionNumber int       `json:"versionNumber"`
	ChangedAt     time.Time `json:"changedAt"`
	ChangeNote    *string   `json:"changeNote"`
	InnerCount    int       `json:"innerCount"`
	MiddleCount   int       `json:"middleCount"`
	OuterCount    int       `json:"outerCount"`
}

// VersionListResponse represents the list of versions response.
type VersionListResponse struct {
	Data  []VersionSummary `json:"data"`
	Meta  Meta             `json:"meta"`
	Links Links            `json:"links"`
}

// CircleSetVersionResponse represents a specific version snapshot response.
type CircleSetVersionResponse struct {
	Data  CircleSetVersion `json:"data"`
	Links Links            `json:"links"`
}

// TemplateListResponse represents the list of templates response.
type TemplateListResponse struct {
	Data  []Template `json:"data"`
	Meta  Meta       `json:"meta"`
	Links Links      `json:"links"`
}

// TemplateResponse represents a single template response.
type TemplateResponse struct {
	Data  Template `json:"data"`
	Links Links    `json:"links"`
}

// StarterPackSummary represents a summary entry in starter pack list.
type StarterPackSummary struct {
	PackID      string             `json:"packId"`
	Name        string             `json:"name"`
	Description string             `json:"description"`
	Variant     StarterPackVariant `json:"variant"`
	ItemCounts  StarterPackCounts  `json:"itemCounts"`
}

// StarterPackCounts represents item counts for a starter pack.
type StarterPackCounts struct {
	Inner  int `json:"inner"`
	Middle int `json:"middle"`
	Outer  int `json:"outer"`
}

// StarterPackListResponse represents the list of starter packs response.
type StarterPackListResponse struct {
	Data  []StarterPackSummary `json:"data"`
	Meta  Meta                 `json:"meta"`
	Links Links                `json:"links"`
}

// StarterPackResponse represents a single starter pack response.
type StarterPackResponse struct {
	Data  StarterPack `json:"data"`
	Links Links       `json:"links"`
}

// OnboardingFlowResponse represents the onboarding flow response.
type OnboardingFlowResponse struct {
	Data  OnboardingFlow `json:"data"`
	Links Links          `json:"links"`
}

// CompleteOnboardingData represents the data returned after completing onboarding.
type CompleteOnboardingData struct {
	CircleSet        CircleSet `json:"circleSet"`
	SponsorShareLink *string   `json:"sponsorShareLink"`
	SponsorShareCode *string   `json:"sponsorShareCode"`
}

// CompleteOnboardingResponse represents the response after completing onboarding.
type CompleteOnboardingResponse struct {
	Data  CompleteOnboardingData `json:"data"`
	Links Links                  `json:"links"`
}

// ShareCircleSetData represents the data returned when creating a share link.
type ShareCircleSetData struct {
	ShareCode   string     `json:"shareCode"`
	ShareLink   string     `json:"shareLink"`
	ExpiresAt   *time.Time `json:"expiresAt"`
	Permissions []string   `json:"permissions"`
}

// ShareCircleSetResponse represents the response when creating a share link.
type ShareCircleSetResponse struct {
	Data  ShareCircleSetData `json:"data"`
	Links Links              `json:"links"`
}

// ViewSharedCircleSetData represents the data for viewing a shared circle set.
type ViewSharedCircleSetData struct {
	Name         string       `json:"name"`
	RecoveryArea RecoveryArea `json:"recoveryArea"`
	InnerCircle  []CircleItem `json:"innerCircle"`
	MiddleCircle []CircleItem `json:"middleCircle"`
	OuterCircle  []CircleItem `json:"outerCircle"`
	SharedAt     time.Time    `json:"sharedAt"`
	ExpiresAt    *time.Time   `json:"expiresAt"`
	CanComment   bool         `json:"canComment"`
}

// ViewSharedCircleSetResponse represents the response when viewing a shared circle set.
type ViewSharedCircleSetResponse struct {
	Data ViewSharedCircleSetData `json:"data"`
	Meta Meta                    `json:"meta"`
}

// SponsorCommentResponse represents a single sponsor comment response.
type SponsorCommentResponse struct {
	Data  SponsorComment `json:"data"`
	Links Links          `json:"links"`
}

// CommentListResponse represents the list of comments response.
type CommentListResponse struct {
	Data  []SponsorComment `json:"data"`
	Meta  Meta             `json:"meta"`
	Links PaginationLinks  `json:"links"`
}

// TimelineData represents timeline entries with summary.
type TimelineData struct {
	Entries []TimelineEntry `json:"entries"`
	Summary TimelineSummary `json:"summary"`
}

// TimelineResponse represents the timeline response.
type TimelineResponse struct {
	Data  TimelineData `json:"data"`
	Meta  Meta         `json:"meta"`
	Links Links        `json:"links"`
}

// InsightListResponse represents the list of insights response.
type InsightListResponse struct {
	Data  []PatternInsight `json:"data"`
	Meta  Meta             `json:"meta"`
	Links Links            `json:"links"`
}

// SummaryResponse represents the pattern summary response.
type SummaryResponse struct {
	Data  Summary `json:"data"`
	Links Links   `json:"links"`
}

// DriftAlertListResponse represents the list of drift alerts response.
type DriftAlertListResponse struct {
	Data  []DriftAlert `json:"data"`
	Links Links        `json:"links"`
}

// ReviewSummary represents a summary entry in review list.
type ReviewSummary struct {
	ReviewID    string     `json:"reviewId"`
	StartedAt   time.Time  `json:"startedAt"`
	CompletedAt *time.Time `json:"completedAt"`
	Completed   bool       `json:"completed"`
}

// ReviewListResponse represents the list of reviews response.
type ReviewListResponse struct {
	Data  []ReviewSummary `json:"data"`
	Meta  Meta            `json:"meta"`
	Links PaginationLinks `json:"links"`
}

// ReviewResponse represents a single review response.
type ReviewResponse struct {
	Data  Review `json:"data"`
	Links Links  `json:"links"`
}

// ────────────────────────────────────────────────────────────────────────────
// Error Response Types
// ────────────────────────────────────────────────────────────────────────────

// ErrorSource represents the source of an error in the request.
type ErrorSource struct {
	Pointer   *string `json:"pointer,omitempty"`
	Parameter *string `json:"parameter,omitempty"`
	Header    *string `json:"header,omitempty"`
}

// ErrorLinks represents links in an error object.
type ErrorLinks struct {
	About *string `json:"about,omitempty"`
	Type  *string `json:"type,omitempty"`
}

// ErrorObject represents a single error in the errors array.
type ErrorObject struct {
	ID            *string      `json:"id,omitempty"`
	Code          string       `json:"code"`
	Status        int          `json:"status"`
	Title         string       `json:"title"`
	Detail        *string      `json:"detail,omitempty"`
	CorrelationID *string      `json:"correlationId,omitempty"`
	Source        *ErrorSource `json:"source,omitempty"`
	Links         *ErrorLinks  `json:"links,omitempty"`
}

// ErrorResponse represents the error response envelope.
type ErrorResponse struct {
	Errors []ErrorObject `json:"errors"`
}

// ────────────────────────────────────────────────────────────────────────────
// Known Error Codes (0x000B = Three Circles domain)
// ────────────────────────────────────────────────────────────────────────────
const (
	ErrCodeFeatureDisabled          = "rr:0x000B0404"
	ErrCodeCircleSetNotFound        = "rr:0x000B0001"
	ErrCodeCircleItemNotFound       = "rr:0x000B0002"
	ErrCodeVersionNotFound          = "rr:0x000B0003"
	ErrCodeTemplateNotFound         = "rr:0x000B0004"
	ErrCodeStarterPackNotFound      = "rr:0x000B0005"
	ErrCodeOnboardingFlowNotFound   = "rr:0x000B0006"
	ErrCodeShareCodeNotFound        = "rr:0x000B0007"
	ErrCodeShareCodeExpired         = "rr:0x000B0008"
	ErrCodeReviewNotFound           = "rr:0x000B0009"
	ErrCodeDriftAlertNotFound       = "rr:0x000B000A"
	ErrCodeCannotCommitEmptyInner   = "rr:0x000B0010"
	ErrCodeCannotDeleteActiveSet    = "rr:0x000B0011"
	ErrCodeInvalidVersionPattern    = "rr:0x000B0012"
	ErrCodeInnerCircleExceedsMax    = "rr:0x000B0013"
	ErrCodeMiddleCircleExceedsMax   = "rr:0x000B0014"
	ErrCodeOuterCircleExceedsMax    = "rr:0x000B0015"
	ErrCodeBehaviorNameTooLong      = "rr:0x000B0016"
	ErrCodeNotesTooLong             = "rr:0x000B0017"
	ErrCodeSpecificityDetailTooLong = "rr:0x000B0018"
	ErrCodeInvalidMergeStrategy     = "rr:0x000B0019"
	ErrCodeUnauthorized             = "rr:0x000B0401"
	ErrCodeValidationFailed         = "rr:0x000B0422"
	ErrCodeInternalError            = "rr:0x000B00FF"
)
