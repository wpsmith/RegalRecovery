# Acting In Behaviors -- MongoDB Schema Design

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft

---

## Overview

The Acting In Behaviors feature requires four document types stored across existing collections, following the project's collection-per-entity and user-centric design principles. All documents carry standard common fields (`_id`, `userId`, `entityType`, `createdAt`, `modifiedAt`, `tenantId`).

---

## 1. Acting-In Behavior Configuration

**Collection:** `actingInBehaviors`
**Description:** User-scoped behavior catalog (enabled/disabled defaults + custom behaviors). One document per user.

### Document Structure

```json
{
  "PK": "USER#u_12345",
  "SK": "ACTINGIN_CONFIG",
  "EntityType": "ACTINGIN_CONFIG",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T10:00:00Z",
  "ModifiedAt": "2026-04-01T14:00:00Z",
  "defaults": {
    "beh_default_blame":          { "enabled": true, "sortOrder": 1 },
    "beh_default_shame":          { "enabled": true, "sortOrder": 2 },
    "beh_default_criticism":      { "enabled": true, "sortOrder": 3 },
    "beh_default_stonewall":      { "enabled": true, "sortOrder": 4 },
    "beh_default_avoid":          { "enabled": true, "sortOrder": 5 },
    "beh_default_hide":           { "enabled": true, "sortOrder": 6 },
    "beh_default_lie":            { "enabled": true, "sortOrder": 7 },
    "beh_default_excuse":         { "enabled": true, "sortOrder": 8 },
    "beh_default_manipulate":     { "enabled": true, "sortOrder": 9 },
    "beh_default_control_anger":  { "enabled": true, "sortOrder": 10 },
    "beh_default_passivity":      { "enabled": true, "sortOrder": 11 },
    "beh_default_humor":          { "enabled": false, "sortOrder": 12 },
    "beh_default_placating":      { "enabled": true, "sortOrder": 13 },
    "beh_default_withhold":       { "enabled": true, "sortOrder": 14 },
    "beh_default_hyperspiritualize": { "enabled": true, "sortOrder": 15 }
  },
  "customBehaviors": [
    {
      "behaviorId": "beh_custom_001",
      "name": "Sarcasm Deflection",
      "description": "Using sharp humor to avoid vulnerability",
      "enabled": true,
      "sortOrder": 16,
      "createdAt": "2026-03-29T09:00:00Z"
    }
  ]
}
```

### Access Patterns

| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| Get user's behavior config | findOne | PK=`USER#<userId>`, SK=`ACTINGIN_CONFIG` | Primary |

### Design Notes

- Single document per user keeps all behavior configuration in one read.
- Default behaviors are stored as a map (not array) for O(1) toggle lookups.
- Custom behaviors are an embedded array since users will have few (< 50).
- System default behavior names and descriptions are stored in application code, not in the database. The database only stores user-level overrides (enabled/disabled state).
- Estimated document size: ~1.5 KB (well under 16 MB limit).

---

## 2. Acting-In Check-In Entry

**Collection:** Main user-scoped collection (single-table)
**Description:** Individual check-in records. One document per check-in submission.

### Document Structure

```json
{
  "PK": "USER#u_12345",
  "SK": "ACTINGIN_CHECKIN#2026-03-28T21:00:00Z",
  "EntityType": "ACTINGIN_CHECKIN",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T21:00:00Z",
  "ModifiedAt": "2026-03-28T21:00:00Z",
  "checkInId": "aic_11111",
  "timestamp": "2026-03-28T21:00:00Z",
  "behaviorCount": 2,
  "behaviors": [
    {
      "behaviorId": "beh_default_stonewall",
      "behaviorName": "Stonewall",
      "contextNote": "Shut down after argument about finances",
      "trigger": "conflict",
      "relationshipTag": "spouse"
    },
    {
      "behaviorId": "beh_default_avoid",
      "behaviorName": "Avoid",
      "contextNote": "Avoided sponsor's call",
      "trigger": "shame",
      "relationshipTag": "sponsor"
    }
  ],
  "triggers": ["conflict", "shame"],
  "relationshipTags": ["spouse", "sponsor"]
}
```

### Indexes

| Index | Fields | Purpose |
|-------|--------|---------|
| Primary | `{ PK: 1, SK: 1 }` | All access patterns below |
| Behavior filter | Application-level | Filter within query results by `behaviors.behaviorId` |

### Access Patterns

| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| Get recent check-ins | find | PK=`USER#<userId>`, SK begins_with `ACTINGIN_CHECKIN#`, sort descending | Primary |
| Get check-ins by date range | find | PK=`USER#<userId>`, SK between `ACTINGIN_CHECKIN#<start>` and `ACTINGIN_CHECKIN#<end>` | Primary |
| Get check-in by ID | find | PK=`USER#<userId>`, SK begins_with `ACTINGIN_CHECKIN#`, filter `checkInId=aic_11111` | Primary |
| Filter by behavior | find + filter | PK=`USER#<userId>`, SK begins_with `ACTINGIN_CHECKIN#`, filter `behaviors.behaviorId` | Primary |
| Filter by trigger | find + filter | PK=`USER#<userId>`, SK begins_with `ACTINGIN_CHECKIN#`, filter `triggers` array contains | Primary |
| Filter by relationship | find + filter | PK=`USER#<userId>`, SK begins_with `ACTINGIN_CHECKIN#`, filter `relationshipTags` array contains | Primary |

