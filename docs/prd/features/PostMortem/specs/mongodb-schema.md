# Post-Mortem Analysis -- MongoDB Schema Design

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft

---

## 1. Overview

The Post-Mortem Analysis feature uses two collections within the `regal-recovery` database, following the project's collection-per-entity design pattern. The primary entity is the expanded `postMortems` collection, with a denormalized entry in the existing `calendarActivities` collection for calendar view support.

---

## 2. Collection: `postMortems`

### Document Structure

```json
{
  "_id": ObjectId("..."),
  "userId": "u_12345",
  "entityType": "POSTMORTEM",
  "tenantId": "DEFAULT",
  "createdAt": ISODate("2026-03-28T23:00:00Z"),
  "modifiedAt": ISODate("2026-03-29T10:00:00Z"),
  "analysisId": "pm_99999",
  "status": "complete",
  "eventType": "relapse",
  "relapseId": "r_98765",
  "addictionId": "a_67890",

  "sections": {
    "dayBefore": {
      "text": "Was feeling disconnected and skipped evening prayer...",
      "moodRating": 4,
      "recoveryPracticesKept": false,
      "unresolvedConflicts": "Argument with spouse about finances"
    },
    "morning": {
      "text": "Woke up feeling flat, skipped morning commitment...",
      "moodRating": 3,
      "morningCommitmentCompleted": false,
      "affirmationViewed": false,
      "autoPopulated": {
        "morningCommitmentCompleted": false,
        "moodRating": null,
        "affirmationViewed": false
      }
    },
    "throughoutTheDay": {
      "timeBlocks": [
        {
          "period": "morning",
          "startTime": "08:00",
          "endTime": "12:00",
          "activity": "Working from home",
          "location": "Home office",
          "company": "Alone",
          "thoughts": "Kept thinking about the argument",
          "feelings": "Resentful, distracted",
          "warningSigns": ["isolation", "forgetting-priorities"]
        },
        {
          "period": "midday",
          "startTime": "12:00",
          "endTime": "14:00",
          "activity": "Skipped lunch, browsed phone",
          "location": "Home",
          "company": "Alone",
          "thoughts": "Started feeling sorry for myself",
          "feelings": "Lonely, bored",
          "warningSigns": ["anxiety", "speeding-up"]
        },
        {
          "period": "afternoon",
          "startTime": "14:00",
          "endTime": "18:00",
          "activity": "Worked but kept checking social media",
          "location": "Home",
          "company": "Alone",
          "thoughts": "Nobody cares about me",
          "feelings": "Angry, isolated",
          "warningSigns": ["ticked-off"]
        },
        {
          "period": "evening",
          "startTime": "18:00",
          "endTime": "22:00",
          "activity": "Watched TV alone, spouse went to bed early",
          "location": "Home",
          "company": "Alone",
          "thoughts": "I deserve this",
          "feelings": "Exhausted, entitled",
          "warningSigns": ["exhausted"]
        }
      ],
      "freeFormEntries": []
    },
    "buildUp": {
      "firstNoticed": "Around midday when I started obsessively browsing my phone",
      "triggers": [
        {
          "category": "emotional",
          "surface": "Boredom",
          "underlying": "Loneliness",
          "coreWound": "Fear of being unlovable"
        },
        {
          "category": "relational",
          "surface": "Argument with spouse",
          "underlying": "Feeling rejected",
          "coreWound": "Abandonment"
        },
        {
          "category": "digital",
          "surface": "Unrestricted phone access",
          "underlying": null,
          "coreWound": null
        }
      ],
      "responseToWarnings": "Ignored them. Told myself I was fine.",
      "missedHelpOpportunities": [
        {
          "description": "Thought about calling sponsor at 3pm",
          "reason": "Felt like I would be bothering him"
        }
      ],
      "decisionPoints": [
        {
          "timeOfDay": "15:00",
          "description": "At 3pm, I could have called my sponsor but instead I kept scrolling",
          "couldHaveDone": "Called my sponsor",
          "insteadDid": "Kept scrolling social media"
        },
        {
          "timeOfDay": "20:00",
          "description": "At 8pm, I could have put the phone away and gone to bed but instead I stayed on the couch alone",
          "couldHaveDone": "Put the phone in the kitchen and gone to bed",
          "insteadDid": "Stayed on the couch with the phone"
        }
      ]
    },
    "actingOut": {
      "description": "Browsed social media late at night, which led to acting out...",
      "addictionId": "a_67890",
      "durationMinutes": 45,
      "linkedRelapseId": "r_98765"
    },
    "immediatelyAfter": {
      "feelings": ["shame", "regret", "hopelessness"],
      "feelingsWheelSelections": ["ashamed", "disappointed", "exhausted"],
      "whatDidNext": "Went to bed feeling terrible",
      "reachedOut": false,
      "reachedOutTo": null,
      "wishDoneDifferently": "I wish I had called my sponsor and been honest about where I was"
    }
  },

  "triggerSummary": ["emotional", "relational", "digital"],
  "triggerDetails": [
    {
      "category": "emotional",
      "surface": "Boredom",
      "underlying": "Loneliness",
      "coreWound": "Fear of being unlovable"
    },
    {
      "category": "relational",
      "surface": "Argument with spouse",
      "underlying": "Feeling rejected",
      "coreWound": "Abandonment"
    },
    {
      "category": "digital",
      "surface": "Unrestricted phone access",
      "underlying": null,
      "coreWound": null
    }
  ],

  "fasterMapping": [
    { "timeOfDay": "08:00", "stage": "forgetting-priorities" },
    { "timeOfDay": "12:00", "stage": "anxiety" },
    { "timeOfDay": "14:00", "stage": "speeding-up" },
    { "timeOfDay": "16:00", "stage": "ticked-off" },
    { "timeOfDay": "18:00", "stage": "exhausted" },
    { "timeOfDay": "22:00", "stage": "relapse" }
  ],

  "actionPlan": [
    {
      "actionId": "ap_001",
      "timelinePoint": "15:00",
      "action": "Call sponsor when I first notice isolation",
      "category": "relational",
      "convertedToCommitmentId": "cm_88888",
      "convertedToGoalId": null
    },
    {
      "actionId": "ap_002",
      "timelinePoint": "20:00",
      "action": "Phone charges outside bedroom by 9pm every night",
      "category": "practical",
      "convertedToCommitmentId": null,
      "convertedToGoalId": "goal_55555"
    },
    {
      "actionId": "ap_003",
      "timelinePoint": "18:00",
      "action": "Attend evening meeting or call AP when spouse is unavailable",
      "category": "relational",
      "convertedToCommitmentId": null,
      "convertedToGoalId": null
    }
  ],

  "sharing": {
    "isShared": true,
    "sharedWith": [
      {
        "contactId": "c_99999",
        "shareType": "full",
        "sharedAt": ISODate("2026-03-29T10:30:00Z")
      }
    ]
  },

  "linkedEntities": {
    "relapseId": "r_98765",
    "urgeLogIds": ["u_77777"],
    "fasterEntryIds": ["fs_33333"],
    "checkInIds": []
  },

  "completedAt": ISODate("2026-03-29T10:00:00Z")
}
```

