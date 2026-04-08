# Phone Calls Activity -- Multi-Agent Implementation Plan

**Activity:** Phone Calls
**Priority:** P1 (Wave 2)
**Feature Flag:** `activity.phone-calls`

---

## Overview

This plan follows the project's spec-driven, test-first development cycle. Each phase produces artifacts that gate the next phase. Agents work in parallel where dependencies allow.

```
Phase 0: Spec Validation
Phase 1: Contract Tests (RED)
Phase 2: Domain Logic + Repository (GREEN)
Phase 3: Handler + Integration Tests
Phase 4: Mobile Clients
Phase 5: E2E Tests + Verification
```

---

## Agent Roster

| Agent ID | Role | Scope |
|----------|------|-------|
| **A1** | Spec Agent | OpenAPI validation, contract test framework |
| **A2** | Domain Agent | Business logic (streak, trends, validation) |
| **A3** | Repository Agent | MongoDB data access, Valkey caching |
| **A4** | Handler Agent | HTTP handlers, middleware wiring |
| **A5** | Event Agent | SNS/SQS events, notifications, commitment integration |
| **A6** | Android Agent | Kotlin API client, ViewModel, offline sync |
| **A7** | iOS Agent | Swift API client, ViewModel, offline sync |
| **A8** | Test Agent | Integration tests, E2E tests, coverage verification |

---

## Phase 0: Spec Validation (Gate: specs are valid)

**Agent:** A1 (Spec Agent)

### Tasks

1. Validate `specs/openapi.yaml` against OpenAPI 3.1 schema
   ```bash
   redocly lint docs/prd/specific-features/PhoneCalls/specs/openapi.yaml --strict
   ```

2. Verify naming conventions compliance:
   - JSON properties: camelCase
   - URL paths: kebab-case pluralized
   - Schema names: PascalCase
   - Error envelope: `{ "errors": [...] }` format
   - Pagination: cursor-based with `cursor` + `limit`

3. Verify acceptance criteria completeness:
   - Every user story from PRD has at least one AC
   - Every AC has a unique ID
   - Every AC follows Given/When/Then format

4. Register feature flag `activity.phone-calls` in flags configuration

### Output Artifacts
- Validated OpenAPI spec (0 errors)
- Feature flag registration in `FLAGS` collection

### Verification Gate
```bash
redocly lint openapi.yaml --strict  # 0 errors
```

---

## Phase 1: Contract Tests (RED)

**Agent:** A1 (Spec Agent)

**Dependencies:** Phase 0 complete

### Tasks

1. Generate Go types from OpenAPI spec using oapi-codegen:
   ```bash
   oapi-codegen -package phonecalls -generate types \
     -o internal/api/phonecalls/types.go \
     docs/prd/specific-features/PhoneCalls/specs/openapi.yaml
   ```

2. Write contract tests validating request/response schemas:
   - `TestContract_CreatePhoneCall_RequestMatchesSpec`
   - `TestContract_CreatePhoneCall_ResponseMatchesSpec`
   - `TestContract_ListPhoneCalls_ResponseMatchesSpec`
   - `TestContract_GetPhoneCall_ResponseMatchesSpec`
   - `TestContract_UpdatePhoneCall_AcceptsMergePatch`
   - `TestContract_DeletePhoneCall_Returns204`
   - `TestContract_CreateSavedContact_*`
   - `TestContract_GetStreak_ResponseMatchesSpec`
   - `TestContract_GetTrends_ResponseMatchesSpec`
   - `TestContract_ErrorResponse_MatchesSiemensFormat`

3. Run contract tests -- all must FAIL (RED):
   ```bash
   make contract-test  # Expected: all fail
   ```

### Output Artifacts
- `internal/api/phonecalls/types.go` (generated types)
- `test/contract/phonecalls/contract_test.go`

### Verification Gate
```bash
go test ./test/contract/phonecalls/... -v  # All RED (fail)
```

---

