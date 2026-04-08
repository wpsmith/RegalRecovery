# Affirmations Experience -- Multi-Agent Implementation Plan

**Version:** 1.0.0
**Date:** 2026-04-08
**Status:** Draft
**Wave:** 2 (P1 Features & Activities)
**Feature Flag:** `activity.affirmations`

---

## Overview

This plan follows the project's spec-driven, test-first development methodology. Each agent works on a defined boundary with explicit input specs and output artifacts. Dependencies between agents are managed through verification gates -- no downstream agent starts until its upstream dependency passes.

The Affirmations Experience is the most clinically complex activity in the app. It combines a progressive level engine (4 levels gated by sobriety duration), session composition (morning/evening/SOS), custom affirmation creation, own-voice audio recording, and multiple clinical safeguards (backfire prevention, post-relapse locking, worsening mood detection, crisis bypass). The implementation is decomposed into 10 agents to keep each agent's scope narrow and testable.

**Specs consumed:**
- `docs/prd/specific-features/Affirmations/affirmations.md` -- Feature requirements document (clinical foundation, content categories, UX)
- `docs/prd/specific-features/Affirmations/specs/openapi.yaml` -- API contract (source of truth, 27 endpoints)
- `docs/prd/specific-features/Affirmations/specs/mongodb-schema.md` -- Collection design, indexes, access patterns (AP-AFF-01 through AP-AFF-25)
- `docs/prd/specific-features/Affirmations/specs/acceptance-criteria.md` -- Acceptance criteria with clinical safeguard requirements
- `docs/prd/specific-features/Affirmations/specs/test-specifications.md` -- Test names, Given/When/Then, coverage targets
- `docs/specs/openapi/content.yaml` -- Existing content API (affirmation packs, favorites)
- `docs/specs/mongodb/content-schema-design.md` -- Content collections (affirmation_packs, affirmations)
- `content/affirmations/christian-affirmations.md` -- Faith-based content library
- `content/affirmations/aa-affirmations.md` -- AA-aligned content library

---

## Prerequisites (Wave 0/1 artifacts required)

Before implementation begins, the following must be in place:

- [ ] MongoDB Atlas cluster provisioned with all affirmation collections (`affirmationSessions`, `affirmationSettings`, `affirmationProgress`, `affirmationFavorites`, `affirmationHidden`, `customAffirmations`, `audioRecordings`, `calendarActivities`)
- [ ] Content library seeded: 200+ affirmations tagged with level (1-4), coreBeliefs (1-4), category (10 categories), track (standard/faith-based)
- [ ] Valkey cache available (local Docker or staging ElastiCache)
- [ ] Feature flag `activity.affirmations` created in `FLAGS` collection (initially disabled)
- [ ] Auth middleware functional (Cognito JWT validation)
- [ ] Tenant isolation middleware functional
- [ ] Calendar activity dual-write infrastructure in place
- [ ] CI/CD pipeline with contract test framework operational
- [ ] Notification infrastructure (SNS/SQS) for alert and reminder events
- [ ] Audio storage infrastructure (local device + optional S3 for cloud backup)
- [ ] Sobriety counter integration available (for level gating: Day 14/60/180)
- [ ] Relapse detection integration available (for 24h post-relapse window)
- [ ] Mood tracking API available (for worsening mood detection across sessions)

---

## Agent Assignments

### Agent 1: Contract Tests (RED)

**Scope:** Write failing contract tests from the OpenAPI spec before any implementation exists.

**Inputs:**
- `docs/prd/specific-features/Affirmations/specs/openapi.yaml`
- `docs/prd/specific-features/Affirmations/specs/acceptance-criteria.md`

**Outputs:**
- `test/contract/affirmations/affirmations_contract_test.go` -- validates all 27 endpoints against OpenAPI schema
- All tests RED (no implementation exists yet)

**Tasks:**
1. Generate Go types from `openapi.yaml` (hand-write to match spec exactly)
2. Write contract tests for each of the 27 endpoints validating request schemas, response schemas, status codes, headers, and error envelope format:
   - **Session endpoints:** `POST /activities/affirmations/sessions/morning`, `POST /activities/affirmations/sessions/evening`, `POST /activities/affirmations/sessions/sos`, `GET /activities/affirmations/sessions`, `GET /activities/affirmations/sessions/{sessionId}`
   - **Library endpoints:** `GET /activities/affirmations/library`, `GET /activities/affirmations/library/{affirmationId}`, `GET /activities/affirmations/library/search`
   - **Favorites endpoints:** `POST /activities/affirmations/favorites/{affirmationId}`, `DELETE /activities/affirmations/favorites/{affirmationId}`, `GET /activities/affirmations/favorites`
   - **Hidden endpoints:** `POST /activities/affirmations/hidden/{affirmationId}`, `DELETE /activities/affirmations/hidden/{affirmationId}`, `GET /activities/affirmations/hidden`
   - **Custom affirmation endpoints:** `POST /activities/affirmations/custom`, `GET /activities/affirmations/custom`, `GET /activities/affirmations/custom/{customId}`, `PUT /activities/affirmations/custom/{customId}`, `DELETE /activities/affirmations/custom/{customId}`, `PATCH /activities/affirmations/custom/{customId}/rotation`
   - **Audio endpoints:** `POST /activities/affirmations/{affirmationId}/audio`, `GET /activities/affirmations/{affirmationId}/audio`, `DELETE /activities/affirmations/{affirmationId}/audio`
   - **Progress endpoints:** `GET /activities/affirmations/progress`, `GET /activities/affirmations/progress/milestones`
   - **Settings endpoints:** `GET /activities/affirmations/settings`, `PATCH /activities/affirmations/settings`
   - **Level endpoint:** `GET /activities/affirmations/level`
3. Write contract tests for error cases (400, 401, 403, 404, 422) and error code format (`rr:0x000Axxxx`)
4. Write contract tests for feature flag disabled scenario (404 response)
5. Verify all tests fail (RED state)

**Verification Gate:** `make contract-test` runs and all affirmation tests are RED (expected failures). No compile errors.

**Dependencies:** None (first agent to start)

---

### Agent 2: Domain Logic -- Level Engine & Content Selection

