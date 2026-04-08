// internal/domain/nutrition/handler.go
package nutrition

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/regalrecovery/api/internal/middleware"
)

// Handler holds route handlers for the nutrition endpoints.
type Handler struct {
	mealService      *MealService
	hydrationService *HydrationService
	settingsService  *SettingsService
	flagEnabled      func(ctx interface{}, key string) bool
}

// NewHandler creates a new Handler.
func NewHandler(
	mealService *MealService,
	hydrationService *HydrationService,
	settingsService *SettingsService,
	flagEnabled func(ctx interface{}, key string) bool,
) *Handler {
	return &Handler{
		mealService:      mealService,
		hydrationService: hydrationService,
		settingsService:  settingsService,
		flagEnabled:      flagEnabled,
	}
}

// RegisterRoutes registers nutrition routes on the given mux.
func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	// Meal CRUD.
	mux.HandleFunc("POST /activities/nutrition/meals", h.withFeatureFlag(h.HandleCreateMealLog))
	mux.HandleFunc("GET /activities/nutrition/meals", h.withFeatureFlag(h.HandleListMealLogs))
	mux.HandleFunc("GET /activities/nutrition/meals/{mealId}", h.withFeatureFlag(h.HandleGetMealLog))
	mux.HandleFunc("PATCH /activities/nutrition/meals/{mealId}", h.withFeatureFlag(h.HandleUpdateMealLog))
	mux.HandleFunc("DELETE /activities/nutrition/meals/{mealId}", h.withFeatureFlag(h.HandleDeleteMealLog))

	// Quick log.
	mux.HandleFunc("POST /activities/nutrition/meals/quick", h.withFeatureFlag(h.HandleCreateQuickMealLog))

	// Hydration.
	mux.HandleFunc("GET /activities/nutrition/hydration", h.withFeatureFlag(h.HandleGetHydrationToday))
	mux.HandleFunc("POST /activities/nutrition/hydration/log", h.withFeatureFlag(h.HandleLogHydration))
	mux.HandleFunc("GET /activities/nutrition/hydration/history", h.withFeatureFlag(h.HandleGetHydrationHistory))

	// Calendar.
	mux.HandleFunc("GET /activities/nutrition/calendar", h.withFeatureFlag(h.HandleGetCalendar))

	// Trends.
	mux.HandleFunc("GET /activities/nutrition/trends", h.withFeatureFlag(h.HandleGetTrends))
	mux.HandleFunc("GET /activities/nutrition/trends/weekly-summary", h.withFeatureFlag(h.HandleGetWeeklySummary))

	// Settings.
	mux.HandleFunc("GET /activities/nutrition/settings", h.withFeatureFlag(h.HandleGetSettings))
	mux.HandleFunc("PATCH /activities/nutrition/settings", h.withFeatureFlag(h.HandleUpdateSettings))
}

// withFeatureFlag wraps a handler with feature flag check.
// FR-NUT-16.1: Returns 404 if activity.nutrition flag is disabled.
func (h *Handler) withFeatureFlag(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if h.flagEnabled != nil && !h.flagEnabled(r.Context(), "activity.nutrition") {
			writeNutritionError(w, http.StatusNotFound, "rr:0x00040404", "Not Found")
			return
		}
		next(w, r)
	}
}

// HandleCreateMealLog handles POST /activities/nutrition/meals.
func (h *Handler) HandleCreateMealLog(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeNutritionError(w, http.StatusUnauthorized, "rr:0x00040401", "Authentication required")
		return
	}
	tenantID := middleware.GetTenantID(r.Context())

	var req CreateMealLogRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeNutritionError(w, http.StatusBadRequest, "rr:0x00040010", "Invalid request body: "+err.Error())
		return
	}

	meal, err := h.mealService.CreateMealLog(r.Context(), userID, tenantID, &req)
	if err != nil {
		writeNutritionServiceError(w, err)
		return
	}

	w.Header().Set("Location", fmt.Sprintf("/v1/activities/nutrition/meals/%s", meal.MealID))
	w.Header().Set("Api-Version", "1.0.0")
	writeNutritionJSON(w, http.StatusCreated, MealLogResponse{
		Data: *meal,
		Meta: map[string]interface{}{"createdAt": meal.CreatedAt.Format(time.RFC3339)},
	})
}

