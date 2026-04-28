# Meetings Attended -- Acceptance Criteria

**Feature:** Meetings Attended Activity
**Priority:** P1 (Wave 2)
**Feature Flag:** `activity.meetings`

---

## Functional Requirements

### FR-MTG-1: Log Meeting Attendance

**FR-MTG-1.1** Quick-Log Entry
- **Given** an authenticated user with `activity.meetings` flag enabled,
  **When** they submit a meeting log with at minimum a timestamp and meeting type,
  **Then** the system creates a meeting log entry, returns a `201 Created` with the meeting ID, and writes a dual-write calendar activity entry.

**FR-MTG-1.2** Meeting Types
- **Given** a user logging a meeting,
  **When** they select a meeting type,
  **Then** the system accepts one of: `SA`, `CR`, `AA`, `therapy`, `group-counseling`, `church`, `custom`.
- **Note:** Only SA (Sexaholics Anonymous) and Celebrate Recovery -- never SAA.

**FR-MTG-1.3** Custom Meeting Type
- **Given** a user selects the `custom` meeting type,
  **When** they provide a `customTypeLabel`,
  **Then** the system stores the custom label (max 100 characters) alongside the type.

**FR-MTG-1.4** Optional Fields
- **Given** a user logging a meeting,
  **When** they include optional fields (name, location, duration, notes),
  **Then** all optional fields are stored and returned on retrieval.
- Fields: `name` (max 200), `location` (max 300), `durationMinutes` (>= 0), `notes` (max 2000).

**FR-MTG-1.5** Immutable Timestamp
- **Given** a meeting log has been created,
  **When** the user attempts to update the `timestamp` field,
  **Then** the update is rejected with a `422 Unprocessable Entity` error indicating the timestamp is immutable (FR2.7).

**FR-MTG-1.6** Multiple Meetings Per Day
- **Given** a user has already logged a meeting today,
  **When** they log another meeting for the same day,
  **Then** both entries are stored independently with unique meeting IDs.

### FR-MTG-2: Saved Meetings (Favorites)

**FR-MTG-2.1** Create Saved Meeting
- **Given** an authenticated user,
  **When** they create a saved meeting with name, type, day/time, and optional location,
  **Then** the system stores it as a reusable template with a unique `savedMeetingId`.

**FR-MTG-2.2** One-Tap Logging from Saved Meeting
- **Given** a user has saved meetings,
  **When** they log attendance using a `savedMeetingId`,
  **Then** the system pre-fills the meeting type, name, and location from the saved template, requiring only the timestamp.

**FR-MTG-2.3** List Saved Meetings
- **Given** a user has created saved meetings,
  **When** they request their saved meetings list,
  **Then** the system returns all active saved meetings sorted by name.

**FR-MTG-2.4** Update Saved Meeting
- **Given** a user has a saved meeting,
  **When** they update its name, type, schedule, or location,
  **Then** the saved meeting is updated. Previously logged meetings from this template are not retroactively changed.

**FR-MTG-2.5** Delete Saved Meeting
- **Given** a user has a saved meeting,
  **When** they delete it,
  **Then** the saved meeting is soft-deleted. Previously logged meetings referencing it are not affected.

### FR-MTG-3: Attendance History

**FR-MTG-3.1** List Meeting Logs (Paginated)
- **Given** an authenticated user with meeting history,
  **When** they request their meeting logs,
  **Then** the system returns meeting entries in reverse chronological order with cursor-based pagination.

**FR-MTG-3.2** Filter by Meeting Type
- **Given** a user with meetings of various types,
  **When** they filter by `meetingType`,
  **Then** only meetings matching that type are returned.

**FR-MTG-3.3** Filter by Date Range
- **Given** a user with meeting history,
  **When** they provide `startDate` and/or `endDate` query parameters,
  **Then** only meetings within the specified range (inclusive) are returned.

