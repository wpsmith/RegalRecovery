# Gratitude List: Test Specifications

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft
**Traces to:** acceptance-criteria.md, openapi.yaml, mongodb-schema.md

---

## Naming Convention

All test functions follow: `TestGratitude_GL_{Domain}_AC{N}_{Description}`

This maps directly to acceptance criteria IDs in `acceptance-criteria.md`.

---

## 1. Unit Tests (70% of test budget)

### 1.1 Domain Logic: Gratitude Entry Validation

**Location:** `internal/domain/gratitude/entry_test.go`

```
TestGratitude_GL_ES_AC1_MinimumOneItem
  Given: CreateGratitudeEntry request with empty items array
  When: Validator processes the request
  Then: Returns validation error "at least one gratitude item required"

TestGratitude_GL_ES_AC1_MinimumOneItem_EmptyText
  Given: CreateGratitudeEntry request with one item where text is ""
  When: Validator processes the request
  Then: Returns validation error "item text cannot be empty"

TestGratitude_GL_DM_AC1_ItemTextMaxLength
  Given: Item with text exactly 300 characters
  When: Validator processes the item
  Then: Passes validation

TestGratitude_GL_DM_AC1_ItemTextMaxLength_Exceeds
  Given: Item with text of 301 characters
  When: Validator processes the item
  Then: Returns validation error "item text exceeds 300 character maximum"

TestGratitude_GL_ES_AC3_UnlimitedItems
  Given: CreateGratitudeEntry request with 50 items
  When: Validator processes the request
  Then: Passes validation (no upper limit on items)

TestGratitude_GL_DM_AC3_MoodScoreRange_Valid
  Given: Entry with moodScore values 1, 2, 3, 4, 5 (table-driven)
  When: Validator processes the entry
  Then: All pass validation

TestGratitude_GL_DM_AC3_MoodScoreRange_Invalid
  Given: Entry with moodScore values 0, 6, -1, 100 (table-driven)
  When: Validator processes the entry
  Then: All return validation error "mood score must be between 1 and 5"

TestGratitude_GL_DM_AC3_MoodScoreRange_Null
  Given: Entry with moodScore = null
  When: Validator processes the entry
  Then: Passes validation (mood is optional)

TestGratitude_GL_DM_AC2_CategoryTagOptions_Valid
  Given: Items with each valid category enum value (table-driven)
  When: Validator processes the items
  Then: All pass validation

TestGratitude_GL_DM_AC2_CategoryTagOptions_Invalid
  Given: Item with category "invalid-category"
  When: Validator processes the item
  Then: Returns validation error "invalid category"

TestGratitude_GL_DM_AC2_CategoryTagOptions_Null
  Given: Item with no category (null)
  When: Validator processes the item
  Then: Passes validation (category is optional)

TestGratitude_GL_ES_AC14_SingleItemValid
  Given: Entry with exactly 1 item
  When: Service creates the entry
  Then: Entry saved successfully with same response structure as multi-item entries
```

### 1.2 Domain Logic: Edit Window Enforcement

**Location:** `internal/domain/gratitude/editwindow_test.go`

```
TestGratitude_GL_DM_AC7_EditWindow_Within
  Given: Entry with CreatedAt = 23 hours ago
  When: IsEditable() is called
  Then: Returns true

TestGratitude_GL_DM_AC8_ReadOnlyAfter24h
  Given: Entry with CreatedAt = 25 hours ago
  When: IsEditable() is called
  Then: Returns false

TestGratitude_GL_DM_AC7_EditWindow_ExactBoundary
  Given: Entry with CreatedAt = exactly 24 hours ago
  When: IsEditable() is called
  Then: Returns false (boundary is exclusive)

TestGratitude_GL_DM_AC10_ImmutableCreatedAt
  Given: Existing entry with CreatedAt = "2026-04-06T07:00:00Z"
  When: Update request includes a different timestamp
  Then: CreatedAt remains unchanged; only ModifiedAt is updated

TestGratitude_GL_ES_AC11_EditWindow_UpdateRejects
  Given: Entry created 25 hours ago
  When: PUT request to update the entry
  Then: Returns 403 with error code rr:0x47520001 and compassionate message
```

### 1.3 Domain Logic: Streak Calculation

