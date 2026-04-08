// internal/domain/devotionals/handler.go
package devotionals

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"

	"github.com/google/uuid"
	"github.com/regalrecovery/api/internal/middleware"
)

const apiVersion = "1.0.0"

// Handler holds route handlers for the devotional endpoints.
type Handler struct {
	selector    *DevotionalSelector
	completion  *CompletionService
	favorites   *FavoritesService
	series      *SeriesProgressionService
	share       *ShareService
	streak      *StreakCalculator
	access      *AccessChecker
	flagEnabled func() bool
}

// NewHandler creates a new devotional Handler.
func NewHandler(
	selector *DevotionalSelector,
	completion *CompletionService,
	favorites *FavoritesService,
	series *SeriesProgressionService,
	share *ShareService,
	streak *StreakCalculator,
	access *AccessChecker,
	flagEnabled func() bool,
) *Handler {
	return &Handler{
		selector:    selector,
		completion:  completion,
		favorites:   favorites,
		series:      series,
		share:       share,
		streak:      streak,
		access:      access,
		flagEnabled: flagEnabled,
	}
}

// RegisterRoutes registers devotional routes on the given mux.
func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("GET /v1/devotionals/today", h.featureGate(h.HandleGetToday))
	mux.HandleFunc("GET /v1/devotionals/streak", h.featureGate(h.HandleGetStreak))
	mux.HandleFunc("GET /v1/devotionals/favorites", h.featureGate(h.HandleListFavorites))
	mux.HandleFunc("GET /v1/devotionals/history", h.featureGate(h.HandleListHistory))
	mux.HandleFunc("POST /v1/devotionals/history/export", h.featureGate(h.HandleExportHistory))
	mux.HandleFunc("GET /v1/devotionals/series", h.featureGate(h.HandleListSeries))
	mux.HandleFunc("GET /v1/devotionals/series/{seriesId}", h.featureGate(h.HandleGetSeries))
	mux.HandleFunc("POST /v1/devotionals/series/{seriesId}/activate", h.featureGate(h.HandleActivateSeries))
	mux.HandleFunc("GET /v1/devotionals/completions/{completionId}", h.featureGate(h.HandleGetCompletion))
	mux.HandleFunc("PATCH /v1/devotionals/completions/{completionId}", h.featureGate(h.HandleUpdateCompletion))
	mux.HandleFunc("GET /v1/devotionals/{id}", h.featureGate(h.HandleGetDevotional))
	mux.HandleFunc("POST /v1/devotionals/{id}/completions", h.featureGate(h.HandleCreateCompletion))
	mux.HandleFunc("POST /v1/devotionals/{id}/share", h.featureGate(h.HandleShareDevotional))
	mux.HandleFunc("POST /v1/devotionals/favorites/{id}", h.featureGate(h.HandleAddFavorite))
	mux.HandleFunc("DELETE /v1/devotionals/favorites/{id}", h.featureGate(h.HandleRemoveFavorite))
	mux.HandleFunc("GET /v1/devotionals", h.featureGate(h.HandleListDevotionals))
}

// featureGate wraps a handler with feature flag check (AC-DEV-EDGE-05).
func (h *Handler) featureGate(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if !h.flagEnabled() {
			writeError(w, http.StatusNotFound, "rr:0x00D00000", "Not Found")
			return
		}
		next(w, r)
	}
}

// HandleGetToday handles GET /v1/devotionals/today.
func (h *Handler) HandleGetToday(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeUnauthorized(w)
		return
	}

	// TODO: Get user timezone and premium status from user profile
	userTimezone := "America/New_York"
	isPremium := false

	content, err := h.selector.GetTodayDevotional(r.Context(), userID, userTimezone, isPremium)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	if content == nil {
		writeError(w, http.StatusNotFound, "rr:0x00D00002", "No devotional available for today")
		return
	}

	devotional := contentToDevotional(content, LangEN, TranslationNIV, false, false)
	setStandardHeaders(w)
	writeJSON(w, http.StatusOK, DevotionalResponse{
		Data: *devotional,
		Links: map[string]string{
			"self": "/v1/devotionals/today",
		},
	})
}