**Scope:** Pure business logic for level determination and affirmation content selection. No I/O dependencies.

**Inputs:**
- `docs/prd/specific-features/Affirmations/affirmations.md` (Sections 2.2, 9.1, 9.2)
- `docs/prd/specific-features/Affirmations/specs/acceptance-criteria.md`
- `docs/prd/specific-features/Affirmations/specs/test-specifications.md` (Section 1.1: Level Engine, Section 1.2: Content Selection)

**Outputs:**
- `internal/domain/affirmations/level.go` -- Level enum (1-4), level determination algorithm, progression gates
- `internal/domain/affirmations/level_engine.go` -- LevelEngine with sobriety day input, post-relapse detection, manual override
- `internal/domain/affirmations/content_selector.go` -- Content selection algorithm: 80/20 level ratio, 7-day no-repeat, favorites priority, hidden exclusion, category diversity, core belief coverage
- `internal/domain/affirmations/types.go` -- Affirmation, Category, CoreBelief, Track, Level enums and structs
- `internal/domain/affirmations/level_test.go` -- level engine unit tests
- `internal/domain/affirmations/content_selector_test.go` -- content selection unit tests

**Tasks:**
1. Write failing unit tests for each acceptance criterion (RED):
   - `TestAffirmations_LevelEngine_DeterminesLevel1_Days0to13`
   - `TestAffirmations_LevelEngine_DeterminesLevel2_Days14to59`
   - `TestAffirmations_LevelEngine_DeterminesLevel3_Days60to179`
   - `TestAffirmations_LevelEngine_DeterminesLevel4_Days180Plus`
   - `TestAffirmations_LevelEngine_PostRelapse_LocksToLevel1_Within24h`
   - `TestAffirmations_LevelEngine_PostRelapse_UnlocksAfter24h`
   - `TestAffirmations_LevelEngine_ManualOverride_LowerLevel`
   - `TestAffirmations_LevelEngine_ManualOverride_RejectsHigherWithout30Days`
   - `TestAffirmations_ContentSelector_80PercentCurrentLevel`
   - `TestAffirmations_ContentSelector_20PercentNextLevel`
   - `TestAffirmations_ContentSelector_NoRepeatWithin7Days`
   - `TestAffirmations_ContentSelector_FavoritesPrioritized`
   - `TestAffirmations_ContentSelector_HiddenExcluded`
   - `TestAffirmations_ContentSelector_HealthySexualityGated_Under60Days`
   - `TestAffirmations_ContentSelector_HealthySexualityGated_NoOptIn`
   - `TestAffirmations_ContentSelector_HealthySexualityGated_OptInAfter60Days`
   - `TestAffirmations_ContentSelector_FaithBasedTrackFiltering`
   - `TestAffirmations_ContentSelector_StandardTrackFiltering`
   - `TestAffirmations_ContentSelector_CoreBeliefCoverageAcrossSessions`
   - `TestAffirmations_ContentSelector_CategoryVarietyInSession`
2. Implement Level enum with values: Permission (1), Process (2), TemperedIdentity (3), FullIdentity (4)
3. Implement LevelEngine with inputs: sobrietyDays, lastRelapseTimestamp, manualOverride, daysSinceLastLevelChange
4. Implement level progression gates: Level 2 at Day 14, Level 3 at Day 60, Level 4 at Day 180
5. Implement post-relapse detection: if relapse within 24h, lock to Level 1 regardless of sobriety days
6. Implement ContentSelector with 80/20 level serving ratio
7. Implement 7-day no-repeat window (exception: user Favorites)
8. Implement favorites priority and hidden exclusion
9. Implement Healthy Sexuality category gating (requires 60+ days AND explicit opt-in)
10. Implement faith-based vs standard track filtering
11. Implement core belief coverage algorithm (ensure all 4 Carnes beliefs addressed across sessions)
12. All tests GREEN

**Verification Gate:** `make test-unit` passes. Coverage >= 95% on `internal/domain/affirmations/level*.go` and `content_selector.go`. 100% on level gating logic and post-relapse locking.

**Dependencies:** None (can run in parallel with Agent 1)

---

### Agent 3: Domain Logic -- Sessions & Clinical Safeguards

**Scope:** Session composition logic and all clinical safeguard detection. Pure business logic with no I/O.

**Inputs:**
- `docs/prd/specific-features/Affirmations/affirmations.md` (Sections 2.3, 4.1, 4.2, 4.3, 5)
- `docs/prd/specific-features/Affirmations/specs/acceptance-criteria.md`
- `docs/prd/specific-features/Affirmations/specs/test-specifications.md` (Section 1.3: Sessions, Section 1.4: Clinical Safeguards, Section 1.5: Progress)
- Domain types from Agent 2

**Outputs:**
- `internal/domain/affirmations/session.go` -- MorningSession, EveningSession, SOSSession composition
- `internal/domain/affirmations/safeguards.go` -- Clinical safeguard detection (worsening mood, crisis bypass, persistent rejection, post-relapse grounding)
- `internal/domain/affirmations/progress.go` -- Cumulative progress tracking, milestone detection
- `internal/domain/affirmations/reengagement.go` -- Re-engagement logic (3/7/14+ day gaps)
- `internal/domain/affirmations/session_test.go` -- session composition unit tests
- `internal/domain/affirmations/safeguards_test.go` -- clinical safeguard unit tests (100% coverage)
- `internal/domain/affirmations/progress_test.go` -- progress tracking unit tests
- `internal/domain/affirmations/reengagement_test.go` -- re-engagement unit tests

