// internal/domain/exercise/handler.go
package exercise

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/regalrecovery/api/internal/middleware"
)

// Handler holds route handlers for the exercise endpoints.
type Handler struct {
	service *ExerciseService
}

// NewHandler creates a new Handler with the given service.
func NewHandler(service *ExerciseService) *Handler {
	return &Handler{service: service}
}

// RegisterRoutes registers exercise routes on the given mux.
func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("POST /v1/activities/exercise", h.HandleCreateExerciseLog)
	mux.HandleFunc("GET /v1/activities/exercise", h.HandleListExerciseLogs)
	mux.HandleFunc("GET /v1/activities/exercise/{exerciseId}", h.HandleGetExerciseLog)
	mux.HandleFunc("PATCH /v1/activities/exercise/{exerciseId}", h.HandleUpdateExerciseLog)
	mux.HandleFunc("DELETE /v1/activities/exercise/{exerciseId}", h.HandleDeleteExerciseLog)

	mux.HandleFunc("GET /v1/activities/exercise/favorites", h.HandleListFavorites)
	mux.HandleFunc("POST /v1/activities/exercise/favorites", h.HandleCreateFavorite)
	mux.HandleFunc("PUT /v1/activities/exercise/favorites/{favoriteId}", h.HandleUpdateFavorite)
	mux.HandleFunc("DELETE /v1/activities/exercise/favorites/{favoriteId}", h.HandleDeleteFavorite)

	mux.HandleFunc("GET /v1/activities/exercise/stats", h.HandleGetStats)
	mux.HandleFunc("GET /v1/activities/exercise/streak", h.HandleGetStreak)
	mux.HandleFunc("GET /v1/activities/exercise/correlations", h.HandleGetCorrelations)

	mux.HandleFunc("GET /v1/activities/exercise/goals", h.HandleGetGoal)
	mux.HandleFunc("PUT /v1/activities/exercise/goals", h.HandleSetGoal)
	mux.HandleFunc("DELETE /v1/activities/exercise/goals", h.HandleDeleteGoal)

	mux.HandleFunc("GET /v1/activities/exercise/widget", h.HandleGetWidget)
}

// --- CRUD Handlers ---

// HandleCreateExerciseLog handles POST /v1/activities/exercise.
func (h *Handler) HandleCreateExerciseLog(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeExerciseError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}
	tenantID := middleware.GetTenantID(r.Context())

	var req createExerciseLogJSON
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeExerciseError(w, http.StatusBadRequest, "rr:0x40010011", "Invalid request body: "+err.Error())
		return
	}

	domainReq := req.toDomainRequest()

	log, err := h.service.CreateExerciseLog(r.Context(), userID, tenantID, domainReq)
	if err != nil {
		writeExerciseServiceError(w, err)
		return
	}

	// Include streak in create response.
	streak, _ := h.service.GetStreak(r.Context(), userID, nil)

	w.Header().Set("Location", fmt.Sprintf("/v1/activities/exercise/%s", log.ExerciseID))
	writeExerciseJSON(w, http.StatusCreated, exerciseLogResponse{
		Data: exerciseLogWithStreak{
			exerciseLogJSON: toExerciseLogJSON(log),
			ExerciseStreak:  toStreakSummaryJSON(streak),
		},
		Meta: metaJSON{CreatedAt: log.CreatedAt.Format(time.RFC3339)},
	})
}

// HandleListExerciseLogs handles GET /v1/activities/exercise.
func (h *Handler) HandleListExerciseLogs(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeExerciseError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	opts := parseListOptions(r)

	logs, cursor, err := h.service.ListExerciseLogs(r.Context(), userID, opts)
	if err != nil {
		writeExerciseServiceError(w, err)
		return
	}

	data := make([]exerciseLogJSON, len(logs))
	for i := range logs {
		data[i] = toExerciseLogJSON(&logs[i])
	}

	var nextCursor *string
	if cursor != "" {
		nextCursor = &cursor
	}

	writeExerciseJSON(w, http.StatusOK, exerciseLogListResponse{
		Data: data,
		Links: paginationLinksJSON{
			Self: r.URL.String(),
		},
		Meta: pageMetaJSON{
			Page: pageInfoJSON{
				NextCursor: nextCursor,
				Limit:      opts.Limit,
			},
		},
	})
}

