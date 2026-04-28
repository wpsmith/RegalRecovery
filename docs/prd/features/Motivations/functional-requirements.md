# FEATURE REQUIREMENTS DOCUMENT

**Motivations -- Personal Recovery Motivation Engine**

Recovery App Feature | Motivation Capture, Curation, Contextual Surfacing & Effectiveness Tracking

| Field | Value |
|-------|-------|
| **Version** | 1.0 |
| **Status** | Draft -- For Review |
| **Date** | April 2026 |
| **Priority** | P0 -- Core Recovery Activity |
| **Audience** | Product, Engineering, UX, Clinical Advisors, Pastoral Advisory |
| **Feature Flag** | `activity.motivations` |
| **Wave** | Wave 1 (Core P0) |
| **Source** | motivators-research.md (v1.0), motivations-engine-research.md (v1.0), SDT/MI/TTM clinical literature |
| **OMTM** | 30-day user retention rate (users who engage with motivations are retained at higher rates) |

> *PASTORAL & CLINICAL NOTICE: This feature helps users identify and stay connected to their personal reasons for recovery. It is not a substitute for professional treatment, pastoral counseling, or sponsor relationships. Motivational content surfaced by the app reflects the user's own words and selections -- the app evokes and preserves motivation; it does not prescribe it. All content involving Scripture or faith framing requires pastoral advisory review.*

---

## 1. Executive Summary

### Problem Statement

People in recovery from sexual addiction face a predictable motivational arc: early recovery is fueled by crisis energy -- fear of consequences, ultimatums, the pain of hitting bottom. That energy is intense but fragile. Between months 3 and 9, crisis motivation fades, the "pink cloud" dissipates, and recovery fatigue sets in. Without deliberate cultivation of deeper, internalized motivations, this gap becomes the highest-risk period for relapse.

Research consistently shows that **autonomous, internally driven motivation produces significantly better long-term recovery outcomes** than externally imposed motivation (SDT literature, Ryan & Deci; Project MATCH 3-year outcomes). Yet most recovery apps treat motivation as a streak counter or a daily quote -- surface-level mechanics that satisfy the need for competence feedback but fail to help users internalize their reasons for recovery.

The cost to the user: relapse during the motivational gap, loss of family trust that took months to rebuild, deepening shame that makes each subsequent recovery attempt harder. The cost is not abstract -- it is measured in marriages, in children watching a parent disappear, in the progressive erosion of identity that sexual addiction produces.

### Business Hypothesis

By providing a structured system for users to identify, curate, evolve, and contextually revisit their personal motivations -- grounded in Self-Determination Theory, Motivational Interviewing principles, and faith-based integration -- we expect to see a measurable improvement in 30-day retention (target: 2-3% increase) and a reduction in the duration of disengagement episodes following recovery fatigue onset.

### Solution Overview

Motivations is a personal recovery motivation engine that operates on a foundational principle from Motivational Interviewing: **motivation cannot be installed -- it can only be elicited, internalized, and kept visible** (Miller & Rollnick). The feature enables users to:

1. **Capture** their personal reasons for recovery through guided discovery exercises
2. **Curate** a living motivation library organized by life domain and importance
3. **Revisit** their motivations at the moments that matter most -- during urges, after difficult check-ins, at milestones, during recovery fatigue
4. **Evolve** their motivations over time as recovery matures from external fear toward integrated identity
5. **Reflect** on the relationship between their motivations and their recovery outcomes

The app is the scaffolding that keeps motivation visible. The user is always the author.

---

## 2. User Personas

### 2.1 Primary Personas

| Persona | Profile | Recovery Stage | Key Motivational Needs |
|---------|---------|----------------|------------------------|
| **Alex** | 34, married, 45 days sober. Celebrate Recovery attendee. Evangelical. Uses app daily. | Early-to-mid recovery | Wants to be the husband and father his family deserves. Needs his motivations surfaced during commute temptation. Morning commitment connected to his "why." |
| **Marcus** | 28, single, 7 days sober. Post-relapse. Deep shame. New to recovery. | Early recovery / post-relapse | Crisis-driven motivation (fear, pain). Needs gentle discovery -- not overwhelmed by exercises. Motivations must not trigger shame. Grace-based reconnection after reset. |
| **Diego** | 42, married, 200 days sober. Small group leader. Has established recovery practices. | Established recovery | Motivations have evolved from fear-based to identity-based. Wants to curate deeper spiritual motivations. Reflection on how motivations have changed over time. |
| **Sarah** | 31, single, 90 days sober. Attends SA. Trauma history. | Mid recovery | Needs trauma-sensitive motivation discovery. Some motivations are painful (family estrangement). Requires gentleness and autonomy -- never forced prompts about relationships. |

### 2.2 Anti-Persona

| Anti-Persona | Why They Are Not Served |
|---|---|
| **Casual motivational quote consumer** | This is not a daily inspirational quote app. Motivations are personal, user-authored, and recovery-specific. |
| **Gamification seeker** | Motivations do not award points, unlock levels, or feed leaderboards. Recovery motivation is not a game. |

---

## 3. Functional Requirements

### 3.1 Motivation Discovery and Capture

#### FR-M-001: Guided Motivation Discovery Exercise

The app shall provide a guided motivation discovery exercise accessible from onboarding (optional), the Motivations hub, and contextual prompts.

**Conditions of Satisfaction:**

- Given a user opens the motivation discovery exercise for the first time, When the exercise begins, Then the app displays an introductory frame: "Your recovery needs a reason that is yours -- not someone else's expectation, not a rule, but something you genuinely care about. Let's find it together."
- Given a user is in the discovery exercise, When they reach the first prompt, Then the app presents an open-ended evocative question modeled on MI technique: "If a miracle happened overnight and your addiction was gone, what would be different when you woke up?" with a free-text response field.
- Given a user completes the miracle question, When they proceed, Then the app presents a values exploration prompt: "What matters most to you in life? Choose up to 5." with a visual card-sort of 12 value categories (see FR-M-003 for categories).
- Given a user has selected values, When they proceed, Then the app presents a concrete motivation prompt for each selected value: "You chose [Family]. What specifically about your family motivates your recovery?" with a free-text response field.
- Given a user has completed all prompts, When the exercise concludes, Then the app displays a summary of captured motivations and offers: "Add to My Motivations" (saves all), "Edit first" (returns to editing), or "Save as draft" (stores but does not activate).
- Given a user exits the discovery exercise at any point, When they return later, Then progress is restored from the point of exit with no data loss.
- Given a user has already completed the discovery exercise, When they access it again, Then the app offers "Start fresh" or "Build on what you have" options.

**Priority:** P0 -- Must Have

**Clinical Rationale:** Modeled on Motivational Enhancement Therapy's brief intervention structure (Miller & Rollnick; validated in Project MATCH). The miracle question is from Solution-Focused Brief Therapy. The values card sort adapts ACT's values clarification. The sequence -- envision future, identify values, connect to concrete motivations -- mirrors MI's evoking process.

---

#### FR-M-002: Quick Motivation Capture

The app shall allow users to add individual motivations at any time without completing the full discovery exercise.

**Conditions of Satisfaction:**

- Given a user is on the Motivations hub screen, When they tap "Add Motivation," Then a capture sheet appears with fields: motivation text (required, max 500 characters), category selection (one required, see FR-M-003), importance rating (optional, see FR-M-006), optional photo attachment (one image), optional Scripture reference (free text).
- Given a user is composing a motivation, When they have entered at least the text and a category, Then the "Save" button becomes enabled.
- Given a user saves a motivation, When save completes, Then the motivation appears in their library within 500ms and the capture sheet dismisses.
- Given a user is on the Motivations hub, When they tap "Add Motivation" and then dismiss without saving, Then no data is persisted and no confirmation dialog is shown (prevent friction for casual exploration).

**Priority:** P0 -- Must Have

---

#### FR-M-003: Motivation Categories

The app shall organize motivations into life-domain categories that reflect the holistic nature of recovery.

**Categories:**

