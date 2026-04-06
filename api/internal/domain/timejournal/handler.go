// internal/domain/timejournal/handler.go
package timejournal

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"github.com/regalrecovery/api/internal/middleware"
)

// Handler holds route handlers for the time journal endpoints.
type Handler struct {
	service *TimeJournalService
}

// NewHandler creates a new Handler with the given service.
func NewHandler(service *TimeJournalService) *Handler {
	return &Handler{service: service}
}

// RegisterRoutes registers time journal routes on the given mux.
func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("GET /activities/time-journal/entries", h.HandleListEntries)
	mux.HandleFunc("POST /activities/time-journal/entries", h.HandleCreateEntry)
	mux.HandleFunc("GET /activities/time-journal/entries/{entryId}", h.HandleGetEntry)
	mux.HandleFunc("PATCH /activities/time-journal/entries/{entryId}", h.HandleUpdateEntry)
	mux.HandleFunc("GET /activities/time-journal/days/{date}", h.HandleGetDay)
	mux.HandleFunc("GET /activities/time-journal/days", h.HandleListDays)
	mux.HandleFunc("GET /activities/time-journal/streaks", h.HandleGetStreaks)
	mux.HandleFunc("GET /activities/time-journal/status", h.HandleGetStatus)
}

// HandleListEntries handles GET /activities/time-journal/entries.
func (h *Handler) HandleListEntries(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	date := r.URL.Query().Get("date")
	if date == "" {
		writeError(w, http.StatusBadRequest, "rr:0x40010010", "Query parameter 'date' is required")
		return
	}

	modeStr := r.URL.Query().Get("mode")
	mode := TimeJournalMode(modeStr)
	if mode != ModeT30 && mode != ModeT60 {
		mode = ModeT60 // default
	}

	entries, err := h.service.GetEntriesForDate(r.Context(), userID, date, mode)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, EntriesResponse{
		Data: entries,
		Meta: map[string]interface{}{
			"date":  date,
			"mode":  mode,
			"count": len(entries),
		},
	})
}

// HandleCreateEntry handles POST /activities/time-journal/entries.
func (h *Handler) HandleCreateEntry(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	var req CreateTimeJournalEntryRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x40010011", "Invalid request body: "+err.Error())
		return
	}

	if req.Date == "" || req.SlotStart == "" {
		writeError(w, http.StatusBadRequest, "rr:0x40010012", "Fields 'date' and 'slotStart' are required")
		return
	}
	if req.Mode != ModeT30 && req.Mode != ModeT60 {
		writeError(w, http.StatusBadRequest, "rr:0x40010013", "Field 'mode' must be 'T30' or 'T60'")
		return
	}

	entry, err := h.service.CreateEntry(r.Context(), userID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	w.Header().Set("Location", fmt.Sprintf("/activities/time-journal/entries/%s", entry.ID))
	writeJSON(w, http.StatusCreated, EntryResponse{
		Data: *entry,
		Meta: map[string]interface{}{"created": true},
	})
}

// HandleGetEntry handles GET /activities/time-journal/entries/{entryId}.
func (h *Handler) HandleGetEntry(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	entryID := r.PathValue("entryId")
	if entryID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x40010014", "Entry ID is required")
		return
	}

	entry, err := h.service.GetEntry(r.Context(), userID, entryID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, EntryResponse{Data: *entry})
}

// HandleUpdateEntry handles PATCH /activities/time-journal/entries/{entryId}.
func (h *Handler) HandleUpdateEntry(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	entryID := r.PathValue("entryId")
	if entryID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x40010014", "Entry ID is required")
		return
	}

	var req UpdateTimeJournalEntryRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x40010011", "Invalid request body: "+err.Error())
		return
	}

	entry, err := h.service.UpdateEntry(r.Context(), userID, entryID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, EntryResponse{Data: *entry})
}

// HandleGetDay handles GET /activities/time-journal/days/{date}.
func (h *Handler) HandleGetDay(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	date := r.PathValue("date")
	if date == "" {
		writeError(w, http.StatusBadRequest, "rr:0x40010015", "Date path parameter is required")
		return
	}

	day, err := h.service.GetDaySummary(r.Context(), userID, date)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, DayResponse{Data: *day})
}

// HandleListDays handles GET /activities/time-journal/days.
func (h *Handler) HandleListDays(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	startDate := r.URL.Query().Get("startDate")
	endDate := r.URL.Query().Get("endDate")
	cursor := r.URL.Query().Get("cursor")
	limitStr := r.URL.Query().Get("limit")

	limit := 50
	if limitStr != "" {
		if parsed, err := strconv.Atoi(limitStr); err == nil && parsed > 0 && parsed <= 100 {
			limit = parsed
		}
	}

	var mode *TimeJournalMode
	if modeStr := r.URL.Query().Get("mode"); modeStr != "" {
		m := TimeJournalMode(modeStr)
		mode = &m
	}

	days, nextCursor, err := h.service.GetDaySummaries(r.Context(), userID, startDate, endDate, mode, cursor, limit)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	links := map[string]string{
		"self": r.URL.String(),
	}
	if nextCursor != "" {
		links["next"] = fmt.Sprintf("/activities/time-journal/days?cursor=%s&limit=%d", nextCursor, limit)
	}

	writeJSON(w, http.StatusOK, DaysResponse{
		Data:  days,
		Links: links,
		Meta: map[string]interface{}{
			"count": len(days),
		},
	})
}

// HandleGetStreaks handles GET /activities/time-journal/streaks.
func (h *Handler) HandleGetStreaks(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	streak, err := h.service.GetStreak(r.Context(), userID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, StreakResponse{Data: *streak})
}

// HandleGetStatus handles GET /activities/time-journal/status.
func (h *Handler) HandleGetStatus(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	modeStr := r.URL.Query().Get("mode")
	mode := TimeJournalMode(modeStr)
	if mode != ModeT30 && mode != ModeT60 {
		mode = ModeT60
	}

	status, err := h.service.GetTodayStatus(r.Context(), userID, mode)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, StatusResponse{Data: *status})
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
	writeJSON(w, status, errorResponse{
		Errors: []apiError{{Code: code, Message: message}},
	})
}

func writeServiceError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, ErrEntryNotFound), errors.Is(err, ErrDayNotFound):
		writeError(w, http.StatusNotFound, "rr:0x40410001", err.Error())
	case errors.Is(err, ErrInvalidInput):
		writeError(w, http.StatusBadRequest, "rr:0x40010020", err.Error())
	case errors.Is(err, ErrEditWindowExpired):
		writeError(w, http.StatusForbidden, "rr:0x40310001", err.Error())
	case errors.Is(err, ErrDuplicateSlot):
		writeError(w, http.StatusConflict, "rr:0x40910001", err.Error())
	default:
		if strings.Contains(err.Error(), "duplicate") {
			writeError(w, http.StatusConflict, "rr:0x40910001", "Slot already exists")
			return
		}
		writeError(w, http.StatusInternalServerError, "rr:0x50010001", "Internal server error")
	}
}
