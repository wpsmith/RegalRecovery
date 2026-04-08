# Affirmations -- MongoDB Schema Design

**Version:** 1.0.0
**Date:** 2026-04-08
**Status:** Draft
**Parent Schema:** `docs/specs/mongodb/schema-design.md`

Extends the main schema with detailed Affirmations domain entities, indexes, and access patterns. The Affirmations feature spans 8 collections supporting the curated library, user sessions, favorites, hidden items, custom affirmations, audio recordings, settings, and progress tracking.

---

## 1. Collections

| Collection | Description |
|------------|-------------|
| `affirmationsLibrary` | Curated affirmation content (system-managed) |
| `affirmationSessions` | Completed morning, evening, and SOS sessions |
| `affirmationFavorites` | User-favorited affirmations (library or custom) |
| `affirmationHidden` | User-hidden affirmations with session hide counts |
| `affirmationCustom` | User-created affirmations |
| `affirmationAudioRecordings` | Metadata for own-voice audio recordings |
| `affirmationSettings` | Per-user notification times, track, level, and category preferences |
| `affirmationProgress` | Aggregated progress metrics, level history, and milestones |

---

## 2. Document Structures

### 2.1 `affirmationsLibrary`

System-managed curated affirmation content. Each document is a single affirmation tagged with level, core beliefs, category, track, and recovery stage per Section 3 of the Affirmations PRD.

**Example Document:**

```json
{
  "_id": ObjectId("664a1b2c3d4e5f6a7b8c9d0e"),
  "affirmationId": "aff_lib_a1b2c3d4e5",
  "text": "It is OK for me to talk to others about what I think and feel.",
  "level": 1,
  "coreBeliefs": [3],
  "category": "connection",
  "track": "standard",
  "recoveryStage": "early",
  "readingLevel": 6,
  "active": true,
  "createdAt": ISODate("2026-01-15T00:00:00Z"),
  "updatedAt": ISODate("2026-01-15T00:00:00Z")
}
```

**Field Reference:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | Yes | MongoDB document ID |
| `affirmationId` | String | Yes | Unique ID, pattern: `aff_lib_{alphanumeric}` |
| `text` | String | Yes | The affirmation text. Present-tense, positive framing. Max 8th-grade reading level. |
| `level` | Int32 | Yes | Progressive level 1-4 (1=Permission, 2=Process, 3=Tempered Identity, 4=Full Identity) |
| `coreBeliefs` | Array of Int32 | Yes | Carnes' core beliefs addressed (1=bad/unworthy, 2=unlovable, 3=needs unmet, 4=sex as primary need) |
| `category` | String | Yes | Enum: `self-worth`, `shame-resilience`, `healthy-relationships`, `connection`, `emotional-regulation`, `purpose-meaning`, `integrity-honesty`, `daily-strength`, `healthy-sexuality`, `sos-crisis` |
| `track` | String | Yes | Content track: `standard` or `faith-based` |
| `recoveryStage` | String | Yes | Target stage: `early`, `middle`, `established` |
| `readingLevel` | Int32 | Yes | Flesch-Kincaid grade level, max 8 |
| `active` | Boolean | Yes | Whether this affirmation is in active rotation. Default: `true` |
| `createdAt` | Date | Yes | Immutable creation timestamp |
| `updatedAt` | Date | Yes | Updated on content edits |

**Constraints:**

- `level` range: 1-4 inclusive
- `coreBeliefs` values: 1-4 inclusive; array min length 1
- `category` must be one of the 10 defined enum values
- `track` must be `standard` or `faith-based`
- `recoveryStage` must be `early`, `middle`, or `established`
- `readingLevel` max: 8
- `healthy-sexuality` category requires Level 3-4 only (enforced at application layer)
- `sos-crisis` category requires Level 1-2 only (enforced at application layer)
- Minimum 200 active affirmations at launch; 400+ at v2

---

### 2.2 `affirmationSessions`

Records each completed affirmation session. Session type determines which optional fields are populated. `createdAt` is immutable per FR2.7.

**Morning Session Example:**

```json
{
  "_id": ObjectId("664b2c3d4e5f6a7b8c9d0e1f"),
  "sessionId": "aff_sess_m1b2c3d4e5",
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "sessionType": "morning",
  "affirmationIds": ["aff_lib_a1b2c3d4e5", "aff_lib_f6g7h8i9j0", "aff_lib_k1l2m3n4o5"],
  "levelServed": 2,
  "intention": "Today I choose to be honest with my sponsor about how I'm feeling.",
  "dayRating": null,
  "reflection": null,
  "morningIntention": null,
  "breathingCompleted": null,
  "reachedOut": null,
  "postCheckInRating": null,
  "postCheckInTimestamp": null,
  "completedAt": ISODate("2026-04-08T07:15:00Z"),
  "skipped": false,
  "createdAt": ISODate("2026-04-08T07:10:00Z")
}
```

