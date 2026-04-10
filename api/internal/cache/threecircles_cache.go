// internal/cache/threecircles_cache.go
package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/regalrecovery/api/internal/domain/threecircles"
)

const (
	// Cache key prefixes
	setsKeyPrefix         = "3c:sets:"
	setKeyPrefix          = "3c:set:"
	templatesKeyPrefix    = "3c:templates:"
	starterPacksKeyPrefix = "3c:starterpacks:"
	onboardingKeyPrefix   = "3c:onboarding:"
	timelineKeyPrefix     = "3c:timeline:"
	summaryKeyPrefix      = "3c:summary:"
	insightsKeyPrefix     = "3c:insights:"
	driftKeyPrefix        = "3c:drift:"

	// TTLs for different cache entries
	setsTTL         = 10 * time.Minute // 10-min TTL for set list
	setTTL          = 10 * time.Minute // 10-min TTL for set detail
	templatesTTL    = 30 * time.Minute // 30-min TTL for templates
	starterPacksTTL = 30 * time.Minute // 30-min TTL for starter packs
	onboardingTTL   = 10 * time.Minute // 10-min TTL for active onboarding
	timelineTTL     = 5 * time.Minute  // 5-min TTL for timeline data
	summaryTTL      = 10 * time.Minute // 10-min TTL for summary
	insightsTTL     = 10 * time.Minute // 10-min TTL for insights
	driftTTL        = 5 * time.Minute  // 5-min TTL for drift alerts
)

// ThreeCirclesCache implements cache-aside pattern for Three Circles data.
type ThreeCirclesCache struct {
	client *ValkeyClient
}

// NewThreeCirclesCache creates a new ThreeCirclesCache with the given Valkey client.
func NewThreeCirclesCache(client *ValkeyClient) *ThreeCirclesCache {
	return &ThreeCirclesCache{client: client}
}

// --- Circle Sets Cache ---

// GetSets retrieves cached set list for a user. Returns nil if cache miss.
func (c *ThreeCirclesCache) GetSets(ctx context.Context, userID string) ([]threecircles.CircleSet, error) {
	key := setsKeyPrefix + userID

	val, err := c.client.Get(ctx, key)
	if err != nil {
		// Cache miss: return nil without error (caller should fall back to DB)
		return nil, nil
	}

	var sets []threecircles.CircleSet
	if err := json.Unmarshal([]byte(val), &sets); err != nil {
		return nil, fmt.Errorf("failed to unmarshal sets for user %s: %w", userID, err)
	}

	return sets, nil
}

// SetSets caches set list with a 10-minute TTL.
func (c *ThreeCirclesCache) SetSets(ctx context.Context, userID string, sets []threecircles.CircleSet) error {
	key := setsKeyPrefix + userID

	data, err := json.Marshal(sets)
	if err != nil {
		return fmt.Errorf("failed to marshal sets for user %s: %w", userID, err)
	}

	if err := c.client.Set(ctx, key, string(data), setsTTL); err != nil {
		return fmt.Errorf("failed to cache sets for user %s: %w", userID, err)
	}

	return nil
}

// InvalidateSets removes cached set list.
func (c *ThreeCirclesCache) InvalidateSets(ctx context.Context, userID string) error {
	key := setsKeyPrefix + userID

	if err := c.client.Delete(ctx, key); err != nil {
		return fmt.Errorf("failed to invalidate sets for user %s: %w", userID, err)
	}

	return nil
}

// GetSet retrieves cached set detail. Returns nil if cache miss.
func (c *ThreeCirclesCache) GetSet(ctx context.Context, setID string) (*threecircles.CircleSet, error) {
	key := setKeyPrefix + setID

	val, err := c.client.Get(ctx, key)
	if err != nil {
		// Cache miss: return nil without error (caller should fall back to DB)
		return nil, nil
	}

	var set threecircles.CircleSet
	if err := json.Unmarshal([]byte(val), &set); err != nil {
		return nil, fmt.Errorf("failed to unmarshal set %s: %w", setID, err)
	}

	return &set, nil
}

// SetSet caches set detail with a 10-minute TTL.
func (c *ThreeCirclesCache) SetSet(ctx context.Context, setID string, set *threecircles.CircleSet) error {
	key := setKeyPrefix + setID

	data, err := json.Marshal(set)
	if err != nil {
		return fmt.Errorf("failed to marshal set %s: %w", setID, err)
	}

	if err := c.client.Set(ctx, key, string(data), setTTL); err != nil {
		return fmt.Errorf("failed to cache set %s: %w", setID, err)
	}

	return nil
}

