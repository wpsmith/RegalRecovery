# Post-Mortem Analysis -- Multi-Agent Implementation Plan

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft

---

## Overview

This plan follows the project's spec-driven, test-first development approach. Each wave produces working, tested code that can be merged independently. Agents work in parallel where dependencies allow.

**Build order context:** Post-Mortem Analysis is a **Wave 2 (P1)** activity per `SPEC-PLAN.md`. It depends on Wave 0 (foundation) and Wave 1 core features (tracking, relapse logging, commitments, FASTER Scale).

**Feature flag:** `activity.post-mortem`

---

## Prerequisites (Must Exist Before Starting)

| Dependency | Source | Status Check |
|-----------|--------|-------------|
| MongoDB collections + indexes | Wave 0 | `postMortems` collection exists |
| Feature flag system | Wave 0 | `activity.post-mortem` flag evaluable |
| Auth + JWT middleware | Wave 0 | Bearer token validation works |
| Tenant isolation middleware | Wave 0 | TenantId enforced on all queries |
| Relapse logging API | Wave 1 | `POST /tracking/relapses` functional |
| Commitments API | Wave 1 | `POST /activities/commitments` functional |
| Goals API | Wave 2 | `POST /activities/goals` functional |
| FASTER Scale API | Wave 1 | FASTER entries readable for auto-population |
| Calendar activity dual-write | Wave 1 | `calendarActivities` collection pattern established |
| Permission system | Wave 1 | Contact permissions checkable |
| Contract test framework | Wave 0 | `make contract-test` infrastructure exists |

---

## Agent Assignments

### Agent A: Spec Validation and Contract Tests (RED)

**Role:** Write failing contract tests that validate the implementation conforms to the OpenAPI spec. This agent runs FIRST -- all other agents depend on its output.

**Artifacts:**
- `test/contract/post_mortem_contract_test.go` -- Contract tests validating Go types match OpenAPI schemas
- `internal/api/postmortem/types.go` -- Generated Go types from OpenAPI spec (via oapi-codegen)
- `internal/api/postmortem/server.go` -- Generated server interface

**Steps:**
1. Validate `docs/prd/specific-features/PostMortem/specs/openapi.yaml` with `redocly lint`
2. Generate Go types and server interface from the OpenAPI spec
3. Write contract tests for all request/response schemas:
   - `CreatePostMortemRequest` matches spec
   - `PostMortemResponse` matches spec (envelope: `data`, `links`, `meta`)
   - `PostMortemDetailResponse` matches spec
   - `PostMortemInsightsResponse` matches spec
   - Error responses match Siemens error envelope format
   - Pagination response matches cursor-based pagination schema
4. Write contract tests for all endpoints:
   - POST /activities/post-mortem -> 201 with Location header
   - GET /activities/post-mortem -> 200 with pagination
   - GET /activities/post-mortem/{analysisId} -> 200
   - PATCH /activities/post-mortem/{analysisId} -> 200
   - DELETE /activities/post-mortem/{analysisId} -> 204 (draft only)
   - POST /activities/post-mortem/{analysisId}/complete -> 200
   - POST /activities/post-mortem/{analysisId}/share -> 200
   - GET /activities/post-mortem/{analysisId}/export?format=pdf -> 200
   - POST /activities/post-mortem/{analysisId}/action-items/{actionId}/convert -> 201
   - GET /activities/post-mortem/insights -> 200
5. Run tests -- all must FAIL (RED) since no implementation exists

**Verification gate:** All contract tests compile and fail with "not implemented" errors.

---

### Agent B: Domain Logic (Business Rules)

**Role:** Implement pure business logic with no I/O dependencies. Fully unit-tested.

**Depends on:** Agent A (types must be generated)

**Artifacts:**
- `internal/domain/postmortem/analysis.go` -- Core post-mortem domain model
- `internal/domain/postmortem/validation.go` -- Validation rules
- `internal/domain/postmortem/triggers.go` -- Trigger analysis logic
- `internal/domain/postmortem/faster_mapping.go` -- FASTER Scale mapping and suggestion logic
- `internal/domain/postmortem/action_plan.go` -- Action plan management
- `internal/domain/postmortem/insights.go` -- Cross-analysis pattern computation
- `internal/domain/postmortem/sharing.go` -- Sharing rules and permission checks
- `internal/domain/postmortem/analysis_test.go` -- Unit tests
- `internal/domain/postmortem/validation_test.go` -- Unit tests
- `internal/domain/postmortem/triggers_test.go` -- Unit tests
- `internal/domain/postmortem/faster_mapping_test.go` -- Unit tests
- `internal/domain/postmortem/action_plan_test.go` -- Unit tests
- `internal/domain/postmortem/insights_test.go` -- Unit tests
- `internal/domain/postmortem/sharing_test.go` -- Unit tests