**Evening Session Example:**

```json
{
  "_id": ObjectId("664c3d4e5f6a7b8c9d0e1f20"),
  "sessionId": "aff_sess_e2c3d4e5f6",
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "sessionType": "evening",
  "affirmationIds": ["aff_lib_p6q7r8s9t0"],
  "levelServed": 2,
  "intention": null,
  "dayRating": 4,
  "reflection": "Had a good day. Stayed present when I felt tempted.",
  "morningIntention": "Today I choose to be honest with my sponsor about how I'm feeling.",
  "breathingCompleted": null,
  "reachedOut": null,
  "postCheckInRating": null,
  "postCheckInTimestamp": null,
  "completedAt": ISODate("2026-04-08T21:05:00Z"),
  "skipped": false,
  "createdAt": ISODate("2026-04-08T21:00:00Z")
}
```

**SOS Session Example:**

```json
{
  "_id": ObjectId("664d4e5f6a7b8c9d0e1f2030"),
  "sessionId": "aff_sess_s3d4e5f6g7",
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "sessionType": "sos",
  "affirmationIds": ["aff_lib_sos_x1y2z3", "aff_lib_sos_a4b5c6", "aff_lib_sos_d7e8f9"],
  "levelServed": 1,
  "intention": null,
  "dayRating": null,
  "reflection": null,
  "morningIntention": null,
  "breathingCompleted": true,
  "reachedOut": true,
  "postCheckInRating": 3,
  "postCheckInTimestamp": ISODate("2026-04-08T14:25:00Z"),
  "completedAt": ISODate("2026-04-08T14:15:00Z"),
  "skipped": false,
  "createdAt": ISODate("2026-04-08T14:10:00Z")
}
```

**Field Reference:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | Yes | MongoDB document ID |
| `sessionId` | String | Yes | Unique ID, pattern: `aff_sess_{alphanumeric}` |
| `userId` | String | Yes | Owner user ID |
| `tenantId` | String | Yes | Tenant identifier for multi-tenant isolation |
| `sessionType` | String | Yes | Enum: `morning`, `evening`, `sos` |
| `affirmationIds` | Array of String | Yes | IDs of affirmations shown (library or custom). Morning: 3, Evening: 1, SOS: 3 |
| `levelServed` | Int32 | Yes | The level (1-4) of affirmations served in this session |
| `intention` | String | No | Morning only. "Today I choose to..." stem completion |
| `dayRating` | Int32 | No | Evening only. Day rating 1-5 |
| `reflection` | String | No | Evening only. Optional free-text reflection |
| `morningIntention` | String | No | Evening only. Echo of the morning intention for review |
| `breathingCompleted` | Boolean | No | SOS only. Whether the 4-7-8 breathing exercise was completed |
| `reachedOut` | Boolean | No | SOS only. Whether the user tapped "Reach out to accountability partner" |
| `postCheckInRating` | Int32 | No | SOS only. Follow-up mood rating 1-5 (10 minutes post-SOS) |
| `postCheckInTimestamp` | Date | No | SOS only. When the post-SOS check-in was completed |
| `completedAt` | Date | Yes | When the session was finished |
| `skipped` | Boolean | Yes | Whether the session was skipped. Default: `false` |
| `createdAt` | Date | Yes | Immutable creation timestamp (FR2.7) |

**Constraints:**

- `sessionType` must be `morning`, `evening`, or `sos`
- `dayRating` range: 1-5 inclusive (evening sessions only)
- `postCheckInRating` range: 1-5 inclusive (SOS sessions only)
- `levelServed` range: 1-4; SOS sessions always 1-2
- `createdAt` is immutable -- never modified after creation
- `affirmationIds` min length 1

---

### 2.3 `affirmationFavorites`

Tracks user-favorited affirmations. An affirmation can be from the curated library or a user-created custom affirmation.

**Example Document:**

```json
{
  "_id": ObjectId("664e5f6a7b8c9d0e1f203040"),
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "affirmationId": "aff_lib_a1b2c3d4e5",
  "addedAt": ISODate("2026-04-05T08:30:00Z")
}
```

**Field Reference:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | Yes | MongoDB document ID |
| `userId` | String | Yes | Owner user ID |
| `tenantId` | String | Yes | Tenant identifier |
| `affirmationId` | String | Yes | ID of the favorited affirmation (`aff_lib_*` or `aff_cust_*`) |
| `addedAt` | Date | Yes | Timestamp when favorited |

**Constraints:**

- Unique compound on (`userId`, `affirmationId`) -- a user cannot favorite the same affirmation twice
- Favorites are prioritized in daily session content selection

---

### 2.4 `affirmationHidden`

