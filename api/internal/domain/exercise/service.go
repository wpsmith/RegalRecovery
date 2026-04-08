// internal/domain/exercise/service.go
package exercise

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// ExerciseService handles exercise business logic.
type ExerciseService struct {
	exerciseRepo ExerciseRepository
	favoriteRepo FavoriteRepository
	goalRepo     GoalRepository
}

// NewExerciseService creates a new ExerciseService with required dependencies.
func NewExerciseService(
	exerciseRepo ExerciseRepository,
	favoriteRepo FavoriteRepository,
	goalRepo GoalRepository,
) *ExerciseService {
	return &ExerciseService{
		exerciseRepo: exerciseRepo,
		favoriteRepo: favoriteRepo,
		goalRepo:     goalRepo,
	}
}

// CreateExerciseLog validates and persists a new exercise log entry.
func (s *ExerciseService) CreateExerciseLog(ctx context.Context, userID, tenantID string, req CreateExerciseLogRequest) (*ExerciseLog, error) {
	now := time.Now().UTC()

	// Default timestamp to now.
	if req.Timestamp.IsZero() {
		req.Timestamp = now
	}

	// Default source to manual.
	if req.Source == "" {
		req.Source = SourceManual
	}

	if err := ValidateCreateRequest(req, now); err != nil {
		return nil, err
	}

	log := ExerciseLog{
		ExerciseID:      "ex_" + uuid.NewString()[:8],
		UserID:          userID,
		TenantID:        tenantID,
		Timestamp:       req.Timestamp,
		ActivityType:    req.ActivityType,
		CustomTypeLabel: req.CustomTypeLabel,
		DurationMinutes: req.DurationMinutes,
		Intensity:       req.Intensity,
		Notes:           req.Notes,
		MoodBefore:      req.MoodBefore,
		MoodAfter:       req.MoodAfter,
		Source:          req.Source,
		ExternalID:      req.ExternalID,
		CreatedAt:       now,
		ModifiedAt:      now,
	}

	if err := s.exerciseRepo.Create(ctx, log); err != nil {
		return nil, fmt.Errorf("creating exercise log: %w", err)
	}

	return &log, nil
}

// GetExerciseLog retrieves a single exercise log by ID.
func (s *ExerciseService) GetExerciseLog(ctx context.Context, userID, exerciseID string) (*ExerciseLog, error) {
	log, err := s.exerciseRepo.GetByID(ctx, userID, exerciseID)
	if err != nil {
		return nil, fmt.Errorf("retrieving exercise log: %w", err)
	}
	if log == nil {
		return nil, ErrExerciseNotFound
	}
	return log, nil
}

// ListExerciseLogs retrieves exercise logs with pagination and filtering.
func (s *ExerciseService) ListExerciseLogs(ctx context.Context, userID string, opts ListOptions) ([]ExerciseLog, string, error) {
	if opts.Limit <= 0 {
		opts.Limit = 50
	}
	if opts.Limit > 100 {
		opts.Limit = 100
	}
	if opts.Sort == "" {
		opts.Sort = "-timestamp"
	}

	logs, cursor, err := s.exerciseRepo.List(ctx, userID, opts)
	if err != nil {
		return nil, "", fmt.Errorf("listing exercise logs: %w", err)
	}
	return logs, cursor, nil
}

// UpdateExerciseLog validates and applies a partial update to an exercise log.
func (s *ExerciseService) UpdateExerciseLog(ctx context.Context, userID, exerciseID string, req UpdateExerciseLogRequest) (*ExerciseLog, error) {
	updates, err := ValidateUpdateRequest(req)
	if err != nil {
		return nil, err
	}

	if len(updates) == 0 {
		return s.GetExerciseLog(ctx, userID, exerciseID)
	}

	updates["modifiedAt"] = time.Now().UTC()

	if err := s.exerciseRepo.Update(ctx, userID, exerciseID, updates); err != nil {
		return nil, fmt.Errorf("updating exercise log: %w", err)
	}

	return s.GetExerciseLog(ctx, userID, exerciseID)
}

// DeleteExerciseLog removes an exercise log.
func (s *ExerciseService) DeleteExerciseLog(ctx context.Context, userID, exerciseID string) error {
	if err := s.exerciseRepo.Delete(ctx, userID, exerciseID); err != nil {
		return fmt.Errorf("deleting exercise log: %w", err)
	}
	return nil
}

// GetStreak computes the exercise streak for a user.
func (s *ExerciseService) GetStreak(ctx context.Context, userID string, tz *time.Location) (*ExerciseStreak, error) {
	if tz == nil {
		tz = time.UTC
	}

	// Get all exercise logs for streak computation (last 365 days is reasonable).
	now := time.Now().In(tz)
	start := now.AddDate(-1, 0, 0)
	logs, err := s.exerciseRepo.GetByDateRange(ctx, userID, start, now)
	if err != nil {
		return nil, fmt.Errorf("retrieving exercise logs for streak: %w", err)
	}

	dates := make([]time.Time, len(logs))
	for i, log := range logs {
		dates[i] = log.Timestamp
	}

	streak := CalculateStreak(dates, now, tz)
	return &streak, nil
}

