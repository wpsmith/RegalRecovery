# Prayer Activity -- Test Specifications

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft

All test names reference acceptance criteria from `acceptance-criteria.md` using the format `Test<Domain>_<AC_ID>_<Behavior>`.

---

## 1. Unit Tests (60-70%)

**Location:** `internal/domain/prayer/*_test.go`

### 1.1 Prayer Session Validation

```
TestPrayerSession_PR_AC1_2_RejectInvalidPrayerType
  Given prayerType is "meditation" (not in enum)
  Then returns validation error with code rr:0x00500001

TestPrayerSession_PR_AC1_2_AcceptAllValidPrayerTypes
  Given prayerType is each of [personal, guided, group, scriptureBased, intercessory, listening]
  Then each is accepted without error

TestPrayerSession_PR_AC1_3_DurationIsOptional
  Given a prayer session with no durationMinutes
  Then session is valid with durationMinutes=null

TestPrayerSession_PR_AC1_4_RejectNotesExceeding1000Chars
  Given notes with 1001 characters
  Then returns validation error pointing to /data/notes

TestPrayerSession_PR_AC1_4_AcceptNotesAt1000Chars
  Given notes with exactly 1000 characters
  Then session is valid

TestPrayerSession_PR_AC1_7_AcceptMoodInRange
  Given moodBefore=1 and moodAfter=5
  Then session is valid

TestPrayerSession_PR_AC1_8_RejectMoodOutOfRange
  Given moodBefore=0 or moodAfter=6
  Then returns validation error

TestPrayerSession_PR_AC1_9_AllowBackdatingWithin7Days
  Given timestamp is 5 days in the past
  Then session is valid with provided timestamp

TestPrayerSession_PR_AC1_9_RejectBackdatingBeyond7Days
  Given timestamp is 8 days in the past
  Then returns validation error

TestPrayerSession_PR_AC1_10_TimestampIsImmutable
  Given an existing prayer session
  When update includes timestamp field
  Then returns error "timestamp is immutable"

TestPrayerSession_PR_AC1_13_NotesEditableWithin24Hours
  Given a prayer session created 23 hours ago
  When notes are updated
  Then update succeeds

TestPrayerSession_PR_AC1_13_NotesReadOnlyAfter24Hours
  Given a prayer session created 25 hours ago
  When notes are updated
  Then returns error "notes are read-only after 24 hours"
```

### 1.2 Prayer Streak Calculation

```
TestPrayerStreak_PR_AC5_1_CalculatesConsecutiveDays
  Given prayer sessions on each of the last 14 consecutive days
  Then currentStreakDays=14

TestPrayerStreak_PR_AC5_1_StreakBreaksOnMissedDay
  Given sessions on days 1-10 and 12-14 (day 11 missing)
  Then currentStreakDays=3 (days 12-14)

TestPrayerStreak_PR_AC5_2_MultipleSameDay_CountsAsOneDay
  Given 3 prayer sessions on March 28
  Then March 28 counts as 1 day for streak

TestPrayerStreak_PR_AC5_3_LongestStreakUpdated
  Given current streak=31 and previous longest=30
  Then longestStreakDays=31

TestPrayerStreak_PR_AC5_3_LongestStreakPreservedOnBreak
  Given longest streak was 30, current streak breaks at 15
  Then longestStreakDays remains 30

TestPrayerStreak_PR_AC5_5_TotalPrayerDaysCountsDistinctDays
  Given 50 prayer sessions across 30 distinct days
  Then totalPrayerDays=30

TestPrayerStreak_PR_AC5_6_TypeDistribution
  Given 10 personal, 5 guided, 3 group sessions
  Then typeDistribution={personal:10, guided:5, group:3, scriptureBased:0, intercessory:0, listening:0}

TestPrayerStreak_TimezoneHandling_UsesUserTimezone
  Given user in America/Los_Angeles
  When session logged at 11:30 PM PST (next day UTC)
  Then counts as today in user's timezone
```

### 1.3 Personal Prayer Validation

```
TestPersonalPrayer_PR_AC3_1_RequiresTitleAndBody
  Given a personal prayer with no title
  Then returns validation error

TestPersonalPrayer_PR_AC3_2_RejectTitleExceeding100Chars
  Given a title with 101 characters
  Then returns validation error

TestPersonalPrayer_PR_AC3_2_AcceptTitleAt100Chars
  Given a title with exactly 100 characters
  Then prayer is valid

TestPersonalPrayer_PR_AC3_5_DeleteRetainsLinkedSessionReference
  Given a prayer session linked to personal prayer pp_11111
  When pp_11111 is deleted
  Then the session retains linkedPrayerId=pp_11111 and linkedPrayerTitle="[Deleted Prayer]"
```

