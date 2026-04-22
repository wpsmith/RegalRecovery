# Bowtie Diagram -- Functional Requirements Document

**Feature name:** Bowtie Diagram (Emotional Self-Awareness Activity)
**Document type:** Functional Requirements Document (FRD)
**Date:** 2026-04-22
**Version:** 1.0
**Author:** Product
**Platform:** iOS (SwiftUI + SwiftData)
**Tiers:** Free (core) / Standard (analytics + history) / Premium+ (AI pattern detection)
**Feature Flag:** `activity.bowtie`
**Wave:** Wave 2
**OMTM:** Anticipatory ratio growth -- increasing percentage of future-side markers relative to total markers over 90 days (measures shift from reactive to proactive emotional management)

> *CLINICAL NOTICE: The Bowtie Diagram is a self-intimacy and emotional awareness tool developed by Redemptive Living Academy. It is not a substitute for professional treatment, pastoral counseling, or group accountability. Content and clinical framing require review by a CSAT and pastoral advisor before release.*

---

## 1. Feature Overview

### 1.1 Problem Statement

The addictive cycle does not begin with acting out. It begins with unprocessed emotional wounds -- subtle, accumulating activations of core shame that go unrecognized until they reach a threshold where the addiction promises relief. The clinical insight from Redemptive Living Academy's work is unambiguous: **acting out is never random.** Every relapse, every destructive outburst, every medicating behavior is informed by emotional activations that accumulated in the hours and days preceding it.

These activations are often subtle -- a dismissive comment from a boss, a spouse needing space at a school event, a neighbor's garbage can left in the driveway, a child walking past without speaking. None of these events are catastrophic in isolation. But they compound. Each one taps into core emotional wounds -- insignificance ("Do I matter?"), incompetence ("Do I have what it takes?"), impotence ("Do I have any control?") -- and when multiple wounds go unprocessed, they create an emotional deficit that the addictive cycle promises to fill.

**The cost of the problem is twofold:**

1. **Pattern blindness.** Without a structured framework for examining what happened before a relapse, users experience relapses as unpredictable, which produces shame ("I don't know what happened") rather than understanding ("I can see the six things that were building up"). Pattern blindness makes each relapse feel like proof of personal failure rather than decodable information.

2. **Reactive living.** Without a proactive framework for anticipating emotional wounds, users enter high-risk situations unprepared -- already operating at an emotional deficit from unprocessed wounds of the previous days. A person who has anticipated and prepared for an emotional wound handles an unexpected additional wound far better than someone already depleted. The absence of anticipatory emotional management is itself a risk factor.

Existing recovery apps offer no structured, multi-layer emotional inventory tool. Check-ins capture mood snapshots; journals capture narrative; FASTER Scale captures relapse trajectory. None of these capture the specific, role-layered, temporally-mapped accumulation of emotional wounds that precedes the trigger stage of the addictive cycle. The Bowtie fills this gap.

### 1.2 Business Hypothesis

By providing a structured, role-layered emotional inventory tool with dual-temporal analysis and actionable processing through the Backbone/Life Situations framework, Regal Recovery can help users develop **emotional self-intimacy** -- the capacity to identify what is stirring in their heart, connect surface emotions to core wounds, name their valid emotional needs, and pursue meeting those needs through true intimacy rather than cycles of destruction.

**Expected OMTM impact:** Among users who complete at least one Bowtie per week for 90 days, the ratio of future-side markers to total markers will increase from an initial baseline of <30% to >50%, indicating a measurable shift from reactive emotional processing to proactive anticipatory living.

### 1.3 Value Proposition

The Bowtie reframes post-relapse analysis from vague shame into specific, decodable data, and reframes the future from unpredictable threat into an anticipatable, preparable landscape.

**For users in early recovery (0-90 days):** Learn to see what's stirring beneath the surface. The guided mode teaches the transparency-layering methodology one role at a time. Big Ticket Emotions (Abandonment, Loneliness, Rejection, Sorrow, Neglect) provide an accessible entry point for users not yet comfortable with Three I's vocabulary. The first Bowtie often produces the revelation: "I can actually see what was building up. It wasn't random."

**For users in mid recovery (90-365 days):** Develop anticipatory living. Weekly Bowties shift the balance from analyzing past relapses to preparing for upcoming challenges. The Prayer-People-Plan framework translates emotional awareness into concrete behavioral preparation.

**For users in established recovery (365+ days):** Refine emotional granularity. Full role-layered analysis with Backbone processing becomes a weekly self-intimacy practice. The longitudinal data reveals which life domains carry the most emotional weight and how the anticipatory-to-retroactive ratio is growing.

**For accountability relationships:** Concrete Bowtie data transforms accountability conversations from "How are you doing?" / "Fine" into specific discussion: "Your incompetence was high this week, mostly in your coworker role. What's going on with your boss?"

### 1.4 Clinical Foundation

The Bowtie Diagram was developed by Redemptive Living Academy as a structured self-awareness tool for addiction recovery. Its clinical foundations include:

| Concept | Description | Bowtie Application |
|---------|-------------|---------------------|
| **Three I's** (Redemptive Living) | Three core emotional wounds that ignite shame cycles: Insignificance ("Do I matter?"), Incompetence ("Do I have what it takes?"), Impotence ("Do I have any control?") | Primary analytical lens for identifying which wounds were activated at each time interval. Every activation marker codes to one or more I's. |
| **Addictive Cycle** (Carnes/Dye) | Triggers -> Preoccupation -> Rituals -> Acting Out -> Guilt/Shame -> repeat. Same triggers also spawn the Acting In cycle. | The Bowtie reveals what feeds the trigger stage. The Three I's and known emotional triggers are the raw material of triggers. |
| **Big Ticket Emotions** (Redemptive Living) | Five common emotions that lead to acting out, acting in, or medicating: Abandonment, Loneliness, Rejection, Sorrow, Neglect | Accessible entry vocabulary for users new to recovery who have not yet internalized the Three I's framework. Maps internally to the Three I's for longitudinal analytics. |
| **Backbone/Life Situations** (Redemptive Living) | Four-level processing framework: Life Situation -> Emotions -> Three I's -> Emotional Needs | The processing step after Bowtie plotting. Moves the user from awareness ("I can see it") to action ("I know what I need"). |
| **Emotional Needs** (Redemptive Living) | 20 valid emotional needs: Acceptance, Affirmation, Agency, Belonging, Comfort, Compassion, Connection, Empathy, Encouragement, Forgiveness, Grace, Hope, Love, Peace, Reassurance, Respect, Safety, Security, Understanding, Validation | The vocabulary for what the user actually needs -- the alternative to what the addiction promises. |
| **True Intimacy** (Redemptive Living) | Three channels of genuine need-meeting: Intimacy with God, Intimacy with Self, Intimacy with Appropriate Others | The resolution step. The Bowtie always points toward intimacy as the antidote to cycles of destruction. |
| **Prayer-People-Plan** (Redemptive Living) | Three-part anticipatory preparation framework: what will I pray, who will I call, what is my concrete plan (before, during, after) | The practical output of the anticipatory (future-side) Bowtie. Translates emotional awareness into behavioral preparation. |
| **Overhead Projector Metaphor** (Redemptive Living) | Roles as transparency layers stacked on the base Bowtie -- each role is a lens that reveals activations invisible when looking at life generically | The mechanism for getting granular. A wound felt as "Father" is different from the same wound felt as "Coworker." Role-by-role analysis catches activations that a generic review misses. |

### 1.5 Design Principles

1. **Self-intimacy is the goal.** The Bowtie is not a diagnostic or a scorecard. It is a practice of connecting with your own heart. Every design decision supports honest self-examination, not performance.
2. **Nothing is too small.** A neighbor's garbage can, a child walking past without speaking, a driver cutting you off -- these "innocuous" activations matter. The UX must never dismiss or minimize small-seeming events.
3. **Responsibility, not blame.** "I feel rejected" is different from "She made me feel rejected." The Bowtie helps users own their emotional experience without blaming others. The issue is not whether someone caused the feeling -- the issue is learning to deal with what you feel.
4. **Numbers are informative, not magical.** The intensity scores and Three I's tallies are a barometer, not a grade. There is no passing score. The numbers reveal where the emotional weight is concentrated.
5. **Compassion in code.** A Bowtie completed after acting out is not a punishment. It is a learning exercise. The tone must reflect this throughout.
6. **Depth on demand.** Quick Bowtie for daily self-check (5-10 minutes); full Bowtie with Backbone processing for deep work (20-40 minutes). Never require depth; always offer it.
7. **Anticipatory living is the destination.** Retroactive Bowties are valuable, but the long-term recovery skill is living from the right side of the Bowtie -- anticipating, preparing, and entering situations with emotional reserves intact.

---

## 2. User Personas

### 2.1 Primary Personas