// InvalidateSet removes cached set detail.
func (c *ThreeCirclesCache) InvalidateSet(ctx context.Context, setID string) error {
	key := setKeyPrefix + setID

	if err := c.client.Delete(ctx, key); err != nil {
		return fmt.Errorf("failed to invalidate set %s: %w", setID, err)
	}

	return nil
}

// --- Templates Cache ---

// GetTemplates retrieves cached templates for a recovery area. Returns nil if cache miss.
func (c *ThreeCirclesCache) GetTemplates(ctx context.Context, recoveryArea string) ([]threecircles.Template, error) {
	key := templatesKeyPrefix + recoveryArea

	val, err := c.client.Get(ctx, key)
	if err != nil {
		// Cache miss: return nil without error (caller should fall back to DB)
		return nil, nil
	}

	var templates []threecircles.Template
	if err := json.Unmarshal([]byte(val), &templates); err != nil {
		return nil, fmt.Errorf("failed to unmarshal templates for area %s: %w", recoveryArea, err)
	}

	return templates, nil
}

// SetTemplates caches templates with a 30-minute TTL.
func (c *ThreeCirclesCache) SetTemplates(ctx context.Context, recoveryArea string, templates []threecircles.Template) error {
	key := templatesKeyPrefix + recoveryArea

	data, err := json.Marshal(templates)
	if err != nil {
		return fmt.Errorf("failed to marshal templates for area %s: %w", recoveryArea, err)
	}

	if err := c.client.Set(ctx, key, string(data), templatesTTL); err != nil {
		return fmt.Errorf("failed to cache templates for area %s: %w", recoveryArea, err)
	}

	return nil
}

// InvalidateTemplates removes cached templates.
func (c *ThreeCirclesCache) InvalidateTemplates(ctx context.Context, recoveryArea string) error {
	key := templatesKeyPrefix + recoveryArea

	if err := c.client.Delete(ctx, key); err != nil {
		return fmt.Errorf("failed to invalidate templates for area %s: %w", recoveryArea, err)
	}

	return nil
}

// --- Starter Packs Cache ---

// GetStarterPacks retrieves cached starter packs for a recovery area. Returns nil if cache miss.
func (c *ThreeCirclesCache) GetStarterPacks(ctx context.Context, recoveryArea string) ([]threecircles.StarterPack, error) {
	key := starterPacksKeyPrefix + recoveryArea

	val, err := c.client.Get(ctx, key)
	if err != nil {
		// Cache miss: return nil without error (caller should fall back to DB)
		return nil, nil
	}

	var packs []threecircles.StarterPack
	if err := json.Unmarshal([]byte(val), &packs); err != nil {
		return nil, fmt.Errorf("failed to unmarshal starter packs for area %s: %w", recoveryArea, err)
	}

	return packs, nil
}

// SetStarterPacks caches starter packs with a 30-minute TTL.
func (c *ThreeCirclesCache) SetStarterPacks(ctx context.Context, recoveryArea string, packs []threecircles.StarterPack) error {
	key := starterPacksKeyPrefix + recoveryArea

	data, err := json.Marshal(packs)
	if err != nil {
		return fmt.Errorf("failed to marshal starter packs for area %s: %w", recoveryArea, err)
	}

	if err := c.client.Set(ctx, key, string(data), starterPacksTTL); err != nil {
		return fmt.Errorf("failed to cache starter packs for area %s: %w", recoveryArea, err)
	}

	return nil
}

// InvalidateStarterPacks removes cached starter packs.
func (c *ThreeCirclesCache) InvalidateStarterPacks(ctx context.Context, recoveryArea string) error {
	key := starterPacksKeyPrefix + recoveryArea

	if err := c.client.Delete(ctx, key); err != nil {
		return fmt.Errorf("failed to invalidate starter packs for area %s: %w", recoveryArea, err)
	}

	return nil
}

// --- Onboarding Cache ---

// GetOnboarding retrieves cached onboarding flow. Returns nil if cache miss.
func (c *ThreeCirclesCache) GetOnboarding(ctx context.Context, userID string) (*threecircles.OnboardingFlow, error) {
	key := onboardingKeyPrefix + userID

	val, err := c.client.Get(ctx, key)
	if err != nil {
		// Cache miss: return nil without error (caller should fall back to DB)
		return nil, nil
	}

	var flow threecircles.OnboardingFlow
	if err := json.Unmarshal([]byte(val), &flow); err != nil {
		return nil, fmt.Errorf("failed to unmarshal onboarding for user %s: %w", userID, err)
	}

	return &flow, nil
}

