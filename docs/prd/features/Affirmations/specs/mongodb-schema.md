# Declarations of Truth (Affirmations) -- MongoDB Schema Design

**Version:** 2.0.0
**Date:** 2026-04-09
**Status:** Draft
**Parent Schema:** `docs/specs/mongodb/schema-design.md` (Sections 4.34-4.37)

This specification supersedes the v1 Affirmation entities (Sections 4.34-4.37) in the parent schema with a comprehensive pack-based architecture supporting default, premium, and custom packs; immersive session types; favorites/hidden curation; audio recordings; progressive level system; and purchase ownership.

---

## 1. Collections

The Affirmations v2 domain introduces 10 collections in the `regal-recovery` database:

| # | Collection | Scope | Description |
|---|-----------|-------|-------------|
| 1 | `affirmationPacks` | System + User | Pack catalog (default, premium, custom) |
| 2 | `affirmationsLibrary` | System | Curated declarations within packs |
| 3 | `affirmationCustomDeclarations` | User | User-written declarations in custom packs |
| 4 | `affirmationSessions` | User | Completed session records (morning/evening/sos/on-demand) |
| 5 | `affirmationFavorites` | User | User-favorited declarations |
| 6 | `affirmationHidden` | User | User-hidden declarations |
| 7 | `affirmationAudioRecordings` | User | Audio recording metadata (files stored on-device) |
| 8 | `affirmationSettings` | User | Per-user preferences and notification config |
| 9 | `affirmationProgress` | User | Cumulative metrics, level history, milestones |
| 10 | `affirmationPurchases` | User | Premium pack ownership records |

---

## 2. Document Structures

### 2.1 Collection: `affirmationPacks`

System-managed default/premium packs and user-created custom packs share a single collection with `type` discriminator.

```json
{
  "_id": ObjectId("..."),
  "packId": "pack_identity_christ",
  "entityType": "AFFIRMATION_PACK",
  "name": "Identity in Christ",
  "description": "30 declarations rooted in who God says you are.",
  "coverImage": "packs/identity-in-christ.jpg",
  "type": "default",
  "category": "identity",
  "primaryLevel": 2,
  "affirmationCount": 30,
  "price": null,
  "previewAffirmationIds": ["aff_001", "aff_002", "aff_003"],
  "active": true,
  "sortOrder": 1,
  "userId": null,
  "tenantId": "SYSTEM",
  "schedule": null,
  "includeInRotation": null,
  "createdAt": ISODate("2026-01-01T00:00:00Z"),
  "updatedAt": ISODate("2026-01-01T00:00:00Z")
}
```

**Custom pack example:**

```json
{
  "_id": ObjectId("..."),
  "packId": "cpack_u12345_morning_armor",
  "entityType": "AFFIRMATION_PACK",
  "name": "Morning Armor",
  "description": "My personal battle declarations.",
  "coverImage": "custom/sunrise-gradient.jpg",
  "type": "custom",
  "category": "custom",
  "primaryLevel": null,
  "affirmationCount": 7,
  "price": null,
  "previewAffirmationIds": [],
  "active": true,
  "sortOrder": 0,
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "schedule": "daily",
  "includeInRotation": true,
  "createdAt": ISODate("2026-04-01T09:00:00Z"),
  "updatedAt": ISODate("2026-04-05T14:30:00Z")
}
```

**Field Definitions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | auto | MongoDB document ID |
| `packId` | String | yes | Unique pack identifier. System packs: `pack_{slug}`. Custom packs: `cpack_{userId}_{slug}` |
| `entityType` | String | yes | Always `"AFFIRMATION_PACK"` |
| `name` | String | yes | Display name, max 100 chars |
| `description` | String | yes | Pack description, max 500 chars |
| `coverImage` | String | no | S3/CDN path to cover image |
| `type` | String (enum) | yes | `default`, `premium`, `custom` |
| `category` | String | yes | Theme category: `identity`, `shame`, `temptation`, `marriage`, `sos`, `evening`, `armor`, `freedom`, `healthy-sexuality`, `custom` |
| `primaryLevel` | Integer (1-4) | no | Primary content level (null for custom packs) |
| `affirmationCount` | Integer | yes | Total declarations in pack |
| `price` | Decimal | no | USD price for premium packs; null for default/custom |
| `previewAffirmationIds` | String[] | no | Up to 3 affirmation IDs for premium pack preview |
| `active` | Boolean | yes | Whether pack is visible in library |
| `sortOrder` | Integer | yes | Display ordering within type group |
| `userId` | String | no | Owner user ID (custom packs only; null for system packs) |
| `tenantId` | String | yes | `"SYSTEM"` for default/premium; tenant ID for custom |
| `schedule` | String (enum) | no | Custom pack schedule: `daily`, `weekdays`, `weekends`, `manual` (custom packs only) |
| `includeInRotation` | Boolean | no | Whether custom pack is included in daily rotation (custom packs only) |
| `createdAt` | Date | yes | Creation timestamp |
| `updatedAt` | Date | yes | Last modification timestamp |

**Validation Rules:**
- `type` must be one of: `default`, `premium`, `custom`
- `price` required and > 0 when `type` = `premium`; null otherwise
- `userId` required when `type` = `custom`; null otherwise
- `previewAffirmationIds` max length: 3
- Custom packs per user: max 20
- `category` = `healthy-sexuality` requires 60+ days sober AND explicit opt-in (enforced at application layer)

---

### 2.2 Collection: `affirmationsLibrary`

Curated declarations organized within packs. System-managed content.

```json
{
  "_id": ObjectId("..."),
  "affirmationId": "aff_001",
  "entityType": "AFFIRMATION",
  "packId": "pack_identity_christ",
  "text": "I am a new creation in Christ. The old has gone, the new has come.",
  "scriptureReference": "2 Corinthians 5:17",
  "scriptureText": "Therefore, if anyone is in Christ, the new creation has come: The old has gone, the new is here!",
  "expansion": "This truth strikes at the core belief that you are fundamentally flawed. In Christ, your identity is not defined by your addiction but by your redemption.",
  "prayer": "Lord, help me to see myself through Your eyes today -- not as broken, but as being made new.",
  "level": 2,
  "coreBeliefs": [1],
  "category": "identity",
  "tags": ["identity", "new-creation", "redemption", "shame-resilience"],
  "audioAvailable": true,
  "active": true,
  "createdAt": ISODate("2026-01-01T00:00:00Z"),
  "updatedAt": ISODate("2026-01-01T00:00:00Z")
}
```

