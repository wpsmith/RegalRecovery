// internal/cache/prayer_cache.go
package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/regalrecovery/api/internal/domain/prayer"
)

const (
	prayerStreakKeyPrefix = "prayer:streak:"
	prayerTodayKeyPrefix = "prayer:today:"
)

// ValkeyPrayerCache implements cache-aside pattern for prayer streak data.
type ValkeyPrayerCache struct {
	client *ValkeyClient
}

// NewValkeyPrayerCache creates a new ValkeyPrayerCache.
func NewValkeyPrayerCache(client *ValkeyClient) *ValkeyPrayerCache {
	return &ValkeyPrayerCache{client: client}
}

// Get retrieves cached prayer stats. Returns nil if cache miss.
func (c *ValkeyPrayerCache) Get(ctx context.Context, userID string) (*prayer.PrayerStats, error) {
	key := prayerStreakKeyPrefix + userID

	val, err := c.client.Get(ctx, key)
	if err != nil {
		// Cache miss: return nil without error (caller falls back to DB).
		return nil, nil
	}

	var stats prayer.PrayerStats
	if err := json.Unmarshal([]byte(val), &stats); err != nil {
		return nil, fmt.Errorf("failed to unmarshal prayer stats for user %s: %w", userID, err)
	}

	return &stats, nil
}

// Set caches prayer stats with the specified TTL in seconds.
func (c *ValkeyPrayerCache) Set(ctx context.Context, userID string, stats *prayer.PrayerStats, ttlSeconds int) error {
	key := prayerStreakKeyPrefix + userID

	data, err := json.Marshal(stats)
	if err != nil {
		return fmt.Errorf("failed to marshal prayer stats for user %s: %w", userID, err)
	}

	ttlDuration := time.Duration(ttlSeconds) * time.Second
	if err := c.client.Set(ctx, key, string(data), ttlDuration); err != nil {
		return fmt.Errorf("failed to cache prayer stats for user %s: %w", userID, err)
	}

	return nil
}

// Invalidate removes cached prayer stats.
func (c *ValkeyPrayerCache) Invalidate(ctx context.Context, userID string) error {
	key := prayerStreakKeyPrefix + userID

	if err := c.client.Delete(ctx, key); err != nil {
		return fmt.Errorf("failed to invalidate prayer stats for user %s: %w", userID, err)
	}

	return nil
}

// GetTodayPrayer retrieves cached today's prayer. Returns nil if cache miss.
func (c *ValkeyPrayerCache) GetTodayPrayer(ctx context.Context, userID, dateStr string) (*prayer.LibraryPrayer, error) {
	key := prayerTodayKeyPrefix + userID + ":" + dateStr

	val, err := c.client.Get(ctx, key)
	if err != nil {
		return nil, nil
	}

	var lp prayer.LibraryPrayer
	if err := json.Unmarshal([]byte(val), &lp); err != nil {
		return nil, fmt.Errorf("failed to unmarshal today's prayer for user %s: %w", userID, err)
	}

	return &lp, nil
}

// SetTodayPrayer caches today's prayer until end of day in user's timezone.
func (c *ValkeyPrayerCache) SetTodayPrayer(ctx context.Context, userID, dateStr string, lp *prayer.LibraryPrayer, ttlSeconds int) error {
	key := prayerTodayKeyPrefix + userID + ":" + dateStr

	data, err := json.Marshal(lp)
	if err != nil {
		return fmt.Errorf("failed to marshal today's prayer for user %s: %w", userID, err)
	}

	ttlDuration := time.Duration(ttlSeconds) * time.Second
	if err := c.client.Set(ctx, key, string(data), ttlDuration); err != nil {
		return fmt.Errorf("failed to cache today's prayer for user %s: %w", userID, err)
	}

	return nil
}