// HandleListDevotionals handles GET /v1/devotionals.
func (h *Handler) HandleListDevotionals(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeUnauthorized(w)
		return
	}

	params := parseListDevotionalsParams(r)
	contents, nextCursor, err := h.completion.contentRepo.List(r.Context(), params)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	summaries := make([]DevotionalSummary, 0, len(contents))
	for _, c := range contents {
		summaries = append(summaries, contentToSummary(&c, false, false, false))
	}

	meta := map[string]interface{}{
		"page": CursorPage{Limit: params.Limit},
	}
	if nextCursor != "" {
		nc := nextCursor
		meta["page"] = CursorPage{NextCursor: &nc, Limit: params.Limit}
	}

	setStandardHeaders(w)
	writeJSON(w, http.StatusOK, DevotionalListResponse{
		Data: summaries,
		Meta: meta,
	})
}

// HandleGetDevotional handles GET /v1/devotionals/{id}.
func (h *Handler) HandleGetDevotional(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeUnauthorized(w)
		return
	}

	id := r.PathValue("id")
	content, err := h.completion.contentRepo.GetByID(r.Context(), id)
	if err != nil || content == nil {
		writeError(w, http.StatusNotFound, "rr:0x00D00003", "Devotional not found")
		return
	}

	// Access check for premium content
	if err := h.access.CheckAccess(content, map[string]bool{}); err != nil {
		if errors.Is(err, ErrPremiumContentLocked) {
			writeJSON(w, http.StatusForbidden, errorResponse{
				Errors: []apiError{{
					ID:     uuid.New().String(),
					Code:   "rr:0x00D00001",
					Status: 403,
					Title:  "Premium Content Locked",
					Detail: "This devotional is part of a premium series. Purchase the series to unlock.",
				}},
			})
			return
		}
		writeServiceError(w, err)
		return
	}

	devotional := contentToDevotional(content, LangEN, TranslationNIV, false, false)
	setStandardHeaders(w)
	writeJSON(w, http.StatusOK, DevotionalResponse{Data: *devotional})
}

// HandleCreateCompletion handles POST /v1/devotionals/{id}/completions.
func (h *Handler) HandleCreateCompletion(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeUnauthorized(w)
		return
	}

	devotionalID := r.PathValue("id")

	var req CompletionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x00D00010", "Invalid request body: "+err.Error())
		return
	}

	userTimezone := "America/New_York" // TODO: from user profile

	completion, err := h.completion.CreateCompletion(r.Context(), userID, devotionalID, &req, userTimezone)
	if err != nil {
		switch {
		case errors.Is(err, ErrDuplicateCompletion):
			writeError(w, http.StatusConflict, "rr:0x00D00011", "Devotional already completed today")
		case errors.Is(err, ErrDevotionalNotFound):
			writeError(w, http.StatusNotFound, "rr:0x00D00003", "Devotional not found")
		case errors.Is(err, ErrInvalidInput):
			writeError(w, http.StatusUnprocessableEntity, "rr:0x00D00012", err.Error())
		default:
			writeServiceError(w, err)
		}
		return
	}

	w.Header().Set("Location", fmt.Sprintf("/v1/devotionals/%s/completions/%s", devotionalID, completion.CompletionID))
	setStandardHeaders(w)
	writeJSON(w, http.StatusCreated, CompletionResponse{
		Data: *completion,
		Meta: map[string]interface{}{
			"createdAt": completion.Timestamp.Format("2006-01-02T15:04:05Z"),
		},
	})
}

// HandleGetCompletion handles GET /v1/devotionals/completions/{completionId}.
func (h *Handler) HandleGetCompletion(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeUnauthorized(w)
		return
	}

	completionID := r.PathValue("completionId")
	completion, err := h.completion.GetCompletion(r.Context(), userID, completionID)
	if err != nil {
		if errors.Is(err, ErrCompletionNotFound) {
			writeError(w, http.StatusNotFound, "rr:0x00D00020", "Completion not found")
			return
		}
		writeServiceError(w, err)
		return
	}

	setStandardHeaders(w)
	writeJSON(w, http.StatusOK, CompletionResponse{Data: *completion})
}

