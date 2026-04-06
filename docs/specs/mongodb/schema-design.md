# Regal Recovery -- MongoDB Document-Based Schema Specification

**Version:** 1.0.0
**Date:** 2026-03-28
**Status:** Draft

---

## Table of Contents

1. [Overview](#1-overview)
2. [Database Schema](#2-database-schema)
3. [Key Design Principles](#3-key-design-principles)
4. [Entity Catalog](#4-entity-catalog)
5. [Access Pattern Reference](#5-access-pattern-reference)
6. [Document Size Estimates](#6-document-size-estimates)
7. [Capacity Planning](#7-capacity-planning)
8. [Operational Considerations](#8-operational-considerations)

---

## 1. Overview

Regal Recovery uses a **document-based schema** in MongoDB Atlas. Entities are organized into purpose-specific collections with indexes to support the full set of access patterns. This design optimizes for:

- **Cost efficiency:** MongoDB Atlas serverless or dedicated clusters with pay-as-you-go pricing.
- **Performance:** Related data embedded in documents for single-query fetches; references where needed for cross-entity queries.
- **Simplicity:** Flexible document schema with intuitive data modeling.

**Trade-off:** Document-based schema requires thoughtful decisions about embedding vs. referencing upfront. Schema changes are easier than with rigid table designs thanks to MongoDB's flexible schema, but index changes on large collections still require careful planning. This trade-off is acceptable because the access patterns are well-defined from the PRD and unlikely to change fundamentally.

---

## 2. Database Schema

### MongoDB Atlas Configuration

| Property | Value |
|----------|-------|
| **Database name** | `regal-recovery` |
| **Cluster tier** | MongoDB Atlas Serverless (Year 1) / Dedicated M10+ (Year 3) |
| **Encryption** | AES-256 encryption at rest (MongoDB Atlas managed) |
| **Continuous backup** | Enabled (point-in-time restore with 35-day window) |
| **Termination protection** | Enabled |

### Collections

Each entity type has its own collection, with indexes optimized for the required access patterns.

### Indexes

| Collection | Index | Fields | Purpose |
|------------|-------|--------|---------|
| `users` | email_1 | `{ email: 1 }` (unique) | Reverse lookups: find user by email |
| `users` | tenantId_1 | `{ tenantId: 1 }` | Tenant queries: list users by tenant |
| `messages` | recipientId_timestamp | `{ recipientId: 1, timestamp: -1 }` | Inbox: messages received by a user |
| `contacts` | contactUserId_1 | `{ contactUserId: 1 }` | Reverse contact lookup: find all users who added me |
| `sessions` | sessionId_1 | `{ sessionId: 1 }` (unique) | Session lookup by ID |

### Common Fields (present on all documents)

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectId | MongoDB document ID |
| `userId` | String | Owner user ID (on user-scoped documents) |
| `entityType` | String | Discriminator for application-level filtering (e.g., `USER`, `CHECKIN`, `URGE`) |
| `createdAt` | Date | Timestamp of creation (e.g., `2026-03-28T10:00:00Z`) |
| `modifiedAt` | Date | Timestamp, updated on every write |
| `tenantId` | String | Tenant identifier for multi-tenant isolation. Default: `DEFAULT` for B2C users |

### Optional Common Fields

| Field | Type | Description |
|-------|------|-------------|
| `expiresAt` | Date | Timestamp for TTL-based auto-deletion (ephemeral documents only) |

---

## 3. Key Design Principles

### 3.1 User-Centric Data Organization

Most recovery data is scoped by `userId`. This ensures that all data for a single user can be efficiently queried using indexed lookups on the `userId` field within each collection.

### 3.2 Collection-Per-Entity Design

Each entity type has its own collection (e.g., `checkIns`, `urgeLogs`, `journalEntries`). Documents within each collection are indexed by `userId` and `timestamp` for efficient chronological queries.

### 3.3 Calendar Activity Collection

For the calendar view (a critical UI feature), a denormalized `calendarActivities` collection aggregates all activity types with compound indexes:
```
{ userId: "u_12345", date: "2026-03-28", activityType: "CHECKIN", timestamp: ISODate("2026-03-28T21:00:00Z") }
{ userId: "u_12345", date: "2026-03-28", activityType: "URGE", timestamp: ISODate("2026-03-28T16:45:00Z") }
{ userId: "u_12345", date: "2026-03-28", activityType: "JOURNAL", timestamp: ISODate("2026-03-28T09:30:00Z") }
```
This allows a single query with `{ userId, date: "2026-03-28" }` to fetch all activities for a given day, or a range query for a month view.

### 3.4 Immutable Timestamps

Per FR2.7, all timestamps on recovery data are immutable once created. The `createdAt` field is set at write time and never updated. `modifiedAt` tracks metadata changes only (e.g., marking a notification as read), never retroactive timestamp changes.

### 3.5 Tenant Isolation

Every document carries a `tenantId` field. The application layer enforces that all queries are scoped to the authenticated user's tenant. A `tenantId` index on relevant collections supports listing users/content per tenant for admin operations.

### 3.6 Ephemeral Data via TTL

Documents marked as ephemeral (per Section 10.3.6) include an `expiresAt` field set to the timestamp when the document should be deleted. MongoDB TTL indexes automatically remove expired documents shortly after the `expiresAt` timestamp.

---

## 4. Entity Catalog

Each entity is documented with its key patterns, a complete example item, and the access patterns it supports.

---

### 4.1 User Profile

**Description:** Core user account information.

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `PROFILE` |
| (indexed) | `EMAIL#<email>` |
| (indexed) | `USER#<userId>` |
| (indexed) | `TENANT#<tenantId>` |
| (indexed) | `USER#<userId>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "PROFILE",
  "EntityType": "USER",
  "_emailIndex": "EMAIL#john@example.com",
  "_indexKey": "USER#u_12345",
  "_tenantIndex": "TENANT#DEFAULT",
  "_tenantSortKey": "USER#u_12345",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-01-15T08:00:00Z",
  "ModifiedAt": "2026-03-28T14:30:00Z",
  "email": "john@example.com",
  "displayName": "John",
  "role": "User",
  "primaryAddictionId": "a_67890",
  "preferredLanguage": "en",
  "preferredBibleVersion": "NIV",
  "birthYear": 1985,
  "gender": "male",
  "maritalStatus": "married",
  "timeZone": "America/New_York",
  "emailVerified": true,
  "biometricEnabled": true,
  "regionId": "us-east-1",
  "subscriptionTier": "premium",
  "subscriptionExpiresAt": "2027-01-15T08:00:00Z"
}
```

**Access Patterns:**
| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| Get user by ID | findOne | PK=`USER#u_12345`, SK=`PROFILE` | Primary |
| Get user by email | find (indexed) | query: `EMAIL#john@example.com` | Secondary |
| List users by tenant | find (indexed) | query: `TENANT#DEFAULT` | Secondary |

---

### 4.2 User Settings

**Description:** User preferences and configuration (notifications, privacy, display).

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `SETTINGS` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "SETTINGS",
  "EntityType": "SETTINGS",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-01-15T08:00:00Z",
  "ModifiedAt": "2026-03-28T14:30:00Z",
  "notificationPreferences": {
    "dailyReminder": true,
    "dailyReminderTime": "07:00",
    "milestoneAlerts": true,
    "urgeFollowUp": true,
    "dataAccessAlerts": false
  },
  "privacySettings": {
    "screenshotProtection": true,
    "ephemeralDefault": "ask",
    "ephemeralDuration": 30,
    "includeEphemeralInExports": false
  },
  "displaySettings": {
    "theme": "system",
    "dynamicType": true
  },
  "securitySettings": {
    "autoLockMinutes": 2,
    "biometricRequired": true
  }
}
```

**Access Patterns:**
| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| Get user settings | findOne | PK=`USER#u_12345`, SK=`SETTINGS` | Primary |

---

### 4.3 Addiction Record

**Description:** A tracked addiction with sobriety start date.

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `ADDICTION#<addictionId>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "ADDICTION#a_67890",
  "EntityType": "ADDICTION",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-01-15T08:00:00Z",
  "ModifiedAt": "2026-01-15T08:00:00Z",
  "addictionId": "a_67890",
  "type": "sex-addiction",
  "sobrietyStartDate": "2026-02-09",
  "isPrimary": true
}
```

**Access Patterns:**
| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| Get addiction by ID | findOne | PK=`USER#u_12345`, SK=`ADDICTION#a_67890` | Primary |
| List all addictions for user | find | PK=`USER#u_12345`, SK begins_with `ADDICTION#` | Primary |

---

### 4.4 Sobriety Streak

**Description:** Current and longest streak per addiction. Recalculated server-side authoritatively.

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `STREAK#<addictionId>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "STREAK#a_67890",
  "EntityType": "STREAK",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-02-09T00:00:00Z",
  "ModifiedAt": "2026-03-28T00:00:00Z",
  "addictionId": "a_67890",
  "currentStreakDays": 47,
  "longestStreakDays": 120,
  "sobrietyStartDate": "2026-02-09",
  "lastRelapseDate": null,
  "totalSoberDays": 2847
}
```

**Access Patterns:**
| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| Get streak for addiction | findOne | PK=`USER#u_12345`, SK=`STREAK#a_67890` | Primary |
| List all streaks for user | find | PK=`USER#u_12345`, SK begins_with `STREAK#` | Primary |

**Note:** Streak data is cached in Valkey with a 5-minute TTL and invalidated on relapse events via MongoDB Change Streams. Dashboard reads hit cache first (cache-aside pattern).

---

### 4.5 Check-In Entry

**Description:** Daily/evening check-in with structured responses and computed score.

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `CHECKIN#<ISO8601 timestamp>` |
| (indexed) | `USER#<userId>#CHECKIN` |
| (indexed) | `<YYYY-MM-DD>` |

**Also written to the calendarActivities collection (dual-write):**
| userId | `<userId>` |
| key | `ACTIVITY#<YYYY-MM-DD>#CHECKIN#<ISO8601 timestamp>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "CHECKIN#2026-03-28T21:00:00Z",
  "EntityType": "CHECKIN",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T21:00:00Z",
  "ModifiedAt": "2026-03-28T21:00:00Z",
  "checkInId": "c_55555",
  "type": "daily",
  "responses": {
    "sobrietyStatus": "yes",
    "urgeCount": 2,
    "meetingAttended": true,
    "spiritualPractices": true,
    "emotionalState": 7,
    "supportNetworkContact": true,
    "overallRecoveryHealth": 8
  },
  "score": 85,
  "colorCode": "green"
}
```

**Access Patterns:**
| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| Get recent check-ins | find | PK=`USER#u_12345`, SK begins_with `CHECKIN#`, ScanIndexForward=false, Limit=N | Primary |
| Get check-ins by date range | find | PK=`USER#u_12345`, SK between `CHECKIN#2026-03-01` and `CHECKIN#2026-03-31` | Primary |
| Get check-in by ID | find | PK=`USER#u_12345`, SK begins_with `CHECKIN#`, filter checkInId=`c_55555` | Primary |

---

### 4.6 Urge Log

**Description:** Logged urge event with intensity, triggers, duration, and outcome.

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `URGE#<ISO8601 timestamp>` |

**Also written to the calendarActivities collection.**

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "URGE#2026-03-28T16:45:00Z",
  "EntityType": "URGE",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T16:45:00Z",
  "ModifiedAt": "2026-03-28T16:45:00Z",
  "urgeId": "u_77777",
  "addictionId": "a_67890",
  "intensity": 8,
  "triggers": ["emotional", "digital", "relational"],
  "notes": "Feeling lonely after a difficult conversation",
  "sobrietyMaintained": true,
  "durationMinutes": 15
}
```

**Access Patterns:**
| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| Get recent urges | find | PK=`USER#u_12345`, SK begins_with `URGE#`, ScanIndexForward=false | Primary |
| Get urges by date range | find | PK=`USER#u_12345`, SK between `URGE#<start>` and `URGE#<end>` | Primary |

---

### 4.7 Journal Entry

**Description:** Free-form journal entry with optional prompt, emotional tags, and ephemeral support.

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `JOURNAL#<ISO8601 timestamp>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "JOURNAL#2026-03-28T09:30:00Z",
  "EntityType": "JOURNAL",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T09:30:00Z",
  "ModifiedAt": "2026-03-28T09:30:00Z",
  "entryId": "j_44444",
  "mode": "morning",
  "content": "Today I'm grateful for my support group...",
  "emotionalTags": ["grateful", "hopeful"],
  "prompt": "What are you grateful for today?",
  "isEphemeral": false,
  "ephemeralDeleteAt": null
}
```

**Ephemeral variant** adds:
```json
{
  "isEphemeral": true,
  "ephemeralDeleteAt": "2026-04-27T09:30:00Z",
  "expiresAt": 1777405800
}
```

**Access Patterns:**
| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| Get recent journals | find | PK=`USER#u_12345`, SK begins_with `JOURNAL#`, ScanIndexForward=false | Primary |
| Get journals by date range | find | PK=`USER#u_12345`, SK between `JOURNAL#<start>` and `JOURNAL#<end>` | Primary |
| Auto-delete ephemeral | TTL | `expiresAt` attribute | N/A (async) |

---

### 4.8 FASTER Scale Entry

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `FASTER#<ISO8601 timestamp>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "FASTER#2026-03-28T20:00:00Z",
  "EntityType": "FASTER",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T20:00:00Z",
  "ModifiedAt": "2026-03-28T20:00:00Z",
  "entryId": "fs_33333",
  "stage": "Ticked_Off",
  "indicators": ["irritability", "blame", "isolation"],
  "notes": "Noticed I was snapping at coworkers today"
}
```

**Access Patterns:**
| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| Get recent FASTER entries | find | PK=`USER#u_12345`, SK begins_with `FASTER#`, ScanIndexForward=false | Primary |

---

### 4.9 PCI (Post-Crisis Inventory) Entry

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `PCI#<ISO8601 timestamp>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "PCI#2026-03-28T19:00:00Z",
  "EntityType": "PCI",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T19:00:00Z",
  "ModifiedAt": "2026-03-28T19:00:00Z",
  "entryId": "pci_22222",
  "checkedBehaviors": ["fantasy", "objectification", "isolation", "dishonesty"],
  "score": 4
}
```

**Access Patterns:**
| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| Get recent PCI entries | find | PK=`USER#u_12345`, SK begins_with `PCI#`, ScanIndexForward=false | Primary |

---

### 4.10 Mood Rating

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `MOOD#<ISO8601 timestamp>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "MOOD#2026-03-28T14:00:00Z",
  "EntityType": "MOOD",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T14:00:00Z",
  "ModifiedAt": "2026-03-28T14:00:00Z",
  "moodId": "m_66666",
  "rating": 7,
  "emotion": "calm",
  "notes": "Good afternoon. Feeling centered after lunch with a friend."
}
```

---

### 4.11 Gratitude Entry

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `GRATITUDE#<ISO8601 timestamp>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "GRATITUDE#2026-03-28T07:00:00Z",
  "EntityType": "GRATITUDE",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T07:00:00Z",
  "ModifiedAt": "2026-03-28T07:00:00Z",
  "gratitudeId": "g_88888",
  "content": "Grateful for 47 days of sobriety and my sponsor's patience.",
  "isEphemeral": false
}
```

---

### 4.12 Phone Call Log

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `PHONECALL#<ISO8601 timestamp>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "PHONECALL#2026-03-28T12:30:00Z",
  "EntityType": "PHONECALL",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T12:30:00Z",
  "ModifiedAt": "2026-03-28T12:30:00Z",
  "callId": "pc_11111",
  "contactType": "sponsor",
  "contactId": "c_99999",
  "durationMinutes": 15
}
```

---

### 4.13 Prayer Log

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `PRAYER#<ISO8601 timestamp>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "PRAYER#2026-03-28T06:00:00Z",
  "EntityType": "PRAYER",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T06:00:00Z",
  "ModifiedAt": "2026-03-28T06:00:00Z",
  "prayerId": "pr_22222",
  "prayerType": "morning",
  "content": "Lord, grant me strength today...",
  "durationMinutes": 10,
  "isEphemeral": false
}
```

---

### 4.14 Meeting Log

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `MEETING#<ISO8601 timestamp>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "MEETING#2026-03-28T19:00:00Z",
  "EntityType": "MEETING",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T19:00:00Z",
  "ModifiedAt": "2026-03-28T19:00:00Z",
  "meetingId": "mt_33333",
  "meetingType": "SAA",
  "name": "Tuesday Night Recovery",
  "location": "Community Center",
  "notes": "Shared my story. Felt supported.",
  "durationMinutes": 60
}
```

---

### 4.15 Exercise Log

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `EXERCISE#<ISO8601 timestamp>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "EXERCISE#2026-03-28T06:30:00Z",
  "EntityType": "EXERCISE",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T06:30:00Z",
  "ModifiedAt": "2026-03-28T06:30:00Z",
  "exerciseId": "ex_44444",
  "type": "running",
  "durationMinutes": 30,
  "calories": 320,
  "source": "manual"
}
```

---

### 4.16 Nutrition Log

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `NUTRITION#<ISO8601 timestamp>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "NUTRITION#2026-03-28T12:00:00Z",
  "EntityType": "NUTRITION",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T12:00:00Z",
  "ModifiedAt": "2026-03-28T12:00:00Z",
  "nutritionId": "nut_55555",
  "mealType": "lunch",
  "description": "Grilled chicken salad, water",
  "healthRating": 4
}
```

---

### 4.17 Integrity Inventory

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `INTEGRITY#<ISO8601 timestamp>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "INTEGRITY#2026-03-28T21:30:00Z",
  "EntityType": "INTEGRITY",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T21:30:00Z",
  "ModifiedAt": "2026-03-28T21:30:00Z",
  "inventoryId": "ii_66666",
  "responses": {
    "wasHonestToday": true,
    "keptCommitments": true,
    "avoidedSecrecy": true,
    "madeAmends": false,
    "notes": "Forgot to follow up on an amends letter."
  }
}
```

---

### 4.18 Time Journal (Interval-Based Check-In)

**Description:** Structured, interval-based journaling activity (every 30-60 minutes) that automatically captures GPS location, timestamp, and available sensor metadata. User records emotions, needs, and notes. Designed for pattern recognition across the day.

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `TIMEJOURNAL#<ISO8601 timestamp>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "TIMEJOURNAL#2026-03-28T14:00:00Z",
  "EntityType": "TIMEJOURNAL",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T14:00:00Z",
  "ModifiedAt": "2026-03-28T14:00:00Z",
  "entryId": "tj_77777",
  "emotion": "focused",
  "intensity": 6,
  "activity": "Working on project report",
  "needs": "Taking a break soon",
  "notes": "Feeling productive. No urges today so far.",
  "location": {
    "latitude": 40.7128,
    "longitude": -74.0060,
    "areaName": "Midtown, NYC",
    "accuracy": "high"
  },
  "sensorData": {
    "motionState": "stationary",
    "batteryLevel": 72,
    "screenTime": null
  },
  "selfieKey": "s3://regal-recovery-media/u_12345/selfies/tj_77777.jpg",
  "isEphemeral": false
}
```

---

### 4.19 Emotional Journal Entry

**Description:** Standalone emotional awareness activity capturing emotion, activity, intensity, automatic GPS location, and optional selfie. Designed for frequent, low-friction use throughout the day.

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `EMOTIONAL#<ISO8601 timestamp>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "EMOTIONAL#2026-03-28T15:00:00Z",
  "EntityType": "EMOTIONAL",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T15:00:00Z",
  "ModifiedAt": "2026-03-28T15:00:00Z",
  "entryId": "ej_88888",
  "emotion": "anxiety",
  "activity": "Preparing for meeting",
  "reason": "Upcoming meeting with a difficult coworker",
  "intensity": 6,
  "copingStrategy": "Called sponsor, did breathing exercise",
  "location": {
    "latitude": 40.7580,
    "longitude": -73.9855,
    "areaName": "Midtown East, NYC",
    "accuracy": "high"
  },
  "selfieKey": "s3://regal-recovery-media/u_12345/selfies/ej_88888.jpg",
  "isEphemeral": true,
  "ephemeralDeleteAt": "2026-04-27T15:00:00Z",
  "expiresAt": 1777424600
}
```

---

### 4.20 Post-Mortem Analysis

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `POSTMORTEM#<ISO8601 timestamp>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "POSTMORTEM#2026-03-28T23:00:00Z",
  "EntityType": "POSTMORTEM",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T23:00:00Z",
  "ModifiedAt": "2026-03-28T23:00:00Z",
  "analysisId": "pm_99999",
  "relapseId": "r_98765",
  "sections": {
    "whatHappened": "Browsed social media late at night alone...",
    "earlyWarnings": "Skipped evening check-in, isolated after dinner",
    "fasterStage": "Exhausted",
    "emotionalState": "lonely, bored, tired",
    "whatWouldIDifferently": "Call sponsor before 9pm, avoid phone in bedroom"
  },
  "triggers": ["isolation", "digital", "fatigue", "emotional"],
  "actionItems": [
    "Set phone charging station outside bedroom",
    "Schedule evening sponsor call for next 7 days",
    "Update Three Circles inner boundary"
  ]
}
```

---

### 4.21 FANOS / Spouse Check-In Prep

**Description:** FANOS (Feelings, Appreciation, Needs, Ownership, Sobriety) or FITNAP preparation entries for spouse communication.

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `FANOS#<ISO8601 timestamp>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "FANOS#2026-03-28T18:00:00Z",
  "EntityType": "FANOS",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T18:00:00Z",
  "ModifiedAt": "2026-03-28T18:00:00Z",
  "entryId": "fn_11111",
  "format": "FANOS",
  "feelings": {
    "primary": "hopeful",
    "secondary": "nervous",
    "notes": "Hopeful about our progress but nervous about the conversation"
  },
  "appreciation": "Thank you for being patient while I work through this",
  "needs": "I need 30 minutes of uninterrupted time to share tonight",
  "ownership": "I take responsibility for not communicating my schedule change yesterday",
  "sobriety": "47 days sober. Had 2 urges this week, both managed."
}
```

---

### 4.22 Financial Activity

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `FINANCIAL#<ISO8601 timestamp>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "FINANCIAL#2026-03-28T10:00:00Z",
  "EntityType": "FINANCIAL",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T10:00:00Z",
  "ModifiedAt": "2026-03-28T10:00:00Z",
  "entryId": "fin_22222",
  "category": "expense-tracking",
  "amount": 0,
  "notes": "Reviewed monthly budget, no unaccounted spending",
  "flagged": false
}
```

---

### 4.23 Acting-In Log

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `ACTINGIN#<ISO8601 timestamp>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "ACTINGIN#2026-03-28T17:00:00Z",
  "EntityType": "ACTINGIN",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T17:00:00Z",
  "ModifiedAt": "2026-03-28T17:00:00Z",
  "entryId": "ai_33333",
  "activityType": "called-sponsor",
  "description": "Called sponsor when urge hit instead of isolating",
  "category": "outer-circle"
}
```

---

### 4.24 Goals

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `GOAL#<goalId>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "GOAL#goal_44444",
  "EntityType": "GOAL",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-01T00:00:00Z",
  "ModifiedAt": "2026-03-28T10:00:00Z",
  "goalId": "goal_44444",
  "title": "90-day sobriety milestone",
  "description": "Maintain sobriety for 90 consecutive days",
  "targetDate": "2026-05-10",
  "category": "sobriety",
  "status": "in-progress",
  "progressPercent": 52,
  "milestones": [
    { "label": "30 days", "achieved": true, "achievedAt": "2026-03-11" },
    { "label": "60 days", "achieved": false },
    { "label": "90 days", "achieved": false }
  ]
}
```

---

### 4.25 Devotional Completion

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `DEVOTIONAL#<ISO8601 timestamp>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "DEVOTIONAL#2026-03-28T06:30:00Z",
  "EntityType": "DEVOTIONAL",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T06:30:00Z",
  "ModifiedAt": "2026-03-28T06:30:00Z",
  "entryId": "dev_55555",
  "devotionalId": "d_content_001",
  "reflection": "The passage about surrender resonated with my week...",
  "scriptureReference": "Psalm 51:10"
}
```

---

### 4.26 Step Work Entry

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `STEPWORK#<stepNumber>#<ISO8601 timestamp>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "STEPWORK#04#2026-03-28T20:00:00Z",
  "EntityType": "STEPWORK",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T20:00:00Z",
  "ModifiedAt": "2026-03-28T20:00:00Z",
  "entryId": "sw_66666",
  "stepNumber": 4,
  "title": "Step 4: Moral Inventory",
  "content": "Looking at resentments toward my father...",
  "promptId": "step4-prompt-3",
  "isEphemeral": false
}
```

---

### 4.27 Commitment

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `COMMITMENT#<commitmentId>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "COMMITMENT#cm_77777",
  "EntityType": "COMMITMENT",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-02-15T08:00:00Z",
  "ModifiedAt": "2026-03-28T21:00:00Z",
  "commitmentId": "cm_77777",
  "title": "Call sponsor daily",
  "frequency": "daily",
  "category": "accountability",
  "isActive": true,
  "currentStreakDays": 41,
  "lastCompletedAt": "2026-03-28T12:30:00Z",
  "totalCompletions": 38
}
```

**Access Patterns:**
| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| List active commitments | find | PK=`USER#u_12345`, SK begins_with `COMMITMENT#`, filter isActive=true | Primary |
| Get commitment by ID | findOne | PK=`USER#u_12345`, SK=`COMMITMENT#cm_77777` | Primary |

---

### 4.28 Support Contact

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `CONTACT#<contactId>` |
| (indexed) | `CONTACT#<contactUserId>` |
| (indexed) | `USER#<userId>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "CONTACT#c_99999",
  "EntityType": "CONTACT",
  "_emailIndex": "CONTACT#u_54321",
  "_indexKey": "USER#u_12345",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-02-01T10:00:00Z",
  "ModifiedAt": "2026-02-05T14:00:00Z",
  "contactId": "c_99999",
  "contactUserId": "u_54321",
  "role": "sponsor",
  "displayName": "Mike S.",
  "email": "mike@example.com",
  "status": "accepted",
  "invitedAt": "2026-02-01T10:00:00Z",
  "acceptedAt": "2026-02-05T14:00:00Z"
}
```

**Access Patterns:**
| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| List user's support network | find | PK=`USER#u_12345`, SK begins_with `CONTACT#` | Primary |
| Find all users who added me | find (indexed) | query: `CONTACT#u_54321` | Secondary |

---

### 4.29 Permission

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `PERMISSION#<contactId>#<dataCategory>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "PERMISSION#c_99999#streaks",
  "EntityType": "PERMISSION",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-02-05T14:30:00Z",
  "ModifiedAt": "2026-02-05T14:30:00Z",
  "permissionId": "p_11111",
  "contactId": "c_99999",
  "contactUserId": "u_54321",
  "dataCategory": "streaks",
  "accessLevel": "read",
  "grantedAt": "2026-02-05T14:30:00Z"
}
```

**Access Patterns:**
| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| List all permissions for user | find | PK=`USER#u_12345`, SK begins_with `PERMISSION#` | Primary |
| List permissions for a contact | find | PK=`USER#u_12345`, SK begins_with `PERMISSION#c_99999#` | Primary |
| Check specific permission | findOne | PK=`USER#u_12345`, SK=`PERMISSION#c_99999#streaks` | Primary |

---

### 4.30 Message

| Attribute | Pattern |
|-----------|---------|
| PK | `CONVERSATION#<conversationId>` |
| SK | `MESSAGE#<ISO8601 timestamp>` |
| (indexed) | `USER#<recipientId>` |
| (indexed) | `MESSAGE#<ISO8601 timestamp>` |

**Example Item:**
```json
{
  "PK": "CONVERSATION#conv_12345",
  "SK": "MESSAGE#2026-03-28T16:00:00Z",
  "EntityType": "MESSAGE",
  "_emailIndex": "USER#u_54321",
  "_indexKey": "MESSAGE#2026-03-28T16:00:00Z",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T16:00:00Z",
  "ModifiedAt": "2026-03-28T16:00:00Z",
  "messageId": "msg_88888",
  "senderId": "u_12345",
  "recipientId": "u_54321",
  "content": "Can we talk tonight? Had a rough day.",
  "isRead": false
}
```

**Access Patterns:**
| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| Get messages in conversation | find | PK=`CONVERSATION#conv_12345`, SK begins_with `MESSAGE#`, ScanIndexForward=false | Primary |
| Get user's inbox (all messages to me) | find (indexed) | query: `USER#u_54321`, sorted by `timestamp` | Secondary |

---

### 4.31 Notification

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `NOTIFICATION#<ISO8601 timestamp>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "NOTIFICATION#2026-03-28T21:15:00Z",
  "EntityType": "NOTIFICATION",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T21:15:00Z",
  "ModifiedAt": "2026-03-28T21:15:00Z",
  "notificationId": "n_44444",
  "type": "milestone",
  "title": "45-Day Milestone!",
  "content": "You've reached 45 days of sobriety. Keep going!",
  "isRead": false,
  "snoozedUntil": null,
  "snoozeCount": 0,
  "expiresAt": 1782676500
}
```

**Note:** Notifications use a TTL index for auto-cleanup. Old notifications expire after 90 days.

---

### 4.32 Milestone

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `MILESTONE#<addictionId>#<days>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "MILESTONE#a_67890#30",
  "EntityType": "MILESTONE",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-11T00:00:00Z",
  "ModifiedAt": "2026-03-11T08:00:00Z",
  "milestoneId": "ms_55555",
  "addictionId": "a_67890",
  "type": "streak",
  "days": 30,
  "achievedAt": "2026-03-11T00:00:00Z",
  "celebrated": true,
  "coinImageUrl": "https://cdn.regalrecovery.com/coins/30-day.png"
}
```

**Access Patterns:**
| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| List milestones for user | find | PK=`USER#u_12345`, SK begins_with `MILESTONE#` | Primary |
| List milestones for addiction | find | PK=`USER#u_12345`, SK begins_with `MILESTONE#a_67890#` | Primary |
| Check if milestone exists | findOne | PK=`USER#u_12345`, SK=`MILESTONE#a_67890#30` | Primary |

---

### 4.33 Recovery Health Score (Daily Snapshot)

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `RHS#<YYYY-MM-DD>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "RHS#2026-03-28",
  "EntityType": "RHS",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T23:59:00Z",
  "ModifiedAt": "2026-03-28T23:59:00Z",
  "scoreId": "rhs_66666",
  "score": 82,
  "components": {
    "sobrietyStreak": 20,
    "checkInConsistency": 18,
    "meetingAttendance": 12,
    "supportNetworkEngagement": 10,
    "spiritualPractices": 8,
    "emotionalAwareness": 7,
    "commitmentCompliance": 7
  },
  "trend": "improving",
  "previousScore": 78
}
```

**Access Patterns:**
| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| Get today's RHS | findOne | PK=`USER#u_12345`, SK=`RHS#2026-03-28` | Primary |
| Get RHS trend (date range) | find | PK=`USER#u_12345`, SK between `RHS#2026-03-01` and `RHS#2026-03-28` | Primary |

---

### 4.34 Affirmation Pack

| Attribute | Pattern |
|-----------|---------|
| PK | `PACK#<packId>` |
| SK | `META` |

**Example Item:**
```json
{
  "PK": "PACK#pack_001",
  "SK": "META",
  "EntityType": "AFFIRMATION_PACK",
  "TenantId": "SYSTEM",
  "CreatedAt": "2026-01-01T00:00:00Z",
  "ModifiedAt": "2026-01-01T00:00:00Z",
  "packId": "pack_001",
  "name": "Daily Strength",
  "description": "30 affirmations for daily encouragement",
  "tier": "free",
  "price": 0,
  "affirmationCount": 30,
  "category": "encouragement"
}
```

---

### 4.35 Affirmation (within Pack)

| Attribute | Pattern |
|-----------|---------|
| PK | `PACK#<packId>` |
| SK | `AFFIRMATION#<affirmationId>` |

**Example Item:**
```json
{
  "PK": "PACK#pack_001",
  "SK": "AFFIRMATION#aff_001",
  "EntityType": "AFFIRMATION",
  "TenantId": "SYSTEM",
  "CreatedAt": "2026-01-01T00:00:00Z",
  "ModifiedAt": "2026-01-01T00:00:00Z",
  "affirmationId": "aff_001",
  "statement": "I am more than my past. Today I choose freedom.",
  "scriptureReference": "2 Corinthians 5:17",
  "category": "identity",
  "language": "en"
}
```

---

### 4.36 Custom Affirmation (User-Created)

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `AFFIRMATION#CUSTOM#<affirmationId>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "AFFIRMATION#CUSTOM#caff_001",
  "EntityType": "CUSTOM_AFFIRMATION",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-15T09:00:00Z",
  "ModifiedAt": "2026-03-15T09:00:00Z",
  "affirmationId": "caff_001",
  "statement": "My family deserves the best version of me.",
  "scriptureReference": "Philippians 4:13",
  "category": "family",
  "schedule": "daily"
}
```

---

### 4.37 User-Owned Pack (Purchase Record)

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `PACK#<packId>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "PACK#pack_002",
  "EntityType": "USER_PACK",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-10T14:00:00Z",
  "ModifiedAt": "2026-03-10T14:00:00Z",
  "packId": "pack_002",
  "purchasedAt": "2026-03-10T14:00:00Z",
  "transactionId": "txn_apple_123"
}
```

---

### 4.38 Assessment Result

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `ASSESSMENT#<type>#<ISO8601 timestamp>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "ASSESSMENT#sastr#2026-03-01T10:00:00Z",
  "EntityType": "ASSESSMENT",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-01T10:00:00Z",
  "ModifiedAt": "2026-03-01T10:00:00Z",
  "assessmentId": "as_77777",
  "type": "sastr",
  "responses": {
    "q1": 3, "q2": 4, "q3": 2, "q4": 5, "q5": 3,
    "q6": 4, "q7": 2, "q8": 3, "q9": 4, "q10": 3
  },
  "score": 33,
  "interpretation": "moderate",
  "previousScore": null
}
```

**Access Patterns:**
| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| List all assessments for user | find | PK=`USER#u_12345`, SK begins_with `ASSESSMENT#` | Primary |
| List assessments by type | find | PK=`USER#u_12345`, SK begins_with `ASSESSMENT#sastr#` | Primary |

---

### 4.39 Three Circles Tool

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `TOOL#THREE_CIRCLES` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "TOOL#THREE_CIRCLES",
  "EntityType": "THREE_CIRCLES",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-02-10T10:00:00Z",
  "ModifiedAt": "2026-03-20T14:00:00Z",
  "innerCircle": {
    "behaviors": ["pornography", "strip clubs", "anonymous encounters"],
    "description": "Bottom-line behaviors that constitute acting out"
  },
  "middleCircle": {
    "behaviors": ["browsing social media late at night", "isolating after dinner", "fantasy"],
    "description": "Warning signs and slippery behaviors"
  },
  "outerCircle": {
    "behaviors": ["calling sponsor", "attending meetings", "exercise", "prayer", "date nights"],
    "description": "Healthy recovery behaviors"
  }
}
```

---

### 4.40 Relapse Prevention Plan

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `TOOL#RELAPSE_PREVENTION` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "TOOL#RELAPSE_PREVENTION",
  "EntityType": "RELAPSE_PREVENTION",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-02-10T10:30:00Z",
  "ModifiedAt": "2026-03-25T16:00:00Z",
  "triggers": [
    { "trigger": "loneliness", "severity": "high", "copingStrategy": "Call sponsor or AP within 5 minutes" },
    { "trigger": "work stress", "severity": "medium", "copingStrategy": "Take a walk, do breathing exercise" },
    { "trigger": "late-night phone use", "severity": "high", "copingStrategy": "Phone charges outside bedroom by 9pm" }
  ],
  "actionSteps": [
    "Attend 3 meetings per week",
    "Daily morning prayer and evening check-in",
    "Weekly sponsor call (Wednesdays 7pm)",
    "No phone after 9pm"
  ],
  "emergencyContacts": [
    { "name": "Mike S.", "role": "sponsor", "phone": "+15551234567" },
    { "name": "988 Suicide & Crisis Lifeline", "role": "crisis", "phone": "988" }
  ]
}
```

---

### 4.41 Vision Statement

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `TOOL#VISION` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "TOOL#VISION",
  "EntityType": "VISION",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-02-15T09:00:00Z",
  "ModifiedAt": "2026-03-01T11:00:00Z",
  "content": "I am a man of integrity who is fully present for my wife and children. I lead with honesty, pursue emotional health, and build a legacy of freedom..."
}
```

---

### 4.42 Arousal Template

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `TOOL#AROUSAL_TEMPLATE` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "TOOL#AROUSAL_TEMPLATE",
  "EntityType": "AROUSAL_TEMPLATE",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-02-20T10:00:00Z",
  "ModifiedAt": "2026-03-15T14:00:00Z",
  "template": {
    "patterns": ["visual stimuli", "emotional distress", "boredom"],
    "peakTimes": ["late evening", "weekend afternoons"],
    "environmentalFactors": ["alone at home", "traveling for work"],
    "emotionalPrecursors": ["rejection", "loneliness", "anger"],
    "physicalPrecursors": ["fatigue", "hunger"]
  }
}
```

---

### 4.43 Backup Metadata

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `BACKUP#<ISO8601 timestamp>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "BACKUP#2026-03-28T22:00:00Z",
  "EntityType": "BACKUP",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T22:00:00Z",
  "ModifiedAt": "2026-03-28T22:00:00Z",
  "backupId": "bk_88888",
  "storageProvider": "icloud",
  "fileUri": "rr_backup_2026-03-28.enc",
  "sizeBytes": 524288,
  "itemCount": 1247,
  "includesEphemeral": false,
  "encryptionVersion": "v1"
}
```

---

### 4.44 Agent Conversation

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `AGENT_CONV#<conversationId>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "AGENT_CONV#ac_99999",
  "EntityType": "AGENT_CONVERSATION",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T15:00:00Z",
  "ModifiedAt": "2026-03-28T15:30:00Z",
  "conversationId": "ac_99999",
  "title": "Understanding my triggers",
  "messageCount": 12,
  "lastMessageAt": "2026-03-28T15:30:00Z",
  "context": {
    "topic": "trigger-analysis",
    "referencedEntities": ["URGE#2026-03-28T16:45:00Z"]
  }
}
```

---

### 4.45 Agent Conversation Message

| Attribute | Pattern |
|-----------|---------|
| PK | `AGENT#<conversationId>` |
| SK | `MSG#<ISO8601 timestamp>#<sequence>` |

