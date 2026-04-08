// internal/domain/goals/service.go
package goals

import (
	"context"
	"errors"
	"fmt"
	"time"
)

var (
	// ErrGoalNotFound indicates the goal definition does not exist.
	ErrGoalNotFound = errors.New("goal not found")

	// ErrInstanceNotFound indicates the goal instance does not exist.
	ErrInstanceNotFound = errors.New("goal instance not found")

	// ErrReviewAlreadySubmitted indicates a review was already submitted for this date.
	ErrReviewAlreadySubmitted = errors.New("review already submitted for this date")

	// ErrPermissionDenied indicates the user does not have permission.
	ErrPermissionDenied = errors.New("permission denied")

	// ErrFeatureDisabled indicates the feature flag is off.
	ErrFeatureDisabled = errors.New("feature disabled")
)

// Service contains business logic for the weekly/daily goals feature.
type Service struct {
	repo              GoalRepository
	permissionChecker PermissionChecker
}

// NewService creates a new goals service.
func NewService(repo GoalRepository, permChecker PermissionChecker) *Service {
	return &Service{
		repo:              repo,
		permissionChecker: permChecker,
	}
}

// CreateGoal creates a new goal definition (AC-GC-1).
func (s *Service) CreateGoal(ctx context.Context, userID, tenantID string, req *CreateWeeklyDailyGoalRequest) (*WeeklyDailyGoal, error) {
	if err := ValidateCreateGoalRequest(req); err != nil {
		return nil, err
	}

	now := time.Now().UTC()

	// AC-GC-4: default scope to daily.
	scope := ScopeDaily
	if req.Scope != nil {
		scope = *req.Scope
	}

	recurrence := RecurrenceOneTime
	if req.Recurrence != nil {
		recurrence = *req.Recurrence
	}

	priority := PriorityMedium
	if req.Priority != nil {
		priority = *req.Priority
	}

	goal := &WeeklyDailyGoal{
		GoalID:     generateGoalID(),
		UserID:     userID,
		TenantID:   tenantID,
		Text:       req.Text,
		Dynamics:   req.Dynamics,
		Scope:      scope,
		Recurrence: recurrence,
		DaysOfWeek: req.DaysOfWeek,
		DayOfWeek:  req.DayOfWeek,
		Priority:   priority,
		Notes:      req.Notes,
		IsActive:   true,
		CreatedAt:  now,
		ModifiedAt: now,
	}

	if err := s.repo.CreateGoal(ctx, userID, goal); err != nil {
		return nil, fmt.Errorf("creating goal: %w", err)
	}

	return goal, nil
}

// GetGoal retrieves a goal definition.
func (s *Service) GetGoal(ctx context.Context, userID, goalID string) (*WeeklyDailyGoal, error) {
	goal, err := s.repo.GetGoal(ctx, userID, goalID)
	if err != nil {
		return nil, fmt.Errorf("retrieving goal: %w", err)
	}
	if goal == nil {
		return nil, ErrGoalNotFound
	}
	return goal, nil
}

// ListGoals lists goal definitions with optional filters.
func (s *Service) ListGoals(ctx context.Context, userID string, scope *GoalScope, dynamic *Dynamic, isActive *bool, cursor string, limit int) ([]WeeklyDailyGoal, string, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}
	return s.repo.ListGoals(ctx, userID, scope, dynamic, isActive, cursor, limit)
}

// UpdateGoal updates a goal definition.
func (s *Service) UpdateGoal(ctx context.Context, userID, goalID string, req *UpdateWeeklyDailyGoalRequest) (*WeeklyDailyGoal, error) {
	if err := ValidateUpdateGoalRequest(req); err != nil {
		return nil, err
	}
	return s.repo.UpdateGoal(ctx, userID, goalID, req)
}

// DeleteGoal deactivates a goal definition (AC-EC-2).
func (s *Service) DeleteGoal(ctx context.Context, userID, goalID string) error {
	isActive := false
	_, err := s.repo.UpdateGoal(ctx, userID, goalID, &UpdateWeeklyDailyGoalRequest{
		IsActive: &isActive,
	})
	return err
}

