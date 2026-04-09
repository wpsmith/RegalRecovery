// internal/domain/affirmations/handler.go
package affirmations

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/regalrecovery/api/internal/events"
	"github.com/regalrecovery/api/internal/middleware"
	"github.com/regalrecovery/api/internal/repository"
)

// Handler holds route handlers for affirmation endpoints.
type Handler struct {
	repo   repository.AffirmationsRepository
	cache  CacheInterface // Optional cache
	events events.Publisher
}

// CacheInterface defines the optional cache operations for affirmations.
// This allows the handler to work with or without a cache implementation.
type CacheInterface interface {
	// Invalidate cache entries (implementation-specific)
	Invalidate(ctx context.Context, key string) error
}

// NewHandler creates a new Handler with the given dependencies.
// The cache parameter is optional and can be nil.
func NewHandler(repo repository.AffirmationsRepository, cache CacheInterface, events events.Publisher) *Handler {
	return &Handler{
		repo:   repo,
		cache:  cache,
		events: events,
	}
}

// RegisterRoutes registers all affirmation routes on the given mux.
func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	// Sessions
	mux.HandleFunc("POST /activities/affirmations/sessions/morning", h.HandleCreateMorningSession)
	mux.HandleFunc("POST /activities/affirmations/sessions/evening", h.HandleCreateEveningSession)
	mux.HandleFunc("POST /activities/affirmations/sos", h.HandleStartSOSSession)
	mux.HandleFunc("GET /activities/affirmations/sessions", h.HandleListSessions)
	mux.HandleFunc("GET /activities/affirmations/sessions/{sessionId}", h.HandleGetSession)

	// Library
	mux.HandleFunc("GET /activities/affirmations/library", h.HandleBrowseLibrary)
	mux.HandleFunc("GET /activities/affirmations/library/{affirmationId}", h.HandleGetAffirmation)
	mux.HandleFunc("GET /activities/affirmations/library/search", h.HandleSearchLibrary)

	// Favorites
	mux.HandleFunc("POST /activities/affirmations/favorites/{affirmationId}", h.HandleAddFavorite)
	mux.HandleFunc("DELETE /activities/affirmations/favorites/{affirmationId}", h.HandleRemoveFavorite)
	mux.HandleFunc("GET /activities/affirmations/favorites", h.HandleListFavorites)

	// Hidden
	mux.HandleFunc("POST /activities/affirmations/hidden/{affirmationId}", h.HandleHideAffirmation)
	mux.HandleFunc("DELETE /activities/affirmations/hidden/{affirmationId}", h.HandleUnhideAffirmation)
	mux.HandleFunc("GET /activities/affirmations/hidden", h.HandleListHidden)

	// Custom
	mux.HandleFunc("POST /activities/affirmations/custom", h.HandleCreateCustom)
	mux.HandleFunc("GET /activities/affirmations/custom", h.HandleListCustom)
	mux.HandleFunc("GET /activities/affirmations/custom/{customId}", h.HandleGetCustom)
	mux.HandleFunc("PUT /activities/affirmations/custom/{customId}", h.HandleUpdateCustom)
	mux.HandleFunc("DELETE /activities/affirmations/custom/{customId}", h.HandleDeleteCustom)
	mux.HandleFunc("PATCH /activities/affirmations/custom/{customId}/rotation", h.HandleToggleRotation)

	// Audio (place before other routes to avoid conflicts)
	mux.HandleFunc("POST /activities/affirmations/audio/{affirmationId}", h.HandleUploadAudio)
	mux.HandleFunc("GET /activities/affirmations/audio/{affirmationId}", h.HandleGetAudio)
	mux.HandleFunc("DELETE /activities/affirmations/audio/{affirmationId}", h.HandleDeleteAudio)

	// Progress
	mux.HandleFunc("GET /activities/affirmations/progress", h.HandleGetProgress)
	mux.HandleFunc("GET /activities/affirmations/progress/milestones", h.HandleGetMilestones)

	// Settings
	mux.HandleFunc("GET /activities/affirmations/settings", h.HandleGetSettings)
	mux.HandleFunc("PATCH /activities/affirmations/settings", h.HandleUpdateSettings)

	// Level
	mux.HandleFunc("GET /activities/affirmations/level", h.HandleGetLevel)
}

