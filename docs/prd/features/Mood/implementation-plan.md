# Mood Ratings -- Multi-Agent Implementation Plan

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft
**Wave:** 2 (P1 Features & Activities)
**Feature Flag:** `activity.mood`

---

## Overview

This plan follows the project's spec-driven, test-first development methodology. Each agent works on a defined boundary with explicit input specs and output artifacts. Dependencies between agents are managed through verification gates -- no downstream agent starts until its upstream dependency passes.

---

## Prerequisites (Wave 0/1 artifacts required)

Before implementation begins, the following must be in place:

- [ ] MongoDB Atlas cluster provisioned with `moodRatings` and `calendarActivities` collections
- [ ] Valkey cache available (local Docker or staging ElastiCache)
- [ ] Feature flag `activity.mood` created in `FLAGS` collection (initially disabled)
- [ ] Auth middleware functional (Cognito JWT validation)
- [ ] Tenant isolation middleware functional
- [ ] Calendar activity dual-write infrastructure in place
- [ ] CI/CD pipeline with contract test framework operational
- [ ] Notification infrastructure (SNS/SQS) for alert events

---

## Agent Assignments

### Agent 1: Contract Tests (RED)

**Scope:** Write failing contract tests from the OpenAPI spec before any implementation.

**Inputs:**
- `docs/prd/specific-features/Mood/specs/openapi.yaml`
- `docs/prd/specific-features/Mood/specs/acceptance-criteria.md`

**Outputs:**
- `test/contract/mood/mood_contract_test.go` -- validates all 11 endpoints against OpenAPI schema
- All tests RED (no implementation exists yet)

**Tasks:**
1. Generate Go types from `openapi.yaml` using oapi-codegen (or hand-write to match)
2. Write contract tests for each endpoint validating request schemas, response schemas, status codes, and error envelope format
3. Write contract tests for error cases (400, 401, 404, 422)
4. Verify all tests fail (RED state)

**Verification Gate:** `make contract-test` runs and all mood tests are RED (expected failures). No compile errors.

**Dependencies:** None (first agent to start)

---

### Agent 2: Domain Logic

**Scope:** Pure business logic with no I/O dependencies. All validation, computation, and rules.

**Inputs:**
- `docs/prd/specific-features/Mood/specs/acceptance-criteria.md`
- `docs/prd/specific-features/Mood/specs/test-specifications.md` (Section 1: Unit Tests)

**Outputs:**
- `internal/domain/mood/entry.go` -- MoodEntry struct, validation, creation
- `internal/domain/mood/validation.go` -- rating range, emotion labels enum, note length, 24h window
- `internal/domain/mood/summary.go` -- daily summary computation, color codes, averages
- `internal/domain/mood/alerts.go` -- sustained low mood detection, crisis detection
- `internal/domain/mood/trends.go` -- trend direction, weekly/monthly summary, heatmap, day-of-week
- `internal/domain/mood/streak.go` -- mood tracking streak calculation
- `internal/domain/mood/labels.go` -- predefined emotion labels, rating label mapping
- `internal/domain/mood/*_test.go` -- all unit tests from Section 1 of test-specifications.md

**Tasks:**
1. Write failing unit tests for each AC (RED)
2. Implement MoodEntry value object with validation:
   - Rating 1-5 with label mapping
   - Emotion labels from predefined enum
   - Context note max 200 chars
   - Source enum validation
3. Implement 24-hour edit/delete window logic
4. Implement immutable timestamp enforcement
5. Implement daily summary computation (average, high, low, count, color code)
6. Implement sustained low mood detection (3+ consecutive days avg <= 2.0)
7. Implement crisis detection (rating = 1)
8. Implement trend direction algorithm (linear regression over daily averages)
9. Implement mood tracking streak (consecutive days with entries)
10. All tests GREEN

**Verification Gate:** `make test-unit` passes. Coverage >= 90% on `internal/domain/mood/`. 100% on alerts, validation, streak, and color code logic.

**Dependencies:** None (can run in parallel with Agent 1)

---

### Agent 3: Repository Layer

**Scope:** MongoDB data access implementing all access patterns from the schema spec.

**Inputs:**
- `docs/prd/specific-features/Mood/specs/mongodb-schema.md`
- `docs/prd/specific-features/Mood/specs/test-specifications.md` (Section 2.1: Repository Tests)
- Domain types from Agent 2

**Outputs:**
- `internal/repository/mood_repository.go` -- interface definition
- `internal/repository/mongodb/mood_repository.go` -- MongoDB implementation
- `test/integration/mood/mood_repository_test.go` -- integration tests

