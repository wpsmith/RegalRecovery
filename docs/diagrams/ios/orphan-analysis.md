# Regal Recovery iOS -- Orphan Analysis

Analysis of types that appear to have no consumers, duplicated concepts between SwiftData models
and plain structs, and services/ViewModels that are defined but not wired into the app.

Generated 2026-04-11 from static analysis of the codebase.

---

## 1. ViewModels Not Referenced by Any View

These `@Observable` ViewModels are defined in `ViewModels/` but are never instantiated or
referenced from any file in `Views/`. Some are only referenced by unit tests.

| ViewModel | Referenced in tests? | Notes |
|---|---|---|
| `HomeViewModel` | No | Defined but no View uses it. `HomeView` queries ModelContext directly and uses `StreakViewModel.milestoneThresholds` as a static reference. |
| `ProgressViewModel` | No | `RecoveryProgressView` likely queries ModelContext directly. |
| `ProfileViewModel` | Yes (ProfileViewModelTests) | `ProfileEditView` uses `@Environment(\.modelContext)` directly instead. |
| `PrivacyViewModel` | No | `PrivacySettingsView` does not reference it. |
| `FeatureFlagViewModel` | No | `DebugFlagsView` and `FeatureFlagView` use `FeatureFlagStore` directly. |
| `AffirmationsViewModel` | Yes (AffirmationsViewModelTests) | Views use `AffirmationSessionViewModel` instead. This may be a legacy/parallel implementation. |
| `FASTERScaleViewModel` | No | Views use `FASTERCheckInViewModel` for the guided flow. `FASTERScaleView` likely queries ModelContext directly. |
| `MoodViewModel` | No | `MoodRatingView` uses `@Environment(\.modelContext)` directly. |
| `EmotionalJournalViewModel` | Yes (EmotionalJournalViewModelTests) | `EmotionalJournalView` uses `@Environment(\.modelContext)` directly. |
| `ExerciseViewModel` | No | `ExerciseLogView` uses `@Environment(\.modelContext)` directly. |
| `GoalViewModel` | No | `WeeklyGoalsView` uses `@Environment(\.modelContext)` directly. |
| `CommitmentViewModel` | No | `MorningCommitmentView` uses `@Environment(\.modelContext)` directly. |
| `SpouseCheckInViewModel` | No | `FANOSCheckInView` and `FITNAPCheckInView` use `@Environment(\.modelContext)` directly. |
| `DevotionalViewModel` | No | `DevotionalView` uses `@Environment(\.modelContext)` directly. |
| `MeetingFinderViewModel` | No | `MeetingFinderView` may use it internally; requires closer inspection. |
| `MeetingViewModel` | No | `MeetingsAttendedView` uses `@Environment(\.modelContext)` directly. |
| `StepWorkViewModel` | No | `StepWorkView` uses `@Environment(\.modelContext)` directly. |
| `UrgeLogViewModel` | Yes (UrgeLogViewModelTests) | `UrgeLogView` uses `@Environment(\.modelContext)` directly. |
| `PhoneCallViewModel` | No | `PhoneCallLogView` uses `@Environment(\.modelContext)` directly. |
| `PrayerViewModel` | No | `PrayerLogView` uses `@Environment(\.modelContext)` directly. |
| `ActivityViewModel` | No | Generic activity ViewModel with no known View consumer. |
| `GratitudeViewModel` | No | Views use the more specific `GratitudeEntryViewModel`, `GratitudeHistoryViewModel`, and `GratitudeTrendsViewModel` instead. |

**Summary:** 22 of ~40 ViewModels have no View consumer. Most Views interact with
SwiftData `ModelContext` directly via `@Environment(\.modelContext)`. The ViewModels exist as
a prepared abstraction layer (likely for future use when API sync is enabled), but the Views
currently bypass them.

---

## 2. Services Not Injected or Referenced Anywhere