// --- Session handlers ---

// HandleCreateMorningSession handles POST /activities/affirmations/sessions/morning.
func (h *Handler) HandleCreateMorningSession(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	_ = middleware.GetTenantID(r.Context()) // tenantID for future use
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	var req CreateMorningSessionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x000A000A", "Invalid request body: "+err.Error())
		return
	}

	// TODO: Call domain logic to create morning session
	// This would involve:
	// 1. Get user settings and progress
	// 2. Determine level
	// 3. Select 3 affirmations using ContentSelector
	// 4. Create session record
	// 5. Update progress
	// 6. Write calendar activity
	// 7. Publish event

	writeError(w, http.StatusNotImplemented, "rr:0x50010001", "Not yet implemented")
}

// HandleCreateEveningSession handles POST /activities/affirmations/sessions/evening.
func (h *Handler) HandleCreateEveningSession(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	_ = middleware.GetTenantID(r.Context()) // tenantID for future use
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	var req CreateEveningSessionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x000A000A", "Invalid request body: "+err.Error())
		return
	}

	// TODO: Call domain logic to create evening session
	// Similar to morning session but with 1 affirmation and evening-specific fields

	writeError(w, http.StatusNotImplemented, "rr:0x50010001", "Not yet implemented")
}

// HandleStartSOSSession handles POST /activities/affirmations/sos.
func (h *Handler) HandleStartSOSSession(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	_ = middleware.GetTenantID(r.Context()) // tenantID for future use
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	var req CreateSOSSessionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x000A000A", "Invalid request body: "+err.Error())
		return
	}

	// TODO: Call domain logic to create SOS session
	// Must restrict to Level 1-2 only

	writeError(w, http.StatusNotImplemented, "rr:0x50010001", "Not yet implemented")
}

// HandleListSessions handles GET /activities/affirmations/sessions.
func (h *Handler) HandleListSessions(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	// Parse query parameters
	_ = r.URL.Query().Get("cursor")      // cursor for future pagination use
	limitStr := r.URL.Query().Get("limit")
	_ = r.URL.Query().Get("type")        // sessionType for future filtering

	limit := 50
	if limitStr != "" {
		if parsed, err := strconv.Atoi(limitStr); err == nil && parsed > 0 && parsed <= 100 {
			limit = parsed
		}
	}

	// TODO: Query sessions from repository with pagination
	sessions, err := h.repo.ListSessions(r.Context(), userID, limit)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	// Convert to response format
	data := make([]map[string]interface{}, 0, len(sessions))
	for _, s := range sessions {
		data = append(data, map[string]interface{}{
			"sessionId":   s.SessionID,
			"sessionType": s.SessionType,
			"levelServed": s.LevelServed,
			"completedAt": s.CompletedAt,
			"skipped":     s.Skipped,
		})
	}

	links := map[string]string{
		"self": r.URL.String(),
	}
	// TODO: Add next cursor if more results available

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data":  data,
		"links": links,
		"meta": map[string]interface{}{
			"count": len(data),
		},
	})
}

// HandleGetSession handles GET /activities/affirmations/sessions/{sessionId}.
func (h *Handler) HandleGetSession(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	sessionID := r.PathValue("sessionId")
	if sessionID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000A0001", "Session ID is required")
		return
	}

	session, err := h.repo.GetSession(r.Context(), sessionID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	// Verify user owns this session
	if session.UserID != userID {
		writeError(w, http.StatusForbidden, "rr:0x40310001", "Access denied")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": session,
	})
}

// --- Library handlers ---