**Location:** `internal/domain/gratitude/streak_test.go`

```
TestGratitude_GL_TI_AC1_CurrentStreak
  Given: Entries on 2026-04-05, 2026-04-06, 2026-04-07 (today)
  When: CalculateStreak() is called
  Then: currentStreak = 3

TestGratitude_GL_TI_AC1_CurrentStreak_BrokenYesterday
  Given: Entries on 2026-04-03, 2026-04-04, 2026-04-07 (gap on 04-05 and 04-06)
  When: CalculateStreak() is called
  Then: currentStreak = 1 (only today)

TestGratitude_GL_TI_AC2_LongestStreak
  Given: Streak of 28 days followed by a gap, then current streak of 5 days
  When: CalculateStreak() is called
  Then: longestStreak = 28

TestGratitude_GL_TI_AC3_TotalDays
  Given: Entries on 50 unique calendar dates over 90 days
  When: CalculateStreak() is called
  Then: totalDaysWithEntries = 50

TestGratitude_GL_TI_AC4_MultipleEntriesSameDay
  Given: 3 entries on 2026-04-07 (timestamps: 07:00, 12:00, 21:00)
  When: CalculateStreak() is called
  Then: Only 1 day counted for that date; streak advances by 1 not 3

TestGratitude_GL_TI_AC10_EveningReviewExcluded
  Given: Evening commitment review with gratitude response on 2026-04-07
        No Gratitude List entry on 2026-04-07
  When: CalculateStreak() is called
  Then: 2026-04-07 does NOT count toward gratitude streak

TestGratitude_GL_TI_AC1_CurrentStreak_TimezoneHandling
  Given: User in America/Los_Angeles timezone
        Entry at 11:30 PM PST on 2026-04-06 (which is 2026-04-07 06:30 UTC)
  When: CalculateStreak() is called with user timezone
  Then: Entry counted as 2026-04-06 in user's local calendar

TestGratitude_GL_TI_AC1_CurrentStreak_Empty
  Given: No gratitude entries exist for user
  When: CalculateStreak() is called
  Then: currentStreak = 0, longestStreak = 0, totalDaysWithEntries = 0
```

### 1.4 Domain Logic: Category Breakdown

**Location:** `internal/domain/gratitude/analytics_test.go`

```
TestGratitude_GL_TI_AC5_CategoryBreakdown
  Given: 30 days of entries with items tagged: family(10), recovery(8), faithGod(5), uncategorized(7)
  When: CalculateCategoryBreakdown(period="30d") is called
  Then: Returns family=43%, recovery=35%, faithGod=22% (uncategorized excluded from breakdown but counted in total)

TestGratitude_GL_TI_AC6_ShiftTracking_SufficientData
  Given: >= 10 entries in current 30-day period, >= 10 entries in previous 30-day period
  When: CalculateShift() is called
  Then: Returns shift with topGainer, topDecliner, and sufficientData=true

TestGratitude_GL_TI_AC6_ShiftTracking_InsufficientData
  Given: 5 entries in current 30-day period (below 10 threshold)
  When: CalculateShift() is called
  Then: Returns shift=null (insufficient data)

TestGratitude_GL_TI_AC7_AvgItemsPerEntry
  Given: 10 entries with item counts [1, 2, 3, 4, 5, 3, 2, 4, 3, 3]
  When: CalculateAverageItems(period="30d") is called
  Then: Returns 3.0
```

### 1.5 Domain Logic: Prompt Selection

**Location:** `internal/domain/gratitude/prompts_test.go`

