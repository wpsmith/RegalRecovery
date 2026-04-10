// test/unit/threecircles_test.go
package unit

import (
	"testing"
	"time"

	"github.com/regalrecovery/api/internal/domain/threecircles"
	. "github.com/regalrecovery/api/test/helpers"
)

// =============================================================================
// E2E Persona Tests -- Three Circles Feature
// =============================================================================

// TestThreeCircles_E2E_Rachel_Day5_StarterPack_Struggling simulates Rachel's
// onboarding: Day 5, struggling emotionally, uses starter pack, edits items, commits.
func TestThreeCircles_E2E_Rachel_Day5_StarterPack_Struggling(t *testing.T) {
	// Given -- Rachel: Day 5 SA, feeling overwhelmed, emotional check-in score = 1
	flow := &threecircles.OnboardingFlow{
		FlowID:                "flow-rachel",
		UserID:                "user-rachel",
		TenantID:              "tenant-1",
		Mode:                  threecircles.ModeStarterPack, // Suggested due to low emotional score
		CurrentStep:           threecircles.StepEmotionalStep,
		EmotionalCheckinScore: 1, // Struggling
		StartedAt:             time.Now().UTC(),
		LastActivityAt:        time.Now().UTC(),
	}

	// When -- Rachel selects recovery area
	recoveryArea := threecircles.RecoveryAreaSexPornography
	flow.RecoveryArea = &recoveryArea

	// When -- Advance to starter pack step
	err := AdvanceOnboardingStep(flow, threecircles.StepStarterPack)
	if err != nil {
		t.Fatalf("expected no error advancing to starter pack, got %v", err)
	}

	// Then -- Starter pack mode recommended
	if flow.Mode != threecircles.ModeStarterPack {
		t.Errorf("expected starter pack mode for struggling user, got %s", flow.Mode)
	}

	// When -- Apply starter pack (secular variant)
	pack := threecircles.StarterPack{
		ID:           "pack-sa-secular",
		Name:         "SA Recovery Starter Pack",
		RecoveryArea: threecircles.RecoveryAreaSexPornography,
		Variant:      threecircles.VariantSecular,
		InnerCircle: []threecircles.StarterPackItem{
			{BehaviorName: "Viewing pornography", Category: "behavioral"},
			{BehaviorName: "Sexual activity outside marriage", Category: "behavioral"},
			{BehaviorName: "Fantasy and objectification", Category: "emotional"},
		},
		MiddleCircle: []threecircles.StarterPackItem{
			{BehaviorName: "Staying up late alone browsing internet", Category: "behavioral"},
			{BehaviorName: "Isolating from accountability partners", Category: "emotional"},
			{BehaviorName: "High-risk environments (bars, clubs)", Category: "environmental"},
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

	draftSet := threecircles.ApplyCircleSet{}
	result, err := threecircles.ApplyStarterPack(pack, draftSet, threecircles.ApplicationModeMerge)
	if err != nil {
		t.Fatalf("expected no error applying starter pack, got %v", err)
	}

	// Then -- Items tagged with source=starterPack
	if result.ItemsAdded != 9 {
		t.Errorf("expected 9 items added, got %d", result.ItemsAdded)
	}
	for _, item := range result.InnerCircle {
		if item.Source != threecircles.SourceStarterPack {
			t.Errorf("expected inner item to have source=starterPack, got %s", item.Source)
		}
	}

	// When -- Rachel edits 2 items for specificity
	result.InnerCircle[0].BehaviorName = "Viewing pornography alone at night"
	result.InnerCircle[0].SpecificityDetail = "Specifically late at night when I'm tired"
	result.InnerCircle[0].ModifiedAt = time.Now().UTC()

	result.MiddleCircle[0].BehaviorName = "Staying up past midnight alone browsing social media or streaming"
	result.MiddleCircle[0].SpecificityDetail = "Instagram and YouTube are triggers"
	result.MiddleCircle[0].ModifiedAt = time.Now().UTC()

	// Then -- Items updated
	if result.InnerCircle[0].SpecificityDetail == "" {
		t.Error("expected specificity detail to be added")
	}

	// When -- Rachel commits the set
	fullSet := &threecircles.CircleSet{
		ID:           "set-rachel",
		UserID:       "user-rachel",
		TenantID:     "tenant-1",
		Name:         "My SA Recovery Journey",
		RecoveryArea: threecircles.RecoveryAreaSexPornography,
		Status:       threecircles.StatusDraft,
		InnerCircle:  result.InnerCircle,
		MiddleCircle: result.MiddleCircle,
		OuterCircle:  result.OuterCircle,
		CreatedAt:    time.Now().UTC(),
		ModifiedAt:   time.Now().UTC(),
	}

	err = CommitSet(fullSet, "Initial commitment with starter pack")
	if err != nil {
		t.Fatalf("expected no error committing set, got %v", err)
	}

	// Then -- Set committed and active
	if fullSet.Status != threecircles.StatusActive {
		t.Errorf("expected status to be active, got %s", fullSet.Status)
	}
	if fullSet.CurrentVersion != 1 {
		t.Errorf("expected version 1, got %d", fullSet.CurrentVersion)
	}

	// Verify inner circle has at least 1 item
	if len(fullSet.InnerCircle) == 0 {
		t.Error("expected inner circle to have at least 1 item")
	}

	// Verify all items have source
	for _, item := range fullSet.InnerCircle {
		if item.Source == "" {
			t.Error("expected all items to have source")
		}
	}
}

// TestThreeCircles_E2E_James_2yrSAA_Express_Good simulates James's onboarding:
// 2 years SAA, express mode, good emotional state, skips framework, commits immediately.
func TestThreeCircles_E2E_James_2yrSAA_Express_Good(t *testing.T) {
	// Given -- James: 2 years in SAA, emotionally healthy, express mode
	flow := &threecircles.OnboardingFlow{
		FlowID:                "flow-james",
		UserID:                "user-james",
		TenantID:              "tenant-1",
		Mode:                  threecircles.ModeExpress,
		CurrentStep:           threecircles.StepRecoveryArea,
		EmotionalCheckinScore: 5, // Doing well
		StartedAt:             time.Now().UTC(),
		LastActivityAt:        time.Now().UTC(),
	}

	// When -- James selects recovery area (SAA)
	recoveryArea := threecircles.RecoveryAreaSexPornography
	flow.RecoveryArea = &recoveryArea

	// When -- James skips framework preference (express mode allows this)
	err := AdvanceOnboardingStep(flow, threecircles.StepInnerCircle)
	if err != nil {
		t.Fatalf("expected no error advancing to inner circle, got %v", err)
	}

	// When -- James adds items directly (express mode)
	set := &threecircles.CircleSet{
		ID:           "set-james",
		UserID:       "user-james",
		TenantID:     "tenant-1",
		Name:         "James's Three Circles",
		RecoveryArea: threecircles.RecoveryAreaSexPornography,
		Status:       threecircles.StatusDraft,
		CreatedAt:    time.Now().UTC(),
		ModifiedAt:   time.Now().UTC(),
	}

	// Add inner circle items (James knows his bottom lines)
	innerItems := []threecircles.CircleItem{
		{
			ItemID:       "james-inner-1",
			BehaviorName: "Viewing pornography or engaging in masturbation",
			Source:       threecircles.SourceUser,
			CreatedAt:    time.Now().UTC(),
			ModifiedAt:   time.Now().UTC(),
		},
		{
			ItemID:       "james-inner-2",
			BehaviorName: "Engaging in anonymous sexual encounters",
			Source:       threecircles.SourceUser,
			CreatedAt:    time.Now().UTC(),
			ModifiedAt:   time.Now().UTC(),
		},
	}

	// Add middle circle items
	middleItems := []threecircles.CircleItem{
		{
			ItemID:       "james-middle-1",
			BehaviorName: "Using dating apps without accountability check-in",
			Category:     "behavioral",
			Source:       threecircles.SourceUser,
			CreatedAt:    time.Now().UTC(),
			ModifiedAt:   time.Now().UTC(),
		},
		{
			ItemID:       "james-middle-2",
			BehaviorName: "Isolating when feeling lonely instead of calling sponsor",
			Category:     "emotional",
			Source:       threecircles.SourceUser,
			CreatedAt:    time.Now().UTC(),
			ModifiedAt:   time.Now().UTC(),
		},
		{
			ItemID:       "james-middle-3",
			BehaviorName: "Staying up past 1am browsing internet",
			Category:     "behavioral",
			Source:       threecircles.SourceUser,
			CreatedAt:    time.Now().UTC(),
			ModifiedAt:   time.Now().UTC(),
		},
	}

	// Add outer circle items
	outerItems := []threecircles.CircleItem{
		{
			ItemID:       "james-outer-1",
			BehaviorName: "Daily morning meditation and prayer",
			Category:     "spiritual",
			Source:       threecircles.SourceUser,
			CreatedAt:    time.Now().UTC(),
			ModifiedAt:   time.Now().UTC(),
		},
		{
			ItemID:       "james-outer-2",
			BehaviorName: "Weekly SAA meeting attendance",
			Category:     "social",
			Source:       threecircles.SourceUser,
			CreatedAt:    time.Now().UTC(),
			ModifiedAt:   time.Now().UTC(),
		},
		{
			ItemID:       "james-outer-3",
			BehaviorName: "Three sponsor check-ins per week",
			Category:     "social",
			Source:       threecircles.SourceUser,
			CreatedAt:    time.Now().UTC(),
			ModifiedAt:   time.Now().UTC(),
		},
	}

	set.InnerCircle = innerItems
	set.MiddleCircle = middleItems
	set.OuterCircle = outerItems

	// When -- James commits immediately
	err = CommitSet(set, "Express mode - ready to commit")
	if err != nil {
		t.Fatalf("expected no error committing set, got %v", err)
	}

	// Then -- Set committed
	if set.Status != threecircles.StatusActive {
		t.Errorf("expected status to be active, got %s", set.Status)
	}
	if set.CurrentVersion != 1 {
		t.Errorf("expected version 1, got %d", set.CurrentVersion)
	}

	// When -- James generates sponsor share
	share, err := GenerateSponsorShare(set, "")
	if err != nil {
		t.Fatalf("expected no error generating sponsor share, got %v", err)
	}

	// Then -- Share created
	if share == nil {
		t.Fatal("expected sponsor share to be created")
	}
	if share.SetID != set.ID {
		t.Errorf("expected share to reference set ID, got %s", share.SetID)
	}

	// When -- James adds comment to share
	err = AddShareComment(share, "Feeling good about my progress. Would love your feedback on middle circle items.")
	if err != nil {
		t.Fatalf("expected no error adding comment, got %v", err)
	}

	// Then -- Comment added
	if share.Comment != "Feeling good about my progress. Would love your feedback on middle circle items." {
		t.Error("expected comment to be added to share")
	}

	// Complete onboarding
	err = CompleteOnboarding(flow)
	if err != nil {
		t.Fatalf("expected no error completing onboarding, got %v", err)
	}

	if !flow.IsCompleted() {
		t.Error("expected onboarding to be completed")
	}
}

// TestThreeCircles_E2E_Maria_6moSLAA_Guided_MultiSet simulates Maria's onboarding:
// 6 months SLAA + codependency, guided mode, creates 2 circle sets, generates patterns.
func TestThreeCircles_E2E_Maria_6moSLAA_Guided_MultiSet(t *testing.T) {
	// Given -- Maria: 6 months SLAA + codependency, guided mode
	flow1 := &threecircles.OnboardingFlow{
		FlowID:                "flow-maria-slaa",
		UserID:                "user-maria",
		TenantID:              "tenant-1",
		Mode:                  threecircles.ModeGuided,
		CurrentStep:           threecircles.StepRecoveryArea,
		EmotionalCheckinScore: 3, // Moderate
		StartedAt:             time.Now().UTC(),
		LastActivityAt:        time.Now().UTC(),
	}

	// When -- Maria creates first set (SLAA)
	recoveryAreaSLAA := threecircles.RecoveryAreaLoveRelationships
	flow1.RecoveryArea = &recoveryAreaSLAA
	frameworkLiberation := threecircles.FrameworkSLAA
	flow1.FrameworkPreference = &frameworkLiberation

	// Advance through guided steps
	err := AdvanceOnboardingStep(flow1, threecircles.StepFramework)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	err = AdvanceOnboardingStep(flow1, threecircles.StepInnerCircle)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	// Create SLAA set
	setSLAA := &threecircles.CircleSet{
		ID:                  "set-maria-slaa",
		UserID:              "user-maria",
		TenantID:            "tenant-1",
		Name:                "Maria's SLAA Recovery",
		RecoveryArea:        threecircles.RecoveryAreaLoveRelationships,
		FrameworkPreference: &frameworkLiberation,
		Status:              threecircles.StatusDraft,
		InnerCircle: []threecircles.CircleItem{
			{
				ItemID:       "maria-slaa-inner-1",
				BehaviorName: "Seeking validation through romantic or sexual attention from unavailable partners",
				Source:       threecircles.SourceUser,
				CreatedAt:    time.Now().UTC(),
				ModifiedAt:   time.Now().UTC(),
			},
		},
		MiddleCircle: []threecircles.CircleItem{
			{
				ItemID:       "maria-slaa-middle-1",
				BehaviorName: "Excessive texting or checking phone for responses",
				Category:     "behavioral",
				Source:       threecircles.SourceUser,
				CreatedAt:    time.Now().UTC(),
				ModifiedAt:   time.Now().UTC(),
			},
			{
				ItemID:       "maria-slaa-middle-2",
				BehaviorName: "Fantasy about unavailable partners",
				Category:     "emotional",
				Source:       threecircles.SourceUser,
				CreatedAt:    time.Now().UTC(),
				ModifiedAt:   time.Now().UTC(),
			},
			{
				ItemID:       "maria-slaa-middle-3",
				BehaviorName: "Isolating when feeling rejected",
				Category:     "emotional",
				Source:       threecircles.SourceUser,
				CreatedAt:    time.Now().UTC(),
				ModifiedAt:   time.Now().UTC(),
			},
		},
		OuterCircle: []threecircles.CircleItem{
			{
				ItemID:       "maria-slaa-outer-1",
				BehaviorName: "Daily SLAA meditation and prayer",
				Category:     "spiritual",
				Source:       threecircles.SourceUser,
				CreatedAt:    time.Now().UTC(),
				ModifiedAt:   time.Now().UTC(),
			},
		},
		CreatedAt:  time.Now().UTC(),
		ModifiedAt: time.Now().UTC(),
	}

	// Commit SLAA set
	err = CommitSet(setSLAA, "SLAA recovery commitment")
	if err != nil {
		t.Fatalf("expected no error committing SLAA set, got %v", err)
	}

	// Complete first onboarding
	err = CompleteOnboarding(flow1)
	if err != nil {
		t.Fatalf("expected no error completing onboarding, got %v", err)
	}

	// When -- Maria creates second set (codependency)
	flow2 := &threecircles.OnboardingFlow{
		FlowID:                "flow-maria-codep",
		UserID:                "user-maria",
		TenantID:              "tenant-1",
		Mode:                  threecircles.ModeGuided,
		CurrentStep:           threecircles.StepRecoveryArea,
		EmotionalCheckinScore: 3,
		StartedAt:             time.Now().UTC(),
		LastActivityAt:        time.Now().UTC(),
	}

	recoveryAreaCodependency := threecircles.RecoveryAreaOther
	flow2.RecoveryArea = &recoveryAreaCodependency
	flow2.FrameworkPreference = &frameworkLiberation

	setCodepend := &threecircles.CircleSet{
		ID:                  "set-maria-codep",
		UserID:              "user-maria",
		TenantID:            "tenant-1",
		Name:                "Maria's Codependency Recovery",
		RecoveryArea:        threecircles.RecoveryAreaOther,
		FrameworkPreference: &frameworkLiberation,
		Status:              threecircles.StatusDraft,
		InnerCircle: []threecircles.CircleItem{
			{
				ItemID:       "maria-codep-inner-1",
				BehaviorName: "Saying yes to requests that compromise my boundaries",
				Source:       threecircles.SourceUser,
				CreatedAt:    time.Now().UTC(),
				ModifiedAt:   time.Now().UTC(),
			},
		},
		MiddleCircle: []threecircles.CircleItem{
			{
				ItemID:       "maria-codep-middle-1",
				BehaviorName: "Over-explaining or justifying my decisions",
				Category:     "behavioral",
				Source:       threecircles.SourceUser,
				CreatedAt:    time.Now().UTC(),
				ModifiedAt:   time.Now().UTC(),
			},
			{
				ItemID:       "maria-codep-middle-2",
				BehaviorName: "Seeking approval before making personal choices",
				Category:     "emotional",
				Source:       threecircles.SourceUser,
				CreatedAt:    time.Now().UTC(),
				ModifiedAt:   time.Now().UTC(),
			},
			{
				ItemID:       "maria-codep-middle-3",
				BehaviorName: "Taking on others' emotional burdens",
				Category:     "emotional",
				Source:       threecircles.SourceUser,
				CreatedAt:    time.Now().UTC(),
				ModifiedAt:   time.Now().UTC(),
			},
		},
		OuterCircle: []threecircles.CircleItem{
			{
				ItemID:       "maria-codep-outer-1",
				BehaviorName: "Healthy boundaries practice with therapist",
				Category:     "social",
				Source:       threecircles.SourceUser,
				CreatedAt:    time.Now().UTC(),
				ModifiedAt:   time.Now().UTC(),
			},
		},
		CreatedAt:  time.Now().UTC(),
		ModifiedAt: time.Now().UTC(),
	}

	// Commit codependency set
	err = CommitSet(setCodepend, "Codependency recovery commitment")
	if err != nil {
		t.Fatalf("expected no error committing codependency set, got %v", err)
	}

	// Then -- Both sets committed and independent
	if setSLAA.ID == setCodepend.ID {
		t.Error("expected sets to have different IDs")
	}
	if setSLAA.RecoveryArea == setCodepend.RecoveryArea {
		t.Error("expected sets to have different recovery areas")
	}

	// When -- Generate pattern data for 30 days (SLAA set)
	entries := make([]threecircles.TimelineEntry, 30)
	baseDate := time.Date(2026, 3, 10, 0, 0, 0, 0, time.UTC)

	for i := 0; i < 30; i++ {
		date := baseDate.AddDate(0, 0, i)
		dominant := threecircles.CircleOuter
		if i%5 == 0 { // Every 5th day: middle circle
			dominant = threecircles.CircleMiddle
		}

		entries[i] = threecircles.TimelineEntry{
			Date:           date.Format("2006-01-02"),
			SetID:          setSLAA.ID,
			DominantCircle: dominant,
			InnerContact:   false,
			MiddleContact:  dominant == threecircles.CircleMiddle,
			OuterContact:   dominant == threecircles.CircleOuter,
			MoodScore:      7,
		}
	}

	// When -- Build timeline summary
	summary, err := BuildTimelineSummary(entries, threecircles.Period30D, time.Date(2026, 4, 8, 0, 0, 0, 0, time.UTC))
	if err != nil {
		t.Fatalf("expected no error building summary, got %v", err)
	}

	// Then -- Summary populated
	if summary.Period != "30d" {
		t.Errorf("expected period 30d, got %s", summary.Period)
	}

	// When -- Generate insights
	insights := GenerateInsights(entries, time.Date(2026, 4, 8, 0, 0, 0, 0, time.UTC))

	// Then -- Insights generated
	if len(insights) == 0 {
		t.Error("expected at least one insight to be generated")
	}

	// Verify all insights use trauma-informed language
	for _, insight := range insights {
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

// TestThreeCircles_E2E_VersionRestore_CreatesNewVersion verifies that version
// restore creates a NEW version, not a rewind.
func TestThreeCircles_E2E_VersionRestore_CreatesNewVersion(t *testing.T) {
	// Given -- Circle set at version 3
	set := &threecircles.CircleSet{
		ID:             "set-1",
		UserID:         "user-1",
		TenantID:       "tenant-1",
		Name:           "My Recovery",
		RecoveryArea:   threecircles.RecoveryAreaSexPornography,
		Status:         threecircles.StatusActive,
		CurrentVersion: 3,
		InnerCircle: []threecircles.CircleItem{
			{ItemID: "item-1", BehaviorName: "Behavior A"},
			{ItemID: "item-2", BehaviorName: "Behavior B"},
		},
		CreatedAt:  time.Now().UTC(),
		ModifiedAt: time.Now().UTC(),
	}
	committedAt := time.Now().UTC()
	set.CommittedAt = &committedAt

	// When -- Create snapshot of version 2 (earlier version)
	v2Set := &threecircles.CircleSet{
		ID:             set.ID,
		UserID:         set.UserID,
		TenantID:       set.TenantID,
		Name:           set.Name,
		RecoveryArea:   set.RecoveryArea,
		Status:         threecircles.StatusActive,
		CurrentVersion: 2,
		InnerCircle: []threecircles.CircleItem{
			{ItemID: "item-1", BehaviorName: "Behavior A"},
		},
		CreatedAt:   set.CreatedAt,
		ModifiedAt:  set.ModifiedAt,
		CommittedAt: set.CommittedAt,
	}
	snapshot := CreateSnapshot(v2Set, "Version 2 snapshot", threecircles.ChangeItemAdded, []string{"item-1"})

	// When -- Restore from version 2 snapshot
	restored, err := RestoreFromSnapshot(snapshot, "Restored version 2")
	if err != nil {
		t.Fatalf("expected no error restoring, got %v", err)
	}

	// Then -- NEW version created (version 4, not rewind to 2)
	if restored.CurrentVersion != 4 {
		t.Errorf("expected version 4 (new version), got %d", restored.CurrentVersion)
	}
	if len(restored.InnerCircle) != 1 {
		t.Errorf("expected 1 inner circle item from v2 restore, got %d", len(restored.InnerCircle))
	}

	// Verify original set unchanged
	if set.CurrentVersion != 3 {
		t.Error("expected original set version to remain unchanged")
	}
}

// TestThreeCircles_E2E_AllMessagesTraumaInformed verifies that ALL system
// messages (guardrails, drift, insights, summaries) pass trauma-informed language check.
func TestThreeCircles_E2E_AllMessagesTraumaInformed(t *testing.T) {
	// Collect all system-generated messages
	messages := []struct {
		name    string
		message string
	}{
		{"Specificity nudge", threecircles.CheckSpecificity("stop").Message},
		{"Inner overload soft", threecircles.CheckInnerCircleOverload(9).Message},
		{"Middle depth", threecircles.CheckMiddleCircleDepth(2).Message},
		{"Isolation check", threecircles.CheckIsolation(false).Message},
		{"Inner add", threecircles.CheckInnerCircleAddition().Message},
		{"Inner remove", threecircles.CheckInnerCircleRemoval().Message},
	}

	// Build drift alert
	driftEntries := []threecircles.TimelineEntry{
		{Date: "2026-04-06", DominantCircle: threecircles.CircleMiddle, MiddleContact: true},
		{Date: "2026-04-07", DominantCircle: threecircles.CircleMiddle, MiddleContact: true},
		{Date: "2026-04-08", DominantCircle: threecircles.CircleMiddle, MiddleContact: true},
	}
	driftAlert := DetectDrift(driftEntries, "user-1", "set-1", 7)
	if driftAlert != nil {
		messages = append(messages, struct {
			name    string
			message string
		}{"Drift alert", driftAlert.Message})
	}

	// Build summary
	timelineEntries := []threecircles.TimelineEntry{
		{Date: "2026-04-01", DominantCircle: threecircles.CircleOuter},
		{Date: "2026-04-02", DominantCircle: threecircles.CircleOuter},
		{Date: "2026-04-03", DominantCircle: threecircles.CircleOuter},
		{Date: "2026-04-04", DominantCircle: threecircles.CircleOuter},
		{Date: "2026-04-05", DominantCircle: threecircles.CircleOuter},
		{Date: "2026-04-06", DominantCircle: threecircles.CircleOuter},
		{Date: "2026-04-07", DominantCircle: threecircles.CircleOuter},
	}
	summary, err := BuildTimelineSummary(timelineEntries, threecircles.Period7D, time.Date(2026, 4, 8, 0, 0, 0, 0, time.UTC))
	if err != nil {
		t.Fatalf("expected no error building summary, got %v", err)
	}
	messages = append(messages, struct {
		name    string
		message string
	}{"Summary framing", summary.FramingMessage})

	// Validate all messages
	for _, msg := range messages {
		t.Run(msg.name, func(t *testing.T) {
			if msg.message == "" {
				t.Skip("message empty, skipping")
			}

			// Verify trauma-informed language
			err := threecircles.ValidateTraumaInformedLanguage(msg.message)
			if err != nil {
				t.Errorf("message violates trauma-informed language: %q - %v", msg.message, err)
			}

			// Verify no "streak" language
			if ContainsWord(msg.message, "streak") {
				t.Errorf("message must not contain 'streak': %s", msg.message)
			}

			// Verify no punitive language
			punitiveForbidden := []string{"failure", "failed", "weak", "should", "must"}
			for _, word := range punitiveForbidden {
				if ContainsWord(msg.message, word) {
					t.Errorf("message contains punitive word %q: %s", word, msg.message)
				}
			}
		})
	}
}

// =============================================================================
// Test Helpers
// =============================================================================

// Helper functions use shared helpers from test/helpers/common.go
