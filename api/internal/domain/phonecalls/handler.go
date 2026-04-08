// internal/domain/phonecalls/handler.go
package phonecalls

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/regalrecovery/api/internal/middleware"
)

// Handler holds route handlers for the phone calls endpoints.
type Handler struct {
	service *PhoneCallService
}

// NewHandler creates a new Handler with the given service.
func NewHandler(service *PhoneCallService) *Handler {
	return &Handler{service: service}
}

// RegisterRoutes registers phone call routes on the given mux.
func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("POST /activities/phone-calls", h.HandleCreatePhoneCall)
	mux.HandleFunc("GET /activities/phone-calls", h.HandleListPhoneCalls)
	mux.HandleFunc("GET /activities/phone-calls/streak", h.HandleGetStreak)
	mux.HandleFunc("GET /activities/phone-calls/trends", h.HandleGetTrends)
	mux.HandleFunc("GET /activities/phone-calls/trends/daily", h.HandleGetDailyTrends)
	mux.HandleFunc("GET /activities/phone-calls/saved-contacts", h.HandleListSavedContacts)
	mux.HandleFunc("POST /activities/phone-calls/saved-contacts", h.HandleCreateSavedContact)
	mux.HandleFunc("GET /activities/phone-calls/{callId}", h.HandleGetPhoneCall)
	mux.HandleFunc("PATCH /activities/phone-calls/{callId}", h.HandleUpdatePhoneCall)
	mux.HandleFunc("DELETE /activities/phone-calls/{callId}", h.HandleDeletePhoneCall)
	mux.HandleFunc("PATCH /activities/phone-calls/saved-contacts/{savedContactId}", h.HandleUpdateSavedContact)
	mux.HandleFunc("DELETE /activities/phone-calls/saved-contacts/{savedContactId}", h.HandleDeleteSavedContact)
}

// HandleCreatePhoneCall handles POST /activities/phone-calls.
func (h *Handler) HandleCreatePhoneCall(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40110001", "Authentication required")
		return
	}
	tenantID := middleware.GetTenantID(r.Context())

	var req CreatePhoneCallRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x40010001", "Invalid request body: "+err.Error())
		return
	}

	call, err := h.service.CreateCall(r.Context(), userID, tenantID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	w.Header().Set("Location", fmt.Sprintf("/activities/phone-calls/%s", call.CallID))
	writeJSON(w, http.StatusCreated, PhoneCallResponse{
		Data: *call,
		Meta: map[string]interface{}{
			"createdAt": call.CreatedAt,
		},
	})
}

// HandleListPhoneCalls handles GET /activities/phone-calls.
func (h *Handler) HandleListPhoneCalls(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40110001", "Authentication required")
		return
	}

	filters := parseListFilters(r)
	cursor := r.URL.Query().Get("cursor")
	limit := parseLimit(r)

	calls, nextCursor, err := h.service.ListCalls(r.Context(), userID, filters, cursor, limit)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	links := map[string]string{
		"self": r.URL.String(),
	}
	if nextCursor != "" {
		links["next"] = fmt.Sprintf("/activities/phone-calls?cursor=%s&limit=%d", nextCursor, limit)
	}

	writeJSON(w, http.StatusOK, PhoneCallListResponse{
		Data:  calls,
		Links: links,
		Meta: map[string]interface{}{
			"page": map[string]interface{}{
				"nextCursor": nextCursor,
				"limit":      limit,
			},
		},
	})
}

// HandleGetPhoneCall handles GET /activities/phone-calls/{callId}.
func (h *Handler) HandleGetPhoneCall(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40110001", "Authentication required")
		return
	}

	callID := r.PathValue("callId")
	if callID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x40010002", "Call ID is required")
		return
	}

	call, err := h.service.GetCall(r.Context(), userID, callID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, PhoneCallResponse{Data: *call})
}

// HandleUpdatePhoneCall handles PATCH /activities/phone-calls/{callId}.
func (h *Handler) HandleUpdatePhoneCall(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40110001", "Authentication required")
		return
	}

	callID := r.PathValue("callId")
	if callID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x40010002", "Call ID is required")
		return
	}

	var req UpdatePhoneCallRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x40010001", "Invalid request body: "+err.Error())
		return
	}

	call, err := h.service.UpdateCall(r.Context(), userID, callID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, PhoneCallResponse{Data: *call})
}

// HandleDeletePhoneCall handles DELETE /activities/phone-calls/{callId}.
func (h *Handler) HandleDeletePhoneCall(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40110001", "Authentication required")
		return
	}

	callID := r.PathValue("callId")
	if callID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x40010002", "Call ID is required")
		return
	}

	if err := h.service.DeleteCall(r.Context(), userID, callID); err != nil {
		writeServiceError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// HandleGetStreak handles GET /activities/phone-calls/streak.
func (h *Handler) HandleGetStreak(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40110001", "Authentication required")
		return
	}

	streak, err := h.service.GetStreak(r.Context(), userID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, StreakResponse{
		Data: *streak,
		Meta: map[string]interface{}{
			"calculatedAt": timeNowUTC(),
		},
	})
}

// HandleGetTrends handles GET /activities/phone-calls/trends.
func (h *Handler) HandleGetTrends(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40110001", "Authentication required")
		return
	}

	period := parsePeriod(r)
	trends, err := h.service.GetTrends(r.Context(), userID, period, DefaultIsolationThresholdDays)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, TrendsResponse{
		Data: *trends,
		Meta: map[string]interface{}{
			"calculatedAt": timeNowUTC(),
		},
	})
}

