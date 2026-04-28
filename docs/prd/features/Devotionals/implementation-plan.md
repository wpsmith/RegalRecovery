# Devotionals -- Multi-Agent Implementation Plan

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft
**Feature Flag:** `activity.devotionals`
**Wave:** 2 (P1 Features & Activities)

---

## Prerequisites

Before starting Devotionals implementation, the following Wave 0 and Wave 1 deliverables must be complete:

- [x] MongoDB collections and indexes (Wave 0)
- [x] Feature flag system (`FLAGS` entity, `GET /flags` endpoint) (Wave 0)
- [x] Authentication/Cognito (Wave 0)
- [x] Valkey cache infrastructure (Wave 0)
- [x] CI/CD pipeline with contract test framework (Wave 0)
- [x] Content/Resources System (Wave 1) -- content pack purchase flow
- [x] Tracking System (Wave 1) -- calendar activity dual-write pattern
- [x] User Settings (Wave 1) -- notification preferences pattern
- [x] Commitments System (Wave 1) -- streak calculation pattern

---

## Implementation Phases

### Phase 1: Specification Validation (Gate: specs are valid)

**Agent: Spec Validator**

| Step | Task | Verification |
|------|------|--------------|
| 1.1 | Validate `specs/openapi.yaml` with `redocly lint` | 0 errors |
| 1.2 | Review `specs/mongodb-schema.md` against existing schema-design.md for consistency | Peer review |
| 1.3 | Review `specs/acceptance-criteria.md` for completeness against PRD | All PRD user stories covered |
| 1.4 | Review `specs/test-specifications.md` for AC coverage | Every AC has at least one test |

**Output:** Validated specs, ready for implementation.

---

### Phase 2: Database & Infrastructure Setup

**Agent: Infrastructure**

| Step | Task | Dependencies | Verification |
|------|------|-------------|--------------|
| 2.1 | Create `devotionals` collection with indexes in MongoDB | None | Indexes created, queries return results |
| 2.2 | Create `devotionalSeries` collection with indexes | None | Indexes created |
| 2.3 | Register feature flag `activity.devotionals` (enabled=false, rollout=0%) | Feature flag system | Flag exists in `FLAGS` collection |
| 2.4 | Add devotional notification preferences to User Settings schema | User Settings | Schema extended |
| 2.5 | Seed initial 30 freemium devotionals | `devotionals` collection | 30 documents with all required fields |
| 2.6 | Configure Valkey cache keys for devotional streak (5-min TTL) | Valkey | Cache key pattern established |

**Output:** Database ready, flag registered, seed data loaded.

---

### Phase 3: Contract Tests (RED)

All contract tests must be written and failing before any implementation begins.

**Agent: Contract Test Author**

| Step | Task | Dependencies | Verification |
|------|------|-------------|--------------|
| 3.1 | Generate Go types from `openapi.yaml` using oapi-codegen | Phase 1 | Types compile |
| 3.2 | Write contract tests validating all request/response schemas | Phase 1 | Tests fail (RED) -- no handlers yet |
| 3.3 | Write contract tests for error response formats | Phase 1 | Tests fail (RED) |
| 3.4 | Write contract tests for pagination structure | Phase 1 | Tests fail (RED) |
| 3.5 | Write contract tests for header requirements (Api-Version, X-Correlation-Id) | Phase 1 | Tests fail (RED) |

**Output:** All contract tests written and failing. `make contract-test` exits non-zero.

---

### Phase 4: Domain Logic (RED then GREEN)

Three agents work in parallel on independent domain modules.

#### Agent A: Content & Selection Logic

| Step | Task | Dependencies | Verification |
|------|------|-------------|--------------|
| 4A.1 | Write unit tests for devotional selector (freemium rotation, series day, timezone) | AC-DEV-CONTENT-02/03, AC-DEV-READ-03, AC-DEV-EDGE-01 | Tests RED |
| 4A.2 | Implement `DevotionalSelector` (timezone-aware day calculation, rotation logic) | 4A.1 | Tests GREEN |
| 4A.3 | Write unit tests for content tier access checking | AC-DEV-CONTENT-04/05 | Tests RED |
| 4A.4 | Implement `AccessChecker` (free vs premium, purchase verification) | 4A.3 | Tests GREEN |
| 4A.5 | Write unit tests for full-text search logic | AC-DEV-LIBRARY-05 | Tests RED |
| 4A.6 | Implement search query builder | 4A.5 | Tests GREEN |

