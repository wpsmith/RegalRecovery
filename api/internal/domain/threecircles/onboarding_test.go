// internal/domain/threecircles/onboarding_test.go
package threecircles

import (
	"testing"
	"time"
)

// ── Test StartOnboardingFlow ──

func TestStartOnboardingFlow_ValidRequest(t *testing.T) {
	t.Parallel()

	recoveryArea := RecoveryAreaSexPornography
	framework := FrameworkSAA

	tests := []struct {
		name              string
		req               StartOnboardingFlowRequest
		expectedMode      OnboardingMode
		expectedStep      OnboardingStep
		expectedArea      *RecoveryArea
		expectedFramework *FrameworkPreference
	}{
		{
			name: "guided mode with recovery area and framework",
			req: StartOnboardingFlowRequest{
				Mode:                  ModeGuided,
				EmotionalCheckinScore: 3,
				RecoveryArea:          &recoveryArea,
				FrameworkPreference:   &framework,
			},
			expectedMode:      ModeGuided,
			expectedStep:      StepFramework,
			expectedArea:      &recoveryArea,
			expectedFramework: &framework,
		},
		{
			name: "express mode without recovery area",
			req: StartOnboardingFlowRequest{
				Mode:                  ModeExpress,
				EmotionalCheckinScore: 4,
			},
			expectedMode: ModeExpress,
			expectedStep: StepRecoveryArea,
		},
		{
			name: "starter pack mode with recovery area",
			req: StartOnboardingFlowRequest{
				Mode:                  ModeStarterPack,
				EmotionalCheckinScore: 1,
				RecoveryArea:          &recoveryArea,
			},
			expectedMode: ModeStarterPack,
			expectedStep: StepStarterPack,
			expectedArea: &recoveryArea,
		},
		{
			name: "starter pack mode without recovery area",
			req: StartOnboardingFlowRequest{
				Mode:                  ModeStarterPack,
				EmotionalCheckinScore: 1,
			},
			expectedMode: ModeStarterPack,
			expectedStep: StepRecoveryArea,
		},
		{
			name: "skipped emotional check-in",
			req: StartOnboardingFlowRequest{
				Mode:                  ModeGuided,
				EmotionalCheckinScore: 0,
			},
			expectedMode: ModeGuided,
			expectedStep: StepRecoveryArea,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			flow, err := StartOnboardingFlow(tt.req, "user-123", "tenant-456")
			if err != nil {
				t.Fatalf("StartOnboardingFlow() error = %v", err)
			}

			if flow.Mode != tt.expectedMode {
				t.Errorf("Mode = %v, want %v", flow.Mode, tt.expectedMode)
			}

			if flow.CurrentStep != tt.expectedStep {
				t.Errorf("CurrentStep = %v, want %v", flow.CurrentStep, tt.expectedStep)
			}

			if tt.expectedArea != nil {
				if flow.RecoveryArea == nil || *flow.RecoveryArea != *tt.expectedArea {
					t.Errorf("RecoveryArea = %v, want %v", flow.RecoveryArea, tt.expectedArea)
				}
			}

			if tt.expectedFramework != nil {
				if flow.FrameworkPreference == nil || *flow.FrameworkPreference != *tt.expectedFramework {
					t.Errorf("FrameworkPreference = %v, want %v", flow.FrameworkPreference, tt.expectedFramework)
				}
			}

			if flow.UserID != "user-123" {
				t.Errorf("UserID = %v, want user-123", flow.UserID)
			}

			if flow.TenantID != "tenant-456" {
				t.Errorf("TenantID = %v, want tenant-456", flow.TenantID)
			}

			if flow.IsCompleted() {
				t.Error("IsCompleted() = true, want false")
			}

			if flow.EmotionalCheckinScore != tt.req.EmotionalCheckinScore {
				t.Errorf("EmotionalCheckinScore = %v, want %v", flow.EmotionalCheckinScore, tt.req.EmotionalCheckinScore)
			}
		})
	}
}

