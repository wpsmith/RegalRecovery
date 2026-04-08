# Affirmations: Test Specifications

**Version:** 1.0.0
**Date:** 2026-04-08
**Status:** Draft
**Traces to:** acceptance-criteria.md, openapi.yaml, mongodb-schema.md

---

## Naming Convention

All test functions follow: `TestAffirmation_AFF_{Domain}_AC{N}_{Description}`

This maps directly to acceptance criteria IDs in `acceptance-criteria.md`.

---

## 1. Unit Tests (70% of test budget)

### 1.1 Domain Logic: Affirmation Validation

**Location:** `internal/domain/affirmation/validation_test.go`

```
TestAffirmation_AFF_DM_AC1_AffirmationStructure
  Given: Affirmation with all required fields (statement, scriptureReference, category, level)
  When: Validator processes the affirmation
  Then: Passes validation

TestAffirmation_AFF_DM_AC1_AffirmationStructure_MissingStatement
  Given: Affirmation with empty statement
  When: Validator processes the affirmation
  Then: Returns validation error "statement is required"

TestAffirmation_AFF_DM_AC2_StatementMaxLength
  Given: Affirmation with statement exactly 500 characters
  When: Validator processes the affirmation
  Then: Passes validation

TestAffirmation_AFF_DM_AC2_StatementMaxLength_Exceeds
  Given: Affirmation with statement of 501 characters
  When: Validator processes the affirmation
  Then: Returns validation error "statement exceeds 500 character maximum"

TestAffirmation_AFF_DM_AC3_CategoryEnum_Valid
  Given: Affirmations with each valid category enum value (table-driven)
  When: Validator processes each
  Then: All pass validation

TestAffirmation_AFF_DM_AC3_CategoryEnum_Invalid
  Given: Affirmation with category "invalid-category"
  When: Validator processes the affirmation
  Then: Returns validation error "invalid category"

TestAffirmation_AFF_DM_AC4_LevelRange_Valid
  Given: Affirmations with levels 1, 2, 3 (table-driven)
  When: Validator processes each
  Then: All pass validation

TestAffirmation_AFF_DM_AC4_LevelRange_Invalid
  Given: Affirmation with level 0, 4, -1, 100 (table-driven)
  When: Validator processes each
  Then: All return validation error "level must be 1, 2, or 3"

TestAffirmation_AFF_DM_AC5_IdPattern_SystemAffirmation
  Given: Affirmation with id "aff_abc123"
  When: ID validator processes
  Then: Passes validation

TestAffirmation_AFF_DM_AC5_IdPattern_CustomAffirmation
  Given: Custom affirmation with id "caff_abc123"
  When: ID validator processes
  Then: Passes validation

TestAffirmation_AFF_DM_AC5_IdPattern_Invalid
  Given: Affirmation with id "invalid_123"
  When: ID validator processes
  Then: Returns validation error "invalid affirmation ID format"
```

### 1.2 Domain Logic: Level Gating

**Location:** `internal/domain/affirmation/level_test.go`

