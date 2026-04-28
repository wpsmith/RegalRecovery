# Nutrition Activity -- Test Specifications

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft

---

## Overview

Test specifications for the Nutrition Activity, organized by test layer (unit, integration, E2E). Every test name references its acceptance criterion ID from `acceptance-criteria.md`. Tests follow the project's spec-driven, test-first methodology.

---

## 1. Unit Tests (60-70% of test budget)

**Location:** `internal/domain/nutrition/*_test.go`

### 1.1 Meal Log Validation

```
TestMealLog_FR_NUT_1_1_MealTypeRequired
  Given: CreateMealLogRequest with mealType omitted
  Then: Returns validation error "mealType is required"

TestMealLog_FR_NUT_1_2_StandardMealTypesAccepted
  Given: CreateMealLogRequest with mealType="breakfast"
  Then: Validation passes

TestMealLog_FR_NUT_1_2_OtherMealTypeRequiresCustomLabel
  Given: CreateMealLogRequest with mealType="other", customMealLabel omitted
  Then: Returns validation error "customMealLabel required when mealType is other"

TestMealLog_FR_NUT_1_2_OtherMealTypeWithLabel
  Given: CreateMealLogRequest with mealType="other", customMealLabel="post-workout shake"
  Then: Validation passes

TestMealLog_FR_NUT_1_3_DescriptionRequired
  Given: CreateMealLogRequest with description omitted
  Then: Returns validation error "description is required"

TestMealLog_FR_NUT_1_4_DescriptionMaxLength
  Given: CreateMealLogRequest with description of 301 characters
  Then: Returns validation error "description exceeds 300 character limit"

TestMealLog_FR_NUT_1_5_TimestampDefaultsToNow
  Given: CreateMealLogRequest without timestamp
  Then: Entry created with timestamp equal to current server time (within 5s tolerance)

TestMealLog_FR_NUT_1_6_BackdatingAllowed
  Given: CreateMealLogRequest with timestamp 2 hours in the past
  Then: Entry created with the provided past timestamp

TestMealLog_FR_NUT_1_7_EatingContextValidValues
  Given: CreateMealLogRequest with eatingContext="homemade"
  Then: Validation passes
  Given: CreateMealLogRequest with eatingContext="invalid_value"
  Then: Returns validation error "invalid eatingContext"

TestMealLog_FR_NUT_1_8_MoodBeforeRange
  Given: CreateMealLogRequest with moodBefore=0
  Then: Returns validation error "moodBefore must be between 1 and 5"
  Given: CreateMealLogRequest with moodBefore=6
  Then: Returns validation error "moodBefore must be between 1 and 5"
  Given: CreateMealLogRequest with moodBefore=3
  Then: Validation passes

TestMealLog_FR_NUT_1_9_MoodAfterRange
  Given: CreateMealLogRequest with moodAfter=0
  Then: Returns validation error
  Given: CreateMealLogRequest with moodAfter=5
  Then: Validation passes

TestMealLog_FR_NUT_1_10_MindfulnessCheckValues
  Given: CreateMealLogRequest with mindfulnessCheck="yes"
  Then: Validation passes
  Given: CreateMealLogRequest with mindfulnessCheck="invalid"
  Then: Returns validation error

TestMealLog_FR_NUT_1_11_NotesMaxLength
  Given: CreateMealLogRequest with notes of 501 characters
  Then: Returns validation error "notes exceeds 500 character limit"

TestMealLog_FR_NUT_1_13_MinimalValidEntry
  Given: CreateMealLogRequest with only mealType="lunch" and description="Sandwich"
  Then: Entry created, all optional fields are nil
```

### 1.2 Quick Log Validation

```
TestQuickLog_FR_NUT_2_1_OnlyMealTypeRequired
  Given: Quick log request with only mealType="breakfast"
  Then: Entry created with isQuickLog=true, description=nil, timestamp=now

TestQuickLog_FR_NUT_2_2_ExpandQuickLog
  Given: Existing quick log entry
  When: Update with description="Eggs and toast", moodBefore=3
  Then: Fields updated, isQuickLog remains true
```