Tracks affirmations hidden by a user. Hidden affirmations are permanently excluded from that user's rotation. The `sessionHideCount` field supports the clinical escalation trigger when a user hides 5+ affirmations in a single session.

**Example Document:**

```json
{
  "_id": ObjectId("664f6a7b8c9d0e1f20304050"),
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "affirmationId": "aff_lib_f6g7h8i9j0",
  "hiddenAt": ISODate("2026-04-06T07:12:00Z"),
  "sessionHideCount": 2
}
```

**Field Reference:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | Yes | MongoDB document ID |
| `userId` | String | Yes | Owner user ID |
| `tenantId` | String | Yes | Tenant identifier |
| `affirmationId` | String | Yes | ID of the hidden affirmation |
| `hiddenAt` | Date | Yes | Timestamp when hidden |
| `sessionHideCount` | Int32 | Yes | Running count of hides in the session where this hide occurred. Used for 5+ detection trigger. |

**Constraints:**

- Unique compound on (`userId`, `affirmationId`) -- an affirmation can only be hidden once per user
- When `sessionHideCount` >= 5, the application layer flags for clinical review and optionally prompts about connecting with a therapist

---

### 2.5 `affirmationCustom`

User-created affirmations. Available from Day 14 onward (enforced at application layer). Custom affirmations can be included in daily session rotation alongside curated content.

**Example Document:**

```json
{
  "_id": ObjectId("66506a7b8c9d0e1f20304050"),
  "customId": "aff_cust_u1v2w3x4y5",
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "text": "I showed courage today by calling my sponsor when I didn't want to.",
  "includeInRotation": true,
  "createdAt": ISODate("2026-04-01T09:00:00Z"),
  "updatedAt": ISODate("2026-04-01T09:00:00Z")
}
```

**Field Reference:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | Yes | MongoDB document ID |
| `customId` | String | Yes | Unique ID, pattern: `aff_cust_{alphanumeric}` |
| `userId` | String | Yes | Owner user ID |
| `tenantId` | String | Yes | Tenant identifier |
| `text` | String | Yes | User-authored affirmation text. Present-tense, positive framing encouraged but not enforced. |
| `includeInRotation` | Boolean | Yes | Whether to include in daily session alongside curated content |
| `createdAt` | Date | Yes | Immutable creation timestamp (FR2.7) |
| `updatedAt` | Date | Yes | Updated on text or rotation edits |

**Constraints:**

- `createdAt` is immutable
- `text` max length: 500 characters
- Day 14+ gate enforced at application layer, not schema level

---

### 2.6 `affirmationAudioRecordings`

Metadata for own-voice audio recordings of affirmations. Audio files are stored locally on-device by default (not synced to cloud without explicit opt-in). This collection tracks metadata for users who opt in to sync.

**Example Document:**

```json
{
  "_id": ObjectId("66516a7b8c9d0e1f20304050"),
  "recordingId": "aff_rec_r1s2t3u4v5",
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "affirmationId": "aff_lib_a1b2c3d4e5",
  "localPath": "/Documents/RegalRecovery/audio/aff_rec_r1s2t3u4v5.m4a",
  "format": "m4a",
  "durationSeconds": 12,
  "backgroundMusic": "ocean",
  "backgroundVolume": 0.6,
  "createdAt": ISODate("2026-04-03T08:00:00Z")
}
```

**Field Reference:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | Yes | MongoDB document ID |
| `recordingId` | String | Yes | Unique ID, pattern: `aff_rec_{alphanumeric}` |
| `userId` | String | Yes | Owner user ID |
| `tenantId` | String | Yes | Tenant identifier |
| `affirmationId` | String | Yes | ID of the affirmation recorded (`aff_lib_*` or `aff_cust_*`) |
| `localPath` | String | Yes | Device-local file path. Not synced by default. |
| `format` | String | Yes | Audio format. Currently always `m4a` (AAC, 64kbps min) |
| `durationSeconds` | Int32 | Yes | Recording duration in seconds. Max 60. |
| `backgroundMusic` | String | Yes | Ambient background selection: `nature`, `ocean`, `rain`, `soft-tones`, `silence` |
| `backgroundVolume` | Double | Yes | Background music volume relative to voice. Range 0.0-1.0. Default: `0.6` |
| `createdAt` | Date | Yes | Immutable creation timestamp |

**Constraints:**

- `durationSeconds` max: 60
- `backgroundVolume` range: 0.0-1.0
- `backgroundMusic` must be one of: `nature`, `ocean`, `rain`, `soft-tones`, `silence`
- Audio auto-pauses on headphone disconnect (enforced at native app layer)
- Audio files never shared with accountability partners

---

### 2.7 `affirmationSettings`

Per-user configuration for the affirmation experience. One document per user.

**Example Document:**

