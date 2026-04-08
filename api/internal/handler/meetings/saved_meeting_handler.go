// internal/handler/meetings/saved_meeting_handler.go
package meetings

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/regalrecovery/api/internal/domain/meetings"
	"github.com/regalrecovery/api/internal/middleware"
)

// SavedMeetingHandler handles HTTP requests for saved meeting template endpoints.
type SavedMeetingHandler struct {
	savedSvc *meetings.SavedMeetingService
}

// NewSavedMeetingHandler creates a new SavedMeetingHandler.
func NewSavedMeetingHandler(savedSvc *meetings.SavedMeetingService) *SavedMeetingHandler {
	return &SavedMeetingHandler{savedSvc: savedSvc}
}

// HandleCreateSavedMeeting handles POST /v1/activities/meetings/saved.
func (h *SavedMeetingHandler) HandleCreateSavedMeeting(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, r, http.StatusUnauthorized, "rr:0x40010001", "Unauthorized", "Authentication required")
		return
	}
	tenantID := middleware.GetTenantID(r.Context())

	var req meetings.CreateSavedMeetingRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, r, http.StatusBadRequest, "rr:0x40000001", "Bad Request", "Invalid JSON body: "+err.Error())
		return
	}

	saved, err := h.savedSvc.CreateSavedMeeting(r.Context(), userID, tenantID, &req)
	if err != nil {
		writeDomainError(w, r, err)
		return
	}

	w.Header().Set("Location", fmt.Sprintf("/v1/activities/meetings/saved/%s", saved.SavedMeetingID))

	resp := meetings.SavedMeetingResponse{
		Data: toSavedMeetingData(saved),
		Meta: map[string]interface{}{
			"createdAt": saved.CreatedAt.Format(time.RFC3339),
		},
	}

	writeJSON(w, http.StatusCreated, resp)
}

// HandleListSavedMeetings handles GET /v1/activities/meetings/saved.
func (h *SavedMeetingHandler) HandleListSavedMeetings(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, r, http.StatusUnauthorized, "rr:0x40010001", "Unauthorized", "Authentication required")
		return
	}

	savedList, err := h.savedSvc.ListSavedMeetings(r.Context(), userID)
	if err != nil {
		writeDomainError(w, r, err)
		return
	}

	data := make([]meetings.SavedMeetingData, 0, len(savedList))
	for _, s := range savedList {
		data = append(data, toSavedMeetingData(s))
	}

	resp := meetings.SavedMeetingListResponse{
		Data: data,
		Meta: map[string]interface{}{
			"totalCount": len(data),
		},
	}

	writeJSON(w, http.StatusOK, resp)
}

// HandleGetSavedMeeting handles GET /v1/activities/meetings/saved/{savedMeetingId}.
func (h *SavedMeetingHandler) HandleGetSavedMeeting(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, r, http.StatusUnauthorized, "rr:0x40010001", "Unauthorized", "Authentication required")
		return
	}

	savedMeetingID := r.PathValue("savedMeetingId")
	if savedMeetingID == "" {
		writeError(w, r, http.StatusBadRequest, "rr:0x40000003", "Bad Request", "savedMeetingId is required")
		return
	}

	saved, err := h.savedSvc.GetSavedMeeting(r.Context(), userID, savedMeetingID)
	if err != nil {
		writeDomainError(w, r, err)
		return
	}

	resp := meetings.SavedMeetingResponse{
		Data: toSavedMeetingData(saved),
		Meta: map[string]interface{}{
			"createdAt":  saved.CreatedAt.Format(time.RFC3339),
			"modifiedAt": saved.ModifiedAt.Format(time.RFC3339),
		},
	}

	writeJSON(w, http.StatusOK, resp)
}

// HandleUpdateSavedMeeting handles PATCH /v1/activities/meetings/saved/{savedMeetingId}.
func (h *SavedMeetingHandler) HandleUpdateSavedMeeting(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, r, http.StatusUnauthorized, "rr:0x40010001", "Unauthorized", "Authentication required")
		return
	}

	savedMeetingID := r.PathValue("savedMeetingId")
	if savedMeetingID == "" {
		writeError(w, r, http.StatusBadRequest, "rr:0x40000003", "Bad Request", "savedMeetingId is required")
		return
	}

	var req meetings.UpdateSavedMeetingRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, r, http.StatusBadRequest, "rr:0x40000001", "Bad Request", "Invalid JSON body: "+err.Error())
		return
	}

	saved, err := h.savedSvc.UpdateSavedMeeting(r.Context(), userID, savedMeetingID, &req)
	if err != nil {
		writeDomainError(w, r, err)
		return
	}

	resp := meetings.SavedMeetingResponse{
		Data: toSavedMeetingData(saved),
		Meta: map[string]interface{}{
			"createdAt":  saved.CreatedAt.Format(time.RFC3339),
			"modifiedAt": saved.ModifiedAt.Format(time.RFC3339),
		},
	}

	writeJSON(w, http.StatusOK, resp)
}

// HandleDeleteSavedMeeting handles DELETE /v1/activities/meetings/saved/{savedMeetingId}.
func (h *SavedMeetingHandler) HandleDeleteSavedMeeting(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, r, http.StatusUnauthorized, "rr:0x40010001", "Unauthorized", "Authentication required")
		return
	}

	savedMeetingID := r.PathValue("savedMeetingId")
	if savedMeetingID == "" {
		writeError(w, r, http.StatusBadRequest, "rr:0x40000003", "Bad Request", "savedMeetingId is required")
		return
	}

	err := h.savedSvc.DeleteSavedMeeting(r.Context(), userID, savedMeetingID)
	if err != nil {
		writeDomainError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// --- Helpers ---

func toSavedMeetingData(s *meetings.SavedMeeting) meetings.SavedMeetingData {
	return meetings.SavedMeetingData{
		SavedMeetingID:        s.SavedMeetingID,
		Name:                  s.Name,
		MeetingType:           s.MeetingType,
		CustomTypeLabel:       s.CustomTypeLabel,
		Location:              s.Location,
		Schedule:              s.Schedule,
		ReminderMinutesBefore: s.ReminderMinutesBefore,
		IsActive:              s.IsActive,
		Links: meetings.SavedMeetingLinks{
			Self: fmt.Sprintf("/v1/activities/meetings/saved/%s", s.SavedMeetingID),
		},
	}
}
