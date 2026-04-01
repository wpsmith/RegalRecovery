# Regal Recovery — Test Strategy

**Version:** 1.0.0
**Date:** 2026-03-28
**Status:** Draft

---

## Table of Contents

1. [Testing Philosophy](#1-testing-philosophy)
2. [Test Pyramid & Budget](#2-test-pyramid--budget)
3. [Go Backend Test Strategy](#3-go-backend-test-strategy)
4. [Native Mobile Test Strategy](#4-native-mobile-test-strategy)
5. [Test Data Strategy](#5-test-data-strategy)
6. [Test Coverage Requirements](#6-test-coverage-requirements)
7. [CI/CD Integration](#7-cicd-integration)
8. [Acceptance Criteria → Test Case Mapping](#8-acceptance-criteria--test-case-mapping)
9. [OpenAPI Contract Testing](#9-openapi-contract-testing)
10. [Testing Anti-Patterns](#10-testing-anti-patterns)

---

## 1. Testing Philosophy

### Spec-Driven + Test-Driven Development

Regal Recovery follows a **contract-first, test-first** development approach:

1. **Design** — OpenAPI specification written first, reviewed against requirements
2. **Generate** — Mock servers, client SDKs, and server stubs generated from spec
3. **Red** — Write failing test that captures acceptance criterion
4. **Green** — Implement minimum code to make test pass
5. **Refactor** — Improve design while keeping tests green
6. **Verify** — Contract tests ensure implementation matches spec

### Core Principles

- **Tests are documentation.** A developer should understand the system's behavior by reading tests alone.
- **Every acceptance criterion becomes at least one test case.** If it's in the PRD, it's testable.
- **Write tests BEFORE implementation.** The test is the first client of your API.
- **Tests must be independent and parallelizable.** No shared mutable state between tests.
- **Fast feedback loop.** Unit tests run in milliseconds; integration tests in seconds; E2E tests in minutes.
- **Test business rules, not implementation details.** If refactoring breaks tests, the tests are coupled to implementation.

### Red-Green-Refactor Cycle

```
┌─────────────┐
│   RED       │  Write a failing test that captures a requirement
└─────┬───────┘
      │
      ▼
┌─────────────┐
│   GREEN     │  Write minimum code to make the test pass
└─────┬───────┘
      │
      ▼
┌─────────────┐
│   REFACTOR  │  Improve the design without changing behavior
└─────┬───────┘
      │
      ▼
    (repeat)
```

### Zero-Defect Mindset

- **Every bug found in production triggers a new test.** If a bug escaped, the test suite has a gap.
- **Tests run on every commit.** CI blocks merges when tests fail.
- **Coverage thresholds are enforced.** PRs are rejected below minimum coverage.
- **Flaky tests are quarantined immediately.** Flakiness above 2% blocks deployment.

---

## 2. Test Pyramid & Budget

### Test Pyramid (Target Distribution)

```
           /       \
          /   E2E   \          <- 5-10% of test budget
         /___________\         Expensive, slow, brittle
        /             \
       /  Integration  \       <- 20-30% of test budget
      /_________________\      Test domain boundaries
     /                   \
    /    Unit Tests       \    <- 60-70% of test budget
   /_______________________\   Fast, cheap, reliable
```

### Test Budget by Layer

| Layer | % of Tests | Execution Time | Scope |
|-------|-----------|----------------|-------|
| **Unit** | 60-70% | < 100ms per test | Business logic, calculations, domain rules |
| **Integration** | 20-30% | 1-5 seconds per test | Database access, AWS services (via LocalStack), event processing |
| **E2E** | 5-10% | 5-30 seconds per test | API + Lambda + DynamoDB + Authentication |

### Critical Path Testing (Higher Coverage)

Critical paths require **E2E + Integration + Unit** coverage:

- Authentication (register, login, token refresh, MFA, passkey)
- Sobriety streak calculation (reset on relapse, timezone handling)
- FASTER Scale scoring and stage detection
- Recovery Health Score calculation
- Permission checking (opt-in model enforcement)
- Data deletion (ephemeral entries, account deletion)
- Relapse logging (immutable timestamps, streak reset, post-mortem prompt)

---

## 3. Go Backend Test Strategy

### 3.1 Project Structure

```
backend/
├── cmd/
│   └── api/                 # Lambda handler entry points
├── internal/
│   ├── api/                 # Generated OpenAPI types and interfaces
│   ├── domain/              # Business logic (100% unit tested)
│   │   ├── streak/          # Streak calculation
│   │   ├── scoring/         # FASTER, PCI, RHS calculation
│   │   ├── permissions/     # Permission checking
│   │   └── ...
│   ├── repository/          # DynamoDB access patterns
│   ├── service/             # Application services
│   └── handler/             # HTTP handlers
├── pkg/
│   ├── testutil/            # Shared test utilities
│   └── fixtures/            # Test data fixtures
└── test/
    ├── unit/                # Unit tests (fast, no I/O)
    ├── integration/         # Integration tests (LocalStack)
    └── e2e/                 # End-to-end API tests
```

### 3.2 Unit Tests

**Location:** Co-located with production code (`*_test.go`)

**Naming Convention:** `Test<FunctionName>_<Scenario>_<ExpectedBehavior>`

#### Example: Sobriety Streak Calculation

```go
// internal/domain/streak/calculator_test.go
package streak_test

import (
	"testing"
	"time"

	"github.com/regalrecovery/backend/internal/domain/streak"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestCalculateStreak_NoRelapse_ReturnsCorrectDayCount(t *testing.T) {
	// Given
	sobrietyStartDate := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
	currentDate := time.Date(2026, 3, 28, 0, 0, 0, 0, time.UTC)
	relapseHistory := []time.Time{} // No relapses

	calculator := streak.NewCalculator()

	// When
	result := calculator.Calculate(sobrietyStartDate, currentDate, relapseHistory)

	// Then
	assert.Equal(t, 86, result.CurrentStreakDays, "should count 86 days from Jan 1 to Mar 28, 2026")
	assert.Equal(t, 86, result.LongestStreakDays)
	assert.Nil(t, result.LastRelapseDate)
}

func TestCalculateStreak_AfterRelapse_ResetsToZero(t *testing.T) {
	// Given
	sobrietyStartDate := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
	relapseDate := time.Date(2026, 3, 28, 22, 15, 0, 0, time.UTC)
	currentDate := time.Date(2026, 3, 29, 10, 0, 0, 0, time.UTC) // Next day
	relapseHistory := []time.Time{relapseDate}

	calculator := streak.NewCalculator()

	// When
	result := calculator.Calculate(sobrietyStartDate, currentDate, relapseHistory)

	// Then
	assert.Equal(t, 0, result.CurrentStreakDays, "streak resets to 0 after relapse")
	assert.Equal(t, 86, result.LongestStreakDays, "longest streak preserved")
	require.NotNil(t, result.LastRelapseDate)
	assert.Equal(t, relapseDate, *result.LastRelapseDate)
}

func TestCalculateStreak_AcrossTimezones_HandlesCorrectly(t *testing.T) {
	// Given - User in Los Angeles (UTC-8)
	la, _ := time.LoadLocation("America/Los_Angeles")
	sobrietyStartDate := time.Date(2026, 1, 1, 0, 0, 0, 0, la)

	// User relapses at 11 PM PST on March 28
	relapseDate := time.Date(2026, 3, 28, 23, 0, 0, 0, la)

	// Current time: 1 AM PST on March 29 (same day in PST, next day in UTC)
	currentDate := time.Date(2026, 3, 29, 1, 0, 0, 0, la)
	relapseHistory := []time.Time{relapseDate}

	calculator := streak.NewCalculator()

	// When
	result := calculator.Calculate(sobrietyStartDate, currentDate, relapseHistory)

	// Then
	// Streak should reset because relapse was yesterday in user's timezone
	assert.Equal(t, 0, result.CurrentStreakDays, "timezone-aware calculation resets streak correctly")
}

func TestCalculateStreak_MultipleRelapses_TracksLongestStreak(t *testing.T) {
	// Given
	sobrietyStartDate := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
	currentDate := time.Date(2026, 3, 28, 0, 0, 0, 0, time.UTC)
	relapseHistory := []time.Time{
		time.Date(2026, 1, 30, 0, 0, 0, 0, time.UTC), // 29-day streak
		time.Date(2026, 2, 15, 0, 0, 0, 0, time.UTC), // 16-day streak
		time.Date(2026, 3, 1, 0, 0, 0, 0, time.UTC),  // 14-day streak, then 27 days to Mar 28
	}

	calculator := streak.NewCalculator()

	// When
	result := calculator.Calculate(sobrietyStartDate, currentDate, relapseHistory)

	// Then
	assert.Equal(t, 27, result.CurrentStreakDays, "current streak from last relapse to now")
	assert.Equal(t, 29, result.LongestStreakDays, "longest streak was 29 days")
}
```

#### Example: FASTER Scale Scoring

```go
// internal/domain/scoring/faster_test.go
package scoring_test

import (
	"testing"

	"github.com/regalrecovery/backend/internal/domain/scoring"
	"github.com/stretchr/testify/assert"
)

func TestFASTERScale_RestoreStage_NoRedFlags(t *testing.T) {
	// Given
	indicators := scoring.FASTERIndicators{
		Forgetting:            false,
		Anxiety:              false,
		Speeding:             false,
		Ticked:               false,
		Exhausted:            false,
		Relapse:              false,
	}

	calculator := scoring.NewFASTERCalculator()

	// When
	result := calculator.Calculate(indicators)

	// Then
	assert.Equal(t, scoring.StageRestore, result.Stage)
	assert.Empty(t, result.Warnings)
	assert.False(t, result.RequiresAlert)
}

func TestFASTERScale_ForgetfulStage_OneIndicator(t *testing.T) {
	// Given
	indicators := scoring.FASTERIndicators{
		Forgetting:            true, // Skipping meetings, avoiding spiritual practices
		Anxiety:              false,
		Speeding:             false,
		Ticked:               false,
		Exhausted:            false,
		Relapse:              false,
	}

	calculator := scoring.NewFASTERCalculator()

	// When
	result := calculator.Calculate(indicators)

	// Then
	assert.Equal(t, scoring.StageForgetful, result.Stage)
	assert.Contains(t, result.Warnings, "You're skipping important recovery practices")
	assert.False(t, result.RequiresAlert, "single indicator does not trigger alert")
}

func TestFASTERScale_RelapseStage_TriggersAlert(t *testing.T) {
	// Given
	indicators := scoring.FASTERIndicators{
		Forgetting:            true,
		Anxiety:              true,
		Speeding:             true,
		Ticked:               true,
		Exhausted:            true,
		Relapse:              true, // Active relapse
	}

	calculator := scoring.NewFASTERCalculator()

	// When
	result := calculator.Calculate(indicators)

	// Then
	assert.Equal(t, scoring.StageRelapse, result.Stage)
	assert.True(t, result.RequiresAlert, "relapse stage always triggers alert")
	assert.Contains(t, result.AlertContacts, "sponsor")
	assert.Contains(t, result.AlertContacts, "counselor")
}

func TestFASTERScale_ThreeOrMoreIndicators_TriggersAlert(t *testing.T) {
	// Given - 3 indicators active (threshold for support network notification)
	indicators := scoring.FASTERIndicators{
		Forgetting:            true,
		Anxiety:              true,
		Speeding:             true,
		Ticked:               false,
		Exhausted:            false,
		Relapse:              false,
	}

	calculator := scoring.NewFASTERCalculator()

	// When
	result := calculator.Calculate(indicators)

	// Then
	assert.True(t, result.RequiresAlert, "3+ indicators trigger support network alert")
}
```

#### Example: Recovery Health Score (Multi-Input Weighted Calculation)

```go
// internal/domain/scoring/recovery_health_test.go
package scoring_test

import (
	"testing"
	"time"

	"github.com/regalrecovery/backend/internal/domain/scoring"
	"github.com/stretchr/testify/assert"
)

func TestRecoveryHealthScore_AllPositiveInputs_Returns100(t *testing.T) {
	// Given - Perfect recovery day
	inputs := scoring.RecoveryHealthInputs{
		SobrietyStreakDays:      60,
		DailyCommitmentMet:      true,
		CheckInScore:            100,
		MeetingAttendedToday:    true,
		SupportContactToday:     true,
		ExerciseMinutes:         30,
		SleepHoursLastNight:     8.0,
		UrgesLoggedToday:        0,
		MoodRating:              9,
		GratitudeEntryToday:     true,
		FasterScaleStage:        scoring.StageRestore,
	}

	calculator := scoring.NewRecoveryHealthScoreCalculator()

	// When
	result := calculator.Calculate(inputs)

	// Then
	assert.Equal(t, 100, result.Score)
	assert.Equal(t, "green", result.ColorCode)
}

func TestRecoveryHealthScore_MixedInputs_ReturnsWeightedScore(t *testing.T) {
	// Given - Decent recovery day with some gaps
	inputs := scoring.RecoveryHealthInputs{
		SobrietyStreakDays:      15,
		DailyCommitmentMet:      true,
		CheckInScore:            70,
		MeetingAttendedToday:    false, // Missed meeting
		SupportContactToday:     true,
		ExerciseMinutes:         0,     // No exercise
		SleepHoursLastNight:     6.0,   // Insufficient sleep
		UrgesLoggedToday:        3,     // Multiple urges
		MoodRating:              6,
		GratitudeEntryToday:     false,
		FasterScaleStage:        scoring.StageForgetful,
	}

	calculator := scoring.NewRecoveryHealthScoreCalculator()

	// When
	result := calculator.Calculate(inputs)

	// Then
	assert.InDelta(t, 58, result.Score, 2, "weighted score reflects mixed inputs")
	assert.Equal(t, "yellow", result.ColorCode)
	assert.Contains(t, result.Recommendations, "Attend a meeting today")
	assert.Contains(t, result.Recommendations, "Get 7-9 hours of sleep tonight")
}

func TestRecoveryHealthScore_RelapseToday_ReturnsZero(t *testing.T) {
	// Given - Relapse occurred today
	inputs := scoring.RecoveryHealthInputs{
		SobrietyStreakDays:      0,
		DailyCommitmentMet:      false,
		CheckInScore:            0,
		MeetingAttendedToday:    false,
		SupportContactToday:     false,
		ExerciseMinutes:         0,
		SleepHoursLastNight:     4.0,
		UrgesLoggedToday:        8,
		MoodRating:              2,
		GratitudeEntryToday:     false,
		FasterScaleStage:        scoring.StageRelapse,
	}

	calculator := scoring.NewRecoveryHealthScoreCalculator()

	// When
	result := calculator.Calculate(inputs)

	// Then
	assert.Equal(t, 0, result.Score)
	assert.Equal(t, "red", result.ColorCode)
	assert.Contains(t, result.Recommendations, "Complete a Post-Mortem Analysis")
}

func TestRecoveryHealthScore_ComponentBreakdown_SumsToTotal(t *testing.T) {
	// Given
	inputs := scoring.RecoveryHealthInputs{
		SobrietyStreakDays:      30,
		DailyCommitmentMet:      true,
		CheckInScore:            80,
		MeetingAttendedToday:    true,
		SupportContactToday:     true,
		ExerciseMinutes:         20,
		SleepHoursLastNight:     7.5,
		UrgesLoggedToday:        1,
		MoodRating:              7,
		GratitudeEntryToday:     true,
		FasterScaleStage:        scoring.StageRestore,
	}

	calculator := scoring.NewRecoveryHealthScoreCalculator()

	// When
	result := calculator.Calculate(inputs)

	// Then
	// Verify component breakdown sums to total score
	componentSum := result.Components.Sobriety +
		result.Components.Commitment +
		result.Components.SupportNetwork +
		result.Components.PhysicalHealth +
		result.Components.EmotionalWellbeing +
		result.Components.FasterScale

	assert.Equal(t, result.Score, componentSum, "component scores must sum to total")
}
```

#### Example: Permission Checking (Opt-In Model)

```go
// internal/domain/permissions/checker_test.go
package permissions_test

import (
	"testing"

	"github.com/regalrecovery/backend/internal/domain/permissions"
	"github.com/stretchr/testify/assert"
)

func TestPermissionChecker_NoPermissionGranted_ReturnsAccessDenied(t *testing.T) {
	// Given
	userID := "user_12345"
	contactID := "contact_67890"
	dataCategory := permissions.CategoryCheckIns
	grantedPermissions := []permissions.Permission{} // No permissions granted

	checker := permissions.NewChecker(grantedPermissions)

	// When
	result := checker.CanAccess(contactID, userID, dataCategory)

	// Then
	assert.False(t, result.Allowed, "default deny: no access without explicit grant")
	assert.Equal(t, permissions.ReasonNoPermission, result.Reason)
}

func TestPermissionChecker_PermissionGranted_ReturnsAccessAllowed(t *testing.T) {
	// Given
	userID := "user_12345"
	contactID := "contact_67890"
	dataCategory := permissions.CategoryCheckIns
	grantedPermissions := []permissions.Permission{
		{
			UserID:       userID,
			ContactID:    contactID,
			DataCategory: permissions.CategoryCheckIns,
			AccessLevel:  permissions.AccessLevelRead,
			GrantedAt:    time.Now(),
		},
	}

	checker := permissions.NewChecker(grantedPermissions)

	// When
	result := checker.CanAccess(contactID, userID, dataCategory)

	// Then
	assert.True(t, result.Allowed, "permission explicitly granted")
}

func TestPermissionChecker_SponsorRole_NoDefaultAccess(t *testing.T) {
	// Given - Sponsor role does NOT grant default access (explicit opt-in required)
	userID := "user_12345"
	sponsorID := "sponsor_67890"
	dataCategory := permissions.CategoryFASTERScale
	grantedPermissions := []permissions.Permission{} // No permissions granted yet

	checker := permissions.NewChecker(grantedPermissions)

	// When
	result := checker.CanAccess(sponsorID, userID, dataCategory)

	// Then
	assert.False(t, result.Allowed, "sponsor has NO default access without explicit grant")
}

func TestPermissionChecker_RevokedPermission_ReturnsAccessDenied(t *testing.T) {
	// Given
	userID := "user_12345"
	contactID := "contact_67890"
	dataCategory := permissions.CategoryUrgeLog
	grantedPermissions := []permissions.Permission{
		{
			UserID:       userID,
			ContactID:    contactID,
			DataCategory: permissions.CategoryUrgeLog,
			AccessLevel:  permissions.AccessLevelRead,
			GrantedAt:    time.Now().Add(-7 * 24 * time.Hour), // Granted 7 days ago
			RevokedAt:    timePtr(time.Now().Add(-1 * time.Hour)), // Revoked 1 hour ago
		},
	}

	checker := permissions.NewChecker(grantedPermissions)

	// When
	result := checker.CanAccess(contactID, userID, dataCategory)

	// Then
	assert.False(t, result.Allowed, "revoked permission denies access")
	assert.Equal(t, permissions.ReasonRevoked, result.Reason)
}
```

#### Example: Immutable Timestamp Enforcement

```go
// internal/domain/activity/timestamp_test.go
package activity_test

import (
	"testing"
	"time"

	"github.com/regalrecovery/backend/internal/domain/activity"
	"github.com/stretchr/testify/assert"
)

func TestActivity_Create_SetsImmutableTimestamp(t *testing.T) {
	// Given
	userID := "user_12345"
	activityType := activity.TypeUrgeLog
	now := time.Now().UTC()

	// When
	act, err := activity.Create(userID, activityType, now, map[string]interface{}{
		"intensity": 7,
		"triggers":  []string{"emotional"},
	})

	// Then
	assert.NoError(t, err)
	assert.Equal(t, now, act.Timestamp)
	assert.True(t, act.TimestampImmutable, "timestamp marked as immutable")
}

func TestActivity_Update_PreventsTimestampModification(t *testing.T) {
	// Given - Activity created yesterday
	userID := "user_12345"
	activityType := activity.TypeUrgeLog
	originalTimestamp := time.Now().UTC().Add(-24 * time.Hour)

	act, _ := activity.Create(userID, activityType, originalTimestamp, map[string]interface{}{
		"intensity": 7,
	})

	// When - Attempt to change timestamp
	err := act.Update(map[string]interface{}{
		"timestamp": time.Now().UTC(), // Try to backdate/forward-date
		"intensity": 8,
	})

	// Then
	assert.Error(t, err, "timestamp modification must fail")
	assert.Contains(t, err.Error(), "timestamp is immutable")
	assert.Equal(t, originalTimestamp, act.Timestamp, "timestamp unchanged")
	assert.Equal(t, 8, act.Data["intensity"], "other fields updated successfully")
}
```

#### Example: Ephemeral Entry Auto-Deletion

```go
// internal/domain/ephemeral/deletion_test.go
package ephemeral_test

import (
	"testing"
	"time"

	"github.com/regalrecovery/backend/internal/domain/ephemeral"
	"github.com/stretchr/testify/assert"
)

func TestEphemeral_Create_SetsTTLCorrectly(t *testing.T) {
	tests := []struct {
		name               string
		retentionPeriod    time.Duration
		expectedTTLSeconds int64
	}{
		{"7 days", 7 * 24 * time.Hour, 7 * 24 * 60 * 60},
		{"30 days", 30 * 24 * time.Hour, 30 * 24 * 60 * 60},
		{"90 days", 90 * 24 * time.Hour, 90 * 24 * 60 * 60},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Given
			now := time.Now().UTC()
			entry := ephemeral.NewEntry("user_12345", "journal", map[string]interface{}{
				"content": "Private thoughts",
			}, tt.retentionPeriod)

			// When
			ttl := entry.TTL

			// Then
			expectedTTL := now.Add(tt.retentionPeriod).Unix()
			assert.InDelta(t, expectedTTL, ttl, 5, "TTL within 5 seconds of expected")
		})
	}
}

func TestEphemeral_IsExpired_ReturnsTrueAfterTTL(t *testing.T) {
	// Given - Entry with 7-day retention created 8 days ago
	pastTimestamp := time.Now().UTC().Add(-8 * 24 * time.Hour)
	entry := ephemeral.NewEntry("user_12345", "journal", map[string]interface{}{
		"content": "Old thought",
	}, 7*24*time.Hour)
	entry.CreatedAt = pastTimestamp
	entry.TTL = pastTimestamp.Add(7 * 24 * time.Hour).Unix()

	// When
	expired := entry.IsExpired(time.Now().UTC())

	// Then
	assert.True(t, expired, "entry expired after TTL")
}

func TestEphemeral_ConvertToPermanent_RemovesTTL(t *testing.T) {
	// Given
	entry := ephemeral.NewEntry("user_12345", "journal", map[string]interface{}{
		"content": "Important thought to keep",
	}, 7*24*time.Hour)

	// When
	err := entry.ConvertToPermanent()

	// Then
	assert.NoError(t, err)
	assert.Equal(t, int64(0), entry.TTL, "TTL removed")
	assert.False(t, entry.IsEphemeral, "no longer marked ephemeral")
}
```

### 3.3 Integration Tests

**Location:** `test/integration/`

**Dependencies:** LocalStack (DynamoDB, S3, SQS, SNS), Docker Compose

#### Example: DynamoDB Repository Test

```go
// test/integration/repository/streak_repository_test.go
// +build integration

package repository_test

import (
	"context"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/regalrecovery/backend/internal/repository"
	"github.com/regalrecovery/backend/pkg/testutil"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestStreakRepository_GetByUser_ReturnsCorrectStreaks(t *testing.T) {
	// Given - LocalStack DynamoDB
	ctx := context.Background()
	cfg, _ := config.LoadDefaultConfig(ctx, config.WithEndpointResolver(
		testutil.LocalStackEndpointResolver(),
	))
	dynamoClient := dynamodb.NewFromConfig(cfg)

	// Seed test data
	testutil.SeedDynamoDB(t, dynamoClient, "streaks", []map[string]interface{}{
		{
			"PK":                "USER#user_12345",
			"SK":                "STREAK#addiction_67890",
			"CurrentStreakDays": 47,
			"LongestStreakDays": 120,
			"SobrietyStartDate": "2026-02-09",
		},
	})

	repo := repository.NewStreakRepository(dynamoClient)

	// When
	streaks, err := repo.GetByUser(ctx, "user_12345")

	// Then
	require.NoError(t, err)
	assert.Len(t, streaks, 1)
	assert.Equal(t, 47, streaks[0].CurrentStreakDays)
	assert.Equal(t, 120, streaks[0].LongestStreakDays)
}

func TestStreakRepository_Update_IncrementsDayCount(t *testing.T) {
	// Given
	ctx := context.Background()
	cfg, _ := config.LoadDefaultConfig(ctx, config.WithEndpointResolver(
		testutil.LocalStackEndpointResolver(),
	))
	dynamoClient := dynamodb.NewFromConfig(cfg)

	testutil.SeedDynamoDB(t, dynamoClient, "streaks", []map[string]interface{}{
		{
			"PK":                "USER#user_12345",
			"SK":                "STREAK#addiction_67890",
			"CurrentStreakDays": 47,
			"LongestStreakDays": 120,
			"SobrietyStartDate": "2026-02-09",
		},
	})

	repo := repository.NewStreakRepository(dynamoClient)

	// When
	err := repo.IncrementStreak(ctx, "user_12345", "addiction_67890")

	// Then
	require.NoError(t, err)

	// Verify
	streaks, _ := repo.GetByUser(ctx, "user_12345")
	assert.Equal(t, 48, streaks[0].CurrentStreakDays)
}
```

#### Example: SQS Event Processing Test

```go
// test/integration/events/relapse_notification_test.go
// +build integration

package events_test

import (
	"context"
	"encoding/json"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
	"github.com/regalrecovery/backend/internal/events"
	"github.com/regalrecovery/backend/pkg/testutil"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestRelapseEventHandler_ProcessesEventAndNotifiesSupportNetwork(t *testing.T) {
	// Given - LocalStack SQS
	ctx := context.Background()
	cfg, _ := config.LoadDefaultConfig(ctx, config.WithEndpointResolver(
		testutil.LocalStackEndpointResolver(),
	))
	sqsClient := sqs.NewFromConfig(cfg)

	queueURL := testutil.CreateSQSQueue(t, sqsClient, "relapse-events")

	// Publish relapse event
	eventPayload := events.RelapseEvent{
		UserID:       "user_12345",
		AddictionID:  "addiction_67890",
		Timestamp:    time.Now().UTC(),
		PreviousStreak: 47,
	}
	eventJSON, _ := json.Marshal(eventPayload)

	_, err := sqsClient.SendMessage(ctx, &sqs.SendMessageInput{
		QueueUrl:    &queueURL,
		MessageBody: stringPtr(string(eventJSON)),
	})
	require.NoError(t, err)

	// When - Handler processes event
	handler := events.NewRelapseEventHandler(sqsClient, mockNotificationService)
	err = handler.ProcessQueue(ctx, queueURL)

	// Then
	require.NoError(t, err)

	// Verify notification sent to support network
	assert.True(t, mockNotificationService.WasCalledWith("sponsor_11111"))
	assert.Contains(t, mockNotificationService.LastMessage, "user_12345 logged a relapse")
}
```

### 3.4 End-to-End API Tests

**Location:** `test/e2e/`

**Dependencies:** Deployed Lambda functions, API Gateway, Cognito, DynamoDB

#### Example: Complete Relapse Logging Flow

```go
// test/e2e/tracking/relapse_test.go
// +build e2e

package tracking_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"testing"
	"time"

	"github.com/regalrecovery/backend/pkg/testutil"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestRelapseLogging_E2E_ResetsStreakAndPromptsPostMortem(t *testing.T) {
	// Given - Authenticated user with active streak
	apiClient := testutil.NewE2EAPIClient(t)
	accessToken := apiClient.Login("test@example.com", "TestPassword123!")

	// Create user with 47-day streak
	apiClient.SetupUserWithStreak(accessToken, "user_12345", 47)

	// When - Log relapse
	relapsePayload := map[string]interface{}{
		"addictionId": "addiction_67890",
		"timestamp":   time.Now().UTC().Format(time.RFC3339),
		"notes":       "Had a difficult conversation earlier",
	}
	relapseJSON, _ := json.Marshal(relapsePayload)

	resp, err := http.Post(
		apiClient.BaseURL+"/v1/tracking/relapses",
		"application/json",
		bytes.NewBuffer(relapseJSON),
	)
	require.NoError(t, err)
	defer resp.Body.Close()

	// Then - Verify response
	assert.Equal(t, http.StatusCreated, resp.StatusCode)
	assert.Equal(t, "application/json", resp.Header.Get("Content-Type"))
	assert.NotEmpty(t, resp.Header.Get("Location"))

	var relapseResp map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&relapseResp)

	data := relapseResp["data"].(map[string]interface{})
	assert.Equal(t, 47.0, data["previousStreakDays"])
	assert.True(t, data["postMortemPrompted"].(bool))

	// Verify streak reset
	streakResp := apiClient.GetStreaks(accessToken)
	streakData := streakResp["data"].([]interface{})[0].(map[string]interface{})
	assert.Equal(t, 0.0, streakData["currentStreakDays"])
	assert.Equal(t, 47.0, streakData["longestStreakDays"])

	// Verify audit trail
	auditResp := apiClient.GetAuditLog(accessToken)
	assert.Contains(t, auditResp["data"], "relapse_logged")
}
```

---

## 4. Native Mobile Test Strategy

### 4.1 Android Business Logic Tests (Kotlin)

**Location:** `androidApp/app/src/test/`

#### Example: Offline Queue Test

```kotlin
// androidApp/app/src/test/java/com/regalrecovery/sync/OfflineQueueTest.kt
package com.regalrecovery.sync

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class OfflineQueueTest {

    @Test
    fun `enqueue activity when offline preserves order`() {
        // Given
        val queue = OfflineQueue()
        val activity1 = Activity(type = ActivityType.URGE_LOG, timestamp = Clock.now())
        val activity2 = Activity(type = ActivityType.CHECK_IN, timestamp = Clock.now().plusMinutes(5))

        // When
        queue.enqueue(activity1)
        queue.enqueue(activity2)

        // Then
        assertEquals(2, queue.size)
        assertEquals(activity1, queue.peek())
    }

    @Test
    fun `replay queue on reconnect uploads in chronological order`() = runTest {
        // Given
        val queue = OfflineQueue()
        val mockApi = MockRecoveryApi()
        val syncManager = SyncManager(queue, mockApi)

        queue.enqueue(Activity(type = ActivityType.URGE_LOG, timestamp = Clock.now()))
        queue.enqueue(Activity(type = ActivityType.CHECK_IN, timestamp = Clock.now().plusMinutes(5)))

        // When
        syncManager.syncWhenConnected()

        // Then
        assertTrue(mockApi.uploadedActivities.size == 2)
        assertTrue(mockApi.uploadedActivities[0].timestamp < mockApi.uploadedActivities[1].timestamp)
    }

    @Test
    fun `conflict resolution merges relapse data from all devices`() = runTest {
        // Given
        val localQueue = listOf(
            RelapseEvent(userId = "user_12345", timestamp = Clock.parse("2026-03-25T22:00:00Z"))
        )
        val serverData = listOf(
            RelapseEvent(userId = "user_12345", timestamp = Clock.parse("2026-03-20T18:00:00Z"))
        )

        val resolver = ConflictResolver()

        // When
        val merged = resolver.mergeRelapses(localQueue, serverData)

        // Then
        assertEquals(2, merged.size) // Union merge
        assertTrue(merged.any { it.timestamp == Clock.parse("2026-03-25T22:00:00Z") })
        assertTrue(merged.any { it.timestamp == Clock.parse("2026-03-20T18:00:00Z") })
    }

    @Test
    fun `sobriety date conflict uses most conservative value`() {
        // Given
        val localSobrietyDate = Clock.parse("2026-01-01")
        val serverSobrietyDate = Clock.parse("2026-03-25") // Later relapse on server

        val resolver = ConflictResolver()

        // When
        val resolvedDate = resolver.resolveSobrietyDate(localSobrietyDate, serverSobrietyDate)

        // Then
        assertEquals(serverSobrietyDate, resolvedDate) // Most conservative (latest relapse) wins
    }
}
```

### 4.2 Jetpack Compose UI Tests

**Location:** `androidApp/app/src/androidTest/`

#### Example: Streak Display Test

```kotlin
// androidApp/app/src/androidTest/java/com/regalrecovery/ui/StreakScreenTest.kt
package com.regalrecovery.ui

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import org.junit.Rule
import org.junit.Test

class StreakScreenTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun streakScreen_displaysCorrectDayCount() {
        // Given
        val streak = Streak(
            currentDays = 47,
            longestDays = 120,
            sobrietyStartDate = LocalDate.parse("2026-02-09")
        )

        // When
        composeTestRule.setContent {
            StreakScreen(streak = streak)
        }

        // Then
        composeTestRule.onNodeWithText("47 days").assertIsDisplayed()
        composeTestRule.onNodeWithText("Longest: 120 days").assertIsDisplayed()
    }

    @Test
    fun streakScreen_darkMode_usesCorrectColors() {
        // Given
        val streak = Streak(currentDays = 47, longestDays = 120, sobrietyStartDate = LocalDate.parse("2026-02-09"))

        // When
        composeTestRule.setContent {
            RecoveryTheme(darkTheme = true) {
                StreakScreen(streak = streak)
            }
        }

        // Then
        composeTestRule.onNodeWithText("47 days")
            .assertIsDisplayed()
            .assertHasBackgroundColor(Color(0xFF1E1E1E)) // Dark background
    }

    @Test
    fun streakScreen_milestoneReached_showsCelebration() {
        // Given
        val streak = Streak(currentDays = 30, longestDays = 30, sobrietyStartDate = LocalDate.parse("2026-02-27"))

        // When
        composeTestRule.setContent {
            StreakScreen(streak = streak, onMilestone = { /* celebration shown */ })
        }

        // Then
        composeTestRule.onNodeWithTag("milestone_celebration").assertIsDisplayed()
        composeTestRule.onNodeWithText("🎉 30 Days Sober!").assertIsDisplayed()
    }
}
```

### 4.3 iOS Business Logic and UI Tests

#### iOS (XCTest)

```swift
// iosApp/RegalRecoveryTests/StreakCalculationTests.swift
import XCTest
@testable import RegalRecovery

class StreakCalculationTests: XCTestCase {

    func testStreakDisplay_formatsDaysCorrectly() {
        // Given
        let streak = Streak(currentDays: 47, longestDays: 120, sobrietyStartDate: Date())
        let viewModel = StreakViewModel(streak: streak)

        // When
        let displayText = viewModel.formattedStreak

        // Then
        XCTAssertEqual(displayText, "47 days")
    }

    func testStreakDisplay_singularDay_omitsPlural() {
        // Given
        let streak = Streak(currentDays: 1, longestDays: 120, sobrietyStartDate: Date())
        let viewModel = StreakViewModel(streak: streak)

        // When
        let displayText = viewModel.formattedStreak

        // Then
        XCTAssertEqual(displayText, "1 day") // No "s"
    }
}
```

#### Android (Espresso)

```kotlin
// androidApp/app/src/androidTest/java/com/regalrecovery/StreakActivityTest.kt
package com.regalrecovery

import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.assertion.ViewAssertions.matches
import androidx.test.espresso.matcher.ViewMatchers.*
import androidx.test.ext.junit.rules.ActivityScenarioRule
import org.junit.Rule
import org.junit.Test

class StreakActivityTest {

    @get:Rule
    val activityRule = ActivityScenarioRule(StreakActivity::class.java)

    @Test
    fun streakActivity_displaysCorrectStreak() {
        // Given - Activity launched with streak data
        activityRule.scenario.onActivity { activity ->
            activity.setStreak(Streak(currentDays = 47, longestDays = 120))
        }

        // Then
        onView(withId(R.id.streak_days)).check(matches(withText("47 days")))
        onView(withId(R.id.longest_streak)).check(matches(withText("Longest: 120 days")))
    }
}
```

---

## 5. Test Data Strategy

### 5.1 Persona-Based Test Fixtures

Test data organized around user personas from the PRD.

```go
// pkg/fixtures/personas.go
package fixtures

import "time"

type Persona struct {
	UserID              string
	Email               string
	DisplayName         string
	PrimaryAddiction    string
	SobrietyStartDate   time.Time
	CurrentStreakDays   int
	RelapseHistory      []time.Time
	HasSponsor          bool
	HasSpouse           bool
	VulnerabilityWindow string // "evening", "morning", "afternoon"
	Language            string
}

var Alex = Persona{
	UserID:            "user_alex",
	Email:             "alex@example.com",
	DisplayName:       "Alex",
	PrimaryAddiction:  "sex-addiction",
	SobrietyStartDate: time.Date(2025, 6, 1, 0, 0, 0, 0, time.UTC),
	CurrentStreakDays: 270,
	RelapseHistory: []time.Time{
		time.Date(2025, 5, 15, 0, 0, 0, 0, time.UTC),
	},
	HasSponsor:          true,
	HasSpouse:           true,
	VulnerabilityWindow: "evening",
	Language:            "en",
}

var Marcus = Persona{
	UserID:            "user_marcus",
	Email:             "marcus@example.com",
	DisplayName:       "Marcus",
	PrimaryAddiction:  "pornography",
	SobrietyStartDate: time.Date(2026, 1, 15, 0, 0, 0, 0, time.UTC),
	CurrentStreakDays: 73,
	RelapseHistory:    []time.Time{},
	HasSponsor:        false, // No sponsor yet
	HasSpouse:         false,
	VulnerabilityWindow: "evening",
	Language:            "en",
}

var Diego = Persona{
	UserID:            "user_diego",
	Email:             "diego@example.com",
	DisplayName:       "Diego",
	PrimaryAddiction:  "sex-addiction",
	SobrietyStartDate: time.Date(2025, 11, 1, 0, 0, 0, 0, time.UTC),
	CurrentStreakDays: 147,
	RelapseHistory: []time.Time{
		time.Date(2025, 10, 1, 0, 0, 0, 0, time.UTC),
	},
	HasSponsor:          true,
	HasSpouse:           true,
	VulnerabilityWindow: "afternoon",
	Language:            "es", // Spanish content
}
```

### 5.2 Test Data Factories

```go
// pkg/fixtures/factory.go
package fixtures

import (
	"time"

	"github.com/google/uuid"
)

type UrgeLogFactory struct{}

func (f *UrgeLogFactory) Build(overrides ...func(*UrgeLog)) UrgeLog {
	urge := UrgeLog{
		UrgeID:              uuid.NewString(),
		UserID:              "user_12345",
		AddictionID:         "addiction_67890",
		Timestamp:           time.Now().UTC(),
		Intensity:           5,
		Triggers:            []string{"emotional"},
		Notes:               "Feeling stressed",
		SobrietyMaintained:  true,
		DurationMinutes:     10,
	}

	for _, override := range overrides {
		override(&urge)
	}

	return urge
}

// Usage in tests:
// factory := fixtures.UrgeLogFactory{}
// highIntensityUrge := factory.Build(func(u *UrgeLog) {
//     u.Intensity = 9
//     u.SobrietyMaintained = false
// })
```

### 5.3 Seed Data for Test Scenarios

```go
// test/integration/seeds/seed_data.go
package seeds

func SeedMarcusEveningVulnerabilityScenario(t *testing.T, db *dynamodb.Client) {
	// Marcus: no sponsor, evening vulnerability, 73-day streak
	testutil.SeedDynamoDB(t, db, "users", []map[string]interface{}{
		{
			"PK":                "USER#user_marcus",
			"SK":                "PROFILE",
			"DisplayName":       "Marcus",
			"PrimaryAddiction":  "pornography",
			"SobrietyStartDate": "2026-01-15",
			"HasSponsor":        false,
		},
	})

	testutil.SeedDynamoDB(t, db, "streaks", []map[string]interface{}{
		{
			"PK":                "USER#user_marcus",
			"SK":                "STREAK#addiction_marcus",
			"CurrentStreakDays": 73,
			"LongestStreakDays": 73,
		},
	})

	// Seed urge logs showing evening vulnerability
	for i := 0; i < 7; i++ {
		timestamp := time.Now().UTC().Add(-24 * time.Duration(i) * time.Hour).Add(20 * time.Hour) // 8 PM
		testutil.SeedDynamoDB(t, db, "urges", []map[string]interface{}{
			{
				"PK":        "USER#user_marcus",
				"SK":        "URGE#" + timestamp.Format(time.RFC3339),
				"Intensity": 7 + i%3,
				"Triggers":  []string{"digital", "emotional"},
			},
		})
	}
}
```

---

## 6. Test Coverage Requirements

### 6.1 Minimum Coverage Thresholds

| Scope | Metric | Target |
|-------|--------|--------|
| **Overall backend** | Line coverage | 80% |
| **Business logic (domain/)** | Line coverage | 90% |
| **Critical algorithms** | Branch coverage | 100% |
| **API handlers** | Line coverage | 75% |
| **Android business logic** | Line coverage | 85% |
| **iOS business logic** | Line coverage | 85% |

### 6.2 100% Coverage Requirements

The following modules MUST achieve 100% line and branch coverage:

- **Streak calculation** (`internal/domain/streak/`)
- **Permission checking** (`internal/domain/permissions/`)
- **FASTER Scale scoring** (`internal/domain/scoring/faster.go`)
- **Recovery Health Score** (`internal/domain/scoring/recovery_health.go`)
- **PCI scoring** (`internal/domain/scoring/pci.go`)
- **Ephemeral data deletion** (`internal/domain/ephemeral/`)
- **Immutable timestamp enforcement** (`internal/domain/activity/`)

### 6.3 Coverage Enforcement in CI

```yaml
# .github/workflows/test.yml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.22'

      - name: Run unit tests with coverage
        run: go test ./... -coverprofile=coverage.out -covermode=atomic

      - name: Check coverage thresholds
        run: |
          go tool cover -func=coverage.out | grep total | awk '{print $3}' | sed 's/%//' | \
          awk '{if ($1 < 80) {print "Coverage below 80%: " $1 "%"; exit 1}}'

      - name: Check critical module coverage
        run: |
          go test ./internal/domain/streak/... -coverprofile=streak_coverage.out
          go tool cover -func=streak_coverage.out | grep total | awk '{print $3}' | sed 's/%//' | \
          awk '{if ($1 < 100) {print "Streak coverage below 100%: " $1 "%"; exit 1}}'

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v4
        with:
          files: ./coverage.out
```

---

## 7. CI/CD Integration

### 7.1 GitHub Actions Workflow

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.22'

      - name: golangci-lint
        uses: golangci/golangci-lint-action@v4
        with:
          version: latest

  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.22'

      - name: Run unit tests
        run: go test ./... -tags=unit -v -coverprofile=coverage.out

      - name: Enforce coverage thresholds
        run: |
          ./scripts/check_coverage.sh

  integration-tests:
    runs-on: ubuntu-latest
    services:
      localstack:
        image: localstack/localstack:latest
        ports:
          - 4566:4566
        env:
          SERVICES: dynamodb,s3,sqs,sns
          DEFAULT_REGION: us-east-1

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.22'

      - name: Wait for LocalStack
        run: |
          until curl -s http://localhost:4566/_localstack/health | grep '"dynamodb": "available"'; do
            echo "Waiting for LocalStack..."
            sleep 2
          done

      - name: Create DynamoDB tables
        run: |
          aws dynamodb create-table \
            --endpoint-url http://localhost:4566 \
            --table-name regal-recovery \
            --attribute-definitions AttributeName=PK,AttributeType=S AttributeName=SK,AttributeType=S \
            --key-schema AttributeName=PK,KeyType=HASH AttributeName=SK,KeyType=RANGE \
            --billing-mode PAY_PER_REQUEST

      - name: Run integration tests
        run: go test ./test/integration/... -tags=integration -v
        env:
          AWS_ENDPOINT_URL: http://localhost:4566
          AWS_ACCESS_KEY_ID: test
          AWS_SECRET_ACCESS_KEY: test
          AWS_REGION: us-east-1

  contract-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Validate OpenAPI spec
        run: |
          npm install -g @redocly/cli
          redocly lint docs/openapi.yaml

      - name: Run contract tests
        run: |
          npm install -g dredd
          dredd docs/openapi.yaml http://localhost:8080 --hookfiles=test/contract/hooks.go

  deploy-staging:
    needs: [lint, unit-tests, integration-tests, contract-tests]
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Deploy to staging
        run: |
          sam build
          sam deploy --stack-name regal-recovery-staging --no-confirm-changeset

  e2e-tests:
    needs: [deploy-staging]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.22'

      - name: Run E2E tests against staging
        run: go test ./test/e2e/... -tags=e2e -v
        env:
          API_BASE_URL: https://staging-api.regalrecovery.com
          TEST_USER_EMAIL: ${{ secrets.TEST_USER_EMAIL }}
          TEST_USER_PASSWORD: ${{ secrets.TEST_USER_PASSWORD }}

  quality-gate:
    needs: [lint, unit-tests, integration-tests, contract-tests, e2e-tests]
    runs-on: ubuntu-latest
    if: always()
    steps:
      - name: Check all tests passed
        run: |
          if [[ "${{ needs.lint.result }}" != "success" || \
                "${{ needs.unit-tests.result }}" != "success" || \
                "${{ needs.integration-tests.result }}" != "success" || \
                "${{ needs.contract-tests.result }}" != "success" || \
                "${{ needs.e2e-tests.result }}" != "success" ]]; then
            echo "Quality gate FAILED: One or more test suites did not pass"
            exit 1
          fi
          echo "Quality gate PASSED: All tests passed"
```

### 7.2 Quality Gates

**PR Merge Criteria:**

- ✅ All tests pass (lint, unit, integration, contract, E2E)
- ✅ Code coverage ≥ 80% overall
- ✅ Critical modules ≥ 100% coverage
- ✅ No security vulnerabilities detected
- ✅ OpenAPI spec validation passes
- ✅ Contract tests pass

**Deployment Criteria:**

- ✅ All quality gates passed
- ✅ E2E tests passed on staging environment
- ✅ Manual approval for production deployment

---

## 8. Acceptance Criteria → Test Case Mapping

Every acceptance criterion in the PRD maps to one or more test cases. This section provides concrete examples.

### 8.1 Example: Sobriety Streak Calculation

**Acceptance Criterion (PRD Section: Feature 3 - Tracking System):**

> **Given** a user sets their sobriety start date to February 9, 2026, **When** they view their streak on March 28, 2026, and have not logged any relapses, **Then** the app displays "47 days" as their current streak.

**Test Case Mapping:**

```go
// Test: TestCalculateStreak_NoRelapse_ReturnsCorrectDayCount
// Location: internal/domain/streak/calculator_test.go
// Maps to: PRD Feature 3 - Sobriety streak calculation
func TestCalculateStreak_NoRelapse_ReturnsCorrectDayCount(t *testing.T) {
	// Given
	sobrietyStartDate := time.Date(2026, 2, 9, 0, 0, 0, 0, time.UTC)
	currentDate := time.Date(2026, 3, 28, 0, 0, 0, 0, time.UTC)
	relapseHistory := []time.Time{}

	calculator := streak.NewCalculator()

	// When
	result := calculator.Calculate(sobrietyStartDate, currentDate, relapseHistory)

	// Then
	assert.Equal(t, 47, result.CurrentStreakDays, "should count 47 days from Feb 9 to Mar 28, 2026")
}
```

### 8.2 Example: Relapse Event Handling

**Acceptance Criterion (PRD Section: Feature 3 - Tracking System):**

> **Given** a user with a 47-day streak logs a relapse, **When** the relapse is recorded, **Then** the streak resets to 0 days, the previous 47-day streak is preserved in history, and the user is prompted to complete a Post-Mortem Analysis.

**Test Case Mapping:**

```go
// Test: TestRelapseLogging_ResetsStreakAndPromptsPostMortem
// Location: test/e2e/tracking/relapse_test.go
// Maps to: PRD Feature 3 - Relapse logging
func TestRelapseLogging_E2E_ResetsStreakAndPromptsPostMortem(t *testing.T) {
	// Given - User with 47-day streak
	apiClient := testutil.NewE2EAPIClient(t)
	accessToken := apiClient.Login("test@example.com", "TestPassword123!")
	apiClient.SetupUserWithStreak(accessToken, "user_12345", 47)

	// When - Log relapse
	relapsePayload := map[string]interface{}{
		"addictionId": "addiction_67890",
		"timestamp":   time.Now().UTC().Format(time.RFC3339),
		"notes":       "Had a difficult conversation earlier",
	}
	resp := apiClient.PostRelapse(accessToken, relapsePayload)

	// Then
	assert.Equal(t, http.StatusCreated, resp.StatusCode)

	data := resp.Data.(map[string]interface{})
	assert.Equal(t, 47.0, data["previousStreakDays"])
	assert.True(t, data["postMortemPrompted"].(bool))

	// Verify streak reset
	streakResp := apiClient.GetStreaks(accessToken)
	streakData := streakResp["data"].([]interface{})[0].(map[string]interface{})
	assert.Equal(t, 0.0, streakData["currentStreakDays"])
	assert.Equal(t, 47.0, streakData["longestStreakDays"])
}
```

### 8.3 Example: Permission Checking (Opt-In Model)

**Acceptance Criterion (PRD Section: Feature 9 - Community):**

> **Given** a user has not granted their sponsor permission to view check-in data, **When** the sponsor attempts to view the user's check-ins, **Then** the API returns 404 Not Found (not 403) to hide the existence of the data.

**Test Case Mapping:**

```go
// Test: TestPermissionChecker_NoPermissionGranted_Returns404
// Location: internal/handler/checkin_handler_test.go
// Maps to: PRD Feature 9 - Opt-in permission model
func TestCheckInHandler_SponsorWithoutPermission_Returns404(t *testing.T) {
	// Given
	userID := "user_12345"
	sponsorID := "sponsor_67890"

	// User has NOT granted sponsor permission
	permissionRepo := mocks.NewPermissionRepository()
	permissionRepo.SetPermissions(userID, []permissions.Permission{}) // No permissions

	handler := NewCheckInHandler(permissionRepo, checkInRepo)

	req := httptest.NewRequest("GET", "/v1/activities/check-ins?userId=user_12345", nil)
	req = req.WithContext(context.WithValue(req.Context(), "requestorID", sponsorID))

	w := httptest.NewRecorder()

	// When
	handler.ServeHTTP(w, req)

	// Then
	assert.Equal(t, http.StatusNotFound, w.Code, "returns 404, not 403, to hide data existence")

	var errResp map[string]interface{}
	json.NewDecoder(w.Body).Decode(&errResp)
	assert.Contains(t, errResp["errors"].([]interface{})[0].(map[string]interface{})["detail"],
		"not found")
}
```

### 8.4 Example: Immutable Timestamp Enforcement

**Acceptance Criterion (PRD Section: FR2.7 - Functional Requirements):**

> **Given** a user creates an urge log entry with a timestamp, **When** they attempt to update the entry later and modify the timestamp, **Then** the update fails and returns an error indicating that timestamps are immutable.

**Test Case Mapping:**

```go
// Test: TestActivity_Update_PreventsTimestampModification
// Location: internal/domain/activity/timestamp_test.go
// Maps to: PRD FR2.7 - Immutable timestamps
func TestActivity_Update_PreventsTimestampModification(t *testing.T) {
	// Given - Activity created yesterday
	userID := "user_12345"
	activityType := activity.TypeUrgeLog
	originalTimestamp := time.Now().UTC().Add(-24 * time.Hour)

	act, _ := activity.Create(userID, activityType, originalTimestamp, map[string]interface{}{
		"intensity": 7,
	})

	// When - Attempt to change timestamp
	err := act.Update(map[string]interface{}{
		"timestamp": time.Now().UTC(), // Try to backdate/forward-date
		"intensity": 8,
	})

	// Then
	assert.Error(t, err, "timestamp modification must fail")
	assert.Contains(t, err.Error(), "timestamp is immutable")
	assert.Equal(t, originalTimestamp, act.Timestamp, "timestamp unchanged")
	assert.Equal(t, 8, act.Data["intensity"], "other fields updated successfully")
}
```

### 8.5 Example: FASTER Scale Alert Threshold

**Acceptance Criterion (PRD Section: Feature - FASTER Scale):**

> **Given** a user completes a FASTER Scale self-assessment, **When** 3 or more indicators are active (regardless of stage), **Then** the system triggers an alert notification to the user's support network (sponsor, counselor if configured).

**Test Case Mapping:**

```go
// Test: TestFASTERScale_ThreeOrMoreIndicators_TriggersAlert
// Location: internal/domain/scoring/faster_test.go
// Maps to: PRD Feature - FASTER Scale alert threshold
func TestFASTERScale_ThreeOrMoreIndicators_TriggersAlert(t *testing.T) {
	// Given - 3 indicators active (threshold for support network notification)
	indicators := scoring.FASTERIndicators{
		Forgetting:            true,
		Anxiety:              true,
		Speeding:             true,
		Ticked:               false,
		Exhausted:            false,
		Relapse:              false,
	}

	calculator := scoring.NewFASTERCalculator()

	// When
	result := calculator.Calculate(indicators)

	// Then
	assert.True(t, result.RequiresAlert, "3+ indicators trigger support network alert")
	assert.Contains(t, result.AlertContacts, "sponsor")
	assert.Contains(t, result.AlertContacts, "counselor")
}
```

---

## 9. OpenAPI Contract Testing

### 9.1 Contract-First Development Workflow

1. **Design** — Write OpenAPI 3.1 spec in `docs/openapi.yaml`
2. **Validate** — `redocly lint docs/openapi.yaml`
3. **Generate** — Mock server + client SDKs + Go server stubs
4. **Test** — Contract tests ensure implementation matches spec
5. **Document** — Auto-generate API reference docs

### 9.2 OpenAPI Spec Validation

```yaml
# .github/workflows/openapi-validation.yml
name: OpenAPI Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install Redocly CLI
        run: npm install -g @redocly/cli

      - name: Validate OpenAPI spec
        run: redocly lint docs/openapi.yaml --strict

      - name: Generate API docs
        run: redocly build-docs docs/openapi.yaml -o docs/api/index.html

      - name: Upload API docs
        uses: actions/upload-artifact@v4
        with:
          name: api-docs
          path: docs/api/
```

### 9.3 Contract Testing with Dredd

```go
// test/contract/hooks.go
package main

import (
	"github.com/snikch/goodman/hooks"
	"github.com/snikch/goodman/transaction"
)

func main() {
	h := hooks.NewHooks()
	server := hooks.NewServer(hooks.NewHooksRunner(h))

	h.Before("/v1/auth/login > POST > 200", func(t *transaction.Transaction) {
		// Set up test user before login test
		t.Skip = false
	})

	h.BeforeEach(func(t *transaction.Transaction) {
		// Authenticate requests
		if t.Name != "Auth > Login" {
			t.Request.Headers.Set("Authorization", "Bearer test_token")
		}
	})

	h.AfterAll(func(t []*transaction.Transaction) {
		// Clean up test data
	})

	server.Serve()
}
```

```bash
# Run contract tests
dredd docs/openapi.yaml http://localhost:8080 --hookfiles=test/contract/hooks.go
```

### 9.4 Mock Server for Mobile Development

```bash
# Generate mock server from OpenAPI spec
npm install -g @stoplight/prism-cli

# Start mock server
prism mock docs/openapi.yaml --port 4010

# Mobile clients can develop against mock server before backend is ready
# Example request:
curl http://localhost:4010/v1/tracking/streaks \
  -H "Authorization: Bearer mock_token"
```

---

## 10. Testing Anti-Patterns

### 10.1 Anti-Patterns to Avoid

❌ **Testing implementation details** — Tests should verify behavior, not internal structure.

```go
// BAD: Tightly coupled to internal field names
func TestBadExample(t *testing.T) {
	calculator := NewCalculator()
	assert.Equal(t, "default_value", calculator.internalField)
}

// GOOD: Tests observable behavior
func TestGoodExample(t *testing.T) {
	calculator := NewCalculator()
	result := calculator.Calculate(input)
	assert.Equal(t, expectedOutput, result)
}
```

❌ **Shared mutable state** — Tests that depend on execution order or shared state are flaky.

```go
// BAD: Global state shared between tests
var globalCounter int

func TestBad1(t *testing.T) {
	globalCounter++
	assert.Equal(t, 1, globalCounter)
}

func TestBad2(t *testing.T) {
	globalCounter++
	assert.Equal(t, 1, globalCounter) // Flaky! Depends on execution order
}

// GOOD: Each test is independent
func TestGood1(t *testing.T) {
	counter := 0
	counter++
	assert.Equal(t, 1, counter)
}

func TestGood2(t *testing.T) {
	counter := 0
	counter++
	assert.Equal(t, 1, counter)
}
```

❌ **Sleeping in tests** — Sleep calls make tests slow and flaky.

```go
// BAD: Arbitrary sleep
func TestBadAsync(t *testing.T) {
	go doSomethingAsync()
	time.Sleep(2 * time.Second) // Flaky! What if it takes 2.5 seconds?
	assert.True(t, completed)
}

// GOOD: Wait for condition with timeout
func TestGoodAsync(t *testing.T) {
	done := make(chan bool)
	go func() {
		doSomethingAsync()
		done <- true
	}()

	select {
	case <-done:
		assert.True(t, completed)
	case <-time.After(5 * time.Second):
		t.Fatal("test timed out")
	}
}
```

❌ **Testing multiple concepts in one test** — Each test should verify one behavior.

```go
// BAD: Tests multiple behaviors
func TestBadMultipleBehaviors(t *testing.T) {
	streak := Calculate(startDate, endDate, relapses)
	assert.Equal(t, 47, streak.CurrentDays)
	assert.Equal(t, 120, streak.LongestDays)
	assert.True(t, streak.IsActive)
	// Which assertion actually failed when this test breaks?
}

// GOOD: Separate tests
func TestCurrentStreakDays(t *testing.T) {
	streak := Calculate(startDate, endDate, relapses)
	assert.Equal(t, 47, streak.CurrentDays)
}

func TestLongestStreakDays(t *testing.T) {
	streak := Calculate(startDate, endDate, relapses)
	assert.Equal(t, 120, streak.LongestDays)
}
```

❌ **Not cleaning up test data** — Tests that don't clean up pollute the database.

```go
// BAD: No cleanup
func TestBadCleanup(t *testing.T) {
	db.Insert(testUser)
	// ... assertions ...
	// Test ends, test data remains
}

// GOOD: Cleanup with t.Cleanup or defer
func TestGoodCleanup(t *testing.T) {
	testUser := db.Insert(userFixture)
	t.Cleanup(func() {
		db.Delete(testUser.ID)
	})
	// ... assertions ...
}
```

---

## 11. Feature Flag System Tests

### 11.1 Flag Evaluation Logic (Unit Tests)

**Location:** `internal/domain/flags/evaluator_test.go`

```go
func TestFlagEvaluator_EnabledFalse_ReturnsDisabled(t *testing.T) {
	// Given - Kill switch activated
	flag := FlagConfig{
		Key:                "feature.recovery-agent",
		Enabled:            false, // Kill switch
		RolloutPercentage:  100,
		Tiers:              []string{"*"},
		Tenants:            []string{"*"},
		Platforms:          []string{"*"},
		MinAppVersion:      "",
	}
	user := User{
		ID:            "user_12345",
		Tier:          "premium",
		Tenant:        "DEFAULT",
		Platform:      "ios",
		AppVersion:    "1.2.0",
	}

	evaluator := NewFlagEvaluator()

	// When
	result := evaluator.Evaluate(flag, user)

	// Then
	assert.False(t, result.Enabled, "kill switch overrides all other settings")
	assert.Equal(t, "flag_disabled", result.Reason)
}

func TestFlagEvaluator_TierGating_OnlyPremiumPlus(t *testing.T) {
	// Given - Flag restricted to Premium+ tier
	flag := FlagConfig{
		Key:                "feature.couples-mode",
		Enabled:            true,
		RolloutPercentage:  100,
		Tiers:              []string{"premium-plus"},
		Tenants:            []string{"*"},
		Platforms:          []string{"*"},
		MinAppVersion:      "",
	}
	premiumUser := User{ID: "user_12345", Tier: "premium", Platform: "ios", AppVersion: "1.2.0"}
	premiumPlusUser := User{ID: "user_67890", Tier: "premium-plus", Platform: "ios", AppVersion: "1.2.0"}

	evaluator := NewFlagEvaluator()

	// When
	premiumResult := evaluator.Evaluate(flag, premiumUser)
	premiumPlusResult := evaluator.Evaluate(flag, premiumPlusUser)

	// Then
	assert.False(t, premiumResult.Enabled, "premium user denied access")
	assert.Equal(t, "tier_not_allowed", premiumResult.Reason)
	assert.True(t, premiumPlusResult.Enabled, "premium-plus user granted access")
}

func TestFlagEvaluator_RolloutPercentage_ConsistentHashing(t *testing.T) {
	// Given - 50% rollout
	flag := FlagConfig{
		Key:                "activity.time-journal",
		Enabled:            true,
		RolloutPercentage:  50,
		Tiers:              []string{"*"},
		Tenants:            []string{"*"},
		Platforms:          []string{"*"},
		MinAppVersion:      "",
	}
	users := generateTestUsers(1000)

	evaluator := NewFlagEvaluator()

	// When
	enabledCount := 0
	for _, user := range users {
		result := evaluator.Evaluate(flag, user)
		if result.Enabled {
			enabledCount++
		}
	}

	// Then
	// With 1000 users and 50% rollout, expect ~500 (allow ±5% variance)
	assert.InDelta(t, 500, enabledCount, 50, "rollout percentage distribution")

	// Verify deterministic: same user always gets same result
	user := users[0]
	result1 := evaluator.Evaluate(flag, user)
	result2 := evaluator.Evaluate(flag, user)
	assert.Equal(t, result1.Enabled, result2.Enabled, "consistent hashing")
}

func TestFlagEvaluator_PlatformGating_iOSOnly(t *testing.T) {
	// Given - Feature only available on iOS
	flag := FlagConfig{
		Key:                "feature.passkey-auth",
		Enabled:            true,
		RolloutPercentage:  100,
		Tiers:              []string{"*"},
		Tenants:            []string{"*"},
		Platforms:          []string{"ios"},
		MinAppVersion:      "",
	}
	iosUser := User{ID: "user_12345", Platform: "ios", AppVersion: "1.2.0"}
	androidUser := User{ID: "user_67890", Platform: "android", AppVersion: "1.2.0"}

	evaluator := NewFlagEvaluator()

	// When
	iosResult := evaluator.Evaluate(flag, iosUser)
	androidResult := evaluator.Evaluate(flag, androidUser)

	// Then
	assert.True(t, iosResult.Enabled, "iOS user granted access")
	assert.False(t, androidResult.Enabled, "Android user denied access")
	assert.Equal(t, "platform_not_allowed", androidResult.Reason)
}

func TestFlagEvaluator_VersionGating_RequiresMinVersion(t *testing.T) {
	// Given - Feature requires app version 1.3.0+
	flag := FlagConfig{
		Key:                "activity.time-journal",
		Enabled:            true,
		RolloutPercentage:  100,
		Tiers:              []string{"*"},
		Tenants:            []string{"*"},
		Platforms:          []string{"*"},
		MinAppVersion:      "1.3.0",
	}
	oldVersionUser := User{ID: "user_12345", Platform: "ios", AppVersion: "1.2.9"}
	newVersionUser := User{ID: "user_67890", Platform: "ios", AppVersion: "1.3.0"}

	evaluator := NewFlagEvaluator()

	// When
	oldResult := evaluator.Evaluate(flag, oldVersionUser)
	newResult := evaluator.Evaluate(flag, newVersionUser)

	// Then
	assert.False(t, oldResult.Enabled, "old version user denied access")
	assert.Equal(t, "version_too_old", oldResult.Reason)
	assert.True(t, newResult.Enabled, "new version user granted access")
}

func TestFlagEvaluator_TenantGating_B2BRestriction(t *testing.T) {
	// Given - Feature restricted to specific tenant
	flag := FlagConfig{
		Key:                "feature.custom-branding",
		Enabled:            true,
		RolloutPercentage:  100,
		Tiers:              []string{"*"},
		Tenants:            []string{"tenant_acme"},
		Platforms:          []string{"*"},
		MinAppVersion:      "",
	}
	acmeUser := User{ID: "user_12345", Tenant: "tenant_acme", Platform: "ios", AppVersion: "1.2.0"}
	defaultUser := User{ID: "user_67890", Tenant: "DEFAULT", Platform: "ios", AppVersion: "1.2.0"}

	evaluator := NewFlagEvaluator()

	// When
	acmeResult := evaluator.Evaluate(flag, acmeUser)
	defaultResult := evaluator.Evaluate(flag, defaultUser)

	// Then
	assert.True(t, acmeResult.Enabled, "ACME tenant user granted access")
	assert.False(t, defaultResult.Enabled, "default tenant user denied access")
	assert.Equal(t, "tenant_not_allowed", defaultResult.Reason)
}
```

### 11.2 Flag CRUD Integration Tests

**Location:** `test/integration/flags/flag_repository_test.go`

```go
func TestFlagRepository_GetAllFlags_ReturnsAllConfigurations(t *testing.T) {
	// Given - LocalStack DynamoDB
	ctx := context.Background()
	dynamoClient := testutil.NewLocalStackDynamoDB(t)

	testutil.SeedDynamoDB(t, dynamoClient, "flags", []map[string]interface{}{
		{
			"PK":                 "FLAGS",
			"SK":                 "feature.recovery-agent",
			"enabled":            true,
			"rolloutPercentage":  100,
			"tiers":              []string{"premium"},
		},
		{
			"PK":                 "FLAGS",
			"SK":                 "activity.time-journal",
			"enabled":            true,
			"rolloutPercentage":  25,
			"tiers":              []string{"*"},
		},
	})

	repo := repository.NewFlagRepository(dynamoClient)

	// When
	flags, err := repo.GetAll(ctx)

	// Then
	require.NoError(t, err)
	assert.Len(t, flags, 2)
	assert.Equal(t, "feature.recovery-agent", flags[0].Key)
	assert.Equal(t, "activity.time-journal", flags[1].Key)
}

func TestFlagRepository_Update_InvalidatesCacheTTL(t *testing.T) {
	// Given - Flag cached in Valkey
	ctx := context.Background()
	dynamoClient := testutil.NewLocalStackDynamoDB(t)
	valkeyClient := testutil.NewLocalStackValkey(t)

	repo := repository.NewFlagRepository(dynamoClient, valkeyClient)

	// Seed initial flag
	initialFlag := FlagConfig{
		Key:               "feature.recovery-agent",
		Enabled:           true,
		RolloutPercentage: 25,
	}
	repo.Update(ctx, initialFlag)

	// Cache populated
	time.Sleep(100 * time.Millisecond)
	cached, _ := repo.GetByKey(ctx, "feature.recovery-agent") // Hits cache
	assert.Equal(t, 25, cached.RolloutPercentage)

	// When - Update flag
	updatedFlag := FlagConfig{
		Key:               "feature.recovery-agent",
		Enabled:           true,
		RolloutPercentage: 50,
	}
	err := repo.Update(ctx, updatedFlag)

	// Then
	require.NoError(t, err)

	// Cache invalidated - fresh read returns new value
	fresh, _ := repo.GetByKey(ctx, "feature.recovery-agent")
	assert.Equal(t, 50, fresh.RolloutPercentage)
}
```

### 11.3 Flag Offline Behavior Tests

**Location:** `androidApp/app/src/test/java/com/regalrecovery/flags/OfflineFlagTest.kt` (Android) / `iosApp/RegalRecoveryTests/OfflineFlagTest.swift` (iOS)

```kotlin
class OfflineFlagTest {

    @Test
    fun `offline app uses last-cached flag state`() = runTest {
        // Given - Flags fetched and cached
        val flagStore = FlagStore()
        flagStore.cacheFlags(listOf(
            EvaluatedFlag(key = "activity.time-journal", enabled = true)
        ))

        // Simulate offline
        val flagManager = FlagManager(flagStore, isOnline = false)

        // When
        val enabled = flagManager.isEnabled("activity.time-journal")

        // Then
        assertTrue(enabled, "offline app uses cached flag state")
    }

    @Test
    fun `first launch offline defaults all flags to false`() = runTest {
        // Given - Never fetched flags (fresh install offline)
        val flagStore = FlagStore()
        val flagManager = FlagManager(flagStore, isOnline = false)

        // When
        val enabled = flagManager.isEnabled("activity.time-journal")

        // Then
        assertFalse(enabled, "fail closed: no cache means disabled")
    }

    @Test
    fun `core P0 features always enabled regardless of flags`() = runTest {
        // Given - Offline with no cached flags
        val flagStore = FlagStore()
        val flagManager = FlagManager(flagStore, isOnline = false)

        // When
        val onboardingEnabled = flagManager.isEnabled("feature.onboarding")
        val trackingEnabled = flagManager.isEnabled("feature.tracking")
        val emergencyToolsEnabled = flagManager.isEnabled("activity.urge-logging")

        // Then
        assertTrue(onboardingEnabled, "P0 feature hardcoded on")
        assertTrue(trackingEnabled, "P0 feature hardcoded on")
        assertTrue(emergencyToolsEnabled, "P0 feature hardcoded on")
    }
}
```

---

## 12. Recovery Agent Architecture Tests

### 12.1 Intent Classification (Unit Tests)

**Location:** `internal/agent/intent/classifier_test.go`

```go
func TestIntentClassifier_ConversationalMessage_ReturnsChat(t *testing.T) {
	// Given
	message := "I'm feeling tempted tonight. What should I do?"
	classifier := intent.NewClassifier()

	// When
	intent := classifier.Classify(message, conversationHistory)

	// Then
	assert.Equal(t, intent.IntentConversational, intent.Type)
	assert.False(t, intent.RequiresTool)
}

func TestIntentClassifier_ToolRequest_ReturnsToolWalkthrough(t *testing.T) {
	// Given
	message := "Can you help me with the FASTER Scale?"
	classifier := intent.NewClassifier()

	// When
	intent := classifier.Classify(message, conversationHistory)

	// Then
	assert.Equal(t, intent.IntentToolWalkthrough, intent.Type)
	assert.True(t, intent.RequiresTool)
	assert.Equal(t, "faster-scale", intent.ToolType)
}

func TestIntentClassifier_CrisisLanguage_ReturnsCrisisEscalation(t *testing.T) {
	// Given - Crisis keywords detected
	message := "I don't want to be here anymore. I'm thinking about ending it."
	classifier := intent.NewClassifier()

	// When
	intent := classifier.Classify(message, conversationHistory)

	// Then
	assert.Equal(t, intent.IntentCrisis, intent.Type)
	assert.True(t, intent.RequiresEscalation)
	assert.False(t, intent.Overridable, "crisis escalation non-overridable")
}
```

### 12.2 Tool Execution Flow (Integration Tests)

**Location:** `test/integration/agent/tool_execution_test.go`

```go
func TestAgentToolExecution_CollectConfirmSubmit_Flow(t *testing.T) {
	// Given - Agent conversation with tool walkthrough initiated
	ctx := context.Background()
	agentService := testutil.NewAgentService(t)
	conversationID := agentService.CreateConversation(ctx, "user_12345")

	// User asks for FASTER Scale help
	agentService.SendMessage(ctx, conversationID, "Help me with FASTER Scale")

	// When - Agent collects data conversationally
	response1 := agentService.SendMessage(ctx, conversationID, "I'm feeling forgetful")
	assert.Contains(t, response1.Text, "Are you feeling anxious?")

	response2 := agentService.SendMessage(ctx, conversationID, "Yes, I'm anxious")
	assert.Contains(t, response2.Text, "Are you speeding?")

	// ... (continue answering questions)

	// Agent shows summary and asks for confirmation
	summaryResponse := agentService.GetLastMessage(ctx, conversationID)
	assert.Contains(t, summaryResponse.Text, "Here's what I'll submit")
	assert.Contains(t, summaryResponse.Text, "Confirm?")

	// User confirms
	confirmResponse := agentService.SendMessage(ctx, conversationID, "Yes, submit it")

	// Then - Tool execution submitted to API
	assert.Contains(t, confirmResponse.Text, "FASTER Scale entry recorded")
	assert.NotEmpty(t, confirmResponse.ToolExecutions)
	assert.Equal(t, "faster-scale", confirmResponse.ToolExecutions[0].ToolType)
}

func TestAgentToolExecution_UserRevises_AllowsEdits(t *testing.T) {
	// Given - Agent shows summary before submission
	ctx := context.Background()
	agentService := testutil.NewAgentService(t)
	conversationID := agentService.CreateConversation(ctx, "user_12345")

	// Complete tool walkthrough to summary stage
	// ... (collect data)

	// When - User wants to revise
	revisionResponse := agentService.SendMessage(ctx, conversationID, "Wait, I want to change my answer for anxiety")

	// Then - Agent allows revision
	assert.Contains(t, revisionResponse.Text, "anxiety")
	assert.NotContains(t, revisionResponse.Text, "recorded") // Not yet submitted
}
```

### 12.3 LiteLLM + Bedrock Integration Tests

**Location:** `test/integration/agent/litellm_test.go`

```go
func TestLiteLLM_BedrockRouting_Production(t *testing.T) {
	// Given - Production LiteLLM config pointing to Bedrock
	ctx := context.Background()
	llmClient := litellm.NewClient(config.LiteLLMBedrockConfig)

	messages := []Message{
		{Role: "user", Content: "I'm struggling with urges tonight"},
	}

	// When
	response, err := llmClient.Complete(ctx, messages, "claude-3-opus")

	// Then
	require.NoError(t, err)
	assert.NotEmpty(t, response.Content)
	assert.Contains(t, response.Model, "anthropic.claude") // Bedrock model ID
	assert.Greater(t, response.TokensUsed.Input, 0)
	assert.Greater(t, response.TokensUsed.Output, 0)
}

func TestLiteLLM_OllamaRouting_Local(t *testing.T) {
	// Given - Local LiteLLM config pointing to Ollama
	ctx := context.Background()
	llmClient := litellm.NewClient(config.LiteLLMLocalConfig)

	messages := []Message{
		{Role: "user", Content: "Help me with FASTER Scale"},
	}

	// When
	response, err := llmClient.Complete(ctx, messages, "qwen")

	// Then
	require.NoError(t, err)
	assert.NotEmpty(t, response.Content)
	assert.Equal(t, "qwen", response.Model) // Ollama model
}

func TestLiteLLM_RateLimiting_ThrottlesExcessiveRequests(t *testing.T) {
	// Given - Rate limit: 10 messages per minute
	ctx := context.Background()
	llmClient := litellm.NewClient(config.LiteLLMWithRateLimit)

	// When - Send 15 messages rapidly
	for i := 0; i < 15; i++ {
		_, err := llmClient.Complete(ctx, []Message{{Role: "user", Content: "test"}}, "claude-3-opus")
		if i >= 10 {
			// Then - Rate limit kicks in after 10 requests
			assert.Error(t, err)
			assert.Contains(t, err.Error(), "rate limit")
		}
	}
}
```

### 12.4 LangGraph State Transitions (Unit Tests)

**Location:** `internal/agent/graph/state_test.go`

```go
func TestLangGraph_CrisisEscalation_NonOverridable(t *testing.T) {
	// Given - Conversation in progress
	graph := langgraph.NewRecoveryAgentGraph()
	state := langgraph.State{
		ConversationID: "conv_123",
		CurrentNode:    "AskQuestion",
		Context:        map[string]interface{}{"tool": "faster-scale"},
	}

	// When - Crisis language detected
	message := "I don't want to live anymore"
	nextState, err := graph.Transition(state, message)

	// Then
	require.NoError(t, err)
	assert.Equal(t, "CrisisEscalation", nextState.CurrentNode)
	assert.True(t, nextState.CrisisDetected)
	assert.False(t, nextState.Overridable, "crisis escalation cannot be overridden")
}

func TestLangGraph_ToolWalkthrough_MaintainsProgress(t *testing.T) {
	// Given - Mid-walkthrough state
	graph := langgraph.NewRecoveryAgentGraph()
	state := langgraph.State{
		ConversationID: "conv_123",
		CurrentNode:    "AskQuestion",
		Context: map[string]interface{}{
			"tool":            "faster-scale",
			"questionsAsked":  3,
			"questionsTotal":  6,
			"collectedData":   map[string]interface{}{"forgetting": false, "anxiety": true},
		},
	}

	// When - Continue answering
	message := "No, I'm not speeding"
	nextState, err := graph.Transition(state, message)

	// Then
	require.NoError(t, err)
	assert.Equal(t, 4, nextState.Context["questionsAsked"])
	assert.Equal(t, false, nextState.Context["collectedData"].(map[string]interface{})["speeding"])
}
```

### 12.5 Langfuse Observability (Integration Tests)

**Location:** `test/integration/agent/langfuse_test.go`

```go
func TestLangfuse_TracesConversation_WithMetadata(t *testing.T) {
	// Given - Agent conversation
	ctx := context.Background()
	agentService := testutil.NewAgentServiceWithLangfuse(t)
	conversationID := agentService.CreateConversation(ctx, "user_12345")

	// When - Exchange messages
	agentService.SendMessage(ctx, conversationID, "Help me with urges")
	agentService.SendMessage(ctx, conversationID, "I'm feeling stressed")

	// Then - Langfuse records traces (without user content)
	time.Sleep(2 * time.Second) // Allow async trace ingestion
	traces := testutil.GetLangfuseTraces(t, conversationID)

	assert.Len(t, traces, 2, "two messages traced")
	assert.NotEmpty(t, traces[0].Model, "model recorded")
	assert.Greater(t, traces[0].TokensUsed, 0, "token count recorded")
	assert.NotContains(t, traces[0].Content, "Help me with urges", "user content NOT logged")
	assert.Contains(t, traces[0].Metadata, "topic:urge") // Classification label only
}
```

---

## Related Documents

- [Strategic PRD](../01-strategic-prd.md)
- [Feature Specifications](../02-feature-specifications.md)
- [Technical Architecture](../03-technical-architecture.md)
- [API Data Model](../architecture/api-data-model.md)

---

**Document Status:** Draft
**Next Steps:**

1. Implement unit test structure for Go backend (`internal/domain/*/`)
2. Set up LocalStack + Docker Compose for integration tests
3. Create persona-based test fixtures (`pkg/fixtures/personas.go`)
4. Configure GitHub Actions CI workflow with quality gates
5. Write contract tests against OpenAPI spec
6. Establish Android and iOS native test suites
7. Train development team on TDD workflow
8. Implement feature flag evaluation unit tests with deterministic hashing
9. Add agent intent classification and LangGraph state transition tests
10. Set up Ollama in Docker for local agent development and CI testing