func TestStartOnboardingFlow_InvalidRequest(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name        string
		req         StartOnboardingFlowRequest
		expectedErr error
	}{
		{
			name: "invalid mode",
			req: StartOnboardingFlowRequest{
				Mode:                  "invalid",
				EmotionalCheckinScore: 3,
			},
			expectedErr: ErrInvalidOnboardingMode,
		},
		{
			name: "emotional score too low",
			req: StartOnboardingFlowRequest{
				Mode:                  ModeGuided,
				EmotionalCheckinScore: -1,
			},
			expectedErr: ErrInvalidEmotionalScore,
		},
		{
			name: "emotional score too high",
			req: StartOnboardingFlowRequest{
				Mode:                  ModeGuided,
				EmotionalCheckinScore: 6,
			},
			expectedErr: ErrInvalidEmotionalScore,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			_, err := StartOnboardingFlow(tt.req, "user-123", "tenant-456")
			if err != tt.expectedErr {
				t.Errorf("StartOnboardingFlow() error = %v, want %v", err, tt.expectedErr)
			}
		})
	}
}

// ── Test SuggestModeFromEmotionalScore ──

func TestSuggestModeFromEmotionalScore(t *testing.T) {
	t.Parallel()

	tests := []struct {
		score        int
		expectedMode OnboardingMode
	}{
		{score: 0, expectedMode: ModeGuided},      // Skipped
		{score: 1, expectedMode: ModeStarterPack}, // Struggling
		{score: 2, expectedMode: ModeGuided},      // Low
		{score: 3, expectedMode: ModeGuided},      // Okay
		{score: 4, expectedMode: ModeGuided},      // Good
		{score: 5, expectedMode: ModeGuided},      // Strong
	}

	for _, tt := range tests {
		t.Run("", func(t *testing.T) {
			t.Parallel()

			mode := SuggestModeFromEmotionalScore(tt.score)
			if mode != tt.expectedMode {
				t.Errorf("SuggestModeFromEmotionalScore(%d) = %v, want %v", tt.score, mode, tt.expectedMode)
			}
		})
	}
}

// ── Test AdvanceStep ──

func TestAdvanceStep_GuidedMode(t *testing.T) {
	t.Parallel()

	recoveryArea := RecoveryAreaSexPornography
	framework := FrameworkSAA

	tests := []struct {
		name        string
		currentStep OnboardingStep
		targetStep  OnboardingStep
		wantErr     bool
	}{
		{
			name:        "advance from recoveryArea to framework",
			currentStep: StepRecoveryArea,
			targetStep:  StepFramework,
			wantErr:     false,
		},
		{
			name:        "advance from framework to innerCircle",
			currentStep: StepFramework,
			targetStep:  StepInnerCircle,
			wantErr:     false,
		},
		{
			name:        "advance from innerCircle to outerCircle",
			currentStep: StepInnerCircle,
			targetStep:  StepOuterCircle,
			wantErr:     false,
		},
		{
			name:        "advance from outerCircle to middleCircle",
			currentStep: StepOuterCircle,
			targetStep:  StepMiddleCircle,
			wantErr:     false,
		},
		{
			name:        "advance from middleCircle to review",
			currentStep: StepMiddleCircle,
			targetStep:  StepReview,
			wantErr:     false,
		},
		{
			name:        "jump from recoveryArea to innerCircle (skip framework)",
			currentStep: StepRecoveryArea,
			targetStep:  StepInnerCircle,
			wantErr:     true,
		},
		{
			name:        "jump from framework to middleCircle (skip inner and outer)",
			currentStep: StepFramework,
			targetStep:  StepMiddleCircle,
			wantErr:     true,
		},
		{
			name:        "jump to review from recoveryArea",
			currentStep: StepRecoveryArea,
			targetStep:  StepReview,
			wantErr:     false, // Can always go to review
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			flow := &OnboardingFlow{
				FlowID:              "flow-123",
				UserID:              "user-123",
				TenantID:            "tenant-456",
				Mode:                ModeGuided,
				CurrentStep:         tt.currentStep,
				RecoveryArea:        &recoveryArea,
				FrameworkPreference: &framework,
				StartedAt:           time.Now().Add(-1 * time.Hour),
				LastActivityAt:      time.Now().Add(-1 * time.Hour),
			}

			err := flow.AdvanceStep(AdvanceStepRequest{
				TargetStep: tt.targetStep,
			})

			if tt.wantErr {
				if err == nil {
					t.Error("AdvanceStep() expected error, got nil")
				}
			} else {
				if err != nil {
					t.Errorf("AdvanceStep() error = %v, want nil", err)
				}
				if flow.CurrentStep != tt.targetStep {
					t.Errorf("CurrentStep = %v, want %v", flow.CurrentStep, tt.targetStep)
				}
			}
		})
	}
}

