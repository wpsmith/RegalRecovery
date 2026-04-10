// test/integration/threecircles_integration_test.go
package integration

import (
	"testing"
	"time"

	"github.com/regalrecovery/api/internal/domain/threecircles"
	. "github.com/regalrecovery/api/test/helpers"
)

// =============================================================================
// Integration Tests -- Three Circles Feature Full Domain Logic Stack
// =============================================================================

// TestThreeCircles_Integration_CircleSetLifecycle verifies the full lifecycle:
// Create -> Add items -> Commit -> Edit -> Version history -> Restore.
func TestThreeCircles_Integration_CircleSetLifecycle(t *testing.T) {
	// Given -- Create a new draft circle set
	set := &threecircles.CircleSet{
		ID:           "set-1",
		UserID:       "user-alex",
		TenantID:     "tenant-1",
		Name:         "My SA Recovery",
		RecoveryArea: threecircles.RecoveryAreaSexPornography,
		Status:       threecircles.StatusDraft,
		CreatedAt:    time.Now().UTC(),
		ModifiedAt:   time.Now().UTC(),
	}

	// When -- Add items to each circle
	innerItem := threecircles.CircleItem{
		ItemID:       "item-1",
		BehaviorName: "Viewing pornography or acting out sexually outside of marriage",
		Source:       threecircles.SourceUser,
		CreatedAt:    time.Now().UTC(),
		ModifiedAt:   time.Now().UTC(),
	}
	middleItem := threecircles.CircleItem{
		ItemID:       "item-2",
		BehaviorName: "Staying up late alone browsing social media",
		Category:     "behavioral",
		Source:       threecircles.SourceUser,
		CreatedAt:    time.Now().UTC(),
		ModifiedAt:   time.Now().UTC(),
	}
	outerItem := threecircles.CircleItem{
		ItemID:       "item-3",
		BehaviorName: "Daily morning prayer and meditation",
		Category:     "spiritual",
		Source:       threecircles.SourceUser,
		CreatedAt:    time.Now().UTC(),
		ModifiedAt:   time.Now().UTC(),
	}

	set.InnerCircle = append(set.InnerCircle, innerItem)
	set.MiddleCircle = append(set.MiddleCircle, middleItem)
	set.OuterCircle = append(set.OuterCircle, outerItem)

	// Then -- Verify circles populated
	if len(set.InnerCircle) != 1 {
		t.Errorf("expected 1 inner circle item, got %d", len(set.InnerCircle))
	}
	if len(set.MiddleCircle) != 1 {
		t.Errorf("expected 1 middle circle item, got %d", len(set.MiddleCircle))
	}
	if len(set.OuterCircle) != 1 {
		t.Errorf("expected 1 outer circle item, got %d", len(set.OuterCircle))
	}

	// When -- Commit the set
	err := CommitSet(set, "Initial commit")
	if err != nil {
		t.Fatalf("expected no error committing set, got %v", err)
	}

	// Then -- Status changed to active
	if set.Status != threecircles.StatusActive {
		t.Errorf("expected status to be active, got %s", set.Status)
	}
	if set.CommittedAt == nil {
		t.Error("expected committedAt to be set")
	}
	if set.CurrentVersion != 1 {
		t.Errorf("expected version 1, got %d", set.CurrentVersion)
	}

	// When -- Edit an item (update middle circle item)
	set.MiddleCircle[0].BehaviorName = "Staying up past midnight alone browsing social media without accountability"
	set.MiddleCircle[0].ModifiedAt = time.Now().UTC()
	set.CurrentVersion++

	// Then -- Version incremented
	if set.CurrentVersion != 2 {
		t.Errorf("expected version 2 after edit, got %d", set.CurrentVersion)
	}

	// When -- Create version snapshot
	snapshot := CreateSnapshot(set, "Added specificity to middle circle item", threecircles.ChangeItemUpdated, []string{"item-2"})

	// Then -- Snapshot created
	if snapshot == nil {
		t.Fatal("expected snapshot to be created")
	}
	if snapshot.VersionNumber != 2 {
		t.Errorf("expected snapshot version 2, got %d", snapshot.VersionNumber)
	}
	if snapshot.ChangeType != threecircles.ChangeItemUpdated {
		t.Errorf("expected change type itemUpdated, got %s", snapshot.ChangeType)
	}
	if len(snapshot.ChangedItems) != 1 {
		t.Errorf("expected 1 changed item, got %d", len(snapshot.ChangedItems))
	}

	// When -- Restore from snapshot (creates new version)
	restored, err := RestoreFromSnapshot(snapshot, "Restored version 2")
	if err != nil {
		t.Fatalf("expected no error restoring, got %v", err)
	}

	// Then -- New version created (not rewind)
	if restored.CurrentVersion != 3 {
		t.Errorf("expected version 3 after restore, got %d", restored.CurrentVersion)
	}
	if restored.Status != threecircles.StatusActive {
		t.Errorf("expected status to remain active, got %s", restored.Status)
	}
}

