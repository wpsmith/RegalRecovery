// internal/events/affirmations_consumers.go
package events

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"time"
)

// Notification text constants - CRITICAL: 100% generic, no recovery/addiction references.
const (
	NotifMorningReminder   = "Your daily moment is ready."
	NotifEveningReminder   = "A moment to close your day."
	NotifPostSOSCheckIn    = "How are you feeling now?"
	NotifReengagement3Day  = "Ready when you are."
	NotifReengagement7Day  = "Coming back is an act of courage."
	NotifReengagement14Day = "Reconnecting with your support network can help."
	NotifMoodEscalation    = "Consider reaching out to someone you trust."
	NotifCrisisHotline     = "Help is available 24/7 at 988 or text HOME to 741741."
)

// Crisis resources - never revealed on lock screen, only shown in-app.
const (
	CrisisTextLine = "741741"      // Crisis Text Line: Text HOME to 741741
	SAMHSA         = "1800662HELP" // SAMHSA National Helpline: 1-800-662-4357
	SuicideLine    = "988"         // 988 Suicide & Crisis Lifeline
)

// NotificationPriority defines the urgency level of a notification.
type NotificationPriority string

const (
	PriorityLow      NotificationPriority = "low"
	PriorityNormal   NotificationPriority = "normal"
	PriorityHigh     NotificationPriority = "high"
	PriorityCritical NotificationPriority = "critical"
)

// NotificationPayload defines the structure of a notification to be delivered.
type NotificationPayload struct {
	UserID       string                 `json:"userId"`
	TenantID     string                 `json:"tenantId"`
	Title        string                 `json:"title"`
	Body         string                 `json:"body"`
	Priority     NotificationPriority   `json:"priority"`
	DeliveryTime time.Time              `json:"deliveryTime"`
	Data         map[string]interface{} `json:"data"`
}

// AffirmationNotificationHandler handles affirmation-related notification events.
type AffirmationNotificationHandler struct {
	notificationService NotificationService
}

// NotificationService defines the interface for delivering notifications.
type NotificationService interface {
	// Schedule schedules a notification for future delivery.
	Schedule(ctx context.Context, payload NotificationPayload) error

	// SendImmediate sends a notification immediately.
	SendImmediate(ctx context.Context, payload NotificationPayload) error
}

// NewAffirmationNotificationHandler creates a new notification handler.
func NewAffirmationNotificationHandler(notificationService NotificationService) *AffirmationNotificationHandler {
	return &AffirmationNotificationHandler{
		notificationService: notificationService,
	}
}

// HandleEvent routes events to the appropriate notification handler.
func (h *AffirmationNotificationHandler) HandleEvent(ctx context.Context, rawEvent []byte) error {
	var event Event
	if err := json.Unmarshal(rawEvent, &event); err != nil {
		return fmt.Errorf("failed to unmarshal event: %w", err)
	}

	slog.Info("handling_affirmation_event",
		slog.String("event_type", string(event.Type)),
		slog.String("user_id", event.UserID),
		slog.String("correlation_id", event.CorrelationID),
	)

	switch event.Type {
	case EventAffirmationSOSCompleted:
		return h.handleSOSCompleted(ctx, event)
	case EventAffirmationMoodWorsening:
		return h.handleMoodWorsening(ctx, event)
	case EventAffirmationCrisisDetected:
		return h.handleCrisisDetected(ctx, event)
	case EventAffirmationMilestoneAchieved:
		return h.handleMilestoneAchieved(ctx, event)
	case EventAffirmationSessionCompleted:
		// Session completed events are tracked but don't trigger notifications
		return nil
	default:
		slog.Warn("unknown_affirmation_event_type",
			slog.String("event_type", string(event.Type)),
			slog.String("correlation_id", event.CorrelationID),
		)
		return nil
	}
}