**Example Item:**
```json
{
  "PK": "AGENT#ac_99999",
  "SK": "MSG#2026-03-28T15:00:00Z#001",
  "EntityType": "AGENT_MESSAGE",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T15:00:00Z",
  "ModifiedAt": "2026-03-28T15:00:00Z",
  "role": "user",
  "content": "I keep getting triggered late at night. What patterns do you see?",
  "tokensUsed": 0
}
```

---

### 4.46 Session

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `SESSION#<sessionId>` |
| (indexed) | `SESSION#<sessionId>` |
| (indexed) | `META` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "SESSION#sess_11111",
  "EntityType": "SESSION",
  "_emailIndex": "SESSION#sess_11111",
  "_indexKey": "META",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T10:00:00Z",
  "ModifiedAt": "2026-03-28T10:00:00Z",
  "sessionId": "sess_11111",
  "deviceId": "dev_iphone_001",
  "ipAddress": "192.168.1.100",
  "userAgent": "RegalRecovery/1.0 iOS/17.4",
  "expiresAt": 1777540800
}
```

**Access Patterns:**
| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| List user's active sessions | find | PK=`USER#u_12345`, SK begins_with `SESSION#` | Primary |
| Lookup session by ID | find (indexed) | query: `SESSION#sess_11111` | Secondary |
| Auto-expire sessions | TTL | `expiresAt` attribute | N/A |