```
TestGratitude_GL_PR_AC1_PromptCount
  Given: Loaded prompt library
  When: Count() is called
  Then: Returns >= 50

TestGratitude_GL_PR_AC2_DeterministicDaily
  Given: userId="u_12345", date="2026-04-07"
  When: GetDailyPrompt() is called twice
  Then: Returns same prompt both times

TestGratitude_GL_PR_AC2_DeterministicDaily_DifferentDay
  Given: userId="u_12345", date="2026-04-07" then date="2026-04-08"
  When: GetDailyPrompt() is called for each date
  Then: Returns different prompts

TestGratitude_GL_PR_AC2_DeterministicDaily_DifferentUser
  Given: date="2026-04-07", userId="u_12345" then userId="u_67890"
  When: GetDailyPrompt() is called for each user
  Then: Returns different prompts (with high probability)

TestGratitude_GL_PR_AC3_CyclePrompt
  Given: userId="u_12345", date="2026-04-07", offset=0
  When: GetDailyPrompt(offset=1) is called
  Then: Returns a different prompt than offset=0

TestGratitude_GL_PR_AC3_CyclePrompt_Wraps
  Given: offset = totalPrompts (wraps around)
  When: GetDailyPrompt(offset=totalPrompts) is called
  Then: Returns the same prompt as offset=0 (wraps around)

TestGratitude_GL_PR_AC5_PromptCategories
  Given: Loaded prompt library
  When: Each prompt is inspected
  Then: Every prompt has a non-empty category from the GratitudeCategory enum

TestGratitude_GL_PR_AC6_CategoryDistribution
  Given: Loaded prompt library
  When: Prompts are grouped by category
  Then: Every GratitudeCategory has >= 3 prompts
```

### 1.6 Domain Logic: Sharing Privacy

**Location:** `internal/domain/gratitude/sharing_test.go`

```
TestGratitude_GL_SH_AC3_PrivacyFilter_ExcludesMood
  Given: Entry with moodScore=4
  When: GenerateShareableContent(entry) is called
  Then: Output does not contain mood score

TestGratitude_GL_SH_AC3_PrivacyFilter_ExcludesCategory
  Given: Entry with items tagged with categories
  When: GenerateShareableContent(entry) is called
  Then: Output does not contain category tags

TestGratitude_GL_SH_AC3_PrivacyFilter_ExcludesPhoto
  Given: Entry with photoKey="s3://bucket/photo.jpg"
  When: GenerateShareableContent(entry) is called
  Then: Output does not contain photo key or reference

TestGratitude_GL_SH_AC1_ShareItem
  Given: Entry with 3 items, sharing item at index 1
  When: GenerateShareableContent(entry, itemId="gi_002") is called
  Then: Output contains only the text of item gi_002

TestGratitude_GL_SH_AC2_ShareEntry
  Given: Entry with 3 items
  When: GenerateShareableContent(entry, shareType="entry") is called
  Then: Output contains all 3 item texts and the entry date
```

### 1.7 Domain Logic: Widget Data

**Location:** `internal/domain/gratitude/widget_test.go`

```
TestGratitude_GL_IN_AC3_DashboardWidget_Completed
  Given: User has at least one entry today
  When: GetWidgetData() is called
  Then: completedToday=true, currentStreak > 0

TestGratitude_GL_IN_AC3_DashboardWidget_NotCompleted
  Given: User has no entries today
  When: GetWidgetData() is called
  Then: completedToday=false

TestGratitude_GL_IN_AC3_DashboardWidget_RandomPastItem
  Given: User has 20 past entries
  When: GetWidgetData() is called on same day
  Then: randomPastItem is deterministic (same user + same day = same item)

TestGratitude_GL_IN_AC3_DashboardWidget_NoPastEntries
  Given: User has never created a gratitude entry
  When: GetWidgetData() is called
  Then: randomPastItem=null, completedToday=false, currentStreak=0
```

### 1.8 Handler Tests

**Location:** `internal/handler/gratitude_handler_test.go`

```
TestGratitude_GL_CC_AC1_AuthRequired
  Given: Request without Authorization header
  When: POST /activities/gratitude
  Then: Returns 401 with WWW-Authenticate header

TestGratitude_GL_CC_AC2_ErrorEnvelope
  Given: Invalid request body
  When: POST /activities/gratitude
  Then: Returns { "errors": [{ "code": "rr:0x...", "status": 422, "title": "...", "detail": "..." }] }

TestGratitude_GL_CC_AC3_ResponseEnvelope
  Given: Valid create request
  When: POST /activities/gratitude
  Then: Returns { "data": {...}, "links": {...}, "meta": {...} }

TestGratitude_GL_CC_AC4_CursorPagination
  Given: 75 gratitude entries exist
  When: GET /activities/gratitude?limit=50
  Then: Returns 50 entries with nextCursor in meta.page; second request with cursor returns remaining 25

TestGratitude_GL_IN_AC10_FeatureFlag_Disabled
  Given: Feature flag activity.gratitude is disabled
  When: POST /activities/gratitude
  Then: Returns 404 (feature not found)

TestGratitude_GL_IN_AC10_FeatureFlag_Enabled
  Given: Feature flag activity.gratitude is enabled
  When: POST /activities/gratitude (valid body)
  Then: Returns 201

TestGratitude_GL_DM_AC11_TenantIsolation
  Given: User in tenant "t_acme" creates entry
  When: User in tenant "DEFAULT" queries entries
  Then: Does not see t_acme user's entries

TestGratitude_GL_CC_AC6_CorrelationId
  Given: Any valid request
  When: Response is received
  Then: X-Correlation-Id header is present
```

