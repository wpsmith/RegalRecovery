# Recovery Quadrant -- Feature PRD

| Field | Value |
|---|---|
| **PRD Title** | Recovery Quadrant |
| **Author** | Travis Smith |
| **Date** | 2026-04-23 |
| **Version** | 1.0 |
| **Designation** | Feature (within Recovery Tools Epic) |
| **OMTM** | Percentage of active users completing weekly quadrant assessments for 8+ consecutive weeks (target >= 60%) |
| **Target Delivery** | 3 sprints (30 business days maximum) |
| **MoSCoW Summary** | 10 Must, 6 Should, 4 Could, 4 Won't |
| **Feature Flag** | `feature.quadrant` |

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

Users in addiction recovery track daily behavioral indicators (via LBI) and emotional/relapse stages (via FASTER Scale), but lack a high-altitude weekly self-assessment that captures how they feel about their overall wellness across the four major life domains: physical, mental, relational, and spiritual. The LBI answers "what warning behaviors happened today?" and the FASTER Scale answers "where am I on the relapse progression?" -- but neither answers the broader question: "How is my whole-person wellness this week?"

**User goal:** Maintain weekly awareness of whole-person balance across Body, Mind, Heart, and Spirit so that dimensional imbalances are caught early and addressed with targeted recovery actions.

**Hurdles:**
- Recovery tools that only track one dimension (sobriety days, mood, meeting attendance) miss cross-dimensional erosion patterns
- Without a structured framework, users default to "I feel fine" assessments that miss slow deterioration
- No existing feature connects quadrant-level self-assessment to actionable recommendations that drive engagement with specific recovery activities
- The relationship between dimensional balance and relapse vulnerability is not made visible to users

**Quantifiable impact:** Research from Marlatt & Donovan (2005) and Carnes' PCI framework confirms that lifestyle imbalance across multiple dimensions precedes relapse. The Recovery Quadrant aims to detect imbalance 1-2 weeks earlier than the LBI alone by capturing subjective self-assessment alongside behavioral data, giving users a dual-lens view of their recovery health.

### Business Hypothesis

By providing a weekly four-quadrant self-assessment with radar chart visualization, trend tracking, imbalance detection, and targeted activity recommendations, we hypothesize that:

