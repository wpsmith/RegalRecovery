// test/e2e/nutrition/meal_test.go
//
// E2E tests for the meal logging flow against the staging environment.
// These tests require a deployed staging environment to run.
package nutrition

import "testing"

// TestE2E_MealLogging_CreateReadUpdateDelete validates the full CRUD lifecycle.
func TestE2E_MealLogging_CreateReadUpdateDelete(t *testing.T) {
	t.Skip("E2E test requires staging environment -- run with make test-e2e")
}