// SetOnboarding caches onboarding flow with a 10-minute TTL.
func (c *ThreeCirclesCache) SetOnboarding(ctx context.Context, userID string, flow *threecircles.OnboardingFlow) error {
	key := onboardingKeyPrefix + userID

	data, err := json.Marshal(flow)
	if err != nil {
		return fmt.Errorf("failed to marshal onboarding for user %s: %w", userID, err)
	}

	if err := c.client.Set(ctx, key, string(data), onboardingTTL); err != nil {
		return fmt.Errorf("failed to cache onboarding for user %s: %w", userID, err)
	}

	return nil
}

// InvalidateOnboarding removes cached onboarding flow.
func (c *ThreeCirclesCache) InvalidateOnboarding(ctx context.Context, userID string) error {
	key := onboardingKeyPrefix + userID

	if err := c.client.Delete(ctx, key); err != nil {
		return fmt.Errorf("failed to invalidate onboarding for user %s: %w", userID, err)
	}

	return nil
}

// --- Timeline Cache ---

// GetTimeline retrieves cached timeline data. Returns nil if cache miss.
func (c *ThreeCirclesCache) GetTimeline(ctx context.Context, userID, period string) ([]threecircles.TimelineEntry, error) {
	key := fmt.Sprintf("%s%s:%s", timelineKeyPrefix, userID, period)

	val, err := c.client.Get(ctx, key)
	if err != nil {
		// Cache miss: return nil without error (caller should fall back to DB)
		return nil, nil
	}

	var entries []threecircles.TimelineEntry
	if err := json.Unmarshal([]byte(val), &entries); err != nil {
		return nil, fmt.Errorf("failed to unmarshal timeline for user %s period %s: %w", userID, period, err)
	}

	return entries, nil
}

// SetTimeline caches timeline data with a 5-minute TTL.
func (c *ThreeCirclesCache) SetTimeline(ctx context.Context, userID, period string, entries []threecircles.TimelineEntry) error {
	key := fmt.Sprintf("%s%s:%s", timelineKeyPrefix, userID, period)

	data, err := json.Marshal(entries)
	if err != nil {
		return fmt.Errorf("failed to marshal timeline for user %s period %s: %w", userID, period, err)
	}

	if err := c.client.Set(ctx, key, string(data), timelineTTL); err != nil {
		return fmt.Errorf("failed to cache timeline for user %s period %s: %w", userID, period, err)
	}

	return nil
}

// InvalidateTimeline removes cached timeline data.
func (c *ThreeCirclesCache) InvalidateTimeline(ctx context.Context, userID, period string) error {
	key := fmt.Sprintf("%s%s:%s", timelineKeyPrefix, userID, period)

	if err := c.client.Delete(ctx, key); err != nil {
		return fmt.Errorf("failed to invalidate timeline for user %s period %s: %w", userID, period, err)
	}

	return nil
}

// --- Summary Cache ---

// GetSummary retrieves cached summary data. Returns nil if cache miss.
func (c *ThreeCirclesCache) GetSummary(ctx context.Context, userID, period string) (*threecircles.TimelineSummary, error) {
	key := fmt.Sprintf("%s%s:%s", summaryKeyPrefix, userID, period)

	val, err := c.client.Get(ctx, key)
	if err != nil {
		// Cache miss: return nil without error (caller should fall back to DB)
		return nil, nil
	}

	var summary threecircles.TimelineSummary
	if err := json.Unmarshal([]byte(val), &summary); err != nil {
		return nil, fmt.Errorf("failed to unmarshal summary for user %s period %s: %w", userID, period, err)
	}

	return &summary, nil
}

// SetSummary caches summary data with a 10-minute TTL.
func (c *ThreeCirclesCache) SetSummary(ctx context.Context, userID, period string, summary *threecircles.TimelineSummary) error {
	key := fmt.Sprintf("%s%s:%s", summaryKeyPrefix, userID, period)

	data, err := json.Marshal(summary)
	if err != nil {
		return fmt.Errorf("failed to marshal summary for user %s period %s: %w", userID, period, err)
	}

	if err := c.client.Set(ctx, key, string(data), summaryTTL); err != nil {
		return fmt.Errorf("failed to cache summary for user %s period %s: %w", userID, period, err)
	}

	return nil
}

// InvalidateSummary removes cached summary data.
func (c *ThreeCirclesCache) InvalidateSummary(ctx context.Context, userID, period string) error {
	key := fmt.Sprintf("%s%s:%s", summaryKeyPrefix, userID, period)

	if err := c.client.Delete(ctx, key); err != nil {
		return fmt.Errorf("failed to invalidate summary for user %s period %s: %w", userID, period, err)
	}

	return nil
}

