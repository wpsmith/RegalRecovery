// internal/events/affirmations_events.go
package events

import "time"

// Affirmation event types
const (
	EventAffirmationSessionCompleted  EventType = "affirmations.session.completed"
	EventAffirmationSOSActivated      EventType = "affirmations.sos.activated"
	EventAffirmationSOSCompleted      EventType = "affirmations.sos.completed"
	EventAffirmationMilestoneAchieved EventType = "affirmations.milestone.achieved"
	EventAffirmationMoodWorsening     EventType = "affirmations.mood.worsening"
	EventAffirmationCrisisDetected    EventType = "affirmations.crisis.detected"
	EventAffirmationRelapseLevelLock  EventType = "affirmations.relapse.level_lock"
)

// NewSessionCompletedEvent creates an event for a completed affirmation session.
func NewSessionCompletedEvent(userID, tenantID, correlationID, sessionType, sessionID string) Event {
	return Event{
		Type:          EventAffirmationSessionCompleted,
		UserID:        userID,
		TenantID:      tenantID,
		Timestamp:     time.Now().UTC(),
		CorrelationID: correlationID,
		Data: map[string]interface{}{
			"sessionType": sessionType,
			"sessionId":   sessionID,
		},
	}
}

// NewSOSActivatedEvent creates an event when SOS mode is activated.
func NewSOSActivatedEvent(userID, tenantID, correlationID string) Event {
	return Event{
		Type:          EventAffirmationSOSActivated,
		UserID:        userID,
		TenantID:      tenantID,
		Timestamp:     time.Now().UTC(),
		CorrelationID: correlationID,
		Data:          map[string]interface{}{},
	}
}

// NewSOSCompletedEvent creates an event when SOS mode session is completed.
func NewSOSCompletedEvent(userID, tenantID, correlationID, sessionID string) Event {
	return Event{
		Type:          EventAffirmationSOSCompleted,
		UserID:        userID,
		TenantID:      tenantID,
		Timestamp:     time.Now().UTC(),
		CorrelationID: correlationID,
		Data: map[string]interface{}{
			"sessionId": sessionID,
		},
	}
}

// NewMilestoneAchievedEvent creates an event when a milestone is achieved.
func NewMilestoneAchievedEvent(userID, tenantID, correlationID, milestone string, count int) Event {
	return Event{
		Type:          EventAffirmationMilestoneAchieved,
		UserID:        userID,
		TenantID:      tenantID,
		Timestamp:     time.Now().UTC(),
		CorrelationID: correlationID,
		Data: map[string]interface{}{
			"milestone": milestone,
			"count":     count,
		},
	}
}

// NewMoodWorseningEvent creates an event when consecutive mood declines are detected.
func NewMoodWorseningEvent(userID, tenantID, correlationID string, consecutiveDeclines int) Event {
	return Event{
		Type:          EventAffirmationMoodWorsening,
		UserID:        userID,
		TenantID:      tenantID,
		Timestamp:     time.Now().UTC(),
		CorrelationID: correlationID,
		Data: map[string]interface{}{
			"consecutiveDeclines": consecutiveDeclines,
		},
	}
}

// NewCrisisDetectedEvent creates an event when crisis indicators are detected.
func NewCrisisDetectedEvent(userID, tenantID, correlationID string) Event {
	return Event{
		Type:          EventAffirmationCrisisDetected,
		UserID:        userID,
		TenantID:      tenantID,
		Timestamp:     time.Now().UTC(),
		CorrelationID: correlationID,
		Data:          map[string]interface{}{},
	}
}

// NewRelapseLevelLockEvent creates an event when relapse level is locked.
func NewRelapseLevelLockEvent(userID, tenantID, correlationID string) Event {
	return Event{
		Type:          EventAffirmationRelapseLevelLock,
		UserID:        userID,
		TenantID:      tenantID,
		Timestamp:     time.Now().UTC(),
		CorrelationID: correlationID,
		Data:          map[string]interface{}{},
	}
}