// TestThreeCircles_Integration_ItemOperations_AddUpdateMoveDelete verifies all
// item operations with version tracking at each step.
func TestThreeCircles_Integration_ItemOperations_AddUpdateMoveDelete(t *testing.T) {
	// Given -- Active circle set with one item
	set := &threecircles.CircleSet{
		ID:             "set-1",
		UserID:         "user-james",
		TenantID:       "tenant-1",
		Name:           "My Recovery",
		RecoveryArea:   threecircles.RecoveryAreaSexPornography,
		Status:         threecircles.StatusActive,
		CurrentVersion: 1,
		InnerCircle: []threecircles.CircleItem{
			{
				ItemID:       "item-1",
				BehaviorName: "Pornography",
				Source:       threecircles.SourceUser,
				CreatedAt:    time.Now().UTC(),
				ModifiedAt:   time.Now().UTC(),
			},
		},
		CreatedAt:  time.Now().UTC(),
		ModifiedAt: time.Now().UTC(),
	}
	committedAt := time.Now().UTC()
	set.CommittedAt = &committedAt

	// When -- Add new item to middle circle
	newItem := threecircles.CircleItem{
		ItemID:       "item-2",
		BehaviorName: "Isolating from accountability partners",
		Category:     "emotional",
		Source:       threecircles.SourceUser,
		CreatedAt:    time.Now().UTC(),
		ModifiedAt:   time.Now().UTC(),
	}
	err := AddItem(set, threecircles.CircleMiddle, newItem)
	if err != nil {
		t.Fatalf("expected no error adding item, got %v", err)
	}

	// Then -- Item added, version incremented
	if len(set.MiddleCircle) != 1 {
		t.Errorf("expected 1 middle circle item, got %d", len(set.MiddleCircle))
	}
	if set.CurrentVersion != 2 {
		t.Errorf("expected version 2, got %d", set.CurrentVersion)
	}

	// When -- Update the item
	err = UpdateItem(set, "item-2", &threecircles.UpdateCircleItemRequest{
		BehaviorName:      "Isolating from accountability partners when feeling shame",
		SpecificityDetail: "Avoiding check-in calls after urges",
	})
	if err != nil {
		t.Fatalf("expected no error updating item, got %v", err)
	}

	// Then -- Item updated, version incremented
	if set.MiddleCircle[0].SpecificityDetail != "Avoiding check-in calls after urges" {
		t.Errorf("expected specificity detail to be updated")
	}
	if set.CurrentVersion != 3 {
		t.Errorf("expected version 3, got %d", set.CurrentVersion)
	}

	// When -- Move item from middle to inner
	err = MoveItem(set, "item-2", threecircles.CircleInner, "Realized this is critical boundary")
	if err != nil {
		t.Fatalf("expected no error moving item, got %v", err)
	}

	// Then -- Item moved, version incremented
	if len(set.MiddleCircle) != 0 {
		t.Errorf("expected middle circle to be empty, got %d items", len(set.MiddleCircle))
	}
	if len(set.InnerCircle) != 2 {
		t.Errorf("expected 2 inner circle items, got %d", len(set.InnerCircle))
	}
	if set.CurrentVersion != 4 {
		t.Errorf("expected version 4, got %d", set.CurrentVersion)
	}

	// When -- Delete item from inner circle
	err = DeleteItem(set, "item-2")
	if err != nil {
		t.Fatalf("expected no error deleting item, got %v", err)
	}

	// Then -- Item deleted, version incremented
	if len(set.InnerCircle) != 1 {
		t.Errorf("expected 1 inner circle item after delete, got %d", len(set.InnerCircle))
	}
	if set.CurrentVersion != 5 {
		t.Errorf("expected version 5, got %d", set.CurrentVersion)
	}
}