**Field Definitions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | auto | MongoDB document ID |
| `affirmationId` | String | yes | Unique declaration ID (`aff_{alphanumeric}`) |
| `entityType` | String | yes | Always `"AFFIRMATION"` |
| `packId` | String | yes | Parent pack reference |
| `text` | String | yes | Declaration text, max 280 chars |
| `scriptureReference` | String | yes | Bible verse reference (e.g., "2 Corinthians 5:17") |
| `scriptureText` | String | yes | Full verse text (NIV default) |
| `expansion` | String | no | 1-2 sentence therapeutic/pastoral reflection |
| `prayer` | String | no | 1-2 sentence related prayer |
| `level` | Integer (1-4) | yes | Progressive level: 1=Permission, 2=Foundation, 3=Growth, 4=Identity |
| `coreBeliefs` | Integer[] | yes | Core beliefs addressed (1-4 per Carnes framework): 1="I am unworthy", 2="No one would love me if they knew", 3="I cannot trust anyone to meet my needs", 4="Sex is my most important need" |
| `category` | String | yes | Content category matching pack category |
| `tags` | String[] | no | Searchable tags for content discovery |
| `audioAvailable` | Boolean | yes | Whether professional narration is available |
| `active` | Boolean | yes | Whether declaration is surfaced in sessions |
| `createdAt` | Date | yes | Creation timestamp |
| `updatedAt` | Date | yes | Last modification timestamp |

**Level Definitions:**
- **Level 1 (Permission):** "It is okay to..." -- gives permission to be broken, to start, to fail. Used in SOS and post-relapse.
- **Level 2 (Foundation):** "God is..." / "I am beginning to..." -- foundational truths about God's character and the user's worth.
- **Level 3 (Growth):** "I am growing..." / "I choose..." -- active statements of growth and agency.
- **Level 4 (Identity):** "I am..." -- full identity declarations. Only served after sustained recovery (180+ days or manual override).

---

### 2.3 Collection: `affirmationCustomDeclarations`

User-written declarations belonging to custom packs.

```json
{
  "_id": ObjectId("..."),
  "customId": "caff_u12345_001",
  "entityType": "CUSTOM_AFFIRMATION",
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "packId": "cpack_u12345_morning_armor",
  "text": "Lord, strengthen me for today's battles. In Jesus' name.",
  "scriptureReference": "Ephesians 6:10",
  "scriptureText": "Finally, be strong in the Lord and in his mighty power.",
  "includeInRotation": true,
  "createdAt": ISODate("2026-04-01T09:15:00Z"),
  "updatedAt": ISODate("2026-04-01T09:15:00Z")
}
```

**Field Definitions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | auto | MongoDB document ID |
| `customId` | String | yes | Unique ID (`caff_{userId}_{seq}`) |
| `entityType` | String | yes | Always `"CUSTOM_AFFIRMATION"` |
| `userId` | String | yes | Owner user ID |
| `tenantId` | String | yes | Tenant identifier |
| `packId` | String | yes | Parent custom pack reference |
| `text` | String | yes | Declaration text, max 280 chars. Guidance: present tense, positive framing. |
| `scriptureReference` | String | no | Optional Bible verse reference |
| `scriptureText` | String | no | Optional full verse text |
| `includeInRotation` | Boolean | yes | Whether this declaration participates in daily rotation |
| `createdAt` | Date | yes | **Immutable** creation timestamp (FR2.7) |
| `updatedAt` | Date | yes | Last modification timestamp |

**Validation Rules:**
- `text` max length: 280 chars
- Max 50 custom declarations per custom pack
- `createdAt` is immutable after initial write
- Custom content is never analyzed by the system (privacy by architecture)

---

### 2.4 Collection: `affirmationSessions`

Completed session records for all session types.

**Morning session example:**

```json
{
  "_id": ObjectId("..."),
  "sessionId": "asess_u12345_20260407_m",
  "entityType": "AFFIRMATION_SESSION",
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "sessionType": "morning",
  "entryPath": "notification",
  "packId": null,
  "affirmationIds": ["aff_001", "aff_042", "aff_105"],
  "levelServed": 2,
  "intention": "be honest with my wife about my day",
  "usedBreathing": false,
  "usedPrayer": true,
  "dayRating": null,
  "reflection": null,
  "morningIntention": null,
  "breathingCompleted": null,
  "reachedOut": null,
  "prayedWith": null,
  "postCheckInRating": null,
  "postCheckInTimestamp": null,
  "durationSeconds": 185,
  "completedAt": ISODate("2026-04-07T07:05:00Z"),
  "skipped": false,
  "createdAt": ISODate("2026-04-07T07:02:00Z")
}
```

**Evening session example:**

```json
{
  "_id": ObjectId("..."),
  "sessionId": "asess_u12345_20260407_e",
  "entityType": "AFFIRMATION_SESSION",
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "sessionType": "evening",
  "entryPath": "notification",
  "packId": null,
  "affirmationIds": ["aff_210"],
  "levelServed": 2,
  "intention": null,
  "usedBreathing": null,
  "usedPrayer": null,
  "dayRating": 4,
  "reflection": "Today was hard but I stayed honest.",
  "morningIntention": "be honest with my wife about my day",
  "breathingCompleted": null,
  "reachedOut": null,
  "prayedWith": null,
  "postCheckInRating": null,
  "postCheckInTimestamp": null,
  "durationSeconds": 120,
  "completedAt": ISODate("2026-04-07T21:10:00Z"),
  "skipped": false,
  "createdAt": ISODate("2026-04-07T21:08:00Z")
}
```

**SOS session example:**

```json
{
  "_id": ObjectId("..."),
  "sessionId": "asess_u12345_20260407_sos_1",
  "entityType": "AFFIRMATION_SESSION",
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "sessionType": "sos",
  "entryPath": "sos",
  "packId": "pack_sos",
  "affirmationIds": ["aff_sos_001", "aff_sos_002", "aff_sos_003"],
  "levelServed": 1,
  "intention": null,
  "usedBreathing": null,
  "usedPrayer": null,
  "dayRating": null,
  "reflection": null,
  "morningIntention": null,
  "breathingCompleted": true,
  "reachedOut": true,
  "prayedWith": false,
  "postCheckInRating": 3,
  "postCheckInTimestamp": ISODate("2026-04-07T15:25:00Z"),
  "durationSeconds": 210,
  "completedAt": ISODate("2026-04-07T15:15:00Z"),
  "skipped": false,
  "createdAt": ISODate("2026-04-07T15:11:00Z")
}
```

**On-demand pack session example:**

```json
{
  "_id": ObjectId("..."),
  "sessionId": "asess_u12345_20260407_od_1",
  "entityType": "AFFIRMATION_SESSION",
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "sessionType": "on-demand",
  "entryPath": "work",
  "packId": "pack_armor_god",
  "affirmationIds": ["aff_ag_001", "aff_ag_002", "aff_ag_003", "aff_ag_004", "aff_ag_005"],
  "levelServed": 3,
  "intention": null,
  "usedBreathing": true,
  "usedPrayer": true,
  "dayRating": null,
  "reflection": null,
  "morningIntention": null,
  "breathingCompleted": null,
  "reachedOut": null,
  "prayedWith": null,
  "postCheckInRating": null,
  "postCheckInTimestamp": null,
  "durationSeconds": 300,
  "completedAt": ISODate("2026-04-07T12:30:00Z"),
  "skipped": false,
  "createdAt": ISODate("2026-04-07T12:25:00Z")
}
```

