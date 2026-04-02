# Activity: Partner Activities — Redemptive Living

**Priority:** P2

**Description:** Partner-provided structured recovery exercises from Redemptive Living, a recovery methodology focused on emotional health, empathy development, and relational repair. These activities go beyond sobriety maintenance into the deeper character and relational work that sustains long-term recovery and rebuilds what addiction destroyed.

---

## User Stories

- As a **recovering user**, I want access to structured Redemptive Living exercises within the app, so that I can do the deep emotional and relational work my counselor or coach assigns without juggling separate workbooks and paper journals
- As a **recovering user**, I want to complete timed journaling exercises (T30/T60), so that I can develop the discipline of sustained emotional processing rather than skimming the surface of my feelings
- As a **recovering user**, I want to practice empathy exercises, so that I can rebuild my capacity to understand and care about how my addiction has affected the people I love
- As a **recovering user**, I want to use the Backbone tool to identify my core needs and the healthy activities that meet them, so that I stop turning to addiction as a counterfeit solution for unmet needs
- As a **recovering user**, I want to use the Bow Tie tool to map how events lead to thoughts, feelings, and behaviors, so that I can interrupt my reactive patterns before they lead to acting out
- As a **recovering user**, I want to create empathy maps for the people my addiction has hurt, so that I can see the full impact of my behavior through their eyes — not just my own
- As a **recovering user**, I want to identify and categorize threats to my recovery, so that I can build specific defenses instead of being blindsided
- As a **recovering user**, I want my completed partner exercises saved and accessible in my history, so that I can revisit them, track my growth, and share them with my counselor or sponsor
- As a **spouse**, I want my partner to engage with empathy exercises and empathy mapping (with visibility if they grant it), so that I can see evidence of genuine understanding — not just sobriety
- As a **counselor**, I want to assign specific Redemptive Living exercises to my clients and see their completed work, so that I can guide their deeper recovery between sessions
- As a **recovering user**, I want these exercises to feel like meaningful recovery work — not busywork — so that I engage with them honestly and see real change in myself and my relationships

---

## Sub-Activities Overview

Redemptive Living includes seven structured sub-activities. Each is independently trackable, assignable by a counselor or coach, and saved to the user's history.

| Sub-Activity | Purpose | Typical Frequency |
|---|---|---|
| T30/60 Journaling | Sustained emotional processing and planning | 2-3x per week |
| Emotional Journaling | Identifying and naming emotions | Daily |
| Empathy Exercises | Developing empathy for self and others | Weekly |
| Backbone | Identifying core needs and commitments | One-time setup, periodic review |
| Bow Tie | Mapping reactive patterns | As needed / weekly |
| Empathy Mapping | Understanding others' experience of your addiction | As assigned / periodic |
| Threats | Identifying and defending against recovery threats | One-time setup, periodic review |

---

## Sub-Activity: T30/60 Journaling Entries

### Description

Timer-based journaling exercises designed to build the capacity for sustained emotional processing. T30 is a 30-minute exercise; T60 is a 60-minute exercise. The structure prevents the user from skimming the surface — the timer ensures they sit with their thoughts long enough for real insight to emerge.

### Structure

**T30 — 30-Minute Journaling:**

The T30 is divided into three 10-minute segments, each with a specific focus:

1. **Segment 1: What happened** (10 minutes)
   - Describe a recent event, interaction, or situation that affected you emotionally
   - Focus on facts and observations — what happened, where, when, who was involved
   - Prompt: "Describe the situation as objectively as you can. What actually happened?"

2. **Segment 2: What I felt** (10 minutes)
   - Explore the emotions the event triggered
   - Feelings Wheel available as a reference
   - Prompt: "What emotions came up for you? When did you first notice them? Where did you feel them in your body?"

3. **Segment 3: What I'll do** (10 minutes)
   - Identify a healthy response, action step, or insight to carry forward
   - Prompt: "Based on what you've discovered, what is one thing you can do differently? What do you need?"

**T60 — 60-Minute Journaling:**

The T60 follows the same three-segment structure but with 20 minutes per segment, allowing deeper exploration. An additional optional segment is available:

4. **Segment 4: Connection to recovery** (optional, open-ended)
   - How does this event, emotion, or pattern relate to your addiction and recovery journey?
   - Prompt: "How does this connect to your recovery? What would the old you have done? What does the new you choose?"

