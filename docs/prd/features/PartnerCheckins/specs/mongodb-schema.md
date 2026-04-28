# Person Check-ins -- MongoDB Collection Design

**Activity:** Person Check-ins
**Priority:** P1 (Wave 2)
**Feature Flag:** `activity.person-check-ins`

---

## 1. Overview

Person Check-ins use the project's document-based schema pattern with `userId` as the primary key. Three entity types are introduced:

1. **Person Check-in Entry** -- the check-in record itself
2. **Person Check-in Streak** -- per-sub-type streak state (cached in Valkey)
3. **Person Check-in Settings** -- per-sub-type configuration (frequency, alerts, contacts)

Additionally, each check-in triggers a dual-write to the `calendarActivities` collection.

---

## 2. Entity: Person Check-in Entry

### Key Pattern

| Attribute | Pattern |
|-----------|---------|
| PK | `USER#<userId>` |
| SK | `PERSON_CHECKIN#<ISO8601 timestamp>` |

### Indexes

| Index | Fields | Purpose |
|-------|--------|---------|
| Primary (PK+SK) | `{ userId: 1, SK: -1 }` | Get check-ins by user in reverse chronological order |
| Type index | `{ userId: 1, checkInType: 1, timestamp: -1 }` | Filter by sub-type with date ordering |
| Calendar dual-write | Written to `calendarActivities` collection | Calendar view support |

### Example Document

```json
{
  "PK": "USER#u_12345",
  "SK": "PERSON_CHECKIN#2026-03-28T18:30:00Z",
  "EntityType": "PERSON_CHECKIN",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T18:30:00Z",
  "ModifiedAt": "2026-03-28T18:30:00Z",
  "checkInId": "pci_11111",
  "checkInType": "spouse",
  "method": "in-person",
  "contactName": "Sarah",
  "durationMinutes": 30,
  "qualityRating": 4,
  "topicsDiscussed": [
    "relationships-marriage",
    "emotions-feelings",
    "accountability"
  ],
  "notes": "Had a really honest conversation about this week. She appreciated the transparency.",
  "followUpItems": [
    {
      "text": "Schedule a date night for Friday",
      "goalId": null
    },
    {
      "text": "Follow up on the apology from Tuesday",
      "goalId": "goal_55555"
    }
  ],
  "counselorSubCategory": null
}
```

### Quick Log Variant

When created via quick log, optional fields are omitted:

```json
{
  "PK": "USER#u_12345",
  "SK": "PERSON_CHECKIN#2026-03-28T20:00:00Z",
  "EntityType": "PERSON_CHECKIN",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T20:00:00Z",
  "ModifiedAt": "2026-03-28T20:00:00Z",
  "checkInId": "pci_22222",
  "checkInType": "sponsor",
  "method": "phone-call",
  "contactName": "Mike S.",
  "durationMinutes": null,
  "qualityRating": null,
  "topicsDiscussed": [],
  "notes": null,
  "followUpItems": [],
  "counselorSubCategory": null
}
```

### Access Patterns

| # | Pattern | Operation | Query | Sort/Filter | Consistency |
|---|---------|-----------|-------|-------------|-------------|
| 1 | List all person check-ins for user | find | PK=`USER#u_12345`, SK begins_with `PERSON_CHECKIN#` | ScanIndexForward=false | Primary |
| 2 | Get check-ins by date range | find | PK=`USER#u_12345`, SK between `PERSON_CHECKIN#<start>` and `PERSON_CHECKIN#<end>` | -- | Primary |
| 3 | Get check-in by ID | find | PK=`USER#u_12345`, SK begins_with `PERSON_CHECKIN#`, filter `checkInId=pci_11111` | -- | Primary |
| 4 | Filter by sub-type | find (index) | `{ userId, checkInType: "spouse", timestamp: { $gte: ..., $lte: ... } }` | timestamp desc | Primary |
| 5 | Filter by method | find | PK=`USER#u_12345`, SK begins_with `PERSON_CHECKIN#`, filter `method=in-person` | -- | Primary |
| 6 | Filter by quality rating | find | PK=`USER#u_12345`, SK begins_with `PERSON_CHECKIN#`, filter `qualityRating >= N` | -- | Primary |
| 7 | Search notes/follow-ups | find | PK=`USER#u_12345`, SK begins_with `PERSON_CHECKIN#`, text search on `notes` and `followUpItems.text` | -- | Primary |
| 8 | Calendar day view | find (calendarActivities) | PK=`USER#u_12345`, SK begins_with `ACTIVITY#2026-03-28#PERSON_CHECKIN#` | -- | Primary |
| 9 | Calendar month view | find (calendarActivities) | PK=`USER#u_12345`, SK between `ACTIVITY#2026-03-01` and `ACTIVITY#2026-03-31~` | filter activityType=`PERSON_CHECKIN` | Primary |

