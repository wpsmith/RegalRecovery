// internal/handler/meetings/summary_handler.go
package meetings

import (
	"net/http"
	"time"

	"github.com/regalrecovery/api/internal/domain/meetings"
	"github.com/regalrecovery/api/internal/middleware"
)

// SummaryHandler handles HTTP requests for the attendance summary endpoint.
type SummaryHandler struct {
	summarySvc *meetings.SummaryService
}

// NewSummaryHandler creates a new SummaryHandler.
func NewSummaryHandler(summarySvc *meetings.SummaryService) *SummaryHandler {
	return &SummaryHandler{summarySvc: summarySvc}
}

// HandleGetAttendanceSummary handles GET /v1/activities/meetings/summary.
func (h *SummaryHandler) HandleGetAttendanceSummary(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, r, http.StatusUnauthorized, "rr:0x40010001", "Unauthorized", "Authentication required")
		return
	}

	periodStr := r.URL.Query().Get("period")
	if periodStr == "" {
		writeError(w, r, http.StatusBadRequest, "rr:0x40000010", "Bad Request", "Query parameter 'period' is required")
		return
	}

	period := meetings.SummaryPeriod(periodStr)
	if !meetings.IsValidSummaryPeriod(period) {
		writeError(w, r, http.StatusBadRequest, "rr:0x40000011", "Bad Request", "period must be one of: week, month, quarter, year")
		return
	}

	// Parse reference date, default to today.
	refDate := time.Now().UTC()
	if dateStr := r.URL.Query().Get("date"); dateStr != "" {
		parsed, err := time.Parse("2006-01-02", dateStr)
		if err != nil {
			writeError(w, r, http.StatusBadRequest, "rr:0x40000012", "Bad Request", "Invalid date format; expected YYYY-MM-DD")
			return
		}
		refDate = parsed
	}

	summary, err := h.summarySvc.CalculateSummary(r.Context(), userID, period, refDate)
	if err != nil {
		writeDomainError(w, r, err)
		return
	}

	resp := meetings.AttendanceSummaryResponse{
		Data: *summary,
		Meta: map[string]interface{}{
			"retrievedAt": time.Now().UTC().Format(time.RFC3339),
		},
	}

	writeJSON(w, http.StatusOK, resp)
}
