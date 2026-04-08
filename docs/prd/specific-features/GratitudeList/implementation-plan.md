# Gratitude List: Multi-Agent Implementation Plan

**Feature:** Gratitude List Activity
**Priority:** P1 (Wave 2)
**Methodology:** Specification-Driven Development + Test-Driven Development
**Feature Flag:** `activity.gratitude`

**Specs consumed:**
- `specs/openapi.yaml` -- API contract (source of truth)
- `specs/mongodb-schema.md` -- Collection design, indexes, access patterns
- `specs/acceptance-criteria.md` -- 74 acceptance criteria (39 P0, 32 P1, 3 P2)
- `specs/test-specifications.md` -- Test names, Given/When/Then, coverage targets

---

## Build Order

### Wave 1: Foundation (sequential -- must complete before Wave 2)

#### Agent A: OpenAPI Contract Tests + Feature Flag

**Spec:** `specs/openapi.yaml`, `specs/acceptance-criteria.md` (GL-CC, GL-IN-AC10)
**Scope:**

1. Register feature flag `activity.gratitude` in the flags collection
2. Write contract tests (RED) that validate all 12 endpoints against the OpenAPI spec:
   - `TestGratitude_Contract_CreateEntry_201_MatchesSpec`
   - `TestGratitude_Contract_ListEntries_200_MatchesSpec`
   - `TestGratitude_Contract_GetEntry_200_MatchesSpec`
   - `TestGratitude_Contract_UpdateEntry_403_AfterEditWindow`
   - `TestGratitude_Contract_ToggleFavorite_200_MatchesSpec`
   - `TestGratitude_Contract_Search_200_MatchesSpec`
   - `TestGratitude_Contract_Calendar_200_MatchesSpec`
   - `TestGratitude_Contract_Streaks_200_MatchesSpec`
   - `TestGratitude_Contract_DailyPrompt_200_MatchesSpec`
   - `TestGratitude_Contract_Widget_200_MatchesSpec`
   - `TestGratitude_Contract_Share_200_MatchesSpec`
3. Write handler-level tests for cross-cutting concerns (RED):
   - `TestGratitude_GL_CC_AC1_AuthRequired`
   - `TestGratitude_GL_CC_AC2_ErrorEnvelope`
   - `TestGratitude_GL_CC_AC3_ResponseEnvelope`
   - `TestGratitude_GL_CC_AC4_CursorPagination`
   - `TestGratitude_GL_CC_AC6_CorrelationId`
   - `TestGratitude_GL_IN_AC10_FeatureFlag_Disabled`
   - `TestGratitude_GL_IN_AC10_FeatureFlag_Enabled`

**Files:**
- `test/contract/gratitude_test.go` (new)
- `internal/handler/gratitude_handler_test.go` (new)
- Feature flag seed: `GRATITUDE` entry in flags collection

**Depends on:** Nothing (Wave 0 foundation assumed complete)
**Validates:** GL-CC-AC1 through GL-CC-AC6, GL-IN-AC10
**Output:** All contract tests FAIL (RED) -- no implementation yet

---

#### Agent B: Domain Logic + Data Model (parallel with Agent A)

**Spec:** `specs/acceptance-criteria.md` (GL-DM, GL-ES validation), `specs/mongodb-schema.md`
**Scope:**

1. Write unit tests (RED) for domain validation:
   - `TestGratitude_GL_ES_AC1_MinimumOneItem`
   - `TestGratitude_GL_ES_AC1_MinimumOneItem_EmptyText`
   - `TestGratitude_GL_DM_AC1_ItemTextMaxLength`
   - `TestGratitude_GL_DM_AC1_ItemTextMaxLength_Exceeds`
   - `TestGratitude_GL_ES_AC3_UnlimitedItems`
   - `TestGratitude_GL_DM_AC3_MoodScoreRange_Valid`
   - `TestGratitude_GL_DM_AC3_MoodScoreRange_Invalid`
   - `TestGratitude_GL_DM_AC2_CategoryTagOptions_Valid`
   - `TestGratitude_GL_DM_AC2_CategoryTagOptions_Invalid`
   - `TestGratitude_GL_ES_AC14_SingleItemValid`
