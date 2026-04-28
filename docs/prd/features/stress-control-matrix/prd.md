# Stress-Control Matrix -- Feature PRD

| Field | Value |
|---|---|
| **PRD Title** | Stress-Control Matrix |
| **Author** | Travis Smith |
| **Date** | 2026-04-23 |
| **Version** | 1.0 |
| **Designation** | Feature (within Recovery Tools Epic) |
| **OMTM** | Reduction in FASTER Scale Anxiety (A) and Stressed (S) stage check-ins among active matrix users over 8 weeks |
| **Target Delivery** | 3 sprints (30 business days maximum) |
| **MoSCoW Summary** | 12 Must, 7 Should, 5 Could, 4 Won't |
| **Feature Flag** | `activity.stress-matrix` |

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Product Overview](#2-product-overview)
3. [Matrix Structure](#3-matrix-structure)
4. [MoSCoW Prioritized Requirements](#4-moscow-prioritized-requirements)
5. [Functional Requirements](#5-functional-requirements)
6. [Non-Functional Requirements](#6-non-functional-requirements)
7. [Technical Considerations](#7-technical-considerations)
8. [User Stories](#8-user-stories)
9. [Implementation Roadmap](#9-implementation-roadmap)
10. [Open Questions and Risks](#10-open-questions-and-risks)
11. [Design Decisions Log](#11-design-decisions-log)

---

## 1. Executive Summary

### Problem Statement

Users in addiction recovery carry an undifferentiated mass of worries -- relationship damage, financial pressure, urge management, work stress, spiritual doubt, the future -- and lack a structured method to sort these stressors by what they can actually do about them. The result is chronic anxiety fueled by fixation on things beyond their control, which the FASTER Scale identifies as the Anxiety (A) and Speeding Up (S) stages of relapse progression. By the time a user recognizes this pattern, they are already deep into emotional escalation.

The Serenity Prayer -- "God, grant me the serenity to accept the things I cannot change, courage to change the things I can, and wisdom to know the difference" -- is prayed at the opening of every 12-step meeting. Yet the prayer offers no practical method for developing the "wisdom to know the difference." It names the skill without teaching it.

**User goal:** Quickly categorize daily stressors by controllability and importance, receive clear action guidance for each category, and track whether categorization skill improves over time.

**Hurdles:**
- Stressors feel equally urgent and overwhelming when experienced as an undifferentiated mass
- Users default to ruminating on uncontrollable stressors rather than acting on controllable ones
- The distinction between "can control" and "can't control" is genuinely difficult and requires practice
- Without structured externalization, worries remain abstract and resistant to logical evaluation

**Quantifiable impact:** Stress is one of the most robust predictors of relapse in addiction research (Sinha, 2001, 2007). Users who develop the ability to differentiate controllable from uncontrollable stressors and redirect energy accordingly should show reduced anxiety-driven FASTER escalation and improved recovery stability.

### Business Hypothesis

By providing a Stress-Control Matrix with fast stressor entry, quadrant-specific action prompts with scripture, a pre-populated stressor library, and longitudinal tracking of categorization patterns, we hypothesize that:

- **Primary outcome:** Active matrix users will show a 15-20% reduction in FASTER Scale Anxiety (A) and Stressed (S) stage check-ins after 8 weeks of use, compared to their pre-matrix baseline
- **Secondary outcome:** 60% of users who complete their first matrix session will use it at least once per week for 6+ weeks
- **OMTM impact:** Contributes to the Recovery Tools epic's overall retention improvement target

### Solution Overview

A Stress-Control Matrix tool within the Regal Recovery iOS app that:
1. **Stressor Entry** -- User adds stressors via text input or selection from a pre-populated library
2. **Quadrant Categorization** -- User places each stressor in one of four quadrants using tap-to-place selection
3. **Action Prompts** -- Each quadrant displays specific action guidance with relevant scripture and prayer prompts
4. **Matrix View** -- A 2x2 grid visualization showing all current stressors organized by quadrant
5. **Trend Tracking** -- Longitudinal view showing quadrant distribution changes over time

---

## 2. Product Overview

### Product Vision

The Stress-Control Matrix operationalizes the Serenity Prayer. Every recovering person prays for "wisdom to know the difference" -- this tool teaches that wisdom through daily practice. It sits alongside the FASTER Scale and Life Balance Index as a proactive recovery tool: the FASTER Scale tells you *where you are* on the relapse progression; the Stress-Control Matrix reveals *why you are there* by exposing which stressor misplacements are feeding your anxiety.

### Target Users

**Primary Persona: Alex (Active Recovery)**
- 6-18 months in SA/Celebrate Recovery
- Experiences daily stress from relationship repair, work pressure, and recovery demands
- Prays the Serenity Prayer regularly but struggles to apply it practically
- Needs: a tool to sort the chaos in their head into actionable categories

**Secondary Persona: Jordan (Early Recovery)**
- 0-6 months in recovery, high stress, everything feels urgent
- Often catastrophizes minor stressors and spirals into anxiety
- Needs: guided categorization with examples to learn the skill

**Tertiary Persona: Sam (Sponsor/Accountability Partner)**
- Reviews shared data from accountability partners
- Needs: visibility into whether a partner is fixating on uncontrollable stressors (a leading indicator of FASTER escalation)

### Value Proposition

"Sort your stress, focus your energy. The Stress-Control Matrix turns the Serenity Prayer into a daily practice -- showing you exactly where to act, what to surrender, and what to stop worrying about entirely."

### OMTM and Success Criteria

| Success Criterion | Target | Measurement Method |
|---|---|---|
| Weekly active usage | >= 60% of first-session completers still using at week 6 | Weekly usage cohort analysis |
| Stressor entry volume | >= 5 stressors per session (average) | Mean stressor count per matrix session |
| FASTER A/S stage reduction | 15-20% fewer A or S stage FASTER check-ins after 8 weeks | Pre/post FASTER stage distribution per user |
| Categorization growth | Quadrant distribution shifts toward Focus Here and Let Go over 8 weeks | Longitudinal quadrant distribution analysis |
| Session duration | <= 5 minutes per matrix session (median) | Time from session start to save |

### Scope Constraints

- **Feature scope:** Maximum 3 sprints (30 business days)
- **Platform:** iOS only (SwiftUI + SwiftData)
- **Tier:** Standard tier for V1 (no AI-assisted categorization)
- **Backend:** Local-first with SwiftData; API sync deferred
- **No therapist portal** in this scope

---

## 3. Matrix Structure

### The Four Quadrants

The matrix is a 2x2 grid with two axes:
- **Horizontal axis:** Can Control (left) / Can't Control (right)
- **Vertical axis:** Matters (top) / Doesn't Matter (bottom)

```
                    CAN CONTROL           CAN'T CONTROL
                +-----------------+-------------------+
                |                 |                   |
    MATTERS     |   FOCUS HERE    |     LET GO        |
                |   Take action   |   Accept, pray,   |
                |   Invest energy |   surrender        |
                |                 |                   |
                +-----------------+-------------------+
                |                 |                   |
  DOESN'T       |   MINIMIZE      |     IGNORE        |
  MATTER        |   Delegate or   |   Stop worrying   |
                |   reduce time   |   entirely         |
                |                 |                   |
                +-----------------+-------------------+
```

### Quadrant Definitions and Action Guidance

#### Q1: Focus Here (Matters + Can Control)

**Definition:** Stressors that are genuinely important to your recovery and life AND where you can take meaningful action.

**Action guidance:**
- Identify one specific next step you can take today
- Break large stressors into smaller controllable actions
- Schedule time to address this stressor
- Ask: "What is the smallest action I can take right now?"

**Recovery examples:** Attending today's meeting, calling my sponsor, completing step work, having a difficult conversation I've been avoiding, paying an overdue bill, exercising.

**Spiritual posture:** Stewardship -- faithful action on what God has entrusted to you.

**Scripture:**
- Colossians 3:23 -- "Whatever you do, work at it with all your heart, as working for the Lord."
- James 1:22 -- "Do not merely listen to the word... Do what it says."
- Proverbs 21:5 -- "The plans of the diligent lead to profit."

**Prayer prompt:** "Lord, give me clarity to see the right action and courage to take it. Help me be faithful with what you have entrusted to me."

---

#### Q2: Let Go (Matters + Can't Control)

**Definition:** Stressors that genuinely matter to you BUT where you cannot force an outcome -- outcomes that depend on other people's choices, timing beyond your control, or circumstances outside your influence.

**Action guidance:**
- Name what you cannot control about this stressor
- Pray specifically about this stressor -- transfer the burden to God
- Talk to your sponsor or counselor about it (share the weight)
- Practice acceptance: this is real pain, and it is not yours to fix
- Ask: "What would surrender look like for this specific thing?"

**Recovery examples:** My spouse's trust timeline, the consequences of past actions, other people's opinions of me, whether my marriage survives, how long recovery takes, my reputation.

**Spiritual posture:** Surrender -- entrusting what is beyond your power to God.

**Scripture:**
- 1 Peter 5:7 -- "Cast all your anxiety on him because he cares for you."
- Philippians 4:6-7 -- "Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God."
- Proverbs 3:5-6 -- "Trust in the Lord with all your heart and lean not on your own understanding."
- Psalm 46:10 -- "Be still, and know that I am God."
- Isaiah 41:10 -- "So do not fear, for I am with you."

**Prayer prompt:** "Father, I cannot control this. I have tried, and it has only brought me anxiety. I release this to you. I trust that you are working even when I cannot see it. Give me the serenity to accept what I cannot change."

---

#### Q3: Minimize (Doesn't Matter + Can Control)

**Definition:** Things you *could* act on but that are not genuinely important to your recovery or well-being -- energy drains, perfectionism targets, low-value busywork.

**Action guidance:**
- Delegate it if possible
- Set a strict time limit (15 minutes max) and then move on
- Ask: "Will this matter in a week? A month? A year?"
- Consider whether this is a distraction from something in Q1 you are avoiding

**Recovery examples:** Organizing a closet perfectly, winning an argument on social media, optimizing something that already works, worrying about minor appearance details, keeping up with news.

**Spiritual posture:** Wisdom -- not wasting the energy God gave you on what does not matter.

**Scripture:**
- Matthew 6:33 -- "But seek first his kingdom and his righteousness, and all these things will be given to you as well."
- Philippians 3:13-14 -- "Forgetting what is behind and straining toward what is ahead, I press on toward the goal."
- Ecclesiastes 11:4 -- "Whoever watches the wind will not plant; whoever looks at the clouds will not reap."

**Prayer prompt:** "Lord, help me not waste energy on distractions. Keep my eyes on what truly matters. Give me the freedom to leave imperfect things imperfect."

---

#### Q4: Ignore (Doesn't Matter + Can't Control)

**Definition:** Things that are neither important nor controllable -- worries that have attached themselves to you without good reason. Background noise.

**Action guidance:**
- Give yourself permission to stop thinking about this entirely
- When it resurfaces, notice it and let it pass ("That's not mine")
- Do not engage with it -- redirect your attention to Q1
- Ask: "Why am I carrying this?"

**Recovery examples:** What strangers think, news you cannot affect, hypothetical worst-case scenarios that may never happen, other people's problems that are not yours to solve, past events you cannot change and that no longer have real consequences.

**Spiritual posture:** Freedom -- the peace of a clear conscience and an uncluttered mind.

**Scripture:**
- Matthew 6:27 -- "Can any one of you by worrying add a single hour to your life?"
- Matthew 6:34 -- "Therefore do not worry about tomorrow, for tomorrow will worry about itself."
- Luke 12:25-26 -- "Who of you by worrying can add a single hour to your life? Since you cannot do this very little thing, why do you worry about the rest?"

**Prayer prompt:** "God, this is not mine to carry. Thank you for the freedom to let it go. I choose peace."

---

### Pre-Populated Stressor Library

Users can select from common stressors or enter custom text. Each library stressor has a suggested default quadrant (overridable).

#### Relational Stressors

| Stressor | Suggested Quadrant |
|---|---|
| Rebuilding trust with my spouse | Focus Here |
| My spouse's emotional timeline | Let Go |
| Conflict with a family member | Focus Here |
| Fear of being rejected | Let Go |
| Loneliness and isolation | Focus Here |
| Wanting my partner to forgive faster | Let Go |
| Having a difficult honest conversation | Focus Here |
| Other people's opinions of me | Ignore |

#### Work and Financial Stressors

| Stressor | Suggested Quadrant |
|---|---|
| Falling behind at work | Focus Here |
| Fear of losing my job | Let Go |
| Overdue bills or debt | Focus Here |
| The economy or market conditions | Ignore |
| Work-life balance | Focus Here |
| A coworker's behavior toward me | Let Go |
| Overspending or impulse purchases | Focus Here |

#### Recovery-Specific Stressors

| Stressor | Suggested Quadrant |
|---|---|
| Urge to act out | Focus Here |
| Shame about my past | Let Go |
| Missing a meeting | Focus Here |
| How long recovery takes | Let Go |
| Triggering content I encountered | Focus Here |
| Whether I'll ever fully recover | Let Go |
| Accountability call I've been avoiding | Focus Here |
| Comparing my recovery to others | Ignore |

#### Health Stressors

| Stressor | Suggested Quadrant |
|---|---|
| Not sleeping well | Focus Here |
| Chronic pain or illness | Let Go |
| Skipping exercise | Focus Here |
| Feeling exhausted | Focus Here |
| Aging or physical decline | Let Go |
| Side effects of medication | Minimize |

#### Emotional and Spiritual Stressors

| Stressor | Suggested Quadrant |
|---|---|
| Anxiety about the future | Let Go |
| Feeling distant from God | Focus Here |
| Guilt about specific past actions | Let Go |
| Boredom and restlessness | Focus Here |
| Anger at myself | Let Go |
| Feeling like God is silent | Let Go |
| Neglecting prayer or devotions | Focus Here |
| Doubting my faith | Let Go |

#### Circumstantial Stressors

| Stressor | Suggested Quadrant |
|---|---|
| Traffic and commute | Ignore |
| Weather | Ignore |
| News events and politics | Ignore |
| Waiting for test results or decisions | Let Go |
| Household chores piling up | Focus Here |
| Technology problems | Minimize |

---

## 4. MoSCoW Prioritized Requirements

### Must Have

| ID | Requirement | Rationale |
|---|---|---|
| M1 | 2x2 matrix grid with four labeled quadrants | Core framework visualization |
| M2 | User can add stressors via free-text input (max 200 characters) | Primary entry method; must support custom stressors |
| M3 | User places each stressor in one of four quadrants via tap selection | Core categorization interaction |
| M4 | Each quadrant displays action guidance, scripture, and a prayer prompt | The matrix is actionless without guidance; spiritual integration is core to the app |
| M5 | Pre-populated stressor library organized by category | Reduces entry friction; helps users who struggle to articulate stressors |
| M6 | Matrix session is persisted to SwiftData with all stressors and their quadrant placements | Offline-first; data must survive app termination |
| M7 | User can review past matrix sessions | Reflection on past categorization is a key therapeutic benefit |
| M8 | User can move a stressor between quadrants after initial placement | Categorization is iterative; initial placement may be wrong |
| M9 | Matrix accessible from Recovery Work tab and Today view | Must be discoverable in primary navigation |
| M10 | Feature gated behind `activity.stress-matrix` feature flag | Architectural requirement -- all features ship behind flags |
| M11 | Stressor text is stored locally only; never transmitted without explicit user action | Privacy by architecture; stressor text is sensitive |
| M12 | User can delete individual stressors or entire sessions | User data control |

### Should Have

| ID | Requirement | Rationale |
|---|---|---|
| S1 | Quadrant distribution summary showing percentage of stressors in each quadrant | Visual insight into where energy is being spent |
| S2 | Trend tracking: quadrant distribution over time (weekly/monthly view) | Longitudinal growth visibility -- "am I getting better at this?" |
| S3 | Integration with FASTER Scale: prompt matrix exercise when A or S stage detected | Connects the diagnostic tool (FASTER) with the intervention tool (matrix) |
| S4 | Journal prompt generation from matrix entries | Deepens reflection beyond categorization |
| S5 | Stressor re-categorization tracking: when users move stressors between quadrants, record the change | Measures growing discernment |
| S6 | Accountability partner sharing: quadrant distribution only (not stressor text) | Accountability without privacy violation |
| S7 | Evening notification prompting matrix review on high-stress days | Engagement driver linked to when the tool is most needed |

### Could Have

| ID | Requirement | Rationale |
|---|---|---|
| C1 | AI-assisted categorization suggestions (Premium+) | Helps users who struggle with the control/importance evaluation |
| C2 | Drag-and-drop stressor placement on iPad | Richer interaction on larger screens |
| C3 | Stressor recurrence tracking: flag stressors that appear in multiple sessions | Identifies chronic stress patterns |
| C4 | Action plan generation from Q1 (Focus Here) stressors | Moves from awareness to structured action |
| C5 | Integration with emergency layer: simplified matrix during active urge | "What stressor is driving this urge? Can you control it?" |

### Won't Have

| ID | Requirement | Rationale |
|---|---|---|
| W1 | Backend API sync for matrix data | Deferred to sync epic |
| W2 | Therapist portal view of client matrix sessions | Requires backend infrastructure not in scope |
| W3 | Stressor intensity rating (1-10 scale) | Adds complexity without proven benefit; importance axis already captures salience |
| W4 | Automated stressor categorization without user input | The categorization process itself is the therapeutic intervention; automation defeats the purpose |

---

## 5. Functional Requirements

### 5.1 Matrix Session Creation

| ID | Requirement | Priority | Conditions of Satisfaction |
|---|---|---|---|
| FR-01 | User can start a new matrix session from the Recovery Work tab or Today view | Must | Given the user taps "Stress-Control Matrix," When the session screen opens, Then a blank matrix grid is displayed with four labeled quadrants |
| FR-02 | User can add a stressor via free-text input with a 200-character limit | Must | Given the session is open, When the user taps "Add Stressor" and types text, Then the text field accepts up to 200 characters and shows a character counter |
| FR-03 | User can select a stressor from the pre-populated library organized by category | Must | Given the user taps "Add from Library," When the library sheet opens, Then stressors are organized by category (Relational, Work/Financial, Recovery, Health, Emotional/Spiritual, Circumstantial) with search |
| FR-04 | User places each stressor in a quadrant by tapping one of four labeled buttons | Must | Given a stressor has been entered, When the placement screen shows, Then four buttons display quadrant names with brief descriptions, and tapping one places the stressor |
| FR-05 | Library stressors pre-fill a suggested quadrant that the user can accept or change | Must | Given the user selects "My spouse's emotional timeline" from the library, When the placement screen shows, Then "Let Go" is pre-selected but all four quadrants are tappable |
| FR-06 | After placement, the stressor appears in its quadrant on the matrix grid view | Must | Given a stressor is placed in Q1 (Focus Here), When the matrix grid renders, Then the stressor text appears in the upper-left quadrant |
| FR-07 | User can continue adding stressors to the same session (no limit enforced, soft guidance at 15+) | Must | Given 15 stressors have been added, When the user adds a 16th, Then a gentle message suggests "Consider whether all of these need your attention right now" but does not prevent entry |

### 5.2 Quadrant Interaction

| ID | Requirement | Priority | Conditions of Satisfaction |
|---|---|---|---|
| FR-08 | Each quadrant on the grid is tappable and expands to show all stressors, action guidance, scripture, and prayer prompt | Must | Given the matrix has stressors in Q2 (Let Go), When the user taps the Q2 section, Then a detail view shows all Q2 stressors, the action guidance text, scripture verses, and the prayer prompt |
| FR-09 | User can move a stressor from one quadrant to another at any time during the session | Must | Given a stressor is in Q1, When the user long-presses or swipes the stressor and selects a new quadrant, Then the stressor moves to the new quadrant with animation |
| FR-10 | User can delete a stressor from the session | Must | Given a stressor exists in a quadrant, When the user swipes to delete, Then the stressor is removed with confirmation |
| FR-11 | User can edit the text of a custom stressor (library stressors are not editable) | Should | Given a custom stressor exists, When the user taps to edit, Then the text field is editable with the 200-character limit |

### 5.3 Session Persistence and Review

| ID | Requirement | Priority | Conditions of Satisfaction |
|---|---|---|---|
| FR-12 | Session is auto-saved to SwiftData as stressors are added/moved | Must | Given the user adds 3 stressors, When the app is force-quit, Then reopening shows the session with all 3 stressors in their placed quadrants |
| FR-13 | User can save/complete a session, which timestamps it and marks it as complete | Must | Given the user taps "Done," When the session is saved, Then it receives a completion timestamp and appears in the session history |
| FR-14 | User can view a list of past sessions sorted by date (most recent first) | Must | Given the user navigates to matrix history, When the list renders, Then each entry shows the date, stressor count, and quadrant distribution summary |
| FR-15 | User can open a past session in read-only mode to review their categorization | Must | Given the user taps a past session, When it opens, Then the matrix grid displays with all stressors in their recorded quadrants, action guidance visible |
| FR-16 | User can start a new session pre-populated with unresolved stressors from the previous session | Should | Given the user starts a new session, When prompted "Carry forward unresolved stressors?", Then stressors from the last session are copied into the new session with their previous quadrant placement |

### 5.4 Scripture and Prayer Integration

| ID | Requirement | Priority | Conditions of Satisfaction |
|---|---|---|---|
| FR-17 | Each quadrant displays 2-3 relevant scripture verses | Must | Given the user views Q2 (Let Go) detail, When the scripture section renders, Then 1 Peter 5:7, Philippians 4:6-7, and Proverbs 3:5-6 are displayed with full text |
| FR-18 | Each quadrant displays a prayer prompt | Must | Given the user views Q1 (Focus Here) detail, When the prayer section renders, Then the prayer "Lord, give me clarity to see the right action and courage to take it..." is displayed |
| FR-19 | User can mark a stressor as "prayed over" | Should | Given a stressor is in Q2 (Let Go), When the user taps a prayer icon on the stressor, Then the stressor is visually marked as prayed-over (subtle indicator) |

### 5.5 Trend Tracking

| ID | Requirement | Priority | Conditions of Satisfaction |
|---|---|---|---|
| FR-20 | Dashboard shows quadrant distribution as a pie chart or bar chart for the current session | Should | Given the session has 10 stressors (4 in Q1, 3 in Q2, 2 in Q3, 1 in Q4), When the distribution view renders, Then a chart shows 40% Focus Here, 30% Let Go, 20% Minimize, 10% Ignore |
| FR-21 | Trend view shows quadrant distribution changes over the last 8 weeks | Should | Given the user has 6 weeks of sessions, When the trend view renders, Then a stacked bar chart or area chart shows weekly quadrant distribution with the percentage in each quadrant |
| FR-22 | Stressor re-categorization events are recorded when a user moves a stressor between quadrants | Should | Given the user moves "spouse's trust timeline" from Q1 to Q2, When the move is saved, Then a re-categorization record is stored with from-quadrant, to-quadrant, and timestamp |

### 5.6 Integration

| ID | Requirement | Priority | Conditions of Satisfaction |
|---|---|---|---|
| FR-23 | FASTER Scale check-in at Anxiety (A) or Stressed (S) stage triggers a prompt: "Would you like to sort your stressors?" | Should | Given the user completes a FASTER check-in with stage A or S, When the check-in is saved, Then a card appears: "Your FASTER check-in shows anxiety. A Stress Matrix session can help sort what's driving it." |
| FR-24 | Matrix session completion appears in the Today view activity feed | Must | Given the user completes a matrix session, When the Today view refreshes, Then a card shows "Stress Matrix: X stressors sorted" with the quadrant distribution |
| FR-25 | Matrix entries can generate a journal prompt: "You placed [stressor] in [quadrant]. Write about what [action guidance] looks like for this." | Should | Given the user taps "Journal about this" on a stressor, When the journal entry screen opens, Then the prompt is pre-filled with the stressor text and quadrant-specific reflection question |

---

## 6. Non-Functional Requirements

### 6.1 Performance

| ID | Requirement | Target |
|---|---|---|
| NFR-01 | Matrix grid render time (up to 20 stressors) | < 500ms on iPhone 13+ |
| NFR-02 | Stressor add/move animation | < 300ms |
| NFR-03 | Session save time | < 200ms |
| NFR-04 | Session history list render (50+ sessions) | < 1 second |
| NFR-05 | Trend chart render (8 weeks) | < 1 second |

### 6.2 Security and Privacy

| ID | Requirement | Target |
|---|---|---|
| NFR-06 | Stressor text stored locally in SwiftData only | Enforced by architecture (no API in scope) |
| NFR-07 | Accountability sharing shares quadrant percentages only, never stressor text | Enforced by sharing data model |
| NFR-08 | Biometric lock protects matrix data alongside all other app data | Inherited from app-level biometric gate |
| NFR-09 | Matrix data included in full data export (DSR compliance) | Included in existing export pipeline |

### 6.3 Usability

| ID | Requirement | Target |
|---|---|---|
| NFR-10 | First matrix session completable in under 5 minutes with 5+ stressors | User testing validation |
| NFR-11 | Stressor entry to quadrant placement takes under 15 seconds per stressor | Measured by median time |
| NFR-12 | All text meets WCAG 2.1 AA contrast ratios | Automated accessibility audit |
| NFR-13 | VoiceOver fully supports matrix grid, stressor entry, and quadrant navigation | Manual accessibility testing |
| NFR-14 | Dynamic Type support for all matrix screens | Tested at all system text sizes |

### 6.4 Reliability

| ID | Requirement | Target |
|---|---|---|
| NFR-15 | No data loss if app terminates mid-session (auto-save after each stressor add/move) | Tested via force-quit during session |
| NFR-16 | Session history is never deleted by the app; only user-initiated deletion | Enforced by data model |

---

## 7. Technical Considerations

### 7.1 Architecture Overview

The Stress-Control Matrix follows the existing app architecture: MVVM with SwiftData persistence, `@Observable` view models, and integration with `ServiceContainer`.

```
Views (SwiftUI)
  |
  v
ViewModels (@Observable)
  |
  v
Models (@Model + Codable types)
  |
  v
SwiftData (local persistence)
```

### 7.2 Data Model (SwiftData)

```swift
// MARK: - Stress Matrix Session

@Model
final class RRStressMatrixSession {
    var id: UUID
    var userId: UUID
    var date: Date                    // Session date (startOfDay)
    var completedAt: Date?            // nil = in-progress
    var stressorsJSON: String         // JSON-encoded [StressMatrixStressor]
    var quadrantDistribution: String  // JSON-encoded [String: Int] quadrant -> count
    var createdAt: Date
    var modifiedAt: Date
    var needsSync: Bool

    init(userId: UUID) {
        self.id = UUID()
        self.userId = userId
        self.date = Calendar.current.startOfDay(for: Date())
        self.completedAt = nil
        self.stressorsJSON = "[]"
        self.quadrantDistribution = "{}"
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.needsSync = true
    }
}

// MARK: - Supporting Codable Types

enum StressQuadrant: String, Codable, CaseIterable {
    case focusHere = "focus_here"        // Matters + Can Control
    case letGo = "let_go"               // Matters + Can't Control
    case minimize = "minimize"           // Doesn't Matter + Can Control
    case ignore = "ignore"              // Doesn't Matter + Can't Control
}

struct StressMatrixStressor: Codable, Identifiable {
    var id: UUID
    var text: String                    // Max 200 chars
    var quadrant: StressQuadrant
    var isFromLibrary: Bool
    var libraryCategory: String?        // e.g., "relational", "recovery"
    var isPrayedOver: Bool
    var addedAt: Date
    var recategorizations: [StressorRecategorization]
}

struct StressorRecategorization: Codable {
    var fromQuadrant: StressQuadrant
    var toQuadrant: StressQuadrant
    var timestamp: Date
}
```

### 7.3 Key Technical Decisions

1. **JSON-encoded stressor array in SwiftData:** Follows the existing pattern used by FASTER Scale and PCI features. The `stressorsJSON` field stores the complete stressor list with quadrant assignments, prayed-over state, and recategorization history.

2. **Session-based model:** Each matrix exercise is a discrete session (unlike the PCI which is a rolling daily tracker). A user may have 0-2 sessions per week. Sessions can be left in-progress (auto-saved) and completed later.

3. **Quadrant distribution cached:** The `quadrantDistribution` JSON field is a cached computation updated on every stressor add/move. This avoids re-decoding the full stressor list for list views and trend calculations.

4. **Recategorization tracking embedded:** Each stressor carries its own recategorization history, enabling both per-stressor and aggregate recategorization analysis.

### 7.4 Integration Points

| Integration | Mechanism | Scope |
|---|---|---|
| FASTER Scale prompt | After FASTER check-in at A/S stage, surface prompt card | Should (S3) |
| Today view activity feed | Completed session rendered as a card | Must (FR-24) |
| Journaling | Deep-link from stressor to pre-filled journal entry | Should (S4/FR-25) |
| Accountability sharing | Quadrant distribution only, via existing sharing infrastructure | Should (S6) |
| Feature flags | `activity.stress-matrix` gates feature visibility | Must (M10) |

### 7.5 Infrastructure

No additional infrastructure required. All data is local (SwiftData). Feature flag evaluated from existing `RRFeatureFlag` model.

---

## 8. User Stories

### Epic: Stress-Control Matrix

---

### Story 1: Create a Matrix Session with Custom Stressors

**As a** recovering person feeling stressed and overwhelmed,
**I want** to write down what is bothering me and categorize each stressor by whether I can control it and whether it matters,
**So that** I can see my stress clearly organized instead of carrying it as an undifferentiated mass of anxiety.

**Priority:** Must (M1, M2, M3, M6)
**Story Points:** 8

**Conditions of Satisfaction:**

- Given I navigate to Stress-Control Matrix, When the session screen opens, Then I see a blank 2x2 grid with labeled quadrants (Focus Here, Let Go, Minimize, Ignore) and an "Add Stressor" button
- Given I tap "Add Stressor," When I type "Rebuilding trust with my wife" (34 chars), Then the text is accepted and a character counter shows "34/200"
- Given I have entered stressor text, When the quadrant selection appears, Then four buttons show quadrant names with one-line descriptions and I can tap one to place the stressor
- Given I place the stressor in "Focus Here," When the matrix grid renders, Then the stressor text appears in the upper-left quadrant
- Given I have placed 5 stressors, When I force-quit and reopen the app, Then the session is restored with all 5 stressors in their quadrants
- Given I have placed stressors in multiple quadrants, When I view the matrix grid, Then each quadrant shows its stressor count and the stressor text items

---

### Story 2: Select Stressors from the Library

**As a** recovering person who struggles to articulate what is stressing me,
**I want** to select from common recovery stressors organized by category,
**So that** I can quickly populate my matrix even when I cannot find the words myself.

**Priority:** Must (M5)
**Story Points:** 5

**Conditions of Satisfaction:**

- Given I tap "Add from Library," When the library sheet opens, Then stressors are organized by category with section headers (Relational, Work/Financial, Recovery, Health, Emotional/Spiritual, Circumstantial)
- Given the library is open, When I search for "spouse," Then matching stressors are filtered (e.g., "Rebuilding trust with my spouse," "My spouse's emotional timeline")
- Given I select "My spouse's emotional timeline," When the quadrant selection appears, Then "Let Go" is pre-selected as the suggested quadrant
- Given the suggested quadrant is "Let Go," When I decide it belongs in "Focus Here" instead, Then I can tap "Focus Here" to override the suggestion
- Given I select a library stressor, When it is placed, Then the stressor is marked as `isFromLibrary = true` and cannot be edited (but can be moved between quadrants)

---

### Story 3: Quadrant Detail View with Action Guidance and Scripture

**As a** recovering person who has categorized my stressors,
**I want** to see specific action guidance, scripture, and a prayer prompt for each quadrant,
**So that** I know what to do with the stressors I have identified and can bring them before God.

**Priority:** Must (M4)
**Story Points:** 5

**Conditions of Satisfaction:**

- Given I tap the "Let Go" quadrant, When the detail view opens, Then I see: all stressors in this quadrant, the action guidance ("Name what you cannot control...", "Pray specifically...", "Talk to your sponsor..."), 2-3 scripture verses with full text, and a prayer prompt
- Given I view the "Focus Here" detail, When I read the action guidance, Then it includes: "Identify one specific next step you can take today" and "Break large stressors into smaller controllable actions"
- Given I view any quadrant detail, When I scroll to the scripture section, Then each verse shows the reference and full text (e.g., "1 Peter 5:7 -- Cast all your anxiety on him because he cares for you.")
- Given I view any quadrant detail, When I scroll to the prayer section, Then a quadrant-specific prayer prompt is displayed with a visual treatment that distinguishes it from action guidance

---

### Story 4: Move Stressors Between Quadrants

**As a** recovering person reflecting on my matrix,
**I want** to move a stressor to a different quadrant when I realize my initial categorization was wrong,
**So that** my matrix reflects my growing discernment about what I can and cannot control.

**Priority:** Must (M8)
**Story Points:** 3

**Conditions of Satisfaction:**

- Given a stressor is in the "Focus Here" quadrant, When I long-press it, Then a move menu appears with the three other quadrant options
- Given I select "Let Go" from the move menu, When the move completes, Then the stressor animates from Q1 to Q2 and the quadrant counts update
- Given I move a stressor, When the move is saved, Then a recategorization record is stored with the from-quadrant, to-quadrant, and timestamp
- Given a stressor has been moved twice, When I view its history (long-press -> "View History"), Then I see the original placement and both moves with timestamps

---

### Story 5: Review Past Matrix Sessions

**As a** recovering person who wants to track my growth in discernment,
**I want** to review past matrix sessions and see how my stress categorization has changed over time,
**So that** I can recognize progress in the "wisdom to know the difference."

**Priority:** Must (M7)
**Story Points:** 5

**Conditions of Satisfaction:**

- Given I navigate to Matrix History, When the list renders, Then past sessions are listed by date (most recent first) with stressor count and quadrant distribution (e.g., "April 20: 8 stressors -- 3 Focus, 3 Let Go, 1 Minimize, 1 Ignore")
- Given I tap a past session, When it opens, Then the matrix grid displays in read-only mode with all stressors in their recorded quadrants
- Given I view a past session, When I tap a quadrant, Then the detail view shows the stressors, action guidance, and scripture (same as active session, but read-only)
- Given I have 4+ weeks of sessions, When I navigate to the trend view, Then a stacked bar chart shows weekly quadrant distribution percentages

---

### Story 6: Carry Forward Unresolved Stressors

**As a** recovering person starting a new matrix session,
**I want** the option to carry forward stressors from my last session that are still active,
**So that** I do not have to re-enter recurring stressors from scratch.

**Priority:** Should (FR-16)
**Story Points:** 3

**Conditions of Satisfaction:**

- Given I start a new session and have a previous session, When the new session screen opens, Then a prompt asks "Carry forward X stressors from your last session?"
- Given I tap "Yes," When the stressors are carried forward, Then they appear in their previous quadrants and I can move or delete them
- Given I tap "No" or "Start Fresh," When the session opens, Then it is blank
- Given stressors are carried forward, When I view the new session, Then carried-forward stressors are visually distinct (e.g., a subtle "carried forward" label) from newly added stressors

---

### Story 7: Mark Stressors as Prayed Over

**As a** recovering person surrendering uncontrollable stressors to God,
**I want** to mark stressors as "prayed over" after bringing them before God in prayer,
**So that** I have a tangible record of surrendering my worries and can see how many of my concerns I have entrusted to God.

**Priority:** Should (FR-19)
**Story Points:** 2

**Conditions of Satisfaction:**

- Given a stressor is in any quadrant, When I tap a prayer icon on the stressor, Then a subtle visual indicator (e.g., a small cross or checkmark) appears on the stressor
- Given a stressor is marked as prayed over, When I view the quadrant detail, Then prayed-over stressors are visually distinct from unprayed ones
- Given the session has 8 stressors, When 5 are marked as prayed over, Then a summary shows "5 of 8 stressors prayed over"

---

### Story 8: Quadrant Distribution Summary

**As a** recovering person who has completed a matrix session,
**I want** to see a visual summary of where my stressors landed,
**So that** I can immediately see if I am spending disproportionate energy on things I cannot control.

**Priority:** Should (S1)
**Story Points:** 3

**Conditions of Satisfaction:**

- Given the session has 10 stressors distributed across quadrants, When I view the distribution summary, Then a pie chart or segmented bar shows the percentage in each quadrant with quadrant colors
- Given 60% of stressors are in "Let Go," When the summary renders, Then a gentle insight message appears: "Most of your stress is about things outside your control. The Serenity Prayer is for moments like this."
- Given 0 stressors are in "Focus Here," When the summary renders, Then an insight says: "Nothing in your Focus quadrant -- are there actions you might be avoiding?"

---

### Story 9: Today View and Navigation Integration

**As a** recovering person using the Today view as my daily hub,
**I want** to see my matrix completion and access the feature from the main navigation,
**So that** the Stress-Control Matrix is part of my daily recovery routine.

**Priority:** Must (M9, FR-24)
**Story Points:** 3

**Conditions of Satisfaction:**

- Given I navigate to the Recovery Work tab, When I look for the Stress-Control Matrix tile, Then a tile labeled "Stress Matrix" with an appropriate icon is visible (feature flag controlled)
- Given I complete a matrix session with 7 stressors, When I view the Today screen, Then an activity card shows "Stress Matrix: 7 stressors sorted" with quadrant distribution
- Given I have not done a matrix session today, When I view the Today screen, Then no matrix card appears (the feature does not nag)

---

### Story 10: FASTER Scale Integration

**As a** recovering person who just checked in at the Anxiety or Stressed stage on the FASTER Scale,
**I want** to be prompted to do a Stress-Control Matrix session,
**So that** I can identify and sort the stressors driving my FASTER escalation.

**Priority:** Should (S3)
**Story Points:** 3

**Conditions of Satisfaction:**

- Given I complete a FASTER Scale check-in at stage A (Anxiety), When the check-in is saved, Then a card appears: "Your FASTER check-in shows anxiety building. Would you like to sort your stressors?" with a "Start Matrix" button
- Given the prompt appears, When I tap "Start Matrix," Then a new matrix session opens
- Given the prompt appears, When I tap "Not now," Then the prompt is dismissed and does not reappear until the next FASTER check-in at A or S
- Given I complete a FASTER check-in at stage F, T, E, or R, When the check-in is saved, Then no matrix prompt appears (matrix is most useful at A and S stages)

---

### Story Point Summary

| Story | Title | Points | Priority | Sprint |
|---|---|---|---|---|
| S1 | Create Matrix Session | 8 | Must | 1 |
| S2 | Library Selection | 5 | Must | 1 |
| S3 | Quadrant Detail View | 5 | Must | 1 |
| S4 | Move Between Quadrants | 3 | Must | 1 |
| S5 | Review Past Sessions | 5 | Must | 2 |
| S6 | Carry Forward Stressors | 3 | Should | 2 |
| S7 | Prayed Over Marking | 2 | Should | 2 |
| S8 | Distribution Summary | 3 | Should | 2 |
| S9 | Navigation Integration | 3 | Must | 2 |
| S10 | FASTER Integration | 3 | Should | 3 |
| **Total** | | **40** | | |

---

## 9. Implementation Roadmap

### Sprint 1: Core Matrix (Ready)

**Sprint Goal:** Users can create matrix sessions, add stressors (custom and library), place them in quadrants, view action guidance with scripture, and move stressors between quadrants.

**Stories:** S1 (8), S2 (5), S3 (5), S4 (3) = 21 points

**Key Tasks:**
- Create `RRStressMatrixSession` SwiftData model and supporting Codable types
- Create stressor library static data file
- Build `StressMatrixViewModel` (session state, stressor CRUD, quadrant management)
- Build quadrant content data (action guidance, scripture, prayer prompts per quadrant)
- Build `StressMatrixView` (2x2 grid, stressor entry, tap-to-place flow)
- Build `StressMatrixQuadrantDetailView` (stressor list, guidance, scripture, prayer)
- Build stressor library sheet with category grouping and search
- Implement stressor move with recategorization tracking
- Feature flag seed: `activity.stress-matrix`
- Register model in `RRModelConfiguration.allModels`

**Dependencies:** None (greenfield feature)

### Sprint 2: History, Trends, and Navigation (Ready)

**Sprint Goal:** Users can review past sessions, carry forward stressors, mark stressors as prayed over, see distribution summaries, and access the feature from main navigation.

**Stories:** S5 (5), S6 (3), S7 (2), S8 (3), S9 (3) = 16 points

**Key Tasks:**
- Build session history list view
- Build read-only past session view
- Implement carry-forward logic
- Add prayed-over state to stressor model and UI
- Build quadrant distribution pie chart (Swift Charts)
- Implement trend view (weekly distribution over 8 weeks)
- Wire into `ActivityDestinationView`, `RecoveryWorkView`, `RecoveryWorkViewModel`
- Add matrix completion to Today view activity feed
- Add completion tracking to `TodayViewModel`

**Dependencies:** Sprint 1 (core matrix functional)

### Sprint 3: Integration and Polish (Stub)

**Sprint Goal:** Matrix integrates with FASTER Scale prompts, journal prompt generation, and accountability sharing.

**Stories:** S10 (3) + integration tasks

**Key Tasks:**
- FASTER Scale A/S stage prompt after check-in
- Journal prompt generation from stressor + quadrant
- Accountability sharing: quadrant distribution
- End-to-end testing of full matrix lifecycle
- Accessibility audit and polish

**Dependencies:** Sprint 2

### Dependency Map

```
Sprint 1                    Sprint 2                    Sprint 3
---------                   ---------                   ---------
S1 Matrix Session --------> S5 Past Sessions
S2 Library Selection         S6 Carry Forward
S3 Quadrant Detail           S7 Prayed Over
S4 Move Stressors --------> S8 Distribution Summary ---> S10 FASTER Integration
                             S9 Navigation Integration
```

---

## 10. Open Questions and Risks

### Open Questions

| # | Question | Impact | Status |
|---|---|---|---|
| OQ-1 | Should the matrix support multiple sessions per day, or one session per day that can be reopened and edited? | Affects data model (session-per-day vs. unlimited) | Open -- recommend session-per-day with edit capability, matching the PCI daily model |
| OQ-2 | Should the "Doesn't Matter" row use different language? Some users may resist categorizing anything as "doesn't matter." Alternatives: "Low Priority," "Not Urgent," "Background." | Affects quadrant labels and copy | Open -- user testing needed |
| OQ-3 | Should there be a "Guided Questions" mode where the app asks "Can you do something about this? Does this genuinely matter?" to help with categorization, or is tap-to-place sufficient? | Affects entry flow complexity | Open -- recommend tap-to-place for V1, guided mode as future enhancement |
| OQ-4 | How should the matrix interact with the existing journaling feature? Should it auto-create a journal entry, pre-fill a prompt, or just link to a new entry? | Affects FR-25 implementation | Open |
| OQ-5 | Should the trend view show individual stressor movement (e.g., "spouse's trust timeline moved from Focus Here to Let Go over 3 weeks") or only aggregate distribution? | Affects trend complexity and privacy considerations | Open -- recommend aggregate for V1 |

### Risks

| # | Risk | Probability | Impact | Mitigation |
|---|---|---|---|---|
| R-1 | Users find the 2x2 framework too simplistic for complex life stressors | Medium | Medium | Frame the matrix as a starting point, not a complete analysis. Encourage sponsor/therapist discussion for complex items. |
| R-2 | Users avoid the "Doesn't Matter" row, placing everything in "Matters" | Medium | Low | Provide gentle prompts: "Consider whether this will matter in a year." The distribution summary makes imbalance visible. |
| R-3 | Categorization disagreements with sponsor/therapist | Low | Medium | The matrix is personal, not prescriptive. Include copy: "Your sponsor may see this differently -- that is a conversation worth having." |
| R-4 | Feature is used once and abandoned (no engagement loop) | Medium | High | FASTER integration (S10) creates a trigger-based engagement loop. Carry-forward (S6) reduces friction for repeat use. |
| R-5 | Library stressor suggestions feel judgmental ("you should categorize spouse's timeline as Let Go") | Low | Medium | Frame suggestions as defaults, not directives. "Often placed in Let Go -- but only you know your situation." |

---

## 11. Design Decisions Log

### Decision D1: Session Model vs. Running List

**Options:**
1. Discrete sessions: each matrix exercise is a timestamped session with its own stressor set
2. Running list: one continuous matrix where stressors are added and removed over time

**Chosen:** Option 1 -- Discrete sessions

**Rationale:** Sessions create clear temporal boundaries that enable longitudinal comparison ("my matrix from April 20 vs. April 27"). A running list would lose the snapshot-in-time quality that makes trend tracking meaningful. Sessions also align with the app's other activity patterns (FASTER check-ins, journal entries) which are discrete events, not running documents.

---

### Decision D2: Stressor Entry Method

**Options:**
1. Drag-and-drop onto a grid
2. Tap-to-place (enter text, then tap a quadrant button)
3. Guided questions (answer two yes/no questions to auto-place)

**Chosen:** Option 2 -- Tap-to-place

**Rationale:** Drag-and-drop is difficult on small iPhone screens and has accessibility barriers (VoiceOver, motor impairment). Guided questions add friction and remove the user's agency in categorization -- part of the therapeutic value is making the judgment call yourself. Tap-to-place is fast, accessible, and preserves the deliberate categorization that gives the tool its clinical value. Guided questions may be added as an optional mode in a future version.

---

### Decision D3: Library Stressor Editability

**Options:**
1. Library stressors are fully editable after selection
2. Library stressors are read-only; users must enter a custom stressor for variations

**Chosen:** Option 2 -- Library stressors are read-only

**Rationale:** Read-only library stressors enable aggregate analysis across users (if/when backend sync is added). If "My spouse's emotional timeline" is tracked as a standardized library item, the app can eventually surface insights like "most users place this in Let Go." Editable library items lose this standardization. Users who need a variation should enter a custom stressor, which is always available.

---

### Decision D4: Quadrant Label Language

**Options:**
1. Academic: "Matters + Can Control," "Matters + Can't Control," etc.
2. Action-oriented: "Focus Here," "Let Go," "Minimize," "Ignore"
3. Spiritual: "Act," "Surrender," "Simplify," "Release"

**Chosen:** Option 2 -- Action-oriented labels with spiritual context in detail views

**Rationale:** "Focus Here" and "Let Go" are immediately understood without explanation. Academic labels require cognitive overhead. Spiritual labels are meaningful but too opaque for first use. The spiritual dimension (surrender, stewardship, trust) is communicated through the scripture and prayer prompts in the quadrant detail views rather than through the primary labels.

---

### Decision D5: Stressor Count Limits

**Options:**
1. No limit (users can add unlimited stressors)
2. Hard limit (e.g., 10 stressors per session)
3. Soft limit with guidance (unlimited but gentle nudge at 15+)

**Chosen:** Option 3 -- Soft limit with guidance

**Rationale:** Hard limits feel arbitrary and may frustrate users during genuinely high-stress periods. No limit risks encouraging exhaustive listing rather than focused reflection. The soft nudge at 15+ stressors ("Consider whether all of these need your attention right now") encourages focus without restricting access.

---

### Decision D6: Accountability Sharing Scope

**Options:**
1. Share quadrant distribution only (no stressor text)
2. Share stressor text and quadrant assignments
3. Share nothing (matrix is fully private)

**Chosen:** Option 1 -- Quadrant distribution only

**Rationale:** Stressor text is deeply personal ("fear of my marriage ending," "shame about what I did"). Sharing this without granular consent risks discouraging honest matrix use. However, quadrant distribution ("70% of your stressors are things you can't control") is actionable accountability data that a sponsor can use to initiate a conversation. This matches the PCI sharing model (scores and risk levels, not indicator text).

---

### Decision D7: Prayed-Over Feature

**Options:**
1. No prayed-over tracking (keep the matrix secular)
2. Prayed-over as a binary flag on any stressor
3. Prayed-over only for Q2 (Let Go) stressors

**Chosen:** Option 2 -- Binary flag on any stressor

**Rationale:** While the "Let Go" quadrant most naturally maps to prayer, users may want to pray over stressors in any quadrant (praying for wisdom to act on Q1 items, praying for freedom from Q4 items). Restricting prayer tracking to one quadrant would feel arbitrary. The flag is optional and unobtrusive -- a small icon tap, not a required step. This reflects the app's Christian integration principle: prayer is relevant to every area of life, not just surrender.

---

*End of Design Decisions Log*

---

## Appendix A: Quadrant Content Reference

| Quadrant | Label | Spiritual Posture | Primary Scripture | Prayer Type |
|---|---|---|---|---|
| Q1 | Focus Here | Stewardship | Colossians 3:23 | Prayer for wisdom and strength |
| Q2 | Let Go | Surrender | 1 Peter 5:7 | Prayer of surrender and trust |
| Q3 | Minimize | Wisdom | Matthew 6:33 | Prayer for focus and priorities |
| Q4 | Ignore | Freedom | Matthew 6:27 | Prayer of freedom from anxiety |

## Appendix B: Stressor Library Categories

| Category | Count | Example Items |
|---|---|---|
| Relational | 8 | Rebuilding trust, spouse's timeline, conflict, rejection fear |
| Work/Financial | 7 | Falling behind, job fear, debt, economy, work-life balance |
| Recovery-Specific | 8 | Urge to act out, shame, missing meetings, recovery timeline |
| Health | 6 | Sleep, chronic pain, exercise, exhaustion, aging |
| Emotional/Spiritual | 8 | Anxiety, distance from God, guilt, boredom, anger, doubt |
| Circumstantial | 6 | Traffic, weather, news, waiting, chores, tech problems |
| **Total** | **43** | |

## Appendix C: Risk Level Colors (for Distribution Charts)

| Quadrant | Color | Hex |
|---|---|---|
| Focus Here | Blue | #007AFF |
| Let Go | Purple | #AF52DE |
| Minimize | Orange | #FF9500 |
| Ignore | Gray | #8E8E93 |
