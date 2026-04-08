// internal/cache/phone_call_streak_cache.go
package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/regalrecovery/api/internal/domain/phonecalls"
)

const (
	phoneCallStreakKeyPrefix = "phone-call-streak:"
)

// ValkeyPhoneCallStreakCache implements cache-aside pattern for phone call streak data.
type ValkeyPhoneCallStreakCache struct {
	client *ValkeyClient
}

// NewValkeyPhoneCallStreakCache creates a new ValkeyPhoneCallStreakCache.
func NewValkeyPhoneCallStreakCache(client *ValkeyClient) *ValkeyPhoneCallStreakCache {
	return &ValkeyPhoneCallStreakCache{client: client}
}

// Get retrieves a cached phone call streak. Returns nil if cache miss.
func (c *ValkeyPhoneCallStreakCache) Get(ctx context.Context, userID string) (*phonecalls.PhoneCallStreak, error) {
	key := phoneCallStreakKeyPrefix + userID

	val, err := c.client.Get(ctx, key)
	if err != nil {
		// Cache miss: return nil without error.
		return nil, nil
	}

	var streak phonecalls.PhoneCallStreak
	if err := json.Unmarshal([]byte(val), &streak); err != nil {
		return nil, fmt.Errorf("failed to unmarshal phone call streak for user %s: %w", userID, err)
	}

	return &streak, nil
}

// Set caches a phone call streak with the specified TTL in seconds.
func (c *ValkeyPhoneCallStreakCache) Set(ctx context.Context, userID string, streak *phonecalls.PhoneCallStreak, ttl int) error {
	key := phoneCallStreakKeyPrefix + userID

	data, err := json.Marshal(streak)
	if err != nil {
		return fmt.Errorf("failed to marshal phone call streak for user %s: %w", userID, err)
	}

	ttlDuration := time.Duration(ttl) * time.Second
	if err := c.client.Set(ctx, key, string(data), ttlDuration); err != nil {
		return fmt.Errorf("failed to cache phone call streak for user %s: %w", userID, err)
	}

	return nil
}

// Invalidate removes a cached phone call streak.
func (c *ValkeyPhoneCallStreakCache) Invalidate(ctx context.Context, userID string) error {
	key := phoneCallStreakKeyPrefix + userID

	if err := c.client.Delete(ctx, key); err != nil {
		return fmt.Errorf("failed to invalidate phone call streak for user %s: %w", userID, err)
	}

	return nil
}
