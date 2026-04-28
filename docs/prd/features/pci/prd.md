# Personal Craziness Index (PCI) -- Feature PRD

| Field | Value |
|---|---|
| **PRD Title** | Personal Craziness Index (PCI) |
| **Author** | Travis Smith |
| **Date** | 2026-04-22 |
| **Version** | 1.0 |
| **Designation** | Feature (within Recovery Tools Epic) |
| **OMTM** | Reduction in weekly PCI score variance (users maintaining Optimal Health or Stable Solidity range >= 80% of tracked weeks) |
| **Target Delivery** | 4 sprints (40 business days maximum) |
| **MoSCoW Summary** | 14 Must, 8 Should, 6 Could, 5 Won't |

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
10. [JIRA Readiness Checklist](#10-jira-readiness-checklist)
11. [Open Questions and Risks](#11-open-questions-and-risks)
12. [Design Decisions Log](#12-design-decisions-log)

---

## 1. Executive Summary

### Problem Statement

Users in addiction recovery lack a structured, daily self-monitoring tool that detects lifestyle erosion before it cascades into relapse-triggering emotional and behavioral patterns. The existing FASTER Scale check-in identifies active relapse progression but only after emotional/behavioral escalation has begun. By the time a user recognizes they are in the Forgetting Priorities (F) or Anxiety (A) stage of FASTER, the conditions that created that vulnerability -- neglected physical health, chaotic finances, social isolation, abandoned recovery practices -- have already been accumulating for days or weeks without detection.

**User goal:** Maintain awareness of daily life balance across all major life dimensions so that small slips in routine are caught early, before they compound into relapse risk.

**Hurdles:**
- Paper-based PCI worksheets require manual scoring, are easily lost, and provide no trend visualization
- The initial setup (defining ~36 personal indicators across 12 life dimensions) is a significant cognitive and time investment that many users abandon
- Without digital tracking, users cannot see multi-week trend lines that reveal the gradual lifestyle erosion pattern Carnes describes as "the boulder starting to roll"
- No existing integration between PCI data and other recovery metrics (FASTER Scale, mood, urge frequency) prevents users from seeing the upstream-downstream relationship

**Quantifiable impact:** Research from Integrity Counseling Group indicates that users who track PCI consistently identify lifestyle deterioration 1-3 weeks before it would otherwise surface as FASTER Scale escalation. The cost of missed early detection is a relapse event, which according to SA recovery literature sets recovery progress back by an average of 30-90 days and carries significant relational, professional, and spiritual consequences.

### Business Hypothesis

By providing a digital PCI implementation with guided setup, frictionless daily check-in (under 60 seconds), automated weekly scoring, and visual trend analysis integrated with existing recovery tools, we hypothesize that:

- **Primary outcome:** 70% of users who complete PCI setup will maintain daily tracking for 8+ weeks (measured by check-in completion rate)
- **Secondary outcome:** Users tracking PCI weekly will show a 15-20% reduction in FASTER Scale escalation events (T/E/R stages) compared to their pre-PCI baseline, measured over 12 weeks
- **OMTM impact:** Target 2-3% improvement in overall app retention (the Recovery Tools epic's contribution to the app-wide OMTM)

### Solution Overview

A three-phase PCI implementation within the Regal Recovery iOS app:
1. **Guided Setup Flow** -- Walk users through defining personal behavioral indicators across 10 life dimensions, then selecting their 7 most critical items for daily tracking
2. **Daily Check-In** -- A sub-60-second binary toggle interface for the 7 critical items, integrated into the evening activity flow alongside existing check-ins
3. **Trend Dashboard** -- Weekly scoring with 5-level risk interpretation, 12-week trend visualization, and correlation display with FASTER Scale and mood data

### Resource Requirements

- 1 iOS developer (4 sprints)
- Design review at Sprint 1 boundary
- QA integrated throughout
- No backend API changes required for MVP (SwiftData local-first)

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Users abandon setup before completion | High | High | Progressive setup (dimension-by-dimension), save progress, allow partial completion |
| Daily check-in fatigue | Medium | High | Sub-60-second UX, evening notification, missed-day rule creates natural incentive |
| Licensing claim from Carnes estate/IITAP | Low | Medium | Use "Life Balance Index" naming with original user-defined behaviors (concept is generic self-assessment) |
| Scope creep from AI-guided setup | Medium | Medium | Defer AI features to Premium+ tier in Sprint 4, ship Standard tier first |
| SwiftData performance with 12+ weeks of daily entries | Low | Low | Indexed queries, lazy loading, tested with 365-day dataset |

---

## 2. Product Overview

### Product Vision

The Life Balance Index (LBI) brings Patrick Carnes' Personal Craziness Index concept into the digital recovery toolkit as the app's most proactive self-monitoring tool. It sits upstream of every other recovery tool -- detecting the gradual erosion of daily routines and life balance that, left unchecked, creates the conditions for the relapse progression the FASTER Scale measures. When a user's LBI score rises, it is an early warning signal that the "boulder is ready to roll" -- and catching it here, before emotional and behavioral escalation begins, is orders of magnitude easier than intervening later.

### Target Users

**Primary Persona: Alex (Active Recovery)**
- 6-18 months into SA/Celebrate Recovery program
- Has a sponsor and accountability partner
- Uses Regal Recovery daily for check-ins, FASTER Scale, mood tracking
- Has worked through or is working through *Facing the Shadow* with a CSAT
- Motivated but struggles with "I feel fine" blindness -- cannot see lifestyle erosion until it manifests as emotional crisis
- Needs: a structured daily practice that makes invisible patterns visible

**Secondary Persona: Jordan (Early Recovery)**
- 0-6 months in recovery, establishing daily routines
- May not yet have encountered the PCI concept in clinical/group settings
- Needs: scaffolded guidance to identify personal warning signs, with examples and encouragement
- Lower tolerance for complex setup -- needs the progressive approach

**Tertiary Persona: Sam (Sponsor/Accountability Partner)**
- Reviews shared data from accountability partners
- Needs: visibility into LBI trend data to identify when a partner's lifestyle is eroding, enabling proactive conversation before crisis

### Value Proposition

"See the erosion before you feel the crisis. Your Life Balance Index tracks the daily routines that keep your recovery strong -- so you catch the first cracks before the foundation gives way."

### OMTM and Success Criteria

**One Metric That Matters:** Weekly PCI score stability -- the percentage of tracked weeks where the user's score falls in the Optimal Health (0-9) or Stable Solidity (10-19) range.

| Success Criterion | Target | Measurement Method |
|---|---|---|
| Setup completion rate | >= 60% of users who start setup finish it within 7 days | Local analytics: setup_started vs setup_completed events |
| Daily check-in adherence | >= 70% of days checked in during first 8 weeks | Completion rate: (days checked in) / (days since setup) |
| Weekly score in healthy range | >= 50% of users in Optimal or Stable range after 4 weeks | Weekly score distribution across active users |
| FASTER escalation reduction | 15-20% fewer T/E/R stage check-ins after 12 weeks of PCI tracking | Pre/post comparison of FASTER stage distribution per user |
| Feature retention | >= 40% of setup completers still tracking at week 12 | 12-week retention cohort analysis |
| Daily check-in duration | <= 60 seconds median | Time from check-in screen open to save |

### Scope Constraints

- **Feature scope:** Maximum 4 sprints (40 business days)
- **Platform:** iOS only (SwiftUI + SwiftData)
- **Tier:** Standard tier (self-directed) ships in Sprints 1-3; Premium+ tier (AI-guided) ships in Sprint 4
- **Backend:** Local-first with SwiftData; API sync deferred to future feature
- **No therapist portal integration** in this scope

### Assumptions

1. Users have completed onboarding and have an active RRUser record in SwiftData
2. Users understand the general concept of relapse prevention (prerequisite recovery knowledge)
3. The LBI naming avoids any licensing issues (the underlying PCI concept of self-defined behavioral indicators across life dimensions is a generic therapeutic technique)
4. Users can define meaningful personal indicators with the aid of Carnes' category descriptions and example behaviors (included in the app as guidance text)
5. The existing evening activity notification infrastructure can be extended to include LBI reminders

---

## 3. MoSCoW Prioritized Requirements

### Must Have (Non-negotiable for launch -- solution fails without these)

| ID | Requirement | Rationale |
|---|---|---|
| M1 | 10 life dimension framework with descriptions and example behaviors | Core structure that ensures whole-life coverage |
| M2 | User defines 1-5 personal behavioral indicators per dimension | Personalization is the defining characteristic of the tool |
| M3 | User selects exactly 7 critical indicators from across all dimensions for daily tracking | The 7-item reduction makes daily tracking sustainable |
| M4 | Binary daily scoring (0 = did not occur, 1 = occurred) for each of the 7 critical items | Original Carnes scoring; simplicity enables sub-60-second check-in |
| M5 | Daily score calculation (0-7) | Fundamental data point for weekly aggregation |
| M6 | Weekly score calculation (0-49) from 7 daily scores | Core metric that maps to risk levels |
| M7 | 5-level risk interpretation (Optimal Health through Very High Risk) with descriptions | Gives meaning to raw numbers |
| M8 | Missed day receives automatic score of 7 | Carnes' rule; inability to track is itself evidence of imbalance |
| M9 | Setup flow allows saving progress and resuming across sessions | 12-dimension setup cannot reasonably be completed in one sitting for all users |
| M10 | Interests dimension handles positive-to-negative rephrasing when selected as critical item | Only positive category; must score consistently with negative indicators |
| M11 | SwiftData persistence for all PCI data (profile, daily entries, weekly summaries) | Offline-first architecture requirement |
| M12 | PCI accessible from Recovery Work tab and Today view | Must be discoverable in the app's primary navigation paths |
| M13 | Users can edit their indicators and critical-7 selections at any time | Items evolve as recovery progresses |
| M14 | Historical data remains valid after indicator edits (profile versioning) | Editing current items must not corrupt or invalidate past entries |

### Should Have (Important but solution is viable without; can be postponed)

| ID | Requirement | Rationale |
|---|---|---|
| S1 | 12-week trend chart with color-coded risk level bands | Visual pattern recognition is a key PCI benefit |
| S2 | Weekly summary card with risk level, score, and week-over-week change | Quick status check without entering full dashboard |
| S3 | Evening notification reminding user to complete daily check-in | Adherence driver; leverages existing notification infrastructure |
| S4 | Integration with Recovery Health Score (LBI weekly score as a component) | Strategic PRD requirement; connects LBI to the overall recovery metric |
| S5 | Psychoeducation content explaining what the LBI is and why it matters (shown before setup) | Reduces setup abandonment by establishing motivation |
| S6 | Per-dimension completion indicator during setup showing progress | Reduces overwhelm during the multi-step setup process |
| S7 | Shareable LBI trend summary for accountability partner | Accountability sharing is a core app feature |
| S8 | Correlation display showing LBI trend alongside FASTER Scale stage history | Demonstrates the upstream-downstream relationship that makes LBI uniquely valuable |

### Could Have (Nice-to-haves that improve UX; first to cut under constraints)

| ID | Requirement | Rationale |
|---|---|---|
| C1 | Premium+ AI-guided setup: AI agent helps users define indicators through conversation | Reduces cognitive load of self-definition; addresses Jordan persona's needs |
| C2 | Weekly reflection journal prompt based on risk level | Deepens self-awareness beyond binary tracking |
| C3 | Achievement badges for tracking streaks (7-day, 30-day, 90-day) | Gamification for adherence |
| C4 | Export PCI data as PDF for therapist/sponsor sharing | Bridges digital and clinical workflows |
| C5 | Suggested action items based on current risk level | Moves from awareness to intervention guidance |
| C6 | Dark mode optimized trend chart with smooth animations | Polish item |

### Won't Have (Explicitly excluded from this scope)

| ID | Requirement | Rationale |
|---|---|---|
| W1 | Backend API sync for PCI data | Deferred to sync epic; local-first is sufficient for MVP |
| W2 | Therapist portal view of client PCI data | Requires backend infrastructure not in scope |
| W3 | Community/group PCI comparisons | Privacy concern; PCI is deeply personal and not comparable across users |
| W4 | Intensity-scale scoring (1-7 or 0-10 per item) | Departs from Carnes' original binary design; adds complexity without proven benefit |
| W5 | Custom dimensions (adding/removing/renaming the 10 base dimensions) | Strict framework ensures whole-life coverage; customization risks blind spots |

---

## 4. Functional Requirements

### 4.1 LBI Setup Flow

| ID | Requirement | Priority | Tier | Conditions of Satisfaction |
|---|---|---|---|---|
| FR-01 | System displays psychoeducation screen explaining LBI purpose, the "boulder" metaphor, and what the user will do during setup | Should | Standard | Given the user navigates to LBI for the first time, When the setup flow begins, Then an educational screen is displayed with a "Get Started" button and the user can dismiss it |
| FR-02 | System presents 10 life dimensions sequentially, one at a time, each with Carnes' description and 2-4 example behaviors | Must | Standard | Given the user is in setup, When a dimension is presented, Then the dimension name, description text, prompt question, and example behaviors are displayed |
| FR-03 | User enters 1-5 personal behavioral indicators per dimension via free-text input fields | Must | Standard | Given a dimension is displayed, When the user types in an indicator field, Then text is accepted up to 200 characters per indicator, and the user can add between 1 and 5 indicators |
| FR-04 | User can skip a dimension during setup (entering 0 indicators) | Must | Standard | Given a dimension is displayed, When the user taps "Skip" or "Next" without entering indicators, Then the system advances to the next dimension and records 0 indicators for the skipped dimension |
| FR-05 | System saves setup progress after each dimension so the user can resume later | Must | Standard | Given the user has completed 4 of 10 dimensions, When the user closes the app and reopens it, Then the setup resumes at dimension 5 with dimensions 1-4 preserved |
| FR-06 | After all 10 dimensions are reviewed, system presents all entered indicators (across all dimensions) for critical-7 selection | Must | Standard | Given the user has completed all 10 dimensions, When the selection screen appears, Then all entered indicators are listed grouped by dimension, each with a selectable toggle |
| FR-07 | User selects exactly 7 indicators as "critical" items for daily tracking | Must | Standard | Given the selection screen is displayed, When the user selects items, Then a counter shows "X of 7 selected" and the "Done" button is enabled only when exactly 7 items are selected |
| FR-08 | When a positive indicator from the Interests dimension is selected as critical, the system automatically prepends "Lack of" and shows the rephrased version | Must | Standard | Given the user selects "Reading for pleasure" from the Interests dimension as a critical item, When the selection is confirmed, Then the daily tracking item reads "Lack of reading for pleasure" |
| FR-09 | System confirms setup completion and transitions to the daily check-in view | Must | Standard | Given the user has selected 7 critical items and taps "Done", When setup completes, Then a confirmation screen is shown with the 7 items listed and a "Start Tracking" button |
| FR-10 | Premium+ AI agent guides the user through indicator definition via conversational prompts | Could | Premium+ | Given a Premium+ user starts AI-guided setup, When a dimension is presented, Then the AI asks probing questions (e.g., "When your physical health slips, what is the first thing you notice?") and suggests indicator phrasing based on user responses |
| FR-11 | Setup flow displays a progress bar showing dimensions completed out of 10 | Should | Standard | Given the user is on dimension 6 of 10, When the screen renders, Then a progress indicator shows "6 of 10" or a proportional bar at 60% |

### 4.2 Daily Check-In

| ID | Requirement | Priority | Tier | Conditions of Satisfaction |
|---|---|---|---|---|
| FR-12 | Daily check-in screen displays the user's 7 critical items as a list of binary toggles | Must | Standard | Given the user opens the daily check-in, When the screen renders, Then 7 items are shown, each with a toggle defaulting to "off" (did not occur), and the screen loads in under 500ms |
| FR-13 | User toggles each item on (occurred = 1 point) or off (did not occur = 0 points) | Must | Standard | Given the check-in screen is displayed, When the user taps an item toggle, Then it switches state with haptic feedback, and the daily score counter updates immediately |
| FR-14 | System displays running daily score (0-7) as items are toggled | Must | Standard | Given 3 of 7 items are toggled on, When the user views the score, Then "3 / 7" is displayed prominently |
| FR-15 | User saves the daily check-in with a single tap | Must | Standard | Given all toggles are set, When the user taps "Save", Then the entry is persisted to SwiftData with the current date, score, and per-item values |
| FR-16 | System prevents duplicate check-ins for the same calendar day; editing an existing entry is allowed | Must | Standard | Given the user has already checked in today, When they open the check-in screen, Then the existing entry is loaded in edit mode with today's previously saved toggle states |
| FR-17 | If the user does not complete a check-in by 11:59 PM local time, the system records an automatic score of 7 for that day | Must | Standard | Given the user did not check in on April 21, When the app opens on April 22, Then April 21 is recorded with a score of 7 and is marked as "Missed" |
| FR-18 | System sends an evening push notification reminding the user to complete their daily check-in | Should | Standard | Given the user has enabled notifications and has not checked in today, When the configured reminder time arrives (default: 9:00 PM), Then a notification is delivered: "Time for your daily Life Balance check-in" |
| FR-19 | Check-in is accessible from Today view quick actions and Recovery Work tab | Must | Standard | Given the user is on the Today view, When they look at quick actions, Then "Life Balance Check-In" appears as an available action |

### 4.3 Scoring and Risk Assessment

| ID | Requirement | Priority | Tier | Conditions of Satisfaction |
|---|---|---|---|---|
| FR-20 | System calculates weekly score by summing 7 daily scores (range: 0-49) | Must | Standard | Given the user has checked in all 7 days of the week, When the weekly summary is calculated, Then the total equals the sum of the 7 daily scores |
| FR-21 | System maps weekly score to one of 5 risk levels per the interpretation scale | Must | Standard | Given a weekly score of 23, When the risk level is determined, Then "Medium Risk" is displayed with its description |
| FR-22 | Weekly summary card shows: weekly score, risk level with color, week-over-week change (arrow + delta), and a one-line description | Should | Standard | Given the current week score is 18 and last week was 12, When the summary card renders, Then it shows "18 - Stable Solidity" with an up arrow and "+6" in amber |
| FR-23 | Risk level colors are consistent throughout the app | Must | Standard | Given risk levels are displayed, When rendering, Then: Optimal Health = green, Stable Solidity = blue, Medium Risk = amber, High Risk = orange, Very High Risk = red |

### 4.4 Trend Visualization

| ID | Requirement | Priority | Tier | Conditions of Satisfaction |
|---|---|---|---|---|
| FR-24 | 12-week trend chart displays weekly scores as a line graph with color-coded risk level bands as horizontal regions | Should | Standard | Given the user has 8 weeks of data, When the trend chart renders, Then 8 data points are plotted on a line graph with horizontal bands at 0-9 (green), 10-19 (blue), 20-29 (amber), 30-39 (orange), 40-49 (red) |
| FR-25 | Tapping a data point on the trend chart shows the weekly breakdown (7 daily scores) | Could | Standard | Given the user taps week 6 on the chart, When the detail popover appears, Then it shows Mon-Sun scores and which items were triggered each day |
| FR-26 | Trend chart displays alongside FASTER Scale stage history for visual correlation | Should | Standard | Given the user has both LBI and FASTER data, When the correlation view renders, Then LBI weekly trend and FASTER stage timeline are shown on aligned time axes |

### 4.5 Profile Management

| ID | Requirement | Priority | Tier | Conditions of Satisfaction |
|---|---|---|---|---|
| FR-27 | User can access LBI settings to view and edit all indicators across all dimensions | Must | Standard | Given the user navigates to LBI settings, When the indicator list renders, Then all dimensions and their indicators are displayed in an editable list |
| FR-28 | User can add, edit, or remove individual indicators within a dimension (maintaining 0-5 per dimension) | Must | Standard | Given the user edits the Physical Health dimension, When they add a 4th indicator, Then it is saved and available for critical-7 selection |
| FR-29 | User can change their critical-7 selection at any time | Must | Standard | Given the user navigates to critical item selection, When they deselect one item and select a different one (maintaining exactly 7), Then the new selection takes effect for the next daily check-in |
| FR-30 | When the user changes their critical-7 selection, the system creates a new profile version; historical daily entries reference the profile version active when they were recorded | Must | Standard | Given the user changes critical items on April 15, When viewing April 14's check-in, Then the items shown match the previous selection, and April 15 onward uses the new selection |

### 4.6 Integration

| ID | Requirement | Priority | Tier | Conditions of Satisfaction |
|---|---|---|---|---|
| FR-31 | LBI weekly score contributes to the Recovery Health Score calculation as a weighted component | Should | Standard | Given the Recovery Health Score formula, When LBI data is available, Then the LBI component is calculated as: (49 - weeklyScore) / 49 * 100, normalized and weighted per the RHS specification |
| FR-32 | Accountability partner sharing includes LBI weekly scores and risk levels (not individual item text) | Should | Standard | Given sharing is enabled, When the partner views shared data, Then they see weekly scores, risk levels, and trend direction -- but not the specific behavioral indicator text |
| FR-33 | LBI check-in appears in the Today view's activity feed when completed | Must | Standard | Given the user completes today's LBI check-in, When the Today view refreshes, Then a card shows "Life Balance: X/7 -- [Risk Level Context]" |

---

## 5. Non-Functional Requirements

### 5.1 Performance

| ID | Requirement | Target |
|---|---|---|
| NFR-01 | Daily check-in screen load time | < 500ms on iPhone 13 or newer |
| NFR-02 | Daily check-in save time | < 200ms |
| NFR-03 | Weekly score calculation time | < 100ms |
| NFR-04 | Trend chart render time (12 weeks of data) | < 1 second |
| NFR-05 | Setup flow dimension transition | < 300ms animation |
| NFR-06 | Storage per year of daily entries | < 500KB per user |

### 5.2 Security and Privacy

| ID | Requirement | Target |
|---|---|---|
| NFR-07 | All PCI indicator text is stored locally in SwiftData only; never transmitted without explicit user action | Enforced by architecture (no API sync in scope) |
| NFR-08 | Accountability sharing shares scores and risk levels only, never indicator text | Enforced by sharing data model |
| NFR-09 | Biometric lock (if enabled) protects PCI data alongside all other app data | Inherited from app-level biometric gate |
| NFR-10 | PCI data included in full data export (DSR compliance) | Included in existing data export pipeline |

### 5.3 Usability

| ID | Requirement | Target |
|---|---|---|
| NFR-11 | Daily check-in completes in under 60 seconds (7 binary toggles + save) | Measured by median completion time |
| NFR-12 | Setup flow completable in 3 or fewer sessions totaling under 30 minutes | User testing validation |
| NFR-13 | All text meets WCAG 2.1 AA contrast ratios | Automated accessibility audit |
| NFR-14 | VoiceOver fully supports setup flow, daily check-in, and trend chart | Manual accessibility testing |
| NFR-15 | Dynamic Type support for all PCI screens | Tested at all system text sizes |

### 5.4 Reliability

| ID | Requirement | Target |
|---|---|---|
| NFR-16 | No data loss if app is terminated during setup (progress saved after each dimension) | Tested via force-quit during setup |
| NFR-17 | No data loss if app is terminated during daily check-in (draft auto-saved) | Tested via force-quit during check-in |
| NFR-18 | Missed-day detection correctly handles timezone changes, DST transitions, and multi-day gaps | Unit tested with edge cases |
| NFR-19 | Profile version history is never deleted; indicator edits create new versions | Enforced by data model constraints |

### 5.5 Compatibility

| ID | Requirement | Target |
|---|---|---|
| NFR-20 | iOS 17.0+ (matching app minimum deployment target) | Build and runtime tested |
| NFR-21 | iPhone SE (3rd gen) through iPhone 16 Pro Max screen sizes | Adaptive layout tested |
| NFR-22 | iPad compatibility (if app supports iPad) | Layout scales appropriately |

---

## 6. Technical Considerations

### 6.1 Architecture Overview

The PCI feature follows the existing app architecture: MVVM with SwiftData persistence, `@Observable` view models, and integration with the `ServiceContainer` singleton.

```
Views (SwiftUI)
  |
  v
ViewModels (@Observable)
  |
  v
Repositories (SwiftData)
  |
  v
Models (@Model)
```

Key architectural decisions:
- **Local-first**: All PCI data persists in SwiftData. No API endpoints in scope.
- **Profile versioning**: Indicator edits create a new `PCIProfileVersion` record; daily entries reference the version active when recorded.
- **Computed weekly scores**: Weekly totals can be computed on demand from daily entries or cached for performance.
- **Feature flag**: PCI feature gated behind `pci_enabled` feature flag with tier-based rollout.

### 6.2 Data Model (SwiftData)

```swift
// MARK: - PCI Profile

@Model
final class RRPCIProfile {
    var id: UUID
    var userId: UUID
    var isActive: Bool          // Only one active profile per user
    var createdAt: Date
    var modifiedAt: Date
    var needsSync: Bool
    
    @Relationship(deleteRule: .cascade)
    var versions: [RRPCIProfileVersion]?
    
    init(userId: UUID) {
        self.id = UUID()
        self.userId = userId
        self.isActive = true
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.needsSync = true
    }
}

// MARK: - PCI Profile Version (immutable snapshot of indicators + critical selection)

@Model
final class RRPCIProfileVersion {
    var id: UUID
    var profile: RRPCIProfile?
    var versionNumber: Int
    var effectiveFrom: Date     // When this version became active
    var dimensionsJSON: String  // JSON-encoded [PCIDimension] array
    var criticalItemsJSON: String // JSON-encoded [PCICriticalItem] array (exactly 7)
    var createdAt: Date
    
    init(profile: RRPCIProfile, versionNumber: Int, dimensions: [PCIDimension], criticalItems: [PCICriticalItem]) {
        self.id = UUID()
        self.profile = profile
        self.versionNumber = versionNumber
        self.effectiveFrom = Date()
        self.dimensionsJSON = (try? JSONEncoder().encode(dimensions))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        self.criticalItemsJSON = (try? JSONEncoder().encode(criticalItems))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        self.createdAt = Date()
    }
}

// MARK: - PCI Daily Entry

@Model
final class RRPCIDailyEntry {
    var id: UUID
    var userId: UUID
    var date: Date              // Calendar date (time component stripped)
    var profileVersionId: UUID  // References the active version when entry was created
    var scoresJSON: String      // JSON-encoded [String: Bool] mapping critical item ID to occurred
    var totalScore: Int         // 0-7 computed from scoresJSON
    var isMissedDay: Bool       // True if auto-scored due to missed check-in
    var createdAt: Date
    var modifiedAt: Date
    var needsSync: Bool
    
    init(userId: UUID, date: Date, profileVersionId: UUID) {
        self.id = UUID()
        self.userId = userId
        self.date = Calendar.current.startOfDay(for: date)
        self.profileVersionId = profileVersionId
        self.scoresJSON = "{}"
        self.totalScore = 0
        self.isMissedDay = false
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.needsSync = true
    }
}

// MARK: - Supporting Codable Types (stored as JSON in profile versions)

struct PCIDimension: Codable, Identifiable {
    var id: UUID
    var dimensionType: PCIDimensionType
    var indicators: [PCIIndicator]
}

struct PCIIndicator: Codable, Identifiable {
    var id: UUID
    var text: String            // User-entered text, max 200 chars
    var isPositive: Bool        // True only for Interests dimension indicators
}

struct PCICriticalItem: Codable, Identifiable {
    var id: UUID                // Matches the PCIIndicator.id it references
    var dimensionType: PCIDimensionType
    var displayText: String     // For Interests items: "Lack of [original text]"
    var originalText: String    // The user's original indicator text
    var sortOrder: Int          // 0-6 display order
}

enum PCIDimensionType: String, Codable, CaseIterable {
    case physicalHealth = "physical_health"
    case environment = "environment"
    case work = "work"
    case interests = "interests"
    case socialLife = "social_life"
    case familyAndSignificantOthers = "family_significant_others"
    case finances = "finances"
    case spiritualLife = "spiritual_life"
    case compulsiveBehaviors = "compulsive_behaviors"
    case recoveryPractice = "recovery_practice"
}

enum PCIRiskLevel: String, Codable {
    case optimalHealth = "optimal_health"        // 0-9
    case stableSolidity = "stable_solidity"      // 10-19
    case mediumRisk = "medium_risk"              // 20-29
    case highRisk = "high_risk"                  // 30-39
    case veryHighRisk = "very_high_risk"         // 40-49
    
    static func from(weeklyScore: Int) -> PCIRiskLevel {
        switch weeklyScore {
        case 0...9: return .optimalHealth
        case 10...19: return .stableSolidity
        case 20...29: return .mediumRisk
        case 30...39: return .highRisk
        default: return .veryHighRisk
        }
    }
}
```

### 6.3 Key Technical Decisions

1. **JSON-encoded arrays in SwiftData**: Follows the existing pattern used by `RRFASTEREntry.selectedIndicatorsJSON`. Indicators and critical items are stored as JSON strings within `@Model` classes.

2. **Profile versioning via immutable snapshots**: Each `RRPCIProfileVersion` is a complete snapshot of all dimensions and critical items at a point in time. Daily entries reference the version ID, ensuring historical entries always render with the indicators that were active when the entry was created.

3. **Missed-day detection**: On app launch and at the configured notification time, the system checks for any days between the last recorded entry and today that have no entry. Each gap day is backfilled with a missed-day entry (score = 7). This handles multi-day gaps, timezone changes, and DST transitions by using `Calendar.current.startOfDay(for:)` for all date comparisons.

4. **Weekly calculation**: Weeks run Monday through Sunday (ISO 8601). The weekly score is the sum of 7 daily scores. If fewer than 7 days exist in a partial week (e.g., user set up PCI on a Wednesday), only the existing days contribute (missed days before setup are not penalized).

### 6.4 Integration Points

| Integration | Mechanism | Scope |
|---|---|---|
| Recovery Health Score | `RRPCIDailyEntry.totalScore` contributes to RHS daily calculation | Should (S4) |
| FASTER Scale correlation | Query both `RRFASTEREntry` and `RRPCIDailyEntry` by date range for trend overlay | Should (S8) |
| Today view activity feed | `RRPCIDailyEntry` rendered as a card in the Today feed | Must (FR-33) |
| Accountability sharing | Weekly score + risk level shared via existing sharing infrastructure | Should (S7) |
| Notifications | Leverage existing `PlanNotificationScheduler` for evening reminders | Should (S3) |
| Feature flags | `pci_enabled` flag gates feature visibility | Must (architectural) |

### 6.5 Infrastructure

No additional infrastructure required. All data is local (SwiftData). The feature flag is evaluated from the existing `RRFeatureFlag` model. Push notifications use the existing local notification scheduling system.

---

## 7. User Stories

### Epic: Life Balance Index (LBI)

---

### Story 1: LBI Psychoeducation Screen

**As a** recovering person opening the Life Balance Index for the first time,
**I want** to understand what the LBI is, why it matters, and what I will be asked to do during setup,
**So that** I am motivated to invest the time in defining my personal indicators and understand the value of daily tracking.

**Priority:** Should (S5)
**Story Points:** 3 (straightforward UI with static content; moderate design effort for layout)

**Conditions of Satisfaction:**

- Given I have never completed LBI setup, When I navigate to the LBI feature, Then an educational screen is displayed with: a title ("Life Balance Index"), a brief explanation of the tool's purpose (2-3 paragraphs), the "boulder" metaphor illustration, and an estimate of setup time ("about 15-20 minutes, and you can save and come back")
- Given the educational screen is displayed, When I tap "Get Started", Then the setup flow begins at Dimension 1
- Given the educational screen is displayed, When I tap the back/close button, Then I return to the previous screen without starting setup
- Given I have completed LBI setup, When I navigate to the LBI feature, Then the educational screen is not shown; I go directly to the daily check-in or dashboard

**INVEST Compliance:**
- Independent: No dependency on other stories
- Negotiable: Content and layout can be adjusted
- Valuable: Reduces setup abandonment by establishing motivation
- Estimable: Well-defined scope
- Small: Single screen with static content
- Testable: All CoS are demonstrable

---

### Story 2: LBI Setup -- Dimension-by-Dimension Indicator Entry

**As a** recovering person setting up my Life Balance Index,
**I want** to work through each life dimension one at a time with guidance and examples,
**So that** I can thoughtfully define the behavioral warning signs that are personally meaningful to me without feeling overwhelmed.

**Priority:** Must (M1, M2, M3, M9)
**Story Points:** 8 (complex multi-step flow with state persistence, dynamic form inputs, 10 dimension content sets)

**Conditions of Satisfaction:**

- Given I am in the setup flow, When a dimension is presented, Then I see: the dimension name, a description paragraph, a prompt question, 2-4 example behaviors, and 1-5 text input fields for my personal indicators
- Given I am entering indicators for Physical Health, When I type "Skipping gym for 3+ days" in the first field, Then the text is accepted and displayed
- Given I have entered 3 indicators for Physical Health, When I tap "Next", Then my 3 indicators are saved to SwiftData and the next dimension (Environment) is presented
- Given I am on dimension 4 of 10, When I tap "Next" without entering any indicators, Then dimension 4 is skipped (0 indicators saved) and dimension 5 is presented
- Given I have completed 6 of 10 dimensions, When I force-quit the app and reopen it, Then the setup resumes at dimension 7 with my indicators for dimensions 1-6 preserved
- Given I am on dimension 10, When I tap "Next" after entering indicators, Then the setup transitions to the critical-7 selection screen (Story 3)
- Given the Interests dimension (dimension 4) is displayed, When I see the description, Then it explains that this is the only positive category and examples are positive activities (e.g., "Reading, cooking, gardening")
- Given any dimension is displayed, When I view the progress indicator, Then it shows my position (e.g., "4 of 10") and a proportional progress bar

**INVEST Compliance:**
- Independent: Depends only on psychoeducation screen (optional)
- Negotiable: Number of example behaviors per dimension, input field count
- Valuable: Core setup functionality; without this, no PCI tracking is possible
- Estimable: 10 dimension screens with consistent template
- Small: Focused on dimension entry only; critical-7 selection is separate story
- Testable: Each CoS is demonstrable with specific inputs/outputs

---

### Story 3: LBI Setup -- Critical 7 Selection

**As a** recovering person who has defined indicators across my life dimensions,
**I want** to select the 7 most important warning signs from all my indicators for daily tracking,
**So that** my daily check-in focuses on the signals that matter most to my personal recovery.

**Priority:** Must (M3, M10)
**Story Points:** 5 (selection UI with constraint enforcement, positive-to-negative rephrasing logic, confirmation)

**Conditions of Satisfaction:**

- Given I have completed all 10 dimensions in setup, When the selection screen appears, Then all my entered indicators are listed, grouped by dimension, each with a selectable checkbox
- Given I am selecting critical items, When I select a 7th item, Then the counter shows "7 of 7 selected" and the "Done" button becomes enabled
- Given I have selected 7 items, When I try to select an 8th, Then the selection is prevented and a message explains "You can select exactly 7 items. Deselect one to choose a different item."
- Given I select "Reading for pleasure" from the Interests dimension, When it is confirmed as a critical item, Then it is automatically rephrased to "Lack of reading for pleasure" and the rephrased version is shown in the confirmation
- Given I have selected 7 items and tap "Done", When the confirmation screen appears, Then my 7 critical items are listed (with any Interests items showing the "Lack of..." version) and I can tap "Start Tracking" to complete setup
- Given I have selected fewer than 7 items, When I look at the "Done" button, Then it is disabled with a label showing how many more items I need to select

**INVEST Compliance:**
- Independent: Depends on Story 2 (dimension entry) which is a natural prerequisite
- Negotiable: Grouping method, display order, rephrasing approach
- Valuable: The 7-item reduction is what makes daily tracking sustainable
- Estimable: Clear UI and logic requirements
- Small: Focused on selection step only
- Testable: All CoS specify exact states and transitions

---

### Story 4: Daily LBI Check-In

**As a** recovering person with my 7 critical items defined,
**I want** to quickly review my day and toggle which warning behaviors occurred,
**So that** I maintain daily awareness of my life balance in under 60 seconds.

**Priority:** Must (M4, M5, FR-12 through FR-16)
**Story Points:** 5 (binary toggle list, score calculation, persistence, edit-existing logic)

**Conditions of Satisfaction:**

- Given I have completed LBI setup, When I open the daily check-in screen, Then my 7 critical items are displayed as a vertical list, each with a binary toggle defaulting to "off" (did not occur)
- Given the check-in screen is displayed, When I toggle "Skipping gym for 3+ days" to "on", Then the toggle animates with haptic feedback and the running score updates from "0/7" to "1/7"
- Given I have toggled 3 items to "on", When I tap "Save", Then a daily entry is persisted with date = today, totalScore = 3, and per-item boolean values
- Given I saved a check-in for today earlier, When I open the check-in screen again today, Then my previous toggle states are loaded and I can edit them
- Given I edit a previously saved check-in, When I toggle one item and tap "Save", Then the existing entry is updated (not duplicated) with the new score
- Given I open the check-in screen, When the screen has fully loaded, Then the load time is under 500ms

**INVEST Compliance:**
- Independent: Depends on completed setup (Story 2 + 3)
- Negotiable: Toggle visual design, score display format
- Valuable: Core daily interaction; the heart of the PCI experience
- Estimable: Well-defined interaction pattern
- Small: Focused exclusively on daily check-in; no weekly scoring or trends
- Testable: All CoS have specific measurable criteria

---

### Story 5: Missed Day Auto-Scoring

**As a** recovering person using the Life Balance Index,
**I want** missed days to automatically receive the maximum score,
**So that** the system reflects Carnes' principle that inability to track is itself evidence of imbalance, and my weekly scores remain accurate.

**Priority:** Must (M8)
**Story Points:** 5 (date gap detection, backfill logic, timezone/DST edge cases)

**Conditions of Satisfaction:**

- Given I did not check in on Monday, When I open the app on Tuesday, Then Monday is recorded as a missed day with totalScore = 7 and isMissedDay = true
- Given I did not check in for 3 consecutive days (Friday, Saturday, Sunday), When I open the app on Monday, Then all 3 days are recorded as missed with totalScore = 7 each
- Given a day is recorded as missed, When I view that day's entry in history, Then it is visually distinct (e.g., "Missed - Auto-scored 7") and cannot be edited retroactively
- Given the user's timezone changes due to travel, When missed-day detection runs, Then it uses the device's current calendar and timezone for date boundary calculations
- Given the user set up PCI on Wednesday, When the first weekly total is calculated for that partial week, Then only Wednesday through Sunday are included (Monday and Tuesday before setup are not counted as missed)
- Given DST transition occurs (clocks spring forward or fall back), When missed-day detection runs, Then it correctly identifies one calendar day per 24-hour period using `Calendar.current.startOfDay`

**INVEST Compliance:**
- Independent: Depends only on having an active PCI profile
- Negotiable: Whether missed days can be retroactively filled in
- Valuable: Maintains data integrity and Carnes' accountability principle
- Estimable: Clear logic with known edge cases
- Small: Focused on gap detection and backfill
- Testable: Each edge case is a specific scenario

---

### Story 6: Weekly Score and Risk Level

**As a** recovering person tracking my Life Balance Index,
**I want** to see my weekly total score and understand what risk level it represents,
**So that** I can assess my overall life balance trajectory and take action when needed.

**Priority:** Must (M6, M7)
**Story Points:** 3 (computation from existing daily data, risk level mapping, summary card UI)

**Conditions of Satisfaction:**

- Given I have 7 daily entries for the current week (Mon-Sun), When the weekly summary is calculated, Then the total score equals the sum of 7 daily totalScore values (range: 0-49)
- Given a weekly total of 14, When the risk level is displayed, Then "Stable Solidity" is shown with a blue color indicator and the description: "Resilient. Recognizes human limits..."
- Given a weekly total of 35, When the risk level is displayed, Then "High Risk" is shown with an orange color indicator and the description: "Living in extremes..."
- Given the current week is incomplete (e.g., it is Wednesday), When the partial weekly score is displayed, Then it shows the running total with a label like "15 so far this week (3 of 7 days)"
- Given last week's score was 12 and this week's is 18, When the summary card renders, Then a week-over-week indicator shows "+6" with an upward arrow in amber

**INVEST Compliance:**
- Independent: Depends on daily entries existing (Story 4/5)
- Negotiable: Summary card design, description truncation
- Valuable: Transforms raw daily data into actionable risk awareness
- Estimable: Straightforward computation and display
- Small: Weekly score and card only; trend chart is separate
- Testable: All score-to-risk mappings are deterministic

---

### Story 7: 12-Week Trend Chart

**As a** recovering person who has been tracking my Life Balance Index for multiple weeks,
**I want** to see a visual trend of my weekly scores over time with color-coded risk bands,
**So that** I can recognize patterns of lifestyle erosion or improvement over the longer arc of my recovery.

**Priority:** Should (S1)
**Story Points:** 8 (custom Swift Charts implementation, risk level bands, interactive data points, responsive layout)

**Conditions of Satisfaction:**

- Given I have 8 weeks of completed data, When the trend chart renders, Then 8 data points are plotted on a line graph with the X-axis showing week labels and the Y-axis showing score (0-49)
- Given the chart is rendered, When I look at the background, Then horizontal color bands are visible: green (0-9), blue (10-19), amber (20-29), orange (30-39), red (40-49)
- Given the chart is rendered, When I tap a data point for week 6, Then a popover or callout shows: "Week 6: Score 22 (Medium Risk)" with option to see daily breakdown
- Given I have fewer than 2 weeks of data, When the trend chart area renders, Then a placeholder message is shown: "Keep tracking -- your trend will appear after 2 weeks"
- Given the chart is rendered on an iPhone SE screen, When I view it, Then the chart scales appropriately without clipping or overlapping labels

**INVEST Compliance:**
- Independent: Depends on having weekly data (Story 6)
- Negotiable: Chart library, interaction style, number of visible weeks
- Valuable: Visual pattern recognition is the primary benefit of multi-week tracking
- Estimable: Swift Charts API provides building blocks
- Small: Chart only; FASTER correlation is a separate story
- Testable: Data point count, band colors, and tap behavior are verifiable

---

### Story 8: LBI Profile Editing with Version History

**As a** recovering person whose recovery is progressing,
**I want** to update my indicators and critical-7 selection as my warning signs evolve,
**So that** my daily tracking remains relevant to my current recovery stage without losing the history of what I tracked before.

**Priority:** Must (M13, M14)
**Story Points:** 5 (edit flow, version creation, historical reference integrity)

**Conditions of Satisfaction:**

- Given I navigate to LBI settings, When I tap "Edit Indicators", Then I see all 10 dimensions with my current indicators in editable text fields
- Given I add a new indicator to the Finances dimension, When I tap "Save", Then a new profile version is created and the new indicator appears in my critical-7 selection pool
- Given I change my critical-7 selection (swap one item), When I save, Then a new profile version is created with the new selection effective from today
- Given I made a critical-7 change on April 15, When I view my April 14 daily entry, Then the old critical items are displayed (from the previous version), not the new ones
- Given I made a critical-7 change on April 15, When I do today's check-in (April 15), Then the new critical items are displayed
- Given I have 3 profile versions, When I view version history in settings, Then I can see when each version was created and what changed

**INVEST Compliance:**
- Independent: Depends on having a completed profile (Story 2+3)
- Negotiable: History display format, whether diff is shown between versions
- Valuable: Enables long-term tool relevance as recovery progresses
- Estimable: Clear version-creation logic
- Small: Editing and versioning only; no impact on chart rendering logic
- Testable: Version creation and historical reference are verifiable

---

### Story 9: LBI Integration with Today View

**As a** recovering person using the Today view as my daily recovery hub,
**I want** to see my LBI status and access the check-in from the Today view,
**So that** LBI is integrated into my existing daily routine rather than being a separate destination I might forget.

**Priority:** Must (M12, FR-19, FR-33)
**Story Points:** 3 (quick action card, completed entry display, navigation)

**Conditions of Satisfaction:**

- Given I have completed LBI setup and have not checked in today, When I view the Today screen, Then a "Life Balance Check-In" quick action card is visible in the activities section
- Given I tap the "Life Balance Check-In" quick action, When the check-in screen opens, Then I can complete my daily check-in (per Story 4)
- Given I have completed today's LBI check-in with a score of 2, When I view the Today screen, Then a card shows "Life Balance: 2/7" with a green indicator
- Given I have completed today's LBI check-in with a score of 6, When I view the Today screen, Then a card shows "Life Balance: 6/7" with an orange/red indicator suggesting elevated risk
- Given I have not yet set up LBI, When I view the Today screen, Then no LBI card appears (feature is not surfaced until setup is complete)

**INVEST Compliance:**
- Independent: Depends on setup completion and daily check-in (Stories 2-4)
- Negotiable: Card design, placement within Today view
- Valuable: Integrates LBI into the existing daily hub
- Estimable: Follows existing quick action card pattern
- Small: Card rendering and navigation only
- Testable: All states (not set up, not checked in, checked in) are verifiable

---

### Story 10: Evening Notification for LBI Check-In

**As a** recovering person who wants to track daily but might forget,
**I want** to receive an evening notification reminding me to complete my Life Balance check-in,
**So that** I maintain consistency and avoid the automatic score of 7 for missed days.

**Priority:** Should (S3)
**Story Points:** 3 (local notification scheduling, integration with existing notification system)

**Conditions of Satisfaction:**

- Given I have completed LBI setup and have notification permissions, When 9:00 PM local time arrives and I have not checked in today, Then a push notification is delivered: "Time for your daily Life Balance check-in"
- Given I have already checked in today, When 9:00 PM arrives, Then no LBI notification is sent
- Given I tap the LBI notification, When the app opens, Then I am navigated directly to the daily check-in screen
- Given I have notifications disabled at the system level, When 9:00 PM arrives, Then no notification attempt is made (no error, graceful degradation)
- Given I navigate to LBI settings, When I view notification preferences, Then I can toggle the LBI reminder on/off and change the reminder time

**INVEST Compliance:**
- Independent: Uses existing notification infrastructure
- Negotiable: Default time, notification text, customizable schedule
- Valuable: Directly supports adherence, the primary success metric
- Estimable: Follows existing `PlanNotificationScheduler` pattern
- Small: Notification scheduling only
- Testable: Notification delivery and suppression are verifiable

---

### Story 11: FASTER Scale Correlation Display

**As a** recovering person tracking both Life Balance Index and FASTER Scale,
**I want** to see my LBI trend alongside my FASTER Scale history on a shared timeline,
**So that** I can see how rising LBI scores preceded FASTER Scale escalation and learn to intervene earlier.

**Priority:** Should (S8)
**Story Points:** 5 (dual-axis chart, data alignment, date range synchronization)

**Conditions of Satisfaction:**

- Given I have 4+ weeks of LBI data and 4+ FASTER entries, When I view the correlation display, Then the LBI weekly trend line and FASTER stage markers are shown on time-aligned axes
- Given the correlation display is rendered, When I observe a week where LBI scored 28 (Medium Risk) followed by a FASTER check-in at the Ticking (T) stage the next week, Then the visual alignment makes the upstream-downstream relationship evident
- Given I have LBI data but no FASTER data, When the correlation view renders, Then only the LBI trend is shown with a message: "Add FASTER Scale check-ins to see how life balance relates to relapse risk"
- Given the display is rendered, When I tap a FASTER stage marker, Then a callout shows the FASTER entry date and assessed stage

**INVEST Compliance:**
- Independent: Uses existing FASTER data; no FASTER code changes needed
- Negotiable: Chart type, axis configuration, annotation style
- Valuable: Demonstrates the unique upstream-downstream insight that justifies PCI
- Estimable: Moderate charting complexity
- Small: Read-only visualization; no data mutation
- Testable: Data alignment and marker display are verifiable

---

### Story 12: Accountability Partner LBI Sharing

**As a** recovering person who shares data with my accountability partner,
**I want** my Life Balance Index weekly scores and risk levels to be included in shared data,
**So that** my accountability partner can see lifestyle erosion trends and initiate supportive conversations before I reach crisis.

**Priority:** Should (S7)
**Story Points:** 3 (extend existing sharing data model, privacy controls)

**Conditions of Satisfaction:**

- Given I have sharing enabled with an accountability partner, When I view sharing settings for LBI, Then I can toggle LBI sharing on/off independently of other shared data
- Given LBI sharing is enabled, When my accountability partner views my shared data, Then they see: weekly scores, risk levels, and trend direction (up/down/stable) -- but NOT my specific indicator text
- Given LBI sharing is enabled and my weekly score is 32 (High Risk), When my partner views the data, Then the risk level is prominently displayed with a recommendation to check in with me
- Given LBI sharing is disabled, When my partner views shared data, Then no LBI information is visible

**INVEST Compliance:**
- Independent: Extends existing sharing infrastructure
- Negotiable: What data points are shared, visual treatment
- Valuable: Accountability relationships are a core app value proposition
- Estimable: Follows existing sharing patterns
- Small: Data pipeline extension only
- Testable: Shared vs. not-shared states are verifiable

---

### Story 13: Recovery Health Score Integration

**As a** recovering person who uses the Recovery Health Score as my overall recovery metric,
**I want** my Life Balance Index weekly performance to contribute to my Recovery Health Score,
**So that** my daily health score reflects my lifestyle balance alongside other recovery activities.

**Priority:** Should (S4)
**Story Points:** 3 (score formula integration, weight configuration)

**Conditions of Satisfaction:**

- Given the Recovery Health Score formula includes an LBI component, When my weekly LBI score is 7 (Optimal Health), Then the LBI contribution to RHS is calculated as (49 - 7) / 49 * 100 = 85.7%, weighted per the RHS specification
- Given my weekly LBI score is 42 (Very High Risk), When the RHS is calculated, Then the LBI contribution is (49 - 42) / 49 * 100 = 14.3%
- Given I have not set up LBI, When the RHS is calculated, Then the LBI component is excluded from the formula (not penalized for not using the feature)
- Given I have a partial week of LBI data, When the RHS is calculated, Then the LBI component uses the running weekly average extrapolated to a full-week estimate

**INVEST Compliance:**
- Independent: RHS formula is modified, but LBI data source is independent
- Negotiable: Weight, formula, handling of partial weeks
- Valuable: Connects LBI to the primary app-wide metric
- Estimable: Mathematical formula with clear inputs/outputs
- Small: Formula change only
- Testable: Deterministic calculation with known inputs/outputs

---

### Story Point Summary

| Story | Title | Points | Priority | Sprint |
|---|---|---|---|---|
| S1 | Psychoeducation Screen | 3 | Should | 1 |
| S2 | Dimension-by-Dimension Setup | 8 | Must | 1 |
| S3 | Critical 7 Selection | 5 | Must | 1 |
| S4 | Daily Check-In | 5 | Must | 2 |
| S5 | Missed Day Auto-Scoring | 5 | Must | 2 |
| S6 | Weekly Score and Risk Level | 3 | Must | 2 |
| S7 | 12-Week Trend Chart | 8 | Should | 3 |
| S8 | Profile Editing with Version History | 5 | Must | 3 |
| S9 | Today View Integration | 3 | Must | 2 |
| S10 | Evening Notification | 3 | Should | 3 |
| S11 | FASTER Scale Correlation | 5 | Should | 3 |
| S12 | Accountability Sharing | 3 | Should | 4 |
| S13 | Recovery Health Score Integration | 3 | Should | 4 |
| **Total** | | **59** | | |

---

## 8. Feature Comparison Matrix

### Standard vs Premium+ Tier

| Capability | Standard (Self-Directed) | Premium+ (AI-Guided) |
|---|---|---|
| **Setup** | Self-directed with written guidance, examples, and prompt questions per dimension | AI conversational agent guides user through indicator definition with probing questions and suggested phrasing |
| **Dimensions** | 10 life dimensions with Carnes' descriptions | Same 10 dimensions with AI-generated follow-up questions personalized to user's recovery context |
| **Indicator Entry** | Free-text fields (1-5 per dimension) | AI suggests indicators based on conversation; user confirms/edits |
| **Critical 7 Selection** | Manual selection from entered indicators | AI recommends critical items based on user's recovery history and expressed concerns |
| **Daily Check-In** | 7 binary toggles, save | Same + AI provides a brief personalized reflection based on today's score and recent trend |
| **Weekly Summary** | Score, risk level, week-over-week change | Same + AI-generated insight ("Your Finances indicators have been triggering consistently -- consider reviewing your budget this weekend") |
| **Trend Chart** | 12-week line chart with risk bands | Same + AI pattern annotations ("Your score tends to rise on weeks with fewer meeting check-ins") |
| **FASTER Correlation** | Side-by-side timeline display | Same + AI narrative explaining observed correlations |
| **Notifications** | Evening reminder | Same + adaptive timing based on when user typically checks in |
| **Profile Editing** | Manual indicator and critical-7 editing | AI suggests indicator revisions based on tracking patterns |

### Feature Availability by Sprint

| Capability | Sprint 1 | Sprint 2 | Sprint 3 | Sprint 4 |
|---|---|---|---|---|
| Psychoeducation screen | Standard | | | |
| Setup flow (dimensions + critical 7) | Standard | | | |
| Daily check-in | | Standard | | |
| Missed day auto-scoring | | Standard | | |
| Weekly score + risk level | | Standard | | |
| Today view integration | | Standard | | |
| 12-week trend chart | | | Standard | |
| Profile editing + versioning | | | Standard | |
| Evening notification | | | Standard | |
| FASTER correlation | | | Standard | |
| Accountability sharing | | | | Standard |
| Recovery Health Score integration | | | | Standard |
| AI-guided setup | | | | Premium+ (stub) |

---

## 9. Implementation Roadmap

### Sprint 1: Foundation -- Setup Flow (Ready)

**Sprint Goal:** Users can define their personal indicators across 10 life dimensions and select their 7 critical items.

**Stories:**
- S1: Psychoeducation Screen (3 pts) -- Should
- S2: Dimension-by-Dimension Setup (8 pts) -- Must
- S3: Critical 7 Selection (5 pts) -- Must

**Total Points:** 16

**Work Breakdown Structure:**

| Task | Story | Estimate |
|---|---|---|
| Create `RRPCIProfile`, `RRPCIProfileVersion`, supporting Codable types | S2 | 3h |
| Create `PCIDimensionType` enum with all 10 dimensions | S2 | 1h |
| Create dimension content data (descriptions, prompt questions, examples) for all 10 dimensions | S2 | 3h |
| Build `PCISetupViewModel` with step tracking, progress persistence, validation | S2 | 4h |
| Build `PCIDimensionEntryView` (single dimension screen with guidance text + input fields) | S2 | 4h |
| Build `PCISetupFlowView` (orchestrates dimension-by-dimension progression) | S2 | 3h |
| Implement setup progress save/resume via SwiftData | S2 | 2h |
| Build `PCICriticalSelectionView` (multi-select with 7-item constraint) | S3 | 3h |
| Implement Interests positive-to-negative rephrasing logic | S3 | 1h |
| Build setup confirmation screen | S3 | 1h |
| Build psychoeducation screen with LBI explanation content | S1 | 2h |
| Create `pci_enabled` feature flag seed data | All | 1h |
| Unit tests: profile creation, version snapshots, indicator validation | S2, S3 | 3h |
| Unit tests: critical-7 constraint enforcement, Interests rephrasing | S3 | 2h |
| UI tests: setup flow navigation, progress persistence | S2 | 2h |

**Dependencies:** None (greenfield feature)

**Definition of Ready:** Met. All stories have CoS, data model is specified, dimension content is defined in research document.

---

### Sprint 2: Core Tracking -- Daily Check-In + Scoring (Ready)

**Sprint Goal:** Users can complete daily binary check-ins, see their daily and weekly scores with risk levels, and the LBI appears in the Today view.

**Stories:**
- S4: Daily Check-In (5 pts) -- Must
- S5: Missed Day Auto-Scoring (5 pts) -- Must
- S6: Weekly Score and Risk Level (3 pts) -- Must
- S9: Today View Integration (3 pts) -- Must

**Total Points:** 16

**Work Breakdown Structure:**

| Task | Story | Estimate |
|---|---|---|
| Create `RRPCIDailyEntry` model with SwiftData persistence | S4 | 2h |
| Build `PCICheckInViewModel` (load active profile, toggle state, save/update) | S4 | 3h |
| Build `PCICheckInView` (7 toggle items, running score, save button) | S4 | 3h |
| Implement duplicate-day detection (edit vs. create logic) | S4 | 2h |
| Implement haptic feedback on toggle | S4 | 0.5h |
| Build missed-day detection service (runs on app launch and foreground) | S5 | 3h |
| Implement backfill logic for single and multi-day gaps | S5 | 2h |
| Unit tests: timezone edge cases, DST transitions, partial-week handling | S5 | 3h |
| Build `PCIWeeklyScoreCalculator` (sum daily scores, map to risk level) | S6 | 2h |
| Build `PCIWeeklySummaryCard` (score, risk level, color, description, delta) | S6 | 2h |
| Implement `PCIRiskLevel` enum with colors, descriptions, and score mapping | S6 | 1h |
| Add LBI quick action card to Today view | S9 | 2h |
| Add LBI completed entry card to Today view | S9 | 2h |
| Unit tests: weekly calculation, risk level mapping, edge cases | S6 | 2h |
| Unit tests: check-in save, edit, duplicate prevention | S4 | 2h |
| Integration tests: setup -> check-in -> weekly score flow | All | 2h |

**Dependencies:** Sprint 1 (setup flow complete; active profile exists)

**Definition of Ready:** Met. All stories have CoS, data model is specified.

---

### Sprint 3: Insights -- Trend Visualization + Profile Management (Stub)

**Sprint Goal:** Users can see multi-week trends, edit their profile, receive evening reminders, and view LBI alongside FASTER data.

**Stories:**
- S7: 12-Week Trend Chart (8 pts) -- Should
- S8: Profile Editing with Version History (5 pts) -- Must
- S10: Evening Notification (3 pts) -- Should
- S11: FASTER Scale Correlation (5 pts) -- Should

**Total Points:** 21

**Key Tasks (stubbed):**
- Implement Swift Charts line graph with risk level background bands
- Build profile editing flow with version creation on save
- Integrate with `PlanNotificationScheduler` for evening LBI reminders
- Build dual-axis correlation view with FASTER stage markers
- Implement version history display in settings
- Comprehensive chart rendering tests across device sizes

**Dependencies:** Sprint 2 (daily entries and weekly scores exist)

---

### Sprint 4: Integration + Premium+ Foundation (Stub)

**Sprint Goal:** LBI data flows into Recovery Health Score and accountability sharing. Premium+ AI-guided setup is stubbed for future implementation.

**Stories:**
- S12: Accountability Sharing (3 pts) -- Should
- S13: Recovery Health Score Integration (3 pts) -- Should
- Premium+ AI-guided setup (stub/spike) -- Could

**Total Points:** 6 + spike

**Key Tasks (stubbed):**
- Extend sharing data model to include LBI weekly scores and risk levels
- Modify Recovery Health Score formula to include LBI component
- Create Premium+ setup flow entry point (gated by tier flag)
- Spike: AI agent prompt design for indicator definition conversation
- End-to-end testing of full LBI lifecycle

**Dependencies:** Sprint 3 (trend chart and profile editing complete)

---

### Dependency Map

```
Sprint 1                    Sprint 2                    Sprint 3                    Sprint 4
---------                   ---------                   ---------                   ---------
S1 Psychoeducation -------> (informational only)
S2 Dimension Setup -------> S4 Daily Check-In --------> S7 Trend Chart
S3 Critical 7 Selection --> S5 Missed Day Scoring ----> S8 Profile Editing
                            S6 Weekly Score ----------> S10 Notification
                            S9 Today Integration -----> S11 FASTER Correlation ---> S12 Sharing
                                                                                    S13 RHS Integration
```

**Cross-Feature Dependencies:**
- Today view (existing): S9 adds a card to the existing Today view layout
- Recovery Health Score (existing): S13 modifies the RHS calculation formula
- Accountability sharing (existing): S12 extends the existing sharing data pipeline
- FASTER Scale (existing): S11 reads existing FASTER entries (no FASTER code changes)
- Notification system (existing): S10 uses `PlanNotificationScheduler`
- Feature flags (existing): PCI gated behind `pci_enabled` flag

---

## 10. JIRA Readiness Checklist

### Stories Ready for Sprint 1 Refinement

**S1: Psychoeducation Screen**
- [x] Clear JIRA summary: "Display Life Balance Index educational screen on first access"
- [x] Description with user story format
- [x] Conditions of Satisfaction from user perspective (4 CoS)
- [ ] Mock-ups/design references attached
- [x] Parent relationship: Story > LBI Feature > Recovery Tools Epic
- [x] MoSCoW priority: Should
- [ ] Investment Driver identified
- [ ] Work Breakdown Structure completed by engineering
- [ ] Dependencies identified and linked (none)
- [x] Story points assigned: 3
- [x] Does not exceed half team velocity

**S2: Dimension-by-Dimension Setup**
- [x] Clear JIRA summary: "Build dimension-by-dimension indicator entry flow with progress persistence"
- [x] Description with user story format
- [x] Conditions of Satisfaction from user perspective (8 CoS)
- [ ] Mock-ups/design references attached
- [x] Parent relationship: Story > LBI Feature > Recovery Tools Epic
- [x] MoSCoW priority: Must
- [ ] Investment Driver identified
- [ ] Work Breakdown Structure completed by engineering
- [ ] Dependencies identified and linked (none)
- [x] Story points assigned: 8
- [ ] Does not exceed half team velocity (flag: 8 points may need splitting depending on team velocity)

**S3: Critical 7 Selection**
- [x] Clear JIRA summary: "Build critical-7 item selection with constraint enforcement and Interests rephrasing"
- [x] Description with user story format
- [x] Conditions of Satisfaction from user perspective (6 CoS)
- [ ] Mock-ups/design references attached
- [x] Parent relationship: Story > LBI Feature > Recovery Tools Epic
- [x] MoSCoW priority: Must
- [ ] Investment Driver identified
- [ ] Work Breakdown Structure completed by engineering
- [x] Dependencies identified and linked: blocked by S2
- [x] Story points assigned: 5
- [x] Does not exceed half team velocity

### Stories Ready for Sprint 2 Refinement

**S4: Daily Check-In**
- [x] Clear JIRA summary: "Build daily LBI check-in with binary toggles, scoring, and persistence"
- [x] Description with user story format
- [x] Conditions of Satisfaction from user perspective (6 CoS)
- [ ] Mock-ups/design references attached
- [x] Parent relationship: Story > LBI Feature > Recovery Tools Epic
- [x] MoSCoW priority: Must
- [ ] Investment Driver identified
- [ ] Dependencies identified: blocked by S2 + S3

**S5: Missed Day Auto-Scoring**
- [x] Clear JIRA summary: "Implement missed-day detection and automatic maximum score backfill"
- [x] Description with user story format
- [x] Conditions of Satisfaction from user perspective (6 CoS)
- [x] Parent relationship: Story > LBI Feature > Recovery Tools Epic
- [x] MoSCoW priority: Must

**S6: Weekly Score and Risk Level**
- [x] Clear JIRA summary: "Calculate weekly LBI score and display risk level with summary card"
- [x] Description with user story format
- [x] Conditions of Satisfaction from user perspective (5 CoS)
- [x] Parent relationship: Story > LBI Feature > Recovery Tools Epic
- [x] MoSCoW priority: Must

**S9: Today View Integration**
- [x] Clear JIRA summary: "Add Life Balance Index card to Today view with check-in access"
- [x] Description with user story format
- [x] Conditions of Satisfaction from user perspective (5 CoS)
- [x] Parent relationship: Story > LBI Feature > Recovery Tools Epic
- [x] MoSCoW priority: Must

---

## 11. Open Questions and Risks

### Open Questions

| # | Question | Impact | Owner | Status |
|---|---|---|---|---|
| OQ-1 | Should users be able to retroactively fill in a missed day (override the auto-7)? Carnes' text implies no, but user compassion principle suggests allowing correction with a warning. | Affects FR-17 CoS | Product | Open |
| OQ-2 | What weight should LBI carry in the Recovery Health Score formula? Current proposal is equal weight with other components, but LBI may warrant higher weight given its upstream position. | Affects S13 implementation | Product | Open |
| OQ-3 | Should the 12-week charting cycle be enforced (reset chart after 12 weeks) or should the chart be a rolling window? Rolling window provides continuity; fixed cycle matches Carnes' original. | Affects S7 implementation | Product | Open -- see Decision D7 |
| OQ-4 | When a user changes their critical-7 selection mid-week, how is the weekly score calculated? Options: (a) split week uses old items for days before change and new items after, (b) entire week uses whichever version was active for more days. | Affects S8 and S6 interaction | Engineering | Open |
| OQ-5 | Should the missed-day notification include the penalty warning ("If you don't check in, today will be scored 7/7")? This could be motivating or anxiety-inducing depending on the user. | Affects S10 notification text | Product + UX | Open |

### Risks

| # | Risk | Probability | Impact | Mitigation | Owner |
|---|---|---|---|---|---|
| R-1 | Setup abandonment: Users start defining indicators but never finish all 10 dimensions | High | High | Progressive setup with save/resume, progress bar, "you can skip dimensions" messaging, psychoeducation to establish motivation | Product + Engineering |
| R-2 | Indicator quality: Users define vague indicators ("feeling bad") that are not actionable | Medium | Medium | Provide Carnes' prompt questions and specific examples; consider Premium+ AI guidance for indicator quality | Product |
| R-3 | Scoring anxiety: The missed-day = 7 rule may feel punitive to users who miss a day due to legitimate reasons (travel, illness) | Medium | Medium | Frame the rule compassionately during onboarding; consider OQ-1 (retroactive override); emphasize that a single high day is information, not judgment | UX + Product |
| R-4 | Feature discovery: Users may not know the LBI feature exists or understand why they should use it | Medium | Medium | Today view integration (S9), onboarding prompt after 30 days of app use, recommendation when FASTER score worsens | Product |
| R-5 | Data model rigidity: If the 10 fixed dimensions prove insufficient, there is no mechanism for user-created custom dimensions | Low | Low | Monitor user feedback; custom dimensions excluded from V1 (W5) but can be added in future version | Product |
| R-6 | Trend chart performance: 365+ daily entries with weekly calculations could cause lag | Low | Low | Indexed SwiftData queries, lazy loading, pre-computed weekly summaries | Engineering |

### Assumptions to Validate

1. Users in SA/Celebrate Recovery are familiar with the PCI concept (if not, psychoeducation is critical path, not nice-to-have)
2. 10 dimensions (consolidated from Carnes' 12) provides sufficient life coverage
3. Binary scoring is preferred over intensity scales by the target user population
4. The "Life Balance Index" name resonates with users who may or may not know the "Personal Craziness Index" name

---

## 12. Design Decisions Log

### Decision D1: Naming

**Options Considered:**
1. "Personal Craziness Index (PCI)" -- Original Carnes name; immediate recognition for clinically-engaged users
2. "Life Balance Index (LBI)" -- Neutral, professional, no licensing risk
3. "Personal Warning Index (PWI)" -- Already identified in strategic PRD as licensing fallback

**Chosen:** Option 2 -- "Life Balance Index (LBI)"

**Rationale:** The word "craziness" carries stigma that conflicts with the app's compassion-first philosophy ("A relapse is not a failure"). Additionally, the original name is closely associated with Carnes' published worksheets and carries potential licensing risk if used commercially without permission from Carnes' estate or IITAP. "Life Balance Index" communicates the tool's purpose clearly, feels approachable, and is fully original for trademark purposes. The subtitle "Inspired by Patrick Carnes' Personal Craziness Index" can appear in the psychoeducation screen to give proper attribution and help clinically-aware users recognize the tool. "Personal Warning Index" was rejected as overly clinical and potentially anxiety-inducing.

---

### Decision D2: Number of Dimensions

**Options Considered:**
1. Keep all 12 original Carnes dimensions
2. Consolidate to 10 dimensions by merging Transportation into Environment and merging Healthy Relationships into Family & Significant Others

**Chosen:** Option 2 -- 10 dimensions

**Rationale:** Transportation as a standalone dimension is the most commonly questioned category in the PCI literature. Carnes uses transportation habits as a proxy for overall lifestyle chaos, but for mobile-native users (many of whom use ride-sharing or public transit), a dedicated Transportation dimension adds cognitive overhead without proportional value. Its core indicators (reckless driving, neglected vehicle maintenance) can be captured under the broader "Environment" dimension, which already covers lifestyle order and maintenance. Similarly, "Healthy Relationships" and "Family & Significant Others" share significant overlap in practice -- both assess relational health, honesty, and boundary maintenance. Merging them reduces the setup burden from 12 to 10 dimensions (saving approximately 5 minutes of setup time) while preserving complete life-domain coverage. The 10 dimensions are:

1. Physical Health
2. Environment (absorbs Transportation indicators as examples)
3. Work
4. Interests (positive -- unique)
5. Social Life
6. Family, Relationships & Significant Others (absorbs Healthy Relationships)
7. Finances
8. Spiritual Life & Personal Reflection
9. Other Compulsive/Symptomatic Behaviors
10. Recovery Practice & Therapeutic Self-Care

---

### Decision D3: Items per Dimension

**Options Considered:**
1. Strict 3 per dimension (matches Carnes' worksheet layout)
2. Flexible 1-5 per dimension
3. Flexible 2-4 per dimension

**Chosen:** Option 2 -- Flexible 1-5 per dimension

**Rationale:** Some dimensions may have strong personal relevance to a user (e.g., Physical Health for someone managing chronic illness) while others may be less immediately relevant (e.g., Finances for a user whose finances are stable). Strict 3 forces users to invent indicators for dimensions where they may only have 1-2 genuine warning signs, producing low-quality indicators. A 1-5 range respects the user's self-knowledge while providing enough room for thorough self-assessment in high-priority dimensions. The minimum of 1 ensures engagement with each non-skipped dimension; the maximum of 5 prevents decision fatigue during critical-7 selection (5 dimensions * 5 indicators = 50 potential items is already a rich selection pool). Allowing 0 (via skip) accommodates dimensions that genuinely do not apply.

---

### Decision D4: Number of Critical Items

**Options Considered:**
1. Strict 7 (Carnes' original)
2. Flexible 5-10

**Chosen:** Option 1 -- Strict 7

**Rationale:** The number 7 is integral to the PCI scoring system (7 items * 7 days = 0-49 weekly range, mapped to 5 risk levels). Changing this number would require recalibrating the entire risk interpretation scale. More importantly, 7 is a well-researched limit for daily self-assessment -- enough to span multiple life dimensions without becoming burdensome. Fewer than 7 risks blind spots; more than 7 extends the daily check-in beyond the target 60-second window. The strictness also creates a valuable constraint that forces users to prioritize, which is itself a therapeutic exercise in identifying what matters most.

---

### Decision D5: Scoring Method

**Options Considered:**
1. Binary (0 or 1 per item) -- Carnes' original
2. Intensity scale (1-7 per item) -- Mantra of Hope adaptation
3. Intensity scale (0-10 per item) -- Augustine Recovery adaptation

**Chosen:** Option 1 -- Binary (0 or 1)

**Rationale:** Binary scoring is the core design choice that makes the PCI work as a daily practice. It asks one simple question per item: "Did this behavior occur today?" This simplicity enables the sub-60-second check-in target, which is critical for long-term adherence. Intensity scales introduce subjectivity (what is a 4 vs. a 5?), increase decision fatigue, extend check-in time, and fundamentally change the nature of the tool from a pattern-detection system to a self-rating system. The binary approach also produces cleaner trend data -- a rising weekly score unambiguously means more warning behaviors are occurring more frequently. Multiple clinical adaptations have tried intensity scales, but the original binary approach remains the most widely used and recommended in CSAT practice.

---

### Decision D6: Missed Day Rule

**Options Considered:**
1. Automatic score of 7 (Carnes' original) -- strict, no override
2. Automatic score of 7 with option to retroactively fill in (compassionate override)
3. Configurable penalty (user sets missed-day score from 0-7)
4. Gentle reminder only, no automatic scoring

**Chosen:** Option 1 -- Automatic score of 7, no override (with compassionate framing)

**Rationale:** The missed-day rule is not a punishment -- it is a diagnostic signal. Carnes explicitly states: "If you cannot even do a daily scoring, you are obviously out of balance." Allowing overrides undermines this principle and creates a loophole where users can backfill missed days with artificially low scores after the fact, defeating the purpose. However, the app's framing of this rule must be compassionate, not punitive. During psychoeducation, the rule is explained as: "If you miss a day, that day counts as 7/7. This isn't a punishment -- it's information. When life is so unmanageable that you can't spend 60 seconds checking in, that itself tells you something important about where you are." The missed-day entry is visually distinct and labeled "Missed" rather than displaying 7 identical toggled items. Open question OQ-1 remains open for user testing feedback.

---

### Decision D7: Tracking Period

**Options Considered:**
1. Fixed 12-week cycles (Carnes' original worksheet structure)
2. Rolling continuous (no cycle boundaries)
3. Rolling window with 12-week default view

**Chosen:** Option 3 -- Rolling continuous with 12-week default chart view

**Rationale:** Fixed 12-week cycles create an artificial boundary that disrupts trend continuity. A user whose score is rising in week 12 should not have their trend reset at week 13 -- that rising trend is precisely the signal they need to see. Rolling continuous tracking preserves the full historical record. The 12-week trend chart is a default view window (matching Carnes' original charting period) that can scroll to show earlier data. This gives users both the 12-week focused view Carnes intended and the long-term historical perspective that digital tools uniquely enable.

---

### Decision D8: Setup Flow

**Options Considered:**
1. All-at-once (single long form with all 12 dimensions)
2. Progressive, dimension-by-dimension (one dimension per screen, with save between)
3. Spread over first week (one dimension per day)

**Chosen:** Option 2 -- Progressive, dimension-by-dimension with save-and-resume

**Rationale:** All-at-once creates a daunting wall of input fields that will cause abandonment. Spreading over a full week delays the start of daily tracking by 7-10 days, during which the user receives no value from the feature. Dimension-by-dimension is the optimal balance: each screen is focused on one life area with guidance and examples, the user makes meaningful progress with each step, and the save-and-resume capability means the user can complete setup across 1-3 sessions without losing work. The progress bar (6/10, 7/10, etc.) provides momentum. Total setup time is estimated at 15-20 minutes for a thoughtful user, which can be split across multiple sittings.

---

### Decision D9: AI Assistance During Setup

**Options Considered:**
1. No AI assistance (self-directed only)
2. AI assistance available for all users
3. AI assistance as Premium+ tier feature

**Chosen:** Option 3 -- AI assistance as Premium+ tier feature (deferred to Sprint 4 stub)

**Rationale:** AI-guided indicator definition is a compelling value-add (the AI can ask probing questions like "When your physical health slips, what's the first thing you notice?" and help users phrase indicators in specific, observable terms). However, the Standard tier must be fully functional without AI, and the AI integration adds significant scope (prompt engineering, conversation flow, error handling, hallucination guards). Deferring AI to Premium+ tier and to Sprint 4 (as a spike/stub) preserves the 4-sprint delivery window while establishing the Premium+ tier differentiation. The Standard tier includes Carnes' own prompt questions and example behaviors, which provide substantial guidance without AI.

---

### Decision D10: Category Customization

**Options Considered:**
1. Users can rename, add, or remove dimensions
2. Strict 10 dimensions, no customization
3. Strict 10 dimensions, but users can "hide" irrelevant dimensions

**Chosen:** Option 2 -- Strict 10 dimensions, no customization

**Rationale:** The 10 life dimensions are the structural backbone that ensures whole-life coverage. Allowing users to remove dimensions creates blind spots -- the very blind spots the PCI is designed to prevent. Carnes' tool is specifically designed so that users must confront areas of life they might prefer to ignore. The flexible indicator count (0-5) already provides escape for dimensions that feel less relevant (user can skip the dimension or enter only 1 indicator). Allowing dimension addition creates scope creep and UI complexity. In a future version, if user feedback strongly supports it, "hide" functionality could be reconsidered, but for V1, the disciplined 10-dimension framework preserves the tool's therapeutic integrity.

---

### Decision D11: Recovery Health Score Integration

**Options Considered:**
1. LBI weekly score is a direct component with equal weight to other RHS factors
2. LBI weekly score is a weighted component with higher weight due to upstream position
3. LBI weekly score does not factor into RHS (independent metric)

**Chosen:** Option 1 -- Equal weight component

**Rationale:** While the LBI is conceptually upstream of other recovery activities, giving it disproportionate weight would mean that a single tool could dominate the Recovery Health Score, potentially discouraging engagement with other activities. Equal weight among components (mood tracking, activity completion, FASTER Scale, LBI, etc.) creates a balanced score that reflects overall recovery engagement. The LBI's upstream value is communicated through the FASTER correlation display (S11) rather than through score weighting. The formula is: LBI contribution = (49 - weeklyScore) / 49 * 100, which maps a 0 (perfect) to 100% and a 49 (worst) to ~2%. This is then weighted equally with other RHS components per the existing formula specification.

---

### Decision D12: Accountability Sharing Scope

**Options Considered:**
1. Share weekly scores, risk levels, and individual indicator text
2. Share weekly scores and risk levels only (no indicator text)
3. Share only risk level (no numeric score)

**Chosen:** Option 2 -- Weekly scores and risk levels only, no indicator text

**Rationale:** The PCI's indicator text is deeply personal self-disclosure ("I stopped going to SA meetings," "I snapped at my wife," "I binged on junk food for 3 days"). Sharing this text with an accountability partner without explicit, granular consent could feel like a privacy violation and discourage honest indicator definition. However, sharing the weekly score and risk level provides accountability partners with exactly the signal they need: "your partner's lifestyle balance has deteriorated to High Risk this week." The partner can then initiate a conversation, and the user can choose to share specifics verbally. This aligns with the app's privacy-by-architecture principle. The trend direction (up/down/stable) provides additional context without exposing specific behaviors.

---

*End of Design Decisions Log*

---

## Appendix A: PCI Dimension Content Reference

The following content is displayed during setup to guide users in defining their personal indicators. Descriptions are adapted from Carnes' original text with Regal Recovery's voice.

| # | Dimension | Prompt Question | Example Behaviors |
|---|---|---|---|
| 1 | Physical Health | "How do you know that you are not taking care of your body?" | Exceeding target weight, missing exercise 2+ days, skipping meals, not sleeping enough, neglecting medication, skipping hygiene routines |
| 2 | Environment | "What are ways in which you neglect your living space or daily logistics?" | Unwashed dishes, overdue laundry, depleted groceries, neglected vehicle maintenance, cluttered living space, missed routine appointments, reckless driving |
| 3 | Work | "When your life is unmanageable at work, what are your behaviors?" | Unreturned calls/emails 24+ hours, late to meetings, falling behind on commitments, overloaded schedule, procrastinating important tasks |
| 4 | Interests | "What positive activities give you perspective and joy when you're not overextended?" | Reading, music, cooking, gardening, fishing, photography, sports, creative hobbies, time in nature |
| 5 | Social Life | "What are signs that you've become isolated from your social support network?" | Canceling plans, not returning friends' calls, avoiding social gatherings, spending weekends alone, losing touch with non-family friends |
| 6 | Family, Relationships & Significant Others | "What behaviors indicate disconnection from those closest to you?" | Going silent, passive-aggressive behavior, avoiding conflict conversations, breaking promises to family, neglecting quality time, lying or withholding truth, boundary violations |
| 7 | Finances | "What signs indicate that you are financially overextended?" | Unbalanced checking account, overdue bills, spending more than earning, impulse purchases, avoiding looking at bank statements |
| 8 | Spiritual Life & Personal Reflection | "What sources of spiritual nourishment and personal reflection do you neglect when overextended?" | Skipping prayer/devotionals, missing church, no Bible reading, neglecting journaling, avoiding quiet time, skipping therapy appointments |
| 9 | Other Compulsive/Symptomatic Behaviors | "What negative compulsive or symptomatic behaviors appear when you feel 'on the edge'?" | Excessive screen time, overeating, nail biting, compulsive shopping, jealousy, forgetfulness, irritability, caffeine/sugar overuse |
| 10 | Recovery Practice & Therapeutic Self-Care | "What recovery activities do you neglect first?" | Missing SA/Celebrate Recovery meetings, not calling sponsor, skipping step work, avoiding accountability check-ins, neglecting therapeutic homework |

---

## Appendix B: Risk Level Reference

| Weekly Score | Risk Level | Color | Description |
|---|---|---|---|
| 0-9 | Optimal Health | Green (#34C759) | Very resilient. Knows limits; has clear priorities; congruent with values; balanced and orderly; resolves crises quickly. |
| 10-19 | Stable Solidity | Blue (#007AFF) | Resilient. Recognizes human limits; maintains most boundaries; well ordered; typically feels competent and supported. |
| 20-29 | Medium Risk | Amber (#FF9500) | Often rushed; no emotional margin for crisis; vulnerable to slipping into old patterns; feeling stretched thin. |
| 30-39 | High Risk | Orange (#FF6B35) | Living in extremes; relationships strained; feeling irresponsible; constantly catching up; saying one thing, doing another. |
| 40-49 | Very High Risk | Red (#FF3B30) | Self-destructive patterns active; blaming others; rarely following through; high risk of relapse escalation. |
