// internal/domain/nutrition/meal.go
package nutrition

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// MealRepository defines the interface for meal log data access.
type MealRepository interface {
	CreateMealLog(ctx context.Context, meal *MealLog) error
	GetMealLog(ctx context.Context, userID, mealID string) (*MealLog, error)
	ListMealLogs(ctx context.Context, userID string, filter MealListFilter) ([]MealLog, string, error)
	UpdateMealLog(ctx context.Context, meal *MealLog) error
	DeleteMealLog(ctx context.Context, userID, mealID string) error
	CountMealsForDate(ctx context.Context, userID, date string) (int, error)
	GetMealsInDateRange(ctx context.Context, userID, startDate, endDate string) ([]MealLog, error)
}

// CalendarRepository defines the interface for calendar dual-write.
type CalendarRepository interface {
	CreateCalendarActivity(ctx context.Context, activity *CalendarActivity) error
	DeleteCalendarActivity(ctx context.Context, userID, sourceKey string) error
	GetCalendarActivities(ctx context.Context, userID string, year, month int) ([]CalendarActivity, error)
}

// MealService handles meal log business logic.
type MealService struct {
	mealRepo     MealRepository
	calendarRepo CalendarRepository
}

// NewMealService creates a new MealService.
func NewMealService(mealRepo MealRepository, calendarRepo CalendarRepository) *MealService {
	return &MealService{
		mealRepo:     mealRepo,
		calendarRepo: calendarRepo,
	}
}

// CreateMealLog creates a new meal log entry.
// FR-NUT-1.5: Timestamp defaults to now if omitted.
// FR-NUT-1.6: Past timestamps are accepted for backdating.
// FR-NUT-1.15: Calendar activity dual-write.
func (s *MealService) CreateMealLog(ctx context.Context, userID, tenantID string, req *CreateMealLogRequest) (*MealLog, error) {
	if err := ValidateCreateMealLog(req); err != nil {
		return nil, err
	}

	now := time.Now().UTC()
	timestamp := now
	if req.Timestamp != nil {
		timestamp = *req.Timestamp
	}

	mealID := fmt.Sprintf("ml_%s", uuid.New().String()[:8])
	desc := req.Description

	meal := &MealLog{
		MealID:           mealID,
		UserID:           userID,
		TenantID:         tenantID,
		Timestamp:        timestamp,
		MealType:         req.MealType,
		CustomMealLabel:  req.CustomMealLabel,
		Description:      &desc,
		EatingContext:    req.EatingContext,
		MoodBefore:       req.MoodBefore,
		MoodAfter:        req.MoodAfter,
		MindfulnessCheck: req.MindfulnessCheck,
		Notes:            req.Notes,
		IsQuickLog:       false,
		CreatedAt:        now,
		ModifiedAt:       now,
	}

	if err := s.mealRepo.CreateMealLog(ctx, meal); err != nil {
		return nil, fmt.Errorf("creating meal log: %w", err)
	}

	// FR-NUT-1.15: Calendar activity dual-write.
	calActivity := &CalendarActivity{
		UserID:       userID,
		Date:         timestamp.Format("2006-01-02"),
		ActivityType: "NUTRITION",
		SourceKey:    fmt.Sprintf("MEAL#%s", timestamp.Format(time.RFC3339)),
	}
	calActivity.Summary.MealType = req.MealType
	calActivity.Summary.MealID = mealID
	calActivity.Summary.HasDescription = true

	if err := s.calendarRepo.CreateCalendarActivity(ctx, calActivity); err != nil {
		// Log but don't fail the meal creation.
		_ = err
	}

	meal.Links = map[string]string{
		"self": fmt.Sprintf("/v1/activities/nutrition/meals/%s", mealID),
	}

	return meal, nil
}

// CreateQuickMealLog creates a one-tap meal log.
// FR-NUT-2.1: Only requires meal type. Timestamp is set to now.
func (s *MealService) CreateQuickMealLog(ctx context.Context, userID, tenantID string, req *CreateQuickMealLogRequest) (*MealLog, error) {
	if err := ValidateQuickMealLog(req); err != nil {
		return nil, err
	}

	now := time.Now().UTC()
	mealID := fmt.Sprintf("ml_%s", uuid.New().String()[:8])

	meal := &MealLog{
		MealID:          mealID,
		UserID:          userID,
		TenantID:        tenantID,
		Timestamp:       now,
		MealType:        req.MealType,
		CustomMealLabel: req.CustomMealLabel,
		Description:     nil, // Null for quick logs
		IsQuickLog:      true,
		CreatedAt:       now,
		ModifiedAt:      now,
	}

	if err := s.mealRepo.CreateMealLog(ctx, meal); err != nil {
		return nil, fmt.Errorf("creating quick meal log: %w", err)
	}

	// Calendar dual-write for quick logs too.
	calActivity := &CalendarActivity{
		UserID:       userID,
		Date:         now.Format("2006-01-02"),
		ActivityType: "NUTRITION",
		SourceKey:    fmt.Sprintf("MEAL#%s", now.Format(time.RFC3339)),
	}
	calActivity.Summary.MealType = req.MealType
	calActivity.Summary.MealID = mealID
	calActivity.Summary.HasDescription = false

	_ = s.calendarRepo.CreateCalendarActivity(ctx, calActivity)

	meal.Links = map[string]string{
		"self": fmt.Sprintf("/v1/activities/nutrition/meals/%s", mealID),
	}

	return meal, nil
}

