// internal/events/exercise_event_handler.go
package events

import (
	"context"
	"fmt"
	"time"
)

// Exercise-specific event types.
const (
	EventExerciseLogged          EventType = "exercise.logged"
	EventExerciseStreakMilestone  EventType = "exercise.streak.milestone"
	EventExerciseGoalAchieved    EventType = "exercise.goal.achieved"
	EventExerciseInactivityNudge EventType = "exercise.inactivity.nudge"
)

// ExerciseEventHandler processes exercise-related domain events.
type ExerciseEventHandler struct {
	publisher Publisher
}

// NewExerciseEventHandler creates a new ExerciseEventHandler.
func NewExerciseEventHandler(publisher Publisher) *ExerciseEventHandler {
	return &ExerciseEventHandler{publisher: publisher}
}

// OnExerciseLogged publishes an event when a new exercise is logged.
// This event triggers:
// - Calendar activity dual-write
// - Weekly goal threshold check
// - Streak milestone detection
// - Physical dynamic goal auto-check
func (h *ExerciseEventHandler) OnExerciseLogged(ctx context.Context, userID, tenantID, exerciseID, activityType string, durationMinutes int) error {
	event := Event{
		Type:      EventExerciseLogged,
		UserID:    userID,
		TenantID:  tenantID,
		Timestamp: time.Now().UTC(),
		Data: map[string]interface{}{
			"exerciseId":      exerciseID,
			"activityType":    activityType,
			"durationMinutes": durationMinutes,
		},
	}
	if err := h.publisher.Publish(ctx, event); err != nil {
		return fmt.Errorf("publishing exercise logged event: %w", err)
	}
	return nil
}

// OnStreakMilestone publishes an event when a streak milestone is reached.
// Milestones: 3, 7, 14, 21, 30, 60, 90 days.
func (h *ExerciseEventHandler) OnStreakMilestone(ctx context.Context, userID, tenantID string, milestoneDays int) error {
	event := Event{
		Type:      EventExerciseStreakMilestone,
		UserID:    userID,
		TenantID:  tenantID,
		Timestamp: time.Now().UTC(),
		Data: map[string]interface{}{
			"milestoneDays": milestoneDays,
			"message":       fmt.Sprintf("You've exercised %d days in a row!", milestoneDays),
		},
	}
	if err := h.publisher.Publish(ctx, event); err != nil {
		return fmt.Errorf("publishing streak milestone event: %w", err)
	}
	return nil
}

// OnGoalAchieved publishes an event when the weekly exercise goal is met.
func (h *ExerciseEventHandler) OnGoalAchieved(ctx context.Context, userID, tenantID string, activeMinutes int) error {
	event := Event{
		Type:      EventExerciseGoalAchieved,
		UserID:    userID,
		TenantID:  tenantID,
		Timestamp: time.Now().UTC(),
		Data: map[string]interface{}{
			"activeMinutes": activeMinutes,
			"message":       fmt.Sprintf("You hit your weekly exercise goal! That's %d active minutes this week.", activeMinutes),
		},
	}
	if err := h.publisher.Publish(ctx, event); err != nil {
		return fmt.Errorf("publishing goal achieved event: %w", err)
	}
	return nil
}

// OnInactivityNudge publishes a gentle nudge event when the user has been inactive.
func (h *ExerciseEventHandler) OnInactivityNudge(ctx context.Context, userID, tenantID string, daysSinceExercise int) error {
	event := Event{
		Type:      EventExerciseInactivityNudge,
		UserID:    userID,
		TenantID:  tenantID,
		Timestamp: time.Now().UTC(),
		Data: map[string]interface{}{
			"daysSinceExercise": daysSinceExercise,
			"message":           fmt.Sprintf("You haven't logged any exercise in %d days. Even a short walk counts.", daysSinceExercise),
		},
	}
	if err := h.publisher.Publish(ctx, event); err != nil {
		return fmt.Errorf("publishing inactivity nudge event: %w", err)
	}
	return nil
}