### Document Size Estimate

| Variant | Avg. Size |
|---------|-----------|
| Quick log (minimal) | 300 B |
| Full entry (all fields) | 800 B |
| Average (weighted) | 500 B |

---

## 3. Entity: Person Check-in Streak

### Key Pattern

| Attribute | Pattern |
|-----------|---------|
| PK | `USER#<userId>` |
| SK | `PERSON_CHECKIN_STREAK#<checkInType>` |

### Example Document

```json
{
  "PK": "USER#u_12345",
  "SK": "PERSON_CHECKIN_STREAK#spouse",
  "EntityType": "PERSON_CHECKIN_STREAK",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-02-01T00:00:00Z",
  "ModifiedAt": "2026-03-28T18:30:00Z",
  "checkInType": "spouse",
  "currentStreak": 5,
  "longestStreak": 21,
  "streakUnit": "days",
  "lastCheckInDate": "2026-03-28",
  "checkInsThisWeek": 4,
  "checkInsThisMonth": 18,
  "averagePerWeek": 4.5
}
```

### Access Patterns

| # | Pattern | Operation | Query | Consistency |
|---|---------|-----------|-------|-------------|
| 1 | Get all person check-in streaks | find | PK=`USER#u_12345`, SK begins_with `PERSON_CHECKIN_STREAK#` | Primary |
| 2 | Get streak by sub-type | findOne | PK=`USER#u_12345`, SK=`PERSON_CHECKIN_STREAK#spouse` | Primary |

### Caching

Streak data is cached in Valkey with a 5-minute TTL:

- **Cache key:** `pci:streak:{userId}:{checkInType}`
- **Invalidation:** On new check-in creation, deletion, or settings change
- **Pattern:** Cache-aside (read from Valkey first; on miss, read from MongoDB, populate cache)

### Document Size Estimate

~250 B per streak document (3 per user = ~750 B total)

---

## 4. Entity: Person Check-in Settings

### Key Pattern

| Attribute | Pattern |
|-----------|---------|
| PK | `USER#<userId>` |
| SK | `PERSON_CHECKIN_SETTINGS` |

### Example Document

```json
{
  "PK": "USER#u_12345",
  "SK": "PERSON_CHECKIN_SETTINGS",
  "EntityType": "PERSON_CHECKIN_SETTINGS",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-02-01T00:00:00Z",
  "ModifiedAt": "2026-03-20T10:00:00Z",
  "spouse": {
    "contactName": "Sarah",
    "streakFrequency": "daily",
    "requiredCountPerWeek": null,
    "inactivityAlertDays": 3,
    "reminderEnabled": false,
    "reminderTime": null,
    "reminderFrequency": null,
    "lastUsedMethod": "in-person"
  },
  "sponsor": {
    "contactName": "Mike S.",
    "streakFrequency": "daily",
    "requiredCountPerWeek": null,
    "inactivityAlertDays": 5,
    "reminderEnabled": true,
    "reminderTime": "09:00",
    "reminderFrequency": "weekly",
    "lastUsedMethod": "phone-call"
  },
  "counselorCoach": {
    "contactName": "Dr. Johnson",
    "streakFrequency": "weekly",
    "requiredCountPerWeek": null,
    "inactivityAlertDays": 10,
    "reminderEnabled": false,
    "reminderTime": null,
    "reminderFrequency": null,
    "lastUsedMethod": "in-person"
  }
}
```

