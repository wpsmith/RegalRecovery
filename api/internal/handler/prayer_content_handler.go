// internal/handler/prayer_content_handler.go
package handler

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/regalrecovery/api/internal/domain/prayer"
)

// PrayerContentHandler handles HTTP requests for prayer content endpoints.
type PrayerContentHandler struct {
	service  *prayer.Service
	baseURL  string
}

// NewPrayerContentHandler creates a new PrayerContentHandler.
func NewPrayerContentHandler(service *prayer.Service, baseURL string) *PrayerContentHandler {
	return &PrayerContentHandler{
		service: service,
		baseURL: baseURL,
	}
}

// ListPrayers handles GET /content/prayers.
func (h *PrayerContentHandler) ListPrayers(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()

	var pack, topic, search, tier *string
	if p := q.Get("pack"); p != "" {
		pack = &p
	}
	if t := q.Get("topic"); t != "" {
		topic = &t
	}
	if s := q.Get("search"); s != "" {
		search = &s
	}
	if t := q.Get("tier"); t != "" {
		tier = &t
	}

	var step *int
	if s := q.Get("step"); s != "" {
		v, _ := strconv.Atoi(s)
		step = &v
	}

	cursor := q.Get("cursor")
	limit := 20
	if l := q.Get("limit"); l != "" {
		limit, _ = strconv.Atoi(l)
	}

	// This delegates to the library repo directly via service.
	// In production this would call through the service; for now we acknowledge
	// the handler wiring exists for contract validation.
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"data":  []interface{}{},
		"links": map[string]string{"self": r.URL.String()},
		"meta": map[string]interface{}{
			"page": map[string]interface{}{
				"nextCursor": nil,
				"limit":      limit,
			},
		},
	})

	// Suppress unused variable warnings.
	_ = pack
	_ = topic
	_ = search
	_ = tier
	_ = step
	_ = cursor
}

// GetTodayPrayer handles GET /content/prayers/today.
func (h *PrayerContentHandler) GetTodayPrayer(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"data": nil,
	})
}

// GetPrayer handles GET /content/prayers/{id}.
func (h *PrayerContentHandler) GetPrayer(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"data": nil,
	})
}

// CreatePersonalPrayer handles POST /content/prayers/personal.
func (h *PrayerContentHandler) CreatePersonalPrayer(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("userID").(string)

	var body struct {
		Title              string   `json:"title"`
		Body               string   `json:"body"`
		TopicTags          []string `json:"topicTags,omitempty"`
		ScriptureReference *string  `json:"scriptureReference,omitempty"`
	}

	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x00500000", "Bad Request", "Request body is malformed")
		return
	}

	req := &prayer.CreatePersonalPrayerRequest{
		Title:              body.Title,
		Body:               body.Body,
		TopicTags:          body.TopicTags,
		ScriptureReference: body.ScriptureReference,
	}

	pp, err := h.service.CreatePersonalPrayer(r.Context(), userID, req)
	if err != nil {
		writeDomainError(w, err)
		return
	}

	w.Header().Set("Location", h.baseURL+"/v1/content/prayers/personal/"+pp.ID)
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"data": personalPrayerToJSON(pp, h.baseURL),
		"meta": map[string]interface{}{
			"createdAt":  pp.CreatedAt.Format(time.RFC3339),
			"modifiedAt": pp.ModifiedAt.Format(time.RFC3339),
		},
	})
}

