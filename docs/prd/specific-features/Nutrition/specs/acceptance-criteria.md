# Nutrition Activity -- Acceptance Criteria

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft
**Priority:** P2 (Wave 2)
**Feature Flag:** `activity.nutrition`

---

## Meal Logging

### FR-NUT-1: Create Meal Log

**FR-NUT-1.1** -- Meal type is required
> **Given** a user submits a meal log, **When** `mealType` is omitted, **Then** the API returns `422 Unprocessable Entity` with error code `rr:0x00040001`.

**FR-NUT-1.2** -- Meal type accepts standard and custom values
> **Given** a user submits a meal log, **When** `mealType` is one of `breakfast`, `lunch`, `dinner`, `snack`, or `other`, **Then** the entry is accepted. **When** `mealType` is `other`, **Then** `customMealLabel` is required (max 50 chars).

**FR-NUT-1.3** -- Description is required
> **Given** a user submits a meal log, **When** `description` is omitted or empty, **Then** the API returns `422 Unprocessable Entity`.

**FR-NUT-1.4** -- Description length limit
> **Given** a user submits a meal log, **When** `description` exceeds 300 characters, **Then** the API returns `422 Unprocessable Entity`.

**FR-NUT-1.5** -- Timestamp defaults to now
> **Given** a user submits a meal log without a `timestamp`, **Then** the server sets `timestamp` to the current UTC time.

**FR-NUT-1.6** -- Timestamp is editable for backdating
> **Given** a user submits a meal log with a past `timestamp`, **Then** the entry is accepted with the provided timestamp.

**FR-NUT-1.7** -- Eating context accepts valid values
> **Given** a user submits a meal log, **When** `eatingContext` is provided, **Then** it must be one of: `homemade`, `takeout`, `on-the-go`, `meal-prepped`, `skipped`, `social`, `alone`.

**FR-NUT-1.8** -- Mood before eating is optional (1-5 scale)
> **Given** a user submits a meal log, **When** `moodBefore` is provided, **Then** it must be an integer between 1 and 5 inclusive.

**FR-NUT-1.9** -- Mood after eating is optional (1-5 scale)
> **Given** a user submits a meal log, **When** `moodAfter` is provided, **Then** it must be an integer between 1 and 5 inclusive.

**FR-NUT-1.10** -- Mindfulness check is optional
> **Given** a user submits a meal log, **When** `mindfulnessCheck` is provided, **Then** it must be one of: `yes`, `somewhat`, `no`.

**FR-NUT-1.11** -- Notes are optional (500 char max)
> **Given** a user submits a meal log, **When** `notes` exceeds 500 characters, **Then** the API returns `422 Unprocessable Entity`.

**FR-NUT-1.12** -- Multiple meals of same type allowed
> **Given** a user has already logged a `lunch` today, **When** they log another `lunch`, **Then** both entries are saved independently with no validation error.

**FR-NUT-1.13** -- Minimal valid entry
> **Given** a user submits a meal log with only `mealType` and `description`, **Then** the entry is accepted and all optional fields are null.

**FR-NUT-1.14** -- Immutable timestamp on creation (FR2.7)
> **Given** a meal log entry exists, **When** the user attempts to update its `timestamp`, **Then** the update fails with error `rr:0x00040002` ("timestamp is immutable").

**FR-NUT-1.15** -- Calendar activity dual-write
> **Given** a meal log is created, **Then** a corresponding `CALENDAR_ACTIVITY` entry with `activityType=NUTRITION` is written for the same date.

### FR-NUT-2: Quick Log

**FR-NUT-2.1** -- Quick log requires only meal type
> **Given** a user creates a quick log, **When** only `mealType` is provided, **Then** the entry is accepted with `isQuickLog=true`, `description` null, and `timestamp` set to now.

**FR-NUT-2.2** -- Quick log expandable
> **Given** a quick log entry exists, **When** the user updates it with `description`, mood, context, and notes, **Then** all fields are saved and `isQuickLog` remains `true`.

