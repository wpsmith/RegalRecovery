# Devotionals -- MongoDB Collection Design

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft

---

## Overview

The Devotionals feature uses multiple collections following the project's collection-per-entity design. Devotional content is system-level data (not user-scoped), while completions, favorites, and series progress are user-scoped.

---

## Collections

### 1. Devotional Content (`devotionals`)

System-level collection containing all devotional content. Not user-scoped.

**Document Structure:**

```json
{
  "_id": ObjectId("..."),
  "devotionalId": "dev_a1b2c3d4",
  "entityType": "DEVOTIONAL_CONTENT",
  "tenantId": "SYSTEM",
  "createdAt": "2026-01-01T00:00:00Z",
  "modifiedAt": "2026-01-01T00:00:00Z",

  "title": "Strength in Surrender",
  "scriptureReference": "2 Corinthians 12:9",
  "scriptureText": {
    "NIV": "My grace is sufficient for you, for my power is made perfect in weakness.",
    "ESV": "My grace is sufficient for you, for my power is made perfect in weakness.",
    "NLT": "My grace is all you need. My power works best in weakness.",
    "KJV": "My grace is sufficient for thee: for my strength is made perfect in weakness.",
    "RVR1960": "Baste mi gracia; porque mi poder se perfecciona en la debilidad.",
    "NVI": "Te basta con mi gracia, pues mi poder se perfecciona en la debilidad."
  },
  "reading": {
    "en": "In our recovery journey, we often try to fight our battles alone...",
    "es": "En nuestro camino de recuperacion, a menudo intentamos luchar solos..."
  },
  "recoveryConnection": {
    "en": "Surrender is not giving up -- it is giving over.",
    "es": "Rendirse no es abandonar -- es entregar."
  },
  "reflectionQuestion": {
    "en": "Where in your recovery are you trying to control what only God can do?",
    "es": "En que parte de tu recuperacion estas intentando controlar lo que solo Dios puede hacer?"
  },
  "prayer": {
    "en": "Lord, I confess that I have been trying to do this on my own...",
    "es": "Senor, confieso que he estado tratando de hacer esto por mi cuenta..."
  },
  "authorName": "Dr. Mark Laaser",
  "authorBio": {
    "en": "Christian counselor specializing in sexual addiction recovery",
    "es": "Consejero cristiano especializado en la recuperacion de la adiccion sexual"
  },
  "topic": "surrender",
  "seriesId": null,
  "seriesDay": null,
  "tier": "free",
  "freemiumRotationDay": 7,
  "wordCount": 450,
  "isPublished": true,
  "publishedAt": "2026-01-01T00:00:00Z"
}
```

**Indexes:**

| Index | Fields | Purpose |
|-------|--------|---------|
| `devotionalId_1` | `{ devotionalId: 1 }` (unique) | Lookup by devotional ID |
| `topic_1_tier_1` | `{ topic: 1, tier: 1 }` | Browse by topic with tier filter |
| `authorName_1` | `{ authorName: 1 }` | Browse by author |
| `seriesId_1_seriesDay_1` | `{ seriesId: 1, seriesDay: 1 }` | Series day lookup |
| `tier_1_freemiumRotationDay_1` | `{ tier: 1, freemiumRotationDay: 1 }` | Free rotation day lookup |
| `isPublished_1` | `{ isPublished: 1 }` | Filter published content |
| Text index | `{ title: "text", "scriptureReference": "text", "reading.en": "text", "reading.es": "text" }` | Full-text search |

**Average Document Size:** ~4 KB (multi-language content with all translations)

---

### 2. Devotional Series (`devotionalSeries`)

System-level collection for series metadata.

**Document Structure:**

```json
{
  "_id": ObjectId("..."),
  "seriesId": "series_recovery365",
  "entityType": "DEVOTIONAL_SERIES",
  "tenantId": "SYSTEM",
  "createdAt": "2026-01-01T00:00:00Z",
  "modifiedAt": "2026-01-01T00:00:00Z",

  "name": {
    "en": "365 Days of Recovery",
    "es": "365 Dias de Recuperacion"
  },
  "description": {
    "en": "A year-long journey through recovery with daily devotionals...",
    "es": "Un viaje de un ano a traves de la recuperacion..."
  },
  "authorName": "Dr. Mark Laaser",
  "totalDays": 365,
  "tier": "premium",
  "price": 14.99,
  "currency": "USD",
  "category": "recovery",
  "language": "en",
  "thumbnailUrl": "https://cdn.regalrecovery.com/series/recovery365.png",
  "isPublished": true,
  "publishedAt": "2026-01-01T00:00:00Z"
}
```

**Indexes:**

