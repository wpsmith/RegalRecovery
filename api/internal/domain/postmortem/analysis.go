// internal/domain/postmortem/analysis.go
package postmortem

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// Domain errors.
var (
	ErrNotFound         = errors.New("post-mortem not found")
	ErrPermissionDenied = errors.New("permission denied")
)

// PostMortemRepository defines the interface for post-mortem data persistence.
type PostMortemRepository interface {
	Create(ctx context.Context, analysis *PostMortemAnalysis) error
	GetByID(ctx context.Context, userID, analysisID string) (*PostMortemAnalysis, error)
	GetByRelapseID(ctx context.Context, userID, relapseID string) (*PostMortemAnalysis, error)
	List(ctx context.Context, userID string, filter ListFilter) (*PaginatedResult, error)
	FindDrafts(ctx context.Context, userID string) ([]*PostMortemAnalysis, error)
	Update(ctx context.Context, analysis *PostMortemAnalysis) error
	Delete(ctx context.Context, userID, analysisID string) error
	GetInsightsData(ctx context.Context, userID string, filter *InsightsFilter) ([]*PostMortemAnalysis, error)
	GetSharedWith(ctx context.Context, contactID string) ([]*PostMortemAnalysis, error)
	WriteCalendarActivity(ctx context.Context, entry *CalendarActivityEntry) error
}

// PermissionChecker checks if a contact has permission to access data.
type PermissionChecker interface {
	HasPermission(ctx context.Context, userID, contactID, dataCategory string) (bool, error)
}

// PostMortemService handles post-mortem analysis business logic.
type PostMortemService struct {
	repo        PostMortemRepository
	permissions PermissionChecker
}

// NewPostMortemService creates a new PostMortemService with required dependencies.
func NewPostMortemService(repo PostMortemRepository, permissions PermissionChecker) *PostMortemService {
	return &PostMortemService{
		repo:        repo,
		permissions: permissions,
	}
}

// CreateAnalysis creates a new post-mortem analysis in draft status.
func (s *PostMortemService) CreateAnalysis(ctx context.Context, userID, tenantID string, eventType string, relapseID, addictionID *string, timestamp time.Time, sections *Sections) (*PostMortemAnalysis, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required")
	}

	if err := ValidateEventType(eventType); err != nil {
		return nil, err
	}
	if err := ValidateEventTypeRelapseLink(eventType, relapseID); err != nil {
		return nil, err
	}
	if sections != nil {
		if err := ValidateSections(sections); err != nil {
			return nil, err
		}
	}

	now := time.Now().UTC()
	analysisID := "pm_" + uuid.New().String()[:8]

	analysis := &PostMortemAnalysis{
		AnalysisID: analysisID,
		UserID:     userID,
		TenantID:   tenantID,
		Status:     StatusDraft,
		EventType:  eventType,
		RelapseID:  relapseID,
		AddictionID: addictionID,
		Timestamp:  timestamp,
		CreatedAt:  now,
		ModifiedAt: now,
	}

	if sections != nil {
		analysis.Sections = *sections
	}

	if err := s.repo.Create(ctx, analysis); err != nil {
		return nil, fmt.Errorf("creating post-mortem: %w", err)
	}

	return analysis, nil
}

// GetAnalysis retrieves a post-mortem analysis by ID. Checks ownership or shared access.
func (s *PostMortemService) GetAnalysis(ctx context.Context, requestingUserID, ownerUserID, analysisID string) (*PostMortemAnalysis, error) {
	analysis, err := s.repo.GetByID(ctx, ownerUserID, analysisID)
	if err != nil {
		return nil, fmt.Errorf("retrieving post-mortem: %w", err)
	}
	if analysis == nil {
		return nil, ErrNotFound
	}

	// Owner always has access.
	if requestingUserID == ownerUserID {
		return analysis, nil
	}

	// Check if shared with the requesting user and they have permission.
	for _, share := range analysis.Sharing.SharedWith {
		if share.ContactID == requestingUserID {
			hasPermission, err := s.permissions.HasPermission(ctx, ownerUserID, requestingUserID, "post-mortem:read")
			if err != nil {
				return nil, fmt.Errorf("checking permission: %w", err)
			}
			if hasPermission {
				return analysis, nil
			}
		}
	}

	// Return not found (not 403) to hide data existence per PM-AC7.5.
	return nil, ErrNotFound
}

// ListAnalyses lists post-mortem analyses for a user with filters and pagination.
func (s *PostMortemService) ListAnalyses(ctx context.Context, userID string, filter ListFilter) (*PaginatedResult, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required")
	}
	if filter.Limit <= 0 {
		filter.Limit = 50
	}
	if filter.Limit > 100 {
		filter.Limit = 100
	}
	return s.repo.List(ctx, userID, filter)
}

