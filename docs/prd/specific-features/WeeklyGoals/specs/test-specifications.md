# Weekly/Daily Goals -- Test Specifications

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft
**Feature Flag:** `activity.weekly-daily-goals`

---

## Test Naming Convention

All test functions reference the acceptance criterion they verify:

```
Test<Domain>_<AC-ID>_<Scenario>
```

Example: `TestGoalCreation_AC_GC_1_CreateManualGoalWithRequiredFields`

---

## 1. Unit Tests (60-70% of test budget)

Location: `internal/domain/goals/*_test.go`

### 1.1 Goal Creation and Validation

```
TestGoalCreation_AC_GC_1_CreateManualGoalWithRequiredFields
  Given valid text and dynamics array
  When createGoal is called
  Then goal is created with generated goalId, defaults applied

TestGoalCreation_AC_GC_2_RejectsEmptyText
  Given empty text field
  When createGoal is called
  Then validation error returned with code rr:0x00800001

TestGoalCreation_AC_GC_2_RejectsTextOver200Chars
  Given text with 201 characters
  When createGoal is called
  Then validation error returned with code rr:0x00800001

TestGoalCreation_AC_GC_3_RejectsEmptyDynamicsArray
  Given empty dynamics array
  When createGoal is called
  Then validation error returned with code rr:0x00800002

TestGoalCreation_AC_GC_3_RejectsNoDynamicsField
  Given no dynamics field provided
  When createGoal is called
  Then validation error returned with code rr:0x00800002

TestGoalCreation_AC_GC_4_DefaultsScopeToDaily
  Given no scope field provided
  When createGoal is called
  Then scope defaults to "daily"

TestGoalCreation_AC_GC_5_RecurrenceOneTime
  Given recurrence set to "one-time"
  When goal instances are materialized
  Then only one instance is created for the current date

TestGoalCreation_AC_GC_5_RecurrenceDaily
  Given recurrence set to "daily"
  When goal instances are materialized for a week
  Then instances are created for every day

TestGoalCreation_AC_GC_5_RecurrenceSpecificDays
  Given recurrence set to "specific-days" with ["monday", "wednesday", "friday"]
  When goal instances are materialized for a week starting Monday
  Then instances are created only for Mon, Wed, Fri

TestGoalCreation_AC_GC_5_RecurrenceWeekly
  Given recurrence set to "weekly" with dayOfWeek "wednesday"
  When goal instances are materialized for two weeks
  Then instances are created only on Wednesdays

TestGoalCreation_AC_GC_6_PrioritySorting
  Given goals with high, low, and medium priority
  When sorted within a dynamic group
  Then order is high, medium, low, with ties broken by createdAt

TestGoalCreation_AC_GC_7_RejectsNotesOver500Chars
  Given notes field with 501 characters
  When createGoal is called
  Then validation error returned

TestGoalCreation_AC_GC_8_MultipleDynamicTags
  Given dynamics ["spiritual", "relational"]
  When daily goals are grouped by dynamic
  Then goal appears in both spiritual and relational sections
```

### 1.2 Auto-Population Logic

```
TestAutoPopulation_AC_AP_1_PopulatesFromActiveCommitments
  Given user has auto-populate commitments enabled
  And commitment "Call sponsor" is active and due today
  When daily goals are materialized
  Then goal instance created with source="commitment", sourceId=commitment ID

TestAutoPopulation_AC_AP_2_PopulatesFromConfiguredActivities
  Given user has auto-populate activities enabled for ["journaling", "prayer"]
  When daily goals are materialized
  Then goal instances created with source="activity" for each

TestAutoPopulation_AC_AP_4_DismissAutoPopulatedGoalForOneDay
  Given auto-populated goal instance exists for today
  When user dismisses it
  Then status changes to "dismissed" for today only
  And same goal reappears tomorrow

TestAutoPopulation_AC_AP_5_SettingsChangeTakesEffectNextDay
  Given today's goals are already materialized
  When user changes auto-populate settings
  Then today's goals remain unchanged

TestAutoPopulation_AC_AP_6_ActivityCompletionAutoChecksGoal
  Given auto-populated goal from "journaling" activity exists
  When user completes a journal entry through the journaling flow
  Then the corresponding goal instance status becomes "completed"
```

### 1.3 Daily View Logic