### 1.9 Permission Tests

**Location:** `internal/domain/gratitude/permissions_test.go`

```
TestGratitude_GL_IN_AC8_CommunityPermissions_SpouseAllowed
  Given: User granted gratitude read permission to spouse contact
  When: Spouse requests user's gratitude entries
  Then: Returns entries (text only, no mood/category/photo)

TestGratitude_GL_IN_AC8_CommunityPermissions_SponsorDenied
  Given: User has NOT granted gratitude read permission to sponsor contact
  When: Sponsor requests user's gratitude entries
  Then: Returns 404 (hides data existence)

TestGratitude_GL_IN_AC8_CommunityPermissions_SpouseMoodExcluded
  Given: Spouse has permission to view gratitude entries
  When: Spouse requests entry detail
  Then: moodScore is null, categories are null, photoKey is null
```

---

## 2. Integration Tests (25% of test budget)

### 2.1 Repository Tests

**Location:** `test/integration/gratitude/repository_test.go`

```
TestGratitude_Repository_CreateAndRetrieve
  Given: MongoDB container running
  When: Insert gratitude entry, then findOne by PK/SK
  Then: Retrieved entry matches inserted data

TestGratitude_Repository_ListReverseChronological
  Given: 5 entries across different dates
  When: find() with sort SK descending
  Then: Entries returned in reverse chronological order

TestGratitude_Repository_CalendarDateQuery
  Given: Entries on 3 different dates in April 2026
  When: Aggregate by calendarDate for month "2026-04"
  Then: Returns 3 dates with correct entry counts

TestGratitude_Repository_FullTextSearch
  Given: Entries containing "sobriety", "sponsor", "coffee"
  When: Text search for "sobriety"
  Then: Returns only entries with matching items

TestGratitude_Repository_ToggleFavorite
  Given: Entry with item gi_002 where isFavorite=false
  When: Update items.$.isFavorite to true
  Then: Item gi_002 isFavorite=true, other items unchanged

TestGratitude_Repository_EditWindowEnforced
  Given: Entry created 25 hours ago
  When: updateOne with CreatedAt >= cutoff condition
  Then: Update fails (no documents matched)

TestGratitude_Repository_CalendarActivityDualWrite
  Given: New gratitude entry created
  When: Query calendarActivities for the same date
  Then: CALENDAR_ACTIVITY document exists with activityType=GRATITUDE

TestGratitude_Repository_FilterCombination
  Given: Entries with various categories, moods, and photo statuses
  When: Query with category=recovery AND moodScore=4 AND hasPhoto=false
  Then: Returns only entries matching all three filters

TestGratitude_Repository_StreakDistinctDates
  Given: 3 entries on same date, 2 entries on another date
  When: distinct("calendarDate") is called
  Then: Returns 2 unique dates
```

### 2.2 Cache Tests

**Location:** `test/integration/gratitude/cache_test.go`

```
TestGratitude_Cache_StreakCachedInValkey
  Given: Streak computed and cached
  When: GetStreak called within TTL
  Then: Returns cached value without hitting MongoDB

TestGratitude_Cache_StreakInvalidatedOnCreate
  Given: Streak cached in Valkey
  When: New gratitude entry created
  Then: Cache key invalidated; next GetStreak reads from MongoDB

TestGratitude_Cache_WidgetCachedInValkey
  Given: Widget data computed and cached
  When: GetWidgetData called within TTL
  Then: Returns cached value

TestGratitude_Cache_CalendarInvalidatedOnCreate
  Given: Calendar month data cached
  When: New entry created for that month
  Then: Calendar cache invalidated
```