// UpdateAnalysis updates a post-mortem analysis (merge patch semantics).
func (s *PostMortemService) UpdateAnalysis(ctx context.Context, userID string, analysis *PostMortemAnalysis, sections *Sections, triggerSummary []string, triggerDetails []TriggerDetail, fasterMapping []FasterMappingEntry, actionPlan []ActionPlanItem) (*PostMortemAnalysis, error) {
	if analysis.UserID != userID {
		return nil, ErrNotFound
	}

	// Completed post-mortems: only actionPlan and sharing editable.
	if analysis.Status == StatusComplete {
		if sections != nil || triggerSummary != nil || triggerDetails != nil || fasterMapping != nil {
			return nil, ErrCompletedImmutable
		}
	}

	// Validate incoming data.
	if sections != nil {
		if err := ValidateSections(sections); err != nil {
			return nil, err
		}
		mergeSections(&analysis.Sections, sections)
	}

	if triggerSummary != nil {
		for _, cat := range triggerSummary {
			if err := ValidateTriggerCategory(cat); err != nil {
				return nil, err
			}
		}
		analysis.TriggerSummary = triggerSummary
	}

	if triggerDetails != nil {
		if err := ValidateTriggerDetails(triggerDetails); err != nil {
			return nil, err
		}
		analysis.TriggerDetails = triggerDetails
	}

	if fasterMapping != nil {
		if err := ValidateFasterMapping(fasterMapping); err != nil {
			return nil, err
		}
		analysis.FasterMapping = fasterMapping
	}

	if actionPlan != nil {
		if err := ValidateActionPlan(actionPlan); err != nil {
			return nil, err
		}
		if len(actionPlan) > MaxActionItems {
			return nil, fmt.Errorf("%w: %d items exceeds maximum of %d", ErrActionItemLimit, len(actionPlan), MaxActionItems)
		}
		analysis.ActionPlan = actionPlan
	}

	analysis.ModifiedAt = time.Now().UTC()

	if err := s.repo.Update(ctx, analysis); err != nil {
		return nil, fmt.Errorf("updating post-mortem: %w", err)
	}

	return analysis, nil
}

// DeleteAnalysis deletes a draft post-mortem. Completed ones cannot be deleted.
func (s *PostMortemService) DeleteAnalysis(ctx context.Context, userID, analysisID string) error {
	analysis, err := s.repo.GetByID(ctx, userID, analysisID)
	if err != nil {
		return fmt.Errorf("retrieving post-mortem: %w", err)
	}
	if analysis == nil {
		return ErrNotFound
	}
	if analysis.Status == StatusComplete {
		return ErrCannotDeleteCompleted
	}
	return s.repo.Delete(ctx, userID, analysisID)
}

// CompleteAnalysis transitions a draft to complete status.
func (s *PostMortemService) CompleteAnalysis(ctx context.Context, userID, analysisID string) (*PostMortemAnalysis, error) {
	analysis, err := s.repo.GetByID(ctx, userID, analysisID)
	if err != nil {
		return nil, fmt.Errorf("retrieving post-mortem: %w", err)
	}
	if analysis == nil {
		return nil, ErrNotFound
	}
	if analysis.UserID != userID {
		return nil, ErrNotFound
	}

	// Already complete is a no-op.
	if analysis.Status == StatusComplete {
		return analysis, nil
	}

	// Validate completeness.
	_, err = ValidateCompleteness(analysis)
	if err != nil {
		return nil, err
	}

	now := time.Now().UTC()
	analysis.Status = StatusComplete
	analysis.CompletedAt = &now
	analysis.ModifiedAt = now

	if err := s.repo.Update(ctx, analysis); err != nil {
		return nil, fmt.Errorf("completing post-mortem: %w", err)
	}

	// Calendar dual-write on completion.
	calEntry := &CalendarActivityEntry{
		UserID:       analysis.UserID,
		Date:         analysis.Timestamp.Format("2006-01-02"),
		ActivityType: "POSTMORTEM",
		Timestamp:    analysis.Timestamp,
		Summary: CalendarActivitySummary{
			AnalysisID:      analysis.AnalysisID,
			EventType:       analysis.EventType,
			Status:          StatusComplete,
			TriggerCount:    len(analysis.TriggerSummary),
			ActionItemCount: len(analysis.ActionPlan),
		},
		SourceKey: fmt.Sprintf("POSTMORTEM#%s", analysis.Timestamp.Format(time.RFC3339)),
	}
	// Calendar write is best-effort; log errors but don't fail.
	_ = s.repo.WriteCalendarActivity(ctx, calEntry)

	return analysis, nil
}

// ShareAnalysis configures sharing for a completed post-mortem.
func (s *PostMortemService) ShareAnalysis(ctx context.Context, userID, analysisID string, shares []SharedWithEntry) (*PostMortemAnalysis, error) {
	analysis, err := s.repo.GetByID(ctx, userID, analysisID)
	if err != nil {
		return nil, fmt.Errorf("retrieving post-mortem: %w", err)
	}
	if analysis == nil {
		return nil, ErrNotFound
	}
	if analysis.Status != StatusComplete {
		return nil, ErrCannotShareDraft
	}

	// Validate share types.
	for _, share := range shares {
		if err := ValidateShareType(share.ShareType); err != nil {
			return nil, err
		}
	}

	analysis.Sharing = SharingStatus{
		IsShared:   len(shares) > 0,
		SharedWith: shares,
	}
	analysis.ModifiedAt = time.Now().UTC()

	if err := s.repo.Update(ctx, analysis); err != nil {
		return nil, fmt.Errorf("sharing post-mortem: %w", err)
	}

	return analysis, nil
}

// mergeSections applies non-nil sections from update onto existing.
func mergeSections(existing *Sections, update *Sections) {
	if update.DayBefore != nil {
		existing.DayBefore = update.DayBefore
	}
	if update.Morning != nil {
		existing.Morning = update.Morning
	}
	if update.ThroughoutTheDay != nil {
		existing.ThroughoutTheDay = update.ThroughoutTheDay
	}
	if update.BuildUp != nil {
		existing.BuildUp = update.BuildUp
	}
	if update.ActingOut != nil {
		existing.ActingOut = update.ActingOut
	}
	if update.ImmediatelyAfter != nil {
		existing.ImmediatelyAfter = update.ImmediatelyAfter
	}
}
