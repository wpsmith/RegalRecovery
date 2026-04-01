# Regal Recovery -- Development Workflow Specification

**Version:** 1.0.0
**Date:** 2026-03-28
**Status:** Draft

---

## Table of Contents

1. [Development Philosophy](#1-development-philosophy)
2. [Spec-Driven + TDD Development Cycle](#2-spec-driven--tdd-development-cycle)
3. [Project Structure: Go Backend](#3-project-structure-go-backend)
4. [Project Structure: Native Mobile Apps](#4-project-structure-native-mobile-apps)
5. [Code Generation Pipeline](#5-code-generation-pipeline)
6. [Test Strategy](#6-test-strategy)
7. [Makefile Targets](#7-makefile-targets)
8. [Local Development Environment](#8-local-development-environment)
9. [Pull Request Workflow](#9-pull-request-workflow)
10. [CI/CD Pipeline](#10-cicd-pipeline)
11. [Branching Strategy](#11-branching-strategy)
12. [Dependency Management](#12-dependency-management)

---

## 1. Development Philosophy

Every line of production code traces back to an acceptance criterion in the PRD, through an OpenAPI contract, through a failing test. This traceability chain ensures that:

- **Nothing is built without a spec.** The OpenAPI specification is the single source of truth for the API contract between backend and mobile.
- **Nothing ships without a test.** Tests are written before implementation (TDD). A feature is not "done" until tests pass, coverage meets threshold, and the spec is satisfied.
- **OpenAPI specs are validated by contract tests.** Developers write Go handlers, Kotlin API clients (Android), and Swift API clients (iOS) by hand, conforming to the OpenAPI spec. Contract tests validate that implementations match the spec exactly -- no code generation tools are used.

---

## 2. Spec-Driven + TDD Development Cycle

```
PRD Acceptance Criteria
        |
        v
OpenAPI 3.1 Specification (contract)
        |
        v
Write contract tests from spec (RED)
        |
        v
Implement handlers to pass tests (GREEN)
        |
        v
Validate implementation against OpenAPI spec (contract tests)
        |
        v
Refactor while tests stay green (REFACTOR)
        |
        v
Deploy to staging --> Run E2E tests
        |
        v
PR review against spec compliance
```

### Step-by-Step Workflow

#### Step 1: PRD Acceptance Criteria --> OpenAPI Spec

1. Product defines acceptance criteria in the PRD (e.g., "User can log an urge with intensity 1-10, triggers, and optional notes").
2. Developer translates acceptance criteria into OpenAPI 3.1 YAML. Each endpoint, request schema, response schema, error code, and query parameter is defined.
3. Spec is validated with `make spec-validate` before any code is written.
4. Spec PR is reviewed by both backend and mobile developers to confirm the contract works for both sides.

#### Step 2: OpenAPI Spec --> Contract Tests (RED)

1. Write contract tests that validate request/response schemas against the OpenAPI spec.
2. Write unit tests that assert the behavior defined in the acceptance criteria: valid inputs produce expected outputs, invalid inputs produce expected errors, edge cases are covered.
3. Name test functions after the acceptance criterion they verify: `TestUrgeLog_AC2_3_IntensityRange`, `TestCheckIn_FR2_6_CompleteHistory`.
4. All tests must fail at this stage. If a test passes before implementation, the test is not testing anything meaningful.

#### Step 3: Implement Handlers (GREEN)

1. Write Go handlers in `internal/domain/<domain>/` that conform to the API contract defined in the OpenAPI spec. Define request/response types by hand to match the spec schemas.
2. Business logic lives in `internal/domain/<domain>/`. Handlers are thin -- they parse the request, call domain logic, and format the response.
3. Repository access goes through `internal/repository/` interfaces. Never call DynamoDB directly from a handler.
4. Run tests after each handler implementation. Stop when all tests pass.

#### Step 5: Refactor (REFACTOR)

1. With green tests, refactor for clarity, performance, and adherence to project conventions.
2. Extract shared logic, reduce duplication, improve naming.
3. Run `make test-unit` after each refactoring pass. Tests must stay green.

#### Step 6: Deploy to Staging --> E2E Tests

1. Push to feature branch. CI runs unit tests, integration tests, linting, and spec validation.
2. On merge to `develop`, CD deploys to staging environment.
3. E2E tests run against the staging API to verify the full request path: API Gateway --> Lambda --> DynamoDB --> Response.

#### Step 7: PR Review Against Spec Compliance

1. Reviewer verifies that the implementation matches the OpenAPI spec.
2. Reviewer checks that test names reference acceptance criteria.
3. Reviewer confirms contract tests validate against the OpenAPI spec.
4. See [PR Checklist](#pr-checklist) for the complete list.

---

## 3. Project Structure: Go Backend

```
regal-recovery-api/
|
+-- specs/
|   +-- openapi/                    # OpenAPI YAML specs (SOURCE OF TRUTH)
|   |   +-- auth.yaml               # Auth domain endpoints
|   |   +-- users.yaml              # Users domain endpoints
|   |   +-- tracking.yaml           # Tracking domain endpoints
|   |   +-- activities.yaml         # Activities domain endpoints
|   |   +-- content.yaml            # Content domain endpoints
|   |   +-- community.yaml          # Community domain endpoints
|   |   +-- analytics.yaml          # Analytics domain endpoints
|   |   +-- tools.yaml              # Tools domain endpoints
|   |   +-- assessments.yaml        # Assessments domain endpoints
|   |   +-- notifications.yaml      # Notifications domain endpoints
|   |   +-- integrations.yaml       # Integrations domain endpoints
|   |   +-- backup.yaml             # Backup domain endpoints
|   |   +-- agent.yaml              # Agent domain endpoints
|   |   +-- admin.yaml              # Admin domain endpoints
|   |   +-- _shared/                # Shared schemas, parameters, responses
|   |   |   +-- schemas.yaml        # Common types (Pagination, Error, etc.)
|   |   |   +-- parameters.yaml     # Common query params (cursor, limit, filter)
|   |   |   +-- responses.yaml      # Common response shapes (400, 401, 403, 404, 429, 500)
|   |   |   +-- security.yaml       # Security schemes (Bearer token, scopes)
|   |   +-- openapi.yaml            # Root spec that references all domain specs
|
+-- internal/
|   +-- domain/                      # Business logic per bounded context
|   |   +-- tracking/                # Streak calculation, milestone detection, relapse handling
|   |   |   +-- service.go           # StreakService, MilestoneService
|   |   |   +-- calculator.go        # Streak calculation logic
|   |   |   +-- events.go            # Domain events (MilestoneAchieved, RelapseRecorded)
|   |   +-- activities/              # Activity logging handlers
|   |   |   +-- service.go           # ActivityService
|   |   |   +-- validators.go        # Input validation per activity type
|   |   +-- community/               # Permissions, messaging, support network
|   |   |   +-- permissions.go       # Permission grant/revoke logic
|   |   |   +-- messaging.go         # Message send/receive, conversation management
|   |   |   +-- network.go           # Support contact invite/accept/remove
|   |   +-- analytics/               # Recovery Health Score, trends, correlations
|   |   |   +-- health_score.go      # RHS calculation algorithm
|   |   |   +-- trends.go            # Trend analysis
|   |   |   +-- correlations.go      # Cross-activity correlation logic
|   |   +-- content/                 # Affirmations, devotionals, packs
|   |   |   +-- service.go           # ContentService
|   |   |   +-- rotation.go          # Affirmation rotation algorithm
|   |   +-- auth/                    # Auth-specific business logic (not Cognito SDK calls)
|   |   |   +-- session.go           # Session management logic
|   |   +-- tools/                   # Three Circles, RPP, Vision, Arousal Template
|   |   +-- assessments/             # Assessment scoring logic
|   |   +-- notifications/           # Notification scheduling, dispatch logic
|   |   +-- backup/                  # Backup/restore orchestration
|   |   +-- agent/                   # AI agent conversation handling
|   |   +-- admin/                   # Tenant management, content admin
|   |
|   +-- repository/                  # DynamoDB data access layer
|   |   +-- dynamo.go                # DynamoDB client wrapper, connection management
|   |   +-- user_repo.go             # User CRUD operations
|   |   +-- activity_repo.go         # Activity read/write operations
|   |   +-- tracking_repo.go         # Streak, milestone, relapse persistence
|   |   +-- community_repo.go        # Contacts, permissions, messages
|   |   +-- content_repo.go          # Affirmation packs, devotionals
|   |   +-- notification_repo.go     # Notification persistence
|   |   +-- analytics_repo.go        # RHS snapshots, trend data
|   |   +-- audit_repo.go            # Audit trail writes
|   |   +-- interfaces.go            # Repository interfaces (for testing)
|   |
|   +-- middleware/                   # HTTP middleware chain
|   |   +-- auth.go                  # JWT validation, claims extraction
|   |   +-- tenant.go                # Tenant context injection and isolation
|   |   +-- logging.go               # Structured request/response logging
|   |   +-- correlation.go           # X-Correlation-Id generation and propagation
|   |   +-- ratelimit.go             # Per-user rate limiting (backed by Valkey)
|   |   +-- recovery.go              # Panic recovery middleware
|   |
|   +-- cache/                       # Valkey (Redis-compatible) cache layer
|   |   +-- valkey.go                # Valkey client wrapper
|   |   +-- streak_cache.go          # Streak cache-aside pattern
|   |   +-- dashboard_cache.go       # Dashboard data caching
|   |
|   +-- config/                      # Environment configuration
|   |   +-- config.go                # Struct-based config loaded from env/SSM
|   |   +-- environments.go          # Per-environment overrides (dev, staging, prod)
|   |
|   +-- events/                      # Event publishing (SNS/SQS)
|   |   +-- publisher.go             # Event publish interface
|   |   +-- sns.go                   # SNS publisher implementation
|   |   +-- types.go                 # Event type definitions
|
+-- cmd/
|   +-- lambda/                      # Lambda handler entrypoints
|   |   +-- auth/main.go             # Auth function group
|   |   +-- tracking/main.go         # Tracking function group
|   |   +-- activities/main.go       # Activities function group
|   |   +-- content/main.go          # Content function group
|   |   +-- community/main.go        # Community function group
|   |   +-- analytics/main.go        # Analytics function group
|   |   +-- tools/main.go            # Tools function group
|   |   +-- notifications/main.go    # Notification function group
|   |   +-- backup/main.go           # Backup function group
|   |   +-- agent/main.go            # Agent function group
|   |   +-- admin/main.go            # Admin function group
|
+-- test/
|   +-- unit/                        # Unit tests per domain
|   |   +-- tracking/                # Streak calc, milestone detection tests
|   |   +-- activities/              # Activity validation, handler tests
|   |   +-- community/               # Permission logic tests
|   |   +-- analytics/               # RHS calculation tests
|   |   +-- content/                 # Rotation algorithm tests
|   +-- integration/                 # LocalStack integration tests
|   |   +-- repository/              # DynamoDB repository tests against LocalStack
|   |   +-- cache/                   # Valkey cache tests
|   |   +-- events/                  # SNS/SQS event publishing tests
|   +-- e2e/                         # End-to-end API tests
|   |   +-- auth_test.go             # Full auth flow tests
|   |   +-- tracking_test.go         # Full tracking flow tests
|   |   +-- activities_test.go       # Full activity logging tests
|   +-- fixtures/                    # Test data fixtures
|   |   +-- users.json               # Sample user data
|   |   +-- activities.json          # Sample activity data
|   +-- helpers/                     # Shared test utilities
|       +-- dynamo_helper.go         # LocalStack DynamoDB setup/teardown
|       +-- auth_helper.go           # Test token generation
|       +-- assertions.go            # Custom assertion helpers
|
+-- Makefile                         # Build, test, generate, deploy commands
+-- docker-compose.yml               # LocalStack + Valkey for local dev
+-- go.mod
+-- go.sum
+-- .golangci.yml                    # Linter configuration
+-- .goreleaser.yml                  # Release configuration
|
+-- cdk/                             # AWS CDK infrastructure (TypeScript)
    +-- bin/app.ts                   # CDK app entrypoint
    +-- lib/
    |   +-- api-stack.ts             # API Gateway + Lambda stack
    |   +-- data-stack.ts            # DynamoDB + S3 stack
    |   +-- cache-stack.ts           # Valkey (ElastiCache) stack
    |   +-- auth-stack.ts            # Cognito stack
    |   +-- messaging-stack.ts       # SQS + SNS stack
    |   +-- observability-stack.ts   # CloudWatch + X-Ray stack
    |   +-- cdn-stack.ts             # CloudFront stack
    +-- test/                        # CDK infrastructure tests
    +-- cdk.json
    +-- tsconfig.json
    +-- package.json
```

### Key Conventions

- **`internal/domain/` owns business logic and API handlers.** Handlers are written by hand to conform to the OpenAPI spec. Domain services have no knowledge of HTTP, Lambda, or DynamoDB. They accept and return domain types. Request/response types are defined manually to match the OpenAPI schemas and validated by contract tests.
- **`internal/repository/` owns data access.** All DynamoDB operations are behind interfaces defined in `interfaces.go`. Unit tests mock these interfaces; integration tests use LocalStack.
- **`cmd/lambda/` is thin.** Each Lambda entrypoint wires together middleware, domain services, and repository implementations. No business logic lives here.
- **One Lambda per domain group.** Each domain (auth, tracking, activities, etc.) maps to one Lambda function. API Gateway routes to the correct function by path prefix. This keeps cold starts fast while avoiding one-function-per-endpoint sprawl.

---

## 4. Project Structure: Native Mobile Apps

Each mobile platform is built natively with its own business logic, data layer, and UI.

### Android App (Kotlin + Jetpack Compose)

```
androidApp/
|
+-- app/
|   +-- src/
|       +-- main/
|       |   +-- java/com/regalrecovery/
|       |   |   +-- domain/                  # Domain models and business logic
|       |   |   |   +-- model/               # Data classes: User, Streak, Activity, etc.
|       |   |   |   +-- usecase/             # Use cases: LogUrge, GetStreaks, SubmitCheckIn
|       |   |   |   +-- validation/          # Input validation rules
|       |   |   +-- data/                    # Data layer
|       |   |   |   +-- repository/          # Repository implementations
|       |   |   |   +-- api/                 # Hand-written API client (conforms to OpenAPI spec)
|       |   |   |   +-- local/              # Room database, DAOs, entities
|       |   |   |   +-- mapper/             # DTO <-> Domain model mappers
|       |   |   +-- sync/                    # Offline queue and conflict resolution
|       |   |   |   +-- OfflineQueue.kt      # Queues writes when offline
|       |   |   |   +-- SyncEngine.kt        # Replays queue on reconnection
|       |   |   |   +-- ConflictResolver.kt  # Domain-specific merge strategies (FR4.3)
|       |   |   +-- di/                      # Dependency injection (Hilt modules)
|       |   |   +-- ui/                      # Jetpack Compose UI screens and components
|       |   |   |   +-- home/                # Dashboard screen
|       |   |   |   +-- tracking/            # Streak, calendar, milestone screens
|       |   |   |   +-- activities/          # Check-in, journal, urge log screens
|       |   |   |   +-- tools/               # Three Circles, RPP, Vision screens
|       |   |   |   +-- community/           # Messaging, support network screens
|       |   |   |   +-- settings/            # Settings, profile, privacy screens
|       |   |   |   +-- theme/               # Material 3 theme, colors, typography
|       |   |   |   +-- components/          # Reusable UI components
|       |   |   +-- navigation/              # Navigation graph
|       |   |   +-- notification/            # Android notification channels, FCM handler
|       |   |   +-- biometric/               # BiometricPrompt integration
|       |   |   +-- util/                    # Utilities (date/time, formatting)
|       |   +-- res/                         # Android resources
|       +-- test/                            # Unit tests
|       +-- androidTest/                     # Instrumented tests
|
+-- build.gradle.kts                         # App-level Gradle build
+-- gradle/
    +-- libs.versions.toml                   # Gradle version catalog
```

### iOS App (Swift + SwiftUI)

```
iosApp/
|
+-- RegalRecovery/
|   +-- Domain/                              # Domain models and business logic
|   |   +-- Model/                           # Structs: User, Streak, Activity, etc.
|   |   +-- UseCase/                         # Use cases: LogUrge, GetStreaks, SubmitCheckIn
|   |   +-- Validation/                      # Input validation rules
|   +-- Data/                                # Data layer
|   |   +-- Repository/                      # Repository implementations
|   |   +-- API/                             # Hand-written API client (conforms to OpenAPI spec)
|   |   +-- Local/                           # SwiftData models and persistence
|   |   +-- Mapper/                          # DTO <-> Domain model mappers
|   +-- Sync/                                # Offline queue and conflict resolution
|   |   +-- OfflineQueue.swift               # Queues writes when offline
|   |   +-- SyncEngine.swift                 # Replays queue on reconnection
|   |   +-- ConflictResolver.swift           # Domain-specific merge strategies (FR4.3)
|   +-- Views/                               # SwiftUI views
|   |   +-- Home/                            # Dashboard screen
|   |   +-- Tracking/                        # Streak, calendar, milestone screens
|   |   +-- Activities/                      # Check-in, journal, urge log screens
|   |   +-- Tools/                           # Three Circles, RPP, Vision screens
|   |   +-- Community/                       # Messaging, support network screens
|   |   +-- Settings/                        # Settings, profile, privacy screens
|   |   +-- Components/                      # Reusable UI components
|   +-- Navigation/                          # iOS navigation
|   +-- Notifications/                       # APNS handler
|   +-- Biometric/                           # Face ID / Touch ID integration
|   +-- DI/                                  # Dependency injection (native Swift DI)
|   +-- Util/                                # Utilities (date/time, formatting)
|   +-- Resources/                           # iOS assets
|
+-- RegalRecoveryTests/                      # Unit tests
+-- RegalRecoveryUITests/                    # UI tests
+-- Package.swift                            # Swift Package Manager dependencies
```

### Key Conventions

- **Each platform implements its own business logic natively.** Android uses Kotlin; iOS uses Swift. There is no shared module.
- **`androidApp/.../data/api/`** and **`iosApp/.../Data/API/`** hold hand-written API client code that conforms to the OpenAPI spec. Contract tests validate that the clients match the spec.
- **Each platform implements its own offline-first sync engine.** Android uses `OfflineQueue.kt` + `SyncEngine.kt`; iOS uses `OfflineQueue.swift` + `SyncEngine.swift`. Both apply domain-specific merge rules (union merge for relapse/urge logs, most-conservative for sobriety dates, LWW for profile changes) per FR4.1-FR4.5.
- **Android uses Jetpack Compose for UI; iOS uses SwiftUI.**
- **Android uses Room for local persistence; iOS uses SwiftData.**
- **Android uses Hilt for DI; iOS uses native Swift dependency injection.**

---

## 5. Spec Validation & Contract Testing

### Approach

The OpenAPI specs remain the single source of truth for the API contract, but no code generation tools are used. Developers write Go handlers and Kotlin API clients by hand, and contract tests validate that implementations conform to the spec.

### Go Backend

**What you write by hand:**
- Request/response type structs in `internal/domain/<domain>/types.go` with JSON tags matching the OpenAPI schemas
- Handler functions in `internal/domain/<domain>/handler.go` that parse requests, call domain logic, and format responses
- Each handler delegates to domain services in `internal/domain/`

**How the spec is enforced:**
- Contract tests load the OpenAPI spec and validate that handler responses match the defined schemas (field names, types, required fields, enum values)
- `make spec-validate` validates the spec itself against OpenAPI 3.1 schema rules
- `make contract-test` runs all contract tests to verify implementations match the spec

### Android Mobile Client (Kotlin + Jetpack Compose)

**What you write by hand:**
- API client classes with suspend functions for each endpoint in `androidApp/.../data/api/`
- Data classes for all request/response models
- Enum classes for string enumerations
- Room entities and DAOs for local persistence

**How the spec is enforced:**
- Contract tests validate that Kotlin data classes serialize/deserialize correctly against OpenAPI schema examples
- Repository implementations in `androidApp/.../data/repository/` wrap the hand-written API calls
- Offline queue integration in repository implementations

### iOS Mobile Client (Swift + SwiftUI)

**What you write by hand:**
- API client structs with async functions for each endpoint in `iosApp/.../Data/API/`
- Codable structs for all request/response models
- Enums for string enumerations
- SwiftData models for local persistence

**How the spec is enforced:**
- Contract tests validate that Swift Codable structs serialize/deserialize correctly against OpenAPI schema examples
- Repository implementations in `iosApp/.../Data/Repository/` wrap the hand-written API calls
- Offline queue integration in repository implementations

### Spec Validation Rules

1. **Spec changes require contract test updates.** Any PR that modifies an OpenAPI spec file must also update the corresponding contract tests and handler/client types to match.
2. **Contract tests run in CI.** Every PR runs `make contract-test` to verify that all handlers and client types conform to the OpenAPI spec.
3. **Spec is the authority.** If a contract test fails, the implementation is wrong -- update the handler or client types to match the spec.

---

## 6. Test Strategy

### Test Pyramid

```
        /   E2E Tests   \            ~10% of tests
       /  (staging API)   \          Full request path validation
      /--------------------\
     / Integration Tests    \        ~20% of tests
    /  (LocalStack, Valkey)  \       Repository, cache, event tests
   /--------------------------\
  /      Unit Tests            \     ~70% of tests
 /  (domain logic, handlers)    \    Fast, isolated, no I/O
/________________________________\
```

### Unit Tests

**Location:** `test/unit/<domain>/`

**Scope:** Business logic in `internal/domain/`, handler logic, input validation, error mapping.

**Dependencies:** All external dependencies (repositories, caches, event publishers) are mocked via interfaces.

**Naming convention:** `Test<Entity>_<AcceptanceCriteria>_<Scenario>`

```go
// Example: test/unit/tracking/streak_test.go
func TestStreak_FR2_2_CalculatesCurrentStreakInRealTime(t *testing.T) { ... }
func TestStreak_FR2_2_HandlesTimezoneTransitions(t *testing.T) { ... }
func TestStreak_NFR2_5_100PercentAccuracyAcrossTimezones(t *testing.T) { ... }
```

**Coverage threshold:** 80% minimum per package. Domain packages target 90%+.

### Integration Tests

**Location:** `test/integration/`

**Scope:** DynamoDB repository operations against LocalStack, Valkey cache operations, SNS/SQS event publishing and consumption.

**Setup:** `docker-compose up` starts LocalStack and Valkey. Test helpers in `test/helpers/` create and tear down tables, seed data, and manage state between tests.

```go
// Example: test/integration/repository/activity_repo_test.go
func TestActivityRepo_WritesUrgeLogToDynamoDB(t *testing.T) { ... }
func TestActivityRepo_QueriesCheckInsByDateRange(t *testing.T) { ... }
func TestActivityRepo_PaginatesCursorBased(t *testing.T) { ... }
```

**Key integration test scenarios:**
- Single-table design access patterns (every pattern in the table design spec must have a test)
- GSI queries return correct results
- TTL-based expiration works for ephemeral data
- Tenant isolation: User A cannot read User B data
- Optimistic locking with conditional writes
- Valkey cache-aside pattern (cache miss -> DB read -> cache write -> cache hit)

### End-to-End Tests

**Location:** `test/e2e/`

**Scope:** Full API request path against a deployed staging environment. Tests authenticate via Cognito, make real HTTP requests, and assert responses.

**Execution:** Run after staging deployment in CI/CD pipeline.

```go
// Example: test/e2e/tracking_test.go
func TestE2E_UserRegistersAndLogsFirstUrge(t *testing.T) { ... }
func TestE2E_RelapseResetsStreakAndTriggersPostMortem(t *testing.T) { ... }
func TestE2E_SponsorCanViewSharedDataOnly(t *testing.T) { ... }
```

### Contract Tests

**Scope:** Validate that the API implementation matches the OpenAPI specification exactly.

**Approach:** Middleware validates every request and response against the spec during integration and E2E tests. Any deviation (missing field, wrong type, extra field not in spec) fails the test.

### Load Tests

**Tool:** k6

**Targets (from NFR3):**
- 500,000 concurrent users
- 10,000 writes/second
- 50,000 API requests/minute

**Execution:** Run on a schedule (weekly) against a dedicated load-test environment. Not part of every PR cycle.

### Security Tests

**Tools:** OWASP ZAP (DAST), AWS Inspector, custom tenant-isolation tests

**Scope:**
- OWASP Top 10 compliance (NFR4.6)
- Tenant isolation verification (Section 10.3.10)
- Rate limiting enforcement
- JWT validation edge cases (expired, tampered, wrong audience)
- IDOR prevention across users

---

## 7. Makefile Targets

```makefile
# ============================================================================
# Spec & Generation
# ============================================================================

spec-validate:            ## Validate all OpenAPI specs against OpenAPI 3.1 schema
	@echo "Validating OpenAPI specs..."
	npx @redocly/cli lint specs/openapi/openapi.yaml

contract-test:            ## Run contract tests validating implementations against OpenAPI specs
	@echo "Running contract tests..."
	go test ./test/contract/... -v -race -count=1

spec-docs:                ## Generate interactive API documentation (Redoc)
	npx @redocly/cli build-docs specs/openapi/openapi.yaml \
	  -o docs/api/index.html

# ============================================================================
# Testing
# ============================================================================

test-unit:                ## Run unit tests
	go test ./test/unit/... -v -race -count=1

test-integration:         ## Run integration tests (requires LocalStack + Valkey)
	go test ./test/integration/... -v -race -count=1 -tags=integration

test-e2e:                ## Run end-to-end tests against staging
	go test ./test/e2e/... -v -count=1 -tags=e2e

test-all:                ## Run unit + integration tests
	$(MAKE) test-unit
	$(MAKE) test-integration

coverage:                ## Generate coverage report (HTML + console)
	go test ./internal/... ./test/unit/... -coverprofile=coverage.out \
	  -covermode=atomic -race
	go tool cover -html=coverage.out -o coverage.html
	go tool cover -func=coverage.out | tail -1

coverage-check:          ## Verify coverage meets 80% threshold
	@COVERAGE=$$(go test ./internal/... -coverprofile=/dev/null 2>&1 \
	  | grep total | awk '{print $$3}' | sed 's/%//'); \
	if [ $$(echo "$$COVERAGE < 80.0" | bc -l) -eq 1 ]; then \
	  echo "FAIL: Coverage $$COVERAGE% is below 80% threshold"; exit 1; \
	else echo "PASS: Coverage $$COVERAGE%"; fi

# ============================================================================
# Code Quality
# ============================================================================

lint:                    ## Run linters (golangci-lint)
	golangci-lint run ./...

fmt:                     ## Format Go code
	gofmt -w -s .
	goimports -w .

vet:                     ## Run go vet
	go vet ./...

# ============================================================================
# Build
# ============================================================================

build:                   ## Build all Lambda binaries (ARM64 for Graviton)
	@for dir in cmd/lambda/*/; do \
	  name=$$(basename $$dir); \
	  echo "Building $$name..."; \
	  GOOS=linux GOARCH=arm64 CGO_ENABLED=0 \
	    go build -ldflags="-s -w" -o bin/$$name/bootstrap ./cmd/lambda/$$name/; \
	done

build-single:            ## Build a single Lambda: make build-single NAME=tracking
	GOOS=linux GOARCH=arm64 CGO_ENABLED=0 \
	  go build -ldflags="-s -w" -o bin/$(NAME)/bootstrap ./cmd/lambda/$(NAME)/

# ============================================================================
# Local Development
# ============================================================================

local-up:                ## Start LocalStack + Valkey for local development
	docker compose up -d
	@echo "Waiting for LocalStack to be ready..."
	@until docker compose exec localstack awslocal sts get-caller-identity > /dev/null 2>&1; do sleep 1; done
	@echo "Creating local DynamoDB table..."
	@./scripts/create-local-tables.sh
	@echo "Local environment ready."

local-down:              ## Stop local services
	docker compose down

local-reset:             ## Stop, remove volumes, and restart local services
	docker compose down -v
	$(MAKE) local-up

local-logs:              ## Tail LocalStack logs
	docker compose logs -f localstack

# ============================================================================
# Deployment
# ============================================================================

deploy-dev:              ## Deploy to dev environment
	cd cdk && npx cdk deploy --all --context env=dev --require-approval never

deploy-staging:          ## Deploy to staging environment
	cd cdk && npx cdk deploy --all --context env=staging

deploy-prod:             ## Deploy to production (requires approval)
	cd cdk && npx cdk deploy --all --context env=prod

cdk-diff:                ## Show infrastructure diff
	cd cdk && npx cdk diff --all --context env=$(ENV)

cdk-synth:               ## Synthesize CloudFormation templates
	cd cdk && npx cdk synth --all --context env=$(ENV)

# ============================================================================
# Utilities
# ============================================================================

clean:                   ## Remove build artifacts
	rm -rf bin/ coverage.out coverage.html

deps:                    ## Download and verify Go dependencies
	go mod download
	go mod verify

tools:                   ## Install required development tools
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	go install golang.org/x/tools/cmd/goimports@latest
	npm install -g @redocly/cli

help:                    ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
.PHONY: spec-validate contract-test spec-docs test-unit test-integration test-e2e \
        test-all coverage coverage-check lint fmt vet build build-single \
        local-up local-down local-reset local-logs deploy-dev deploy-staging \
        deploy-prod cdk-diff cdk-synth clean deps tools help
```

---

## 8. Local Development Environment

### Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Go | 1.22+ | Backend language |
| Docker + Docker Compose | Latest | LocalStack + Valkey containers |
| Node.js | 20+ | CDK, Redocly CLI |
| AWS CLI v2 | Latest | AWS operations |
| golangci-lint | v1.57+ | Go linting |

### docker-compose.yml

```yaml
services:
  localstack:
    image: localstack/localstack:latest
    ports:
      - "4566:4566"        # LocalStack gateway
    environment:
      - SERVICES=dynamodb,s3,sqs,sns,ssm,sts
      - DEFAULT_REGION=us-east-1
      - EAGER_SERVICE_LOADING=1
    volumes:
      - localstack-data:/var/lib/localstack

  valkey:
    image: valkey/valkey:7-alpine
    ports:
      - "6379:6379"
    command: valkey-server --maxmemory 64mb --maxmemory-policy allkeys-lru

volumes:
  localstack-data:
```

### Getting Started

```bash
# 1. Clone and install dependencies
git clone <repo-url> && cd regal-recovery-api
make deps
make tools

# 2. Start local services
make local-up

# 3. Validate specs and run contract tests
make spec-validate
make contract-test

# 4. Run tests
make test-unit
make test-integration    # requires local-up

# 5. Build
make build
```

---

## 9. Pull Request Workflow

### PR Checklist

Every PR must satisfy all applicable items before merge:

- [ ] **Spec updated** -- If the PR changes any API behavior (new endpoint, modified request/response schema, new error code, changed validation), the corresponding OpenAPI spec file in `specs/openapi/` has been updated.
- [ ] **Contract tests validate against OpenAPI spec** -- `make contract-test` passes. If the spec changed, contract tests and handler/client types have been updated to match.
- [ ] **Unit tests pass** -- `make test-unit` exits 0. New tests are included for new behavior.
- [ ] **Integration tests pass** -- `make test-integration` exits 0. New repository/cache tests included if data access patterns changed.
- [ ] **Coverage meets threshold** -- `make coverage-check` confirms 80%+ coverage. New code must not decrease overall coverage.
- [ ] **Linter passes** -- `make lint` exits 0. No new linter warnings introduced.
- [ ] **No security vulnerabilities** -- `go vet ./...` passes. No hardcoded secrets, no SQL/NoSQL injection vectors, tenant isolation preserved.
- [ ] **Acceptance criteria referenced** -- Test function names reference the FR/NFR/AC they verify (e.g., `TestUrgeLog_FR2_3_StoresCompleteHistory`).
- [ ] **Breaking changes documented** -- If the PR introduces a breaking API change, an ADR is included explaining the decision and migration path.

### PR Size Guidelines

- **Target: <400 lines changed.**
- Prefer small, focused PRs over large feature PRs.
- If a feature requires >400 lines, split into stacked PRs: spec PR -> domain logic PR -> handler PR -> integration test PR.

### Review Focus Areas

Reviewers should prioritize:
1. **Spec compliance** -- Does the implementation match the OpenAPI contract exactly?
2. **Test quality** -- Do tests cover meaningful scenarios? Are edge cases addressed?
3. **Domain logic correctness** -- Is the business logic sound? Are invariants enforced?
4. **Security** -- Tenant isolation maintained? Auth checks present? No data leakage?
5. **Error handling** -- Errors follow Siemens error response format? Appropriate status codes?

---

## 10. CI/CD Pipeline

### Pipeline Stages

```
Push to feature branch
    |
    v
[Stage 1: Validate]
    - make spec-validate
    - make contract-test
    - make lint
    - make vet
    |
    v
[Stage 2: Test]
    - make test-unit
    - make coverage-check
    - make test-integration (LocalStack in CI via Docker)
    |
    v
[Stage 3: Build]
    - make build (ARM64 Lambda binaries)
    - CDK synth (validate infrastructure templates)
    |
    v
Merge to develop
    |
    v
[Stage 4: Deploy Staging]
    - make deploy-staging
    - make test-e2e (against staging)
    |
    v
Merge to main (release)
    |
    v
[Stage 5: Deploy Production]
    - make deploy-prod (with approval gate)
    - Smoke tests against production
    - Monitor error rates for 15 minutes (automatic rollback if elevated)
```

### CI Environment

- **Runner:** GitHub Actions with `ubuntu-latest`
- **Docker services:** LocalStack and Valkey started as service containers for integration tests
- **Caching:** Go modules cached, Docker layer caching for LocalStack image
- **Secrets:** AWS credentials for staging/prod deployments stored in GitHub Secrets (never in code)
- **Artifacts:** Coverage reports and test results uploaded as workflow artifacts

---

## 11. Branching Strategy

```
main (production)
  |
  +-- develop (staging)
  |     |
  |     +-- feature/<domain>/<description>   (e.g., feature/tracking/streak-calculation)
  |     +-- feature/<domain>/<description>
  |     +-- fix/<issue-number>-<description>  (e.g., fix/142-timezone-streak-bug)
  |
  +-- hotfix/<description>                    (branched from main, merged to main + develop)
```

- **`main`** -- Production. Every commit is deployed. Protected: requires PR with passing CI and 1 approval.
- **`develop`** -- Staging. Integration branch. Protected: requires PR with passing CI.
- **`feature/*`** -- Short-lived. Branched from `develop`, merged back via PR.
- **`hotfix/*`** -- Emergency fixes. Branched from `main`, merged to both `main` and `develop`.

---

## 12. Dependency Management

### Go Backend

- **Go modules** (`go.mod` / `go.sum`) for all dependencies.
- **Dependabot** configured for weekly dependency update PRs.
- **Vulnerability scanning:** `govulncheck` runs in CI to detect known vulnerabilities.
- **Pinned versions:** All dependencies use exact versions, not ranges.

### Android (Kotlin)

- **Gradle version catalog** (`gradle/libs.versions.toml`) for centralized version management.
- **Dependabot** configured for weekly Gradle dependency updates.
- **Dependency locking** enabled for reproducible builds.

### iOS (Swift)

- **Swift Package Manager** (`Package.swift`) for dependency management.
- **Dependabot** configured for weekly Swift package updates.
- **Package.resolved** committed for reproducible builds.

### Infrastructure (CDK)

- **npm lockfile** (`package-lock.json`) committed for reproducible CDK deployments.
- **CDK version pinned** in `package.json` to prevent infrastructure drift from library updates.

---

## Related Documents

- [Technical Architecture](../docs/03-technical-architecture.md)
- [API Data Model](../docs/architecture/api-data-model.md)
- [AWS Infrastructure](../docs/architecture/aws-infrastructure.md)
- [DynamoDB Table Design](dynamodb/table-design.md)
