# Bowtie Diagram — Implementation Design Spec

**Date:** 2026-04-22
**PRD:** docs/prd/specific-features/bowtie/prd.md
**Status:** Approved

---

## Open Question Decisions

1. **Small screens:** Default to list-based entry on smaller screens, visual diagram on larger screens (use `horizontalSizeClass`)
2. **Role granularity:** Support sub-roles via optional parent relationship on `RRUserRole`
3. **Big Ticket → Three I's mapping:** System suggests default mapping, users can customize
4. **Frequency prompts:** Entirely user-initiated, no weekly prompts
5. **Spiritual lens:** Included as default step in Backbone flow
6. **PPP follow-up timing:** Next time user opens the app after the anticipated time
7. **Post-mortem linking:** Skip for v1
8. **Time intervals:** Fixed intervals (1, 3, 6, 12, 24, 36, 48h) as guides representing approximate ranges; make configurable

---

## Data Layer

### SwiftData Models (added to RRModels.swift)

**RRBowtieSession**
- `id: UUID`, `status: BowtieStatus` (draft/complete)
- `referenceTimestamp: Date` — the "Now" point
- `createdAt: Date`, `completedAt: Date?`, `modifiedAt: Date`
- `selectedRoleIds: [UUID]`
- `emotionVocabulary: EmotionVocabulary` (threeIs/bigTicket/combined)
- `entryPath: BowtieEntryPath` (activities/postRelapse/fasterScale/checkIn)
- `sessionMode: BowtieSessionMode` (guided/freeform)
- Computed tally fields: `pastInsignificanceTotal`, `pastIncompetenceTotal`, `pastImpotenceTotal`, `futureInsignificanceTotal`, `futureIncompetenceTotal`, `futureImpotenceTotal`
- `syncStatus: SyncStatus`
- Relationship: `@Relationship(deleteRule: .cascade) var markers: [RRBowtieMarker]`

**RRBowtieMarker**
- `id: UUID`, `side: BowtieSide` (past/future)
- `timeIntervalHours: Int` (1, 3, 6, 12, 24, 36, 48)
- `roleId: UUID`
- `iActivations: [IActivation]` — embedded Codable array
- `bigTicketEmotions: [BigTicketActivation]?`
- `customEmotions: [String]?`
- `knownTriggerIds: [UUID]?`
- `briefDescription: String?` (max 280 chars)
- `isProcessed: Bool`
- `createdAt: Date`
- Relationship: `var session: RRBowtieSession?` (inverse)
- Relationship: `@Relationship(deleteRule: .cascade) var backboneProcessing: RRBackboneProcessing?`
- Relationship: `@Relationship(deleteRule: .cascade) var pppEntry: RRPPPEntry?`

**RRBackboneProcessing**
- `id: UUID`, `lifeSituation: String` (max 500 chars)
- `emotions: [String]`
- `threeIs: [IActivation]`
- `emotionalNeeds: [String]`
- `intimacyActions: [IntimacyAction]`
- `spiritualReflection: String?`
- `createdAt: Date`
- Relationship: `var marker: RRBowtieMarker?` (inverse)

**RRPPPEntry**
- `id: UUID`
- `prayer: String?`
- `peopleContactIds: [UUID]?`
- `planBefore: String?`, `planDuring: String?`, `planAfter: String?`
- `reminderTime: Date?`
- `followUpOutcome: PPPOutcome?` (better/expected/harder/reflectLater)
- `followUpReflection: String?`
- `createdAt: Date`
- Relationship: `var marker: RRBowtieMarker?` (inverse)

**RRUserRole**
- `id: UUID`, `label: String`, `sortOrder: Int`, `isArchived: Bool`
- `parentRoleId: UUID?` — for sub-roles (e.g., "Father" → "Father — Oldest")
- `createdAt: Date`

**RRKnownEmotionalTrigger**
- `id: UUID`, `label: String`
- `mappedIType: ThreeIType?` — optional default mapping to a primary I
- `createdAt: Date`

### Embedded Codable Structs

```swift
struct IActivation: Codable, Hashable {
    let iType: ThreeIType
    var intensity: Int // 1-10
}

struct BigTicketActivation: Codable, Hashable {
    let emotion: BigTicketEmotion
    var intensity: Int // 1-10
}

struct IntimacyAction: Codable, Hashable {
    let category: IntimacyCategory
    let label: String
    let isCustom: Bool
}
```

### Enums (added to Types.swift)

