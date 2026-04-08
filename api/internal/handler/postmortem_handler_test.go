// internal/handler/postmortem_handler_test.go
package handler

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/regalrecovery/api/internal/domain/postmortem"
)

// setupHandler creates a handler with mock dependencies for testing.
func setupHandler() (*PostMortemHandler, *mockPostMortemRepo) {
	repo := newMockPostMortemRepo()
	perms := &mockPerms{allowed: true}
	svc := postmortem.NewPostMortemService(repo, perms)
	return NewPostMortemHandler(svc), repo
}

// TestPostMortemHandler_Create_ValidRequest_Returns201 verifies 201 with Location header.
func TestPostMortemHandler_Create_ValidRequest_Returns201(t *testing.T) {
	h, _ := setupHandler()

	body := `{"timestamp":"2026-03-28T23:00:00Z","eventType":"relapse","relapseId":"r_98765","sections":{"dayBefore":{"text":"test","moodRating":4}}}`
	req := httptest.NewRequest(http.MethodPost, "/activities/post-mortem", bytes.NewBufferString(body))
	req.Header.Set("X-User-Id", "u_12345")
	req.Header.Set("X-Correlation-Id", "test-correlation-id")

	rr := httptest.NewRecorder()
	h.CreatePostMortemAnalysis(rr, req)

	if rr.Code != http.StatusCreated {
		t.Errorf("expected 201, got %d", rr.Code)
	}
	if rr.Header().Get("Location") == "" {
		t.Error("expected Location header to be set")
	}

	var resp postMortemResponseJSON
	json.NewDecoder(rr.Body).Decode(&resp)
	if resp.Meta["message"] != postmortem.OpeningMessage {
		t.Errorf("expected opening message in meta, got '%v'", resp.Meta["message"])
	}
}

// TestPostMortemHandler_Create_InvalidEventType_Returns422 verifies validation error.
func TestPostMortemHandler_Create_InvalidEventType_Returns422(t *testing.T) {
	h, _ := setupHandler()

	body := `{"timestamp":"2026-03-28T23:00:00Z","eventType":"unknown"}`
	req := httptest.NewRequest(http.MethodPost, "/activities/post-mortem", bytes.NewBufferString(body))
	req.Header.Set("X-User-Id", "u_12345")

	rr := httptest.NewRecorder()
	h.CreatePostMortemAnalysis(rr, req)

	if rr.Code != http.StatusUnprocessableEntity {
		t.Errorf("expected 422, got %d", rr.Code)
	}

	var resp errorResponseJSON
	json.NewDecoder(rr.Body).Decode(&resp)
	if len(resp.Errors) == 0 || resp.Errors[0].Code != ErrCodeInvalidEventType {
		t.Errorf("expected error code %s, got %v", ErrCodeInvalidEventType, resp.Errors)
	}
}

// TestPostMortemHandler_Create_NearMissWithRelapseId_Returns422 verifies near-miss validation.
func TestPostMortemHandler_Create_NearMissWithRelapseId_Returns422(t *testing.T) {
	h, _ := setupHandler()

	body := `{"timestamp":"2026-03-28T23:00:00Z","eventType":"near-miss","relapseId":"r_98765"}`
	req := httptest.NewRequest(http.MethodPost, "/activities/post-mortem", bytes.NewBufferString(body))
	req.Header.Set("X-User-Id", "u_12345")

	rr := httptest.NewRecorder()
	h.CreatePostMortemAnalysis(rr, req)

	if rr.Code != http.StatusUnprocessableEntity {
		t.Errorf("expected 422, got %d", rr.Code)
	}
}

// TestPostMortemHandler_Get_NotFound_Returns404 verifies 404 for missing analysis.
func TestPostMortemHandler_Get_NotFound_Returns404(t *testing.T) {
	h, _ := setupHandler()

	req := httptest.NewRequest(http.MethodGet, "/activities/post-mortem/pm_nonexist", nil)
	req.Header.Set("X-User-Id", "u_12345")

	rr := httptest.NewRecorder()
	h.GetPostMortemAnalysis(rr, req, "pm_nonexist")

	if rr.Code != http.StatusNotFound {
		t.Errorf("expected 404, got %d", rr.Code)
	}
}

