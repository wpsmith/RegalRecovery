# Regal Recovery — Specification-Driven + Test-Driven Development Plan

**The single source of truth for how this project is built.**

Every line of code in Regal Recovery is derived from a specification. Every specification is validated by a test. No code is written without a failing test. No test is written without an acceptance criterion. No acceptance criterion exists without a user story.

```
User Story → Acceptance Criteria → OpenAPI Spec → Contract Tests (RED) → Implement Handlers (GREEN) → Validate Against Spec → Deploy
```

---

## 1. Document Map

### Product Requirements (what to build)

| Document | Path | Purpose |
|----------|------|---------|
| Strategic PRD | `docs/01-strategic-prd.md` | Problem, personas, KPIs, competitive analysis, business model, roadmap |
| Feature Specifications | `docs/02-feature-specifications.md` | 31 features, 30 activities, tools, assessments — user stories + acceptance criteria |
| Technical Architecture | `docs/03-technical-architecture.md` | FRs, NFRs, tech stack, environments, feature flags, agent architecture, security |
| Content Strategy | `docs/04-content-strategy.md` | Content tiers, packs, localization, licensing |
| Future Features | `docs/05-future-features.md` | Deferred work (ZK, content filter, Signal Protocol, field-level encryption) |
| Feature Dependencies | `docs/feature-dependency-map.md` | Build order, blocking dependencies |
| Glossary | `content/glossary.md` | Recovery terminology for development team |

### Architecture (how it's structured)

| Document | Path | Purpose |
|----------|------|---------|
| C4 Diagrams | `docs/architecture/c4-diagrams.md` | System Context, Container, Component diagrams |
| AWS Infrastructure | `docs/architecture/aws-infrastructure.md` | AWS services, multi-region, backup, cost estimates |
| Sequence/Flow Diagrams | `docs/architecture/sequence-flow-diagrams.md` | 8 critical user flow diagrams |
| API & Data Model | `docs/architecture/api-data-model.md` | API domain map, ER diagram, DynamoDB patterns, security flow |
| Well-Architected Review | `docs/architecture/well-architected-review.md` | 6-pillar AWS review with prioritized findings |
| 12-Factor Audit | `docs/architecture/12factor-audit.md` | 12-factor compliance (10/12 compliant, 2 partial) |

### API Specifications (the contracts)

| Spec | Path | Endpoints |
|------|------|-----------|
| README (conventions) | `specs/openapi/README.md` | Development workflow, naming conventions |
| Auth | `specs/openapi/auth.yaml` | Register, login, passkey, sessions |
| Users | `specs/openapi/users.yaml` | Profile, settings, privacy, addictions |
| Tracking | `specs/openapi/tracking.yaml` | Streaks, milestones, calendar, relapses |
| Activities | `specs/openapi/activities.yaml` | 23 activity types (largest spec) |
| Content | `specs/openapi/content.yaml` | Affirmations, devotionals, prayers, packs |
| Community | `specs/openapi/community.yaml` | Support network, permissions, messaging |
| Analytics | `specs/openapi/analytics.yaml` | Dashboard, health score, trends |
| Tools | `specs/openapi/tools.yaml` | 3 Circles, Relapse Prevention Plan, Vision |
| Assessments | `specs/openapi/assessments.yaml` | 5 assessment types |
| Notifications | `specs/openapi/notifications.yaml` | Preferences, history, snooze |
| Integrations | `specs/openapi/integrations.yaml` | Health sync, calendar, meeting finder |
| Backup | `specs/openapi/backup.yaml` | Backup/restore, DSR, account deletion |
| Agent | `specs/openapi/agent.yaml` | Conversations, tool execution, Bedrock metadata |
| Admin | `specs/openapi/admin.yaml` | Tenant management, content management |
| Flags | `specs/openapi/flags.yaml` | Feature flag evaluation + admin CRUD |

### Data & Testing Specifications

