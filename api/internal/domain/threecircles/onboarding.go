// internal/domain/threecircles/onboarding.go
package threecircles

import (
	"errors"
	"time"
)

// Sentinel errors for onboarding.
var (
	ErrInvalidOnboardingMode     = errors.New("invalid onboarding mode")
	ErrInvalidOnboardingStep     = errors.New("invalid onboarding step")
	ErrInvalidCommitOption       = errors.New("invalid commit option")
	ErrOnboardingFlowNotFound    = errors.New("onboarding flow not found")
	ErrFlowAlreadyCompleted      = errors.New("onboarding flow is already completed")
	ErrStepOrderViolation        = errors.New("guided mode requires steps in order")
	ErrInnerCircleRequiredCommit = errors.New("inner circle must have at least 1 item to commit immediately")
	ErrActiveFlowExists          = errors.New("active onboarding flow already exists for this recovery area")
	ErrInvalidEmotionalScore     = errors.New("emotional check-in score must be 0 (skipped) or 1-5")
)

// OnboardingMode represents the onboarding flow mode.
type OnboardingMode string

const (
	ModeGuided      OnboardingMode = "guided"
	ModeStarterPack OnboardingMode = "starterPack"
	ModeExpress     OnboardingMode = "express"
)

// IsValid returns true if the onboarding mode is recognized.
func (om OnboardingMode) IsValid() bool {
	return om == ModeGuided || om == ModeStarterPack || om == ModeExpress
}

// OnboardingStep represents the current step in the onboarding flow.
type OnboardingStep string

const (
	StepRecoveryArea  OnboardingStep = "recoveryArea"
	StepFramework     OnboardingStep = "framework"
	StepInnerCircle   OnboardingStep = "innerCircle"
	StepOuterCircle   OnboardingStep = "outerCircle"
	StepMiddleCircle  OnboardingStep = "middleCircle"
	StepReview        OnboardingStep = "review"
	StepStarterPack   OnboardingStep = "starterPack"
	StepEmotionalStep OnboardingStep = "emotionalCheckin"
)

// IsValid returns true if the onboarding step is recognized.
func (os OnboardingStep) IsValid() bool {
	switch os {
	case StepRecoveryArea, StepFramework, StepInnerCircle, StepOuterCircle, StepMiddleCircle, StepReview, StepStarterPack, StepEmotionalStep:
		return true
	default:
		return false
	}
}

// CommitOption represents the final commit decision in the onboarding flow.
type CommitOption string

const (
	CommitNow               CommitOption = "commitNow"
	CommitDraft             CommitOption = "draft"
	CommitDraftShareSponsor CommitOption = "draftShareSponsor"
	CommitDraftNoShare      CommitOption = "draftNoShare"
)

// IsValid returns true if the commit option is recognized.
func (co CommitOption) IsValid() bool {
	switch co {
	case CommitNow, CommitDraft, CommitDraftShareSponsor, CommitDraftNoShare:
		return true
	default:
		return false
	}
}

// OnboardingFlow represents the state of a user's onboarding flow.
// One active flow per recovery area per user is enforced at the repository layer.
type OnboardingFlow struct {
	FlowID                string               `json:"flowId"`
	UserID                string               `json:"userId"`
	TenantID              string               `json:"tenantId"`
	Mode                  OnboardingMode       `json:"mode"`
	CurrentStep           OnboardingStep       `json:"currentStep"`
	EmotionalCheckinScore int                  `json:"emotionalCheckinScore"` // 1-5, 0 = skipped
	RecoveryArea          *RecoveryArea        `json:"recoveryArea,omitempty"`
	FrameworkPreference   *FrameworkPreference `json:"frameworkPreference,omitempty"`
	DraftSetID            string               `json:"draftSetId"`                     // Associated draft circle set
	AppliedStarterPackID  string               `json:"appliedStarterPackId,omitempty"` // If starter pack was applied
	StartedAt             time.Time            `json:"startedAt"`
	LastActivityAt        time.Time            `json:"lastActivityAt"`
	CompletedAt           *time.Time           `json:"completedAt,omitempty"`
}

// IsCompleted returns true if the onboarding flow is completed.
func (of *OnboardingFlow) IsCompleted() bool {
	return of.CompletedAt != nil
}

// StepSequence defines the required step order for guided mode.
var guidedStepSequence = []OnboardingStep{
	StepRecoveryArea,
	StepFramework,
	StepInnerCircle,
	StepOuterCircle,
	StepMiddleCircle,
	StepReview,
}

// StartOnboardingFlowRequest represents the initial request to start an onboarding flow.
type StartOnboardingFlowRequest struct {
	Mode                  OnboardingMode       `json:"mode"`
	EmotionalCheckinScore int                  `json:"emotionalCheckinScore"` // 0 = skipped, 1-5 = score
	RecoveryArea          *RecoveryArea        `json:"recoveryArea,omitempty"`
	FrameworkPreference   *FrameworkPreference `json:"frameworkPreference,omitempty"`
}

