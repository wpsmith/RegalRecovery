# Three Circles -- MongoDB Schema Design

**Version:** 1.0.0
**Date:** 2026-04-08
**Status:** Draft
**Parent Schema:** `docs/specs/mongodb/schema-design.md`
**Feature Flag:** `feature.3circles`
**Error Code Prefix:** `rr:0x000B`

This specification defines the MongoDB document schema for the Three Circles domain: circle set management, version history, templates, starter packs, onboarding flow state, sponsor review, pattern visualization, drift alerts, insights, and quarterly reviews.

---

## 1. Collections

The Three Circles domain introduces 11 collections in the `regal-recovery` database:

| # | Collection | Scope | Description |
|---|-----------|-------|-------------|
| 1 | `circlesSets` | User | Circle sets with inner, middle, and outer circle items |
| 2 | `circlesVersions` | User | Immutable version snapshots of circle sets |
| 3 | `circlesTemplates` | System | Individual template items organized by recovery area and circle |
| 4 | `circlesStarterPacks` | System | Pre-built complete circle sets for quick start |
| 5 | `circlesOnboarding` | User | Onboarding flow state (save and resume) |
| 6 | `circlesShares` | User | Share links and codes for sponsor review |
| 7 | `circlesSponsorComments` | Public | Sponsor/therapist comments on shared circle items |
| 8 | `circlesPatternTimeline` | User | Daily circle-level check-in data for pattern visualization |
| 9 | `circlesInsights` | User | Auto-generated pattern insight cards |
| 10 | `circlesDriftAlerts` | User | Middle circle drift alert records |
| 11 | `circlesReviews` | User | Quarterly review sessions with reflections |

---

## 2. Document Structures

### 2.1 Collection: `circlesSets`

The primary collection. Each document represents a complete circle set for a single recovery area.

```json
{
  "_id": ObjectId("..."),
  "setId": "3c_set_a1b2c3d4",
  "entityType": "CIRCLE_SET",
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "name": "Sex/Pornography Recovery",
  "recoveryArea": "sex-pornography",
  "frameworkPreference": "SAA",
  "status": "active",
  "innerCircle": [
    {
      "itemId": "3c_item_x1y2z3",
      "behaviorName": "Viewing pornography",
      "notes": "Includes any explicit visual content",
      "specificityDetail": "Includes browsing Instagram models, TikTok provocative content, explicit websites",
      "category": null,
      "source": "template",
      "flags": { "uncertain": false },
      "createdAt": ISODate("2026-03-01T10:00:00Z"),
      "modifiedAt": ISODate("2026-03-01T10:00:00Z")
    }
  ],
  "middleCircle": [
    {
      "itemId": "3c_item_m1n2o3",
      "behaviorName": "Staying up past midnight alone with phone",
      "notes": "This is my most reliable warning sign",
      "specificityDetail": null,
      "category": "environmental-trigger",
      "source": "user",
      "flags": { "uncertain": true },
      "createdAt": ISODate("2026-03-01T10:05:00Z"),
      "modifiedAt": ISODate("2026-03-15T14:30:00Z")
    }
  ],
  "outerCircle": [
    {
      "itemId": "3c_item_p1q2r3",
      "behaviorName": "Daily exercise (30+ minutes)",
      "notes": "Running or gym",
      "specificityDetail": null,
      "category": "exercise",
      "source": "starterPack",
      "flags": { "uncertain": false },
      "createdAt": ISODate("2026-03-01T10:10:00Z"),
      "modifiedAt": ISODate("2026-03-01T10:10:00Z")
    }
  ],
  "versionNumber": 5,
  "starterPackId": "3c_pack_sex_secular_01",
  "createdAt": ISODate("2026-03-01T10:00:00Z"),
  "modifiedAt": ISODate("2026-04-01T09:30:00Z"),
  "committedAt": ISODate("2026-03-01T10:20:00Z"),
  "lastReviewedAt": ISODate("2026-03-01T10:20:00Z"),
  "nextReviewDue": ISODate("2026-06-01T10:20:00Z")
}
```

**Field Definitions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | auto | MongoDB document ID |
| `setId` | String | yes | Unique set identifier (`3c_set_{alphanumeric}`) |
| `entityType` | String | yes | Always `"CIRCLE_SET"` |
| `userId` | String | yes | Owner user ID |
| `tenantId` | String | yes | Tenant identifier for isolation |
| `name` | String | yes | Display name, max 100 chars |
| `recoveryArea` | String (enum) | yes | `sex-pornography`, `alcohol`, `drugs`, `gambling`, `food-eating`, `internet-technology`, `work`, `shopping-debt`, `love-relationships`, `other` |
| `frameworkPreference` | String (enum) | no | `SAA`, `SLAA`, `AA`, `NA`, `SMART`, `OA`, `GA`, `DA`, `CoDA`, `ITAA`, `WA`, `other`, `none` |
| `status` | String (enum) | yes | `draft`, `active`, `archived` |
| `innerCircle` | CircleItem[] | yes | Hard boundary behaviors (max 20 items) |
| `middleCircle` | CircleItem[] | yes | Warning signs and slippery behaviors (max 50 items) |
| `outerCircle` | CircleItem[] | yes | Healthy behaviors and practices (max 50 items) |
| `versionNumber` | Integer | yes | Current version number, starts at 1, increments on circle changes |
| `starterPackId` | String | no | If created from a starter pack, the pack ID (for 14-day check-in scheduling) |
| `createdAt` | Date | yes | **Immutable** creation timestamp (FR2.7) |
| `modifiedAt` | Date | yes | Last modification timestamp |
| `committedAt` | Date | no | When set transitioned from draft to active; null for drafts |
| `lastReviewedAt` | Date | no | Timestamp of most recent quarterly review |
| `nextReviewDue` | Date | no | 90 days from last review or commit date |

**CircleItem Subdocument:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `itemId` | String | yes | Unique item identifier (`3c_item_{alphanumeric}`) |
| `behaviorName` | String | yes | Behavior/sign/practice name, 1-200 chars |
| `notes` | String | no | User context or reasoning, max 1000 chars |
| `specificityDetail` | String | no | "What exactly counts as this?", max 500 chars |
| `category` | String | no | Middle circle: `behavioral-precursor`, `emotional-trigger`, `environmental-trigger`, `lifestyle-warning`, `uncertain`, `halt-hungry`, `halt-angry`, `halt-lonely`, `halt-tired`, `halt-bored`. Outer circle: `social`, `education`, `exercise`, `diet`, `sleep`, `spiritual`. Inner/other: null or free text, max 50 chars |
| `source` | String (enum) | yes | `user`, `template`, `starterPack` |
| `flags` | Object | no | `{ uncertain: Boolean }` -- item flagged for sponsor review |
| `createdAt` | Date | yes | **Immutable** item creation timestamp |
| `modifiedAt` | Date | yes | Last item modification timestamp |