## Phase 2: Domain Logic + Repository (GREEN)

**Agents:** A2 (Domain) + A3 (Repository) -- parallel

### Phase 2a: Domain Logic (A2)

**Dependencies:** Phase 1 types generated

#### Tasks

1. Write unit tests FIRST (RED), then implement:

   **Call Log Validation** (`internal/domain/phonecalls/validator.go`):
   - Direction enum validation
   - ContactType enum validation
   - Custom contact type requires label
   - ContactName max length (50)
   - Notes max length (500)
   - Duration non-negative
   - Timestamp immutability enforcement

   ```
   TestPhoneCall_AC_PC_1_CreateWithRequiredFields
   TestPhoneCall_AC_PC_2_DirectionValidation_*
   TestPhoneCall_AC_PC_3_ContactTypeValidation_*
   TestPhoneCall_AC_PC_4_CustomContactType_*
   TestPhoneCall_AC_PC_5_ConnectedStatus_*
   TestPhoneCall_AC_PC_6_OptionalFields_*
   TestPhoneCall_AC_PC_7_ContactName_*
   TestPhoneCall_AC_PC_8_Notes_*
   TestPhoneCall_AC_PC_9_Duration_*
   TestPhoneCall_AC_PC_11_TimestampImmutable_*
   ```

2. **Call Streak Calculator** (`internal/domain/phonecalls/streak.go`):
   - Group calls by user-local calendar date
   - Count consecutive days backward from today
   - Both connected and attempted count
   - Backdate triggers recalculation
   - Delete triggers recalculation

   ```
   TestCallStreak_AC_PC_50_*
   TestCallStreak_AC_PC_51_*
   TestCallStreak_AC_PC_52_*
   TestCallStreak_AC_PC_53_*
   ```

3. **Trends Calculator** (`internal/domain/phonecalls/trends.go`):
   - Connection rate: connectedOutgoing / totalOutgoing * 100
   - Contact type distribution
   - Period comparison
   - Isolation warning detection

   ```
   TestTrends_AC_PC_60_*
   TestTrends_AC_PC_61_*
   TestTrends_AC_PC_62_*
   TestTrends_AC_PC_63_*
   TestTrends_AC_PC_64_*
   ```

4. **Saved Contact Validator** (`internal/domain/phonecalls/saved_contact.go`):
   - Max 10 contacts enforcement
   - Name max length
   - Phone number E.164 format validation

   ```
   TestSavedContact_AC_PC_30_*
   TestSavedContact_AC_PC_31_*
   TestSavedContact_AC_PC_32_*
   ```

#### Output Artifacts
- `internal/domain/phonecalls/validator.go`
- `internal/domain/phonecalls/validator_test.go`
- `internal/domain/phonecalls/streak.go`
- `internal/domain/phonecalls/streak_test.go`
- `internal/domain/phonecalls/trends.go`
- `internal/domain/phonecalls/trends_test.go`
- `internal/domain/phonecalls/saved_contact.go`
- `internal/domain/phonecalls/saved_contact_test.go`

#### Verification Gate
```bash
go test ./internal/domain/phonecalls/... -v -coverprofile=coverage.out
# All GREEN, coverage >= 90% (100% for streak, trends, immutability)
```

---

### Phase 2b: Repository Layer (A3)

**Dependencies:** Phase 1 types generated, MongoDB schema design

#### Tasks

1. Implement phone call repository (`internal/repository/phonecall_repo.go`):
   - `Create(ctx, userId, call)` -- dual-write to calendarActivities
   - `GetByID(ctx, userId, callId)`
   - `List(ctx, userId, filters, cursor, limit)` -- cursor pagination
   - `Update(ctx, userId, callId, patch)` -- prevents timestamp mutation
   - `Delete(ctx, userId, callId)` -- deletes calendar dual-write too
   - `GetByDateRange(ctx, userId, start, end)`