```json
{
  "_id": ObjectId("66526a7b8c9d0e1f20304050"),
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "morningTime": "07:00",
  "eveningTime": "21:00",
  "track": "standard",
  "levelOverride": null,
  "enabledCategories": [
    "self-worth",
    "shame-resilience",
    "healthy-relationships",
    "connection",
    "emotional-regulation",
    "purpose-meaning",
    "integrity-honesty",
    "daily-strength"
  ],
  "healthySexualityEnabled": false,
  "notificationsEnabled": true,
  "reEngagementEnabled": true,
  "audioAutoPlay": false,
  "updatedAt": ISODate("2026-04-01T12:00:00Z")
}
```

**Field Reference:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | Yes | MongoDB document ID |
| `userId` | String | Yes | Owner user ID |
| `tenantId` | String | Yes | Tenant identifier |
| `morningTime` | String | Yes | Morning session notification time, HH:MM format (24h) |
| `eveningTime` | String | Yes | Evening session notification time, HH:MM format (24h). Default: `"21:00"` |
| `track` | String | Yes | Content track: `standard` or `faith-based`. Default: `"standard"` |
| `levelOverride` | Int32 | No | Manual level selection (1-4). Null means auto-determined by sobriety counter + algorithm. |
| `enabledCategories` | Array of String | Yes | Active content categories. Default: all except `healthy-sexuality` |
| `healthySexualityEnabled` | Boolean | Yes | Explicit opt-in for healthy-sexuality category. Default: `false`. Requires 60+ days logged. |
| `notificationsEnabled` | Boolean | Yes | Whether push notifications are enabled for sessions. Default: `true` |
| `reEngagementEnabled` | Boolean | Yes | Whether re-engagement prompts after gaps are enabled. Default: `true` |
| `audioAutoPlay` | Boolean | Yes | Whether evening affirmation auto-plays as audio. Default: `false` |
| `updatedAt` | Date | Yes | Updated on any settings change |

**Constraints:**

- One document per user (upsert pattern)
- `morningTime` and `eveningTime` must be valid HH:MM strings (00:00-23:59)
- `levelOverride` range: 1-4 or null
- `healthySexualityEnabled` can only be set to `true` if user has 60+ days logged (enforced at application layer)
- `enabledCategories` values must be valid category enum values

---

### 2.8 `affirmationProgress`

Aggregated progress metrics for a user. One document per user, updated incrementally on session completion. Stores level history, milestones, and the 7-day no-repeat window for content selection.

**Example Document:**

```json
{
  "_id": ObjectId("66536a7b8c9d0e1f20304050"),
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "totalSessions": 47,
  "totalAffirmationsPracticed": 141,
  "totalSOSSessions": 3,
  "totalCustomCreated": 5,
  "totalAudioRecorded": 2,
  "currentLevel": 2,
  "daysAtCurrentLevel": 34,
  "levelHistory": [
    {
      "level": 1,
      "startedAt": ISODate("2026-02-15T00:00:00Z"),
      "endedAt": ISODate("2026-03-05T00:00:00Z")
    },
    {
      "level": 2,
      "startedAt": ISODate("2026-03-05T00:00:00Z"),
      "endedAt": null
    }
  ],
  "milestones": [
    {
      "type": "first_session",
      "achievedAt": ISODate("2026-02-15T07:15:00Z")
    },
    {
      "type": "sessions_10",
      "achievedAt": ISODate("2026-02-25T07:10:00Z")
    },
    {
      "type": "sessions_25",
      "achievedAt": ISODate("2026-03-12T07:12:00Z")
    },
    {
      "type": "first_custom",
      "achievedAt": ISODate("2026-04-01T09:00:00Z")
    },
    {
      "type": "first_audio",
      "achievedAt": ISODate("2026-04-03T08:00:00Z")
    }
  ],
  "lastSessionAt": ISODate("2026-04-08T07:15:00Z"),
  "lastServedAffirmationIds": [
    "aff_lib_a1b2c3d4e5",
    "aff_lib_f6g7h8i9j0",
    "aff_lib_k1l2m3n4o5",
    "aff_lib_p6q7r8s9t0",
    "aff_lib_sos_x1y2z3",
    "aff_lib_sos_a4b5c6",
    "aff_lib_sos_d7e8f9"
  ],
  "updatedAt": ISODate("2026-04-08T07:15:00Z")
}
```

