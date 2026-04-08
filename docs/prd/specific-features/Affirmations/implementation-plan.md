# Affirmations: Multi-Agent Implementation Plan

**Feature:** Christian Affirmations Activity
**Methodology:** Specification-Driven Development + Test-Driven Development
**Specs:** `specs/acceptance-criteria.md`, `specs/openapi.yaml`, `specs/mongodb-schema.md`, `specs/test-specifications.md`

---

## Build Order

### Wave 1: Foundation (parallel -- no dependencies between tasks)

#### Agent 1: Content Library & Data Seeding
- **Spec:** `specs/mongodb-schema.md` (Sections 2.1, 2.2)
- **Scope:**
  1. Create `content/affirmations/affirmations-pack-basic.json` with 55+ affirmations organized by category and level
     - Categories: identity, strength, recovery, purity, freedom, surrender, courage, hope, family, healthySexuality
     - Levels: Level 1 (30+), Level 2 (15+), Level 3 (10+, including healthySexuality)
     - Structure per affirmation: statement, scriptureReference, scriptureText, expansion, prayer, category, level, tags
     - Tags include trigger mappings: `trigger_emotional`, `trigger_environmental`, `trigger_relational`, `trigger_physical`, `trigger_digital`, `trigger_spiritual`
  2. Source content from `content/affirmations/christian-affirmations.md` and `content/affirmations/aa-affirmations.md`
  3. Create MongoDB seed script for pack and affirmation documents
  4. RED: Write content validation tests
     - Verify 55+ affirmations exist
     - Verify all categories have >= 3 affirmations
     - Verify all levels have content
     - Verify every affirmation has required fields
     - Verify healthySexuality affirmations are Level 3 only
  5. GREEN: Validate content passes all checks
- **Files:**
  - `content/affirmations/affirmations-pack-basic.json` (new)
  - `scripts/seed/affirmations.js` (new -- MongoDB seed script)
  - `test/content/affirmation_content_test.go` (new)
- **Depends on:** Nothing
- **Validates:** AFF-DM-AC1, AFF-DM-AC3, AFF-DM-AC4, AFF-DM-AC9

#### Agent 2: Domain Models & Validation
- **Spec:** `specs/acceptance-criteria.md` (AFF-DM-*), `specs/openapi.yaml` (schemas)
- **Scope:**
  1. RED: Write unit tests for affirmation validation
     - `TestAffirmation_AFF_DM_AC1_AffirmationStructure`
     - `TestAffirmation_AFF_DM_AC2_StatementMaxLength`
     - `TestAffirmation_AFF_DM_AC3_CategoryEnum_Valid`
     - `TestAffirmation_AFF_DM_AC3_CategoryEnum_Invalid`
     - `TestAffirmation_AFF_DM_AC4_LevelRange_Valid`
     - `TestAffirmation_AFF_DM_AC4_LevelRange_Invalid`
     - `TestAffirmation_AFF_DM_AC5_IdPattern_SystemAffirmation`
     - `TestAffirmation_AFF_DM_AC5_IdPattern_CustomAffirmation`
  2. GREEN: Implement domain types and validators
     - `Affirmation` struct with all fields
     - `AffirmationCategory` enum
     - `AffirmationLevel` type with validation
     - `AffirmationPack` struct
     - Validation functions for statement length, category, level, ID pattern
  3. Write custom affirmation validation
     - `CreateCustomAffirmationRequest` struct
     - `UpdateCustomAffirmationRequest` struct
     - Schedule validation (daily, weekdays, weekends, custom + customScheduleDays)
- **Files:**
  - `internal/domain/affirmation/types.go` (new)
  - `internal/domain/affirmation/validation.go` (new)
  - `internal/domain/affirmation/validation_test.go` (new)
- **Depends on:** Nothing
- **Validates:** AFF-DM-AC1 through AFF-DM-AC5

