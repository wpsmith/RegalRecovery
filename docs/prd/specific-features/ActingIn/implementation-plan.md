# Acting In Behaviors -- Multi-Agent Implementation Plan

**Feature:** Acting In Behaviors Activity
**Priority:** P2 (Wave 2)
**Feature Flag:** `activity.acting-in-behaviors`
**Target PR Size:** < 400 lines per PR (stacked PRs)

---

## Prerequisites

Before starting implementation, the following Wave 0 and Wave 1 artifacts must be complete:

- [ ] MongoDB single-table with compound indexes (`PK`, `SK`)
- [ ] Calendar activity dual-write infrastructure
- [ ] Feature flag system (`GET /flags` endpoint, Valkey cache, flag evaluator)
- [ ] Auth middleware (JWT validation, user context extraction)
- [ ] Tenant isolation middleware
- [ ] Correlation ID middleware
- [ ] Permission checker domain logic
- [ ] Notification scheduling infrastructure (SQS/SNS)
- [ ] Offline sync queue infrastructure (mobile)
- [ ] Contract test framework (`make contract-test`)
- [ ] Persona test fixtures (Alex, Marcus, Diego)

---

## Phase 1: Specification Validation

**Agent:** Spec Validator
**Duration:** 1 session
**Input:** OpenAPI spec, MongoDB schema, acceptance criteria
**Output:** Validated specs, no blocking issues

### Tasks

1. Run `redocly lint` on `docs/prd/specific-features/ActingIn/specs/openapi.yaml`
2. Verify all acceptance criteria have corresponding OpenAPI endpoints
3. Verify all MongoDB access patterns are covered by indexes
4. Verify feature flag key `activity.acting-in-behaviors` is added to the flags collection seed data
5. Verify all enum values in OpenAPI spec match PRD (triggers, relationship tags, default behaviors)

### Verification Gate

- [ ] `make spec-validate` passes
- [ ] All AC IDs traceable to at least one endpoint
- [ ] No orphaned access patterns

---

## Phase 2: Contract Tests (RED)

**Agent:** Contract Test Agent
**Duration:** 1 session
**Depends on:** Phase 1
**Output:** Failing contract tests for all endpoints

### Tasks

Write contract tests in `test/contract/actingin_test.go` that validate:

1. `POST /activities/acting-in-behaviors/check-ins` -- request and response schemas
2. `GET /activities/acting-in-behaviors/check-ins` -- paginated list response schema
3. `GET /activities/acting-in-behaviors/check-ins/{checkInId}` -- single resource response
4. `GET /activities/acting-in-behaviors/behaviors` -- behavior list response
5. `POST /activities/acting-in-behaviors/behaviors/custom` -- create custom behavior
6. `PUT /activities/acting-in-behaviors/behaviors/custom/{behaviorId}` -- update custom behavior
7. `DELETE /activities/acting-in-behaviors/behaviors/custom/{behaviorId}` -- 204 response
8. `PATCH /activities/acting-in-behaviors/behaviors/{behaviorId}/toggle` -- toggle response
9. `GET /activities/acting-in-behaviors/insights/frequency` -- insights response
10. `GET /activities/acting-in-behaviors/insights/triggers` -- trigger analysis response
11. `GET /activities/acting-in-behaviors/insights/relationships` -- relationship impact response
12. `GET /activities/acting-in-behaviors/insights/heatmap` -- heatmap response
13. `GET /activities/acting-in-behaviors/insights/cross-tool` -- cross-tool response
14. `GET /activities/acting-in-behaviors/export?format=csv` -- content type
15. `GET /activities/acting-in-behaviors/export?format=pdf` -- content type
16. `GET /activities/acting-in-behaviors/settings` -- settings response
17. `PUT /activities/acting-in-behaviors/settings` -- settings update response
18. Error responses match `ErrorResponse` schema with `rr:0x` error codes

### Verification Gate