// TestThreeCircles_Integration_StarterPack_ApplyMerge verifies starter pack
// application in merge mode with source tagging.
func TestThreeCircles_Integration_StarterPack_ApplyMerge(t *testing.T) {
	// Given -- Draft circle set with one user-added item
	set := threecircles.ApplyCircleSet{
		InnerCircle: []threecircles.CircleItem{
			{
				ItemID:       "user-item-1",
				BehaviorName: "My specific bottom line behavior",
				Source:       threecircles.SourceUser,
				CreatedAt:    time.Now().UTC(),
				ModifiedAt:   time.Now().UTC(),
			},
		},
	}

	// Build starter pack
	pack := threecircles.StarterPack{
		ID:           "pack-sa-secular",
		Name:         "SA Recovery Starter Pack (Secular)",
		RecoveryArea: threecircles.RecoveryAreaSexPornography,
		Variant:      threecircles.VariantSecular,
		InnerCircle: []threecircles.StarterPackItem{
			{BehaviorName: "Viewing pornography", Category: "behavioral"},
			{BehaviorName: "Sexual activity outside marriage", Category: "behavioral"},
			{BehaviorName: "Fantasy and objectification", Category: "emotional"},
		},
		MiddleCircle: []threecircles.StarterPackItem{
			{BehaviorName: "Staying up late alone", Category: "behavioral"},
			{BehaviorName: "Isolating from accountability", Category: "emotional"},
			{BehaviorName: "High-risk environments", Category: "environmental"},
			{BehaviorName: "Skipping recovery meetings", Category: "lifestyle"},
		},
		OuterCircle: []threecircles.StarterPackItem{
			{BehaviorName: "Daily prayer and meditation", Category: "spiritual"},
			{BehaviorName: "Regular exercise", Category: "physical"},
		},
		ClinicalReviewer:  "Dr. Jane Smith, CSAT",
		CommunityReviewer: "John Doe (10 years SA)",
		Version:           1,
		IsActive:          true,
	}

	// When -- Apply starter pack in merge mode
	result, err := threecircles.ApplyStarterPack(pack, set, threecircles.ApplicationModeMerge)
	if err != nil {
		t.Fatalf("expected no error applying starter pack, got %v", err)
	}

	// Then -- User item preserved, pack items added with correct source
	if result.ItemsAdded != 9 {
		t.Errorf("expected 9 items added (3 inner + 4 middle + 2 outer), got %d", result.ItemsAdded)
	}
	if len(result.InnerCircle) != 4 {
		t.Errorf("expected 4 inner circle items (1 user + 3 pack), got %d", len(result.InnerCircle))
	}
	if len(result.MiddleCircle) != 4 {
		t.Errorf("expected 4 middle circle items, got %d", len(result.MiddleCircle))
	}
	if len(result.OuterCircle) != 2 {
		t.Errorf("expected 2 outer circle items, got %d", len(result.OuterCircle))
	}

	// Verify source tagging
	for _, item := range result.InnerCircle {
		if item.BehaviorName == "My specific bottom line behavior" {
			if item.Source != threecircles.SourceUser {
				t.Errorf("expected user item to have source=user, got %s", item.Source)
			}
		} else {
			if item.Source != threecircles.SourceStarterPack {
				t.Errorf("expected pack item to have source=starterPack, got %s", item.Source)
			}
		}
	}
}

