# Exercise / Physical Activity -- Multi-Agent Implementation Plan

**Priority:** P1 (Wave 2)
**Feature Flag:** `activity.exercise`
**Estimated Total Effort:** 5-7 sprints (2-week sprints)
**Dependencies:** Wave 0 (foundation), Wave 1 core tracking system, feature flag system

---

## Implementation Philosophy

Spec-driven, test-first. Every agent writes failing tests before implementation code. The OpenAPI spec at `docs/prd/specific-features/Exercise/specs/openapi.yaml` is the source of truth. If the spec says X and the code does Y, the code is wrong.

---

## Agent Roster

| Agent ID | Responsibility | Skills |
|----------|---------------|--------|
| **A1** | OpenAPI Contract Tests | Go, OpenAPI validation, Dredd/Schemathesis |
| **A2** | Domain Logic (Business Rules) | Go, TDD, domain modeling |
| **A3** | Repository Layer (MongoDB) | Go, MongoDB driver, index design |
| **A4** | Handler Layer (HTTP) | Go, chi/mux, middleware, auth |
| **A5** | Cache Layer (Valkey) | Go, Valkey client, cache-aside pattern |
| **A6** | Integration Tests | Go, Docker, MongoDB, Valkey |
| **A7** | Android Client | Kotlin, Jetpack Compose, Room, Retrofit |
| **A8** | iOS Client | Swift, SwiftUI, SwiftData, URLSession |
| **A9** | Notifications & Events | Go, SQS/SNS, event handlers |

---

## Phase 0: Pre-Implementation Setup

**Agents:** All
**Duration:** 1 day
**Verification Gate:** All agents confirm specs are understood and dependencies are met

### Tasks

1. All agents read and acknowledge:
   - `docs/prd/specific-features/Exercise/Exercise_Physical_Activity.md` (PRD)
   - `docs/prd/specific-features/Exercise/specs/acceptance-criteria.md` (ACs)
   - `docs/prd/specific-features/Exercise/specs/openapi.yaml` (API contract)
   - `docs/prd/specific-features/Exercise/specs/mongodb-schema.md` (data model)
   - `docs/prd/specific-features/Exercise/specs/test-specifications.md` (test plan)

2. Verify foundation dependencies:
   - [ ] Feature flag `activity.exercise` exists in the flags collection
   - [ ] MongoDB collection indexes are in place
   - [ ] Valkey is reachable from the exercise service
   - [ ] Calendar activity dual-write infrastructure exists
   - [ ] Notification system accepts exercise-type events

---

## Phase 1: Contract Tests (RED)

**Agent:** A1
**Duration:** 2-3 days
**Dependencies:** OpenAPI spec finalized
**Verification Gate:** All contract tests written and failing (RED)

### Tasks

1. **Validate OpenAPI spec**
   ```bash
   redocly lint docs/prd/specific-features/Exercise/specs/openapi.yaml --strict
   ```

2. **Write contract tests** for all 17 endpoints:
   - `POST /activities/exercise` -- request/response schema validation
   - `GET /activities/exercise` -- pagination, filtering params
   - `GET /activities/exercise/{exerciseId}` -- single resource response
   - `PATCH /activities/exercise/{exerciseId}` -- merge patch, immutable field rejection
   - `DELETE /activities/exercise/{exerciseId}` -- 204 response
   - `GET /activities/exercise/favorites` -- list response
   - `POST /activities/exercise/favorites` -- create response
   - `PUT /activities/exercise/favorites/{favoriteId}` -- replace response
   - `DELETE /activities/exercise/favorites/{favoriteId}` -- 204 response
   - `GET /activities/exercise/stats` -- period-based response
   - `GET /activities/exercise/streak` -- streak response
   - `GET /activities/exercise/correlations` -- insights response
   - `GET /activities/exercise/goals` -- goal + progress response
   - `PUT /activities/exercise/goals` -- upsert response
   - `DELETE /activities/exercise/goals` -- 204 response
   - `GET /activities/exercise/widget` -- widget response

3. **Verify error response format** matches Siemens guidelines (rr:0x code, correlationId, source pointer)

4. **Verify naming conventions:**
   - All JSON properties are camelCase
   - All URL paths are kebab-case
   - All schema names are PascalCase

### Deliverables
- `test/contract/exercise_test.go` (all RED)

---

## Phase 2: Domain Logic (RED then GREEN)