// GetStats computes exercise statistics for a given period.
func (s *ExerciseService) GetStats(ctx context.Context, userID string, period string, referenceDate time.Time) (*ExerciseStats, error) {
	start, end := PeriodDateRange(period, referenceDate)
	prevStart, prevEnd := PreviousPeriodDateRange(period, referenceDate)

	currentLogs, err := s.exerciseRepo.GetByDateRange(ctx, userID, start, end)
	if err != nil {
		return nil, fmt.Errorf("retrieving current period logs: %w", err)
	}

	previousLogs, err := s.exerciseRepo.GetByDateRange(ctx, userID, prevStart, prevEnd)
	if err != nil {
		return nil, fmt.Errorf("retrieving previous period logs: %w", err)
	}

	streak, err := s.GetStreak(ctx, userID, referenceDate.Location())
	if err != nil {
		return nil, fmt.Errorf("computing streak for stats: %w", err)
	}

	stats := CalculateStats(currentLogs, previousLogs, *streak, period, referenceDate.Format("2006-01-02"))
	return &stats, nil
}

// GetGoal retrieves the user's weekly goal with current progress.
func (s *ExerciseService) GetGoal(ctx context.Context, userID string) (*GoalProgress, error) {
	goal, err := s.goalRepo.Get(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("retrieving goal: %w", err)
	}
	if goal == nil {
		return nil, ErrGoalNotFound
	}

	now := time.Now().UTC()
	weekStart := WeekStartDate(now)
	weekEnd := weekStart.AddDate(0, 0, 7)

	logs, err := s.exerciseRepo.GetByDateRange(ctx, userID, weekStart, weekEnd)
	if err != nil {
		return nil, fmt.Errorf("retrieving logs for goal progress: %w", err)
	}

	progress := CalculateGoalProgress(*goal, logs, weekStart)
	return &progress, nil
}

// SetGoal creates or updates the user's weekly exercise goal.
func (s *ExerciseService) SetGoal(ctx context.Context, userID, tenantID string, goal ExerciseGoal) (*GoalProgress, error) {
	goal.UserID = userID
	goal.TenantID = tenantID

	if err := ValidateGoal(goal); err != nil {
		return nil, err
	}

	now := time.Now().UTC()
	goal.ModifiedAt = now

	if err := s.goalRepo.Upsert(ctx, userID, goal); err != nil {
		return nil, fmt.Errorf("saving goal: %w", err)
	}

	return s.GetGoal(ctx, userID)
}

// DeleteGoal removes the user's weekly exercise goal.
func (s *ExerciseService) DeleteGoal(ctx context.Context, userID string) error {
	if err := s.goalRepo.Delete(ctx, userID); err != nil {
		return fmt.Errorf("deleting goal: %w", err)
	}
	return nil
}

// GetWidget assembles dashboard widget data.
func (s *ExerciseService) GetWidget(ctx context.Context, userID string, tz *time.Location) (*WidgetData, error) {
	if tz == nil {
		tz = time.UTC
	}

	now := time.Now()
	todayStart, todayEnd := TodayDateRange(now, tz)

	todayLogs, err := s.exerciseRepo.GetByDateRange(ctx, userID, todayStart, todayEnd)
	if err != nil {
		return nil, fmt.Errorf("retrieving today's logs: %w", err)
	}

	streak, err := s.GetStreak(ctx, userID, tz)
	if err != nil {
		return nil, fmt.Errorf("computing streak for widget: %w", err)
	}

	var goalProgress *GoalProgress
	progress, err := s.GetGoal(ctx, userID)
	if err == nil {
		goalProgress = progress
	}
	// ErrGoalNotFound is acceptable; widget shows nil.

	widget := AssembleWidgetData(todayLogs, *streak, goalProgress)
	return &widget, nil
}

// ListFavorites retrieves all favorites for a user.
func (s *ExerciseService) ListFavorites(ctx context.Context, userID string) ([]ExerciseFavorite, error) {
	favs, err := s.favoriteRepo.List(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("listing favorites: %w", err)
	}
	return favs, nil
}

// CreateFavorite creates a new exercise favorite.
func (s *ExerciseService) CreateFavorite(ctx context.Context, userID, tenantID string, fav ExerciseFavorite) (*ExerciseFavorite, error) {
	fav.UserID = userID
	fav.TenantID = tenantID
	fav.FavoriteID = "fav_" + uuid.NewString()[:8]

	if err := ValidateFavorite(fav); err != nil {
		return nil, err
	}

	count, err := s.favoriteRepo.Count(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("counting favorites: %w", err)
	}
	if err := CanAddFavorite(count); err != nil {
		return nil, err
	}

	fav.SortOrder = count + 1
	now := time.Now().UTC()
	fav.CreatedAt = now
	fav.ModifiedAt = now

	if err := s.favoriteRepo.Create(ctx, fav); err != nil {
		return nil, fmt.Errorf("creating favorite: %w", err)
	}

	return &fav, nil
}

// UpdateFavorite replaces a favorite.
func (s *ExerciseService) UpdateFavorite(ctx context.Context, userID, favoriteID string, fav ExerciseFavorite) (*ExerciseFavorite, error) {
	fav.FavoriteID = favoriteID
	fav.UserID = userID

	if err := ValidateFavorite(fav); err != nil {
		return nil, err
	}

	fav.ModifiedAt = time.Now().UTC()

	if err := s.favoriteRepo.Update(ctx, userID, favoriteID, fav); err != nil {
		return nil, fmt.Errorf("updating favorite: %w", err)
	}

	return &fav, nil
}

// DeleteFavorite removes a favorite.
func (s *ExerciseService) DeleteFavorite(ctx context.Context, userID, favoriteID string) error {
	if err := s.favoriteRepo.Delete(ctx, userID, favoriteID); err != nil {
		return fmt.Errorf("deleting favorite: %w", err)
	}
	return nil
}
