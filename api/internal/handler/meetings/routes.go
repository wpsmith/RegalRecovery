// internal/handler/meetings/routes.go
package meetings

import (
	"net/http"

	domain "github.com/regalrecovery/api/internal/domain/meetings"
)

// Handler aggregates all meeting-related handlers.
type Handler struct {
	meetingHandler *MeetingHandler
	savedHandler   *SavedMeetingHandler
	summaryHandler *SummaryHandler
	flagChecker    FeatureFlagChecker
}

// FeatureFlagChecker checks if the meetings feature flag is enabled.
type FeatureFlagChecker interface {
	// IsEnabled returns true if the activity.meetings flag is enabled for the request context.
	IsEnabled(r *http.Request) bool
}

// NewHandler creates a new Handler with all sub-handlers wired.
func NewHandler(
	meetingSvc *domain.MeetingLogService,
	savedSvc *domain.SavedMeetingService,
	summarySvc *domain.SummaryService,
	flagChecker FeatureFlagChecker,
) *Handler {
	return &Handler{
		meetingHandler: NewMeetingHandler(meetingSvc),
		savedHandler:   NewSavedMeetingHandler(savedSvc),
		summaryHandler: NewSummaryHandler(summarySvc),
		flagChecker:    flagChecker,
	}
}

// RegisterRoutes registers all meeting routes on the given mux.
// All routes are gated by the activity.meetings feature flag.
func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	// Meeting log endpoints.
	mux.HandleFunc("POST /v1/activities/meetings", h.withFlag(h.meetingHandler.HandleCreateMeetingLog))
	mux.HandleFunc("GET /v1/activities/meetings", h.withFlag(h.meetingHandler.HandleListMeetingLogs))
	mux.HandleFunc("GET /v1/activities/meetings/{meetingId}", h.withFlag(h.meetingHandler.HandleGetMeetingLog))
	mux.HandleFunc("PATCH /v1/activities/meetings/{meetingId}", h.withFlag(h.meetingHandler.HandleUpdateMeetingLog))
	mux.HandleFunc("DELETE /v1/activities/meetings/{meetingId}", h.withFlag(h.meetingHandler.HandleDeleteMeetingLog))

	// Summary endpoint (must be registered before the {meetingId} catch-all).
	mux.HandleFunc("GET /v1/activities/meetings/summary", h.withFlag(h.summaryHandler.HandleGetAttendanceSummary))

	// Saved meeting endpoints.
	mux.HandleFunc("POST /v1/activities/meetings/saved", h.withFlag(h.savedHandler.HandleCreateSavedMeeting))
	mux.HandleFunc("GET /v1/activities/meetings/saved", h.withFlag(h.savedHandler.HandleListSavedMeetings))
	mux.HandleFunc("GET /v1/activities/meetings/saved/{savedMeetingId}", h.withFlag(h.savedHandler.HandleGetSavedMeeting))
	mux.HandleFunc("PATCH /v1/activities/meetings/saved/{savedMeetingId}", h.withFlag(h.savedHandler.HandleUpdateSavedMeeting))
	mux.HandleFunc("DELETE /v1/activities/meetings/saved/{savedMeetingId}", h.withFlag(h.savedHandler.HandleDeleteSavedMeeting))
}

// withFlag wraps a handler with feature flag checking.
// Returns 404 if the activity.meetings flag is disabled (NFR-MTG-5, fail closed).
func (h *Handler) withFlag(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if h.flagChecker != nil && !h.flagChecker.IsEnabled(r) {
			writeError(w, r, http.StatusNotFound, "rr:0x40400002", "Not Found", "resource not found")
			return
		}
		next(w, r)
	}
}
