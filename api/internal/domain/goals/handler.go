// internal/domain/goals/handler.go
package goals

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/regalrecovery/api/internal/middleware"
)

// FlagChecker checks whether a feature flag is enabled.
type FlagChecker interface {
	IsEnabled(flagKey string) bool
}

// Handler holds route handlers for weekly/daily goals endpoints.
type Handler struct {
	service     *Service
	flagChecker FlagChecker
}

// NewHandler creates a new Handler.
func NewHandler(service *Service, flagChecker FlagChecker) *Handler {
	return &Handler{service: service, flagChecker: flagChecker}
}

const featureFlagKey = "activity.weekly-daily-goals"

// RegisterRoutes registers weekly/daily goals routes on the given mux.
func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	// Daily/Weekly views
	mux.HandleFunc("GET /activities/weekly-daily-goals/daily", h.HandleGetDailyGoals)
	mux.HandleFunc("GET /activities/weekly-daily-goals/weekly", h.HandleGetWeeklyGoals)

	// Goal CRUD
	mux.HandleFunc("POST /activities/weekly-daily-goals", h.HandleCreateGoal)
	mux.HandleFunc("GET /activities/weekly-daily-goals", h.HandleListGoals)
	mux.HandleFunc("GET /activities/weekly-daily-goals/{goalId}", h.HandleGetGoal)
	mux.HandleFunc("PATCH /activities/weekly-daily-goals/{goalId}", h.HandleUpdateGoal)
	mux.HandleFunc("DELETE /activities/weekly-daily-goals/{goalId}", h.HandleDeleteGoal)

	// Instance actions
	mux.HandleFunc("POST /activities/weekly-daily-goals/instances/{goalInstanceId}/complete", h.HandleCompleteInstance)
	mux.HandleFunc("POST /activities/weekly-daily-goals/instances/{goalInstanceId}/uncomplete", h.HandleUncompleteInstance)
	mux.HandleFunc("POST /activities/weekly-daily-goals/instances/{goalInstanceId}/dismiss", h.HandleDismissInstance)

	// Nudge dismissal
	mux.HandleFunc("POST /activities/weekly-daily-goals/nudges/{dynamic}/dismiss", h.HandleDismissNudge)

	// Reviews
	mux.HandleFunc("GET /activities/weekly-daily-goals/reviews/daily", h.HandleGetDailyReview)
	mux.HandleFunc("POST /activities/weekly-daily-goals/reviews/daily", h.HandleSubmitDailyReview)
	mux.HandleFunc("GET /activities/weekly-daily-goals/reviews/weekly", h.HandleGetWeeklyReview)
	mux.HandleFunc("POST /activities/weekly-daily-goals/reviews/weekly", h.HandleSubmitWeeklyReview)

	// Trends and history
	mux.HandleFunc("GET /activities/weekly-daily-goals/trends", h.HandleGetTrends)
	mux.HandleFunc("GET /activities/weekly-daily-goals/history", h.HandleGetHistory)
	mux.HandleFunc("POST /activities/weekly-daily-goals/history/export", h.HandleExportHistory)

	// Settings
	mux.HandleFunc("GET /activities/weekly-daily-goals/settings", h.HandleGetSettings)
	mux.HandleFunc("PATCH /activities/weekly-daily-goals/settings", h.HandleUpdateSettings)

	// Sponsor view
	mux.HandleFunc("GET /activities/weekly-daily-goals/users/{userId}/summary", h.HandleGetUserSummary)
}

// checkFeatureFlag returns true if the feature flag is enabled. Writes 404 if not.
func (h *Handler) checkFeatureFlag(w http.ResponseWriter) bool {
	if h.flagChecker != nil && !h.flagChecker.IsEnabled(featureFlagKey) {
		writeError(w, http.StatusNotFound, "rr:0x00800404", "Not found")
		return false
	}
	return true
}

