# Exercise / Physical Activity -- Acceptance Criteria

**Source:** `docs/prd/specific-features/Exercise/Exercise_Physical_Activity.md`
**Priority:** P1 (Wave 2)
**Feature Flag:** `activity.exercise`

---

## Functional Requirements

### FR-EX-1: Manual Exercise Logging

**FR-EX-1.1** Activity type selection
- **Given** the user opens the exercise log form, **When** they tap the activity type field, **Then** a list of predefined activity types is displayed: Walking, Running/Jogging, Gym/Weight Training, Yoga/Stretching, Swimming, Cycling, Sports, Hiking, Dance, Martial Arts, Group Fitness Class, Home Workout, Yardwork/Physical Labor, Other.
- **Given** the user selects "Other," **When** they confirm the selection, **Then** a free-text label field (max 50 chars) is shown.

**FR-EX-1.2** Duration input
- **Given** the user is logging an exercise, **When** they reach the duration field, **Then** they can enter minutes manually or tap a quick-select button (15, 30, 45, 60, 90).
- **Given** a duration value, **When** it is less than 1 minute, **Then** the form rejects the input with a validation error.

**FR-EX-1.3** Intensity selection
- **Given** the user is logging an exercise, **When** they optionally select intensity, **Then** the options are Light, Moderate, or Vigorous with helper text: "Light = easy conversation possible; Moderate = can talk but not sing; Vigorous = can only say a few words."

**FR-EX-1.4** Date and time
- **Given** the user opens the exercise log form, **When** it loads, **Then** the date/time field defaults to the current date and time.
- **Given** the user edits the date/time, **When** they select a past date, **Then** the log is created with that date and streak credit is given for the original date.
- **Given** the user edits the date/time, **When** they select a future date beyond 24 hours, **Then** the form rejects the input.

**FR-EX-1.5** Notes
- **Given** the user is logging an exercise, **When** they tap the notes field, **Then** a free-text area is shown with a 500-character limit and voice-to-text availability.
- **Given** the notes field is empty, **When** the field receives focus, **Then** a rotating placeholder prompt is displayed (e.g., "How did you feel before and after?").

**FR-EX-1.6** Mood before/after
- **Given** the user is logging an exercise, **When** they optionally rate mood before and after, **Then** each mood is captured on a 1-5 integer scale.

**FR-EX-1.7** Immutable timestamps
- **Given** an exercise log has been created, **When** any update is attempted, **Then** the `createdAt` and `timestamp` fields cannot be modified (FR2.7).

### FR-EX-2: Quick Log

**FR-EX-2.1** Favorite activities
- **Given** a user has saved favorite activities, **When** they use quick log, **Then** they can tap a favorite to create a log with default type, duration, and intensity.
- **Given** a user attempts to save more than 5 favorites, **When** they tap "Save as Favorite," **Then** they are prompted to replace an existing favorite.

**FR-EX-2.2** Quick log access
- **Given** the user is on the Dashboard, **When** they tap the quick log button on the exercise widget, **Then** the quick log interface appears.
- **Given** the user long-presses a favorite in quick log, **When** the hold is detected, **Then** the edit form opens pre-populated with the favorite's defaults.

**FR-EX-2.3** Custom type promotion
- **Given** the user logs the same custom activity type 3 or more times, **When** the third log is saved, **Then** the user is prompted to save it as a favorite.

### FR-EX-3: Exercise History

**FR-EX-3.1** History listing
- **Given** the user opens exercise history, **When** the screen loads, **Then** past entries are shown in reverse chronological order with activity type icon, type name, duration, intensity, date/time, and mood before/after (if logged).

**FR-EX-3.2** Detail view
- **Given** the user taps a history entry, **When** the detail view opens, **Then** all fields including notes are displayed.

**FR-EX-3.3** Filtering
- **Given** the user is on the history screen, **When** they apply filters, **Then** entries can be filtered by activity type, intensity, and date range.

**FR-EX-3.4** Note search
- **Given** the user is on the history screen, **When** they enter a search term, **Then** entries whose notes contain the keyword are returned.

### FR-EX-4: Stats and Trends

**FR-EX-4.1** Weekly summary
- **Given** the user views the exercise stats screen, **When** weekly summary loads, **Then** it displays: total active minutes this week, number of sessions, most common activity type, and comparison to previous week.

**FR-EX-4.2** Monthly and 90-day views
- **Given** the user views monthly/90-day stats, **When** data loads, **Then** it shows: active minutes per week (bar chart data), sessions per week, activity type distribution, and intensity distribution over time.

**FR-EX-4.3** Exercise streak
- **Given** the user has logged exercise on consecutive days, **When** the streak is calculated, **Then** current consecutive days, longest streak ever, and progress toward next milestone are returned.
- **Given** the user did not log exercise today, **When** the streak is checked, **Then** the current streak does not include today (only completed days count).

**FR-EX-4.4** Correlation insights
- **Given** the user has at least 14 days of exercise and recovery data, **When** correlation insights are requested, **Then** the system returns insights such as: urge frequency difference on active vs. inactive days, average check-in score difference, and post-exercise mood improvement average.

### FR-EX-5: Dashboard Widget

**FR-EX-5.1** Widget display
- **Given** the user has the exercise feature enabled, **When** the dashboard loads, **Then** a compact card shows: today's exercise status (logged/not), current exercise streak, and weekly active minutes progress bar (if weekly goal set).