**Field Reference:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | Yes | MongoDB document ID |
| `userId` | String | Yes | Owner user ID |
| `tenantId` | String | Yes | Tenant identifier |
| `totalSessions` | Int32 | Yes | Cumulative count of all completed sessions (morning + evening + SOS) |
| `totalAffirmationsPracticed` | Int32 | Yes | Cumulative count of individual affirmations shown across all sessions |
| `totalSOSSessions` | Int32 | Yes | Cumulative count of SOS sessions |
| `totalCustomCreated` | Int32 | Yes | Cumulative count of custom affirmations authored |
| `totalAudioRecorded` | Int32 | Yes | Cumulative count of audio recordings saved |
| `currentLevel` | Int32 | Yes | Current affirmation level (1-4). Determined by sobriety counter + algorithm or manual override. |
| `daysAtCurrentLevel` | Int32 | Yes | Days spent at current level. Resets on level change. |
| `levelHistory` | Array | Yes | Chronological record of level transitions |
| `levelHistory[].level` | Int32 | Yes | Level value (1-4) |
| `levelHistory[].startedAt` | Date | Yes | When the user entered this level |
| `levelHistory[].endedAt` | Date | No | When the user left this level. Null for current level. |
| `milestones` | Array | Yes | Achieved milestone events |
| `milestones[].type` | String | Yes | Milestone type (see milestone types below) |
| `milestones[].achievedAt` | Date | Yes | Timestamp of achievement |
| `lastSessionAt` | Date | No | Timestamp of most recent session completion |
| `lastServedAffirmationIds` | Array of String | Yes | Affirmation IDs served in the last 7 days. Used for no-repeat content selection. |
| `updatedAt` | Date | Yes | Updated on every session completion or level change |

**Milestone Types:**

| Type | Description |
|------|-------------|
| `first_session` | First session completed |
| `sessions_10` | 10th session completed |
| `sessions_25` | 25th session completed |
| `sessions_50` | 50th session completed |
| `sessions_100` | 100th session completed |
| `sessions_250` | 250th session completed |
| `first_custom` | First custom affirmation created |
| `first_audio` | First audio recording saved |
| `first_sos` | First SOS session completed ("Coming back in a hard moment is courage.") |

**Constraints:**

- One document per user (upsert pattern)
- `currentLevel` range: 1-4
- `lastServedAffirmationIds` rolling window: application layer prunes entries older than 7 days on each session completion
- Milestone achievement is idempotent -- each type can appear at most once

---

## 3. Indexes

### 3.1 Index Definitions

| Collection | Index Name | Fields | Type | Purpose |
|------------|-----------|--------|------|---------|
| `affirmationsLibrary` | `level_category_track` | `{ level: 1, category: 1, track: 1 }` | Compound | Content selection by level, category, and track (AP-AFF-01) |
| `affirmationsLibrary` | `text_search` | `{ text: "text" }` | Text | Full-text keyword search (AP-AFF-02) |
| `affirmationsLibrary` | `category_active` | `{ category: 1, active: 1 }` | Compound | Filter active affirmations by category |
| `affirmationSessions` | `userId_sessionType_completedAt` | `{ userId: 1, sessionType: 1, completedAt: -1 }` | Compound | Session history by type with reverse-chronological sort (AP-AFF-11) |
| `affirmationSessions` | `userId_createdAt` | `{ userId: 1, createdAt: -1 }` | Compound | All sessions for user reverse-chronological (AP-AFF-15, AP-AFF-16) |
| `affirmationFavorites` | `userId_affirmationId` | `{ userId: 1, affirmationId: 1 }` | Compound (unique) | Favorite lookup and dedup (AP-AFF-03, AP-AFF-04) |
| `affirmationFavorites` | `userId` | `{ userId: 1 }` | Single | List all favorites for user |
| `affirmationHidden` | `userId_affirmationId` | `{ userId: 1, affirmationId: 1 }` | Compound (unique) | Hidden lookup and dedup (AP-AFF-05, AP-AFF-06) |
| `affirmationHidden` | `userId` | `{ userId: 1 }` | Single | List all hidden for user |
| `affirmationCustom` | `userId_createdAt` | `{ userId: 1, createdAt: -1 }` | Compound | List custom affirmations reverse-chronological (AP-AFF-07) |
| `affirmationCustom` | `customId` | `{ customId: 1 }` | Single (unique) | Lookup by custom ID |
| `affirmationAudioRecordings` | `userId_affirmationId` | `{ userId: 1, affirmationId: 1 }` | Compound | Get recordings for a specific affirmation (AP-AFF-20) |
| `affirmationSettings` | `userId` | `{ userId: 1 }` | Single (unique) | Settings lookup (AP-AFF-14) |
| `affirmationProgress` | `userId` | `{ userId: 1 }` | Single (unique) | Progress lookup (AP-AFF-12, AP-AFF-13) |

### 3.2 Index Creation Scripts