**Tasks:**
1. Define `MoodRepository` interface with methods:
   - `Create(ctx, entry) -> MoodEntry, error`
   - `GetByID(ctx, moodId) -> MoodEntry, error`
   - `ListByDateRange(ctx, userId, start, end, cursor, limit) -> []MoodEntry, cursor, error`
   - `ListByFilters(ctx, userId, filters, cursor, limit) -> []MoodEntry, cursor, error`
   - `Update(ctx, moodId, fields) -> MoodEntry, error` (with 24h check)
   - `Delete(ctx, moodId) -> error` (with 24h check)
   - `GetDailySummaries(ctx, userId, start, end) -> []DailySummary, error`
   - `GetHourlyHeatmap(ctx, userId, period) -> []HourBucket, error`
   - `GetDayOfWeekAverages(ctx, userId, period) -> []DayBucket, error`
   - `GetEmotionLabelFrequency(ctx, userId, period) -> []LabelCount, error`
   - `GetTodayEntries(ctx, userId) -> []MoodEntry, error`
   - `SearchByKeyword(ctx, userId, keyword, cursor, limit) -> []MoodEntry, cursor, error`
   - `CountConsecutiveLowDays(ctx, userId) -> int, error`
   - `GetStreak(ctx, userId) -> StreakInfo, error`
2. Implement MongoDB queries matching access patterns AP-MOOD-01 through AP-MOOD-15
3. Implement calendar activity dual-write in Create/Delete
4. Write cursor-based pagination using `createdAt` + `_id` compound cursor
5. Create MongoDB indexes as specified in schema
6. Write integration tests against local MongoDB

**Verification Gate:** `make test-integration` passes for all mood repository tests. All access patterns verified.

**Dependencies:** Agent 2 (needs domain types)

---

### Agent 4: Cache Layer

**Scope:** Valkey cache-aside pattern for mood data.

**Inputs:**
- `docs/prd/specific-features/Mood/specs/mongodb-schema.md` (Section 6: Caching Strategy)
- Repository interface from Agent 3

**Outputs:**
- `internal/cache/mood_cache.go` -- Valkey cache wrapper
- `test/integration/mood/mood_cache_test.go` -- cache integration tests

**Tasks:**
1. Implement cache-aside for today's entries (5-min TTL)
2. Implement cache for mood streak (1-hour TTL)
3. Implement cache for daily averages (24-hour TTL)
4. Implement cache invalidation on create/update/delete
5. Write integration tests verifying cache hit/miss/invalidation

**Verification Gate:** Cache integration tests pass. Cache invalidation verified for all mutation operations.

**Dependencies:** Agent 3 (needs repository interface)

---

### Agent 5: Handler Layer (HTTP)

**Scope:** HTTP handlers that wire domain logic, repository, and cache together.

**Inputs:**
- `docs/prd/specific-features/Mood/specs/openapi.yaml`
- Domain logic from Agent 2
- Repository from Agent 3
- Cache from Agent 4

**Outputs:**
- `internal/handler/mood_handler.go` -- HTTP handler implementing all 11 endpoints
- `internal/handler/mood_handler_test.go` -- handler unit tests with mocked dependencies
- `internal/middleware/mood_feature_flag.go` -- feature flag middleware for mood endpoints

**Tasks:**
1. Implement HTTP handlers for all endpoints:
   - `POST /activities/mood` -> createMoodEntry
   - `GET /activities/mood` -> listMoodEntries
   - `GET /activities/mood/{moodId}` -> getMoodEntry
   - `PATCH /activities/mood/{moodId}` -> updateMoodEntry
   - `DELETE /activities/mood/{moodId}` -> deleteMoodEntry
   - `GET /activities/mood/today` -> getMoodToday
   - `GET /activities/mood/daily-summaries` -> getMoodDailySummaries
   - `GET /activities/mood/trends` -> getMoodTrends
   - `GET /activities/mood/correlations` -> getMoodCorrelations
   - `GET /activities/mood/alerts/status` -> getMoodAlertStatus
   - `GET /activities/mood/streak` -> getMoodStreak
2. Wire feature flag check (`activity.mood`) -- return 404 when disabled
3. Wire auth middleware (Bearer JWT)
4. Wire tenant isolation
5. Implement response envelope format (`{ data, links, meta }`)
6. Implement error response format (`{ errors: [...] }`)
7. Implement cursor-based pagination response format
8. Set Location header and correlation ID on create
9. Handle permission checks for support network access
10. Write handler unit tests with mocked domain/repo/cache

**Verification Gate:** `make contract-test` passes (all RED tests from Agent 1 now GREEN). Handler unit tests pass.

**Dependencies:** Agents 2, 3, 4 (needs all layers)

