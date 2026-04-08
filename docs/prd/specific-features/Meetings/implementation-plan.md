# Meetings Attended -- Multi-Agent Implementation Plan

**Feature:** Meetings Attended Activity
**Priority:** P1 (Wave 2)
**Feature Flag:** `activity.meetings`
**Build Order:** Wave 2 (requires Wave 0 foundation + Wave 1 tracking system)

---

## Prerequisites

Before starting this implementation, the following Wave 0/1 deliverables must be complete:

- [ ] MongoDB single-table with PK/SK compound index
- [ ] Calendar activity dual-write infrastructure (`calendarActivities` pattern)
- [ ] Feature flag system (`GET /flags`, Valkey cache, evaluator)
- [ ] Auth middleware (Cognito JWT validation, userId extraction)
- [ ] Tenant isolation middleware
- [ ] Correlation ID middleware
- [ ] Permission checking domain logic (`internal/domain/permissions/`)
- [ ] Commitment tracking system (event-driven progress updates)
- [ ] Notification system (SNS/SQS event publishing)
- [ ] Contract test framework (`make contract-test`)
- [ ] Offline sync infrastructure (client-side queue, union merge resolver)

---

## Phase 1: Specification Validation

**Agent:** Spec Validator
**Duration:** 0.5 day
**Dependencies:** None (specs already written)

### Tasks

1. Validate OpenAPI spec with Redocly
   ```bash
   redocly lint docs/prd/specific-features/Meetings/specs/openapi.yaml --strict
   ```
2. Verify all schema references resolve correctly
3. Verify the spec aligns with Siemens REST API Guidelines v2.5.1 (camelCase properties, kebab-case URLs, error envelope, cursor pagination)
4. Verify meeting types exclude SAA (only SA and CR for 12-step)
5. Cross-reference acceptance criteria IDs against test specifications to confirm full coverage

### Gate
- [ ] OpenAPI spec passes `redocly lint --strict` with 0 errors
- [ ] Every acceptance criterion in `acceptance-criteria.md` has at least one test in `test-specifications.md`

---

## Phase 2: Contract Tests (RED)

**Agent:** Contract Test Agent
**Duration:** 1 day
**Dependencies:** Phase 1 complete

### Tasks

1. Generate Go server interfaces from the meetings OpenAPI spec using `oapi-codegen`
   ```bash
   oapi-codegen -package meetings -generate types,chi-server \
     -o internal/api/meetings/types.go \
     docs/prd/specific-features/Meetings/specs/openapi.yaml
   ```

2. Write contract tests that validate request/response shapes against the OpenAPI schema:
   - `test/contract/meetings_test.go`
   - Test every endpoint: POST, GET (list), GET (by ID), PATCH, DELETE for meeting logs
   - Test every endpoint: POST, GET (list), GET (by ID), PATCH, DELETE for saved meetings
   - Test attendance summary endpoint
   - Test all error response shapes match Siemens error format

3. Write acceptance criterion unit tests (RED -- all failing):
   - `internal/domain/meetings/meeting_log_test.go` -- all FR-MTG-1.x tests
   - `internal/domain/meetings/saved_meeting_test.go` -- all FR-MTG-2.x tests
   - `internal/domain/meetings/summary_test.go` -- all FR-MTG-3.5 tests
   - `internal/domain/meetings/validation_test.go` -- field validation, immutability

4. Run tests to confirm they all fail (RED state)
   ```bash
   make test-unit  # All meeting tests FAIL
   ```

### Gate
- [ ] All contract tests written and failing
- [ ] All unit tests written and failing
- [ ] Test names reference acceptance criteria (FR-MTG-x.x format)
- [ ] Zero implementation code exists yet

---

## Phase 3: Domain Logic (GREEN)

**Agent:** Domain Logic Agent
**Duration:** 2 days
**Dependencies:** Phase 2 complete

### Tasks

1. Implement domain types in `internal/domain/meetings/types.go`:
   - `MeetingLog` struct
   - `SavedMeeting` struct
   - `MeetingType` enum with validation (SA, CR, AA, therapy, group-counseling, church, custom)
   - `MeetingStatus` enum (attended, canceled)
   - `AttendanceSummary` struct

2. Implement domain logic in `internal/domain/meetings/`:
   - `meeting_log.go` -- Create, Update (with timestamp immutability), Validate
   - `saved_meeting.go` -- Create, Update, SoftDelete, PreFill (template to log)
   - `summary.go` -- CalculateSummary (aggregation by type, period date range)
   - `validation.go` -- All field validation rules

