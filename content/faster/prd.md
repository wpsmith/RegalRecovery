# FASTER Scale Check-In — Mini PRD

**Feature name:** FASTER Scale Check-In
**Tiers:** Standard · Premium+
**Last updated:** April 2026

---

## 1. Feature overview

The FASTER Scale Check-In translates Michael Dye's six-stage relapse awareness framework into an interactive daily self-assessment activity within the recovery app. Users identify where they fall on the Restoration → F → A → S → T → E → R progression by reviewing behavioral indicators, then receive stage-appropriate guidance, journaling prompts, and (at higher risk) accountability alerts.

**Standard** delivers the full self-assessment flow as a structured, self-directed activity with visual feedback, journaling, and accountability partner sharing.

**Premium+** adds a conversational AI agent that guides the user through the check-in via adaptive dialogue, probes beneath surface selections, completes the FASTER Scale assessment on the user's behalf based on conversation responses, and generates clinical-grade session notes for the user, their accountability partner, and (optionally) their therapist.

---

## 2. Standard tier — FASTER Scale Check-In

### 2.1 Feature description

A guided, self-paced daily activity where the user works through the FASTER Scale stages using progressive disclosure. Each stage is presented as an expandable card containing 5–8 behavioral indicators rendered as toggleable chips. After completing selections, the app displays a visual position indicator ("thermometer" gradient from green/Restoration through red/Relapse), surfaces stage-matched coping resources, and offers structured journaling. Results can be shared with an accountability partner at user-controlled granularity.

### 2.2 Functional requirements

| ID | Requirement |
|----|-------------|
| S-01 | The system shall present an entry screen with a low-cognitive-load mood prompt ("How are you doing right now?") using 5 selectable emoji/icon options before revealing the full scale. |
| S-02 | The system shall render the six FASTER stages (F, A, S, T, E, R) plus Restoration as vertically stacked, expandable accordion cards in descending order from Restoration at top to Relapse at bottom. |
| S-03 | Each stage card shall contain 5–8 behavioral indicators displayed as toggleable chips. Indicators shall be drawn from the canonical FASTER Scale behavioral markers (e.g., under **F**: isolating, keeping secrets, sarcasm, procrastination, breaking small commitments, overconfidence, preoccupation with entertainment). |
| S-04 | The system shall allow the user to toggle any number of indicators across any number of stages in a single session. |
| S-05 | Upon completing selections, the system shall calculate and display the user's assessed position as the lowest (most severe) stage in which at least one indicator is selected, consistent with the FASTER Scale rule that stages stack cumulatively. |
| S-06 | The system shall render a visual "thermometer" or gradient bar showing the user's current position, color-coded from green (Restoration) through amber (F/A/S) to red (T/E/R). |
| S-07 | The system shall display stage-appropriate adaptive content after assessment completion, specifically: Restoration → encouragement and maintenance tips; F → priority-review exercise; A → breathing/grounding exercises; S → slow-down activities and mindfulness content; T → Feeling Wheel tool and anger-management resources; E → prominent SOS button + prompt to contact accountability partner; R → crisis support resources + Recovery Action Plan activation + accountability alert trigger. |
| S-08 | The system shall present a structured journaling prompt after the adaptive content, offering two labeled fields: "Ah-ha" (insight) and "Uh-oh" (warning sign), mirroring the Genesis Process group exercise format. An optional free-text field shall also be available. |
| S-09 | The system shall store each completed check-in with timestamp, all selected indicators, assessed stage, and journal entries in the user's encrypted local history. |
| S-10 | The system shall provide a trends dashboard showing assessed-stage history over 7/30/90-day windows as a timeline visualization, with the ability to tap any data point to review the full check-in detail. |
| S-11 | The system shall track and display cumulative positive engagement metrics (e.g., "47 check-ins completed this month") rather than abstinence streak counters to avoid triggering the Abstinence Violation Effect. |
| S-12 | The system shall allow the user to configure a daily check-in reminder notification at a user-selected time. Notification preview text shall use generic, non-identifying language (e.g., "Time for your daily check-in") that does not reveal the app's recovery purpose on a lock screen. |
| S-13 | The system shall support sharing check-in results with a designated accountability partner. Sharing granularity shall be user-controlled with three levels: (a) stage-only summary, (b) stage + selected indicators, (c) stage + indicators + journal entries. |
| S-14 | The system shall trigger an automatic push notification to the accountability partner when the user's assessed position is Exhausted or Relapse, provided the user has opted into this alert. |
| S-15 | The system shall include a one-tap SOS button accessible from any screen within the check-in flow. Tapping SOS shall immediately notify the accountability partner and surface crisis support resources. |
| S-16 | All check-in data shall be encrypted at rest (AES-256 or equivalent) and in transit (TLS 1.3). The app shall support biometric or PIN lock as a secondary authentication layer. |
| S-17 | The system shall provide a complete data deletion option allowing the user to permanently erase all stored check-in history from the device and server. |

