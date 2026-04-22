# Regal Recovery Content — MongoDB Schema Design

**Database:** `regal-recovery-content`
**Version:** 1.0.0
**Date:** 2026-04-03
**Status:** Draft

---

## Table of Contents

1. [Overview](#1-overview)
2. [Database Schema](#2-database-schema)
3. [Collection Catalog](#3-collection-catalog)
4. [Index Reference](#4-index-reference)
5. [Caching Strategy](#5-caching-strategy)
6. [Localization](#6-localization)
7. [Migration Plan](#7-migration-plan)

---

## 1. Overview

`regal-recovery-content` is a dedicated MongoDB database for all static editorial content in the Regal Recovery app. It is separate from `regal-recovery` (which holds user recovery data) because content has fundamentally different access patterns:

- **Read-heavy, rarely written** — content changes on editorial cycles, not user actions
- **No user-scoping** — all documents are system-level (no `userId`)
- **Aggressively cacheable** — 24-hour Valkey TTL on all collections
- **Tenant-overridable** — every document carries `tenantId` (default `SYSTEM`) for future B2B tenant content overrides

### Collection Summary

| # | Collection | Category | Document Count | Tier Model |
|---|-----------|----------|---------------|-----------|
| 1 | `feature_abouts` | Reference | 31 | — |
| 2 | `affirmation_packs` | Pack | ~few | standard/premium |
| 3 | `affirmations` | Pack Item | 100+ | — |
| 4 | `devotional_packs` | Pack | ~few | standard/premium |
| 5 | `devotionals` | Pack Item | 365+ | — |
| 6 | `journal_prompts` | Reference | 150 | — |
| 7 | `glossary_terms` | Reference | 20+ | — |
| 8 | `acting_in_behaviors` | Reference | 15 | — |
| 9 | `needs` | Reference | 20 | — |
| 10 | `sobriety_reset_messages` | Reference | 50 | — |
| 11 | `evening_review_questions` | Reference | 40+ | — |
| 12 | `themes` | App Asset | ~10+ | standard/premium |

### Common Fields

All documents in all collections carry these fields:

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectId | MongoDB document ID |
| `tenantId` | string | Tenant identifier. Default: `SYSTEM` |
| `status` | string | `draft`, `published`, or `archived` |
| `createdAt` | datetime | ISO 8601 creation timestamp |
| `modifiedAt` | datetime | ISO 8601 last-modified timestamp |

---

## 2. Database Schema

### Connection

| Property | Value |
|----------|-------|
| **Database name** | `regal-recovery-content` |
| **Connection** | Same MongoDB Atlas cluster as `regal-recovery` |
| **Read preference** | `secondaryPreferred` (content reads can tolerate eventual consistency) |
| **Write concern** | `majority` |

---

## 3. Collection Catalog

### 3.1 Feature Abouts

**Description:** One document per app feature explaining what it is and how to use it. Displayed as "About this feature" content within the app.

**31 features across 5 categories:**

| Category | Slugs |
|----------|-------|
| `activity` | sobriety-commitment, urge-logging, journaling, prayer, meetings, exercise, nutrition, gratitude-list, acting-in, time-journal, emotional-journal, memory-verse, book-reading, rl-backbone, post-mortem, faster-scale, pci, evening-review, mood-tracking |
| `tool` | 3circles, arousal-template, relapse-prevention, vision-statement, triggers |
| `assessment` | sast-r, denial |
| `communication` | fanos, fitnap |
| `content` | affirmations, devotionals, step-work |

**Schema:**

| Field | Type | Description |
|-------|------|-------------|
| `slug` | string | Unique URL-safe identifier (e.g., `faster-scale`) |
| `title` | string | Display title (e.g., "Understanding the FASTER Scale") |
| `summary` | string | One-sentence description for cards/lists |
| `contentHtml` | string | Full HTML body content |
| `category` | string | `activity`, `tool`, `assessment`, `communication`, or `content` |
| `relatedFeatureFlag` | string | Corresponding feature flag key (e.g., `activity.faster-scale`) |
| `iconName` | string | Icon identifier for the app |
| `sortOrder` | int | Display order within category |

**Example Document:**

```json
{
  "_id": ObjectId("..."),
  "tenantId": "SYSTEM",
  "status": "published",
  "createdAt": ISODate("2026-01-01T00:00:00Z"),
  "modifiedAt": ISODate("2026-04-03T00:00:00Z"),
  "slug": "faster-scale",
  "title": "Understanding the FASTER Scale",
  "summary": "The FASTER Scale helps identify where you are in the relapse cycle — from Restoration through Exhaustion and beyond.",
  "contentHtml": "<h2>What is the FASTER Scale?</h2><p>Developed by Michael Dye, the FASTER Scale is a relapse-awareness tool used in Celebrate Recovery and other Christian recovery programs...</p>",
  "category": "activity",
  "relatedFeatureFlag": "activity.faster-scale",
  "iconName": "speedometer",
  "sortOrder": 1
}
```

---

### 3.2 Affirmation Packs

**Description:** Metadata for a bundled group of affirmations. Can be standard (free) or premium (purchasable).

**Schema:**

| Field | Type | Description |
|-------|------|-------------|
| `packId` | string | Unique pack identifier (e.g., `pack_christian`) |
| `name` | string | Display name |
| `description` | string | Pack description |
| `tier` | string | `standard` or `premium` |
| `price` | int | Price in cents (0 for standard). e.g., 499 = $4.99 |
| `currency` | string | ISO 4217 currency code (e.g., `USD`) |
| `affirmationCount` | int | Number of affirmations in the pack |
| `category` | string | Pack category (e.g., `christian`, `recovery`, `identity`) |
| `thumbnailUrl` | string | Pack thumbnail image URL |
| `sortOrder` | int | Display order |

**Example Document:**

```json
{
  "_id": ObjectId("..."),
  "tenantId": "SYSTEM",
  "status": "published",
  "createdAt": ISODate("2026-01-01T00:00:00Z"),
  "modifiedAt": ISODate("2026-01-01T00:00:00Z"),
  "packId": "pack_christian",
  "name": "Affirmations",
  "description": "44 biblical affirmations for daily recovery",
  "tier": "standard",
  "price": 0,
  "currency": "USD",
  "affirmationCount": 44,
  "category": "christian",
  "thumbnailUrl": "",
  "sortOrder": 1
}
```

---

### 3.3 Affirmations

**Description:** Individual affirmation statements belonging to an affirmation pack.

**Schema:**

| Field | Type | Description |
|-------|------|-------------|
| `affirmationId` | string | Unique affirmation identifier |
| `packId` | string | Parent pack identifier |
| `statement` | string | Affirmation text |
| `scriptureReference` | string | Bible verse reference (optional) |
| `category` | string | Affirmation category (e.g., `identity`, `strength`, `hope`) |
| `language` | string | ISO 639-1 language code (e.g., `en`) |
| `sortOrder` | int | Display order within pack |

**Example Document:**

```json
{
  "_id": ObjectId("..."),
  "tenantId": "SYSTEM",
  "status": "published",
  "createdAt": ISODate("2026-01-01T00:00:00Z"),
  "modifiedAt": ISODate("2026-01-01T00:00:00Z"),
  "affirmationId": "aff_001",
  "packId": "pack_christian",
  "statement": "I am fearfully and wonderfully made.",
  "scriptureReference": "Psalm 139:14",
  "category": "identity",
  "language": "en",
  "sortOrder": 1
}
```

---

### 3.4 Devotional Packs

**Description:** Metadata for a bundled group of devotionals. Devotionals are day-numbered within their pack. Can be standard or premium.

**Schema:**

| Field | Type | Description |
|-------|------|-------------|
| `packId` | string | Unique pack identifier (e.g., `dpack_first90`) |
| `name` | string | Display name |
| `description` | string | Pack description |
| `tier` | string | `standard` or `premium` |
| `price` | int | Price in cents (0 for standard) |
| `currency` | string | ISO 4217 currency code |
| `devotionalCount` | int | Number of devotionals in the pack |
| `category` | string | Pack category (e.g., `early-recovery`, `lent`, `advent`) |
| `thumbnailUrl` | string | Pack thumbnail image URL |
| `sortOrder` | int | Display order |

**Example Document:**

```json
{
  "_id": ObjectId("..."),
  "tenantId": "SYSTEM",
  "status": "published",
  "createdAt": ISODate("2026-01-01T00:00:00Z"),
  "modifiedAt": ISODate("2026-01-01T00:00:00Z"),
  "packId": "dpack_first90",
  "name": "First 90 Days",
  "description": "90 devotionals for the critical first 90 days of recovery",
  "tier": "premium",
  "price": 499,
  "currency": "USD",
  "devotionalCount": 90,
  "category": "early-recovery",
  "thumbnailUrl": "",
  "sortOrder": 1
}
```

---

### 3.5 Devotionals

**Description:** Individual devotional entries belonging to a devotional pack. Day-numbered within the pack.

**Schema:**

| Field | Type | Description |
|-------|------|-------------|
| `devotionalId` | string | Unique devotional identifier |
| `packId` | string | Parent pack identifier |
| `day` | int | Day number within the pack (1-indexed) |
| `title` | string | Devotional title |
| `scripture` | string | Bible verse reference |
| `scriptureText` | string | Full verse text |
| `reflection` | string | Devotional reflection content |
| `prayerPrompt` | string | Suggested prayer |

**Example Document:**

```json
{
  "_id": ObjectId("..."),
  "tenantId": "SYSTEM",
  "status": "published",
  "createdAt": ISODate("2026-01-01T00:00:00Z"),
  "modifiedAt": ISODate("2026-01-01T00:00:00Z"),
  "devotionalId": "dev_001",
  "packId": "dpack_first90",
  "day": 1,
  "title": "A New Beginning",
  "scripture": "2 Corinthians 5:17",
  "scriptureText": "Therefore, if anyone is in Christ, the new creation has come: The old has gone, the new is here!",
  "reflection": "Every day in recovery is a fresh start. God does not define us by our past failures but by His redeeming love. Today, choose to walk in newness of life, knowing that your identity is secure in Christ.",
  "prayerPrompt": "Lord, help me embrace this new beginning. Remind me that Your mercies are new every morning."
}
```

---

### 3.6 Journal Prompts

**Description:** Reflective journal prompts for recovery journaling, organized by category with optional framework tags.

**Schema:**

| Field | Type | Description |
|-------|------|-------------|
| `promptId` | string | Unique prompt identifier |
| `text` | string | Prompt text |
| `category` | string | `daily`, `sobriety`, `emotional`, `relationships`, `spiritual`, `shame`, `triggers`, `amends`, `gratitude`, or `deep` |
| `tags` | []string | Framework tags: `FASTER`, `3 Circles`, `12-Step`, `FANOS/FITNAP`, `PCI`, `Arousal Template` |
| `sortOrder` | int | Display order within category |

**Example Document:**

```json
{
  "_id": ObjectId("..."),
  "tenantId": "SYSTEM",
  "status": "published",
  "createdAt": ISODate("2026-01-01T00:00:00Z"),
  "modifiedAt": ISODate("2026-01-01T00:00:00Z"),
  "promptId": "prompt_001",
  "text": "What am I most grateful for today, and what was the hardest part of my day?",
  "category": "daily",
  "tags": [],
  "sortOrder": 1
}
```

---

### 3.7 Glossary Terms

**Description:** Recovery-specific terminology definitions for developer reference and in-app tooltips.

**Schema:**

| Field | Type | Description |
|-------|------|-------------|
| `termId` | string | Unique term identifier |
| `term` | string | The term (e.g., "FASTER Scale") |
| `definition` | string | Definition text |
| `relatedSlugs` | []string | Related feature_abouts slugs for cross-referencing |
| `sortOrder` | int | Display order |

**Example Document:**

```json
{
  "_id": ObjectId("..."),
  "tenantId": "SYSTEM",
  "status": "published",
  "createdAt": ISODate("2026-01-01T00:00:00Z"),
  "modifiedAt": ISODate("2026-01-01T00:00:00Z"),
  "termId": "term_faster",
  "term": "FASTER Scale",
  "definition": "A relapse-awareness tool developed by Michael Dye that maps six progressive stages leading to relapse. Each letter represents a stage: Forgetting Priorities, Anxiety, Speeding Up, Ticked Off, Exhausted, Relapse.",
  "relatedSlugs": ["faster-scale"],
  "sortOrder": 1
}
```

---

### 3.8 Evening Review Questions

**Description:** Structured evening review questions organized by dimension. Used in the evening review activity.

**Dimensions:** `sobriety`, `emotional`, `relational`, `spiritual`, `recovery`, `faster-scale`, `looking-forward`

**Schema:**

| Field | Type | Description |
|-------|------|-------------|
| `questionId` | string | Unique question identifier |
| `text` | string | Question text |
| `dimension` | string | Question dimension/grouping |
| `sortOrder` | int | Display order within dimension |

**Example Document:**

```json
{
  "_id": ObjectId("..."),
  "tenantId": "SYSTEM",
  "status": "published",
  "createdAt": ISODate("2026-01-01T00:00:00Z"),
  "modifiedAt": ISODate("2026-01-01T00:00:00Z"),
  "questionId": "erq_001",
  "text": "Was I sober today in thought, word, and action?",
  "dimension": "sobriety",
  "sortOrder": 1
}
```

---

### 3.9 Acting-In Behaviors

**Description:** List of acting-in behaviors — subtle, internalized addiction behaviors that occur within relationships.

**Schema:**

| Field | Type | Description |
|-------|------|-------------|
| `behaviorId` | string | Unique behavior identifier |
| `name` | string | Behavior name (e.g., "Blame") |
| `description` | string | Optional description |
| `sortOrder` | int | Display order |

**Example Document:**

```json
{
  "_id": ObjectId("..."),
  "tenantId": "SYSTEM",
  "status": "published",
  "createdAt": ISODate("2026-01-01T00:00:00Z"),
  "modifiedAt": ISODate("2026-01-01T00:00:00Z"),
  "behaviorId": "aib_001",
  "name": "Blame",
  "description": "",
  "sortOrder": 1
}
```

---

### 3.10 Needs

**Description:** List of emotional/relational needs used in recovery check-ins and journaling.

**Schema:**

| Field | Type | Description |
|-------|------|-------------|
| `needId` | string | Unique need identifier |
| `name` | string | Need name (e.g., "Acceptance") |
| `description` | string | Optional description |
| `sortOrder` | int | Display order |

**Example Document:**

```json
{
  "_id": ObjectId("..."),
  "tenantId": "SYSTEM",
  "status": "published",
  "createdAt": ISODate("2026-01-01T00:00:00Z"),
  "modifiedAt": ISODate("2026-01-01T00:00:00Z"),
  "needId": "need_001",
  "name": "Acceptance",
  "description": "",
  "sortOrder": 1
}
```

---

### 3.11 Sobriety Reset Messages

**Description:** Encouragement messages shown when a user resets their sobriety date. Compassionate, grace-centered, evangelical Christian tone.

**Schema:**

| Field | Type | Description |
|-------|------|-------------|
| `messageId` | string | Unique message identifier |
| `text` | string | Message text |
| `scriptureReference` | string | Bible verse reference (optional) |
| `sortOrder` | int | Display order |

**Example Document:**

```json
{
  "_id": ObjectId("..."),
  "tenantId": "SYSTEM",
  "status": "published",
  "createdAt": ISODate("2026-01-01T00:00:00Z"),
  "modifiedAt": ISODate("2026-01-01T00:00:00Z"),
  "messageId": "srm_001",
  "text": "His mercies are new this morning — and so are you.",
  "scriptureReference": "Lamentations 3:22-23",
  "sortOrder": 1
}
```

---

### 3.12 Themes

**Description:** App color scheme themes. Can be standard (free) or premium (purchasable).

**Schema:**

| Field | Type | Description |
|-------|------|-------------|
| `themeId` | string | Unique theme identifier |
| `name` | string | Display name |
| `description` | string | Theme description |
| `tier` | string | `standard` or `premium` |
| `price` | int | Price in cents (0 for standard) |
| `currency` | string | ISO 4217 currency code |
| `colors` | object | Color definitions (see below) |
| `previewUrl` | string | Theme preview image URL |
| `sortOrder` | int | Display order |

**Colors Object:**

| Field | Type | Description |
|-------|------|-------------|
| `primary` | string | Primary brand color (hex) |
| `secondary` | string | Secondary brand color (hex) |
| `accent` | string | Accent/highlight color (hex) |
| `background` | string | Background color (hex) |
| `surface` | string | Surface/card color (hex) |
| `text` | string | Primary text color (hex) |
| `textSecondary` | string | Secondary text color (hex) |

**Example Document:**

```json
{
  "_id": ObjectId("..."),
  "tenantId": "SYSTEM",
  "status": "published",
  "createdAt": ISODate("2026-01-01T00:00:00Z"),
  "modifiedAt": ISODate("2026-01-01T00:00:00Z"),
  "themeId": "theme_midnight",
  "name": "Midnight",
  "description": "Deep navy dark theme",
  "tier": "standard",
  "price": 0,
  "currency": "USD",
  "colors": {
    "primary": "#1A1A2E",
    "secondary": "#16213E",
    "accent": "#0F3460",
    "background": "#0A0A1A",
    "surface": "#1A1A2E",
    "text": "#E0E0E0",
    "textSecondary": "#A0A0A0"
  },
  "previewUrl": "",
  "sortOrder": 1
}
```

---

## 4. Index Reference

### Complete Index Matrix

| # | Collection | Index | Unique | Purpose |
|---|-----------|-------|--------|---------|
| 1 | `feature_abouts` | `{ slug: 1 }` | Yes | Lookup by slug |
| 2 | `feature_abouts` | `{ category: 1, sortOrder: 1 }` | No | List by category |
| 3 | `feature_abouts` | `{ status: 1 }` | No | Filter by status |
| 4 | `affirmation_packs` | `{ packId: 1 }` | Yes | Lookup by pack ID |
| 5 | `affirmation_packs` | `{ tier: 1 }` | No | Filter by tier |
| 6 | `affirmation_packs` | `{ status: 1 }` | No | Filter by status |
| 7 | `affirmations` | `{ affirmationId: 1 }` | Yes | Lookup by ID |
| 8 | `affirmations` | `{ packId: 1, sortOrder: 1 }` | No | List within pack |
| 9 | `devotional_packs` | `{ packId: 1 }` | Yes | Lookup by pack ID |
| 10 | `devotional_packs` | `{ tier: 1 }` | No | Filter by tier |
| 11 | `devotional_packs` | `{ status: 1 }` | No | Filter by status |
| 12 | `devotionals` | `{ devotionalId: 1 }` | Yes | Lookup by ID |
| 13 | `devotionals` | `{ packId: 1, day: 1 }` | Yes | Lookup by pack + day |
| 14 | `journal_prompts` | `{ promptId: 1 }` | Yes | Lookup by ID |
| 15 | `journal_prompts` | `{ category: 1, sortOrder: 1 }` | No | List by category |
| 16 | `journal_prompts` | `{ tags: 1 }` | No | Filter by framework tag (multikey) |
| 17 | `glossary_terms` | `{ termId: 1 }` | Yes | Lookup by ID |
| 18 | `glossary_terms` | `{ term: 1 }` | Yes | Lookup by term name |
| 19 | `evening_review_questions` | `{ questionId: 1 }` | Yes | Lookup by ID |
| 20 | `evening_review_questions` | `{ dimension: 1, sortOrder: 1 }` | No | List by dimension |
| 21 | `acting_in_behaviors` | `{ behaviorId: 1 }` | Yes | Lookup by ID |
| 22 | `needs` | `{ needId: 1 }` | Yes | Lookup by ID |
| 23 | `sobriety_reset_messages` | `{ messageId: 1 }` | Yes | Lookup by ID |
| 24 | `themes` | `{ themeId: 1 }` | Yes | Lookup by ID |
| 25 | `themes` | `{ tier: 1 }` | No | Filter by tier |
| 26 | `themes` | `{ status: 1 }` | No | Filter by status |

---

## 5. Caching Strategy

All content is cached in Valkey with a 24-hour TTL. Cache-aside pattern: read from cache first, fall back to MongoDB, populate cache on miss. Invalidate on write.

| Collection | TTL | Cache Key Pattern | Invalidation |
|-----------|-----|-------------------|-------------|
| `feature_abouts` | 24h | `content:about:{slug}` | On write |
| `affirmation_packs` | 24h | `content:apack:{packId}` | On write |
| `affirmations` | 24h | `content:aff:{packId}` (list) | On pack write |
| `devotional_packs` | 24h | `content:dpack:{packId}` | On write |
| `devotionals` | 24h | `content:dev:{packId}:{day}` | On pack write |
| `journal_prompts` | 24h | `content:prompts:{category}` | On write |
| `glossary_terms` | 24h | `content:glossary` (full list) | On write |
| `evening_review_questions` | 24h | `content:erq:{dimension}` | On write |
| `acting_in_behaviors` | 24h | `content:aib` (full list) | On write |
| `needs` | 24h | `content:needs` (full list) | On write |
| `sobriety_reset_messages` | 24h | `content:srm` (full list) | On write |
| `themes` | 24h | `content:themes:{tier}` | On write |

Small collections (`acting_in_behaviors`, `needs`, `sobriety_reset_messages`, `glossary_terms`) are cached as full lists since they are always fetched in full.

---

## 6. Localization

### 6.1 Database-Per-Language Architecture

Each supported language gets its own complete copy of the content database. All databases share the same schema, indexes, and collection structure — only the content text differs.

**Database naming convention:**

| Locale | Database Name |
|--------|--------------|
| English (default) | `regal-recovery-content` |
| Spanish (Spain) | `regal-recovery-content-es-ES` |
| Spanish (generic) | `regal-recovery-content-es` |
| French (France) | `regal-recovery-content-fr-FR` |
| French (generic) | `regal-recovery-content-fr` |

**Base name:** `regal-recovery-content`
**Suffix pattern:** `-{language}` or `-{language}-{region}` (BCP 47 / IETF locale tag)

### 6.2 Locale Fallback Chain

The API requires a `locale` parameter (e.g., `es-ES`). The content resolver attempts databases in this order:

1. **Full locale:** `regal-recovery-content-es-ES`
2. **Language only:** `regal-recovery-content-es`
3. **Default (English):** `regal-recovery-content`

The first database that exists and contains content is used. Resolution is cached at startup with a configurable TTL to avoid per-request database existence checks.

### 6.3 Implementation

A `ContentResolver` wraps the locale fallback logic:

```
ContentResolver
  ├── resolveDatabase(locale string) *ContentClient
  │   ├── try "regal-recovery-content-{locale}"
  │   ├── try "regal-recovery-content-{language}"
  │   └── fallback "regal-recovery-content"
  └── cachedClients map[string]*ContentClient
```

- Uses the same underlying `mongo.Client` connection — only the database name changes
- Caches resolved `ContentClient` instances per locale (no repeated lookups)
- Database existence is checked by attempting to list collection names
- The resolver is initialized once at Lambda cold start

### 6.4 Non-Translatable Collections

Some collections contain language-independent data and are always read from the default database:

| Collection | Reason |
|-----------|--------|
| `themes` | Color schemes are language-independent |

All other collections are read from the locale-resolved database.

---

## 7. Migration Plan

### 7.1 Collections Migrated from `regal-recovery`

| Source Collection | Target Collection | Schema Changes |
|------------------|------------------|----------------|
| `regal-recovery.affirmation_packs` | `regal-recovery-content.affirmation_packs` | Add `status`, `currency`, `thumbnailUrl`, `sortOrder` |
| `regal-recovery.affirmations` | `regal-recovery-content.affirmations` | Add `status`, `sortOrder` |
| `regal-recovery.devotionals` | `regal-recovery-content.devotionals` | Add `devotionalId`, `packId`, `status`, `prayerPrompt`; create default devotional pack |
| `regal-recovery.prompts` | `regal-recovery-content.journal_prompts` | Add `status`; rename collection |

### 7.2 New Collections Seeded from Repo Content

| Collection | Source File |
|-----------|------------|
| `feature_abouts` | New (31 entries authored per feature; `triggers` entry from `content/triggers/about.md`) |
| `glossary_terms` | `content/glossary.md` |
| `acting_in_behaviors` | `content/acting-in.md` |
| `needs` | `content/needs.md` |
| `sobriety_reset_messages` | `content/sobriety-reset-messages.md` |
| `evening_review_questions` | `content/evening-review-questions.md` |
| `devotional_packs` | New (wrapping existing devotionals into a default pack) |
| `themes` | New (authored fresh) |

### 7.3 Migration Steps

1. Create `regal-recovery-content` database and all indexes
2. Copy and transform documents from source collections in `regal-recovery`
3. Seed new collections from repo content files
4. Update `ContentRepo` in the Go API to connect to `regal-recovery-content`
5. Verify all reads work against the new database
6. Drop migrated source collections from `regal-recovery`

---

## Related Documents

- [MongoDB Schema Design (User Data)](schema-design.md)
- [Content & Resources OpenAPI Spec](../openapi/content.yaml)
- [Test Strategy](../testing/test-strategy.md)
- [Development Workflow](../development-workflow.md)