// SuggestModeFromEmotionalScore returns a recommended mode based on emotional check-in score.
func SuggestModeFromEmotionalScore(score int) OnboardingMode {
	switch score {
	case 1:
		// Struggling: suggest starter pack for quick foundation
		return ModeStarterPack
	case 2:
		// Low: suggest guided for structured support
		return ModeGuided
	case 3, 4, 5:
		// Okay/good/strong: allow guided or express
		return ModeGuided
	default:
		// Skipped (0): default to guided
		return ModeGuided
	}
}

// StartOnboardingFlow creates a new onboarding flow.
func StartOnboardingFlow(req StartOnboardingFlowRequest, userID, tenantID string) (*OnboardingFlow, error) {
	if !req.Mode.IsValid() {
		return nil, ErrInvalidOnboardingMode
	}

	// Validate emotional score if provided
	if req.EmotionalCheckinScore < 0 || req.EmotionalCheckinScore > 5 {
		return nil, ErrInvalidEmotionalScore
	}

	// Validate recovery area if provided
	if req.RecoveryArea != nil && !req.RecoveryArea.IsValid() {
		return nil, ErrInvalidRecoveryArea
	}

	// Validate framework if provided
	if req.FrameworkPreference != nil && !req.FrameworkPreference.IsValid() {
		return nil, ErrInvalidFramework
	}

	now := time.Now()
	flow := &OnboardingFlow{
		FlowID:                "", // Will be generated by repository layer
		UserID:                userID,
		TenantID:              tenantID,
		Mode:                  req.Mode,
		CurrentStep:           determineInitialStep(req.Mode, req.RecoveryArea),
		EmotionalCheckinScore: req.EmotionalCheckinScore,
		RecoveryArea:          req.RecoveryArea,
		FrameworkPreference:   req.FrameworkPreference,
		DraftSetID:            "", // Will be created when recovery area is set
		StartedAt:             now,
		LastActivityAt:        now,
		CompletedAt:           nil,
	}

	return flow, nil
}

// determineInitialStep returns the initial step based on mode and whether recovery area is provided.
func determineInitialStep(mode OnboardingMode, area *RecoveryArea) OnboardingStep {
	// If starter pack mode, go to starter pack selection
	if mode == ModeStarterPack {
		if area == nil {
			return StepRecoveryArea
		}
		return StepStarterPack
	}

	// For guided and express, start at recovery area if not provided
	if area == nil {
		return StepRecoveryArea
	}

	// If recovery area is provided, go to framework
	return StepFramework
}

// AdvanceStepRequest represents a request to advance to the next step.
type AdvanceStepRequest struct {
	TargetStep          OnboardingStep       `json:"targetStep"`
	RecoveryArea        *RecoveryArea        `json:"recoveryArea,omitempty"`
	FrameworkPreference *FrameworkPreference `json:"frameworkPreference,omitempty"`
}

// AdvanceStep moves the onboarding flow to the next step.
// For guided mode, enforces step order.
// For express mode, allows flexible step ordering.
func (of *OnboardingFlow) AdvanceStep(req AdvanceStepRequest) error {
	if of.IsCompleted() {
		return ErrFlowAlreadyCompleted
	}

	if !req.TargetStep.IsValid() {
		return ErrInvalidOnboardingStep
	}

	// Validate recovery area if provided
	if req.RecoveryArea != nil {
		if !req.RecoveryArea.IsValid() {
			return ErrInvalidRecoveryArea
		}
		of.RecoveryArea = req.RecoveryArea
	}

	// Validate framework if provided
	if req.FrameworkPreference != nil {
		if !req.FrameworkPreference.IsValid() {
			return ErrInvalidFramework
		}
		of.FrameworkPreference = req.FrameworkPreference
	}

	// For guided mode, enforce step order
	if of.Mode == ModeGuided {
		if err := validateStepOrder(of.CurrentStep, req.TargetStep); err != nil {
			return err
		}
	}

	// Update the flow
	of.CurrentStep = req.TargetStep
	of.LastActivityAt = time.Now()

	return nil
}

// validateStepOrder ensures guided mode follows the required sequence.
func validateStepOrder(currentStep, targetStep OnboardingStep) error {
	currentIdx := -1
	targetIdx := -1

	for i, step := range guidedStepSequence {
		if step == currentStep {
			currentIdx = i
		}
		if step == targetStep {
			targetIdx = i
		}
	}

	// If we can't find the steps in the sequence, allow it (e.g., starter pack step)
	if currentIdx == -1 || targetIdx == -1 {
		return nil
	}

	// Target must be the next step or review (can always go back to review)
	if targetIdx == currentIdx+1 || targetStep == StepReview {
		return nil
	}

	return ErrStepOrderViolation
}

