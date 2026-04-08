// internal/domain/mood/handler.go
package mood

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/regalrecovery/api/internal/middleware"
)

// Handler holds route handlers for mood endpoints.
type Handler struct {
	repo      MoodRepository
	flagCheck func(ctx interface{}, flagKey string) bool
}

// NewHandler creates a new Handler with the given repository.
// flagCheck is a function that evaluates whether a feature flag is enabled.
func NewHandler(repo MoodRepository, flagCheck func(ctx interface{}, flagKey string) bool) *Handler {
	return &Handler{
		repo:      repo,
		flagCheck: flagCheck,
	}
}

// RegisterRoutes registers mood routes on the given mux.
func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("POST /activities/mood", h.handleCreateMoodEntry)
	mux.HandleFunc("GET /activities/mood", h.handleListMoodEntries)
	mux.HandleFunc("GET /activities/mood/today", h.handleGetMoodToday)
	mux.HandleFunc("GET /activities/mood/daily-summaries", h.handleGetDailySummaries)
	mux.HandleFunc("GET /activities/mood/trends", h.handleGetMoodTrends)
	mux.HandleFunc("GET /activities/mood/correlations", h.handleGetMoodCorrelations)
	mux.HandleFunc("GET /activities/mood/alerts/status", h.handleGetAlertStatus)
	mux.HandleFunc("GET /activities/mood/streak", h.handleGetMoodStreak)
	mux.HandleFunc("GET /activities/mood/{moodId}", h.handleGetMoodEntry)
	mux.HandleFunc("PATCH /activities/mood/{moodId}", h.handleUpdateMoodEntry)
	mux.HandleFunc("DELETE /activities/mood/{moodId}", h.handleDeleteMoodEntry)
}

// checkFeatureFlag returns 404 if the activity.mood flag is disabled.
func (h *Handler) checkFeatureFlag(w http.ResponseWriter, r *http.Request) bool {
	if h.flagCheck != nil && !h.flagCheck(r.Context(), "activity.mood") {
		writeErrorResponse(w, http.StatusNotFound, "rr:0x00040404", "Not Found", "This feature is not available.", r)
		return false
	}
	return true
}

// handleCreateMoodEntry handles POST /activities/mood.
func (h *Handler) handleCreateMoodEntry(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeErrorResponse(w, http.StatusUnauthorized, "rr:0x00040401", "Unauthorized", "Authentication required.", r)
		return
	}
	tenantID := middleware.GetTenantID(r.Context())

	var req CreateMoodEntryRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeErrorResponse(w, http.StatusBadRequest, "rr:0x00040400", "Bad Request", "Invalid request body: "+err.Error(), r)
		return
	}

	entry, err := NewMoodEntry(userID, tenantID, req)
	if err != nil {
		writeValidationError(w, err, r)
		return
	}

	if err := h.repo.Create(r.Context(), entry); err != nil {
		writeErrorResponse(w, http.StatusInternalServerError, "rr:0x00040500", "Internal Server Error", "Failed to save mood entry.", r)
		return
	}

	correlationID := uuid.New().String()
	w.Header().Set("Location", fmt.Sprintf("/v1/activities/mood/%s", entry.MoodID))
	w.Header().Set("X-Correlation-Id", correlationID)
	w.Header().Set("Api-Version", "1.0.0")

	writeJSON(w, http.StatusCreated, moodEntryResponseEnvelope(entry))
}

