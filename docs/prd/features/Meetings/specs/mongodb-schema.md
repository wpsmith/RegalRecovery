# Meetings Attended -- MongoDB Schema Design

**Feature:** Meetings Attended Activity
**Priority:** P1 (Wave 2)
**Aligns with:** `docs/specs/mongodb/schema-design.md` conventions

---

## 1. Collections

### 1.1 Meeting Log (entity 4.14 extension)

Extends the existing Meeting Log entity from the main schema with additional fields for saved meeting references, status, and custom types.

**Collection:** Uses the main single-table pattern with `PK`/`SK` keys.

| Attribute | Pattern |
|-----------|---------|
| PK | `USER#<userId>` |
| SK | `MEETING#<ISO8601 timestamp>` |

**Document Structure:**

```json
{
  "PK": "USER#u_12345",
  "SK": "MEETING#2026-03-28T19:00:00Z",
  "EntityType": "MEETING",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T19:00:00Z",
  "ModifiedAt": "2026-03-28T19:00:00Z",
  "meetingId": "mt_33333",
  "meetingType": "SA",
  "customTypeLabel": null,
  "name": "Tuesday Night Recovery",
  "location": "Community Center",
  "notes": "Shared my story. Felt supported.",
  "durationMinutes": 60,
  "status": "attended",
  "savedMeetingId": "sm_11111"
}
```

**Field Descriptions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `meetingId` | String | Yes | Unique meeting log ID (`mt_` prefix) |
| `meetingType` | String (enum) | Yes | `SA`, `CR`, `AA`, `therapy`, `group-counseling`, `church`, `custom` |
| `customTypeLabel` | String | No | Free-text label when `meetingType` is `custom` (max 100 chars) |
| `name` | String | No | Meeting name or group name (max 200 chars) |
| `location` | String | No | Meeting location (max 300 chars) |
| `notes` | String | No | Post-meeting notes (max 2000 chars) |
| `durationMinutes` | Integer | No | Meeting duration in minutes (>= 0) |
| `status` | String (enum) | Yes | `attended`, `canceled` |
| `savedMeetingId` | String | No | Reference to saved meeting template (if logged from favorite) |

**Access Patterns:**

| # | Pattern | Operation | Key Condition | Filter/Sort |
|---|---------|-----------|---------------|-------------|
| 1 | Get recent meetings | find | PK=`USER#<userId>`, SK begins_with `MEETING#` | Sort desc by SK |
| 2 | Get meetings by date range | find | PK=`USER#<userId>`, SK between `MEETING#<start>` and `MEETING#<end>` | -- |
| 3 | Get meeting by ID | find | PK=`USER#<userId>`, SK begins_with `MEETING#`, filter `meetingId=mt_33333` | -- |
| 4 | Get meetings by type | find | PK=`USER#<userId>`, SK begins_with `MEETING#` | Filter `meetingType` |

---

### 1.2 Saved Meeting (New Entity)

User-created meeting templates for one-tap logging.

| Attribute | Pattern |
|-----------|---------|
| PK | `USER#<userId>` |
| SK | `SAVED_MEETING#<savedMeetingId>` |

**Document Structure:**

```json
{
  "PK": "USER#u_12345",
  "SK": "SAVED_MEETING#sm_11111",
  "EntityType": "SAVED_MEETING",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-02-01T10:00:00Z",
  "ModifiedAt": "2026-03-15T08:00:00Z",
  "savedMeetingId": "sm_11111",
  "name": "Tuesday Night Recovery",
  "meetingType": "SA",
  "customTypeLabel": null,
  "location": "Community Center",
  "schedule": {
    "dayOfWeek": "tuesday",
    "time": "19:00",
    "timeZone": "America/New_York"
  },
  "reminderMinutesBefore": 30,
  "isActive": true
}
```

**Field Descriptions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `savedMeetingId` | String | Yes | Unique saved meeting ID (`sm_` prefix) |
| `name` | String | Yes | Meeting name (max 200 chars) |
| `meetingType` | String (enum) | Yes | Same enum as meeting log |
| `customTypeLabel` | String | No | Custom type label |
| `location` | String | No | Default location (max 300 chars) |
| `schedule` | Object | No | Recurring schedule |
| `schedule.dayOfWeek` | String | No | Day of week (lowercase) |
| `schedule.time` | String | No | Local time (HH:mm) |
| `schedule.timeZone` | String | No | IANA timezone |
| `reminderMinutesBefore` | Integer | No | Minutes before meeting to send reminder (15, 30, 60) |
| `isActive` | Boolean | Yes | Soft-delete flag |

**Access Patterns:**

| # | Pattern | Operation | Key Condition | Filter |
|---|---------|-----------|---------------|--------|
| 1 | List saved meetings | find | PK=`USER#<userId>`, SK begins_with `SAVED_MEETING#` | Filter `isActive=true` |
| 2 | Get saved meeting by ID | findOne | PK=`USER#<userId>`, SK=`SAVED_MEETING#sm_11111` | -- |

---

### 1.3 Calendar Activity Dual-Write (Existing Pattern)

Follows the existing `calendarActivities` dual-write pattern from section 4.48 of the main schema.

| Attribute | Pattern |
|-----------|---------|
| PK | `USER#<userId>` |
| SK | `ACTIVITY#<YYYY-MM-DD>#MEETING#<ISO8601 timestamp>` |

**Document Structure:**

```json
{
  "PK": "USER#u_12345",
  "SK": "ACTIVITY#2026-03-28#MEETING#2026-03-28T19:00:00Z",
  "EntityType": "CALENDAR_ACTIVITY",
  "activityType": "MEETING",
  "summary": {
    "meetingType": "SA",
    "name": "Tuesday Night Recovery",
    "status": "attended"
  },
  "sourceKey": "MEETING#2026-03-28T19:00:00Z"
}
```

---

## 2. Indexes

No new indexes required beyond the existing compound index on `{ PK: 1, SK: 1 }`. All meeting access patterns use the primary key with SK prefix filters.

The `meetingType` filter on pattern #4 is applied as an application-level filter on the result set returned by the SK prefix query. Given the expected volume (~3 meetings per user per week), this is acceptable without a secondary index.

---

## 3. Document Size Estimates

| Entity | Avg. Doc Size | Frequency per User per Day |
|--------|---------------|---------------------------|
| Meeting Log | 400 B | 0-1 (3x/week typical) |
| Saved Meeting | 350 B | -- (3-10 per user) |
| Calendar Activity (Meeting) | 250 B | 0-1 (mirrors meeting log) |

**Estimated per user per year:** ~156 meeting logs + ~156 calendar entries = ~312 documents, ~100 KB.

---

## 4. Data Lifecycle

- **Immutable timestamps:** `CreatedAt` and the SK timestamp are never modified (FR2.7).
- **Soft delete on saved meetings:** `isActive` set to `false`; document retained for referential integrity.
- **Hard delete on meeting logs:** Both the meeting document and its calendar activity dual-write are deleted.
- **Account deletion:** All `MEETING#*` and `SAVED_MEETING#*` documents for the user are purged within 30 days (FR1.4).

---

## 5. Offline Sync Considerations

- **Conflict resolution:** Union merge. If the same meeting appears on both client and server (matched by timestamp), the most recent `ModifiedAt` wins for mutable fields. Meeting logs are append-only in practice, so conflicts are rare.
- **Offline queue:** Meetings created offline are queued with client-generated `meetingId` values and synced chronologically on reconnect.
