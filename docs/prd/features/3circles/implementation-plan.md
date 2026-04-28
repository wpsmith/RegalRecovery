# Three Circles -- Multi-Agent Implementation Plan

**Version:** 1.0.0
**Date:** 2026-04-08
**Status:** Draft
**Wave:** 1 (Core P0)
**Feature Flag:** `feature.3circles`

---

## Overview

This plan follows the project's spec-driven, test-first development methodology. Each agent works on a defined boundary with explicit input specs and output artifacts. Dependencies between agents are managed through verification gates -- no downstream agent starts until its upstream dependency passes.

The Three Circles feature is the foundational recovery tool: circle set builder with templates and starter packs, version history, sponsor review, pattern visualization with drift detection and insights, and quarterly review workflow. It spans 11 MongoDB collections, 36+ API endpoints, and deep integration with the daily check-in system. This warrants 12 agents across backend, mobile, and cross-cutting concerns.

---

## Prerequisites (Wave 0/1 artifacts required)

Before implementation begins, the following must be in place:

- [ ] MongoDB Atlas cluster provisioned with all 11 collections: `circlesSets`, `circlesVersions`, `circlesTemplates`, `circlesStarterPacks`, `circlesOnboarding`, `circlesShares`, `circlesSponsorComments`, `circlesPatternTimeline`, `circlesInsights`, `circlesDriftAlerts`, `circlesReviews`
- [ ] `calendarActivities` collection in place (dual-write target)
- [ ] Valkey cache available (local Docker or staging ElastiCache)
- [ ] Feature flag `feature.3circles` created in `FLAGS` collection (initially disabled)
- [ ] Auth middleware functional (Cognito JWT validation)
- [ ] Tenant isolation middleware functional
- [ ] Calendar activity dual-write infrastructure in place
- [ ] CI/CD pipeline with contract test framework operational
- [ ] Daily check-in integration: check-in events available for timeline data ingestion
- [ ] Template content seeded: templates for all 10 recovery areas (requires clinical + community review)
- [ ] Starter pack content seeded: minimum 3 variants (secular, faith-based, LGBTQ+-affirming) per recovery area (requires CSAT + pastoral review)
- [ ] Crisis resource integration (988, SAMHSA) functional for builder exit handling

---

## Agent Assignments

### Agent 1: Contract Tests (RED)

**Scope:** Write failing contract tests from the OpenAPI spec before any implementation. Cover all 36+ endpoints.

**Inputs:**
- `docs/prd/specific-features/3circles/specs/openapi.yaml`
- `docs/prd/specific-features/3circles/specs/acceptance-criteria.md`

**Outputs:**
- `api/test/contract/threecircles/threecircles_contract_test.go` -- validates all endpoints against OpenAPI schema
- All tests RED (no implementation exists yet)

**Tasks:**
1. Write contract tests for each endpoint group validating request schemas, response schemas, status codes, and error envelope format:
   - Circle Sets: `GET/POST /sets`, `GET/PUT/PATCH/DELETE /sets/{setId}`, `POST /sets/{setId}/commit`
   - Circle Items: `POST /sets/{setId}/items`, `PUT/DELETE /sets/{setId}/items/{itemId}`, `POST /sets/{setId}/items/{itemId}/move`
   - Version History: `GET /sets/{setId}/versions`, `GET /sets/{setId}/versions/{versionId}`, `POST /sets/{setId}/versions/{versionId}/restore`
   - Templates: `GET /templates`, `GET /templates/{templateId}`
   - Starter Packs: `GET /starter-packs`, `GET /starter-packs/{packId}`, `POST /sets/{setId}/apply-starter-pack`
   - Onboarding: `POST /onboarding/start`, `PATCH /onboarding/{flowId}`, `POST /onboarding/{flowId}/complete`
   - Sponsor Review: `POST /sets/{setId}/share`, `GET /share/{shareCode}`, `POST /share/{shareCode}/comments`, `GET /sets/{setId}/comments`
   - Pattern Visualization: `GET /patterns/timeline`, `GET /patterns/insights`, `GET /patterns/summary`, `GET /patterns/drift-alerts`, `POST /patterns/drift-alerts/{alertId}/dismiss`
   - Quarterly Review: `GET/POST /reviews`, `PATCH /reviews/{reviewId}`, `POST /reviews/{reviewId}/complete`
2. Write contract tests for error cases (400, 401, 404, 409, 410, 422)
3. Write contract tests for feature flag gating (404 when `feature.3circles` disabled)
4. Define all error codes in `rr:0x000B{4 hex}` format
5. Verify all tests fail (RED state)

**Verification Gate:** `make contract-test` runs and all three-circles tests are RED (expected failures). No compile errors. `redocly lint openapi.yaml` passes with 0 errors.

**Dependencies:** None (first agent to start)

---

### Agent 2: Domain Logic -- Circle Set & Item Management

**Scope:** Circle set CRUD, circle item CRUD (add/update/delete/move), commit logic, and version snapshot creation.

**Inputs:**
- `docs/prd/specific-features/3circles/prd.md` (PRD 1, Sections 1, 3)
- Acceptance criteria: TC-CS-001 through TC-CS-025, TC-CI-001 through TC-CI-024

**Outputs:**
- `api/internal/domain/threecircles/set.go` -- CircleSet struct, CircleSetStatus enum, RecoveryArea enum, FrameworkPreference enum
- `api/internal/domain/threecircles/item.go` -- CircleItem struct, CircleType enum, CircleItemSource enum, item validation
- `api/internal/domain/threecircles/commit.go` -- commit logic (zero-inner check, status transition, version creation)
- `api/internal/domain/threecircles/version.go` -- version snapshot creation, changeType tracking, changedItems
- `api/internal/domain/threecircles/*_test.go` -- unit tests with 100% coverage on commit validation and version creation

