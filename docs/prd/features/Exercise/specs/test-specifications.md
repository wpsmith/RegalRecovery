# Exercise / Physical Activity -- Test Specifications

**Source:** `docs/prd/specific-features/Exercise/specs/acceptance-criteria.md`
**Feature Flag:** `activity.exercise`

---

## 1. Unit Tests (70% of test budget)

### 1.1 Exercise Log Domain Logic

**Location:** `internal/domain/exercise/exercise_test.go`

```
TestExerciseLog_FR_EX_1_1_ActivityTypeValidation_AcceptsPredefinedTypes
TestExerciseLog_FR_EX_1_1_ActivityTypeOther_RequiresCustomLabel
TestExerciseLog_FR_EX_1_1_ActivityTypeOther_MissingLabel_ReturnsError
TestExerciseLog_FR_EX_1_2_DurationMinimum_RejectsZero
TestExerciseLog_FR_EX_1_2_DurationMinimum_AcceptsOne
TestExerciseLog_FR_EX_1_2_DurationMaximum_Rejects1441
TestExerciseLog_FR_EX_1_3_IntensityValidation_AcceptsLightModerateVigorous
TestExerciseLog_FR_EX_1_3_IntensityOptional_NilIsValid
TestExerciseLog_FR_EX_1_4_TimestampDefault_UsesCurrentTime
TestExerciseLog_FR_EX_1_4_TimestampBackdated_AllowsPastDate
TestExerciseLog_FR_EX_1_4_TimestampFuture_RejectsBeyond24Hours
TestExerciseLog_FR_EX_1_5_NotesMaxLength_Rejects501Chars
TestExerciseLog_FR_EX_1_5_NotesOptional_NilIsValid
TestExerciseLog_FR_EX_1_6_MoodBeforeAfter_AcceptsRange1To5
TestExerciseLog_FR_EX_1_6_MoodBeforeAfter_RejectsOutOfRange
TestExerciseLog_FR_EX_1_6_MoodOptional_NilIsValid
TestExerciseLog_FR_EX_1_7_ImmutableTimestamp_RejectsModification
TestExerciseLog_FR_EX_1_7_ImmutableCreatedAt_RejectsModification
TestExerciseLog_FR_EX_1_7_ImmutableActivityType_RejectsModification
TestExerciseLog_FR_EX_1_7_ImmutableDuration_RejectsModification
TestExerciseLog_FR_EX_1_7_ImmutableSource_RejectsModification
TestExerciseLog_FR_EX_1_7_MutableIntensity_AcceptsUpdate
TestExerciseLog_FR_EX_1_7_MutableNotes_AcceptsUpdate
TestExerciseLog_FR_EX_1_7_MutableMood_AcceptsUpdate
```

### 1.2 Exercise Favorites

**Location:** `internal/domain/exercise/favorites_test.go`

```
TestFavorites_FR_EX_2_1_CreateFavorite_Success
TestFavorites_FR_EX_2_1_MaxFiveFavorites_RejectsExceedingLimit
TestFavorites_FR_EX_2_1_QuickLogFromFavorite_AppliesDefaults
TestFavorites_FR_EX_2_2_UpdateFavorite_Success
TestFavorites_FR_EX_2_2_DeleteFavorite_Success
TestFavorites_FR_EX_2_3_CustomTypePromotion_PromptAfterThreeUses
TestFavorites_FR_EX_2_3_CustomTypePromotion_NoPromptBeforeThreeUses
```

### 1.3 Exercise Streak Calculation

**Location:** `internal/domain/exercise/streak_test.go`

