# Phone Calls Activity -- MongoDB Schema Design

**Activity:** Phone Calls
**Priority:** P1 (Wave 2)
**Feature Flag:** `activity.phone-calls`

---

## Collections

The Phone Calls activity uses two new document types within the existing single-table design, plus dual-writes to the `calendarActivities` collection.

---

## 1. Phone Call Log

**Entity Type:** `PHONECALL`

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `PHONECALL#<ISO8601 timestamp>` |

### Document Structure

```json
{
  "PK": "USER#u_12345",
  "SK": "PHONECALL#2026-03-28T12:30:00Z",
  "EntityType": "PHONECALL",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T12:30:00Z",
  "ModifiedAt": "2026-03-28T12:30:00Z",
  "callId": "pc_11111",
  "direction": "made",
  "contactType": "sponsor",
  "customContactLabel": null,
  "connected": true,
  "contactName": "Mike S.",
  "savedContactId": "sc_99999",
  "durationMinutes": 15,
  "notes": "Discussed urge triggers from earlier today"
}
```

### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `PK` | String | Yes | `USER#<userId>` |
| `SK` | String | Yes | `PHONECALL#<ISO8601 timestamp>` |
| `EntityType` | String | Yes | Always `PHONECALL` |
| `TenantId` | String | Yes | Tenant identifier (default: `DEFAULT`) |
| `CreatedAt` | Date | Yes | Immutable creation timestamp (FR2.7) |
| `ModifiedAt` | Date | Yes | Updated on every write |
| `callId` | String | Yes | Unique identifier (`pc_` prefix) |
| `direction` | String | Yes | `made` or `received` |
| `contactType` | String | Yes | `sponsor`, `accountability-partner`, `counselor`, `coach`, `support-person`, `custom` |
| `customContactLabel` | String | No | Free-text label when contactType = "custom" |
| `connected` | Boolean | Yes | Whether a conversation actually happened |
| `contactName` | String | No | Free-text contact name (max 50 chars) |
| `savedContactId` | String | No | Reference to saved contact document |
| `durationMinutes` | Integer | No | Call duration in minutes |
| `notes` | String | No | Free-text notes (max 500 chars) |

### Calendar Activity Dual-Write

Written alongside the canonical phone call document:

```json
{
  "PK": "USER#u_12345",
  "SK": "ACTIVITY#2026-03-28#PHONECALL#2026-03-28T12:30:00Z",
  "EntityType": "CALENDAR_ACTIVITY",
  "activityType": "PHONECALL",
  "summary": {
    "direction": "made",
    "contactType": "sponsor",
    "connected": true,
    "contactName": "Mike S."
  },
  "sourceKey": "PHONECALL#2026-03-28T12:30:00Z"
}
```

### Access Patterns

| # | Access Pattern | Query | Sort/Filter | Operation |
|---|---------------|-------|-------------|-----------|
| 1 | Get recent phone calls | PK=`USER#<userId>`, SK begins_with `PHONECALL#` | ScanIndexForward=false | Query (desc) |
| 2 | Get calls by date range | PK=`USER#<userId>`, SK between `PHONECALL#<start>` and `PHONECALL#<end>` | -- | find |
| 3 | Get call by ID | PK=`USER#<userId>`, SK begins_with `PHONECALL#`, filter callId=`pc_11111` | -- | find + filter |
| 4 | Get calls for a day (calendar) | PK=`USER#<userId>`, SK begins_with `ACTIVITY#<YYYY-MM-DD>#PHONECALL` | -- | find |
| 5 | Filter by direction | PK=`USER#<userId>`, SK begins_with `PHONECALL#` | filter direction=`made` | find + filter |
| 6 | Filter by contactType | PK=`USER#<userId>`, SK begins_with `PHONECALL#` | filter contactType=`sponsor` | find + filter |
| 7 | Filter by connected | PK=`USER#<userId>`, SK begins_with `PHONECALL#` | filter connected=`true` | find + filter |
| 8 | Search notes | PK=`USER#<userId>`, SK begins_with `PHONECALL#` | filter notes contains keyword | find + filter |

---

## 2. Saved Contact

