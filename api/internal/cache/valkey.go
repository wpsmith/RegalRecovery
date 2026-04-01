// internal/cache/valkey.go
package cache

import (
	"context"
	"fmt"
	"time"

	"github.com/valkey-io/valkey-go"
)

// ValkeyClient wraps the valkey-go client for cache operations.
type ValkeyClient struct {
	client valkey.Client
}

// NewValkeyClient creates a new Valkey client connected to the given address.
func NewValkeyClient(addr string) (*ValkeyClient, error) {
	client, err := valkey.NewClient(valkey.ClientOption{
		InitAddress: []string{addr},
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create valkey client: %w", err)
	}

	return &ValkeyClient{client: client}, nil
}

// Get retrieves a value by key from Valkey.
// Returns an error if the key does not exist or if the operation fails.
func (c *ValkeyClient) Get(ctx context.Context, key string) (string, error) {
	cmd := c.client.B().Get().Key(key).Build()
	resp := c.client.Do(ctx, cmd)

	val, err := resp.ToString()
	if err != nil {
		return "", fmt.Errorf("failed to get key %s: %w", key, err)
	}

	return val, nil
}

// Set stores a key-value pair with an optional TTL.
// If ttl is 0, the key has no expiration.
func (c *ValkeyClient) Set(ctx context.Context, key string, value string, ttl time.Duration) error {
	var cmd valkey.Completed

	if ttl > 0 {
		cmd = c.client.B().Set().Key(key).Value(value).Ex(ttl).Build()
	} else {
		cmd = c.client.B().Set().Key(key).Value(value).Build()
	}

	resp := c.client.Do(ctx, cmd)
	if err := resp.Error(); err != nil {
		return fmt.Errorf("failed to set key %s: %w", key, err)
	}

	return nil
}

// Delete removes a key from Valkey.
func (c *ValkeyClient) Delete(ctx context.Context, key string) error {
	cmd := c.client.B().Del().Key(key).Build()
	resp := c.client.Do(ctx, cmd)

	if err := resp.Error(); err != nil {
		return fmt.Errorf("failed to delete key %s: %w", key, err)
	}

	return nil
}

// Close closes the Valkey client connection.
func (c *ValkeyClient) Close() {
	c.client.Close()
}