// HandleUpdateCompletion handles PATCH /v1/devotionals/completions/{completionId}.
func (h *Handler) HandleUpdateCompletion(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeUnauthorized(w)
		return
	}

	completionID := r.PathValue("completionId")

	var req CompletionUpdateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x00D00010", "Invalid request body: "+err.Error())
		return
	}

	completion, err := h.completion.UpdateCompletion(r.Context(), userID, completionID, &req)
	if err != nil {
		switch {
		case errors.Is(err, ErrCompletionNotFound):
			writeError(w, http.StatusNotFound, "rr:0x00D00020", "Completion not found")
		case errors.Is(err, ErrTimestampImmutable):
			writeError(w, http.StatusUnprocessableEntity, "rr:0x00D00021", "Timestamp is immutable (FR2.7)")
		case errors.Is(err, ErrInvalidInput):
			writeError(w, http.StatusUnprocessableEntity, "rr:0x00D00012", err.Error())
		default:
			writeServiceError(w, err)
		}
		return
	}

	setStandardHeaders(w)
	writeJSON(w, http.StatusOK, CompletionResponse{Data: *completion})
}

// HandleListHistory handles GET /v1/devotionals/history.
func (h *Handler) HandleListHistory(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeUnauthorized(w)
		return
	}

	params := parseListHistoryParams(r)
	completions, nextCursor, err := h.completion.completionRepo.ListByDateRange(r.Context(), userID, params)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	data := make([]DevotionalCompletion, 0, len(completions))
	for _, doc := range completions {
		data = append(data, *docToCompletion(&doc))
	}

	meta := map[string]interface{}{
		"page":           CursorPage{Limit: params.Limit},
		"totalCompleted": len(data),
	}
	if nextCursor != "" {
		nc := nextCursor
		meta["page"] = CursorPage{NextCursor: &nc, Limit: params.Limit}
	}

	setStandardHeaders(w)
	writeJSON(w, http.StatusOK, HistoryResponse{
		Data: data,
		Meta: meta,
	})
}

// HandleExportHistory handles POST /v1/devotionals/history/export.
func (h *Handler) HandleExportHistory(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeUnauthorized(w)
		return
	}

	// Async export: enqueue the export job and return 202
	exportID := fmt.Sprintf("exp_%s", uuid.New().String()[:8])

	resp := ExportResponse{}
	resp.Data.ExportID = exportID
	resp.Data.Status = "pending"
	resp.Data.Links = map[string]string{
		"status": fmt.Sprintf("/v1/devotionals/history/exports/%s", exportID),
	}

	w.Header().Set("Location", fmt.Sprintf("/v1/devotionals/history/exports/%s", exportID))
	setStandardHeaders(w)
	writeJSON(w, http.StatusAccepted, resp)
}

// HandleListFavorites handles GET /v1/devotionals/favorites.
func (h *Handler) HandleListFavorites(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeUnauthorized(w)
		return
	}

	cursor := r.URL.Query().Get("cursor")
	limit := parseLimit(r, 20)

	favorites, nextCursor, err := h.favorites.ListFavorites(r.Context(), userID, cursor, limit)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	summaries := make([]DevotionalSummary, 0, len(favorites))
	for _, f := range favorites {
		summaries = append(summaries, DevotionalSummary{
			ID:                 f.DevotionalID,
			Title:              f.DevotionalTitle,
			ScriptureReference: f.ScriptureReference,
			Topic:              f.Topic,
			IsFavorite:         true,
		})
	}

	meta := map[string]interface{}{
		"page": CursorPage{Limit: limit},
	}
	if nextCursor != "" {
		nc := nextCursor
		meta["page"] = CursorPage{NextCursor: &nc, Limit: limit}
	}

	setStandardHeaders(w)
	writeJSON(w, http.StatusOK, FavoritesResponse{
		Data: summaries,
		Meta: meta,
	})
}

