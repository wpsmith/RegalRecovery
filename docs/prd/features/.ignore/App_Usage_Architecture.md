# App Usage Architecture

**Priority:** P0 (Foundational — defines how all features are organized and presented to the user)

**Description:** This document defines how Regal Recovery organizes its 35+ activities, tools, assessments, and features into a coherent daily experience across four layers of engagement: Emergency, Daily, Occasional, and One-Time. The "Today" view is the heart of the app — not a dashboard of widgets, but a personalized daily recovery plan the user executes against.

---

## 1. Architecture Philosophy

### Core Principle

The app is not a menu of 35 activities the user browses and picks from. It is a **personalized daily recovery plan** that the user configures once and then executes against, with the app tracking completion, scoring their day, and surfacing the right thing at the right time.

### Three Primary Uses

1. **Emergency** — In crisis situations, immediately reach contacts, crisis centers, or self-enabling exercises to guide the person through the issue. Always available, context-independent, never competes with daily activities for attention.

2. **Daily Recovery Plan** — Provide daily activities for a user to live in active recovery. The user configures which activities they do daily and when. The "Today" view shows their plan and tracks completion. A daily Recovery Score quantifies their engagement.

3. **Source of Truth** — Be a comprehensive log that determines whether one's recovery activity is vibrant in both qualitative and quantitative measures. Every activity completion, every check-in score, every urge logged, every milestone achieved feeds into the Recovery Health Score and historical analytics.

### Four Layers of Engagement

| Layer | Purpose | Frequency | Where It Lives |
|---|---|---|---|
| **Emergency** | Crisis intervention, immediate help | As needed (hopefully rarely) | Floating Action Button on every screen |
| **Daily** | Structured recovery rhythm | Every day, at configured times | Today view (home screen) |
| **Occasional** | Event-triggered or periodic recovery work | Reactive or scheduled (weekly, monthly, as-needed) | Recovery Work section |
| **One-Time** | Foundational recovery setup | Once, with periodic review | My Recovery Foundation section |

---

## 2. Layer 1: Emergency (Always Available)

### Access

The Emergency layer floats above everything else. It is accessible from **any screen, any time**, regardless of what the user is doing. It is a separate system that never competes with daily activities for attention.

- **Emergency FAB (Floating Action Button):** Persistent bottom-right on every screen (amber/orange, 56x56dp minimum)
  - **Single tap:** Opens Urge Surfing Timer (wave animation with countdown, motivations, companion tools)
  - **Long press:** Opens full Emergency Tools overlay
- **Quick Action Shortcuts:** OS-level access (Siri, Action Button, Android App Shortcuts) without opening the app
- **Voice command:** "I'm struggling" triggers Emergency overlay
- **Lock Screen Widget:** Accessible without unlocking the device

### Emergency Tools Overlay

When activated, the full-screen overlay presents:

**Contact & Broadcast:**
- "Send Help" Accountability Broadcast → sends pre-formatted message to selected support contacts via preferred platform (WhatsApp, Signal, Telegram, SMS, in-app)
- One-tap call buttons: Sponsor, Accountability Partner, Counselor, Custom contact
- Crisis center numbers (988 Suicide & Crisis Lifeline, Crisis Text Line, SAMHSA, custom)

**Self-Intervention:**
- Panic Button with Camera → front-facing camera showing user's own face with motivations overlay, family photo, breathing guide, and biometric-aware personalized intervention
- Urge Surfing Timer → 20-minute wave animation with milestone markers, recovery data overlay, companion tool buttons
- Breathing exercises → Box Breathing, Physiological Sigh, 5-4-3-2-1 Grounding (accessible in <2 seconds)
- Panic Prayer → rotating scripture with audio option
- "View My Plan" → opens Relapse Prevention Plan

**Navigation:**
- GPS to nearest safe zone (if geofencing configured)
- Nearest meeting finder
- Distraction tools (counting exercise, recovery music via Spotify, testimony video)

### Automatic Logging

Every activation of the Emergency layer **automatically logs a potential urge event** with:
- Timestamp
- Which tool was accessed
- Duration of engagement
- Outcome (if user completes the Urge Surfing Timer or taps "I'm okay now")

