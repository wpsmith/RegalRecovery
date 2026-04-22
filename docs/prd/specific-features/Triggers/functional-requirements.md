# Triggers Feature -- Functional Requirements Document

**Feature name:** Triggers
**Document type:** Functional Requirements Document (FRD)
**Date:** 2026-04-22
**Version:** 1.0
**Author:** Product
**Platform:** iOS (SwiftUI + SwiftData)
**Tiers:** Free (core) / Standard (analytics) / Premium+ (AI insights)
**OMTM:** Reduction in unmanaged trigger-to-urge escalation rate (target: 15% reduction within 90 days of consistent use)

---

## 1. Feature Overview

### 1.1 Problem Statement

Triggers -- internal states, external cues, and situational contexts that activate craving -- are the initiating event in the relapse process. Research consistently identifies trigger identification and management as the cornerstone of relapse prevention (Melemis, 2015; Carnes, 2010; Dye, Genesis Process). Marlatt's relapse taxonomy found that 59% of relapses were intrapersonal (with negative emotional states alone accounting for 37%), while Grimm and Shaham's incubation-of-craving research demonstrated that cue-induced craving actually *intensifies* over the first 60 days of abstinence rather than fading. This means the period when users most need trigger management tools is precisely when triggers are at peak intensity.

Despite this clinical reality, existing recovery apps offer minimal trigger support. The competitive landscape analysis (triggers-research.md, Section 4.1) found that no current consumer app provides structured, multi-layer trigger logging with pattern analysis and AI-powered insight generation. Most apps rely on timers and motivational quotes unaligned with any therapeutic framework; Baumel et al.'s 2019 JMIR study found median 30-day retention of just 3.3% for mental health apps.

**The cost of the problem:** Without structured trigger awareness, users experience triggers as unpredictable threats rather than decodable signals. This produces two harmful outcomes: (1) shame-driven underreporting, where users avoid acknowledging triggers because doing so feels like admitting failure, and (2) pattern blindness, where recurring trigger sequences that could be anticipated and disrupted remain invisible. Both outcomes increase the probability of the trigger-to-behavior cascade completing.

### 1.2 Business Hypothesis

By providing a fast, compassionate, multi-depth trigger logging and analysis system that integrates with existing recovery activities (urge logs, FASTER Scale, check-ins, journaling), Regal Recovery can help users develop trigger literacy -- the capacity to notice, label, and respond to triggers skillfully -- which the clinical literature identifies as the therapeutic goal that produces durable relapse prevention (Bowen et al., 2014 JAMA Psychiatry; Gustafson et al., 2014 JAMA Psychiatry).

**Expected OMTM impact:** 15% reduction in unmanaged trigger-to-urge escalation rate among users who log triggers at least 3 times per week for 90 days, measured by the ratio of logged triggers that are followed by urge logs within a 4-hour window versus those that are not.

### 1.3 Value Proposition

The Triggers feature reframes triggers from threats to teachers. Consistent with both the clinical evidence (MBRP, ACT, CBT-based relapse prevention) and the Christian recovery understanding of temptation versus sin, the feature treats every trigger experience as information about unmet needs and an opportunity for growth -- never as evidence of failure.

**For users in early recovery (0-24 months):** Fast trigger identification and immediate coping resource surfacing when trigger reactivity is at its neurobiological peak.

**For users in sustained recovery (24+ months):** Pattern analysis and deeper reflection tools that reveal the subtle erosion of recovery practices (Forgetting Priorities on the FASTER Scale) before it becomes acute.

**For accountability relationships:** Concrete, shareable trigger data that transforms accountability conversations from "How are you doing?" / "Fine" into specific, actionable discussion grounded in real patterns.

### 1.4 Clinical Foundation

This feature design draws on the following evidence base (detailed in triggers-research.md and triggers-teachers-research.md):

| Source | Key Finding | Feature Implication |
|--------|-------------|---------------------|
| Koob & Volkow (2016) | Triggers operate through mesolimbic dopamine sensitization that persists for years | Trigger management is positioned as a long-term practice, not a time-limited exercise |
| Grimm & Shaham (2001) | Cue-induced craving intensifies over the first 60 days of abstinence | Early recovery users (0-90 days) receive heightened support and education about trigger intensification |
| Melemis (2015) | Relapse is a three-stage process (emotional, mental, physical) with triggers as the initiating event | Trigger logging includes stage-of-relapse assessment and FASTER Scale correlation |
| Bowen et al. (2014) | MBRP outperformed standard relapse prevention at 12 months | The "trigger as teacher" reframe is the primary UX stance, not avoidance |
| Gustafson et al. (2014) | A-CHESS app with geofenced trigger awareness nearly halved risky drinking days | User-defined geofencing is included as an opt-in feature |
| Marlatt (1985) | 37% of relapses precipitated by negative emotional states alone | Emotional triggers are first-class citizens with rich subcategorization |
| Carnes (2010) | The addiction cycle (Preoccupation, Ritualization, Compulsive Behavior, Despair) maps trigger cascades | Trigger chain logging captures the sequential nature of the cycle |
| Dye (Genesis Process) | The FASTER Scale provides a 2-week minimum warning before relapse when used consistently | FASTER Scale integration provides unified risk assessment |
| Voon et al. (2014) | Compulsive sexual behavior shows the same neural cue-reactivity signature as substance addiction | The trigger concept applies to sex addiction with full neurobiological support |
| Nahum-Shani et al. (2018) | The JITAI framework defines six components for real-time adaptive interventions | Feature architecture follows JITAI: decision points, tailoring variables, intervention options, decision rules |

### 1.5 Design Principles

1. **Compassion in code.** A trigger is not a failure. Every piece of UX copy, every interaction pattern, and every data visualization reinforces this truth. The temptation-versus-sin distinction (1 Corinthians 10:13) is explicitly integrated into the logging experience.
2. **Depth on demand.** Quick logging for the moment of need (under 15 seconds); deep exploration for reflection time (5+ minutes). Never require depth; always offer it.
3. **Privacy by architecture.** Trigger data is encrypted at rest, user-controlled, and never shared without explicit consent. Location data is strictly opt-in. The user can delete any or all trigger data at any time.
4. **Growth orientation.** Trigger data tells a story of increasing self-knowledge and resilience, not a chronicle of vulnerability. Positive metrics (triggers navigated successfully, expanding coping repertoire, decreasing average intensity) are surfaced alongside frequency data.
5. **Connection over isolation.** Every trigger logging interaction offers a path to connection: share with a partner, call your sponsor, access community resources.
6. **Trigger as teacher.** Language draws from MBRP and ACT rather than pure avoidance framing. Triggers are data to be decoded, not dangers to be eliminated.

---

## 2. Functional Requirements

### 2.1 Personal Trigger Library (Trigger Identification and Cataloging)

| ID | Requirement | MoSCoW | Rationale |
|----|-------------|--------|-----------|
| FR-T-001 | The system shall provide a pre-populated trigger library containing 120 triggers organized across 7 categories (Emotional, Physical, Environmental, Relational, Cognitive, Spiritual, Situational), sourced from the canonical trigger taxonomy in `content/triggers/triggers-list.md`. | Must | CBT-based trigger identification requires a structured catalog. The 120-item taxonomy was developed from Carnes, Dye, Laaser, and SA/CR literature. |
| FR-T-002 | The system shall display a "Popular" subset of the 20 most commonly reported triggers (as defined in `content/triggers/triggers-list.md`) as the default quick-access view during trigger logging. | Must | Low-friction capture is the most critical UX principle; users must reach their most likely triggers within 1-2 taps. |
| FR-T-003 | The system shall allow the user to create custom triggers with a user-defined label and user-assigned category. Custom triggers shall be stored in the user's personal trigger library alongside the pre-populated items. | Must | Triggers are highly individual. Two people may share an emotional trigger but have completely different environmental triggers. Personalized trigger identification is a cornerstone of relapse prevention planning (Carnes, 2010). |
| FR-T-004 | The system shall allow the user to edit the label and category of custom triggers they have created. Pre-populated triggers shall not be editable. | Should | Supports evolving self-knowledge as recovery progresses. |
| FR-T-005 | The system shall allow the user to delete custom triggers they have created. Deleting a custom trigger shall not delete historical trigger log entries that reference it; those entries shall retain the trigger label as a static string. | Should | User control over their data; preserves historical accuracy. |
| FR-T-006 | The system shall learn from usage and surface the user's most frequently logged triggers at the top of the selection interface, dynamically reordering the list based on the user's personal logging history. After 10 or more trigger log entries, the "Popular" default view shall be replaced by the user's personal top triggers. | Should | Reduces selection time for repeat triggers; the list adapts to the individual. |
| FR-T-007 | The system shall allow the user to "pin" up to 10 triggers as favorites that always appear at the top of the selection interface, regardless of frequency-based ordering. | Could | Power users may want manual control over their quick-access list. |
| FR-T-008 | The system shall allow the user to hide pre-populated triggers that are not relevant to their experience, removing them from the selection interface without deleting them. Hidden triggers shall be recoverable from a "Show hidden" option. | Could | Reduces cognitive load by eliminating irrelevant items. |