2. Write unit tests (RED) for edit window enforcement:
   - `TestGratitude_GL_DM_AC7_EditWindow_Within`
   - `TestGratitude_GL_DM_AC8_ReadOnlyAfter24h`
   - `TestGratitude_GL_DM_AC10_ImmutableCreatedAt`
   - `TestGratitude_GL_ES_AC11_EditWindow_UpdateRejects`
3. GREEN: Implement domain types and validation:
   - `GratitudeEntry` struct with all fields
   - `GratitudeItem` struct
   - `GratitudeCategory` enum
   - Entry validator (items min 1, text max 300, mood 1-5, category enum)
   - Edit window calculator (24h from CreatedAt)
   - Immutable timestamp enforcement

**Files:**
- `internal/domain/gratitude/types.go` (new)
- `internal/domain/gratitude/entry.go` (new)
- `internal/domain/gratitude/editwindow.go` (new)
- `internal/domain/gratitude/entry_test.go` (new)
- `internal/domain/gratitude/editwindow_test.go` (new)

**Depends on:** Nothing
**Validates:** GL-DM-AC1 through GL-DM-AC11, GL-ES-AC1 through GL-ES-AC3, GL-ES-AC14

---

#### Agent C: Prompt Library + Selection Algorithm (parallel with Agents A and B)

**Spec:** `specs/acceptance-criteria.md` (GL-PR), `specs/05-prompts.md`
**Scope:**

1. Create `gratitude-prompts.json` with 50+ prompts organized by category
2. Write unit tests (RED):
   - `TestGratitude_GL_PR_AC1_PromptCount`
   - `TestGratitude_GL_PR_AC2_DeterministicDaily`
   - `TestGratitude_GL_PR_AC2_DeterministicDaily_DifferentDay`
   - `TestGratitude_GL_PR_AC2_DeterministicDaily_DifferentUser`
   - `TestGratitude_GL_PR_AC3_CyclePrompt`
   - `TestGratitude_GL_PR_AC3_CyclePrompt_Wraps`
   - `TestGratitude_GL_PR_AC5_PromptCategories`
   - `TestGratitude_GL_PR_AC6_CategoryDistribution`
3. GREEN: Implement prompt service:
   - Load prompts from bundled JSON
   - Deterministic daily selection: `(dayOfYear + hash(userId)) % promptCount`
   - Offset cycling for "Different prompt"

**Files:**
- `content/gratitude-prompts.json` (new)
- `internal/domain/gratitude/prompts.go` (new)
- `internal/domain/gratitude/prompts_test.go` (new)

**Depends on:** Nothing
**Validates:** GL-PR-AC1 through GL-PR-AC6

---

### Verification Gate 1

**Command:** `make test-unit` (gratitude domain tests only)
**Criteria:**
- All domain logic unit tests GREEN
- All contract tests RED (no implementation yet -- expected)
- Domain code coverage >= 90%
- Edit window coverage = 100%

---

### Wave 2: Repository + Streak + Analytics (parallel -- all depend on Wave 1)

#### Agent D: Repository Layer

**Spec:** `specs/mongodb-schema.md`, `specs/acceptance-criteria.md` (GL-DM, GL-HS)
**Scope:**

1. Create MongoDB indexes per `specs/mongodb-schema.md` Section 3
2. Write integration tests (RED):
   - `TestGratitude_Repository_CreateAndRetrieve`
   - `TestGratitude_Repository_ListReverseChronological`
   - `TestGratitude_Repository_CalendarDateQuery`
   - `TestGratitude_Repository_FullTextSearch`
   - `TestGratitude_Repository_ToggleFavorite`
   - `TestGratitude_Repository_EditWindowEnforced`
   - `TestGratitude_Repository_CalendarActivityDualWrite`
   - `TestGratitude_Repository_FilterCombination`
   - `TestGratitude_Repository_StreakDistinctDates`
3. GREEN: Implement repository behind interface:
   - `GratitudeRepository` interface
   - `MongoGratitudeRepository` implementation
   - All 18 access patterns from mongodb-schema.md
   - Calendar activity dual-write on create/delete

**Files:**
- `internal/repository/gratitude_repo.go` (new)
- `internal/repository/gratitude_repo_interface.go` (new)
- `test/integration/gratitude/repository_test.go` (new)

**Depends on:** Agent B (domain types)
**Validates:** GL-DM-AC5, GL-DM-AC9, GL-HS-AC1, GL-HS-AC6, GL-HS-AC7, GL-IN-AC9

---

