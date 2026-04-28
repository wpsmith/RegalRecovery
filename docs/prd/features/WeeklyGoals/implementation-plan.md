# Weekly/Daily Goals -- Multi-Agent Implementation Plan

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft
**Wave:** 2 (P1 Features & Activities)
**Feature Flag:** `activity.weekly-daily-goals`
**Priority:** P1

---

## Overview

This plan follows the project's spec-driven, test-first methodology:

```
Acceptance Criteria -> OpenAPI Spec -> Contract Tests (RED) -> Domain Logic -> Repository -> Handler -> Integration Tests -> Mobile Clients
```

Each phase is assigned to a specific agent role with clear inputs, outputs, and verification gates.

---

## Prerequisites

Before starting this implementation, the following Wave 0 and Wave 1 deliverables must be complete:

- [x] MongoDB table with PK/SK indexes operational
- [x] Cognito authentication working
- [x] Feature flag system (`GET /flags`, Valkey cache)
- [x] Contract test framework (`make contract-test`)
- [x] Commitments system (`COMMITMENT#` entities, CRUD endpoints)
- [x] Activities framework (base activity types, calendar dual-write)
- [x] Tracking system (streak tracking, calendar activities collection)
- [x] Community permissions system (opt-in model, permission checking)
- [x] Notification infrastructure (SNS/SQS, notification preferences)

---

## Phase 1: Specification Validation (Agent: Spec Reviewer)

**Input:** PRD, acceptance criteria, OpenAPI spec, MongoDB schema
**Output:** Validated and consistent specification set

### Tasks

1. Validate `specs/openapi.yaml` with Redocly
   ```bash
   redocly lint docs/prd/specific-features/WeeklyGoals/specs/openapi.yaml --strict
   ```

2. Cross-reference every acceptance criterion (AC-*) in `acceptance-criteria.md` against the OpenAPI spec to verify all ACs have corresponding endpoints

3. Cross-reference MongoDB schema against OpenAPI response schemas to verify all response fields are stored or computed from stored fields

4. Verify feature flag `activity.weekly-daily-goals` is registered in `specs/openapi/flags.yaml`

### Verification Gate

- [ ] OpenAPI spec passes Redocly lint with 0 errors
- [ ] Every AC-* has at least one endpoint that satisfies it
- [ ] No orphan fields (stored but never returned) or phantom fields (returned but not stored)
- [ ] Flag key registered

---

## Phase 2: Contract Tests -- RED (Agent: Contract Test Author)

**Input:** OpenAPI spec (`specs/openapi.yaml`)
**Output:** Failing contract tests in `test/contract/goals/`
**Depends on:** Phase 1

### Tasks

1. Generate Go types from the OpenAPI spec
   ```bash
   oapi-codegen -package goals -generate types \
     -o internal/api/goals/types.go \
     docs/prd/specific-features/WeeklyGoals/specs/openapi.yaml
   ```

2. Write contract tests that validate:
   - Request schemas (CreateWeeklyDailyGoalRequest, UpdateWeeklyDailyGoalRequest, SubmitDailyReviewRequest, etc.)
   - Response schemas (DailyGoalsResponse, WeeklyGoalsResponse, GoalTrendsResponse, etc.)
   - Error response envelope structure
   - Pagination structure (cursor-based)
   - All endpoints require bearerAuth

3. Write handler interface stubs matching the spec's operationIds:
   - `createWeeklyDailyGoal`
   - `listWeeklyDailyGoals`
   - `getWeeklyDailyGoal`
   - `updateWeeklyDailyGoal`
   - `deleteWeeklyDailyGoal`
   - `getDailyGoals`
   - `getWeeklyGoals`
   - `completeGoalInstance`
   - `uncompleteGoalInstance`
   - `dismissGoalInstance`
   - `dismissDynamicNudge`
   - `getDailyReview`
   - `submitDailyReview`
   - `getWeeklyReview`
   - `submitWeeklyReview`
   - `getGoalTrends`
   - `getGoalHistory`
   - `exportGoalHistory`
   - `getGoalSettings`
   - `updateGoalSettings`
   - `getUserGoalSummary`