// HandleBrowseLibrary handles GET /activities/affirmations/library.
func (h *Handler) HandleBrowseLibrary(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	// Parse query parameters
	levelStr := r.URL.Query().Get("level")
	category := r.URL.Query().Get("category")
	track := r.URL.Query().Get("track")
	limitStr := r.URL.Query().Get("limit")

	level := 1
	if levelStr != "" {
		if parsed, err := strconv.Atoi(levelStr); err == nil && parsed >= 1 && parsed <= 4 {
			level = parsed
		}
	}

	limit := 50
	if limitStr != "" {
		if parsed, err := strconv.Atoi(limitStr); err == nil && parsed > 0 && parsed <= 100 {
			limit = parsed
		}
	}

	if track == "" {
		track = "standard"
	}

	affirmations, err := h.repo.GetLibraryAffirmations(r.Context(), level, category, track, true, limit)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": affirmations,
		"meta": map[string]interface{}{
			"count": len(affirmations),
			"level": level,
			"track": track,
		},
	})
}

// HandleGetAffirmation handles GET /activities/affirmations/library/{affirmationId}.
func (h *Handler) HandleGetAffirmation(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	affirmationID := r.PathValue("affirmationId")
	if affirmationID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000A0001", "Affirmation ID is required")
		return
	}

	affirmation, err := h.repo.GetLibraryAffirmationByID(r.Context(), affirmationID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": affirmation,
	})
}

// HandleSearchLibrary handles GET /activities/affirmations/library/search.
func (h *Handler) HandleSearchLibrary(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	keyword := r.URL.Query().Get("keyword")
	if keyword == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000A0001", "Keyword parameter is required")
		return
	}

	limitStr := r.URL.Query().Get("limit")
	limit := 50
	if limitStr != "" {
		if parsed, err := strconv.Atoi(limitStr); err == nil && parsed > 0 && parsed <= 100 {
			limit = parsed
		}
	}

	results, err := h.repo.SearchLibraryAffirmations(r.Context(), keyword, true, limit)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": results,
		"meta": map[string]interface{}{
			"count":   len(results),
			"keyword": keyword,
		},
	})
}

// --- Favorites handlers ---

// HandleAddFavorite handles POST /activities/affirmations/favorites/{affirmationId}.
func (h *Handler) HandleAddFavorite(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	tenantID := middleware.GetTenantID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	affirmationID := r.PathValue("affirmationId")
	if affirmationID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000A0001", "Affirmation ID is required")
		return
	}

	// Verify affirmation exists
	_, err := h.repo.GetLibraryAffirmationByID(r.Context(), affirmationID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	// Add to favorites
	if err := h.repo.AddFavorite(r.Context(), userID, affirmationID, tenantID); err != nil {
		writeServiceError(w, err)
		return
	}

	// Invalidate cache if available
	if h.cache != nil {
		_ = h.cache.Invalidate(r.Context(), fmt.Sprintf("favorites:%s", userID))
	}

	w.WriteHeader(http.StatusNoContent)
}

// HandleRemoveFavorite handles DELETE /activities/affirmations/favorites/{affirmationId}.
func (h *Handler) HandleRemoveFavorite(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	affirmationID := r.PathValue("affirmationId")
	if affirmationID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000A0001", "Affirmation ID is required")
		return
	}

	if err := h.repo.RemoveFavorite(r.Context(), userID, affirmationID); err != nil {
		writeServiceError(w, err)
		return
	}

	// Invalidate cache if available
	if h.cache != nil {
		_ = h.cache.Invalidate(r.Context(), fmt.Sprintf("favorites:%s", userID))
	}

	w.WriteHeader(http.StatusNoContent)
}

// HandleListFavorites handles GET /activities/affirmations/favorites.
func (h *Handler) HandleListFavorites(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	favorites, err := h.repo.ListFavorites(r.Context(), userID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": favorites,
		"meta": map[string]interface{}{
			"count": len(favorites),
		},
	})
}

// --- Hidden handlers ---