// TestPostMortemHandler_Delete_CompletedReturns422 verifies completed cannot be deleted.
func TestPostMortemHandler_Delete_CompletedReturns422(t *testing.T) {
	h, repo := setupHandler()

	// Create and complete a post-mortem via repo.
	analysis := createTestAnalysis("u_12345")
	analysis.Status = postmortem.StatusComplete
	repo.analyses[analysis.AnalysisID] = analysis

	req := httptest.NewRequest(http.MethodDelete, "/activities/post-mortem/"+analysis.AnalysisID, nil)
	req.Header.Set("X-User-Id", "u_12345")

	rr := httptest.NewRecorder()
	h.DeletePostMortemAnalysis(rr, req, analysis.AnalysisID)

	if rr.Code != http.StatusUnprocessableEntity {
		t.Errorf("expected 422, got %d", rr.Code)
	}
}

// TestPostMortemHandler_Delete_DraftReturns204 verifies draft deletion.
func TestPostMortemHandler_Delete_DraftReturns204(t *testing.T) {
	h, repo := setupHandler()

	analysis := createTestAnalysis("u_12345")
	repo.analyses[analysis.AnalysisID] = analysis

	req := httptest.NewRequest(http.MethodDelete, "/activities/post-mortem/"+analysis.AnalysisID, nil)
	req.Header.Set("X-User-Id", "u_12345")

	rr := httptest.NewRecorder()
	h.DeletePostMortemAnalysis(rr, req, analysis.AnalysisID)

	if rr.Code != http.StatusNoContent {
		t.Errorf("expected 204, got %d", rr.Code)
	}
}

// TestPostMortemHandler_Complete_MissingSections_Returns422 verifies incomplete completion.
func TestPostMortemHandler_Complete_MissingSections_Returns422(t *testing.T) {
	h, repo := setupHandler()

	analysis := createTestAnalysis("u_12345")
	repo.analyses[analysis.AnalysisID] = analysis

	req := httptest.NewRequest(http.MethodPost, "/activities/post-mortem/"+analysis.AnalysisID+"/complete", nil)
	req.Header.Set("X-User-Id", "u_12345")

	rr := httptest.NewRecorder()
	h.CompletePostMortemAnalysis(rr, req, analysis.AnalysisID)

	if rr.Code != http.StatusUnprocessableEntity {
		t.Errorf("expected 422, got %d", rr.Code)
	}
}

// TestPostMortemHandler_Share_DraftNotAllowed_Returns422 verifies draft sharing rejection.
func TestPostMortemHandler_Share_DraftNotAllowed_Returns422(t *testing.T) {
	h, repo := setupHandler()

	analysis := createTestAnalysis("u_12345")
	repo.analyses[analysis.AnalysisID] = analysis

	body := `{"shares":[{"contactId":"c_99999","shareType":"full"}]}`
	req := httptest.NewRequest(http.MethodPost, "/activities/post-mortem/"+analysis.AnalysisID+"/share", bytes.NewBufferString(body))
	req.Header.Set("X-User-Id", "u_12345")

	rr := httptest.NewRecorder()
	h.SharePostMortemAnalysis(rr, req, analysis.AnalysisID)

	if rr.Code != http.StatusUnprocessableEntity {
		t.Errorf("expected 422, got %d", rr.Code)
	}
}

// TestPostMortemHandler_Update_CompletedPostMortem_SectionsImmutable verifies immutability.
func TestPostMortemHandler_Update_CompletedPostMortem_SectionsImmutable(t *testing.T) {
	h, repo := setupHandler()

	analysis := createFullTestAnalysis("u_12345")
	analysis.Status = postmortem.StatusComplete
	repo.analyses[analysis.AnalysisID] = analysis

	body := `{"sections":{"dayBefore":{"text":"changed"}}}`
	req := httptest.NewRequest(http.MethodPatch, "/activities/post-mortem/"+analysis.AnalysisID, bytes.NewBufferString(body))
	req.Header.Set("X-User-Id", "u_12345")

	rr := httptest.NewRecorder()
	h.UpdatePostMortemAnalysis(rr, req, analysis.AnalysisID)

	if rr.Code != http.StatusUnprocessableEntity {
		t.Errorf("expected 422, got %d", rr.Code)
	}
}