**Field Definitions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | auto | MongoDB document ID |
| `sessionId` | String | yes | Unique session ID (`asess_{userId}_{date}_{type}_{seq}`) |
| `entityType` | String | yes | Always `"AFFIRMATION_SESSION"` |
| `userId` | String | yes | Owner user ID |
| `tenantId` | String | yes | Tenant identifier |
| `sessionType` | String (enum) | yes | `morning`, `evening`, `sos`, `on-demand` |
| `entryPath` | String (enum) | yes | `today`, `work`, `sos`, `notification`, `widget`, `post-relapse` |
| `packId` | String | no | Specific pack ID for on-demand and SOS sessions; null for scheduled sessions |
| `affirmationIds` | String[] | yes | Ordered list of declaration IDs served in this session |
| `levelServed` | Integer (1-4) | yes | Primary level of declarations served |
| `intention` | String | no | Morning daily intention text (morning sessions only) |
| `usedBreathing` | Boolean | no | Whether user engaged breathing exercise (morning/on-demand) |
| `usedPrayer` | Boolean | no | Whether user tapped prayer on any declaration (morning/on-demand) |
| `dayRating` | Integer (1-5) | no | Evening mood rating (evening sessions only) |
| `reflection` | String | no | Evening reflection text (evening sessions only) |
| `morningIntention` | String | no | Echoed morning intention (evening sessions only) |
| `breathingCompleted` | Boolean | no | Whether breathing exercise completed (SOS only) |
| `reachedOut` | Boolean | no | Whether user tapped "Reach out" (SOS only) |
| `prayedWith` | Boolean | no | Whether user tapped "Pray with me" (SOS only) |
| `postCheckInRating` | Integer (1-5) | no | Post-SOS check-in rating (SOS only) |
| `postCheckInTimestamp` | Date | no | When post-SOS check-in was answered (SOS only) |
| `durationSeconds` | Integer | yes | Total session duration in seconds |
| `completedAt` | Date | no | Session completion timestamp (null if abandoned) |
| `skipped` | Boolean | yes | Whether user explicitly skipped the session |
| `createdAt` | Date | yes | **Immutable** session start timestamp (FR2.7) |

**Validation Rules:**
- `sessionType` must be one of: `morning`, `evening`, `sos`, `on-demand`
- `entryPath` must be one of: `today`, `work`, `sos`, `notification`, `widget`, `post-relapse`
- `affirmationIds` minimum length: 1
- `dayRating` range: 1-5 inclusive (evening only)
- `postCheckInRating` range: 1-5 inclusive (SOS only)
- `levelServed` for SOS sessions must be <= 2 (NFR-AFF-007)
- `createdAt` is immutable after initial write (FR2.7)
- No streak counters derived from sessions (NFR-AFF-004)

---

### 2.5 Collection: `affirmationFavorites`

```json
{
  "_id": ObjectId("..."),
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "entityType": "AFFIRMATION_FAVORITE",
  "affirmationId": "aff_001",
  "packId": "pack_identity_christ",
  "addedAt": ISODate("2026-04-03T07:10:00Z")
}
```

**Field Definitions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | auto | MongoDB document ID |
| `userId` | String | yes | Owner user ID |
| `tenantId` | String | yes | Tenant identifier |
| `entityType` | String | yes | Always `"AFFIRMATION_FAVORITE"` |
| `affirmationId` | String | yes | Declaration ID (library `aff_*` or custom `caff_*`) |
| `packId` | String | yes | Source pack for grouping |
| `addedAt` | Date | yes | Timestamp when favorited |

**Constraint:** Unique compound on `{ userId, affirmationId }` -- a user can favorite a declaration only once.

---

### 2.6 Collection: `affirmationHidden`

```json
{
  "_id": ObjectId("..."),
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "entityType": "AFFIRMATION_HIDDEN",
  "affirmationId": "aff_042",
  "packId": "pack_identity_christ",
  "hiddenAt": ISODate("2026-04-05T07:08:00Z"),
  "sessionHideCount": 1
}
```

**Field Definitions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | auto | MongoDB document ID |
| `userId` | String | yes | Owner user ID |
| `tenantId` | String | yes | Tenant identifier |
| `entityType` | String | yes | Always `"AFFIRMATION_HIDDEN"` |
| `affirmationId` | String | yes | Hidden declaration ID |
| `packId` | String | yes | Source pack for clinical aggregation |
| `hiddenAt` | Date | yes | Timestamp when hidden |
| `sessionHideCount` | Integer | yes | Running count of hides within the current session context; used for 5+ detection prompt (US-AFF-042) |

**Constraint:** Unique compound on `{ userId, affirmationId }`.

**Clinical note:** Hidden count by `packId` and by core belief category (joined via `affirmationsLibrary`) is a clinical signal. Rolling 30-day hidden count is surfaced to therapist/pastor with user consent.

---

### 2.7 Collection: `affirmationAudioRecordings`

Metadata only -- audio files are stored on-device. Never synced to cloud by default (US-AFF-052).

```json
{
  "_id": ObjectId("..."),
  "recordingId": "arec_u12345_aff001",
  "entityType": "AFFIRMATION_AUDIO",
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "affirmationId": "aff_001",
  "localPath": "/recordings/affirmations/arec_u12345_aff001.m4a",
  "format": "m4a",
  "durationSeconds": 22,
  "backgroundMusic": "worship",
  "backgroundVolume": 0.4,
  "createdAt": ISODate("2026-04-04T07:15:00Z")
}
```

**Field Definitions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | auto | MongoDB document ID |
| `recordingId` | String | yes | Unique recording ID (`arec_{userId}_{affirmationId}`) |
| `entityType` | String | yes | Always `"AFFIRMATION_AUDIO"` |
| `userId` | String | yes | Owner user ID |
| `tenantId` | String | yes | Tenant identifier |
| `affirmationId` | String | yes | Declaration this recording is for |
| `localPath` | String | yes | On-device file path |
| `format` | String | yes | Always `"m4a"` (AAC 64kbps) |
| `durationSeconds` | Integer | yes | Recording length, max 60 seconds |
| `backgroundMusic` | String (enum) | yes | `worship`, `nature`, `hymns`, `atmospheric`, `silence` |
| `backgroundVolume` | Decimal | yes | Background mix level, range 0.0-1.0, default 0.4 |
| `createdAt` | Date | yes | **Immutable** creation timestamp (FR2.7) |

**Privacy:** This collection stores metadata only. Audio files remain on-device unless user explicitly opts into cloud sync. Audio is never shared with partners.

---

### 2.8 Collection: `affirmationSettings`

One document per user. Upserted on first access.

```json
{
  "_id": ObjectId("..."),
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "entityType": "AFFIRMATION_SETTINGS",
  "morningTime": "07:00",
  "eveningTime": "21:00",
  "activePackIds": ["pack_identity_christ", "pack_freedom_shame", "cpack_u12345_morning_armor"],
  "levelOverride": null,
  "healthySexualityEnabled": false,
  "notificationsEnabled": true,
  "reEngagementEnabled": true,
  "preferredBackground": "nature",
  "preferredAudio": "worship",
  "audioAutoPlay": false,
  "updatedAt": ISODate("2026-04-07T08:00:00Z")
}
```