// HandleGetDailyGoals handles GET /activities/weekly-daily-goals/daily.
func (h *Handler) HandleGetDailyGoals(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w) {
		return
	}
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x00800401", "Authentication required")
		return
	}

	date := r.URL.Query().Get("date")
	instances, balance, nudges, err := h.service.GetDailyGoals(r.Context(), userID, date)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	total, completed := ComputeDailySummary(instances)
	if date == "" {
		date = time.Now().UTC().Format("2006-01-02")
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": map[string]interface{}{
			"date":  date,
			"goals": instances,
			"summary": map[string]interface{}{
				"totalGoals":     total,
				"completedGoals": completed,
				"dynamicBalance": balance,
			},
			"nudges": nudges,
			"links": map[string]string{
				"self":   fmt.Sprintf("/activities/weekly-daily-goals/daily?date=%s", date),
				"weekly": fmt.Sprintf("/activities/weekly-daily-goals/weekly?weekOf=%s", date),
			},
		},
		"meta": map[string]interface{}{
			"retrievedAt": time.Now().UTC().Format(time.RFC3339),
		},
	})
}

// HandleGetWeeklyGoals handles GET /activities/weekly-daily-goals/weekly.
func (h *Handler) HandleGetWeeklyGoals(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w) {
		return
	}
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x00800401", "Authentication required")
		return
	}

	weekOf := r.URL.Query().Get("weekOf")
	instances, weekStart, weekEnd, total, completed, rate, balance, err := h.service.GetWeeklyGoals(r.Context(), userID, weekOf)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": map[string]interface{}{
			"weekStart": weekStart,
			"weekEnd":   weekEnd,
			"goals":     instances,
			"summary": map[string]interface{}{
				"totalGoals":     total,
				"completedGoals": completed,
				"completionRate": rate,
				"dynamicBalance": balance,
			},
			"links": map[string]interface{}{
				"self": fmt.Sprintf("/activities/weekly-daily-goals/weekly?weekOf=%s", weekStart),
			},
		},
		"meta": map[string]interface{}{
			"retrievedAt": time.Now().UTC().Format(time.RFC3339),
		},
	})
}

// HandleCreateGoal handles POST /activities/weekly-daily-goals.
func (h *Handler) HandleCreateGoal(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w) {
		return
	}
	userID := middleware.GetUserID(r.Context())
	tenantID := middleware.GetTenantID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x00800401", "Authentication required")
		return
	}

	var req CreateWeeklyDailyGoalRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x00800400", "Invalid request body: "+err.Error())
		return
	}

	goal, err := h.service.CreateGoal(r.Context(), userID, tenantID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	w.Header().Set("Location", fmt.Sprintf("/activities/weekly-daily-goals/%s", goal.GoalID))
	writeJSON(w, http.StatusCreated, map[string]interface{}{
		"data": goal,
		"meta": map[string]interface{}{
			"createdAt": goal.CreatedAt.Format(time.RFC3339),
		},
	})
}

// HandleListGoals handles GET /activities/weekly-daily-goals.
func (h *Handler) HandleListGoals(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w) {
		return
	}
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x00800401", "Authentication required")
		return
	}

	var scope *GoalScope
	if s := r.URL.Query().Get("scope"); s != "" {
		gs := GoalScope(s)
		scope = &gs
	}
	var dynamic *Dynamic
	if d := r.URL.Query().Get("dynamic"); d != "" {
		dd := Dynamic(d)
		dynamic = &dd
	}
	var isActive *bool
	if a := r.URL.Query().Get("isActive"); a != "" {
		b := a == "true"
		isActive = &b
	}

	cursor := r.URL.Query().Get("cursor")
	limit := 50
	if l := r.URL.Query().Get("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 && parsed <= 100 {
			limit = parsed
		}
	}

	goals, nextCursor, err := h.service.ListGoals(r.Context(), userID, scope, dynamic, isActive, cursor, limit)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	links := map[string]interface{}{"self": r.URL.String()}
	if nextCursor != "" {
		links["next"] = fmt.Sprintf("/activities/weekly-daily-goals?cursor=%s&limit=%d", nextCursor, limit)
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data":  goals,
		"links": links,
		"meta": map[string]interface{}{
			"page": map[string]interface{}{
				"nextCursor": nextCursor,
				"limit":      limit,
			},
		},
	})
}

// HandleGetGoal handles GET /activities/weekly-daily-goals/{goalId}.
func (h *Handler) HandleGetGoal(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w) {
		return
	}
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x00800401", "Authentication required")
		return
	}

	goalID := r.PathValue("goalId")
	goal, err := h.service.GetGoal(r.Context(), userID, goalID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": goal,
		"meta": map[string]interface{}{},
	})
}