2. Implement saved contact repository (`internal/repository/saved_contact_repo.go`):
   - `Create(ctx, userId, contact)`
   - `List(ctx, userId)`
   - `Update(ctx, userId, savedContactId, patch)`
   - `Delete(ctx, userId, savedContactId)`
   - `Count(ctx, userId)` -- for max 10 enforcement

3. Implement Valkey cache layer (`internal/cache/phone_call_streak_cache.go`):
   - `GetStreak(ctx, userId)` -- cache-aside
   - `InvalidateStreak(ctx, userId)` -- on create/delete
   - 300s TTL

#### Output Artifacts
- `internal/repository/phonecall_repo.go`
- `internal/repository/saved_contact_repo.go`
- `internal/cache/phone_call_streak_cache.go`

#### Verification Gate
- Repository interfaces defined and compile
- Integration tests written (run in Phase 3)

---

## Phase 3: Handler + Integration Tests

**Agents:** A4 (Handler) + A5 (Event) + A8 (Test) -- sequential with overlap

### Phase 3a: HTTP Handlers (A4)

**Dependencies:** Phase 2a + 2b complete

#### Tasks

1. Implement handlers (`internal/handler/phonecall_handler.go`):
   - `POST /activities/phone-calls` -> `createPhoneCallLog`
   - `GET /activities/phone-calls` -> `listPhoneCallLogs`
   - `GET /activities/phone-calls/{callId}` -> `getPhoneCallLog`
   - `PATCH /activities/phone-calls/{callId}` -> `updatePhoneCallLog`
   - `DELETE /activities/phone-calls/{callId}` -> `deletePhoneCallLog`
   - `POST /activities/phone-calls/saved-contacts` -> `createSavedContact`
   - `GET /activities/phone-calls/saved-contacts` -> `listSavedContacts`
   - `PATCH /activities/phone-calls/saved-contacts/{id}` -> `updateSavedContact`
   - `DELETE /activities/phone-calls/saved-contacts/{id}` -> `deleteSavedContact`
   - `GET /activities/phone-calls/streak` -> `getPhoneCallStreak`
   - `GET /activities/phone-calls/trends` -> `getPhoneCallTrends`
   - `GET /activities/phone-calls/trends/daily` -> `getPhoneCallDailyTrends`

2. Wire feature flag middleware:
   - Check `activity.phone-calls` flag on every request
   - Return 404 if flag disabled (fail closed)

3. Wire auth middleware:
   - Bearer token validation
   - Extract userId from JWT
   - Tenant isolation enforcement

4. Wire permission middleware for support network access:
   - Check `phone-calls` permission for third-party reads
   - Return 404 (not 403) if permission not granted

#### Output Artifacts
- `internal/handler/phonecall_handler.go`
- `internal/handler/phonecall_handler_test.go`

#### Verification Gate
```bash
go test ./internal/handler/... -run PhoneCall -v
# Contract tests now GREEN
make contract-test  # PASS
```

---

### Phase 3b: Event Processing (A5)

**Dependencies:** Phase 3a handlers complete

#### Tasks

1. Publish events on call creation/deletion:
   - `phonecall.created` -> SNS topic
   - `phonecall.deleted` -> SNS topic

2. Event consumers:
   - **Isolation Warning Consumer:** Check days since last call, create notification if threshold exceeded
   - **Streak Milestone Consumer:** Check if streak hits milestone, create notification
   - **Commitment Consumer:** Increment commitment progress if user has daily call commitment
   - **Tracking Consumer:** Update tracking system with call-streak data

3. Notification templates:
   - Daily call reminder
   - Missed call streak nudge
   - Streak milestone celebration
   - Commitment reminder

#### Output Artifacts
- `internal/events/phonecall_events.go`
- `internal/events/phonecall_consumers.go`

---

### Phase 3c: Integration Tests (A8)

**Dependencies:** Phase 3a + 3b complete

#### Tasks