### 1.4 Prayer Type Enum Mapping

```
TestPrayerTypeMapping_PRDToAPI_AllTypesRepresented
  Given the PRD defines 6 prayer types
  Then the enum contains exactly [personal, guided, group, scriptureBased, intercessory, listening]
  And each maps to the correct PRD definition

TestPrayerTypeMapping_QuickLog_DefaultsToPersonal
  Given a quick log with no prayerType specified
  Then prayerType defaults to "personal" per PR-AC1.11
```

### 1.5 Linked Prayer Validation

```
TestLinkedPrayer_PR_AC1_5_ResolvesLinkedPrayerTitle
  Given linkedPrayerId=pryr_1a2b3c4d exists in library
  Then linkedPrayerTitle is set to the prayer's title

TestLinkedPrayer_PR_AC1_6_RejectLockedPremiumPrayer
  Given linkedPrayerId references a premium prayer the user has not purchased
  Then returns error with code rr:0x00500002
```

### 1.6 Feature Flag Evaluation

```
TestPrayerFeatureFlag_PR_AC7_1_DisabledReturns404
  Given feature flag activity.prayer is disabled
  When any prayer endpoint is called
  Then returns 404 Not Found

TestPrayerFeatureFlag_PR_AC7_2_FlagUnavailableReturns404
  Given feature flag system is unavailable
  When any prayer endpoint is called
  Then returns 404 Not Found (fail closed)
```

---

## 2. Integration Tests (20-30%)

**Location:** `test/integration/prayer/`

### 2.1 Prayer Session Repository

```
TestPrayerRepository_CreateAndRetrieve_PR_AC1_1
  Given a valid prayer session
  When created via repository
  Then retrievable by PK/SK with all fields intact

TestPrayerRepository_ListByDateRange_PR_AC6_3
  Given 10 prayer sessions across March
  When querying startDate=2026-03-10 endDate=2026-03-20
  Then only sessions within range returned

TestPrayerRepository_FilterByType_PR_AC6_2
  Given sessions of types personal and guided
  When filtering by prayerType=guided
  Then only guided sessions returned

TestPrayerRepository_CalendarDualWrite_PR_AC10_1
  Given a prayer session is created
  Then a CALENDAR_ACTIVITY entry exists with activityType=PRAYER

TestPrayerRepository_EphemeralTTL_SetsExpiresAt
  Given an ephemeral prayer session
  Then expiresAt is set to 30 days from creation

TestPrayerRepository_CursorPagination_PR_AC6_1
  Given 60 prayer sessions
  When requesting limit=20
  Then first page returns 20 with nextCursor, second page returns next 20
```

### 2.2 Personal Prayer Repository

```
TestPersonalPrayerRepository_CRUD_PR_AC3_1
  Given a new personal prayer
  When created, updated, and deleted
  Then each operation succeeds with correct state

TestPersonalPrayerRepository_Reorder_PR_AC3_6
  Given 5 personal prayers
  When reorder endpoint called with new ID order
  Then sortOrder fields reflect new order

TestPersonalPrayerRepository_ListSorted_PR_AC3_3
  Given personal prayers with sortOrder 1, 2, 3
  Then listed in sortOrder ascending
```

### 2.3 Prayer Favorite Repository

```
TestPrayerFavoriteRepository_FavoriteAndUnfavorite_PR_AC4_1_AC4_2
  Given a library prayer
  When favorited then unfavorited
  Then favorite created then removed

TestPrayerFavoriteRepository_ListFavorites_PR_AC4_3
  Given 5 favorited prayers
  When listing favorites
  Then all 5 returned with correct titles

TestPrayerFavoriteRepository_DuplicateFavorite_Returns409
  Given a prayer already favorited
  When favorited again
  Then returns 409 Conflict
```

### 2.4 Library Prayer Repository