**Validation Rules:**
- `innerCircle` max 20 items
- `middleCircle` max 50 items
- `outerCircle` max 50 items
- `behaviorName` min 1 char, max 200 chars
- `status` must be one of: `draft`, `active`, `archived`
- Cannot commit (transition to `active`) with zero inner circle items
- `createdAt` is immutable after initial write (FR2.7)
- Multiple sets per user allowed (co-occurring recovery areas)

---

### 2.2 Collection: `circlesVersions`

Immutable version snapshots created on every change to circle contents. Supports timeline view, comparison, and restore.

```json
{
  "_id": ObjectId("..."),
  "versionId": "3c_ver_a1b2c3d4_v5",
  "entityType": "CIRCLE_SET_VERSION",
  "setId": "3c_set_a1b2c3d4",
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "versionNumber": 5,
  "snapshot": {
    "innerCircle": [
      {
        "itemId": "3c_item_x1y2z3",
        "behaviorName": "Viewing pornography",
        "notes": "Includes any explicit visual content",
        "specificityDetail": "Includes browsing Instagram models, TikTok provocative content",
        "category": null,
        "source": "template",
        "flags": { "uncertain": false }
      }
    ],
    "middleCircle": [],
    "outerCircle": []
  },
  "changeNote": "Added specificity detail after sponsor feedback",
  "changeType": "itemUpdated",
  "changedItems": ["3c_item_x1y2z3"],
  "innerCount": 3,
  "middleCount": 7,
  "outerCount": 10,
  "changedAt": ISODate("2026-04-01T09:30:00Z"),
  "createdAt": ISODate("2026-04-01T09:30:00Z")
}
```

**Field Definitions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | auto | MongoDB document ID |
| `versionId` | String | yes | Unique version ID (`3c_ver_{setId}_{vN}`) |
| `entityType` | String | yes | Always `"CIRCLE_SET_VERSION"` |
| `setId` | String | yes | Parent circle set reference |
| `userId` | String | yes | Owner user ID |
| `tenantId` | String | yes | Tenant identifier |
| `versionNumber` | Integer | yes | Sequential version number within this set |
| `snapshot` | Object | yes | Full circle data at this version (inner, middle, outer arrays) |
| `changeNote` | String | no | User-provided reason for change, max 500 chars |
| `changeType` | String (enum) | yes | `itemAdded`, `itemUpdated`, `itemDeleted`, `itemMoved`, `setCommitted`, `setRestored`, `starterPackApplied`, `bulkReplace`, `reviewChange` |
| `changedItems` | String[] | no | Item IDs affected by this change |
| `innerCount` | Integer | yes | Item count in inner circle at this version |
| `middleCount` | Integer | yes | Item count in middle circle at this version |
| `outerCount` | Integer | yes | Item count in outer circle at this version |
| `changedAt` | Date | yes | Timestamp of the change |
| `createdAt` | Date | yes | **Immutable** creation timestamp (FR2.7) |

**Validation Rules:**
- `snapshot` must contain all three circle arrays
- `versionNumber` must be unique per `setId`
- Documents are **append-only** -- versions are never updated or deleted
- `createdAt` is immutable (FR2.7)

---

### 2.3 Collection: `circlesTemplates`

System-managed template items. Individual suggestions shown during guided/express onboarding flow.

```json
{
  "_id": ObjectId("..."),
  "templateId": "3c_tpl_sex_inner_001",
  "entityType": "CIRCLE_TEMPLATE",
  "recoveryArea": "sex-pornography",
  "circle": "inner",
  "behaviorName": "Viewing pornography",
  "rationale": "Many people identify this as a primary behavior causing harm to themselves and their relationships.",
  "specificityGuidance": "Consider specifying: types of content, platforms, situations (e.g., 'browsing explicit websites or apps')",
  "category": null,
  "frameworkVariant": null,
  "tags": ["pornography", "content", "visual"],
  "sortOrder": 1,
  "version": 1,
  "active": true,
  "createdAt": ISODate("2026-01-01T00:00:00Z"),
  "updatedAt": ISODate("2026-01-01T00:00:00Z")
}
```

**Field Definitions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | auto | MongoDB document ID |
| `templateId` | String | yes | Unique template ID (`3c_tpl_{alphanumeric}`) |
| `entityType` | String | yes | Always `"CIRCLE_TEMPLATE"` |
| `recoveryArea` | String (enum) | yes | Target recovery area |
| `circle` | String (enum) | yes | `inner`, `middle`, `outer` |
| `behaviorName` | String | yes | Suggested behavior text, max 200 chars |
| `rationale` | String | yes | Why this item is commonly included, max 500 chars |
| `specificityGuidance` | String | no | Suggestions for making this more specific, max 500 chars |
| `category` | String | no | Middle circle category or SEEDS category for outer circle |
| `frameworkVariant` | String | no | Specific to a recovery framework (SAA, SLAA, etc.); null = universal |
| `tags` | String[] | no | Searchable tags |
| `sortOrder` | Integer | yes | Display ordering within recovery area + circle group |
| `version` | Integer | yes | Template content version (increments on edit) |
| `active` | Boolean | yes | Whether template is visible |
| `createdAt` | Date | yes | Creation timestamp |
| `updatedAt` | Date | yes | Last modification timestamp |

**Validation Rules:**
- Templates are system-managed; no user writes
- `circle` must be one of: `inner`, `middle`, `outer`
- Templates are versioned independently of the API
- User circle data never auto-populates from templates without explicit user action

---

### 2.4 Collection: `circlesStarterPacks`

System-managed pre-built complete circle sets. Higher content quality bar than individual templates.

