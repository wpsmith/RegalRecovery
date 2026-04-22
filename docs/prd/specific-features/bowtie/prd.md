# FEATURE REQUIREMENTS DOCUMENT

**Bowtie Diagram — Emotional Self-Awareness Activity**

Recovery App Feature | Structured Emotional Inventory & Anticipatory Planning Module

| Field | Value |
|-------|-------|
| **Version** | 1.0 |
| **Status** | Draft — For Review |
| **Date** | April 2026 |
| **Priority** | P1 — Core Recovery Activity |
| **Audience** | Product, Engineering, UX, Clinical Advisors, Pastoral Advisory |
| **Feature Flag** | `activity.bowtie` |
| **Wave** | Wave 2 |
| **Source** | Bowtie Diagram Part 1 & 2 (video transcripts), RLA Tools Bowtie MBR (video transcript), Bowtie_Tool.pdf (Redemptive Living Academy workbook) |

> *CLINICAL NOTICE: The Bowtie Diagram is a self-intimacy and emotional awareness tool developed by Redemptive Living Academy. It is not a substitute for professional treatment, pastoral counseling, or group accountability. Content and clinical framing require review by a CSAT and pastoral advisor before release.*

---

## 1. Executive Summary

The Bowtie Diagram is a structured self-awareness tool that helps users identify, map, and process the emotional wounds and unmet needs that drive addictive cycles. Users examine a rolling 48-hour window — retrospectively (what has already affected me?) and anticipatorily (what is coming that may affect me?) — through the layered lenses of their life roles, the Three I's (Insignificance, Incompetence, Impotence), and their known emotional triggers.

The tool's visual metaphor is a bowtie shape: two triangles meeting at a center point ("Now"), with the left triangle representing the past 48 hours and the right triangle representing the next 48 hours. Time intervals (1, 3, 6, 12, 24, 36, 48 hours) divide each triangle into columns. Users plot emotional activations across these intervals, then process unresolved points through the Backbone/Life Situations framework, ultimately redirecting unmet needs toward true intimacy (with God, Self, and Appropriate Others) rather than cycles of destruction.

**Key differentiators:**
- Dual-direction temporal analysis (retroactive + anticipatory) in a single tool
- Role-based emotional layering — the overhead-projector transparency metaphor digitized
- Integration with the Three I's, known emotional triggers, and the Backbone/Life Situations processing framework
- Produces actionable output: Prayer-People-Plan commitments and Intimacy action steps
- Connects to existing app features (Triggers, Urge Logs, FASTER Scale, Journaling, Check-Ins, Three Circles)

---

## 2. Clinical Foundation

### 2.1 The Bowtie Concept

The Bowtie Diagram, developed by Redemptive Living Academy, operates on a foundational insight: **acting out (or acting in) is never random.** Every relapse, every destructive outburst, every medicating behavior is informed by emotional activations that accumulated in the hours and days preceding it. These activations are often subtle — a dismissive comment, a neighbor's garbage can, a child's indifference — but they compound. When unprocessed, they create an emotional deficit that the addictive cycle promises to fill.

The Bowtie makes these invisible accumulations visible. It does so through two complementary modes:

**Retroactive mode:** After acting out, acting in, or medicating, the user looks backward through the preceding 48 hours to identify what emotional wounds were activated, in what roles, and at what intensity. This transforms post-relapse analysis from vague shame ("I don't know what happened") into specific, decodable data ("My incompetence was hit at a 7 six hours before, and my significance was hit at a 5 two days before, and I never processed either").

**Anticipatory mode:** Proactively, the user looks forward through the next 48 hours to identify upcoming situations that may activate emotional wounds. This enables preparation — prayer, positioning people, making plans — before the activation occurs. The clinical evidence is clear: a person who has anticipated and prepared for an emotional wound will handle an unexpected additional wound far better than someone already operating at an emotional deficit.

### 2.2 Theoretical Framework

| Concept | Description | Application in Bowtie |
|---------|-------------|----------------------|
| **Three I's** | Three core emotional wounds that ignite shame: Insignificance ("Do I matter?"), Incompetence ("Do I have what it takes?"), Impotence ("Do I have any control?") | Primary lens for identifying which wounds were activated at each time interval |
| **Known Emotional Triggers** | Personal hot-button emotions (e.g., embarrassment, failure, rejection, loneliness, being bullied) with deep personal history | Second lens overlaid on the Three I's to provide more granular identification |
| **Big Ticket Emotions** | Five common emotions that lead to Acting Out, Acting In, or Medicating: Abandonment, Loneliness, Rejection, Sorrow, Neglect | Accessible entry point for users not yet comfortable with the Three I's vocabulary |
| **Life Roles** | The distinct social roles a person occupies (Christian, Husband, Father, Son, Brother, Coach, Friend, Neighbor, Man in Recovery, etc.) | Transparency layers that enable granular analysis — a wound felt as "Father" is different from the same wound felt as "Employee" |
| **Backbone/Life Situations** | A four-level processing framework: Life Situation → Emotions → Three I's → Emotional Needs | The processing step after plotting the Bowtie — how to move from awareness to action |
| **Emotional Needs** | Valid needs that arise from activated wounds: Acceptance, Affirmation, Agency, Belonging, Comfort, Compassion, Connection, Empathy, Encouragement, Forgiveness, Grace, Hope, Love, Peace, Reassurance, Respect, Safety, Security, Understanding, Validation | The vocabulary for what the user actually needs — the alternative to cycles of destruction |
| **Intimacy as Antidote** | Three channels of true intimacy that meet emotional needs: Intimacy with God (prayer, Scripture, worship), Intimacy with Self (journaling, exercise, speaking truth, completing the Bowtie itself), Intimacy with Appropriate Others (spouse, accountability partner, group) | The resolution step — where the Bowtie points the user after awareness |
| **Prayer-People-Plan** | Three-part anticipatory preparation framework for upcoming emotional challenges | The practical output of the anticipatory (right-side) Bowtie |
| **Addictive Cycle** | Triggers → Preoccupation → Rituals → Acting Out → Guilt/Shame → (repeat). Same triggers also spawn the Acting In cycle: Preoccupation → Act In (blame, control, condescension, stonewalling, humor, hyper-spirituality) → Guilt/Shame → (repeat) | The Bowtie reveals what feeds the trigger stage of both cycles |

### 2.3 Design Principles

