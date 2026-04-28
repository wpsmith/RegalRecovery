# Devotionals -- Test Specifications

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft
**Feature Flag:** `activity.devotionals`

---

## Overview

Test specifications for the Devotionals activity, organized by the test pyramid: unit (70%), integration (20%), E2E (10%). Each test name references its acceptance criterion ID.

---

## 1. Unit Tests (Domain Logic)

### 1.1 Devotional Content Selection

**Location:** `internal/domain/devotionals/selector_test.go`

```
TestSelector_AC_DEV_CONTENT_02_FreemiumRotationReturnsCorrectDay
  Given: Free-tier user, current rotation day index = 7
  When: GetTodayDevotional called
  Then: Returns devotional with freemiumRotationDay=7

TestSelector_AC_DEV_CONTENT_03_FreemiumRotationResetsAfter30
  Given: Free-tier user, rotation day index = 31
  When: GetTodayDevotional called
  Then: Returns devotional with freemiumRotationDay=1 (mod 30 + 1)

TestSelector_AC_DEV_READ_03_UsesUserTimezoneForDayBoundary
  Given: User timezone America/Los_Angeles, server time 2026-04-08T06:30:00Z (11:30 PM PST on Apr 7)
  When: GetTodayDevotional called
  Then: Returns devotional for April 7 (user's local date)

TestSelector_AC_DEV_EDGE_01_PostMidnightShowsCurrentDay
  Given: User timezone America/New_York, local time 1:00 AM on April 8
  When: GetTodayDevotional called
  Then: Returns devotional for April 8

TestSelector_PremiumUserWithActiveSeries_ReturnsSeriesDay
  Given: Premium user with active series at day 38
  When: GetTodayDevotional called
  Then: Returns devotional from that series at day 38

TestSelector_PremiumUserNoActiveSeries_FallsBackToFreeRotation
  Given: Premium user with no active series
  When: GetTodayDevotional called
  Then: Returns devotional from freemium rotation
```

### 1.2 Devotional Completion

**Location:** `internal/domain/devotionals/completion_test.go`

```
TestCompletion_AC_DEV_REFLECT_01_SavesReflectionWithCompletion
  Given: Devotional ID and reflection text
  When: CreateCompletion called with reflection
  Then: Completion record includes reflection text

TestCompletion_AC_DEV_REFLECT_02_AcceptsUnlimitedReflectionText
  Given: Reflection text of 10,000 characters
  When: CreateCompletion called
  Then: Completion saves successfully without truncation

TestCompletion_AC_DEV_REFLECT_04_SavesMoodTag
  Given: Devotional completion with moodTag="hopeful"
  When: CreateCompletion called
  Then: Completion record includes moodTag

TestCompletion_AC_DEV_REFLECT_05_CompletionWithoutReflection
  Given: No reflection text provided
  When: CreateCompletion called with reflection=nil
  Then: Completion saves successfully with null reflection

TestCompletion_ImmutableTimestamp_FR2_7_RejectsTimestampUpdate
  Given: Existing completion with timestamp T1
  When: UpdateCompletion called with new timestamp T2
  Then: Error returned "timestamp is immutable"; timestamp unchanged

TestCompletion_UpdateReflection_AllowedAfterCreation
  Given: Existing completion without reflection
  When: UpdateCompletion called with reflection text
  Then: Reflection is saved; timestamp unchanged

TestCompletion_UpdateMoodTag_AllowedAfterCreation
  Given: Existing completion with moodTag="hopeful"
  When: UpdateCompletion called with moodTag="convicted"
  Then: MoodTag updated; timestamp unchanged

TestCompletion_DuplicateCompletionSameDay_ReturnsConflict
  Given: Completion already exists for devotional dev_X on 2026-04-07
  When: CreateCompletion called for same devotional same day
  Then: Error returned with 409 Conflict
```

### 1.3 Devotional Streak Calculation

**Location:** `internal/domain/devotionals/streak_test.go`