### 2.2 Trigger Categories

| ID | Requirement | MoSCoW | Rationale |
|----|-------------|--------|-----------|
| FR-T-010 | The system shall organize triggers into the following 7 categories, consistent with the Marlatt IDTS taxonomy adapted for sex addiction recovery: **Emotional** (24 items), **Physical** (13 items), **Environmental** (17 items), **Relational** (18 items), **Cognitive** (17 items), **Spiritual** (13 items), **Situational** (18 items). | Must | Marlatt's categories are the clinical standard, enabling therapists to interpret patterns. The 7-category system extends Marlatt's internal/external taxonomy with spiritual and cognitive categories specific to SA and Celebrate Recovery contexts. |
| FR-T-011 | Each category shall be visually distinguished with a unique icon and color within the app's design system. Category colors shall be consistent across all Trigger feature screens (logging, library, analytics, insights). | Must | Visual differentiation enables rapid pattern recognition in analytics views. |
| FR-T-012 | The system shall support browsing the trigger library by category, displaying triggers grouped under their category headings with counts of items per category. | Must | Supports the trigger cataloging exercise that is part of CBT-based relapse prevention. |
| FR-T-013 | The system shall support a search/filter function within the trigger library, allowing the user to find triggers by text search across all categories. | Should | With 120+ items, scrolling alone is insufficient for discovery. |
| FR-T-014 | When creating a custom trigger (FR-T-003), the system shall require the user to assign it to one of the 7 predefined categories. Custom categories shall not be supported. | Must | Maintaining category consistency preserves the analytical value of category-based pattern detection and ensures compatibility with clinical interpretation frameworks. |

### 2.3 Trigger Intensity and Risk Rating

| ID | Requirement | MoSCoW | Rationale |
|----|-------------|--------|-----------|
| FR-T-020 | The system shall capture trigger intensity on a 1-10 integer scale during trigger logging. The scale shall use plain-language anchors: 1 = "Barely noticeable," 5 = "Moderate -- I feel the pull," 10 = "Overwhelming -- I need help now." | Must | Intensity rating is a validated component of ecological momentary assessment (EMA). The 1-10 scale aligns with the Penn Alcohol Craving Scale format and the SMART Recovery Urge Log. |
| FR-T-021 | The intensity input shall be rendered as a slider with the current numeric value displayed. The slider shall default to 5 (midpoint) on each new log entry. | Must | Slider input is faster than picker or text entry; defaulting to midpoint avoids anchoring bias toward either extreme. |
| FR-T-022 | The system shall apply the following risk classification based on intensity: 1-3 = Low (green), 4-6 = Moderate (amber), 7-10 = High (red). This classification shall drive intervention escalation (FR-T-070 through FR-T-074). | Must | Risk stratification enables proportioned intervention delivery consistent with the JITAI framework. At low intensity, a brief mindfulness reframe is sufficient; at high intensity, escalation to active coping and human contact is appropriate. |
| FR-T-023 | When the user logs a trigger with intensity >= 7, the system shall immediately surface the emergency coping toolkit (see FR-T-074) and display a prominent option to contact their accountability partner or call a crisis line. | Must | High-intensity triggers demand immediate support. Gustafson's A-CHESS RCT demonstrated the value of escalation at high distress thresholds. |
| FR-T-024 | The system shall not require an intensity rating to submit a trigger log. If intensity is not provided, the entry shall be recorded with intensity = null and excluded from intensity-based analytics. | Should | Reducing required fields to zero (beyond trigger selection) maximizes adoption. Some users will want to log the trigger name only, especially in acute distress. |

### 2.4 Trigger Logging (Core Logging Flow)

| ID | Requirement | MoSCoW | Rationale |
|----|-------------|--------|-----------|
| FR-T-030 | The system shall provide a trigger logging flow accessible from: (a) a floating action button (FAB) on the home screen, (b) the urge log flow as a linked entry, (c) the FASTER Scale check-in as a contextual prompt, (d) the activities list, and (e) a quick-action from the notification shade or widget. | Must | Multi-point access ensures the user can log triggers regardless of where they are in the app. The FAB provides the fastest path, consistent with the "one-tap reachable" principle from the A-CHESS and JITAI literature. |
| FR-T-031 | The minimum viable trigger log shall require only: (a) selection of one or more triggers from the personal trigger library. All other fields shall be optional. Target completion time for a minimum log: under 15 seconds. | Must | Low-friction capture is the single most critical UX requirement. Users experiencing triggers are in distress; cognitive load is high and capacity for form-filling is low. The research literature (triggers-research.md, Section 4.2) confirms that flows exceeding 30 seconds kill adoption. |
| FR-T-032 | The system shall support multi-trigger selection in a single log entry, allowing the user to select up to 10 triggers per entry. | Must | Triggers frequently co-occur. Capturing co-occurrence is essential for trigger chain analysis and cluster detection. |
| FR-T-033 | The trigger logging flow shall support three depth levels, selectable by the user through progressive disclosure: **Quick Log** (trigger selection + optional intensity, target: 10-15 seconds), **Standard Log** (adds context fields: mood/emotion, situation, who you were with, body sensation, response taken), **Deep Log** (adds journaling reflection, unmet need exploration, and coping strategy selection). | Must | Tiered depth matches the user's available time and emotional capacity. The research (triggers-research.md, Section 4.2) recommends variable depth with smart defaults. Quick log for the acute moment; deep log for reflection time. |
| FR-T-034 | The system shall automatically capture the following context with every trigger log entry without user input: (a) timestamp (date and time), (b) day of week, (c) time-of-day classification (early morning 5-8, morning 8-12, afternoon 12-17, evening 17-22, late night 22-5). | Must | Automatic context capture provides temporal pattern data without increasing user burden. Time-of-day classification enables the temporal heat map (FR-T-100). |
| FR-T-035 | The system shall optionally capture the user's approximate location category (home, work, car, hotel, other -- user-selectable, not GPS) during trigger logging. Location capture shall be presented as an optional tap-to-select field, never required. | Should | Location context is clinically valuable for environmental trigger pattern detection (home alone, hotel, office alone are among the most commonly reported acting-out contexts). User-selectable categories avoid the privacy burden of GPS while capturing the analytically useful signal. |
| FR-T-036 | The system shall support opt-in GPS-based location capture for trigger logging. When enabled, the system shall record the approximate location (rounded to 500-meter precision) and store it encrypted on-device only. GPS location data shall never be transmitted to the server. | Could | GPS data enables geofencing (FR-T-090) but carries significant privacy sensitivity. On-device-only storage with user-controlled deletion mitigates risk. Rounding to 500m prevents exact-address identification. |
| FR-T-037 | The Standard Log depth level shall include the following optional context fields: (a) current mood/emotion (selection from Feelings Wheel categories or quick-select list), (b) situation description (free text, max 500 characters), (c) who you were with (alone, spouse/partner, family, friends, coworkers, strangers, other), (d) body sensation location (selectable body map or text), (e) what you did in response (selection from coping strategies or free text). | Should | These fields capture the empirically validated tailoring core identified in the JITAI literature: craving + negative affect + contextual availability + self-efficacy. Mood/emotion captures affect; situation captures context; response captures self-efficacy. |
| FR-T-038 | The Deep Log depth level shall include the following additional fields beyond Standard: (a) "What need might this trigger be pointing to?" with Laaser's Seven Desires as selectable options (to be heard, affirmed, blessed, safe, touched, chosen, included) and a free-text option, (b) "What did this trigger teach you about yourself?" free-text reflection (max 1000 characters), (c) FASTER Scale quick-position indicator (Restoration / F / A / S / T / E), (d) coping strategy effectiveness rating (1-5: "Did the response help?"). | Should | The unmet-need exploration draws from Laaser's attachment-based trigger model and Jay Stringer's research connecting acting-out patterns to unresolved wounds. The "trigger as teacher" reflection implements the growth-oriented reframe supported by MBRP and PTG research. FASTER Scale correlation provides unified risk assessment. |
| FR-T-039 | Upon successful trigger log submission, the system shall display an affirming completion message that normalizes the trigger experience. Examples: "Trigger logged. Recognizing what you're experiencing is a recovery skill." / "Noticing a trigger is strength, not weakness." / "You saw it. You named it. That matters." The message shall rotate from a curated set and never use clinical or shame-inducing language. | Must | Combats the shame response that discourages honest reporting. The temptation-versus-sin distinction from Christian recovery theology is embedded in UX copy: experiencing a trigger is not a moral failure. |
| FR-T-040 | After displaying the affirming message, the system shall present contextual next-action options based on the logged intensity: Low (1-3): "Continue your day" (dismiss) + "Reflect in journal" + "Log another trigger." Moderate (4-6): Above + "Try a coping exercise" (link to breathing/grounding) + "Check in with FASTER Scale." High (7-10): "Reach out now" (contact accountability partner) + "Urge surfing exercise" + "Call crisis line" + "SOS alert." | Must | Intervention escalation proportioned to intensity follows the JITAI framework and A-CHESS model. Low-intensity triggers need acknowledgment; high-intensity triggers need immediate support pathways. |