```
TestExerciseStreak_FR_EX_4_3_ConsecutiveDays_CalculatesCorrectly
TestExerciseStreak_FR_EX_4_3_GapInDays_ResetsStreak
TestExerciseStreak_FR_EX_4_3_MultipleWorkoutsPerDay_CountsAsOneDay
TestExerciseStreak_FR_EX_4_3_NoExerciseToday_ExcludesToday
TestExerciseStreak_FR_EX_4_3_LongestStreak_PreservedAcrossGaps
TestExerciseStreak_FR_EX_4_3_BackdatedEntry_ExtendsStreakForOriginalDate
TestExerciseStreak_FR_EX_4_3_EmptyHistory_ReturnsZero
TestExerciseStreak_FR_EX_4_3_SingleDay_ReturnsOne
TestExerciseStreak_FR_EX_4_3_TimezoneHandling_UsesUserTimezone
TestExerciseStreak_FR_EX_4_3_NextMilestone_CalculatesCorrectly
TestExerciseStreak_FR_EX_4_3_NextMilestone_AtMilestone_ReturnsNext
```

### 1.4 Exercise Stats Calculation

**Location:** `internal/domain/exercise/stats_test.go`

```
TestExerciseStats_FR_EX_4_1_WeeklySummary_TotalActiveMinutes
TestExerciseStats_FR_EX_4_1_WeeklySummary_SessionCount
TestExerciseStats_FR_EX_4_1_WeeklySummary_MostCommonActivityType
TestExerciseStats_FR_EX_4_1_WeeklySummary_ComparisonToPreviousWeek
TestExerciseStats_FR_EX_4_1_WeeklySummary_EmptyWeek_ReturnsZeros
TestExerciseStats_FR_EX_4_2_ActivityTypeDistribution_CorrectCounts
TestExerciseStats_FR_EX_4_2_IntensityDistribution_CorrectCounts
TestExerciseStats_FR_EX_4_2_MonthlyView_AggregatesCorrectly
TestExerciseStats_FR_EX_4_2_NinetyDayView_AggregatesCorrectly
```

### 1.5 Correlation Insights

**Location:** `internal/domain/exercise/correlations_test.go`

```
TestCorrelations_FR_EX_4_4_InsufficientData_ReturnsSufficientDataFalse
TestCorrelations_FR_EX_4_4_UrgeFrequency_CalculatesPercentDelta
TestCorrelations_FR_EX_4_4_CheckInScore_CalculatesPointsDelta
TestCorrelations_FR_EX_4_4_MoodImprovement_CalculatesAverage
TestCorrelations_FR_EX_4_4_InactivityRisk_CalculatesDaysSinceExercise
TestCorrelations_FR_EX_4_4_NoUrgeData_SkipsUrgeInsight
TestCorrelations_FR_EX_4_4_NoCheckInData_SkipsCheckInInsight
TestCorrelations_FR_EX_4_4_NoMoodData_SkipsMoodInsight
```

### 1.6 Weekly Goal

**Location:** `internal/domain/exercise/goals_test.go`

```
TestGoal_FR_EX_6_1_SetGoal_ValidMinutesAndSessions
TestGoal_FR_EX_6_1_SetGoal_OnlyMinutes_Valid
TestGoal_FR_EX_6_1_SetGoal_OnlySessions_Valid
TestGoal_FR_EX_6_1_SetGoal_NeitherMinutesNorSessions_RejectsEmpty
TestGoal_FR_EX_6_2_ProgressCalculation_ActiveMinutesPercent
TestGoal_FR_EX_6_2_ProgressCalculation_SessionsPercent
TestGoal_FR_EX_6_2_ProgressCalculation_UsesHigherPercent
TestGoal_FR_EX_6_3_GoalMet_DetectsThresholdCrossing
TestGoal_FR_EX_6_3_GoalNotMet_DoesNotTrigger
TestGoal_FR_EX_6_3_GoalExceeded_ReportsOver100Percent
TestGoal_FR_EX_6_4_DynamicGoalIntegration_AutoChecksPhysicalGoal
```

### 1.7 Duplicate Detection

**Location:** `internal/domain/exercise/duplicate_test.go`

```
TestDuplicate_FR_EX_8_3_SameTypeWithin30Min_DetectedAsDuplicate
TestDuplicate_FR_EX_8_3_SameTypeOutside30Min_NotDuplicate
TestDuplicate_FR_EX_8_3_DifferentType_NotDuplicate
TestDuplicate_FR_EX_8_3_ExternalIdMatch_DetectedAsDuplicate
TestDuplicate_FR_EX_8_3_NullExternalId_FallsBackToTimeWindow
```