#### Agent 3: Level Gating Logic
- **Spec:** `specs/acceptance-criteria.md` (AFF-LV-*)
- **Scope:**
  1. RED: Write unit tests for level gating
     - `TestAffirmation_AFF_LV_AC1_Level1Access`
     - `TestAffirmation_AFF_LV_AC2_Level2Unlock`
     - `TestAffirmation_AFF_LV_AC2_Level2Unlock_Below`
     - `TestAffirmation_AFF_LV_AC3_Level3Unlock`
     - `TestAffirmation_AFF_LV_AC3_Level3Unlock_Below`
     - `TestAffirmation_AFF_LV_AC4_PostRelapseLevel1Only`
     - `TestAffirmation_AFF_LV_AC4_PostRelapseLevel1Only_After24h`
     - `TestAffirmation_AFF_LV_AC5_SOSModeMaxLevel2`
     - `TestAffirmation_AFF_LV_AC5_SOSModeMaxLevel2_Level1User`
     - `TestAffirmation_AFF_LV_AC6_CumulativeNotStreak`
     - `TestAffirmation_AFF_LV_AC7_HealthySexualityOptIn_NotOptedIn`
     - `TestAffirmation_AFF_LV_AC7_HealthySexualityOptIn_OptedIn`
     - `TestAffirmation_AFF_LV_AC7_HealthySexualityOptIn_InsufficientDays`
     - `TestAffirmation_AFF_DM_AC8_HealthySexualityGating`
  2. GREEN: Implement level gating logic
     - `GetMaxLevel(cumulativeDays int) int`
     - `GetEffectiveMaxLevel(cumulativeDays int, sobrietyResetAt *time.Time, sosMode bool) int`
     - `IsHealthySexualityAccessible(cumulativeDays int, optedIn bool) bool`
     - `FilterByLevel(affirmations []Affirmation, maxLevel int, hsAccessible bool) []Affirmation`
- **Files:**
  - `internal/domain/affirmation/level.go` (new)
  - `internal/domain/affirmation/level_test.go` (new)
- **Depends on:** Agent 2 (types)
- **Validates:** AFF-LV-AC1 through AFF-LV-AC7, AFF-DM-AC8

---

### Wave 2: Core Logic (parallel -- all depend on Wave 1)

#### Agent 4: Rotation & Selection Engine
- **Spec:** `specs/acceptance-criteria.md` (AFF-RO-*, AFF-DL-AC1, AFF-DL-AC2)
- **Scope:**
  1. RED: Write unit tests for rotation logic
     - `TestAffirmation_AFF_DL_AC1_DeterministicDaily`
     - `TestAffirmation_AFF_DL_AC1_DeterministicDaily_DifferentDay`
     - `TestAffirmation_AFF_DL_AC2_OwnedPacksOnly`
     - `TestAffirmation_AFF_RO_AC1_IndividuallyChosen`
     - `TestAffirmation_AFF_RO_AC2_RandomAutomatic`
     - `TestAffirmation_AFF_RO_AC3_PermanentPackage`
     - `TestAffirmation_AFF_RO_AC4_DayOfWeekPackage`
     - `TestAffirmation_AFF_RO_AC5_RotationWeighting`
     - `TestAffirmation_AFF_RO_AC6_TriggerOverride`
     - `TestAffirmation_AFF_RO_AC7_NoDuplicatesInCycle`
     - `TestAffirmation_AFF_RO_AC7_NoDuplicatesInCycle_Reset`
  2. GREEN: Implement rotation engine
     - `SelectDailyAffirmation(ctx SelectionContext) (*Affirmation, error)`
     - `GetContextualAffirmation(ctx SelectionContext, trigger string) (*Affirmation, error)`
     - `BuildWeightedPool(affirmations []Affirmation, favorites []string, triggers []string, shownInCycle []string) []WeightedAffirmation`
     - Deterministic seeding: `hash(userId + date) mod poolSize`
     - Cycle tracking: append to rotationCycleShown, reset when all shown
  3. Implement rotation state management
     - `UpdateRotationState(state *RotationState) error`
     - Validation for mode-specific required fields
- **Files:**
  - `internal/domain/affirmation/rotation.go` (new)
  - `internal/domain/affirmation/rotation_test.go` (new)
- **Depends on:** Agent 2 (types), Agent 3 (level gating)
- **Validates:** AFF-DL-AC1, AFF-DL-AC2, AFF-RO-AC1 through AFF-RO-AC7