3. Implement domain interfaces:
   - `MeetingRepository` interface (for repository layer to implement)
   - `SavedMeetingRepository` interface
   - `EventPublisher` interface (for commitment tracking events)

4. Run unit tests until GREEN:
   ```bash
   make test-unit  # All meeting domain tests PASS
   ```

### Gate
- [ ] All FR-MTG-1.x unit tests pass (meeting log creation, validation, immutability)
- [ ] All FR-MTG-2.x unit tests pass (saved meetings CRUD, pre-fill)
- [ ] All FR-MTG-3.5 unit tests pass (attendance summary)
- [ ] All FR-MTG-4.x unit tests pass (update, cancel, delete)
- [ ] All permission check unit tests pass (FR-MTG-5.3)
- [ ] All feature flag gating tests pass (NFR-MTG-5)
- [ ] Coverage >= 90% on `internal/domain/meetings/`
- [ ] 100% branch coverage on timestamp immutability
- [ ] 100% branch coverage on permission checks

---

## Phase 4: Repository Layer

**Agent:** Repository Agent
**Duration:** 1.5 days
**Dependencies:** Phase 3 complete
**Parallel with:** Phase 5 (handler layer can start once domain interfaces are defined)

### Tasks

1. Implement MongoDB repository in `internal/repository/meetings/`:
   - `meeting_repository.go` -- implements `MeetingRepository` interface
     - Create (with calendar activity dual-write)
     - GetByID
     - ListByUser (with cursor pagination, date range filter, type filter)
     - Update
     - Delete (both meeting and calendar activity)
   - `saved_meeting_repository.go` -- implements `SavedMeetingRepository` interface
     - Create
     - GetByID
     - ListActive (sorted by name)
     - Update
     - SoftDelete

2. Implement event publisher in `internal/events/meetings/`:
   - `publisher.go` -- publishes meeting-created events to SQS for commitment tracking

3. Write integration tests in `test/integration/meetings/`:
   - All repository integration tests from test-specifications.md section 2.1
   - All event publishing tests from section 2.3

4. Run integration tests against local MongoDB:
   ```bash
   make local-up
   make test-integration  # Meeting integration tests PASS
   ```

### Gate
- [ ] All repository integration tests pass against local MongoDB
- [ ] Calendar dual-write creates/deletes correctly
- [ ] Cursor pagination works with limit and nextCursor
- [ ] Date range and type filters produce correct results
- [ ] Event publishing integration tests pass
- [ ] Soft-delete on saved meetings preserves document with isActive=false

---

## Phase 5: Handler Layer

**Agent:** Handler Agent
**Duration:** 1.5 days
**Dependencies:** Phase 3 complete (domain interfaces), Phase 4 in progress or complete
**Parallel with:** Phase 4 (can use mocked repository)

### Tasks

1. Implement HTTP handlers in `internal/handler/meetings/`:
   - `meeting_handler.go`
     - `POST /v1/activities/meetings` -- create meeting log
     - `GET /v1/activities/meetings` -- list with filters and pagination
     - `GET /v1/activities/meetings/{meetingId}` -- get by ID
     - `PATCH /v1/activities/meetings/{meetingId}` -- update
     - `DELETE /v1/activities/meetings/{meetingId}` -- delete
   - `saved_meeting_handler.go`
     - `POST /v1/activities/meetings/saved` -- create saved meeting
     - `GET /v1/activities/meetings/saved` -- list saved meetings
     - `GET /v1/activities/meetings/saved/{savedMeetingId}` -- get by ID
     - `PATCH /v1/activities/meetings/saved/{savedMeetingId}` -- update
     - `DELETE /v1/activities/meetings/saved/{savedMeetingId}` -- soft delete
   - `summary_handler.go`
     - `GET /v1/activities/meetings/summary` -- attendance summary

2. Wire middleware:
   - Feature flag check (`activity.meetings`) -- returns 404 if disabled
   - Auth (Cognito JWT)
   - Tenant isolation
   - Correlation ID
   - Permission check for support network access

3. Write handler integration tests from test-specifications.md section 2.2

4. Run all handler tests:
   ```bash
   make test-integration  # Handler tests PASS
   ```

