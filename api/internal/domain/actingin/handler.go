// internal/domain/actingin/handler.go
package actingin

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/regalrecovery/api/internal/middleware"
)

// Handler holds route handlers for the acting-in behaviors endpoints.
type Handler struct {
	service *Service
}

// NewHandler creates a new Handler with the given service.
func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

// RegisterRoutes registers acting-in behavior routes on the given mux.
func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	// Behavior catalog.
	mux.HandleFunc("GET /activities/acting-in-behaviors/behaviors", h.HandleListBehaviors)
	mux.HandleFunc("POST /activities/acting-in-behaviors/behaviors/custom", h.HandleCreateCustomBehavior)
	mux.HandleFunc("PUT /activities/acting-in-behaviors/behaviors/custom/{behaviorId}", h.HandleUpdateCustomBehavior)
	mux.HandleFunc("DELETE /activities/acting-in-behaviors/behaviors/custom/{behaviorId}", h.HandleDeleteCustomBehavior)
	mux.HandleFunc("PATCH /activities/acting-in-behaviors/behaviors/{behaviorId}/toggle", h.HandleToggleBehavior)

	// Check-ins.
	mux.HandleFunc("POST /activities/acting-in-behaviors/check-ins", h.HandleCreateCheckIn)
	mux.HandleFunc("GET /activities/acting-in-behaviors/check-ins", h.HandleListCheckIns)
	mux.HandleFunc("GET /activities/acting-in-behaviors/check-ins/{checkInId}", h.HandleGetCheckIn)

	// Insights.
	mux.HandleFunc("GET /activities/acting-in-behaviors/insights/frequency", h.HandleFrequencyInsights)
	mux.HandleFunc("GET /activities/acting-in-behaviors/insights/triggers", h.HandleTriggerInsights)
	mux.HandleFunc("GET /activities/acting-in-behaviors/insights/relationships", h.HandleRelationshipInsights)
	mux.HandleFunc("GET /activities/acting-in-behaviors/insights/heatmap", h.HandleHeatmapInsights)
	mux.HandleFunc("GET /activities/acting-in-behaviors/insights/cross-tool", h.HandleCrossToolInsights)

	// Export.
	mux.HandleFunc("GET /activities/acting-in-behaviors/export", h.HandleExport)

	// Settings.
	mux.HandleFunc("GET /activities/acting-in-behaviors/settings", h.HandleGetSettings)
	mux.HandleFunc("PUT /activities/acting-in-behaviors/settings", h.HandleUpdateSettings)
}

// --- Behavior catalog handlers ---

// HandleListBehaviors handles GET /activities/acting-in-behaviors/behaviors.
func (h *Handler) HandleListBehaviors(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40100001", "Authentication required")
		return
	}

	behaviors, err := h.service.ListBehaviors(r.Context(), userID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	enabledCount := 0
	defaultCount := 0
	customCount := 0
	for _, b := range behaviors {
		if b.Enabled {
			enabledCount++
		}
		if b.IsDefault {
			defaultCount++
		} else {
			customCount++
		}
	}

	writeJSON(w, http.StatusOK, BehaviorsResponse{
		Data: behaviors,
		Meta: map[string]interface{}{
			"totalBehaviors": len(behaviors),
			"enabledCount":   enabledCount,
			"defaultCount":   defaultCount,
			"customCount":    customCount,
		},
	})
}

// HandleCreateCustomBehavior handles POST /activities/acting-in-behaviors/behaviors/custom.
func (h *Handler) HandleCreateCustomBehavior(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40100001", "Authentication required")
		return
	}

	var req CreateCustomBehaviorRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x40000010", "Invalid request body: "+err.Error())
		return
	}

	behavior, err := h.service.CreateCustomBehavior(r.Context(), userID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	w.Header().Set("Location", fmt.Sprintf("/activities/acting-in-behaviors/behaviors/custom/%s", behavior.BehaviorID))
	writeJSON(w, http.StatusCreated, BehaviorResponse{
		Data: *behavior,
		Meta: map[string]interface{}{"createdAt": time.Now().UTC().Format(time.RFC3339)},
	})
}

