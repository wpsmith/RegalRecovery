# Daily Quadrant Check-In -- Feature PRD

| Field | Value |
|---|---|
| **PRD Title** | Daily Quadrant Check-In |
| **Author** | Travis Smith |
| **Date** | 2026-04-27 |
| **Version** | 1.0 |
| **Designation** | Feature (within Recovery Quadrant Epic) |
| **OMTM** | Percentage of active users completing daily quadrant check-ins for 14+ consecutive days (target >= 45%) |
| **Target Delivery** | 2 sprints (20 business days maximum) |
| **MoSCoW Summary** | 9 Must, 5 Should, 3 Could, 3 Won't |
| **Feature Flag** | `feature.quadrant.daily` |
| **Depends On** | `feature.quadrant` (Weekly Quadrant Review -- must be shipped first) |

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Product Overview](#2-product-overview)
3. [MoSCoW Prioritized Requirements](#3-moscow-prioritized-requirements)
4. [Functional Requirements](#4-functional-requirements)
5. [Non-Functional Requirements](#5-non-functional-requirements)
6. [Technical Considerations](#6-technical-considerations)
7. [User Stories](#7-user-stories)
8. [Implementation Roadmap](#8-implementation-roadmap)
9. [Open Questions and Risks](#9-open-questions-and-risks)
10. [Design Decisions Log](#10-design-decisions-log)

---

## 1. Executive Summary

### Problem Statement

The Weekly Quadrant Review gives users a satellite view of their whole-person wellness once per week. But the source material (Redemptive Living transcripts, Jason Martinkus' quadrant curriculum) is emphatic: the quadrant is not just a weekly assessment tool -- it is a moment-to-moment self-awareness practice. From the curriculum:

> "You can do this exercise at any given moment, at any time, for any reason to figure out what's going on with me."
> -- Jason Martinkus, Aware 1: Self-Intimacy

The quadrant's most powerful use case is **real-time self-awareness**: pausing in the middle of a triggering moment, a difficult conversation, or a temptation and asking "What am I thinking? What am I feeling? What is my body doing? Where am I with God?" This moment-to-moment awareness is the mechanism that prevents acting out. The weekly review captures the trend; the daily check-in captures the moment.

**User goal:** Build a daily habit of whole-person self-awareness using the quadrant framework so that moment-to-moment dysregulation is caught early, named accurately, and met with the next right action -- before it escalates to temptation or relapse.

**Hurdles:**
- No lightweight daily entry point exists for quadrant work; the weekly assessment flow (4 full screens + summary) is too heavy for a quick in-the-moment check-in
- Users who are mid-conflict, mid-trigger, or mid-temptation need a sub-60-second capture, not a 3-minute flow
- Without a daily habit, the weekly assessment can become a "report card" rather than a living tool; users fill it in from memory at the end of the week instead of from lived awareness throughout it
- The connection between the quadrant and "the next right thing" -- the curriculum's central application -- is not currently surfaced in a daily context

**Quantifiable impact:** The source material explicitly connects daily quadrant awareness to relapse prevention: a person who can name "I feel hopeless, my neck is tense, I'm vilifying her, I don't know where God is" is a person who can choose the next right thing instead of acting out. The daily check-in turns the quadrant from a measurement tool into a prevention tool.

### Business Hypothesis

By providing a lightweight daily quadrant check-in with an in-the-moment capture mode, a "next right thing" prompt, and optional role context, we hypothesize that:

- **Primary outcome:** 45% of users who complete their first daily check-in will maintain a 14-day streak (measured by daily check-in completion rate)
- **Secondary outcome:** Users with a regular daily check-in habit will show earlier identification of imbalance -- their weekly assessment scores will have lower week-to-week variance, indicating more stable self-awareness
- **OMTM impact:** Daily check-in habit increases overall session frequency, contributing to the app's core engagement metric

### Solution Overview

A two-mode daily quadrant activity within the Regal Recovery iOS app:

1. **Scheduled Check-In Mode** -- A brief (sub-90-second) daily check-in for the current moment. Four quadrant sliders (1-10), a role selector (what role are you primarily in right now?), and a "next right thing" prompt. No behavioral indicator checklists -- those are weekly only. Saves as a `RRQuadrantDailyEntry` distinct from the weekly `RRQuadrantAssessment`.
2. **In-the-Moment Mode** -- Triggered from an emergency/urge moment or manually. Same four sliders, but leads with "What just happened?" context and ends with "What is God calling you to right now?" instead of "next right thing." A rapid capture that names the moment and points toward the character response.

Both modes share the same data model and contribute to the weekly assessment's trend data as contextual anchors.

### Resource Requirements

- 1 iOS developer (2 sprints)
- Depends on Weekly Quadrant Review being shipped (shares data model and visualization infrastructure)
- No backend API changes required for MVP (SwiftData local-first)

---

## 2. Product Overview

### Product Vision

The Daily Quadrant Check-In turns the quadrant from a weekly report into a living daily practice. While the Weekly Quadrant Review answers "How was my Body/Mind/Heart/Spirit this week?", the daily check-in answers "How am I right now, in this role, in this moment?" -- and then asks the most important recovery question: "What is God calling me to next?" The daily practice is what builds the self-intimacy that makes the weekly assessment honest and actionable.

The vision for a seasoned user: they open the app, tap "Daily Check-In", rate four sliders in 30 seconds, pick "Husband" as their current role, read their character intention for that role, and tap "I want to grow in empathy today." Then they close the app and walk back into the room. That is whole-person recovery in 45 seconds.

### Target Users

**Primary Persona: Alex (Active Recovery, 6-18 months)**
- Uses LBI daily and weekly Quadrant; wants to deepen the practice
- Needs: a quick daily moment of honest self-assessment that is lighter-weight than the weekly flow
- Benefit: catches dimensional drift early -- before it shows in the weekly score

**Secondary Persona: Jordan (Early Recovery, 0-6 months)**
- Still building awareness habits; struggles to name what he's feeling in real time
- Needs: a structured prompt that teaches him to name his mind/heart/body/soul state in the moment
- Benefit: the daily check-in is an on-ramp to emotional literacy and self-intimacy

**Tertiary Persona: Any user in a triggering moment**
- In conflict with spouse, feeling temptation, anxious before a hard conversation
- Needs: an immediate tool to stop, name what's happening across all four dimensions, and identify the next right action
- Benefit: the in-the-moment mode is a pattern interrupt that replaces rumination or acting out with self-awareness

### Relationship to Weekly Quadrant Review

The daily check-in is **not** a replacement for the weekly assessment and must not be positioned that way. The relationship is:

| Tool | Frequency | Duration | Primary Question | Output |
|---|---|---|---|---|
| Weekly Quadrant Review | Once/week | ~3 minutes | "How was my Body/Mind/Heart/Spirit this week?" | Assessment scores, trend chart, imbalance alerts |
| Daily Check-In | Once/day (or in-the-moment) | ~45-90 seconds | "How am I right now, in this role?" | Daily entry, character prompt, next right thing |

Daily entries feed context into the weekly review: when the user sees their weekly Spirit score is 4, they can look back at daily entries that showed "Spirit: 3" every Wednesday and Thursday -- the pattern becomes visible.

### OMTM and Success Criteria

**One Metric That Matters:** 14-day daily check-in streak rate -- percentage of users who complete a daily check-in every day for 14 consecutive days after their first entry.

| Success Criterion | Target | Measurement Method |
|---|---|---|
| First daily check-in completion | >= 75% of users who open the feature | feature_opened vs check_in_saved events |
| 14-day streak rate | >= 45% of users who complete their first check-in | 14-day retention cohort |
| Median completion time (scheduled mode) | <= 90 seconds | check_in_started to check_in_saved |
| Median completion time (in-the-moment mode) | <= 60 seconds | Same |
| In-the-moment mode activation | >= 10% of all daily check-ins | mode = "moment" in analytics |
| Next right thing follow-through | >= 20% of in-the-moment check-ins followed by a recovery activity within 2 hours | check_in_saved to activity_completed within 120 min |

---

## 3. MoSCoW Prioritized Requirements

### Must Have

| ID | Requirement | Rationale |
|---|---|---|
| M1 | Daily check-in entry with four quadrant sliders (1-10) for the current moment | Core data capture; sub-90-second target |
| M2 | Scheduled Check-In mode: daily routine self-check, role selector, "next right thing" free-text prompt | Primary daily use case |
| M3 | In-the-Moment mode: rapid capture for triggering situations, leads with context, ends with character question | Recovery-critical use case; the curriculum's central application |
| M4 | Role selector: user picks their currently active role(s) (Husband, Father, Employee, Friend, Son of God, etc.) | Grounds the check-in in context; mirrors the curriculum's role-and-character framework |
| M5 | Slider anchor labels: 1-3 "Struggling", 4-6 "Managing", 7-8 "Stable", 9-10 "Thriving" | Consistent with Weekly Quadrant Review language |
| M6 | SwiftData persistence for all daily entries | Offline-first architecture requirement |
| M7 | Daily entries visible in a history list on the Quadrant dashboard | Users must be able to review past daily entries |
| M8 | Daily check-in accessible from the Work tab and Today view | Must be discoverable in primary navigation |
| M9 | One daily entry per calendar day (not per ISO week); user can edit the day's entry | Daily granularity distinct from weekly |

### Should Have

| ID | Requirement | Rationale |
|---|---|---|
| S1 | Character intention: after role selection, show the character traits the user has set for that role, and prompt "Which trait do you want to grow in today?" | Direct implementation of the curriculum's roles-character-quadrant framework |
| S2 | "Next right thing" displayed at the end of both modes with the option to navigate directly to a related activity | Makes the check-in actionable; drives engagement with existing features |
| S3 | Daily check-in entries feed into the weekly dashboard as contextual anchors (mini-markers on the trend chart) | Connects daily practice to weekly review |
| S4 | Daily notification at user-configured time (default 7:00 AM) | Habit-building; increases daily check-in consistency |
| S5 | Today view card shows daily check-in status and quick-access button | Daily habit should surface on the daily hub screen |

### Could Have

| ID | Requirement | Rationale |
|---|---|---|
| C1 | Weekly summary view showing all daily entries for the current week alongside the weekly assessment scores | Gives users insight into which days drove their weekly scores |
| C2 | Streak counter and streak milestones (7-day, 14-day, 30-day) | Gamification that rewards consistency |
| C3 | Character profile management: user can define roles and character traits per role | Enables the full roles-character-quadrant workflow from the curriculum |

### Won't Have

| ID | Requirement | Rationale |
|---|---|---|
| W1 | Backend API sync for daily entries | Deferred; local-first is sufficient |
| W2 | Replacing the weekly assessment with aggregated daily entries | The weekly assessment is a deliberate, reflective tool; daily entries are moment captures -- different cadence, different purpose |
| W3 | Daily entries shared with accountability partners | Daily entries are more intimate and immediate than weekly scores; privacy risk outweighs accountability benefit |

---

## 4. Functional Requirements

### 4.1 Entry Points and Modes

| ID | Requirement | Priority | Conditions of Satisfaction |
|---|---|---|---|
| FR-01 | Daily check-in is accessible via a "Daily Check-In" button on the Quadrant dashboard | Must | Given the user is on the Quadrant dashboard, When they tap "Daily Check-In", Then the mode selection screen (or direct entry if already today's mode is set) opens |
| FR-02 | Today view card shows a "Daily Check-In" quick-action button | Should | Given the user has used the Quadrant feature, When the Today view renders, Then a card shows daily check-in status with a one-tap entry button |
| FR-03 | In-the-Moment mode is accessible from the daily check-in mode selector and from any screen via a floating action | Must | Given the user is in a triggering moment, When they tap the in-the-moment shortcut, Then the in-the-moment capture screen opens immediately without navigation overhead |

### 4.2 Scheduled Check-In Mode Flow

The scheduled check-in is the daily routine practice. It follows this sequence:

**Screen 1: Role Context**
- Header: "How are you right now?"
- Role selector: horizontally scrollable chip list of roles (Husband, Father, Employee, Friend, Son, Son of God, Brother, Coach, [Other])
- User selects 1-3 active roles for this moment
- If character intentions are set for a selected role (S1), they display as a brief reminder

**Screen 2: Quadrant Sliders**
- All four quadrants displayed on one screen (not sequential like the weekly flow)
- Each quadrant: name, icon, color, 1-10 slider with anchor labels
- No behavioral indicators (those are weekly only)
- Optional: one-word or emoji descriptor per quadrant (e.g., "foggy", "heavy", "connected", "distant")

**Screen 3: Next Right Thing**
- "Based on where you are right now, what is God calling you to?"
- Three options:
  1. Free-text "I want to..." field (max 140 characters)
  2. Quick-select from suggested actions mapped to the lowest-scoring quadrant
  3. Navigate directly to a related app activity

| ID | Requirement | Priority | Conditions of Satisfaction |
|---|---|---|---|
| FR-04 | Role selector presents at least 8 predefined roles plus "Other" | Must | Given Screen 1 renders, When the user views roles, Then Husband, Father, Employee, Friend, Son, Son of God, Brother, Coach, and Other chips are displayed |
| FR-05 | Quadrant sliders screen shows all four quadrants on one screen | Must | Given Screen 2 renders, When the user views it, Then Body, Mind, Heart, and Spirit sliders are all visible without scrolling on iPhone 13 |
| FR-06 | Slider values update in real time with anchor label display | Must | Given the user drags the Mind slider to 3, When the value updates, Then "Struggling" appears below the slider |
| FR-07 | "Next right thing" screen provides free text, quick select, and navigate-to-activity options | Must | Given Screen 3 renders, Then all three response options are available; user may skip (record nothing) |
| FR-08 | Entry saves with timestamp, roles, four scores, optional descriptors, and optional next right thing | Must | Given the user taps "Save", Then a `RRQuadrantDailyEntry` is created with all captured data and the calendar date |
| FR-09 | If a daily entry already exists for today, the user is taken to edit it rather than create a new one | Must | Given today's entry exists, When the user opens the daily check-in, Then the existing entry's values are pre-populated for editing |

### 4.3 In-the-Moment Mode Flow

In-the-moment mode is designed for urgent capture. It must open fast and close fast.

**Screen 1: Context Capture**
- Header: "What's happening right now?"
- Three quick-select context tags: "In a conversation", "Feeling temptation", "Before something hard", "After a conflict", "Feeling anxious", "Just because"
- Optional: 1-sentence free text "What just happened?" (max 140 characters)

**Screen 2: Quadrant Snapshot (same as scheduled, same single-screen layout)**

**Screen 3: Character Question**
- Not "next right thing" (cognitive task) but "What is God calling you to?" (identity/character question)
- Header: "In this moment, who is God calling you to be?"
- Quick-select options drawn from the user's character intentions if set, otherwise generic: "Present", "Kind", "Honest", "Calm", "Protective", "Tender", "Trusting"
- One-tap selection; no text required
- Optional: "What would that look like right now?" one-sentence field

| ID | Requirement | Priority | Conditions of Satisfaction |
|---|---|---|---|
| FR-10 | In-the-moment mode opens in <= 2 taps from the Work tab or Today view | Must | Given the user is on Work or Today, When they trigger in-the-moment mode, Then the context screen renders within 2 taps |
| FR-11 | Context tags are pre-selected quick-taps; no typing required to complete the mode | Must | Given the user is in crisis/trigger, Then they can complete the entire in-the-moment capture in under 60 seconds without typing |
| FR-12 | "Who is God calling you to be?" screen shows character options (from user's role profile if available, generic otherwise) | Must | Given Screen 3 renders, Then at least 6 character trait quick-selects are shown |
| FR-13 | In-the-moment entry is saved with mode="moment", context tag, four scores, and character selection | Must | Given the user taps "Done", Then the entry saves and the app returns to the previous screen |
| FR-14 | In-the-moment entries are visually distinguished from scheduled entries in the history list | Must | Given the history list renders, Then in-the-moment entries show a distinct indicator (e.g., a lightning bolt icon) |

### 4.4 Role and Character Profile

The roles-and-character framework is the core of the Redemptive Living curriculum. The quadrant is the tool; the role and character are the lens through which it is applied.

| ID | Requirement | Priority | Conditions of Satisfaction |
|---|---|---|---|
| FR-15 | System provides a default set of roles (Husband, Father, Employee, Friend, Son, Son of God, Brother, Coach, Other) | Must | Given the feature is first opened, Then the default roles are available in the selector without user setup |
| FR-16 | User can define character traits they are growing in for each role (C3 -- Could Have) | Could | Given the user taps "Edit Character" for the Husband role, Then a text field allows entering character traits (e.g., "Tender, Pursuing, Transparent") |
| FR-17 | When a role with defined character traits is selected during check-in, the traits display as a brief reminder before the sliders screen | Should | Given the user selects "Husband" and has traits set, Then the traits are shown as a header reminder on the sliders screen |

### 4.5 History and Dashboard Integration

| ID | Requirement | Priority | Conditions of Satisfaction |
|---|---|---|---|
| FR-18 | Quadrant dashboard shows a "Daily Check-Ins" section with the last 7 days of entries | Must | Given the user has daily entries, When the dashboard renders, Then a list of the last 7 days shows each entry with date, roles, four scores (compact), and mode indicator |
| FR-19 | Tapping a history entry opens it in read-only view (today's entry opens in edit mode) | Must | Given the user taps a past entry, Then it opens read-only with all saved data |
| FR-20 | Daily entries appear as micro-markers on the weekly trend chart (Could) | Could | Given 4+ daily entries exist in a given week, When the trend chart renders, Then small dots mark each daily entry date on the chart's x-axis |

### 4.6 Notifications

| ID | Requirement | Priority | Conditions of Satisfaction |
|---|---|---|---|
| FR-21 | Daily check-in notification fires at user-configured time (default 7:00 AM) if no entry exists for today | Should | Given no entry exists for today and it is 7:00 AM, Then a notification: "How are your Mind, Heart, Body, and Spirit today?" is delivered |
| FR-22 | Tapping the notification takes the user directly to the daily check-in entry screen | Should | Given the user taps the notification, Then the scheduled check-in mode opens at Screen 1 |

---

## 5. Non-Functional Requirements

### 5.1 Performance

| ID | Requirement | Target |
|---|---|---|
| NFR-01 | Scheduled check-in: time from tap to first screen | < 400ms |
| NFR-02 | In-the-moment mode: time from trigger to context screen | < 300ms (must feel immediate) |
| NFR-03 | Entry save time | < 150ms |
| NFR-04 | History list load (last 30 days) | < 500ms |

### 5.2 Security and Privacy

| ID | Requirement | Target |
|---|---|---|
| NFR-05 | All daily entries stored locally in SwiftData; no API sync in scope | Architecture-enforced |
| NFR-06 | Daily entries are NOT shared with accountability partners (W3) | Explicitly excluded from sharing model |
| NFR-07 | Daily entries included in full data export (DSR compliance) | Included in existing export pipeline |
| NFR-08 | Biometric lock protects daily entries alongside all other app data | Inherited from app-level biometric gate |

### 5.3 Usability

| ID | Requirement | Target |
|---|---|---|
| NFR-09 | Scheduled mode completes in <= 90 seconds median | Measured by time from first screen open to save |
| NFR-10 | In-the-moment mode completes in <= 60 seconds median | Must not require typing to complete |
| NFR-11 | All quadrant sliders meet minimum touch target size (44x44pt) | Apple HIG compliance |
| NFR-12 | WCAG 2.1 AA contrast on all text | Automated accessibility audit |
| NFR-13 | VoiceOver fully supports both modes | Manual accessibility testing |

---

## 6. Technical Considerations

### 6.1 Data Model (SwiftData)

The daily entry is a separate model from `RRQuadrantAssessment`. Weekly assessments are deliberate reflective summaries; daily entries are moment snapshots. Conflating them would compromise both.

```swift
// MARK: - Daily Quadrant Entry

@Model
final class RRQuadrantDailyEntry {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var entryDate: Date            // Calendar date (day granularity)
    var mode: String               // "scheduled" | "moment"

    // Quadrant scores (1-10)
    var bodyScore: Int
    var mindScore: Int
    var heartScore: Int
    var spiritScore: Int

    // Role context
    var rolesJSON: String          // JSON-encoded [String] of selected role names

    // Optional descriptors (one-word or emoji per quadrant)
    var bodyDescriptor: String?
    var mindDescriptor: String?
    var heartDescriptor: String?
    var spiritDescriptor: String?

    // Scheduled mode: next right thing
    var nextRightThing: String?    // Free text, max 140 chars

    // In-the-moment mode: context and character
    var contextTag: String?        // e.g., "In a conversation", "Feeling temptation"
    var contextNote: String?       // Optional one-sentence, max 140 chars
    var characterSelection: String? // e.g., "Tender"
    var characterNote: String?     // Optional one-sentence, max 140 chars

    // Metadata
    var createdAt: Date
    var modifiedAt: Date
    var needsSync: Bool
}
```

### 6.2 Role Model

Roles are user-defined strings. The system provides defaults; the user can add custom roles (C3). Character traits per role are stored as a simple JSON string array.

```swift
// MARK: - User Role Profile (Could Have -- C3)

@Model
final class RRUserRole {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var roleName: String           // e.g., "Husband"
    var isDefault: Bool            // true for system-provided defaults
    var characterTraitsJSON: String // JSON-encoded [String], e.g., ["Tender", "Pursuing"]
    var sortOrder: Int
    var createdAt: Date
}
```

Default roles (system-provided, `isDefault = true`):
- Son of God
- Husband
- Father
- Employee
- Friend
- Son
- Brother
- Coach

### 6.3 Mode Differentiation

The two modes share the same `RRQuadrantDailyEntry` model. The `mode` field distinguishes them:

| Field | Scheduled ("scheduled") | In-the-Moment ("moment") |
|---|---|---|
| `contextTag` | nil | required |
| `contextNote` | nil | optional |
| `nextRightThing` | optional | nil |
| `characterSelection` | nil | optional |
| `characterNote` | nil | optional |

### 6.4 Relationship to Weekly Assessment

Daily entries do NOT replace or auto-populate the weekly assessment. The weekly assessment is always a deliberate manual entry. The relationship is read-only: the weekly dashboard can display daily entries as context anchors, and the weekly assessment flow can optionally show "You had 4 daily check-ins this week -- here's your average scores" as a starting reference (not pre-populated).

### 6.5 Integration Points

| Integration | Mechanism | Scope |
|---|---|---|
| Quadrant dashboard | Daily entries section shows last 7 days | Must (FR-18) |
| Today view | Card with daily check-in status and quick-action | Should (S5) |
| Activity navigation | "Next right thing" → deep link to activity | Must (FR-07) |
| Weekly trend chart | Daily entry micro-markers on x-axis | Could (FR-20) |
| Notifications | Daily local notification via `PlanNotificationScheduler` | Should (FR-21) |
| Feature flag | `feature.quadrant.daily` gates the daily feature independently from weekly | Must |

### 6.6 Feature Flag Dependency

`feature.quadrant.daily` requires `feature.quadrant` to be enabled. If `feature.quadrant` is off, the daily check-in is never shown regardless of `feature.quadrant.daily` state. The daily entry point on the Quadrant dashboard only renders when both flags are enabled.

---

## 7. User Stories

### Story 1: Scheduled Daily Check-In

**As a** recovering person building a daily self-awareness habit,
**I want** to do a quick 3-slider, role-anchored check-in each morning,
**So that** I stay connected to how my Body, Mind, Heart, and Spirit are doing day by day -- not just week by week.

**Priority:** Must (M1, M2)
**Story Points:** 8

**Conditions of Satisfaction:**
- Given I open the daily check-in, When Screen 1 loads, Then I see a role selector with at least 8 role chips
- Given I select "Husband" and "Employee", When I tap Next, Then Screen 2 shows all four quadrant sliders on one screen with my selected roles displayed as context
- Given I set Body=7, Mind=5, Heart=8, Spirit=6, When I tap Next, Then the "next right thing" screen appears with quick-select suggestions based on my lowest score (Mind=5 → "Journaling", "Step Work")
- Given I tap "Save", Then a `RRQuadrantDailyEntry` is created with mode="scheduled", today's date, two roles, and four scores
- Given today's entry already exists, When I open the daily check-in, Then my existing values are pre-populated for editing

---

### Story 2: In-the-Moment Capture

**As a** recovering person in a triggering situation,
**I want** to capture what is happening in my Mind, Heart, Body, and Spirit right now and identify who God is calling me to be in this moment,
**So that** I interrupt the pattern before it escalates and orient toward the next right action.

**Priority:** Must (M3)
**Story Points:** 5

**Conditions of Satisfaction:**
- Given I tap the in-the-moment button from the Work tab, When the screen opens, Then I see context tags immediately (no loading state)
- Given I tap "In a conversation", When I advance to sliders, Then all four sliders are pre-set to 5 (neutral) for quick adjustment
- Given I set Spirit=3, When I reach Screen 3, Then "Who is God calling you to be?" displays with character options including "Present", "Kind", "Calm", "Tender"
- Given I tap "Tender" and tap "Done", Then the entry saves with mode="moment", contextTag="In a conversation", and characterSelection="Tender" in under 60 seconds
- Given the entry saves, Then I am returned to the screen I came from without additional navigation

---

### Story 3: Role and Character Context

**As a** recovering person who wants to anchor my daily check-in to the character God is growing in me,
**I want** to see my character intentions for the roles I'm currently in when I start my check-in,
**So that** the check-in is connected to the man I'm becoming, not just a data capture exercise.

**Priority:** Should (S1)
**Story Points:** 3

**Conditions of Satisfaction:**
- Given I have set character traits "Tender, Pursuing, Transparent" for the Husband role, When I select "Husband" in the daily check-in, Then those traits appear as a brief header reminder before the sliders screen
- Given I have no character traits set for a role, When I select that role, Then no reminder is shown (graceful degradation)
- Given character traits are displayed, When I view the "next right thing" or character screen, Then the quick-select options are drawn from my character traits for that role rather than generic defaults

---

### Story 4: History and Dashboard Integration

**As a** recovering person reviewing my recovery data,
**I want** to see my recent daily check-ins on the Quadrant dashboard alongside my weekly trend,
**So that** I can see which individual days drove my weekly scores.

**Priority:** Must (M7, FR-18)
**Story Points:** 3

**Conditions of Satisfaction:**
- Given I have 5 daily entries this week, When the Quadrant dashboard renders, Then a "Daily Check-Ins" section shows all 5 entries with date, roles, and four scores in a compact card format
- Given I tap a past entry, Then it opens read-only with all saved fields visible
- Given today's entry exists, When I tap it from the history list, Then it opens in edit mode
- Given I have an in-the-moment entry, When it displays in the history list, Then a lightning bolt icon distinguishes it from scheduled entries

---

### Story 5: Today View Integration

**As a** recovering person using the Today view as my daily hub,
**I want** to see my daily check-in status and access it in one tap,
**So that** the daily check-in is integrated into my existing daily routine.

**Priority:** Should (S5)
**Story Points:** 2

**Conditions of Satisfaction:**
- Given I have not completed today's check-in, When the Today view renders, Then a card shows "Daily Check-In" with a "Check in now" button
- Given I have completed today's check-in, When the Today view renders, Then the card shows today's four scores and "View" instead of the prompt
- Given I have never used the daily check-in feature, When the Today view renders, Then no daily check-in card appears

---

### Story Point Summary

| Story | Title | Points | Priority | Sprint |
|---|---|---|---|---|
| S1 | Scheduled Daily Check-In | 8 | Must | 1 |
| S2 | In-the-Moment Capture | 5 | Must | 1 |
| S3 | Role and Character Context | 3 | Should | 1 |
| S4 | History and Dashboard Integration | 3 | Must | 2 |
| S5 | Today View Integration | 2 | Should | 2 |
| **Total** | | **21** | | |

---

## 8. Implementation Roadmap

### Sprint 1: Core Check-In Modes

**Sprint Goal:** Users can complete both a scheduled daily check-in and an in-the-moment capture with role context and character prompts.

**Stories:** S1 (8 pts), S2 (5 pts), S3 (3 pts)
**Total Points:** 16

**Deliverables:**
- `RRQuadrantDailyEntry` SwiftData model
- `RRUserRole` model (default roles only; character trait editing is C3, deferred)
- Scheduled check-in flow: Role selector → Sliders → Next Right Thing
- In-the-moment flow: Context tags → Sliders → Character question
- Feature flag `feature.quadrant.daily` gating
- Daily notification (scheduled mode only, default 7:00 AM)

### Sprint 2: Dashboard Integration + Polish

**Sprint Goal:** Daily entries are visible on the Quadrant dashboard and Today view; history is browsable.

**Stories:** S4 (3 pts), S5 (2 pts) + notification polish, character profile setup
**Total Points:** 8 + integration

**Deliverables:**
- "Daily Check-Ins" section on Quadrant dashboard (last 7 days)
- Today view card with quick-action
- Read-only history entry viewer
- Notification: daily reminder with completion check

---

## 9. Open Questions and Risks

### Open Questions

| # | Question | Impact | Status |
|---|---|---|---|
| OQ-1 | Should in-the-moment entries count toward the daily streak, or only scheduled entries? | Affects streak logic (C2) and OMTM measurement | Open |
| OQ-2 | Should the "next right thing" from a daily check-in be trackable (did the user actually follow through)? | Affects FR-07 and FR-22 success metric | Open |
| OQ-3 | How many roles should a user be able to create beyond the 8 defaults? | Affects C3 implementation scope | Open |
| OQ-4 | Should the daily check-in have its own onboarding/psychoeducation screen, or rely on the weekly quadrant's psychoeducation? | Affects Sprint 1 scope | Open |
| OQ-5 | Should daily entries from the same day but different modes (one scheduled, one moment) both be stored, or should a day be limited to one entry? | Affects FR-09 and data model | Open -- leaning toward allowing both (moment entries are distinct events) |

### Risks

| # | Risk | Probability | Impact | Mitigation |
|---|---|---|---|---|
| R-1 | Daily fatigue: users who already do LBI daily find three daily tools too many | Medium | High | Differentiate clearly: LBI = behavioral tracking (what happened), Daily Quadrant = self-awareness (how I am). Keep daily check-in under 90 seconds |
| R-2 | In-the-moment mode feels intrusive or performative rather than genuinely helpful | Medium | Medium | Keep Screen 1 to context tags only (no required typing); make the character question feel like an invitation, not an assignment |
| R-3 | Character trait feature (S1, C3) adds significant complexity and may delay Sprint 1 | Medium | Medium | Launch S1 without character traits if needed; graceful degradation to generic options. C3 explicitly deferred to Could |
| R-4 | Users skip "next right thing" entirely, making scheduled mode feel like a data dump | Medium | Low | Design the screen as a moment of reflection, not a required field; add subtle copy: "What's one thing you could do for your [lowest quadrant] today?" |
| R-5 | Daily entry history becomes overwhelming (30+ entries) | Low | Low | History shows last 7 days by default; full history available behind "Show more" |

---

## 10. Design Decisions Log

### D1: Separate Model from Weekly Assessment

**Chosen:** `RRQuadrantDailyEntry` is a distinct SwiftData model from `RRQuadrantAssessment`.

**Rationale:** Daily entries are moment snapshots (what am I right now?) while weekly assessments are reflective summaries (how was my week?). Conflating them would require either downgrading the weekly assessment (losing behavioral indicators, reflections, imbalance scoring) or overloading daily entries with weekly-level complexity. Separation keeps both tools clean and purpose-fit.

### D2: Single-Screen Sliders vs. Sequential Quadrant Screens

**Chosen:** All four sliders on one screen (not sequential like the weekly flow).

**Rationale:** The weekly flow uses sequential screens because each screen includes a scripture verse, 5 behavioral indicators, and an optional reflection -- each screen has content that justifies its own space. The daily check-in has only sliders and optional one-word descriptors -- putting each on its own screen would add unnecessary navigation steps and extend completion time beyond the 90-second target.

### D3: Two Distinct Modes vs. One Flexible Entry

**Chosen:** Two named modes (Scheduled, In-the-Moment) with different flows.

**Rationale:** The curriculum makes a clear distinction between "planned quadrant work" (routine, character-growth-focused) and "real-time quadrant work" (triggered, crisis-interrupt-focused). The final questions differ meaningfully: "What's the next right thing?" (cognitive planning) vs. "Who is God calling you to be?" (identity/character grounding). A single mode would force a compromise that weakens both use cases.

### D4: Character Traits Not Required for Launch

**Chosen:** Character trait display and editing (S1/C3) is Should/Could -- graceful degradation to generic character options if not set up.

**Rationale:** Requiring users to set up character traits per role before the daily check-in is useful creates an onboarding barrier. The tool must work out of the box with default roles and generic character options. Character trait customization is a power-user feature that deepens the practice for engaged users.

### D5: Daily Entries Not Shared with Accountability Partners

**Chosen:** Daily entries are never shared (W3).

**Rationale:** The in-the-moment mode captures users in their most vulnerable states -- mid-conflict, mid-temptation, mid-crisis. These entries must be completely private to be genuinely honest. Accountability partners receive sufficient signal from weekly quadrant scores. The daily entries' value is in the user's own awareness, not in external accountability.

---

## Appendix A: Daily Check-In Content Reference

### Default Role List

| Role | Display Name |
|---|---|
| son_of_god | Son of God |
| husband | Husband |
| father | Father |
| employee | Employee |
| friend | Friend |
| son | Son |
| brother | Brother |
| coach | Coach |

### Context Tags (In-the-Moment Mode)

| Tag Key | Display Label |
|---|---|
| in_conversation | In a conversation |
| feeling_temptation | Feeling temptation |
| before_hard | Before something hard |
| after_conflict | After a conflict |
| feeling_anxious | Feeling anxious |
| just_because | Just because |

### Generic Character Options (When No Role Profile Set)

Present, Kind, Honest, Calm, Protective, Tender, Trusting, Patient, Humble, Courageous

### Quick-Select Activity Mapping (Next Right Thing)

Same as Weekly Quadrant Review recommendation mapping:

| Lowest Quadrant | Suggested Activities |
|---|---|
| Body | Exercise, Nutrition Check-in |
| Mind | Journaling, Step Work |
| Heart | Phone Calls, FANOS Check-in |
| Spirit | Prayer, Declarations of Truth |
