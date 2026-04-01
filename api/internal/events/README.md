# Events Package

Production-ready domain event publishing for the Regal Recovery Go backend.

## Overview

This package provides event publishing infrastructure for domain events using AWS SNS, with local development logging fallback.

## Components

### Event Types (`types.go`)

Domain event type definitions:
```go
type EventType string

const (
    EventMilestoneAchieved EventType = "milestone.achieved"
    EventRelapseRecorded   EventType = "relapse.recorded"
    EventStreakUpdated     EventType = "streak.updated"
    EventCheckInCompleted  EventType = "checkin.completed"
    EventActivityLogged    EventType = "activity.logged"
)
```

**Event Structure:**
```go
type Event struct {
    Type          EventType              // Event type identifier
    UserID        string                 // User who triggered the event
    TenantID      string                 // Tenant isolation
    Timestamp     time.Time              // Event timestamp
    CorrelationID string                 // Distributed tracing
    Data          map[string]interface{} // Event-specific payload
}
```

### Publisher Interface (`publisher.go`)

Abstract event publishing:
```go
type Publisher interface {
    Publish(ctx context.Context, event Event) error
}
```

Allows for different implementations (SNS, SQS, in-memory, etc.).

### SNS Publisher (`sns.go`)

AWS SNS implementation:
- Publishes events to an SNS topic
- Includes message attributes for filtering (event_type, tenant_id, user_id)
- **Local dev mode**: If `topicARN` is empty, logs events instead of publishing

**Usage:**
```go
// Production
cfg, _ := config.LoadDefaultConfig(ctx)
publisher := events.NewSNSPublisher(cfg, "arn:aws:sns:us-east-1:123456789012:regal-recovery-events")

// Local dev (empty topicARN)
publisher := events.NewSNSPublisher(cfg, "")

// Publish event
err := publisher.Publish(ctx, events.Event{
    Type:          events.EventMilestoneAchieved,
    UserID:        "u_alex",
    TenantID:      "DEFAULT",
    Timestamp:     time.Now(),
    CorrelationID: middleware.GetCorrelationID(ctx),
    Data: map[string]interface{}{
        "milestone": "30_days",
        "currentStreak": 30,
    },
})
```

## Event-Driven Patterns

### 1. Milestone Achievement
```go
events.Event{
    Type:   events.EventMilestoneAchieved,
    UserID: userID,
    Data: map[string]interface{}{
        "milestone":     "30_days",
        "currentStreak": 30,
        "achievedAt":    time.Now(),
    },
}
```

Triggers:
- Push notification
- Badge unlock
- Recovery Health Score recalculation

### 2. Relapse Recorded
```go
events.Event{
    Type:   events.EventRelapseRecorded,
    UserID: userID,
    Data: map[string]interface{}{
        "previousStreak": 45,
        "triggers":       []string{"stress", "loneliness"},
        "recordedAt":     time.Now(),
    },
}
```

Triggers:
- Post-mortem form suggestion
- Sponsor notification (if permission granted)
- Streak reset
- Analytics update

### 3. Check-In Completed
```go
events.Event{
    Type:   events.EventCheckInCompleted,
    UserID: userID,
    Data: map[string]interface{}{
        "checkInType": "daily",
        "fanos":       map[string]int{"F": 4, "A": 3, "N": 2, "O": 5, "S": 4},
        "completedAt": time.Now(),
    },
}
```

Triggers:
- Recovery Health Score update
- Trend analysis
- Milestone detection (e.g., 100th check-in)

## SNS Message Attributes

Events are published with the following message attributes for SQS filtering:
- `event_type`: Event type string (e.g., "milestone.achieved")
- `tenant_id`: Tenant ID for isolation
- `user_id`: User ID for user-specific subscriptions

## Local Development

SNS publisher automatically detects local dev mode (empty topicARN) and logs events:
```go
publisher := events.NewSNSPublisher(cfg, "") // Empty topicARN

// Events are logged with slog instead of published
```

Log output:
```json
{
  "level": "INFO",
  "msg": "event_published_local",
  "event_type": "milestone.achieved",
  "user_id": "u_alex",
  "tenant_id": "DEFAULT",
  "correlation_id": "uuid",
  "event": { ... }
}
```

## Production Considerations

1. **SNS Topic ARN**: Load from environment variable or SSM Parameter Store
2. **At-Least-Once Delivery**: Events may be delivered multiple times; consumers must be idempotent
3. **Error Handling**: Failed publishes should be logged and retried (consider using SQS dead-letter queue)
4. **Event Schema Versioning**: Include `version` field in `Data` if event schema changes
5. **Filtering**: Use SNS subscription filter policies to route events to specific SQS queues
6. **Monitoring**: Track event publish failures and latency in CloudWatch

## Event Consumers (Future)

Potential consumers for each event type:
- **Notification Service**: milestone.achieved, relapse.recorded
- **Analytics Service**: streak.updated, checkin.completed, activity.logged
- **Sponsorship Service**: relapse.recorded (if sponsor notification enabled)
- **Badge Service**: milestone.achieved

## Testing

Mock the Publisher interface for unit tests:
```go
type MockPublisher struct {
    PublishedEvents []events.Event
}

func (m *MockPublisher) Publish(ctx context.Context, event events.Event) error {
    m.PublishedEvents = append(m.PublishedEvents, event)
    return nil
}
```

Integration tests can use LocalStack SNS.
