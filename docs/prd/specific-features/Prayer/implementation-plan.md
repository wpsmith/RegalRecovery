# Prayer Activity -- Multi-Agent Implementation Plan

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft
**Wave:** 2 (P1 Features & Activities)
**Feature Flag:** `activity.prayer`
**Priority:** P1

---

## Overview

This plan follows the project's spec-driven, test-first development cycle:

```
Acceptance Criteria --> OpenAPI Spec --> Contract Tests (RED) --> Domain Logic (GREEN) --> Repository --> Handler --> Integration Tests --> Mobile Clients --> E2E Tests
```

Each phase is assigned to an agent with explicit inputs, outputs, and verification gates.

---

## Prerequisites

Before starting implementation, the following Wave 0 and Wave 1 dependencies must be complete:

- [x] MongoDB single-table with PK/SK compound index
- [x] Cognito authentication (JWT bearer tokens)
- [x] Feature flag system (`FLAGS` entity, `/flags` endpoint, Valkey cache)
- [x] Valkey cache infrastructure (local Docker + staging ElastiCache)
- [x] Content pack purchase system (`content.yaml` pack endpoints)
- [x] Calendar activity dual-write infrastructure
- [x] CI/CD pipeline with contract test framework
- [x] Permission checking middleware (opt-in model)
- [x] Notification system (SNS/SQS event publishing)

---

## Phase 1: Specification Validation

### Agent 1A: Spec Validator

**Input:**
- `docs/prd/specific-features/Prayer/specs/openapi.yaml`
- `docs/prd/specific-features/Prayer/specs/acceptance-criteria.md`
- `docs/prd/specific-features/Prayer/specs/mongodb-schema.md`

**Tasks:**
1. Run `redocly lint` on `openapi.yaml` -- fix any violations
2. Verify every acceptance criterion (PR-AC*) has a corresponding endpoint in the OpenAPI spec
3. Verify every MongoDB access pattern has a corresponding endpoint
4. Verify all naming conventions match project standards (camelCase JSON, kebab-case URLs, PascalCase schemas)
5. Verify error codes follow `rr:0x00XXXXXX` format
6. Verify cursor-based pagination on all list endpoints

**Output:** Validated, linted OpenAPI spec ready for code generation

**Verification Gate:** `make spec-validate` passes with 0 errors

---

## Phase 2: Contract Tests (RED)

### Agent 2A: Contract Test Author

**Input:**
- Validated OpenAPI spec from Phase 1
- Acceptance criteria from `acceptance-criteria.md`

**Tasks:**
1. Write contract tests validating request/response schemas against OpenAPI spec
2. Write Go server interface stubs generated from `oapi-codegen`
3. Write failing acceptance tests for each PR-AC criterion:
   - `TestPrayerSession_PR_AC1_1_ManualEntry`
   - `TestPrayerSession_PR_AC1_2_InvalidPrayerType`
   - `TestPrayerSession_PR_AC1_10_TimestampImmutable`
   - `TestPrayerStreak_PR_AC5_1_ConsecutiveDays`
   - `TestPrayerStreak_PR_AC5_2_MultipleSameDay`
   - All tests from `test-specifications.md` Section 1

**Output:**
- `test/contract/prayer_test.go` -- contract tests
- `internal/api/prayer/types.go` -- generated types
- `internal/api/prayer/server.go` -- generated server interface
- `test/unit/prayer/*_test.go` -- failing unit tests

**Verification Gate:** All tests compile but FAIL (RED state). `make test-unit` shows expected failures.

**Dependencies:** Phase 1 complete

---

## Phase 3: Domain Logic (GREEN)

### Agent 3A: Prayer Session Domain

**Input:**
- Failing tests from Phase 2
- Acceptance criteria (Section 1: Prayer Session Logging)

**Tasks:**
1. Implement `PrayerSession` domain model with validation
   - Prayer type enum validation (PR-AC1.2)
   - Notes character limit (PR-AC1.4)
   - Mood range validation (PR-AC1.7, PR-AC1.8)
   - Backdating validation -- max 7 days (PR-AC1.9)
   - Timestamp immutability enforcement (PR-AC1.10)
   - Notes edit window -- 24 hours (PR-AC1.13)
   - Quick log defaults (PR-AC1.11)