```json
{
  "_id": ObjectId("..."),
  "packId": "3c_pack_sex_secular_01",
  "entityType": "CIRCLE_STARTER_PACK",
  "name": "Sex Addiction Recovery -- Secular",
  "description": "A balanced starting recovery plan for sexual addiction, built from common patterns in SAA and SLAA recovery communities.",
  "recoveryArea": "sex-pornography",
  "variant": "secular",
  "innerCircle": [
    {
      "behaviorName": "Viewing pornography",
      "rationale": "Identified as a primary acting-out behavior by most people in sex addiction recovery.",
      "category": null
    },
    {
      "behaviorName": "Paying for sexual services",
      "rationale": "A common bottom-line behavior that involves exploitation and significant risk.",
      "category": null
    },
    {
      "behaviorName": "Sexual contact outside committed relationship",
      "rationale": "A core boundary for relational recovery.",
      "category": null
    }
  ],
  "middleCircle": [
    {
      "behaviorName": "Staying up past midnight alone with phone or laptop",
      "rationale": "Late-night isolation with internet access is one of the most common precursors to acting out.",
      "category": "environmental-trigger"
    },
    {
      "behaviorName": "Browsing dating apps 'just to look'",
      "rationale": "A classic rationalization behavior that often escalates.",
      "category": "behavioral-precursor"
    },
    {
      "behaviorName": "Isolating from family or friends for extended periods",
      "rationale": "Isolation is consistently identified as a precursor across recovery communities.",
      "category": "lifestyle-warning"
    },
    {
      "behaviorName": "Skipping recovery meetings or sponsor calls",
      "rationale": "Disengagement from recovery support is a warning sign that boundaries may be weakening.",
      "category": "lifestyle-warning"
    },
    {
      "behaviorName": "Feeling unusually angry, lonely, or bored (HALT states)",
      "rationale": "HALT emotional states are the most common triggers for acting-out behavior.",
      "category": "emotional-trigger"
    },
    {
      "behaviorName": "Sleeping less than 6 hours consistently",
      "rationale": "Sleep deprivation weakens impulse control and emotional regulation.",
      "category": "lifestyle-warning"
    }
  ],
  "outerCircle": [
    {
      "behaviorName": "Daily exercise (30+ minutes)",
      "rationale": "Physical activity reduces stress, improves mood, and supports impulse control.",
      "category": "exercise"
    },
    {
      "behaviorName": "Consistent sleep schedule (7-8 hours)",
      "rationale": "Adequate sleep is foundational to emotional regulation and recovery.",
      "category": "sleep"
    },
    {
      "behaviorName": "Weekly recovery meeting attendance",
      "rationale": "Community connection is one of the strongest protective factors in recovery.",
      "category": "social"
    },
    {
      "behaviorName": "Regular sponsor or accountability partner check-ins",
      "rationale": "Breaking isolation through honest relationships is core to sustained recovery.",
      "category": "social"
    },
    {
      "behaviorName": "Journaling or structured reflection",
      "rationale": "Self-awareness through writing helps identify patterns before they escalate.",
      "category": "education"
    }
  ],
  "clinicalReviewer": "Dr. Sarah Mitchell, CSAT",
  "communityReviewer": "Recovery advisory panel (SAA/SLAA)",
  "version": 1,
  "active": true,
  "createdAt": ISODate("2026-01-01T00:00:00Z"),
  "updatedAt": ISODate("2026-01-01T00:00:00Z")
}
```

**Field Definitions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | auto | MongoDB document ID |
| `packId` | String | yes | Unique pack ID (`3c_pack_{alphanumeric}`) |
| `entityType` | String | yes | Always `"CIRCLE_STARTER_PACK"` |
| `name` | String | yes | Display name, max 100 chars |
| `description` | String | yes | Pack description, max 1000 chars |
| `recoveryArea` | String (enum) | yes | Target recovery area |
| `variant` | String (enum) | yes | `secular`, `faith-based`, `lgbtq-affirming` |
| `innerCircle` | StarterPackItem[] | yes | 3-5 inner circle items |
| `middleCircle` | StarterPackItem[] | yes | 6-10 middle circle items |
| `outerCircle` | StarterPackItem[] | yes | SEEDS-based outer circle items |
| `clinicalReviewer` | String | yes | Name of clinician who reviewed |
| `communityReviewer` | String | yes | Name of recovery community reviewer |
| `version` | Integer | yes | Content version |
| `active` | Boolean | yes | Whether pack is available |
| `createdAt` | Date | yes | Creation timestamp |
| `updatedAt` | Date | yes | Last modification timestamp |

**StarterPackItem Subdocument:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `behaviorName` | String | yes | Behavior/sign/practice name |
| `rationale` | String | yes | Why this item is in the pack |
| `category` | String | no | Category tag for middle/outer circle items |

**Validation Rules:**
- Packs are system-managed; no user writes
- `innerCircle` must have 3-5 items
- `middleCircle` must have 6-10 items
- Must exist for each recovery area in at least 3 variants: secular, faith-based, LGBTQ+-affirming
- Both `clinicalReviewer` and `communityReviewer` required
- Content quality bar is higher than individual templates

---

### 2.5 Collection: `circlesOnboarding`

Onboarding flow state for save-and-resume. One active flow per user per recovery area.

```json
{
  "_id": ObjectId("..."),
  "flowId": "3c_flow_f1g2h3i4",
  "entityType": "CIRCLE_ONBOARDING",
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "mode": "guided",
  "currentStep": "middleCircle",
  "emotionalCheckinScore": 3,
  "recoveryArea": "sex-pornography",
  "frameworkPreference": "SAA",
  "progress": {
    "innerCircle": [
      { "behaviorName": "Viewing pornography", "source": "template" },
      { "behaviorName": "Visiting massage parlors", "source": "user" }
    ],
    "outerCircle": [
      { "behaviorName": "Daily exercise", "source": "template" }
    ],
    "middleCircle": []
  },
  "draftSetId": null,
  "completed": false,
  "startedAt": ISODate("2026-03-01T10:00:00Z"),
  "lastUpdatedAt": ISODate("2026-03-01T10:12:00Z"),
  "completedAt": null,
  "createdAt": ISODate("2026-03-01T10:00:00Z")
}
```

**Field Definitions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | auto | MongoDB document ID |
| `flowId` | String | yes | Unique flow ID (`3c_flow_{alphanumeric}`) |
| `entityType` | String | yes | Always `"CIRCLE_ONBOARDING"` |
| `userId` | String | yes | Owner user ID |
| `tenantId` | String | yes | Tenant identifier |
| `mode` | String (enum) | yes | `guided`, `starterPack`, `express` |
| `currentStep` | String (enum) | yes | `recoveryArea`, `framework`, `innerCircle`, `outerCircle`, `middleCircle`, `review` |
| `emotionalCheckinScore` | Integer (1-5) | no | Pre-builder check-in: 1=struggling, 2=low, 3=okay, 4=good, 5=strong |
| `recoveryArea` | String (enum) | no | Selected recovery area (set in step 1) |
| `frameworkPreference` | String (enum) | no | Selected framework (set in step 2) |
| `progress` | Object | yes | Step-specific progress data (inner/middle/outer circle draft items) |
| `draftSetId` | String | no | Created circle set ID (populated on complete) |
| `completed` | Boolean | yes | Whether onboarding has been completed |
| `startedAt` | Date | yes | Flow start timestamp |
| `lastUpdatedAt` | Date | yes | Last progress save timestamp |
| `completedAt` | Date | no | Completion timestamp |
| `createdAt` | Date | yes | **Immutable** creation timestamp (FR2.7) |

**Validation Rules:**
- One active (non-completed) flow per user per recovery area
- Mode can be switched mid-flow without losing progress
- Progress auto-saves on every step
- `createdAt` is immutable (FR2.7)

---

### 2.6 Collection: `circlesShares`

Share links and codes for sponsor/therapist review.