```swift
BowtieStatus: String, Codable { case draft, complete }
BowtieSide: String, Codable { case past, future }
ThreeIType: String, Codable { case insignificance, incompetence, impotence }
BigTicketEmotion: String, Codable { case abandonment, loneliness, rejection, sorrow, neglect }
EmotionVocabulary: String, Codable { case threeIs, bigTicket, combined }
BowtieEntryPath: String, Codable { case activities, postRelapse, fasterScale, checkIn }
BowtieSessionMode: String, Codable { case guided, freeform }
IntimacyCategory: String, Codable { case god, self_, others }
PPPOutcome: String, Codable { case better, expected, harder, reflectLater }
```

Each enum includes computed properties for display name, color, and icon following the `FASTERStage` pattern.

---

## ViewModel Layer

### BowtieSessionViewModel (@Observable)
- Session lifecycle: create, resume draft, complete, delete
- Current session state: selected roles, emotion vocabulary, session mode
- Running tallies computed from markers (past/future per I-type or Big Ticket)
- Auto-save on every mutation via SwiftData
- Guided mode step flow: iterates selected roles × past/future sides
- Entry path handling with optional pre-set reference timestamp

### BowtieMarkerViewModel (@Observable)
- Form state for single activation marker
- Supports all three emotion vocabulary modes
- Known emotional trigger tagging
- Validation: at least one I-activation or emotion, intensity 1-10

### BackboneProcessingViewModel (@Observable)
- 6-step wizard: Life Situation → Emotions → Three I's → Spiritual Reflection → Emotional Needs → Intimacy Actions
- Step enum with forward/back navigation (MoodRatingView swipe pattern)
- Progress fraction, canAdvance computed properties
- Saves BackboneProcessing, updates marker `isProcessed` flag

### PPPEntryViewModel (@Observable)
- Form state: prayer, contacts, before/during/after plan text
- Reminder scheduling via local notifications
- Follow-up state: outcome + reflection

### BowtieHistoryViewModel (@Observable)
- Queries completed sessions chronologically
- Aggregate analytics: I-distribution over time, role activation frequency, anticipatory ratio
- Date range filtering

### BowtieOnboardingViewModel (@Observable)
- Onboarding step tracking (explanation → roles → triggers)
- Role and trigger suggestion lists with add/remove
- Persists to RRUserRole and RRKnownEmotionalTrigger

### RolesManagerViewModel (@Observable)
- CRUD for roles with sub-role support
- Reorder, archive, edit labels
- Shared by onboarding and settings

---

## View Layer

### Entry Points
- `ActivitiesListView` — row gated by `activity.bowtie` flag, "Continue" badge for drafts
- Post-relapse contextual card — new Bowtie with pre-set timestamp
- FASTER Scale follow-up (P2)
- Check-in follow-up (P2)

### Primary Views

**BowtieSessionView** — main session screen
- Progress bar (guided) or past/future tab selector (freeform)
- Adaptive: `BowtieDiagramView` on regular width, `BowtieListEntryView` on compact
- Running tallies card
- Toolbar: help icon, complete button

**BowtieDiagramView** — visual bowtie shape (larger screens)
- Two triangles meeting at "Now" center
- Time interval columns, colored/shaped marker dots
- Tap column → add marker, tap marker → edit/process
- Solid shapes (past) vs outlined shapes (future)

**BowtieListEntryView** — list-based (smaller screens, VoiceOver)
- Sectioned by side then time interval
- Marker cards with role, I-types, intensities, description
- Add button per section

**BowtieMarkerFormView** — sheet
- Role picker, time interval segmented control
- Emotion vocabulary section (chips based on session mode)
- Intensity slider per selection (1-10)
- Known triggers multi-select, description field (280 char), spiritual lens toggle

**BackboneFlowView** — sheet, 6-step wizard
- Swipe gesture navigation, progress bar
- Steps: Life Situation (text) → Emotions (chip selector) → Three I's (selector + intensity) → Spiritual Reflection (text) → Emotional Needs (chip selector) → Intimacy Actions (3-column picker)
- Completion overlay

**PPPFormView** — sheet
- Prayer text field with optional guided prompts based on identified I
- People contact picker from support contacts
- Plan: before/during/after text fields
- Reminder toggle + interval picker
- Follow-up section (post-anticipated time)

**BowtieOnboardingView** — full-screen flow
- 4 pages: explanation, visual metaphor, role setup, trigger setup
- Skippable, re-accessible from help icon

**BowtieHistoryView** — navigation destination
- Chronological list with summary cards
- Tap → read-only session view, swipe to delete with confirmation