**Agent:** A2
**Duration:** 5-7 days
**Dependencies:** Phase 1 (contract tests exist for reference)
**Verification Gate:** All unit tests GREEN, 90%+ coverage, 100% on critical paths

### Tasks (in order)

#### 2.1 Exercise Log Model + Validation (Days 1-2)

Write failing tests first, then implement:

- Activity type validation (predefined enum + "other" with label)
- Duration validation (1-1440 minutes)
- Intensity validation (light/moderate/vigorous, optional)
- Timestamp validation (no future > 24h)
- Notes validation (500 char max)
- Mood before/after validation (1-5, optional)
- Immutable field enforcement (timestamp, createdAt, activityType, durationMinutes, source)
- Mutable field update (intensity, notes, mood, customTypeLabel)

**Test file:** `internal/domain/exercise/exercise_test.go`

#### 2.2 Exercise Streak Calculation (Day 3)

- Consecutive calendar day calculation from exercise log dates
- Multiple workouts per day count as one day
- Longest streak tracking across gaps
- Backdated entry handling (credit original date)
- Today exclusion (only completed days)
- Timezone-aware day boundaries
- Next milestone calculation (3, 7, 14, 21, 30, 60, 90 days)

**Test file:** `internal/domain/exercise/streak_test.go`
**Coverage requirement:** 100%

#### 2.3 Exercise Stats (Day 4)

- Weekly summary aggregation (total minutes, sessions, most common type, comparison)
- Monthly aggregation
- 90-day aggregation
- Activity type distribution
- Intensity distribution

**Test file:** `internal/domain/exercise/stats_test.go`

#### 2.4 Correlation Insights (Day 5)

- Minimum data threshold check (14 days)
- Urge frequency delta on exercise vs. non-exercise days
- Check-in score delta on exercise vs. non-exercise days
- Mood before/after improvement average
- Inactivity risk detection (days since last exercise correlated with relapse history)

**Test file:** `internal/domain/exercise/correlations_test.go`

#### 2.5 Weekly Goal (Day 5)

- Goal validation (at least one of minutes or sessions required)
- Progress calculation (higher of minutes% or sessions%)
- Goal met detection (threshold crossing)

**Test file:** `internal/domain/exercise/goals_test.go`

#### 2.6 Favorites (Day 6)

- Max 5 favorites enforcement
- Quick log creation from favorite defaults
- Custom type promotion (3 uses triggers prompt)

**Test file:** `internal/domain/exercise/favorites_test.go`

#### 2.7 Duplicate Detection (Day 6)

- Same activity type within 30-minute window detection
- External ID match detection
- Null external ID fallback to time window

**Test file:** `internal/domain/exercise/duplicate_test.go`

#### 2.8 Widget Data Assembly (Day 7)

- Today's exercise status
- Streak inclusion
- Goal progress inclusion (or null when no goal)

**Test file:** `internal/domain/exercise/widget_test.go`

### Deliverables
- `internal/domain/exercise/*.go` (all domain logic)
- `internal/domain/exercise/*_test.go` (all GREEN)

---

## Phase 3: Repository Layer

**Agent:** A3
**Duration:** 3-4 days
**Dependencies:** Phase 2 (domain types defined)
**Verification Gate:** Repository interface tests pass against mocks, integration tests written

### Tasks

#### 3.1 Repository Interface Definition (Day 1)

Define interfaces that the domain layer consumes:

```go
type ExerciseRepository interface {
    Create(ctx context.Context, log ExerciseLog) error
    GetByID(ctx context.Context, userID, exerciseID string) (*ExerciseLog, error)
    List(ctx context.Context, userID string, opts ListOptions) ([]ExerciseLog, string, error)
    Update(ctx context.Context, userID, exerciseID string, updates map[string]interface{}) error
    Delete(ctx context.Context, userID, exerciseID string) error
    GetByDateRange(ctx context.Context, userID string, start, end time.Time) ([]ExerciseLog, error)
    CountInWeek(ctx context.Context, userID string, weekStart time.Time) (int, error)
    FindDuplicates(ctx context.Context, userID string, activityType string, timestamp time.Time, externalID *string) ([]ExerciseLog, error)
}

type FavoriteRepository interface {
    Create(ctx context.Context, fav ExerciseFavorite) error
    List(ctx context.Context, userID string) ([]ExerciseFavorite, error)
    Update(ctx context.Context, userID, favoriteID string, fav ExerciseFavorite) error
    Delete(ctx context.Context, userID, favoriteID string) error
    Count(ctx context.Context, userID string) (int, error)
}

type GoalRepository interface {
    Get(ctx context.Context, userID string) (*ExerciseGoal, error)
    Upsert(ctx context.Context, userID string, goal ExerciseGoal) error
    Delete(ctx context.Context, userID string) error
}
```

