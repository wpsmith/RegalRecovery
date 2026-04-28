# Person Check-ins -- Test Specifications

**Activity:** Person Check-ins
**Priority:** P1 (Wave 2)
**Feature Flag:** `activity.person-check-ins`

---

## 1. Test Naming Convention

All test function names reference the acceptance criterion they verify using the format:

```
Test<Domain>_<CriterionID>_<Behavior>
```

Example: `TestPersonCheckIn_FR_PCI_1_1_CreatesEntryWithImmutableTimestamp`

---

## 2. Unit Tests (60-70%)

### 2.1 Check-in Creation & Validation

**Location:** `internal/domain/person_checkin/checkin_test.go`

```
TestPersonCheckIn_FR_PCI_1_1_CreatesEntryWithImmutableTimestamp
TestPersonCheckIn_FR_PCI_1_2_RejectsInvalidCheckInType
TestPersonCheckIn_FR_PCI_1_3_RejectsInvalidMethod
TestPersonCheckIn_FR_PCI_1_4_RejectsContactNameExceeding50Chars
TestPersonCheckIn_FR_PCI_1_5_RejectsNotesExceeding1000Chars
TestPersonCheckIn_FR_PCI_1_6_RejectsQualityRatingOutOfRange
TestPersonCheckIn_FR_PCI_1_7_RejectsInvalidTopicDiscussed
TestPersonCheckIn_FR_PCI_1_8_RejectsMoreThan3FollowUpItems
TestPersonCheckIn_FR_PCI_1_8_RejectsFollowUpItemExceeding200Chars
TestPersonCheckIn_FR_PCI_1_9_RejectsDurationMinutesOutOfRange
TestPersonCheckIn_FR_PCI_1_10_AcceptsBackdatedTimestamp
TestPersonCheckIn_FR_PCI_1_11_SuggestsPreviousContactName
TestPersonCheckIn_NFR_PCI_1_CreatedAtIsImmutableOnUpdate
TestPersonCheckIn_CheckInTypeIsImmutableOnUpdate
TestPersonCheckIn_AllowsNullOptionalFields
TestPersonCheckIn_DefaultsTimestampToNowWhenOmitted
TestPersonCheckIn_CounselorSubCategory_AcceptsValidValues
TestPersonCheckIn_CounselorSubCategory_RejectsForNonCounselorType
```

### 2.2 Quick Log

**Location:** `internal/domain/person_checkin/quick_log_test.go`

```
TestPersonCheckIn_FR_PCI_2_1_QuickLogCreatesWithMinimalFields
TestPersonCheckIn_FR_PCI_2_1_QuickLogDefaultsMethodToLastUsed
TestPersonCheckIn_FR_PCI_2_1_QuickLogDefaultsMethodToInPersonWhenNoHistory
TestPersonCheckIn_FR_PCI_2_2_QuickLogEntryExpandableViaPatch
TestPersonCheckIn_FR_PCI_2_2_PatchUpdatesModifiedAtNotCreatedAt
```

### 2.3 Streak Calculation

**Location:** `internal/domain/person_checkin/streak_test.go`

```
TestPersonCheckInStreak_FR_PCI_4_1_DailyStreakCountsConsecutiveDays
TestPersonCheckInStreak_FR_PCI_4_2_WeeklyStreakCountsConsecutiveWeeks
TestPersonCheckInStreak_FR_PCI_4_3_DailyStreakResetsOnMissedDay
TestPersonCheckInStreak_FR_PCI_4_3_PreservesLongestStreakOnReset
TestPersonCheckInStreak_FR_PCI_4_4_MultipleSameDayCountsAsOneDay
TestPersonCheckInStreak_FR_PCI_4_5_BackdatedEntryFillsGapInStreak
TestPersonCheckInStreak_FR_PCI_4_6_XPerWeekRequiresConfiguredCount
TestPersonCheckInStreak_FR_PCI_4_6_XPerWeekResetsWhenCountNotMet
TestPersonCheckInStreak_FR_PCI_4_7_FrequencyDashboardIncludesAllMetrics
TestPersonCheckInStreak_FR_PCI_5_1_FrequencyChangeTriggersRecalculation
TestPersonCheckInStreak_FR_PCI_5_2_DefaultCounselorFrequencyIsWeekly
TestPersonCheckInStreak_IndependentPerSubType
TestPersonCheckInStreak_DeletionTriggersRecalculation
TestPersonCheckInStreak_EmptyHistory_ReturnsZeroStreak
TestPersonCheckInStreak_TimezoneHandling_UsesUserTimezone
```

### 2.4 Settings & Configuration

