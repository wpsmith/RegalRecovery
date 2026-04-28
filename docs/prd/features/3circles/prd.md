# Product Requirements Documents
## Recovery App — Three Circles Core Features

**Document version:** 1.1
**Date:** April 2026
**Status:** Draft for review

**Changelog**
- v1.1: Added Starter Pack mode to PRD 3 as a third entry mode for users facing the blank page. Related updates to PRD 1 template system to support full pre-built sets.
- v1.0: Initial draft.

---

# PRD 1: Three Circles Builder with Templates

## Overview

The Three Circles Builder is the foundational feature of the recovery app. It transforms the paper-worksheet exercise used across SAA, SLAA, ITAA, and other recovery communities into an interactive, evolving, personalized recovery plan. Every other feature in the app — daily check-ins, urge support, pattern analysis, accountability — references the circles the user defines here.

## Problem Statement

People in recovery currently define their three circles on paper worksheets, in notebooks, or in notes apps. These static artifacts become stale, get lost, aren't shared effectively with sponsors, and provide no connection between the plan and daily execution. New users also struggle with the blank-page problem: they don't know what belongs in each circle, especially the middle, and often define circles in isolation in ways that are either too loose (enabling rationalization) or too rigid (setting up shame spirals).

## Goals

- Enable users to create a complete, personalized three circles plan in a single sitting (under 20 minutes)
- Reduce the blank-page problem through addiction-specific templates that starter users can accept, edit, or discard
- Support the clinically recommended creation sequence: inner → outer → middle
- Make the circles a living document that evolves with the user's recovery
- Preserve user autonomy — the app suggests; the user decides
- Support sponsor/therapist review of circles before they're committed

## Non-Goals

- The app does not diagnose, label, or tell users what belongs in any circle
- The app does not prescribe which recovery framework (SAA, SLAA, AA, SMART, etc.) the user must follow
- The app does not force users to use templates if they want to start blank
- V1 will not support collaborative real-time editing between users and sponsors (async review only)

## User Stories

**As a new user in early recovery**, I want guided help defining my circles so I don't stare at a blank page or copy someone else's plan that doesn't fit my situation.

**As someone who has done three circles work on paper before**, I want to import my existing circles quickly without being forced through an onboarding flow designed for beginners.

**As someone with co-occurring addictions** (e.g., sex/porn plus alcohol), I want to maintain separate circle sets for each area without them bleeding into each other.

**As a user whose recovery evolves over time**, I want to update my circles as I learn more about my patterns, without losing the history of what they used to say.

**As a user working with a sponsor**, I want my sponsor to review my circles before I commit them, and I want to flag specific items I'm uncertain about.

**As a user who initially defined circles too loosely**, I want the app to help me notice when my definitions might need tightening, without shaming me.

## Functional Requirements

### 1. Onboarding flow for first-time circle creation

**Step 1: Recovery area selection**
- Present recovery area options: Sex/pornography, Alcohol, Drugs, Gambling, Food/eating, Internet/technology, Work, Shopping/debt, Love/relationships, Other, Multiple areas
- Allow selecting multiple areas, which triggers separate circle sets
- Do not require users to self-label as "addicted" — use neutral phrasing: "What area of recovery are you working on?"

**Step 2: Framework preference (optional)**
- Ask whether the user is working with a specific fellowship (SAA, SLAA, AA, NA, SMART, OA, GA, DA, CoDA, ITAA, WA, other, none)
- Use this to adapt terminology throughout ("sobriety" vs. "abstinence" vs. "recovery") and to load framework-appropriate example content
- This step is fully skippable

**Step 3: Inner circle creation**
- Display plain-language definition: "These are the behaviors you're committing to stay away from completely. Hard boundaries. Engaging in any of these is what you're working to stop."
- Show clinical guidance inline: "Start with as few items as possible, focusing on the behaviors that have caused the most harm. You can add more later."
- Present template suggestions for the user's selected recovery area(s) as checkboxes
- Allow free-text entry of custom behaviors
- For each item, capture: behavior name (required), optional notes/context (free text), optional specificity detail ("What exactly counts as this?")
- Show count with soft guidance if under 1 item ("Add at least one behavior to continue") or over 10 items ("That's a lot for an inner circle. Consider whether some of these might fit better in your middle circle.")
- Do not hard-block based on count