```
TestAffirmation_AFF_LV_AC1_Level1Access
  Given: User with 0 cumulative sobriety days
  When: GetMaxLevel() is called
  Then: Returns 1

TestAffirmation_AFF_LV_AC2_Level2Unlock
  Given: User with 30 cumulative sobriety days
  When: GetMaxLevel() is called
  Then: Returns 2

TestAffirmation_AFF_LV_AC2_Level2Unlock_Below
  Given: User with 29 cumulative sobriety days
  When: GetMaxLevel() is called
  Then: Returns 1

TestAffirmation_AFF_LV_AC3_Level3Unlock
  Given: User with 90 cumulative sobriety days
  When: GetMaxLevel() is called
  Then: Returns 3

TestAffirmation_AFF_LV_AC3_Level3Unlock_Below
  Given: User with 89 cumulative sobriety days
  When: GetMaxLevel() is called
  Then: Returns 2

TestAffirmation_AFF_LV_AC4_PostRelapseLevel1Only
  Given: User with 120 cumulative days, sobriety reset 12 hours ago
  When: GetEffectiveMaxLevel() is called
  Then: Returns 1 (post-relapse 24h restriction)

TestAffirmation_AFF_LV_AC4_PostRelapseLevel1Only_After24h
  Given: User with 120 cumulative days, sobriety reset 25 hours ago
  When: GetEffectiveMaxLevel() is called
  Then: Returns 3 (post-relapse restriction lifted)

TestAffirmation_AFF_LV_AC5_SOSModeMaxLevel2
  Given: User with 120 cumulative days, SOS mode active
  When: GetEffectiveMaxLevel() is called
  Then: Returns 2 (SOS never above Level 2)

TestAffirmation_AFF_LV_AC5_SOSModeMaxLevel2_Level1User
  Given: User with 10 cumulative days, SOS mode active
  When: GetEffectiveMaxLevel() is called
  Then: Returns 1 (SOS does not upgrade level, only caps)

TestAffirmation_AFF_LV_AC6_CumulativeNotStreak
  Given: User with 45 total sobriety days (across 3 streaks: 20, 15, 10)
  When: GetMaxLevel() is called with cumulativeDays=45
  Then: Returns 2 (based on 45 cumulative, not current streak of 10)

TestAffirmation_AFF_LV_AC7_HealthySexualityOptIn_NotOptedIn
  Given: User with 90 cumulative days, healthySexualityOptIn=false
  When: IsHealthySexualityAccessible() is called
  Then: Returns false

TestAffirmation_AFF_LV_AC7_HealthySexualityOptIn_OptedIn
  Given: User with 90 cumulative days, healthySexualityOptIn=true
  When: IsHealthySexualityAccessible() is called
  Then: Returns true

TestAffirmation_AFF_LV_AC7_HealthySexualityOptIn_InsufficientDays
  Given: User with 55 cumulative days, healthySexualityOptIn=true
  When: IsHealthySexualityAccessible() is called
  Then: Returns false (requires 60+)

TestAffirmation_AFF_DM_AC8_HealthySexualityGating
  Given: User with 90 cumulative days, healthySexualityOptIn=false
  When: Filtering affirmations by available categories
  Then: healthySexuality category is excluded from results
```

### 1.3 Domain Logic: Rotation & Selection

**Location:** `internal/domain/affirmation/rotation_test.go`

```
TestAffirmation_AFF_DL_AC1_DeterministicDaily
  Given: userId="u_12345", date="2026-04-08", mode=randomAutomatic
  When: SelectDailyAffirmation() is called twice
  Then: Returns same affirmation both times

TestAffirmation_AFF_DL_AC1_DeterministicDaily_DifferentDay
  Given: userId="u_12345", date changes from "2026-04-08" to "2026-04-09"
  When: SelectDailyAffirmation() is called for each date
  Then: Returns different affirmations

TestAffirmation_AFF_DL_AC2_OwnedPacksOnly
  Given: User owns pack_basic but not pack_premium
  When: SelectDailyAffirmation() runs rotation
  Then: Only selects from pack_basic affirmations

TestAffirmation_AFF_RO_AC1_IndividuallyChosen
  Given: selectionMode=individuallyChosen, chosenAffirmationId="aff_005"
  When: SelectDailyAffirmation() is called
  Then: Returns affirmation aff_005

TestAffirmation_AFF_RO_AC2_RandomAutomatic
  Given: selectionMode=randomAutomatic
  When: SelectDailyAffirmation() is called
  Then: Returns an affirmation from owned packs within user's level

TestAffirmation_AFF_RO_AC3_PermanentPackage
  Given: selectionMode=permanentPackage, activePackId="pack_basic"
  When: SelectDailyAffirmation() is called on consecutive days
  Then: Cycles sequentially through pack_basic affirmations

TestAffirmation_AFF_RO_AC4_DayOfWeekPackage
  Given: selectionMode=dayOfWeekPackage, monday="aff_001", tuesday="aff_002", etc.
  When: SelectDailyAffirmation() is called on a Monday
  Then: Returns aff_001

TestAffirmation_AFF_RO_AC5_RotationWeighting
  Given: selectionMode=randomAutomatic, user has recent triggers, favorites, and under-served categories
  When: BuildWeightedPool() is called
  Then: Trigger-relevant affirmations get 40% weight, favorites 30%, under-served 20%, random 10%

TestAffirmation_AFF_RO_AC6_TriggerOverride
  Given: selectionMode=individuallyChosen (or any mode), triggerCategory="emotional"
  When: GetContextualAffirmation(trigger="emotional") is called
  Then: Returns affirmation tagged with "trigger_emotional" regardless of mode

TestAffirmation_AFF_RO_AC7_NoDuplicatesInCycle
  Given: 10 affirmations in active set, 8 already shown in current cycle
  When: SelectDailyAffirmation() is called
  Then: Returns one of the 2 remaining un-shown affirmations

TestAffirmation_AFF_RO_AC7_NoDuplicatesInCycle_Reset
  Given: All affirmations in active set have been shown
  When: SelectDailyAffirmation() is called
  Then: Cycle resets; new cycle begins
```