### 2.3 Event Tests

**Location:** `test/integration/gratitude/events_test.go`

```
TestGratitude_GL_IN_AC6_StreakNotifications_Milestone7
  Given: User completes 7th consecutive day of gratitude
  When: Entry saved and streak calculated
  Then: SNS notification published with milestone=7 message

TestGratitude_GL_IN_AC6_StreakNotifications_Milestone30
  Given: User completes 30th consecutive day
  When: Entry saved
  Then: SNS notification published with milestone=30 message

TestGratitude_GL_IN_AC7_MissedNudge
  Given: User's last gratitude entry was 4 days ago, threshold=3 days
  When: Scheduled job checks inactivity
  Then: Nudge notification enqueued to SQS

TestGratitude_GL_IN_AC5_PlanScoring
  Given: User has a daily goal with category "emotional"
  When: Gratitude entry created
  Then: Goal auto-checked for the day via event

TestGratitude_GL_IN_AC9_CalendarActivity
  Given: New gratitude entry created
  When: Dual-write event processed
  Then: CALENDAR_ACTIVITY document created with activityType=GRATITUDE
```

---

## 3. Contract Tests (validates against OpenAPI spec)

### 3.1 Request/Response Validation

**Location:** `test/contract/gratitude_test.go`

```
TestGratitude_Contract_CreateEntry_201_MatchesSpec
  Given: Valid CreateGratitudeEntryRequest body
  When: POST /activities/gratitude
  Then: Response body validates against GratitudeEntryResponse schema in openapi.yaml

TestGratitude_Contract_CreateEntry_422_EmptyItems
  Given: Request with items: []
  When: POST /activities/gratitude
  Then: Response body validates against ErrorResponse schema

TestGratitude_Contract_ListEntries_200_MatchesSpec
  Given: Valid query parameters
  When: GET /activities/gratitude?limit=10
  Then: Response body validates against GratitudeEntryListResponse schema

TestGratitude_Contract_GetEntry_200_MatchesSpec
  Given: Valid gratitudeId
  When: GET /activities/gratitude/{gratitudeId}
  Then: Response validates against GratitudeEntryResponse schema

TestGratitude_Contract_UpdateEntry_403_AfterEditWindow
  Given: Entry older than 24 hours
  When: PUT /activities/gratitude/{gratitudeId}
  Then: Response validates against ErrorResponse schema with status 403

TestGratitude_Contract_ToggleFavorite_200_MatchesSpec
  Given: Valid gratitudeId and itemId
  When: PATCH /activities/gratitude/{gratitudeId}/items/{itemId}/favorite
  Then: Response validates against the toggle favorite response schema

TestGratitude_Contract_Search_200_MatchesSpec
  Given: Query q="sobriety"
  When: GET /activities/gratitude/search?q=sobriety
  Then: Response validates against GratitudeSearchResponse schema

TestGratitude_Contract_Calendar_200_MatchesSpec
  Given: Valid month parameter
  When: GET /activities/gratitude/calendar?month=2026-04
  Then: Response validates against GratitudeCalendarResponse schema

TestGratitude_Contract_Streaks_200_MatchesSpec
  Given: Valid period parameter
  When: GET /activities/gratitude/streaks?period=30d
  Then: Response validates against GratitudeStreaksResponse schema

TestGratitude_Contract_DailyPrompt_200_MatchesSpec
  Given: No parameters (defaults)
  When: GET /activities/gratitude/prompts/daily
  Then: Response validates against GratitudePromptResponse schema

TestGratitude_Contract_Widget_200_MatchesSpec
  Given: Authenticated user
  When: GET /activities/gratitude/widget
  Then: Response validates against GratitudeWidgetResponse schema

TestGratitude_Contract_Share_200_MatchesSpec
  Given: Valid share request
  When: POST /activities/gratitude/{gratitudeId}/share
  Then: Response validates against ShareGratitudeResponse schema
```

---

## 4. E2E Tests (5% of test budget)

### 4.1 Complete User Flow

**Location:** `test/e2e/gratitude/flow_test.go`

