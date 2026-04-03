// internal/cache/session_cache.go
package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/regalrecovery/api/internal/domain/auth"
)

const (
	sessionKeyPrefix = "session:"
	sessionTTL       = 10 * time.Minute
)

// SessionCache implements cache-aside pattern for session data.
type SessionCache struct {
	client *ValkeyClient
}

// NewSessionCache creates a new SessionCache with the given Valkey client.
func NewSessionCache(client *ValkeyClient) *SessionCache {
	return &SessionCache{client: client}
}

// GetSession retrieves a cached session. Returns nil if cache miss (key not found).
func (c *SessionCache) GetSession(ctx context.Context, sessionID string) (*auth.Session, error) {
	key := sessionKeyPrefix + sessionID

	val, err := c.client.Get(ctx, key)
	if err != nil {
		// Cache miss: return nil without error (caller should fall back to DB)
		return nil, nil
	}

	var session auth.Session
	if err := json.Unmarshal([]byte(val), &session); err != nil {
		return nil, fmt.Errorf("failed to unmarshal session %s: %w", sessionID, err)
	}

	return &session, nil
}

// SetSession caches a session with a 10-minute TTL.
func (c *SessionCache) SetSession(ctx context.Context, sessionID string, session *auth.Session) error {
	key := sessionKeyPrefix + sessionID

	data, err := json.Marshal(session)
	if err != nil {
		return fmt.Errorf("failed to marshal session %s: %w", sessionID, err)
	}

	if err := c.client.Set(ctx, key, string(data), sessionTTL); err != nil {
		return fmt.Errorf("failed to cache session %s: %w", sessionID, err)
	}

	return nil
}

// InvalidateSession removes a cached session.
func (c *SessionCache) InvalidateSession(ctx context.Context, sessionID string) error {
	key := sessionKeyPrefix + sessionID

	if err := c.client.Delete(ctx, key); err != nil {
		return fmt.Errorf("failed to invalidate session %s: %w", sessionID, err)
	}

	return nil
}