**Step 4: Outer circle creation**
- Display definition: "These are the healthy behaviors, practices, and self-care that support your recovery. The life you're building toward."
- Offer two paths:
  - **SEEDS framework** (default, opt-out available): Social/Spiritual, Education, Exercise, Diet, Sleep — each with example behaviors and customizable targets
  - **Custom behaviors**: Free-form list of user-defined healthy behaviors
  - Users can combine both approaches
- For users who selected a spiritual/faith framework, include optional "Spiritual disciplines" category (prayer, meditation, scripture reading, worship, fellowship, service)
- Template suggestions tailored to recovery area
- Encourage expansiveness: "There's no limit to your outer circle. The more healthy practices, the better."

**Step 5: Middle circle creation**
- Display definition with extra care: "These are behaviors, moods, and patterns that aren't relapse themselves — but they show up before relapse. Early warning signs. Hitting the middle circle is not a loss of sobriety; it's a signal to reach out."
- Emphasize the non-punitive framing explicitly
- Offer structured categories to scaffold the blank page:
  - **Behavioral precursors** (contacting certain people, visiting certain places, specific rituals)
  - **Emotional states** (HALT+B: Hungry, Angry, Lonely, Tired, Bored) plus custom emotional triggers
  - **Environmental triggers** (times of day, locations, situations)
  - **Lifestyle warning signs** (isolation, overwork, skipping meetings, poor sleep, conflict)
  - **Uncertain behaviors** (things the user isn't sure whether to consider slippery)
- Template suggestions for each category based on recovery area
- Include an optional "middle bubble" sub-zone: behaviors that, while not technically inner circle, will almost certainly lead there — treated as a final warning before the inner circle

**Step 6: Review and commit**
- Display all three circles visually (concentric rings, red/yellow/green)
- Show total items per circle
- Allow final edits
- Offer three commit options:
  - **Commit now** — circles become active immediately
  - **Save as draft and share with sponsor** — circles are saved but not active; shareable link or code generated for sponsor review
  - **Save as draft, review later** — circles are saved but not active

### 2. Template system

**Template library structure**
- Templates are organized by recovery area (sex/porn, alcohol, drugs, gambling, food, technology, work, etc.)
- Each template contains suggested items per circle with a short rationale for why each item is commonly included
- Templates are versioned and can be updated by the app without affecting user data
- Templates are clearly marked as suggestions, not prescriptions: "These are examples from others in recovery. Use what fits. Ignore what doesn't."

**Two template formats**
- **Individual template items** — suggestions shown during the guided flow, accepted one at a time
- **Starter Packs** — complete, coherent pre-built sets spanning all three circles that a user can accept as a whole and then edit. See PRD 3, Section 2 for the user-facing experience. Each Starter Pack is a curated combination of template items designed to work together as a balanced starting recovery plan.

**Template content sourcing**
- Templates should be developed with input from clinicians (CSATs, addiction counselors) and community members (SAA, SLAA, ITAA literature)
- Avoid religious or culturally specific framing in default templates
- Provide optional faith-based template variants for users who select a spiritual framework
- Starter Packs require additional clinical review because users may accept them wholesale — content quality bar is higher

**Template interaction**
- Users can accept all, accept individual items, edit items inline, or reject all
- Users can return to templates after initial creation to pull in additional suggestions
- Templates never auto-populate without explicit user action
- Starter Packs, when accepted, populate all three circles at once and immediately enter an editing review state — the user must explicitly commit before the circles become active

### 3. Post-onboarding circle management

**View and edit circles**
- Home screen displays the three circles as the primary visual
- Tapping any circle reveals its contents
- Tapping any item allows editing, deleting, or moving to a different circle
- All edits trigger a version snapshot (see Version history below)

**Add items after onboarding**
- Users can add items to any circle at any time
- When adding to the inner circle, display a gentle confirmation: "Adding behaviors to your inner circle is a significant commitment. Consider discussing this with your sponsor or support person."
- When removing items from the inner circle, display a stronger confirmation: "Removing a behavior from your inner circle means you're no longer committing to stay away from it. This is a significant change. Would you like to discuss this with your sponsor first?"
- Do not hard-block any action

**Version history**
- Every change to any circle is versioned with timestamp and optional user note ("Why did I make this change?")
- Users can view their full circle history as a timeline
- Users can compare any two versions side by side
- Users can restore a previous version

**Quarterly review prompts**
- Every 90 days, prompt: "It's been a while since you reviewed your circles. Recovery evolves — do your circles still fit?"
- Review flow walks through each circle with reflection prompts
- Review is fully skippable and does not block app use

**Multiple circle sets**
- Users with co-occurring recovery areas can maintain separate circle sets
- Each set has a name, recovery area tag, and independent circles
- The home screen allows switching between sets or viewing all
- Daily check-ins apply to the active set

### 4. Sponsor review flow

- Users can generate a shareable read-only view of their draft circles
- Sponsors can view via a link or code without needing the app
- Sponsors can leave comments on individual items (V1: async only)
- Users see sponsor comments and can accept, reject, or modify items accordingly
- Once the user commits, the sponsor relationship (if established in-app) can be notified

### 5. Guardrails against common pitfalls

- **Vague definitions check**: When a user adds an item with very short text (under 5 words) or ambiguous phrasing ("be better," "stop being bad"), offer a prompt: "Can you make this more specific? Specific definitions are easier to recognize and act on."
- **Excessive rigidity check**: When a user's inner circle exceeds 10 items, offer: "Many people find starting with fewer inner circle items more sustainable. Are there items that might fit better in your middle circle?"
- **Moral incongruence check**: Include optional psychoeducation content before the inner circle step explaining the difference between behaviors that cause harm and behaviors that cause distress due to values conflict. Do not assume or pathologize — make the content available, not mandatory.
- **Isolation check**: If the user commits circles without using the sponsor review flow, gently suggest: "Would you like to share these with a sponsor or trusted person? Defining recovery in isolation can be harder."

## Non-Functional Requirements

- Onboarding flow must complete in under 20 minutes for median users
- All circle data must be stored locally first, with optional encrypted cloud sync
- All user-generated content must be end-to-end encrypted if synced
- The builder must work fully offline
- Template data must be cacheable and updateable independently of app versions
- Accessibility: screen reader compatible, high-contrast mode, adjustable text size
- All copy must pass a trauma-informed language review (no "failure," "clean/dirty," "weakness," "addict")

## Success Metrics

- **Completion rate**: % of users who start onboarding and complete all three circles (target: >70%)
- **Template usage**: % of users who accept at least one template item (target: >60%)
- **Sponsor review**: % of users who share draft circles with a sponsor before committing (target: >25%)
- **Circle evolution**: % of users who edit their circles in the first 30 days (target: >40% — indicates active engagement, not just one-time setup)
- **Quarterly review engagement**: % of users who complete at least one quarterly review (target: >50%)

## Open Questions

- Should the app offer AI-assisted circle suggestions based on user journaling and check-in patterns over time? (Privacy implications significant.)
- How do we handle users who want to import circles from a paper worksheet? (OCR, photo upload, manual entry wizard?)
- What's the right level of friction for removing items from the inner circle?
- Should the sponsor review flow require the sponsor to have an account, or support fully anonymous async review via link?

---

# PRD 2: Basic Pattern Visualization (Which Circle Over Time)

## Overview

Pattern visualization transforms daily check-in data into visual insights that help users see where they're living, how they're trending, and what's driving movement between circles. This feature turns the app from a static recovery plan into an active feedback loop — showing users their recovery in motion.

## Problem Statement

Users in recovery often lose perspective on how they're actually doing. Memory is unreliable, shame distorts recall, and a single bad day can feel like a failed month. Without objective data, users can't see that they've been mostly in the outer circle for weeks with occasional middle-circle drift, or that their middle-circle drift consistently happens on Fridays, or that sleep deprivation reliably precedes their urge spikes. Paper journals don't surface these patterns. Existing recovery apps show binary streak counters that erase nuance and reset to zero after any slip.

## Goals

- Show users which circle they've been living in over time, with visual clarity
- Surface meaningful correlations (time patterns, trigger patterns, SEEDS correlations) that users would miss on their own
- Reframe slips and setbacks as data points in a longer story, not as failures
- Make middle-circle drift visible early, before it becomes a slip
- Respect the user's emotional state — visualizations should inform, not punish

## Non-Goals

- V1 will not offer predictive AI forecasting ("you're 73% likely to slip tomorrow")
- V1 will not compare users to others or provide any social benchmarks
- V1 will not include advanced statistical analysis beyond clear correlations
- Visualizations do not replace clinical assessment or sponsor conversations

## User Stories

**As a user one month into recovery**, I want to see that I've been mostly in the outer circle despite two middle-circle days, so I can maintain perspective instead of catastrophizing.

**As a user struggling with middle-circle drift**, I want to know if there's a pattern — certain days, times, or triggers — so I can plan ahead.

**As a user who just had a slip**, I want to see what was happening in the days before so I can understand what led up to it, without being shamed by a "streak reset" screen.

**As a user sharing progress with a sponsor**, I want a simple visual summary I can show or send.

**As a user who has been in recovery for over a year**, I want to see long-term trends that validate the work I've been doing.

## Functional Requirements

### 1. Primary visualization: Circle timeline

**Display**
- Horizontal timeline showing which circle the user logged each day
- Color-coded bands: red (inner circle), yellow (middle circle), green (outer circle), gray (no check-in)
- Default view: last 30 days
- Zoom controls: 7 days, 30 days, 90 days, 1 year, all time
- Tapping any day reveals the full check-in details for that day

**Summary stats above the timeline**
- Days in outer circle (green)
- Days with middle circle contact (yellow)
- Days with inner circle contact (red)
- Days without check-in (gray, shown neutrally — not as "missed")
- Current consecutive outer-circle days (shown as context, not as a primary streak counter)

**Framing copy**
- Avoid "streak lost" language
- Avoid percentages that imply grading ("you were 73% recovered this month")
- Use descriptive framing: "You logged 22 outer circle days, 6 middle circle days, and 2 inner circle days this month. Each one is data for understanding your recovery."

### 2. Mood and urge overlay

- Optional overlay on the circle timeline showing daily mood (1–5 emoji scale) and urge intensity (0–10)
- Toggle on/off
- Helps users visually correlate emotional state with circle movement

### 3. Pattern insight cards

**Auto-generated insights** (shown on a dashboard, refreshed weekly)
- Day-of-week patterns: "You tend to have middle circle contact on Fridays. Want to plan ahead for this Friday?"
- Time patterns: "Your urges tend to spike between 10pm and midnight."
- Trigger correlations: "On days you log 'lonely,' you're 3x more likely to have middle circle contact."
- Protective correlations: "Days you call your sponsor, you're much more likely to stay in the outer circle."
- Sleep correlations: "Nights under 6 hours of sleep precede 60% of your urge spikes."
- SEEDS correlations: "Days when you exercise tend to be outer circle days."

**Insight guardrails**
- Only show insights backed by at least 14 days of data and a clear pattern (minimum threshold to avoid spurious correlations)
- Frame insights as observations, not predictions
- Always include a constructive next step: "Want to add Fridays to your weekly plan review?"
- Never surface insights that could be shaming ("You slip most often after talking to your mother")
- Allow users to dismiss insights or turn off categories they find unhelpful

### 4. Middle circle drift alert

- When check-ins show 3+ middle circle days in a 7-day window, surface a gentle, non-punitive alert
- Alert copy: "You've been in your middle circle a few times this week. That's useful information — it means you're noticing. Would you like to [call your sponsor / review your circles / try a grounding exercise]?"
- Alert is one-time per drift episode; does not repeat daily
- Fully dismissible

### 5. Weekly and monthly summaries

**Weekly summary** (delivered Sunday evening or user-selected time)
- Brief visual showing the week's circle distribution
- One insight card if any new pattern is detected
- One reflection prompt
- One outer circle win to highlight
- Shareable as an image or summary card

**Monthly summary**
- Full circle timeline for the month
- Top 3 insights
- Mood and urge trends
- SEEDS domain summary
- Shareable format for sponsor or therapist

### 6. Sharing with support people

- Export summary as image, PDF, or shareable link (read-only)
- Granular controls: share circle distribution only, or include check-in details, mood, urges, or SEEDS data
- Generated shares expire after a user-selected window (24 hours, 7 days, never)

### 7. Reframing slips in visualizations

- When a day is logged as inner circle contact, the visualization shows the slip in context, not in isolation
- Show the days leading up to it and the days following — highlight recovery
- Include a "recovery total" alongside any streak counter: "You've been actively working on your recovery for 347 days, including 12 days of learning through setbacks"
- Offer a journal prompt from the slip day, if one exists

## Non-Functional Requirements

- Visualizations must render within 500ms on median devices
- All pattern analysis must happen on-device to preserve privacy
- Correlation calculations must be deterministic and reproducible
- Visualizations must be accessible (screen reader descriptions of trends, high contrast mode, color-blind-safe palettes)
- No visualization should ever show data the user hasn't explicitly agreed to share externally
- Works fully offline

## Success Metrics

- **Weekly visualization engagement**: % of users who open the timeline view at least once per week (target: >50%)
- **Insight card engagement**: % of insights that receive user interaction (tap, dismiss, or act on) (target: >40%)
- **Middle circle drift alert responsiveness**: % of alerts that lead to a user action within 24 hours (sponsor call, grounding exercise, review) (target: >30%)
- **Sharing**: % of users who share a summary with a sponsor or therapist at least once (target: >15%)
- **User-reported usefulness**: Survey rating of visualization helpfulness (target: >4.0/5.0)

## Open Questions

- What's the minimum data threshold before we show insights? (Risk of spurious correlations with small samples.)
- How do we handle users who check in inconsistently — do gaps skew the visualization?
- Should we offer a "rough week" mode that suppresses certain insights during difficult periods?
- How prominently should the recovery timeline be displayed on the home screen relative to the circles themselves?

---

# PRD 3: Optimizing the Experience of Building the Three Circles

## Overview

The Three Circles Builder exists (PRD 1). This PRD focuses on the subjective experience of going through it — the tone, pacing, emotional safety, and design decisions that determine whether users complete the flow, feel supported while doing it, and produce circles they actually use.

The builder is the most emotionally loaded experience in the app. Users are being asked to name behaviors they feel shame about, identify warning signs they may have been ignoring, and commit to a plan. Getting this experience right is the difference between a user who completes and engages versus one who abandons the app after one session.

## Problem Statement

Defining three circles is hard. Users face the blank page, confront shame, wrestle with uncertainty about what belongs where, and often give up or produce vague, unusable circles. Research shows the most common failures are: circles defined in isolation leading to self-deceptive looseness or punishing rigidity, underestimated middle circles, vague inner circle definitions inviting rationalization, and shame-based framing that turns the exercise into a punishment. A well-designed builder must actively counter all of these failure modes while preserving user autonomy and completing in a reasonable timeframe.

## Goals

- Make users feel emotionally safe throughout the process
- Reduce the blank-page problem through templates, examples, and reflection prompts
- Pace the experience so users don't burn out mid-flow
- Catch common pitfalls without hard-blocking or shaming
- Produce circles that are specific enough to be actionable, personal enough to fit the user, and balanced enough to be sustainable
- Meet users where they are: newcomers need more scaffolding, experienced users need less friction

## Non-Goals

- This is not a therapy session — the app does not replace clinical support
- Optimization is not about speed at all costs — some friction is therapeutic
- The app does not attempt to determine whether the user "really" has an addiction

## User Stories

**As a user who feels deep shame about my behaviors**, I want the app to feel like a compassionate friend, not a clinical checklist or a judgmental authority.

**As a user who has never done recovery work before**, I want enough explanation and examples that I understand what I'm being asked to do without feeling like I'm being lectured.

**As a user who has done years of 12-step work**, I want to move through quickly without being forced through beginner content.

**As a user who gets overwhelmed easily**, I want the option to complete the builder in multiple sessions without losing progress.

**As a user who is anxious or in crisis right now**, I want the app to recognize that and offer a lighter-touch path or crisis resources.

## Functional Requirements

### 1. Pre-builder emotional check-in

Before entering the builder, a brief (optional, skippable) emotional check-in:
- "How are you feeling right now?" (5-point scale with labels: struggling, low, okay, good, strong)
- If user reports "struggling," offer three paths:
  - **Start anyway** — standard flow
  - **Save for later** — schedule a reminder for a better time
  - **Get support first** — crisis resources, sponsor contact, grounding exercise
- If user reports "low," suggest the lighter-touch "guided mode" (see below)
- Never prevent users from proceeding, but offer alternatives

### 2. Three entry modes

Users select (or are routed to) one of three modes at the start of the builder. The choice is never final — users can switch modes mid-flow without losing progress.

**Guided mode** (default for new users)
- Full explanations and context for each circle
- Reflection prompts before and after each circle
- Template suggestions offered as individual items to accept or decline
- More pacing, more breaks, more encouragement
- Estimated time: 20–30 minutes
- Can be paused and resumed

**Starter Pack mode** (for users who can't face the blank page)
- For users who are overwhelmed, in early recovery, in crisis, or simply stuck on where to begin
- Presents a curated, complete, pre-built set of circles for the user's recovery area — inner, outer, and middle fully populated with clinically and community-reviewed content
- User reviews the pack, edits any items that don't fit, removes items that aren't relevant, adds anything missing, and commits
- Estimated time: 10–15 minutes
- Explicitly framed as a starting point, not a finished plan: "This is a starting point built from what's helped others in similar situations. Your circles will become more personal over time as you learn what fits you. For now, this gives you something to work with."
- All items in the pack are tagged as "from Starter Pack" in version history so users (and their sponsors) can see which items were accepted wholesale versus personalized
- After commit, the app schedules a 14-day check-in specifically prompting: "You started with a Starter Pack two weeks ago. Now that you've been using your circles, is there anything you'd like to change to make them more yours?"

**Express mode** (for experienced users)
- Minimal explanations, templates ready to tap
- Streamlined flow
- Estimated time: 5–10 minutes
- Best for users importing existing paper-worksheet circles

**A fourth path — Import from paper** — offers to photograph or manually transcribe existing circles into the app structure.

**Mode selection experience**
- At the start of the builder, after the emotional check-in, present the mode options with honest, non-judgmental descriptions
- Recommended routing based on the pre-builder emotional check-in:
  - "Struggling" → offer Starter Pack first, guided second
  - "Low" → offer guided first, Starter Pack second as "if this feels like too much"
  - "Okay," "Good," "Strong" → offer guided first (for new users) or express (if user has indicated prior experience)
- The Starter Pack option must never be framed as "the easy way out" or "for people who aren't serious" — it is framed as a legitimate, clinically valid path for anyone who needs it
- Users can switch modes mid-builder without losing work; switching to Starter Pack merges the pack into anything the user has already written rather than overwriting

**Starter Pack content requirements**
- Every Starter Pack must be reviewed by both a clinician and a recovery community member before release
- Packs must exist for each supported recovery area
- Packs must be available in faith-based and secular variants
- Packs must be available in LGBTQ+-affirming variants
- Each item in a pack includes a short rationale the user can tap to understand why it's there
- Packs are designed to be deliberately balanced: modest inner circle (3–5 items), substantial outer circle built around SEEDS, rich middle circle (6–10 items covering behavioral, emotional, environmental, and lifestyle warning signs) — modeling good circle-building practice
- See PRD 1, Section 2 for template system requirements

### 3. Pacing and breaks

- Progress indicator shows which circle the user is on (inner, outer, middle)
- After completing each circle, show a "pause point" with three options: continue, take a break (saves progress), or share with sponsor
- If the user has been in the builder for over 15 minutes without a break, suggest one: "You've been working on this for a while. Would you like to save and come back?"
- If the user edits the same item more than 3 times, gently suggest: "Take your time with this. You can always change it later. Would you like to move on for now?"

### 4. Reflection prompts (optional, between steps)

**Before inner circle**
- "The inner circle is the hardest to start with — but it's the foundation. Take a breath. You're not committing to perfection. You're naming what you want to stop."
- Optional deeper prompt: "What brought you here today? What's the one behavior that's been hurting you most?"

**Before outer circle**
- "Now we shift. The outer circle isn't about what to avoid — it's about the life you want to build. This is the good part."
- Optional prompt: "When you imagine yourself 90 days from now, living the way you want to live, what are you doing?"

**Before middle circle**
- "The middle circle is the most important, and often the hardest to see. These are the warning signs — the moods, situations, and behaviors that show up before you slip. Hitting the middle circle is not failure. It's noticing."
- Optional prompt: "Think back to the last time you acted out. What were you feeling in the hours or days before? What did you do that now looks like a warning sign?"

**After commit**
- "You've just built your recovery plan. This isn't the end — it's a starting point. Your circles will grow and change as you learn. What matters is that you now have something to come back to."

### 5. Guardrails and pitfalls (implementation details)

**Specificity nudge**
- If an item is under 5 words or uses vague language (detected via a small keyword list: "be," "stop," "better," "good," "bad," "right"), show a gentle inline prompt: "Could you make this more specific? Specific definitions are easier to act on. For example, instead of 'stop being bad,' try 'no pornography on my phone.'"
- Dismissible, non-blocking

**Overload nudge (inner circle only)**
- If the inner circle exceeds 8 items, show: "Many people find starting with fewer items more sustainable. Would you like to move some to your middle circle?"
- Non-blocking

**Middle circle depth nudge**
- If the middle circle has fewer than 3 items, show: "Most people find their middle circle is the largest — it's where the warning signs live. Would you like to see some examples?"
- Offer category prompts (behavioral, emotional, environmental, lifestyle) as scaffolding
- Non-blocking

**Moral incongruence check (optional, recovery-area specific)**
- For sex/porn recovery, include an optional link to a short explainer: "Some behaviors feel wrong because they cause real harm. Others feel wrong because they conflict with values or beliefs. Both matter, but they call for different responses. Want to learn more?"
- Never mandatory, never assumes the user's situation
- Presented as information, not a challenge

**Isolation nudge**
- At the commit step, if the user hasn't shared with a sponsor or support person: "Would you like to review these with a sponsor or trusted person before committing? Defining recovery in community is part of how this tool works best."
- Offer: share now, skip for now, commit without sharing

### 6. Template experience

- Templates appear as optional suggestions, clearly marked: "Examples from others in recovery. Tap any to add."
- Each template item includes a brief "why" — e.g., "Pornography use — many people in recovery identify this as a primary behavior they want to stop because..."
- Templates are organized in collapsible sections by category
- Never pre-checked or auto-selected
- Templates are updated independently of app releases

### 7. Examples and definitions on demand

- Every screen has a small, unobtrusive "?" or "examples" link
- Tapping reveals: the clinical/community definition, 3–5 example items, a brief explanation of common pitfalls
- Examples are recovery-area specific
- Opening examples does not interrupt the flow

### 8. Save and resume

- Every screen auto-saves progress
- If the user leaves the builder, they can return exactly where they left off
- A small banner on the home screen shows: "You started building your circles — want to continue?"
- Draft circles are distinct from committed circles; drafts don't activate any app features until committed

### 9. Tone, voice, and language guidelines

**Do**
- Use "you" and "your," never "the user"
- Use person-first language: "people in recovery," not "addicts"
- Use compassionate framing: "this is hard work," "take your time," "you're doing something brave"
- Use active, empowering verbs: "choose," "define," "build"
- Acknowledge difficulty directly: "this part can be painful"
- Offer exits and breaks throughout

**Don't**
- Use words: "addict," "abuser," "clean," "dirty," "sober" (unless user selected a framework that uses it), "failure," "weakness," "should," "must"
- Use clinical jargon without plain-language explanation
- Assume the user's religious, sexual, or cultural background
- Use emojis in serious content
- Use urgency or countdown pressure
- Use comparative language ("most people struggle with this" is okay; "you should be able to do this" is not)

### 10. Accessibility and inclusion

- All content reviewed for cultural neutrality
- Templates available for LGBTQ+-affirming recovery (explicit note that sexual orientation and consensual practices are not disorders)
- Gender-neutral default language
- Screen reader fully supported with descriptive labels
- High-contrast mode available
- Adjustable text size throughout
- Low-literacy alternative content available (simpler language, more visual guidance)

### 11. Exit and crisis handling

- A small, always-visible "I need support" button in the top corner
- Tapping reveals: crisis resources (988, SAMHSA), grounding exercise, call a contact, exit to home
- If the user exits the builder from a crisis screen, save draft and suggest: "Take care of yourself first. Your circles will be here when you're ready."

## Non-Functional Requirements

- Median completion time in guided mode: 20–25 minutes
- Median completion time in express mode: 5–8 minutes
- Drop-off rate per step should be monitored; no single step should have >15% drop-off
- All content must pass a trauma-informed language review before release
- Content should be reviewed by recovery community members across multiple addiction types and identities before launch
- No builder content can trigger a notification or alert to any other party without explicit user action

## Success Metrics

- **Emotional safety score**: Post-builder survey asking "Did you feel supported during this process?" (target: >4.2/5.0)
- **Completion rate in guided mode**: >70%
- **Completion rate in Starter Pack mode**: >85% (higher because the lift is lower)
- **Completion rate in express mode**: >85%
- **Mode distribution**: Monitor what % of users choose each mode — no specific target, but Starter Pack uptake should be meaningful (>20% of new users) to validate the decision to build it
- **Starter Pack personalization**: % of Starter Pack users who edit at least one item before committing (target: >60% — indicates users are engaging, not rubber-stamping)
- **Starter Pack 14-day revision**: % of Starter Pack users who return within 14 days to personalize further (target: >50%)
- **Save and resume usage**: % of users who use save-and-resume at least once (target: 30–50% — indicates users are pacing themselves)
- **Post-builder engagement**: % of users who return to edit or review their circles within 30 days (target: >60%)
- **Circle quality proxy**: % of committed circles with specific (5+ word) items (target: >75%)
- **Sponsor review uptake**: % of users who use the sponsor review option (target: >25%)
- **Pitfall guardrail engagement**: % of users who act on specificity or overload nudges when shown (target: >40% — indicates nudges are useful, not annoying)

## Open Questions

- How do we measure the quality of circles beyond specificity length? (Sponsor review? Self-rating?)
- Should the emotional check-in at the start affect the flow dynamically (fewer prompts for low-affect users, more for struggling users)?
- How do we handle users who complete the builder and then immediately request major changes — is that a red flag or normal?
- What's the right default: guided mode, Starter Pack, or express? Should we detect based on signals (fellowship selected, emotional check-in, prior experience)?
- Should Starter Pack users who never personalize beyond the initial pack receive any additional nudges, or is that patronizing?
- How many Starter Pack variants should we launch with per recovery area? (Minimum viable: 1 secular + 1 faith-based + 1 LGBTQ+-affirming per area.)

## Dependencies

- PRD 1 (Three Circles Builder) must be implemented as the foundation
- Trauma-informed content review process must be in place
- Template content must be written and reviewed by clinical and community reviewers
- Accessibility review process must be in place
- Crisis resource integration (988, SAMHSA) must be functional

---

**End of PRDs**