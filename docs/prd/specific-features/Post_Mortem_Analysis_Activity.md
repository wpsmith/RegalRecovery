# Activity: Post-Mortem Analysis

**Priority:** P1

**Description:** Structured review of the entire last 24 hours after a relapse or near-miss event, tracing the full progression from normalcy to acting out.

---

## User Stories

- As a **recovering user**, I want to walk through the full 24 hours leading up to a relapse, so that I can understand the chain of events, emotions, and decisions that led me there
- As a **recovering user**, I want to identify the specific decision points where I could have intervened, so that I can build a concrete plan for next time
- As a **recovering user**, I want to map my FASTER Scale stages onto the timeline, so that I can recognize how far I had progressed toward relapse before I noticed
- As a **recovering user**, I want to see a visual timeline of my progression, so that the pattern becomes clear and memorable rather than abstract
- As a **recovering user**, I want to create an action plan from my analysis, so that I leave with specific changes I can implement immediately
- As a **recovering user**, I want to share my completed post-mortem with my sponsor or counselor, so that we can discuss it together and strengthen my recovery plan
- As a **recovering user**, I want to review past post-mortems, so that I can spot recurring patterns across multiple relapses and address root causes
- As a **recovering user**, I want the post-mortem process to feel compassionate rather than punishing, so that I engage with it honestly instead of avoiding it out of shame
- As a **sponsor**, I want to see my sponsee's post-mortem analysis, so that I can help them identify blind spots and reinforce healthier decision-making

---

## Guided Walkthrough Sections

The post-mortem guides the user through a structured reconstruction of their day, broken into six sections:

### 1. The Day Before
- What was your emotional and spiritual state going into the day?
- Had you been keeping up with your recovery practices?
- Were there any unresolved conflicts, stressors, or unmet needs?
- Free-text input with optional mood rating (1-10)

### 2. Morning
- How did the day start? Did you complete your morning commitment?
- What was your mood when you woke up?
- Did anything notable happen in the first few hours?
- Auto-populated data (if available): morning commitment completion status, mood rating, affirmation viewed

### 3. Throughout the Day
- Walk through key events, interactions, and emotional shifts hour by hour
- Guided time-block prompts (morning, midday, afternoon, evening) or free-form hour-by-hour entry
- For each block: What were you doing? Where were you? Who were you with? What were you thinking and feeling?
- Identify when warning signs first appeared (FASTER Scale stages, PCI behaviors, acting-in behaviors)

### 4. The Build-Up
- When did you first notice something was off?
- What triggers accumulated? (link to trigger categories from Urge Logging: Emotional, Environmental, Relational, Physical, Digital, Spiritual)
- What did you do — or not do — in response?
- Were there moments you considered reaching out for help but didn't? Why?
- Decision point identification: "At this moment, I could have _____ but instead I _____"

### 5. The Acting Out
- What happened? What were you thinking and feeling in that moment?
- Which addiction was involved? (auto-linked to relapse log if already recorded)
- How long did the episode last?
- Free-text input — no judgment framing, compassionate tone throughout

### 6. Immediately After
- How did you feel? (Feelings Wheel integration)
- What did you do next?
- Did you reach out to anyone?
- What do you wish you had done differently in this moment?

---

## Visual Timeline

- Plot the full 24-hour progression as an interactive timeline
- Each section maps to a segment on the timeline
- Events, emotions, and decisions are plotted as data points along the timeline
- FASTER Scale stages overlaid as color-coded bands (green → yellow → orange → red)
- Trigger accumulation shown as stacking indicators
- Decision points marked with distinct icons — tappable to view the user's reflection on what they could have done differently

---

## Trigger Identification

- Surface-level triggers identified via quick-select chips (same categories as Urge Logging)
- Deeper exploration prompts: "What was underneath that trigger?"
  - Surface trigger → Underlying emotion → Core wound
  - Example: Boredom → Loneliness → Fear of being unlovable
- Pattern linking: "This trigger also appeared in your post-mortem from [date]"

---

## FASTER Scale Mapping

- After completing the walkthrough, the user maps which FASTER stages were active at each point in the timeline
- Pre-populated suggestions based on the user's descriptions (e.g., mentions of skipping meetings → Forgetting Priorities)
- User confirms or adjusts the mapping
- Result: a clear visual of how the FASTER progression unfolded across the day

---

## Action Plan

- User creates 3-5 specific, actionable changes based on their analysis
- Structured format: "At [point in timeline], I could have [alternative action]"
- Each action item can be tagged to a recovery category: spiritual, relational, emotional, physical, practical
- Option to convert action items into commitments or daily/weekly goals within the app
- Action plan saved alongside the post-mortem for future reference

---

## Sharing & Visibility

- Completed post-mortem shareable with sponsor, counselor, or coach (opt-in, per-analysis basis)
- Shared version can include full analysis or summary only (user chooses)
- Support network members see shared post-mortems in their dashboard
- Export as PDF for use in therapy sessions or sponsor meetings

---

## History & Pattern Analysis

- All saved post-mortems accessible in reverse chronological order
- Browse by date, filter by addiction type
- Cross-analysis insights:
  - Most common triggers across all post-mortems
  - Most frequent FASTER stage at the point of no return
  - Most common time of day for acting out
  - Recurring decision points where intervention was missed
- Link post-mortems to related urge logs and FASTER Scale check-ins

---

## Tone & Messaging

- All prompts written in a compassionate, non-judgmental tone
- Opening message: "A relapse is painful, but it's also an opportunity to learn. This process will help you understand what happened so you can build a stronger foundation going forward."
- Closing message: "Thank you for your honesty and courage. Every insight you've gained here is a step toward lasting freedom."
- No shame-based language — focus on learning, growth, and grace

---

## Integration Points

- Linked from Relapse Logging flow (prompted automatically after logging a relapse)
- Linked from FASTER Scale (if user selects "R — Relapse")
- Feeds into Analytics Dashboard (post-mortem completion rate after relapses, trigger trends)
- Action plan items can auto-populate into Weekly/Daily Goals or Commitments
- Saved analysis linkable to future urge logs and FASTER Scale check-ins for pattern tracking

---

## Edge Cases

- User starts post-mortem but doesn't finish → Auto-save progress, prompt to resume later
- Multiple relapses in a short period → Each can have its own post-mortem, or user can do a combined analysis covering the full period
- User completes relapse log but skips post-mortem → Gentle reminder after 24 hours: "Taking a few minutes to reflect on what happened can strengthen your recovery. Would you like to complete a post-mortem?"
- Near-miss events (urge resisted) → User can optionally complete a post-mortem for near-misses to reinforce what worked
- Offline → Full post-mortem flow available offline, synced when connection restored