// TestThreeCircles_Integration_Onboarding_GuidedFlow_AdvanceSteps verifies
// guided onboarding flow step progression and completion.
func TestThreeCircles_Integration_Onboarding_GuidedFlow_AdvanceSteps(t *testing.T) {
	// Given -- New onboarding flow in guided mode
	flow := &threecircles.OnboardingFlow{
		FlowID:                "flow-1",
		UserID:                "user-maria",
		TenantID:              "tenant-1",
		Mode:                  threecircles.ModeGuided,
		CurrentStep:           threecircles.StepRecoveryArea,
		EmotionalCheckinScore: 0,
		StartedAt:             time.Now().UTC(),
		LastActivityAt:        time.Now().UTC(),
	}

	// When -- Advance to framework step
	err := AdvanceOnboardingStep(flow, threecircles.StepFramework)
	if err != nil {
		t.Fatalf("expected no error advancing to framework, got %v", err)
	}

	// Then -- Step advanced
	if flow.CurrentStep != threecircles.StepFramework {
		t.Errorf("expected current step to be framework, got %s", flow.CurrentStep)
	}

	// When -- Set recovery area and framework
	recoveryArea := threecircles.RecoveryAreaLoveRelationships
	frameworkPref := threecircles.FrameworkSLAA
	flow.RecoveryArea = &recoveryArea
	flow.FrameworkPreference = &frameworkPref

	// When -- Advance to inner circle step
	err = AdvanceOnboardingStep(flow, threecircles.StepInnerCircle)
	if err != nil {
		t.Fatalf("expected no error advancing to inner circle, got %v", err)
	}

	// When -- Advance to outer circle step
	err = AdvanceOnboardingStep(flow, threecircles.StepOuterCircle)
	if err != nil {
		t.Fatalf("expected no error advancing to outer circle, got %v", err)
	}

	// When -- Advance to middle circle step
	err = AdvanceOnboardingStep(flow, threecircles.StepMiddleCircle)
	if err != nil {
		t.Fatalf("expected no error advancing to middle circle, got %v", err)
	}

	// When -- Advance to review step
	err = AdvanceOnboardingStep(flow, threecircles.StepReview)
	if err != nil {
		t.Fatalf("expected no error advancing to review, got %v", err)
	}

	// Then -- Flow at review step
	if flow.CurrentStep != threecircles.StepReview {
		t.Errorf("expected current step to be review, got %s", flow.CurrentStep)
	}

	// When -- Complete onboarding
	err = CompleteOnboarding(flow)
	if err != nil {
		t.Fatalf("expected no error completing onboarding, got %v", err)
	}

	// Then -- Flow completed
	if !flow.IsCompleted() {
		t.Error("expected flow to be completed")
	}
	if flow.CompletedAt == nil {
		t.Error("expected completedAt to be set")
	}
}

// TestThreeCircles_Integration_Onboarding_SwitchMode_StarterPackToExpress
// verifies mode switching during onboarding.
func TestThreeCircles_Integration_Onboarding_SwitchMode_StarterPackToExpress(t *testing.T) {
	// Given -- Onboarding flow in starter pack mode
	flow := &threecircles.OnboardingFlow{
		FlowID:                "flow-1",
		UserID:                "user-rachel",
		TenantID:              "tenant-1",
		Mode:                  threecircles.ModeStarterPack,
		CurrentStep:           threecircles.StepStarterPack,
		EmotionalCheckinScore: 1, // Struggling
		StartedAt:             time.Now().UTC(),
		LastActivityAt:        time.Now().UTC(),
	}
	recoveryArea := threecircles.RecoveryAreaSexPornography
	flow.RecoveryArea = &recoveryArea

	// When -- User decides to switch to express mode
	err := SwitchOnboardingMode(flow, threecircles.ModeExpress)
	if err != nil {
		t.Fatalf("expected no error switching mode, got %v", err)
	}

	// Then -- Mode changed, step reset
	if flow.Mode != threecircles.ModeExpress {
		t.Errorf("expected mode to be express, got %s", flow.Mode)
	}
	if flow.CurrentStep != threecircles.StepInnerCircle {
		t.Errorf("expected step to reset to innerCircle, got %s", flow.CurrentStep)
	}
}