| Spec | Path | Purpose |
|------|------|---------|
| DynamoDB Table Design | `specs/dynamodb/table-design.md` | Single-table design, 53 entities, 55 access patterns |
| Test Strategy | `specs/testing/test-strategy.md` | TDD approach, test pyramid, persona fixtures, CI/CD gates |
| Development Workflow | `specs/development-workflow.md` | Dev cycle, project structure, Makefile, PR checklist |

### Content Assets

| Asset | Path | Purpose |
|-------|------|---------|
| Motivations | `content/motivations.md` | Default motivation options for onboarding |
| Christian Affirmations | `content/affirmations/christian-affirmations.md` | Freemium affirmation pack content |
| AA Affirmations | `content/affirmations/aa-affirmations.md` | AA-aligned affirmation content |
| Needs | `content/needs.md` | Quick-select needs for Time Journal |
| Acting-In Behaviors | `content/acting-in.md` | 15 default acting-in behavior definitions |

---

## 2. The Development Cycle

### Phase 0: Before Any Code

```
1. Read the acceptance criteria for the feature/activity in 02-feature-specifications.md
2. Read the OpenAPI spec for the relevant domain in specs/openapi/
3. Read the DynamoDB access patterns in specs/dynamodb/table-design.md
4. Read the sequence diagram in docs/architecture/sequence-flow-diagrams.md (if applicable)
5. Check the feature dependency map — are all dependencies built?
6. Check the feature flag — is this feature flagged? What's the flag key?
```

### Phase 1: Validate Spec

```bash
make spec-validate
```

This validates all OpenAPI specs against the OpenAPI 3.1 schema using Redocly. Specs must be valid before writing any code.

### Phase 2: Test (RED)

Write failing tests BEFORE any implementation:

```bash
# Write tests derived from acceptance criteria
# Each test function name references the AC it validates:
# TestFR2_7_ImmutableTimestamps
# TestFeature3_StreakResetOnRelapse
# TestActivity_FASTERScale_CrisisEscalation

make test-unit         # All fail (RED) — no implementation yet
```

**Test sources:**
- Acceptance criteria → unit tests (one test per Given/When/Then)
- OpenAPI schemas → contract tests (request/response validation)
- DynamoDB access patterns → repository tests
- Sequence diagrams → integration tests
- Security requirements → security tests (permissions, rate limiting)

### Phase 3: Implement (GREEN)

Write the minimum code to make tests pass:

```bash
# Implement handler, service, repository
make test-unit         # GREEN — tests pass
make lint              # No linting issues
make coverage          # Meets 80% threshold (100% for critical paths)
```

### Phase 4: Refactor

Improve code quality while all tests stay green:

```bash
make test-all          # Unit + integration tests still GREEN
```

### Phase 5: Integration Verify

```bash
make local-up          # Start LocalStack + Valkey + Ollama
make test-integration  # Run against local services
make local-down
```

### Phase 6: Deploy + E2E

```bash
make deploy-staging    # Staging wakes up, deploys
make test-e2e          # Run E2E against staging
                       # Staging auto-sleeps after tests
```

### Phase 7: PR

```
PR Checklist:
- [ ] OpenAPI spec updated (if API changed)
- [ ] Contract tests validate against OpenAPI spec (`make contract-test`)
- [ ] DynamoDB table design updated (if entities changed)
- [ ] Feature flag key documented
- [ ] Unit tests pass (`make test-unit`)
- [ ] Integration tests pass (`make test-integration`)
- [ ] Coverage meets threshold (`make coverage` >= 80%)
- [ ] No security vulnerabilities (`make lint`)
- [ ] Acceptance criteria referenced in test names
- [ ] No hardcoded colors (dark mode compatible)
```

---

## 3. Build Order

Derived from `docs/feature-dependency-map.md`. Each wave must be complete before the next starts.

### Wave 0: Foundation (infrastructure only)