**Tasks:**
1. Write failing unit tests for all circle set and item operations (RED)
2. Implement CircleSet struct:
   - Name (max 100), RecoveryArea (enum), FrameworkPreference (optional enum), Status (draft/active/archived)
   - Inner/middle/outer circle arrays with max limits (20/50/50)
   - VersionNumber (auto-increment on circle changes)
   - Immutable createdAt (FR2.7)
3. Implement CircleItem struct:
   - BehaviorName (1-200 chars), Notes (max 1000), SpecificityDetail (max 500), Category (max 50)
   - Source enum: user, template, starterPack
   - Flags: uncertain boolean
   - Auto-generated itemId with pattern `3c_item_{alphanumeric}`
4. Implement commit logic:
   - Validate inner circle has >= 1 item
   - Transition status from draft to active
   - Set committedAt timestamp
   - Create version snapshot
5. Implement version snapshot creation:
   - Full snapshot of all three circles
   - changeType enum: itemAdded, itemUpdated, itemDeleted, itemMoved, setCommitted, setRestored, starterPackApplied, bulkReplace, reviewChange
   - changedItems array tracking affected item IDs
   - Inner/middle/outer count at snapshot time
6. Implement move logic:
   - Validate targetCircle is different from current
   - Check target circle capacity limits
   - Create version snapshot with changeType=itemMoved
7. All tests GREEN

**Verification Gate:** `make test-unit` passes. Coverage >= 90% on `api/internal/domain/threecircles/`. 100% on commit validation, version creation, item limits, and move logic.

**Dependencies:** None (can run in parallel with Agent 1)

---

### Agent 3: Domain Logic -- Guardrails & Validation

**Scope:** All guardrail advisory logic, trauma-informed language validation, and input sanitization.

**Inputs:**
- `docs/prd/specific-features/3circles/prd.md` (PRD 1 Section 5, PRD 3 Section 5)
- Acceptance criteria: TC-GR-001 through TC-GR-014

**Outputs:**
- `api/internal/domain/threecircles/guardrails.go` -- guardrail detection engine
- `api/internal/domain/threecircles/language.go` -- trauma-informed language validation
- `api/internal/domain/threecircles/*_test.go` -- unit tests with 100% coverage on all guardrail rules

**Tasks:**
1. Write failing unit tests for all guardrail rules (RED)
2. Implement specificity nudge:
   - Detect items with text under 5 words
   - Detect vague keywords: "be," "stop," "better," "good," "bad," "right"
   - Return advisory in meta.guardrails array (non-blocking)
3. Implement overload nudge:
   - Soft threshold at 8 inner circle items (advisory)
   - Hard limit at 20 inner circle items (422)
4. Implement middle circle depth nudge:
   - Detect middle circle with fewer than 3 items at commit time
5. Implement isolation nudge:
   - Detect commit without prior sponsor share
6. Implement inner circle significance advisories:
   - Addition advisory: "Adding to inner circle is a significant commitment"
   - Removal advisory: "Removing from inner circle means you're no longer committing to avoid this"
7. Implement pacing advisory:
   - Track same-item edit count (advisory at 3+)
8. Implement time check advisory:
   - Track onboarding flow duration (advisory at 15+ minutes)
9. Implement trauma-informed language validation:
   - Reject advisory text containing "failure," "clean," "dirty," "weakness," "addict," "should," "must"
   - Applied to all guardrail messages and system copy
10. All tests GREEN

**Verification Gate:** `make test-unit` passes. 100% coverage on all guardrail rules. All guardrail messages pass trauma-informed language check.

**Dependencies:** Agent 2 (needs CircleSet, CircleItem types)

---

### Agent 4: Domain Logic -- Onboarding Flow

**Scope:** Onboarding flow state machine, three entry modes (guided/starterPack/express), emotional check-in, and flow completion.

**Inputs:**
- `docs/prd/specific-features/3circles/prd.md` (PRD 3, Sections 1-4)
- Acceptance criteria: TC-OB-001 through TC-OB-025

**Outputs:**
- `api/internal/domain/threecircles/onboarding.go` -- OnboardingFlow struct, mode enum, step enum, state machine
- `api/internal/domain/threecircles/onboarding_complete.go` -- flow completion, circle set creation, sponsor share generation
- `api/internal/domain/threecircles/*_test.go` -- unit tests

**Tasks:**
1. Write failing unit tests (RED)
2. Implement OnboardingFlow struct:
   - FlowId (pattern `3c_flow_{alphanumeric}`)
   - Mode: guided, starterPack, express
   - CurrentStep: recoveryArea, framework, innerCircle, outerCircle, middleCircle, review
   - EmotionalCheckinScore: 1-5 (optional)
   - Progress: step-specific draft data
3. Implement guided mode step sequence enforcement:
   - Required order: recoveryArea -> framework -> innerCircle -> outerCircle -> middleCircle -> review
4. Implement express mode:
   - Flexible step ordering
   - Minimal validation between steps
5. Implement starterPack mode:
   - Apply selected pack, enter review/edit state
6. Implement mode switching:
   - Preserve all existing progress when switching modes
   - Merge starter pack into existing items when switching to starterPack mode
7. Implement completion logic:
   - commitNow: create active circle set
   - draft: create draft circle set
   - draft + generateSponsorShare: create draft + share link/code
   - draftNoShare: create draft, no share
   - Validate inner circle >= 1 for commitNow
8. Implement one-active-flow-per-area constraint
9. All tests GREEN