| Index | Fields | Purpose |
|-------|--------|---------|
| `seriesId_1` | `{ seriesId: 1 }` (unique) | Lookup by series ID |
| `tier_1_isPublished_1` | `{ tier: 1, isPublished: 1 }` | Browse available series |
| `category_1` | `{ category: 1 }` | Browse by category |

**Average Document Size:** ~1.5 KB

---

### 3. Devotional Completion (User-Scoped, existing `calendarActivities` pattern)

User-scoped completions follow the existing entity pattern with `PK`/`SK` keys.

**Document Structure (in the main user-scoped collection):**

```json
{
  "PK": "USER#u_12345",
  "SK": "DEVOTIONAL#2026-04-07T06:30:00Z",
  "EntityType": "DEVOTIONAL",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-04-07T06:30:00Z",
  "ModifiedAt": "2026-04-07T06:30:00Z",

  "completionId": "dc_e5f6g7h8",
  "devotionalId": "dev_a1b2c3d4",
  "devotionalTitle": "Strength in Surrender",
  "scriptureReference": "2 Corinthians 12:9",
  "reflection": "The passage about surrender resonated deeply...",
  "moodTag": "hopeful",
  "seriesId": null,
  "seriesDay": null,
  "topic": "surrender"
}
```

**Also written to calendarActivities collection (dual-write):**

```json
{
  "PK": "USER#u_12345",
  "SK": "ACTIVITY#2026-04-07#DEVOTIONAL#2026-04-07T06:30:00Z",
  "EntityType": "CALENDAR_ACTIVITY",
  "activityType": "DEVOTIONAL",
  "summary": {
    "devotionalTitle": "Strength in Surrender",
    "scriptureReference": "2 Corinthians 12:9",
    "hasReflection": true,
    "moodTag": "hopeful"
  },
  "sourceKey": "DEVOTIONAL#2026-04-07T06:30:00Z"
}
```

**Access Patterns:**

| # | Pattern | Operation | Key Condition | Consistency |
|---|---------|-----------|---------------|-------------|
| 1 | Get recent devotional completions | find | PK=`USER#u_12345`, SK begins_with `DEVOTIONAL#`, sort desc | Primary |
| 2 | Get completions by date range | find | PK=`USER#u_12345`, SK between `DEVOTIONAL#<start>` and `DEVOTIONAL#<end>` | Primary |
| 3 | Get completion by ID | find | PK=`USER#u_12345`, SK begins_with `DEVOTIONAL#`, filter completionId=`dc_e5f6g7h8` | Primary |
| 4 | Calendar day view | find | PK=`USER#u_12345`, SK begins_with `ACTIVITY#2026-04-07#DEVOTIONAL` | Primary |

**Average Document Size:** ~500 B

---

### 4. Devotional Favorites (User-Scoped)

```json
{
  "PK": "USER#u_12345",
  "SK": "DEVFAV#dev_a1b2c3d4",
  "EntityType": "DEVOTIONAL_FAVORITE",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-04-07T06:45:00Z",
  "ModifiedAt": "2026-04-07T06:45:00Z",

  "devotionalId": "dev_a1b2c3d4",
  "devotionalTitle": "Strength in Surrender",
  "scriptureReference": "2 Corinthians 12:9",
  "topic": "surrender"
}
```

**Access Patterns:**

| # | Pattern | Operation | Key Condition |
|---|---------|-----------|---------------|
| 5 | List favorites | find | PK=`USER#u_12345`, SK begins_with `DEVFAV#` |
| 6 | Check if favorited | findOne | PK=`USER#u_12345`, SK=`DEVFAV#dev_a1b2c3d4` |
| 7 | Remove favorite | deleteOne | PK=`USER#u_12345`, SK=`DEVFAV#dev_a1b2c3d4` |

**Average Document Size:** ~300 B

---

### 5. Series Progress (User-Scoped)

Tracks user's progress and state for each series they have interacted with.

```json
{
  "PK": "USER#u_12345",
  "SK": "DEVSERIES#series_recovery365",
  "EntityType": "DEVOTIONAL_SERIES_PROGRESS",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-01T00:00:00Z",
  "ModifiedAt": "2026-04-07T06:30:00Z",

  "seriesId": "series_recovery365",
  "currentDay": 38,
  "completedDays": 37,
  "status": "active",
  "startedAt": "2026-03-01T00:00:00Z",
  "lastCompletedAt": "2026-04-07T06:30:00Z",
  "pausedAt": null
}
```

**Access Patterns:**

| # | Pattern | Operation | Key Condition |
|---|---------|-----------|---------------|
| 8 | Get active series | find | PK=`USER#u_12345`, SK begins_with `DEVSERIES#`, filter status=`active` |
| 9 | Get series progress | findOne | PK=`USER#u_12345`, SK=`DEVSERIES#series_recovery365` |
| 10 | List all series progress | find | PK=`USER#u_12345`, SK begins_with `DEVSERIES#` |