- [ ] All contract tests written and FAILING (RED)
- [ ] Tests reference OpenAPI schema definitions
- [ ] `make contract-test` exits non-zero (expected)

---

## Phase 3: Domain Logic (Unit Tests RED, then GREEN)

**Agent:** Domain Logic Agent
**Duration:** 2-3 sessions
**Depends on:** Phase 2
**Output:** Domain logic package with passing unit tests

### PR 3a: Behavior Configuration Domain

**Files:**
- `internal/domain/actingin/behavior_config.go`
- `internal/domain/actingin/behavior_config_test.go`
- `internal/domain/actingin/types.go`

**Tasks:**
1. Write failing unit tests for AC-AIB-001 through AC-AIB-007
2. Implement `BehaviorConfig` struct with default behaviors map
3. Implement `CreateCustomBehavior`, `UpdateCustomBehavior`, `DeleteCustomBehavior`
4. Implement `ToggleBehavior`, `GetEnabledBehaviors`
5. Implement validation: name length (1-100), description length (0-500)

### PR 3b: Check-In Domain

**Files:**
- `internal/domain/actingin/checkin.go`
- `internal/domain/actingin/checkin_test.go`

**Tasks:**
1. Write failing unit tests for AC-AIB-012 through AC-AIB-018
2. Implement `CheckIn` struct with embedded behaviors array
3. Implement validation: behaviorId must be in enabled list, trigger/relationship enum validation
4. Implement context note length validation (500 chars)
5. Implement compassionate messaging selection (zero vs non-zero behaviors, rotating messages)
6. Enforce immutable timestamps (FR2.7)

### PR 3c: Streak Calculation

**Files:**
- `internal/domain/actingin/streak.go`
- `internal/domain/actingin/streak_test.go`

**Tasks:**
1. Write failing unit tests for AC-AIB-020, AC-AIB-021, AC-AIB-091
2. Implement streak calculation for daily and weekly cadences
3. Implement frequency change recalculation
4. Handle timezone-aware day boundary detection

### PR 3d: Insights Calculation

**Files:**
- `internal/domain/actingin/insights.go`
- `internal/domain/actingin/insights_test.go`

**Tasks:**
1. Write failing unit tests for AC-AIB-030 through AC-AIB-035
2. Implement frequency aggregation with rank ordering
3. Implement trend arrow calculation (current period vs prior equal-length period)
4. Implement trigger analysis and trigger-to-behavior correlation
5. Implement relationship impact aggregation with trends
6. Implement heatmap bucketing (day-of-week x hour-of-day)

### PR 3e: Cross-Tool Correlation

**Files:**
- `internal/domain/actingin/correlation.go`
- `internal/domain/actingin/correlation_test.go`

**Tasks:**
1. Write failing unit tests for AC-AIB-036 through AC-AIB-038
2. Implement PCI correlation (compare PCI scores with acting-in counts by date)
3. Implement FASTER correlation (map acting-in spikes to FASTER stages)
4. Implement post-mortem pattern detection (identify acting-in in build-up phases)
5. Handle missing cross-tool data gracefully (`correlationFound: false`)

### PR 3f: Export

**Files:**
- `internal/domain/actingin/export.go`
- `internal/domain/actingin/export_test.go`

**Tasks:**
1. Write failing unit tests for AC-AIB-043, AC-AIB-044
2. Implement CSV export (headers: date, behaviors, context, triggers, relationships)
3. Implement PDF export (formatted report suitable for therapy/sponsor meetings)
4. Implement date range filtering

### PR 3g: Settings

**Files:**
- `internal/domain/actingin/settings.go`
- `internal/domain/actingin/settings_test.go`

**Tasks:**
1. Write failing unit tests for AC-AIB-010, AC-AIB-011
2. Implement settings struct with frequency, reminder time, reminder day
3. Implement validation (time format, enum values)
4. Implement default values (daily, 21:00, Sunday)

### Verification Gate

