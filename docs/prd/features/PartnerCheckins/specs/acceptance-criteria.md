# Person Check-ins -- Acceptance Criteria

**Activity:** Person Check-ins
**Priority:** P1 (Wave 2)
**Feature Flag:** `activity.person-check-ins`

---

## Terminology

- **Sub-type:** One of `spouse`, `sponsor`, `counselor-coach`
- **Method:** One of `in-person`, `phone-call`, `video-call`, `text-message`, `app-messaging`
- **Streak frequency:** `daily`, `x-per-week`, `weekly` (configurable per sub-type)

---

## FR-PCI: Functional Requirements

### FR-PCI-1: Check-in Logging

| ID | Criterion |
|----|-----------|
| FR-PCI-1.1 | **Given** a user opens the Person Check-in form, **When** they select a sub-type and method and submit, **Then** a check-in entry is created with an immutable `createdAt` timestamp and the entry is persisted. |
| FR-PCI-1.2 | **Given** a user submits a check-in, **When** the `checkInType` field is missing or not one of `spouse`, `sponsor`, `counselor-coach`, **Then** the API returns 422 with a validation error. |
| FR-PCI-1.3 | **Given** a user submits a check-in, **When** the `method` field is missing or not one of the valid enum values, **Then** the API returns 422. |
| FR-PCI-1.4 | **Given** a user provides a `contactName`, **When** the name exceeds 50 characters, **Then** the API returns 422. |
| FR-PCI-1.5 | **Given** a user provides `notes`, **When** the notes exceed 1000 characters, **Then** the API returns 422. |
| FR-PCI-1.6 | **Given** a user provides a `qualityRating`, **When** the value is outside 1-5, **Then** the API returns 422. |
| FR-PCI-1.7 | **Given** a user provides `topicsDiscussed`, **When** any topic is not in the allowed set, **Then** the API returns 422. |
| FR-PCI-1.8 | **Given** a user provides `followUpItems`, **When** there are more than 3 items or any item exceeds 200 characters, **Then** the API returns 422. |
| FR-PCI-1.9 | **Given** a user provides a `durationMinutes`, **When** the value is less than 0 or greater than 480, **Then** the API returns 422. |
| FR-PCI-1.10 | **Given** a user provides a `timestamp` in the past (backdating), **When** the check-in is submitted, **Then** the check-in is created with the provided timestamp and streaks are recalculated to include the backdated entry. |
| FR-PCI-1.11 | **Given** a user creates a check-in, **When** `contactName` is not provided but a previous check-in of the same sub-type exists with a `contactName`, **Then** the response includes the previously saved `contactName` as a suggestion. |

### FR-PCI-2: Quick Log

| ID | Criterion |
|----|-----------|
| FR-PCI-2.1 | **Given** a user triggers a quick log, **When** they provide only `checkInType`, **Then** a check-in is created with `method` defaulting to the last-used method for that sub-type, `timestamp` set to now, and all optional fields omitted. |
| FR-PCI-2.2 | **Given** a user created a quick-log entry, **When** they later update the entry with `qualityRating`, `topicsDiscussed`, `notes`, or `followUpItems`, **Then** the entry is updated (PATCH) and `modifiedAt` is updated while `createdAt` remains immutable. |

### FR-PCI-3: Check-in History

| ID | Criterion |
|----|-----------|
| FR-PCI-3.1 | **Given** a user requests their check-in history, **When** no filter is applied, **Then** all check-ins are returned in reverse chronological order with cursor-based pagination. |
| FR-PCI-3.2 | **Given** a user filters by `checkInType=spouse`, **When** the request is processed, **Then** only spouse check-ins are returned. |
| FR-PCI-3.3 | **Given** a user filters by `method=in-person`, **When** the request is processed, **Then** only in-person check-ins are returned. |
| FR-PCI-3.4 | **Given** a user filters by `qualityRating=4`, **When** the request is processed, **Then** only check-ins with quality rating >= 4 are returned. |
| FR-PCI-3.5 | **Given** a user provides `startDate` and `endDate`, **When** the request is processed, **Then** only check-ins within the date range are returned. |
| FR-PCI-3.6 | **Given** a user searches by `q=keyword`, **When** the keyword matches text in `notes` or `followUpItems`, **Then** matching check-ins are returned. |
| FR-PCI-3.7 | **Given** a user requests a single check-in by ID, **When** the check-in exists and belongs to the user, **Then** the full check-in detail is returned including topics, notes, and follow-up items. |
| FR-PCI-3.8 | **Given** a user requests a check-in by ID, **When** the check-in does not exist or belongs to another user, **Then** the API returns 404. |