**FR-MTG-3.4** Get Meeting Detail
- **Given** a meeting log exists,
  **When** the user requests it by `meetingId`,
  **Then** the full meeting details including notes are returned.

**FR-MTG-3.5** Attendance Summary
- **Given** a user with meeting history,
  **When** they request attendance summary with a period (`week`, `month`),
  **Then** the system returns total count, count by type, and the period's date range.

### FR-MTG-4: Update and Delete Meeting Logs

**FR-MTG-4.1** Update Meeting Log
- **Given** an existing meeting log,
  **When** the user sends a PATCH with updated fields (name, location, duration, notes, meetingType),
  **Then** the allowed fields are updated, `modifiedAt` is refreshed, and the timestamp remains immutable.

**FR-MTG-4.2** Mark as Canceled
- **Given** a meeting that was scheduled but canceled,
  **When** the user marks it as `status: canceled`,
  **Then** the meeting log is preserved with a `canceled` status. Commitment streak impact is configurable per user preference.

**FR-MTG-4.3** Delete Meeting Log
- **Given** an existing meeting log,
  **When** the user deletes it,
  **Then** both the meeting log and its calendar activity dual-write entry are removed. Returns `204 No Content`.

### FR-MTG-5: Integration Points

**FR-MTG-5.1** Calendar Activity Dual-Write
- **Given** a meeting log is created,
  **When** the write succeeds,
  **Then** a corresponding `CALENDAR_ACTIVITY` entry with `activityType: MEETING` is written to the calendar activities collection.

**FR-MTG-5.2** Commitment Tracking Feed
- **Given** a user has a commitment "attend X meetings per week",
  **When** a meeting is logged,
  **Then** an event is published to the commitments tracking system to update progress.

**FR-MTG-5.3** Support Network Visibility
- **Given** a sponsor/counselor/coach has been granted `meetings` permission,
  **When** they request the user's meeting logs,
  **Then** they see the logs. Without explicit permission, they receive a `404 Not Found`.

**FR-MTG-5.4** Analytics Correlation
- **Given** meeting attendance data exists,
  **When** the analytics dashboard computes correlations,
  **Then** meeting attendance feeds into Recovery Health Score's `meetingAttendance` component.

### FR-MTG-6: Notifications

**FR-MTG-6.1** Pre-Meeting Reminder
- **Given** a user has a saved meeting with a scheduled day/time and reminders enabled,
  **When** the reminder time arrives (configurable: 15, 30, 60 min before),
  **Then** a push notification is sent reminding the user of the meeting.

**FR-MTG-6.2** Post-Meeting Logging Prompt
- **Given** a user had a saved meeting scheduled for today and has not logged it,
  **When** 1 hour after the scheduled meeting end time passes,
  **Then** a push notification is sent: "You had a meeting scheduled today. Would you like to log it?"

### FR-MTG-7: Offline Support

**FR-MTG-7.1** Offline Creation
- **Given** the user is offline,
  **When** they log a meeting,
  **Then** the entry is saved to local storage and queued for sync.

**FR-MTG-7.2** Sync on Reconnect
- **Given** the user has offline-queued meeting logs,
  **When** connectivity is restored,
  **Then** entries are synced to the server in chronological order. Conflicts use union merge (both versions kept).

---

## Non-Functional Requirements

**NFR-MTG-1** Meeting log creation responds within 300ms (P95) under normal load.

**NFR-MTG-2** Meeting list queries with date range filters respond within 500ms (P95) for users with up to 1,000 meeting logs.

**NFR-MTG-3** All meeting data is scoped by `userId` and `tenantId`. Tenant isolation is enforced at the API layer.

**NFR-MTG-4** Meeting notes support up to 2,000 characters of free text. No analytics are performed on meeting note content (privacy by architecture).

**NFR-MTG-5** The `activity.meetings` feature flag controls availability. When disabled, all meeting endpoints return `404 Not Found`.