### 1.4 Domain Logic: Custom Affirmation

**Location:** `internal/domain/affirmation/custom_test.go`

```
TestAffirmation_AFF_CU_AC1_CreateCustom_Valid
  Given: Valid custom affirmation with statement, category, schedule=daily
  When: CreateCustomAffirmation() is called
  Then: Created successfully with caff_ ID prefix

TestAffirmation_AFF_CU_AC1_CreateCustom_MissingStatement
  Given: Custom affirmation with empty statement
  When: CreateCustomAffirmation() is called
  Then: Returns validation error

TestAffirmation_AFF_CU_AC3_RotationInclusion_Daily
  Given: Custom affirmation with schedule=daily
  When: IsScheduledForToday(monday) is called
  Then: Returns true

TestAffirmation_AFF_CU_AC3_RotationInclusion_Weekdays
  Given: Custom affirmation with schedule=weekdays
  When: IsScheduledForToday(saturday) is called
  Then: Returns false

TestAffirmation_AFF_CU_AC3_RotationInclusion_Custom
  Given: Custom affirmation with schedule=custom, days=["monday", "wednesday", "friday"]
  When: IsScheduledForToday(wednesday) is called
  Then: Returns true

TestAffirmation_AFF_CU_AC4_EditDelete_Edit
  Given: Existing custom affirmation
  When: UpdateCustomAffirmation() with new statement
  Then: Statement updated, CreatedAt unchanged, ModifiedAt updated

TestAffirmation_AFF_CU_AC4_EditDelete_Delete
  Given: Existing custom affirmation
  When: DeleteCustomAffirmation() is called
  Then: Affirmation removed; count decremented

TestAffirmation_AFF_CU_AC5_MaxCustomLimit
  Given: User already has 50 custom affirmations
  When: CreateCustomAffirmation() is called
  Then: Returns 422 with error "maximum 50 custom affirmations reached"

TestAffirmation_AFF_CU_AC5_MaxCustomLimit_Under
  Given: User has 49 custom affirmations
  When: CreateCustomAffirmation() is called
  Then: Created successfully

TestAffirmation_AFF_CU_AC6_UserScoped
  Given: User u_12345 creates custom affirmation
  When: User u_67890 lists custom affirmations
  Then: User u_67890's list does not contain u_12345's custom affirmation
```

### 1.5 Domain Logic: Favorites

**Location:** `internal/domain/affirmation/favorites_test.go`