```javascript
// affirmationsLibrary
db.affirmationsLibrary.createIndex(
  { level: 1, category: 1, track: 1 },
  { name: "level_category_track" }
);
db.affirmationsLibrary.createIndex(
  { text: "text" },
  { name: "text_search", default_language: "english" }
);
db.affirmationsLibrary.createIndex(
  { category: 1, active: 1 },
  { name: "category_active" }
);

// affirmationSessions
db.affirmationSessions.createIndex(
  { userId: 1, sessionType: 1, completedAt: -1 },
  { name: "userId_sessionType_completedAt" }
);
db.affirmationSessions.createIndex(
  { userId: 1, createdAt: -1 },
  { name: "userId_createdAt" }
);

// affirmationFavorites
db.affirmationFavorites.createIndex(
  { userId: 1, affirmationId: 1 },
  { unique: true, name: "userId_affirmationId_unique" }
);
db.affirmationFavorites.createIndex(
  { userId: 1 },
  { name: "userId" }
);

// affirmationHidden
db.affirmationHidden.createIndex(
  { userId: 1, affirmationId: 1 },
  { unique: true, name: "userId_affirmationId_unique" }
);
db.affirmationHidden.createIndex(
  { userId: 1 },
  { name: "userId" }
);

// affirmationCustom
db.affirmationCustom.createIndex(
  { userId: 1, createdAt: -1 },
  { name: "userId_createdAt" }
);
db.affirmationCustom.createIndex(
  { customId: 1 },
  { unique: true, name: "customId_unique" }
);

// affirmationAudioRecordings
db.affirmationAudioRecordings.createIndex(
  { userId: 1, affirmationId: 1 },
  { name: "userId_affirmationId" }
);

// affirmationSettings
db.affirmationSettings.createIndex(
  { userId: 1 },
  { unique: true, name: "userId_unique" }
);

// affirmationProgress
db.affirmationProgress.createIndex(
  { userId: 1 },
  { unique: true, name: "userId_unique" }
);
```

---

## 4. Calendar Activity Dual-Write

When a session is completed, a corresponding `calendarActivities` entry is written following entity 4.48 in the parent schema.

**Morning Session Calendar Entry:**

```json
{
  "PK": "USER#u_12345",
  "SK": "ACTIVITY#2026-04-08#AFFIRMATION#2026-04-08T07:15:00Z",
  "EntityType": "CALENDAR_ACTIVITY",
  "activityType": "AFFIRMATION",
  "summary": {
    "sessionType": "morning",
    "affirmationCount": 3,
    "levelServed": 2,
    "hasIntention": true,
    "skipped": false
  },
  "sourceKey": "aff_sess_m1b2c3d4e5"
}
```

**Evening Session Calendar Entry:**

```json
{
  "PK": "USER#u_12345",
  "SK": "ACTIVITY#2026-04-08#AFFIRMATION#2026-04-08T21:05:00Z",
  "EntityType": "CALENDAR_ACTIVITY",
  "activityType": "AFFIRMATION",
  "summary": {
    "sessionType": "evening",
    "affirmationCount": 1,
    "levelServed": 2,
    "dayRating": 4,
    "skipped": false
  },
  "sourceKey": "aff_sess_e2c3d4e5f6"
}
```

**SOS Session Calendar Entry:**

```json
{
  "PK": "USER#u_12345",
  "SK": "ACTIVITY#2026-04-08#AFFIRMATION#2026-04-08T14:15:00Z",
  "EntityType": "CALENDAR_ACTIVITY",
  "activityType": "AFFIRMATION",
  "summary": {
    "sessionType": "sos",
    "affirmationCount": 3,
    "levelServed": 1,
    "breathingCompleted": true,
    "reachedOut": true,
    "skipped": false
  },
  "sourceKey": "aff_sess_s3d4e5f6g7"
}
```

The dual-write enables the calendar view to display affirmation sessions alongside other recovery activities in a single query on `PK + SK prefix`.

---

## 5. Access Patterns

