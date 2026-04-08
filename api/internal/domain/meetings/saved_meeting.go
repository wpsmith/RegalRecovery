// internal/domain/meetings/saved_meeting.go
package meetings

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// SavedMeetingService handles saved meeting template business logic.
type SavedMeetingService struct {
	repo SavedMeetingRepository
}

// NewSavedMeetingService creates a new SavedMeetingService.
func NewSavedMeetingService(repo SavedMeetingRepository) *SavedMeetingService {
	return &SavedMeetingService{repo: repo}
}

// CreateSavedMeeting creates a new saved meeting template.
func (s *SavedMeetingService) CreateSavedMeeting(ctx context.Context, userID, tenantID string, req *CreateSavedMeetingRequest) (*SavedMeeting, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required: %w", ErrInvalidInput)
	}

	if err := ValidateCreateSavedMeetingRequest(req); err != nil {
		return nil, err
	}

	now := time.Now().UTC()
	saved := &SavedMeeting{
		SavedMeetingID:        "sm_" + uuid.New().String()[:8],
		UserID:                userID,
		TenantID:              tenantID,
		Name:                  req.Name,
		MeetingType:           req.MeetingType,
		CustomTypeLabel:       req.CustomTypeLabel,
		Location:              req.Location,
		Schedule:              req.Schedule,
		ReminderMinutesBefore: req.ReminderMinutesBefore,
		IsActive:              true,
		CreatedAt:             now,
		ModifiedAt:            now,
	}

	if err := s.repo.Create(ctx, saved); err != nil {
		return nil, fmt.Errorf("creating saved meeting: %w", err)
	}

	return saved, nil
}

// GetSavedMeeting retrieves a saved meeting by ID.
func (s *SavedMeetingService) GetSavedMeeting(ctx context.Context, userID, savedMeetingID string) (*SavedMeeting, error) {
	if userID == "" || savedMeetingID == "" {
		return nil, fmt.Errorf("user ID and saved meeting ID are required: %w", ErrInvalidInput)
	}

	saved, err := s.repo.GetByID(ctx, userID, savedMeetingID)
	if err != nil {
		return nil, fmt.Errorf("retrieving saved meeting: %w", err)
	}
	if saved == nil {
		return nil, ErrSavedMeetingNotFound
	}

	return saved, nil
}

// ListSavedMeetings retrieves all active saved meetings for a user, sorted by name.
func (s *SavedMeetingService) ListSavedMeetings(ctx context.Context, userID string) ([]*SavedMeeting, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required: %w", ErrInvalidInput)
	}

	meetings, err := s.repo.ListActive(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("listing saved meetings: %w", err)
	}

	return meetings, nil
}

// UpdateSavedMeeting updates a saved meeting template.
// Previously logged meetings are not retroactively changed.
func (s *SavedMeetingService) UpdateSavedMeeting(ctx context.Context, userID, savedMeetingID string, req *UpdateSavedMeetingRequest) (*SavedMeeting, error) {
	if userID == "" || savedMeetingID == "" {
		return nil, fmt.Errorf("user ID and saved meeting ID are required: %w", ErrInvalidInput)
	}

	if err := ValidateUpdateSavedMeetingRequest(req); err != nil {
		return nil, err
	}

	existing, err := s.repo.GetByID(ctx, userID, savedMeetingID)
	if err != nil {
		return nil, fmt.Errorf("retrieving saved meeting: %w", err)
	}
	if existing == nil {
		return nil, ErrSavedMeetingNotFound
	}

	// Apply updates.
	if req.Name != nil {
		existing.Name = *req.Name
	}
	if req.MeetingType != nil {
		existing.MeetingType = *req.MeetingType
	}
	if req.CustomTypeLabel != nil {
		existing.CustomTypeLabel = req.CustomTypeLabel
	}
	if req.Location != nil {
		existing.Location = req.Location
	}
	if req.Schedule != nil {
		existing.Schedule = req.Schedule
	}
	if req.ReminderMinutesBefore != nil {
		existing.ReminderMinutesBefore = req.ReminderMinutesBefore
	}

	existing.ModifiedAt = time.Now().UTC()

	if err := s.repo.Update(ctx, existing); err != nil {
		return nil, fmt.Errorf("updating saved meeting: %w", err)
	}

	return existing, nil
}

// DeleteSavedMeeting soft-deletes a saved meeting template.
// Sets isActive to false; previously logged meetings are unaffected.
func (s *SavedMeetingService) DeleteSavedMeeting(ctx context.Context, userID, savedMeetingID string) error {
	if userID == "" || savedMeetingID == "" {
		return fmt.Errorf("user ID and saved meeting ID are required: %w", ErrInvalidInput)
	}

	existing, err := s.repo.GetByID(ctx, userID, savedMeetingID)
	if err != nil {
		return fmt.Errorf("retrieving saved meeting: %w", err)
	}
	if existing == nil {
		return ErrSavedMeetingNotFound
	}

	if err := s.repo.SoftDelete(ctx, userID, savedMeetingID); err != nil {
		return fmt.Errorf("soft-deleting saved meeting: %w", err)
	}

	return nil
}
