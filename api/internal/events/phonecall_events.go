// internal/events/phonecall_events.go
package events

import (
	"context"
	"fmt"
	"time"

	"github.com/regalrecovery/api/internal/domain/phonecalls"
)

const (
	// EventPhoneCallCreated is published when a phone call is logged.
	EventPhoneCallCreated EventType = "phonecall.created"

	// EventPhoneCallDeleted is published when a phone call is deleted.
	EventPhoneCallDeleted EventType = "phonecall.deleted"

	// EventPhoneCallIsolationWarning is published when the isolation threshold is reached.
	EventPhoneCallIsolationWarning EventType = "phonecall.isolation-warning"

	// EventPhoneCallStreakMilestone is published when a streak milestone is hit.
	EventPhoneCallStreakMilestone EventType = "phonecall.streak-milestone"
)

// PhoneCallEventPublisher publishes phone call domain events.
type PhoneCallEventPublisher struct {
	publisher Publisher
}

// NewPhoneCallEventPublisher creates a new PhoneCallEventPublisher.
func NewPhoneCallEventPublisher(publisher Publisher) *PhoneCallEventPublisher {
	return &PhoneCallEventPublisher{publisher: publisher}
}

// PublishCallCreated publishes a phonecall.created event.
func (p *PhoneCallEventPublisher) PublishCallCreated(ctx context.Context, call *phonecalls.PhoneCall, correlationID string) error {
	event := Event{
		Type:          EventPhoneCallCreated,
		UserID:        call.UserID,
		TenantID:      call.TenantID,
		Timestamp:     time.Now().UTC(),
		CorrelationID: correlationID,
		Data: map[string]interface{}{
			"callId":      call.CallID,
			"direction":   string(call.Direction),
			"contactType": string(call.ContactType),
			"connected":   call.Connected,
			"timestamp":   call.Timestamp.Format(time.RFC3339),
		},
	}

	if err := p.publisher.Publish(ctx, event); err != nil {
		return fmt.Errorf("publishing phonecall.created event: %w", err)
	}

	return nil
}

// PublishCallDeleted publishes a phonecall.deleted event.
func (p *PhoneCallEventPublisher) PublishCallDeleted(ctx context.Context, userID, tenantID, callID, correlationID string) error {
	event := Event{
		Type:          EventPhoneCallDeleted,
		UserID:        userID,
		TenantID:      tenantID,
		Timestamp:     time.Now().UTC(),
		CorrelationID: correlationID,
		Data: map[string]interface{}{
			"callId": callID,
		},
	}

	if err := p.publisher.Publish(ctx, event); err != nil {
		return fmt.Errorf("publishing phonecall.deleted event: %w", err)
	}

	return nil
}

// PublishIsolationWarning publishes a phonecall.isolation-warning event.
func (p *PhoneCallEventPublisher) PublishIsolationWarning(ctx context.Context, userID, tenantID string, daysSinceLastCall int, correlationID string) error {
	event := Event{
		Type:          EventPhoneCallIsolationWarning,
		UserID:        userID,
		TenantID:      tenantID,
		Timestamp:     time.Now().UTC(),
		CorrelationID: correlationID,
		Data: map[string]interface{}{
			"daysSinceLastCall": daysSinceLastCall,
			"message":           fmt.Sprintf("It's been %d days since you last connected with someone by phone. Isolation is addiction's favorite weapon. Who could you call right now?", daysSinceLastCall),
		},
	}

	if err := p.publisher.Publish(ctx, event); err != nil {
		return fmt.Errorf("publishing phonecall.isolation-warning event: %w", err)
	}

	return nil
}

// PublishStreakMilestone publishes a phonecall.streak-milestone event.
func (p *PhoneCallEventPublisher) PublishStreakMilestone(ctx context.Context, userID, tenantID string, streakDays int, correlationID string) error {
	event := Event{
		Type:          EventPhoneCallStreakMilestone,
		UserID:        userID,
		TenantID:      tenantID,
		Timestamp:     time.Now().UTC(),
		CorrelationID: correlationID,
		Data: map[string]interface{}{
			"streakDays": streakDays,
			"message":    fmt.Sprintf("%d consecutive days of phone contact. Staying connected is one of the bravest things you can do in recovery.", streakDays),
		},
	}

	if err := p.publisher.Publish(ctx, event); err != nil {
		return fmt.Errorf("publishing phonecall.streak-milestone event: %w", err)
	}

	return nil
}