| # | Access Pattern | Collection | Query | Index Used |
|---|---------------|------------|-------|------------|
| AP-AFF-01 | Get library affirmations by level + category + track | `affirmationsLibrary` | `find({ level: 2, category: "connection", track: "standard", active: true }).skip(N).limit(M)` | `level_category_track` |
| AP-AFF-02 | Search library by keyword | `affirmationsLibrary` | `find({ $text: { $search: "courage" }, active: true })` | `text_search` |
| AP-AFF-03 | Get user favorites list | `affirmationFavorites` | `find({ userId: "u_12345" }).sort({ addedAt: -1 })` | `userId` |
| AP-AFF-04 | Check if affirmation is favorited | `affirmationFavorites` | `findOne({ userId: "u_12345", affirmationId: "aff_lib_a1b2c3d4e5" })` | `userId_affirmationId` |
| AP-AFF-05 | Get user hidden list | `affirmationHidden` | `find({ userId: "u_12345" })` | `userId` |
| AP-AFF-06 | Check if affirmation is hidden | `affirmationHidden` | `findOne({ userId: "u_12345", affirmationId: "aff_lib_f6g7h8i9j0" })` | `userId_affirmationId` |
| AP-AFF-07 | Get custom affirmations for user | `affirmationCustom` | `find({ userId: "u_12345" }).sort({ createdAt: -1 })` | `userId_createdAt` |
| AP-AFF-08 | Get morning session content | `affirmationsLibrary` + `affirmationFavorites` + `affirmationHidden` + `affirmationProgress` | Application-layer algorithm: (1) load favorites, hidden, last-7-day served IDs; (2) query library by level + track excluding hidden and recently served; (3) weight 80% current level, 20% one level above; (4) prioritize favorites; (5) ensure category variety | `level_category_track`, `userId_affirmationId`, `userId` |
| AP-AFF-09 | Get evening session content | `affirmationsLibrary` + `affirmationFavorites` + `affirmationHidden` | Same algorithm as AP-AFF-08 but selects 1 affirmation (calming, level-appropriate). Echoes the morning intention from that day's morning session. | `level_category_track`, `userId_sessionType_completedAt` |
| AP-AFF-10 | Get SOS content | `affirmationsLibrary` | `find({ level: { $lte: 2 }, category: "sos-crisis", track: settings.track, active: true })` | `level_category_track` |
| AP-AFF-11 | Get session history by type and date range | `affirmationSessions` | `find({ userId: "u_12345", sessionType: "morning", completedAt: { $gte: start, $lte: end } }).sort({ completedAt: -1 })` | `userId_sessionType_completedAt` |
| AP-AFF-12 | Get progress metrics for user | `affirmationProgress` | `findOne({ userId: "u_12345" })` | `userId` |
| AP-AFF-13 | Get level info and history | `affirmationProgress` | `findOne({ userId: "u_12345" }, { projection: { currentLevel: 1, daysAtCurrentLevel: 1, levelHistory: 1 } })` | `userId` |
| AP-AFF-14 | Get settings for user | `affirmationSettings` | `findOne({ userId: "u_12345" })` | `userId` |
| AP-AFF-15 | Count sessions in date range | `affirmationSessions` | `countDocuments({ userId: "u_12345", createdAt: { $gte: start, $lte: end } })` | `userId_createdAt` |
| AP-AFF-16 | Get 30-day consistency data | `affirmationSessions` | `aggregate([{ $match: { userId: "u_12345", createdAt: { $gte: thirtyDaysAgo } } }, { $group: { _id: { $dateToString: { format: "%Y-%m-%d", date: "$completedAt" } }, count: { $sum: 1 } } }])` | `userId_createdAt` |
| AP-AFF-17 | Check post-relapse window | External: sobriety tracking collection | `findOne({ userId: "u_12345", eventType: "relapse", timestamp: { $gte: twentyFourHoursAgo } })` | External index |
| AP-AFF-18 | Count hides in current session | `affirmationHidden` | `countDocuments({ userId: "u_12345", hiddenAt: { $gte: sessionStartTime } })` | `userId` |
| AP-AFF-19 | Get last 7 days served affirmations | `affirmationProgress` | `findOne({ userId: "u_12345" }, { projection: { lastServedAffirmationIds: 1 } })` | `userId` |
| AP-AFF-20 | Get audio recording metadata | `affirmationAudioRecordings` | `findOne({ userId: "u_12345", affirmationId: "aff_lib_a1b2c3d4e5" })` | `userId_affirmationId` |
| AP-AFF-21 | Calendar activity dual-write | `calendarActivities` | `insertOne({ PK: "USER#u_12345", SK: "ACTIVITY#2026-04-08#AFFIRMATION#...", ... })` | PK/SK compound |
| AP-AFF-22 | Get milestone achievements | `affirmationProgress` | `findOne({ userId: "u_12345" }, { projection: { milestones: 1 } })` | `userId` |
| AP-AFF-23 | Count consecutive sessions with mood decline | `affirmationSessions` | `find({ userId: "u_12345", sessionType: "evening", dayRating: { $ne: null } }).sort({ completedAt: -1 }).limit(10)` then application-layer check for 3+ consecutive declining ratings | `userId_sessionType_completedAt` |
| AP-AFF-24 | Get daily mood ratings from evening sessions | `affirmationSessions` | `find({ userId: "u_12345", sessionType: "evening", dayRating: { $ne: null }, completedAt: { $gte: start, $lte: end } }).sort({ completedAt: 1 })` | `userId_sessionType_completedAt` |
| AP-AFF-25 | Get sharing summary (session counts only) | `affirmationSessions` | `countDocuments({ userId: "u_12345", completedAt: { $gte: weekStart, $lte: weekEnd }, skipped: false })` | `userId_sessionType_completedAt` |

---

## 6. Document Size Estimates

