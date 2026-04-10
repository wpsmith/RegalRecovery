// internal/domain/threecircles/handler.go
package threecircles

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/regalrecovery/api/internal/middleware"
)

// Handler holds route handlers for Three Circles endpoints.
type Handler struct {
	service ServiceInterface
	cache   CacheInterface
	flags   FeatureFlagInterface
}

// ServiceInterface defines the business logic operations for Three Circles.
type ServiceInterface interface {
	// Circle Set operations
	ListSets(ctx interface{}, userID string) ([]CircleSet, error)
	CreateSet(ctx interface{}, userID, tenantID string, req *CreateCircleSetRequest) (*CircleSet, error)
	GetSet(ctx interface{}, setID, userID string) (*CircleSet, error)
	ReplaceSet(ctx interface{}, setID, userID string, req *ReplaceCircleSetRequest) (*CircleSet, error)
	UpdateSet(ctx interface{}, setID, userID string, req *UpdateCircleSetRequest) (*CircleSet, error)
	DeleteSet(ctx interface{}, setID, userID string) error
	CommitSet(ctx interface{}, setID, userID string, req *CommitCircleSetRequest) (*CircleSet, error)

	// Item operations
	AddItem(ctx interface{}, setID, userID string, req *CreateCircleItemRequest) (*CircleItem, error)
	UpdateItem(ctx interface{}, setID, itemID, userID string, req *UpdateCircleItemRequest) (*CircleItem, error)
	DeleteItem(ctx interface{}, setID, itemID, userID string) error
	MoveItem(ctx interface{}, setID, itemID, userID string, req *MoveCircleItemRequest) (*CircleSet, error)

	// Version operations
	ListVersions(ctx interface{}, setID, userID string) ([]VersionSnapshot, error)
	GetVersion(ctx interface{}, setID, userID string, versionNumber int) (*VersionSnapshot, error)
	RestoreVersion(ctx interface{}, setID, userID string, versionNumber int) (*CircleSet, error)

	// Template operations
	ListTemplates(ctx interface{}, recoveryArea RecoveryArea, circle *CircleType, framework *FrameworkPreference) ([]Template, error)
	GetTemplate(ctx interface{}, templateID string) (*Template, error)

	// Starter Pack operations
	ListStarterPacks(ctx interface{}, recoveryArea RecoveryArea, variant *StarterPackVariant) ([]StarterPack, error)
	GetStarterPack(ctx interface{}, packID string) (*StarterPack, error)
	ApplyStarterPack(ctx interface{}, setID, packID, userID string) (*CircleSet, error)

	// Onboarding operations
	StartOnboarding(ctx interface{}, userID, tenantID string, req *StartOnboardingFlowRequest) (*OnboardingFlow, error)
	UpdateOnboarding(ctx interface{}, flowID, userID string, updates map[string]interface{}) (*OnboardingFlow, error)
	CompleteOnboarding(ctx interface{}, flowID, userID string) (*OnboardingFlow, error)

	// Sponsor Review operations
	CreateShare(ctx interface{}, setID, userID string, expiresInHours int) (*CircleSetShare, error)
	GetShare(ctx interface{}, shareCode string) (*CircleSet, *CircleSetShare, error)
	AddComment(ctx interface{}, shareCode string, req *AddCommentRequest) (*ShareComment, error)
	ListComments(ctx interface{}, setID, userID string) ([]ShareComment, error)

	// Pattern Analysis operations
	GetTimeline(ctx interface{}, userID string, period Period) ([]TimelineEntry, error)
	GetInsights(ctx interface{}, userID string) ([]PatternInsight, error)
	GetSummary(ctx interface{}, userID string, period Period) (*TimelineSummary, error)
	GetDriftAlerts(ctx interface{}, userID string) ([]DriftAlert, error)
	DismissDriftAlert(ctx interface{}, alertID, userID string) error

	// Review operations
	ListReviews(ctx interface{}, userID string) ([]ScheduledReview, error)
	StartReview(ctx interface{}, userID, tenantID string, req *StartReviewRequest) (*ScheduledReview, error)
	UpdateReview(ctx interface{}, reviewID, userID string, req *UpdateReviewRequest) (*ScheduledReview, error)
	CompleteReview(ctx interface{}, reviewID, userID string, req *CompleteReviewRequest) (*ScheduledReview, error)
}

