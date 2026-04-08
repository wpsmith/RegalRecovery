# Phone Calls Activity -- Acceptance Criteria

**Activity:** Phone Calls
**Priority:** P1 (Wave 2)
**Feature Flag:** `activity.phone-calls`

---

## Call Logging

### AC-PC-1: Create Phone Call Log (Required Fields)

**Given** an authenticated user with the `activity.phone-calls` flag enabled,
**When** they submit a phone call log with direction, contact type, and connected status,
**Then** the system creates the call log with a unique `callId`, sets `createdAt` as immutable, writes a calendar activity dual-write, and returns 201 with the call record.

### AC-PC-2: Direction Field Validation

**Given** a user logging a phone call,
**When** they set direction to "made" or "received",
**Then** the value is accepted; any other value returns 422 Unprocessable Entity.

### AC-PC-3: Contact Type Enum Validation

**Given** a user logging a phone call,
**When** they set contactType to one of: `sponsor`, `accountability-partner`, `counselor`, `coach`, `support-person`, `custom`,
**Then** the value is accepted; any other value returns 422.

### AC-PC-4: Custom Contact Type Requires Label

**Given** a user logging a phone call with contactType = "custom",
**When** they do not provide a `customContactLabel`,
**Then** the system returns 422 with detail "customContactLabel is required when contactType is custom".

### AC-PC-5: Connected Status Tracking

**Given** a user logging a phone call,
**When** they set connected to `true` or `false`,
**Then** the value is persisted. Both connected and not-connected calls count toward the daily call streak.

### AC-PC-6: Optional Fields Are Truly Optional

**Given** a user logging a phone call,
**When** they omit contactName, durationMinutes, and notes,
**Then** the call log is created successfully with those fields as null.

### AC-PC-7: Contact Name Length Validation

**Given** a user logging a phone call,
**When** they provide a contactName exceeding 50 characters,
**Then** the system returns 422 with source pointer `/data/contactName`.

### AC-PC-8: Notes Length Validation

**Given** a user logging a phone call,
**When** they provide notes exceeding 500 characters,
**Then** the system returns 422 with source pointer `/data/notes`.

### AC-PC-9: Duration Quick-Select Values

**Given** a user logging a phone call,
**When** they provide a durationMinutes value,
**Then** any non-negative integer is accepted (quick-select values 5, 10, 15, 20, 30, 60 are UI-only suggestions).

### AC-PC-10: Timestamp Backdating Allowed

**Given** a user logging a phone call,
**When** they set the timestamp to a past date/time,
**Then** the call is created with that timestamp and the call streak is recalculated to include the original date.

### AC-PC-11: Timestamp Immutability (FR2.7)

**Given** a phone call log has been created,
**When** the user attempts to update the timestamp via PATCH,
**Then** the system returns 422 with detail "timestamp is immutable" and the timestamp remains unchanged.

---

## Quick Log

### AC-PC-20: Quick Log Minimal Fields

**Given** a user triggers quick log (dashboard widget, notification, or quick action),
**When** they submit with only direction (default: "made"), contactType (default: last used), and connected (default: true),
**Then** the call log is created with timestamp = now and remaining fields null.

### AC-PC-21: Quick Log Expansion

**Given** a user has created a call log via quick log,
**When** they PATCH the call with contactName, durationMinutes, and notes,
**Then** those fields are updated; `createdAt` and `timestamp` remain unchanged.

---

## Saved Contacts

### AC-PC-30: Create Saved Contact

**Given** an authenticated user,
**When** they create a saved contact with name and contactType,
**Then** the contact is saved and available for quick-select during call logging.

### AC-PC-31: Saved Contact Limit

**Given** a user already has 10 saved contacts,
**When** they attempt to create an 11th,
**Then** the system returns 422 with detail "Maximum 10 saved contacts allowed".

### AC-PC-32: Saved Contact Phone Number Optional

**Given** a user creating a saved contact,
**When** they omit the phoneNumber field,
**Then** the contact is saved without a phone number; the "Call Now" deep-link button is not available for this contact.

### AC-PC-33: Delete Saved Contact Preserves History

**Given** a user deletes a saved contact,
**When** historical call logs reference that contact's savedContactId,
**Then** the historical logs are preserved unchanged; only the saved contact record is removed.

### AC-PC-34: Saved Contacts in Emergency Tools

**Given** a user has saved contacts with phone numbers,
**When** they access the Emergency Tools overlay,
**Then** those saved contacts appear as crisis call options with deep-link to phone dialer.

---

## Call History

### AC-PC-40: List Calls Reverse Chronological

**Given** a user has logged multiple phone calls,
**When** they request the call history without sort parameter,
**Then** calls are returned in reverse chronological order (newest first) with cursor-based pagination.

### AC-PC-41: Filter by Direction

**Given** a user requests call history with `filter=direction eq 'made'`,
**When** the query executes,
**Then** only outgoing calls are returned.

### AC-PC-42: Filter by Contact Type

**Given** a user requests call history with `filter=contactType eq 'sponsor'`,
**When** the query executes,
**Then** only calls with contactType "sponsor" are returned.

### AC-PC-43: Filter by Connected Status

**Given** a user requests call history with `filter=connected eq true`,
**When** the query executes,
**Then** only calls where a conversation happened are returned.

### AC-PC-44: Filter by Date Range

**Given** a user requests call history with startDate and endDate parameters,
**When** the query executes,
**Then** only calls within the specified date range (inclusive) are returned.

### AC-PC-45: Search Notes by Keyword

**Given** a user requests call history with `search=sponsor`,
**When** the query executes,
**Then** calls whose notes contain "sponsor" (case-insensitive) are returned.

### AC-PC-46: Calendar View Day Query

