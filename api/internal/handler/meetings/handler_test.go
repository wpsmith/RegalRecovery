// internal/handler/meetings/handler_test.go
package meetings

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/regalrecovery/api/internal/domain/meetings"
	"github.com/regalrecovery/api/internal/middleware"
)

// Ensure context import is used.
var _ = context.Background

// --- Mock dependencies ---

type mockMeetingRepo struct {
	store map[string]*meetings.MeetingLog
}

func newMockMeetingRepo() *mockMeetingRepo {
	return &mockMeetingRepo{store: make(map[string]*meetings.MeetingLog)}
}

func (m *mockMeetingRepo) Create(ctx context.Context, meeting *meetings.MeetingLog) error {
	m.store[meeting.MeetingID] = meeting
	return nil
}

func (m *mockMeetingRepo) GetByID(ctx context.Context, userID, meetingID string) (*meetings.MeetingLog, error) {
	mtg, ok := m.store[meetingID]
	if !ok || mtg.UserID != userID {
		return nil, nil
	}
	return mtg, nil
}

func (m *mockMeetingRepo) ListByUser(ctx context.Context, userID string, filter meetings.ListMeetingLogsFilter) ([]*meetings.MeetingLog, string, error) {
	var results []*meetings.MeetingLog
	for _, mtg := range m.store {
		if mtg.UserID == userID {
			results = append(results, mtg)
		}
	}
	return results, "", nil
}

func (m *mockMeetingRepo) Update(ctx context.Context, meeting *meetings.MeetingLog) error {
	m.store[meeting.MeetingID] = meeting
	return nil
}

func (m *mockMeetingRepo) Delete(ctx context.Context, userID, meetingID string) error {
	delete(m.store, meetingID)
	return nil
}

func (m *mockMeetingRepo) GetMeetingsInRange(ctx context.Context, userID string, start, end time.Time) ([]*meetings.MeetingLog, error) {
	return nil, nil
}

type mockSavedMeetingRepo struct {
	store map[string]*meetings.SavedMeeting
}

func newMockSavedMeetingRepo() *mockSavedMeetingRepo {
	return &mockSavedMeetingRepo{store: make(map[string]*meetings.SavedMeeting)}
}

func (m *mockSavedMeetingRepo) Create(ctx context.Context, saved *meetings.SavedMeeting) error {
	m.store[saved.SavedMeetingID] = saved
	return nil
}

func (m *mockSavedMeetingRepo) GetByID(ctx context.Context, userID, savedMeetingID string) (*meetings.SavedMeeting, error) {
	s, ok := m.store[savedMeetingID]
	if !ok || s.UserID != userID {
		return nil, nil
	}
	return s, nil
}

func (m *mockSavedMeetingRepo) ListActive(ctx context.Context, userID string) ([]*meetings.SavedMeeting, error) {
	var results []*meetings.SavedMeeting
	for _, s := range m.store {
		if s.UserID == userID && s.IsActive {
			results = append(results, s)
		}
	}
	return results, nil
}

func (m *mockSavedMeetingRepo) Update(ctx context.Context, saved *meetings.SavedMeeting) error {
	m.store[saved.SavedMeetingID] = saved
	return nil
}

func (m *mockSavedMeetingRepo) SoftDelete(ctx context.Context, userID, savedMeetingID string) error {
	if s, ok := m.store[savedMeetingID]; ok && s.UserID == userID {
		s.IsActive = false
	}
	return nil
}

type mockPublisher struct{}

func (m *mockPublisher) PublishMeetingCreated(ctx context.Context, meeting *meetings.MeetingLog) error {
	return nil
}

type mockFlagChecker struct {
	enabled bool
}

func (m *mockFlagChecker) IsEnabled(r *http.Request) bool {
	return m.enabled
}

// --- Test helpers ---

func makeTestHandler(flagEnabled bool) (*Handler, *mockMeetingRepo) {
	meetingRepo := newMockMeetingRepo()
	savedRepo := newMockSavedMeetingRepo()
	publisher := &mockPublisher{}

	meetingSvc := meetings.NewMeetingLogService(meetingRepo, savedRepo, publisher)
	savedSvc := meetings.NewSavedMeetingService(savedRepo)
	summarySvc := meetings.NewSummaryService(meetingRepo)

	handler := NewHandler(meetingSvc, savedSvc, summarySvc, &mockFlagChecker{enabled: flagEnabled})
	return handler, meetingRepo
}

func makeAuthenticatedRequest(method, path string, body interface{}) *http.Request {
	var bodyBytes []byte
	if body != nil {
		bodyBytes, _ = json.Marshal(body)
	}

	req := httptest.NewRequest(method, path, bytes.NewReader(bodyBytes))
	req.Header.Set("Content-Type", "application/json")

	// Inject auth context values using middleware test helpers.
	ctx := middleware.WithTestAuth(req.Context(), "u_alex", "DEFAULT")
	ctx = middleware.WithTestCorrelation(ctx, "test-corr-123")
	return req.WithContext(ctx)
}