// HandleUpdateCustomBehavior handles PUT /activities/acting-in-behaviors/behaviors/custom/{behaviorId}.
func (h *Handler) HandleUpdateCustomBehavior(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40100001", "Authentication required")
		return
	}

	behaviorID := r.PathValue("behaviorId")
	if behaviorID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x40000011", "Behavior ID is required")
		return
	}

	var req UpdateCustomBehaviorRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x40000010", "Invalid request body: "+err.Error())
		return
	}

	behavior, err := h.service.UpdateCustomBehavior(r.Context(), userID, behaviorID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, BehaviorResponse{
		Data: *behavior,
		Meta: map[string]interface{}{"modifiedAt": time.Now().UTC().Format(time.RFC3339)},
	})
}

// HandleDeleteCustomBehavior handles DELETE /activities/acting-in-behaviors/behaviors/custom/{behaviorId}.
func (h *Handler) HandleDeleteCustomBehavior(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40100001", "Authentication required")
		return
	}

	behaviorID := r.PathValue("behaviorId")
	if behaviorID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x40000011", "Behavior ID is required")
		return
	}

	if err := h.service.DeleteCustomBehavior(r.Context(), userID, behaviorID); err != nil {
		writeServiceError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// HandleToggleBehavior handles PATCH /activities/acting-in-behaviors/behaviors/{behaviorId}/toggle.
func (h *Handler) HandleToggleBehavior(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40100001", "Authentication required")
		return
	}

	behaviorID := r.PathValue("behaviorId")
	if behaviorID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x40000011", "Behavior ID is required")
		return
	}

	var req ToggleBehaviorRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x40000010", "Invalid request body: "+err.Error())
		return
	}

	behavior, err := h.service.ToggleBehavior(r.Context(), userID, behaviorID, req.Enabled)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, BehaviorResponse{
		Data: *behavior,
		Meta: map[string]interface{}{"modifiedAt": time.Now().UTC().Format(time.RFC3339)},
	})
}

// --- Check-in handlers ---

// HandleCreateCheckIn handles POST /activities/acting-in-behaviors/check-ins.
func (h *Handler) HandleCreateCheckIn(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40100001", "Authentication required")
		return
	}

	var req CreateCheckInRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x40000010", "Invalid request body: "+err.Error())
		return
	}

	checkIn, err := h.service.SubmitCheckIn(r.Context(), userID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	w.Header().Set("Location", fmt.Sprintf("/activities/acting-in-behaviors/check-ins/%s", checkIn.CheckInID))
	writeJSON(w, http.StatusCreated, CheckInResponse{
		Data: *checkIn,
		Meta: map[string]interface{}{"createdAt": checkIn.CreatedAt.Format(time.RFC3339)},
	})
}

// HandleListCheckIns handles GET /activities/acting-in-behaviors/check-ins.
func (h *Handler) HandleListCheckIns(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40100001", "Authentication required")
		return
	}

	filters := CheckInFilters{}
	if sd := r.URL.Query().Get("startDate"); sd != "" {
		if t, err := time.Parse("2006-01-02", sd); err == nil {
			filters.StartDate = &t
		}
	}
	if ed := r.URL.Query().Get("endDate"); ed != "" {
		if t, err := time.Parse("2006-01-02", ed); err == nil {
			end := t.Add(24*time.Hour - time.Nanosecond)
			filters.EndDate = &end
		}
	}
	filters.BehaviorID = r.URL.Query().Get("behaviorId")
	if t := r.URL.Query().Get("trigger"); t != "" {
		filters.Trigger = Trigger(t)
	}
	if rt := r.URL.Query().Get("relationshipTag"); rt != "" {
		filters.RelationshipTag = RelationshipTag(rt)
	}

	cursor := r.URL.Query().Get("cursor")
	limit := 50
	if l := r.URL.Query().Get("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 && parsed <= 100 {
			limit = parsed
		}
	}

	checkIns, nextCursor, err := h.service.ListCheckIns(r.Context(), userID, filters, cursor, limit)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	links := map[string]string{
		"self": r.URL.String(),
	}
	if nextCursor != "" {
		links["next"] = fmt.Sprintf("/activities/acting-in-behaviors/check-ins?cursor=%s&limit=%d", nextCursor, limit)
	}

	writeJSON(w, http.StatusOK, CheckInsListResponse{
		Data:  checkIns,
		Links: links,
		Meta: map[string]interface{}{
			"page": map[string]interface{}{
				"nextCursor": nextCursor,
				"limit":      limit,
			},
		},
	})
}

