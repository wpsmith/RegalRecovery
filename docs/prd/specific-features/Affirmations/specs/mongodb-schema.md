# Affirmations: MongoDB Collection Design

**Version:** 1.0.0
**Date:** 2026-04-08
**Status:** Draft
**Traces to:** acceptance-criteria.md, openapi.yaml, docs/specs/mongodb/schema-design.md (entities 4.34-4.36)

---

## 1. Overview

The Affirmations feature uses three document types within the existing MongoDB schema:
1. **Affirmation Packs** (system content, TenantId=SYSTEM)
2. **Affirmations** (within packs, system content)
3. **Custom Affirmations** (user-created, TenantId per user's tenant)

Additionally, user-level state is tracked for favorites, rotation position, read history, and level progression.

---

## 2. Collection: System Affirmation Packs

### 2.1 Pack Metadata Document

```json
{
  "_id": ObjectId("..."),
  "PK": "PACK#pack_basic_affirmations",
  "SK": "META",
  "EntityType": "AFFIRMATION_PACK",
  "TenantId": "SYSTEM",
  "CreatedAt": "2026-01-01T00:00:00Z",
  "ModifiedAt": "2026-01-01T00:00:00Z",
  "packId": "pack_basic_affirmations",
  "name": "Basic Affirmations Pack",
  "description": "50+ scripture-based affirmations across core recovery categories",
  "tier": "free",
  "price": 0,
  "affirmationCount": 55,
  "categories": ["identity", "strength", "recovery", "purity", "freedom", "surrender", "courage", "hope"],
  "language": "en",
  "version": 1
}
```

### 2.2 Affirmation Document (within Pack)

```json
{
  "_id": ObjectId("..."),
  "PK": "PACK#pack_basic_affirmations",
  "SK": "AFFIRMATION#aff_001",
  "EntityType": "AFFIRMATION",
  "TenantId": "SYSTEM",
  "CreatedAt": "2026-01-01T00:00:00Z",
  "ModifiedAt": "2026-01-01T00:00:00Z",
  "affirmationId": "aff_001",
  "statement": "I am fearfully and wonderfully made.",
  "scriptureReference": "Psalm 139:14",
  "scriptureText": "I praise you because I am fearfully and wonderfully made; your works are wonderful, I know that full well.",
  "expansion": "God created you with intention and purpose. Your worth is not determined by your addiction or your failures. You are a masterpiece in progress.",
  "prayer": "Lord, help me see myself as You see me today -- fearfully and wonderfully made, not defined by my struggles.",
  "category": "identity",
  "level": 1,
  "language": "en",
  "tags": ["morning", "identity", "worth"],
  "sortOrder": 0
}
```

### Field Reference

| Field | Type | Required | Immutable | Description |
|-------|------|----------|-----------|-------------|
| `PK` | String | Yes | Yes | `PACK#{packId}` -- pack partition key |
| `SK` | String | Yes | Yes | `AFFIRMATION#{affirmationId}` -- sort key within pack |
| `EntityType` | String | Yes | Yes | Always `"AFFIRMATION"` |
| `TenantId` | String | Yes | Yes | `"SYSTEM"` for system packs |
| `CreatedAt` | Date | Yes | Yes | Immutable creation timestamp (FR2.7) |
| `ModifiedAt` | Date | Yes | No | Updated on content revisions |
| `affirmationId` | String | Yes | Yes | Unique ID (`aff_{alphanumeric}`) |
| `statement` | String | Yes | No | First-person, present-tense affirmation (max 500 chars) |
| `scriptureReference` | String | Yes | No | Bible verse reference (e.g., "Psalm 139:14") |
| `scriptureText` | String | No | No | Full verse text in default translation |
| `expansion` | String | No | No | Optional deeper reflection text |
| `prayer` | String | No | No | Optional closing prayer |
| `category` | String | Yes | No | Category enum value |
| `level` | Integer | Yes | No | 1, 2, or 3 (progression level) |
| `language` | String | Yes | No | Language code (en, es, etc.) |
| `tags` | Array[String] | No | No | Searchable tags for contextual delivery |
| `sortOrder` | Integer | Yes | No | Display order within pack |

### Constraints

- `statement` max length: 500 characters
- `category` enum: `identity`, `strength`, `recovery`, `purity`, `freedom`, `surrender`, `courage`, `hope`, `family`, `healthySexuality`
- `level` range: 1-3 inclusive
- `language` enum: `en`, `es`
- `CreatedAt` is immutable -- content updates only modify `ModifiedAt`

---

## 3. Collection: Custom Affirmations (User-Created)

### Document Structure

```json
{
  "_id": ObjectId("..."),
  "PK": "USER#u_12345",
  "SK": "AFFIRMATION#CUSTOM#caff_001",
  "EntityType": "CUSTOM_AFFIRMATION",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-15T09:00:00Z",
  "ModifiedAt": "2026-03-15T09:00:00Z",
  "affirmationId": "caff_001",
  "statement": "My family deserves the best version of me.",
  "scriptureReference": "Philippians 4:13",
  "scriptureText": null,
  "category": "family",
  "level": 1,
  "schedule": "daily",
  "customScheduleDays": null,
  "isActive": true
}
```

### Field Reference

| Field | Type | Required | Immutable | Description |
|-------|------|----------|-----------|-------------|
| `PK` | String | Yes | Yes | `USER#{userId}` -- owner partition key |
| `SK` | String | Yes | Yes | `AFFIRMATION#CUSTOM#{affirmationId}` |
| `EntityType` | String | Yes | Yes | Always `"CUSTOM_AFFIRMATION"` |
| `TenantId` | String | Yes | Yes | User's tenant ID |
| `CreatedAt` | Date | Yes | Yes | Immutable creation timestamp (FR2.7) |
| `ModifiedAt` | Date | Yes | No | Updated on edits |
| `affirmationId` | String | Yes | Yes | Unique ID (`caff_{alphanumeric}`) |
| `statement` | String | Yes | No | User-written affirmation (max 500 chars) |
| `scriptureReference` | String | No | No | Optional scripture reference |
| `scriptureText` | String | No | No | Optional verse text |
| `category` | String | Yes | No | Category enum value |
| `level` | Integer | Yes | No | Always 1 for custom affirmations |
| `schedule` | String | Yes | No | Delivery schedule enum |
| `customScheduleDays` | Array[String] | No | No | Days for custom schedule (e.g., ["monday", "wednesday", "friday"]) |
| `isActive` | Boolean | Yes | No | Whether included in rotation |

### Constraints

- Max 50 custom affirmations per user
- `schedule` enum: `daily`, `weekdays`, `weekends`, `custom`
- `customScheduleDays` required when schedule is `custom`; values from: `monday`, `tuesday`, `wednesday`, `thursday`, `friday`, `saturday`, `sunday`
- Custom affirmations always level 1 (user-created content cannot self-assign advanced levels)

---

## 4. Collection: User Affirmation State

### 4.1 Favorite Record

```json
{
  "_id": ObjectId("..."),
  "PK": "USER#u_12345",
  "SK": "AFFIRMATION#FAVORITE#aff_001",
  "EntityType": "AFFIRMATION_FAVORITE",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-04-01T08:00:00Z",
  "affirmationId": "aff_001",
  "packId": "pack_basic_affirmations"
}
```

### 4.2 Read History Record

```json
{
  "_id": ObjectId("..."),
  "PK": "USER#u_12345",
  "SK": "AFFIRMATION#READ#2026-04-08",
  "EntityType": "AFFIRMATION_READ",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-04-08T07:15:00Z",
  "affirmationId": "aff_023",
  "source": "daily",
  "calendarDate": "2026-04-08"
}
```

### 4.3 Rotation State

```json
{
  "_id": ObjectId("..."),
  "PK": "USER#u_12345",
  "SK": "AFFIRMATION#ROTATION_STATE",
  "EntityType": "AFFIRMATION_ROTATION_STATE",
  "TenantId": "DEFAULT",
  "ModifiedAt": "2026-04-08T00:00:00Z",
  "selectionMode": "randomAutomatic",
  "activePackId": null,
  "dayOfWeekAssignments": null,
  "chosenAffirmationId": null,
  "rotationCycleShown": ["aff_001", "aff_003", "aff_007"],
  "lastDeliveredId": "aff_023",
  "lastDeliveredDate": "2026-04-08",
  "healthySexualityOptIn": false,
  "healthySexualityOptInDate": null
}
```

### 4.4 Cumulative Progress

```json
{
  "_id": ObjectId("..."),
  "PK": "USER#u_12345",
  "SK": "AFFIRMATION#PROGRESS",
  "EntityType": "AFFIRMATION_PROGRESS",
  "TenantId": "DEFAULT",
  "ModifiedAt": "2026-04-08T07:15:00Z",
  "totalRead": 142,
  "totalFavorites": 12,
  "totalCustomCreated": 3,
  "categoryBreakdown": {
    "identity": 35,
    "strength": 28,
    "recovery": 30,
    "purity": 15,
    "freedom": 12,
    "surrender": 10,
    "courage": 8,
    "hope": 4,
    "family": 0,
    "healthySexuality": 0
  },
  "levelBreakdown": {
    "1": 80,
    "2": 50,
    "3": 12
  }
}
```

---

## 5. Indexes

| Index Name | Fields | Type | Purpose |
|------------|--------|------|---------|
| Pack primary | `{ PK: 1, SK: 1 }` | Compound (unique) | Get affirmation by pack + ID; list affirmations in pack |
| Pack by category | `{ PK: 1, category: 1 }` | Compound | Filter affirmations by category within a pack |
| Pack by level | `{ PK: 1, level: 1 }` | Compound | Filter affirmations by level within a pack |
| User favorites | `{ PK: 1, SK: 1 }` | Primary | List user's favorited affirmations (SK prefix `AFFIRMATION#FAVORITE#`) |
| User custom | `{ PK: 1, SK: 1 }` | Primary | List user's custom affirmations (SK prefix `AFFIRMATION#CUSTOM#`) |
| Read history by date | `{ PK: 1, calendarDate: 1 }` | Compound | Read history for calendar/progress queries |
| Tenant | `{ TenantId: 1 }` | Single | Tenant admin queries |
| Full-text search | `{ statement: "text" }` | Text | Search affirmation text |

### Index Definitions

```javascript
// Pack content indexes
db.affirmations.createIndex(
  { "PK": 1, "SK": 1 },
  { unique: true, name: "pk_sk_unique" }
);

db.affirmations.createIndex(
  { "PK": 1, "category": 1 },
  { name: "pk_category" }
);

db.affirmations.createIndex(
  { "PK": 1, "level": 1 },
  { name: "pk_level" }
);

// Full-text search
db.affirmations.createIndex(
  { "statement": "text", "tags": "text" },
  { name: "statement_tags_text_search", default_language: "english" }
);

// User state: read history by date
db.affirmationReads.createIndex(
  { "PK": 1, "calendarDate": 1 },
  { name: "pk_calendarDate" }
);

// Tenant isolation
db.affirmations.createIndex(
  { "TenantId": 1 },
  { name: "tenantId" }
);
```

---

## 6. Access Patterns

| # | Access Pattern | Query | Index | Consistency |
|---|---------------|-------|-------|-------------|
| AP1 | List affirmations in pack | `find({ PK: "PACK#pack_001", SK: { $regex: "^AFFIRMATION#" } }).sort({ sortOrder: 1 })` | Primary | Primary |
| AP2 | Get affirmation by ID | `findOne({ PK: "PACK#pack_001", SK: "AFFIRMATION#aff_001" })` | Primary | Primary |
| AP3 | Filter by category in pack | `find({ PK: "PACK#pack_001", category: "identity" })` | Category | Primary |
| AP4 | Filter by level in pack | `find({ PK: "PACK#pack_001", level: 1 })` | Level | Primary |
| AP5 | Filter by level and category | `find({ PK: "PACK#pack_001", level: { $lte: 2 }, category: "recovery" })` | Level + Category | Primary |
| AP6 | Get today's affirmation | Computed: rotation state + owned packs + level gating | Multiple | Primary |
| AP7 | List user favorites | `find({ PK: "USER#u_12345", SK: { $regex: "^AFFIRMATION#FAVORITE#" } })` | Primary | Primary |
| AP8 | Toggle favorite | `insertOne / deleteOne({ PK: "USER#u_12345", SK: "AFFIRMATION#FAVORITE#aff_001" })` | Primary | Primary |
| AP9 | List custom affirmations | `find({ PK: "USER#u_12345", SK: { $regex: "^AFFIRMATION#CUSTOM#" } })` | Primary | Primary |
| AP10 | Create custom affirmation | `insertOne({ PK: "USER#u_12345", SK: "AFFIRMATION#CUSTOM#caff_001", ... })` | Primary | Primary |
| AP11 | Update custom affirmation | `updateOne({ PK: "USER#u_12345", SK: "AFFIRMATION#CUSTOM#caff_001" }, { $set: ... })` | Primary | Primary |
| AP12 | Delete custom affirmation | `deleteOne({ PK: "USER#u_12345", SK: "AFFIRMATION#CUSTOM#caff_001" })` | Primary | Primary |
| AP13 | Get rotation state | `findOne({ PK: "USER#u_12345", SK: "AFFIRMATION#ROTATION_STATE" })` | Primary | Primary |
| AP14 | Update rotation state | `updateOne({ PK: "USER#u_12345", SK: "AFFIRMATION#ROTATION_STATE" }, { $set: ... })` | Primary | Primary |
| AP15 | Record affirmation read | `insertOne({ PK: "USER#u_12345", SK: "AFFIRMATION#READ#2026-04-08", ... })` | Primary | Primary |
| AP16 | Get read history (date range) | `find({ PK: "USER#u_12345", calendarDate: { $gte: "2026-04-01", $lte: "2026-04-30" } })` | Read Date | Primary |
| AP17 | Get cumulative progress | `findOne({ PK: "USER#u_12345", SK: "AFFIRMATION#PROGRESS" })` | Primary | Primary |
| AP18 | Update cumulative progress | `updateOne({ PK: "USER#u_12345", SK: "AFFIRMATION#PROGRESS" }, { $inc: { totalRead: 1 } })` | Primary | Primary |
| AP19 | Full-text search | `find({ PK: "PACK#pack_001", $text: { $search: "freedom" } })` | Text | Primary |
| AP20 | Count custom affirmations | `countDocuments({ PK: "USER#u_12345", EntityType: "CUSTOM_AFFIRMATION" })` | Primary | Primary |
| AP21 | Get contextual affirmation (trigger) | `find({ PK: "PACK#pack_001", tags: "trigger_emotional", level: { $lte: userLevel } })` | Primary | Primary |

---

## 7. Calendar Activity Dual-Write

Following the established calendarActivities pattern, each affirmation read creates a corresponding calendar activity:

```json
{
  "PK": "USER#u_12345",
  "SK": "ACTIVITY#2026-04-08#AFFIRMATION#2026-04-08T07:15:00Z",
  "EntityType": "CALENDAR_ACTIVITY",
  "activityType": "AFFIRMATION",
  "summary": {
    "affirmationId": "aff_023",
    "category": "recovery",
    "source": "daily"
  },
  "sourceKey": "AFFIRMATION#READ#2026-04-08"
}
```

---

## 8. Document Size Estimates

| Scenario | Estimated Size |
|----------|---------------|
| System affirmation (all fields) | ~600 B |
| System affirmation (minimal) | ~300 B |
| Custom affirmation | ~350 B |
| Favorite record | ~200 B |
| Read record | ~250 B |
| Rotation state | ~500 B |
| Cumulative progress | ~400 B |

**Per-user annual estimate** (1 read/day, 5 favorites, 3 custom): ~365 reads x 250 B + 5 x 200 B + 3 x 350 B + 500 B + 400 B = ~94 KB/year

---

## 9. Caching Strategy

| Data | Cache | TTL | Invalidation |
|------|-------|-----|--------------|
| Pack metadata | Valkey | 1 hour | On pack content update |
| Affirmations in pack (by level) | Valkey | 1 hour | On pack content update |
| User favorites list | Valkey | 5 minutes | On favorite toggle |
| Today's affirmation | Valkey | Until midnight user TZ | On manual override or rotation change |
| Rotation state | Valkey | 5 minutes | On mode change or affirmation delivery |
| Cumulative progress | Valkey | 5 minutes | On new read |

Cache keys: `affirmation:{packId}:meta`, `affirmation:{packId}:level:{n}`, `affirmation:{userId}:favorites`, `affirmation:{userId}:today`, `affirmation:{userId}:rotation`, `affirmation:{userId}:progress`

---

## 10. Security and Privacy

- **Tenant isolation:** All queries include `TenantId` filter at the application layer
- **User scoping:** User-created content scoped by `PK = USER#{userId}` -- no cross-user access
- **Custom affirmations are private:** Never shared with support network, never visible to community
- **System content read-only:** System affirmation packs are immutable from user perspective (admin-only updates)
- **Healthy Sexuality gating:** Server enforces 60+ day AND opt-in requirement; cannot be bypassed by client
- **Post-relapse protection:** Server enforces Level 1 restriction for 24 hours after sobriety reset
- **Offline sync:** LWW for favorites and rotation state; read history uses union merge