### 2.5 Trigger-to-Coping Strategy Mapping

| ID | Requirement | MoSCoW | Rationale |
|----|-------------|--------|-----------|
| FR-T-050 | The system shall maintain a mapping between trigger categories and recommended coping strategies, sourced from evidence-based modalities: Emotional triggers -> emotion regulation (breathing, grounding, Feelings Wheel, urge surfing), Physical triggers -> self-care actions (eat, rest, move, HALT check), Environmental triggers -> environmental restructuring (leave situation, device-free action, change location), Relational triggers -> connection actions (call sponsor, accountability partner, attend meeting), Cognitive triggers -> cognitive restructuring (CBT coping cards, "play the tape forward," scripture meditation), Spiritual triggers -> spiritual practices (prayer, scripture, worship, fellowship), Situational triggers -> planning and preparation (review recovery plan, calendar risk assessment). | Must | The Three Circles model provides the clinical foundation: when triggered (middle circle/yellow), move to healthy behavior (outer circle/green). Category-specific coping recommendations ensure the suggested action addresses the type of vulnerability the trigger represents. |
| FR-T-051 | After logging a trigger, when the user selects "Try a coping exercise" (FR-T-040), the system shall present coping strategies matched to the trigger's category and intensity, ordered by relevance. | Must | Category-matched coping is more effective than generic suggestions. |
| FR-T-052 | The system shall allow the user to create personalized coping strategies and associate them with specific triggers in their personal library. When those triggers are subsequently logged, the user's custom coping strategies shall appear alongside the system defaults. | Should | Personalized relapse prevention planning requires individualized response protocols. The research (triggers-research.md, Section 3.3) identifies defining a specific planned response for each high-risk trigger as a standard of care. |
| FR-T-053 | After using a coping strategy, the system shall allow the user to rate its effectiveness (1-5 scale: "Did not help" to "Very helpful"). Over time, the system shall surface the user's highest-rated strategies first for each trigger category. | Should | Self-assessed effectiveness data enables personalized recommendation ordering. Users develop a curated toolkit of what works for them. |
| FR-T-054 | The system shall provide direct in-app access to the following coping tools from the trigger logging flow without navigating away: (a) guided breathing exercise, (b) 5-4-3-2-1 grounding exercise, (c) urge surfing audio guide, (d) HALT quick check, (e) one-tap accountability partner contact, (f) scripture meditation (contextual verse matched to trigger category), (g) crisis hotline display (988, SAMHSA). | Must | Immediate access to evidence-based interventions at the moment of trigger is the core therapeutic mechanism. Research from the A-CHESS RCT demonstrated that in-context coping delivery significantly reduces risky behavior. |

### 2.6 Real-Time Trigger Logging (During an Urge)

| ID | Requirement | MoSCoW | Rationale |
|----|-------------|--------|-----------|
| FR-T-060 | When a user initiates an urge log (existing feature), the system shall prompt the user to identify associated triggers from their personal trigger library as part of the urge logging flow. Trigger selection within the urge log shall be optional. | Must | Linking triggers to urges captures the antecedent-behavior chain that is central to CBT functional analysis. The existing `UrgeLogViewModel` already has a `triggers` field but currently uses a static 8-item list; this requirement replaces it with the full personal trigger library. |
| FR-T-061 | When triggers are selected within the urge log flow, the system shall create a linked trigger log entry and a linked urge log entry, associated by a shared correlation identifier. Both entries shall be independently queryable but cross-referenced. | Must | Linked entries enable the trigger-to-urge escalation analysis that defines the OMTM. The correlation ID allows the system to determine which triggers precede urges and which do not. |
| FR-T-062 | The system shall support initiating a trigger log that transitions into an urge log if the user indicates the trigger has produced an active urge. After submitting a trigger log, one of the next-action options (FR-T-040) shall be "This became an urge -- log it now," which pre-populates the urge log with the trigger data. | Should | Supports the clinical reality that triggers and urges are related but distinct phenomena. A trigger is the cue; an urge is the craving response. Not all triggers produce urges. This distinction reduces the shame of urge logging (it is an escalation of a normal trigger experience, not a sudden failure). |
| FR-T-063 | When a post-mortem analysis is initiated (following a relapse event), the system shall auto-populate the trigger analysis section with all trigger log entries from the 72-hour window preceding the relapse event, organized chronologically. The user shall be able to add, remove, or annotate triggers in the post-mortem context. | Should | Post-mortem auto-population uses real-time data to construct the trigger chain that preceded the relapse, replacing the unreliable retrospective self-report that is subject to memory bias and mood-congruent recall. The 72-hour window is clinically appropriate given that Dye's FASTER Scale progression typically spans days to weeks. |

### 2.7 Trigger Pattern Analysis and Insights

