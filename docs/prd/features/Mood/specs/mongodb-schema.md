# Mood Ratings -- MongoDB Collection Design

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft
**Parent Schema:** `docs/specs/mongodb/schema-design.md` (Section 4.10)

---

## 1. Collection: `moodRatings`

### Document Structure

Each mood entry is a standalone document in the `moodRatings` collection. The PRD specifies a 1-5 scale (not 1-10 as the existing schema placeholder shows). This spec supersedes Section 4.10 of the parent schema.

```json
{
  "_id": ObjectId("..."),
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "entityType": "MOOD",
  "moodId": "mood_a1b2c3",
  "rating": 4,
  "emotionLabels": ["Hopeful", "Grateful"],
  "contextNote": "Felt centered after morning prayer.",
  "source": "direct",
  "createdAt": ISODate("2026-04-07T14:30:00Z"),
  "modifiedAt": ISODate("2026-04-07T14:30:00Z")
}
```

### Field Definitions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | auto | MongoDB document ID |
| `userId` | String | yes | Owner user ID |
| `tenantId` | String | yes | Tenant identifier. Default: `DEFAULT` |
| `entityType` | String | yes | Always `MOOD` |
| `moodId` | String | yes | Unique mood entry ID (format: `mood_{alphanumeric}`) |
| `rating` | Integer | yes | Mood rating 1-5 (1=Crisis, 2=Struggling, 3=Okay, 4=Good, 5=Great) |
| `emotionLabels` | String[] | no | Zero or more predefined emotion labels |
| `contextNote` | String | no | Free-text note, max 200 characters |
| `source` | String | yes | Entry source: `direct`, `widget`, `post-activity`, `notification` |
| `createdAt` | Date | yes | Immutable creation timestamp (UTC). Set once, never modified. |
| `modifiedAt` | Date | yes | Last modification timestamp (UTC). Updated on edits within 24h window. |

### Validation Rules

- `rating` must be integer in range [1, 5]
- `emotionLabels` must be a subset of the predefined list (15 labels)
- `contextNote` maxLength: 200 characters
- `source` must be one of: `direct`, `widget`, `post-activity`, `notification`
- `createdAt` is immutable after initial write
- Edits and deletes only permitted within 24 hours of `createdAt`

### Predefined Emotion Labels (Enum)

```
Peaceful, Grateful, Hopeful, Confident, Connected,
Anxious, Lonely, Angry, Ashamed, Overwhelmed,
Sad, Numb, Restless, Afraid, Frustrated
```

---

## 2. Indexes

