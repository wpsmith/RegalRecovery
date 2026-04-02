# Activity: Mood Ratings

**Priority:** P1

**Description:** Track mood multiple times throughout the day for emotional awareness, recognizing that emotional blindness is one of the most dangerous drivers of relapse.

---

## User Stories

- As a **recovering user**, I want to log my mood quickly throughout the day, so that I build awareness of my emotional state instead of numbing or ignoring it
- As a **recovering user**, I want to see my mood patterns over time, so that I can identify emotional trends that correlate with urges, relapses, or strong recovery days
- As a **recovering user**, I want to add a brief note when I log my mood, so that I can capture what's driving how I feel and reflect on it later
- As a **recovering user**, I want to log my mood in under 10 seconds, so that the barrier to tracking is as low as possible and I actually do it consistently
- As a **recovering user**, I want to see what time of day my mood tends to dip, so that I can plan recovery activities and support around my most vulnerable hours
- As a **recovering user**, I want to understand how my mood connects to my other recovery activities, so that I can see which practices (prayer, exercise, meetings) actually improve how I feel
- As a **recovering user**, I want mood tracking to help me name what I'm feeling, so that I grow my emotional vocabulary instead of collapsing everything into "fine" or "bad"
- As a **sponsor**, I want to see my sponsee's mood trends (with permission), so that I can check in proactively when I notice sustained low moods rather than waiting for a crisis
- As a **counselor**, I want access to my client's mood data between sessions, so that I can identify emotional patterns and bring targeted insights into our work together
- As a **recovering user**, I want mood tracking to feel like self-compassion rather than self-surveillance, so that I approach my emotions with curiosity instead of judgment

---

## Mood Entry

### Rating Scale

Two display modes available (user selects preference in Settings → Mood Ratings → Display Mode):

**Emoji Mode (default):**
- 😄 Great
- 🙂 Good
- 😐 Okay
- 😟 Struggling
- 😰 Crisis

**Numeric Mode:**
- 5 — Great
- 4 — Good
- 3 — Okay
- 2 — Struggling
- 1 — Crisis

Both modes map to the same underlying 1-5 scale for consistent data analysis regardless of display preference.

### Entry Flow

1. **Select mood** — single tap on emoji or number (required)
2. **Context note** (optional) — brief free-text input, 200 char max, voice-to-text available
   - Placeholder prompts (rotating):
     - "What's behind this feeling?"
     - "What just happened?"
     - "One word for right now?"
     - "What do you need?"
3. **Emotion label** (optional) — quick-select from a condensed emotion list for more specificity:
   - Peaceful, Grateful, Hopeful, Confident, Connected
   - Anxious, Lonely, Angry, Ashamed, Overwhelmed
   - Sad, Numb, Restless, Afraid, Frustrated
   - Tap to select one or more; links to Feelings Wheel for deeper exploration if desired
4. **Save** — tap to save; gentle confirmation animation
   - Entry timestamped automatically
   - Total time to complete: under 10 seconds for rating only; under 30 seconds with note and emotion label

### Multiple Entries Per Day

- Unlimited mood entries per day, each independently timestamped
- Each entry stands alone — no requirement to update a previous entry
- All entries for the day visible in a mini-timeline on the Mood Ratings screen

---

## Quick Access Points

Mood logging should be frictionless and available from multiple surfaces:

- **Dashboard widget** — "How are you feeling?" with emoji row; single tap logs and saves
- **Quick Action Shortcut** — OS-level shortcut (Siri, Action Button, Android App Shortcut) opens directly to mood entry
- **Post-activity prompts** — optional mood check after key activities:
  - After morning commitment: "How are you feeling this morning?"
  - After urge log resolution: "How are you feeling now?"
  - After exercise: "How do you feel after your workout?"
  - After prayer/devotional: "How are you feeling after spending time with God?"
  - These prompts are configurable — user enables/disables each in Settings
- **Notification prompt** — scheduled mood check-ins at user-configured times (see Notifications section)