1. Write and run integration tests against local MongoDB + Valkey:
   ```
   TestPhoneCallRepository_Create_PersistsToMongoDB
   TestPhoneCallRepository_Create_WritesCalendarActivityDualWrite
   TestPhoneCallRepository_GetByDateRange_ReturnsCorrectEntries
   TestPhoneCallRepository_CursorPagination_*
   TestSavedContactRepository_*
   TestStreakCache_*
   TestPhoneCallEvent_*
   ```

2. Run full test suite:
   ```bash
   make local-up
   make test-integration -run PhoneCall
   make local-down
   ```

#### Verification Gate
```bash
make test-integration -run PhoneCall  # All GREEN
make coverage  # >= 80% overall, 100% critical paths
```

---

## Phase 4: Mobile Clients (parallel)

**Agents:** A6 (Android) + A7 (iOS) -- fully parallel

### Phase 4a: Android (A6)

**Dependencies:** Phase 3a handlers deployed to staging (or mock server)

#### Tasks

1. Hand-write Kotlin API client (`PhoneCallApiClient.kt`):
   - All 12 endpoints from OpenAPI spec
   - Retrofit/OkHttp integration
   - Request/response models matching spec

2. ViewModel (`PhoneCallViewModel.kt`):
   - Quick log flow with defaults
   - Duration quick-select mapping
   - Contact name autocomplete from saved contacts
   - Streak display formatting
   - Rotating encouraging post-log messages
   - Isolation warning display logic

3. Offline sync (`PhoneCallOfflineQueue.kt`):
   - Queue calls when offline
   - Sync in chronological order on reconnect
   - Union merge conflict resolution

4. UI tests:
   - Call logging screen
   - Call history list with filters
   - Saved contacts management
   - Dashboard widget
   - Dark mode color compliance

#### Output Artifacts
- `androidApp/app/src/main/java/com/regalrecovery/data/api/PhoneCallApiClient.kt`
- `androidApp/app/src/main/java/com/regalrecovery/ui/phonecalls/PhoneCallViewModel.kt`
- `androidApp/app/src/main/java/com/regalrecovery/sync/PhoneCallOfflineQueue.kt`
- Unit + UI tests

---

### Phase 4b: iOS (A7)

**Dependencies:** Phase 3a handlers deployed to staging (or mock server)

#### Tasks

1. Hand-write Swift API client (`PhoneCallAPIClient.swift`):
   - All 12 endpoints from OpenAPI spec
   - URLSession integration
   - Codable request/response models matching spec

2. ViewModel (`PhoneCallViewModel.swift`):
   - Quick log flow with defaults
   - Duration quick-select mapping
   - Contact name autocomplete from saved contacts
   - Streak display formatting
   - Rotating encouraging post-log messages
   - Isolation warning display logic

3. Offline sync (`PhoneCallOfflineSync.swift`):
   - SwiftData local persistence
   - Sync engine with union merge

4. UI tests:
   - SwiftUI views for call logging, history, contacts
   - Dashboard widget
   - Dark mode compliance

#### Output Artifacts
- `iosApp/RegalRecovery/Data/API/PhoneCallAPIClient.swift`
- `iosApp/RegalRecovery/UI/PhoneCalls/PhoneCallViewModel.swift`
- `iosApp/RegalRecovery/Sync/PhoneCallOfflineSync.swift`
- XCTest unit + UI tests

---

## Phase 5: E2E Tests + Verification

**Agent:** A8 (Test Agent)

**Dependencies:** Phases 3 + 4 complete, staging deployed

### Tasks

1. Deploy to staging:
   ```bash
   make deploy-staging
   ```

2. Run E2E tests against staging:
   ```
   TestE2E_PhoneCall_CreateReadUpdateDelete_FullLifecycle
   TestE2E_PhoneCall_QuickLog_ThenExpand_FullFlow
   TestE2E_PhoneCall_BackdatedCall_StreakRecalculated
   TestE2E_SavedContact_CreateAndUseInCallLog
   TestE2E_SavedContact_MaxTenEnforced
   TestE2E_Trends_30DaySummary_ReturnsAccurateData
   TestE2E_SupportNetwork_SponsorWithPermission_SeesCallLogs
   TestE2E_SupportNetwork_SponsorWithoutPermission_Gets404
   TestE2E_Integration_CallLogFeedsTrackingSystem
   TestE2E_Integration_CallLogFulfillsCommitment
   ```

