# Phone Calls Activity -- Test Specifications

**Activity:** Phone Calls
**Priority:** P1 (Wave 2)
**Feature Flag:** `activity.phone-calls`

---

## Test Naming Convention

All test functions reference the acceptance criterion they verify:

```
Test<Domain>_<AC-ID>_<Scenario>
```

---

## 1. Unit Tests (60-70%)

**Location:** `internal/domain/phonecalls/*_test.go`

### 1.1 Call Log Validation

```
TestPhoneCall_AC_PC_1_CreateWithRequiredFields
TestPhoneCall_AC_PC_2_DirectionValidation_Made
TestPhoneCall_AC_PC_2_DirectionValidation_Received
TestPhoneCall_AC_PC_2_DirectionValidation_InvalidValue_RejectsRequest
TestPhoneCall_AC_PC_3_ContactTypeValidation_AllValidValues
TestPhoneCall_AC_PC_3_ContactTypeValidation_InvalidValue_RejectsRequest
TestPhoneCall_AC_PC_4_CustomContactType_RequiresLabel
TestPhoneCall_AC_PC_4_CustomContactType_WithLabel_Succeeds
TestPhoneCall_AC_PC_5_ConnectedStatus_True
TestPhoneCall_AC_PC_5_ConnectedStatus_False
TestPhoneCall_AC_PC_6_OptionalFields_AllOmitted_Succeeds
TestPhoneCall_AC_PC_7_ContactName_ExceedsMaxLength_Rejects
TestPhoneCall_AC_PC_7_ContactName_AtMaxLength_Accepts
TestPhoneCall_AC_PC_8_Notes_ExceedsMaxLength_Rejects
TestPhoneCall_AC_PC_8_Notes_AtMaxLength_Accepts
TestPhoneCall_AC_PC_9_Duration_ZeroIsValid
TestPhoneCall_AC_PC_9_Duration_NegativeIsRejected
TestPhoneCall_AC_PC_9_Duration_NullIsValid
TestPhoneCall_AC_PC_10_BackdatedTimestamp_Accepted
TestPhoneCall_AC_PC_11_TimestampImmutable_UpdateRejectsTimestampChange
TestPhoneCall_AC_PC_11_TimestampImmutable_OtherFieldsUpdateSuccessfully
```

### 1.2 Quick Log

```
TestQuickLog_AC_PC_20_MinimalFields_Succeeds
TestQuickLog_AC_PC_20_DefaultDirection_IsMade
TestQuickLog_AC_PC_20_DefaultConnected_IsTrue
TestQuickLog_AC_PC_20_TimestampDefaultsToNow
TestQuickLog_AC_PC_21_ExpandQuickLog_AddsNameDurationNotes
TestQuickLog_AC_PC_21_ExpandQuickLog_PreservesCreatedAtAndTimestamp
```

### 1.3 Saved Contacts

```
TestSavedContact_AC_PC_30_CreateWithNameAndType
TestSavedContact_AC_PC_31_MaxTenContacts_RejectsEleventh
TestSavedContact_AC_PC_31_MaxTenContacts_AcceptsTenth
TestSavedContact_AC_PC_32_PhoneNumberOptional_CreatesWithout
TestSavedContact_AC_PC_32_PhoneNumberPresent_EnablesCallNow
TestSavedContact_AC_PC_33_DeletePreservesHistoricalLogs
TestSavedContact_AC_PC_34_ContactsWithPhoneNumbers_AvailableInEmergencyTools
```

### 1.4 Call Streak Calculation

```
TestCallStreak_AC_PC_50_AttemptedCallCountsTowardStreak
TestCallStreak_AC_PC_50_ConnectedCallCountsTowardStreak
TestCallStreak_AC_PC_51_FirstCallOfDay_IncrementsStreak
TestCallStreak_AC_PC_52_SecondCallSameDay_NoDoubleCount
TestCallStreak_AC_PC_53_BackdatedCall_RecalculatesStreak
TestCallStreak_AC_PC_53_BackdatedCall_FillsGap_ExtendsStreak
TestCallStreak_NoCalls_ZeroStreak
TestCallStreak_GapInDays_StreakResets
TestCallStreak_ConsecutiveDays_CorrectCount
TestCallStreak_TimezoneAware_UserLocalDate
TestCallStreak_DeleteCall_RecalculatesStreak
TestCallStreak_DeleteLastCallOfDay_BreaksStreak
```

### 1.5 Trends and Insights Calculation