---

## Hydration Tracking

### FR-NUT-3: Log Water Intake

**FR-NUT-3.1** -- Increment water intake
> **Given** a user taps the "+" water button, **Then** one serving is added to today's hydration total.

**FR-NUT-3.2** -- Decrement water intake
> **Given** a user taps the "-" water button, **When** current count is greater than 0, **Then** one serving is removed. **When** current count is 0, **Then** count remains 0.

**FR-NUT-3.3** -- Configurable serving size
> **Given** a user's hydration settings have `servingSizeOz` set to 16, **When** they log one serving, **Then** 16 oz is added to their daily intake.

**FR-NUT-3.4** -- Default serving size
> **Given** a user has not configured a serving size, **Then** the default serving size is 8 oz.

**FR-NUT-3.5** -- Daily target configurable
> **Given** a user sets their daily hydration target to 10 glasses, **When** they view hydration progress, **Then** progress is calculated against a target of 10 servings.

**FR-NUT-3.6** -- Default daily target
> **Given** a user has not configured a daily target, **Then** the default is 8 servings (64 oz).

**FR-NUT-3.7** -- Serving size change preserves history
> **Given** a user changes their serving size from 8 oz to 16 oz mid-week, **Then** historical data retains the original serving size values and the daily total is recalculated in ounces for consistency.

**FR-NUT-3.8** -- Hydration date boundary
> **Given** a user logs water at 11:59 PM in their timezone, **Then** it counts toward today's total. **When** they log at 12:01 AM, **Then** it counts toward tomorrow.

---

## Meal History

### FR-NUT-4: List and Filter Meals

**FR-NUT-4.1** -- Reverse chronological default
> **Given** a user requests meal history, **Then** entries are returned sorted by timestamp descending (newest first).

**FR-NUT-4.2** -- Filter by meal type
> **Given** a user filters by `mealType=breakfast`, **Then** only breakfast entries are returned.

**FR-NUT-4.3** -- Filter by eating context
> **Given** a user filters by `eatingContext=homemade`, **Then** only home-cooked meal entries are returned.

**FR-NUT-4.4** -- Filter by mood rating
> **Given** a user filters by `moodBefore=1,2`, **Then** only entries where moodBefore is 1 or 2 are returned.

**FR-NUT-4.5** -- Filter by mindfulness check
> **Given** a user filters by `mindfulnessCheck=no`, **Then** only entries with mindfulnessCheck=no are returned.

**FR-NUT-4.6** -- Filter by date range
> **Given** a user provides `startDate` and `endDate`, **Then** only entries within that range are returned.

**FR-NUT-4.7** -- Search descriptions and notes by keyword
> **Given** a user provides `search=chicken`, **Then** entries whose `description` or `notes` contain "chicken" (case-insensitive) are returned.

**FR-NUT-4.8** -- Cursor pagination
> **Given** more results than `limit`, **Then** response includes `meta.page.nextCursor` and `links.next`.

### FR-NUT-5: Calendar View

**FR-NUT-5.1** -- Daily summary
> **Given** a user requests calendar data for a month, **Then** each day includes: `mealsLogged` (count), `hydrationGoalMet` (boolean), `completeness` (`green`, `yellow`, `gray`).

**FR-NUT-5.2** -- Green indicator
> **Given** a day has 3+ meals logged AND hydration goal met, **Then** completeness is `green`.

**FR-NUT-5.3** -- Yellow indicator
> **Given** a day has 1-2 meals logged OR hydration goal partially met (>50%), **Then** completeness is `yellow`.

**FR-NUT-5.4** -- Gray indicator
> **Given** a day has 0 meals logged, **Then** completeness is `gray`.

---

## Hydration History

### FR-NUT-6: Hydration History

**FR-NUT-6.1** -- Daily hydration history
> **Given** a user requests hydration history for a date range, **Then** each day returns: `date`, `servingsLogged`, `totalOunces`, `goalMet`, `servingSizeOz`.

