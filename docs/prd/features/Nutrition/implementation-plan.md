# Nutrition Activity -- Multi-Agent Implementation Plan

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft
**Wave:** 2 (P1 Features & Activities)
**Feature Flag:** `activity.nutrition`

---

## Prerequisites

Before implementation begins, the following Wave 0 and Wave 1 items must be complete:

- [x] Project scaffolding (Go module, Android project, iOS project)
- [x] MongoDB collections and indexes created
- [x] Cognito authentication operational
- [x] Valkey cache operational
- [x] CI/CD pipeline with quality gates
- [x] Feature flag system (`GET /flags` endpoint, Valkey cache)
- [x] Contract test framework (`make contract-test`)
- [x] Calendar activity dual-write infrastructure
- [x] Tracking system (streak calculation for activity consistency)
- [x] Notification infrastructure

---

## Phase 0: Specification Validation

**Duration:** 1 day
**Gate:** All specs validated before any code is written.

| Task | Owner | Deliverable | Verification |
|------|-------|-------------|-------------|
| Validate OpenAPI spec | Agent: Spec | `make spec-validate` passes for `nutrition/specs/openapi.yaml` | Zero Redocly errors |
| Review acceptance criteria completeness | Agent: Spec | All PRD user stories have at least one AC | Manual review |
| Review MongoDB schema against access patterns | Agent: Spec | All 20 access patterns have supporting indexes | Manual review |
| Create feature flag entry | Agent: Infra | `activity.nutrition` flag in FLAGS collection | `make flags-list` shows flag |

---

## Phase 1: Contract Tests (RED)

**Duration:** 2 days
**Goal:** Write failing contract tests that validate implementations against the OpenAPI spec. All tests fail because no implementation exists.

### Agent: Contract-Test

**Scope:** Generate contract test stubs from the OpenAPI spec.

| Task | File | Tests |
|------|------|-------|
| Meal CRUD contract tests | `test/contract/nutrition/meals_test.go` | 4 tests (create, get, list, update match spec) |
| Quick log contract tests | `test/contract/nutrition/quick_log_test.go` | 1 test |
| Hydration contract tests | `test/contract/nutrition/hydration_test.go` | 3 tests (get today, log, history) |
| Calendar contract tests | `test/contract/nutrition/calendar_test.go` | 1 test |
| Trends contract tests | `test/contract/nutrition/trends_test.go` | 2 tests (trends, weekly summary) |
| Settings contract tests | `test/contract/nutrition/settings_test.go` | 2 tests (get, update) |
| Error format contract tests | `test/contract/nutrition/errors_test.go` | 1 test (Siemens error format) |

**Verification Gate:** `make contract-test` runs, all 14 nutrition tests are RED (fail).

---

## Phase 2: Domain Logic + Unit Tests (RED then GREEN)

**Duration:** 3-4 days
**Goal:** Implement business logic with TDD. Write failing unit tests first, then implement.

### Agent: Domain-Meal

**Scope:** Meal log validation, creation, update logic.

| Task | File | Depends On |
|------|------|-----------|
| Meal log validator | `internal/domain/nutrition/meal_validator.go` | -- |
| Meal log validator tests (RED) | `internal/domain/nutrition/meal_validator_test.go` | -- |
| Meal log domain model | `internal/domain/nutrition/meal.go` | Validator |
| Meal log domain tests (GREEN) | `internal/domain/nutrition/meal_test.go` | Model |
| Quick log creation logic | `internal/domain/nutrition/quick_log.go` | Model |
| Immutable timestamp enforcement | `internal/domain/nutrition/timestamp.go` | Model |

**Test Coverage:** FR-NUT-1.1 through FR-NUT-1.14, FR-NUT-2.1, FR-NUT-2.2

### Agent: Domain-Hydration

**Scope:** Hydration logic -- increment/decrement, goal tracking, date boundaries.

| Task | File | Depends On |
|------|------|-----------|
| Hydration service | `internal/domain/nutrition/hydration.go` | -- |
| Hydration service tests (RED then GREEN) | `internal/domain/nutrition/hydration_test.go` | -- |
| Serving size and goal calculation | `internal/domain/nutrition/hydration_config.go` | -- |
| Date boundary logic (timezone-aware) | `internal/domain/nutrition/hydration_date.go` | -- |

**Test Coverage:** FR-NUT-3.1 through FR-NUT-3.8

### Agent: Domain-Trends

**Scope:** Trends calculation, insight generation, ED safeguards.