**Tasks:**
1. Write failing unit tests (RED):
   - **Morning session:**
     - `TestAffirmations_MorningSession_Composes3Affirmations`
     - `TestAffirmations_MorningSession_IncludesIntentionPrompt`
     - `TestAffirmations_MorningSession_AffirmationsMatchUserLevel`
     - `TestAffirmations_MorningSession_SkipWithoutPenalty`
   - **Evening session:**
     - `TestAffirmations_EveningSession_Composes1Affirmation`
     - `TestAffirmations_EveningSession_IncludesMorningIntention`
     - `TestAffirmations_EveningSession_IncludesDayRating1to5`
     - `TestAffirmations_EveningSession_OptionalFreeTextReflection`
   - **SOS session:**
     - `TestAffirmations_SOSSession_Level1Or2Only`
     - `TestAffirmations_SOSSession_NeverAboveLevel2_RegardlessOfProgress`
     - `TestAffirmations_SOSSession_IncludesBreathingExercise`
     - `TestAffirmations_SOSSession_SurfacesAdditionalAfterBreathing`
     - `TestAffirmations_SOSSession_OffersAccountabilityPartnerReachOut`
   - **Clinical safeguards:**
     - `TestAffirmations_Safeguard_WorseningMood_3ConsecutiveSessions_TriggersPrompt`
     - `TestAffirmations_Safeguard_WorseningMood_2Sessions_NoTrigger`
     - `TestAffirmations_Safeguard_CrisisBypass_SkipsAffirmations_RoutesToCrisisResources`
     - `TestAffirmations_Safeguard_PersistentRejection_5PlusHides_FlagsForReview`
     - `TestAffirmations_Safeguard_PersistentRejection_4Hides_NoFlag`
     - `TestAffirmations_Safeguard_PostRelapse_CompassionateGroundingMessage`
     - `TestAffirmations_Safeguard_PostRelapse_Level1Only`
   - **Progress:**
     - `TestAffirmations_Progress_CumulativeSessionCount_NeverStreakBased`
     - `TestAffirmations_Progress_CumulativeAffirmationCount`
     - `TestAffirmations_Progress_NoStreakCounterAnywhere`
     - `TestAffirmations_Progress_MilestoneDetection_1_10_25_50_100_250`
     - `TestAffirmations_Progress_MilestoneDetection_FirstCustomCreated`
     - `TestAffirmations_Progress_MilestoneDetection_FirstAudioSaved`
     - `TestAffirmations_Progress_MilestoneDetection_FirstSOSCompleted`
   - **Re-engagement:**
     - `TestAffirmations_Reengagement_3DayGap_SingleAffirmationPrompt`
     - `TestAffirmations_Reengagement_7DayGap_FreshLevel1SessionOption`
     - `TestAffirmations_Reengagement_14DayGap_TherapistReconnectPrompt`
     - `TestAffirmations_Reengagement_NeverShameBased`
2. Implement MorningSession composition: 3 affirmations + Daily Intention prompt ("Today I choose to...")
3. Implement EveningSession composition: 1 affirmation + morning intention recall + 1-5 day rating + optional reflection
4. Implement SOSSession composition: Level 1-2 only + 4-7-8 breathing exercise + 2 additional affirmations after breathing
5. Implement worsening mood detection: mood decline across 3+ consecutive sessions triggers therapist/sponsor prompt
6. Implement crisis bypass: crisis-level mood (1/5 on two consecutive evenings) skips affirmations, routes to crisis resources
7. Implement persistent rejection detection: 5+ hides in single session flags for self-review
8. Implement post-relapse compassionate grounding message appended to Level 1 affirmations
9. Implement re-engagement logic for 3/7/14+ day gaps with appropriate prompts
10. Implement cumulative progress tracking (total sessions, total affirmations -- NOT streaks)
11. Implement milestone detection for defined thresholds
12. All tests GREEN

**Verification Gate:** `make test-unit` passes. Coverage = 100% on `safeguards.go`. Coverage >= 90% on all other files in this agent's scope. Zero references to "streak" in any progress-related code or test assertions.

**Dependencies:** Agent 2 (needs level engine types, Level enum, ContentSelector interface)

---

### Agent 4: Domain Logic -- Custom Affirmations & Audio

**Scope:** Custom affirmation CRUD logic and audio recording metadata management. Pure business logic with no I/O.

**Inputs:**
- `docs/prd/specific-features/Affirmations/affirmations.md` (Sections 4.5, 4.6, 9.3)
- `docs/prd/specific-features/Affirmations/specs/acceptance-criteria.md`
- `docs/prd/specific-features/Affirmations/specs/test-specifications.md` (Section 1.6: Custom Affirmations, Section 1.7: Audio)

**Outputs:**
- `internal/domain/affirmations/custom.go` -- CustomAffirmation struct, validation, CRUD logic
- `internal/domain/affirmations/audio.go` -- AudioRecording metadata, format validation, background options
- `internal/domain/affirmations/custom_test.go` -- custom affirmation unit tests
- `internal/domain/affirmations/audio_test.go` -- audio metadata unit tests

**Tasks:**
1. Write failing unit tests (RED):
   - **Custom affirmation validation:**
     - `TestAffirmations_Custom_Day14GateEnforced`
     - `TestAffirmations_Custom_Day13Rejected`
     - `TestAffirmations_Custom_PresentTenseValidation_Passes`
     - `TestAffirmations_Custom_FutureTense_Rejected` ("I will be" not allowed)
     - `TestAffirmations_Custom_PositiveFraming_Passes`
     - `TestAffirmations_Custom_NegationDetected` ("I am not addicted" rejected)
     - `TestAffirmations_Custom_AcceptableNegation` ("I am free from..." accepted)
     - `TestAffirmations_Custom_IncludeInRotationToggle_On`
     - `TestAffirmations_Custom_IncludeInRotationToggle_Off`
   - **Audio validation:**
     - `TestAffirmations_Audio_MaxDuration60Seconds`
     - `TestAffirmations_Audio_ExceedsDuration_Rejected`
     - `TestAffirmations_Audio_M4AFormatRequired`
     - `TestAffirmations_Audio_InvalidFormatRejected`
     - `TestAffirmations_Audio_5BackgroundOptions`
     - `TestAffirmations_Audio_HeadphoneDisconnectInterface`
     - `TestAffirmations_Audio_LocalOnlyStorageDefault`
     - `TestAffirmations_Audio_CloudSyncOptInRequired`
