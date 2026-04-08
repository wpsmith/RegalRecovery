// internal/handler/meetings/meeting_handler.go
package meetings

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/regalrecovery/api/internal/domain/meetings"
	"github.com/regalrecovery/api/internal/middleware"
)

// MeetingHandler handles HTTP requests for meeting log endpoints.
type MeetingHandler struct {
	meetingSvc *meetings.MeetingLogService
}

// NewMeetingHandler creates a new MeetingHandler.
func NewMeetingHandler(meetingSvc *meetings.MeetingLogService) *MeetingHandler {
	return &MeetingHandler{meetingSvc: meetingSvc}
}

// HandleCreateMeetingLog handles POST /v1/activities/meetings.
func (h *MeetingHandler) HandleCreateMeetingLog(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, r, http.StatusUnauthorized, "rr:0x40010001", "Unauthorized", "Authentication required")
		return
	}
	tenantID := middleware.GetTenantID(r.Context())

	// Parse request body.
	var rawBody map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&rawBody); err != nil {
		writeError(w, r, http.StatusBadRequest, "rr:0x40000001", "Bad Request", "Invalid JSON body: "+err.Error())
		return
	}

	// Check for immutable timestamp violation in raw body (defensive).
	req, err := parseMeetingLogCreateRequest(rawBody)
	if err != nil {
		writeError(w, r, http.StatusBadRequest, "rr:0x40000002", "Bad Request", err.Error())
		return
	}

	meeting, err := h.meetingSvc.CreateMeetingLog(r.Context(), userID, tenantID, req)
	if err != nil {
		writeDomainError(w, r, err)
		return
	}

	// Set Location header.
	w.Header().Set("Location", fmt.Sprintf("/v1/activities/meetings/%s", meeting.MeetingID))

	resp := meetings.MeetingLogResponse{
		Data: toMeetingLogData(meeting),
		Meta: map[string]interface{}{
			"createdAt": meeting.CreatedAt.Format(time.RFC3339),
		},
	}

	writeJSON(w, http.StatusCreated, resp)
}

// HandleListMeetingLogs handles GET /v1/activities/meetings.
func (h *MeetingHandler) HandleListMeetingLogs(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, r, http.StatusUnauthorized, "rr:0x40010001", "Unauthorized", "Authentication required")
		return
	}

	filter := meetings.ListMeetingLogsFilter{}

	// Parse query parameters.
	if mt := r.URL.Query().Get("meetingType"); mt != "" {
		mtType := meetings.MeetingType(mt)
		filter.MeetingType = &mtType
	}
	if sd := r.URL.Query().Get("startDate"); sd != "" {
		t, err := time.Parse("2006-01-02", sd)
		if err == nil {
			filter.StartDate = &t
		}
	}
	if ed := r.URL.Query().Get("endDate"); ed != "" {
		t, err := time.Parse("2006-01-02", ed)
		if err == nil {
			// End of day.
			t = t.Add(24*time.Hour - time.Nanosecond)
			filter.EndDate = &t
		}
	}
	filter.Cursor = r.URL.Query().Get("cursor")
	if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil {
			filter.Limit = l
		}
	}
	filter.Sort = r.URL.Query().Get("sort")

	meetingList, nextCursor, err := h.meetingSvc.ListMeetingLogs(r.Context(), userID, filter)
	if err != nil {
		writeDomainError(w, r, err)
		return
	}

	data := make([]meetings.MeetingLogData, 0, len(meetingList))
	for _, m := range meetingList {
		data = append(data, toMeetingLogData(m))
	}

	limit := filter.Limit
	if limit <= 0 {
		limit = 50
	}

	links := map[string]interface{}{
		"self": fmt.Sprintf("/v1/activities/meetings?limit=%d", limit),
	}
	if nextCursor != "" {
		links["next"] = fmt.Sprintf("/v1/activities/meetings?cursor=%s&limit=%d", nextCursor, limit)
	}

	resp := meetings.MeetingLogListResponse{
		Data:  data,
		Links: links,
		Meta: map[string]interface{}{
			"page": map[string]interface{}{
				"nextCursor": nextCursor,
				"limit":      limit,
			},
		},
	}

	writeJSON(w, http.StatusOK, resp)
}