### 1.8 Feature Flag Gating

**Location:** `internal/domain/exercise/flag_test.go`

```
TestFeatureFlag_NFR_EX_4_FlagDisabled_Returns404
TestFeatureFlag_NFR_EX_4_FlagEnabled_AllowsAccess
TestFeatureFlag_NFR_EX_4_FlagRollout50Percent_ConsistentPerUser
```

### 1.9 Dashboard Widget

**Location:** `internal/domain/exercise/widget_test.go`

```
TestWidget_FR_EX_5_1_ExercisedToday_ReturnsTrue
TestWidget_FR_EX_5_1_NotExercisedToday_ReturnsFalse
TestWidget_FR_EX_5_1_StreakIncluded_MatchesStreakCalculation
TestWidget_FR_EX_5_1_WeeklyGoalIncluded_WhenGoalSet
TestWidget_FR_EX_5_1_WeeklyGoalNull_WhenNoGoalSet
```

### 1.10 Edge Cases

**Location:** `internal/domain/exercise/edge_cases_test.go`

```
TestEdge_EC_EX_1_MultipleWorkoutsPerDay_AllCountIndependently
TestEdge_EC_EX_1_MultipleWorkoutsPerDay_TotalMinutesSumsAll
TestEdge_EC_EX_3_BackdatedExercise_StreakCreditOnOriginalDate
TestEdge_EC_EX_4_WeeklyGoalNotMet_NoPenalty
TestEdge_EC_EX_5_CustomTypeThreeOccurrences_PromptToSaveFavorite
TestEdge_EC_EX_5_CustomTypeTwoOccurrences_NoPrompt
TestEdge_NFR_EX_5_BackdatedYesterday_StreakIncludes
```

---

## 2. Integration Tests (20% of test budget)

### 2.1 Repository Layer

**Location:** `test/integration/exercise/repository_test.go`
**Dependencies:** MongoDB (local Docker)

```
TestExerciseRepository_CreateAndRetrieve_RoundTrips
TestExerciseRepository_ListByDateRange_ReturnsCorrectEntries
TestExerciseRepository_FilterByActivityType_ReturnsFiltered
TestExerciseRepository_FilterByIntensity_ReturnsFiltered
TestExerciseRepository_SearchNotes_FindsKeyword
TestExerciseRepository_CursorPagination_ReturnsCorrectPages
TestExerciseRepository_Delete_RemovesEntryAndCalendarActivity
TestExerciseRepository_Update_ModifiesMutableFieldsOnly
TestExerciseRepository_DualWrite_CreatesCalendarActivity
TestExerciseRepository_DualWrite_DeleteRemovesCalendarActivity

TestFavoriteRepository_CreateAndList_MaxFive
TestFavoriteRepository_Delete_RemovesFavorite
TestFavoriteRepository_Count_ReturnsAccurateCount

TestGoalRepository_Upsert_CreatesOrReplaces
TestGoalRepository_Delete_RemovesGoal
TestGoalRepository_Get_ReturnsGoalOrNil

TestExerciseRepository_DuplicateDetection_FindsByExternalId
TestExerciseRepository_DuplicateDetection_FindsByTimeWindow
```

### 2.2 Valkey Cache Layer

**Location:** `test/integration/exercise/cache_test.go`
**Dependencies:** Valkey (local Docker)

```
TestExerciseCache_StreakCache_SetAndGet
TestExerciseCache_StreakCache_InvalidatedOnCreate
TestExerciseCache_StreakCache_InvalidatedOnDelete
TestExerciseCache_WidgetCache_SetAndGet
TestExerciseCache_WidgetCache_InvalidatedOnCreate
TestExerciseCache_StatsCache_SetAndGet
TestExerciseCache_StatsCache_Expiry
```

### 2.3 Handler Integration

**Location:** `test/integration/exercise/handler_test.go`
**Dependencies:** MongoDB + Valkey (local Docker)

