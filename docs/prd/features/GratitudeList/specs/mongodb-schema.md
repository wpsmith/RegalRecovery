# Gratitude List: MongoDB Collection Design

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft
**Traces to:** Gratitude_List_Activity.md, specs/01-data-model.md, docs/specs/mongodb/schema-design.md

---

## 1. Overview

The Gratitude List feature extends the existing MongoDB document-based schema. Gratitude entries are stored in the main collection following the established PK/SK pattern with `userId` as the primary key. The existing entity 4.11 (Gratitude Entry) in the schema-design.md stores a simple `content` string -- this design replaces it with structured items, categories, and metadata.

---

## 2. Collection: `gratitudeEntries`

### Document Structure

```json
{
  "_id": ObjectId("..."),
  "PK": "USER#u_12345",
  "SK": "GRATITUDE#2026-04-07T07:00:00Z",
  "EntityType": "GRATITUDE",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-04-07T07:00:00Z",
  "ModifiedAt": "2026-04-07T07:05:00Z",
  "gratitudeId": "g_88888",
  "items": [
    {
      "itemId": "gi_001",
      "text": "Grateful for 47 days of sobriety",
      "category": "recovery",
      "isFavorite": false,
      "sortOrder": 0
    },
    {
      "itemId": "gi_002",
      "text": "My sponsor's patience and wisdom",
      "category": "relationships",
      "isFavorite": true,
      "sortOrder": 1
    },
    {
      "itemId": "gi_003",
      "text": "Morning coffee in the quiet",
      "category": "smallMoments",
      "isFavorite": false,
      "sortOrder": 2
    }
  ],
  "moodScore": 4,
  "photoKey": null,
  "promptUsed": null,
  "calendarDate": "2026-04-07"
}
```

### Field Reference

| Field | Type | Required | Immutable | Description |
|-------|------|----------|-----------|-------------|
| `PK` | String | Yes | Yes | `USER#{userId}` -- owner partition key |
| `SK` | String | Yes | Yes | `GRATITUDE#{ISO8601 timestamp}` -- sort key for chronological ordering |
| `EntityType` | String | Yes | Yes | Always `"GRATITUDE"` |
| `TenantId` | String | Yes | Yes | Tenant identifier for multi-tenant isolation |
| `CreatedAt` | Date | Yes | Yes | Immutable creation timestamp (FR2.7) |
| `ModifiedAt` | Date | Yes | No | Updated on every write |
| `gratitudeId` | String | Yes | Yes | Unique entry ID (`g_{alphanumeric}`) |
| `items` | Array | Yes | No | Ordered list of gratitude items (min 1) |
| `items[].itemId` | String | Yes | Yes | Unique item ID (`gi_{alphanumeric}`) |
| `items[].text` | String | Yes | No | Gratitude text (1-300 chars) |
| `items[].category` | String | No | No | Category enum value or null |
| `items[].isFavorite` | Boolean | Yes | No | Individual favorite flag |
| `items[].sortOrder` | Integer | Yes | No | Display order (0-based) |
| `moodScore` | Integer | No | No | Optional mood 1-5 or null |
| `photoKey` | String | No | No | S3 key for attached photo or null |
| `promptUsed` | String | No | No | Prompt text used for inspiration or null |
| `calendarDate` | String | Yes | Yes | `YYYY-MM-DD` extracted from timestamp for calendar queries |

### Constraints

- `items` array minimum length: 1
- `items[].text` maximum length: 300 characters
- `moodScore` range: 1-5 inclusive (or null)
- `category` enum: `faithGod`, `family`, `relationships`, `health`, `recovery`, `workCareer`, `natureBeauty`, `smallMoments`, `growthProgress`, `custom`
- `CreatedAt` is immutable -- updates cannot modify it
- Edit window: updates allowed only when `now - CreatedAt < 24 hours`

---

## 3. Indexes

| Index Name | Fields | Type | Purpose |
|------------|--------|------|---------|
| Primary (PK/SK) | `{ PK: 1, SK: 1 }` | Compound (unique) | Get entry by user + timestamp; list entries for user |
| Calendar Date | `{ PK: 1, calendarDate: 1 }` | Compound | Calendar view: find entries by date; streak calculation |
| Favorites | `{ PK: 1, "items.isFavorite": 1 }` | Compound | List favorited items for a user |
| Full-text Search | `{ "items.text": "text" }` | Text | Full-text search across gratitude item text |
| Tenant | `{ TenantId: 1 }` | Single | Tenant admin queries |

