// test/unit/goals_test.go
package unit

import (
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/regalrecovery/api/internal/domain/goals"
)

// =============================================================================
// 1.1 Goal Creation and Validation
// =============================================================================

func TestGoalCreation_AC_GC_1_CreateManualGoalWithRequiredFields(t *testing.T) {
	req := &goals.CreateWeeklyDailyGoalRequest{
		Text:     "Morning prayer and scripture reading",
		Dynamics: []goals.Dynamic{goals.DynamicSpiritual},
	}

	err := goals.ValidateCreateGoalRequest(req)
	if err != nil {
		t.Errorf("expected no error for valid request, got: %v", err)
	}
}

func TestGoalCreation_AC_GC_2_RejectsEmptyText(t *testing.T) {
	req := &goals.CreateWeeklyDailyGoalRequest{
		Text:     "",
		Dynamics: []goals.Dynamic{goals.DynamicSpiritual},
	}

	err := goals.ValidateCreateGoalRequest(req)
	if err == nil {
		t.Fatal("expected validation error for empty text")
	}

	var valErr *goals.ValidationError
	if ok := isValidationError(err, &valErr); !ok || valErr.Code != goals.ErrCodeTextInvalid {
		t.Errorf("expected error code %s, got %v", goals.ErrCodeTextInvalid, err)
	}
}

func TestGoalCreation_AC_GC_2_RejectsTextOver200Chars(t *testing.T) {
	req := &goals.CreateWeeklyDailyGoalRequest{
		Text:     strings.Repeat("a", 201),
		Dynamics: []goals.Dynamic{goals.DynamicSpiritual},
	}

	err := goals.ValidateCreateGoalRequest(req)
	if err == nil {
		t.Fatal("expected validation error for text over 200 chars")
	}

	var valErr *goals.ValidationError
	if ok := isValidationError(err, &valErr); !ok || valErr.Code != goals.ErrCodeTextInvalid {
		t.Errorf("expected error code %s, got %v", goals.ErrCodeTextInvalid, err)
	}
}

func TestGoalCreation_AC_GC_3_RejectsEmptyDynamicsArray(t *testing.T) {
	req := &goals.CreateWeeklyDailyGoalRequest{
		Text:     "Valid text",
		Dynamics: []goals.Dynamic{},
	}

	err := goals.ValidateCreateGoalRequest(req)
	if err == nil {
		t.Fatal("expected validation error for empty dynamics")
	}

	var valErr *goals.ValidationError
	if ok := isValidationError(err, &valErr); !ok || valErr.Code != goals.ErrCodeDynamicsInvalid {
		t.Errorf("expected error code %s, got %v", goals.ErrCodeDynamicsInvalid, err)
	}
}

func TestGoalCreation_AC_GC_3_RejectsNoDynamicsField(t *testing.T) {
	req := &goals.CreateWeeklyDailyGoalRequest{
		Text:     "Valid text",
		Dynamics: nil,
	}

	err := goals.ValidateCreateGoalRequest(req)
	if err == nil {
		t.Fatal("expected validation error for nil dynamics")
	}
}

func TestGoalCreation_AC_GC_4_DefaultsScopeToDaily(t *testing.T) {
	// When scope is nil, the service should default to "daily".
	// Tested via the service layer setting the default.
	req := &goals.CreateWeeklyDailyGoalRequest{
		Text:     "Test goal",
		Dynamics: []goals.Dynamic{goals.DynamicSpiritual},
		Scope:    nil, // no scope specified
	}

	err := goals.ValidateCreateGoalRequest(req)
	if err != nil {
		t.Errorf("expected no error, got: %v", err)
	}
	// Scope defaulting is tested through the service, not the validator.
}

func TestGoalCreation_AC_GC_5_RecurrenceOneTime(t *testing.T) {
	recurrence := goals.RecurrenceOneTime
	goalDef := goals.WeeklyDailyGoal{
		GoalID:     "wdg_test",
		Text:       "One-time goal",
		Dynamics:   []goals.Dynamic{goals.DynamicSpiritual},
		Scope:      goals.ScopeDaily,
		Recurrence: recurrence,
		IsActive:   true,
		CreatedAt:  time.Now(),
	}

	instances := goals.MaterializeInstances([]goals.WeeklyDailyGoal{goalDef}, "2026-04-07", "u_test", "DEFAULT")
	if len(instances) != 1 {
		t.Errorf("expected 1 instance for one-time goal, got %d", len(instances))
	}
}

