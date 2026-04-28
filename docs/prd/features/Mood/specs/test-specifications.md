# Mood Ratings -- Test Specifications

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft
**Acceptance Criteria Source:** `docs/prd/specific-features/Mood/specs/acceptance-criteria.md`

---

## Naming Convention

All test functions reference the acceptance criterion they verify:

```
Test{Domain}_{AC_ID}_{Description}
```

Example: `TestMood_AC001_CreateMoodEntry_RatingOnly`

---

## 1. Unit Tests (60-70% of test budget)

**Location:** `internal/domain/mood/*_test.go`

### 1.1 Mood Entry Creation

```
TestMood_AC001_CreateMoodEntry_RatingOnly
  Given: valid rating (1-5) and timestamp
  When: CreateMoodEntry is called
  Then: entry created with auto-generated moodId, rating saved, createdAt set

TestMood_AC001_CreateMoodEntry_InvalidRating_Zero
  Given: rating = 0
  When: CreateMoodEntry is called
  Then: validation error returned ("rating must be between 1 and 5")

TestMood_AC001_CreateMoodEntry_InvalidRating_Six
  Given: rating = 6
  When: CreateMoodEntry is called
  Then: validation error returned

TestMood_AC002_CreateMoodEntry_WithContextNote
  Given: rating = 4 and contextNote = "Feeling good after prayer"
  When: CreateMoodEntry is called
  Then: entry created with contextNote saved

TestMood_AC007_CreateMoodEntry_ContextNoteTooLong
  Given: contextNote with 201 characters
  When: CreateMoodEntry is called
  Then: validation error returned ("contextNote must be 200 characters or fewer")

TestMood_AC003_CreateMoodEntry_WithEmotionLabels
  Given: rating = 3, emotionLabels = ["Anxious", "Lonely"]
  When: CreateMoodEntry is called
  Then: entry created with both emotion labels saved

TestMood_AC003_CreateMoodEntry_InvalidEmotionLabel
  Given: emotionLabels = ["Happy"] (not in predefined list)
  When: CreateMoodEntry is called
  Then: validation error returned ("invalid emotion label: Happy")

TestMood_AC003_CreateMoodEntry_EmptyEmotionLabels
  Given: emotionLabels = []
  When: CreateMoodEntry is called
  Then: entry created successfully with empty emotion labels array

TestMood_FR001_RatingScale_MapsCorrectLabel
  Given: each rating 1-5
  When: label is computed
  Then: 1=Crisis, 2=Struggling, 3=Okay, 4=Good, 5=Great

TestMood_AC028_CrisisEntry_SetsCrisisPromptedTrue
  Given: rating = 1 (Crisis)
  When: CreateMoodEntry is called
  Then: response includes crisisPrompted = true

TestMood_AC028_NonCrisisEntry_SetsCrisisPromptedFalse
  Given: rating = 3 (Okay)
  When: CreateMoodEntry is called
  Then: response includes crisisPrompted = false
```

### 1.2 Mood Entry Update (24-Hour Window)

```
TestMood_AC032_UpdateEntry_WithinWindow
  Given: entry created 1 hour ago
  When: UpdateMoodEntry is called with new rating
  Then: rating updated, modifiedAt changed, createdAt unchanged

TestMood_AC034_UpdateEntry_OutsideWindow
  Given: entry created 25 hours ago
  When: UpdateMoodEntry is called
  Then: 422 error returned ("entry is older than 24 hours and can no longer be edited")

TestMood_AC032_UpdateEntry_TimestampImmutable
  Given: entry created 1 hour ago, update includes new timestamp
  When: UpdateMoodEntry is called
  Then: timestamp NOT changed, other fields updated

TestMood_NFR001_UpdateEntry_CreatedAtNeverChanges
  Given: entry created 1 hour ago
  When: UpdateMoodEntry is called with new rating
  Then: createdAt remains exactly the original value
```

### 1.3 Mood Entry Deletion (24-Hour Window)

```
TestMood_AC033_DeleteEntry_WithinWindow
  Given: entry created 30 minutes ago
  When: DeleteMoodEntry is called
  Then: entry is permanently removed, returns 204

TestMood_AC035_DeleteEntry_OutsideWindow
  Given: entry created 25 hours ago
  When: DeleteMoodEntry is called
  Then: 422 error returned ("entry is older than 24 hours and cannot be deleted")
```

