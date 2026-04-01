// internal/events/sns.go
package events

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/sns"
	"github.com/aws/aws-sdk-go-v2/service/sns/types"
)

// SNSPublisher publishes domain events to AWS SNS.
type SNSPublisher struct {
	client   *sns.Client
	topicARN string
}

// NewSNSPublisher creates a new SNS publisher.
// If topicARN is empty, events are logged instead of published (local dev mode).
func NewSNSPublisher(cfg aws.Config, topicARN string) *SNSPublisher {
	return &SNSPublisher{
		client:   sns.NewFromConfig(cfg),
		topicARN: topicARN,
	}
}

// Publish publishes an event to SNS. In local dev mode (empty topicARN), logs the event instead.
func (p *SNSPublisher) Publish(ctx context.Context, event Event) error {
	// Local dev mode: log instead of publishing
	if p.topicARN == "" {
		eventJSON, _ := json.MarshalIndent(event, "", "  ")
		slog.Info("event_published_local",
			slog.String("event_type", string(event.Type)),
			slog.String("user_id", event.UserID),
			slog.String("tenant_id", event.TenantID),
			slog.String("correlation_id", event.CorrelationID),
			slog.String("event", string(eventJSON)),
		)
		return nil
	}

	// Serialize event to JSON
	eventJSON, err := json.Marshal(event)
	if err != nil {
		return fmt.Errorf("failed to marshal event: %w", err)
	}

	// Publish to SNS with event type as message attribute
	_, err = p.client.Publish(ctx, &sns.PublishInput{
		TopicArn: aws.String(p.topicARN),
		Message:  aws.String(string(eventJSON)),
		MessageAttributes: map[string]types.MessageAttributeValue{
			"event_type": {
				DataType:    aws.String("String"),
				StringValue: aws.String(string(event.Type)),
			},
			"tenant_id": {
				DataType:    aws.String("String"),
				StringValue: aws.String(event.TenantID),
			},
			"user_id": {
				DataType:    aws.String("String"),
				StringValue: aws.String(event.UserID),
			},
		},
	})

	if err != nil {
		return fmt.Errorf("failed to publish event to SNS: %w", err)
	}

	slog.Info("event_published",
		slog.String("event_type", string(event.Type)),
		slog.String("user_id", event.UserID),
		slog.String("tenant_id", event.TenantID),
		slog.String("correlation_id", event.CorrelationID),
	)

	return nil
}