// HandleHideAffirmation handles POST /activities/affirmations/hidden/{affirmationId}.
func (h *Handler) HandleHideAffirmation(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	tenantID := middleware.GetTenantID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	affirmationID := r.PathValue("affirmationId")
	if affirmationID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000A0001", "Affirmation ID is required")
		return
	}

	// Parse request body for session hide count
	var req struct {
		SessionHideCount int `json:"sessionHideCount"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		req.SessionHideCount = 0
	}

	// Verify affirmation exists
	_, err := h.repo.GetLibraryAffirmationByID(r.Context(), affirmationID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	// Hide affirmation
	if err := h.repo.HideAffirmation(r.Context(), userID, affirmationID, tenantID, req.SessionHideCount); err != nil {
		writeServiceError(w, err)
		return
	}

	// Invalidate cache if available
	if h.cache != nil {
		_ = h.cache.Invalidate(r.Context(), fmt.Sprintf("hidden:%s", userID))
	}

	w.WriteHeader(http.StatusNoContent)
}

// HandleUnhideAffirmation handles DELETE /activities/affirmations/hidden/{affirmationId}.
func (h *Handler) HandleUnhideAffirmation(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	affirmationID := r.PathValue("affirmationId")
	if affirmationID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000A0001", "Affirmation ID is required")
		return
	}

	if err := h.repo.UnhideAffirmation(r.Context(), userID, affirmationID); err != nil {
		writeServiceError(w, err)
		return
	}

	// Invalidate cache if available
	if h.cache != nil {
		_ = h.cache.Invalidate(r.Context(), fmt.Sprintf("hidden:%s", userID))
	}

	w.WriteHeader(http.StatusNoContent)
}

// HandleListHidden handles GET /activities/affirmations/hidden.
func (h *Handler) HandleListHidden(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	hidden, err := h.repo.ListHidden(r.Context(), userID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": hidden,
		"meta": map[string]interface{}{
			"count": len(hidden),
		},
	})
}

// --- Custom affirmation handlers ---

// HandleCreateCustom handles POST /activities/affirmations/custom.
func (h *Handler) HandleCreateCustom(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	tenantID := middleware.GetTenantID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	var req CreateCustomAffirmationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x000A0002", "Invalid request body: "+err.Error())
		return
	}

	// Validate custom affirmation text
	// TODO: Get actual sobriety days from user's addiction tracking data
	sobrietyDays := 14 // Temporary placeholder
	validationResult := ValidateCustomStatement(req.Text, sobrietyDays)
	if !validationResult.Valid {
		writeError(w, http.StatusBadRequest, "rr:0x000A0002", strings.Join(validationResult.Errors, "; "))
		return
	}

	// Create custom affirmation document
	now := time.Now()
	custom := &repository.AffirmationCustomDoc{
		CustomID:          generateID(),
		UserID:            userID,
		Text:              req.Text,
		IncludeInRotation: req.IncludeInRotation,
		UpdatedAt:         now,
	}
	custom.CreatedAt = now
	custom.ModifiedAt = now
	custom.TenantID = tenantID

	if err := h.repo.CreateCustom(r.Context(), custom); err != nil {
		writeServiceError(w, err)
		return
	}

	// Update progress count
	_ = h.repo.IncrementSessionCount(r.Context(), userID, "custom_created")

	w.Header().Set("Location", fmt.Sprintf("/activities/affirmations/custom/%s", custom.CustomID))
	writeJSON(w, http.StatusCreated, map[string]interface{}{
		"data": custom,
		"meta": map[string]interface{}{"created": true},
	})
}

// HandleListCustom handles GET /activities/affirmations/custom.
func (h *Handler) HandleListCustom(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	customs, err := h.repo.ListCustom(r.Context(), userID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": customs,
		"meta": map[string]interface{}{
			"count": len(customs),
		},
	})
}

// HandleGetCustom handles GET /activities/affirmations/custom/{customId}.
func (h *Handler) HandleGetCustom(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	customID := r.PathValue("customId")
	if customID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000A0001", "Custom ID is required")
		return
	}

	custom, err := h.repo.GetCustom(r.Context(), customID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	// Verify user owns this custom affirmation
	if custom.UserID != userID {
		writeError(w, http.StatusForbidden, "rr:0x40310001", "Access denied")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": custom,
	})
}

// HandleUpdateCustom handles PUT /activities/affirmations/custom/{customId}.
func (h *Handler) HandleUpdateCustom(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	customID := r.PathValue("customId")
	if customID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000A0001", "Custom ID is required")
		return
	}

	// Fetch existing custom affirmation
	custom, err := h.repo.GetCustom(r.Context(), customID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	// Verify user owns this custom affirmation
	if custom.UserID != userID {
		writeError(w, http.StatusForbidden, "rr:0x40310001", "Access denied")
		return
	}

	var req UpdateCustomAffirmationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x000A0002", "Invalid request body: "+err.Error())
		return
	}

	// Validate new text
	// TODO: Get actual sobriety days from user's addiction tracking data
	sobrietyDays := 14 // Temporary placeholder
	validationResult := ValidateCustomStatement(req.Text, sobrietyDays)
	if !validationResult.Valid {
		writeError(w, http.StatusBadRequest, "rr:0x000A0002", strings.Join(validationResult.Errors, "; "))
		return
	}

	// Update fields
	custom.Text = req.Text
	custom.IncludeInRotation = req.IncludeInRotation
	custom.UpdatedAt = time.Now()
	custom.ModifiedAt = time.Now()

	if err := h.repo.UpdateCustom(r.Context(), custom); err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": custom,
	})
}

// HandleDeleteCustom handles DELETE /activities/affirmations/custom/{customId}.
func (h *Handler) HandleDeleteCustom(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	customID := r.PathValue("customId")
	if customID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000A0001", "Custom ID is required")
		return
	}

	// Verify ownership before deleting
	custom, err := h.repo.GetCustom(r.Context(), customID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	if custom.UserID != userID {
		writeError(w, http.StatusForbidden, "rr:0x40310001", "Access denied")
		return
	}

	if err := h.repo.DeleteCustom(r.Context(), customID); err != nil {
		writeServiceError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// HandleToggleRotation handles PATCH /activities/affirmations/custom/{customId}/rotation.
func (h *Handler) HandleToggleRotation(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	customID := r.PathValue("customId")
	if customID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000A0001", "Custom ID is required")
		return
	}

	// Verify ownership
	custom, err := h.repo.GetCustom(r.Context(), customID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	if custom.UserID != userID {
		writeError(w, http.StatusForbidden, "rr:0x40310001", "Access denied")
		return
	}

	var req struct {
		IncludeInRotation bool `json:"includeInRotation"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x000A0002", "Invalid request body: "+err.Error())
		return
	}

	if err := h.repo.ToggleRotation(r.Context(), customID, req.IncludeInRotation); err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": map[string]interface{}{
			"customId":          customID,
			"includeInRotation": req.IncludeInRotation,
		},
	})
}