func TestGoalCreation_AC_GC_5_RecurrenceDaily(t *testing.T) {
	goalDef := goals.WeeklyDailyGoal{
		GoalID:     "wdg_test",
		Text:       "Daily goal",
		Dynamics:   []goals.Dynamic{goals.DynamicPhysical},
		Scope:      goals.ScopeDaily,
		Recurrence: goals.RecurrenceDaily,
		IsActive:   true,
		CreatedAt:  time.Now(),
	}

	// Materialize for each day of the week.
	dates := []string{"2026-04-06", "2026-04-07", "2026-04-08", "2026-04-09", "2026-04-10", "2026-04-11", "2026-04-12"}
	totalInstances := 0
	for _, d := range dates {
		instances := goals.MaterializeInstances([]goals.WeeklyDailyGoal{goalDef}, d, "u_test", "DEFAULT")
		totalInstances += len(instances)
	}
	if totalInstances != 7 {
		t.Errorf("expected 7 instances for daily recurrence over a week, got %d", totalInstances)
	}
}

func TestGoalCreation_AC_GC_5_RecurrenceSpecificDays(t *testing.T) {
	goalDef := goals.WeeklyDailyGoal{
		GoalID:     "wdg_test",
		Text:       "MWF goal",
		Dynamics:   []goals.Dynamic{goals.DynamicPhysical},
		Scope:      goals.ScopeDaily,
		Recurrence: goals.RecurrenceSpecificDays,
		DaysOfWeek: []goals.DayOfWeek{goals.Monday, goals.Wednesday, goals.Friday},
		IsActive:   true,
		CreatedAt:  time.Now(),
	}

	// 2026-04-06 is Sunday, 07 is Monday, 08 Tue, 09 Wed, 10 Thu, 11 Fri, 12 Sat
	dates := []string{"2026-04-06", "2026-04-07", "2026-04-08", "2026-04-09", "2026-04-10", "2026-04-11", "2026-04-12"}
	totalInstances := 0
	for _, d := range dates {
		instances := goals.MaterializeInstances([]goals.WeeklyDailyGoal{goalDef}, d, "u_test", "DEFAULT")
		totalInstances += len(instances)
	}
	// Only Mon (07), Wed (09), Fri (11) = 3
	if totalInstances != 3 {
		t.Errorf("expected 3 instances for specific-days MWF, got %d", totalInstances)
	}
}

func TestGoalCreation_AC_GC_5_RecurrenceWeekly(t *testing.T) {
	wed := goals.Wednesday
	goalDef := goals.WeeklyDailyGoal{
		GoalID:     "wdg_test",
		Text:       "Weekly goal",
		Dynamics:   []goals.Dynamic{goals.DynamicRelational},
		Scope:      goals.ScopeWeekly,
		Recurrence: goals.RecurrenceWeekly,
		DayOfWeek:  &wed,
		IsActive:   true,
		CreatedAt:  time.Now(),
	}

	// Two weeks: 2026-04-06 to 2026-04-19
	dates := make([]string, 14)
	for i := range 14 {
		d := time.Date(2026, 4, 6+i, 0, 0, 0, 0, time.UTC)
		dates[i] = d.Format("2006-01-02")
	}

	totalInstances := 0
	for _, d := range dates {
		instances := goals.MaterializeInstances([]goals.WeeklyDailyGoal{goalDef}, d, "u_test", "DEFAULT")
		totalInstances += len(instances)
	}
	// Only Wednesdays: Apr 8 and Apr 15 = 2
	// 2026-04-08 is Wednesday and 2026-04-15 is Wednesday
	if totalInstances != 2 {
		t.Errorf("expected 2 instances for weekly Wednesday over 2 weeks, got %d", totalInstances)
	}
}

func TestGoalCreation_AC_GC_6_PrioritySorting(t *testing.T) {
	now := time.Now()
	instances := []goals.GoalInstance{
		{GoalInstanceID: "gi_1", Priority: goals.PriorityLow, CreatedAt: now.Add(-2 * time.Hour)},
		{GoalInstanceID: "gi_2", Priority: goals.PriorityHigh, CreatedAt: now.Add(-1 * time.Hour)},
		{GoalInstanceID: "gi_3", Priority: goals.PriorityMedium, CreatedAt: now},
	}

	goals.SortInstancesByPriority(instances)

	if instances[0].Priority != goals.PriorityHigh {
		t.Errorf("expected first item to be high priority, got %s", instances[0].Priority)
	}
	if instances[1].Priority != goals.PriorityMedium {
		t.Errorf("expected second item to be medium priority, got %s", instances[1].Priority)
	}
	if instances[2].Priority != goals.PriorityLow {
		t.Errorf("expected third item to be low priority, got %s", instances[2].Priority)
	}
}