| Task | Details |
|------|---------|
| Project scaffolding | Go module, Android (Kotlin + Jetpack Compose) project, iOS (Swift + SwiftUI) project, CDK stack, docker-compose |
| DynamoDB table | Single table with GSIs per `specs/dynamodb/table-design.md` |
| Cognito setup | User pool with email, Apple, Google, passkey providers |
| Valkey | Local Docker + staging/prod ElastiCache |
| CI/CD pipeline | GitHub Actions: lint → test → deploy |
| Feature flag system | `FLAGS` entity in DynamoDB, `GET /flags` endpoint, Valkey cache |
| LocalStack + Ollama | `make local-up` works end-to-end |
| Contract test framework | `make contract-test` validates handlers + client types against OpenAPI specs |

**Spec files consumed:** `specs/openapi/auth.yaml`, `specs/openapi/flags.yaml`, `specs/dynamodb/table-design.md`, `docs/03-technical-architecture.md` (10.2.1, 10.2.2)

### Wave 1: Core P0 Features

| Feature | Spec | Flag Key |
|---------|------|----------|
| Onboarding (Fast Track) | Feature 1 | `feature.onboarding` |
| Profile Management | Feature 2 | `feature.profile-management` |
| Tracking System | Feature 3 | `feature.tracking` |
| Content/Resources System | Feature 4 | `feature.content-resources` |
| Commitments System | Feature 5 | `feature.commitments` |
| Light/Dark Mode | Feature 31 | `feature.dark-mode` |
| Offline-First (core) | Feature 23 | `feature.offline-first` |
| DSR (export/delete) | Feature 12 | `feature.dsr` |

**Activities (P0):**

| Activity | Spec | Flag Key |
|----------|------|----------|
| Daily Sobriety Commitment | Activity spec | `activity.sobriety-commitment` |
| Christian Affirmations | Activity spec | `activity.affirmations` |
| Urge Logging & Emergency Tools | Activity spec | `activity.urge-logging` |
| Journaling/Jotting | Activity spec | `activity.journaling` |
| FASTER Scale | Activity spec | `activity.faster-scale` |
| Recovery Check-ins | Activity spec | `activity.check-ins` |

**Assessments (P0):**

| Assessment | Flag Key |
|------------|----------|
| SAST-R | `assessment.sast-r` (existing P0) |
| Family Impact | `assessment.family-impact` |
| Denial | `assessment.denial` |
| Addiction Severity | `assessment.addiction-severity` |
| Relationship Health | `assessment.relationship-health` |

**OpenAPI specs consumed:** `auth.yaml`, `users.yaml`, `tracking.yaml`, `activities.yaml` (subset), `content.yaml`, `backup.yaml`, `flags.yaml`, `notifications.yaml`

**Test focus:** Streak calculation, permission checks (opt-in), immutable timestamps, offline sync, content pack purchases

### Wave 2: P1 Features & Activities

| Feature/Activity | Spec | Flag Key |
|------------------|------|----------|
| Analytics Dashboard | Feature 6 | `feature.analytics-dashboard` |
| Meeting Finder | Feature 21 | `feature.meeting-finder` |
| Quick Action Shortcuts | Feature 14 | `feature.quick-actions` |
| Data Backup | Feature 13 | `feature.backup` |
| Messaging Integrations | Feature 22 | `feature.messaging-integrations` |
| Notification Strategy | Section 4.11 | N/A (infrastructure) |
| Emotional Journaling | Activity | `activity.emotional-journaling` |
| Time Journal | Activity | `activity.time-journal` |
| Spouse Check-in Prep | Activity | `activity.spouse-checkin-prep` |
| Person Check-ins | Activity | `activity.person-check-ins` |
| Meetings Attended | Activity | `activity.meetings` |
| Post-Mortem Analysis | Activity | `activity.post-mortem` |
| Guided 12 Step Work | Activity | `activity.step-work` |
| Weekly/Daily Goals | Activity | `activity.goals` |
| Devotionals | Activity | `activity.devotionals` |
| Exercise | Activity | `activity.exercise` |
| Mood Ratings | Activity | `activity.mood` |
| Gratitude List | Activity | `activity.gratitude` |
| Phone Calls | Activity | `activity.phone-calls` |
| Prayer | Activity | `activity.prayer` |
| Integrity Inventory | Activity | `activity.integrity-inventory` |
| PCI | Activity | `activity.pci` |

