# Prayer Activity -- Acceptance Criteria

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft
**Source:** `docs/prd/specific-features/Prayer/Prayer_Activity.md`

---

## Naming Convention

Each acceptance criterion has a unique ID in the format `PR-AC{section}.{number}` where:
- `PR` = Prayer Activity domain
- `AC` = Acceptance Criterion
- Section numbers map to PRD sections

---

## 1. Prayer Session Logging

### PR-AC1.1 -- Manual Entry: Required Fields

**Given** a user opens the prayer session log form,
**When** they submit an entry with a valid `prayerType` and `timestamp`,
**Then** the session is recorded successfully with `prayerId` assigned, `createdAt` set immutably, and the entry appears in prayer history.

### PR-AC1.2 -- Manual Entry: Prayer Type Enum Validation

**Given** a user submits a prayer session,
**When** the `prayerType` is not one of `personal`, `guided`, `group`, `scriptureBased`, `intercessory`, `listening`,
**Then** the API returns `422 Unprocessable Entity` with error code `rr:0x00500001`.

### PR-AC1.3 -- Manual Entry: Optional Duration

**Given** a user submits a prayer session without a `durationMinutes` value,
**When** the session is saved,
**Then** the session is recorded as valid with `durationMinutes` set to `null` -- duration is never required.

### PR-AC1.4 -- Manual Entry: Notes Character Limit

**Given** a user submits a prayer session with `notes` exceeding 1000 characters,
**When** the API validates the request,
**Then** the API returns `422 Unprocessable Entity` with error pointing to `/data/notes`.

### PR-AC1.5 -- Manual Entry: Linked Prayer Reference

**Given** a user submits a prayer session with `linkedPrayerId` referencing a prayer from the library,
**When** the session is saved,
**Then** the linked prayer ID is stored and the linked prayer title is returned in the response.

### PR-AC1.6 -- Manual Entry: Linked Prayer Validation

**Given** a user submits a prayer session with `linkedPrayerId` referencing a prayer they do not own (locked premium),
**When** the API validates the request,
**Then** the API returns `422 Unprocessable Entity` with error code `rr:0x00500002`.

### PR-AC1.7 -- Manual Entry: Mood Before/After

**Given** a user submits a prayer session with `moodBefore` and `moodAfter` values,
**When** the values are integers between 1 and 5 inclusive,
**Then** both values are stored and returned in the response.

### PR-AC1.8 -- Manual Entry: Mood Out of Range

**Given** a user submits a prayer session with `moodBefore` or `moodAfter` outside the range 1-5,
**When** the API validates the request,
**Then** the API returns `422 Unprocessable Entity`.

### PR-AC1.9 -- Manual Entry: Backdating

**Given** a user submits a prayer session with a `timestamp` in the past (within 7 days),
**When** the session is saved,
**Then** the session `timestamp` is set to the provided value and `createdAt` is set to the current server time (both immutable after creation).

### PR-AC1.10 -- Manual Entry: Timestamp Immutability

**Given** a user attempts to update the `timestamp` on a saved prayer session,
**When** the PATCH request includes a `timestamp` field,
**Then** the API returns `422 Unprocessable Entity` with detail "timestamp is immutable" per FR2.7.

### PR-AC1.11 -- Quick Log: One-Tap Creation

**Given** a user taps the quick log button from the dashboard widget,
**When** the quick log request is submitted,
**Then** a prayer session is created with `prayerType` defaulting to `personal`, `timestamp` set to now, and all other fields null.

### PR-AC1.12 -- Quick Log: Expand After Creation

**Given** a user has created a quick log prayer session,
**When** they expand the entry within 24 hours,
**Then** they can PATCH `durationMinutes`, `notes`, `moodBefore`, `moodAfter`, and `linkedPrayerId` onto the existing session.

### PR-AC1.13 -- Notes Edit Window

**Given** a user attempts to edit prayer session notes more than 24 hours after creation,
**When** the PATCH request is submitted,
**Then** the API returns `422 Unprocessable Entity` with detail "notes are read-only after 24 hours".

---

## 2. Prayer Content Library

### PR-AC2.1 -- List Library Prayers with Pagination

**Given** a user requests the prayer library,
**When** the GET request is made to `/content/prayers`,
**Then** prayers are returned with cursor-based pagination, each including `title`, `body`, `topicTags`, `sourceAttribution`, and `scriptureConnection`.

### PR-AC2.2 -- Filter by Topic Tag

**Given** a user requests prayers filtered by topic tag (e.g., `temptation`),
**When** the GET request includes `topic=temptation`,
**Then** only prayers tagged with `temptation` are returned.

