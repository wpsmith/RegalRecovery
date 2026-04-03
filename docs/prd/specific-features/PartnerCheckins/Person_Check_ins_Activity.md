# Activity: Person Check-ins

**Priority:** P1

**Description:** Track interpersonal check-ins with key support people, separate from app-based Recovery Check-ins. While Recovery Check-ins measure internal self-assessment, Person Check-ins track the relational dimension of recovery — the real conversations that build trust, accountability, and connection.

---

## User Stories

- As a **recovering user**, I want to log check-ins with my spouse, sponsor, and counselor separately, so that I can track how consistently I'm investing in each of these critical relationships
- As a **recovering user**, I want to record how the check-in happened (in-person, phone, video, text), so that I can see what methods I rely on most and whether I'm having enough face-to-face connection
- As a **recovering user**, I want to add notes after a check-in, so that I can capture key takeaways, commitments made, or things I need to follow up on
- As a **recovering user**, I want independent streaks for each check-in type (spouse, sponsor, counselor/coach), so that I can see where I'm consistent and where I'm falling behind
- As a **recovering user**, I want to see my check-in frequency with each person over time, so that I can hold myself accountable to maintaining all my support relationships — not just the easiest ones
- As a **recovering user**, I want Person Check-ins to be distinct from Phone Calls, so that I'm tracking the depth of connection (check-ins) separately from the act of reaching out (calls)
- As a **recovering user**, I want to be prompted when it's been too long since I checked in with a key support person, so that I don't let important relationships go quiet without realizing it
- As a **spouse**, I want to see that my partner is consistently checking in with their sponsor and counselor (with permission), so that I know they're engaging with their recovery support system beyond just me
- As a **sponsor**, I want to see my sponsee's check-in patterns across their whole support team, so that I can encourage balanced engagement and identify if they're relying too heavily on one person
- As a **counselor**, I want to see how often my client is checking in with their sponsor and spouse between sessions, so that I can address relational avoidance patterns in our work together

---

## Check-in Sub-Types

Each sub-type is independently tracked with its own streak, history, and frequency metrics:

### 1. Spouse Check-in
- Check-ins with spouse or committed partner
- Distinct from the Spouse Check-in Preparation activity (FANOS/FITNAP), which is a preparation tool — this logs that an actual conversation happened
- Cross-reference: "You completed a FANOS preparation today. Did you also have the check-in conversation with your spouse?" (optional prompt)

### 2. Sponsor Check-in
- Check-ins with 12-step sponsor
- May include step work discussions, accountability conversations, or general support
- Cross-reference with Phone Calls: if a call to sponsor is logged, prompt to also log a person check-in if the conversation included substantive recovery discussion

### 3. Counselor/Coach Check-in
- Check-ins with therapist, counselor, or recovery coach
- Includes formal sessions and informal between-session contact
- Sub-categories (optional): Scheduled Session, Between-Session Contact
  - Scheduled sessions: regular appointments (therapy, coaching)
  - Between-session contact: unscheduled calls, emails, or messages for support or crisis

---

## Check-in Logging

### Entry Fields

- **Check-in type** (required) — Spouse, Sponsor, or Counselor/Coach

- **Contact name** (optional, auto-populated if previously entered) — free-text, 50 char max
  - Saved per sub-type so user doesn't have to re-enter each time

- **Date and time** (default: now, editable for backdating)

- **Method** (required) — how the check-in happened:
  - In-Person
  - Phone Call
  - Video Call
  - Text / Message
  - App Messaging (via Regal Recovery in-app messaging)

- **Duration** (optional) — minutes (number input or quick-select: 5, 10, 15, 20, 30, 45, 60, 90)

- **Quality rating** (optional) — "How meaningful was this check-in?"
  - Scale: 1-5 (1 = Surface-level, 5 = Deep and honest)
  - Helps the user reflect on whether they're showing up authentically or going through the motions

- **Topics discussed** (optional) — quick-select chips:
  - Sobriety / Recovery progress
  - Step work
  - Triggers / Urges
  - Emotions / Feelings
  - Relationships / Marriage
  - Boundaries
  - Goals / Commitments
  - Accountability
  - Spiritual life
  - General life / Support
  - Crisis / Emergency
  - Other

- **Notes** (optional) — free-text, 1000 char max, voice-to-text available
  - Suggested prompts (rotating placeholder text):
    - "What was the most important thing discussed?"
    - "Is there anything you need to follow up on?"
    - "Were you fully honest in this conversation?"
    - "How did you feel after this check-in?"

- **Follow-up items** (optional) — user can add 1-3 brief action items that came out of the check-in
  - Each item: free-text, 200 char max
  - Follow-up items can optionally be converted into Daily/Weekly Goals