func TestAdvanceStep_ExpressMode(t *testing.T) {
	t.Parallel()

	recoveryArea := RecoveryAreaSexPornography

	// Express mode allows flexible step ordering
	tests := []struct {
		name        string
		currentStep OnboardingStep
		targetStep  OnboardingStep
	}{
		{
			name:        "jump from recoveryArea to innerCircle",
			currentStep: StepRecoveryArea,
			targetStep:  StepInnerCircle,
		},
		{
			name:        "jump from innerCircle to middleCircle",
			currentStep: StepInnerCircle,
			targetStep:  StepMiddleCircle,
		},
		{
			name:        "jump from framework to review",
			currentStep: StepFramework,
			targetStep:  StepReview,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			flow := &OnboardingFlow{
				FlowID:         "flow-123",
				UserID:         "user-123",
				TenantID:       "tenant-456",
				Mode:           ModeExpress,
				CurrentStep:    tt.currentStep,
				RecoveryArea:   &recoveryArea,
				StartedAt:      time.Now().Add(-1 * time.Hour),
				LastActivityAt: time.Now().Add(-1 * time.Hour),
			}

			err := flow.AdvanceStep(AdvanceStepRequest{
				TargetStep: tt.targetStep,
			})

			if err != nil {
				t.Errorf("AdvanceStep() error = %v, want nil (express mode allows flexible ordering)", err)
			}

			if flow.CurrentStep != tt.targetStep {
				t.Errorf("CurrentStep = %v, want %v", flow.CurrentStep, tt.targetStep)
			}
		})
	}
}

func TestAdvanceStep_UpdatesRecoveryAreaAndFramework(t *testing.T) {
	t.Parallel()

	flow := &OnboardingFlow{
		FlowID:         "flow-123",
		UserID:         "user-123",
		TenantID:       "tenant-456",
		Mode:           ModeGuided,
		CurrentStep:    StepRecoveryArea,
		StartedAt:      time.Now().Add(-1 * time.Hour),
		LastActivityAt: time.Now().Add(-1 * time.Hour),
	}

	recoveryArea := RecoveryAreaAlcohol
	framework := FrameworkAA

	err := flow.AdvanceStep(AdvanceStepRequest{
		TargetStep:          StepFramework,
		RecoveryArea:        &recoveryArea,
		FrameworkPreference: &framework,
	})

	if err != nil {
		t.Fatalf("AdvanceStep() error = %v", err)
	}

	if flow.RecoveryArea == nil || *flow.RecoveryArea != recoveryArea {
		t.Errorf("RecoveryArea = %v, want %v", flow.RecoveryArea, recoveryArea)
	}

	if flow.FrameworkPreference == nil || *flow.FrameworkPreference != framework {
		t.Errorf("FrameworkPreference = %v, want %v", flow.FrameworkPreference, framework)
	}
}