**Location:** `internal/domain/person_checkin/settings_test.go`

```
TestPersonCheckInSettings_DefaultSpouseInactivityAlert3Days
TestPersonCheckInSettings_DefaultSponsorInactivityAlert5Days
TestPersonCheckInSettings_DefaultCounselorInactivityAlert10Days
TestPersonCheckInSettings_DefaultCounselorStreakFrequencyWeekly
TestPersonCheckInSettings_UpdateInactivityThreshold
TestPersonCheckInSettings_UpdateStreakFrequency
TestPersonCheckInSettings_RejectsInvalidStreakFrequency
TestPersonCheckInSettings_RejectsInactivityAlertDaysOutOfRange
TestPersonCheckInSettings_SavesLastUsedMethodOnCheckIn
```

### 2.5 Trends & Insights

**Location:** `internal/domain/person_checkin/trends_test.go`

```
TestPersonCheckInTrends_FR_PCI_8_1_FrequencyOverTime_7Day
TestPersonCheckInTrends_FR_PCI_8_1_FrequencyOverTime_30Day
TestPersonCheckInTrends_FR_PCI_8_1_FrequencyOverTime_90Day
TestPersonCheckInTrends_FR_PCI_8_2_MethodDistributionPerSubType
TestPersonCheckInTrends_FR_PCI_8_3_QualityTrendImproving
TestPersonCheckInTrends_FR_PCI_8_3_QualityTrendDeclining
TestPersonCheckInTrends_FR_PCI_8_3_QualityTrendStable
TestPersonCheckInTrends_FR_PCI_8_4_TopicFrequencyAcrossAllCheckIns
TestPersonCheckInTrends_FR_PCI_8_4_TopicFrequencyPerSubType
TestPersonCheckInTrends_FR_PCI_8_5_BalanceAnalysisDetectsGaps
TestPersonCheckInTrends_FR_PCI_8_5_BalanceAnalysisNoGapsWhenBalanced
TestPersonCheckInTrends_EmptyHistory_ReturnsEmptyTrends
TestPersonCheckInTrends_SingleSubType_OmitsBalanceGaps
```

### 2.6 Inactivity Alerts

**Location:** `internal/domain/person_checkin/inactivity_test.go`

```
TestPersonCheckInInactivity_FR_PCI_9_1_SpouseAlertAfter3Days
TestPersonCheckInInactivity_FR_PCI_9_2_SponsorAlertAfter5Days
TestPersonCheckInInactivity_FR_PCI_9_3_CounselorAlertAfter10Days
TestPersonCheckInInactivity_FR_PCI_9_4_NoAlertForUnconfiguredSubType
TestPersonCheckInInactivity_FR_PCI_9_5_CustomThresholdUsedForAlert
TestPersonCheckInInactivity_NoAlertWithinThreshold
TestPersonCheckInInactivity_AlertIncludesQuickLogAction
TestPersonCheckInInactivity_AlertMessageIncludesContactName
```

### 2.7 Permissions

**Location:** `internal/domain/person_checkin/permissions_test.go`

```
TestPersonCheckInPermission_FR_PCI_10_1_SpouseSeesOnlySpouseCheckIns
TestPersonCheckInPermission_FR_PCI_10_2_SponsorSeesAllSubTypes
TestPersonCheckInPermission_FR_PCI_10_3_NoPermission_Returns404
TestPersonCheckInPermission_CounselorSeesAllSubTypes
TestPersonCheckInPermission_DefaultDeny_NoAccessWithoutGrant
```

### 2.8 Follow-up Items

**Location:** `internal/domain/person_checkin/followup_test.go`

```
TestPersonCheckInFollowUp_FR_PCI_7_1_FollowUpItemsStoredWithCheckIn
TestPersonCheckInFollowUp_FR_PCI_7_2_ConvertToGoal_CreatesGoalEntity
TestPersonCheckInFollowUp_FR_PCI_7_2_ConvertToGoal_LinksGoalIdBack
TestPersonCheckInFollowUp_ConvertToGoal_InvalidIndex_Returns404
TestPersonCheckInFollowUp_ConvertToGoal_AlreadyConverted_Returns409
```

### 2.9 Feature Flag Gating

**Location:** `internal/domain/person_checkin/flag_test.go`

```
TestPersonCheckIn_NFR_PCI_4_FlagDisabled_Returns404
TestPersonCheckIn_NFR_PCI_4_FlagEnabled_AllowsAccess
TestPersonCheckIn_NFR_PCI_4_FlagDisabled_AllEndpointsReturn404
```

---

## 3. Integration Tests (20-30%)

