# Stress-Control Matrix -- TDD Implementation Plan

| Field | Value |
|---|---|
| **Feature** | Stress-Control Matrix |
| **Date** | 2026-04-23 |
| **Methodology** | Test-Driven Development (RED -> GREEN -> REFACTOR) |
| **Target Directory** | `ios/RegalRecovery/RegalRecovery/` (iOS) and `api/` (Backend) |
| **Feature Flag** | `activity.stress-matrix` |
| **Estimated Phases** | 9 (sequential phases, tasks within each phase may parallelize) |

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Phase Summary](#2-phase-summary)
3. [Phase 1: OpenAPI Spec + Contract Tests (RED)](#3-phase-1-openapi-spec--contract-tests-red)
4. [Phase 2: Domain Types + Service Logic with Unit Tests](#4-phase-2-domain-types--service-logic-with-unit-tests)
5. [Phase 3: MongoDB Repository + Integration Tests](#5-phase-3-mongodb-repository--integration-tests)
6. [Phase 4: Lambda Handler + API Tests](#6-phase-4-lambda-handler--api-tests)
7. [Phase 5: iOS Models + SwiftData](#7-phase-5-ios-models--swiftdata)
8. [Phase 6: iOS Views + ViewModel Tests (Matrix UI)](#8-phase-6-ios-views--viewmodel-tests-matrix-ui)
9. [Phase 7: Stressor Library + Categorization Logic](#9-phase-7-stressor-library--categorization-logic)
10. [Phase 8: Integration with FASTER Scale, Journaling, Emergency Layer](#10-phase-8-integration-with-faster-scale-journaling-emergency-layer)
11. [Phase 9: Feature Flag Wiring](#11-phase-9-feature-flag-wiring)
12. [Test Naming Convention](#12-test-naming-convention)
13. [Verification Checklist](#13-verification-checklist)

---

## 1. Architecture Overview

### Backend (Go)

```
api/
  cmd/lambda/activities/       # Lambda entrypoint (activities domain covers matrix)
  cmd/local/                   # Local HTTP server
  internal/
    domain/activities/
      stress_matrix_types.go   # Domain types: StressMatrixSession, Stressor, Quadrant
      stress_matrix_service.go # Business logic: create, update, recategorize, trends
      stress_matrix_repository.go # Repository interface
    repository/
      stress_matrix_mongo.go   # MongoDB implementation
  test/unit/
    stress_matrix_service_test.go
    stress_matrix_handler_test.go
  test/integration/
    stress_matrix_repository_test.go
```

### iOS (Swift)

```
ios/RegalRecovery/RegalRecovery/
  Data/Models/RRModels.swift           # Add RRStressMatrixSession @Model
  Models/StressMatrixTypes.swift       # Codable types, quadrant enum
  Models/StressMatrixLibrary.swift     # Pre-populated stressor library
  Models/StressMatrixContent.swift     # Quadrant content (guidance, scripture, prayers)
  ViewModels/StressMatrixViewModel.swift
  ViewModels/StressMatrixHistoryViewModel.swift
  Views/Activities/StressMatrix/
    StressMatrixView.swift             # Main 2x2 grid + stressor entry
    StressMatrixQuadrantDetailView.swift
    StressMatrixLibrarySheet.swift
    StressMatrixHistoryView.swift
    StressMatrixSessionDetailView.swift
    StressMatrixTrendView.swift
    StressMatrixDistributionChart.swift
  Services/FeatureFlagStore.swift      # Add flag seed
```

### API Spec

```
docs/specs/openapi/activities.yaml    # Add stress-matrix paths and schemas
```

---

## 2. Phase Summary

| Phase | Focus | Test Type | Key Deliverables |
|---|---|---|---|
| 1 | OpenAPI Spec + Contract Tests | Contract (RED) | OpenAPI paths, schemas, contract test stubs |
| 2 | Domain Types + Service Logic | Unit (RED -> GREEN) | Go domain types, service, unit tests |
| 3 | MongoDB Repository | Integration (RED -> GREEN) | Repository implementation, integration tests |
| 4 | Lambda Handler + API | API (RED -> GREEN) | HTTP handler, route registration, API tests |
| 5 | iOS Models + SwiftData | Unit (RED -> GREEN) | SwiftData models, Codable types |
| 6 | iOS Views + ViewModel | ViewModel Unit + UI (RED -> GREEN) | Matrix UI, entry flow, quadrant detail |
| 7 | Stressor Library + Categorization | Unit (RED -> GREEN) | Library data, search, categorization |
| 8 | Feature Integration | Integration (RED -> GREEN) | FASTER link, journaling, Today view |
| 9 | Feature Flag Wiring | Integration (GREEN) | Flag registration, gated visibility |

---

## 3. Phase 1: OpenAPI Spec + Contract Tests (RED)

### 3.1 OpenAPI Spec Additions

Add the following paths and schemas to `docs/specs/openapi/activities.yaml`:

**Paths:**

```yaml
/activities/stress-matrix:
  post:
    summary: Create a new stress matrix session
    tags: [Stress Matrix]
    operationId: createStressMatrixSession
    requestBody:
      required: true
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/CreateStressMatrixSessionRequest'
    responses:
      '201':
        description: Session created
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/StressMatrixSessionResponse'
  get:
    summary: List stress matrix sessions
    tags: [Stress Matrix]
    operationId: listStressMatrixSessions
    parameters:
      - name: cursor
        in: query
        schema: { type: string }
      - name: limit
        in: query
        schema: { type: integer, default: 20, maximum: 100 }
    responses:
      '200':
        description: Session list
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/StressMatrixSessionListResponse'

/activities/stress-matrix/{sessionId}:
  get:
    summary: Get a stress matrix session by ID
    tags: [Stress Matrix]
    operationId: getStressMatrixSession
  put:
    summary: Update a stress matrix session (add/remove/move stressors)
    tags: [Stress Matrix]
    operationId: updateStressMatrixSession
  delete:
    summary: Delete a stress matrix session
    tags: [Stress Matrix]
    operationId: deleteStressMatrixSession

/activities/stress-matrix/{sessionId}/complete:
  post:
    summary: Mark a session as complete
    tags: [Stress Matrix]
    operationId: completeStressMatrixSession

/activities/stress-matrix/trends:
  get:
    summary: Get quadrant distribution trends
    tags: [Stress Matrix]
    operationId: getStressMatrixTrends
    parameters:
      - name: weeks
        in: query
        schema: { type: integer, default: 8, maximum: 52 }
```

**Schemas:**

```yaml
CreateStressMatrixSessionRequest:
  type: object
  properties:
    stressors:
      type: array
      items:
        $ref: '#/components/schemas/StressMatrixStressorInput'

StressMatrixStressorInput:
  type: object
  required: [text, quadrant]
  properties:
    text:
      type: string
      maxLength: 200
    quadrant:
      $ref: '#/components/schemas/StressQuadrant'
    isFromLibrary:
      type: boolean
      default: false
    libraryCategory:
      type: string

StressQuadrant:
  type: string
  enum: [focusHere, letGo, minimize, ignore]

StressMatrixSessionResponse:
  type: object
  properties:
    data:
      $ref: '#/components/schemas/StressMatrixSession'

StressMatrixSession:
  type: object
  properties:
    id:
      type: string
      format: uuid
    userId:
      type: string
      format: uuid
    date:
      type: string
      format: date
    completedAt:
      type: string
      format: date-time
      nullable: true
    stressors:
      type: array
      items:
        $ref: '#/components/schemas/StressMatrixStressor'
    quadrantDistribution:
      $ref: '#/components/schemas/QuadrantDistribution'
    createdAt:
      type: string
      format: date-time
    modifiedAt:
      type: string
      format: date-time

StressMatrixStressor:
  type: object
  properties:
    id:
      type: string
      format: uuid
    text:
      type: string
    quadrant:
      $ref: '#/components/schemas/StressQuadrant'
    isFromLibrary:
      type: boolean
    libraryCategory:
      type: string
      nullable: true
    isPrayedOver:
      type: boolean
    addedAt:
      type: string
      format: date-time
    recategorizations:
      type: array
      items:
        $ref: '#/components/schemas/StressorRecategorization'

StressorRecategorization:
  type: object
  properties:
    fromQuadrant:
      $ref: '#/components/schemas/StressQuadrant'
    toQuadrant:
      $ref: '#/components/schemas/StressQuadrant'
    timestamp:
      type: string
      format: date-time

QuadrantDistribution:
  type: object
  properties:
    focusHere:
      type: integer
    letGo:
      type: integer
    minimize:
      type: integer
    ignore:
      type: integer
```

### 3.2 Contract Tests (RED)

Create `api/test/unit/stress_matrix_contract_test.go`:

```go
// All tests RED -- no implementation exists yet.

func TestStressMatrix_Contract_CreateSessionRequestSchema(t *testing.T) {
    // Validate that CreateStressMatrixSessionRequest matches OpenAPI schema
    // - stressors array with text (max 200 chars) and quadrant (enum)
}

func TestStressMatrix_Contract_SessionResponseSchema(t *testing.T) {
    // Validate StressMatrixSessionResponse envelope: { data: ... }
    // - id, userId, date, completedAt (nullable), stressors array
    // - quadrantDistribution object with 4 integer fields
}

func TestStressMatrix_Contract_QuadrantEnumValues(t *testing.T) {
    // Validate StressQuadrant enum: exactly [focusHere, letGo, minimize, ignore]
}

func TestStressMatrix_Contract_StressorMaxLength(t *testing.T) {
    // Validate stressor text max 200 characters per schema
}

func TestStressMatrix_Contract_RecategorizationSchema(t *testing.T) {
    // Validate recategorization object: fromQuadrant, toQuadrant, timestamp
}

func TestStressMatrix_Contract_TrendResponseSchema(t *testing.T) {
    // Validate trend response: array of weekly quadrant distributions
}

func TestStressMatrix_Contract_PaginationParameters(t *testing.T) {
    // Validate cursor + limit query params on list endpoint
}
```

**Exit criteria:** All contract tests exist and FAIL (RED). No implementation code yet.

---

## 4. Phase 2: Domain Types + Service Logic with Unit Tests

### 4.1 Domain Types

Create `api/internal/domain/activities/stress_matrix_types.go`:

```go
package activities

import (
    "time"
    "github.com/google/uuid"
)

type StressQuadrant string

const (
    QuadrantFocusHere StressQuadrant = "focusHere"
    QuadrantLetGo     StressQuadrant = "letGo"
    QuadrantMinimize  StressQuadrant = "minimize"
    QuadrantIgnore    StressQuadrant = "ignore"
)

type StressMatrixSession struct {
    ID                    uuid.UUID              `json:"id" bson:"_id"`
    UserID                uuid.UUID              `json:"userId" bson:"userId"`
    TenantID              string                 `json:"tenantId" bson:"tenantId"`
    Date                  time.Time              `json:"date" bson:"date"`
    CompletedAt           *time.Time             `json:"completedAt" bson:"completedAt"`
    Stressors             []StressMatrixStressor `json:"stressors" bson:"stressors"`
    QuadrantDistribution  QuadrantDistribution   `json:"quadrantDistribution" bson:"quadrantDistribution"`
    CreatedAt             time.Time              `json:"createdAt" bson:"createdAt"`
    ModifiedAt            time.Time              `json:"modifiedAt" bson:"modifiedAt"`
}

type StressMatrixStressor struct {
    ID                uuid.UUID                  `json:"id" bson:"id"`
    Text              string                     `json:"text" bson:"text"`
    Quadrant          StressQuadrant             `json:"quadrant" bson:"quadrant"`
    IsFromLibrary     bool                       `json:"isFromLibrary" bson:"isFromLibrary"`
    LibraryCategory   *string                    `json:"libraryCategory" bson:"libraryCategory,omitempty"`
    IsPrayedOver      bool                       `json:"isPrayedOver" bson:"isPrayedOver"`
    AddedAt           time.Time                  `json:"addedAt" bson:"addedAt"`
    Recategorizations []StressorRecategorization `json:"recategorizations" bson:"recategorizations"`
}

type StressorRecategorization struct {
    FromQuadrant StressQuadrant `json:"fromQuadrant" bson:"fromQuadrant"`
    ToQuadrant   StressQuadrant `json:"toQuadrant" bson:"toQuadrant"`
    Timestamp    time.Time      `json:"timestamp" bson:"timestamp"`
}

type QuadrantDistribution struct {
    FocusHere int `json:"focusHere" bson:"focusHere"`
    LetGo     int `json:"letGo" bson:"letGo"`
    Minimize  int `json:"minimize" bson:"minimize"`
    Ignore    int `json:"ignore" bson:"ignore"`
}
```

### 4.2 Repository Interface

Create `api/internal/domain/activities/stress_matrix_repository.go`:

```go
package activities

import (
    "context"
    "github.com/google/uuid"
)

type StressMatrixRepository interface {
    Create(ctx context.Context, session *StressMatrixSession) error
    GetByID(ctx context.Context, userID, sessionID uuid.UUID) (*StressMatrixSession, error)
    Update(ctx context.Context, session *StressMatrixSession) error
    Delete(ctx context.Context, userID, sessionID uuid.UUID) error
    List(ctx context.Context, userID uuid.UUID, cursor string, limit int) ([]*StressMatrixSession, string, error)
    GetTrends(ctx context.Context, userID uuid.UUID, weeks int) ([]WeeklyQuadrantDistribution, error)
}

type WeeklyQuadrantDistribution struct {
    WeekStart    time.Time            `json:"weekStart"`
    Distribution QuadrantDistribution `json:"distribution"`
    SessionCount int                  `json:"sessionCount"`
}
```

### 4.3 Service Logic

Create `api/internal/domain/activities/stress_matrix_service.go`:

```go
package activities

type StressMatrixService struct {
    repo StressMatrixRepository
}

func NewStressMatrixService(repo StressMatrixRepository) *StressMatrixService { ... }

func (s *StressMatrixService) CreateSession(ctx context.Context, userID uuid.UUID, tenantID string, input CreateSessionInput) (*StressMatrixSession, error) { ... }
func (s *StressMatrixService) AddStressor(ctx context.Context, userID, sessionID uuid.UUID, input AddStressorInput) (*StressMatrixSession, error) { ... }
func (s *StressMatrixService) MoveStressor(ctx context.Context, userID, sessionID, stressorID uuid.UUID, toQuadrant StressQuadrant) (*StressMatrixSession, error) { ... }
func (s *StressMatrixService) RemoveStressor(ctx context.Context, userID, sessionID, stressorID uuid.UUID) (*StressMatrixSession, error) { ... }
func (s *StressMatrixService) MarkPrayedOver(ctx context.Context, userID, sessionID, stressorID uuid.UUID) (*StressMatrixSession, error) { ... }
func (s *StressMatrixService) CompleteSession(ctx context.Context, userID, sessionID uuid.UUID) (*StressMatrixSession, error) { ... }
func (s *StressMatrixService) GetSession(ctx context.Context, userID, sessionID uuid.UUID) (*StressMatrixSession, error) { ... }
func (s *StressMatrixService) ListSessions(ctx context.Context, userID uuid.UUID, cursor string, limit int) ([]*StressMatrixSession, string, error) { ... }
func (s *StressMatrixService) DeleteSession(ctx context.Context, userID, sessionID uuid.UUID) error { ... }
func (s *StressMatrixService) GetTrends(ctx context.Context, userID uuid.UUID, weeks int) ([]WeeklyQuadrantDistribution, error) { ... }

// computeDistribution recalculates QuadrantDistribution from stressor list.
func computeDistribution(stressors []StressMatrixStressor) QuadrantDistribution { ... }
```

### 4.4 Unit Tests (RED -> GREEN)

Create `api/test/unit/stress_matrix_service_test.go`:

```go
// --- Session Lifecycle ---

func TestStressMatrix_AC1_1_UserCanCreateSession(t *testing.T) {
    // Given no existing session
    // When CreateSession is called with valid input
    // Then a session is created with ID, date, empty stressor list, zero distribution
}

func TestStressMatrix_AC1_2_SessionHasImmutableCreatedAt(t *testing.T) {
    // Given a session is created
    // When the session is updated
    // Then CreatedAt is unchanged (FR2.7 immutable timestamp)
}

func TestStressMatrix_AC1_3_SessionCanBeCompleted(t *testing.T) {
    // Given an in-progress session
    // When CompleteSession is called
    // Then CompletedAt is set to current time
}

func TestStressMatrix_AC1_4_CompletedSessionCannotBeModified(t *testing.T) {
    // Given a completed session
    // When AddStressor is called
    // Then an error is returned
}

// --- Stressor Management ---

func TestStressMatrix_AC2_1_UserCanAddStressorToSession(t *testing.T) {
    // Given an in-progress session
    // When AddStressor is called with text="Job stress" and quadrant=focusHere
    // Then stressor is added with generated ID, the quadrant distribution updates
}

func TestStressMatrix_AC2_2_StressorTextMaxLength200(t *testing.T) {
    // Given an in-progress session
    // When AddStressor is called with text of 201 characters
    // Then a validation error is returned
}

func TestStressMatrix_AC2_3_StressorTextCannotBeEmpty(t *testing.T) {
    // Given an in-progress session
    // When AddStressor is called with empty text
    // Then a validation error is returned
}

func TestStressMatrix_AC2_4_QuadrantMustBeValid(t *testing.T) {
    // Given an in-progress session
    // When AddStressor is called with quadrant="invalid"
    // Then a validation error is returned
}

func TestStressMatrix_AC2_5_LibraryStressorFlagged(t *testing.T) {
    // Given a library stressor input with isFromLibrary=true, libraryCategory="relational"
    // When AddStressor is called
    // Then the stressor has IsFromLibrary=true and LibraryCategory="relational"
}

// --- Recategorization ---

func TestStressMatrix_AC3_1_UserCanMoveStressorBetweenQuadrants(t *testing.T) {
    // Given a stressor in quadrant focusHere
    // When MoveStressor is called with toQuadrant=letGo
    // Then stressor.Quadrant is letGo and a recategorization record is appended
}

func TestStressMatrix_AC3_2_RecategorizationRecordsFromAndTo(t *testing.T) {
    // Given a stressor moved from focusHere to letGo
    // When the stressor is inspected
    // Then Recategorizations[0] has FromQuadrant=focusHere, ToQuadrant=letGo, Timestamp set
}

func TestStressMatrix_AC3_3_MultipleRecategorizationsTracked(t *testing.T) {
    // Given a stressor moved twice (focusHere -> letGo -> minimize)
    // When the stressor is inspected
    // Then Recategorizations has 2 entries in chronological order
}

func TestStressMatrix_AC3_4_MoveToSameQuadrantIsNoOp(t *testing.T) {
    // Given a stressor in quadrant letGo
    // When MoveStressor is called with toQuadrant=letGo
    // Then no recategorization is recorded, no error returned
}

func TestStressMatrix_AC3_5_DistributionUpdatesOnMove(t *testing.T) {
    // Given 3 stressors: 2 in focusHere, 1 in letGo
    // When one focusHere stressor is moved to letGo
    // Then distribution is focusHere=1, letGo=2, minimize=0, ignore=0
}

// --- Quadrant Distribution ---

func TestStressMatrix_AC4_1_DistributionComputedCorrectly(t *testing.T) {
    // Given stressors: [focusHere, focusHere, letGo, minimize, ignore, ignore]
    // When computeDistribution is called
    // Then result is {focusHere: 2, letGo: 1, minimize: 1, ignore: 2}
}

func TestStressMatrix_AC4_2_EmptySessionHasZeroDistribution(t *testing.T) {
    // Given an empty stressor list
    // When computeDistribution is called
    // Then result is {focusHere: 0, letGo: 0, minimize: 0, ignore: 0}
}

func TestStressMatrix_AC4_3_DistributionUpdatesOnAdd(t *testing.T) {
    // Given a session with known distribution
    // When a stressor is added
    // Then the session's QuadrantDistribution reflects the new stressor
}

func TestStressMatrix_AC4_4_DistributionUpdatesOnRemove(t *testing.T) {
    // Given a session with a stressor in focusHere
    // When RemoveStressor is called
    // Then focusHere count decreases by 1
}

// --- Prayed Over ---

func TestStressMatrix_AC5_1_UserCanMarkStressorAsPrayedOver(t *testing.T) {
    // Given a stressor with IsPrayedOver=false
    // When MarkPrayedOver is called
    // Then IsPrayedOver=true
}

func TestStressMatrix_AC5_2_PrayedOverIsIdempotent(t *testing.T) {
    // Given a stressor with IsPrayedOver=true
    // When MarkPrayedOver is called again
    // Then IsPrayedOver remains true, no error
}

// --- Session Deletion ---

func TestStressMatrix_AC6_1_UserCanDeleteSession(t *testing.T) {
    // Given an existing session
    // When DeleteSession is called
    // Then the session is removed
}

func TestStressMatrix_AC6_2_DeleteNonexistentSessionReturnsNotFound(t *testing.T) {
    // Given no session with the provided ID
    // When DeleteSession is called
    // Then a not-found error is returned
}

// --- Trends ---

func TestStressMatrix_AC7_1_TrendsReturnWeeklyDistributions(t *testing.T) {
    // Given sessions across 4 weeks
    // When GetTrends is called with weeks=4
    // Then 4 weekly distributions are returned sorted chronologically
}

func TestStressMatrix_AC7_2_TrendsAggregateMultipleSessionsPerWeek(t *testing.T) {
    // Given 3 sessions in the same week
    // When GetTrends is called
    // Then the week's distribution is the sum of all 3 sessions' stressors
}

func TestStressMatrix_AC7_3_TrendsReturnEmptyWeeksAsZero(t *testing.T) {
    // Given sessions in weeks 1 and 3 but not week 2
    // When GetTrends is called with weeks=3
    // Then week 2 has all-zero distribution with sessionCount=0
}
```

**Exit criteria:** All unit tests written (RED), then implementation makes them GREEN. Refactor.

---

## 5. Phase 3: MongoDB Repository + Integration Tests

### 5.1 MongoDB Schema

Collection: `stress_matrix_sessions`

```json
{
    "_id": "uuid",
    "userId": "uuid",
    "tenantId": "string",
    "date": "ISODate",
    "completedAt": "ISODate | null",
    "stressors": [
        {
            "id": "uuid",
            "text": "string",
            "quadrant": "string enum",
            "isFromLibrary": "bool",
            "libraryCategory": "string | null",
            "isPrayedOver": "bool",
            "addedAt": "ISODate",
            "recategorizations": [
                {
                    "fromQuadrant": "string",
                    "toQuadrant": "string",
                    "timestamp": "ISODate"
                }
            ]
        }
    ],
    "quadrantDistribution": {
        "focusHere": "int",
        "letGo": "int",
        "minimize": "int",
        "ignore": "int"
    },
    "createdAt": "ISODate",
    "modifiedAt": "ISODate"
}
```

**Indexes:**

```javascript
// Primary lookup
db.stress_matrix_sessions.createIndex({ userId: 1, date: -1 })
// Trend queries
db.stress_matrix_sessions.createIndex({ userId: 1, completedAt: -1 })
// Unique constraint per session
db.stress_matrix_sessions.createIndex({ _id: 1 }, { unique: true })
```

### 5.2 Repository Implementation

Create `api/internal/repository/stress_matrix_mongo.go`:

Implement `StressMatrixRepository` interface against MongoDB using `mongo-driver/v2`.

### 5.3 Integration Tests (RED -> GREEN)

Create `api/test/integration/stress_matrix_repository_test.go`:

```go
func TestStressMatrixRepo_Create_InsertsSession(t *testing.T) {
    // Insert session, verify it exists in MongoDB
}

func TestStressMatrixRepo_GetByID_ReturnsSession(t *testing.T) {
    // Insert session, fetch by ID, verify fields
}

func TestStressMatrixRepo_GetByID_WrongUser_ReturnsNotFound(t *testing.T) {
    // Insert session for user A, fetch with user B's ID, verify not found
    // (tenant isolation)
}

func TestStressMatrixRepo_Update_PersistsChanges(t *testing.T) {
    // Insert session, add stressor, update, fetch, verify stressor present
}

func TestStressMatrixRepo_Delete_RemovesSession(t *testing.T) {
    // Insert session, delete, verify not found
}

func TestStressMatrixRepo_List_ReturnsPaginated(t *testing.T) {
    // Insert 25 sessions, list with limit=10, verify 10 returned with cursor
}

func TestStressMatrixRepo_List_SortsByDateDescending(t *testing.T) {
    // Insert sessions with different dates, list, verify newest first
}

func TestStressMatrixRepo_GetTrends_AggregatesWeekly(t *testing.T) {
    // Insert sessions across 4 weeks, get trends, verify weekly aggregation
}

func TestStressMatrixRepo_GetTrends_HandlesEmptyWeeks(t *testing.T) {
    // Insert sessions in weeks 1 and 3, get trends for 3 weeks
    // Verify week 2 has zero distribution
}

func TestStressMatrixRepo_ImmutableCreatedAt(t *testing.T) {
    // Insert session, update, verify createdAt unchanged
}
```

**Exit criteria:** All integration tests written (RED), then repository implementation makes them GREEN. Requires `make local-up`.

---

## 6. Phase 4: Lambda Handler + API Tests

### 6.1 Handler Implementation

Add stress matrix routes to the activities Lambda handler and local server.

Routes to register:

```go
// In cmd/lambda/activities/main.go and cmd/local/main.go
mux.HandleFunc("POST /v1/activities/stress-matrix", handler.CreateSession)
mux.HandleFunc("GET /v1/activities/stress-matrix", handler.ListSessions)
mux.HandleFunc("GET /v1/activities/stress-matrix/{sessionId}", handler.GetSession)
mux.HandleFunc("PUT /v1/activities/stress-matrix/{sessionId}", handler.UpdateSession)
mux.HandleFunc("DELETE /v1/activities/stress-matrix/{sessionId}", handler.DeleteSession)
mux.HandleFunc("POST /v1/activities/stress-matrix/{sessionId}/complete", handler.CompleteSession)
mux.HandleFunc("GET /v1/activities/stress-matrix/trends", handler.GetTrends)
```

### 6.2 API Tests (RED -> GREEN)

Create `api/test/unit/stress_matrix_handler_test.go`:

```go
func TestStressMatrixHandler_AC1_1_CreateSession_Returns201(t *testing.T) {
    // POST /v1/activities/stress-matrix with valid body
    // Expect 201 with StressMatrixSessionResponse envelope
}

func TestStressMatrixHandler_AC1_2_CreateSession_InvalidBody_Returns400(t *testing.T) {
    // POST with malformed JSON -> 400 with error envelope
}

func TestStressMatrixHandler_AC2_1_GetSession_Returns200(t *testing.T) {
    // GET /v1/activities/stress-matrix/{id} -> 200 with session data
}

func TestStressMatrixHandler_AC2_2_GetSession_NotFound_Returns404(t *testing.T) {
    // GET /v1/activities/stress-matrix/{nonexistent} -> 404
}

func TestStressMatrixHandler_AC3_1_UpdateSession_AddStressor(t *testing.T) {
    // PUT with new stressor added -> 200, stressor appears in response
}

func TestStressMatrixHandler_AC3_2_UpdateSession_MoveStressor(t *testing.T) {
    // PUT with stressor quadrant changed -> 200, recategorization recorded
}

func TestStressMatrixHandler_AC4_1_CompleteSession_Returns200(t *testing.T) {
    // POST /v1/activities/stress-matrix/{id}/complete -> 200, completedAt set
}

func TestStressMatrixHandler_AC5_1_ListSessions_ReturnsPaginated(t *testing.T) {
    // GET /v1/activities/stress-matrix?limit=5 -> 200 with up to 5 sessions
}

func TestStressMatrixHandler_AC6_1_DeleteSession_Returns204(t *testing.T) {
    // DELETE /v1/activities/stress-matrix/{id} -> 204
}

func TestStressMatrixHandler_AC7_1_GetTrends_ReturnsWeekly(t *testing.T) {
    // GET /v1/activities/stress-matrix/trends?weeks=4 -> 200 with 4 weekly entries
}

func TestStressMatrixHandler_StressorTextTooLong_Returns400(t *testing.T) {
    // PUT with stressor text > 200 chars -> 400
}

func TestStressMatrixHandler_InvalidQuadrant_Returns400(t *testing.T) {
    // PUT with quadrant="badvalue" -> 400
}

func TestStressMatrixHandler_ResponseEnvelopeFormat(t *testing.T) {
    // Verify all responses use { "data": ..., "links": {...}, "meta": {...} } or { "errors": [...] }
}
```

**Exit criteria:** All handler tests RED, then GREEN after implementation. Contract tests from Phase 1 should also pass.

---

## 7. Phase 5: iOS Models + SwiftData

### 7.1 SwiftData Model

Add `RRStressMatrixSession` to `Data/Models/RRModels.swift`:

```swift
@Model
final class RRStressMatrixSession {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var date: Date
    var completedAt: Date?
    var stressorsJSON: String      // JSON-encoded [StressMatrixStressor]
    var quadrantDistributionJSON: String  // JSON-encoded QuadrantDistribution
    var createdAt: Date
    var modifiedAt: Date
    var needsSync: Bool

    init(userId: UUID) { ... }

    // Computed property to decode/encode stressors
    var stressors: [StressMatrixStressor] { get set }
    // Computed property for distribution
    var quadrantDistribution: QuadrantDistribution { get }
}
```

Register in `RRModelConfiguration.allModels`.

### 7.2 Supporting Types

Create `Models/StressMatrixTypes.swift`:

```swift
enum StressQuadrant: String, Codable, CaseIterable, Identifiable {
    case focusHere = "focus_here"
    case letGo = "let_go"
    case minimize = "minimize"
    case ignore = "ignore"

    var id: String { rawValue }
    var displayName: String { ... }
    var actionLabel: String { ... }  // "Take action", "Accept & pray", etc.
    var color: Color { ... }
    var icon: String { ... }  // SF Symbol name
}

struct StressMatrixStressor: Codable, Identifiable {
    var id: UUID
    var text: String
    var quadrant: StressQuadrant
    var isFromLibrary: Bool
    var libraryCategory: String?
    var isPrayedOver: Bool
    var addedAt: Date
    var recategorizations: [StressorRecategorization]
}

struct StressorRecategorization: Codable {
    var fromQuadrant: StressQuadrant
    var toQuadrant: StressQuadrant
    var timestamp: Date
}

struct QuadrantDistribution: Codable {
    var focusHere: Int
    var letGo: Int
    var minimize: Int
    var ignore: Int

    static let zero = QuadrantDistribution(focusHere: 0, letGo: 0, minimize: 0, ignore: 0)

    var total: Int { focusHere + letGo + minimize + ignore }
}
```

### 7.3 iOS Model Unit Tests

Create `ios/RegalRecovery/RegalRecovery/Tests/Unit/StressMatrixModelTests.swift`:

```swift
func testStressMatrix_AC1_1_SessionInitializesWithDefaults() {
    // Session has UUID, today's date, nil completedAt, empty stressors
}

func testStressMatrix_AC2_1_StressorEncodesAndDecodes() {
    // Create stressor, encode to JSON, decode, verify equality
}

func testStressMatrix_AC3_1_RecategorizationTracked() {
    // Create stressor, add recategorization, verify fromQuadrant and toQuadrant
}

func testStressMatrix_AC4_1_QuadrantDistributionComputed() {
    // Session with known stressors, verify distribution counts
}

func testStressMatrix_AC4_2_EmptySessionHasZeroDistribution() {
    // Empty stressor list -> all zeros
}

func testStressMatrix_AC5_1_PrayedOverDefaultsFalse() {
    // New stressor has isPrayedOver = false
}

func testStressMatrix_AC6_1_QuadrantEnumAllCases() {
    // StressQuadrant.allCases has exactly 4 values
}

func testStressMatrix_AC6_2_QuadrantDisplayNames() {
    // Each quadrant has a non-empty displayName
}

func testStressMatrix_AC6_3_QuadrantColors() {
    // Each quadrant has a distinct color
}
```

**Exit criteria:** Tests RED, then GREEN after model implementation.

---

## 8. Phase 6: iOS Views + ViewModel Tests (Matrix UI)

### 8.1 StressMatrixViewModel

Create `ViewModels/StressMatrixViewModel.swift`:

```swift
@Observable
class StressMatrixViewModel {
    // Session state
    var session: RRStressMatrixSession?
    var stressors: [StressMatrixStressor] = []
    var isLoading: Bool = true
    var isNewSession: Bool = true

    // Entry state
    var newStressorText: String = ""
    var selectedQuadrant: StressQuadrant?
    var showingLibrary: Bool = false
    var showingQuadrantDetail: StressQuadrant?

    // Computed
    var distribution: QuadrantDistribution { ... }
    var stressorsForQuadrant(_ quadrant: StressQuadrant) -> [StressMatrixStressor] { ... }
    var canSaveStressor: Bool { !newStressorText.isEmpty && selectedQuadrant != nil }

    // Actions
    func loadOrCreateSession(context: ModelContext, userId: UUID) { ... }
    func addStressor(context: ModelContext) { ... }
    func addLibraryStressor(_ stressor: LibraryStressor, quadrant: StressQuadrant, context: ModelContext) { ... }
    func moveStressor(_ stressorId: UUID, to quadrant: StressQuadrant, context: ModelContext) { ... }
    func removeStressor(_ stressorId: UUID, context: ModelContext) { ... }
    func markPrayedOver(_ stressorId: UUID, context: ModelContext) { ... }
    func completeSession(context: ModelContext) { ... }
}
```

### 8.2 ViewModel Unit Tests (RED -> GREEN)

Create `ios/RegalRecovery/RegalRecovery/Tests/Unit/StressMatrixViewModelTests.swift`:

```swift
func testStressMatrix_AC1_1_AddStressorUpdatesStressorList() {
    // Set text and quadrant, call addStressor, verify stressor in list
}

func testStressMatrix_AC1_2_AddStressorClearsInputState() {
    // After addStressor, newStressorText is empty, selectedQuadrant is nil
}

func testStressMatrix_AC2_1_MoveStressorChangesQuadrant() {
    // Add stressor to focusHere, move to letGo, verify quadrant changed
}

func testStressMatrix_AC2_2_MoveStressorRecordsRecategorization() {
    // Move stressor, verify recategorization record has from/to/timestamp
}

func testStressMatrix_AC3_1_RemoveStressorUpdatesDistribution() {
    // Add 3 stressors, remove 1, verify distribution counts
}

func testStressMatrix_AC4_1_DistributionComputedFromStressors() {
    // Add stressors to known quadrants, verify distribution
}

func testStressMatrix_AC5_1_MarkPrayedOverTogglesBool() {
    // Add stressor, mark prayed over, verify isPrayedOver = true
}

func testStressMatrix_AC6_1_CompleteSessionSetsCompletedAt() {
    // Complete session, verify completedAt is not nil
}

func testStressMatrix_AC7_1_StressorsForQuadrantFiltersCorrectly() {
    // 5 stressors across quadrants, filter for focusHere, verify only focusHere returned
}

func testStressMatrix_AC8_1_CannotAddEmptyStressor() {
    // Set empty text, verify canSaveStressor is false
}

func testStressMatrix_AC8_2_CannotAddWithoutQuadrant() {
    // Set text but no quadrant, verify canSaveStressor is false
}

func testStressMatrix_AC9_1_LibraryStressorHasIsFromLibraryTrue() {
    // Add from library, verify isFromLibrary = true
}

func testStressMatrix_AC9_2_LibraryStressorHasCategory() {
    // Add from library with category "relational", verify libraryCategory
}
```

### 8.3 Views

Create the following view files in `Views/Activities/StressMatrix/`:

**`StressMatrixView.swift`** -- Main view with 2x2 grid showing quadrant labels, stressor counts, and stressor snippets. "Add Stressor" button. Tap quadrant to expand.

**`StressMatrixQuadrantDetailView.swift`** -- Full-screen detail for a quadrant showing: all stressors (with move/delete/pray actions), action guidance text, scripture verses, prayer prompt.

**`StressMatrixLibrarySheet.swift`** -- Bottom sheet with categories, search, and tap-to-select.

**`StressMatrixEntryView.swift`** -- Stressor text input + quadrant selection buttons.

**`StressMatrixDistributionChart.swift`** -- Pie chart or segmented bar using Swift Charts.

---

## 9. Phase 7: Stressor Library + Categorization Logic

### 9.1 Library Data

Create `Models/StressMatrixLibrary.swift`:

```swift
struct LibraryStressor: Identifiable {
    let id: UUID
    let text: String
    let category: StressorCategory
    let suggestedQuadrant: StressQuadrant
}

enum StressorCategory: String, CaseIterable, Identifiable {
    case relational
    case workFinancial = "work_financial"
    case recovery
    case health
    case emotionalSpiritual = "emotional_spiritual"
    case circumstantial

    var id: String { rawValue }
    var displayName: String { ... }
    var icon: String { ... }
}

extension LibraryStressor {
    static let all: [LibraryStressor] = [
        // Relational (8)
        LibraryStressor(id: UUID(), text: "Rebuilding trust with my spouse", category: .relational, suggestedQuadrant: .focusHere),
        // ... all 43 library stressors from PRD Appendix B
    ]

    static func stressors(for category: StressorCategory) -> [LibraryStressor] { ... }
    static func search(_ query: String) -> [LibraryStressor] { ... }
}
```

### 9.2 Quadrant Content Data

Create `Models/StressMatrixContent.swift`:

```swift
struct StressMatrixQuadrantContent {
    let quadrant: StressQuadrant
    let title: String
    let definition: String
    let actionGuidance: [String]      // Bullet points
    let recoveryExamples: [String]
    let spiritualPosture: String
    let scriptures: [ScriptureReference]
    let prayerPrompt: String
}

struct ScriptureReference {
    let reference: String    // "1 Peter 5:7"
    let text: String         // Full verse text
}

extension StressMatrixQuadrantContent {
    static let all: [StressMatrixQuadrantContent] = [
        // Focus Here, Let Go, Minimize, Ignore
        // Content from PRD Section 3
    ]

    static func content(for quadrant: StressQuadrant) -> StressMatrixQuadrantContent { ... }
}
```

### 9.3 Library Tests (RED -> GREEN)

```swift
func testStressMatrix_Library_AC1_1_AllLibraryStressorsHaveUniqueIds() {
    // Verify no duplicate IDs in LibraryStressor.all
}

func testStressMatrix_Library_AC1_2_AllCategoriesRepresented() {
    // Verify every StressorCategory has at least 1 library stressor
}

func testStressMatrix_Library_AC2_1_SearchFindsMatchingStressors() {
    // Search "spouse" -> returns stressors containing "spouse"
}

func testStressMatrix_Library_AC2_2_SearchIsCaseInsensitive() {
    // Search "SPOUSE" -> returns same results as "spouse"
}

func testStressMatrix_Library_AC2_3_EmptySearchReturnsAll() {
    // Search "" -> returns all library stressors
}

func testStressMatrix_Library_AC3_1_CategoryFilterReturnsCorrectStressors() {
    // Filter by .relational -> only relational stressors returned
}

func testStressMatrix_Library_AC4_1_AllSuggestedQuadrantsAreValid() {
    // Verify every library stressor has a valid StressQuadrant
}

func testStressMatrix_Content_AC1_1_AllQuadrantsHaveContent() {
    // Verify StressMatrixQuadrantContent.all has exactly 4 entries
}

func testStressMatrix_Content_AC1_2_AllQuadrantsHaveScripture() {
    // Verify each quadrant content has at least 2 scripture references
}

func testStressMatrix_Content_AC1_3_AllQuadrantsHavePrayerPrompt() {
    // Verify each quadrant content has a non-empty prayer prompt
}

func testStressMatrix_Content_AC1_4_AllQuadrantsHaveActionGuidance() {
    // Verify each quadrant content has at least 2 action guidance items
}
```

---

## 10. Phase 8: Integration with FASTER Scale, Journaling, Emergency Layer

### 8.1 FASTER Scale Integration

Modify `ViewModels/FASTERCheckInViewModel.swift` (or the FASTER check-in completion flow):

After a FASTER check-in is saved at stage A (Anxiety) or S (Speeding Up), surface a prompt card.

**Tests (RED -> GREEN):**

```swift
func testStressMatrix_FASTER_AC1_1_PromptShownAtAnxietyStage() {
    // Given FASTER check-in completes at stage A
    // When completion view renders
    // Then a "Sort your stressors?" prompt card is visible
}

func testStressMatrix_FASTER_AC1_2_PromptShownAtStressedStage() {
    // Given FASTER check-in completes at stage S
    // Then prompt card is visible
}

func testStressMatrix_FASTER_AC1_3_PromptNotShownAtOtherStages() {
    // Given FASTER check-in completes at stage F, T, E, or R
    // Then no matrix prompt card is shown
}

func testStressMatrix_FASTER_AC1_4_PromptDismissable() {
    // Given prompt is shown
    // When user taps "Not now"
    // Then prompt is dismissed
}
```

### 8.2 Today View Integration

Modify `ViewModels/TodayViewModel.swift`:

Add matrix session completion to the activity log (same pattern as FASTER and PCI entries).

**Tests (RED -> GREEN):**

```swift
func testStressMatrix_Today_AC1_1_CompletedSessionAppearsInActivityLog() {
    // Given a completed matrix session today
    // When activity log loads
    // Then a "Stress Matrix: X stressors sorted" entry appears
}

func testStressMatrix_Today_AC1_2_InProgressSessionDoesNotAppear() {
    // Given an in-progress session (not completed)
    // When activity log loads
    // Then no matrix entry appears
}

func testStressMatrix_Today_AC2_1_CompletionTimestampTracked() {
    // Given a completed matrix session
    // When completionTimestamps("stress-matrix") is called
    // Then the session's completedAt is returned
}
```

### 8.3 Journal Integration

When user taps "Journal about this" on a stressor, open journal entry with pre-filled prompt.

**Tests (RED -> GREEN):**

```swift
func testStressMatrix_Journal_AC1_1_PromptGeneratedForFocusHereStressor() {
    // Given stressor "Job stress" in Focus Here
    // When journal prompt is generated
    // Then prompt contains the stressor text and "What is one action you can take today?"
}

func testStressMatrix_Journal_AC1_2_PromptGeneratedForLetGoStressor() {
    // Given stressor "Spouse's trust timeline" in Let Go
    // When journal prompt is generated
    // Then prompt contains "What does surrender look like for this?"
}
```

---

## 11. Phase 9: Feature Flag Wiring

### 9.1 Feature Flag Registration

Add `activity.stress-matrix` to:
- **iOS:** `FeatureFlagStore.swift` `flagDefaults` dictionary (default: `true`)
- **Backend:** `scripts/seed-flags.js` or equivalent flag seed script

### 9.2 Flag Gating

**iOS:**
- `RecoveryWorkViewModel.swift`: Stress Matrix tile visibility gated by `FeatureFlagStore.shared.isEnabled("activity.stress-matrix")`
- `ActivityDestinationView.swift`: Route `"stress-matrix"` to `StressMatrixView()`
- `RecoveryWorkView.swift`: Tile registered with `featureFlagKey: "activity.stress-matrix"`

**Backend:**
- Handler registration wrapped in flag check (follows existing pattern)

### 9.3 Flag Tests

```go
func TestStressMatrix_Flag_AC1_1_FeatureDisabledReturns404(t *testing.T) {
    // Given flag activity.stress-matrix is disabled
    // When POST /v1/activities/stress-matrix is called
    // Then 404 or 403 is returned
}

func TestStressMatrix_Flag_AC1_2_FeatureEnabledReturns201(t *testing.T) {
    // Given flag activity.stress-matrix is enabled
    // When POST /v1/activities/stress-matrix is called with valid body
    // Then 201 is returned
}
```

```swift
func testStressMatrix_Flag_AC1_1_TileHiddenWhenFlagDisabled() {
    // Given feature flag "activity.stress-matrix" is false
    // When Recovery Work tiles render
    // Then no "Stress Matrix" tile is visible
}

func testStressMatrix_Flag_AC1_2_TileVisibleWhenFlagEnabled() {
    // Given feature flag "activity.stress-matrix" is true
    // When Recovery Work tiles render
    // Then "Stress Matrix" tile is visible
}
```

---

## 12. Test Naming Convention

All test functions follow the project convention:

```
Test{Feature}_{AcceptanceCriteria}_{Description}
```

Examples:
```
TestStressMatrix_AC1_1_UserCanCreateSession
TestStressMatrix_AC2_2_StressorTextMaxLength200
TestStressMatrix_AC3_1_UserCanMoveStressorBetweenQuadrants
TestStressMatrix_AC7_1_TrendsReturnWeeklyDistributions
TestStressMatrix_FASTER_AC1_1_PromptShownAtAnxietyStage
TestStressMatrix_Library_AC2_1_SearchFindsMatchingStressors
TestStressMatrix_Contract_CreateSessionRequestSchema
```

iOS tests use the same pattern with `test` prefix (lowercase):
```
testStressMatrix_AC1_1_SessionInitializesWithDefaults
testStressMatrix_AC4_1_QuadrantDistributionComputed
testStressMatrix_Flag_AC1_1_TileHiddenWhenFlagDisabled
```

---

## 13. Verification Checklist

### Build Verification
- [ ] `make spec-validate` passes with stress-matrix additions to activities.yaml
- [ ] `make contract-test` passes for stress-matrix schemas
- [ ] `make test-unit` passes (all Go unit tests GREEN)
- [ ] `make test-integration` passes (all Go integration tests GREEN, requires `make local-up`)
- [ ] Xcode build succeeds with no errors
- [ ] iOS unit tests pass

### Feature Flow Verification
- [ ] Recovery Work tab shows "Stress Matrix" tile (flag-controlled)
- [ ] New session creates blank 2x2 grid
- [ ] Custom stressor entry with tap-to-place works
- [ ] Library stressor selection with suggested quadrant works
- [ ] Stressor appears in correct quadrant on grid
- [ ] Long-press stressor shows move options
- [ ] Moving stressor records recategorization
- [ ] Quadrant detail shows stressors, action guidance, scripture, and prayer
- [ ] Prayed-over marking works on any stressor
- [ ] Session completes and appears in history
- [ ] Past sessions open in read-only mode
- [ ] Distribution chart renders correctly
- [ ] Trend view shows weekly distribution over 8 weeks
- [ ] Carry-forward prompts and works
- [ ] Today view shows completed session in activity feed
- [ ] FASTER Scale A/S prompt appears and navigates to matrix
- [ ] Feature flag disabling hides all matrix UI

### Data Integrity Verification
- [ ] CreatedAt is immutable on sessions
- [ ] Session auto-saves after each stressor add/move
- [ ] Quadrant distribution matches stressor counts at all times
- [ ] Recategorization history is append-only
- [ ] Library stressor text is not editable
- [ ] Date comparisons use `Calendar.current.startOfDay(for:)` consistently

### API Contract Verification
- [ ] All endpoints return `{ "data": ... }` or `{ "errors": [...] }` envelope
- [ ] JSON properties are camelCase
- [ ] URL paths are kebab-case (`/stress-matrix`)
- [ ] Pagination uses cursor + limit
- [ ] Error codes follow `rr:0x{8 hex}` format
- [ ] Stressor text validated to max 200 characters
- [ ] Quadrant enum validated to exactly 4 values

### Security Verification
- [ ] Stressor text stored locally only on iOS (no API sync in V1)
- [ ] Backend enforces tenant isolation (userId filter on all queries)
- [ ] Accountability sharing exposes only distribution, never stressor text
- [ ] Biometric lock protects matrix data (inherited from app gate)