- **Primary outcome:** 60% of users who complete their first quadrant assessment will continue weekly assessments for 8+ weeks (measured by assessment completion rate)
- **Secondary outcome:** Users who maintain weekly quadrant assessments will show a 10-15% improvement in Daily Recovery Score stability over 12 weeks, compared to their pre-quadrant baseline
- **OMTM impact:** Target 1-2% improvement in overall app retention (the Recovery Tools epic's contribution to the app-wide OMTM)

### Solution Overview

A three-layer Recovery Quadrant implementation within the Regal Recovery iOS app:

1. **Weekly Self-Assessment** -- A 2-3 minute weekly assessment where users rate four life dimensions (Body, Mind, Heart, Spirit) on a 1-10 Likert scale with behavioral indicator checklists and optional reflections
2. **Visualization Dashboard** -- Radar chart for current-week snapshot, multi-line trend chart for historical comparison, balance score with threshold alerts
3. **Actionable Recommendations** -- When imbalances are detected, the app suggests specific recovery activities (prayer, exercise, journaling, phone calls) mapped to the deficient quadrant, creating a feedback loop that drives engagement with existing features

### Resource Requirements

- 1 iOS developer (3 sprints)
- Design review at Sprint 1 boundary
- QA integrated throughout
- No backend API changes required for MVP (SwiftData local-first)

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Assessment fatigue alongside LBI daily check-in | Medium | High | Weekly frequency (not daily); position as the "big picture" complement to LBI's daily detail |
| Self-reporting bias (users overrate dimensions) | Medium | Medium | Include behavioral indicators alongside Likert ratings to ground self-assessment in observable reality |
| Feature feels redundant with LBI | Medium | Medium | Clear differentiation: LBI = behavioral tracking (what happened), Quadrant = self-assessment (how you feel about each domain). Different frequency, different granularity |
| Low engagement after initial novelty | Medium | Medium | Actionable recommendations create a feedback loop; integration with Daily Recovery Score provides ongoing incentive |
| Radar chart readability on small screens | Low | Medium | Test on iPhone SE; provide alternative list view for accessibility |

---

## 2. Product Overview

### Product Vision

The Recovery Quadrant provides the "satellite view" of recovery wellness. While the Life Balance Index tracks ground-level daily behaviors and the FASTER Scale monitors active relapse progression, the Recovery Quadrant answers the weekly question every recovering person should ask: "Am I loving God with all my heart, soul, mind, and strength?" (Mark 12:30). By making whole-person balance visible, measurable, and actionable, the Recovery Quadrant helps users catch dimensional imbalances before they cascade into behavioral erosion (rising LBI) or emotional escalation (FASTER stage progression).

### Target Users

**Primary Persona: Alex (Active Recovery)**
- 6-18 months into SA/Celebrate Recovery program
- Uses Regal Recovery daily for LBI check-ins, FASTER Scale, mood tracking
- Has a routine but may not notice slow erosion in specific life areas
- Needs: a weekly check-in that gives a holistic snapshot and flags imbalances before they become crises

**Secondary Persona: Jordan (Early Recovery)**
- 0-6 months in recovery, establishing daily routines
- May be overwhelmed by granular tracking tools
- Needs: a simple, high-level assessment that introduces the concept of whole-person recovery without overwhelming detail
- The Quadrant's 4-dimension simplicity is more accessible than LBI's 10 dimensions for early recovery users

**Tertiary Persona: Sam (Sponsor/Accountability Partner)**
- Reviews shared data from accountability partners
- Needs: at-a-glance visibility into a partner's whole-person balance to guide conversation priorities

### Value Proposition

"See the shape of your recovery. The Recovery Quadrant reveals how your Body, Mind, Heart, and Spirit are working together -- so you can strengthen what's weak before it pulls the rest down."

### OMTM and Success Criteria

**One Metric That Matters:** Weekly assessment completion consistency -- percentage of active users who complete their quadrant assessment every week for 8+ consecutive weeks.

| Success Criterion | Target | Measurement Method |
|---|---|---|
| First assessment completion rate | >= 80% of users who open the feature | Local analytics: feature_opened vs assessment_completed events |
| Weekly assessment adherence | >= 60% of weeks assessed during first 8 weeks | Completion rate: (weeks assessed) / (weeks since first assessment) |
| Time to complete assessment | <= 3 minutes median | Time from assessment screen open to save |
| Activity recommendation follow-through | >= 25% of recommendations result in the suggested activity being completed within 7 days | Recommendation shown vs linked activity completed |
| Quadrant score stability | Users show reduced score variance after 4 weeks of tracking | Standard deviation of quadrant scores week-over-week |
| Feature retention | >= 50% of first-assessment completers still assessing at week 8 | 8-week retention cohort analysis |

### Scope Constraints

- **Feature scope:** Maximum 3 sprints (30 business days)
- **Platform:** iOS only (SwiftUI + SwiftData)
- **Tier:** Standard tier ships in Sprints 1-2; Premium insights (AI analysis) deferred to future scope
- **Backend:** Local-first with SwiftData; API sync deferred to future feature
- **No therapist portal integration** in this scope

### Assumptions

1. Users have completed onboarding and have an active RRUser record in SwiftData
2. Users understand the concept of holistic recovery (body, mind, heart, spirit) -- if not, the psychoeducation screen establishes the framework
3. Weekly assessment frequency is sustainable alongside daily LBI check-ins
4. The Mark 12:30 framing resonates with the SA/Celebrate Recovery Christian user base
5. Existing notification infrastructure can schedule weekly assessment reminders

---

## 3. MoSCoW Prioritized Requirements

### Must Have (Non-negotiable for launch)

| ID | Requirement | Rationale |
|---|---|---|
| M1 | Four quadrant framework: Body, Mind, Heart, Spirit with descriptions and scripture foundations | Core feature structure |
| M2 | Weekly self-assessment with 1-10 Likert scale per quadrant | Primary data capture mechanism |
| M3 | 3-5 behavioral indicators per quadrant as supporting evidence for the Likert rating | Grounds subjective assessment in observable reality |
| M4 | Radar chart visualization showing current week's four quadrant scores | Primary "balance at a glance" visualization |
| M5 | Balance score calculation from the four quadrant ratings (mean + variance-based) | Single metric for overall wellness |
| M6 | 8-week trend chart showing quadrant scores over time | Pattern recognition over meaningful time horizon |
| M7 | Imbalance detection: flag when any quadrant is 3+ points below the average of others | Early warning system for dimensional neglect |
| M8 | Activity recommendations mapped to each quadrant (suggest specific app activities when a quadrant is low) | Makes assessment actionable, not just measurement |
| M9 | SwiftData persistence for all quadrant data (assessments, scores, recommendations) | Offline-first architecture requirement |
| M10 | Quadrant accessible from Recovery Work tab | Must be discoverable in app's primary navigation |

### Should Have (Important but solution is viable without)

| ID | Requirement | Rationale |
|---|---|---|
| S1 | Psychoeducation screen explaining the quadrant framework, Mark 12:30 foundation, and how it complements LBI | Reduces confusion about feature purpose; establishes theological grounding |
| S2 | Integration with Daily Recovery Score (quadrant balance as a weighted component) | Strategic PRD requirement; connects Quadrant to the overall recovery metric |
| S3 | Weekly notification reminding user to complete their quadrant assessment | Adherence driver |
| S4 | Optional one-sentence reflection per quadrant during assessment | Deepens self-awareness beyond numeric rating |
| S5 | Scripture verse display per quadrant during assessment | Reinforces Christian integration during the experience |
| S6 | Accountability partner sharing of quadrant scores and trends (not reflections) | Accountability sharing is a core app feature |

### Could Have (Nice-to-haves)

| ID | Requirement | Rationale |
|---|---|---|
| C1 | LBI correlation display: quadrant trends alongside LBI weekly scores | Demonstrates the satellite-vs-street-level complementary relationship |
| C2 | FASTER Scale correlation display: quadrant trends alongside FASTER stage history | Shows how quadrant decline precedes FASTER escalation |
| C3 | Premium AI-generated weekly insight based on quadrant trends and recommendations | Premium tier differentiation |
| C4 | Achievement badges for assessment streaks (4-week, 8-week, 12-week) | Gamification for adherence |

### Won't Have (Explicitly excluded)

| ID | Requirement | Rationale |
|---|---|---|
| W1 | Backend API sync for quadrant data | Deferred to sync epic; local-first is sufficient for MVP |
| W2 | Custom quadrant labels or adding/removing quadrants | The 4-quadrant framework (Body/Mind/Heart/Spirit) must remain fixed for scriptural integrity and scoring consistency |
| W3 | Daily quadrant assessment option | Weekly frequency is deliberate -- daily would cause fatigue alongside LBI and other check-ins |
| W4 | Community/group quadrant comparisons | Privacy concern; quadrant data is personal and not comparable across users |

---

## 4. Functional Requirements

### 4.1 Quadrant Definitions

| ID | Requirement | Priority | Conditions of Satisfaction |
|---|---|---|---|
| FR-01 | System defines four recovery quadrants: Body, Mind, Heart, Spirit | Must | Given the quadrant feature is loaded, When the definitions are displayed, Then each quadrant shows its name, description, scripture verse, icon, and color |
| FR-02 | Each quadrant has 3-5 behavioral indicators that serve as observable evidence | Must | Given a quadrant is being assessed, When the user views indicators, Then 3-5 checkable indicators are displayed below the Likert scale for that quadrant |

**Quadrant Definitions:**

| Quadrant | Label | Scripture | Color | Icon | Description | Behavioral Indicators |
|---|---|---|---|---|---|---|
| **Body** | Physical Stewardship | 1 Cor 6:19-20 | Green (#34C759) | figure.walk | "Honoring God by caring for your body -- the temple of the Holy Spirit. Physical health, rest, nutrition, and energy." | Exercised 3+ times this week; Slept 7+ hours most nights; Ate regular, balanced meals; Took prescribed medications; Felt physically energized |
| **Mind** | Mental Renewal | Romans 12:2 | Blue (#007AFF) | brain.head.profile | "Renewing your mind through learning, reflection, and emotional awareness. Mental health, clarity, and cognitive engagement." | Engaged in learning or reading; Managed stress without avoidance; Processed emotions constructively; Attended therapy or did therapeutic homework; Felt mentally clear and focused |
| **Heart** | Relational Connection | Galatians 6:2 | Orange (#FF9500) | heart.circle | "Carrying each other's burdens through authentic relationship. Connection with others, accountability, and emotional honesty." | Talked honestly with sponsor or AP; Attended a meeting or support group; Had meaningful time with family; Reached out to a friend; Felt connected rather than isolated |
| **Spirit** | Spiritual Vitality | Psalm 42:1 | Purple (#AF52DE) | sparkles | "Your soul thirsting for God. Prayer, scripture, worship, and awareness of God's presence in your recovery." | Prayed or had devotional time daily; Read scripture this week; Attended church or worship; Practiced gratitude; Felt God's presence or guidance |

### 4.2 Weekly Self-Assessment Flow

| ID | Requirement | Priority | Conditions of Satisfaction |
|---|---|---|---|
| FR-03 | System presents a sequential assessment flow: one quadrant per screen with Likert scale and behavioral indicators | Must | Given the user starts the assessment, When a quadrant screen is displayed, Then it shows the quadrant name, scripture, a 1-10 slider, behavioral indicator checkboxes, and an optional reflection text field |
| FR-04 | User rates each quadrant on a 1-10 Likert scale with anchor descriptions | Must | Given a quadrant is displayed, When the user adjusts the slider, Then the numeric value (1-10) updates with anchor labels: 1-3 "Struggling", 4-6 "Managing", 7-8 "Stable", 9-10 "Thriving" |
| FR-05 | User can check applicable behavioral indicators (0 to all) for each quadrant | Must | Given the quadrant screen shows behavioral indicators, When the user checks 3 of 5 indicators, Then a counter shows "3 of 5" and the checked indicators are stored |
| FR-06 | User can write an optional one-sentence reflection per quadrant (max 280 characters) | Should | Given the quadrant screen shows a text field, When the user types a reflection, Then text is accepted up to 280 characters with a character counter |
| FR-07 | Each quadrant screen displays its scripture verse as a visual header | Should | Given the Body quadrant screen is displayed, When the user views the header, Then "Do you not know that your bodies are temples of the Holy Spirit?" (1 Cor 6:19) is displayed |
| FR-08 | After rating all four quadrants, system shows a summary screen with radar chart | Must | Given the user has rated all four quadrants, When the summary screen appears, Then a radar chart displays the four scores with the balance score and any imbalance alerts |
| FR-09 | User saves the assessment from the summary screen | Must | Given the summary screen is displayed, When the user taps "Save", Then the assessment is persisted to SwiftData with date, scores, indicators, and reflections |
| FR-10 | System prevents duplicate assessments for the same ISO week (Mon-Sun); editing an existing assessment is allowed | Must | Given the user has already completed this week's assessment, When they open the assessment, Then the existing entry is loaded for editing |

### 4.3 Scoring and Balance Detection

| ID | Requirement | Priority | Conditions of Satisfaction |
|---|---|---|---|
| FR-11 | System calculates a composite balance score from the four quadrant ratings | Must | Given scores of Body=8, Mind=6, Heart=7, Spirit=9, When the balance score is calculated, Then it reflects both the mean (7.5) and the variance (low variance = balanced) |
| FR-12 | System detects imbalance when any quadrant is 3+ points below the average of the other three | Must | Given Body=3, Mind=8, Heart=7, Spirit=8, When imbalance detection runs, Then Body is flagged as "Needs Attention" (3 is 4.7 points below the average of 7.67) |
| FR-13 | Balance score maps to an overall wellness level | Must | Given a balance score, When the level is determined, Then one of four levels is displayed: Flourishing (mean >= 8, low variance), Growing (mean >= 6), Rebuilding (mean >= 4), Struggling (mean < 4) |
| FR-14 | Imbalance alerts display on the summary screen with the specific quadrant(s) flagged | Must | Given Body is flagged as imbalanced, When the summary screen renders, Then a visual alert highlights Body with "This area needs your attention" and a recommended action |

### 4.4 Visualization

| ID | Requirement | Priority | Conditions of Satisfaction |
|---|---|---|---|
| FR-15 | Radar chart displays four quadrant scores as a polygon on four axes | Must | Given scores Body=7, Mind=5, Heart=8, Spirit=6, When the radar chart renders, Then four axes (Body, Mind, Heart, Spirit) show the scores with the polygon connecting them |
| FR-16 | Radar chart overlays current week and previous week for comparison | Should | Given current and previous week data exist, When the chart renders, Then two polygons are shown: current week (solid fill) and previous week (dashed outline) |
| FR-17 | 8-week trend chart shows four line series (one per quadrant) over time | Must | Given 6 weeks of data exist, When the trend chart renders, Then four colored lines plot each quadrant's score over the 6 weeks with a shared x-axis |
| FR-18 | Balance score trend is shown alongside quadrant trends | Should | Given 6 weeks of data, When the trend chart renders, Then a fifth line (or separate chart) shows the composite balance score over time |

### 4.5 Actionable Recommendations

| ID | Requirement | Priority | Conditions of Satisfaction |
|---|---|---|---|
| FR-19 | When a quadrant is rated 5 or below, system shows 1-2 recommended app activities | Must | Given Spirit is rated 4, When the summary screen shows recommendations, Then "Prayer" and "Affirmations" are suggested with tap-to-navigate links |
| FR-20 | Recommendations are mapped per quadrant to existing app activities | Must | Given the mapping exists, When a recommendation is shown, Then it links to the correct activity entry point in the app |
| FR-21 | Imbalanced quadrants show priority recommendations with urgency framing | Must | Given Body is flagged as imbalanced (3+ below average), When the recommendation is shown, Then it uses urgent framing: "Your Body score is significantly lower than your other areas. Consider prioritizing physical care this week." |

**Recommendation Mapping:**

| Quadrant | If Score <= 5 | Recommended Activities |
|---|---|---|
| Body | Physical wellness attention needed | Exercise, Sleep log (manual note), Nutrition check-in (manual note), Medical appointment reminder |
| Mind | Mental wellness attention needed | Journaling, CBT Thoughts (if available), Step work, Therapy check-in (manual note) |
| Heart | Relational connection attention needed | Phone Calls, FANOS check-in, Meeting attendance, Accountability check-in |
| Spirit | Spiritual vitality attention needed | Prayer, Affirmations (Declarations of Truth), Devotional, Gratitude list |

### 4.6 Integration

| ID | Requirement | Priority | Conditions of Satisfaction |
|---|---|---|---|
| FR-22 | Quadrant balance score contributes to Daily Recovery Score as a weighted component | Should | Given the Recovery Health Score formula includes a Quadrant component, When the score is calculated, Then the Quadrant balance score is included as a weekly-updated component |
| FR-23 | Quadrant assessment appears in the Today view's activity feed when completed | Must | Given the user completes this week's assessment, When the Today view refreshes, Then a card shows "Recovery Quadrant: [Wellness Level]" with the radar chart thumbnail |
| FR-24 | Accountability partner sharing includes quadrant scores and trends (not reflections) | Should | Given sharing is enabled, When the partner views shared data, Then they see quadrant scores, balance score, and trend direction -- but NOT reflection text |

---

## 5. Non-Functional Requirements

### 5.1 Performance

| ID | Requirement | Target |
|---|---|---|
| NFR-01 | Assessment screen load time | < 500ms on iPhone 13 or newer |
| NFR-02 | Assessment save time | < 200ms |
| NFR-03 | Radar chart render time | < 500ms |
| NFR-04 | Trend chart render time (8 weeks of data) | < 1 second |
| NFR-05 | Balance score calculation time | < 50ms |

### 5.2 Security and Privacy

| ID | Requirement | Target |
|---|---|---|
| NFR-06 | All quadrant data (including reflections) stored locally in SwiftData only | Enforced by architecture (no API sync in scope) |
| NFR-07 | Accountability sharing shares scores only, never reflection text | Enforced by sharing data model |
| NFR-08 | Biometric lock protects quadrant data alongside all other app data | Inherited from app-level biometric gate |
| NFR-09 | Quadrant data included in full data export (DSR compliance) | Included in existing data export pipeline |

### 5.3 Usability

| ID | Requirement | Target |
|---|---|---|
| NFR-10 | Weekly assessment completes in under 3 minutes (4 quadrants + summary) | Measured by median completion time |
| NFR-11 | All text meets WCAG 2.1 AA contrast ratios | Automated accessibility audit |
| NFR-12 | VoiceOver fully supports assessment flow, radar chart, and trend chart | Manual accessibility testing |
| NFR-13 | Dynamic Type support for all quadrant screens | Tested at all system text sizes |
| NFR-14 | Radar chart has an accessible text alternative (quadrant scores as list) | VoiceOver reads scores as "Body: 7, Mind: 5, Heart: 8, Spirit: 6" |

### 5.4 Compatibility

| ID | Requirement | Target |
|---|---|---|
| NFR-15 | iOS 17.0+ (matching app minimum deployment target) | Build and runtime tested |
| NFR-16 | iPhone SE (3rd gen) through iPhone 16 Pro Max screen sizes | Adaptive layout tested |

---

## 6. Technical Considerations

### 6.1 Architecture Overview

The Quadrant feature follows the existing app architecture: MVVM with SwiftData persistence, `@Observable` view models, and integration with the `ServiceContainer` singleton.

```
Views (SwiftUI)
  |
  v
ViewModels (@Observable)
  |
  v
Models (@Model, SwiftData)
```

Key architectural decisions:
- **Local-first:** All quadrant data persists in SwiftData. No API endpoints in scope.
- **Weekly granularity:** One assessment per ISO week (Monday-Sunday), duplicate prevention via week-number matching.
- **Computed balance score:** Balance score is derived from the four quadrant ratings using mean and standard deviation.
- **Feature flag:** Gated behind `feature.quadrant` feature flag.

### 6.2 Data Model (SwiftData)

```swift
// MARK: - Quadrant Assessment

@Model
final class RRQuadrantAssessment {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var weekStartDate: Date          // Monday of the assessed week
    var isoWeekNumber: Int           // ISO week number for duplicate prevention
    var isoYear: Int                 // ISO year for duplicate prevention
    var bodyScore: Int               // 1-10
    var mindScore: Int               // 1-10
    var heartScore: Int              // 1-10
    var spiritScore: Int             // 1-10
    var balanceScore: Double         // Computed composite (0-100 scale)
    var wellnessLevel: String        // "flourishing", "growing", "rebuilding", "struggling"
    var bodyIndicatorsJSON: String   // JSON-encoded [String] of checked indicators
    var mindIndicatorsJSON: String
    var heartIndicatorsJSON: String
    var spiritIndicatorsJSON: String
    var bodyReflection: String?      // Optional one-sentence reflection
    var mindReflection: String?
    var heartReflection: String?
    var spiritReflection: String?
    var imbalancedQuadrantsJSON: String // JSON-encoded [String] of flagged quadrant names
    var createdAt: Date
    var modifiedAt: Date
    var needsSync: Bool

    init(userId: UUID, weekStartDate: Date) {
        self.id = UUID()
        self.userId = userId
        self.weekStartDate = weekStartDate
        let calendar = Calendar(identifier: .iso8601)
        let components = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: weekStartDate)
        self.isoWeekNumber = components.weekOfYear ?? 0
        self.isoYear = components.yearForWeekOfYear ?? 0
        self.bodyScore = 5
        self.mindScore = 5
        self.heartScore = 5
        self.spiritScore = 5
        self.balanceScore = 0
        self.wellnessLevel = "growing"
        self.bodyIndicatorsJSON = "[]"
        self.mindIndicatorsJSON = "[]"
        self.heartIndicatorsJSON = "[]"
        self.spiritIndicatorsJSON = "[]"
        self.imbalancedQuadrantsJSON = "[]"
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.needsSync = true
    }
}

// MARK: - Supporting Types

enum QuadrantType: String, Codable, CaseIterable, Identifiable {
    case body = "body"
    case mind = "mind"
    case heart = "heart"
    case spirit = "spirit"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .body: return String(localized: "Body")
        case .mind: return String(localized: "Mind")
        case .heart: return String(localized: "Heart")
        case .spirit: return String(localized: "Spirit")
        }
    }

    var subtitle: String {
        switch self {
        case .body: return String(localized: "Physical Stewardship")
        case .mind: return String(localized: "Mental Renewal")
        case .heart: return String(localized: "Relational Connection")
        case .spirit: return String(localized: "Spiritual Vitality")
        }
    }

    var icon: String {
        switch self {
        case .body: return "figure.walk"
        case .mind: return "brain.head.profile"
        case .heart: return "heart.circle"
        case .spirit: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .body: return Color(.systemGreen)      // #34C759
        case .mind: return Color(.systemBlue)        // #007AFF
        case .heart: return Color(.systemOrange)     // #FF9500
        case .spirit: return Color(.systemPurple)    // #AF52DE
        }
    }

    var scriptureReference: String {
        switch self {
        case .body: return "1 Corinthians 6:19-20"
        case .mind: return "Romans 12:2"
        case .heart: return "Galatians 6:2"
        case .spirit: return "Psalm 42:1"
        }
    }

    var scriptureText: String {
        switch self {
        case .body: return String(localized: "Do you not know that your bodies are temples of the Holy Spirit, who is in you, whom you have received from God? You are not your own; you were bought at a price. Therefore honor God with your bodies.")
        case .mind: return String(localized: "Do not conform to the pattern of this world, but be transformed by the renewing of your mind. Then you will be able to test and approve what God's will is — his good, pleasing and perfect will.")
        case .heart: return String(localized: "Carry each other's burdens, and in this way you will fulfill the law of Christ.")
        case .spirit: return String(localized: "As the deer pants for streams of water, so my soul pants for you, my God. My soul thirsts for God, for the living God.")
        }
    }

    var description: String {
        switch self {
        case .body: return String(localized: "Honoring God by caring for your body — the temple of the Holy Spirit. Physical health, rest, nutrition, and energy.")
        case .mind: return String(localized: "Renewing your mind through learning, reflection, and emotional awareness. Mental health, clarity, and cognitive engagement.")
        case .heart: return String(localized: "Carrying each other's burdens through authentic relationship. Connection with others, accountability, and emotional honesty.")
        case .spirit: return String(localized: "Your soul thirsting for God. Prayer, scripture, worship, and awareness of God's presence in your recovery.")
        }
    }

    var behavioralIndicators: [String] {
        switch self {
        case .body: return [
            String(localized: "Exercised 3+ times this week"),
            String(localized: "Slept 7+ hours most nights"),
            String(localized: "Ate regular, balanced meals"),
            String(localized: "Took prescribed medications"),
            String(localized: "Felt physically energized")
        ]
        case .mind: return [
            String(localized: "Engaged in learning or reading"),
            String(localized: "Managed stress without avoidance"),
            String(localized: "Processed emotions constructively"),
            String(localized: "Attended therapy or did therapeutic homework"),
            String(localized: "Felt mentally clear and focused")
        ]
        case .heart: return [
            String(localized: "Talked honestly with sponsor or AP"),
            String(localized: "Attended a meeting or support group"),
            String(localized: "Had meaningful time with family"),
            String(localized: "Reached out to a friend"),
            String(localized: "Felt connected rather than isolated")
        ]
        case .spirit: return [
            String(localized: "Prayed or had devotional time daily"),
            String(localized: "Read scripture this week"),
            String(localized: "Attended church or worship"),
            String(localized: "Practiced gratitude"),
            String(localized: "Felt God's presence or guidance")
        ]
        }
    }

    var recommendedActivities: [(key: String, label: String)] {
        switch self {
        case .body: return [
            ("exercise", "Exercise"),
            ("nutrition", "Nutrition Check-in")
        ]
        case .mind: return [
            ("journal", "Journaling"),
            ("stepWork", "Step Work")
        ]
        case .heart: return [
            ("phoneCalls", "Phone Calls"),
            ("fanos", "FANOS Check-in")
        ]
        case .spirit: return [
            ("prayer", "Prayer"),
            ("affirmations", "Declarations of Truth")
        ]
        }
    }
}

enum WellnessLevel: String, Codable, CaseIterable {
    case flourishing = "flourishing"   // mean >= 8.0 AND stdev <= 1.5
    case growing = "growing"           // mean >= 6.0
    case rebuilding = "rebuilding"     // mean >= 4.0
    case struggling = "struggling"     // mean < 4.0

    var displayName: String {
        switch self {
        case .flourishing: return String(localized: "Flourishing")
        case .growing: return String(localized: "Growing")
        case .rebuilding: return String(localized: "Rebuilding")
        case .struggling: return String(localized: "Struggling")
        }
    }

    var description: String {
        switch self {
        case .flourishing: return String(localized: "Your recovery is thriving across all dimensions. Keep nurturing each area.")
        case .growing: return String(localized: "You are making steady progress. Watch for areas that may need more attention.")
        case .rebuilding: return String(localized: "Some areas need strengthening. Focus on the recommendations below.")
        case .struggling: return String(localized: "Multiple areas need attention. Consider reaching out to your support network.")
        }
    }

    var color: Color {
        switch self {
        case .flourishing: return Color(.systemGreen)
        case .growing: return Color(.systemBlue)
        case .rebuilding: return Color(.systemOrange)
        case .struggling: return Color(.systemRed)
        }
    }
}
```

### 6.3 Balance Score Formula

```
mean = (body + mind + heart + spirit) / 4.0
stdev = sqrt(((body - mean)^2 + (mind - mean)^2 + (heart - mean)^2 + (spirit - mean)^2) / 4.0)
balanceScore = (mean / 10.0) * (1.0 - (stdev / 4.5)) * 100.0
```

The balance score (0-100) rewards both high average scores AND low variance (balance). A perfect score of 100 requires all four quadrants at 10. A mean of 10 but high variance is mathematically impossible (bounded 1-10), so the formula naturally rewards balance among high scores.

**Wellness level thresholds:**
- Flourishing: mean >= 8.0 AND standard deviation <= 1.5
- Growing: mean >= 6.0
- Rebuilding: mean >= 4.0
- Struggling: mean < 4.0

**Imbalance detection:**
- A quadrant is "imbalanced" when its score is 3+ points below the mean of the other three quadrants
- Example: Body=3, Mind=8, Heart=7, Spirit=8 -> Mean of others = 7.67, Body is 4.67 below -> flagged

### 6.4 Integration Points

| Integration | Mechanism | Scope |
|---|---|---|
| Recovery Health Score | Quadrant balance score contributes to RHS weekly calculation | Should (S2) |
| Today view activity feed | `RRQuadrantAssessment` rendered as a card in the Today feed | Must (FR-23) |
| Activity recommendations | Low quadrant score triggers deep link to related activity | Must (FR-19, FR-20) |
| Accountability sharing | Weekly scores + wellness level shared via existing sharing infrastructure | Should (S6) |
| Notifications | Weekly reminder via existing `PlanNotificationScheduler` | Should (S3) |
| Feature flags | `feature.quadrant` flag gates feature visibility | Must |

### 6.5 Infrastructure

No additional infrastructure required. All data is local (SwiftData). The feature flag is evaluated from the existing `RRFeatureFlag` model. Notifications use the existing local notification scheduling system.

---

## 7. User Stories

### Epic: Recovery Quadrant

---

### Story 1: Quadrant Psychoeducation Screen

**As a** recovering person opening the Recovery Quadrant for the first time,
**I want** to understand what the four quadrants are, why whole-person balance matters, and how this connects to Mark 12:30,
**So that** I am motivated to invest 3 minutes weekly in this self-assessment and understand its relationship to my other recovery tools.

**Priority:** Should (S1)
**Story Points:** 3

**Conditions of Satisfaction:**

- Given I have never completed a quadrant assessment, When I navigate to the Quadrant feature, Then a psychoeducation screen displays with: the Mark 12:30 verse, a brief explanation of the four quadrants, the "satellite view" metaphor, and an estimate of time ("about 3 minutes each week")
- Given the psychoeducation screen is displayed, When I tap "Begin Assessment", Then the assessment flow starts at the Body quadrant
- Given I have completed at least one assessment, When I navigate to the Quadrant feature, Then the psychoeducation screen is not shown; I go directly to the dashboard or assessment

---

### Story 2: Weekly Quadrant Assessment

**As a** recovering person doing my weekly self-check,
**I want** to rate each of the four life dimensions with a simple slider and check applicable behavioral indicators,
**So that** I build a weekly habit of honest whole-person self-assessment.

**Priority:** Must (M2, M3, FR-03 through FR-10)
**Story Points:** 8

**Conditions of Satisfaction:**

- Given I start the assessment, When the Body quadrant screen appears, Then I see: the quadrant name, subtitle, scripture verse, a 1-10 slider with anchor labels, 5 behavioral indicator checkboxes, and an optional reflection text field
- Given I rate Body as 7 and check 3 indicators, When I tap "Next", Then Mind is presented with the same layout
- Given I have rated all four quadrants, When the summary screen appears, Then a radar chart shows my four scores, the balance score is displayed, and any imbalanced quadrants are flagged
- Given this is my first assessment this week, When I save, Then a new `RRQuadrantAssessment` is created for this ISO week
- Given I already saved an assessment this week, When I open the assessment, Then my previous ratings are loaded for editing
- Given I am on the Heart quadrant, When I type "Connected with wife over dinner twice this week" in the reflection field, Then the text is accepted (under 280 characters) and saved

---

### Story 3: Radar Chart Visualization

**As a** recovering person who has completed my weekly assessment,
**I want** to see a radar chart showing my four quadrant scores at a glance,
**So that** I can instantly see which areas are strong and which need attention.

**Priority:** Must (M4, FR-15)
**Story Points:** 5

**Conditions of Satisfaction:**

- Given I have completed this week's assessment with Body=7, Mind=5, Heart=8, Spirit=6, When the radar chart renders, Then four labeled axes display the scores with a filled polygon connecting them
- Given previous week data exists, When the radar chart renders, Then two polygons are shown: current (solid) and previous (dashed outline) for week-over-week comparison
- Given I have no previous week data, When the radar chart renders, Then only the current week polygon is shown
- Given I am using VoiceOver, When the radar chart is focused, Then the accessibility label reads: "Recovery Quadrant: Body 7, Mind 5, Heart 8, Spirit 6"

---

### Story 4: Balance Score and Wellness Level

**As a** recovering person tracking my quadrant scores,
**I want** to see a single balance score and wellness level that tells me how my overall recovery is doing,
**So that** I have a quick answer to "how am I doing this week?"

**Priority:** Must (M5, FR-11 through FR-14)
**Story Points:** 3

**Conditions of Satisfaction:**

- Given scores of Body=8, Mind=7, Heart=8, Spirit=7, When the balance score is calculated, Then the score is high (low variance, high mean) and the wellness level is "Growing" (or "Flourishing" if mean >= 8)
- Given scores of Body=3, Mind=8, Heart=7, Spirit=9, When the imbalance detection runs, Then Body is flagged with "This area needs your attention" and a recommendation
- Given all four scores are below 4, When the wellness level is shown, Then "Struggling" is displayed with encouragement to reach out to support network

---

### Story 5: Trend Tracking

**As a** recovering person who has been doing weekly assessments for several weeks,
**I want** to see how my quadrant scores have changed over time,
**So that** I can recognize patterns of improvement or erosion across my recovery dimensions.

**Priority:** Must (M6, FR-17)
**Story Points:** 5

**Conditions of Satisfaction:**

- Given I have 6 weeks of assessment data, When the trend chart renders, Then four colored lines show each quadrant's score over the 6 weeks
- Given I have fewer than 2 weeks of data, When the trend area renders, Then a placeholder message shows: "Keep assessing -- your trends will appear after 2 weeks"
- Given the chart is rendered on an iPhone SE, When I view it, Then the chart scales without clipping or overlapping labels

---

### Story 6: Activity Recommendations

**As a** recovering person with an imbalanced quadrant,
**I want** to receive specific activity recommendations for my weakest area,
**So that** I know what to do about the imbalance, not just that it exists.

**Priority:** Must (M8, FR-19 through FR-21)
**Story Points:** 5

**Conditions of Satisfaction:**

- Given Spirit is rated 4, When the summary screen shows recommendations, Then "Prayer" and "Declarations of Truth" are suggested with tap-to-navigate links
- Given I tap "Prayer" in the recommendations, When the app navigates, Then I am taken to the Prayer activity entry point
- Given Body is flagged as imbalanced (3+ below average), When the recommendation shows, Then it uses urgent framing: "Your Body score is significantly below your other areas. Consider prioritizing physical care this week."
- Given all four quadrants are above 7, When the summary screen shows, Then no specific recommendations appear and a positive message is shown: "Your recovery is well-balanced this week. Keep it up!"

---

### Story 7: Today View Integration

**As a** recovering person using the Today view as my daily hub,
**I want** to see my quadrant assessment status and be reminded if I haven't assessed this week,
**So that** the weekly assessment stays integrated into my recovery routine.

**Priority:** Must (M10, FR-23)
**Story Points:** 3

**Conditions of Satisfaction:**

- Given I have completed this week's assessment, When I view the Today screen, Then a card shows "Recovery Quadrant: [Wellness Level]" with a small radar chart thumbnail
- Given I have not yet completed this week's assessment and it is Wednesday or later, When I view the Today screen, Then a prompt card shows "Time for your weekly Recovery Quadrant check-in"
- Given I have not set up (never used) the Quadrant, When I view the Today screen, Then no Quadrant card appears

---

### Story 8: Weekly Notification

**As a** recovering person who wants consistent weekly assessments,
**I want** to receive a weekly notification reminding me to complete my quadrant check-in,
**So that** I maintain consistency.

**Priority:** Should (S3)
**Story Points:** 2

**Conditions of Satisfaction:**

- Given I have completed at least one assessment and notifications are enabled, When the configured day/time arrives (default: Sunday 7:00 PM) and I have not assessed this week, Then a notification is delivered: "How are your Body, Mind, Heart, and Spirit this week? Take 3 minutes for your Recovery Quadrant."
- Given I have already assessed this week, When the reminder time arrives, Then no notification is sent
- Given I tap the notification, When the app opens, Then I am taken directly to the assessment flow

---

### Story Point Summary

| Story | Title | Points | Priority | Sprint |
|---|---|---|---|---|
| S1 | Psychoeducation Screen | 3 | Should | 1 |
| S2 | Weekly Assessment | 8 | Must | 1 |
| S3 | Radar Chart | 5 | Must | 1 |
| S4 | Balance Score + Wellness Level | 3 | Must | 2 |
| S5 | Trend Tracking | 5 | Must | 2 |
| S6 | Activity Recommendations | 5 | Must | 2 |
| S7 | Today View Integration | 3 | Must | 2 |
| S8 | Weekly Notification | 2 | Should | 3 |
| **Total** | | **34** | | |

---

## 8. Feature Comparison Matrix

### Standard vs Premium Tier

| Capability | Standard | Premium |
|---|---|---|
| **Assessment** | 4-quadrant Likert + behavioral indicators | Same + AI follow-up questions based on low scores |
| **Visualization** | Radar chart + 8-week trend | Same + personalized insight annotations |
| **Recommendations** | Static activity mapping per quadrant | AI-generated personalized recommendations based on assessment history |
| **Reflections** | Optional one-sentence per quadrant | Same + AI-prompted deeper reflection questions |
| **Sharing** | Scores + wellness level to accountability partner | Same |

---

## 9. Implementation Roadmap

### Sprint 1: Foundation -- Assessment + Radar Chart

**Sprint Goal:** Users can complete a weekly four-quadrant assessment and see their results on a radar chart.

**Stories:** S1 (3 pts), S2 (8 pts), S3 (5 pts)
**Total Points:** 16

### Sprint 2: Intelligence -- Scoring, Trends, Recommendations, Today Integration

**Sprint Goal:** Users see balance scores, trend analysis, imbalance alerts, and activity recommendations.

**Stories:** S4 (3 pts), S5 (5 pts), S6 (5 pts), S7 (3 pts)
**Total Points:** 16

### Sprint 3: Polish -- Notification + Integration

**Sprint Goal:** Weekly notifications, accountability sharing, RHS integration.

**Stories:** S8 (2 pts) + S2 (RHS), S6 (Sharing)
**Total Points:** ~8 + integration work

---

## 10. Open Questions and Risks

### Open Questions

| # | Question | Impact | Status |
|---|---|---|---|
| OQ-1 | Should users be able to back-fill a missed week's assessment retroactively? | Affects FR-10 | Open |
| OQ-2 | What weight should the Quadrant carry in the Recovery Health Score? | Affects S2 integration | Open |
| OQ-3 | Should the assessment reminder be configurable (day of week, time)? | Affects S8 | Open |
| OQ-4 | Should we show LBI correlation alongside Quadrant trends in Sprint 2 or defer to Sprint 3? | Affects scope | Open |
| OQ-5 | When a user's score drops from "Growing" to "Struggling", should the app proactively suggest contacting their support network? | Affects recommendation urgency | Open |

### Risks

| # | Risk | Probability | Impact | Mitigation |
|---|---|---|---|---|
| R-1 | Assessment fatigue alongside LBI | Medium | High | Weekly frequency, differentiated purpose, brief completion time |
| R-2 | Self-reporting bias (inflated scores) | Medium | Medium | Behavioral indicators ground subjective ratings |
| R-3 | Feature perceived as redundant with LBI | Medium | Medium | Clear psychoeducation, different abstraction level |
| R-4 | Low engagement after initial use | Medium | Medium | Recommendations create feedback loop; Today view integration |
| R-5 | Radar chart accessibility | Low | Medium | Text alternative for VoiceOver |

---

## 11. Design Decisions Log

### D1: Quadrant Framework

**Chosen:** Hybrid model (Covey labels + SAMHSA grounding + BPS-S clinical foundation + Mark 12:30 scripture)

**Rationale:** "Body, Mind, Heart, Spirit" is the most intuitive, memorable, and scripturally resonant labeling. SAMHSA provides clinical credibility. Mark 12:30 provides the theological anchor. See research.md Section 7 for full analysis.

### D2: Assessment Frequency

**Options:** Daily, Weekly, Bi-weekly
**Chosen:** Weekly (one assessment per ISO week, Monday-Sunday)

**Rationale:** Daily assessment would cause fatigue alongside daily LBI check-ins. Bi-weekly is too infrequent for early recovery. Weekly provides enough data for trend analysis, aligns with the LBI weekly scoring cycle, and respects the user's time. The 3-minute target is sustainable weekly but would be burdensome daily.

### D3: Scoring Method

**Options:** (A) Likert only (1-10), (B) Behavioral indicators only, (C) Combined Likert + indicators
**Chosen:** (C) Combined

**Rationale:** Likert alone is fast but purely subjective. Indicators alone are more objective but feel like a checklist without personal assessment. Combined gives both the subjective self-rating and the behavioral grounding. Users rate how they feel (Likert) AND report what they did (indicators), creating a richer data point.

### D4: Number of Quadrants

**Options:** 3 (body/mind/spirit), 4 (body/mind/heart/spirit), 5+ (add purpose, environment)
**Chosen:** 4

**Rationale:** Four is the sweet spot -- comprehensive enough to cover whole-person wellness, simple enough for a weekly assessment. Three omits the relational dimension (critical for recovery). Five or more approaches the LBI's complexity level and loses the quadrant visual metaphor. Mark 12:30 specifically names four dimensions.

### D5: Fixed vs. Customizable Quadrants

**Chosen:** Fixed (Body, Mind, Heart, Spirit -- not user-editable)

**Rationale:** The four quadrants are the feature's structural backbone, grounded in Mark 12:30. Allowing customization would break the scoring consistency, the biblical framing, and the accountability sharing contract. Users who want granular customization should use the LBI feature. The Quadrant deliberately trades customization for simplicity and consistency.

### D6: Balance Score Formula

**Chosen:** Composite of mean and variance: `(mean / 10) * (1 - stdev / 4.5) * 100`

**Rationale:** The balance score must reward both high scores (doing well) AND low variance (balanced). A user scoring 10/10/10/2 is doing great in three areas but dangerously imbalanced. The formula penalizes variance while rewarding overall health. The 4.5 divisor for stdev normalizes the variance component (maximum possible stdev for 4 values in range 1-10 is approximately 4.5).

### D7: Reflection Privacy

**Chosen:** Reflections are NEVER shared with accountability partners. Only scores, wellness level, and trend direction are shareable.

**Rationale:** Reflections are intimate personal writing. Sharing them would discourage honest reflection. The scores provide accountability partners with sufficient signal ("Spirit is low this week") without exposing the user's inner processing.

---

## Appendix A: Mark 12:30 Quadrant Mapping

> "Love the Lord your God with all your **heart** and with all your **soul** and with all your **mind** and with all your **strength**." -- Mark 12:30 (NIV)

| Jesus' Word | Greek | Quadrant | Recovery Dimension |
|---|---|---|---|
| Heart (kardia) | kardia | Heart | Relational Connection -- loving God through loving others |
| Soul (psyche) | psyche | Spirit | Spiritual Vitality -- loving God in the deepest part of your being |
| Mind (dianoia) | dianoia | Mind | Mental Renewal -- loving God with your thoughts and understanding |
| Strength (ischys) | ischys | Body | Physical Stewardship -- loving God through bodily discipline and care |

---

## Appendix B: Wellness Level Reference

| Balance Score Range | Wellness Level | Color | Description |
|---|---|---|---|
| Mean >= 8.0 and StDev <= 1.5 | Flourishing | Green (#34C759) | Recovery thriving across all dimensions. Well-balanced and strong. |
| Mean >= 6.0 | Growing | Blue (#007AFF) | Steady progress. Some areas may need attention but overall positive trajectory. |
| Mean >= 4.0 | Rebuilding | Orange (#FF9500) | Multiple areas need strengthening. Focus on recommendations and reach out to support. |
| Mean < 4.0 | Struggling | Red (#FF3B30) | Significant attention needed. Consider contacting your sponsor, counselor, or support network. |
