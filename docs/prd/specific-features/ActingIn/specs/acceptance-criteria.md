# Acting In Behaviors -- Acceptance Criteria

**Feature:** Acting In Behaviors Activity
**Priority:** P2 (Wave 2)
**Feature Flag:** `activity.acting-in-behaviors`

---

## Behavior Configuration

### AC-AIB-001: Default behaviors available on first use

**Given** a user enables the Acting In Behaviors activity for the first time,
**When** they open the behavior configuration screen,
**Then** all 15 default behaviors (Blame, Shame, Criticism, Stonewall, Avoid, Hide, Lie, Excuse, Manipulate, Control with Anger, Passivity, Humor, Placating, Withhold Love/Sex, HyperSpiritualize) are listed and enabled by default.

### AC-AIB-002: Disable a default behavior

**Given** a user has all 15 default behaviors enabled,
**When** they toggle off the "Humor" behavior in Settings,
**Then** "Humor" no longer appears in the check-in flow, and historical data for "Humor" is preserved.

### AC-AIB-003: Re-enable a previously disabled default behavior

**Given** a user has disabled the "Humor" behavior,
**When** they toggle it back on in Settings,
**Then** "Humor" reappears in the check-in flow, and all prior historical data is accessible.

### AC-AIB-004: Create a custom behavior

**Given** a user is on the behavior configuration screen,
**When** they tap "Add Custom" and enter a name ("Sarcasm Deflection", 100 chars max) and an optional description,
**Then** the custom behavior is saved and appears alongside enabled defaults in the check-in flow.

### AC-AIB-005: Custom behavior name validation

**Given** a user is adding a custom behavior,
**When** they enter a name exceeding 100 characters,
**Then** the input is rejected with a validation error before submission.

### AC-AIB-006: Edit a custom behavior

**Given** a user has a custom behavior named "Sarcasm Deflection",
**When** they edit the name to "Deflecting with Humor" and save,
**Then** the updated name is reflected in future check-ins and historical entries reference the updated name.

### AC-AIB-007: Delete a custom behavior

**Given** a user has a custom behavior,
**When** they delete it,
**Then** it is removed from the check-in flow, and historical check-in entries that included this behavior are preserved with the original name.

---

## Check-In Flow

### AC-AIB-010: Daily check-in frequency configuration

**Given** a user opens Settings for Acting In Behaviors,
**When** they select "Daily" frequency and set the reminder time to 9:00 PM,
**Then** the system schedules a daily reminder notification at 9:00 PM in the user's local time zone.

### AC-AIB-011: Weekly check-in frequency configuration

**Given** a user opens Settings for Acting In Behaviors,
**When** they select "Weekly" frequency and choose Sunday as the check-in day,
**Then** the system schedules a weekly reminder notification on Sundays in the user's local time zone.

### AC-AIB-012: Check-in screen displays enabled behaviors

**Given** a user has 12 default behaviors enabled and 2 custom behaviors,
**When** they open the acting-in check-in,
**Then** all 14 behaviors are displayed as a checklist, and none are pre-checked.

### AC-AIB-013: Mark behaviors and add context

**Given** a user is completing an acting-in check-in,
**When** they check "Stonewall" and "Avoid",
**Then** for each checked behavior, they see optional fields: context note (500 char max), trigger chip selector (Stress, Conflict, Fear, Shame, Exhaustion, Loneliness, Other), and relationship tag selector (Spouse, Child, Coworker, Friend, Sponsor, Self, Other).

### AC-AIB-014: Context note character limit

**Given** a user is adding a context note to a checked behavior,
**When** they type more than 500 characters,
**Then** the input is truncated or rejected at 500 characters.

### AC-AIB-015: Submit check-in with behaviors marked

**Given** a user has checked 3 behaviors with optional context,
**When** they submit the check-in,
**Then** the check-in is saved with a timestamp, all checked behaviors, their context notes, triggers, and relationship tags, and a compassionate confirmation message is displayed: "Awareness is the first step toward change. Thank you for being honest."

