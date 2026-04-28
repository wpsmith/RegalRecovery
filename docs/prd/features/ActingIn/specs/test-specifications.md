# Acting In Behaviors -- Test Specifications

**Feature:** Acting In Behaviors Activity
**Feature Flag:** `activity.acting-in-behaviors`
**Test Naming Convention:** `Test<Component>_<AC_ID>_<Scenario>`

---

## 1. Unit Tests (60-70% of test budget)

### 1.1 Behavior Configuration

**Location:** `internal/domain/actingin/behavior_config_test.go`

| Test Name | AC | Description |
|-----------|----|-------------|
| `TestBehaviorConfig_AC_AIB_001_DefaultBehaviorsAvailableOnFirstUse` | AC-AIB-001 | New user config contains all 15 defaults enabled |
| `TestBehaviorConfig_AC_AIB_002_DisableDefaultBehavior` | AC-AIB-002 | Toggling off a default sets `enabled=false`, preserves behavior in config |
| `TestBehaviorConfig_AC_AIB_003_ReEnableDefaultBehavior` | AC-AIB-003 | Re-enabling a previously disabled default restores it to check-in flow |
| `TestBehaviorConfig_AC_AIB_004_CreateCustomBehavior` | AC-AIB-004 | Adding custom behavior with valid name and description succeeds |
| `TestBehaviorConfig_AC_AIB_005_CustomBehaviorNameValidation_TooLong` | AC-AIB-005 | Name > 100 chars returns validation error |
| `TestBehaviorConfig_AC_AIB_005_CustomBehaviorNameValidation_Empty` | AC-AIB-005 | Empty name returns validation error |
| `TestBehaviorConfig_AC_AIB_006_EditCustomBehavior` | AC-AIB-006 | Editing name/description of existing custom behavior succeeds |
| `TestBehaviorConfig_AC_AIB_006_EditDefaultBehavior_Rejected` | AC-AIB-006 | Attempting to edit a default behavior returns error |
| `TestBehaviorConfig_AC_AIB_007_DeleteCustomBehavior` | AC-AIB-007 | Deleting custom behavior removes from config but preserves in history |
| `TestBehaviorConfig_AC_AIB_007_DeleteDefaultBehavior_Rejected` | AC-AIB-007 | Attempting to delete a default behavior returns error |
| `TestBehaviorConfig_GetEnabledBehaviors_ReturnsOnlyEnabled` | -- | Helper returns only enabled behaviors (defaults + custom) sorted by `sortOrder` |

### 1.2 Check-In Domain Logic

**Location:** `internal/domain/actingin/checkin_test.go`

| Test Name | AC | Description |
|-----------|----|-------------|
| `TestCheckIn_AC_AIB_012_DisplaysAllEnabledBehaviors` | AC-AIB-012 | Check-in behavior list matches enabled behaviors from config |
| `TestCheckIn_AC_AIB_013_MarkBehaviorsWithContext` | AC-AIB-013 | Checked behaviors accept optional context note, trigger, and relationship tag |
| `TestCheckIn_AC_AIB_014_ContextNoteCharLimit` | AC-AIB-014 | Context note > 500 chars is rejected |
| `TestCheckIn_AC_AIB_015_SubmitWithBehaviors` | AC-AIB-015 | Check-in with behaviors returns correct `behaviorCount` and compassionate message |
| `TestCheckIn_AC_AIB_016_SubmitZeroBehaviors` | AC-AIB-016 | Zero-behavior check-in is valid and returns celebration message |
| `TestCheckIn_AC_AIB_017_NoBehaviorLimit` | AC-AIB-017 | All 15+ behaviors can be checked without error |
| `TestCheckIn_AC_AIB_015_CompassionateMessage` | AC-AIB-015 | Message matches "Awareness is the first step toward change..." |
| `TestCheckIn_AC_AIB_016_ZeroBehaviorMessage` | AC-AIB-016 | Message matches "No acting-in behaviors today..." |
| `TestCheckIn_AC_AIB_071_RotatingPostCheckInMessages` | AC-AIB-071 | Post-check-in messages rotate among the 3 defined messages |
| `TestCheckIn_InvalidBehaviorId_Rejected` | -- | Submitting a behaviorId not in the user's enabled list returns error |
| `TestCheckIn_DisabledBehaviorId_Rejected` | -- | Submitting a disabled behaviorId returns error |
| `TestCheckIn_InvalidTrigger_Rejected` | -- | Trigger value outside enum returns validation error |
| `TestCheckIn_InvalidRelationshipTag_Rejected` | -- | Relationship tag outside enum returns validation error |
| `TestCheckIn_ImmutableTimestamp_FR2_7` | FR2.7 | Attempting to modify check-in timestamp after creation returns error |