---

## Today's Mood View

- **Mini-timeline:** Horizontal timeline showing all mood entries for today, plotted by time of day
  - Each entry displayed as its emoji (or number) at the corresponding time
  - Tap any entry to expand and see note, emotion labels, and timestamp
- **Today's summary:**
  - Average mood for today (numeric, displayed alongside emoji equivalent)
  - Highest and lowest mood entries
  - Number of entries logged today
- **Quick compare:** "Yesterday at this time you felt: [emoji]" — subtle contextual reference

---

## Mood History

### Daily View

- Browse past days in reverse chronological order
- Each day shows: date, number of entries, average mood (emoji + numeric), high/low, mini-timeline preview
- Tap any day to expand and see all individual entries with notes and emotion labels

### Calendar View

- Monthly calendar with color-coded days based on average daily mood:
  - Green (4.0-5.0) — Great / Good
  - Yellow (3.0-3.9) — Okay
  - Orange (2.0-2.9) — Struggling
  - Red (1.0-1.9) — Crisis
- Days without entries shown as neutral/gray
- Tap any day to view that day's entries
- Swipe between months; "Today" quick-jump button

### Search & Filter

- Search notes by keyword
- Filter by mood rating (e.g., show only "Struggling" and "Crisis" entries)
- Filter by emotion label
- Filter by date range
- Filter by time of day (morning, afternoon, evening, night)

---

## Trends & Insights

### Mood Over Time

- **Daily average line graph** — 7-day, 30-day, 90-day views
  - Smooth line showing average daily mood
  - Individual entries plotted as dots for granularity
  - Trend line overlay showing overall direction (improving, stable, declining)

- **Weekly summary:**
  - Average mood this week vs. last week
  - Best day and most challenging day
  - Most common emotion labels this week
  - Number of entries (engagement consistency)

- **Monthly summary:**
  - Average mood this month
  - Distribution breakdown: X% Great, X% Good, X% Okay, X% Struggling, X% Crisis
  - Comparison to previous month

### Time-of-Day Patterns

- **Heatmap:** Grid showing average mood by hour of day across weeks/months
  - Reveals vulnerable time windows (e.g., "Your mood drops most between 9 PM and midnight")
  - Reveals strong windows (e.g., "Your mood is highest in the morning after your commitment")

- **Day-of-week patterns:**
  - Average mood by day of week
  - "Your most challenging day tends to be Sunday evening"
  - "Saturdays are your strongest mood days"

### Emotion Label Trends

- Most frequent emotion labels over time (bar chart, 30-day view)
- Shift tracking: "Compared to last month, you're feeling 'anxious' less often and 'peaceful' more often"
- Emotion co-occurrence: "When you feel 'lonely,' you also tend to feel 'ashamed'"

### Correlation Insights

- **With recovery activities:**
  - "On days you exercise, your average mood is X points higher"
  - "On days you pray, your average mood is X points higher"
  - "On days you attend meetings, your evening mood averages X points higher than days you don't"
  - "On days you journal, your mood variability is lower (more stable throughout the day)"

- **With urges and sobriety:**
  - "Your average mood in the 24 hours before a logged urge is X"
  - "When your daily average drops below X for 3+ consecutive days, your urge frequency increases by X%"
  - "Your mood has been below 'Okay' for X consecutive days — consider reaching out to your support network"

- **With check-in scores:**
  - "Your mood ratings and check-in scores are strongly correlated — mood is a reliable early indicator for you"

### Alerts

- **Sustained low mood alert:** If average daily mood is ≤2.0 for 3+ consecutive days, prompt:
  - "Your mood has been low for a few days. This can be a sign that something needs attention. Would you like to reach out to someone?"
  - Options: Contact sponsor, Contact counselor, Log an urge, Journal, View coping tools
  - Alert also optionally sent to support network (configurable — user chooses whether low mood alerts are shared)