// ListPersonalPrayers handles GET /content/prayers/personal.
func (h *PrayerContentHandler) ListPersonalPrayers(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("userID").(string)
	q := r.URL.Query()

	cursor := q.Get("cursor")
	limit := 50
	if l := q.Get("limit"); l != "" {
		limit, _ = strconv.Atoi(l)
	}

	prayers, nextCursor, err := h.service.ListPersonalPrayers(r.Context(), userID, cursor, limit)
	if err != nil {
		writeDomainError(w, err)
		return
	}

	data := make([]interface{}, len(prayers))
	for i, pp := range prayers {
		data[i] = personalPrayerToJSON(&pp, h.baseURL)
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

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// UpdatePersonalPrayer handles PATCH /content/prayers/personal/{id}.
func (h *PrayerContentHandler) UpdatePersonalPrayer(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("userID").(string)
	prayerID := r.PathValue("id")

	var body struct {
		Title              *string  `json:"title,omitempty"`
		Body               *string  `json:"body,omitempty"`
		TopicTags          []string `json:"topicTags,omitempty"`
		ScriptureReference *string  `json:"scriptureReference,omitempty"`
	}

	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x00500000", "Bad Request", "Request body is malformed")
		return
	}

	req := &prayer.UpdatePersonalPrayerRequest{
		Title:              body.Title,
		Body:               body.Body,
		TopicTags:          body.TopicTags,
		ScriptureReference: body.ScriptureReference,
	}

	pp, err := h.service.UpdatePersonalPrayer(r.Context(), userID, prayerID, req)
	if err != nil {
		writeDomainError(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"data": personalPrayerToJSON(pp, h.baseURL),
		"meta": map[string]interface{}{
			"createdAt":  pp.CreatedAt.Format(time.RFC3339),
			"modifiedAt": pp.ModifiedAt.Format(time.RFC3339),
		},
	})
}

// DeletePersonalPrayer handles DELETE /content/prayers/personal/{id}.
func (h *PrayerContentHandler) DeletePersonalPrayer(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("userID").(string)
	prayerID := r.PathValue("id")

	err := h.service.DeletePersonalPrayer(r.Context(), userID, prayerID)
	if err != nil {
		writeDomainError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// ReorderPersonalPrayers handles PUT /content/prayers/personal/order.
func (h *PrayerContentHandler) ReorderPersonalPrayers(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("userID").(string)

	var body struct {
		PrayerIDs []string `json:"prayerIds"`
	}

	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x00500000", "Bad Request", "Request body is malformed")
		return
	}

	err := h.service.ReorderPersonalPrayers(r.Context(), userID, body.PrayerIDs)
	if err != nil {
		writeDomainError(w, err)
		return
	}

	w.WriteHeader(http.StatusOK)
}

// ListFavorites handles GET /content/prayers/favorites.
func (h *PrayerContentHandler) ListFavorites(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("userID").(string)
	q := r.URL.Query()

	cursor := q.Get("cursor")
	limit := 50
	if l := q.Get("limit"); l != "" {
		limit, _ = strconv.Atoi(l)
	}

	favorites, nextCursor, err := h.service.ListFavorites(r.Context(), userID, cursor, limit)
	if err != nil {
		writeDomainError(w, err)
		return
	}

	data := make([]interface{}, len(favorites))
	for i, fav := range favorites {
		data[i] = map[string]interface{}{
			"prayerId":     fav.PrayerID,
			"prayerSource": fav.PrayerSource,
			"title":        fav.Title,
			"createdAt":    fav.CreatedAt.Format(time.RFC3339),
		}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"data": data,
		"meta": map[string]interface{}{
			"page": map[string]interface{}{
				"nextCursor": nilIfEmpty(nextCursor),
				"limit":      limit,
			},
		},
	})
}

// FavoritePrayer handles POST /content/prayers/favorites/{id}.
func (h *PrayerContentHandler) FavoritePrayer(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("userID").(string)
	prayerID := r.PathValue("id")

	err := h.service.FavoritePrayer(r.Context(), userID, prayerID)
	if err != nil {
		writeDomainError(w, err)
		return
	}

	w.WriteHeader(http.StatusCreated)
}

// UnfavoritePrayer handles DELETE /content/prayers/favorites/{id}.
func (h *PrayerContentHandler) UnfavoritePrayer(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("userID").(string)
	prayerID := r.PathValue("id")

	err := h.service.UnfavoritePrayer(r.Context(), userID, prayerID)
	if err != nil {
		writeDomainError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// personalPrayerToJSON converts a PersonalPrayer to a JSON-friendly map.
func personalPrayerToJSON(pp *prayer.PersonalPrayer, baseURL string) map[string]interface{} {
	result := map[string]interface{}{
		"id":         pp.ID,
		"title":      pp.Title,
		"body":       pp.Body,
		"topicTags":  pp.TopicTags,
		"isFavorite": pp.IsFavorite,
		"sortOrder":  pp.SortOrder,
		"createdAt":  pp.CreatedAt.Format(time.RFC3339),
		"modifiedAt": pp.ModifiedAt.Format(time.RFC3339),
		"links": map[string]string{
			"self": baseURL + "/v1/content/prayers/personal/" + pp.ID,
		},
	}

	if pp.ScriptureReference != nil {
		result["scriptureReference"] = *pp.ScriptureReference
	} else {
		result["scriptureReference"] = nil
	}

	return result
}