### Verification Gate

- [ ] All contract tests compile
- [ ] All contract tests FAIL (RED) -- no implementation yet
- [ ] Generated types match OpenAPI schema exactly

---

## Phase 3: Domain Logic -- Unit Tests RED then GREEN (Agent: Domain Logic Developer)

**Input:** Acceptance criteria, test specifications
**Output:** Domain logic in `internal/domain/goals/` with passing unit tests
**Depends on:** Phase 2 (types generated)

### Sub-phases

#### 3a: Write failing unit tests (RED)

Write all unit tests from `test-specifications.md` Section 1:

| Test Group | File | Test Count |
|-----------|------|------------|
| Goal creation & validation | `goal_creation_test.go` | 12 |
| Auto-population logic | `auto_population_test.go` | 5 |
| Daily view logic | `daily_view_test.go` | 5 |
| Dynamic gap nudge | `nudge_test.go` | 4 |
| End-of-day review | `daily_review_test.go` | 3 |
| End-of-week review | `weekly_review_test.go` | 3 |
| Trends & insights | `trends_test.go` | 5 |
| Edge cases | `edge_cases_test.go` | 3 |
| Integration points | `integration_points_test.go` | 2 |

#### 3b: Implement domain logic (GREEN)

Implement the following domain types and functions:

| File | Responsibility |
|------|----------------|
| `types.go` | Domain types: WeeklyDailyGoal, GoalInstance, GoalReview, GoalSettings, DynamicBalance |
| `validator.go` | Input validation (text length, dynamics required, notes length, recurrence rules) |
| `materializer.go` | Goal instance materialization from definitions + auto-population sources |
| `completion.go` | Complete/uncomplete logic, status transitions |
| `nudge.go` | Dynamic gap detection and nudge generation |
| `review.go` | End-of-day and end-of-week review logic, disposition processing, carry-to-tomorrow |
| `trends.go` | Completion rate calculation, consistency score, streak computation, dynamic balance |
| `summary.go` | Daily/weekly summary aggregation |
| `permissions.go` | Support network permission checking for sponsor view |

#### 3c: Refactor

Improve code quality while maintaining green tests.

### Verification Gate

- [ ] All 42+ unit tests pass (GREEN)
- [ ] Domain logic coverage >= 90%
- [ ] Materialization logic coverage = 100%
- [ ] Trend computation coverage = 100%
- [ ] Permission checking coverage = 100%
- [ ] No dependencies on HTTP or MongoDB packages in domain layer

---

## Phase 4: Repository Layer (Agent: Repository Developer)

**Input:** MongoDB schema design, domain types from Phase 3
**Output:** Repository implementation in `internal/repository/goals/`
**Depends on:** Phase 3

### Tasks

1. Implement repository interface:
   ```go
   type GoalRepository interface {
       // Goal definitions
       CreateGoal(ctx, userId, goal) error
       GetGoal(ctx, userId, goalId) (*WeeklyDailyGoal, error)
       ListGoals(ctx, userId, filters) ([]WeeklyDailyGoal, cursor, error)
       UpdateGoal(ctx, userId, goalId, updates) error
       DeleteGoal(ctx, userId, goalId) error

       // Goal instances
       GetDailyInstances(ctx, userId, date) ([]GoalInstance, error)
       GetWeeklyInstances(ctx, userId, weekStart, weekEnd) ([]GoalInstance, error)
       GetInstancesByDateRange(ctx, userId, start, end, filters) ([]GoalInstance, cursor, error)
       CreateInstance(ctx, userId, instance) error
       UpdateInstanceStatus(ctx, userId, date, instanceId, status, completedAt) error
       BatchCreateInstances(ctx, userId, instances) error

       // Reviews
       GetDailyReview(ctx, userId, date) (*GoalReview, error)
       CreateDailyReview(ctx, userId, review) error
       GetWeeklyReview(ctx, userId, weekStart) (*GoalReview, error)
       CreateWeeklyReview(ctx, userId, review) error

       // Nudges
       GetDismissedNudges(ctx, userId, date) ([]string, error)
       DismissNudge(ctx, userId, date, dynamic) error

       // Settings
       GetGoalSettings(ctx, userId) (*GoalSettings, error)
       UpdateGoalSettings(ctx, userId, settings) error

       // Calendar dual-write
       WriteCalendarActivity(ctx, userId, date, instance) error
   }
   ```