| Persona | Profile | Recovery Stage | Key Bowtie Needs |
|---------|---------|----------------|------------------|
| **Alex** | 34, married, 45 days sober. Celebrate Recovery attendee. Evangelical. Uses app daily. | Early-to-mid recovery | Learn the tool with guided mode; retroactive Bowtie after urge spikes; start recognizing which I's get hit most. Needs the transparency-layer concept taught step by step. |
| **Marcus** | 28, single, 7 days sober. Post-relapse. Deep shame. New to recovery vocabulary. | Early recovery / post-relapse | Compassionate retroactive Bowtie to understand "how did I get here" without shame; Big Ticket Emotions entry point (Three I's not yet accessible); may skip future side entirely and that is okay. |
| **Diego** | 42, married, 200 days sober. Small group leader. Deep recovery vocabulary. | Established recovery | Full anticipatory Bowtie with role layering; weekly Sunday-evening practice; Backbone processing for unresolved points; PPP for the week ahead. His anticipatory ratio is growing. |
| **Sarah** | 31, single woman, 90 days sober. Attends SA. Trauma history. | Mid recovery | Gentle entry; may not relate to "roles" framing initially; emphasis on self-intimacy and emotional needs vocabulary; spiritual lens optional, never assumed. |

### 2.2 Anti-Personas

| Anti-Persona | Why They Are Not Served |
|---|---|
| **Casual self-help user** | The Bowtie requires familiarity with recovery concepts (Three I's, emotional wounds, addictive cycles). Without this context, the tool is confusing rather than helpful. |
| **User seeking quick fix** | The Bowtie is reflective work that takes time. It is not a crisis intervention tool (that is SOS mode / Affirmations). Users in acute crisis should be routed to emergency resources, not a 20-minute self-awareness exercise. |

---

## 3. Functional Requirements

### 3.1 Bowtie Session Lifecycle

#### FR-BT-001: Session Creation

The system shall allow the user to create a new Bowtie Diagram session from multiple entry points.

**Conditions of Satisfaction:**

- Given the Bowtie feature flag `activity.bowtie` is enabled, When a user navigates to the Activities section, Then "Bowtie Diagram" appears as an available activity.
- Given a user taps "Bowtie Diagram" from Activities, When no draft Bowtie exists, Then a new Bowtie session is created with "Now" defaulting to the current date/time.
- Given a user taps "Bowtie Diagram" from Activities, When a draft Bowtie exists, Then the user is presented with options: "Continue draft" or "Start new." Only one draft may exist at a time.
- Given a user has logged a sobriety reset (relapse event), When the post-reset flow completes, Then a contextual card appears: "Understanding what happened starts with knowing what was going on inside you. A Bowtie Diagram can help." Tapping creates a new Bowtie with "Now" pre-set to the relapse event timestamp.
- Given a user has completed a FASTER Scale check-in at "Speeding Up" or beyond, When the results screen displays, Then a non-blocking suggestion appears: "Your FASTER Scale is showing drift. A Bowtie can help you see what's building." Tapping opens a new Bowtie with "Now" as current time.
- Given a user completes an evening review or check-in that surfaces emotional activation, When the review concludes, Then an optional prompt appears: "Would you like to examine this further with a Bowtie?" Tapping opens a new Bowtie.

**Priority:** P0 -- Must Have

---

#### FR-BT-002: Reference Timestamp ("Now" Point)

Each Bowtie session shall have a "Now" reference point that anchors the temporal analysis.

**Conditions of Satisfaction:**

- Given a new Bowtie session is created from the Activities section, When the session initializes, Then "Now" defaults to the current date/time.
- Given a new Bowtie session is created from a post-relapse prompt, When the session initializes, Then "Now" is pre-set to the relapse event timestamp. The user can see and modify this before proceeding.
- Given a Bowtie session exists, When the user views or edits the session, Then the "Now" timestamp is displayed prominently as the anchor point. The user can adjust "Now" to any past timestamp (e.g., the moment of an acting-in event, a medicating episode, or any other ground-zero moment they want to analyze).
- Given "Now" is set to a past timestamp, When the Past and Future sides are calculated, Then the Past side represents the 48 hours before "Now" and the Future side represents the 48 hours after "Now" (which may also be in the past relative to the current moment).

**Priority:** P0 -- Must Have

**Clinical Rationale:** Retroactive Bowties require anchoring "Now" to the event being analyzed, not the current clock time. A user analyzing a relapse that happened at 5 PM yesterday needs "Now" at 5 PM yesterday so the 48-hour window correctly frames what led up to and followed the event.

---

#### FR-BT-003: Session Status and Draft Management

Each Bowtie session shall have a lifecycle status supporting interruption and resumption.

**Conditions of Satisfaction:**

- Given a Bowtie session is created, When the user begins adding data, Then the session status is `draft`.
- Given a Bowtie session is in `draft` status, When the user navigates away or the app is backgrounded/terminated, Then all data is preserved via auto-save. The session remains in `draft` status.
- Given a draft Bowtie session exists, When the user returns to the Bowtie feature, Then a "Continue" affordance is displayed prominently on the Activities screen, showing the session date and "Now" reference.
- Given a Bowtie session is in `draft` status, When the user taps "Complete Bowtie," Then the status changes to `complete`, a completion timestamp is recorded, and a rotating completion message is displayed (see Section 10.4).
- Given a Bowtie session is `complete`, When the user views it from history, Then the session opens in read-only mode with an option to "Process unaddressed markers" (which does not create a new session but allows additional Backbone processing on existing markers).
- Given a user has a `draft` Bowtie session, When they attempt to create a new session, Then they are prompted to either continue the draft or discard it. Only one draft may exist at a time to prevent abandoned sessions from accumulating.

**Priority:** P0 -- Must Have

---

#### FR-BT-004: Auto-Save

The system shall auto-save all Bowtie data to local storage on every change.

**Conditions of Satisfaction:**

- Given a user is working on a Bowtie session, When any change occurs (marker added, marker edited, Backbone step completed, PPP entry added, role selection changed), Then the change is persisted to SwiftData within 100ms.
- Given a user is working on a Bowtie session, When the app is terminated by the system or by the user, Then zero data loss occurs. The session resumes exactly where it was left off.
- Given a user is working on a Bowtie session offline, When changes are auto-saved, Then all data is persisted locally with `syncStatus: pending`. When connectivity returns, the SyncEngine queues the session for server sync.

**Priority:** P0 -- Must Have

**Rationale:** Data loss during vulnerable emotional work would be deeply harmful to user trust. The Bowtie may take 20-40 minutes of deeply personal reflection. Losing that work is unacceptable.

---

#### FR-BT-005: Session History

The system shall store completed Bowties viewable as a chronological history.

**Conditions of Satisfaction:**

- Given the user navigates to Bowtie history, When completed sessions exist, Then a reverse-chronological list displays: date, "Now" reference timestamp, roles examined, Past tallies (Insignificance X, Incompetence Y, Impotence Z), Future tallies (same), number of markers processed through Backbone, and completion status.
- Given a user taps a completed Bowtie in history, When the session opens, Then the full Bowtie is displayed in read-only mode with all markers, processing, and PPP entries visible.
- Given no completed Bowties exist, When the user navigates to history, Then an empty state is displayed: "Your Bowtie history will appear here as you complete sessions. Each one builds your understanding of yourself."

**Priority:** P0 -- Must Have

---

#### FR-BT-006: Session Deletion

The system shall allow the user to delete individual Bowtie sessions.

**Conditions of Satisfaction:**

- Given a user views a completed or draft Bowtie, When they select "Delete," Then a single confirmation dialog appears: "Delete this Bowtie? All markers, processing, and plans will be permanently removed." On confirm, the session and all associated data (markers, Backbone processing, PPP entries) are permanently deleted.
- Given a Bowtie session is deleted, When the deletion completes, Then the session is removed from local storage immediately and from remote storage within 24 hours.
- Given a Bowtie session has associated calendar activity entries, When the session is deleted, Then the associated calendar activity entry is also deleted.

**Priority:** P0 -- Must Have

---

### 3.2 Role Configuration and Selection

#### FR-BT-010: Personal Role List

The system shall maintain a persistent personal role list configurable across sessions.

**Conditions of Satisfaction:**

- Given a user opens the Bowtie feature for the first time, When the role configuration step is reached (during onboarding or first session), Then a pre-populated suggestions list is displayed: Christian/Person of Faith, Husband/Wife/Partner, Father/Mother/Parent, Son/Daughter, Brother/Sister/Sibling, Friend, Man/Woman in Recovery, Coworker/Employee, Neighbor, Coach/Mentor, Church Member, Student.
- Given a user views the role suggestions, When they select roles, Then selected roles are added to their personal role list. The suggestions are gender-inclusive; the user selects the labels that match their life.
- Given a user has a personal role list, When they add a custom role, Then the custom role is saved with a user-defined label and appears alongside the pre-populated selections.
- Given a user has a personal role list, When they edit a role label, Then the label is updated across all future sessions. Historical sessions retain the label as it was at the time of the session.
- Given a user no longer occupies a role, When they archive the role, Then it is hidden from the selection list for new sessions but remains visible on historical Bowties that used it. Archived roles are recoverable from a "Show archived" option.
- Given a user has roles in their personal list, When they reorder the roles, Then the new order persists and is used as the default display order in future sessions.
- Given the role configuration is complete, When roles are saved, Then they persist across Bowtie sessions and are available immediately for future sessions.

**Priority:** P0 -- Must Have

**Clinical Rationale:** Roles are the foundational "transparency layers" of the Bowtie -- the overhead projector metaphor from the source material. Each role is a lens that reveals activations invisible when looking at life generically. A wound felt as "Father" is emotionally distinct from the same wound felt as "Coworker." The role list must be reusable because users return to the same roles across sessions, and the analytical value of seeing patterns per role requires consistent role identity over time.

---

#### FR-BT-011: Session Role Selection

At the start of each Bowtie session, the user shall select which roles to examine.

**Conditions of Satisfaction:**

- Given a user starts a new Bowtie session, When the role selection step is presented, Then all roles from their personal list are displayed. The user toggles which roles to examine in this session.
- Given a user is selecting roles, When at least 1 role is selected, Then the "Continue" action becomes enabled. There is no maximum.
- Given a user selects 2-3 roles, When they proceed, Then the session is configured for a focused Bowtie (daily self-check). Given 6-8 roles, the session supports a comprehensive weekly Bowtie. The system does not limit or recommend a count.

**Priority:** P0 -- Must Have

---

### 3.3 Emotion Vocabulary Configuration

#### FR-BT-020: Emotion Vocabulary Mode

The system shall support three emotion vocabulary modes for activation markers.

**Conditions of Satisfaction:**

- Given a user configures Bowtie settings, When they select an emotion vocabulary mode, Then the following options are available: **Three I's mode** (Insignificance, Incompetence, Impotence), **Big Ticket Emotions mode** (Abandonment, Loneliness, Rejection, Sorrow, Neglect), **Combined mode** (both vocabularies presented together).
- Given the user is in Three I's mode, When they add an activation marker, Then the I selector displays three options with their diagnostic questions: Insignificance -- "Do I matter?", Incompetence -- "Do I have what it takes?", Impotence -- "Do I have any control?" Each selected I receives an individual intensity rating (1-10).
- Given the user is in Big Ticket Emotions mode, When they add an activation marker, Then the emotion selector displays five options: Abandonment, Loneliness, Rejection, Sorrow, Neglect. Each selected emotion receives an individual intensity rating (1-10). Tallies are shown per emotion rather than per I.
- Given the user is in Combined mode, When they add an activation marker, Then both the Three I's and Big Ticket Emotions are presented. The user selects from either or both vocabularies.
- Given a user is in Big Ticket Emotions mode, When activation data is stored, Then the system internally tracks a mapping between Big Ticket Emotions and Three I's (e.g., Rejection maps primarily to Insignificance) for analytics consistency. This mapping is configurable per user (see FR-BT-021).
- Given a new user completes their first Bowtie session, When the session uses Big Ticket Emotions mode, Then after the third completed session, the system suggests: "You've been building your emotional vocabulary. Would you like to explore the Three I's? They go deeper into the wounds beneath emotions like Rejection and Loneliness." The suggestion is dismissible and non-recurring for 30 days.

**Priority:** P0 -- Must Have (Three I's and Big Ticket modes); P1 -- Should Have (Combined mode)

**Clinical Rationale:** From the MBR transcript: "For some of us, especially folks that are new in recovery or new in feelings and emotions, we don't walk around saying 'gosh, I feel so insignificant.' Instead, we might feel things like abandonment, neglect, rejection." Big Ticket Emotions provide the accessible on-ramp; the Three I's provide the clinical depth. The progression from Big Ticket to Three I's mirrors the recovery vocabulary development that happens naturally over months of group work.

---

#### FR-BT-021: Big Ticket Emotion to Three I's Mapping

The system shall maintain a mapping between Big Ticket Emotions and the Three I's.

**Conditions of Satisfaction:**

- Given the system stores Big Ticket Emotion activation data, When analytics are computed, Then the following default mapping is applied: Abandonment -> Insignificance, Loneliness -> Insignificance, Rejection -> Insignificance, Sorrow -> Incompetence, Neglect -> Insignificance.
- Given the default mapping exists, When a user views Bowtie analytics in Three I's terms, Then Big Ticket Emotion data from earlier sessions is included via the mapping, providing a continuous analytical baseline even when the user transitions vocabulary modes.
- Given a user wants to customize the mapping, When they navigate to Bowtie settings, Then they can reassign any Big Ticket Emotion to a different primary I. Custom mappings are stored per user.

**Priority:** P1 -- Should Have

---

#### FR-BT-022: Custom Emotion Labels

The system shall support user-defined emotion labels.

**Conditions of Satisfaction:**

- Given a user navigates to Bowtie settings, When they access the custom emotions option, Then they can create up to 10 personal emotion labels (e.g., "being controlled," "feeling stupid," "being overlooked").
- Given custom emotions exist, When the user adds an activation marker, Then custom emotions appear alongside the selected vocabulary mode (Three I's or Big Ticket Emotions).
- Given a user creates a custom emotion, When they are prompted, Then they can optionally map it to a primary I for analytics consistency.

**Priority:** P2 -- Could Have

---

### 3.4 Activation Plotting

#### FR-BT-030: Bowtie Diagram Layout

The system shall render the Bowtie as two triangular regions meeting at a center point.

**Conditions of Satisfaction:**

- Given a Bowtie session is active, When the diagram is rendered, Then two triangular regions are displayed meeting at a center point labeled "Now." The left triangle represents the Past 48 hours; the right triangle represents the Future 48 hours.
- Given the diagram is rendered, When time interval markers are displayed, Then they appear at 1h, 3h, 6h, 12h, 24h, 36h, and 48h from center on each side. These intervals serve as placement guides; the intervals are not absolute (a marker placed at "6h" represents "approximately 6 hours from Now").
- Given the diagram is displayed on an iPhone SE-sized screen, When the visual becomes too compressed, Then the system gracefully degrades: labels abbreviate, and a list-based entry mode is offered as the primary interaction.

**Priority:** P0 -- Must Have

---

#### FR-BT-031: Activation Marker Creation

The user shall be able to place activation markers on either triangle.

**Conditions of Satisfaction:**

- Given a Bowtie session is active, When a user adds an activation marker, Then the marker captures: (a) side (past or future), (b) approximate time interval (1h, 3h, 6h, 12h, 24h, 36h, or 48h from "Now"), (c) which I's or Big Ticket Emotions are activated (one or more), (d) intensity per selected I/emotion (1-10 scale), (e) the role this activation is experienced in (from the session's selected roles), (f) optional brief description (max 280 characters).
- Given a user taps a time interval column on the diagram, When the marker creation sheet opens, Then the role, I/emotion, intensity, and description fields are presented. All fields except role and at least one I/emotion are optional.
- Given a user has created a marker, When the marker is saved, Then it appears on the diagram at the appropriate time interval, visually coded by which I is activated (see FR-BT-033).
- Given a user adds multiple markers at the same time interval, When the markers are displayed, Then all markers are visible (stacked, grouped, or numbered) without obscuring each other.

**Priority:** P0 -- Must Have

---

#### FR-BT-032: List-Based Entry Mode

The system shall support a list-based entry mode as an alternative to visual diagram interaction.

**Conditions of Satisfaction:**

- Given a Bowtie session is active, When the user selects list-based entry mode, Then activations are added as a structured list: each row shows time interval, role, I/emotion, intensity, and description. The list is organized by side (Past, then Future) and sorted by time interval (nearest to "Now" first).
- Given a user adds markers via list-based entry, When they switch to visual diagram mode, Then all markers appear correctly plotted on the diagram.
- Given both entry modes exist, When the user switches between them, Then the same underlying data is displayed. Both modes produce identical data.

**Priority:** P1 -- Should Have

**Rationale:** Some users prefer structured forms over visual interaction, especially on smaller screens. The visual diagram may be difficult to use on iPhone SE. VoiceOver users will rely primarily on the list-based mode.

---

#### FR-BT-033: Activation Marker Visual Coding

Activation markers shall be visually distinguished by I type and side.

**Conditions of Satisfaction:**

- Given an activation marker is displayed on the diagram, When the marker represents Insignificance, Then it uses a distinct visual treatment (color + icon/shape). When representing Incompetence, a different treatment. When representing Impotence, a third treatment.
- Given markers exist on both sides, When the Past side is displayed, Then markers use solid fill. When the Future side is displayed, Then markers use outlined/dotted treatment. The visual distinction between past and future is perceptible in both color and shape.
- Given color is used for visual coding, When accessibility is considered, Then color is never the sole differentiator. Each I has a distinct icon and/or label in addition to color. Markers on the Past side are distinguishable from Future-side markers by shape in addition to fill/outline.

**Priority:** P0 -- Must Have

---

#### FR-BT-034: Running Tallies

The system shall display running tallies for each I on each side.

**Conditions of Satisfaction:**

- Given a Bowtie session has markers, When tallies are displayed, Then the Past side shows the summed intensity for Insignificance, Incompetence, and Impotence separately. The Future side shows the same three sums separately.
- Given a user adds, edits, or removes a marker, When the change is saved, Then tallies update in real-time (within 100ms).
- Given a user is in Big Ticket Emotions mode, When tallies are displayed, Then tallies are shown per Big Ticket Emotion rather than per I (Abandonment total, Loneliness total, etc.).
- Given the tallies are displayed, When the user views them, Then no judgment language accompanies the numbers. The tallies are informational: "Past Insignificance: 13" -- not "Warning: high insignificance."

**Priority:** P0 -- Must Have

**Clinical Rationale:** From the MBR transcript: "There's no magical number here. It just is telling. I feel more incompetent than I feel insignificant as I'm processing the last 48 hours. Done. That's helpful. It's informative." The tallies reveal where emotional weight is concentrated -- the primary insight of the Bowtie.

---

#### FR-BT-035: Marker Editing and Deletion

The user shall be able to edit or delete any activation marker.

**Conditions of Satisfaction:**

- Given a marker exists on the diagram or in the list, When the user taps it, Then the marker detail opens for viewing. An "Edit" option allows modification of all fields. A "Delete" option removes the marker.
- Given a marker is edited, When the edit is saved, Then tallies and any associated Backbone processing are updated accordingly.
- Given a marker is deleted, When the deletion completes, Then associated Backbone processing and PPP entries linked to that marker are also deleted. Tallies update immediately.

**Priority:** P0 -- Must Have

---

### 3.5 Backbone/Life Situations Processing

#### FR-BT-040: Initiating Backbone Processing

The user shall be able to process any activation marker through the Backbone framework.

**Conditions of Satisfaction:**

- Given a marker exists on the Bowtie, When the user taps it and selects "Process this," Then the Backbone flow opens as a sequential four-step wizard: Life Situation -> Emotions -> Three I's -> Emotional Needs, followed by the Intimacy Action step.
- Given a marker has not been processed, When it is displayed on the diagram, Then it appears without a processing indicator (unfilled, unchecked).
- Given a marker has been processed through all Backbone steps, When it is displayed on the diagram, Then a visual indicator (checkmark or filled state) shows that the marker has been addressed.
- Given a user is viewing the Bowtie, When unprocessed markers exist, Then the count of unprocessed markers is visible: "4 of 7 markers addressed."

**Priority:** P0 -- Must Have

---

#### FR-BT-041: Backbone Step 1 -- Life Situation

The system shall prompt the user to name the specific life situation.

**Conditions of Satisfaction:**

- Given the Backbone flow opens, When Step 1 is presented, Then the prompt reads: "What is happening in this moment that you're experiencing? What's happened in the recent past? Or what are you anticipating?" A free-text field is presented, max 500 characters.
- Given the marker has a brief description, When Step 1 loads, Then the description is pre-populated in the text field. The user can edit or expand it.

**Priority:** P0 -- Must Have

---

#### FR-BT-042: Backbone Step 2 -- Emotions

The system shall prompt the user to identify specific emotions.

**Conditions of Satisfaction:**

- Given the user has completed Step 1, When Step 2 is presented, Then the prompt reads: "What are you feeling about this life situation?" A horizontally scrolling set of emotion chips is displayed.
- Given the emotion chips are displayed, When the user views them, Then the curated list includes: sad, frustrated, disappointed, rejected, devalued, anxious, overwhelmed, angry, lonely, ashamed, hopeless, fearful, embarrassed, helpless, invisible, defensive, numb. Multiple selections are allowed.
- Given the curated list does not contain the user's feeling, When the user needs a custom emotion, Then a free-text "Other" option is available.

**Priority:** P0 -- Must Have

---

#### FR-BT-043: Backbone Step 3 -- Three I's

The system shall prompt the user to connect emotions to core wounds.

**Conditions of Satisfaction:**

- Given the user has completed Step 2, When Step 3 is presented, Then three options are displayed with their diagnostic questions: Insignificance -- "Do I matter?", Incompetence -- "Do I have what it takes?", Impotence -- "Do I have any control?"
- Given the three options are displayed, When the user selects one or more, Then each selected I receives an individual intensity rating (1-10). The intensity may differ from the original marker intensity -- Backbone processing often reveals deeper insight.
- Given the Backbone Three I's assessment differs from the original marker, When the Backbone is saved, Then both the original marker assessment and the Backbone assessment are stored. The Backbone assessment is used for analytics; the original marker is preserved as the initial self-assessment.

**Priority:** P0 -- Must Have

---

#### FR-BT-044: Backbone Step 4 -- Emotional Needs

The system shall prompt the user to identify valid emotional needs.

**Conditions of Satisfaction:**

- Given the user has completed Step 3, When Step 4 is presented, Then the prompt reads: "What do I need in this situation?" The following emotional needs are displayed as selectable options: Acceptance, Affirmation, Agency, Belonging, Comfort, Compassion, Connection, Empathy, Encouragement, Forgiveness, Grace, Hope, Love, Peace, Reassurance, Respect, Safety, Security, Understanding, Validation.
- Given the needs list is displayed, When the user selects needs, Then multiple selections are allowed. A free-text "Other" option is available for needs not in the list.

**Priority:** P0 -- Must Have

**Clinical Rationale:** From the MBR transcript: "Valid emotional needs -- it's like potentially a driver for us going into the cycles of destruction. It's me dealing and coping with the three I's, having needs that are going unmet. And I'm committed to not going down those roads today, and the best defense I have is to process what I'm feeling so I can identify what I need and then choose not cycles of destruction but true intimacy."

---

#### FR-BT-045: Backbone Step 5 -- Intimacy Action

The system shall present the user with actionable intimacy pathways.

**Conditions of Satisfaction:**

- Given the user has completed Step 4, When the Intimacy Action step is presented, Then three columns are displayed: **Intimacy with God** (Prayer, Scripture Reading, Sermons, Worship Music, Read a Book), **Intimacy with Self** (Complete Bowtie, Journal, Exercise, Speak Truth Over Yourself, Make a Plan, Quadrant Work), **Intimacy with Appropriate Others** (Connect with Wife/Partner, Connect with Accountability Partner, Text Your Group).
- Given the three columns are displayed, When the user selects actions, Then at least one action must be selected from any column. Multiple selections across columns are encouraged. Custom actions can be added.
- Given the user selects "Journal" as an Intimacy action, When the action is saved, Then the app offers to open the journal pre-filled with Bowtie context: "From your Bowtie: [life situation summary]. What you're feeling: [emotions]. What you need: [needs]."
- Given the user selects "Speak Truth Over Yourself," When the action is saved, Then the app offers to launch an on-demand Affirmation session.

**Priority:** P0 -- Must Have (three columns and standard actions); P1 -- Should Have (journal bridging and affirmation launch)

---

### 3.6 Prayer-People-Plan (Anticipatory Preparation)

#### FR-BT-050: PPP Entry Creation

For any activation marker on the Future side, the user shall be able to create a Prayer-People-Plan.

**Conditions of Satisfaction:**

- Given a marker exists on the Future side of the Bowtie, When the user opens the marker detail, Then a "Create Prayer-People-Plan" option is available.
- Given the user initiates PPP creation, When the PPP form opens, Then three sections are presented:
  - **Prayer:** Free-text field for what the user will pray about. Optional suggested prayer prompts based on the identified I (e.g., for Insignificance: "Lord, remind me that I am seen and valued by You"; for Incompetence: "Father, my worth is not in my performance"; for Impotence: "God, I surrender control to You").
  - **People:** Contact selector from the user's recovery contacts (accountability partner, sponsor, spouse, group members). The user identifies who they will reach out to before, during, or after the anticipated situation.
  - **Plan:** Structured free-text with prompts: "Before this situation, I will ___", "During this situation, I will ___", "After this situation, I will ___."
- Given a PPP entry is created, When the entry is saved, Then the associated future marker displays a PPP indicator on the Bowtie diagram.

**Priority:** P0 -- Must Have

**Clinical Rationale:** From the Part 2 transcript: "Prayer, people, and a plan. Hey, I know I'm going to talk to my brother tonight, so I'm going to be prayed up as I go into that. I'm going to have somebody on the hook that I'm going to call. I've already agreed, I'm going to call you after I hang up with my brother. And I'm going to have a plan."

---

#### FR-BT-051: PPP Reminder Notifications

The system shall optionally schedule a reminder before the anticipated situation.

**Conditions of Satisfaction:**

- Given a PPP entry exists for a future marker, When the user enables a reminder, Then they select a reminder interval: 30 minutes, 1 hour, 3 hours, or custom time before the anticipated moment.
- Given a reminder is scheduled, When the reminder time arrives, Then a local notification is delivered. The notification text is completely non-identifying: "Your plan is ready." No mention of recovery, emotions, wounds, or any clinical terminology.
- Given the device is offline, When the reminder time arrives, Then the local notification still fires (local notifications do not require connectivity).

**Priority:** P1 -- Should Have

---

#### FR-BT-052: PPP Follow-Up

After the anticipated time passes, the system shall surface an optional follow-up prompt.

**Conditions of Satisfaction:**

- Given a PPP entry exists for a future marker, When the anticipated time has passed and the user opens the app, Then a gentle prompt appears: "How did it go?" with quick-response options: "Better than expected" / "About what I anticipated" / "Harder than expected" / "I'll reflect later."
- Given the user selects a response, When they optionally add a free-text reflection, Then the response and reflection are stored with the PPP entry.
- Given the user selects "I'll reflect later," When 24 hours pass and the user opens the app, Then the prompt reappears once. If dismissed again, it does not reappear.

**Priority:** P2 -- Could Have

---

### 3.7 Known Emotional Triggers Integration

#### FR-BT-060: Personal Known Emotional Triggers

The system shall maintain a personal list of known emotional triggers for the user.

**Conditions of Satisfaction:**

- Given a user opens Bowtie settings or creates their first Bowtie, When the known triggers configuration is presented, Then a pre-populated list of common known emotional triggers is displayed: Embarrassment, Failure, Feeling bullied, Rejection, Overwhelm, Loneliness, Stress, Being controlled, Criticism, Being ignored, Feeling stupid, Conflict.
- Given the pre-populated list is shown, When the user selects triggers, Then selected items are added to their personal known triggers list. Custom triggers can be added with a user-defined label.
- Given a personal known triggers list exists, When the user creates activation markers, Then an optional tag field allows multi-select from the personal known triggers list. This is in addition to the Three I's/Big Ticket Emotions -- it is a second analytical layer.

**Priority:** P1 -- Should Have

**Clinical Rationale:** From the Part 1 transcript: "For all of us, we all have hot button emotional things. For some person it's failure. For another person it's overwhelm. For somebody it's loneliness. They're present with us and we know it. Somebody offends you and you're not going to get a rise out of you, but if they make you feel stupid, you'll lose your mind." Known emotional triggers are the second transparency layer -- the overhead projector stacking that reveals patterns the Three I's lens alone may miss.

---

### 3.8 Spiritual Lens

#### FR-BT-070: Spiritual Lens Processing

The system shall offer an optional spiritual lens for Bowtie analysis.

**Conditions of Satisfaction:**

- Given a user is viewing an activation marker, When they expand the marker detail, Then an optional "Spiritual lens" section is available with guided prompts: "How did you experience yourself and God in this role during this time?" and "Was there conviction, resistance, closeness, distance?" A free-text reflection field captures the response.
- Given the spiritual lens is available, When a user does not engage it, Then no prompt or judgment is shown. The spiritual lens is always optional, never assumed.
- Given the user has engaged the spiritual lens on a marker, When the marker is viewed, Then the spiritual reflection is displayed alongside the emotional processing.

**Priority:** P1 -- Should Have

**Clinical Rationale:** From the Part 2 transcript: "We can also do the same thing from a spiritual perspective. As it pertains to my role as a father with my middle, over the last 48 hours, how do I experience myself and God relative to my son?" The spiritual lens adds a layer beyond emotional self-awareness -- it asks what is happening between the user and God in the context of these wounds.

---

### 3.9 Guided Mode and Onboarding

#### FR-BT-080: First-Time Onboarding

The system shall provide a first-time onboarding flow when the user opens the Bowtie for the first time.

**Conditions of Satisfaction:**

- Given a user opens the Bowtie feature for the first time, When the onboarding begins, Then it covers: (a) what the Bowtie is in plain language ("A tool to help you see what's been stirring in your heart -- and what's coming -- so you can meet your real needs instead of reaching for something that hurts you"), (b) the visual metaphor (looking back 48 hours and looking ahead 48 hours, with "Now" at the center), (c) the Three I's concept with diagnostic questions and the Big Ticket Emotions alternative, (d) the difference between retroactive and anticipatory use, (e) that this is a self-intimacy practice -- not a test or a grade.
- Given the onboarding is displayed, When the user taps "Skip," Then the onboarding closes and is re-accessible from a help icon within the Bowtie feature.
- Given the onboarding is complete, When the user proceeds, Then role configuration (FR-BT-010) and known triggers configuration (FR-BT-060) are offered if not already completed.

**Priority:** P0 -- Must Have

---

#### FR-BT-081: Guided vs. Freeform Session Mode

The system shall offer two session modes with an automatic transition.

**Conditions of Satisfaction:**

- Given a user has completed fewer than 3 Bowties, When they start a new session, Then the default mode is **Guided**. Guided mode walks through each selected role sequentially with prompts.
- Given the user has completed 3 or more Bowties, When they start a new session, Then the default mode is **Freeform**. Freeform mode presents the full Bowtie diagram for self-directed use.
- Given the user is in either mode, When they want to switch, Then a toggle is available to switch between Guided and Freeform at any time during the session.

**Priority:** P0 -- Must Have

---

#### FR-BT-082: Guided Mode Role-by-Role Prompts

In Guided mode, the system shall walk through each role sequentially.

**Conditions of Satisfaction:**

- Given the session is in Guided mode, When the Past side analysis begins, Then the system presents the first selected role with the prompt: "Over the last 48 hours, as a [Role], has anything stirred the Three I's? Has anything hit your known emotional triggers?"
- Given the user is prompted for a role, When they add markers, Then each marker is automatically associated with the current role. The user adds markers or indicates "Nothing for this role."
- Given the current role is complete, When the user taps "Next role," Then the system moves to the next selected role. After all roles on the Past side, the system repeats the role-by-role prompts for the Future side: "Looking ahead over the next 48 hours, as a [Role], is anything coming up that might stir your emotions?"
- Given all roles on both sides have been prompted, When the Guided mode completes the role scan, Then the user is presented with the full Bowtie diagram showing all markers with an invitation to process unaddressed markers through the Backbone.

**Priority:** P0 -- Must Have

**Clinical Rationale:** From the MBR transcript: "Take each of those transparencies and lay them down onto the overhead projector. So now I can take each of those layers. I look at my husband role, then we go through the dad roles, then son-in-law, then coworker... You just walk through these." The role-by-role prompting implements the overhead-projector transparency metaphor -- one layer at a time until the full picture emerges.

---

#### FR-BT-083: Guided Mode Educational Content

In Guided mode, the system shall provide inline education as concepts are introduced.

**Conditions of Satisfaction:**

- Given a concept is introduced for the first time (Three I's, Big Ticket Emotions, Backbone, PPP), When the concept appears in the flow, Then a brief (2-3 sentence) educational note is shown as an expandable "Learn more" section.
- Given educational notes are displayed, When the user has seen a concept in 3+ sessions, Then the educational note is no longer shown by default but remains accessible via the help icon.

**Priority:** P1 -- Should Have

---

### 3.10 Pattern Analysis and Insights

#### FR-BT-090: Three I's Distribution Over Time

The system shall track and display which I's are most frequently activated.

**Conditions of Satisfaction:**

- Given a user has completed 3+ Bowties, When they navigate to Bowtie Insights, Then aggregate data is displayed: total and average intensity per I across all completed Bowties. Trend lines show whether each I's activation is increasing, decreasing, or stable over 30/90-day windows.
- Given the trend for an I is declining, When the user views it, Then growth-oriented framing is used: "Your Insignificance activation has decreased 15% over the past month."

**Priority:** P1 -- Should Have

---

#### FR-BT-091: Role-Based Activation Analysis

The system shall display which roles produce the most emotional activation.

**Conditions of Satisfaction:**

- Given a user has completed 3+ Bowties, When they navigate to role analytics, Then a ranked list shows roles by total emotional activation (sum of intensities across all markers for that role). Per-role frequency (number of markers) and average intensity are displayed.
- Given role analytics are displayed, When a user taps a role, Then a drill-down shows the I distribution for that role across sessions.

**Priority:** P1 -- Should Have

---

#### FR-BT-092: Anticipatory Ratio Tracking

The system shall track the ratio of past-side to future-side activations.

**Conditions of Satisfaction:**

- Given a user has completed 5+ Bowties, When they navigate to practice insights, Then the anticipatory ratio is displayed: percentage of total markers that are on the future side, shown as a trend over sessions.
- Given the anticipatory ratio is increasing, When the user views it, Then growth-oriented framing is used: "Your anticipatory awareness is growing -- you're spending more time preparing than reacting. That's a recovery skill most people never develop."
- Given the anticipatory ratio is decreasing or flat, When the user views it, Then neutral framing is used: "Most of your Bowtie work has been looking back. If you're ready, try spending more time on the future side next session." No judgment.

**Priority:** P2 -- Could Have

---

### 3.11 Viewing Completed Bowties

#### FR-BT-095: Completed Bowtie Review

The system shall allow users to view completed Bowties in full detail.

**Conditions of Satisfaction:**

- Given a user taps a completed Bowtie in history, When the session opens, Then the full Bowtie diagram is displayed with all markers, processing indicators, PPP entries, and tallies. The session is read-only except for the ability to process unaddressed markers.
- Given a completed Bowtie has unprocessed markers, When the user views it, Then a "Process unaddressed markers" option is available. Backbone processing on existing markers does not create a new session.

**Priority:** P0 -- Must Have

---

## 4. Non-Functional Requirements

### 4.1 Privacy and Security

| ID | Requirement | MoSCoW |
|----|-------------|--------|
| NFR-BT-001 | All Bowtie data shall be encrypted at rest using AES-256 via SwiftData encrypted storage. | Must |
| NFR-BT-002 | All Bowtie data transmitted to the server shall be encrypted in transit using TLS 1.3 minimum. | Must |
| NFR-BT-003 | The app's biometric or PIN lock applies to all Bowtie data. No Bowtie content is accessible without authentication. | Must |
| NFR-BT-004 | All Bowtie-related notifications (PPP reminders, weekly practice reminders) shall use completely non-identifying language. No notification shall contain the words "bowtie," "recovery," "emotion," "wound," "trigger," or any clinical terminology visible on the lock screen. | Must |
| NFR-BT-005 | The system shall not perform analytics on user-entered free-text content (life situation descriptions, spiritual reflections, PPP plans) for any purpose other than displaying it back to the user. No NLP processing, sentiment analysis, or text mining without explicit consent. | Must |
| NFR-BT-006 | Immutable timestamps: `createdAt` is never modified on any Bowtie entity (session, marker, backbone processing, PPP entry). | Must |
| NFR-BT-007 | Tenant isolation: every server-side document carries `tenantId`, enforced at API layer. | Must |
| NFR-BT-008 | When the user deletes Bowtie data, it shall be permanently erased from all local and remote storage within 24 hours, including any derived analytics or cached computations referencing the deleted entries. | Must |

### 4.2 Performance

| ID | Requirement | MoSCoW |
|----|-------------|--------|
| NFR-BT-010 | Bowtie diagram render time: < 500ms on devices from the past 3 years. | Must |
| NFR-BT-011 | Marker add/edit response time: < 100ms (perceived instant). | Must |
| NFR-BT-012 | Backbone flow step transitions: < 200ms per step. | Must |
| NFR-BT-013 | History list load (100 sessions): < 1s. | Must |
| NFR-BT-014 | Analytics computation (50 sessions): < 2s. | Should |
| NFR-BT-015 | Auto-save write: < 100ms. | Must |

### 4.3 Accessibility

| ID | Requirement | MoSCoW |
|----|-------------|--------|
| NFR-BT-020 | All Bowtie feature screens shall meet WCAG 2.1 AA compliance. | Must |
| NFR-BT-021 | VoiceOver full support. Bowtie diagram announced as structured data: "Past side: 3 activation markers. Future side: 2 activation markers. Tallies: Insignificance past 8, future 4..." List-based entry mode (FR-BT-032) provides the primary VoiceOver-accessible interaction. | Must |
| NFR-BT-022 | All text scales with Dynamic Type from xSmall to AX5. Bowtie diagram gracefully degrades at larger text sizes. | Must |
| NFR-BT-023 | Minimum 44x44pt touch targets for all interactive elements (markers, role chips, emotion chips, I selectors, intensity controls, buttons). | Must |
| NFR-BT-024 | Color never the sole indicator of which I is activated. Icons and labels accompany all color-coded elements. Past/Future markers differentiated by shape in addition to color/fill. | Must |
| NFR-BT-025 | Full support for increased contrast mode. | Should |
| NFR-BT-026 | Disable animation on the Bowtie diagram when Reduce Motion is enabled. | Should |
| NFR-BT-027 | All UI text and educational content at 8th-grade reading level maximum. | Must |

### 4.4 Reliability

| ID | Requirement | MoSCoW |
|----|-------------|--------|
| NFR-BT-030 | Zero data loss during Bowtie sessions, including app termination, backgrounding, and system memory pressure. | Must |
| NFR-BT-031 | If a Bowtie session fails to sync to the server, retry with exponential backoff (up to 5 attempts). Failed syncs produce no user-visible error for 24 hours; after 24 hours: "Some of your data is waiting to sync. It will be saved when connectivity returns." | Must |
| NFR-BT-032 | Compassionate error states: all error messages avoid clinical, technical, or shame-inducing language. | Must |

### 4.5 Other Non-Functional

| ID | Requirement | MoSCoW |
|----|-------------|--------|
| NFR-BT-040 | Feature flag `activity.bowtie` fail-closed: 404 / feature hidden when disabled. | Must |
| NFR-BT-041 | Calendar activity dual-write: every completed session writes to `calendarActivities` with `activityType: "BOWTIE"`. | Must |
| NFR-BT-042 | No streak-based metrics: zero streak counters for Bowtie practice anywhere in code, UI, or notifications. Cumulative metrics only. | Must |
| NFR-BT-043 | Guided-to-freeform transition: after 3 completed guided sessions, default switches to freeform. User can override in either direction. | Must |
| NFR-BT-044 | Test coverage: >= 80% overall; 100% on data persistence, Backbone state machine, PPP reminder scheduling, tally computation, and auto-save reliability. | Must |
| NFR-BT-045 | Offline-first: all core Bowtie functionality (creation, markers, Backbone, PPP, history, analytics) works without internet. Server sync is the only feature requiring connectivity. | Must |

---

## 5. Data Model

### 5.1 SwiftData Models (iOS Local Storage)

**BowtieSession**

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Unique identifier |
| `status` | BowtieStatus (enum) | draft, complete |
| `referenceTimestamp` | Date | The "Now" point of the Bowtie |
| `createdAt` | Date | Immutable creation timestamp |
| `completedAt` | Date? | When the user marked it complete |
| `modifiedAt` | Date | Last modification timestamp |
| `selectedRoleIds` | [UUID] | Roles examined in this session |
| `emotionVocabulary` | EmotionVocabulary (enum) | threeIs, bigTicket, combined |
| `entryPath` | BowtieEntryPath (enum) | activities, postRelapse, fasterScale, checkIn |
| `sessionMode` | BowtieSessionMode (enum) | guided, freeform |
| `pastInsignificanceTotal` | Int | Computed sum of past Insignificance intensities |
| `pastIncompetenceTotal` | Int | Computed sum of past Incompetence intensities |
| `pastImpotenceTotal` | Int | Computed sum of past Impotence intensities |
| `futureInsignificanceTotal` | Int | Computed sum of future Insignificance intensities |
| `futureIncompetenceTotal` | Int | Computed sum of future Incompetence intensities |
| `futureImpotenceTotal` | Int | Computed sum of future Impotence intensities |
| `syncStatus` | SyncStatus (enum) | pending, synced, failed |

**BowtieMarker** (Activation Point)

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Unique identifier |
| `sessionId` | UUID | Parent Bowtie session |
| `side` | BowtieSide (enum) | past, future |
| `timeIntervalHours` | Int | Approximate hours from "Now" (1, 3, 6, 12, 24, 36, 48) |
| `roleId` | UUID | Which role this activation is experienced in |
| `iActivations` | [IActivation] | Array of activated I's with individual intensities |
| `bigTicketEmotions` | [BigTicketActivation]? | If using Big Ticket mode |
| `customEmotions` | [String]? | If using custom emotion labels |
| `knownTriggerIds` | [UUID]? | Optional known emotional triggers involved |
| `briefDescription` | String? | Max 280 characters |
| `spiritualReflection` | String? | Optional spiritual lens free-text |
| `isProcessed` | Bool | Whether Backbone processing has been completed |
| `createdAt` | Date | Immutable creation timestamp |

**IActivation** (embedded)

| Field | Type | Description |
|-------|------|-------------|
| `iType` | ThreeIType (enum) | insignificance, incompetence, impotence |
| `intensity` | Int | 1-10 |

**BigTicketActivation** (embedded)

| Field | Type | Description |
|-------|------|-------------|
| `emotion` | BigTicketEmotion (enum) | abandonment, loneliness, rejection, sorrow, neglect |
| `intensity` | Int | 1-10 |

**BackboneProcessing** (linked to a BowtieMarker)

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Unique identifier |
| `markerId` | UUID | Parent marker |
| `lifeSituation` | String | Max 500 characters |
| `emotions` | [String] | Selected emotion labels |
| `threeIs` | [IActivation] | Three I's with intensities (may differ from marker's original assessment) |
| `emotionalNeeds` | [String] | Selected emotional needs |
| `intimacyActions` | [IntimacyAction] | Selected actions with category |
| `createdAt` | Date | Immutable creation timestamp |

**IntimacyAction** (embedded)

| Field | Type | Description |
|-------|------|-------------|
| `category` | IntimacyCategory (enum) | god, self, others |
| `label` | String | Action label |
| `isCustom` | Bool | Whether user-created |

**PPPEntry** (Prayer-People-Plan, linked to a future BowtieMarker)

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Unique identifier |
| `markerId` | UUID | Parent future marker |
| `prayer` | String? | Prayer text |
| `peopleContactIds` | [UUID]? | Recovery contacts to reach out to |
| `planBefore` | String? | "Before, I will ___" |
| `planDuring` | String? | "During, I will ___" |
| `planAfter` | String? | "After, I will ___" |
| `reminderTime` | Date? | Scheduled reminder |
| `followUpOutcome` | PPPOutcome (enum)? | better, expected, harder, reflectLater |
| `followUpReflection` | String? | Optional reflection text |
| `createdAt` | Date | Immutable creation timestamp |

**UserRole** (persistent across sessions)

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Unique identifier |
| `label` | String | Role name |
| `sortOrder` | Int | Display order |
| `isArchived` | Bool | Hidden from new session selection |
| `createdAt` | Date | Creation timestamp |

**KnownEmotionalTrigger** (persistent across sessions)

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Unique identifier |
| `label` | String | Trigger label (e.g., "embarrassment," "feeling bullied") |
| `mappedI` | ThreeIType? | Optional mapping to a primary I |
| `createdAt` | Date | Creation timestamp |

### 5.2 Enumerations

```
BowtieStatus: draft, complete
BowtieSide: past, future
ThreeIType: insignificance, incompetence, impotence
BigTicketEmotion: abandonment, loneliness, rejection, sorrow, neglect
EmotionVocabulary: threeIs, bigTicket, combined
BowtieEntryPath: activities, postRelapse, fasterScale, checkIn
BowtieSessionMode: guided, freeform
IntimacyCategory: god, self, others
PPPOutcome: better, expected, harder, reflectLater
SyncStatus: pending, synced, failed
```

### 5.3 Server-Side Schema (MongoDB)

The Bowtie session follows the existing collection-per-entity pattern:

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `BOWTIE#<ISO8601 timestamp>` |
| entityType | `BOWTIE` |

**Calendar Activity Entry:**
```json
{
  "userId": "u_12345",
  "date": "2026-04-22",
  "activityType": "BOWTIE",
  "timestamp": "2026-04-22T20:00:00Z"
}
```

**Access Patterns:**

| Pattern | Operation | Key Condition |
|---------|-----------|---------------|
| Get recent bowties | find | PK=USER#{userId}, SK begins_with BOWTIE#, ScanIndexForward=false |
| Get bowties by date range | find | PK=USER#{userId}, SK between BOWTIE#{start} and BOWTIE#{end} |
| Get bowtie with markers | find | PK=BOWTIE#{bowtieId}, SK begins_with MARKER# |

### 5.4 Sync Conflict Resolution

Per the project's established sync patterns:
- **New sessions/markers:** Union merge (both sides keep their additions)
- **Edits:** Last-write-wins based on `modifiedAt` timestamp
- **Deletes:** Immediate propagation (delete wins over edit)

---

## 6. User Journeys

### 6.1 Journey: First-Time Bowtie (Alex, Day 45, Guided Mode)

```
Alex -> Activities -> Bowtie Diagram -> [First time: Onboarding]
  -> "What is the Bowtie Diagram?" (brief visual explanation)
    "A tool to help you see what's been stirring in your heart --
    and what's coming -- so you can meet your real needs instead
    of reaching for something that hurts you."
  -> "Set up your roles" -> pre-populated suggestions
    Alex selects: Christian, Husband, Father (oldest), Man in Recovery, Coworker
  -> "Set up your known emotional triggers"
    Alex selects: Rejection, Failure, Overwhelm, Feeling dismissed
  -> [Onboarding complete -- saved to profile]

  -> New Bowtie -> "Now" = current moment (default)
  -> Select roles for this session: Christian, Husband, Father (oldest), Coworker
  -> PAST 48 HOURS (Guided mode -- role by role):
    -> Prompt: "Over the last 48 hours, as a Husband,
      has anything stirred the Three I's?"
    -> Alex adds: "Wife needed space at school event" ->
      Insignificance, intensity 4, role: Husband, ~24h ago
    -> Prompt: "As a Coworker?"
    -> Alex adds: "Boss criticized my report" ->
      Incompetence, intensity 6, role: Coworker, ~6h ago
    -> Past tallies update: Insignificance: 4, Incompetence: 6, Impotence: 0

  -> FUTURE 48 HOURS (Guided mode continues):
    -> Prompt: "Looking ahead, as a Coworker,
      is anything coming up that might stir your emotions?"
    -> Alex adds: "Team meeting with boss tomorrow" ->
      Incompetence, intensity 5 (anticipated), role: Coworker, ~18h out
    -> Future tallies: Insignificance: 0, Incompetence: 5, Impotence: 0

  -> PROCESS: Alex taps the boss criticism marker (intensity 6)
    -> Backbone flow opens:
      -> Life Situation: "Boss said my report was 'sloppy work'"
      -> Emotions: frustrated, embarrassed, devalued
      -> Three I's: Incompetence (7)
      -> Emotional Needs: Affirmation, Respect
      -> Intimacy Action: "Journal about this" (Self) +
        "Text accountability partner" (Others)
    -> Marker updated with processing checkmark

  -> PPP for tomorrow's meeting:
    -> Prayer: "Ask God for peace and perspective before the meeting"
    -> People: "Text Jake after the meeting"
    -> Plan: "Before: Arrive 5 min early, pray in parking lot.
      During: If criticized, pause before responding.
      After: Journal emotions before going home."

  -> [Complete Bowtie] -> "You just did real work.
    Seeing what's stirring in your heart is a recovery skill."
  -> Bowtie saved. Calendar activity entry created.
```

### 6.2 Journey: Post-Relapse Retroactive Bowtie (Marcus, Day 1 Reset)

```
Marcus reports sobriety reset at 11 PM last night
  -> System suggests: "Understanding what happened is part of recovery.
    A Bowtie Diagram can help you see what was building up."
  -> Marcus taps [Start Bowtie]
  -> "Now" auto-set to 11 PM last night

  -> Using Big Ticket Emotions mode (Marcus is early in recovery vocabulary)
  -> Past 48 hours:
    -> 1h before: "Scrolling alone in apartment" -> Loneliness (8)
    -> 6h before: "Friend cancelled dinner plans" -> Rejection (7)
    -> 24h before: "Skipped church, felt guilty" -> Sorrow (5)
    -> 36h before: "Mom's birthday, didn't call" -> Neglect (4), Sorrow (3)
  -> Past tallies: Abandonment: 0, Loneliness: 8, Rejection: 7,
    Sorrow: 8, Neglect: 4

  -> Marcus skips Future side -> [That's okay. You can add this later.]

  -> Processes the friend cancellation (Rejection 7):
    -> Life Situation: "Only friend who knows about my recovery cancelled"
    -> Emotions: rejected, invisible, desperate
    -> Three I's: Insignificance (8)
    -> Needs: Connection, Belonging
    -> Intimacy Action: "Call a different friend tomorrow" (Others)

  -> [Complete Bowtie]
  -> "What you just did took courage. You looked at something painful
    and learned from it. That's not failure -- that's recovery."
  -> Bowtie saved with link to the relapse event.
```

### 6.3 Journey: Anticipatory Bowtie (Diego, Day 200, Weekly Practice)

```
Diego -> Activities -> Bowtie -> New Bowtie (Sunday evening routine)
  -> Freeform mode (his default after 20+ sessions)
  -> Selects roles: Christian, Husband, Father (all 3), Brother, Coach
  -> Quick scan of Past 48 (3 markers, minimal guidance needed)
  -> Past tallies: Insignificance: 5, Incompetence: 3, Impotence: 0

  -> Future 48 (where Diego spends most time now):
    -> 3h: Evening conversation with wife about finances ->
      Incompetence (4), role: Husband
    -> 12h: Monday standup with difficult colleague ->
      Insignificance (3), role: Coworker
    -> 24h: Brother's birthday -- should he call? ->
      Insignificance (6) + Impotence (4), role: Brother
    -> 36h: Kids' soccer practice (coaching) ->
      Incompetence (3) + Impotence (3), role: Coach/Father
  -> Future tallies: Insignificance: 9, Incompetence: 7, Impotence: 7

  -> Diego notes: "Impotence is higher than expected this week."

  -> Creates PPP for brother's birthday:
    -> Prayer: "Pray for the conversation before dialing"
    -> People: "Matt on standby -- call after I hang up"
    -> Plan: "Before: Call from the study, set 30-min limit.
      During: Listen more than talk.
      After: Journal 3 emotions before doing anything else."

  -> Processes the finance conversation through Backbone:
    -> Life Situation: "We overspent; I feel responsible"
    -> Emotions: ashamed, anxious, inadequate
    -> Three I's: Incompetence (5)
    -> Needs: Grace, Understanding, Reassurance
    -> Intimacy: "Pray together before the conversation" (God) +
      "Be honest about feeling inadequate" (Self) +
      "Ask Emma for grace, not solutions" (Others)

  -> [Complete Bowtie]
  -> Weekly Bowtie logged. Anticipatory ratio: 68%.
```

---

## 7. Integrations

### 7.1 Internal App Integrations

| System | Integration Type | Direction | Details |
|--------|-----------------|-----------|---------|
| **Sobriety Counter** | Contextual trigger | Read | Sobriety reset event triggers post-relapse Bowtie suggestion (FR-BT-001). |
| **FASTER Scale** | Contextual trigger | Read | Elevated FASTER position ("Speeding Up" or beyond) triggers Bowtie suggestion (FR-BT-001). |
| **Triggers Feature** | Data correlation | Read/Write | Known emotional triggers in Bowtie may reference Trigger Library entries. Bowtie activations that identify triggers create correlation data. |
| **Urge Logs** | Data correlation | Read | Post-relapse Bowtie correlates with preceding urge log entries within 72h window. |
| **Journaling** | Content bridging | Write | Backbone "Journal" intimacy action opens journal pre-filled with Bowtie context (FR-BT-045). |
| **Check-Ins (FANOS, Evening Review)** | Contextual trigger | Read | Check-in responses indicating emotional activation may suggest a Bowtie (FR-BT-001). |
| **Calendar Activity** | Dual-write | Write | Each completed session writes `activityType: "BOWTIE"` to calendar. |
| **Feature Flags** | Gating | Read | `activity.bowtie` controls feature visibility. Fail closed. |
| **Notifications** | Scheduling | Write | PPP reminder notifications. Optional weekly practice reminders. |
| **Three Circles** | Pattern correlation | Read | Bowtie activation patterns correlate with middle-circle drift. |
| **Affirmations** | Content bridging | Read | Intimacy action "Speak Truth Over Yourself" can launch an on-demand Affirmation session. |

### 7.2 External Integrations

None required for v1. The Bowtie is a self-contained reflective tool.

---

## 8. Premium Tier Boundaries

| Capability | Free | Standard | Premium+ |
|------------|------|----------|----------|
| Bowtie session creation | Unlimited | Unlimited | Unlimited |
| Guided and freeform modes | Full access | Full access | Full access |
| Role configuration and selection | Full access | Full access | Full access |
| Three I's, Big Ticket, and Combined modes | Full access | Full access | Full access |
| Activation marker plotting (past + future) | Full access | Full access | Full access |
| Running tallies | Full access | Full access | Full access |
| Backbone/Life Situations processing | Full access | Full access | Full access |
| Intimacy action selection | Full access | Full access | Full access |
| PPP creation | Full access | Full access | Full access |
| PPP reminders | Full access | Full access | Full access |
| Auto-save and draft management | Full access | Full access | Full access |
| Session history (last 30 days) | Full access | N/A | N/A |
| Session history (full) | No | Full access | Full access |
| Known emotional triggers integration | No | Full access | Full access |
| Spiritual lens | No | Full access | Full access |
| Custom emotion labels | No | Full access | Full access |
| Three I's distribution over time | No | Full access | Full access |
| Role-based activation analysis | No | Full access | Full access |
| Anticipatory ratio tracking | No | Full access | Full access |
| PPP follow-up tracking | No | Full access | Full access |
| AI-assisted pattern detection across sessions | No | No | Full access |
| Accountability partner Bowtie summary sharing | No | No | Full access |

**Design Principle:** The core therapeutic mechanism -- creating a Bowtie, plotting activations, processing through the Backbone, creating PPP plans -- is always free. Self-intimacy should never be paywalled. Premium unlocks longitudinal analytics and pattern detection that enhance the experience but are not required for the tool's clinical value.

---

## 9. Analytics & Tracking

### 9.1 Product Analytics Events

All events are anonymized. No user-entered text, emotion selections, or personal data in analytics. Opt-out available.

| Event | Properties | Purpose |
|-------|------------|---------|
| `bowtie.session.started` | `entryPath`, `mode`, `emotionVocabulary`, `roleCount` | Session engagement by entry path |
| `bowtie.session.completed` | `entryPath`, `mode`, `durationMinutes`, `pastMarkerCount`, `futureMarkerCount`, `backboneCompletedCount`, `pppCreatedCount` | Session depth and completion patterns |
| `bowtie.session.abandoned` | `entryPath`, `mode`, `durationMinutes`, `lastStepReached` | Drop-off analysis |
| `bowtie.session.resumed` | `draftAgeHours` | Draft resume patterns |
| `bowtie.marker.added` | `side`, `iType`, `intensity`, `hasNote` (bool) | Activation distribution |
| `bowtie.backbone.started` | `markerSide`, `markerIType` | Backbone engagement |
| `bowtie.backbone.completed` | `needsSelectedCount`, `intimacyActionsCount` | Backbone completion depth |
| `bowtie.ppp.created` | `hasPrayer` (bool), `hasPeople` (bool), `hasPlan` (bool), `reminderSet` (bool) | PPP adoption and completeness |
| `bowtie.ppp.followup.responded` | `outcome` | PPP effectiveness signal |
| `bowtie.history.viewed` | `totalCompleted` | History engagement |
| `bowtie.insights.viewed` | `insightType` | Analytics engagement |
| `bowtie.onboarding.completed` | `skipped` (bool), `durationSeconds` | Onboarding effectiveness |

### 9.2 Key Product Metrics (KPIs)

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Bowtie adoption** | 30% of active users complete at least 1 Bowtie within 30 days of launch | Event tracking |
| **Session completion rate (guided)** | > 60% | Started sessions reaching "Complete" |
| **Session completion rate (freeform)** | > 75% | Started sessions reaching "Complete" |
| **Backbone processing rate** | > 40% of activation markers processed | Processed markers / total markers |
| **PPP creation rate** | > 30% of future markers with PPP | PPP entries / future markers |
| **Weekly practice rate (30-day)** | > 20% of adopters complete 1+/week at 30 days | Rolling 7-day completion |
| **Anticipatory ratio growth** | Increasing trend over 90 days | Future markers / total markers, monthly |
| **Post-relapse Bowtie uptake** | > 25% of relapse events followed by Bowtie within 48h | Relapse events -> Bowtie sessions |

---

## 10. Tone, Voice, and Language Guidelines

### 10.1 Core Principle

The Bowtie is the most introspective tool in the app. The user is sitting with their wounds. The tone is that of a trusted counselor -- calm, honest, never rushing, never minimizing.

### 10.2 Language Rules

| Instead of | Use |
|------------|-----|
| "Trigger analysis" | "What's been stirring in your heart" |
| "Emotional damage" | "Emotional activation" or "what got stirred" |
| "You were triggered by your wife" | "You felt something in your role as a husband" |
| "Rate your pain" | "How strongly did this hit?" |
| "You failed to process" | "This one hasn't been addressed yet" |
| "Relapse indicators" | "What was building up" |
| "Fix your emotions" | "Meet your real needs" |
| "You should have seen this coming" | "Now you can see the pattern. That's growth." |

### 10.3 Empty States

**No Bowties yet:**
"The Bowtie Diagram helps you see what's really going on inside -- the subtle wounds and unmet needs that build up beneath the surface. When you're ready, this is where you start building that awareness."

**No activations on Future side:**
"Nothing on the radar? That's okay. Sometimes the future looks clear. You can always come back and add to this if something comes to mind."

**All markers processed:**
"Every point on your Bowtie has been addressed. You've done real self-intimacy work today."

### 10.4 Completion Messages (rotating set)

- "You just practiced seeing yourself honestly. That's a recovery skill most people never develop."
- "The more you do this, the less the addiction can surprise you."
- "Knowing what's stirring in your heart is the beginning of freedom."
- "You've moved from reacting to understanding. That matters."
- "Self-intimacy is the antidote. You just practiced it."

---

## 11. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| **Tool complexity deters adoption.** The Bowtie is the most complex activity in the app -- multiple layers, roles, vocabularies, Backbone processing. | High | High | Guided mode for first 3 sessions teaches the methodology incrementally. Quick Bowtie (2-3 roles, skip Backbone) takes 5-10 minutes. Depth on demand, never required. |
| **Emotional overwhelm during deep processing.** Processing painful wounds through the Backbone may surface intense emotions. | Medium | High | Backbone processing is always optional. Each step has a "Skip" or "Come back later" option. After completing a Backbone with high-intensity content, a grounding prompt appears: "You just did hard work. Take a breath." Crisis resources remain one tap away. |
| **Post-relapse Bowtie feels like punishment.** A user who just relapsed may interpret a Bowtie suggestion as rubbing it in. | Medium | High | The suggestion language is compassionate and fully dismissible: "Understanding what happened is part of recovery." Never automatic; always user-initiated after seeing the suggestion. Completion messages emphasize courage, not failure. |
| **Small-screen visual limitations.** The bowtie shape with 7 time intervals per side is challenging on iPhone SE. | High | Medium | List-based entry mode as primary fallback. Visual diagram auto-simplifies at small sizes. |
| **Privacy concern about emotional data.** Bowtie data is deeply personal -- specific wounds, roles, relationships. | Medium | Critical | Encryption at rest and in transit. Biometric lock. Non-identifying notifications. No text analytics. Full user-controlled deletion. |
| **Vocabulary confusion.** Users may not understand the relationship between Three I's, Big Ticket Emotions, and known emotional triggers. | Medium | Medium | Onboarding explains each concept. Guided mode introduces concepts progressively. "Learn more" expandable sections available throughout. Big Ticket to Three I's migration is suggested, never forced. |
| **Low Backbone processing completion.** Users may plot the Bowtie but skip the Backbone, reducing clinical value. | Medium | Medium | "Process this" is prominent but optional. Guided mode walks through at least one Backbone per session. Unprocessed marker count is visible but framed neutrally. |

---

## 12. Open Questions

1. **Bowtie visual on small screens:** The bowtie shape with 7 time intervals per side may be difficult to render on iPhone SE-sized screens. Should we default to list-based entry on smaller screens and reserve the visual diagram for larger screens?

2. **Role granularity for children:** The source material distinguishes "Father of Child 1" from "Father of Child 2" because each relationship carries unique emotional dynamics. Should we support sub-roles (e.g., "Father" with children as sub-entries), or keep roles flat and let the user create "Father -- Oldest," "Father -- Middle," etc.?

3. **Big Ticket Emotions to Three I's mapping accuracy:** The mapping is approximate and varies by person. Should the system suggest a default mapping and let users customize, or require users to define their own mapping? If users define their own, analytics consistency across the user base is reduced.

4. **Bowtie frequency recommendations:** The source material suggests weekly Bowties for ongoing self-awareness and immediate Bowties after acting out/in events. Should the app actively prompt for a weekly Bowtie (opt-in reminder), or leave it entirely user-initiated?

5. **Spiritual lens as default or opt-in:** The source material treats the spiritual lens as integral. In an overtly Christian app, should the spiritual processing step be included by default in the Backbone flow, or offered as an optional additional step? Recommendation: optional step to respect Sarah's persona (trauma history, spiritual lens optional).

6. **PPP follow-up timing:** When should the PPP follow-up prompt appear -- at the anticipated time, 1 hour after, or the next time the user opens the app after the anticipated time? Recommendation: next app open after the anticipated time.

7. **Bowtie and post-mortem relationship:** Should a retroactive Bowtie completed after a relapse automatically create or link to a post-mortem entry? Recommendation: cross-reference link, not automatic creation.

8. **Time interval flexibility:** The source material uses 1h/3h/6h/12h/24h/36h/48h intervals but notes "the numbers aren't absolute." Should we allow users to place markers at arbitrary points on the timeline, or keep fixed intervals as placement guides? Recommendation: fixed intervals as guides with the understanding they represent approximate ranges.

---

## 13. Dependencies

| Dependency | Status | Blocks |
|------------|--------|--------|
| SwiftData models and repository | Available | Blocking -- no local persistence |
| SyncEngine configuration for BOWTIE entity | Requires work | Blocking for server sync; offline creation works |
| Feature flag service | Available | Blocking -- feature cannot ship without flag |
| Calendar activity view | Shipped | FR-BT integration available |
| Sobriety counter (relapse event) | Wave 1 -- In progress | Post-relapse suggestion entry point |
| FASTER Scale feature | Wave 2 -- In progress | FASTER suggestion entry point (non-blocking) |
| Triggers feature | Wave 2 -- In progress | Known emotional triggers cross-reference (non-blocking) |
| Journaling | Wave 1 -- In progress | Backbone -> Journal bridging (non-blocking) |
| Three Circles feature | Wave 1 -- In progress | Pattern correlation (non-blocking) |
| Affirmations feature | Wave 1 -- Shipped | Intimacy action -> Affirmation session (non-blocking) |
| Notification infrastructure | Available | PPP reminders |

---

## 14. Success Criteria

| Criteria | Measurement | Target |
|----------|-------------|--------|
| Feature adopted by active users | Bowtie completions / active users | > 30% within 30 days of GA |
| Session completion rate (guided) | Completion rate | > 60% |
| Session completion rate (freeform) | Completion rate | > 75% |
| Backbone processing depth | % of markers processed | > 40% |
| PPP adoption on future markers | % of future markers with PPP | > 30% |
| Weekly practice retention | Users completing 1+/week at 30 days | > 20% of adopters |
| Post-relapse Bowtie usage | Relapse events followed by Bowtie within 48h | > 25% |
| Anticipatory growth | Future-side marker ratio increasing over 90 days | Positive trend |
| User-reported usefulness | "Does the Bowtie help you understand yourself better?" | > 4.0/5.0 |
| Zero privacy incidents | Privacy breach count | 0 |
| Accessibility audit | WCAG 2.1 AA violations | 0 critical, < 5 minor |

---

## 15. References

### Source Material

- **Bowtie Diagram Part 1** (video transcript) -- Redemptive Living Academy. Retroactive use, Three I's lens, known emotional triggers lens, overhead projector transparency metaphor, responsibility vs. blame distinction, acting in/acting out cycle connection.
- **Bowtie Diagram Part 2** (video transcript) -- Redemptive Living Academy. Role-based transparency layering, spiritual lens, anticipatory use, Prayer-People-Plan framework, anticipatory living as the recovery destination.
- **RLA Tools: Bowtie MBR** (video transcript) -- Redemptive Living Academy. Big Ticket Emotions, Backbone/Life Situations processing framework, emotional needs vocabulary, practical worked example with roles and tallies, true intimacy as the antidote.
- **Bowtie_Tool.pdf** (workbook) -- Redemptive Living Academy. Visual diagram template, step-by-step guide (Identify roles -> Past 48 -> Future 48 -> Backbone -> Intimacy), Backbone/Life Situations diagram, emotional needs list, blank worksheets for practice.

### Existing Feature Documents

- `docs/prd/specific-features/bowtie/prd.md` -- Feature Requirements Document (PRD) v1.0
- `docs/specs/openapi/activities.yaml` -- OpenAPI spec for activities
- `docs/specs/mongodb/schema-design.md` -- MongoDB schema patterns

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-04-22 | Product | Initial FRD based on Bowtie Diagram Part 1 & 2 transcripts, RLA Tools Bowtie MBR transcript, and Bowtie_Tool.pdf workbook |

---

*End of Document*

Functional Requirements Document v1.0 -- Bowtie Diagram (Emotional Self-Awareness Activity)
