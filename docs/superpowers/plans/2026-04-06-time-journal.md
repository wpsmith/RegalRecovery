# Time Journal (T-30/T-60) — Multi-Agent Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan. Each wave contains independent tasks that can be parallelized across agents. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the complete Time Journal feature — a structured, interval-based journaling tool for addiction recovery. Covers PRD requirements TJ-001 through TJ-085 across iOS (SwiftUI/SwiftData), Go backend (Lambda/MongoDB), and infrastructure.

**Specifications (source of truth):**
- **PRD:** `docs/prd/specific-features/TimeJournal/prd.md`
- **OpenAPI Spec:** `docs/specs/openapi/time-journal.yaml`
- **MongoDB Schema:** `docs/specs/mongodb/time-journal-schema.md`
- **iOS Design Spec:** `docs/superpowers/specs/2026-04-06-time-journal-design.md`

**Development Method:** Spec-driven + TDD
- OpenAPI spec is the single source of truth for API contracts
- Write contract tests (RED) before handler implementation (GREEN)
- Test names reference acceptance criteria: `TestTimeJournal_TJ001_TimeSlotAutoPopulated`
- Coverage: ≥80% overall, 100% for status engine and streak calculation

**Feature Flag:** `activity.time-journal` (all UI and API gated behind this flag)

---

## Wave 0: Foundation (Parallel — 3 agents)