```
TestAffirmation_AFF_FA_AC1_ToggleFavorite_Add
  Given: Affirmation aff_001 not favorited
  When: AddFavorite("aff_001") is called
  Then: Favorite record created

TestAffirmation_AFF_FA_AC1_ToggleFavorite_Remove
  Given: Affirmation aff_001 is favorited
  When: RemoveFavorite("aff_001") is called
  Then: Favorite record deleted

TestAffirmation_AFF_FA_AC1_ToggleFavorite_CustomAffirmation
  Given: Custom affirmation caff_001
  When: AddFavorite("caff_001") is called
  Then: Favorite record created (works for both system and custom)

TestAffirmation_AFF_FA_AC2_FavoritesList
  Given: User has favorited aff_001, aff_005, caff_002
  When: ListFavorites() is called
  Then: Returns all 3 affirmations with full data

TestAffirmation_AFF_FA_AC3_FavoriteWeighting
  Given: 10 affirmations total, 3 are favorites
  When: BuildWeightedPool() for randomAutomatic mode
  Then: Favorites receive 30% of total weight
```

### 1.6 Domain Logic: Audio Safety

**Location:** `internal/domain/affirmation/audio_test.go`

```
TestAffirmation_AFF_AU_AC2_HeadphoneDisconnectPause
  Given: Audio playback active
  When: Headphone disconnect event occurs
  Then: Playback immediately pauses (non-negotiable safety)

TestAffirmation_AFF_AU_AC4_OfflineTTS
  Given: No network connectivity
  When: TTS playback requested
  Then: On-device TTS engine used; playback succeeds
```

### 1.7 Domain Logic: Progress Tracking

**Location:** `internal/domain/affirmation/progress_test.go`

```
TestAffirmation_AFF_IN_AC8_CumulativeProgress_Increment
  Given: User has totalRead=141
  When: RecordRead() is called
  Then: totalRead incremented to 142

TestAffirmation_AFF_IN_AC8_CumulativeProgress_CategoryBreakdown
  Given: User reads affirmation with category=recovery
  When: RecordRead() is called
  Then: categoryBreakdown.recovery incremented by 1

TestAffirmation_AFF_IN_AC8_CumulativeProgress_LevelBreakdown
  Given: User reads Level 2 affirmation
  When: RecordRead() is called
  Then: levelBreakdown["2"] incremented by 1
```

### 1.8 Domain Logic: Sharing

**Location:** `internal/domain/affirmation/sharing_test.go`

```
TestAffirmation_AFF_IN_AC10_Sharing_TextFormat
  Given: Affirmation with statement and scripture
  When: GenerateShareableContent(format="text") is called
  Then: Output contains statement, scripture reference, and "Regal Recovery" attribution

TestAffirmation_AFF_IN_AC10_Sharing_NoExpansionOrPrayer
  Given: Affirmation with expansion and prayer text
  When: GenerateShareableContent(format="text") is called
  Then: Output contains only statement and scripture (no expansion, no prayer)
```

### 1.9 Domain Logic: Widget

**Location:** `internal/domain/affirmation/widget_test.go`

```
TestAffirmation_AFF_IN_AC4_DashboardWidget_HasRead
  Given: User has read today's affirmation
  When: GetWidgetData() is called
  Then: hasReadToday=true, todayStatement truncated to 100 chars

TestAffirmation_AFF_IN_AC4_DashboardWidget_NotRead
  Given: User has not read today's affirmation
  When: GetWidgetData() is called
  Then: hasReadToday=false, todayStatement still present (preview)

TestAffirmation_AFF_IN_AC4_DashboardWidget_Truncation
  Given: Today's affirmation statement is 300 characters
  When: GetWidgetData() is called
  Then: todayStatement is 100 characters with "..." appended
```

### 1.10 Handler Tests

**Location:** `internal/handler/affirmation_handler_test.go`