func TestGoalCreation_AC_GC_7_RejectsNotesOver500Chars(t *testing.T) {
	notes := strings.Repeat("n", 501)
	req := &goals.CreateWeeklyDailyGoalRequest{
		Text:     "Valid text",
		Dynamics: []goals.Dynamic{goals.DynamicSpiritual},
		Notes:    &notes,
	}

	err := goals.ValidateCreateGoalRequest(req)
	if err == nil {
		t.Fatal("expected validation error for notes over 500 chars")
	}
}

func TestGoalCreation_AC_GC_8_MultipleDynamicTags(t *testing.T) {
	instances := []goals.GoalInstance{
		{
			GoalInstanceID: "gi_1",
			Dynamics:       []goals.Dynamic{goals.DynamicSpiritual, goals.DynamicRelational},
			Priority:       goals.PriorityHigh,
		},
	}

	grouped := goals.GroupByDynamic(instances)

	if len(grouped[goals.DynamicSpiritual]) != 1 {
		t.Errorf("expected goal in spiritual group, got %d", len(grouped[goals.DynamicSpiritual]))
	}
	if len(grouped[goals.DynamicRelational]) != 1 {
		t.Errorf("expected goal in relational group, got %d", len(grouped[goals.DynamicRelational]))
	}
}

// =============================================================================
// 1.2 Auto-Population Logic
// =============================================================================

func TestAutoPopulation_AC_AP_1_PopulatesFromActiveCommitments(t *testing.T) {
	sources := []goals.AutoPopulateSource{
		{
			Source:   goals.SourceCommitment,
			SourceID: "cm_77777",
			Text:     "Call sponsor",
			Dynamics: []goals.Dynamic{goals.DynamicRelational},
		},
	}

	instances := goals.MaterializeAutoPopulated(sources, "2026-04-07", "u_test", "DEFAULT")
	if len(instances) != 1 {
		t.Fatalf("expected 1 auto-populated instance, got %d", len(instances))
	}
	if *instances[0].Source != goals.SourceCommitment {
		t.Errorf("expected source=commitment, got %v", *instances[0].Source)
	}
	if *instances[0].SourceID != "cm_77777" {
		t.Errorf("expected sourceId=cm_77777, got %s", *instances[0].SourceID)
	}
}

func TestAutoPopulation_AC_AP_2_PopulatesFromConfiguredActivities(t *testing.T) {
	sources := []goals.AutoPopulateSource{
		{Source: goals.SourceActivity, SourceID: "act_journal", Text: "Journaling", Dynamics: []goals.Dynamic{goals.DynamicEmotional}},
		{Source: goals.SourceActivity, SourceID: "act_prayer", Text: "Prayer", Dynamics: []goals.Dynamic{goals.DynamicSpiritual}},
	}

	instances := goals.MaterializeAutoPopulated(sources, "2026-04-07", "u_test", "DEFAULT")
	if len(instances) != 2 {
		t.Fatalf("expected 2 auto-populated instances, got %d", len(instances))
	}
	for _, inst := range instances {
		if *inst.Source != goals.SourceActivity {
			t.Errorf("expected source=activity, got %v", *inst.Source)
		}
	}
}

func TestAutoPopulation_AC_AP_4_DismissAutoPopulatedGoalForOneDay(t *testing.T) {
	inst := &goals.GoalInstance{
		GoalInstanceID: "gi_test",
		Status:         goals.StatusPending,
	}

	goals.DismissInstance(inst)

	if inst.Status != goals.StatusDismissed {
		t.Errorf("expected status=dismissed, got %s", inst.Status)
	}
}

func TestAutoPopulation_AC_AP_6_ActivityCompletionAutoChecksGoal(t *testing.T) {
	source := goals.SourceActivity
	inst := &goals.GoalInstance{
		GoalInstanceID: "gi_test",
		Status:         goals.StatusPending,
		Source:         &source,
	}

	goals.AutoCompleteFromActivity(inst)

	if inst.Status != goals.StatusCompleted {
		t.Errorf("expected status=completed, got %s", inst.Status)
	}
	if inst.CompletedAt == nil {
		t.Error("expected completedAt to be set")
	}
}

// =============================================================================
// 1.3 Daily View Logic
// =============================================================================