// handleSOSCompleted schedules a 10-minute delayed check-in notification after SOS completion.
func (h *AffirmationNotificationHandler) handleSOSCompleted(ctx context.Context, event Event) error {
	deliveryTime := event.Timestamp.Add(10 * time.Minute)

	payload := NotificationPayload{
		UserID:       event.UserID,
		TenantID:     event.TenantID,
		Title:        "",
		Body:         NotifPostSOSCheckIn,
		Priority:     PriorityNormal,
		DeliveryTime: deliveryTime,
		Data: map[string]interface{}{
			"type":          "sos_checkin",
			"correlationId": event.CorrelationID,
		},
	}

	if err := h.notificationService.Schedule(ctx, payload); err != nil {
		return fmt.Errorf("failed to schedule SOS check-in notification: %w", err)
	}

	slog.Info("scheduled_sos_checkin_notification",
		slog.String("user_id", event.UserID),
		slog.String("correlation_id", event.CorrelationID),
		slog.Time("delivery_time", deliveryTime),
	)

	return nil
}

// handleMoodWorsening sends an escalation notification for consecutive mood declines.
func (h *AffirmationNotificationHandler) handleMoodWorsening(ctx context.Context, event Event) error {
	consecutiveDeclines, _ := event.Data["consecutiveDeclines"].(int)

	payload := NotificationPayload{
		UserID:       event.UserID,
		TenantID:     event.TenantID,
		Title:        "",
		Body:         NotifMoodEscalation,
		Priority:     PriorityHigh,
		DeliveryTime: time.Now().UTC(),
		Data: map[string]interface{}{
			"type":                "mood_escalation",
			"consecutiveDeclines": consecutiveDeclines,
			"correlationId":       event.CorrelationID,
		},
	}

	if err := h.notificationService.SendImmediate(ctx, payload); err != nil {
		return fmt.Errorf("failed to send mood worsening notification: %w", err)
	}

	slog.Info("sent_mood_escalation_notification",
		slog.String("user_id", event.UserID),
		slog.String("correlation_id", event.CorrelationID),
		slog.Int("consecutive_declines", consecutiveDeclines),
	)

	return nil
}

// handleCrisisDetected sends a critical notification with crisis resources.
func (h *AffirmationNotificationHandler) handleCrisisDetected(ctx context.Context, event Event) error {
	payload := NotificationPayload{
		UserID:       event.UserID,
		TenantID:     event.TenantID,
		Title:        "",
		Body:         NotifCrisisHotline,
		Priority:     PriorityCritical,
		DeliveryTime: time.Now().UTC(),
		Data: map[string]interface{}{
			"type":           "crisis",
			"crisisTextLine": CrisisTextLine,
			"samhsa":         SAMHSA,
			"suicideLine":    SuicideLine,
			"correlationId":  event.CorrelationID,
		},
	}

	if err := h.notificationService.SendImmediate(ctx, payload); err != nil {
		return fmt.Errorf("failed to send crisis notification: %w", err)
	}

	slog.Info("sent_crisis_notification",
		slog.String("user_id", event.UserID),
		slog.String("correlation_id", event.CorrelationID),
	)

	return nil
}

// handleMilestoneAchieved sends a celebration notification for milestones.
func (h *AffirmationNotificationHandler) handleMilestoneAchieved(ctx context.Context, event Event) error {
	milestone, _ := event.Data["milestone"].(string)
	count, _ := event.Data["count"].(int)

	// Generic celebration message - no specifics revealed on lock screen
	body := "A moment worth celebrating."

	payload := NotificationPayload{
		UserID:       event.UserID,
		TenantID:     event.TenantID,
		Title:        "",
		Body:         body,
		Priority:     PriorityNormal,
		DeliveryTime: time.Now().UTC(),
		Data: map[string]interface{}{
			"type":          "milestone",
			"milestone":     milestone,
			"count":         count,
			"correlationId": event.CorrelationID,
		},
	}

	if err := h.notificationService.SendImmediate(ctx, payload); err != nil {
		return fmt.Errorf("failed to send milestone notification: %w", err)
	}

	slog.Info("sent_milestone_notification",
		slog.String("user_id", event.UserID),
		slog.String("correlation_id", event.CorrelationID),
		slog.String("milestone", milestone),
		slog.Int("count", count),
	)

	return nil
}