1. **Self-intimacy is the goal.** The Bowtie is not a diagnostic or a scorecard. It is a practice of connecting with your own heart. Every design decision should support honest self-examination, not performance.
2. **Nothing is too small.** A neighbor's garbage can, a child walking past without speaking, a driver cutting you off — these "innocuous" activations matter. The UX must not dismiss or minimize small-seeming events.
3. **Responsibility, not blame.** "I feel rejected" is different from "She made me feel rejected." The Bowtie helps users own their emotional experience without blaming others. This is not about whose fault it is — it is about learning to deal with what you feel.
4. **Numbers are informative, not magical.** The intensity scores and Three I's tallies are a barometer, not a grade. There is no passing score. The numbers reveal where the emotional weight is concentrated.
5. **Compassion in code.** A Bowtie completed after acting out is not a punishment. It is a learning exercise. The tone must reflect this throughout.
6. **Depth on demand.** Quick Bowtie for daily self-check (5-10 minutes); full Bowtie with Backbone processing for deep work (20-40 minutes). Never require depth; always offer it.
7. **Anticipatory living is the destination.** Retroactive Bowties are valuable, but the long-term recovery skill is living from the right side of the Bowtie — anticipating, preparing, and entering situations with emotional reserves intact.

---

## 3. User Personas

### 3.1 Primary Personas

