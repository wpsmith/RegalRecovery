// internal/domain/content/service.go
package content

import (
	"context"
	"crypto/sha256"
	"encoding/binary"
	"errors"
	"fmt"
)

var (
	// ErrContentNotFound indicates content does not exist.
	ErrContentNotFound = errors.New("content not found")

	// ErrInvalidInput indicates invalid input data.
	ErrInvalidInput = errors.New("invalid input data")
)

// ContentService handles content retrieval business logic.
type ContentService struct {
	repo  ContentRepository
	cache ContentCache
}

// NewContentService creates a new ContentService with required dependencies.
func NewContentService(repo ContentRepository, cache ContentCache) *ContentService {
	return &ContentService{
		repo:  repo,
		cache: cache,
	}
}

// GetAffirmationPacks retrieves all affirmation packs.
// Uses cache-aside pattern for performance.
func (s *ContentService) GetAffirmationPacks(ctx context.Context) ([]*AffirmationPack, error) {
	// Try cache first.
	packs, err := s.cache.GetAffirmationPacks(ctx)
	if err != nil || len(packs) == 0 {
		// Cache miss, fetch from repository.
		packs, err = s.repo.GetAffirmationPacks(ctx)
		if err != nil {
			return nil, fmt.Errorf("retrieving affirmation packs: %w", err)
		}

		// Store in cache with 1-hour TTL (content rarely changes).
		_ = s.cache.SetAffirmationPacks(ctx, packs, 3600)
	}

	return packs, nil
}

// GetAffirmationPack retrieves a specific affirmation pack by ID.
func (s *ContentService) GetAffirmationPack(ctx context.Context, packID string) (*AffirmationPack, error) {
	if packID == "" {
		return nil, fmt.Errorf("pack ID is required: %w", ErrInvalidInput)
	}

	pack, err := s.repo.GetAffirmationPack(ctx, packID)
	if err != nil {
		return nil, fmt.Errorf("retrieving affirmation pack: %w", err)
	}
	if pack == nil {
		return nil, ErrContentNotFound
	}

	return pack, nil
}

// GetDevotional retrieves a devotional by day number.
// Uses cache-aside pattern for performance.
func (s *ContentService) GetDevotional(ctx context.Context, day int) (*Devotional, error) {
	if day < 1 {
		return nil, fmt.Errorf("day must be positive: %w", ErrInvalidInput)
	}

	// Try cache first.
	devotional, err := s.cache.GetDevotional(ctx, day)
	if err != nil || devotional == nil {
		// Cache miss, fetch from repository.
		devotional, err = s.repo.GetDevotional(ctx, day)
		if err != nil {
			return nil, fmt.Errorf("retrieving devotional: %w", err)
		}
		if devotional == nil {
			return nil, ErrContentNotFound
		}

		// Store in cache with 1-hour TTL.
		_ = s.cache.SetDevotional(ctx, day, devotional, 3600)
	}

	return devotional, nil
}

// GetTodaysAffirmation retrieves a daily affirmation for a user.
// Uses deterministic selection based on user ID and current date to ensure
// the same user gets the same affirmation each day.
func (s *ContentService) GetTodaysAffirmation(ctx context.Context, userID string, packID string) (*Affirmation, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required: %w", ErrInvalidInput)
	}
	if packID == "" {
		return nil, fmt.Errorf("pack ID is required: %w", ErrInvalidInput)
	}

	pack, err := s.GetAffirmationPack(ctx, packID)
	if err != nil {
		return nil, fmt.Errorf("retrieving pack: %w", err)
	}

	if len(pack.Affirmations) == 0 {
		return nil, fmt.Errorf("pack has no affirmations: %w", ErrContentNotFound)
	}

	// Select affirmation based on user ID hash.
	// This ensures the same user gets consistent affirmations.
	index := s.getAffirmationIndex(userID, len(pack.Affirmations))
	affirmation := pack.Affirmations[index]

	return &affirmation, nil
}

// getAffirmationIndex returns a deterministic index based on user ID.
func (s *ContentService) getAffirmationIndex(userID string, count int) int {
	hash := sha256.Sum256([]byte(userID))
	num := binary.BigEndian.Uint64(hash[:8])
	return int(num % uint64(count))
}

// GetPrompts retrieves all prompts, optionally filtered by category.
func (s *ContentService) GetPrompts(ctx context.Context, category string) ([]*Prompt, error) {
	prompts, err := s.repo.GetPrompts(ctx, category)
	if err != nil {
		return nil, fmt.Errorf("retrieving prompts: %w", err)
	}
	return prompts, nil
}

// GetPrompt retrieves a specific prompt by ID.
func (s *ContentService) GetPrompt(ctx context.Context, promptID string) (*Prompt, error) {
	if promptID == "" {
		return nil, fmt.Errorf("prompt ID is required: %w", ErrInvalidInput)
	}
	prompt, err := s.repo.GetPrompt(ctx, promptID)
	if err != nil {
		return nil, fmt.Errorf("retrieving prompt: %w", err)
	}
	if prompt == nil {
		return nil, ErrContentNotFound
	}
	return prompt, nil
}

// GetRandomPrompt retrieves a random prompt, optionally filtered by category.
func (s *ContentService) GetRandomPrompt(ctx context.Context, category string) (*Prompt, error) {
	prompt, err := s.repo.GetRandomPrompt(ctx, category)
	if err != nil {
		return nil, fmt.Errorf("retrieving random prompt: %w", err)
	}
	if prompt == nil {
		return nil, ErrContentNotFound
	}
	return prompt, nil
}
