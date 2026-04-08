# Prayer Activity -- MongoDB Schema Design

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft

Extends the main schema at `docs/specs/mongodb/schema-design.md` with detailed Prayer Activity entities, indexes, and access patterns.

---

## 1. Entities

The Prayer Activity domain introduces 3 new entity types and extends 1 existing entity:

| Entity | Collection Pattern | Description |
|--------|-------------------|-------------|
| Prayer Session (extended) | `PRAYER#<ISO8601>` | Full prayer session log with type, mood, linked prayer |
| Personal Prayer | `PERSONAL_PRAYER#<prayerId>` | User-created prayer content |
| Prayer Favorite | `PRAYER_FAV#<prayerId>` | Favorite link to library or personal prayer |
| Library Prayer (system) | `PRAYER_CONTENT#<prayerId>` in `PACK#<packId>` | Curated prayer content within packs |

---

## 2. Document Structures

### 2.1 Prayer Session (replaces existing 4.13 Prayer Log)

The existing Prayer Log entity (Section 4.13 in schema-design.md) is replaced with this expanded structure to support the full PRD requirements.

| Attribute | Pattern |
|-----------|---------|
| PK | `USER#<userId>` |
| SK | `PRAYER#<ISO8601 timestamp>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "PRAYER#2026-03-28T06:00:00Z",
  "EntityType": "PRAYER_SESSION",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T06:01:00Z",
  "ModifiedAt": "2026-03-28T06:01:00Z",
  "prayerId": "ps_22222",
  "prayerType": "guided",
  "durationMinutes": 15,
  "notes": "Spent time in silence after the guided prayer. Felt peace.",
  "linkedPrayerId": "pryr_1a2b3c4d",
  "linkedPrayerTitle": "Prayer for Strength Against Temptation",
  "moodBefore": 3,
  "moodAfter": 4,
  "isEphemeral": false,
  "notesEditableUntil": "2026-03-29T06:01:00Z"
}
```

**Field Descriptions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `prayerId` | String | Yes | Unique session ID (`ps_` prefix) |
| `prayerType` | String (enum) | Yes | `personal`, `guided`, `group`, `scriptureBased`, `intercessory`, `listening` |
| `durationMinutes` | Integer | No | Duration in minutes (null is valid) |
| `notes` | String | No | Free-text notes, max 1000 chars |
| `linkedPrayerId` | String | No | Reference to library (`pryr_`) or personal (`pp_`) prayer |
| `linkedPrayerTitle` | String | No | Denormalized title of linked prayer |
| `moodBefore` | Integer (1-5) | No | Mood rating before prayer |
| `moodAfter` | Integer (1-5) | No | Mood rating after prayer |
| `isEphemeral` | Boolean | Yes | If true, TTL auto-deletes after 30 days |
| `notesEditableUntil` | Date | Yes | 24 hours after CreatedAt; notes become read-only after |

**Ephemeral variant** adds:
```json
{
  "isEphemeral": true,
  "ephemeralDeleteAt": "2026-04-27T06:01:00Z",
  "expiresAt": 1777405800
}
```

**Access Patterns:**

| # | Pattern | Operation | Key Condition | Consistency |
|---|---------|-----------|---------------|-------------|
| P1 | Get recent prayer sessions | find | PK=`USER#<userId>`, SK begins_with `PRAYER#`, sort desc | Primary |
| P2 | Get prayer sessions by date range | find | PK=`USER#<userId>`, SK between `PRAYER#<start>` and `PRAYER#<end>` | Primary |
| P3 | Get prayer session by ID | find | PK=`USER#<userId>`, SK begins_with `PRAYER#`, filter prayerId=`ps_22222` | Primary |
| P4 | Count prayer days for streak | aggregate | PK=`USER#<userId>`, SK begins_with `PRAYER#`, group by date | Primary |
| P5 | Get sessions by type | find | PK=`USER#<userId>`, SK begins_with `PRAYER#`, filter prayerType | Primary |
| P6 | Auto-delete ephemeral | TTL | `expiresAt` attribute | N/A (async) |

**Estimated Document Size:** 500 B average (up from 400 B in existing Prayer Log)

---

### 2.2 Personal Prayer

| Attribute | Pattern |
|-----------|---------|
| PK | `USER#<userId>` |
| SK | `PERSONAL_PRAYER#<prayerId>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "PERSONAL_PRAYER#pp_11111",
  "EntityType": "PERSONAL_PRAYER",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-15T09:00:00Z",
  "ModifiedAt": "2026-03-20T14:00:00Z",
  "personalPrayerId": "pp_11111",
  "title": "Prayer for my marriage",
  "body": "Lord, heal the wounds between us. Give me the courage to be honest and the patience to listen...",
  "topicTags": ["marriage", "healing"],
  "scriptureReference": "1 Corinthians 13:4-7",
  "sortOrder": 1,
  "isFavorite": false
}
```