### 1.3 Streak Calculation

**Location:** `internal/domain/actingin/streak_test.go`

| Test Name | AC | Description |
|-----------|----|-------------|
| `TestStreak_AC_AIB_091_ConsecutiveDailyCheckIns` | AC-AIB-091 | 7 consecutive daily check-ins returns streak of 7 |
| `TestStreak_AC_AIB_020_FrequencyChangeDailyToWeekly` | AC-AIB-020 | Changing to weekly recalculates streak based on weekly cadence |
| `TestStreak_AC_AIB_021_FrequencyChangeWeeklyToDaily` | AC-AIB-021 | Changing to daily starts daily tracking, weekly data preserved |
| `TestStreak_MissedDay_ResetsStreak` | -- | Missing a day resets daily streak to 0 |
| `TestStreak_MissedWeek_ResetsStreak` | -- | Missing a week resets weekly streak to 0 |
| `TestStreak_TimezoneHandling` | -- | Streak calculation respects user's time zone for day boundaries |

### 1.4 Insights Calculation

**Location:** `internal/domain/actingin/insights_test.go`

| Test Name | AC | Description |
|-----------|----|-------------|
| `TestInsights_AC_AIB_030_FrequencyDashboard_BarChart` | AC-AIB-030 | Correctly counts behavior occurrences sorted by frequency |
| `TestInsights_AC_AIB_031_TimeRangeViews` | AC-AIB-031 | 7d, 30d, 90d ranges return correct aggregated data |
| `TestInsights_AC_AIB_032_TrendArrows_Increasing` | AC-AIB-032 | Behavior with higher recent count shows "increasing" |
| `TestInsights_AC_AIB_032_TrendArrows_Decreasing` | AC-AIB-032 | Behavior with lower recent count shows "decreasing" |
| `TestInsights_AC_AIB_032_TrendArrows_Stable` | AC-AIB-032 | Behavior with similar counts shows "stable" |
| `TestInsights_AC_AIB_033_TriggerAnalysis` | AC-AIB-033 | Triggers ranked by frequency with correct counts |
| `TestInsights_AC_AIB_033_TriggerBehaviorCorrelation` | AC-AIB-033 | Trigger-to-behavior mapping returns correct top behaviors and narrative |
| `TestInsights_AC_AIB_034_RelationshipImpact` | AC-AIB-034 | Relationship tags ranked by frequency with trend lines |
| `TestInsights_AC_AIB_035_HeatmapCalculation` | AC-AIB-035 | Correct day-of-week and hour-of-day bucketing |
| `TestInsights_InsufficientData_ReturnsEmpty` | -- | Less than 7 days of data returns empty insights, not error |
| `TestInsights_TrendCalculation_EqualPeriodComparison` | -- | Trend compares current period vs prior equal-length period |

### 1.5 Cross-Tool Correlation

**Location:** `internal/domain/actingin/correlation_test.go`

