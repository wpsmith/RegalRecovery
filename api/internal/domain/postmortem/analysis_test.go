// internal/domain/postmortem/analysis_test.go
package postmortem

import (
	"context"
	"errors"
	"testing"
	"time"
)

// mockRepo is a test double for PostMortemRepository.
type mockRepo struct {
	analyses map[string]*PostMortemAnalysis
	calEntry *CalendarActivityEntry
	createErr error
	updateErr error
}

func newMockRepo() *mockRepo {
	return &mockRepo{analyses: make(map[string]*PostMortemAnalysis)}
}

func (m *mockRepo) Create(_ context.Context, a *PostMortemAnalysis) error {
	if m.createErr != nil {
		return m.createErr
	}
	m.analyses[a.AnalysisID] = a
	return nil
}

func (m *mockRepo) GetByID(_ context.Context, userID, analysisID string) (*PostMortemAnalysis, error) {
	a, ok := m.analyses[analysisID]
	if !ok || a.UserID != userID {
		return nil, nil
	}
	return a, nil
}

func (m *mockRepo) GetByRelapseID(_ context.Context, userID, relapseID string) (*PostMortemAnalysis, error) {
	for _, a := range m.analyses {
		if a.UserID == userID && a.RelapseID != nil && *a.RelapseID == relapseID {
			return a, nil
		}
	}
	return nil, nil
}

func (m *mockRepo) List(_ context.Context, _ string, _ ListFilter) (*PaginatedResult, error) {
	var all []*PostMortemAnalysis
	for _, a := range m.analyses {
		all = append(all, a)
	}
	return &PaginatedResult{Analyses: all}, nil
}

func (m *mockRepo) FindDrafts(_ context.Context, userID string) ([]*PostMortemAnalysis, error) {
	var drafts []*PostMortemAnalysis
	for _, a := range m.analyses {
		if a.UserID == userID && a.Status == StatusDraft {
			drafts = append(drafts, a)
		}
	}
	return drafts, nil
}

func (m *mockRepo) Update(_ context.Context, a *PostMortemAnalysis) error {
	if m.updateErr != nil {
		return m.updateErr
	}
	m.analyses[a.AnalysisID] = a
	return nil
}

func (m *mockRepo) Delete(_ context.Context, userID, analysisID string) error {
	delete(m.analyses, analysisID)
	return nil
}

func (m *mockRepo) GetInsightsData(_ context.Context, _ string, _ *InsightsFilter) ([]*PostMortemAnalysis, error) {
	return nil, nil
}

func (m *mockRepo) GetSharedWith(_ context.Context, _ string) ([]*PostMortemAnalysis, error) {
	return nil, nil
}

func (m *mockRepo) WriteCalendarActivity(_ context.Context, entry *CalendarActivityEntry) error {
	m.calEntry = entry
	return nil
}

// mockPermissions is a test double for PermissionChecker.
type mockPermissions struct {
	allowed bool
}

func (m *mockPermissions) HasPermission(_ context.Context, _, _, _ string) (bool, error) {
	return m.allowed, nil
}

// TestPostMortem_PM_AC2_1_AutoSaveDraft verifies draft creation.
// Acceptance Criterion (PM-AC2.1): Auto-save as draft.
func TestPostMortem_PM_AC2_1_AutoSaveDraft(t *testing.T) {
	repo := newMockRepo()
	svc := NewPostMortemService(repo, &mockPermissions{})
	ctx := context.Background()

	sections := &Sections{
		DayBefore: &DayBeforeSection{Text: "feeling disconnected"},
	}

	analysis, err := svc.CreateAnalysis(ctx, "u_12345", "DEFAULT", EventTypeRelapse, strPtr("r_98765"), strPtr("a_67890"), time.Now(), sections)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if analysis.Status != StatusDraft {
		t.Errorf("expected status 'draft', got '%s'", analysis.Status)
	}
	if analysis.CompletedAt != nil {
		t.Error("expected completedAt to be nil for draft")
	}
}

