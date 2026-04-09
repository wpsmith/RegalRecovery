// internal/domain/affirmations/handler_test.go
package affirmations

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/regalrecovery/api/internal/events"
	"github.com/regalrecovery/api/internal/middleware"
	"github.com/regalrecovery/api/internal/repository"
)

// --- Mock implementations ---

type mockAffirmationsRepo struct {
	getLibraryAffirmationsFn    func(ctx context.Context, level int, category, track string, active bool, limit int) ([]repository.AffirmationLibraryDoc, error)
	getLibraryAffirmationByIDFn func(ctx context.Context, affirmationID string) (*repository.AffirmationLibraryDoc, error)
	searchLibraryAffirmationsFn func(ctx context.Context, keyword string, active bool, limit int) ([]repository.AffirmationLibraryDoc, error)
	listSessionsFn              func(ctx context.Context, userID string, limit int) ([]repository.AffirmationSessionDoc, error)
	getSessionFn                func(ctx context.Context, sessionID string) (*repository.AffirmationSessionDoc, error)
	addFavoriteFn               func(ctx context.Context, userID, affirmationID, tenantID string) error
	listFavoritesFn             func(ctx context.Context, userID string) ([]repository.AffirmationFavoriteDoc, error)
	createCustomFn              func(ctx context.Context, custom *repository.AffirmationCustomDoc) error
	getSettingsFn               func(ctx context.Context, userID string) (*repository.AffirmationSettingsDoc, error)
	upsertSettingsFn            func(ctx context.Context, settings *repository.AffirmationSettingsDoc) error
	saveAudioMetadataFn         func(ctx context.Context, audio *repository.AffirmationAudioDoc) error
}

// Implement all required interface methods...
func (m *mockAffirmationsRepo) GetLibraryAffirmations(ctx context.Context, level int, category, track string, active bool, limit int) ([]repository.AffirmationLibraryDoc, error) {
	if m.getLibraryAffirmationsFn != nil {
		return m.getLibraryAffirmationsFn(ctx, level, category, track, active, limit)
	}
	return nil, nil
}

func (m *mockAffirmationsRepo) GetLibraryAffirmationByID(ctx context.Context, affirmationID string) (*repository.AffirmationLibraryDoc, error) {
	if m.getLibraryAffirmationByIDFn != nil {
		return m.getLibraryAffirmationByIDFn(ctx, affirmationID)
	}
	return nil, errors.New("not found")
}

func (m *mockAffirmationsRepo) SearchLibraryAffirmations(ctx context.Context, keyword string, active bool, limit int) ([]repository.AffirmationLibraryDoc, error) {
	if m.searchLibraryAffirmationsFn != nil {
		return m.searchLibraryAffirmationsFn(ctx, keyword, active, limit)
	}
	return nil, nil
}

func (m *mockAffirmationsRepo) CreateSession(ctx context.Context, session *repository.AffirmationSessionDoc) error {
	return nil
}

func (m *mockAffirmationsRepo) GetSession(ctx context.Context, sessionID string) (*repository.AffirmationSessionDoc, error) {
	if m.getSessionFn != nil {
		return m.getSessionFn(ctx, sessionID)
	}
	return nil, errors.New("not found")
}

func (m *mockAffirmationsRepo) ListSessions(ctx context.Context, userID string, limit int) ([]repository.AffirmationSessionDoc, error) {
	if m.listSessionsFn != nil {
		return m.listSessionsFn(ctx, userID, limit)
	}
	return []repository.AffirmationSessionDoc{}, nil
}

func (m *mockAffirmationsRepo) ListSessionsByTypeAndDateRange(ctx context.Context, userID, sessionType string, startDate, endDate time.Time, limit int) ([]repository.AffirmationSessionDoc, error) {
	return nil, nil
}

func (m *mockAffirmationsRepo) CountSessionsInDateRange(ctx context.Context, userID string, startDate, endDate time.Time) (int64, error) {
	return 0, nil
}