### Gate
- [ ] All HTTP handler tests pass
- [ ] All response shapes match OpenAPI spec (validated by contract tests)
- [ ] Location header set on 201 responses
- [ ] Error responses follow Siemens format with correlation IDs
- [ ] Feature flag middleware returns 404 when flag disabled
- [ ] Permission middleware returns 404 for unauthorized support contacts
- [ ] Timestamp immutability enforced at handler level (422 on PATCH with timestamp)

---

## Phase 6: Contract Validation (GREEN)

**Agent:** Contract Test Agent (same as Phase 2)
**Duration:** 0.5 day
**Dependencies:** Phases 4 and 5 complete

### Tasks

1. Run full contract test suite against the running API:
   ```bash
   make contract-test  # All meeting contract tests PASS
   ```

2. Run Schemathesis property-based testing:
   ```bash
   schemathesis run docs/prd/specific-features/Meetings/specs/openapi.yaml \
     --base-url http://localhost:8080/v1 \
     --checks all \
     --hypothesis-max-examples=200
   ```

3. Verify all acceptance criteria from `acceptance-criteria.md` are covered by passing tests

### Gate
- [ ] All contract tests pass (implementation matches spec)
- [ ] Schemathesis finds no violations
- [ ] Every FR-MTG and NFR-MTG criterion has at least one passing test

---

## Phase 7: Mobile API Clients

**Agent:** Mobile Client Agent (split into iOS and Android sub-agents)
**Duration:** 1.5 days (parallel iOS + Android)
**Dependencies:** Phase 6 complete (stable API contract)

### 7a: Android (Kotlin)

**Sub-Agent:** Android Client Agent

1. Hand-write Kotlin API client in `androidApp/.../data/api/MeetingsApi.kt`:
   - Request/response data classes matching OpenAPI schemas
   - Retrofit interface for all meeting endpoints
   - Offline queue support (enqueue meeting logs when offline)

2. Write client contract tests:
   - Validate serialization/deserialization matches OpenAPI types
   - Validate offline queue syncs in chronological order

3. Write UI tests for meeting logging screen:
   - Quick-log from saved meeting (one-tap)
   - Meeting type selection
   - Notes entry

### 7b: iOS (Swift)

**Sub-Agent:** iOS Client Agent

1. Hand-write Swift API client in `iosApp/.../Data/API/MeetingsAPI.swift`:
   - Codable structs matching OpenAPI schemas
   - URLSession-based client for all meeting endpoints
   - Offline queue support

2. Write client contract tests:
   - Validate encoding/decoding matches OpenAPI types
   - Validate offline queue syncs in chronological order

3. Write SwiftUI tests for meeting logging screen:
   - Quick-log from saved meeting (one-tap)
   - Meeting type selection
   - Notes entry

### Gate
- [ ] Android contract tests pass
- [ ] iOS contract tests pass
- [ ] Offline queue tests pass on both platforms
- [ ] UI tests pass on both platforms

---

## Phase 8: End-to-End Tests

**Agent:** E2E Test Agent
**Duration:** 1 day
**Dependencies:** Phase 7 complete

### Tasks

1. Write E2E tests from test-specifications.md section 3:
   - Full user flow: create saved meeting, log from template, view history, check summary
   - Sponsor permission flow (with and without permission)
   - Calendar integration verification
   - Canceled meeting and commitment streak interaction

2. Deploy to staging:
   ```bash
   make deploy-staging
   ```

3. Run E2E tests against staging:
   ```bash
   make test-e2e  # Meeting E2E tests PASS
   ```

### Gate
- [ ] All E2E tests pass on staging
- [ ] Calendar view shows meetings alongside other activities
- [ ] Permission model (opt-in, 404 for denied) works end-to-end
- [ ] Feature flag kill switch works (disable flag, verify 404)

---

## Phase 9: Notification Integration

**Agent:** Notifications Agent
**Duration:** 0.5 day
**Dependencies:** Phase 5 complete (handlers wired), notifications system from Wave 1

### Tasks

1. Implement pre-meeting reminder scheduling:
   - When a saved meeting with `reminderMinutesBefore` is created/updated, schedule a notification
   - SNS topic: `meeting-reminders`

2. Implement post-meeting logging prompt:
   - Scheduled check 1 hour after saved meeting end time
   - If no meeting logged for that day matching the saved meeting type, send prompt
   - "You had a meeting scheduled today. Would you like to log it?"

3. Write integration tests for notification scheduling and delivery