// HandleCreateQuickMealLog handles POST /activities/nutrition/meals/quick.
func (h *Handler) HandleCreateQuickMealLog(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeNutritionError(w, http.StatusUnauthorized, "rr:0x00040401", "Authentication required")
		return
	}
	tenantID := middleware.GetTenantID(r.Context())

	var req CreateQuickMealLogRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeNutritionError(w, http.StatusBadRequest, "rr:0x00040010", "Invalid request body: "+err.Error())
		return
	}

	meal, err := h.mealService.CreateQuickMealLog(r.Context(), userID, tenantID, &req)
	if err != nil {
		writeNutritionServiceError(w, err)
		return
	}

	w.Header().Set("Location", fmt.Sprintf("/v1/activities/nutrition/meals/%s", meal.MealID))
	w.Header().Set("Api-Version", "1.0.0")
	writeNutritionJSON(w, http.StatusCreated, MealLogResponse{
		Data: *meal,
		Meta: map[string]interface{}{"createdAt": meal.CreatedAt.Format(time.RFC3339)},
	})
}

// HandleGetMealLog handles GET /activities/nutrition/meals/{mealId}.
func (h *Handler) HandleGetMealLog(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeNutritionError(w, http.StatusUnauthorized, "rr:0x00040401", "Authentication required")
		return
	}

	mealID := r.PathValue("mealId")
	if mealID == "" {
		writeNutritionError(w, http.StatusBadRequest, "rr:0x00040010", "mealId is required")
		return
	}

	meal, err := h.mealService.GetMealLog(r.Context(), userID, mealID)
	if err != nil {
		writeNutritionServiceError(w, err)
		return
	}

	writeNutritionJSON(w, http.StatusOK, MealLogResponse{Data: *meal})
}

// HandleListMealLogs handles GET /activities/nutrition/meals.
func (h *Handler) HandleListMealLogs(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeNutritionError(w, http.StatusUnauthorized, "rr:0x00040401", "Authentication required")
		return
	}

	q := r.URL.Query()
	filter := MealListFilter{
		Sort:   q.Get("sort"),
		Cursor: q.Get("cursor"),
		Limit:  50,
	}

	if mt := q.Get("mealType"); mt != "" {
		filter.MealType = &mt
	}
	if ec := q.Get("eatingContext"); ec != "" {
		filter.EatingContext = &ec
	}
	if mb := q.Get("moodBefore"); mb != "" {
		filter.MoodBefore = &mb
	}
	if ma := q.Get("moodAfter"); ma != "" {
		filter.MoodAfter = &ma
	}
	if mc := q.Get("mindfulnessCheck"); mc != "" {
		filter.MindfulnessCheck = &mc
	}
	if sd := q.Get("startDate"); sd != "" {
		filter.StartDate = &sd
	}
	if ed := q.Get("endDate"); ed != "" {
		filter.EndDate = &ed
	}
	if s := q.Get("search"); s != "" {
		filter.Search = &s
	}
	if l := q.Get("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil {
			filter.Limit = parsed
		}
	}

	meals, nextCursor, err := h.mealService.ListMealLogs(r.Context(), userID, filter)
	if err != nil {
		writeNutritionServiceError(w, err)
		return
	}

	links := map[string]string{"self": r.URL.String()}
	if nextCursor != "" {
		links["next"] = fmt.Sprintf("/v1/activities/nutrition/meals?cursor=%s&limit=%d", nextCursor, filter.Limit)
	}

	writeNutritionJSON(w, http.StatusOK, MealLogListResponse{
		Data:  meals,
		Links: links,
		Meta: map[string]interface{}{
			"page": map[string]interface{}{
				"nextCursor": nextCursor,
				"limit":      filter.Limit,
			},
		},
	})
}

// HandleUpdateMealLog handles PATCH /activities/nutrition/meals/{mealId}.
func (h *Handler) HandleUpdateMealLog(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeNutritionError(w, http.StatusUnauthorized, "rr:0x00040401", "Authentication required")
		return
	}

	mealID := r.PathValue("mealId")
	if mealID == "" {
		writeNutritionError(w, http.StatusBadRequest, "rr:0x00040010", "mealId is required")
		return
	}

	var req UpdateMealLogRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeNutritionError(w, http.StatusBadRequest, "rr:0x00040010", "Invalid request body: "+err.Error())
		return
	}

	meal, err := h.mealService.UpdateMealLog(r.Context(), userID, mealID, &req)
	if err != nil {
		writeNutritionServiceError(w, err)
		return
	}

	writeNutritionJSON(w, http.StatusOK, MealLogResponse{Data: *meal})
}

