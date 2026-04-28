# Weekly/Daily Goals -- MongoDB Schema Design

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft

---

## Overview

The Weekly/Daily Goals feature uses three document types within the existing single-table MongoDB design, plus a settings extension on the user settings document:

1. **WeeklyDailyGoal** -- Goal definitions (templates) with recurrence rules
2. **GoalInstance** -- Materialized goal instances for specific dates
3. **GoalReview** -- End-of-day and end-of-week review records
4. **GoalSettings** (embedded in User Settings) -- Auto-population and notification configuration

All documents follow the project conventions: `userId` as primary key pattern, `tenantId` for multi-tenant isolation, immutable `createdAt`, and `modifiedAt` for metadata changes.

---

## 1. WeeklyDailyGoal (Goal Definition)

**Description:** A goal template that defines what the user wants to track, its recurrence, dynamics, and priority. Goal instances are materialized from these definitions.

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `WDGOAL#<goalId>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "WDGOAL#wdg_22222",
  "EntityType": "WEEKLY_DAILY_GOAL",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-04-01T10:00:00Z",
  "ModifiedAt": "2026-04-07T08:00:00Z",
  "goalId": "wdg_22222",
  "text": "Morning prayer and scripture reading",
  "dynamics": ["spiritual"],
  "scope": "daily",
  "recurrence": "daily",
  "daysOfWeek": null,
  "dayOfWeek": null,
  "priority": "high",
  "notes": "Start with Psalm 51, then free prayer",
  "isActive": true
}
```

**Field Descriptions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `goalId` | String | Yes | Unique ID with `wdg_` prefix |
| `text` | String | Yes | Goal description (1-200 chars) |
| `dynamics` | String[] | Yes | One or more of: `spiritual`, `physical`, `emotional`, `intellectual`, `relational` |
| `scope` | String | Yes | `daily` or `weekly` |
| `recurrence` | String | Yes | `one-time`, `daily`, `specific-days`, `weekly` |
| `daysOfWeek` | String[] | No | For `specific-days` recurrence: array of day names |
| `dayOfWeek` | String | No | For `weekly` recurrence: specific day of week |
| `priority` | String | Yes | `high`, `medium`, `low` |
| `notes` | String | No | Additional context (max 500 chars) |
| `isActive` | Boolean | Yes | Active goals generate instances; inactive ones are preserved for history |

**Access Patterns:**

| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| List all goal definitions for user | find | PK=`USER#u_12345`, SK begins_with `WDGOAL#` | Primary |
| Get goal definition by ID | findOne | PK=`USER#u_12345`, SK=`WDGOAL#wdg_22222` | Primary |
| List active goal definitions | find | PK=`USER#u_12345`, SK begins_with `WDGOAL#`, filter `isActive=true` | Primary |

---

## 2. GoalInstance (Materialized Goal for a Date)

**Description:** A specific goal occurrence for a given date. Created by the goal materialization process (daily cron or on-demand when the user opens their daily view). Also created for auto-populated goals from commitments and activities.

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `WDGINST#<YYYY-MM-DD>#<goalInstanceId>` |

**Example Items:**

Manual goal instance:
```json
{
  "PK": "USER#u_12345",
  "SK": "WDGINST#2026-04-07#gi_11111",
  "EntityType": "GOAL_INSTANCE",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-04-07T06:00:00Z",
  "ModifiedAt": "2026-04-07T07:30:00Z",
  "goalInstanceId": "gi_11111",
  "goalId": "wdg_22222",
  "date": "2026-04-07",
  "text": "Morning prayer and scripture reading",
  "dynamics": ["spiritual"],
  "scope": "daily",
  "priority": "high",
  "status": "completed",
  "completedAt": "2026-04-07T07:30:00Z",
  "source": null,
  "sourceId": null,
  "carriedFrom": null,
  "notes": "Read Psalm 51"
}
```

Auto-populated goal instance from commitment:
```json
{
  "PK": "USER#u_12345",
  "SK": "WDGINST#2026-04-07#gi_33333",
  "EntityType": "GOAL_INSTANCE",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-04-07T06:00:00Z",
  "ModifiedAt": "2026-04-07T06:00:00Z",
  "goalInstanceId": "gi_33333",
  "goalId": null,
  "date": "2026-04-07",
  "text": "Call sponsor",
  "dynamics": ["relational"],
  "scope": "daily",
  "priority": "medium",
  "status": "pending",
  "completedAt": null,
  "source": "commitment",
  "sourceId": "cm_77777",
  "carriedFrom": null,
  "notes": null
}
```