**Field Descriptions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `personalPrayerId` | String | Yes | Unique ID (`pp_` prefix) |
| `title` | String | Yes | Prayer title, max 100 chars |
| `body` | String | Yes | Full prayer text (unlimited) |
| `topicTags` | String[] | No | Topic tags for browsing |
| `scriptureReference` | String | No | Bible verse reference |
| `sortOrder` | Integer | Yes | User-defined display order |
| `isFavorite` | Boolean | Yes | Whether user has favorited this prayer |

**Access Patterns:**

| # | Pattern | Operation | Key Condition | Consistency |
|---|---------|-----------|---------------|-------------|
| P7 | List personal prayers | find | PK=`USER#<userId>`, SK begins_with `PERSONAL_PRAYER#` | Primary |
| P8 | Get personal prayer by ID | findOne | PK=`USER#<userId>`, SK=`PERSONAL_PRAYER#pp_11111` | Primary |

**Estimated Document Size:** 800 B average (body text can vary widely)

---

### 2.3 Prayer Favorite

| Attribute | Pattern |
|-----------|---------|
| PK | `USER#<userId>` |
| SK | `PRAYER_FAV#<prayerId>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "PRAYER_FAV#pryr_1a2b3c4d",
  "EntityType": "PRAYER_FAVORITE",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-20T10:00:00Z",
  "ModifiedAt": "2026-03-20T10:00:00Z",
  "prayerId": "pryr_1a2b3c4d",
  "prayerSource": "library",
  "title": "Prayer for Strength Against Temptation",
  "packId": "pack_temptation"
}
```

**Field Descriptions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `prayerId` | String | Yes | ID of the favorited prayer (`pryr_` or `pp_`) |
| `prayerSource` | String | Yes | `library` or `personal` |
| `title` | String | Yes | Denormalized title for display |
| `packId` | String | No | Pack ID if library prayer |

**Access Patterns:**

| # | Pattern | Operation | Key Condition | Consistency |
|---|---------|-----------|---------------|-------------|
| P9 | List favorites | find | PK=`USER#<userId>`, SK begins_with `PRAYER_FAV#` | Primary |
| P10 | Check if prayer is favorited | findOne | PK=`USER#<userId>`, SK=`PRAYER_FAV#pryr_1a2b3c4d` | Primary |

**Estimated Document Size:** 250 B average

---

### 2.4 Library Prayer (System Content)

Library prayers are stored as system content within prayer packs, following the same pattern as affirmation packs (Sections 4.34-4.35 in schema-design.md).

| Attribute | Pattern |
|-----------|---------|
| PK | `PACK#<packId>` |
| SK | `PRAYER_CONTENT#<prayerId>` |

**Example Item:**
```json
{
  "PK": "PACK#pack_temptation",
  "SK": "PRAYER_CONTENT#pryr_1a2b3c4d",
  "EntityType": "PRAYER_CONTENT",
  "TenantId": "SYSTEM",
  "CreatedAt": "2026-01-01T00:00:00Z",
  "ModifiedAt": "2026-01-01T00:00:00Z",
  "prayerId": "pryr_1a2b3c4d",
  "title": "Prayer for Strength Against Temptation",
  "body": "Heavenly Father, I come to You in my weakness. The pull of temptation is strong, but Your strength is stronger...",
  "topicTags": ["temptation", "strength", "spiritual-warfare"],
  "sourceAttribution": "App Original",
  "scriptureConnection": "1 Corinthians 10:13",
  "stepNumber": null,
  "tier": "premium",
  "language": "en"
}
```

**Step Prayer Example (freemium):**
```json
{
  "PK": "PACK#pack_step_prayers",
  "SK": "PRAYER_CONTENT#pryr_step04",
  "EntityType": "PRAYER_CONTENT",
  "TenantId": "SYSTEM",
  "CreatedAt": "2026-01-01T00:00:00Z",
  "ModifiedAt": "2026-01-01T00:00:00Z",
  "prayerId": "pryr_step04",
  "title": "Step 4 Prayer: Courage for Moral Inventory",
  "body": "God, give me the courage to look honestly at myself...",
  "topicTags": ["step-work", "courage", "honesty"],
  "sourceAttribution": "App Original",
  "scriptureConnection": "Psalm 139:23-24",
  "stepNumber": 4,
  "tier": "free",
  "language": "en"
}
```

**Access Patterns:**

| # | Pattern | Operation | Key Condition | Consistency |
|---|---------|-----------|---------------|-------------|
| P11 | List prayers in pack | find | PK=`PACK#<packId>`, SK begins_with `PRAYER_CONTENT#` | Primary |
| P12 | Get single prayer | findOne | PK=`PACK#<packId>`, SK=`PRAYER_CONTENT#<prayerId>` | Primary |
| P13 | Search prayers (full-text) | Atlas Search | text index on `title`, `body` fields | Secondary |

---

### 2.5 Calendar Activity Integration (dual-write)