// HandleGetCheckIn handles GET /activities/acting-in-behaviors/check-ins/{checkInId}.
func (h *Handler) HandleGetCheckIn(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40100001", "Authentication required")
		return
	}

	checkInID := r.PathValue("checkInId")
	if checkInID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x40000012", "Check-in ID is required")
		return
	}

	checkIn, err := h.service.GetCheckIn(r.Context(), userID, checkInID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, CheckInResponse{
		Data: *checkIn,
		Meta: map[string]interface{}{"retrievedAt": time.Now().UTC().Format(time.RFC3339)},
	})
}

// --- Insights handlers ---

// HandleFrequencyInsights handles GET /activities/acting-in-behaviors/insights/frequency.
func (h *Handler) HandleFrequencyInsights(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40100001", "Authentication required")
		return
	}

	rangeStr := r.URL.Query().Get("range")
	ir := InsightsRange(rangeStr)
	if !ValidInsightsRanges[ir] {
		writeError(w, http.StatusBadRequest, "rr:0x40000020", "Query parameter 'range' must be '7d', '30d', or '90d'")
		return
	}

	insights, err := h.service.GetFrequencyInsights(r.Context(), userID, ir)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, FrequencyInsightsResponse{
		Data: *insights,
		Meta: map[string]interface{}{"retrievedAt": time.Now().UTC().Format(time.RFC3339)},
	})
}

// HandleTriggerInsights handles GET /activities/acting-in-behaviors/insights/triggers.
func (h *Handler) HandleTriggerInsights(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40100001", "Authentication required")
		return
	}

	rangeStr := r.URL.Query().Get("range")
	ir := InsightsRange(rangeStr)
	if !ValidInsightsRanges[ir] {
		writeError(w, http.StatusBadRequest, "rr:0x40000020", "Query parameter 'range' must be '7d', '30d', or '90d'")
		return
	}

	insights, err := h.service.GetTriggerInsights(r.Context(), userID, ir)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, TriggerInsightsResponse{
		Data: *insights,
		Meta: map[string]interface{}{"retrievedAt": time.Now().UTC().Format(time.RFC3339)},
	})
}

// HandleRelationshipInsights handles GET /activities/acting-in-behaviors/insights/relationships.
func (h *Handler) HandleRelationshipInsights(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40100001", "Authentication required")
		return
	}

	rangeStr := r.URL.Query().Get("range")
	ir := InsightsRange(rangeStr)
	if !ValidInsightsRanges[ir] {
		writeError(w, http.StatusBadRequest, "rr:0x40000020", "Query parameter 'range' must be '7d', '30d', or '90d'")
		return
	}

	insights, err := h.service.GetRelationshipInsights(r.Context(), userID, ir)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, RelationshipInsightsResponse{
		Data: *insights,
		Meta: map[string]interface{}{"retrievedAt": time.Now().UTC().Format(time.RFC3339)},
	})
}

// HandleHeatmapInsights handles GET /activities/acting-in-behaviors/insights/heatmap.
func (h *Handler) HandleHeatmapInsights(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40100001", "Authentication required")
		return
	}

	rangeStr := r.URL.Query().Get("range")
	ir := InsightsRange(rangeStr)
	if !ValidHeatmapRanges[ir] {
		writeError(w, http.StatusBadRequest, "rr:0x40000021", "Query parameter 'range' must be '30d' or '90d' for heatmap")
		return
	}

	insights, err := h.service.GetHeatmapInsights(r.Context(), userID, ir)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, HeatmapInsightsResponse{
		Data: *insights,
		Meta: map[string]interface{}{"retrievedAt": time.Now().UTC().Format(time.RFC3339)},
	})
}

// HandleCrossToolInsights handles GET /activities/acting-in-behaviors/insights/cross-tool.
func (h *Handler) HandleCrossToolInsights(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40100001", "Authentication required")
		return
	}

	rangeStr := r.URL.Query().Get("range")
	ir := InsightsRange(rangeStr)
	if !ValidHeatmapRanges[ir] {
		writeError(w, http.StatusBadRequest, "rr:0x40000021", "Query parameter 'range' must be '30d' or '90d'")
		return
	}

	insights, err := h.service.GetCrossToolInsights(r.Context(), userID, ir)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, CrossToolInsightsResponse{
		Data: *insights,
		Meta: map[string]interface{}{"retrievedAt": time.Now().UTC().Format(time.RFC3339)},
	})
}

// --- Export handler ---