### Flow

1. User selects T30 or T60
2. Timer starts for Segment 1 with prompt displayed at top of screen
3. Free-text journaling area (unlimited length, voice-to-text available)
4. Timer visible but non-intrusive — gentle chime and prompt transition at each segment boundary
5. User can continue writing past the segment time (timer pauses, "Continue" or "Move to next segment" options)
6. After final segment: review screen showing all segments together
7. Save to history

### Technical Notes

- Timer runs on-device (works offline)
- Auto-save every 30 seconds during writing
- If user exits mid-exercise, progress saved and resumable within 24 hours
- Screen stays awake during active journaling

---

## Sub-Activity: Emotional Journaling

### Description

Structured journaling focused on identifying, expressing, and processing emotions healthily. This is also available as a standalone activity elsewhere in the app — when accessed through Redemptive Living, it follows the same format but is tagged as a partner activity for tracking purposes.

### Structure

Simple 3-field entry — quick and low-friction:

1. **What emotion?** — Select via Feelings Wheel or emoji picker
2. **Why?** — Free-text input (voice-to-text available), 1000 char max
3. **Intensity** — Slider scale 1-10 (range allows -1 to 15 to capture extremes beyond the normal scale)

### Additional Redemptive Living Context

When accessed through the Redemptive Living section, the following optional fields are available:

- **When did you first experience this emotion?** — Free-text prompt encouraging the user to trace the emotion back to an early life experience (ages 6-16)
  - Prompt: "Can you remember a time early in life when you felt this same way? What was happening?"
- **What did you do with this emotion?** — How did you respond?
  - Quick-select: Expressed it healthily, Stuffed it, Numbed it, Acted out, Talked to someone, Prayed, Journaled, Other
- **What would a healthy response look like?** — Free-text, 500 char max

### Notes

- Multiple entries per day allowed
- Tracks emotional patterns over time (most frequent emotions, average intensity, time-of-day trends)
- Feeds into Tracking System (consecutive days with at least one entry)
- Tagged as "Redemptive Living" when completed through the partner activities section; tagged as standalone when completed through the main Emotional Journaling activity — both count toward the same streak

---

## Sub-Activity: Empathy Exercises

### Description

Exercises designed to develop and strengthen the user's capacity for empathy — for themselves, their spouse, their children, and others affected by their addiction. Empathy atrophy is a hallmark of active addiction; these exercises rebuild it intentionally.

### Exercise Types

**1. Self-Empathy Exercise**
- Prompt: "Think about yourself in a recent moment of struggle. What were you feeling? What did you need? What would you say to a friend in that same situation?"
- Guided reflection: describe the situation → identify the feeling → identify the unmet need → write a compassionate response to yourself
- Purpose: break the cycle of self-contempt that fuels relapse

**2. Spouse/Partner Empathy Exercise**
- Prompt: "Think about a recent moment when your addiction affected your spouse. Put yourself in their shoes completely. What did they see? What did they feel? What do they need from you?"
- Guided reflection: describe what your spouse experienced → identify what they likely felt → identify what they need → write what you wish you could say to them
- Purpose: develop genuine understanding of betrayal trauma from the spouse's perspective

**3. Child Empathy Exercise**
- Prompt: "Think about how your addiction has affected your children — even in ways they may not fully understand yet. What have they experienced? What might they be feeling?"
- Guided reflection: describe what your child(ren) have witnessed or sensed → identify what they might be feeling → identify what they need from you → write a commitment to your child
- Purpose: confront the impact on children without minimization

**4. Other Person Empathy Exercise**
- Prompt: "Think about someone else your addiction has affected — a friend, family member, coworker, or community member."
- Same guided reflection structure as above
- Purpose: expand empathy beyond immediate family

### Flow

1. User selects exercise type
2. Guided prompts presented one at a time with generous text input areas
3. Feelings Wheel available as reference throughout
4. Voice-to-text available for all inputs
5. Review screen showing complete exercise
6. Save to history
7. Optional: share with counselor or sponsor

---

## Sub-Activity: Backbone

### Description

A foundational tool for identifying core needs, the healthy activities that meet those needs, and the commitments required to maintain them. The "backbone" is the structural support system the user builds to replace the counterfeit solutions addiction provided.

### Structure

The Backbone exercise has three layers:

**Layer 1: Core Needs Identification**
- Prompt: "What are your fundamental needs as a person? What do you need to thrive — not just survive?"
- Pre-populated need categories (user selects and customizes):
  - Connection / Belonging
  - Significance / Purpose
  - Security / Safety
  - Autonomy / Freedom
  - Physical Health
  - Emotional Expression
  - Spiritual Life
  - Recreation / Play
  - Intimacy (healthy)
  - Creative Expression
  - Custom (free-text)
- User selects their top 5-7 core needs and ranks them by importance

**Layer 2: Healthy Activities**
- For each identified core need, the user defines 2-3 healthy activities that meet that need
- Prompt: "For [need], what healthy activities fulfill this need for you?"
- Example: Connection/Belonging → "Weekly recovery group," "Date night with spouse," "Phone call with best friend"
- Free-text input per activity, 200 char max

**Layer 3: Commitments**
- For each healthy activity, the user defines a specific commitment
- Prompt: "What commitment will you make to ensure this activity happens regularly?"
- Structure: What + How Often + When
- Example: "Attend recovery group — weekly — every Tuesday at 7 PM"
- Commitments created here can optionally be synced to the Commitments System for tracking

### Flow

1. User works through Layer 1 (needs identification and ranking)
2. For each need, defines healthy activities (Layer 2)
3. For each activity, defines commitments (Layer 3)
4. Review screen showing complete Backbone: Needs → Activities → Commitments
5. Save to history
6. Backbone accessible anytime as a reference document (like a static tool)
7. Periodic review prompt: "It's been X weeks since you reviewed your Backbone. Would you like to revisit it?"

### Notes

- One-time setup with periodic review (recommended: monthly)
- Saved Backbone displayed as a structured reference document
- Editable at any time — changes saved as a new version with history preserved
- Commitments from Backbone can be pushed to the Commitments System with one tap

---

## Sub-Activity: Bow Tie

### Description

A visual mapping tool that traces the chain from an external event to an internal thought to a feeling to a behavior — revealing the reactive patterns that drive acting out. Named for its shape: event and behavior on the outer edges, thoughts and feelings at the center.

### Structure

```
EVENT → THOUGHT → FEELING → BEHAVIOR
```

**Step 1: Event**
- "What happened? Describe the triggering event or situation."
- Free-text, 500 char max

**Step 2: Thought**
- "What thought did this event trigger? What story did you tell yourself?"
- Free-text, 500 char max
- Common thought patterns offered as examples: "I'm not enough," "Nobody cares," "I deserve this," "It doesn't matter," "I can't handle this"

**Step 3: Feeling**
- "What emotion arose from that thought?"
- Feelings Wheel available
- Intensity slider (1-10)

**Step 4: Behavior**
- "What did you do as a result?"
- Free-text, 500 char max
- Category tag: Healthy response, Acting in, Acting out, Numbing, Isolating, Other

**Step 5: Alternative Pathway (the intervention)**
- "Now rewrite the chain. Same event — but what if you chose a different thought?"
- Alternative thought → Alternative feeling → Alternative behavior
- Purpose: practice cognitive restructuring in a recovery-specific context

### Visual Display

- Completed Bow Tie displayed as a visual diagram:
  - Top path: the reactive chain (event → thought → feeling → behavior)
  - Bottom path: the alternative chain (same event → new thought → new feeling → new behavior)
  - Center: the "bow tie" — the point where thought is the fulcrum
- Color-coded: reactive path in amber/red, alternative path in green/blue

### Flow

1. User works through Steps 1-4 (the reactive chain)
2. User completes Step 5 (the alternative pathway)
3. Visual Bow Tie diagram generated and displayed
4. Review and save to history
5. Optional: share with counselor or sponsor

---

## Sub-Activity: Empathy Mapping

### Description

Create structured empathy maps for specific people affected by the user's addiction. More detailed and formalized than the Empathy Exercises — empathy maps create a comprehensive portrait of another person's experience.

### Structure

For a chosen person (spouse, child, parent, friend, etc.):

**1. Who are you mapping?**
- Name or relationship label
- Context: "What is their relationship to your addiction? How have they been affected?"

**2. What do they SEE?**
- "What does this person see when they look at your behavior, your recovery, your daily life?"
- Free-text, 500 char max

**3. What do they HEAR?**
- "What do they hear you say? What do they hear from others about you or about addiction?"
- Free-text, 500 char max