### 1.3 Immutable Timestamp

```
TestMealLog_FR_NUT_1_14_TimestampImmutable
  Given: Existing meal log created at 2026-03-28T12:00:00Z
  When: Update request includes timestamp=2026-03-29T12:00:00Z
  Then: Error returned with code "rr:0x00040002", timestamp unchanged

TestMealLog_FR_NUT_1_14_OtherFieldsUpdatable
  Given: Existing meal log
  When: Update request includes description="Updated meal", notes="New notes"
  Then: description and notes updated, timestamp unchanged
```

### 1.4 Hydration Logic

```
TestHydration_FR_NUT_3_1_IncrementServing
  Given: Today's hydration at 4 servings
  When: Add 1 serving
  Then: servingsLogged=5, totalOunces recalculated

TestHydration_FR_NUT_3_2_DecrementServing
  Given: Today's hydration at 3 servings
  When: Remove 1 serving
  Then: servingsLogged=2

TestHydration_FR_NUT_3_2_DecrementAtZero
  Given: Today's hydration at 0 servings
  When: Remove 1 serving
  Then: servingsLogged remains 0

TestHydration_FR_NUT_3_3_ConfigurableServingSize
  Given: User's serving size is 16 oz
  When: Add 1 serving
  Then: totalOunces increases by 16

TestHydration_FR_NUT_3_4_DefaultServingSize
  Given: User has no custom serving size configured
  Then: Default serving size is 8 oz

TestHydration_FR_NUT_3_5_DailyTargetConfigurable
  Given: User sets dailyTargetServings=10
  When: 9 servings logged
  Then: goalMet=false, goalProgressPercent=90

TestHydration_FR_NUT_3_6_DefaultDailyTarget
  Given: User has no custom target configured
  Then: Default target is 8 servings (64 oz)

TestHydration_FR_NUT_3_7_ServingSizeChangePreservesHistory
  Given: User logged 4 servings at 8 oz (32 oz total) on Monday
  When: User changes serving size to 16 oz on Tuesday
  Then: Monday's record still shows servingSizeOz=8, totalOunces=32

TestHydration_FR_NUT_3_8_DateBoundary
  Given: User's timezone is America/New_York
  When: Log water at 2026-03-28T23:59:00-04:00
  Then: Counts toward 2026-03-28
  When: Log water at 2026-03-29T00:01:00-04:00
  Then: Counts toward 2026-03-29
```

### 1.5 Calendar View Logic

```
TestCalendar_FR_NUT_5_2_GreenCompleteness
  Given: A day with 3 meals logged and hydration goal met
  Then: completeness="green"

TestCalendar_FR_NUT_5_3_YellowCompleteness_FewMeals
  Given: A day with 2 meals logged and hydration goal not met
  Then: completeness="yellow"

TestCalendar_FR_NUT_5_3_YellowCompleteness_PartialHydration
  Given: A day with 0 meals logged but hydration at 60%
  Then: completeness="yellow"

TestCalendar_FR_NUT_5_4_GrayCompleteness
  Given: A day with 0 meals logged and no hydration
  Then: completeness="gray"
```

### 1.6 Trends Calculation

```
TestTrends_FR_NUT_7_1_MealsPerDay
  Given: 7 days of meal data with varying counts
  Then: Correct daily counts and breakdown by meal type returned

TestTrends_FR_NUT_7_2_MealRegularity
  Given: 30 days of data where breakfast logged 20 days
  Then: breakfast percentage = 66.7%

TestTrends_FR_NUT_7_3_GapDetection
  Given: Breakfast skipped 5 of last 7 days
  Then: Insight returned with type="gap-detection" and message about breakfast pattern

TestTrends_FR_NUT_8_1_MoodBeforeAfterComparison
  Given: 15 meals with mood data, average moodBefore=2.5, average moodAfter=3.8
  Then: averageMoodBefore=2.5, averageMoodAfter=3.8, moodImprovementPercent calculated

TestTrends_FR_NUT_8_2_MoodToMealCorrelation
  Given: On low-mood days (moodBefore<=2), 80% of meals are "takeout" or "on-the-go"
  Then: Insight returned noting correlation

TestMindfulness_Trend_Direction
  Given: This month 65% mindful, last month 50% mindful
  Then: trendDirection="improving"
```