**OpenAPI specs consumed:** `analytics.yaml`, `integrations.yaml`, `activities.yaml` (remaining endpoints), `notifications.yaml`

**Test focus:** Recovery Health Score calculation, GPS/sensor metadata (Time Journal, Emotional Journal), FANOS/FITNAP frameworks, calendar integration, meeting finder API

### Wave 3: P2 Features

| Feature | Spec | Flag Key |
|---------|------|----------|
| Community | Feature 9 | `feature.community` |
| Therapist Portal | Feature 17 | `feature.therapist-portal` |
| Recovery Health Score | Feature 18 | `feature.health-score` |
| Achievement System | Feature 19 | `feature.achievements` |
| Couples Recovery Mode | Feature 26 | `feature.couples-mode` |
| Geofencing | Feature 24 | `feature.geofencing` |
| Screen Time | Feature 25 | `feature.screen-time` |
| Sleep Tracking | Feature 27 | `feature.sleep-tracking` |
| Superbill/LMN | Feature 20 | `feature.superbill` |

**OpenAPI specs consumed:** `community.yaml`, `analytics.yaml`, `integrations.yaml`, `tools.yaml`

**Test focus:** Opt-in permission model (no default access), coercive control safeguards, therapist data access tiers, couples mode bilateral consent, geofence region monitoring

### Wave 4: P3 Features & Premium

| Feature | Spec | Flag Key |
|---------|------|----------|
| Recovery Agent | Feature 8 | `feature.recovery-agent` |
| Premium Advanced Analytics | Feature 7 | `feature.premium-analytics` |
| Panic Button (biometric) | Feature 16 | `feature.panic-button-biometric` |
| Anonymous Recovery Stories | Feature 29 | `feature.recovery-stories` |
| Branding (B2B) | Feature 10 | `feature.branding` |
| Tenancy (B2B) | Feature 11 | `feature.tenancy` |
| Spotify Integration | Feature 30 | `feature.spotify` |

**OpenAPI specs consumed:** `agent.yaml`, `admin.yaml`, `analytics.yaml`

**Test focus:** LangGraph state machine, LiteLLM→Bedrock routing (prod) / LiteLLM→Ollama (local), Langfuse tracing (metadata only), tool execution confirmation flow, crisis escalation non-overridable, B2B tenant isolation

### Wave 5: Future (from `docs/05-future-features.md`)

- Zero-Knowledge Architecture
- Signal Protocol E2E Messaging
- WebKit Content Filter
- Field-Level Encryption
- Per-User KMS CMKs
- Content Trigger Log (depends on Content Filter)

---

## 4. Specification Traceability Matrix

Every requirement is traceable from user story through to deployed, tested code:

```
User Story (02-feature-specifications.md)
  ↓ derives
Acceptance Criterion (Given/When/Then in same file)
  ↓ defines contract
OpenAPI Spec (specs/openapi/*.yaml)
  ↓ validated by
Contract Test (test/contract/) — validates handlers and client types against spec
  ↓ implements
Handler + Service + Repository (internal/domain/) — hand-written Go handlers
Android API Client (androidApp/) — hand-written Kotlin client
iOS API Client (iosApp/) — hand-written Swift client
  ↓ verifies
Unit Test (test/unit/) — named after AC: TestFR2_7_ImmutableTimestamps
Integration Test (test/integration/) — LocalStack + Valkey + Ollama
  ↓ stores
DynamoDB Entity (specs/dynamodb/table-design.md)
  ↓ cached
Valkey (streaks, flags, sessions)
  ↓ observed
Langfuse Trace (agent interactions only)
  ↓ gated
Feature Flag (specs/openapi/flags.yaml)
  ↓ deployed
Canary → Production
```

### Traceability Example: FASTER Scale