### Agent 1: iOS Data Layer

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/Data/Models/RRTimeJournalEntry.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Models/TimeJournalTypes.swift`
- Modify: `ios/RegalRecovery/RegalRecovery/Data/Models/RRModels.swift` (add to allModels)
- Modify: `ios/RegalRecovery/RegalRecovery.xcodeproj/project.pbxproj`

- [ ] **Step 1: Create TimeJournalTypes.swift**
  Define `TimeJournalMode` enum (t30/t60), `TimeJournalSlotStatus` enum (empty/filled/retroactive/autoFilled/flagged), `TimeJournalDayStatus` enum (inProgress/overdue/completed) with the status evaluation algorithm from TJ-060-064. Include `EmotionCategory` enum and static emotion catalog (40+ emotions with the three I's). Reference iOS design spec §1.1–1.5.

- [ ] **Step 2: Create RRTimeJournalEntry SwiftData model**
  Fields per iOS design spec §1.4: id, userId, date, slotStart, slotEnd, mode, location, gpsLatitude, gpsLongitude, gpsAddress, activity, peopleJSON, emotionsJSON, extras, sleepFlag, isRetroactive, retroactiveTimestamp, isAutoFilled, autoFillSource, redlineNote, createdAt, modifiedAt. Add computed properties for decoded people/emotions arrays.

- [ ] **Step 3: Register model in RRModelConfiguration.allModels**
  Add `RRTimeJournalEntry.self` to the model list in `RRModels.swift`.

- [ ] **Step 4: Add new files to Xcode project (pbxproj)**
  Add PBXBuildFile, PBXFileReference, group children, and Sources build phase entries.

- [ ] **Step 5: Build and verify**
  `xcodebuild -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`

- [ ] **Step 6: Commit**
  `git commit -m "feat(ios): add Time Journal data model and type definitions"`

### Agent 2: Go Backend Domain + Repository

**Files:**
- Create: `api/internal/domain/timejournal/types.go`
- Create: `api/internal/domain/timejournal/service.go`
- Create: `api/internal/domain/timejournal/handler.go`
- Create: `api/internal/repository/timejournal_repo.go`
- Modify: `api/internal/repository/mongo.go` (add timejournal collection)
- Modify: `api/internal/repository/models.go` (add TimeJournalEntry model)

- [ ] **Step 1: Define domain types**
  `types.go`: TimeJournalEntry struct (all fields from OpenAPI spec), TimeJournalDay struct (daily aggregate), TimeJournalMode (t30/t60), DayStatus (inProgress/overdue/completed), Emotion struct, PersonPresent struct. Use camelCase JSON tags per Siemens guidelines.

- [ ] **Step 2: Define repository interface**
  `service.go`: TimeJournalRepository interface with methods: CreateEntry, GetEntry, UpdateEntry, GetEntriesForDate, GetDaySummary, GetDaySummaries, GetStreak, GetTodayStatus. TimeJournalService struct implementing business logic (status engine per TJ-060-064, streak calculation per TJ-030, retroactive flagging per TJ-011, 24hr edit window per TJ-017).

- [ ] **Step 3: Implement MongoDB repository**
  `timejournal_repo.go`: Implement the repository interface against MongoDB. Use `timeJournalEntries` and `timeJournalDays` collections per schema design. Compound indexes on (userId, date) and (userId, date, slotStart). Upsert daily aggregate on each entry write.

- [ ] **Step 4: Define HTTP handlers**
  `handler.go`: REST handlers matching OpenAPI spec endpoints. Request validation, response envelope formatting, error codes with `rr:0x` prefix. Wire to service layer.

- [ ] **Step 5: Add collection initialization**
  Update `mongo.go` to create timeJournalEntries and timeJournalDays collections. Add indexes per MongoDB schema spec.

- [ ] **Step 6: Commit**
  `git commit -m "feat(api): add Time Journal domain, repository, and handlers"`

### Agent 3: Contract Tests + Unit Test Scaffolding

**Files:**
- Create: `api/test/unit/timejournal_test.go`
- Create: `api/test/integration/timejournal_integration_test.go`

- [ ] **Step 1: Write contract tests (RED)**
  Validate handler responses against `docs/specs/openapi/time-journal.yaml`. Tests:
  - `TestTimeJournal_TJ001_TimeSlotAutoPopulated` — POST creates entry with correct slot boundaries
  - `TestTimeJournal_TJ003_ActivityFreeText` — Activity field supports multi-line
  - `TestTimeJournal_TJ005_EmotionWithIntensity` — Emotion array with 1-10 intensity validated
  - `TestTimeJournal_TJ011_RetroactiveEntry` — Past slot entry marked retroactive with timestamp
  - `TestTimeJournal_TJ017_EditWindow24hr` — PATCH rejected after 24hr window
  - `TestTimeJournal_TJ060_StatusInProgress` — Status engine: default is inProgress
  - `TestTimeJournal_TJ061_StatusOverdue` — Status engine: elapsed unfilled slot → overdue
  - `TestTimeJournal_TJ062_StatusCompleted` — Status engine: all slots filled → completed
  - `TestTimeJournal_TJ063_StatusOverdueGap` — Status engine: gap with later completion still overdue
  - `TestTimeJournal_TJ030_StreakCalculation` — Streak: consecutive days ≥80%

- [ ] **Step 2: Write status engine unit tests (RED)**
  Pure function tests for the status evaluation algorithm. Cover all 5 examples from the PRD table. 100% coverage required for this function.

- [ ] **Step 3: Write streak calculation unit tests (RED)**
  Test ≥80% threshold, streak break on <80%, streak counter reset. 100% coverage required.

- [ ] **Step 4: Commit**
  `git commit -m "test(api): add Time Journal contract and unit tests (RED)"`

---

## Wave 1: Core iOS Views (Parallel — 3 agents, depends on Wave 0 Agent 1)

### Agent 4: Daily Journal View

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/TimeJournal/TimeJournalDailyView.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/TimeJournal/TimeJournalHeaderView.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/TimeJournal/TimeJournalTimelineView.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/TimeJournal/TimeJournalSlotRow.swift`
- Create: `ios/RegalRecovery/RegalRecovery/ViewModels/TimeJournalViewModel.swift`

- [ ] **Step 1: Create TimeJournalViewModel**
  State: entries for current date, mode, day summary. Computed: status per TJ-060-064, completionPercent, overdueCount, lastUpdatedAt. Actions: loadDay, saveEntry, navigateDate. Reference iOS design spec §3.