```
TestDailyView_AC_DV_1_GroupsByDynamic
  Given goals tagged to spiritual, physical, and relational dynamics
  When daily goals are retrieved
  Then goals are grouped under their respective dynamics

TestDailyView_AC_DV_2_ProgressSummary
  Given 7 goals, 4 completed
  When daily summary is computed
  Then totalGoals=7, completedGoals=4

TestDailyView_AC_DV_3_DynamicBalanceIndicator
  Given goals across 5 dynamics with varying completion
  When dynamic balance is computed
  Then each dynamic shows total and completed counts

TestDailyView_AC_DV_4_CompleteGoal
  Given a pending goal instance
  When user completes it
  Then status changes to "completed", completedAt is set

TestDailyView_AC_DV_5_UncompleteGoal
  Given a completed goal instance
  When user uncompletes it
  Then status reverts to "pending", completedAt is cleared
```

### 1.4 Dynamic Gap Nudge Logic

```
TestNudge_AC_DN_1_ShowsNudgeForEmptyDynamic
  Given no goals exist for "intellectual" dynamic today
  And nudges are enabled
  When daily goals are retrieved
  Then nudge message includes "intellectual"

TestNudge_AC_DN_2_DismissedNudgeDoesNotReappear
  Given nudge for "intellectual" was dismissed today
  When daily goals are retrieved again
  Then no nudge for "intellectual" is returned

TestNudge_AC_DN_3_NudgeDisabledPerDynamic
  Given user has disabled nudges for "physical"
  And no physical goals exist today
  When daily goals are retrieved
  Then no nudge for "physical" is returned

TestNudge_AC_DN_3_AllNudgesDisabled
  Given user has disabled all nudges
  When daily goals are retrieved
  Then no nudges are returned regardless of empty dynamics
```

### 1.5 End-of-Day Review Logic

```
TestDailyReview_AC_ED_2_UncompletedGoalDisposition
  Given uncompleted goals exist
  When user submits dispositions
  Then each goal disposition is validated as carry-to-tomorrow, skipped, or no-longer-relevant

TestDailyReview_AC_ED_3_CarryToTomorrow
  Given user selects "carry-to-tomorrow" for an uncompleted goal
  When daily review is submitted
  Then a new goal instance is created for tomorrow with carriedFrom set

TestDailyReview_AC_ED_5_ReflectionStored
  Given user submits a reflection with the daily review
  When review is saved
  Then reflection text is stored in the review record
```

### 1.6 End-of-Week Review Logic

```
TestWeeklyReview_AC_EW_2_StatsComputation
  Given a week's goal instances with varying completion
  When weekly stats are computed
  Then totalGoals, completedGoals, completionRate, strongestDynamic, weakestDynamic are correct

TestWeeklyReview_AC_EW_2_PreviousWeekComparison
  Given current week completion rate is 66.7% and previous week was 55%
  When comparison is computed
  Then change is +11.7 percentage points

TestWeeklyReview_AC_EW_2_WeakestDynamic_NoGoalsSet
  Given "intellectual" has 0 goals for the week
  When weakest dynamic is determined
  Then "intellectual" is the weakest (no goals set takes priority over low completion)
```

### 1.7 Trends and Insights

```
TestTrends_AC_TI_1_CompletionRateOverTime
  Given 30 days of goal instance data
  When trends are computed for 30d period
  Then daily completion rates are returned as an array of date/rate pairs

TestTrends_AC_TI_2_PerDynamicTrends
  Given goal instances across multiple dynamics over 30 days
  When per-dynamic trends are computed
  Then separate trend arrays are returned per dynamic

TestTrends_AC_TI_3_ConsistencyScore
  Given 30 days of data; 20 days have goals completed across 3+ dynamics
  When consistency score is computed
  Then score is 66.7% (20/30)

TestTrends_AC_TI_4_AllGoalsCompletedStreak
  Given 5 consecutive days with all goals completed, then 1 day incomplete
  When streak is computed
  Then allGoalsCompleted streak is 5

TestTrends_AC_TI_4_WeeklyEightyPercentStreak
  Given 3 consecutive weeks with 80%+ completion, then 1 week at 70%
  When streak is computed
  Then weeklyEightyPercent streak is 3
```

### 1.8 Edge Cases

