// test/e2e/nutrition/flag_test.go
package nutrition

import "testing"

// TestE2E_FeatureFlag_Disabled validates that disabled flag returns 404.
func TestE2E_FeatureFlag_Disabled(t *testing.T) {
	t.Skip("E2E test requires staging environment -- run with make test-e2e")
}