2. Implement linked prayer validation (PR-AC1.5, PR-AC1.6)

**Output:** `internal/domain/prayer/session.go`, `session_validation.go`

**Verification Gate:** All PR-AC1.* unit tests pass (GREEN). Coverage >= 100% for validation logic.

### Agent 3B: Prayer Streak Domain

**Input:**
- Failing tests from Phase 2
- Acceptance criteria (Section 5: Prayer Streak and Trends)

**Tasks:**
1. Implement prayer streak calculator
   - Consecutive day counting (PR-AC5.1)
   - Multiple sessions per day collapsing (PR-AC5.2)
   - Longest streak tracking (PR-AC5.3)
   - Total prayer days (PR-AC5.5)
   - Type distribution (PR-AC5.6)
   - Timezone-aware day boundaries
2. Implement mood impact statistics

**Output:** `internal/domain/prayer/streak.go`, `stats.go`

**Verification Gate:** All PR-AC5.* unit tests pass (GREEN). Coverage = 100% for streak calculation.

### Agent 3C: Personal Prayer Domain

**Input:**
- Failing tests from Phase 2
- Acceptance criteria (Section 3: Personal Prayers)

**Tasks:**
1. Implement personal prayer model with validation
   - Title length validation (PR-AC3.2)
   - Required fields (PR-AC3.1)
   - Sort order management (PR-AC3.6)
2. Implement delete behavior -- retain linked references (PR-AC3.5)

**Output:** `internal/domain/prayer/personal.go`

**Verification Gate:** All PR-AC3.* unit tests pass (GREEN).

**Note:** Agents 3A, 3B, and 3C can run in parallel -- no dependencies between them.

---

## Phase 4: Repository Layer

### Agent 4A: Prayer Repository

**Input:**
- Domain models from Phase 3
- MongoDB schema from `mongodb-schema.md`
- Access patterns P1-P14

**Tasks:**
1. Implement prayer session repository
   - Create with calendar dual-write (PR-AC10.1)
   - List with pagination (P1)
   - Filter by date range (P2), type (P5)
   - Get by ID (P3)
   - Update with immutability checks
   - Delete with calendar cleanup
   - Ephemeral TTL support (P6)
2. Implement personal prayer repository
   - CRUD operations (P7, P8)
   - Sort order update
3. Implement prayer favorite repository
   - Add/remove favorites (P9, P10)
   - Duplicate detection (409 Conflict)
4. Implement library prayer repository
   - List by pack (P11)
   - Get by ID (P12)
   - Full-text search via Atlas Search (P13)
   - Lock status based on pack ownership

**Output:**
- `internal/repository/prayer_session_repo.go`
- `internal/repository/personal_prayer_repo.go`
- `internal/repository/prayer_favorite_repo.go`
- `internal/repository/library_prayer_repo.go`

**Verification Gate:** Integration tests from `test-specifications.md` Section 2 pass against local MongoDB.

**Dependencies:** Phase 3 complete

### Agent 4B: Prayer Cache Layer

**Input:**
- Streak domain from Agent 3B
- Valkey cache patterns from project infrastructure

**Tasks:**
1. Implement Valkey cache-aside for prayer streak
   - Cache key: `prayer:streak:<userId>`
   - TTL: 5 minutes
2. Implement cache invalidation on session create/delete
3. Implement "today's prayer" cache
   - Cache key: `prayer:today:<userId>:<date>`
   - TTL: until end of user's timezone day

**Output:** `internal/cache/prayer_cache.go`

**Verification Gate:** Cache integration tests pass (populate, hit, invalidate cycle).

**Dependencies:** Agent 3B complete

---

## Phase 5: Handler Layer

### Agent 5A: Prayer Session Handlers

**Input:**
- Repository from Agent 4A
- Domain from Agent 3A
- Generated server interface from Phase 2

