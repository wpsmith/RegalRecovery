# Nutrition Activity -- MongoDB Schema Design

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft

---

## Overview

The Nutrition activity uses three document types within the existing `regal-recovery` database, following the project's collection-per-entity and user-centric patterns. All documents carry the standard common fields (`_id`, `userId`, `entityType`, `createdAt`, `modifiedAt`, `tenantId`).

---

## 1. Collections

### 1.1 Meal Log (`mealLogs`)

**Entity Type:** `MEAL`
**Sort Key Pattern:** `MEAL#<ISO8601 timestamp>`

**Document Structure:**

```json
{
  "PK": "USER#u_12345",
  "SK": "MEAL#2026-03-28T12:00:00Z",
  "EntityType": "MEAL",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T12:00:05Z",
  "ModifiedAt": "2026-03-28T12:00:05Z",
  "mealId": "ml_11111",
  "mealType": "lunch",
  "customMealLabel": null,
  "description": "Grilled chicken salad with water",
  "eatingContext": "homemade",
  "moodBefore": 3,
  "moodAfter": 4,
  "mindfulnessCheck": "somewhat",
  "notes": "Felt better after eating. Was hungrier than I realized.",
  "isQuickLog": false
}
```

**Field Reference:**

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `mealId` | String | Yes | `ml_` prefix + random | Unique meal log identifier |
| `mealType` | String | Yes | Enum: `breakfast`, `lunch`, `dinner`, `snack`, `other` | Meal category |
| `customMealLabel` | String | No | Max 50 chars | Custom label when mealType is "other" |
| `description` | String | Yes* | Max 300 chars | Natural language meal description. *Null for unexpanded quick logs. |
| `eatingContext` | String | No | Enum: `homemade`, `takeout`, `on-the-go`, `meal-prepped`, `skipped`, `social`, `alone` | Where/how the meal happened |
| `moodBefore` | Integer | No | 1-5 | Emotional state before eating |
| `moodAfter` | Integer | No | 1-5 | Emotional state after eating |
| `mindfulnessCheck` | String | No | Enum: `yes`, `somewhat`, `no` | Whether user ate mindfully |
| `notes` | String | No | Max 500 chars | Free-text notes |
| `isQuickLog` | Boolean | Yes | Default: false | Whether created via quick-log |

**Immutability:** The `SK` timestamp and `CreatedAt` are immutable after creation per FR2.7.

### 1.2 Hydration Log (`hydrationLogs`)

**Entity Type:** `HYDRATION`
**Sort Key Pattern:** `HYDRATION#<YYYY-MM-DD>`

One document per user per day. Updated in-place when servings are added/removed.

**Document Structure:**

```json
{
  "PK": "USER#u_12345",
  "SK": "HYDRATION#2026-03-28",
  "EntityType": "HYDRATION",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T08:00:00Z",
  "ModifiedAt": "2026-03-28T14:30:00Z",
  "date": "2026-03-28",
  "servingsLogged": 5,
  "servingSizeOz": 8,
  "totalOunces": 40,
  "dailyTargetServings": 8,
  "goalMet": false,
  "entries": [
    { "timestamp": "2026-03-28T08:00:00Z", "servings": 1, "action": "add" },
    { "timestamp": "2026-03-28T10:30:00Z", "servings": 2, "action": "add" },
    { "timestamp": "2026-03-28T12:00:00Z", "servings": 1, "action": "add" },
    { "timestamp": "2026-03-28T14:30:00Z", "servings": 1, "action": "add" }
  ]
}
```

**Field Reference:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `date` | String (YYYY-MM-DD) | Yes | Calendar date for this record |
| `servingsLogged` | Integer | Yes | Current total servings for the day |
| `servingSizeOz` | Number | Yes | Serving size in effect when created |
| `totalOunces` | Number | Yes | servingsLogged * servingSizeOz |
| `dailyTargetServings` | Integer | Yes | Target at the start of the day |
| `goalMet` | Boolean | Yes | servingsLogged >= dailyTargetServings |
| `entries` | Array | Yes | Individual log actions for auditability |