### 1.7 Eating Disorder Safeguards

```
TestEDSafeguard_FR_NUT_11_1_NoCalorieFields
  Given: MealLog schema
  Then: No field named "calories", "calorieCount", or "macros" exists

TestEDSafeguard_FR_NUT_11_5_ConcerningPatternDetection
  Given: User logged 0-1 meals per day for 7 consecutive days
  Then: ConcerningPattern flag is set, gentle prompt content generated
  Then: No automated support network alert is triggered

TestEDSafeguard_FR_NUT_11_6_SkippedMealsNeutral
  Given: User logs eatingContext="skipped" for lunch
  Then: Entry saved normally, no negative message or flag generated
```

### 1.8 Feature Flag

```
TestFeatureFlag_FR_NUT_16_1_DisabledReturns404
  Given: activity.nutrition flag is disabled for user
  When: Any nutrition endpoint is called
  Then: Returns 404 Not Found

TestFeatureFlag_FR_NUT_16_2_RolloutPercentage
  Given: activity.nutrition flag has rolloutPercentage=50
  When: 1000 users evaluated
  Then: ~500 users have access (within 5% tolerance)
```

---

## 2. Integration Tests (20-30% of test budget)

**Location:** `test/integration/nutrition/`
**Dependencies:** MongoDB (local), Valkey (local), Docker Compose

### 2.1 Repository Tests

```
TestMealLogRepository_CreateAndRetrieve
  Given: Valid meal log document
  When: Inserted into mealLogs collection
  Then: Retrievable by userId and mealId

TestMealLogRepository_ListByDateRange
  Given: 10 meal logs spanning 5 days
  When: Query for 3-day range
  Then: Only entries in that range returned, sorted desc

TestMealLogRepository_FilterByMealType
  Given: Meals of types breakfast, lunch, dinner
  When: Filter by mealType="breakfast"
  Then: Only breakfast entries returned

TestMealLogRepository_TextSearch
  Given: Meals with descriptions "chicken salad", "pasta carbonara", "grilled chicken"
  When: Search for "chicken"
  Then: 2 results returned

TestMealLogRepository_UpdatePreservesTimestamp
  Given: Existing meal log
  When: Update description via updateOne
  Then: SK (timestamp) unchanged, ModifiedAt updated

TestMealLogRepository_Delete
  Given: Existing meal log
  When: Delete by mealId
  Then: Document removed from mealLogs AND calendarActivities

TestHydrationRepository_UpsertDaily
  Given: No hydration record for today
  When: First water log
  Then: New document created with servingsLogged=1

TestHydrationRepository_IncrementExisting
  Given: Hydration record with servingsLogged=3
  When: Add 1 serving
  Then: servingsLogged=4, new entry appended to entries array

TestHydrationRepository_HistoryRange
  Given: 30 days of hydration data
  When: Query for 7-day range
  Then: 7 documents returned

TestNutritionSettingsRepository_CreateDefaults
  Given: New user with no nutrition settings
  When: First access
  Then: Default settings document created with all defaults

TestNutritionSettingsRepository_UpdateMerge
  Given: Existing settings with default hydration
  When: Patch hydration.servingSizeOz=16
  Then: Only servingSizeOz changes; all other settings preserved
```

### 2.2 Calendar Dual-Write Tests