When a prayer session is created, a calendar activity entry is also written per Section 4.48 of schema-design.md.

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "ACTIVITY#2026-03-28#PRAYER#2026-03-28T06:00:00Z",
  "EntityType": "CALENDAR_ACTIVITY",
  "activityType": "PRAYER",
  "summary": {
    "prayerType": "guided",
    "durationMinutes": 15,
    "linkedPrayerTitle": "Prayer for Strength Against Temptation"
  },
  "sourceKey": "PRAYER#2026-03-28T06:00:00Z"
}
```

---

### 2.6 Prayer Streak (Computed, Cached)

Prayer streak is computed from prayer session data and cached in Valkey. It is not stored as a separate MongoDB document -- it is derived from the aggregate of prayer sessions.

**Valkey Cache Key:** `prayer:streak:<userId>`
**Valkey Cache TTL:** 5 minutes
**Invalidation:** On prayer session create/delete via MongoDB Change Streams

**Computed Fields:**

| Field | Derivation |
|-------|-----------|
| `currentStreakDays` | Count consecutive days (from today backwards) with >= 1 prayer session |
| `longestStreakDays` | Max consecutive-day count across all prayer history |
| `totalPrayerDays` | Count distinct days with >= 1 prayer session |
| `sessionsThisWeek` | Count sessions in current ISO week |
| `averageDurationMinutes` | Average of non-null `durationMinutes` values |
| `typeDistribution` | Group-by count of `prayerType` across all sessions |

---

## 3. Indexes

### New Indexes

| Collection/Table | Index | Fields | Purpose |
|-----------------|-------|--------|---------|
| Main table | (existing PK/SK) | `{ PK: 1, SK: 1 }` | All prayer session queries (P1-P6) |
| Main table | (existing PK/SK) | `{ PK: 1, SK: 1 }` | Personal prayer queries (P7-P8) |
| Main table | (existing PK/SK) | `{ PK: 1, SK: 1 }` | Favorite queries (P9-P10) |
| Main table | (existing PK/SK) | `{ PK: 1, SK: 1 }` | Library prayer queries (P11-P12) |
| Library prayers | Atlas Search | `{ title: "text", body: "text" }` | Full-text search (P13) |

No new indexes are required beyond the existing PK/SK compound index and the Atlas Search text index for prayer content search. All access patterns are served by the existing single-table key structure.

---

## 4. Document Size Estimates

| Entity | Avg. Doc Size | Frequency per User per Day |
|--------|---------------|---------------------------|
| Prayer Session | 500 B | 0-3 |
| Personal Prayer | 800 B | -- (0-20 per user lifetime) |
| Prayer Favorite | 250 B | -- (0-50 per user lifetime) |
| Library Prayer | 600 B | -- (system content) |
| Calendar Activity (prayer) | 250 B | 0-3 (mirror of sessions) |

### Storage Impact per Active User per Year

| Category | Items/Year | Avg Size | Storage |
|----------|-----------|----------|---------|
| Prayer sessions (1/day avg) | 365 | 500 B | 178 KB |
| Calendar mirrors | 365 | 250 B | 89 KB |
| Personal prayers | 10 | 800 B | 8 KB |
| Favorites | 20 | 250 B | 5 KB |
| **Total per user per year** | **760** | | **280 KB** |

---

## 5. Access Pattern Summary

| # | Access Pattern | Key Condition | Notes |
|---|---------------|---------------|-------|
| P1 | Recent prayer sessions | PK=`USER#<userId>`, SK begins_with `PRAYER#` desc | Main list view |
| P2 | Prayer sessions by date range | PK=`USER#<userId>`, SK between `PRAYER#<start>` and `PRAYER#<end>` | History filter |
| P3 | Prayer session by ID | PK=`USER#<userId>`, filter prayerId | Detail view |
| P4 | Prayer days for streak | PK=`USER#<userId>`, SK begins_with `PRAYER#`, aggregate | Streak calculation |
| P5 | Sessions by type | PK=`USER#<userId>`, SK begins_with `PRAYER#`, filter type | Type distribution |
| P6 | Auto-delete ephemeral | TTL on `expiresAt` | Async cleanup |
| P7 | List personal prayers | PK=`USER#<userId>`, SK begins_with `PERSONAL_PRAYER#` | Personal library |
| P8 | Get personal prayer | PK=`USER#<userId>`, SK=`PERSONAL_PRAYER#<id>` | Detail/edit |
| P9 | List favorites | PK=`USER#<userId>`, SK begins_with `PRAYER_FAV#` | Favorites view |
| P10 | Check if favorited | PK=`USER#<userId>`, SK=`PRAYER_FAV#<id>` | Toggle state |
| P11 | Prayers in pack | PK=`PACK#<packId>`, SK begins_with `PRAYER_CONTENT#` | Pack browsing |
| P12 | Get single library prayer | PK=`PACK#<packId>`, SK=`PRAYER_CONTENT#<id>` | Detail view |
| P13 | Full-text prayer search | Atlas Search text index | Library search |
| P14 | Calendar: prayer activities | PK=`USER#<userId>`, SK begins_with `ACTIVITY#<date>#PRAYER#` | Calendar view |