### 1.4 Daily Summary Computation

```
TestMood_AC008_TodaySummary_CalculatesAverage
  Given: 3 entries today with ratings 3, 4, 5
  When: GetTodaySummary is called
  Then: averageRating = 4.0, highestRating = 5, lowestRating = 3, entryCount = 3

TestMood_AC008_TodaySummary_NoEntries
  Given: no entries today
  When: GetTodaySummary is called
  Then: empty entries array, null summary

TestMood_AC012_DailySummary_ColorCode_Green
  Given: daily average = 4.5
  When: color code is computed
  Then: colorCode = "green"

TestMood_AC012_DailySummary_ColorCode_Yellow
  Given: daily average = 3.2
  When: color code is computed
  Then: colorCode = "yellow"

TestMood_AC012_DailySummary_ColorCode_Orange
  Given: daily average = 2.5
  When: color code is computed
  Then: colorCode = "orange"

TestMood_AC012_DailySummary_ColorCode_Red
  Given: daily average = 1.5
  When: color code is computed
  Then: colorCode = "red"

TestMood_AC012_DailySummary_ColorCode_Gray
  Given: no entries for this day
  When: color code is computed
  Then: colorCode = "gray"
```

### 1.5 Alerts Logic

```
TestMood_AC025_SustainedLowMood_ThreeDays
  Given: daily averages of [2.0, 1.5, 1.8] for last 3 days
  When: alert check is evaluated
  Then: sustainedLowMood = true, consecutiveLowDays = 3

TestMood_AC025_SustainedLowMood_TwoDays
  Given: daily averages of [2.0, 1.5] for last 2 days (threshold not met)
  When: alert check is evaluated
  Then: sustainedLowMood = false, consecutiveLowDays = 2

TestMood_AC025_SustainedLowMood_BrokenByOkayDay
  Given: daily averages of [1.5, 3.0, 1.8] (broken by day at 3.0)
  When: alert check is evaluated
  Then: sustainedLowMood = false, consecutiveLowDays = 1

TestMood_AC027_SustainedLowMood_NoAutoShare
  Given: sustained low mood detected AND user has NOT enabled sharing
  When: alert evaluated
  Then: alertSharedWithNetwork = false

TestMood_AC026_SustainedLowMood_ShareEnabled
  Given: sustained low mood detected AND user HAS enabled low mood alert sharing
  When: alert evaluated
  Then: alertSharedWithNetwork = true, notification triggered to support contacts
```

### 1.6 Trend Calculations

```
TestMood_AC017_TrendDirection_Improving
  Given: 7 daily averages showing upward trend [2.0, 2.5, 3.0, 3.5, 3.5, 4.0, 4.2]
  When: trend direction is calculated
  Then: trendDirection = "improving"

TestMood_AC017_TrendDirection_Declining
  Given: 7 daily averages showing downward trend [4.5, 4.0, 3.5, 3.0, 2.5, 2.0, 1.8]
  When: trend direction is calculated
  Then: trendDirection = "declining"

TestMood_AC017_TrendDirection_Stable
  Given: 7 daily averages that are flat [3.0, 3.1, 2.9, 3.0, 3.2, 3.0, 3.1]
  When: trend direction is calculated
  Then: trendDirection = "stable"

TestMood_AC018_WeeklySummary_ComparesLastWeek
  Given: this week avg = 3.5, last week avg = 2.8
  When: weekly summary is computed
  Then: averageThisWeek = 3.5, averageLastWeek = 2.8

TestMood_AC019_MonthlySummary_Distribution
  Given: 20 entries: 5 Great, 8 Good, 4 Okay, 2 Struggling, 1 Crisis
  When: monthly summary is computed
  Then: great = 25%, good = 40%, okay = 20%, struggling = 10%, crisis = 5%

TestMood_AC020_TimeOfDayHeatmap_CalculatesHourlyAverages
  Given: entries at hours 8, 14, 20 with ratings 4, 3, 2
  When: heatmap is computed
  Then: hour 8 avg = 4.0, hour 14 avg = 3.0, hour 20 avg = 2.0

TestMood_AC021_DayOfWeekPatterns_CalculatesAverages
  Given: entries across a week
  When: day-of-week patterns computed
  Then: each day has an average rating calculated

TestMood_AC022_EmotionLabelTrends_FrequencySorted
  Given: 30 entries with labels: Anxious (10x), Peaceful (8x), Lonely (5x)
  When: emotion label trends computed
  Then: sorted by count desc: Anxious, Peaceful, Lonely
```