```
TestGratitude_E2E_CompleteGratitudeFlow
  Given: Authenticated user (persona: Alex) with existing entries
  Steps:
    1. GET /activities/gratitude/prompts/daily -- get a prompt
    2. POST /activities/gratitude -- create entry with 3 items, one using prompt
    3. Verify response includes gratitudeId, currentStreak, warmMessage
    4. GET /activities/gratitude/{gratitudeId} -- retrieve created entry
    5. Verify all items, mood, prompt recorded correctly
    6. PATCH favorite on item gi_002
    7. GET /activities/gratitude/favorites -- verify item appears
    8. GET /activities/gratitude/search?q={text of item 1} -- verify search returns entry
    9. GET /activities/gratitude/calendar?month=2026-04 -- verify date appears
    10. GET /activities/gratitude/streaks -- verify streak incremented
    11. GET /activities/gratitude/widget -- verify completedToday=true

TestGratitude_E2E_EditWindowEnforcement
  Given: Entry created > 24 hours ago
  Steps:
    1. PUT /activities/gratitude/{gratitudeId} -- attempt update
    2. Verify returns 403 with compassionate error message
    3. DELETE /activities/gratitude/{gratitudeId} -- attempt delete
    4. Verify returns 403

TestGratitude_E2E_MultipleEntriesPerDay
  Given: Authenticated user
  Steps:
    1. POST /activities/gratitude -- create first entry at 07:00
    2. POST /activities/gratitude -- create second entry at 12:00
    3. POST /activities/gratitude -- create third entry at 21:00
    4. GET /activities/gratitude?startDate=today -- verify all 3 returned
    5. GET /activities/gratitude/streaks -- verify streak counts as 1 day
    6. GET /activities/gratitude/calendar?month=current -- verify date has entryCount=3

TestGratitude_E2E_ShareWithSupportNetwork
  Given: User with spouse contact who has gratitude view permission
  Steps:
    1. POST /activities/gratitude -- create entry
    2. POST /activities/gratitude/{id}/share with target=supportNetwork, contactIds=[spouse]
    3. Verify shared content contains only text and date (no mood, no category, no photo)
```

---

## 5. Test Data Fixtures

### Persona: Alex (long-term recovery user)

```go
var AlexGratitudeFixtures = []GratitudeEntry{
    {
        GratitudeId: "g_alex_001",
        Timestamp:   time.Date(2026, 4, 1, 7, 0, 0, 0, time.UTC),
        Items: []GratitudeItem{
            {ItemId: "gi_a01", Text: "270 days of sobriety", Category: "recovery", IsFavorite: true, SortOrder: 0},
            {ItemId: "gi_a02", Text: "My wife's forgiveness", Category: "family", IsFavorite: true, SortOrder: 1},
        },
        MoodScore: 4,
    },
    // ... entries for 2026-04-02 through 2026-04-07
}
```

### Persona: Marcus (early recovery, no sponsor)

```go
var MarcusGratitudeFixtures = []GratitudeEntry{
    {
        GratitudeId: "g_marcus_001",
        Timestamp:   time.Date(2026, 4, 5, 8, 0, 0, 0, time.UTC),
        Items: []GratitudeItem{
            {ItemId: "gi_m01", Text: "Made it through another day", Category: "recovery", SortOrder: 0},
        },
        MoodScore: 3,
        PromptUsed: "What is something about your recovery journey you're thankful for right now?",
    },
}
```

---

## 6. Coverage Requirements

| Module | Target | Rationale |
|--------|--------|-----------|
| `internal/domain/gratitude/entry.go` | 90% | Core validation logic |
| `internal/domain/gratitude/streak.go` | 100% | Critical path: streak calculation |
| `internal/domain/gratitude/editwindow.go` | 100% | Critical path: immutable timestamp enforcement |
| `internal/domain/gratitude/prompts.go` | 90% | Deterministic prompt selection |
| `internal/domain/gratitude/sharing.go` | 100% | Critical path: privacy filter (no mood/category/photo shared) |
| `internal/domain/gratitude/analytics.go` | 85% | Category breakdown, volume trends |
| `internal/handler/gratitude_handler.go` | 80% | HTTP handler tests |
| `internal/repository/gratitude_repo.go` | 75% | Covered by integration tests |
| **Overall gratitude module** | **>= 85%** | Above project 80% minimum |