### Gate
- [ ] Pre-meeting reminders fire at configured time
- [ ] Post-meeting prompt fires only if meeting not already logged
- [ ] Notification preferences respected (user can disable)

---

## Agent Dependency Graph

```
Phase 1: Spec Validator
    |
    v
Phase 2: Contract Test Agent (RED)
    |
    v
Phase 3: Domain Logic Agent (GREEN)
    |
    +-----------+------------+
    |                        |
    v                        v
Phase 4: Repository Agent   Phase 5: Handler Agent
    |                        |
    +----------+-------------+
               |
               v
Phase 6: Contract Test Agent (validate)
               |
    +----------+----------+----------+
    |                     |          |
    v                     v          v
Phase 7a: Android Agent  Phase 7b: iOS Agent   Phase 9: Notifications Agent
    |                     |
    +----------+----------+
               |
               v
Phase 8: E2E Test Agent
```

---

## Verification Gates Summary

| Gate | Criteria | Blocking |
|------|----------|----------|
| G1 - Spec Valid | `redocly lint` passes, AC coverage complete | Blocks Phase 2 |
| G2 - Tests RED | All tests written and failing, zero implementation | Blocks Phase 3 |
| G3 - Domain GREEN | All unit tests pass, 90%+ coverage, 100% on critical paths | Blocks Phases 4, 5 |
| G4 - Repository GREEN | All integration tests pass against local MongoDB | Blocks Phase 6 |
| G5 - Handler GREEN | All HTTP tests pass, contract-compliant responses | Blocks Phase 6 |
| G6 - Contract GREEN | Full contract suite passes, schemathesis clean | Blocks Phases 7, 8 |
| G7 - Mobile GREEN | Android + iOS client tests pass, offline queue works | Blocks Phase 8 |
| G8 - E2E GREEN | All E2E tests pass on staging | Blocks PR merge |
| G9 - Notifications | Reminder and prompt notifications working | Non-blocking for merge |

---

## PR Strategy

Target PR size: <400 lines each. Split into stacked PRs:

| PR | Contents | Review Focus |
|----|----------|-------------|
| PR 1 | OpenAPI spec + acceptance criteria + test specs | Spec correctness, AC completeness |
| PR 2 | Generated types + contract tests (RED) + domain unit tests (RED) | Test quality, AC coverage |
| PR 3 | Domain logic (types, validation, summary) | Business rules, immutability, meeting type validation |
| PR 4 | Repository layer + integration tests | MongoDB patterns, dual-write, pagination |
| PR 5 | Handler layer + handler tests | HTTP compliance, middleware wiring, error responses |
| PR 6 | Contract validation + property tests | Spec conformance |
| PR 7a | Android API client + tests | Kotlin types, offline queue |
| PR 7b | iOS API client + tests | Swift types, offline queue |
| PR 8 | E2E tests | Full flow coverage |
| PR 9 | Notification scheduling | Reminder and prompt logic |

---

## Feature Flag Configuration

```json
{
  "PK": "FLAGS",
  "SK": "activity.meetings",
  "EntityType": "FEATURE_FLAG",
  "TenantId": "SYSTEM",
  "enabled": true,
  "rolloutPercentage": 0,
  "tiers": ["*"],
  "tenants": ["*"],
  "platforms": ["ios", "android"],
  "minAppVersion": "1.2.0",
  "description": "Meeting attendance logging with saved templates and attendance history"
}
```

Initial rollout: 0% (flag created but disabled). Incremental rollout: 10% -> 25% -> 50% -> 100% after E2E validation on staging.

---

## Estimated Total Duration

| Phase | Duration | Parallelism |
|-------|----------|-------------|
| Phase 1: Spec Validation | 0.5 day | -- |
| Phase 2: Contract Tests (RED) | 1 day | -- |
| Phase 3: Domain Logic (GREEN) | 2 days | -- |
| Phase 4: Repository | 1.5 days | Parallel with Phase 5 |
| Phase 5: Handler | 1.5 days | Parallel with Phase 4 |
| Phase 6: Contract Validation | 0.5 day | -- |
| Phase 7: Mobile Clients | 1.5 days | iOS + Android parallel |
| Phase 8: E2E Tests | 1 day | -- |
| Phase 9: Notifications | 0.5 day | Parallel with Phase 8 |

**Critical path:** Phases 1-2-3-4/5-6-7-8 = ~8 days
**With parallelism:** ~7 working days
