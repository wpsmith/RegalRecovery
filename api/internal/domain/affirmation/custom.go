// internal/domain/affirmation/custom.go
package affirmation

import (
	"fmt"
	"time"

	"github.com/google/uuid"
)

// CustomAffirmationService manages user-created affirmations.
type CustomAffirmationService struct {
	repo CustomAffirmationRepository
}

// CustomAffirmationRepository defines the interface for custom affirmation storage.
type CustomAffirmationRepository interface {
	Create(userID string, ca *CustomAffirmation) error
	Update(userID, affirmationID string, ca *CustomAffirmation) error
	Delete(userID, affirmationID string) error
	List(userID string) ([]CustomAffirmation, error)
	Get(userID, affirmationID string) (*CustomAffirmation, error)
	Count(userID string) (int, error)
}

// NewCustomAffirmationService creates a new CustomAffirmationService.
func NewCustomAffirmationService(repo CustomAffirmationRepository) *CustomAffirmationService {
	return &CustomAffirmationService{repo: repo}
}

// CreateCustomAffirmation creates a new user-defined affirmation.
// Enforces the 50 max limit per user. Custom affirmations are always Level 1.
func (s *CustomAffirmationService) CreateCustomAffirmation(
	userID string,
	req *CreateCustomAffirmationRequest,
) (*CustomAffirmation, error) {
	if err := ValidateCreateCustomRequest(req); err != nil {
		return nil, fmt.Errorf("validation error: %w", err)
	}

	count, err := s.repo.Count(userID)
	if err != nil {
		return nil, fmt.Errorf("failed to count custom affirmations: %w", err)
	}
	if count >= MaxCustomAffirmations {
		return nil, fmt.Errorf("maximum %d custom affirmations reached", MaxCustomAffirmations)
	}

	now := time.Now().UTC()
	ca := &CustomAffirmation{
		Affirmation: Affirmation{
			AffirmationID: "caff_" + uuid.New().String()[:8],
			Statement:     req.Statement,
			ScriptureRef:  derefStringOr(req.ScriptureReference, ""),
			Category:      AffirmationCategory(req.Category),
			Level:         1, // Custom affirmations are always Level 1
			IsCustom:      true,
			Language:      "en",
			CreatedAt:     now,
			ModifiedAt:    now,
		},
		Schedule:           Schedule(req.Schedule),
		CustomScheduleDays: req.CustomScheduleDays,
		IsActive:           true,
	}

	if err := s.repo.Create(userID, ca); err != nil {
		return nil, fmt.Errorf("failed to create custom affirmation: %w", err)
	}

	return ca, nil
}

// UpdateCustomAffirmation updates an existing custom affirmation.
// No edit window restriction -- custom affirmations are always editable.
// CreatedAt is immutable (FR2.7).
func (s *CustomAffirmationService) UpdateCustomAffirmation(
	userID, affirmationID string,
	req *UpdateCustomAffirmationRequest,
) (*CustomAffirmation, error) {
	if err := ValidateUpdateCustomRequest(req); err != nil {
		return nil, fmt.Errorf("validation error: %w", err)
	}

	existing, err := s.repo.Get(userID, affirmationID)
	if err != nil {
		return nil, fmt.Errorf("custom affirmation not found: %w", err)
	}

	// Apply updates (CreatedAt is immutable)
	if req.Statement != nil {
		existing.Statement = *req.Statement
	}
	if req.ScriptureReference != nil {
		existing.ScriptureRef = *req.ScriptureReference
	}
	if req.Category != nil {
		existing.Category = AffirmationCategory(*req.Category)
	}
	if req.Schedule != nil {
		existing.Schedule = Schedule(*req.Schedule)
	}
	if req.CustomScheduleDays != nil {
		existing.CustomScheduleDays = req.CustomScheduleDays
	}
	if req.IsActive != nil {
		existing.IsActive = *req.IsActive
	}
	existing.ModifiedAt = time.Now().UTC()

	if err := s.repo.Update(userID, affirmationID, existing); err != nil {
		return nil, fmt.Errorf("failed to update custom affirmation: %w", err)
	}

	return existing, nil
}

// DeleteCustomAffirmation removes a custom affirmation.
func (s *CustomAffirmationService) DeleteCustomAffirmation(userID, affirmationID string) error {
	if err := s.repo.Delete(userID, affirmationID); err != nil {
		return fmt.Errorf("failed to delete custom affirmation: %w", err)
	}
	return nil
}

// ListCustomAffirmations returns all custom affirmations for a user.
func (s *CustomAffirmationService) ListCustomAffirmations(userID string) ([]CustomAffirmation, error) {
	return s.repo.List(userID)
}

func derefStringOr(s *string, def string) string {
	if s != nil {
		return *s
	}
	return def
}
