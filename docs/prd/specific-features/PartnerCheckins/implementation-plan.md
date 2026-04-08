# Person Check-ins -- Multi-Agent Implementation Plan

**Activity:** Person Check-ins
**Priority:** P1 (Wave 2)
**Feature Flag:** `activity.person-check-ins`
**Estimated Total Effort:** 5-7 development days across agents

---

## Prerequisites

Before starting this implementation, the following Wave 0/1 foundations must be complete:

- MongoDB collections and indexes deployed (`make local-up` works)
- Feature flag system operational (`activity.person-check-ins` flag created, default: disabled)
- Auth middleware (JWT validation, userId extraction)
- Tenant isolation middleware
- Calendar activity dual-write infrastructure
- Valkey cache-aside pattern established
- Contract test framework (`make contract-test` works)
- Notification system (for inactivity alerts and streak milestones)
- Goals API (for follow-up item conversion -- FR-PCI-7.2)
- Phone Calls activity (for cross-reference prompts -- FR-PCI-11.1)
- Spouse Check-in Prep / FANOS (for cross-reference prompts -- FR-PCI-11.2)

---

## Agent Roles

| Agent | Responsibility | Skills |
|-------|---------------|--------|
| **Agent A: Spec & Contract** | OpenAPI validation, contract test scaffolding (RED) | Go, OpenAPI, Dredd/Schemathesis |
| **Agent B: Domain Logic** | Business logic: validation, streak calculation, trends, inactivity | Go, TDD |
| **Agent C: Repository** | MongoDB data access, Valkey caching, dual-write | Go, MongoDB, Valkey |
| **Agent D: Handler** | HTTP handlers, middleware integration, request/response mapping | Go, chi/net-http |
| **Agent E: Integration Tests** | Integration tests against LocalStack/MongoDB/Valkey | Go, Docker |
| **Agent F: Mobile - Android** | Kotlin API client, ViewModel, Compose UI, offline queue | Kotlin, Jetpack Compose |
| **Agent G: Mobile - iOS** | Swift API client, ViewModel, SwiftUI, offline queue | Swift, SwiftUI |

---

## Implementation Phases

### Phase 1: Spec Validation & Contract Test Scaffolding (RED)

**Agent A** works alone. All other agents are blocked until Phase 1 completes.

| Step | Agent | Task | Output | Verification |
|------|-------|------|--------|-------------|
| 1.1 | A | Validate `openapi.yaml` against OpenAPI 3.1 | Spec passes `redocly lint` | `make spec-validate` exits 0 |
| 1.2 | A | Generate Go types from spec using `oapi-codegen` | `internal/api/person_checkin/types.go` | Types compile |
| 1.3 | A | Write contract test stubs for all endpoints (RED) | `test/contract/person_checkin_test.go` | All tests FAIL (no handler yet) |
| 1.4 | A | Validate request/response examples match schema | Example validation passes | Schemathesis dry run |

**Gate:** All contract tests exist and fail. Spec is valid. Types are generated.

---

### Phase 2: Domain Logic (RED then GREEN)

**Agent B** writes failing unit tests, then implements domain logic. No HTTP or DB awareness.

**Agent C** can start in parallel on repository interfaces (not implementation).