func (m *mockAffirmationsRepo) GetRecentSessionAffirmationIDs(ctx context.Context, userID string, days int) ([]string, error) {
	return nil, nil
}

func (m *mockAffirmationsRepo) GetEveningSessionsByDateRange(ctx context.Context, userID string, startDate, endDate time.Time) ([]repository.AffirmationSessionDoc, error) {
	return nil, nil
}

func (m *mockAffirmationsRepo) GetMorningSessionForDate(ctx context.Context, userID, date string) (*repository.AffirmationSessionDoc, error) {
	return nil, nil
}

func (m *mockAffirmationsRepo) GetSettings(ctx context.Context, userID string) (*repository.AffirmationSettingsDoc, error) {
	if m.getSettingsFn != nil {
		return m.getSettingsFn(ctx, userID)
	}
	return nil, errors.New("not found")
}

func (m *mockAffirmationsRepo) UpsertSettings(ctx context.Context, settings *repository.AffirmationSettingsDoc) error {
	if m.upsertSettingsFn != nil {
		return m.upsertSettingsFn(ctx, settings)
	}
	return nil
}

func (m *mockAffirmationsRepo) GetProgress(ctx context.Context, userID string) (*repository.AffirmationProgressDoc, error) {
	return nil, errors.New("not found")
}

func (m *mockAffirmationsRepo) UpsertProgress(ctx context.Context, progress *repository.AffirmationProgressDoc) error {
	return nil
}

func (m *mockAffirmationsRepo) IncrementSessionCount(ctx context.Context, userID, sessionType string) error {
	return nil
}

func (m *mockAffirmationsRepo) IncrementAffirmationCount(ctx context.Context, userID string, count int) error {
	return nil
}

func (m *mockAffirmationsRepo) RecordMilestone(ctx context.Context, userID, milestoneType string, achievedAt time.Time) error {
	return nil
}

func (m *mockAffirmationsRepo) UpdateLastServedAffirmations(ctx context.Context, userID string, affirmationIDs []string, timestamp time.Time) error {
	return nil
}

func (m *mockAffirmationsRepo) RecordLevelChange(ctx context.Context, userID string, newLevel int, timestamp time.Time) error {
	return nil
}

func (m *mockAffirmationsRepo) AddFavorite(ctx context.Context, userID, affirmationID, tenantID string) error {
	if m.addFavoriteFn != nil {
		return m.addFavoriteFn(ctx, userID, affirmationID, tenantID)
	}
	return nil
}

func (m *mockAffirmationsRepo) RemoveFavorite(ctx context.Context, userID, affirmationID string) error {
	return nil
}

func (m *mockAffirmationsRepo) ListFavorites(ctx context.Context, userID string) ([]repository.AffirmationFavoriteDoc, error) {
	if m.listFavoritesFn != nil {
		return m.listFavoritesFn(ctx, userID)
	}
	return []repository.AffirmationFavoriteDoc{}, nil
}

func (m *mockAffirmationsRepo) IsFavorite(ctx context.Context, userID, affirmationID string) (bool, error) {
	return false, nil
}

func (m *mockAffirmationsRepo) HideAffirmation(ctx context.Context, userID, affirmationID, tenantID string, sessionHideCount int) error {
	return nil
}

func (m *mockAffirmationsRepo) UnhideAffirmation(ctx context.Context, userID, affirmationID string) error {
	return nil
}

func (m *mockAffirmationsRepo) ListHidden(ctx context.Context, userID string) ([]repository.AffirmationHiddenDoc, error) {
	return []repository.AffirmationHiddenDoc{}, nil
}

func (m *mockAffirmationsRepo) IsHidden(ctx context.Context, userID, affirmationID string) (bool, error) {
	return false, nil
}

func (m *mockAffirmationsRepo) CountHiddenInSession(ctx context.Context, userID string, sessionStartTime time.Time) (int64, error) {
	return 0, nil
}