// CacheInterface defines the optional cache operations for Three Circles.
type CacheInterface interface {
	InvalidateSet(ctx interface{}, setID string) error
	InvalidateSets(ctx interface{}, userID string) error
	InvalidateAll(ctx interface{}, userID string) error
}

// FeatureFlagInterface defines feature flag checking.
type FeatureFlagInterface interface {
	IsEnabled(ctx interface{}, flag string) bool
}

// NewHandler creates a new Handler with the given dependencies.
func NewHandler(service ServiceInterface, cache CacheInterface, flags FeatureFlagInterface) *Handler {
	return &Handler{
		service: service,
		cache:   cache,
		flags:   flags,
	}
}

// RegisterRoutes registers all Three Circles routes on the given mux.
func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	// Circle Sets
	mux.HandleFunc("GET /tools/three-circles/sets", h.HandleListSets)
	mux.HandleFunc("POST /tools/three-circles/sets", h.HandleCreateSet)
	mux.HandleFunc("GET /tools/three-circles/sets/{setId}", h.HandleGetSet)
	mux.HandleFunc("PUT /tools/three-circles/sets/{setId}", h.HandleReplaceSet)
	mux.HandleFunc("PATCH /tools/three-circles/sets/{setId}", h.HandleUpdateSet)
	mux.HandleFunc("DELETE /tools/three-circles/sets/{setId}", h.HandleDeleteSet)
	mux.HandleFunc("POST /tools/three-circles/sets/{setId}/commit", h.HandleCommitSet)

	// Items
	mux.HandleFunc("POST /tools/three-circles/sets/{setId}/items", h.HandleAddItem)
	mux.HandleFunc("PUT /tools/three-circles/sets/{setId}/items/{itemId}", h.HandleUpdateItem)
	mux.HandleFunc("DELETE /tools/three-circles/sets/{setId}/items/{itemId}", h.HandleDeleteItem)
	mux.HandleFunc("POST /tools/three-circles/sets/{setId}/items/{itemId}/move", h.HandleMoveItem)

	// Versions
	mux.HandleFunc("GET /tools/three-circles/sets/{setId}/versions", h.HandleListVersions)
	mux.HandleFunc("GET /tools/three-circles/sets/{setId}/versions/{versionId}", h.HandleGetVersion)
	mux.HandleFunc("POST /tools/three-circles/sets/{setId}/versions/{versionId}/restore", h.HandleRestoreVersion)

	// Templates + Starter Packs
	mux.HandleFunc("GET /tools/three-circles/templates", h.HandleListTemplates)
	mux.HandleFunc("GET /tools/three-circles/templates/{templateId}", h.HandleGetTemplate)
	mux.HandleFunc("GET /tools/three-circles/starter-packs", h.HandleListStarterPacks)
	mux.HandleFunc("GET /tools/three-circles/starter-packs/{packId}", h.HandleGetStarterPack)
	mux.HandleFunc("POST /tools/three-circles/sets/{setId}/apply-starter-pack", h.HandleApplyStarterPack)

	// Onboarding
	mux.HandleFunc("POST /tools/three-circles/onboarding/start", h.HandleStartOnboarding)
	mux.HandleFunc("PATCH /tools/three-circles/onboarding/{flowId}", h.HandleUpdateOnboarding)
	mux.HandleFunc("POST /tools/three-circles/onboarding/{flowId}/complete", h.HandleCompleteOnboarding)

	// Sponsor Review
	mux.HandleFunc("POST /tools/three-circles/sets/{setId}/share", h.HandleCreateShare)
	mux.HandleFunc("GET /tools/three-circles/share/{shareCode}", h.HandleViewShare)            // PUBLIC, no auth
	mux.HandleFunc("POST /tools/three-circles/share/{shareCode}/comments", h.HandleAddComment) // PUBLIC
	mux.HandleFunc("GET /tools/three-circles/sets/{setId}/comments", h.HandleListComments)

	// Patterns
	mux.HandleFunc("GET /tools/three-circles/patterns/timeline", h.HandleGetTimeline)
	mux.HandleFunc("GET /tools/three-circles/patterns/insights", h.HandleGetInsights)
	mux.HandleFunc("GET /tools/three-circles/patterns/summary", h.HandleGetSummary)
	mux.HandleFunc("GET /tools/three-circles/patterns/drift-alerts", h.HandleGetDriftAlerts)
	mux.HandleFunc("POST /tools/three-circles/patterns/drift-alerts/{alertId}/dismiss", h.HandleDismissDriftAlert)

	// Reviews
	mux.HandleFunc("GET /tools/three-circles/reviews", h.HandleListReviews)
	mux.HandleFunc("POST /tools/three-circles/reviews", h.HandleStartReview)
	mux.HandleFunc("PATCH /tools/three-circles/reviews/{reviewId}", h.HandleUpdateReview)
	mux.HandleFunc("POST /tools/three-circles/reviews/{reviewId}/complete", h.HandleCompleteReview)
}

