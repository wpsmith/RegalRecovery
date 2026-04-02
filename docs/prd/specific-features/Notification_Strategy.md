# Notification Strategy

**Priority:** P0 (Must-Have — foundational to user experience across all features)

**Description:** A unified notification framework that ensures users receive timely, relevant recovery support without experiencing notification fatigue. This strategy governs all push notifications, in-app notifications, and badge counts across every feature in the app.

---

## 1. The Problem

Across all activities and features, Regal Recovery defines approximately 40-50 distinct notification types. A user who enables every default notification could receive 8-12 push notifications per day — morning commitment, affirmation, devotional, mood check, exercise reminder, hydration reminders (multiple), gratitude prompt, evening review, check-in reminder, call reminder, and streak celebrations.

For a population already managing anxiety, shame, and overwhelm, excessive notifications create three risks:

1. **Notification fatigue** — User disables all notifications, losing the accountability structure that makes the app effective
2. **Anxiety amplification** — Constant pings feel like surveillance or pressure rather than support, especially for users in early recovery
3. **OS-level suppression** — Mobile operating systems (iOS Focus modes, Android notification channels) may silently suppress notifications if the app sends too many, making critical notifications (crisis follow-ups, urge check-ins) unreliable

The goal is to make every notification feel like a gift — not a burden.

---

## 2. Core Principles

- **Every notification must earn its place.** If the user wouldn't miss it, don't send it.
- **Recovery-critical notifications are sacred.** Morning commitment, crisis follow-ups, and support network messages are never suppressed by internal caps or batching.
- **The app should feel like a thoughtful friend, not an anxious manager.** A friend checks in once or twice a day. They don't send 12 messages.
- **Silence is a feature.** The absence of a notification is sometimes the most supportive thing the app can do.
- **User control is absolute.** Every notification type is independently togglable. The system applies intelligent defaults, but the user always has final say.

---

## 3. Notification Priority Hierarchy

Every notification in the app is assigned to one of four priority tiers. Priority determines whether a notification can be suppressed, batched, delayed, or skipped when the daily cap is reached.

### Tier 1: Critical (Never Suppressed)

These notifications are essential to user safety and core recovery function. They are never subject to daily caps, batching, or quiet hours suppression. They always generate a push notification with sound/vibration.

| Notification | Trigger | Rationale |
|---|---|---|
| Crisis follow-up | 15 min and 1 hour after urge log | User may be in active danger; timely check-in can prevent relapse |
| Support network message | Incoming message from sponsor, counselor, spouse, AP | Real human reaching out — delay could undermine trust or miss a crisis |
| Accountability broadcast response | Someone responded to user's "Send Help" | User asked for help and someone answered — must be immediate |
| Sustained low mood alert | 3+ consecutive days with average mood ≤ 2.0 | Potential mental health risk; early intervention matters |
| Crisis entry response | User logged a "Crisis" mood rating | Immediate support resources must be surfaced |
| Counselor assignment | Counselor assigns a new exercise or task | Professional instruction — timely delivery respects the therapeutic relationship |

**Tier 1 rules:**
- Always delivered immediately regardless of daily cap, quiet hours, or batch window
- Always produce a push notification (never silently added to in-app queue only)
- Sound and vibration enabled (unless user has device on silent)
- Badge count updated immediately

### Tier 2: Recovery Routine (Protected)

These notifications support the user's daily recovery structure. They are protected from batching and daily cap suppression but respect quiet hours (with exceptions noted).

| Notification | Default Time | Rationale |
|---|---|---|
| Morning commitment reminder | 8:00 AM | Anchors the daily recovery rhythm; most important daily touchpoint |
| Evening review reminder | 9:00 PM | Closes the daily accountability loop |
| Daily affirmation | 12:00 PM | Midday spiritual grounding |
| Devotional reminder | 7:00 AM | Morning spiritual practice |
| Sobriety milestone celebration | Morning after achievement | Positive reinforcement at a key moment |