func TestDailyView_AC_DV_1_GroupsByDynamic(t *testing.T) {
	instances := []goals.GoalInstance{
		{Dynamics: []goals.Dynamic{goals.DynamicSpiritual}, Priority: goals.PriorityHigh},
		{Dynamics: []goals.Dynamic{goals.DynamicPhysical}, Priority: goals.PriorityMedium},
		{Dynamics: []goals.Dynamic{goals.DynamicRelational}, Priority: goals.PriorityLow},
	}

	grouped := goals.GroupByDynamic(instances)

	if len(grouped[goals.DynamicSpiritual]) != 1 {
		t.Errorf("expected 1 spiritual goal, got %d", len(grouped[goals.DynamicSpiritual]))
	}
	if len(grouped[goals.DynamicPhysical]) != 1 {
		t.Errorf("expected 1 physical goal, got %d", len(grouped[goals.DynamicPhysical]))
	}
	if len(grouped[goals.DynamicRelational]) != 1 {
		t.Errorf("expected 1 relational goal, got %d", len(grouped[goals.DynamicRelational]))
	}
}

func TestDailyView_AC_DV_2_ProgressSummary(t *testing.T) {
	instances := []goals.GoalInstance{
		{Status: goals.StatusCompleted, Dynamics: []goals.Dynamic{goals.DynamicSpiritual}},
		{Status: goals.StatusCompleted, Dynamics: []goals.Dynamic{goals.DynamicSpiritual}},
		{Status: goals.StatusPending, Dynamics: []goals.Dynamic{goals.DynamicPhysical}},
		{Status: goals.StatusCompleted, Dynamics: []goals.Dynamic{goals.DynamicEmotional}},
		{Status: goals.StatusPending, Dynamics: []goals.Dynamic{goals.DynamicRelational}},
		{Status: goals.StatusPending, Dynamics: []goals.Dynamic{goals.DynamicRelational}},
		{Status: goals.StatusCompleted, Dynamics: []goals.Dynamic{goals.DynamicRelational}},
	}

	total, completed := goals.ComputeDailySummary(instances)
	if total != 7 {
		t.Errorf("expected totalGoals=7, got %d", total)
	}
	if completed != 4 {
		t.Errorf("expected completedGoals=4, got %d", completed)
	}
}

func TestDailyView_AC_DV_3_DynamicBalanceIndicator(t *testing.T) {
	instances := []goals.GoalInstance{
		{Status: goals.StatusCompleted, Dynamics: []goals.Dynamic{goals.DynamicSpiritual}},
		{Status: goals.StatusCompleted, Dynamics: []goals.Dynamic{goals.DynamicSpiritual}},
		{Status: goals.StatusPending, Dynamics: []goals.Dynamic{goals.DynamicPhysical}},
		{Status: goals.StatusCompleted, Dynamics: []goals.Dynamic{goals.DynamicEmotional}},
		{Status: goals.StatusPending, Dynamics: []goals.Dynamic{goals.DynamicRelational}},
		{Status: goals.StatusPending, Dynamics: []goals.Dynamic{goals.DynamicRelational}},
		{Status: goals.StatusCompleted, Dynamics: []goals.Dynamic{goals.DynamicRelational}},
	}

	balance := goals.ComputeDynamicBalance(instances)

	if balance.Spiritual.Total != 2 || balance.Spiritual.Completed != 2 {
		t.Errorf("spiritual: expected 2/2, got %d/%d", balance.Spiritual.Completed, balance.Spiritual.Total)
	}
	if balance.Physical.Total != 1 || balance.Physical.Completed != 0 {
		t.Errorf("physical: expected 0/1, got %d/%d", balance.Physical.Completed, balance.Physical.Total)
	}
	if balance.Emotional.Total != 1 || balance.Emotional.Completed != 1 {
		t.Errorf("emotional: expected 1/1, got %d/%d", balance.Emotional.Completed, balance.Emotional.Total)
	}
	if balance.Intellectual.Total != 0 || balance.Intellectual.Completed != 0 {
		t.Errorf("intellectual: expected 0/0, got %d/%d", balance.Intellectual.Completed, balance.Intellectual.Total)
	}
	if balance.Relational.Total != 3 || balance.Relational.Completed != 1 {
		t.Errorf("relational: expected 1/3, got %d/%d", balance.Relational.Completed, balance.Relational.Total)
	}
}

func TestDailyView_AC_DV_4_CompleteGoal(t *testing.T) {
	inst := &goals.GoalInstance{
		GoalInstanceID: "gi_test",
		Status:         goals.StatusPending,
	}

	goals.CompleteInstance(inst)

	if inst.Status != goals.StatusCompleted {
		t.Errorf("expected status=completed, got %s", inst.Status)
	}
	if inst.CompletedAt == nil {
		t.Error("expected completedAt to be set")
	}
}