```
TestLibraryPrayerRepository_ListByPack_PR_AC2_3
  Given 10 prayers in pack_temptation
  When listing by pack=pack_temptation
  Then all 10 returned

TestLibraryPrayerRepository_FilterByTopic_PR_AC2_2
  Given prayers tagged with "temptation" and "gratitude"
  When filtering by topic=temptation
  Then only temptation-tagged prayers returned

TestLibraryPrayerRepository_FilterByStep_PR_AC2_4
  Given 12 step prayers
  When filtering by step=4
  Then only Step 4 prayer returned

TestLibraryPrayerRepository_FullTextSearch_PR_AC2_5
  Given prayers with "strength" in title or body
  When searching for "strength"
  Then matching prayers returned

TestLibraryPrayerRepository_LockedContent_PR_AC2_6
  Given user has not purchased pack_temptation
  When listing prayers from that pack
  Then isLocked=true and body is truncated

TestLibraryPrayerRepository_FreemiumAlwaysAccessible_PR_AC2_8
  Given freemium prayers in pack_step_prayers and pack_core
  When user has no purchases
  Then freemium prayers have isLocked=false
```

### 2.5 Prayer Streak Cache (Valkey)

```
TestPrayerStreakCache_CachePopulated
  Given prayer streak computed
  When streak is cached in Valkey
  Then cache hit returns correct streak within 5-minute TTL

TestPrayerStreakCache_InvalidatedOnCreate
  Given cached streak=14
  When new prayer session created
  Then cache is invalidated and recomputed to 15

TestPrayerStreakCache_InvalidatedOnDelete
  Given cached streak=14
  When today's prayer session deleted
  Then cache is invalidated and streak recalculated
```

### 2.6 Event Publishing

```
TestPrayerEvents_SessionCreated_PublishesToSNS
  Given a prayer session is created
  Then an SNS event prayer.session.created is published with prayerId and userId

TestPrayerEvents_StreakMilestone_PublishesNotification
  Given prayer streak reaches 7 days
  Then an SNS event prayer.streak.milestone is published with milestone=7
```

---

## 3. End-to-End Tests (5-10%)

**Location:** `test/e2e/prayer/`

### 3.1 Complete Prayer Session Flow

```
TestPrayerE2E_CreateLogViewHistory_PR_AC1_1_AC6_1
  Given authenticated user
  When POST /activities/prayer with prayerType=personal, duration=10
  Then 201 returned with prayerId
  And GET /activities/prayer returns session in history
  And GET /activities/prayer/{id} returns full detail with notes

TestPrayerE2E_QuickLogThenExpand_PR_AC1_11_AC1_12
  Given authenticated user
  When POST /activities/prayer with only prayerType=personal and timestamp
  Then 201 returned
  When PATCH /activities/prayer/{id} adds notes, duration, mood
  Then 200 returned with all fields populated

TestPrayerE2E_StreakCalculation_PR_AC5_1
  Given authenticated user logs prayer on 7 consecutive days
  When GET /activities/prayer/stats
  Then currentStreakDays=7

TestPrayerE2E_PersonalPrayerCRUD_PR_AC3_1_AC3_4_AC3_5
  Given authenticated user
  When POST /content/prayers/personal with title and body
  Then 201 returned
  When PATCH /content/prayers/personal/{id} updates title
  Then 200 returned with new title
  When DELETE /content/prayers/personal/{id}
  Then 204 returned
  And GET /content/prayers/personal no longer includes deleted prayer

TestPrayerE2E_FavoriteFlow_PR_AC4_1_AC4_2_AC4_3
  Given authenticated user and library prayer pryr_1a2b3c4d
  When POST /content/prayers/favorites/pryr_1a2b3c4d
  Then 201 returned
  And GET /content/prayers/favorites includes the prayer
  When DELETE /content/prayers/favorites/pryr_1a2b3c4d
  Then 204 returned
  And GET /content/prayers/favorites no longer includes it

TestPrayerE2E_TodaysPrayer_PR_AC2_7
  Given authenticated user with owned packs
  When GET /content/prayers/today
  Then 200 returned with a prayer from owned packs
  And same prayer returned on second call within same day

TestPrayerE2E_LockedContent_PR_AC2_6
  Given authenticated user without pack_temptation purchased
  When GET /content/prayers?pack=pack_temptation
  Then prayers returned with isLocked=true and body truncated

TestPrayerE2E_TimestampImmutability_PR_AC1_10
  Given authenticated user with existing prayer session
  When PATCH /activities/prayer/{id} with timestamp field
  Then 422 returned with "timestamp is immutable"
```

### 3.2 Community Permission Tests

```
TestPrayerE2E_SupportNetworkAccess_PR_AC9_1
  Given user has granted spouse permission to view prayer data
  When spouse requests user's prayer stats
  Then prayer streak data returned

TestPrayerE2E_NoDefaultAccess_PR_AC9_2
  Given user has NOT granted contact permission to view prayer data
  When contact requests user's prayer data
  Then 404 returned (hide existence)
```