**Entity Type:** `SAVED_CONTACT`

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `SAVED_CONTACT#<savedContactId>` |

### Document Structure

```json
{
  "PK": "USER#u_12345",
  "SK": "SAVED_CONTACT#sc_99999",
  "EntityType": "SAVED_CONTACT",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-02-01T10:00:00Z",
  "ModifiedAt": "2026-02-01T10:00:00Z",
  "savedContactId": "sc_99999",
  "contactName": "Mike S.",
  "contactType": "sponsor",
  "phoneNumber": "+15551234567"
}
```

### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `PK` | String | Yes | `USER#<userId>` |
| `SK` | String | Yes | `SAVED_CONTACT#<savedContactId>` |
| `EntityType` | String | Yes | Always `SAVED_CONTACT` |
| `TenantId` | String | Yes | Tenant identifier |
| `CreatedAt` | Date | Yes | Creation timestamp |
| `ModifiedAt` | Date | Yes | Last modification timestamp |
| `savedContactId` | String | Yes | Unique identifier (`sc_` prefix) |
| `contactName` | String | Yes | Display name (max 50 chars) |
| `contactType` | String | Yes | Same enum as phone call contactType |
| `phoneNumber` | String | No | E.164 phone number for deep-link dialing |

### Access Patterns

| # | Access Pattern | Query | Operation |
|---|---------------|-------|-----------|
| 1 | List saved contacts | PK=`USER#<userId>`, SK begins_with `SAVED_CONTACT#` | find |
| 2 | Get saved contact by ID | PK=`USER#<userId>`, SK=`SAVED_CONTACT#<savedContactId>` | findOne |

---

## 3. Phone Call Streak (Denormalized)

The phone call streak is derived data, calculated from phone call log entries. It is cached in Valkey with a 5-minute TTL and recalculated on each new call log or deletion.

The streak is NOT stored as a separate MongoDB document. Instead, it is computed by querying `PHONECALL#` entries, grouping by date, and counting consecutive days.

### Streak Calculation Logic

1. Query all phone calls for user sorted by timestamp descending
2. Group by calendar date (in user's timezone)
3. Count consecutive days backward from today where at least one call exists
4. Both `connected=true` and `connected=false` count (effort matters)
5. Backdated calls trigger recalculation

### Valkey Cache Key

```
phone-call-streak:{userId}
```

**TTL:** 300 seconds (5 minutes)
**Invalidated on:** call creation, call deletion, call update (date change via backdate)

---

## Document Size Estimates

| Entity | Avg. Doc Size | Frequency per User per Day |
|--------|---------------|---------------------------|
| Phone Call Log | 300 B | 0-3 |
| Calendar Activity (phone call) | 250 B | 0-3 (mirror) |
| Saved Contact | 200 B | Static (0-10 per user) |

### Estimated Storage per User at 1 Year

- Phone call logs: ~365 entries x 300 B = ~107 KB
- Calendar mirrors: ~365 entries x 250 B = ~89 KB
- Saved contacts: ~5 entries x 200 B = ~1 KB
- **Total per user per year: ~197 KB**

---

## Indexes

No additional indexes are required beyond the existing primary key pattern (`PK` + `SK`). All phone call access patterns are served by the primary key with begins_with and range queries on the sort key.

The calendarActivities dual-write leverages the existing `ACTIVITY#<date>#<type>#<timestamp>` pattern documented in the main schema design (Section 4.48).

---

## Conflict Resolution (Offline Sync)

Per project conventions:
- **Phone call logs:** Union merge (both versions kept). If the same call is logged on two devices, both entries are preserved.
- **Saved contacts:** Last-write-wins (LWW) on the savedContactId.

---

## Data Deletion

- **Account deletion (FR1.4):** All `PHONECALL#*` and `SAVED_CONTACT#*` documents for the user are deleted along with corresponding calendar activity dual-writes.
- **Individual call deletion:** The call document and its calendar activity dual-write are both deleted. Streak is recalculated.
- **Saved contact deletion:** Only the `SAVED_CONTACT#` document is removed. Historical phone call logs referencing the savedContactId are preserved unchanged.