| Test Name | AC | Description |
|-----------|----|-------------|
| `TestCorrelation_AC_AIB_036_PciElevatedWithActingIn` | AC-AIB-036 | Elevated PCI scores on same day as high acting-in count returns correlation |
| `TestCorrelation_AC_AIB_037_FasterStageCorrelation` | AC-AIB-037 | Acting-in spikes during Anxiety/Ticked stages are detected |
| `TestCorrelation_AC_AIB_038_PostMortemBuildUp` | AC-AIB-038 | Acting-in behaviors in build-up phase of past relapses are identified |
| `TestCorrelation_NoPci_ReturnsNoCorrelation` | -- | No PCI data returns `correlationFound: false` |
| `TestCorrelation_NoFaster_ReturnsNoCorrelation` | -- | No FASTER data returns `correlationFound: false` |

### 1.6 Settings

**Location:** `internal/domain/actingin/settings_test.go`

| Test Name | AC | Description |
|-----------|----|-------------|
| `TestSettings_AC_AIB_010_DailyFrequency` | AC-AIB-010 | Setting daily frequency with time saves correctly |
| `TestSettings_AC_AIB_011_WeeklyFrequency` | AC-AIB-011 | Setting weekly frequency with day saves correctly |
| `TestSettings_InvalidReminderTime_Rejected` | -- | Invalid time format returns validation error |
| `TestSettings_DefaultValues` | -- | New settings default to daily, 21:00, Sunday |

### 1.7 Permissions

**Location:** `internal/domain/actingin/permissions_test.go`

| Test Name | AC | Description |
|-----------|----|-------------|
| `TestPermissions_AC_AIB_060_SponsorNoAccessWithoutGrant` | AC-AIB-060 | Sponsor without permission sees 404, not 403 |
| `TestPermissions_AC_AIB_061_SpouseWithPermission` | AC-AIB-061 | Spouse with read access sees frequency trends (not individual notes) |
| `TestPermissions_AC_AIB_061_AuditTrailLogged` | AC-AIB-061 | Data access by support network member creates audit entry |

### 1.8 Feature Flag

**Location:** `internal/domain/actingin/flag_test.go`

| Test Name | AC | Description |
|-----------|----|-------------|
| `TestFlag_AC_AIB_080_DisabledFlagReturns404` | AC-AIB-080 | Feature flag disabled returns 404 on all endpoints |
| `TestFlag_AC_AIB_081_TierAndRolloutRespected` | AC-AIB-081 | Flag with tier restriction and rollout % correctly gates access |

### 1.9 Export

**Location:** `internal/domain/actingin/export_test.go`

| Test Name | AC | Description |
|-----------|----|-------------|
| `TestExport_AC_AIB_043_CsvFormat` | AC-AIB-043 | CSV export contains correct headers and all check-in data |
| `TestExport_AC_AIB_044_PdfFormat` | AC-AIB-044 | PDF export is generated as valid PDF binary |
| `TestExport_DateRangeFilter` | -- | Export respects startDate and endDate parameters |
| `TestExport_EmptyRange_ReturnsEmptyFile` | -- | Export with no data in range returns empty file, not error |

---

## 2. Integration Tests (20-30% of test budget)

**Location:** `test/integration/actingin/`
**Dependencies:** MongoDB (local Docker), Valkey (local Docker)

### 2.1 Repository Tests

| Test Name | AC | Description |
|-----------|----|-------------|
| `TestActingInRepo_SaveAndRetrieveConfig` | AC-AIB-001 | Config document round-trips through MongoDB correctly |
| `TestActingInRepo_SaveAndRetrieveCheckIn` | AC-AIB-015 | Check-in document with behaviors saved and queried by date |
| `TestActingInRepo_QueryByDateRange` | AC-AIB-040 | Date range query returns correct check-ins in descending order |
| `TestActingInRepo_FilterByBehavior` | AC-AIB-042 | Filter by behaviorId returns only matching check-ins |
| `TestActingInRepo_FilterByTrigger` | AC-AIB-042 | Filter by trigger returns only matching check-ins |
| `TestActingInRepo_FilterByRelationshipTag` | AC-AIB-042 | Filter by relationship tag returns only matching check-ins |
| `TestActingInRepo_CalendarDualWrite` | AC-AIB-090 | Check-in creates corresponding calendar activity |
| `TestActingInRepo_StreakUpdate` | AC-AIB-091 | Streak increments on consecutive check-in |
| `TestActingInRepo_InsightsCacheReadWrite` | AC-AIB-030 | Insights cache document saved and retrieved with TTL |