#### Agent E: Streak Calculation + Analytics (parallel with Agent D)

**Spec:** `specs/acceptance-criteria.md` (GL-TI)
**Scope:**

1. Write unit tests (RED):
   - `TestGratitude_GL_TI_AC1_CurrentStreak`
   - `TestGratitude_GL_TI_AC1_CurrentStreak_BrokenYesterday`
   - `TestGratitude_GL_TI_AC1_CurrentStreak_TimezoneHandling`
   - `TestGratitude_GL_TI_AC1_CurrentStreak_Empty`
   - `TestGratitude_GL_TI_AC2_LongestStreak`
   - `TestGratitude_GL_TI_AC3_TotalDays`
   - `TestGratitude_GL_TI_AC4_MultipleEntriesSameDay`
   - `TestGratitude_GL_TI_AC10_EveningReviewExcluded`
   - `TestGratitude_GL_TI_AC5_CategoryBreakdown`
   - `TestGratitude_GL_TI_AC6_ShiftTracking_SufficientData`
   - `TestGratitude_GL_TI_AC6_ShiftTracking_InsufficientData`
   - `TestGratitude_GL_TI_AC7_AvgItemsPerEntry`
2. GREEN: Implement streak calculator and analytics:
   - `CalculateStreak(dates []string, userTimezone string) -> StreakData`
   - `CalculateCategoryBreakdown(entries, period) -> []CategoryCount`
   - `CalculateShift(current30d, previous30d) -> ShiftData`
   - `CalculateAverageItems(entries) -> float64`

**Files:**
- `internal/domain/gratitude/streak.go` (new)
- `internal/domain/gratitude/analytics.go` (new)
- `internal/domain/gratitude/streak_test.go` (new)
- `internal/domain/gratitude/analytics_test.go` (new)

**Depends on:** Agent B (domain types)
**Validates:** GL-TI-AC1 through GL-TI-AC10
**Coverage:** Streak = 100%, Analytics >= 85%

---

#### Agent F: Sharing + Privacy + Permissions (parallel with Agents D and E)

**Spec:** `specs/acceptance-criteria.md` (GL-SH, GL-IN-AC8)
**Scope:**

1. Write unit tests (RED):
   - `TestGratitude_GL_SH_AC3_PrivacyFilter_ExcludesMood`
   - `TestGratitude_GL_SH_AC3_PrivacyFilter_ExcludesCategory`
   - `TestGratitude_GL_SH_AC3_PrivacyFilter_ExcludesPhoto`
   - `TestGratitude_GL_SH_AC1_ShareItem`
   - `TestGratitude_GL_SH_AC2_ShareEntry`
   - `TestGratitude_GL_IN_AC8_CommunityPermissions_SpouseAllowed`
   - `TestGratitude_GL_IN_AC8_CommunityPermissions_SponsorDenied`
   - `TestGratitude_GL_IN_AC8_CommunityPermissions_SpouseMoodExcluded`
2. GREEN: Implement sharing service:
   - `GenerateShareableContent(entry, shareType, itemId)` -- strips mood/category/photo
   - Permission check integration with existing permission checker
   - Styled graphic renderer (generates PNG via template)

**Files:**
- `internal/domain/gratitude/sharing.go` (new)
- `internal/domain/gratitude/sharing_test.go` (new)
- `internal/domain/gratitude/permissions_test.go` (new)

**Depends on:** Agent B (domain types)
**Validates:** GL-SH-AC1 through GL-SH-AC6, GL-IN-AC8
**Coverage:** Sharing/privacy = 100%

---

### Verification Gate 2

**Command:** `make test-unit && make test-integration` (gratitude tests)
**Criteria:**
- All unit tests GREEN
- All integration tests GREEN
- Contract tests still RED (handler not wired yet)
- Streak calculation coverage = 100%
- Sharing privacy coverage = 100%

---

### Wave 3: Handler Layer + Service Wiring (sequential -- depends on Wave 2)

#### Agent G: HTTP Handler + Service Layer

**Spec:** `specs/openapi.yaml`, all acceptance criteria
**Scope:**

