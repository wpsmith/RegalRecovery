// internal/domain/personcheckin/handler.go
package personcheckin

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/regalrecovery/api/internal/middleware"
)

// Handler holds route handlers for person check-in endpoints.
type Handler struct {
	service *PersonCheckInService
}

// NewHandler creates a new Handler with the given service.
func NewHandler(service *PersonCheckInService) *Handler {
	return &Handler{service: service}
}

// RegisterRoutes registers person check-in routes on the given mux.
// All routes are gated by the `activity.person-check-ins` feature flag.
func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("POST /activities/person-check-ins", h.HandleCreateCheckIn)
	mux.HandleFunc("GET /activities/person-check-ins", h.HandleListCheckIns)
	mux.HandleFunc("POST /activities/person-check-ins/quick", h.HandleQuickLogCheckIn)
	mux.HandleFunc("GET /activities/person-check-ins/streaks", h.HandleGetStreaks)
	mux.HandleFunc("GET /activities/person-check-ins/settings", h.HandleGetSettings)
	mux.HandleFunc("PATCH /activities/person-check-ins/settings", h.HandleUpdateSettings)
	mux.HandleFunc("GET /activities/person-check-ins/trends", h.HandleGetTrends)
	mux.HandleFunc("GET /activities/person-check-ins/calendar", h.HandleGetCalendar)
	mux.HandleFunc("GET /activities/person-check-ins/{checkInId}", h.HandleGetCheckIn)
	mux.HandleFunc("PATCH /activities/person-check-ins/{checkInId}", h.HandleUpdateCheckIn)
	mux.HandleFunc("DELETE /activities/person-check-ins/{checkInId}", h.HandleDeleteCheckIn)
	mux.HandleFunc("POST /activities/person-check-ins/{checkInId}/follow-ups/{index}/convert-to-goal", h.HandleConvertFollowUpToGoal)
}

// HandleCreateCheckIn handles POST /activities/person-check-ins.
func (h *Handler) HandleCreateCheckIn(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}
	tenantID := middleware.GetTenantID(r.Context())

	var req CreatePersonCheckInRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x40010011", "Invalid request body: "+err.Error())
		return
	}

	checkIn, streak, encouragement, err := h.service.CreateCheckIn(r.Context(), userID, tenantID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	checkIn.Links = &Links{
		Self: fmt.Sprintf("/activities/person-check-ins/%s", checkIn.CheckInID),
	}

	w.Header().Set("Location", fmt.Sprintf("/activities/person-check-ins/%s", checkIn.CheckInID))
	writeJSON(w, http.StatusCreated, PersonCheckInResponse{
		Data: *checkIn,
		Meta: map[string]interface{}{
			"createdAt":     checkIn.CreatedAt,
			"streakUpdated": true,
			"currentStreak": streak.CurrentStreak,
			"encouragement": encouragement,
		},
	})
}

// HandleListCheckIns handles GET /activities/person-check-ins.
func (h *Handler) HandleListCheckIns(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	params := parseListParams(r)

	checkIns, nextCursor, err := h.service.ListCheckIns(r.Context(), userID, params)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	// Add self links.
	for i := range checkIns {
		checkIns[i].Links = &Links{
			Self: fmt.Sprintf("/activities/person-check-ins/%s", checkIns[i].CheckInID),
		}
	}

	var nextLink *string
	if nextCursor != "" {
		link := fmt.Sprintf("/activities/person-check-ins?cursor=%s&limit=%d", nextCursor, params.Limit)
		nextLink = &link
	}

	writeJSON(w, http.StatusOK, PersonCheckInListResponse{
		Data: checkIns,
		Links: PaginationLinks{
			Self: r.URL.String(),
			Next: nextLink,
		},
		Meta: map[string]interface{}{
			"page": PageMetadata{
				NextCursor: stringPtrOrNil(nextCursor),
				Limit:      params.Limit,
			},
		},
	})
}

// HandleQuickLogCheckIn handles POST /activities/person-check-ins/quick.
func (h *Handler) HandleQuickLogCheckIn(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}
	tenantID := middleware.GetTenantID(r.Context())

	var req QuickLogPersonCheckInRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x40010011", "Invalid request body: "+err.Error())
		return
	}

	checkIn, streak, encouragement, err := h.service.QuickLogCheckIn(r.Context(), userID, tenantID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	checkIn.Links = &Links{
		Self: fmt.Sprintf("/activities/person-check-ins/%s", checkIn.CheckInID),
	}

	w.Header().Set("Location", fmt.Sprintf("/activities/person-check-ins/%s", checkIn.CheckInID))
	writeJSON(w, http.StatusCreated, PersonCheckInResponse{
		Data: *checkIn,
		Meta: map[string]interface{}{
			"createdAt":     checkIn.CreatedAt,
			"streakUpdated": true,
			"currentStreak": streak.CurrentStreak,
			"encouragement": encouragement,
		},
	})
}