- [ ] All unit tests GREEN
- [ ] Coverage >= 90% on `internal/domain/actingin/`
- [ ] No external dependencies (pure domain logic, interfaces only)

---

## Phase 4: Repository Layer

**Agent:** Repository Agent
**Duration:** 1-2 sessions
**Depends on:** Phase 3
**Output:** MongoDB repository with passing integration tests

### PR 4a: Repository Interface and Implementation

**Files:**
- `internal/repository/actingin_repository.go`
- `internal/repository/actingin_repository_test.go` (integration)

**Tasks:**
1. Define repository interface: `ActingInRepository`
   - `GetBehaviorConfig(ctx, userId) -> BehaviorConfig`
   - `SaveBehaviorConfig(ctx, config) -> error`
   - `GetSettings(ctx, userId) -> Settings`
   - `SaveSettings(ctx, settings) -> error`
   - `CreateCheckIn(ctx, checkIn) -> error`
   - `GetCheckIn(ctx, userId, checkInId) -> CheckIn`
   - `ListCheckIns(ctx, userId, filters, cursor, limit) -> []CheckIn, nextCursor`
   - `GetCheckInsByDateRange(ctx, userId, start, end) -> []CheckIn`
   - `GetCachedInsights(ctx, userId, range) -> Insights`
   - `SaveCachedInsights(ctx, insights) -> error`
2. Implement MongoDB operations with compound key patterns
3. Implement calendar dual-write for check-ins
4. Write integration tests against local MongoDB

### Verification Gate

- [ ] All integration tests GREEN
- [ ] Repository methods match all access patterns from schema doc
- [ ] Calendar dual-write verified

---

## Phase 5: Handler Layer

**Agent:** Handler Agent
**Duration:** 1-2 sessions
**Depends on:** Phase 3, Phase 4
**Output:** HTTP handlers wiring domain logic to repository

### PR 5a: Check-In and History Handlers

**Files:**
- `internal/handler/actingin_handler.go`
- `internal/handler/actingin_handler_test.go`

**Tasks:**
1. Implement `POST /activities/acting-in-behaviors/check-ins`
2. Implement `GET /activities/acting-in-behaviors/check-ins` (paginated)
3. Implement `GET /activities/acting-in-behaviors/check-ins/{checkInId}`
4. Wire feature flag check middleware
5. Wire permission check for support network access
6. Wire correlation ID and tenant isolation middleware

### PR 5b: Behavior Catalog Handlers

**Files:**
- `internal/handler/actingin_behavior_handler.go`
- `internal/handler/actingin_behavior_handler_test.go`

**Tasks:**
1. Implement `GET /activities/acting-in-behaviors/behaviors`
2. Implement `POST /activities/acting-in-behaviors/behaviors/custom`
3. Implement `PUT /activities/acting-in-behaviors/behaviors/custom/{behaviorId}`
4. Implement `DELETE /activities/acting-in-behaviors/behaviors/custom/{behaviorId}`
5. Implement `PATCH /activities/acting-in-behaviors/behaviors/{behaviorId}/toggle`

### PR 5c: Insights and Export Handlers

**Files:**
- `internal/handler/actingin_insights_handler.go`
- `internal/handler/actingin_insights_handler_test.go`

**Tasks:**
1. Implement all 5 insights endpoints (frequency, triggers, relationships, heatmap, cross-tool)
2. Implement export endpoint (CSV and PDF)
3. Wire cache-aside pattern for insights (Valkey 5-min TTL)

### PR 5d: Settings Handler

**Files:**
- `internal/handler/actingin_settings_handler.go`
- `internal/handler/actingin_settings_handler_test.go`

**Tasks:**
1. Implement `GET /activities/acting-in-behaviors/settings`
2. Implement `PUT /activities/acting-in-behaviors/settings`
3. Wire notification rescheduling on settings change

### Verification Gate