// HandleExport handles GET /activities/acting-in-behaviors/export.
func (h *Handler) HandleExport(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40100001", "Authentication required")
		return
	}

	formatStr := r.URL.Query().Get("format")
	format := ExportFormat(formatStr)
	if format != ExportCSV && format != ExportPDF {
		writeError(w, http.StatusUnprocessableEntity, "rr:0x42200010", "Query parameter 'format' must be 'csv' or 'pdf'")
		return
	}

	var startDate, endDate *time.Time
	if sd := r.URL.Query().Get("startDate"); sd != "" {
		if t, err := time.Parse("2006-01-02", sd); err == nil {
			startDate = &t
		}
	}
	if ed := r.URL.Query().Get("endDate"); ed != "" {
		if t, err := time.Parse("2006-01-02", ed); err == nil {
			end := t.Add(24*time.Hour - time.Nanosecond)
			endDate = &end
		}
	}

	data, contentType, err := h.service.ExportHistory(r.Context(), userID, format, startDate, endDate)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	filename := fmt.Sprintf("acting-in-export-%s.%s", time.Now().UTC().Format("2006-01-02"), formatStr)
	w.Header().Set("Content-Type", contentType)
	w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename="%s"`, filename))
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write(data)
}

// --- Settings handlers ---

// HandleGetSettings handles GET /activities/acting-in-behaviors/settings.
func (h *Handler) HandleGetSettings(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40100001", "Authentication required")
		return
	}

	settings, err := h.service.GetOrCreateSettings(r.Context(), userID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, SettingsResponse{
		Data: *settings,
		Meta: map[string]interface{}{"retrievedAt": time.Now().UTC().Format(time.RFC3339)},
	})
}

// HandleUpdateSettings handles PUT /activities/acting-in-behaviors/settings.
func (h *Handler) HandleUpdateSettings(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40100001", "Authentication required")
		return
	}

	var req UpdateSettingsRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x40000010", "Invalid request body: "+err.Error())
		return
	}

	settings, err := h.service.UpdateSettings(r.Context(), userID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, SettingsResponse{
		Data: *settings,
		Meta: map[string]interface{}{"modifiedAt": settings.ModifiedAt.Format(time.RFC3339)},
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
	w.Header().Set("Api-Version", "1.0.0")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

func writeError(w http.ResponseWriter, status int, code, message string) {
	writeJSON(w, status, errorResponse{
		Errors: []apiError{{
			Code:   code,
			Status: status,
			Title:  message,
		}},
	})
}

func writeServiceError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, ErrCheckInNotFound), errors.Is(err, ErrBehaviorNotFound):
		writeError(w, http.StatusNotFound, "rr:0x40400001", err.Error())
	case errors.Is(err, ErrInvalidBehaviorID), errors.Is(err, ErrDisabledBehaviorID),
		errors.Is(err, ErrInvalidTrigger), errors.Is(err, ErrInvalidRelationshipTag):
		writeError(w, http.StatusUnprocessableEntity, "rr:0x42200001", err.Error())
	case errors.Is(err, ErrNameTooLong), errors.Is(err, ErrNameEmpty),
		errors.Is(err, ErrDescriptionTooLong), errors.Is(err, ErrContextNoteTooLong):
		writeError(w, http.StatusUnprocessableEntity, "rr:0x42200002", err.Error())
	case errors.Is(err, ErrInvalidFrequency), errors.Is(err, ErrInvalidReminderTime),
		errors.Is(err, ErrInvalidReminderDay):
		writeError(w, http.StatusUnprocessableEntity, "rr:0x42200003", err.Error())
	case errors.Is(err, ErrCannotEditDefault), errors.Is(err, ErrCannotDeleteDefault):
		writeError(w, http.StatusUnprocessableEntity, "rr:0x42200004", err.Error())
	case errors.Is(err, ErrTimestampImmutable):
		writeError(w, http.StatusUnprocessableEntity, "rr:0x42200005", err.Error())
	case errors.Is(err, ErrFeatureDisabled):
		writeError(w, http.StatusNotFound, "rr:0x40400002", "Not found")
	default:
		if strings.Contains(err.Error(), "not found") {
			writeError(w, http.StatusNotFound, "rr:0x40400001", err.Error())
			return
		}
		writeError(w, http.StatusInternalServerError, "rr:0x50000001", "Internal server error")
	}
}