// HandleDeleteMealLog handles DELETE /activities/nutrition/meals/{mealId}.
func (h *Handler) HandleDeleteMealLog(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeNutritionError(w, http.StatusUnauthorized, "rr:0x00040401", "Authentication required")
		return
	}

	mealID := r.PathValue("mealId")
	if mealID == "" {
		writeNutritionError(w, http.StatusBadRequest, "rr:0x00040010", "mealId is required")
		return
	}

	if err := h.mealService.DeleteMealLog(r.Context(), userID, mealID); err != nil {
		writeNutritionServiceError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// HandleGetHydrationToday handles GET /activities/nutrition/hydration.
func (h *Handler) HandleGetHydrationToday(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeNutritionError(w, http.StatusUnauthorized, "rr:0x00040401", "Authentication required")
		return
	}

	log, err := h.hydrationService.GetTodayStatus(r.Context(), userID, time.UTC)
	if err != nil {
		writeNutritionServiceError(w, err)
		return
	}

	writeNutritionJSON(w, http.StatusOK, HydrationStatusResponse{
		Data: *log,
		Meta: map[string]interface{}{"retrievedAt": time.Now().UTC().Format(time.RFC3339)},
	})
}

// HandleLogHydration handles POST /activities/nutrition/hydration/log.
func (h *Handler) HandleLogHydration(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeNutritionError(w, http.StatusUnauthorized, "rr:0x00040401", "Authentication required")
		return
	}
	tenantID := middleware.GetTenantID(r.Context())

	var req LogHydrationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeNutritionError(w, http.StatusBadRequest, "rr:0x00040010", "Invalid request body: "+err.Error())
		return
	}

	log, err := h.hydrationService.LogHydration(r.Context(), userID, tenantID, &req, time.UTC)
	if err != nil {
		writeNutritionServiceError(w, err)
		return
	}

	writeNutritionJSON(w, http.StatusOK, HydrationStatusResponse{Data: *log})
}

// HandleGetHydrationHistory handles GET /activities/nutrition/hydration/history.
func (h *Handler) HandleGetHydrationHistory(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeNutritionError(w, http.StatusUnauthorized, "rr:0x00040401", "Authentication required")
		return
	}

	startDate := r.URL.Query().Get("startDate")
	endDate := r.URL.Query().Get("endDate")
	if startDate == "" || endDate == "" {
		writeNutritionError(w, http.StatusBadRequest, "rr:0x00040010", "startDate and endDate are required")
		return
	}

	logs, err := h.hydrationService.GetHydrationHistory(r.Context(), userID, startDate, endDate)
	if err != nil {
		writeNutritionServiceError(w, err)
		return
	}

	// Calculate aggregate metadata.
	var totalOunces float64
	goalMetDays := 0
	for _, l := range logs {
		totalOunces += l.TotalOunces
		if l.GoalMet {
			goalMetDays++
		}
	}
	totalDays := len(logs)
	avgDaily := 0.0
	if totalDays > 0 {
		avgDaily = totalOunces / float64(totalDays)
	}

	writeNutritionJSON(w, http.StatusOK, HydrationHistoryResponse{
		Data: logs,
		Meta: map[string]interface{}{
			"averageDailyOunces": avgDaily,
			"daysGoalMet":        goalMetDays,
			"totalDays":          totalDays,
		},
	})
}

