// internal/cache/streak_cache.go
package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/regalrecovery/api/internal/domain/tracking"
)

const (
	streakKeyPrefix = "streak:"
)

// ValkeyStreakCache implements cache-aside pattern for streak data.
type ValkeyStreakCache struct {
	client *ValkeyClient
}

// NewValkeyStreakCache creates a new ValkeyStreakCache with the given Valkey client.
func NewValkeyStreakCache(client *ValkeyClient) *ValkeyStreakCache {
	return &ValkeyStreakCache{client: client}
}

// Get retrieves a cached streak. Returns nil if cache miss (key not found).
func (c *ValkeyStreakCache) Get(ctx context.Context, addictionID string) (*tracking.StreakData, error) {
	key := streakKeyPrefix + addictionID

	val, err := c.client.Get(ctx, key)
	if err != nil {
		// Cache miss: return nil without error (caller should fall back to DB)
		return nil, nil
	}

	var streak tracking.StreakData
	if err := json.Unmarshal([]byte(val), &streak); err != nil {
		return nil, fmt.Errorf("failed to unmarshal streak for addiction %s: %w", addictionID, err)
	}

	return &streak, nil
}

// Set caches a streak with the specified TTL in seconds.
func (c *ValkeyStreakCache) Set(ctx context.Context, addictionID string, streak *tracking.StreakData, ttl int) error {
	key := streakKeyPrefix + addictionID

	data, err := json.Marshal(streak)
	if err != nil {
		return fmt.Errorf("failed to marshal streak for addiction %s: %w", addictionID, err)
	}

	ttlDuration := time.Duration(ttl) * time.Second
	if err := c.client.Set(ctx, key, string(data), ttlDuration); err != nil {
		return fmt.Errorf("failed to cache streak for addiction %s: %w", addictionID, err)
	}

	return nil
}

// Invalidate removes a cached streak.
func (c *ValkeyStreakCache) Invalidate(ctx context.Context, addictionID string) error {
	key := streakKeyPrefix + addictionID

	if err := c.client.Delete(ctx, key); err != nil {
		return fmt.Errorf("failed to invalidate streak for addiction %s: %w", addictionID, err)
	}

	return nil
}
