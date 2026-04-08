// internal/handler/prayer_session_handler.go
package handler

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"time"

	"github.com/regalrecovery/api/internal/domain/prayer"
)

// PrayerSessionHandler handles HTTP requests for prayer session endpoints.
type PrayerSessionHandler struct {
	service  *prayer.Service
	baseURL  string
}

// NewPrayerSessionHandler creates a new PrayerSessionHandler.
func NewPrayerSessionHandler(service *prayer.Service, baseURL string) *PrayerSessionHandler {
	return &PrayerSessionHandler{
		service: service,
		baseURL: baseURL,
	}
}

// CreatePrayerSession handles POST /activities/prayer.
func (h *PrayerSessionHandler) CreatePrayerSession(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("userID").(string)

	var body struct {
		Timestamp       string  `json:"timestamp"`
		PrayerType      string  `json:"prayerType"`
		DurationMinutes *int    `json:"durationMinutes,omitempty"`
		Notes           *string `json:"notes,omitempty"`
		LinkedPrayerID  *string `json:"linkedPrayerId,omitempty"`
		MoodBefore      *int    `json:"moodBefore,omitempty"`
		MoodAfter       *int    `json:"moodAfter,omitempty"`
		IsEphemeral     bool    `json:"isEphemeral"`
	}

	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x00500000", "Bad Request", "Request body is malformed")
		return
	}

	ts, err := time.Parse(time.RFC3339, body.Timestamp)
	if err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x00500000", "Bad Request", "timestamp must be RFC3339 format")
		return
	}

	req := &prayer.CreatePrayerSessionRequest{
		Timestamp:       ts,
		PrayerType:      body.PrayerType,
		DurationMinutes: body.DurationMinutes,
		Notes:           body.Notes,
		LinkedPrayerID:  body.LinkedPrayerID,
		MoodBefore:      body.MoodBefore,
		MoodAfter:       body.MoodAfter,
		IsEphemeral:     body.IsEphemeral,
	}

	session, err := h.service.CreateSession(r.Context(), userID, req)
	if err != nil {
		writeDomainError(w, err)
		return
	}

	w.Header().Set("Location", prayer.SelfLink(h.baseURL, session.PrayerID))
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"data": sessionToJSON(session, h.baseURL),
		"meta": map[string]interface{}{
			"createdAt": session.CreatedAt.Format(time.RFC3339),
		},
	})
}