**Verification Gate:** `make test-unit` passes. 100% coverage on mode switching, step validation, completion logic, and one-active-flow constraint.

**Dependencies:** Agent 2 (needs CircleSet creation), Agent 3 (needs guardrails for flow advisories)

---

### Agent 5: Domain Logic -- Templates & Starter Packs

**Scope:** Template retrieval, starter pack retrieval, and pack application logic (merge/replace strategies).

**Inputs:**
- `docs/prd/specific-features/3circles/prd.md` (PRD 1 Section 2, PRD 3 Section 2)
- Acceptance criteria: TC-TP-001 through TC-TP-012, TC-SP-001 through TC-SP-019

**Outputs:**
- `api/internal/domain/threecircles/template.go` -- Template struct, retrieval logic, filtering
- `api/internal/domain/threecircles/starterpack.go` -- StarterPack struct, application logic, merge/replace strategies
- `api/internal/domain/threecircles/*_test.go` -- unit tests

**Tasks:**
1. Write failing unit tests (RED)
2. Implement Template struct:
   - TemplateId, RecoveryArea, Circle, BehaviorName, Rationale, SpecificityGuidance, Category
   - FrameworkVariant (null = universal)
   - Filtering: by recoveryArea, circle, framework
3. Implement StarterPack struct:
   - PackId, Name, Description, RecoveryArea, Variant (secular/faith-based/lgbtq-affirming)
   - InnerCircle (3-5), MiddleCircle (6-10), OuterCircle (SEEDS-based)
   - ClinicalReviewer, CommunityReviewer
4. Implement pack application logic:
   - Replace strategy: clear existing items, populate with pack items
   - Merge strategy (default): add pack items, skip duplicates (matching behaviorName)
   - All applied items tagged with source=starterPack
   - Creates version snapshot with changeType=starterPackApplied
   - Set remains in draft status after application
5. Implement pack validation:
   - Inner circle: 3-5 items required per pack
   - Middle circle: 6-10 items, must span behavioral, emotional, environmental, lifestyle categories
   - Outer circle: SEEDS categories represented
   - Both reviewers required
6. All tests GREEN

**Verification Gate:** `make test-unit` passes. 100% coverage on merge/replace logic, duplicate detection, source tagging, and pack validation.

**Dependencies:** Agent 2 (needs CircleSet, CircleItem types)

---

### Agent 6: Domain Logic -- Version History

**Scope:** Version retrieval, comparison, and restore logic.

**Inputs:**
- `docs/prd/specific-features/3circles/prd.md` (PRD 1 Section 3)
- Acceptance criteria: TC-VH-001 through TC-VH-015

**Outputs:**
- `api/internal/domain/threecircles/version_history.go` -- version list, get, compare, restore
- `api/internal/domain/threecircles/*_test.go` -- unit tests

**Tasks:**
1. Write failing unit tests (RED)
2. Implement version list retrieval:
   - Reverse chronological order
   - Summary fields: versionNumber, changedAt, changeNote, innerCount, middleCount, outerCount
3. Implement version detail retrieval:
   - Full snapshot of all three circles at that version
   - Support vN format and "latest" keyword
4. Implement restore logic:
   - Load target version snapshot
   - Replace current circles with snapshot data
   - Create new version (does NOT rewind history)
   - changeType=setRestored
   - Optional changeNote
   - Draft sets become active on restore
5. All tests GREEN

**Verification Gate:** `make test-unit` passes. 100% coverage on restore logic (new version creation, draft-to-active transition).

**Dependencies:** Agent 2 (needs version snapshot types)

---

### Agent 7: Domain Logic -- Pattern Analysis

**Scope:** Timeline visualization, insight generation, drift detection, and summary computation.

**Inputs:**
- `docs/prd/specific-features/3circles/prd.md` (PRD 2)
- Acceptance criteria: TC-PV-001 through TC-PV-017, TC-DA-001 through TC-DA-012, TC-IN-001 through TC-IN-018

**Outputs:**
- `api/internal/domain/threecircles/timeline.go` -- timeline query, period handling, summary stats
- `api/internal/domain/threecircles/insight.go` -- insight generation engine, correlation detection
- `api/internal/domain/threecircles/drift.go` -- drift alert detection (3/7 threshold), episode tracking
- `api/internal/domain/threecircles/summary.go` -- weekly/monthly summary, framing message generation
- `api/internal/domain/threecircles/*_test.go` -- unit tests

**Tasks:**
1. Write failing unit tests (RED)
2. Implement timeline query:
   - Support periods: 7d, 30d, 90d, 1y, all
   - Support custom startDate/endDate
   - Return entries with date, circle, checkinDetails
   - Compute summary: outerDays, middleDays, innerDays, noCheckinDays, currentConsecutiveOuterDays
3. Implement drift detection:
   - Sliding 7-day window
   - Trigger at 3+ middle circle days
   - One alert per drift episode (track windowStart/windowEnd to prevent duplicates)
   - Gentle, non-punitive message generation
4. Implement insight generation:
   - Minimum 14 days of data required
   - Day-of-week pattern: cluster analysis on middle/inner circle days
   - Trigger correlation: mood + SEEDS data correlated with circle movement
   - Protective correlation: positive behaviors correlated with outer circle days
   - Sleep correlation: sleep deprivation preceding urge spikes
   - All insights framed as observations with constructive action suggestions
   - Shaming correlation filter: reject insights referencing personal names or relationships
   - Deterministic and reproducible calculations
5. Implement summary computation:
   - Weekly and monthly periods
   - Circle distribution counts
   - Top 3 insights
   - Mood trend: improving/stable/declining/insufficient-data
   - Framing message: descriptive language, no percentages or grading