// TestPostMortem_PM_AC2_3_DraftToCompleteTransition verifies transition from draft to complete.
// Acceptance Criterion (PM-AC2.3): Draft -> complete with completedAt set.
func TestPostMortem_PM_AC2_3_DraftToCompleteTransition(t *testing.T) {
	repo := newMockRepo()
	svc := NewPostMortemService(repo, &mockPermissions{})
	ctx := context.Background()

	analysis := createFullDraftAnalysis(t, svc, ctx)

	completed, err := svc.CompleteAnalysis(ctx, analysis.UserID, analysis.AnalysisID)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if completed.Status != StatusComplete {
		t.Errorf("expected status 'complete', got '%s'", completed.Status)
	}
	if completed.CompletedAt == nil {
		t.Error("expected completedAt to be set")
	}
}

// TestPostMortem_PM_AC1_9_RelapseIdOptional verifies near-miss without relapseId.
// Acceptance Criterion (PM-AC1.9): Relapse link is optional.
func TestPostMortem_PM_AC1_9_RelapseIdOptional(t *testing.T) {
	repo := newMockRepo()
	svc := NewPostMortemService(repo, &mockPermissions{})
	ctx := context.Background()

	analysis, err := svc.CreateAnalysis(ctx, "u_12345", "DEFAULT", EventTypeNearMiss, nil, nil, time.Now(), nil)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if analysis.RelapseID != nil {
		t.Error("expected relapseId to be nil for near-miss")
	}
}

// TestPostMortem_PM_AC1_9_RelapseIdLinked verifies relapse event with linked relapseId.
func TestPostMortem_PM_AC1_9_RelapseIdLinked(t *testing.T) {
	repo := newMockRepo()
	svc := NewPostMortemService(repo, &mockPermissions{})
	ctx := context.Background()

	relapseID := "r_98765"
	analysis, err := svc.CreateAnalysis(ctx, "u_12345", "DEFAULT", EventTypeRelapse, &relapseID, nil, time.Now(), nil)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if analysis.RelapseID == nil || *analysis.RelapseID != relapseID {
		t.Error("expected relapseId to be linked")
	}
}

// TestPostMortem_PM_AC13_1_ImmutableTimestamp verifies createdAt cannot be modified.
// Acceptance Criterion (PM-AC13.1): Immutable timestamp.
func TestPostMortem_PM_AC13_1_ImmutableTimestamp(t *testing.T) {
	repo := newMockRepo()
	svc := NewPostMortemService(repo, &mockPermissions{})
	ctx := context.Background()

	analysis, err := svc.CreateAnalysis(ctx, "u_12345", "DEFAULT", EventTypeRelapse, nil, nil, time.Now(), nil)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	originalCreatedAt := analysis.CreatedAt

	// Update the analysis.
	_, err = svc.UpdateAnalysis(ctx, "u_12345", analysis,
		&Sections{Morning: &MorningSection{Text: "updated"}},
		nil, nil, nil, nil)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	// CreatedAt must remain unchanged.
	if !analysis.CreatedAt.Equal(originalCreatedAt) {
		t.Errorf("createdAt was modified: was %v, now %v", originalCreatedAt, analysis.CreatedAt)
	}
}

// TestPostMortem_PM_AC7_5_PermissionCheckOnAccess verifies permission denied returns 404.
// Acceptance Criterion (PM-AC7.5): Return 404, not 403.
func TestPostMortem_PM_AC7_5_PermissionCheckOnAccess(t *testing.T) {
	repo := newMockRepo()
	perms := &mockPermissions{allowed: false}
	svc := NewPostMortemService(repo, perms)
	ctx := context.Background()

	// Create and complete a post-mortem.
	analysis := createFullDraftAnalysis(t, svc, ctx)
	analysis, _ = svc.CompleteAnalysis(ctx, analysis.UserID, analysis.AnalysisID)

	// Share it.
	shares := []SharedWithEntry{
		{ContactID: "c_99999", ShareType: ShareTypeFull, SharedAt: time.Now()},
	}
	_, err := svc.ShareAnalysis(ctx, analysis.UserID, analysis.AnalysisID, shares)
	if err != nil {
		t.Fatalf("unexpected error sharing: %v", err)
	}

	// Contact without permission tries to access.
	_, err = svc.GetAnalysis(ctx, "c_99999", analysis.UserID, analysis.AnalysisID)
	if !errors.Is(err, ErrNotFound) {
		t.Errorf("expected ErrNotFound for denied access, got %v", err)
	}
}