**Field Definitions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | auto | MongoDB document ID |
| `userId` | String | yes | Owner user ID (unique -- one per user) |
| `tenantId` | String | yes | Tenant identifier |
| `entityType` | String | yes | Always `"AFFIRMATION_SETTINGS"` |
| `morningTime` | String | yes | Preferred morning session time, `HH:MM` 24h format. Default: `"07:00"` |
| `eveningTime` | String | yes | Preferred evening session time, `HH:MM` 24h format. Default: `"21:00"` |
| `activePackIds` | String[] | yes | Pack IDs included in daily rotation. Minimum 1. |
| `levelOverride` | Integer (1-4) | no | Manual level override; null = automatic level based on days sober |
| `healthySexualityEnabled` | Boolean | yes | Healthy sexuality content opt-in. Default: `false`. Requires 60+ days sober (NFR-AFF-008). |
| `notificationsEnabled` | Boolean | yes | Morning/evening notification delivery. Default: `true` |
| `reEngagementEnabled` | Boolean | yes | Re-engagement prompts after 3/7/14 day gaps. Default: `true` |
| `preferredBackground` | String | no | Default background: `nature`, `abstract`, `cross`, `solid`, `rotate` |
| `preferredAudio` | String | no | Default audio: `worship`, `nature`, `hymns`, `atmospheric`, `silence` |
| `audioAutoPlay` | Boolean | yes | Whether narrated audio auto-plays. Default: `false` |
| `updatedAt` | Date | yes | Last modification timestamp |

**Constraint:** Unique index on `{ userId }` -- one settings document per user.

---

### 2.9 Collection: `affirmationProgress`

Single denormalized progress document per user, updated on session completion. No streak counters (NFR-AFF-004).

```json
{
  "_id": ObjectId("..."),
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "entityType": "AFFIRMATION_PROGRESS",
  "totalSessions": 127,
  "totalDeclarationsPracticed": 412,
  "totalSOSSessions": 8,
  "totalCustomCreated": 5,
  "totalAudioRecorded": 3,
  "packsExplored": 6,
  "currentLevel": 2,
  "daysAtCurrentLevel": 31,
  "levelHistory": [
    { "level": 1, "startedAt": ISODate("2026-02-20T00:00:00Z"), "endedAt": ISODate("2026-03-06T00:00:00Z"), "trigger": "automatic" },
    { "level": 2, "startedAt": ISODate("2026-03-06T00:00:00Z"), "endedAt": null, "trigger": "automatic" }
  ],
  "milestones": [
    { "type": "sessions", "value": 1, "achievedAt": ISODate("2026-02-20T07:05:00Z") },
    { "type": "sessions", "value": 10, "achievedAt": ISODate("2026-03-01T07:10:00Z") },
    { "type": "sessions", "value": 25, "achievedAt": ISODate("2026-03-10T07:08:00Z") },
    { "type": "sessions", "value": 50, "achievedAt": ISODate("2026-03-25T07:12:00Z") },
    { "type": "sessions", "value": 100, "achievedAt": ISODate("2026-04-05T07:06:00Z") },
    { "type": "firstCustom", "value": 1, "achievedAt": ISODate("2026-04-01T09:15:00Z") },
    { "type": "firstAudio", "value": 1, "achievedAt": ISODate("2026-04-04T07:15:00Z") },
    { "type": "firstSOS", "value": 1, "achievedAt": ISODate("2026-03-15T15:11:00Z") }
  ],
  "lastSessionAt": ISODate("2026-04-07T21:10:00Z"),
  "lastServedAffirmationIds": ["aff_001", "aff_042", "aff_105", "aff_210", "aff_sos_001", "aff_sos_002", "aff_sos_003"],
  "updatedAt": ISODate("2026-04-07T21:10:00Z")
}
```

**Field Definitions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | auto | MongoDB document ID |
| `userId` | String | yes | Owner user ID (unique -- one per user) |
| `tenantId` | String | yes | Tenant identifier |
| `entityType` | String | yes | Always `"AFFIRMATION_PROGRESS"` |
| `totalSessions` | Integer | yes | Cumulative completed session count (all types) |
| `totalDeclarationsPracticed` | Integer | yes | Cumulative declarations viewed across all sessions |
| `totalSOSSessions` | Integer | yes | Cumulative SOS session count |
| `totalCustomCreated` | Integer | yes | Total custom declarations ever written |
| `totalAudioRecorded` | Integer | yes | Total audio recordings ever made |
| `packsExplored` | Integer | yes | Distinct packs from which declarations have been served |
| `currentLevel` | Integer (1-4) | yes | User's current declaration level |
| `daysAtCurrentLevel` | Integer | yes | Days since last level change |
| `levelHistory` | Object[] | yes | Ordered level transitions: `{ level, startedAt, endedAt, trigger }` |
| `levelHistory[].trigger` | String | yes | `automatic`, `manual`, `post-relapse` |
| `milestones` | Object[] | yes | Achieved milestones: `{ type, value, achievedAt }` |
| `milestones[].type` | String | yes | `sessions`, `firstCustom`, `firstAudio`, `firstSOS`, `firstPurchase` |
| `lastSessionAt` | Date | no | Timestamp of most recent session completion |
| `lastServedAffirmationIds` | String[] | yes | Affirmation IDs served in the last 7 days (rolling window for no-repeat logic) |
| `updatedAt` | Date | yes | Last modification timestamp |

**Constraint:** Unique index on `{ userId }`. Milestone thresholds for `sessions` type: 1, 10, 25, 50, 100, 250.

---

### 2.10 Collection: `affirmationPurchases`

Premium pack ownership records. Used for purchase validation and restore-purchases flow.

```json
{
  "_id": ObjectId("..."),
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "entityType": "AFFIRMATION_PURCHASE",
  "packId": "pack_marriage_restoration",
  "purchasedAt": ISODate("2026-03-20T14:00:00Z"),
  "platform": "ios",
  "receiptId": "txn_apple_abc123def456",
  "price": 4.99,
  "bundleId": null
}
```

**Field Definitions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | auto | MongoDB document ID |
| `userId` | String | yes | Purchaser user ID |
| `tenantId` | String | yes | Tenant identifier |
| `entityType` | String | yes | Always `"AFFIRMATION_PURCHASE"` |
| `packId` | String | yes | Purchased pack ID |
| `purchasedAt` | Date | yes | Purchase timestamp |
| `platform` | String (enum) | yes | `ios`, `android` |
| `receiptId` | String | yes | Platform-specific receipt/transaction ID for server-side validation |
| `price` | Decimal | yes | Purchase price in USD at time of purchase |
| `bundleId` | String | no | Bundle ID if purchased as part of a bundle; null for individual purchases |

**Constraint:** Unique compound on `{ userId, packId }` -- a user can purchase a pack only once.

---

## 3. Indexes

### 3.1 `affirmationPacks`