### FR-PCI-4: Streaks & Frequency

| ID | Criterion |
|----|-----------|
| FR-PCI-4.1 | **Given** a user logs a spouse check-in every day for 7 consecutive days with streak frequency set to `daily`, **When** they request their streaks, **Then** the spouse streak shows `currentStreak: 7`. |
| FR-PCI-4.2 | **Given** a user has a sponsor streak frequency of `weekly` and logs at least one sponsor check-in every calendar week for 4 weeks, **When** they request streaks, **Then** the sponsor streak shows `currentStreak: 4`. |
| FR-PCI-4.3 | **Given** a user has a `daily` spouse streak of 5 and misses a day, **When** they request streaks the day after the gap, **Then** the spouse streak resets to 0 and `longestStreak` is preserved at 5 (or higher). |
| FR-PCI-4.4 | **Given** a user logs multiple check-ins with the same sub-type on the same day, **When** streaks are calculated, **Then** only one day is counted for streak purposes. |
| FR-PCI-4.5 | **Given** a user backdates a check-in to fill a gap in their streak, **When** streaks are recalculated, **Then** the streak includes the backdated entry and the gap is filled. |
| FR-PCI-4.6 | **Given** a user configures streak frequency for sponsor to `x-per-week` with `requiredCount: 3`, **When** they log 3 sponsor check-ins in a rolling 7-day window, **Then** the streak increments by 1 week. |
| FR-PCI-4.7 | **Given** a user requests the frequency dashboard, **When** data is returned, **Then** it includes per-sub-type: `currentStreak`, `longestStreak`, `checkInsThisWeek`, `checkInsThisMonth`, and `averagePerWeek` (30-day rolling). |

### FR-PCI-5: Streak Configuration

| ID | Criterion |
|----|-----------|
| FR-PCI-5.1 | **Given** a user updates their streak frequency for a sub-type, **When** the new frequency is saved, **Then** streaks are recalculated from scratch using the new frequency. |
| FR-PCI-5.2 | **Given** a user sets counselor-coach streak frequency to `weekly` (default), **When** they log at least one counselor check-in per calendar week, **Then** the counselor streak increments. |

### FR-PCI-6: Calendar View

| ID | Criterion |
|----|-----------|
| FR-PCI-6.1 | **Given** a user requests the calendar view for a month, **When** the data is returned, **Then** each day shows color-coded indicators by sub-type (spouse, sponsor, counselor-coach). |
| FR-PCI-6.2 | **Given** a user has multiple sub-type check-ins on the same day, **When** the calendar day is returned, **Then** multiple sub-type indicators are present. |

### FR-PCI-7: Follow-up Items

| ID | Criterion |
|----|-----------|
| FR-PCI-7.1 | **Given** a user adds follow-up items to a check-in, **When** the check-in is saved, **Then** follow-up items are stored with the check-in and retrievable. |
| FR-PCI-7.2 | **Given** a follow-up item exists, **When** the user converts it to a goal, **Then** a goal entity is created via the Goals API and a `goalId` is linked back to the follow-up item. |

### FR-PCI-8: Trends & Insights

| ID | Criterion |
|----|-----------|
| FR-PCI-8.1 | **Given** a user requests frequency trends, **When** the period is specified (7, 30, or 90 days), **Then** a per-sub-type frequency series is returned. |
| FR-PCI-8.2 | **Given** a user requests method distribution, **When** the data is returned, **Then** a per-sub-type breakdown of method counts is provided. |
| FR-PCI-8.3 | **Given** a user requests quality trends, **When** check-ins have quality ratings, **Then** the average quality per sub-type per period is returned. |
| FR-PCI-8.4 | **Given** a user requests topic trends, **When** the data is returned, **Then** topic frequency counts across all check-ins and per sub-type are provided. |
| FR-PCI-8.5 | **Given** a user requests balance analysis, **When** data exists for multiple sub-types, **Then** a comparison of check-in frequency across sub-types is returned with gap detection. |