**Tasks:**
1. Implement HTTP handlers for prayer session endpoints:
   - `POST /activities/prayer` -- createPrayerSession
   - `GET /activities/prayer` -- listPrayerSessions
   - `GET /activities/prayer/{id}` -- getPrayerSession
   - `PATCH /activities/prayer/{id}` -- updatePrayerSession
   - `DELETE /activities/prayer/{id}` -- deletePrayerSession
   - `GET /activities/prayer/stats` -- getPrayerStats
   - `GET /activities/prayer/trends` -- getPrayerTrends
2. Wire feature flag check middleware (`activity.prayer`)
3. Wire permission check middleware for support network access
4. Publish SNS events on session create (for notifications)

**Output:** `internal/handler/prayer_session_handler.go`

**Verification Gate:** Contract tests pass. Handler unit tests pass with mocked repository.

### Agent 5B: Prayer Content Handlers

**Input:**
- Repository from Agent 4A
- Domain from Agent 3C
- Generated server interface from Phase 2

**Tasks:**
1. Implement HTTP handlers for prayer content endpoints:
   - `GET /content/prayers` -- listPrayers
   - `GET /content/prayers/today` -- getTodayPrayer
   - `GET /content/prayers/{id}` -- getPrayer
   - `POST /content/prayers/personal` -- createPersonalPrayer
   - `GET /content/prayers/personal` -- listPersonalPrayers
   - `PATCH /content/prayers/personal/{id}` -- updatePersonalPrayer
   - `DELETE /content/prayers/personal/{id}` -- deletePersonalPrayer
   - `PUT /content/prayers/personal/order` -- reorderPersonalPrayers
   - `GET /content/prayers/favorites` -- listFavoritePrayers
   - `POST /content/prayers/favorites/{id}` -- favoritePrayer
   - `DELETE /content/prayers/favorites/{id}` -- unfavoritePrayer
2. Wire content pack ownership check for locked content

**Output:** `internal/handler/prayer_content_handler.go`

**Verification Gate:** Contract tests pass. Handler unit tests pass.

**Note:** Agents 5A and 5B can run in parallel.

**Dependencies:** Phase 4 complete

---

## Phase 6: Integration Tests

### Agent 6A: Integration Test Author

**Input:**
- All handlers from Phase 5
- Test specifications Section 2

**Tasks:**
1. Write integration tests against local MongoDB + Valkey:
   - Prayer session CRUD with calendar dual-write
   - Personal prayer CRUD with sort order
   - Favorite add/remove/list
   - Library prayer browsing with lock status
   - Streak calculation from real data
   - Cache populate/invalidate cycle
   - Pagination edge cases
2. Seed test data using persona fixtures (Alex, Marcus, Diego prayer histories)

**Output:** `test/integration/prayer/*_test.go`

**Verification Gate:** `make test-integration` passes for prayer domain. Coverage >= 80%.

**Dependencies:** Phase 5 complete

---

## Phase 7: Mobile API Clients

### Agent 7A: Android Prayer Client (Kotlin)

**Input:**
- OpenAPI spec from Phase 1
- Existing Android API client patterns

**Tasks:**
1. Hand-write Kotlin API client for prayer endpoints
   - `PrayerSessionApi` -- session CRUD + stats + trends
   - `PrayerContentApi` -- library + personal + favorites
2. Implement offline queue for prayer session logging
3. Implement prayer library cache (Room)
4. Implement prayer streak display in ViewModel
5. Write unit tests for offline sync and conflict resolution

**Output:**
- `androidApp/.../data/api/PrayerSessionApi.kt`
- `androidApp/.../data/api/PrayerContentApi.kt`
- `androidApp/.../data/local/PrayerDao.kt`
- `androidApp/.../ui/prayer/PrayerViewModel.kt`

**Verification Gate:** Android contract tests validate client against OpenAPI spec. Offline tests pass.

### Agent 7B: iOS Prayer Client (Swift)

**Input:**
- OpenAPI spec from Phase 1
- Existing iOS API client patterns

