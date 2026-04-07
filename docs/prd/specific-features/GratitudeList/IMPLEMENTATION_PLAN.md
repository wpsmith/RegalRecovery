# Gratitude List: Multi-Agent Implementation Plan

**Feature:** Gratitude List Activity
**Methodology:** Specification-Driven Development + Test-Driven Development
**Specs:** `specs/01-data-model.md` through `specs/07-integrations.md`

---

## Build Order

### Wave 1: Foundation (sequential — must complete before Wave 2)

#### Task 1.1: Data Model & Migration
- **Spec:** `specs/01-data-model.md`
- **Agent:** `swift-expert` or `general-purpose`
- **Scope:**
  1. RED: Write unit tests for `GratitudeItem`, `GratitudeCategory`, and `RRGratitudeEntry` model
     - `TestGratitude_GL_DM_AC1_ItemTextMaxLength`
     - `TestGratitude_GL_DM_AC2_CategoryTagOptions`
     - `TestGratitude_GL_DM_AC3_MoodScoreRange`
     - `TestGratitude_GL_DM_AC5_ItemOrdering`
     - `TestGratitude_GL_DM_AC6_ItemFavoriting`
     - `TestGratitude_GL_DM_AC7_EditWindow`
     - `TestGratitude_GL_DM_AC8_ReadOnlyAfter24h`
     - `TestGratitude_GL_DM_AC9_MultiplePerDay`
  2. GREEN: Implement `GratitudeItem` struct, `GratitudeCategory` enum, update `RRGratitudeEntry` model
  3. Write migration from legacy `[String]` items to `[GratitudeItem]`
     - `TestGratitude_GL_DM_AC10_LegacyMigration`
  4. Register updated model in `RRModelConfiguration`
- **Files:**
  - `ios/RegalRecovery/RegalRecovery/Data/Models/RRModels.swift`
  - `ios/RegalRecovery/RegalRecovery/Models/Types.swift` (add `GratitudeCategory`)
  - `ios/RegalRecovery/RegalRecovery/Tests/Unit/GratitudeModelTests.swift` (new)
- **Depends on:** Nothing
- **Validates:** All GL-DM-AC* criteria

#### Task 1.2: Prompt Library Content
- **Spec:** `specs/05-prompts.md`
- **Agent:** `general-purpose`
- **Scope:**
  1. Create `gratitude-prompts.json` with 50+ prompts organized by category
  2. Create `GratitudePrompt` model and `GratitudePromptService`
  3. RED: Write tests for prompt selection algorithm
     - `TestGratitude_GL_PR_AC1_PromptCount`
     - `TestGratitude_GL_PR_AC2_DeterministicDaily`
     - `TestGratitude_GL_PR_AC3_CyclePrompt`
     - `TestGratitude_GL_PR_AC5_PromptCategories`
     - `TestGratitude_GL_PR_AC6_CategoryDistribution`
  4. GREEN: Implement deterministic daily prompt selection
- **Files:**
  - `content/gratitude-prompts.json` (new)
  - `ios/RegalRecovery/RegalRecovery/Services/GratitudePromptService.swift` (new)
  - `ios/RegalRecovery/RegalRecovery/Tests/Unit/GratitudePromptTests.swift` (new)
- **Depends on:** Nothing (can run parallel with 1.1)
- **Validates:** All GL-PR-AC* criteria

---

### Wave 2: Core Screens (parallel — all depend on Wave 1)

#### Task 2.1: Entry Screen (GratitudeEntryView)
- **Spec:** `specs/02-entry-screen.md`
- **Agent:** `general-purpose`
- **Scope:**
  1. RED: Write ViewModel tests
     - `TestGratitude_GL_ES_AC1_MinimumOneItem`
     - `TestGratitude_GL_ES_AC2_CharacterLimit`
     - `TestGratitude_GL_ES_AC3_UnlimitedItems`
     - `TestGratitude_GL_ES_AC4_DeleteBeforeSave`
     - `TestGratitude_GL_ES_AC5_CategoryTag`
     - `TestGratitude_GL_ES_AC6_MoodScore`
     - `TestGratitude_GL_ES_AC10_ClearAfterSave`
     - `TestGratitude_GL_ES_AC14_SingleItemValid`
     - `TestGratitude_GL_ES_AC15_NoAbandonedTracking`
  2. GREEN: Implement `GratitudeEntryViewModel`
  3. Build `GratitudeEntryView` replacing current `GratitudeListView`
     - Dynamic item list with add/delete
     - Category tag picker (horizontal pill selector)
     - Mood selector (5 emoji buttons)
     - Photo attachment picker
     - Prompt integration (uses `GratitudePromptService`)
     - Save with confirmation animation
     - Edit mode for entries within 24h
  4. Wire post-save messages (rotating)
  5. First-use onboarding text
- **Files:**
  - `ios/RegalRecovery/RegalRecovery/ViewModels/GratitudeEntryViewModel.swift` (new)
  - `ios/RegalRecovery/RegalRecovery/Views/Activities/GratitudeListView.swift` (rewrite)
  - `ios/RegalRecovery/RegalRecovery/Tests/Unit/GratitudeEntryViewModelTests.swift` (new)