func TestAdvanceStep_CompletedFlow(t *testing.T) {
	t.Parallel()

	now := time.Now()
	flow := &OnboardingFlow{
		FlowID:         "flow-123",
		UserID:         "user-123",
		TenantID:       "tenant-456",
		Mode:           ModeGuided,
		CurrentStep:    StepReview,
		StartedAt:      now.Add(-1 * time.Hour),
		LastActivityAt: now.Add(-10 * time.Minute),
		CompletedAt:    &now,
	}

	err := flow.AdvanceStep(AdvanceStepRequest{
		TargetStep: StepInnerCircle,
	})

	if err != ErrFlowAlreadyCompleted {
		t.Errorf("AdvanceStep() error = %v, want %v", err, ErrFlowAlreadyCompleted)
	}
}

// ── Test SwitchMode ──

func TestSwitchMode_ValidSwitch(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name          string
		initialMode   OnboardingMode
		targetMode    OnboardingMode
		starterPackID string
		expectedStep  OnboardingStep
		wantErr       bool
	}{
		{
			name:          "switch from guided to express",
			initialMode:   ModeGuided,
			targetMode:    ModeExpress,
			starterPackID: "",
			expectedStep:  StepFramework, // Unchanged
			wantErr:       false,
		},
		{
			name:          "switch from express to guided",
			initialMode:   ModeExpress,
			targetMode:    ModeGuided,
			starterPackID: "",
			expectedStep:  StepFramework, // Unchanged
			wantErr:       false,
		},
		{
			name:          "switch to starter pack with pack ID",
			initialMode:   ModeGuided,
			targetMode:    ModeStarterPack,
			starterPackID: "pack-123",
			expectedStep:  StepReview, // Goes to review after applying pack
			wantErr:       false,
		},
		{
			name:          "switch to starter pack without pack ID",
			initialMode:   ModeGuided,
			targetMode:    ModeStarterPack,
			starterPackID: "",
			expectedStep:  StepFramework,
			wantErr:       true, // Should fail
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			recoveryArea := RecoveryAreaSexPornography
			flow := &OnboardingFlow{
				FlowID:         "flow-123",
				UserID:         "user-123",
				TenantID:       "tenant-456",
				Mode:           tt.initialMode,
				CurrentStep:    StepFramework,
				RecoveryArea:   &recoveryArea,
				StartedAt:      time.Now().Add(-1 * time.Hour),
				LastActivityAt: time.Now().Add(-1 * time.Hour),
			}

			err := flow.SwitchMode(SwitchModeRequest{
				NewMode:         tt.targetMode,
				StarterPackID:   tt.starterPackID,
				ApplicationMode: ApplicationModeMerge,
			})

			if tt.wantErr {
				if err == nil {
					t.Error("SwitchMode() expected error, got nil")
				}
			} else {
				if err != nil {
					t.Errorf("SwitchMode() error = %v, want nil", err)
				}

				if flow.Mode != tt.targetMode {
					t.Errorf("Mode = %v, want %v", flow.Mode, tt.targetMode)
				}

				if flow.CurrentStep != tt.expectedStep {
					t.Errorf("CurrentStep = %v, want %v", flow.CurrentStep, tt.expectedStep)
				}

				if tt.starterPackID != "" && flow.AppliedStarterPackID != tt.starterPackID {
					t.Errorf("AppliedStarterPackID = %v, want %v", flow.AppliedStarterPackID, tt.starterPackID)
				}
			}
		})
	}
}