// HandleAddFavorite handles POST /v1/devotionals/favorites/{id}.
func (h *Handler) HandleAddFavorite(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeUnauthorized(w)
		return
	}

	devotionalID := r.PathValue("id")
	err := h.favorites.AddFavorite(r.Context(), userID, devotionalID)
	if err != nil {
		if errors.Is(err, ErrDevotionalNotFound) {
			writeError(w, http.StatusNotFound, "rr:0x00D00003", "Devotional not found")
			return
		}
		writeServiceError(w, err)
		return
	}

	setStandardHeaders(w)
	w.WriteHeader(http.StatusNoContent)
}

// HandleRemoveFavorite handles DELETE /v1/devotionals/favorites/{id}.
func (h *Handler) HandleRemoveFavorite(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeUnauthorized(w)
		return
	}

	devotionalID := r.PathValue("id")
	err := h.favorites.RemoveFavorite(r.Context(), userID, devotionalID)
	if err != nil {
		if errors.Is(err, ErrDevotionalNotFound) {
			writeError(w, http.StatusNotFound, "rr:0x00D00003", "Devotional not found")
			return
		}
		writeServiceError(w, err)
		return
	}

	setStandardHeaders(w)
	w.WriteHeader(http.StatusNoContent)
}

// HandleListSeries handles GET /v1/devotionals/series.
func (h *Handler) HandleListSeries(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeUnauthorized(w)
		return
	}

	cursor := r.URL.Query().Get("cursor")
	limit := parseLimit(r, 20)

	var tier *ContentTier
	if t := r.URL.Query().Get("tier"); t != "" {
		ct := ContentTier(t)
		tier = &ct
	}

	seriesList, nextCursor, err := h.series.seriesRepo.List(r.Context(), tier, cursor, limit)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	// Enrich with user progress
	progressList, _ := h.series.progressRepo.ListAll(r.Context(), userID)
	progressMap := make(map[string]*SeriesProgressDoc, len(progressList))
	for i := range progressList {
		progressMap[progressList[i].SeriesID] = &progressList[i]
	}

	data := make([]DevotionalSeries, 0, len(seriesList))
	for _, s := range seriesList {
		ds := seriesToResponse(&s, progressMap[s.SeriesID], LangEN)
		data = append(data, ds)
	}

	meta := map[string]interface{}{
		"page": CursorPage{Limit: limit},
	}
	if nextCursor != "" {
		nc := nextCursor
		meta["page"] = CursorPage{NextCursor: &nc, Limit: limit}
	}

	setStandardHeaders(w)
	writeJSON(w, http.StatusOK, SeriesListResponse{
		Data: data,
		Meta: meta,
	})
}

// HandleGetSeries handles GET /v1/devotionals/series/{seriesId}.
func (h *Handler) HandleGetSeries(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeUnauthorized(w)
		return
	}

	seriesID := r.PathValue("seriesId")
	series, err := h.series.seriesRepo.GetByID(r.Context(), seriesID)
	if err != nil || series == nil {
		writeError(w, http.StatusNotFound, "rr:0x00D00030", "Series not found")
		return
	}

	progress, _ := h.series.progressRepo.Get(r.Context(), userID, seriesID)
	ds := seriesToResponse(series, progress, LangEN)

	setStandardHeaders(w)
	writeJSON(w, http.StatusOK, SeriesResponse{Data: ds})
}

// HandleActivateSeries handles POST /v1/devotionals/series/{seriesId}/activate.
func (h *Handler) HandleActivateSeries(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeUnauthorized(w)
		return
	}

	seriesID := r.PathValue("seriesId")
	// TODO: check if user owns series via content purchase system
	isOwned := true

	resp, err := h.series.ActivateSeries(r.Context(), userID, seriesID, isOwned)
	if err != nil {
		switch {
		case errors.Is(err, ErrSeriesNotFound):
			writeError(w, http.StatusNotFound, "rr:0x00D00030", "Series not found")
		case errors.Is(err, ErrSeriesNotOwned):
			writeJSON(w, http.StatusForbidden, errorResponse{
				Errors: []apiError{{
					Code:   "rr:0x00D00031",
					Status: 403,
					Title:  "Series Not Purchased",
					Detail: "Purchase this series to activate it.",
				}},
			})
		default:
			writeServiceError(w, err)
		}
		return
	}

	setStandardHeaders(w)
	writeJSON(w, http.StatusOK, resp)
}

