// internal/domain/devotionals/access.go
package devotionals

import "errors"

var (
	// ErrPremiumContentLocked indicates the user has not purchased the premium content.
	ErrPremiumContentLocked = errors.New("premium content locked")

	// ErrFeatureDisabled indicates the devotionals feature flag is disabled.
	ErrFeatureDisabled = errors.New("feature disabled")
)

// AccessChecker verifies whether a user can access a devotional.
type AccessChecker struct{}

// NewAccessChecker creates a new AccessChecker.
func NewAccessChecker() *AccessChecker {
	return &AccessChecker{}
}

// CheckAccess verifies that the user can access the given devotional content.
// Free-tier content is accessible to all users.
// Premium content requires the user to own the containing series.
func (c *AccessChecker) CheckAccess(content *DevotionalContent, ownedSeriesIDs map[string]bool) error {
	if content.Tier == TierFree {
		return nil
	}

	// Premium content -- check if user owns the series
	if content.SeriesID != nil && ownedSeriesIDs[*content.SeriesID] {
		return nil
	}

	return ErrPremiumContentLocked
}

// IsLocked returns whether a devotional is locked for the user.
// A devotional is locked if it is premium and the user does not own the containing series.
func (c *AccessChecker) IsLocked(tier ContentTier, seriesID *string, ownedSeriesIDs map[string]bool) bool {
	if tier == TierFree {
		return false
	}
	if seriesID != nil && ownedSeriesIDs[*seriesID] {
		return false
	}
	return true
}

// CheckFeatureFlag verifies the devotionals feature is enabled.
// Returns ErrFeatureDisabled if the flag is not enabled.
func CheckFeatureFlag(enabled bool) error {
	if !enabled {
		return ErrFeatureDisabled
	}
	return nil
}