```
TestExerciseHandler_CreateLog_201WithStreakUpdate
TestExerciseHandler_ListLogs_200WithPagination
TestExerciseHandler_GetLog_200
TestExerciseHandler_GetLog_404WhenNotFound
TestExerciseHandler_UpdateLog_200MutableFieldsOnly
TestExerciseHandler_UpdateLog_422WhenImmutableFieldChanged
TestExerciseHandler_DeleteLog_204
TestExerciseHandler_DeleteLog_404WhenNotFound

TestExerciseHandler_CreateFavorite_201
TestExerciseHandler_CreateFavorite_422WhenMaxReached
TestExerciseHandler_ListFavorites_200
TestExerciseHandler_DeleteFavorite_204

TestExerciseHandler_GetStats_200WeekPeriod
TestExerciseHandler_GetStats_200MonthPeriod
TestExerciseHandler_GetStreak_200
TestExerciseHandler_GetCorrelations_200
TestExerciseHandler_GetCorrelations_InsufficientData

TestExerciseHandler_SetGoal_200
TestExerciseHandler_GetGoal_200
TestExerciseHandler_GetGoal_404WhenNotSet
TestExerciseHandler_DeleteGoal_204

TestExerciseHandler_GetWidget_200
TestExerciseHandler_GetWidget_WithGoal
TestExerciseHandler_GetWidget_WithoutGoal
```

---

## 3. Contract Tests

### 3.1 OpenAPI Contract Validation

**Location:** `test/contract/exercise_test.go`

```
TestContract_Exercise_CreateLog_MatchesOpenAPISchema
TestContract_Exercise_ListLogs_MatchesOpenAPISchema
TestContract_Exercise_GetLog_MatchesOpenAPISchema
TestContract_Exercise_UpdateLog_MatchesOpenAPISchema
TestContract_Exercise_DeleteLog_MatchesOpenAPISchema
TestContract_Exercise_ListFavorites_MatchesOpenAPISchema
TestContract_Exercise_CreateFavorite_MatchesOpenAPISchema
TestContract_Exercise_UpdateFavorite_MatchesOpenAPISchema
TestContract_Exercise_DeleteFavorite_MatchesOpenAPISchema
TestContract_Exercise_GetStats_MatchesOpenAPISchema
TestContract_Exercise_GetStreak_MatchesOpenAPISchema
TestContract_Exercise_GetCorrelations_MatchesOpenAPISchema
TestContract_Exercise_GetGoal_MatchesOpenAPISchema
TestContract_Exercise_SetGoal_MatchesOpenAPISchema
TestContract_Exercise_DeleteGoal_MatchesOpenAPISchema
TestContract_Exercise_GetWidget_MatchesOpenAPISchema

TestContract_Exercise_ErrorResponses_MatchSiemensFormat
TestContract_Exercise_PaginationLinks_MatchCursorFormat
TestContract_Exercise_CamelCaseProperties_Enforced
```

---

## 4. End-to-End Tests (10% of test budget)

### 4.1 Exercise Logging Flow

**Location:** `test/e2e/exercise/exercise_logging_test.go`
**Dependencies:** Deployed staging environment

```
TestE2E_Exercise_FullLoggingFlow_CreateReadUpdateDelete
TestE2E_Exercise_QuickLog_CreateFromFavorite
TestE2E_Exercise_BackdatedEntry_StreakCreditOnOriginalDate
TestE2E_Exercise_MultiplePerDay_AllCountIndependently
```

### 4.2 Stats and Streak Flow

**Location:** `test/e2e/exercise/exercise_stats_test.go`

```
TestE2E_Exercise_WeeklyStats_AccurateAfterMultipleLogs
TestE2E_Exercise_Streak_IncrementsOnConsecutiveDays
TestE2E_Exercise_Streak_ResetsAfterGap
TestE2E_Exercise_Correlations_ReturnsInsightsWith14DaysData
```

### 4.3 Weekly Goal Flow

**Location:** `test/e2e/exercise/exercise_goals_test.go`