```
TestAffirmation_AFF_CC_AC1_AuthRequired
  Given: Request without Authorization header
  When: GET /activities/affirmations/today
  Then: Returns 401 with WWW-Authenticate header

TestAffirmation_AFF_CC_AC2_ErrorEnvelope
  Given: Invalid custom affirmation request body
  When: POST /activities/affirmations/custom
  Then: Returns { "errors": [{ "code": "rr:0x000A0004", "status": 422, "title": "...", "detail": "..." }] }

TestAffirmation_AFF_CC_AC3_ResponseEnvelope
  Given: Valid request for today's affirmation
  When: GET /activities/affirmations/today
  Then: Returns { "data": {...}, "meta": {...} }

TestAffirmation_AFF_CC_AC4_CursorPagination
  Given: 55 affirmations in owned packs
  When: GET /activities/affirmations?limit=20
  Then: Returns 20 affirmations with nextCursor; second request returns next 20

TestAffirmation_AFF_IN_AC6_FeatureFlag_Disabled
  Given: Feature flag activity.affirmations is disabled
  When: GET /activities/affirmations/today
  Then: Returns 404 (feature not found)

TestAffirmation_AFF_IN_AC6_FeatureFlag_Enabled
  Given: Feature flag activity.affirmations is enabled
  When: GET /activities/affirmations/today
  Then: Returns 200

TestAffirmation_AFF_DM_AC7_TenantIsolation
  Given: Custom affirmation created by user in tenant "t_acme"
  When: User in tenant "DEFAULT" queries custom affirmations
  Then: Does not see t_acme user's custom affirmations

TestAffirmation_AFF_CC_AC6_CorrelationId
  Given: Any valid request
  When: Response is received
  Then: X-Correlation-Id header is present

TestAffirmation_AFF_DM_AC6_ImmutableCreatedAt
  Given: Custom affirmation created at "2026-04-01T08:00:00Z"
  When: PUT update request with different body
  Then: CreatedAt remains "2026-04-01T08:00:00Z"; only ModifiedAt changes

TestAffirmation_AFF_DM_AC10_PermanentUnlock
  Given: User purchases premium pack
  When: Pack ownership is queried after subscription lapses
  Then: Pack still shows isOwned=true (permanent unlock)
```

---

## 2. Integration Tests (25% of test budget)

### 2.1 Repository Tests

**Location:** `test/integration/affirmation/repository_test.go`

```
TestAffirmation_Repository_CreateAndRetrieveCustom
  Given: MongoDB container running
  When: Insert custom affirmation, then findOne by PK/SK
  Then: Retrieved affirmation matches inserted data

TestAffirmation_Repository_ListPackAffirmations
  Given: Pack with 10 affirmations seeded
  When: find() with PK=PACK#pack_basic and SK prefix AFFIRMATION#
  Then: Returns 10 affirmations in sortOrder

TestAffirmation_Repository_FilterByCategory
  Given: Pack with affirmations in categories identity(5), recovery(3), strength(2)
  When: find() with PK=PACK#pack_basic and category=recovery
  Then: Returns 3 affirmations

TestAffirmation_Repository_FilterByLevel
  Given: Pack with Level 1(20), Level 2(15), Level 3(10)
  When: find() with level <= 2
  Then: Returns 35 affirmations (Level 1 + Level 2)

TestAffirmation_Repository_ToggleFavorite
  Given: User with no favorites
  When: Insert favorite for aff_001, then list favorites
  Then: Returns aff_001

TestAffirmation_Repository_ToggleFavorite_Remove
  Given: User with aff_001 favorited
  When: Delete favorite for aff_001, then list favorites
  Then: Returns empty list

TestAffirmation_Repository_RecordRead
  Given: No read history
  When: Insert read record for today
  Then: Read record persisted with calendarDate

TestAffirmation_Repository_ReadHistory_DateRange
  Given: Read records across 30 days
  When: find() with calendarDate range
  Then: Returns only records in range

TestAffirmation_Repository_CustomAffirmation_MaxLimit
  Given: User with 50 custom affirmations
  When: countDocuments for EntityType=CUSTOM_AFFIRMATION
  Then: Returns 50

TestAffirmation_Repository_RotationState_Upsert
  Given: No rotation state exists
  When: updateOne with upsert=true
  Then: Rotation state created

TestAffirmation_Repository_CalendarActivityDualWrite
  Given: Affirmation read recorded
  When: Query calendarActivities for same date
  Then: CALENDAR_ACTIVITY document exists with activityType=AFFIRMATION

TestAffirmation_Repository_FullTextSearch
  Given: Affirmations containing "freedom", "courage", "identity"
  When: Text search for "freedom"
  Then: Returns only affirmations with matching text
```