| Index Name | Fields | Type | Purpose |
|------------|--------|------|---------|
| `packId_1` | `{ packId: 1 }` | Unique | Lookup pack by ID |
| `type_active_sortOrder` | `{ type: 1, active: 1, sortOrder: 1 }` | Compound | Browse packs by type (default/premium/custom) |
| `userId_type` | `{ userId: 1, type: 1 }` | Compound, sparse | User's custom packs (null userId for system packs) |
| `category_active` | `{ category: 1, active: 1 }` | Compound | Browse packs by category |
| `tenantId_1` | `{ tenantId: 1 }` | Single | Tenant admin queries |

### 3.2 `affirmationsLibrary`

| Index Name | Fields | Type | Purpose |
|------------|--------|------|---------|
| `affirmationId_1` | `{ affirmationId: 1 }` | Unique | Direct lookup by declaration ID |
| `packId_level_active` | `{ packId: 1, level: 1, active: 1 }` | Compound | Get declarations in a pack filtered by level |
| `packId_active` | `{ packId: 1, active: 1 }` | Compound | Get all active declarations in a pack |
| `level_category_active` | `{ level: 1, category: 1, active: 1 }` | Compound | Level + category filtering for session content selection |
| `coreBeliefs_level` | `{ coreBeliefs: 1, level: 1 }` | Compound (multikey) | Clinical: filter by core belief addressed |
| `tags_1` | `{ tags: 1 }` | Multikey | Tag-based filtering |
| `text_search` | `{ text: "text", scriptureReference: "text", tags: "text" }` | Text | Full-text search across declarations |

### 3.3 `affirmationCustomDeclarations`

| Index Name | Fields | Type | Purpose |
|------------|--------|------|---------|
| `customId_1` | `{ customId: 1 }` | Unique | Direct lookup |
| `userId_packId` | `{ userId: 1, packId: 1 }` | Compound | List custom declarations in a pack |
| `userId_includeInRotation` | `{ userId: 1, includeInRotation: 1 }` | Compound | Get all user's declarations in rotation |
| `tenantId_1` | `{ tenantId: 1 }` | Single | Tenant admin queries |

### 3.4 `affirmationSessions`

| Index Name | Fields | Type | Purpose |
|------------|--------|------|---------|
| `sessionId_1` | `{ sessionId: 1 }` | Unique | Direct lookup |
| `userId_createdAt` | `{ userId: 1, createdAt: -1 }` | Compound | List sessions reverse chronological |
| `userId_sessionType_createdAt` | `{ userId: 1, sessionType: 1, createdAt: -1 }` | Compound | Filter sessions by type + date |
| `userId_completedAt` | `{ userId: 1, completedAt: -1 }` | Compound, sparse | Completed sessions only (null completedAt excluded) |
| `userId_sessionType_dayRating` | `{ userId: 1, sessionType: 1, dayRating: 1, createdAt: -1 }` | Compound, sparse | Evening mood ratings for trend analysis |
| `userId_entryPath_createdAt` | `{ userId: 1, entryPath: 1, createdAt: -1 }` | Compound | Session analysis by entry path |
| `tenantId_1` | `{ tenantId: 1 }` | Single | Tenant admin queries |

### 3.5 `affirmationFavorites`

| Index Name | Fields | Type | Purpose |
|------------|--------|------|---------|
| `userId_affirmationId` | `{ userId: 1, affirmationId: 1 }` | Unique compound | Check if favorited; prevent duplicates |
| `userId_packId` | `{ userId: 1, packId: 1 }` | Compound | List favorites grouped by pack |
| `userId_addedAt` | `{ userId: 1, addedAt: -1 }` | Compound | List all favorites reverse chronological |
| `tenantId_1` | `{ tenantId: 1 }` | Single | Tenant admin queries |

### 3.6 `affirmationHidden`

| Index Name | Fields | Type | Purpose |
|------------|--------|------|---------|
| `userId_affirmationId` | `{ userId: 1, affirmationId: 1 }` | Unique compound | Check if hidden; prevent duplicates |
| `userId_hiddenAt` | `{ userId: 1, hiddenAt: -1 }` | Compound | List hidden reverse chronological; rolling 30-day count |
| `userId_packId` | `{ userId: 1, packId: 1 }` | Compound | Hidden count per pack (clinical signal) |
| `tenantId_1` | `{ tenantId: 1 }` | Single | Tenant admin queries |

### 3.7 `affirmationAudioRecordings`

| Index Name | Fields | Type | Purpose |
|------------|--------|------|---------|
| `recordingId_1` | `{ recordingId: 1 }` | Unique | Direct lookup |
| `userId_affirmationId` | `{ userId: 1, affirmationId: 1 }` | Compound | Get recording for a specific declaration |
| `userId_createdAt` | `{ userId: 1, createdAt: -1 }` | Compound | List recordings reverse chronological |
| `tenantId_1` | `{ tenantId: 1 }` | Single | Tenant admin queries |

### 3.8 `affirmationSettings`

| Index Name | Fields | Type | Purpose |
|------------|--------|------|---------|
| `userId_1` | `{ userId: 1 }` | Unique | One settings doc per user |
| `tenantId_1` | `{ tenantId: 1 }` | Single | Tenant admin queries |

### 3.9 `affirmationProgress`

| Index Name | Fields | Type | Purpose |
|------------|--------|------|---------|
| `userId_1` | `{ userId: 1 }` | Unique | One progress doc per user |
| `tenantId_1` | `{ tenantId: 1 }` | Single | Tenant admin queries |

### 3.10 `affirmationPurchases`

| Index Name | Fields | Type | Purpose |
|------------|--------|------|---------|
| `userId_packId` | `{ userId: 1, packId: 1 }` | Unique compound | Check if user owns a pack |
| `userId_purchasedAt` | `{ userId: 1, purchasedAt: -1 }` | Compound | Purchase history reverse chronological |
| `receiptId_1` | `{ receiptId: 1 }` | Unique | Receipt validation / duplicate detection |
| `tenantId_1` | `{ tenantId: 1 }` | Single | Tenant admin queries |

### Index Count Summary

| Collection | Index Count |
|-----------|-------------|
| `affirmationPacks` | 5 |
| `affirmationsLibrary` | 7 |
| `affirmationCustomDeclarations` | 4 |
| `affirmationSessions` | 7 |
| `affirmationFavorites` | 4 |
| `affirmationHidden` | 4 |
| `affirmationAudioRecordings` | 4 |
| `affirmationSettings` | 2 |
| `affirmationProgress` | 2 |
| `affirmationPurchases` | 4 |
| **Total** | **43** |

---

## 4. Calendar Activity Dual-Write

Every completed affirmation session writes a denormalized entry to the `calendarActivities` collection (NFR-AFF-003).

### Morning Session

```json
{
  "_id": ObjectId("..."),
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "entityType": "CALENDAR_ACTIVITY",
  "activityType": "DECLARATIONS",
  "date": "2026-04-07",
  "timestamp": ISODate("2026-04-07T07:05:00Z"),
  "summary": {
    "sessionType": "morning",
    "declarationCount": 3,
    "levelServed": 2,
    "durationSeconds": 185,
    "usedBreathing": false,
    "usedPrayer": true,
    "hasIntention": true
  },
  "sourceId": "asess_u12345_20260407_m"
}
```