// HandleGetDailyTrends handles GET /activities/phone-calls/trends/daily.
func (h *Handler) HandleGetDailyTrends(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40110001", "Authentication required")
		return
	}

	period := parsePeriod(r)
	daily, err := h.service.GetDailyTrends(r.Context(), userID, period)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, DailyTrendsResponse{
		Data: daily,
		Meta: map[string]interface{}{
			"period":    period,
			"totalDays": len(daily),
		},
	})
}

// HandleCreateSavedContact handles POST /activities/phone-calls/saved-contacts.
func (h *Handler) HandleCreateSavedContact(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40110001", "Authentication required")
		return
	}
	tenantID := middleware.GetTenantID(r.Context())

	var req CreateSavedContactRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x40010001", "Invalid request body: "+err.Error())
		return
	}

	contact, err := h.service.CreateSavedContact(r.Context(), userID, tenantID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	w.Header().Set("Location", fmt.Sprintf("/activities/phone-calls/saved-contacts/%s", contact.SavedContactID))
	writeJSON(w, http.StatusCreated, SavedContactResponse{
		Data: *contact,
		Meta: map[string]interface{}{
			"createdAt": contact.CreatedAt,
		},
	})
}

// HandleListSavedContacts handles GET /activities/phone-calls/saved-contacts.
func (h *Handler) HandleListSavedContacts(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40110001", "Authentication required")
		return
	}

	contacts, err := h.service.ListSavedContacts(r.Context(), userID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, SavedContactListResponse{
		Data: contacts,
		Meta: map[string]interface{}{
			"totalContacts": len(contacts),
		},
	})
}

// HandleUpdateSavedContact handles PATCH /activities/phone-calls/saved-contacts/{savedContactId}.
func (h *Handler) HandleUpdateSavedContact(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40110001", "Authentication required")
		return
	}

	savedContactID := r.PathValue("savedContactId")
	if savedContactID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x40010003", "Saved contact ID is required")
		return
	}

	var req UpdateSavedContactRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x40010001", "Invalid request body: "+err.Error())
		return
	}

	contact, err := h.service.UpdateSavedContact(r.Context(), userID, savedContactID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, SavedContactResponse{Data: *contact})
}

// HandleDeleteSavedContact handles DELETE /activities/phone-calls/saved-contacts/{savedContactId}.
func (h *Handler) HandleDeleteSavedContact(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40110001", "Authentication required")
		return
	}

	savedContactID := r.PathValue("savedContactId")
	if savedContactID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x40010003", "Saved contact ID is required")
		return
	}

	if err := h.service.DeleteSavedContact(r.Context(), userID, savedContactID); err != nil {
		writeServiceError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
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
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

func writeError(w http.ResponseWriter, status int, code string, detail string) {
	writeJSON(w, status, errorResponse{
		Errors: []apiError{{
			Status: status,
			Code:   code,
			Title:  http.StatusText(status),
			Detail: detail,
		}},
	})
}

func writeServiceError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, ErrPhoneCallNotFound), errors.Is(err, ErrSavedContactNotFound):
		writeError(w, http.StatusNotFound, "rr:0x40410001", err.Error())
	case errors.Is(err, ErrTimestampImmutable):
		writeError(w, http.StatusUnprocessableEntity, "rr:0x42210001", err.Error())
	case errors.Is(err, ErrInvalidDirection),
		errors.Is(err, ErrInvalidContactType),
		errors.Is(err, ErrCustomLabelRequired),
		errors.Is(err, ErrContactNameTooLong),
		errors.Is(err, ErrNotesTooLong),
		errors.Is(err, ErrNegativeDuration),
		errors.Is(err, ErrInvalidPhoneNumber),
		errors.Is(err, ErrSavedContactNameRequired),
		errors.Is(err, ErrMaxSavedContacts):
		writeError(w, http.StatusUnprocessableEntity, "rr:0x42210002", err.Error())
	default:
		writeError(w, http.StatusInternalServerError, "rr:0x50010001", "Internal server error")
	}
}

// --- Query parameter helpers ---

func parseListFilters(r *http.Request) ListFilters {
	filters := ListFilters{}

	if d := r.URL.Query().Get("direction"); d != "" {
		dir := Direction(d)
		filters.Direction = &dir
	}
	if ct := r.URL.Query().Get("contactType"); ct != "" {
		contactType := ContactType(ct)
		filters.ContactType = &contactType
	}
	if c := r.URL.Query().Get("connected"); c != "" {
		connected := c == "true"
		filters.Connected = &connected
	}
	if sd := r.URL.Query().Get("startDate"); sd != "" {
		filters.StartDate = &sd
	}
	if ed := r.URL.Query().Get("endDate"); ed != "" {
		filters.EndDate = &ed
	}
	if s := r.URL.Query().Get("search"); s != "" {
		filters.Search = &s
	}

	return filters
}

func parseLimit(r *http.Request) int {
	limit := 50
	if l := r.URL.Query().Get("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 && parsed <= 100 {
			limit = parsed
		}
	}
	return limit
}

func parsePeriod(r *http.Request) TrendPeriod {
	p := r.URL.Query().Get("period")
	switch TrendPeriod(p) {
	case TrendPeriod7d:
		return TrendPeriod7d
	case TrendPeriod90d:
		return TrendPeriod90d
	default:
		return TrendPeriod30d
	}
}

func timeNowUTC() string {
	return fmt.Sprintf("%s", time.Now().UTC().Format(time.RFC3339))
}
