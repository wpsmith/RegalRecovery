// internal/events/publisher.go
package events

import "context"

// Publisher defines the interface for publishing domain events.
type Publisher interface {
	Publish(ctx context.Context, event Event) error
}