- [ ] All handler tests GREEN
- [ ] Contract tests now GREEN (`make contract-test` passes)
- [ ] Coverage >= 75% on handler layer

---

## Phase 6: Integration Tests

**Agent:** Integration Test Agent
**Duration:** 1 session
**Depends on:** Phase 5
**Output:** Integration test suite against local MongoDB + Valkey

### PR 6a: Integration Tests

**Files:**
- `test/integration/actingin/checkin_test.go`
- `test/integration/actingin/insights_test.go`
- `test/integration/actingin/cache_test.go`
- `test/integration/actingin/notification_test.go`

**Tasks:**
1. Seed persona data (Alex, Marcus, Diego) into local MongoDB
2. Test full check-in flow through handler -> repository -> MongoDB
3. Test insights computation and caching
4. Test cache invalidation on new check-in
5. Test notification scheduling for reminders and re-engagement
6. Test permission enforcement for support network access

### Verification Gate

- [ ] `make test-integration` passes for actingin module
- [ ] All personas exercised
- [ ] Cache behavior verified

---

## Phase 7: Mobile API Clients

Two agents work in parallel (no shared dependencies).

### Agent: Android Client Agent

**Duration:** 1-2 sessions
**Depends on:** Phase 5 (OpenAPI spec finalized)

#### PR 7a: Android API Client

**Files:**
- `androidApp/.../api/ActingInApi.kt`
- `androidApp/.../repository/ActingInRepository.kt`
- `androidApp/.../viewmodel/ActingInViewModel.kt`
- `androidApp/.../ui/ActingInCheckInScreen.kt`
- `androidApp/.../sync/ActingInOfflineQueue.kt`

**Tasks:**
1. Hand-write Kotlin API client matching OpenAPI spec
2. Implement Room entities for offline storage
3. Implement offline queue for check-ins
4. Implement check-in UI with behavior checklist, context notes, trigger chips
5. Implement insights dashboard with bar chart and trend arrows
6. Write unit tests for ViewModel and offline queue

### Agent: iOS Client Agent

**Duration:** 1-2 sessions
**Depends on:** Phase 5 (OpenAPI spec finalized)

#### PR 7b: iOS API Client

**Files:**
- `iosApp/.../API/ActingInAPI.swift`
- `iosApp/.../Repository/ActingInRepository.swift`
- `iosApp/.../ViewModel/ActingInViewModel.swift`
- `iosApp/.../Views/ActingInCheckInView.swift`
- `iosApp/.../Sync/ActingInOfflineQueue.swift`

**Tasks:**
1. Hand-write Swift API client matching OpenAPI spec
2. Implement SwiftData models for offline storage
3. Implement offline queue for check-ins
4. Implement check-in UI with behavior checklist, context notes, trigger chips
5. Implement insights dashboard with bar chart and trend arrows
6. Write unit tests for ViewModel and offline queue

### Verification Gate

- [ ] Mobile clients match OpenAPI request/response schemas
- [ ] Offline check-in flow works end-to-end
- [ ] Mobile unit tests GREEN

---

## Phase 8: E2E Tests

**Agent:** E2E Test Agent
**Duration:** 1 session
**Depends on:** Phase 6, Phase 7
**Output:** E2E test suite against staging

### PR 8a: E2E Tests

**Files:**
- `test/e2e/actingin/checkin_test.go`
- `test/e2e/actingin/insights_test.go`
- `test/e2e/actingin/permissions_test.go`

**Tasks:**
1. Full check-in flow (auth -> configure -> submit -> verify)
2. Zero-behavior check-in flow
3. Custom behavior lifecycle (create -> edit -> delete)
4. History browsing with filters
5. Insights dashboard with 7+ days of data
6. Export CSV and PDF
7. Feature flag disabled -> 404
8. Sponsor access denied -> 404
9. Spouse access granted -> trend data visible
10. Calendar integration verification

### Verification Gate