| Step | Agent | Task | Output | Verification |
|------|-------|------|--------|-------------|
| 2.1 | B | Write validation unit tests (FR-PCI-1.*) -- RED | `internal/domain/person_checkin/checkin_test.go` | All tests FAIL |
| 2.2 | B | Implement validation logic -- GREEN | `internal/domain/person_checkin/validation.go` | Tests pass |
| 2.3 | B | Write streak calculation tests (FR-PCI-4.*) -- RED | `internal/domain/person_checkin/streak_test.go` | All tests FAIL |
| 2.4 | B | Implement streak calculator -- GREEN | `internal/domain/person_checkin/streak.go` | Tests pass, 100% coverage |
| 2.5 | B | Write quick-log tests (FR-PCI-2.*) -- RED | `quick_log_test.go` | FAIL |
| 2.6 | B | Implement quick-log logic -- GREEN | `quick_log.go` | Tests pass |
| 2.7 | B | Write settings logic tests (FR-PCI-5.*) -- RED then GREEN | `settings_test.go`, `settings.go` | Tests pass |
| 2.8 | B | Write trends calculation tests (FR-PCI-8.*) -- RED then GREEN | `trends_test.go`, `trends.go` | Tests pass |
| 2.9 | B | Write inactivity alert tests (FR-PCI-9.*) -- RED then GREEN | `inactivity_test.go`, `inactivity.go` | Tests pass |
| 2.10 | B | Write permission tests (FR-PCI-10.*) -- RED then GREEN | `permissions_test.go`, `permissions.go` | Tests pass |
| 2.11 | B | Write follow-up conversion tests (FR-PCI-7.*) -- RED then GREEN | `followup_test.go`, `followup.go` | Tests pass |
| 2.12 | C | Define repository interfaces | `internal/domain/person_checkin/interfaces.go` | Interfaces compile |

**Gate:** All domain unit tests pass. Streak calculator at 100% coverage. Domain logic has zero HTTP/DB imports.

---

### Phase 3: Repository Layer

**Agent C** implements MongoDB + Valkey access patterns. **Agent B** is available for domain logic refinements.

| Step | Agent | Task | Output | Verification |
|------|-------|------|--------|-------------|
| 3.1 | C | Implement check-in MongoDB repository | `internal/repository/person_checkin_repo.go` | Compiles against interface |
| 3.2 | C | Implement calendar activity dual-write | Dual-write in create/delete | Calendar entries appear |
| 3.3 | C | Implement streak MongoDB repository | `internal/repository/person_checkin_streak_repo.go` | Compiles |
| 3.4 | C | Implement Valkey cache layer for streaks | `internal/cache/person_checkin_streak_cache.go` | Cache-aside pattern |
| 3.5 | C | Implement settings MongoDB repository | `internal/repository/person_checkin_settings_repo.go` | Compiles |
| 3.6 | C | Create MongoDB indexes | Index creation script/migration | Indexes verified |

**Gate:** All repository implementations compile and satisfy interfaces.

---

### Phase 4: Handler Layer & Integration

**Agent D** wires HTTP handlers. **Agent E** starts writing integration tests.

| Step | Agent | Task | Output | Verification |
|------|-------|------|--------|-------------|
| 4.1 | D | Implement `POST /activities/person-check-ins` handler | `internal/handler/person_checkin_handler.go` | Contract test passes |
| 4.2 | D | Implement `GET /activities/person-check-ins` handler (list) | Same file | Contract test passes |
| 4.3 | D | Implement `POST /activities/person-check-ins/quick` handler | Same file | Contract test passes |
| 4.4 | D | Implement `GET /activities/person-check-ins/{id}` handler | Same file | Contract test passes |
| 4.5 | D | Implement `PATCH /activities/person-check-ins/{id}` handler | Same file | Contract test passes |
| 4.6 | D | Implement `DELETE /activities/person-check-ins/{id}` handler | Same file | Contract test passes |
| 4.7 | D | Implement `GET /activities/person-check-ins/streaks` handler | Same file | Contract test passes |
| 4.8 | D | Implement `GET/PATCH /activities/person-check-ins/settings` handlers | Same file | Contract test passes |
| 4.9 | D | Implement `GET /activities/person-check-ins/trends` handler | Same file | Contract test passes |
| 4.10 | D | Implement `GET /activities/person-check-ins/calendar` handler | Same file | Contract test passes |
| 4.11 | D | Implement `POST .../follow-ups/{index}/convert-to-goal` handler | Same file | Contract test passes |
| 4.12 | D | Wire feature flag middleware (`activity.person-check-ins`) | Middleware wraps all routes | Flag disabled returns 404 |
| 4.13 | D | Wire permission middleware for support contact access | Permission check on list endpoint | Returns 404 without grant |