// --- Audio handlers ---

// HandleUploadAudio handles POST /activities/affirmations/{affirmationId}/audio.
func (h *Handler) HandleUploadAudio(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	tenantID := middleware.GetTenantID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	affirmationID := r.PathValue("affirmationId")
	if affirmationID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000A0001", "Affirmation ID is required")
		return
	}

	var req UploadAudioRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x000A0004", "Invalid request body: "+err.Error())
		return
	}

	// Validate audio metadata
	if err := ValidateAudioRecording(req.DurationSeconds, req.Format); err != nil {
		if errors.Is(err, ErrInvalidAudioFormat) {
			writeError(w, http.StatusBadRequest, "rr:0x000A0004", err.Error())
		} else if errors.Is(err, ErrAudioDurationExceeded) {
			writeError(w, http.StatusBadRequest, "rr:0x000A0005", err.Error())
		} else {
			writeError(w, http.StatusBadRequest, "rr:0x000A0004", err.Error())
		}
		return
	}

	// Create audio metadata record
	now := time.Now()
	audio := &repository.AffirmationAudioDoc{
		RecordingID:      generateID(),
		UserID:           userID,
		AffirmationID:    affirmationID,
		LocalPath:        req.LocalPath,
		Format:           req.Format,
		DurationSeconds:  req.DurationSeconds,
		BackgroundMusic:  req.BackgroundMusic,
		BackgroundVolume: req.BackgroundVolume,
	}
	audio.CreatedAt = now
	audio.ModifiedAt = now
	audio.TenantID = tenantID

	if err := h.repo.SaveAudioMetadata(r.Context(), audio); err != nil {
		writeServiceError(w, err)
		return
	}

	w.Header().Set("Location", fmt.Sprintf("/activities/affirmations/%s/audio", affirmationID))
	writeJSON(w, http.StatusCreated, map[string]interface{}{
		"data": audio,
		"meta": map[string]interface{}{"created": true},
	})
}