- **Crisis entry alert:** If user selects "Crisis" (1/😰), immediate prompt:
  - "It sounds like you're really struggling right now. You're not alone."
  - Options: Emergency tools overlay, Call sponsor, Call crisis line, Breathing exercise, Panic prayer
  - Does not auto-notify support network unless user explicitly chooses to broadcast

---

## Dashboard Widget

- Compact card on main Dashboard showing:
  - "How are you feeling?" with emoji row for one-tap logging
  - Today's average mood (if entries exist)
  - Current mood streak (consecutive days with at least one entry)
- Tap widget header to open full Mood Ratings screen
- Emoji tap logs directly from Dashboard — no navigation required

---

## Integration Points

- Feeds into Tracking System (consecutive days with at least one mood entry)
- Feeds into Analytics Dashboard (mood trends, time-of-day patterns, correlation with all recovery metrics)
- Feeds into Weekly/Daily Goals — if user has an emotional dynamic goal related to mood awareness, logging counts toward completion
- Mood before/after data from Exercise, Prayer, and Devotionals activities cross-referenced with standalone mood entries for richer pattern analysis
- Emotion labels contribute to Emotional Journaling insights (shared emotional vocabulary)
- Linked from Urge Logging — mood at time of urge captured and compared to baseline
- Linked from Recovery Check-ins — "How is your emotional state right now?" check-in question compared to mood entry data for consistency
- Visible to support network (sponsor, counselor, coach, spouse) based on community permissions
- Crisis entry triggers emergency tools (see Alerts section)

---

## Notifications

- **Scheduled mood check-ins** (optional) — user configures 1-3 check-in times per day
  - Default: OFF (mood logging works best when self-initiated or prompted by activities)
  - Suggested times if enabled: morning (8:00 AM), afternoon (2:00 PM), evening (8:00 PM)
  - Notification text: "Quick check — how are you feeling right now?" with emoji options in the notification itself (if OS supports interactive notifications)

- **Missed mood nudge:** "You haven't logged your mood in X days. Checking in with yourself takes just a moment." (optional, sent after user-configured inactivity threshold, default: 3 days)

- **Streak milestone:** "X days of mood tracking. You're building real emotional awareness — that's a superpower in recovery."

- **Low mood alert notification** (to support network, if enabled): "Your [sponsee/client/partner] has had a sustained low mood. Consider reaching out."
  - Only sent after 3+ consecutive low days AND only if user has enabled this sharing in Settings

- All mood notifications independently togglable in Settings

---

## Tone & Messaging

- Mood tracking framed as emotional awareness — a recovery skill, not a performance metric
- Helper text on first use: "Most people in addiction have spent years ignoring, numbing, or stuffing their emotions. Mood tracking is how you start paying attention again. There are no wrong answers — just honest ones."
- Post-entry messages (rotating):
  - "Noticed. Named. That's more than most people do. Well done."
  - "Your feelings matter. Every single one of them."
  - "Awareness is the beginning of freedom. You're doing the work."
  - "It's okay to not be okay. What matters is that you're paying attention."
- No judgment on low moods — the app never frames a low mood as failure
- Crisis-level entries met with warmth and immediate support, never alarm or shame

---

## Edge Cases

- User logs only "Great" every day without variation → No intervention; pattern noted in insights as potential emotional avoidance if combined with other indicators (elevated PCI, missed check-ins)
- User logs 20+ entries in a single day → All saved; insights use daily average; no cap imposed
- User selects "Crisis" accidentally → Entry editable for 24 hours; crisis prompt can be dismissed without taking action
- User switches between emoji and numeric display modes → Historical data unaffected; both modes map to the same 1-5 scale
- User wants to delete a mood entry → Deletable within 24 hours; after that, entry is permanent (preserves data integrity for clinical and sponsor use)
- Time zone change during the day → Entries timestamped in UTC; displayed in user's current time zone; daily average calculated based on user's home time zone
- Offline → Full mood logging available offline; entries timestamped at time of creation and synced when connection restored