func TestSwitchMode_CompletedFlow(t *testing.T) {
	t.Parallel()

	now := time.Now()
	flow := &OnboardingFlow{
		FlowID:         "flow-123",
		UserID:         "user-123",
		TenantID:       "tenant-456",
		Mode:           ModeGuided,
		CurrentStep:    StepReview,
		StartedAt:      now.Add(-1 * time.Hour),
		LastActivityAt: now.Add(-10 * time.Minute),
		CompletedAt:    &now,
	}

	err := flow.SwitchMode(SwitchModeRequest{
		NewMode:         ModeExpress,
		ApplicationMode: ApplicationModeMerge,
	})

	if err != ErrFlowAlreadyCompleted {
		t.Errorf("SwitchMode() error = %v, want %v", err, ErrFlowAlreadyCompleted)
	}
}

// ── Test CompleteOnboarding ──

func TestCompleteOnboarding_CommitNow(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name           string
		innerCount     int
		expectedStatus CircleSetStatus
		wantErr        bool
	}{
		{
			name:           "valid commit with 1 inner item",
			innerCount:     1,
			expectedStatus: StatusActive,
			wantErr:        false,
		},
		{
			name:           "valid commit with multiple inner items",
			innerCount:     5,
			expectedStatus: StatusActive,
			wantErr:        false,
		},
		{
			name:           "invalid commit with no inner items",
			innerCount:     0,
			expectedStatus: "",
			wantErr:        true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			flow := &OnboardingFlow{
				FlowID:         "flow-123",
				UserID:         "user-123",
				TenantID:       "tenant-456",
				Mode:           ModeGuided,
				CurrentStep:    StepReview,
				StartedAt:      time.Now().Add(-1 * time.Hour),
				LastActivityAt: time.Now().Add(-10 * time.Minute),
			}

			status, err := flow.CompleteOnboarding(CompleteOnboardingRequest{
				CommitOption: CommitNow,
				InnerCount:   tt.innerCount,
				MiddleCount:  10,
				OuterCount:   15,
			})

			if tt.wantErr {
				if err == nil {
					t.Error("CompleteOnboarding() expected error, got nil")
				}
			} else {
				if err != nil {
					t.Errorf("CompleteOnboarding() error = %v, want nil", err)
				}

				if status != tt.expectedStatus {
					t.Errorf("status = %v, want %v", status, tt.expectedStatus)
				}

				if !flow.IsCompleted() {
					t.Error("IsCompleted() = false, want true")
				}

				if flow.CompletedAt == nil {
					t.Error("CompletedAt = nil, want non-nil")
				}
			}
		})
	}
}

func TestCompleteOnboarding_DraftVariants(t *testing.T) {
	t.Parallel()

	tests := []struct {
		commitOption   CommitOption
		expectedStatus CircleSetStatus
	}{
		{
			commitOption:   CommitDraft,
			expectedStatus: StatusDraft,
		},
		{
			commitOption:   CommitDraftShareSponsor,
			expectedStatus: StatusDraft,
		},
		{
			commitOption:   CommitDraftNoShare,
			expectedStatus: StatusDraft,
		},
	}

	for _, tt := range tests {
		t.Run(string(tt.commitOption), func(t *testing.T) {
			t.Parallel()

			flow := &OnboardingFlow{
				FlowID:         "flow-123",
				UserID:         "user-123",
				TenantID:       "tenant-456",
				Mode:           ModeGuided,
				CurrentStep:    StepReview,
				StartedAt:      time.Now().Add(-1 * time.Hour),
				LastActivityAt: time.Now().Add(-10 * time.Minute),
			}

			// Draft options don't require inner circle items
			status, err := flow.CompleteOnboarding(CompleteOnboardingRequest{
				CommitOption: tt.commitOption,
				InnerCount:   0,
				MiddleCount:  0,
				OuterCount:   0,
			})

			if err != nil {
				t.Errorf("CompleteOnboarding() error = %v, want nil", err)
			}

			if status != tt.expectedStatus {
				t.Errorf("status = %v, want %v", status, tt.expectedStatus)
			}

			if !flow.IsCompleted() {
				t.Error("IsCompleted() = false, want true")
			}
		})
	}
}