6. All tests GREEN

**Verification Gate:** `make test-unit` passes. 100% coverage on drift threshold, insight minimum data, shaming filter, framing message validation, and deterministic correlation logic.

**Dependencies:** None for types (can define own timeline/insight structs); reads from Agent 2 types for set references

---

### Agent 8: Repository Layer

**Scope:** MongoDB data access implementing all 32 access patterns for 11 collections.

**Inputs:**
- `docs/prd/specific-features/3circles/specs/mongodb-schema.md` (all sections)
- Domain types from Agents 2-7

**Outputs:**
- `api/internal/domain/threecircles/repository.go` -- repository interface definitions
- `api/internal/repository/mongodb/threecircles_set_repository.go` -- circle sets
- `api/internal/repository/mongodb/threecircles_version_repository.go` -- versions
- `api/internal/repository/mongodb/threecircles_template_repository.go` -- templates
- `api/internal/repository/mongodb/threecircles_starterpack_repository.go` -- starter packs
- `api/internal/repository/mongodb/threecircles_onboarding_repository.go` -- onboarding flows
- `api/internal/repository/mongodb/threecircles_share_repository.go` -- shares + comments
- `api/internal/repository/mongodb/threecircles_pattern_repository.go` -- timeline + insights + drift alerts
- `api/internal/repository/mongodb/threecircles_review_repository.go` -- quarterly reviews
- `api/test/integration/threecircles/threecircles_repository_test.go` -- integration tests

**Tasks:**
1. Define repository interfaces:
   - `SetRepository` -- CRUD sets, list with filters, commit, soft-delete
   - `VersionRepository` -- create version, list versions, get version, get latest
   - `TemplateRepository` -- list by recoveryArea+circle+framework, get by ID
   - `StarterPackRepository` -- list by recoveryArea+variant, get by ID
   - `OnboardingRepository` -- create flow, update flow, complete flow, find active flow
   - `ShareRepository` -- create share, get by code, deactivate, create comment, list comments
   - `PatternRepository` -- create timeline entry, query timeline, count by circle, create/list/dismiss insights, create/list/dismiss drift alerts
   - `ReviewRepository` -- create review, update review, complete review, list reviews
2. Implement MongoDB queries matching access patterns AP-TC-01 through AP-TC-32
3. Implement cursor-based pagination using `createdAt` + `_id` compound cursor
4. Create all 45 indexes as specified in schema
5. Implement calendar activity dual-write on:
   - Circle set commit (activityType: THREE_CIRCLES, action: committed)
   - Quarterly review complete (activityType: THREE_CIRCLES, action: reviewCompleted)
6. Implement TTL index on `circlesShares.expiresAt` for auto-expiry
7. Implement TTL index on `circlesInsights.expiresAt` for auto-cleanup
8. Write integration tests against local MongoDB

**Verification Gate:** `make test-integration` passes for all three-circles repository tests. All 32 access patterns verified. Calendar dual-write verified. TTL indexes verified.

**Dependencies:** Agents 2-7 (needs all domain types)

---

### Agent 9: Cache + Handlers + Events

**Scope:** Valkey cache-aside pattern, HTTP handler layer for all 36+ endpoints, feature flag gating, and SNS/SQS event publishing.

**Inputs:**
- `docs/prd/specific-features/3circles/specs/openapi.yaml`
- Domain logic from Agents 2-7
- Repository from Agent 8

**Outputs:**
- `api/internal/cache/threecircles_cache.go` -- Valkey cache wrapper
- `api/internal/handler/threecircles_set_handler.go` -- set + item endpoints
- `api/internal/handler/threecircles_version_handler.go` -- version endpoints
- `api/internal/handler/threecircles_template_handler.go` -- template + starter pack endpoints
- `api/internal/handler/threecircles_onboarding_handler.go` -- onboarding endpoints
- `api/internal/handler/threecircles_share_handler.go` -- sponsor review endpoints (includes public)
- `api/internal/handler/threecircles_pattern_handler.go` -- timeline, insights, drift, summary endpoints
- `api/internal/handler/threecircles_review_handler.go` -- quarterly review endpoints
- `api/internal/events/threecircles_events.go` -- event type definitions + SNS publisher
- `api/internal/handler/*_test.go` -- handler unit tests

**Tasks:**
1. Implement Valkey cache-aside for all 10 cache keys defined in schema:
   - Set list, set detail, templates, starter packs, onboarding, timeline, summary, insights, drift, unread comments
   - Cache invalidation on all mutations
   - Graceful degradation when Valkey unavailable
2. Implement feature flag check on all handlers: `feature.3circles` disabled -> 404 (fail closed)
3. Implement handlers for all endpoint groups:
   - Circle Sets: CRUD + commit
   - Circle Items: add, update, delete, move
   - Version History: list, get, restore
   - Templates: list, get
   - Starter Packs: list, get, apply
   - Onboarding: start, update, complete
   - Sponsor Review: share, public view, public comment, owner comments
   - Pattern: timeline, insights, summary, drift alerts, dismiss
   - Quarterly Review: list, start, update, complete
4. Implement public endpoints (no auth):
   - `GET /share/{shareCode}` -- public circle view
   - `POST /share/{shareCode}/comments` -- public sponsor comment