// TestThreeCircles_Integration_Guardrails_SpecificityNudge verifies vague item
// detection and specificity nudge message.
func TestThreeCircles_Integration_Guardrails_SpecificityNudge(t *testing.T) {
	// Given -- User enters vague behavior
	vagueItems := []string{
		"Stop",
		"Be good",
		"Better habits",
		"Don't be bad",
	}

	for _, behavior := range vagueItems {
		t.Run(behavior, func(t *testing.T) {
			// When -- Check specificity
			advice := threecircles.CheckSpecificity(behavior)

			// Then -- Advisory returned
			if advice == nil {
				t.Fatal("expected specificity advice for vague behavior")
			}
			if advice.Type != threecircles.GuardrailSpecificity {
				t.Errorf("expected specificity type, got %s", advice.Type)
			}
			if advice.Blocking {
				t.Error("expected non-blocking advice")
			}
			if advice.Message == "" {
				t.Error("expected message to be provided")
			}

			// Verify trauma-informed language
			err := threecircles.ValidateTraumaInformedLanguage(advice.Message)
			if err != nil {
				t.Errorf("guardrail message violates trauma-informed language: %v", err)
			}
		})
	}
}

// TestThreeCircles_Integration_Guardrails_InnerCircleOverload verifies overload
// detection at 9 items (soft) and 20+ items (hard).
func TestThreeCircles_Integration_Guardrails_InnerCircleOverload(t *testing.T) {
	tests := []struct {
		name      string
		count     int
		expectAdv bool
		blocking  bool
	}{
		{"8 items - no advice", 8, false, false},
		{"9 items - soft advisory", 9, true, false},
		{"15 items - soft advisory", 15, true, false},
		{"20 items - no advice at boundary", 20, false, false},
		{"21 items - blocking", 21, true, true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// When -- Check overload
			advice := threecircles.CheckInnerCircleOverload(tt.count)

			// Then -- Verify advice presence
			if tt.expectAdv && advice == nil {
				t.Fatal("expected advice but got nil")
			}
			if !tt.expectAdv && advice != nil {
				t.Fatalf("expected no advice but got: %+v", advice)
			}

			if advice != nil {
				if advice.Blocking != tt.blocking {
					t.Errorf("expected blocking=%v, got %v", tt.blocking, advice.Blocking)
				}
				if advice.Type != threecircles.GuardrailOverload {
					t.Errorf("expected overload type, got %s", advice.Type)
				}

				// Verify trauma-informed language
				err := threecircles.ValidateTraumaInformedLanguage(advice.Message)
				if err != nil {
					t.Errorf("guardrail message violates trauma-informed language: %v", err)
				}
			}
		})
	}
}

// TestThreeCircles_Integration_Guardrails_MiddleCircleDepth verifies depth
// nudge when middle circle has fewer than 3 items at commit time.
func TestThreeCircles_Integration_Guardrails_MiddleCircleDepth(t *testing.T) {
	tests := []struct {
		name      string
		count     int
		expectAdv bool
	}{
		{"0 items - advice", 0, true},
		{"2 items - advice", 2, true},
		{"3 items - no advice", 3, false},
		{"5 items - no advice", 5, false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// When -- Check depth
			advice := threecircles.CheckMiddleCircleDepth(tt.count)

			// Then -- Verify advice
			if tt.expectAdv && advice == nil {
				t.Fatal("expected advice but got nil")
			}
			if !tt.expectAdv && advice != nil {
				t.Fatalf("expected no advice but got: %+v", advice)
			}

			if advice != nil {
				if advice.Blocking {
					t.Error("expected non-blocking advice")
				}
				if advice.Type != threecircles.GuardrailMiddleCircleDepth {
					t.Errorf("expected middleCircleDepth type, got %s", advice.Type)
				}

				// Verify trauma-informed language
				err := threecircles.ValidateTraumaInformedLanguage(advice.Message)
				if err != nil {
					t.Errorf("guardrail message violates trauma-informed language: %v", err)
				}
			}
		})
	}
}