func (m *mockAffirmationsRepo) CreateCustom(ctx context.Context, custom *repository.AffirmationCustomDoc) error {
	if m.createCustomFn != nil {
		return m.createCustomFn(ctx, custom)
	}
	return nil
}

func (m *mockAffirmationsRepo) GetCustom(ctx context.Context, customID string) (*repository.AffirmationCustomDoc, error) {
	return nil, errors.New("not found")
}

func (m *mockAffirmationsRepo) ListCustom(ctx context.Context, userID string) ([]repository.AffirmationCustomDoc, error) {
	return []repository.AffirmationCustomDoc{}, nil
}

func (m *mockAffirmationsRepo) UpdateCustom(ctx context.Context, custom *repository.AffirmationCustomDoc) error {
	return nil
}

func (m *mockAffirmationsRepo) DeleteCustom(ctx context.Context, customID string) error {
	return nil
}

func (m *mockAffirmationsRepo) ToggleRotation(ctx context.Context, customID string, includeInRotation bool) error {
	return nil
}

func (m *mockAffirmationsRepo) SaveAudioMetadata(ctx context.Context, audio *repository.AffirmationAudioDoc) error {
	if m.saveAudioMetadataFn != nil {
		return m.saveAudioMetadataFn(ctx, audio)
	}
	return nil
}

func (m *mockAffirmationsRepo) GetAudioMetadata(ctx context.Context, userID, affirmationID string) (*repository.AffirmationAudioDoc, error) {
	return nil, errors.New("not found")
}

func (m *mockAffirmationsRepo) DeleteAudioMetadata(ctx context.Context, recordingID string) error {
	return nil
}

func (m *mockAffirmationsRepo) ListAudioByUser(ctx context.Context, userID string) ([]repository.AffirmationAudioDoc, error) {
	return nil, nil
}

func (m *mockAffirmationsRepo) WriteCalendarActivity(ctx context.Context, activity *repository.Activity) error {
	return nil
}

type mockPublisher struct{}

func (m *mockPublisher) Publish(ctx context.Context, event events.Event) error {
	return nil
}

// --- Test helpers ---

