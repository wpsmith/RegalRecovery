# Declarations of Truth (Affirmations) -- Multi-Agent Implementation Plan

**Version:** 2.0.0
**Date:** 2026-04-09
**Status:** Draft
**Wave:** 1 (Core P0)
**Feature Flag:** `activity.affirmations`

---

## Overview

This plan follows the project's spec-driven, test-first development methodology. Each agent works on a defined boundary with explicit input specs and output artifacts. Dependencies between agents are managed through verification gates -- no downstream agent starts until its upstream dependency passes.

The Affirmations feature is architecturally complex: pack-based content model, level engine with clinical safeguards, immersive session composition, in-app purchases, audio recording, offline-first sessions, and deep integrations with sobriety counter, relapse detection, mood tracking, and journaling. This warrants 12 agents across backend, mobile, and cross-cutting concerns.

---

## Prerequisites (Wave 0/1 artifacts required)

Before implementation begins, the following must be in place:

- [ ] MongoDB Atlas cluster provisioned with all 10 collections: `affirmationsLibrary`, `affirmationPacks`, `affirmationSessions`, `affirmationFavorites`, `affirmationHidden`, `affirmationCustom`, `affirmationCustomPacks`, `affirmationAudioRecordings`, `affirmationSettings`, `affirmationProgress`
- [ ] `calendarActivities` collection in place (dual-write target)
- [ ] Valkey cache available (local Docker or staging ElastiCache)
- [ ] Feature flag `activity.affirmations` created in `FLAGS` collection (initially disabled)
- [ ] Auth middleware functional (Cognito JWT validation)
- [ ] Tenant isolation middleware functional
- [ ] Calendar activity dual-write infrastructure in place
- [ ] CI/CD pipeline with contract test framework operational
- [ ] Notification infrastructure (SNS/SQS) for reminders, re-engagement, and clinical events
- [ ] Content library seeded: 10 default packs with 200+ declarations (requires pastoral + CSAT review)
- [ ] In-app purchase infrastructure: StoreKit 2 (iOS) + Play Billing v6+ (Android) receipt validation endpoints
- [ ] Sobriety counter integration: days-sober API available for level engine reads
- [ ] Relapse detection integration: `sobriety.reset` event available for level-lock trigger
- [ ] CMS pipeline for content hot updates (Contentful or custom) -- at minimum a seeding script

---

## Agent Assignments

### Agent 1: Contract Tests (RED)

**Scope:** Write failing contract tests from the OpenAPI spec before any implementation. Cover all 27+ endpoints.

**Inputs:**
- `docs/specs/openapi/affirmations.yaml` (to be authored as first task)
- `docs/prd/specific-features/Affirmations/prd.md` (Section 8.1: API Endpoints)

**Outputs:**
- `docs/specs/openapi/affirmations.yaml` -- OpenAPI 3.1 spec for all 27+ endpoints
- `test/contract/affirmations/affirmations_contract_test.go` -- validates all endpoints against OpenAPI schema
- All tests RED (no implementation exists yet)

**Tasks:**
1. Author `affirmations.yaml` OpenAPI spec covering all endpoint groups:
   - Sessions: `GET/POST /activities/affirmations/session/morning`, `GET/POST /session/evening`, `POST /session/on-demand`
   - SOS: `POST /activities/affirmations/sos`, `POST /sos/{sosId}/complete`
   - Library: `GET /activities/affirmations/library`, `GET /library/{affirmationId}`
   - Packs: `GET /activities/affirmations/packs`, `GET /packs/{packId}`, `POST /packs/{packId}/purchase`, `POST /packs/{packId}/restore`, `POST /packs/{packId}/session`
   - Favorites: `GET /activities/affirmations/favorites`, `POST /favorites`, `DELETE /favorites/{favoriteId}`
   - Hidden: `GET /activities/affirmations/hidden`, `POST /hidden`, `DELETE /hidden/{hiddenId}`
   - Custom declarations: `GET /activities/affirmations/custom`, `POST /custom`, `PATCH /custom/{customId}`, `DELETE /custom/{customId}`
   - Custom packs: `POST /activities/affirmations/custom-packs`, `PATCH /custom-packs/{packId}`, `DELETE /custom-packs/{packId}`
   - Audio: `GET /activities/affirmations/{affirmationId}/audio`, `POST /{affirmationId}/audio` (multipart), `DELETE /{affirmationId}/audio`
   - Progress: `GET /activities/affirmations/progress`
   - Settings: `GET /activities/affirmations/settings`, `PATCH /settings` (JSON Merge Patch)
   - Level: `GET /activities/affirmations/level`, `POST /level/override`
   - Sharing: `GET /activities/affirmations/sharing/summary`
2. Define all request/response schemas following Siemens REST API Guidelines v2.5.1
3. Define error codes in `rr:0x000Axxxx` format (0x000A = affirmations domain)
4. Write contract tests for each endpoint validating request schemas, response schemas, status codes, and error envelope format
5. Write contract tests for error cases (400, 401, 403, 404, 409, 422)
6. Write contract tests for feature flag gating (404 when `activity.affirmations` disabled)
7. Verify all tests fail (RED state)

**Verification Gate:** `make contract-test` runs and all affirmation tests are RED (expected failures). No compile errors. `redocly lint affirmations.yaml` passes with 0 errors.

**Dependencies:** None (first agent to start)

---

### Agent 2: Domain Logic -- Pack Model & Level Engine

**Scope:** Pack types, pack validation, pack ownership, and the level engine that gates content by sobriety days.

**Inputs:**
- `docs/prd/specific-features/Affirmations/prd.md` (Sections 3.3, 3.9, 6.1)
- Acceptance criteria for US-AFF-020 through US-AFF-027, US-AFF-080 through US-AFF-082
- NFR-AFF-006, NFR-AFF-007, NFR-AFF-008

**Outputs:**
- `internal/domain/affirmation/pack.go` -- Pack struct, PackType enum (default/premium/custom), pack validation
- `internal/domain/affirmation/declaration.go` -- Declaration struct, level enum (1-4), core belief mapping
- `internal/domain/affirmation/level.go` -- LevelEngine: day-gated levels, post-relapse lock, SOS cap
- `internal/domain/affirmation/serving.go` -- 80/20 ratio, 7-day no-repeat, favorites priority, hidden exclusion
- `internal/domain/affirmation/ownership.go` -- Pack ownership, purchase validation, bundle resolution
- `internal/domain/affirmation/*_test.go` -- unit tests with 100% coverage on level engine

**Tasks:**
1. Write failing unit tests for all level engine rules (RED)
2. Implement PackType enum: `default` (free), `premium` (IAP), `custom` (user-created)
3. Implement Declaration struct with level (1-4), core belief tag, Scripture reference, expansion text, prayer
4. Implement LevelEngine:
   - Day 0-13: Level 1 only
   - Day 14-59: Level 1-2
   - Day 60-179: Level 1-3
   - Day 180+: Level 1-4
   - Post-relapse: locked to Level 1 for 24 hours from `sobrietyResetAt` timestamp
   - SOS mode: capped at Level 2 regardless of user state
   - Purity & Holiness pack: double-gate (60+ days AND explicit opt-in)
