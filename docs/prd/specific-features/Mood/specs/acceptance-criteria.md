# Mood Ratings -- Acceptance Criteria

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft
**PRD Source:** `docs/prd/specific-features/Mood/Mood_Ratings_Activity.md`
**Priority:** P1 (Wave 2)
**Feature Flag:** `activity.mood`

---

## Naming Convention

Each criterion has a unique ID: `MOOD-{category}-{number}`

- **FR** = Functional Requirement
- **AC** = Acceptance Criterion (behavioral, Given/When/Then)
- **NFR** = Non-Functional Requirement
- **EC** = Edge Case

---

## 1. Mood Entry

### MOOD-FR-001: Rating Scale (1-5)

Both display modes (emoji and numeric) map to the same underlying 1-5 integer scale.

| Value | Label | Emoji |
|-------|-------|-------|
| 5 | Great | (emoji: grinning) |
| 4 | Good | (emoji: slightly smiling) |
| 3 | Okay | (emoji: neutral) |
| 2 | Struggling | (emoji: worried) |
| 1 | Crisis | (emoji: anxious with sweat) |

### MOOD-AC-001: Create Mood Entry -- Rating Only

**Given** an authenticated user on the Mood Ratings screen,
**When** they tap a mood rating (1-5),
**Then** a mood entry is created with the selected rating, timestamped automatically in UTC, and a confirmation animation is shown.

### MOOD-AC-002: Create Mood Entry -- With Context Note

**Given** an authenticated user selecting a mood rating,
**When** they enter an optional context note (max 200 characters),
**Then** the note is saved alongside the mood entry.

### MOOD-AC-003: Create Mood Entry -- With Emotion Labels

**Given** an authenticated user selecting a mood rating,
**When** they select one or more emotion labels from the predefined list,
**Then** the selected emotion labels are saved as an array alongside the mood entry.

**Predefined emotion labels:**
- Positive: Peaceful, Grateful, Hopeful, Confident, Connected
- Anxious cluster: Anxious, Lonely, Angry, Ashamed, Overwhelmed
- Low cluster: Sad, Numb, Restless, Afraid, Frustrated

### MOOD-AC-004: Mood Entry Under 10 Seconds

**Given** an authenticated user,
**When** they log a mood with rating only (no note, no emotion labels),
**Then** the entire flow completes in under 10 seconds from tap to save confirmation.

### MOOD-AC-005: Mood Entry Under 30 Seconds (Full)

**Given** an authenticated user,
**When** they log a mood with rating, context note, and emotion labels,
**Then** the entire flow completes in under 30 seconds.

### MOOD-FR-002: Multiple Entries Per Day

Unlimited mood entries per day, each independently timestamped. Each entry stands alone.

### MOOD-AC-006: Multiple Entries Saved Independently

**Given** a user who has already logged a mood today,
**When** they log another mood entry,
**Then** a new independent entry is created (not an update to the previous one) and both entries are visible in the mini-timeline.

### MOOD-AC-007: Context Note Max Length

**Given** a user entering a context note,
**When** the note exceeds 200 characters,
**Then** the input is truncated or rejected with a validation error.

---

## 2. Mood Entry Retrieval

### MOOD-AC-008: Get Today's Entries

**Given** an authenticated user with mood entries for today,
**When** they open the Mood Ratings screen,
**Then** they see a mini-timeline showing all today's entries plotted by time, with today's average mood, highest/lowest entries, and entry count.

### MOOD-AC-009: Get Entries by Date Range

**Given** an authenticated user,
**When** they request mood entries for a specific date range,
**Then** entries within that range are returned in reverse chronological order with cursor-based pagination.

### MOOD-AC-010: Get Single Entry Detail

**Given** an authenticated user who taps an entry on the mini-timeline,
**When** the entry detail loads,
**Then** it shows the rating, context note, emotion labels, and exact timestamp.

---

## 3. Mood History

### MOOD-AC-011: Daily View -- Browse Past Days

**Given** an authenticated user on the Mood History screen,
**When** they browse past days,
**Then** each day shows: date, number of entries, average mood (emoji + numeric), high/low, and a mini-timeline preview, in reverse chronological order.

### MOOD-AC-012: Calendar View -- Color Coded

**Given** an authenticated user on the Calendar View,
**When** the monthly calendar loads,
**Then** days are color-coded by average daily mood:
- Green: 4.0-5.0
- Yellow: 3.0-3.9
- Orange: 2.0-2.9
- Red: 1.0-1.9
- Gray: no entries