### 1.7 Mood Tracking Streak

```
TestMood_AC041_Streak_ConsecutiveDays
  Given: entries on April 5, 6, 7 (3 consecutive days)
  When: streak is calculated
  Then: currentStreakDays = 3

TestMood_AC041_Streak_GapBreaks
  Given: entries on April 3, 5, 6, 7 (gap on April 4)
  When: streak is calculated
  Then: currentStreakDays = 3 (from April 5)

TestMood_AC041_Streak_MultipleEntriesSameDay
  Given: 5 entries on April 7, 1 entry on April 6
  When: streak is calculated
  Then: currentStreakDays = 2 (multiple same-day entries count as one day)
```

### 1.8 Feature Flag Gating

```
TestMood_NFR002_FeatureFlag_Disabled_Returns404
  Given: feature flag "activity.mood" is disabled
  When: any mood endpoint is called
  Then: 404 Not Found returned

TestMood_NFR002_FeatureFlag_Enabled_AllowsAccess
  Given: feature flag "activity.mood" is enabled
  When: createMoodEntry is called with valid data
  Then: 201 Created returned
```

---

## 2. Integration Tests (20-30% of test budget)

**Location:** `test/integration/mood/`

### 2.1 Repository Tests (MongoDB)

```
TestMoodRepository_Create_PersistsDocument
  Given: valid mood entry
  When: Create is called
  Then: document persisted in moodRatings collection with correct fields

TestMoodRepository_Create_WritesCalendarActivity
  Given: valid mood entry
  When: Create is called
  Then: denormalized entry also written to calendarActivities collection

TestMoodRepository_GetByDateRange_ReturnsCorrectEntries
  Given: 5 entries across 3 days
  When: GetByDateRange("2026-04-05", "2026-04-06")
  Then: only entries from April 5-6 returned

TestMoodRepository_GetByDateRange_CursorPagination
  Given: 60 entries in date range
  When: GetByDateRange with limit=50
  Then: first 50 returned with nextCursor; second call returns remaining 10

TestMood_AC013_Repository_SearchByKeyword
  Given: entries with contextNote containing "prayer" and "meeting"
  When: Search("prayer")
  Then: only entries with "prayer" in contextNote returned

TestMood_AC014_Repository_FilterByRating
  Given: entries with ratings 1, 2, 3, 4, 5
  When: FilterByRating([1, 2])
  Then: only Crisis and Struggling entries returned

TestMood_AC015_Repository_FilterByEmotionLabel
  Given: entries with various emotion labels
  When: FilterByEmotionLabel("Anxious")
  Then: only entries containing "Anxious" label returned

TestMoodRepository_Update_OnlyWithin24Hours
  Given: entry created 23 hours ago
  When: Update is called
  Then: update succeeds, modifiedAt updated

TestMoodRepository_Update_After24Hours_Fails
  Given: entry created 25 hours ago
  When: Update is called with conditional check
  Then: update fails with "entry locked" error

TestMoodRepository_Delete_OnlyWithin24Hours
  Given: entry created 1 hour ago
  When: Delete is called
  Then: entry removed from moodRatings AND calendarActivities

TestMoodRepository_Delete_After24Hours_Fails
  Given: entry created 25 hours ago
  When: Delete is called
  Then: delete fails

TestMoodRepository_DailySummaryAggregation
  Given: entries across 7 days
  When: GetDailySummaries("2026-04-01", "2026-04-07")
  Then: returns 7 summary objects with correct averages, counts, color codes

TestMood_AC020_Repository_HourlyHeatmap
  Given: 30 days of entries at various hours
  When: GetHourlyHeatmap("30d")
  Then: 24 buckets returned with correct averages per hour

TestMood_AC022_Repository_EmotionLabelFrequency
  Given: entries with emotion labels over 30 days
  When: GetEmotionLabelFrequency("30d")
  Then: labels sorted by frequency with counts
```