- [ ] **Step 2: Create TimeJournalDailyView (TJ-015)**
  Full 24-hour timeline. Date navigation header with left/right arrows. Completion ring showing % filled. Status badge (In Progress / Overdue / Completed).

- [ ] **Step 3: Create TimeJournalTimelineView**
  ScrollView of TimeJournalSlotRow items. 24 rows (T-60) or 48 rows (T-30). Slot coloring per TJ-016: filled=solid, retroactive=dashed, empty=gray, auto-filled=system badge.

- [ ] **Step 4: Create TimeJournalSlotRow**
  Time label, status indicator, activity preview, emotion chips, tap to edit. Empty slots show "Tap to log" prompt.

- [ ] **Step 5: Add files to Xcode project, build, commit**
  `git commit -m "feat(ios): add Time Journal daily view with 24hr timeline"`

### Agent 5: Quick Entry Card

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/TimeJournal/TimeJournalQuickEntrySheet.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/TimeJournal/LocationField.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/TimeJournal/ActivityField.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/TimeJournal/PeopleField.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/TimeJournal/EmotionPicker.swift`
- Create: `ios/RegalRecovery/RegalRecovery/ViewModels/TimeJournalEntryViewModel.swift`

- [ ] **Step 1: Create TimeJournalEntryViewModel**
  State: current entry fields. Actions: save, validate, carry-forward location (TJ-013). Enforce 24hr edit window (TJ-017). Mark retroactive entries (TJ-011).

- [ ] **Step 2: Create LocationField (TJ-002)**
  Free-text with quick-select from recent/saved locations (@home, @work, @church). GPS auto-capture on entry open.

- [ ] **Step 3: Create ActivityField (TJ-003)**
  Multi-line text field. Voice-to-text button (TJ-012, P1). Prompt for people if activity contains meeting-related keywords (TJ-004).

- [ ] **Step 4: Create PeopleField (TJ-004)**
  Dynamic list of (name, gender) entries. Add/remove people.

- [ ] **Step 5: Create EmotionPicker (TJ-005)**
  Emotion grid from catalog. Tap to select, intensity slider 1-10. Three I's as quick-select. Multiple emotions per entry. Optional "why" field (TJ-043).

- [ ] **Step 6: Create TimeJournalQuickEntrySheet (TJ-010)**
  Bottom sheet with 3-tap minimum: location, activity, one emotion. Expandable for full detail. Save button persists to SwiftData.

- [ ] **Step 7: Add files to Xcode project, build, commit**
  `git commit -m "feat(ios): add Time Journal quick entry card with emotion picker"`

### Agent 6: Today Screen + Recovery Work Integration

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/Views/Today/TimeJournalTodayCard.swift`
- Modify: `ios/RegalRecovery/RegalRecovery/Views/Today/TodayView.swift`
- Modify: `ios/RegalRecovery/RegalRecovery/ViewModels/RecoveryWorkViewModel.swift`
- Modify: `ios/RegalRecovery/RegalRecovery/Views/Activities/ActivitiesListView.swift`

- [ ] **Step 1: Create TimeJournalTodayCard (TJ-065-068)**
  Card showing: Time Journal title at top of plan items (TJ-065), progress bar (TJ-066), last updated timestamp (TJ-067), status badge. Tap navigates to TimeJournalDailyView (TJ-068).

- [ ] **Step 2: Integrate into TodayView**
  When `activity.time-journal` flag is enabled and Time Journal is in user's plan, insert TimeJournalTodayCard at top of activity list. Feature flag gating per TJ-074.

- [ ] **Step 3: Add Time Journal to RecoveryWorkViewModel (TJ-069-076)**
  Generate daily `RecoveryWorkItem` with `activityType: "timeJournal"`. Always in "Due Now" section (TJ-070). Map status via shared engine (TJ-071). Dynamic trigger reason with slot count and last updated (TJ-072). Tap navigates to Daily Journal View (TJ-073). Feature flag gated (TJ-074).