2. Implement MongoDB access patterns from `mongodb-schema.md`

3. Implement Valkey cache-aside for:
   - Daily goals (cache key: `goals:daily:{userId}:{date}`, TTL 5 min)
   - Goal settings (cache key: `goals:settings:{userId}`, TTL 10 min)

### Verification Gate

- [ ] Repository implementation compiles against domain interface
- [ ] All MongoDB access patterns from schema doc are implemented
- [ ] Cache-aside pattern implemented with invalidation on writes

---

## Phase 5: Handler Layer (Agent: Handler Developer)

**Input:** OpenAPI spec, domain logic, repository interface
**Output:** HTTP handlers in `internal/handler/goals/`
**Depends on:** Phase 3, Phase 4

### Tasks

1. Implement HTTP handlers for all 21 operationIds from the OpenAPI spec

2. Wire feature flag check on every handler:
   ```go
   if !flags.IsEnabled(ctx, "activity.weekly-daily-goals") {
       return NotFound()
   }
   ```

3. Wire authentication middleware (Cognito JWT extraction)

4. Wire tenant isolation (tenantId from JWT)

5. Implement permission checking for sponsor view endpoint

6. Map domain errors to HTTP status codes:
   - Validation errors -> 422
   - Not found -> 404
   - Permission denied -> 404 (hide data existence)

### Verification Gate

- [ ] All contract tests from Phase 2 now PASS (GREEN)
- [ ] Feature flag gating works (404 when disabled)
- [ ] Permission checking returns 404 for unauthorized access
- [ ] All handlers return correct status codes and response envelopes
- [ ] Handler coverage >= 75%

---

## Phase 6: Integration Tests (Agent: Integration Test Author)

**Input:** Test specifications Section 2, repository + handler implementations
**Output:** Passing integration tests in `test/integration/goals/`
**Depends on:** Phase 4, Phase 5

### Tasks

1. Write repository integration tests against MongoDB (LocalStack):
   - CRUD operations
   - Range queries (daily, weekly, date range)
   - Calendar dual-write verification
   - Text search on goal history

2. Write auto-population integration tests:
   - Commitment lookup and goal instance creation
   - Settings-based filtering

3. Write Valkey cache tests:
   - Cache hit/miss verification
   - Cache invalidation on writes

4. Run all integration tests:
   ```bash
   make local-up
   make test-integration -- --run TestGoal
   make local-down
   ```

### Verification Gate

- [ ] All integration tests pass
- [ ] MongoDB access patterns confirmed working
- [ ] Cache behavior verified
- [ ] Calendar dual-write confirmed

---

## Phase 7: Mobile API Clients (Agents: Android Developer, iOS Developer)

**Input:** OpenAPI spec
**Output:** Hand-written API clients + UI components
**Depends on:** Phase 5 (handlers working)

### 7a: Android (Kotlin + Jetpack Compose)

| Task | File |
|------|------|
| API client | `androidApp/.../data/api/GoalsApiClient.kt` |
| Request/response models | `androidApp/.../data/model/Goals.kt` |
| Repository (Room + offline queue) | `androidApp/.../data/repository/GoalsRepository.kt` |
| ViewModel | `androidApp/.../ui/goals/GoalsViewModel.kt` |
| Daily Goals screen | `androidApp/.../ui/goals/DailyGoalsScreen.kt` |
| Weekly Goals screen | `androidApp/.../ui/goals/WeeklyGoalsScreen.kt` |
| End-of-day review sheet | `androidApp/.../ui/goals/DailyReviewSheet.kt` |
| Quick add goal sheet | `androidApp/.../ui/goals/QuickAddGoalSheet.kt` |
| Goal trends screen | `androidApp/.../ui/goals/GoalTrendsScreen.kt` |
| Offline sync | `androidApp/.../sync/GoalsSyncWorker.kt` |