| ID | Requirement | MoSCoW | Rationale |
|----|-------------|--------|-----------|
| FR-T-070 | The system shall provide a Trigger Insights dashboard accessible from the Triggers feature home screen, displaying: (a) total triggers logged (cumulative and for the selected period), (b) triggers navigated successfully (not followed by an urge log within 4 hours), (c) average trigger intensity for the selected period, (d) top 5 triggers by frequency, (e) category distribution chart. | Must | Pattern visibility is the primary analytical value of trigger logging. Without insights, logging becomes a journaling exercise rather than a self-knowledge tool. The "triggers navigated successfully" metric is a positive, growth-oriented measure that counterbalances the inherently negative framing of trigger frequency. |
| FR-T-071 | The system shall display a temporal heat map showing trigger frequency by hour-of-day (rows) and day-of-week (columns), color-coded by frequency (lighter = fewer, darker = more). The heat map shall be filterable by date range (7/30/90 days) and by trigger category. | Must | Temporal heat maps surface patterns invisible in list views. "You experience the most triggers between 10 PM and midnight on weekdays" is immediately actionable. This visualization pattern is recommended by both research documents. |
| FR-T-072 | The system shall display intensity trend lines showing average trigger intensity over 7/30/90-day windows. Declining intensity, even if frequency remains stable, shall be highlighted as a positive indicator: "Your average trigger intensity has decreased by X% this month." | Must | Intensity trend is a more meaningful resilience metric than frequency alone. A person whose trigger frequency is stable but intensity is declining is building coping capacity. |
| FR-T-073 | The system shall generate natural-language weekly insight summaries based on trigger log data, covering: (a) trigger frequency trend compared to the previous week, (b) most common trigger and its category, (c) time-of-day pattern observation if one exists, (d) one growth-oriented observation (e.g., "You navigated 12 triggers this week without escalation -- your coping skills are growing"). | Should | Natural-language insights are more accessible than raw data for most users. The growth-oriented observation implements the trigger-as-teacher stance. |
| FR-T-074 | The system shall detect and surface the following rule-based alerts: (a) "You have logged X triggers today, which is above your Y-day average. Consider reaching out to your accountability partner." (threshold: > 2x rolling 7-day daily average), (b) "Your trigger intensity has been trending upward over the past 7 days." (threshold: 3+ consecutive days of increasing average), (c) "You have not logged a trigger in X days. Check in with yourself -- are things going well, or have you stopped noticing?" (threshold: 7+ days without a log after establishing a baseline of 3+ logs/week). | Should | Rule-based alerts represent Phase 1 of the JITAI implementation. These are conservative, theory-driven decision rules (Nahum-Shani et al., 2018) that surface clinically meaningful patterns without requiring ML. The "silence alert" addresses the clinical concern that absence of trigger logging may indicate disengagement rather than well-being. |
| FR-T-075 | The system shall correlate trigger log data with FASTER Scale check-in data, displaying a combined view showing: (a) trigger frequency and intensity plotted alongside FASTER Scale assessed stage over time, (b) an alert when increasing trigger load coincides with FASTER Scale progression (e.g., "Your trigger frequency has increased this week and your FASTER Scale position has moved from Anxiety to Speeding Up. This pattern warrants attention."). | Should | The FASTER Scale's predictive value (minimum 2-week warning before relapse when used consistently, per Dye) combined with trigger frequency data provides a unified risk trajectory view that neither data stream provides alone. |
| FR-T-076 | The Trigger Insights dashboard shall provide selectable time windows: 7 days, 30 days, 90 days, and "All time." All analytics shall recalculate for the selected window. | Must | Users in early recovery need short-window views; users in sustained recovery benefit from long-term trend analysis. |
| FR-T-077 | The system shall track and display a "trigger resilience" metric: the percentage of logged triggers that were NOT followed by an urge log within 4 hours. This metric shall be prominently displayed as a positive achievement. | Should | Positive framing of trigger data. A rising resilience percentage is direct evidence of growing recovery capital. |
| FR-T-078 | The system shall detect trigger co-occurrence clusters: groups of 2-3 triggers that are frequently logged together in the same entry or within a 2-hour window. The top 3 clusters shall be surfaced in the Insights dashboard with an explanatory note (e.g., "When you experience work stress, you often also experience conflict with spouse and late-night vulnerability within the same day."). | Could | Trigger chain analysis reveals cascade patterns. Identifying that work stress reliably leads to spousal conflict, which reliably leads to late-night vulnerability, makes the entire chain interruptible at its earliest point. |

### 2.8 Proactive Trigger Warnings and Alerts

| ID | Requirement | MoSCoW | Rationale |
|----|-------------|--------|-----------|
| FR-T-080 | The system shall support time-based proactive alerts. If the user's trigger history shows a pattern of elevated trigger frequency during a specific time window (e.g., 10 PM - midnight), the system shall deliver a gentle notification 30 minutes before that window begins: "The next couple of hours have historically been a challenging time for you. Your coping plan is ready if you need it." | Should | Proactive intervention before the trigger window opens is more effective than reactive support after the trigger has already activated the reward pathway. This implements the JITAI "decision point" component. |
| FR-T-081 | Time-based proactive alerts (FR-T-080) shall activate only after a minimum of 30 trigger log entries over at least 14 days, providing sufficient data for pattern detection. | Must | Prevents false positives from insufficient data. |
| FR-T-082 | The system shall support calendar-based proactive alerts. If the user tags upcoming calendar events as potentially triggering (e.g., "Business travel next week," "Anniversary of disclosure"), the system shall deliver a preparation prompt 24 hours before the event: "You have [event] tomorrow. Would you like to review your coping plan?" | Should | Calendar integration addresses seasonal and life-event trigger patterns documented in the research. Advance preparation is a standard relapse prevention practice. |
| FR-T-083 | All proactive alerts shall use completely non-identifying notification language. Notifications shall never contain the words "trigger," "recovery," "addiction," "relapse," or any clinical terminology visible on the lock screen. Example: "Your evening check-in is ready" rather than "Trigger alert for high-risk time window." | Must | Notification privacy is a non-negotiable safety requirement. Users may be in environments where visible recovery-related notifications create real danger (workplace, family settings, partner surveillance). |
| FR-T-084 | The user shall be able to disable any category of proactive alert independently (time-based, calendar-based) and shall be able to set "quiet hours" during which no proactive alerts are delivered. | Must | User agency over notification frequency prevents alert fatigue, which the research identifies as a significant risk (Bidargaddi et al., 2018 found notification effects decay over weeks without user control). |
| FR-T-085 | If GPS-based location capture is enabled (FR-T-036), the system shall support user-defined geofenced locations marked as "high-risk." When the user enters a geofenced area, the system shall deliver an on-device notification: "You are near a location you have marked as challenging. Your coping tools are here for you." Geofence matching shall occur entirely on-device; no location data shall be transmitted to the server. | Could | User-defined geofences outperform generic ones (62% vs. 49% accuracy per Wray et al., 2019). On-device-only processing addresses the extreme privacy sensitivity of location-to-trigger correlation. A-CHESS's geofencing feature was a key component of its RCT success. |

### 2.9 Integration with Existing Features

| ID | Requirement | MoSCoW | Rationale |
|----|-------------|--------|-----------|
| FR-T-090 | The system shall integrate trigger logging with the existing urge log feature. When triggers are selected during urge logging (FR-T-060), they shall be recorded in both the urge log and the trigger log, with a bidirectional cross-reference. Trigger analytics shall include triggers logged from the urge log flow. | Must | The existing `UrgeEntry` model already captures `triggers: [String]`; this requirement upgrades that field from a static 8-item list to the full 120-item personal trigger library and ensures data flows to the Trigger analytics system. |
| FR-T-091 | The system shall integrate trigger data with FASTER Scale check-ins. When a user completes a FASTER Scale check-in, the system shall display any triggers logged within the same day as contextual information: "You logged [trigger names] earlier today. Does this connect to where you are on the FASTER Scale?" | Should | Bidirectional correlation between triggers and FASTER Scale position provides the unified risk trajectory described in triggers-research.md Section 4.6. |
| FR-T-092 | The system shall integrate trigger data with check-in activities (FANOS, FITNAP, evening review). The evening review shall include a trigger summary for the day: "You logged X triggers today: [names]. How did you handle them?" FITNAP check-ins already include an explicit "Triggers" component; the system shall pre-populate it with any triggers logged since the last check-in. | Should | FITNAP explicitly covers Feelings, Information, Triggers, Needs, Amends, and Praise. Pre-populating the Triggers component with actual logged data transforms a retrospective recall exercise into a review of real data. |
| FR-T-093 | The system shall integrate trigger data with journaling. Trigger log entries shall be surfaceable as journal prompts: "Earlier today you logged [trigger]. What was going on for you?" The trigger-specific journal prompt section (content/prompts.md, Section 7) shall reference the user's most recently logged triggers. | Should | Journaling provides narrative depth that structured logging cannot. Connecting trigger logs to journal prompts implements the "multi-layer depth" principle: quick log captures the event, journal captures the meaning. |
| FR-T-094 | The system shall integrate trigger data with the Three Circles feature. Triggers from the user's personal library shall be mappable to their middle-circle (yellow) items. When logging a trigger that maps to a yellow-circle item, the system shall surface the user's corresponding outer-circle (green) behaviors as recommended coping actions. | Could | The Three Circles model explicitly places triggers in the middle circle. Connecting trigger logs to the user's personal Three Circles definitions provides clinically grounded coping recommendations that the user has already identified as healthy alternatives. |
| FR-T-095 | The system shall integrate trigger data with the accountability partner feature. The user shall be able to share trigger data with their accountability partner at three granularity levels: (a) summary only (count + category breakdown), (b) summary + trigger names, (c) full detail (triggers + intensity + context + journal reflections). Sharing shall be user-initiated (never automatic) except for the opt-in high-intensity alert (FR-T-023). | Must | Accountability sharing transforms private trigger data into relational support. The three-tier granularity model is consistent with the FASTER Scale sharing model and gives the user control over their vulnerability. |
| FR-T-096 | The system shall integrate trigger log timestamps with the calendar/activity view. Trigger logs shall appear as calendar activity entries alongside check-ins, urge logs, journal entries, and other activities. | Must | The calendarActivities collection pattern (documented in schema-design.md) requires a new `activityType: "TRIGGER"` entry for trigger logs. This provides a unified daily view of all recovery activities. |
| FR-T-097 | The system shall integrate trigger data with the PCI (Personal Craziness Index) tracking feature when implemented. Rising PCI scores shall be correlated with trigger frequency and surfaced as a combined vulnerability indicator. | Won't (this scope) | PCI integration requires PCI to be implemented first. Documenting the integration point here for future feature planning. |
| FR-T-098 | The system shall integrate trigger data with the recovery AI agent (Premium+ subscription). The agent shall have read access to the user's trigger history and patterns, enabling it to reference trigger data in FASTER Scale conversations: "I've noticed your trigger intensity has been climbing this week. Can we talk about what's been going on?" | Won't (this scope) | Agent integration is a Premium+ feature dependent on the recovery agent implementation. Documenting the API contract here for future feature planning. The agent shall access trigger data through the same read APIs used by the analytics dashboard. |