- [ ] **Step 4: Add Time Journal to ActivitiesListView**
  Add Time Journal entry in the Journaling & Reflection section. Navigation to TimeJournalDailyView.

- [ ] **Step 5: Build, commit**
  `git commit -m "feat(ios): integrate Time Journal into Today screen and Recovery Work"`

---

## Wave 2: Backend Implementation (Parallel — 2 agents, depends on Wave 0 Agents 2+3)

### Agent 7: Make Contract Tests Pass (GREEN)

**Files:**
- Modify: `api/internal/domain/timejournal/service.go`
- Modify: `api/internal/domain/timejournal/handler.go`
- Modify: `api/internal/repository/timejournal_repo.go`

- [ ] **Step 1: Implement status engine (TJ-060-064)**
  Pure function `EvaluateDayStatus(entries []TimeJournalEntry, mode TimeJournalMode, now time.Time) DayStatus`. Scan slots from midnight to now; any elapsed unfilled slot → overdue. All filled including final slot → completed. Otherwise → inProgress.

- [ ] **Step 2: Implement streak calculation (TJ-030)**
  Query timeJournalDays for consecutive days where completionPercent ≥ 80. Return current and longest streak.

- [ ] **Step 3: Implement entry creation handler**
  POST /activities/time-journal/entries. Auto-populate slot boundaries based on mode. Validate emotion intensity 1-10. Flag retroactive entries. Enforce feature flag. Upsert daily aggregate.

- [ ] **Step 4: Implement entry update handler**
  PATCH /activities/time-journal/entries/{entryId}. Enforce 24hr edit window (TJ-017). Update daily aggregate.

- [ ] **Step 5: Implement query handlers**
  GET entries by date, GET day summary, GET day summaries (date range), GET streak, GET today status.

- [ ] **Step 6: Run all contract tests — verify GREEN**
  `make contract-test`

- [ ] **Step 7: Commit**
  `git commit -m "feat(api): implement Time Journal handlers (contract tests GREEN)"`

### Agent 8: Lambda Wiring + Integration Tests

**Files:**
- Modify: `api/cmd/lambda/activities/main.go` (add time-journal routes)
- Modify: `api/scripts/init-indexes.sh` (add timejournal indexes)
- Modify: `api/scripts/seed-local-data.sh` (add seed entries for Alex persona)
- Create: `api/test/integration/timejournal_integration_test.go`

- [ ] **Step 1: Wire routes in activities Lambda**
  Add routes: GET/POST /activities/time-journal/entries, GET/PATCH /activities/time-journal/entries/{id}, GET /activities/time-journal/days/{date}, GET /activities/time-journal/days, GET /activities/time-journal/streaks, GET /activities/time-journal/status.

- [ ] **Step 2: Add index creation to init-indexes.sh**
  Compound indexes per MongoDB schema spec: (userId, date), (userId, date, slotStart) unique, (userId, status).

- [ ] **Step 3: Add seed data**
  Seed 7 days of T-60 entries for Alex persona. Include mix of filled, retroactive, and auto-filled sleep entries. Day 1: 100% complete. Day 3: 85% with 2 retroactive. Day 7 (today): in-progress with 8 of 24 filled.

- [ ] **Step 4: Write integration tests**
  Tests against local MongoDB:
  - `TestTimeJournal_Integration_CreateAndRetrieveEntry`
  - `TestTimeJournal_Integration_DaySummaryCalculation`
  - `TestTimeJournal_Integration_StatusEngineEndToEnd`
  - `TestTimeJournal_Integration_StreakAcrossDays`
  - `TestTimeJournal_Integration_EditWindowEnforcement`

- [ ] **Step 5: Run integration tests**
  `make local-up && make test-integration`

- [ ] **Step 6: Commit**
  `git commit -m "feat(api): wire Time Journal Lambda routes and integration tests"`

---

## Wave 3: P1 Features (Parallel — 3 agents, depends on Waves 1+2)