// HandleGetExerciseLog handles GET /v1/activities/exercise/{exerciseId}.
func (h *Handler) HandleGetExerciseLog(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeExerciseError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	exerciseID := r.PathValue("exerciseId")
	if exerciseID == "" {
		writeExerciseError(w, http.StatusBadRequest, "rr:0x40010014", "Exercise ID is required")
		return
	}

	log, err := h.service.GetExerciseLog(r.Context(), userID, exerciseID)
	if err != nil {
		writeExerciseServiceError(w, err)
		return
	}

	writeExerciseJSON(w, http.StatusOK, singleExerciseLogResponse{
		Data: toExerciseLogJSON(log),
		Meta: metaJSON{RetrievedAt: time.Now().UTC().Format(time.RFC3339)},
	})
}

// HandleUpdateExerciseLog handles PATCH /v1/activities/exercise/{exerciseId}.
func (h *Handler) HandleUpdateExerciseLog(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeExerciseError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	exerciseID := r.PathValue("exerciseId")
	if exerciseID == "" {
		writeExerciseError(w, http.StatusBadRequest, "rr:0x40010014", "Exercise ID is required")
		return
	}

	// Decode raw JSON to check for immutable field violations.
	var rawJSON map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&rawJSON); err != nil {
		writeExerciseError(w, http.StatusBadRequest, "rr:0x40010011", "Invalid request body: "+err.Error())
		return
	}

	if err := CheckImmutableFieldViolation(rawJSON); err != nil {
		writeExerciseError(w, http.StatusUnprocessableEntity, "rr:0x42200001", err.Error())
		return
	}

	// Build domain update request from raw JSON.
	req := buildUpdateRequest(rawJSON)

	log, err := h.service.UpdateExerciseLog(r.Context(), userID, exerciseID, req)
	if err != nil {
		writeExerciseServiceError(w, err)
		return
	}

	writeExerciseJSON(w, http.StatusOK, singleExerciseLogResponse{
		Data: toExerciseLogJSON(log),
		Meta: metaJSON{ModifiedAt: log.ModifiedAt.Format(time.RFC3339)},
	})
}

// HandleDeleteExerciseLog handles DELETE /v1/activities/exercise/{exerciseId}.
func (h *Handler) HandleDeleteExerciseLog(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeExerciseError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	exerciseID := r.PathValue("exerciseId")
	if exerciseID == "" {
		writeExerciseError(w, http.StatusBadRequest, "rr:0x40010014", "Exercise ID is required")
		return
	}

	if err := h.service.DeleteExerciseLog(r.Context(), userID, exerciseID); err != nil {
		writeExerciseServiceError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// --- Favorites Handlers ---

// HandleListFavorites handles GET /v1/activities/exercise/favorites.
func (h *Handler) HandleListFavorites(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeExerciseError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	favs, err := h.service.ListFavorites(r.Context(), userID)
	if err != nil {
		writeExerciseServiceError(w, err)
		return
	}

	data := make([]favoriteJSON, len(favs))
	for i := range favs {
		data[i] = toFavoriteJSON(&favs[i])
	}

	writeExerciseJSON(w, http.StatusOK, favoriteListResponse{
		Data: data,
		Meta: metaJSON{RetrievedAt: time.Now().UTC().Format(time.RFC3339)},
	})
}

// HandleCreateFavorite handles POST /v1/activities/exercise/favorites.
func (h *Handler) HandleCreateFavorite(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeExerciseError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}
	tenantID := middleware.GetTenantID(r.Context())

	var req createFavoriteJSON
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeExerciseError(w, http.StatusBadRequest, "rr:0x40010011", "Invalid request body: "+err.Error())
		return
	}

	fav, err := h.service.CreateFavorite(r.Context(), userID, tenantID, req.toDomainFavorite())
	if err != nil {
		writeExerciseServiceError(w, err)
		return
	}

	writeExerciseJSON(w, http.StatusCreated, favoriteResponse{
		Data: toFavoriteJSON(fav),
		Meta: metaJSON{CreatedAt: fav.CreatedAt.Format(time.RFC3339)},
	})
}