### FR-PCI-9: Inactivity Alerts

| ID | Criterion |
|----|-----------|
| FR-PCI-9.1 | **Given** a user has no spouse check-in for 3+ days, **When** the inactivity check runs, **Then** a notification is created with the configured alert message and a quick-log action. |
| FR-PCI-9.2 | **Given** a user has no sponsor check-in for 5+ days, **When** the inactivity check runs, **Then** a notification is created. |
| FR-PCI-9.3 | **Given** a user has no counselor check-in for 10+ days (between sessions), **When** the inactivity check runs, **Then** a notification is created. |
| FR-PCI-9.4 | **Given** a user has not configured a contact for a sub-type, **When** the inactivity check runs, **Then** no alert is generated for that sub-type. |
| FR-PCI-9.5 | **Given** inactivity alert thresholds are configurable, **When** the user updates the threshold for a sub-type, **Then** subsequent alerts use the new threshold. |

### FR-PCI-10: Permissions & Visibility

| ID | Criterion |
|----|-----------|
| FR-PCI-10.1 | **Given** a user has granted their spouse permission to view `person-check-ins`, **When** the spouse requests the user's person check-in data, **Then** only spouse-sub-type check-ins are returned (not sponsor or counselor data). |
| FR-PCI-10.2 | **Given** a sponsor has permission to view `person-check-ins`, **When** the sponsor requests data, **Then** check-ins across all sub-types are returned (per community permissions: sponsor sees all except journal and financial). |
| FR-PCI-10.3 | **Given** no permission has been granted, **When** any support contact requests person check-in data, **Then** the API returns 404 (not 403). |

### FR-PCI-11: Cross-Activity Linking

| ID | Criterion |
|----|-----------|
| FR-PCI-11.1 | **Given** a user logged a phone call with their sponsor, **When** the phone call is saved, **Then** a cross-reference prompt is returned suggesting the user also log a person check-in. |
| FR-PCI-11.2 | **Given** a user completed FANOS/FITNAP spouse check-in preparation, **When** the preparation is saved, **Then** a cross-reference prompt is returned suggesting logging a spouse person check-in. |

### FR-PCI-12: Offline Support

| ID | Criterion |
|----|-----------|
| FR-PCI-12.1 | **Given** the user is offline, **When** they log a person check-in, **Then** the check-in is stored locally and synced when connectivity is restored. |
| FR-PCI-12.2 | **Given** multiple check-ins were created offline, **When** sync occurs, **Then** all check-ins are uploaded in chronological order and streaks are recalculated server-side. |

---

## NFR-PCI: Non-Functional Requirements

| ID | Criterion |
|----|-----------|
| NFR-PCI-1 | **Given** any person check-in is created, **When** `createdAt` is set, **Then** it is immutable and cannot be modified by any subsequent update (FR2.7). |
| NFR-PCI-2 | **Given** a list endpoint is called, **When** results exceed the default limit, **Then** cursor-based pagination is used. |
| NFR-PCI-3 | **Given** a check-in is created, **When** the response is returned, **Then** it includes `links.self` and conforms to the Siemens response envelope (`data`, `links`, `meta`). |
| NFR-PCI-4 | **Given** the `activity.person-check-ins` feature flag is disabled, **When** any person check-in endpoint is called, **Then** the API returns 404 as if the resource does not exist. |
| NFR-PCI-5 | **Given** a person check-in is created, **When** the calendar activity collection is queried for that day, **Then** a `PERSON_CHECKIN` entry appears (dual-write). |
| NFR-PCI-6 | **Given** streak data for person check-ins, **When** the data is read, **Then** it is served from Valkey cache with a 5-minute TTL. |