**Tier 2 rules:**
- Delivered at user-configured times (or defaults above)
- Not subject to daily cap — these are the core recovery cadence
- Respect quiet hours EXCEPT morning commitment (which may be scheduled before quiet hours end — user configures this explicitly)
- Not batched with other notifications — each stands alone because each represents a distinct recovery action
- Snooze option: 15 minutes, max 3 times
- If missed: one follow-up reminder (see missed notification policy below)

### Tier 3: Engagement (Managed)

These notifications encourage deeper engagement with recovery tools but are not essential to the daily routine. They are subject to daily caps, intelligent batching, and quiet hours.

| Notification | Trigger | Default State |
|---|---|---|
| Check-in reminder | User-configured time | ON |
| Exercise reminder | User-configured time | OFF |
| Meal reminder | User-configured times | OFF |
| Hydration reminder | Periodic interval | OFF |
| Gratitude prompt | User-configured time | OFF |
| Prayer reminder | User-configured time | OFF |
| Phone call reminder | User-configured time | OFF |
| Mood check-in prompt | User-configured times | OFF |
| Weekly goal review | Sunday evening | ON |
| Streak milestones (non-sobriety) | Upon achievement | ON |
| Dynamic gap nudge | When a recovery dynamic has no goals | ON |
| Profile completion prompt | Contextual (first 14 days) | ON |
| New content available | When new packs/resources published | ON |

**Tier 3 rules:**
- Subject to daily cap (see Section 4)
- Eligible for intelligent batching (see Section 5)
- Suppressed during quiet hours (see Section 6)
- When daily cap is reached, Tier 3 notifications are queued as in-app notifications only (no push)
- Priority within Tier 3: notifications with user-configured times take precedence over system-generated prompts

### Tier 4: Informational (Best-Effort)

These notifications provide useful but non-urgent information. They are the first to be suppressed when the daily cap is reached and are always candidates for batching.

| Notification | Trigger | Default State |
|---|---|---|
| Missed activity nudge (exercise, gratitude, prayer, etc.) | X days of inactivity per activity | ON (but only triggers once per activity per threshold) |
| Inactivity re-engagement | 3, 7, 14 days of no app usage | ON |
| Weekly summary available | End of week | ON |
| Partner activity review reminder | X weeks since last Backbone/Threats review | ON |
| Sponsor/counselor viewed your data | Support network member accessed shared data | OFF |
| App update available | New version released | ON |
| Community announcement | Admin broadcast | ON |