#### 3.2 MongoDB Implementation (Days 2-3)

Implement repository interfaces with MongoDB driver:

- PK/SK key construction following schema-design.md patterns
- Calendar activity dual-write on create/delete
- Cursor-based pagination using SK ordering
- Date range queries using SK between
- Application-layer filtering for activityType, intensity, notes search

#### 3.3 Mock Implementations (Day 4)

Create mock repositories for use by handler unit tests.

### Deliverables
- `internal/repository/exercise_repository.go`
- `internal/repository/exercise_repository_mongo.go`
- `internal/repository/exercise_repository_mock.go`
- `internal/repository/favorite_repository.go` (+ mongo + mock)
- `internal/repository/goal_repository.go` (+ mongo + mock)

---

## Phase 4: Cache Layer

**Agent:** A5
**Duration:** 2 days
**Dependencies:** Phase 3 (repository interfaces defined)
**Verification Gate:** Cache-aside pattern works, invalidation correct

### Tasks

1. **Exercise Streak Cache**
   - Key: `exercise:streak:{userId}`
   - TTL: 5 minutes
   - Invalidation: on exercise create/delete
   - Fallback: compute from repository on cache miss

2. **Widget Cache**
   - Key: `exercise:widget:{userId}`
   - TTL: 2 minutes
   - Invalidation: on exercise create/delete, goal change

3. **Stats Cache**
   - Key: `exercise:stats:{userId}:{period}:{date}`
   - TTL: 10 minutes
   - Invalidation: on exercise create/delete

### Deliverables
- `internal/cache/exercise_cache.go`
- `internal/cache/exercise_cache_test.go`

---

## Phase 5: Handler Layer

**Agent:** A4
**Duration:** 4-5 days
**Dependencies:** Phase 2 (domain), Phase 3 (repository), Phase 4 (cache)
**Verification Gate:** All handler tests pass, contract tests pass against running handlers

### Tasks

#### 5.1 Route Registration (Day 1)

Register all exercise routes under `/activities/exercise`:
- Feature flag middleware check (`activity.exercise`)
- Auth middleware (Bearer JWT)
- Tenant isolation middleware
- Correlation ID middleware

#### 5.2 CRUD Handlers (Days 1-2)

- `POST /activities/exercise` -- createExerciseLog handler
- `GET /activities/exercise` -- listExerciseLogs handler (pagination, filtering)
- `GET /activities/exercise/{exerciseId}` -- getExerciseLog handler
- `PATCH /activities/exercise/{exerciseId}` -- updateExerciseLog handler
- `DELETE /activities/exercise/{exerciseId}` -- deleteExerciseLog handler

#### 5.3 Favorites Handlers (Day 3)

- `GET /activities/exercise/favorites`
- `POST /activities/exercise/favorites`
- `PUT /activities/exercise/favorites/{favoriteId}`
- `DELETE /activities/exercise/favorites/{favoriteId}`

#### 5.4 Stats, Streak, Correlations Handlers (Day 3-4)

- `GET /activities/exercise/stats`
- `GET /activities/exercise/streak`
- `GET /activities/exercise/correlations`

#### 5.5 Goal Handlers (Day 4)

- `GET /activities/exercise/goals`
- `PUT /activities/exercise/goals`
- `DELETE /activities/exercise/goals`

#### 5.6 Widget Handler (Day 4)

- `GET /activities/exercise/widget`

#### 5.7 Contract Test Validation (Day 5)

Run A1's contract tests against running handlers. All must pass.

### Deliverables
- `internal/handler/exercise_handler.go`
- `internal/handler/exercise_handler_test.go`

---

## Phase 6: Notifications & Events

**Agent:** A9
**Duration:** 2-3 days
**Dependencies:** Phase 5 (handlers emit events)
**Verification Gate:** Event handlers process correctly, notifications delivered

### Tasks

1. **Exercise logged event** -- published to SNS on each exercise log creation
   - Updates calendar activity (dual-write)
   - Checks weekly goal threshold crossing
   - Updates streak milestone detection