```json
{
  "_id": ObjectId("..."),
  "shareId": "3c_share_s1t2u3v4",
  "entityType": "CIRCLE_SHARE",
  "setId": "3c_set_a1b2c3d4",
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "shareCode": "AB3X9KL2",
  "shareLink": "https://app.regalrecovery.com/share/AB3X9KL2",
  "permissions": ["view", "comment"],
  "expiresAt": ISODate("2026-04-08T10:00:00Z"),
  "active": true,
  "commentCount": 3,
  "createdAt": ISODate("2026-04-01T10:00:00Z")
}
```

**Field Definitions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | auto | MongoDB document ID |
| `shareId` | String | yes | Unique share ID (`3c_share_{alphanumeric}`) |
| `entityType` | String | yes | Always `"CIRCLE_SHARE"` |
| `setId` | String | yes | Circle set being shared |
| `userId` | String | yes | Owner user ID |
| `tenantId` | String | yes | Tenant identifier |
| `shareCode` | String | yes | 8-character alphanumeric code (`^[A-Z0-9]{8}$`) |
| `shareLink` | String | yes | Full share URL |
| `permissions` | String[] | yes | Array of: `view`, `comment` |
| `expiresAt` | Date | no | Expiration timestamp; null = never expires |
| `active` | Boolean | yes | Whether share link is active (can be revoked) |
| `commentCount` | Integer | yes | Running count of sponsor comments |
| `createdAt` | Date | yes | **Immutable** creation timestamp (FR2.7) |

**Validation Rules:**
- `shareCode` must be unique across all shares
- `expiresAt` derives from user selection: 24h, 7d, or null (never)
- Expired shares return 410 Gone
- Multiple active shares per set allowed
- `createdAt` is immutable (FR2.7)

---

### 2.7 Collection: `circlesSponsorComments`

Comments from sponsors/therapists on shared circle items. Public write (no auth required; share code is the access token).

```json
{
  "_id": ObjectId("..."),
  "commentId": "3c_cmt_c1d2e3f4",
  "entityType": "CIRCLE_SPONSOR_COMMENT",
  "shareId": "3c_share_s1t2u3v4",
  "shareCode": "AB3X9KL2",
  "setId": "3c_set_a1b2c3d4",
  "userId": "u_12345",
  "itemId": "3c_item_x1y2z3",
  "text": "I think you should be more specific about what platforms count here. Would Instagram count?",
  "commenterName": "John (sponsor)",
  "read": false,
  "createdAt": ISODate("2026-04-02T15:30:00Z")
}
```

**Field Definitions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | auto | MongoDB document ID |
| `commentId` | String | yes | Unique comment ID (`3c_cmt_{alphanumeric}`) |
| `entityType` | String | yes | Always `"CIRCLE_SPONSOR_COMMENT"` |
| `shareId` | String | yes | Parent share reference |
| `shareCode` | String | yes | Share code used for access |
| `setId` | String | yes | Circle set reference |
| `userId` | String | yes | Owner of the circle set (for querying) |
| `itemId` | String | yes | Specific circle item being commented on |
| `text` | String | yes | Comment text, max 1000 chars |
| `commenterName` | String | no | Optional commenter display name, max 100 chars |
| `read` | Boolean | yes | Whether the set owner has read this comment |
| `createdAt` | Date | yes | **Immutable** creation timestamp (FR2.7) |

**Validation Rules:**
- `text` max 1000 chars
- `commenterName` max 100 chars
- Comments are created via public endpoint (no auth); share code is the access token
- Comments are append-only; they cannot be edited or deleted by the commenter
- The set owner marks comments as `read`
- `createdAt` is immutable (FR2.7)

---

### 2.8 Collection: `circlesPatternTimeline`

Daily circle-level records sourced from check-ins. Used for timeline visualization, summary generation, and drift detection.

```json
{
  "_id": ObjectId("..."),
  "timelineId": "3c_tl_u12345_20260407",
  "entityType": "CIRCLE_PATTERN_TIMELINE",
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "setId": "3c_set_a1b2c3d4",
  "date": "2026-04-07",
  "circle": "outer",
  "checkinDetails": {
    "mood": 4,
    "urgeIntensity": 2,
    "notes": "Good day. Exercised and called sponsor."
  },
  "createdAt": ISODate("2026-04-07T21:00:00Z")
}
```

**Field Definitions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | auto | MongoDB document ID |
| `timelineId` | String | yes | Unique timeline entry ID (`3c_tl_{userId}_{YYYYMMDD}`) |
| `entityType` | String | yes | Always `"CIRCLE_PATTERN_TIMELINE"` |
| `userId` | String | yes | Owner user ID |
| `tenantId` | String | yes | Tenant identifier |
| `setId` | String | yes | Circle set this entry applies to |
| `date` | String (date) | yes | Calendar date (`YYYY-MM-DD`) |
| `circle` | String (enum) | yes | `inner`, `middle`, `outer` |
| `checkinDetails` | Object | no | Optional check-in data |
| `checkinDetails.mood` | Integer (1-5) | no | Daily mood rating |
| `checkinDetails.urgeIntensity` | Integer (0-10) | no | Urge intensity |
| `checkinDetails.notes` | String | no | Free-text notes |
| `createdAt` | Date | yes | **Immutable** creation timestamp (FR2.7) |

**Validation Rules:**
- One entry per user per set per date
- `circle` must be one of: `inner`, `middle`, `outer`
- `mood` range: 1-5 inclusive
- `urgeIntensity` range: 0-10 inclusive
- `createdAt` is immutable (FR2.7)
- Data sourced from daily check-ins; not user-created directly in this domain

---

### 2.9 Collection: `circlesInsights`

Auto-generated pattern insight cards. Refreshed weekly when sufficient data (14+ days) exists.

```json
{
  "_id": ObjectId("..."),
  "insightId": "3c_ins_i1j2k3l4",
  "entityType": "CIRCLE_INSIGHT",
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "setId": "3c_set_a1b2c3d4",
  "type": "dayOfWeek",
  "description": "You tend to have middle circle contact on Fridays.",
  "confidence": "medium",
  "actionSuggestion": "Want to add Fridays to your weekly plan review?",
  "dataPoints": 28,
  "dismissed": false,
  "dismissedAt": null,
  "detectedAt": ISODate("2026-04-07T02:00:00Z"),
  "expiresAt": ISODate("2026-04-14T02:00:00Z"),
  "createdAt": ISODate("2026-04-07T02:00:00Z")
}
```

**Field Definitions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | auto | MongoDB document ID |
| `insightId` | String | yes | Unique insight ID (`3c_ins_{alphanumeric}`) |
| `entityType` | String | yes | Always `"CIRCLE_INSIGHT"` |
| `userId` | String | yes | Owner user ID |
| `tenantId` | String | yes | Tenant identifier |
| `setId` | String | yes | Circle set this insight relates to |
| `type` | String (enum) | yes | `dayOfWeek`, `time`, `trigger`, `protective`, `sleep`, `seeds` |
| `description` | String | yes | Human-readable insight text, max 500 chars |
| `confidence` | String (enum) | yes | `low`, `medium`, `high` |
| `actionSuggestion` | String | yes | Constructive next step, max 500 chars |
| `dataPoints` | Integer | yes | Number of days analyzed for this insight |
| `dismissed` | Boolean | yes | Whether user has dismissed this insight |
| `dismissedAt` | Date | no | When insight was dismissed |
| `detectedAt` | Date | yes | When pattern was detected |
| `expiresAt` | Date | yes | When insight should be refreshed or removed |
| `createdAt` | Date | yes | **Immutable** creation timestamp (FR2.7) |