**Average Document Size:** ~350 B

---

### 6. Devotional Streak (User-Scoped)

Denormalized streak counter updated on each completion.

```json
{
  "PK": "USER#u_12345",
  "SK": "DEVSTREAK",
  "EntityType": "DEVOTIONAL_STREAK",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-23T00:00:00Z",
  "ModifiedAt": "2026-04-07T06:30:00Z",

  "currentDays": 15,
  "longestDays": 23,
  "lastCompletedDate": "2026-04-07"
}
```

**Access Patterns:**

| # | Pattern | Operation | Key Condition |
|---|---------|-----------|---------------|
| 11 | Get devotional streak | findOne | PK=`USER#u_12345`, SK=`DEVSTREAK` |

**Note:** Cached in Valkey with 5-minute TTL. Invalidated on new devotional completion.

**Average Document Size:** ~200 B

---

### 7. Devotional Notification Preferences (via User Settings)

Devotional notification preferences are stored as part of the existing User Settings document:

```json
{
  "PK": "USER#u_12345",
  "SK": "SETTINGS",
  "notificationPreferences": {
    "devotionalReminder": true,
    "devotionalReminderTime": "07:00",
    "devotionalMissedFollowUp": true,
    "devotionalMissedFollowUpTime": "12:00",
    "devotionalStreakMilestone": true,
    "devotionalNewContent": true
  }
}
```

No separate collection needed -- extends the existing Settings entity.

---

## Complete Access Pattern Summary

| # | Access Pattern | Collection | Query | Frequency |
|---|---------------|------------|-------|-----------|
| 1 | Get today's devotional (free rotation) | `devotionals` | `tier=free, freemiumRotationDay=N` | High (daily per user) |
| 2 | Get today's devotional (series) | `devotionals` | `seriesId, seriesDay=N` | High (daily per premium user) |
| 3 | Get devotional by ID | `devotionals` | `devotionalId=X` | Medium |
| 4 | Browse by topic | `devotionals` | `topic=X, tier=Y` | Medium |
| 5 | Browse by author | `devotionals` | `authorName=X` | Low |
| 6 | Full-text search | `devotionals` | Text index search | Medium |
| 7 | List series | `devotionalSeries` | `tier=X, isPublished=true` | Low |
| 8 | Get series by ID | `devotionalSeries` | `seriesId=X` | Low |
| 9 | Record completion | User collection | Insert `DEVOTIONAL#<ts>` | High |
| 10 | List completions (history) | User collection | SK begins_with `DEVOTIONAL#` | Medium |
| 11 | Completions by date range | User collection | SK between range | Medium |
| 12 | Add/remove favorite | User collection | Upsert/delete `DEVFAV#<devId>` | Low |
| 13 | List favorites | User collection | SK begins_with `DEVFAV#` | Medium |
| 14 | Get/update series progress | User collection | SK=`DEVSERIES#<seriesId>` | Medium |
| 15 | Get devotional streak | User collection | SK=`DEVSTREAK` | High |
| 16 | Calendar day view (devotionals) | User collection | SK begins_with `ACTIVITY#<date>#DEVOTIONAL` | High |
| 17 | Search reflections | User collection | SK begins_with `DEVOTIONAL#`, filter reflection | Low |

---

## Document Size Estimates

| Entity | Avg Size | Frequency per User/Day | Notes |
|--------|----------|------------------------|-------|
| Devotional Content | 4 KB | N/A | System content, ~400+ documents |
| Devotional Series | 1.5 KB | N/A | System content, ~10-20 documents |
| Devotional Completion | 500 B | 0-1 | Daily |
| Calendar Activity (devotional) | 250 B | 0-1 | Mirror of completion |
| Devotional Favorite | 300 B | Rare | 0-20 per user total |
| Series Progress | 350 B | N/A | 0-5 per user total |
| Devotional Streak | 200 B | N/A | 1 per user |

**Estimated storage per active user per year:**
- Completions: 365 x 500 B = ~178 KB
- Calendar mirrors: 365 x 250 B = ~89 KB
- Favorites: 20 x 300 B = ~6 KB
- Series progress: 5 x 350 B = ~1.7 KB
- Streak: 200 B
- **Total per user/year: ~275 KB**

---

## Offline Sync Considerations

- **Devotional content caching:** Current day + next 7 days pre-loaded to device
- **Completion sync:** Offline completions saved locally with timestamp, synced on reconnection
- **Conflict resolution:** If same devotional completed on multiple devices, union merge (keep both records, deduplicate by devotionalId + date)
- **Streak recalculation:** Server-side authoritative; client shows optimistic value, corrected on sync