### AC-AIB-016: Submit check-in with zero behaviors

**Given** a user opens the check-in and checks no behaviors,
**When** they submit,
**Then** a zero-behavior check-in is recorded and the message "No acting-in behaviors today. That's growth worth noticing." is displayed.

### AC-AIB-017: No limit on behaviors checked

**Given** a user is completing a check-in,
**When** they check all 15+ behaviors,
**Then** all are accepted without error, and the same compassionate confirmation is shown.

### AC-AIB-018: Voice-to-text for context notes

**Given** a user is adding a context note,
**When** they tap the voice-to-text button,
**Then** the system transcribes their voice input into the context note field.

---

## Frequency Change and Streaks

### AC-AIB-020: Change frequency from daily to weekly

**Given** a user has been doing daily check-ins for 14 days,
**When** they switch to weekly frequency,
**Then** historical daily data is preserved, and the check-in streak is recalculated based on the new weekly cadence.

### AC-AIB-021: Change frequency from weekly to daily

**Given** a user has been doing weekly check-ins for 4 weeks,
**When** they switch to daily frequency,
**Then** historical weekly data is preserved, and the streak starts tracking daily completions.

---

## Pattern Tracking and Insights

### AC-AIB-030: Frequency dashboard -- bar chart

**Given** a user has at least 7 days of acting-in check-in data,
**When** they open the insights dashboard and select the 7-day view,
**Then** a bar chart displays each behavior's occurrence count, sorted by frequency (most frequent first).

### AC-AIB-031: Frequency dashboard -- time range views

**Given** a user has 90+ days of data,
**When** they toggle between 7-day, 30-day, and 90-day views,
**Then** the bar chart updates to reflect the selected time range.

### AC-AIB-032: Trend arrows

**Given** a user has at least 14 days of data,
**When** they view the frequency dashboard,
**Then** each behavior shows a trend indicator: increasing (up arrow), stable (right arrow), or decreasing (down arrow), based on comparison of recent period vs prior period of equal length.

### AC-AIB-033: Trigger analysis

**Given** a user has check-in data with triggers logged,
**When** they view the trigger analysis section,
**Then** they see the most common triggers ranked by frequency, and trigger-to-behavior correlations (e.g., "When you're stressed, you most often stonewall or avoid").

### AC-AIB-034: Relationship impact view

**Given** a user has check-in data with relationship tags,
**When** they view the relationship impact section,
**Then** they see which relationships are most frequently affected, with trend lines showing changes over time (e.g., "Acting-in behaviors affecting your spouse have decreased 40% over the last month").

### AC-AIB-035: Time-of-day and day-of-week heatmap

**Given** a user has 30+ days of data,
**When** they view the pattern heatmap,
**Then** they see a heatmap showing when acting-in behaviors are most common by day-of-week and time-of-day.

### AC-AIB-036: Cross-tool correlation -- PCI

**Given** a user has both PCI and acting-in data,
**When** they view the cross-tool insights,
**Then** they see a note when elevated PCI scores coincide with increased acting-in behaviors.

### AC-AIB-037: Cross-tool correlation -- FASTER Scale

**Given** a user has both FASTER Scale and acting-in data,
**When** they view the cross-tool insights,
**Then** they see which FASTER stages (particularly Anxiety and Ticked Off) correlate with acting-in behavior spikes.

### AC-AIB-038: Cross-tool correlation -- Post-Mortem

**Given** a user has post-mortem analysis data,
**When** they view the cross-tool insights,
**Then** they see acting-in behaviors identified in the build-up phase of past relapses.

---

## History

### AC-AIB-040: Browse past check-ins

**Given** a user has multiple past check-ins,
**When** they open the history view,
**Then** they see a chronological list of past check-ins browsable by date.

