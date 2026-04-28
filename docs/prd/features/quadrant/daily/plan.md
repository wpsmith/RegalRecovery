# Daily Quadrant Check-In -- TDD Implementation Plan

| Field | Value |
|---|---|
| **Feature** | Daily Quadrant Check-In |
| **Date** | 2026-04-27 |
| **Target Directory** | `ios/RegalRecovery/RegalRecovery/` |
| **Estimated Phases** | 5 (iOS only; no backend in scope) |
| **Feature Flags** | `feature.quadrant` (dependency), `feature.quadrant.daily` (this feature) |
| **Depends On** | Weekly Quadrant Review (`feature.quadrant`) must be shipped |
| **Test Naming Convention** | `testDailyQuadrant_AC{story}_{criterion}_{description}()` |

---

## Table of Contents

1. [Overview](#1-overview)
2. [Phase 1: Data Models + SwiftData (RED → GREEN)](#2-phase-1-data-models--swiftdata-red--green)
3. [Phase 2: ViewModels (RED → GREEN)](#3-phase-2-viewmodels-red--green)
4. [Phase 3: Views](#4-phase-3-views)
5. [Phase 4: Integration + Feature Flag Wiring](#5-phase-4-integration--feature-flag-wiring)
6. [Phase 5: Notifications + Polish](#6-phase-5-notifications--polish)
7. [Test Case Summary](#7-test-case-summary)
8. [Appendix A: Phase Dependencies](#8-appendix-a-phase-dependencies)
9. [Appendix B: Shared Test Fixtures](#9-appendix-b-shared-test-fixtures)

---

## 1. Overview

### Development Philosophy

Every line of production code traces: **User Story → Acceptance Criteria → Failing Test (RED) → Implementation (GREEN) → Refactor (REFACTOR).**

This feature is iOS-only, local-first (SwiftData). No backend API. The TDD cycle applies to every ViewModel method and every model computed property before any SwiftUI view is written.

### Architecture Summary

```
PRD Acceptance Criteria
  |
  v
Failing Unit Tests (RED)
  |
  v
SwiftData Models → ViewModels → Views → Navigation + Feature Flag
  |
  v
Today View + Quadrant Dashboard Integration
  |
  v
Notification Wiring
```

### File Organization

```
ios/RegalRecovery/RegalRecovery/
  Data/Models/RRModels.swift                   # Modified: add RRQuadrantDailyEntry, RRUserRole
  Models/QuadrantDailyTypes.swift              # New: DailyEntryMode, ContextTag, CharacterOption enums
  ViewModels/
    QuadrantDailyCheckInViewModel.swift         # New: scheduled + moment mode logic
    QuadrantDailyHistoryViewModel.swift         # New: history list and today-entry editing
  Views/Activities/Quadrant/Daily/
    QuadrantDailyEntryPointView.swift           # New: mode selector (Scheduled / In-the-Moment)
    QuadrantDailyScheduledView.swift            # New: 3-screen scheduled flow
    QuadrantDailyMomentView.swift               # New: 3-screen in-the-moment flow
    QuadrantDailyRoleChipView.swift             # New: horizontal role chip selector
    QuadrantDailySlidersView.swift              # New: all 4 sliders on one screen (shared by both modes)
    QuadrantDailyNextRightThingView.swift       # New: Screen 3 for scheduled mode
    QuadrantDailyCharacterView.swift            # New: Screen 3 for in-the-moment mode
    QuadrantDailyHistoryListView.swift          # New: last 7 days entries in dashboard section
    QuadrantDailyEntryDetailView.swift          # New: read-only / edit view for a single entry
  Tests/Unit/
    QuadrantDailyCheckInViewModelTests.swift    # New
    QuadrantDailyHistoryViewModelTests.swift    # New
  Services/PlanNotificationScheduler.swift      # Modified: add daily check-in notification
  ViewModels/TodayViewModel.swift               # Modified: daily check-in card
  ViewModels/QuadrantWeeklyReviewDashboardViewModel.swift # Modified: expose daily entries
  Views/Activities/Quadrant/
    QuadrantWeeklyReviewDashboardView.swift     # Modified: add Daily Check-Ins section
  Views/Today/TodayView.swift                   # Modified: daily check-in card
```

---

## 2. Phase 1: Data Models + SwiftData (RED → GREEN)

### Goal

Define the SwiftData models for daily entries and user roles. Write model-level unit tests first. All tests fail because no model exists yet.

### 2.1 Tests to Write First (RED)

**File:** `Tests/Unit/QuadrantDailyCheckInViewModelTests.swift`

Write these model-layer tests before creating any model code:

```swift
// MARK: - RRQuadrantDailyEntry Model

func testDailyQuadrant_AC1_1_NewEntryDefaultsToScheduledMode()
// RRQuadrantDailyEntry() -> mode == "scheduled"

func testDailyQuadrant_AC1_2_EntryDateIsCalendarDay()
// Created with Date() -> entryDate has same year/month/day as today (no time component used for date matching)

func testDailyQuadrant_AC1_3_ScoresDefaultToFive()
// bodyScore == 5, mindScore == 5, heartScore == 5, spiritScore == 5

func testDailyQuadrant_AC1_4_MomentModeFieldsAreNil()
// mode = "scheduled" -> contextTag == nil, contextNote == nil, characterSelection == nil

func testDailyQuadrant_AC1_5_ScheduledModeFieldsAreNil()
// mode = "moment" -> nextRightThing == nil (set by mode semantics)

func testDailyQuadrant_AC1_6_RolesJSONRoundtrip()
// Set rolesJSON = ["Husband", "Father"] -> decode -> ["Husband", "Father"]

func testDailyQuadrant_AC9_1_OnlyOneEntryPerCalendarDayPerMode()
// Given scheduled entry for today, creating another scheduled entry for today -> should be detected as duplicate

// MARK: - RRUserRole Model

func testDailyQuadrant_AC4_1_DefaultRolesCount()
// Default role list has exactly 8 predefined roles (Son of God through Coach)

func testDailyQuadrant_AC4_2_DefaultRolesHaveCorrectNames()
// Roles include: "Son of God", "Husband", "Father", "Employee", "Friend", "Son", "Brother", "Coach"

func testDailyQuadrant_AC4_3_IsDefaultFlagSetForSystemRoles()
// All 8 default roles have isDefault == true

func testDailyQuadrant_AC4_4_CharacterTraitsJSONRoundtrip()
// Set traitsJSON = ["Tender", "Pursuing"] -> decode -> ["Tender", "Pursuing"]

// MARK: - DailyEntryMode enum

func testDailyQuadrant_AC3_1_ModeScheduledRawValue()
// DailyEntryMode.scheduled.rawValue == "scheduled"

func testDailyQuadrant_AC3_2_ModeMomentRawValue()
// DailyEntryMode.moment.rawValue == "moment"

// MARK: - ContextTag enum

func testDailyQuadrant_AC10_1_ContextTagHasSixOptions()
// ContextTag.allCases.count == 6

func testDailyQuadrant_AC10_2_ContextTagDisplayLabels()
// .inConversation.displayLabel == "In a conversation"
// .feelingTemptation.displayLabel == "Feeling temptation"
// etc.
```

### 2.2 Implementation (GREEN)

**File:** `Models/QuadrantDailyTypes.swift`

```swift
// MARK: - Supporting types for daily check-in (no SwiftData dependency)

enum DailyEntryMode: String, Codable {
    case scheduled = "scheduled"
    case moment    = "moment"
}

enum ContextTag: String, Codable, CaseIterable, Identifiable {
    case inConversation    = "in_conversation"
    case feelingTemptation = "feeling_temptation"
    case beforeSomething   = "before_hard"
    case afterConflict     = "after_conflict"
    case feelingAnxious    = "feeling_anxious"
    case justBecause       = "just_because"

    var id: String { rawValue }

    var displayLabel: String { /* localized labels per PRD */ }
    var icon: String         { /* SF Symbol per tag */ }
}

struct CharacterOption: Identifiable, Hashable {
    let id: String
    let label: String
    let isFromUserProfile: Bool
}

// Default generic character options when no role profile exists
extension CharacterOption {
    static let defaults: [CharacterOption] = [
        .init(id: "present",    label: "Present",    isFromUserProfile: false),
        .init(id: "kind",       label: "Kind",       isFromUserProfile: false),
        .init(id: "honest",     label: "Honest",     isFromUserProfile: false),
        .init(id: "calm",       label: "Calm",       isFromUserProfile: false),
        .init(id: "protective", label: "Protective", isFromUserProfile: false),
        .init(id: "tender",     label: "Tender",     isFromUserProfile: false),
        .init(id: "trusting",   label: "Trusting",   isFromUserProfile: false),
        .init(id: "patient",    label: "Patient",    isFromUserProfile: false),
        .init(id: "humble",     label: "Humble",     isFromUserProfile: false),
        .init(id: "courageous", label: "Courageous", isFromUserProfile: false),
    ]
}
```

**File:** `Data/Models/RRModels.swift` (add two models)

```swift
// MARK: - Daily Quadrant Entry

@Model
final class RRQuadrantDailyEntry {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var entryDate: Date             // Calendar date; time stripped for day-level matching
    var mode: String                // DailyEntryMode.rawValue

    var bodyScore: Int
    var mindScore: Int
    var heartScore: Int
    var spiritScore: Int

    var rolesJSON: String           // JSON [String]

    var bodyDescriptor: String?
    var mindDescriptor: String?
    var heartDescriptor: String?
    var spiritDescriptor: String?

    // Scheduled mode
    var nextRightThing: String?     // max 140 chars
    var nextRightThingActivityKey: String?  // deep-link key if quick-selected

    // In-the-moment mode
    var contextTag: String?
    var contextNote: String?        // max 140 chars
    var characterSelection: String?
    var characterNote: String?      // max 140 chars

    var createdAt: Date
    var modifiedAt: Date
    var needsSync: Bool
}

// MARK: - User Role Profile

@Model
final class RRUserRole {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var roleName: String
    var isDefault: Bool
    var characterTraitsJSON: String   // JSON [String]
    var sortOrder: Int
    var createdAt: Date
}
```

Register both models in `RRModelConfiguration.allModels`.

Add a static factory for the default role set:

```swift
extension RRUserRole {
    static let defaultRoleNames = [
        "Son of God", "Husband", "Father", "Employee",
        "Friend", "Son", "Brother", "Coach"
    ]

    static func makeDefaults(userId: UUID) -> [RRUserRole] {
        defaultRoleNames.enumerated().map { idx, name in
            RRUserRole(userId: userId, roleName: name,
                       isDefault: true, sortOrder: idx)
        }
    }
}
```

### 2.3 Refactoring Opportunities

- The `rolesJSON` / `characterTraitsJSON` pattern already exists in `RRQuadrantAssessment` (`bodyIndicatorsJSON` etc.) -- extract a shared `JSONStringArray` helper if one does not exist
- Confirm that `entryDate` strips time component consistently (use `Calendar.current.startOfDay(for:)`) for day-level duplicate detection

---

## 3. Phase 2: ViewModels (RED → GREEN)

### Goal

Implement all business logic -- mode switching, role loading, duplicate detection, character option resolution, activity navigation mapping, history loading -- as testable ViewModel methods before building any view.

### 3.1 Tests: QuadrantDailyCheckInViewModel (RED)

**File:** `Tests/Unit/QuadrantDailyCheckInViewModelTests.swift`

```swift
// MARK: - Mode Initialization

func testDailyQuadrant_AC2_1_ScheduledModeIsDefault()
// QuadrantDailyCheckInViewModel() -> currentMode == .scheduled

func testDailyQuadrant_AC3_3_MomentModeCanBeSetAtInit()
// init(mode: .moment) -> currentMode == .moment

// MARK: - Role Loading

func testDailyQuadrant_AC4_5_LoadsDefaultRolesWhenNoneExist()
// Given no RRUserRole records, loadRoles() -> availableRoles has 8 defaults

func testDailyQuadrant_AC4_6_LoadsPersistedRolesWhenPresent()
// Given 3 persisted roles, loadRoles() -> availableRoles has those 3

func testDailyQuadrant_AC4_7_SelectedRolesDefaultToEmpty()
// On init, selectedRoles == []

func testDailyQuadrant_AC4_8_CanSelectMultipleRoles()
// toggleRole("Husband") + toggleRole("Father") -> selectedRoles == ["Husband", "Father"]

func testDailyQuadrant_AC4_9_CanDeselectRole()
// toggleRole("Husband") twice -> selectedRoles == []

func testDailyQuadrant_AC4_10_SelectionLimitedToThree()
// Select 4 roles -> only first 3 remain selected (or 4th is ignored)

// MARK: - Slider State

func testDailyQuadrant_AC5_1_AllSlidersDefaultToFive()
// bodyScore == 5, mindScore == 5, heartScore == 5, spiritScore == 5

func testDailyQuadrant_AC5_2_SlidersAcceptValidRange()
// setScore(.body, 1) and setScore(.body, 10) -> no error

func testDailyQuadrant_AC5_3_SliderAnchorLabelFor1to3()
// anchorLabel(for: 2) == "Struggling"

func testDailyQuadrant_AC5_4_SliderAnchorLabelFor4to6()
// anchorLabel(for: 5) == "Managing"

func testDailyQuadrant_AC5_5_SliderAnchorLabelFor7to8()
// anchorLabel(for: 8) == "Stable"

func testDailyQuadrant_AC5_6_SliderAnchorLabelFor9to10()
// anchorLabel(for: 10) == "Thriving"

// MARK: - Character Options

func testDailyQuadrant_AC4_11_CharacterOptionsFromUserProfile()
// Given Husband role has traits ["Tender", "Pursuing"],
// selectRole("Husband") -> characterOptions contains CharacterOption(label: "Tender")
// with isFromUserProfile == true

func testDailyQuadrant_AC4_12_CharacterOptionsFallBackToDefaults()
// Given role has no traits, characterOptions == CharacterOption.defaults

func testDailyQuadrant_AC4_13_CharacterOptionsBlendProfileAndDefaults()
// If role has 2 traits, characterOptions = 2 profile options + defaults (no duplicates)

// MARK: - Next Right Thing Activity Mapping

func testDailyQuadrant_AC6_1_LowestQuadrantDrivesQuickSelectSuggestions()
// body=3, mind=7, heart=7, spirit=7 -> quickSelectActivities contain "Exercise", "Nutrition Check-in"

func testDailyQuadrant_AC6_2_TiedLowestUsesFirstByOrder()
// body=3, mind=3, heart=7, spirit=7 -> body wins (enum order: body < mind)

func testDailyQuadrant_AC6_3_NoSuggestionsWhenAllAbove5()
// All scores 6+ -> quickSelectActivities == []  (threshold is score <= 5)

// MARK: - Duplicate Detection (Scheduled Mode)

func testDailyQuadrant_AC9_2_DetectsDuplicateScheduledEntryForToday()
// Given scheduled entry for today exists in context,
// checkForExistingEntry() -> existingEntry != nil, isEditingExisting == true

func testDailyQuadrant_AC9_3_LoadsExistingEntryValuesForEditing()
// Given existing entry with bodyScore=8, loadExistingEntry() -> bodyScore == 8

func testDailyQuadrant_AC9_4_MomentModeAlwaysCreatesNewEntry()
// mode = .moment, existing scheduled entry today -> does NOT load it; creates new entry

// MARK: - Save

func testDailyQuadrant_AC8_1_SaveCreatesNewEntry()
// Given no existing entry, save() -> entry persisted with correct mode, date, scores

func testDailyQuadrant_AC8_2_SaveUpdatesExistingEntry()
// Given existing entry loaded (isEditingExisting == true), save() -> modifiedAt updated, id unchanged

func testDailyQuadrant_AC8_3_SaveStoresSelectedRolesAsJSON()
// selectedRoles = ["Husband", "Father"] -> saved entry.rolesJSON == "[\"Husband\",\"Father\"]"

func testDailyQuadrant_AC8_4_SaveSetsCorrectEntryDate()
// save() -> entryDate == Calendar.current.startOfDay(for: Date())

func testDailyQuadrant_AC8_5_SaveSetsCorrectMode()
// Scheduled mode save() -> entry.mode == "scheduled"
// Moment mode save() -> entry.mode == "moment"

func testDailyQuadrant_AC8_6_MomentSaveStoresContextTag()
// mode = .moment, contextTag = .inConversation -> entry.contextTag == "in_conversation"

func testDailyQuadrant_AC8_7_MomentSaveStoresCharacterSelection()
// characterSelection = "Tender" -> entry.characterSelection == "Tender"

func testDailyQuadrant_AC8_8_ScheduledSaveStoresNextRightThing()
// nextRightThingText = "Call my sponsor" -> entry.nextRightThing == "Call my sponsor"

func testDailyQuadrant_AC8_9_NextRightThingActivityKeyStoredWhenQuickSelected()
// tapQuickSelectActivity(key: "prayer") -> entry.nextRightThingActivityKey == "prayer"

// MARK: - Navigation Deep Links

func testDailyQuadrant_AC7_1_ActivityKeyMapsToCorrectDeepLink()
// "prayer" -> activityDeepLinkKey == "prayer" (matches Work tab activityTypeKey)
// "journal" -> activityDeepLinkKey == "journal"
// "phoneCalls" -> activityDeepLinkKey == "phoneCalls"

func testDailyQuadrant_AC7_2_NoDeepLinkWhenNoActivitySelected()
// nextRightThingActivityKey == nil -> resolveActivityDestination() == nil
```

### 3.2 Tests: QuadrantDailyHistoryViewModel (RED)

**File:** `Tests/Unit/QuadrantDailyHistoryViewModelTests.swift`

```swift
// MARK: - History Loading

func testDailyQuadrant_AC7_3_HistoryLoadsLast7Days()
// Given 10 daily entries over 10 days, loadHistory() -> entries.count == 7

func testDailyQuadrant_AC7_4_HistoryOrderedNewestFirst()
// entries[0].entryDate > entries[1].entryDate

func testDailyQuadrant_AC7_5_HistoryIncludesBothModes()
// Given 3 scheduled + 2 moment entries in last 7 days -> all 5 appear

func testDailyQuadrant_AC7_6_TodaysEntryIsEditable()
// Entry with today's date -> isEditable == true

func testDailyQuadrant_AC7_7_PastEntryIsReadOnly()
// Entry with yesterday's date -> isEditable == false

func testDailyQuadrant_AC14_1_MomentEntriesHaveDistinctIndicator()
// mode == "moment" -> isMomentEntry == true

func testDailyQuadrant_AC14_2_ScheduledEntriesHaveNoMomentIndicator()
// mode == "scheduled" -> isMomentEntry == false

// MARK: - Today View Card State

func testDailyQuadrant_AC5_3_TodayCardStateNeverUsed()
// No daily entries ever -> todayCardState == .neverUsed

func testDailyQuadrant_AC5_4_TodayCardStateNotYetCheckedIn()
// Has past entries but none today -> todayCardState == .notYetCheckedIn

func testDailyQuadrant_AC5_5_TodayCardStateCheckedIn()
// Has entry for today -> todayCardState == .checkedIn(entry)

// MARK: - Streak (Could Have -- C2)

func testDailyQuadrant_AC11_1_StreakIsZeroWithNoEntries()
// No entries -> currentStreak == 0

func testDailyQuadrant_AC11_2_StreakCountsConsecutiveDays()
// Entries for today, yesterday, day before -> currentStreak == 3

func testDailyQuadrant_AC11_3_StreakBrokenByGap()
// Entries for today and 3 days ago (gap) -> currentStreak == 1 (only today)

func testDailyQuadrant_AC11_4_StreakCountsMomentAndScheduledBothAsCheckedIn()
// Moment entry today + scheduled entries for prior 4 days -> currentStreak == 5
```

### 3.3 Implementation (GREEN)

**File:** `ViewModels/QuadrantDailyCheckInViewModel.swift`

```swift
@Observable
final class QuadrantDailyCheckInViewModel {
    // State
    var currentMode: DailyEntryMode = .scheduled
    var availableRoles: [RRUserRole] = []
    var selectedRoles: [String] = []

    var bodyScore: Int = 5
    var mindScore: Int = 5
    var heartScore: Int = 5
    var spiritScore: Int = 5

    var bodyDescriptor: String = ""
    var mindDescriptor: String = ""
    var heartDescriptor: String = ""
    var spiritDescriptor: String = ""

    // Scheduled mode
    var nextRightThingText: String = ""
    var nextRightThingActivityKey: String? = nil

    // In-the-moment mode
    var selectedContextTag: ContextTag? = nil
    var contextNote: String = ""
    var selectedCharacter: String? = nil
    var characterNote: String = ""

    // Edit state
    var isEditingExisting: Bool = false
    var existingEntryId: UUID? = nil

    // Derived
    var characterOptions: [CharacterOption] { /* from profile or defaults */ }
    var quickSelectActivities: [(key: String, label: String)] { /* from lowest score */ }
    var lowestQuadrant: QuadrantWeeklyReviewType? { /* body/mind/heart/spirit */ }

    // Methods
    init(mode: DailyEntryMode = .scheduled)
    func loadRoles(context: ModelContext, userId: UUID)
    func loadExistingEntry(context: ModelContext, userId: UUID)
    func toggleRole(_ roleName: String)
    func setScore(_ quadrant: QuadrantWeeklyReviewType, _ value: Int)
    func anchorLabel(for score: Int) -> String
    func save(context: ModelContext, userId: UUID)
    func resolveActivityDestination() -> String?

    // NOTE: reuses QuadrantWeeklyReviewType (body/mind/heart/spirit) for quadrant identity
}
```

**File:** `ViewModels/QuadrantDailyHistoryViewModel.swift`

```swift
@Observable
final class QuadrantDailyHistoryViewModel {
    var entries: [RRQuadrantDailyEntry] = []
    var currentStreak: Int = 0

    enum TodayCardState {
        case neverUsed
        case notYetCheckedIn
        case checkedIn(RRQuadrantDailyEntry)
    }
    var todayCardState: TodayCardState = .neverUsed

    func load(context: ModelContext, userId: UUID)
    func isEditable(_ entry: RRQuadrantDailyEntry) -> Bool
    func isMomentEntry(_ entry: RRQuadrantDailyEntry) -> Bool
}
```

### 3.4 Refactoring Opportunities

- `anchorLabel(for:)` is shared logic with the Weekly Quadrant Review slider (same 1-3/4-6/7-8/9-10 bands) -- extract to `QuadrantWeeklyReviewScoringService` or a shared helper to avoid duplication
- The activity key → display label mapping is identical to `QuadrantWeeklyReviewType.recommendedActivities` -- reuse it rather than duplicating the mapping in the daily ViewModel

---

## 4. Phase 3: Views

### Goal

Build the SwiftUI views for both check-in modes, the history list, and the detail viewer. Views have no logic -- all state lives in the ViewModels tested in Phase 2.

### 4.1 Shared Component: Sliders Screen

**File:** `Views/Activities/Quadrant/Daily/QuadrantDailySlidersView.swift`

Single-screen layout showing all four quadrant sliders simultaneously. Used by both Scheduled and In-the-Moment modes.

```
┌─────────────────────────────────┐
│  [Roles context: "Husband · Father"]        │
│                                 │
│  🧠 Mind         [━━━●━━━━] 5  Managing  │
│  💙 Heart        [━━━━━●━━] 6  Managing  │
│  🏃 Body         [━━━━━━━●] 8  Stable    │
│  ✨ Spirit       [●━━━━━━━] 2  Struggling│
│                                 │
│  [optional: one-word field per quadrant]    │
│                                 │
│              [Next →]           │
└─────────────────────────────────┘
```

Key constraints:
- All four sliders visible without scrolling on iPhone SE (3rd gen)
- Role context shown as a pill row at the top if roles are selected
- Anchor label (Struggling / Managing / Stable / Thriving) updates in real time
- Optional one-word/emoji descriptor field below each slider (placeholder: "one word...")

### 4.2 Scheduled Mode Flow

**File:** `Views/Activities/Quadrant/Daily/QuadrantDailyScheduledView.swift`

Three-screen flow using `NavigationStack` with `.navigationDestination`:

**Screen 1 -- Role Context (`QuadrantDailyRoleChipView`)**

```
┌─────────────────────────────────┐
│  "How are you right now?"       │
│                                 │
│  [Son of God] [Husband] [Father]│
│  [Employee] [Friend] [Son]      │
│  [Brother] [Coach]              │
│                                 │
│  If Husband selected + traits:  │
│  ┌──────────────────────────┐   │
│  │ Growing in: Tender ·     │   │
│  │ Pursuing · Transparent   │   │
│  └──────────────────────────┘   │
│                                 │
│              [Next →]           │
└─────────────────────────────────┘
```

**Screen 2 -- Sliders** (reuse `QuadrantDailySlidersView`)

**Screen 3 -- Next Right Thing (`QuadrantDailyNextRightThingView`)**

```
┌─────────────────────────────────┐
│  "What is God calling you to?"  │
│                                 │
│  Quick suggestions (lowest Q):  │
│  [📔 Journaling] [📋 Step Work] │
│                                 │
│  Or write your own:             │
│  ┌──────────────────────────┐   │
│  │ I want to...             │   │
│  └──────────────────────────┘   │
│                                 │
│  [Skip]            [Save ✓]     │
└─────────────────────────────────┘
```

### 4.3 In-the-Moment Mode Flow

**File:** `Views/Activities/Quadrant/Daily/QuadrantDailyMomentView.swift`

Three-screen flow. Must feel fast -- no loading states on Screen 1.

**Screen 1 -- Context (`QuadrantDailyContextView` as inner view)**

```
┌─────────────────────────────────┐
│  "What's happening right now?"  │
│                                 │
│  [💬 In a conversation]         │
│  [🔥 Feeling temptation]        │
│  [😓 Before something hard]     │
│  [💥 After a conflict]          │
│  [😰 Feeling anxious]           │
│  [✦  Just because]              │
│                                 │
│  Optional: "What just happened?"│
│  ┌──────────────────────────┐   │
│  │                          │   │
│  └──────────────────────────┘   │
│                                 │
│              [Next →]           │
└─────────────────────────────────┘
```

**Screen 2 -- Sliders** (reuse `QuadrantDailySlidersView`)

**Screen 3 -- Character Question (`QuadrantDailyCharacterView`)**

```
┌─────────────────────────────────┐
│  "Who is God calling you to be?"│
│                                 │
│  [Present] [Kind] [Honest]      │
│  [Calm] [Protective] [Tender]   │
│  [Trusting] [Patient] [Humble]  │
│  [Courageous]                   │
│                                 │
│  Optional: "What would that     │
│  look like right now?"          │
│  ┌──────────────────────────┐   │
│  │                          │   │
│  └──────────────────────────┘   │
│                                 │
│  [Skip]            [Done ✓]     │
└─────────────────────────────────┘
```

### 4.4 Entry Point and Mode Selector

**File:** `Views/Activities/Quadrant/Daily/QuadrantDailyEntryPointView.swift`

Routes to the correct mode based on how the feature is accessed:
- Work tab tile → Mode selector sheet: two large buttons "Daily Check-In" and "In-the-Moment"
- Today view "Check in now" → Scheduled mode directly
- Any "in-the-moment" shortcut → Moment mode directly
- If today's scheduled entry already exists → load it for editing (no mode selector)

```swift
struct QuadrantDailyEntryPointView: View {
    var launchMode: DailyEntryMode? = nil  // nil = show selector

    var body: some View {
        if let mode = launchMode ?? resolvedMode {
            // route to scheduled or moment view
        } else {
            // show mode selector
        }
    }
}
```

### 4.5 History and Dashboard Section

**File:** `Views/Activities/Quadrant/Daily/QuadrantDailyHistoryListView.swift`

Compact card list for embedding in `QuadrantWeeklyReviewDashboardView`:

```
Daily Check-Ins
─────────────────────────────────
Mon Apr 28  Husband · Father
            🧠7  💙6  🏃8  ✨5
─────────────────────────────────
Sun Apr 27  ⚡ In a conversation    ← lightning = moment entry
            🧠4  💙3  🏃6  ✨4
─────────────────────────────────
Sat Apr 26  (no entry)
─────────────────────────────────
```

Shows last 7 calendar days. Days with no entry shown as a muted "no entry" row.

**File:** `Views/Activities/Quadrant/Daily/QuadrantDailyEntryDetailView.swift`

Read-only view for past entries; edit mode for today's entry. Shows all fields: roles, scores, descriptors, context tag, next right thing / character selection.

### 4.6 Today View Card

Modify `Views/Today/TodayView.swift` to include the daily check-in card driven by `TodayCardState`:

```
┌─────────────────────────────────┐
│ 📊 Daily Check-In               │
│ How are you right now?          │     (state: .notYetCheckedIn)
│                     [Check in →]│
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ 📊 Daily Check-In  ✓ Done       │
│ 🧠7  💙6  🏃8  ✨5              │     (state: .checkedIn)
│  Husband · Father        [View] │
└─────────────────────────────────┘
```

The `.neverUsed` state shows no card.

---

## 5. Phase 4: Integration + Feature Flag Wiring

### Goal

Wire the daily check-in into the app's navigation, feature flags, Quadrant dashboard, and Today view. Write integration-level tests first.

### 5.1 Tests to Write First (RED)

```swift
// MARK: - Feature Flag

func testDailyQuadrant_FF_1_DailyFeatureHiddenWhenFlagDisabled()
// feature.quadrant.daily = false -> No "Daily Check-In" button on Quadrant dashboard

func testDailyQuadrant_FF_2_DailyFeatureHiddenWhenParentFlagDisabled()
// feature.quadrant = false (parent off) -> daily feature also hidden regardless of daily flag

func testDailyQuadrant_FF_3_DailyFeatureVisibleWhenBothFlagsEnabled()
// feature.quadrant = true AND feature.quadrant.daily = true -> button visible

// MARK: - Work Tab Tile

func testDailyQuadrant_FF_4_WorkTabTileNavigatesToDailyEntryPoint()
// Tap "Daily Check-In" tile in Work tab -> QuadrantDailyEntryPointView presented

// MARK: - Today View

func testDailyQuadrant_AC5_6_TodayViewCardHiddenWhenNeverUsed()
// No daily entries ever -> no daily check-in card in Today view

func testDailyQuadrant_AC5_7_TodayViewCardShowsPromptWhenNotCheckedIn()
// Has past entries, none today -> card with "Check in now" visible

func testDailyQuadrant_AC5_8_TodayViewCardShowsScoresWhenCheckedIn()
// Today's entry exists -> card shows four scores

// MARK: - Quadrant Dashboard

func testDailyQuadrant_AC7_8_DashboardShowsDailyCheckInsSection()
// Daily entries exist -> "Daily Check-Ins" section visible on Quadrant dashboard

func testDailyQuadrant_AC7_9_DashboardHidesDailySectionWhenNoEntries()
// No daily entries -> section not shown (not an empty state; simply absent)
```

### 5.2 Implementation (GREEN)

**`Services/FeatureFlagStore.swift`** -- add flag default:

```swift
"feature.quadrant.daily": false   // disabled until graduated rollout
```

**`ViewModels/RecoveryWorkViewModel.swift`** -- add tile (or verify it exists):

The Daily Check-In is accessed from the **Quadrant dashboard** (not a separate Work tile), so no new Work tile is needed. The existing `"quadrant"` tile leads to `QuadrantWeeklyReviewEntryPointView`, which embeds the Daily Check-Ins section on the dashboard.

However, add a convenience deep-link check: if the feature flag `feature.quadrant.daily` is enabled, the Quadrant dashboard shows the "Daily Check-In" button prominently.

**`Views/Activities/Quadrant/QuadrantWeeklyReviewDashboardView.swift`** -- add section:

```swift
// After radar chart + trend sections:
if featureFlags["feature.quadrant.daily"] == true {
    QuadrantDailyHistoryListView(vm: dailyHistoryVM)
        .padding(.top, 16)
}
```

**`ViewModels/QuadrantWeeklyReviewDashboardViewModel.swift`** -- add:

```swift
var dailyHistoryVM = QuadrantDailyHistoryViewModel()

func load(context: ModelContext, userId: UUID) {
    // existing weekly load...
    dailyHistoryVM.load(context: context, userId: userId)
}
```

**`ViewModels/TodayViewModel.swift`** -- add daily check-in card state:

```swift
var dailyCheckInCardState: QuadrantDailyHistoryViewModel.TodayCardState = .neverUsed

// In loadTodayData():
let dailyHistoryVM = QuadrantDailyHistoryViewModel()
dailyHistoryVM.load(context: context, userId: userId)
dailyCheckInCardState = dailyHistoryVM.todayCardState
```

**`Views/Today/TodayView.swift`** -- add card:

```swift
// Guarded by feature.quadrant AND feature.quadrant.daily
if featureFlags["feature.quadrant"] == true &&
   featureFlags["feature.quadrant.daily"] == true {
    switch todayViewModel.dailyCheckInCardState {
    case .neverUsed:
        EmptyView()
    case .notYetCheckedIn:
        DailyCheckInPromptCard()
    case .checkedIn(let entry):
        DailyCheckInCompletedCard(entry: entry)
    }
}
```

**Activity deep-link wiring**: when the user taps a quick-select activity from the "next right thing" screen, use the existing `destinationView(for:)` switch in `RecoveryWorkView`. The `nextRightThingActivityKey` values ("prayer", "journal", "phoneCalls", "fanos") must match existing `activityTypeKey` values in `RecoveryWorkViewModel.allTiles`.

---

## 6. Phase 5: Notifications + Polish

### Goal

Add the daily check-in notification, verify the streak logic, and confirm end-to-end behavior for both modes.

### 6.1 Tests to Write First (RED)

```swift
// MARK: - Notifications

func testDailyQuadrant_AC13_1_NotificationScheduledAtConfiguredTime()
// scheduleDailyCheckInNotification(at: 7:00 AM) -> pending notification exists

func testDailyQuadrant_AC13_2_NotificationSuppressedWhenAlreadyCheckedIn()
// Today's entry exists -> checkAndSuppressNotificationIfCompleted() -> no pending notification

func testDailyQuadrant_AC13_3_NotificationBodyIsCorrect()
// Notification body == "How are your Mind, Heart, Body, and Spirit today?"

func testDailyQuadrant_AC13_4_TappingNotificationOpensDailyCheckIn()
// UNNotificationResponse with daily check-in identifier -> routes to QuadrantDailyEntryPointView(launchMode: .scheduled)

// MARK: - End-to-End Flow Validation

func testDailyQuadrant_E2E_1_ScheduledFlowSavesAllFields()
// Complete full scheduled flow -> verify all fields persisted correctly

func testDailyQuadrant_E2E_2_MomentFlowSavesAllFields()
// Complete full moment flow -> verify mode, contextTag, characterSelection persisted

func testDailyQuadrant_E2E_3_EditingTodayEntryPreservesCreatedAt()
// Load today's entry, change score, save -> createdAt unchanged, modifiedAt updated

func testDailyQuadrant_E2E_4_DeepLinkFromNextRightThingNavigatesCorrectly()
// Tap "Prayer" quick-select -> app navigates to Prayer activity entry point
```

### 6.2 Implementation (GREEN)

**`Services/PlanNotificationScheduler.swift`** -- add daily check-in notification:

```swift
// Daily check-in reminder
// Identifier: "daily.quadrant.checkin"
// Default time: 7:00 AM (user-configurable in notification settings)
// Repeat: daily
// Suppression check: if RRQuadrantDailyEntry with today's date exists for scheduled mode
//                    -> cancel the pending notification for today

func scheduleDailyQuadrantCheckIn(at time: DateComponents)
func cancelDailyQuadrantCheckIn()
func suppressTodayDailyQuadrantNotificationIfCompleted(context: ModelContext, userId: UUID)
```

Trigger `suppressTodayDailyQuadrantNotificationIfCompleted` on app foreground and on daily check-in save.

### 6.3 Refactoring Opportunities

- Both notification scheduling calls (weekly quadrant + daily check-in) follow the same pattern -- consider a `QuadrantNotificationCoordinator` that manages both and handles suppression logic in one place
- The "days with entries" streak calculation and the Today view card state are both derived from the same query -- run the query once in `QuadrantDailyHistoryViewModel.load` and share the result

---

## 7. Test Case Summary

### Total Test Cases by Phase

| Phase | Component | Test Count | Test Type |
|---|---|---|---|
| 1 | Data models (SwiftData) | 14 | Unit |
| 2 | QuadrantDailyCheckInViewModel | 31 | Unit |
| 2 | QuadrantDailyHistoryViewModel | 11 | Unit |
| 4 | Feature flag + integration | 9 | Integration |
| 5 | Notifications + E2E | 8 | Integration/E2E |
| **Total** | | **73** | |

### Critical Path Tests (100% Coverage Required)

| Test | Why Critical |
|---|---|
| `testDailyQuadrant_AC9_2_DetectsDuplicateScheduledEntryForToday` | Prevents double-entry data corruption |
| `testDailyQuadrant_AC9_4_MomentModeAlwaysCreatesNewEntry` | Moment entries are distinct events; must not overwrite scheduled entry |
| `testDailyQuadrant_AC8_4_SaveSetsCorrectEntryDate` | Incorrect date strips the daily habit pattern from history |
| `testDailyQuadrant_FF_2_DailyFeatureHiddenWhenParentFlagDisabled` | Parent flag dependency must be enforced |
| `testDailyQuadrant_E2E_3_EditingTodayEntryPreservesCreatedAt` | Immutable `createdAt` (FR2.7 pattern) |
| `testDailyQuadrant_AC13_2_NotificationSuppressedWhenAlreadyCheckedIn` | Prevents notification spam after user completes check-in |

### Test Naming Convention

All tests follow: `testDailyQuadrant_AC{story}_{criterion}_{description}()`

Examples:
- `testDailyQuadrant_AC2_1_ScheduledModeIsDefault()`
- `testDailyQuadrant_AC8_6_MomentSaveStoresContextTag()`
- `testDailyQuadrant_FF_2_DailyFeatureHiddenWhenParentFlagDisabled()`
- `testDailyQuadrant_E2E_1_ScheduledFlowSavesAllFields()`

### Coverage Targets

| Component | Target | Rationale |
|---|---|---|
| Data models (computed properties) | 100% | Mode semantics and JSON roundtrip are load-bearing |
| QuadrantDailyCheckInViewModel | >= 90% | All save and navigation paths |
| QuadrantDailyHistoryViewModel | >= 90% | Card state drives Today view behavior |
| Feature flag wiring | 100% | Parent flag dependency is critical |
| Views | >= 60% | Logic-free; snapshot tests if practical |

---

## 8. Appendix A: Phase Dependencies

```
Phase 1: Data Models + SwiftData
  |
  v
Phase 2: ViewModels (depends on models compiling)
  |
  ├──→ Phase 3: Views (depends on ViewModels)
  |
  └──→ Phase 4: Integration + Feature Flag Wiring
         |
         v
       Phase 5: Notifications + Polish
```

**Parallelization within phases:**
- Phase 2: `QuadrantDailyCheckInViewModel` and `QuadrantDailyHistoryViewModel` can be developed in parallel once Phase 1 models exist
- Phase 3: Scheduled and In-the-Moment mode views can be built in parallel; they share `QuadrantDailySlidersView` which should be built first
- Phase 4 and Phase 3 can overlap once ViewModels from Phase 2 are green

**Dependency on Weekly Quadrant Review:**
- `QuadrantWeeklyReviewType` (body/mind/heart/spirit enum) is reused for slider identity -- do not duplicate it
- `QuadrantWeeklyReviewScoringService.anchorLabel(for:)` should be extended to serve daily sliders
- `QuadrantWeeklyReviewDashboardView` is modified in Phase 4 -- requires the weekly feature to be fully shipped

---

## 9. Appendix B: Shared Test Fixtures

These expected values must be consistent with the weekly scoring service (which shares the same slider anchor labels and activity mappings):

### Slider Anchor Labels

| Score Range | Label |
|---|---|
| 1-3 | Struggling |
| 4-6 | Managing |
| 7-8 | Stable |
| 9-10 | Thriving |

### Quick-Select Activity Suggestions (score <= 5 triggers)

| Lowest Quadrant | Suggested Activity Keys + Labels |
|---|---|
| Body | `exercise` "Exercise", `nutrition` "Nutrition Check-in" |
| Mind | `journal` "Journaling", `stepWork` "Step Work" |
| Heart | `phoneCalls` "Phone Calls", `fanos` "FANOS Check-in" |
| Spirit | `prayer` "Prayer", `affirmations` "Declarations of Truth" |

These keys must match `activityTypeKey` values in `RecoveryWorkViewModel.allTiles` for deep-link navigation to work.

### Default Role Names (exact strings for test assertions)

```
"Son of God", "Husband", "Father", "Employee",
"Friend", "Son", "Brother", "Coach"
```

### Context Tag Raw Values (for `contextTag` field assertions)

```
"in_conversation", "feeling_temptation", "before_hard",
"after_conflict", "feeling_anxious", "just_because"
```