### Calendar Activity Dual-Write

Each check-in also writes to the `calendarActivities` collection:

```json
{
  "PK": "USER#u_12345",
  "SK": "ACTIVITY#2026-03-28#ACTINGIN_CHECKIN#2026-03-28T21:00:00Z",
  "EntityType": "CALENDAR_ACTIVITY",
  "activityType": "ACTINGIN_CHECKIN",
  "summary": { "behaviorCount": 2 },
  "sourceKey": "ACTINGIN_CHECKIN#2026-03-28T21:00:00Z"
}
```

### Design Notes

- `behaviorName` is denormalized into each check-in entry to preserve the name at the time of logging, even if the custom behavior is later renamed or deleted.
- `triggers` and `relationshipTags` are top-level arrays (denormalized from the embedded behaviors) to support efficient filtering.
- Timestamps are immutable per FR2.7.
- Estimated document size: ~500 B (zero behaviors) to ~3 KB (15+ behaviors with notes).

---

## 3. Acting-In Settings

**Collection:** Main user-scoped collection (single-table)
**Description:** User's frequency, reminder, and first-use preferences.

### Document Structure

```json
{
  "PK": "USER#u_12345",
  "SK": "ACTINGIN_SETTINGS",
  "EntityType": "ACTINGIN_SETTINGS",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T10:00:00Z",
  "ModifiedAt": "2026-04-01T14:00:00Z",
  "frequency": "daily",
  "reminderTime": "21:00",
  "reminderDay": "sunday",
  "firstUseCompleted": true,
  "streakCount": 14,
  "lastCheckInAt": "2026-04-06T21:00:00Z"
}
```

### Access Patterns

| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| Get acting-in settings | findOne | PK=`USER#<userId>`, SK=`ACTINGIN_SETTINGS` | Primary |

### Design Notes

- `streakCount` and `lastCheckInAt` are maintained server-side on each check-in submission.
- When frequency changes, `streakCount` is recalculated based on the new cadence.
- Estimated document size: ~300 B.

---

## 4. Insights Cache (Optional Materialized View)

**Collection:** `actingInInsights` (optional, for performance)
**Description:** Pre-computed insights refreshed daily by a scheduled Lambda.

### Document Structure

```json
{
  "PK": "USER#u_12345",
  "SK": "INSIGHTS#30d",
  "EntityType": "ACTINGIN_INSIGHTS",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-04-07T00:00:00Z",
  "ModifiedAt": "2026-04-07T00:00:00Z",
  "range": "30d",
  "frequencyData": [
    { "behaviorId": "beh_default_stonewall", "count": 12, "trend": "decreasing" },
    { "behaviorId": "beh_default_avoid", "count": 8, "trend": "stable" }
  ],
  "triggerData": [
    { "trigger": "stress", "count": 15, "topBehaviors": ["beh_default_stonewall", "beh_default_avoid"] }
  ],
  "relationshipData": [
    { "relationshipTag": "spouse", "count": 10, "trend": "decreasing" }
  ],
  "heatmapData": [
    { "dayOfWeek": 1, "hourOfDay": 21, "count": 5, "intensity": 0.8 }
  ],
  "expiresAt": 1777987200
}
```

### Access Patterns

| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| Get cached insights | findOne | PK=`USER#<userId>`, SK=`INSIGHTS#<range>` | Primary |

### Design Notes

- TTL-based expiry (24 hours) ensures insights are refreshed daily.
- If cache miss, insights are computed on-the-fly from check-in data and cached.
- Valkey cache-aside layer in front of this for hot reads (5-minute TTL).
- Estimated document size: ~2 KB.

---

## Document Size Estimates

| Entity | Avg. Size | Frequency per User per Day |
|--------|-----------|---------------------------|
| Behavior Config | 1.5 KB | -- (1 per user) |
| Check-In Entry | 1 KB | 0-1 (daily) or 0-1 per week |
| Settings | 300 B | -- (1 per user) |
| Insights Cache | 2 KB | -- (3 per user: 7d, 30d, 90d) |
| Calendar Activity | 250 B | 0-1 (mirror of check-in) |

### Estimated Storage per User at 1 Year

- Config: 1.5 KB (static)
- Settings: 300 B (static)
- Check-ins (daily): 365 x 1 KB = 365 KB
- Calendar mirrors: 365 x 250 B = 91 KB
- Insights cache: 3 x 2 KB = 6 KB (ephemeral)
- **Total per user per year: ~464 KB**

---

## Access Pattern Summary (added to global matrix)

| # | Access Pattern | Collection | Query | Operation |
|---|---------------|------------|-------|-----------|
| 56 | Get acting-in behavior config | Table | PK=`USER#<userId>`, SK=`ACTINGIN_CONFIG` | findOne |
| 57 | Get acting-in settings | Table | PK=`USER#<userId>`, SK=`ACTINGIN_SETTINGS` | findOne |
| 58 | Get recent acting-in check-ins | Table | PK=`USER#<userId>`, SK begins_with `ACTINGIN_CHECKIN#` | Query (desc) |
| 59 | Get acting-in check-ins by date range | Table | PK=`USER#<userId>`, SK between `ACTINGIN_CHECKIN#<start>` and `ACTINGIN_CHECKIN#<end>` | find |
| 60 | Get cached acting-in insights | Table | PK=`USER#<userId>`, SK=`INSIGHTS#<range>` | findOne |