### Evening Session

```json
{
  "_id": ObjectId("..."),
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "entityType": "CALENDAR_ACTIVITY",
  "activityType": "DECLARATIONS",
  "date": "2026-04-07",
  "timestamp": ISODate("2026-04-07T21:10:00Z"),
  "summary": {
    "sessionType": "evening",
    "declarationCount": 1,
    "levelServed": 2,
    "durationSeconds": 120,
    "dayRating": 4,
    "hasReflection": true
  },
  "sourceId": "asess_u12345_20260407_e"
}
```

### SOS Session

```json
{
  "_id": ObjectId("..."),
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "entityType": "CALENDAR_ACTIVITY",
  "activityType": "DECLARATIONS",
  "date": "2026-04-07",
  "timestamp": ISODate("2026-04-07T15:15:00Z"),
  "summary": {
    "sessionType": "sos",
    "declarationCount": 3,
    "levelServed": 1,
    "durationSeconds": 210,
    "breathingCompleted": true,
    "reachedOut": true
  },
  "sourceId": "asess_u12345_20260407_sos_1"
}
```

### On-Demand Pack Session

```json
{
  "_id": ObjectId("..."),
  "userId": "u_12345",
  "tenantId": "DEFAULT",
  "entityType": "CALENDAR_ACTIVITY",
  "activityType": "DECLARATIONS",
  "date": "2026-04-07",
  "timestamp": ISODate("2026-04-07T12:30:00Z"),
  "summary": {
    "sessionType": "on-demand",
    "packId": "pack_armor_god",
    "declarationCount": 5,
    "levelServed": 3,
    "durationSeconds": 300
  },
  "sourceId": "asess_u12345_20260407_od_1"
}
```

**Note:** Calendar `activityType` is `"DECLARATIONS"` (not "affirmations") to match the user-facing feature name "Declarations of Truth."

---

## 5. Access Patterns

### 5.1 Pack Management

| # | Access Pattern | Collection | Query | Index | Notes |
|---|---------------|------------|-------|-------|-------|
| AP-AFF-01 | List all packs by type | `affirmationPacks` | `{ type: "default", active: true }` sort `{ sortOrder: 1 }` | `type_active_sortOrder` | Pack library browse |
| AP-AFF-02 | Get pack by packId | `affirmationPacks` | `{ packId: "pack_identity_christ" }` | `packId_1` | Pack detail view |
| AP-AFF-03 | Get user's custom packs | `affirmationPacks` | `{ userId: "u_12345", type: "custom" }` | `userId_type` | My Packs view |
| AP-AFF-04 | Browse packs by category | `affirmationPacks` | `{ category: "identity", active: true }` | `category_active` | Category filter |

### 5.2 Library Content

| # | Access Pattern | Collection | Query | Index | Notes |
|---|---------------|------------|-------|-------|-------|
| AP-AFF-05 | Get declarations in a pack by level | `affirmationsLibrary` | `{ packId: "pack_identity_christ", level: 2, active: true }` | `packId_level_active` | Session content selection |
| AP-AFF-06 | Get all active declarations in a pack | `affirmationsLibrary` | `{ packId: "pack_identity_christ", active: true }` | `packId_active` | Pack detail/preview |
| AP-AFF-07 | Search declarations by keyword | `affirmationsLibrary` | `{ $text: { $search: "identity" } }` | `text_search` | Library search |
| AP-AFF-08 | Filter by level + category | `affirmationsLibrary` | `{ level: { $lte: 2 }, category: "sos", active: true }` | `level_category_active` | SOS content selection |
| AP-AFF-09 | Filter by core belief | `affirmationsLibrary` | `{ coreBeliefs: 1, level: { $lte: 2 } }` | `coreBeliefs_level` | Clinical analysis |

### 5.3 Custom Declarations

| # | Access Pattern | Collection | Query | Index | Notes |
|---|---------------|------------|-------|-------|-------|
| AP-AFF-10 | Get declarations in custom pack | `affirmationCustomDeclarations` | `{ userId: "u_12345", packId: "cpack_u12345_morning_armor" }` | `userId_packId` | Custom pack detail |
| AP-AFF-11 | Get user's rotation declarations | `affirmationCustomDeclarations` | `{ userId: "u_12345", includeInRotation: true }` | `userId_includeInRotation` | Daily rotation pool |

### 5.4 Purchase Validation

| # | Access Pattern | Collection | Query | Index | Notes |
|---|---------------|------------|-------|-------|-------|
| AP-AFF-12 | Check if user owns premium pack | `affirmationPurchases` | `{ userId: "u_12345", packId: "pack_marriage_restoration" }` | `userId_packId` | Access control |
| AP-AFF-13 | Get purchase history | `affirmationPurchases` | `{ userId: "u_12345" }` sort `{ purchasedAt: -1 }` | `userId_purchasedAt` | Restore purchases / history view |
| AP-AFF-14 | Validate receipt | `affirmationPurchases` | `{ receiptId: "txn_apple_abc123def456" }` | `receiptId_1` | Duplicate purchase prevention |

### 5.5 Favorites & Hidden

| # | Access Pattern | Collection | Query | Index | Notes |
|---|---------------|------------|-------|-------|-------|
| AP-AFF-15 | Get user favorites | `affirmationFavorites` | `{ userId: "u_12345" }` sort `{ addedAt: -1 }` | `userId_addedAt` | Favorites view |
| AP-AFF-16 | Get favorites grouped by pack | `affirmationFavorites` | `{ userId: "u_12345" }` group by `packId` | `userId_packId` | Favorites collection view |
| AP-AFF-17 | Check if declaration is favorited | `affirmationFavorites` | `{ userId: "u_12345", affirmationId: "aff_001" }` | `userId_affirmationId` | Heart icon state |
| AP-AFF-18 | Get user hidden list | `affirmationHidden` | `{ userId: "u_12345" }` sort `{ hiddenAt: -1 }` | `userId_hiddenAt` | Settings hidden list |
| AP-AFF-19 | Check if declaration is hidden | `affirmationHidden` | `{ userId: "u_12345", affirmationId: "aff_042" }` | `userId_affirmationId` | Session content exclusion |
| AP-AFF-20 | Hidden count in rolling 30 days | `affirmationHidden` | `{ userId: "u_12345", hiddenAt: { $gte: 30daysAgo } }` count | `userId_hiddenAt` | Clinical signal for therapist view |
| AP-AFF-21 | Hidden count by pack (clinical) | `affirmationHidden` | `{ userId: "u_12345" }` group by `packId` | `userId_packId` | Pattern analysis per theme |

### 5.6 Session Content Selection

