// internal/cache/mood_cache.go
package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/regalrecovery/api/internal/domain/mood"
)

const (
	// MoodTodayTTL is the TTL for today's entries cache.
	MoodTodayTTL = 5 * time.Minute

	// MoodStreakTTL is the TTL for mood streak cache.
	MoodStreakTTL = 1 * time.Hour

	// MoodDailyAvgTTL is the TTL for daily average cache.
	MoodDailyAvgTTL = 24 * time.Hour
)

// MoodCache provides caching for mood data using Valkey.
type MoodCache struct {
	client *ValkeyClient
}

// NewMoodCache creates a new MoodCache.
func NewMoodCache(client *ValkeyClient) *MoodCache {
	return &MoodCache{client: client}
}

// todayKey returns the cache key for today's entries.
func todayKey(userID, datePartition string) string {
	return fmt.Sprintf("mood:today:%s:%s", userID, datePartition)
}

// streakKey returns the cache key for the mood streak.
func streakKey(userID string) string {
	return fmt.Sprintf("mood:streak:%s", userID)
}

// dailyAvgKey returns the cache key for a daily average.
func dailyAvgKey(userID, datePartition string) string {
	return fmt.Sprintf("mood:daily-avg:%s:%s", userID, datePartition)
}

// GetTodayEntries retrieves today's cached entries.
func (c *MoodCache) GetTodayEntries(ctx context.Context, userID, datePartition string) ([]mood.MoodEntry, error) {
	data, err := c.client.Get(ctx, todayKey(userID, datePartition))
	if err != nil {
		return nil, err
	}

	var entries []mood.MoodEntry
	if err := json.Unmarshal([]byte(data), &entries); err != nil {
		return nil, fmt.Errorf("unmarshaling cached today entries: %w", err)
	}

	return entries, nil
}

// SetTodayEntries caches today's entries.
func (c *MoodCache) SetTodayEntries(ctx context.Context, userID, datePartition string, entries []mood.MoodEntry) error {
	data, err := json.Marshal(entries)
	if err != nil {
		return fmt.Errorf("marshaling today entries: %w", err)
	}
	return c.client.Set(ctx, todayKey(userID, datePartition), string(data), MoodTodayTTL)
}

// InvalidateTodayEntries removes today's entries from cache.
func (c *MoodCache) InvalidateTodayEntries(ctx context.Context, userID, datePartition string) error {
	return c.client.Delete(ctx, todayKey(userID, datePartition))
}

// GetStreak retrieves the cached mood streak.
func (c *MoodCache) GetStreak(ctx context.Context, userID string) (*mood.StreakInfo, error) {
	data, err := c.client.Get(ctx, streakKey(userID))
	if err != nil {
		return nil, err
	}

	var streak mood.StreakInfo
	if err := json.Unmarshal([]byte(data), &streak); err != nil {
		return nil, fmt.Errorf("unmarshaling cached streak: %w", err)
	}

	return &streak, nil
}

// SetStreak caches the mood streak.
func (c *MoodCache) SetStreak(ctx context.Context, userID string, streak *mood.StreakInfo) error {
	data, err := json.Marshal(streak)
	if err != nil {
		return fmt.Errorf("marshaling streak: %w", err)
	}
	return c.client.Set(ctx, streakKey(userID), string(data), MoodStreakTTL)
}

// InvalidateStreak removes the mood streak from cache.
func (c *MoodCache) InvalidateStreak(ctx context.Context, userID string) error {
	return c.client.Delete(ctx, streakKey(userID))
}

// GetDailyAverage retrieves a cached daily average.
func (c *MoodCache) GetDailyAverage(ctx context.Context, userID, datePartition string) (*mood.DailySummary, error) {
	data, err := c.client.Get(ctx, dailyAvgKey(userID, datePartition))
	if err != nil {
		return nil, err
	}

	var summary mood.DailySummary
	if err := json.Unmarshal([]byte(data), &summary); err != nil {
		return nil, fmt.Errorf("unmarshaling cached daily average: %w", err)
	}

	return &summary, nil
}

// SetDailyAverage caches a daily average.
func (c *MoodCache) SetDailyAverage(ctx context.Context, userID, datePartition string, summary *mood.DailySummary) error {
	data, err := json.Marshal(summary)
	if err != nil {
		return fmt.Errorf("marshaling daily average: %w", err)
	}
	return c.client.Set(ctx, dailyAvgKey(userID, datePartition), string(data), MoodDailyAvgTTL)
}

// InvalidateDailyAverage removes a daily average from cache.
func (c *MoodCache) InvalidateDailyAverage(ctx context.Context, userID, datePartition string) error {
	return c.client.Delete(ctx, dailyAvgKey(userID, datePartition))
}

// InvalidateAll invalidates all mood caches for a user on a given date.
// Called after create, update, or delete operations.
func (c *MoodCache) InvalidateAll(ctx context.Context, userID, datePartition string) {
	_ = c.InvalidateTodayEntries(ctx, userID, datePartition)
	_ = c.InvalidateStreak(ctx, userID)
	_ = c.InvalidateDailyAverage(ctx, userID, datePartition)
}