// --- Circle Set handlers ---

// HandleListSets handles GET /tools/three-circles/sets.
func (h *Handler) HandleListSets(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	sets, err := h.service.ListSets(r.Context(), userID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, CircleSetListResponse{
		Data: sets,
		Meta: map[string]interface{}{"count": len(sets)},
		Links: map[string]string{
			"self": r.URL.String(),
		},
	})
}

// HandleCreateSet handles POST /tools/three-circles/sets.
func (h *Handler) HandleCreateSet(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	tenantID := middleware.GetTenantID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	var req CreateCircleSetRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x000B0001", "Invalid request body: "+err.Error())
		return
	}

	set, err := h.service.CreateSet(r.Context(), userID, tenantID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	if h.cache != nil {
		_ = h.cache.InvalidateSets(r.Context(), userID)
	}

	w.Header().Set("Location", fmt.Sprintf("/tools/three-circles/sets/%s", set.ID))
	writeJSON(w, http.StatusCreated, CircleSetResponse{
		Data: *set,
		Meta: map[string]interface{}{"created": true},
	})
}

// HandleGetSet handles GET /tools/three-circles/sets/{setId}.
func (h *Handler) HandleGetSet(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	setID := r.PathValue("setId")
	if setID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0002", "Set ID is required")
		return
	}

	set, err := h.service.GetSet(r.Context(), setID, userID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, CircleSetResponse{
		Data: *set,
	})
}

// HandleReplaceSet handles PUT /tools/three-circles/sets/{setId}.
func (h *Handler) HandleReplaceSet(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	setID := r.PathValue("setId")
	if setID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0002", "Set ID is required")
		return
	}

	var req ReplaceCircleSetRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x000B0001", "Invalid request body: "+err.Error())
		return
	}

	set, err := h.service.ReplaceSet(r.Context(), setID, userID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	if h.cache != nil {
		_ = h.cache.InvalidateSet(r.Context(), setID)
		_ = h.cache.InvalidateSets(r.Context(), userID)
	}

	writeJSON(w, http.StatusOK, CircleSetResponse{
		Data: *set,
	})
}

// HandleUpdateSet handles PATCH /tools/three-circles/sets/{setId}.
func (h *Handler) HandleUpdateSet(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	setID := r.PathValue("setId")
	if setID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0002", "Set ID is required")
		return
	}

	var req UpdateCircleSetRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x000B0001", "Invalid request body: "+err.Error())
		return
	}

	set, err := h.service.UpdateSet(r.Context(), setID, userID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	if h.cache != nil {
		_ = h.cache.InvalidateSet(r.Context(), setID)
		_ = h.cache.InvalidateSets(r.Context(), userID)
	}

	writeJSON(w, http.StatusOK, CircleSetResponse{
		Data: *set,
	})
}

// HandleDeleteSet handles DELETE /tools/three-circles/sets/{setId}.
func (h *Handler) HandleDeleteSet(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	setID := r.PathValue("setId")
	if setID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0002", "Set ID is required")
		return
	}

	if err := h.service.DeleteSet(r.Context(), setID, userID); err != nil {
		writeServiceError(w, err)
		return
	}

	if h.cache != nil {
		_ = h.cache.InvalidateSet(r.Context(), setID)
		_ = h.cache.InvalidateSets(r.Context(), userID)
	}

	w.WriteHeader(http.StatusNoContent)
}