### 2.2 Cache Tests

**Location:** `test/integration/affirmation/cache_test.go`

```
TestAffirmation_Cache_TodayCachedInValkey
  Given: Today's affirmation computed and cached
  When: GetTodayAffirmation called within same day
  Then: Returns cached value without hitting MongoDB

TestAffirmation_Cache_TodayInvalidatedAtMidnight
  Given: Today's affirmation cached
  When: User timezone crosses midnight
  Then: Cache expired; new affirmation computed

TestAffirmation_Cache_FavoritesInvalidatedOnToggle
  Given: Favorites list cached
  When: AddFavorite() or RemoveFavorite() called
  Then: Favorites cache invalidated

TestAffirmation_Cache_ProgressInvalidatedOnRead
  Given: Progress data cached
  When: New affirmation read recorded
  Then: Progress cache invalidated
```

### 2.3 Event Tests

**Location:** `test/integration/affirmation/events_test.go`

```
TestAffirmation_AFF_IN_AC5_CalendarActivity
  Given: New affirmation read recorded
  When: Dual-write event processed
  Then: CALENDAR_ACTIVITY document created with activityType=AFFIRMATION

TestAffirmation_AFF_IN_AC1_MorningCommitment
  Given: Morning commitment completed
  When: Commitment confirmation event fires
  Then: Today's affirmation is available for display

TestAffirmation_AFF_IN_AC2_PostUrgeLog
  Given: Urge log completed with triggerCategory=emotional
  When: Post-urge-log event fires
  Then: Contextual affirmation for "emotional" trigger is delivered
```

---

## 3. Contract Tests (validates against OpenAPI spec)

### 3.1 Request/Response Validation

**Location:** `test/contract/affirmation_test.go`

```
TestAffirmation_Contract_TodayAffirmation_200_MatchesSpec
  Given: Authenticated user with owned packs
  When: GET /activities/affirmations/today
  Then: Response validates against AffirmationResponse schema in openapi.yaml

TestAffirmation_Contract_ContextualAffirmation_200_MatchesSpec
  Given: triggerCategory=emotional
  When: GET /activities/affirmations/contextual?triggerCategory=emotional
  Then: Response validates against AffirmationResponse schema

TestAffirmation_Contract_ListAffirmations_200_MatchesSpec
  Given: Valid query parameters
  When: GET /activities/affirmations?limit=10
  Then: Response validates against paginated AffirmationResponse array schema

TestAffirmation_Contract_CreateCustom_201_MatchesSpec
  Given: Valid CreateCustomAffirmationRequest body
  When: POST /activities/affirmations/custom
  Then: Response validates against CustomAffirmationResponse schema

TestAffirmation_Contract_CreateCustom_422_MissingStatement
  Given: Request with empty statement
  When: POST /activities/affirmations/custom
  Then: Response validates against ErrorResponse schema

TestAffirmation_Contract_UpdateCustom_200_MatchesSpec
  Given: Valid UpdateCustomAffirmationRequest body
  When: PUT /activities/affirmations/custom/{id}
  Then: Response validates against CustomAffirmationResponse schema

TestAffirmation_Contract_DeleteCustom_204
  Given: Valid custom affirmation ID
  When: DELETE /activities/affirmations/custom/{id}
  Then: Returns 204 No Content

TestAffirmation_Contract_Favorites_200_MatchesSpec
  Given: User with favorites
  When: GET /activities/affirmations/favorites
  Then: Response validates against paginated AffirmationResponse schema

TestAffirmation_Contract_ToggleFavorite_204
  Given: Valid affirmation ID
  When: POST /activities/affirmations/{id}/favorite
  Then: Returns 204

TestAffirmation_Contract_Rotation_200_MatchesSpec
  Given: Authenticated user
  When: GET /activities/affirmations/rotation
  Then: Response validates against RotationStateResponse schema

TestAffirmation_Contract_UpdateRotation_200_MatchesSpec
  Given: Valid UpdateRotationStateRequest body
  When: PUT /activities/affirmations/rotation
  Then: Response validates against RotationStateResponse schema

TestAffirmation_Contract_Progress_200_MatchesSpec
  Given: Authenticated user
  When: GET /activities/affirmations/progress
  Then: Response validates against AffirmationProgressResponse schema

TestAffirmation_Contract_ReadHistory_200_MatchesSpec
  Given: User with read history
  When: GET /activities/affirmations/history?limit=10
  Then: Response validates against paginated AffirmationReadResponse schema

TestAffirmation_Contract_Packs_200_MatchesSpec
  Given: Authenticated user
  When: GET /activities/affirmations/packs
  Then: Response validates against AffirmationPackResponse array schema

TestAffirmation_Contract_Widget_200_MatchesSpec
  Given: Authenticated user
  When: GET /activities/affirmations/widget
  Then: Response validates against AffirmationWidgetResponse schema

TestAffirmation_Contract_Share_200_MatchesSpec
  Given: Valid share request
  When: POST /activities/affirmations/{id}/share
  Then: Response matches share response schema

TestAffirmation_Contract_HealthySexuality_OptIn_204
  Given: User with 60+ cumulative days
  When: POST /activities/affirmations/healthy-sexuality/opt-in
  Then: Returns 204

TestAffirmation_Contract_HealthySexuality_OptIn_403
  Given: User with 55 cumulative days
  When: POST /activities/affirmations/healthy-sexuality/opt-in
  Then: Returns 403 with ErrorResponse schema

TestAffirmation_Contract_FeatureFlag_404
  Given: Feature flag activity.affirmations disabled
  When: GET /activities/affirmations/today
  Then: Returns 404 with ErrorResponse matching FeatureDisabled response
```