| Category | Icon (SF Symbol) | Description | Example Motivations |
|----------|-----------------|-------------|---------------------|
| **Spiritual** | `hands.and.sparkles` | Relationship with God, faith identity, spiritual growth | "I want to walk in integrity before God," "My faith is the foundation of my identity" |
| **Relational** | `heart.fill` | Marriage, family, children, friendships, trust rebuilding | "I want to be present for my kids," "My wife deserves a husband she can trust" |
| **Health** | `figure.walk` | Physical health, mental health, emotional wellbeing | "I want to sleep without guilt," "My anxiety has decreased since I've been sober" |
| **Professional** | `briefcase.fill` | Career, vocation, calling, financial stability | "I want to lead at work without a double life," "I want to be trusted with responsibility" |
| **Personal Growth** | `leaf.fill` | Character development, education, identity, self-respect | "I am becoming a man of integrity," "I want to look in the mirror without shame" |
| **Financial** | `banknote.fill` | Financial security, debt reduction, stewardship | "Recovery frees money I was wasting," "I want to provide for my family without secrets" |

**Conditions of Satisfaction:**

- Given a user is creating or editing a motivation, When they select a category, Then exactly one category is assigned per motivation.
- Given a user views their motivation library, When motivations exist in multiple categories, Then the library displays motivations grouped by category with the category icon and name as section headers.
- Given the system has 6 default categories, When a user cannot find a fitting category, Then the "Personal Growth" category serves as the catch-all -- no "Other" or "Uncategorized" label (which feels dismissive of the user's motivation).

**Priority:** P0 -- Must Have

---

#### FR-M-004: Photo Attachment for Motivations

The app shall allow users to attach a personal photo to any motivation.

**Conditions of Satisfaction:**

- Given a user is creating or editing a motivation, When they tap the photo attachment option, Then the system presents a choice: "Take Photo" (camera), "Choose from Library" (photo picker), or "Remove Photo" (if one exists).
- Given a user attaches a photo, When the motivation is saved, Then the photo is stored locally on-device, compressed to a maximum of 500KB, and encrypted at rest using iOS Data Protection.
- Given a user has a motivation with a photo, When that motivation is surfaced during an urge (FR-M-010), Then the photo is displayed prominently alongside the motivation text.
- Given a user's photo contains faces, When the photo is stored, Then no facial recognition, image analysis, or content scanning is performed. Photos are treated as opaque encrypted blobs.
- Given cloud sync is enabled for motivations, When a photo-attached motivation syncs, Then the photo is included in the encrypted sync payload. Photos are never stored unencrypted on any server.

**Priority:** P1 -- Should Have

**Clinical Rationale:** Research on motivation walls/vision boards (I Am Sober, clinical MI practice) shows that personally meaningful visual content -- photos of children, family, meaningful places -- is exponentially more motivating than text alone, especially during acute urge states when cognitive processing is impaired.

---

#### FR-M-005: Scripture Integration for Motivations

The app shall allow users to connect a Scripture reference to any motivation.

**Conditions of Satisfaction:**

- Given a user is creating or editing a motivation, When they enter a Scripture reference, Then the app accepts free-text input (e.g., "Romans 8:28", "Psalm 46:1-3") and stores it as-is without validation.
- Given a motivation has a Scripture reference, When the motivation is displayed in any context (library, crisis surfacing, reflection), Then the reference appears below the motivation text in italicized secondary text.
- Given a motivation has a Scripture reference, When the full verse text is available in the app's content database, Then the full verse text is displayed expandable below the reference. If not available, only the reference string is shown.
- Given the discovery exercise (FR-M-001) includes faith-based prompts, When a user identifies a spiritual motivation, Then the app suggests: "Is there a verse that connects to this for you?" with a skip option.

**Priority:** P0 -- Must Have

**Pastoral Rationale:** For this app's audience, Scripture is not a motivational add-on -- it is the motivational core. Faith-based motivation operates as integrated regulation in SDT terms, connecting identity, belonging, transcendent purpose, and daily accountability.

---

#### FR-M-006: Motivation Importance Rating

The app shall allow users to rate the importance of each motivation.

**Conditions of Satisfaction:**

- Given a user is creating or editing a motivation, When they set the importance rating, Then the app presents a 5-point scale with labels: "Meaningful" (1), "Important" (2), "Very Important" (3), "Core to My Recovery" (4), "Non-Negotiable" (5).
- Given a motivation has an importance rating, When motivations are surfaced during crisis moments (FR-M-010), Then higher-rated motivations are prioritized for display.
- Given a user does not set an importance rating, When the motivation is saved, Then the default importance is 3 ("Very Important") -- all motivations are treated as meaningful by default.
- Given a user changes a motivation's importance rating, When the change is saved, Then the previous rating is preserved in the motivation's history with a timestamp.

**Priority:** P1 -- Should Have

**Clinical Rationale:** Adapted from MI's importance ruler technique (0-10 scale). The follow-up question in MI -- "Why didn't you rate yourself lower?" -- evokes change talk. The app's version is simplified to 5 points with positive-only labels (no motivation is rated "unimportant").

---

#### FR-M-007: Motivation Confidence Rating

The app shall allow users to rate their confidence that a motivation will sustain them.

**Conditions of Satisfaction:**

- Given a user is viewing a motivation detail, When they tap the confidence indicator, Then the app presents a 5-point scale with labels: "Uncertain" (1), "Hopeful" (2), "Committed" (3), "Confident" (4), "Unshakeable" (5).
- Given a user sets a confidence rating, When the rating is saved, Then the previous rating is preserved in the motivation's history with a timestamp.
- Given a user rates confidence as 1 ("Uncertain") on a motivation rated importance 4-5, When the save completes, Then the app offers a gentle reflection prompt: "It sounds like this matters deeply to you, even if it feels fragile right now. Would you like to write about what makes it hard to trust?" (links to journal with pre-filled prompt). The prompt is dismissible and shown at most once per motivation per 30-day period.
- Given confidence ratings change over time, When a user views their motivation history (FR-M-015), Then confidence trends are visualized alongside importance trends.

**Priority:** P2 -- Could Have

**Clinical Rationale:** Adapted from MI's confidence ruler. The discrepancy between high importance and low confidence is a clinical signal that the motivation needs reinforcement -- through sponsor conversation, journaling, or spiritual practice.

---

### 3.2 Motivation Library and Management

#### FR-M-008: Personal Motivation Library

The app shall provide a dedicated Motivation Library view as the primary hub for all motivation-related activity.

**Conditions of Satisfaction:**

- Given a user navigates to the Motivations section, When the library loads, Then motivations are displayed grouped by category (FR-M-003) with category headers, icons, and motivation count per category.
- Given motivations exist in the library, When the user views a category group, Then motivations within each category are sorted by importance rating (highest first), then by creation date (newest first).
- Given the library contains motivations, When the user taps any motivation, Then a detail view opens showing: motivation text, category, importance rating, confidence rating (if set), Scripture reference (if set), photo (if attached), creation date, last modified date, and a "Reflect on this" button (FR-M-013).
- Given the library is empty, When the user opens the Motivations section, Then an empty state is displayed with the text: "Your recovery needs a reason that is yours. What are you fighting for?" and a prominent "Discover My Motivations" button launching FR-M-001, plus a secondary "Add one now" link for FR-M-002.
- Given the library contains motivations, When the user scrolls to the top, Then a summary bar shows total motivation count and the most recent reflection date.

**Priority:** P0 -- Must Have

---

#### FR-M-009: Motivation CRUD Operations

The app shall support full create, read, update, and delete operations for motivations.

**Conditions of Satisfaction:**

- **Create:** Covered by FR-M-001 (discovery) and FR-M-002 (quick capture).
- **Read:** Covered by FR-M-008 (library) and motivation detail view.
- **Update:** Given a user opens a motivation detail view, When they tap "Edit," Then all fields are editable: text, category, importance, confidence, Scripture reference, and photo. When saved, the previous version is preserved in history (immutable timestamps per FR2.7).
- **Delete:** Given a user opens a motivation detail view, When they tap "Delete," Then a confirmation dialog appears: "Are you sure? This motivation and its history will be permanently removed. If you are reconsidering this motivation rather than removing it, consider lowering its importance instead." On confirm, the motivation and all associated data (photo, history, reflections) are permanently deleted.
- Given a user deletes a motivation, When the deletion completes, Then the motivation is removed from all surfacing pools (crisis, check-in, reflection) within the current app session.
- Given a user edits a motivation's text, When the edit is saved, Then the `createdAt` timestamp is never modified. A `modifiedAt` timestamp is updated.

**Priority:** P0 -- Must Have

---

### 3.3 Contextual Motivation Surfacing

#### FR-M-010: Motivation Surfacing During Urge Events

The app shall surface the user's personal motivations during urge-related flows as an anchor against acting out.

**Conditions of Satisfaction:**

- Given a user has logged an urge (via urge log or SOS/FAB activation), When the urge logging flow reaches the post-submission screen, Then a "Remember Your Why" card appears displaying one motivation selected from the user's library, prioritized by: (1) importance rating (highest first), (2) motivations with photos (visual impact during cognitive impairment), (3) motivations not shown in the last 7 days (freshness).
- Given the "Remember Your Why" card is displayed, When the user taps it, Then the motivation detail view opens with the full text, photo (if any), and Scripture reference (if any). A "See more motivations" option displays up to 3 additional motivations.
- Given a user has no motivations in their library, When an urge event occurs, Then the "Remember Your Why" card is not displayed. Instead, the post-urge flow proceeds normally. No empty-state prompt is shown during a crisis moment (the user is vulnerable; do not add cognitive load).
- Given a user is in the SOS/FAB flow, When the breathing exercise completes and before the affirmation declarations begin, Then a single high-importance motivation is displayed for 5 seconds with the user's photo (if attached) as background and the text overlaid. The display is interruptible (tap to proceed).
- Given the user taps "Reach out to someone" after an urge, When the contact list appears, Then the selected motivation text is optionally pre-filled as context for the outreach message: "I'm struggling right now. Here's what I'm holding onto: [motivation text]". The user can edit or remove this before sending.

**Priority:** P0 -- Must Have

**Clinical Rationale:** Research from I Am Sober's pledge model (127M+ daily pledges, most-praised feature across consumer reviews) and MI practice demonstrates that resurfacing the user's own words at moments of vulnerability is the single most effective digital motivational intervention. The user's own "why" in their own words at the moment of temptation is worth more than any curated content.

---

#### FR-M-011: Motivation Surfacing During Low Mood and Check-In

The app shall surface motivations when check-in data indicates emotional difficulty.

**Conditions of Satisfaction:**

- Given a user completes a mood rating of 1 or 2 (out of 5), When the mood check-in confirmation screen displays, Then a compassionate motivation card appears: "Hard days are part of the journey. Here's what you told us matters most:" followed by one motivation (highest importance, category matching the likely emotional need -- relational for loneliness indicators, spiritual for despair indicators, or the highest-rated motivation as default).
- Given a user completes a FASTER Scale check-in at the "Ticked Off" or "Exhausted" stage, When the results screen displays, Then a targeted motivation card appears with framing: "You're noticing the drift. That awareness is strength. Remember:" followed by one high-importance motivation.
- Given a user completes an evening review with a day rating of 1-2, When the review concludes, Then a single motivation is displayed with the framing: "Today was hard. But your reasons haven't changed:" followed by the motivation text.
- Given contextual surfacing has occurred, When the same user completes another check-in within 4 hours, Then motivations are not surfaced again (prevent notification fatigue even within the app).

**Priority:** P0 -- Must Have

---

#### FR-M-012: Motivation Surfacing at Milestones

The app shall surface motivations at sobriety milestones as reinforcement and reflection prompts.

**Conditions of Satisfaction:**

- Given a user reaches a sobriety milestone (1, 7, 14, 30, 60, 90, 180, 365 days), When the milestone celebration screen displays, Then the celebration includes: the milestone number, a personalized message, and one motivation from the user's library with the framing: "This is what [N] days of faithfulness looks like. You said your recovery was about: [motivation text]."
- Given a user has motivations with photos, When a milestone celebration includes a motivation, Then the photo is displayed as the background of the celebration card with appropriate text overlay contrast.
- Given a milestone celebration includes a motivation, When the user taps the motivation, Then the app offers: "Has this motivation grown or changed? Update it now." linking to the motivation edit view. This supports motivational evolution per the research finding that motivations shift from external to integrated over time.
- Given a user reaches a milestone and has been in recovery for 90+ days, When the celebration screen displays, Then an additional prompt appears: "Your motivations may have deepened since day one. Would you like to revisit them?" linking to the Motivation Library.

**Priority:** P1 -- Should Have

---

#### FR-M-013: Motivation Surfacing After Sobriety Reset

The app shall surface motivations with grace-based framing after a sobriety date reset.

**Conditions of Satisfaction:**

- Given a user has reset their sobriety date, When they return to the app after the reset, Then a compassionate motivation card appears (not immediately -- after the sobriety reset message from the existing 50 grace-based messages has been shown): "Your reasons haven't changed, even if your date has. You said: [highest-importance motivation text]."
- Given the post-reset motivation card is displayed, When the user taps it, Then the full Motivation Library opens, allowing them to reconnect with all their motivations.
- Given a user has reset their sobriety date, When 24 hours have passed since the reset, Then a gentle prompt appears: "When you're ready, reconnecting with your motivations can help ground the restart. No rush." This prompt appears once and is fully dismissible.
- Given the post-reset context, When motivations are surfaced, Then no motivation framed around streak counting, days lost, or progress erased is ever displayed. The framing is always forward-looking and grace-anchored.

**Priority:** P0 -- Must Have

**Pastoral Rationale:** Aligns with the existing sobriety reset message tone ("A relapse is information, not identity"). The user's motivations persist through a reset -- the counter changes, but the reasons do not. This is a direct application of the app's core principle: "A relapse is not a failure."

---

### 3.4 Motivation Reflection and Journaling

#### FR-M-014: Motivation Reflection Prompts

The app shall provide structured reflection prompts connected to specific motivations.

**Conditions of Satisfaction:**

- Given a user views a motivation detail, When they tap "Reflect on this," Then the app opens a journal entry pre-filled with a reflection prompt. Prompts rotate from a curated set of 5 per category:
  - **Spiritual:** "How has your relationship with God strengthened your commitment to recovery this week?"
  - **Relational:** "Write about a moment this week when your recovery made a difference for someone you love."
  - **Health:** "How has your body or mind responded to your commitment to recovery?"
  - **Professional:** "How has sobriety changed the way you show up at work?"
  - **Personal Growth:** "Who are you becoming that you could not become while acting out?"
  - **Financial:** "What has recovery freed you to invest in that matters?"
- Given a user completes a motivation reflection journal entry, When the entry is saved, Then it is stored as a standard journal entry with a tag linking it to the source motivation. The entry appears in both the journal history and the motivation's reflection history.
- Given a user has written reflections on a motivation, When they view the motivation detail, Then a "Reflections" section shows the count and date of the most recent reflection with a link to view all.
- Given a user has not reflected on any motivation in 30 days, When they open the Motivations hub, Then a gentle prompt appears: "It's been a while since you sat with your motivations. Sometimes revisiting your 'why' reveals growth you didn't notice." Shown once, dismissible, not repeated for 30 days.

**Priority:** P1 -- Should Have

**Clinical Rationale:** Narrative therapy principles -- helping users build "unique outcomes" that contradict the addiction narrative. Each reflection is evidence for the recovery story. The journal prompts align with existing codebase prompt patterns (content/prompts.md Section 9: Gratitude & Hope).

---

#### FR-M-015: Motivation Evolution Timeline

The app shall track and visualize how motivations change over time.

**Conditions of Satisfaction:**

- Given a user has motivations with edit history, When they navigate to the Motivation Library and tap "My Journey," Then a chronological timeline displays: motivations added (with date), motivations edited (showing before/after text), importance rating changes, confidence rating changes, and motivations removed.
- Given a user views the evolution timeline, When entries span more than 60 days, Then the timeline includes section headers by month and a summary observation: "In [Month], you added [N] motivations in [Category]. Your focus has been shifting toward [most-changed category]."
- Given a user views the evolution timeline, When their earliest motivations were primarily in external categories (financial, professional consequences) and newer motivations are in identity/spiritual categories, Then an insight card appears: "Your motivations have been deepening -- moving from what you might lose to who you are becoming. That shift is a sign of real growth." (This maps the SDT internalization continuum from external regulation toward integrated regulation.)
- Given the evolution timeline exists, When fewer than 3 motivation events have occurred, Then the timeline is not shown (insufficient data to be meaningful). A placeholder message appears: "Your motivation story is just beginning. As you add and revisit your motivations, this view will show how your 'why' evolves."

**Priority:** P2 -- Could Have

**Clinical Rationale:** Research shows motivation migrates from external to integrated over the recovery timeline (Svendsen et al., 2017; Laudet & Stanick, 2010; Kelly et al., Commitment to Sobriety Scale). Making this migration visible reinforces it.

---

### 3.5 Motivation Effectiveness Tracking

#### FR-M-016: Post-Surfacing Effectiveness Check

The app shall track whether motivation surfacing correlates with positive recovery outcomes.

**Conditions of Satisfaction:**

- Given a motivation was surfaced during an urge event (FR-M-010), When the user does not report a relapse within 24 hours of the urge, Then the surfacing event is tagged as "held" in the motivation's effectiveness data.
- Given a motivation was surfaced during an urge event, When the user reports a relapse within 24 hours, Then the surfacing event is tagged as "did not hold" -- no judgment language is attached. This data is never shown to the user as a "failure rate."
- Given a motivation was surfaced during a low mood check-in (FR-M-011), When the user's next mood check-in (within 48 hours) shows improvement (higher rating), Then the surfacing event is tagged as "positive shift."
- Given effectiveness data has accumulated over 30+ days, When the system selects motivations for crisis surfacing, Then motivations with higher "held" rates are weighted more heavily in the selection algorithm. This is a behavioral signal, not a content analysis -- the system learns which motivations correlate with better outcomes without reading or analyzing motivation text.

**Priority:** P2 -- Could Have

**Privacy Safeguard:** Effectiveness tracking uses only behavioral signals (did relapse occur within N hours, did mood improve). No analysis is performed on motivation text content. No effectiveness data is shared with any party. All computation occurs on-device.

---

#### FR-M-017: Motivation Engagement Metrics (Personal Dashboard)

The app shall provide users with a personal view of their engagement with motivations.

**Conditions of Satisfaction:**

- Given a user navigates to the Motivations hub, When they tap "My Practice," Then a personal metrics view displays:
  - Total motivations in library
  - Motivations added this month
  - Reflections written this month
  - Times motivations were surfaced during urges this month
  - Last motivation review date
- Given the metrics view is displayed, When the user views it, Then no streak counters, comparison metrics, or judgment-laden language appears. Framing is purely informational: "This month: 12 motivations, 3 reflections, surfaced 5 times during urges."
- Given the metrics view is displayed, When the user has not engaged with motivations in 14+ days, Then a gentle observation appears: "It's been a couple weeks. Your motivations are still here when you need them." No shame. No urgency.

**Priority:** P2 -- Could Have

---

### 3.6 Integration with Existing Features

#### FR-M-018: Morning Commitment Integration

The app shall integrate motivations into the morning commitment flow.

**Conditions of Satisfaction:**

- Given a user has motivations in their library, When they complete the morning sobriety commitment, Then the confirmation screen includes one motivation as reinforcement: "Today, remember: [motivation text]." The motivation rotates daily (round-robin by importance, no repeat within 7 days unless library has fewer than 7 motivations).
- Given the morning commitment displays a motivation, When the user taps it, Then the motivation detail view opens.
- Given a user has no motivations, When they complete the morning commitment, Then no motivation is displayed and no prompt to add one appears (the commitment is complete on its own terms).

**Priority:** P1 -- Should Have

---

#### FR-M-019: Evening Review Integration

The app shall integrate motivations into the evening review flow.

**Conditions of Satisfaction:**

- Given a user completes the evening review, When the review's reflection step is reached, Then an optional prompt appears: "Did your motivations come to mind today? Were they a source of strength?" with response options: "Yes, they helped" / "I forgot about them" / "They felt distant" / "Skip."
- Given a user selects "They felt distant," When the response is recorded, Then the app offers: "That's honest -- and important to notice. Would you like to revisit your motivations tomorrow morning?" If confirmed, the next morning commitment includes a motivation refresh prompt.
- Given a user selects "Yes, they helped," When the response is recorded, Then the app responds: "That's the practice working. Your reasons are becoming part of who you are."

**Priority:** P1 -- Should Have

---

#### FR-M-020: Journal Integration

The app shall connect motivations to the journaling system.

**Conditions of Satisfaction:**

- Given the journal prompt system rotates prompts, When a user has motivations in their library, Then motivations-specific prompts are added to the rotation pool:
  - "Write about why [highest-importance motivation] matters to you today."
  - "Your motivations brought you to recovery. Which one feels strongest right now? Which feels weakest? Write about both."
  - "Describe a moment this week when your motivations kept you grounded."
  - "What would you tell someone on day one about why recovery is worth it?"
  - "Write a letter to the person you are becoming -- the man your motivations describe."
- Given a user writes a journal entry from a motivations prompt, When the entry is saved, Then it is tagged with the source motivation (if applicable) and appears in both the journal and the motivation's reflection history.

**Priority:** P1 -- Should Have

---

#### FR-M-021: Affirmations Integration

The app shall connect motivations to the Declarations of Truth (Affirmations) feature.

**Conditions of Satisfaction:**

- Given a user has motivations in the "Personal Growth" or "Spiritual" categories, When they create a custom affirmation/declaration pack, Then the app suggests: "Would you like to create declarations from your motivations?" If confirmed, each selected motivation is pre-formatted as a declaration draft: "I am [motivation rephrased as identity statement]."
- Given motivations exist, When the morning affirmation session completes, Then the Daily Intention prompt optionally pre-fills with a motivation-derived suggestion: "Today, empowered by the Spirit, I choose to [action connected to a motivation]." The user can edit or replace.

**Priority:** P2 -- Could Have

---

#### FR-M-022: FASTER Scale Integration

The app shall surface targeted motivations when FASTER Scale check-ins indicate drift.

**Conditions of Satisfaction:**

- Given a user completes a FASTER Scale check-in, When the result indicates the "Speeding Up" stage or beyond, Then a motivation card appears on the results screen: "Your recovery FASTER Scale is showing drift. Ground yourself in your reason:" followed by one high-importance motivation.
- Given FASTER Scale results show the "Relapse/Reuse" stage, When the results screen displays, Then motivations are NOT surfaced (the user is in crisis -- route to SOS/FAB and grace-based support first; motivations surface post-crisis per FR-M-013).

**Priority:** P1 -- Should Have

---

#### FR-M-023: Three Circles Integration

The app shall connect motivations to the Three Circles recovery plan.

**Conditions of Satisfaction:**

- Given a user is viewing their Three Circles outer circle behaviors, When they tap an outer circle item, Then an option appears: "Connect a motivation -- why does this healthy behavior matter to you?" If a motivation is linked, it appears on the outer circle item detail view.
- Given a user views the Three Circles pattern dashboard, When a period of sustained outer circle living is highlighted, Then the app surfaces: "During your best weeks, your motivations were [list]. Keep them close."

**Priority:** P2 -- Could Have

---

#### FR-M-024: Post-Mortem Analysis Integration

The app shall integrate motivations into the post-mortem (relapse analysis) flow.

**Conditions of Satisfaction:**

- Given a user is completing a post-mortem analysis after a relapse, When the reflection section is reached, Then a prompt appears: "Before the relapse, how connected did you feel to your motivations?" with options: "Very connected" / "Somewhat" / "Disconnected" / "I forgot about them."
- Given the post-mortem is complete, When the summary screen displays, Then the app offers: "Reconnect with your motivations. Your reasons are still true:" followed by a link to the Motivation Library.
- Given the post-mortem records a disconnection from motivations, When the analysis is stored, Then this data point contributes to pattern insights (FR-M-015 evolution timeline): motivation disconnection preceding relapse is a pattern worth surfacing in future FASTER Scale check-ins.

**Priority:** P1 -- Should Have

---

### 3.7 Motivation Sharing and Accountability

#### FR-M-025: Accountability Partner Motivation Sharing

The app shall allow users to share selected motivations with accountability partners.

**Conditions of Satisfaction:**

- Given a user has an accountability partner configured, When they navigate to a motivation detail view, Then a "Share with [Partner Name]" option appears.
- Given a user taps share, When the sharing dialog appears, Then the user explicitly selects which motivations to share (opt-in per motivation, never bulk). A preview shows exactly what the partner will see.
- Given motivations are shared with a partner, When the partner views the shared data, Then they see: motivation text, category, and importance rating only. Photos, journal reflections, confidence ratings, and Scripture references are NOT shared unless the user explicitly includes them.
- Given shared motivations exist, When the accountability partner views the user's profile, Then shared motivations appear in a "Their Motivations" section with the framing: "These are the reasons [User] has shared with you. You can encourage them around these."
- Given a user has shared motivations, When they revoke sharing, Then the motivations are immediately removed from the partner's view.

**Priority:** P2 -- Could Have

---

### 3.8 Motivation Periodic Review

#### FR-M-026: Quarterly Motivation Review

The app shall prompt users to review and evolve their motivations periodically.

**Conditions of Satisfaction:**

- Given 90 days have passed since the user's last motivation review (or since initial creation if no review has occurred), When the user opens the app, Then a gentle prompt appears: "Your recovery grows, and so do your reasons. Would you like to revisit your motivations?" with options: "Review now" / "Remind me later" / "I'm good."
- Given a user selects "Review now," When the review flow begins, Then each motivation is presented one at a time with options: "Still true" (keep as-is), "Update" (edit text/importance/confidence), "Archive" (remove from active library but preserve in history), and "Remove" (delete permanently).
- Given a user completes the quarterly review, When the review concludes, Then a summary screen shows: motivations kept, updated, archived, and removed, with the framing: "Your motivations are evolving with your recovery. That's exactly how it should work."
- Given the quarterly prompt is shown, When the user selects "Remind me later," Then the prompt reappears in 7 days. If dismissed again, it does not reappear for another 90 days.
- Given a user is in the first 30 days of recovery, When 90 days have not yet elapsed, Then no quarterly review prompt is shown. Early recovery users should not be asked to question their motivations -- they need stability.

**Priority:** P1 -- Should Have

**Clinical Rationale:** Recovery is a motivational migration (Svendsen et al., 2017). Motivations that bring someone to day one are not the motivations that sustain year one. Periodic review supports the internalization process -- the gradual shift from "I have to" toward "This is who I am."

---

### 3.9 Offline and Data Requirements

#### FR-M-027: Offline-First Operation

All motivation features shall function fully offline.

**Conditions of Satisfaction:**

- Given the device has no internet connection, When a user creates, edits, or deletes a motivation, Then the operation completes locally via SwiftData within 200ms.
- Given the device has no internet connection, When motivations are surfaced during an urge or check-in, Then the surfacing operates from the local SwiftData store with no degradation.
- Given the device has no internet connection, When a user attaches a photo to a motivation, Then the photo is stored locally and queued for sync when connectivity returns.
- Given the device regains internet connectivity, When the SyncEngine detects the connection, Then motivation changes are synced to the backend using the standard sync protocol (union merge for new motivations, last-write-wins for edits, immediate propagation for deletes).

**Priority:** P0 -- Must Have

---

#### FR-M-028: Local Data Persistence

The app shall persist all motivation data using SwiftData.

**Conditions of Satisfaction:**

- Given the SwiftData schema, When the Motivation model is defined, Then it includes the following fields:
  - `id: UUID` (primary key)
  - `userId: String` (tenant isolation)
  - `text: String` (motivation content, max 500 characters)
  - `category: MotivationCategory` (enum, one of 6 categories)
  - `importanceRating: Int` (1-5, default 3)
  - `confidenceRating: Int?` (1-5, optional)
  - `scriptureReference: String?` (optional, free text)
  - `photoLocalPath: String?` (optional, local file path to encrypted photo)
  - `isArchived: Bool` (default false)
  - `createdAt: Date` (immutable after creation)
  - `modifiedAt: Date` (updated on every edit)
  - `lastSurfacedAt: Date?` (updated when surfaced during urge/check-in)
  - `surfaceCount: Int` (incremented on each surfacing, default 0)
  - `reflectionCount: Int` (incremented on each linked journal entry, default 0)
  - `source: MotivationSource` (enum: discovery, manual, import)
  - `syncStatus: SyncStatus` (enum: synced, pending, conflict)
- Given the SwiftData schema includes Motivation, When the app launches, Then the model is registered with the shared ModelContainer.
- Given motivation data exists, When the user deletes the app and reinstalls, Then local data is lost unless cloud sync was enabled. This is expected behavior consistent with offline-first architecture.

**Priority:** P0 -- Must Have

---

#### FR-M-029: Motivation History Model

The app shall persist motivation change history for evolution tracking.

**Conditions of Satisfaction:**

- Given the SwiftData schema, When the MotivationHistory model is defined, Then it includes:
  - `id: UUID` (primary key)
  - `motivationId: UUID` (foreign key to Motivation)
  - `changeType: MotivationChangeType` (enum: created, textEdited, importanceChanged, confidenceChanged, categoryChanged, photoAdded, photoRemoved, archived, restored, deleted)
  - `previousValue: String?` (serialized previous state for the changed field)
  - `newValue: String?` (serialized new state)
  - `timestamp: Date` (immutable)
- Given a user edits any field on a motivation, When the edit is saved, Then a MotivationHistory record is created atomically in the same SwiftData transaction.

**Priority:** P1 -- Should Have

---

#### FR-M-030: Motivation Surfacing Event Model

The app shall persist records of when and where motivations were surfaced.

**Conditions of Satisfaction:**

- Given the SwiftData schema, When the MotivationSurfacingEvent model is defined, Then it includes:
  - `id: UUID` (primary key)
  - `motivationId: UUID` (foreign key to Motivation)
  - `context: SurfacingContext` (enum: urgeLog, sosFlow, moodCheckIn, fasterScale, eveningReview, milestone, sobrietyReset, morningCommitment, postMortem)
  - `timestamp: Date` (immutable)
  - `userInteracted: Bool` (true if user tapped/expanded the motivation, false if dismissed/ignored)
  - `outcome: SurfacingOutcome?` (enum: held, didNotHold, positiveShift, neutral -- populated asynchronously based on subsequent user behavior per FR-M-016)
- Given a surfacing event is created, When the record is stored, Then `createdAt` is immutable per FR2.7.

**Priority:** P2 -- Could Have

---

### 3.10 Calendar Activity Integration

#### FR-M-031: Calendar Activity Dual-Write

The app shall record motivation-related activities in the calendar activity system.

**Conditions of Satisfaction:**

- Given a user completes the motivation discovery exercise (FR-M-001), When the exercise saves, Then a calendar activity is written: type "motivations," subtype "discovery."
- Given a user completes a motivation reflection journal entry (FR-M-014), When the entry saves, Then a calendar activity is written: type "motivations," subtype "reflection."
- Given a user completes a quarterly motivation review (FR-M-026), When the review saves, Then a calendar activity is written: type "motivations," subtype "review."
- Given calendar activities are written, When the user views their Today screen or activity history, Then motivation activities appear alongside other recovery activities with the Motivations icon.

**Priority:** P1 -- Should Have

---

## 4. Non-Functional Requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-M-001 | Feature flag `activity.motivations` fail-closed | Feature returns 404 / is hidden when flag is disabled |
| NFR-M-002 | Immutable timestamps (FR2.7) | `createdAt` is never modified on motivation, history, or surfacing records |
| NFR-M-003 | Calendar activity dual-write | Every completed motivation activity writes to `calendarActivities` |
| NFR-M-004 | No streak counters | Zero streak-based metrics for motivations anywhere in code, UI, or notifications |
| NFR-M-005 | Offline-first | All motivation CRUD, surfacing, and reflection functions work fully offline |
| NFR-M-006 | Privacy: no text analytics | The system never analyzes, classifies, or processes the text content of motivations. All personalization uses behavioral signals only (importance rating, surfacing outcome, engagement frequency). |
| NFR-M-007 | Privacy: photos encrypted at rest | All motivation photos are encrypted using iOS Data Protection (AES-256) |
| NFR-M-008 | Privacy: sharing opt-in | No motivation data is shared with any partner, sponsor, therapist, or external party without explicit per-motivation user consent |
| NFR-M-009 | Performance: library load | Motivation library loads in < 500ms (cached), < 1s (cold) |
| NFR-M-010 | Performance: crisis surfacing | Motivation surfacing during SOS/FAB flow completes in < 300ms from trigger event |
| NFR-M-011 | Performance: photo display | Motivation photos render in < 200ms from local storage |
| NFR-M-012 | Notification text safety | All motivation-related notifications use generic language that does not reveal recovery context. Example: "A moment to reflect" -- never "Remember your recovery motivation" |
| NFR-M-013 | Accessibility: VoiceOver | All motivation screens are fully VoiceOver-accessible. Motivations read as: "Motivation: [text]. Category: [category]. Importance: [rating]." Photos have alt text: "Personal motivation photo." |
| NFR-M-014 | Accessibility: Dynamic Type | All motivation text scales from smallest to largest system text size. Cards reflow correctly at all sizes. |
| NFR-M-015 | Accessibility: touch targets | All interactive elements (edit, delete, reflect, share, importance selector) meet minimum 44x44pt |
| NFR-M-016 | Accessibility: color independence | Category colors are never the sole indicator of meaning. Each category also has a distinct icon and text label. |
| NFR-M-017 | Reading level | All UI text, prompts, and guidance at 8th-grade reading level maximum |
| NFR-M-018 | Tone: grace over shame | Every user-facing string passes a compassion review. No string implies judgment for missing, ignoring, or changing motivations. |
| NFR-M-019 | Test coverage | >= 80% overall; 100% on surfacing algorithm, privacy controls, and offline sync |
| NFR-M-020 | Trauma-informed language | No UI text uses: "failure," "weak," "addict," "clean/dirty," "should," "must." Reviewed by clinical advisor. |
| NFR-M-021 | Data deletion | Full motivation data export + deletion within 30 days on GDPR/CCPA request, including photos, history, and surfacing events |

---

## 5. Technical Considerations

### 5.1 Architecture Overview

```
MotivationsView (SwiftUI)
    |
    v
MotivationsViewModel (@Observable)
    |
    v
MotivationRepository (Protocol)
    |
    v
SwiftDataMotivationRepository (Implementation)
    |
    v
SwiftData ModelContainer (RRMotivation, RRMotivationHistory, RRMotivationSurfacingEvent)
    |
    v
SyncEngine (queues changes for backend sync when online)
```

### 5.2 SwiftData Models

**RRMotivation** -- Primary motivation entity
**RRMotivationHistory** -- Append-only change log
**RRMotivationSurfacingEvent** -- Append-only surfacing records

See FR-M-028, FR-M-029, FR-M-030 for field specifications.

### 5.3 Surfacing Algorithm

The motivation surfacing algorithm selects which motivation to display in a given context:

```
Input: context (urge, mood, milestone, reset), user's motivation library
Output: 1-3 motivations to display

1. Filter: exclude archived motivations
2. Filter: exclude motivations surfaced within the last 24 hours (freshness)
3. Score each remaining motivation:
   - importanceRating * 3.0 (highest weight)
   - hasPhoto ? 2.0 : 0.0 (visual impact during cognitive impairment)
   - daysSinceLastSurfaced * 0.1 (freshness bonus, capped at 3.0)
   - effectivenessRate * 1.5 (if FR-M-016 data available)
   - categoryMatch(context) ? 1.0 : 0.0 (context relevance)
4. Sort by score descending
5. Select top N (1 for crisis, up to 3 for library browsing)
6. If all motivations were recently surfaced, relax the 24-hour filter
7. Record surfacing event (FR-M-030)
```

**Context-category matching:**
- Urge event: prioritize Relational, Spiritual
- Low mood: prioritize Spiritual, Health
- FASTER drift: prioritize Personal Growth, Spiritual
- Milestone: prioritize the category with the most motivations (user's focus area)
- Sobriety reset: prioritize Spiritual, Relational (grace and connection)

All computation occurs on-device. No server calls for surfacing decisions.

### 5.4 Photo Storage

- Photos stored in the app's encrypted documents directory
- File naming: `motivation_{motivationId}.jpg`
- Compressed to max 500KB using JPEG compression at 0.7 quality
- Encrypted at rest via iOS Data Protection (NSFileProtectionCompleteUntilFirstUserAuthentication)
- Thumbnails generated at 150x150 for library grid view
- Full-size loaded on-demand for detail view and crisis surfacing

### 5.5 Sync Conflict Resolution

Per the project's established sync patterns:
- **New motivations:** Union merge (both sides keep their additions)
- **Edits:** Last-write-wins based on `modifiedAt` timestamp
- **Deletes:** Immediate propagation (delete wins over edit)
- **Photos:** Included in sync payload, encrypted in transit (TLS 1.3)

### 5.6 Feature Flag

- Flag key: `activity.motivations`
- Fail closed: when disabled, the Motivations section is hidden from navigation
- When disabled, contextual surfacing (FR-M-010 through FR-M-013) is also suppressed
- Existing features (urge log, check-in, morning commitment) continue to function normally without motivation surfacing

---

## 6. User Journeys

### 6.1 Journey: First-Time Discovery (Alex, Day 45)

```
Alex opens the app → navigates to Work tab → sees "Motivations" in activity list
  → Taps → Empty state: "What are you fighting for?"
  → Taps "Discover My Motivations"
  → Introduction: "Your recovery needs a reason that is yours..."
  → Miracle Question: "If a miracle happened overnight..."
    → Alex writes: "I would wake up without the weight of a secret life.
       My wife would trust me. My kids would have a father who is present."
  → Values Card Sort: Alex selects Relational, Spiritual, Personal Growth
  → Concrete prompts:
    → Relational: "My daughter deserves a father who keeps his promises."
      → Attaches a photo of his daughter's birthday
      → Scripture: "Train up a child in the way he should go (Prov 22:6)"
    → Spiritual: "I want to walk in integrity before God."
      → Scripture: "Create in me a clean heart, O God (Psalm 51:10)"
    → Personal Growth: "I am becoming a man of integrity."
  → Summary: 3 motivations captured → "Add to My Motivations"
  → Library now shows 3 motivations organized by category
  → Calendar activity recorded: "Motivation Discovery completed"
```

### 6.2 Journey: Urge Surfacing (Alex, Day 52, commute)

```
Alex sitting in car in parking lot → urge rises → taps SOS FAB
  → Breathing exercise (30 seconds)
  → After breathing: Alex's daughter's photo fills the screen
    "My daughter deserves a father who keeps his promises."
    (5 seconds, interruptible)
  → Affirmation declarations begin (Level 2)
  → After session: "Reach out to someone" → selects sponsor
    → Pre-filled: "I'm struggling right now. Holding onto:
       My daughter deserves a father who keeps his promises."
    → Alex edits and sends
  → Surfacing event recorded: context=sosFlow, motivationId=..., userInteracted=true
```

### 6.3 Journey: Post-Reset Reconnection (Marcus, Day 1 reset)

```
Marcus reports sobriety reset
  → Sobriety reset message #7 displays:
    "Peter denied Jesus three times and became the rock of the church.
     Your story isn't over. Not even close."
  → After reset message: motivation card appears:
    "Your reasons haven't changed, even if your date has.
     You said: 'I don't want to be controlled by something
     that makes me hate myself.'"
  → Marcus taps the card → Motivation Library opens
  → He reads through his 4 motivations → pauses on one → taps "Reflect"
  → Journal entry opens with prompt: "Who are you becoming
     that you could not become while acting out?"
  → Marcus writes a paragraph → saves
  → 24 hours later: "When you're ready, reconnecting with your
     motivations can help ground the restart. No rush."
```

### 6.4 Journey: Quarterly Review (Diego, Day 200)

```
Diego opens app → prompt: "Your recovery grows, and so do your reasons.
   Would you like to revisit your motivations?"
  → Taps "Review now"
  → Motivation 1: "I don't want to lose my marriage."
    → Diego reflects: this was his day-one motivation, driven by fear.
       Now it feels different. He taps "Update."
    → Changes to: "I am building a marriage worthy of the trust
       my wife has placed in me."
    → Importance: changes from 5 to 5 (still non-negotiable)
    → Confidence: changes from 2 to 4
  → Motivation 2: "I want to stop lying."
    → Diego taps "Archive" — this has been internalized.
       Honesty is now who he is, not a motivation he needs to see.
  → Motivation 3: "I want to mentor other men in recovery."
    → This is new. Diego adds it via "Add Motivation" during review.
    → Category: Personal Growth. Importance: 4.
  → Review complete: Summary shows 1 updated, 1 archived, 1 added.
    "Your motivations are evolving with your recovery.
     That's exactly how it should work."
  → Evolution timeline now shows the shift from fear-based
     to identity-based motivation.
```

### 6.5 Journey: Low Mood Check-In (Sarah, Day 90)

```
Sarah completes evening review → day rating: 2/5
  → Motivation card appears: "Today was hard.
     But your reasons haven't changed:"
    "I want to be free from the shame that controlled me for years."
    — Psalm 34:18
  → Sarah taps the card → views detail → taps "Reflect on this"
  → Journal opens with prompt: "How has your body or mind responded
     to your commitment to recovery?"
  → Sarah writes about how her anxiety has lessened even though
     today was hard → saves
  → Surfacing event recorded: context=eveningReview,
     motivationId=..., userInteracted=true
```

---

## 7. Analytics & Tracking

### 7.1 Product Analytics Events

All events are anonymized. No motivation text, custom content, Scripture references, or personal data in analytics. Opt-out available.

| Event | Properties | Purpose |
|-------|------------|---------|
| `motivation.discovery.started` | `entryPath` (onboarding/hub/prompt) | Discovery funnel entry |
| `motivation.discovery.completed` | `motivationCount`, `categoriesUsed[]`, `durationSeconds` | Discovery completion rate |
| `motivation.discovery.abandoned` | `stepAbandoned`, `durationSeconds` | Discovery drop-off analysis |
| `motivation.created` | `source` (discovery/manual), `category`, `hasPhoto`, `hasScripture`, `importanceRating` | Motivation creation patterns |
| `motivation.edited` | `fieldsChanged[]` | Edit frequency and patterns |
| `motivation.deleted` | `ageInDays`, `category` | Deletion patterns |
| `motivation.archived` | `ageInDays`, `category` | Archive patterns (internalization signal) |
| `motivation.surfaced` | `context` (urge/mood/faster/milestone/reset/morning/evening), `category`, `hasPhoto` | Surfacing frequency by context |
| `motivation.surfaced.interacted` | `context`, `interactionType` (tapped/expanded/reflected/dismissed) | Surfacing engagement |
| `motivation.reflection.started` | `category` | Reflection engagement |
| `motivation.reflection.completed` | `category`, `wordCount` (bucketed: short/medium/long), `durationSeconds` | Reflection depth |
| `motivation.review.started` | `motivationCount` | Review engagement |
| `motivation.review.completed` | `kept`, `updated`, `archived`, `removed` | Review outcomes |
| `motivation.sharing.initiated` | `partnerType` (ap/sponsor/therapist) | Sharing adoption |
| `motivation.library.viewed` | `motivationCount`, `viewDurationSeconds` | Library engagement |

### 7.2 Key Product Metrics (KPIs)

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Discovery completion rate** | > 65% | Users completing discovery / users starting discovery |
| **Motivations per user (30-day active)** | >= 3 | Average motivations in library for users active 30+ days |
| **Surfacing engagement rate** | > 40% | Surfacing events where user interacted / total surfacing events |
| **Monthly reflection rate** | > 20% | Users writing at least 1 motivation reflection per month / active users with motivations |
| **Quarterly review completion** | > 30% | Users completing quarterly review / users prompted |
| **Retention impact** | +2-3% | 30-day retention for users with 3+ motivations vs. users with 0 |
| **Post-urge non-relapse correlation** | Positive | Users who interacted with motivation during urge vs. those who did not, controlling for urge intensity |
| **Photo attachment rate** | > 25% | Motivations with photos / total motivations |
| **Scripture attachment rate** | > 40% | Motivations with Scripture / total motivations |
| **Evolution signal** | Track | Users whose motivation categories shift from external (Financial, Professional) to internal (Spiritual, Personal Growth) over 6 months |

---

## 8. Accessibility Requirements

### 8.1 Standards

- **WCAG 2.1 AA** compliance minimum across all motivation screens
- **Section 508** compliance for US federal accessibility

### 8.2 Detailed Requirements

| Area | Requirement | Priority |
|------|-------------|----------|
| **Screen Reader** | VoiceOver full support. Motivations read as: "Motivation: [text]. Category: [category]. Importance: [rating] of 5. Double tap to view details." | P0 |
| **Dynamic Type** | All text scales from xSmall to AX5. Motivation cards reflow from horizontal to vertical layout at larger sizes. | P0 |
| **Touch Targets** | Minimum 44x44pt for all interactive elements: edit, delete, reflect, share, importance stars, category selector, photo picker. | P0 |
| **Color** | Color never sole indicator of category or importance. Each category has icon + text label. Importance uses filled/unfilled indicators + numeric label. | P0 |
| **High Contrast** | Full support for increased contrast mode. Category colors adjust for minimum 4.5:1 contrast ratio. | P1 |
| **Reduced Motion** | Respects "Reduce Motion" setting. Card transitions become instant. Photo zoom disabled. No parallax effects. | P1 |
| **Keyboard Navigation** | Full keyboard navigation for iPad with external keyboard. Tab order follows visual layout. | P1 |
| **Photo Alt Text** | All motivation photos labeled as "Personal motivation photo" for screen readers. No image analysis for alt text generation. | P0 |
| **Reading Level** | All UI text at 8th-grade reading level maximum. Discovery prompts reviewed for clarity and simplicity. | P0 |

---

## 9. Premium vs. Free Tier Boundaries

| Feature | Free Tier | Premium Tier |
|---------|-----------|-------------|
| Motivation discovery exercise | Full access | Full access |
| Quick motivation capture | Full access | Full access |
| Motivation library (up to 10) | Full access | N/A |
| Motivation library (unlimited) | N/A | Full access |
| Photo attachments | Up to 3 photos | Unlimited |
| Scripture integration | Full access | Full access |
| Importance/confidence ratings | Full access | Full access |
| Crisis surfacing (urge, SOS) | Full access | Full access |
| Check-in surfacing (mood, FASTER) | Full access | Full access |
| Milestone surfacing | Full access | Full access |
| Post-reset surfacing | Full access | Full access |
| Morning/evening integration | Full access | Full access |
| Motivation reflection journaling | Full access | Full access |
| Evolution timeline | Not available | Full access |
| Effectiveness tracking | Not available | Full access |
| Quarterly review prompts | Full access | Full access |
| Accountability partner sharing | Not available | Full access |
| Personal engagement metrics | Not available | Full access |

**Design Principle:** The core motivational engine -- capture, surfacing during crisis, and basic management -- is always free. Recovery motivation should never be paywalled. Premium unlocks deeper analytics, evolution tracking, and social features that enhance the experience but are not required for the feature's therapeutic value.

---

## 10. Integrations

### 10.1 Internal App Integrations

| System | Integration Type | Direction | Details |
|--------|-----------------|-----------|---------|
| **Urge Log** | Crisis surfacing | Read (motivations) → Write (surfacing event) | After urge submission, surface highest-importance motivation. See FR-M-010. |
| **SOS/FAB Flow** | Crisis surfacing | Read → Write | After breathing exercise, display motivation with photo before affirmations. See FR-M-010. |
| **Mood Check-In** | Contextual surfacing | Read → Write | On low mood (1-2/5), surface targeted motivation. See FR-M-011. |
| **FASTER Scale** | Drift alert | Read → Write | On "Speeding Up" or beyond, surface motivation. See FR-M-022. |
| **Morning Commitment** | Reinforcement | Read | After commitment, display one rotating motivation. See FR-M-018. |
| **Evening Review** | Reflection prompt | Read → Write | After review, prompt about motivation connection. See FR-M-019. |
| **Journal** | Content bridge | Write | Motivation reflections stored as tagged journal entries. See FR-M-020. |
| **Affirmations** | Content bridge | Read | Motivations can seed custom declaration packs. See FR-M-021. |
| **Three Circles** | Behavioral linking | Read → Write | Outer circle items linkable to motivations. See FR-M-023. |
| **Post-Mortem** | Reflection prompt | Read → Write | Post-relapse reconnection to motivations. See FR-M-024. |
| **Milestones** | Celebration enrichment | Read | Milestone celebrations include motivation. See FR-M-012. |
| **Sobriety Reset** | Grace-based reconnection | Read | Post-reset, surface motivations with forward-looking framing. See FR-M-013. |
| **Calendar Activity** | Dual-write | Write | Discovery, reflection, review activities recorded. See FR-M-031. |
| **Feature Flags** | Gating | Read | `activity.motivations` controls visibility. Fail closed. |
| **Vision Statement** | Complementary | Read | Vision statement and motivations are distinct but related. Vision = identity aspiration ("I am becoming..."). Motivations = reasons for recovery ("I fight for..."). Link from motivation library to vision hub if vision exists. |

### 10.2 External Integrations

| System | Integration | Details |
|--------|------------|---------|
| **Photo Library** | PHPickerViewController | Read-only photo selection. No camera roll write access. |
| **Camera** | AVCaptureSession | Optional camera capture for motivation photos. |
| **Crisis Resources** | Deep links | If motivation surfacing during SOS does not de-escalate, crisis resources (988, SAMHSA) remain accessible. |

---

## 11. Out of Scope (v1)

- AI-generated motivation suggestions based on journal analysis (Phase 2 -- premium chatbot feature)
- Community-sourced anonymous motivations ("Others fighting for the same reasons")  (Phase 3)
- Motivation-based notification scheduling ("Your daughter's school pickup is in 1 hour -- stay grounded") (Phase 2)
- Video recording attached to motivations (Phase 2)
- Spouse/partner view of shared motivations in their own app (Phase 3 -- requires partner app)
- Motivational Interviewing chatbot that conducts full MI sessions (Phase 4 -- recovery agent feature)
- Predictive motivation lull detection via ML (Phase 2)
- Motivation content packs (curated themed motivation sets for purchase) (Phase 2)
- Widget displaying daily motivation on home screen (Phase 2)
- Stage-of-change detection that auto-adjusts motivational content type (Phase 2)

---

## 12. Dependencies

| Dependency | Status | Blocks |
|------------|--------|--------|
| Sobriety counter (days sober, reset events) | Wave 1 -- In progress | Milestone surfacing (FR-M-012), post-reset surfacing (FR-M-013) |
| Urge reporting (urge log, SOS/FAB flow) | Wave 1 -- In progress | Crisis surfacing (FR-M-010) |
| FASTER Scale (stage detection) | Wave 1 -- Implemented | FASTER integration (FR-M-022) |
| Journal (entry creation, tagging) | Wave 1 -- In progress | Reflection journaling (FR-M-014, FR-M-020) |
| Mood tracking (rating system) | Wave 1 -- Implemented | Low mood surfacing (FR-M-011) |
| Morning commitment flow | Wave 1 -- Implemented | Morning integration (FR-M-018) |
| Evening review flow | Wave 1 -- Implemented | Evening integration (FR-M-019) |
| Calendar activity dual-write | Wave 0 -- Complete | Activity recording (FR-M-031) |
| Feature flag infrastructure | Wave 0 -- Complete | Feature gating |
| SwiftData model container | Wave 0 -- Complete | Local persistence (FR-M-028) |
| SyncEngine | Wave 1 -- In progress | Offline sync (FR-M-027) |
| Post-mortem analysis | Wave 2 -- Not started | Post-mortem integration (FR-M-024) -- non-blocking |
| Accountability partner system | Wave 2 -- Not started | Sharing (FR-M-025) -- non-blocking |
| Three Circles | Wave 1 -- Implemented | Three Circles integration (FR-M-023) -- non-blocking |
| Affirmations | Wave 1 -- Implemented | Affirmations integration (FR-M-021) -- non-blocking |
| Vision Statement | Wave 1 -- Implemented | Complementary link -- non-blocking |

---

## 13. Success Criteria

| Criteria | Measurement | Target |
|----------|-------------|--------|
| Feature adopted by active users | Users with 1+ motivations / active users | > 50% within 60 days of GA |
| Discovery exercise completion | Completion rate | > 65% |
| Average motivations per engaged user | Mean library size for users with 1+ | >= 3 |
| Crisis surfacing engagement | Interactions / surfacings during urge events | > 40% |
| Retention impact | 30-day retention with vs without motivations | > 2% improvement |
| Reflection depth | Users writing 1+ reflection per month | > 20% of users with motivations |
| Quarterly review participation | Completed reviews / prompted | > 30% |
| Photo attachment rate | Motivations with photos / total | > 25% |
| Scripture attachment rate | Motivations with Scripture / total | > 40% |
| Zero privacy incidents | Privacy breach count | 0 |
| Accessibility audit | WCAG 2.1 AA violations | 0 critical, < 5 minor |
| Compassion audit | User-reported feeling of judgment or shame from motivations feature | 0 reports |

---

## 14. Open Questions

1. **Discovery exercise timing:** Should the discovery exercise be offered during onboarding (adding to an already-loaded flow) or deferred to the first week of app use? Research suggests onboarding is already emotionally heavy (Three Circles builder, account setup, recovery date). Recommendation: offer a lightweight "What's your biggest motivation?" single-field capture during onboarding, with the full discovery exercise available from the Motivations hub after Day 3.

2. **Motivation-to-motivation relationships:** Should users be able to link motivations to each other (e.g., "My daughter" links to "Being a present father" links to "Walking in integrity before God")? This creates a motivation graph that could be powerful for understanding motivational architecture but adds complexity.

3. **Notification delivery of motivations:** Should the app ever push a notification containing a user's motivation text? Risk: if the phone is visible to others, a notification saying "Remember: my wife deserves a husband she can trust" could expose recovery context. Recommendation: notifications should be generic ("A moment to reflect") and motivations only displayed after the user opens the app.

4. **Motivation archiving vs. deletion semantics:** When a user archives a motivation (e.g., "I don't want to lose my marriage" evolves into an internalized identity), should the archived motivation still appear in the evolution timeline? Recommendation: yes -- archived motivations are part of the recovery story and should be visible in the timeline as "internalized" milestones.

5. **Cross-device motivation sync priority:** If a user has the app on two devices and creates different motivations on each while offline, the union merge strategy means both sets are preserved. Should there be a deduplication check (fuzzy text matching) or is duplication acceptable? Recommendation: accept duplication and let the user manage it -- false positive deduplication could delete a meaningful motivation.

6. **Integration depth with Vision Statement:** The Vision Statement feature captures identity aspirations ("I am becoming...") which overlaps conceptually with Personal Growth motivations. Should motivations auto-populate from vision statement values, or remain fully independent? Recommendation: independent with a cross-link. The vision is the destination; motivations are the fuel.

---

## 15. Design Principles for Motivations

These principles govern every design and engineering decision for this feature:

1. **The user is the author.** The app evokes and preserves motivation; it never prescribes it. No pre-written motivations are offered as content to adopt. The discovery exercise asks questions; the user writes the answers.

2. **Grace over shame, always.** No motivational feature should leave a user feeling worse. When motivations are surfaced after a relapse, the framing is forward-looking and compassionate. When a user has not engaged with motivations, the prompt is gentle, never scolding.

3. **Personal over generic.** A user's own words and photos are exponentially more motivating than curated content. The system prioritizes surfacing user-authored material over any system-generated messaging.

4. **Contextual over scheduled.** Motivations are surfaced when they matter -- during urges, after setbacks, at milestones -- not on a fixed daily schedule. The right motivation at the right moment is worth a hundred random reminders.

5. **Progressive, not static.** Motivations evolve as recovery matures. The feature supports and celebrates this evolution, from crisis-driven fear to identity-integrated purpose. A motivation that gets archived is not a failure -- it is a sign of growth.

6. **Faith-integrated, not faith-added.** Scripture and spiritual framing are woven into the core experience, not bolted on as optional extras. For this audience, faith is the motivational architecture.

7. **Privacy is non-negotiable.** Motivations are among the most intimate data in the app -- they reference family situations, sexual struggles, spiritual wounds. No analytics on text content. No sharing without explicit consent. No surfacing in notifications that could expose context.

8. **Offline is the baseline.** Every motivational interaction must work without internet. The user who needs their daughter's photo during a 2 AM urge in a hotel room cannot wait for a server response.

---

*End of Document*

Functional Requirements Document v1.0 -- Motivations (Personal Recovery Motivation Engine)