```
TestStreak_AC_DEV_NOTIFY_04_ConsecutiveDaysIncrement
  Given: User completed devotionals on days 1-14
  When: Completion recorded for day 15
  Then: currentDays=15, longestDays=15

TestStreak_MissedDay_ResetsToZero
  Given: User completed devotionals on days 1-14, missed day 15
  When: Completion recorded for day 16
  Then: currentDays=1, longestDays=14

TestStreak_LongestStreakPreserved
  Given: User had longest streak of 23, current streak broken
  When: Streak recalculated
  Then: longestDays=23 (preserved)

TestStreak_TimezoneAware_DayBoundary
  Given: User in America/Los_Angeles completes at 11:30 PM PST (next day UTC)
  When: Streak calculated
  Then: Counts as completion for the PST date, not UTC date

TestStreak_FirstCompletion_StartsAtOne
  Given: User has no previous completions
  When: First devotional completion recorded
  Then: currentDays=1, longestDays=1
```

### 1.4 Series Progression

**Location:** `internal/domain/devotionals/series_test.go`

```
TestSeries_AC_DEV_SERIES_01_SequentialProgression
  Given: User completed day 37 of series
  When: Completion recorded
  Then: Series progress updates to currentDay=38

TestSeries_AC_DEV_SERIES_02_MissedDayNoAutoAdvance
  Given: User at day 15, last completed 2 days ago
  When: GetNextSeriesDevotional called
  Then: Returns day 15 (no auto-advance)

TestSeries_AC_DEV_SERIES_03_OneActiveSeriesAtATime
  Given: User has Series A active at day 15
  When: ActivateSeries called for Series B
  Then: Series A paused at day 15, Series B becomes active

TestSeries_AC_DEV_SERIES_04_PausedSeriesResumes
  Given: Series A paused at day 15
  When: ActivateSeries called for Series A
  Then: Series A resumes at day 15

TestSeries_AC_DEV_SERIES_05_ProgressIndicator
  Given: User at day 47 of 365-day series
  When: GetSeriesProgress called
  Then: Returns currentDay=47, totalDays=365

TestSeries_AC_DEV_EDGE_03_MultipleSeriesPurchase
  Given: User active on Series A day 15, purchases Series B
  When: ListSeriesProgress called
  Then: Series A shows active at day 15, Series B shows not_started

TestSeries_CompletedSeries_StatusCompleted
  Given: User completes day 365 of 365-day series
  When: Completion recorded
  Then: Series status changes to "completed"
```

### 1.5 Content Tier Access

**Location:** `internal/domain/devotionals/access_test.go`

```
TestAccess_AC_DEV_CONTENT_04_PremiumUnlockedForever
  Given: User purchased series_X at time T1
  When: User accesses series_X devotional at time T2 >> T1
  Then: Access granted

TestAccess_AC_DEV_CONTENT_05_LockedPremiumContent
  Given: User has NOT purchased series_X
  When: User requests GET /devotionals/{premiumDevId}
  Then: Returns 403 with "Premium Content Locked" error

TestAccess_FreeTierCanAccessFreeContent
  Given: Free-tier user
  When: User requests free-tier devotional
  Then: Access granted

TestAccess_AC_DEV_EDGE_05_FeatureFlagDisabled
  Given: Feature flag activity.devotionals is disabled
  When: Any devotional endpoint called
  Then: Returns 404
```

### 1.6 Favorites

**Location:** `internal/domain/devotionals/favorites_test.go`

```
TestFavorites_AC_DEV_FAVORITE_01_AddToFavorites
  Given: Devotional dev_X exists
  When: AddFavorite called
  Then: Favorite record created

TestFavorites_AC_DEV_FAVORITE_02_RemoveFromFavorites
  Given: Devotional dev_X is favorited
  When: RemoveFavorite called
  Then: Favorite record deleted

TestFavorites_AC_DEV_FAVORITE_03_ListFavorites
  Given: User has 5 favorited devotionals
  When: ListFavorites called
  Then: Returns 5 devotional summaries

TestFavorites_AddDuplicate_Idempotent
  Given: Devotional dev_X already favorited
  When: AddFavorite called again
  Then: No error, no duplicate record
```

### 1.7 Sharing

**Location:** `internal/domain/devotionals/share_test.go`