// HandleShareDevotional handles POST /v1/devotionals/{id}/share.
func (h *Handler) HandleShareDevotional(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeUnauthorized(w)
		return
	}

	devotionalID := r.PathValue("id")

	var req ShareRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x00D00010", "Invalid request body: "+err.Error())
		return
	}

	// Stub contact lookup
	contactExists := func(contactID string) bool {
		return contactID != ""
	}

	resp, err := h.share.ShareDevotional(devotionalID, &req, contactExists)
	if err != nil {
		switch {
		case errors.Is(err, ErrContactNotFound):
			writeError(w, http.StatusNotFound, "rr:0x00D00040", "Contact not found")
		case errors.Is(err, ErrContactRequired):
			writeError(w, http.StatusBadRequest, "rr:0x00D00041", "Contact ID required for contact share")
		default:
			writeServiceError(w, err)
		}
		return
	}

	setStandardHeaders(w)
	writeJSON(w, http.StatusOK, resp)
}

// HandleGetStreak handles GET /v1/devotionals/streak.
func (h *Handler) HandleGetStreak(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeUnauthorized(w)
		return
	}

	userTimezone := "America/New_York" // TODO: from user profile
	streak, err := h.streak.GetStreak(r.Context(), userID, userTimezone)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	setStandardHeaders(w)
	writeJSON(w, http.StatusOK, StreakResponse{Data: *streak})
}

// --- Helper functions ---

func setStandardHeaders(w http.ResponseWriter) {
	w.Header().Set("Api-Version", apiVersion)
	w.Header().Set("X-Correlation-Id", uuid.New().String())
}

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
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

func writeError(w http.ResponseWriter, status int, code, detail string) {
	writeJSON(w, status, errorResponse{
		Errors: []apiError{{
			ID:            uuid.New().String(),
			Code:          code,
			Status:        status,
			Title:         http.StatusText(status),
			Detail:        detail,
			CorrelationID: uuid.New().String(),
		}},
	})
}

func writeUnauthorized(w http.ResponseWriter) {
	w.Header().Set("WWW-Authenticate", `Bearer realm="Regal Recovery"`)
	writeError(w, http.StatusUnauthorized, "rr:0x00D00099", "Missing or invalid authentication")
}

func writeServiceError(w http.ResponseWriter, err error) {
	writeError(w, http.StatusInternalServerError, "rr:0x00D0FFFF", "Internal server error")
}

func parseLimit(r *http.Request, defaultLimit int) int {
	if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil && l > 0 && l <= 100 {
			return l
		}
	}
	return defaultLimit
}

func parseListDevotionalsParams(r *http.Request) ListDevotionalsParams {
	params := ListDevotionalsParams{
		Cursor: r.URL.Query().Get("cursor"),
		Limit:  parseLimit(r, 20),
	}
	if t := r.URL.Query().Get("topic"); t != "" {
		topic := Topic(t)
		params.Topic = &topic
	}
	if a := r.URL.Query().Get("author"); a != "" {
		params.Author = &a
	}
	if s := r.URL.Query().Get("seriesId"); s != "" {
		params.SeriesID = &s
	}
	if t := r.URL.Query().Get("tier"); t != "" {
		tier := ContentTier(t)
		params.Tier = &tier
	}
	if l := r.URL.Query().Get("language"); l != "" {
		lang := Language(l)
		params.Language = &lang
	}
	if q := r.URL.Query().Get("search"); q != "" {
		params.Search = &q
	}
	return params
}