| Layer | Artifact | Reference |
|-------|----------|-----------|
| **User Story** | "As a recovering user, I want to assess where I am on the FASTER Scale..." | `02-feature-specifications.md` → ACTIVITY: FASTER Scale |
| **Acceptance Criteria** | "Given user opens FASTER Scale, When they complete all 6 stages, Then score calculated..." | Same file, Acceptance Criteria section |
| **OpenAPI Spec** | `POST /activities/faster-scale` | `specs/openapi/activities.yaml` |
| **Hand-Written Type** | `FASTERScaleEntry` struct | `internal/domain/activities/types.go` |
| **Contract Test** | Validates `FASTERScaleEntry` matches OpenAPI schema | `test/contract/activities_test.go` |
| **DynamoDB Pattern** | PK=`USER#{userId}`, SK=`FASTER#{timestamp}` | `specs/dynamodb/table-design.md` |
| **Unit Test** | `TestFASTERScale_StageDetection_AlertThresholds` | `test/unit/activities/faster_scale_test.go` |
| **Integration Test** | `TestFASTERScale_SaveAndRetrieve_DynamoDB` | `test/integration/activities/faster_scale_test.go` |
| **Feature Flag** | `activity.faster-scale` | `specs/openapi/flags.yaml` |
| **Sequence Diagram** | Recovery Agent guided FASTER Scale walkthrough | `docs/architecture/sequence-flow-diagrams.md` |

---

## 5. Test Pyramid

```
        ╱╲
       ╱  ╲        E2E Tests (5-10%)
      ╱ E2E╲       - Full user flows against staging
     ╱──────╲      - Persona-based scenarios (Alex, Marcus, Diego)
    ╱        ╲
   ╱Integration╲   Integration Tests (20-30%)
  ╱─────────────╲  - LocalStack DynamoDB/SQS/SNS
 ╱               ╲ - Valkey caching
╱   Unit Tests    ╲ - Ollama agent interactions
╱─────────────────╲
                    Unit Tests (60-70%)
                    - Handler tests (HTTP → response)
                    - Service tests (business logic)
                    - Repository tests (DynamoDB mocks)
                    - Flag evaluation tests
                    - Scoring algorithms (Health Score, FASTER, PCI)
                    - Permission checks (opt-in enforcement)
```

### Coverage Requirements

| Category | Minimum | Critical Paths (100%) |
|----------|---------|----------------------|
| Overall | 80% | — |
| Streak calculation | — | Reset on relapse, timezone handling, milestone detection |
| Permission checks | — | Opt-in enforcement, no default access, silent revoke |
| Scoring algorithms | — | Health Score, FASTER Scale, PCI, Integrity Inventory |
| Data deletion | — | Account deletion, ephemeral TTL, DSR export |
| Immutable timestamps | — | FR2.7 enforcement |
| Feature flag evaluation | — | Kill switch, rollout %, tier gating, consistent hashing |
| Crisis escalation | — | Non-overridable, resource display |
| Financial calculations | — | Money saved, cost tracking |

---

## 6. Environment Matrix

| Aspect | Local | Staging | Production |
|--------|-------|---------|------------|
| **Infra** | Docker Compose | CDK (ephemeral) | CDK (persistent) |
| **Database** | LocalStack DynamoDB | DynamoDB on-demand | DynamoDB on-demand + PITR |
| **Cache** | Docker Valkey | Auto-shutdown micro | Multi-AZ Valkey |
| **LLM** | Ollama + Qwen | Bedrock (sandbox) | Bedrock (Claude primary) |
| **Auth** | Mocked JWT | Cognito sandbox | Cognito production |
| **Push** | Console log | Test SNS topic | APNS/FCM |
| **Email** | Mailhog | SES sandbox | SES production |
| **Monitoring** | stdout | CloudWatch basic | CloudWatch + X-Ray + alarms |
| **WAF** | N/A | N/A | Enabled |
| **Feature Flags** | All enabled | Per-flag config | Per-flag config |
| **Cost** | $0 | ~$3-8/mo | ~$12-38/mo + LLM |
| **Deploy** | `make dev-api` | `make deploy-staging` | `make deploy-prod` (canary) |