// GetDailyGoals retrieves all goals for a specific day (AC-DV-1 through AC-DV-3, AC-DN-1).
func (s *Service) GetDailyGoals(ctx context.Context, userID, date string) ([]GoalInstance, DynamicBalance, []DynamicNudge, error) {
	if date == "" {
		date = time.Now().UTC().Format("2006-01-02")
	}

	instances, err := s.repo.GetDailyInstances(ctx, userID, date)
	if err != nil {
		return nil, DynamicBalance{}, nil, fmt.Errorf("retrieving daily instances: %w", err)
	}

	SortInstancesByPriority(instances)
	balance := ComputeDynamicBalance(instances)

	// Generate nudges.
	settings, _ := s.repo.GetGoalSettings(ctx, userID)
	dismissed, _ := s.repo.GetDismissedNudges(ctx, userID, date)
	nudges := GenerateNudges(instances, settings, dismissed)

	return instances, balance, nudges, nil
}

// GetWeeklyGoals retrieves all goals for a specific week (AC-WV-1 through AC-WV-3).
func (s *Service) GetWeeklyGoals(ctx context.Context, userID, weekOf string) ([]GoalInstance, string, string, int, int, float64, DynamicBalance, error) {
	if weekOf == "" {
		weekOf = time.Now().UTC().Format("2006-01-02")
	}

	t, err := time.Parse("2006-01-02", weekOf)
	if err != nil {
		return nil, "", "", 0, 0, 0, DynamicBalance{}, fmt.Errorf("invalid weekOf date: %w", err)
	}

	weekStart := WeekStartDate(t).Format("2006-01-02")
	weekEnd := WeekEndDate(t).Format("2006-01-02")

	instances, err := s.repo.GetWeeklyInstances(ctx, userID, weekStart, weekEnd)
	if err != nil {
		return nil, "", "", 0, 0, 0, DynamicBalance{}, fmt.Errorf("retrieving weekly instances: %w", err)
	}

	total, completed, rate := ComputeWeeklySummary(instances)
	balance := ComputeDynamicBalance(instances)

	return instances, weekStart, weekEnd, total, completed, rate, balance, nil
}

// CompleteGoalInstance marks a goal instance as completed (AC-DV-4).
func (s *Service) CompleteGoalInstance(ctx context.Context, userID, goalInstanceID string) (*GoalInstance, error) {
	instance, err := s.repo.GetInstance(ctx, userID, goalInstanceID)
	if err != nil {
		return nil, fmt.Errorf("retrieving instance: %w", err)
	}
	if instance == nil {
		return nil, ErrInstanceNotFound
	}

	CompleteInstance(instance)

	completedAt := instance.CompletedAt.Format(time.RFC3339)
	if err := s.repo.UpdateInstanceStatus(ctx, userID, goalInstanceID, StatusCompleted, &completedAt); err != nil {
		return nil, fmt.Errorf("updating instance status: %w", err)
	}

	// Calendar dual-write.
	_ = s.repo.WriteCalendarActivity(ctx, userID, instance.Date, instance)

	return instance, nil
}

// UncompleteGoalInstance reverts a goal instance to pending (AC-DV-5).
func (s *Service) UncompleteGoalInstance(ctx context.Context, userID, goalInstanceID string) (*GoalInstance, error) {
	instance, err := s.repo.GetInstance(ctx, userID, goalInstanceID)
	if err != nil {
		return nil, fmt.Errorf("retrieving instance: %w", err)
	}
	if instance == nil {
		return nil, ErrInstanceNotFound
	}

	UncompleteInstance(instance)

	if err := s.repo.UpdateInstanceStatus(ctx, userID, goalInstanceID, StatusPending, nil); err != nil {
		return nil, fmt.Errorf("updating instance status: %w", err)
	}

	return instance, nil
}

// DismissGoalInstance dismisses an auto-populated goal for the day (AC-AP-4).
func (s *Service) DismissGoalInstance(ctx context.Context, userID, goalInstanceID string) (*GoalInstance, error) {
	instance, err := s.repo.GetInstance(ctx, userID, goalInstanceID)
	if err != nil {
		return nil, fmt.Errorf("retrieving instance: %w", err)
	}
	if instance == nil {
		return nil, ErrInstanceNotFound
	}

	DismissInstance(instance)

	if err := s.repo.UpdateInstanceStatus(ctx, userID, goalInstanceID, StatusDismissed, nil); err != nil {
		return nil, fmt.Errorf("updating instance status: %w", err)
	}

	return instance, nil
}

// DismissDynamicNudge dismisses a nudge for a dynamic for the day (AC-DN-2).
func (s *Service) DismissDynamicNudge(ctx context.Context, userID, date string, dynamic string) error {
	return s.repo.DismissNudge(ctx, userID, date, dynamic)
}