2. Implement CustomAffirmation struct with fields: id, userId, statement, createdAt, includeInRotation, isActive
3. Implement Day 14 gate: reject custom creation if sobrietyDays < 14
4. Implement present-tense validation (detect "I will", "I'm going to" as future tense)
5. Implement positive framing check: reject direct negations ("I am not", "I don't"), allow "free from" pattern
6. Implement include-in-rotation toggle
7. Implement AudioRecording metadata: id, affirmationId, userId, durationSeconds, format, backgroundOption, createdAt, storageLocation
8. Implement audio validation: max 60 seconds, m4a format required, 5 background options (nature, soft-tones, rain, ocean, silence)
9. Define HeadphoneDisconnectHandler interface (platform-specific implementation in mobile clients)
10. Implement local-only storage default with explicit cloud sync opt-in flag
11. All tests GREEN

**Verification Gate:** `make test-unit` passes. Coverage >= 90% on `custom.go` and `audio.go`. 100% on Day 14 gate and tense/framing validation.

**Dependencies:** None (can run in parallel with Agents 1 and 2)

---

### Agent 5: Repository Layer

**Scope:** MongoDB data access implementing all access patterns from the schema spec.

**Inputs:**
- `docs/prd/specific-features/Affirmations/specs/mongodb-schema.md`
- `docs/prd/specific-features/Affirmations/specs/test-specifications.md` (Section 2.1: Repository Tests)
- Domain types from Agents 2, 3, 4

**Outputs:**
- `internal/repository/affirmations_repo.go` -- AffirmationsRepository interface definition
- `internal/repository/mongodb/affirmations_session_repo.go` -- Session collection MongoDB implementation
- `internal/repository/mongodb/affirmations_settings_repo.go` -- Settings collection MongoDB implementation
- `internal/repository/mongodb/affirmations_progress_repo.go` -- Progress collection MongoDB implementation
- `internal/repository/mongodb/affirmations_favorites_repo.go` -- Favorites collection MongoDB implementation
- `internal/repository/mongodb/affirmations_hidden_repo.go` -- Hidden collection MongoDB implementation
- `internal/repository/mongodb/affirmations_custom_repo.go` -- Custom affirmations MongoDB implementation
- `internal/repository/mongodb/affirmations_audio_repo.go` -- Audio recordings MongoDB implementation
- `test/integration/affirmations/affirmations_repository_test.go` -- integration tests

**Tasks:**
1. Define `AffirmationsRepository` interface with methods covering all 8 collections:
   - Sessions: `CreateSession`, `GetSession`, `ListSessions`, `ListSessionsByDateRange`
   - Settings: `GetSettings`, `UpdateSettings`
   - Progress: `GetProgress`, `IncrementSessionCount`, `IncrementAffirmationCount`, `RecordMilestone`
   - Favorites: `AddFavorite`, `RemoveFavorite`, `ListFavorites`, `IsFavorite`
   - Hidden: `HideAffirmation`, `UnhideAffirmation`, `ListHidden`, `IsHidden`, `CountHiddenInSession`
   - Custom: `CreateCustom`, `GetCustom`, `ListCustom`, `UpdateCustom`, `DeleteCustom`, `ToggleRotation`
   - Audio: `SaveAudioMetadata`, `GetAudioMetadata`, `DeleteAudioMetadata`, `ListAudioByUser`
   - Level: `GetLevelHistory`, `RecordLevelChange`
2. Implement MongoDB queries matching access patterns AP-AFF-01 through AP-AFF-25:
   - AP-AFF-01: Get user settings by userId
   - AP-AFF-02: Get current level by userId
   - AP-AFF-03: List sessions by userId + dateRange (reverse chronological)
   - AP-AFF-04: Get session by sessionId
   - AP-AFF-05: List favorites by userId
   - AP-AFF-06: List hidden by userId
   - AP-AFF-07: Get progress by userId
   - AP-AFF-08: List custom affirmations by userId
   - AP-AFF-09: Get custom affirmation by customId
   - AP-AFF-10: Get audio metadata by affirmationId + userId
   - AP-AFF-11: List audio recordings by userId
   - AP-AFF-12: Get recent session affirmation IDs (7-day no-repeat window)
   - AP-AFF-13: Count hides in current session
   - AP-AFF-14: Count consecutive worsening mood sessions
   - AP-AFF-15: Get milestones by userId
   - AP-AFF-16: Get level change history by userId
   - AP-AFF-17: Search library by keyword + level + category
   - AP-AFF-18: List library by category + level + track
   - AP-AFF-19: Get SOS content pool (Level 1-2, SOS category)
   - AP-AFF-20: Get last session timestamp (for re-engagement calculation)
   - AP-AFF-21: Calendar activity query by month
   - AP-AFF-22: Get morning intention for today (for evening session)
   - AP-AFF-23: Get session count for date range (for calendar heatmap)
   - AP-AFF-24: Count total favorites
   - AP-AFF-25: Get core belief distribution across recent sessions
3. Implement calendar activity dual-write on session creation
4. Write cursor-based pagination using `createdAt` + `_id` compound cursor
5. Create MongoDB indexes as specified in schema
6. Write integration tests against local MongoDB for all access patterns

**Verification Gate:** `make test-integration` passes for all affirmation repository tests. All 25 access patterns verified. Calendar dual-write tested.

**Dependencies:** Agents 2, 3, 4 (needs domain types from all three)

---

### Agent 6: Cache Layer

**Scope:** Valkey cache-aside pattern for affirmation data.

**Inputs:**
- `docs/prd/specific-features/Affirmations/specs/mongodb-schema.md` (caching strategy section)
- Repository interface from Agent 5

**Outputs:**
- `internal/cache/affirmations_cache.go` -- Valkey cache wrapper for affirmation data
- `test/integration/affirmations/affirmations_cache_test.go` -- cache integration tests

**Tasks:**
1. Implement cache-aside for morning session content (5-min TTL) -- ensures consistent content if user reopens session within window
2. Implement cache for user progress (10-min TTL) -- cumulative counts queried frequently from home screen
3. Implement cache for user settings (10-min TTL) -- delivery times, track preference, category opt-ins
4. Implement cache for level info (10-min TTL) -- current level, sobriety days, level change eligibility
5. Implement SOS content local cache strategy -- SOS pool always available, refreshed on app launch
6. Implement cache invalidation on all mutation operations:
   - Session creation invalidates: progress, morning content (if same day)
   - Settings update invalidates: settings cache
   - Favorite/hide mutation invalidates: favorites list, hidden list, morning content
   - Custom affirmation mutation invalidates: custom list, morning content (if in rotation)
   - Level change invalidates: level info, morning content