// HandleGetCalendar handles GET /activities/nutrition/calendar.
func (h *Handler) HandleGetCalendar(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeNutritionError(w, http.StatusUnauthorized, "rr:0x00040401", "Authentication required")
		return
	}

	yearStr := r.URL.Query().Get("year")
	monthStr := r.URL.Query().Get("month")
	if yearStr == "" || monthStr == "" {
		writeNutritionError(w, http.StatusBadRequest, "rr:0x00040010", "year and month are required")
		return
	}

	year, err := strconv.Atoi(yearStr)
	if err != nil {
		writeNutritionError(w, http.StatusBadRequest, "rr:0x00040010", "invalid year")
		return
	}
	month, err := strconv.Atoi(monthStr)
	if err != nil || month < 1 || month > 12 {
		writeNutritionError(w, http.StatusBadRequest, "rr:0x00040010", "invalid month")
		return
	}

	// Build date range for the month.
	startDate := fmt.Sprintf("%04d-%02d-01", year, month)
	lastDay := time.Date(year, time.Month(month)+1, 0, 0, 0, 0, 0, time.UTC).Day()
	endDate := fmt.Sprintf("%04d-%02d-%02d", year, month, lastDay)

	// Get meals and hydration for the month.
	meals, err := h.mealService.mealRepo.GetMealsInDateRange(r.Context(), userID, startDate, endDate)
	if err != nil {
		writeNutritionServiceError(w, err)
		return
	}

	hydrationLogs, err := h.hydrationService.GetHydrationHistory(r.Context(), userID, startDate, endDate)
	if err != nil {
		writeNutritionServiceError(w, err)
		return
	}

	// Build hydration map.
	hydrationMap := make(map[string]*HydrationLog)
	for i := range hydrationLogs {
		hydrationMap[hydrationLogs[i].Date] = &hydrationLogs[i]
	}

	// Group meals by date.
	mealsByDate := make(map[string][]MealLog)
	for _, meal := range meals {
		date := meal.Timestamp.Format("2006-01-02")
		mealsByDate[date] = append(mealsByDate[date], meal)
	}

	// Build calendar days.
	var days []NutritionCalendarDay
	for day := 1; day <= lastDay; day++ {
		date := fmt.Sprintf("%04d-%02d-%02d", year, month, day)
		dayMeals := mealsByDate[date]
		mealsLogged := len(dayMeals)

		// Collect distinct meal types.
		typeSet := make(map[MealType]bool)
		for _, m := range dayMeals {
			typeSet[m.MealType] = true
		}
		mealTypes := make([]MealType, 0, len(typeSet))
		for mt := range typeSet {
			mealTypes = append(mealTypes, mt)
		}

		hydrationGoalMet := false
		hydrationProgress := 0
		if h, ok := hydrationMap[date]; ok {
			hydrationGoalMet = h.GoalMet
			hydrationProgress = h.GoalProgressPercent
		}

		days = append(days, NutritionCalendarDay{
			Date:             date,
			MealsLogged:      mealsLogged,
			MealTypes:        mealTypes,
			HydrationGoalMet: hydrationGoalMet,
			Completeness:     CalculateCompleteness(mealsLogged, hydrationGoalMet, hydrationProgress),
		})
	}

	resp := NutritionCalendarResponse{}
	resp.Data.Year = year
	resp.Data.Month = month
	resp.Data.Days = days
	resp.Meta = map[string]interface{}{"retrievedAt": time.Now().UTC().Format(time.RFC3339)}

	writeNutritionJSON(w, http.StatusOK, resp)
}