### Agent 9: Reminders + Sleep Auto-Fill (iOS)

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/Services/TimeJournalReminderManager.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Services/FocusStatusMonitor.swift`

- [ ] **Step 1: Create TimeJournalReminderManager (TJ-036-040)**
  Schedule local notifications at each interval boundary during waking hours. Support DND mode (TJ-037). Smart dampening (TJ-038): if user fills consistently, prompt to reduce; if gaps appear, increase. End-of-day review reminder (TJ-039).

- [ ] **Step 2: Create FocusStatusMonitor (TJ-080-085)**
  Use iOS Focus API to detect Sleep Focus start/end. Record timestamps. On exit, auto-fill all fully-overlapping slots with "Sleep" activity. Carry-forward location. Mark as autoFilled with source "sleepFocus". Visual attribution badge. Entries are editable (TJ-083). Partial slots not auto-filled (TJ-084).

- [ ] **Step 3: Build, commit**
  `git commit -m "feat(ios): add Time Journal reminders and sleep auto-fill"`

### Agent 10: Consistency Tracking + Streaks (iOS)

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/TimeJournal/TimeJournalStreakView.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/TimeJournal/TimeJournalHeatmapView.swift`
- Modify: `ios/RegalRecovery/RegalRecovery/Views/Activities/TimeJournal/TimeJournalDailyView.swift`

- [ ] **Step 1: Create TimeJournalStreakView (TJ-030-031)**
  Streak counter display. Completion score ring. Shared with Trust Partners. Celebrate milestones at 7/30/60/90/180/365 days (TJ-034) with clinically framed affirmation.

- [ ] **Step 2: Create TimeJournalHeatmapView (TJ-032)**
  Weekly and monthly calendar heatmap color-coded by daily completion percentage.

- [ ] **Step 3: Add emotion timeline to DailyView (TJ-019)**
  Horizontal graph showing emotional intensity across the day's entries.

- [ ] **Step 4: Build, commit**
  `git commit -m "feat(ios): add Time Journal streaks, heatmap, and emotion timeline"`

### Agent 11: Integrity Prompts + Honesty Features (iOS)

**Files:**
- Modify: `ios/RegalRecovery/RegalRecovery/Views/Activities/TimeJournal/TimeJournalQuickEntrySheet.swift`

- [ ] **Step 1: Add integrity check-in prompts (TJ-046-047)**
  Random prompt on entry submission: "Is there anything in today's journal you're tempted to leave out?" Submission prompt: "Are you satisfied this entry reflects the whole truth?"

- [ ] **Step 2: Add redline field (TJ-048)**
  Optional confidential note field NOT shared with Trust Partners. Clearly labeled. Stored locally only per privacy requirements.

- [ ] **Step 3: Add gap alerts (TJ-033)**
  If user hasn't filled a slot in >90 minutes during waking hours, send gentle nudge notification.

- [ ] **Step 4: Build, commit**
  `git commit -m "feat(ios): add Time Journal integrity prompts and redline field"`

---

## Wave 4: Final Integration + Verification (Sequential)

### Agent 12: End-to-End Verification

- [ ] **Step 1: Full clean build (iOS)**
  `xcodebuild clean build -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`

- [ ] **Step 2: Run all backend tests**
  `make test-all && make coverage-check`

- [ ] **Step 3: Validate OpenAPI spec**
  `make spec-validate` — ensure time-journal.yaml passes Redocly validation

- [ ] **Step 4: Manual flow verification**
  1. Today screen → Time Journal card at top → shows progress bar and "In Progress"
  2. Tap → navigates to Daily Journal View with 24hr timeline
  3. Tap empty slot → quick entry sheet opens with location/activity/emotion
  4. Fill entry → slot changes from gray to solid color → progress bar updates
  5. Skip a slot, fill later one → status changes to "Overdue"
  6. Fill skipped slot → status returns to "In Progress"
  7. Recovery Work screen → Time Journal tile in "Due Now" with dynamic trigger reason
  8. Fill all slots including 11 PM → status changes to "Completed"
  9. Enable Sleep Focus → wake up → overnight slots auto-filled with "Sleep" badge
  10. Streak counter increments on day with ≥80% completion

