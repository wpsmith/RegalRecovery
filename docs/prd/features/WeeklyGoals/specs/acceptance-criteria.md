# Weekly/Daily Goals -- Acceptance Criteria

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft
**Feature Flag:** `activity.weekly-daily-goals`

---

## Five Dynamics

The five dynamics referenced throughout are: `spiritual`, `physical`, `emotional`, `intellectual`, `relational`.

---

## Goal Creation

### AC-GC-1: Create a manual goal with required fields

**Given** an authenticated user,
**When** they submit a new goal with `text` (1-200 chars) and at least one `dynamic` tag,
**Then** the system creates the goal, returns `201 Created` with `goalId`, and the goal appears in the appropriate daily or weekly view.

### AC-GC-2: Goal text validation

**Given** a user creates a goal,
**When** the `text` field is empty or exceeds 200 characters,
**Then** the system returns `422 Unprocessable Entity` with error code `rr:0x00800001`.

### AC-GC-3: Dynamic tag is required

**Given** a user creates a goal,
**When** no `dynamics` array is provided or it is empty,
**Then** the system returns `422 Unprocessable Entity` with error code `rr:0x00800002`.

### AC-GC-4: Goal scope defaults

**Given** a user creates a goal without specifying `scope`,
**Then** the scope defaults to `daily`.

### AC-GC-5: Recurrence options

**Given** a user creates a goal with `recurrence`,
**When** recurrence is `one-time`, `daily`, `specific-days` (with `daysOfWeek`), or `weekly` (with `dayOfWeek`),
**Then** the system stores the recurrence and generates goal instances accordingly.

### AC-GC-6: Priority sorting

**Given** a user assigns priority (`high`, `medium`, `low`) to goals,
**When** viewing the goal list within a dynamic section,
**Then** goals are sorted by priority (high first), then by creation time.

### AC-GC-7: Notes field validation

**Given** a user creates a goal with `notes`,
**When** notes exceed 500 characters,
**Then** the system returns `422 Unprocessable Entity`.

### AC-GC-8: Multiple dynamic tags

**Given** a user creates a goal tagged with multiple dynamics (e.g., `["spiritual", "relational"]`),
**Then** the goal appears in both dynamic sections in the daily/weekly view.

---

## Auto-Population

### AC-AP-1: Auto-populate from active commitments

**Given** a user has enabled auto-population from commitments in settings,
**And** they have an active commitment due today,
**When** the daily goals are generated for today,
**Then** the commitment appears as a pre-filled goal tagged to the appropriate dynamic with `source: "commitment"` and `sourceId` referencing the commitment.

### AC-AP-2: Auto-populate from activities

**Given** a user has enabled auto-population from activities in settings,
**And** they have configured specific activities to auto-populate,
**When** the daily goals are generated for today,
**Then** each configured activity appears as a pre-filled goal with `source: "activity"` and `sourceId`.

### AC-AP-3: Visual distinction of auto-populated goals

**Given** auto-populated goals exist in the daily view,
**Then** they are visually distinguished from manual goals via the `source` field (non-null indicates auto-populated).

### AC-AP-4: Remove auto-populated goal for one day

**Given** a user dismisses an auto-populated goal for today,
**When** they remove it,
**Then** the goal is marked as `dismissed` for that day only; it reappears the next applicable day according to auto-populate settings.

### AC-AP-5: Settings change takes effect next day

**Given** a user changes auto-populate settings mid-day,
**Then** today's goals are unchanged; the new settings take effect starting the following day.

### AC-AP-6: Activity completion auto-checks goal

**Given** a user completes an activity through its native flow (e.g., finishes journaling),
**And** the activity has a corresponding auto-populated goal,
**Then** the goal is automatically marked as `completed`.

---

## Daily Goals View

### AC-DV-1: Goals grouped by dynamic

**Given** a user views today's goals,
**Then** goals are grouped under collapsible sections for each of the five dynamics, each with its icon.

### AC-DV-2: Progress summary

**Given** a user views today's goals,
**Then** a progress summary is displayed at the top showing "X of Y goals completed today".

### AC-DV-3: Dynamic balance indicator

**Given** a user views today's goals,
**Then** a per-dynamic completion indicator is shown (e.g., "Spiritual 2/2, Physical 0/1, Emotional 1/1, Intellectual 0/0, Relational 1/3").

### AC-DV-4: Check off a goal

**Given** a user taps the checkbox on a goal,
**When** the goal is not yet completed,
**Then** the goal status changes to `completed`, `completedAt` is set, and the progress summary updates.

### AC-DV-5: Uncheck a completed goal

**Given** a user unchecks a previously completed goal,
**Then** the goal status reverts to `pending` and `completedAt` is cleared.

### AC-DV-6: Edit goal from daily view

**Given** a user taps a goal to expand it,
**Then** they can view notes, edit text, change dynamic tags, and remove the goal.

### AC-DV-7: Quick add goal

**Given** a user taps the floating "+" button,
**Then** a quick-add sheet appears to create a new goal for today.

---

## Dynamic Gap Nudge

### AC-DN-1: Nudge when dynamic has no goals

**Given** a dynamic has zero goals for today,
**Then** a subtle inline prompt is shown: "You don't have any [dynamic] goals today. Would you like to add one?"

### AC-DN-2: Nudge dismissal

**Given** a user dismisses a dynamic gap nudge,
**Then** the nudge does not reappear for that dynamic for the rest of the day.

### AC-DN-3: Nudge configuration

**Given** a user disables nudges for a specific dynamic or all nudges in Settings,
**Then** no nudge is shown for the disabled dynamic(s).

---

## Weekly Goals View

### AC-WV-1: Weekly goals grouped by dynamic