**Steps:**
1. Define domain types (PostMortemAnalysis, Section types, TriggerDetail, FasterMapping, ActionPlanItem, etc.)
2. Implement validation rules:
   - Six-section structure validation
   - Mood rating range (1-10)
   - Text length limits
   - Trigger category validation (6 allowed categories)
   - FASTER stage validation (7 stages)
   - Action plan category validation (5 categories)
   - Event type validation (relapse, near-miss, combined)
   - Near-miss cannot have relapseId
   - Minimum 1 / maximum 10 action items for completion
3. Implement draft/complete state machine:
   - Draft creation with partial sections
   - Section-by-section update
   - Completion validation (all 6 sections + action plan required)
   - Immutable createdAt enforcement
   - Completed post-mortems: only actionPlan and sharing editable
4. Implement trigger analysis:
   - Three-layer exploration (surface/underlying/coreWound)
   - Trigger category aggregation for summary
5. Implement FASTER mapping:
   - Stage assignment to timeline points
   - Keyword-based suggestion generation (e.g., "skipping meetings" -> "forgetting-priorities")
6. Implement action plan:
   - Structured format validation
   - Category tagging
   - Conversion reference tracking
7. Implement cross-analysis insights:
   - Common triggers (ranked by frequency)
   - Most frequent FASTER stage at point of no return
   - Most common time of day
   - Recurring decision point themes
8. Implement sharing rules:
   - Only complete post-mortems can be shared
   - Full vs. summary share types
   - Permission check integration (post-mortem:read)
9. Write unit tests for ALL of the above -- tests reference PM-AC IDs

**Verification gate:** `go test ./internal/domain/postmortem/...` passes with 100% coverage on validation, state machine, trigger analysis, and insights computation.

---

### Agent C: Repository Layer (MongoDB Data Access)

**Role:** Implement MongoDB repository behind an interface. Integration-tested against local MongoDB.

**Depends on:** Agent B (domain types)

**Artifacts:**
- `internal/repository/postmortem_repository.go` -- Repository interface + MongoDB implementation
- `internal/repository/postmortem_repository_test.go` -- Integration tests (test/integration/)
- MongoDB index creation script/migration

**Steps:**
1. Define `PostMortemRepository` interface:
   ```go
   type PostMortemRepository interface {
       Create(ctx context.Context, analysis *PostMortemAnalysis) error
       GetByID(ctx context.Context, userID, analysisID string) (*PostMortemAnalysis, error)
       GetByRelapseID(ctx context.Context, userID, relapseID string) (*PostMortemAnalysis, error)
       List(ctx context.Context, userID string, filter ListFilter) (*PaginatedResult, error)
       FindDrafts(ctx context.Context, userID string) ([]*PostMortemAnalysis, error)
       Update(ctx context.Context, analysis *PostMortemAnalysis) error
       Delete(ctx context.Context, userID, analysisID string) error
       GetInsightsData(ctx context.Context, userID string, filter *InsightsFilter) ([]*PostMortemAnalysis, error)
       GetSharedWith(ctx context.Context, contactID string) ([]*PostMortemAnalysis, error)
   }
   ```
2. Implement MongoDB data access with:
   - Compound indexes per mongodb-schema.md
   - Cursor-based pagination (encode/decode cursor from `createdAt` + `_id`)
   - Tenant isolation on all queries
   - Immutable `createdAt` enforcement at repository level
3. Implement calendar activity dual-write (on status transition to `complete`)
4. Write integration tests against local MongoDB:
   - CRUD operations
   - Pagination with cursors
   - Date range filtering
   - Addiction filtering
   - Status filtering
   - Tenant isolation
   - Shared post-mortem reverse lookup
   - Calendar dual-write verification

**Verification gate:** `go test ./test/integration/postmortem/...` passes with all repository tests green against local MongoDB.

---

### Agent D: Handler Layer (HTTP Handlers)

**Role:** Wire HTTP handlers to domain logic and repository. Handles request parsing, response formatting, and middleware integration.

**Depends on:** Agent A (server interface), Agent B (domain logic), Agent C (repository)

**Artifacts:**
- `internal/handler/postmortem_handler.go` -- HTTP handler implementing the generated server interface
- `internal/handler/postmortem_handler_test.go` -- Handler unit tests with mocked dependencies