```
TestShare_AC_DEV_SHARE_01_ExcludesPersonalReflection
  Given: User completed devotional with reflection
  When: ShareDevotional called
  Then: Shared content includes title, scripture, reading, prayer but NOT user's reflection

TestShare_ToContact_ValidatesContactExists
  Given: ShareType=contact, contactId does not exist
  When: ShareDevotional called
  Then: Returns 404

TestShare_GeneratesShareLink
  Given: ShareType=link
  When: ShareDevotional called
  Then: Returns a shareable URL
```

---

## 2. Integration Tests

### 2.1 Repository Tests

**Location:** `test/integration/devotionals/repository_test.go`

```
TestDevotionalRepository_GetByFreemiumDay_ReturnsCorrectDevotional
  Given: MongoDB seeded with 30 freemium devotionals
  When: GetByFreemiumDay(7) called
  Then: Returns devotional with freemiumRotationDay=7

TestDevotionalRepository_GetBySeriesDay_ReturnsCorrectDevotional
  Given: MongoDB seeded with series devotionals
  When: GetBySeriesAndDay("series_recovery365", 38) called
  Then: Returns correct devotional

TestDevotionalRepository_FullTextSearch_MatchesTitleAndScripture
  Given: MongoDB seeded with devotionals
  When: Search("surrender") called
  Then: Returns devotionals matching "surrender" in title, scripture, or body

TestCompletionRepository_SaveAndRetrieve_PreservesAllFields
  Given: Devotional completion with reflection and mood tag
  When: Save then GetByDateRange called
  Then: All fields preserved including reflection text

TestCompletionRepository_CalendarDualWrite_CreatesActivityEntry
  Given: Devotional completion saved
  When: Query calendar activities for that date
  Then: DEVOTIONAL calendar activity exists with correct summary

TestFavoriteRepository_AddRemoveList_CRUD
  Given: Empty favorites
  When: Add 3 favorites, remove 1, list
  Then: Returns 2 favorites

TestSeriesProgressRepository_ActivatePauseResume_StateTransitions
  Given: Series A active
  When: Activate Series B, then re-activate Series A
  Then: Series A resumes at correct day, Series B paused

TestStreakRepository_IncrementAndReset_UpdatesCorrectly
  Given: Current streak at 14
  When: Increment called
  Then: currentDays=15, longestDays=max(15, previous longest)
```

### 2.2 Valkey Cache Tests

**Location:** `test/integration/devotionals/cache_test.go`

```
TestCache_DevotionalStreak_CacheHitAndInvalidation
  Given: Streak cached in Valkey with 5-min TTL
  When: New completion triggers invalidation, then streak queried
  Then: Fresh value returned from MongoDB

TestCache_TodayDevotional_CachedForDay
  Given: Today's devotional fetched
  When: Same request within cache TTL
  Then: Returns cached value without MongoDB query
```

### 2.3 Event Processing Tests

**Location:** `test/integration/devotionals/events_test.go`

```
TestEvent_CompletionCreated_PublishesTrackingEvent
  Given: Devotional completion saved
  When: Event handler processes
  Then: SNS/SQS event published with DEVOTIONAL activity type

TestEvent_StreakMilestone_PublishesNotificationEvent
  Given: User reaches 30-day devotional streak
  When: Completion triggers milestone check
  Then: Notification event published for streak milestone

TestEvent_GoalAutoCheck_PublishesGoalCompletionEvent
  Given: User has a "devotional" daily goal
  When: Devotional completed
  Then: Goal completion event published
```

---

## 3. Handler/API Tests

**Location:** `internal/handler/devotionals_handler_test.go`