// HandleGetMeetingLog handles GET /v1/activities/meetings/{meetingId}.
func (h *MeetingHandler) HandleGetMeetingLog(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, r, http.StatusUnauthorized, "rr:0x40010001", "Unauthorized", "Authentication required")
		return
	}

	meetingID := r.PathValue("meetingId")
	if meetingID == "" {
		writeError(w, r, http.StatusBadRequest, "rr:0x40000003", "Bad Request", "meetingId is required")
		return
	}

	meeting, err := h.meetingSvc.GetMeetingLog(r.Context(), userID, meetingID)
	if err != nil {
		writeDomainError(w, r, err)
		return
	}

	resp := meetings.MeetingLogResponse{
		Data: toMeetingLogData(meeting),
		Meta: map[string]interface{}{
			"createdAt":  meeting.CreatedAt.Format(time.RFC3339),
			"modifiedAt": meeting.ModifiedAt.Format(time.RFC3339),
		},
	}

	writeJSON(w, http.StatusOK, resp)
}

// HandleUpdateMeetingLog handles PATCH /v1/activities/meetings/{meetingId}.
func (h *MeetingHandler) HandleUpdateMeetingLog(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, r, http.StatusUnauthorized, "rr:0x40010001", "Unauthorized", "Authentication required")
		return
	}

	meetingID := r.PathValue("meetingId")
	if meetingID == "" {
		writeError(w, r, http.StatusBadRequest, "rr:0x40000003", "Bad Request", "meetingId is required")
		return
	}

	// Parse raw body to check for immutable timestamp field.
	var rawBody map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&rawBody); err != nil {
		writeError(w, r, http.StatusBadRequest, "rr:0x40000001", "Bad Request", "Invalid JSON body: "+err.Error())
		return
	}

	// FR2.7: Reject if timestamp is included in PATCH.
	if _, hasTimestamp := rawBody["timestamp"]; hasTimestamp {
		writeError(w, r, http.StatusUnprocessableEntity, "rr:0x42200001", "Unprocessable Entity", "timestamp is immutable")
		return
	}

	req, err := parseMeetingLogUpdateRequest(rawBody)
	if err != nil {
		writeError(w, r, http.StatusBadRequest, "rr:0x40000002", "Bad Request", err.Error())
		return
	}

	meeting, err := h.meetingSvc.UpdateMeetingLog(r.Context(), userID, meetingID, req)
	if err != nil {
		writeDomainError(w, r, err)
		return
	}

	resp := meetings.MeetingLogResponse{
		Data: toMeetingLogData(meeting),
		Meta: map[string]interface{}{
			"createdAt":  meeting.CreatedAt.Format(time.RFC3339),
			"modifiedAt": meeting.ModifiedAt.Format(time.RFC3339),
		},
	}

	writeJSON(w, http.StatusOK, resp)
}