// GetDailyReview retrieves end-of-day review data (AC-ED-2).
func (s *Service) GetDailyReview(ctx context.Context, userID, date string) ([]GoalInstance, DynamicBalance, bool, error) {
	if date == "" {
		date = time.Now().UTC().Format("2006-01-02")
	}

	instances, err := s.repo.GetDailyInstances(ctx, userID, date)
	if err != nil {
		return nil, DynamicBalance{}, false, err
	}

	balance := ComputeDynamicBalance(instances)

	existingReview, _ := s.repo.GetDailyReview(ctx, userID, date)
	previousReviewSubmitted := existingReview != nil

	return instances, balance, previousReviewSubmitted, nil
}

// SubmitDailyReview processes the end-of-day review (AC-ED-2 through AC-ED-5).
func (s *Service) SubmitDailyReview(ctx context.Context, userID, tenantID string, req *SubmitDailyReviewRequest) (*GoalReview, error) {
	instances, err := s.repo.GetDailyInstances(ctx, userID, req.Date)
	if err != nil {
		return nil, fmt.Errorf("retrieving daily instances: %w", err)
	}

	review, carriedInstances, err := ProcessDailyReview(instances, req, userID, tenantID)
	if err != nil {
		return nil, err
	}

	// Persist review.
	if err := s.repo.CreateDailyReview(ctx, userID, review); err != nil {
		return nil, fmt.Errorf("creating daily review: %w", err)
	}

	// Create carried instances for tomorrow.
	if len(carriedInstances) > 0 {
		if err := s.repo.BatchCreateInstances(ctx, userID, carriedInstances); err != nil {
			return nil, fmt.Errorf("creating carried instances: %w", err)
		}
	}

	return review, nil
}

// GetWeeklyReview retrieves end-of-week review data (AC-EW-2).
func (s *Service) GetWeeklyReview(ctx context.Context, userID, weekOf string) (*WeeklyStats, []string, bool, error) {
	if weekOf == "" {
		weekOf = time.Now().UTC().Format("2006-01-02")
	}

	t, err := time.Parse("2006-01-02", weekOf)
	if err != nil {
		return nil, nil, false, err
	}

	weekStart := WeekStartDate(t).Format("2006-01-02")
	weekEnd := WeekEndDate(t).Format("2006-01-02")
	prevWeekStart := WeekStartDate(t.AddDate(0, 0, -7)).Format("2006-01-02")
	prevWeekEnd := WeekEndDate(t.AddDate(0, 0, -7)).Format("2006-01-02")

	currentInstances, err := s.repo.GetWeeklyInstances(ctx, userID, weekStart, weekEnd)
	if err != nil {
		return nil, nil, false, err
	}

	prevInstances, _ := s.repo.GetWeeklyInstances(ctx, userID, prevWeekStart, prevWeekEnd)

	stats := ComputeWeeklyStats(currentInstances, prevInstances)
	prompts := WeeklyReflectionPrompts()

	existingReview, _ := s.repo.GetWeeklyReview(ctx, userID, weekStart)
	previousReviewSubmitted := existingReview != nil

	return stats, prompts, previousReviewSubmitted, nil
}

// SubmitWeeklyReview processes the end-of-week review (AC-EW-2, AC-EW-4).
func (s *Service) SubmitWeeklyReview(ctx context.Context, userID, tenantID string, req *SubmitWeeklyReviewRequest) (*GoalReview, error) {
	t, err := time.Parse("2006-01-02", req.WeekOf)
	if err != nil {
		return nil, fmt.Errorf("invalid weekOf date: %w", err)
	}

	weekStart := WeekStartDate(t).Format("2006-01-02")
	weekEnd := WeekEndDate(t).Format("2006-01-02")
	prevWeekStart := WeekStartDate(t.AddDate(0, 0, -7)).Format("2006-01-02")
	prevWeekEnd := WeekEndDate(t.AddDate(0, 0, -7)).Format("2006-01-02")

	currentInstances, err := s.repo.GetWeeklyInstances(ctx, userID, weekStart, weekEnd)
	if err != nil {
		return nil, err
	}
	prevInstances, _ := s.repo.GetWeeklyInstances(ctx, userID, prevWeekStart, prevWeekEnd)

	stats := ComputeWeeklyStats(currentInstances, prevInstances)

	review := &GoalReview{
		ReviewID:    generateReviewID(),
		UserID:      userID,
		TenantID:    tenantID,
		Type:        "weekly",
		Date:        weekStart,
		Reflections: req.Reflections,
		Stats:       stats,
		CreatedAt:   time.Now().UTC(),
	}

	if err := s.repo.CreateWeeklyReview(ctx, userID, review); err != nil {
		return nil, fmt.Errorf("creating weekly review: %w", err)
	}

	return review, nil
}