### Quick Log

- One-tap logging from Dashboard widget or notification
- Quick log records: check-in type (user selects), method (defaults to last used), timestamp
- User can expand afterward to add quality rating, topics, notes, and follow-up items

---

## Check-in History

### List View

- Browse past check-ins in reverse chronological order
- Filterable by sub-type (Spouse / Sponsor / Counselor-Coach / All)
- Each entry shows: sub-type icon and label, contact name, method icon, quality rating (if logged), date/time, duration (if logged)
- Tap any entry to view full details including topics, notes, and follow-up items
- Follow-up items display with completion status (if converted to goals)

### Calendar View

- Monthly calendar with color-coded indicators by sub-type:
  - Spouse: one color (e.g., pink/rose)
  - Sponsor: another color (e.g., blue)
  - Counselor/Coach: another color (e.g., green)
- Multiple check-in types on the same day shown as stacked dots
- Tap any day to view that day's check-in entries

### Filter & Search

- Filter by sub-type, method, quality rating, topics discussed, date range
- Search notes by keyword
- Search follow-up items by keyword

---

## Streaks & Frequency

### Independent Streaks (per sub-type)

Each sub-type has its own streak tracked independently:

- **Spouse check-in streak** — consecutive days (or weeks, configurable) with at least one spouse check-in
- **Sponsor check-in streak** — consecutive days (or weeks) with at least one sponsor check-in
- **Counselor/Coach check-in streak** — consecutive weeks with at least one counselor/coach check-in (default: weekly, since sessions are typically weekly)

Streak frequency is configurable per sub-type in Settings → Person Check-ins:
- Daily: streak requires at least one check-in per day
- X times per week: streak requires X check-ins per rolling 7-day window
- Weekly: streak requires at least one check-in per calendar week

### Frequency Dashboard

- **Per sub-type:**
  - Current streak
  - Longest streak
  - Check-ins this week / this month
  - Average check-ins per week (30-day rolling)

- **Combined view:**
  - All three sub-type streaks displayed side by side
  - Total check-ins across all types this week / month
  - Balance indicator: visual comparison of frequency across sub-types

---

## Trends & Insights

### Check-in Patterns

- **Frequency over time** — line graph per sub-type (7-day, 30-day, 90-day views)
- **Method distribution** — pie chart showing in-person vs. phone vs. video vs. text breakdown per sub-type
  - Insight: "80% of your sponsor check-ins are via text. Consider scheduling a phone call or in-person meeting for deeper connection."
- **Quality trends** — average quality rating over time per sub-type
  - Insight: "Your spouse check-in quality has improved from 2.8 to 4.1 over the last month. The honesty is paying off."

### Topic Trends

- Most discussed topics across all check-ins (bar chart, 30-day view)
- Topic distribution per sub-type: "With your sponsor you mostly discuss step work and accountability; with your counselor you mostly discuss emotions and triggers"
- Topic shifts: "Compared to last month, you're discussing 'boundaries' more frequently"

### Balance Analysis

- Comparison across sub-types: which relationships are getting the most and least attention
- Gap detection: "You've checked in with your sponsor 8 times this month but your counselor only twice (outside of scheduled sessions)"
- Recommendation: "Consider increasing between-session contact with your counselor during this phase of recovery"

### Correlation Insights

- "On weeks with 3+ person check-ins, your average check-in score is X points higher"
- "Your urge frequency is X% lower in weeks where you check in with all three support types"
- "Your spouse check-in quality correlates strongly with your overall mood rating"
- "When you go 7+ days without a sponsor check-in, your FASTER Scale tends to reach A (Anxiety) or higher"

### Inactivity Alerts

Per sub-type, if no check-in logged for a configurable number of days (defaults below):
- **Spouse:** 3 days → "It's been a few days since you checked in with [spouse name]. How are things between you?"
- **Sponsor:** 5 days → "You haven't connected with your sponsor in X days. Recovery works best when you stay connected."
- **Counselor/Coach:** 10 days (between sessions) → "Consider reaching out to your counselor between sessions. You don't have to wait for your next appointment."
- Each alert includes: quick-log button, call/text shortcut (if saved contact), dismiss option
- Alerts optionally shared with the relevant support person (configurable per sub-type)

---

## Relationship to Other Activities

### vs. Phone Calls
- **Phone Calls** tracks the act of calling — frequency, direction, connection rate, effort
- **Person Check-ins** tracks the substance of the conversation — depth, topics, quality, follow-up
- A single conversation can generate both a Phone Call log and a Person Check-in log
- Cross-reference prompt after logging a phone call with a support person: "Would you also like to log this as a person check-in?"