### 7b: iOS (Swift + SwiftUI)

| Task | File |
|------|------|
| API client | `iosApp/.../Data/API/GoalsAPIClient.swift` |
| Models | `iosApp/.../Data/Model/Goals.swift` |
| Repository (SwiftData + offline) | `iosApp/.../Data/Repository/GoalsRepository.swift` |
| ViewModel | `iosApp/.../UI/Goals/GoalsViewModel.swift` |
| Daily Goals view | `iosApp/.../UI/Goals/DailyGoalsView.swift` |
| Weekly Goals view | `iosApp/.../UI/Goals/WeeklyGoalsView.swift` |
| End-of-day review | `iosApp/.../UI/Goals/DailyReviewView.swift` |
| Quick add goal | `iosApp/.../UI/Goals/QuickAddGoalView.swift` |
| Goal trends view | `iosApp/.../UI/Goals/GoalTrendsView.swift` |
| Offline sync | `iosApp/.../Sync/GoalsSyncManager.swift` |

### Verification Gate

- [ ] API client types match OpenAPI spec (contract tests)
- [ ] Offline goal creation, completion, and sync working
- [ ] UI tests for daily/weekly views
- [ ] Dark mode compatible (no hardcoded colors)

---

## Phase 8: E2E Tests (Agent: E2E Test Author)

**Input:** Test specifications Section 3
**Output:** Passing E2E tests in `test/e2e/goals/`
**Depends on:** Phase 5, Phase 6

### Tasks

1. Write E2E tests from test specifications Section 3:
   - Full goal lifecycle (create, view, complete, review)
   - Auto-population from commitments
   - Activity completion auto-check
   - Sponsor view with/without permission
   - Feature flag gating
   - Trends and export

2. Run against staging:
   ```bash
   make deploy-staging
   make test-e2e -- --run TestE2E_Goal
   ```

### Verification Gate

- [ ] All E2E tests pass against staging
- [ ] Persona-based scenarios (Alex, Marcus, Diego) pass
- [ ] Feature flag toggle verified in staging

---

## Phase 9: Notification Integration (Agent: Notification Developer)

**Input:** Acceptance criteria AC-NT-*, notification infrastructure
**Output:** Goal notification handlers
**Depends on:** Phase 5

### Tasks

1. Register notification types:
   - `goal.morning-summary` -- morning goal count notification
   - `goal.midday-nudge` -- midday completion encouragement
   - `goal.evening-review` -- end-of-day review prompt
   - `goal.weekly-review` -- end-of-week review prompt
   - `goal.dynamic-gap` -- weekly dynamic gap alert

2. Implement scheduled notification triggers (SQS/SNS):
   - Morning: cron-triggered based on user's `morningTime`
   - Midday: cron-triggered (fixed schedule relative to morning)
   - Evening: cron-triggered based on user's `eveningTime`
   - Weekly: cron-triggered on user's `weeklyReviewDay`
   - Dynamic gap: weekly check, max once per dynamic per week

3. Respect notification settings from goal settings

### Verification Gate

- [ ] AC-NT-1 through AC-NT-4 satisfied
- [ ] Each notification type independently togglable
- [ ] Notification delivery verified in integration tests

---

## Dependency Graph

```
Phase 1 (Spec Validation)
    |
    v
Phase 2 (Contract Tests RED)
    |
    v
Phase 3 (Domain Logic)
    |
    +--------+--------+
    |                 |
    v                 v
Phase 4            Phase 9
(Repository)      (Notifications)
    |
    v
Phase 5 (Handlers)
    |
    +--------+--------+
    |        |        |
    v        v        v
Phase 6   Phase 7   Phase 8
(Integ)   (Mobile)  (E2E)
```