// HandleDeleteMeetingLog handles DELETE /v1/activities/meetings/{meetingId}.
func (h *MeetingHandler) HandleDeleteMeetingLog(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, r, http.StatusUnauthorized, "rr:0x40010001", "Unauthorized", "Authentication required")
		return
	}

	meetingID := r.PathValue("meetingId")
	if meetingID == "" {
		writeError(w, r, http.StatusBadRequest, "rr:0x40000003", "Bad Request", "meetingId is required")
		return
	}

	err := h.meetingSvc.DeleteMeetingLog(r.Context(), userID, meetingID)
	if err != nil {
		writeDomainError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// --- Helpers ---

func toMeetingLogData(m *meetings.MeetingLog) meetings.MeetingLogData {
	return meetings.MeetingLogData{
		MeetingID:       m.MeetingID,
		Timestamp:       m.Timestamp,
		MeetingType:     m.MeetingType,
		CustomTypeLabel: m.CustomTypeLabel,
		Name:            m.Name,
		Location:        m.Location,
		DurationMinutes: m.DurationMinutes,
		Notes:           m.Notes,
		Status:          m.Status,
		SavedMeetingID:  m.SavedMeetingID,
		Links: meetings.MeetingLogLinks{
			Self: fmt.Sprintf("/v1/activities/meetings/%s", m.MeetingID),
		},
	}
}

func parseMeetingLogCreateRequest(raw map[string]interface{}) (*meetings.CreateMeetingLogRequest, error) {
	req := &meetings.CreateMeetingLogRequest{}

	if ts, ok := raw["timestamp"].(string); ok {
		t, err := time.Parse(time.RFC3339, ts)
		if err != nil {
			return nil, fmt.Errorf("invalid timestamp format: %s", err.Error())
		}
		req.Timestamp = t
	}

	if mt, ok := raw["meetingType"].(string); ok {
		req.MeetingType = meetings.MeetingType(mt)
	}

	if label, ok := raw["customTypeLabel"].(string); ok {
		req.CustomTypeLabel = &label
	}
	if name, ok := raw["name"].(string); ok {
		req.Name = &name
	}
	if loc, ok := raw["location"].(string); ok {
		req.Location = &loc
	}
	if dur, ok := raw["durationMinutes"].(float64); ok {
		d := int(dur)
		req.DurationMinutes = &d
	}
	if notes, ok := raw["notes"].(string); ok {
		req.Notes = &notes
	}
	if smID, ok := raw["savedMeetingId"].(string); ok {
		req.SavedMeetingID = &smID
	}

	return req, nil
}

func parseMeetingLogUpdateRequest(raw map[string]interface{}) (*meetings.UpdateMeetingLogRequest, error) {
	req := &meetings.UpdateMeetingLogRequest{}

	if mt, ok := raw["meetingType"].(string); ok {
		mtType := meetings.MeetingType(mt)
		req.MeetingType = &mtType
	}
	if label, ok := raw["customTypeLabel"].(string); ok {
		req.CustomTypeLabel = &label
	}
	if name, ok := raw["name"].(string); ok {
		req.Name = &name
	}
	if loc, ok := raw["location"].(string); ok {
		req.Location = &loc
	}
	if dur, ok := raw["durationMinutes"].(float64); ok {
		d := int(dur)
		req.DurationMinutes = &d
	}
	if notes, ok := raw["notes"].(string); ok {
		req.Notes = &notes
	}
	if status, ok := raw["status"].(string); ok {
		s := meetings.MeetingStatus(status)
		req.Status = &s
	}

	return req, nil
}

// --- Shared response helpers ---

type errorResponse struct {
	Errors []apiError `json:"errors"`
}

type apiError struct {
	ID            string `json:"id,omitempty"`
	Code          string `json:"code"`
	Status        int    `json:"status"`
	Title         string `json:"title"`
	Detail        string `json:"detail,omitempty"`
	CorrelationID string `json:"correlationId,omitempty"`
}

func writeJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Api-Version", "1.0.0")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

func writeError(w http.ResponseWriter, r *http.Request, status int, code, title, detail string) {
	correlationID := middleware.GetCorrelationID(r.Context())
	writeJSON(w, status, errorResponse{
		Errors: []apiError{{
			Code:          code,
			Status:        status,
			Title:         title,
			Detail:        detail,
			CorrelationID: correlationID,
		}},
	})
}

func writeDomainError(w http.ResponseWriter, r *http.Request, err error) {
	switch {
	case errors.Is(err, meetings.ErrMeetingNotFound), errors.Is(err, meetings.ErrSavedMeetingNotFound):
		writeError(w, r, http.StatusNotFound, "rr:0x40400001", "Not Found", err.Error())
	case errors.Is(err, meetings.ErrTimestampImmutable):
		writeError(w, r, http.StatusUnprocessableEntity, "rr:0x42200001", "Unprocessable Entity", "timestamp is immutable")
	case errors.Is(err, meetings.ErrInvalidMeetingType):
		writeError(w, r, http.StatusUnprocessableEntity, "rr:0x42200002", "Unprocessable Entity", err.Error())
	case errors.Is(err, meetings.ErrCustomTypeLabelRequired):
		writeError(w, r, http.StatusUnprocessableEntity, "rr:0x42200003", "Unprocessable Entity", err.Error())
	case errors.Is(err, meetings.ErrInvalidReminderMinutes):
		writeError(w, r, http.StatusUnprocessableEntity, "rr:0x42200004", "Unprocessable Entity", err.Error())
	case errors.Is(err, meetings.ErrInvalidInput):
		writeError(w, r, http.StatusUnprocessableEntity, "rr:0x42200005", "Unprocessable Entity", err.Error())
	case errors.Is(err, meetings.ErrFeatureDisabled):
		writeError(w, r, http.StatusNotFound, "rr:0x40400002", "Not Found", "resource not found")
	case errors.Is(err, meetings.ErrPermissionDenied):
		writeError(w, r, http.StatusNotFound, "rr:0x40400003", "Not Found", "resource not found")
	default:
		if strings.Contains(err.Error(), "required") || strings.Contains(err.Error(), "must") {
			writeError(w, r, http.StatusUnprocessableEntity, "rr:0x42200005", "Unprocessable Entity", err.Error())
		} else {
			writeError(w, r, http.StatusInternalServerError, "rr:0x50000001", "Internal Server Error", "an unexpected error occurred")
		}
	}
}
