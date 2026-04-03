# Regal Recovery API Test Framework

This directory contains the test framework for the Regal Recovery Go backend.

## Test Structure

```
test/
├── helpers/          # Test utilities (MongoDB, auth, assertions)
├── fixtures/         # Test data (users, activities)
├── unit/             # Unit tests (pure functions, business logic)
└── integration/      # Integration tests (MongoDB, Valkey)
```

## Test Naming Convention

All tests follow the naming pattern:

```
Test<Entity>_<AcceptanceCriteria>_<Scenario>
```

Examples:
- `TestStreak_FR2_2_CalculatesCurrentStreakInRealTime`
- `TestFlag_EvaluateEnabled_ReturnsTrue`
- `TestRegister_ValidInput_CreatesUser`

This convention makes it easy to trace tests back to feature specifications and acceptance criteria.

## Running Tests

### Unit Tests

```bash
# Run all unit tests
go test ./test/unit/... -v

# Run specific test file
go test ./test/unit/tracking_test.go -v

# Run tests with coverage
go test ./test/unit/... -cover

# Run tests with race detector
go test ./test/unit/... -race
```

### Integration Tests

Integration tests require MongoDB and Valkey to be running.

```bash
# Start local services
make local-up

# Run integration tests
go test ./test/integration/... -v -tags=integration

# Stop local services
make local-down
```

## Test Helpers

### MongoDB Helper (`helpers/mongo_helper.go`)

Provides utilities for setting up test MongoDB:

- `SetupTestMongo(t *testing.T) *repository.MongoClient` - Creates MongoDB client pointing to localhost:27017
- `SeedTestData(t *testing.T, client *repository.MongoClient)` - Seeds test fixtures into the database
- `CleanupDatabase(t *testing.T, client *repository.MongoClient)` - Drops the test database

### Auth Helper (`helpers/auth_helper.go`)

Provides utilities for test authentication:

- `TestUserContext(userID, tenantID string) context.Context` - Creates context with auth claims
- `DevToken() string` - Returns "dev-token" for local auth bypass

### Assertions Helper (`helpers/assertions.go`)

Provides custom assertions for API responses:

- `AssertSiemensEnvelope(t *testing.T, body []byte)` - Verifies Siemens API envelope format
- `AssertSiemensError(t *testing.T, body []byte, expectedStatus int)` - Verifies error envelope
- `AssertJSON(t *testing.T, body []byte, key string, expected interface{})` - Extract and compare JSON values

## Test Fixtures

### Users (`fixtures/users.json`)

Contains the Alex persona fixture with:
- UserID: `u_alex`
- Email: `alex@example.com`
- Sobriety date: July 4, 2025
- Bible version: ESV
- Timezone: America/Chicago

### Activities (`fixtures/activities.json`)

Contains sample activities for Alex:
- 5 check-ins over the past 5 days
- 3 urge logs with varying intensity
- 2 journal entries

## Writing New Tests

### Unit Test Example

```go
// TestFeature_AcceptanceCriteria_Scenario verifies that [description].
//
// Acceptance Criterion (Feature X): [criterion from spec]
func TestFeature_AcceptanceCriteria_Scenario(t *testing.T) {
	// Given - Setup test data

	// When - Execute the function under test

	// Then - Assert expected outcomes
	if result != expected {
		t.Errorf("expected %v, got %v", expected, result)
	}
}
```

### Integration Test Example

```go
//go:build integration

func TestRepository_GetUser_ReturnsUser(t *testing.T) {
	// Given - MongoDB
	client := helpers.SetupTestMongo(t)
	defer helpers.CleanupDatabase(t, client)

	// Seed test data
	// ...

	// When - Call repository method

	// Then - Assert database state
}
```

## Mock Objects

Tests use mock implementations of repository interfaces rather than real database connections. This keeps unit tests fast and isolated.

Example mock pattern:

```go
type MockUserRepository struct {
	users map[string]*User
}

func (m *MockUserRepository) CreateUser(ctx context.Context, user *User) error {
	m.users[user.ID] = user
	return nil
}
```

## Test Coverage Requirements

| Scope | Target |
|-------|--------|
| Overall backend | 80% |
| Business logic (domain/) | 90% |
| Critical algorithms | 100% |
| API handlers | 75% |

Critical paths requiring 100% coverage:
- Streak calculation
- Permission checking
- FASTER Scale scoring
- Flag evaluation

## CI/CD Integration

Tests run automatically in GitHub Actions on every push and pull request.

Quality gates:
- All tests must pass
- Coverage must meet minimum thresholds
- No race conditions detected
- Code passes linting

## Related Documentation

- [Test Strategy](/Users/travis.smith/Projects/personal/RR/docs/specs/testing/test-strategy.md)
- [SPEC-PLAN](/Users/travis.smith/Projects/personal/RR/docs/specs/SPEC-PLAN.md)
- [Feature Specifications](/Users/travis.smith/Projects/personal/RR/docs/02-feature-specifications.md)