// GetGoalTrends computes goal trends over a period (AC-TI-1 through AC-TI-4).
func (s *Service) GetGoalTrends(ctx context.Context, userID, period string, dynamic *Dynamic) (*GoalTrends, error) {
	days := 30
	switch period {
	case "7d":
		days = 7
	case "90d":
		days = 90
	default:
		period = "30d"
	}

	endDate := time.Now().UTC().Format("2006-01-02")
	startDate := time.Now().UTC().AddDate(0, 0, -days).Format("2006-01-02")

	var dynamicFilter *Dynamic
	var statusFilter *GoalInstanceStatus
	if dynamic != nil {
		dynamicFilter = dynamic
	}

	instances, _, _, err := s.repo.GetInstancesByDateRange(ctx, userID, startDate, endDate, dynamicFilter, statusFilter, "", "", days*20)
	if err != nil {
		return nil, fmt.Errorf("retrieving instances for trends: %w", err)
	}

	trends := ComputeTrends(instances, period)
	return trends, nil
}

// GetGoalHistory retrieves paginated goal history with filters (AC-HI-1 through AC-HI-3).
func (s *Service) GetGoalHistory(ctx context.Context, userID string, startDate, endDate string, dynamic *Dynamic, status *GoalInstanceStatus, search, cursor string, limit int) ([]GoalInstance, string, int, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}
	return s.repo.GetInstancesByDateRange(ctx, userID, startDate, endDate, dynamic, status, search, cursor, limit)
}

// GetGoalSettings retrieves goal settings.
func (s *Service) GetGoalSettings(ctx context.Context, userID string) (*GoalSettings, error) {
	settings, err := s.repo.GetGoalSettings(ctx, userID)
	if err != nil {
		return nil, err
	}
	if settings == nil {
		return DefaultGoalSettings(userID), nil
	}
	return settings, nil
}

// UpdateGoalSettings updates goal settings.
func (s *Service) UpdateGoalSettings(ctx context.Context, userID string, req *UpdateGoalSettingsRequest) (*GoalSettings, error) {
	return s.repo.UpdateGoalSettings(ctx, userID, req)
}

// GetUserGoalSummary retrieves a user's goal summary for the support network (AC-IP-3).
func (s *Service) GetUserGoalSummary(ctx context.Context, requestingUserID, targetUserID, period string) (*UserGoalSummary, error) {
	// Check permission.
	if s.permissionChecker != nil {
		allowed, err := CheckSponsorViewPermission(s.permissionChecker, requestingUserID, targetUserID)
		if err != nil {
			return nil, fmt.Errorf("checking permission: %w", err)
		}
		if !allowed {
			return nil, ErrPermissionDenied
		}
	}

	days := 30
	switch period {
	case "7d":
		days = 7
	case "90d":
		days = 90
	}

	endDate := time.Now().UTC().Format("2006-01-02")
	startDate := time.Now().UTC().AddDate(0, 0, -days).Format("2006-01-02")

	instances, _, _, err := s.repo.GetInstancesByDateRange(ctx, targetUserID, startDate, endDate, nil, nil, "", "", days*20)
	if err != nil {
		return nil, err
	}

	total, completed, rate := ComputeWeeklySummary(instances)
	_ = total
	_ = completed
	balance := ComputeDynamicBalance(instances)
	strongest, weakest := FindStrongestWeakest(instances)

	dateInstances := make(map[string][]GoalInstance)
	for _, inst := range instances {
		dateInstances[inst.Date] = append(dateInstances[inst.Date], inst)
	}
	consistencyScore := ComputeConsistencyScore(dateInstances)

	return &UserGoalSummary{
		UserID:           targetUserID,
		Period:           period,
		CompletionRate:   rate,
		DynamicBalance:   balance,
		ConsistencyScore: consistencyScore,
		StrongestDynamic: strongest,
		WeakestDynamic:   weakest,
	}, nil
}