| Task | File | Depends On |
|------|------|-----------|
| Meal consistency calculator | `internal/domain/nutrition/trends_consistency.go` | -- |
| Emotional eating analyzer | `internal/domain/nutrition/trends_emotional.go` | -- |
| Mindfulness trend calculator | `internal/domain/nutrition/trends_mindfulness.go` | -- |
| Calendar completeness calculator | `internal/domain/nutrition/calendar_completeness.go` | -- |
| Gap detection engine | `internal/domain/nutrition/trends_gaps.go` | -- |
| ED safeguard checks | `internal/domain/nutrition/ed_safeguards.go` | -- |
| Insight generator | `internal/domain/nutrition/insights.go` | All trend calculators |
| All trend tests (RED then GREEN) | `internal/domain/nutrition/trends_*_test.go` | -- |

**Test Coverage:** FR-NUT-5.1 through FR-NUT-5.4, FR-NUT-7.1 through FR-NUT-8.2, FR-NUT-11.1 through FR-NUT-11.6

### Agent: Domain-Settings

**Scope:** Nutrition settings with defaults, merge logic.

| Task | File | Depends On |
|------|------|-----------|
| Settings model with defaults | `internal/domain/nutrition/settings.go` | -- |
| Settings merge (JSON Merge Patch) | `internal/domain/nutrition/settings_merge.go` | -- |
| Settings tests | `internal/domain/nutrition/settings_test.go` | -- |

**Test Coverage:** FR-NUT-10.1 through FR-NUT-10.6

**Phase 2 Verification Gate:** `make test-unit` -- all nutrition unit tests GREEN. Coverage >= 90% for `internal/domain/nutrition/`.

---

## Phase 3: Repository Layer

**Duration:** 2 days
**Goal:** Implement MongoDB data access behind repository interfaces.

### Agent: Repository

**Scope:** All MongoDB operations for meal logs, hydration, settings, calendar dual-write.

| Task | File | Depends On |
|------|------|-----------|
| Meal log repository interface | `internal/repository/nutrition_meal.go` | Domain model |
| Meal log repository implementation | `internal/repository/nutrition_meal_mongo.go` | Interface |
| Hydration repository interface | `internal/repository/nutrition_hydration.go` | Domain model |
| Hydration repository implementation | `internal/repository/nutrition_hydration_mongo.go` | Interface |
| Settings repository interface | `internal/repository/nutrition_settings.go` | Domain model |
| Settings repository implementation | `internal/repository/nutrition_settings_mongo.go` | Interface |
| Calendar dual-write logic | `internal/repository/nutrition_calendar.go` | Calendar infra |
| Aggregation pipelines (trends) | `internal/repository/nutrition_aggregation.go` | -- |
| Text search implementation | `internal/repository/nutrition_search.go` | Text index |
| Integration tests | `test/integration/nutrition/repository_test.go` | Local MongoDB |

**Integration Tests:** NUT-1 through NUT-20 access patterns verified.

**Phase 3 Verification Gate:** `make test-integration` -- all nutrition repository tests pass against local MongoDB.

---

## Phase 4: Handler Layer

**Duration:** 2 days
**Goal:** Wire HTTP handlers to domain logic and repositories.

### Agent: Handler

**Scope:** HTTP handlers for all nutrition endpoints, including feature flag gating, auth, and error formatting.

| Task | File | Depends On |
|------|------|-----------|
| Meal handler (CRUD + quick log) | `internal/handler/nutrition_meal_handler.go` | Domain + Repository |
| Hydration handler | `internal/handler/nutrition_hydration_handler.go` | Domain + Repository |
| Calendar handler | `internal/handler/nutrition_calendar_handler.go` | Domain + Repository |
| Trends handler | `internal/handler/nutrition_trends_handler.go` | Domain + Repository |
| Settings handler | `internal/handler/nutrition_settings_handler.go` | Domain + Repository |
| Feature flag middleware integration | `internal/handler/nutrition_flag_gate.go` | Flag system |
| Permission check for support network | `internal/handler/nutrition_permissions.go` | Permission system |
| Handler unit tests | `internal/handler/nutrition_*_test.go` | Mocked repos |

**Phase 4 Verification Gate:**
- Handler unit tests GREEN
- `make contract-test` -- all 14 nutrition contract tests GREEN
- Coverage >= 75% for handler layer

---

## Phase 5: Integration Tests

**Duration:** 1-2 days
**Goal:** Full integration tests with MongoDB, Valkey, and event processing.

### Agent: Integration-Test

**Scope:** End-to-end integration testing with local infrastructure.

