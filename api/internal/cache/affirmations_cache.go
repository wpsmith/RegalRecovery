// internal/cache/affirmations_cache.go
package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/regalrecovery/api/internal/domain/affirmations"
)

const (
	// Cache key prefixes
	morningSessionKeyPrefix = "affirmations:morning:"
	progressKeyPrefix       = "affirmations:progress:"
	settingsKeyPrefix       = "affirmations:settings:"
	levelKeyPrefix          = "affirmations:level:"
	sosPoolKeyPrefix        = "affirmations:sos:"
	favoritesKeyPrefix      = "affirmations:favorites:"

	// TTLs for different cache entries
	morningSessionTTL = 5 * time.Minute  // 5-min TTL for morning session content
	progressTTL       = 10 * time.Minute // 10-min TTL for user progress
	settingsTTL       = 10 * time.Minute // 10-min TTL for user settings
	levelTTL          = 10 * time.Minute // 10-min TTL for level info
	sosPoolTTL        = 30 * time.Minute // 30-min TTL for SOS content pool
	favoritesTTL      = 10 * time.Minute // 10-min TTL for favorites list
)

// AffirmationsCache implements cache-aside pattern for affirmation data.
type AffirmationsCache struct {
	client *ValkeyClient
}

// NewAffirmationsCache creates a new AffirmationsCache with the given Valkey client.
func NewAffirmationsCache(client *ValkeyClient) *AffirmationsCache {
	return &AffirmationsCache{client: client}
}

// --- Morning Session Cache ---

// GetMorningSession retrieves a cached morning session. Returns nil if cache miss.
func (c *AffirmationsCache) GetMorningSession(ctx context.Context, userID string) (*affirmations.MorningSession, error) {
	key := morningSessionKeyPrefix + userID

	val, err := c.client.Get(ctx, key)
	if err != nil {
		// Cache miss: return nil without error (caller should fall back to composition)
		return nil, nil
	}

	var session affirmations.MorningSession
	if err := json.Unmarshal([]byte(val), &session); err != nil {
		return nil, fmt.Errorf("failed to unmarshal morning session for user %s: %w", userID, err)
	}

	return &session, nil
}

// SetMorningSession caches a morning session with a 5-minute TTL.
func (c *AffirmationsCache) SetMorningSession(ctx context.Context, userID string, session *affirmations.MorningSession) error {
	key := morningSessionKeyPrefix + userID

	data, err := json.Marshal(session)
	if err != nil {
		return fmt.Errorf("failed to marshal morning session for user %s: %w", userID, err)
	}

	if err := c.client.Set(ctx, key, string(data), morningSessionTTL); err != nil {
		return fmt.Errorf("failed to cache morning session for user %s: %w", userID, err)
	}

	return nil
}

// InvalidateMorningSession removes a cached morning session.
func (c *AffirmationsCache) InvalidateMorningSession(ctx context.Context, userID string) error {
	key := morningSessionKeyPrefix + userID

	if err := c.client.Delete(ctx, key); err != nil {
		return fmt.Errorf("failed to invalidate morning session for user %s: %w", userID, err)
	}

	return nil
}

// --- Progress Cache ---

// GetProgress retrieves cached user progress. Returns nil if cache miss.
func (c *AffirmationsCache) GetProgress(ctx context.Context, userID string) (*affirmations.AffirmationProgress, error) {
	key := progressKeyPrefix + userID

	val, err := c.client.Get(ctx, key)
	if err != nil {
		// Cache miss: return nil without error (caller should fall back to DB)
		return nil, nil
	}

	var progress affirmations.AffirmationProgress
	if err := json.Unmarshal([]byte(val), &progress); err != nil {
		return nil, fmt.Errorf("failed to unmarshal progress for user %s: %w", userID, err)
	}

	return &progress, nil
}

// SetProgress caches user progress with a 10-minute TTL.
func (c *AffirmationsCache) SetProgress(ctx context.Context, userID string, progress *affirmations.AffirmationProgress) error {
	key := progressKeyPrefix + userID

	data, err := json.Marshal(progress)
	if err != nil {
		return fmt.Errorf("failed to marshal progress for user %s: %w", userID, err)
	}

	if err := c.client.Set(ctx, key, string(data), progressTTL); err != nil {
		return fmt.Errorf("failed to cache progress for user %s: %w", userID, err)
	}

	return nil
}