// HandleUpdateGoal handles PATCH /activities/weekly-daily-goals/{goalId}.
func (h *Handler) HandleUpdateGoal(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w) {
		return
	}
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x00800401", "Authentication required")
		return
	}

	goalID := r.PathValue("goalId")
	var req UpdateWeeklyDailyGoalRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x00800400", "Invalid request body: "+err.Error())
		return
	}

	goal, err := h.service.UpdateGoal(r.Context(), userID, goalID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": goal,
		"meta": map[string]interface{}{},
	})
}

// HandleDeleteGoal handles DELETE /activities/weekly-daily-goals/{goalId}.
func (h *Handler) HandleDeleteGoal(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w) {
		return
	}
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x00800401", "Authentication required")
		return
	}

	goalID := r.PathValue("goalId")
	if err := h.service.DeleteGoal(r.Context(), userID, goalID); err != nil {
		writeServiceError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// HandleCompleteInstance handles POST /activities/weekly-daily-goals/instances/{goalInstanceId}/complete.
func (h *Handler) HandleCompleteInstance(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w) {
		return
	}
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x00800401", "Authentication required")
		return
	}

	instanceID := r.PathValue("goalInstanceId")
	instance, err := h.service.CompleteGoalInstance(r.Context(), userID, instanceID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": instance,
		"meta": map[string]interface{}{},
	})
}

// HandleUncompleteInstance handles POST /activities/weekly-daily-goals/instances/{goalInstanceId}/uncomplete.
func (h *Handler) HandleUncompleteInstance(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w) {
		return
	}
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x00800401", "Authentication required")
		return
	}

	instanceID := r.PathValue("goalInstanceId")
	instance, err := h.service.UncompleteGoalInstance(r.Context(), userID, instanceID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": instance,
		"meta": map[string]interface{}{},
	})
}

// HandleDismissInstance handles POST /activities/weekly-daily-goals/instances/{goalInstanceId}/dismiss.
func (h *Handler) HandleDismissInstance(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w) {
		return
	}
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x00800401", "Authentication required")
		return
	}

	instanceID := r.PathValue("goalInstanceId")
	instance, err := h.service.DismissGoalInstance(r.Context(), userID, instanceID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": instance,
		"meta": map[string]interface{}{},
	})
}