- **Depends on:** Task 1.1, Task 1.2
- **Validates:** All GL-ES-AC* criteria

#### Task 2.2: History & Browse (GratitudeHistoryView)
- **Spec:** `specs/03-history-screen.md`
- **Agent:** `general-purpose`
- **Scope:**
  1. RED: Write ViewModel tests
     - `TestGratitude_GL_HS_AC1_ReverseChronological`
     - `TestGratitude_GL_HS_AC2_EntryCardPreview`
     - `TestGratitude_GL_HS_AC6_SearchResults`
     - `TestGratitude_GL_HS_AC7_FilterCombination`
     - `TestGratitude_GL_HS_AC8_FavoritesTab`
     - `TestGratitude_GL_HS_AC9_FavoriteToggle`
  2. GREEN: Implement `GratitudeHistoryViewModel`
  3. Build views:
     - `GratitudeHistoryView` — tabbed (List / Calendar / Favorites)
     - `GratitudeDetailView` — full entry view with edit/share actions
     - Search bar with full-text search
     - Filter chips (category, date, photo, mood)
     - Calendar view with green dot indicators
- **Files:**
  - `ios/RegalRecovery/RegalRecovery/ViewModels/GratitudeHistoryViewModel.swift` (new)
  - `ios/RegalRecovery/RegalRecovery/Views/Activities/GratitudeHistoryView.swift` (new)
  - `ios/RegalRecovery/RegalRecovery/Views/Activities/GratitudeDetailView.swift` (new)
  - `ios/RegalRecovery/RegalRecovery/Tests/Unit/GratitudeHistoryViewModelTests.swift` (new)
- **Depends on:** Task 1.1
- **Validates:** All GL-HS-AC* criteria

#### Task 2.3: Trends & Insights (GratitudeTrendsView)
- **Spec:** `specs/04-trends-insights.md`
- **Agent:** `general-purpose`
- **Scope:**
  1. RED: Write ViewModel tests
     - `TestGratitude_GL_TI_AC1_CurrentStreak`
     - `TestGratitude_GL_TI_AC2_LongestStreak`
     - `TestGratitude_GL_TI_AC3_TotalDays`
     - `TestGratitude_GL_TI_AC4_MultipleEntriesSameDay`
     - `TestGratitude_GL_TI_AC5_CategoryBreakdown`
     - `TestGratitude_GL_TI_AC7_AvgItemsPerEntry`
     - `TestGratitude_GL_TI_AC10_EveningReviewExcluded`
  2. GREEN: Implement `GratitudeTrendsViewModel`
  3. Build `GratitudeTrendsView`:
     - Streak card (current, longest, total)
     - Category breakdown chart (30d/90d/all)
     - Volume trends line graph
     - Correlation insight cards
- **Files:**
  - `ios/RegalRecovery/RegalRecovery/ViewModels/GratitudeTrendsViewModel.swift` (new)
  - `ios/RegalRecovery/RegalRecovery/Views/Activities/GratitudeTrendsView.swift` (new)
  - `ios/RegalRecovery/RegalRecovery/Tests/Unit/GratitudeTrendsViewModelTests.swift` (new)
- **Depends on:** Task 1.1
- **Validates:** All GL-TI-AC* criteria

---

### Wave 3: Integration & Polish (sequential — depends on Wave 2)

#### Task 3.1: Sharing
- **Spec:** `specs/06-sharing.md`
- **Agent:** `general-purpose`
- **Scope:**
  1. RED: Write tests
     - `TestGratitude_GL_SH_AC3_PrivacyFilter` (mood/category excluded from shared text)
  2. GREEN: Implement sharing service
  3. Build styled graphic renderer
  4. Wire share sheet into `GratitudeDetailView`
- **Files:**
  - `ios/RegalRecovery/RegalRecovery/Services/GratitudeSharingService.swift` (new)
  - `ios/RegalRecovery/RegalRecovery/Tests/Unit/GratitudeSharingTests.swift` (new)
- **Depends on:** Task 2.2 (detail view)
- **Validates:** All GL-SH-AC* criteria

#### Task 3.2: Evening Review Integration
- **Spec:** `specs/07-integrations.md` (Section 1)
- **Agent:** `general-purpose`
- **Scope:**
  1. Modify `EveningReviewView` to query today's gratitude entries
  2. Show "You already captured X gratitude items today" message
  3. Add "Add More" / "Skip" actions
  4. RED: Test that evening review response does NOT count toward streak
     - `TestGratitude_GL_IN_AC1_EveningReviewCrossRef`
     - `TestGratitude_GL_IN_AC2_EveningReviewExcluded`
- **Files:**
  - `ios/RegalRecovery/RegalRecovery/Views/Activities/EveningReviewView.swift` (modify)
- **Depends on:** Task 2.1
- **Validates:** GL-IN-AC1, GL-IN-AC2