func makeAuthenticatedRequest(method, path string, body interface{}) *http.Request {
	var reqBody []byte
	if body != nil {
		reqBody, _ = json.Marshal(body)
	}
	req := httptest.NewRequest(method, path, bytes.NewReader(reqBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer dev-token")
	return req
}

func wrapWithMiddleware(mux *http.ServeMux) http.Handler {
	return middleware.CorrelationMiddleware(middleware.AuthMiddleware(mux))
}

// --- Tests ---

func TestHandleBrowseLibrary_Success(t *testing.T) {
	repo := &mockAffirmationsRepo{
		getLibraryAffirmationsFn: func(ctx context.Context, level int, category, track string, active bool, limit int) ([]repository.AffirmationLibraryDoc, error) {
			return []repository.AffirmationLibraryDoc{
				{
					AffirmationID: "aff-1",
					Text:          "I am worthy of love",
					Level:         1,
					Category:      "selfWorth",
					Track:         "standard",
				},
			}, nil
		},
	}

	handler := NewHandler(repo, nil, &mockPublisher{})
	mux := http.NewServeMux()
	handler.RegisterRoutes(mux)
	wrappedHandler := wrapWithMiddleware(mux)

	req := makeAuthenticatedRequest("GET", "/activities/affirmations/library?level=1&track=standard&limit=10", nil)
	rec := httptest.NewRecorder()

	wrappedHandler.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestHandleGetAffirmation_NotFound(t *testing.T) {
	repo := &mockAffirmationsRepo{
		getLibraryAffirmationByIDFn: func(ctx context.Context, affirmationID string) (*repository.AffirmationLibraryDoc, error) {
			return nil, errors.New("not found")
		},
	}

	handler := NewHandler(repo, nil, &mockPublisher{})
	mux := http.NewServeMux()
	handler.RegisterRoutes(mux)
	wrappedHandler := wrapWithMiddleware(mux)

	req := makeAuthenticatedRequest("GET", "/activities/affirmations/library/nonexistent", nil)
	req.SetPathValue("affirmationId", "nonexistent")
	rec := httptest.NewRecorder()

	wrappedHandler.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Errorf("expected status 404, got %d", rec.Code)
	}
}

func TestHandleAddFavorite_Success(t *testing.T) {
	addFavoriteCalled := false

	repo := &mockAffirmationsRepo{
		getLibraryAffirmationByIDFn: func(ctx context.Context, affirmationID string) (*repository.AffirmationLibraryDoc, error) {
			return &repository.AffirmationLibraryDoc{
				AffirmationID: affirmationID,
				Text:          "Test affirmation",
			}, nil
		},
		addFavoriteFn: func(ctx context.Context, userID, affirmationID, tenantID string) error {
			addFavoriteCalled = true
			return nil
		},
	}

	handler := NewHandler(repo, nil, &mockPublisher{})
	mux := http.NewServeMux()
	handler.RegisterRoutes(mux)
	wrappedHandler := wrapWithMiddleware(mux)

	req := makeAuthenticatedRequest("POST", "/activities/affirmations/favorites/aff-1", nil)
	req.SetPathValue("affirmationId", "aff-1")
	rec := httptest.NewRecorder()

	wrappedHandler.ServeHTTP(rec, req)

	if rec.Code != http.StatusNoContent {
		t.Errorf("expected status 204, got %d", rec.Code)
	}

	if !addFavoriteCalled {
		t.Errorf("expected AddFavorite to be called")
	}
}

func TestHandleCreateCustom_ValidationFailure(t *testing.T) {
	repo := &mockAffirmationsRepo{}

	handler := NewHandler(repo, nil, &mockPublisher{})
	mux := http.NewServeMux()
	handler.RegisterRoutes(mux)
	wrappedHandler := wrapWithMiddleware(mux)

	reqBody := CreateCustomAffirmationRequest{
		Text:              "I will be happy tomorrow", // Future tense - should fail
		IncludeInRotation: true,
	}

	req := makeAuthenticatedRequest("POST", "/activities/affirmations/custom", reqBody)
	rec := httptest.NewRecorder()

	wrappedHandler.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected status 400, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestHandleUploadAudio_InvalidFormat(t *testing.T) {
	repo := &mockAffirmationsRepo{}

	handler := NewHandler(repo, nil, &mockPublisher{})
	mux := http.NewServeMux()
	handler.RegisterRoutes(mux)
	wrappedHandler := wrapWithMiddleware(mux)

	reqBody := UploadAudioRequest{
		LocalPath:       "/path/to/audio.mp3",
		Format:          "mp3", // Invalid format - must be m4a
		DurationSeconds: 30,
	}

	req := makeAuthenticatedRequest("POST", "/activities/affirmations/audio/aff-1", reqBody)
	req.SetPathValue("affirmationId", "aff-1")
	rec := httptest.NewRecorder()

	wrappedHandler.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected status 400, got %d", rec.Code)
	}
}

func TestHandleGetSettings_Success(t *testing.T) {
	repo := &mockAffirmationsRepo{
		getSettingsFn: func(ctx context.Context, userID string) (*repository.AffirmationSettingsDoc, error) {
			return &repository.AffirmationSettingsDoc{
				UserID:               userID,
				MorningTime:          "07:00",
				EveningTime:          "21:00",
				Track:                "standard",
				NotificationsEnabled: true,
				UpdatedAt:            time.Now(),
			}, nil
		},
	}

	handler := NewHandler(repo, nil, &mockPublisher{})
	mux := http.NewServeMux()
	handler.RegisterRoutes(mux)
	wrappedHandler := wrapWithMiddleware(mux)

	req := makeAuthenticatedRequest("GET", "/activities/affirmations/settings", nil)
	rec := httptest.NewRecorder()

	wrappedHandler.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", rec.Code)
	}
}