3. Verify contract tests pass against deployed API:
   ```bash
   make contract-test
   ```

4. Verify coverage thresholds:
   ```bash
   make coverage-check  # >= 80% overall, 100% critical
   ```

### Verification Gate (Final)
```bash
make test-all        # Unit + integration GREEN
make test-e2e        # E2E GREEN
make contract-test   # Contract tests GREEN
make coverage-check  # Coverage thresholds met
```

---

## Dependency Graph

```
Phase 0 (Spec Validation)
    |
    v
Phase 1 (Contract Tests - RED)
    |
    ├──────────────────┐
    v                  v
Phase 2a (Domain)    Phase 2b (Repository)
    |                  |
    ├──────────────────┘
    v
Phase 3a (Handlers)
    |
    ├──────────────────┐
    v                  v
Phase 3b (Events)   Phase 3c (Integration Tests)
    |                  |
    ├──────────────────┘
    |
    ├──────────────────┐
    v                  v
Phase 4a (Android)   Phase 4b (iOS)
    |                  |
    ├──────────────────┘
    v
Phase 5 (E2E + Final Verification)
```

---

## PR Strategy

Split into stacked PRs targeting < 400 lines each:

| PR # | Title | Content | Lines (est) |
|------|-------|---------|-------------|
| 1 | `spec: add phone calls OpenAPI spec and acceptance criteria` | openapi.yaml, acceptance-criteria.md, mongodb-schema.md, test-specifications.md | ~300 |
| 2 | `feat(phone-calls): add contract tests and generated types` | types.go, contract_test.go | ~250 |
| 3 | `feat(phone-calls): add domain logic (validation, streak, trends)` | validator.go, streak.go, trends.go, saved_contact.go + all unit tests | ~400 |
| 4 | `feat(phone-calls): add repository layer and cache` | phonecall_repo.go, saved_contact_repo.go, streak_cache.go | ~300 |
| 5 | `feat(phone-calls): add HTTP handlers and middleware wiring` | phonecall_handler.go + handler tests | ~350 |
| 6 | `feat(phone-calls): add event processing and notifications` | events.go, consumers.go | ~250 |
| 7 | `feat(phone-calls): add integration tests` | integration test files | ~300 |
| 8 | `feat(phone-calls): add Android API client and ViewModel` | Kotlin files + tests | ~400 |
| 9 | `feat(phone-calls): add iOS API client and ViewModel` | Swift files + tests | ~400 |
| 10 | `feat(phone-calls): add E2E tests` | E2E test files | ~200 |

---

## Quality Gates Per PR

Each PR must pass before merge:

- [ ] OpenAPI spec valid (if changed): `redocly lint`
- [ ] Contract tests pass: `make contract-test`
- [ ] Unit tests pass: `make test-unit`
- [ ] Coverage >= 80% (100% for critical paths)
- [ ] No linting errors: `make lint`
- [ ] Test names reference acceptance criteria (AC-PC-*)
- [ ] No hardcoded colors (dark mode compatible)
- [ ] Feature flag `activity.phone-calls` gating verified

---

## Timeline Estimate

| Phase | Duration | Parallelism |
|-------|----------|-------------|
| Phase 0 | 0.5 day | -- |
| Phase 1 | 1 day | -- |
| Phase 2 | 2 days | A2 + A3 parallel |
| Phase 3 | 2 days | A4 -> A5 + A8 |
| Phase 4 | 3 days | A6 + A7 parallel |
| Phase 5 | 1 day | -- |
| **Total** | **~9.5 days** | **5 agents parallel at peak** |
