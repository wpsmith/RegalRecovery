// internal/cache/personcheckin_streak_cache.go
package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/regalrecovery/api/internal/domain/personcheckin"
)

const (
	pciStreakKeyPrefix = "pci:streak:"
)

// ValkeyPersonCheckInStreakCache implements personcheckin.StreakCache using Valkey.
type ValkeyPersonCheckInStreakCache struct {
	client *ValkeyClient
}

// NewValkeyPersonCheckInStreakCache creates a new cache for person check-in streaks.
func NewValkeyPersonCheckInStreakCache(client *ValkeyClient) *ValkeyPersonCheckInStreakCache {
	return &ValkeyPersonCheckInStreakCache{client: client}
}

// Get retrieves cached streak data for a user and sub-type.
func (c *ValkeyPersonCheckInStreakCache) Get(ctx context.Context, userID string, checkInType personcheckin.CheckInType) (*personcheckin.PersonCheckInStreak, error) {
	key := pciStreakKey(userID, checkInType)

	val, err := c.client.Get(ctx, key)
	if err != nil {
		return nil, nil // Cache miss.
	}

	var streak personcheckin.PersonCheckInStreak
	if err := json.Unmarshal([]byte(val), &streak); err != nil {
		return nil, fmt.Errorf("failed to unmarshal person check-in streak: %w", err)
	}

	return &streak, nil
}

// Set caches streak data with TTL in seconds.
func (c *ValkeyPersonCheckInStreakCache) Set(ctx context.Context, userID string, checkInType personcheckin.CheckInType, streak *personcheckin.PersonCheckInStreak, ttlSeconds int) error {
	key := pciStreakKey(userID, checkInType)

	data, err := json.Marshal(streak)
	if err != nil {
		return fmt.Errorf("failed to marshal person check-in streak: %w", err)
	}

	ttlDuration := time.Duration(ttlSeconds) * time.Second
	if err := c.client.Set(ctx, key, string(data), ttlDuration); err != nil {
		return fmt.Errorf("failed to cache person check-in streak: %w", err)
	}

	return nil
}

// Invalidate removes cached streak data for a user and sub-type.
func (c *ValkeyPersonCheckInStreakCache) Invalidate(ctx context.Context, userID string, checkInType personcheckin.CheckInType) error {
	key := pciStreakKey(userID, checkInType)

	if err := c.client.Delete(ctx, key); err != nil {
		return fmt.Errorf("failed to invalidate person check-in streak: %w", err)
	}

	return nil
}

// InvalidateAll removes all cached streak data for a user.
func (c *ValkeyPersonCheckInStreakCache) InvalidateAll(ctx context.Context, userID string) error {
	for _, ciType := range personcheckin.ValidCheckInTypes {
		_ = c.Invalidate(ctx, userID, ciType)
	}
	return nil
}

func pciStreakKey(userID string, checkInType personcheckin.CheckInType) string {
	return pciStreakKeyPrefix + userID + ":" + string(checkInType)
}