#### Task 3.3: Navigation Wiring & Dashboard Widget
- **Spec:** `specs/07-integrations.md` (Sections 2-5)
- **Agent:** `general-purpose`
- **Scope:**
  1. Wire `GratitudeListView` as the main entry point (replaces old view)
  2. Add tab navigation within gratitude: Entry / History / Trends
  3. Update `RecoveryWorkView` tile destination for gratitude
  4. Build `GratitudeWidgetCard` for Today screen
  5. Update `TodayViewModel` gratitude status
  6. Wire notifications (streak milestones, missed entry nudge, daily reminder)
     - `TestGratitude_GL_IN_AC3_DashboardWidget`
     - `TestGratitude_GL_IN_AC5_PlanScoring`
     - `TestGratitude_GL_IN_AC6_StreakNotifications`
- **Files:**
  - `ios/RegalRecovery/RegalRecovery/Views/Activities/GratitudeTabView.swift` (new — container)
  - `ios/RegalRecovery/RegalRecovery/Views/Today/GratitudeWidgetCard.swift` (new)
  - `ios/RegalRecovery/RegalRecovery/Views/Today/TodayView.swift` (modify)
  - `ios/RegalRecovery/RegalRecovery/ViewModels/TodayViewModel.swift` (modify)
  - `ios/RegalRecovery/RegalRecovery/Views/Work/RecoveryWorkView.swift` (verify tile wiring)
- **Depends on:** Tasks 2.1, 2.2, 2.3
- **Validates:** GL-IN-AC3, GL-IN-AC4, GL-IN-AC5, GL-IN-AC6, GL-IN-AC7

---

## Agent Dispatch Summary

```
Wave 1 (parallel):
  Agent A: Task 1.1 — Data Model & Migration
  Agent B: Task 1.2 — Prompt Library Content

Wave 2 (parallel, after Wave 1):
  Agent C: Task 2.1 — Entry Screen
  Agent D: Task 2.2 — History & Browse
  Agent E: Task 2.3 — Trends & Insights

Wave 3 (sequential, after Wave 2):
  Agent F: Task 3.1 — Sharing
  Agent G: Task 3.2 — Evening Review Integration
  Agent H: Task 3.3 — Navigation & Dashboard Widget
```

**Maximum parallelism:** 3 agents (Wave 2)
**Total tasks:** 8
**Review checkpoints:** After each wave, build + verify before proceeding.

---

## TDD Cycle Per Task

Each task follows this cycle:

1. **Read spec** — agent reads the relevant spec file
2. **RED** — write failing tests referencing acceptance criteria IDs
3. **GREEN** — implement minimum code to pass tests
4. **REFACTOR** — clean up while keeping tests green
5. **BUILD** — `xcodebuild` must succeed
6. **VERIFY** — run tests, confirm all pass

---

## Verification Gates

| Gate | Command | Criteria |
|------|---------|----------|
| Build | `xcodebuild -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.3.1' build` | BUILD SUCCEEDED |
| Unit Tests | `xcodebuild test -scheme RegalRecovery ...` | All GL-* tests pass |
| Coverage | Gratitude ViewModel files >= 80% | `make coverage-check` |

---

## File Map

| New File | Task | Purpose |
|----------|------|---------|
| `Models/GratitudeTypes.swift` | 1.1 | `GratitudeItem`, `GratitudeCategory` |
| `content/gratitude-prompts.json` | 1.2 | 50+ prompts |
| `Services/GratitudePromptService.swift` | 1.2 | Prompt selection logic |
| `ViewModels/GratitudeEntryViewModel.swift` | 2.1 | Entry screen logic |
| `ViewModels/GratitudeHistoryViewModel.swift` | 2.2 | History/search/filter |
| `ViewModels/GratitudeTrendsViewModel.swift` | 2.3 | Streaks, charts, insights |
| `Views/Activities/GratitudeListView.swift` | 2.1 | Rewrite of entry screen |
| `Views/Activities/GratitudeHistoryView.swift` | 2.2 | Browse/calendar/favorites |
| `Views/Activities/GratitudeDetailView.swift` | 2.2 | Full entry detail |
| `Views/Activities/GratitudeTrendsView.swift` | 2.3 | Trends dashboard |
| `Views/Activities/GratitudeTabView.swift` | 3.3 | Tab container |
| `Views/Today/GratitudeWidgetCard.swift` | 3.3 | Today screen widget |
| `Services/GratitudeSharingService.swift` | 3.1 | Share + styled graphic |
| `Tests/Unit/GratitudeModelTests.swift` | 1.1 | Data model tests |
| `Tests/Unit/GratitudePromptTests.swift` | 1.2 | Prompt service tests |
| `Tests/Unit/GratitudeEntryViewModelTests.swift` | 2.1 | Entry VM tests |
| `Tests/Unit/GratitudeHistoryViewModelTests.swift` | 2.2 | History VM tests |
| `Tests/Unit/GratitudeTrendsViewModelTests.swift` | 2.3 | Trends VM tests |
| `Tests/Unit/GratitudeSharingTests.swift` | 3.1 | Sharing tests |