**Validation Rules:**
- Minimum 14 days of data required before generating insights
- Insights are observations, not predictions
- Insights never surface shaming correlations
- Users can dismiss insights; dismissed insights are retained for analytics
- `createdAt` is immutable (FR2.7)

---

### 2.10 Collection: `circlesDriftAlerts`

Middle circle drift alerts. Triggered when 3+ middle circle days occur in a 7-day window.

```json
{
  "_id": ObjectId("..."),
  "alertId": "3c_alert_d1e2f3g4",
  "entityType": "CIRCLE_DRIFT_ALERT",
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "setId": "3c_set_a1b2c3d4",
  "windowStart": "2026-04-01",
  "windowEnd": "2026-04-07",
  "middleCircleDays": 3,
  "middleCircleDates": ["2026-04-02", "2026-04-04", "2026-04-06"],
  "message": "You've been in your middle circle a few times this week. That's useful information -- it means you're noticing. Would you like to call your sponsor, review your circles, or try a grounding exercise?",
  "dismissed": false,
  "dismissedAt": null,
  "actionTaken": null,
  "createdAt": ISODate("2026-04-07T02:00:00Z")
}
```

**Field Definitions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | auto | MongoDB document ID |
| `alertId` | String | yes | Unique alert ID (`3c_alert_{alphanumeric}`) |
| `entityType` | String | yes | Always `"CIRCLE_DRIFT_ALERT"` |
| `userId` | String | yes | Owner user ID |
| `tenantId` | String | yes | Tenant identifier |
| `setId` | String | yes | Circle set this alert relates to |
| `windowStart` | String (date) | yes | 7-day window start date |
| `windowEnd` | String (date) | yes | 7-day window end date |
| `middleCircleDays` | Integer | yes | Count of middle circle days in window (>= 3) |
| `middleCircleDates` | String[] | yes | Specific dates with middle circle contact |
| `message` | String | yes | Alert copy (gentle, non-punitive) |
| `dismissed` | Boolean | yes | Whether user has dismissed |
| `dismissedAt` | Date | no | When alert was dismissed |
| `actionTaken` | String | no | Action user chose: `calledSponsor`, `reviewedCircles`, `groundingExercise`, `other`, null |
| `createdAt` | Date | yes | **Immutable** creation timestamp (FR2.7) |

**Validation Rules:**
- One alert per drift episode (not repeated daily)
- `middleCircleDays` must be >= 3
- Alert is fully dismissible
- `createdAt` is immutable (FR2.7)

---

### 2.11 Collection: `circlesReviews`

Quarterly review sessions with reflection prompts and progress tracking.

```json
{
  "_id": ObjectId("..."),
  "reviewId": "3c_rev_r1s2t3u4",
  "entityType": "CIRCLE_REVIEW",
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "setId": "3c_set_a1b2c3d4",
  "currentStep": "middleReview",
  "reflections": {
    "innerCircle": "I feel good about my inner circle. The boundaries are clear and I haven't needed to change them.",
    "outerCircle": "I want to add more social activities. Isolation has been creeping in.",
    "middleCircle": null
  },
  "changesApplied": [
    "Added 'weekly coffee with friend' to outer circle",
    "Moved 'skipping gym' from lifestyle-warning to behavioral-precursor"
  ],
  "completed": false,
  "summary": null,
  "startedAt": ISODate("2026-06-01T10:00:00Z"),
  "completedAt": null,
  "nextReviewDue": null,
  "createdAt": ISODate("2026-06-01T10:00:00Z")
}
```

**Field Definitions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | auto | MongoDB document ID |
| `reviewId` | String | yes | Unique review ID (`3c_rev_{alphanumeric}`) |
| `entityType` | String | yes | Always `"CIRCLE_REVIEW"` |
| `userId` | String | yes | Owner user ID |
| `tenantId` | String | yes | Tenant identifier |
| `setId` | String | yes | Circle set being reviewed |
| `currentStep` | String (enum) | yes | `innerReview`, `outerReview`, `middleReview`, `finalReview` |
| `reflections` | Object | no | Free-form reflection notes per circle |
| `changesApplied` | String[] | no | List of changes made during review |
| `completed` | Boolean | yes | Whether review has been completed |
| `summary` | String | no | Optional summary reflection, max 1000 chars |
| `startedAt` | Date | yes | Review start timestamp |
| `completedAt` | Date | no | Completion timestamp |
| `nextReviewDue` | Date | no | 90 days from completion (set on complete) |
| `createdAt` | Date | yes | **Immutable** creation timestamp (FR2.7) |

**Validation Rules:**
- Review is fully skippable and does not block app use
- Completing a review sets `nextReviewDue` = completedAt + 90 days
- Also updates `lastReviewedAt` and `nextReviewDue` on the parent `circlesSets` document
- `createdAt` is immutable (FR2.7)

---

## 3. Indexes

### 3.1 `circlesSets`

| Index Name | Fields | Type | Purpose |
|------------|--------|------|---------|
| `setId_1` | `{ setId: 1 }` | Unique | Direct lookup by set ID |
| `userId_status` | `{ userId: 1, status: 1 }` | Compound | List user's sets filtered by status |
| `userId_recoveryArea` | `{ userId: 1, recoveryArea: 1 }` | Compound | List user's sets by recovery area |
| `userId_nextReviewDue` | `{ userId: 1, nextReviewDue: 1 }` | Compound, sparse | Find sets due for quarterly review |
| `tenantId_1` | `{ tenantId: 1 }` | Single | Tenant admin queries |

### 3.2 `circlesVersions`

| Index Name | Fields | Type | Purpose |
|------------|--------|------|---------|
| `versionId_1` | `{ versionId: 1 }` | Unique | Direct lookup |
| `setId_versionNumber` | `{ setId: 1, versionNumber: -1 }` | Compound | List versions for a set (reverse chronological) |
| `userId_changedAt` | `{ userId: 1, changedAt: -1 }` | Compound | User's change timeline across all sets |
| `tenantId_1` | `{ tenantId: 1 }` | Single | Tenant admin queries |

### 3.3 `circlesTemplates`

| Index Name | Fields | Type | Purpose |
|------------|--------|------|---------|
| `templateId_1` | `{ templateId: 1 }` | Unique | Direct lookup |
| `recoveryArea_circle_active` | `{ recoveryArea: 1, circle: 1, active: 1, sortOrder: 1 }` | Compound | List templates by recovery area and circle |
| `recoveryArea_frameworkVariant` | `{ recoveryArea: 1, frameworkVariant: 1 }` | Compound | Framework-specific template filtering |
| `tags_1` | `{ tags: 1 }` | Multikey | Tag-based filtering |