#### Agent 5: Custom Affirmation CRUD
- **Spec:** `specs/acceptance-criteria.md` (AFF-CU-*)
- **Scope:**
  1. RED: Write unit tests for custom CRUD
     - `TestAffirmation_AFF_CU_AC1_CreateCustom_Valid`
     - `TestAffirmation_AFF_CU_AC1_CreateCustom_MissingStatement`
     - `TestAffirmation_AFF_CU_AC3_RotationInclusion_Daily`
     - `TestAffirmation_AFF_CU_AC3_RotationInclusion_Weekdays`
     - `TestAffirmation_AFF_CU_AC3_RotationInclusion_Custom`
     - `TestAffirmation_AFF_CU_AC4_EditDelete_Edit`
     - `TestAffirmation_AFF_CU_AC4_EditDelete_Delete`
     - `TestAffirmation_AFF_CU_AC5_MaxCustomLimit`
     - `TestAffirmation_AFF_CU_AC5_MaxCustomLimit_Under`
     - `TestAffirmation_AFF_CU_AC6_UserScoped`
  2. GREEN: Implement custom affirmation service
     - `CreateCustomAffirmation(userId string, req CreateCustomAffirmationRequest) (*CustomAffirmation, error)`
     - `UpdateCustomAffirmation(userId string, id string, req UpdateCustomAffirmationRequest) (*CustomAffirmation, error)`
     - `DeleteCustomAffirmation(userId string, id string) error`
     - `ListCustomAffirmations(userId string) ([]CustomAffirmation, error)`
     - `IsScheduledForToday(schedule string, days []string, today time.Weekday) bool`
     - Enforce 50 max limit per user
- **Files:**
  - `internal/domain/affirmation/custom.go` (new)
  - `internal/domain/affirmation/custom_test.go` (new)
- **Depends on:** Agent 2 (types, validation)
- **Validates:** AFF-CU-AC1 through AFF-CU-AC6

#### Agent 6: Favorites & Progress
- **Spec:** `specs/acceptance-criteria.md` (AFF-FA-*, AFF-IN-AC8)
- **Scope:**
  1. RED: Write unit tests for favorites
     - `TestAffirmation_AFF_FA_AC1_ToggleFavorite_Add`
     - `TestAffirmation_AFF_FA_AC1_ToggleFavorite_Remove`
     - `TestAffirmation_AFF_FA_AC1_ToggleFavorite_CustomAffirmation`
     - `TestAffirmation_AFF_FA_AC2_FavoritesList`
     - `TestAffirmation_AFF_FA_AC3_FavoriteWeighting`
  2. RED: Write unit tests for progress
     - `TestAffirmation_AFF_IN_AC8_CumulativeProgress_Increment`
     - `TestAffirmation_AFF_IN_AC8_CumulativeProgress_CategoryBreakdown`
     - `TestAffirmation_AFF_IN_AC8_CumulativeProgress_LevelBreakdown`
  3. GREEN: Implement favorites service
     - `AddFavorite(userId string, affirmationId string) error`
     - `RemoveFavorite(userId string, affirmationId string) error`
     - `ListFavorites(userId string) ([]Affirmation, error)`
  4. GREEN: Implement progress tracking
     - `RecordRead(userId string, affirmation *Affirmation, source string) error`
     - `GetProgress(userId string) (*AffirmationProgress, error)`
     - `GetReadHistory(userId string, startDate, endDate string) ([]AffirmationRead, error)`
     - Cumulative counters only -- no streak metrics
- **Files:**
  - `internal/domain/affirmation/favorites.go` (new)
  - `internal/domain/affirmation/favorites_test.go` (new)
  - `internal/domain/affirmation/progress.go` (new)
  - `internal/domain/affirmation/progress_test.go` (new)
- **Depends on:** Agent 2 (types)
- **Validates:** AFF-FA-AC1 through AFF-FA-AC3, AFF-IN-AC8

---

### Wave 3: Infrastructure (parallel -- depends on Wave 2)

#### Agent 7: Repository & Cache Layer
- **Spec:** `specs/mongodb-schema.md`, `specs/acceptance-criteria.md` (AFF-DM-AC6, AFF-DM-AC7, AFF-DM-AC10)
- **Scope:**
  1. Define repository interfaces
     - `AffirmationPackRepository` (read-only for system packs)
     - `CustomAffirmationRepository` (CRUD for user custom)
     - `AffirmationFavoriteRepository` (add/remove/list)
     - `AffirmationReadRepository` (record/query)
     - `AffirmationRotationRepository` (get/upsert state)
     - `AffirmationProgressRepository` (get/increment)
  2. Implement MongoDB repository for each interface
     - Enforce immutable CreatedAt (FR2.7)
     - Enforce TenantId on all queries
     - Calendar activity dual-write on read recording
  3. Implement Valkey cache-aside for:
     - Today's affirmation (TTL: until midnight user TZ)
     - Favorites list (TTL: 5 min)
     - Progress data (TTL: 5 min)
     - Pack metadata (TTL: 1 hour)
  4. Write integration tests
     - All repository tests from `specs/test-specifications.md` Section 2.1
     - All cache tests from Section 2.2