1. Wire domain logic, repository, and analytics into a service layer
2. Implement HTTP handlers for all 12 endpoints:
   - `POST /activities/gratitude` -- create entry
   - `GET /activities/gratitude` -- list entries with filters
   - `GET /activities/gratitude/{gratitudeId}` -- get entry detail
   - `PUT /activities/gratitude/{gratitudeId}` -- update entry (24h window)
   - `DELETE /activities/gratitude/{gratitudeId}` -- delete entry (24h window)
   - `PATCH /activities/gratitude/{gratitudeId}/items/{itemId}/favorite` -- toggle favorite
   - `GET /activities/gratitude/favorites` -- list favorites
   - `GET /activities/gratitude/search?q=` -- full-text search
   - `GET /activities/gratitude/calendar?month=` -- calendar view
   - `GET /activities/gratitude/streaks?period=` -- streak and trends
   - `GET /activities/gratitude/prompts/daily?offset=` -- daily prompt
   - `GET /activities/gratitude/widget` -- dashboard widget
   - `POST /activities/gratitude/{gratitudeId}/share` -- share entry
3. Wire feature flag check middleware (`activity.gratitude`)
4. Wire Valkey caching (streak, widget, calendar)
5. Wire event publishing (streak milestones, missed nudge, goal completion)
6. Verify all contract tests now GREEN

**Files:**
- `internal/service/gratitude_service.go` (new)
- `internal/handler/gratitude_handler.go` (new)
- `internal/cache/gratitude_cache.go` (new)
- `internal/events/gratitude_events.go` (new)
- `cmd/lambda/activities/gratitude_routes.go` (new)

**Depends on:** All Wave 2 agents (D, E, F)
**Validates:** All GL-CC, GL-ES-AC9, GL-ES-AC13, GL-HS-AC1 through GL-HS-AC10, GL-IN-AC3
**Output:** All contract tests GREEN, all handler tests GREEN

---

#### Agent H: Cache + Event Integration Tests (parallel with Agent G's later work)

**Spec:** `specs/acceptance-criteria.md` (GL-IN-AC5 through GL-IN-AC9)
**Scope:**

1. Write integration tests for Valkey caching:
   - `TestGratitude_Cache_StreakCachedInValkey`
   - `TestGratitude_Cache_StreakInvalidatedOnCreate`
   - `TestGratitude_Cache_WidgetCachedInValkey`
   - `TestGratitude_Cache_CalendarInvalidatedOnCreate`
2. Write integration tests for event publishing:
   - `TestGratitude_GL_IN_AC6_StreakNotifications_Milestone7`
   - `TestGratitude_GL_IN_AC6_StreakNotifications_Milestone30`
   - `TestGratitude_GL_IN_AC7_MissedNudge`
   - `TestGratitude_GL_IN_AC5_PlanScoring`
   - `TestGratitude_GL_IN_AC9_CalendarActivity`

**Files:**
- `test/integration/gratitude/cache_test.go` (new)
- `test/integration/gratitude/events_test.go` (new)

**Depends on:** Agent G (service layer must be wired)
**Validates:** GL-IN-AC5 through GL-IN-AC9

---

### Verification Gate 3

**Command:** `make test-all && make contract-test`
**Criteria:**
- All unit tests GREEN
- All integration tests GREEN
- All contract tests GREEN
- Coverage >= 85% overall, 100% on critical paths
- `make spec-validate` passes on `specs/openapi.yaml`

---

### Wave 4: E2E Tests + iOS Client (sequential -- depends on Wave 3)

#### Agent I: E2E Tests

**Spec:** `specs/test-specifications.md` Section 4
**Scope:**

1. Write E2E tests against staging:
   - `TestGratitude_E2E_CompleteGratitudeFlow`
   - `TestGratitude_E2E_EditWindowEnforcement`
   - `TestGratitude_E2E_MultipleEntriesPerDay`
   - `TestGratitude_E2E_ShareWithSupportNetwork`
2. Verify with persona test data (Alex, Marcus)

**Files:**
- `test/e2e/gratitude/flow_test.go` (new)

**Depends on:** All Wave 3 agents, staging deployment
**Validates:** Full user flow end-to-end

---

#### Agent J: iOS SwiftUI Client (parallel with Agent I)

**Spec:** `specs/02-entry-screen.md`, `specs/03-history-screen.md`, `specs/04-trends-insights.md`
**Scope:**

1. Implement SwiftData model migration (legacy [String] to [GratitudeItem])
2. Build ViewModels:
   - `GratitudeEntryViewModel` -- entry creation, validation, save
   - `GratitudeHistoryViewModel` -- list, search, filter, calendar
   - `GratitudeTrendsViewModel` -- streaks, charts, insights
