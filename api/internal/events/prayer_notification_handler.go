// internal/events/prayer_notification_handler.go
package events

import (
	"context"
	"fmt"
	"time"
)

// Prayer-specific event types.
const (
	EventPrayerSessionCreated EventType = "prayer.session.created"
	EventPrayerStreakMilestone EventType = "prayer.streak.milestone"
	EventPrayerReminder       EventType = "prayer.reminder.daily"
	EventPrayerMissedNudge    EventType = "prayer.nudge.missed"
	EventPrayerPackAvailable  EventType = "prayer.pack.available"
)

// PrayerMilestones defines the streak milestones that trigger notifications.
var PrayerMilestones = []int{7, 14, 30, 60, 90}

// PrayerEventPublisher publishes prayer domain events to SNS.
type PrayerEventPublisher struct {
	publisher Publisher
}

// NewPrayerEventPublisher creates a new PrayerEventPublisher.
func NewPrayerEventPublisher(publisher Publisher) *PrayerEventPublisher {
	return &PrayerEventPublisher{publisher: publisher}
}

// PublishSessionCreated publishes a prayer.session.created event.
func (p *PrayerEventPublisher) PublishSessionCreated(ctx context.Context, userID, prayerID string) error {
	event := Event{
		Type:      EventPrayerSessionCreated,
		UserID:    userID,
		Timestamp: time.Now().UTC(),
		Data: map[string]interface{}{
			"prayerId": prayerID,
		},
	}
	if err := p.publisher.Publish(ctx, event); err != nil {
		return fmt.Errorf("publishing prayer session created event: %w", err)
	}
	return nil
}

// PublishStreakMilestone publishes a prayer.streak.milestone event.
func (p *PrayerEventPublisher) PublishStreakMilestone(ctx context.Context, userID string, milestone int) error {
	event := Event{
		Type:      EventPrayerStreakMilestone,
		UserID:    userID,
		Timestamp: time.Now().UTC(),
		Data: map[string]interface{}{
			"milestone":      milestone,
			"celebrationMsg": milestoneMessage(milestone),
		},
	}
	if err := p.publisher.Publish(ctx, event); err != nil {
		return fmt.Errorf("publishing prayer streak milestone event: %w", err)
	}
	return nil
}

// IsMilestone checks if the given streak count is a milestone.
func IsMilestone(streakDays int) bool {
	for _, m := range PrayerMilestones {
		if streakDays == m {
			return true
		}
	}
	return false
}

// milestoneMessage returns a celebration message for a given milestone.
func milestoneMessage(days int) string {
	switch days {
	case 7:
		return "One week of faithful prayer! Your consistency honors God."
	case 14:
		return "Two weeks of daily prayer. You are building a powerful habit."
	case 30:
		return "30 days of prayer! What a testimony of faithfulness."
	case 60:
		return "60 days of prayer. Your commitment to God is bearing fruit."
	case 90:
		return "90 days of daily prayer! This is a remarkable spiritual discipline."
	default:
		return fmt.Sprintf("%d days of faithful prayer. Keep going!", days)
	}
}

// PrayerNotificationConfig holds notification preferences for prayer reminders.
type PrayerNotificationConfig struct {
	DailyReminderEnabled bool
	DailyReminderTime    string // HH:MM format
	MissedNudgeEnabled   bool
	MissedNudgeDays      int    // Number of inactive days before nudge (default: 3)
	MilestoneEnabled     bool
}

// DefaultPrayerNotificationConfig returns default notification settings.
func DefaultPrayerNotificationConfig() *PrayerNotificationConfig {
	return &PrayerNotificationConfig{
		DailyReminderEnabled: false,
		DailyReminderTime:    "07:00",
		MissedNudgeEnabled:   true,
		MissedNudgeDays:      3,
		MilestoneEnabled:     true,
	}
}
