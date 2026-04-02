# Activity: Exercise/Physical Activity

**Priority:** P1

**Description:** Log workouts and physical activity to support holistic recovery, recognizing that physical health is a critical component of sustained sobriety.

---

## User Stories

- As a **recovering user**, I want to log my workouts and physical activity, so that I can see how consistently I'm caring for my body as part of my recovery
- As a **recovering user**, I want to choose from common activity types when logging, so that I can quickly record what I did without friction
- As a **recovering user**, I want to sync exercise data from Apple Health or Google Fit, so that workouts I track elsewhere automatically appear in my recovery app
- As a **recovering user**, I want to see my exercise streak over time, so that I'm motivated to maintain the habit even on days I don't feel like it
- As a **recovering user**, I want to understand the connection between my physical activity and my recovery outcomes, so that I can see how exercise impacts my mood, urges, and sobriety
- As a **recovering user**, I want to add notes to my workout log, so that I can capture how I felt before and after exercising
- As a **recovering user**, I want exercise to count toward my physical dynamic goals, so that my workout logs automatically check off related daily or weekly goals
- As a **recovering user**, I want to log low-intensity activities like walking or stretching, so that I don't feel like only intense workouts count toward my recovery
- As a **sponsor**, I want to see whether my sponsee is staying physically active, so that I can encourage them in an area that directly supports sobriety
- As a **recovering user**, I want a simple, judgment-free logging experience, so that exercise feels like a gift to myself rather than another obligation

---

## Activity Logging

### Manual Entry

- **Activity type** (required) — select from predefined list or custom:
  - Walking
  - Running / Jogging
  - Gym / Weight Training
  - Yoga / Stretching
  - Swimming
  - Cycling
  - Sports (basketball, soccer, tennis, etc.)
  - Hiking
  - Dance
  - Martial Arts
  - Group Fitness Class
  - Home Workout
  - Yardwork / Physical Labor
  - Other (free-text label)

- **Duration** (required) — minutes (number input or quick-select: 15, 30, 45, 60, 90)

- **Intensity** (optional) — Light, Moderate, Vigorous
  - Helper text: "Light = easy conversation possible; Moderate = can talk but not sing; Vigorous = can only say a few words"

- **Date and time** (default: now, editable)

- **Notes** (optional) — free-text, 500 char max, voice-to-text available
  - Suggested prompts (shown as placeholder text, rotating):
    - "How did you feel before and after?"
    - "Did this help with stress or urges today?"
    - "What motivated you to move today?"

- **Mood before/after** (optional) — simple emoji or 1-5 scale for each
  - Enables mood-exercise correlation insights over time

### Quick Log

- One-tap logging for saved favorite activities
- User can save up to 5 favorite activities (type + default duration + default intensity)
- Quick log from Dashboard widget, Quick Action Shortcut, or notification prompt
- Tap to log with defaults; long-press to edit before saving

---

## Platform Integrations

### Automatic Sync

- **Apple Health** (iOS) — reads workout data including type, duration, calories, heart rate
- **Google Fit** (Android) — reads activity sessions including type, duration, calories

### Configuration

- Enabled via Settings → Exercise → Connected Apps
- OAuth authentication flow for each platform
- Sync frequency: real-time (when app is opened) or background sync (if permissions granted)
- Duplicate detection: if user manually logs a workout that also appears via sync, prompt to merge or keep both
- User can disable auto-sync at any time; previously synced data remains in history

### Future App Integrations (to explore)

- Strava — running, cycling, swimming
- Peloton — indoor cycling, strength, yoga
- Garmin Connect — multi-sport tracking
- Fitbit — steps, workouts, sleep
- Each integration follows the same OAuth + sync model

---

## Exercise History

- Browse past entries in reverse chronological order
- Each entry shows: activity type icon, type name, duration, intensity, date/time, mood before/after (if logged)
- Tap any entry to view full details including notes
- Filter by activity type, intensity, date range
- Search notes by keyword