// --- Insights Cache ---

// GetInsights retrieves cached insights. Returns nil if cache miss.
func (c *ThreeCirclesCache) GetInsights(ctx context.Context, userID string) ([]threecircles.PatternInsight, error) {
	key := insightsKeyPrefix + userID

	val, err := c.client.Get(ctx, key)
	if err != nil {
		// Cache miss: return nil without error (caller should fall back to DB)
		return nil, nil
	}

	var insights []threecircles.PatternInsight
	if err := json.Unmarshal([]byte(val), &insights); err != nil {
		return nil, fmt.Errorf("failed to unmarshal insights for user %s: %w", userID, err)
	}

	return insights, nil
}

// SetInsights caches insights with a 10-minute TTL.
func (c *ThreeCirclesCache) SetInsights(ctx context.Context, userID string, insights []threecircles.PatternInsight) error {
	key := insightsKeyPrefix + userID

	data, err := json.Marshal(insights)
	if err != nil {
		return fmt.Errorf("failed to marshal insights for user %s: %w", userID, err)
	}

	if err := c.client.Set(ctx, key, string(data), insightsTTL); err != nil {
		return fmt.Errorf("failed to cache insights for user %s: %w", userID, err)
	}

	return nil
}

// InvalidateInsights removes cached insights.
func (c *ThreeCirclesCache) InvalidateInsights(ctx context.Context, userID string) error {
	key := insightsKeyPrefix + userID

	if err := c.client.Delete(ctx, key); err != nil {
		return fmt.Errorf("failed to invalidate insights for user %s: %w", userID, err)
	}

	return nil
}

// --- Drift Alerts Cache ---

// GetDriftAlerts retrieves cached drift alerts. Returns nil if cache miss.
func (c *ThreeCirclesCache) GetDriftAlerts(ctx context.Context, userID string) ([]threecircles.DriftAlert, error) {
	key := driftKeyPrefix + userID

	val, err := c.client.Get(ctx, key)
	if err != nil {
		// Cache miss: return nil without error (caller should fall back to DB)
		return nil, nil
	}

	var alerts []threecircles.DriftAlert
	if err := json.Unmarshal([]byte(val), &alerts); err != nil {
		return nil, fmt.Errorf("failed to unmarshal drift alerts for user %s: %w", userID, err)
	}

	return alerts, nil
}

// SetDriftAlerts caches drift alerts with a 5-minute TTL.
func (c *ThreeCirclesCache) SetDriftAlerts(ctx context.Context, userID string, alerts []threecircles.DriftAlert) error {
	key := driftKeyPrefix + userID

	data, err := json.Marshal(alerts)
	if err != nil {
		return fmt.Errorf("failed to marshal drift alerts for user %s: %w", userID, err)
	}

	if err := c.client.Set(ctx, key, string(data), driftTTL); err != nil {
		return fmt.Errorf("failed to cache drift alerts for user %s: %w", userID, err)
	}

	return nil
}

// InvalidateDriftAlerts removes cached drift alerts.
func (c *ThreeCirclesCache) InvalidateDriftAlerts(ctx context.Context, userID string) error {
	key := driftKeyPrefix + userID

	if err := c.client.Delete(ctx, key); err != nil {
		return fmt.Errorf("failed to invalidate drift alerts for user %s: %w", userID, err)
	}

	return nil
}

// --- Convenience Methods ---

// InvalidateAll invalidates all Three Circles cache entries for a user.
// Use this after major user changes (deletion, tenant transfer, etc.).
func (c *ThreeCirclesCache) InvalidateAll(ctx context.Context, userID string) error {
	// Collect all errors to report complete failure details
	var errs []error

	if err := c.InvalidateSets(ctx, userID); err != nil {
		errs = append(errs, err)
	}

	if err := c.InvalidateOnboarding(ctx, userID); err != nil {
		errs = append(errs, err)
	}

	if err := c.InvalidateInsights(ctx, userID); err != nil {
		errs = append(errs, err)
	}

	if err := c.InvalidateDriftAlerts(ctx, userID); err != nil {
		errs = append(errs, err)
	}

	// Invalidate all timeline periods
	for _, period := range []string{"7d", "30d", "90d", "1y", "all"} {
		if err := c.InvalidateTimeline(ctx, userID, period); err != nil {
			errs = append(errs, err)
		}
		if err := c.InvalidateSummary(ctx, userID, period); err != nil {
			errs = append(errs, err)
		}
	}

	if len(errs) > 0 {
		return fmt.Errorf("failed to invalidate all cache entries for user %s: %v", userID, errs)
	}

	return nil
}