// --- Tests ---

// TestMeetingHandler_POST_201_CreatesAndReturnsLocation verifies that creating a meeting log
// returns 201 with a Location header.
func TestMeetingHandler_POST_201_CreatesAndReturnsLocation(t *testing.T) {
	handler, _ := makeTestHandler(true)

	body := map[string]interface{}{
		"timestamp":   time.Now().UTC().Format(time.RFC3339),
		"meetingType": "SA",
		"name":        "Tuesday Night Recovery",
	}

	mux := http.NewServeMux()
	handler.RegisterRoutes(mux)

	req := makeAuthenticatedRequest("POST", "/v1/activities/meetings", body)
	rr := httptest.NewRecorder()
	mux.ServeHTTP(rr, req)

	if rr.Code != http.StatusCreated {
		t.Errorf("expected 201, got %d: %s", rr.Code, rr.Body.String())
	}
	if loc := rr.Header().Get("Location"); loc == "" {
		t.Error("expected Location header to be set")
	}
}

// TestMeetingHandler_POST_400_MalformedJSON verifies that malformed JSON body returns 400.
func TestMeetingHandler_POST_400_MalformedJSON(t *testing.T) {
	handler, _ := makeTestHandler(true)

	mux := http.NewServeMux()
	handler.RegisterRoutes(mux)

	req := makeAuthenticatedRequest("POST", "/v1/activities/meetings", nil)
	req.Body = http.NoBody
	rr := httptest.NewRecorder()
	mux.ServeHTTP(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rr.Code)
	}
}

// TestMeetingHandler_PATCH_422_TimestampImmutable verifies that attempting to update
// the timestamp field returns 422 (FR2.7).
//
// Acceptance Criterion (FR-MTG-1.5): Timestamp is immutable.
func TestMeetingHandler_PATCH_422_TimestampImmutable(t *testing.T) {
	handler, repo := makeTestHandler(true)

	// Seed a meeting.
	repo.store["mt_33333"] = &meetings.MeetingLog{
		MeetingID:   "mt_33333",
		UserID:      "u_alex",
		TenantID:    "DEFAULT",
		Timestamp:   time.Now().UTC(),
		MeetingType: "SA",
		Status:      meetings.MeetingStatusAttended,
		CreatedAt:   time.Now().UTC(),
		ModifiedAt:  time.Now().UTC(),
	}

	body := map[string]interface{}{
		"timestamp": time.Now().Add(24 * time.Hour).UTC().Format(time.RFC3339),
		"notes":     "trying to change timestamp",
	}

	mux := http.NewServeMux()
	handler.RegisterRoutes(mux)

	req := makeAuthenticatedRequest("PATCH", "/v1/activities/meetings/mt_33333", body)
	rr := httptest.NewRecorder()
	mux.ServeHTTP(rr, req)

	if rr.Code != http.StatusUnprocessableEntity {
		t.Errorf("expected 422 for immutable timestamp, got %d: %s", rr.Code, rr.Body.String())
	}
}

// TestMeetingHandler_DELETE_204 verifies that deleting a meeting returns 204.
func TestMeetingHandler_DELETE_204(t *testing.T) {
	handler, repo := makeTestHandler(true)

	repo.store["mt_33333"] = &meetings.MeetingLog{
		MeetingID:   "mt_33333",
		UserID:      "u_alex",
		TenantID:    "DEFAULT",
		Timestamp:   time.Now().UTC(),
		MeetingType: "SA",
		Status:      meetings.MeetingStatusAttended,
		CreatedAt:   time.Now().UTC(),
		ModifiedAt:  time.Now().UTC(),
	}

	mux := http.NewServeMux()
	handler.RegisterRoutes(mux)

	req := makeAuthenticatedRequest("DELETE", "/v1/activities/meetings/mt_33333", nil)
	rr := httptest.NewRecorder()
	mux.ServeHTTP(rr, req)

	if rr.Code != http.StatusNoContent {
		t.Errorf("expected 204, got %d: %s", rr.Code, rr.Body.String())
	}
}