### 2.3 User stories — Standard

**US-S01: First-time check-in onboarding**
As a new user opening the FASTER Scale activity for the first time, I want a brief educational walkthrough explaining what each stage means and how the scale works, so that I can complete the check-in with understanding rather than confusion.
*Acceptance criteria:*
- A 4–6 screen onboarding carousel is displayed on first launch of the activity, covering: what the FASTER Scale is, the six stages in plain language, how to use the toggle indicators, and what the results mean.
- User can skip the onboarding at any time.
- User can re-access the educational content from a help icon within the activity.
- Onboarding is shown only once; subsequent launches go directly to the check-in.

**US-S02: Daily mood entry**
As a user starting my daily check-in, I want to quickly indicate my general mood before diving into the detailed scale, so that I have a low-effort entry point even when I'm feeling depleted.
*Acceptance criteria:*
- Five emoji/icon options are displayed on the entry screen representing a spectrum from "great" to "struggling."
- Tapping an option records the mood and transitions to the full FASTER Scale view.
- Mood selection is required to proceed but takes no more than one tap.
- Mood history is stored and visible on the trends dashboard.

**US-S03: Indicator selection across stages**
As a user working through the FASTER Scale, I want to expand each stage card and toggle the specific behaviors I'm experiencing, so that I can honestly identify where I am without being forced into a single category.
*Acceptance criteria:*
- Each of the seven sections (Restoration + F/A/S/T/E/R) is expandable and collapsible independently.
- Each section contains 5–8 behavioral indicator chips with concise labels.
- Chips toggle on/off with visible state change (filled vs. outlined).
- Multiple chips across multiple stages can be selected simultaneously.
- Selections persist within the session until the user submits.
- A running count of selected indicators per stage is shown on the collapsed card header.

**US-S04: Visual position assessment**
As a user who has completed my selections, I want to see a clear visual representation of where I fall on the FASTER Scale, so that I immediately understand my current risk level.
*Acceptance criteria:*
- A vertical or horizontal thermometer/gradient renders after submission.
- The user's position is marked at the lowest (most severe) stage with at least one selection.
- Color coding transitions from green (Restoration) through amber (F/A/S) to red (T/E/R).
- The stage name and a one-sentence summary are displayed alongside the indicator.
- If Restoration is the only section with selections, the user sees an affirming "You're in Restoration" message.

**US-S05: Stage-adaptive coping resources**
As a user assessed at a specific stage, I want to receive relevant therapeutic resources matched to that stage, so that I can take immediate action appropriate to my current state.
*Acceptance criteria:*
- Restoration: motivational content and a suggested maintenance activity.
- Forgetting Priorities: a priority-review checklist prompting the user to evaluate their commitments, meeting attendance, and relational engagement.
- Anxiety: a guided breathing exercise (minimum 60 seconds) and a grounding technique (e.g., 5-4-3-2-1 sensory exercise).
- Speeding Up: a mindfulness prompt or slow-down challenge (e.g., "Take 10 minutes to do nothing").
- Ticked Off: an interactive Feeling Wheel tool and a brief anger-management resource.
- Exhausted: SOS button rendered at full width and high contrast, with text prompting the user to contact their accountability partner. Crisis resources displayed.
- Relapse: crisis support information displayed immediately. Recovery Action Plan activated. If opted in, accountability partner is auto-notified.
- Resources are tappable and expand inline; they do not navigate away from the check-in.