---

### Agent 6: Event Publishing

**Scope:** SNS/SQS event publishing for crisis and alert notifications.

**Inputs:**
- `docs/prd/specific-features/Mood/specs/acceptance-criteria.md` (Sections 5, 8)
- `docs/prd/specific-features/Mood/specs/test-specifications.md` (Section 2.3: Event Publishing)

**Outputs:**
- `internal/events/mood_events.go` -- mood event types and publisher
- `internal/events/mood_handler.go` -- event consumers (notification triggers)
- `test/integration/mood/mood_events_test.go` -- event integration tests

**Tasks:**
1. Define event types:
   - `mood.crisis_entry` -- published when rating = 1
   - `mood.sustained_low_mood` -- published when 3+ consecutive low days
   - `mood.streak_milestone` -- published on mood streak milestones
2. Implement SNS publisher for each event type
3. Implement SQS consumer for notification delivery:
   - Crisis: log only (no auto-notify network)
   - Sustained low mood with sharing enabled: notify support contacts
   - Streak milestone: notify user
4. Implement scheduled mood check-in notifications (cron-triggered)
5. Implement missed mood nudge (cron-triggered, configurable threshold)
6. Write integration tests against local SQS/SNS

**Verification Gate:** Event integration tests pass. Crisis events published correctly. Sustained low mood notifications sent only when sharing is enabled.

**Dependencies:** Agent 5 (needs handler to trigger events)

---

### Agent 7: Integration Tests (Full Stack)

**Scope:** End-to-end integration tests against local infrastructure.

**Inputs:**
- `docs/prd/specific-features/Mood/specs/test-specifications.md` (Sections 2, 3)
- All implementation from Agents 2-6

**Outputs:**
- `test/integration/mood/mood_full_test.go` -- full-stack integration tests
- `test/e2e/mood/mood_e2e_test.go` -- E2E tests for staging

**Tasks:**
1. Write full-stack integration tests using `make local-up`:
   - Create -> Read -> Update -> Delete lifecycle
   - Multiple entries per day
   - Today's summary accuracy
   - Daily summaries for calendar
   - Trends computation with seeded data
   - Alert status evaluation
   - Streak calculation
2. Write E2E tests using persona fixtures (Alex, Marcus, Diego):
   - Full mood logging flow
   - Crisis entry flow
   - Support network permission check (sponsor with/without permission)
   - Offline sync (timestamp preservation)
3. Verify calendar activity dual-write
4. Verify cache behavior end-to-end

**Verification Gate:** `make test-integration` and `make test-e2e` pass. All acceptance criteria verified.

**Dependencies:** Agents 2-6 (needs complete implementation)

---

### Agent 8: Mobile API Clients

**Scope:** Hand-written API clients for Android (Kotlin) and iOS (Swift).

**Inputs:**
- `docs/prd/specific-features/Mood/specs/openapi.yaml`
- `docs/prd/specific-features/Mood/specs/test-specifications.md` (Section 5: Mobile Client Tests)

**Outputs:**
- `androidApp/.../data/api/MoodApiClient.kt` -- Kotlin API client
- `androidApp/.../data/api/MoodApiClientTest.kt` -- Kotlin contract tests
- `iosApp/.../Data/API/MoodAPIClient.swift` -- Swift API client
- `iosApp/.../Tests/MoodAPIClientTests.swift` -- Swift contract tests

**Tasks (Android):**
1. Hand-write Kotlin data classes matching OpenAPI schemas (camelCase)
2. Hand-write Retrofit service interface for all 11 endpoints
3. Implement offline queue for mood entries
4. Implement display mode toggle (emoji/numeric) -- local preference, no API call
5. Write contract tests validating request/response types match spec

**Tasks (iOS):**
1. Hand-write Swift Codable structs matching OpenAPI schemas
2. Hand-write URLSession API client for all 11 endpoints
3. Implement offline queue with SwiftData persistence
4. Implement display mode toggle (emoji/numeric) -- local UserDefaults
5. Write contract tests validating request/response types match spec

**Verification Gate:** Mobile contract tests pass against mock server (Prism). Offline queue tests pass.

**Dependencies:** Agent 1 (needs finalized OpenAPI spec). Can run in parallel with Agents 2-6.

---

## Execution Timeline