### vs. Recovery Check-ins
- **Recovery Check-ins** are self-assessment questionnaires the user completes within the app
- **Person Check-ins** are real conversations with real people logged after they happen
- Both are valuable; they measure different dimensions of recovery health (internal awareness vs. relational engagement)

### vs. Spouse Check-in Preparation (FANOS/FITNAP)
- **Spouse Check-in Preparation** is a tool for organizing thoughts before a conversation
- **Person Check-ins (Spouse)** logs that the actual conversation happened and captures its substance
- Ideal flow: Prepare (FANOS/FITNAP) → Have the conversation → Log the Person Check-in

---

## Dashboard Widget

- Compact card on main Dashboard showing:
  - Check-in status for each sub-type today/this week: ✓ or pending
  - Current streak per sub-type (compact display)
  - Quick log button: "Log a Check-in"
- Tap widget header to open full Person Check-ins screen

---

## Integration Points

- Feeds into Tracking System (per sub-type, consecutive days/weeks based on configured frequency)
- Feeds into Analytics Dashboard (check-in frequency, quality trends, method distribution, topic trends, correlation with recovery outcomes)
- Feeds into Weekly/Daily Goals — logging a person check-in auto-checks a relational dynamic goal if one is set
- Feeds into Commitments tracking — if user has check-in commitments (e.g., "check in with sponsor daily"), person check-in logs count toward fulfillment
- Linked from Phone Calls — cross-reference prompt after call logging
- Linked from Spouse Check-in Preparation — prompt to log person check-in after completing FANOS/FITNAP preparation
- Follow-up items convertible to Daily/Weekly Goals
- Visible to support network based on community permissions (each sub-type visible to the relevant role: spouse check-in data to spouse, sponsor check-in data to sponsor, etc.)

---

## Notifications

- **Check-in reminders** (optional, per sub-type) — user-configured time and frequency
  - Spouse: "Have you checked in with [spouse name] today?" (default: daily, OFF)
  - Sponsor: "Time to connect with your sponsor this week." (default: weekly, OFF)
  - Counselor/Coach: "Consider reaching out to your counselor before your next session." (default: OFF)

- **Inactivity alerts** — sent when no check-in logged for X days per sub-type (see Inactivity Alerts section)

- **Streak milestones:**
  - "X consecutive [days/weeks] of checking in with your [spouse/sponsor/counselor]. Relationships are the backbone of recovery."

- **Follow-up reminders:** If follow-up items were logged, optional reminder the next day: "You noted a follow-up from yesterday's check-in: '[item text]'. Have you taken care of it?"

- All person check-in notifications independently togglable per sub-type in Settings

---

## Tone & Messaging

- Person check-ins framed as relational investment — the lifeblood of recovery
- Helper text on first use: "Recovery doesn't happen alone. The people around you — your spouse, your sponsor, your counselor — are part of your healing. Tracking your check-ins helps you stay intentional about the relationships that hold you up."
- Post-log messages (rotating):
  - "Showing up for that conversation took courage. That's recovery in action."
  - "The people in your corner need to hear from you. And you need to hear from them."
  - "Every honest conversation builds something that addiction tried to destroy: trust."
  - "You didn't do today alone. That's worth celebrating."
- Quality rating framed as self-reflection, not self-criticism: "This isn't about grading the conversation. It's about noticing whether you're bringing your real self."
- Low quality ratings met with encouragement: "Surface-level check-ins are still check-ins. Depth comes with practice and safety."

---

## Edge Cases

- User logs multiple check-ins with the same person in one day → Each logged independently; all count as one day for streak purposes
- User has a check-in that covers multiple sub-types (e.g., a group meeting with sponsor and counselor present) → User can log as one check-in and tag the primary sub-type, or log separate check-ins for each
- User doesn't have a sponsor or counselor yet → Sub-types without a configured contact are hidden from the dashboard widget and not included in balance analysis; prompted to add contacts when they're ready
- User switches sponsors or counselors → Historical check-in data preserved under the original contact name; new contact name used going forward; streak continues (streak tracks the relationship type, not the specific individual)
- User logs a text exchange as a check-in → Valid; method recorded as "Text / Message"; quality rating and notes capture the substance
- User completes Spouse Check-in Preparation (FANOS/FITNAP) but doesn't have the actual conversation → Preparation logged in its own activity; no person check-in logged; gentle prompt the next day: "You prepared a spouse check-in yesterday. Were you able to have the conversation?"
- User backdates a check-in → Allowed; streak recalculated to include the original date
- Offline → Full logging available offline; synced when connection restored