// InvalidateProgress removes cached user progress.
func (c *AffirmationsCache) InvalidateProgress(ctx context.Context, userID string) error {
	key := progressKeyPrefix + userID

	if err := c.client.Delete(ctx, key); err != nil {
		return fmt.Errorf("failed to invalidate progress for user %s: %w", userID, err)
	}

	return nil
}

// --- Settings Cache ---

// GetSettings retrieves cached user settings. Returns nil if cache miss.
func (c *AffirmationsCache) GetSettings(ctx context.Context, userID string) (*affirmations.UserAffirmationPreferences, error) {
	key := settingsKeyPrefix + userID

	val, err := c.client.Get(ctx, key)
	if err != nil {
		// Cache miss: return nil without error (caller should fall back to DB)
		return nil, nil
	}

	var settings affirmations.UserAffirmationPreferences
	if err := json.Unmarshal([]byte(val), &settings); err != nil {
		return nil, fmt.Errorf("failed to unmarshal settings for user %s: %w", userID, err)
	}

	return &settings, nil
}

// SetSettings caches user settings with a 10-minute TTL.
func (c *AffirmationsCache) SetSettings(ctx context.Context, userID string, settings *affirmations.UserAffirmationPreferences) error {
	key := settingsKeyPrefix + userID

	data, err := json.Marshal(settings)
	if err != nil {
		return fmt.Errorf("failed to marshal settings for user %s: %w", userID, err)
	}

	if err := c.client.Set(ctx, key, string(data), settingsTTL); err != nil {
		return fmt.Errorf("failed to cache settings for user %s: %w", userID, err)
	}

	return nil
}

// InvalidateSettings removes cached user settings.
func (c *AffirmationsCache) InvalidateSettings(ctx context.Context, userID string) error {
	key := settingsKeyPrefix + userID

	if err := c.client.Delete(ctx, key); err != nil {
		return fmt.Errorf("failed to invalidate settings for user %s: %w", userID, err)
	}

	return nil
}

// --- Level Info Cache ---

// LevelInfo holds cached level determination data.
type LevelInfo struct {
	DeterminedLevel Level  `json:"determinedLevel"`
	SobrietyDays    int    `json:"sobrietyDays"`
	Reason          string `json:"reason"`
	IsLocked        bool   `json:"isLocked"`
}

// Level is an alias for affirmations.Level to avoid import cycles in cached data.
type Level = affirmations.Level

// GetLevel retrieves cached level info. Returns nil if cache miss.
func (c *AffirmationsCache) GetLevel(ctx context.Context, userID string) (*LevelInfo, error) {
	key := levelKeyPrefix + userID

	val, err := c.client.Get(ctx, key)
	if err != nil {
		// Cache miss: return nil without error (caller should fall back to computation)
		return nil, nil
	}

	var levelInfo LevelInfo
	if err := json.Unmarshal([]byte(val), &levelInfo); err != nil {
		return nil, fmt.Errorf("failed to unmarshal level info for user %s: %w", userID, err)
	}

	return &levelInfo, nil
}

// SetLevel caches level info with a 10-minute TTL.
func (c *AffirmationsCache) SetLevel(ctx context.Context, userID string, levelInfo *LevelInfo) error {
	key := levelKeyPrefix + userID

	data, err := json.Marshal(levelInfo)
	if err != nil {
		return fmt.Errorf("failed to marshal level info for user %s: %w", userID, err)
	}

	if err := c.client.Set(ctx, key, string(data), levelTTL); err != nil {
		return fmt.Errorf("failed to cache level info for user %s: %w", userID, err)
	}

	return nil
}

// InvalidateLevel removes cached level info.
func (c *AffirmationsCache) InvalidateLevel(ctx context.Context, userID string) error {
	key := levelKeyPrefix + userID

	if err := c.client.Delete(ctx, key); err != nil {
		return fmt.Errorf("failed to invalidate level info for user %s: %w", userID, err)
	}

	return nil
}

// --- SOS Content Pool Cache ---

