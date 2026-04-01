// internal/domain/content/repository.go
package content

import "context"

// ContentRepository defines the interface for content data retrieval.
type ContentRepository interface {
	// GetAffirmationPacks retrieves all affirmation packs.
	GetAffirmationPacks(ctx context.Context) ([]*AffirmationPack, error)

	// GetAffirmationPack retrieves a specific affirmation pack by ID.
	GetAffirmationPack(ctx context.Context, packID string) (*AffirmationPack, error)

	// GetDevotional retrieves a devotional by day number.
	GetDevotional(ctx context.Context, day int) (*Devotional, error)

	// GetAffirmationByID retrieves a specific affirmation.
	GetAffirmationByID(ctx context.Context, affirmationID string) (*Affirmation, error)

	// GetPrompts retrieves all prompts, optionally filtered by category.
	GetPrompts(ctx context.Context, category string) ([]*Prompt, error)

	// GetPrompt retrieves a specific prompt by ID.
	GetPrompt(ctx context.Context, promptID string) (*Prompt, error)

	// GetRandomPrompt retrieves a random prompt, optionally filtered by category.
	GetRandomPrompt(ctx context.Context, category string) (*Prompt, error)
}

// ContentCache defines the interface for content caching.
type ContentCache interface {
	// GetAffirmationPacks retrieves all affirmation packs from cache.
	GetAffirmationPacks(ctx context.Context) ([]*AffirmationPack, error)

	// SetAffirmationPacks stores affirmation packs in cache with TTL.
	SetAffirmationPacks(ctx context.Context, packs []*AffirmationPack, ttl int) error

	// GetDevotional retrieves a devotional from cache.
	GetDevotional(ctx context.Context, day int) (*Devotional, error)

	// SetDevotional stores a devotional in cache with TTL.
	SetDevotional(ctx context.Context, day int, devotional *Devotional, ttl int) error
}