| Task | File | Depends On |
|------|------|-----------|
| Meal CRUD integration | `test/integration/nutrition/meal_test.go` | All layers |
| Hydration integration | `test/integration/nutrition/hydration_test.go` | All layers |
| Calendar dual-write integration | `test/integration/nutrition/calendar_test.go` | All layers |
| Trends aggregation integration | `test/integration/nutrition/trends_test.go` | All layers |
| Settings integration | `test/integration/nutrition/settings_test.go` | All layers |
| Feature flag gating integration | `test/integration/nutrition/flag_test.go` | Flag system |
| Permission integration | `test/integration/nutrition/permission_test.go` | Permission system |
| Notification trigger integration | `test/integration/nutrition/notification_test.go` | Notification system |
| Seed data (persona fixtures) | `test/integration/nutrition/seeds.go` | Persona fixtures |

**Phase 5 Verification Gate:** `make local-up && make test-integration` -- all nutrition integration tests pass.

---

## Phase 6: Mobile API Clients

**Duration:** 2-3 days (parallelizable)
**Goal:** Hand-written API clients for Android and iOS, with contract test validation.

### Agent: Mobile-Android

**Scope:** Kotlin API client for nutrition endpoints.

| Task | File | Depends On |
|------|------|-----------|
| NutritionApiClient | `androidApp/.../data/api/NutritionApiClient.kt` | OpenAPI spec |
| NutritionRepository (Room + API) | `androidApp/.../data/repository/NutritionRepository.kt` | API client |
| Offline queue for meal logs | `androidApp/.../sync/NutritionSyncManager.kt` | Offline infra |
| Conflict resolver (union merge meals, LWW hydration) | `androidApp/.../sync/NutritionConflictResolver.kt` | -- |
| ViewModel tests | `androidApp/.../test/.../NutritionViewModelTest.kt` | -- |
| Contract tests (Kotlin) | `androidApp/.../test/.../NutritionContractTest.kt` | API client |

### Agent: Mobile-iOS

**Scope:** Swift API client for nutrition endpoints.

| Task | File | Depends On |
|------|------|-----------|
| NutritionAPIClient | `iosApp/.../Data/API/NutritionAPIClient.swift` | OpenAPI spec |
| NutritionRepository (SwiftData + API) | `iosApp/.../Data/Repository/NutritionRepository.swift` | API client |
| Offline queue for meal logs | `iosApp/.../Sync/NutritionSyncManager.swift` | Offline infra |
| Conflict resolver | `iosApp/.../Sync/NutritionConflictResolver.swift` | -- |
| ViewModel tests | `iosApp/Tests/Nutrition/NutritionViewModelTests.swift` | -- |
| Contract tests (Swift) | `iosApp/Tests/Nutrition/NutritionContractTests.swift` | API client |

**Phase 6 Verification Gate:** Mobile contract tests pass against mock server (`prism mock nutrition/specs/openapi.yaml`).

---

## Phase 7: E2E Tests

**Duration:** 1 day
**Goal:** Validate the complete flow against the staging environment.

### Agent: E2E-Test

| Task | File | Depends On |
|------|------|-----------|
| Meal CRUD E2E | `test/e2e/nutrition/meal_test.go` | Staging deployed |
| Quick log E2E | `test/e2e/nutrition/quick_log_test.go` | Staging deployed |
| Hydration E2E | `test/e2e/nutrition/hydration_test.go` | Staging deployed |
| Calendar E2E | `test/e2e/nutrition/calendar_test.go` | Staging deployed |
| Trends E2E | `test/e2e/nutrition/trends_test.go` | Staging deployed |
| Settings E2E | `test/e2e/nutrition/settings_test.go` | Staging deployed |
| Feature flag E2E | `test/e2e/nutrition/flag_test.go` | Staging deployed |
| Permission/privacy E2E | `test/e2e/nutrition/permission_test.go` | Staging deployed |

**Phase 7 Verification Gate:** `make deploy-staging && make test-e2e` -- all nutrition E2E tests pass.

---

## Dependency Graph

```
Phase 0: Spec Validation
    |
    v
Phase 1: Contract Tests (RED)
    |
    v
Phase 2: Domain Logic + Unit Tests ──────────────────────────┐
    |                                                         |
    |  [Agent: Domain-Meal]     ─┐                            |
    |  [Agent: Domain-Hydration] ├── parallel                 |
    |  [Agent: Domain-Trends]   ─┤                            |
    |  [Agent: Domain-Settings] ─┘                            |
    |                                                         |
    v                                                         |
Phase 3: Repository Layer                                     |
    |  [Agent: Repository] ── depends on all Domain agents    |
    |                                                         |
    v                                                         |
Phase 4: Handler Layer                                        |
    |  [Agent: Handler] ── depends on Repository + Domain     |
    |                                                         |
    v                                                         |
Phase 5: Integration Tests                                    |
    |  [Agent: Integration-Test]                              |
    |                                                         |
    +──────────────────┬──────────────────┐                   |
    |                  |                  |                    |
    v                  v                  v                    |
Phase 6a:          Phase 6b:         Phase 6c:                |
Mobile-Android     Mobile-iOS        Backend Deploy           |
(parallel)         (parallel)        to Staging               |
    |                  |                  |                    |
    +──────────────────+──────────────────+                   |
    |                                                         |
    v                                                         |
Phase 7: E2E Tests                                            |
    |                                                         |
    v                                                         |
DONE ─────────────────────────────────────────────────────────┘
```