### 2.10 Trigger Management (CRUD Operations)

| ID | Requirement | MoSCoW | Rationale |
|----|-------------|--------|-----------|
| FR-T-100 | The system shall provide a Trigger Log History view displaying all trigger log entries in reverse chronological order, with each entry showing: trigger name(s), intensity (if provided), category icon/color, timestamp, and a truncated context summary (if provided). | Must | History view enables retrospective review and serves as the data source for accountability conversations. |
| FR-T-101 | The system shall allow the user to view the full detail of any historical trigger log entry, including all context fields, journal reflections, linked urge logs, and coping strategy used. | Must | Full detail view supports post-mortem analysis and therapeutic review. |
| FR-T-102 | The system shall allow the user to edit a historical trigger log entry within 24 hours of creation. Editable fields: trigger selection, intensity, context fields, journal reflections. Timestamp and automatic context (date, time-of-day classification) shall not be editable. After 24 hours, entries become read-only to preserve data integrity. | Should | A 24-hour edit window allows the user to add context during reflection while preserving the integrity of real-time data for pattern analysis. |
| FR-T-103 | The system shall allow the user to delete individual trigger log entries. Deletion shall be confirmed with a single confirmation dialog. Deleted entries shall be permanently removed from local and remote storage within 24 hours. | Must | User control over their data is a non-negotiable privacy requirement. |
| FR-T-104 | The system shall provide a "Delete all trigger data" option in settings. This shall permanently erase all trigger log entries, custom triggers, coping strategy ratings, and trigger-related analytics from local and remote storage within 24 hours. A two-step confirmation flow shall explain that the action is permanent. | Must | Bulk deletion supports the user's right to full data control. The two-step confirmation prevents accidental data loss. |
| FR-T-105 | The system shall provide a data export function allowing the user to export all trigger log data in a machine-readable format (JSON) and a human-readable format (PDF summary). The export shall include all log entries with full detail and analytics summaries. | Could | Data portability supports the user's right to access and move their own data. PDF export enables sharing with therapists who do not use the app. |

### 2.11 Offline-First Requirements

| ID | Requirement | MoSCoW | Rationale |
|----|-------------|--------|-----------|
| FR-T-110 | All trigger logging flows (quick, standard, deep) shall function fully offline. Trigger log entries shall be persisted to SwiftData local storage immediately upon submission. | Must | Offline-first is an architectural principle of the app. Triggers occur regardless of network connectivity. The user must be able to log triggers at any time, in any location. |
| FR-T-111 | The personal trigger library (pre-populated + custom triggers) shall be available offline from first app launch. The 120-item canonical library shall be bundled with the app binary. | Must | The trigger selection interface must work without network access. |
| FR-T-112 | Trigger analytics (FR-T-070 through FR-T-078) shall be computed on-device from local SwiftData and available offline. Analytics shall not depend on server-side computation. | Must | Analytics computed on-device means all pattern insights are available offline, which is essential for users in environments with limited connectivity (rural areas, travel, areas with poor signal). |
| FR-T-113 | When network connectivity is restored, the system shall sync trigger log entries to the server via the SyncEngine. Sync shall use the app's standard conflict resolution strategy. For trigger logs, conflict resolution shall use union merge: if a trigger log exists on-device but not on the server, it is synced up; if it exists on both with different content, the most recent modification wins (LWW). | Must | Consistent with the app's documented offline sync strategy (CLAUDE.md: "Union merge for relapse/urge logs, most-conservative for sobriety dates, LWW for profile"). Trigger logs follow the same union-merge principle as urge logs to prevent data loss. |
| FR-T-114 | Coping strategy resources that do not require network access (breathing exercise instructions, grounding technique steps, scripture text, crisis hotline numbers) shall be bundled with the app binary and available offline. Audio-guided exercises shall be cached on first use. | Must | The coping toolkit must be available at the moment of need. A user logging a high-intensity trigger while offline must still receive useful intervention resources. |

### 2.12 Trigger Education and Onboarding

| ID | Requirement | MoSCoW | Rationale |
|----|-------------|--------|-----------|
| FR-T-120 | The system shall provide a first-time onboarding flow when the user opens the Triggers feature for the first time. The onboarding shall cover: (a) what triggers are in plain language (not clinical terminology), (b) the temptation-versus-sin distinction ("Recognizing a trigger is a recovery skill, not a failure"), (c) the three depth levels of logging, (d) how to access coping tools, (e) how trigger data stays private. The onboarding shall be skippable and re-accessible from a help icon. | Must | Onboarding reduces first-use anxiety and establishes the growth-oriented framing from the first interaction. The privacy reassurance is essential given the extreme sensitivity of trigger data. |
| FR-T-121 | The system shall provide educational content about trigger categories, accessible from the Trigger Library. Each category shall have a brief (150-300 word) explanation drawing from the content in `content/triggers/about.md`, written in plain language with a compassionate tone. | Should | Education supports the trigger-as-teacher stance. Users who understand *why* loneliness is a trigger (attachment needs, isolation of the addiction) are better equipped to address the root cause. |
| FR-T-122 | The system shall provide a "Trigger 101" educational module accessible from the Triggers feature, covering: the neurological basis of triggers in plain language (sensitization, conditioned response), the HALT framework as a daily check, the distinction between triggers and urges, the Three Circles context for triggers (middle circle), and the incubation-of-craving phenomenon (triggers intensify before they improve). Content shall be drawn from `content/triggers/about.md` and adapted for in-app presentation. | Could | Psychoeducation about trigger neuroscience reduces shame by externalizing the experience: "This is your brain's conditioning, not a character flaw." Educating about incubation of craving prevents the dangerous assumption that early recovery difficulty means personal failure. |
| FR-T-123 | For users in their first 90 days of sobriety (as determined by their sobriety start date), the system shall display a contextual message in the Trigger Insights dashboard: "Trigger intensity often increases during the first 60-90 days of recovery. This is a well-documented neurological process, not a sign of failure. It gets better." | Should | Grimm and Shaham's incubation-of-craving research shows that cue-induced craving peaks at 60-90 days. Users who do not know this may interpret increasing difficulty as evidence that recovery is not working. This contextual message normalizes the experience. |

---

## 3. Non-Functional Requirements

### 3.1 Privacy and Security

| ID | Requirement | MoSCoW |
|----|-------------|--------|
| NFR-T-001 | All trigger log data shall be encrypted at rest using AES-256 or equivalent encryption via SwiftData's encrypted storage. | Must |
| NFR-T-002 | All trigger log data transmitted to the server shall be encrypted in transit using TLS 1.3. | Must |
| NFR-T-003 | GPS location data (FR-T-036) shall be stored encrypted on-device only and shall never be transmitted to the server. | Must |
| NFR-T-004 | Trigger-related push notifications shall use completely non-identifying language. No notification shall contain the words "trigger," "recovery," "addiction," "relapse," "sexual," "sobriety," or any clinical terminology visible on the lock screen. | Must |
| NFR-T-005 | The system shall support the app's biometric or PIN lock as a secondary authentication layer before displaying trigger log history or analytics. | Should |
| NFR-T-006 | The system shall not perform analytics on user-entered free-text content (situation descriptions, journal reflections) for any purpose other than displaying it back to the user. No NLP processing, sentiment analysis, or text mining shall be performed on free-text fields without explicit user consent for a specific purpose. | Must |
| NFR-T-007 | The system shall comply with the app's privacy-by-architecture principle: all data sharing is opt-in, no analytics on user text, no default access. Trigger data shall never be shared with any third party, including for research purposes, without explicit informed consent. | Must |
| NFR-T-008 | When the user deletes trigger data (FR-T-103, FR-T-104), the data shall be permanently erased from all local and remote storage within 24 hours. Deletion shall include any derived analytics or cached computations that reference the deleted entries. | Must |