**Steps:**
1. Implement handler methods for each endpoint:
   - `CreatePostMortemAnalysis` -- parse request, validate, create draft, return 201 + Location
   - `ListPostMortemAnalyses` -- parse query params, delegate to repository, format paginated response
   - `GetPostMortemAnalysis` -- fetch by ID, check ownership or sharing permission, return full detail
   - `UpdatePostMortemAnalysis` -- parse merge patch, validate status-based editability, update
   - `DeletePostMortemAnalysis` -- verify draft status, delete
   - `CompletePostMortemAnalysis` -- validate completeness, transition status, dual-write calendar
   - `SharePostMortemAnalysis` -- verify complete status, configure sharing
   - `ExportPostMortemAnalysis` -- generate PDF, return binary
   - `ConvertActionItemToCommitment` -- create commitment/goal, update action item reference
   - `GetPostMortemInsights` -- compute or retrieve cached insights
2. Integrate middleware:
   - Feature flag check (`activity.post-mortem`)
   - Auth (bearer token)
   - Tenant isolation
   - Correlation ID
   - Rate limiting
3. Implement response envelope formatting:
   - `data` wrapper
   - `links` with self, next (for pagination)
   - `meta` with timestamps
   - Error responses with `rr:0x0005xxxx` error codes
4. Write handler unit tests with mocked domain service and repository:
   - Valid requests return correct status codes and headers
   - Invalid requests return 422 with validation details
   - Missing resources return 404
   - Feature flag disabled returns 404
   - Permission denied returns 404 (not 403)
   - Compassionate messages included in complete/create responses

**Verification gate:** `go test ./internal/handler/...` passes. Contract tests from Agent A now pass (GREEN).

---

### Agent E: Event Processing and Cache

**Role:** Implement async event handlers and caching layer.

**Depends on:** Agent C (repository), Agent B (domain)

**Artifacts:**
- `internal/events/postmortem_events.go` -- SQS event handlers
- `internal/cache/postmortem_cache.go` -- Valkey cache-aside for insights
- `test/integration/events/postmortem_events_test.go`
- `test/integration/cache/postmortem_cache_test.go`

**Steps:**
1. Implement relapse event listener:
   - On relapse event, schedule 24-hour reminder check
   - If no post-mortem created within 24 hours, publish gentle reminder notification
   - If post-mortem created, cancel reminder
2. Implement post-mortem completion event publisher:
   - On status -> complete, publish event to SNS
   - Analytics service consumes event for completion rate tracking
3. Implement Valkey cache-aside for insights:
   - Cache computed insights with 30-minute TTL
   - Invalidate on new post-mortem completion
4. Write integration tests:
   - Relapse event -> reminder scheduling
   - Completion event -> analytics notification
   - Cache hit/miss/invalidation

**Verification gate:** Integration tests pass against local SQS/SNS (LocalStack) and Valkey (Docker).

---

### Agent F: Mobile API Clients

**Role:** Hand-write native API clients for Android (Kotlin) and iOS (Swift) that conform to the OpenAPI spec. Write contract tests for each.

**Depends on:** Agent A (OpenAPI spec finalized)

**Artifacts:**
- Android: `androidApp/.../data/api/PostMortemApiClient.kt`
- Android: `androidApp/.../data/api/PostMortemApiClientTest.kt`
- iOS: `iosApp/.../Data/API/PostMortemAPIClient.swift`
- iOS: `iosApp/.../Tests/PostMortemAPIClientTests.swift`

**Steps:**
1. Android (Kotlin):
   - Define request/response data classes matching OpenAPI schemas (camelCase)
   - Implement Retrofit interface for all 10 endpoints
   - Handle draft resume flow (check for existing drafts on app launch)
   - Implement offline queue for post-mortem creation/updates
   - Write contract tests validating serialized JSON matches spec
2. iOS (Swift):
   - Define Codable structs matching OpenAPI schemas (camelCase)
   - Implement URLSession-based API client for all 10 endpoints
   - Handle draft resume flow
   - Implement offline queue with SwiftData persistence
   - Write contract tests validating encoded JSON matches spec

**Verification gate:** Mobile contract tests pass. Mock server (Prism) integration works.

---

### Agent G: End-to-End Tests

**Role:** Write E2E tests that exercise the full stack against staging.

**Depends on:** All other agents (D must be deployed to staging)

**Artifacts:**
- `test/e2e/postmortem/post_mortem_test.go`

**Steps:**
1. Write E2E tests per test-specifications.md Section 3:
   - Full relapse flow (create draft, add sections incrementally, complete)
   - Near-miss flow
   - Share with sponsor (with and without permission)
   - Convert action item to commitment
   - Cross-analysis insights after 3+ post-mortems
   - Feature flag disabled -> 404
2. Use persona fixtures (Alex, Marcus, Diego)
3. Verify calendar activity creation on completion
4. Verify analytics event on completion