| Service | Type | Notes |
|---|---|---|
| `FocusStatusMonitor` | Singleton | Defined with `shared` singleton but never referenced outside its own file. Sleep Focus auto-fill for time journal is not wired. |
| `TimeJournalReminderManager` | Singleton | Defined with `shared` singleton but never referenced outside its own file. Slot reminders are not scheduled. |
| `AffirmationOfflineCache` | @Observable | Defined but never referenced outside its own file. Contains nested `@Model` types (`RRCachedAffirmation`, `RROfflineAffirmationSession`) that are registered in `RRModelConfiguration.allModels` but have no repository protocol. |
| `AffirmationAudioSessionManager` | @Observable | Defined but never referenced outside its own file. Audio recording/playback for affirmations is not wired. |
| `ThreeCirclesOfflineCache` | @Observable | Defined but never referenced outside its own file. Contains nested `@Model` types (`RRCachedCircleSet`, `RROfflineCircleMutation`) that are not in `RRModelConfiguration.allModels`. |

**Note:** `GratitudeSharingService` IS used -- it is referenced by `GratitudeDetailView`.

---

## 3. SwiftData Models Without a Repository Protocol

These `@Model` classes are registered in `RRModelConfiguration.allModels` but have no
corresponding protocol in `RepositoryProtocols.swift`:

| Model | Managed by | Notes |
|---|---|---|
| `RRTimeJournalEntry` | `TimeJournalViewModel` directly via `ModelContext` | Has its own file `Data/Models/RRTimeJournalEntry.swift`. Uses `TimeJournalRepository` for the older `RRTimeBlock` model, but `RRTimeJournalEntry` has no repository. The `TimeJournalRepository` protocol manages `RRTimeBlock`, not `RRTimeJournalEntry`. |
| `RRCachedAffirmation` | `AffirmationOfflineCache` (unused) | Nested in `Services/AffirmationOfflineCache.swift`. No repository protocol. |
| `RROfflineAffirmationSession` | `AffirmationOfflineCache` (unused) | Nested in `Services/AffirmationOfflineCache.swift`. No repository protocol. |

Models in `ThreeCirclesOfflineCache` (`RRCachedCircleSet`, `RROfflineCircleMutation`) are NOT registered in `RRModelConfiguration.allModels`, so they are not available to the SwiftData container at all.

---

## 4. Repository Protocols/Actors Not Referenced by Any ViewModel or Service

All 21 repository protocols have corresponding `@ModelActor` implementations. However, **none
of the repository actors are instantiated by any ViewModel or Service**. The ViewModels that
interact with persistence do so through `ModelContext` directly (either via
`@Environment(\.modelContext)` in Views or by receiving a `ModelContext` parameter).

The entire repository layer (`RepositoryProtocols.swift` + `SwiftDataRepositories.swift`) exists
as a prepared abstraction for future use (e.g., when the `SyncEngine` needs to coordinate
writes through a repository interface). Currently, the repository layer is **structurally
orphaned** -- defined and implemented but never called.

---

## 5. Duplicated Concepts: SwiftData Models vs. Plain Structs

Several domain concepts exist as both a `@Model` class (for SwiftData persistence) and a plain
`struct` (for View-layer display). This is an intentional pattern (persistence model vs. view
model) but creates maintenance surface area.

| SwiftData Model | Plain Struct (Types.swift) | Overlap |
|---|---|---|
| `RRStreak` | `StreakData` | Both represent streak info. `StreakData` has `nextMilestoneDays` which `RRStreak` does not. |
| `RRMilestone` | `Milestone` | Same concept. `Milestone` (struct) has auto-generated `id`, `RRMilestone` (model) has persisted `id`. |
| `RRSupportContact` | `SupportContact` | Both represent contacts. Struct uses `ContactRole` enum; model stores role as `String`. |
| `RRFASTEREntry` | `FASTEREntry` | Both represent FASTER assessments. Struct uses `FASTERStage` enum and `[FASTERStage: Set<String>]` for indicators; model stores `stage` as `Int` and indicators as JSON string. |
| `RRCheckIn` | `CheckInEntry` | Both represent check-ins. Struct uses `[String: Int]` for answers; model uses `JSONPayload`. |
| `RREmotionalJournal` | `EmotionalJournalEntry` | Both represent emotional journal entries. Struct uses `Color` for emotionColor; model stores as `String`. |
| `RRTimeBlock` | `TimeBlock` | Both represent time blocks. Struct has a `Color` field; model does not. |
| `RRGoal` | `WeeklyGoal` | Both represent goals. Struct is simpler (no userId, dates). |
| `RRStepWork` | `StepWorkItem` | Both represent step work. Struct uses `StepStatus` enum; model stores status as `String`. |
| `RRUrgeLog` | (no direct duplicate) | Struct `ActivityEntry` is generic; `RRUrgeLog` is specific. |
| `RRMoodEntry` | (no direct duplicate) | ViewModel `MoodViewModel` has its own internal types. |
| `RRGratitudeEntry` | (uses `GratitudeItem` from GratitudeTypes.swift) | `GratitudeItem` is stored inside `RRGratitudeEntry.items` as a Codable array. This is shared, not duplicated. |
| `RRMeetingLog` | `Meeting` | `Meeting` has location/distance fields for meeting finder; `RRMeetingLog` is for attendance logging. Different purposes. |