### 3.4 `circlesStarterPacks`

| Index Name | Fields | Type | Purpose |
|------------|--------|------|---------|
| `packId_1` | `{ packId: 1 }` | Unique | Direct lookup |
| `recoveryArea_variant_active` | `{ recoveryArea: 1, variant: 1, active: 1 }` | Compound | List packs by recovery area + variant |

### 3.5 `circlesOnboarding`

| Index Name | Fields | Type | Purpose |
|------------|--------|------|---------|
| `flowId_1` | `{ flowId: 1 }` | Unique | Direct lookup |
| `userId_completed` | `{ userId: 1, completed: 1 }` | Compound | Find active (incomplete) flows |
| `userId_recoveryArea_completed` | `{ userId: 1, recoveryArea: 1, completed: 1 }` | Compound | One active flow per user per recovery area |
| `tenantId_1` | `{ tenantId: 1 }` | Single | Tenant admin queries |

### 3.6 `circlesShares`

| Index Name | Fields | Type | Purpose |
|------------|--------|------|---------|
| `shareCode_1` | `{ shareCode: 1 }` | Unique | Public share code lookup |
| `setId_active` | `{ setId: 1, active: 1 }` | Compound | List active shares for a set |
| `userId_createdAt` | `{ userId: 1, createdAt: -1 }` | Compound | User's share history |
| `expiresAt_1` | `{ expiresAt: 1 }` | Single, sparse, TTL | Auto-deactivate expired shares |
| `tenantId_1` | `{ tenantId: 1 }` | Single | Tenant admin queries |

### 3.7 `circlesSponsorComments`

| Index Name | Fields | Type | Purpose |
|------------|--------|------|---------|
| `commentId_1` | `{ commentId: 1 }` | Unique | Direct lookup |
| `shareCode_createdAt` | `{ shareCode: 1, createdAt: -1 }` | Compound | Comments on a share (for sponsor view) |
| `userId_setId_read` | `{ userId: 1, setId: 1, read: 1 }` | Compound | Unread comments for set owner |
| `tenantId_1` | `{ tenantId: 1 }` | Single | Tenant admin queries |

### 3.8 `circlesPatternTimeline`

| Index Name | Fields | Type | Purpose |
|------------|--------|------|---------|
| `userId_setId_date` | `{ userId: 1, setId: 1, date: -1 }` | Unique compound | One entry per user per set per date; timeline queries |
| `userId_setId_circle_date` | `{ userId: 1, setId: 1, circle: 1, date: -1 }` | Compound | Filter by circle type + date range |
| `userId_date` | `{ userId: 1, date: -1 }` | Compound | Cross-set timeline view |
| `tenantId_1` | `{ tenantId: 1 }` | Single | Tenant admin queries |

### 3.9 `circlesInsights`

| Index Name | Fields | Type | Purpose |
|------------|--------|------|---------|
| `insightId_1` | `{ insightId: 1 }` | Unique | Direct lookup |
| `userId_setId_dismissed` | `{ userId: 1, setId: 1, dismissed: 1 }` | Compound | Active insights for a set |
| `userId_type_detectedAt` | `{ userId: 1, type: 1, detectedAt: -1 }` | Compound | Insights filtered by type |
| `expiresAt_1` | `{ expiresAt: 1 }` | Single, TTL | Auto-remove expired insights |
| `tenantId_1` | `{ tenantId: 1 }` | Single | Tenant admin queries |

### 3.10 `circlesDriftAlerts`

| Index Name | Fields | Type | Purpose |
|------------|--------|------|---------|
| `alertId_1` | `{ alertId: 1 }` | Unique | Direct lookup |
| `userId_setId_dismissed` | `{ userId: 1, setId: 1, dismissed: 1 }` | Compound | Active alerts for a set |
| `userId_windowEnd` | `{ userId: 1, windowEnd: -1 }` | Compound | Recent drift episodes |
| `tenantId_1` | `{ tenantId: 1 }` | Single | Tenant admin queries |

### 3.11 `circlesReviews`

| Index Name | Fields | Type | Purpose |
|------------|--------|------|---------|
| `reviewId_1` | `{ reviewId: 1 }` | Unique | Direct lookup |
| `userId_setId_completed` | `{ userId: 1, setId: 1, completed: 1 }` | Compound | Review history for a set; find incomplete reviews |
| `userId_startedAt` | `{ userId: 1, startedAt: -1 }` | Compound | User's review history (reverse chronological) |
| `tenantId_1` | `{ tenantId: 1 }` | Single | Tenant admin queries |

### Index Count Summary

| Collection | Index Count |
|-----------|-------------|
| `circlesSets` | 5 |
| `circlesVersions` | 4 |
| `circlesTemplates` | 4 |
| `circlesStarterPacks` | 2 |
| `circlesOnboarding` | 4 |
| `circlesShares` | 5 |
| `circlesSponsorComments` | 4 |
| `circlesPatternTimeline` | 4 |
| `circlesInsights` | 5 |
| `circlesDriftAlerts` | 4 |
| `circlesReviews` | 4 |
| **Total** | **45** |

---

## 4. Access Patterns

### 4.1 Circle Set Management

| # | Access Pattern | Collection | Query | Index | Notes |
|---|---------------|------------|-------|-------|-------|
| AP-TC-01 | List user's circle sets | `circlesSets` | `{ userId: "u_12345", status: "active" }` | `userId_status` | Home screen set list |
| AP-TC-02 | Get circle set by setId | `circlesSets` | `{ setId: "3c_set_..." }` | `setId_1` | Set detail view |
| AP-TC-03 | List sets by recovery area | `circlesSets` | `{ userId: "u_12345", recoveryArea: "sex-pornography" }` | `userId_recoveryArea` | Recovery-area filter |
| AP-TC-04 | Find sets due for review | `circlesSets` | `{ userId: "u_12345", nextReviewDue: { $lte: now } }` | `userId_nextReviewDue` | Quarterly review prompt |
| AP-TC-05 | Update circle set status | `circlesSets` | `{ setId: "3c_set_..." }` update `{ status, committedAt, modifiedAt }` | `setId_1` | Commit / archive |

### 4.2 Version History

| # | Access Pattern | Collection | Query | Index | Notes |
|---|---------------|------------|-------|-------|-------|
| AP-TC-06 | List versions for a set | `circlesVersions` | `{ setId: "3c_set_..." }` sort `{ versionNumber: -1 }` | `setId_versionNumber` | Version timeline |
| AP-TC-07 | Get specific version | `circlesVersions` | `{ setId: "3c_set_...", versionNumber: 3 }` | `setId_versionNumber` | Version detail / comparison |
| AP-TC-08 | Get latest version | `circlesVersions` | `{ setId: "3c_set_..." }` sort `{ versionNumber: -1 }` limit 1 | `setId_versionNumber` | Restore confirmation |