// TestThreeCircles_Integration_PatternTimeline_Build30Entries_Query7d30d verifies
// building a 30-day timeline and querying with different periods.
func TestThreeCircles_Integration_PatternTimeline_Build30Entries_Query7d30d(t *testing.T) {
	// Given -- Build 30 days of timeline entries
	entries := make([]threecircles.TimelineEntry, 30)
	baseDate := time.Date(2026, 3, 10, 0, 0, 0, 0, time.UTC)

	for i := 0; i < 30; i++ {
		date := baseDate.AddDate(0, 0, i)
		dominant := threecircles.CircleOuter
		if i%7 == 0 { // Every 7th day: middle circle
			dominant = threecircles.CircleMiddle
		}
		if i == 15 { // One inner circle day
			dominant = threecircles.CircleInner
		}

		entries[i] = threecircles.TimelineEntry{
			Date:           date.Format("2006-01-02"),
			SetID:          "set-1",
			DominantCircle: dominant,
			InnerContact:   dominant == threecircles.CircleInner,
			MiddleContact:  dominant == threecircles.CircleMiddle,
			OuterContact:   dominant == threecircles.CircleOuter,
			MoodScore:      7,
			UrgeIntensity:  3,
		}
	}

	// When -- Query 7-day summary
	summary7d, err := BuildTimelineSummary(entries, threecircles.Period7D, time.Date(2026, 4, 8, 0, 0, 0, 0, time.UTC))
	if err != nil {
		t.Fatalf("expected no error building 7d summary, got %v", err)
	}

	// Then -- Summary populated
	if summary7d.Period != "7d" {
		t.Errorf("expected period 7d, got %s", summary7d.Period)
	}
	if summary7d.OuterDays+summary7d.MiddleDays+summary7d.InnerDays+summary7d.NoCheckinDays != 7 {
		t.Error("expected 7 total days in 7d summary")
	}

	// When -- Query 30-day summary
	summary30d, err := BuildTimelineSummary(entries, threecircles.Period30D, time.Date(2026, 4, 8, 0, 0, 0, 0, time.UTC))
	if err != nil {
		t.Fatalf("expected no error building 30d summary, got %v", err)
	}

	// Then -- Summary populated
	if summary30d.Period != "30d" {
		t.Errorf("expected period 30d, got %s", summary30d.Period)
	}
	if summary30d.OuterDays+summary30d.MiddleDays+summary30d.InnerDays+summary30d.NoCheckinDays != 30 {
		t.Error("expected 30 total days in 30d summary")
	}

	// Verify framing message is non-judgmental and contains no "streak" language
	if ContainsWord(summary30d.FramingMessage, "streak") {
		t.Errorf("framing message must not contain 'streak': %s", summary30d.FramingMessage)
	}
	err = threecircles.ValidateTraumaInformedLanguage(summary30d.FramingMessage)
	if err != nil {
		t.Errorf("framing message violates trauma-informed language: %v", err)
	}
}

// TestThreeCircles_Integration_DriftDetection_3MiddleDays_VerifyAlert verifies
// drift alert triggered when 3+ middle circle days in 7-day window.
func TestThreeCircles_Integration_DriftDetection_3MiddleDays_VerifyAlert(t *testing.T) {
	// Given -- 7-day window with 3 middle circle days
	entries := []threecircles.TimelineEntry{
		{Date: "2026-04-02", DominantCircle: threecircles.CircleOuter, MiddleContact: false},
		{Date: "2026-04-03", DominantCircle: threecircles.CircleMiddle, MiddleContact: true},
		{Date: "2026-04-04", DominantCircle: threecircles.CircleOuter, MiddleContact: false},
		{Date: "2026-04-05", DominantCircle: threecircles.CircleMiddle, MiddleContact: true},
		{Date: "2026-04-06", DominantCircle: threecircles.CircleOuter, MiddleContact: false},
		{Date: "2026-04-07", DominantCircle: threecircles.CircleMiddle, MiddleContact: true},
		{Date: "2026-04-08", DominantCircle: threecircles.CircleOuter, MiddleContact: false},
	}

	// When -- Detect drift
	alert := DetectDrift(entries, "user-1", "set-1", 7)

	// Then -- Alert generated
	if alert == nil {
		t.Fatal("expected drift alert to be generated")
	}
	if alert.MiddleCircleDays != 3 {
		t.Errorf("expected 3 middle circle days, got %d", alert.MiddleCircleDays)
	}
	if alert.Message == "" {
		t.Error("expected drift alert message")
	}

	// Verify message is gentle and non-punitive
	if ContainsWord(alert.Message, "fail") || ContainsWord(alert.Message, "weak") {
		t.Errorf("drift message must be gentle and non-punitive: %s", alert.Message)
	}
	err := threecircles.ValidateTraumaInformedLanguage(alert.Message)
	if err != nil {
		t.Errorf("drift message violates trauma-informed language: %v", err)
	}

	// When -- Dismiss alert
	err = DismissAlert(alert, "Working with sponsor on this")
	if err != nil {
		t.Fatalf("expected no error dismissing alert, got %v", err)
	}

	// Then -- Alert dismissed
	if !alert.Dismissed {
		t.Error("expected alert to be dismissed")
	}
	if alert.DismissedAt == nil {
		t.Error("expected dismissedAt to be set")
	}
	if alert.ActionTaken != "Working with sponsor on this" {
		t.Errorf("expected action taken to be recorded, got %s", alert.ActionTaken)
	}
}