3. Build SwiftUI views:
   - `GratitudeEntryView` -- item list, category picker, mood selector, prompt card
   - `GratitudeHistoryView` -- tabbed (List/Calendar/Favorites)
   - `GratitudeDetailView` -- full entry with edit/share
   - `GratitudeTrendsView` -- streak card, charts, insights
   - `GratitudeTabView` -- container with tab navigation
   - `GratitudeWidgetCard` -- Today screen compact card
4. Write ViewModel unit tests (RED then GREEN)
5. Wire API client to backend endpoints

**Files:**
- `ios/RegalRecovery/RegalRecovery/Data/Models/GratitudeTypes.swift` (new)
- `ios/RegalRecovery/RegalRecovery/ViewModels/Gratitude*.swift` (new, 3 files)
- `ios/RegalRecovery/RegalRecovery/Views/Activities/Gratitude*.swift` (new, 5 files)
- `ios/RegalRecovery/RegalRecovery/Views/Today/GratitudeWidgetCard.swift` (new)
- `ios/RegalRecovery/RegalRecovery/Services/GratitudePromptService.swift` (new)
- `ios/RegalRecovery/RegalRecovery/Services/GratitudeSharingService.swift` (new)
- `ios/RegalRecovery/RegalRecovery/Tests/Unit/Gratitude*Tests.swift` (new, 5 files)

**Depends on:** Agent G (API endpoints available), Agent C (prompt content)
**Validates:** All GL-ES, GL-HS, GL-TI acceptance criteria (UI-level)

---

### Verification Gate 4 (Final)

**Commands:**
```bash
make spec-validate          # OpenAPI spec valid
make contract-test          # All contract tests GREEN
make test-unit              # All unit tests GREEN
make test-integration       # All integration tests GREEN
make deploy-staging         # Deploy to staging
make test-e2e               # All E2E tests GREEN
xcodebuild test -scheme RegalRecovery ...  # iOS tests GREEN
```

**Criteria:**
- All 74 acceptance criteria verified by at least one test
- Coverage >= 85% overall, 100% on critical paths (streak, edit window, sharing privacy)
- OpenAPI spec validates with 0 errors
- E2E flow completes successfully on staging
- iOS build succeeds and tests pass

---

## Agent Dispatch Summary

```
Wave 1 (parallel, no dependencies):
  Agent A: Contract Tests + Feature Flag          ┐
  Agent B: Domain Logic + Data Model              ├─ All start immediately
  Agent C: Prompt Library + Selection Algorithm    ┘

  [Verification Gate 1]

Wave 2 (parallel, depends on Wave 1):
  Agent D: Repository Layer                       ┐
  Agent E: Streak Calculation + Analytics          ├─ All depend on Agent B
  Agent F: Sharing + Privacy + Permissions         ┘

  [Verification Gate 2]

Wave 3 (sequential, depends on Wave 2):
  Agent G: HTTP Handler + Service Layer            ← Depends on D, E, F
  Agent H: Cache + Event Integration Tests         ← Depends on G

  [Verification Gate 3]

Wave 4 (parallel, depends on Wave 3):
  Agent I: E2E Tests                               ┐
  Agent J: iOS SwiftUI Client                      ┘ Both depend on G

  [Verification Gate 4 - Final]
```

**Maximum parallelism:** 3 agents (Waves 1 and 2)
**Total agents:** 10
**Estimated duration:** 4 waves with verification gates between each

---

## TDD Cycle Per Agent

Each agent follows this cycle for every acceptance criterion:

1. **Read** -- Read the relevant spec files and acceptance criteria
2. **RED** -- Write a failing test named `TestGratitude_GL_{Domain}_AC{N}_{Description}`
3. **GREEN** -- Write minimum code to make the test pass
4. **REFACTOR** -- Improve code quality, extract shared utilities
5. **BUILD** -- Verify compilation succeeds
6. **VERIFY** -- Run all tests, confirm all GREEN

---

## Dependency Graph