**FR-NUT-6.2** -- Trend data
> **Given** a user requests hydration trends for the last 30 days, **Then** response includes: `averageDailyOunces`, `daysGoalMet`, `totalDays`.

---

## Trends and Insights

### FR-NUT-7: Meal Consistency Trends

**FR-NUT-7.1** -- Meals per day
> **Given** a user requests 7-day meal trends, **Then** response includes daily meal counts broken down by meal type.

**FR-NUT-7.2** -- Meal regularity
> **Given** a user has 30 days of history, **Then** response includes percentage of days each meal type was logged.

**FR-NUT-7.3** -- Gap detection
> **Given** a user skipped breakfast 5 of the last 7 days, **Then** an insight of type `gap-detection` is returned with the pattern.

### FR-NUT-8: Emotional Eating Patterns

**FR-NUT-8.1** -- Mood before/after comparison
> **Given** a user has mood data on 10+ meals, **Then** response includes average mood before vs. after eating.

**FR-NUT-8.2** -- Mood-to-meal correlation
> **Given** a user has mood + context data, **Then** response includes correlation insights (e.g., low mood days correlate with fast food).

### FR-NUT-9: Cross-Domain Correlation

**FR-NUT-9.1** -- Meal logging vs check-in score
> **Given** a user has both meal logs and check-in data, **Then** the analytics system can compute correlation: "On days you eat 3+ meals, your check-in score averages X points higher."

**FR-NUT-9.2** -- Hydration vs mood
> **Given** a user has both hydration and mood data, **Then** the analytics system can compute correlation between hydration goal met and average mood rating.

**FR-NUT-9.3** -- Meal skipping and urge frequency
> **Given** a user has both meal logs and urge logs, **Then** the analytics system can identify whether meal skipping days have higher urge frequency.

---

## Nutrition Settings

### FR-NUT-10: User Configuration

**FR-NUT-10.1** -- Hydration goal setting
> **Given** a user updates their hydration goal to 12 servings, **Then** progress calculations use the new target going forward.

**FR-NUT-10.2** -- Serving size setting
> **Given** a user updates their serving size to 16 oz, **Then** future servings are recorded at 16 oz.

**FR-NUT-10.3** -- Meal reminder settings
> **Given** a user enables breakfast reminders at 8:00 AM, **Then** a notification is scheduled for 8:00 AM in their timezone.

**FR-NUT-10.4** -- Hydration reminder interval
> **Given** a user enables hydration reminders every 2 hours, **Then** notifications are sent every 2 hours during waking hours.

**FR-NUT-10.5** -- Missed meal nudge
> **Given** a user enables the missed meal nudge, **When** no meals are logged by 2:00 PM (configurable), **Then** a notification is sent.

**FR-NUT-10.6** -- Insight preferences for ED-sensitive users
> **Given** a user's addiction profile includes eating disorders, **When** they open nutrition settings, **Then** they can disable specific insight types.

---

## Eating Disorder Safeguards

### FR-NUT-11: Content Safety

**FR-NUT-11.1** -- No calorie data
> **Given** any API response in the nutrition domain, **Then** no field named `calories`, `calorieCount`, `macros`, or equivalent exists.

**FR-NUT-11.2** -- No weight tracking
> **Given** any API request or response, **Then** no field for `weight`, `bmi`, or body measurements exists.

**FR-NUT-11.3** -- No food judgment language
> **Given** any system-generated insight or message, **Then** no language classifying food as "healthy", "unhealthy", "good", "bad", "clean", "dirty", "cheat", or "guilty" is used.

**FR-NUT-11.4** -- ED-adjusted prompts
> **Given** a user's addiction profile includes eating disorders, **When** meal logging placeholder prompts are displayed, **Then** prompts emphasize nourishment (e.g., "What did you nourish yourself with?").