func TestCompleteOnboarding_AlreadyCompleted(t *testing.T) {
	t.Parallel()

	now := time.Now()
	flow := &OnboardingFlow{
		FlowID:         "flow-123",
		UserID:         "user-123",
		TenantID:       "tenant-456",
		Mode:           ModeGuided,
		CurrentStep:    StepReview,
		StartedAt:      now.Add(-1 * time.Hour),
		LastActivityAt: now.Add(-10 * time.Minute),
		CompletedAt:    &now,
	}

	_, err := flow.CompleteOnboarding(CompleteOnboardingRequest{
		CommitOption: CommitNow,
		InnerCount:   5,
		MiddleCount:  10,
		OuterCount:   15,
	})

	if err != ErrFlowAlreadyCompleted {
		t.Errorf("CompleteOnboarding() error = %v, want %v", err, ErrFlowAlreadyCompleted)
	}
}

func TestCompleteOnboarding_InvalidCommitOption(t *testing.T) {
	t.Parallel()

	flow := &OnboardingFlow{
		FlowID:         "flow-123",
		UserID:         "user-123",
		TenantID:       "tenant-456",
		Mode:           ModeGuided,
		CurrentStep:    StepReview,
		StartedAt:      time.Now().Add(-1 * time.Hour),
		LastActivityAt: time.Now().Add(-10 * time.Minute),
	}

	_, err := flow.CompleteOnboarding(CompleteOnboardingRequest{
		CommitOption: "invalid",
		InnerCount:   5,
		MiddleCount:  10,
		OuterCount:   15,
	})

	if err != ErrInvalidCommitOption {
		t.Errorf("CompleteOnboarding() error = %v, want %v", err, ErrInvalidCommitOption)
	}
}

// ── Test GetProgressMetadata ──

func TestGetProgressMetadata(t *testing.T) {
	t.Parallel()

	recoveryArea := RecoveryAreaSexPornography
	framework := FrameworkSAA
	now := time.Now()

	tests := []struct {
		name                   string
		flow                   *OnboardingFlow
		expectedStepsCompleted int
	}{
		{
			name: "recovery area step",
			flow: &OnboardingFlow{
				FlowID:         "flow-123",
				UserID:         "user-123",
				TenantID:       "tenant-456",
				Mode:           ModeGuided,
				CurrentStep:    StepRecoveryArea,
				StartedAt:      now,
				LastActivityAt: now,
			},
			expectedStepsCompleted: 0,
		},
		{
			name: "framework step with recovery area set",
			flow: &OnboardingFlow{
				FlowID:         "flow-123",
				UserID:         "user-123",
				TenantID:       "tenant-456",
				Mode:           ModeGuided,
				CurrentStep:    StepFramework,
				RecoveryArea:   &recoveryArea,
				StartedAt:      now,
				LastActivityAt: now,
			},
			expectedStepsCompleted: 1,
		},
		{
			name: "inner circle step",
			flow: &OnboardingFlow{
				FlowID:              "flow-123",
				UserID:              "user-123",
				TenantID:            "tenant-456",
				Mode:                ModeGuided,
				CurrentStep:         StepInnerCircle,
				RecoveryArea:        &recoveryArea,
				FrameworkPreference: &framework,
				StartedAt:           now,
				LastActivityAt:      now,
			},
			expectedStepsCompleted: 3,
		},
		{
			name: "review step",
			flow: &OnboardingFlow{
				FlowID:              "flow-123",
				UserID:              "user-123",
				TenantID:            "tenant-456",
				Mode:                ModeGuided,
				CurrentStep:         StepReview,
				RecoveryArea:        &recoveryArea,
				FrameworkPreference: &framework,
				StartedAt:           now,
				LastActivityAt:      now,
			},
			expectedStepsCompleted: 6,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			meta := tt.flow.GetProgressMetadata()

			if meta["flowId"] != tt.flow.FlowID {
				t.Errorf("flowId = %v, want %v", meta["flowId"], tt.flow.FlowID)
			}

			if meta["mode"] != string(tt.flow.Mode) {
				t.Errorf("mode = %v, want %v", meta["mode"], string(tt.flow.Mode))
			}

			if meta["currentStep"] != string(tt.flow.CurrentStep) {
				t.Errorf("currentStep = %v, want %v", meta["currentStep"], string(tt.flow.CurrentStep))
			}

			if meta["stepsCompleted"] != tt.expectedStepsCompleted {
				t.Errorf("stepsCompleted = %v, want %v", meta["stepsCompleted"], tt.expectedStepsCompleted)
			}

			if meta["totalSteps"] != 6 {
				t.Errorf("totalSteps = %v, want 6", meta["totalSteps"])
			}

			if meta["isCompleted"] != tt.flow.IsCompleted() {
				t.Errorf("isCompleted = %v, want %v", meta["isCompleted"], tt.flow.IsCompleted())
			}
		})
	}
}