#### Agent B: Completion & Streak Logic

| Step | Task | Dependencies | Verification |
|------|------|-------------|--------------|
| 4B.1 | Write unit tests for completion creation (with/without reflection, mood tag) | AC-DEV-REFLECT-01/02/04/05 | Tests RED |
| 4B.2 | Implement `CompletionService` (create, update, immutable timestamp) | 4B.1 | Tests GREEN |
| 4B.3 | Write unit tests for immutable timestamp enforcement | FR2.7 | Tests RED |
| 4B.4 | Implement timestamp immutability guard in completion update | 4B.3 | Tests GREEN |
| 4B.5 | Write unit tests for devotional streak calculation | AC-DEV-NOTIFY-04 | Tests RED |
| 4B.6 | Implement `DevotionalStreakCalculator` (timezone-aware, increment, reset, longest) | 4B.5 | Tests GREEN |
| 4B.7 | Write unit tests for duplicate completion detection | Conflict handling | Tests RED |
| 4B.8 | Implement duplicate check (same devotional + same day = 409) | 4B.7 | Tests GREEN |

#### Agent C: Series & Favorites Logic

| Step | Task | Dependencies | Verification |
|------|------|-------------|--------------|
| 4C.1 | Write unit tests for series progression (sequential advance, no auto-advance) | AC-DEV-SERIES-01/02 | Tests RED |
| 4C.2 | Implement `SeriesProgressionService` | 4C.1 | Tests GREEN |
| 4C.3 | Write unit tests for series activation (one active, pause/resume) | AC-DEV-SERIES-03/04 | Tests RED |
| 4C.4 | Implement `SeriesActivationService` | 4C.3 | Tests GREEN |
| 4C.5 | Write unit tests for favorites (add, remove, list, idempotent add) | AC-DEV-FAVORITE-01/02/03 | Tests RED |
| 4C.6 | Implement `FavoritesService` | 4C.5 | Tests GREEN |
| 4C.7 | Write unit tests for sharing (exclude reflection, validate contact) | AC-DEV-SHARE-01 | Tests RED |
| 4C.8 | Implement `ShareService` | 4C.7 | Tests GREEN |

**Gate:** All unit tests GREEN. `make test-unit` passes. Coverage >= 90% for domain logic.

---

### Phase 5: Repository Layer

**Agent: Repository Developer**

| Step | Task | Dependencies | Verification |
|------|------|-------------|--------------|
| 5.1 | Implement `DevotionalContentRepository` (CRUD, search, filter by topic/author/series) | Phase 2, Phase 4A | Compiles against interfaces |
| 5.2 | Implement `DevotionalCompletionRepository` (save, get, list by date range, calendar dual-write) | Phase 2, Phase 4B | Compiles against interfaces |
| 5.3 | Implement `DevotionalFavoriteRepository` (add, remove, list) | Phase 2, Phase 4C | Compiles against interfaces |
| 5.4 | Implement `SeriesProgressRepository` (get, update, activate, pause) | Phase 2, Phase 4C | Compiles against interfaces |
| 5.5 | Implement `DevotionalStreakRepository` (get, increment, reset, Valkey cache-aside) | Phase 2, Phase 4B | Compiles against interfaces |
| 5.6 | Write integration tests for all repositories against local MongoDB | Phase 5.1-5.5 | Tests GREEN with `make local-up` |

**Gate:** All repository integration tests GREEN. `make test-integration` passes for devotionals.

---

### Phase 6: Handler Layer

**Agent: Handler Developer**