```
TestCalendarDualWrite_MealCreated
  Given: New meal log created
  Then: Corresponding ACTIVITY entry exists in calendarActivities
  Then: activityType="NUTRITION", summary.mealType matches

TestCalendarDualWrite_MealDeleted
  Given: Existing meal log with calendar entry
  When: Meal log deleted
  Then: Calendar activity entry also deleted

TestCalendarDualWrite_MonthQuery
  Given: 20 meal logs across March 2026
  When: Query calendar for March 2026
  Then: All 20 NUTRITION activities returned
```

### 2.3 Aggregation Pipeline Tests

```
TestAggregation_MealCountsByDay
  Given: 30 days of meal data
  When: Aggregate meal counts grouped by date
  Then: Correct count per day with meal type breakdown

TestAggregation_MoodAverages
  Given: 20 meals with moodBefore and moodAfter data
  When: Aggregate averages
  Then: Correct averages computed

TestAggregation_EatingContextDistribution
  Given: 30 meals with mixed eating contexts
  When: Group by eatingContext
  Then: Correct percentage distribution
```

---

## 3. End-to-End Tests (5-10% of test budget)

**Location:** `test/e2e/nutrition/`
**Dependencies:** Deployed staging environment

### 3.1 Full Meal Logging Flow

```
TestE2E_MealLogging_CreateReadUpdateDelete
  Given: Authenticated user (Alex persona)
  When: POST /activities/nutrition/meals with full payload
  Then: 201 Created, Location header set
  When: GET /activities/nutrition/meals/{mealId}
  Then: 200 OK, all fields match
  When: PATCH /activities/nutrition/meals/{mealId} with updated notes
  Then: 200 OK, notes updated, timestamp unchanged
  When: DELETE /activities/nutrition/meals/{mealId}
  Then: 204 No Content
  When: GET /activities/nutrition/meals/{mealId}
  Then: 404 Not Found

TestE2E_QuickLog_CreateAndExpand
  Given: Authenticated user
  When: POST /activities/nutrition/meals/quick with mealType=breakfast
  Then: 201 Created, isQuickLog=true, description=null
  When: PATCH /activities/nutrition/meals/{mealId} with description and mood
  Then: 200 OK, fields populated, isQuickLog=true
```

### 3.2 Hydration Flow

```
TestE2E_Hydration_AddAndRemoveServings
  Given: Authenticated user
  When: POST /activities/nutrition/hydration/log with action=add
  Then: 200 OK, servingsLogged incremented
  When: POST /activities/nutrition/hydration/log with action=remove
  Then: 200 OK, servingsLogged decremented
  When: GET /activities/nutrition/hydration
  Then: 200 OK, correct totals shown

TestE2E_Hydration_GoalCompletion
  Given: User with dailyTargetServings=8
  When: Log 8 servings
  Then: goalMet=true, goalProgressPercent=100
```

### 3.3 Calendar and Trends

```
TestE2E_Calendar_MonthView
  Given: User with 7 days of meal and hydration data
  When: GET /activities/nutrition/calendar?year=2026&month=3
  Then: 200 OK, each day has correct mealsLogged, hydrationGoalMet, completeness

TestE2E_Trends_SevenDayPeriod
  Given: User with 7 days of varied meal data
  When: GET /activities/nutrition/trends?period=7d
  Then: 200 OK, mealConsistency, eatingContext, mindfulness trends returned

TestE2E_WeeklySummary
  Given: User with current week and previous week data
  When: GET /activities/nutrition/trends/weekly-summary
  Then: 200 OK, comparison includes direction
```

### 3.4 Settings

```
TestE2E_Settings_UpdateHydrationGoal
  Given: Authenticated user
  When: PATCH /activities/nutrition/settings with hydration.dailyTargetServings=10
  Then: 200 OK
  When: GET /activities/nutrition/settings
  Then: dailyTargetServings=10

TestE2E_Settings_EnableMealReminder
  Given: Authenticated user
  When: PATCH /activities/nutrition/settings with mealReminders.breakfast.enabled=true
  Then: 200 OK
```

### 3.5 Error Cases