### 2.2 Cache Tests

| Test Name | AC | Description |
|-----------|----|-------------|
| `TestActingInCache_InsightsCacheAside` | -- | Cache miss triggers computation and caches result in Valkey |
| `TestActingInCache_CacheInvalidationOnCheckIn` | -- | New check-in invalidates insights cache |
| `TestActingInCache_BehaviorConfigCached` | -- | Behavior config cached in Valkey with 5-min TTL |

### 2.3 Notification Tests

| Test Name | AC | Description |
|-----------|----|-------------|
| `TestActingInNotification_AC_AIB_072_ReEngagementPrompt` | AC-AIB-072 | Missed check-ins trigger gentle re-engagement notification |
| `TestActingInNotification_DailyReminder` | AC-AIB-010 | Daily reminder scheduled at user's configured time |
| `TestActingInNotification_WeeklyReminder` | AC-AIB-011 | Weekly reminder scheduled on user's configured day |

---

## 3. End-to-End API Tests (5-10% of test budget)

**Location:** `test/e2e/actingin/`
**Dependencies:** Deployed staging environment

### 3.1 Full Flow Tests

| Test Name | AC | Description |
|-----------|----|-------------|
| `TestActingIn_E2E_CompleteCheckInFlow` | AC-AIB-012,013,015 | Auth, configure behaviors, submit check-in with context, verify response |
| `TestActingIn_E2E_ZeroBehaviorCheckIn` | AC-AIB-016 | Submit empty check-in, verify celebration message |
| `TestActingIn_E2E_CustomBehaviorLifecycle` | AC-AIB-004,006,007 | Create, edit, delete custom behavior, verify historical preservation |
| `TestActingIn_E2E_ToggleDefaultBehavior` | AC-AIB-002,003 | Disable, verify hidden, re-enable, verify restored |
| `TestActingIn_E2E_HistoryBrowseAndFilter` | AC-AIB-040,041,042 | Submit multiple check-ins, browse history, filter by behavior/trigger |
| `TestActingIn_E2E_InsightsDashboard` | AC-AIB-030,031,032 | Submit 7+ days of data, verify frequency dashboard and trend arrows |
| `TestActingIn_E2E_ExportCsv` | AC-AIB-043 | Export as CSV, verify file content |
| `TestActingIn_E2E_ExportPdf` | AC-AIB-044 | Export as PDF, verify content type and non-empty body |
| `TestActingIn_E2E_SettingsUpdate` | AC-AIB-010,011 | Change frequency and reminder time, verify persistence |
| `TestActingIn_E2E_FeatureFlagDisabled` | AC-AIB-080 | With flag off, all endpoints return 404 |
| `TestActingIn_E2E_SponsorAccessDenied` | AC-AIB-060 | Sponsor without permission gets 404 |
| `TestActingIn_E2E_SpouseAccessGranted` | AC-AIB-061 | Spouse with permission sees trend data |
| `TestActingIn_E2E_CalendarIntegration` | AC-AIB-090 | Check-in appears in calendar view for the day |

### 3.2 Offline Sync Tests (Mobile)

| Test Name | AC | Description |
|-----------|----|-------------|
| `TestActingIn_E2E_OfflineCheckIn` | AC-AIB-050 | Check-in saved locally offline, synced on reconnect |
| `TestActingIn_E2E_OfflineMultipleCheckIns` | AC-AIB-051 | Multiple offline check-ins sync in chronological order |

---

## 4. Contract Tests

**Location:** `test/contract/actingin_test.go`
**Purpose:** Validate implementations against `specs/acting-in-behaviors/openapi.yaml`