### PR-AC2.3 -- Filter by Pack

**Given** a user requests prayers filtered by pack ID,
**When** the GET request includes `pack=pack_temptation`,
**Then** only prayers from that pack are returned.

### PR-AC2.4 -- Filter by Step Number

**Given** a user requests step-specific prayers,
**When** the GET request includes `step=4`,
**Then** only the Step 4 prayer is returned.

### PR-AC2.5 -- Full-Text Search

**Given** a user searches the prayer library with a keyword query,
**When** the GET request includes `search=strength`,
**Then** prayers whose `title` or `body` contain the keyword are returned, ranked by relevance.

### PR-AC2.6 -- Locked Content Indicator

**Given** a user views prayers from a premium pack they have not purchased,
**When** the library response is returned,
**Then** each locked prayer includes `isLocked: true` and the prayer body is truncated or omitted.

### PR-AC2.7 -- Today's Prayer

**Given** a user requests today's featured prayer,
**When** the GET request is made to `/content/prayers/today`,
**Then** a prayer is returned that rotates daily, drawn from the user's owned packs, consistent for the entire day in the user's timezone.

### PR-AC2.8 -- Freemium Prayers Always Available

**Given** a user with no premium purchases,
**When** they browse the prayer library,
**Then** all freemium prayers (step prayers, Serenity Prayer, Lord's Prayer, recovery-focused prayers, daily morning/evening prayers) are accessible with `isLocked: false`.

---

## 3. Personal Prayers (User-Created)

### PR-AC3.1 -- Create Personal Prayer

**Given** a user submits a new personal prayer with `title` (required, max 100 chars) and `body` (required),
**When** the POST request is made to `/content/prayers/personal`,
**Then** the prayer is created with a unique ID and stored in the user's personal prayer collection.

### PR-AC3.2 -- Title Length Validation

**Given** a user submits a personal prayer with a `title` exceeding 100 characters,
**When** the API validates the request,
**Then** the API returns `422 Unprocessable Entity`.

### PR-AC3.3 -- List Personal Prayers

**Given** a user requests their personal prayers,
**When** the GET request is made to `/content/prayers/personal`,
**Then** all personal prayers are returned sorted by creation date (newest first) with cursor-based pagination.

### PR-AC3.4 -- Update Personal Prayer

**Given** a user updates their personal prayer's `title`, `body`, `topicTags`, or `scriptureReference`,
**When** the PATCH request is submitted,
**Then** the prayer is updated and `modifiedAt` is refreshed.

### PR-AC3.5 -- Delete Personal Prayer

**Given** a user deletes a personal prayer,
**When** the DELETE request is submitted,
**Then** the prayer is permanently removed and any prayer sessions linked to it retain the `linkedPrayerId` but show "[Deleted Prayer]" for the title.

### PR-AC3.6 -- Reorder Personal Prayers

**Given** a user reorders their personal prayers,
**When** the PUT request is made to `/content/prayers/personal/order` with the new sort order,
**Then** the personal prayers are displayed in the specified order.

---

## 4. Favorites

### PR-AC4.1 -- Favorite a Prayer

**Given** a user favorites a library prayer or personal prayer,
**When** the POST request is made to `/content/prayers/favorites/{id}`,
**Then** the prayer is added to favorites and `isFavorite: true` is reflected in subsequent queries.

### PR-AC4.2 -- Unfavorite a Prayer

**Given** a user unfavorites a prayer,
**When** the DELETE request is made to `/content/prayers/favorites/{id}`,
**Then** the prayer is removed from favorites.

### PR-AC4.3 -- List Favorites

**Given** a user requests their favorited prayers,
**When** the GET request is made to `/content/prayers/favorites`,
**Then** all favorited prayers are returned with cursor-based pagination.

### PR-AC4.4 -- Favorite Premium Prayer Persistence

**Given** a user has favorited a prayer from a purchased premium pack,
**When** the user's subscription status changes (irrelevant -- packs are unlocked forever),
**Then** the favorited prayer remains accessible because content packs are permanent purchases.

---

## 5. Prayer Streak and Trends

### PR-AC5.1 -- Prayer Streak Calculation

**Given** a user has logged at least one prayer session on each of the last N consecutive days,
**When** they request the prayer streak,
**Then** the API returns `currentStreakDays: N`.

### PR-AC5.2 -- Multiple Sessions Same Day

**Given** a user logs multiple prayer sessions in one day,
**When** the streak is calculated,
**Then** all sessions count as one day for streak purposes.

### PR-AC5.3 -- Longest Streak Tracking

**Given** a user's current streak exceeds their previous longest streak,
**When** the streak is recalculated,
**Then** `longestStreakDays` is updated to match the current streak.

### PR-AC5.4 -- Streak Break Compassion

**Given** a user's prayer streak breaks (no session logged yesterday),
**When** they open the prayer screen,
**Then** a compassionate message is displayed: "Every conversation with God is a fresh start. Welcome back."

### PR-AC5.5 -- Prayer Stats Summary

**Given** a user requests prayer trends,
**When** the GET request is made to `/activities/prayer/stats`,
**Then** the response includes `currentStreakDays`, `longestStreakDays`, `totalPrayerDays`, `sessionsThisWeek`, `averageDurationMinutes`, and `typeDistribution`.

### PR-AC5.6 -- Prayer Type Distribution

**Given** a user requests prayer statistics,
**When** the stats are calculated,
**Then** `typeDistribution` contains a count per prayer type (personal, guided, group, scriptureBased, intercessory, listening).

---

## 6. Prayer History

### PR-AC6.1 -- List Prayer History

**Given** a user requests prayer history,
**When** the GET request is made to `/activities/prayer`,
**Then** sessions are returned in reverse chronological order with `prayerId`, `prayerType`, `timestamp`, `durationMinutes`, `linkedPrayerTitle`, `moodBefore`, `moodAfter`.

### PR-AC6.2 -- Filter by Prayer Type

**Given** a user filters prayer history by type,
**When** the GET request includes `prayerType=guided`,
**Then** only guided prayer sessions are returned.

### PR-AC6.3 -- Filter by Date Range

**Given** a user filters prayer history by date range,
**When** the GET request includes `startDate` and `endDate`,
**Then** only sessions within that range (inclusive) are returned.

### PR-AC6.4 -- Get Single Prayer Session

**Given** a user requests a specific prayer session by ID,
**When** the GET request is made to `/activities/prayer/{id}`,
**Then** the full session detail is returned including notes.

---

## 7. Feature Flag Gating

### PR-AC7.1 -- Feature Flag Controls Access

**Given** the feature flag `activity.prayer` is disabled,
**When** a user attempts any prayer endpoint,
**Then** the API returns `404 Not Found` (feature hidden, not forbidden).

### PR-AC7.2 -- Feature Flag Fail Closed

**Given** the feature flag system is unavailable,
**When** a user attempts any prayer endpoint,
**Then** the API returns `404 Not Found` (fail closed per project convention).

---

## 8. Offline Support

### PR-AC8.1 -- Offline Prayer Logging

**Given** the user is offline,
**When** they log a prayer session,
**Then** the session is stored locally and synced when connection is restored.

### PR-AC8.2 -- Offline Library Browsing

**Given** the user is offline,
**When** they browse the prayer library,
**Then** cached library prayers (including owned packs) are available for reading.

### PR-AC8.3 -- Offline Conflict Resolution

**Given** prayer sessions were logged on multiple devices while offline,
**When** both devices sync,
**Then** all sessions are union-merged (no prayer session is lost).

---

## 9. Community Permissions

### PR-AC9.1 -- Prayer Visibility to Support Network

**Given** a user has granted their spouse permission to view prayer data,
**When** the spouse requests the user's prayer streak,
**Then** the prayer streak data is returned.

### PR-AC9.2 -- No Default Prayer Access

**Given** a user has NOT granted a contact permission to view prayer data,
**When** the contact attempts to view the user's prayer data,
**Then** the API returns `404 Not Found` (hide existence, per project convention).

---

## 10. Calendar Activity Integration

### PR-AC10.1 -- Calendar Dual-Write

**Given** a prayer session is logged,
**When** the session is persisted,
**Then** a corresponding `CALENDAR_ACTIVITY` entry is written with `activityType: PRAYER` and a summary containing `prayerType` and `durationMinutes`.

---

## 11. Notifications

### PR-AC11.1 -- Daily Prayer Reminder

**Given** a user has enabled the daily prayer reminder at a configured time,
**When** the configured time arrives,
**Then** a push notification is sent with the configured message.

### PR-AC11.2 -- Missed Prayer Nudge

**Given** a user has not logged a prayer session for N days (where N is their configured inactivity threshold, default 3),
**When** the nudge check runs,
**Then** a compassionate nudge notification is sent.

### PR-AC11.3 -- Streak Milestone Notification

**Given** a user reaches a prayer streak milestone (7, 14, 30, 60, 90 days),
**When** the milestone is detected,
**Then** a celebration notification is sent.