// HandleCommitSet handles POST /tools/three-circles/sets/{setId}/commit.
func (h *Handler) HandleCommitSet(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	setID := r.PathValue("setId")
	if setID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0002", "Set ID is required")
		return
	}

	var req CommitCircleSetRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x000B0001", "Invalid request body: "+err.Error())
		return
	}

	set, err := h.service.CommitSet(r.Context(), setID, userID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	if h.cache != nil {
		_ = h.cache.InvalidateSet(r.Context(), setID)
		_ = h.cache.InvalidateSets(r.Context(), userID)
	}

	writeJSON(w, http.StatusOK, CircleSetResponse{
		Data: *set,
		Meta: map[string]interface{}{"committed": true},
	})
}

// --- Item handlers ---

// HandleAddItem handles POST /tools/three-circles/sets/{setId}/items.
func (h *Handler) HandleAddItem(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	setID := r.PathValue("setId")
	if setID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0002", "Set ID is required")
		return
	}

	var req CreateCircleItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x000B0001", "Invalid request body: "+err.Error())
		return
	}

	item, err := h.service.AddItem(r.Context(), setID, userID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	if h.cache != nil {
		_ = h.cache.InvalidateSet(r.Context(), setID)
		_ = h.cache.InvalidateSets(r.Context(), userID)
	}

	w.Header().Set("Location", fmt.Sprintf("/tools/three-circles/sets/%s/items/%s", setID, item.ItemID))
	writeJSON(w, http.StatusCreated, CircleItemResponse{
		Data: *item,
		Meta: map[string]interface{}{"created": true},
	})
}

// HandleUpdateItem handles PUT /tools/three-circles/sets/{setId}/items/{itemId}.
func (h *Handler) HandleUpdateItem(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	setID := r.PathValue("setId")
	itemID := r.PathValue("itemId")
	if setID == "" || itemID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0002", "Set ID and Item ID are required")
		return
	}

	var req UpdateCircleItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x000B0001", "Invalid request body: "+err.Error())
		return
	}

	item, err := h.service.UpdateItem(r.Context(), setID, itemID, userID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	if h.cache != nil {
		_ = h.cache.InvalidateSet(r.Context(), setID)
		_ = h.cache.InvalidateSets(r.Context(), userID)
	}

	writeJSON(w, http.StatusOK, CircleItemResponse{
		Data: *item,
	})
}

// HandleDeleteItem handles DELETE /tools/three-circles/sets/{setId}/items/{itemId}.
func (h *Handler) HandleDeleteItem(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	setID := r.PathValue("setId")
	itemID := r.PathValue("itemId")
	if setID == "" || itemID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0002", "Set ID and Item ID are required")
		return
	}

	if err := h.service.DeleteItem(r.Context(), setID, itemID, userID); err != nil {
		writeServiceError(w, err)
		return
	}

	if h.cache != nil {
		_ = h.cache.InvalidateSet(r.Context(), setID)
		_ = h.cache.InvalidateSets(r.Context(), userID)
	}

	w.WriteHeader(http.StatusNoContent)
}

// HandleMoveItem handles POST /tools/three-circles/sets/{setId}/items/{itemId}/move.
func (h *Handler) HandleMoveItem(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	setID := r.PathValue("setId")
	itemID := r.PathValue("itemId")
	if setID == "" || itemID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0002", "Set ID and Item ID are required")
		return
	}

	var req MoveCircleItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x000B0001", "Invalid request body: "+err.Error())
		return
	}

	set, err := h.service.MoveItem(r.Context(), setID, itemID, userID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	if h.cache != nil {
		_ = h.cache.InvalidateSet(r.Context(), setID)
		_ = h.cache.InvalidateSets(r.Context(), userID)
	}

	writeJSON(w, http.StatusOK, CircleSetResponse{
		Data: *set,
		Meta: map[string]interface{}{"itemMoved": true},
	})
}

// --- Version handlers ---

// HandleListVersions handles GET /tools/three-circles/sets/{setId}/versions.
func (h *Handler) HandleListVersions(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	setID := r.PathValue("setId")
	if setID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0002", "Set ID is required")
		return
	}

	versions, err := h.service.ListVersions(r.Context(), setID, userID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, VersionHistoryResponse{
		Data: versions,
		Meta: map[string]interface{}{"count": len(versions)},
		Links: map[string]string{
			"self": r.URL.String(),
		},
	})
}

