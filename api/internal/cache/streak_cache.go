// internal/cache/streak_cache.go
package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"time"
)

const (
	streakKeyPrefix = "streak:"
	streakTTL       = 5 * time.Minute
)

// Streak represents a user's streak data.
// This mirrors the expected structure from the repository package.
type Streak struct {
	UserID        string    `json:"userId"`
	CurrentDays   int       `json:"currentDays"`
	SobrietyDate  time.Time `json:"sobrietyDate"`
	LongestStreak int       `json:"longestStreak"`
	TotalRelapses int       `json:"totalRelapses"`
}

// StreakCache implements cache-aside pattern for streak data.
type StreakCache struct {
	client *ValkeyClient
}

// NewStreakCache creates a new StreakCache with the given Valkey client.
func NewStreakCache(client *ValkeyClient) *StreakCache {
	return &StreakCache{client: client}
}

// GetStreak retrieves a cached streak. Returns nil if cache miss (key not found).
func (c *StreakCache) GetStreak(ctx context.Context, userID string) (*Streak, error) {
	key := streakKeyPrefix + userID

	val, err := c.client.Get(ctx, key)
	if err != nil {
		// Cache miss: return nil without error (caller should fall back to DB)
		return nil, nil
	}

	var streak Streak
	if err := json.Unmarshal([]byte(val), &streak); err != nil {
		return nil, fmt.Errorf("failed to unmarshal streak for user %s: %w", userID, err)
	}

	return &streak, nil
}

// SetStreak caches a streak with a 5-minute TTL.
func (c *StreakCache) SetStreak(ctx context.Context, userID string, streak *Streak) error {
	key := streakKeyPrefix + userID

	data, err := json.Marshal(streak)
	if err != nil {
		return fmt.Errorf("failed to marshal streak for user %s: %w", userID, err)
	}

	if err := c.client.Set(ctx, key, string(data), streakTTL); err != nil {
		return fmt.Errorf("failed to cache streak for user %s: %w", userID, err)
	}

	return nil
}

// InvalidateStreak removes a cached streak.
func (c *StreakCache) InvalidateStreak(ctx context.Context, userID string) error {
	key := streakKeyPrefix + userID

	if err := c.client.Delete(ctx, key); err != nil {
		return fmt.Errorf("failed to invalidate streak for user %s: %w", userID, err)
	}

	return nil
}