### Access Patterns

| # | Pattern | Operation | Query | Consistency |
|---|---------|-----------|-------|-------------|
| 1 | Get person check-in settings | findOne | PK=`USER#u_12345`, SK=`PERSON_CHECKIN_SETTINGS` | Primary |
| 2 | Update settings | updateOne | PK=`USER#u_12345`, SK=`PERSON_CHECKIN_SETTINGS` | Primary |

### Document Size Estimate

~600 B per settings document (1 per user)

---

## 5. Calendar Activity Dual-Write

Each person check-in triggers a dual-write to `calendarActivities`:

```json
{
  "PK": "USER#u_12345",
  "SK": "ACTIVITY#2026-03-28#PERSON_CHECKIN#2026-03-28T18:30:00Z",
  "EntityType": "CALENDAR_ACTIVITY",
  "activityType": "PERSON_CHECKIN",
  "summary": {
    "checkInType": "spouse",
    "method": "in-person",
    "contactName": "Sarah",
    "qualityRating": 4
  },
  "sourceKey": "PERSON_CHECKIN#2026-03-28T18:30:00Z"
}
```

### Document Size Estimate

~250 B per calendar activity entry

---

## 6. Complete Access Pattern Matrix

| # | Access Pattern | Collection | Query | Filter/Sort | Operation |
|---|---------------|------------|-------|-------------|-----------|
| 56 | List person check-ins | Table | `USER#<userId>` | begins_with `PERSON_CHECKIN#` | Query (desc) |
| 57 | Person check-ins by date range | Table | `USER#<userId>` | between `PERSON_CHECKIN#<start>` and `PERSON_CHECKIN#<end>` | find |
| 58 | Person check-ins by sub-type | Index | `{ userId, checkInType, timestamp }` | filter checkInType | find |
| 59 | Get person check-in streaks | Table | `USER#<userId>` | begins_with `PERSON_CHECKIN_STREAK#` | find |
| 60 | Get person check-in streak by type | Table | `USER#<userId>` | = `PERSON_CHECKIN_STREAK#<type>` | findOne |
| 61 | Get person check-in settings | Table | `USER#<userId>` | = `PERSON_CHECKIN_SETTINGS` | findOne |
| 62 | Calendar: person check-ins for day | Table | `USER#<userId>` | begins_with `ACTIVITY#<date>#PERSON_CHECKIN#` | find |

---

## 7. Storage Estimates

### Per-User Annual Storage

| Data | Items/Year | Avg. Size | Storage |
|------|-----------|-----------|---------|
| Person check-in entries (avg 3/week) | ~156 | 500 B | 78 KB |
| Calendar activity mirrors | ~156 | 250 B | 39 KB |
| Streak documents (3 sub-types) | 3 | 250 B | 750 B |
| Settings document | 1 | 600 B | 600 B |
| **Total per active user per year** | **~316** | | **~119 KB** |

---

## 8. Operational Notes

- **Streak recalculation:** Triggered on check-in creation, deletion, backdating, or settings change. Recalculates from full history for the affected sub-type. Invalidates Valkey cache.
- **Inactivity alerts:** A scheduled job (CloudWatch Events / EventBridge) runs daily, queries each user's last check-in date per sub-type, and creates notifications for users who exceed their configured `inactivityAlertDays` threshold.
- **Account deletion:** Delete all documents where `userId` matches across `PERSON_CHECKIN#*`, `PERSON_CHECKIN_STREAK#*`, `PERSON_CHECKIN_SETTINGS`, and corresponding `calendarActivities` entries.
- **Offline sync:** Union merge for check-in entries (same as urge/relapse logs). Streaks recalculated server-side after sync.