func parseListHistoryParams(r *http.Request) ListHistoryParams {
	params := ListHistoryParams{
		Cursor: r.URL.Query().Get("cursor"),
		Limit:  parseLimit(r, 20),
		Sort:   r.URL.Query().Get("sort"),
	}
	if params.Sort == "" {
		params.Sort = "-timestamp"
	}
	if s := r.URL.Query().Get("seriesId"); s != "" {
		params.SeriesID = &s
	}
	if t := r.URL.Query().Get("topic"); t != "" {
		topic := Topic(t)
		params.Topic = &topic
	}
	if a := r.URL.Query().Get("author"); a != "" {
		params.Author = &a
	}
	if d := r.URL.Query().Get("startDate"); d != "" {
		params.StartDate = &d
	}
	if d := r.URL.Query().Get("endDate"); d != "" {
		params.EndDate = &d
	}
	if q := r.URL.Query().Get("searchReflections"); q != "" {
		params.SearchReflections = &q
	}
	return params
}

func contentToDevotional(c *DevotionalContent, lang Language, translation BibleTranslation, isCompleted, isFavorite bool) *Devotional {
	d := &Devotional{
		ID:                 c.DevotionalID,
		Title:              c.Title,
		ScriptureReference: c.ScriptureReference,
		Topic:              c.Topic,
		Tier:               c.Tier,
		Language:           lang,
		SeriesID:           c.SeriesID,
		SeriesDay:          c.SeriesDay,
		AuthorName:         c.AuthorName,
		IsCompleted:        isCompleted,
		IsFavorite:         isFavorite,
		BibleTranslation:   translation,
	}

	if text, ok := c.ScriptureText[translation]; ok {
		d.ScriptureText = text
	}
	if reading, ok := c.Reading[lang]; ok {
		d.Reading = reading
	}
	if rc, ok := c.RecoveryConnection[lang]; ok {
		d.RecoveryConnection = rc
	}
	if rq, ok := c.ReflectionQuestion[lang]; ok {
		d.ReflectionQuestion = rq
	}
	if p, ok := c.Prayer[lang]; ok {
		d.Prayer = p
	}
	if bio, ok := c.AuthorBio[lang]; ok {
		d.AuthorBio = &bio
	}

	d.Links = map[string]string{
		"self": fmt.Sprintf("/v1/devotionals/%s", c.DevotionalID),
	}

	return d
}

func contentToSummary(c *DevotionalContent, isLocked, isCompleted, isFavorite bool) DevotionalSummary {
	return DevotionalSummary{
		ID:                 c.DevotionalID,
		Title:              c.Title,
		ScriptureReference: c.ScriptureReference,
		Topic:              c.Topic,
		AuthorName:         c.AuthorName,
		SeriesID:           c.SeriesID,
		Tier:               c.Tier,
		IsLocked:           isLocked,
		IsCompleted:        isCompleted,
		IsFavorite:         isFavorite,
		Links: map[string]string{
			"self": fmt.Sprintf("/v1/devotionals/%s", c.DevotionalID),
		},
	}
}

func seriesToResponse(s *SeriesContent, progress *SeriesProgressDoc, lang Language) DevotionalSeries {
	ds := DevotionalSeries{
		SeriesID:  s.SeriesID,
		TotalDays: s.TotalDays,
		Tier:      s.Tier,
		Price:     s.Price,
		Currency:  s.Currency,
		Category:  s.Category,
		Language:  s.Language,
		ThumbnailURL: s.ThumbnailURL,
		AuthorName:   s.AuthorName,
		Status:       SeriesNotStarted,
	}

	if name, ok := s.Name[lang]; ok {
		ds.Name = name
	}
	if desc, ok := s.Description[lang]; ok {
		ds.Description = desc
	}

	if progress != nil {
		ds.CurrentDay = &progress.CurrentDay
		ds.CompletedDays = progress.CompletedDays
		ds.Status = progress.Status
		ds.IsActive = progress.Status == SeriesActive
	}

	ds.Links = map[string]string{
		"self":        fmt.Sprintf("/v1/devotionals/series/%s", s.SeriesID),
		"devotionals": fmt.Sprintf("/v1/devotionals?seriesId=%s", s.SeriesID),
	}

	return ds
}