// ListPrayerSessions handles GET /activities/prayer.
func (h *PrayerSessionHandler) ListPrayerSessions(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("userID").(string)
	q := r.URL.Query()

	var prayerType *string
	if pt := q.Get("prayerType"); pt != "" {
		prayerType = &pt
	}

	var startDate, endDate *time.Time
	if sd := q.Get("startDate"); sd != "" {
		t, _ := time.Parse("2006-01-02", sd)
		startDate = &t
	}
	if ed := q.Get("endDate"); ed != "" {
		t, _ := time.Parse("2006-01-02", ed)
		endDate = &t
	}

	var linkedPrayerID *string
	if lp := q.Get("linkedPrayerId"); lp != "" {
		linkedPrayerID = &lp
	}

	cursor := q.Get("cursor")
	limit := 50
	if l := q.Get("limit"); l != "" {
		limit, _ = strconv.Atoi(l)
	}

	sessions, nextCursor, err := h.service.ListSessions(r.Context(), userID, prayerType, startDate, endDate, linkedPrayerID, cursor, limit)
	if err != nil {
		writeDomainError(w, err)
		return
	}

	data := make([]interface{}, len(sessions))
	for i, s := range sessions {
		data[i] = sessionSummaryToJSON(&s, h.baseURL)
	}

	response := map[string]interface{}{
		"data": data,
		"meta": map[string]interface{}{
			"page": map[string]interface{}{
				"nextCursor": nilIfEmpty(nextCursor),
				"limit":      limit,
			},
		},
	}

	if nextCursor != "" {
		response["links"] = map[string]string{
			"self": r.URL.String(),
			"next": r.URL.Path + "?cursor=" + nextCursor,
		}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// GetPrayerSession handles GET /activities/prayer/{id}.
func (h *PrayerSessionHandler) GetPrayerSession(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("userID").(string)
	prayerID := r.PathValue("id")

	session, err := h.service.GetSession(r.Context(), userID, prayerID)
	if err != nil {
		writeDomainError(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"data": sessionToJSON(session, h.baseURL),
		"meta": map[string]interface{}{
			"createdAt":  session.CreatedAt.Format(time.RFC3339),
			"modifiedAt": session.ModifiedAt.Format(time.RFC3339),
		},
	})
}

// UpdatePrayerSession handles PATCH /activities/prayer/{id}.
func (h *PrayerSessionHandler) UpdatePrayerSession(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("userID").(string)
	prayerID := r.PathValue("id")

	var body struct {
		PrayerType      *string `json:"prayerType,omitempty"`
		DurationMinutes *int    `json:"durationMinutes,omitempty"`
		Notes           *string `json:"notes,omitempty"`
		LinkedPrayerID  *string `json:"linkedPrayerId,omitempty"`
		MoodBefore      *int    `json:"moodBefore,omitempty"`
		MoodAfter       *int    `json:"moodAfter,omitempty"`
		Timestamp       *string `json:"timestamp,omitempty"`
	}

	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x00500000", "Bad Request", "Request body is malformed")
		return
	}

	req := &prayer.UpdatePrayerSessionRequest{
		PrayerType:      body.PrayerType,
		DurationMinutes: body.DurationMinutes,
		Notes:           body.Notes,
		LinkedPrayerID:  body.LinkedPrayerID,
		MoodBefore:      body.MoodBefore,
		MoodAfter:       body.MoodAfter,
	}

	// Detect timestamp immutability violation.
	if body.Timestamp != nil {
		ts, _ := time.Parse(time.RFC3339, *body.Timestamp)
		req.Timestamp = &ts
	}

	session, err := h.service.UpdateSession(r.Context(), userID, prayerID, req)
	if err != nil {
		writeDomainError(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"data": sessionToJSON(session, h.baseURL),
		"meta": map[string]interface{}{
			"createdAt":  session.CreatedAt.Format(time.RFC3339),
			"modifiedAt": session.ModifiedAt.Format(time.RFC3339),
		},
	})
}

// DeletePrayerSession handles DELETE /activities/prayer/{id}.
func (h *PrayerSessionHandler) DeletePrayerSession(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("userID").(string)
	prayerID := r.PathValue("id")

	err := h.service.DeleteSession(r.Context(), userID, prayerID)
	if err != nil {
		writeDomainError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// GetPrayerStats handles GET /activities/prayer/stats.
func (h *PrayerSessionHandler) GetPrayerStats(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("userID").(string)

	// Use user's timezone from context or default to UTC.
	loc := time.UTC
	if tz := r.Header.Get("X-Timezone"); tz != "" {
		if l, err := time.LoadLocation(tz); err == nil {
			loc = l
		}
	}

	stats, err := h.service.GetStats(r.Context(), userID, loc)
	if err != nil {
		writeDomainError(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"data": statsToJSON(stats),
	})
}

// sessionToJSON converts a PrayerSession to a JSON-friendly map.
func sessionToJSON(s *prayer.PrayerSession, baseURL string) map[string]interface{} {
	result := map[string]interface{}{
		"prayerId":    s.PrayerID,
		"timestamp":   s.Timestamp.Format(time.RFC3339),
		"prayerType":  s.PrayerType,
		"isEphemeral": s.IsEphemeral,
		"links": map[string]string{
			"self": prayer.SelfLink(baseURL, s.PrayerID),
		},
	}

	if s.DurationMinutes != nil {
		result["durationMinutes"] = *s.DurationMinutes
	} else {
		result["durationMinutes"] = nil
	}
	if s.Notes != nil {
		result["notes"] = *s.Notes
	} else {
		result["notes"] = nil
	}
	if s.LinkedPrayerID != nil {
		result["linkedPrayerId"] = *s.LinkedPrayerID
	} else {
		result["linkedPrayerId"] = nil
	}
	if s.LinkedPrayerTitle != nil {
		result["linkedPrayerTitle"] = *s.LinkedPrayerTitle
	} else {
		result["linkedPrayerTitle"] = nil
	}
	if s.MoodBefore != nil {
		result["moodBefore"] = *s.MoodBefore
	} else {
		result["moodBefore"] = nil
	}
	if s.MoodAfter != nil {
		result["moodAfter"] = *s.MoodAfter
	} else {
		result["moodAfter"] = nil
	}

	return result
}

// sessionSummaryToJSON converts a session to a summary for list views.
func sessionSummaryToJSON(s *prayer.PrayerSession, baseURL string) map[string]interface{} {
	result := map[string]interface{}{
		"prayerId":   s.PrayerID,
		"timestamp":  s.Timestamp.Format(time.RFC3339),
		"prayerType": s.PrayerType,
		"links": map[string]string{
			"self": prayer.SelfLink(baseURL, s.PrayerID),
		},
	}

	if s.DurationMinutes != nil {
		result["durationMinutes"] = *s.DurationMinutes
	} else {
		result["durationMinutes"] = nil
	}
	if s.LinkedPrayerTitle != nil {
		result["linkedPrayerTitle"] = *s.LinkedPrayerTitle
	} else {
		result["linkedPrayerTitle"] = nil
	}
	if s.MoodBefore != nil {
		result["moodBefore"] = *s.MoodBefore
	} else {
		result["moodBefore"] = nil
	}
	if s.MoodAfter != nil {
		result["moodAfter"] = *s.MoodAfter
	} else {
		result["moodAfter"] = nil
	}

	return result
}

// statsToJSON converts PrayerStats to a JSON-friendly map.
func statsToJSON(s *prayer.PrayerStats) map[string]interface{} {
	result := map[string]interface{}{
		"currentStreakDays": s.CurrentStreakDays,
		"longestStreakDays": s.LongestStreakDays,
		"totalPrayerDays":  s.TotalPrayerDays,
		"sessionsThisWeek": s.SessionsThisWeek,
		"typeDistribution": s.TypeDistribution,
	}

	if s.AverageDurationMinutes != nil {
		result["averageDurationMinutes"] = *s.AverageDurationMinutes
	} else {
		result["averageDurationMinutes"] = nil
	}

	if s.MoodImpact != nil {
		mi := map[string]interface{}{}
		if s.MoodImpact.AverageMoodBefore != nil {
			mi["averageMoodBefore"] = *s.MoodImpact.AverageMoodBefore
		} else {
			mi["averageMoodBefore"] = nil
		}
		if s.MoodImpact.AverageMoodAfter != nil {
			mi["averageMoodAfter"] = *s.MoodImpact.AverageMoodAfter
		} else {
			mi["averageMoodAfter"] = nil
		}
		result["moodImpact"] = mi
	} else {
		result["moodImpact"] = nil
	}

	return result
}

// writeDomainError translates domain errors to HTTP error responses.
func writeDomainError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, prayer.ErrPrayerNotFound),
		errors.Is(err, prayer.ErrFavoriteNotFound),
		errors.Is(err, prayer.ErrFeatureDisabled):
		writeError(w, http.StatusNotFound, "", "Not Found", err.Error())

	case errors.Is(err, prayer.ErrFavoriteAlreadyExists):
		writeError(w, http.StatusConflict, "", "Conflict", err.Error())

	case errors.Is(err, prayer.ErrInvalidPrayerType),
		errors.Is(err, prayer.ErrLinkedPrayerLocked),
		errors.Is(err, prayer.ErrNotesExceedLimit),
		errors.Is(err, prayer.ErrMoodOutOfRange),
		errors.Is(err, prayer.ErrBackdatingTooFar),
		errors.Is(err, prayer.ErrTimestampImmutable),
		errors.Is(err, prayer.ErrNotesReadOnly),
		errors.Is(err, prayer.ErrTitleRequired),
		errors.Is(err, prayer.ErrBodyRequired),
		errors.Is(err, prayer.ErrTitleExceedsLimit),
		errors.Is(err, prayer.ErrDurationOutOfRange),
		errors.Is(err, prayer.ErrFutureTimestamp),
		errors.Is(err, prayer.ErrInvalidReorderIDs):
		code := prayer.ErrorCode[err]
		writeError(w, http.StatusUnprocessableEntity, code, "Unprocessable Entity", err.Error())

	default:
		writeError(w, http.StatusInternalServerError, "", "Internal Server Error", "An unexpected error occurred")
	}
}

// writeError writes a standard JSON error response.
func writeError(w http.ResponseWriter, status int, code, title, detail string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	errObj := map[string]interface{}{
		"status": status,
		"title":  title,
		"detail": detail,
	}
	if code != "" {
		errObj["code"] = code
	}
	json.NewEncoder(w).Encode(map[string]interface{}{
		"errors": []interface{}{errObj},
	})
}

// nilIfEmpty returns nil for empty strings (for JSON null output).
func nilIfEmpty(s string) interface{} {
	if s == "" {
		return nil
	}
	return s
}