// handleListMoodEntries handles GET /activities/mood.
func (h *Handler) handleListMoodEntries(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeErrorResponse(w, http.StatusUnauthorized, "rr:0x00040401", "Unauthorized", "Authentication required.", r)
		return
	}

	q := r.URL.Query()
	cursor := q.Get("cursor")
	limit := parseIntDefault(q.Get("limit"), 50, 1, 100)

	filters := MoodFilters{}
	if ratingStr := q.Get("rating"); ratingStr != "" {
		for _, rs := range strings.Split(ratingStr, ",") {
			if v, err := strconv.Atoi(strings.TrimSpace(rs)); err == nil {
				filters.Ratings = append(filters.Ratings, v)
			}
		}
	}
	if el := q.Get("emotionLabel"); el != "" {
		filters.EmotionLabel = el
	}
	if search := q.Get("search"); search != "" {
		filters.Search = search
	}
	if sd := q.Get("startDate"); sd != "" {
		if t, err := time.Parse("2006-01-02", sd); err == nil {
			filters.StartDate = &t
		}
	}
	if ed := q.Get("endDate"); ed != "" {
		if t, err := time.Parse("2006-01-02", ed); err == nil {
			endOfDay := t.Add(24*time.Hour - time.Nanosecond)
			filters.EndDate = &endOfDay
		}
	}

	entries, nextCursor, err := h.repo.ListByFilters(r.Context(), userID, filters, cursor, limit)
	if err != nil {
		writeErrorResponse(w, http.StatusInternalServerError, "rr:0x00040500", "Internal Server Error", "Failed to list mood entries.", r)
		return
	}

	w.Header().Set("Api-Version", "1.0.0")
	writeJSON(w, http.StatusOK, moodListResponseEnvelope(entries, nextCursor, limit))
}

// handleGetMoodEntry handles GET /activities/mood/{moodId}.
func (h *Handler) handleGetMoodEntry(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeErrorResponse(w, http.StatusUnauthorized, "rr:0x00040401", "Unauthorized", "Authentication required.", r)
		return
	}

	moodID := r.PathValue("moodId")
	entry, err := h.repo.GetByID(r.Context(), moodID)
	if err != nil {
		if err == ErrEntryNotFound {
			writeErrorResponse(w, http.StatusNotFound, "rr:0x00040404", "Not Found", "Mood entry not found.", r)
			return
		}
		writeErrorResponse(w, http.StatusInternalServerError, "rr:0x00040500", "Internal Server Error", "Failed to retrieve mood entry.", r)
		return
	}

	// Tenant isolation: verify entry belongs to this user.
	if entry.UserID != userID {
		writeErrorResponse(w, http.StatusNotFound, "rr:0x00040404", "Not Found", "Mood entry not found.", r)
		return
	}

	w.Header().Set("Api-Version", "1.0.0")
	writeJSON(w, http.StatusOK, moodEntryResponseEnvelope(entry))
}

// handleUpdateMoodEntry handles PATCH /activities/mood/{moodId}.
func (h *Handler) handleUpdateMoodEntry(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeErrorResponse(w, http.StatusUnauthorized, "rr:0x00040401", "Unauthorized", "Authentication required.", r)
		return
	}

	moodID := r.PathValue("moodId")

	var req UpdateMoodEntryRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeErrorResponse(w, http.StatusBadRequest, "rr:0x00040400", "Bad Request", "Invalid request body.", r)
		return
	}

	entry, err := h.repo.Update(r.Context(), moodID, req)
	if err != nil {
		if err == ErrEntryNotFound {
			writeErrorResponse(w, http.StatusNotFound, "rr:0x00040404", "Not Found", "Mood entry not found.", r)
			return
		}
		if err == ErrEntryLocked {
			writeErrorResponse(w, http.StatusUnprocessableEntity, "rr:0x00040001", "Entry Locked", "This mood entry is older than 24 hours and can no longer be edited.", r)
			return
		}
		writeValidationError(w, err, r)
		return
	}

	w.Header().Set("Api-Version", "1.0.0")
	writeJSON(w, http.StatusOK, moodEntryResponseEnvelope(entry))
}