```
TestTrends_AC_PC_60_WeeklySummary_CorrectTotals
TestTrends_AC_PC_60_WeeklySummary_PreviousWeekComparison
TestTrends_AC_PC_61_ConnectionRate_CalculatesCorrectly
TestTrends_AC_PC_61_ConnectionRate_NoOutgoingCalls_ReturnsZero
TestTrends_AC_PC_61_ConnectionRate_AllConnected_Returns100
TestTrends_AC_PC_62_ContactTypeDistribution_CorrectPercentages
TestTrends_AC_PC_62_ContactTypeDistribution_SingleType_Returns100Percent
TestTrends_AC_PC_63_IsolationWarning_ThresholdReached_ReturnsTrue
TestTrends_AC_PC_63_IsolationWarning_BelowThreshold_ReturnsFalse
TestTrends_AC_PC_64_IsolationWarning_CustomThreshold_Respected
TestTrends_DailyBreakdown_CorrectPerDayCounts
TestTrends_EmptyPeriod_ReturnsZeros
```

### 1.6 Feature Flag Gating

```
TestPhoneCall_AC_PC_110_FlagDisabled_Returns404
TestPhoneCall_AC_PC_111_FlagTierGating_UnauthorizedTier_Returns404
TestPhoneCall_AC_PC_110_FlagEnabled_AllowsAccess
```

---

## 2. Integration Tests (20-30%)

**Location:** `test/integration/phonecalls/`

### 2.1 Repository Tests (MongoDB)

```
TestPhoneCallRepository_Create_PersistsToMongoDB
TestPhoneCallRepository_Create_WritesCalendarActivityDualWrite
TestPhoneCallRepository_GetByDateRange_ReturnsCorrectEntries
TestPhoneCallRepository_GetByDateRange_ExcludesOutOfRange
TestPhoneCallRepository_GetRecent_ReturnsReverseChronological
TestPhoneCallRepository_Update_ModifiesFields_PreservesTimestamp
TestPhoneCallRepository_Delete_RemovesDocumentAndCalendarActivity
TestPhoneCallRepository_FilterByDirection_ReturnsCorrectSubset
TestPhoneCallRepository_FilterByContactType_ReturnsCorrectSubset
TestPhoneCallRepository_FilterByConnected_ReturnsCorrectSubset
TestPhoneCallRepository_SearchNotes_CaseInsensitive
TestPhoneCallRepository_CursorPagination_ReturnsCorrectPages
TestPhoneCallRepository_CursorPagination_LastPage_NoNextCursor
```

### 2.2 Saved Contact Repository Tests

```
TestSavedContactRepository_Create_PersistsToMongoDB
TestSavedContactRepository_List_ReturnsAllForUser
TestSavedContactRepository_Update_ModifiesFields
TestSavedContactRepository_Delete_RemovesDocument
TestSavedContactRepository_Delete_DoesNotAffectPhoneCallLogs
TestSavedContactRepository_CountForUser_ReturnsCorrectCount
```

### 2.3 Streak Cache Tests (Valkey)

```
TestStreakCache_GetStreak_ReturnsCachedValue
TestStreakCache_GetStreak_CacheMiss_CalculatesFromDB
TestStreakCache_InvalidateOnCreate_RefreshesCache
TestStreakCache_InvalidateOnDelete_RefreshesCache
TestStreakCache_TTL_ExpiresAfter5Minutes
```

### 2.4 Event Processing Tests

```
TestPhoneCallEvent_NewCall_PublishesToSNS
TestPhoneCallEvent_IsolationWarning_CreatesNotification
TestPhoneCallEvent_StreakMilestone_CreatesNotification
TestPhoneCallEvent_CommitmentFulfillment_UpdatesCommitment
```

---

## 3. Contract Tests

**Location:** `test/contract/phonecalls/`

### 3.1 OpenAPI Spec Conformance

```
TestContract_CreatePhoneCall_RequestMatchesSpec
TestContract_CreatePhoneCall_ResponseMatchesSpec
TestContract_CreatePhoneCall_201_HasLocationHeader
TestContract_ListPhoneCalls_ResponseMatchesSpec
TestContract_ListPhoneCalls_PaginationLinksMatchSpec
TestContract_GetPhoneCall_ResponseMatchesSpec
TestContract_UpdatePhoneCall_AcceptsMergePatch
TestContract_DeletePhoneCall_Returns204
TestContract_CreateSavedContact_RequestMatchesSpec
TestContract_CreateSavedContact_ResponseMatchesSpec
TestContract_ListSavedContacts_ResponseMatchesSpec
TestContract_GetStreak_ResponseMatchesSpec
TestContract_GetTrends_ResponseMatchesSpec
TestContract_GetDailyTrends_ResponseMatchesSpec
TestContract_ErrorResponse_MatchesSiemensFormat
TestContract_ErrorResponse_HasCorrelationId
```

---

## 4. E2E Tests (5-10%)

**Location:** `test/e2e/phonecalls/`

### 4.1 Full Call Logging Flow

```
TestE2E_PhoneCall_CreateReadUpdateDelete_FullLifecycle
TestE2E_PhoneCall_QuickLog_ThenExpand_FullFlow
TestE2E_PhoneCall_BackdatedCall_StreakRecalculated
TestE2E_PhoneCall_MultipleCallsSameDay_StreakCountsOnce
```

### 4.2 Saved Contacts Flow