```
TestE2E_Exercise_SetGoal_ProgressUpdatesOnLog
TestE2E_Exercise_GoalMet_NotificationSent
TestE2E_Exercise_DeleteGoal_WidgetNoLongerShowsGoal
```

### 4.4 Dashboard Widget Flow

**Location:** `test/e2e/exercise/exercise_widget_test.go`

```
TestE2E_Exercise_Widget_ReflectsCurrentState
TestE2E_Exercise_Widget_UpdatesAfterNewLog
```

### 4.5 Persona Scenarios

**Location:** `test/e2e/exercise/persona_test.go`

```
TestE2E_Exercise_Alex_LogsRunAndYoga_StatsReflectBoth
TestE2E_Exercise_Marcus_FirstExerciseLog_StreakStartsAtOne
TestE2E_Exercise_Diego_BackdatesYesterdayWorkout_StreakPreserved
```

---

## 5. Mobile Tests

### 5.1 Android (Kotlin)

**Location:** `androidApp/app/src/test/java/com/regalrecovery/exercise/`

```kotlin
class ExerciseViewModelTest {
    fun `quick log from favorite creates log with defaults`()
    fun `exercise streak displays correct day count`()
    fun `offline exercise log queued for sync`()
    fun `duplicate detection prompts user on sync conflict`()
    fun `weekly goal progress bar updates on log`()
}

class ExerciseOfflineSyncTest {
    fun `enqueue exercise when offline preserves data`()
    fun `replay syncs exercise logs in chronological order`()
    fun `conflict resolution uses union merge for exercise logs`()
}
```

### 5.2 iOS (Swift)

**Location:** `iosApp/RegalRecoveryTests/Exercise/`

```swift
class ExerciseViewModelTests: XCTestCase {
    func testQuickLogFromFavorite_CreatesLogWithDefaults()
    func testExerciseStreak_DisplaysCorrectDayCount()
    func testOfflineExerciseLog_QueuedForSync()
    func testDuplicateDetection_PromptsUserOnSyncConflict()
    func testWeeklyGoalProgress_UpdatesOnLog()
}

class ExerciseAppleHealthSyncTests: XCTestCase {
    func testAppleHealthSync_ImportsWorkoutData()
    func testAppleHealthSync_DuplicateDetection()
    func testAppleHealthSync_DisablePreservesHistory()
}
```

---

## 6. Test Data Fixtures

### 6.1 Exercise Log Factory

```go
type ExerciseLogFactory struct{}

func (f *ExerciseLogFactory) Build(overrides ...func(*ExerciseLog)) ExerciseLog {
    log := ExerciseLog{
        ExerciseID:      "ex_" + uuid.NewString()[:5],
        UserID:          "user_12345",
        Timestamp:       time.Now().UTC(),
        ActivityType:    "running",
        DurationMinutes: 30,
        Intensity:       "moderate",
        Source:          "manual",
    }
    for _, override := range overrides {
        override(&log)
    }
    return log
}
```

### 6.2 Persona Exercise Seeds

```go
func SeedAlexExerciseScenario(t *testing.T, db *mongo.Client) {
    // Alex: 270-day sobriety streak, regular exerciser
    // 5 exercise logs this week (running x3, yoga x2)
    // Weekly goal: 150 min, 4 sessions
    // Current streak: 12 days
}

func SeedMarcusExerciseScenario(t *testing.T, db *mongo.Client) {
    // Marcus: 73-day streak, no exercise history yet
    // First-time exercise user scenario
}

func SeedDiegoExerciseScenario(t *testing.T, db *mongo.Client) {
    // Diego: 147-day streak, afternoon exerciser
    // Backdated exercise entries
    // Apple Health sync enabled
}
```

---

## 7. Coverage Requirements

| Scope | Target |
|-------|--------|
| `internal/domain/exercise/` overall | 90% line coverage |
| Exercise streak calculation | 100% line + branch coverage |
| Immutable field enforcement | 100% line + branch coverage |
| Duplicate detection logic | 100% line + branch coverage |
| Goal progress calculation | 100% line + branch coverage |
| Handler layer | 75% line coverage |
| Repository layer (integration) | 80% line coverage |