```
TestEdgeCase_AC_EC_1_NoGoalsSetForDay
  Given user has no goals for today
  When daily goals are retrieved
  Then empty goals array returned; no errors

TestEdgeCase_AC_EC_2_DisableRecurringGoal
  Given a recurring goal with past completion data
  When user sets isActive=false
  Then future instances stop generating; past data preserved

TestEdgeCase_AC_EC_4_FeatureFlagDisabled
  Given feature flag activity.weekly-daily-goals is disabled
  When any goal endpoint is called
  Then 404 Not Found is returned
```

### 1.9 Integration Point Logic

```
TestIntegration_AC_IP_2_CommitmentCrossReference
  Given goal is tied to commitment cm_77777
  When goal is marked completed
  Then corresponding commitment completion is triggered

TestIntegration_AC_IP_4_PostMortemActionItemsAutoPopulate
  Given post-mortem analysis produces action items
  When goal auto-population runs
  Then action items appear as goal instances with source="post-mortem"
```

---

## 2. Integration Tests (20-30% of test budget)

Location: `test/integration/goals/`

### 2.1 Repository Tests

```
TestGoalRepository_CreateAndRetrieveGoalDefinition
  Given MongoDB with LocalStack
  When a goal definition is created
  Then it can be retrieved by PK+SK

TestGoalRepository_ListActiveGoals_FiltersInactive
  Given 5 goal definitions, 2 inactive
  When listing active goals
  Then 3 goals returned

TestGoalRepository_MaterializeGoalInstances_Daily
  Given 3 active daily goals
  When instances are materialized for 2026-04-07
  Then 3 instances with correct date prefix in SK

TestGoalRepository_GetDailyInstances_RangeQuery
  Given instances for 2026-04-05 through 2026-04-10
  When querying for 2026-04-07
  Then only 2026-04-07 instances returned

TestGoalRepository_GetWeeklyInstances_RangeQuery
  Given instances for a full month
  When querying for week of 2026-04-06 to 2026-04-12
  Then only instances within that week returned

TestGoalRepository_CompleteGoalInstance_UpdatesStatus
  Given a pending goal instance
  When complete is called
  Then status=completed and completedAt set in DB

TestGoalRepository_SubmitDailyReview_CreatesReviewDocument
  Given review data with dispositions
  When review is submitted
  Then WDGREVIEW#DAILY#<date> document exists

TestGoalRepository_CarryGoal_CreatesTomorrowInstance
  Given carry-to-tomorrow disposition
  When daily review is processed
  Then new instance exists for tomorrow with carriedFrom set

TestGoalRepository_DualWriteCalendarActivity
  Given goal instance is completed
  When completion is saved
  Then ACTIVITY#<date>#GOAL_COMPLETED#<timestamp> exists in calendar activities

TestGoalRepository_HistoryQuery_TextSearch
  Given multiple goal instances with various text
  When searching for "prayer"
  Then matching instances returned
```

### 2.2 Auto-Population Integration

```
TestAutoPopulationIntegration_CommitmentsPopulated
  Given user settings with autoPopulateCommitments=true
  And active commitment in DB
  When materialization runs
  Then goal instance created referencing commitment

TestAutoPopulationIntegration_SettingsRespected
  Given user settings with specific commitment IDs
  When materialization runs
  Then only those specific commitments are populated
```

### 2.3 Valkey Cache Tests

```
TestGoalCache_DailyGoalsCached
  Given daily goals for today are fetched
  When same date is fetched again within TTL
  Then result served from Valkey cache

TestGoalCache_CompletionInvalidatesCache
  Given cached daily goals
  When a goal is completed
  Then cache is invalidated and fresh data returned on next fetch
```

---

## 3. E2E Tests (5-10% of test budget)

Location: `test/e2e/goals/`

### 3.1 Full Goal Lifecycle

```
TestE2E_GoalLifecycle_CreateViewCompleteReview
  Given authenticated user (persona: Alex)
  When user creates a daily goal tagged to spiritual
  And views today's goals
  And completes the goal
  And submits end-of-day review
  Then goal appears in daily view
  And progress summary reflects completion
  And review record is persisted
  And calendar activity is written

TestE2E_WeeklyGoalLifecycle
  Given authenticated user (persona: Marcus)
  When user creates a weekly goal "Attend 3 meetings"
  And views this week's goals
  And completes the goal mid-week
  Then weekly summary reflects completion
  And weekly review shows correct stats
```

### 3.2 Auto-Population E2E

