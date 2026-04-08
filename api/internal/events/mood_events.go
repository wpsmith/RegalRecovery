// internal/events/mood_events.go
package events

import (
	"context"
	"time"
)

// Mood event types.
const (
	EventMoodCrisisEntry   EventType = "mood.crisis_entry"
	EventMoodSustainedLow  EventType = "mood.sustained_low_mood"
	EventMoodStreakMilestone EventType = "mood.streak_milestone"
)

// PublishMoodCrisisEntry publishes an event when a crisis entry (rating=1) is logged.
// Per PRD: crisis entries do NOT auto-notify the support network.
func PublishMoodCrisisEntry(ctx context.Context, publisher Publisher, userID, tenantID, moodID string) error {
	return publisher.Publish(ctx, Event{
		Type:      EventMoodCrisisEntry,
		UserID:    userID,
		TenantID:  tenantID,
		Timestamp: time.Now().UTC(),
		Data: map[string]interface{}{
			"moodId":       moodID,
			"autoNotified": false,
		},
	})
}

// PublishMoodSustainedLow publishes an event when sustained low mood is detected
// (3+ consecutive days with average <= 2.0).
// sharingEnabled indicates whether the user has opted in to sharing alerts.
func PublishMoodSustainedLow(ctx context.Context, publisher Publisher, userID, tenantID string, consecutiveDays int, sharingEnabled bool) error {
	return publisher.Publish(ctx, Event{
		Type:      EventMoodSustainedLow,
		UserID:    userID,
		TenantID:  tenantID,
		Timestamp: time.Now().UTC(),
		Data: map[string]interface{}{
			"consecutiveLowDays":    consecutiveDays,
			"sharingEnabled":        sharingEnabled,
			"notifyNetwork":         sharingEnabled,
		},
	})
}

// PublishMoodStreakMilestone publishes an event when a mood tracking streak
// milestone is reached.
func PublishMoodStreakMilestone(ctx context.Context, publisher Publisher, userID, tenantID string, streakDays int) error {
	return publisher.Publish(ctx, Event{
		Type:      EventMoodStreakMilestone,
		UserID:    userID,
		TenantID:  tenantID,
		Timestamp: time.Now().UTC(),
		Data: map[string]interface{}{
			"streakDays": streakDays,
		},
	})
}