// HandleDismissNudge handles POST /activities/weekly-daily-goals/nudges/{dynamic}/dismiss.
func (h *Handler) HandleDismissNudge(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w) {
		return
	}
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x00800401", "Authentication required")
		return
	}

	dynamic := r.PathValue("dynamic")
	var body struct {
		Date string `json:"date"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x00800400", "Invalid request body")
		return
	}

	if err := h.service.DismissDynamicNudge(r.Context(), userID, body.Date, dynamic); err != nil {
		writeServiceError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// HandleGetDailyReview handles GET /activities/weekly-daily-goals/reviews/daily.
func (h *Handler) HandleGetDailyReview(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w) {
		return
	}
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x00800401", "Authentication required")
		return
	}

	date := r.URL.Query().Get("date")
	instances, balance, prevSubmitted, err := h.service.GetDailyReview(r.Context(), userID, date)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	total, completed := ComputeDailySummary(instances)

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": map[string]interface{}{
			"date":  date,
			"goals": instances,
			"summary": map[string]interface{}{
				"totalGoals":     total,
				"completedGoals": completed,
				"dynamicBalance": balance,
			},
			"previousReviewSubmitted": prevSubmitted,
		},
		"meta": map[string]interface{}{},
	})
}

// HandleSubmitDailyReview handles POST /activities/weekly-daily-goals/reviews/daily.
func (h *Handler) HandleSubmitDailyReview(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w) {
		return
	}
	userID := middleware.GetUserID(r.Context())
	tenantID := middleware.GetTenantID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x00800401", "Authentication required")
		return
	}

	var req SubmitDailyReviewRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x00800400", "Invalid request body: "+err.Error())
		return
	}

	review, err := h.service.SubmitDailyReview(r.Context(), userID, tenantID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	w.Header().Set("Location", fmt.Sprintf("/activities/weekly-daily-goals/reviews/daily?date=%s", review.Date))
	writeJSON(w, http.StatusCreated, map[string]interface{}{
		"data": map[string]interface{}{
			"reviewId":     review.ReviewID,
			"date":         review.Date,
			"dispositions": review.Dispositions,
			"reflection":   review.Reflection,
			"summary":      review.Summary,
			"links": map[string]string{
				"self": fmt.Sprintf("/activities/weekly-daily-goals/reviews/daily?date=%s", review.Date),
			},
		},
		"meta": map[string]interface{}{
			"createdAt": review.CreatedAt.Format(time.RFC3339),
		},
	})
}

// HandleGetWeeklyReview handles GET /activities/weekly-daily-goals/reviews/weekly.
func (h *Handler) HandleGetWeeklyReview(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w) {
		return
	}
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x00800401", "Authentication required")
		return
	}

	weekOf := r.URL.Query().Get("weekOf")
	stats, prompts, prevSubmitted, err := h.service.GetWeeklyReview(r.Context(), userID, weekOf)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": map[string]interface{}{
			"stats":                   stats,
			"reflectionPrompts":       prompts,
			"previousReviewSubmitted": prevSubmitted,
		},
		"meta": map[string]interface{}{},
	})
}

// HandleSubmitWeeklyReview handles POST /activities/weekly-daily-goals/reviews/weekly.
func (h *Handler) HandleSubmitWeeklyReview(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w) {
		return
	}
	userID := middleware.GetUserID(r.Context())
	tenantID := middleware.GetTenantID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x00800401", "Authentication required")
		return
	}

	var req SubmitWeeklyReviewRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x00800400", "Invalid request body: "+err.Error())
		return
	}

	review, err := h.service.SubmitWeeklyReview(r.Context(), userID, tenantID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	w.Header().Set("Location", fmt.Sprintf("/activities/weekly-daily-goals/reviews/weekly?weekOf=%s", review.Date))
	writeJSON(w, http.StatusCreated, map[string]interface{}{
		"data": map[string]interface{}{
			"reviewId":    review.ReviewID,
			"weekOf":      review.Date,
			"reflections": review.Reflections,
			"stats":       review.Stats,
			"links": map[string]string{
				"self": fmt.Sprintf("/activities/weekly-daily-goals/reviews/weekly?weekOf=%s", review.Date),
			},
		},
		"meta": map[string]interface{}{
			"createdAt": review.CreatedAt.Format(time.RFC3339),
		},
	})
}

// HandleGetTrends handles GET /activities/weekly-daily-goals/trends.
func (h *Handler) HandleGetTrends(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w) {
		return
	}
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x00800401", "Authentication required")
		return
	}

	period := r.URL.Query().Get("period")
	var dynamic *Dynamic
	if d := r.URL.Query().Get("dynamic"); d != "" {
		dd := Dynamic(d)
		dynamic = &dd
	}

	trends, err := h.service.GetGoalTrends(r.Context(), userID, period, dynamic)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": trends,
		"meta": map[string]interface{}{},
	})
}

// HandleGetHistory handles GET /activities/weekly-daily-goals/history.
func (h *Handler) HandleGetHistory(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w) {
		return
	}
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x00800401", "Authentication required")
		return
	}

	startDate := r.URL.Query().Get("startDate")
	endDate := r.URL.Query().Get("endDate")
	search := r.URL.Query().Get("search")
	cursor := r.URL.Query().Get("cursor")

	var dynamic *Dynamic
	if d := r.URL.Query().Get("dynamic"); d != "" {
		dd := Dynamic(d)
		dynamic = &dd
	}
	var status *GoalInstanceStatus
	if s := r.URL.Query().Get("status"); s != "" {
		ss := GoalInstanceStatus(s)
		status = &ss
	}

	limit := 50
	if l := r.URL.Query().Get("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 && parsed <= 100 {
			limit = parsed
		}
	}

	instances, nextCursor, totalResults, err := h.service.GetGoalHistory(r.Context(), userID, startDate, endDate, dynamic, status, search, cursor, limit)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	links := map[string]interface{}{"self": r.URL.String()}
	if nextCursor != "" {
		links["next"] = fmt.Sprintf("/activities/weekly-daily-goals/history?cursor=%s&limit=%d", nextCursor, limit)
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data":  instances,
		"links": links,
		"meta": map[string]interface{}{
			"page": map[string]interface{}{
				"nextCursor": nextCursor,
				"limit":      limit,
			},
			"totalResults": totalResults,
		},
	})
}

// HandleExportHistory handles POST /activities/weekly-daily-goals/history/export.
func (h *Handler) HandleExportHistory(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w) {
		return
	}
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x00800401", "Authentication required")
		return
	}

	var req ExportGoalHistoryRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x00800400", "Invalid request body")
		return
	}

	exportID := fmt.Sprintf("exp_%d", time.Now().UnixNano())
	w.Header().Set("Location", fmt.Sprintf("/activities/weekly-daily-goals/history/export/%s", exportID))
	writeJSON(w, http.StatusAccepted, map[string]interface{}{
		"data": map[string]interface{}{
			"exportId": exportID,
			"status":   "pending",
			"links": map[string]string{
				"self": fmt.Sprintf("/activities/weekly-daily-goals/history/export/%s", exportID),
			},
		},
		"meta": map[string]interface{}{
			"createdAt": time.Now().UTC().Format(time.RFC3339),
		},
	})
	_ = userID
}

// HandleGetSettings handles GET /activities/weekly-daily-goals/settings.
func (h *Handler) HandleGetSettings(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w) {
		return
	}
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x00800401", "Authentication required")
		return
	}

	settings, err := h.service.GetGoalSettings(r.Context(), userID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": settings,
		"meta": map[string]interface{}{},
	})
}

// HandleUpdateSettings handles PATCH /activities/weekly-daily-goals/settings.
func (h *Handler) HandleUpdateSettings(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w) {
		return
	}
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x00800401", "Authentication required")
		return
	}

	var req UpdateGoalSettingsRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x00800400", "Invalid request body: "+err.Error())
		return
	}

	settings, err := h.service.UpdateGoalSettings(r.Context(), userID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": settings,
		"meta": map[string]interface{}{},
	})
}

// HandleGetUserSummary handles GET /activities/weekly-daily-goals/users/{userId}/summary.
func (h *Handler) HandleGetUserSummary(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w) {
		return
	}
	requestingUserID := middleware.GetUserID(r.Context())
	if requestingUserID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x00800401", "Authentication required")
		return
	}

	targetUserID := r.PathValue("userId")
	period := r.URL.Query().Get("period")
	if period == "" {
		period = "30d"
	}

	summary, err := h.service.GetUserGoalSummary(r.Context(), requestingUserID, targetUserID, period)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": summary,
		"meta": map[string]interface{}{},
	})
}

// --- Response helpers ---

type errorResponse struct {
	Errors []apiError `json:"errors"`
}

type apiError struct {
	Code    string `json:"code"`
	Status  int    `json:"status"`
	Title   string `json:"title"`
	Detail  string `json:"detail,omitempty"`
}

func writeJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

func writeError(w http.ResponseWriter, status int, code string, message string) {
	writeJSON(w, status, errorResponse{
		Errors: []apiError{{Code: code, Status: status, Title: message}},
	})
}

func writeServiceError(w http.ResponseWriter, err error) {
	var validErr *ValidationError
	if errors.As(err, &validErr) {
		writeError(w, http.StatusUnprocessableEntity, validErr.Code, validErr.Message)
		return
	}

	switch {
	case errors.Is(err, ErrGoalNotFound), errors.Is(err, ErrInstanceNotFound):
		writeError(w, http.StatusNotFound, "rr:0x00800404", err.Error())
	case errors.Is(err, ErrPermissionDenied):
		// Return 404 to hide data existence (AC-IP-3).
		writeError(w, http.StatusNotFound, "rr:0x00800404", "Not found")
	case errors.Is(err, ErrFeatureDisabled):
		writeError(w, http.StatusNotFound, "rr:0x00800404", "Not found")
	default:
		writeError(w, http.StatusInternalServerError, "rr:0x00800500", "Internal server error")
	}
}