The user can dismiss the urge log if activation was accidental (within 5 seconds), but the default assumption is that reaching for emergency tools means something was happening. This data feeds into the Recovery Health Score, Analytics Dashboard, and is available for Post-Mortem analysis.

### Technical Requirements

- All emergency tools work **100% offline** — no server dependency
- All actions load in **<1 second**
- Emergency FAB renders above all other UI elements (z-index priority)
- Contact buttons use deep links to phone dialer, SMS, WhatsApp, Signal, Telegram
- Camera, breathing animations, and timer run entirely on-device

---

## 3. Layer 2: Daily Recovery Plan (The Today View)

### Overview

The Today view is the **home screen** of the app — the first thing the user sees when they open it. It replaces the traditional dashboard concept. Instead of showing widgets and stats, it shows: **"Here's what you need to do today, and here's how you're doing."**

### 3.1 Recovery Plan Setup

**Location:** Settings → My Recovery Plan (also accessible during deferred onboarding, Day 3-5)

**Setup Flow:**

1. The app presents all daily-eligible activities in a categorized list
2. For each activity, the user:
   - Toggles ON/OFF for their daily plan
   - Sets the scheduled time(s) — some activities allow multiple daily instances
   - Optionally sets the day(s) of the week (if not every day)
3. The only **default-on** activity is the Morning Commitment — everything else starts OFF and the user opts in
4. The setup screen groups activities by natural time blocks to help the user visualize their recovery rhythm

**Daily-Eligible Activities:**

The following activities can be added to the daily plan:

| Activity | Multiple Per Day? | Default State | Typical Time |
|---|---|---|---|
| Morning Commitment | No (once) | **ON** (only default) | Morning |
| Affirmations | No (once, can browse more) | OFF | Morning |
| Journaling | Yes (unlimited) | OFF | Any |
| Devotional | No (once) | OFF | Morning |
| Prayer | Yes (multiple sessions) | OFF | Morning / Evening |
| Memory Verse Review | No (once per spaced repetition cycle) | OFF | Morning |
| Emotional Journaling | Yes (up to 5) | OFF | Any |
| Mood Rating | Yes (up to 5) | OFF | Any |
| Gratitude List | No (once) | OFF | Evening |
| Phone Calls | Yes (multiple) | OFF | Any |
| Exercise / Physical Activity | No (once) | OFF | Morning / Afternoon |
| Meetings Attended | No (once) | OFF | Evening |
| Person Check-in — Spouse | No (once) | OFF | Evening |
| Person Check-in — Sponsor | No (once) | OFF | Any |
| Person Check-in — Counselor/Coach | No (once) | OFF | Any |
| Spouse Check-in Preparation (FANOS/FITNAP) | No (once) | OFF | Evening |
| Recovery Check-in | No (once) | OFF | Evening |
| FASTER Scale | No (once) | OFF | Evening |
| PCI | No (once) | OFF | Evening |
| Weekly/Daily Goals Review | No (once) | OFF | Evening |
| Nutrition (meal logging) | Yes (up to 5 meals) | OFF | Mealtimes |
| T30/60 Journaling | Yes (if configured as daily) | OFF | Any |
| Acting In Behaviors Check-in | No (once — can be daily or weekly) | OFF | Evening |
| Voice Journal | Yes (unlimited) | OFF | Any |
| Book Reading | No (once) | OFF | Any |

**Setup Examples:**

**Example 1 — Intensive Daily Plan (14 activities):**
```
Morning Block (7:00 AM):
  ✦ Morning Commitment
  ✦ Affirmations
  ✦ Journaling
  ✦ Devotional
  ✦ Prayer

Midday (12:00 PM):
  ✦ Phone Call #1

Afternoon (5:00 PM):
  ✦ Phone Call #2

Exercise (8:00 AM):
  ✦ Exercise

Evening Block (8:00-9:00 PM):
  ✦ Meeting Attendance (8:00 PM)
  ✦ Spouse Check-in (9:00 PM)
  ✦ Gratitude List (9:00 PM)
  ✦ PCI (9:00 PM)

Recurring:
  ✦ T60 Journal Entry (hourly — 7AM, 8AM, 9AM... )
```