**Design Note:** A single daily document avoids high-frequency writes creating many small documents. The `entries` array provides auditability. Max document size is well within MongoDB's 16 MB limit (~365 entries/day maximum at ~100 bytes each = ~36 KB).

### 1.3 Nutrition Settings (`nutritionSettings`)

**Entity Type:** `NUTRITION_SETTINGS`
**Sort Key Pattern:** `NUTRITION_SETTINGS`

One document per user. Created with defaults on first nutrition activity use.

**Document Structure:**

```json
{
  "PK": "USER#u_12345",
  "SK": "NUTRITION_SETTINGS",
  "EntityType": "NUTRITION_SETTINGS",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-01T10:00:00Z",
  "ModifiedAt": "2026-03-28T14:00:00Z",
  "hydration": {
    "servingSizeOz": 8,
    "dailyTargetServings": 8
  },
  "mealReminders": {
    "breakfast": { "enabled": false, "time": "08:00" },
    "lunch": { "enabled": false, "time": "12:00" },
    "dinner": { "enabled": false, "time": "18:00" }
  },
  "hydrationReminders": {
    "enabled": false,
    "intervalHours": 2
  },
  "missedMealNudge": {
    "enabled": false,
    "nudgeTime": "14:00"
  },
  "insightPreferences": {
    "mealConsistencyEnabled": true,
    "emotionalEatingEnabled": true,
    "mindfulnessEnabled": true,
    "crossDomainEnabled": true
  }
}
```

---

## 2. Calendar Activity Dual-Write

When a meal log is created, a corresponding calendar activity entry is also written to the `calendarActivities` collection:

```json
{
  "PK": "USER#u_12345",
  "SK": "ACTIVITY#2026-03-28#NUTRITION#2026-03-28T12:00:00Z",
  "EntityType": "CALENDAR_ACTIVITY",
  "activityType": "NUTRITION",
  "summary": {
    "mealType": "lunch",
    "mealId": "ml_11111",
    "hasDescription": true
  },
  "sourceKey": "MEAL#2026-03-28T12:00:00Z"
}
```

---

## 3. Indexes

| Collection | Index Name | Fields | Purpose |
|------------|-----------|--------|---------|
| `mealLogs` | `userId_timestamp` | `{ PK: 1, SK: -1 }` (compound, primary) | Chronological queries per user |
| `mealLogs` | `userId_mealType_timestamp` | `{ PK: 1, mealType: 1, SK: -1 }` | Filter by meal type |
| `mealLogs` | `userId_eatingContext_timestamp` | `{ PK: 1, eatingContext: 1, SK: -1 }` | Filter by eating context |
| `mealLogs` | `text_search` | `{ description: "text", notes: "text" }` | Keyword search in descriptions and notes |
| `hydrationLogs` | `userId_date` | `{ PK: 1, SK: 1 }` (compound, primary) | Daily hydration lookup |
| `nutritionSettings` | `userId` | `{ PK: 1, SK: 1 }` (compound, primary) | Settings lookup |

---

## 4. Access Patterns