// HandleGetVersion handles GET /tools/three-circles/sets/{setId}/versions/{versionId}.
func (h *Handler) HandleGetVersion(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	setID := r.PathValue("setId")
	versionID := r.PathValue("versionId")
	if setID == "" || versionID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0002", "Set ID and Version ID are required")
		return
	}

	// Parse version number
	var versionNum int
	if _, err := fmt.Sscanf(versionID, "%d", &versionNum); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x000B0003", "Invalid version ID format")
		return
	}

	version, err := h.service.GetVersion(r.Context(), setID, userID, versionNum)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, VersionSnapshotResponse{
		Data: *version,
	})
}

// HandleRestoreVersion handles POST /tools/three-circles/sets/{setId}/versions/{versionId}/restore.
func (h *Handler) HandleRestoreVersion(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	setID := r.PathValue("setId")
	versionID := r.PathValue("versionId")
	if setID == "" || versionID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0002", "Set ID and Version ID are required")
		return
	}

	// Parse version number
	var versionNum int
	if _, err := fmt.Sscanf(versionID, "%d", &versionNum); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x000B0003", "Invalid version ID format")
		return
	}

	set, err := h.service.RestoreVersion(r.Context(), setID, userID, versionNum)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	if h.cache != nil {
		_ = h.cache.InvalidateSet(r.Context(), setID)
		_ = h.cache.InvalidateSets(r.Context(), userID)
	}

	writeJSON(w, http.StatusOK, CircleSetResponse{
		Data: *set,
		Meta: map[string]interface{}{"restored": true, "fromVersion": versionNum},
	})
}

// --- Template handlers ---

// HandleListTemplates handles GET /tools/three-circles/templates.
func (h *Handler) HandleListTemplates(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	// Parse query parameters
	recoveryAreaStr := r.URL.Query().Get("recoveryArea")
	circleStr := r.URL.Query().Get("circle")
	frameworkStr := r.URL.Query().Get("framework")

	if recoveryAreaStr == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0004", "Query parameter 'recoveryArea' is required")
		return
	}

	recoveryArea := RecoveryArea(recoveryAreaStr)
	if !recoveryArea.IsValid() {
		writeError(w, http.StatusBadRequest, "rr:0x000B0005", "Invalid recovery area")
		return
	}

	var circle *CircleType
	if circleStr != "" {
		c := CircleType(circleStr)
		if !c.IsValid() {
			writeError(w, http.StatusBadRequest, "rr:0x000B0006", "Invalid circle type")
			return
		}
		circle = &c
	}

	var framework *FrameworkPreference
	if frameworkStr != "" {
		f := FrameworkPreference(frameworkStr)
		if !f.IsValid() {
			writeError(w, http.StatusBadRequest, "rr:0x000B0007", "Invalid framework preference")
			return
		}
		framework = &f
	}

	templates, err := h.service.ListTemplates(r.Context(), recoveryArea, circle, framework)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": templates,
		"meta": map[string]interface{}{
			"count":        len(templates),
			"recoveryArea": recoveryArea,
		},
		"links": map[string]string{
			"self": r.URL.String(),
		},
	})
}

// HandleGetTemplate handles GET /tools/three-circles/templates/{templateId}.
func (h *Handler) HandleGetTemplate(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	templateID := r.PathValue("templateId")
	if templateID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0008", "Template ID is required")
		return
	}

	template, err := h.service.GetTemplate(r.Context(), templateID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": template,
	})
}

// --- Starter Pack handlers ---

// HandleListStarterPacks handles GET /tools/three-circles/starter-packs.
func (h *Handler) HandleListStarterPacks(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	// Parse query parameters
	recoveryAreaStr := r.URL.Query().Get("recoveryArea")
	variantStr := r.URL.Query().Get("variant")

	if recoveryAreaStr == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0004", "Query parameter 'recoveryArea' is required")
		return
	}

	recoveryArea := RecoveryArea(recoveryAreaStr)
	if !recoveryArea.IsValid() {
		writeError(w, http.StatusBadRequest, "rr:0x000B0005", "Invalid recovery area")
		return
	}

	var variant *StarterPackVariant
	if variantStr != "" {
		v := StarterPackVariant(variantStr)
		variant = &v
	}

	packs, err := h.service.ListStarterPacks(r.Context(), recoveryArea, variant)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": packs,
		"meta": map[string]interface{}{
			"count":        len(packs),
			"recoveryArea": recoveryArea,
		},
		"links": map[string]string{
			"self": r.URL.String(),
		},
	})
}