```
TestE2E_MealLog_ImmutableTimestamp
  Given: Existing meal log
  When: PATCH with timestamp field
  Then: 422 Unprocessable Entity with code "rr:0x00040002"

TestE2E_MealLog_InvalidMealType
  Given: POST with mealType="invalid"
  Then: 422 Unprocessable Entity

TestE2E_FeatureFlag_Disabled
  Given: activity.nutrition flag disabled for test user
  When: Any nutrition endpoint called
  Then: 404 Not Found
```

### 3.6 Permission and Privacy

```
TestE2E_SupportNetwork_NutritionExcludedByDefault
  Given: User with a sponsor contact (accepted, no nutrition permission)
  When: Sponsor requests user's nutrition data
  Then: 404 Not Found (data existence hidden)

TestE2E_SupportNetwork_NutritionWithPermission
  Given: User grants sponsor "nutrition" read permission
  When: Sponsor requests user's meal logs
  Then: 200 OK, meal data returned
```

---

## 4. Contract Tests

**Location:** `test/contract/nutrition/`

```
TestContract_CreateMealLog_MatchesOpenAPISpec
  Validate: POST /activities/nutrition/meals request and 201 response match openapi.yaml schema

TestContract_ListMealLogs_MatchesOpenAPISpec
  Validate: GET /activities/nutrition/meals 200 response matches openapi.yaml schema

TestContract_GetHydration_MatchesOpenAPISpec
  Validate: GET /activities/nutrition/hydration 200 response matches openapi.yaml schema

TestContract_LogHydration_MatchesOpenAPISpec
  Validate: POST /activities/nutrition/hydration/log request and 200 response match schema

TestContract_GetCalendar_MatchesOpenAPISpec
  Validate: GET /activities/nutrition/calendar 200 response matches schema

TestContract_GetTrends_MatchesOpenAPISpec
  Validate: GET /activities/nutrition/trends 200 response matches schema

TestContract_GetSettings_MatchesOpenAPISpec
  Validate: GET /activities/nutrition/settings 200 response matches schema

TestContract_ErrorResponses_MatchSiemensFormat
  Validate: All 4xx and 5xx responses follow Siemens error object structure with rr:0x error codes
```

---

## 5. Mobile Client Tests

### 5.1 Android (Kotlin)

**Location:** `androidApp/app/src/test/java/com/regalrecovery/nutrition/`

```
TestNutritionViewModel_LoadMeals_DisplaysInReverseChronological
TestNutritionViewModel_QuickLog_SetsIsQuickLogTrue
TestNutritionViewModel_HydrationIncrement_UpdatesProgressBar
TestNutritionViewModel_OfflineMode_QueuesForSync
TestNutritionConflictResolver_UnionMergeMealLogs
TestNutritionConflictResolver_LWWHydration
```

### 5.2 iOS (Swift)

**Location:** `iosApp/RegalRecoveryTests/Nutrition/`

```
TestNutritionViewModel_LoadMeals_DisplaysInReverseChronological
TestNutritionViewModel_QuickLog_SetsIsQuickLogTrue
TestNutritionViewModel_HydrationIncrement_UpdatesProgressBar
TestNutritionViewModel_OfflineMode_QueuesForSync
TestNutritionConflictResolver_UnionMergeMealLogs
TestNutritionConflictResolver_LWWHydration
```

---

## 6. Coverage Requirements

| Scope | Target |
|-------|--------|
| `internal/domain/nutrition/` | 90% line coverage |
| Meal validation logic | 100% branch coverage |
| Hydration calculation logic | 100% branch coverage |
| Calendar completeness calculation | 100% branch coverage |
| Trends aggregation | 90% line coverage |
| ED safeguard checks | 100% branch coverage |
| Feature flag gating | 100% branch coverage |
| Overall nutrition module | 80% line coverage |

---

## Related Documents

- [Acceptance Criteria](./acceptance-criteria.md)
- [OpenAPI Spec](./openapi.yaml)
- [MongoDB Schema](./mongodb-schema.md)
- [Test Strategy (project-wide)](../../../../docs/specs/testing/test-strategy.md)