- **Files:**
  - `internal/repository/affirmation_repo.go` (new)
  - `internal/repository/affirmation_cache.go` (new)
  - `test/integration/affirmation/repository_test.go` (new)
  - `test/integration/affirmation/cache_test.go` (new)
- **Depends on:** Agent 2 (types), Agent 5 (custom), Agent 6 (favorites, progress)
- **Validates:** AFF-DM-AC6, AFF-DM-AC7, AFF-DM-AC10, AFF-IN-AC5, AFF-IN-AC7

#### Agent 8: HTTP Handler & Middleware
- **Spec:** `specs/openapi.yaml`, `specs/acceptance-criteria.md` (AFF-CC-*, AFF-IN-AC6)
- **Scope:**
  1. Implement affirmation HTTP handler following OpenAPI spec
     - `GET /activities/affirmations/today` -- getTodayAffirmation
     - `GET /activities/affirmations/contextual` -- getContextualAffirmation
     - `GET /activities/affirmations` -- listAffirmations
     - `GET /activities/affirmations/{affirmationId}` -- getAffirmation
     - `GET /activities/affirmations/custom` -- listCustomAffirmations
     - `POST /activities/affirmations/custom` -- createCustomAffirmation
     - `PUT /activities/affirmations/custom/{affirmationId}` -- updateCustomAffirmation
     - `DELETE /activities/affirmations/custom/{affirmationId}` -- deleteCustomAffirmation
     - `GET /activities/affirmations/favorites` -- listFavoriteAffirmations
     - `POST /activities/affirmations/{affirmationId}/favorite` -- addFavoriteAffirmation
     - `DELETE /activities/affirmations/{affirmationId}/favorite` -- removeFavoriteAffirmation
     - `GET /activities/affirmations/rotation` -- getRotationState
     - `PUT /activities/affirmations/rotation` -- updateRotationState
     - `GET /activities/affirmations/progress` -- getAffirmationProgress
     - `GET /activities/affirmations/history` -- getAffirmationReadHistory
     - `GET /activities/affirmations/packs` -- listAffirmationPacks
     - `POST /activities/affirmations/{affirmationId}/share` -- shareAffirmation
     - `GET /activities/affirmations/widget` -- getAffirmationWidget
     - `POST /activities/affirmations/healthy-sexuality/opt-in` -- optInHealthySexuality
     - `DELETE /activities/affirmations/healthy-sexuality/opt-in` -- optOutHealthySexuality
  2. Wire feature flag `activity.affirmations` middleware (fail closed -- 404 when disabled)
  3. Wire Bearer auth middleware
  4. Wire correlation ID middleware
  5. Response envelope: `{ "data": ..., "links": {...}, "meta": {...} }`
  6. Error envelope: `{ "errors": [...] }` with `rr:0x000Axxxx` codes
  7. Cursor-based pagination
  8. RED: Write handler tests
     - `TestAffirmation_AFF_CC_AC1_AuthRequired`
     - `TestAffirmation_AFF_CC_AC2_ErrorEnvelope`
     - `TestAffirmation_AFF_CC_AC3_ResponseEnvelope`
     - `TestAffirmation_AFF_CC_AC4_CursorPagination`
     - `TestAffirmation_AFF_IN_AC6_FeatureFlag_Disabled`
     - `TestAffirmation_AFF_IN_AC6_FeatureFlag_Enabled`
     - `TestAffirmation_AFF_DM_AC7_TenantIsolation`
     - `TestAffirmation_AFF_CC_AC6_CorrelationId`
     - `TestAffirmation_AFF_DM_AC6_ImmutableCreatedAt`
  9. GREEN: Pass all handler tests