**FR-EX-5.2** Widget interaction
- **Given** the user taps the exercise widget, **When** the tap is detected, **Then** the exercise screen opens.
- **Given** the user taps the quick log button on the widget, **When** the tap is detected, **Then** the quick log interface opens.

### FR-EX-6: Weekly Goal

**FR-EX-6.1** Goal configuration
- **Given** the user navigates to Settings > Exercise > Weekly Goal, **When** they set a target, **Then** they can configure target active minutes per week and/or target sessions per week.

**FR-EX-6.2** Goal progress
- **Given** a weekly goal is set, **When** the user logs exercise, **Then** progress is updated in real time on the dashboard widget and exercise screen.

**FR-EX-6.3** Goal completion notification
- **Given** the user's weekly exercise total meets or exceeds their goal, **When** the threshold is crossed, **Then** a milestone notification is sent: "You hit your weekly exercise goal!"

**FR-EX-6.4** Goal-to-dynamic integration
- **Given** the user logs exercise and has a physical dynamic goal set, **When** the exercise is saved, **Then** the related physical dynamic goal is auto-checked.

### FR-EX-7: Notifications

**FR-EX-7.1** Exercise reminder
- **Given** the user enables exercise reminders in settings, **When** the configured time arrives, **Then** a push notification is delivered.
- **Given** the user configures smart reminders, **When** the system detects a usual exercise time pattern, **Then** a reminder is sent at the predicted time.

**FR-EX-7.2** Inactivity nudge
- **Given** the user has not logged exercise for the configured inactivity threshold (default: 3 days), **When** the threshold is exceeded, **Then** a gentle nudge is sent: "You haven't logged any exercise in X days. Even a short walk counts."

**FR-EX-7.3** Streak milestone
- **Given** the user reaches a new exercise streak milestone, **When** the milestone is detected, **Then** a notification is sent: "You've exercised X days in a row!"

**FR-EX-7.4** Independent toggles
- **Given** the user is in notification settings, **When** they configure exercise notifications, **Then** each type (reminder, nudge, streak, goal) can be toggled independently.

### FR-EX-8: Platform Integrations

**FR-EX-8.1** Apple Health sync (iOS)
- **Given** the user enables Apple Health integration, **When** the app is opened or a background sync occurs, **Then** workout data (type, duration, calories, heart rate) is read from Apple Health and merged into the exercise history.

**FR-EX-8.2** Google Fit sync (Android)
- **Given** the user enables Google Fit integration, **When** the app is opened or a background sync occurs, **Then** activity session data (type, duration, calories) is read from Google Fit and merged into the exercise history.

**FR-EX-8.3** Duplicate detection
- **Given** a synced workout matches a manually logged workout within a 30-minute window and same activity type, **When** the duplicate is detected, **Then** the user is prompted: "This looks similar to a workout you already logged. Merge or keep both?"

**FR-EX-8.4** Sync disable
- **Given** the user disables auto-sync, **When** the setting is saved, **Then** no new data is synced, but previously synced data remains in history.

---

## Non-Functional Requirements

### NFR-EX-1: Offline Support
- **Given** the user is offline, **When** they log exercise, **Then** the log is stored locally and synced when connectivity is restored.

### NFR-EX-2: Performance
- **Given** the user has 1 year of exercise data, **When** they load the history screen, **Then** the initial page loads within 500ms.

### NFR-EX-3: Privacy
- **Given** the user has community permissions configured, **When** a sponsor/counselor/coach views the user's data, **Then** exercise data visibility follows the standard permission model (opt-in only).
- **Given** no calorie tracking, weight tracking, or body image language is present, **When** the exercise feature is used, **Then** the focus remains on movement as recovery support.

### NFR-EX-4: Feature Flag
- **Given** the feature flag `activity.exercise` is disabled, **When** the user accesses the app, **Then** all exercise endpoints return 404 and mobile UI hides exercise features.
- **Given** the feature flag `activity.exercise` is enabled, **When** the user accesses the app, **Then** exercise features are available per the flag's rollout/tier/platform configuration.

### NFR-EX-5: Data Integrity
- **Given** multiple workouts are logged in one day, **When** they are stored, **Then** each is logged independently and all count toward daily active minutes.
- **Given** a workout is backdated to a previous day, **When** it is saved, **Then** streak credit is given for the original date.

---

## Edge Cases

### EC-EX-1: Multiple workouts per day
- **Given** the user logs 3 workouts in one day, **When** daily stats are calculated, **Then** all 3 count independently and total active minutes sums all durations.

### EC-EX-2: Duplicate sync detection
- **Given** the user manually logs a 30-minute run at 7:00 AM and Apple Health syncs a 30-minute run at 7:05 AM, **When** the sync processes, **Then** a duplicate detection prompt is shown.

### EC-EX-3: Backdated exercise
- **Given** the user exercised yesterday but logs it today, **When** they select yesterday's date, **Then** the entry is credited to yesterday for streak and stats purposes.

### EC-EX-4: Weekly goal not met
- **Given** the user has a weekly goal set but does not exercise, **When** the week ends, **Then** no penalty is applied; a gentle nudge is sent if inactivity threshold is configured.

### EC-EX-5: Custom type promotion
- **Given** the user logs "Pickleball" under Other 3 times, **When** the third entry is saved, **Then** the user is prompted: "You log Pickleball often. Save it as a favorite?"

### EC-EX-6: Offline then sync
- **Given** the user logs exercise while offline, **When** connectivity is restored, **Then** the exercise is synced and platform sync is queued until online.