### 3.2 Performance

| ID | Requirement | MoSCoW |
|----|-------------|--------|
| NFR-T-010 | The trigger logging flow shall render and be interactive within 500ms of user initiation on devices from the past 3 years. | Must |
| NFR-T-011 | The trigger selection interface shall render the full personal library (120+ items with custom additions) with smooth scrolling (60fps) and no perceptible lag during search/filter operations. | Must |
| NFR-T-012 | Trigger analytics (heat maps, trend lines, category charts) shall compute and render within 2 seconds for up to 1,000 trigger log entries. | Must |
| NFR-T-013 | The system shall maintain acceptable performance with up to 10,000 trigger log entries per user (approximately 3 years of daily logging at 10 entries/day). | Should |
| NFR-T-014 | Trigger log submission (SwiftData write) shall complete within 100ms to ensure the affirming completion message appears without perceptible delay. | Must |

### 3.3 Accessibility

| ID | Requirement | MoSCoW |
|----|-------------|--------|
| NFR-T-020 | All Trigger feature screens shall meet WCAG 2.1 AA compliance. | Must |
| NFR-T-021 | All interactive elements (trigger chips, intensity slider, buttons, coping tool links) shall have minimum 44x44pt touch targets. | Must |
| NFR-T-022 | The intensity slider (FR-T-021) shall be accessible via VoiceOver with clear value announcements ("Intensity: 5 of 10, Moderate"). | Must |
| NFR-T-023 | Trigger category colors shall meet WCAG AA contrast ratios against the background and shall be distinguishable in both light and dark modes. Color shall never be the sole means of conveying information; icons and labels shall accompany all color-coded elements. | Must |
| NFR-T-024 | The temporal heat map (FR-T-071) shall provide a VoiceOver-accessible alternative representation (e.g., sorted list of highest-frequency time slots). | Should |
| NFR-T-025 | All text in the Trigger feature shall support Dynamic Type scaling. | Must |

### 3.4 Reliability

| ID | Requirement | MoSCoW |
|----|-------------|--------|
| NFR-T-030 | The trigger logging flow shall never lose user data. If the app is backgrounded or terminated during logging, any partially completed entry shall be recoverable on next launch. | Must |
| NFR-T-031 | If a trigger log fails to sync to the server, the system shall retry with exponential backoff (up to 5 attempts). Failed syncs shall not produce user-visible error messages unless they persist for 24+ hours, and even then, the message shall be non-alarming: "Some of your data is waiting to sync. It will be saved when connectivity returns." | Must |
| NFR-T-032 | Compassionate error states: all error messages within the Trigger feature shall avoid clinical, technical, or shame-inducing language. "Your experience has been saved" is preferred over "Trigger log submission failed." | Must |

---

## 4. Data Model Considerations

### 4.1 SwiftData Models (iOS Local Storage)

The following models are needed for on-device persistence. All models use SwiftData with encrypted storage.

**TriggerDefinition** (Personal Trigger Library)

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Unique identifier |
| `label` | String | Display label (e.g., "Stress," "Home alone") |
| `category` | TriggerCategory (enum) | One of: emotional, physical, environmental, relational, cognitive, spiritual, situational |
| `isCustom` | Bool | Whether this trigger was created by the user |
| `isPinned` | Bool | Whether the user has pinned this trigger for quick access |
| `isHidden` | Bool | Whether the user has hidden this trigger |
| `useCount` | Int | Number of times this trigger has been logged (for frequency-based ordering) |
| `lastUsed` | Date? | Timestamp of most recent log (for recency-based ordering) |
| `createdAt` | Date | Creation timestamp |
| `linkedCopingStrategies` | [CopingStrategy] | User-defined coping strategies associated with this trigger |

**TriggerLogEntry** (Individual Trigger Log)

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Unique identifier |
| `timestamp` | Date | When the trigger was logged |
| `dayOfWeek` | Int | Computed from timestamp (1=Sunday, 7=Saturday) |
| `timeOfDaySlot` | TimeOfDaySlot (enum) | earlyMorning, morning, afternoon, evening, lateNight |
| `triggers` | [TriggerReference] | Array of trigger IDs + labels (label stored as snapshot to survive deletion) |
| `intensity` | Int? | 1-10, nullable if not provided |
| `riskLevel` | RiskLevel (enum)? | Computed: low (1-3), moderate (4-6), high (7-10), null if no intensity |
| `logDepth` | LogDepth (enum) | quick, standard, deep |
| `mood` | String? | Selected mood/emotion (standard+ depth) |
| `situation` | String? | Free-text situation context (standard+ depth) |
| `socialContext` | SocialContext (enum)? | alone, spouse, family, friends, coworkers, strangers, other |
| `bodySensation` | String? | Body sensation description or location (standard+ depth) |
| `responseTaken` | String? | What the user did in response (standard+ depth) |
| `copingStrategyUsed` | CopingStrategy? | Selected coping strategy (standard+ depth) |
| `copingEffectiveness` | Int? | 1-5 effectiveness rating (deep depth) |
| `unmetNeed` | String? | Laaser's Seven Desires selection or free text (deep depth) |
| `teacherReflection` | String? | "What did this trigger teach you?" free text (deep depth) |
| `fasterPosition` | FASTERStage (enum)? | Quick FASTER position at time of trigger (deep depth) |
| `locationCategory` | LocationCategory (enum)? | home, work, car, hotel, other (optional) |
| `gpsCoordinate` | CLLocationCoordinate2D? | Rounded to 500m, on-device only, never synced |
| `linkedUrgeLogId` | UUID? | Cross-reference to urge log entry if linked |
| `linkedPostMortemId` | UUID? | Cross-reference to post-mortem if referenced |
| `syncStatus` | SyncStatus (enum) | pending, synced, failed |
| `createdAt` | Date | Immutable creation timestamp (FR2.7 compliance) |
| `modifiedAt` | Date | Last modification timestamp |

**CopingStrategy** (User-Defined Coping Plans)

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Unique identifier |
| `label` | String | User-defined label |
| `description` | String? | Optional description |
| `category` | TriggerCategory | Associated trigger category |
| `isSystem` | Bool | Whether this is a system-provided strategy |
| `effectivenessSum` | Int | Sum of effectiveness ratings |
| `effectivenessCount` | Int | Count of effectiveness ratings (average = sum/count) |
| `linkedTriggerIds` | [UUID] | Triggers this strategy is associated with |
| `createdAt` | Date | Creation timestamp |

**Geofence** (User-Defined High-Risk Locations)

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Unique identifier |
| `label` | String | User-defined label (e.g., "Old neighborhood") |
| `coordinate` | CLLocationCoordinate2D | Center point |
| `radiusMeters` | Double | Geofence radius (default 200m) |
| `isActive` | Bool | Whether alerts are enabled |
| `createdAt` | Date | Creation timestamp |

### 4.2 Enumerations

```
TriggerCategory: emotional, physical, environmental, relational, cognitive, spiritual, situational
TimeOfDaySlot: earlyMorning (5-8), morning (8-12), afternoon (12-17), evening (17-22), lateNight (22-5)
RiskLevel: low, moderate, high
LogDepth: quick, standard, deep
SocialContext: alone, spouse, family, friends, coworkers, strangers, other
LocationCategory: home, work, car, hotel, other
FASTERStage: restoration, forgettingPriorities, anxiety, speedingUp, tickedOff, exhausted, relapse
SyncStatus: pending, synced, failed
```

### 4.3 Server-Side Schema (MongoDB)

The trigger log entry follows the existing collection-per-entity pattern:

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `TRIGGER#<ISO8601 timestamp>` |
| entityType | `TRIGGER` |

**Calendar Activity Entry:**
```json
{
  "userId": "u_12345",
  "date": "2026-04-22",
  "activityType": "TRIGGER",
  "timestamp": "2026-04-22T22:30:00Z"
}
```

**Access Patterns:**