| Collection | Avg. Doc Size | Frequency per User |
|------------|---------------|-------------------|
| `affirmationsLibrary` | 350 B | N/A (system content, 200-400 docs total) |
| `affirmationSessions` | 500 B | 2-3/day (morning + evening + occasional SOS) |
| `affirmationFavorites` | 150 B | 0-50 per user lifetime |
| `affirmationHidden` | 150 B | 0-30 per user lifetime |
| `affirmationCustom` | 300 B | 0-50 per user lifetime |
| `affirmationAudioRecordings` | 250 B | 0-20 per user lifetime |
| `affirmationSettings` | 400 B | 1 per user |
| `affirmationProgress` | 1.5 KB | 1 per user (grows with levelHistory and milestones) |

### Per-User Annual Storage (Active User)

| Category | Items/Year | Avg Size | Storage |
|----------|-----------|----------|---------|
| Sessions (2/day avg) | 730 | 500 B | 356 KB |
| Calendar mirrors | 730 | 250 B | 178 KB |
| Favorites | 25 | 150 B | 3.7 KB |
| Hidden | 10 | 150 B | 1.5 KB |
| Custom affirmations | 10 | 300 B | 3 KB |
| Audio metadata | 5 | 250 B | 1.3 KB |
| Settings | 1 | 400 B | 0.4 KB |
| Progress | 1 | 1.5 KB | 1.5 KB |
| **Total per user per year** | **~1,512** | | **~545 KB** |

All documents are well within MongoDB's 16 MB document limit. The `affirmationProgress` document grows slowly (9 milestones max, level transitions typically 3-4 per year).

---

## 7. Caching Strategy

| Data | Cache Key | TTL | Invalidation |
|------|-----------|-----|--------------|
| Morning session content (selected affirmations) | `affirmations:morning-content:{userId}` | 5 min | On favorite add/remove, hide add, settings change |
| SOS session content | `affirmations:sos-content:{userId}:{track}` | Cached locally on device | Always available offline. Server cache: 30 min TTL. |
| Progress metrics | `affirmations:progress:{userId}` | 10 min | On session completion |
| Settings | `affirmations:settings:{userId}` | 10 min | On settings update |
| Level info | `affirmations:level:{userId}` | 10 min | On level change, level override, or relapse event |
| Favorites list | `affirmations:favorites:{userId}` | 10 min | On favorite add/remove |
| Hidden list | `affirmations:hidden:{userId}` | 10 min | On hide add |
| 30-day consistency | `affirmations:consistency:{userId}` | 10 min | On session completion |
| Library page (by level+category+track) | `affirmations:library:{level}:{category}:{track}:{cursor}` | 30 min | On library content update (admin action) |

**Offline-First Design:**

- SOS content (Level 1-2, `sos-crisis` category) is cached locally on device at all times. Must work without internet.
- Minimum 30 affirmations from the user's current level and track are cached locally for morning/evening sessions.
- Sessions completed offline are stored locally and synced on reconnection (union merge -- all sessions kept).

---

## 8. Migration Notes

This is a new feature with no existing schema entities to migrate. All 8 collections are created fresh.

### Initial Data Seeding

1. **`affirmationsLibrary`:** Seed with 200+ curated affirmations reviewed by CSAT. Each affirmation must have all required tags (level, coreBeliefs, category, track, recoveryStage, readingLevel).
2. **`affirmationSettings`:** Created on user onboarding with defaults (standard track, all categories except healthy-sexuality, notifications enabled).
3. **`affirmationProgress`:** Created on first session completion with initial values (totalSessions=1, currentLevel=1, empty milestones array with `first_session` added).

### Feature Flag

Feature flag: `activity.affirmations`

- When disabled: all affirmation endpoints return 404, push notifications suppressed, calendar dual-writes skipped.
- When enabled: collections are available, onboarding flow includes affirmation setup.

---

## 9. Security and Privacy

- **Tenant isolation:** All queries include `tenantId` filter at the application layer.
- **User scoping:** All user-scoped queries are filtered by `userId`. No cross-user access.
- **Community permissions:** Accountability partners see session counts only (AP-AFF-25). No affirmation text, intentions, reflections, mood ratings, or custom content shared unless explicitly consented.
- **Therapist/sponsor view:** With user consent, therapist dashboard shows: practice consistency, hidden affirmation count, mood trend, level progression. No affirmation text or journal content.
- **Audio privacy:** Audio recordings stored locally only. Metadata synced only with opt-in. Audio files never shared with accountability partners.
- **Audit trail:** Data access by support network contacts logged as audit entries per entity 4.47 in the parent schema.
- **Offline sync:** Union merge for sessions (all sessions from all devices are kept). LWW for settings. Favorites and hidden items use union merge.
- **Data deletion (FR1.4):** On account deletion, all documents across all 8 collections for the user are removed. Calendar activity mirrors are also deleted.