// GetSOSPool retrieves cached SOS content pool. Returns nil if cache miss.
func (c *AffirmationsCache) GetSOSPool(ctx context.Context, userID string) ([]affirmations.Affirmation, error) {
	key := sosPoolKeyPrefix + userID

	val, err := c.client.Get(ctx, key)
	if err != nil {
		// Cache miss: return nil without error (caller should fall back to DB)
		return nil, nil
	}

	var pool []affirmations.Affirmation
	if err := json.Unmarshal([]byte(val), &pool); err != nil {
		return nil, fmt.Errorf("failed to unmarshal SOS pool for user %s: %w", userID, err)
	}

	return pool, nil
}

// SetSOSPool caches SOS content pool with a 30-minute TTL.
func (c *AffirmationsCache) SetSOSPool(ctx context.Context, userID string, pool []affirmations.Affirmation) error {
	key := sosPoolKeyPrefix + userID

	data, err := json.Marshal(pool)
	if err != nil {
		return fmt.Errorf("failed to marshal SOS pool for user %s: %w", userID, err)
	}

	if err := c.client.Set(ctx, key, string(data), sosPoolTTL); err != nil {
		return fmt.Errorf("failed to cache SOS pool for user %s: %w", userID, err)
	}

	return nil
}

// InvalidateSOSPool removes cached SOS content pool.
func (c *AffirmationsCache) InvalidateSOSPool(ctx context.Context, userID string) error {
	key := sosPoolKeyPrefix + userID

	if err := c.client.Delete(ctx, key); err != nil {
		return fmt.Errorf("failed to invalidate SOS pool for user %s: %w", userID, err)
	}

	return nil
}

// --- Favorites List Cache ---

// GetFavorites retrieves cached favorites list. Returns nil if cache miss.
func (c *AffirmationsCache) GetFavorites(ctx context.Context, userID string) ([]string, error) {
	key := favoritesKeyPrefix + userID

	val, err := c.client.Get(ctx, key)
	if err != nil {
		// Cache miss: return nil without error (caller should fall back to DB)
		return nil, nil
	}

	var favorites []string
	if err := json.Unmarshal([]byte(val), &favorites); err != nil {
		return nil, fmt.Errorf("failed to unmarshal favorites for user %s: %w", userID, err)
	}

	return favorites, nil
}

// SetFavorites caches favorites list with a 10-minute TTL.
func (c *AffirmationsCache) SetFavorites(ctx context.Context, userID string, favorites []string) error {
	key := favoritesKeyPrefix + userID

	data, err := json.Marshal(favorites)
	if err != nil {
		return fmt.Errorf("failed to marshal favorites for user %s: %w", userID, err)
	}

	if err := c.client.Set(ctx, key, string(data), favoritesTTL); err != nil {
		return fmt.Errorf("failed to cache favorites for user %s: %w", userID, err)
	}

	return nil
}

// InvalidateFavorites removes cached favorites list.
func (c *AffirmationsCache) InvalidateFavorites(ctx context.Context, userID string) error {
	key := favoritesKeyPrefix + userID

	if err := c.client.Delete(ctx, key); err != nil {
		return fmt.Errorf("failed to invalidate favorites for user %s: %w", userID, err)
	}

	return nil
}

// --- Convenience Methods ---

// InvalidateAll invalidates all affirmation-related cache entries for a user.
// Use this after major user changes (deletion, tenant transfer, etc.).
func (c *AffirmationsCache) InvalidateAll(ctx context.Context, userID string) error {
	// Collect all errors to report complete failure details
	var errs []error

	if err := c.InvalidateMorningSession(ctx, userID); err != nil {
		errs = append(errs, err)
	}

	if err := c.InvalidateProgress(ctx, userID); err != nil {
		errs = append(errs, err)
	}

	if err := c.InvalidateSettings(ctx, userID); err != nil {
		errs = append(errs, err)
	}

	if err := c.InvalidateLevel(ctx, userID); err != nil {
		errs = append(errs, err)
	}

	if err := c.InvalidateSOSPool(ctx, userID); err != nil {
		errs = append(errs, err)
	}

	if err := c.InvalidateFavorites(ctx, userID); err != nil {
		errs = append(errs, err)
	}

	if len(errs) > 0 {
		return fmt.Errorf("failed to invalidate all cache entries for user %s: %v", userID, errs)
	}

	return nil
}