// handleDeleteMoodEntry handles DELETE /activities/mood/{moodId}.
func (h *Handler) handleDeleteMoodEntry(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeErrorResponse(w, http.StatusUnauthorized, "rr:0x00040401", "Unauthorized", "Authentication required.", r)
		return
	}

	moodID := r.PathValue("moodId")

	// Verify entry exists and belongs to user first.
	entry, err := h.repo.GetByID(r.Context(), moodID)
	if err != nil {
		if err == ErrEntryNotFound {
			writeErrorResponse(w, http.StatusNotFound, "rr:0x00040404", "Not Found", "Mood entry not found.", r)
			return
		}
		writeErrorResponse(w, http.StatusInternalServerError, "rr:0x00040500", "Internal Server Error", "Failed to retrieve mood entry.", r)
		return
	}
	if entry.UserID != userID {
		writeErrorResponse(w, http.StatusNotFound, "rr:0x00040404", "Not Found", "Mood entry not found.", r)
		return
	}

	err = h.repo.Delete(r.Context(), moodID)
	if err != nil {
		if err == ErrEntryPermanent {
			writeErrorResponse(w, http.StatusUnprocessableEntity, "rr:0x00040002", "Entry Permanent", "This mood entry is older than 24 hours and cannot be deleted.", r)
			return
		}
		writeErrorResponse(w, http.StatusInternalServerError, "rr:0x00040500", "Internal Server Error", "Failed to delete mood entry.", r)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// handleGetMoodToday handles GET /activities/mood/today.
func (h *Handler) handleGetMoodToday(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeErrorResponse(w, http.StatusUnauthorized, "rr:0x00040401", "Unauthorized", "Authentication required.", r)
		return
	}

	today := time.Now().UTC().Format("2006-01-02")
	entries, err := h.repo.GetTodayEntries(r.Context(), userID, today)
	if err != nil {
		writeErrorResponse(w, http.StatusInternalServerError, "rr:0x00040500", "Internal Server Error", "Failed to retrieve today's entries.", r)
		return
	}

	summary := ComputeTodaySummary(entries)

	response := map[string]interface{}{
		"data": map[string]interface{}{
			"entries": entries,
			"summary": summary,
		},
		"meta": map[string]interface{}{
			"date":     today,
			"timezone": "UTC",
		},
	}

	w.Header().Set("Api-Version", "1.0.0")
	writeJSON(w, http.StatusOK, response)
}

// handleGetDailySummaries handles GET /activities/mood/daily-summaries.
func (h *Handler) handleGetDailySummaries(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeErrorResponse(w, http.StatusUnauthorized, "rr:0x00040401", "Unauthorized", "Authentication required.", r)
		return
	}

	q := r.URL.Query()
	startDate := q.Get("startDate")
	endDate := q.Get("endDate")

	if startDate == "" || endDate == "" {
		writeErrorResponse(w, http.StatusBadRequest, "rr:0x00040400", "Bad Request", "startDate and endDate are required.", r)
		return
	}

	summaries, err := h.repo.GetDailySummaries(r.Context(), userID, startDate, endDate)
	if err != nil {
		writeErrorResponse(w, http.StatusInternalServerError, "rr:0x00040500", "Internal Server Error", "Failed to retrieve daily summaries.", r)
		return
	}

	daysWithEntries := 0
	for _, s := range summaries {
		if s.EntryCount > 0 {
			daysWithEntries++
		}
	}

	response := map[string]interface{}{
		"data": summaries,
		"meta": map[string]interface{}{
			"startDate":        startDate,
			"endDate":          endDate,
			"daysWithEntries":  daysWithEntries,
			"daysWithoutEntries": len(summaries) - daysWithEntries,
		},
	}

	w.Header().Set("Api-Version", "1.0.0")
	writeJSON(w, http.StatusOK, response)
}