// HandleGetStarterPack handles GET /tools/three-circles/starter-packs/{packId}.
func (h *Handler) HandleGetStarterPack(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	packID := r.PathValue("packId")
	if packID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0009", "Pack ID is required")
		return
	}

	pack, err := h.service.GetStarterPack(r.Context(), packID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": pack,
	})
}

// HandleApplyStarterPack handles POST /tools/three-circles/sets/{setId}/apply-starter-pack.
func (h *Handler) HandleApplyStarterPack(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	setID := r.PathValue("setId")
	if setID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0002", "Set ID is required")
		return
	}

	var req struct {
		PackID string `json:"packId"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x000B0001", "Invalid request body: "+err.Error())
		return
	}

	if req.PackID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0009", "Pack ID is required")
		return
	}

	set, err := h.service.ApplyStarterPack(r.Context(), setID, req.PackID, userID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	if h.cache != nil {
		_ = h.cache.InvalidateSet(r.Context(), setID)
		_ = h.cache.InvalidateSets(r.Context(), userID)
	}

	writeJSON(w, http.StatusOK, CircleSetResponse{
		Data: *set,
		Meta: map[string]interface{}{"starterPackApplied": true, "packId": req.PackID},
	})
}

// --- Onboarding handlers ---

// HandleStartOnboarding handles POST /tools/three-circles/onboarding/start.
func (h *Handler) HandleStartOnboarding(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	tenantID := middleware.GetTenantID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	var req StartOnboardingFlowRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x000B0001", "Invalid request body: "+err.Error())
		return
	}

	flow, err := h.service.StartOnboarding(r.Context(), userID, tenantID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	w.Header().Set("Location", fmt.Sprintf("/tools/three-circles/onboarding/%s", flow.FlowID))
	writeJSON(w, http.StatusCreated, OnboardingFlowResponse{
		Data: *flow,
		Meta: map[string]interface{}{"started": true},
	})
}

// HandleUpdateOnboarding handles PATCH /tools/three-circles/onboarding/{flowId}.
func (h *Handler) HandleUpdateOnboarding(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	flowID := r.PathValue("flowId")
	if flowID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0010", "Flow ID is required")
		return
	}

	var updates map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&updates); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x000B0001", "Invalid request body: "+err.Error())
		return
	}

	flow, err := h.service.UpdateOnboarding(r.Context(), flowID, userID, updates)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, OnboardingFlowResponse{
		Data: *flow,
	})
}

// HandleCompleteOnboarding handles POST /tools/three-circles/onboarding/{flowId}/complete.
func (h *Handler) HandleCompleteOnboarding(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	flowID := r.PathValue("flowId")
	if flowID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0010", "Flow ID is required")
		return
	}

	flow, err := h.service.CompleteOnboarding(r.Context(), flowID, userID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, OnboardingFlowResponse{
		Data: *flow,
		Meta: map[string]interface{}{"completed": true},
	})
}

// --- Sponsor Review handlers ---

// HandleCreateShare handles POST /tools/three-circles/sets/{setId}/share.
func (h *Handler) HandleCreateShare(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	setID := r.PathValue("setId")
	if setID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0002", "Set ID is required")
		return
	}

	var req CreateShareRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		// Use default if body is empty
		req.ExpiresInHours = 168 // 7 days
	}

	if req.ExpiresInHours <= 0 {
		req.ExpiresInHours = 168
	}
	if req.ExpiresInHours > 336 {
		req.ExpiresInHours = 336 // Max 14 days
	}

	share, err := h.service.CreateShare(r.Context(), setID, userID, req.ExpiresInHours)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusCreated, map[string]interface{}{
		"data": share,
		"meta": map[string]interface{}{
			"shareUrl": fmt.Sprintf("/tools/three-circles/share/%s", share.ShareCode),
		},
	})
}

// HandleViewShare handles GET /tools/three-circles/share/{shareCode}.
// This is a PUBLIC endpoint (no auth required).
func (h *Handler) HandleViewShare(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	shareCode := r.PathValue("shareCode")
	if shareCode == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0011", "Share code is required")
		return
	}

	set, share, err := h.service.GetShare(r.Context(), shareCode)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	// Check expiration
	if time.Now().After(share.ExpiresAt) {
		writeError(w, http.StatusGone, "rr:0x000B0012", "Share link has expired")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": set,
		"meta": map[string]interface{}{
			"shareId":   share.ShareID,
			"expiresAt": share.ExpiresAt,
		},
	})
}

// HandleAddComment handles POST /tools/three-circles/share/{shareCode}/comments.
// This is a PUBLIC endpoint (no auth required).
func (h *Handler) HandleAddComment(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	shareCode := r.PathValue("shareCode")
	if shareCode == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0011", "Share code is required")
		return
	}

	var req AddCommentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x000B0001", "Invalid request body: "+err.Error())
		return
	}

	if req.CommenterName == "" || req.CommentText == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0013", "Commenter name and comment text are required")
		return
	}

	comment, err := h.service.AddComment(r.Context(), shareCode, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusCreated, map[string]interface{}{
		"data": comment,
		"meta": map[string]interface{}{"created": true},
	})
}

// HandleListComments handles GET /tools/three-circles/sets/{setId}/comments.
func (h *Handler) HandleListComments(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	setID := r.PathValue("setId")
	if setID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0002", "Set ID is required")
		return
	}

	comments, err := h.service.ListComments(r.Context(), setID, userID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": comments,
		"meta": map[string]interface{}{"count": len(comments)},
		"links": map[string]string{
			"self": r.URL.String(),
		},
	})
}

// --- Pattern Analysis handlers ---

// HandleGetTimeline handles GET /tools/three-circles/patterns/timeline.
func (h *Handler) HandleGetTimeline(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	periodStr := r.URL.Query().Get("period")
	if periodStr == "" {
		periodStr = "30d" // Default to 30 days
	}

	period := Period(periodStr)
	if !period.IsValid() {
		writeError(w, http.StatusBadRequest, "rr:0x000B0014", "Invalid period parameter")
		return
	}

	entries, err := h.service.GetTimeline(r.Context(), userID, period)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": entries,
		"meta": map[string]interface{}{
			"period": period,
			"count":  len(entries),
		},
		"links": map[string]string{
			"self": r.URL.String(),
		},
	})
}

// HandleGetInsights handles GET /tools/three-circles/patterns/insights.
func (h *Handler) HandleGetInsights(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	insights, err := h.service.GetInsights(r.Context(), userID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": insights,
		"meta": map[string]interface{}{"count": len(insights)},
		"links": map[string]string{
			"self": r.URL.String(),
		},
	})
}

// HandleGetSummary handles GET /tools/three-circles/patterns/summary.
func (h *Handler) HandleGetSummary(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	periodStr := r.URL.Query().Get("period")
	if periodStr == "" {
		periodStr = "30d" // Default to 30 days
	}

	period := Period(periodStr)
	if !period.IsValid() {
		writeError(w, http.StatusBadRequest, "rr:0x000B0014", "Invalid period parameter")
		return
	}

	summary, err := h.service.GetSummary(r.Context(), userID, period)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": summary,
	})
}

// HandleGetDriftAlerts handles GET /tools/three-circles/patterns/drift-alerts.
func (h *Handler) HandleGetDriftAlerts(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	alerts, err := h.service.GetDriftAlerts(r.Context(), userID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": alerts,
		"meta": map[string]interface{}{"count": len(alerts)},
		"links": map[string]string{
			"self": r.URL.String(),
		},
	})
}

// HandleDismissDriftAlert handles POST /tools/three-circles/patterns/drift-alerts/{alertId}/dismiss.
func (h *Handler) HandleDismissDriftAlert(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	alertID := r.PathValue("alertId")
	if alertID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0015", "Alert ID is required")
		return
	}

	if err := h.service.DismissDriftAlert(r.Context(), alertID, userID); err != nil {
		writeServiceError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// --- Review handlers ---

// HandleListReviews handles GET /tools/three-circles/reviews.
func (h *Handler) HandleListReviews(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	reviews, err := h.service.ListReviews(r.Context(), userID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": reviews,
		"meta": map[string]interface{}{"count": len(reviews)},
		"links": map[string]string{
			"self": r.URL.String(),
		},
	})
}

// HandleStartReview handles POST /tools/three-circles/reviews.
func (h *Handler) HandleStartReview(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	tenantID := middleware.GetTenantID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	var req StartReviewRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x000B0001", "Invalid request body: "+err.Error())
		return
	}

	review, err := h.service.StartReview(r.Context(), userID, tenantID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	w.Header().Set("Location", fmt.Sprintf("/tools/three-circles/reviews/%s", review.ReviewID))
	writeJSON(w, http.StatusCreated, map[string]interface{}{
		"data": review,
		"meta": map[string]interface{}{"created": true},
	})
}

// HandleUpdateReview handles PATCH /tools/three-circles/reviews/{reviewId}.
func (h *Handler) HandleUpdateReview(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	reviewID := r.PathValue("reviewId")
	if reviewID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0016", "Review ID is required")
		return
	}

	var req UpdateReviewRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x000B0001", "Invalid request body: "+err.Error())
		return
	}

	review, err := h.service.UpdateReview(r.Context(), reviewID, userID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": review,
	})
}

// HandleCompleteReview handles POST /tools/three-circles/reviews/{reviewId}/complete.
func (h *Handler) HandleCompleteReview(w http.ResponseWriter, r *http.Request) {
	if !h.checkFeatureFlag(w, r) {
		return
	}

	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeError(w, http.StatusUnauthorized, "rr:0x40010001", "Authentication required")
		return
	}

	reviewID := r.PathValue("reviewId")
	if reviewID == "" {
		writeError(w, http.StatusBadRequest, "rr:0x000B0016", "Review ID is required")
		return
	}

	var req CompleteReviewRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "rr:0x000B0001", "Invalid request body: "+err.Error())
		return
	}

	review, err := h.service.CompleteReview(r.Context(), reviewID, userID, &req)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": review,
		"meta": map[string]interface{}{"completed": true},
	})
}

// --- Helper methods ---

// checkFeatureFlag checks if the Three Circles feature is enabled.
// Returns false and writes 404 response if disabled.
func (h *Handler) checkFeatureFlag(w http.ResponseWriter, r *http.Request) bool {
	if h.flags != nil && !h.flags.IsEnabled(r.Context(), "feature.3circles") {
		writeError(w, http.StatusNotFound, "rr:0x40410001", "Feature not available")
		return false
	}
	return true
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
	case errors.Is(err, ErrSetNotFound), errors.Is(err, ErrItemNotFound), errors.Is(err, ErrTemplateNotFound):
		writeError(w, http.StatusNotFound, "rr:0x000B0017", err.Error())
	case errors.Is(err, ErrInvalidCircleType), errors.Is(err, ErrInvalidStatus), errors.Is(err, ErrInvalidRecoveryArea),
		errors.Is(err, ErrInvalidFramework), errors.Is(err, ErrInvalidSource), errors.Is(err, ErrInvalidChangeType):
		writeError(w, http.StatusBadRequest, "rr:0x000B0018", err.Error())
	case errors.Is(err, ErrSetNameTooLong), errors.Is(err, ErrSetNameEmpty), errors.Is(err, ErrBehaviorNameTooLong),
		errors.Is(err, ErrBehaviorNameEmpty), errors.Is(err, ErrNotesTooLong), errors.Is(err, ErrSpecificityDetailTooLong),
		errors.Is(err, ErrCategoryTooLong), errors.Is(err, ErrChangeNoteTooLong):
		writeError(w, http.StatusBadRequest, "rr:0x000B0019", err.Error())
	case errors.Is(err, ErrInnerCircleFull), errors.Is(err, ErrMiddleCircleFull), errors.Is(err, ErrOuterCircleFull),
		errors.Is(err, ErrInnerCircleEmpty):
		writeError(w, http.StatusBadRequest, "rr:0x000B0020", err.Error())
	case errors.Is(err, ErrCannotCommitActive), errors.Is(err, ErrCannotCommitArchived), errors.Is(err, ErrSameCircleMove):
		writeError(w, http.StatusConflict, "rr:0x40910001", err.Error())
	case strings.Contains(err.Error(), "not found"):
		writeError(w, http.StatusNotFound, "rr:0x000B0017", err.Error())
	case strings.Contains(err.Error(), "expired"):
		writeError(w, http.StatusGone, "rr:0x000B0012", err.Error())
	case strings.Contains(err.Error(), "access denied"):
		writeError(w, http.StatusForbidden, "rr:0x40310001", err.Error())
	default:
		writeError(w, http.StatusInternalServerError, "rr:0x50010001", "Internal server error")
	}
}
