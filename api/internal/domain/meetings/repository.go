// internal/domain/meetings/repository.go
package meetings

import (
	"context"
	"time"
)

// MeetingRepository defines the interface for meeting log data persistence.
type MeetingRepository interface {
	// Create creates a new meeting log entry and its dual-write calendar activity.
	Create(ctx context.Context, meeting *MeetingLog) error

	// GetByID retrieves a meeting log by its meetingId.
	GetByID(ctx context.Context, userID, meetingID string) (*MeetingLog, error)

	// ListByUser retrieves meeting logs for a user with optional filters and cursor pagination.
	ListByUser(ctx context.Context, userID string, filter ListMeetingLogsFilter) ([]*MeetingLog, string, error)

	// Update updates an existing meeting log's mutable fields.
	Update(ctx context.Context, meeting *MeetingLog) error

	// Delete permanently removes a meeting log and its calendar activity dual-write.
	Delete(ctx context.Context, userID, meetingID string) error

	// GetMeetingsInRange retrieves all meeting logs for a user within a date range.
	// Used for summary calculations.
	GetMeetingsInRange(ctx context.Context, userID string, start, end time.Time) ([]*MeetingLog, error)
}

// SavedMeetingRepository defines the interface for saved meeting template persistence.
type SavedMeetingRepository interface {
	// Create creates a new saved meeting template.
	Create(ctx context.Context, saved *SavedMeeting) error

	// GetByID retrieves a saved meeting by its savedMeetingId.
	GetByID(ctx context.Context, userID, savedMeetingID string) (*SavedMeeting, error)

	// ListActive retrieves all active saved meetings for a user, sorted by name.
	ListActive(ctx context.Context, userID string) ([]*SavedMeeting, error)

	// Update updates an existing saved meeting template.
	Update(ctx context.Context, saved *SavedMeeting) error

	// SoftDelete marks a saved meeting as inactive (isActive=false).
	SoftDelete(ctx context.Context, userID, savedMeetingID string) error
}

// EventPublisher defines the interface for publishing meeting-related domain events.
type EventPublisher interface {
	// PublishMeetingCreated publishes an event when a meeting is logged,
	// for commitment tracking progress updates.
	PublishMeetingCreated(ctx context.Context, meeting *MeetingLog) error
}