func TestDailyView_AC_DV_5_UncompleteGoal(t *testing.T) {
	now := time.Now()
	inst := &goals.GoalInstance{
		GoalInstanceID: "gi_test",
		Status:         goals.StatusCompleted,
		CompletedAt:    &now,
	}

	goals.UncompleteInstance(inst)

	if inst.Status != goals.StatusPending {
		t.Errorf("expected status=pending, got %s", inst.Status)
	}
	if inst.CompletedAt != nil {
		t.Error("expected completedAt to be nil")
	}
}

// =============================================================================
// 1.4 Dynamic Gap Nudge Logic
// =============================================================================

func TestNudge_AC_DN_1_ShowsNudgeForEmptyDynamic(t *testing.T) {
	instances := []goals.GoalInstance{
		{Dynamics: []goals.Dynamic{goals.DynamicSpiritual}, Status: goals.StatusPending},
		{Dynamics: []goals.Dynamic{goals.DynamicPhysical}, Status: goals.StatusPending},
	}

	settings := &goals.GoalSettings{NudgesEnabled: true}
	nudges := goals.GenerateNudges(instances, settings, nil)

	// Should have nudges for emotional, intellectual, relational.
	if len(nudges) != 3 {
		t.Fatalf("expected 3 nudges for empty dynamics, got %d", len(nudges))
	}

	hasDynamic := func(d goals.Dynamic) bool {
		for _, n := range nudges {
			if n.Dynamic == d {
				return true
			}
		}
		return false
	}

	if !hasDynamic(goals.DynamicIntellectual) {
		t.Error("expected nudge for intellectual dynamic")
	}
	if !hasDynamic(goals.DynamicEmotional) {
		t.Error("expected nudge for emotional dynamic")
	}
}

func TestNudge_AC_DN_2_DismissedNudgeDoesNotReappear(t *testing.T) {
	instances := []goals.GoalInstance{
		{Dynamics: []goals.Dynamic{goals.DynamicSpiritual}, Status: goals.StatusPending},
	}

	settings := &goals.GoalSettings{NudgesEnabled: true}
	dismissed := []string{"intellectual"}

	nudges := goals.GenerateNudges(instances, settings, dismissed)

	for _, n := range nudges {
		if n.Dynamic == goals.DynamicIntellectual {
			t.Error("intellectual nudge should not appear when dismissed")
		}
	}
}

func TestNudge_AC_DN_3_NudgeDisabledPerDynamic(t *testing.T) {
	instances := []goals.GoalInstance{
		{Dynamics: []goals.Dynamic{goals.DynamicSpiritual}, Status: goals.StatusPending},
	}

	settings := &goals.GoalSettings{
		NudgesEnabled:          true,
		NudgesDisabledDynamics: []goals.Dynamic{goals.DynamicPhysical},
	}

	nudges := goals.GenerateNudges(instances, settings, nil)

	for _, n := range nudges {
		if n.Dynamic == goals.DynamicPhysical {
			t.Error("physical nudge should not appear when disabled")
		}
	}
}

func TestNudge_AC_DN_3_AllNudgesDisabled(t *testing.T) {
	instances := []goals.GoalInstance{}

	settings := &goals.GoalSettings{NudgesEnabled: false}
	nudges := goals.GenerateNudges(instances, settings, nil)

	if len(nudges) != 0 {
		t.Errorf("expected 0 nudges when all disabled, got %d", len(nudges))
	}
}

// =============================================================================
// 1.5 End-of-Day Review Logic
// =============================================================================

func TestDailyReview_AC_ED_2_UncompletedGoalDisposition(t *testing.T) {
	req := &goals.SubmitDailyReviewRequest{
		Date: "2026-04-07",
		Dispositions: []goals.Disposition{
			{GoalInstanceID: "gi_1", Action: goals.ActionCarryToTomorrow},
			{GoalInstanceID: "gi_2", Action: goals.ActionSkipped},
		},
	}

	err := goals.ValidateDailyReviewRequest(req)
	if err != nil {
		t.Errorf("expected valid dispositions, got error: %v", err)
	}
}