| # | Access Pattern | Collection(s) | Description | Notes |
|---|---------------|--------------|-------------|-------|
| AP-AFF-22 | Morning session content | `affirmationsLibrary`, `affirmationFavorites`, `affirmationHidden`, `affirmationProgress`, `affirmationSettings` | 1. Get active pack IDs from settings. 2. Get declarations at user's level from active packs (80%) + one level up (20%). 3. Exclude hidden (AP-AFF-19). 4. Prioritize favorites. 5. Exclude `lastServedAffirmationIds` from progress (7-day no-repeat). 6. Select 3-5 declarations with pack rotation. | Multi-collection read; cached result |
| AP-AFF-23 | Evening session content | `affirmationsLibrary`, `affirmationHidden`, `affirmationSettings` | 1 declaration at Level 1-2 from active packs. Exclude hidden. Calming category preferred. | Simpler selection than morning |
| AP-AFF-24 | SOS content | `affirmationsLibrary`, `affirmationHidden` | 3 declarations from SOS pack. Level 1-2 only (NFR-AFF-007). Locally cached. | Must work offline (NFR-AFF-011) |
| AP-AFF-25 | On-demand pack session | `affirmationsLibrary`, `affirmationHidden`, `affirmationProgress` | Declarations from specified pack at user's level. Exclude hidden. 3-5 declarations. | Pack-scoped selection |
| AP-AFF-26 | Post-relapse content | `affirmationsLibrary` | Level 1 only for 24h after sobriety reset. Auto-append Lamentations 3:22-23. | Level locked (NFR-AFF-006) |

### 5.7 Session History & Progress

| # | Access Pattern | Collection | Query | Index | Notes |
|---|---------------|------------|-------|-------|-------|
| AP-AFF-27 | Session history by type and date range | `affirmationSessions` | `{ userId: "u_12345", sessionType: "morning", createdAt: { $gte: start, $lte: end } }` sort `{ createdAt: -1 }` | `userId_sessionType_createdAt` | History view with filters |
| AP-AFF-28 | Progress metrics | `affirmationProgress` | `{ userId: "u_12345" }` | `userId_1` | Progress dashboard |
| AP-AFF-29 | Level info and history | `affirmationProgress` | `{ userId: "u_12345" }` project `currentLevel`, `daysAtCurrentLevel`, `levelHistory` | `userId_1` | Level display + history |
| AP-AFF-30 | Settings | `affirmationSettings` | `{ userId: "u_12345" }` | `userId_1` | Settings view |

### 5.8 Analytics & Clinical

| # | Access Pattern | Collection | Query | Index | Notes |
|---|---------------|------------|-------|-------|-------|
| AP-AFF-31 | 30-day consistency | `affirmationSessions` | Aggregate: `$match { userId, createdAt: { $gte: 30daysAgo } }`, `$group { _id: { $dateToString: { format: "%Y-%m-%d", date: "$createdAt" } }, sessionCount: { $sum: 1 } }` | `userId_createdAt` | Heat map data |
| AP-AFF-32 | Post-relapse window check | External (sobriety counter API) | Check if `lastSobrietyResetAt + 24h > now` | N/A | Determines Level 1 lock |
| AP-AFF-33 | Last 7 days served (no-repeat) | `affirmationProgress` | `{ userId: "u_12345" }` project `lastServedAffirmationIds` | `userId_1` | Content selection exclusion |
| AP-AFF-34 | Audio recording metadata | `affirmationAudioRecordings` | `{ userId: "u_12345", affirmationId: "aff_001" }` | `userId_affirmationId` | Audio playback screen |
| AP-AFF-35 | Milestones | `affirmationProgress` | `{ userId: "u_12345" }` project `milestones` | `userId_1` | Milestone celebrations |
| AP-AFF-36 | Consecutive declining mood (3+) | `affirmationSessions` | Aggregate: `$match { userId, sessionType: "evening", dayRating: { $exists: true }, createdAt: { $gte: 7daysAgo } }` sort `{ createdAt: -1 }` limit 3, check if all ratings declining | `userId_sessionType_dayRating` | Clinical escalation trigger |
| AP-AFF-37 | Evening mood ratings (trend) | `affirmationSessions` | `{ userId: "u_12345", sessionType: "evening", dayRating: { $ne: null } }` sort `{ createdAt: -1 }` limit 30 | `userId_sessionType_dayRating` | Mood trend chart |
| AP-AFF-38 | Sharing summary (session count) | `affirmationSessions` | Aggregate: `$match { userId, createdAt: { $gte: weekStart } }` count | `userId_createdAt` | Partner view: "Sessions this week: N" |
| AP-AFF-39 | Calendar dual-write | `calendarActivities` | `{ userId, date, activityType: "DECLARATIONS" }` | Existing calendar indexes | Calendar view integration |
| AP-AFF-40 | Hide count in current session | `affirmationHidden` | `{ userId: "u_12345", hiddenAt: { $gte: sessionStartTime } }` count | `userId_hiddenAt` | 5+ hide detection for gentle prompt (US-AFF-042) |

---

## 6. Document Size Estimates

### Per-Document Sizes

| Collection | Avg Doc Size | Notes |
|-----------|-------------|-------|
| `affirmationPacks` | 500 B | System packs; custom packs slightly smaller |
| `affirmationsLibrary` | 800 B | Full declaration with scripture, expansion, prayer |
| `affirmationCustomDeclarations` | 400 B | User-written, shorter content |
| `affirmationSessions` | 600 B (morning/on-demand), 500 B (evening), 550 B (SOS) | Varies by session type fields |
| `affirmationFavorites` | 150 B | Minimal reference document |
| `affirmationHidden` | 150 B | Minimal reference document |
| `affirmationAudioRecordings` | 250 B | Metadata only; audio file on device |
| `affirmationSettings` | 400 B | Single doc per user |
| `affirmationProgress` | 2 KB (growing) | Level history and milestones arrays grow over time |
| `affirmationPurchases` | 200 B | One per premium pack owned |

### Per-User Annual Estimate

Assumptions: 1 morning + 1 evening session/day, 2 SOS sessions/month, 1 on-demand/week, 20 favorites, 10 hidden, 5 custom declarations, 3 audio recordings, 2 premium purchases.

| Category | Items/Year | Avg Size | Storage |
|----------|-----------|----------|---------|
| Sessions (morning) | 365 | 600 B | 214 KB |
| Sessions (evening) | 365 | 500 B | 178 KB |
| Sessions (SOS) | 24 | 550 B | 13 KB |
| Sessions (on-demand) | 52 | 600 B | 30 KB |
| Calendar dual-write mirrors | 806 | 300 B | 236 KB |
| Favorites | 20 | 150 B | 3 KB |
| Hidden | 10 | 150 B | 1.5 KB |
| Custom declarations | 5 | 400 B | 2 KB |
| Audio recording metadata | 3 | 250 B | 0.75 KB |
| Settings | 1 | 400 B | 0.4 KB |
| Progress | 1 | 2 KB | 2 KB |
| Purchases | 2 | 200 B | 0.4 KB |
| **Total per user/year** | **~1,654** | | **~681 KB** |

### System Content (Shared)

| Content | Documents | Avg Size | Total |
|---------|----------|----------|-------|
| Default packs | ~10 | 500 B | 5 KB |
| Premium packs | ~15 | 500 B | 7.5 KB |
| Library declarations | ~500 | 800 B | 400 KB |
| **Total system content** | **~525** | | **~413 KB** |