// TestPostMortem_PM_AC7_5_PermissionCheckGranted verifies access granted with permission.
func TestPostMortem_PM_AC7_5_PermissionCheckGranted(t *testing.T) {
	repo := newMockRepo()
	perms := &mockPermissions{allowed: true}
	svc := NewPostMortemService(repo, perms)
	ctx := context.Background()

	analysis := createFullDraftAnalysis(t, svc, ctx)
	analysis, _ = svc.CompleteAnalysis(ctx, analysis.UserID, analysis.AnalysisID)

	shares := []SharedWithEntry{
		{ContactID: "c_99999", ShareType: ShareTypeFull, SharedAt: time.Now()},
	}
	_, err := svc.ShareAnalysis(ctx, analysis.UserID, analysis.AnalysisID, shares)
	if err != nil {
		t.Fatalf("unexpected error sharing: %v", err)
	}

	result, err := svc.GetAnalysis(ctx, "c_99999", analysis.UserID, analysis.AnalysisID)
	if err != nil {
		t.Fatalf("expected access to be granted, got error: %v", err)
	}
	if result.AnalysisID != analysis.AnalysisID {
		t.Error("expected the shared analysis to be returned")
	}
}

// TestPostMortem_CannotDeleteCompleted verifies completed post-mortems cannot be deleted.
// Acceptance Criterion: rr:0x00050004.
func TestPostMortem_CannotDeleteCompleted(t *testing.T) {
	repo := newMockRepo()
	svc := NewPostMortemService(repo, &mockPermissions{})
	ctx := context.Background()

	analysis := createFullDraftAnalysis(t, svc, ctx)
	_, err := svc.CompleteAnalysis(ctx, analysis.UserID, analysis.AnalysisID)
	if err != nil {
		t.Fatalf("unexpected error completing: %v", err)
	}

	err = svc.DeleteAnalysis(ctx, analysis.UserID, analysis.AnalysisID)
	if !errors.Is(err, ErrCannotDeleteCompleted) {
		t.Errorf("expected ErrCannotDeleteCompleted, got %v", err)
	}
}

// TestPostMortem_CannotShareDraft verifies drafts cannot be shared.
// Acceptance Criterion: rr:0x00050005.
func TestPostMortem_CannotShareDraft(t *testing.T) {
	repo := newMockRepo()
	svc := NewPostMortemService(repo, &mockPermissions{})
	ctx := context.Background()

	analysis, _ := svc.CreateAnalysis(ctx, "u_12345", "DEFAULT", EventTypeRelapse, nil, nil, time.Now(), nil)

	shares := []SharedWithEntry{
		{ContactID: "c_99999", ShareType: ShareTypeFull, SharedAt: time.Now()},
	}
	_, err := svc.ShareAnalysis(ctx, analysis.UserID, analysis.AnalysisID, shares)
	if !errors.Is(err, ErrCannotShareDraft) {
		t.Errorf("expected ErrCannotShareDraft, got %v", err)
	}
}