### Index Definitions

```javascript
// Primary key (already exists in single-table pattern)
db.gratitudeEntries.createIndex(
  { "PK": 1, "SK": 1 },
  { unique: true, name: "pk_sk_unique" }
);

// Calendar date index for calendar view and streak calculation
db.gratitudeEntries.createIndex(
  { "PK": 1, "calendarDate": 1 },
  { name: "pk_calendarDate" }
);

// Favorites index
db.gratitudeEntries.createIndex(
  { "PK": 1, "items.isFavorite": 1 },
  { name: "pk_favorites" }
);

// Full-text search index on item text
db.gratitudeEntries.createIndex(
  { "items.text": "text" },
  { name: "items_text_search", default_language: "english" }
);

// Tenant isolation index
db.gratitudeEntries.createIndex(
  { "TenantId": 1 },
  { name: "tenantId" }
);
```

---

## 4. Access Patterns

| # | Access Pattern | Query | Index | Consistency |
|---|---------------|-------|-------|-------------|
| AP1 | Create gratitude entry | `insertOne({ PK, SK, ... })` | Primary | Primary |
| AP2 | Get entry by ID | `findOne({ PK: "USER#u_12345", gratitudeId: "g_88888" })` | Primary | Primary |
| AP3 | List entries (reverse chronological) | `find({ PK: "USER#u_12345", SK: { $regex: "^GRATITUDE#" } }).sort({ SK: -1 }).limit(N)` | Primary | Primary |
| AP4 | List entries by date range | `find({ PK: "USER#u_12345", SK: { $gte: "GRATITUDE#2026-03-01", $lte: "GRATITUDE#2026-03-31~" } })` | Primary | Primary |
| AP5 | Get entries for a specific calendar date | `find({ PK: "USER#u_12345", calendarDate: "2026-04-07" })` | Calendar Date | Primary |
| AP6 | Get calendar indicators for a month | `aggregate([{ $match: { PK: "USER#u_12345", calendarDate: { $gte: "2026-04-01", $lte: "2026-04-30" } } }, { $group: { _id: "$calendarDate", entryCount: { $sum: 1 } } }])` | Calendar Date | Primary |
| AP7 | Streak calculation (unique dates) | `distinct("calendarDate", { PK: "USER#u_12345" })` | Calendar Date | Primary |
| AP8 | Full-text search | `find({ PK: "USER#u_12345", $text: { $search: "sobriety" } })` | Text | Primary |
| AP9 | List favorited items | `find({ PK: "USER#u_12345", "items.isFavorite": true })` with projection | Favorites | Primary |
| AP10 | Update entry (within 24h) | `updateOne({ PK, SK, CreatedAt: { $gte: cutoff } }, { $set: { items, moodScore, photoKey, ModifiedAt } })` | Primary | Primary |
| AP11 | Toggle item favorite | `updateOne({ PK, gratitudeId, "items.itemId": "gi_001" }, { $set: { "items.$.isFavorite": true, ModifiedAt } })` | Primary | Primary |
| AP12 | Delete entry (within 24h) | `deleteOne({ PK, SK, CreatedAt: { $gte: cutoff } })` | Primary | Primary |
| AP13 | Category breakdown (aggregation) | `aggregate([{ $match: { PK, calendarDate: { $gte, $lte } } }, { $unwind: "$items" }, { $group: { _id: "$items.category", count: { $sum: 1 } } }])` | Calendar Date | Primary |
| AP14 | Average items per entry | `aggregate([{ $match: { PK, calendarDate range } }, { $project: { itemCount: { $size: "$items" } } }, { $group: { _id: null, avg: { $avg: "$itemCount" } } }])` | Calendar Date | Primary |
| AP15 | Today's completion check (widget) | `findOne({ PK: "USER#u_12345", calendarDate: "2026-04-07" })` | Calendar Date | Primary |
| AP16 | Filter by category | `find({ PK: "USER#u_12345", "items.category": "recovery" })` | Primary | Primary |
| AP17 | Filter by mood score | `find({ PK: "USER#u_12345", moodScore: 4 })` | Primary | Primary |
| AP18 | Filter by has photo | `find({ PK: "USER#u_12345", photoKey: { $ne: null } })` | Primary | Primary |

---

## 5. Calendar Activity Dual-Write