// TestThreeCircles_Integration_InsightGeneration_DayOfWeekPattern verifies
// insight generation from 14+ days with detectable pattern.
func TestThreeCircles_Integration_InsightGeneration_DayOfWeekPattern(t *testing.T) {
	// Given -- 21 days with middle circle consistently on Fridays
	entries := make([]threecircles.TimelineEntry, 21)
	baseDate := time.Date(2026, 3, 17, 0, 0, 0, 0, time.UTC) // Tuesday

	for i := 0; i < 21; i++ {
		date := baseDate.AddDate(0, 0, i)
		dayOfWeek := date.Weekday()
		dominant := threecircles.CircleOuter
		if dayOfWeek == time.Friday {
			dominant = threecircles.CircleMiddle
		}

		entries[i] = threecircles.TimelineEntry{
			Date:           date.Format("2006-01-02"),
			SetID:          "set-1",
			DominantCircle: dominant,
			InnerContact:   false,
			MiddleContact:  dominant == threecircles.CircleMiddle,
			OuterContact:   dominant == threecircles.CircleOuter,
			MoodScore:      7,
		}
	}

	// When -- Generate insights
	insights := GenerateInsights(entries, time.Date(2026, 4, 8, 0, 0, 0, 0, time.UTC))

	// Then -- Day-of-week insight generated
	foundDayOfWeek := false
	for _, insight := range insights {
		if insight.InsightType == threecircles.InsightDayOfWeek {
			foundDayOfWeek = true
			if insight.Description == "" {
				t.Error("expected insight description")
			}
			if insight.ActionSuggestion == "" {
				t.Error("expected action suggestion")
			}
			if insight.Confidence < 0.7 {
				t.Errorf("expected high confidence for clear pattern, got %f", insight.Confidence)
			}

			// Verify language is non-judgmental
			err := threecircles.ValidateTraumaInformedLanguage(insight.Description)
			if err != nil {
				t.Errorf("insight description violates trauma-informed language: %v", err)
			}
			err = threecircles.ValidateTraumaInformedLanguage(insight.ActionSuggestion)
			if err != nil {
				t.Errorf("action suggestion violates trauma-informed language: %v", err)
			}
		}
	}

	if !foundDayOfWeek {
		t.Error("expected day-of-week insight to be generated")
	}
}