---

## 6. Static Data Catalogs

These are intentionally not "orphaned" -- they serve specific roles:

| Type | Location | Purpose | Consumers |
|---|---|---|---|
| `SeedData` | `Data/Repositories/SeedData.swift` | Demo data seeded at app launch | `RegalRecoveryApp.swift` calls `SeedData.seedDatabase(context:)` |
| `MockData` | `Models/MockData.swift` | Preview/test data | SwiftUI previews, `ThreeCirclesViewModel.load()`, test files |
| `ContentData` | `Models/ContentData.swift` | Static content (affirmation packs, devotional, prayers, glossary, etc.) | Multiple Views in `Content/` and `Activities/` |
| `BigBookData` | `Models/BigBookData.swift` | Big Book chapter content | `BigBookView` and `BigBookChapterView` |
| `BookCatalog` | `Models/BookCatalog.swift` | Book metadata catalog | **Not referenced outside its own file** -- potential orphan |
| `BookData` | `Models/BookData.swift` | Supporting types (`Book`, `BookChapter`, `NumberStyle`) | **Not referenced outside its own file** -- potential orphan |

**`BookCatalog` and `BookData` appear to be orphaned.** They define a book/chapter data model
that is not consumed by any View or ViewModel. The `BigBookView` uses `BigBookData` instead.
These may be a newer abstraction that has not yet replaced `BigBookData`, or they may be dead code.

---

## 7. Summary of Action Items

### High Priority (dead code / wasted binary size)
1. **BookCatalog.swift and BookData.swift** -- Appear fully orphaned. Verify and remove, or wire into `BigBookView`.
2. **FocusStatusMonitor** -- Singleton never called. Either wire into time journal flow or remove.
3. **TimeJournalReminderManager** -- Singleton never called. Either wire into notification scheduling or remove.
4. **AffirmationOfflineCache / AffirmationAudioSessionManager** -- Not connected to any consumer. Either wire into `AffirmationSessionViewModel` or remove.
5. **ThreeCirclesOfflineCache** -- Not connected and its models are not even registered in `RRModelConfiguration`. Either register + wire or remove.

### Medium Priority (architectural inconsistency)
6. **22 ViewModels with no View consumer** -- Views bypass these and use `ModelContext` directly. Decide whether to:
   - (a) Wire Views to use their corresponding ViewModels (better testability, separation of concerns), or
   - (b) Remove unused ViewModels to reduce code surface.
7. **Repository layer entirely unused** -- All 21 protocols + 21 actors are implemented but never called. The `SyncEngine` does not use them either. Decide whether to wire the sync engine through repositories or remove the layer.
8. **RRTimeBlock vs. RRTimeJournalEntry** -- Two SwiftData models for time journal data. `RRTimeBlock` has a repository (`TimeJournalRepository`); `RRTimeJournalEntry` does not. These may be at different stages of migration. Consolidate to one model.

### Low Priority (design debt)
9. **Model/Struct duplication** -- 9+ concepts have both a `@Model` class and a plain struct. This is a valid pattern but increases maintenance cost. Consider generating the view-layer structs from the models, or using the models directly in Views where SwiftData observation suffices.
10. **ThreeCirclesOfflineCache models not registered** -- `RRCachedCircleSet` and `RROfflineCircleMutation` are `@Model` classes but missing from `RRModelConfiguration.allModels`. If the cache is used in the future, they will crash at runtime unless registered.