// ── Test Type Validations ──

func TestOnboardingMode_IsValid(t *testing.T) {
	t.Parallel()

	tests := []struct {
		mode  OnboardingMode
		valid bool
	}{
		{ModeGuided, true},
		{ModeStarterPack, true},
		{ModeExpress, true},
		{"invalid", false},
		{"", false},
	}

	for _, tt := range tests {
		t.Run(string(tt.mode), func(t *testing.T) {
			t.Parallel()

			if tt.mode.IsValid() != tt.valid {
				t.Errorf("IsValid() = %v, want %v", tt.mode.IsValid(), tt.valid)
			}
		})
	}
}

func TestOnboardingStep_IsValid(t *testing.T) {
	t.Parallel()

	tests := []struct {
		step  OnboardingStep
		valid bool
	}{
		{StepRecoveryArea, true},
		{StepFramework, true},
		{StepInnerCircle, true},
		{StepOuterCircle, true},
		{StepMiddleCircle, true},
		{StepReview, true},
		{StepStarterPack, true},
		{StepEmotionalStep, true},
		{"invalid", false},
		{"", false},
	}

	for _, tt := range tests {
		t.Run(string(tt.step), func(t *testing.T) {
			t.Parallel()

			if tt.step.IsValid() != tt.valid {
				t.Errorf("IsValid() = %v, want %v", tt.step.IsValid(), tt.valid)
			}
		})
	}
}

func TestCommitOption_IsValid(t *testing.T) {
	t.Parallel()

	tests := []struct {
		option CommitOption
		valid  bool
	}{
		{CommitNow, true},
		{CommitDraft, true},
		{CommitDraftShareSponsor, true},
		{CommitDraftNoShare, true},
		{"invalid", false},
		{"", false},
	}

	for _, tt := range tests {
		t.Run(string(tt.option), func(t *testing.T) {
			t.Parallel()

			if tt.option.IsValid() != tt.valid {
				t.Errorf("IsValid() = %v, want %v", tt.option.IsValid(), tt.valid)
			}
		})
	}
}

// ── Test IsCompleted ──

func TestIsCompleted(t *testing.T) {
	t.Parallel()

	now := time.Now()

	tests := []struct {
		name        string
		completedAt *time.Time
		expected    bool
	}{
		{
			name:        "not completed",
			completedAt: nil,
			expected:    false,
		},
		{
			name:        "completed",
			completedAt: &now,
			expected:    true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			flow := &OnboardingFlow{
				FlowID:         "flow-123",
				UserID:         "user-123",
				TenantID:       "tenant-456",
				Mode:           ModeGuided,
				CurrentStep:    StepReview,
				StartedAt:      now,
				LastActivityAt: now,
				CompletedAt:    tt.completedAt,
			}

			if flow.IsCompleted() != tt.expected {
				t.Errorf("IsCompleted() = %v, want %v", flow.IsCompleted(), tt.expected)
			}
		})
	}
}