7. Write integration tests verifying cache hit/miss/invalidation for each pattern

**Verification Gate:** Cache integration tests pass. Cache invalidation verified for all mutation operations. SOS content available without network.

**Dependencies:** Agent 5 (needs repository interface)

---

### Agent 7: Handler Layer (HTTP)

**Scope:** HTTP handlers that wire domain logic, repository, and cache together. All 27 endpoints.

**Inputs:**
- `docs/prd/specific-features/Affirmations/specs/openapi.yaml`
- Domain logic from Agents 2, 3, 4
- Repository from Agent 5
- Cache from Agent 6

**Outputs:**
- `internal/handler/affirmations_handler.go` -- HTTP handler implementing all 27 endpoints
- `internal/handler/affirmations_handler_test.go` -- handler unit tests with mocked dependencies
- `internal/middleware/affirmations_feature_flag.go` -- feature flag middleware for affirmation endpoints

**Tasks:**
1. Implement HTTP handlers for all 27 endpoints:
   - **Sessions:**
     - `POST /activities/affirmations/sessions/morning` -- compose and record morning session
     - `POST /activities/affirmations/sessions/evening` -- compose and record evening session
     - `POST /activities/affirmations/sessions/sos` -- compose and record SOS session
     - `GET /activities/affirmations/sessions` -- list sessions with cursor pagination
     - `GET /activities/affirmations/sessions/{sessionId}` -- get session detail
   - **Library:**
     - `GET /activities/affirmations/library` -- browse library filtered by category, level, track
     - `GET /activities/affirmations/library/{affirmationId}` -- get single affirmation
     - `GET /activities/affirmations/library/search` -- keyword search
   - **Favorites:**
     - `POST /activities/affirmations/favorites/{affirmationId}` -- add to favorites
     - `DELETE /activities/affirmations/favorites/{affirmationId}` -- remove from favorites
     - `GET /activities/affirmations/favorites` -- list favorites
   - **Hidden:**
     - `POST /activities/affirmations/hidden/{affirmationId}` -- hide affirmation
     - `DELETE /activities/affirmations/hidden/{affirmationId}` -- unhide affirmation
     - `GET /activities/affirmations/hidden` -- list hidden (for management)
   - **Custom:**
     - `POST /activities/affirmations/custom` -- create custom affirmation (Day 14 gate)
     - `GET /activities/affirmations/custom` -- list user's custom affirmations
     - `GET /activities/affirmations/custom/{customId}` -- get custom affirmation
     - `PUT /activities/affirmations/custom/{customId}` -- update custom affirmation
     - `DELETE /activities/affirmations/custom/{customId}` -- delete custom affirmation
     - `PATCH /activities/affirmations/custom/{customId}/rotation` -- toggle in-rotation
   - **Audio:**
     - `POST /activities/affirmations/{affirmationId}/audio` -- upload audio recording (multipart/form-data)
     - `GET /activities/affirmations/{affirmationId}/audio` -- get audio metadata
     - `DELETE /activities/affirmations/{affirmationId}/audio` -- delete audio recording
   - **Progress:**
     - `GET /activities/affirmations/progress` -- get cumulative progress
     - `GET /activities/affirmations/progress/milestones` -- get achieved milestones
   - **Settings:**
     - `GET /activities/affirmations/settings` -- get user settings
     - `PATCH /activities/affirmations/settings` -- update settings (JSON Merge Patch)
   - **Level:**
     - `GET /activities/affirmations/level` -- get current level info