### 3.3 Contract Tests

```
TestPrayerContract_CreateSessionRequest_MatchesOpenAPISpec
  Given OpenAPI spec for POST /activities/prayer
  When request is validated against spec
  Then all required fields enforced, all enums validated, all constraints checked

TestPrayerContract_PrayerSessionResponse_MatchesOpenAPISpec
  Given OpenAPI spec PrayerSession schema
  When response is validated against spec
  Then all fields present with correct types

TestPrayerContract_LibraryPrayerResponse_MatchesOpenAPISpec
  Given OpenAPI spec LibraryPrayer schema
  When response is validated against spec
  Then all fields present with correct types

TestPrayerContract_ErrorResponse_MatchesSiemensGuidelines
  Given a 422 error response
  Then structure follows Siemens error object (id, code, status, title, detail, correlationId)
```

---

## 4. Mobile Tests

### 4.1 Android (Kotlin)

```
TestPrayerOfflineQueue_PR_AC8_1_EnqueueWhenOffline
  Given device is offline
  When prayer session logged
  Then session queued locally

TestPrayerOfflineSync_PR_AC8_3_UnionMerge
  Given sessions logged on two devices offline
  When both sync
  Then all sessions present (union merge)

TestPrayerLibraryCache_PR_AC8_2_OfflineBrowsing
  Given prayer library cached
  When device goes offline
  Then cached prayers available for reading

TestPrayerScreen_StreakDisplay_ShowsCurrentStreak
  Given prayer streak = 14 days
  When prayer screen rendered
  Then "14 days" displayed

TestPrayerScreen_QuickLogButton_CreatesSession
  Given user taps quick log button
  Then prayer session created with type=personal
```

### 4.2 iOS (Swift)

```
TestPrayerOfflineQueue_PR_AC8_1_StoresLocally
  Given device is offline
  When prayer session logged
  Then session stored in SwiftData

TestPrayerFullScreenMode_DisplaysCleanUI
  Given a library prayer opened in full-screen mode
  Then prayer body displayed in serif font, large type, calming background

TestPrayerPostSessionPrompt_OffersLogging
  Given user exits full-screen prayer mode
  Then prompt "Would you like to log this as a prayer session?" shown
```

---

## 5. Coverage Requirements

| Module | Target Coverage |
|--------|----------------|
| `internal/domain/prayer/` | 90% line coverage |
| Prayer streak calculation | 100% line + branch |
| Prayer session validation | 100% line + branch |
| Feature flag gating | 100% line + branch |
| Permission checking for prayer data | 100% line + branch |
| Overall prayer module | >= 80% |

---

## 6. Test Data Fixtures

### Persona Extensions

```go
// pkg/fixtures/prayer_fixtures.go

var AlexPrayerHistory = []PrayerSession{
    {PrayerType: "personal", DurationMinutes: ptr(15), Timestamp: daysAgo(0)},
    {PrayerType: "guided", DurationMinutes: ptr(10), Timestamp: daysAgo(1), LinkedPrayerId: ptr("pryr_step04")},
    {PrayerType: "personal", DurationMinutes: nil, Timestamp: daysAgo(2)},
    // ... 14 consecutive days of prayer
}

var MarcusPrayerHistory = []PrayerSession{
    // No prayer history -- Marcus has not engaged with prayer yet
}

var DiegoPrayerHistory = []PrayerSession{
    {PrayerType: "personal", DurationMinutes: ptr(20), Timestamp: daysAgo(0)},
    {PrayerType: "intercessory", DurationMinutes: ptr(10), Timestamp: daysAgo(0)},
    // Diego prays twice daily, 30-day streak
}
```

### Prayer Content Fixtures

```go
var FreemiumPrayers = []LibraryPrayer{
    {ID: "pryr_serenity", Title: "Serenity Prayer (Full)", Pack: "pack_core", Tier: "free", StepNumber: nil},
    {ID: "pryr_lords", Title: "Lord's Prayer", Pack: "pack_core", Tier: "free", StepNumber: nil},
    {ID: "pryr_step01", Title: "Step 1 Prayer: Admitting Powerlessness", Pack: "pack_step_prayers", Tier: "free", StepNumber: ptr(1)},
    // ... 12 step prayers + daily morning + daily evening + recovery-focused
}

var PremiumPrayers = []LibraryPrayer{
    {ID: "pryr_tempt01", Title: "Prayer for Strength Against Temptation", Pack: "pack_temptation", Tier: "premium"},
    // ... premium pack content
}
```