| Persona | Profile | Recovery Stage | Key Bowtie Needs |
|---------|---------|----------------|------------------|
| **Alex** | 34, married, 45 days sober. Celebrate Recovery attendee. Evangelical. Uses app daily. | Early-to-mid recovery | Learn the tool with guided mode; retroactive Bowtie after urge spikes; start recognizing which I's get hit most |
| **Marcus** | 28, single, 7 days sober. Post-relapse. Deep shame. New to recovery. | Early recovery / post-relapse | Compassionate retroactive Bowtie to understand "how did I get here" without shame; Big Ticket Emotions entry point (not Three I's yet) |
| **Diego** | 42, married, 200 days sober. Small group leader. Has deep recovery vocabulary. | Established recovery | Full anticipatory Bowtie with role layering; weekly practice; Backbone processing for unresolved points; shares insights with accountability group |
| **Sarah** | 31, single woman, 90 days sober. Attends SA. Trauma history. | Mid recovery | Gentle entry; may not relate to "roles" framing initially; emphasis on self-intimacy and emotional needs vocabulary; spiritual lens optional |

### 3.2 Anti-Persona

| Anti-Persona | Why They Are Not Served |
|---|---|
| **Casual self-help user** | The Bowtie requires familiarity with recovery concepts (Three I's, emotional wounds, addictive cycles). Without this context, the tool is confusing rather than helpful. |
| **User seeking quick fix** | The Bowtie is reflective work that takes time. It is not a crisis intervention tool (that is SOS mode / Affirmations). |

---

## 4. User Stories

### 4.1 Bowtie Creation and Core Flow

| ID | Story | Priority | Acceptance Criteria |
|----|-------|----------|---------------------|
| US-BT-001 | As a user, I want to create a new Bowtie Diagram so that I can examine what has been affecting me emotionally in the last 48 hours and what is coming in the next 48 hours. | P0 | User can create a new Bowtie from the Activities section. Bowtie opens with "Now" as the center point. Default timestamp is current time. User can optionally set "Now" to a specific past moment (e.g., the moment of a relapse). |
| US-BT-002 | As a user, I want to select which roles to examine in this Bowtie session so that I can layer the analysis through the roles most active in my life right now. | P0 | User selects from their personal role list (configured in settings). Minimum 1 role, no maximum. Roles are the "transparency layers" applied during the session. |
| US-BT-003 | As a user, I want to plot emotional activations on the Past 48-hour side of the Bowtie, noting which I (Insignificance, Incompetence, or Impotence) was activated, in which role, at approximately what time interval, and at what intensity (1-10). | P0 | User places activation markers on the left triangle at approximate time intervals (1h, 3h, 6h, 12h, 24h, 36h, 48h). Each marker captures: which I(s), intensity (1-10), role, and optional brief note. Multiple markers per interval allowed. |
| US-BT-004 | As a user, I want to plot anticipated emotional activations on the Future 48-hour side of the Bowtie, noting which I may be activated, in which role, at approximately what time interval, and at what perceived intensity. | P0 | Same interaction as US-BT-003 but for the right (future) triangle. Anticipated activations are visually distinguished from past activations. |
| US-BT-005 | As a user, I want to see running tallies for each of the Three I's on both the Past and Future sides so that I can see where my emotional weight is concentrated. | P0 | Past side shows summed intensity for Insignificance, Incompetence, and Impotence separately. Future side shows the same. Tallies update in real-time as markers are added/edited. |
| US-BT-006 | As a user who is new to the Three I's, I want the option to use Big Ticket Emotions (Abandonment, Loneliness, Rejection, Sorrow, Neglect) or my own custom emotion labels instead of or alongside the Three I's so that I can work at my current level of emotional vocabulary. | P1 | User can toggle between Three I's mode, Big Ticket Emotions mode, or a combined mode. In Big Ticket Emotions mode, tallies are shown per emotion rather than per I. The system tracks which Big Ticket Emotions map to which I for analytics purposes. |
| US-BT-007 | As a user, I want the Bowtie to auto-save my progress so that I can pause and return to it later without losing work. | P0 | Every change auto-saves to local storage. Bowtie entries have a status: draft, complete. Drafts appear with a "Continue" option on the Activities screen. |

### 4.2 Backbone/Life Situations Processing

| ID | Story | Priority | Acceptance Criteria |
|----|-------|----------|---------------------|
| US-BT-010 | As a user who has plotted my Bowtie, I want to select unresolved activation points and process them through the Backbone/Life Situations framework so that I can identify what I am actually feeling and what I need. | P0 | User taps any activation marker on the Bowtie and selects "Process this." Opens the Backbone flow: Life Situation → Emotions → Three I's → Emotional Needs. Each step has guided prompts. |
| US-BT-011 | As a user processing an activation through the Backbone, I want to name the specific Life Situation that triggered the activation so that I can be concrete about what happened or what I am anticipating. | P0 | Free-text field with placeholder: "What happened?" or "What are you anticipating?" Max 500 characters. |
| US-BT-012 | As a user processing an activation, I want to name the specific emotions I feel about this Life Situation so that I can move beyond vague feelings to precise naming. | P0 | Emotion selector: horizontal scroll of emotion chips drawn from an expanded feelings vocabulary (sad, frustrated, disappointed, rejected, devalued, anxious, overwhelmed, angry, lonely, ashamed, hopeless, etc.) + free text option. Multiple selections allowed. |
| US-BT-013 | As a user processing an activation, I want to identify which of the Three I's are being tapped by these emotions so that I can see the core wound beneath the surface feeling. | P0 | Three I's selector with the diagnostic questions displayed: Insignificance ("Do I matter?"), Incompetence ("Do I have what it takes?"), Impotence ("Do I have any control?"). Multiple selections allowed with individual intensity (1-10). |
| US-BT-014 | As a user processing an activation, I want to identify my valid emotional needs in this situation so that I know what I actually need instead of what the addiction promises. | P0 | Emotional needs selector: Acceptance, Affirmation, Agency, Belonging, Comfort, Compassion, Connection, Empathy, Encouragement, Forgiveness, Grace, Hope, Love, Peace, Reassurance, Respect, Safety, Security, Understanding, Validation. Multiple selections allowed. Free text option for needs not in the list. |
| US-BT-015 | As a user who has identified my emotional needs, I want to choose how I will pursue meeting those needs through true intimacy (with God, Self, or Appropriate Others) so that the Bowtie produces an actionable next step. | P1 | Three-column intimacy action picker. Each column lists suggested actions: **God** (Prayer, Scripture Reading, Sermons, Worship Music, Read a Book), **Self** (Complete Bowtie, Journal, Exercise, Speak Truth Over Yourself, Make a Plan, Quadrant Work), **Others** (Connect with Wife/Partner, Connect with Accountability Partner, Text Your Group). User selects at least one action and can add custom actions. |

### 4.3 Prayer-People-Plan (Anticipatory Preparation)

| ID | Story | Priority | Acceptance Criteria |
|----|-------|----------|---------------------|
| US-BT-020 | As a user who has identified anticipated activations on the Future side of my Bowtie, I want to create a Prayer-People-Plan preparation for each anticipated situation so that I enter the situation with reserves intact. | P1 | For each future activation point, user can create a PPP entry: **Prayer** (free text or structured prayer prompt), **People** (select from contacts: accountability partner, sponsor, spouse, friend, group), **Plan** (free text: what will I do before, during, and after this situation?). |
| US-BT-021 | As a user with a PPP plan for an upcoming situation, I want to receive a gentle reminder before the anticipated time so that I am prompted to review my plan. | P1 | Optional reminder notification scheduled relative to the anticipated time (30 min, 1 hour, 3 hours before). Notification text is completely non-identifying: "Your plan is ready for later." |
| US-BT-022 | As a user who has passed through an anticipated situation, I want to revisit my PPP plan and note how it went so that I build a record of what preparation strategies work for me. | P2 | After the anticipated time passes, the system surfaces a gentle prompt: "How did it go?" Options: "Better than expected" / "About what I anticipated" / "Harder than expected" / "I'll reflect later." Optional free-text reflection. |

### 4.4 Roles Management

| ID | Story | Priority | Acceptance Criteria |
|----|-------|----------|---------------------|
| US-BT-030 | As a user, I want to configure my personal list of roles (e.g., Christian, Husband, Father, Son, Brother, Man in Recovery, Coworker, Coach, Neighbor, Friend) so that they are available when I create a Bowtie. | P0 | Roles configured in Bowtie settings or during first Bowtie creation. Pre-populated suggestions list. User can add custom roles, reorder, and archive roles they no longer occupy. Roles persist across Bowtie sessions. |
| US-BT-031 | As a user, I want to select a subset of my roles for each Bowtie session so that I focus on the roles most relevant to my current situation. | P0 | Role picker at Bowtie creation. All roles shown, user selects which to examine this session. At least 1 required. |

### 4.5 Known Emotional Triggers Integration

| ID | Story | Priority | Acceptance Criteria |
|----|-------|----------|---------------------|
| US-BT-040 | As a user, I want to configure my personal list of known emotional triggers (e.g., embarrassment, failure, feeling bullied, rejection, overwhelm) so that they are available as an additional analysis lens in the Bowtie. | P1 | Known emotional triggers configured in Bowtie settings or during first use. Pre-populated list from common triggers. User can add custom triggers. These are distinct from the Triggers feature's 120-item library — they represent recurring personal emotional patterns, not situational triggers. |
| US-BT-041 | As a user plotting activations on the Bowtie, I want to optionally tag each activation with which of my known emotional triggers were involved so that I can see patterns across sessions. | P1 | Optional tag field on each activation marker. Multi-select from personal known emotional triggers list. |

### 4.6 Spiritual Lens

| ID | Story | Priority | Acceptance Criteria |
|----|-------|----------|---------------------|
| US-BT-050 | As a user, I want the option to examine the Bowtie through a spiritual lens in addition to the emotional lens so that I can process what is going on between me and God in these situations. | P1 | Optional "Spiritual lens" toggle on each activation marker or as a separate pass through the Bowtie. Guided prompts: "How did you experience yourself and God in this role during this time?" / "Was there conviction, resistance, closeness, distance?" Free-text reflection field. |

### 4.7 Viewing History and Patterns

| ID | Story | Priority | Acceptance Criteria |
|----|-------|----------|---------------------|
| US-BT-060 | As a user, I want to view my completed Bowties in chronological order so that I can revisit past self-awareness work. | P0 | Bowtie History list showing: date, time reference ("Now" moment), roles examined, summary tallies (Past: Insignificance X, Incompetence Y, Impotence Z; Future: same), completion status. Tapping opens the full Bowtie for review. |
| US-BT-061 | As a user with multiple completed Bowties, I want to see which of the Three I's is most frequently activated across all my Bowties so that I can identify my primary emotional vulnerability. | P1 | Aggregate analytics view: total and average intensity per I across all completed Bowties. Trend over time (is my Insignificance activation increasing, decreasing, or stable?). |
| US-BT-062 | As a user, I want to see which roles produce the most emotional activation across my Bowties so that I can focus my recovery work on the relationships that need it most. | P1 | Per-role activation frequency and average intensity. Ranked list of roles by total emotional activation. |
| US-BT-063 | As a user, I want to see whether my Bowtie practice is shifting from predominantly retroactive (looking back after events) to anticipatory (looking ahead and preparing) so that I can track my growth in proactive emotional management. | P2 | Ratio of past-side activations to future-side activations across Bowties over time. Growth-oriented framing: "Your anticipatory awareness is growing — you're spending more time preparing than reacting." |

### 4.8 Entry Points and Contextual Triggers

| ID | Story | Priority | Acceptance Criteria |
|----|-------|----------|---------------------|
| US-BT-070 | As a user, I want to start a Bowtie from the Activities section of the app so that I can do proactive self-awareness work at any time. | P0 | Bowtie appears in the Activities list. Tapping opens a new Bowtie or continues a draft. |
| US-BT-071 | As a user who just logged a relapse, acting in, or medicating event, I want the app to suggest a retroactive Bowtie so that I can understand what led to this moment. | P1 | After a sobriety reset or acting-in/medicating log, a contextual card appears: "Understanding what happened starts with knowing what was going on inside you. A Bowtie Diagram can help." Tapping opens a new Bowtie with "Now" pre-set to the event timestamp. |
| US-BT-072 | As a user who just completed a FASTER Scale check-in showing progression to "Speeding Up" or beyond, I want the app to suggest a Bowtie so that I can examine what emotional activations are driving the acceleration. | P2 | Contextual suggestion after elevated FASTER Scale results. Non-blocking, dismissible. |
| US-BT-073 | As a user completing an evening review or check-in, I want the option to start a quick Bowtie if the review surfaces unprocessed emotions. | P2 | Optional "Would you like to examine this further with a Bowtie?" prompt after check-in entries that indicate emotional activation. |

---

## 5. User Journeys

### 5.1 Journey: First-Time Bowtie (Alex, Day 45, Guided Mode)

```
Alex → Activities → Bowtie Diagram → [First time: Onboarding]
  → "What is the Bowtie Diagram?" (brief explanation with visual)
    "A tool to help you see what's been stirring in your heart —
    and what's coming — so you can meet your real needs instead
    of reaching for something that hurts you."
  → "Set up your roles" → pre-populated suggestions
    Alex selects: Christian, Husband, Father (×3 kids), Man in Recovery, Coworker
  → "Set up your known emotional triggers" → pre-populated suggestions
    Alex selects: Rejection, Failure, Overwhelm, Feeling dismissed
  → [Onboarding complete — saved to profile]

  → New Bowtie → "Now" = current moment (default)
  → Select roles for this session: Christian, Husband, Father (oldest), Coworker
  → PAST 48 HOURS:
    → Guided prompt: "Think back over the last 48 hours.
      As a Husband, has anything stirred the Three I's?"
    → Alex adds: "Wife needed space at school event" →
      Insignificance, intensity 4, role: Husband, ~24h ago
    → Next role prompt: "As a Coworker?"
    → Alex adds: "Boss criticized my report" →
      Incompetence, intensity 6, role: Coworker, ~6h ago
    → Past tallies update: Insignificance: 4, Incompetence: 6, Impotence: 0

  → FUTURE 48 HOURS:
    → Guided prompt: "Looking ahead, is anything coming up
      that might stir your emotions?"
    → Alex adds: "Team meeting with boss tomorrow" →
      Incompetence, intensity 5 (anticipated), role: Coworker, ~18h out
    → Future tallies: Insignificance: 0, Incompetence: 5, Impotence: 0

  → PROCESS: Alex taps the boss criticism marker (intensity 6)
    → Backbone flow opens:
      → Life Situation: "Boss said my report was 'sloppy work'"
      → Emotions: frustrated, embarrassed, devalued
      → Three I's: Incompetence (7)
      → Emotional Needs: Affirmation, Competence, Respect
      → Intimacy Action: "Journal about this" (Self) + "Text accountability partner" (Others)
    → Marker updated with processing status ✓

  → PPP for tomorrow's meeting:
    → Prayer: "Ask God for peace and perspective before the meeting"
    → People: "Text Jake after the meeting"
    → Plan: "Arrive 5 min early. Pray in the parking lot.
      If criticized, pause before responding. Journal after."

  → [Complete Bowtie] → "You just did real work.
    Seeing what's stirring in your heart is a recovery skill."
  → Bowtie saved. Calendar activity entry created.
```

### 5.2 Journey: Post-Relapse Retroactive Bowtie (Marcus, Day 1 Reset)

```
Marcus reports sobriety reset at 11 PM last night
  → System suggests: "Understanding what happened is part of recovery.
    A Bowtie Diagram can help you see what was building up."
  → Marcus taps [Start Bowtie]
  → "Now" auto-set to 11 PM last night (moment of acting out)

  → Using Big Ticket Emotions mode (Marcus is early in recovery vocabulary)
  → Past 48 hours:
    → 1h before: "Scrolling alone in apartment" → Loneliness (8)
    → 6h before: "Friend cancelled dinner plans" → Rejection (7)
    → 24h before: "Skipped church, felt guilty about it" → Sorrow (5)
    → 36h before: "Mom's birthday, didn't call" → Neglect (4), Sorrow (3)
  → Past tallies: Abandonment: 0, Loneliness: 8, Rejection: 7, Sorrow: 8, Neglect: 4

  → Marcus skips Future side (not ready yet) → [That's okay. You can add this later.]

  → Processes the friend cancellation (Rejection 7):
    → Life Situation: "Only friend who knows about my recovery cancelled on me"
    → Emotions: rejected, invisible, desperate
    → Three I's: Insignificance (8)
    → Needs: Connection, Belonging, Being Chosen
    → Intimacy Action: "Call a different friend tomorrow" (Others)

  → [Complete Bowtie]
  → "What you just did took courage. You looked at something painful
    and learned from it. That's not failure — that's recovery."
  → Bowtie saved with link to the relapse event for post-mortem correlation.
```

### 5.3 Journey: Anticipatory Bowtie (Diego, Day 200, Weekly Practice)

```
Diego → Activities → Bowtie → New Bowtie (Sunday evening routine)
  → Selects roles: Christian, Husband, Father (all 3), Brother, Coach
  → Quick scan of Past 48:
    → Adds 3 markers quickly (familiar with the tool, minimal guidance)
    → Past tallies: Insignificance: 5, Incompetence: 3, Impotence: 0

  → Future 48 (where Diego spends most of his time now):
    → 3h: Evening conversation with wife about finances → Incompetence (4)
    → 12h: Monday morning standup with difficult colleague → Insignificance (3)
    → 24h: Brother's birthday — should he call? → Insignificance (6), Impotence (4)
    → 36h: Kids' soccer practice (coaching) → Incompetence (3), Impotence (3)
    → Future tallies: Insignificance: 9, Incompetence: 7, Impotence: 7

  → Diego notes: "Wow, impotence is higher than I expected this week."

  → Creates PPP for brother's birthday (highest single activation):
    → Prayer: "Pray for the conversation before dialing"
    → People: "Matt on standby — will call after I hang up"
    → Plan: "Call from the study. Set a 30-min time limit.
      Have journal ready. After the call, write down 3 emotions
      before doing anything else. Then go be with the family."

  → Processes the finance conversation through Backbone:
    → Life Situation: "We overspent this month and I feel responsible"
    → Emotions: ashamed, anxious, inadequate
    → Three I's: Incompetence (5)
    → Needs: Grace, Understanding, Reassurance
    → Intimacy: "Pray together before the conversation" (God) +
      "Be honest about feeling inadequate" (Self) +
      "Ask Emma for grace, not solutions" (Others)

  → [Complete Bowtie]
  → Weekly Bowtie logged. Diego's anticipatory-to-retroactive ratio: 68% anticipatory.
```

---

## 6. Functional Requirements

### 6.1 Bowtie Session Management

| ID | Requirement | MoSCoW | Rationale |
|----|-------------|--------|-----------|
| FR-BT-001 | The system shall allow the user to create a new Bowtie Diagram session from the Activities section, from a post-relapse contextual prompt, or from a FASTER Scale follow-up suggestion. | Must | Multi-point entry ensures the Bowtie is accessible both proactively and reactively. |
| FR-BT-002 | Each Bowtie session shall have a "Now" reference point, defaulting to the current date/time. The user shall be able to override "Now" to a specific past timestamp (e.g., the moment of a relapse or acting-in event). | Must | Retroactive Bowties require anchoring "Now" to the event being analyzed, not the current moment. |
| FR-BT-003 | Each Bowtie session shall have a status: `draft` (in progress, auto-saved) or `complete` (user has explicitly marked it done). Draft Bowties shall appear with a "Continue" affordance on the Activities screen. | Must | Bowties may take 20-40 minutes; interruption must not lose work. |
| FR-BT-004 | The system shall auto-save all Bowtie data to local storage on every change. If the app is backgrounded or terminated during a session, all data shall be preserved. | Must | Data loss during vulnerable emotional work would be deeply harmful to user trust. |
| FR-BT-005 | The system shall store completed Bowties in chronological order, viewable as a history list. Each entry shall display: date, "Now" reference, roles examined, Past/Future tallies summary, processing completion status. | Must | History enables longitudinal pattern recognition and recovery progress tracking. |
| FR-BT-006 | The system shall allow the user to delete individual Bowtie sessions. Deletion shall require a single confirmation dialog. Deleted sessions shall be permanently removed from local and remote storage within 24 hours. | Must | User control over sensitive emotional data is non-negotiable. |

### 6.2 Role Configuration and Selection

| ID | Requirement | MoSCoW | Rationale |
|----|-------------|--------|-----------|
| FR-BT-010 | The system shall maintain a persistent personal role list for the user, configurable from Bowtie settings or during first-time Bowtie creation. | Must | Roles are the foundational "transparency layers" of the Bowtie. They must be reusable across sessions. |
| FR-BT-011 | The system shall provide a pre-populated suggestions list of common roles: Christian/Person of Faith, Husband/Wife/Partner, Father/Mother/Parent, Son/Daughter, Brother/Sister/Sibling, Friend, Man/Woman in Recovery, Coworker/Employee, Neighbor, Coach/Mentor, Church Member, Student. | Must | Scaffolding reduces blank-page friction. Suggestions are gender-inclusive while supporting the user's specific context. |
| FR-BT-012 | The user shall be able to add custom roles, edit role labels, reorder roles, and archive roles they no longer actively occupy. Archived roles shall remain available for historical Bowties but not appear in the selection list for new sessions. | Should | Recovery evolves — a user may gain or lose roles over time (new job, divorce, new child). |
| FR-BT-013 | At the start of each Bowtie session, the user shall select which roles to examine. At least 1 role must be selected. All personal roles are shown; the user toggles which to include. | Must | Not every Bowtie examines every role. A quick daily Bowtie might examine 2-3 roles; a deep weekly one might examine 6-8. |

### 6.3 Activation Plotting (Past and Future)

| ID | Requirement | MoSCoW | Rationale |
|----|-------------|--------|-----------|
| FR-BT-020 | The system shall display the Bowtie as two triangular regions meeting at a center point labeled "Now." The left triangle represents the Past 48 hours; the right triangle represents the Future 48 hours. Time interval markers shall be displayed at 1h, 3h, 6h, 12h, 24h, 36h, and 48h from center. | Must | This is the defining visual of the Bowtie tool. The layout must be immediately recognizable as a bowtie shape. |
| FR-BT-021 | The user shall be able to place activation markers on either triangle at any time interval. Each activation marker shall capture: (a) which Three I's are activated (one or more of Insignificance, Incompetence, Impotence), (b) intensity per I (1-10 scale), (c) the role this activation is experienced in, (d) optional brief description (max 280 characters). | Must | This is the core data capture of the Bowtie. The activation marker is the atomic unit of the tool. |
| FR-BT-022 | The system shall support multiple activation markers at the same time interval. | Must | Multiple things happen in the same time window. A user may feel both Insignificance from their boss and Incompetence as a father within the same 6-hour block. |
| FR-BT-023 | Activation markers shall be visually coded by which I is activated: distinct color or icon for Insignificance, Incompetence, and Impotence. Markers on the Past side shall be visually distinguishable from markers on the Future side (e.g., solid vs. outlined). | Must | Visual differentiation enables at-a-glance pattern recognition. Color alone shall not be the sole differentiator (accessibility). |
| FR-BT-024 | The system shall display running tallies for each of the Three I's on each side (Past and Future), summing the intensity values of all markers for that I on that side. Tallies shall update in real-time as markers are added, edited, or removed. | Must | The tallies reveal where emotional weight is concentrated — the primary insight of the Bowtie. |
| FR-BT-025 | The user shall be able to edit or delete any activation marker after placing it. Editing opens the marker detail for modification. | Must | Self-awareness is iterative; users may revise their assessment as they reflect. |
| FR-BT-026 | Placement of markers on the Bowtie diagram should support both tap-to-place (tap a time interval column, then fill in marker details) and a list-based entry mode (add activations as a structured list without interacting with the visual diagram). Both modes shall produce the same data. | Should | Some users prefer visual interaction; others prefer structured forms. The visual diagram may be difficult to use on smaller screens. |

### 6.4 Alternative Emotion Vocabulary

| ID | Requirement | MoSCoW | Rationale |
|----|-------------|--------|-----------|
| FR-BT-030 | The system shall support three emotion vocabulary modes for activation markers: **Three I's mode** (Insignificance, Incompetence, Impotence), **Big Ticket Emotions mode** (Abandonment, Loneliness, Rejection, Sorrow, Neglect), and **Combined mode** (both). The user shall select their preferred mode in Bowtie settings. | Must | Users new to recovery may not yet have vocabulary for the Three I's. Big Ticket Emotions provide an accessible entry point. Combined mode serves users who are developing their Three I's fluency. |
| FR-BT-031 | In Big Ticket Emotions mode, tallies shall be shown per emotion. The system shall internally track the mapping between Big Ticket Emotions and Three I's for analytics purposes (e.g., Rejection maps primarily to Insignificance). | Should | Enables longitudinal analytics even when users start with simpler vocabulary and transition to Three I's over time. |
| FR-BT-032 | The system shall support a custom emotions option, allowing the user to add up to 10 personal emotion labels that are meaningful to them (e.g., "being controlled," "feeling stupid," "being overlooked"). Custom emotions shall be mappable to the Three I's. | Could | Known emotional triggers are deeply personal. Some users' primary activations are specific enough that generic labels don't fit. |

### 6.5 Backbone/Life Situations Processing

| ID | Requirement | MoSCoW | Rationale |
|----|-------------|--------|-----------|
| FR-BT-040 | The user shall be able to select any activation marker on the Bowtie and initiate Backbone processing for it. The Backbone flow shall present four steps in sequence: Life Situation → Emotions → Three I's → Emotional Needs. | Must | The Backbone is how the Bowtie moves from awareness to action. Without it, the Bowtie is a map with no directions. |
| FR-BT-041 | **Life Situation step:** The system shall prompt: "What is happening in this moment that you're experiencing? What's happened in the recent past? Or what are you anticipating?" Free text, max 500 characters. Pre-populated with the marker's brief description if one was provided. | Must | Grounds the processing in specifics rather than abstractions. |
| FR-BT-042 | **Emotions step:** The system shall prompt: "What are you feeling about this life situation?" Emotion selector with a curated list of emotions commonly relevant to recovery (sad, frustrated, disappointed, rejected, devalued, anxious, overwhelmed, angry, lonely, ashamed, hopeless, fearful, embarrassed, helpless, invisible, defensive, numb). Multiple selections allowed. Free text option. | Must | Emotion naming is the bridge between awareness and Three I's identification. |
| FR-BT-043 | **Three I's step:** The system shall display the three core wounds with their diagnostic questions: Insignificance — "Do I matter?", Incompetence — "Do I have what it takes?", Impotence — "Do I have any control?" User selects which are present and rates intensity (1-10). | Must | Connects surface emotions to core wounds. |
| FR-BT-044 | **Emotional Needs step:** The system shall display the following emotional needs vocabulary and prompt: "What do I need in this situation?" Selectable needs: Acceptance, Affirmation, Agency, Belonging, Comfort, Compassion, Connection, Empathy, Encouragement, Forgiveness, Grace, Hope, Love, Peace, Reassurance, Respect, Safety, Security, Understanding, Validation. Multiple selections allowed. Free text option. | Must | Identifying valid emotional needs is the pivot point — the alternative to seeking relief through addictive cycles. |
| FR-BT-045 | After completing the Emotional Needs step, the system shall present the Intimacy Action step with three columns: **Intimacy with God** (suggested actions: Prayer, Scripture Reading, Sermons, Worship Music, Read a Book), **Intimacy with Self** (Journal, Exercise, Speak Truth Over Yourself, Make a Plan, Quadrant Work, Complete Bowtie), **Intimacy with Appropriate Others** (Connect with Wife/Partner, Connect with Accountability Partner, Text Your Group). User selects at least one action. Custom actions supported. | Must | The Bowtie must produce a concrete next step. Intimacy as the antidote to addiction is the theological and clinical foundation. |
| FR-BT-046 | Activation markers that have been processed through the Backbone shall display a visual indicator (e.g., checkmark, filled state) on the Bowtie diagram so the user can see which points have been addressed and which remain unresolved. | Must | Visual processing status motivates completion and identifies unresolved emotional inventory. |

### 6.6 Prayer-People-Plan

| ID | Requirement | MoSCoW | Rationale |
|----|-------------|--------|-----------|
| FR-BT-050 | For any activation marker on the Future side of the Bowtie, the user shall be able to create a Prayer-People-Plan (PPP) preparation entry. | Must | PPP is the practical tool for anticipatory recovery — translating awareness into preparation. |
| FR-BT-051 | **Prayer:** Free text field for what the user will pray about regarding this situation. Optional suggested prayer prompts based on the identified I (e.g., for Insignificance: "Lord, remind me that I am seen and valued by You"). | Should | Guided prayer prompts lower the barrier for users who struggle to articulate prayers around their wounds. |
| FR-BT-052 | **People:** Contact selector from the user's recovery contacts (accountability partner, sponsor, spouse, group members). The user identifies who they will reach out to before, during, or after the anticipated situation. | Must | Isolation is the enemy of recovery. PPP explicitly plans for human connection. |
| FR-BT-053 | **Plan:** Structured free-text field with prompts: "Before this situation, I will ___", "During this situation, I will ___", "After this situation, I will ___." | Must | Concrete behavioral plans are more effective than vague intentions. The before/during/after structure matches the temporal nature of the Bowtie. |
| FR-BT-054 | The system shall optionally schedule a notification reminder before the anticipated situation time. Reminder intervals: 30 minutes, 1 hour, 3 hours, or custom. Notification text shall be completely non-identifying: "Your plan is ready." | Should | Proactive reminders increase PPP follow-through. Privacy-safe notification text is mandatory. |
| FR-BT-055 | After the anticipated time passes, the system shall surface an optional follow-up prompt: "How did it go?" with quick-response options and an optional reflection field. | Should | Closing the loop builds data on which preparation strategies work and reinforces the anticipatory practice. |

### 6.7 Guided Mode (First-Time and Educational)

| ID | Requirement | MoSCoW | Rationale |
|----|-------------|--------|-----------|
| FR-BT-060 | The system shall provide a first-time onboarding flow when the user opens the Bowtie feature for the first time. The onboarding shall cover: (a) what the Bowtie is in plain language, (b) the visual metaphor (looking back and looking ahead through your life roles), (c) the Three I's concept with diagnostic questions, (d) the difference between retroactive and anticipatory use, (e) that this is a self-intimacy practice — not a test. The onboarding shall be skippable and re-accessible from a help icon. | Must | The Bowtie is a complex tool. Without onboarding, users will not understand the layered transparency metaphor or the Three I's vocabulary. |
| FR-BT-061 | The system shall offer two session modes: **Guided** (default for first 3 sessions) and **Freeform** (default after 3 completed sessions). Guided mode walks through each selected role sequentially with prompts. Freeform mode presents the full Bowtie diagram for self-directed use. Users can switch between modes at any time. | Must | Guided mode teaches the transparency-layering methodology. Freeform mode supports efficient use once the methodology is learned. |
| FR-BT-062 | In Guided mode, for each selected role, the system shall prompt: "Over the last 48 hours, as a [Role], has anything stirred the Three I's? Has anything hit your known emotional triggers?" The user adds markers or indicates "Nothing for this role." The system then moves to the next role. After all roles on the Past side, it repeats for the Future side. | Must | Role-by-role prompting implements the overhead-projector transparency metaphor — one layer at a time until the full picture emerges. |
| FR-BT-063 | In Guided mode, the system shall provide inline educational content for each concept as it is introduced (Three I's, emotional triggers, Backbone, PPP). Educational content shall be brief (2-3 sentences), dismissible, and marked as "Learn more" rather than mandatory reading. | Should | Progressive education embedded in the workflow is more effective than front-loaded lectures. |

---

## 7. Analytics & Tracking

### 7.1 Product Analytics Events

All events are anonymized. No user-entered text, emotion selections, or personal data in analytics. Opt-out available.

| Event | Properties | Purpose |
|-------|------------|---------|
| `bowtie.session.started` | `entryPath` (activities/post-relapse/faster-scale/check-in), `mode` (guided/freeform), `emotionVocabulary` (threeIs/bigTicket/combined), `roleCount` | Session engagement by entry path |
| `bowtie.session.completed` | `entryPath`, `mode`, `durationMinutes`, `pastMarkerCount`, `futureMarkerCount`, `backboneCompletedCount`, `pppCreatedCount` | Session depth and completion patterns |
| `bowtie.session.abandoned` | `entryPath`, `mode`, `durationMinutes`, `lastStepReached` | Drop-off analysis |
| `bowtie.session.resumed` | `draftAgeHours` | Draft resume patterns |
| `bowtie.marker.added` | `side` (past/future), `iType` (insignificance/incompetence/impotence/bigTicket), `intensity`, `hasNote` (bool) | Activation distribution |
| `bowtie.backbone.started` | `markerSide`, `markerIType` | Backbone engagement |
| `bowtie.backbone.completed` | `needsSelectedCount`, `intimacyActionsCount` | Backbone completion depth |
| `bowtie.ppp.created` | `hasPrayer` (bool), `hasPeople` (bool), `hasPlan` (bool), `reminderSet` (bool) | PPP adoption and completeness |
| `bowtie.ppp.followup.responded` | `outcome` (better/expected/harder/later) | PPP effectiveness signal |
| `bowtie.history.viewed` | `totalCompleted` | History engagement |
| `bowtie.insights.viewed` | `insightType` (iDistribution/roleActivation/anticipatoryRatio) | Analytics engagement |
| `bowtie.onboarding.completed` | `skipped` (bool), `durationSeconds` | Onboarding effectiveness |

### 7.2 Clinical Tracking (Per-User Private Data)

| Metric | Storage | Clinical Use |
|--------|---------|-------------|
| Session history (date, reference time, roles, markers, processing) | SwiftData `BowtieSession` | Self-awareness practice consistency |
| Three I's distribution over time | Aggregation from markers | Primary wound pattern identification |
| Role-based activation frequency | Aggregation from markers | Identifies which life domains carry the most emotional weight |
| Backbone processing completion rate | Computed from sessions | Measures whether awareness translates to processing |
| PPP creation and follow-through rate | Computed from PPP entries | Measures anticipatory preparation skill development |
| Retroactive-to-anticipatory ratio | Computed from marker counts | Tracks growth from reactive to proactive emotional management |

### 7.3 Key Product Metrics (KPIs)

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Bowtie adoption** | 30% of active users complete at least 1 Bowtie within 30 days of feature launch | Event tracking |
| **Session completion rate (guided)** | > 60% | Started sessions reaching "Complete" |
| **Session completion rate (freeform)** | > 75% | Started sessions reaching "Complete" |
| **Backbone processing rate** | > 40% of activation markers get Backbone processing | Processed markers / total markers |
| **PPP creation rate** | > 30% of future-side markers get a PPP entry | PPP entries / future markers |
| **Weekly practice rate (30-day)** | > 20% of adopters complete 1+ Bowtie per week at 30 days | Rolling 7-day completion |
| **Anticipatory ratio growth** | Increasing trend over 90 days | Future markers / total markers, monthly |
| **Post-relapse Bowtie uptake** | > 25% of relapse events followed by a Bowtie within 48 hours | Relapse events → Bowtie sessions |

---

## 8. Integrations

### 8.1 Internal App Integrations

| System | Integration Type | Direction | Details |
|--------|-----------------|-----------|---------|
| **Sobriety Counter** | Contextual trigger | Read | Sobriety reset event triggers post-relapse Bowtie suggestion (US-BT-071) |
| **FASTER Scale** | Contextual trigger | Read | Elevated FASTER position ("Speeding Up" or beyond) triggers Bowtie suggestion (US-BT-072) |
| **Triggers Feature** | Data correlation | Read/Write | Known emotional triggers in Bowtie may reference or link to Trigger Library entries. Bowtie activations that identify triggers create correlation data for Trigger analytics. |
| **Urge Logs** | Data correlation | Read | Post-relapse Bowtie correlates with preceding urge log entries within 72h window for post-mortem analysis. |
| **Journaling** | Content bridging | Write | Backbone reflections and PPP plans optionally create linked journal entries. Intimacy action "Journal" opens the journal pre-filled with Bowtie context. |
| **Check-Ins (FANOS, Evening Review)** | Contextual trigger | Read | Check-in responses indicating emotional activation may suggest a Bowtie. |
| **Calendar Activity** | Dual-write | Write | Each completed Bowtie session → `calendarActivities` entry (activityType: "BOWTIE") |
| **Feature Flags** | Gating | Read | `activity.bowtie` controls feature visibility. Fail closed → 404. |
| **Notifications** | Scheduling | Write | PPP reminder notifications. Weekly practice reminders (opt-in). |
| **Three Circles** | Pattern correlation | Read | Bowtie activation patterns correlate with middle-circle drift — "Your Bowtie shows high incompetence activation this week, and your check-ins show middle-circle contact on 3 of those days." |
| **Affirmations** | Content bridging | Read | Intimacy action "Speak Truth Over Yourself" can launch an on-demand Affirmation session. |

### 8.2 External Integrations

None required for v1. The Bowtie is a self-contained reflective tool.

---

## 9. Accessibility Requirements

| Area | Requirement | Priority |
|------|-------------|----------|
| **Screen Reader** | VoiceOver full support. Bowtie diagram announced as structured data: "Past side: 3 activation markers. Future side: 2 activation markers. Tallies: Insignificance past 8, future 4..." List-based entry mode (FR-BT-026) provides full VoiceOver-accessible alternative to visual diagram. | P0 |
| **Dynamic Type** | All text scales with system text size settings. Bowtie diagram gracefully degrades at larger text sizes (labels may abbreviate, markers may stack). | P0 |
| **Touch Targets** | Minimum 44x44pt for all interactive elements (markers, role chips, emotion chips, buttons). | P0 |
| **Color** | Color never the sole indicator of which I is activated. Icons and labels accompany all color-coded elements. Past/Future markers differentiated by shape in addition to color. | P0 |
| **High Contrast** | Full support for high contrast / increased contrast modes. | P1 |
| **Reduced Motion** | Disable any animation on the Bowtie diagram when Reduce Motion is enabled. | P1 |
| **Reading Level** | All UI text and educational content at 8th-grade reading level max. | P0 |

---

## 10. Technical Requirements

### 10.1 Data Architecture (SwiftData — iOS Local Storage)

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
| `futureInsignificanceTotal` | Int | Computed sums for future side |
| `futureIncompetenceTotal` | Int | |
| `futureImpotenceTotal` | Int | |
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
| `threeIs` | [IActivation] | Three I's with intensities |
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

### 10.2 Enumerations

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

### 10.3 Performance Requirements

| Metric | Target |
|--------|--------|
| Bowtie diagram render time | < 500ms |
| Marker add/edit response time | < 100ms |
| Backbone flow transition | < 200ms per step |
| History list load (100 sessions) | < 1s |
| Analytics computation (50 sessions) | < 2s |
| Auto-save write | < 100ms |

### 10.4 Offline Requirements

| Feature | Offline Support |
|---------|----------------|
| Bowtie creation and editing | Full |
| Backbone processing | Full |
| PPP creation | Full |
| Role and trigger configuration | Full |
| History viewing | Full |
| Analytics computation | Full (on-device) |
| PPP reminder notifications | Full (local notifications) |
| Server sync | Requires internet |

### 10.5 Security Requirements

| Requirement | Specification |
|-------------|---------------|
| Data encryption (rest) | AES-256 via SwiftData encrypted storage |
| Data encryption (transit) | TLS 1.3 minimum |
| Biometric lock | App-level biometric lock applies to all Bowtie data |
| Notification text | 100% generic — never contains recovery, emotion, or wound terminology |
| Feature flag | `activity.bowtie` — fail closed (404 when disabled) |
| Immutable timestamps | `createdAt` never modified on any Bowtie entity |
| Tenant isolation | `tenantId` on every server-side document, enforced at API layer |

---

## 11. Non-Functional Requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-BT-001 | Feature flag `activity.bowtie` fail-closed | 404 when disabled |
| NFR-BT-002 | Immutable timestamps (FR2.7) | `createdAt` never modified on session, marker, backbone, or PPP records |
| NFR-BT-003 | Calendar activity dual-write | Every completed session writes to `calendarActivities` |
| NFR-BT-004 | No streak-based metrics | Zero streak counters for Bowtie practice. Cumulative metrics only. |
| NFR-BT-005 | Test coverage | >= 80% overall; 100% on data persistence, Backbone state machine, PPP reminder scheduling |
| NFR-BT-006 | Offline-first | All core Bowtie functionality works without internet |
| NFR-BT-007 | Auto-save reliability | Zero data loss during Bowtie sessions, even on app termination |
| NFR-BT-008 | Guided-to-freeform transition | After 3 completed guided sessions, default switches to freeform. User can override in either direction. |

---

## 12. Tone, Voice, and Language Guidelines

### 12.1 Core Principles

The Bowtie is the most introspective tool in the app. The user is sitting with their wounds. The tone must be that of a trusted counselor — calm, honest, never rushing, never minimizing.

### 12.2 Language Rules

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

### 12.3 Empty States

**No Bowties yet:**
"The Bowtie Diagram helps you see what's really going on inside — the subtle wounds and unmet needs that build up beneath the surface. When you're ready, this is where you start building that awareness."

**No activations on Future side:**
"Nothing on the radar? That's okay. Sometimes the future looks clear. You can always come back and add to this if something comes to mind."

**All markers processed:**
"Every point on your Bowtie has been addressed. You've done real self-intimacy work today."

### 12.4 Completion Messages (rotating set)

- "You just practiced seeing yourself honestly. That's a recovery skill most people never develop."
- "The more you do this, the less the addiction can surprise you."
- "Knowing what's stirring in your heart is the beginning of freedom."
- "You've moved from reacting to understanding. That matters."
- "Self-intimacy is the antidote. You just practiced it."

---

## 13. Out of Scope (v1)

- AI-assisted pattern detection across Bowties ("Your Insignificance spikes every time your brother calls")
- Shared Bowties with accountability partner or counselor (v2 — sharing summary only, never raw data)
- Guided Bowtie audio walkthrough (narrated session mode)
- Integration with quadrant work feature (not yet implemented)
- Bowtie comparison view (side-by-side comparison of two Bowties from different dates)
- Spouse/partner Bowtie variant (processing relational wounds from the partner's perspective)
- Group Bowtie facilitation mode (for small group leaders like Diego)
- Export to PDF for therapist sharing

---

## 14. Dependencies

| Dependency | Status | Blocks |
|------------|--------|--------|
| SwiftData models and repository | Available | Blocking — no local persistence |
| SyncEngine configuration for BOWTIE entity | Requires work | Blocking for server sync; offline creation works |
| Feature flag service | Available | Blocking — feature cannot ship without flag |
| Calendar activity view | Shipped | FR-BT integration available |
| Sobriety counter (relapse event) | Wave 1 — In progress | US-BT-071 post-relapse suggestion |
| FASTER Scale feature | Wave 2 — In progress | US-BT-072 contextual suggestion (non-blocking; degrades gracefully) |
| Triggers feature | Wave 2 — In progress | Known emotional triggers cross-reference (non-blocking; Bowtie maintains its own trigger list) |
| Journaling | Wave 1 — In progress | Backbone → Journal bridging (non-blocking; Backbone works without journal) |
| Three Circles feature | Wave 1 — In progress | Pattern correlation (non-blocking; analytics enhancement only) |
| Affirmations feature | Wave 1 — Shipped | Intimacy action → Affirmation session launch (non-blocking) |
| Notification infrastructure | Available | PPP reminders |

---

## 15. Open Questions

1. **Bowtie visual on small screens:** The bowtie shape with 7 time intervals per side may be difficult to render on iPhone SE-sized screens. Should we default to list-based entry on smaller screens and reserve the visual diagram for larger screens?

2. **Role granularity for children:** The source material distinguishes "Father of Child 1" from "Father of Child 2" because each relationship carries unique emotional dynamics. Should we support sub-roles (e.g., "Father" with children as sub-entries), or keep roles flat and let the user create "Father — Oldest," "Father — Middle," etc.?

3. **Big Ticket Emotions to Three I's mapping accuracy:** The mapping (e.g., Rejection → Insignificance) is approximate and varies by person. Should the system suggest a mapping or let users define their own? If users define their own, analytics consistency is reduced.

4. **Bowtie frequency recommendations:** The source material suggests weekly Bowties for ongoing self-awareness and immediate Bowties after acting out/in events. Should the app actively prompt for a weekly Bowtie, or leave it entirely user-initiated?

5. **Spiritual lens as default or opt-in:** The source material treats the spiritual lens as integral to the Bowtie. In an overtly Christian app, should the spiritual processing step be included by default in the Backbone flow, or offered as an optional additional step?

6. **PPP follow-up timing:** When should the PPP follow-up prompt appear — at the anticipated time, 1 hour after, or the next time the user opens the app after the anticipated time?

7. **Bowtie and post-mortem relationship:** Should a retroactive Bowtie completed after a relapse automatically create or link to a post-mortem entry, or should they remain separate tools that can be cross-referenced?

8. **Time interval flexibility:** The source material uses 1h/3h/6h/12h/24h/36h/48h intervals but notes "the numbers aren't absolute." Should we allow users to place markers at arbitrary points on the timeline, or keep the fixed intervals as placement guides?

---

## 16. Success Criteria

| Criteria | Measurement | Target |
|----------|-------------|--------|
| Feature adopted by active users | Bowtie completions / active users | > 30% within 30 days of GA |
| Session completion rate (guided) | Completion rate | > 60% |
| Backbone processing depth | % of markers processed through Backbone | > 40% |
| PPP adoption on future markers | % of future markers with PPP entries | > 30% |
| Weekly practice retention | Users completing 1+ Bowtie/week at 30 days | > 20% of adopters |
| Post-relapse Bowtie usage | Relapse events followed by Bowtie within 48h | > 25% |
| Anticipatory growth | Future-side marker ratio increasing over 90 days | Positive trend |
| User-reported usefulness | In-app feedback: "Does the Bowtie help you understand yourself better?" | > 4.0/5.0 |
| Zero privacy incidents | Privacy breach count | 0 |
| Accessibility audit | WCAG 2.1 AA violations | 0 critical, < 5 minor |

---

*End of Document*

Feature Requirements Document v1.0 — Bowtie Diagram (Emotional Self-Awareness Activity)
