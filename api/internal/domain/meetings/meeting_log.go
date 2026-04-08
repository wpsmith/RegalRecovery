// internal/domain/meetings/meeting_log.go
package meetings

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// MeetingLogService handles meeting log business logic.
type MeetingLogService struct {
	meetingRepo MeetingRepository
	savedRepo   SavedMeetingRepository
	publisher   EventPublisher
}

// NewMeetingLogService creates a new MeetingLogService.
func NewMeetingLogService(meetingRepo MeetingRepository, savedRepo SavedMeetingRepository, publisher EventPublisher) *MeetingLogService {
	return &MeetingLogService{
		meetingRepo: meetingRepo,
		savedRepo:   savedRepo,
		publisher:   publisher,
	}
}

// CreateMeetingLog creates a new meeting log entry.
// If savedMeetingId is provided, pre-fills fields from the saved meeting template.
// Creates a dual-write calendar activity and publishes a commitment event.
func (s *MeetingLogService) CreateMeetingLog(ctx context.Context, userID, tenantID string, req *CreateMeetingLogRequest) (*MeetingLog, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required: %w", ErrInvalidInput)
	}

	// If logging from a saved meeting template, pre-fill fields.
	if req.SavedMeetingID != nil && *req.SavedMeetingID != "" {
		saved, err := s.savedRepo.GetByID(ctx, userID, *req.SavedMeetingID)
		if err != nil {
			return nil, fmt.Errorf("retrieving saved meeting: %w", err)
		}
		if saved == nil {
			return nil, fmt.Errorf("saved meeting not found: %w", ErrSavedMeetingNotFound)
		}

		// Pre-fill from template if not explicitly provided in request.
		// Copy values (not pointers) to ensure independence from the template.
		if req.MeetingType == "" {
			req.MeetingType = saved.MeetingType
		}
		if req.Name == nil {
			nameCopy := saved.Name
			req.Name = &nameCopy
		}
		if req.Location == nil && saved.Location != nil {
			locCopy := *saved.Location
			req.Location = &locCopy
		}
		if req.CustomTypeLabel == nil && saved.CustomTypeLabel != nil {
			labelCopy := *saved.CustomTypeLabel
			req.CustomTypeLabel = &labelCopy
		}
	}

	if err := ValidateCreateMeetingLogRequest(req); err != nil {
		return nil, err
	}

	now := time.Now().UTC()
	meeting := &MeetingLog{
		MeetingID:       "mt_" + uuid.New().String()[:8],
		UserID:          userID,
		TenantID:        tenantID,
		Timestamp:       req.Timestamp,
		MeetingType:     req.MeetingType,
		CustomTypeLabel: req.CustomTypeLabel,
		Name:            req.Name,
		Location:        req.Location,
		DurationMinutes: req.DurationMinutes,
		Notes:           req.Notes,
		Status:          MeetingStatusAttended,
		SavedMeetingID:  req.SavedMeetingID,
		CreatedAt:       now,
		ModifiedAt:      now,
	}

	if err := s.meetingRepo.Create(ctx, meeting); err != nil {
		return nil, fmt.Errorf("creating meeting log: %w", err)
	}

	// Publish event for commitment tracking (best-effort).
	if s.publisher != nil {
		_ = s.publisher.PublishMeetingCreated(ctx, meeting)
	}

	return meeting, nil
}

// GetMeetingLog retrieves a meeting log by ID.
func (s *MeetingLogService) GetMeetingLog(ctx context.Context, userID, meetingID string) (*MeetingLog, error) {
	if userID == "" || meetingID == "" {
		return nil, fmt.Errorf("user ID and meeting ID are required: %w", ErrInvalidInput)
	}

	meeting, err := s.meetingRepo.GetByID(ctx, userID, meetingID)
	if err != nil {
		return nil, fmt.Errorf("retrieving meeting log: %w", err)
	}
	if meeting == nil {
		return nil, ErrMeetingNotFound
	}

	return meeting, nil
}

// ListMeetingLogs retrieves meeting logs for a user with filters and pagination.
func (s *MeetingLogService) ListMeetingLogs(ctx context.Context, userID string, filter ListMeetingLogsFilter) ([]*MeetingLog, string, error) {
	if userID == "" {
		return nil, "", fmt.Errorf("user ID is required: %w", ErrInvalidInput)
	}

	// Default limit to 50, max 100.
	if filter.Limit <= 0 {
		filter.Limit = 50
	}
	if filter.Limit > 100 {
		filter.Limit = 100
	}

	// Default sort to newest first.
	if filter.Sort == "" {
		filter.Sort = "-timestamp"
	}

	meetings, nextCursor, err := s.meetingRepo.ListByUser(ctx, userID, filter)
	if err != nil {
		return nil, "", fmt.Errorf("listing meeting logs: %w", err)
	}

	return meetings, nextCursor, nil
}

// UpdateMeetingLog updates a meeting log's mutable fields.
// The timestamp field is immutable and cannot be changed (FR2.7).
func (s *MeetingLogService) UpdateMeetingLog(ctx context.Context, userID, meetingID string, req *UpdateMeetingLogRequest) (*MeetingLog, error) {
	if userID == "" || meetingID == "" {
		return nil, fmt.Errorf("user ID and meeting ID are required: %w", ErrInvalidInput)
	}

	if err := ValidateUpdateMeetingLogRequest(req); err != nil {
		return nil, err
	}

	existing, err := s.meetingRepo.GetByID(ctx, userID, meetingID)
	if err != nil {
		return nil, fmt.Errorf("retrieving meeting log: %w", err)
	}
	if existing == nil {
		return nil, ErrMeetingNotFound
	}

	// Apply updates to mutable fields only.
	if req.MeetingType != nil {
		existing.MeetingType = *req.MeetingType
	}
	if req.CustomTypeLabel != nil {
		existing.CustomTypeLabel = req.CustomTypeLabel
	}
	if req.Name != nil {
		existing.Name = req.Name
	}
	if req.Location != nil {
		existing.Location = req.Location
	}
	if req.DurationMinutes != nil {
		existing.DurationMinutes = req.DurationMinutes
	}
	if req.Notes != nil {
		existing.Notes = req.Notes
	}
	if req.Status != nil {
		existing.Status = *req.Status
	}

	existing.ModifiedAt = time.Now().UTC()

	if err := s.meetingRepo.Update(ctx, existing); err != nil {
		return nil, fmt.Errorf("updating meeting log: %w", err)
	}

	return existing, nil
}

// DeleteMeetingLog deletes a meeting log and its calendar activity dual-write.
func (s *MeetingLogService) DeleteMeetingLog(ctx context.Context, userID, meetingID string) error {
	if userID == "" || meetingID == "" {
		return fmt.Errorf("user ID and meeting ID are required: %w", ErrInvalidInput)
	}

	existing, err := s.meetingRepo.GetByID(ctx, userID, meetingID)
	if err != nil {
		return fmt.Errorf("retrieving meeting log: %w", err)
	}
	if existing == nil {
		return ErrMeetingNotFound
	}

	if err := s.meetingRepo.Delete(ctx, userID, meetingID); err != nil {
		return fmt.Errorf("deleting meeting log: %w", err)
	}

	return nil
}
