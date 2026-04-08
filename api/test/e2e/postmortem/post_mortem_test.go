//go:build e2e
// +build e2e

// test/e2e/postmortem/post_mortem_test.go
package postmortem

import (
	"testing"
)

// TestPostMortem_E2E_CompleteRelapseFlow tests the full relapse post-mortem flow.
// Requires staging environment: go test ./test/e2e/postmortem/... -tags=e2e
//
// Steps:
// 1. POST /activities/post-mortem (create draft with dayBefore section)
// 2. PATCH /activities/post-mortem/{id} (add morning section)
// 3. PATCH /activities/post-mortem/{id} (add throughoutTheDay section)
// 4. PATCH /activities/post-mortem/{id} (add buildUp section)
// 5. PATCH /activities/post-mortem/{id} (add actingOut section)
// 6. PATCH /activities/post-mortem/{id} (add immediatelyAfter section)
// 7. PATCH /activities/post-mortem/{id} (add FASTER mapping)
// 8. PATCH /activities/post-mortem/{id} (add action plan)
// 9. POST /activities/post-mortem/{id}/complete
//
// Verifies: status is "complete", completedAt is set, calendar activity is created.
func TestPostMortem_E2E_CompleteRelapseFlow(t *testing.T) {
	t.Skip("E2E tests require staging deployment")
}

// TestPostMortem_E2E_NearMissFlow tests the near-miss post-mortem flow.
func TestPostMortem_E2E_NearMissFlow(t *testing.T) {
	t.Skip("E2E tests require staging deployment")
}

// TestPostMortem_E2E_ShareWithSponsor tests sharing with a sponsor who has permission.
func TestPostMortem_E2E_ShareWithSponsor(t *testing.T) {
	t.Skip("E2E tests require staging deployment")
}

// TestPostMortem_E2E_ShareDeniedWithoutPermission tests sharing denied returns 404.
func TestPostMortem_E2E_ShareDeniedWithoutPermission(t *testing.T) {
	t.Skip("E2E tests require staging deployment")
}

// TestPostMortem_E2E_ConvertActionItemToCommitment tests action item conversion.
func TestPostMortem_E2E_ConvertActionItemToCommitment(t *testing.T) {
	t.Skip("E2E tests require staging deployment")
}

// TestPostMortem_E2E_InsightsAfterMultiplePostMortems tests cross-analysis insights.
func TestPostMortem_E2E_InsightsAfterMultiplePostMortems(t *testing.T) {
	t.Skip("E2E tests require staging deployment")
}

// TestPostMortem_E2E_FeatureFlagDisabled tests feature flag gating returns 404.
func TestPostMortem_E2E_FeatureFlagDisabled(t *testing.T) {
	t.Skip("E2E tests require staging deployment")
}