```
TestHandler_GetTodayDevotional_200_ReturnsFullContent
  Given: Authenticated user, feature flag enabled
  When: GET /devotionals/today
  Then: 200 with full Devotional schema, data envelope

TestHandler_GetTodayDevotional_401_Unauthenticated
  Given: No auth token
  When: GET /devotionals/today
  Then: 401 with WWW-Authenticate header

TestHandler_ListDevotionals_200_PaginatedWithCursor
  Given: 50 devotionals in database
  When: GET /devotionals?limit=20
  Then: 200 with 20 items, nextCursor in meta.page

TestHandler_ListDevotionals_FilterByTopic
  Given: Devotionals with various topics
  When: GET /devotionals?topic=surrender
  Then: Only devotionals with topic=surrender returned

TestHandler_GetDevotional_403_PremiumLocked
  Given: Authenticated free-tier user
  When: GET /devotionals/{premiumDevId}
  Then: 403 with error code rr:0x00D00001

TestHandler_CreateCompletion_201_WithReflection
  Given: Valid completion request with reflection and mood
  When: POST /devotionals/{id}/completions
  Then: 201 with Location header, completion data, streak update

TestHandler_CreateCompletion_409_AlreadyCompletedToday
  Given: Devotional already completed today
  When: POST /devotionals/{id}/completions
  Then: 409 Conflict

TestHandler_UpdateCompletion_200_AddReflectionLater
  Given: Existing completion without reflection
  When: PATCH /devotionals/completions/{id} with reflection
  Then: 200 with updated reflection

TestHandler_UpdateCompletion_422_TimestampImmutable
  Given: Existing completion
  When: PATCH /devotionals/completions/{id} with new timestamp
  Then: 422 with "timestamp is immutable"

TestHandler_ListHistory_200_ReverseChronological
  Given: 10 completions over 10 days
  When: GET /devotionals/history?sort=-timestamp
  Then: 200, items sorted newest first

TestHandler_ListHistory_FilterByDateRange
  Given: Completions across March and April
  When: GET /devotionals/history?startDate=2026-04-01&endDate=2026-04-07
  Then: Only April completions returned

TestHandler_SearchReflections_MatchesUserText
  Given: User has reflections with keyword "surrender"
  When: GET /devotionals/history?searchReflections=surrender
  Then: Returns completions where reflection contains "surrender"

TestHandler_AddFavorite_204
  Given: Devotional exists
  When: POST /devotionals/favorites/{id}
  Then: 204 No Content

TestHandler_RemoveFavorite_204
  Given: Devotional is favorited
  When: DELETE /devotionals/favorites/{id}
  Then: 204 No Content

TestHandler_ListFavorites_200
  Given: User has 3 favorites
  When: GET /devotionals/favorites
  Then: 200 with 3 items

TestHandler_ListSeries_200_WithProgress
  Given: User has progress on 2 series
  When: GET /devotionals/series
  Then: 200 with series list including user's progress

TestHandler_ActivateSeries_200_PausesPreviousActive
  Given: Series A active, user activates Series B
  When: POST /devotionals/series/{seriesB}/activate
  Then: 200 with activeSeriesId=seriesB, pausedSeries.seriesId=seriesA

TestHandler_ActivateSeries_403_NotPurchased
  Given: User has not purchased premium series
  When: POST /devotionals/series/{premiumSeriesId}/activate
  Then: 403

TestHandler_ShareDevotional_200_ExcludesReflection
  Given: User completed devotional with reflection
  When: POST /devotionals/{id}/share with shareType=link
  Then: 200 with shareUrl, no reflection in shared content

TestHandler_GetStreak_200
  Given: User has 15-day streak
  When: GET /devotionals/streak
  Then: 200 with currentDays=15

TestHandler_ExportHistory_202_ReturnsExportId
  Given: User has completions
  When: POST /devotionals/history/export
  Then: 202 with exportId and status URL
```

---

## 4. E2E Tests

**Location:** `test/e2e/devotionals/devotional_flow_test.go`

