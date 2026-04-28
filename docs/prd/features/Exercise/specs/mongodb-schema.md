# Exercise / Physical Activity -- MongoDB Schema Design

**Source:** Exercise PRD + `docs/specs/mongodb/schema-design.md` (Section 4.15)
**Feature Flag:** `activity.exercise`

---

## 1. Collections and Document Structures

### 1.1 Exercise Log (extends existing entity 4.15)

**Collection:** Main single-table collection (user-scoped)

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `EXERCISE#<ISO8601 timestamp>` |

**Also written to `calendarActivities` collection (dual-write).**

**Extended Example Item:**

```json
{
  "PK": "USER#u_12345",
  "SK": "EXERCISE#2026-03-28T06:30:00Z",
  "EntityType": "EXERCISE",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T06:30:00Z",
  "ModifiedAt": "2026-03-28T06:30:00Z",
  "exerciseId": "ex_44444",
  "activityType": "running",
  "customTypeLabel": null,
  "durationMinutes": 30,
  "intensity": "moderate",
  "notes": "Morning jog in the park. Felt great after.",
  "moodBefore": 3,
  "moodAfter": 5,
  "source": "manual",
  "externalId": null
}
```

**Field Reference:**

| Field | Type | Required | Immutable | Description |
|-------|------|----------|-----------|-------------|
| `exerciseId` | String | Yes | Yes | Unique ID (`ex_` prefix) |
| `activityType` | String (enum) | Yes | Yes | One of: walking, running, gym, yoga, swimming, cycling, sports, hiking, dance, martial-arts, group-fitness, home-workout, yardwork, other |
| `customTypeLabel` | String (50 max) | No | No | Free-text label when activityType is "other" |
| `durationMinutes` | Integer (1-1440) | Yes | Yes | Duration in minutes |
| `intensity` | String (enum) | No | No | light, moderate, vigorous |
| `notes` | String (500 max) | No | No | Free-text notes |
| `moodBefore` | Integer (1-5) | No | No | Mood rating before exercise |
| `moodAfter` | Integer (1-5) | No | No | Mood rating after exercise |
| `source` | String (enum) | Yes | Yes | manual, apple-health, google-fit |
| `externalId` | String | No | Yes | External platform ID for duplicate detection |

**Immutability note:** `CreatedAt`, `SK` (timestamp), `exerciseId`, `activityType`, `durationMinutes`, and `source` are immutable after creation per FR2.7. Only `intensity`, `notes`, `moodBefore`, `moodAfter`, and `customTypeLabel` can be updated.

---

### 1.2 Exercise Favorite

**Collection:** Main single-table collection (user-scoped)

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `EXERCISE_FAV#<favoriteId>` |

**Example Item:**

```json
{
  "PK": "USER#u_12345",
  "SK": "EXERCISE_FAV#fav_11111",
  "EntityType": "EXERCISE_FAVORITE",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-15T09:00:00Z",
  "ModifiedAt": "2026-03-15T09:00:00Z",
  "favoriteId": "fav_11111",
  "activityType": "running",
  "customTypeLabel": null,
  "defaultDurationMinutes": 30,
  "defaultIntensity": "moderate",
  "label": "Morning Run",
  "sortOrder": 1
}
```

**Field Reference:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `favoriteId` | String | Yes | Unique ID (`fav_` prefix) |
| `activityType` | String (enum) | Yes | Predefined activity type |
| `customTypeLabel` | String (50 max) | No | Label when activityType is "other" |
| `defaultDurationMinutes` | Integer | Yes | Default duration for quick log |
| `defaultIntensity` | String (enum) | No | Default intensity for quick log |
| `label` | String (50 max) | No | Display label for the favorite |
| `sortOrder` | Integer | Yes | Display order (1-5) |

**Constraint:** Maximum 5 favorites per user. Enforced at application layer before write.

---

### 1.3 Exercise Weekly Goal

**Collection:** Main single-table collection (user-scoped)

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `EXERCISE_GOAL` |

**Example Item:**

```json
{
  "PK": "USER#u_12345",
  "SK": "EXERCISE_GOAL",
  "EntityType": "EXERCISE_GOAL",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-01T08:00:00Z",
  "ModifiedAt": "2026-03-28T10:00:00Z",
  "targetActiveMinutes": 150,
  "targetSessions": 4
}
```

**Note:** One goal per user. `PUT` creates or replaces. `DELETE` removes. Progress is computed at read time by querying exercise logs for the current week.

---

### 1.4 Exercise Streak (Computed/Cached)

Exercise streak is not stored as a separate entity. It is computed on demand by querying exercise logs and counting consecutive calendar days with at least one entry. The result is cached in Valkey with a 5-minute TTL, invalidated on new exercise log creation or deletion.

**Valkey Cache Key:** `exercise:streak:{userId}`

```json
{
  "currentDays": 5,
  "longestDays": 12,
  "lastExerciseDate": "2026-03-28",
  "computedAt": "2026-03-28T10:00:00Z"
}
```

---

### 1.5 Calendar Activity Entry (Dual-Write)

On every exercise log create/delete, a corresponding calendar activity is written/removed:

```json
{
  "PK": "USER#u_12345",
  "SK": "ACTIVITY#2026-03-28#EXERCISE#2026-03-28T06:30:00Z",
  "EntityType": "CALENDAR_ACTIVITY",
  "activityType": "EXERCISE",
  "summary": {
    "type": "running",
    "durationMinutes": 30,
    "intensity": "moderate"
  },
  "sourceKey": "EXERCISE#2026-03-28T06:30:00Z"
}
```

---

## 2. Access Patterns

| # | Access Pattern | Query | Filter/Sort | Operation |
|---|---------------|-------|-------------|-----------|
| EX-1 | Create exercise log | PK=`USER#{userId}`, SK=`EXERCISE#{timestamp}` | -- | insertOne |
| EX-2 | Get exercise by ID | PK=`USER#{userId}`, SK begins_with `EXERCISE#`, filter exerciseId | -- | find + filter |
| EX-3 | List exercise logs (desc) | PK=`USER#{userId}`, SK begins_with `EXERCISE#` | ScanIndexForward=false | Query (desc) |
| EX-4 | Exercise logs by date range | PK=`USER#{userId}`, SK between `EXERCISE#{start}` and `EXERCISE#{end}` | -- | find |
| EX-5 | Filter by activity type | PK=`USER#{userId}`, SK begins_with `EXERCISE#` | filter activityType | find + filter |
| EX-6 | Filter by intensity | PK=`USER#{userId}`, SK begins_with `EXERCISE#` | filter intensity | find + filter |
| EX-7 | Search notes by keyword | PK=`USER#{userId}`, SK begins_with `EXERCISE#` | filter notes contains keyword | find + filter |
| EX-8 | Get exercise for date (streak calc) | PK=`USER#{userId}`, SK between `EXERCISE#{date}T00:00:00Z` and `EXERCISE#{date}T23:59:59Z` | -- | find |
| EX-9 | Count exercises in week | PK=`USER#{userId}`, SK between `EXERCISE#{weekStart}` and `EXERCISE#{weekEnd}` | -- | count |
| EX-10 | List favorites | PK=`USER#{userId}`, SK begins_with `EXERCISE_FAV#` | -- | find |
| EX-11 | Get favorite by ID | PK=`USER#{userId}`, SK=`EXERCISE_FAV#{favoriteId}` | -- | findOne |
| EX-12 | Count favorites | PK=`USER#{userId}`, SK begins_with `EXERCISE_FAV#` | -- | count |
| EX-13 | Get weekly goal | PK=`USER#{userId}`, SK=`EXERCISE_GOAL` | -- | findOne |
| EX-14 | Upsert weekly goal | PK=`USER#{userId}`, SK=`EXERCISE_GOAL` | -- | updateOne (upsert) |
| EX-15 | Duplicate detection (external) | PK=`USER#{userId}`, SK begins_with `EXERCISE#` | filter externalId | find + filter |
| EX-16 | Calendar: exercise for day | PK=`USER#{userId}`, SK begins_with `ACTIVITY#{date}#EXERCISE` | -- | find |

---

## 3. Indexes

No additional indexes beyond the existing compound index on `{ userId, timestamp }` are required. All exercise access patterns are satisfied by the PK/SK key design:

- PK = `USER#{userId}` provides user scoping
- SK prefix `EXERCISE#` with ISO8601 timestamp enables efficient date range queries
- Activity type and intensity filtering is done at the application layer (post-query filter) since exercise logs per user are bounded (~365/year)

**Valkey Cache Entries:**

| Key Pattern | TTL | Invalidation |
|-------------|-----|-------------|
| `exercise:streak:{userId}` | 5 min | On exercise log create/delete |
| `exercise:widget:{userId}` | 2 min | On exercise log create/delete, goal change |
| `exercise:stats:{userId}:{period}:{date}` | 10 min | On exercise log create/delete |

---

## 4. Document Size Estimates

| Entity | Avg. Doc Size | Frequency per User per Day |
|--------|---------------|---------------------------|
| Exercise Log | 350 B | 0-3 |
| Exercise Favorite | 250 B | -- (max 5 per user) |
| Exercise Goal | 200 B | -- (1 per user) |
| Calendar Activity (exercise) | 250 B | 0-3 (mirror of exercise logs) |

**Per-user annual storage (active user, 1 exercise/day avg):**
- Exercise logs: 365 x 350 B = ~125 KB
- Calendar mirrors: 365 x 250 B = ~89 KB
- Static (favorites + goal): ~1.5 KB
- **Total: ~216 KB/year**

---

## 5. Offline Sync Considerations

Exercise logs follow the standard offline-first pattern:

- **Conflict resolution:** Union merge for exercise logs (all logs from all devices are kept).
- **Duplicate detection:** If the same `externalId` from a health platform exists on the server, the client is prompted to merge or keep both.
- **Streak recalculation:** After sync, streak is recomputed server-side and cache is invalidated.

---

## 6. Data Deletion

- **Account deletion (FR1.4):** All `EXERCISE#*`, `EXERCISE_FAV#*`, `EXERCISE_GOAL`, and corresponding `ACTIVITY#*#EXERCISE#*` entries are deleted.
- **Individual entry deletion:** Deletes the exercise log and its calendar activity mirror. Streak cache is invalidated.
- **No TTL/ephemeral support:** Exercise logs are permanent by default (no ephemeral mode).