---

### 4.47 Audit Trail Entry

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `AUDIT#<ISO8601 timestamp>#<sequence>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "AUDIT#2026-03-28T16:00:00Z#001",
  "EntityType": "AUDIT",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T16:00:00Z",
  "ModifiedAt": "2026-03-28T16:00:00Z",
  "auditId": "aud_22222",
  "accessorUserId": "u_54321",
  "accessorRole": "sponsor",
  "accessorDisplayName": "Mike S.",
  "dataCategory": "check-ins",
  "action": "view",
  "resourceId": "CHECKIN#2026-03-28T21:00:00Z",
  "ipAddress": "10.0.0.50",
  "expiresAt": 1809208800
}
```

**Note:** Audit entries expire after 1 year via TTL index (per Section 10.3.8). `expiresAt` is set to creation time + 365 days.

**Access Patterns:**
| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| List audit trail for user | find | PK=`USER#u_12345`, SK begins_with `AUDIT#`, ScanIndexForward=false | Primary |
| List audit trail by date range | find | PK=`USER#u_12345`, SK between `AUDIT#<start>` and `AUDIT#<end>` | Primary |

---

### 4.48 Calendar Activity (Composite View)

**Description:** Denormalized activity entries optimized for the calendar view. Written alongside the canonical entity item (dual-write).

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `ACTIVITY#<YYYY-MM-DD>#<activityType>#<ISO8601 timestamp>` |