// HandleUpdateFavorite handles PUT /v1/activities/exercise/favorites/{favoriteId}.
func (h *Handler) HandleUpdateFavorite(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeExerciseError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	favoriteID := r.PathValue("favoriteId")
	if favoriteID == "" {
		writeExerciseError(w, http.StatusBadRequest, "rr:0x40010014", "Favorite ID is required")
		return
	}

	var req createFavoriteJSON
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeExerciseError(w, http.StatusBadRequest, "rr:0x40010011", "Invalid request body: "+err.Error())
		return
	}

	fav, err := h.service.UpdateFavorite(r.Context(), userID, favoriteID, req.toDomainFavorite())
	if err != nil {
		writeExerciseServiceError(w, err)
		return
	}

	writeExerciseJSON(w, http.StatusOK, favoriteResponse{
		Data: toFavoriteJSON(fav),
		Meta: metaJSON{ModifiedAt: fav.ModifiedAt.Format(time.RFC3339)},
	})
}

// HandleDeleteFavorite handles DELETE /v1/activities/exercise/favorites/{favoriteId}.
func (h *Handler) HandleDeleteFavorite(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeExerciseError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	favoriteID := r.PathValue("favoriteId")
	if favoriteID == "" {
		writeExerciseError(w, http.StatusBadRequest, "rr:0x40010014", "Favorite ID is required")
		return
	}

	if err := h.service.DeleteFavorite(r.Context(), userID, favoriteID); err != nil {
		writeExerciseServiceError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// --- Stats, Streak, Correlations Handlers ---

// HandleGetStats handles GET /v1/activities/exercise/stats.
func (h *Handler) HandleGetStats(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeExerciseError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	period := r.URL.Query().Get("period")
	if period == "" {
		writeExerciseError(w, http.StatusBadRequest, "rr:0x40010020", "Query parameter 'period' is required")
		return
	}

	refDateStr := r.URL.Query().Get("referenceDate")
	var refDate time.Time
	if refDateStr != "" {
		var err error
		refDate, err = time.Parse("2006-01-02", refDateStr)
		if err != nil {
			writeExerciseError(w, http.StatusBadRequest, "rr:0x40010021", "Invalid referenceDate format, expected YYYY-MM-DD")
			return
		}
	} else {
		refDate = time.Now().UTC()
	}

	stats, err := h.service.GetStats(r.Context(), userID, period, refDate)
	if err != nil {
		writeExerciseServiceError(w, err)
		return
	}

	writeExerciseJSON(w, http.StatusOK, map[string]interface{}{
		"data": stats,
		"meta": map[string]interface{}{
			"retrievedAt": time.Now().UTC().Format(time.RFC3339),
		},
	})
}

// HandleGetStreak handles GET /v1/activities/exercise/streak.
func (h *Handler) HandleGetStreak(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeExerciseError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	streak, err := h.service.GetStreak(r.Context(), userID, nil)
	if err != nil {
		writeExerciseServiceError(w, err)
		return
	}

	writeExerciseJSON(w, http.StatusOK, map[string]interface{}{
		"data": streak,
		"meta": map[string]interface{}{
			"retrievedAt": time.Now().UTC().Format(time.RFC3339),
		},
	})
}

// HandleGetCorrelations handles GET /v1/activities/exercise/correlations.
func (h *Handler) HandleGetCorrelations(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeExerciseError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	// Correlation data requires cross-domain data (urges, check-ins).
	// For now, return a stub that indicates insufficient data.
	// Full implementation requires integration with tracking service.
	result := CorrelationInsights{
		SufficientData: false,
		Insights:       nil,
	}

	writeExerciseJSON(w, http.StatusOK, map[string]interface{}{
		"data": result,
		"meta": map[string]interface{}{
			"dataWindowDays": 90,
			"retrievedAt":    time.Now().UTC().Format(time.RFC3339),
		},
	})
}

// --- Goal Handlers ---

// HandleGetGoal handles GET /v1/activities/exercise/goals.
func (h *Handler) HandleGetGoal(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeExerciseError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	progress, err := h.service.GetGoal(r.Context(), userID)
	if err != nil {
		writeExerciseServiceError(w, err)
		return
	}

	writeExerciseJSON(w, http.StatusOK, map[string]interface{}{
		"data": progress,
		"meta": map[string]interface{}{
			"retrievedAt": time.Now().UTC().Format(time.RFC3339),
		},
	})
}

// HandleSetGoal handles PUT /v1/activities/exercise/goals.
func (h *Handler) HandleSetGoal(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeExerciseError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}
	tenantID := middleware.GetTenantID(r.Context())

	var req setGoalJSON
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeExerciseError(w, http.StatusBadRequest, "rr:0x40010011", "Invalid request body: "+err.Error())
		return
	}

	goal := ExerciseGoal{
		TargetActiveMinutes: req.TargetActiveMinutes,
		TargetSessions:      req.TargetSessions,
	}

	progress, err := h.service.SetGoal(r.Context(), userID, tenantID, goal)
	if err != nil {
		writeExerciseServiceError(w, err)
		return
	}

	writeExerciseJSON(w, http.StatusOK, map[string]interface{}{
		"data": progress,
		"meta": map[string]interface{}{
			"retrievedAt": time.Now().UTC().Format(time.RFC3339),
		},
	})
}