**Parallelizable work:**
- Phase 4 (Repository) and Phase 9 (Notifications) can run in parallel after Phase 3
- Phase 6 (Integration), Phase 7 (Mobile), and Phase 8 (E2E) can overlap after Phase 5
- Phase 7a (Android) and Phase 7b (iOS) are fully independent of each other

---

## Agent Assignment Summary

| Agent | Phase | Estimated Effort |
|-------|-------|-----------------|
| Spec Reviewer | Phase 1 | 0.5 day |
| Contract Test Author | Phase 2 | 1 day |
| Domain Logic Developer | Phase 3 | 3 days |
| Repository Developer | Phase 4 | 2 days |
| Handler Developer | Phase 5 | 2 days |
| Integration Test Author | Phase 6 | 1.5 days |
| Android Developer | Phase 7a | 3 days |
| iOS Developer | Phase 7b | 3 days |
| E2E Test Author | Phase 8 | 1 day |
| Notification Developer | Phase 9 | 1 day |

**Critical path:** Phase 1 -> 2 -> 3 -> 4 -> 5 -> 8 = **9.5 days**
**Total elapsed (with parallelism):** ~10-11 working days
**Total effort:** ~18 agent-days

---

## PR Strategy

Split into stacked PRs targeting `<400 lines` each:

| PR # | Content | Lines (est.) |
|------|---------|-------------|
| 1 | OpenAPI spec + acceptance criteria + MongoDB schema + test specs | ~400 (docs only) |
| 2 | Generated types + contract tests (RED) | ~300 |
| 3 | Domain types + validation + unit tests | ~350 |
| 4 | Materialization + auto-population + unit tests | ~350 |
| 5 | Completion, nudge, review logic + unit tests | ~350 |
| 6 | Trends + summary computation + unit tests | ~300 |
| 7 | Repository implementation | ~350 |
| 8 | Handler layer + contract tests GREEN | ~400 |
| 9 | Integration tests | ~350 |
| 10 | Notification integration | ~200 |
| 11 | E2E tests | ~250 |
| 12 | Android API client + repository | ~350 |
| 13 | Android UI screens | ~400 |
| 14 | iOS API client + repository | ~350 |
| 15 | iOS UI screens | ~400 |

---

## Feature Flag Configuration

```json
{
  "PK": "FLAGS",
  "SK": "activity.weekly-daily-goals",
  "EntityType": "FEATURE_FLAG",
  "TenantId": "SYSTEM",
  "enabled": true,
  "rolloutPercentage": 0,
  "tiers": ["*"],
  "tenants": ["*"],
  "platforms": ["ios", "android"],
  "minAppVersion": "1.4.0",
  "description": "Weekly and daily recovery goals with five-dynamic tracking"
}
```

**Rollout plan:**
1. Internal testing: `rolloutPercentage: 0`, manual override for team
2. Beta: `rolloutPercentage: 10`, premium tier only
3. Gradual: `rolloutPercentage: 50`
4. Full: `rolloutPercentage: 100`

---

## Completion Checklist

- [ ] Phase 1: Spec validation passed
- [ ] Phase 2: Contract tests written (RED)
- [ ] Phase 3: Domain logic implemented, unit tests GREEN
- [ ] Phase 4: Repository layer complete
- [ ] Phase 5: Handlers complete, contract tests GREEN
- [ ] Phase 6: Integration tests pass
- [ ] Phase 7a: Android client and UI complete
- [ ] Phase 7b: iOS client and UI complete
- [ ] Phase 8: E2E tests pass on staging
- [ ] Phase 9: Notifications wired
- [ ] Feature flag registered and configured
- [ ] PR checklist items verified for all PRs
- [ ] Coverage thresholds met (80% overall, 100% critical paths)