### 4.3 Templates

| # | Access Pattern | Collection | Query | Index | Notes |
|---|---------------|------------|-------|-------|-------|
| AP-TC-09 | List templates by recovery area and circle | `circlesTemplates` | `{ recoveryArea: "sex-pornography", circle: "inner", active: true }` sort `{ sortOrder: 1 }` | `recoveryArea_circle_active` | Onboarding template suggestions |
| AP-TC-10 | Get template detail | `circlesTemplates` | `{ templateId: "3c_tpl_..." }` | `templateId_1` | Template rationale view |
| AP-TC-11 | List framework-specific templates | `circlesTemplates` | `{ recoveryArea: "sex-pornography", frameworkVariant: "SAA" }` | `recoveryArea_frameworkVariant` | Framework filter |

### 4.4 Starter Packs

| # | Access Pattern | Collection | Query | Index | Notes |
|---|---------------|------------|-------|-------|-------|
| AP-TC-12 | List starter packs by recovery area + variant | `circlesStarterPacks` | `{ recoveryArea: "sex-pornography", variant: "secular", active: true }` | `recoveryArea_variant_active` | Starter pack selection |
| AP-TC-13 | Get starter pack detail | `circlesStarterPacks` | `{ packId: "3c_pack_..." }` | `packId_1` | Pack preview + apply |

### 4.5 Onboarding

| # | Access Pattern | Collection | Query | Index | Notes |
|---|---------------|------------|-------|-------|-------|
| AP-TC-14 | Find active onboarding flow | `circlesOnboarding` | `{ userId: "u_12345", completed: false }` | `userId_completed` | Resume incomplete flow |
| AP-TC-15 | Get onboarding by flowId | `circlesOnboarding` | `{ flowId: "3c_flow_..." }` | `flowId_1` | Update flow progress |
| AP-TC-16 | Check existing flow for recovery area | `circlesOnboarding` | `{ userId: "u_12345", recoveryArea: "sex-pornography", completed: false }` | `userId_recoveryArea_completed` | Prevent duplicate flows |

### 4.6 Sponsor Review

| # | Access Pattern | Collection | Query | Index | Notes |
|---|---------------|------------|-------|-------|-------|
| AP-TC-17 | Get share by code (public) | `circlesShares` | `{ shareCode: "AB3X9KL2", active: true }` | `shareCode_1` | Sponsor views shared circles |
| AP-TC-18 | List active shares for a set | `circlesShares` | `{ setId: "3c_set_...", active: true }` | `setId_active` | Manage shares |
| AP-TC-19 | List comments by share code | `circlesSponsorComments` | `{ shareCode: "AB3X9KL2" }` sort `{ createdAt: -1 }` | `shareCode_createdAt` | Sponsor comment thread |
| AP-TC-20 | Get unread comments for set | `circlesSponsorComments` | `{ userId: "u_12345", setId: "3c_set_...", read: false }` | `userId_setId_read` | Unread badge count |
| AP-TC-21 | Mark comments as read | `circlesSponsorComments` | `{ userId: "u_12345", setId: "3c_set_...", read: false }` update `{ read: true }` | `userId_setId_read` | Bulk mark read |

### 4.7 Pattern Visualization

| # | Access Pattern | Collection | Query | Index | Notes |
|---|---------------|------------|-------|-------|-------|
| AP-TC-22 | Get timeline for period | `circlesPatternTimeline` | `{ userId: "u_12345", setId: "3c_set_...", date: { $gte: "2026-03-08", $lte: "2026-04-07" } }` sort `{ date: 1 }` | `userId_setId_date` | 30-day timeline |
| AP-TC-23 | Count days by circle type in window | `circlesPatternTimeline` | Aggregate: `$match { userId, setId, date: { $gte, $lte } }`, `$group { _id: "$circle", count: { $sum: 1 } }` | `userId_setId_circle_date` | Summary stats |
| AP-TC-24 | Consecutive outer circle days | `circlesPatternTimeline` | `{ userId: "u_12345", setId: "3c_set_...", circle: "outer" }` sort `{ date: -1 }` | `userId_setId_circle_date` | Current outer streak (context, not primary metric) |
| AP-TC-25 | Middle circle days in 7-day window | `circlesPatternTimeline` | `{ userId: "u_12345", setId: "3c_set_...", circle: "middle", date: { $gte: 7daysAgo } }` count | `userId_setId_circle_date` | Drift alert detection |

### 4.8 Insights & Drift Alerts

| # | Access Pattern | Collection | Query | Index | Notes |
|---|---------------|------------|-------|-------|-------|
| AP-TC-26 | Active insights for a set | `circlesInsights` | `{ userId: "u_12345", setId: "3c_set_...", dismissed: false }` | `userId_setId_dismissed` | Insight dashboard |
| AP-TC-27 | Insights by type | `circlesInsights` | `{ userId: "u_12345", type: "dayOfWeek" }` sort `{ detectedAt: -1 }` | `userId_type_detectedAt` | Filtered insight view |
| AP-TC-28 | Active drift alerts | `circlesDriftAlerts` | `{ userId: "u_12345", setId: "3c_set_...", dismissed: false }` | `userId_setId_dismissed` | Drift alert banner |
| AP-TC-29 | Recent drift episodes | `circlesDriftAlerts` | `{ userId: "u_12345" }` sort `{ windowEnd: -1 }` limit 5 | `userId_windowEnd` | Drift history |

### 4.9 Quarterly Reviews

| # | Access Pattern | Collection | Query | Index | Notes |
|---|---------------|------------|-------|-------|-------|
| AP-TC-30 | List reviews for a set | `circlesReviews` | `{ userId: "u_12345", setId: "3c_set_..." }` sort `{ startedAt: -1 }` | `userId_setId_completed` | Review history |
| AP-TC-31 | Find incomplete review | `circlesReviews` | `{ userId: "u_12345", setId: "3c_set_...", completed: false }` | `userId_setId_completed` | Resume review |
| AP-TC-32 | Complete review + schedule next | `circlesReviews` | Update `{ completed: true, completedAt, nextReviewDue, summary }` then update parent `circlesSets.nextReviewDue` | `reviewId_1` + `setId_1` | Two-document update |

---

## 5. Document Size Estimates

### Per-Document Sizes

| Collection | Avg Doc Size | Notes |
|-----------|-------------|-------|
| `circlesSets` | 3-8 KB | Varies with item count; 20 items ~4 KB |
| `circlesVersions` | 3-8 KB | Full snapshot mirrors set size |
| `circlesTemplates` | 400 B | System content |
| `circlesStarterPacks` | 3 KB | Full pack with rationales |
| `circlesOnboarding` | 1-3 KB | Grows as progress accumulates |
| `circlesShares` | 300 B | Minimal metadata |
| `circlesSponsorComments` | 400 B | Comment text + metadata |
| `circlesPatternTimeline` | 250 B | One per day per set |
| `circlesInsights` | 400 B | Insight text + metadata |
| `circlesDriftAlerts` | 350 B | Alert metadata |
| `circlesReviews` | 1-2 KB | Reflections text + change list |