**Verification gate:** `go test ./test/e2e/postmortem/... -tags=e2e` passes against staging.

---

## Execution Timeline

```
Week 1:
  Agent A: Spec validation + contract tests (RED)        [2 days]
  Agent B: Domain logic + unit tests                     [3 days, starts day 2 after types from A]
  Agent F: Mobile API clients (can start with spec)      [3 days, parallel with B]

Week 2:
  Agent C: Repository layer + integration tests          [3 days, depends on B]
  Agent E: Event processing + cache                      [2 days, depends on B+C]
  Agent D: Handler layer + handler tests                 [3 days, depends on A+B+C]

Week 3:
  Agent D: Handler completion + contract tests GREEN     [2 days]
  Agent G: E2E tests against staging                     [3 days, depends on D deployed]
  All: Bug fixes, coverage gaps, review                  [2 days]
```

---

## Dependency Graph

```
Agent A (Contract Tests RED)
  |
  +---> Agent B (Domain Logic)
  |       |
  |       +---> Agent C (Repository)
  |       |       |
  |       |       +---> Agent D (Handlers) <--- Agent A (server interface)
  |       |       |       |
  |       |       |       +---> Agent G (E2E Tests)
  |       |       |
  |       +---> Agent E (Events + Cache)
  |
  +---> Agent F (Mobile Clients) [parallel, needs only spec]
```

---

## Verification Gates Summary

| Gate | Command | Criteria | When |
|------|---------|----------|------|
| G1: Spec valid | `redocly lint openapi.yaml` | 0 errors | Before any code |
| G2: Contract tests RED | `make contract-test` | All tests fail with "not implemented" | After Agent A |
| G3: Domain tests GREEN | `go test ./internal/domain/postmortem/...` | 100% pass, 100% coverage on critical | After Agent B |
| G4: Repository tests GREEN | `go test ./test/integration/postmortem/...` | All pass against local MongoDB | After Agent C |
| G5: Handler tests GREEN | `go test ./internal/handler/...` | All pass with mocked deps | After Agent D |
| G6: Contract tests GREEN | `make contract-test` | All contract tests pass | After Agent D |
| G7: Event tests GREEN | `go test ./test/integration/events/...` | Pass against LocalStack | After Agent E |
| G8: Mobile contract tests GREEN | Platform test runners | JSON serialization matches spec | After Agent F |
| G9: E2E tests GREEN | `go test ./test/e2e/postmortem/... -tags=e2e` | All pass against staging | After Agent G |
| G10: Coverage check | `make coverage-check` | >= 80% overall, 100% critical paths | Before merge |

---

## Error Codes

| Code | HTTP | Title | Description |
|------|------|-------|-------------|
| `rr:0x00050001` | 422 | Incomplete Post-Mortem | Missing required sections for completion |
| `rr:0x00050002` | 422 | Invalid Event Type | eventType must be relapse, near-miss, or combined |
| `rr:0x00050003` | 422 | Near-Miss Cannot Link Relapse | near-miss eventType cannot have relapseId |
| `rr:0x00050004` | 422 | Cannot Delete Completed | Completed post-mortems cannot be deleted |
| `rr:0x00050005` | 422 | Cannot Share Draft | Only completed post-mortems can be shared |
| `rr:0x00050006` | 422 | Invalid Trigger Category | Trigger category not in allowed set |
| `rr:0x00050007` | 422 | Invalid FASTER Stage | FASTER stage not in allowed set |
| `rr:0x00050008` | 422 | Invalid Action Category | Action category not in allowed set |
| `rr:0x00050009` | 422 | Action Item Limit | Action plan must have 1-10 items |
| `rr:0x0005000A` | 422 | Completed Post-Mortem Immutable | Cannot modify sections of completed post-mortem |
| `rr:0x0005000B` | 422 | Cannot Export Draft | Only completed post-mortems can be exported |

---

## PR Strategy

Following the project's <400 line PR target, this feature should be split into stacked PRs:

1. **PR 1: Spec + Acceptance Criteria** -- OpenAPI spec, mongodb-schema, acceptance criteria, test specs (this document set)
2. **PR 2: Contract Tests (RED) + Generated Types** -- Agent A output
3. **PR 3: Domain Logic + Unit Tests** -- Agent B output
4. **PR 4: Repository + Integration Tests** -- Agent C output
5. **PR 5: Handlers + Contract Tests GREEN** -- Agent D output
6. **PR 6: Events + Cache** -- Agent E output
7. **PR 7: Mobile API Clients** -- Agent F output (Android + iOS can be separate PRs)
8. **PR 8: E2E Tests** -- Agent G output

Each PR is independently reviewable and mergeable. Feature flag keeps everything hidden until the full stack is deployed.