### 2.2 Valkey Cache Tests

```
TestMoodCache_TodayEntries_CachedAfterFirstRead
  Given: entries exist for today
  When: GetTodaySummary called twice
  Then: first call hits MongoDB, second hits Valkey

TestMoodCache_NewEntry_InvalidatesTodayCache
  Given: today's entries cached in Valkey
  When: new mood entry created
  Then: today cache key invalidated

TestMoodCache_Streak_CachedWithOneHourTTL
  Given: streak calculated
  When: GetStreak called again within 1 hour
  Then: returns cached value without MongoDB query
```

### 2.3 Event Publishing

```
TestMoodEvents_CrisisEntry_PublishesCrisisEvent
  Given: mood entry with rating = 1
  When: entry is saved
  Then: crisis event published to SNS topic

TestMoodEvents_SustainedLowMood_PublishesAlertEvent
  Given: 3rd consecutive day with average <= 2.0
  When: daily alert check runs
  Then: sustained_low_mood event published to SNS

TestMoodEvents_SustainedLowMood_SharingEnabled_NotifiesNetwork
  Given: sustained low mood event AND user has sharing enabled
  When: event handler processes
  Then: push notification sent to configured support contacts
```

---

## 3. E2E Tests (5-10% of test budget)

**Location:** `test/e2e/mood/`

### 3.1 Full Mood Logging Flow

```
TestMoodE2E_CreateReadUpdateDelete_FullLifecycle
  Given: authenticated user (persona: Alex)
  When:
    1. POST /activities/mood (rating=4, emotionLabels=["Hopeful"])
    2. GET /activities/mood/{moodId}
    3. PATCH /activities/mood/{moodId} (rating=3)
    4. DELETE /activities/mood/{moodId}
  Then:
    1. 201 Created with moodId
    2. 200 OK with rating=4
    3. 200 OK with rating=3, modifiedAt updated
    4. 204 No Content

TestMoodE2E_MultipleEntriesPerDay
  Given: authenticated user
  When: POST /activities/mood 3 times with different ratings
  Then: GET /activities/mood/today returns 3 entries with correct summary

TestMoodE2E_CrisisFlow
  Given: authenticated user
  When: POST /activities/mood with rating=1
  Then:
    - 201 Created with crisisPrompted=true
    - GET /activities/mood/alerts/status shows lastCrisisEntry populated
```

### 3.2 Trends and Insights E2E

```
TestMoodE2E_Trends_SevenDayView
  Given: user with 7 days of mood data (seeded)
  When: GET /activities/mood/trends?period=7d
  Then: response includes dailyAverages (7 entries), trendDirection, weeklySummary

TestMoodE2E_DailySummaries_CalendarMonth
  Given: user with 30 days of mood data (seeded)
  When: GET /activities/mood/daily-summaries?startDate=2026-03-01&endDate=2026-03-31
  Then: 30 daily summaries with correct color codes
```

### 3.3 Permission and Access E2E

```
TestMoodE2E_SponsorAccess_WithPermission
  Given: user has granted sponsor permission to "mood" data category
  When: sponsor calls GET /activities/mood?userId={userId}
  Then: 200 OK with mood entries

TestMoodE2E_SponsorAccess_WithoutPermission
  Given: user has NOT granted sponsor permission to mood data
  When: sponsor calls GET /activities/mood?userId={userId}
  Then: 404 Not Found (hides data existence)
```

### 3.4 Offline Sync E2E

```
TestMoodE2E_OfflineSync_TimestampPreserved
  Given: mood entry created offline at T1
  When: device reconnects and syncs at T2
  Then: entry persisted with createdAt=T1, not T2
```

---

## 4. Contract Tests

**Location:** `test/contract/mood/`

### 4.1 OpenAPI Spec Validation