**BowtieInsightsView** — analytics within history
- I-distribution bar chart with trend
- Role activation ranking
- Anticipatory ratio line chart
- Growth-oriented framing language

### Guided Mode
- Sequential role-by-role prompting through past then future sides
- Inline educational content (dismissible "Learn more" for each concept)
- After 3 completed guided sessions, default flips to freeform (tracked in UserDefaults `bowtie.guidedCompletionCount`)

---

## Integrations

**Calendar Activity:** Completed session → `RRActivity` with `activityType: "BOWTIE"`, payload: session ID, role count, marker counts, backbone count.

**Feature Flag:** `activity.bowtie` in `FeatureFlagStore.flagDefaults` as `false`. Gates Activities row, entry points, and notifications. Fail closed.

**Notifications (PPP Reminders):** `UNCalendarNotificationTrigger` at anticipated time minus interval. Content: "Your plan is ready." — non-identifying. Cancel on PPP delete or toggle off.

**PPP Follow-up:** On app foreground, query PPP entries past anticipated time with nil outcome. Surface card with 4 outcome options + optional reflection.

**Post-Relapse Entry (US-BT-071):** Contextual card after sobriety reset. Opens Bowtie with `.postRelapse` entry path and pre-set reference timestamp.

**FASTER Entry (US-BT-072, P2):** Suggestion card after `.speedingUp` or higher FASTER result.

**Journal Bridge:** "Journal" intimacy action → open `RRJournalEntry` pre-filled with Backbone context.

**Affirmation Bridge:** "Speak Truth Over Yourself" → navigate to `AffirmationSessionView`.

**Analytics:** All events from PRD Section 7.1. No PII in events. Respects existing analytics consent.

---

## Subagent Decomposition

### Phase 1 — Foundation (parallel)
- **Agent 1:** Data models — all SwiftData models, embedded types, enums, model container registration
- **Agent 2:** Roles manager — `RolesManagerViewModel`, `RolesManagerView`, sub-role support, suggestions list

### Phase 2 — Core Session (parallel, after Phase 1)
- **Agent 3:** Session + past plotting — `BowtieSessionViewModel`, `BowtieMarkerViewModel`, `BowtieSessionView`, `BowtieListEntryView`, `BowtieMarkerFormView` (past side, list-based)
- **Agent 4:** Feature flag + Activities integration — register flag, gate row, draft badge, calendar dual-write

### Phase 3 — Complete Plotting (parallel, after Phase 2)
- **Agent 5:** Future side + tallies — extend session view, running tally computation and display, complete button
- **Agent 6:** Visual diagram — `BowtieDiagramView`, adaptive layout switching, marker color/shape rendering

### Phase 4 — Processing Workflows (parallel, after Phase 3)
- **Agent 7:** Backbone flow — `BackboneProcessingViewModel`, `BackboneFlowView` (6-step wizard), processed indicator
- **Agent 8:** PPP + notifications — `PPPEntryViewModel`, `PPPFormView`, notification scheduling, follow-up prompt
- **Agent 9:** Guided mode + onboarding — `BowtieOnboardingViewModel`, `BowtieOnboardingView`, guided flow, transition tracking

### Phase 5 — History & Polish (parallel, after Phase 4)
- **Agent 10:** History + analytics — `BowtieHistoryViewModel`, `BowtieHistoryView`, `BowtieInsightsView`
- **Agent 11:** Entry points + bridges — post-relapse, FASTER, journal bridge, affirmation bridge, analytics events

### Phase 6 — Accessibility (after Phase 5)
- **Agent 12:** Accessibility + polish — VoiceOver, Dynamic Type, touch targets, color independence, reduced motion, tone review

**12 agents, 6 phases, max 3 concurrent agents per phase.**

---

## Tone & Language

All UI copy follows PRD Section 12 guidelines:
- Counselor tone: calm, honest, never rushing
- "Emotional activation" not "trigger" or "damage"
- "How strongly did this hit?" not "Rate your pain"
- Completion messages from the rotating set in PRD 12.4
- Empty states from PRD 12.3
- 8th-grade reading level maximum

## Accessibility

- VoiceOver: full support, diagram announced as structured data, list-based entry as accessible alternative
- Dynamic Type: all text scales, diagram degrades gracefully at large sizes
- Touch targets: minimum 44x44pt
- Color: never sole indicator, icons and labels accompany all color coding
- Reduced motion: disable diagram animations when enabled
- High contrast: full support