**Example Items (one day):**
```json
[
  {
    "PK": "USER#u_12345",
    "SK": "ACTIVITY#2026-03-28#CHECKIN#2026-03-28T21:00:00Z",
    "EntityType": "CALENDAR_ACTIVITY",
    "activityType": "CHECKIN",
    "summary": { "score": 85, "colorCode": "green" },
    "sourceKey": "CHECKIN#2026-03-28T21:00:00Z"
  },
  {
    "PK": "USER#u_12345",
    "SK": "ACTIVITY#2026-03-28#URGE#2026-03-28T16:45:00Z",
    "EntityType": "CALENDAR_ACTIVITY",
    "activityType": "URGE",
    "summary": { "intensity": 8, "sobrietyMaintained": true },
    "sourceKey": "URGE#2026-03-28T16:45:00Z"
  },
  {
    "PK": "USER#u_12345",
    "SK": "ACTIVITY#2026-03-28#JOURNAL#2026-03-28T09:30:00Z",
    "EntityType": "CALENDAR_ACTIVITY",
    "activityType": "JOURNAL",
    "summary": { "mode": "morning", "hasContent": true },
    "sourceKey": "JOURNAL#2026-03-28T09:30:00Z"
  },
  {
    "PK": "USER#u_12345",
    "SK": "ACTIVITY#2026-03-28#MEETING#2026-03-28T19:00:00Z",
    "EntityType": "CALENDAR_ACTIVITY",
    "activityType": "MEETING",
    "summary": { "meetingType": "SAA", "name": "Tuesday Night Recovery" },
    "sourceKey": "MEETING#2026-03-28T19:00:00Z"
  }
]
```