// handleGetMoodTrends handles GET /activities/mood/trends.
func (h *Handler) handleGetMoodTrends(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeErrorResponse(w, http.StatusUnauthorized, "rr:0x00040401", "Unauthorized", "Authentication required.", r)
		return
	}

	period := r.URL.Query().Get("period")
	if period != "7d" && period != "30d" && period != "90d" {
		writeErrorResponse(w, http.StatusBadRequest, "rr:0x00040400", "Bad Request", "period must be 7d, 30d, or 90d.", r)
		return
	}

	now := time.Now().UTC()
	var start time.Time
	switch period {
	case "7d":
		start = now.AddDate(0, 0, -7)
	case "30d":
		start = now.AddDate(0, 0, -30)
	case "90d":
		start = now.AddDate(0, 0, -90)
	}

	startStr := start.Format("2006-01-02")
	endStr := now.Format("2006-01-02")

	summaries, err := h.repo.GetDailySummaries(r.Context(), userID, startStr, endStr)
	if err != nil {
		writeErrorResponse(w, http.StatusInternalServerError, "rr:0x00040500", "Internal Server Error", "Failed to compute trends.", r)
		return
	}

	// Build daily averages and compute trend.
	dailyAverages := make([]DailyAverage, len(summaries))
	avgValues := make([]float64, len(summaries))
	for i, s := range summaries {
		dailyAverages[i] = DailyAverage{
			Date:          s.Date,
			AverageRating: s.AverageRating,
			EntryCount:    s.EntryCount,
		}
		avgValues[i] = s.AverageRating
	}

	// Reverse for chronological order (summaries are desc).
	for i, j := 0, len(avgValues)-1; i < j; i, j = i+1, j-1 {
		avgValues[i], avgValues[j] = avgValues[j], avgValues[i]
	}
	trendDirection := CalculateTrendDirection(avgValues)

	// Get heatmap data.
	heatmap, _ := h.repo.GetHourlyHeatmap(r.Context(), userID, start, now)
	dayOfWeek, _ := h.repo.GetDayOfWeekAverages(r.Context(), userID, start, now)
	emotionLabels, _ := h.repo.GetEmotionLabelFrequency(r.Context(), userID, start, now)

	totalEntries := 0
	for _, s := range summaries {
		totalEntries += s.EntryCount
	}

	response := map[string]interface{}{
		"data": map[string]interface{}{
			"dailyAverages":      dailyAverages,
			"trendDirection":     trendDirection,
			"timeOfDayHeatmap":   heatmap,
			"dayOfWeekPatterns":  dayOfWeek,
			"emotionLabelTrends": emotionLabels,
		},
		"meta": map[string]interface{}{
			"period":       period,
			"startDate":    startStr,
			"endDate":      endStr,
			"totalEntries": totalEntries,
		},
	}

	w.Header().Set("Api-Version", "1.0.0")
	writeJSON(w, http.StatusOK, response)
}

// handleGetMoodCorrelations handles GET /activities/mood/correlations.
func (h *Handler) handleGetMoodCorrelations(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeErrorResponse(w, http.StatusUnauthorized, "rr:0x00040401", "Unauthorized", "Authentication required.", r)
		return
	}

	period := r.URL.Query().Get("period")
	if period != "30d" && period != "90d" {
		writeErrorResponse(w, http.StatusBadRequest, "rr:0x00040400", "Bad Request", "period must be 30d or 90d.", r)
		return
	}

	// Correlations require cross-domain data. Return placeholder structure.
	// Full implementation requires integration with other activity repositories.
	response := map[string]interface{}{
		"data": map[string]interface{}{
			"activities":      []interface{}{},
			"urgeCorrelation": nil,
		},
		"meta": map[string]interface{}{
			"period":         period,
			"sufficientData": false,
		},
	}

	_ = userID // Used once cross-domain correlation is implemented.

	w.Header().Set("Api-Version", "1.0.0")
	writeJSON(w, http.StatusOK, response)
}

// handleGetAlertStatus handles GET /activities/mood/alerts/status.
func (h *Handler) handleGetAlertStatus(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeErrorResponse(w, http.StatusUnauthorized, "rr:0x00040401", "Unauthorized", "Authentication required.", r)
		return
	}

	consecutiveLow, err := h.repo.CountConsecutiveLowDays(r.Context(), userID)
	if err != nil {
		writeErrorResponse(w, http.StatusInternalServerError, "rr:0x00040500", "Internal Server Error", "Failed to evaluate alert status.", r)
		return
	}

	lastCrisis, _ := h.repo.GetLastCrisisEntry(r.Context(), userID)

	var lastCrisisData interface{}
	if lastCrisis != nil {
		lastCrisisData = map[string]interface{}{
			"moodId":    lastCrisis.MoodID,
			"timestamp": lastCrisis.Timestamp,
		}
	}

	sustainedLow := consecutiveLow >= SustainedLowMoodDays

	response := map[string]interface{}{
		"data": map[string]interface{}{
			"sustainedLowMood":      sustainedLow,
			"consecutiveLowDays":    consecutiveLow,
			"lastCrisisEntry":       lastCrisisData,
			"alertSharedWithNetwork": false, // Requires user settings integration.
		},
		"meta": map[string]interface{}{
			"evaluatedAt": time.Now().UTC(),
		},
	}

	w.Header().Set("Api-Version", "1.0.0")
	writeJSON(w, http.StatusOK, response)
}