- **Files:**
  - `internal/handler/affirmation_handler.go` (new)
  - `internal/handler/affirmation_handler_test.go` (new)
  - `cmd/lambda/activities/affirmation_routes.go` (new -- route wiring)
- **Depends on:** All Wave 2 agents (4, 5, 6), Agent 7 (repository)
- **Validates:** AFF-CC-AC1 through AFF-CC-AC6, AFF-IN-AC6

---

### Wave 4: Platform Integration (parallel -- depends on Wave 3)

#### Agent 9: iOS SwiftUI Views & ViewModel
- **Spec:** `specs/acceptance-criteria.md` (AFF-DL-*, AFF-AU-*, AFF-IN-AC4)
- **Scope:**
  1. Create `AffirmationViewModel`
     - Today's affirmation loading and display
     - Favorite toggle
     - Rotation mode management
     - Level display with progress
     - Audio playback with TTS
     - Headphone disconnect detection and auto-pause (AFF-AU-AC2 -- non-negotiable)
  2. Create `AffirmationView` (main affirmation display)
     - Statement display with scripture reference
     - "Read More" expandable section (expansion + prayer)
     - Favorite button (heart icon)
     - Share button
     - Audio play/pause with speed controls
     - Dark mode gradient background styling
  3. Create `AffirmationBrowseView` (library browse)
     - Pack filter chips
     - Category filter chips
     - Level indicator badges
     - Search bar
     - Paginated list
  4. Create `CustomAffirmationView` (create/edit)
     - Statement text field with character counter
     - Scripture reference field (optional)
     - Category picker
     - Schedule picker (daily/weekdays/weekends/custom)
     - Day-of-week selector (for custom schedule)
  5. Create `AffirmationWidgetCard` for Today screen
     - Truncated statement (100 chars)
     - Cumulative read count
     - Tap to navigate to full affirmation
  6. Create `AffirmationSettingsView`
     - Selection mode picker
     - Active pack selector (for package mode)
     - Day-of-week assignments (for day-of-week mode)
     - Healthy Sexuality opt-in toggle (with sobriety day check)
  7. Wire audio session for headphone disconnect
     - `AVAudioSession.routeChangeNotification`
     - On `.oldDeviceUnavailable` reason, immediately pause
  8. RED: Write ViewModel tests
     - `TestAffirmation_AFF_AU_AC2_HeadphoneDisconnectPause`
     - `TestAffirmation_AFF_DL_AC4_DisplayFields`
     - `TestAffirmation_AFF_DL_AC5_ExpandedView`
     - `TestAffirmation_AFF_IN_AC4_DashboardWidget_Truncation`
- **Files:**
  - `ios/RegalRecovery/RegalRecovery/ViewModels/AffirmationViewModel.swift` (new)
  - `ios/RegalRecovery/RegalRecovery/Views/Activities/AffirmationView.swift` (new)
  - `ios/RegalRecovery/RegalRecovery/Views/Activities/AffirmationBrowseView.swift` (new)
  - `ios/RegalRecovery/RegalRecovery/Views/Activities/CustomAffirmationView.swift` (new)
  - `ios/RegalRecovery/RegalRecovery/Views/Activities/AffirmationSettingsView.swift` (new)
  - `ios/RegalRecovery/RegalRecovery/Views/Today/AffirmationWidgetCard.swift` (new)
  - `ios/RegalRecovery/RegalRecovery/Services/AffirmationAudioService.swift` (new)
  - `ios/RegalRecovery/RegalRecovery/Tests/Unit/AffirmationViewModelTests.swift` (new)
- **Depends on:** Agent 8 (API endpoints to call)
- **Validates:** AFF-DL-AC4, AFF-DL-AC5, AFF-DL-AC6, AFF-DL-AC9, AFF-AU-AC1 through AFF-AU-AC4, AFF-IN-AC4

#### Agent 10: Contract Tests & E2E Tests
- **Spec:** `specs/test-specifications.md` (Sections 3, 4)
- **Scope:**
  1. Write contract tests validating all endpoints against OpenAPI spec
     - All 19 contract tests from `specs/test-specifications.md` Section 3.1
  2. Write E2E tests for complete user flows
     - All 6 E2E flows from `specs/test-specifications.md` Section 4.1
  3. Create test data fixtures for personas (Alex, Marcus, Diego)
  4. Wire sharing and integration event tests
     - `TestAffirmation_AFF_IN_AC10_Sharing_TextFormat`
     - `TestAffirmation_AFF_IN_AC10_Sharing_NoExpansionOrPrayer`
     - `TestAffirmation_AFF_IN_AC5_CalendarActivity`