**4. What do they THINK?**
- "What thoughts might be going through their mind? What beliefs have they formed?"
- Free-text, 500 char max

**5. What do they FEEL?**
- "What emotions are they likely experiencing?"
- Feelings Wheel available as reference
- Free-text elaboration, 500 char max

**6. What do they NEED?**
- "What does this person need from you? What would healing look like for them?"
- Free-text, 500 char max

**7. What are their FEARS?**
- "What are they afraid of? What keeps them up at night because of your addiction?"
- Free-text, 500 char max

### Visual Display

- Completed empathy map displayed as a structured visual card or diagram with all six perspectives arranged around the person's name
- Printable/exportable as PDF

### Flow

1. User selects who to map (or creates a new map)
2. Works through each perspective one at a time with guided prompts
3. Review screen showing complete empathy map
4. Save to history
5. Optional: share with counselor or spouse (with sensitivity — sharing should be discussed with a counselor first)

### Notes

- Multiple empathy maps can be created (one per person)
- Each map is revisitable and editable — changes saved as new version with history preserved
- Recommended: create empathy maps as assigned by counselor, not self-directed (the exercise can be emotionally intense)
- Periodic review prompt: "Would you like to revisit your empathy map for [person]? Your understanding may have deepened since you last reflected."

---

## Sub-Activity: Threats

### Description

Identify, categorize, and build defenses against specific threats to recovery. Threats are anything — internal or external — that could undermine sobriety, relational healing, or spiritual growth.

### Structure

**Step 1: Identify Threats**
- Prompt: "What are the biggest threats to your recovery right now?"
- User lists threats as individual items (free-text, 200 char max each)
- Unlimited items; minimum 5 recommended

**Step 2: Categorize Each Threat**
- For each identified threat, assign a category:
  - Internal — thoughts, beliefs, emotions, character defects
  - Relational — people, relationships, conflicts, isolation
  - Environmental — places, situations, routines, access points
  - Digital — apps, websites, devices, social media
  - Spiritual — disconnection from God, faith doubts, spiritual neglect
  - Physical — exhaustion, hunger, illness, neglected self-care
  - Professional — work stress, travel, workplace dynamics
  - Financial — money stress, spending triggers, financial consequences

**Step 3: Assess Each Threat**
- Likelihood: How likely is this threat to occur? (Low / Medium / High)
- Impact: If it occurs, how much damage could it do? (Low / Medium / High)
- Current defense: What am I currently doing to protect against this? (free-text, 300 char max)
- Defense gap: Is my current defense sufficient? (Yes / Partially / No)

**Step 4: Build Defenses**
- For each threat with a "Partially" or "No" defense gap:
  - "What specific action, boundary, or change would protect you from this threat?"
  - Free-text, 300 char max
  - Each defense can optionally be converted into a commitment or daily/weekly goal

### Visual Display

- Completed threat assessment displayed as a structured table or card view:
  - Each threat shows: description, category icon, likelihood/impact indicators, current defense, planned defense
- Sortable by category, likelihood, or impact
- Color-coded by defense gap: Green (sufficient), Yellow (partial), Red (insufficient)

### Flow

1. User identifies threats (Step 1)
2. Categorizes each threat (Step 2)
3. Assesses each threat (Step 3)
4. Builds defenses for under-protected threats (Step 4)
5. Review screen showing complete threat assessment
6. Save to history
7. Defenses convertible to Commitments or Goals with one tap

### Notes

- One-time setup with periodic review (recommended: monthly or after a relapse/near-miss)
- Saved threat assessment accessible anytime as a reference document
- Editable at any time — changes saved as new version with history preserved
- New threats can be added incrementally without redoing the full exercise
- Linked from Post-Mortem Analysis: "Based on this relapse, are there any new threats you should add to your threat assessment?"

---

## Partner Activity History

- All completed partner exercises accessible in a unified history view
- Browse by sub-activity type (T30/60, Emotional Journaling, Empathy Exercises, Backbone, Bow Tie, Empathy Mapping, Threats)
- Browse by date (reverse chronological)
- Each entry shows: sub-activity icon and label, date completed, brief preview (first line or title)
- Tap any entry to view full completed exercise
- Filter by sub-activity type, date range
- Search content by keyword
- Export individual exercises or full history as PDF for therapy sessions, sponsor meetings, or personal records