// HandleDeleteGoal handles DELETE /v1/activities/exercise/goals.
func (h *Handler) HandleDeleteGoal(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeExerciseError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	if err := h.service.DeleteGoal(r.Context(), userID); err != nil {
		writeExerciseServiceError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// --- Widget Handler ---

// HandleGetWidget handles GET /v1/activities/exercise/widget.
func (h *Handler) HandleGetWidget(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeExerciseError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	widget, err := h.service.GetWidget(r.Context(), userID, nil)
	if err != nil {
		writeExerciseServiceError(w, err)
		return
	}

	writeExerciseJSON(w, http.StatusOK, map[string]interface{}{
		"data": widget,
		"meta": map[string]interface{}{
			"retrievedAt": time.Now().UTC().Format(time.RFC3339),
		},
	})
}

// --- JSON Types ---

type createExerciseLogJSON struct {
	Timestamp       string  `json:"timestamp"`
	ActivityType    string  `json:"activityType"`
	CustomTypeLabel *string `json:"customTypeLabel,omitempty"`
	DurationMinutes int     `json:"durationMinutes"`
	Intensity       *string `json:"intensity,omitempty"`
	Notes           *string `json:"notes,omitempty"`
	MoodBefore      *int    `json:"moodBefore,omitempty"`
	MoodAfter       *int    `json:"moodAfter,omitempty"`
	Source          string  `json:"source,omitempty"`
	ExternalID      *string `json:"externalId,omitempty"`
}

func (j createExerciseLogJSON) toDomainRequest() CreateExerciseLogRequest {
	var ts time.Time
	if j.Timestamp != "" {
		ts, _ = time.Parse(time.RFC3339, j.Timestamp)
	}
	source := j.Source
	if source == "" {
		source = SourceManual
	}
	return CreateExerciseLogRequest{
		Timestamp:       ts,
		ActivityType:    j.ActivityType,
		CustomTypeLabel: j.CustomTypeLabel,
		DurationMinutes: j.DurationMinutes,
		Intensity:       j.Intensity,
		Notes:           j.Notes,
		MoodBefore:      j.MoodBefore,
		MoodAfter:       j.MoodAfter,
		Source:          source,
		ExternalID:      j.ExternalID,
	}
}

type exerciseLogJSON struct {
	ExerciseID      string  `json:"exerciseId"`
	Timestamp       string  `json:"timestamp"`
	ActivityType    string  `json:"activityType"`
	CustomTypeLabel *string `json:"customTypeLabel,omitempty"`
	DurationMinutes int     `json:"durationMinutes"`
	Intensity       *string `json:"intensity,omitempty"`
	Notes           *string `json:"notes,omitempty"`
	MoodBefore      *int    `json:"moodBefore,omitempty"`
	MoodAfter       *int    `json:"moodAfter,omitempty"`
	Source          string  `json:"source"`
	ExternalID      *string `json:"externalId,omitempty"`
	Links           linksJSON `json:"links"`
}

type exerciseLogWithStreak struct {
	exerciseLogJSON
	ExerciseStreak *streakSummaryJSON `json:"exerciseStreak,omitempty"`
}

type streakSummaryJSON struct {
	CurrentDays int `json:"currentDays"`
	LongestDays int `json:"longestDays"`
}

type linksJSON struct {
	Self string `json:"self"`
}

type metaJSON struct {
	CreatedAt   string `json:"createdAt,omitempty"`
	ModifiedAt  string `json:"modifiedAt,omitempty"`
	RetrievedAt string `json:"retrievedAt,omitempty"`
}

type exerciseLogResponse struct {
	Data exerciseLogWithStreak `json:"data"`
	Meta metaJSON              `json:"meta"`
}

type singleExerciseLogResponse struct {
	Data exerciseLogJSON `json:"data"`
	Meta metaJSON        `json:"meta"`
}

type exerciseLogListResponse struct {
	Data  []exerciseLogJSON  `json:"data"`
	Links paginationLinksJSON `json:"links"`
	Meta  pageMetaJSON        `json:"meta"`
}

type paginationLinksJSON struct {
	Self string  `json:"self"`
	Next *string `json:"next,omitempty"`
}

type pageMetaJSON struct {
	Page pageInfoJSON `json:"page"`
}

type pageInfoJSON struct {
	NextCursor *string `json:"nextCursor,omitempty"`
	Limit      int     `json:"limit"`
}

type createFavoriteJSON struct {
	ActivityType           string  `json:"activityType"`
	CustomTypeLabel        *string `json:"customTypeLabel,omitempty"`
	DefaultDurationMinutes int     `json:"defaultDurationMinutes"`
	DefaultIntensity       *string `json:"defaultIntensity,omitempty"`
	Label                  string  `json:"label"`
}

func (j createFavoriteJSON) toDomainFavorite() ExerciseFavorite {
	return ExerciseFavorite{
		ActivityType:           j.ActivityType,
		CustomTypeLabel:        j.CustomTypeLabel,
		DefaultDurationMinutes: j.DefaultDurationMinutes,
		DefaultIntensity:       j.DefaultIntensity,
		Label:                  j.Label,
	}
}

type favoriteJSON struct {
	FavoriteID             string  `json:"favoriteId"`
	ActivityType           string  `json:"activityType"`
	CustomTypeLabel        *string `json:"customTypeLabel,omitempty"`
	DefaultDurationMinutes int     `json:"defaultDurationMinutes"`
	DefaultIntensity       *string `json:"defaultIntensity,omitempty"`
	Label                  string  `json:"label"`
	Links                  linksJSON `json:"links"`
}

type favoriteResponse struct {
	Data favoriteJSON `json:"data"`
	Meta metaJSON     `json:"meta"`
}

type favoriteListResponse struct {
	Data []favoriteJSON `json:"data"`
	Meta metaJSON       `json:"meta"`
}

type setGoalJSON struct {
	TargetActiveMinutes *int `json:"targetActiveMinutes,omitempty"`
	TargetSessions      *int `json:"targetSessions,omitempty"`
}

// --- Helper Functions ---

func toExerciseLogJSON(log *ExerciseLog) exerciseLogJSON {
	return exerciseLogJSON{
		ExerciseID:      log.ExerciseID,
		Timestamp:       log.Timestamp.Format(time.RFC3339),
		ActivityType:    log.ActivityType,
		CustomTypeLabel: log.CustomTypeLabel,
		DurationMinutes: log.DurationMinutes,
		Intensity:       log.Intensity,
		Notes:           log.Notes,
		MoodBefore:      log.MoodBefore,
		MoodAfter:       log.MoodAfter,
		Source:          log.Source,
		ExternalID:      log.ExternalID,
		Links: linksJSON{
			Self: fmt.Sprintf("/v1/activities/exercise/%s", log.ExerciseID),
		},
	}
}

func toFavoriteJSON(fav *ExerciseFavorite) favoriteJSON {
	return favoriteJSON{
		FavoriteID:             fav.FavoriteID,
		ActivityType:           fav.ActivityType,
		CustomTypeLabel:        fav.CustomTypeLabel,
		DefaultDurationMinutes: fav.DefaultDurationMinutes,
		DefaultIntensity:       fav.DefaultIntensity,
		Label:                  fav.Label,
		Links: linksJSON{
			Self: fmt.Sprintf("/v1/activities/exercise/favorites/%s", fav.FavoriteID),
		},
	}
}

func toStreakSummaryJSON(streak *ExerciseStreak) *streakSummaryJSON {
	if streak == nil {
		return nil
	}
	return &streakSummaryJSON{
		CurrentDays: streak.CurrentDays,
		LongestDays: streak.LongestDays,
	}
}

func parseListOptions(r *http.Request) ListOptions {
	opts := ListOptions{
		Limit: 50,
		Sort:  "-timestamp",
	}

	if at := r.URL.Query().Get("activityType"); at != "" {
		opts.ActivityType = &at
	}
	if intensity := r.URL.Query().Get("intensity"); intensity != "" {
		opts.Intensity = &intensity
	}
	if search := r.URL.Query().Get("search"); search != "" {
		opts.Search = &search
	}
	if cursor := r.URL.Query().Get("cursor"); cursor != "" {
		opts.Cursor = &cursor
	}
	if sort := r.URL.Query().Get("sort"); sort != "" {
		opts.Sort = sort
	}
	if startDate := r.URL.Query().Get("startDate"); startDate != "" {
		if t, err := time.Parse("2006-01-02", startDate); err == nil {
			opts.StartDate = &t
		}
	}
	if endDate := r.URL.Query().Get("endDate"); endDate != "" {
		if t, err := time.Parse("2006-01-02", endDate); err == nil {
			opts.EndDate = &t
		}
	}
	if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil && l > 0 {
			opts.Limit = l
		}
	}

	return opts
}

func buildUpdateRequest(raw map[string]interface{}) UpdateExerciseLogRequest {
	var req UpdateExerciseLogRequest
	if v, ok := raw["intensity"].(string); ok {
		req.Intensity = &v
	}
	if v, ok := raw["notes"].(string); ok {
		req.Notes = &v
	}
	if v, ok := raw["moodBefore"].(float64); ok {
		i := int(v)
		req.MoodBefore = &i
	}
	if v, ok := raw["moodAfter"].(float64); ok {
		i := int(v)
		req.MoodAfter = &i
	}
	if v, ok := raw["customTypeLabel"].(string); ok {
		req.CustomTypeLabel = &v
	}
	return req
}

// --- Error Helpers ---

type exerciseErrorResponse struct {
	Errors []exerciseAPIError `json:"errors"`
}

type exerciseAPIError struct {
	Status int    `json:"status"`
	Title  string `json:"title"`
	Code   string `json:"code,omitempty"`
	Detail string `json:"detail,omitempty"`
}

func writeExerciseJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

func writeExerciseError(w http.ResponseWriter, status int, code string, detail string) {
	writeExerciseJSON(w, status, exerciseErrorResponse{
		Errors: []exerciseAPIError{{
			Status: status,
			Title:  http.StatusText(status),
			Code:   code,
			Detail: detail,
		}},
	})
}

func writeExerciseServiceError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, ErrExerciseNotFound), errors.Is(err, ErrFavoriteNotFound), errors.Is(err, ErrGoalNotFound):
		writeExerciseError(w, http.StatusNotFound, "rr:0x40410001", err.Error())
	case errors.Is(err, ErrInvalidInput), errors.Is(err, ErrInvalidActivityType),
		errors.Is(err, ErrInvalidIntensity), errors.Is(err, ErrInvalidSource),
		errors.Is(err, ErrInvalidDuration), errors.Is(err, ErrInvalidMood),
		errors.Is(err, ErrNotesTooLong), errors.Is(err, ErrTimestampTooFarFuture),
		errors.Is(err, ErrCustomLabelRequired), errors.Is(err, ErrCustomLabelTooLong),
		errors.Is(err, ErrGoalEmpty):
		writeExerciseError(w, http.StatusUnprocessableEntity, "rr:0x42200001", err.Error())
	case errors.Is(err, ErrImmutableField):
		writeExerciseError(w, http.StatusUnprocessableEntity, "rr:0x42200002", err.Error())
	case errors.Is(err, ErrMaxFavoritesReached):
		writeExerciseError(w, http.StatusUnprocessableEntity, "rr:0x42200003", err.Error())
	case errors.Is(err, ErrDuplicateDetected):
		writeExerciseError(w, http.StatusConflict, "rr:0x40910001", err.Error())
	default:
		writeExerciseError(w, http.StatusInternalServerError, "rr:0x50010001", "Internal server error")
	}
}