### MOOD-AC-013: Search Notes by Keyword

**Given** an authenticated user on Mood History,
**When** they search by keyword,
**Then** entries whose context notes contain that keyword are returned.

### MOOD-AC-014: Filter by Rating

**Given** an authenticated user,
**When** they filter by one or more mood ratings (e.g., "Struggling" and "Crisis"),
**Then** only entries with those ratings are returned.

### MOOD-AC-015: Filter by Emotion Label

**Given** an authenticated user,
**When** they filter by emotion label (e.g., "Anxious"),
**Then** only entries containing that label are returned.

### MOOD-AC-016: Filter by Time of Day

**Given** an authenticated user,
**When** they filter by time of day (morning, afternoon, evening, night),
**Then** only entries created during that time window (in user's timezone) are returned.

---

## 4. Trends and Insights (Read-Only Aggregations)

### MOOD-AC-017: Daily Average Line Graph

**Given** an authenticated user on Trends,
**When** they select a time range (7-day, 30-day, 90-day),
**Then** a daily average mood line graph is displayed with individual entries as data points and an overall trend direction (improving, stable, declining).

### MOOD-AC-018: Weekly Summary

**Given** an authenticated user,
**When** they view the weekly summary,
**Then** it shows: average mood this week vs. last week, best and most challenging day, most common emotion labels, and number of entries.

### MOOD-AC-019: Monthly Summary

**Given** an authenticated user,
**When** they view the monthly summary,
**Then** it shows: average mood, distribution breakdown by rating (% Great, Good, Okay, Struggling, Crisis), and comparison to previous month.

### MOOD-AC-020: Time-of-Day Heatmap

**Given** an authenticated user on Insights,
**When** they view the time-of-day heatmap,
**Then** it displays average mood by hour of day across the selected period, revealing vulnerable and strong time windows.

### MOOD-AC-021: Day-of-Week Patterns

**Given** an authenticated user,
**When** they view day-of-week patterns,
**Then** it displays average mood by day of the week with textual insight (e.g., "Your most challenging day tends to be Sunday evening").

### MOOD-AC-022: Emotion Label Trends

**Given** an authenticated user,
**When** they view emotion label trends (30-day),
**Then** it shows the most frequent labels as a bar chart, shift tracking vs. previous period, and co-occurrence patterns.

### MOOD-AC-023: Correlation with Recovery Activities

**Given** an authenticated user with mood and activity data,
**When** they view correlation insights,
**Then** the system calculates and displays correlations between mood and exercise, prayer, meetings, journaling, and other tracked activities.

### MOOD-AC-024: Correlation with Urges and Sobriety

**Given** an authenticated user with mood and urge data,
**When** they view urge correlations,
**Then** the system displays average mood before urges, consecutive low-mood warnings, and urge frequency patterns.

---

## 5. Alerts

### MOOD-AC-025: Sustained Low Mood Alert

**Given** a user whose average daily mood is <=2.0 for 3 or more consecutive days,
**When** the threshold is met,
**Then** the system prompts the user with a compassionate message and options: contact sponsor, contact counselor, log an urge, journal, or view coping tools.

### MOOD-AC-026: Sustained Low Mood -- Support Network Notification

**Given** a user with sustained low mood AND the user has enabled low-mood alert sharing in Settings,
**When** the 3-day threshold is met,
**Then** a notification is sent to the configured support network contacts.

### MOOD-AC-027: Sustained Low Mood -- No Auto-Share

**Given** a user with sustained low mood who has NOT enabled low-mood alert sharing,
**When** the 3-day threshold is met,
**Then** no notification is sent to the support network. Only the user is prompted.

### MOOD-AC-028: Crisis Entry Alert

**Given** a user who selects "Crisis" (rating = 1),
**When** the entry is saved,
**Then** the system immediately shows a compassionate prompt with options: Emergency tools overlay, Call sponsor, Call crisis line, Breathing exercise, Panic prayer.

### MOOD-AC-029: Crisis Entry -- No Auto-Notification

**Given** a user who logs a crisis-level entry,
**When** the crisis prompt appears,
**Then** the support network is NOT automatically notified. The user must explicitly choose to broadcast.

---

## 6. Dashboard Widget

### MOOD-AC-030: Widget One-Tap Logging

**Given** the mood widget is visible on the Dashboard,
**When** the user taps an emoji in the widget row,
**Then** a mood entry is created directly (no navigation required) with the selected rating.

### MOOD-AC-031: Widget Today Summary

**Given** the user has logged moods today,
**When** the Dashboard loads,
**Then** the mood widget shows today's average mood and the current mood tracking streak (consecutive days with at least one entry).

---

## 7. Edit and Delete

### MOOD-AC-032: Edit Entry Within 24 Hours

**Given** a mood entry created less than 24 hours ago,
**When** the user edits the rating, note, or emotion labels,
**Then** the entry is updated successfully. The `createdAt` timestamp remains immutable; only `modifiedAt` changes.

### MOOD-AC-033: Delete Entry Within 24 Hours

**Given** a mood entry created less than 24 hours ago,
**When** the user deletes the entry,
**Then** the entry is permanently removed.

### MOOD-AC-034: Cannot Edit After 24 Hours

**Given** a mood entry created more than 24 hours ago,
**When** the user attempts to edit it,
**Then** the API returns 422 Unprocessable Entity with a message that the entry is locked.

### MOOD-AC-035: Cannot Delete After 24 Hours

**Given** a mood entry created more than 24 hours ago,
**When** the user attempts to delete it,
**Then** the API returns 422 Unprocessable Entity with a message that the entry is permanent.

---

## 8. Notifications

### MOOD-AC-036: Scheduled Mood Check-In

**Given** a user has configured scheduled mood check-in times (1-3 per day),
**When** a scheduled time arrives,
**Then** a push notification is sent with text: "Quick check -- how are you feeling right now?"

### MOOD-AC-037: Missed Mood Nudge

**Given** a user has not logged mood for X days (user-configurable threshold, default 3),
**When** the inactivity threshold is reached,
**Then** a nudge notification is sent: "You haven't logged your mood in X days. Checking in with yourself takes just a moment."

### MOOD-AC-038: Streak Milestone

**Given** a user has logged mood for X consecutive days,
**When** a milestone is reached,
**Then** a celebration notification is sent: "X days of mood tracking. You're building real emotional awareness."

---

## 9. Integration Points

### MOOD-AC-039: Calendar Activity Dual-Write

**Given** a mood entry is created,
**When** the entry is saved to the moodRatings collection,
**Then** a denormalized entry is also written to the calendarActivities collection with activityType=MOOD.

### MOOD-AC-040: Support Network Visibility

**Given** a support contact (sponsor, counselor, coach, spouse) with mood data permission,
**When** they request the user's mood data,
**Then** the data is returned if the user has granted explicit permission. Otherwise 404 is returned.

### MOOD-AC-041: Tracking Streak Integration

**Given** a user logs at least one mood entry per day,
**When** the tracking system calculates streaks,
**Then** consecutive days with at least one mood entry count as a mood tracking streak.

---

## 10. Offline and Edge Cases

### MOOD-EC-001: Offline Mood Logging

**Given** a user has no internet connection,
**When** they log a mood entry,
**Then** the entry is saved locally with its creation timestamp, and synced to the server when connection is restored.

### MOOD-EC-002: Timezone Change

**Given** a user changes timezones during the day,
**When** mood entries are displayed,
**Then** entries are timestamped in UTC, displayed in the user's current timezone, and daily averages are calculated based on the user's home timezone.

### MOOD-EC-003: High-Volume Logging (20+ per day)

**Given** a user logs 20 or more entries in a single day,
**When** insights are calculated,
**Then** all entries are saved; insights use the daily average; no cap is imposed.

### MOOD-EC-004: Display Mode Switch

**Given** a user switches between emoji and numeric display modes in Settings,
**When** historical data is displayed,
**Then** all historical data is displayed in the new mode without data loss (both modes map to 1-5 scale).

### MOOD-EC-005: Accidental Crisis Selection

**Given** a user selects "Crisis" accidentally,
**When** they view the entry,
**Then** the entry is editable within 24 hours, and the crisis prompt can be dismissed without taking action.

---

## 11. Non-Functional Requirements

### MOOD-NFR-001: Immutable Timestamps

All mood entry `createdAt` timestamps are immutable once set (FR2.7). Updates only modify `modifiedAt`.

### MOOD-NFR-002: Feature Flag Gating

All mood endpoints are gated behind `activity.mood` feature flag. When disabled, endpoints return 404.

### MOOD-NFR-003: Tenant Isolation

All mood data is scoped by `tenantId`. Queries enforce tenant isolation at the application layer.

### MOOD-NFR-004: Privacy by Architecture

Mood data is not shared with the support network by default. All sharing requires explicit opt-in via permissions.

### MOOD-NFR-005: Compassionate Error Messages

Error messages and empty states never frame low moods or inconsistency as failure. Crisis-level entries are met with warmth.