**Access Patterns:**
| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| Get all activities for a day | find | PK=`USER#u_12345`, SK begins_with `ACTIVITY#2026-03-28#` | Primary |
| Get all activities for a month | find | PK=`USER#u_12345`, SK between `ACTIVITY#2026-03-01` and `ACTIVITY#2026-03-31~` | Primary |
| Get activities of one type for a month | find | PK=`USER#u_12345`, SK between `ACTIVITY#2026-03-01#CHECKIN` and `ACTIVITY#2026-03-31#CHECKIN~` | Primary |

---

### 4.49 Tenant

| Attribute | Pattern |
|-----------|---------|
| PK | `TENANT#<tenantId>` |
| SK | `META` |

**Example Item:**
```json
{
  "PK": "TENANT#t_acme",
  "SK": "META",
  "EntityType": "TENANT",
  "TenantId": "t_acme",
  "CreatedAt": "2026-01-01T00:00:00Z",
  "ModifiedAt": "2026-03-15T10:00:00Z",
  "tenantId": "t_acme",
  "name": "ACME Recovery Center",
  "domain": "acme.regalrecovery.com",
  "dataRegion": "us-east-1",
  "brandingConfig": {
    "primaryColor": "#1A5276",
    "logoUrl": "https://cdn.regalrecovery.com/tenants/acme/logo.png"
  },
  "subscriptionTier": "enterprise",
  "maxUsers": 500,
  "activeUsers": 127
}
```

