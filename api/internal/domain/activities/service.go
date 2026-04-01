// internal/domain/activities/service.go
package activities

import (
	"context"
	"errors"
	"fmt"
	"time"
)

var (
	// ErrActivityNotFound indicates activity does not exist.
	ErrActivityNotFound = errors.New("activity not found")

	// ErrInvalidInput indicates invalid input data.
	ErrInvalidInput = errors.New("invalid input data")

	// ErrInvalidActivityType indicates invalid activity type.
	ErrInvalidActivityType = errors.New("invalid activity type")
)

// Valid activity types.
var validActivityTypes = map[string]bool{
	ActivityTypeCommitmentMorning:  true,
	ActivityTypeCommitmentEvening:  true,
	ActivityTypeJournal:            true,
	ActivityTypeEmotionalJournal:   true,
	ActivityTypeTimeJournal:        true,
	ActivityTypeCheckIn:            true,
	ActivityTypePersonCheckIn:      true,
	ActivityTypeFASTER:             true,
	ActivityTypePCI:                true,
	ActivityTypeUrge:               true,
	ActivityTypeMood:               true,
	ActivityTypeGratitude:          true,
	ActivityTypePhoneCall:          true,
	ActivityTypePrayer:             true,
	ActivityTypeMeeting:            true,
	ActivityTypeExercise:           true,
	ActivityTypeNutrition:          true,
	ActivityTypeDevotional:         true,
	ActivityTypeIntegrityInventory: true,
	ActivityTypeActingIn:           true,
	ActivityTypePostMortem:         true,
	ActivityTypeFinancial:          true,
	ActivityTypeStepWork:           true,
	ActivityTypeGoal:               true,
	ActivityTypeSpouseCheckInPrep:  true,
}

// ActivityService handles activity tracking business logic.
type ActivityService struct {
	repo ActivityRepository
}

// NewActivityService creates a new ActivityService with required dependencies.
func NewActivityService(repo ActivityRepository) *ActivityService {
	return &ActivityService{
		repo: repo,
	}
}

// LogActivity creates a new activity log entry.
// Validates input and stores the activity with immutable timestamp.
func (s *ActivityService) LogActivity(ctx context.Context, userID string, activityType string, data map[string]interface{}, ephemeral bool) (*Activity, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required: %w", ErrInvalidInput)
	}
	if activityType == "" {
		return nil, fmt.Errorf("activity type is required: %w", ErrInvalidInput)
	}
	if !s.isValidActivityType(activityType) {
		return nil, fmt.Errorf("activity type %s is not valid: %w", activityType, ErrInvalidActivityType)
	}
	if data == nil {
		data = make(map[string]interface{})
	}

	now := time.Now()
	activity := &Activity{
		UserID:       userID,
		ActivityType: activityType,
		Timestamp:    now,
		Data:         data,
		Ephemeral:    ephemeral,
		CreatedAt:    now,
		ModifiedAt:   now,
	}

	if err := s.repo.CreateActivity(ctx, activity); err != nil {
		return nil, fmt.Errorf("creating activity: %w", err)
	}

	return activity, nil
}

// GetActivity retrieves a specific activity by ID.
func (s *ActivityService) GetActivity(ctx context.Context, activityID string) (*Activity, error) {
	if activityID == "" {
		return nil, fmt.Errorf("activity ID is required: %w", ErrInvalidInput)
	}

	activity, err := s.repo.GetActivity(ctx, activityID)
	if err != nil {
		return nil, fmt.Errorf("retrieving activity: %w", err)
	}
	if activity == nil {
		return nil, ErrActivityNotFound
	}

	return activity, nil
}

// GetActivities retrieves activities for a user with cursor-based pagination.
// Returns activities and the next cursor token.
func (s *ActivityService) GetActivities(ctx context.Context, userID string, activityType string, cursor string, limit int) ([]*Activity, string, error) {
	if userID == "" {
		return nil, "", fmt.Errorf("user ID is required: %w", ErrInvalidInput)
	}

	// Validate activity type if specified.
	if activityType != "" && !s.isValidActivityType(activityType) {
		return nil, "", fmt.Errorf("activity type %s is not valid: %w", activityType, ErrInvalidActivityType)
	}

	// Default limit to 50, max 100.
	if limit <= 0 {
		limit = 50
	}
	if limit > 100 {
		limit = 100
	}

	activities, nextCursor, err := s.repo.GetUserActivities(ctx, userID, activityType, cursor, limit)
	if err != nil {
		return nil, "", fmt.Errorf("retrieving activities: %w", err)
	}

	return activities, nextCursor, nil
}

// GetActivitiesByDate retrieves all activities for a user on a specific date.
// Used for calendar day view showing all activities for that day.
func (s *ActivityService) GetActivitiesByDate(ctx context.Context, userID string, date time.Time) ([]*Activity, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required: %w", ErrInvalidInput)
	}

	activities, err := s.repo.GetUserActivitiesByDate(ctx, userID, date)
	if err != nil {
		return nil, fmt.Errorf("retrieving activities by date: %w", err)
	}

	return activities, nil
}

// GetActivitiesInRange retrieves activities for a user within a date range.
// Optionally filter by activity type.
func (s *ActivityService) GetActivitiesInRange(ctx context.Context, userID string, startDate, endDate time.Time, activityType string) ([]*Activity, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required: %w", ErrInvalidInput)
	}

	// Validate activity type if specified.
	if activityType != "" && !s.isValidActivityType(activityType) {
		return nil, fmt.Errorf("activity type %s is not valid: %w", activityType, ErrInvalidActivityType)
	}

	activities, err := s.repo.GetUserActivitiesInRange(ctx, userID, startDate, endDate, activityType)
	if err != nil {
		return nil, fmt.Errorf("retrieving activities in range: %w", err)
	}

	return activities, nil
}

// isValidActivityType checks if an activity type is valid.
func (s *ActivityService) isValidActivityType(activityType string) bool {
	return validActivityTypes[activityType]
}

// GetValidActivityTypes returns a list of all valid activity types.
func (s *ActivityService) GetValidActivityTypes() []string {
	types := make([]string, 0, len(validActivityTypes))
	for t := range validActivityTypes {
		types = append(types, t)
	}
	return types
}