---

## Agent Summary

| Agent | Phase(s) | Parallelizable With | Key Deliverables |
|-------|----------|--------------------|--------------------|
| **Spec** | 0 | -- | Validated specs, feature flag entry |
| **Contract-Test** | 1 | -- | 14 failing contract tests |
| **Domain-Meal** | 2 | Domain-Hydration, Domain-Trends, Domain-Settings | Meal validation, creation, update, immutable timestamps |
| **Domain-Hydration** | 2 | Domain-Meal, Domain-Trends, Domain-Settings | Hydration increment/decrement, goal tracking, date boundaries |
| **Domain-Trends** | 2 | Domain-Meal, Domain-Hydration, Domain-Settings | Trends calculation, gap detection, insight generation, ED safeguards |
| **Domain-Settings** | 2 | Domain-Meal, Domain-Hydration, Domain-Trends | Settings model, defaults, merge logic |
| **Repository** | 3 | -- | MongoDB CRUD, aggregation pipelines, text search, dual-write |
| **Handler** | 4 | -- | HTTP handlers, flag gating, permission checks, error formatting |
| **Integration-Test** | 5 | -- | Full-stack integration tests with local infra |
| **Mobile-Android** | 6 | Mobile-iOS | Kotlin API client, offline sync, conflict resolver |
| **Mobile-iOS** | 6 | Mobile-Android | Swift API client, offline sync, conflict resolver |
| **E2E-Test** | 7 | -- | Staging E2E tests for all flows |

---

## Quality Gates (must pass before each phase advances)

| Gate | Criteria | Command |
|------|----------|---------|
| **Spec Gate** | OpenAPI spec valid, zero errors | `make spec-validate` |
| **RED Gate** | All contract tests exist and fail | `make contract-test` (expect failures) |
| **Unit Gate** | All unit tests pass, coverage >= 90% domain, >= 80% overall | `make test-unit && make coverage` |
| **Contract Gate** | All contract tests pass | `make contract-test` (expect success) |
| **Integration Gate** | All integration tests pass | `make local-up && make test-integration` |
| **Mobile Gate** | Mobile contract tests pass against mock server | `prism mock` + test runner |
| **E2E Gate** | All E2E tests pass on staging | `make deploy-staging && make test-e2e` |
| **PR Gate** | All of the above + lint + no security vulns + PR checklist complete | `make test-all && make lint` |

---

## Estimated Timeline

| Phase | Duration | Cumulative |
|-------|----------|-----------|
| Phase 0: Spec Validation | 1 day | Day 1 |
| Phase 1: Contract Tests (RED) | 2 days | Day 3 |
| Phase 2: Domain Logic (4 agents parallel) | 3-4 days | Day 7 |
| Phase 3: Repository Layer | 2 days | Day 9 |
| Phase 4: Handler Layer | 2 days | Day 11 |
| Phase 5: Integration Tests | 1-2 days | Day 13 |
| Phase 6: Mobile Clients (parallel) | 2-3 days | Day 16 |
| Phase 7: E2E Tests | 1 day | Day 17 |

**Total: ~17 working days (3.5 weeks)**

---

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Trends aggregation performance on large datasets | Use MongoDB aggregation pipelines with appropriate indexes; cache trend results in Valkey with 5-min TTL |
| ED safeguard language review | Have clinical advisor review all generated insight text before release |
| Calendar dual-write consistency | Use MongoDB transactions for meal create + calendar write; integration test covers both writes |
| Offline conflict resolution edge cases | Extensive unit tests for union merge and LWW scenarios; test with persona fixtures that simulate multi-device usage |
| Cross-domain correlation accuracy | Start with simple correlations; defer ML-based correlations to Wave 4 (Recovery Agent) |

---

## Related Documents

- [Acceptance Criteria](./specs/acceptance-criteria.md)
- [OpenAPI Spec](./specs/openapi.yaml)
- [MongoDB Schema](./specs/mongodb-schema.md)
- [Test Specifications](./specs/test-specifications.md)
- [Nutrition PRD](./Nutrition_Activity.md)
- [SPEC-PLAN (project-wide)](../../docs/specs/SPEC-PLAN.md)
