// internal/domain/devotionals/completion.go
package devotionals

import (
	"context"
	"errors"
	"fmt"
	"time"
)

var (
	// ErrTimestampImmutable indicates an attempt to modify an immutable timestamp.
	ErrTimestampImmutable = errors.New("timestamp is immutable")

	// ErrDuplicateCompletion indicates a devotional was already completed on the same day.
	ErrDuplicateCompletion = errors.New("devotional already completed today")

	// ErrCompletionNotFound indicates the completion record was not found.
	ErrCompletionNotFound = errors.New("completion not found")

	// ErrDevotionalNotFound indicates the devotional was not found.
	ErrDevotionalNotFound = errors.New("devotional not found")

	// ErrInvalidInput indicates invalid input data.
	ErrInvalidInput = errors.New("invalid input")
)

// CompletionService manages devotional completion operations.
type CompletionService struct {
	completionRepo DevotionalCompletionRepository
	contentRepo    DevotionalContentRepository
	streakCalc     *StreakCalculator
}

// NewCompletionService creates a new CompletionService.
func NewCompletionService(
	completionRepo DevotionalCompletionRepository,
	contentRepo DevotionalContentRepository,
	streakCalc *StreakCalculator,
) *CompletionService {
	return &CompletionService{
		completionRepo: completionRepo,
		contentRepo:    contentRepo,
		streakCalc:     streakCalc,
	}
}

// CreateCompletion records a devotional completion.
// Validates that the devotional exists and has not already been completed today.
// Also updates the devotional streak.
func (s *CompletionService) CreateCompletion(ctx context.Context, userID, devotionalID string, req *CompletionRequest, userTimezone string) (*DevotionalCompletion, error) {
	if userID == "" || devotionalID == "" {
		return nil, fmt.Errorf("userID and devotionalID are required: %w", ErrInvalidInput)
	}
	if req.Timestamp.IsZero() {
		return nil, fmt.Errorf("timestamp is required: %w", ErrInvalidInput)
	}

	// Validate mood tag if provided
	if req.MoodTag != nil && !ValidMoodTags[*req.MoodTag] {
		return nil, fmt.Errorf("invalid mood tag %q: %w", *req.MoodTag, ErrInvalidInput)
	}

	// Verify devotional exists
	content, err := s.contentRepo.GetByID(ctx, devotionalID)
	if err != nil {
		return nil, fmt.Errorf("looking up devotional: %w", err)
	}
	if content == nil {
		return nil, ErrDevotionalNotFound
	}

	// Check for duplicate completion on the same day
	completionDate := UserLocalDateAt(req.Timestamp, userTimezone).Format("2006-01-02")
	existing, err := s.completionRepo.GetByDevotionalAndDate(ctx, userID, devotionalID, completionDate)
	if err != nil {
		return nil, fmt.Errorf("checking duplicate completion: %w", err)
	}
	if existing != nil {
		return nil, ErrDuplicateCompletion
	}

	// Create completion document
	now := time.Now().UTC()
	completionID := fmt.Sprintf("dc_%d", now.UnixNano())
	doc := &CompletionDoc{
		PK:                 fmt.Sprintf("USER#%s", userID),
		SK:                 fmt.Sprintf("DEVOTIONAL#%s", req.Timestamp.Format(time.RFC3339)),
		EntityType:         "DEVOTIONAL",
		TenantID:           "DEFAULT",
		CreatedAt:          req.Timestamp,
		ModifiedAt:         now,
		CompletionID:       completionID,
		DevotionalID:       devotionalID,
		DevotionalTitle:    content.Title,
		ScriptureReference: content.ScriptureReference,
		Reflection:         req.Reflection,
		MoodTag:            req.MoodTag,
		SeriesID:           content.SeriesID,
		SeriesDay:          content.SeriesDay,
		Topic:              content.Topic,
	}

	if err := s.completionRepo.Save(ctx, userID, doc); err != nil {
		return nil, fmt.Errorf("saving completion: %w", err)
	}

	// Update streak
	streak, err := s.streakCalc.RecordCompletion(ctx, userID, completionDate, userTimezone)
	if err != nil {
		// Log but don't fail the completion
		streak = &DevotionalStreak{CurrentDays: 0, LongestDays: 0}
	}

	return &DevotionalCompletion{
		CompletionID:       completionID,
		DevotionalID:       devotionalID,
		DevotionalTitle:    content.Title,
		ScriptureReference: content.ScriptureReference,
		Timestamp:          req.Timestamp,
		Reflection:         req.Reflection,
		MoodTag:            req.MoodTag,
		SeriesID:           content.SeriesID,
		SeriesDay:          content.SeriesDay,
		DevotionalStreak:   streak,
	}, nil
}

// UpdateCompletion updates the mutable fields of a completion.
// Only reflection and moodTag can be updated. Timestamp is immutable (FR2.7).
func (s *CompletionService) UpdateCompletion(ctx context.Context, userID, completionID string, req *CompletionUpdateRequest) (*DevotionalCompletion, error) {
	if completionID == "" {
		return nil, fmt.Errorf("completionID is required: %w", ErrInvalidInput)
	}

	// Validate mood tag if provided
	if req.MoodTag != nil && !ValidMoodTags[*req.MoodTag] {
		return nil, fmt.Errorf("invalid mood tag %q: %w", *req.MoodTag, ErrInvalidInput)
	}

	// Retrieve existing completion
	existing, err := s.completionRepo.GetByID(ctx, userID, completionID)
	if err != nil {
		return nil, fmt.Errorf("looking up completion: %w", err)
	}
	if existing == nil {
		return nil, ErrCompletionNotFound
	}

	// Apply updates (only mutable fields)
	if req.Reflection != nil {
		existing.Reflection = req.Reflection
	}
	if req.MoodTag != nil {
		existing.MoodTag = req.MoodTag
	}
	existing.ModifiedAt = time.Now().UTC()

	if err := s.completionRepo.Update(ctx, userID, existing); err != nil {
		return nil, fmt.Errorf("updating completion: %w", err)
	}

	return docToCompletion(existing), nil
}

// GetCompletion retrieves a single completion by ID.
func (s *CompletionService) GetCompletion(ctx context.Context, userID, completionID string) (*DevotionalCompletion, error) {
	doc, err := s.completionRepo.GetByID(ctx, userID, completionID)
	if err != nil {
		return nil, fmt.Errorf("looking up completion: %w", err)
	}
	if doc == nil {
		return nil, ErrCompletionNotFound
	}
	return docToCompletion(doc), nil
}

// docToCompletion converts a CompletionDoc to a DevotionalCompletion.
func docToCompletion(doc *CompletionDoc) *DevotionalCompletion {
	return &DevotionalCompletion{
		CompletionID:       doc.CompletionID,
		DevotionalID:       doc.DevotionalID,
		DevotionalTitle:    doc.DevotionalTitle,
		ScriptureReference: doc.ScriptureReference,
		Timestamp:          doc.CreatedAt,
		Reflection:         doc.Reflection,
		MoodTag:            doc.MoodTag,
		SeriesID:           doc.SeriesID,
		SeriesDay:          doc.SeriesDay,
	}
}

// ValidateTimestampImmutability checks that a timestamp update is not attempted.
// Returns ErrTimestampImmutable if the caller tries to change the timestamp.
func ValidateTimestampImmutability(original, attempted time.Time) error {
	if !attempted.IsZero() && !attempted.Equal(original) {
		return ErrTimestampImmutable
	}
	return nil
}