---

### 4.50 Tenant Content

| Attribute | Pattern |
|-----------|---------|
| PK | `TENANT#<tenantId>` |
| SK | `CONTENT#<contentType>#<contentId>` |

**Example Item:**
```json
{
  "PK": "TENANT#t_acme",
  "SK": "CONTENT#devotional#tc_001",
  "EntityType": "TENANT_CONTENT",
  "TenantId": "t_acme",
  "CreatedAt": "2026-02-01T10:00:00Z",
  "ModifiedAt": "2026-02-01T10:00:00Z",
  "contentId": "tc_001",
  "type": "devotional",
  "title": "Daily Hope - Day 1",
  "content": "Today we begin a journey of healing...",
  "tier": "premium"
}
```

---

### 4.51 Relapse Event

| Attribute | Pattern |
|-----------|---------|
| userId | `<userId>` |
| key | `RELAPSE#<ISO8601 timestamp>` |

**Example Item:**
```json
{
  "PK": "USER#u_12345",
  "SK": "RELAPSE#2026-03-28T22:15:00Z",
  "EntityType": "RELAPSE",
  "TenantId": "DEFAULT",
  "CreatedAt": "2026-03-28T22:16:00Z",
  "ModifiedAt": "2026-03-28T22:16:00Z",
  "relapseId": "r_98765",
  "addictionId": "a_67890",
  "timestamp": "2026-03-28T22:15:00Z",
  "previousStreakDays": 47,
  "notes": "Detailed notes about the event",
  "postMortemCompleted": false
}
```

---

### 4.52 Feature Flag

**Description:** Feature flag configuration for runtime control of features, activities, and tools.

| Attribute | Pattern |
|-----------|---------|
| PK | `FLAGS` |
| SK | `{flagKey}` |

**Example Item:**
```json
{
  "PK": "FLAGS",
  "SK": "feature.recovery-agent",
  "EntityType": "FEATURE_FLAG",
  "TenantId": "SYSTEM",
  "CreatedAt": "2026-03-01T00:00:00Z",
  "ModifiedAt": "2026-04-01T12:00:00Z",
  "enabled": true,
  "rolloutPercentage": 100,
  "tiers": ["premium", "premium-plus"],
  "tenants": ["*"],
  "platforms": ["ios", "android"],
  "minAppVersion": "1.2.0",
  "description": "AI-powered Recovery Agent with guided tool walkthroughs",
  "updatedAt": "2026-04-01T12:00:00Z",
  "updatedBy": "admin@regalrecovery.com"
}
```

**Access Patterns:**
| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| Get all flags | find | PK=`FLAGS` | Primary |
| Get single flag | findOne | PK=`FLAGS`, SK=`{flagKey}` | Primary |
| Update flag | updateOne (upsert) | PK=`FLAGS`, SK=`{flagKey}` | Primary |

**Note:** Cached in Valkey with 60-second TTL. A single query on the `featureFlags` collection returns all flags for efficient client fetch.

---

### 4.53 Feature Flag Audit

**Description:** Audit trail of all changes to feature flags.

| Attribute | Pattern |
|-----------|---------|
| PK | `FLAG_AUDIT#{flagKey}` |
| SK | `{timestamp}` |

**Example Item:**
```json
{
  "PK": "FLAG_AUDIT#feature.recovery-agent",
  "SK": "2026-04-01T12:00:00Z",
  "EntityType": "FLAG_AUDIT",
  "TenantId": "SYSTEM",
  "CreatedAt": "2026-04-01T12:00:00Z",
  "ModifiedAt": "2026-04-01T12:00:00Z",
  "changedBy": "admin@regalrecovery.com",
  "changes": [
    {
      "field": "rolloutPercentage",
      "oldValue": 25,
      "newValue": 50
    },
    {
      "field": "tiers",
      "oldValue": ["*"],
      "newValue": ["premium", "premium-plus"]
    }
  ]
}
```

**Access Patterns:**
| Pattern | Operation | Key Condition | Consistency |
|---------|-----------|---------------|-------------|
| Get audit for flag | find | PK=`FLAG_AUDIT#{flagKey}`, ScanIndexForward=false | Primary |