// GetMealLog retrieves a meal log by ID.
func (s *MealService) GetMealLog(ctx context.Context, userID, mealID string) (*MealLog, error) {
	meal, err := s.mealRepo.GetMealLog(ctx, userID, mealID)
	if err != nil {
		return nil, fmt.Errorf("getting meal log: %w", err)
	}
	if meal == nil {
		return nil, ErrMealNotFound
	}

	meal.Links = map[string]string{
		"self": fmt.Sprintf("/v1/activities/nutrition/meals/%s", mealID),
	}

	return meal, nil
}

// ListMealLogs retrieves meal logs with filtering.
func (s *MealService) ListMealLogs(ctx context.Context, userID string, filter MealListFilter) ([]MealLog, string, error) {
	if filter.Limit <= 0 {
		filter.Limit = 50
	}
	if filter.Limit > 100 {
		filter.Limit = 100
	}
	if filter.Sort == "" {
		filter.Sort = "-timestamp"
	}

	meals, nextCursor, err := s.mealRepo.ListMealLogs(ctx, userID, filter)
	if err != nil {
		return nil, "", fmt.Errorf("listing meal logs: %w", err)
	}

	for i := range meals {
		meals[i].Links = map[string]string{
			"self": fmt.Sprintf("/v1/activities/nutrition/meals/%s", meals[i].MealID),
		}
	}

	return meals, nextCursor, nil
}

// UpdateMealLog updates a meal log entry.
// FR-NUT-1.14: Timestamp is immutable.
// FR-NUT-2.2: Quick log fields can be expanded.
func (s *MealService) UpdateMealLog(ctx context.Context, userID, mealID string, req *UpdateMealLogRequest) (*MealLog, error) {
	if err := ValidateUpdateMealLog(req); err != nil {
		return nil, err
	}

	meal, err := s.mealRepo.GetMealLog(ctx, userID, mealID)
	if err != nil {
		return nil, fmt.Errorf("getting meal log for update: %w", err)
	}
	if meal == nil {
		return nil, ErrMealNotFound
	}

	// Apply merge patch fields.
	if req.Description != nil {
		meal.Description = req.Description
	}
	if req.EatingContext != nil {
		meal.EatingContext = req.EatingContext
	}
	if req.MoodBefore != nil {
		meal.MoodBefore = req.MoodBefore
	}
	if req.MoodAfter != nil {
		meal.MoodAfter = req.MoodAfter
	}
	if req.MindfulnessCheck != nil {
		meal.MindfulnessCheck = req.MindfulnessCheck
	}
	if req.Notes != nil {
		meal.Notes = req.Notes
	}

	meal.ModifiedAt = time.Now().UTC()

	if err := s.mealRepo.UpdateMealLog(ctx, meal); err != nil {
		return nil, fmt.Errorf("updating meal log: %w", err)
	}

	meal.Links = map[string]string{
		"self": fmt.Sprintf("/v1/activities/nutrition/meals/%s", mealID),
	}

	return meal, nil
}

// DeleteMealLog deletes a meal log and its calendar activity.
func (s *MealService) DeleteMealLog(ctx context.Context, userID, mealID string) error {
	meal, err := s.mealRepo.GetMealLog(ctx, userID, mealID)
	if err != nil {
		return fmt.Errorf("getting meal log for deletion: %w", err)
	}
	if meal == nil {
		return ErrMealNotFound
	}

	if err := s.mealRepo.DeleteMealLog(ctx, userID, mealID); err != nil {
		return fmt.Errorf("deleting meal log: %w", err)
	}

	// Delete corresponding calendar activity.
	sourceKey := fmt.Sprintf("MEAL#%s", meal.Timestamp.Format(time.RFC3339))
	_ = s.calendarRepo.DeleteCalendarActivity(ctx, userID, sourceKey)

	return nil
}