**Gate:** All contract tests pass (GREEN). Feature flag gating works.

---

### Phase 5: Integration Tests

**Agent E** writes and runs integration tests against LocalStack/MongoDB/Valkey.

| Step | Agent | Task | Output | Verification |
|------|-------|------|--------|-------------|
| 5.1 | E | Write repository integration tests | `test/integration/person_checkin/repository_test.go` | Tests pass against local MongoDB |
| 5.2 | E | Write streak repository + cache tests | `test/integration/person_checkin/streak_repository_test.go` | Cache-aside verified |
| 5.3 | E | Write cache integration tests | `test/integration/person_checkin/cache_test.go` | TTL, invalidation verified |
| 5.4 | E | Write event processing tests | `test/integration/person_checkin/events_test.go` | SNS/SQS verified |
| 5.5 | E | Write settings repository tests | `test/integration/person_checkin/settings_repository_test.go` | Default creation verified |
| 5.6 | E | Seed persona test data | `test/integration/person_checkin/seed_test.go` | Alex, Marcus, Diego fixtures |

**Gate:** All integration tests pass with `make test-integration`.

---

### Phase 6: Mobile Clients (Parallel)

**Agent F** (Android) and **Agent G** (iOS) work in parallel. Both start after Phase 4 contract tests pass (so they have a working API to integrate against, or use mock server).

| Step | Agent | Task | Output |
|------|-------|------|--------|
| 6.1 | F | Write Kotlin API client (hand-written, matches spec) | `androidApp/.../data/api/PersonCheckInApi.kt` |
| 6.2 | F | Write ViewModel + state management | `PersonCheckInViewModel.kt` |
| 6.3 | F | Implement Compose UI (list, create, quick-log, calendar) | Compose screens |
| 6.4 | F | Implement offline queue for check-ins | `PersonCheckInOfflineQueue.kt` |
| 6.5 | F | Write unit + UI tests | Test files in `src/test/` and `src/androidTest/` |
| 6.6 | G | Write Swift API client (hand-written, matches spec) | `iosApp/.../Data/API/PersonCheckInAPI.swift` |
| 6.7 | G | Write ViewModel + state management | `PersonCheckInViewModel.swift` |
| 6.8 | G | Implement SwiftUI views (list, create, quick-log, calendar) | SwiftUI views |
| 6.9 | G | Implement offline queue for check-ins | `PersonCheckInOfflineQueue.swift` |
| 6.10 | G | Write unit + UI tests | Test files in `RegalRecoveryTests/PersonCheckIn/` |

**Gate:** Mobile clients pass contract tests against mock server. Offline queue verified.

---

### Phase 7: E2E Tests & Polish

**Agent E** writes E2E tests. **Agent D** addresses any gaps found.

| Step | Agent | Task | Output | Verification |
|------|-------|------|--------|-------------|
| 7.1 | E | Write E2E check-in flow test | `test/e2e/person_checkin/checkin_flow_test.go` | Passes against staging |
| 7.2 | E | Write E2E streak flow test | `test/e2e/person_checkin/streak_flow_test.go` | Passes |
| 7.3 | E | Write E2E permissions flow test | `test/e2e/person_checkin/permissions_flow_test.go` | Passes |
| 7.4 | E | Write E2E feature flag test | `test/e2e/person_checkin/feature_flag_test.go` | Passes |
| 7.5 | E | Write E2E trends + calendar test | `test/e2e/person_checkin/trends_flow_test.go` | Passes |
| 7.6 | D | Fix any issues found during E2E | Bug fixes | All E2E green |

**Gate:** All E2E tests pass. `make test-all` green. `make coverage-check` passes (>=80% overall, 100% for streaks/permissions).

---

## Dependency Graph