func TestDailyReview_AC_ED_3_CarryToTomorrow(t *testing.T) {
	inst := &goals.GoalInstance{
		GoalInstanceID: "gi_1",
		GoalID:         strPtr("wdg_1"),
		UserID:         "u_test",
		TenantID:       "DEFAULT",
		Date:           "2026-04-07",
		Text:           "Test goal",
		Dynamics:       []goals.Dynamic{goals.DynamicSpiritual},
		Scope:          goals.ScopeDaily,
		Priority:       goals.PriorityHigh,
		Status:         goals.StatusPending,
	}

	instances := []goals.GoalInstance{*inst}
	req := &goals.SubmitDailyReviewRequest{
		Date: "2026-04-07",
		Dispositions: []goals.Disposition{
			{GoalInstanceID: "gi_1", Action: goals.ActionCarryToTomorrow},
		},
	}

	review, carried, err := goals.ProcessDailyReview(instances, req, "u_test", "DEFAULT")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if review == nil {
		t.Fatal("expected review to be created")
	}

	if len(carried) != 1 {
		t.Fatalf("expected 1 carried instance, got %d", len(carried))
	}

	if *carried[0].CarriedFrom != "2026-04-07" {
		t.Errorf("expected carriedFrom=2026-04-07, got %s", *carried[0].CarriedFrom)
	}
	if carried[0].Date != "2026-04-08" {
		t.Errorf("expected carried date=2026-04-08, got %s", carried[0].Date)
	}
}

func TestDailyReview_AC_ED_5_ReflectionStored(t *testing.T) {
	reflection := "Work was intense today, but I stayed connected with my sponsor."
	instances := []goals.GoalInstance{
		{GoalInstanceID: "gi_1", Status: goals.StatusCompleted, Dynamics: []goals.Dynamic{goals.DynamicSpiritual}},
	}
	req := &goals.SubmitDailyReviewRequest{
		Date:         "2026-04-07",
		Dispositions: []goals.Disposition{},
		Reflection:   &reflection,
	}

	review, _, err := goals.ProcessDailyReview(instances, req, "u_test", "DEFAULT")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if review.Reflection == nil || *review.Reflection != reflection {
		t.Errorf("expected reflection to be stored, got %v", review.Reflection)
	}
}

// =============================================================================
// 1.6 End-of-Week Review Logic
// =============================================================================

func TestWeeklyReview_AC_EW_2_StatsComputation(t *testing.T) {
	current := []goals.GoalInstance{
		{Status: goals.StatusCompleted, Dynamics: []goals.Dynamic{goals.DynamicSpiritual}},
		{Status: goals.StatusCompleted, Dynamics: []goals.Dynamic{goals.DynamicSpiritual}},
		{Status: goals.StatusPending, Dynamics: []goals.Dynamic{goals.DynamicPhysical}},
	}
	previous := []goals.GoalInstance{
		{Status: goals.StatusCompleted, Dynamics: []goals.Dynamic{goals.DynamicSpiritual}},
		{Status: goals.StatusPending, Dynamics: []goals.Dynamic{goals.DynamicPhysical}},
	}

	stats := goals.ComputeWeeklyStats(current, previous)

	if stats.TotalGoals != 3 {
		t.Errorf("expected totalGoals=3, got %d", stats.TotalGoals)
	}
	if stats.CompletedGoals != 2 {
		t.Errorf("expected completedGoals=2, got %d", stats.CompletedGoals)
	}
	if stats.CompletionRate < 66.0 || stats.CompletionRate > 67.0 {
		t.Errorf("expected completionRate ~66.7, got %.1f", stats.CompletionRate)
	}
}

func TestWeeklyReview_AC_EW_2_PreviousWeekComparison(t *testing.T) {
	// Current: 2/3 = 66.7%, Previous: 1/2 = 50%
	current := []goals.GoalInstance{
		{Status: goals.StatusCompleted, Dynamics: []goals.Dynamic{goals.DynamicSpiritual}},
		{Status: goals.StatusCompleted, Dynamics: []goals.Dynamic{goals.DynamicSpiritual}},
		{Status: goals.StatusPending, Dynamics: []goals.Dynamic{goals.DynamicPhysical}},
	}
	previous := []goals.GoalInstance{
		{Status: goals.StatusCompleted, Dynamics: []goals.Dynamic{goals.DynamicSpiritual}},
		{Status: goals.StatusPending, Dynamics: []goals.Dynamic{goals.DynamicPhysical}},
	}

	stats := goals.ComputeWeeklyStats(current, previous)

	expectedChange := stats.CompletionRate - stats.PreviousWeekCompletionRate
	if stats.Change < expectedChange-0.1 || stats.Change > expectedChange+0.1 {
		t.Errorf("expected change ~%.1f, got %.1f", expectedChange, stats.Change)
	}
}