**Location:** `test/integration/person_checkin/`

### 3.1 Repository Tests

**File:** `repository_test.go`

```
TestPersonCheckInRepo_Create_PersistsToMongoDB
TestPersonCheckInRepo_Create_DualWritesToCalendarActivities
TestPersonCheckInRepo_GetByUser_ReturnsSortedByTimestampDesc
TestPersonCheckInRepo_GetByUser_FiltersByCheckInType
TestPersonCheckInRepo_GetByUser_FiltersByDateRange
TestPersonCheckInRepo_GetByUser_CursorPagination
TestPersonCheckInRepo_GetById_ReturnsCorrectEntry
TestPersonCheckInRepo_GetById_NotFound_ReturnsNil
TestPersonCheckInRepo_Update_ModifiesOptionalFieldsOnly
TestPersonCheckInRepo_Update_DoesNotModifyCreatedAt
TestPersonCheckInRepo_Delete_RemovesEntryAndCalendarActivity
TestPersonCheckInRepo_Delete_NonExistent_ReturnsNotFound
```

### 3.2 Streak Repository Tests

**File:** `streak_repository_test.go`

```
TestPersonCheckInStreakRepo_GetByUser_ReturnsAllSubTypeStreaks
TestPersonCheckInStreakRepo_GetByType_ReturnsSingleStreak
TestPersonCheckInStreakRepo_Recalculate_UpdatesStreakFromHistory
TestPersonCheckInStreakRepo_Recalculate_BackdateTriggersRecalc
```

### 3.3 Cache Integration Tests

**File:** `cache_test.go`

```
TestPersonCheckInCache_StreakReadFromValkey_OnCacheHit
TestPersonCheckInCache_StreakReadFromMongoDB_OnCacheMiss
TestPersonCheckInCache_StreakInvalidated_OnNewCheckIn
TestPersonCheckInCache_StreakInvalidated_OnDeletion
TestPersonCheckInCache_StreakInvalidated_OnSettingsChange
TestPersonCheckInCache_TTL_5Minutes
```

### 3.4 Event Processing Tests

**File:** `events_test.go`

```
TestPersonCheckInEvent_NewCheckIn_PublishesStreakUpdateEvent
TestPersonCheckInEvent_StreakMilestone_PublishesNotification
TestPersonCheckInEvent_InactivityAlert_PublishesNotification
TestPersonCheckInEvent_CrossReference_PhoneCallToPersonCheckIn
TestPersonCheckInEvent_CrossReference_FANOSToPersonCheckIn
```

### 3.5 Settings Repository Tests

**File:** `settings_repository_test.go`

```
TestPersonCheckInSettingsRepo_Get_ReturnsDefaults_WhenNoSettings
TestPersonCheckInSettingsRepo_Update_PersistsChanges
TestPersonCheckInSettingsRepo_Update_PartialUpdate_MergesCorrectly
```

---

## 4. End-to-End Tests (5-10%)

**Location:** `test/e2e/person_checkin/`

### 4.1 Full Check-in Flow

**File:** `checkin_flow_test.go`

```
TestPersonCheckIn_E2E_CreateRetrieveUpdateDelete
TestPersonCheckIn_E2E_QuickLogThenExpandEntry
TestPersonCheckIn_E2E_BackdatedCheckInRecalculatesStreak
TestPersonCheckIn_E2E_MultipleCheckInsSameDayStreakUnaffected
```

### 4.2 Streak Flow

**File:** `streak_flow_test.go`

```
TestPersonCheckIn_E2E_DailyStreakIncrements_Over7Days
TestPersonCheckIn_E2E_StreakResets_AfterMissedDay
TestPersonCheckIn_E2E_ChangeFrequency_RecalculatesStreak
TestPersonCheckIn_E2E_AllThreeSubTypeStreaksIndependent
```

### 4.3 Permissions Flow

**File:** `permissions_flow_test.go`

```
TestPersonCheckIn_E2E_SpouseViewsSpouseCheckInsOnly
TestPersonCheckIn_E2E_SponsorViewsAllSubTypes
TestPersonCheckIn_E2E_NoPermission_Returns404
```

### 4.4 Trends Flow

**File:** `trends_flow_test.go`

```
TestPersonCheckIn_E2E_Trends_30Day_ReturnsFrequencyAndBalance
TestPersonCheckIn_E2E_Calendar_ReturnsColorCodedDays
```

### 4.5 Follow-up to Goal Flow

**File:** `followup_goal_test.go`

```
TestPersonCheckIn_E2E_ConvertFollowUpToGoal_CreatesLinkedGoal
```