| Step | Task | Dependencies | Verification |
|------|------|-------------|--------------|
| 6.1 | Implement `GET /devotionals/today` handler | Phase 4A, Phase 5.1 | Handler test GREEN |
| 6.2 | Implement `GET /devotionals` handler (list with filters, search, pagination) | Phase 4A, Phase 5.1 | Handler test GREEN |
| 6.3 | Implement `GET /devotionals/{id}` handler (with access check) | Phase 4A, Phase 5.1 | Handler test GREEN |
| 6.4 | Implement `POST /devotionals/{id}/completions` handler | Phase 4B, Phase 5.2 | Handler test GREEN |
| 6.5 | Implement `PATCH /devotionals/completions/{completionId}` handler | Phase 4B, Phase 5.2 | Handler test GREEN |
| 6.6 | Implement `GET /devotionals/completions/{completionId}` handler | Phase 5.2 | Handler test GREEN |
| 6.7 | Implement `GET /devotionals/history` handler (filters, search, pagination) | Phase 5.2 | Handler test GREEN |
| 6.8 | Implement `POST /devotionals/history/export` handler (async PDF) | Phase 5.2 | Handler test GREEN |
| 6.9 | Implement favorites handlers (GET list, POST add, DELETE remove) | Phase 4C, Phase 5.3 | Handler tests GREEN |
| 6.10 | Implement series handlers (GET list, GET detail, POST activate) | Phase 4C, Phase 5.4 | Handler tests GREEN |
| 6.11 | Implement `POST /devotionals/{id}/share` handler | Phase 4C | Handler test GREEN |
| 6.12 | Implement `GET /devotionals/streak` handler | Phase 5.5 | Handler test GREEN |
| 6.13 | Add feature flag check middleware for all devotional routes | Feature flag system | 404 when flag disabled |
| 6.14 | Add tenant isolation middleware | Tenant system | All queries scoped to tenantId |

**Gate:** All handler tests GREEN. Contract tests GREEN. `make contract-test` passes.

---

### Phase 7: Event Integration

**Agent: Event Integration Developer**

| Step | Task | Dependencies | Verification |
|------|------|-------------|--------------|
| 7.1 | Publish `devotional.completed` event on completion (SNS/SQS) | Phase 6.4 | Event published |
| 7.2 | Implement tracking system consumer (log DEVOTIONAL activity type) | AC-DEV-INTEG-01 | Activity recorded |
| 7.3 | Implement streak milestone check and notification trigger | AC-DEV-NOTIFY-04 | Notification sent at 30-day milestone |
| 7.4 | Implement goal auto-check consumer (mark devotional goal complete) | AC-DEV-INTEG-05 | Goal checked off |
| 7.5 | Implement daily reminder notification scheduling | AC-DEV-NOTIFY-01/02 | Notification sent at configured time |
| 7.6 | Implement missed devotional follow-up notification | AC-DEV-NOTIFY-03 | Follow-up sent once at configured time |
| 7.7 | Write integration tests for all event flows | Phase 7.1-7.6 | Tests GREEN |

**Gate:** All event integration tests GREEN.

---

### Phase 8: Mobile API Clients

Two agents work in parallel.

#### Agent: Android Client Developer

| Step | Task | Dependencies | Verification |
|------|------|-------------|--------------|
| 8A.1 | Hand-write Kotlin API client for all devotional endpoints | Phase 6 (OpenAPI spec) | Compiles |
| 8A.2 | Implement offline cache (current day + 7 days) | AC-DEV-OFFLINE-01 | Cache populated |
| 8A.3 | Implement offline completion queue with sync | AC-DEV-OFFLINE-02 | Queue persists, syncs on reconnect |
| 8A.4 | Write Android unit tests (ViewModel, cache, sync) | 8A.1-8A.3 | Tests GREEN |
| 8A.5 | Write contract tests validating Kotlin types against OpenAPI spec | Phase 3 | Tests GREEN |

#### Agent: iOS Client Developer

| Step | Task | Dependencies | Verification |
|------|------|-------------|--------------|
| 8B.1 | Hand-write Swift API client for all devotional endpoints | Phase 6 (OpenAPI spec) | Compiles |
| 8B.2 | Implement offline cache using SwiftData (current day + 7 days) | AC-DEV-OFFLINE-01 | Cache populated |
| 8B.3 | Implement offline completion queue with sync | AC-DEV-OFFLINE-02 | Queue persists, syncs on reconnect |
| 8B.4 | Write iOS unit tests (ViewModel, cache, sync) | 8B.1-8B.3 | Tests GREEN |
| 8B.5 | Write contract tests validating Swift types against OpenAPI spec | Phase 3 | Tests GREEN |

**Gate:** Mobile client tests GREEN. Contract tests GREEN for both platforms.

---

### Phase 9: E2E Tests

**Agent: E2E Test Author**

| Step | Task | Dependencies | Verification |
|------|------|-------------|--------------|
| 9.1 | Deploy devotionals to staging (enable feature flag at 100%) | Phase 6, Phase 7 | Deployment successful |
| 9.2 | Write and run E2E test: daily devotional flow | Phase 9.1 | Test GREEN |
| 9.3 | Write and run E2E test: premium series flow | Phase 9.1 | Test GREEN |
| 9.4 | Write and run E2E test: favorites flow | Phase 9.1 | Test GREEN |
| 9.5 | Write and run E2E test: series switching | Phase 9.1 | Test GREEN |
| 9.6 | Write and run E2E test: calendar integration | Phase 9.1 | Test GREEN |
| 9.7 | Write and run E2E test: history export | Phase 9.1 | Test GREEN |