// HandleGetTrends handles GET /activities/nutrition/trends.
func (h *Handler) HandleGetTrends(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeNutritionError(w, http.StatusUnauthorized, "rr:0x00040401", "Authentication required")
		return
	}

	period := r.URL.Query().Get("period")
	if period != "7d" && period != "30d" && period != "90d" {
		writeNutritionError(w, http.StatusBadRequest, "rr:0x00040010", "period must be 7d, 30d, or 90d")
		return
	}

	// Calculate date range.
	var days int
	switch period {
	case "7d":
		days = 7
	case "30d":
		days = 30
	case "90d":
		days = 90
	}

	endDate := time.Now().UTC().Format("2006-01-02")
	startDate := time.Now().UTC().AddDate(0, 0, -days).Format("2006-01-02")

	meals, err := h.mealService.mealRepo.GetMealsInDateRange(r.Context(), userID, startDate, endDate)
	if err != nil {
		writeNutritionServiceError(w, err)
		return
	}

	hydrationLogs, err := h.hydrationService.GetHydrationHistory(r.Context(), userID, startDate, endDate)
	if err != nil {
		writeNutritionServiceError(w, err)
		return
	}

	settings, _ := h.settingsService.GetSettings(r.Context(), userID)

	trendsData := NutritionTrendsData{
		Period:          period,
		MealConsistency: CalculateMealConsistency(meals, startDate, endDate),
		EmotionalEating: CalculateEmotionalEatingTrend(meals),
		Mindfulness:     CalculateMindfulnessTrend(meals, nil),
		Insights:        GenerateInsights(meals, hydrationLogs, days, settings),
	}

	// Eating context distribution.
	contextDist := make(map[string]int)
	socialCount := 0
	for _, meal := range meals {
		if meal.EatingContext != nil {
			contextDist[string(*meal.EatingContext)]++
			if *meal.EatingContext == EatingContextSocial {
				socialCount++
			}
		}
	}
	totalContexted := 0
	for _, v := range contextDist {
		totalContexted += v
	}
	pctDist := make(map[string]float64)
	if totalContexted > 0 {
		for k, v := range contextDist {
			pctDist[k] = float64(v) / float64(totalContexted) * 100
		}
	}
	trendsData.EatingContext = &EatingContextTrend{
		Distribution:      pctDist,
		SocialEatingCount: socialCount,
	}

	// Hydration trend.
	var totalOz float64
	goalMetDays := 0
	dailyIntake := make([]DailyHydration, 0, len(hydrationLogs))
	for _, l := range hydrationLogs {
		totalOz += l.TotalOunces
		if l.GoalMet {
			goalMetDays++
		}
		dailyIntake = append(dailyIntake, DailyHydration{
			Date:        l.Date,
			TotalOunces: l.TotalOunces,
			GoalMet:     l.GoalMet,
		})
	}
	avgOz := 0.0
	if days > 0 {
		avgOz = totalOz / float64(days)
	}
	trendsData.Hydration = &HydrationTrend{
		AverageDailyOunces: avgOz,
		DaysGoalMet:        goalMetDays,
		TotalDays:          days,
		DailyIntake:        dailyIntake,
	}

	writeNutritionJSON(w, http.StatusOK, NutritionTrendsResponse{
		Data: trendsData,
		Meta: map[string]interface{}{"retrievedAt": time.Now().UTC().Format(time.RFC3339)},
	})
}

// HandleGetWeeklySummary handles GET /activities/nutrition/trends/weekly-summary.
func (h *Handler) HandleGetWeeklySummary(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeNutritionError(w, http.StatusUnauthorized, "rr:0x00040401", "Authentication required")
		return
	}

	now := time.Now().UTC()
	// Current week: Monday to Sunday.
	weekday := int(now.Weekday())
	if weekday == 0 {
		weekday = 7
	}
	currentWeekStart := now.AddDate(0, 0, -(weekday - 1))
	currentWeekEnd := currentWeekStart.AddDate(0, 0, 6)
	prevWeekStart := currentWeekStart.AddDate(0, 0, -7)
	prevWeekEnd := currentWeekStart.AddDate(0, 0, -1)

	currentMeals, _ := h.mealService.mealRepo.GetMealsInDateRange(r.Context(), userID,
		currentWeekStart.Format("2006-01-02"), currentWeekEnd.Format("2006-01-02"))
	prevMeals, _ := h.mealService.mealRepo.GetMealsInDateRange(r.Context(), userID,
		prevWeekStart.Format("2006-01-02"), prevWeekEnd.Format("2006-01-02"))

	currentHydration, _ := h.hydrationService.GetHydrationHistory(r.Context(), userID,
		currentWeekStart.Format("2006-01-02"), currentWeekEnd.Format("2006-01-02"))
	prevHydration, _ := h.hydrationService.GetHydrationHistory(r.Context(), userID,
		prevWeekStart.Format("2006-01-02"), prevWeekEnd.Format("2006-01-02"))

	currentSummary := buildWeekSummary(currentMeals, currentHydration)
	prevSummary := buildWeekSummary(prevMeals, prevHydration)

	delta := currentSummary.MealsLogged - prevSummary.MealsLogged
	hydrationDelta := currentSummary.HydrationGoalMetDays - prevSummary.HydrationGoalMetDays
	direction := TrendDirectionStable
	if delta > 2 || hydrationDelta > 1 {
		direction = TrendDirectionImproving
	} else if delta < -2 || hydrationDelta < -1 {
		direction = TrendDirectionDeclining
	}

	writeNutritionJSON(w, http.StatusOK, WeeklySummaryResponse{
		Data: WeeklySummaryData{
			CurrentWeek:  currentSummary,
			PreviousWeek: prevSummary,
			Comparison: WeeklyComparison{
				MealsLoggedDelta: delta,
				HydrationDelta:   hydrationDelta,
				Direction:        direction,
			},
		},
		Meta: map[string]interface{}{
			"weekStartDate": currentWeekStart.Format("2006-01-02"),
			"weekEndDate":   currentWeekEnd.Format("2006-01-02"),
		},
	})
}