Carried-over goal instance:
```json
{
  "PK": "USER#u_12345",
  "SK": "WDGINST#2026-04-07#gi_55555",
  "EntityType": "GOAL_INSTANCE",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-04-07T06:00:00Z",
  "ModifiedAt": "2026-04-07T06:00:00Z",
  "goalInstanceId": "gi_55555",
  "goalId": "wdg_44444",
  "date": "2026-04-07",
  "text": "Write amends letter",
  "dynamics": ["relational", "emotional"],
  "scope": "daily",
  "priority": "high",
  "status": "pending",
  "completedAt": null,
  "source": null,
  "sourceId": null,
  "carriedFrom": "2026-04-06",
  "notes": null
}
```

**Field Descriptions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `goalInstanceId` | String | Yes | Unique ID with `gi_` prefix |
| `goalId` | String | No | Reference to the goal definition (null for auto-populated) |
| `date` | String | Yes | The date this instance belongs to (YYYY-MM-DD) |
| `text` | String | Yes | Snapshot of goal text at materialization time |
| `dynamics` | String[] | Yes | Snapshot of dynamics |
| `scope` | String | Yes | `daily` or `weekly` |
| `priority` | String | Yes | `high`, `medium`, `low` |
| `status` | String | Yes | `pending`, `completed`, `skipped`, `dismissed`, `carried` |
| `completedAt` | Date | No | When the goal was completed |
| `source` | String | No | `commitment`, `activity`, `post-mortem` -- null for manual |
| `sourceId` | String | No | ID of the source entity |
| `carriedFrom` | String | No | Date this goal was carried from |
| `notes` | String | No | Goal notes |

**Access Patterns:**

| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| Get all goal instances for a day | find | PK=`USER#u_12345`, SK begins_with `WDGINST#2026-04-07#` | Primary |
| Get all goal instances for a week | find | PK=`USER#u_12345`, SK between `WDGINST#2026-04-06#` and `WDGINST#2026-04-12#~` | Primary |
| Get all goal instances for a date range | find | PK=`USER#u_12345`, SK between `WDGINST#<start>#` and `WDGINST#<end>#~` | Primary |
| Get specific goal instance | findOne | PK=`USER#u_12345`, SK=`WDGINST#2026-04-07#gi_11111` | Primary |
| Get goal instances by status | find | PK=`USER#u_12345`, SK begins_with `WDGINST#2026-04-07#`, filter `status=pending` | Primary |

**Note:** The SK design `WDGINST#<date>#<instanceId>` enables efficient date-range queries. A single query retrieves all instances for a day, week, or arbitrary date range.

---

## 3. GoalReview (Daily/Weekly Review Record)

**Description:** Stores end-of-day and end-of-week review submissions including dispositions and reflections.

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `WDGREVIEW#<type>#<YYYY-MM-DD>` |

**Example Items:**

Daily review:
```json
{
  "PK": "USER#u_12345",
  "SK": "WDGREVIEW#DAILY#2026-04-07",
  "EntityType": "GOAL_REVIEW",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-04-07T21:30:00Z",
  "ModifiedAt": "2026-04-07T21:30:00Z",
  "reviewId": "gr_88888",
  "type": "daily",
  "date": "2026-04-07",
  "dispositions": [
    { "goalInstanceId": "gi_33333", "action": "carry-to-tomorrow" },
    { "goalInstanceId": "gi_44444", "action": "skipped" }
  ],
  "reflection": "Work was intense today, but I stayed connected with my sponsor.",
  "summary": {
    "totalGoals": 7,
    "completedGoals": 4,
    "carriedGoals": 1,
    "skippedGoals": 2,
    "dynamicBalance": {
      "spiritual": { "total": 2, "completed": 2 },
      "physical": { "total": 1, "completed": 0 },
      "emotional": { "total": 1, "completed": 1 },
      "intellectual": { "total": 0, "completed": 0 },
      "relational": { "total": 3, "completed": 1 }
    }
  }
}
```

Weekly review:
```json
{
  "PK": "USER#u_12345",
  "SK": "WDGREVIEW#WEEKLY#2026-04-06",
  "EntityType": "GOAL_REVIEW",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-04-12T20:00:00Z",
  "ModifiedAt": "2026-04-12T20:00:00Z",
  "reviewId": "gr_99999",
  "type": "weekly",
  "date": "2026-04-06",
  "reflections": {
    "biggestWin": "Maintained all spiritual goals every day this week",
    "dynamicNeedingAttention": "physical",
    "freeText": "Need to get back to exercise routine"
  },
  "stats": {
    "totalGoals": 18,
    "completedGoals": 12,
    "completionRate": 66.7,
    "strongestDynamic": "spiritual",
    "weakestDynamic": "physical",
    "previousWeekCompletionRate": 55.0,
    "change": 11.7
  }
}
```

**Access Patterns:**

| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| Get daily review for a date | findOne | PK=`USER#u_12345`, SK=`WDGREVIEW#DAILY#2026-04-07` | Primary |
| Get weekly review for a week | findOne | PK=`USER#u_12345`, SK=`WDGREVIEW#WEEKLY#2026-04-06` | Primary |
| List all reviews | find | PK=`USER#u_12345`, SK begins_with `WDGREVIEW#` | Primary |
| List daily reviews in date range | find | PK=`USER#u_12345`, SK between `WDGREVIEW#DAILY#<start>` and `WDGREVIEW#DAILY#<end>` | Primary |

---

## 4. GoalNudgeDismissal (Transient)

**Description:** Tracks which dynamic nudges have been dismissed for a given date. Lightweight document, no need for a separate entity; can be embedded in the daily goals materialization or stored as a small document.

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `WDGNUDGE#<YYYY-MM-DD>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "WDGNUDGE#2026-04-07",
  "EntityType": "GOAL_NUDGE_DISMISSAL",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-04-07T10:00:00Z",
  "ModifiedAt": "2026-04-07T14:00:00Z",
  "date": "2026-04-07",
  "dismissedDynamics": ["intellectual", "physical"]
}
```

**Access Patterns:**

| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| Get dismissed nudges for today | findOne | PK=`USER#u_12345`, SK=`WDGNUDGE#2026-04-07` | Primary |

---

## 5. GoalSettings (Extension to User Settings)

**Description:** Goal-specific settings are added as a nested object within the existing User Settings document (Section 4.2 of the main schema).

**Added fields on the `SETTINGS` document:**

```json
{
  "PK": "USER#u_12345",
  "SK": "SETTINGS",
  "goalSettings": {
    "autoPopulateCommitments": true,
    "autoPopulateActivities": true,
    "autoPopulateCommitmentIds": [],
    "autoPopulateActivityTypes": ["journaling", "prayer", "affirmations"],
    "nudgesEnabled": true,
    "nudgesDisabledDynamics": [],
    "notifications": {
      "morningEnabled": true,
      "morningTime": "07:00",
      "middayEnabled": false,
      "eveningEnabled": true,
      "eveningTime": "21:00",
      "weeklyEnabled": true,
      "weeklyReviewDay": "sunday",
      "dynamicGapEnabled": true
    }
  }
}
```

**Access Pattern:** Same as existing user settings -- `findOne` on `PK=USER#<userId>`, `SK=SETTINGS`.

---

## 6. Calendar Activity Integration

Goal completions are dual-written to the `calendarActivities` collection for calendar view integration:

```json
{
  "PK": "USER#u_12345",
  "SK": "ACTIVITY#2026-04-07#GOAL_COMPLETED#2026-04-07T07:30:00Z",
  "EntityType": "CALENDAR_ACTIVITY",
  "activityType": "GOAL_COMPLETED",
  "summary": {
    "goalInstanceId": "gi_11111",
    "text": "Morning prayer and scripture reading",
    "dynamics": ["spiritual"]
  },
  "sourceKey": "WDGINST#2026-04-07#gi_11111"
}
```

---

## 7. Document Size Estimates

| Entity | Avg. Doc Size | Frequency per User per Day |
|--------|---------------|----------------------------|
| WeeklyDailyGoal (definition) | 350 B | -- (5-15 per user total) |
| GoalInstance | 400 B | 5-15 (one per active goal per day) |
| GoalReview (daily) | 800 B | 0-1 |
| GoalReview (weekly) | 600 B | 0-1 (weekly) |
| GoalNudgeDismissal | 200 B | 0-1 |
| Calendar Activity (dual-write) | 250 B | 3-10 |

**Estimated storage per user per year (active user):**
- Goal definitions: ~5 KB (static, updated rarely)
- Goal instances: ~365 days x 10 instances/day x 400 B = ~1.4 MB
- Daily reviews: ~365 x 800 B = ~285 KB
- Weekly reviews: ~52 x 600 B = ~31 KB
- Calendar dual-writes: ~365 x 7 x 250 B = ~625 KB
- **Total: ~2.3 MB per active user per year**

---

## 8. Indexes

No additional collection-level indexes are required. All access patterns use the existing primary key (`PK` + `SK`) with prefix-based queries. The SK design with date prefixes (e.g., `WDGINST#2026-04-07#`) enables efficient range queries for daily, weekly, and arbitrary date ranges without secondary indexes.

| Access Pattern | Key Strategy | Efficient? |
|----------------|-------------|------------|
| Day's goals | SK begins_with `WDGINST#<date>#` | Yes -- single prefix scan |
| Week's goals | SK between `WDGINST#<weekStart>#` and `WDGINST#<weekEnd>#~` | Yes -- range scan |
| History (date range) | SK between `WDGINST#<start>#` and `WDGINST#<end>#~` | Yes -- range scan |
| Goal definitions | SK begins_with `WDGOAL#` | Yes -- prefix scan |
| Reviews | SK begins_with `WDGREVIEW#` | Yes -- prefix scan |