// HandleGetAudio handles GET /activities/affirmations/{affirmationId}/audio.
func (h *Handler) HandleGetAudio(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	affirmationID := r.PathValue("affirmationId")
	if affirmationID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000A0001", "Affirmation ID is required")
		return
	}

	audio, err := h.repo.GetAudioMetadata(r.Context(), userID, affirmationID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": audio,
	})
}

// HandleDeleteAudio handles DELETE /activities/affirmations/{affirmationId}/audio.
func (h *Handler) HandleDeleteAudio(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	affirmationID := r.PathValue("affirmationId")
	if affirmationID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000A0001", "Affirmation ID is required")
		return
	}

	// Get audio to verify ownership and get recording ID
	audio, err := h.repo.GetAudioMetadata(r.Context(), userID, affirmationID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	// Delete audio metadata
	if err := h.repo.DeleteAudioMetadata(r.Context(), audio.RecordingID); err != nil {
		writeServiceError(w, err)
		return
	}

	// TODO: Also delete the actual audio file from storage (S3)

	w.WriteHeader(http.StatusNoContent)
}

// --- Progress handlers ---

// HandleGetProgress handles GET /activities/affirmations/progress.
func (h *Handler) HandleGetProgress(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	progress, err := h.repo.GetProgress(r.Context(), userID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": progress,
	})
}

// HandleGetMilestones handles GET /activities/affirmations/progress/milestones.
func (h *Handler) HandleGetMilestones(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	progress, err := h.repo.GetProgress(r.Context(), userID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": progress.Milestones,
		"meta": map[string]interface{}{
			"count": len(progress.Milestones),
		},
	})
}

// --- Settings handlers ---

// HandleGetSettings handles GET /activities/affirmations/settings.
func (h *Handler) HandleGetSettings(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	settings, err := h.repo.GetSettings(r.Context(), userID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": settings,
	})
}

// HandleUpdateSettings handles PATCH /activities/affirmations/settings.
func (h *Handler) HandleUpdateSettings(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	tenantID := middleware.GetTenantID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	// Get existing settings
	settings, err := h.repo.GetSettings(r.Context(), userID)
	if err != nil {
		// If not found, create default settings
		settings = &repository.AffirmationSettingsDoc{
			UserID:                   userID,
			TenantID:                 tenantID,
			MorningTime:              "07:00",
			EveningTime:              "21:00",
			Track:                    "standard",
			EnabledCategories:        []string{},
			HealthySexualityEnabled:  false,
			NotificationsEnabled:     true,
			ReEngagementEnabled:      true,
			AudioAutoPlay:            false,
			UpdatedAt:                time.Now(),
		}
	}

	// Parse partial update (JSON Merge Patch - RFC 7396)
	var patch map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&patch); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x000A0009", "Invalid request body: "+err.Error())
		return
	}

	// Apply patch to settings
	if val, ok := patch["morningTime"]; ok {
		if str, ok := val.(string); ok {
			settings.MorningTime = str
		}
	}
	if val, ok := patch["eveningTime"]; ok {
		if str, ok := val.(string); ok {
			settings.EveningTime = str
		}
	}
	if val, ok := patch["track"]; ok {
		if str, ok := val.(string); ok {
			settings.Track = str
		}
	}
	if val, ok := patch["levelOverride"]; ok {
		if num, ok := val.(float64); ok {
			level := int(num)
			settings.LevelOverride = &level
		}
	}
	if val, ok := patch["healthySexualityEnabled"]; ok {
		if b, ok := val.(bool); ok {
			settings.HealthySexualityEnabled = b
		}
	}
	if val, ok := patch["notificationsEnabled"]; ok {
		if b, ok := val.(bool); ok {
			settings.NotificationsEnabled = b
		}
	}
	if val, ok := patch["reEngagementEnabled"]; ok {
		if b, ok := val.(bool); ok {
			settings.ReEngagementEnabled = b
		}
	}
	if val, ok := patch["audioAutoPlay"]; ok {
		if b, ok := val.(bool); ok {
			settings.AudioAutoPlay = b
		}
	}

	settings.UpdatedAt = time.Now()

	// Upsert settings
	if err := h.repo.UpsertSettings(r.Context(), settings); err != nil {
		writeServiceError(w, err)
		return
	}

	// Invalidate cache if available
	if h.cache != nil {
		_ = h.cache.Invalidate(r.Context(), fmt.Sprintf("settings:%s", userID))
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": settings,
	})
}