// SwitchModeRequest represents a request to switch onboarding modes mid-flow.
type SwitchModeRequest struct {
	NewMode         OnboardingMode  `json:"newMode"`
	StarterPackID   string          `json:"starterPackId,omitempty"`   // Required if switching to starterPack
	ApplicationMode ApplicationMode `json:"applicationMode,omitempty"` // merge or replace (default: merge)
}

// SwitchMode changes the onboarding mode while preserving all progress.
// When switching to starterPack mode, applies the pack using the specified application mode.
func (of *OnboardingFlow) SwitchMode(req SwitchModeRequest) error {
	if of.IsCompleted() {
		return ErrFlowAlreadyCompleted
	}

	if !req.NewMode.IsValid() {
		return ErrInvalidOnboardingMode
	}

	// If switching to starter pack mode, validate starter pack ID
	if req.NewMode == ModeStarterPack && req.StarterPackID == "" {
		return ErrStarterPackNotFound
	}

	// Default to merge mode if not specified
	if req.ApplicationMode == "" {
		req.ApplicationMode = ApplicationModeMerge
	}

	if !req.ApplicationMode.IsValid() {
		return ErrInvalidApplicationMode
	}

	// Update mode
	of.Mode = req.NewMode

	// If switching to starter pack, update step and record pack ID
	if req.NewMode == ModeStarterPack {
		of.CurrentStep = StepReview // After applying pack, go to review
		of.AppliedStarterPackID = req.StarterPackID
	}

	of.LastActivityAt = time.Now()

	return nil
}

// CompleteOnboardingRequest represents the final commit decision.
type CompleteOnboardingRequest struct {
	CommitOption CommitOption `json:"commitOption"`
	InnerCount   int          `json:"innerCount"`  // For validation
	MiddleCount  int          `json:"middleCount"` // For metadata
	OuterCount   int          `json:"outerCount"`  // For metadata
}

// CompleteOnboarding marks the flow as complete and determines the final circle set status.
func (of *OnboardingFlow) CompleteOnboarding(req CompleteOnboardingRequest) (CircleSetStatus, error) {
	if of.IsCompleted() {
		return "", ErrFlowAlreadyCompleted
	}

	if !req.CommitOption.IsValid() {
		return "", ErrInvalidCommitOption
	}

	// Validate inner circle requirement for immediate commit
	if req.CommitOption == CommitNow && req.InnerCount < 1 {
		return "", ErrInnerCircleRequiredCommit
	}

	now := time.Now()
	of.CompletedAt = &now
	of.LastActivityAt = now

	// Determine circle set status based on commit option
	var status CircleSetStatus
	if req.CommitOption == CommitNow {
		status = StatusActive
	} else {
		// All draft variants result in draft status
		status = StatusDraft
	}

	return status, nil
}

// GetProgressMetadata returns metadata about the onboarding progress.
func (of *OnboardingFlow) GetProgressMetadata() map[string]interface{} {
	stepsCompleted := 0
	totalSteps := 6 // recoveryArea, framework, inner, middle, outer, review

	// Count completed steps based on current progress
	if of.RecoveryArea != nil {
		stepsCompleted++
	}
	if of.FrameworkPreference != nil {
		stepsCompleted++
	}

	// Add additional steps based on current step
	switch of.CurrentStep {
	case StepInnerCircle:
		stepsCompleted += 1 // Framework is done
	case StepOuterCircle:
		stepsCompleted += 2 // Framework and inner are done
	case StepMiddleCircle:
		stepsCompleted += 3 // Framework, inner, outer are done
	case StepReview:
		stepsCompleted = totalSteps // All done
	}

	// Cap at total steps
	if stepsCompleted > totalSteps {
		stepsCompleted = totalSteps
	}

	metadata := map[string]interface{}{
		"flowId":                of.FlowID,
		"mode":                  string(of.Mode),
		"currentStep":           string(of.CurrentStep),
		"emotionalCheckinScore": of.EmotionalCheckinScore,
		"stepsCompleted":        stepsCompleted,
		"totalSteps":            totalSteps,
		"isCompleted":           of.IsCompleted(),
		"startedAt":             of.StartedAt.Format(time.RFC3339),
		"lastActivityAt":        of.LastActivityAt.Format(time.RFC3339),
	}

	if of.RecoveryArea != nil {
		metadata["recoveryArea"] = string(*of.RecoveryArea)
	}

	if of.FrameworkPreference != nil {
		metadata["frameworkPreference"] = string(*of.FrameworkPreference)
	}

	if of.DraftSetID != "" {
		metadata["draftSetId"] = of.DraftSetID
	}

	if of.AppliedStarterPackID != "" {
		metadata["appliedStarterPackId"] = of.AppliedStarterPackID
	}

	if of.CompletedAt != nil {
		metadata["completedAt"] = of.CompletedAt.Format(time.RFC3339)
	}

	return metadata
}

// OnboardingFlowResponse wraps a single OnboardingFlow.
type OnboardingFlowResponse struct {
	Data  OnboardingFlow         `json:"data"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
	Links map[string]string      `json:"links,omitempty"`
}