---

## 7. CI/CD Pipeline

```
git push
  │
  ├─ lint (Go + Kotlin + Swift)
  ├─ spec-validate (Redocly lint on all OpenAPI YAMLs)
  ├─ contract-test (validate implementations against OpenAPI specs)
  ├─ test-unit (Go + Android + iOS)
  │
  ├─ [on merge to main]
  │   ├─ test-integration (LocalStack + Valkey + Ollama in Docker)
  │   ├─ build (Go ARM64 Lambda binaries + Android APK + iOS IPA)
  │   ├─ deploy-staging (CDK, staging wakes up)
  │   ├─ test-e2e (against staging)
  │   └─ staging auto-sleeps
  │
  └─ [on tag v*.*.*]
      ├─ deploy-prod (canary: 10% traffic, 10 min)
      ├─ monitor (error rate, latency, crash rate)
      ├─ auto-rollback if error spike
      └─ full rollout if healthy
```

### Quality Gates (merge blockers)

| Gate | Threshold |
|------|-----------|
| Unit test pass rate | 100% |
| Integration test pass rate | 100% |
| Code coverage | ≥ 80% |
| Critical path coverage | 100% |
| OpenAPI spec valid | 0 errors |
| Contract tests pass | `make contract-test` exits 0 |
| Linting | 0 errors |
| Security scan | 0 high/critical vulnerabilities |

---

## 8. Makefile Reference

```makefile
# Specification
make spec-validate        # Validate all OpenAPI specs (Redocly)
make spec-diff            # Show API changes since last release
make contract-test        # Validate implementations against OpenAPI specs

# Testing
make test-unit            # Run unit tests
make test-integration     # Run integration tests (requires local-up)
make test-e2e             # Run E2E tests (requires staging)
make test-all             # Unit + integration
make coverage             # Generate coverage report
make test-agent           # Agent-specific tests with Ollama

# Local Development
make local-up             # Start LocalStack + Valkey + Ollama + Mailhog
make local-seed           # Seed DynamoDB with persona test data
make local-down           # Stop all local services
make local-reset          # Wipe and re-seed
make dev-api              # Start Go API with hot reload (air)

# Build
make build                # Build Lambda binaries (ARM64)
make lint                 # Run Go + Kotlin linters

# Deploy
make deploy-staging       # Deploy to staging (wakes up if asleep)
make deploy-prod          # Deploy to production (canary)
make rollback-prod        # Rollback production to previous version

# Feature Flags
make flags-list           # List all feature flags and their state
make flags-enable KEY     # Enable a feature flag
make flags-disable KEY    # Disable a feature flag (kill switch)
make flags-rollout KEY %  # Set rollout percentage
```

---

## 9. Key Principles

1. **Specs are the source of truth.** If the spec says X and the code does Y, the code is wrong.
2. **Tests before code.** No implementation without a failing test. No test without an acceptance criterion.
3. **OpenAPI specs validated by contract tests.** Developers write Go handlers, Kotlin API clients (Android), and Swift API clients (iOS) by hand. Contract tests validate that implementations conform to the OpenAPI spec -- the spec remains the authority.
4. **Feature flags on everything.** Every feature ships behind a flag. Flags enable gradual rollout, kill switches, and tier gating.
5. **Fail closed.** Unknown flags default to disabled. Unknown permissions default to denied. Unknown users see nothing.
6. **Compassion in code.** Error messages, empty states, and edge cases are designed with the user's emotional state in mind. A relapse is not a failure — the code treats it that way.
7. **Privacy by architecture.** All data sharing is opt-in. No analytics on user text. No default access for anyone. Audit everything.
8. **Offline first.** Core recovery tools work without internet. Data syncs when connection returns. The user is never left without support.
9. **One table.** DynamoDB single-table design. All 53 entities in one table with GSIs. Access patterns drive the schema.
10. **Local = Production.** Same Go code, same DynamoDB patterns, same API contracts. LocalStack + Ollama + Valkey mirrors the production stack.