All documents are well within MongoDB's 16 MB limit. The `affirmationProgress` document is the largest per-user document; at 250 sessions/year the milestones array grows by ~5-6 entries/year and levelHistory by ~2-3 entries/year, keeping total size under 5 KB for multi-year users.

---

## 7. Caching Strategy (Valkey)

| Cache Key | TTL | Invalidation Trigger | Purpose |
|-----------|-----|---------------------|---------|
| `affirmations:packs:catalog` | 1 hour | On pack create/update/deactivate (admin) | Pack library browse (system packs rarely change) |
| `affirmations:packs:custom:{userId}` | 10 min | On custom pack create/update/delete | User's custom pack list |
| `affirmations:library:{packId}:level:{level}` | 1 hour | On declaration update (admin) | Declarations in pack at level (content selection pool) |
| `affirmations:sos:content` | 24 hours | On SOS pack content update (admin) | SOS declarations (must also be cached on-device for offline) |
| `affirmations:settings:{userId}` | 5 min | On settings update | User preferences and active pack IDs |
| `affirmations:progress:{userId}` | 5 min | On session complete, custom create, audio record, purchase | Progress dashboard metrics |
| `affirmations:favorites:{userId}` | 5 min | On favorite add/remove | Favorite affirmation ID set for session content selection |
| `affirmations:hidden:{userId}` | 5 min | On hide/unhide | Hidden affirmation ID set for session content exclusion |
| `affirmations:served:{userId}` | 24 hours | On session complete | `lastServedAffirmationIds` for 7-day no-repeat |
| `affirmations:session:morning:{userId}:{date}` | Until next morning time | On session complete | Pre-computed morning session content (avoids multi-collection read at session time) |
| `affirmations:session:evening:{userId}:{date}` | Until next evening time | On session complete | Pre-computed evening session content |
| `affirmations:ownership:{userId}` | 10 min | On purchase | Set of owned premium pack IDs for access control |
| `affirmations:mood:trend:{userId}` | 10 min | On evening session complete | Last 30 evening mood ratings for trend chart |
| `affirmations:consistency:{userId}:{month}` | 10 min | On session complete | 30-day consistency heat map data |

**Cache warming:** Morning and evening session content is pre-computed and cached during the quiet period (2-4 AM user-local) for high-engagement users. SOS content is always cached on-device for offline use.

**Cache invalidation pattern:** Application-layer invalidation on write operations. No MongoDB Change Streams dependency for cache (simplicity over real-time consistency; 5-min staleness is acceptable for all cached data).

---

## 8. Migration Notes

### From v1 Schema (Sections 4.34-4.37)

The v1 schema in `schema-design.md` defines four simple entities:
- **4.34 Affirmation Pack** (`PACK#<packId>` / `META`): flat pack metadata
- **4.35 Affirmation** (`PACK#<packId>` / `AFFIRMATION#<affirmationId>`): single statement + scripture
- **4.36 Custom Affirmation** (`USER#<userId>` / `AFFIRMATION#CUSTOM#<affirmationId>`): user-written
- **4.37 User-Owned Pack** (`USER#<userId>` / `PACK#<packId>`): purchase record

### Migration Strategy

1. **Additive migration:** New collections are created alongside the v1 entities. No destructive changes to existing documents.
2. **Content migration:** Existing affirmation content from `AFFIRMATION#<id>` documents is migrated into `affirmationsLibrary` with new fields (`expansion`, `prayer`, `level`, `coreBeliefs`, `tags`) populated by content team.
3. **Pack migration:** Existing `AFFIRMATION_PACK` documents are migrated to `affirmationPacks` with new fields (`type`, `primaryLevel`, `previewAffirmationIds`, `coverImage`) added.
4. **Purchase migration:** `USER_PACK` documents map to `affirmationPurchases` with `platform` and `receiptId` backfilled from App Store/Play Store records.
5. **Custom declaration migration:** `CUSTOM_AFFIRMATION` documents map to `affirmationCustomDeclarations` with `packId` set to an auto-created "My Declarations" custom pack per user.
6. **Dual-read period:** Application reads from both v1 and v2 collections during transition. Feature flag `activity.affirmations.v2` gates the v2 experience; v1 remains available as fallback.
7. **Cutover:** After v2 is stable and all users migrated, v1 entities are archived and removed.

### New Entities (No Migration Required)

- `affirmationSessions` -- new collection; no v1 equivalent (v1 had no session tracking)
- `affirmationFavorites` -- new collection
- `affirmationHidden` -- new collection
- `affirmationAudioRecordings` -- new collection
- `affirmationSettings` -- new collection
- `affirmationProgress` -- new collection

The parent `schema-design.md` should be updated to reference this document for the canonical Affirmations v2 schema, noting that Sections 4.34-4.37 are superseded.

---

## 9. Offline Sync Considerations

| Data | Offline Support | Sync Strategy |
|------|----------------|---------------|
| System packs + declarations | Read-only cache (30+ declarations for active packs, full SOS pack) | Pull on connectivity; background refresh daily |
| Custom packs + declarations | Full CRUD | Offline-first; queue changes; sync on reconnect with LWW for edits |
| Sessions | Full create | Offline-first; queue completed sessions; sync on reconnect with union merge |
| Favorites | Full add/remove | Offline-first; sync with union merge (both sides kept) |
| Hidden | Full add/remove | Offline-first; sync with union merge |
| Audio recordings | Full create/play | On-device only by default; metadata syncs on reconnect if cloud sync enabled |
| Settings | Read cached; write queued | LWW on reconnect |
| Progress | Read cached; computed locally | Server recomputes on session sync; server-authoritative |
| Purchases | Requires internet | StoreKit 2 / Play Billing handle offline receipt queuing natively |

**Conflict resolution:**
- **Union merge** for sessions, favorites, hidden (keep all records from both sides)
- **LWW (last-writer-wins)** for settings, custom declaration edits
- **Server-authoritative** for progress (recomputed from session data)
- **Immutable** `createdAt` timestamps never modified during sync (FR2.7)

---

## 10. Security and Privacy

- **Tenant isolation:** All queries include `tenantId` filter at the application layer
- **User scoping:** All user-scoped queries are scoped by `userId` -- no cross-user access
- **Audio privacy:** Audio recordings metadata syncs; audio files remain on-device unless explicit cloud opt-in. Audio is never shared with partners (US-AFF-052).
- **Custom content privacy:** Custom declarations are never analyzed by the system. Never surfaced to partners, therapists, or analytics (privacy by architecture).
- **Partner visibility:** Session count only (AP-AFF-38). No declaration text, no custom content, no hidden list, no audio (US-AFF-070).
- **Therapist/pastor visibility (with consent):** Practice consistency, mood trend, hidden count, level progression (US-AFF-071). Granular opt-in per relationship. Revocable.
- **Audit trail:** Data access by support network contacts logged per the existing audit entity pattern.
- **Deletion (GDPR/CCPA):** Full export + deletion of all 10 collections' user-scoped data within 30 days on request. System content (`affirmationPacks`, `affirmationsLibrary`) is not user data and is excluded from deletion requests.