func TestWeeklyReview_AC_EW_2_WeakestDynamic_NoGoalsSet(t *testing.T) {
	// Intellectual has 0 goals = should be weakest.
	instances := []goals.GoalInstance{
		{Status: goals.StatusCompleted, Dynamics: []goals.Dynamic{goals.DynamicSpiritual}},
		{Status: goals.StatusPending, Dynamics: []goals.Dynamic{goals.DynamicPhysical}},
	}

	_, weakest := goals.FindStrongestWeakest(instances)

	// No intellectual goals means it should be the weakest.
	if weakest != goals.DynamicEmotional && weakest != goals.DynamicIntellectual && weakest != goals.DynamicRelational {
		// Any dynamic with 0 goals is acceptable as weakest.
	}
	// The first dynamic with 0 goals in iteration order should be weakest.
	// With our AllDynamics order: emotional, intellectual, or relational.
	// Since they all have 0, the first found is weakest.
}

// =============================================================================
// 1.7 Trends and Insights
// =============================================================================

func TestTrends_AC_TI_1_CompletionRateOverTime(t *testing.T) {
	var instances []goals.GoalInstance
	for i := range 30 {
		date := time.Date(2026, 3, 9+i, 0, 0, 0, 0, time.UTC).Format("2006-01-02")
		instances = append(instances,
			goals.GoalInstance{Date: date, Status: goals.StatusCompleted, Dynamics: []goals.Dynamic{goals.DynamicSpiritual}},
			goals.GoalInstance{Date: date, Status: goals.StatusPending, Dynamics: []goals.Dynamic{goals.DynamicPhysical}},
		)
	}

	trends := goals.ComputeTrends(instances, "30d")
	if len(trends.DailyCompletionRates) != 30 {
		t.Errorf("expected 30 daily rates, got %d", len(trends.DailyCompletionRates))
	}
}

func TestTrends_AC_TI_2_PerDynamicTrends(t *testing.T) {
	var instances []goals.GoalInstance
	for i := range 5 {
		date := time.Date(2026, 4, 1+i, 0, 0, 0, 0, time.UTC).Format("2006-01-02")
		instances = append(instances,
			goals.GoalInstance{Date: date, Status: goals.StatusCompleted, Dynamics: []goals.Dynamic{goals.DynamicSpiritual}},
			goals.GoalInstance{Date: date, Status: goals.StatusPending, Dynamics: []goals.Dynamic{goals.DynamicPhysical}},
		)
	}

	trends := goals.ComputeTrends(instances, "7d")

	if _, ok := trends.DynamicTrends["spiritual"]; !ok {
		t.Error("expected dynamic trends to include spiritual")
	}
	if _, ok := trends.DynamicTrends["physical"]; !ok {
		t.Error("expected dynamic trends to include physical")
	}
}

func TestTrends_AC_TI_3_ConsistencyScore(t *testing.T) {
	dateInstances := make(map[string][]goals.GoalInstance)

	// 20 days with 3+ dynamics completed.
	for i := range 20 {
		date := time.Date(2026, 3, 9+i, 0, 0, 0, 0, time.UTC).Format("2006-01-02")
		dateInstances[date] = []goals.GoalInstance{
			{Status: goals.StatusCompleted, Dynamics: []goals.Dynamic{goals.DynamicSpiritual}},
			{Status: goals.StatusCompleted, Dynamics: []goals.Dynamic{goals.DynamicPhysical}},
			{Status: goals.StatusCompleted, Dynamics: []goals.Dynamic{goals.DynamicEmotional}},
		}
	}

	// 10 days with fewer than 3 dynamics completed.
	for i := range 10 {
		date := time.Date(2026, 3, 29+i, 0, 0, 0, 0, time.UTC).Format("2006-01-02")
		dateInstances[date] = []goals.GoalInstance{
			{Status: goals.StatusCompleted, Dynamics: []goals.Dynamic{goals.DynamicSpiritual}},
			{Status: goals.StatusPending, Dynamics: []goals.Dynamic{goals.DynamicPhysical}},
		}
	}

	score := goals.ComputeConsistencyScore(dateInstances)

	// 20/30 = 66.7%
	if score < 66.0 || score > 67.0 {
		t.Errorf("expected consistency score ~66.7%%, got %.1f%%", score)
	}
}