| Pattern | Operation | Key Condition |
|---------|-----------|---------------|
| Get recent triggers | find | PK=USER#{userId}, SK begins_with TRIGGER#, ScanIndexForward=false |
| Get triggers by date range | find | PK=USER#{userId}, SK between TRIGGER#{start} and TRIGGER#{end} |
| Get triggers by category | find | PK=USER#{userId}, SK begins_with TRIGGER#, filter on category |
| Get trigger-urge correlations | find | PK=USER#{userId}, join on linkedUrgeLogId |

**Note:** GPS coordinate data (FR-T-036) is explicitly excluded from the server-side schema. It exists only in the on-device SwiftData model.

---

## 5. UI/UX Considerations

### 5.1 Trigger Logging Flow (Quick Log)

1. User taps FAB or "Log a trigger" entry point
2. **Screen 1: Trigger Selection.** Grid/list of triggers. Top section: user's pinned/most-frequent triggers (max 10). Below: "Popular" or personal top triggers. Below: "All triggers" expandable by category. Each trigger is a tappable chip that toggles selected/unselected state. Multi-select supported. Search bar at top for text filtering.
3. **Screen 1 (continued): Intensity Slider.** Below the trigger selection, a horizontal slider (1-10) with color gradient (green-amber-red) and plain-language anchor labels. Optional -- user can skip by tapping "Log without intensity."
4. **Screen 1 (continued): Submit.** Single "Log it" button. Below: expandable "Add more detail" section that reveals Standard Log fields (FR-T-037).
5. **Confirmation overlay.** Affirming message (FR-T-039) + contextual next actions (FR-T-040) based on intensity.

**Design goal:** Trigger selection + intensity + submit on a single screen. No multi-step wizard. No page transitions for the minimum viable log.

### 5.2 Trigger Logging Flow (Standard and Deep)

Standard and Deep depth fields are presented as expandable sections below the Quick Log submit area, using progressive disclosure. The user can expand any section without expanding all. Fields are clearly labeled with concise helper text.

**Standard additions:** Mood selector (horizontal scroll of emotion chips), Situation (free text with placeholder: "What was happening?"), Social context (horizontal chip selector), Body sensation (tappable body outline or free text), Response taken (free text with placeholder: "What did you do?").

