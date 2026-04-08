// internal/events/postmortem_events.go
package events

import "time"

// Post-mortem specific event types.
const (
	EventPostMortemCompleted   EventType = "post-mortem.completed"
	EventPostMortemReminder    EventType = "post-mortem.reminder"
	EventRelapsePostMortemDue  EventType = "relapse.post-mortem-due"
)

// PostMortemCompletedData contains data for the post-mortem.completed event.
type PostMortemCompletedData struct {
	AnalysisID      string    `json:"analysisId"`
	EventType       string    `json:"eventType"`
	RelapseID       string    `json:"relapseId,omitempty"`
	AddictionID     string    `json:"addictionId,omitempty"`
	TriggerCount    int       `json:"triggerCount"`
	ActionItemCount int       `json:"actionItemCount"`
	CompletedAt     time.Time `json:"completedAt"`
}

// PostMortemReminderData contains data for the post-mortem gentle reminder.
type PostMortemReminderData struct {
	RelapseID  string    `json:"relapseId"`
	RelapseAt  time.Time `json:"relapseAt"`
	Message    string    `json:"message"`
}

// PostMortemReminderMessage is the gentle reminder text per PM-AC11.3.
const PostMortemReminderMessage = "Taking a few minutes to reflect on what happened can strengthen your recovery. Would you like to complete a post-mortem?"

// NewPostMortemCompletedEvent creates a post-mortem.completed event.
func NewPostMortemCompletedEvent(userID, tenantID, correlationID string, data PostMortemCompletedData) Event {
	return Event{
		Type:          EventPostMortemCompleted,
		UserID:        userID,
		TenantID:      tenantID,
		Timestamp:     time.Now().UTC(),
		CorrelationID: correlationID,
		Data: map[string]interface{}{
			"analysisId":      data.AnalysisID,
			"eventType":       data.EventType,
			"relapseId":       data.RelapseID,
			"addictionId":     data.AddictionID,
			"triggerCount":    data.TriggerCount,
			"actionItemCount": data.ActionItemCount,
			"completedAt":     data.CompletedAt.Format(time.RFC3339),
		},
	}
}

// NewPostMortemReminderEvent creates a gentle reminder event for a relapse without post-mortem.
func NewPostMortemReminderEvent(userID, tenantID, correlationID string, data PostMortemReminderData) Event {
	return Event{
		Type:          EventPostMortemReminder,
		UserID:        userID,
		TenantID:      tenantID,
		Timestamp:     time.Now().UTC(),
		CorrelationID: correlationID,
		Data: map[string]interface{}{
			"relapseId": data.RelapseID,
			"relapseAt": data.RelapseAt.Format(time.RFC3339),
			"message":   data.Message,
		},
	}
}
