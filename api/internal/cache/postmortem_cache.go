// internal/cache/postmortem_cache.go
package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/regalrecovery/api/internal/domain/postmortem"
)

const (
	// PostMortemInsightsTTL is the cache TTL for insights data.
	PostMortemInsightsTTL = 30 * time.Minute

	// postMortemInsightsKeyPrefix is the cache key prefix for insights.
	postMortemInsightsKeyPrefix = "pm:insights:"
)

// PostMortemCache provides caching for post-mortem insights using Valkey.
type PostMortemCache struct {
	client CacheClient
}

// CacheClient abstracts the Valkey client for testability.
type CacheClient interface {
	Get(ctx context.Context, key string) (string, error)
	Set(ctx context.Context, key string, value string, ttl time.Duration) error
	Delete(ctx context.Context, key string) error
}

// NewPostMortemCache creates a new PostMortemCache.
func NewPostMortemCache(client CacheClient) *PostMortemCache {
	return &PostMortemCache{client: client}
}

// GetInsights attempts to retrieve cached insights for a user.
// Returns nil if not cached or on error (cache-aside pattern).
func (c *PostMortemCache) GetInsights(ctx context.Context, userID string, addictionID *string) *postmortem.PostMortemInsights {
	key := c.insightsKey(userID, addictionID)
	data, err := c.client.Get(ctx, key)
	if err != nil || data == "" {
		return nil
	}

	var insights postmortem.PostMortemInsights
	if err := json.Unmarshal([]byte(data), &insights); err != nil {
		return nil
	}
	return &insights
}

// SetInsights caches computed insights for a user.
func (c *PostMortemCache) SetInsights(ctx context.Context, userID string, addictionID *string, insights *postmortem.PostMortemInsights) {
	key := c.insightsKey(userID, addictionID)
	data, err := json.Marshal(insights)
	if err != nil {
		return
	}
	_ = c.client.Set(ctx, key, string(data), PostMortemInsightsTTL)
}

// InvalidateInsights invalidates the insights cache for a user.
// Called when a new post-mortem is completed.
func (c *PostMortemCache) InvalidateInsights(ctx context.Context, userID string) {
	// Invalidate the general insights cache.
	key := c.insightsKey(userID, nil)
	_ = c.client.Delete(ctx, key)
}

// insightsKey builds the cache key for insights.
func (c *PostMortemCache) insightsKey(userID string, addictionID *string) string {
	key := postMortemInsightsKeyPrefix + userID
	if addictionID != nil && *addictionID != "" {
		key = fmt.Sprintf("%s:%s", key, *addictionID)
	}
	return key
}
