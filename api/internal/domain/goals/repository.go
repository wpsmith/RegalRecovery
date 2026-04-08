// internal/domain/goals/repository.go
package goals

import "context"

// GoalRepository defines the persistence interface for weekly/daily goals.
type GoalRepository interface {
	// Goal definitions
	CreateGoal(ctx context.Context, userID string, goal *WeeklyDailyGoal) error
	GetGoal(ctx context.Context, userID, goalID string) (*WeeklyDailyGoal, error)
	ListGoals(ctx context.Context, userID string, scope *GoalScope, dynamic *Dynamic, isActive *bool, cursor string, limit int) ([]WeeklyDailyGoal, string, error)
	UpdateGoal(ctx context.Context, userID, goalID string, req *UpdateWeeklyDailyGoalRequest) (*WeeklyDailyGoal, error)
	DeleteGoal(ctx context.Context, userID, goalID string) error

	// Goal instances
	GetDailyInstances(ctx context.Context, userID, date string) ([]GoalInstance, error)
	GetWeeklyInstances(ctx context.Context, userID, weekStart, weekEnd string) ([]GoalInstance, error)
	GetInstancesByDateRange(ctx context.Context, userID, startDate, endDate string, dynamic *Dynamic, status *GoalInstanceStatus, search string, cursor string, limit int) ([]GoalInstance, string, int, error)
	GetInstance(ctx context.Context, userID, goalInstanceID string) (*GoalInstance, error)
	CreateInstance(ctx context.Context, userID string, instance *GoalInstance) error
	UpdateInstanceStatus(ctx context.Context, userID, goalInstanceID string, status GoalInstanceStatus, completedAt *string) error
	BatchCreateInstances(ctx context.Context, userID string, instances []GoalInstance) error

	// Reviews
	GetDailyReview(ctx context.Context, userID, date string) (*GoalReview, error)
	CreateDailyReview(ctx context.Context, userID string, review *GoalReview) error
	GetWeeklyReview(ctx context.Context, userID, weekStart string) (*GoalReview, error)
	CreateWeeklyReview(ctx context.Context, userID string, review *GoalReview) error

	// Nudges
	GetDismissedNudges(ctx context.Context, userID, date string) ([]string, error)
	DismissNudge(ctx context.Context, userID, date string, dynamic string) error

	// Settings
	GetGoalSettings(ctx context.Context, userID string) (*GoalSettings, error)
	UpdateGoalSettings(ctx context.Context, userID string, req *UpdateGoalSettingsRequest) (*GoalSettings, error)

	// Calendar dual-write
	WriteCalendarActivity(ctx context.Context, userID, date string, instance *GoalInstance) error
}