```
TestE2E_SavedContact_CreateAndUseInCallLog
TestE2E_SavedContact_MaxTenEnforced
TestE2E_SavedContact_DeletePreservesCallHistory
```

### 4.3 Trends and Analytics Flow

```
TestE2E_Trends_30DaySummary_ReturnsAccurateData
TestE2E_Trends_ConnectionRate_MatchesActualData
TestE2E_Trends_IsolationWarning_TriggersAfterThreshold
```

### 4.4 Support Network Visibility

```
TestE2E_SupportNetwork_AC_PC_80_SponsorWithPermission_SeesCallLogs
TestE2E_SupportNetwork_AC_PC_81_SponsorWithoutPermission_Gets404
```

### 4.5 Cross-Feature Integration

```
TestE2E_Integration_AC_PC_90_CallLogFeedsTrackingSystem
TestE2E_Integration_AC_PC_91_CallLogFulfillsCommitment
TestE2E_Integration_AC_PC_92_CrossReferencePromptReturned
TestE2E_Integration_AC_PC_93_OfflineCallSync_UnionMerge
```

---

## 5. Mobile Tests

### 5.1 Android (Kotlin)

**Location:** `androidApp/app/src/test/java/com/regalrecovery/phonecalls/`

```kotlin
class PhoneCallViewModelTest {
    fun `quick log defaults direction to made`()
    fun `quick log defaults connected to true`()
    fun `duration quick-select values map to correct integers`()
    fun `contact name saved for future quick-select`()
    fun `offline call queued for sync`()
    fun `streak display formats correctly for singular day`()
    fun `streak display formats correctly for plural days`()
    fun `isolation warning shows after threshold days`()
    fun `post-log encouraging message rotates`()
}

class PhoneCallOfflineSyncTest {
    fun `enqueue call when offline preserves data`()
    fun `sync when online uploads in chronological order`()
    fun `conflict resolution uses union merge`()
}
```

### 5.2 iOS (Swift)

**Location:** `iosApp/RegalRecoveryTests/PhoneCalls/`

```swift
class PhoneCallViewModelTests: XCTestCase {
    func testQuickLog_defaultsDirectionToMade()
    func testQuickLog_defaultsConnectedToTrue()
    func testDurationQuickSelect_mapsToCorrectIntegers()
    func testContactName_savedForFutureQuickSelect()
    func testOfflineCall_queuedForSync()
    func testStreakDisplay_singularDay_omitsPlural()
    func testStreakDisplay_pluralDays_includesPlural()
    func testIsolationWarning_showsAfterThresholdDays()
    func testPostLogMessage_rotatesEncouragingText()
}

class PhoneCallOfflineSyncTests: XCTestCase {
    func testEnqueueCallWhenOffline_preservesData()
    func testSyncWhenOnline_uploadsInChronologicalOrder()
    func testConflictResolution_usesUnionMerge()
}
```

---

## 6. Test Data Fixtures

### Persona Extensions

```go
// pkg/fixtures/phone_call_fixtures.go

var AlexPhoneCallScenario = PhoneCallTestData{
    Persona: fixtures.Alex,
    Calls: []PhoneCallFixture{
        {Direction: "made", ContactType: "sponsor", Connected: true, DurationMinutes: 15},
        {Direction: "made", ContactType: "accountability-partner", Connected: true, DurationMinutes: 10},
        {Direction: "received", ContactType: "counselor", Connected: true, DurationMinutes: 30},
    },
    SavedContacts: []SavedContactFixture{
        {ContactName: "Mike S.", ContactType: "sponsor", PhoneNumber: "+15551234567"},
        {ContactName: "James R.", ContactType: "accountability-partner", PhoneNumber: "+15559876543"},
    },
    ExpectedStreakDays: 12,
}

var MarcusIsolationScenario = PhoneCallTestData{
    Persona: fixtures.Marcus,
    Calls: []PhoneCallFixture{}, // No calls in 5 days
    SavedContacts: []SavedContactFixture{},
    ExpectedStreakDays: 0,
    ExpectedIsolationWarning: true,
}

var DiegoHighVolumeScenario = PhoneCallTestData{
    Persona: fixtures.Diego,
    Calls: generateDailyCallsForDays(90), // 1-3 calls per day for 90 days
    SavedContacts: []SavedContactFixture{
        {ContactName: "Carlos M.", ContactType: "sponsor", PhoneNumber: "+525551234567"},
    },
    ExpectedStreakDays: 90,
}
```

---

## 7. Coverage Requirements

| Scope | Target |
|-------|--------|
| Overall phone calls domain | 80% line coverage |
| Streak calculation logic | 100% line + branch coverage |
| Connection rate calculation | 100% line + branch coverage |
| Isolation warning logic | 100% line + branch coverage |
| Saved contact limit enforcement | 100% line + branch coverage |
| Timestamp immutability enforcement | 100% line + branch coverage |
| Permission checking (support network) | 100% line + branch coverage |