---

## Stats & Trends

- **Weekly summary:**
  - Total active minutes this week
  - Number of workout sessions
  - Most common activity type
  - Comparison to previous week

- **Monthly and 90-day views:**
  - Active minutes per week (bar chart)
  - Sessions per week (line graph)
  - Activity type distribution (pie chart)
  - Intensity distribution over time

- **Streaks:**
  - Current consecutive days with at least one logged activity
  - Longest streak ever
  - Progress toward next streak milestone

- **Correlation insights:**
  - "On days you exercise, your urge frequency is X% lower"
  - "Your average check-in score is X points higher on active days"
  - "You haven't exercised in X days — your last 3 relapses followed similar gaps"
  - Mood before/after trends: "Your post-exercise mood averages 1.5 points higher than pre-exercise"

---

## Dashboard Widget

- Compact card on main Dashboard showing:
  - Today's exercise status: logged or not
  - Current exercise streak
  - Weekly active minutes (progress bar toward a user-set weekly goal, if configured)
- Tap to open Exercise screen
- Quick log button directly on widget

---

## Weekly Goal (Optional)

- User can set a weekly exercise target in Settings → Exercise → Weekly Goal:
  - Target active minutes per week (e.g., 150 minutes)
  - Target sessions per week (e.g., 4 sessions)
- Progress bar visible on Dashboard widget and Exercise screen
- Milestone notification when weekly goal is met
- Weekly goal completion feeds into Weekly/Daily Goals dynamic balance (Physical dynamic)

---

## Integration Points

- Feeds into Tracking System (consecutive days of exercise logged)
- Feeds into Analytics Dashboard (activity trends, correlation with recovery metrics)
- Feeds into Weekly/Daily Goals — completing an exercise log auto-checks a physical dynamic goal if one is set
- Linked from Urge Logging action plan — "Start Exercise" button opens quick log
- Linked from Emergency Tools — physical activity listed as a healthy coping action
- Visible to support network (sponsor, counselor, coach) based on community permissions
- Mood before/after data feeds into Mood Ratings trends (if user also uses Mood Ratings activity)

---

## Notifications

- Exercise reminder at user-configured time (optional, default: OFF)
  - Configurable: daily, specific days of the week, or smart reminder ("You usually exercise around this time")
- Missed activity nudge: "You haven't logged any exercise in X days. Even a short walk counts." (optional, sent after user-configured inactivity threshold, default: 3 days)
- Streak milestone: "You've exercised X days in a row! Your body and your recovery are stronger for it."
- Weekly goal achieved: "You hit your weekly exercise goal! That's X active minutes this week."
- All exercise notifications independently togglable in Settings

---

## Tone & Messaging

- All language celebrates movement of any kind — no intensity gatekeeping
- Helper text on first use: "Physical activity is one of the most powerful tools in recovery. It reduces stress, improves mood, and rebuilds your connection with your body. Every minute counts."
- Post-log messages (rotating):
  - "Great work. Moving your body is an act of self-care."
  - "Exercise isn't punishment — it's freedom. You showed up for yourself today."
  - "Your body carried you through today. That's worth celebrating."
- No calorie tracking, weight tracking, or body image language — the focus is on movement as recovery support, not fitness performance

---

## Edge Cases

- User logs multiple workouts in one day → Each logged independently; all count toward daily active minutes
- User syncs a workout from Apple Health that was already manually logged → Duplicate detection prompt: "This looks similar to a workout you already logged. Merge or keep both?"
- User exercises but doesn't log until the next day → Backdating allowed via date/time picker; streak credit given for the original date
- User sets a weekly goal but doesn't exercise at all → No penalty; gentle nudge after inactivity threshold; weekly review highlights the gap without shame
- Activity type not in predefined list → "Other" with free-text label; if user logs the same custom type 3+ times, prompt to save as a favorite
- Offline → Full logging available offline; synced when connection restored; platform sync queued until online