```
                    ┌──────────┐
                    │  Wave 0  │  (Foundation -- assumed complete)
                    │  Infra   │
                    └────┬─────┘
                         │
          ┌──────────────┼──────────────┐
          │              │              │
    ┌─────▼─────┐  ┌────▼────┐  ┌─────▼─────┐
    │  Agent A  │  │ Agent B │  │  Agent C  │
    │ Contracts │  │ Domain  │  │  Prompts  │
    └─────┬─────┘  └────┬────┘  └─────┬─────┘
          │              │              │
          │    ┌─────────┼──────────┐   │
          │    │         │          │   │
          │ ┌──▼──┐  ┌──▼──┐  ┌───▼─┐ │
          │ │  D  │  │  E  │  │  F  │ │
          │ │Repo │  │Streak│  │Share│ │
          │ └──┬──┘  └──┬──┘  └──┬──┘ │
          │    │         │       │     │
          │    └─────────┼───────┘     │
          │              │             │
          │         ┌────▼────┐        │
          └────────►│ Agent G │◄───────┘
                    │ Handler │
                    └────┬────┘
                         │
                    ┌────▼────┐
                    │ Agent H │
                    │ Cache+  │
                    │ Events  │
                    └────┬────┘
                         │
              ┌──────────┼──────────┐
              │                     │
         ┌────▼────┐          ┌────▼────┐
         │ Agent I │          │ Agent J │
         │  E2E    │          │  iOS    │
         └─────────┘          └─────────┘
```

---

## File Map

| New File | Agent | Purpose |
|----------|-------|---------|
| `test/contract/gratitude_test.go` | A | Contract tests against OpenAPI spec |
| `internal/handler/gratitude_handler_test.go` | A | Handler cross-cutting tests |
| `internal/domain/gratitude/types.go` | B | Domain types (Entry, Item, Category) |
| `internal/domain/gratitude/entry.go` | B | Entry validation logic |
| `internal/domain/gratitude/editwindow.go` | B | 24-hour edit window enforcement |
| `internal/domain/gratitude/entry_test.go` | B | Entry validation tests |
| `internal/domain/gratitude/editwindow_test.go` | B | Edit window tests |
| `content/gratitude-prompts.json` | C | 50+ curated prompts |
| `internal/domain/gratitude/prompts.go` | C | Prompt selection algorithm |
| `internal/domain/gratitude/prompts_test.go` | C | Prompt tests |
| `internal/repository/gratitude_repo.go` | D | MongoDB repository implementation |
| `internal/repository/gratitude_repo_interface.go` | D | Repository interface |
| `test/integration/gratitude/repository_test.go` | D | Repository integration tests |
| `internal/domain/gratitude/streak.go` | E | Streak calculation |
| `internal/domain/gratitude/analytics.go` | E | Category breakdown, volume trends |
| `internal/domain/gratitude/streak_test.go` | E | Streak tests (100% coverage) |
| `internal/domain/gratitude/analytics_test.go` | E | Analytics tests |
| `internal/domain/gratitude/sharing.go` | F | Privacy-filtered sharing |
| `internal/domain/gratitude/sharing_test.go` | F | Sharing privacy tests (100% coverage) |
| `internal/domain/gratitude/permissions_test.go` | F | Permission enforcement tests |
| `internal/service/gratitude_service.go` | G | Application service layer |
| `internal/handler/gratitude_handler.go` | G | HTTP handlers for all 12 endpoints |
| `internal/cache/gratitude_cache.go` | G | Valkey cache-aside for streak/widget/calendar |
| `internal/events/gratitude_events.go` | G | SNS/SQS event publishing |
| `cmd/lambda/activities/gratitude_routes.go` | G | API Gateway route registration |
| `test/integration/gratitude/cache_test.go` | H | Valkey caching integration tests |
| `test/integration/gratitude/events_test.go` | H | Event publishing integration tests |
| `test/e2e/gratitude/flow_test.go` | I | End-to-end flow tests |
| iOS files (15+ files) | J | SwiftUI views, ViewModels, services, tests |

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Legacy data migration breaks existing entries | Agent D includes migration integration test; dual-write during transition |
| Full-text search performance on large collections | Text index created before data load; monitored via MongoDB Atlas query targeting |
| Streak calculation timezone edge cases | Agent E writes explicit timezone tests with multiple locales |
| Sharing privacy leak (mood/category exposed) | Agent F has 100% coverage requirement on privacy filter; contract tests validate response shape |
| Feature flag not wired correctly | Agent A writes explicit enable/disable tests as first task |
| Calendar activity dual-write consistency | Agent D tests dual-write atomicity; compensating event on failure |
