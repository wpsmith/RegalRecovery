# CBT Thought Records -- Feature PRD

| Field | Value |
|---|---|
| **PRD Title** | CBT Thought Records |
| **Author** | Travis Smith |
| **Date** | 2026-04-23 |
| **Version** | 1.0 |
| **Designation** | Feature (within Recovery Activities Epic) |
| **OMTM** | Average emotion intensity reduction per thought record (before vs. after balanced thought), targeting >= 20% reduction at 4 weeks |
| **Target Delivery** | 4 sprints (40 business days maximum) |
| **MoSCoW Summary** | 16 Must, 9 Should, 7 Could, 5 Won't |

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Product Overview](#2-product-overview)
3. [MoSCoW Prioritized Requirements](#3-moscow-prioritized-requirements)
4. [Functional Requirements](#4-functional-requirements)
5. [Non-Functional Requirements](#5-non-functional-requirements)
6. [Technical Considerations](#6-technical-considerations)
7. [User Stories](#7-user-stories)
8. [Feature Comparison Matrix](#8-feature-comparison-matrix)
9. [Implementation Roadmap](#9-implementation-roadmap)
10. [Open Questions and Risks](#10-open-questions-and-risks)
11. [Design Decisions Log](#11-design-decisions-log)

---

## 1. Executive Summary

### Problem Statement

Users in sex addiction recovery experience automatic cognitive distortions -- permission-giving thoughts, minimization, entitlement, rationalization -- that serve as the cognitive bridge between triggers and acting-out behavior. These distorted thoughts operate below conscious awareness, feeling like truth rather than interpretation. Current app tools address the behavioral dimension (urge logging), the emotional dimension (FASTER Scale, mood tracking), and the lifestyle dimension (LBI/PCI), but no tool directly targets the cognitive dimension: the specific thoughts that make acting out feel justified, inevitable, or harmless.

**User goal:** Interrupt distorted thinking in real time by making automatic thoughts visible, examining them against evidence, and replacing them with truth-based balanced perspectives.

**Hurdles:**
- Automatic thoughts are rapid and habitual -- users do not notice them without structured practice
- Generating balanced alternative thoughts is the hardest step -- users know what they are thinking but struggle to articulate a truthful alternative
- Traditional paper thought records are cumbersome, easily abandoned, and provide no pattern analysis
- Without tracking, users cannot see their most frequent cognitive distortions or measure improvement over time
- The full 7-column thought record is overwhelming for beginners, leading to abandonment before the skill develops

**Quantifiable impact:** CBT meta-analyses demonstrate modest but positive effect sizes for addiction treatment. Thought records are the primary cognitive restructuring tool in CBT. In clinical practice, consistent thought record use develops the metacognitive skill to notice and challenge distorted thoughts before they drive behavior. The cost of unchallenged distorted thinking is the permission-giving thought chain that precedes every relapse event.

### Business Hypothesis

By providing a progressive guided thought record implementation with step-by-step wizard entry, a curated cognitive distortion library with sex addiction-specific examples, scripture-based balanced thought suggestions, and longitudinal pattern analytics, we hypothesize that:

- **Primary outcome:** Users who complete 10+ thought records will show a >= 20% average reduction in emotion intensity ratings (before vs. after balanced thought)
- **Secondary outcome:** Users who actively use thought records during urge events will show a 15-25% reduction in acting-out episodes compared to their pre-feature baseline over 12 weeks
- **OMTM impact:** Target 2-3% improvement in overall app retention (the Recovery Activities contribution to the app-wide OMTM)

### Solution Overview

A three-phase CBT Thought Records implementation within the Regal Recovery iOS app:
1. **Progressive Guided Wizard** -- Step-by-step thought record entry starting with 3 columns (Situation, Thought, Emotion), graduating to 5 and then 7 columns as the user builds skill
2. **Cognitive Distortion Library** -- 14 curated distortions with definitions, sex addiction-specific examples, counter-questions, and related scripture
3. **Pattern Analytics** -- Track most frequent distortions, emotion intensity trends, trigger patterns, and improvement over time

### Resource Requirements

- 1 iOS developer (4 sprints)
- Design review at Sprint 1 boundary
- QA integrated throughout
- No backend API changes required for MVP (SwiftData local-first)

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Users abandon wizard before completion | Medium | High | Progressive column introduction; 3-column mode completes in under 3 minutes |
| Balanced thought quality is poor without guidance | High | Medium | Guided prompts, scripture suggestions, Premium+ AI assist |
| Feature overlap with journaling | Medium | Low | Thought records are structured and analytical; journaling is free-form and exploratory. Clear differentiation in onboarding. |
| Users avoid feature during active distress | Medium | High | Integration with urge log and emergency layer creates natural entry points when distorted thinking is active |
| Privacy concern about recording thoughts | Low | Medium | Compassionate framing, local-first storage, granular sharing controls |

---

## 2. Product Overview

### Product Vision

CBT Thought Records bring the most evidence-based cognitive restructuring technique in clinical psychology into the Regal Recovery toolkit. Where the FASTER Scale tells you how far you have progressed toward relapse, and the LBI tells you whether your lifestyle conditions are deteriorating, thought records address the cognitive engine that drives both: the specific thoughts that transform triggers into permission. By making these invisible thoughts visible and systematically challenging them against evidence and truth, users develop the metacognitive skill that Paul describes in 2 Corinthians 10:5: "We take captive every thought to make it obedient to Christ."

### Target Users

**Primary Persona: Alex (Active Recovery)**
- 6-18 months into SA/Celebrate Recovery program
- Has a sponsor and a therapist/CSAT
- Experiences recurring cognitive distortions (entitlement, minimization) that they can identify after the fact but struggle to catch in the moment
- Needs: a structured tool to practice catching and challenging distorted thoughts in real time, building the skill through repetition

**Secondary Persona: Jordan (Early Recovery)**
- 0-6 months in recovery
- Has not yet learned the vocabulary of cognitive distortions
- Distorted thoughts feel like truth; low metacognitive awareness
- Needs: guided introduction to the concept, starting with the simplest version, learning one distortion at a time

**Tertiary Persona: Sam (Sponsor/Counselor)**
- Reviews shared data from accountability partners or clients
- Needs: visibility into distortion patterns (which distortions are most frequent, whether they are decreasing) without access to raw thought content

### Value Proposition

"See the lies your addiction tells you. Thought Records help you catch the automatic thoughts that give you permission to act out -- and replace them with truth."

### OMTM and Success Criteria

**One Metric That Matters:** Average emotion intensity reduction per thought record (column 3 "before" rating minus column 7 "after" rating), targeting >= 20% reduction at 4 weeks of use.

| Success Criterion | Target | Measurement Method |
|---|---|---|
| First thought record completion | >= 70% of users who open the feature complete at least one 3-column record | Completion funnel analytics |
| Progressive level adoption | >= 40% of users advance to 5-column within 4 weeks | Level transition tracking |
| Emotion intensity reduction | >= 20% average reduction (before vs. after) | Column 3 vs. column 7 ratings |
| Urge-linked completion rate | >= 30% of urge log entries result in a linked thought record | Cross-feature link tracking |
| Feature retention at week 8 | >= 35% of first-week completers still using at week 8 | 8-week retention cohort |
| Average completion time (3-column) | <= 3 minutes | Time from wizard open to save |
| Average completion time (7-column) | <= 8 minutes | Time from wizard open to save |

### Scope Constraints

- **Feature scope:** Maximum 4 sprints (40 business days)
- **Platform:** iOS only (SwiftUI + SwiftData)
- **Tier:** Standard tier (guided entry with prompts) ships in Sprints 1-3; Premium+ tier (AI-assisted balanced thoughts) ships in Sprint 4
- **Backend:** Local-first with SwiftData; API sync deferred to future feature
- **No therapist portal integration** in this scope

### Assumptions

1. Users have completed onboarding and have an active RRUser record in SwiftData
2. Users can benefit from cognitive restructuring regardless of whether they have formal CBT training
3. The guided wizard approach will compensate for lack of therapist guidance
4. The progressive column model will prevent overwhelm while building genuine skill
5. The existing evening/daily activity notification infrastructure can include thought record reminders

---

## 3. MoSCoW Prioritized Requirements

### Must Have (Non-negotiable for launch)

| ID | Requirement | Rationale |
|---|---|---|
| M1 | 3-column thought record entry (Situation, Automatic Thought, Emotion with intensity 0-100%) | Entry-level format that builds foundational skill |
| M2 | 5-column thought record entry (+ Cognitive Distortion, Balanced Thought) | Intermediate format that introduces challenging and reframing |
| M3 | 7-column thought record entry (+ Evidence For, Evidence Against) | Full format with complete evidence examination |
| M4 | Progressive level system: 3-column default, unlock 5-column after 5 records, unlock 7-column after 10 | Prevents overwhelm, builds skill progressively |
| M5 | Step-by-step guided wizard flow (one column per screen) | Reduces cognitive load, guides learning |
| M6 | Cognitive distortion library with 14 distortions, definitions, and examples | Core educational component |
| M7 | Distortion picker in 5-column and 7-column modes | Structured identification rather than free-form |
| M8 | Emotion picker with intensity slider (0-100%) | Quantifies emotional state for tracking |
| M9 | Emotion re-rating in 7-column mode (Outcome column) | Measures effectiveness of cognitive restructuring |
| M10 | SwiftData persistence for all thought record data | Offline-first architecture requirement |
| M11 | Thought record history list with date, situation summary, distortion tag, and emotion change | Users must be able to review past records |
| M12 | Feature accessible from Recovery Work tab and Today view | Must be discoverable in primary navigation |
| M13 | Users can manually switch between 3/5/7-column modes at any time | Expert users should not be locked into beginner mode |
| M14 | Individual thought records can be deleted | User data control; compassionate design |
| M15 | Psychoeducation screen explaining what thought records are and why they matter | First-use onboarding to establish motivation |
| M16 | Guided prompts on each wizard step with contextual help text | Users need guidance on what to write at each step |

### Should Have (Important but solution is viable without)

| ID | Requirement | Rationale |
|---|---|---|
| S1 | Pattern analytics: most frequent distortions (bar chart) | Core pattern recognition benefit |
| S2 | Pattern analytics: emotion intensity before vs. after trend (line chart) | Measures skill development over time |
| S3 | Scripture suggestions for balanced thoughts based on selected distortion | Christian integration |
| S4 | Integration with urge log: prompt to create thought record after logging an urge | Natural entry point during cognitive distress |
| S5 | Integration with FASTER Scale: suggest thought record when FASTER check-in reaches A/S/T | Bridges behavioral and cognitive awareness |
| S6 | Accountability sharing: distortion frequency and emotion trends (not raw text) | Accountability without privacy violation |
| S7 | Evening notification suggesting thought record if user logged urges but no records today | Habit formation nudge |
| S8 | "Quick Entry" mode (all columns on one scrollable screen) for experienced users | Reduces taps for skilled users |
| S9 | Balanced thought bookmarking: save effective balanced thoughts for re-use | Builds a personal truth library |

### Could Have (Nice-to-haves)

| ID | Requirement | Rationale |
|---|---|---|
| C1 | Premium+ AI-assisted balanced thought generation | Addresses the hardest step for users |
| C2 | Premium+ AI cognitive distortion detection from automatic thought text | Reduces identification burden |
| C3 | Link thought records to post-mortem analysis timeline | Enriches post-mortem with real-time cognitive data |
| C4 | Export thought records as PDF for therapist sharing | Bridges digital and clinical workflows |
| C5 | "Thought of the Day" review: surface a random past balanced thought as a morning reminder | Reinforcement of learned truths |
| C6 | Achievement badges for thought record milestones (5, 10, 25, 50, 100) | Gamification for adherence |
| C7 | Dark mode optimized wizard animations | Polish |

### Won't Have (Explicitly excluded)

| ID | Requirement | Rationale |
|---|---|---|
| W1 | Backend API sync for thought record data | Deferred to sync epic; local-first sufficient for MVP |
| W2 | Therapist portal view of client thought records | Requires backend infrastructure not in scope |
| W3 | Voice-to-text entry for thought records | Complex speech recognition scope; defer |
| W4 | Real-time collaborative thought records (therapist guides entry live) | Requires real-time infrastructure |
| W5 | Automatic cognitive distortion detection without AI (rules-based NLP) | Insufficient accuracy without ML; either use AI or manual selection |

---

## 4. Functional Requirements

### 4.1 Psychoeducation and Onboarding

| ID | Requirement | Priority | Tier | Conditions of Satisfaction |
|---|---|---|---|---|
| FR-01 | System displays psychoeducation screen explaining thought records on first access | Must | Standard | Given the user navigates to Thought Records for the first time, When the feature loads, Then an educational screen explains: what automatic thoughts are, how distortions work, what a thought record does, and the progressive level system |
| FR-02 | Psychoeducation includes the 2 Corinthians 10:5 and Romans 12:2 connection | Must | Standard | Given the educational screen is displayed, When the user reads the content, Then the biblical parallel ("taking every thought captive", "renewing of the mind") is presented alongside the CBT explanation |
| FR-03 | User can dismiss psychoeducation and proceed to first entry | Must | Standard | Given the educational screen is displayed, When the user taps "Start My First Record", Then the wizard opens in 3-column mode |

### 4.2 Thought Record Entry (Guided Wizard)

| ID | Requirement | Priority | Tier | Conditions of Satisfaction |
|---|---|---|---|---|
| FR-04 | Wizard presents one column per screen in sequential order | Must | Standard | Given the user starts a new thought record in 5-column mode, When the wizard opens, Then screen 1 = Situation, screen 2 = Automatic Thought, screen 3 = Emotion, screen 4 = Cognitive Distortion, screen 5 = Balanced Thought, with navigation between screens |
| FR-05 | Situation screen: free-text input with guiding prompt | Must | Standard | Given the Situation screen is displayed, When the user sees the prompt "What happened? Where were you? Who were you with?", Then a text field accepts up to 500 characters |
| FR-06 | Automatic Thought screen: free-text input with multiple thought support | Must | Standard | Given the Automatic Thought screen is displayed, When the user enters text, Then they can enter 1-5 automatic thoughts as separate entries, each up to 300 characters |
| FR-07 | Emotion screen: multi-select emotion picker with intensity sliders | Must | Standard | Given the Emotion screen is displayed, When the user selects emotions, Then they can select 1-5 emotions from a curated list and rate each on a 0-100% intensity slider |
| FR-08 | Emotion list includes at least: anxious, angry, ashamed, sad, lonely, bored, hopeless, worthless, disgusted, excited, guilty, jealous, frustrated, afraid, overwhelmed | Must | Standard | Given the emotion picker is displayed, When the user views the list, Then all 15 core emotions are available plus a "Custom" option for free-text entry |
| FR-09 | Cognitive Distortion screen (5-column and 7-column only): distortion picker from library | Must | Standard | Given the user is in 5-column or 7-column mode at the distortion step, When the screen displays, Then the user selects 1-3 distortions from the curated library, each showing name, brief definition, and an example |
| FR-10 | Evidence For screen (7-column only): free-text input for supporting evidence | Must | Standard | Given the user is in 7-column mode at the Evidence For step, When the screen displays, Then a text field accepts up to 500 characters with the prompt "What facts support this thought? (Observable evidence, not feelings)" |
| FR-11 | Evidence Against screen (7-column only): free-text input with guided prompts | Must | Standard | Given the user is in 7-column mode at the Evidence Against step, When the screen displays, Then a text field accepts up to 500 characters with prompts including "What would you tell a friend in this situation?", "Has there been a time when this thought wasn't true?", "What does the evidence actually show?" |
| FR-12 | Balanced Thought screen: free-text input with assistance options | Must | Standard | Given the Balanced Thought screen is displayed, When the user sees the input, Then guided prompts are shown ("Based on all the evidence, what is a more realistic perspective?") and a "Scripture Suggestion" button is available |
| FR-13 | Outcome screen (7-column only): emotion re-rating with same emotions as step 3 | Must | Standard | Given the user is in 7-column mode at the Outcome step, When the screen displays, Then the emotions selected in step 3 are shown with their original intensity, and the user re-rates each on the same 0-100% slider |
| FR-14 | User can navigate back and forth between wizard steps without losing data | Must | Standard | Given the user is on step 4 of 5, When they tap back to step 2 and edit, Then step 3 and 4 data are preserved |
| FR-15 | Wizard shows progress indicator (step N of M) | Must | Standard | Given the user is in 5-column mode on step 3, When they view the progress bar, Then it shows "3 of 5" or a proportional progress bar |

### 4.3 Cognitive Distortion Library

| ID | Requirement | Priority | Tier | Conditions of Satisfaction |
|---|---|---|---|---|
| FR-16 | Distortion library contains 14 standard cognitive distortions with: name, definition, general example, sex addiction-specific example, counter-questions, and related scripture | Must | Standard | Given the user opens the distortion library, When the list renders, Then all 14 distortions are shown with complete content |
| FR-17 | Distortion picker allows selecting 1-3 distortions per thought record | Must | Standard | Given the distortion picker is displayed, When the user selects distortions, Then a counter shows "X of 3 selected" and selection is capped at 3 |
| FR-18 | Each distortion entry includes a "Learn More" expandable section with counter-questions and scripture | Should | Standard | Given the user taps "Learn More" on a distortion, When the section expands, Then counter-questions and a related scripture passage are shown |
| FR-19 | Distortion library is accessible standalone (outside of a thought record entry) for educational browsing | Should | Standard | Given the user navigates to the distortion library from settings or the learning section, When the list renders, Then all 14 distortions with full content are browsable |

### 4.4 Scripture Suggestions

| ID | Requirement | Priority | Tier | Conditions of Satisfaction |
|---|---|---|---|---|
| FR-20 | After selecting a cognitive distortion, relevant scripture passages are suggested for the balanced thought | Should | Standard | Given the user selected "Catastrophizing" as a distortion, When they reach the Balanced Thought step, Then scripture suggestions like "With God all things are possible (Matthew 19:26)" and "I can do all things through Christ (Philippians 4:13)" appear as tappable chips |
| FR-21 | Tapping a scripture chip inserts a formatted reference into the balanced thought text field | Should | Standard | Given the user taps a scripture chip, When it is selected, Then the text is appended to the balanced thought field in the format: "[Scripture text] -- [Reference]" |
| FR-22 | Scripture suggestions are curated and mapped to specific distortions (not AI-generated in Standard tier) | Should | Standard | Given the scripture mapping, When suggestions appear, Then they are from a pre-curated library of 2-4 passages per distortion |

### 4.5 Progressive Level System

| ID | Requirement | Priority | Tier | Conditions of Satisfaction |
|---|---|---|---|---|
| FR-23 | New users default to 3-column mode | Must | Standard | Given a user who has never created a thought record, When they open the wizard, Then it is in 3-column mode (Situation, Automatic Thought, Emotion) |
| FR-24 | After completing 5 thought records, 5-column mode unlocks with a celebration notification | Must | Standard | Given the user saves their 5th thought record, When the save completes, Then a notification/banner appears: "Congratulations! You've unlocked the intermediate Thought Record with Distortion Identification and Balanced Thoughts." |
| FR-25 | After completing 10 thought records (cumulative, any mode), 7-column mode unlocks | Must | Standard | Given the user saves their 10th thought record, When the save completes, Then 7-column mode is unlocked with a celebration |
| FR-26 | User can manually switch between unlocked modes at any time | Must | Standard | Given the user has unlocked 5-column mode, When they start a new record, Then a mode selector allows choosing 3-column or 5-column |
| FR-27 | Previously locked modes show as coming soon with the unlock requirement | Should | Standard | Given the user has only completed 2 records, When they view the mode selector, Then 5-column shows "Complete 3 more records to unlock" and 7-column shows "Complete 8 more records to unlock" |

### 4.6 History and Pattern Analytics

| ID | Requirement | Priority | Tier | Conditions of Satisfaction |
|---|---|---|---|---|
| FR-28 | Thought record history shows all records sorted by date (newest first) | Must | Standard | Given the user navigates to history, When the list renders, Then records are shown with date, situation excerpt (first 50 chars), distortion tag(s) (if 5+ column), and emotion change indicator |
| FR-29 | Tapping a history entry opens the full thought record in read-only view | Must | Standard | Given the user taps a record, When it opens, Then all completed columns are displayed in a readable format |
| FR-30 | Pattern analytics: most frequent distortions bar chart | Should | Standard | Given the user has 10+ records with distortions identified, When the analytics screen renders, Then a bar chart shows distortion frequency ranked from most to least common |
| FR-31 | Pattern analytics: emotion intensity before vs. after trend line | Should | Standard | Given the user has 5+ 7-column records, When the analytics screen renders, Then a line chart shows average pre-balanced and post-balanced emotion intensity over time |
| FR-32 | Pattern analytics: trigger situation categories | Should | Standard | Given the user has categorized situations, When the analytics screen renders, Then a summary shows which situation types (work, relationships, solitude, digital, spiritual, etc.) are most associated with distorted thinking |

### 4.7 Feature Integrations

| ID | Requirement | Priority | Tier | Conditions of Satisfaction |
|---|---|---|---|---|
| FR-33 | After saving an urge log entry, prompt user to create a linked thought record | Should | Standard | Given the user saves an urge log, When the save confirmation appears, Then a prompt asks "Want to examine the thoughts behind this urge?" with a button to open a thought record pre-linked to the urge |
| FR-34 | FASTER Scale check-in at A/S/T stage suggests a thought record | Should | Standard | Given the user completes a FASTER check-in at Anxiety, Speeding Up, or Ticking stage, When the result is shown, Then a suggestion appears: "A Thought Record can help you examine what's driving this escalation" |
| FR-35 | Thought records appear in the Today view activity log when completed | Must | Standard | Given the user completes a thought record, When the Today view refreshes, Then a card shows "Thought Record: [distortion] -- [emotion change]" |
| FR-36 | Completed thought records can be linked to post-mortem analysis entries | Could | Standard | Given the user is completing a post-mortem, When they reach the "Throughout the Day" section, Then any thought records from that day appear as linkable entries on the timeline |

### 4.8 Balanced Thought Bookmarking

| ID | Requirement | Priority | Tier | Conditions of Satisfaction |
|---|---|---|---|---|
| FR-37 | User can bookmark/star a balanced thought for later re-use | Should | Standard | Given the user is viewing a completed thought record, When they tap the bookmark icon on the balanced thought, Then it is saved to a "Truth Library" |
| FR-38 | The Truth Library shows all bookmarked balanced thoughts searchable by distortion | Should | Standard | Given the user opens the Truth Library, When the list renders, Then bookmarked balanced thoughts are shown grouped by the distortion they counter |

### 4.9 Privacy Controls

| ID | Requirement | Priority | Tier | Conditions of Satisfaction |
|---|---|---|---|---|
| FR-39 | All thought record text is stored locally in SwiftData only; never transmitted without explicit user action | Must | Standard | Enforced by architecture (no API sync in scope) |
| FR-40 | Accountability sharing shares only: number of records completed, distortion frequencies, and emotion intensity trends -- never situation text, thought text, or balanced thought text | Must | Standard | Enforced by sharing data model |
| FR-41 | User can mark individual thought records as "Private" (excluded from all sharing, including summary analytics shared with accountability partners) | Should | Standard | Given the user marks a record as private, When their partner views shared data, Then that record's data is excluded from all analytics |

---

## 5. Non-Functional Requirements

### 5.1 Performance

| ID | Requirement | Target |
|---|---|---|
| NFR-01 | Wizard step transition time | < 300ms animation |
| NFR-02 | Thought record save time | < 200ms |
| NFR-03 | History list load time (100+ records) | < 500ms |
| NFR-04 | Pattern analytics chart render time | < 1 second |
| NFR-05 | Distortion library load time | < 200ms |
| NFR-06 | Storage per year (100 records) | < 2MB per user |

### 5.2 Security and Privacy

| ID | Requirement | Target |
|---|---|---|
| NFR-07 | All thought record text stored locally in SwiftData only | Enforced by architecture |
| NFR-08 | Accountability sharing shares aggregates only, never raw text | Enforced by sharing data model |
| NFR-09 | Biometric lock protects thought records alongside all other app data | Inherited from app-level biometric gate |
| NFR-10 | Thought record data included in full data export (DSR compliance) | Included in existing data export pipeline |
| NFR-11 | Deleted thought records are permanently removed from device | No soft-delete for privacy-sensitive content |

### 5.3 Usability

| ID | Requirement | Target |
|---|---|---|
| NFR-12 | 3-column thought record completes in under 3 minutes | Measured by median completion time |
| NFR-13 | 7-column thought record completes in under 8 minutes | Measured by median completion time |
| NFR-14 | All text meets WCAG 2.1 AA contrast ratios | Automated accessibility audit |
| NFR-15 | VoiceOver fully supports wizard flow, distortion picker, and emotion slider | Manual accessibility testing |
| NFR-16 | Dynamic Type support for all thought record screens | Tested at all system text sizes |

### 5.4 Reliability

| ID | Requirement | Target |
|---|---|---|
| NFR-17 | No data loss if app is terminated during wizard (draft auto-saved between steps) | Tested via force-quit during entry |
| NFR-18 | Wizard state preserved if user backgrounds the app and returns | Tested via background/foreground cycle |
| NFR-19 | Progressive level unlock state persists across app reinstall (SwiftData migration) | Tested via delete and reinstall flow |

### 5.5 Compatibility

| ID | Requirement | Target |
|---|---|---|
| NFR-20 | iOS 17.0+ (matching app minimum deployment target) | Build and runtime tested |
| NFR-21 | iPhone SE (3rd gen) through iPhone 16 Pro Max screen sizes | Adaptive layout tested |
| NFR-22 | iPad compatibility (if app supports iPad) | Layout scales appropriately |

---

## 6. Technical Considerations

### 6.1 Architecture Overview

The CBT Thought Records feature follows the existing MVVM + SwiftData architecture. Key patterns:

```
Views (SwiftUI Wizard + History + Analytics)
  |
  v
ViewModels (@Observable)
  |
  v
Models (@Model + Codable support types)
```

### 6.2 Data Model (SwiftData)

```swift
// MARK: - Thought Record

@Model
final class RRThoughtRecord {
    var id: UUID
    var userId: UUID
    var date: Date
    var mode: Int                    // 3, 5, or 7 (column count)

    // Column 1: Situation
    var situationText: String

    // Column 2: Automatic Thought(s)
    var thoughtsJSON: String         // JSON-encoded [ThoughtEntry]

    // Column 3: Emotions (before balanced thought)
    var emotionsJSON: String         // JSON-encoded [EmotionRating]

    // Column 4: Cognitive Distortion(s) -- 5/7-column only
    var distortionsJSON: String?     // JSON-encoded [String] (distortion IDs)

    // Column 5/6: Evidence For/Against -- 7-column only
    var evidenceForText: String?
    var evidenceAgainstText: String?

    // Column 6/5: Balanced Thought
    var balancedThoughtText: String?

    // Column 7: Outcome emotions -- 7-column only
    var outcomeEmotionsJSON: String? // JSON-encoded [EmotionRating]

    // Metadata
    var isBookmarked: Bool           // Balanced thought bookmarked
    var isPrivate: Bool              // Excluded from sharing analytics
    var linkedUrgeLogId: UUID?       // Optional link to urge log entry
    var linkedFasterEntryId: UUID?   // Optional link to FASTER entry
    var createdAt: Date
    var modifiedAt: Date
    var needsSync: Bool

    init(userId: UUID, mode: Int) {
        self.id = UUID()
        self.userId = userId
        self.date = Date()
        self.mode = mode
        self.situationText = ""
        self.thoughtsJSON = "[]"
        self.emotionsJSON = "[]"
        self.isBookmarked = false
        self.isPrivate = false
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.needsSync = true
    }
}

// MARK: - User's CBT Progress

@Model
final class RRCBTProgress {
    var id: UUID
    var userId: UUID
    var totalRecordsCompleted: Int
    var unlockedLevel: Int           // 3, 5, or 7
    var preferredLevel: Int          // User's selected default level
    var hasSeenPsychoeducation: Bool
    var createdAt: Date
    var modifiedAt: Date

    init(userId: UUID) {
        self.id = UUID()
        self.userId = userId
        self.totalRecordsCompleted = 0
        self.unlockedLevel = 3
        self.preferredLevel = 3
        self.hasSeenPsychoeducation = false
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

// MARK: - Supporting Codable Types

struct ThoughtEntry: Codable, Identifiable {
    var id: UUID
    var text: String                 // Max 300 chars
    var isHotThought: Bool           // The most distressing thought (for focus in later columns)
}

struct EmotionRating: Codable, Identifiable {
    var id: UUID
    var emotionType: String          // Enum raw value or custom text
    var intensity: Int               // 0-100
}

enum CognitiveDistortionType: String, Codable, CaseIterable, Identifiable {
    case allOrNothing = "all_or_nothing"
    case overgeneralization = "overgeneralization"
    case mentalFilter = "mental_filter"
    case disqualifyingPositive = "disqualifying_positive"
    case mindReading = "mind_reading"
    case fortuneTelling = "fortune_telling"
    case catastrophizing = "catastrophizing"
    case magnificationMinimization = "magnification_minimization"
    case emotionalReasoning = "emotional_reasoning"
    case shouldStatements = "should_statements"
    case labeling = "labeling"
    case personalization = "personalization"
    case blaming = "blaming"
    case entitlement = "entitlement"

    var id: String { rawValue }
    var displayName: String { /* localized names */ }
    var definition: String { /* brief definition */ }
    var generalExample: String { /* general example */ }
    var addictionExample: String { /* sex addiction specific example */ }
    var counterQuestions: [String] { /* Socratic questions to challenge this distortion */ }
    var relatedScripture: [(verse: String, reference: String)] { /* 2-4 relevant passages */ }
    var icon: String { /* SF Symbol name */ }
}

enum EmotionType: String, Codable, CaseIterable {
    case anxious, angry, ashamed, sad, lonely, bored, hopeless
    case worthless, disgusted, excited, guilty, jealous
    case frustrated, afraid, overwhelmed

    var displayName: String { /* localized names */ }
    var color: Color { /* emotion-specific colors */ }
    var icon: String { /* SF Symbol */ }
}
```

### 6.3 Key Technical Decisions

1. **JSON-encoded arrays in SwiftData**: Follows the existing pattern (LBI, FASTER, Urge Log). Emotions, thoughts, and distortions are stored as JSON strings.

2. **Mode as integer (3, 5, 7)**: Simple numeric representation of which columns are active. The wizard uses this to determine which screens to show.

3. **Draft auto-save**: The wizard saves the current state to the SwiftData model after each step transition. If the user force-quits, the partial record is preserved and can be resumed or deleted.

4. **Separate progress model**: `RRCBTProgress` tracks the user's level progression independently from individual records. This allows the level system to survive even if individual records are deleted.

5. **Linked entries**: Optional UUID references to urge log and FASTER entries enable cross-feature correlation without tight coupling.

### 6.4 Integration Points

| Integration | Mechanism | Scope |
|---|---|---|
| Today view activity feed | `RRThoughtRecord` rendered as a card | Must (FR-35) |
| Urge Log | Optional `linkedUrgeLogId` reference; prompt after urge save | Should (FR-33) |
| FASTER Scale | Optional `linkedFasterEntryId`; suggestion at A/S/T stages | Should (FR-34) |
| Post-Mortem | Query thought records by date range for timeline inclusion | Could (FR-36) |
| Accountability sharing | Summary analytics (distortion frequency, emotion trends) only | Should (FR-40) |
| Notifications | Leverage existing `PlanNotificationScheduler` | Should (S7) |
| Feature flags | `activity.cbt-thoughts` flag gates feature visibility | Must (architectural) |

### 6.5 Infrastructure

No additional infrastructure required. All data is local (SwiftData). The feature flag is evaluated from the existing `RRFeatureFlag` model. Push notifications use the existing local notification scheduling system. AI-assisted features (Premium+ tier, Sprint 4) will use the existing LiteLLM integration via the `RecoveryAgentService`.

---

## 7. User Stories

### Epic: CBT Thought Records

---

### Story 1: Psychoeducation Screen

**As a** recovering person opening Thought Records for the first time,
**I want** to understand what thought records are, why they matter for my recovery, and how the biblical mandate to "take every thought captive" connects to this practice,
**So that** I am motivated to invest the effort in learning this skill.

**Priority:** Must (M15)
**Story Points:** 3

**Conditions of Satisfaction:**

- Given I have never opened the Thought Records feature, When I navigate to it, Then a psychoeducation screen displays with: a title, an explanation of automatic thoughts and cognitive distortions, the 2 Corinthians 10:5 connection, and the progressive level system description
- Given the psychoeducation screen is displayed, When I tap "Start My First Record", Then the 3-column wizard opens
- Given I have completed at least one thought record, When I navigate to the feature, Then the psychoeducation screen is not shown; I go directly to the entry/history view

---

### Story 2: 3-Column Thought Record Entry (Beginner)

**As a** recovering person learning to identify my automatic thoughts,
**I want** to record what happened, what I thought, and how I felt in a simple guided format,
**So that** I begin building the foundational skill of noticing my thoughts.

**Priority:** Must (M1, M5, M16)
**Story Points:** 8

**Conditions of Satisfaction:**

- Given I am in the 3-column wizard, When step 1 (Situation) displays, Then I see the prompt "What happened? Where were you? Who were you with?" with a text field (500 char limit)
- Given I am on step 2 (Automatic Thought), When the screen displays, Then I see "What went through your mind?" with 1-5 thought entry fields (300 char limit each) and a "+" button to add more
- Given I enter multiple thoughts, When I mark one as the "hot thought" (most distressing), Then it is highlighted and will be the focus of later columns when I advance to 5/7-column mode
- Given I am on step 3 (Emotions), When the screen displays, Then I see a grid of emotion options (15 core + custom), each tappable, with a 0-100% intensity slider appearing after selection
- Given I have completed all 3 steps, When I tap "Save", Then the record is persisted to SwiftData and a completion card shows "Great work -- you just took a thought captive!"
- Given I am in the wizard, When I navigate between steps, Then my data on each step is preserved

---

### Story 3: 5-Column Thought Record Entry (Intermediate)

**As a** recovering person who has built basic thought awareness,
**I want** to identify the cognitive distortion in my thinking and generate a balanced alternative,
**So that** I actively challenge my distorted thoughts rather than just noticing them.

**Priority:** Must (M2, M6, M7)
**Story Points:** 8

**Conditions of Satisfaction:**

- Given I am in 5-column mode, When the wizard opens, Then 5 steps are shown: Situation, Automatic Thought, Emotion, Cognitive Distortion, Balanced Thought
- Given I am on step 4 (Cognitive Distortion), When the picker displays, Then I see 14 distortions each with name, brief definition, and a sex addiction example, and I can select 1-3
- Given I select "Entitlement", When the selection is confirmed, Then it is tagged to this record and will inform the Balanced Thought suggestions
- Given I am on step 5 (Balanced Thought), When the screen displays, Then I see guided prompts ("What is a more realistic way to see this?", "What would you tell a friend?") and a "Scripture Suggestion" button
- Given I tap "Scripture Suggestion" and I selected "Catastrophizing", When the suggestions display, Then relevant scripture chips appear (e.g., "With God all things are possible -- Matthew 19:26")
- Given I tap a scripture chip, When it is selected, Then the verse text and reference are appended to my balanced thought field

---

### Story 4: 7-Column Thought Record Entry (Advanced)

**As a** recovering person with developed thought record skills,
**I want** to systematically examine the evidence for and against my automatic thought before generating a balanced perspective and measuring the emotional outcome,
**So that** I engage in thorough cognitive restructuring that changes how I feel.

**Priority:** Must (M3, M9)
**Story Points:** 5

**Conditions of Satisfaction:**

- Given I am in 7-column mode, When the wizard opens, Then 7 steps are shown: Situation, Automatic Thought, Emotion, Evidence For, Evidence Against, Balanced Thought, Outcome
- Given I am on step 4 (Evidence For), When the screen displays, Then the prompt reads "What facts support this thought? List observable evidence, not feelings." with a 500-char text field
- Given I am on step 5 (Evidence Against), When the screen displays, Then guided prompts are shown alongside the text field: "What would you tell a friend?", "Has there been a time this thought wasn't true?", "What does God say about this?"
- Given I am on step 7 (Outcome), When the screen displays, Then my original emotions from step 3 are listed with their original intensity ratings, and I can re-rate each on the same 0-100% slider
- Given I re-rate "Ashamed" from 80% to 45%, When I save the record, Then the emotion change (35% reduction) is stored and visible in history

---

### Story 5: Progressive Level System

**As a** recovering person using thought records,
**I want** advanced modes to unlock as I build skill, with the option to switch between modes,
**So that** I am not overwhelmed early but can access full cognitive restructuring as I grow.

**Priority:** Must (M4, M13)
**Story Points:** 3

**Conditions of Satisfaction:**

- Given I am a new user, When I start my first thought record, Then only 3-column mode is available
- Given I have completed 5 records (any mode), When I complete the 5th, Then a celebration banner announces 5-column mode is unlocked
- Given I have completed 10 records (cumulative), When I complete the 10th, Then 7-column mode is unlocked with a celebration
- Given 5-column mode is unlocked, When I start a new record, Then I can choose between 3-column and 5-column
- Given I have unlocked 7-column mode, When I start a new record, Then I can choose between 3, 5, and 7-column mode
- Given I am viewing the mode selector, When a mode is still locked, Then it shows the unlock requirement and how many more records are needed

---

### Story 6: Cognitive Distortion Library

**As a** recovering person learning about cognitive distortions,
**I want** to browse a library of distortions with definitions, examples relevant to my addiction, counter-questions, and related scripture,
**So that** I develop the vocabulary to name my distorted thinking patterns.

**Priority:** Must (M6)
**Story Points:** 5

**Conditions of Satisfaction:**

- Given I navigate to the distortion library, When the list renders, Then 14 distortions are listed with name, icon, and one-line definition
- Given I tap "Entitlement", When the detail view opens, Then I see: full definition, general example, sex addiction example ("I work hard, I deserve this pleasure"), 3 counter-questions, and 2-3 related scripture passages
- Given I am in a thought record wizard at the distortion step, When I tap a distortion for more info, Then the full detail view opens inline without losing my wizard progress
- Given I am browsing the library outside a wizard, When I view any distortion, Then all content is identical to what appears during wizard entry

---

### Story 7: Thought Record History

**As a** recovering person who has completed multiple thought records,
**I want** to review past records to see my patterns and progress,
**So that** I can identify recurring distortions and celebrate my growth.

**Priority:** Must (M11)
**Story Points:** 5

**Conditions of Satisfaction:**

- Given I have 15 thought records, When I navigate to history, Then records are listed newest first, each showing: date, situation excerpt (first 50 chars), distortion tags (if 5+ column), and emotion change indicator (if 7-column)
- Given I tap a record from February 14, When it opens, Then all completed columns are displayed in a readable, non-editable format
- Given I view a 7-column record, When the emotion change is displayed, Then both original and outcome intensities are shown for each emotion
- Given I want to delete a record, When I swipe to delete and confirm, Then the record is permanently removed and the deletion is reflected in analytics

---

### Story 8: Pattern Analytics Dashboard

**As a** recovering person who has been using thought records for several weeks,
**I want** to see which distortions I use most, whether my emotional reactivity is decreasing, and which situations trigger the most distorted thinking,
**So that** I can target my growth and see evidence of progress.

**Priority:** Should (S1, S2)
**Story Points:** 8

**Conditions of Satisfaction:**

- Given I have 10+ records with distortions identified, When I view analytics, Then a horizontal bar chart shows my distortions ranked by frequency
- Given I have 5+ 7-column records, When I view analytics, Then a line chart shows average pre-balanced and post-balanced emotion intensity over time (grouped by week)
- Given I have fewer than 5 records, When I view analytics, Then a placeholder message says "Keep recording -- your patterns will appear after 5 thought records"
- Given the analytics charts are displayed, When I tap a distortion bar, Then a detail view shows the records tagged with that distortion

---

### Story 9: Urge Log Integration

**As a** recovering person who just logged an urge,
**I want** to be prompted to examine the thoughts behind my urge with a thought record,
**So that** I address the cognitive dimension of my urge while it is active.

**Priority:** Should (S4)
**Story Points:** 3

**Conditions of Satisfaction:**

- Given I save an urge log entry, When the save confirmation appears, Then a prompt asks "Want to examine the thoughts behind this urge?" with "Yes" and "Not now" buttons
- Given I tap "Yes", When the thought record wizard opens, Then it is pre-linked to the urge log entry (linkedUrgeLogId is set) and the Situation field is pre-populated with the urge context
- Given I complete the linked thought record, When I view it in history, Then the urge log link is visible and tappable

---

### Story 10: FASTER Scale Integration

**As a** recovering person who just completed a FASTER Scale check-in at an elevated stage,
**I want** to be suggested a thought record to examine the cognitive component of my escalation,
**So that** I intervene at the cognitive level during an active FASTER progression.

**Priority:** Should (S5)
**Story Points:** 3

**Conditions of Satisfaction:**

- Given I complete a FASTER check-in and my assessed stage is Anxiety, Speeding Up, or Ticking, When the results screen displays, Then a suggestion banner appears: "A Thought Record can help you examine what's driving this escalation"
- Given I tap the suggestion, When the wizard opens, Then it is pre-linked to the FASTER entry and the Situation field prompts "What situation or thoughts are contributing to your FASTER stage?"
- Given my FASTER check-in is at Forgetting Priorities or lower, When the results screen displays, Then no thought record suggestion appears

---

### Story 11: Balanced Thought Bookmarking (Truth Library)

**As a** recovering person who has generated effective balanced thoughts,
**I want** to save my best balanced thoughts for easy re-use when I face similar distortions,
**So that** I build a personal library of truth statements I can turn to in moments of distorted thinking.

**Priority:** Should (S9)
**Story Points:** 3

**Conditions of Satisfaction:**

- Given I am viewing a completed thought record with a balanced thought, When I tap the bookmark icon, Then the balanced thought is saved to my Truth Library with its associated distortion(s)
- Given I navigate to the Truth Library, When the list renders, Then bookmarked balanced thoughts are grouped by distortion, showing the thought text and source record date
- Given I am in a new thought record at the Balanced Thought step, When I tap "My Truth Library", Then I can browse saved balanced thoughts and insert one as a starting point

---

### Story 12: Today View Integration

**As a** recovering person using the Today view as my daily hub,
**I want** to see my completed thought records in the activity feed and access the feature from quick actions,
**So that** thought records are part of my integrated daily recovery view.

**Priority:** Must (M12, FR-35)
**Story Points:** 3

**Conditions of Satisfaction:**

- Given I have completed a thought record today, When I view the Today screen, Then a card shows "Thought Record" with the distortion tag and emotion change if available
- Given I have not yet created a thought record today, When I view Today quick actions, Then "Thought Record" is available as an action
- Given I have not yet set up the feature (no psychoeducation completed), When I view Today, Then no thought record card appears

---

### Story Point Summary

| Story | Title | Points | Priority | Sprint |
|---|---|---|---|---|
| S1 | Psychoeducation Screen | 3 | Must | 1 |
| S2 | 3-Column Entry (Beginner) | 8 | Must | 1 |
| S3 | 5-Column Entry (Intermediate) | 8 | Must | 2 |
| S4 | 7-Column Entry (Advanced) | 5 | Must | 2 |
| S5 | Progressive Level System | 3 | Must | 1 |
| S6 | Cognitive Distortion Library | 5 | Must | 1 |
| S7 | Thought Record History | 5 | Must | 2 |
| S8 | Pattern Analytics Dashboard | 8 | Should | 3 |
| S9 | Urge Log Integration | 3 | Should | 3 |
| S10 | FASTER Scale Integration | 3 | Should | 3 |
| S11 | Balanced Thought Bookmarking | 3 | Should | 3 |
| S12 | Today View Integration | 3 | Must | 2 |
| **Total** | | **57** | | |

---

## 8. Feature Comparison Matrix

### Standard vs Premium+ Tier

| Capability | Standard (Self-Directed) | Premium+ (AI-Assisted) |
|---|---|---|
| **Entry Modes** | 3, 5, 7-column with guided prompts | Same + AI suggests which mode based on situation complexity |
| **Distortion Identification** | Manual selection from library | AI suggests distortions based on automatic thought text |
| **Evidence Generation** | Guided prompts (questions to consider) | AI generates evidence-against suggestions the user can accept/edit |
| **Balanced Thought** | Manual with scripture suggestions | AI generates 2-3 candidate balanced thoughts, user selects/edits |
| **Scripture Integration** | Pre-curated per-distortion suggestions | AI selects contextually relevant scripture based on full record content |
| **Analytics** | Charts and trends | Same + AI narrative insights ("You tend toward entitlement thinking after work stress -- here is what you can try") |
| **Pattern Insights** | Distortion frequency, emotion trends | Same + AI identifies trigger-distortion patterns and suggests targeted exercises |

### Feature Availability by Sprint

| Capability | Sprint 1 | Sprint 2 | Sprint 3 | Sprint 4 |
|---|---|---|---|---|
| Psychoeducation screen | Standard | | | |
| 3-column entry wizard | Standard | | | |
| Progressive level system | Standard | | | |
| Cognitive distortion library | Standard | | | |
| 5-column entry wizard | | Standard | | |
| 7-column entry wizard | | Standard | | |
| History and detail view | | Standard | | |
| Today view integration | | Standard | | |
| Pattern analytics | | | Standard | |
| Urge log integration | | | Standard | |
| FASTER Scale integration | | | Standard | |
| Truth Library (bookmarks) | | | Standard | |
| Scripture suggestions | | | Standard | |
| AI distortion detection | | | | Premium+ |
| AI balanced thought assist | | | | Premium+ |

---

## 9. Implementation Roadmap

### Sprint 1: Foundation -- 3-Column Entry + Distortion Library (Ready)

**Sprint Goal:** Users can create 3-column thought records and browse the cognitive distortion library.

**Stories:**
- S1: Psychoeducation Screen (3 pts) -- Must
- S2: 3-Column Entry (8 pts) -- Must
- S5: Progressive Level System (3 pts) -- Must
- S6: Cognitive Distortion Library (5 pts) -- Must

**Total Points:** 19

**Work Breakdown:**

| Task | Story | Estimate |
|---|---|---|
| Create `RRThoughtRecord` and `RRCBTProgress` SwiftData models | S2, S5 | 3h |
| Create supporting Codable types (`ThoughtEntry`, `EmotionRating`, `CognitiveDistortionType`, `EmotionType`) | S2, S6 | 4h |
| Create cognitive distortion content data (14 distortions with all fields) | S6 | 4h |
| Create emotion content data (15 emotions with colors/icons) | S2 | 1h |
| Create scripture suggestion data (2-4 passages per distortion) | S6 | 2h |
| Build `CBTWizardViewModel` with step management, state, save logic | S2 | 4h |
| Build `CBTSituationStepView` | S2 | 2h |
| Build `CBTThoughtStepView` (multi-thought entry with hot thought marking) | S2 | 3h |
| Build `CBTEmotionStepView` (emotion picker grid + intensity sliders) | S2 | 4h |
| Build `CBTWizardFlowView` (orchestrates step-by-step navigation) | S2 | 3h |
| Build `CBTPsychoeducationView` with Christian integration content | S1 | 2h |
| Build `CBTDistortionLibraryView` with list and detail views | S6 | 3h |
| Build `CBTProgressService` for level tracking and unlock logic | S5 | 2h |
| Register models in `RRModelConfiguration.allModels` | All | 0.5h |
| Add `activity.cbt-thoughts` feature flag | All | 0.5h |
| Unit tests: model creation, save, level unlock thresholds | S2, S5 | 3h |
| Unit tests: distortion content completeness | S6 | 1h |

**Dependencies:** None (greenfield feature)

---

### Sprint 2: Full Entry -- 5/7-Column + History (Ready)

**Sprint Goal:** Users can create 5-column and 7-column thought records with distortion identification, evidence examination, balanced thoughts, and outcome measurement. History view is available.

**Stories:**
- S3: 5-Column Entry (8 pts) -- Must
- S4: 7-Column Entry (5 pts) -- Must
- S7: Thought Record History (5 pts) -- Must
- S12: Today View Integration (3 pts) -- Must

**Total Points:** 21

**Work Breakdown:**

| Task | Story | Estimate |
|---|---|---|
| Build `CBTDistortionStepView` (picker with expandable details) | S3 | 3h |
| Build `CBTBalancedThoughtStepView` (prompts + scripture suggestion button) | S3 | 3h |
| Build `CBTEvidenceForStepView` | S4 | 2h |
| Build `CBTEvidenceAgainstStepView` (with guided prompts) | S4 | 2h |
| Build `CBTOutcomeStepView` (emotion re-rating) | S4 | 3h |
| Extend `CBTWizardViewModel` for 5-column and 7-column modes | S3, S4 | 3h |
| Build `CBTHistoryListView` with record cards | S7 | 3h |
| Build `CBTRecordDetailView` (read-only view of completed record) | S7 | 2h |
| Build delete functionality with confirmation | S7 | 1h |
| Add thought record card to Today view activity log | S12 | 2h |
| Add thought record to Today view completion tracking | S12 | 1h |
| Navigation integration: Recovery Work tab tile, ActivityDestinationView routing | S12 | 2h |
| Unit tests: 5-column save with distortions, 7-column save with evidence and outcome | S3, S4 | 3h |
| Unit tests: emotion intensity change calculation | S4 | 2h |

**Dependencies:** Sprint 1 (models, 3-column wizard, distortion library)

---

### Sprint 3: Insights -- Analytics + Integrations + Truth Library (Stub)

**Sprint Goal:** Users can see patterns in their thought records, receive prompts from urge log and FASTER Scale, and bookmark effective balanced thoughts.

**Stories:**
- S8: Pattern Analytics Dashboard (8 pts) -- Should
- S9: Urge Log Integration (3 pts) -- Should
- S10: FASTER Scale Integration (3 pts) -- Should
- S11: Balanced Thought Bookmarking (3 pts) -- Should

**Total Points:** 17

**Key Tasks:**
- Build analytics view with distortion frequency bar chart (Swift Charts)
- Build emotion intensity trend line chart
- Extend urge log save flow with thought record prompt
- Extend FASTER results view with thought record suggestion at A/S/T stages
- Build Truth Library view and bookmark functionality
- Scripture suggestion UI integrated into Balanced Thought step
- Comprehensive analytics accuracy tests

**Dependencies:** Sprint 2 (history, full entry modes)

---

### Sprint 4: Premium+ AI + Polish (Stub)

**Sprint Goal:** Premium+ tier adds AI-assisted distortion detection and balanced thought generation. Polish and edge case handling.

**Stories:**
- AI distortion detection (Could, C2)
- AI balanced thought generation (Could, C1)
- Accountability sharing for thought record analytics (Should, S6)
- End-to-end testing and polish

**Total Points:** 8 + spike

**Key Tasks:**
- Design AI prompts for distortion detection from automatic thought text
- Design AI prompts for balanced thought generation
- Build Premium+ tier gate on AI features
- Extend sharing data model for thought record summary analytics
- Full regression testing across 3/5/7-column modes

**Dependencies:** Sprint 3 (analytics, integrations)

---

### Dependency Map

```
Sprint 1                    Sprint 2                    Sprint 3                    Sprint 4
---------                   ---------                   ---------                   ---------
S1 Psychoeducation -------> (informational only)
S2 3-Column Entry --------> S3 5-Column Entry --------> S8 Analytics
                            S4 7-Column Entry --------> S9 Urge Integration
S5 Level System ----------> S3/S4 (unlock gates)        S10 FASTER Integration ---> AI Features
S6 Distortion Library ----> S3 (distortion picker) ---> S11 Truth Library --------> Sharing
                            S7 History ----------------> S8 (data source)
                            S12 Today Integration
```

---

## 10. Open Questions and Risks

### Open Questions

| # | Question | Impact | Owner | Status |
|---|---|---|---|---|
| OQ-1 | Should the progressive unlock thresholds be 5/10 records, or should they be based on quality indicators (e.g., emotion reduction achieved)? | Affects S5 implementation | Product | Open |
| OQ-2 | Should users be able to edit a saved thought record, or should records be immutable once saved? Immutability preserves the "in the moment" cognitive snapshot, but users may want to refine balanced thoughts. | Affects S7 and data model | Product | Open |
| OQ-3 | Should the emotion picker use a feelings wheel (more nuanced) or a simple grid (faster)? | Affects S2 UI design | UX | Open |
| OQ-4 | How should thought records contributed to the Recovery Health Score? Options: (a) records-per-week count, (b) average emotion reduction, (c) frequency relative to urge events. | Affects future RHS integration | Product | Open |
| OQ-5 | Should AI-generated balanced thoughts include an explicit "AI suggested this" label, or is the Premium+ context sufficient? | Affects C1 UI | Product + Legal | Open |
| OQ-6 | Should the feature name be "Thought Records" (clinical) or "Thought Check" (approachable)? | Affects all UI text | Product + UX | Open |

### Risks

| # | Risk | Probability | Impact | Mitigation | Owner |
|---|---|---|---|---|---|
| R-1 | Wizard abandonment: users start a record but do not complete it | Medium | Medium | Draft auto-save between steps; show "You have an unfinished record" on next visit; keep 3-column mode fast (< 3 min) | Engineering |
| R-2 | Poor balanced thought quality: users struggle to generate alternatives without AI | High | High | Guided prompts with Socratic questions, scripture suggestions, "What would you tell a friend?" prompt, future AI assist | Product |
| R-3 | Feature confusion with journaling: users see overlap between thought records and journal entries | Medium | Low | Clear onboarding differentiation; thought records are structured and analytical, journaling is free-form and exploratory | Product + UX |
| R-4 | Over-intellectualization: users complete thought records mechanically without emotional engagement | Low | Medium | Compassionate framing throughout; emotion intensity sliders keep feelings central; outcome measurement validates emotional impact | UX |
| R-5 | Privacy anxiety: users reluctant to record deeply personal thoughts digitally | Low | Medium | Local-only storage, biometric lock, private marking option, no automatic sharing | Product |
| R-6 | Distortion library overwhelm: 14 distortions is too many for beginners | Medium | Low | Progressive distortion introduction (show 5 most common initially, expand to all 14 after 5 records) | UX |

### Assumptions to Validate

1. Users in SA/Celebrate Recovery will engage with a CBT-based tool alongside their 12-step work (not seen as conflicting frameworks)
2. The progressive 3 -> 5 -> 7 column model reduces abandonment compared to starting with the full 7 columns
3. Scripture suggestions meaningfully enhance balanced thought quality for this user population
4. The guided wizard format is preferred over free-form entry for the target user personas

---

## 11. Design Decisions Log

### Decision D1: Feature Naming

**Options Considered:**
1. "CBT Thought Records" -- Clinical, recognizable to therapy-literate users
2. "Thought Check" -- Approachable, less clinical
3. "Mind Renewal" -- Christian-first, references Romans 12:2
4. "Thought Captive" -- References 2 Corinthians 10:5

**Chosen:** Option 1 -- "CBT Thought Records" (in-app label: "Thought Records")

**Rationale:** The feature should be immediately recognizable to users who have encountered thought records in therapy or self-help reading (Alex persona). The label "Thought Records" is used in-app (without the CBT prefix) for simplicity. "Mind Renewal" and "Thought Captive" are creative but may not communicate what the tool actually does. The biblical connections are made in the psychoeducation content and throughout the feature UX, but the feature name itself prioritizes functional clarity. Open question OQ-6 may revisit this based on user testing.

---

### Decision D2: Progressive Column Model (3 -> 5 -> 7)

**Options Considered:**
1. Start all users with 7-column (full format)
2. Start all users with 3-column, permanently (simplified only)
3. Progressive unlock: 3 -> 5 -> 7 based on record count

**Chosen:** Option 3 -- Progressive unlock

**Rationale:** The full 7-column thought record is a powerful tool but has high cognitive load. Starting beginners with 7 columns risks abandonment before the skill develops. Starting everyone with 3 columns and never advancing misses the therapeutic power of evidence examination and balanced thought generation. The progressive approach builds skill incrementally: first learn to notice (3 columns), then learn to challenge (5 columns), then learn to fully restructure (7 columns). The CCI's graduated worksheet series (Thought Diary 1, 2, 3) validates this clinical pattern. Users can always manually unlock higher levels if they are already experienced with thought records.

---

### Decision D3: Emotion Rating Scale

**Options Considered:**
1. 0-10 integer scale
2. 0-100% continuous slider
3. Categorical (none, mild, moderate, severe, extreme)

**Chosen:** Option 2 -- 0-100% continuous slider

**Rationale:** The 0-100% scale is the standard used in clinical thought records (Greenberger & Padesky). It provides granularity for measuring change: a shift from 75% to 50% is meaningful and measurable, while a shift from 8 to 5 on a 10-point scale loses nuance. The percentage framing also makes the "before vs. after" comparison intuitive -- users can see a "30% reduction in shame" as a concrete achievement. Continuous sliders are natural on touch screens. The categorical option is too coarse for tracking improvement over time.

---

### Decision D4: Number of Cognitive Distortions

**Options Considered:**
1. Burns' original 10 distortions
2. Extended 14 (Burns' 10 + addiction-specific additions)
3. Simplified 8 (most common only)

**Chosen:** Option 2 -- Extended 14 distortions

**Rationale:** Burns' original 10 capture the general cognitive distortions, but addiction recovery requires "Entitlement" as a separate, named distortion. Entitlement thinking is so central to sex addiction (and so common in thought records from this population) that it warrants explicit inclusion rather than being subsumed under "Should Statements." The 14-distortion library includes Burns' 10 (with "Jumping to Conclusions" split into Mind Reading and Fortune Telling, and "Magnification/Minimization" retained alongside Catastrophizing as a specific subtype) plus Entitlement and Blaming as separate entries. The distortion library can be progressively disclosed (show 5 most common initially) per Risk R-6.

---

### Decision D5: Wizard vs. Free-Form Entry

**Options Considered:**
1. Wizard only (one step per screen)
2. Free-form only (all columns on one screen)
3. Wizard by default, Quick Entry mode unlockable

**Chosen:** Option 3 -- Wizard default with Quick Entry unlock

**Rationale:** The wizard format dramatically reduces cognitive load for beginners -- each screen has a single focused task with contextual guidance. However, experienced users will find the wizard slow. Quick Entry mode (all columns visible on one scrollable screen) is unlocked as an option once the user has completed 10 records and demonstrated fluency. Both modes produce identical data. This follows the PCI/LBI pattern where the feature starts guided and becomes more flexible with experience.

---

### Decision D6: Scripture Integration Approach

**Options Considered:**
1. No scripture integration (purely clinical CBT)
2. Scripture as optional balanced thought suggestions (per-distortion mapping)
3. Scripture as mandatory component of balanced thoughts

**Chosen:** Option 2 -- Optional scripture suggestions

**Rationale:** Making scripture mandatory would alienate users who prefer a purely cognitive approach or who are exploring the app before fully embracing the faith dimension. Making it entirely absent would miss the core value proposition of a Christian recovery app. The chosen approach maps 2-4 scripture passages to each cognitive distortion, presented as tappable chips on the Balanced Thought screen. Users can incorporate scripture, ignore it, or combine scripture with their own words. This respects both the clinical integrity of the thought record and the spiritual dimension of the app's identity.

---

### Decision D7: Draft Auto-Save Strategy

**Options Considered:**
1. Save only on explicit "Save" action
2. Auto-save after each wizard step
3. Auto-save on app background/close

**Chosen:** Option 2 -- Auto-save after each step

**Rationale:** Thought records are often completed during emotional distress. If a user is on step 5 of 7 and their phone dies, losing all progress would be deeply frustrating and could discourage future use. Auto-saving after each step means the maximum data loss is the current step's content. On next access, the user sees "You have an unfinished record" and can resume or discard. This follows the PCI/LBI setup flow's save-and-resume pattern.

---

### Decision D8: Thought Record Mutability

**Options Considered:**
1. Immutable once saved (preserves "in the moment" snapshot)
2. Fully editable at any time
3. Editable within 24 hours, then locked

**Chosen:** Option 1 -- Immutable once saved (recommended, pending OQ-2)

**Rationale:** A thought record captures a cognitive event as it happened. The therapeutic value is in the authentic, unedited thought process. Editing a thought record after the fact changes it from a real-time cognitive capture to a polished narrative, which reduces its clinical utility. Users who want to refine a balanced thought can create a new record referencing the same situation. However, this is an open question (OQ-2) -- user testing may reveal that editing is strongly desired.

---

### Decision D9: Accountability Sharing Scope

**Options Considered:**
1. Share everything (full record text visible to accountability partner)
2. Share summary analytics only (distortion frequency, emotion trends)
3. Share nothing (completely private feature)

**Chosen:** Option 2 -- Summary analytics only

**Rationale:** Thought records contain the most sensitive data in the entire app -- raw, unfiltered automatic thoughts about addiction, desire, shame, and rationalization. Sharing this text directly could discourage honest recording. However, sharing analytics (which distortions are most frequent, whether emotion intensity is decreasing) provides accountability partners with exactly the signal they need without exposing specific cognitive content. This follows the PCI/LBI pattern of sharing scores but not item text.

---

## Appendix A: Cognitive Distortion Library Content

| # | Distortion | Definition | General Example | Sex Addiction Example | Counter-Questions | Scripture |
|---|-----------|-----------|----------------|---------------------|------------------|-----------|
| 1 | All-or-Nothing Thinking | Seeing things in absolute terms with no middle ground | "If I'm not perfect, I'm a total failure." | "I relapsed once, so my whole recovery is ruined." | "Is there any middle ground here? Can something be partly true?" | Proverbs 24:16 -- "Though the righteous fall seven times, they rise again." |
| 2 | Overgeneralization | Drawing broad conclusions from single events | "This always happens to me." | "I always give in to temptation. I'll never change." | "Is this really always true? What exceptions exist?" | Philippians 1:6 -- "He who began a good work in you will carry it on to completion." |
| 3 | Mental Filter | Dwelling on negatives while filtering out positives | "The whole day was awful." (ignoring good parts) | "All I can think about is that one triggering moment today." | "What am I choosing not to see? What went well?" | Philippians 4:8 -- "Whatever is true, noble, right, pure, lovely... think about such things." |
| 4 | Disqualifying the Positive | Rejecting positive experiences as not counting | "My sobriety streak doesn't matter -- it's just luck." | "30 days clean doesn't mean anything; I'll just fail again." | "If a friend had this achievement, what would I say to them?" | 1 Thessalonians 5:18 -- "Give thanks in all circumstances." |
| 5 | Mind Reading | Assuming others think negatively about you | "Everyone can tell I'm struggling." | "My sponsor thinks I'm hopeless." | "Do I have actual evidence for what they think? Have I asked them?" | 1 Samuel 16:7 -- "The Lord does not look at the things people look at." |
| 6 | Fortune Telling | Predicting negative outcomes | "I know this is going to end badly." | "If I go to that event, I know I'll be triggered and relapse." | "Can I really predict the future? What other outcomes are possible?" | Jeremiah 29:11 -- "'For I know the plans I have for you,' declares the Lord, 'plans to prosper you.'" |
| 7 | Catastrophizing | Assuming the worst possible outcome | "If people find out, my life is over." | "If my wife discovers what I did, she'll leave and I'll lose everything." | "What is the most likely outcome (not worst case)? How have I handled difficult situations before?" | Isaiah 41:10 -- "Do not fear, for I am with you; do not be dismayed." |
| 8 | Magnification/Minimization | Blowing up negatives, shrinking positives | "My mistake was enormous; my efforts don't matter." | "One lustful thought means all my recovery work is worthless." | "Am I giving appropriate weight to both the good and the bad?" | Romans 8:1 -- "There is now no condemnation for those who are in Christ Jesus." |
| 9 | Emotional Reasoning | Treating feelings as facts | "I feel like a failure, so I must be one." | "I feel like I need this, so I must need it. The urge is unbearable." | "Just because I feel something, is it actually true? Have feelings misled me before?" | 2 Corinthians 5:7 -- "For we walk by faith, not by sight." |
| 10 | Should Statements | Rigid rules about how things should be | "I should be further along by now." | "I should be able to resist every temptation by now." | "Who says 'should'? Is this realistic? Can I replace 'should' with 'I would like to'?" | Galatians 5:1 -- "It is for freedom that Christ has set us free." |
| 11 | Labeling | Attaching a negative label to yourself or others | "I'm an idiot." | "I'm a disgusting person. I'm beyond help." | "Is this a fair label? Would I label someone else this way for the same thing?" | 2 Corinthians 5:17 -- "If anyone is in Christ, the new creation has come." |
| 12 | Personalization | Taking disproportionate blame for external events | "It's all my fault my marriage is struggling." | "My wife's unhappiness is entirely because of my addiction." | "What other factors are involved? What is actually within my control?" | 1 Peter 5:7 -- "Cast all your anxiety on him because he cares for you." |
| 13 | Blaming | Assigning all responsibility to others | "If my spouse understood me, I wouldn't have this problem." | "If my wife met my needs, I wouldn't look elsewhere." | "What is my part in this? What can I take responsibility for?" | Galatians 6:5 -- "Each one should carry their own load." |
| 14 | Entitlement | Believing you deserve special treatment or reward | "I've been so good, I deserve a break from recovery." | "I work hard and handle stress all day -- I've earned some pleasure." | "Does 'deserving' something make it wise? What do I truly need vs. what do I want?" | Matthew 26:41 -- "Watch and pray so that you will not fall into temptation." |

---

## Appendix B: Emotion Type Reference

| Emotion | Color | SF Symbol |
|---------|-------|-----------|
| Anxious | #FFA500 (orange) | heart.circle |
| Angry | #FF3B30 (red) | flame.fill |
| Ashamed | #8E44AD (purple) | eye.slash.fill |
| Sad | #5B7FDB (blue) | cloud.rain.fill |
| Lonely | #95A5A6 (gray) | person.crop.circle.badge.minus |
| Bored | #BDC3C7 (silver) | zzz |
| Hopeless | #2C3E50 (dark blue) | xmark.circle.fill |
| Worthless | #7F8C8D (charcoal) | minus.circle.fill |
| Disgusted | #27AE60 (green) | hand.raised.slash.fill |
| Excited | #F39C12 (gold) | bolt.fill |
| Guilty | #C0392B (dark red) | scale.3d |
| Jealous | #16A085 (teal) | eye.fill |
| Frustrated | #E74C3C (red-orange) | exclamationmark.triangle.fill |
| Afraid | #2980B9 (blue) | shield.slash.fill |
| Overwhelmed | #8B0000 (dark red) | tornado |