// ScheduleMorningReminder schedules a morning reminder notification for the user's configured time.
func (h *AffirmationNotificationHandler) ScheduleMorningReminder(ctx context.Context, userID, tenantID string, deliveryTime time.Time) error {
	payload := NotificationPayload{
		UserID:       userID,
		TenantID:     tenantID,
		Title:        "",
		Body:         NotifMorningReminder,
		Priority:     PriorityLow,
		DeliveryTime: deliveryTime,
		Data: map[string]interface{}{
			"type": "morning_reminder",
		},
	}

	if err := h.notificationService.Schedule(ctx, payload); err != nil {
		return fmt.Errorf("failed to schedule morning reminder: %w", err)
	}

	slog.Info("scheduled_morning_reminder",
		slog.String("user_id", userID),
		slog.Time("delivery_time", deliveryTime),
	)

	return nil
}

// ScheduleEveningReminder schedules an evening reminder notification for the user's configured time.
func (h *AffirmationNotificationHandler) ScheduleEveningReminder(ctx context.Context, userID, tenantID string, deliveryTime time.Time) error {
	payload := NotificationPayload{
		UserID:       userID,
		TenantID:     tenantID,
		Title:        "",
		Body:         NotifEveningReminder,
		Priority:     PriorityLow,
		DeliveryTime: deliveryTime,
		Data: map[string]interface{}{
			"type": "evening_reminder",
		},
	}

	if err := h.notificationService.Schedule(ctx, payload); err != nil {
		return fmt.Errorf("failed to schedule evening reminder: %w", err)
	}

	slog.Info("scheduled_evening_reminder",
		slog.String("user_id", userID),
		slog.Time("delivery_time", deliveryTime),
	)

	return nil
}

// SendReengagement3Day sends a 3-day re-engagement notification (once per gap).
func (h *AffirmationNotificationHandler) SendReengagement3Day(ctx context.Context, userID, tenantID string) error {
	payload := NotificationPayload{
		UserID:       userID,
		TenantID:     tenantID,
		Title:        "",
		Body:         NotifReengagement3Day,
		Priority:     PriorityLow,
		DeliveryTime: time.Now().UTC(),
		Data: map[string]interface{}{
			"type": "reengagement_3day",
		},
	}

	if err := h.notificationService.SendImmediate(ctx, payload); err != nil {
		return fmt.Errorf("failed to send 3-day re-engagement notification: %w", err)
	}

	slog.Info("sent_reengagement_3day_notification",
		slog.String("user_id", userID),
	)

	return nil
}

// SendReengagement7Day sends a 7-day re-engagement notification (once per gap).
func (h *AffirmationNotificationHandler) SendReengagement7Day(ctx context.Context, userID, tenantID string) error {
	payload := NotificationPayload{
		UserID:       userID,
		TenantID:     tenantID,
		Title:        "",
		Body:         NotifReengagement7Day,
		Priority:     PriorityLow,
		DeliveryTime: time.Now().UTC(),
		Data: map[string]interface{}{
			"type": "reengagement_7day",
		},
	}

	if err := h.notificationService.SendImmediate(ctx, payload); err != nil {
		return fmt.Errorf("failed to send 7-day re-engagement notification: %w", err)
	}

	slog.Info("sent_reengagement_7day_notification",
		slog.String("user_id", userID),
	)

	return nil
}

// SendReengagement14Day sends a 14+ day re-engagement notification with support network prompt (once per gap).
func (h *AffirmationNotificationHandler) SendReengagement14Day(ctx context.Context, userID, tenantID string) error {
	payload := NotificationPayload{
		UserID:       userID,
		TenantID:     tenantID,
		Title:        "",
		Body:         NotifReengagement14Day,
		Priority:     PriorityNormal,
		DeliveryTime: time.Now().UTC(),
		Data: map[string]interface{}{
			"type": "reengagement_14day",
		},
	}

	if err := h.notificationService.SendImmediate(ctx, payload); err != nil {
		return fmt.Errorf("failed to send 14-day re-engagement notification: %w", err)
	}

	slog.Info("sent_reengagement_14day_notification",
		slog.String("user_id", userID),
	)

	return nil
}
