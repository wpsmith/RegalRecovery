// internal/events/types.go
package events

import "time"

// EventType represents the type of domain event.
type EventType string

const (
	EventMilestoneAchieved EventType = "milestone.achieved"
	EventRelapseRecorded   EventType = "relapse.recorded"
	EventStreakUpdated     EventType = "streak.updated"
	EventCheckInCompleted  EventType = "checkin.completed"
	EventActivityLogged    EventType = "activity.logged"
)

// Event represents a domain event to be published.
type Event struct {
	Type          EventType              `json:"type"`
	UserID        string                 `json:"userId"`
	TenantID      string                 `json:"tenantId"`
	Timestamp     time.Time              `json:"timestamp"`
	CorrelationID string                 `json:"correlationId"`
	Data          map[string]interface{} `json:"data"`
}