2. **Streak milestone notification**
   - Milestones: 3, 7, 14, 21, 30, 60, 90 days
   - Message: "You've exercised X days in a row!"

3. **Weekly goal achieved notification**
   - Triggered when weekly total crosses goal threshold
   - Message: "You hit your weekly exercise goal! That's X active minutes this week."

4. **Inactivity nudge** (scheduled)
   - Runs daily via scheduled Lambda
   - Checks last exercise date against user's configured inactivity threshold
   - Message: "You haven't logged any exercise in X days. Even a short walk counts."

5. **Exercise reminder** (scheduled)
   - User-configured time and days
   - Respects independent notification toggle

6. **Physical dynamic goal auto-check**
   - On exercise log creation, check if user has a physical dynamic goal
   - If so, mark the goal as completed for the day

### Deliverables
- `internal/events/exercise_event_handler.go`
- `internal/events/exercise_event_handler_test.go`

---

## Phase 7: Integration Tests

**Agent:** A6
**Duration:** 3-4 days
**Dependencies:** Phases 2-6 complete
**Verification Gate:** All integration tests pass against local Docker services

### Tasks

1. **Repository integration tests** (MongoDB)
   - Full CRUD round-trip
   - Pagination verification
   - Date range queries
   - Calendar activity dual-write verification
   - Duplicate detection

2. **Cache integration tests** (Valkey)
   - Cache-aside pattern verification
   - TTL expiry
   - Invalidation on write

3. **Handler integration tests** (HTTP + MongoDB + Valkey)
   - Full endpoint flow with real database
   - Feature flag gating
   - Auth middleware
   - Error response format validation

4. **Event processing tests** (SQS/SNS)
   - Goal completion notification trigger
   - Streak milestone notification trigger
   - Inactivity nudge scheduling

### Deliverables
- `test/integration/exercise/*.go`

---

## Phase 8: Mobile API Clients

### Phase 8A: Android Client

**Agent:** A7
**Duration:** 5-7 days (parallel with Phase 8B)
**Dependencies:** Phase 5 (API contract finalized)
**Verification Gate:** Contract tests pass, UI renders correctly, offline sync works

#### Tasks

1. **API client** -- hand-written Retrofit client matching OpenAPI spec
2. **Repository** -- Room database for offline storage
3. **ViewModel** -- exercise list, detail, stats, quick log
4. **UI screens** -- Compose screens:
   - Exercise log form (manual entry)
   - Quick log (favorites)
   - Exercise history (list + filters)
   - Exercise stats (charts)
   - Dashboard widget card
   - Weekly goal settings
5. **Offline sync** -- queue exercise logs offline, sync on reconnect
6. **Google Fit integration** -- OAuth flow, workout data import
7. **Notifications** -- handle exercise notification types

### Phase 8B: iOS Client

**Agent:** A8
**Duration:** 5-7 days (parallel with Phase 8A)
**Dependencies:** Phase 5 (API contract finalized)
**Verification Gate:** Contract tests pass, UI renders correctly, offline sync works

#### Tasks

1. **API client** -- hand-written URLSession client matching OpenAPI spec
2. **Repository** -- SwiftData for offline storage
3. **ViewModel** -- exercise list, detail, stats, quick log
4. **UI screens** -- SwiftUI views:
   - Exercise log form (manual entry)
   - Quick log (favorites)
   - Exercise history (list + filters)
   - Exercise stats (charts)
   - Dashboard widget card
   - Weekly goal settings
5. **Offline sync** -- queue exercise logs offline, sync on reconnect
6. **Apple Health integration** -- HealthKit authorization, workout data import, duplicate detection
7. **Notifications** -- handle exercise notification types

---

## Phase 9: End-to-End Tests

**Agent:** A6
**Duration:** 2-3 days
**Dependencies:** Phases 7-8 complete, staging deployed
**Verification Gate:** All E2E tests pass against staging

### Tasks

1. Full exercise logging flow (create, read, update, delete)
2. Quick log from favorite flow
3. Stats accuracy after multiple logs
4. Streak increment and reset
5. Weekly goal progress and notification
6. Widget data accuracy
7. Persona scenarios (Alex, Marcus, Diego)

### Deliverables
- `test/e2e/exercise/*.go`

---

## Dependency Graph