### Per-User Annual Estimate

Assumptions: 1 active set, 5 edits/month (60 versions/year), 1 quarterly review per 90 days (4/year), 1 share per quarter, 5 sponsor comments/year, 365 timeline entries/year, 12 insights/year, 4 drift alerts/year.

| Category | Items/Year | Avg Size | Storage |
|----------|-----------|----------|---------|
| Circle sets | 1-3 | 5 KB | 15 KB |
| Versions | 60 | 5 KB | 300 KB |
| Onboarding flows | 1-3 | 2 KB | 6 KB |
| Shares | 4 | 300 B | 1.2 KB |
| Sponsor comments | 5 | 400 B | 2 KB |
| Timeline entries | 365 | 250 B | 89 KB |
| Insights | 12 | 400 B | 4.8 KB |
| Drift alerts | 4 | 350 B | 1.4 KB |
| Reviews | 4 | 1.5 KB | 6 KB |
| **Total per user/year** | **~454** | | **~425 KB** |

### System Content (Shared)

| Content | Documents | Avg Size | Total |
|---------|----------|----------|-------|
| Templates | ~200 (20 per area x 10 areas) | 400 B | 80 KB |
| Starter Packs | ~30 (3 variants x 10 areas) | 3 KB | 90 KB |
| **Total system content** | **~230** | | **~170 KB** |

All documents are well within MongoDB's 16 MB limit. The largest per-user documents are `circlesSets` (with embedded items) and `circlesVersions` (full snapshots), both under 10 KB for typical usage.

---

## 6. Caching Strategy (Valkey)

| Cache Key | TTL | Invalidation Trigger | Purpose |
|-----------|-----|---------------------|---------|
| `3circles:sets:{userId}` | 5 min | On set create/update/delete/commit | User's circle set list |
| `3circles:set:{setId}` | 5 min | On item add/update/delete/move, set update | Set detail |
| `3circles:templates:{recoveryArea}:{circle}` | 1 hour | On template update (admin) | Template list (system content, rarely changes) |
| `3circles:starter-packs:{recoveryArea}` | 1 hour | On pack update (admin) | Starter pack list |
| `3circles:onboarding:{flowId}` | 10 min | On onboarding update | Active onboarding flow state |
| `3circles:timeline:{userId}:{setId}:{period}` | 10 min | On new timeline entry | Timeline visualization data |
| `3circles:summary:{userId}:{setId}:{period}:{startDate}` | 10 min | On new timeline entry | Period summary |
| `3circles:insights:{userId}:{setId}` | 10 min | On insight generation/dismiss | Active insight cards |
| `3circles:drift:{userId}:{setId}` | 10 min | On drift alert create/dismiss | Active drift alerts |
| `3circles:comments:{userId}:{setId}:unread` | 5 min | On comment create, mark read | Unread comment count |

**Cache warming:** Template and starter pack caches are warmed on API cold start. User-specific caches are populated on first access (cache-aside pattern).

**Cache invalidation pattern:** Application-layer invalidation on write operations. No Change Streams dependency. 5-10 minute staleness is acceptable for all cached data.

---

## 7. Calendar Activity Dual-Write

Circle-related events write to the `calendarActivities` collection for the unified calendar view.

### Circle Set Committed

```json
{
  "_id": ObjectId("..."),
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "entityType": "CALENDAR_ACTIVITY",
  "activityType": "THREE_CIRCLES",
  "date": "2026-03-01",
  "timestamp": ISODate("2026-03-01T10:20:00Z"),
  "summary": {
    "action": "committed",
    "setName": "Sex/Pornography Recovery",
    "innerCount": 3,
    "middleCount": 7,
    "outerCount": 10,
    "versionNumber": 1
  },
  "sourceId": "3c_set_a1b2c3d4"
}
```

### Quarterly Review Completed

```json
{
  "_id": ObjectId("..."),
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "entityType": "CALENDAR_ACTIVITY",
  "activityType": "THREE_CIRCLES",
  "date": "2026-06-01",
  "timestamp": ISODate("2026-06-01T11:00:00Z"),
  "summary": {
    "action": "reviewCompleted",
    "setName": "Sex/Pornography Recovery",
    "changesCount": 2,
    "nextReviewDue": "2026-09-01"
  },
  "sourceId": "3c_rev_r1s2t3u4"
}
```

---

## 8. Offline Sync Considerations

| Data | Offline Support | Sync Strategy |
|------|----------------|---------------|
| Circle sets (view + edit) | Full CRUD | Offline-first; queue changes; sync on reconnect with most-conservative merge for items |
| Templates | Read-only cache | Pull on connectivity; background refresh daily |
| Starter packs | Read-only cache | Pull on connectivity; background refresh daily |
| Onboarding flow | Full CRUD | Offline-first; queue progress; sync on reconnect with LWW |
| Sponsor comments | Read cached | Pull on connectivity; comments created online only |
| Pattern timeline | Read cached | Written by check-in domain; synced separately |
| Insights | Read cached | Server-computed; pulled on connectivity |
| Drift alerts | Read cached | Server-computed; pulled on connectivity |
| Reviews | Full CRUD | Offline-first; queue progress; sync on reconnect with LWW |

**Conflict resolution:**
- **Most-conservative merge** for circle items: if a behavior was added to inner circle on either device, it stays in inner circle (the stricter boundary wins)
- **LWW (last-writer-wins)** for set metadata, onboarding progress, review reflections
- **Server-authoritative** for pattern timeline (computed from check-in data), insights, and drift alerts
- **Immutable** `createdAt` timestamps never modified during sync (FR2.7)

---

## 9. Security and Privacy

- **Tenant isolation:** All queries include `tenantId` filter at the application layer
- **User scoping:** All user-scoped queries are scoped by `userId` -- no cross-user access
- **Sponsor review:** Public endpoints (share view, comment) use share code as access token; no user data exposed beyond circle items
- **Pattern data:** All pattern analysis happens on-device for privacy; server stores aggregated results only
- **Community permissions:** Sponsor/Counselor/Coach can see circles when shared; AP/Sponsor see all except journal and financial data (per community permissions default)
- **Sharing controls:** Share links expire; shares can be revoked; granular permission control (view/comment)
- **Deletion (GDPR/CCPA):** Full export + deletion of all 11 collections' user-scoped data within 30 days on request. System content (`circlesTemplates`, `circlesStarterPacks`) is not user data and is excluded from deletion requests.
- **Trauma-informed data:** Circle item text is user-generated and highly sensitive; it is never surfaced to analytics, never visible to other users, and never shared without explicit consent.
