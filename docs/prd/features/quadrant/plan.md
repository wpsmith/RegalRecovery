# Recovery Quadrant -- TDD Implementation Plan

| Field | Value |
|---|---|
| **Feature** | Recovery Quadrant |
| **Date** | 2026-04-23 |
| **Target Directory** | `ios/RegalRecovery/RegalRecovery/` (iOS), `api/` (Go backend) |
| **Estimated Phases** | 7 (sequential phases, tasks within each phase can be parallelized) |
| **Feature Flag** | `feature.quadrant` |
| **Test Naming Convention** | `TestQuadrant_AC{story}_{criterion}_{description}` |

---

## Table of Contents

1. [Overview](#1-overview)
2. [Phase 1: OpenAPI Spec + Contract Tests (RED)](#2-phase-1-openapi-spec--contract-tests-red)
3. [Phase 2: Domain Types + Service Logic with Unit Tests](#3-phase-2-domain-types--service-logic-with-unit-tests)
4. [Phase 3: MongoDB Repository + Integration Tests](#4-phase-3-mongodb-repository--integration-tests)
5. [Phase 4: Lambda Handler + API Tests](#5-phase-4-lambda-handler--api-tests)
6. [Phase 5: iOS Models + SwiftData](#6-phase-5-ios-models--swiftdata)
7. [Phase 6: iOS Views + ViewModel Tests](#7-phase-6-ios-views--viewmodel-tests)
8. [Phase 7: Integration + Feature Flag Wiring](#8-phase-7-integration--feature-flag-wiring)
9. [Test Case Summary](#9-test-case-summary)

---

## 1. Overview

### Development Philosophy

Every line of production code traces: **User Story -> Acceptance Criteria -> OpenAPI Spec -> Contract Tests (RED) -> Implementation (GREEN) -> Validate Against Spec -> Deploy.**

The Recovery Quadrant feature is developed using strict test-driven development:
1. Write failing tests first (RED)
2. Write the minimum code to pass (GREEN)
3. Refactor while keeping tests green (REFACTOR)

### Architecture Summary

```
OpenAPI Spec (source of truth)
  |
  v
Contract Tests (RED) --> Go Domain Types + Service --> MongoDB Repository --> Lambda Handler
  |
  v
iOS SwiftData Models --> iOS ViewModels --> iOS Views --> Navigation + Feature Flag
```

### File Organization (Planned)

```
# Backend (Go)
api/
  docs/specs/openapi/activities.yaml    # Modified: add quadrant endpoints
  internal/domain/quadrant/
    types.go                            # Domain types
    service.go                          # Business logic
    repository.go                       # Repository interface
  internal/repository/quadrant_repo.go  # MongoDB implementation
  cmd/lambda/activities/quadrant.go     # Lambda handler routes
  test/unit/quadrant_service_test.go    # Unit tests
  test/unit/quadrant_handler_test.go    # Handler unit tests
  test/integration/quadrant_test.go     # Integration tests

# iOS
ios/RegalRecovery/RegalRecovery/
  Models/QuadrantTypes.swift            # Supporting enums and structs
  Data/Models/RRModels.swift            # Modified: add RRQuadrantAssessment
  ViewModels/QuadrantAssessmentViewModel.swift
  ViewModels/QuadrantDashboardViewModel.swift
  ViewModels/QuadrantScoringService.swift
  Views/Activities/Quadrant/
    QuadrantPsychoeducationView.swift
    QuadrantAssessmentFlowView.swift
    QuadrantRatingView.swift
    QuadrantSummaryView.swift
    QuadrantRadarChartView.swift
    QuadrantTrendChartView.swift
    QuadrantDashboardView.swift
    QuadrantEntryPointView.swift
  Services/FeatureFlagStore.swift       # Modified: add feature.quadrant
  Tests/Unit/
    QuadrantScoringServiceTests.swift
    QuadrantAssessmentViewModelTests.swift
    QuadrantDashboardViewModelTests.swift
```

---

## 2. Phase 1: OpenAPI Spec + Contract Tests (RED)

### Goal

Define the API contract for quadrant endpoints in OpenAPI 3.1 YAML, then write contract tests that validate the spec. All tests fail initially because no implementation exists.

### 2.1 OpenAPI Spec Updates

Add quadrant endpoints to `docs/specs/openapi/activities.yaml`:

**Endpoints:**

| Method | Path | Description |
|---|---|---|
| POST | `/quadrant-assessments` | Create a new weekly assessment |
| GET | `/quadrant-assessments` | List assessments (paginated, filtered by date range) |
| GET | `/quadrant-assessments/{id}` | Get a specific assessment |
| PUT | `/quadrant-assessments/{id}` | Update an existing assessment |
| GET | `/quadrant-assessments/current-week` | Get the current week's assessment (convenience endpoint) |
| GET | `/quadrant-assessments/trends` | Get trend data (weekly scores over time) |

**Schema Definitions:**

```yaml
QuadrantAssessment:
  type: object
  required: [id, userId, weekStartDate, bodyScore, mindScore, heartScore, spiritScore, balanceScore, wellnessLevel]
  properties:
    id:
      type: string
      format: uuid
    userId:
      type: string
      format: uuid
    weekStartDate:
      type: string
      format: date
    isoWeekNumber:
      type: integer
    isoYear:
      type: integer
    bodyScore:
      type: integer
      minimum: 1
      maximum: 10
    mindScore:
      type: integer
      minimum: 1
      maximum: 10
    heartScore:
      type: integer
      minimum: 1
      maximum: 10
    spiritScore:
      type: integer
      minimum: 1
      maximum: 10
    balanceScore:
      type: number
      format: double
    wellnessLevel:
      type: string
      enum: [flourishing, growing, rebuilding, struggling]
    bodyIndicators:
      type: array
      items:
        type: string
    mindIndicators:
      type: array
      items:
        type: string
    heartIndicators:
      type: array
      items:
        type: string
    spiritIndicators:
      type: array
      items:
        type: string
    bodyReflection:
      type: string
      maxLength: 280
      nullable: true
    mindReflection:
      type: string
      maxLength: 280
      nullable: true
    heartReflection:
      type: string
      maxLength: 280
      nullable: true
    spiritReflection:
      type: string
      maxLength: 280
      nullable: true
    imbalancedQuadrants:
      type: array
      items:
        type: string
        enum: [body, mind, heart, spirit]
    createdAt:
      type: string
      format: date-time
    modifiedAt:
      type: string
      format: date-time

QuadrantTrend:
  type: object
  properties:
    weeks:
      type: array
      items:
        type: object
        properties:
          weekStartDate:
            type: string
            format: date
          bodyScore:
            type: integer
          mindScore:
            type: integer
          heartScore:
            type: integer
          spiritScore:
            type: integer
          balanceScore:
            type: number
          wellnessLevel:
            type: string
```

### 2.2 Contract Tests (RED)

**File:** `api/test/unit/quadrant_contract_test.go`

Write these tests first. All will fail (RED) because no implementation exists:

```go
// Contract tests validate API responses against the OpenAPI spec

func TestQuadrant_Contract_CreateAssessment_ReturnsValidSchema(t *testing.T)
// POST /quadrant-assessments -> 201 with QuadrantAssessment schema

func TestQuadrant_Contract_CreateAssessment_ScoresInRange(t *testing.T)
// Verify bodyScore, mindScore, heartScore, spiritScore all 1-10

func TestQuadrant_Contract_CreateAssessment_BalanceScoreComputed(t *testing.T)
// Verify balanceScore is populated and 0-100

func TestQuadrant_Contract_CreateAssessment_WellnessLevelValid(t *testing.T)
// Verify wellnessLevel is one of: flourishing, growing, rebuilding, struggling

func TestQuadrant_Contract_CreateAssessment_DuplicateWeekReturns409(t *testing.T)
// POST for same ISO week -> 409 Conflict

func TestQuadrant_Contract_GetAssessment_ReturnsValidSchema(t *testing.T)
// GET /quadrant-assessments/{id} -> 200 with QuadrantAssessment schema

func TestQuadrant_Contract_ListAssessments_ReturnsPaginatedResponse(t *testing.T)
// GET /quadrant-assessments -> 200 with data array + pagination meta

func TestQuadrant_Contract_GetCurrentWeek_Returns200OrEmpty(t *testing.T)
// GET /quadrant-assessments/current-week -> 200 with data or 204

func TestQuadrant_Contract_UpdateAssessment_ModifiesExisting(t *testing.T)
// PUT /quadrant-assessments/{id} -> 200 with updated scores

func TestQuadrant_Contract_GetTrends_ReturnsWeeklyData(t *testing.T)
// GET /quadrant-assessments/trends?weeks=8 -> 200 with QuadrantTrend

func TestQuadrant_Contract_ResponseEnvelope_FollowsRESTGuidelines(t *testing.T)
// Verify { "data": ..., "links": {...}, "meta": {...} } envelope
```

### 2.3 Spec Validation

```bash
cd api && make spec-validate
```

Validate the updated OpenAPI spec with Redocly before proceeding.

### Refactoring Opportunities
- Extract shared OpenAPI schema components (pagination, error envelope) if not already extracted
- Ensure the Quadrant schema references common types (UUID, date-time format)

---

## 3. Phase 2: Domain Types + Service Logic with Unit Tests

### Goal

Define Go domain types and implement the quadrant service with scoring, imbalance detection, and wellness level calculation. Write unit tests first (RED), then implement to pass (GREEN).

### 3.1 Tests to Write First (RED)

**File:** `api/test/unit/quadrant_service_test.go`

```go
// --- Balance Score Calculation ---

func TestQuadrant_AC4_1_BalanceScoreHighMeanLowVariance(t *testing.T)
// Input: body=8, mind=8, heart=8, spirit=8
// Expected: high balance score (>= 80), wellnessLevel = "flourishing"

func TestQuadrant_AC4_2_BalanceScoreHighMeanHighVariance(t *testing.T)
// Input: body=10, mind=10, heart=10, spirit=2
// Expected: moderate balance score (penalized for variance)

func TestQuadrant_AC4_3_BalanceScoreLowMean(t *testing.T)
// Input: body=2, mind=3, heart=2, spirit=3
// Expected: low balance score, wellnessLevel = "struggling"

func TestQuadrant_AC4_4_BalanceScoreAllTens(t *testing.T)
// Input: body=10, mind=10, heart=10, spirit=10
// Expected: balance score = 100, wellnessLevel = "flourishing"

func TestQuadrant_AC4_5_BalanceScoreAllOnes(t *testing.T)
// Input: body=1, mind=1, heart=1, spirit=1
// Expected: balance score near minimum, wellnessLevel = "struggling"

// --- Wellness Level ---

func TestQuadrant_AC4_6_WellnessLevelFlourishing(t *testing.T)
// Mean >= 8.0 AND stdev <= 1.5 -> "flourishing"

func TestQuadrant_AC4_7_WellnessLevelGrowing(t *testing.T)
// Mean >= 6.0, not meeting flourishing criteria -> "growing"

func TestQuadrant_AC4_8_WellnessLevelRebuilding(t *testing.T)
// Mean >= 4.0, < 6.0 -> "rebuilding"

func TestQuadrant_AC4_9_WellnessLevelStruggling(t *testing.T)
// Mean < 4.0 -> "struggling"

// --- Imbalance Detection ---

func TestQuadrant_AC4_10_ImbalanceDetected(t *testing.T)
// Input: body=3, mind=8, heart=7, spirit=8
// Expected: body is imbalanced (3+ below mean of others = 7.67)

func TestQuadrant_AC4_11_NoImbalanceWhenBalanced(t *testing.T)
// Input: body=7, mind=7, heart=7, spirit=7
// Expected: no quadrants flagged

func TestQuadrant_AC4_12_MultipleImbalances(t *testing.T)
// Input: body=2, mind=9, heart=2, spirit=9
// Expected: body AND heart both flagged

func TestQuadrant_AC4_13_ImbalanceThresholdExactly3(t *testing.T)
// Input: body=4, mind=7, heart=7, spirit=7
// Expected: body is exactly 3 below mean of others (7.0) -> flagged

func TestQuadrant_AC4_14_ImbalanceThresholdJustBelow3(t *testing.T)
// Input: body=5, mind=7, heart=7, spirit=8
// Expected: body is 2.33 below mean of others (7.33) -> NOT flagged

// --- Score Validation ---

func TestQuadrant_AC2_1_ScoresMustBe1to10(t *testing.T)
// Scores outside 1-10 range should return validation error

func TestQuadrant_AC2_2_ReflectionMaxLength280(t *testing.T)
// Reflection text > 280 chars should return validation error

// --- Duplicate Week Prevention ---

func TestQuadrant_AC2_3_DuplicateWeekDetected(t *testing.T)
// Creating two assessments for the same ISO week -> error

func TestQuadrant_AC2_4_DifferentWeeksAllowed(t *testing.T)
// Creating assessments for different weeks -> success

// --- Trend Calculation ---

func TestQuadrant_AC5_1_TrendReturns8Weeks(t *testing.T)
// Given 10 weeks of data, request 8 -> returns last 8 weeks

func TestQuadrant_AC5_2_TrendReturnsPartialData(t *testing.T)
// Given 3 weeks of data, request 8 -> returns 3 weeks

func TestQuadrant_AC5_3_TrendOrderedChronologically(t *testing.T)
// Trend data returned in ascending date order
```

### 3.2 Implementation (GREEN)

**File:** `api/internal/domain/quadrant/types.go`

```go
package quadrant

import (
    "math"
    "time"
)

type QuadrantType string

const (
    QuadrantBody   QuadrantType = "body"
    QuadrantMind   QuadrantType = "mind"
    QuadrantHeart  QuadrantType = "heart"
    QuadrantSpirit QuadrantType = "spirit"
)

type WellnessLevel string

const (
    WellnessFlourishing WellnessLevel = "flourishing"
    WellnessGrowing     WellnessLevel = "growing"
    WellnessRebuilding  WellnessLevel = "rebuilding"
    WellnessStruggling  WellnessLevel = "struggling"
)

type Assessment struct {
    ID                   string
    UserID               string
    WeekStartDate        time.Time
    ISOWeekNumber        int
    ISOYear              int
    BodyScore            int
    MindScore            int
    HeartScore           int
    SpiritScore          int
    BalanceScore         float64
    WellnessLevel        WellnessLevel
    BodyIndicators       []string
    MindIndicators       []string
    HeartIndicators      []string
    SpiritIndicators     []string
    BodyReflection       *string
    MindReflection       *string
    HeartReflection      *string
    SpiritReflection     *string
    ImbalancedQuadrants  []QuadrantType
    CreatedAt            time.Time
    ModifiedAt           time.Time
}
```

**File:** `api/internal/domain/quadrant/service.go`

```go
package quadrant

type Service struct {
    repo Repository
}

func (s *Service) CalculateBalanceScore(body, mind, heart, spirit int) float64 {
    // mean = (body + mind + heart + spirit) / 4.0
    // stdev = sqrt(sum of (score - mean)^2 / 4.0)
    // balanceScore = (mean / 10.0) * (1.0 - (stdev / 4.5)) * 100.0
    // Clamp to 0-100
}

func (s *Service) DetermineWellnessLevel(body, mind, heart, spirit int) WellnessLevel {
    // mean >= 8.0 AND stdev <= 1.5 -> flourishing
    // mean >= 6.0 -> growing
    // mean >= 4.0 -> rebuilding
    // mean < 4.0 -> struggling
}

func (s *Service) DetectImbalances(body, mind, heart, spirit int) []QuadrantType {
    // For each quadrant, compute mean of other three
    // If this quadrant's score is 3+ below that mean, flag it
}

func (s *Service) CreateAssessment(input CreateAssessmentInput) (*Assessment, error) {
    // Validate scores 1-10
    // Validate reflections <= 280 chars
    // Check for duplicate ISO week
    // Compute balance score, wellness level, imbalances
    // Persist via repository
}

func (s *Service) UpdateAssessment(id string, input UpdateAssessmentInput) (*Assessment, error) {
    // Recompute balance score, wellness level, imbalances
    // Update via repository
}

func (s *Service) GetTrend(userID string, weeks int) ([]TrendWeek, error) {
    // Fetch last N weeks of assessments
    // Return ordered by weekStartDate ascending
}
```

### 3.3 Refactoring Opportunities
- Extract the balance score formula into a pure function for testability
- Extract imbalance detection into a pure function
- Consider creating a `Scores` value object that encapsulates the four scores and provides computed properties

---

## 4. Phase 3: MongoDB Repository + Integration Tests

### Goal

Implement the MongoDB repository for quadrant assessments. Write integration tests that require a running MongoDB instance.

### 4.1 Tests to Write First (RED)

**File:** `api/test/integration/quadrant_test.go`

```go
// Requires: make local-up (MongoDB running)

func TestQuadrant_Repo_CreateAndRetrieve(t *testing.T)
// Create assessment -> retrieve by ID -> verify all fields match

func TestQuadrant_Repo_DuplicateWeekPrevention(t *testing.T)
// Create for week 17 -> create again for week 17 -> expect error

func TestQuadrant_Repo_ListByDateRange(t *testing.T)
// Create 5 assessments over 5 weeks -> list last 3 -> verify 3 returned

func TestQuadrant_Repo_UpdatePreservesCreatedAt(t *testing.T)
// Create -> update -> verify createdAt unchanged (FR2.7 immutable timestamps)

func TestQuadrant_Repo_GetCurrentWeekAssessment(t *testing.T)
// Create for current week -> getCurrentWeek -> returns it

func TestQuadrant_Repo_GetCurrentWeekEmpty(t *testing.T)
// No assessment this week -> getCurrentWeek -> returns nil

func TestQuadrant_Repo_TrendQuery(t *testing.T)
// Create 10 weekly assessments -> getTrend(8) -> returns 8 most recent

func TestQuadrant_Repo_UserIsolation(t *testing.T)
// Create assessments for user A and user B -> list for user A -> only A's returned
```

### 4.2 Implementation (GREEN)

**File:** `api/internal/repository/quadrant_repo.go`

```go
package repository

type QuadrantRepository struct {
    collection *mongo.Collection
}

// MongoDB collection: "quadrant_assessments"
// Indexes:
//   - { userId: 1, isoYear: 1, isoWeekNumber: 1 } unique (duplicate prevention)
//   - { userId: 1, weekStartDate: -1 } (list + trend queries)

func (r *QuadrantRepository) Create(ctx context.Context, assessment *quadrant.Assessment) error
func (r *QuadrantRepository) GetByID(ctx context.Context, id string) (*quadrant.Assessment, error)
func (r *QuadrantRepository) Update(ctx context.Context, assessment *quadrant.Assessment) error
func (r *QuadrantRepository) GetCurrentWeek(ctx context.Context, userID string) (*quadrant.Assessment, error)
func (r *QuadrantRepository) List(ctx context.Context, userID string, opts ListOptions) ([]*quadrant.Assessment, error)
func (r *QuadrantRepository) GetTrend(ctx context.Context, userID string, weeks int) ([]*quadrant.Assessment, error)
```

**MongoDB Schema:**

```javascript
// Collection: quadrant_assessments
{
    _id: ObjectId,
    userId: UUID,
    weekStartDate: ISODate,
    isoWeekNumber: 17,
    isoYear: 2026,
    bodyScore: 7,
    mindScore: 5,
    heartScore: 8,
    spiritScore: 6,
    balanceScore: 72.5,
    wellnessLevel: "growing",
    bodyIndicators: ["Exercised 3+ times", "Slept 7+ hours"],
    mindIndicators: ["Engaged in learning"],
    heartIndicators: ["Talked honestly with sponsor"],
    spiritIndicators: ["Prayed daily", "Read scripture"],
    bodyReflection: "Good week for exercise, struggled with sleep on Wednesday",
    mindReflection: null,
    heartReflection: "Connected with wife over dinner twice",
    spiritReflection: null,
    imbalancedQuadrants: ["mind"],
    createdAt: ISODate,
    modifiedAt: ISODate,
    tenantId: "default"
}
```

### 4.3 Seed Script

**File:** `api/scripts/seed-quadrant.js`

Add seed data for the Alex persona with 8 weeks of quadrant assessments showing a realistic recovery pattern (initial low scores, gradual improvement with some setbacks).

### 4.4 Refactoring Opportunities
- Ensure the compound unique index on (userId, isoYear, isoWeekNumber) handles the year boundary correctly
- Add TTL index if data retention policy requires it

---

## 5. Phase 4: Lambda Handler + API Tests

### Goal

Wire up HTTP handlers that expose the quadrant service through the API. Write handler-level tests.

### 5.1 Tests to Write First (RED)

**File:** `api/test/unit/quadrant_handler_test.go`

```go
func TestQuadrant_Handler_CreateAssessment_201(t *testing.T)
// POST valid assessment -> 201 Created with response body

func TestQuadrant_Handler_CreateAssessment_400_InvalidScores(t *testing.T)
// POST with bodyScore=15 -> 400 Bad Request with error

func TestQuadrant_Handler_CreateAssessment_400_MissingRequired(t *testing.T)
// POST without bodyScore -> 400

func TestQuadrant_Handler_CreateAssessment_409_DuplicateWeek(t *testing.T)
// POST duplicate week -> 409 Conflict

func TestQuadrant_Handler_GetAssessment_200(t *testing.T)
// GET existing assessment -> 200 with full schema

func TestQuadrant_Handler_GetAssessment_404(t *testing.T)
// GET non-existent ID -> 404

func TestQuadrant_Handler_ListAssessments_200(t *testing.T)
// GET list -> 200 with data array and meta

func TestQuadrant_Handler_ListAssessments_Pagination(t *testing.T)
// GET with cursor and limit -> paginated response

func TestQuadrant_Handler_UpdateAssessment_200(t *testing.T)
// PUT with updated scores -> 200 with recomputed balance

func TestQuadrant_Handler_GetCurrentWeek_200(t *testing.T)
// GET current week -> 200 or 204

func TestQuadrant_Handler_GetTrends_200(t *testing.T)
// GET trends?weeks=8 -> 200 with trend data

func TestQuadrant_Handler_ResponseFormat_RESTGuidelines(t *testing.T)
// Verify camelCase properties, envelope, error format
```

### 5.2 Implementation (GREEN)

**File:** `api/cmd/lambda/activities/quadrant.go`

```go
// Mount routes:
// POST   /quadrant-assessments
// GET    /quadrant-assessments
// GET    /quadrant-assessments/current-week
// GET    /quadrant-assessments/trends
// GET    /quadrant-assessments/{id}
// PUT    /quadrant-assessments/{id}
```

**File:** `api/cmd/local/main.go` (modify)

Add quadrant routes to the local development server alongside existing activity routes.

### 5.3 Refactoring Opportunities
- Extract common handler patterns (envelope wrapping, error formatting, pagination) if not already shared
- Ensure correlation ID is passed through to service layer

---

## 6. Phase 5: iOS Models + SwiftData

### Goal

Create the iOS data model and supporting types. Write unit tests for scoring, imbalance detection, and data model behavior.

### 6.1 Tests to Write First (RED)

**File:** `ios/RegalRecovery/RegalRecovery/Tests/Unit/QuadrantScoringServiceTests.swift`

```swift
// --- Balance Score ---

func testQuadrant_AC4_1_BalanceScoreHighMeanLowVariance() {
    // Input: 8, 8, 8, 8
    // Expected: high balance score (>= 80)
}

func testQuadrant_AC4_2_BalanceScorePenalizesVariance() {
    // Input: 10, 10, 10, 2
    // Expected: lower than 8, 8, 8, 8 despite same mean
}

func testQuadrant_AC4_4_PerfectScoreIs100() {
    // Input: 10, 10, 10, 10
    // Expected: 100.0
}

func testQuadrant_AC4_5_AllOnesIsMinimum() {
    // Input: 1, 1, 1, 1
    // Expected: near minimum (but not zero due to mean = 1)
}

// --- Wellness Level ---

func testQuadrant_AC4_6_FlourishingRequiresHighMeanAndLowVariance() {
    // Mean >= 8.0, stdev <= 1.5 -> .flourishing
}

func testQuadrant_AC4_7_HighMeanHighVarianceIsNotFlourishing() {
    // Mean >= 8.0 but stdev > 1.5 -> .growing (not flourishing)
}

func testQuadrant_AC4_8_GrowingLevel() {
    // Mean 6.0-7.9 -> .growing
}

func testQuadrant_AC4_9_RebuildingLevel() {
    // Mean 4.0-5.9 -> .rebuilding
}

func testQuadrant_AC4_10_StrugglingLevel() {
    // Mean < 4.0 -> .struggling
}

// --- Imbalance Detection ---

func testQuadrant_AC4_11_DetectsImbalancedQuadrant() {
    // body=3, mind=8, heart=7, spirit=8
    // body is 4.67 below others' mean -> flagged
}

func testQuadrant_AC4_12_NoImbalanceWhenBalanced() {
    // 7, 7, 7, 7 -> no flags
}

func testQuadrant_AC4_13_MultipleImbalances() {
    // body=2, mind=9, heart=2, spirit=9
    // body AND heart flagged
}

func testQuadrant_AC4_14_ThresholdExactly3() {
    // body=4, mind=7, heart=7, spirit=7
    // body is exactly 3 below others (7.0) -> flagged
}

func testQuadrant_AC4_15_ThresholdJustBelow3() {
    // body=5, mind=7, heart=7, spirit=8
    // body is 2.33 below others -> NOT flagged
}

// --- Score Validation ---

func testQuadrant_AC2_1_ScoreRange1to10() {
    // Verify 0 is invalid, 11 is invalid, 1 and 10 are valid
}

// --- Week Number Calculation ---

func testQuadrant_AC2_3_WeekStartDateIsMonday() {
    // Given a Wednesday date, weekStartDate should be the preceding Monday
}

func testQuadrant_AC2_4_ISOWeekNumberCalculation() {
    // Verify ISO week number matches expected for known dates
}
```

### 6.2 Implementation (GREEN)

**File:** `ios/RegalRecovery/RegalRecovery/Models/QuadrantTypes.swift`

Create `QuadrantType`, `WellnessLevel` enums with all computed properties (displayName, color, icon, scripture, indicators, recommendations).

**File:** `ios/RegalRecovery/RegalRecovery/ViewModels/QuadrantScoringService.swift`

```swift
struct QuadrantScoringService {
    static func balanceScore(body: Int, mind: Int, heart: Int, spirit: Int) -> Double
    static func wellnessLevel(body: Int, mind: Int, heart: Int, spirit: Int) -> WellnessLevel
    static func detectImbalances(body: Int, mind: Int, heart: Int, spirit: Int) -> [QuadrantType]
    static func weekStartDate(for date: Date) -> Date
    static func isoWeekComponents(for date: Date) -> (weekNumber: Int, year: Int)
}
```

**File:** `ios/RegalRecovery/RegalRecovery/Data/Models/RRModels.swift` (modify)

Add `RRQuadrantAssessment` `@Model` class. Register in `RRModelConfiguration.allModels`.

### 6.3 Refactoring Opportunities
- Extract balance score formula into a standalone function that both Go and Swift tests validate against the same expected values
- Create test fixtures with shared expected values documented in both test files

---

## 7. Phase 6: iOS Views + ViewModel Tests

### Goal

Build the iOS user interface: assessment flow, radar chart, trend chart, dashboard. Write ViewModel unit tests first.

### 7.1 Tests to Write First (RED)

**File:** `ios/RegalRecovery/RegalRecovery/Tests/Unit/QuadrantAssessmentViewModelTests.swift`

```swift
// --- Assessment Flow ---

func testQuadrant_AC2_1_InitialStepIsBody() {
    // ViewModel starts at .body quadrant
}

func testQuadrant_AC2_2_NextAdvancesToMind() {
    // From .body, calling next() moves to .mind
}

func testQuadrant_AC2_3_CanNavigateAllFour() {
    // body -> mind -> heart -> spirit -> summary
}

func testQuadrant_AC2_4_ScoreDefaultsTo5() {
    // Each quadrant's score defaults to 5
}

func testQuadrant_AC2_5_ScoreUpdatesPersist() {
    // Setting body to 8, advancing, coming back -> body still 8
}

func testQuadrant_AC2_6_IndicatorsStartUnchecked() {
    // All behavioral indicators start unchecked
}

func testQuadrant_AC2_7_ReflectionIsOptional() {
    // Can save without entering any reflections
}

func testQuadrant_AC2_8_ReflectionMaxLength280() {
    // Text > 280 characters is truncated or blocked
}

// --- Existing Assessment Loading ---

func testQuadrant_AC2_9_LoadExistingAssessmentForEditing() {
    // If assessment exists for this week, load it
}

func testQuadrant_AC2_10_NewAssessmentWhenNoneExists() {
    // If no assessment for this week, start fresh
}

// --- Save ---

func testQuadrant_AC2_11_SaveComputesBalanceScoreAndWellnessLevel() {
    // After save, balanceScore and wellnessLevel are populated
}

func testQuadrant_AC2_12_SaveComputesImbalances() {
    // After save with imbalanced scores, imbalancedQuadrants is populated
}
```

**File:** `ios/RegalRecovery/RegalRecovery/Tests/Unit/QuadrantDashboardViewModelTests.swift`

```swift
// --- Dashboard ---

func testQuadrant_AC3_1_RadarChartDataHasFourPoints() {
    // Radar chart data always has exactly 4 data points
}

func testQuadrant_AC5_1_TrendDataOrderedChronologically() {
    // Trend data sorted by weekStartDate ascending
}

func testQuadrant_AC5_2_TrendShowsMaximum8Weeks() {
    // With 12 weeks of data, trend shows most recent 8
}

func testQuadrant_AC5_3_TrendHandlesPartialData() {
    // With 3 weeks of data, trend shows all 3
}

func testQuadrant_AC6_1_RecommendationsForLowScore() {
    // Spirit = 4 -> recommends Prayer and Affirmations
}

func testQuadrant_AC6_2_NoRecommendationsWhenAllHigh() {
    // All scores >= 7 -> no recommendations
}

func testQuadrant_AC6_3_ImbalanceRecommendationHasUrgentFraming() {
    // Imbalanced quadrant -> recommendation has "significantly below" text
}

func testQuadrant_AC7_1_HasAssessedThisWeek() {
    // Returns true when this week's assessment exists
}

func testQuadrant_AC7_2_HasNotAssessedThisWeek() {
    // Returns false when no assessment for this week
}
```

### 7.2 Implementation (GREEN)

**File:** `ios/RegalRecovery/RegalRecovery/ViewModels/QuadrantAssessmentViewModel.swift`

```swift
@Observable
class QuadrantAssessmentViewModel {
    var currentQuadrant: QuadrantType = .body
    var scores: [QuadrantType: Int] = [.body: 5, .mind: 5, .heart: 5, .spirit: 5]
    var indicators: [QuadrantType: Set<String>] = [:]
    var reflections: [QuadrantType: String] = [:]
    var isEditingExisting: Bool = false
    var existingAssessmentId: UUID?

    // Navigation
    func next() { /* advance to next quadrant or summary */ }
    func previous() { /* go back */ }
    var isAtSummary: Bool { /* after spirit */ }
    var progress: Double { /* 0.0 to 1.0 */ }

    // Data
    func load(context: ModelContext, userId: UUID) { /* load existing or start fresh */ }
    func save(context: ModelContext, userId: UUID) { /* persist with computed scores */ }
}
```

**File:** `ios/RegalRecovery/RegalRecovery/ViewModels/QuadrantDashboardViewModel.swift`

```swift
@Observable
class QuadrantDashboardViewModel {
    var currentAssessment: RRQuadrantAssessment?
    var trendData: [(weekStart: Date, body: Int, mind: Int, heart: Int, spirit: Int, balance: Double)] = []
    var recommendations: [(quadrant: QuadrantType, activities: [(key: String, label: String)])] = []
    var hasAssessedThisWeek: Bool = false

    func load(context: ModelContext, userId: UUID) { /* load current + trend + recommendations */ }
}
```

### 7.3 Views (GREEN)

| View File | Description |
|---|---|
| `QuadrantPsychoeducationView.swift` | Mark 12:30 intro, quadrant explanation, "Begin Assessment" button |
| `QuadrantAssessmentFlowView.swift` | Flow container: switches between QuadrantRatingView per quadrant and summary |
| `QuadrantRatingView.swift` | Single quadrant rating: slider (1-10), behavioral indicators, reflection field, scripture verse |
| `QuadrantSummaryView.swift` | Summary after all 4 rated: radar chart, balance score, wellness level, imbalance alerts, recommendations, save button |
| `QuadrantRadarChartView.swift` | Radar/spider chart with four axes, filled polygon, optional previous-week overlay |
| `QuadrantTrendChartView.swift` | 8-week trend chart with four colored lines (one per quadrant) using Swift Charts |
| `QuadrantDashboardView.swift` | Main feature hub: radar chart, weekly summary card, trend chart, recommendation cards |
| `QuadrantEntryPointView.swift` | Routes between psychoeducation (first use), assessment (new/edit), and dashboard (view results) |

### 7.4 Refactoring Opportunities
- Extract the radar chart into a reusable component (could be used by other features)
- Create a shared `LikertSlider` component if one does not already exist
- Consider using a protocol for the quadrant data to allow preview mocking

---

## 8. Phase 7: Integration + Feature Flag Wiring

### Goal

Wire the Quadrant feature into the app's navigation, Today view, feature flags, and existing systems.

### 8.1 Tests to Write First (RED)

```swift
// --- Feature Flag ---

func testQuadrant_FF_1_FeatureHiddenWhenFlagDisabled() {
    // feature.quadrant = false -> tile not visible in Recovery Work

func testQuadrant_FF_2_FeatureVisibleWhenFlagEnabled() {
    // feature.quadrant = true -> tile visible

// --- Today View ---

func testQuadrant_AC7_3_TodayViewShowsCompletedAssessment() {
    // Assessment saved -> Today view shows "Recovery Quadrant: Growing" card

func testQuadrant_AC7_4_TodayViewShowsPromptWhenNotAssessed() {
    // No assessment this week, Wednesday+ -> prompt card shown

func testQuadrant_AC7_5_TodayViewHiddenBeforeFirstUse() {
    // Never used Quadrant -> no card in Today view
```

### 8.2 Implementation (GREEN)

**Files to modify:**

| File | Change |
|---|---|
| `Services/FeatureFlagStore.swift` | Add `"feature.quadrant": false` to `flagDefaults` (disabled by default for gradual rollout) |
| `Data/Models/RRModels.swift` | Add `RRQuadrantAssessment.self` to `RRModelConfiguration.allModels` |
| `Views/Shared/ActivityDestinationView.swift` | Add `case "quadrant": QuadrantEntryPointView()` |
| `ViewModels/RecoveryWorkViewModel.swift` | Add Quadrant tile to `allTiles` with `featureFlagKey: "feature.quadrant"`, `activityTypeKey: "quadrant"` |
| `ViewModels/TodayViewModel.swift` | Add Quadrant to activity log and completion check |
| `Models/Types.swift` | Add `.quadrant` to `ActivityType` enum if assessment should appear in the activity feed |

**Recovery Work Tile:**

```swift
WorkTileItem(
    id: "feature.quadrant",
    title: String(localized: "Recovery Quadrant"),
    icon: "chart.pie",
    iconColor: .purple,
    category: .activities,
    featureFlagKey: "feature.quadrant",
    implemented: true,
    activityTypeKey: "quadrant"
)
```

**Today View Activity Log:**

```swift
// Quadrant Assessment
let quadrantDesc = FetchDescriptor<RRQuadrantAssessment>(
    predicate: #Predicate { $0.weekStartDate >= thisWeekStart && $0.weekStartDate < nextWeekStart },
    sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
)
if let results = try? context.fetch(quadrantDesc) {
    for q in results {
        all.append((q.createdAt, RecentActivity(
            title: "Recovery Quadrant",
            detail: q.wellnessLevel.capitalized,
            time: fmt.localizedString(for: q.createdAt, relativeTo: now),
            icon: "chart.pie",
            iconColor: .purple
        )))
    }
}
```

### 8.3 Notification Wiring

Add weekly reminder to `PlanNotificationScheduler`:
- Default: Sunday 7:00 PM
- Content: "How are your Body, Mind, Heart, and Spirit this week? Take 3 minutes for your Recovery Quadrant."
- Suppress if this week's assessment already exists

### 8.4 Refactoring Opportunities
- Consolidate activity type registration if a pattern emerges for feature registration
- Consider creating a `FeatureRegistration` protocol that each feature implements to provide its tile, flag, and Today view integration

---

## 9. Test Case Summary

### Total Test Cases by Phase

| Phase | Component | Test Count | Test Type |
|---|---|---|---|
| 1 | Contract tests (OpenAPI) | 11 | Contract |
| 2 | Domain service (Go) | 19 | Unit |
| 3 | MongoDB repository | 8 | Integration |
| 4 | Lambda handler | 12 | Unit |
| 5 | iOS scoring service | 16 | Unit |
| 6 | iOS ViewModels | 20 | Unit |
| 7 | Feature flag + integration | 5 | Integration |
| **Total** | | **91** | |

### Critical Path Tests (100% Coverage Required)

These tests cover critical recovery paths where bugs could cause harm:

| Test | Why Critical |
|---|---|
| Balance score calculation (all variants) | Incorrect scoring could give false sense of security or unnecessary alarm |
| Imbalance detection threshold | Missing an imbalance means missing a warning; false positive causes unnecessary anxiety |
| Wellness level thresholds | Incorrect level assignment affects recommendations and user psychology |
| Duplicate week prevention | Data integrity -- double-counting distorts trends |
| Score validation (1-10 range) | Boundary violations corrupt scoring formulas |

### Test Naming Convention

All tests follow the pattern: `TestQuadrant_AC{story}_{criterion}_{description}`

Examples:
- `TestQuadrant_AC4_1_BalanceScoreHighMeanLowVariance` (Go)
- `testQuadrant_AC4_1_BalanceScoreHighMeanLowVariance()` (Swift)
- `TestQuadrant_Contract_CreateAssessment_ReturnsValidSchema` (Contract)
- `TestQuadrant_Repo_CreateAndRetrieve` (Integration)
- `TestQuadrant_Handler_CreateAssessment_201` (Handler)

### Coverage Targets

| Component | Target | Rationale |
|---|---|---|
| Scoring service (Go + Swift) | 100% | Critical path: balance, wellness, imbalance |
| Domain service | >= 90% | Business logic |
| Repository | >= 80% | Data access |
| Handler | >= 80% | API layer |
| ViewModel | >= 80% | UI logic |
| Views | >= 60% | UI rendering (snapshot tests if practical) |

---

## Appendix A: Phase Dependencies

```
Phase 1: OpenAPI Spec + Contract Tests
  |
  v
Phase 2: Domain Types + Service (Go) ------> Phase 3: MongoDB Repository
  |                                              |
  v                                              v
Phase 4: Lambda Handler <--------------------- Phase 3
  |
  v
Phase 5: iOS Models + SwiftData (can start parallel with Phase 3-4)
  |
  v
Phase 6: iOS Views + ViewModels
  |
  v
Phase 7: Integration + Feature Flags
```

**Parallelization opportunities:**
- Phases 1-4 (backend) and Phase 5 (iOS models) can proceed in parallel once the OpenAPI spec (Phase 1) is agreed upon
- Phase 5 iOS models can start as soon as the data schema is defined (Phase 1-2 overlap)
- Phase 6 and the later parts of Phase 4 can proceed in parallel

---

## Appendix B: Shared Test Fixtures

The following expected values should be validated by both Go and Swift test suites to ensure cross-platform consistency:

| Input (Body, Mind, Heart, Spirit) | Expected Balance Score | Expected Wellness Level | Expected Imbalances |
|---|---|---|---|
| 10, 10, 10, 10 | 100.0 | flourishing | [] |
| 8, 8, 8, 8 | ~88.9 | flourishing | [] |
| 7, 7, 7, 7 | ~77.8 | growing | [] |
| 5, 5, 5, 5 | ~55.6 | rebuilding | [] |
| 3, 3, 3, 3 | ~33.3 | struggling | [] |
| 1, 1, 1, 1 | ~11.1 | struggling | [] |
| 3, 8, 7, 8 | varies | growing | [body] |
| 2, 9, 2, 9 | varies | rebuilding | [body, heart] |
| 8, 8, 9, 3 | varies | growing | [spirit] |
| 10, 10, 10, 2 | varies | growing | [spirit] |
| 8, 9, 8, 9 | varies | flourishing | [] |
| 6, 6, 6, 6 | ~66.7 | growing | [] |

Note: "varies" values should be computed from the formula and hard-coded in both test suites for cross-platform verification.
