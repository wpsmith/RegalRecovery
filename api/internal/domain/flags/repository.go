// internal/domain/flags/repository.go
package flags

import "context"

// FlagRepository defines the interface for flag data persistence.
type FlagRepository interface {
	// GetFlag retrieves a flag by key.
	GetFlag(ctx context.Context, key string) (*Flag, error)

	// GetAllFlags retrieves all flags.
	GetAllFlags(ctx context.Context) ([]*Flag, error)

	// SetFlag creates or updates a flag.
	SetFlag(ctx context.Context, flag *Flag) error

	// DeleteFlag removes a flag.
	DeleteFlag(ctx context.Context, key string) error
}

// FlagCache defines the interface for flag caching.
type FlagCache interface {
	// Get retrieves a flag from cache.
	Get(ctx context.Context, key string) (*Flag, error)

	// Set stores a flag in cache with TTL.
	Set(ctx context.Context, key string, flag *Flag, ttl int) error

	// GetAll retrieves all flags from cache.
	GetAll(ctx context.Context) ([]*Flag, error)

	// SetAll stores all flags in cache with TTL.
	SetAll(ctx context.Context, flags []*Flag, ttl int) error

	// Invalidate removes a flag from cache.
	Invalidate(ctx context.Context, key string) error

	// InvalidateAll removes all flags from cache.
	InvalidateAll(ctx context.Context) error
}