func buildWeekSummary(meals []MealLog, hydration []HydrationLog) WeekSummary {
	goalMetDays := 0
	for _, h := range hydration {
		if h.GoalMet {
			goalMetDays++
		}
	}

	// Most common context.
	contextCounts := make(map[string]int)
	mindfulCount := 0
	mindfulTotal := 0
	for _, meal := range meals {
		if meal.EatingContext != nil {
			contextCounts[string(*meal.EatingContext)]++
		}
		if meal.MindfulnessCheck != nil {
			mindfulTotal++
			if *meal.MindfulnessCheck == MindfulnessYes {
				mindfulCount++
			}
		}
	}

	var topContext *string
	maxCount := 0
	for ctx, count := range contextCounts {
		if count > maxCount {
			maxCount = count
			c := ctx
			topContext = &c
		}
	}

	mindfulPct := 0.0
	if mindfulTotal > 0 {
		mindfulPct = float64(mindfulCount) / float64(mindfulTotal) * 100
	}

	avgMeals := 0.0
	if len(meals) > 0 {
		avgMeals = float64(len(meals)) / 7.0
	}

	return WeekSummary{
		MealsLogged:          len(meals),
		AverageMealsPerDay:   avgMeals,
		HydrationGoalMetDays: goalMetDays,
		MostCommonContext:    topContext,
		MindfulMealPercent:   mindfulPct,
	}
}

// HandleGetSettings handles GET /activities/nutrition/settings.
func (h *Handler) HandleGetSettings(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeNutritionError(w, http.StatusUnauthorized, "rr:0x00040401", "Authentication required")
		return
	}

	settings, err := h.settingsService.GetSettings(r.Context(), userID)
	if err != nil {
		writeNutritionServiceError(w, err)
		return
	}

	writeNutritionJSON(w, http.StatusOK, NutritionSettingsResponse{Data: *settings})
}

// HandleUpdateSettings handles PATCH /activities/nutrition/settings.
func (h *Handler) HandleUpdateSettings(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		writeNutritionError(w, http.StatusUnauthorized, "rr:0x00040401", "Authentication required")
		return
	}

	var patch map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&patch); err != nil {
		writeNutritionError(w, http.StatusBadRequest, "rr:0x00040010", "Invalid request body: "+err.Error())
		return
	}

	settings, err := h.settingsService.UpdateSettings(r.Context(), userID, patch)
	if err != nil {
		writeNutritionServiceError(w, err)
		return
	}

	writeNutritionJSON(w, http.StatusOK, NutritionSettingsResponse{Data: *settings})
}

// --- Response helpers ---

type nutritionErrorResponse struct {
	Errors []nutritionAPIError `json:"errors"`
}

type nutritionAPIError struct {
	Code    string `json:"code"`
	Status  int    `json:"status"`
	Title   string `json:"title"`
	Detail  string `json:"detail,omitempty"`
}

func writeNutritionJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

func writeNutritionError(w http.ResponseWriter, status int, code string, message string) {
	writeNutritionJSON(w, status, nutritionErrorResponse{
		Errors: []nutritionAPIError{{
			Code:   code,
			Status: status,
			Title:  message,
		}},
	})
}

func writeNutritionServiceError(w http.ResponseWriter, err error) {
	var ve *ValidationError
	if errors.As(err, &ve) {
		writeNutritionError(w, http.StatusUnprocessableEntity, ve.Code, ve.Message)
		return
	}

	if errors.Is(err, ErrMealNotFound) {
		writeNutritionError(w, http.StatusNotFound, "rr:0x00040404", "Meal log not found")
		return
	}

	writeNutritionError(w, http.StatusInternalServerError, "rr:0x00040500", "Internal server error")
}
