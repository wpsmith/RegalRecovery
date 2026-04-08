// internal/events/meetings/publisher.go
package meetings

import (
	"context"
	"time"

	domain "github.com/regalrecovery/api/internal/domain/meetings"
	"github.com/regalrecovery/api/internal/events"
	"github.com/regalrecovery/api/internal/middleware"
)

// EventType constants for meeting-related events.
const (
	EventMeetingCreated events.EventType = "meeting.created"
)

// MeetingEventPublisher publishes meeting-related domain events.
type MeetingEventPublisher struct {
	publisher events.Publisher
}

// NewMeetingEventPublisher creates a new MeetingEventPublisher.
func NewMeetingEventPublisher(publisher events.Publisher) *MeetingEventPublisher {
	return &MeetingEventPublisher{publisher: publisher}
}

// PublishMeetingCreated publishes an event when a meeting is logged.
// This event is consumed by the commitments tracking system to update progress.
func (p *MeetingEventPublisher) PublishMeetingCreated(ctx context.Context, meeting *domain.MeetingLog) error {
	correlationID := middleware.GetCorrelationID(ctx)

	event := events.Event{
		Type:          EventMeetingCreated,
		UserID:        meeting.UserID,
		TenantID:      meeting.TenantID,
		Timestamp:     time.Now().UTC(),
		CorrelationID: correlationID,
		Data: map[string]interface{}{
			"meetingId":   meeting.MeetingID,
			"meetingType": string(meeting.MeetingType),
			"timestamp":   meeting.Timestamp.Format(time.RFC3339),
			"status":      string(meeting.Status),
		},
	}

	return p.publisher.Publish(ctx, event)
}