**Example 2 — Moderate Daily Plan (13 activities):**
```
Morning Block (7:00 AM):
  ✦ Morning Commitment
  ✦ Affirmations
  ✦ Journaling
  ✦ Devotional
  ✦ Prayer

Exercise (8:00 AM):
  ✦ Exercise

Midday (10:00 AM, 2:00 PM, 5:00 PM):
  ✦ Emotional Journal #1 (10:00 AM)
  ✦ Emotional Journal #2 (2:00 PM)
  ✦ Emotional Journal #3 (5:00 PM)

Calls (12:00 PM, 5:00 PM):
  ✦ Phone Call #1 (12:00 PM)
  ✦ Phone Call #2 (5:00 PM)

Evening Block (8:00-9:00 PM):
  ✦ Meeting Attendance (8:00 PM)
  ✦ Gratitude List (9:00 PM)
  ✦ PCI (9:00 PM)
```

**Example 3 — Light Daily Plan (4 activities):**
```
Morning (9:00 AM):
  ✦ Morning Commitment

Late Morning (10:00 AM):
  ✦ Devotional

Midday (12:00 PM):
  ✦ Meeting Attendance

Evening (10:00 PM):
  ✦ Journaling
```

**Plan Modification:**

- User can modify their plan at any time in Settings → My Recovery Plan
- Changes take effect the following day (today's plan is locked to prevent mid-day gaming of the score)
- Adding a new activity mid-day is allowed as a bonus (counts toward score but doesn't penalize if skipped)
- Therapist can suggest plan additions via the Therapist Portal (user must accept)
- The app may suggest additions based on recovery stage: "You've been in recovery for 30 days. Users at your stage often benefit from adding a FASTER Scale check-in to their evening routine. Would you like to add it?"

### 3.2 The Today View (Home Screen)

**Layout:**

The Today view shows the user's configured daily plan in chronological order by scheduled time, organized into time blocks:

```
┌─────────────────────────────────────────┐
│  Good morning, Alex              Day 47  │
│  Today's Recovery Score: ●●●○○○  52      │
├─────────────────────────────────────────┤
│                                          │
│  ⚠️ RECOVERY WORK DUE                    │
│  ┌──────────────────────────────────┐   │
│  │ Post-Mortem Analysis             │   │
│  │ From yesterday's relapse         │   │
│  │ [Start] [Dismiss]               │   │
│  └──────────────────────────────────┘   │
│                                          │
│  MORNING — 7:00 AM                       │
│  ✅ Morning Commitment      completed    │
│  ✅ Affirmations            completed    │
│  ○  Journaling              pending      │
│  ○  Devotional              pending      │
│  ○  Prayer                  pending      │
│                                          │
│  EXERCISE — 8:00 AM                      │
│  ○  Exercise                upcoming     │
│                                          │
│  MIDDAY — 12:00 PM                       │
│  ○  Phone Call #1           upcoming     │
│                                          │
│  AFTERNOON — 5:00 PM                     │
│  ○  Phone Call #2           upcoming     │
│  ○  Emotional Journal       upcoming     │
│                                          │
│  EVENING — 8:00-9:00 PM                  │
│  ○  Meeting Attendance      upcoming     │
│  ○  Spouse Check-in         upcoming     │
│  ○  Gratitude List          upcoming     │
│  ○  PCI                     upcoming     │
│                                          │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  TODAY'S RECOVERY SCORE                  │
│  ●●●●●○○○○○○○○○  32                     │
│  3 of 14 activities completed            │
│  [View Score Breakdown]                  │
│                                          │
└─────────────────────────────────────────┘
│  [Today] [Progress] [Work] [Resources]   │
│  [Profile]                               │
└─────────────────────────────────────────┘
     [🆘 Emergency FAB — always visible]
```

**Activity States:**

| State | Icon | Appearance | Behavior |
|---|---|---|---|
| **Completed** | ✅ | Green checkmark, muted text | Tap to view completed entry |
| **Pending** | ○ | Normal text, active color | Tap to start the activity |
| **Upcoming** | ○ | Lighter text | Tap to start early (counts toward score) |
| **Overdue** | ⚠️ | Amber highlight, subtle pulse | Past scheduled time; still completable |
| **Skipped** | ✕ | Strikethrough, gray | User explicitly skipped (or day ended without completion) |

**Interaction:**

- Tap any pending/upcoming/overdue activity → opens that activity's flow directly (no intermediate screens)
- Swipe right on an activity → mark as complete (for activities with no input required, like "attended meeting")
- Swipe left on an activity → skip with optional reason ("Not today" / "Didn't have time" / "Not applicable today")
- Long press → view activity details, edit scheduled time, or remove from today only
- Pull down → refresh / show motivational quote
- Activities completed out of order still count — the schedule is a guide, not a constraint

**Recovery Work Cards (Occasional Activities):**

When an occasional activity is triggered or due, it appears as a card **above** the daily plan in the Today view:

- Styled differently (distinct card background, slightly larger) to separate it from the daily routine
- Shows: activity name, trigger reason ("From yesterday's relapse" / "Assigned by your counselor" / "Monthly review due"), and [Start] / [Dismiss] buttons
- Dismissing moves the card to the Recovery Work section; it doesn't disappear entirely
- Multiple recovery work cards stack vertically (max 3 visible; "View all" if more)

**Daily Recovery Score Position:**

The score is visible at the top of the Today view (persistent summary) and in detail at the bottom (full breakdown). As activities are completed throughout the day, the score updates in real-time. The top summary shows a progress bar or dot indicator for quick visual scanning.

### 3.3 Daily Recovery Score

**Calculation:**

The Daily Recovery Score (0-100) is calculated as a weighted percentage of planned activities completed.

**Weighting:**

- **Morning Commitment:** Fixed 20% weight (always present, always 20% of the score regardless of how many other activities are configured)
- **Remaining activities:** 80% divided equally among all other configured activities

**Formula:**

```
Score = (Morning Commitment completed ? 20 : 0) + 
        (Completed other activities / Total other activities) × 80
```

**Examples:**

| Plan | Activities | Completed | Score |
|---|---|---|---|
| Example 1 (14 activities) | Commitment (20%) + 13 others (6.15% each) | All 14 | 100 |
| Example 1 (14 activities) | Commitment + 9 of 13 others | 10 of 14 | 20 + (9/13 × 80) = 75 |
| Example 1 (14 activities) | No commitment + 13 of 13 others | 13 of 14 | 0 + 80 = 80 |
| Example 3 (4 activities) | Commitment (20%) + 3 others (26.7% each) | All 4 | 100 |
| Example 3 (4 activities) | Commitment + 2 of 3 others | 3 of 4 | 20 + (2/3 × 80) = 73 |
| Example 3 (4 activities) | Commitment + 0 of 3 others | 1 of 4 | 20 + 0 = 20 |

**Key design decision:** A user with a lighter plan (4 activities) who completes everything gets the same 100 as a user with a heavy plan (14 activities) who completes everything. The score measures **faithfulness to the plan you set**, not the volume of activities. This prevents shame for users in early recovery or with limited time, while still rewarding consistency.

**Score Display:**

| Range | Label | Color | Meaning |
|---|---|---|---|
| 90-100 | Excellent | Green | Completed almost everything planned |
| 70-89 | Strong | Blue | Solid engagement; minor gaps |
| 50-69 | Moderate | Yellow | Meaningful effort but significant gaps |
| 25-49 | Low | Orange | Limited engagement; consider adjusting plan or reaching out |
| 0-24 | Minimal | Red | Very low engagement today; support network may be notified |

**Score Integration:**

- Daily Recovery Score feeds into the Recovery Health Score (Engagement dimension, 25% weight)
- Score trend visible in Progress tab (7-day, 30-day, 90-day graphs)
- Weekly average visible to support network (with permission)
- Therapist portal shows daily scores and trends
- Consecutive days with score ≥70 tracked as a "recovery rhythm streak"
- Score below 25 for 3+ consecutive days triggers a supportive prompt: "Your recovery engagement has been low. This isn't about judgment — it's about making sure you're okay. Would you like to reach out to someone?"

**What the score does NOT do:**

- It does not compare users against each other
- It does not penalize for having a lighter plan
- It does not penalize for occasional activities or one-time activities not being done (those are separate)
- It does not break sobriety streaks — the Daily Recovery Score and the sobriety streak are independent metrics
- It does not generate shame messaging — low scores produce concern and support, not criticism

### 3.4 Notification Integration

Notifications fire at the scheduled times for daily plan activities. They are not generic reminders — they are **specific action prompts tied to the activity the user configured for that time slot.**

**Batching (per Notification Strategy):**

Activities scheduled at the same time are batched into a single notification:
- "Good morning, Alex. Your morning commitment, affirmations, devotional, and prayer are ready." → Tap opens Today view scrolled to the morning block
- "Evening recovery time. Your meeting attendance, spouse check-in, gratitude list, and PCI are waiting." → Tap opens Today view scrolled to the evening block

**Overdue handling:**

- Activity not completed within 2 hours of scheduled time: subtle amber indicator in Today view (no push notification — the user is aware)
- Activity not completed by end of day: marked as "Missed" in daily history; score reflects the gap; no shame notification the next morning

**Completion acknowledgment:**

- When the last activity of the day is completed: brief celebration — "100% today. Every single one. That's what recovery looks like." (or appropriate message for the score achieved)
- When the morning commitment is completed (regardless of other activities): "Commitment made. Whatever else happens today, you started right."

---

## 4. Layer 3: Occasional Activities (Recovery Work)

### Overview

Occasional activities don't live in the daily plan. They appear when something triggers them, when the user proactively initiates them, or when they're due based on a schedule. They surface as **Recovery Work cards** on the Today view and live in the **Recovery Work** section of the app.

### 4.1 Reactive Activities (Event-Triggered)

These activities are triggered by specific events in the user's recovery:

| Activity | Trigger Event | Urgency |
|---|---|---|
| Post-Mortem Analysis | User logs a relapse | High — card appears on Today view within 24 hours |
| FASTER Scale (ad-hoc) | Urge logged, or self-initiated, or therapist-assigned | Medium — prompted but not forced |
| Content Trigger Log review | Content filter event with concerning response pattern | Low — surfaces in weekly review |
| Urge follow-up | 15 minutes and 1 hour after urge log | High — Tier 1 notification |

**Reactive flow:**
1. Triggering event occurs (e.g., user logs a relapse in the evening review)
2. App schedules the reactive activity (e.g., Post-Mortem Analysis due within 24 hours)
3. Recovery Work card appears on the Today view the next day: "Post-Mortem Analysis — From yesterday's relapse. Taking a few minutes to understand what happened builds stronger defenses. [Start] [Not now]"
4. If dismissed ("Not now"), card moves to Recovery Work section; gentle reminder after 48 hours
5. If still not completed after 72 hours: single notification — "Your Post-Mortem from [date] is still waiting. Completing it while the experience is fresh is most valuable." No further reminders.

### 4.2 Proactive Activities (User-Initiated or Scheduled)

These activities are done on a recurring but non-daily basis, or when the user decides to engage:

| Activity | Typical Frequency | How It Surfaces |
|---|---|---|
| Memory Verse study/quiz | Per spaced repetition schedule (daily-ish but algorithm-driven) | Notification at configured time; card on Today if due |
| Empathy Exercises | 1-2x per month; therapist-assigned | Recovery Work card when assigned |
| T30/60 Journaling (if not daily) | 2-3x per week | Recovery Work card on configured days |
| Bow Tie exercise | As needed; therapist-assigned | Recovery Work card when assigned |
| Backbone review | Monthly | Recovery Work card when due |
| Threats review | Monthly or after relapse | Recovery Work card when due |
| Empathy Mapping | Therapist-assigned; periodic | Recovery Work card when assigned |
| Book reading/logging | User-initiated | Available in Resources; reading streak tracked separately |
| Acting In Behaviors (if weekly, not daily) | Weekly | Recovery Work card on configured day |

### 4.3 Assessment Activities (Clinical Intervals)

Assessments are prompted at specific clinical intervals and surface as Recovery Work:

| Assessment | Schedule | Trigger |
|---|---|---|
| SAST-R | Intake, 90 days, 6 months, 1 year, annually | Recovery Work card when due |
| Denial Assessment | Intake, 30 days, 90 days, 6 months, annually | Recovery Work card when due |
| Addiction Severity Assessment | Intake, 90 days, 6 months, annually | Recovery Work card when due |
| Family Impact Assessment | Monthly (recommended) | Recovery Work card when due |
| Relationship Health Assessment | Monthly (recommended) | Recovery Work card when due |

### 4.4 Therapist-Assigned Work

When a therapist assigns an activity via the Therapist Portal:

1. Assignment notification sent to user (Tier 2 — protected)
2. Recovery Work card appears on Today view: "[Activity name] — Assigned by [Therapist name]. Due [date]. [Start]"
3. Completion status visible to therapist in portal
4. Overdue assignments generate a gentle reminder (not shame): "Your counselor assigned [activity] due [date]. Would you like to start it now?"

### 4.5 Recovery Work Section

**Location:** "Work" tab in bottom navigation

**Content:**
- All pending recovery work (reactive, proactive, assessments, therapist-assigned)
- Organized by: Due Now, This Week, This Month, Overdue
- Each item shows: activity name, trigger/source, due date (if any), priority, status (Not Started / In Progress / Completed)
- Completed items move to a "Completed" archive (browsable for reference)
- Filters: by type (assessment, reactive, assigned, proactive), by status, by date

---

## 5. Layer 4: One-Time Activities (My Recovery Foundation)

### Overview

One-time activities are foundational setup exercises — the user does them once to establish a core element of their recovery, then references and occasionally updates them. They never appear as daily tasks or recovery work unless a periodic review is due.

### Activities

| Activity | Purpose | Review Prompt |
|---|---|---|
| 3 Circles Tool | Map inner/middle/outer circle behaviors | Every 60 days: "Has anything changed in your circles?" |
| Structured Relapse Prevention Plan | Build personalized prevention strategies | Every 30 days + after any relapse |
| Vision Statement | Define recovery vision and values | Every 90 days: "Does your vision still reflect who you're becoming?" |
| Arousal Template | Understand and reshape arousal patterns (therapist-guided) | Therapist-initiated review only |
| Acting In Behaviors (configuration) | Define which acting-in behaviors to track | As needed when new patterns are identified |
| Support Network Setup | Configure sponsor, AP, counselor, spouse connections | As relationships change |
| My Recovery Plan (daily activities) | Configure daily activity plan | As needed; suggested review at 30, 90 days |
| Notification Preferences | Configure notification schedule | After 14 days of use (Smart Defaults Adaptation) |
| Geofence Zones | Mark high-risk and safe locations | As needed; prompted after relapse |

### Where They Live

**Location:** "My Recovery Foundation" section within Profile or Settings

**Presentation:**
- Each item displayed as a card showing: name, brief description, last completed/reviewed date, review status (Up to Date / Review Suggested / Never Completed)
- Tap to view the completed setup (read-only reference)
- "Edit" button to modify
- "Review" button for periodic review (guided through what's changed since last time)

### Review Prompts

When a review is due, a **low-priority notification** (Tier 4) appears:
- "It's been 60 days since you reviewed your 3 Circles. Your understanding of your patterns may have deepened. Would you like to take another look?"
- Tapping opens the existing setup with an "Update" flow
- If dismissed twice, the prompt moves to the Recovery Foundation section only and does not resurface as a notification

---

## 6. Revised Information Architecture

Based on this framework, the app's primary navigation changes:

### Bottom Navigation (5 tabs)

| Tab | Purpose | Content |
|---|---|---|
| **Today** | Daily recovery plan execution | Home screen: daily activities in chronological order, Recovery Work cards, Daily Recovery Score, Emergency FAB |
| **Progress** | Recovery data and trends | Recovery Health Score, sobriety streak, analytics dashboard, achievement gallery, milestone history, activity history, calendar view |
| **Work** | Occasional and assigned recovery activities | Pending recovery work (reactive, proactive, assessments, therapist assignments), completed archive |
| **Resources** | Content and external support | Devotionals, affirmations, prayers, podcasts, books, external links, meeting finder, anonymous stories, memory verse library, Spotify |
| **Profile** | Account and configuration | My Recovery Plan setup, My Recovery Foundation, support network, notification settings, privacy, backup, account management |

### Key Change: Today Replaces Dashboard

The original PRD's Dashboard concept (widgets showing streak, affirmation, quick stats) is replaced by the Today view. The Dashboard's informational elements move to the Progress tab. The user's first experience when opening the app is not "here's a summary of your data" — it's "here's what you need to do right now."

**Exception:** If no daily plan is configured (brand new user), the Today view shows the onboarding-style suggested first actions: "Make your first commitment," "Set up your recovery plan," "Explore your tools."

### Emergency: Not in Navigation

The Emergency layer is never in the tab bar. It's the FAB — always visible, always accessible, independent of navigation state. This ensures it's reachable even when the user is deep in a journaling flow or browsing resources.

---

## 7. Daily Recovery Score vs. Recovery Health Score

Two scores exist in the app. They serve different purposes and should not be confused:

| Dimension | Daily Recovery Score | Recovery Health Score |
|---|---|---|
| **Scope** | Today only | Holistic, ongoing |
| **Measures** | Completion of planned daily activities | Overall recovery health across 5 dimensions |
| **Calculation** | % of today's plan completed (weighted) | Weighted composite of sobriety, engagement, emotional health, connection, growth |
| **Updates** | Real-time throughout the day | Daily (calculated from rolling data) |
| **Range** | 0-100 | 0-100 |
| **Resets** | Every day at midnight | Never resets — continuous trend |
| **Visible to** | User, support network (optional), therapist | User, support network (optional), therapist |
| **Feeds into** | Recovery Health Score (Engagement dimension) | Analytics Dashboard, alerts, therapist portal |
| **Purpose** | "Am I doing my recovery work today?" | "How is my overall recovery going?" |

The Daily Recovery Score is an **input** to the Recovery Health Score. The Recovery Health Score is the **output** that synthesizes everything — sobriety, daily engagement, emotional health, connection, and growth — into a single holistic measure.

---

## 8. Edge Cases

- **User configures zero daily activities (only Morning Commitment):** Daily Recovery Score is binary — 0 or 100. The app gently suggests adding activities after 7 days: "Your morning commitment is a strong foundation. Would you like to add one more activity to deepen your daily recovery?"
- **User has 20+ daily activities configured:** No cap enforced, but a warning during setup: "You've planned 22 activities per day. That's ambitious! Recovery works best when your plan is sustainable. Consider starting with fewer and adding more as you build momentum."
- **User completes activities not in their plan:** Bonus activities are logged and count toward the Recovery Health Score (Growth dimension) but do not affect the Daily Recovery Score. The daily score only measures faithfulness to the plan.
- **User changes time zones mid-day:** Today's plan uses the time zone active when the day started. Time zone changes take effect the following day.
- **User opens the app for the first time at 9 PM:** Today view shows all activities, with morning/afternoon ones marked as "Missed" (no retroactive shame). Evening activities are still completable. The app focuses forward: "There's still time for your evening activities."
- **User is on vacation / intentional break:** "Pause daily plan" option pauses the Daily Recovery Score for up to 14 days. Support network notified. Morning Commitment remains available but not required. Resuming restarts the plan and score without penalty.
- **Weekend vs. weekday differences:** Users can configure different plans for different days of the week in Settings → My Recovery Plan → Day-Specific Plans. The Today view shows the plan for the current day of the week.
- **Therapist adds an activity to the daily plan:** Therapist can suggest (not force) additions. User sees: "[Therapist name] suggests adding FASTER Scale to your evening routine. [Add] [Not now]"
- **User relapses and daily plan feels overwhelming:** After a relapse, the app can offer "Recovery Mode" — a temporarily simplified plan (Morning Commitment + one other activity) for 3-7 days while the user stabilizes. Compassionate framing: "Recovery after a setback doesn't mean doing everything. It means doing one thing: showing up tomorrow."
