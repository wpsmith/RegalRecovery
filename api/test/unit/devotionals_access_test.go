// test/unit/devotionals_access_test.go
package unit

import (
	"errors"
	"testing"

	"github.com/regalrecovery/api/internal/domain/devotionals"
)

// =============================================================================
// Content Tier Access Tests
// Location: internal/domain/devotionals/access_test.go (spec)
// =============================================================================

// TestAccess_AC_DEV_CONTENT_04_PremiumUnlockedForever verifies that once
// a premium series is purchased, access is permanently granted.
func TestAccess_AC_DEV_CONTENT_04_PremiumUnlockedForever(t *testing.T) {
	// Given: user purchased series_X
	checker := devotionals.NewAccessChecker()
	seriesID := "series_X"
	content := &devotionals.DevotionalContent{
		Tier:     devotionals.TierPremium,
		SeriesID: &seriesID,
	}
	ownedSeries := map[string]bool{"series_X": true}

	// When
	err := checker.CheckAccess(content, ownedSeries)

	// Then: access granted
	if err != nil {
		t.Errorf("expected access granted for owned premium series, got %v", err)
	}
}

// TestAccess_AC_DEV_CONTENT_05_LockedPremiumContent verifies that premium
// content is locked when the user has not purchased the containing series.
func TestAccess_AC_DEV_CONTENT_05_LockedPremiumContent(t *testing.T) {
	// Given: user has NOT purchased series_X
	checker := devotionals.NewAccessChecker()
	seriesID := "series_X"
	content := &devotionals.DevotionalContent{
		Tier:     devotionals.TierPremium,
		SeriesID: &seriesID,
	}
	ownedSeries := map[string]bool{}

	// When
	err := checker.CheckAccess(content, ownedSeries)

	// Then: 403 equivalent error
	if !errors.Is(err, devotionals.ErrPremiumContentLocked) {
		t.Errorf("expected ErrPremiumContentLocked, got %v", err)
	}
}

// TestAccess_FreeTierCanAccessFreeContent verifies that free-tier content
// is accessible to all users.
func TestAccess_FreeTierCanAccessFreeContent(t *testing.T) {
	// Given: free-tier content
	checker := devotionals.NewAccessChecker()
	content := &devotionals.DevotionalContent{
		Tier: devotionals.TierFree,
	}
	ownedSeries := map[string]bool{}

	// When
	err := checker.CheckAccess(content, ownedSeries)

	// Then: access granted
	if err != nil {
		t.Errorf("expected access granted for free content, got %v", err)
	}
}

// TestAccess_AC_DEV_EDGE_05_FeatureFlagDisabled verifies that all endpoints
// return 404 when the feature flag is disabled.
func TestAccess_AC_DEV_EDGE_05_FeatureFlagDisabled(t *testing.T) {
	// Given: feature flag disabled
	err := devotionals.CheckFeatureFlag(false)

	// Then
	if !errors.Is(err, devotionals.ErrFeatureDisabled) {
		t.Errorf("expected ErrFeatureDisabled, got %v", err)
	}
}

// TestAccess_FeatureFlagEnabled verifies normal operation when flag is enabled.
func TestAccess_FeatureFlagEnabled(t *testing.T) {
	err := devotionals.CheckFeatureFlag(true)
	if err != nil {
		t.Errorf("expected no error when flag enabled, got %v", err)
	}
}

// TestAccess_IsLocked_PremiumNotOwned verifies isLocked helper.
func TestAccess_IsLocked_PremiumNotOwned(t *testing.T) {
	checker := devotionals.NewAccessChecker()
	seriesID := "series_X"

	locked := checker.IsLocked(devotionals.TierPremium, &seriesID, map[string]bool{})
	if !locked {
		t.Error("expected premium content to be locked when not owned")
	}
}

// TestAccess_IsLocked_PremiumOwned verifies isLocked when owned.
func TestAccess_IsLocked_PremiumOwned(t *testing.T) {
	checker := devotionals.NewAccessChecker()
	seriesID := "series_X"

	locked := checker.IsLocked(devotionals.TierPremium, &seriesID, map[string]bool{"series_X": true})
	if locked {
		t.Error("expected premium content to be unlocked when owned")
	}
}

// TestAccess_IsLocked_FreeTier verifies free content is never locked.
func TestAccess_IsLocked_FreeTier(t *testing.T) {
	checker := devotionals.NewAccessChecker()

	locked := checker.IsLocked(devotionals.TierFree, nil, map[string]bool{})
	if locked {
		t.Error("expected free content to never be locked")
	}
}
