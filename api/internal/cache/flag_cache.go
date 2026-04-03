// internal/cache/flag_cache.go
package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/regalrecovery/api/internal/domain/flags"
)

const (
	flagKeyPrefix = "flag:"
	flagsAllKey   = "flags:all"
)

// ValkeyFlagCache implements the flags.FlagCache interface using Valkey.
type ValkeyFlagCache struct {
	client *ValkeyClient
}

// NewValkeyFlagCache creates a new ValkeyFlagCache with the given Valkey client.
func NewValkeyFlagCache(client *ValkeyClient) *ValkeyFlagCache {
	return &ValkeyFlagCache{client: client}
}

// Get retrieves a cached flag by key. Returns nil if cache miss (key not found).
func (c *ValkeyFlagCache) Get(ctx context.Context, key string) (*flags.Flag, error) {
	cacheKey := flagKeyPrefix + key

	val, err := c.client.Get(ctx, cacheKey)
	if err != nil {
		// Cache miss: return nil without error (caller should fall back to DB)
		return nil, nil
	}

	var flag flags.Flag
	if err := json.Unmarshal([]byte(val), &flag); err != nil {
		return nil, fmt.Errorf("failed to unmarshal flag %s: %w", key, err)
	}

	return &flag, nil
}

// Set stores a flag in cache with the specified TTL (in seconds).
func (c *ValkeyFlagCache) Set(ctx context.Context, key string, flag *flags.Flag, ttl int) error {
	cacheKey := flagKeyPrefix + key

	data, err := json.Marshal(flag)
	if err != nil {
		return fmt.Errorf("failed to marshal flag %s: %w", key, err)
	}

	ttlDuration := time.Duration(ttl) * time.Second
	if err := c.client.Set(ctx, cacheKey, string(data), ttlDuration); err != nil {
		return fmt.Errorf("failed to cache flag %s: %w", key, err)
	}

	return nil
}

// GetAll retrieves all cached flags. Returns nil if cache miss (key not found).
func (c *ValkeyFlagCache) GetAll(ctx context.Context) ([]*flags.Flag, error) {
	val, err := c.client.Get(ctx, flagsAllKey)
	if err != nil {
		// Cache miss: return nil without error (caller should fall back to DB)
		return nil, nil
	}

	var flagList []*flags.Flag
	if err := json.Unmarshal([]byte(val), &flagList); err != nil {
		return nil, fmt.Errorf("failed to unmarshal all flags: %w", err)
	}

	return flagList, nil
}

// SetAll stores all flags in cache with the specified TTL (in seconds).
func (c *ValkeyFlagCache) SetAll(ctx context.Context, flags []*flags.Flag, ttl int) error {
	data, err := json.Marshal(flags)
	if err != nil {
		return fmt.Errorf("failed to marshal all flags: %w", err)
	}

	ttlDuration := time.Duration(ttl) * time.Second
	if err := c.client.Set(ctx, flagsAllKey, string(data), ttlDuration); err != nil {
		return fmt.Errorf("failed to cache all flags: %w", err)
	}

	return nil
}

// Invalidate removes a single flag from cache.
func (c *ValkeyFlagCache) Invalidate(ctx context.Context, key string) error {
	cacheKey := flagKeyPrefix + key

	if err := c.client.Delete(ctx, cacheKey); err != nil {
		return fmt.Errorf("failed to invalidate flag %s: %w", key, err)
	}

	return nil
}

// InvalidateAll removes the all-flags cache entry.
func (c *ValkeyFlagCache) InvalidateAll(ctx context.Context) error {
	if err := c.client.Delete(ctx, flagsAllKey); err != nil {
		return fmt.Errorf("failed to invalidate all flags cache: %w", err)
	}

	return nil
}