// handleGetMoodStreak handles GET /activities/mood/streak.
func (h *Handler) handleGetMoodStreak(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeErrorResponse(w, http.StatusUnauthorized, "rr:0x00040401", "Unauthorized", "Authentication required.", r)
		return
	}

	dates, err := h.repo.GetDistinctEntryDates(r.Context(), userID)
	if err != nil {
		writeErrorResponse(w, http.StatusInternalServerError, "rr:0x00040500", "Internal Server Error", "Failed to calculate streak.", r)
		return
	}

	today := time.Now().UTC().Format("2006-01-02")
	streak := CalculateStreak(dates, today)

	response := map[string]interface{}{
		"data": map[string]interface{}{
			"currentStreakDays": streak.CurrentStreakDays,
			"longestStreakDays": streak.LongestStreakDays,
			"lastEntryDate":    streak.LastEntryDate,
		},
		"meta": map[string]interface{}{
			"evaluatedAt": time.Now().UTC(),
		},
	}

	w.Header().Set("Api-Version", "1.0.0")
	writeJSON(w, http.StatusOK, response)
}

// --- Response helpers ---

func moodEntryResponseEnvelope(entry *MoodEntry) map[string]interface{} {
	return map[string]interface{}{
		"data": map[string]interface{}{
			"moodId":         entry.MoodID,
			"timestamp":      entry.Timestamp,
			"rating":         entry.Rating,
			"ratingLabel":    entry.RatingLabel,
			"emotionLabels":  entry.EmotionLabels,
			"contextNote":    entry.ContextNote,
			"source":         entry.Source,
			"crisisPrompted": entry.CrisisPrompted,
			"links": map[string]string{
				"self": fmt.Sprintf("/v1/activities/mood/%s", entry.MoodID),
			},
		},
		"meta": map[string]interface{}{
			"createdAt":  entry.CreatedAt,
			"modifiedAt": entry.ModifiedAt,
		},
	}
}

func moodListResponseEnvelope(entries []MoodEntry, nextCursor string, limit int) map[string]interface{} {
	data := make([]map[string]interface{}, len(entries))
	for i, e := range entries {
		data[i] = map[string]interface{}{
			"moodId":         e.MoodID,
			"timestamp":      e.Timestamp,
			"rating":         e.Rating,
			"ratingLabel":    e.RatingLabel,
			"emotionLabels":  e.EmotionLabels,
			"contextNote":    e.ContextNote,
			"source":         e.Source,
			"crisisPrompted": e.CrisisPrompted,
			"links": map[string]string{
				"self": fmt.Sprintf("/v1/activities/mood/%s", e.MoodID),
			},
		}
	}

	links := map[string]interface{}{
		"self": "/v1/activities/mood",
	}
	if nextCursor != "" {
		links["next"] = fmt.Sprintf("/v1/activities/mood?cursor=%s&limit=%d", nextCursor, limit)
	}

	return map[string]interface{}{
		"data":  data,
		"links": links,
		"meta": map[string]interface{}{
			"page": map[string]interface{}{
				"nextCursor": nextCursor,
				"limit":      limit,
			},
			"totalEntries": len(entries),
		},
	}
}

func writeJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

func writeErrorResponse(w http.ResponseWriter, status int, code, title, detail string, r *http.Request) {
	correlationID := r.Header.Get("X-Correlation-Id")
	if correlationID == "" {
		correlationID = uuid.New().String()
	}

	resp := map[string]interface{}{
		"errors": []map[string]interface{}{
			{
				"id":            uuid.New().String(),
				"code":          code,
				"status":        status,
				"title":         title,
				"detail":        detail,
				"correlationId": correlationID,
			},
		},
	}

	writeJSON(w, status, resp)
}

func writeValidationError(w http.ResponseWriter, err error, r *http.Request) {
	status := http.StatusUnprocessableEntity
	if strings.Contains(err.Error(), "invalid input") {
		status = http.StatusBadRequest
	}
	writeErrorResponse(w, status, "rr:0x00040422", "Validation Error", err.Error(), r)
}

func parseIntDefault(s string, defaultVal, min, max int) int {
	if s == "" {
		return defaultVal
	}
	v, err := strconv.Atoi(s)
	if err != nil {
		return defaultVal
	}
	if v < min {
		return min
	}
	if v > max {
		return max
	}
	return v
}