**FR-NUT-11.5** -- Concerning pattern detection
> **Given** a user logs 0-1 meals per day for 7+ consecutive days, **Then** a gentle prompt is shown: "We've noticed your meal logging has been low recently..." with options to contact counselor, view resources, or dismiss. **No** automated alerts are sent to the support network.

**FR-NUT-11.6** -- Skipped meals treated neutrally
> **Given** a user logs `eatingContext=skipped` for a meal, **Then** it is recorded for awareness without any negative messaging or flags.

---

## Platform Integrations

### FR-NUT-12: Health Platform Sync

**FR-NUT-12.1** -- Apple Health read
> **Given** Apple Health integration is enabled, **When** new meal data is available in HealthKit, **Then** it is imported with description and timestamp only -- calorie data is discarded.

**FR-NUT-12.2** -- Google Fit read
> **Given** Google Fit integration is enabled, **When** new nutrition data is available, **Then** it is imported with description and timestamp only.

**FR-NUT-12.3** -- Duplicate detection
> **Given** a user manually logs a meal AND the same meal is imported via health sync, **When** timestamps are within 30 minutes, **Then** the user is prompted to merge or keep both.

**FR-NUT-12.4** -- Calorie data discarded on import
> **Given** any external data source includes calorie or macro information, **Then** that data is discarded during import and never stored.

---

## Integration Points

### FR-NUT-13: Cross-Feature Integration

**FR-NUT-13.1** -- Tracking system feed
> **Given** a user logs at least one meal per day for consecutive days, **Then** the tracking system increments their nutrition logging streak.

**FR-NUT-13.2** -- Goal auto-check
> **Given** a user has a daily goal "Eat three meals today", **When** they log their third meal, **Then** the goal is auto-completed.

**FR-NUT-13.3** -- Support network visibility
> **Given** nutrition data, **Then** it is excluded from all support network views by default. The user must explicitly grant `nutrition` permission for any contact to see this data.

---

## Offline Support

### FR-NUT-14: Offline First

**FR-NUT-14.1** -- Offline meal logging
> **Given** the device is offline, **When** the user logs a meal, **Then** the entry is saved locally and synced when connection is restored.

**FR-NUT-14.2** -- Offline hydration logging
> **Given** the device is offline, **When** the user taps "+", **Then** the hydration count is incremented locally and synced when connection is restored.

**FR-NUT-14.3** -- Offline conflict resolution
> **Given** a meal was logged offline and a different entry was created on another device for the same timestamp, **Then** union merge is used -- both entries are kept.

---

## Notifications

### FR-NUT-15: Notification Rules

**FR-NUT-15.1** -- Meal reminders default off
> **Given** a new user, **Then** all meal reminder notifications are disabled by default.

**FR-NUT-15.2** -- Hydration reminders default off
> **Given** a new user, **Then** hydration reminder notifications are disabled by default.

**FR-NUT-15.3** -- Streak milestone notification
> **Given** a user logs meals for X consecutive days, **Then** a milestone notification is sent with compassionate messaging.

**FR-NUT-15.4** -- Hydration goal celebration
> **Given** a user meets their daily hydration goal, **Then** a celebration notification is sent: "You hit your water goal today! Your body thanks you."

**FR-NUT-15.5** -- All nutrition notifications independently togglable
> **Given** a user's notification settings, **Then** each nutrition notification type (meal reminders per meal type, hydration reminders, missed meal nudge, streak milestones, hydration celebration) can be enabled/disabled independently.

---

## Feature Flag

### FR-NUT-16: Feature Flag Gating

**FR-NUT-16.1** -- Flag disabled returns 404
> **Given** the `activity.nutrition` feature flag is disabled for a user, **When** they call any nutrition endpoint, **Then** the API returns `404 Not Found`.

**FR-NUT-16.2** -- Flag evaluation respects tier and rollout
> **Given** the `activity.nutrition` flag has `rolloutPercentage=50` and `tiers=["premium"]`, **Then** only ~50% of premium users can access nutrition endpoints.