---

## 4. E2E Tests (5% of test budget)

### 4.1 Complete User Flow

**Location:** `test/e2e/affirmation/flow_test.go`

```
TestAffirmation_E2E_CompleteDailyFlow
  Given: Authenticated user (persona: Alex, 270 cumulative days) with owned packs
  Steps:
    1. GET /activities/affirmations/today -- get daily affirmation
    2. Verify response includes statement, scriptureReference, level <= 3, isFavorite
    3. Verify meta includes userLevel=3, cumulativeDays=270, selectionMode
    4. POST /activities/affirmations/{id}/favorite -- add to favorites
    5. GET /activities/affirmations/favorites -- verify it appears
    6. GET /activities/affirmations/progress -- verify totalRead incremented
    7. GET /activities/affirmations/widget -- verify hasReadToday=true

TestAffirmation_E2E_CustomAffirmationLifecycle
  Given: Authenticated user with < 50 custom affirmations
  Steps:
    1. POST /activities/affirmations/custom -- create custom affirmation
    2. Verify 201 with caff_ ID prefix
    3. GET /activities/affirmations/custom -- verify it appears in list
    4. PUT /activities/affirmations/custom/{id} -- update statement
    5. Verify statement changed, CreatedAt unchanged
    6. DELETE /activities/affirmations/custom/{id} -- delete
    7. GET /activities/affirmations/custom -- verify removed

TestAffirmation_E2E_LevelGatingProgression
  Given: User with 20 cumulative days (Level 1)
  Steps:
    1. GET /activities/affirmations?level=2 -- should return empty (user only has Level 1)
    2. GET /activities/affirmations -- verify all returned are Level 1
    3. Simulate 30 cumulative days
    4. GET /activities/affirmations?level=2 -- should now return Level 2 affirmations
    5. GET /activities/affirmations -- verify Level 1 and 2 returned

TestAffirmation_E2E_PostRelapseRestriction
  Given: User with 120 cumulative days (Level 3), then sobriety reset
  Steps:
    1. GET /activities/affirmations/today -- verify Level 1 affirmation returned
    2. Verify meta.userLevel=1 within 24h of reset
    3. After 24h, verify meta.userLevel=3 restored

TestAffirmation_E2E_ContextualTriggerDelivery
  Given: User completes urge log with triggerCategory=relational
  Steps:
    1. GET /activities/affirmations/contextual?triggerCategory=relational&source=postUrgeLog
    2. Verify returned affirmation has tags containing "trigger_relational"
    3. Verify read recorded with source=triggerOverride

TestAffirmation_E2E_HealthySexualityGating
  Given: User with 55 cumulative days
  Steps:
    1. POST /activities/affirmations/healthy-sexuality/opt-in -- returns 403
    2. Simulate 60+ days
    3. POST /activities/affirmations/healthy-sexuality/opt-in -- returns 204
    4. GET /activities/affirmations?category=healthySexuality -- returns results
    5. DELETE /activities/affirmations/healthy-sexuality/opt-in -- revoke
    6. GET /activities/affirmations?category=healthySexuality -- returns empty
```