// HandleGetCheckIn handles GET /activities/person-check-ins/{checkInId}.
func (h *Handler) HandleGetCheckIn(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	checkInID := r.PathValue("checkInId")
	if checkInID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x40010014", "Check-in ID is required")
		return
	}

	checkIn, err := h.service.GetCheckIn(r.Context(), userID, checkInID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	checkIn.Links = &Links{
		Self: fmt.Sprintf("/activities/person-check-ins/%s", checkIn.CheckInID),
	}

	writeJSON(w, http.StatusOK, PersonCheckInResponse{Data: *checkIn})
}

// HandleUpdateCheckIn handles PATCH /activities/person-check-ins/{checkInId}.
func (h *Handler) HandleUpdateCheckIn(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	checkInID := r.PathValue("checkInId")
	if checkInID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x40010014", "Check-in ID is required")
		return
	}

	var req UpdatePersonCheckInRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x40010011", "Invalid request body: "+err.Error())
		return
	}

	checkIn, err := h.service.UpdateCheckIn(r.Context(), userID, checkInID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	checkIn.Links = &Links{
		Self: fmt.Sprintf("/activities/person-check-ins/%s", checkIn.CheckInID),
	}

	writeJSON(w, http.StatusOK, PersonCheckInResponse{Data: *checkIn})
}

// HandleDeleteCheckIn handles DELETE /activities/person-check-ins/{checkInId}.
func (h *Handler) HandleDeleteCheckIn(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}
	tenantID := middleware.GetTenantID(r.Context())

	checkInID := r.PathValue("checkInId")
	if checkInID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x40010014", "Check-in ID is required")
		return
	}

	if err := h.service.DeleteCheckIn(r.Context(), userID, tenantID, checkInID); err != nil {
		writeServiceError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// HandleGetStreaks handles GET /activities/person-check-ins/streaks.
func (h *Handler) HandleGetStreaks(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}
	tenantID := middleware.GetTenantID(r.Context())

	streaks, err := h.service.GetStreaks(r.Context(), userID, tenantID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, PersonCheckInStreaksResponse{
		Data:  *streaks,
		Links: Links{Self: "/activities/person-check-ins/streaks"},
		Meta: map[string]interface{}{
			"retrievedAt": time.Now(),
		},
	})
}

// HandleGetSettings handles GET /activities/person-check-ins/settings.
func (h *Handler) HandleGetSettings(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}
	tenantID := middleware.GetTenantID(r.Context())

	settings, err := h.service.GetSettings(r.Context(), userID, tenantID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, PersonCheckInSettingsResponse{
		Data:  *settings,
		Links: Links{Self: "/activities/person-check-ins/settings"},
		Meta: map[string]interface{}{
			"modifiedAt": settings.ModifiedAt,
		},
	})
}

// HandleUpdateSettings handles PATCH /activities/person-check-ins/settings.
func (h *Handler) HandleUpdateSettings(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}
	tenantID := middleware.GetTenantID(r.Context())

	var req UpdateSettingsRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x40010011", "Invalid request body: "+err.Error())
		return
	}

	settings, err := h.service.UpdateSettings(r.Context(), userID, tenantID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, PersonCheckInSettingsResponse{
		Data:  *settings,
		Links: Links{Self: "/activities/person-check-ins/settings"},
		Meta: map[string]interface{}{
			"modifiedAt": settings.ModifiedAt,
		},
	})
}

// HandleGetTrends handles GET /activities/person-check-ins/trends.
func (h *Handler) HandleGetTrends(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}
	tenantID := middleware.GetTenantID(r.Context())

	period := r.URL.Query().Get("period")
	if period == "" {
		writeError(w, http.StatusUnprocessableEntity, "rr:0x42210001", "Query parameter 'period' is required")
		return
	}
	if period != "7d" && period != "30d" && period != "90d" {
		writeError(w, http.StatusUnprocessableEntity, "rr:0x42210002", "period must be one of: 7d, 30d, 90d")
		return
	}

	var checkInTypeFilter *CheckInType
	if ciType := r.URL.Query().Get("checkInType"); ciType != "" {
		t := CheckInType(ciType)
		if !isValidCheckInType(t) {
			writeError(w, http.StatusUnprocessableEntity, "rr:0x42210003", "Invalid checkInType filter")
			return
		}
		checkInTypeFilter = &t
	}

	trends, err := h.service.GetTrends(r.Context(), userID, tenantID, period, checkInTypeFilter)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, PersonCheckInTrendsResponse{
		Data:  *trends,
		Links: Links{Self: fmt.Sprintf("/activities/person-check-ins/trends?period=%s", period)},
		Meta: map[string]interface{}{
			"period":       period,
			"calculatedAt": time.Now(),
		},
	})
}

// HandleGetCalendar handles GET /activities/person-check-ins/calendar.
func (h *Handler) HandleGetCalendar(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	month := r.URL.Query().Get("month")
	if month == "" {
		writeError(w, http.StatusUnprocessableEntity, "rr:0x42210004", "Query parameter 'month' is required (YYYY-MM)")
		return
	}

	calendar, err := h.service.GetCalendar(r.Context(), userID, month)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	var totalCheckIns int
	for _, day := range calendar.Days {
		for _, ci := range day.CheckIns {
			totalCheckIns += ci.Count
		}
	}

	writeJSON(w, http.StatusOK, PersonCheckInCalendarResponse{
		Data:  *calendar,
		Links: Links{Self: fmt.Sprintf("/activities/person-check-ins/calendar?month=%s", month)},
		Meta: map[string]interface{}{
			"totalCheckIns": totalCheckIns,
		},
	})
}