// --- Test helpers ---

func createTestAnalysis(userID string) *postmortem.PostMortemAnalysis {
	return &postmortem.PostMortemAnalysis{
		AnalysisID: "pm_test001",
		UserID:     userID,
		TenantID:   "DEFAULT",
		Status:     postmortem.StatusDraft,
		EventType:  postmortem.EventTypeRelapse,
		Sections: postmortem.Sections{
			DayBefore: &postmortem.DayBeforeSection{Text: "test"},
		},
	}
}

func createFullTestAnalysis(userID string) *postmortem.PostMortemAnalysis {
	dur := 45
	return &postmortem.PostMortemAnalysis{
		AnalysisID: "pm_full001",
		UserID:     userID,
		TenantID:   "DEFAULT",
		Status:     postmortem.StatusDraft,
		EventType:  postmortem.EventTypeRelapse,
		Sections: postmortem.Sections{
			DayBefore:        &postmortem.DayBeforeSection{Text: "test"},
			Morning:          &postmortem.MorningSection{Text: "test"},
			ThroughoutTheDay: &postmortem.ThroughoutTheDaySection{},
			BuildUp:          &postmortem.BuildUpSection{},
			ActingOut:        &postmortem.ActingOutSection{Description: "test", DurationMinutes: &dur},
			ImmediatelyAfter: &postmortem.ImmediatelyAfterSection{},
		},
		ActionPlan: []postmortem.ActionPlanItem{
			{ActionID: "ap_001", Action: "test", Category: postmortem.ActionCategorySpiritual},
		},
	}
}

// mockPostMortemRepo implements postmortem.PostMortemRepository for handler tests.
type mockPostMortemRepo struct {
	analyses map[string]*postmortem.PostMortemAnalysis
}

func newMockPostMortemRepo() *mockPostMortemRepo {
	return &mockPostMortemRepo{analyses: make(map[string]*postmortem.PostMortemAnalysis)}
}

func (m *mockPostMortemRepo) Create(_ context.Context, a *postmortem.PostMortemAnalysis) error {
	m.analyses[a.AnalysisID] = a
	return nil
}

func (m *mockPostMortemRepo) GetByID(_ context.Context, userID, analysisID string) (*postmortem.PostMortemAnalysis, error) {
	a, ok := m.analyses[analysisID]
	if !ok || a.UserID != userID {
		return nil, nil
	}
	return a, nil
}

func (m *mockPostMortemRepo) GetByRelapseID(_ context.Context, _, _ string) (*postmortem.PostMortemAnalysis, error) {
	return nil, nil
}

func (m *mockPostMortemRepo) List(_ context.Context, _ string, _ postmortem.ListFilter) (*postmortem.PaginatedResult, error) {
	return &postmortem.PaginatedResult{}, nil
}

func (m *mockPostMortemRepo) FindDrafts(_ context.Context, _ string) ([]*postmortem.PostMortemAnalysis, error) {
	return nil, nil
}

func (m *mockPostMortemRepo) Update(_ context.Context, a *postmortem.PostMortemAnalysis) error {
	m.analyses[a.AnalysisID] = a
	return nil
}

func (m *mockPostMortemRepo) Delete(_ context.Context, _, analysisID string) error {
	delete(m.analyses, analysisID)
	return nil
}

func (m *mockPostMortemRepo) GetInsightsData(_ context.Context, _ string, _ *postmortem.InsightsFilter) ([]*postmortem.PostMortemAnalysis, error) {
	return nil, nil
}

func (m *mockPostMortemRepo) GetSharedWith(_ context.Context, _ string) ([]*postmortem.PostMortemAnalysis, error) {
	return nil, nil
}

func (m *mockPostMortemRepo) WriteCalendarActivity(_ context.Context, _ *postmortem.CalendarActivityEntry) error {
	return nil
}

// mockPerms implements postmortem.PermissionChecker.
type mockPerms struct {
	allowed bool
}

func (m *mockPerms) HasPermission(_ context.Context, _, _, _ string) (bool, error) {
	return m.allowed, nil
}