5. Implement serving algorithm:
   - 80% current level, 20% one level up (if available)
   - 7-day no-repeat window (unless favorited)
   - Favorites priority boost in selection
   - Hidden declarations excluded from all serving
6. Implement pack ownership validation:
   - Default packs: always accessible
   - Premium packs: require valid purchase receipt
   - Custom packs: require user ownership + Day 14 gate
   - Max 20 custom packs per user, max 50 declarations per custom pack
7. All tests GREEN

**Verification Gate:** `make test-unit` passes. Coverage >= 90% on `internal/domain/affirmation/`. 100% on level engine, serving algorithm, post-relapse lock, SOS cap, double-gate, and ownership validation.

**Dependencies:** None (can run in parallel with Agent 1)

---

### Agent 3: Domain Logic -- Session Composition & Clinical Safeguards

**Scope:** Morning, evening, SOS, and on-demand session composition. All clinical safeguard logic.

**Inputs:**
- `docs/prd/specific-features/Affirmations/prd.md` (Sections 3.1, 3.2, 3.5, 3.7)
- Acceptance criteria for US-AFF-001 through US-AFF-005, US-AFF-010 through US-AFF-015, US-AFF-040 through US-AFF-043, US-AFF-060 through US-AFF-063
- NFR-AFF-003, NFR-AFF-004

**Outputs:**
- `internal/domain/affirmation/session.go` -- SessionType enum, session composition, session completion
- `internal/domain/affirmation/morning.go` -- morning session: 3-5 declarations + intention prompt
- `internal/domain/affirmation/evening.go` -- evening session: 1 declaration + intention recall + day rating
- `internal/domain/affirmation/sos.go` -- SOS session: breathing + 3 Level 1-2 declarations + post-SOS options
- `internal/domain/affirmation/ondemand.go` -- on-demand: declarations from specific pack
- `internal/domain/affirmation/clinical.go` -- clinical safeguard rules
- `internal/domain/affirmation/progress.go` -- cumulative progress, milestone detection
- `internal/domain/affirmation/reengagement.go` -- gap detection and re-engagement logic
- `internal/domain/affirmation/*_test.go` -- unit tests with 100% coverage on clinical safeguards

**Tasks:**
1. Write failing unit tests for all session types and clinical rules (RED)
2. Implement morning session composition:
   - Select 3-5 declarations from active packs at current level
   - Apply 80/20 ratio from Agent 2's serving algorithm
   - Apply 7-day no-repeat, favorites priority, hidden exclusion
   - Include Daily Intention prompt at end
3. Implement evening reflection:
   - Select 1 declaration (Level 1-2 only) from calming/evening packs
   - Surface morning intention text
   - Accept day rating (1-5)
   - Accept optional reflection text