| # | Access Pattern | Collection | Query | Operation |
|---|---------------|------------|-------|-----------|
| NUT-1 | Create meal log | `mealLogs` | Insert with PK=`USER#<userId>`, SK=`MEAL#<timestamp>` | insertOne |
| NUT-2 | Get meal log by ID | `mealLogs` | PK=`USER#<userId>`, filter `mealId=<mealId>` | findOne |
| NUT-3 | List recent meals | `mealLogs` | PK=`USER#<userId>`, SK begins_with `MEAL#`, sort desc | find (desc) |
| NUT-4 | List meals by date range | `mealLogs` | PK=`USER#<userId>`, SK between `MEAL#<start>` and `MEAL#<end>` | find |
| NUT-5 | Filter meals by type | `mealLogs` | PK=`USER#<userId>`, `mealType=<type>`, SK desc | find (indexed) |
| NUT-6 | Filter meals by context | `mealLogs` | PK=`USER#<userId>`, `eatingContext=<ctx>`, SK desc | find (indexed) |
| NUT-7 | Search meals by keyword | `mealLogs` | PK=`USER#<userId>`, text search on description/notes | find (text) |
| NUT-8 | Update meal log | `mealLogs` | PK=`USER#<userId>`, `mealId=<mealId>` | updateOne |
| NUT-9 | Delete meal log | `mealLogs` | PK=`USER#<userId>`, `mealId=<mealId>` | deleteOne |
| NUT-10 | Get today's hydration | `hydrationLogs` | PK=`USER#<userId>`, SK=`HYDRATION#<today>` | findOne |
| NUT-11 | Log hydration (add/remove) | `hydrationLogs` | PK=`USER#<userId>`, SK=`HYDRATION#<date>` | updateOne (upsert) |
| NUT-12 | Get hydration history (range) | `hydrationLogs` | PK=`USER#<userId>`, SK between `HYDRATION#<start>` and `HYDRATION#<end>` | find |
| NUT-13 | Get nutrition settings | `nutritionSettings` | PK=`USER#<userId>`, SK=`NUTRITION_SETTINGS` | findOne |
| NUT-14 | Update nutrition settings | `nutritionSettings` | PK=`USER#<userId>`, SK=`NUTRITION_SETTINGS` | updateOne (upsert) |
| NUT-15 | Calendar: meals for a day | `calendarActivities` | PK=`USER#<userId>`, SK begins_with `ACTIVITY#<date>#NUTRITION` | find |
| NUT-16 | Calendar: meals for a month | `calendarActivities` | PK=`USER#<userId>`, SK between `ACTIVITY#<month-start>#NUTRITION` and `ACTIVITY#<month-end>#NUTRITION~` | find |
| NUT-17 | Meal count by day (trends) | `mealLogs` | PK=`USER#<userId>`, SK between `MEAL#<start>` and `MEAL#<end>`, aggregation pipeline | aggregate |
| NUT-18 | Mood aggregation (trends) | `mealLogs` | PK=`USER#<userId>`, filter `moodBefore != null`, `moodAfter != null` | aggregate |
| NUT-19 | Eating context distribution | `mealLogs` | PK=`USER#<userId>`, group by `eatingContext` | aggregate |
| NUT-20 | Mindfulness distribution | `mealLogs` | PK=`USER#<userId>`, group by `mindfulnessCheck` | aggregate |

---

## 5. Document Size Estimates

| Entity | Avg. Doc Size | Frequency per User per Day | Notes |
|--------|---------------|---------------------------|-------|
| Meal Log | 400 B | 0-5 | 3 meals + optional snacks |
| Hydration Log | 500 B | 1 (daily) | Single doc updated in-place; entries array grows |
| Nutrition Settings | 400 B | -- | 1 per user |
| Calendar Activity (nutrition) | 250 B | 0-5 | Mirror of meal logs |

**Estimated storage per active user per year:**
- Meal logs: ~3 meals/day x 365 days x 400 B = ~438 KB
- Hydration logs: 365 days x 500 B = ~183 KB
- Calendar activities: ~3/day x 365 x 250 B = ~274 KB
- Settings: ~400 B
- **Total: ~895 KB/user/year**

---

## 6. Data Deletion

- **Account deletion (FR1.4):** Delete all documents where PK matches `USER#<userId>` across `mealLogs`, `hydrationLogs`, `nutritionSettings`, and corresponding `calendarActivities`.
- **Individual entry deletion:** Delete meal log and its corresponding calendar activity entry.
- **No ephemeral mode:** Nutrition logs are not ephemeral. Standard deletion applies.

---

## 7. Offline Sync

- **Conflict resolution for meal logs:** Union merge -- both entries are kept on conflict.
- **Conflict resolution for hydration:** LWW (last-writer-wins) at the daily document level. The `entries` array enables client-side merge if needed.
- **Conflict resolution for settings:** LWW for all settings fields.

---

## Related Documents

- [MongoDB Schema Design (main)](../../../../docs/specs/mongodb/schema-design.md)
- [Nutrition Activity PRD](../Nutrition_Activity.md)
- [OpenAPI Spec](./openapi.yaml)