5. Implement meta.guardrails inclusion on relevant responses (delegate to Agent 3's guardrail engine)
6. Implement response envelope format (`{ data, links, meta }`) and error format (`{ errors: [...] }`)
7. Implement error codes in `rr:0x000B{4 hex}` range
8. Set Location header on 201 responses
9. Implement correlation ID on all error responses
10. Implement JSON Merge Patch (RFC 7396) for PATCH endpoints
11. Define event types:
    - `threecircles.set.committed` -- setId, userId, innerCount, middleCount, outerCount
    - `threecircles.set.edited` -- setId, userId, changeType
    - `threecircles.share.created` -- setId, userId, shareCode, expiresAt
    - `threecircles.comment.added` -- setId, shareCode, commentId
    - `threecircles.drift.detected` -- setId, userId, middleCircleDays, windowStart, windowEnd
    - `threecircles.review.completed` -- setId, userId, changesCount, nextReviewDue
    - `threecircles.starterpack.applied` -- setId, userId, packId
    - `threecircles.onboarding.completed` -- userId, mode, recoveryArea, commitOption
12. Implement SNS publisher for each event type
13. Write handler unit tests with mocked dependencies

**Verification Gate:** `make contract-test` passes (all RED tests from Agent 1 now GREEN). Handler unit tests pass. Feature flag gating verified. Cache invalidation verified. Events fire correctly.

**Dependencies:** Agents 2-8 (needs all layers)

---

### Agent 10: Integration & E2E Tests

**Scope:** Full-stack integration tests against local infrastructure. E2E flows covering all 3 personas and lifecycle scenarios.

**Inputs:**
- `docs/prd/specific-features/3circles/specs/test-specifications.md` (all sections)
- All implementation from Agents 2-9

**Outputs:**
- `api/test/integration/threecircles/threecircles_full_test.go` -- full-stack integration tests
- `api/test/e2e/threecircles/threecircles_e2e_test.go` -- E2E tests for staging

**Tasks:**
1. Write full-stack integration tests using `make local-up`:
   - Circle set lifecycle: create -> add items -> commit -> edit -> version history -> restore
   - Item operations: add -> update -> move -> delete (with version verification each step)
   - Starter pack lifecycle: list packs -> get detail -> apply merge -> verify items tagged -> commit
   - Onboarding lifecycle: start guided -> progress through steps -> switch mode -> complete -> verify set created
   - Sponsor review: generate share -> public view -> public comment -> owner read comments -> mark read
   - Pattern visualization: ingest 30 days of timeline data -> query timeline -> verify summary stats
   - Drift detection: ingest 3 middle circle days in 7-day window -> verify alert generated -> dismiss
   - Insight generation: ingest 14+ days of data with patterns -> verify insights generated
   - Quarterly review: start -> progress -> add item during review -> complete -> verify nextReviewDue
   - Calendar dual-write: verify on commit and review completion
   - Cache behavior: verify cache hit/miss/invalidation for set detail, templates, timeline
2. Write E2E persona flows:
   - Rachel (Day 5, starter pack): full onboarding through starter pack mode with edits and sponsor share
   - James (2yr SAA, express): fast onboarding with manual entry, immediate commit
   - Maria (6mo SLAA+codep, guided, multi-set): two independent guided flows
3. Write E2E lifecycle tests:
   - Full edit/version/share/comment lifecycle
   - Pattern visualization with 30 days of data
   - Quarterly review with changes
4. Verify feature flag gating: disable flag -> all endpoints 404
5. Verify offline resilience patterns

**Verification Gate:** `make test-integration` and `make test-e2e` pass. All 3 persona journeys verified. All 242 acceptance criteria covered. Calendar dual-write verified.

**Dependencies:** Agents 2-9 (needs complete implementation)

---

### Agent 11: iOS Mobile Client -- API & Models

**Scope:** iOS API client, SwiftData models, offline cache, and sync engine for Three Circles.

**Inputs:**
- `docs/prd/specific-features/3circles/specs/openapi.yaml`
- `docs/prd/specific-features/3circles/prd.md`

**Outputs:**
- `ios/RegalRecovery/RegalRecovery/Models/ThreeCircles/` -- SwiftData models
- `ios/RegalRecovery/RegalRecovery/Services/ThreeCirclesAPIClient.swift` -- hand-written API client
- `ios/RegalRecovery/RegalRecovery/Services/ThreeCirclesSyncEngine.swift` -- offline sync
- `ios/RegalRecovery/RegalRecovery/ViewModels/ThreeCircles/` -- MVVM view models
- `ios/RegalRecovery/RegalRecovery/Tests/Unit/ThreeCircles/` -- Swift Testing unit tests

**Tasks:**
1. Hand-write Swift Codable structs for all types:
   - `CircleSet`, `CircleItem`, `CircleSetVersion`, `Template`, `StarterPack`, `StarterPackItem`
   - `OnboardingFlow`, `SponsorComment`, `TimelineEntry`, `PatternInsight`, `DriftAlert`, `Summary`, `Review`
   - All request/response envelopes matching OpenAPI schemas
2. Hand-write URLSession API client for all 36+ endpoints:
   - Circle set CRUD + commit, item CRUD + move
   - Version history: list, get, restore
   - Templates + starter packs: list, get, apply
   - Onboarding: start, update, complete
   - Sponsor review: share, view (public), comment (public), get comments
   - Pattern: timeline, insights, summary, drift alerts, dismiss
   - Reviews: list, start, update, complete
3. Implement SwiftData models for offline cache:
   - Cache active circle sets with all items for offline viewing and editing
   - Cache templates and starter packs for offline onboarding
   - Cache onboarding flow progress for save-and-resume
   - Queue mutations (item add/update/delete/move, set commit) for sync
   - Cache timeline data for offline pattern viewing
4. Implement SyncEngine:
   - Queue offline mutations with timestamps
   - Sync on NetworkMonitor connectivity restored
   - Most-conservative merge for circle items (stricter boundary wins)
   - LWW for set metadata and onboarding progress
5. Implement view models:
   - `CircleSetListViewModel` -- manage set list, filtering, switching
   - `CircleSetDetailViewModel` -- item management, version history, guardrail display
   - `OnboardingViewModel` -- flow state machine, mode switching, step navigation
   - `TemplateViewModel` -- template browsing, selection, application
   - `StarterPackViewModel` -- pack selection, preview, apply
   - `SponsorReviewViewModel` -- share generation, comment viewing
   - `PatternViewModel` -- timeline, insights, drift alerts, summary
   - `ReviewViewModel` -- quarterly review flow
6. Write Swift Testing unit tests:
   - API client serialization/deserialization tests
   - ViewModel state management tests
   - Offline queue tests
   - Sync conflict resolution tests

**Verification Gate:** All Swift Testing tests pass. API client matches all 36+ endpoints from OpenAPI spec. Offline cache and sync verified.

**Dependencies:** Agent 1 (needs OpenAPI spec for API client). Can run in parallel with Agents 2-9.

---

### Agent 12: iOS Mobile Client -- UI & Navigation

**Scope:** SwiftUI views for the Three Circles builder, pattern visualization, and all navigation entry points.

**Inputs:**
- `docs/prd/specific-features/3circles/prd.md` (PRD 1, PRD 2, PRD 3 -- UX requirements)
- View models from Agent 11

**Outputs:**
- `ios/RegalRecovery/RegalRecovery/Views/Tools/ThreeCircles/` -- all SwiftUI views
- `ios/RegalRecovery/RegalRecovery/Views/Tools/ThreeCircles/Builder/` -- onboarding builder views
- `ios/RegalRecovery/RegalRecovery/Views/Tools/ThreeCircles/Pattern/` -- visualization views
- `ios/RegalRecovery/RegalRecovery/Views/Tools/ThreeCircles/Review/` -- quarterly review views

**Tasks:**
1. Implement circle visualization:
   - Concentric rings display (red inner, yellow middle, green outer)
   - Tap-to-expand each circle's items
   - Item detail view with edit/delete/move actions
2. Implement onboarding builder:
   - Pre-builder emotional check-in (5-point scale, skippable)
   - Mode selection screen (guided/starterPack/express with honest descriptions)
   - Recovery area selection
   - Framework preference (skippable)
   - Circle building screens (inner -> outer -> middle for guided mode)
   - Template suggestion display (checkboxes, collapsible by category)
   - Starter pack selection and review/edit screen
   - Progress indicator (which circle you're on)
   - Pause points between circles
   - Reflection prompts (optional, between steps)
   - Review and commit screen with three options
3. Implement guardrail UI:
   - Inline specificity nudge (dismissible, non-blocking)
   - Overload nudge for inner circle > 8 items
   - Middle circle depth nudge at commit time
   - Isolation nudge at commit time
   - Inner circle add/remove confirmation dialogs
4. Implement sponsor review UI:
   - Share generation with expiry options
   - Share link/code display and copy
   - Comment viewing with unread badge
5. Implement pattern visualization:
   - Horizontal timeline with color-coded bands (red/yellow/green/gray)
   - Zoom controls (7d/30d/90d/1y/all)
   - Tap-day to reveal check-in details
   - Summary stats above timeline
   - Mood and urge overlay (toggle on/off)
   - Insight cards with action suggestions
   - Drift alert banner (gentle, dismissible)
   - Weekly/monthly summary view (shareable)
6. Implement quarterly review:
   - Review prompt when nextReviewDue is past
   - Step-through review with reflection prompts per circle
   - Inline editing during review
   - Summary and completion
7. Implement accessibility:
   - VoiceOver labels for all interactive elements
   - Min 44x44pt touch targets
   - Dynamic Type support
   - High Contrast mode
   - Color-blind safe palette for timeline (not just red/yellow/green)
   - Reduced Motion support
8. Implement crisis handling:
   - "I need support" button always visible in builder
   - Crisis resources, grounding exercise, call contact, exit to home
   - Save draft on crisis exit
9. Implement save and resume:
   - Auto-save on every builder screen
   - Resume banner on home screen for incomplete flows
   - Draft vs. committed visual distinction
10. Implement tone and language:
    - All copy reviewed for compassionate, person-first language
    - No "failure," "clean/dirty," "weakness," "addict" in any UI text
    - Gender-neutral default language

**Verification Gate:** VoiceOver audit complete. Dynamic Type tested at all sizes. All guardrail nudges display correctly. Builder completes in all 3 modes. Pattern visualization renders with test data. Crisis exit saves draft.

**Dependencies:** Agent 11 (needs view models and API client)

---

## Execution Timeline

```
Week 1:
  [Agent 1]  Contract Tests (RED)           ████████░░░░░░░░░░░░░░░░░░░░░░░░
  [Agent 2]  Circle Set & Item Logic        ████████████░░░░░░░░░░░░░░░░░░░░
  [Agent 5]  Templates & Starter Packs      ████████████░░░░░░░░░░░░░░░░░░░░
  [Agent 7]  Pattern Analysis Logic         ████████████░░░░░░░░░░░░░░░░░░░░
  [Agent 11] iOS Client (models + API)      ████████░░░░░░░░░░░░░░░░░░░░░░░░

Week 2:
  [Agent 3]  Guardrails & Validation        ░░░░░░░░████████████░░░░░░░░░░░░
  [Agent 4]  Onboarding Flow                ░░░░░░░░████████████░░░░░░░░░░░░
  [Agent 6]  Version History                ░░░░░░░░████████████░░░░░░░░░░░░
  [Agent 11] iOS Client (sync + cache)      ░░░░░░░░████████░░░░░░░░░░░░░░░░

Week 3:
  [Agent 8]  Repository Layer               ░░░░░░░░░░░░░░░░████████████░░░░
  [Agent 11] iOS Client (view models)       ░░░░░░░░░░░░░░░░████████░░░░░░░░
  [Agent 12] iOS Client (builder UI)        ░░░░░░░░░░░░░░░░████████████░░░░

Week 4:
  [Agent 9]  Cache + Handlers + Events      ░░░░░░░░░░░░░░░░░░░░░░░░████████
  [Agent 12] iOS Client (pattern + review)  ░░░░░░░░░░░░░░░░░░░░░░░░████████

Week 5:
  [Agent 10] Integration + E2E Tests        ░░░░░░░░░░░░░░░░░░░░░░░░░░░░████
  [Agent 12] iOS Client (a11y + polish)     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░████

Gate: All tests GREEN -> Enable feature flag for staging
```

---

## Dependency Graph

```
Agent 1 (Contract Tests RED) ----+----------------------------+
  |                              |                            |
  |                         Agent 11                          |
  |                         (iOS models + API)                |
  |                              |                            |
Agent 2 (Circle Set +            |                            |
         Item Logic) ------------+---+---+                    |
  |         |        |           |   |   |                    |
  |         |        |           |   |   |                    |
  v         v        v           |   |   |                    |
Agent 3   Agent 5  Agent 7       |   |   |                    |
(Guard-   (Templ + (Pattern      |   |   |                    |
 rails)   Starter)  Analysis)    |   |   |                    |
  |         |        |           |   |   |                    |
  +----+----+        |           |   |   |                    |
       |             |           |   |   |                    |
       v             |           |   |   |                    |
Agent 4 (Onboarding) |           |   |   |                    |
  |                  |           |   |   |                    |
  +------+-----------+           |   |   |                    |
         |                       |   |   |                    |
         v                       |   |   |                    |
Agent 6 (Version History)        |   |   |                    |
         |                       |   |   |                    |
         +------+----------------+   |   |                    |
                |                    |   |                    |
                v                    |   |                    |
Agent 8 (Repository Layer)          |   |                    |
                |                    |   |                    |
                v                    |   |                    |
Agent 9 (Cache + Handlers + Events) |   |                    |
  |                   |             |   |                    |
  |                   |   +---------+   |                    |
  |                   |   |             |                    |
  v                   v   v             v                    |
Agent 10            Agent 12          Agent 11               |
(Integration +      (iOS UI +         (iOS view models)      |
 E2E Tests)          Navigation)                             |
                        |                                    |
                        +<----(verifies Agent 1's tests)-----+
```

---

## Verification Gates (Quality Checkpoints)

| Gate | Trigger | Criteria | Blocks |
|------|---------|----------|--------|
| **G1: Spec Valid** | After Agent 1 | `redocly lint openapi.yaml` passes with 0 errors. All contract tests RED. | All agents |
| **G2: Core Domain** | After Agent 2 | Unit tests pass. 100% coverage on commit validation, version creation, item limits, move logic. | Agents 3, 4, 5, 6 |
| **G3: Guardrails** | After Agent 3 | Unit tests pass. 100% coverage on all guardrail rules. All messages pass trauma-informed language check. | Agent 4 |
| **G4: Onboarding** | After Agent 4 | Unit tests pass. 100% coverage on mode switching, step validation, completion logic, one-active-flow constraint. | Agent 8 |
| **G5: Templates** | After Agent 5 | Unit tests pass. 100% coverage on merge/replace logic, duplicate detection, source tagging, pack validation. | Agent 8 |
| **G6: Version History** | After Agent 6 | Unit tests pass. 100% coverage on restore logic. | Agent 8 |
| **G7: Pattern Analysis** | After Agent 7 | Unit tests pass. 100% coverage on drift threshold, insight min data, shaming filter, deterministic calculations. | Agent 8 |
| **G8: Repository** | After Agent 8 | Integration tests pass. All 32 access patterns verified. Calendar dual-write verified. TTL indexes verified. | Agent 9 |
| **G9: Handlers GREEN** | After Agent 9 | All contract tests from Agent 1 now GREEN. Handler unit tests pass. Feature flag gating verified. Cache invalidation verified. | Agent 10 |
| **G10: Full Integration** | After Agent 10 | `make test-integration` + `make test-e2e` pass. All 3 persona journeys verified. All 242 ACs covered. | Feature flag enable |
| **G11: iOS API Client** | After Agent 11 | Swift Testing tests pass. API client matches all 36+ endpoints. Offline cache and sync verified. | Agent 12 |
| **G12: iOS UI** | After Agent 12 | VoiceOver audit complete. Dynamic Type tested. Builder completes in all modes. Pattern visualization renders. Crisis exit saves draft. | App release |

---

## Feature Flag Rollout Plan

| Stage | `feature.3circles` Config | Audience |
|-------|--------------------------|----------|
| Development | Enabled for `tenant: DEV` only | Dev team |
| Staging QA | Enabled for all tenants, staging only | QA team + recovery advisory review |
| Content Review | Enabled, staging only, full template + starter pack content loaded | CSAT + pastoral advisor content review |
| Canary | Enabled, rolloutPercentage: 5% | 5% of production users (established recovery, Day 30+) |
| Early Access | rolloutPercentage: 15% | Include new users |
| Gradual | rolloutPercentage: 25% -> 50% -> 75% -> 100% | Progressive rollout over 3 weeks |
| GA | Enabled, rolloutPercentage: 100% | All users |

---

## Risk Mitigation

| # | Risk | Severity | Mitigation |
|---|------|----------|-----------|
| 1 | **Blank page abandonment** -- users who start the builder but don't finish due to overwhelm, shame, or uncertainty | Critical | Three entry modes (guided/starter pack/express). Starter pack eliminates blank page. Save-and-resume preserves progress. Emotional check-in routes overwhelmed users to appropriate mode. Pacing advisories suggest breaks. Crisis exit always available. |
| 2 | **Vague definitions enabling rationalization** -- inner circle items too loose to be enforceable ("be a better person") | High | Specificity guardrail detects items under 5 words and vague keywords. Advisory prompts specificity without blocking. Templates model specific language. Sponsor review catches vagueness in review flow. |
| 3 | **Excessive rigidity causing shame** -- inner circle too strict, setting up inevitable "failure" and shame spiral | High | Overload nudge at 8+ inner circle items. Soft guidance to move items to middle circle. Middle circle framing emphasizes "signals, not failures." No "streak reset" language anywhere in the system. Recovery total alongside any outer-circle consecutive days count. |
| 4 | **Template quality** -- templates that are culturally insensitive, clinically harmful, or theologically unsound | High | Dual review pipeline: CSAT reviews clinical appropriateness + recovery community member reviews relevance. Starter packs have even higher bar (both clinicalReviewer and communityReviewer required). Templates updated independently of app releases. Faith-based, secular, and LGBTQ+-affirming variants reviewed by appropriate communities. |
| 5 | **Sponsor review privacy leak** -- circle content shared without user intent or control | Medium | Explicit opt-in share generation required. Share links expire. Shares are revocable. No auth-less access to user identity (only circle items visible). Comments from sponsors go through share code only. No notification without user action. |
| 6 | **Drift alert fatigue** -- too many alerts desensitizing the user | Medium | One alert per drift episode (not daily). Fully dismissible. Gentle, non-punitive tone. Action-oriented suggestions. No automatic escalation to sponsors. |
| 7 | **Pattern visualization as judgment** -- users interpreting data as a "grade" on their recovery | Medium | Descriptive framing only (no percentages). "X outer circle days, Y middle circle days, Z inner circle days. Each one is data for understanding your recovery." Consecutive outer days shown as context, not primary streak. Slips shown in context (days before and after). Recovery total always visible. |
| 8 | **Insight generation: spurious correlations** -- insights based on insufficient data leading to incorrect conclusions | Medium | 14-day minimum data threshold. Confidence levels (low/medium/high). All insights framed as observations, not predictions. Shaming correlation filter. Users can dismiss unhelpful insights. Deterministic and reproducible calculations. |
| 9 | **Offline sync conflicts** -- edits on two devices creating conflicting circle states | Medium | Most-conservative merge for circle items (stricter boundary wins). LWW for metadata. Version history preserved on both sides. Conflict resolution tested in E2E suite. |
| 10 | **Content localization** -- templates and starter packs in English only limiting global reach | Low | Architecture supports localized templates via language tag (future). English-first for Wave 1. Content structure separates text from structure for easy translation. |

---

## PR Decomposition

Target < 400 lines per PR. Recommended stacking:

| PR | Agent | Content | Lines (est.) |
|----|-------|---------|-------------|
| PR-1 | 1 | Contract tests (RED) -- all 36+ endpoints | ~400 |
| PR-2 | 2 | Domain types: CircleSet, CircleItem, enums, validation | ~350 |
| PR-3 | 2 | Commit logic, version snapshot creation, item move | ~350 |
| PR-4 | 3 | Guardrail detection engine + trauma-informed language validation | ~300 |
| PR-5 | 4 | Onboarding flow state machine + mode switching | ~400 |
| PR-6 | 4 | Onboarding completion + circle set creation + sponsor share | ~300 |
| PR-7 | 5 | Template struct + filtering + starter pack struct | ~300 |
| PR-8 | 5 | Starter pack application logic (merge/replace) + source tagging | ~350 |
| PR-9 | 6 | Version history: list, get, compare, restore | ~300 |
| PR-10 | 7 | Timeline query + summary computation | ~350 |
| PR-11 | 7 | Drift detection + insight generation engine | ~400 |
| PR-12 | 8 | Repository interfaces + set/version/template/starter pack MongoDB impl | ~400 |
| PR-13 | 8 | Repository: onboarding, share, pattern, review MongoDB impl + integration tests | ~400 |
| PR-14 | 9 | Cache layer (all keys + invalidation) | ~300 |
| PR-15 | 9 | Handlers: sets + items + versions + feature flag gating | ~400 |
| PR-16 | 9 | Handlers: templates, starter packs, onboarding | ~400 |
| PR-17 | 9 | Handlers: sponsor review (public + private) + guardrails in meta | ~350 |
| PR-18 | 9 | Handlers: pattern, drift, insights, summary, reviews + events | ~400 |
| PR-19 | 10 | Integration tests (full-stack flows) | ~400 |
| PR-20 | 10 | E2E tests (3 persona journeys + lifecycle) | ~400 |
| PR-21 | 11 | iOS: SwiftData models + API client (all 36+ endpoints) | ~400 |
| PR-22 | 11 | iOS: sync engine + offline cache + view models | ~400 |
| PR-23 | 12 | iOS: onboarding builder UI (3 modes) | ~400 |
| PR-24 | 12 | iOS: circle visualization + item management + version history | ~400 |
| PR-25 | 12 | iOS: pattern visualization + drift alerts + insights | ~400 |
| PR-26 | 12 | iOS: sponsor review UI + quarterly review + accessibility | ~400 |