### AC-AIB-041: View check-in details

**Given** a user sees a past check-in in the history list,
**When** they tap on it,
**Then** they see the full details: all behaviors checked, context notes, triggers, and relationship tags.

### AC-AIB-042: Filter history

**Given** a user is browsing history,
**When** they filter by a specific behavior ("Stonewall"), trigger ("Stress"), or relationship tag ("Spouse"),
**Then** only check-ins matching the filter are displayed.

### AC-AIB-043: Export history as CSV

**Given** a user is on the history screen,
**When** they tap "Export" and select CSV,
**Then** a CSV file is generated containing all check-in data within the selected date range and downloaded to the device.

### AC-AIB-044: Export history as PDF

**Given** a user is on the history screen,
**When** they tap "Export" and select PDF,
**Then** a formatted PDF report is generated containing check-in summaries, suitable for therapy sessions or sponsor meetings.

---

## Offline Support

### AC-AIB-050: Complete check-in offline

**Given** the user's device has no internet connection,
**When** they complete an acting-in check-in,
**Then** the check-in is saved locally and synced when connection is restored.

### AC-AIB-051: Offline data consistency

**Given** a user completes 3 check-ins offline,
**When** the device reconnects,
**Then** all 3 check-ins are uploaded in chronological order with original timestamps preserved (immutable).

---

## Permissions and Visibility

### AC-AIB-060: Sponsor visibility requires explicit permission

**Given** a user has a sponsor in their support network,
**When** the sponsor attempts to view the user's acting-in behavior data without explicit permission,
**Then** the API returns 404 (not 403) to hide data existence.

### AC-AIB-061: Spouse visibility with permission

**Given** a user has granted their spouse read access to acting-in behaviors,
**When** the spouse views acting-in data,
**Then** they see the user's acting-in behavior patterns (frequency trends, not individual context notes) and the access is logged in the audit trail.

---

## Compassionate Messaging

### AC-AIB-070: First-use helper text

**Given** a user opens the Acting In Behaviors feature for the first time,
**When** the screen loads,
**Then** helper text is displayed: "Acting-in behaviors are the subtle ways addiction affects our relationships -- even when we're sober. Tracking them helps you see the full picture of your recovery, not just the absence of acting out."

### AC-AIB-071: Post-check-in rotating messages

**Given** a user submits a check-in with one or more behaviors checked,
**When** the confirmation screen appears,
**Then** one of the following messages is displayed (rotating): "Sobriety is more than not acting out. The work you're doing here is building real character." / "Noticing these patterns takes courage. You're becoming someone new." / "Every behavior you name loses a little power over you."

### AC-AIB-072: Re-engagement prompt after missed check-ins

**Given** a user has not completed a check-in for 3+ days (daily) or 2+ weeks (weekly),
**When** they receive a notification,
**Then** the message reads: "It's been a few days since your last acting-in check. Picking it back up is always worthwhile." with no guilt framing.

---

## Feature Flag

### AC-AIB-080: Feature gated by flag

**Given** the feature flag `activity.acting-in-behaviors` is disabled,
**When** a user attempts to access acting-in behaviors endpoints,
**Then** the API returns 404 and the mobile UI hides the feature.

### AC-AIB-081: Feature flag respects tier and rollout

**Given** the feature flag has `tiers: ["premium"]` and `rolloutPercentage: 50`,
**When** a free-tier user or a premium user outside the rollout bucket requests the feature,
**Then** the feature is not available to them.

---

## Calendar and Tracking Integration

### AC-AIB-090: Check-in appears in calendar view

**Given** a user completes an acting-in check-in on March 28,
**When** they view the calendar for March,
**Then** March 28 shows an acting-in activity indicator.

### AC-AIB-091: Check-in streak tracking

**Given** a user has completed daily check-ins for 7 consecutive days,
**When** they view the tracking system,
**Then** their acting-in check-in streak shows 7 days.