### Field Definitions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `userId` | String | Yes | Owner user ID |
| `entityType` | String | Yes | Always `"POSTMORTEM"` |
| `tenantId` | String | Yes | Tenant ID for isolation |
| `createdAt` | Date | Yes | Immutable creation timestamp |
| `modifiedAt` | Date | Yes | Last modification timestamp |
| `analysisId` | String | Yes | Unique post-mortem ID (`pm_` prefix) |
| `status` | String | Yes | `"draft"` or `"complete"` |
| `eventType` | String | Yes | `"relapse"`, `"near-miss"`, or `"combined"` |
| `relapseId` | String | No | Reference to relapse record (null for near-miss) |
| `addictionId` | String | No | Associated addiction ID |
| `sections` | Object | Yes | The six walkthrough sections (see below) |
| `triggerSummary` | Array[String] | No | High-level trigger categories |
| `triggerDetails` | Array[Object] | No | Three-layer trigger exploration |
| `fasterMapping` | Array[Object] | No | FASTER stage assignments to timeline points |
| `actionPlan` | Array[Object] | No | Action items with category and conversion refs |
| `sharing` | Object | No | Sharing configuration |
| `linkedEntities` | Object | No | References to related recovery data |
| `completedAt` | Date | No | Set when status transitions to `"complete"` |

### Section Fields Summary

| Section | Key Fields |
|---------|-----------|
| `dayBefore` | `text`, `moodRating` (1-10), `recoveryPracticesKept`, `unresolvedConflicts` |
| `morning` | `text`, `moodRating`, `morningCommitmentCompleted`, `affirmationViewed`, `autoPopulated` |
| `throughoutTheDay` | `timeBlocks[]` (period, startTime, endTime, activity, location, company, thoughts, feelings, warningSigns), `freeFormEntries[]` |
| `buildUp` | `firstNoticed`, `triggers[]` (category, surface, underlying, coreWound), `responseToWarnings`, `missedHelpOpportunities[]`, `decisionPoints[]` |
| `actingOut` | `description`, `addictionId`, `durationMinutes`, `linkedRelapseId` |
| `immediatelyAfter` | `feelings[]`, `feelingsWheelSelections[]`, `whatDidNext`, `reachedOut`, `reachedOutTo`, `wishDoneDifferently` |

---

## 3. Indexes