```
Phase 1 (Agent A: Spec + Contract RED)
   |
   +---> Phase 2 (Agent B: Domain Logic)
   |        |
   |        +---> Phase 3 (Agent C: Repository)
   |                 |
   |                 +---> Phase 4 (Agent D: Handlers)
   |                          |
   |                          +---> Phase 5 (Agent E: Integration Tests)
   |                          |
   |                          +---> Phase 6 (Agents F+G: Mobile, parallel)
   |                          |
   |                          +---> Phase 7 (Agent E: E2E Tests)
   |
   +---> Phase 2 (Agent C: Repository Interfaces, parallel with B)
```

---

## PR Strategy

Target < 400 lines per PR. Split into stacked PRs:

| PR # | Title | Contents | Depends On |
|------|-------|----------|------------|
| 1 | `spec: add person check-ins OpenAPI spec` | `openapi.yaml`, acceptance criteria, test specs, this plan | -- |
| 2 | `feat(person-checkin): domain types and validation` | Types, validation logic, unit tests | PR 1 |
| 3 | `feat(person-checkin): streak calculation` | Streak calculator, streak unit tests (100% coverage) | PR 2 |
| 4 | `feat(person-checkin): settings, trends, inactivity` | Settings, trends, inactivity domain logic + tests | PR 2 |
| 5 | `feat(person-checkin): MongoDB repository + indexes` | Repository impl, dual-write, Valkey cache | PR 2, PR 3 |
| 6 | `feat(person-checkin): HTTP handlers` | All endpoint handlers, feature flag wiring | PR 2-5 |
| 7 | `feat(person-checkin): contract tests GREEN` | Contract tests pass against handlers | PR 6 |
| 8 | `feat(person-checkin): integration tests` | Integration tests against local services | PR 5, PR 6 |
| 9 | `feat(person-checkin): Android client + UI` | Kotlin API client, ViewModel, Compose UI, offline | PR 7 |
| 10 | `feat(person-checkin): iOS client + UI` | Swift API client, ViewModel, SwiftUI, offline | PR 7 |
| 11 | `feat(person-checkin): E2E tests` | E2E test suite against staging | PR 6-8 |

---

## Verification Gates

Each phase has a verification gate that must pass before the next phase begins:

| Gate | Command | Criteria |
|------|---------|----------|
| Spec valid | `redocly lint specs/person-check-ins/openapi.yaml` | 0 errors |
| Contract RED | `make contract-test` | All person check-in tests FAIL |
| Domain unit | `go test ./internal/domain/person_checkin/...` | All PASS, streak 100% |
| Contract GREEN | `make contract-test` | All person check-in tests PASS |
| Integration | `make test-integration` | All PASS |
| Coverage | `make coverage-check` | >= 80% overall, 100% critical |
| E2E | `make test-e2e` | All PASS on staging |
| Mobile contract | Mock server tests | Android + iOS clients conform to spec |

---

## Feature Flag Rollout Plan

| Stage | `activity.person-check-ins` | Notes |
|-------|---------------------------|-------|
| Development | `enabled: true` (local only) | All flags enabled locally |
| Staging | `enabled: true, rolloutPercentage: 100` | Full testing |
| Production (Week 1) | `enabled: true, rolloutPercentage: 10, tiers: ["premium"]` | Canary with premium users |
| Production (Week 2) | `rolloutPercentage: 50` | Expand if error rate < 0.1% |
| Production (Week 3) | `rolloutPercentage: 100, tiers: ["*"]` | Full rollout |

---

## Risk Mitigations

| Risk | Mitigation |
|------|-----------|
| Streak calculation complexity with 3 frequency modes | 100% test coverage on streak calculator; property-based tests for edge cases |
| Offline sync conflicts with backdated entries | Union merge strategy (same as urge logs); server-side streak recalculation after sync |
| Cross-reference prompts depend on Phone Calls and FANOS activities | Feature-flag gate cross-references independently; degrade gracefully if those activities are not yet built |
| Settings document schema evolution | Additive-only changes; MongoDB flexible schema handles new fields without migration |
| Calendar dual-write consistency | Use MongoDB transactions for atomic write of check-in + calendar entry; retry on failure |
