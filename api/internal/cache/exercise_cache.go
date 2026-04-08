// internal/cache/exercise_cache.go
package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/regalrecovery/api/internal/domain/exercise"
)

const (
	exerciseStreakKeyPrefix = "exercise:streak:"
	exerciseWidgetKeyPrefix = "exercise:widget:"
	exerciseStatsKeyPrefix  = "exercise:stats:"

	// ExerciseStreakTTL is the cache TTL for exercise streak data.
	ExerciseStreakTTL = 5 * time.Minute

	// ExerciseWidgetTTL is the cache TTL for exercise widget data.
	ExerciseWidgetTTL = 2 * time.Minute

	// ExerciseStatsTTL is the cache TTL for exercise stats data.
	ExerciseStatsTTL = 10 * time.Minute
)

// ExerciseCache implements cache-aside pattern for exercise data.
type ExerciseCache struct {
	client *ValkeyClient
}

// NewExerciseCache creates a new ExerciseCache with the given Valkey client.
func NewExerciseCache(client *ValkeyClient) *ExerciseCache {
	return &ExerciseCache{client: client}
}

// --- Streak Cache ---

// GetStreak retrieves cached exercise streak data.
// Returns nil on cache miss.
func (c *ExerciseCache) GetStreak(ctx context.Context, userID string) (*exercise.ExerciseStreak, error) {
	key := exerciseStreakKeyPrefix + userID

	val, err := c.client.Get(ctx, key)
	if err != nil {
		return nil, nil // Cache miss
	}

	var streak exercise.ExerciseStreak
	if err := json.Unmarshal([]byte(val), &streak); err != nil {
		return nil, fmt.Errorf("failed to unmarshal exercise streak for user %s: %w", userID, err)
	}

	return &streak, nil
}

// SetStreak caches exercise streak data.
func (c *ExerciseCache) SetStreak(ctx context.Context, userID string, streak *exercise.ExerciseStreak) error {
	key := exerciseStreakKeyPrefix + userID

	data, err := json.Marshal(streak)
	if err != nil {
		return fmt.Errorf("failed to marshal exercise streak for user %s: %w", userID, err)
	}

	if err := c.client.Set(ctx, key, string(data), ExerciseStreakTTL); err != nil {
		return fmt.Errorf("failed to cache exercise streak for user %s: %w", userID, err)
	}

	return nil
}

// --- Widget Cache ---

// GetWidget retrieves cached exercise widget data.
// Returns nil on cache miss.
func (c *ExerciseCache) GetWidget(ctx context.Context, userID string) (*exercise.WidgetData, error) {
	key := exerciseWidgetKeyPrefix + userID

	val, err := c.client.Get(ctx, key)
	if err != nil {
		return nil, nil // Cache miss
	}

	var widget exercise.WidgetData
	if err := json.Unmarshal([]byte(val), &widget); err != nil {
		return nil, fmt.Errorf("failed to unmarshal exercise widget for user %s: %w", userID, err)
	}

	return &widget, nil
}

// SetWidget caches exercise widget data.
func (c *ExerciseCache) SetWidget(ctx context.Context, userID string, widget *exercise.WidgetData) error {
	key := exerciseWidgetKeyPrefix + userID

	data, err := json.Marshal(widget)
	if err != nil {
		return fmt.Errorf("failed to marshal exercise widget for user %s: %w", userID, err)
	}

	if err := c.client.Set(ctx, key, string(data), ExerciseWidgetTTL); err != nil {
		return fmt.Errorf("failed to cache exercise widget for user %s: %w", userID, err)
	}

	return nil
}

// --- Stats Cache ---

// GetStats retrieves cached exercise stats data.
// Returns nil on cache miss.
func (c *ExerciseCache) GetStats(ctx context.Context, userID, period, date string) (*exercise.ExerciseStats, error) {
	key := fmt.Sprintf("%s%s:%s:%s", exerciseStatsKeyPrefix, userID, period, date)

	val, err := c.client.Get(ctx, key)
	if err != nil {
		return nil, nil // Cache miss
	}

	var stats exercise.ExerciseStats
	if err := json.Unmarshal([]byte(val), &stats); err != nil {
		return nil, fmt.Errorf("failed to unmarshal exercise stats for user %s: %w", userID, err)
	}

	return &stats, nil
}

// SetStats caches exercise stats data.
func (c *ExerciseCache) SetStats(ctx context.Context, userID, period, date string, stats *exercise.ExerciseStats) error {
	key := fmt.Sprintf("%s%s:%s:%s", exerciseStatsKeyPrefix, userID, period, date)

	data, err := json.Marshal(stats)
	if err != nil {
		return fmt.Errorf("failed to marshal exercise stats for user %s: %w", userID, err)
	}

	if err := c.client.Set(ctx, key, string(data), ExerciseStatsTTL); err != nil {
		return fmt.Errorf("failed to cache exercise stats for user %s: %w", userID, err)
	}

	return nil
}

// --- Invalidation ---

// InvalidateOnExerciseChange invalidates all exercise caches for a user.
// Called on exercise log create/delete.
func (c *ExerciseCache) InvalidateOnExerciseChange(ctx context.Context, userID string) error {
	// Invalidate streak cache.
	if err := c.client.Delete(ctx, exerciseStreakKeyPrefix+userID); err != nil {
		// Log but don't fail — cache invalidation is best-effort.
		_ = err
	}

	// Invalidate widget cache.
	if err := c.client.Delete(ctx, exerciseWidgetKeyPrefix+userID); err != nil {
		_ = err
	}

	// Stats cache uses period+date keys; we can't easily enumerate them.
	// They will expire via TTL (10 minutes). For stricter invalidation,
	// a prefix-based delete would be needed (not supported by basic Valkey ops).

	return nil
}

// InvalidateOnGoalChange invalidates goal-related caches for a user.
// Called on goal create/update/delete.
func (c *ExerciseCache) InvalidateOnGoalChange(ctx context.Context, userID string) error {
	// Widget includes goal progress — invalidate it.
	if err := c.client.Delete(ctx, exerciseWidgetKeyPrefix+userID); err != nil {
		_ = err
	}
	return nil
}