**Note:** Newest changes first via `sort({ timestamp: -1 })`.

---

## 5. Access Pattern Reference

### Complete Access Pattern Matrix

| # | Access Pattern | Collection/Index | Query | Filter/Sort | Operation | Read Preference |
|---|---------------|-----------|----|--------------|-----------| ------------|
| 1 | Get user profile | Table | `USER#<userId>` | `= PROFILE` | findOne | Primary |
| 2 | Get user settings | Table | `USER#<userId>` | `= SETTINGS` | findOne | Primary |
| 3 | Lookup user by email | Index | `EMAIL#<email>` | -- | find | Secondary |
| 4 | List users by tenant | Index | `TENANT#<tenantId>` | -- | find | Secondary |
| 5 | List addictions | Table | `USER#<userId>` | begins_with `ADDICTION#` | find | Primary |
| 6 | Get streak | Table | `USER#<userId>` | `= STREAK#<addictionId>` | findOne | Primary |
| 7 | List all streaks | Table | `USER#<userId>` | begins_with `STREAK#` | find | Primary |
| 8 | Get recent check-ins | Table | `USER#<userId>` | begins_with `CHECKIN#` | Query (desc) | Primary |
| 9 | Check-ins by date range | Table | `USER#<userId>` | between `CHECKIN#<start>` and `CHECKIN#<end>` | find | Primary |
| 10 | Get recent urges | Table | `USER#<userId>` | begins_with `URGE#` | Query (desc) | Primary |
| 11 | Get recent journals | Table | `USER#<userId>` | begins_with `JOURNAL#` | Query (desc) | Primary |
| 12 | List commitments | Table | `USER#<userId>` | begins_with `COMMITMENT#` | find | Primary |
| 13 | List milestones | Table | `USER#<userId>` | begins_with `MILESTONE#` | find | Primary |
| 14 | Milestones by addiction | Table | `USER#<userId>` | begins_with `MILESTONE#<addictionId>#` | find | Primary |
| 15 | List support contacts | Table | `USER#<userId>` | begins_with `CONTACT#` | find | Primary |
| 16 | Reverse contact lookup | Index | `CONTACT#<contactUserId>` | -- | find | Secondary |
| 17 | List permissions | Table | `USER#<userId>` | begins_with `PERMISSION#` | find | Primary |
| 18 | Permissions for contact | Table | `USER#<userId>` | begins_with `PERMISSION#<contactId>#` | find | Primary |
| 19 | Check specific permission | Table | `USER#<userId>` | `= PERMISSION#<contactId>#<category>` | findOne | Primary |
| 20 | Messages in conversation | Table | `CONVERSATION#<id>` | begins_with `MESSAGE#` | Query (desc) | Primary |
| 21 | User inbox | Index | `USER#<recipientId>` | begins_with `MESSAGE#` | Query (desc) | Secondary |
| 22 | User notifications | Table | `USER#<userId>` | begins_with `NOTIFICATION#` | Query (desc) | Primary |
| 23 | User backups | Table | `USER#<userId>` | begins_with `BACKUP#` | Query (desc) | Primary |
| 24 | RHS by date range | Table | `USER#<userId>` | between `RHS#<start>` and `RHS#<end>` | find | Primary |
| 25 | FASTER entries | Table | `USER#<userId>` | begins_with `FASTER#` | Query (desc) | Primary |
| 26 | PCI entries | Table | `USER#<userId>` | begins_with `PCI#` | Query (desc) | Primary |
| 27 | Meeting logs | Table | `USER#<userId>` | begins_with `MEETING#` | Query (desc) | Primary |
| 28 | Affirmations in pack | Table | `PACK#<packId>` | begins_with `AFFIRMATION#` | find | Primary |
| 29 | Custom affirmations | Table | `USER#<userId>` | begins_with `AFFIRMATION#CUSTOM#` | find | Primary |
| 30 | Owned packs | Table | `USER#<userId>` | begins_with `PACK#` | find | Primary |
| 31 | Assessments by type | Table | `USER#<userId>` | begins_with `ASSESSMENT#<type>#` | find | Primary |
| 32 | All assessments | Table | `USER#<userId>` | begins_with `ASSESSMENT#` | find | Primary |
| 33 | Tool data (3 Circles) | Table | `USER#<userId>` | `= TOOL#THREE_CIRCLES` | findOne | Primary |
| 34 | Tool data (RPP) | Table | `USER#<userId>` | `= TOOL#RELAPSE_PREVENTION` | findOne | Primary |
| 35 | Tool data (Vision) | Table | `USER#<userId>` | `= TOOL#VISION` | findOne | Primary |
| 36 | Tool data (Arousal) | Table | `USER#<userId>` | `= TOOL#AROUSAL_TEMPLATE` | findOne | Primary |
| 37 | Calendar: day view | Table | `USER#<userId>` | begins_with `ACTIVITY#<YYYY-MM-DD>#` | find | Primary |
| 38 | Calendar: month view | Table | `USER#<userId>` | between `ACTIVITY#<month-start>` and `ACTIVITY#<month-end>~` | find | Primary |
| 39 | Audit trail | Table | `USER#<userId>` | begins_with `AUDIT#` | Query (desc) | Primary |
| 40 | User sessions | Table | `USER#<userId>` | begins_with `SESSION#` | find | Primary |
| 41 | Session by ID | Index | `SESSION#<sessionId>` | `= META` | find | Secondary |
| 42 | Tenant metadata | Table | `TENANT#<tenantId>` | `= META` | findOne | Primary |
| 43 | Tenant content | Table | `TENANT#<tenantId>` | begins_with `CONTENT#` | find | Primary |
| 44 | Agent conversations | Table | `USER#<userId>` | begins_with `AGENT_CONV#` | find | Primary |
| 45 | Agent messages | Table | `AGENT#<conversationId>` | begins_with `MSG#` | find | Primary |
| 46 | Goals | Table | `USER#<userId>` | begins_with `GOAL#` | find | Primary |
| 47 | Step work by step | Table | `USER#<userId>` | begins_with `STEPWORK#<stepNum>#` | find | Primary |
| 48 | Relapse history | Table | `USER#<userId>` | begins_with `RELAPSE#` | Query (desc) | Primary |
| 49 | Mood ratings | Table | `USER#<userId>` | begins_with `MOOD#` | Query (desc) | Primary |
| 50 | Gratitude entries | Table | `USER#<userId>` | begins_with `GRATITUDE#` | Query (desc) | Primary |
| 51 | Emotional journal | Table | `USER#<userId>` | begins_with `EMOTIONAL#` | Query (desc) | Primary |
| 52 | Get all feature flags | Table | `FLAGS` | -- | find | Primary |
| 53 | Get single feature flag | Table | `FLAGS` | `= {flagKey}` | findOne | Primary |
| 54 | Update feature flag | Table | `FLAGS` | `= {flagKey}` | updateOne (upsert) | Primary |
| 55 | Get flag audit history | Table | `FLAG_AUDIT#{flagKey}` | -- | Query (desc) | Primary |

---

## 6. Document Size Estimates

### Average Document Size by Entity Type