---

## 5. Test Data Fixtures

### Persona: Alex (long-term recovery, 270 cumulative days, Level 3)

```go
var AlexAffirmationFixtures = AffirmationTestContext{
    UserId:           "u_alex",
    CumulativeDays:   270,
    MaxLevel:         3,
    OwnedPacks:       []string{"pack_basic_affirmations", "pack_premium_strength"},
    Favorites:        []string{"aff_001", "aff_015", "aff_042"},
    CustomAffirmations: []CustomAffirmation{
        {Id: "caff_alex_001", Statement: "My wife's trust is being rebuilt one honest day at a time.", Category: "family", Schedule: "daily"},
    },
    HealthySexualityOptIn: true,
    RotationMode:     "randomAutomatic",
}
```

### Persona: Marcus (early recovery, 15 cumulative days, Level 1)

```go
var MarcusAffirmationFixtures = AffirmationTestContext{
    UserId:           "u_marcus",
    CumulativeDays:   15,
    MaxLevel:         1,
    OwnedPacks:       []string{"pack_basic_affirmations"},
    Favorites:        []string{"aff_003"},
    CustomAffirmations: nil,
    HealthySexualityOptIn: false,
    RotationMode:     "randomAutomatic",
}
```

### Persona: Diego (30 cumulative days, Level 2, Spanish)

```go
var DiegoAffirmationFixtures = AffirmationTestContext{
    UserId:           "u_diego",
    CumulativeDays:   30,
    MaxLevel:         2,
    OwnedPacks:       []string{"pack_basic_affirmations_es"},
    Favorites:        []string{},
    CustomAffirmations: []CustomAffirmation{
        {Id: "caff_diego_001", Statement: "Mi familia merece lo mejor de mi.", Category: "family", Schedule: "daily"},
    },
    HealthySexualityOptIn: false,
    RotationMode:     "permanentPackage",
    Language:         "es",
}
```

---

## 6. Coverage Requirements

| Module | Target | Rationale |
|--------|--------|-----------|
| `internal/domain/affirmation/validation.go` | 90% | Core validation logic |
| `internal/domain/affirmation/level.go` | 100% | Critical path: level gating, post-relapse, SOS |
| `internal/domain/affirmation/rotation.go` | 100% | Critical path: selection algorithm, weighting |
| `internal/domain/affirmation/custom.go` | 90% | Custom CRUD with limit enforcement |
| `internal/domain/affirmation/favorites.go` | 90% | Favorite toggle + weighting |
| `internal/domain/affirmation/progress.go` | 85% | Cumulative counters |
| `internal/domain/affirmation/sharing.go` | 100% | Critical path: no private data leaked |
| `internal/domain/affirmation/audio.go` | 100% | Critical path: headphone disconnect (safety) |
| `internal/handler/affirmation_handler.go` | 80% | HTTP handler tests |
| `internal/repository/affirmation_repo.go` | 75% | Covered by integration tests |
| **Overall affirmation module** | **>= 85%** | Above project 80% minimum |