---

## Counselor/Coach Assignment Integration

- Counselors and coaches can assign specific Redemptive Living exercises to their clients through the Community permissions system
- Assigned exercises appear in the user's task list with: exercise type, due date (optional), instructions or focus area (optional, free-text from counselor)
- User completes the exercise within the app and marks it as complete
- Completed assignment visible to the assigning counselor/coach in their dashboard
- Assignment status: Assigned → In Progress → Completed
- Overdue assignments generate a gentle reminder (not a penalty)

---

## Integration Points

- Feeds into Tracking System:
  - T30/60 Journaling — consecutive days of completion
  - Emotional Journaling — consecutive days (shared streak with standalone Emotional Journaling activity)
  - Empathy Exercises — completion count (not streak-based; these are periodic, not daily)
  - Backbone — completion and review dates tracked
  - Bow Tie — completion count
  - Empathy Mapping — completion and review dates tracked
  - Threats — completion and review dates tracked
- Feeds into Analytics Dashboard (partner activity engagement, completion rates, assignment compliance)
- Feeds into Weekly/Daily Goals — completing a partner activity auto-checks an emotional or relational dynamic goal if one is set
- Backbone commitments sync to Commitments System
- Threat defenses sync to Commitments System or Weekly/Daily Goals
- Bow Tie entries linked to Urge Logging and FASTER Scale data for pattern cross-referencing
- Empathy Maps linked to Spouse Check-in Preparation (FANOS/FITNAP) — insights from empathy mapping can inform the Triggers and Needs sections
- Visible to support network (counselor, coach, sponsor) based on community permissions
- Counselor assignment integration through Community system

---

## Notifications

- **Assignment notification:** "Your counselor has assigned a new exercise: [exercise type]. Tap to get started."
- **Assignment reminder:** "You have an incomplete assignment: [exercise type]. Due [date]." (sent day before and day of due date)
- **Periodic review reminders:**
  - Backbone: "It's been X weeks since you reviewed your Backbone. Your needs and commitments may have evolved."
  - Threats: "It's been X weeks since you reviewed your threat assessment. Are your defenses still strong?"
  - Empathy Maps: "Would you like to revisit your empathy map for [person]? Recovery deepens your understanding over time."
- **Completion celebration:** "You completed [exercise type]. This is the kind of deep work that changes everything. Well done."
- All partner activity notifications independently togglable in Settings

---

## Tone & Messaging

- Partner activities framed as transformational work — the exercises that turn sobriety into genuine recovery and character change
- Helper text on first use: "These exercises go deeper than daily tracking. They're designed to help you understand yourself, rebuild empathy, and become the person you were created to be. They may be uncomfortable — that's where the growth happens."
- Post-completion messages (rotating):
  - "This is the work that changes who you are — not just what you do. Thank you for going there."
  - "Empathy, honesty, and self-awareness are muscles. You just worked out."
  - "The hardest exercises produce the deepest healing. You didn't take the easy way today."
  - "This kind of work is what separates sobriety from true recovery. You're doing both."
- Exercises that involve confronting harm to others (Empathy Exercises, Empathy Mapping) include compassionate framing: "This exercise may be painful. That pain is a sign that your heart is coming back to life. Be gentle with yourself."
- No shaming for incomplete or skipped exercises — gentle re-engagement only

---

## Edge Cases

- User starts a T30/60 but exits before completing → Progress auto-saved; resumable within 24 hours; after 24 hours, saved as incomplete with whatever was written
- User completes Emotional Journaling through the standalone activity and through Redemptive Living on the same day → Both entries saved; both tagged appropriately; only one day counted toward the shared streak
- User has no counselor to assign exercises → All exercises available for self-directed use; assignment integration simply not activated
- Counselor assigns an exercise the user has already completed recently → User can complete again (repetition is valuable) or mark as "Already completed" with a link to the previous entry
- User creates a Backbone but never converts commitments to the Commitments System → Backbone still functions as a reference document; gentle prompt: "Would you like to turn these commitments into trackable goals?"
- User creates multiple Bow Ties for the same event → Each saved independently; pattern analysis can surface recurring events
- User wants to delete an empathy map → Deletable with confirmation; counselor notified if the map was part of an assignment
- Offline → All exercises fully available offline (no server dependency for content); completed exercises synced when connection restored