**Gate:** All E2E tests GREEN on staging. `make test-e2e` passes.

---

### Phase 10: Rollout

| Step | Task | Verification |
|------|------|--------------|
| 10.1 | Code review -- all phases pass PR checklist | Review approved |
| 10.2 | Set feature flag `activity.devotionals` rollout to 10% | Flag updated |
| 10.3 | Monitor error rates, latency, crash rates for 24 hours | No anomalies |
| 10.4 | Increase rollout to 50% | Flag updated |
| 10.5 | Monitor for 48 hours | No anomalies |
| 10.6 | Increase rollout to 100% | Flag updated |
| 10.7 | Seed premium devotional series content | Content loaded |

---

## Agent Dependency Graph

```
Phase 1: Spec Validator
    |
    v
Phase 2: Infrastructure ──────────────────────────────┐
    |                                                   |
    v                                                   v
Phase 3: Contract Test Author                    Phase 4A: Content Logic
    |                                             Phase 4B: Completion Logic  (parallel)
    |                                             Phase 4C: Series Logic
    |                                                   |
    |                                                   v
    |                                            Phase 5: Repository Developer
    |                                                   |
    |<──────────────────────────────────────────────────┘
    |
    v
Phase 6: Handler Developer
    |
    ├──────────────────┐
    v                  v
Phase 7: Events    Phase 8A: Android Client  (parallel)
    |              Phase 8B: iOS Client
    |                  |
    v                  v
Phase 9: E2E Test Author
    |
    v
Phase 10: Rollout
```

---

## Verification Gates Summary

| Gate | Criteria | Command |
|------|----------|---------|
| G1: Specs Valid | OpenAPI lint passes, all ACs covered | `redocly lint specs/openapi.yaml` |
| G2: Contract Tests RED | All contract tests written and failing | `make contract-test` (exits non-zero) |
| G3: Domain Tests GREEN | All unit tests pass, 90%+ coverage | `make test-unit` |
| G4: Integration Tests GREEN | Repository + cache + event tests pass | `make test-integration` |
| G5: Contract Tests GREEN | Handlers conform to OpenAPI spec | `make contract-test` (exits zero) |
| G6: Mobile Tests GREEN | Android + iOS client tests pass | Platform-specific test commands |
| G7: E2E Tests GREEN | Full flows pass on staging | `make test-e2e` |
| G8: Coverage Met | Domain >= 90%, overall >= 85%, critical paths = 100% | `make coverage-check` |
| G9: PR Approved | Code review passes all checklist items | Manual review |
| G10: Canary Healthy | 10% rollout with no error spikes for 24h | CloudWatch monitoring |

---

## Estimated Effort

| Phase | Agents | Estimated Duration |
|-------|--------|--------------------|
| Phase 1: Spec Validation | 1 | 0.5 day |
| Phase 2: Infrastructure | 1 | 1 day |
| Phase 3: Contract Tests | 1 | 1 day |
| Phase 4: Domain Logic (3 parallel) | 3 | 2 days |
| Phase 5: Repository Layer | 1 | 2 days |
| Phase 6: Handler Layer | 1 | 2 days |
| Phase 7: Event Integration | 1 | 1 day |
| Phase 8: Mobile Clients (2 parallel) | 2 | 2 days |
| Phase 9: E2E Tests | 1 | 1 day |
| Phase 10: Rollout | 1 | 3 days (monitoring) |
| **Total (critical path)** | | **~12 days** |
| **Total (with parallelism)** | | **~9 days** |

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Full-text search performance on large content set | MongoDB text index; if slow, add Atlas Search or Elasticsearch |
| Offline sync conflicts (same devotional completed on multiple devices) | Union merge strategy: keep both, deduplicate by devotionalId + date |
| PDF export timeout for users with large histories | Async export via SQS; poll for status; S3 pre-signed URL for download |
| Premium content access bypass | Server-side access check on every request; client-side lock icon is cosmetic only |
| Timezone edge cases | All day-boundary logic server-side using user's configured timezone from profile |