- **Files:**
  - `test/contract/affirmation_test.go` (new)
  - `test/e2e/affirmation/flow_test.go` (new)
  - `test/fixtures/affirmation_fixtures.go` (new)
  - `internal/domain/affirmation/sharing.go` (new)
  - `internal/domain/affirmation/sharing_test.go` (new)
  - `internal/domain/affirmation/widget.go` (new)
  - `internal/domain/affirmation/widget_test.go` (new)
- **Depends on:** Agent 8 (handler), Agent 7 (repository)
- **Validates:** All AFF-CC-*, AFF-IN-AC5, AFF-IN-AC10

---

## Agent Dispatch Summary

```
Wave 1 (parallel):
  Agent 1:  Content Library & Data Seeding
  Agent 2:  Domain Models & Validation
  Agent 3:  Level Gating Logic (light dependency on Agent 2 types)

Wave 2 (parallel, after Wave 1):
  Agent 4:  Rotation & Selection Engine
  Agent 5:  Custom Affirmation CRUD
  Agent 6:  Favorites & Progress

Wave 3 (parallel, after Wave 2):
  Agent 7:  Repository & Cache Layer
  Agent 8:  HTTP Handler & Middleware

Wave 4 (parallel, after Wave 3):
  Agent 9:  iOS SwiftUI Views & ViewModel
  Agent 10: Contract Tests & E2E Tests
```

**Maximum parallelism:** 3 agents (Waves 1 and 2)
**Total agents:** 10
**Review checkpoints:** After each wave, build + verify before proceeding.

---

## TDD Cycle Per Agent

Each agent follows this cycle:

1. **Read spec** -- agent reads the relevant spec file(s)
2. **RED** -- write failing tests referencing acceptance criteria IDs (AFF-*)
3. **GREEN** -- implement minimum code to pass tests
4. **REFACTOR** -- clean up while keeping tests green
5. **BUILD** -- compilation must succeed
6. **VERIFY** -- run tests, confirm all pass

---

## Verification Gates

| Gate | Command | Criteria |
|------|---------|----------|
| Build (Go) | `go build ./...` | BUILD SUCCEEDED |
| Unit Tests | `go test ./internal/domain/affirmation/...` | All AFF-* tests pass |
| Integration Tests | `go test ./test/integration/affirmation/...` (requires local-up) | All repository + cache tests pass |
| Contract Tests | `go test ./test/contract/...` | All responses validate against openapi.yaml |
| E2E Tests | `go test ./test/e2e/affirmation/...` (requires staging) | All user flows pass |
| Coverage | `go test -coverprofile` | >= 85% overall, 100% for level.go, rotation.go, sharing.go, audio.go |
| Build (iOS) | `xcodebuild -scheme RegalRecovery build` | BUILD SUCCEEDED |
| iOS Tests | `xcodebuild test -scheme RegalRecovery` | All AFF-* SwiftUI tests pass |
| Spec Validation | `make spec-validate` | openapi.yaml is valid |

---

## Error Codes

| Code | Status | Usage |
|------|--------|-------|
| `rr:0x000A0001` | 401 | Authentication required |
| `rr:0x000A0002` | 404 | Affirmation not found |
| `rr:0x000A0003` | 404 | Feature flag disabled |
| `rr:0x000A0004` | 422 | Validation error (statement too long, invalid category, etc.) |
| `rr:0x000A0005` | 422 | Max custom affirmations exceeded (50 limit) |
| `rr:0x000A0006` | 422 | Invalid rotation state (missing required fields for mode) |
| `rr:0x000A0007` | 422 | Custom schedule requires customScheduleDays |
| `rr:0x000A0008` | 422 | healthySexuality category not allowed for custom affirmations |
| `rr:0x000A0010` | 403 | Healthy Sexuality opt-in requires 60+ days |
| `rr:0x000A0011` | 403 | Affirmation above user's current level |
| `rr:0x000A00FF` | 500 | Internal server error |

---

## File Map

All Go files are rooted under `api/`. iOS files are under `ios/RegalRecovery/`.