2. Wire feature flag check (`activity.affirmations`) -- return 404 when disabled (fail closed)
3. Wire auth middleware (Bearer JWT)
4. Wire tenant isolation (every request scoped to authenticated user's tenant)
5. Implement response envelope format (`{ data, links, meta }`)
6. Implement error response format (`{ errors: [...] }`) with `rr:0x000Axxxx` error codes:
   - `rr:0x000A0001` -- Affirmation not found
   - `rr:0x000A0002` -- Custom affirmation validation failed
   - `rr:0x000A0003` -- Day 14 gate not met for custom creation
   - `rr:0x000A0004` -- Audio format invalid
   - `rr:0x000A0005` -- Audio duration exceeded
   - `rr:0x000A0006` -- Level override not eligible
   - `rr:0x000A0007` -- Healthy Sexuality category not available
   - `rr:0x000A0008` -- Feature disabled
   - `rr:0x000A0009` -- Settings validation failed
   - `rr:0x000A000A` -- Session composition failed
7. Handle audio upload via multipart form data (m4a, max 60s)
8. Implement JSON Merge Patch for settings endpoint (RFC 7396)
9. Set Location header and X-Correlation-Id on create operations
10. Write handler unit tests with mocked domain/repo/cache dependencies
11. Contract tests from Agent 1 should now be GREEN

**Verification Gate:** `make contract-test` passes (all RED tests from Agent 1 now GREEN). Handler unit tests pass. All 27 endpoints return correct status codes and envelope format.

**Dependencies:** Agents 2, 3, 4 (domain logic), Agent 5 (repository), Agent 6 (cache)

---

### Agent 8: Event Publishing

**Scope:** SNS/SQS event publishing for notifications, alerts, and clinical escalation.

**Inputs:**
- `docs/prd/specific-features/Affirmations/affirmations.md` (Sections 2.3, 4.3, 5.3, 5.4, 8.2)
- `docs/prd/specific-features/Affirmations/specs/acceptance-criteria.md`
- `docs/prd/specific-features/Affirmations/specs/test-specifications.md` (Section 2.3: Event Publishing)

**Outputs:**
- `internal/events/affirmations_events.go` -- affirmation event types and SNS publisher
- `internal/events/affirmations_consumers.go` -- SQS event consumers (notification triggers)
- `test/integration/affirmations/affirmations_events_test.go` -- event integration tests

**Tasks:**
1. Define event types:
   - `affirmations.session.completed` -- published on every session completion (morning/evening/SOS)
   - `affirmations.sos.activated` -- published immediately when SOS mode starts
   - `affirmations.sos.completed` -- published when SOS session finishes
   - `affirmations.milestone.achieved` -- published on milestone detection (1st, 10th, 25th, 50th, 100th, 250th session; 1st custom; 1st audio; 1st SOS)
   - `affirmations.mood.worsening` -- published when 3+ consecutive session mood declines detected
   - `affirmations.crisis.detected` -- published when crisis bypass activates
   - `affirmations.relapse.level_lock` -- published when post-relapse locks level to 1
2. Implement SNS publisher for each event type
3. Implement SQS consumers for notification delivery:
   - Post-SOS check-in: schedule gentle in-app notification 10 minutes after SOS completion ("Checking in -- how are you feeling?")
   - Morning session reminder: daily at user's configured time ("Your daily moment is ready.")
   - Evening reflection reminder: daily at user's configured time ("A moment to close your day.")
   - Re-engagement notification (3-day gap): "Ready when you are." (once per gap period)
   - Re-engagement notification (7-day gap): "Coming back is an act of courage." (once per gap period)
   - Re-engagement notification (14+ day gap): prompt to reconnect with therapist/partner (once)
   - Worsening mood clinical escalation: surface therapist/sponsor prompt
   - Crisis routing: bypass affirmations, route to Crisis Text Line, SAMHSA Helpline, designated therapist/sponsor
4. Implement notification text requirements: 100% generic language, never reference recovery or addiction
5. Write integration tests against local SQS/SNS verifying:
   - Event payloads match expected schema
   - Post-SOS notification fires with 10-minute delay
   - Re-engagement notifications fire once per gap period (not daily)
   - Crisis events bypass normal notification flow

**Verification Gate:** Event integration tests pass. Post-SOS check-in fires at correct delay. Notification text is 100% generic (no recovery-specific language). Clinical escalation events published on correct triggers.

**Dependencies:** Agent 7 (needs handler to trigger events on session completion)

---

### Agent 9: Integration + E2E Tests

**Scope:** Full-stack integration tests and persona-based E2E tests.

**Inputs:**
- `docs/prd/specific-features/Affirmations/specs/test-specifications.md` (Sections 2, 3)
- All implementation from Agents 2-8

**Outputs:**
- `test/integration/affirmations/affirmations_full_test.go` -- full-stack integration tests
- `test/e2e/affirmations/affirmations_e2e_test.go` -- E2E tests for staging

**Tasks:**
1. Write full-stack integration tests using `make local-up`:
   - **Morning -> Evening -> SOS full flow:**
     - `TestAffirmations_Integration_MorningSession_Creates3AffirmationsAndIntention`
     - `TestAffirmations_Integration_EveningSession_RecallsMorningIntention_RecordsDayRating`
     - `TestAffirmations_Integration_SOSSession_Level1Or2_WithBreathingExercise`
     - `TestAffirmations_Integration_FullDayFlow_Morning_Evening_ProgressIncrements`
   - **Post-relapse level locking flow:**
     - `TestAffirmations_Integration_PostRelapse_LevelLockedTo1_Within24h`
     - `TestAffirmations_Integration_PostRelapse_CompassionateGroundingAppended`
     - `TestAffirmations_Integration_PostRelapse_UnlocksAfter24h`
   - **Custom affirmation + audio flow:**
     - `TestAffirmations_Integration_CustomAffirmation_CreateAfterDay14`
     - `TestAffirmations_Integration_CustomAffirmation_RejectedBeforeDay14`
     - `TestAffirmations_Integration_CustomAffirmation_InRotation_AppearsInSession`
     - `TestAffirmations_Integration_AudioUpload_M4A_Under60s`
     - `TestAffirmations_Integration_AudioUpload_RejectsInvalidFormat`
   - **Clinical safeguard trigger flows:**
     - `TestAffirmations_Integration_WorseningMood_3Sessions_TriggersPromptEvent`
     - `TestAffirmations_Integration_CrisisBypass_RoutesToResources`
     - `TestAffirmations_Integration_PersistentRejection_5Hides_FlagsEvent`
   - **Library and curation flow:**
     - `TestAffirmations_Integration_FavoriteAffirmation_PrioritizedInNextSession`
     - `TestAffirmations_Integration_HideAffirmation_NeverServedAgain`
     - `TestAffirmations_Integration_7DayNoRepeat_Enforced`
   - **Calendar dual-write:**
     - `TestAffirmations_Integration_CalendarActivity_CreatedOnSessionCompletion`
   - **Cache behavior:**
     - `TestAffirmations_Integration_Cache_ProgressCachedAndInvalidated`
     - `TestAffirmations_Integration_Cache_SettingsCachedAndInvalidated`
2. Write E2E tests using persona fixtures:
   - **Alex (new to recovery, Day 3):** Level 1 only, no custom affirmations, standard track
   - **Marcus (60+ days, faith-based):** Level 3 eligible, faith-based track, can create custom affirmations
   - **Diego (post-relapse within 24h):** Locked to Level 1, compassionate grounding message, SOS flow
3. Verify cumulative-only progress: assert no "streak" field or streak-like behavior anywhere
4. Verify notification text genericity: assert no recovery-specific language in any notification

**Verification Gate:** `make test-integration` and `make test-e2e` pass. All acceptance criteria verified. All clinical safeguard flows exercised.

**Dependencies:** Agents 2-8 (needs complete implementation)

---

### Agent 10: Mobile API Clients (iOS + Android)

**Scope:** Hand-written API clients for both platforms with offline support, audio session management, and headphone disconnect handling.

**Inputs:**
- `docs/prd/specific-features/Affirmations/specs/openapi.yaml`
- `docs/prd/specific-features/Affirmations/affirmations.md` (Sections 4.6, 7.1, 8, 9.3)
- `docs/prd/specific-features/Affirmations/specs/test-specifications.md` (Section 5: Mobile Client Tests)

**Outputs (iOS):**
- `iosApp/.../Data/API/AffirmationsAPIClient.swift` -- Swift URLSession API client for all 27 endpoints
- `iosApp/.../Data/Models/AffirmationTypes.swift` -- Swift Codable structs matching OpenAPI schemas
- `iosApp/.../Services/AffirmationAudioSessionManager.swift` -- AVAudioSession management, headphone disconnect detection
- `iosApp/.../Services/AffirmationOfflineCache.swift` -- SwiftData persistence for 30 offline affirmations + SOS pool
- `iosApp/.../Tests/AffirmationsAPIClientTests.swift` -- Swift contract tests

**Outputs (Android):**
- `androidApp/.../data/api/AffirmationsApiClient.kt` -- Kotlin Retrofit service for all 27 endpoints
- `androidApp/.../data/models/AffirmationTypes.kt` -- Kotlin data classes matching OpenAPI schemas
- `androidApp/.../services/AffirmationAudioSessionManager.kt` -- AudioManager focus change, headphone disconnect detection
- `androidApp/.../services/AffirmationOfflineCache.kt` -- Room persistence for 30 offline affirmations + SOS pool
- `androidApp/.../tests/AffirmationsApiClientTest.kt` -- Kotlin contract tests

**Tasks (iOS):**
1. Hand-write Swift Codable structs matching OpenAPI schemas (camelCase JSON decoding)
2. Hand-write URLSession API client for all 27 endpoints with proper error handling
3. Implement offline cache: persist 30 affirmations locally via SwiftData, refresh on app launch when online
4. Implement SOS pool local cache: always available offline, separate from daily cache
5. Implement AVAudioSession audio session manager:
   - Configure audio session for recording (`.playAndRecord` category)
   - Configure audio session for playback (`.playback` category)
   - Monitor `AVAudioSession.routeChangeNotification` for headphone disconnect
   - Immediately pause audio on `.oldDeviceUnavailable` route change reason
   - Background music mixing at 60% volume relative to voice
6. Implement headphone disconnect detection: subscribe to `AVAudioSession.routeChangeNotification`, pause on disconnect -- non-negotiable safety feature
7. Write contract tests validating request/response types match spec against Prism mock server

**Tasks (Android):**
1. Hand-write Kotlin data classes matching OpenAPI schemas (camelCase via `@SerializedName`)
2. Hand-write Retrofit service interface for all 27 endpoints
3. Implement offline cache: persist 30 affirmations locally via Room, refresh on app launch when online
4. Implement SOS pool local cache: always available offline
5. Implement AudioManager audio session manager:
   - Configure audio focus for recording
   - Configure audio focus for playback
   - Monitor `AudioManager.OnAudioFocusChangeListener` and `BroadcastReceiver` for `ACTION_HEADSET_PLUG`
   - Immediately pause audio on headset disconnect
   - Background music mixing at 60% default volume
6. Implement headphone disconnect detection: register `BroadcastReceiver` for `ACTION_HEADSET_PLUG` and Bluetooth disconnect -- non-negotiable safety feature
7. Write contract tests validating request/response types match spec against Prism mock server

**Verification Gate:** Mobile contract tests pass against Prism mock. Offline cache tests pass (30 affirmations persisted). Headphone disconnect tests pass on both platforms. Audio pause verified within 100ms of disconnect event.

**Dependencies:** Agent 1 (needs finalized OpenAPI spec). Can run in parallel with Agents 2-8.

---

## Execution Timeline

```
Week 1:
  [Agent 1]  Contract Tests (RED)                ████░░░░░░░░░░░░░░░░░░░░
  [Agent 2]  Level Engine & Content Selection     ████████░░░░░░░░░░░░░░░░
  [Agent 4]  Custom Affirmations & Audio          ████████░░░░░░░░░░░░░░░░
  [Agent 10] Mobile API Clients (start)           ██░░░░░░░░░░░░░░░░░░░░░░

Week 2:
  [Agent 3]  Sessions & Clinical Safeguards       ░░░░████████░░░░░░░░░░░░
  [Agent 10] Mobile API Clients (cont.)           ░░██████████░░░░░░░░░░░░

Week 3:
  [Agent 5]  Repository Layer                     ░░░░░░░░████████░░░░░░░░
  [Agent 10] Mobile API Clients (cont.)           ░░░░░░░░████████░░░░░░░░

Week 4:
  [Agent 6]  Cache Layer                          ░░░░░░░░░░░░████░░░░░░░░
  [Agent 10] Mobile API Clients (cont.)           ░░░░░░░░░░░░████░░░░░░░░

Week 5:
  [Agent 7]  Handler Layer (HTTP)                 ░░░░░░░░░░░░░░░░████████
  [Agent 8]  Event Publishing                     ░░░░░░░░░░░░░░░░░░░░████

Week 6:
  [Agent 9]  Integration + E2E Tests              ░░░░░░░░░░░░░░░░░░░░████
  [Agent 10] Mobile API Clients (finish)          ░░░░░░░░░░░░░░░░░░░░░░██

Gate: All tests GREEN -> Enable feature flag for staging
```

---

## Dependency Graph

```
Agent 1 (Contract Tests RED)
  |
  +--- Agent 7 (Handler) verifies against Agent 1's tests
  |
  +--- Agent 10 (Mobile Clients) uses Agent 1's spec
  |
Agent 2 (Level Engine & Content Selection) ----+
  |                                            |
  v                                            |
Agent 3 (Sessions & Clinical Safeguards) ------+
  |                                            |
  |   Agent 4 (Custom & Audio) ----------------+
  |     |                                      |
  |     |                                      |
  v     v                                      |
Agent 5 (Repository) -------------------------+
  |                                            |
  v                                            |
Agent 6 (Cache) ------------------------------+
  |                                            |
  v                                            v
Agent 7 (Handler) <----------------------------+
  |
  v
Agent 8 (Event Publishing)
  |
  v
Agent 9 (Integration + E2E Tests)

Agent 10 (Mobile Clients) -- parallel, needs only Agent 1's spec
```

---

## Verification Gates (Quality Checkpoints)

| Gate | Trigger | Criteria | Blocks |
|------|---------|----------|--------|
| **G1: Spec Valid** | After Agent 1 | `redocly lint openapi.yaml` passes with 0 errors; all 27 endpoint contracts written | All agents |
| **G2: Level Engine** | After Agent 2 | Unit tests pass; 100% coverage on level gating, post-relapse locking, 80/20 ratio | Agent 3 |
| **G3: Sessions & Safeguards** | After Agent 3 | Unit tests pass; 100% coverage on `safeguards.go`; zero "streak" references in progress code | Agent 5 |
| **G4: Custom & Audio** | After Agent 4 | Unit tests pass; 100% coverage on Day 14 gate, tense/framing validation | Agent 5 |
| **G5: Repository** | After Agent 5 | Integration tests pass; all 25 access patterns verified; calendar dual-write tested | Agent 6 |
| **G6: Cache** | After Agent 6 | Cache integration tests pass; invalidation verified for all mutations; SOS pool cached locally | Agent 7 |
| **G7: Handlers GREEN** | After Agent 7 | All contract tests from Agent 1 now GREEN; all 27 endpoints return correct envelope format | Agent 8, 9 |
| **G8: Events** | After Agent 8 | Event integration tests pass; notification text is 100% generic; clinical escalation verified | Agent 9 |
| **G9: Full Integration** | After Agent 9 | `make test-integration` + `make test-e2e` pass; all clinical safeguard flows exercised | Feature flag enable |
| **G10: Mobile Clients** | After Agent 10 | Mobile contract tests pass against Prism mock; headphone disconnect tested; offline cache verified | App release |

---

## Feature Flag Rollout Plan

| Stage | `activity.affirmations` Config | Audience |
|-------|-------------------------------|----------|
| Development | Enabled for `tenant: DEV` only | Dev team |
| Staging QA | Enabled for all tenants, staging only | QA team + CSAT clinical reviewer |
| Content Review | Enabled, staging only; all 200+ affirmations reviewed by CSAT | CSAT advisor |
| Canary | Enabled, rolloutPercentage: 10% | 10% of production users |
| Gradual | rolloutPercentage: 25% -> 50% -> 100% | Progressive rollout over 2 weeks |
| GA | Enabled, rolloutPercentage: 100% | All users |

---

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| **Backfire risk:** Identity-level affirmations served to early-recovery users cause harm | Level engine prevents Level 3-4 affirmations before Day 60/180; 100% test coverage on level gating; post-relapse locks to Level 1. Agent 2 verification gate blocks downstream if this fails. |
| **Audio privacy:** Headphone disconnect plays personal recording on speaker in public | Headphone disconnect detection is non-negotiable; tested on both iOS (AVAudioSession route change) and Android (BroadcastReceiver); Agent 10 must demonstrate pause within 100ms of disconnect. |
| **Shame spiral:** Streak counter creates shame on missed days | Cumulative-only progress; no streak counters anywhere; Agent 3 tests assert zero "streak" references; Agent 9 E2E verifies no streak-like behavior. |
| **Clinical safeguard gaps:** Worsening mood or crisis not detected | 100% test coverage on all safeguard paths in Agent 3; integration tests in Agent 9 exercise every clinical trigger; crisis bypass routes to professional resources, never self-handles. |
| **Content quality:** Affirmations not clinically appropriate or backfire-safe | CSAT review required before content launch (out of scope for code); feature flag rollout includes explicit Content Review stage on staging. |
| **SOS latency:** User in active urge waits too long for SOS response | SOS content pool cached locally on device (Agent 6 + Agent 10); 0-5 second response requirement; offline-capable; integration tests verify local cache availability. |
| **Healthy Sexuality premature exposure:** Sensitive category shown before user is ready | Double gate: 60+ days sobriety AND explicit opt-in required; default OFF; Agent 2 tests verify both gates independently. |
| **Post-relapse messaging tone:** Grounding message feels punitive instead of compassionate | CSAT-reviewed message templates; Agent 3 tests verify compassionate framing; re-engagement messaging is never shame-based (tested). |
| **Existing content.yaml spec conflict:** Current `content.yaml` has simpler Affirmation schema without levels/sessions | This activity spec extends the content model. The `content.yaml` endpoints serve the basic content library; the `activities/affirmations` endpoints in this spec handle the clinical session experience layer on top. Both coexist. |

---

## PR Decomposition

Target < 400 lines per PR. Recommended stacking:

| PR | Agent | Content | Lines (est.) |
|----|-------|---------|-------------|
| PR-1 | 1 | OpenAPI spec + contract tests (RED) for all 27 endpoints | ~400 |
| PR-2 | 2 | Domain types, Level enum, LevelEngine + level gating tests | ~350 |
| PR-3 | 2 | ContentSelector: 80/20 ratio, 7-day no-repeat, favorites/hidden, category/track filtering + tests | ~400 |
| PR-4 | 3 | Morning/Evening/SOS session composition + tests | ~350 |
| PR-5 | 3 | Clinical safeguards (worsening mood, crisis bypass, persistent rejection, post-relapse grounding) + tests | ~350 |
| PR-6 | 3 | Progress tracking (cumulative-only) + milestones + re-engagement logic + tests | ~300 |
| PR-7 | 4 | Custom affirmation CRUD + validation (Day 14 gate, tense, framing) + audio metadata + tests | ~350 |
| PR-8 | 5 | Repository interface + MongoDB implementation (sessions, settings, progress, level) | ~400 |
| PR-9 | 5 | Repository MongoDB implementation (favorites, hidden, custom, audio) + integration tests | ~400 |
| PR-10 | 6 | Cache layer (morning content, progress, settings, level, SOS) + cache integration tests | ~300 |
| PR-11 | 7 | HTTP handlers: session endpoints + library endpoints + feature flag middleware | ~400 |
| PR-12 | 7 | HTTP handlers: favorites, hidden, custom, audio, progress, settings, level endpoints | ~400 |
| PR-13 | 8 | Event publishing (7 event types) + notification consumers + event integration tests | ~350 |
| PR-14 | 9 | Full-stack integration tests + persona E2E tests (Alex, Marcus, Diego) | ~400 |
| PR-15 | 10 | iOS API client + Codable types + audio session manager + offline cache + headphone disconnect | ~400 |
| PR-16 | 10 | Android API client + data classes + audio session manager + offline cache + headphone disconnect | ~400 |
