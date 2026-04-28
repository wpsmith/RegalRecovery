# CBT Thought Records -- TDD Implementation Plan

| Field | Value |
|---|---|
| **Feature** | CBT Thought Records |
| **Date** | 2026-04-26 |
| **Methodology** | Test-Driven Development (RED -> GREEN -> REFACTOR) |
| **Target Directory** | `ios/RegalRecovery/RegalRecovery/` (iOS) and `api/` (Backend) |
| **Feature Flag** | `activity.cbt-thoughts` |
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
8. [Phase 6: iOS Views + ViewModel Tests (Guided Wizard)](#8-phase-6-ios-views--viewmodel-tests-guided-wizard)
9. [Phase 7: Cognitive Distortion Library + Pattern Analysis](#9-phase-7-cognitive-distortion-library--pattern-analysis)
10. [Phase 8: Integration with Urge Log, FASTER Scale, Post-Mortem](#10-phase-8-integration-with-urge-log-faster-scale-post-mortem)
11. [Phase 9: Feature Flag Wiring](#11-phase-9-feature-flag-wiring)
12. [Test Naming Convention](#12-test-naming-convention)
13. [Verification Checklist](#13-verification-checklist)

---

## 1. Architecture Overview

### Backend (Go)

```
api/
  cmd/lambda/activities/            # Lambda entrypoint (activities domain)
  cmd/local/                        # Local HTTP server
  internal/
    domain/activities/
      cbt_thought_types.go          # Domain types: ThoughtRecord, CognitiveDistortion, EmotionRating
      cbt_thought_service.go        # Business logic: create, update, level progression, pattern analysis
      cbt_thought_repository.go     # Repository interface
    repository/
      cbt_thought_mongo.go          # MongoDB implementation
  test/unit/
    cbt_thought_service_test.go
    cbt_thought_handler_test.go
  test/integration/
    cbt_thought_repository_test.go
```

### iOS (Swift)

```
ios/RegalRecovery/RegalRecovery/
  Data/Models/RRModels.swift                 # Add RRThoughtRecord, RRCBTProgress @Models
  Models/CBTThoughtTypes.swift               # Codable types, enums
  Models/CognitiveDistortionLibrary.swift    # 14 distortions with definitions, examples, scripture
  ViewModels/CBTThoughtWizardViewModel.swift # Wizard state machine
  ViewModels/CBTThoughtHistoryViewModel.swift
  ViewModels/CBTPatternViewModel.swift       # Analytics and pattern detection
  Views/Activities/CBTThoughts/
    CBTThoughtPsychoeducationView.swift      # First-use educational screen
    CBTThoughtWizardView.swift               # Step-by-step wizard container
    CBTSituationStepView.swift               # Step 1: Situation
    CBTAutomaticThoughtStepView.swift        # Step 2: Automatic Thought(s)
    CBTEmotionStepView.swift                 # Step 3: Emotions with intensity
    CBTDistortionStepView.swift              # Step 4: Cognitive Distortion picker
    CBTEvidenceForStepView.swift             # Step 5: Evidence For (7-col only)
    CBTEvidenceAgainstStepView.swift         # Step 6: Evidence Against (7-col only)
    CBTBalancedThoughtStepView.swift         # Step 7: Balanced Thought
    CBTOutcomeStepView.swift                 # Step 8: Outcome re-rating (7-col only)
    CBTThoughtHistoryView.swift              # History list
    CBTThoughtDetailView.swift               # Read-only completed record
    CBTPatternDashboardView.swift            # Distortion frequency + emotion trends
    CBTDistortionLibraryView.swift           # Standalone browsable library
    CBTDistortionDetailView.swift            # Single distortion deep-dive
    CBTTruthLibraryView.swift                # Bookmarked balanced thoughts
  Services/FeatureFlagStore.swift            # Add flag seed
```

### API Spec

```
docs/specs/openapi/activities.yaml    # Add cbt-thoughts paths and schemas
```

---

## 2. Phase Summary

| Phase | Focus | Test Type | Key Deliverables |
|---|---|---|---|
| 1 | OpenAPI Spec + Contract Tests | Contract (RED) | OpenAPI paths, schemas, contract test stubs |
| 2 | Domain Types + Service Logic | Unit (RED -> GREEN) | Go domain types, service, unit tests |
| 3 | MongoDB Repository | Integration (RED -> GREEN) | Repository implementation, integration tests |
| 4 | Lambda Handler + API | API (RED -> GREEN) | HTTP handler, route registration, API tests |
| 5 | iOS Models + SwiftData | Unit (RED -> GREEN) | SwiftData models, Codable types, level logic |
| 6 | iOS Views + ViewModel | ViewModel Unit + UI (RED -> GREEN) | Wizard flow, history, detail views |
| 7 | Distortion Library + Patterns | Unit (RED -> GREEN) | Library data, pattern analysis, analytics |
| 8 | Feature Integration | Integration (RED -> GREEN) | Urge log link, FASTER link, Today view |
| 9 | Feature Flag Wiring | Integration (GREEN) | Flag registration, gated visibility |

---

## 3. Phase 1: OpenAPI Spec + Contract Tests (RED)

### 3.1 OpenAPI Spec Additions

Add the following paths and schemas to `docs/specs/openapi/activities.yaml`:

**Paths:**

```yaml
/activities/cbt-thoughts:
  post:
    summary: Create a new CBT thought record
    tags: [CBT Thoughts]
    operationId: createThoughtRecord
    requestBody:
      required: true
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/CreateThoughtRecordRequest'
    responses:
      '201':
        description: Thought record created
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/ThoughtRecordResponse'
  get:
    summary: List thought records
    tags: [CBT Thoughts]
    operationId: listThoughtRecords
    parameters:
      - name: cursor
        in: query
        schema: { type: string }
      - name: limit
        in: query
        schema: { type: integer, default: 20, maximum: 100 }
      - name: mode
        in: query
        schema: { type: integer, enum: [3, 5, 7] }
    responses:
      '200':
        description: Thought record list
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/ThoughtRecordListResponse'

/activities/cbt-thoughts/{recordId}:
  get:
    summary: Get a thought record by ID
    tags: [CBT Thoughts]
    operationId: getThoughtRecord
  put:
    summary: Update a thought record (draft save between wizard steps)
    tags: [CBT Thoughts]
    operationId: updateThoughtRecord
  delete:
    summary: Delete a thought record permanently
    tags: [CBT Thoughts]
    operationId: deleteThoughtRecord

/activities/cbt-thoughts/progress:
  get:
    summary: Get user's CBT progress (level, record count)
    tags: [CBT Thoughts]
    operationId: getCBTProgress

/activities/cbt-thoughts/patterns:
  get:
    summary: Get distortion frequency and emotion trend analytics
    tags: [CBT Thoughts]
    operationId: getCBTPatterns
    parameters:
      - name: weeks
        in: query
        schema: { type: integer, default: 8, maximum: 52 }

/activities/cbt-thoughts/truth-library:
  get:
    summary: List bookmarked balanced thoughts
    tags: [CBT Thoughts]
    operationId: listTruthLibrary
```

**Schemas:**

```yaml
CreateThoughtRecordRequest:
  type: object
  required: [mode, situationText, thoughtsJSON, emotionsJSON]
  properties:
    mode:
      type: integer
      enum: [3, 5, 7]
    situationText:
      type: string
      maxLength: 500
    thoughtsJSON:
      type: string
      description: JSON-encoded array of ThoughtEntry objects
    emotionsJSON:
      type: string
      description: JSON-encoded array of EmotionRating objects
    distortionsJSON:
      type: string
      nullable: true
      description: JSON-encoded array of distortion IDs (5/7-col only)
    evidenceForText:
      type: string
      maxLength: 500
      nullable: true
    evidenceAgainstText:
      type: string
      maxLength: 500
      nullable: true
    balancedThoughtText:
      type: string
      maxLength: 1000
      nullable: true
    outcomeEmotionsJSON:
      type: string
      nullable: true
    isPrivate:
      type: boolean
      default: false
    linkedUrgeLogId:
      type: string
      format: uuid
      nullable: true
    linkedFasterEntryId:
      type: string
      format: uuid
      nullable: true

ThoughtEntry:
  type: object
  required: [id, text]
  properties:
    id:
      type: string
      format: uuid
    text:
      type: string
      maxLength: 300
    isHotThought:
      type: boolean
      default: false

EmotionRating:
  type: object
  required: [id, emotionType, intensity]
  properties:
    id:
      type: string
      format: uuid
    emotionType:
      type: string
    intensity:
      type: integer
      minimum: 0
      maximum: 100

ThoughtRecordResponse:
  type: object
  properties:
    data:
      $ref: '#/components/schemas/ThoughtRecord'

ThoughtRecord:
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
      format: date-time
    mode:
      type: integer
      enum: [3, 5, 7]
    situationText:
      type: string
    thoughtsJSON:
      type: string
    emotionsJSON:
      type: string
    distortionsJSON:
      type: string
      nullable: true
    evidenceForText:
      type: string
      nullable: true
    evidenceAgainstText:
      type: string
      nullable: true
    balancedThoughtText:
      type: string
      nullable: true
    outcomeEmotionsJSON:
      type: string
      nullable: true
    isBookmarked:
      type: boolean
    isPrivate:
      type: boolean
    linkedUrgeLogId:
      type: string
      format: uuid
      nullable: true
    linkedFasterEntryId:
      type: string
      format: uuid
      nullable: true
    emotionChange:
      type: number
      format: float
      nullable: true
      description: Average emotion intensity reduction (before - after), 7-col only
    createdAt:
      type: string
      format: date-time
    modifiedAt:
      type: string
      format: date-time

CBTProgress:
  type: object
  properties:
    totalRecordsCompleted:
      type: integer
    unlockedLevel:
      type: integer
      enum: [3, 5, 7]
    preferredLevel:
      type: integer
      enum: [3, 5, 7]
    hasSeenPsychoeducation:
      type: boolean

CBTPatterns:
  type: object
  properties:
    distortionFrequency:
      type: array
      items:
        type: object
        properties:
          distortionId:
            type: string
          count:
            type: integer
    emotionTrend:
      type: array
      items:
        type: object
        properties:
          week:
            type: string
            format: date
          avgBeforeIntensity:
            type: number
          avgAfterIntensity:
            type: number
          recordCount:
            type: integer
```

### 3.2 Contract Tests (RED)

Create `api/test/unit/cbt_thought_contract_test.go`:

```go
// All tests RED -- no implementation exists yet.

func TestCBTThought_Contract_CreateRequestSchema(t *testing.T) {
    // Validate CreateThoughtRecordRequest matches OpenAPI schema
    // - mode is required, enum [3, 5, 7]
    // - situationText required, max 500 chars
    // - thoughtsJSON required (JSON-encoded ThoughtEntry array)
    // - emotionsJSON required (JSON-encoded EmotionRating array)
    // - distortionsJSON nullable (only for 5/7-col)
    // - evidenceForText, evidenceAgainstText nullable (only for 7-col)
    // - balancedThoughtText nullable (only for 5/7-col)
    // - outcomeEmotionsJSON nullable (only for 7-col)
}

func TestCBTThought_Contract_ThoughtRecordResponseSchema(t *testing.T) {
    // Validate ThoughtRecordResponse envelope: { data: ... }
    // - All fields present with correct types
    // - emotionChange nullable float
}

func TestCBTThought_Contract_ModeEnumValues(t *testing.T) {
    // Validate mode enum: exactly [3, 5, 7]
}

func TestCBTThought_Contract_EmotionIntensityRange(t *testing.T) {
    // Validate EmotionRating intensity: minimum 0, maximum 100
}

func TestCBTThought_Contract_ThoughtEntryMaxLength(t *testing.T) {
    // Validate ThoughtEntry text max 300 characters
    // Validate situationText max 500 characters
}

func TestCBTThought_Contract_ProgressResponseSchema(t *testing.T) {
    // Validate CBTProgress: totalRecordsCompleted, unlockedLevel (enum), preferredLevel (enum), hasSeenPsychoeducation
}

func TestCBTThought_Contract_PatternsResponseSchema(t *testing.T) {
    // Validate CBTPatterns: distortionFrequency array, emotionTrend array with week/avg fields
}

func TestCBTThought_Contract_PaginationParameters(t *testing.T) {
    // Validate cursor + limit query params on list endpoint
    // Validate optional mode filter
}
```

**Exit criteria:** All 8 contract tests exist and FAIL (RED). No implementation code yet.

---

## 4. Phase 2: Domain Types + Service Logic with Unit Tests

### 4.1 Domain Types

Create `api/internal/domain/activities/cbt_thought_types.go`:

```go
package activities

import (
    "time"
    "github.com/google/uuid"
)

type ThoughtRecordMode int

const (
    ThoughtMode3Column ThoughtRecordMode = 3
    ThoughtMode5Column ThoughtRecordMode = 5
    ThoughtMode7Column ThoughtRecordMode = 7
)

type CognitiveDistortionID string

const (
    DistortionAllOrNothing          CognitiveDistortionID = "all_or_nothing"
    DistortionOvergeneralization     CognitiveDistortionID = "overgeneralization"
    DistortionMentalFilter           CognitiveDistortionID = "mental_filter"
    DistortionDisqualifyingPositive  CognitiveDistortionID = "disqualifying_positive"
    DistortionMindReading            CognitiveDistortionID = "mind_reading"
    DistortionFortuneTelling         CognitiveDistortionID = "fortune_telling"
    DistortionCatastrophizing        CognitiveDistortionID = "catastrophizing"
    DistortionMagnification          CognitiveDistortionID = "magnification_minimization"
    DistortionEmotionalReasoning     CognitiveDistortionID = "emotional_reasoning"
    DistortionShouldStatements       CognitiveDistortionID = "should_statements"
    DistortionLabeling               CognitiveDistortionID = "labeling"
    DistortionPersonalization        CognitiveDistortionID = "personalization"
    DistortionBlaming                CognitiveDistortionID = "blaming"
    DistortionEntitlement            CognitiveDistortionID = "entitlement"
)

type ThoughtRecord struct {
    ID                  uuid.UUID              `json:"id" bson:"_id"`
    UserID              uuid.UUID              `json:"userId" bson:"userId"`
    TenantID            string                 `json:"tenantId" bson:"tenantId"`
    Date                time.Time              `json:"date" bson:"date"`
    Mode                ThoughtRecordMode      `json:"mode" bson:"mode"`
    SituationText       string                 `json:"situationText" bson:"situationText"`
    Thoughts            []ThoughtEntry         `json:"thoughts" bson:"thoughts"`
    Emotions            []EmotionRating        `json:"emotions" bson:"emotions"`
    Distortions         []CognitiveDistortionID `json:"distortions,omitempty" bson:"distortions,omitempty"`
    EvidenceForText     *string                `json:"evidenceForText,omitempty" bson:"evidenceForText,omitempty"`
    EvidenceAgainstText *string                `json:"evidenceAgainstText,omitempty" bson:"evidenceAgainstText,omitempty"`
    BalancedThoughtText *string                `json:"balancedThoughtText,omitempty" bson:"balancedThoughtText,omitempty"`
    OutcomeEmotions     []EmotionRating        `json:"outcomeEmotions,omitempty" bson:"outcomeEmotions,omitempty"`
    IsBookmarked        bool                   `json:"isBookmarked" bson:"isBookmarked"`
    IsPrivate           bool                   `json:"isPrivate" bson:"isPrivate"`
    LinkedUrgeLogID     *uuid.UUID             `json:"linkedUrgeLogId,omitempty" bson:"linkedUrgeLogId,omitempty"`
    LinkedFASTEREntryID *uuid.UUID             `json:"linkedFasterEntryId,omitempty" bson:"linkedFasterEntryId,omitempty"`
    EmotionChange       *float64               `json:"emotionChange,omitempty" bson:"emotionChange,omitempty"`
    CreatedAt           time.Time              `json:"createdAt" bson:"createdAt"`
    ModifiedAt          time.Time              `json:"modifiedAt" bson:"modifiedAt"`
}

type ThoughtEntry struct {
    ID          uuid.UUID `json:"id" bson:"id"`
    Text        string    `json:"text" bson:"text"`
    IsHotThought bool    `json:"isHotThought" bson:"isHotThought"`
}

type EmotionRating struct {
    ID           uuid.UUID `json:"id" bson:"id"`
    EmotionType  string    `json:"emotionType" bson:"emotionType"`
    Intensity    int       `json:"intensity" bson:"intensity"`
}

type CBTProgress struct {
    ID                     uuid.UUID `json:"id" bson:"_id"`
    UserID                 uuid.UUID `json:"userId" bson:"userId"`
    TotalRecordsCompleted  int       `json:"totalRecordsCompleted" bson:"totalRecordsCompleted"`
    UnlockedLevel          int       `json:"unlockedLevel" bson:"unlockedLevel"`
    PreferredLevel         int       `json:"preferredLevel" bson:"preferredLevel"`
    HasSeenPsychoeducation bool      `json:"hasSeenPsychoeducation" bson:"hasSeenPsychoeducation"`
    CreatedAt              time.Time `json:"createdAt" bson:"createdAt"`
    ModifiedAt             time.Time `json:"modifiedAt" bson:"modifiedAt"`
}
```

### 4.2 Repository Interface

Create `api/internal/domain/activities/cbt_thought_repository.go`:

```go
package activities

import (
    "context"
    "github.com/google/uuid"
)

type CBTThoughtRepository interface {
    CreateThoughtRecord(ctx context.Context, record *ThoughtRecord) error
    GetThoughtRecord(ctx context.Context, userID, recordID uuid.UUID) (*ThoughtRecord, error)
    UpdateThoughtRecord(ctx context.Context, record *ThoughtRecord) error
    DeleteThoughtRecord(ctx context.Context, userID, recordID uuid.UUID) error
    ListThoughtRecords(ctx context.Context, userID uuid.UUID, cursor string, limit int, mode *int) ([]ThoughtRecord, string, error)
    GetCBTProgress(ctx context.Context, userID uuid.UUID) (*CBTProgress, error)
    UpsertCBTProgress(ctx context.Context, progress *CBTProgress) error
    GetDistortionFrequency(ctx context.Context, userID uuid.UUID, weeks int) (map[CognitiveDistortionID]int, error)
    GetEmotionTrend(ctx context.Context, userID uuid.UUID, weeks int) ([]EmotionTrendWeek, error)
    ListBookmarkedThoughts(ctx context.Context, userID uuid.UUID) ([]ThoughtRecord, error)
}

type EmotionTrendWeek struct {
    Week               string  `json:"week"`
    AvgBeforeIntensity float64 `json:"avgBeforeIntensity"`
    AvgAfterIntensity  float64 `json:"avgAfterIntensity"`
    RecordCount        int     `json:"recordCount"`
}
```

### 4.3 Service

Create `api/internal/domain/activities/cbt_thought_service.go`:

```go
package activities

type CBTThoughtService struct {
    repo CBTThoughtRepository
}

func NewCBTThoughtService(repo CBTThoughtRepository) *CBTThoughtService {
    return &CBTThoughtService{repo: repo}
}
```

### 4.4 Unit Tests (RED -> GREEN)

Create `api/test/unit/cbt_thought_service_test.go`:

```go
// --- Validation Tests ---

func TestCBTThought_AC2_1_3ColumnRequiresSituationThoughtsEmotions(t *testing.T) {
    // Given mode=3, When situationText is empty, Then validation error
    // Given mode=3, When thoughts array is empty, Then validation error
    // Given mode=3, When emotions array is empty, Then validation error
}

func TestCBTThought_AC2_2_SituationTextMax500Chars(t *testing.T) {
    // Given situationText of 501 chars, When creating record, Then validation error
    // Given situationText of 500 chars, When creating record, Then success
}

func TestCBTThought_AC2_3_ThoughtEntryMax300Chars(t *testing.T) {
    // Given a thought entry with 301 chars, When creating record, Then validation error
}

func TestCBTThought_AC2_4_ThoughtsArrayMax5Entries(t *testing.T) {
    // Given 6 thought entries, When creating record, Then validation error
    // Given 5 thought entries, When creating record, Then success
}

func TestCBTThought_AC2_5_EmotionIntensityRange0To100(t *testing.T) {
    // Given emotion intensity of -1, When creating record, Then validation error
    // Given emotion intensity of 101, When creating record, Then validation error
    // Given emotion intensity of 0, When creating record, Then success
    // Given emotion intensity of 100, When creating record, Then success
}

func TestCBTThought_AC2_6_EmotionsArrayMax5Entries(t *testing.T) {
    // Given 6 emotions, When creating record, Then validation error
}

func TestCBTThought_AC3_1_5ColumnRequiresDistortions(t *testing.T) {
    // Given mode=5, When distortions is nil, Then validation error
    // Given mode=5, When distortions has 1-3 items, Then success
}

func TestCBTThought_AC3_2_DistortionsMax3(t *testing.T) {
    // Given 4 distortion IDs, When creating record, Then validation error
    // Given 3 distortion IDs, When creating record, Then success
}

func TestCBTThought_AC3_3_DistortionIDsMustBeValid(t *testing.T) {
    // Given distortion ID "invalid_distortion", When creating record, Then validation error
    // Given distortion ID "entitlement", When creating record, Then success
}

func TestCBTThought_AC4_1_7ColumnRequiresEvidenceFields(t *testing.T) {
    // Given mode=7, When evidenceForText is nil, Then validation error
    // Given mode=7, When evidenceAgainstText is nil, Then validation error
}

func TestCBTThought_AC4_2_7ColumnOutcomeEmotionsMustMatchOriginal(t *testing.T) {
    // Given emotions=[anxious, ashamed], When outcomeEmotions has only [anxious], Then validation error
    // Given emotions=[anxious, ashamed], When outcomeEmotions=[anxious, ashamed], Then success
}

// --- Emotion Change Calculation ---

func TestCBTThought_AC4_3_EmotionChangeCalculation(t *testing.T) {
    // Given emotions=[{anxious, 80}, {ashamed, 70}], outcomeEmotions=[{anxious, 40}, {ashamed, 50}]
    // When calculating emotionChange, Then result = ((80-40)+(70-50))/2 = 30.0
}

func TestCBTThought_AC4_4_EmotionChangeNilFor3And5Column(t *testing.T) {
    // Given mode=3, When record is saved, Then emotionChange is nil
    // Given mode=5, When record is saved, Then emotionChange is nil
}

func TestCBTThought_AC4_5_EmotionChangeCanBeNegative(t *testing.T) {
    // Given emotions=[{anxious, 30}], outcomeEmotions=[{anxious, 60}]
    // When calculating, Then emotionChange = -30.0 (intensity increased)
}

// --- Level Progression ---

func TestCBTThought_AC5_1_NewUserStartsAt3Column(t *testing.T) {
    // Given no CBTProgress exists, When getting progress, Then unlockedLevel=3, preferredLevel=3
}

func TestCBTThought_AC5_2_5ColumnUnlocksAfter5Records(t *testing.T) {
    // Given totalRecordsCompleted=4, When 5th record saved, Then unlockedLevel updated to 5
    // Given totalRecordsCompleted=3, When checking, Then unlockedLevel remains 3
}

func TestCBTThought_AC5_3_7ColumnUnlocksAfter10Records(t *testing.T) {
    // Given totalRecordsCompleted=9, When 10th record saved, Then unlockedLevel updated to 7
}

func TestCBTThought_AC5_4_CannotCreateRecordAboveUnlockedLevel(t *testing.T) {
    // Given unlockedLevel=3, When creating mode=5 record, Then error "5-column mode not yet unlocked"
    // Given unlockedLevel=5, When creating mode=7 record, Then error "7-column mode not yet unlocked"
}

func TestCBTThought_AC5_5_UnlockLevelNeverDecreases(t *testing.T) {
    // Given unlockedLevel=7, When a record is deleted bringing total below 10, Then unlockedLevel remains 7
}

// --- Pattern Analysis ---

func TestCBTThought_AC8_1_DistortionFrequencyCalculation(t *testing.T) {
    // Given 10 records: 5 with entitlement, 3 with catastrophizing, 2 with emotional_reasoning
    // When calculating frequency, Then entitlement=5, catastrophizing=3, emotional_reasoning=2
    // Sorted descending by count
}

func TestCBTThought_AC8_2_EmotionTrendGroupedByWeek(t *testing.T) {
    // Given records across 3 weeks with varying emotion changes
    // When calculating trend, Then weekly averages are correctly computed
}

func TestCBTThought_AC8_3_PrivateRecordsExcludedFromSharedAnalytics(t *testing.T) {
    // Given 5 records, 2 marked isPrivate=true
    // When generating shared analytics, Then only 3 records contribute to frequency/trends
}

// --- Bookmark ---

func TestCBTThought_AC11_1_BookmarkBalancedThought(t *testing.T) {
    // Given a 5-column record with balancedThoughtText, When bookmarking, Then isBookmarked=true
}

func TestCBTThought_AC11_2_CannotBookmark3ColumnRecord(t *testing.T) {
    // Given a 3-column record (no balanced thought), When bookmarking, Then error
}
```

**Total Phase 2 tests: 23**

**Exit criteria:** All 23 unit tests written and FAIL (RED). Implement service methods to make them pass (GREEN). Refactor validation into a shared `validate()` method on ThoughtRecord.

---

## 5. Phase 3: MongoDB Repository + Integration Tests

### 5.1 Collection Schema

Collection: `cbtThoughtRecords`

```json
{
    "_id": "uuid",
    "userId": "uuid",
    "tenantId": "string",
    "date": "ISODate",
    "mode": 3,
    "situationText": "string",
    "thoughts": [{"id": "uuid", "text": "string", "isHotThought": false}],
    "emotions": [{"id": "uuid", "emotionType": "string", "intensity": 80}],
    "distortions": ["entitlement", "catastrophizing"],
    "evidenceForText": "string | null",
    "evidenceAgainstText": "string | null",
    "balancedThoughtText": "string | null",
    "outcomeEmotions": [{"id": "uuid", "emotionType": "string", "intensity": 45}],
    "isBookmarked": false,
    "isPrivate": false,
    "linkedUrgeLogId": "uuid | null",
    "linkedFasterEntryId": "uuid | null",
    "emotionChange": 30.0,
    "createdAt": "ISODate",
    "modifiedAt": "ISODate"
}
```

Collection: `cbtProgress`

```json
{
    "_id": "uuid",
    "userId": "uuid",
    "totalRecordsCompleted": 5,
    "unlockedLevel": 5,
    "preferredLevel": 5,
    "hasSeenPsychoeducation": true,
    "createdAt": "ISODate",
    "modifiedAt": "ISODate"
}
```

### 5.2 Indexes

```javascript
db.cbtThoughtRecords.createIndex({ "userId": 1, "date": -1 })
db.cbtThoughtRecords.createIndex({ "userId": 1, "isBookmarked": 1 }, { partialFilterExpression: { "isBookmarked": true } })
db.cbtThoughtRecords.createIndex({ "userId": 1, "distortions": 1 })
db.cbtProgress.createIndex({ "userId": 1 }, { unique: true })
```

### 5.3 Integration Tests (RED -> GREEN)

Create `api/test/integration/cbt_thought_repository_test.go`:

```go
func TestCBTThought_Repo_CreateAndGetRecord(t *testing.T) {
    // Create a 5-column thought record, retrieve by ID, verify all fields match
}

func TestCBTThought_Repo_ListRecordsPaginatedByDate(t *testing.T) {
    // Create 25 records across 5 days, list with limit=10
    // Verify cursor-based pagination returns correct pages ordered by date desc
}

func TestCBTThought_Repo_ListRecordsFilterByMode(t *testing.T) {
    // Create records in mode 3, 5, and 7, filter by mode=5
    // Verify only 5-column records returned
}

func TestCBTThought_Repo_UpdateRecord(t *testing.T) {
    // Create a draft record (3-col), update with balanced thought (upgrade to 5-col)
    // Verify modifiedAt updated, new fields persisted
}

func TestCBTThought_Repo_DeleteRecordPermanently(t *testing.T) {
    // Create record, delete, attempt get -- verify not found error
}

func TestCBTThought_Repo_UpsertProgress(t *testing.T) {
    // Create progress, upsert with new level -- verify updated
    // Upsert for non-existent user -- verify created
}

func TestCBTThought_Repo_DistortionFrequencyAggregation(t *testing.T) {
    // Create records with known distortions, run aggregation
    // Verify frequency counts match expected, sorted descending
}

func TestCBTThought_Repo_EmotionTrendAggregation(t *testing.T) {
    // Create 7-column records across 4 weeks with known emotion values
    // Verify weekly averages and record counts
}

func TestCBTThought_Repo_ListBookmarkedThoughts(t *testing.T) {
    // Create 5 records, bookmark 2, list bookmarked -- verify only 2 returned
}

func TestCBTThought_Repo_TenantIsolation(t *testing.T) {
    // Create records for tenant A and tenant B
    // Query as tenant A -- verify tenant B records not returned
}
```

**Total Phase 3 tests: 10**

**Exit criteria:** All 10 integration tests pass (GREEN) against a local MongoDB instance via `make local-up`.

---

## 6. Phase 4: Lambda Handler + API Tests

### 6.1 Handler Registration

Add routes to `cmd/local/main.go` and `cmd/lambda/activities/main.go`:

```
POST   /activities/cbt-thoughts                -> handleCreateThoughtRecord
GET    /activities/cbt-thoughts                -> handleListThoughtRecords
GET    /activities/cbt-thoughts/{recordId}     -> handleGetThoughtRecord
PUT    /activities/cbt-thoughts/{recordId}     -> handleUpdateThoughtRecord
DELETE /activities/cbt-thoughts/{recordId}     -> handleDeleteThoughtRecord
GET    /activities/cbt-thoughts/progress       -> handleGetCBTProgress
GET    /activities/cbt-thoughts/patterns       -> handleGetCBTPatterns
GET    /activities/cbt-thoughts/truth-library  -> handleListTruthLibrary
```

### 6.2 Handler Tests (RED -> GREEN)

Create `api/test/unit/cbt_thought_handler_test.go`:

```go
// --- Create ---

func TestCBTThought_Handler_CreateReturns201WithRecord(t *testing.T) {
    // POST valid 3-column body -> 201, response envelope { data: ThoughtRecord }
}

func TestCBTThought_Handler_CreateReturns400ForInvalidMode(t *testing.T) {
    // POST with mode=4 -> 400, error body with code rr:0x... and message
}

func TestCBTThought_Handler_CreateReturns400ForEmptySituation(t *testing.T) {
    // POST with empty situationText -> 400
}

func TestCBTThought_Handler_CreateReturns403ForLockedLevel(t *testing.T) {
    // POST mode=7 when unlockedLevel=5 -> 403
}

// --- Get ---

func TestCBTThought_Handler_GetReturns200WithRecord(t *testing.T) {
    // GET existing record -> 200, response envelope
}

func TestCBTThought_Handler_GetReturns404ForMissing(t *testing.T) {
    // GET non-existent record ID -> 404
}

// --- List ---

func TestCBTThought_Handler_ListReturns200WithPagination(t *testing.T) {
    // GET /cbt-thoughts?limit=5 -> 200, array with cursor in meta
}

func TestCBTThought_Handler_ListFiltersByMode(t *testing.T) {
    // GET /cbt-thoughts?mode=5 -> 200, only 5-column records
}

// --- Update ---

func TestCBTThought_Handler_UpdateReturns200(t *testing.T) {
    // PUT with updated balancedThoughtText -> 200, updated record
}

// --- Delete ---

func TestCBTThought_Handler_DeleteReturns204(t *testing.T) {
    // DELETE existing record -> 204, no body
}

func TestCBTThought_Handler_DeleteReturns404ForMissing(t *testing.T) {
    // DELETE non-existent -> 404
}

// --- Progress ---

func TestCBTThought_Handler_ProgressReturns200(t *testing.T) {
    // GET /progress -> 200, CBTProgress object
}

// --- Patterns ---

func TestCBTThought_Handler_PatternsReturns200(t *testing.T) {
    // GET /patterns?weeks=4 -> 200, CBTPatterns object
}

// --- Truth Library ---

func TestCBTThought_Handler_TruthLibraryReturns200(t *testing.T) {
    // GET /truth-library -> 200, array of bookmarked records
}
```

**Total Phase 4 tests: 14**

**Exit criteria:** All 14 handler tests pass (GREEN). Verify with `make test-unit`.

---

## 7. Phase 5: iOS Models + SwiftData

### 7.1 SwiftData Models

Add to `RRModels.swift`:

- `RRThoughtRecord` — `@Model` class matching the PRD data model (Section 6.2)
- `RRCBTProgress` — `@Model` class tracking level progression

Create `CBTThoughtTypes.swift`:

- `CognitiveDistortionType` enum — 14 cases with `displayName`, `definition`, `generalExample`, `addictionExample`, `counterQuestions`, `relatedScripture`, `icon`
- `EmotionType` enum — 15 core emotions with `displayName`, `color`, `icon`
- `ThoughtEntry` struct — Codable
- `EmotionRating` struct — Codable
- `ThoughtRecordMode` enum — `.threeColumn`, `.fiveColumn`, `.sevenColumn` with `columnCount: Int` and `stepTitles: [String]`

### 7.2 Unit Tests (RED -> GREEN)

Create `ios/RegalRecovery/RegalRecovery/Tests/Unit/CBTThoughtModelTests.swift`:

```swift
// --- Mode Tests ---

func testCBTThought_AC2_1_ThreeColumnModeHas3Steps() {
    // ThoughtRecordMode.threeColumn.columnCount == 3
    // stepTitles == ["Situation", "Automatic Thought", "Emotions"]
}

func testCBTThought_AC3_1_FiveColumnModeHas5Steps() {
    // ThoughtRecordMode.fiveColumn.columnCount == 5
    // stepTitles == ["Situation", "Automatic Thought", "Emotions", "Distortion", "Balanced Thought"]
}

func testCBTThought_AC4_1_SevenColumnModeHas7Steps() {
    // ThoughtRecordMode.sevenColumn.columnCount == 7
    // stepTitles includes Evidence For, Evidence Against, Outcome
}

// --- Emotion Change Calculation (mirrors Go tests) ---

func testCBTThought_AC4_3_EmotionChangeCalculation() {
    // Same test data as Go: emotions=[{anxious,80},{ashamed,70}], outcome=[{anxious,40},{ashamed,50}]
    // emotionChange == 30.0
}

func testCBTThought_AC4_4_EmotionChangeNilForNon7Column() {
    // 3-column record -> computedEmotionChange == nil
}

func testCBTThought_AC4_5_EmotionChangeCanBeNegative() {
    // emotions=[{anxious,30}], outcome=[{anxious,60}] -> emotionChange == -30.0
}

// --- Level Progression (mirrors Go tests) ---

func testCBTThought_AC5_1_DefaultProgressIs3Column() {
    // New RRCBTProgress -> unlockedLevel == 3, preferredLevel == 3
}

func testCBTThought_AC5_2_5ColumnUnlocksAt5Records() {
    // progress.totalRecordsCompleted = 5 -> computedUnlockedLevel == 5
}

func testCBTThought_AC5_3_7ColumnUnlocksAt10Records() {
    // progress.totalRecordsCompleted = 10 -> computedUnlockedLevel == 7
}

// --- Distortion Library ---

func testCBTThought_AC6_1_LibraryContains14Distortions() {
    // CognitiveDistortionType.allCases.count == 14
}

func testCBTThought_AC6_2_EachDistortionHasRequiredContent() {
    // For each distortion: displayName non-empty, definition non-empty,
    // generalExample non-empty, addictionExample non-empty,
    // counterQuestions.count >= 2, relatedScripture.count >= 2
}

func testCBTThought_AC6_3_EmotionTypeHas15CoreEmotions() {
    // EmotionType.allCases.count == 15
    // Includes: anxious, angry, ashamed, sad, lonely, bored, hopeless,
    //           worthless, disgusted, excited, guilty, jealous,
    //           frustrated, afraid, overwhelmed
}

// --- Validation ---

func testCBTThought_AC2_2_SituationTextMaxLength() {
    // String of 501 chars -> validation fails
}

func testCBTThought_AC2_4_MaxFiveThoughtEntries() {
    // Array of 6 ThoughtEntry -> validation fails
}

func testCBTThought_AC3_2_MaxThreeDistortions() {
    // Array of 4 distortion IDs -> validation fails
}

func testCBTThought_AC2_5_EmotionIntensityBounds() {
    // intensity = -1 -> invalid; intensity = 101 -> invalid
    // intensity = 0 -> valid; intensity = 100 -> valid
}
```

**Total Phase 5 tests: 16**

**Exit criteria:** All 16 tests pass (GREEN). Cross-platform consistency verified (Go and Swift tests use shared test fixtures from Appendix A).

---

## 8. Phase 6: iOS Views + ViewModel Tests (Guided Wizard)

### 8.1 ViewModel

Create `CBTThoughtWizardViewModel.swift`:

```swift
@Observable
final class CBTThoughtWizardViewModel {
    var mode: ThoughtRecordMode
    var currentStep: Int = 0
    var situationText: String = ""
    var thoughts: [ThoughtEntry] = []
    var emotions: [EmotionRating] = []
    var selectedDistortions: [CognitiveDistortionType] = []
    var evidenceForText: String = ""
    var evidenceAgainstText: String = ""
    var balancedThoughtText: String = ""
    var outcomeEmotions: [EmotionRating] = []
    var isPrivate: Bool = false
    var linkedUrgeLogId: UUID?
    var linkedFasterEntryId: UUID?

    var totalSteps: Int { mode.columnCount }
    var canAdvance: Bool { /* validation per step */ }
    var canSave: Bool { /* final step validation */ }
    var progressFraction: Double { Double(currentStep + 1) / Double(totalSteps) }
}
```

### 8.2 ViewModel Tests (RED -> GREEN)

Create `ios/RegalRecovery/RegalRecovery/Tests/Unit/CBTThoughtWizardViewModelTests.swift`:

```swift
// --- Wizard Navigation ---

func testCBTThought_Wizard_InitialStepIsZero() {
    // new wizard -> currentStep == 0
}

func testCBTThought_Wizard_AdvanceIncrements() {
    // advance() when canAdvance -> currentStep == 1
}

func testCBTThought_Wizard_CannotAdvancePastLastStep() {
    // 3-col at step 2 -> advance() does not increment
}

func testCBTThought_Wizard_GoBackDecrements() {
    // at step 2, goBack() -> currentStep == 1
}

func testCBTThought_Wizard_GoBackCannotGoBelowZero() {
    // at step 0, goBack() -> currentStep == 0
}

func testCBTThought_Wizard_ProgressFraction3Column() {
    // 3-col step 0 -> 1/3, step 1 -> 2/3, step 2 -> 3/3
}

func testCBTThought_Wizard_ProgressFraction7Column() {
    // 7-col step 3 -> 4/7
}

// --- Step Validation (canAdvance) ---

func testCBTThought_Wizard_CannotAdvanceWithEmptySituation() {
    // step 0, situationText empty -> canAdvance == false
}

func testCBTThought_Wizard_CanAdvanceWithSituation() {
    // step 0, situationText = "At work..." -> canAdvance == true
}

func testCBTThought_Wizard_CannotAdvanceWithNoThoughts() {
    // step 1, thoughts empty -> canAdvance == false
}

func testCBTThought_Wizard_CannotAdvanceWithNoEmotions() {
    // step 2, emotions empty -> canAdvance == false
}

func testCBTThought_Wizard_5ColCannotAdvanceWithNoDistortions() {
    // 5-col step 3, selectedDistortions empty -> canAdvance == false
}

// --- Data Preservation ---

func testCBTThought_Wizard_DataPreservedOnNavigateBack() {
    // Enter situation, advance, advance to emotions, go back twice
    // situationText still contains original text
}

// --- Save ---

func testCBTThought_Wizard_CanSaveOnlyOnFinalStep() {
    // 3-col step 1 -> canSave == false
    // 3-col step 2 with emotions -> canSave == true
}

func testCBTThought_Wizard_SaveCreatesRecord() {
    // Fill all 3-col fields, save() -> RRThoughtRecord created in modelContext
}

func testCBTThought_Wizard_SaveUpdatesProgress() {
    // save() increments totalRecordsCompleted on RRCBTProgress
}

func testCBTThought_Wizard_SaveTriggersLevelUnlock() {
    // totalRecordsCompleted goes from 4 to 5 -> unlockedLevel updated to 5
}

// --- Linked Entry ---

func testCBTThought_Wizard_LinkedUrgeLogPrePopulatesSituation() {
    // init with linkedUrgeLogId, situation pre-populated from urge context
}

func testCBTThought_Wizard_LinkedFASTEREntryPrePopulatesSituation() {
    // init with linkedFasterEntryId, situation prompt includes FASTER context
}

// --- Scripture Suggestions ---

func testCBTThought_Wizard_ScriptureSuggestionsMatchDistortion() {
    // selected distortion = .catastrophizing
    // scriptureSuggestions contains "Matthew 19:26" and "Philippians 4:13"
}
```

**Total Phase 6 tests: 20**

### 8.3 Views

Implement the wizard views listed in the architecture overview. Key interaction patterns:

- `CBTThoughtWizardView` — container with step navigation, progress bar, next/back buttons
- Each step view receives bindings from the ViewModel
- Emotion picker uses the `EmotionType` grid with intensity sliders (reuse pattern from mood rating)
- Distortion picker shows 14 cards with multi-select (max 3)
- Scripture chip view for balanced thought step

**Exit criteria:** All 20 ViewModel tests pass (GREEN). Wizard flow works end-to-end in Xcode preview.

---

## 9. Phase 7: Cognitive Distortion Library + Pattern Analysis

### 9.1 Distortion Library Data

Create `CognitiveDistortionLibrary.swift` with all 14 distortions. Each includes:

| Distortion | Addiction-Specific Example | Key Counter-Question | Scripture |
|---|---|---|---|
| All-or-Nothing | "I already looked, so I might as well go all the way" | "Is there really no middle ground?" | James 3:2 |
| Overgeneralization | "I always fail at this; I'll never get sober" | "Is 'always' really true?" | Lamentations 3:22-23 |
| Mental Filter | Focusing only on the one bad day in a 30-day streak | "What am I choosing not to see?" | Philippians 4:8 |
| Disqualifying Positive | "My 90-day streak doesn't count because I still have urges" | "Would you dismiss someone else's progress?" | 1 Corinthians 15:58 |
| Mind Reading | "My wife thinks I'm disgusting" | "Do I actually know what they're thinking?" | 1 Samuel 16:7 |
| Fortune Telling | "I'll never be able to have a healthy relationship" | "Can I really predict the future?" | Jeremiah 29:11 |
| Catastrophizing | "If anyone finds out, my life is over" | "What's the most likely outcome?" | Romans 8:28 |
| Magnification/Minimization | Magnifying relapse, minimizing 6 months of sobriety | "Am I keeping this in proportion?" | 2 Corinthians 4:17 |
| Emotional Reasoning | "I feel like a failure, so I must be one" | "Are feelings the same as facts?" | Proverbs 3:5 |
| Should Statements | "I should be over this by now" | "Says who? What's the actual timeline?" | Ecclesiastes 3:1 |
| Labeling | "I'm an addict, that's all I'll ever be" | "Am I more than this one label?" | 2 Corinthians 5:17 |
| Personalization | "My marriage problems are entirely my fault" | "Am I taking responsibility for things outside my control?" | Galatians 6:5 |
| Blaming | "She drove me to this" | "What part of this is within my control?" | Romans 14:12 |
| Entitlement | "I work hard, I deserve this release" | "Does my effort entitle me to harm myself?" | 1 Corinthians 6:12 |

### 9.2 Pattern Analysis Tests (RED -> GREEN)

Create `ios/RegalRecovery/RegalRecovery/Tests/Unit/CBTPatternViewModelTests.swift`:

```swift
// --- Distortion Frequency ---

func testCBTThought_Pattern_DistortionFrequencySortedDescending() {
    // Given records with entitlement(5), catastrophizing(3), labeling(1)
    // When computing frequency, Then order is entitlement, catastrophizing, labeling
}

func testCBTThought_Pattern_DistortionFrequencyExcludesPrivateRecords() {
    // Given 3 public records + 2 private records with entitlement
    // When computing shared frequency, Then entitlement count = 3 (not 5)
}

func testCBTThought_Pattern_3ColumnRecordsExcludedFromDistortionFrequency() {
    // Given 5 three-column records (no distortions), When computing frequency, Then empty
}

// --- Emotion Trend ---

func testCBTThought_Pattern_EmotionTrendWeeklyAverages() {
    // Given week 1: records with emotionChange [20, 30], week 2: [40, 50]
    // When computing trend, Then week1 avg=25, week2 avg=45
}

func testCBTThought_Pattern_EmotionTrendRequires7ColumnRecords() {
    // Given mix of 3-col and 7-col records, When computing trend, Then only 7-col contribute
}

func testCBTThought_Pattern_EmotionTrendEmptyForLessThan5Records() {
    // Given 3 records, When checking analytics availability, Then emotion trend unavailable
}

// --- Analytics Availability ---

func testCBTThought_Pattern_DistortionChartAvailableAfter10Records() {
    // Given 9 records with distortions, Then distortionChartAvailable == false
    // Given 10 records with distortions, Then distortionChartAvailable == true
}

func testCBTThought_Pattern_PlaceholderMessageWhenInsufficient() {
    // Given 3 records, When viewing analytics, Then placeholder text shown
}

// --- Truth Library ---

func testCBTThought_TruthLibrary_GroupedByDistortion() {
    // Given 3 bookmarked records: 2 with entitlement, 1 with catastrophizing
    // When listing, Then grouped: entitlement(2), catastrophizing(1)
}

func testCBTThought_TruthLibrary_OnlyBookmarkedRecordsIncluded() {
    // Given 5 records, 2 bookmarked, When listing truth library, Then 2 returned
}

func testCBTThought_TruthLibrary_InsertFromLibraryIntoWizard() {
    // Given a bookmarked balanced thought for entitlement
    // When user selects it in wizard, Then balancedThoughtText pre-populated
}

func testCBTThought_TruthLibrary_EmptyLibraryShowsEncouragement() {
    // Given 0 bookmarks, When viewing truth library, Then placeholder with encouragement text
}
```

**Total Phase 7 tests: 12**

**Exit criteria:** All 12 tests pass (GREEN). Library data verified complete for all 14 distortions.

---

## 10. Phase 8: Integration with Urge Log, FASTER Scale, Post-Mortem

### 8.1 Urge Log Integration Tests

```swift
func testCBTThought_Integration_UrgeLogPromptAfterSave() {
    // Given user saves an urge log, When completion appears
    // Then "Examine the thoughts behind this urge?" prompt is shown
}

func testCBTThought_Integration_UrgeLogLinkedToThoughtRecord() {
    // Given user taps "Yes" on urge prompt, When wizard opens
    // Then linkedUrgeLogId is set and situationText is pre-populated
}

func testCBTThought_Integration_UrgeLogLinkVisibleInHistory() {
    // Given a thought record linked to an urge log
    // When viewing in history, Then urge link icon is visible and tappable
}
```

### 8.2 FASTER Scale Integration Tests

```swift
func testCBTThought_Integration_FASTERSuggestsThoughtRecordAtElevatedStages() {
    // Given FASTER check-in result is "Angry", "Stressed", or "Tempted"
    // Then suggestion banner appears for thought record
}

func testCBTThought_Integration_FASTERNoSuggestionAtLowStages() {
    // Given FASTER check-in result is "Forgetting"
    // Then no thought record suggestion appears
}

func testCBTThought_Integration_FASTERLinkedToThoughtRecord() {
    // Given user taps FASTER suggestion, When wizard opens
    // Then linkedFasterEntryId is set
}
```

### 8.3 Today View Integration Tests

```swift
func testCBTThought_Integration_CompletedRecordAppearsInTodayLog() {
    // Given user completes a thought record today
    // When Today view refreshes, Then activity log shows "Thought Record" entry
}

func testCBTThought_Integration_TodayLogShowsDistortionAndEmotionChange() {
    // Given a 7-column record with entitlement distortion and 30% reduction
    // When shown in Today log, Then displays "Entitlement -- 30% reduction"
}
```

### 8.4 Post-Mortem Integration Tests

```swift
func testCBTThought_Integration_PostMortemShowsLinkedThoughtRecords() {
    // Given a post-mortem for today, and 2 thought records created today
    // When viewing the timeline section, Then both records appear as linkable entries
}
```

**Total Phase 8 tests: 9**

**Exit criteria:** All 9 integration tests pass (GREEN). Cross-feature navigation works correctly.

---

## 11. Phase 9: Feature Flag Wiring

### 9.1 Flag Registration

Add `activity.cbt-thoughts` to the feature flag seed data in:
- `FeatureFlagStore.swift` (iOS default flags)
- `api/scripts/seed-flags.js` (backend seed)

### 9.2 Gating Tests

```swift
// iOS
func testCBTThought_Flag_FeatureHiddenWhenDisabled() {
    // Given activity.cbt-thoughts is disabled
    // When rendering activity destinations, Then CBT Thoughts is not visible
}

func testCBTThought_Flag_FeatureVisibleWhenEnabled() {
    // Given activity.cbt-thoughts is enabled
    // When rendering activity destinations, Then CBT Thoughts is visible
}
```

```go
// Go
func TestCBTThought_Flag_EndpointReturns404WhenDisabled(t *testing.T) {
    // Given activity.cbt-thoughts is disabled
    // When POST /activities/cbt-thoughts, Then 404
}

func TestCBTThought_Flag_EndpointReturns201WhenEnabled(t *testing.T) {
    // Given activity.cbt-thoughts is enabled
    // When POST /activities/cbt-thoughts with valid body, Then 201
}
```

**Total Phase 9 tests: 4**

**Exit criteria:** Feature fully gated behind flag. Disabled by default. Enabled via DebugFlagsView for testing.

---

## 12. Test Naming Convention

All tests follow the pattern:

```
TestCBTThought_{Category}_{Description}           (Go)
testCBTThought_{Category}_{Description}            (Swift)
```

Where category maps to acceptance criteria or functional area:

| Category | Area |
|---|---|
| `AC2_*` | 3-column entry (Story 2) |
| `AC3_*` | 5-column entry (Story 3) |
| `AC4_*` | 7-column entry (Story 4) |
| `AC5_*` | Progressive level system (Story 5) |
| `AC6_*` | Distortion library (Story 6) |
| `AC7_*` | History (Story 7) |
| `AC8_*` | Pattern analytics (Story 8) |
| `AC9_*` | Urge log integration (Story 9) |
| `AC10_*` | FASTER integration (Story 10) |
| `AC11_*` | Truth library / bookmarks (Story 11) |
| `Contract_*` | OpenAPI contract validation |
| `Repo_*` | MongoDB repository |
| `Handler_*` | HTTP handler |
| `Wizard_*` | Wizard ViewModel |
| `Pattern_*` | Pattern analysis |
| `Integration_*` | Cross-feature integration |
| `Flag_*` | Feature flag gating |

---

## 13. Verification Checklist

### Per-Phase Gates

| Phase | Gate | Command |
|---|---|---|
| 1 | Contract tests exist and FAIL | `go test ./test/unit/... -run TestCBTThought_Contract -v` |
| 2 | Service unit tests PASS | `go test ./test/unit/... -run TestCBTThought_AC -v` |
| 3 | Integration tests PASS | `make local-up && go test ./test/integration/... -run TestCBTThought_Repo -v` |
| 4 | Handler tests PASS | `go test ./test/unit/... -run TestCBTThought_Handler -v` |
| 5 | iOS model tests PASS | Xcode: Test Navigator -> CBTThoughtModelTests |
| 6 | iOS ViewModel tests PASS | Xcode: Test Navigator -> CBTThoughtWizardViewModelTests |
| 7 | Pattern tests PASS | Xcode: Test Navigator -> CBTPatternViewModelTests |
| 8 | Integration tests PASS | Xcode: Test Navigator -> Integration tests |
| 9 | Flag tests PASS | Both Go and Swift flag tests |

### Final Verification

- [ ] `make spec-validate` passes
- [ ] `make contract-test` passes
- [ ] `make test-unit` passes (all Go tests)
- [ ] `make test-integration` passes
- [ ] Xcode test suite passes (all Swift tests)
- [ ] `make coverage-check` passes (>= 80%, 100% for emotion change calculation and level progression)
- [ ] Feature flag `activity.cbt-thoughts` gates all entry points
- [ ] Wizard flow tested manually in Xcode simulator (3-col, 5-col, 7-col)
- [ ] Level progression tested manually (create 10 records, verify unlocks)
- [ ] Urge log -> thought record link tested manually
- [ ] FASTER Scale -> thought record suggestion tested manually

---

## Appendix A: Shared Test Fixtures

These values must produce identical results in Go and Swift test suites:

### Emotion Change Calculation

| Test Case | Before Emotions | After Emotions | Expected Change |
|---|---|---|---|
| Standard reduction | [{anxious, 80}, {ashamed, 70}] | [{anxious, 40}, {ashamed, 50}] | 30.0 |
| No change | [{sad, 50}] | [{sad, 50}] | 0.0 |
| Increase (negative) | [{anxious, 30}] | [{anxious, 60}] | -30.0 |
| Full reduction | [{guilty, 100}] | [{guilty, 0}] | 100.0 |
| Mixed | [{angry, 90}, {ashamed, 40}, {afraid, 70}] | [{angry, 30}, {ashamed, 35}, {afraid, 20}] | 38.33 |

### Level Progression

| Total Records | Expected Unlocked Level |
|---|---|
| 0 | 3 |
| 1 | 3 |
| 4 | 3 |
| 5 | 5 |
| 9 | 5 |
| 10 | 7 |
| 50 | 7 |

### Distortion Frequency

| Records | Expected Top 3 |
|---|---|
| 5x entitlement, 3x catastrophizing, 2x emotional_reasoning, 1x labeling | entitlement(5), catastrophizing(3), emotional_reasoning(2) |

---

## Test Count Summary

| Phase | Test Count |
|---|---|
| Phase 1: Contract Tests | 8 |
| Phase 2: Service Unit Tests | 23 |
| Phase 3: Repository Integration Tests | 10 |
| Phase 4: Handler Tests | 14 |
| Phase 5: iOS Model Tests | 16 |
| Phase 6: iOS ViewModel Tests | 20 |
| Phase 7: Pattern + Library Tests | 12 |
| Phase 8: Integration Tests | 9 |
| Phase 9: Feature Flag Tests | 4 |
| **Total** | **116** |