| New File | Agent | Purpose |
|----------|-------|---------|
| `content/affirmations/affirmations-pack-basic.json` | 1 | 55+ affirmations content |
| `api/scripts/seed/affirmations.js` | 1 | MongoDB seed script |
| `api/test/content/affirmation_content_test.go` | 1 | Content validation |
| `api/internal/domain/affirmation/types.go` | 2 | Domain types |
| `api/internal/domain/affirmation/validation.go` | 2 | Validation logic |
| `api/test/unit/affirmation_validation_test.go` | 2 | Validation tests |
| `api/internal/domain/affirmation/level.go` | 3 | Level gating logic |
| `api/test/unit/affirmation_level_test.go` | 3 | Level gating tests |
| `api/internal/domain/affirmation/rotation.go` | 4 | Rotation & selection |
| `api/test/unit/affirmation_rotation_test.go` | 4 | Rotation tests |
| `api/internal/domain/affirmation/custom.go` | 5 | Custom CRUD |
| `api/test/unit/affirmation_custom_test.go` | 5 | Custom tests |
| `api/internal/domain/affirmation/favorites.go` | 6 | Favorites service |
| `api/test/unit/affirmation_favorites_test.go` | 6 | Favorites tests |
| `api/internal/domain/affirmation/progress.go` | 6 | Progress tracking |
| `api/test/unit/affirmation_progress_test.go` | 6 | Progress tests |
| `api/internal/repository/affirmation_repo.go` | 7 | MongoDB repository |
| `api/internal/cache/affirmation_cache.go` | 7 | Valkey cache |
| `api/test/integration/affirmation/repository_test.go` | 7 | Repository integration tests |
| `api/test/integration/affirmation/cache_test.go` | 7 | Cache integration tests |
| `api/internal/handler/affirmation_handler.go` | 8 | HTTP handler (placeholder) |
| `api/test/unit/affirmation_handler_test.go` | 8 | Handler tests |
| `ios/.../ViewModels/AffirmationViewModel.swift` | 9 | ViewModel |
| `ios/.../Views/Activities/AffirmationView.swift` | 9 | Main display view |
| `ios/.../Views/Activities/AffirmationBrowseView.swift` | 9 | Library browse |
| `ios/.../Views/Activities/CustomAffirmationView.swift` | 9 | Custom create/edit |
| `ios/.../Views/Activities/AffirmationSettingsView.swift` | 9 | Settings |
| `ios/.../Views/Today/AffirmationWidgetCard.swift` | 9 | Dashboard widget |
| `ios/.../Services/AffirmationAudioService.swift` | 9 | Audio + headphone safety |
| `ios/.../Tests/Unit/AffirmationViewModelTests.swift` | 9 | iOS ViewModel tests |
| `api/test/contract/affirmation_test.go` | 10 | Contract tests |
| `api/test/e2e/affirmation/flow_test.go` | 10 | E2E tests |
| `api/test/fixtures/affirmation_fixtures.go` | 10 | Test persona fixtures |
| `api/internal/domain/affirmation/sharing.go` | 10 | Sharing logic |
| `api/test/unit/affirmation_sharing_test.go` | 10 | Sharing tests |
| `api/internal/domain/affirmation/widget.go` | 10 | Widget logic |
| `api/test/unit/affirmation_widget_test.go` | 10 | Widget tests |

---

## Critical Safety Requirements (Non-Negotiable)

1. **Audio auto-pause on headphone disconnect** -- If headphones disconnect during TTS playback, audio MUST pause immediately. This prevents affirmation audio from playing through device speakers in public/unsafe environments.

2. **Post-relapse Level 1 restriction** -- After sobriety reset, user sees ONLY Level 1 (identity, worth, hope) affirmations for 24 hours. Level 2/3 content about growth and leadership can feel invalidating during acute shame.

3. **SOS mode Level 2 cap** -- During crisis (SOS mode active), affirmations never exceed Level 2. Level 3 content about giving back and healthy sexuality is inappropriate during acute distress.

4. **Cumulative progress only** -- Progress is measured in TOTAL affirmations read, not streaks. Streak-based gamification of sobriety is clinically contraindicated for addiction recovery.

5. **Healthy Sexuality double-gate** -- The healthySexuality category requires BOTH 60+ cumulative days AND explicit opt-in. This category addresses sexual health topics that can be triggering for users in early recovery.