**Deep additions:** Unmet need (horizontal scroll of Laaser's Seven Desires as labeled icons), "What did this trigger teach you?" (free text area), FASTER position (segmented control: R / F / A / S / T / E), Coping effectiveness (1-5 star rating, appears only if a coping strategy was selected).

### 5.3 Trigger Library View

Tab-based navigation: "My Triggers" (filtered to pinned + frequently used) | "All Triggers" (full library by category) | "Custom" (user-created triggers).

Each trigger displays: category icon, label, use count badge, pinned indicator. Swipe actions: pin/unpin, hide (pre-populated), edit/delete (custom).

### 5.4 Trigger Insights Dashboard

**Header metrics row:** Total triggers (period), Navigated successfully (%), Average intensity, Trend arrow (up/down/stable vs. previous period).

**Heat map section:** 7-column (days) x 5-row (time slots) grid, color-coded by frequency. Tappable cells expand to show trigger details for that time slot.

**Category distribution:** Horizontal bar chart or donut chart showing relative frequency by category. Tappable categories drill into category-specific history.

**Intensity trend:** Line chart showing 7/30/90-day rolling average intensity. Declining trend highlighted in green with encouraging label.

**Top triggers:** Ranked list of top 5 triggers by frequency for the selected period, with trend arrows and mini-sparklines.

**Weekly insight card:** Natural-language summary card (FR-T-073) with growth-oriented observation.

### 5.5 Color and Iconography

| Category | Icon Concept | Color |
|----------|-------------|-------|
| Emotional | Heart | Indigo |
| Physical | Body | Teal |
| Environmental | Location pin | Green |
| Relational | People | Warm orange |
| Cognitive | Brain/thought bubble | Purple |
| Spiritual | Cross/dove | Gold |
| Situational | Calendar | Slate blue |

These colors are illustrative; final colors must pass WCAG AA contrast checks against both light and dark mode backgrounds and must be distinguishable by users with color vision deficiency.

### 5.6 Tone and Language Guidelines

| Instead of | Use |
|------------|-----|
| "Trigger alert" | "Something came up" |
| "You were triggered" | "You noticed something" |
| "Trigger failure" | (never used) |
| "Relapse risk" | "Your recovery tools are here" |
| "High-risk warning" | "This time has been challenging before" |
| "Trigger logged successfully" | "You saw it. You named it. That matters." |
| "No triggers logged" (empty state) | "Nothing to show yet. When you notice a trigger, this is where you'll track it. Every entry builds self-knowledge." |

**Scripture integration (optional, user-configurable):** After logging a trigger, the system may display a relevant scripture verse. Examples:
- 1 Corinthians 10:13: "No temptation has overtaken you except what is common to mankind..."
- James 1:2-4: "Consider it pure joy...whenever you face trials..."
- Romans 5:3-4: "Suffering produces perseverance; perseverance, character; character, hope."

Scripture display shall be togglable in settings under "Faith content preferences."

---

## 6. Premium Tier Boundaries

| Capability | Free | Standard | Premium+ |
|------------|------|----------|----------|
| Trigger logging (all depths) | Up to 5/day | Unlimited | Unlimited |
| Personal trigger library (browse, search, select) | Full 120 items | Full 120 items | Full 120 items |
| Custom trigger creation | Up to 5 | Unlimited | Unlimited |
| Intensity rating | Yes | Yes | Yes |
| Affirming completion + next actions | Yes | Yes | Yes |
| Coping strategy access from trigger flow | Yes | Yes | Yes |
| Trigger log history (view, edit, delete) | Last 30 days | Full history | Full history |
| Basic trigger count per day | Yes | Yes | Yes |
| Temporal heat map | No | Yes | Yes |
| Category distribution chart | No | Yes | Yes |
| Intensity trend lines | No | Yes | Yes |
| Top triggers dashboard | No | Yes | Yes |
| Weekly insight summaries (natural language) | No | Yes | Yes |
| Rule-based proactive alerts | No | Yes | Yes |
| FASTER Scale correlation view | No | Yes | Yes |
| Trigger resilience metric | No | Yes | Yes |
| Trigger co-occurrence clusters | No | No | Yes |
| Trigger chain analysis | No | No | Yes |
| AI-generated personalized relapse prevention recommendations | No | No | Yes |
| AI agent integration (trigger data in conversations) | No | No | Yes |
| Geofencing (user-defined high-risk locations) | No | No | Yes |
| Accountability partner sharing | Summary only | Full granularity | Full granularity |
| Data export (JSON/PDF) | No | Yes | Yes |
| Calendar-based proactive alerts | No | Yes | Yes |
| Time-based proactive alerts | No | Yes | Yes |

**Free tier rationale:** The free tier provides the core therapeutic mechanism -- logging triggers and receiving coping support -- without restriction on therapeutic value. The 5/day limit is generous for most users (research suggests 2-3 trigger logs per day is typical for active users). Analytics and pattern detection, which require sustained engagement, are gated at Standard to create upgrade motivation. The limit on history view (30 days) provides enough data for personal review while creating a natural upgrade path for users who want to track long-term trends.

---

## 7. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| **Low adoption:** Users do not log triggers because the flow feels like confession | Medium | High | Affirming UX copy, trigger-as-teacher framing, under-15-second quick log, positive reinforcement after every entry. |
| **Assessment reactivity:** The act of logging triggers itself induces craving | Low | Medium | Brief assessments with "not now" option. No required fields beyond trigger selection. Immediate coping tool access after logging. Research (triggers-teachers-research.md) notes this risk exists but is manageable with good design. |
| **Digital trigger paradox:** The smartphone used for logging is itself a trigger | Medium | Medium | Minimal engagement time (15-second quick log). No extended screen interaction required. Offline logging supports device-free periods. The app never competes for attention. |
| **False-positive proactive alerts:** Alerts create self-fulfilling prophecy or alert fatigue | Medium | Medium | Conservative thresholds (FR-T-081: 30 entries over 14 days minimum). User-controllable frequency caps and quiet hours. Language framed as observation, not prediction. |
| **Privacy breach:** Trigger data exposed to unintended party | Low | Critical | Encryption at rest and in transit. Biometric lock. GPS data on-device only. Non-identifying notifications. Two-step deletion confirmation. No server-side storage of free-text NLP processing. |
| **Shame amplification:** Analytics showing high trigger frequency makes user feel worse | Medium | High | Growth-oriented metrics (resilience %, decreasing intensity). "Triggers navigated successfully" framed as primary metric, not trigger count. Contextual encouragement messages on analytics screens. |
| **Over-reliance on app:** Users substitute app logging for human connection | Low | Medium | Every logging flow offers a path to human connection (accountability partner contact, sponsor call, meeting finder). The app positions itself as a complement to relational recovery, not a replacement. |
| **Data loss during offline period:** Trigger logs lost before sync | Low | High | SwiftData local persistence is immediate and reliable. Sync uses union merge to prevent data loss. Failed syncs retry with exponential backoff. |

---

## 8. Open Questions

1. **Urge log migration:** The existing `UrgeLogViewModel.availableTriggers` contains a static 8-item list. Should the upgrade to the full 120-item personal trigger library happen as part of this feature, or as a prerequisite migration? Recommendation: include in this feature scope as FR-T-060.

2. **Three Circles integration timing:** FR-T-094 requires the Three Circles feature to support trigger-to-circle mapping. If Three Circles is not yet at this maturity, should this requirement be deferred? Recommendation: implement the trigger-side data model now; connect to Three Circles when that feature is ready.

3. **Geofence battery impact:** iOS geofencing via Core Location can impact battery life. What is the acceptable battery drain threshold? Recommendation: limit to 20 user-defined geofences, use significant location change monitoring rather than continuous GPS.

4. **Analytics computation at scale:** With potentially 10,000+ trigger entries, should on-device analytics use pre-computed aggregates or compute on-demand? Recommendation: maintain rolling aggregate tables in SwiftData (daily counts by category, weekly intensity averages) updated on each log entry, with on-demand computation for ad-hoc queries.

5. **Free tier trigger logging limit:** The proposed 5/day limit covers most usage patterns, but a user in acute crisis might exceed it. Should the limit be lifted automatically when the user logs a high-intensity trigger (>= 7)? Recommendation: yes, high-intensity triggers bypass the daily limit.

6. **Accountability partner notification consent model:** FR-T-023 triggers an automatic notification at high intensity. Should this be an always-on default that the user opts out of, or an opt-in that the user explicitly enables? Recommendation: opt-in, consistent with the privacy-by-architecture principle.

---

## 9. Success Criteria

| Metric | Target | Measurement Method |
|--------|--------|--------------------|
| **OMTM: Unmanaged trigger-to-urge escalation rate** | 15% reduction at 90 days among users logging 3+/week | Ratio of triggers followed by urge logs within 4 hours, comparing first 30 days to days 60-90 |
| **Trigger logging adoption** | 40% of active users log at least 1 trigger within 14 days of feature launch | Event tracking on trigger log submission |
| **Trigger logging retention** | 25% of adopters log triggers at least 3x/week at 30 days | Rolling 7-day active trigger loggers / total adopters |
| **Quick log completion time** | Median under 15 seconds | Timer from flow initiation to submission |
| **Coping tool engagement** | 30% of trigger logs (intensity >= 4) lead to coping tool access | Event tracking on coping tool tap from trigger flow |
| **Accountability sharing rate** | 20% of Standard+ users share trigger data with a partner at least once per week | Event tracking on share action |
| **Trigger resilience improvement** | 10% increase in resilience metric (triggers not followed by urges) from month 1 to month 3 | On-device analytics computation |
| **Feature satisfaction (qualitative)** | Users report triggers feel like "a growth tool, not a shame log" in in-app feedback | Qualitative feedback prompt at 30 days |

---

## 10. Assumptions and Constraints

### Assumptions

1. The existing SwiftData infrastructure supports the additional models without architectural changes.
2. The SyncEngine can handle a new entity type (TRIGGER) without modification beyond configuration.
3. Users are familiar with the general concept of triggers from their recovery program involvement (SA, Celebrate Recovery).
4. The 120-item trigger taxonomy in `content/triggers/triggers-list.md` is clinically sufficient for the initial release; user feedback will drive additions.
5. The existing FAB on the home screen can accommodate a trigger log entry point alongside existing actions.

### Constraints

1. **iOS only.** All requirements target the iOS app; API contract implications are noted but backend implementation is out of scope.
2. **No ML in initial release.** All analytics and pattern detection use rule-based logic. ML-based trigger prediction (Phase 2/3) is explicitly excluded from this scope.
3. **No NLP on free text.** Consistent with the privacy-by-architecture principle, free-text fields are stored and displayed but not analyzed programmatically.
4. **Feature flag gated.** The entire Triggers feature shall ship behind a feature flag with rollout %, tier gating, and kill switch, consistent with the app's feature flag architecture.
5. **Max 40 business days.** Implementation must fit within 4 sprints (14-day sprints, 56 calendar days, 40 business days).

---

## 11. Dependencies

| Dependency | Type | Status | Impact if Delayed |
|------------|------|--------|-------------------|
| SwiftData models and repository | Technical | Available | Blocking -- no local persistence |
| SyncEngine configuration for TRIGGER entity | Technical | Requires work | Blocking for server sync; offline logging still works |
| Urge Log feature (existing) | Feature integration | Shipped | FR-T-060/061 deferred; standalone trigger logging unaffected |
| FASTER Scale feature (existing) | Feature integration | Shipped | FR-T-075/091 deferred; standalone trigger logging unaffected |
| Three Circles feature | Feature integration | In progress | FR-T-094 deferred; standalone trigger logging unaffected |
| Accountability partner feature | Feature integration | In progress | FR-T-095 deferred; sharing features deferred |
| Feature flag service | Infrastructure | Available | Blocking -- feature cannot ship without flag |
| Breathing exercise / coping tools | Content | Shipped | Non-blocking -- coping tool links degrade gracefully |
| `content/triggers/triggers-list.md` | Content | Available | Non-blocking -- already exists in repo |
| Calendar activity view | Feature integration | Shipped | FR-T-096 integration available |

---

## 12. References

### Research Documents (In-Repository)

- `docs/prd/specific-features/Triggers/triggers-research.md` -- Comprehensive trigger research for Regal Recovery (sex addiction specific)
- `docs/prd/specific-features/Triggers/triggers-teachers-research.md` -- Triggers as teachers: clinical and behavioral science synthesis

### Content Assets (In-Repository)

- `content/triggers/triggers-list.md` -- 120-item trigger taxonomy across 7 categories
- `content/triggers/about.md` -- Comprehensive trigger reference for sex addiction recovery
- `content/prompts.md` (Section 7) -- 15 trigger-specific journal prompts
- `content/evening-review-questions.md` -- Evening review questions including trigger awareness

### Existing Feature Documents

- `docs/prd/specific-features/FASTER/FASTER-Scale-Feature-PRD.md` -- FASTER Scale check-in specification
- `docs/specs/openapi/activities.yaml` -- OpenAPI spec including urge log and post-mortem schemas
- `docs/specs/mongodb/schema-design.md` -- MongoDB schema including urge log entity pattern

### Clinical Literature

See triggers-research.md and triggers-teachers-research.md for full citation lists. Key sources informing this FRD:

- Bowen et al. (2014). MBRP vs. RP vs. TAU. *JAMA Psychiatry*.
- Carnes, P. (2010). *Facing the Shadow* (3rd edition).
- Dye, M. *The Genesis Process* (FASTER Scale).
- Grimm, Hope, Wise & Shaham (2001). Incubation of craving. *Nature*.
- Gustafson et al. (2014). A-CHESS RCT. *JAMA Psychiatry*.
- Koob & Volkow (2016). Neurobiology of addiction. *Lancet Psychiatry*.
- Laaser, M. (2008). *The Seven Desires of Every Heart*.
- Marlatt, G.A. (1985). Relapse taxonomy.
- Melemis, S.M. (2015). Relapse prevention. *Yale Journal of Biology and Medicine*.
- Nahum-Shani et al. (2018). JITAI framework. *Annals of Behavioral Medicine*.
- Voon et al. (2014). Cue reactivity in compulsive sexual behavior. *PLOS ONE*.

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-04-22 | Product | Initial FRD based on triggers-research.md and triggers-teachers-research.md |