// HandleConvertFollowUpToGoal handles POST .../follow-ups/{index}/convert-to-goal.
func (h *Handler) HandleConvertFollowUpToGoal(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	checkInID := r.PathValue("checkInId")
	if checkInID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x40010014", "Check-in ID is required")
		return
	}

	indexStr := r.PathValue("index")
	index, err := strconv.Atoi(indexStr)
	if err != nil || index < 0 || index > 2 {
		writeError(w, http.StatusBadRequest, "rr:0x40010015", "Follow-up index must be 0, 1, or 2")
		return
	}

	result, err := h.service.ConvertFollowUpToGoal(r.Context(), userID, checkInID, index)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	w.Header().Set("Location", result.Links.Goal)
	writeJSON(w, http.StatusCreated, ConvertFollowUpResponse{
		Data: *result,
	})
}

// --- Helper functions ---

func parseListParams(r *http.Request) ListCheckInsParams {
	params := ListCheckInsParams{
		Sort:  r.URL.Query().Get("sort"),
		Cursor: r.URL.Query().Get("cursor"),
	}

	if ciType := r.URL.Query().Get("checkInType"); ciType != "" {
		t := CheckInType(ciType)
		params.CheckInType = &t
	}

	if method := r.URL.Query().Get("method"); method != "" {
		m := Method(method)
		params.Method = &m
	}

	if minQR := r.URL.Query().Get("minQualityRating"); minQR != "" {
		if val, err := strconv.Atoi(minQR); err == nil {
			params.MinQualityRating = &val
		}
	}

	if topic := r.URL.Query().Get("topic"); topic != "" {
		t := Topic(topic)
		params.Topic = &t
	}

	if sd := r.URL.Query().Get("startDate"); sd != "" {
		if t, err := time.Parse("2006-01-02", sd); err == nil {
			params.StartDate = &t
		}
	}

	if ed := r.URL.Query().Get("endDate"); ed != "" {
		if t, err := time.Parse("2006-01-02", ed); err == nil {
			params.EndDate = &t
		}
	}

	if q := r.URL.Query().Get("q"); q != "" {
		params.Query = &q
	}

	if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
		if val, err := strconv.Atoi(limitStr); err == nil {
			params.Limit = val
		}
	}

	if params.Limit <= 0 {
		params.Limit = 25
	}
	if params.Limit > 100 {
		params.Limit = 100
	}

	return params
}

func stringPtrOrNil(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}

// --- Response helpers ---

type errorResponse struct {
	Errors []apiError `json:"errors"`
}

type apiError struct {
	Status int    `json:"status"`
	Code   string `json:"code"`
	Title  string `json:"title"`
	Detail string `json:"detail,omitempty"`
}

func writeJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Api-Version", "1.0.0")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

func writeError(w http.ResponseWriter, status int, code string, message string) {
	writeJSON(w, status, errorResponse{
		Errors: []apiError{{
			Status: status,
			Code:   code,
			Title:  message,
		}},
	})
}

func writeServiceError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, ErrCheckInNotFound):
		writeError(w, http.StatusNotFound, "rr:0x40410001", "Person check-in not found")
	case errors.Is(err, ErrFollowUpIndexOutOfRange):
		writeError(w, http.StatusNotFound, "rr:0x40410002", "Follow-up item not found")
	case errors.Is(err, ErrFollowUpAlreadyConverted):
		writeError(w, http.StatusConflict, "rr:0x40910001", "Follow-up item has already been converted to a goal")
	case errors.Is(err, ErrInvalidCheckInType),
		errors.Is(err, ErrInvalidMethod),
		errors.Is(err, ErrContactNameTooLong),
		errors.Is(err, ErrNotesTooLong),
		errors.Is(err, ErrQualityRatingOutOfRange),
		errors.Is(err, ErrInvalidTopic),
		errors.Is(err, ErrTooManyFollowUpItems),
		errors.Is(err, ErrFollowUpItemTooLong),
		errors.Is(err, ErrDurationOutOfRange),
		errors.Is(err, ErrCounselorSubCategoryForNonCounselor),
		errors.Is(err, ErrInvalidCounselorSubCategory),
		errors.Is(err, ErrInvalidStreakFrequency),
		errors.Is(err, ErrInactivityAlertDaysOutOfRange),
		errors.Is(err, ErrTimestampInFuture):
		writeError(w, http.StatusUnprocessableEntity, "rr:0x42210001", err.Error())
	case errors.Is(err, ErrImmutableField):
		writeError(w, http.StatusUnprocessableEntity, "rr:0x42210002", err.Error())
	default:
		writeError(w, http.StatusInternalServerError, "rr:0x50010001", "Internal server error")
	}
}