### 4.6 Feature Flag Flow

**File:** `feature_flag_test.go`

```
TestPersonCheckIn_E2E_FlagDisabled_AllEndpoints404
TestPersonCheckIn_E2E_FlagEnabled_EndpointsWork
```

---

## 5. Contract Tests

**Location:** `test/contract/person_checkin_test.go`

### 5.1 OpenAPI Spec Conformance

```
TestContract_PersonCheckIn_CreateRequest_MatchesSpec
TestContract_PersonCheckIn_CreateResponse_MatchesSpec
TestContract_PersonCheckIn_ListResponse_MatchesSpec
TestContract_PersonCheckIn_StreaksResponse_MatchesSpec
TestContract_PersonCheckIn_SettingsResponse_MatchesSpec
TestContract_PersonCheckIn_TrendsResponse_MatchesSpec
TestContract_PersonCheckIn_CalendarResponse_MatchesSpec
TestContract_PersonCheckIn_ErrorResponse_MatchesSpec
TestContract_PersonCheckIn_PaginationLinks_MatchesSpec
TestContract_PersonCheckIn_QuickLogRequest_MatchesSpec
TestContract_PersonCheckIn_UpdateRequest_ContentType_MergePatch
```

---

## 6. Mobile Tests

### 6.1 Android (Kotlin)

**Location:** `androidApp/app/src/test/java/com/regalrecovery/personcheckin/`

```kotlin
// PersonCheckInViewModelTest.kt
`quick log displays last-used method for sub-type`()
`streak display formats days correctly`()
`streak display formats weeks correctly for counselor`()
`quality rating displays descriptive label`()
`topic chips render correct set of options`()
`follow-up item count limited to 3`()
`offline queue preserves check-in for sync`()
`calendar view shows color-coded dots per sub-type`()

// PersonCheckInApiClientTest.kt
`create check-in sends correct request body`()
`list check-ins parses cursor pagination`()
`quick log sends minimal request`()
`patch sends merge-patch content type`()
```

### 6.2 iOS (Swift)

**Location:** `iosApp/RegalRecoveryTests/PersonCheckIn/`

```swift
// PersonCheckInViewModelTests.swift
func testQuickLogDisplaysLastUsedMethod()
func testStreakDisplayFormatsDaysCorrectly()
func testStreakDisplayFormatsWeeksForCounselor()
func testQualityRatingDisplaysDescriptiveLabel()
func testTopicChipsRenderCorrectSet()
func testFollowUpItemCountLimitedTo3()
func testOfflineQueuePreservesCheckInForSync()
func testCalendarViewShowsColorCodedDots()

// PersonCheckInAPIClientTests.swift
func testCreateCheckInSendsCorrectRequestBody()
func testListCheckInsParseCursorPagination()
func testQuickLogSendsMinimalRequest()
func testPatchSendsMergePatchContentType()
```

---

## 7. Coverage Requirements

| Scope | Target |
|-------|--------|
| Overall person check-in domain | 90% |
| Streak calculation logic | 100% |
| Permission checking | 100% |
| Inactivity alert logic | 100% |
| Validation logic | 90% |
| Trend calculation | 85% |
| Handler layer | 80% |
| Repository layer | 80% |

---

## 8. Test Data Fixtures

### Persona Extensions

```go
// pkg/fixtures/person_checkin_fixtures.go

// Alex: married, has sponsor, has counselor -- uses all 3 sub-types
var AlexPersonCheckIns = PersonCheckInFixtures{
    SpouseCheckIns: generateDailyCheckIns("spouse", "Emily", 30, "in-person"),
    SponsorCheckIns: generateDailyCheckIns("sponsor", "Mike S.", 30, "phone-call"),
    CounselorCheckIns: generateWeeklyCheckIns("counselor-coach", "Dr. Johnson", 12, "in-person"),
}

// Marcus: no spouse, no sponsor -- only counselor configured
var MarcusPersonCheckIns = PersonCheckInFixtures{
    SpouseCheckIns: nil, // not configured
    SponsorCheckIns: nil, // not configured
    CounselorCheckIns: generateWeeklyCheckIns("counselor-coach", "Dr. Williams", 8, "video-call"),
}

// Diego: married, has sponsor -- no counselor
var DiegoPersonCheckIns = PersonCheckInFixtures{
    SpouseCheckIns: generateDailyCheckIns("spouse", "Maria", 14, "in-person"),
    SponsorCheckIns: generateDailyCheckIns("sponsor", "Carlos", 14, "phone-call"),
    CounselorCheckIns: nil, // not configured
}
```