**US-S06: Structured journaling**
As a user completing my check-in, I want to journal about my insights and warning signs in a structured format, so that I build the self-awareness habit used in Genesis Process groups.
*Acceptance criteria:*
- Two labeled text fields appear: "Ah-ha (insight)" and "Uh-oh (warning sign)."
- A third optional free-text field labeled "Anything else?" is available below.
- Each field accepts up to 1,000 characters.
- Journal entries are saved with the check-in record and viewable in history.
- User can submit the check-in without filling any journal fields.

**US-S07: Accountability partner sharing**
As a user with a linked accountability partner, I want to choose what level of detail from my check-in is shared with them, so that I maintain control over my vulnerability while still being accountable.
*Acceptance criteria:*
- After completing the check-in, a "Share with partner" prompt appears.
- Three sharing levels are presented: stage only, stage + indicators, stage + indicators + journal.
- The user selects one level and confirms before any data is transmitted.
- The partner receives a push notification with the shared content rendered in the companion/partner view.
- The user can change their default sharing level in settings.
- If no partner is linked, the prompt is replaced with a "Connect a partner" CTA.

**US-S08: SOS emergency alert**
As a user in acute distress, I want to send an immediate alert to my accountability partner with one tap, so that I can reach out for help without having to compose a message.
*Acceptance criteria:*
- The SOS button is accessible on every screen within the check-in flow.
- Tapping SOS triggers a confirmation dialog ("Send an alert to [Partner Name]?").
- Upon confirmation, the partner receives an immediate push notification with the message: "[User's display name] is reaching out for support."
- Crisis resources (hotline numbers, text lines) are displayed to the user after sending.
- SOS events are logged in the user's check-in history with a timestamp.

**US-S09: Trend tracking and history**
As a user who has been doing check-ins over time, I want to see my FASTER Scale position history as a visual trend, so that I can recognize patterns and share progress with my therapist or group.
*Acceptance criteria:*
- A trends view displays assessed-stage data points over selectable 7/30/90-day windows.
- Data is rendered as a timeline chart with color-coded dots per stage.
- Tapping a data point opens the full detail of that check-in (indicators, journal, mood).
- A cumulative engagement counter shows total check-ins completed in the selected period.
- The trend view is exportable as a PDF summary for sharing with a therapist.

**US-S10: Notification privacy**
As a user who needs absolute discretion, I want all notifications from the app to be completely non-identifying, so that no one who sees my phone can infer I'm in a recovery program.
*Acceptance criteria:*
- All push notification titles and preview text use generic language ("Daily check-in reminder," "A friend needs your support").
- No notification ever contains the words "recovery," "addiction," "relapse," "FASTER," "sexual," or any clinical terminology.
- The app icon and name in notifications can be configured to display a neutral alias (e.g., "Wellspring" or a user-defined label) if the OS supports it.
- Notifications on lock screen show only the generic preview; full content is visible only after device unlock.

**US-S11: Data security and deletion**
As a user who values privacy, I want to be able to permanently delete all my check-in data, so that I know I retain full control over my information.
*Acceptance criteria:*
- A "Delete all data" option is available in settings.
- Tapping triggers a two-step confirmation flow explaining the action is permanent.
- Upon confirmation, all check-in records, journal entries, trend data, and mood history are permanently erased from local storage and remote servers within 24 hours.
- The user receives on-screen confirmation that deletion is complete.
- Shared data already transmitted to an accountability partner is flagged in their view as "source data deleted by user."

---

## 3. Premium+ tier — AI-Guided FASTER Scale conversation

### 3.1 Feature description

Premium+ replaces the self-directed toggle-based check-in with a conversational AI agent that guides the user through the FASTER Scale via adaptive dialogue. Instead of selecting chips from a list, the user answers the agent's questions in natural language. The agent uses clinical probing techniques (open-ended questions, reflective paraphrasing, "why" follow-ups) to assess the user's true position on the scale — often surfacing indicators the user would not have self-identified in the Standard flow. The agent completes the FASTER Scale assessment on the user's behalf, generates a structured session summary with all responses captured as clinical-style notes, and delivers the same stage-adaptive resources as Standard. Session notes are shareable with accountability partners, group leaders, and therapists at configurable granularity.

### 3.2 Functional requirements