| Test Name | Description |
|-----------|-------------|
| `TestContract_CreateCheckIn_RequestSchema` | Request body matches OpenAPI `CreateCheckInRequest` schema |
| `TestContract_CreateCheckIn_ResponseSchema` | Response body matches OpenAPI `CheckIn` schema |
| `TestContract_ListCheckIns_ResponseSchema` | Response matches paginated list with `PaginationLinks` and `PageMetadata` |
| `TestContract_ListBehaviors_ResponseSchema` | Response matches `Behavior[]` schema |
| `TestContract_CreateCustomBehavior_RequestSchema` | Request matches `CreateCustomBehaviorRequest` schema |
| `TestContract_FrequencyInsights_ResponseSchema` | Response matches frequency insights schema |
| `TestContract_ExportCsv_ContentType` | CSV export returns `text/csv` content type |
| `TestContract_ExportPdf_ContentType` | PDF export returns `application/pdf` content type |
| `TestContract_ErrorResponse_Schema` | All error responses match `ErrorResponse` schema with `rr:0x` codes |
| `TestContract_PaginationLinks_Structure` | Pagination links match `PaginationLinks` schema with cursor fields |

---

## 5. Mobile Tests

### 5.1 Android (Kotlin)

**Location:** `androidApp/app/src/test/java/com/regalrecovery/actingin/`

| Test Name | AC | Description |
|-----------|----|-------------|
| `BehaviorChecklist_displaysAllEnabledBehaviors` | AC-AIB-012 | Compose UI shows correct behavior count |
| `CheckInFlow_zeroBehaviors_showsCelebration` | AC-AIB-016 | Zero-behavior UI shows celebration message |
| `ContextNote_truncatesAt500Characters` | AC-AIB-014 | Input field enforces 500-char limit |
| `OfflineQueue_preservesCheckInOrder` | AC-AIB-051 | Offline queue maintains chronological order |
| `InsightsDashboard_showsBarChart` | AC-AIB-030 | Frequency bar chart renders with correct data |
| `TrendArrow_showsCorrectDirection` | AC-AIB-032 | Arrow direction matches trend enum |

### 5.2 iOS (Swift)

**Location:** `iosApp/RegalRecoveryTests/ActingIn/`

| Test Name | AC | Description |
|-----------|----|-------------|
| `testBehaviorChecklist_displaysAllEnabled` | AC-AIB-012 | SwiftUI list shows correct behavior count |
| `testCheckIn_zeroBehaviors_showsCelebration` | AC-AIB-016 | Zero-behavior confirmation shows growth message |
| `testContextNote_enforcesCharLimit` | AC-AIB-014 | Text field enforces 500-char max |
| `testOfflineSync_preservesOrder` | AC-AIB-051 | Offline entries sync in chronological order |
| `testFrequencyDashboard_rendersCorrectly` | AC-AIB-030 | Chart view renders with behavior frequency data |

---

## 6. Persona-Based Test Fixtures

### Alex (270 days sober, has sponsor + spouse)

- 90 days of daily acting-in check-ins
- Most frequent behaviors: Stonewall (35x), Avoid (28x), Hide (15x)
- Top triggers: Stress (40%), Conflict (30%)
- Top affected relationship: Spouse (55%)
- Trend: Stonewall decreasing, Avoid stable
- Spouse has read permission for acting-in data

### Marcus (73 days sober, no sponsor)

- 30 days of daily acting-in check-ins
- Most frequent behaviors: Passivity (20x), Humor (18x), Excuse (12x)
- Top triggers: Loneliness (45%), Shame (25%)
- Top affected relationship: Self (60%)
- Trend: All stable (new to tracking)

### Diego (147 days sober, has sponsor + spouse)

- 60 days of weekly acting-in check-ins
- Most frequent behaviors: HyperSpiritualize (8x), Placating (6x)
- Top triggers: Fear (40%), Shame (30%)
- Top affected relationship: Spouse (50%)
- Trend: HyperSpiritualize decreasing
- Sponsor has read permission, spouse has read permission