4. Implement SOS session:
   - Mandatory 4-7-8 breathing exercise (30 seconds minimum)
   - 3 declarations from SOS pack, Level 1-2 only (Agent 2's SOS cap)
   - Post-SOS options: reach out, pray, okay
   - SOS privacy: never surfaced to partners without explicit post-session confirmation
5. Implement on-demand pack session:
   - Draw declarations only from the specified pack
   - Apply level gating and hidden exclusion
6. Implement clinical safeguards:
   - Worsening mood: detect 3+ consecutive sessions with declining day rating
   - Crisis bypass: SOS → crisis resources deep link always available
   - Persistent rejection: 5+ hides triggers clinical flag
   - Hidden insight: 3+ hides from same core belief triggers "Holy Spirit" prompt (once per week max)
   - Post-relapse compassionate grounding: Level 1 only, auto-append Lam 3:22-23
7. Implement re-engagement logic:
   - 3-day gap: "Ready when you are."
   - 7-day gap: "Coming back is courage."
   - 14+ day gap: "Reconnect with your partner or pastor?"
   - Never shame language. Never streak reference.
8. Implement cumulative progress:
   - Total sessions, total declarations spoken, packs explored, SOS count
   - NEVER streak-based (NFR-AFF-004)
   - Milestone detection: 1, 10, 25, 50, 100, 250 sessions + first custom + first audio + first SOS + first pack purchased
9. Implement calendar activity dual-write model for session completion
10. All tests GREEN

**Verification Gate:** `make test-unit` passes. Coverage >= 90%. 100% on clinical safeguards, SOS composition, re-engagement logic, and milestone detection. Zero streak-based references in any code or test.

**Dependencies:** Agent 2 (needs level engine, serving algorithm, pack types)

---

### Agent 4: Domain Logic -- Custom Declarations, Audio & Purchases

**Scope:** Custom declaration CRUD, custom pack assembly, audio recording metadata, and purchase model.

**Inputs:**
- `docs/prd/specific-features/Affirmations/prd.md` (Sections 3.3, 3.6, 6.2)
- Acceptance criteria for US-AFF-023 through US-AFF-027, US-AFF-050 through US-AFF-053

**Outputs:**
- `internal/domain/affirmation/custom.go` -- custom declaration CRUD, validation, guidance rules
- `internal/domain/affirmation/custom_pack.go` -- custom pack creation, curated + custom mixing
- `internal/domain/affirmation/audio.go` -- audio metadata, recording constraints, headphone detection interface
- `internal/domain/affirmation/purchase.go` -- purchase model, receipt validation, ownership, restore, bundles
- `internal/domain/affirmation/*_test.go` -- unit tests

**Tasks:**
1. Write failing unit tests (RED)
2. Implement custom declaration CRUD:
   - Day 14 gate: reject creation before Day 14
   - Max 280 characters
   - Present-tense guidance validation (advisory, not blocking)
   - Scripture reference optional
   - Warning text: "Your words carry power. Make sure this feels at least partially true right now."
3. Implement custom pack creation:
   - Mix curated declarations (from owned packs) + custom-written
   - Source attribution preserved for curated declarations
   - Max 20 packs per user, max 50 declarations per pack
   - Name, cover image reference, schedule (daily/weekday/weekend/custom)
   - "Include in daily rotation" toggle
4. Implement audio recording metadata:
   - Max 60 seconds
   - AAC 64kbps .m4a format
   - 5 background music options: worship piano, nature, hymns instrumental, atmospheric, silence
   - Default volume 40% for background behind voice
   - User-adjustable volume
   - Local-only storage by default; cloud sync opt-in flag
5. Define headphone disconnect detection interface:
   - Platform-agnostic interface for AVAudioSession route-change (iOS) / AudioManager (Android)
   - Zero-delay pause requirement (<100ms)
6. Implement purchase model:
   - One-time IAP (never subscription-gated)
   - Receipt validation interface (StoreKit 2 receipt, Play Billing token)
   - Ownership record: userId, packId, receiptId, platform, purchasedAt
   - Restore purchases across devices
   - Bundle support: multiple packs in one purchase
   - Refund handling: revoke ownership on receipt invalidation
7. All tests GREEN

**Verification Gate:** `make test-unit` passes. 100% coverage on Day 14 gate, pack constraints, audio constraints, and purchase ownership logic.

**Dependencies:** Agent 2 (needs pack types and ownership model)

---

### Agent 5: Repository Layer

**Scope:** MongoDB data access implementing all access patterns for 10 collections.

**Inputs:**
- `docs/prd/specific-features/Affirmations/prd.md` (Section 8.2)
- `docs/specs/mongodb/schema-design.md` (Sections 4.34-4.36)
- Domain types from Agents 2, 3, 4

**Outputs:**
- `internal/domain/affirmation/repository.go` -- repository interface definitions
- `internal/repository/mongodb/affirmation_library_repository.go` -- library/pack content
- `internal/repository/mongodb/affirmation_session_repository.go` -- session records
- `internal/repository/mongodb/affirmation_favorites_repository.go` -- favorites
- `internal/repository/mongodb/affirmation_hidden_repository.go` -- hidden declarations
- `internal/repository/mongodb/affirmation_custom_repository.go` -- custom declarations + custom packs
- `internal/repository/mongodb/affirmation_audio_repository.go` -- audio metadata
- `internal/repository/mongodb/affirmation_settings_repository.go` -- user settings
- `internal/repository/mongodb/affirmation_progress_repository.go` -- progress + level history
- `internal/repository/mongodb/affirmation_purchase_repository.go` -- purchase records
- `test/integration/affirmations/affirmation_repository_test.go` -- integration tests

**Tasks:**
1. Define repository interfaces for each collection:
   - `LibraryRepository` -- list packs, get pack, list declarations by pack, search declarations (text index), get preview (3 declarations)
   - `SessionRepository` -- create session, list sessions (date range + type filter), get session by ID, count sessions (cumulative), get 30-day heatmap data
   - `FavoritesRepository` -- add favorite, remove favorite, list favorites (grouped by pack), check if favorited, count favorites
   - `HiddenRepository` -- add hidden, remove hidden, list hidden, check if hidden, count hidden (rolling 30-day), count by core belief
   - `CustomRepository` -- CRUD custom declarations, CRUD custom packs, list user customs, count packs, count declarations per pack
   - `AudioRepository` -- create metadata, get metadata, delete metadata, list by user
   - `SettingsRepository` -- get settings, upsert settings (JSON Merge Patch)
   - `ProgressRepository` -- get progress, increment counters, add level history entry, get level history, add milestone
   - `PurchaseRepository` -- create purchase, get by user+pack, list by user, validate ownership, revoke (refund)
2. Implement MongoDB queries matching access patterns AP-AFF-01 through AP-AFF-30:
   - AP-AFF-01: List packs by category/tier
   - AP-AFF-02: Get pack with declaration count
   - AP-AFF-03: List declarations by pack + level filter
   - AP-AFF-04: Get declaration by ID with expansion
   - AP-AFF-05: Search declarations by text (text index)
   - AP-AFF-06: Create session record
   - AP-AFF-07: List sessions by date range + type
   - AP-AFF-08: Get cumulative session count
   - AP-AFF-09: Get 30-day heatmap (date + count)
   - AP-AFF-10: Add/remove favorite
   - AP-AFF-11: List favorites grouped by source pack
   - AP-AFF-12: Check favorite status (batch)
   - AP-AFF-13: Add/remove hidden
   - AP-AFF-14: List hidden with rolling 30-day count
   - AP-AFF-15: Count hidden by core belief (aggregation)
   - AP-AFF-16: CRUD custom declaration
   - AP-AFF-17: CRUD custom pack with member declarations
   - AP-AFF-18: Count custom packs per user
   - AP-AFF-19: Count declarations per custom pack
   - AP-AFF-20: Create/get/delete audio metadata
   - AP-AFF-21: Get/upsert settings
   - AP-AFF-22: Get progress counters
   - AP-AFF-23: Add level history entry
   - AP-AFF-24: Get milestone history
   - AP-AFF-25: Create purchase record
   - AP-AFF-26: Validate pack ownership
   - AP-AFF-27: List user purchases
   - AP-AFF-28: Restore purchases (by platform receipt)
   - AP-AFF-29: Get recently served declaration IDs (7-day window for no-repeat)
   - AP-AFF-30: Calendar activity dual-write on session completion
3. Implement calendar activity dual-write in session creation (type: `declarations`)
4. Implement cursor-based pagination using `createdAt` + `_id` compound cursor
5. Create text index on `affirmationsLibrary` for declaration search
6. Create all compound indexes as specified in schema
7. Write integration tests against local MongoDB

**Verification Gate:** `make test-integration` passes for all affirmation repository tests. All 30 access patterns verified. Calendar dual-write verified.

**Dependencies:** Agents 2, 3, 4 (needs all domain types)

---

### Agent 6: Cache Layer

**Scope:** Valkey cache-aside pattern for affirmation data with invalidation on mutations.

**Inputs:**
- Repository interfaces from Agent 5
- Performance requirements from PRD Section 8.3

**Outputs:**
- `internal/cache/affirmation_cache.go` -- Valkey cache wrapper for all cached entities
- `test/integration/affirmations/affirmation_cache_test.go` -- cache integration tests

**Tasks:**
1. Implement cache-aside for morning session content (5-min TTL):
   - Key: `aff:morning:{userId}:{date}`
   - Invalidation: on session completion, favorite/hide change
2. Implement cache for pack list (10-min TTL):
   - Key: `aff:packs:{userId}` (includes ownership state)
   - Invalidation: on purchase, custom pack create/delete
3. Implement cache for progress counters (10-min TTL):
   - Key: `aff:progress:{userId}`
   - Invalidation: on session completion, milestone achievement
4. Implement cache for user settings (10-min TTL):
   - Key: `aff:settings:{userId}`
   - Invalidation: on settings PATCH
5. Implement cache for level computation (10-min TTL):
   - Key: `aff:level:{userId}`
   - Invalidation: on sobriety reset event, level override
6. Implement SOS content local device caching strategy:
   - SOS pack declarations pre-fetched and stored with no TTL
   - Key: `aff:sos:content`
   - Invalidation: only on SOS pack content update from CMS
7. Implement cache invalidation on all mutations:
   - Favorite add/remove -> invalidate morning content + favorites list
   - Hide add/remove -> invalidate morning content + hidden list
   - Session complete -> invalidate progress + morning content + heatmap
   - Settings change -> invalidate settings
   - Purchase -> invalidate pack list + ownership
8. Write integration tests verifying cache hit/miss/invalidation for each key pattern

**Verification Gate:** Cache integration tests pass. Cache invalidation verified for all mutation operations. SOS content available when Valkey is unreachable (graceful degradation).

**Dependencies:** Agent 5 (needs repository interface)

---

### Agent 7: Handler Layer (HTTP)

**Scope:** HTTP handlers for all 27+ endpoints, wiring domain logic, repository, and cache with feature flag gating.

**Inputs:**
- `docs/specs/openapi/affirmations.yaml` (from Agent 1)
- Domain logic from Agents 2, 3, 4
- Repository from Agent 5
- Cache from Agent 6

**Outputs:**
- `internal/handler/affirmation_session_handler.go` -- morning, evening, SOS, on-demand session handlers
- `internal/handler/affirmation_library_handler.go` -- library browsing, pack detail, pack preview
- `internal/handler/affirmation_favorites_handler.go` -- favorites CRUD
- `internal/handler/affirmation_hidden_handler.go` -- hidden CRUD
- `internal/handler/affirmation_custom_handler.go` -- custom declarations + custom packs CRUD
- `internal/handler/affirmation_audio_handler.go` -- audio upload (multipart), get, delete
- `internal/handler/affirmation_progress_handler.go` -- progress, milestones
- `internal/handler/affirmation_settings_handler.go` -- settings get + JSON Merge Patch
- `internal/handler/affirmation_level_handler.go` -- level get + override
- `internal/handler/affirmation_purchase_handler.go` -- purchase, restore
- `internal/handler/affirmation_sharing_handler.go` -- sharing summary (partner/therapist view)
- `internal/handler/*_test.go` -- handler unit tests with mocked dependencies

**Tasks:**
1. Implement feature flag check on all handlers: `activity.affirmations` disabled -> 404 (fail closed, NFR-AFF-001)
2. Implement session handlers:
   - `GET /session/morning` -- compose morning session (read)
   - `POST /session/morning` -- complete morning session (write: declarations viewed, intention, duration)
   - `GET /session/evening` -- compose evening session (read: 1 declaration + intention recall)
   - `POST /session/evening` -- complete evening session (write: day rating, reflection, duration)
   - `POST /sos` -- initiate SOS session (returns breathing + declarations)
   - `POST /sos/{sosId}/complete` -- complete SOS (write: reached out, prayed, okay + sharing confirmation)
   - `POST /packs/{packId}/session` -- on-demand pack session
3. Implement library handlers:
   - `GET /library` -- list packs with category filter, tier filter, search
   - `GET /library/{affirmationId}` -- get declaration with full expansion
4. Implement pack handlers:
   - `GET /packs` -- list user's owned + available packs
   - `GET /packs/{packId}` -- pack detail with declarations (owned) or preview (3 declarations if premium + not owned)
   - `POST /packs/{packId}/purchase` -- validate receipt, create ownership
   - `POST /packs/{packId}/restore` -- restore purchases by platform receipt
5. Implement favorites handlers with cursor pagination
6. Implement hidden handlers with cursor pagination + hidden insight trigger (3+ hides)
7. Implement custom declaration handlers with Day 14 gate enforcement
8. Implement custom pack handlers with max 20/50 constraints
9. Implement audio handler with multipart upload support:
   - Validate m4a format, 60s max, file size
   - Store metadata in MongoDB; file stays on device (or S3 if cloud sync opted in)
10. Implement progress handler with cumulative totals and 30-day heatmap
11. Implement settings handler with JSON Merge Patch (RFC 7396)
12. Implement level handler with current level + override (admin/clinical use)
13. Implement sharing handler:
    - Partner view: session count only (no content, no custom, no hidden, no audio)
    - Therapist/pastor view: consistency, mood trend, hidden count, level progression (requires consent)
14. Wire auth middleware (Bearer JWT) and tenant isolation on all handlers
15. Implement response envelope format (`{ data, links, meta }`) and error format (`{ errors: [...] }`)
16. Implement error codes in `rr:0x000Axxxx` range
17. Set Location header and correlation ID on creates
18. Write handler unit tests with mocked domain/repo/cache dependencies

**Verification Gate:** `make contract-test` passes (all RED tests from Agent 1 now GREEN). Handler unit tests pass. Feature flag gating verified.

**Dependencies:** Agents 2, 3, 4, 5, 6 (needs all layers)

---

### Agent 8: Event Publishing & Notifications

**Scope:** SNS/SQS event publishing for session lifecycle, clinical signals, and scheduled notifications.

**Inputs:**
- `docs/prd/specific-features/Affirmations/prd.md` (Sections 3.2, 3.7, 3.8, 5.2, 6.1)
- Handler layer from Agent 7

**Outputs:**
- `internal/events/affirmation_events.go` -- event type definitions
- `internal/events/affirmation_publisher.go` -- SNS publisher for all event types
- `internal/events/affirmation_consumer.go` -- SQS consumers for notification triggers
- `test/integration/affirmations/affirmation_events_test.go` -- event integration tests

**Tasks:**
1. Define event types:
   - `affirmation.session.completed` -- sessionType, userId, declarationCount, duration
   - `affirmation.sos.activated` -- userId, entryPath, daysSober
   - `affirmation.sos.completed` -- userId, breathingCompleted, reachedOut, prayedWith, duration
   - `affirmation.milestone.achieved` -- userId, milestoneType, count
   - `affirmation.mood.worsening` -- userId, consecutiveDeclines (3+)
   - `affirmation.crisis.detected` -- userId, source (SOS/mood rating)
   - `affirmation.relapse.level_lock` -- userId, lockedUntil, previousLevel
   - `affirmation.pack.purchased` -- userId, packId, price, platform
2. Implement SNS publisher for each event type
3. Implement SQS consumers:
   - Post-SOS check-in: 10-minute delayed delivery, in-app notification only (not push)
   - Message: "How are you doing? God is still with you." (no judgment, no recovery language)
   - Morning reminder: user-configured time (default 7:00 AM), generic text
   - Evening reminder: user-configured time (default 9:00 PM), generic text
   - Re-engagement notifications:
     - 3-day gap: "Ready when you are."
     - 7-day gap: "Coming back is courage."
     - 14+ day gap: "Reconnect with your partner or pastor?"
   - Clinical escalation: `mood.worsening` -> flag for therapist dashboard (no auto-notify)
   - Partner encouragement delivery: pre-written messages from partner -> card on user's home screen
4. Ensure all notification text is 100% generic (NFR-AFF-012) -- never recovery-specific language in push notifications
5. Implement `sobriety.reset` event consumer -> trigger level lock to 1 for 24 hours
6. Write integration tests against local SQS/SNS (LocalStack)

**Verification Gate:** Event integration tests pass. Post-SOS check-in fires at correct delay. All notification text verified as generic. Level lock triggered on relapse event. Clinical escalation does not auto-notify.

**Dependencies:** Agent 7 (needs handler to trigger events)

---

### Agent 9: Analytics Instrumentation

**Scope:** All 26 product analytics events from PRD Section 5.1, plus clinical tracking separation.

**Inputs:**
- `docs/prd/specific-features/Affirmations/prd.md` (Section 5.1, 5.2)
- Handler layer from Agent 7

**Outputs:**
- `internal/analytics/affirmation_analytics.go` -- analytics event definitions and publisher
- `internal/analytics/affirmation_clinical.go` -- clinical tracking (non-analytics, per-user)
- `test/unit/affirmation_analytics_test.go` -- unit tests

**Tasks:**
1. Implement all 26 product analytics events matching PRD Section 5.1 exactly:
   - `affirmation.session.started` -- sessionType, entryPath, packId, level
   - `affirmation.session.completed` -- sessionType, entryPath, declarationCount, durationSeconds, level, usedBreathing, usedPrayer
   - `affirmation.session.skipped` -- sessionType, entryPath
   - `affirmation.session.abandoned` -- sessionType, declarationIndex, durationSeconds
   - `affirmation.declaration.viewed` -- affirmationId, packId, level, durationOnCard
   - `affirmation.declaration.favorited` -- affirmationId, packId, level
   - `affirmation.declaration.hidden` -- affirmationId, packId, level
   - `affirmation.declaration.expanded` -- affirmationId, expandedSection
   - `affirmation.sos.triggered` -- entryPath, daysSober
   - `affirmation.sos.completed` -- breathingCompleted, reachedOut, prayedWith, durationSeconds
   - `affirmation.sos.postCheckin` -- rating, responded
   - `affirmation.pack.viewed` -- packId, packType
   - `affirmation.pack.purchased` -- packId, price, bundleId
   - `affirmation.pack.purchaseAbandoned` -- packId, step
   - `affirmation.custom.packCreated` -- affirmationCount, hasCustomWritten, hasCurated
   - `affirmation.custom.declarationWritten` -- hasScripture, charCount
   - `affirmation.audio.recorded` -- affirmationId, durationSeconds, backgroundMusic
   - `affirmation.audio.played` -- affirmationId, isOwnVoice, isNarrated
   - `affirmation.audio.headphoneDisconnect` -- (no properties)
   - `affirmation.level.changed` -- previousLevel, newLevel, trigger
   - `affirmation.milestone.achieved` -- milestoneType, count
   - `affirmation.evening.dayRating` -- rating
   - `affirmation.reEngagement.shown` -- gapDays, entryPath
   - `affirmation.reEngagement.accepted` -- gapDays
   - `affirmation.notification.tapped` -- notificationType
   - `affirmation.widget.tapped` -- (no properties)
   - `affirmation.sharing.partnerViewed` -- dataType
   - `affirmation.sharing.therapistViewed` -- dataTypes[]
2. Ensure all events are anonymized: no declaration content, no custom text, no personal data
3. Implement opt-out support: check user analytics preference before publishing
4. Implement clinical tracking (non-analytics, per-user) as separate data path:
   - Session history (type, date, time, duration) -> stored in `affirmationSessions`
   - Level history (level, date, trigger) -> stored in `affirmationProgress.levelHistory`
   - Hidden declaration count (rolling 30-day) -> aggregated from `affirmationHidden`
   - Hidden declarations by core belief -> aggregation pipeline
   - Evening mood ratings (rolling) -> stored in `affirmationSessions` (evening type)
   - Consecutive declining mood count -> computed in domain layer
   - SOS frequency (rolling 30-day) -> aggregation pipeline
   - Custom declaration themes -> NEVER analyzed by system (privacy)
5. Verify zero declaration content leaks into analytics pipeline
6. Write unit tests for event property validation and anonymization

**Verification Gate:** All 26 analytics events fire with correct properties. Zero personal data in analytics events. Opt-out respected. Clinical tracking stored per-user only. Custom declaration content never in analytics.

**Dependencies:** Agent 7 (needs handler integration points)

---

### Agent 10: Integration + E2E Tests

**Scope:** Full-stack integration tests against local infrastructure. E2E flows covering all 7 user journeys from PRD Section 4.

**Inputs:**
- `docs/prd/specific-features/Affirmations/prd.md` (Section 4: User Journeys, Section 12: Success Criteria)
- All implementation from Agents 2-9

**Outputs:**
- `test/integration/affirmations/affirmation_full_test.go` -- full-stack integration tests
- `test/e2e/affirmations/affirmation_e2e_test.go` -- E2E tests for staging

**Tasks:**
1. Write full-stack integration tests using `make local-up`:
   - Morning session: compose -> complete -> verify progress + calendar dual-write
   - Evening session: compose (with intention recall) -> complete (with day rating) -> verify mood feed
   - SOS session: activate -> breathing -> declarations (Level 1-2 only) -> complete -> verify 10-min check-in scheduled
   - On-demand pack session: select pack -> compose -> complete
   - Favorite lifecycle: add -> verify serving priority -> remove
   - Hidden lifecycle: add -> verify excluded from serving -> hidden insight trigger at 3+
   - Custom declaration: create (Day 14 gate) -> edit -> add to custom pack -> session from custom pack
   - Audio metadata: create -> get -> delete -> verify local-only storage
   - Purchase: validate receipt -> create ownership -> verify pack access -> restore on new device
   - Level progression: Day 1 -> Day 14 (L2 unlock) -> Day 60 (L3 unlock) -> Day 180 (L4 unlock)
   - Post-relapse: sobriety reset -> verify Level 1 lock -> verify 24h expiry -> verify normal resume
   - Settings: get defaults -> patch -> verify cached settings invalidated
   - Sharing: partner view (count only) -> therapist view (with consent) -> revoke consent
2. Write E2E persona flows from PRD Section 4:
   - Journey 4.1 -- Alex first-time: onboarding -> Level 1 -> first declaration -> Amen -> Today card
   - Journey 4.2 -- Alex morning (Day 45): notification -> 3 declarations (L2+L3 mix) -> favorite -> intention -> Amen
   - Journey 4.3 -- Marcus SOS (Day 7): SOS tap -> breathing -> 3 L1 declarations -> reach out -> post-check-in
   - Journey 4.4 -- Diego custom pack (Day 200): create pack -> browse owned -> curate + write -> save -> session
   - Journey 4.5 -- Marcus post-relapse (Day 1 reset): relapse report -> L1 lock -> compassionate card -> L1 session
   - Journey 4.6 -- Sarah evening (Day 90): notification -> 1 calming declaration -> intention recall -> rate 4/5 -> Amen
   - Journey 4.7 -- Diego premium purchase: browse -> preview 3 -> purchase -> unlock -> start session
3. Verify clinical safeguard triggers:
   - 3+ declining mood sessions -> worsening event
   - 5+ hides -> clinical flag
   - 3+ hides same core belief -> insight prompt
   - Post-relapse + SOS -> compassionate L1 only
4. Verify calendar activity dual-write on every session type
5. Verify cache behavior end-to-end (morning content, settings, progress)
6. Verify feature flag gating: disable flag -> all endpoints 404

**Verification Gate:** `make test-integration` and `make test-e2e` pass. All 7 user journeys verified. All acceptance criteria covered. Calendar dual-write verified for every session type.

**Dependencies:** Agents 2-9 (needs complete implementation)

---

### Agent 11: iOS Mobile Client

**Scope:** Full iOS implementation including API client, offline cache, immersive session UI, StoreKit 2 purchases, audio recording, and widgets.

**Inputs:**
- `docs/specs/openapi/affirmations.yaml` (from Agent 1)
- `docs/prd/specific-features/Affirmations/prd.md` (Sections 3, 7, 8)

**Outputs:**
- `ios/RegalRecovery/RegalRecovery/Models/Affirmation/` -- SwiftData models for all types
- `ios/RegalRecovery/RegalRecovery/Services/AffirmationAPIClient.swift` -- hand-written API client
- `ios/RegalRecovery/RegalRecovery/Services/AffirmationSyncEngine.swift` -- offline sync
- `ios/RegalRecovery/RegalRecovery/Services/AffirmationAudioManager.swift` -- audio recording + playback
- `ios/RegalRecovery/RegalRecovery/Services/AffirmationStoreManager.swift` -- StoreKit 2 purchases
- `ios/RegalRecovery/RegalRecovery/ViewModels/Affirmation/` -- MVVM view models
- `ios/RegalRecovery/RegalRecovery/Views/Activities/Affirmations/` -- all SwiftUI views
- `ios/RegalRecovery/RegalRecovery/Views/Tools/AffirmationWidget/` -- WidgetKit extension
- `ios/RegalRecovery/RegalRecovery/Tests/Unit/Affirmation/` -- Swift Testing unit tests

**Tasks:**
1. Hand-write Swift Codable structs for all types:
   - `AffirmationPack`, `AffirmationDeclaration`, `AffirmationSession`, `AffirmationFavorite`, `AffirmationHidden`, `AffirmationCustomDeclaration`, `AffirmationCustomPack`, `AffirmationAudioMetadata`, `AffirmationSettings`, `AffirmationProgress`, `AffirmationLevel`, `AffirmationPurchase`, `AffirmationSharingSummary`
2. Hand-write URLSession API client for all 27+ endpoints:
   - Session endpoints (morning GET/POST, evening GET/POST, SOS POST, on-demand POST)
   - Library endpoints (list, get)
   - Pack endpoints (list, get, purchase, restore, session)
   - Favorites, hidden, custom, audio, progress, settings, level, sharing
3. Implement SwiftData models for offline cache:
   - Cache 30+ declarations from active packs for offline morning/evening sessions
   - Cache full SOS pack permanently (always available offline)
   - Cache favorites, custom packs, custom declarations locally
   - Cache progress counters and level locally
   - Queue mutations (favorite, hide, custom CRUD, session completion) for sync
4. Implement `SyncEngine` integration:
   - Queue offline mutations with timestamps
   - Sync on `NetworkMonitor` connectivity restored
   - Union merge for session records (never lose a session)
5. Implement pack browser UI:
   - Pack library grid: default (free), premium (locked with price), custom packs
   - Category/theme filtering
   - Pack detail: cover art, description, declaration list (owned) or preview (3 declarations if premium)
   - Purchase flow with StoreKit 2 sheet
   - Custom pack creation wizard: name, cover, add from owned packs, write custom, set schedule
6. Implement immersive session UI:
   - Full-screen mode, no status bar, fade-in transition
   - Large serif typography (24pt+ with Dynamic Type support)
   - Calming background (12+ options: nature, abstract, cross/light, solid)
   - One declaration per screen with swipe right (next) / swipe left (previous)
   - Progress indicator (dots)
   - Heart icon (favorite), hide icon, pray button, audio button, breathing icon
   - Scripture reference visible; tap/swipe-up reveals full verse + reflection + prayer
   - "Amen" close button on final screen with gentle fade-out
   - Daily Intention prompt (morning) with text field
   - Evening: intention recall + day rating (1-5) + optional reflection
7. Implement SOS mode:
   - Immediate full-screen calm with Psalm 46:1
   - 4-7-8 breathing animation (30s mandatory, visual animation)
   - 3 Level 1-2 declarations from SOS pack
   - Post-SOS: "Reach out" (contact list), "Pray with me" (guided prayer), "I'm okay" (gentle close)
   - SOS privacy: sharing confirmation before any data leaves device
8. Implement StoreKit 2 purchase flow:
   - Product fetching, purchase sheet, receipt validation via API
   - Restore purchases, transaction listener for pending transactions
   - Ownership persistence in SwiftData
9. Implement audio session manager:
   - AVAudioRecorder for recording (AAC 64kbps, .m4a, 60s max)
   - AVAudioPlayer for playback with background music mixing
   - 5 background options at configurable volume (default 40%)
   - AVAudioSession route-change notification for headphone disconnect (< 100ms pause)
   - Local-only storage with optional cloud sync
10. Implement WidgetKit extension:
    - Small widget: today's declaration (Scripture only, privacy-safe)
    - Medium widget: declaration + Scripture reference
    - Daily rotation at morning time
    - Deep link: tap -> immersive session
    - No recovery language, no app name visible (NFR-AFF-013)
11. Implement VoiceOver accessibility:
    - Declaration read as: "Declaration: [text]. Scripture reference: [ref]. Tap to expand reflection."
    - All interactive elements: min 44x44pt touch targets
    - Dynamic Type support at all system sizes
    - Reduced Motion setting: disable parallax, breathing animation (static), fade (instant)
    - High Contrast mode support
    - Swipe alternatives: next/previous buttons
12. Write Swift Testing unit tests:
    - ViewModel tests for session composition, pack browsing, custom creation
    - API client serialization tests
    - Offline queue tests
    - Audio manager tests (mock AVAudioSession)
    - StoreKit manager tests

**Verification Gate:** All Swift Testing tests pass. VoiceOver audit complete. Dynamic Type tested at all sizes. Offline session functionality verified. Headphone disconnect pauses in < 100ms.

**Dependencies:** Agent 1 (needs OpenAPI spec for API client). Can run in parallel with Agents 2-9.

---

### Agent 12: Android Mobile Client (Placeholder)

**Scope:** Kotlin scaffolding for Android. This is placeholder implementation for future Wave 2 work.

**Inputs:**
- `docs/specs/openapi/affirmations.yaml` (from Agent 1)
- `docs/prd/specific-features/Affirmations/prd.md` (Section 8.6)

**Outputs:**
- `android/app/src/main/java/.../data/model/Affirmation*.kt` -- Kotlin data classes
- `android/app/src/main/java/.../data/api/AffirmationApiService.kt` -- Retrofit interface
- `android/app/src/main/java/.../data/local/AffirmationDao.kt` -- Room DAO for offline cache
- `android/app/src/main/java/.../data/store/AffirmationDataStore.kt` -- DataStore for settings
- `android/app/src/main/java/.../ui/affirmation/` -- Compose UI scaffolding
- `android/app/src/main/java/.../billing/AffirmationBillingManager.kt` -- Play Billing v6+
- `android/app/src/main/java/.../audio/AffirmationAudioManager.kt` -- AudioManager headphone detection
- `android/app/src/main/java/.../widget/AffirmationWidget.kt` -- AppWidget provider
- `android/app/src/test/java/.../affirmation/` -- unit tests

**Tasks:**
1. Hand-write Kotlin data classes matching OpenAPI schemas (camelCase with `@SerializedName`)
2. Hand-write Retrofit service interface for all 27+ endpoints
3. Implement Room entities + DAO for offline cache:
   - Cache declarations, SOS pack, favorites, custom packs
   - Queue mutations for sync
4. Implement DataStore for settings and preferences
5. Implement Compose UI scaffolding:
   - Pack browser, session screen (placeholder), custom creation
   - Immersive session with `WindowCompat` for edge-to-edge
6. Implement Play Billing v6+ purchase flow:
   - BillingClient setup, product query, purchase launch, receipt validation
   - Purchase acknowledgment, restore (queryPurchasesAsync)
7. Implement AudioManager headphone detection:
   - `ACTION_HEADSET_PLUG` broadcast receiver
   - `AudioDeviceCallback` for API 23+
   - Zero-delay pause on disconnect
8. Implement AppWidget (small, medium):
   - Privacy-safe Scripture only
   - Daily rotation, deep link to session
9. Write unit tests for data classes, billing state, audio detection

**Verification Gate:** Kotlin compiles. Retrofit interface matches OpenAPI spec. Room schema validated. Unit tests pass.

**Dependencies:** Agent 1 (needs OpenAPI spec). Can run in parallel with Agents 2-9 and Agent 11.

---

## Execution Timeline

```
Week 1:
  [Agent 1]  Contract Tests (RED)           ████████░░░░░░░░░░░░░░░░░░░░░░░░
  [Agent 2]  Pack Model & Level Engine      ████████████░░░░░░░░░░░░░░░░░░░░
  [Agent 11] iOS Client (models + API)      ████░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  [Agent 12] Android Client (models + API)  ████░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Week 2:
  [Agent 3]  Session & Clinical Safeguards  ░░░░░░░░████████████░░░░░░░░░░░░
  [Agent 4]  Custom, Audio & Purchases      ░░░░░░░░████████████░░░░░░░░░░░░
  [Agent 11] iOS Client (offline + sync)    ░░░░████████░░░░░░░░░░░░░░░░░░░░
  [Agent 12] Android Client (Room + Store)  ░░░░████████░░░░░░░░░░░░░░░░░░░░

Week 3:
  [Agent 5]  Repository Layer               ░░░░░░░░░░░░░░░░████████████░░░░
  [Agent 6]  Cache Layer                    ░░░░░░░░░░░░░░░░░░░░████████░░░░
  [Agent 11] iOS Client (session UI + SOS)  ░░░░░░░░░░░░████████████░░░░░░░░

Week 4:
  [Agent 7]  Handler Layer                  ░░░░░░░░░░░░░░░░░░░░░░░░████████
  [Agent 11] iOS Client (purchase + audio)  ░░░░░░░░░░░░░░░░░░░░████████░░░░

Week 5:
  [Agent 8]  Event Publishing               ░░░░░░░░░░░░░░░░░░░░░░░░░░░░████
  [Agent 9]  Analytics Instrumentation      ░░░░░░░░░░░░░░░░░░░░░░░░░░░░████
  [Agent 11] iOS Client (widget + a11y)     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░████
  [Agent 12] Android Client (Compose + wdg) ░░░░░░░░░░░░░░░░░░░░░░░░████████

Week 6:
  [Agent 10] Integration + E2E Tests        ░░░░░░░░░░░░░░░░░░░░░░░░░░░░████
  [Agent 11] iOS Client (tests + polish)    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░████
  [Agent 12] Android Client (tests)         ░░░░░░░░░░░░░░░░░░░░░░░░░░░░████

Gate: All tests GREEN -> Enable feature flag for staging
```

---

## Dependency Graph

```
Agent 1 (Contract Tests RED) ----+------+------+
  |                              |      |      |
  |                        Agent 11  Agent 12  |
  |                        (iOS)    (Android)  |
  |                              |      |      |
Agent 2 (Pack Model +           |      |      |
         Level Engine) ---------+------+------+
  |              |                             |
  |              |                             |
  v              v                             |
Agent 3        Agent 4                         |
(Session +     (Custom +                       |
 Clinical)     Audio +                         |
  |            Purchase)                       |
  |              |                             |
  +------+-------+                             |
         |                                     |
         v                                     |
Agent 5 (Repository Layer)                     |
         |                                     |
         v                                     |
Agent 6 (Cache Layer)                          |
         |                                     |
         v                                     |
Agent 7 (Handler Layer) <----------------------+
  |         |         |        (verifies Agent 1's tests GREEN)
  |         |         |
  v         v         v
Agent 8   Agent 9   Agent 10
(Events)  (Analytics) (Integration + E2E)
```

---

## Verification Gates (Quality Checkpoints)

| Gate | Trigger | Criteria | Blocks |
|------|---------|----------|--------|
| **G1: Spec Valid** | After Agent 1 | `redocly lint affirmations.yaml` passes with 0 errors. All contract tests RED. | All agents |
| **G2: Level Engine** | After Agent 2 | Unit tests pass. 100% coverage on level engine, serving algorithm, SOS cap, double-gate, post-relapse lock. | Agents 3, 4 |
| **G3: Session & Clinical** | After Agent 3 | Unit tests pass. 100% coverage on clinical safeguards, SOS composition, re-engagement. Zero streak references. | Agent 5 |
| **G4: Custom & Purchase** | After Agent 4 | Unit tests pass. 100% coverage on Day 14 gate, pack constraints, audio constraints, purchase ownership. | Agent 5 |
| **G5: Repository** | After Agent 5 | Integration tests pass. All 30 access patterns verified. Calendar dual-write verified. | Agent 6 |
| **G6: Cache** | After Agent 6 | Cache integration tests pass. Invalidation verified for all mutations. SOS graceful degradation verified. | Agent 7 |
| **G7: Handlers GREEN** | After Agent 7 | All contract tests from Agent 1 now GREEN. Handler unit tests pass. Feature flag gating verified. | Agents 8, 9, 10 |
| **G8: Events** | After Agent 8 | Event integration tests pass. Post-SOS 10-min delay verified. All notification text generic. Level lock on relapse. | Agent 10 |
| **G9: Analytics** | After Agent 9 | All 26 events fire correctly. Zero personal data in analytics. Opt-out respected. Clinical tracking separate. | Agent 10 |
| **G10: Full Integration** | After Agent 10 | `make test-integration` + `make test-e2e` pass. All 7 user journeys verified. All ACs covered. | Feature flag enable |
| **G11: iOS Client** | After Agent 11 | Swift Testing tests pass. VoiceOver audit complete. Dynamic Type all sizes. Offline verified. Headphone disconnect < 100ms. | App release |
| **G12: Android Client** | After Agent 12 | Kotlin compiles. Retrofit matches spec. Room schema valid. Unit tests pass. | Future Android release |

---

## Feature Flag Rollout Plan

| Stage | `activity.affirmations` Config | Audience |
|-------|-------------------------------|----------|
| Development | Enabled for `tenant: DEV` only | Dev team |
| Staging QA | Enabled for all tenants, staging only | QA team + pastoral advisory review |
| Content Review | Enabled, staging only, full content library loaded | CSAT + pastoral advisor content review |
| Canary | Enabled, rolloutPercentage: 5% | 5% of production users (established recovery, Day 60+) |
| Early Access | rolloutPercentage: 15% | Include new users, Day 14+ |
| Gradual | rolloutPercentage: 25% -> 50% -> 75% -> 100% | Progressive rollout over 3 weeks |
| GA | Enabled, rolloutPercentage: 100% | All users |

---

## Risk Mitigation

| # | Risk | Severity | Mitigation |
|---|------|----------|-----------|
| 1 | **Backfire risk** -- identity-level declarations too early in recovery cause shame, not healing (Carnes' research) | Critical | Level engine with day-gated locks (L1 only until Day 14). Post-relapse 24h Level 1 lock. 100% test coverage on level engine. SOS capped at L2. Content reviewed by CSAT before release. |
| 2 | **Audio privacy** -- accidental playback of recorded declarations in public | Critical | Headphone disconnect detection with < 100ms pause (NFR-AFF-005). Local-only storage by default. Cloud sync explicitly opt-in. Audio never synced to partner view. Non-negotiable safety requirement. |
| 3 | **Shame spiral** -- missed sessions triggering guilt, which triggers relapse | High | Zero streak-based metrics (NFR-AFF-004). No "missed day" language. No "broken streak." Cumulative totals only. Re-engagement messages use compassionate framing. Code review rejects any streak reference. |
| 4 | **Clinical safeguard failure** -- worsening mood or crisis not detected | High | 3+ declining session ratings triggers `mood.worsening` event. Rating = 1 triggers crisis resources. 5+ hides triggers clinical flag. All safeguards have 100% test coverage. Safeguards are never disabled by feature flags. |
| 5 | **Content quality / theological error** -- declarations that are doctrinally unsound, prosperity-gospel adjacent, or clinically harmful | High | Dual review pipeline: CSAT reviews clinical appropriateness + pastoral advisor reviews theological accuracy. CMS hot update capability for rapid correction. No user-generated content visible to other users. |
| 6 | **SOS latency** -- slow response when user is in crisis | High | SOS pack always cached locally (offline-first, NFR-AFF-011). Target < 500ms from tap to full-screen. SOS never requires network. Performance tested under load. Graceful degradation if Valkey unreachable. |
| 7 | **IAP edge cases** -- refunds, duplicate purchases, subscription confusion, cross-platform ownership | Medium | Server-side receipt validation. One-time purchase model only (never subscription-gated). Restore purchases endpoint. Refund webhook revokes ownership. Bundle handling. Integration tests cover purchase/restore/refund flows. |
| 8 | **Theological review pipeline bottleneck** -- content blocked on pastoral advisor availability | Medium | Seed with 10 pre-reviewed default packs (200+ declarations). CMS hot update for corrections. Pastoral advisor on retainer with 48-hour SLA. Premium packs reviewed in advance, not on purchase. |
| 9 | **Offline-first complexity** -- sync conflicts between device cache and server state | Medium | Union merge for session records (never lose a completed session). LWW for settings and favorites. Custom declarations are local-first, server-synced. SOS always works offline. Conflict resolution tested in E2E suite. |
| 10 | **Post-relapse re-entry** -- user reports relapse and is met with advanced content that deepens shame | Medium | Automatic Level 1 lock for 24h (non-overridable). Auto-append Lamentations 3:22-23. Compassionate card on Today screen. No identity-level declarations served. 24h window auto-expires. Integration tests verify lock + expiry. |
| 11 | **Purity & Holiness pack misuse** -- sexually explicit themes presented to users not ready | Medium | Double-gate: 60+ days sobriety AND explicit opt-in required (NFR-AFF-008). Not in default rotation. Not discoverable until Day 60. Warning dialog on opt-in. |
| 12 | **Widget privacy leak** -- home screen widget reveals recovery context to bystander | Low | Widget shows general Scripture only (NFR-AFF-013). No recovery language. No app name visible. No "affirmation" or "recovery" text. Content reviewed for privacy safety. |
| 13 | **Partner notification misuse** -- SOS or session details shared without consent | Low | SOS never surfaced to partners without explicit post-session confirmation (US-AFF-015). Partner view shows session count only (US-AFF-070). Therapist view requires granular consent per data type. Audit log of shared events. |

---

## PR Decomposition

Target < 400 lines per PR. Recommended stacking:

| PR | Agent | Content | Lines (est.) |
|----|-------|---------|-------------|
| PR-1 | 1 | OpenAPI spec `affirmations.yaml` | ~400 |
| PR-2 | 1 | Contract tests (RED) -- all 27+ endpoints | ~400 |
| PR-3 | 2 | Domain types: Pack, Declaration, Level enum, PackType | ~300 |
| PR-4 | 2 | Level engine + serving algorithm + tests | ~400 |
| PR-5 | 2 | Pack ownership validation + tests | ~250 |
| PR-6 | 3 | Session types + morning/evening composition + tests | ~400 |
| PR-7 | 3 | SOS session + clinical safeguards + tests | ~400 |
| PR-8 | 3 | Progress, milestones, re-engagement logic + tests | ~350 |
| PR-9 | 4 | Custom declaration + custom pack CRUD + tests | ~400 |
| PR-10 | 4 | Audio metadata + purchase model + tests | ~350 |
| PR-11 | 5 | Repository interfaces + library/session/favorites/hidden MongoDB impl | ~400 |
| PR-12 | 5 | Repository: custom, audio, settings, progress, purchase MongoDB impl + integration tests | ~400 |
| PR-13 | 6 | Cache layer (all keys + invalidation) + tests | ~350 |
| PR-14 | 7 | Handlers: sessions (morning/evening/SOS/on-demand) + feature flag | ~400 |
| PR-15 | 7 | Handlers: library, packs, favorites, hidden, sharing | ~400 |
| PR-16 | 7 | Handlers: custom, audio (multipart), progress, settings, level, purchase | ~400 |
| PR-17 | 8 | Event publishing + notification consumers + tests | ~350 |
| PR-18 | 9 | Analytics instrumentation (26 events) + clinical tracking + tests | ~350 |
| PR-19 | 10 | Integration tests (full-stack flows) | ~400 |
| PR-20 | 10 | E2E tests (7 persona journeys) | ~400 |
| PR-21 | 11 | iOS: models + API client + offline SwiftData cache | ~400 |
| PR-22 | 11 | iOS: pack browser UI + custom pack creation | ~400 |
| PR-23 | 11 | iOS: immersive session UI + SOS mode | ~400 |
| PR-24 | 11 | iOS: StoreKit 2 purchase flow + audio manager | ~400 |
| PR-25 | 11 | iOS: WidgetKit + accessibility + Swift Testing tests | ~400 |
| PR-26 | 12 | Android: data classes + Retrofit + Room + DataStore | ~350 |
| PR-27 | 12 | Android: Compose scaffolding + Play Billing + widget | ~350 |