| ID | Requirement |
|----|-------------|
| P-01 | The system shall provide a conversational AI agent accessible as the primary check-in modality for Premium+ subscribers. |
| P-02 | The agent shall initiate each session with a warm, open-ended prompt (e.g., "How have things been going since we last talked?") and adapt its conversational path based on user responses. |
| P-03 | The agent shall systematically explore all six FASTER stages through natural dialogue, using at minimum one probing question per stage. The agent shall not present stages as a list or checklist but shall weave exploration into the conversational flow. |
| P-04 | The agent shall employ clinically informed conversational techniques: open-ended questions, reflective paraphrasing, "tell me more" probes, scaled questions (e.g., "On a 1–10, how anxious have you felt?"), behavioral specificity prompts (e.g., "Can you give me an example of when that happened this week?"), and gentle confrontation when responses appear minimizing. |
| P-05 | The agent shall track all behavioral indicators identified during the conversation (both explicitly stated and inferred from context) and map them to their corresponding FASTER Scale stages in real time. |
| P-06 | The agent shall allow the user to steer the conversation, go off-topic, or express emotions freely. The agent shall acknowledge these moments empathetically before gently returning to the assessment flow. |
| P-07 | The agent shall use the Double Bind concept from the Genesis Process framework to probe beneath surface behaviors, asking questions like "What would feel risky about changing this pattern?" when relevant indicators are identified. |
| P-08 | The conversation shall last 5–15 minutes depending on user engagement. The agent shall manage pacing — not rushing through stages and not allowing indefinite open-ended wandering — by tracking which stages have been explored and which remain. |
| P-09 | At conversation end, the agent shall present a FASTER Scale assessment summary showing: assessed position, all identified indicators organized by stage, the agent's reasoning for the assessment, and a highlighted list of indicators the user may not have self-identified. |
| P-10 | The user shall be able to review and adjust the agent's assessment before finalizing (e.g., "I don't think I'm really at Ticked Off — that was just one incident"). The agent shall respond to adjustments conversationally, either accepting or gently probing further. |
| P-11 | The system shall generate a structured session note upon finalization containing: session date/time, duration, assessed FASTER stage, all identified indicators with the user's own words as supporting evidence, journal-format "Ah-ha" and "Uh-oh" entries auto-extracted from the conversation, a summary paragraph, and recommended next actions. |
| P-12 | Session notes shall be formatted in a clinical-style template suitable for sharing with therapists, group leaders, or accountability partners. |
| P-13 | The system shall provide configurable sharing controls for session notes with four tiers: (a) stage-only summary, (b) stage + indicators, (c) stage + indicators + AI-generated summary paragraph, (d) full session notes including user quotes. |
| P-14 | The system shall support sharing session notes with multiple recipients: accountability partner, group leader, and/or licensed therapist, each with independently configurable sharing tiers. |
| P-15 | The agent shall remember key context from the user's previous 3–5 sessions (identified patterns, recurring indicators, stated goals, names of people mentioned) and reference this context naturally in future conversations (e.g., "Last time you mentioned tension with your boss — how has that been?"). |
| P-16 | The system shall detect escalation patterns across sessions (e.g., user's assessed stage has worsened for 3+ consecutive check-ins) and trigger the agent to flag this explicitly during conversation: "I've noticed you've been moving further down the scale over the past few sessions. Can we talk about what's going on?" |
| P-17 | When the user is assessed at Exhausted or Relapse, the agent shall prioritize immediate safety: surface crisis resources, strongly encourage contacting the accountability partner, and offer to send the SOS alert on the user's behalf within the conversation flow. |
| P-18 | The system shall provide a voice-input option for the conversation, allowing the user to speak responses rather than type, with real-time transcription. |
| P-19 | All conversation transcripts and session notes shall be encrypted at rest and in transit. Transcripts shall be stored separately from session notes; the user can delete transcripts while retaining notes, or delete both. |
| P-20 | The agent shall never diagnose, prescribe, or provide therapy. A standing disclaimer shall be accessible within the conversation UI: "This is a self-awareness tool, not a substitute for professional counseling." |
| P-21 | All Standard tier features (S-01 through S-17) shall remain available to Premium+ users. Premium+ users may choose between the agent-guided conversation and the self-directed check-in on any given day. |

### 3.3 User stories — Premium+

**US-P01: Starting a guided conversation**
As a Premium+ user opening my daily check-in, I want to choose between the self-directed checklist and the AI-guided conversation, so that I can use whichever format fits my energy and time.
*Acceptance criteria:*
- The check-in entry screen presents two options: "Quick check-in" (Standard flow) and "Guided conversation" (agent flow).
- The default option can be set in user preferences.
- Both options lead to the same underlying FASTER Scale assessment with identical data storage.
- The user can switch from guided conversation to quick check-in mid-session (progress carries over for any indicators already identified).

**US-P02: Opening dialogue and rapport**
As a user beginning a guided conversation, I want the agent to greet me warmly and ask an open-ended question, so that I feel safe to be honest rather than pressured to perform.
*Acceptance criteria:*
- The agent opens with a personalized, non-clinical greeting (e.g., "Hey [name], good to see you. How have things been going?").
- If this is a returning user, the agent references context from the last session (e.g., "Last time you mentioned feeling stretched thin at work — how's that been?").
- The agent does not immediately mention the FASTER Scale, stages, or clinical terminology.
- The opening message is warm, human, and conversational in tone.

**US-P03: Natural-language stage exploration**
As a user in conversation with the agent, I want it to explore each FASTER stage through natural questions about my week rather than reading me a checklist, so that I discover things about my state I wouldn't have noticed on my own.
*Acceptance criteria:*
- The agent covers all six FASTER stages over the course of the conversation without ever naming the stages unless the user asks.
- Questions are contextual and behavioral (e.g., "Have you been keeping up with your group meetings this week?" for Forgetting Priorities; "How's your sleep been?" for Anxiety; "Have you felt yourself staying busier than usual?" for Speeding Up).
- The agent uses at least one follow-up probe per stage when indicators are detected (e.g., "You mentioned snapping at your wife — can you tell me more about what was going on for you in that moment?").
- The agent adapts question depth based on responses: briefly skimming stages where the user shows no indicators, spending more time on stages with multiple signals.
- The conversation never feels like an interrogation; transitions between topics are natural.

**US-P04: Handling emotional moments**
As a user who becomes emotional or goes off-topic during the conversation, I want the agent to acknowledge my feelings before redirecting, so that I feel heard rather than processed.
*Acceptance criteria:*
- When the user shares something emotionally charged (detected via sentiment analysis and/or explicit emotional language), the agent responds with empathetic acknowledgment before continuing (e.g., "That sounds really painful. Thank you for sharing that.").
- The agent allows the user at least one follow-up message on the emotional topic before gently steering back.
- The agent never cuts off an emotional disclosure with a clinical redirect.
- If the user expresses suicidal ideation or intent to self-harm, the agent immediately pauses the assessment, provides crisis resources, and offers to alert the accountability partner.

**US-P05: Double Bind exploration**
As a user showing indicators in the Ticked Off or Exhausted stages, I want the agent to help me explore what underlying conflict might be driving my behavior, so that I can address root causes rather than just symptoms.
*Acceptance criteria:*
- When the user has indicators in T or E stages, the agent introduces a Double Bind–style question (e.g., "It sounds like you're stuck between two hard choices. What would feel risky about doing things differently?").
- The agent waits for and processes the user's response before proceeding.
- The agent does not force the Double Bind exploration if the user deflects; it notes the deflection in session notes and moves on.
- The agent surfaces this as an "Ah-ha" candidate in the session summary.

**US-P06: Real-time assessment visibility**
As a user in the middle of a conversation, I want to optionally see which indicators the agent has identified so far, so that I can correct misinterpretations in real time.
*Acceptance criteria:*
- A collapsible "Assessment so far" panel is accessible via a subtle icon in the conversation UI.
- The panel shows identified indicators grouped by stage, each with a one-line quote or paraphrase from the user's response as evidence.
- The user can tap any indicator to dispute it; the agent responds conversationally (e.g., "Got it — I may have read too much into that. Let me take that off.").
- Disputed indicators are removed from the assessment and flagged in session notes as "user-disputed."

**US-P07: Assessment presentation and negotiation**
As a user who has completed the conversation, I want to see the agent's FASTER Scale assessment with clear reasoning, and I want to be able to challenge it, so that the final result reflects my honest self-evaluation rather than an algorithm's guess.
*Acceptance criteria:*
- The agent presents the assessment conversationally: "Based on our conversation, it seems like you're sitting around [stage]. Here's what I noticed…"
- Each identified indicator is listed with the user's own words as evidence.
- Indicators the user did not explicitly mention but the agent inferred are highlighted separately as "Patterns I noticed."
- The user can respond with agreement, disagreement, or nuance.
- If the user disagrees, the agent engages: "Help me understand — what makes you feel like that's not where you are?" The agent can accept the user's correction or explain its reasoning once, then accept.
- The finalized assessment is recorded only after the user confirms.

**US-P08: Automated session notes generation**
As a user who has completed the guided conversation, I want the system to generate structured clinical-style notes from our dialogue, so that I have a useful record without needing to write anything myself.
*Acceptance criteria:*
- Session notes are generated within 10 seconds of assessment finalization.
- Notes contain: date, time, session duration, opening mood, final assessed FASTER stage, all identified indicators with supporting user quotes (paraphrased for clarity), auto-extracted "Ah-ha" and "Uh-oh" entries, a 3–5 sentence summary paragraph, and recommended next actions based on the assessed stage.
- Notes are formatted in a clean, professional template suitable for printing or sharing with a clinician.
- The user can view, edit, or add to the generated notes before saving.
- Notes are saved as part of the check-in record and accessible from the history view.

**US-P09: Multi-recipient note sharing**
As a user with an accountability partner, a group leader, and a therapist, I want to share different levels of detail with each person, so that my therapist gets the full picture while my group leader gets a summary.
*Acceptance criteria:*
- After notes are finalized, the user is presented with a sharing screen listing all connected recipients.
- Each recipient has an independent sharing-tier selector: stage only, stage + indicators, stage + indicators + summary, or full notes with quotes.
- The user confirms sharing individually per recipient.
- Each recipient receives a push notification with the content appropriate to their tier.
- Recipients see only their authorized content; they cannot infer that other recipients received more or less detail.
- Sharing preferences per recipient are remembered as defaults for future sessions.

**US-P10: Cross-session pattern recognition**
As a returning user, I want the agent to recognize patterns across my recent sessions and raise them proactively, so that I can see trends I might miss day-to-day.
*Acceptance criteria:*
- The agent retains context from the user's previous 3–5 sessions including assessed stages, recurring indicators, names/situations mentioned, and stated goals.
- When a pattern is detected (e.g., the same indicator appearing 3+ sessions in a row, or a progressive worsening trend), the agent raises it naturally in conversation (e.g., "I've noticed you've mentioned difficulty sleeping in our last three conversations. Do you think that's connected to anything?").
- If the user's assessed stage has worsened for three consecutive sessions, the agent flags this explicitly and suggests a conversation about what has changed.
- The agent's pattern observations are included in session notes under a "Trends" section.

**US-P11: Escalation and safety protocol**
As a user assessed at Exhausted or Relapse, I want the agent to shift into a supportive safety mode, so that I'm connected to help immediately rather than just handed a score.
*Acceptance criteria:*
- When the agent assesses the user at E or R during conversation, it pauses the standard flow and shifts tone: "I want to make sure you're okay right now. Can I help you reach out to someone?"
- The agent offers three actions: (1) send SOS alert to accountability partner, (2) display crisis hotline numbers, (3) continue the conversation in supportive mode.
- If the user selects SOS, the agent confirms and sends the alert within the conversation flow — the user does not leave the chat.
- The agent does not end the conversation abruptly; it remains available for as long as the user wants to talk.
- All escalation events are logged in session notes and the trends dashboard.

**US-P12: Voice input**
As a user who finds typing difficult when I'm upset, I want to speak my responses and have them transcribed, so that I can complete the conversation even when I'm in a low place.
*Acceptance criteria:*
- A microphone button is available adjacent to the text input field.
- Pressing and holding records audio; releasing submits for transcription.
- Transcribed text appears in the input field for the user to review and edit before sending.
- A hands-free "continuous listening" mode can be enabled in settings, where the agent auto-detects end-of-speech and processes the response.
- Voice input works offline with on-device transcription; audio is never transmitted to external servers.
- The agent's responses can optionally be read aloud via text-to-speech (configurable in settings).

**US-P13: Conversation-to-checklist fallback**
As a Premium+ user who starts the guided conversation but realizes I don't have time, I want to switch to the quick check-in without losing what I've already shared, so that I can still complete my daily assessment.
*Acceptance criteria:*
- A "Switch to quick check-in" option is available in the conversation menu at any time.
- Upon switching, all indicators the agent has identified so far are pre-selected on the Standard checklist.
- The user can add or remove indicators and submit as a Standard check-in.
- Session notes are not generated for a switched session; it is recorded as a Standard check-in with a "started as conversation" flag.
- The user can resume the conversation where they left off within a configurable window (default: 2 hours).

**US-P14: Therapist integration and export**
As a user working with a licensed therapist, I want to grant my therapist ongoing read access to my session notes, so that they can review my FASTER Scale trends before our appointments without me needing to share each one manually.
*Acceptance criteria:*
- The user can invite a therapist via email. The therapist creates a provider account with a separate portal view.
- The user configures a default sharing tier for the therapist (changeable per session).
- All future session notes are automatically shared with the therapist at the configured tier unless the user marks a specific session as private.
- The therapist portal displays a timeline of session notes, a trend chart of assessed stages, and the ability to leave private comments visible only to the user.
- The user can revoke therapist access at any time; upon revocation, all shared notes are removed from the therapist portal within 24 hours.

**US-P15: Session notes privacy and deletion**
As a user who wants control over my conversation data, I want to independently manage transcripts and session notes, so that I can keep useful summaries while deleting raw conversation logs.
*Acceptance criteria:*
- Conversation transcripts (full chat logs) and session notes (structured summaries) are stored as separate data objects.
- The user can delete transcripts while retaining session notes, or delete both.
- Deletion is per-session or bulk ("delete all transcripts older than 30 days").
- Deleted data is permanently erased from local and remote storage within 24 hours.
- A "data inventory" screen shows total storage consumed by transcripts vs. notes.

---

## 4. Non-functional requirements (both tiers)

| ID | Requirement |
|----|-------------|
| NF-01 | All screens within the check-in flow shall render within 1 second on devices from the past 3 years. |
| NF-02 | The Standard check-in flow shall be fully functional offline. Data syncs upon reconnection. |
| NF-03 | The Premium+ agent conversation shall function with intermittent connectivity, queuing user messages and delivering agent responses upon reconnection. Degraded-mode fallback to Standard check-in shall activate after 30 seconds without connectivity. |
| NF-04 | The app shall comply with HIPAA (if handling PHI through therapist integration) and shall follow SAMHSA's six principles of trauma-informed care in all user-facing copy and interaction patterns. |
| NF-05 | The Premium+ agent shall respond to each user message within 3 seconds under normal network conditions. |
| NF-06 | Accessibility: all check-in screens shall meet WCAG 2.1 AA. The conversation UI shall support screen readers. All interactive elements shall have minimum 44×44pt touch targets. |
| NF-07 | The app icon, default app name, and all system-level identifiers shall be non-identifying. A "stealth mode" setting shall allow the user to rename the app on their home screen to a neutral label. |
| NF-08 | The system shall support localization. Initial release in English with framework for Spanish, Portuguese, and Korean based on largest Genesis Process adoption markets. |

---

## 5. Feature comparison matrix

| Capability | Standard | Premium+ |
|------------|----------|----------|
| Daily FASTER Scale self-assessment | ✅ | ✅ |
| Behavioral indicator chip toggles | ✅ | ✅ (also available as fallback) |
| Visual position thermometer | ✅ | ✅ |
| Stage-adaptive coping resources | ✅ | ✅ |
| Structured journaling (Ah-ha / Uh-oh) | ✅ Manual entry | ✅ Auto-extracted + manual |
| Trend dashboard (7/30/90 days) | ✅ | ✅ Enhanced with pattern insights |
| Cumulative engagement metrics | ✅ | ✅ |
| Accountability partner sharing | ✅ 3-tier granularity | ✅ 4-tier granularity |
| SOS emergency alert | ✅ | ✅ Agent-assisted |
| Push notification privacy controls | ✅ | ✅ |
| Data encryption and deletion | ✅ | ✅ Extended (transcript vs. note) |
| AI-guided conversational check-in | ❌ | ✅ |
| Clinical probing and Double Bind exploration | ❌ | ✅ |
| Automated session notes generation | ❌ | ✅ |
| Multi-recipient configurable sharing | ❌ | ✅ |
| Cross-session pattern recognition | ❌ | ✅ |
| Voice input and text-to-speech | ❌ | ✅ |
| Therapist portal integration | ❌ | ✅ |
| Conversation-to-checklist fallback | ❌ | ✅ |