**Tier 4 rules:**
- First to be suppressed when daily cap is reached
- Always eligible for batching
- Suppressed during quiet hours
- If suppressed by daily cap: queued as in-app notification only; never generates a push the next day to "catch up"
- Maximum one Tier 4 push notification per day (even if cap isn't reached)

---

## 4. Daily Notification Cap

### Hard Cap

- **Maximum push notifications per day: 6** (excluding Tier 1 Critical notifications)
- This cap applies across all Tier 2, 3, and 4 notifications combined
- Tier 1 (Critical) notifications are never counted against the cap

### How the Cap Works

1. Each day at midnight (user's local time), the notification counter resets to 0
2. Each push notification sent increments the counter by 1
3. When the counter reaches 6, no additional Tier 3 or Tier 4 push notifications are sent for the rest of the day
4. Suppressed notifications are delivered as in-app notifications (visible when the user opens the app)
5. Tier 2 (Recovery Routine) notifications are protected — they are sent even if the counter is at 6, but they still increment the counter (so Tier 3/4 may be suppressed earlier on heavy days)

### Cap Priority Order

When the cap is approaching, the system prioritizes in this order:

1. Tier 2 notifications at their scheduled times (always sent)
2. Tier 3 notifications with user-configured times (sent until cap reached)
3. Tier 3 system-generated prompts (sent until cap reached)
4. Tier 4 notifications (first suppressed; max 1/day even without cap pressure)

### User-Adjustable Cap

- Users can adjust their daily cap in Settings → Notifications → Daily Limit
- Options: 4, 6 (default), 8, 10, Unlimited
- "Unlimited" disables the cap entirely — all enabled notifications sent as push
- Helper text: "This controls how many notifications you receive per day. Recovery-critical and safety notifications are always delivered regardless of this setting."

---

## 5. Intelligent Batching

### What Is Batching?

Instead of sending multiple individual notifications within a short window, the system combines related notifications into a single, consolidated push notification. This reduces interruption frequency while preserving the information.

### Batching Rules

**Eligible for batching:** Tier 3 and Tier 4 notifications only
**Never batched:** Tier 1 (Critical) and Tier 2 (Recovery Routine) notifications — these always stand alone

**Batching window:** 30 minutes
- If two or more eligible notifications are scheduled within 30 minutes of each other, they are combined into a single push notification
- The combined notification is sent at the time of the earliest notification in the batch

**Batching groups:** Notifications are only batched with related notifications. The system defines the following batching groups:

| Batch Group | Notifications That Can Combine | Example Batched Notification |
|---|---|---|
| Morning routine | Devotional reminder + Affirmation + Prayer reminder | "Good morning, [Name]. Your devotional, affirmation, and prayer are ready." |
| Activity reminders | Exercise + Meal + Hydration reminders | "Time to take care of your body — log a meal, drink some water, or get moving." |
| Evening routine | Evening review + Check-in + Gratitude prompt | "Time to wrap up your day — your evening review, check-in, and gratitude list are waiting." |
| Streak celebrations | Multiple streak milestones achieved on the same day | "You hit milestones today: 30-day prayer streak and 14-day exercise streak!" |
| Missed activity nudges | Multiple "you haven't done X in Y days" nudges | "It's been a few days since you journaled, exercised, or logged a call. Pick one to do today." |
| Content updates | Multiple new resources or packs available | "New content is available: 2 new devotionals and a prayer pack." |

**Notifications that are never batched together (even if eligible and within the window):**
- Notifications from different batch groups (e.g., a morning devotional and an exercise reminder are not combined even if scheduled at the same time)
- Notifications requiring distinct user actions (e.g., mood check-in and gratitude list — each requires a different flow, so combining them creates confusion)

### Batched Notification Design

- **Title:** Batch group name or a combined summary (e.g., "Morning Recovery Routine")
- **Body:** Brief list of items included (e.g., "Devotional, affirmation, and prayer are ready")
- **Tap action:** Opens a "Today's Plan" screen showing all items in the batch with individual action buttons
- **Expandable (if OS supports):** On Android, expanded notification shows individual items; on iOS, opens directly to the Today's Plan screen

### Batching Settings

- Users can disable batching entirely in Settings → Notifications → Batching
- If disabled: all eligible notifications sent individually (subject to daily cap)
- Users cannot configure individual batch groups — the system handles this automatically
- Helper text: "Batching combines related reminders into a single notification so your phone buzzes less. Your daily cap still applies."

---

## 6. Quiet Hours

### Definition

Quiet hours are a user-defined window during which all non-critical push notifications are silenced. Notifications scheduled during quiet hours are either held until quiet hours end or converted to in-app-only notifications.

### Default Configuration

- **Default quiet hours:** 10:00 PM – 7:00 AM (user's local time)
- **Default state:** ON
- Configurable in Settings → Notifications → Quiet Hours

### Quiet Hours Behavior by Tier

| Tier | During Quiet Hours |
|---|---|
| Tier 1 (Critical) | **Always delivered immediately** — crisis follow-ups, support network messages, and safety alerts override quiet hours entirely |
| Tier 2 (Recovery Routine) | **Held until quiet hours end**, then delivered immediately — EXCEPT morning commitment, which the user can explicitly schedule during quiet hours (e.g., 6:00 AM) via a dedicated toggle: "Allow morning commitment during quiet hours" |
| Tier 3 (Engagement) | **Silenced** — converted to in-app notification only; not delivered as push when quiet hours end (prevents a burst of notifications in the morning) |
| Tier 4 (Informational) | **Silenced** — converted to in-app notification only; never delivered as push after quiet hours end |

### Morning Transition

When quiet hours end, the system delivers held Tier 2 notifications in a controlled sequence:

1. **Wait 5 minutes** after quiet hours end before sending any held notifications (avoids waking the user at exactly 7:00 AM with a burst)
2. **Deliver morning commitment first** (if held — or it may already be scheduled for a specific time)
3. **Wait 10 minutes**, then deliver any other held Tier 2 notifications (devotional, affirmation)
4. **No catch-up for Tier 3/4** — these are simply available as in-app notifications; no morning push burst

### Quiet Hours Exceptions

Users can configure specific exceptions in Settings → Notifications → Quiet Hours → Exceptions:

- **Morning commitment during quiet hours:** Toggle ON/OFF — allows the morning commitment notification to push during quiet hours if the user's commitment time is within the quiet window (e.g., 6:00 AM commitment, quiet hours until 7:00 AM)
- **Support network messages during quiet hours:** Toggle ON (default) / OFF — allows incoming messages from sponsor, counselor, spouse, and accountability partner during quiet hours; some users may want to silence even these overnight
- **Override quiet hours for milestone celebrations:** Toggle ON/OFF (default OFF) — if a sobriety milestone is achieved at midnight, notification waits until morning by default

### Custom Quiet Hours Schedules

- Users can set different quiet hours for different days of the week
  - Example: Weekdays 10:00 PM – 6:00 AM; Weekends 11:00 PM – 8:00 AM
- Accessible via Settings → Notifications → Quiet Hours → Custom Schedule
- If no custom schedule is set, the single default window applies to all days

---

## 7. Missed Notification Policy

When a user misses a recovery-critical notification (doesn't act on it within a reasonable window), the system follows a defined escalation path.

### Morning Commitment Missed

| Time After Scheduled Reminder | Action |
|---|---|
| +2 hours | Second reminder: "Your morning commitment is waiting. A few minutes can set the tone for your whole day." (Tier 2, counts toward cap) |
| +6 hours | Final reminder: "You can still make your commitment for today. It's never too late." (Tier 3, counts toward cap) |
| Next morning | Gentle note on Dashboard: "You missed yesterday's commitment. Today is a fresh start." (In-app only, no push) |

- Maximum 2 follow-up reminders for morning commitment (original + 2 follow-ups = 3 total touches)
- If the user completes the commitment at any point, all pending follow-ups are canceled

### Evening Review Missed

| Time After Scheduled Reminder | Action |
|---|---|
| +1 hour | One follow-up: "Quick evening check — how did today go?" (Tier 3) |
| Next morning | Morning commitment screen shows: "You didn't complete last night's review. Would you like to do it now?" (In-app only) |

- Maximum 1 follow-up reminder for evening review
- Missing the evening review does NOT break the commitment streak (the morning commitment is the streak anchor)

### Urge Log Follow-Up Missed

| Time After Urge Log | Action |
|---|---|
| +15 minutes | "How are you doing? Are you safe?" (Tier 1 — always delivered) |
| +1 hour | "Checking in again. You logged an urge earlier. Did you maintain sobriety?" (Tier 1 — always delivered) |
| +4 hours | No further push notifications — in-app prompt when user next opens the app |

- Urge follow-ups are Tier 1 (Critical) — always delivered, no cap, no quiet hours suppression
- If user responds to either follow-up, the remaining follow-up is canceled

### General Activity Reminders Missed

- If user doesn't act on a Tier 3 activity reminder (exercise, gratitude, etc.): **no follow-up push notification**
- The activity remains accessible from the Dashboard and in-app notification center
- After the user's configured inactivity threshold (default: 3 days for most activities), a single "missed activity nudge" may be sent (Tier 4, subject to cap and batching)
- No escalation beyond the single nudge — the app respects the user's choice not to engage with a particular activity

---

## 8. Notification Channels (OS-Level)

### Android Notification Channels

Android requires apps to define notification channels that users can independently control at the OS level. Regal Recovery defines the following channels:

| Channel ID | Channel Name | Importance | Description |
|---|---|---|---|
| `critical_safety` | Safety & Crisis | High (sound + vibration) | Crisis follow-ups, support network messages, safety alerts |
| `recovery_routine` | Recovery Routine | High (sound) | Morning commitment, evening review, daily affirmation, devotional |
| `milestone_celebration` | Milestones | Default (sound) | Sobriety milestones, streak celebrations |
| `activity_reminders` | Activity Reminders | Default (no sound) | Exercise, meal, hydration, gratitude, prayer, mood, call reminders |
| `engagement` | Check-ins & Goals | Default (no sound) | Check-in reminders, goal reviews, dynamic nudges |
| `community` | Community & Sharing | Default (no sound) | Community messages, content updates, assignments |
| `system` | App Updates & Info | Low (silent) | App updates, system announcements, profile prompts |

### iOS Notification Categories

iOS does not support user-configurable channels in the same way, but the app uses notification categories to define action buttons and grouping:

- **Critical notifications** use the iOS Critical Alerts framework (requires Apple approval) for Tier 1 safety notifications — these bypass Do Not Disturb and silent mode
- **Time-sensitive notifications** (iOS 15+) used for Tier 2 Recovery Routine notifications — these appear prominently even during Focus modes
- **Standard notifications** for Tier 3 and Tier 4
- **Notification grouping** enabled — notifications from the same batch group are visually grouped in Notification Center

---

## 9. In-App Notification Center

When push notifications are suppressed (by daily cap, quiet hours, or user preference), they are stored in the in-app notification center.

### Design

- Accessible via bell icon on Dashboard (top right)
- Badge count shows unread in-app notifications
- Reverse chronological list of all notifications (pushed and suppressed)
- Each notification shows: icon, title, body text, timestamp, action button (e.g., "Make Commitment," "Log Mood")
- Swipe to dismiss individual notifications
- "Mark all as read" button
- Suppressed notifications labeled subtly: "Delivered quietly" (so user understands why they didn't get a push)

### Retention

- In-app notifications retained for 7 days, then auto-cleared
- Milestone celebrations retained for 30 days (users like to revisit these)
- Users can clear all notifications manually at any time

---

## 10. User Settings Interface

All notification settings are accessible via Settings → Notifications.

### Settings Structure

```
Settings → Notifications
├── Daily Limit: [4 / 6 / 8 / 10 / Unlimited]
├── Quiet Hours
│   ├── Enabled: [ON / OFF]
│   ├── Start Time: [10:00 PM]
│   ├── End Time: [7:00 AM]
│   ├── Custom Schedule: [Weekday / Weekend]
│   └── Exceptions
│       ├── Allow morning commitment: [ON / OFF]
│       ├── Allow support messages: [ON / OFF]
│       └── Allow milestone celebrations: [ON / OFF]
├── Batching: [ON / OFF]
├── Recovery Routine
│   ├── Morning Commitment: [ON] — Time: [8:00 AM]
│   ├── Evening Review: [ON] — Time: [9:00 PM]
│   ├── Daily Affirmation: [ON] — Time: [12:00 PM]
│   └── Devotional Reminder: [ON] — Time: [7:00 AM]
├── Activity Reminders
│   ├── Check-in: [ON] — Time: [9:00 PM]
│   ├── Exercise: [OFF] — Time: [—]
│   ├── Meals: [OFF] — Times: [—]
│   ├── Hydration: [OFF] — Interval: [—]
│   ├── Gratitude: [OFF] — Time: [—]
│   ├── Prayer: [OFF] — Time: [—]
│   ├── Phone Call: [OFF] — Time: [—]
│   ├── Mood Check-in: [OFF] — Times: [—]
│   └── Spouse/Sponsor/Counselor Check-in: [OFF]
├── Milestones & Streaks
│   ├── Sobriety milestones: [ON]
│   └── Activity streak milestones: [ON]
├── Community & Content
│   ├── Support network messages: [ON]
│   ├── Counselor assignments: [ON]
│   ├── New content available: [ON]
│   └── Community announcements: [ON]
├── Nudges & Re-engagement
│   ├── Missed activity nudges: [ON]
│   ├── Inactivity threshold: [3 days]
│   └── Re-engagement messages: [ON]
└── Advanced
    ├── Notification sound: [Default / Custom / Silent]
    ├── Vibration: [ON / OFF]
    └── Badge count: [ON / OFF]
```

### Onboarding Default State

During the Fast Track onboarding, if the user grants notification permission, the following defaults are activated:

**ON by default:**
- Morning commitment (8:00 AM)
- Evening review (9:00 PM)
- Daily affirmation (12:00 PM)
- Check-in reminder (9:00 PM — batched with evening review)
- Sobriety milestone celebrations
- Support network messages
- Quiet hours (10:00 PM – 7:00 AM)
- Batching (ON)
- Daily cap (6)

**OFF by default:**
- Devotional reminder (prompted during deferred profile completion when user first engages with devotionals)
- All activity-specific reminders (exercise, meals, hydration, gratitude, prayer, mood, calls)
- Activity streak milestones
- New content notifications
- Community announcements
- Custom quiet hours schedule

This ensures a new user receives approximately **3-4 push notifications per day** on their first day (morning commitment, affirmation, evening review/check-in batch, and possibly a milestone), well within the daily cap and far below the fatigue threshold.

### Smart Defaults Adaptation

After 14 days of usage, the app can suggest notification adjustments based on behavior:

- "You've completed devotionals 12 of the last 14 days without a reminder. Would you like to keep the devotional reminder, or are you good without it?"
- "You've never opened the affirmation notification. Would you like to turn it off or change the time?"
- "You seem to journal most around 7 PM. Want us to send a journaling reminder at that time?"

These suggestions appear as in-app cards (not push notifications) and are fully optional. The user can dismiss them permanently with "Don't suggest notification changes."

---

## 11. Notification Copy Guidelines

### Tone

- Warm, brief, and actionable
- Never guilt-inducing ("You missed your commitment!" ✗) — always inviting ("Your commitment is waiting when you're ready" ✓)
- Use the user's name sparingly — once per day maximum in notifications (overuse feels performative)
- No exclamation marks in recovery-critical contexts — save them for genuine celebrations (milestones)

### Length

- **Title:** 5-8 words maximum (must be readable without expanding the notification)
- **Body:** 1-2 sentences maximum (under 100 characters ideal; never more than 150)
- **Action button text:** 2-3 words (e.g., "Make Commitment," "Log Mood," "View Milestone")

### Examples by Tier

**Tier 1 (Critical):**
- Title: "Checking in"
- Body: "You logged an urge 15 minutes ago. How are you doing?"
- Action: "I'm Okay" / "I Need Help"

**Tier 2 (Recovery Routine):**
- Title: "Good morning, [Name]"
- Body: "Your daily commitment is ready. Start your day with intention."
- Action: "Make Commitment"

**Tier 3 (Engagement) — Individual:**
- Title: "Time to check in"
- Body: "A quick check-in helps you stay aware. How was your day?"
- Action: "Check In"

**Tier 3 (Engagement) — Batched:**
- Title: "Evening recovery routine"
- Body: "Your review, check-in, and gratitude list are waiting."
- Action: "Start Routine"

**Tier 4 (Informational):**
- Title: "It's been a few days"
- Body: "You haven't journaled since Tuesday. Even one sentence counts."
- Action: "Open Journal"

### Localization

- All notification copy must be translated into Spanish with cultural adaptation (not literal translation)
- Spanish notifications should match the emotional register of the Spanish-speaking user personas — warm, familial, faith-resonant
- Example: English "Your daily commitment is ready" → Spanish "Tu compromiso diario te espera" (not "Su compromiso diario está listo")
- Scripture references in notifications use the user's selected Bible translation

---

## 12. Analytics & Monitoring

### Metrics to Track

| Metric | Description | Target |
|---|---|---|
| Daily push count per user | Average number of push notifications sent per user per day | 3-5 (excluding Tier 1) |
| Notification open rate | % of push notifications that result in app open | 35%+ for Tier 2; 20%+ for Tier 3 |
| Notification dismissal rate | % of push notifications swiped away without opening | < 40% for Tier 2; < 60% for Tier 3 |
| Cap hit rate | % of users hitting the daily cap on any given day | < 10% of daily active users |
| Quiet hours override rate | % of users who configure exceptions to quiet hours | Track for insight; no target |
| Batching adoption | % of users with batching enabled | 80%+ (it's ON by default) |
| Notification-driven action rate | % of notifications that result in the prompted action being completed | 50%+ for Tier 2; 25%+ for Tier 3 |
| Notification opt-out rate | % of users who disable all notifications | < 5% (alarm threshold: > 10%) |
| Time from notification to action | Median minutes between push notification and action completion | < 15 min for Tier 2 |

### Alerting

- If notification opt-out rate exceeds 10% for any 7-day window: flag for product review — likely indicates fatigue or poor notification quality
- If Tier 2 open rate drops below 25%: review notification copy and timing
- If daily push count per user exceeds 6 (excluding Tier 1) for more than 5% of users: investigate batching or cap logic failure

### Quarterly Review

- Review notification metrics quarterly
- A/B test notification copy, timing, and batching strategies
- Survey users on notification satisfaction: "Do you feel you receive too many, too few, or the right number of notifications?"
- Adjust defaults based on aggregate data (e.g., if 60% of users disable a specific notification type, consider changing its default to OFF)

---

## 13. Edge Cases

- **User in multiple time zones during a day (travel):** Notification times follow the user's configured home time zone, not current GPS location. Quiet hours follow home time zone. User can manually update time zone in Settings if they relocate.
- **User disables all notifications at the OS level:** App detects this on next launch and displays a gentle banner: "Notifications are disabled for Regal Recovery. Your reminders and support messages won't come through. Enable them in Settings?" with a deep link to OS notification settings. No repeated nagging — banner shown once per session, dismissible, reappears on next launch if still disabled.
- **User enables 15+ activity reminders:** Daily cap (6) naturally suppresses the excess. In-app card suggests: "You have a lot of reminders enabled. We'll send the most important ones as push notifications and keep the rest in your notification center."
- **Two Tier 2 notifications scheduled at the exact same time:** Both sent — Tier 2 notifications are never batched. 30-second delay between them to avoid simultaneous buzzing.
- **User receives a Tier 1 crisis notification during quiet hours at 2 AM:** Delivered immediately with sound and vibration. This is by design — crisis notifications exist precisely for these moments.
- **User hasn't opened the app in 30+ days:** Re-engagement notifications follow the defined cadence (Day 3, 7, 14, 30). After Day 30, no further push notifications sent. If user returns, all notification defaults restored as they were; no "welcome back" notification burst.
- **User's device has low battery or power saving mode:** OS may defer notifications. The app cannot control this but can surface in-app notifications when the user next opens the app, noting any missed notifications: "You may have missed some reminders while your phone was in power saving mode."
- **Notification permission revoked mid-use:** App detects on next launch. Banner prompts re-enabling. All notification logic continues to run server-side so that if permission is re-granted, scheduling resumes without reconfiguration.
- **Multiple batched notifications where user only wants to act on one:** "Today's Plan" screen (opened from batched notification) shows all items with individual action buttons and a "Dismiss" option per item. User is not forced to complete all items in a batch.
