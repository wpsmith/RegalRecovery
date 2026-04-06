# Time Journal -- MongoDB Schema Design

**Version:** 1.0.0
**Date:** 2026-04-03
**Status:** Draft
**Parent:** [schema-design.md](./schema-design.md) (Section 4.18)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Collections](#2-collections)
3. [Indexes](#3-indexes)
4. [Access Pattern Reference](#4-access-pattern-reference)
5. [Document Size Estimates](#5-document-size-estimates)
6. [Operational Considerations](#6-operational-considerations)

---

## 1. Overview

The Time Journal (T-30/T-60) is a structured, interval-based journaling tool used in sexual addiction recovery. Users document their day in 30- or 60-minute increments, recording time, location, activity, people present, and emotional state. This schema extends the main Regal Recovery MongoDB schema to support the full Time Journal feature set defined in the [Time Journal PRD](../../prd/specific-features/TimeJournal/prd.md).

**Design decisions:**

- **Two collections** — `timeJournalEntries` stores individual slot entries; `timeJournalDays` stores materialized daily aggregates. The daily aggregate is a denormalized view maintained by the application on each entry write, enabling efficient heatmap, streak, and status engine queries without scanning all entries.
- **Separate from main single-table** — Time Journal entries are high-volume (up to 48 per user per day in T-30 mode) and have unique access patterns (slot-based lookups, daily completion scoring, partner sharing). A dedicated collection avoids bloating the main table and allows purpose-built indexes.
- **Calendar activity dual-write** — Each Time Journal entry also writes a summary to the `calendarActivities` collection per Section 3.3 of the main schema.

**Common fields** — All documents in both collections carry the standard fields defined in the main schema: `_id` (ObjectId), `userId` (String), `entityType` (String), `createdAt` (Date), `modifiedAt` (Date), `tenantId` (String).

---

## 2. Collections

### 2.1 timeJournalEntries

**Description:** Individual time slot entries. Each document represents one 30- or 60-minute interval in a user's day.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | Yes | MongoDB document ID |
| `entryId` | String | Yes | Application-level ID with `tj_` prefix (e.g., `tj_77777`) |
| `userId` | String | Yes | Owner user ID |
| `tenantId` | String | Yes | Tenant identifier. Default: `DEFAULT` |
| `entityType` | String | Yes | Always `TIME_JOURNAL_ENTRY` |
| `date` | String | Yes | Calendar date in `YYYY-MM-DD` format (user's local timezone) |
| `slotStart` | Date | Yes | ISO 8601 datetime marking the start of this time slot |
| `slotEnd` | Date | Yes | ISO 8601 datetime marking the end of this time slot |
| `mode` | String | Yes | `t30` (48 slots/day) or `t60` (24 slots/day) |
| `location` | String | No | Free-text or quick-select location (e.g., `@home`, `@work`) |
| `gpsLatitude` | Double | No | Latitude coordinate captured automatically |
| `gpsLongitude` | Double | No | Longitude coordinate captured automatically |
| `gpsAddress` | String | No | Reverse-geocoded address from Apple POI / Google Maps |
| `gpsErrorRange` | Double | No | GPS accuracy in meters |
| `activity` | String | No | Free-text description of what the user was doing |
| `people` | Array | No | Array of `{ name: String, gender: String }` objects |
| `emotions` | Array | No | Array of `{ name: String, intensity: Number (1-10), why: String }` objects |
| `extras` | Object | No | Optional structured fields: financial transactions, screen-time events, notable interactions (TJ-006) |
| `sleepFlag` | Boolean | No | `true` if this slot is marked as sleeping (TJ-008). Default: `false` |
| `isRetroactive` | Boolean | No | `true` if entry was filled after the slot's time period elapsed (TJ-011). Default: `false` |
| `retroactiveTimestamp` | Date | No | When the retroactive entry was actually created. Present only when `isRetroactive` is `true` |
| `isAutoFilled` | Boolean | No | `true` if entry was auto-generated (e.g., Sleep Focus detection). Default: `false` |
| `autoFillSource` | String | No | Source of auto-fill (e.g., `sleep-focus-ios`, `bedtime-android`). Present only when `isAutoFilled` is `true` |
| `redlineNote` | String | No | Confidential note NOT shared with Trust Partners (TJ-048). Encrypted at application layer |
| `createdAt` | Date | Yes | Immutable. Set at write time, never changed (FR2.7) |
| `modifiedAt` | Date | Yes | Updated on every write |

**Example Document:**

```json
{
  "_id": ObjectId("6625a1b2c3d4e5f6a7b8c9d0"),
  "entryId": "tj_77777",
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "entityType": "TIME_JOURNAL_ENTRY",
  "date": "2026-03-28",
  "slotStart": ISODate("2026-03-28T14:00:00Z"),
  "slotEnd": ISODate("2026-03-28T14:59:59Z"),
  "mode": "t60",
  "location": "@work",
  "gpsLatitude": 40.7128,
  "gpsLongitude": -74.0060,
  "gpsAddress": "350 5th Ave, Midtown, NYC",
  "gpsErrorRange": 15.2,
  "activity": "Working on project report",
  "people": [
    { "name": "Dave", "gender": "male" },
    { "name": "Sarah", "gender": "female" }
  ],
  "emotions": [
    { "name": "focused", "intensity": 6, "why": null },
    { "name": "anxious", "intensity": 3, "why": "Upcoming deadline" }
  ],
  "extras": null,
  "sleepFlag": false,
  "isRetroactive": false,
  "retroactiveTimestamp": null,
  "isAutoFilled": false,
  "autoFillSource": null,
  "redlineNote": null,
  "createdAt": ISODate("2026-03-28T14:02:15Z"),
  "modifiedAt": ISODate("2026-03-28T14:02:15Z")
}
```

**Retroactive Entry Example:**

```json
{
  "_id": ObjectId("6625a1b2c3d4e5f6a7b8c9d1"),
  "entryId": "tj_77778",
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "entityType": "TIME_JOURNAL_ENTRY",
  "date": "2026-03-28",
  "slotStart": ISODate("2026-03-28T10:00:00Z"),
  "slotEnd": ISODate("2026-03-28T10:59:59Z"),
  "mode": "t60",
  "location": "@gym",
  "gpsLatitude": 40.7580,
  "gpsLongitude": -73.9855,
  "gpsAddress": "Planet Fitness, Midtown East, NYC",
  "gpsErrorRange": 8.5,
  "activity": "Morning workout — cardio and weights",
  "people": [],
  "emotions": [
    { "name": "energized", "intensity": 7, "why": null }
  ],
  "extras": null,
  "sleepFlag": false,
  "isRetroactive": true,
  "retroactiveTimestamp": ISODate("2026-03-28T14:30:00Z"),
  "isAutoFilled": false,
  "autoFillSource": null,
  "redlineNote": null,
  "createdAt": ISODate("2026-03-28T14:30:00Z"),
  "modifiedAt": ISODate("2026-03-28T14:30:00Z")
}
```

**Auto-Filled Sleep Entry Example:**

```json
{
  "_id": ObjectId("6625a1b2c3d4e5f6a7b8c9d2"),
  "entryId": "tj_77779",
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "entityType": "TIME_JOURNAL_ENTRY",
  "date": "2026-03-28",
  "slotStart": ISODate("2026-03-28T01:00:00Z"),
  "slotEnd": ISODate("2026-03-28T01:59:59Z"),
  "mode": "t60",
  "location": "@home",
  "gpsLatitude": null,
  "gpsLongitude": null,
  "gpsAddress": null,
  "gpsErrorRange": null,
  "activity": "Sleep",
  "people": [],
  "emotions": [],
  "extras": null,
  "sleepFlag": true,
  "isRetroactive": false,
  "retroactiveTimestamp": null,
  "isAutoFilled": true,
  "autoFillSource": "sleep-focus-ios",
  "redlineNote": null,
  "createdAt": ISODate("2026-03-28T06:15:00Z"),
  "modifiedAt": ISODate("2026-03-28T06:15:00Z")
}
```

**Also written to the calendarActivities collection (dual-write):**

```json
{
  "PK": "USER#u_12345",
  "SK": "ACTIVITY#2026-03-28#TIMEJOURNAL#2026-03-28T14:00:00Z",
  "EntityType": "CALENDAR_ACTIVITY",
  "activityType": "TIMEJOURNAL",
  "summary": { "slotStart": "14:00", "slotEnd": "15:00", "activity": "Working on project report", "emotion": "focused" },
  "sourceKey": "TIMEJOURNAL#2026-03-28T14:00:00Z"
}
```

---

### 2.2 timeJournalDays

**Description:** Daily aggregated view (materialized). One document per user per day, maintained by the application layer on each entry write. Powers the status engine (TJ-060 through TJ-064), heatmap (TJ-032), streak counter (TJ-030), and completion score (TJ-031).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | Yes | MongoDB document ID |
| `dayId` | String | Yes | Application-level ID with `tjd_` prefix (e.g., `tjd_88888`) |
| `userId` | String | Yes | Owner user ID |
| `tenantId` | String | Yes | Tenant identifier. Default: `DEFAULT` |
| `entityType` | String | Yes | Always `TIME_JOURNAL_DAY` |
| `date` | String | Yes | Calendar date in `YYYY-MM-DD` format |
| `mode` | String | Yes | `t30` or `t60` — the mode active on this day |
| `totalSlots` | Number | Yes | Total slots for the day (48 for T-30, 24 for T-60) |
| `filledSlots` | Number | Yes | Number of slots with entries |
| `completionPercent` | Number | Yes | `(filledSlots / totalSlots) * 100`, rounded to nearest integer |
| `status` | String | Yes | One of: `inProgress`, `overdue`, `completed`. Derived from status engine (TJ-060 through TJ-064) |
| `overdueSlotCount` | Number | Yes | Number of elapsed but unfilled slots. `0` when status is `completed` |
| `retroactiveCount` | Number | Yes | Number of entries marked as retroactive |
| `autoFilledCount` | Number | Yes | Number of entries auto-filled (e.g., sleep detection) |
| `lastEntryAt` | Date | No | Timestamp of the most recent entry saved for this day |
| `streakEligible` | Boolean | Yes | `true` if `completionPercent >= 80` (TJ-030 threshold) |
| `emotionSummary` | Object | No | Aggregated emotion data: `{ topEmotions: [{ name, count, avgIntensity }], peakIntensityTime: Date, peakIntensityEmotion: String }` |
| `createdAt` | Date | Yes | Immutable. Set when the first entry for this day is saved |
| `modifiedAt` | Date | Yes | Updated on every entry write for this day |

**Example Document:**

```json
{
  "_id": ObjectId("6625b2c3d4e5f6a7b8c9d0e1"),
  "dayId": "tjd_88888",
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "entityType": "TIME_JOURNAL_DAY",
  "date": "2026-03-28",
  "mode": "t60",
  "totalSlots": 24,
  "filledSlots": 18,
  "completionPercent": 75,
  "status": "inProgress",
  "overdueSlotCount": 2,
  "retroactiveCount": 3,
  "autoFilledCount": 7,
  "lastEntryAt": ISODate("2026-03-28T18:05:00Z"),
  "streakEligible": false,
  "emotionSummary": {
    "topEmotions": [
      { "name": "focused", "count": 5, "avgIntensity": 6.2 },
      { "name": "anxious", "count": 3, "avgIntensity": 4.7 },
      { "name": "grateful", "count": 2, "avgIntensity": 7.5 }
    ],
    "peakIntensityTime": ISODate("2026-03-28T16:00:00Z"),
    "peakIntensityEmotion": "anxious"
  },
  "createdAt": ISODate("2026-03-28T06:15:00Z"),
  "modifiedAt": ISODate("2026-03-28T18:05:00Z")
}
```

**Completed Day Example:**

```json
{
  "_id": ObjectId("6625b2c3d4e5f6a7b8c9d0e2"),
  "dayId": "tjd_88889",
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "entityType": "TIME_JOURNAL_DAY",
  "date": "2026-03-27",
  "mode": "t60",
  "totalSlots": 24,
  "filledSlots": 24,
  "completionPercent": 100,
  "status": "completed",
  "overdueSlotCount": 0,
  "retroactiveCount": 1,
  "autoFilledCount": 7,
  "lastEntryAt": ISODate("2026-03-27T23:05:00Z"),
  "streakEligible": true,
  "emotionSummary": {
    "topEmotions": [
      { "name": "calm", "count": 8, "avgIntensity": 5.5 },
      { "name": "hopeful", "count": 4, "avgIntensity": 7.0 },
      { "name": "tired", "count": 3, "avgIntensity": 6.0 }
    ],
    "peakIntensityTime": ISODate("2026-03-27T20:00:00Z"),
    "peakIntensityEmotion": "hopeful"
  },
  "createdAt": ISODate("2026-03-27T06:05:00Z"),
  "modifiedAt": ISODate("2026-03-27T23:05:00Z")
}
```

---

## 3. Indexes

### 3.1 timeJournalEntries Indexes

| Index Name | Fields | Type | Purpose |
|------------|--------|------|---------|
| `userId_date` | `{ userId: 1, date: 1 }` | Compound | Get all entries for a user on a given date. Supports daily view (TJ-015) |
| `userId_date_slotStart` | `{ userId: 1, date: 1, slotStart: 1 }` | Compound, Unique | Slot-level lookups. Prevents duplicate entries for the same slot. Supports status engine (TJ-063) |
| `userId_createdAt` | `{ userId: 1, createdAt: -1 }` | Compound | Recent entries across all dates. Supports engagement metrics |
| `tenantId_userId` | `{ tenantId: 1, userId: 1 }` | Compound | Tenant-scoped queries for admin and counselor views |
| `userId_isRetroactive` | `{ userId: 1, isRetroactive: 1, date: 1 }` | Compound, Sparse | Retroactive entry analysis. Only indexes documents where `isRetroactive` is `true` |
| `userId_isAutoFilled` | `{ userId: 1, isAutoFilled: 1, date: 1 }` | Compound, Sparse | Auto-filled entry queries. Only indexes documents where `isAutoFilled` is `true` |

### 3.2 timeJournalDays Indexes

| Index Name | Fields | Type | Purpose |
|------------|--------|------|---------|
| `userId_date` | `{ userId: 1, date: -1 }` | Compound, Unique | Daily aggregate lookup and date-range queries. Unique constraint ensures one day document per user per date |
| `userId_status` | `{ userId: 1, status: 1, date: -1 }` | Compound | Status engine: find overdue days, streak calculation (consecutive `completed` or `streakEligible` days) |
| `userId_streakEligible` | `{ userId: 1, streakEligible: 1, date: -1 }` | Compound | Streak counter (TJ-030): find consecutive streak-eligible days |
| `tenantId_userId` | `{ tenantId: 1, userId: 1 }` | Compound | Tenant-scoped admin queries |

---

## 4. Access Pattern Reference

### 4.1 timeJournalEntries Access Patterns

| # | Access Pattern | Index | Query | Filter/Sort | Operation | Read Preference | PRD Ref |
|---|---------------|-------|-------|-------------|-----------|-----------------|---------|
| 1 | Get all entries for a user on a given date | `userId_date` | `{ userId: "u_12345", date: "2026-03-28" }` | Sort by `slotStart: 1` | find | Primary | TJ-015 |
| 2 | Get a specific slot entry | `userId_date_slotStart` | `{ userId: "u_12345", date: "2026-03-28", slotStart: ISODate("2026-03-28T14:00:00Z") }` | -- | findOne | Primary | TJ-017 |
| 3 | Upsert a slot entry | `userId_date_slotStart` | `{ userId: "u_12345", date: "2026-03-28", slotStart: ISODate(...) }` | -- | updateOne (upsert) | Primary | TJ-010 |
| 4 | Get overdue slots for today | `userId_date` | `{ userId: "u_12345", date: "2026-03-28" }` | Application-side: compare filled slots against elapsed time slots | find | Primary | TJ-061 |
| 5 | Get entries shared with trust partner | `userId_date` | `{ userId: "u_12345", date: "2026-03-28" }` | Projection excludes `redlineNote` | find | Primary | TJ-023 |
| 6 | Count entries this month | `userId_date` | `{ userId: "u_12345", date: { $gte: "2026-03-01", $lte: "2026-03-31" } }` | -- | countDocuments | Secondary | Engagement metric |
| 7 | Get retroactive entries for a date range | `userId_isRetroactive` | `{ userId: "u_12345", isRetroactive: true, date: { $gte: "2026-03-01", $lte: "2026-03-31" } }` | -- | find | Secondary | TJ-011 |
| 8 | Get retroactive entry rate | `userId_isRetroactive` | `{ userId: "u_12345", isRetroactive: true, date: { $gte: "2026-03-01", $lte: "2026-03-31" } }` | Count retroactive vs. total entries for the period | aggregate | Secondary | Clinical insight |
| 9 | Get emotion frequency distribution | `userId_date` | `{ userId: "u_12345", date: { $gte: "2026-03-01", $lte: "2026-03-31" } }` | Unwind `emotions`, group by `name`, calculate count and avgIntensity | aggregate | Secondary | TJ-044 |
| 10 | Auto-fill sleep entries for a date range | `userId_isAutoFilled` | `{ userId: "u_12345", isAutoFilled: true, date: { $gte: "2026-03-22", $lte: "2026-03-28" } }` | -- | find | Secondary | TJ-080-084 |
| 11 | Get recent entries across all dates | `userId_createdAt` | `{ userId: "u_12345" }` | Sort by `createdAt: -1`, Limit N | find | Primary | Partner notification |
| 12 | Delete all entries for a user (account deletion) | `userId_date` | `{ userId: "u_12345" }` | -- | deleteMany | Primary | FR1.4 |
| 13 | List entries by tenant | `tenantId_userId` | `{ tenantId: "t_acme" }` | -- | find | Secondary | Admin/counselor |

### 4.2 timeJournalDays Access Patterns

| # | Access Pattern | Index | Query | Filter/Sort | Operation | Read Preference | PRD Ref |
|---|---------------|-------|-------|-------------|-----------|-----------------|---------|
| 1 | Get daily summary for a specific date | `userId_date` | `{ userId: "u_12345", date: "2026-03-28" }` | -- | findOne | Primary | TJ-018, TJ-031 |
| 2 | Get daily summaries for date range (heatmap) | `userId_date` | `{ userId: "u_12345", date: { $gte: "2026-03-01", $lte: "2026-03-31" } }` | Sort by `date: -1` | find | Primary | TJ-032 |
| 3 | Calculate streak (consecutive streak-eligible days) | `userId_streakEligible` | `{ userId: "u_12345", streakEligible: true }` | Sort by `date: -1`. Application-side: walk dates backward to find consecutive days | find | Primary | TJ-030 |
| 4 | Get overdue days | `userId_status` | `{ userId: "u_12345", status: "overdue" }` | Sort by `date: -1` | find | Primary | TJ-061 |
| 5 | Get completed days in range | `userId_status` | `{ userId: "u_12345", status: "completed", date: { $gte: "2026-03-01", $lte: "2026-03-31" } }` | -- | find | Primary | TJ-076 |
| 6 | Upsert daily aggregate | `userId_date` | `{ userId: "u_12345", date: "2026-03-28" }` | Update `filledSlots`, `completionPercent`, `status`, `overdueSlotCount`, `lastEntryAt`, `streakEligible`, `emotionSummary`, `modifiedAt` | updateOne (upsert) | Primary | Status engine |
| 7 | Get today's status for Today screen | `userId_date` | `{ userId: "u_12345", date: "2026-04-03" }` | -- | findOne | Primary | TJ-065-073 |
| 8 | Count completed days this month | `userId_status` | `{ userId: "u_12345", status: "completed", date: { $gte: "2026-03-01", $lte: "2026-03-31" } }` | -- | countDocuments | Secondary | Engagement metric |
| 9 | Get weekly emotion summary | `userId_date` | `{ userId: "u_12345", date: { $gte: "2026-03-22", $lte: "2026-03-28" } }` | Project `emotionSummary` only | find | Secondary | TJ-044 |
| 10 | Delete all day summaries for a user | `userId_date` | `{ userId: "u_12345" }` | -- | deleteMany | Primary | FR1.4 |

---

## 5. Document Size Estimates

### 5.1 Per-Document Size

| Entity | Avg. Doc Size | Notes |
|--------|---------------|-------|
| Time Journal Entry (minimal: location + activity + 1 emotion) | 450 B | Quick entry (TJ-010) |
| Time Journal Entry (full: GPS + people + multiple emotions + extras) | 1.2 KB | Typical engaged entry |
| Time Journal Entry (auto-filled sleep) | 350 B | Sparse: activity only, no emotions/people |
| Time Journal Day (aggregate) | 600 B | Includes emotion summary |

### 5.2 Per-User Daily Volume

| Mode | Slots/Day | Avg. Entry Size | Daily Entry Storage | Day Aggregate | Daily Total |
|------|-----------|-----------------|---------------------|---------------|-------------|
| T-60 | 24 | 800 B | 19.2 KB | 600 B | ~20 KB |
| T-30 | 48 | 650 B (lighter entries at higher frequency) | 31.2 KB | 600 B | ~32 KB |

### 5.3 Per-User Annual Volume

| Mode | Entries/Year | Entry Storage | Day Aggregates (365) | Calendar Dual-Writes | Total |
|------|-------------|---------------|----------------------|---------------------|-------|
| T-60 (active daily user) | 8,760 | 6.84 MB | 214 KB | 2.14 MB | ~9.2 MB |
| T-30 (active daily user) | 17,520 | 11.13 MB | 214 KB | 4.28 MB | ~15.6 MB |
| T-60 (avg. user, 70% compliance) | 6,132 | 4.79 MB | 214 KB | 1.50 MB | ~6.5 MB |

**Note:** The Time Journal is the highest-volume activity in the Regal Recovery schema. At Year 3 scale (110,000 DAU), assuming 20% of DAU use Time Journal in T-60 mode at 70% compliance: ~22,000 users x 6.5 MB = ~143 GB for Time Journal alone.

---

## 6. Operational Considerations

### 6.1 Write Pattern

Each slot entry triggers two writes:
1. **Upsert** to `timeJournalEntries` (the slot entry itself)
2. **Upsert** to `timeJournalDays` (recalculate aggregate fields)

Additionally, a dual-write to `calendarActivities` occurs per Section 3.3 of the main schema.

The day aggregate upsert should be performed atomically using MongoDB's `$set` and `$inc` operators to avoid race conditions if the user submits multiple entries rapidly.

### 6.2 Status Engine Implementation

The status engine (TJ-060 through TJ-064) runs on the `timeJournalDays` document. On each entry write:

1. Query `timeJournalEntries` for `{ userId, date }` to get all filled slots.
2. Compare filled slots against the set of elapsed time slots (current time vs. slot boundaries).
3. Calculate `overdueSlotCount` = count of elapsed slots without entries.
4. Determine `status`:
   - `completed` if all 24/48 slots are filled (including final slot) and the final slot's time has elapsed.
   - `overdue` if any elapsed slot is unfilled.
   - `inProgress` otherwise.
5. Calculate `completionPercent` and `streakEligible`.
6. Update the `timeJournalDays` document.

### 6.3 Partner Access (Trust Partner Sharing)

Trust Partner reads use the same queries as the owning user, with one modification:

- The `redlineNote` field is **excluded from projection** when the reader is not the owning user.
- Permission is checked against the `permissions` collection: `PERMISSION#<contactId>#time-journal`.
- No separate "shared" collection is needed; the partner queries the same `timeJournalEntries` and `timeJournalDays` collections using the owning user's `userId`.

### 6.4 Streak Calculation

The streak counter (TJ-030) is calculated by querying `timeJournalDays` sorted by `date` descending, walking backward from today and counting consecutive days where `streakEligible` is `true`. The streak value can be cached in Valkey with a 5-minute TTL, invalidated on entry writes.

### 6.5 Data Deletion

- **Account deletion (FR1.4):** Delete all documents in both `timeJournalEntries` and `timeJournalDays` where `userId` matches. Also delete corresponding `calendarActivities` entries.
- **No TTL-based expiration:** Time Journal entries are permanent recovery data (not ephemeral). The `redlineNote` field is excluded from data exports per privacy policy but is included in account deletion.

### 6.6 Offline-First Sync

Time Journal entries are created offline-first on the device. On reconnection:
- New entries are upserted using the `userId_date_slotStart` unique index, ensuring idempotent sync.
- Day aggregates are recalculated server-side after all pending entries are synced.
- Conflict resolution: Last-Write-Wins (LWW) on `modifiedAt` for individual slot entries. This is acceptable because only the owning user writes slot entries.

### 6.7 Entry Edit Window

Per TJ-017, entries are editable for 24 hours after creation. The application layer enforces this by comparing `createdAt` against the current time before allowing updates. No database-level enforcement is needed.

---

## Related Documents

- [MongoDB Schema Design](./schema-design.md) — Main schema (Section 4.18 for Time Journal summary)
- [Time Journal PRD](../../prd/specific-features/TimeJournal/prd.md) — Full product requirements
- [Development Workflow](../development-workflow.md) — PR checklist and branching strategy