```
TestMoodContract_CreateMoodEntry_MatchesSpec
  Validate: POST /activities/mood request/response matches openapi.yaml schema

TestMoodContract_ListMoodEntries_MatchesSpec
  Validate: GET /activities/mood response matches openapi.yaml schema

TestMoodContract_GetMoodEntry_MatchesSpec
  Validate: GET /activities/mood/{moodId} response matches openapi.yaml schema

TestMoodContract_UpdateMoodEntry_MatchesSpec
  Validate: PATCH /activities/mood/{moodId} request/response matches openapi.yaml schema

TestMoodContract_DeleteMoodEntry_MatchesSpec
  Validate: DELETE /activities/mood/{moodId} response matches openapi.yaml schema

TestMoodContract_GetMoodToday_MatchesSpec
  Validate: GET /activities/mood/today response matches openapi.yaml schema

TestMoodContract_GetDailySummaries_MatchesSpec
  Validate: GET /activities/mood/daily-summaries response matches openapi.yaml schema

TestMoodContract_GetMoodTrends_MatchesSpec
  Validate: GET /activities/mood/trends response matches openapi.yaml schema

TestMoodContract_GetMoodCorrelations_MatchesSpec
  Validate: GET /activities/mood/correlations response matches openapi.yaml schema

TestMoodContract_GetAlertStatus_MatchesSpec
  Validate: GET /activities/mood/alerts/status response matches openapi.yaml schema

TestMoodContract_GetMoodStreak_MatchesSpec
  Validate: GET /activities/mood/streak response matches openapi.yaml schema
```

### 4.2 Error Response Validation

```
TestMoodContract_InvalidRating_Returns400
  Given: POST with rating=0
  Then: 400 response matches ErrorResponse schema

TestMoodContract_Unauthorized_Returns401
  Given: request without Bearer token
  Then: 401 response matches ErrorResponse schema with WWW-Authenticate header

TestMoodContract_NotFound_Returns404
  Given: GET /activities/mood/mood_nonexistent
  Then: 404 response matches ErrorResponse schema

TestMoodContract_EntryLocked_Returns422
  Given: PATCH on entry older than 24 hours
  Then: 422 response matches ErrorResponse schema with code "rr:0x00040001"
```

---

## 5. Mobile Client Tests

### 5.1 Android (Kotlin)

**Location:** `androidApp/app/src/test/java/com/regalrecovery/mood/`

```kotlin
TestMood_AC004_EntryCompletesInUnder10Seconds
  // Performance test: rating-only entry flow under 10 seconds

TestMood_EC001_OfflineEntry_QueuesForSync
  // Verify offline mood entry is queued and syncs on reconnect

TestMood_EC004_DisplayModeSwitch_PreservesData
  // Switch between emoji/numeric mode; verify data unchanged

TestMood_AC030_WidgetOneTap_CreatesMoodEntry
  // Tap emoji on dashboard widget creates entry without navigation
```

### 5.2 iOS (Swift)

**Location:** `iosApp/RegalRecoveryTests/Mood/`

```swift
TestMood_AC004_EntryCompletesInUnder10Seconds
  // Performance test: rating-only entry flow under 10 seconds

TestMood_EC001_OfflineEntry_SavesLocally
  // Verify offline mood entry saved to local store with correct timestamp

TestMood_EC002_TimezoneChange_DisplaysInCurrentTimezone
  // Entries timestamped UTC, displayed in user's current timezone

TestMood_AC031_Widget_ShowsTodayAverageAndStreak
  // Dashboard widget displays correct today average and streak count
```

---

## 6. Coverage Requirements

| Scope | Minimum | Notes |
|-------|---------|-------|
| Overall mood domain | 80% | Standard threshold |
| Mood entry validation (rating, labels, note) | 90% | Domain logic |
| Alert logic (sustained low mood, crisis) | 100% | Critical path |
| 24-hour edit/delete window | 100% | Critical path |
| Immutable timestamp enforcement | 100% | Critical path (FR2.7) |
| Color code calculation | 100% | UI-facing logic |
| Streak calculation | 100% | Tracking integration |
| Feature flag gating | 100% | Fail-closed requirement |

---

## 7. Test Personas

Tests use the standard persona fixtures:

| Persona | Mood Testing Scenario |
|---------|----------------------|
| **Alex** | Active user, 270-day streak, logs mood 3x/day, uses emotion labels. Tests trends/insights. |
| **Marcus** | Evening vulnerability, no sponsor. Tests sustained low mood alerts (evening dips). |
| **Diego** | Spanish language, afternoon vulnerability. Tests timezone handling (US timezone). |
