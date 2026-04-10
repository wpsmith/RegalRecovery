// internal/events/threecircles_events.go
package events

import "time"

// Three Circles event types
const (
	EventThreeCirclesSetCommitted       EventType = "threecircles.set.committed"
	EventThreeCirclesSetEdited          EventType = "threecircles.set.edited"
	EventThreeCirclesShareCreated       EventType = "threecircles.share.created"
	EventThreeCirclesCommentAdded       EventType = "threecircles.comment.added"
	EventThreeCirclesDriftDetected      EventType = "threecircles.drift.detected"
	EventThreeCirclesReviewCompleted    EventType = "threecircles.review.completed"
	EventThreeCirclesStarterPackApplied EventType = "threecircles.starterpack.applied"
	EventThreeCirclesOnboardingComplete EventType = "threecircles.onboarding.completed"
)

// NewSetCommittedEvent creates an event when a circle set is committed.
func NewSetCommittedEvent(userID, tenantID, correlationID, setID string, versionNumber int) Event {
	return Event{
		Type:          EventThreeCirclesSetCommitted,
		UserID:        userID,
		TenantID:      tenantID,
		Timestamp:     time.Now().UTC(),
		CorrelationID: correlationID,
		Data: map[string]interface{}{
			"setId":         setID,
			"versionNumber": versionNumber,
		},
	}
}

// NewSetEditedEvent creates an event when a circle set is edited.
func NewSetEditedEvent(userID, tenantID, correlationID, setID string, changeType string, versionNumber int) Event {
	return Event{
		Type:          EventThreeCirclesSetEdited,
		UserID:        userID,
		TenantID:      tenantID,
		Timestamp:     time.Now().UTC(),
		CorrelationID: correlationID,
		Data: map[string]interface{}{
			"setId":         setID,
			"changeType":    changeType,
			"versionNumber": versionNumber,
		},
	}
}

// NewShareCreatedEvent creates an event when a circle set is shared.
func NewShareCreatedEvent(userID, tenantID, correlationID, setID, shareCode string, expiresIn int) Event {
	return Event{
		Type:          EventThreeCirclesShareCreated,
		UserID:        userID,
		TenantID:      tenantID,
		Timestamp:     time.Now().UTC(),
		CorrelationID: correlationID,
		Data: map[string]interface{}{
			"setId":     setID,
			"shareCode": shareCode,
			"expiresIn": expiresIn,
		},
	}
}

// NewCommentAddedEvent creates an event when a comment is added to a shared set.
func NewCommentAddedEvent(userID, tenantID, correlationID, setID, shareCode, commentID, commenterName string, isOwner bool) Event {
	return Event{
		Type:          EventThreeCirclesCommentAdded,
		UserID:        userID,
		TenantID:      tenantID,
		Timestamp:     time.Now().UTC(),
		CorrelationID: correlationID,
		Data: map[string]interface{}{
			"setId":         setID,
			"shareCode":     shareCode,
			"commentId":     commentID,
			"commenterName": commenterName,
			"isOwner":       isOwner,
		},
	}
}

// NewDriftDetectedEvent creates an event when drift is detected in a user's circle patterns.
func NewDriftDetectedEvent(userID, tenantID, correlationID, setID, alertID string, middleCircleDays int) Event {
	return Event{
		Type:          EventThreeCirclesDriftDetected,
		UserID:        userID,
		TenantID:      tenantID,
		Timestamp:     time.Now().UTC(),
		CorrelationID: correlationID,
		Data: map[string]interface{}{
			"setId":            setID,
			"alertId":          alertID,
			"middleCircleDays": middleCircleDays,
		},
	}
}

// NewReviewCompletedEvent creates an event when a user completes a Three Circles review.
func NewReviewCompletedEvent(userID, tenantID, correlationID, reviewID, setID string, changesApplied bool) Event {
	return Event{
		Type:          EventThreeCirclesReviewCompleted,
		UserID:        userID,
		TenantID:      tenantID,
		Timestamp:     time.Now().UTC(),
		CorrelationID: correlationID,
		Data: map[string]interface{}{
			"reviewId":       reviewID,
			"setId":          setID,
			"changesApplied": changesApplied,
		},
	}
}

// NewStarterPackAppliedEvent creates an event when a starter pack is applied to a circle set.
func NewStarterPackAppliedEvent(userID, tenantID, correlationID, setID, packID string, itemsAdded int) Event {
	return Event{
		Type:          EventThreeCirclesStarterPackApplied,
		UserID:        userID,
		TenantID:      tenantID,
		Timestamp:     time.Now().UTC(),
		CorrelationID: correlationID,
		Data: map[string]interface{}{
			"setId":      setID,
			"packId":     packID,
			"itemsAdded": itemsAdded,
		},
	}
}

// NewOnboardingCompletedEvent creates an event when onboarding is completed.
func NewOnboardingCompletedEvent(userID, tenantID, correlationID, flowID, setID, mode string) Event {
	return Event{
		Type:          EventThreeCirclesOnboardingComplete,
		UserID:        userID,
		TenantID:      tenantID,
		Timestamp:     time.Now().UTC(),
		CorrelationID: correlationID,
		Data: map[string]interface{}{
			"flowId": flowID,
			"setId":  setID,
			"mode":   mode,
		},
	}
}