```
TestE2E_DailyDevotionalFlow_ReadReflectComplete
  Given: Authenticated user (persona: Alex)
  When:
    1. GET /devotionals/today -> read devotional
    2. POST /devotionals/{id}/completions with reflection and mood
    3. GET /devotionals/streak
    4. GET /devotionals/history
  Then:
    - Devotional completion recorded
    - Streak incremented
    - Completion appears in history with reflection

TestE2E_PremiumSeriesFlow_PurchaseActivateProgress
  Given: Authenticated premium user (persona: Marcus)
  When:
    1. GET /devotionals/series -> see available series
    2. POST /content/packs/{id}/purchase -> purchase series pack
    3. POST /devotionals/series/{id}/activate -> activate series
    4. GET /devotionals/today -> get series day 1
    5. POST /devotionals/{id}/completions -> complete day 1
    6. GET /devotionals/series/{id} -> check progress
  Then:
    - Series activated, day 1 completed, progress shows day 2

TestE2E_FavoritesFlow_AddBrowseRemove
  Given: Authenticated user
  When:
    1. Read today's devotional
    2. POST /devotionals/favorites/{id} -> add to favorites
    3. GET /devotionals/favorites -> browse favorites
    4. DELETE /devotionals/favorites/{id} -> remove
    5. GET /devotionals/favorites -> verify removal
  Then:
    - Favorites list updated correctly at each step

TestE2E_OfflineSync_CompletionSyncedOnReconnect
  Given: User completes devotional while offline (simulated via delayed API call)
  When: Client syncs offline completions
  Then: Completion appears in history with original timestamp

TestE2E_SeriesSwitching_PauseAndResume
  Given: User active on Series A at day 15
  When:
    1. POST /devotionals/series/{seriesB}/activate -> switch to B
    2. Complete day 1 of Series B
    3. POST /devotionals/series/{seriesA}/activate -> switch back
    4. GET /devotionals/today
  Then:
    - Series A resumes at day 15
    - Series B paused at day 2

TestE2E_CalendarIntegration_DevotionalShowsInCalendar
  Given: User completes devotional on 2026-04-07
  When: GET calendar activities for 2026-04-07
  Then: DEVOTIONAL activity type present in calendar day view

TestE2E_HistoryExport_GeneratesPDF
  Given: User has 30 completed devotionals
  When: POST /devotionals/history/export
  Then: Export status eventually shows "completed" with download URL
```

---

## 5. Contract Tests

**Location:** `test/contract/devotionals_contract_test.go`

```
TestContract_GetTodayDevotional_MatchesOpenAPISchema
  Validates response against Devotional schema in openapi.yaml

TestContract_CreateCompletion_RequestMatchesSchema
  Validates request body against DevotionalCompletionRequest schema

TestContract_CreateCompletion_ResponseMatchesSchema
  Validates response against DevotionalCompletion schema

TestContract_ListHistory_PaginationMatchesSchema
  Validates cursor pagination structure in response

TestContract_ErrorResponses_MatchErrorObjectSchema
  Validates 400/401/403/404/409/422/500 responses match ErrorResponse schema

TestContract_AllEndpoints_ReturnApiVersionHeader
  Validates Api-Version header present on all successful responses

TestContract_AllEndpoints_ReturnCorrelationIdHeader
  Validates X-Correlation-Id header present on mutating responses
```

---

## 6. Mobile Client Tests

### 6.1 Android (Kotlin)

**Location:** `androidApp/app/src/test/java/com/regalrecovery/devotionals/`

```
DevotionalViewModelTest:
  - test_todayDevotional_displaysAllContentElements
  - test_reflection_savesAndShowsInHistory
  - test_offlineCompletion_queuedForSync
  - test_streakDisplay_formatsCorrectly
  - test_seriesProgress_showsCurrentOfTotal
  - test_lockedContent_showsPurchaseCTA

DevotionalOfflineCacheTest:
  - test_cacheCurrentDayPlusSevenDays
  - test_offlineReflection_savedLocally
  - test_conflictResolution_unionMergeCompletions
```

### 6.2 iOS (Swift / XCTest)

**Location:** `iosApp/RegalRecoveryTests/Devotionals/`

```
DevotionalViewModelTests:
  - testTodayDevotional_displaysAllContentElements
  - testReflection_savesAndShowsInHistory
  - testOfflineCompletion_queuedForSync
  - testStreakDisplay_formatsCorrectly
  - testSeriesProgress_showsCurrentOfTotal
  - testLockedContent_showsPurchaseCTA

DevotionalOfflineCacheTests:
  - testCacheCurrentDayPlusSevenDays
  - testOfflineReflection_savedLocally
  - testConflictResolution_unionMergeCompletions
```

---

## Coverage Requirements

| Scope | Target |
|-------|--------|
| Devotional domain logic (`internal/domain/devotionals/`) | 90% line coverage |
| Streak calculation | 100% line + branch coverage |
| Content access/tier checking | 100% line + branch coverage |
| Immutable timestamp enforcement | 100% line + branch coverage |
| Handler layer | 80% line coverage |
| Overall devotionals module | 85% line coverage |