- [ ] `make test-e2e` passes for actingin module
- [ ] All critical paths covered
- [ ] Feature flag gating verified

---

## Phase 9: Final Validation

**Agent:** Validation Agent
**Duration:** 1 session
**Depends on:** All previous phases

### Tasks

1. Run full test suite: `make test-all`
2. Run contract tests: `make contract-test`
3. Verify coverage: `make coverage-check` (>= 80% overall, >= 90% domain)
4. Run lint: `make lint`
5. Verify feature flag seed data includes `activity.acting-in-behaviors`
6. Verify all AC IDs traceable to passing tests
7. Verify compassionate messaging in all user-facing responses
8. Verify offline sync works end-to-end
9. Verify audit trail for support network data access

### Final Verification Gate

- [ ] All tests GREEN
- [ ] Coverage >= 80% overall, >= 90% domain, 100% streak calculation
- [ ] Contract tests GREEN
- [ ] Lint clean
- [ ] Feature flag configured
- [ ] PR checklist complete

---

## Agent Dependency Graph

```
Phase 1: Spec Validator
    |
    v
Phase 2: Contract Test Agent (RED)
    |
    v
Phase 3: Domain Logic Agent (RED -> GREEN, 7 PRs)
    |         \
    v          v
Phase 4:    Phase 7a: Android Client Agent
Repository     (parallel, depends on spec)
Agent       Phase 7b: iOS Client Agent
    |          (parallel, depends on spec)
    v
Phase 5: Handler Agent (4 PRs)
    |
    v
Phase 6: Integration Test Agent
    |
    v
Phase 8: E2E Test Agent
    |
    v
Phase 9: Validation Agent
```

---

## PR Stack Summary

| PR | Agent | Description | Est. Lines | Depends On |
|----|-------|-------------|------------|------------|
| 1 | Spec Validator | Validate specs | -- | -- |
| 2 | Contract Test | RED contract tests | ~300 | PR 1 |
| 3a | Domain Logic | Behavior config domain | ~250 | PR 2 |
| 3b | Domain Logic | Check-in domain | ~350 | PR 2 |
| 3c | Domain Logic | Streak calculation | ~200 | PR 2 |
| 3d | Domain Logic | Insights calculation | ~400 | PR 2 |
| 3e | Domain Logic | Cross-tool correlation | ~250 | PR 2 |
| 3f | Domain Logic | Export | ~200 | PR 2 |
| 3g | Domain Logic | Settings | ~150 | PR 2 |
| 4a | Repository | MongoDB repository | ~400 | PR 3a-3g |
| 5a | Handler | Check-in handlers | ~350 | PR 3b, 4a |
| 5b | Handler | Behavior catalog handlers | ~300 | PR 3a, 4a |
| 5c | Handler | Insights + export handlers | ~350 | PR 3d-3f, 4a |
| 5d | Handler | Settings handler | ~150 | PR 3g, 4a |
| 6a | Integration Test | Integration tests | ~400 | PR 5a-5d |
| 7a | Android Client | Android API + UI | ~600 | PR 1 (spec) |
| 7b | iOS Client | iOS API + UI | ~600 | PR 1 (spec) |
| 8a | E2E Test | E2E tests | ~400 | PR 6a, 7a, 7b |
| 9 | Validation | Final validation | -- | All |

**Total estimated: ~5,650 lines across 17 PRs**

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Cross-tool correlation depends on PCI, FASTER, Post-Mortem data | Implement with interfaces; mock when cross-tool data unavailable; return `correlationFound: false` |
| Insights computation expensive for users with many check-ins | Cache-aside pattern with 5-min Valkey TTL + daily materialized view refresh |
| Offline sync conflicts | Check-ins use union merge (append all); timestamps immutable; no conflict possible |
| PDF export complexity | Use lightweight Go PDF library (e.g., `go-pdf`); keep format simple for v1 |
| Mobile clients diverge from spec | Contract tests catch drift; mock server (Prism) for mobile development |