```
TestE2E_AutoPopulation_CommitmentsAppearAsGoals
  Given user with active commitments and auto-populate enabled
  When user views today's goals
  Then commitment-sourced goals appear with correct source/sourceId
  And are visually distinguishable in response

TestE2E_AutoPopulation_ActivityCompletion_AutoChecks
  Given user with auto-populated goal from journaling
  When user submits a journal entry via /activities/journals
  Then the corresponding goal instance is automatically completed
```

### 3.3 Support Network Access

```
TestE2E_SponsorView_AC_IP_3_WithPermission
  Given sponsor with goals permission granted
  When sponsor calls /activities/weekly-daily-goals/users/{userId}/summary
  Then user's goal completion patterns are returned

TestE2E_SponsorView_AC_IP_3_WithoutPermission
  Given sponsor without goals permission
  When sponsor calls /activities/weekly-daily-goals/users/{userId}/summary
  Then 404 Not Found returned (hides data existence)
```

### 3.4 Feature Flag Gating

```
TestE2E_FeatureFlag_AC_EC_4_Disabled
  Given feature flag activity.weekly-daily-goals is disabled
  When any goal endpoint is called
  Then 404 Not Found returned

TestE2E_FeatureFlag_AC_EC_4_Enabled
  Given feature flag activity.weekly-daily-goals is enabled
  When goal endpoints are called
  Then normal responses returned
```

### 3.5 Offline Sync (Mobile-Level)

```
TestE2E_OfflineSync_AC_EC_3_GoalCreatedOffline
  Given user creates a goal while offline
  When connection is restored and sync occurs
  Then goal appears in server-side data

TestE2E_OfflineSync_AC_EC_3_GoalCompletedOffline
  Given user completes a goal while offline
  When connection is restored and sync occurs
  Then completion status and timestamp are persisted
```

### 3.6 Trends and Export

```
TestE2E_Trends_ReturnsCompletionData
  Given user with 30 days of goal data
  When GET /activities/weekly-daily-goals/trends?period=30d
  Then response includes dailyCompletionRates, dynamicTrends, consistencyScore, streaks

TestE2E_Export_CSV
  Given user requests CSV export
  When POST /activities/weekly-daily-goals/history/export with format=csv
  Then 202 Accepted returned with export job ID
```

---

## 4. Contract Tests

Location: `test/contract/goals/`

### 4.1 OpenAPI Schema Validation

```
TestContract_CreateGoal_RequestMatchesSpec
  Validate CreateWeeklyDailyGoalRequest against openapi.yaml schema

TestContract_CreateGoal_ResponseMatchesSpec
  Validate WeeklyDailyGoalResponse against openapi.yaml schema

TestContract_DailyGoals_ResponseMatchesSpec
  Validate DailyGoalsResponse against openapi.yaml schema

TestContract_WeeklyGoals_ResponseMatchesSpec
  Validate WeeklyGoalsResponse against openapi.yaml schema

TestContract_GoalTrends_ResponseMatchesSpec
  Validate GoalTrendsResponse against openapi.yaml schema

TestContract_GoalHistory_PaginationMatchesSpec
  Validate cursor-based pagination in GoalHistoryResponse

TestContract_ErrorResponses_MatchSpec
  Validate 400, 401, 404, 422 error responses match ErrorResponse schema

TestContract_AllEndpoints_RequireBearerAuth
  Validate all goal endpoints require bearerAuth security scheme
```

---

## 5. Coverage Requirements

| Scope | Target |
|-------|--------|
| Overall goals domain | >= 80% line coverage |
| Goal instance materialization logic | 100% branch coverage |
| Auto-population logic | 100% branch coverage |
| Dynamic balance calculation | 100% branch coverage |
| Trend computation (consistency score, streaks) | 100% branch coverage |
| Permission checking for sponsor view | 100% branch coverage |
| Feature flag gating | 100% branch coverage |

---

## 6. Persona Test Fixtures

### Alex (Established Recovery)
- 15 active goal definitions across all 5 dynamics
- Daily recurrence for spiritual and physical goals
- Auto-populate from commitments enabled
- 30+ days of goal history with 75% average completion
- Has sponsor with goals permission granted

### Marcus (Early Recovery, No Sponsor)
- 5 goal definitions, mostly spiritual and relational
- No auto-population configured
- 10 days of goal history with inconsistent completion
- No support network configured

### Diego (Bilingual, Spouse Present)
- 10 goal definitions with relational emphasis
- Auto-populate from both commitments and activities
- Weekly goals for meeting attendance
- Spouse has goals visibility