**Given** a user requests the calendar day view for a specific date,
**When** the query executes against calendarActivities,
**Then** PHONECALL activity entries for that date are returned with summary data (count, connected vs. attempted).

---

## Call Streak

### AC-PC-50: Streak Counts Connected and Attempted Calls

**Given** a user logs a call with connected = false (attempted but not connected),
**When** the call streak is calculated,
**Then** that day counts toward the consecutive call streak because the effort of reaching out matters.

### AC-PC-51: Streak Increments on First Call of the Day

**Given** a user has not logged any calls today,
**When** they log their first call (any direction, any connected status),
**Then** the daily call streak increments by one.

### AC-PC-52: Multiple Calls Same Day Do Not Double-Count

**Given** a user has already logged a call today,
**When** they log a second call on the same day,
**Then** the daily call streak remains the same (one day per calendar day).

### AC-PC-53: Backdated Call Recalculates Streak

**Given** a user missed logging yesterday,
**When** they backdate a call to yesterday's date,
**Then** the call streak is recalculated to include yesterday, potentially extending the streak.

---

## Trends and Insights

### AC-PC-60: Call Frequency Summary

**Given** a user has logged calls over the past 30 days,
**When** they request the weekly summary,
**Then** the response includes: total calls (made + received), connection rate percentage, most contacted type, and comparison to previous week.

### AC-PC-61: Connection Rate Calculation

**Given** a user has logged 10 outgoing calls of which 8 were connected,
**When** the connection rate is calculated,
**Then** the rate is 80% (connected outgoing calls / total outgoing calls).

### AC-PC-62: Contact Type Distribution

**Given** a user has logged calls to various contact types,
**When** they request the contact type distribution,
**Then** the response includes counts and percentages per contact type.

### AC-PC-63: Isolation Warning Trigger

**Given** a user has not logged any calls for their configured inactivity threshold (default: 3 days),
**When** the isolation check runs,
**Then** the system creates an in-app notification with isolation warning text and quick-dial options.

### AC-PC-64: Isolation Warning Configurable

**Given** a user updates their phone call notification settings,
**When** they set isolationThresholdDays to 5,
**Then** the isolation warning is only triggered after 5 consecutive days without a call.

---

## Notifications

### AC-PC-70: Daily Call Reminder

**Given** a user has enabled the daily call reminder,
**When** the configured reminder time arrives and no call has been logged today,
**Then** a push notification is sent with encouraging text.

### AC-PC-71: Missed Call Streak Nudge

**Given** a user has not logged a call for their configured inactivity threshold days,
**When** the nudge is triggered,
**Then** a push notification is sent with the number of days since last call and encouragement to reach out.

### AC-PC-72: Streak Milestone Notification

**Given** a user's daily call streak reaches a milestone (7, 14, 21, 30, 60, 90 days),
**When** the streak is recalculated,
**Then** a streak milestone notification is sent with encouraging text.

### AC-PC-73: All Phone Call Notifications Independently Togglable

**Given** a user in notification settings,
**When** they toggle phoneCallDailyReminder, phoneCallStreakNudge, or phoneCallMilestone independently,
**Then** only that specific notification type is affected.

---

## Support Network Visibility

### AC-PC-80: Sponsor Can View Sponsee Calls

**Given** a sponsor has been granted `phone-calls` read permission by the user,
**When** the sponsor requests the user's phone call logs,
**Then** the call logs are returned (per community permission model).

### AC-PC-81: No Permission Returns 404

**Given** a sponsor has NOT been granted `phone-calls` read permission,
**When** the sponsor requests the user's phone call logs,
**Then** the system returns 404 (not 403) to hide data existence.

---

## Integration Points

### AC-PC-90: Feeds Tracking System

**Given** a user logs a phone call,
**When** the call is saved,
**Then** the tracking system is updated with consecutive-days-with-call data.

### AC-PC-91: Feeds Commitment Fulfillment

**Given** a user has a commitment "make X calls per day/week",
**When** they log a phone call,
**Then** the commitment progress is incremented.

### AC-PC-92: Cross-Reference Person Check-In Prompt

**Given** a user has just logged a phone call,
**When** the response is returned,
**Then** it includes a `crossReferencePrompt` field suggesting they also log a person check-in (dismissible client-side).

### AC-PC-93: Offline Call Logging

**Given** the user has no internet connection,
**When** they log a phone call,
**Then** the call is stored locally and synced when connection is restored. Conflicts resolved by union merge (both versions kept).

---

## Edge Cases

### AC-PC-100: Call With No Duration Is Valid

**Given** a user logs a call without specifying durationMinutes,
**Then** the call is saved with durationMinutes = null. This is valid by design.

### AC-PC-101: Multiple Calls to Same Person Same Day

**Given** a user calls their sponsor twice in one day,
**When** both calls are logged,
**Then** each call is stored as an independent entry.

### AC-PC-102: Received Not-Connected is Valid

**Given** a user logs a received call with connected = false,
**Then** the call is saved as a missed incoming call the user is logging for awareness.

### AC-PC-103: Delete Call Log

**Given** a user deletes a phone call log entry,
**When** the deletion succeeds,
**Then** the call streak and all analytics are recalculated. Calendar activity dual-write is also deleted.

---

## Feature Flag

### AC-PC-110: Feature Flag Disabled Returns 404

**Given** the `activity.phone-calls` feature flag is disabled for a user,
**When** the user attempts to access any phone call endpoint,
**Then** the system returns 404 Not Found (fail closed).

### AC-PC-111: Feature Flag Respects Tier Gating

**Given** the `activity.phone-calls` flag is configured with specific tiers,
**When** a user outside those tiers attempts to access phone call endpoints,
**Then** the system returns 404 Not Found.