- [ ] **Step 5: Coverage report**
  Verify ≥80% overall. Verify 100% on: status engine, streak calculation, edit window enforcement, sleep auto-fill boundary logic.

- [ ] **Step 6: Final commit**
  `git commit -m "feat: Time Journal feature complete — TJ-001 through TJ-085"`

---

## Dependency Graph

```
Wave 0 (Foundation — parallel)
├── Agent 1: iOS Data Layer
├── Agent 2: Go Backend Domain
└── Agent 3: Contract Tests (RED)
         │
Wave 1 (iOS Views — parallel, depends on Agent 1)
├── Agent 4: Daily Journal View
├── Agent 5: Quick Entry Card
└── Agent 6: Today + Work Integration
         │
Wave 2 (Backend — parallel, depends on Agents 2+3)
├── Agent 7: Make Tests GREEN
└── Agent 8: Lambda + Integration Tests
         │
Wave 3 (P1 Features — parallel, depends on Waves 1+2)
├── Agent 9: Reminders + Sleep Auto-Fill
├── Agent 10: Streaks + Heatmap
└── Agent 11: Integrity Prompts
         │
Wave 4 (Verification — sequential)
└── Agent 12: E2E Verification
```

## PRD Traceability Matrix

| PRD Req | Wave | Agent | Test |
|---------|------|-------|------|
| TJ-001 (Time Slot) | 0 | 1, 2 | TestTimeJournal_TJ001_TimeSlotAutoPopulated |
| TJ-002 (Location) | 1 | 5 | TestTimeJournal_TJ002_LocationQuickSelect |
| TJ-003 (Activity) | 1 | 5 | TestTimeJournal_TJ003_ActivityFreeText |
| TJ-004 (People) | 1 | 5 | TestTimeJournal_TJ004_PeopleWithGender |
| TJ-005 (Emotions) | 1 | 5 | TestTimeJournal_TJ005_EmotionWithIntensity |
| TJ-009 (Real-Time Prompt) | 3 | 9 | TestTimeJournal_TJ009_IntervalReminder |
| TJ-010 (Quick Entry) | 1 | 5 | TestTimeJournal_TJ010_ThreeTapMinimum |
| TJ-011 (Retroactive) | 0 | 3 | TestTimeJournal_TJ011_RetroactiveEntry |
| TJ-015 (Daily View) | 1 | 4 | TestTimeJournal_TJ015_24HourTimeline |
| TJ-017 (24hr Edit) | 0 | 3 | TestTimeJournal_TJ017_EditWindow24hr |
| TJ-030 (Streak) | 2 | 7 | TestTimeJournal_TJ030_StreakCalculation |
| TJ-060 (In Progress) | 0 | 3 | TestTimeJournal_TJ060_StatusInProgress |
| TJ-061 (Overdue) | 0 | 3 | TestTimeJournal_TJ061_StatusOverdue |
| TJ-062 (Completed) | 0 | 3 | TestTimeJournal_TJ062_StatusCompleted |
| TJ-063 (Gap Rule) | 0 | 3 | TestTimeJournal_TJ063_StatusOverdueGap |
| TJ-065 (Today Placement) | 1 | 6 | TestTimeJournal_TJ065_TodayScreenTop |
| TJ-066 (Progress Bar) | 1 | 6 | TestTimeJournal_TJ066_ProgressBar |
| TJ-071 (Work Status) | 1 | 6 | TestTimeJournal_TJ071_WorkStatusMapping |
| TJ-080 (Sleep Focus) | 3 | 9 | TestTimeJournal_TJ080_SleepFocusDetection |
| TJ-081 (Auto-Fill) | 3 | 9 | TestTimeJournal_TJ081_SleepAutoFill |
| TJ-084 (Partial Slot) | 3 | 9 | TestTimeJournal_TJ084_PartialSlotNoAutoFill |