| Index Name | Fields | Type | Purpose |
|------------|--------|------|---------|
| `userId_createdAt` | `{ userId: 1, createdAt: -1 }` | Compound | Primary query: list user's mood entries by date (desc) |
| `userId_rating` | `{ userId: 1, rating: 1, createdAt: -1 }` | Compound | Filter by rating value |
| `userId_emotionLabels` | `{ userId: 1, emotionLabels: 1, createdAt: -1 }` | Compound (multikey) | Filter by emotion label |
| `userId_date_partition` | `{ userId: 1, "datePartition": 1 }` | Compound | Daily aggregation queries (datePartition = YYYY-MM-DD string derived from createdAt in user's home timezone) |
| `tenantId_1` | `{ tenantId: 1 }` | Single | Tenant admin queries |
| `moodId_1` | `{ moodId: 1 }` | Single (unique) | Direct lookup by mood ID |

### Derived Field: `datePartition`

A denormalized `YYYY-MM-DD` string computed from `createdAt` in the user's home timezone at write time. This enables efficient daily grouping without timezone conversion at query time.

---

## 3. Calendar Activity Dual-Write

When a mood entry is created, a denormalized record is also written to the `calendarActivities` collection:

```json
{
  "_id": ObjectId("..."),
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "entityType": "CALENDAR_ACTIVITY",
  "activityType": "MOOD",
  "date": "2026-04-07",
  "timestamp": ISODate("2026-04-07T14:30:00Z"),
  "summary": {
    "rating": 4,
    "emotionLabels": ["Hopeful", "Grateful"]
  },
  "sourceId": "mood_a1b2c3"
}
```

This enables the calendar month view to fetch all activity types for a date range in a single query.

---

## 4. Access Patterns

| # | Access Pattern | Collection | Query | Sort | Notes |
|---|---------------|------------|-------|------|-------|
| AP-MOOD-01 | List mood entries (paginated, desc) | `moodRatings` | `{ userId, createdAt: { $gte, $lte } }` | `{ createdAt: -1 }` | Primary listing with cursor pagination |
| AP-MOOD-02 | Get single mood entry by ID | `moodRatings` | `{ moodId }` | -- | Direct lookup |
| AP-MOOD-03 | Get today's entries | `moodRatings` | `{ userId, datePartition: "2026-04-07" }` | `{ createdAt: 1 }` | Mini-timeline (chronological) |
| AP-MOOD-04 | Get daily averages for date range | `moodRatings` | Aggregation: `$match { userId, datePartition: { $gte, $lte } }`, `$group { _id: "$datePartition", avg: { $avg: "$rating" }, count: { $sum: 1 }, min: { $min: "$rating" }, max: { $max: "$rating" } }` | `{ _id: -1 }` | Calendar color-coding, daily view |
| AP-MOOD-05 | Filter by rating | `moodRatings` | `{ userId, rating: { $in: [1, 2] } }` | `{ createdAt: -1 }` | Search/filter |
| AP-MOOD-06 | Filter by emotion label | `moodRatings` | `{ userId, emotionLabels: "Anxious" }` | `{ createdAt: -1 }` | Uses multikey index |
| AP-MOOD-07 | Search notes by keyword | `moodRatings` | `{ userId, contextNote: { $regex: "keyword", $options: "i" } }` | `{ createdAt: -1 }` | Text search on notes |
| AP-MOOD-08 | Hourly heatmap aggregation | `moodRatings` | Aggregation: `$match { userId, createdAt range }`, `$group { _id: { $hour: "$createdAt" }, avg: { $avg: "$rating" } }` | -- | Time-of-day patterns |
| AP-MOOD-09 | Day-of-week aggregation | `moodRatings` | Aggregation: `$match { userId, createdAt range }`, `$group { _id: { $dayOfWeek: "$createdAt" }, avg: { $avg: "$rating" } }` | -- | Day-of-week patterns |
| AP-MOOD-10 | Emotion label frequency | `moodRatings` | Aggregation: `$match { userId, createdAt range }`, `$unwind "$emotionLabels"`, `$group { _id: "$emotionLabels", count: { $sum: 1 } }` | `{ count: -1 }` | Emotion trends |
| AP-MOOD-11 | Sustained low mood check | `moodRatings` | Aggregation: daily averages for last 3+ days, filter `avg <= 2.0` | -- | Alert trigger |
| AP-MOOD-12 | Mood tracking streak | `moodRatings` | Aggregation: distinct `datePartition` values, check consecutive days | -- | Tracking integration |
| AP-MOOD-13 | Calendar view (month) | `calendarActivities` | `{ userId, activityType: "MOOD", date: { $gte: "2026-04-01", $lte: "2026-04-30" } }` | `{ date: 1, timestamp: 1 }` | Calendar dual-write |
| AP-MOOD-14 | Update mood entry | `moodRatings` | `{ moodId, userId }` + condition: `createdAt > (now - 24h)` | -- | 24-hour edit window |
| AP-MOOD-15 | Delete mood entry | `moodRatings` | `{ moodId, userId }` + condition: `createdAt > (now - 24h)` | -- | 24-hour delete window |

---

## 5. Document Size Estimate

| Field | Avg Bytes |
|-------|-----------|
| `_id` | 12 |
| `userId` | 20 |
| `tenantId` | 15 |
| `entityType` | 10 |
| `moodId` | 20 |
| `rating` | 4 |
| `emotionLabels` (avg 2 labels) | 40 |
| `contextNote` (avg 80 chars) | 80 |
| `source` | 15 |
| `datePartition` | 15 |
| `createdAt` | 8 |
| `modifiedAt` | 8 |
| BSON overhead | ~50 |
| **Total** | **~300 B** |

At 3 entries/user/day, 5000 DAU: ~15,000 entries/day, ~450 KB/day, ~16 MB/month.

---

## 6. Caching Strategy (Valkey)

| Cache Key | TTL | Invalidation | Purpose |
|-----------|-----|-------------|---------|
| `mood:today:{userId}:{datePartition}` | 5 min | On new mood entry | Today's entries for mini-timeline |
| `mood:streak:{userId}` | 1 hour | On new mood entry | Mood tracking streak count |
| `mood:daily-avg:{userId}:{datePartition}` | 24 hours | On mood entry create/update/delete | Daily average for calendar coloring |

---

## 7. Migration Notes

The existing schema (Section 4.10 of `schema-design.md`) defines a Mood Rating entity with:
- A 1-10 `rating` scale
- A single `emotion` string
- A `notes` field with 500 char implied max

This specification updates the Mood entity to match the PRD:
- Rating scale changed to 1-5
- `emotion` replaced with `emotionLabels` (array of predefined labels)
- `notes` renamed to `contextNote` with 200 char max
- Added `source`, `datePartition` fields
- Added dedicated indexes for filtering and aggregation

The parent `schema-design.md` should be updated to reference this document for the canonical Mood Rating schema.