Following the established calendarActivities pattern (entity 4.48), each gratitude entry creates a corresponding calendar activity document:

```json
{
  "PK": "USER#u_12345",
  "SK": "ACTIVITY#2026-04-07#GRATITUDE#2026-04-07T07:00:00Z",
  "EntityType": "CALENDAR_ACTIVITY",
  "activityType": "GRATITUDE",
  "summary": {
    "itemCount": 3,
    "categories": ["recovery", "relationships", "smallMoments"],
    "moodScore": 4
  },
  "sourceKey": "GRATITUDE#2026-04-07T07:00:00Z"
}
```

This dual-write enables the calendar view to include gratitude entries alongside other activities in a single query.

---

## 6. Document Size Estimates

| Scenario | Items | Estimated Size |
|----------|-------|---------------|
| Minimal entry (1 item, no optional fields) | 1 | ~250 B |
| Typical entry (3 items, mood, no photo) | 3 | ~500 B |
| Rich entry (5 items, mood, category tags, prompt) | 5 | ~800 B |
| Maximum reasonable entry (10 items, all fields) | 10 | ~1.5 KB |

**Per-user annual estimate** (1 entry/day, avg 3 items): ~365 entries x ~500 B = ~178 KB/year

This is well within MongoDB's 16 MB document limit and adds minimal storage overhead.

---

## 7. Caching Strategy

| Data | Cache | TTL | Invalidation |
|------|-------|-----|--------------|
| Current streak | Valkey | 5 minutes | On new entry creation or deletion |
| Widget data (today status, streak, random item) | Valkey | 5 minutes | On new entry creation |
| Calendar month data | Valkey | 10 minutes | On new entry creation for that month |

Cache keys follow the pattern: `gratitude:{userId}:{dataType}` (e.g., `gratitude:u_12345:streak`, `gratitude:u_12345:widget`, `gratitude:u_12345:calendar:2026-04`).

---

## 8. Migration from Legacy Schema

The existing schema-design.md entity 4.11 stores gratitude as a simple `content` string:

```json
{
  "PK": "USER#u_12345",
  "SK": "GRATITUDE#2026-03-28T07:00:00Z",
  "gratitudeId": "g_88888",
  "content": "Grateful for 47 days of sobriety and my sponsor's patience."
}
```

### Migration Strategy

1. **Read old format:** Detect documents with `content` (string) instead of `items` (array)
2. **Convert:** Split `content` into a single `GratitudeItem`:
   ```json
   {
     "items": [
       {
         "itemId": "gi_{generated}",
         "text": "{original content, truncated to 300 chars}",
         "category": null,
         "isFavorite": false,
         "sortOrder": 0
       }
     ],
     "moodScore": null,
     "photoKey": null,
     "promptUsed": null,
     "calendarDate": "{extracted from SK timestamp}"
   }
   ```
3. **Backfill:** Run bulk update to add new fields and `calendarDate` index field
4. **Dual-write:** Application writes both old and new format during transition
5. **Cutover:** Remove old `content` field reads after all clients updated
6. **Cleanup:** Remove `content` field from migrated documents

### Migration Script (pseudocode)

```javascript
db.collection.find({ EntityType: "GRATITUDE", items: { $exists: false } }).forEach(doc => {
  const calendarDate = doc.SK.replace("GRATITUDE#", "").substring(0, 10);
  db.collection.updateOne(
    { _id: doc._id },
    {
      $set: {
        items: [{
          itemId: "gi_" + ObjectId().toString().substring(0, 8),
          text: (doc.content || "").substring(0, 300),
          category: null,
          isFavorite: false,
          sortOrder: 0
        }],
        moodScore: null,
        photoKey: null,
        promptUsed: null,
        calendarDate: calendarDate,
        ModifiedAt: new Date().toISOString()
      },
      $unset: { content: "" }
    }
  );
});
```

---

## 9. Security and Privacy

- **Tenant isolation:** All queries include `TenantId` filter at the application layer
- **User scoping:** All queries are scoped by `PK = USER#{userId}` -- no cross-user access
- **Community permissions:** Gratitude text visible to spouse/counselor if permissions granted; mood, category, and photo metadata NEVER shared
- **Audit trail:** Data access by support network contacts logged as AUDIT entries per entity 4.47
- **Offline sync:** Union merge for new entries; LWW (last-writer-wins) for edits to existing entries