// --- Level handler ---

// HandleGetLevel handles GET /activities/affirmations/level.
func (h *Handler) HandleGetLevel(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	// TODO: Get user sobriety data and settings to determine level
	// This would call LevelEngine to compute the current level

	writeError(w, http.StatusNotImplemented, "rr:0x50010001", "Not yet implemented")
}

// --- Request/Response types ---

// CreateMorningSessionRequest represents the request body for creating a morning session.
type CreateMorningSessionRequest struct {
	Intention string `json:"intention"`
	Skipped   bool   `json:"skipped"`
}

// CreateEveningSessionRequest represents the request body for creating an evening session.
type CreateEveningSessionRequest struct {
	DayRating  int    `json:"dayRating"`
	Reflection string `json:"reflection,omitempty"`
}

// CreateSOSSessionRequest represents the request body for creating an SOS session.
type CreateSOSSessionRequest struct {
	BreathingCompleted  bool   `json:"breathingCompleted"`
	ReachedOut          bool   `json:"reachedOut"`
	PostCheckInRating   *int   `json:"postCheckInRating,omitempty"`
}

// CreateCustomAffirmationRequest represents the request body for creating a custom affirmation.
type CreateCustomAffirmationRequest struct {
	Text              string `json:"text"`
	IncludeInRotation bool   `json:"includeInRotation"`
}

// UpdateCustomAffirmationRequest represents the request body for updating a custom affirmation.
type UpdateCustomAffirmationRequest struct {
	Text              string `json:"text"`
	IncludeInRotation bool   `json:"includeInRotation"`
}

// UploadAudioRequest represents the request body for uploading audio metadata.
type UploadAudioRequest struct {
	LocalPath        string  `json:"localPath"`
	Format           string  `json:"format"`
	DurationSeconds  int     `json:"durationSeconds"`
	BackgroundMusic  string  `json:"backgroundMusic"`
	BackgroundVolume float64 `json:"backgroundVolume"`
}

// --- Response helpers ---

// errorResponse is the standard error envelope per Siemens REST API Guidelines.
type errorResponse struct {
	Errors []apiError `json:"errors"`
}

type apiError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

func writeJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

func writeError(w http.ResponseWriter, status int, code string, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(errorResponse{
		Errors: []apiError{{Code: code, Message: message}},
	})
}

func writeServiceError(w http.ResponseWriter, err error) {
	switch {
	case strings.Contains(err.Error(), "not found"):
		writeError(w, http.StatusNotFound, "rr:0x000A0001", err.Error())
	case errors.Is(err, ErrInvalidLevel), errors.Is(err, ErrInvalidCategory), errors.Is(err, ErrInvalidTrack):
		writeError(w, http.StatusBadRequest, "rr:0x000A0002", err.Error())
	case errors.Is(err, ErrInsufficientSobriety):
		writeError(w, http.StatusForbidden, "rr:0x000A0003", err.Error())
	case errors.Is(err, ErrHealthySexualityNotGated):
		writeError(w, http.StatusForbidden, "rr:0x000A0007", err.Error())
	case errors.Is(err, ErrNoContentAvailable):
		writeError(w, http.StatusNotFound, "rr:0x000A0001", err.Error())
	default:
		writeError(w, http.StatusInternalServerError, "rr:0x50010001", "Internal server error")
	}
}

// generateID generates a unique ID for affirmation entities.
// In production, this would use a more robust ID generation strategy (UUID, ULID, etc.).
func generateID() string {
	return fmt.Sprintf("aff_%d", time.Now().UnixNano())
}