// TestPostMortem_CompletedPostMortemImmutable verifies completed analyses' sections cannot be modified.
// Acceptance Criterion: rr:0x0005000A.
func TestPostMortem_CompletedPostMortemImmutable(t *testing.T) {
	repo := newMockRepo()
	svc := NewPostMortemService(repo, &mockPermissions{})
	ctx := context.Background()

	analysis := createFullDraftAnalysis(t, svc, ctx)
	analysis, _ = svc.CompleteAnalysis(ctx, analysis.UserID, analysis.AnalysisID)

	_, err := svc.UpdateAnalysis(ctx, analysis.UserID, analysis,
		&Sections{Morning: &MorningSection{Text: "changed"}},
		nil, nil, nil, nil)
	if !errors.Is(err, ErrCompletedImmutable) {
		t.Errorf("expected ErrCompletedImmutable, got %v", err)
	}
}

// TestPostMortem_CompletedPostMortem_ActionPlanEditable verifies action plan is editable after completion.
func TestPostMortem_CompletedPostMortem_ActionPlanEditable(t *testing.T) {
	repo := newMockRepo()
	svc := NewPostMortemService(repo, &mockPermissions{})
	ctx := context.Background()

	analysis := createFullDraftAnalysis(t, svc, ctx)
	analysis, _ = svc.CompleteAnalysis(ctx, analysis.UserID, analysis.AnalysisID)

	newPlan := []ActionPlanItem{
		{ActionID: "ap_new1", Action: "New action", Category: ActionCategorySpiritual},
		{ActionID: "ap_new2", Action: "Another action", Category: ActionCategoryRelational},
	}
	updated, err := svc.UpdateAnalysis(ctx, analysis.UserID, analysis, nil, nil, nil, nil, newPlan)
	if err != nil {
		t.Fatalf("expected action plan update on completed to succeed, got error: %v", err)
	}
	if len(updated.ActionPlan) != 2 {
		t.Errorf("expected 2 action items, got %d", len(updated.ActionPlan))
	}
}

// TestPostMortem_CalendarDualWriteOnComplete verifies calendar activity is written on completion.
func TestPostMortem_CalendarDualWriteOnComplete(t *testing.T) {
	repo := newMockRepo()
	svc := NewPostMortemService(repo, &mockPermissions{})
	ctx := context.Background()

	analysis := createFullDraftAnalysis(t, svc, ctx)
	_, err := svc.CompleteAnalysis(ctx, analysis.UserID, analysis.AnalysisID)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if repo.calEntry == nil {
		t.Fatal("expected calendar activity entry to be written")
	}
	if repo.calEntry.ActivityType != "POSTMORTEM" {
		t.Errorf("expected activity type 'POSTMORTEM', got '%s'", repo.calEntry.ActivityType)
	}
}

// createFullDraftAnalysis is a helper that creates a draft with all sections + action plan.
func createFullDraftAnalysis(t *testing.T, svc *PostMortemService, ctx context.Context) *PostMortemAnalysis {
	t.Helper()
	dur := 45
	sections := &Sections{
		DayBefore:        &DayBeforeSection{Text: "felt disconnected"},
		Morning:          &MorningSection{Text: "skipped commitment"},
		ThroughoutTheDay: &ThroughoutTheDaySection{TimeBlocks: []TimeBlock{{Period: "morning", StartTime: "08:00", EndTime: "12:00"}}},
		BuildUp:          &BuildUpSection{FirstNoticed: "around midday"},
		ActingOut:        &ActingOutSection{Description: "acted out", DurationMinutes: &dur},
		ImmediatelyAfter: &ImmediatelyAfterSection{Feelings: []string{"shame"}},
	}

	analysis, err := svc.CreateAnalysis(ctx, "u_12345", "DEFAULT", EventTypeRelapse, strPtr("r_98765"), strPtr("a_67890"), time.Now(), sections)
	if err != nil {
		t.Fatalf("failed to create analysis: %v", err)
	}

	// Add action plan.
	plan := []ActionPlanItem{
		{ActionID: "ap_001", Action: "Call sponsor", Category: ActionCategoryRelational},
	}
	analysis, err = svc.UpdateAnalysis(ctx, "u_12345", analysis, nil, nil, nil, nil, plan)
	if err != nil {
		t.Fatalf("failed to add action plan: %v", err)
	}

	return analysis
}

func strPtr(s string) *string {
	return &s
}