**Given** a user views this week's goals,
**Then** goals are grouped by dynamic with completion status and due day shown.

### AC-WV-2: Weekly progress summary

**Given** a user views this week's goals,
**Then** a weekly progress summary is shown: "X of Y goals completed this week".

### AC-WV-3: Dynamic balance for the week

**Given** a user views this week's goals,
**Then** a completion percentage per dynamic is displayed.

### AC-WV-4: Week navigation

**Given** a user views weekly goals,
**When** they swipe or tap navigation arrows,
**Then** past weeks' goals and completion data are displayed.

---

## End-of-Day Review

### AC-ED-1: Prompted at configured time

**Given** a user has end-of-day review enabled,
**Then** a notification is sent at their configured time (default: evening).

### AC-ED-2: Uncompleted goal disposition

**Given** a user opens the end-of-day review,
**And** uncompleted goals exist,
**Then** each uncompleted goal offers options: "Carry to tomorrow", "Skipped", or "No longer relevant".

### AC-ED-3: Carry to tomorrow

**Given** a user selects "Carry to tomorrow" for an uncompleted goal,
**Then** the goal appears in tomorrow's daily goals with `carriedFrom` date set.

### AC-ED-4: Reflection prompt

**Given** a user completes the end-of-day review,
**Then** an optional reflection prompt is shown: "What made today's goals easy or hard to complete?" with free-text and voice-to-text input.

### AC-ED-5: Review saves reflection

**Given** a user submits a reflection,
**Then** the reflection text is stored with the daily review record.

---

## End-of-Week Review

### AC-EW-1: Prompted on review day

**Given** a user has end-of-week review enabled,
**Then** a notification is sent on their chosen review day (default: Sunday evening).

### AC-EW-2: Weekly stats displayed

**Given** a user opens the end-of-week review,
**Then** the following stats are shown:
- Total goals set vs. completed
- Completion rate (percentage)
- Strongest dynamic (highest completion rate)
- Weakest dynamic (lowest completion rate or no goals set)
- Comparison to previous week

### AC-EW-3: Pre-set next week's goals

**Given** a user completes the end-of-week review,
**Then** they are offered the option to pre-set goals for the next week.

### AC-EW-4: Weekly reflection prompts

**Given** a user opens the end-of-week review,
**Then** optional reflection prompts are shown: "What was your biggest win this week?" and "What dynamic needs more attention next week?"

---

## Trends and Insights

### AC-TI-1: Completion rate over time

**Given** a user views goal trends,
**Then** a line graph shows daily and weekly goal completion rates with 7-day, 30-day, and 90-day view options.

### AC-TI-2: Per-dynamic trends

**Given** a user views goal trends,
**Then** separate trend data is available for each dynamic.

### AC-TI-3: Consistency score

**Given** a user views goal trends,
**Then** a consistency score is shown based on percentage of days with at least one goal completed across 3+ dynamics.

### AC-TI-4: Goal completion streaks

**Given** a user views goal trends,
**Then** streaks are shown for consecutive days with all goals completed and consecutive weeks with 80%+ completion.

---

## History

### AC-HI-1: Browse past goals by date

**Given** a user navigates to goal history,
**Then** they can browse past daily and weekly goals by date.

### AC-HI-2: Filter history

**Given** a user views goal history,
**When** they apply filters (dynamic, completion status, date range),
**Then** only matching goals are shown.

### AC-HI-3: Search goals by text

**Given** a user searches goal history,
**When** they enter a search term,
**Then** goals matching the search text are returned.

### AC-HI-4: Export goals

**Given** a user requests a goal export,
**Then** goal data is exported as CSV or PDF.

---

## Integration Points

### AC-IP-1: Feeds into tracking system

**Given** a user completes at least one goal per day,
**Then** the tracking system records goal completion as a streak-eligible activity.

### AC-IP-2: Commitment cross-reference

**Given** a user completes a goal tied to a commitment,
**Then** the corresponding commitment is also marked as completed for that day.

### AC-IP-3: Visible to support network

**Given** a sponsor/counselor/coach has been granted `goals` permission,
**Then** they can view the user's goal completion patterns.

### AC-IP-4: Post-mortem action items auto-populate

**Given** a post-mortem analysis produces action items,
**Then** each action item can auto-populate as a goal.

---

## Notifications

### AC-NT-1: Morning summary notification

**Given** a user has morning goal notifications enabled,
**Then** a notification is sent at the configured time: "You have X goals for today."

### AC-NT-2: Midday nudge

**Given** a user has midday nudge enabled,
**Then** a notification is sent: "You've completed X of Y goals so far today. Keep going!"

### AC-NT-3: Dynamic gap notification

**Given** a user has dynamic gap notifications enabled,
**And** a dynamic has no goals set for the current week,
**Then** a notification is sent once per week max per dynamic.

### AC-NT-4: Notifications independently togglable

**Given** the user navigates to goal notification settings,
**Then** each notification type (morning, midday, evening, weekly, dynamic gap) is independently togglable.

---

## Edge Cases

### AC-EC-1: No goals set for a day

**Given** a user has no goals for today,
**Then** no penalty is applied; a gentle prompt is shown on the dashboard.

### AC-EC-2: Recurring goal disabled

**Given** a user disables a recurring goal,
**Then** future occurrences are removed; past completion data is preserved.

### AC-EC-3: Offline goal management

**Given** a user is offline,
**Then** full goal creation, editing, completion, and dismissal are available; data syncs on reconnection.

### AC-EC-4: Feature flag gating

**Given** the feature flag `activity.weekly-daily-goals` is disabled for a user,
**Then** all goal-related endpoints return `404 Not Found` and mobile UI hides goal screens.