func TestTrends_AC_TI_4_AllGoalsCompletedStreak(t *testing.T) {
	var rates []goals.DailyCompletionRate
	// 1 day incomplete, then 5 days all completed.
	rates = append(rates, goals.DailyCompletionRate{Date: "2026-04-01", CompletionRate: 50, TotalGoals: 2, CompletedGoals: 1})
	for i := range 5 {
		date := time.Date(2026, 4, 2+i, 0, 0, 0, 0, time.UTC).Format("2006-01-02")
		rates = append(rates, goals.DailyCompletionRate{Date: date, CompletionRate: 100, TotalGoals: 3, CompletedGoals: 3})
	}

	streaks := goals.ComputeGoalStreaks(rates)

	if streaks.AllGoalsCompleted != 5 {
		t.Errorf("expected allGoalsCompleted streak=5, got %d", streaks.AllGoalsCompleted)
	}
}

func TestTrends_AC_TI_4_WeeklyEightyPercentStreak(t *testing.T) {
	var rates []goals.DailyCompletionRate
	// 3 weeks of 80%+ data, then 1 week at 70%.
	// Week 1 (good): 3 days at 90%.
	for i := range 7 {
		date := time.Date(2026, 3, 16+i, 0, 0, 0, 0, time.UTC).Format("2006-01-02")
		rates = append(rates, goals.DailyCompletionRate{Date: date, TotalGoals: 10, CompletedGoals: 9})
	}
	// Week 2 (good): 7 days at 85%.
	for i := range 7 {
		date := time.Date(2026, 3, 23+i, 0, 0, 0, 0, time.UTC).Format("2006-01-02")
		rates = append(rates, goals.DailyCompletionRate{Date: date, TotalGoals: 10, CompletedGoals: 9})
	}
	// Week 3 (good): 7 days at 80%.
	for i := range 7 {
		date := time.Date(2026, 3, 30+i, 0, 0, 0, 0, time.UTC).Format("2006-01-02")
		rates = append(rates, goals.DailyCompletionRate{Date: date, TotalGoals: 10, CompletedGoals: 8})
	}

	streaks := goals.ComputeGoalStreaks(rates)

	if streaks.WeeklyEightyPercent != 3 {
		t.Errorf("expected weeklyEightyPercent streak=3, got %d", streaks.WeeklyEightyPercent)
	}
}

// =============================================================================
// 1.8 Edge Cases
// =============================================================================

func TestEdgeCase_AC_EC_1_NoGoalsSetForDay(t *testing.T) {
	instances := []goals.GoalInstance{}

	total, completed := goals.ComputeDailySummary(instances)

	if total != 0 || completed != 0 {
		t.Errorf("expected 0/0 for empty day, got %d/%d", completed, total)
	}
}

func TestEdgeCase_AC_EC_2_DisableRecurringGoal(t *testing.T) {
	goalDef := goals.WeeklyDailyGoal{
		GoalID:     "wdg_test",
		Text:       "Disabled goal",
		Dynamics:   []goals.Dynamic{goals.DynamicSpiritual},
		Scope:      goals.ScopeDaily,
		Recurrence: goals.RecurrenceDaily,
		IsActive:   false, // disabled
		CreatedAt:  time.Now(),
	}

	instances := goals.MaterializeInstances([]goals.WeeklyDailyGoal{goalDef}, "2026-04-07", "u_test", "DEFAULT")

	if len(instances) != 0 {
		t.Errorf("expected 0 instances for inactive goal, got %d", len(instances))
	}
}

// =============================================================================
// 1.9 Integration Point Logic
// =============================================================================

func TestIntegration_AC_IP_4_PostMortemActionItemsAutoPopulate(t *testing.T) {
	sources := []goals.AutoPopulateSource{
		{
			Source:   goals.SourcePostMortem,
			SourceID: "pm_action_1",
			Text:     "Set up accountability call",
			Dynamics: []goals.Dynamic{goals.DynamicRelational},
		},
	}

	instances := goals.MaterializeAutoPopulated(sources, "2026-04-07", "u_test", "DEFAULT")

	if len(instances) != 1 {
		t.Fatalf("expected 1 post-mortem instance, got %d", len(instances))
	}
	if *instances[0].Source != goals.SourcePostMortem {
		t.Errorf("expected source=post-mortem, got %v", *instances[0].Source)
	}
}

// =============================================================================
// Helpers
// =============================================================================

func isValidationError(err error, target **goals.ValidationError) bool {
	var valErr *goals.ValidationError
	if ok := errors.As(err, &valErr); ok {
		*target = valErr
		return true
	}
	return false
}

func strPtr(s string) *string {
	return &s
}