| Index Name | Fields | Purpose |
|------------|--------|---------|
| `userId_createdAt` | `{ userId: 1, createdAt: -1 }` | List post-mortems for user in reverse chronological order |
| `userId_status` | `{ userId: 1, status: 1 }` | Find draft post-mortems for resume prompt |
| `userId_addictionId` | `{ userId: 1, addictionId: 1, createdAt: -1 }` | Filter by addiction type |
| `userId_relapseId` | `{ userId: 1, relapseId: 1 }` (sparse) | Lookup post-mortem by relapse reference |
| `tenantId` | `{ tenantId: 1 }` | Tenant admin queries |
| `sharing_contactId` | `{ "sharing.sharedWith.contactId": 1 }` (sparse) | Reverse lookup: find post-mortems shared with a contact |

---

## 4. Access Patterns

| # | Access Pattern | Index | Query | Operation |
|---|---------------|-------|-------|-----------|
| 1 | List user's post-mortems (recent first) | `userId_createdAt` | `{ userId: "u_12345" }` sort `{ createdAt: -1 }` | find (paginated) |
| 2 | Get post-mortem by ID | `userId_createdAt` | `{ userId: "u_12345", analysisId: "pm_99999" }` | findOne |
| 3 | Get draft post-mortems | `userId_status` | `{ userId: "u_12345", status: "draft" }` | find |
| 4 | Get post-mortem for relapse | `userId_relapseId` | `{ userId: "u_12345", relapseId: "r_98765" }` | findOne |
| 5 | Filter by addiction type | `userId_addictionId` | `{ userId: "u_12345", addictionId: "a_67890" }` sort `{ createdAt: -1 }` | find (paginated) |
| 6 | Filter by date range | `userId_createdAt` | `{ userId: "u_12345", createdAt: { $gte: start, $lte: end } }` | find (paginated) |
| 7 | Cross-analysis: trigger frequency | `userId_createdAt` | `{ userId: "u_12345", status: "complete" }` project `triggerSummary` | find + aggregate |
| 8 | Cross-analysis: FASTER stages | `userId_createdAt` | `{ userId: "u_12345", status: "complete" }` project `fasterMapping` | find + aggregate |
| 9 | Shared post-mortems for contact | `sharing_contactId` | `{ "sharing.sharedWith.contactId": "c_99999" }` | find |
| 10 | Tenant admin: list all | `tenantId` | `{ tenantId: "t_acme" }` | find |

---

## 5. Calendar Activity Dual-Write

When a post-mortem is completed, a denormalized entry is written to the `calendarActivities` collection:

```json
{
  "userId": "u_12345",
  "date": "2026-03-28",
  "activityType": "POSTMORTEM",
  "timestamp": ISODate("2026-03-28T23:00:00Z"),
  "summary": {
    "analysisId": "pm_99999",
    "eventType": "relapse",
    "status": "complete",
    "triggerCount": 3,
    "actionItemCount": 3
  },
  "sourceKey": "POSTMORTEM#2026-03-28T23:00:00Z"
}
```

---

## 6. Document Size Estimate

| Component | Estimated Size |
|-----------|---------------|
| Base fields (IDs, timestamps, status) | ~200 B |
| Sections (6 sections with text) | ~4-8 KB |
| Trigger details (3-6 triggers) | ~500 B |
| FASTER mapping (4-6 entries) | ~300 B |
| Action plan (3-5 items) | ~500 B |
| Sharing metadata | ~200 B |
| Linked entities | ~150 B |
| **Total average** | **~6-10 KB** |
| **Maximum realistic** | **~15 KB** |

This is well within MongoDB's 16 MB document limit. The expanded schema (compared to the original 1.2 KB estimate in the main schema doc) reflects the full six-section guided walkthrough with structured data.

---

## 7. Migration from Existing Schema

The existing `POSTMORTEM` entity in `schema-design.md` (Section 4.20) uses a flat `sections` structure with five simple string fields. The expanded schema adds:

1. Structured `sections` object with typed fields per section
2. `status` field (draft/complete) for auto-save
3. `eventType` field (relapse/near-miss/combined)
4. `triggerDetails` with three-layer exploration
5. `fasterMapping` array
6. `actionPlan` with conversion references
7. `sharing` configuration
8. `linkedEntities` references

Migration approach: additive. New fields are added alongside existing ones. Existing post-mortems (if any) continue to work with the flat `sections` structure. Application code handles both formats during transition.

---

## 8. Conflict Resolution (Offline Sync)

Following the project's conflict resolution strategy:

- **Union merge** for the overall post-mortem document -- if created on two devices, both are kept
- **Last-write-wins** for draft updates within the same post-mortem
- **Immutable** `createdAt` timestamp -- never modified after creation
- **Status transitions** are one-way: `draft` -> `complete` (never reversed)