```
Phase 0: Setup
    |
Phase 1: Contract Tests (RED) [A1]
    |
Phase 2: Domain Logic [A2]
    |
    +---> Phase 3: Repository [A3]
    |         |
    |         +---> Phase 4: Cache [A5]
    |                   |
    +---> Phase 5: Handlers [A4] (depends on A2, A3, A5)
              |
              +---> Phase 6: Events/Notifications [A9]
              |
              +---> Phase 7: Integration Tests [A6]
              |
              +---> Phase 8A: Android Client [A7] (can start when API is stable)
              |
              +---> Phase 8B: iOS Client [A8] (can start when API is stable)
                        |
                        +---> Phase 9: E2E Tests [A6]
```

**Parallelization opportunities:**
- A7 and A8 run fully in parallel
- A7/A8 can start after Phase 5 using mock server from OpenAPI spec
- A3 and A5 can start once A2 has domain types defined (after Day 2 of Phase 2)
- A9 can start after Phase 5, parallel with A6

---

## Verification Gates Summary

| Gate | Criteria | Blocker For |
|------|----------|-------------|
| G0 | All agents confirm specs understood | Phase 1 |
| G1 | Contract tests written and RED | Phase 2 |
| G2 | All domain unit tests GREEN, 90%+ coverage | Phase 3, 4, 5 |
| G3 | Repository tests pass against mocks | Phase 5 |
| G4 | Cache invalidation verified | Phase 5 |
| G5 | Contract tests GREEN against handlers | Phase 6, 7 |
| G6 | Integration tests GREEN | Phase 8 |
| G7 | Mobile contract tests GREEN | Phase 9 |
| G8 | E2E tests GREEN on staging | PR merge |

---

## PR Strategy

Split into stacked PRs to stay under 400 lines each:

| PR | Contents | Size Est. |
|----|----------|-----------|
| PR-1 | OpenAPI spec + acceptance criteria + test specs | ~300 lines |
| PR-2 | Domain types + exercise log validation + unit tests | ~350 lines |
| PR-3 | Exercise streak calculation + unit tests | ~250 lines |
| PR-4 | Exercise stats + correlations + goals domain logic | ~350 lines |
| PR-5 | Favorites + duplicate detection + widget domain logic | ~300 lines |
| PR-6 | Repository interfaces + MongoDB implementation | ~350 lines |
| PR-7 | Cache layer + Valkey implementation | ~200 lines |
| PR-8 | HTTP handlers (CRUD) | ~350 lines |
| PR-9 | HTTP handlers (stats, streak, goals, widget, favorites) | ~350 lines |
| PR-10 | Event handlers + notifications | ~300 lines |
| PR-11 | Integration tests | ~400 lines |
| PR-12 | Android API client + repository | ~350 lines |
| PR-13 | Android UI screens | ~400 lines |
| PR-14 | Android offline sync + Google Fit | ~350 lines |
| PR-15 | iOS API client + repository | ~350 lines |
| PR-16 | iOS UI screens | ~400 lines |
| PR-17 | iOS offline sync + Apple Health | ~350 lines |
| PR-18 | E2E tests | ~300 lines |

---

## Feature Flag Configuration

```json
{
  "PK": "FLAGS",
  "SK": "activity.exercise",
  "EntityType": "FEATURE_FLAG",
  "TenantId": "SYSTEM",
  "enabled": true,
  "rolloutPercentage": 0,
  "tiers": ["*"],
  "tenants": ["*"],
  "platforms": ["ios", "android"],
  "minAppVersion": "1.3.0",
  "description": "Exercise/Physical Activity logging with stats, streaks, and recovery correlations"
}
```

**Rollout plan:**
1. `rolloutPercentage: 0` -- internal testing only
2. `rolloutPercentage: 10` -- beta users
3. `rolloutPercentage: 50` -- wider rollout
4. `rolloutPercentage: 100` -- general availability

---

## Tone and Messaging Checklist

Before shipping, verify all user-facing strings follow the PRD's tone guidelines:

- [ ] No calorie tracking, weight tracking, or body image language
- [ ] All language celebrates movement of any kind -- no intensity gatekeeping
- [ ] First-use helper text present: "Physical activity is one of the most powerful tools in recovery..."
- [ ] Post-log rotating messages present (3 compassionate messages)
- [ ] Inactivity nudge is gentle, not shaming
- [ ] Streak messaging is encouraging, not punitive on breaks