**Tasks:**
1. Hand-write Swift API client for prayer endpoints
   - `PrayerSessionService` -- session CRUD + stats + trends
   - `PrayerContentService` -- library + personal + favorites
2. Implement offline queue using SwiftData
3. Implement prayer library cache
4. Implement full-screen prayer mode UI
5. Write unit tests for offline sync and conflict resolution

**Output:**
- `iosApp/.../Data/API/PrayerSessionService.swift`
- `iosApp/.../Data/API/PrayerContentService.swift`
- `iosApp/.../Data/Local/PrayerStore.swift`
- `iosApp/.../UI/Prayer/PrayerFullScreenView.swift`

**Verification Gate:** iOS contract tests validate client against OpenAPI spec. Offline tests pass.

**Note:** Agents 7A and 7B can run in parallel, and both can start as soon as Phase 1 (spec validation) is complete -- they work against the spec, not the implementation.

---

## Phase 8: Content Seeding

### Agent 8A: Prayer Content Author

**Input:**
- PRD content requirements (freemium prayers, premium packs)
- Existing content format from `content/` directory

**Tasks:**
1. Write freemium prayer content:
   - 12 step prayers (one per step)
   - Serenity Prayer (full version)
   - Lord's Prayer with recovery reflection notes
   - 5-8 recovery-focused prayers
   - Daily morning prayer
   - Daily evening prayer
2. Write seed data for premium prayer packs (sample content):
   - Temptation & Urges pack (3-5 sample prayers)
   - Shame & Identity pack (3-5 sample prayers)
   - Marriage Restoration pack (3-5 sample prayers)
3. Create MongoDB seed script for `make local-seed`

**Output:**
- `content/prayers/freemium/*.md`
- `content/prayers/premium-samples/*.md`
- `scripts/seed_prayer_content.go`

**Verification Gate:** `make local-seed` populates prayer content. Library browsing returns expected prayers.

**Dependencies:** Phase 4 complete (repository exists to seed into)

---

## Phase 9: E2E Tests

### Agent 9A: E2E Test Author

**Input:**
- Test specifications Section 3
- Deployed staging environment

**Tasks:**
1. Write E2E tests against staging API:
   - Complete prayer session flow (create, list, detail)
   - Quick log then expand flow
   - Streak calculation across multiple days
   - Personal prayer CRUD
   - Favorite flow
   - Today's prayer consistency
   - Locked content enforcement
   - Timestamp immutability
   - Community permission enforcement
2. Use persona test accounts (Alex, Marcus, Diego)

**Output:** `test/e2e/prayer/*_test.go`

**Verification Gate:** `make test-e2e` passes for prayer domain on staging.

**Dependencies:** Phase 6 (integration tests pass) + staging deployment

---

## Phase 10: Notification Integration

### Agent 10A: Prayer Notification Handler

**Input:**
- Notification system infrastructure
- PRD notification requirements

**Tasks:**
1. Implement SQS handler for prayer events:
   - Daily prayer reminder at user-configured time
   - Missed prayer nudge after N days inactivity (default: 3)
   - Streak milestone celebrations (7, 14, 30, 60, 90 days)
   - New prayer pack available notification
2. Add prayer notification preferences to user settings
3. Write integration tests for event processing

**Output:**
- `internal/events/prayer_notification_handler.go`
- Integration tests for notification triggers

**Verification Gate:** SNS events trigger correct notifications in integration tests.

**Dependencies:** Phase 5 complete (handlers publish events)

---

## Dependency Graph

```
Phase 1 (Spec Validation)
    |
    v
Phase 2 (Contract Tests - RED)          Phase 7A/7B (Mobile Clients - parallel)
    |                                         |
    v                                         |
Phase 3A/3B/3C (Domain Logic - parallel)      |
    |                                         |
    v                                         |
Phase 4A/4B (Repository + Cache)              |
    |                                         |
    v                                         |
Phase 5A/5B (Handlers - parallel)   Phase 8 (Content Seeding)
    |                                   |
    v                                   v
Phase 6 (Integration Tests)     Seed data available
    |
    v
Deploy to Staging
    |
    v
Phase 9 (E2E Tests)
    |
Phase 10 (Notifications)
```

