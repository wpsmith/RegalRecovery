// internal/cache/goal_cache.go
package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/regalrecovery/api/internal/domain/goals"
)

const (
	goalDailyCacheTTL    = 5 * time.Minute
	goalSettingsCacheTTL = 10 * time.Minute
)

// GoalCache provides cache-aside for goal data using Valkey.
type GoalCache struct {
	client *ValkeyClient
}

// NewGoalCache creates a new GoalCache.
func NewGoalCache(client *ValkeyClient) *GoalCache {
	return &GoalCache{client: client}
}

// dailyCacheKey returns the cache key for daily goals.
func dailyCacheKey(userID, date string) string {
	return fmt.Sprintf("goals:daily:%s:%s", userID, date)
}

// settingsCacheKey returns the cache key for goal settings.
func settingsCacheKey(userID string) string {
	return fmt.Sprintf("goals:settings:%s", userID)
}

// GetDailyGoals returns cached daily goals, or nil if not cached.
func (c *GoalCache) GetDailyGoals(ctx context.Context, userID, date string) ([]goals.GoalInstance, error) {
	if c.client == nil {
		return nil, nil
	}

	data, err := c.client.Get(ctx, dailyCacheKey(userID, date))
	if err != nil || data == "" {
		return nil, nil
	}

	var instances []goals.GoalInstance
	if err := json.Unmarshal([]byte(data), &instances); err != nil {
		return nil, nil
	}
	return instances, nil
}

// SetDailyGoals caches daily goals.
func (c *GoalCache) SetDailyGoals(ctx context.Context, userID, date string, instances []goals.GoalInstance) error {
	if c.client == nil {
		return nil
	}

	data, err := json.Marshal(instances)
	if err != nil {
		return fmt.Errorf("marshaling daily goals for cache: %w", err)
	}
	return c.client.Set(ctx, dailyCacheKey(userID, date), string(data), goalDailyCacheTTL)
}

// InvalidateDailyGoals removes daily goals from cache.
func (c *GoalCache) InvalidateDailyGoals(ctx context.Context, userID, date string) error {
	if c.client == nil {
		return nil
	}
	return c.client.Delete(ctx, dailyCacheKey(userID, date))
}

// GetGoalSettings returns cached goal settings, or nil if not cached.
func (c *GoalCache) GetGoalSettings(ctx context.Context, userID string) (*goals.GoalSettings, error) {
	if c.client == nil {
		return nil, nil
	}

	data, err := c.client.Get(ctx, settingsCacheKey(userID))
	if err != nil || data == "" {
		return nil, nil
	}

	var settings goals.GoalSettings
	if err := json.Unmarshal([]byte(data), &settings); err != nil {
		return nil, nil
	}
	return &settings, nil
}

// SetGoalSettings caches goal settings.
func (c *GoalCache) SetGoalSettings(ctx context.Context, userID string, settings *goals.GoalSettings) error {
	if c.client == nil {
		return nil
	}

	data, err := json.Marshal(settings)
	if err != nil {
		return fmt.Errorf("marshaling goal settings for cache: %w", err)
	}
	return c.client.Set(ctx, settingsCacheKey(userID), string(data), goalSettingsCacheTTL)
}

// InvalidateGoalSettings removes settings from cache.
func (c *GoalCache) InvalidateGoalSettings(ctx context.Context, userID string) error {
	if c.client == nil {
		return nil
	}
	return c.client.Delete(ctx, settingsCacheKey(userID))
}