```
Week 1:
  [Agent 1] Contract Tests (RED)          ████░░░░░░░░░░░░
  [Agent 2] Domain Logic                  ████████░░░░░░░░
  [Agent 8] Mobile API Clients (start)    ██░░░░░░░░░░░░░░

Week 2:
  [Agent 3] Repository Layer              ░░░░████████░░░░
  [Agent 4] Cache Layer                   ░░░░░░░░████░░░░
  [Agent 8] Mobile API Clients (cont.)    ░░██████████░░░░

Week 3:
  [Agent 5] Handler Layer                 ░░░░░░░░░░████░░
  [Agent 6] Event Publishing              ░░░░░░░░░░░░████

Week 4:
  [Agent 7] Integration + E2E Tests       ░░░░░░░░░░░░████
  [Agent 8] Mobile API Clients (finish)   ░░░░░░░░░░░░░░██

Gate: All tests GREEN -> Enable feature flag for staging
```

---

## Dependency Graph

```
Agent 1 (Contract Tests RED)
  |
  +--- Agent 5 (Handler) verifies against Agent 1's tests
  |
Agent 2 (Domain Logic) ----+
  |                        |
  v                        |
Agent 3 (Repository) ------+
  |                        |
  v                        |
Agent 4 (Cache) -----------+
  |                        |
  v                        v
Agent 5 (Handler) <--------+
  |
  v
Agent 6 (Events)
  |
  v
Agent 7 (Integration + E2E)

Agent 8 (Mobile Clients) -- parallel, needs only Agent 1's spec
```

---

## Verification Gates (Quality Checkpoints)

| Gate | Trigger | Criteria | Blocks |
|------|---------|----------|--------|
| **G1: Spec Valid** | After Agent 1 | `redocly lint openapi.yaml` passes with 0 errors | All agents |
| **G2: Domain Logic** | After Agent 2 | Unit tests pass, coverage >= 90%, 100% on critical paths | Agent 3 |
| **G3: Repository** | After Agent 3 | Integration tests pass, all 15 access patterns verified | Agent 4, 5 |
| **G4: Cache** | After Agent 4 | Cache integration tests pass, invalidation verified | Agent 5 |
| **G5: Handlers GREEN** | After Agent 5 | All contract tests from Agent 1 now GREEN | Agent 6, 7 |
| **G6: Events** | After Agent 6 | Event integration tests pass, notifications verified | Agent 7 |
| **G7: Full Integration** | After Agent 7 | `make test-integration` + `make test-e2e` pass | Feature flag enable |
| **G8: Mobile Clients** | After Agent 8 | Mobile contract tests pass against Prism mock | App release |

---

## Feature Flag Rollout Plan

| Stage | `activity.mood` Config | Audience |
|-------|----------------------|----------|
| Development | Enabled for `tenant: DEV` only | Dev team |
| Staging QA | Enabled for all tenants, staging only | QA team |
| Canary | Enabled, rolloutPercentage: 10% | 10% of production users |
| Gradual | rolloutPercentage: 25% -> 50% -> 100% | Progressive rollout over 2 weeks |
| GA | Enabled, rolloutPercentage: 100% | All users |

---

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Existing `activities.yaml` has 1-10 rating scale | This spec supersedes with 1-5 scale. Update parent spec to reference this document. No production data exists yet. |
| Aggregation queries on large datasets slow down | `datePartition` index enables efficient daily grouping. Valkey caching for frequently-accessed summaries. |
| Crisis auto-notification concerns | PRD is explicit: crisis entries do NOT auto-notify. Only sustained low mood with explicit opt-in. Enforced at event handler level with tests. |
| 24-hour edit window race conditions | MongoDB conditional update with `createdAt > (now - 24h)` as atomic filter. Integration tests verify boundary conditions. |
| Calendar activity dual-write consistency | Dual-write in same handler transaction. If calendar write fails, mood entry still succeeds (calendar is denormalized read optimization). Eventual consistency via background reconciliation job. |

---

## PR Decomposition

Target < 400 lines per PR. Recommended stacking:

| PR | Agent | Content | Lines (est.) |
|----|-------|---------|-------------|
| PR-1 | 1 | OpenAPI spec + contract tests (RED) | ~350 |
| PR-2 | 2 | Domain types, validation, labels | ~300 |
| PR-3 | 2 | Summary, alerts, trends, streak logic + tests | ~400 |
| PR-4 | 3 | Repository interface + MongoDB implementation | ~400 |
| PR-5 | 4 | Cache layer | ~200 |
| PR-6 | 5 | HTTP handlers (CRUD endpoints) | ~400 |
| PR-7 | 5 | HTTP handlers (summary, trends, alerts endpoints) | ~400 |
| PR-8 | 6 | Event publishing + notification handlers | ~300 |
| PR-9 | 7 | Integration + E2E tests | ~400 |
| PR-10 | 8 | Android API client + tests | ~350 |
| PR-11 | 8 | iOS API client + tests | ~350 |