// TestMeetingLog_NFR_MTG_5_FlagDisabled_Returns404 verifies that when the
// activity.meetings feature flag is disabled, all endpoints return 404.
//
// Acceptance Criterion (NFR-MTG-5): Fail closed.
func TestMeetingLog_NFR_MTG_5_FlagDisabled_Returns404(t *testing.T) {
	handler, _ := makeTestHandler(false)

	mux := http.NewServeMux()
	handler.RegisterRoutes(mux)

	endpoints := []struct {
		method string
		path   string
	}{
		{"POST", "/v1/activities/meetings"},
		{"GET", "/v1/activities/meetings"},
		{"GET", "/v1/activities/meetings/mt_33333"},
		{"PATCH", "/v1/activities/meetings/mt_33333"},
		{"DELETE", "/v1/activities/meetings/mt_33333"},
		{"GET", "/v1/activities/meetings/summary?period=week"},
		{"POST", "/v1/activities/meetings/saved"},
		{"GET", "/v1/activities/meetings/saved"},
		{"GET", "/v1/activities/meetings/saved/sm_11111"},
		{"PATCH", "/v1/activities/meetings/saved/sm_11111"},
		{"DELETE", "/v1/activities/meetings/saved/sm_11111"},
	}

	for _, ep := range endpoints {
		req := makeAuthenticatedRequest(ep.method, ep.path, map[string]interface{}{})
		rr := httptest.NewRecorder()
		mux.ServeHTTP(rr, req)

		if rr.Code != http.StatusNotFound {
			t.Errorf("[%s %s] expected 404 when flag disabled, got %d", ep.method, ep.path, rr.Code)
		}
	}
}

// TestMeetingLog_NFR_MTG_5_FlagEnabled_EndpointsAccessible verifies that when the
// activity.meetings feature flag is enabled, endpoints respond normally.
func TestMeetingLog_NFR_MTG_5_FlagEnabled_EndpointsAccessible(t *testing.T) {
	handler, _ := makeTestHandler(true)

	mux := http.NewServeMux()
	handler.RegisterRoutes(mux)

	req := makeAuthenticatedRequest("GET", "/v1/activities/meetings", nil)
	rr := httptest.NewRecorder()
	mux.ServeHTTP(rr, req)

	if rr.Code == http.StatusNotFound {
		t.Error("expected endpoints to be accessible when flag enabled, got 404")
	}
}

// TestMeetingHandler_GET_meetingId_404_NotFound verifies that requesting a
// nonexistent meeting returns 404.
func TestMeetingHandler_GET_meetingId_404_NotFound(t *testing.T) {
	handler, _ := makeTestHandler(true)

	mux := http.NewServeMux()
	handler.RegisterRoutes(mux)

	req := makeAuthenticatedRequest("GET", "/v1/activities/meetings/mt_nonexistent", nil)
	rr := httptest.NewRecorder()
	mux.ServeHTTP(rr, req)

	if rr.Code != http.StatusNotFound {
		t.Errorf("expected 404, got %d", rr.Code)
	}
}

// TestMeetingLogUpdate_FR_MTG_4_1_UpdateAllowedFields verifies that allowed
// fields can be updated via PATCH.
func TestMeetingLogUpdate_FR_MTG_4_1_UpdateAllowedFields(t *testing.T) {
	handler, repo := makeTestHandler(true)

	repo.store["mt_33333"] = &meetings.MeetingLog{
		MeetingID:   "mt_33333",
		UserID:      "u_alex",
		TenantID:    "DEFAULT",
		Timestamp:   time.Now().UTC(),
		MeetingType: "SA",
		Status:      meetings.MeetingStatusAttended,
		CreatedAt:   time.Now().UTC(),
		ModifiedAt:  time.Now().UTC(),
	}

	body := map[string]interface{}{
		"notes":           "Updated notes after reflection.",
		"durationMinutes": 75,
	}

	mux := http.NewServeMux()
	handler.RegisterRoutes(mux)

	req := makeAuthenticatedRequest("PATCH", "/v1/activities/meetings/mt_33333", body)
	rr := httptest.NewRecorder()
	mux.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rr.Code, rr.Body.String())
	}
}

// TestMeetingLogUpdate_FR_MTG_4_2_MarkAsCanceled verifies that a meeting
// can be marked as canceled.
func TestMeetingLogUpdate_FR_MTG_4_2_MarkAsCanceled(t *testing.T) {
	handler, repo := makeTestHandler(true)

	repo.store["mt_33333"] = &meetings.MeetingLog{
		MeetingID:   "mt_33333",
		UserID:      "u_alex",
		TenantID:    "DEFAULT",
		Timestamp:   time.Now().UTC(),
		MeetingType: "SA",
		Status:      meetings.MeetingStatusAttended,
		CreatedAt:   time.Now().UTC(),
		ModifiedAt:  time.Now().UTC(),
	}

	body := map[string]interface{}{
		"status": "canceled",
	}

	mux := http.NewServeMux()
	handler.RegisterRoutes(mux)

	req := makeAuthenticatedRequest("PATCH", "/v1/activities/meetings/mt_33333", body)
	rr := httptest.NewRecorder()
	mux.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rr.Code, rr.Body.String())
	}

	// Verify the status was updated.
	if repo.store["mt_33333"].Status != meetings.MeetingStatusCanceled {
		t.Error("expected status to be 'canceled'")
	}
}