| Entity | Avg. Doc Size | Frequency per User per Day | Notes |
|--------|---------------|---------------------------|-------|
| User Profile | 600 B | -- | 1 per user |
| User Settings | 400 B | -- | 1 per user |
| Addiction | 200 B | -- | 1-3 per user |
| Streak | 200 B | -- | 1 per addiction |
| Check-In | 500 B | 1-2 | Daily + optional evening |
| Urge Log | 400 B | 0-5 | Varies widely |
| Journal Entry | 1.5 KB | 0-2 | Content-heavy |
| FASTER Scale | 350 B | 0-1 | |
| PCI Entry | 300 B | 0-1 | Weekly typical |
| Mood Rating | 250 B | 1-3 | |
| Gratitude Entry | 300 B | 0-1 | |
| Phone Call Log | 200 B | 0-2 | |
| Prayer Log | 400 B | 0-1 | |
| Meeting Log | 350 B | 0-1 | 3x/week typical |
| Exercise Log | 250 B | 0-1 | |
| Nutrition Log | 250 B | 0-3 | |
| Integrity Inventory | 400 B | 0-1 | |
| Time Journal | 1.2 KB | 0-24 | Interval-based (30-60 min); includes GPS, sensor data, optional selfie S3 key |
| Emotional Journal | 700 B | 0-2 | Includes GPS location, optional selfie S3 key |
| Post-Mortem | 1.2 KB | Rare | On relapse only |
| FANOS Entry | 600 B | 0-1 | Weekly typical |
| Financial Entry | 250 B | 0-1 | |
| Acting-In Log | 250 B | 0-2 | |
| Goal | 500 B | -- | 3-10 per user |
| Devotional Completion | 400 B | 0-1 | |
| Step Work Entry | 1 KB | 0-1 | |
| Commitment | 350 B | -- | 5-15 per user |
| Support Contact | 400 B | -- | 2-5 per user |
| Permission | 250 B | -- | 5-20 per user |
| Message | 400 B | 0-10 | |
| Notification | 350 B | 1-5 | |
| Milestone | 300 B | Rare | On achievement |
| RHS Snapshot | 400 B | 1 | Daily |
| Affirmation | 300 B | -- | System content |
| Custom Affirmation | 300 B | -- | 0-10 per user |
| Pack Ownership | 200 B | -- | 0-5 per user |
| Assessment | 500 B | Rare | Quarterly typical |
| Tool (3 Circles) | 800 B | -- | 1 per user |
| Tool (RPP) | 1 KB | -- | 1 per user |
| Tool (Vision) | 500 B | -- | 1 per user |
| Tool (Arousal Template) | 600 B | -- | 1 per user |
| Backup Metadata | 300 B | Rare | |
| Agent Conversation | 350 B | 0-2 | |
| Agent Message | 500 B | 0-20 | Per conversation |
| Session | 300 B | -- | 1-3 per user |
| Audit Entry | 350 B | 0-5 | On data access by contacts |
| Calendar Activity | 250 B | 3-15 | Mirror of activity items |
| Feature Flag | 400 B | -- | System-wide (not per-user) |
| Flag Audit Entry | 350 B | Rare | System-wide (on flag changes) |

### Estimated Storage per User at 1 Year

**Assumptions:**
- Active user logging 8 activities per day on average
- Calendar activity dual-writes add ~50% more items
- 10 messages per week
- 5 notifications per day (most auto-expire)

| Category | Items per Year | Avg. Size | Storage |
|----------|---------------|-----------|---------|
| Static data (profile, settings, tools, addictions, streaks, contacts, permissions) | ~40 | 400 B | 16 KB |
| Daily activities (check-ins, urges, journals, mood, etc.) | ~2,920 | 400 B | 1.14 MB |
| Time journal entries (avg 8/day for active users) | ~2,920 | 1.2 KB | 3.42 MB |
| Calendar activity mirrors | ~5,840 | 250 B | 1.43 MB |
| Messages | ~520 | 400 B | 203 KB |
| Notifications (90-day TTL effective) | ~450 | 350 B | 154 KB |
| RHS daily snapshots | ~365 | 400 B | 143 KB |
| Milestones | ~10 | 300 B | 3 KB |
| Audit trail (1-year TTL) | ~500 | 350 B | 171 KB |
| Commitments | ~10 | 350 B | 3.4 KB |
| Goals | ~5 | 500 B | 2.5 KB |
| Assessments | ~4 | 500 B | 2 KB |
| Agent conversations + messages | ~100 | 450 B | 44 KB |
| **Total per active user per year** | **~14,744** | | **~7.5 MB** |

### Estimated Total Storage

| Timeframe | Total Users | Active Users (DAU) | Total Storage |
|-----------|------------|-------------------|---------------|
| Year 1 | 25,000 | 5,000 | ~37.5 GB active + ~7.5 GB inactive = ~45 GB |
| Year 3 | 550,000 | 110,000 | ~825 GB active + ~165 GB inactive = ~990 GB |

---

## 7. Capacity Planning

### Year 1 (25,000 users, 5,000 DAU)

**Assumptions:**
- 40 API calls per DAU per day (from AWS infrastructure doc)
- 60% reads, 40% writes
- Peak multiplier: 3x average (morning + evening check-in spikes)

| Metric | Average | Peak (3x) |
|--------|---------|-----------|
| API calls/day | 200,000 | -- |
| API calls/second (avg) | 2.3 | 6.9 |
| Read requests/second | 1.4 | 4.2 |
| Write requests/second | 0.9 | 2.8 |

**MongoDB Atlas Serverless billing estimate (Year 1):**
- Read processing units: ~50M/month
- Write processing units: ~10M/month
- Storage: 45 GB
- **Total MongoDB Atlas: ~$30-40/month**

### Year 3 (550,000 users, 110,000 DAU)

| Metric | Average | Peak (3x) |
|--------|---------|-----------|
| API calls/day | 4,400,000 | -- |
| API calls/second (avg) | 51 | 153 |
| Read requests/second | 30.6 | 91.8 |
| Write requests/second | 20.4 | 61.2 |

**MongoDB Atlas Dedicated billing estimate (Year 3):**
- Compute: M30+ dedicated cluster (~$400/month)
- Storage: 990 GB (~$250/month)
- Index storage: ~300 GB (~$75/month)
- **Total MongoDB Atlas: ~$725/month**

**Note:** At Year 3 scale, MongoDB Atlas auto-scaling handles traffic spikes. Consider reserved instance pricing for dedicated clusters when usage patterns stabilize around Year 2.

### Index Capacity

Indexes are maintained automatically by MongoDB. Key indexes:

| Index | Collections Covered | Primary Use Cases |
|-------|-------------------|-------------------|
| email index | users | User lookup by email |
| tenantId index | users, tenantContent | Tenant admin queries |
| userId + timestamp compound | All activity collections | Chronological queries per user |
| contactUserId index | contacts | Reverse contact lookup |
| recipientId index | messages | Inbox queries |

---

## 8. Operational Considerations

### 8.1 Hot Collection Prevention

- User-centric indexing distributes load efficiently across the working set.
- System content (affirmation packs) is read-heavy but low-volume. If a single pack gets hot, add a Valkey cache layer.
- Calendar month queries touch at most ~450 documents per user per month -- well within MongoDB's query performance limits.

### 8.2 Backup and Recovery

- **Continuous Backup:** Enabled with 35-day window (MongoDB Atlas continuous backup with point-in-time restore).
- **Daily snapshots:** MongoDB Atlas creates nightly snapshots with 90-day retention.
- **RTO:** 4 hours for full database restore from PITR. Minutes for individual collection recovery.
- **RPO:** Seconds (continuous backup), 24 hours (daily snapshots).

### 8.3 Data Deletion

- **Account deletion (FR1.4):** Delete all documents where `userId` matches across all collections. Also delete conversation messages where the user is a participant. Purge within 30 days.
- **Ephemeral data:** TTL indexes handle automatic deletion. MongoDB removes expired documents shortly after the `expiresAt` timestamp.
- **Audit trail:** 1-year TTL auto-cleanup.
- **Notifications:** 90-day TTL auto-cleanup.

### 8.4 Migration Strategy

If schema changes are needed post-launch:

1. Add new fields alongside existing ones (additive change). MongoDB's flexible schema makes this straightforward.
2. Create new indexes before migrating queries.
3. Backfill historical documents with new fields using bulk update operations.
4. Switch reads to use new fields/indexes.
5. Remove deprecated fields in a cleanup migration.

This expand-and-contract approach avoids downtime.

### 8.5 Monitoring

**MongoDB Atlas alerts:**
- Opcounters (reads/writes per second) trending toward cluster limits
- Query targeting ratio alerts (queries scanning too many documents)
- Connection pool utilization
- Replication lag (for replica sets)
- Database size growth rate (capacity planning)

### 8.6 Document Size Limits

MongoDB limits individual documents to 16 MB. No single entity in this schema approaches this limit (the largest documents, such as post-mortem analyses, are ~1.2 KB). For collections with heavy per-user activity, compound indexes on `{ userId, timestamp }` ensure efficient range queries regardless of collection size.

---

## Related Documents

- [API Data Model](../../docs/architecture/api-data-model.md)
- [AWS Infrastructure](../../docs/architecture/aws-infrastructure.md)
- [Technical Architecture](../../docs/03-technical-architecture.md)
- [Development Workflow](../development-workflow.md)