// TestThreeCircles_Integration_VersionCompare_TwoVersions_VerifyDiff verifies
// version comparison and diff output.
func TestThreeCircles_Integration_VersionCompare_TwoVersions_VerifyDiff(t *testing.T) {
	// Given -- Version 1
	v1 := &threecircles.CircleSet{
		ID:             "set-1",
		UserID:         "user-1",
		TenantID:       "tenant-1",
		Name:           "My Recovery",
		RecoveryArea:   threecircles.RecoveryAreaSexPornography,
		Status:         threecircles.StatusActive,
		CurrentVersion: 1,
		InnerCircle: []threecircles.CircleItem{
			{ItemID: "item-1", BehaviorName: "Pornography"},
		},
		MiddleCircle: []threecircles.CircleItem{
			{ItemID: "item-2", BehaviorName: "Staying up late"},
		},
		CreatedAt:  time.Now().UTC(),
		ModifiedAt: time.Now().UTC(),
	}

	// Given -- Version 2 (added item to middle, moved item to inner)
	v2 := &threecircles.CircleSet{
		ID:             "set-1",
		UserID:         "user-1",
		TenantID:       "tenant-1",
		Name:           "My Recovery",
		RecoveryArea:   threecircles.RecoveryAreaSexPornography,
		Status:         threecircles.StatusActive,
		CurrentVersion: 2,
		InnerCircle: []threecircles.CircleItem{
			{ItemID: "item-1", BehaviorName: "Pornography"},
			{ItemID: "item-2", BehaviorName: "Staying up late alone"},
		},
		MiddleCircle: []threecircles.CircleItem{
			{ItemID: "item-3", BehaviorName: "Skipping meetings"},
		},
		CreatedAt:  time.Now().UTC(),
		ModifiedAt: time.Now().UTC(),
	}

	// Create snapshots for comparison
	snapshot1 := threecircles.VersionSnapshot{
		VersionNumber: v1.CurrentVersion,
		SetID:         v1.ID,
		UserID:        v1.UserID,
		Snapshot:      *v1,
		InnerCount:    len(v1.InnerCircle),
		MiddleCount:   len(v1.MiddleCircle),
		OuterCount:    len(v1.OuterCircle),
		ChangedAt:     time.Now().UTC(),
	}
	snapshot2 := threecircles.VersionSnapshot{
		VersionNumber: v2.CurrentVersion,
		SetID:         v2.ID,
		UserID:        v2.UserID,
		Snapshot:      *v2,
		InnerCount:    len(v2.InnerCircle),
		MiddleCount:   len(v2.MiddleCircle),
		OuterCount:    len(v2.OuterCircle),
		ChangedAt:     time.Now().UTC(),
	}

	// When -- Compare versions
	diff := threecircles.CompareVersions(snapshot1, snapshot2)

	// Then -- Diff populated
	if len(diff.ItemsMoved) == 0 && len(diff.MiddleAdded) == 0 {
		t.Error("expected changes to be detected")
	}

	// Verify diff contains moved item (item-2 moved from middle to inner)
	foundMove := false
	for _, move := range diff.ItemsMoved {
		if move.ItemID == "item-2" && move.FromCircle == threecircles.CircleMiddle && move.ToCircle == threecircles.CircleInner {
			foundMove = true
		}
	}

	// Verify diff contains added item (item-3 added to middle)
	foundAdd := false
	for _, item := range diff.MiddleAdded {
		if item.ItemID == "item-3" {
			foundAdd = true
		}
	}

	if !foundMove {
		t.Error("expected to find item-2 move in diff")
	}
	if !foundAdd {
		t.Error("expected to find item-3 addition in diff")
	}
}

// TestThreeCircles_Integration_TraumaInformedLanguage_AllGuardrails verifies
// that ALL guardrail messages pass trauma-informed language validation.
func TestThreeCircles_Integration_TraumaInformedLanguage_AllGuardrails(t *testing.T) {
	// Collect all guardrail messages
	messages := []string{
		threecircles.CheckSpecificity("stop").Message,
		threecircles.CheckInnerCircleOverload(9).Message,
		threecircles.CheckMiddleCircleDepth(2).Message,
		threecircles.CheckIsolation(false).Message,
		threecircles.CheckInnerCircleAddition().Message,
		threecircles.CheckInnerCircleRemoval().Message,
	}

	// Verify each message passes trauma-informed language check
	for i, msg := range messages {
		t.Run("Message "+string(rune(i+'0')), func(t *testing.T) {
			err := threecircles.ValidateTraumaInformedLanguage(msg)
			if err != nil {
				t.Errorf("guardrail message violates trauma-informed language: %q - %v", msg, err)
			}

			// Verify no "streak" language
			if ContainsWord(msg, "streak") {
				t.Errorf("message must not contain 'streak': %s", msg)
			}
		})
	}
}

// =============================================================================
// Test Helpers
// =============================================================================

// Helper functions use shared helpers from test/helpers/common.go