---

## Agent Summary

| Agent | Phase | Scope | Parallelizable With | Est. Effort |
|-------|-------|-------|---------------------|-------------|
| 1A | 1 | Spec validation | -- | 0.5 day |
| 2A | 2 | Contract tests (RED) | -- | 1 day |
| 3A | 3 | Prayer session domain | 3B, 3C | 1 day |
| 3B | 3 | Prayer streak domain | 3A, 3C | 1 day |
| 3C | 3 | Personal prayer domain | 3A, 3B | 0.5 day |
| 4A | 4 | Repository layer | 4B | 1.5 days |
| 4B | 4 | Cache layer | 4A | 0.5 day |
| 5A | 5 | Session handlers | 5B | 1 day |
| 5B | 5 | Content handlers | 5A | 1 day |
| 6A | 6 | Integration tests | -- | 1 day |
| 7A | 7 | Android client | 7B (starts at Phase 1) | 2 days |
| 7B | 7 | iOS client | 7A (starts at Phase 1) | 2 days |
| 8A | 8 | Content seeding | 7A, 7B | 1 day |
| 9A | 9 | E2E tests | -- | 1 day |
| 10A | 10 | Notifications | -- | 0.5 day |

**Critical path:** Phase 1 --> 2 --> 3 --> 4 --> 5 --> 6 --> Deploy --> 9
**Estimated critical path duration:** 7 days
**Total estimated effort (with parallelism):** 8-9 days

---

## Verification Gates Summary

| Gate | Command | Pass Criteria |
|------|---------|---------------|
| G1 -- Spec Valid | `redocly lint openapi.yaml` | 0 errors |
| G2 -- Tests RED | `make test-unit` | All prayer tests compile, all FAIL |
| G3 -- Tests GREEN | `make test-unit` | All prayer unit tests PASS |
| G4 -- Coverage | `make coverage` | >= 80% overall, 100% for streak + validation |
| G5 -- Integration | `make test-integration` | All prayer integration tests PASS |
| G6 -- Contract | `make contract-test` | Prayer endpoints match OpenAPI spec |
| G7 -- E2E | `make test-e2e` | All prayer E2E tests PASS on staging |
| G8 -- Mobile Contract | Platform-specific | Android + iOS clients match spec |

---

## Feature Flag Configuration

```json
{
  "PK": "FLAGS",
  "SK": "activity.prayer",
  "EntityType": "FEATURE_FLAG",
  "TenantId": "SYSTEM",
  "enabled": true,
  "rolloutPercentage": 0,
  "tiers": ["*"],
  "tenants": ["*"],
  "platforms": ["ios", "android"],
  "minAppVersion": "1.2.0",
  "description": "Prayer activity: session logging, content library, personal prayers, streak tracking"
}
```

**Rollout Plan:**
1. `rolloutPercentage: 0` -- Development/QA only
2. `rolloutPercentage: 10` -- Internal dogfood
3. `rolloutPercentage: 50` -- Beta
4. `rolloutPercentage: 100` -- GA

---

## PR Strategy

Target < 400 lines per PR. Split as follows:

| PR # | Scope | Lines (est) |
|------|-------|-------------|
| 1 | OpenAPI spec + acceptance criteria + MongoDB schema | ~300 |
| 2 | Domain models + validation + unit tests | ~350 |
| 3 | Streak calculator + unit tests | ~250 |
| 4 | Personal prayer domain + unit tests | ~200 |
| 5 | Prayer session repository + integration tests | ~350 |
| 6 | Personal prayer + favorite repository + integration tests | ~300 |
| 7 | Cache layer + integration tests | ~200 |
| 8 | Prayer session handlers + contract tests | ~350 |
| 9 | Prayer content handlers + contract tests | ~350 |
| 10 | Freemium prayer content + seed script | ~300 |
| 11 | Notification handler + integration tests | ~250 |
| 12 | E2E tests | ~300 |
| 13 | Android API client + offline sync | ~350 |
| 14 | iOS API client + offline sync + full-screen mode | ~400 |
