# Regal Recovery — API Data Model

**Version:** 1.0.0
**Date:** 2026-03-28
**Status:** Draft

---

## 1. API Domain Map

The API is organized into bounded contexts that align with the product's feature domains. Each domain groups related endpoints and encapsulates a cohesive set of recovery-focused capabilities.

```mermaid
flowchart TB
    subgraph Auth Domain
        A1[POST /v1/auth/register]
        A2[POST /v1/auth/login]
        A3[POST /v1/auth/refresh]
        A4[POST /v1/auth/logout]
        A5[POST /v1/auth/passkey/register]
        A6[POST /v1/auth/passkey/authenticate]
        A7[POST /v1/auth/password-reset]
        A8[POST /v1/auth/verify-email]
        A9[POST /v1/auth/biometric/register]
        A10[DELETE /v1/auth/sessions/:sessionId]
    end

    subgraph Users Domain
        U1[GET /v1/users/me]
        U2[PATCH /v1/users/me]
        U3[GET /v1/users/me/profile]
        U4[PATCH /v1/users/me/profile]
        U5[GET /v1/users/me/settings]
        U6[PATCH /v1/users/me/settings]
        U7[GET /v1/users/me/permissions]
        U8[POST /v1/users/me/permissions]
        U9[DELETE /v1/users/me]
        U10[POST /v1/users/me/export]
    end

    subgraph Tracking Domain
        T1[GET /v1/tracking/streaks]
        T2[GET /v1/tracking/streaks/:addictionId]
        T3[GET /v1/tracking/calendar]
        T4[GET /v1/tracking/milestones]
        T5[GET /v1/tracking/history]
        T6[POST /v1/tracking/relapses]
        T7[PATCH /v1/tracking/sobriety-date]
    end

    subgraph Activities Domain
        AC1[POST /v1/activities/commitments]
        AC2[GET /v1/activities/commitments]
        AC3[PATCH /v1/activities/commitments/:id]
        AC4[POST /v1/activities/check-ins]
        AC5[GET /v1/activities/check-ins]
        AC6[POST /v1/activities/urges]
        AC7[GET /v1/activities/urges]
        AC8[POST /v1/activities/journal]
        AC9[GET /v1/activities/journal]
        AC10[POST /v1/activities/faster-scale]
        AC11[GET /v1/activities/faster-scale]
        AC12[POST /v1/activities/pci]
        AC13[GET /v1/activities/pci]
        AC14[POST /v1/activities/mood]
        AC15[POST /v1/activities/gratitude]
        AC16[POST /v1/activities/phone-calls]
        AC17[POST /v1/activities/prayer]
        AC18[POST /v1/activities/meetings]
        AC19[POST /v1/activities/exercise]
        AC20[POST /v1/activities/nutrition]
        AC21[POST /v1/activities/devotionals]
        AC22[POST /v1/activities/integrity-inventory]
        AC23[POST /v1/activities/post-mortem]
        AC24[POST /v1/activities/fanos]
        AC25[POST /v1/activities/emotional-journal]
    end

    subgraph Content Domain
        C1[GET /v1/content/affirmations]
        C2[GET /v1/content/affirmations/:id]
        C3[POST /v1/content/affirmations/custom]
        C4[GET /v1/content/devotionals]
        C5[GET /v1/content/devotionals/:id]
        C6[GET /v1/content/prayers]
        C7[GET /v1/content/prayers/:id]
        C8[GET /v1/content/resources]
        C9[GET /v1/content/packs]
        C10[POST /v1/content/packs/:packId/purchase]
    end

    subgraph Community Domain
        CM1[GET /v1/community/network]
        CM2[POST /v1/community/network/invites]
        CM3[PATCH /v1/community/network/:contactId]
        CM4[DELETE /v1/community/network/:contactId]
        CM5[POST /v1/community/permissions]
        CM6[PATCH /v1/community/permissions/:permissionId]
        CM7[GET /v1/community/messages]
        CM8[POST /v1/community/messages]
        CM9[POST /v1/community/broadcasts]
    end

    subgraph Analytics Domain
        AN1[GET /v1/analytics/dashboard]
        AN2[GET /v1/analytics/recovery-health-score]
        AN3[GET /v1/analytics/trends]
        AN4[GET /v1/analytics/insights]
        AN5[GET /v1/analytics/correlations]
    end

    subgraph Tools Domain
        TL1[GET /v1/tools/three-circles]
        TL2[PATCH /v1/tools/three-circles]
        TL3[GET /v1/tools/relapse-prevention-plan]
        TL4[PATCH /v1/tools/relapse-prevention-plan]
        TL5[GET /v1/tools/vision]
        TL6[PATCH /v1/tools/vision]
        TL7[GET /v1/tools/arousal-template]
        TL8[PATCH /v1/tools/arousal-template]
    end

    subgraph Assessments Domain
        AS1[GET /v1/assessments/templates]
        AS2[POST /v1/assessments/sastr]
        AS3[GET /v1/assessments/sastr]
        AS4[POST /v1/assessments/family-impact]
        AS5[POST /v1/assessments/denial]
        AS6[POST /v1/assessments/addiction-severity]
        AS7[POST /v1/assessments/relationship-health]
    end

    subgraph Notifications Domain
        N1[GET /v1/notifications]
        N2[PATCH /v1/notifications/:id/read]
        N3[POST /v1/notifications/:id/snooze]
        N4[GET /v1/notifications/preferences]
        N5[PATCH /v1/notifications/preferences]
        N6[GET /v1/notifications/history]
    end

    subgraph Integrations Domain
        I1[POST /v1/integrations/health/sync]
        I2[GET /v1/integrations/health/data]
        I3[POST /v1/integrations/calendar/events]
        I4[GET /v1/integrations/meetings/search]
        I5[POST /v1/integrations/spotify/connect]
        I6[DELETE /v1/integrations/spotify/disconnect]
    end

    subgraph Backup Domain
        B1[POST /v1/backup/create]
        B2[GET /v1/backup/list]
        B3[POST /v1/backup/restore]
        B4[DELETE /v1/backup/:backupId]
    end

    subgraph Agent Domain
        AG1[POST /v1/agent/conversations]
        AG2[POST /v1/agent/conversations/:conversationId/messages]
        AG3[GET /v1/agent/conversations/:conversationId]
        AG4[POST /v1/agent/tools/execute]
    end

    subgraph Admin Domain
        AD1[GET /v1/admin/tenants]
        AD2[POST /v1/admin/tenants]
        AD3[PATCH /v1/admin/tenants/:tenantId]
        AD4[DELETE /v1/admin/tenants/:tenantId]
        AD5[GET /v1/admin/content]
        AD6[POST /v1/admin/content]
        AD7[PATCH /v1/admin/content/:contentId]
    end
```

---

## 2. Entity Relationship Diagram

This ERD represents the core data model for DynamoDB. Although DynamoDB is NoSQL, we model entities and relationships logically to understand the domain structure and access patterns.

```mermaid
erDiagram
    User ||--o{ Addiction : "tracks"
    User ||--o{ SobrietyStreak : "maintains"
    User ||--o{ UrgeLog : "records"
    User ||--o{ JournalEntry : "writes"
    User ||--o{ Commitment : "creates"
    User ||--o{ CheckIn : "completes"
    User ||--o{ FASTERScaleEntry : "assesses"
    User ||--o{ PCIEntry : "logs"
    User ||--o{ MoodRating : "tracks"
    User ||--o{ GratitudeEntry : "writes"
    User ||--o{ PhoneCallLog : "records"
    User ||--o{ PrayerLog : "records"
    User ||--o{ MeetingLog : "attends"
    User ||--o{ IntegrityInventory : "completes"
    User ||--o{ DevotionalEntry : "reads"
    User ||--o{ Assessment : "takes"
    User ||--o{ Milestone : "achieves"
    User ||--o{ SupportContact : "connects to"
    User ||--o{ Permission : "grants"
    User ||--o{ Message : "sends"
    User ||--o{ Notification : "receives"
    User ||--o{ BackupRecord : "creates"
    User ||--o{ RecoveryHealthScore : "earns"
    User ||--o{ ExerciseLog : "records"
    User ||--o{ NutritionLog : "records"
    User ||--o{ EmotionalJournalEntry : "writes"
    User ||--o{ PostMortemAnalysis : "completes"
    User ||--o{ FANOSEntry : "prepares"
    User ||--o{ ThreeCircles : "defines"
    User ||--o{ RelapsePrevention : "maintains"
    User ||--o{ Vision : "writes"
    User ||--o{ ArousalTemplate : "defines"
    User ||--o{ CustomAffirmation : "creates"
    User ||--o{ Session : "has"

    Addiction ||--o{ SobrietyStreak : "has"
    Addiction ||--o{ UrgeLog : "triggers"
    Addiction ||--o{ CheckIn : "references"

    SupportContact ||--o{ Permission : "receives"
    SupportContact ||--o{ Message : "exchanges"

    AffirmationPack ||--o{ Affirmation : "contains"
    User ||--o{ AffirmationPack : "owns"

    Tenant ||--o{ User : "contains"
    Tenant ||--o{ ContentItem : "manages"

    User {
        string userId PK
        string email
        string displayName
        string role
        datetime createdAt
        datetime modifiedAt
        string tenantId
        string primaryAddictionId
        string preferredLanguage
        string preferredBibleVersion
        int birthYear
        string gender
        string maritalStatus
        string timeZone
        boolean emailVerified
        boolean biometricEnabled
    }

    Addiction {
        string addictionId PK
        string userId FK
        string type
        datetime sobrietyStartDate
        boolean isPrimary
        datetime createdAt
    }

    SobrietyStreak {
        string streakId PK
        string userId FK
        string addictionId FK
        int currentStreakDays
        int longestStreakDays
        datetime lastRelapseDate
        datetime createdAt
        datetime modifiedAt
    }

    UrgeLog {
        string urgeId PK
        string userId FK
        string addictionId FK
        datetime timestamp
        int intensity
        string[] triggers
        string notes
        boolean sobrietyMaintained
        int durationMinutes
    }

    JournalEntry {
        string entryId PK
        string userId FK
        datetime timestamp
        string mode
        string content
        string[] emotionalTags
        string prompt
        boolean isEphemeral
        datetime ephemeralDeleteAt
    }

    Commitment {
        string commitmentId PK
        string userId FK
        string title
        string frequency
        string category
        datetime createdAt
        boolean isActive
    }

    CheckIn {
        string checkInId PK
        string userId FK
        datetime timestamp
        string type
        object responses
        int score
        string colorCode
    }

    FASTERScaleEntry {
        string entryId PK
        string userId FK
        datetime timestamp
        string stage
        string[] indicators
        string notes
    }

    PCIEntry {
        string entryId PK
        string userId FK
        datetime timestamp
        string[] checkedBehaviors
        int score
    }

    MoodRating {
        string moodId PK
        string userId FK
        datetime timestamp
        int rating
        string emotion
        string notes
    }

    GratitudeEntry {
        string gratitudeId PK
        string userId FK
        datetime timestamp
        string content
    }

    PhoneCallLog {
        string callId PK
        string userId FK
        datetime timestamp
        string contactType
        int durationMinutes
    }

    PrayerLog {
        string prayerId PK
        string userId FK
        datetime timestamp
        string prayerType
        string content
    }

    MeetingLog {
        string meetingId PK
        string userId FK
        datetime timestamp
        string meetingType
        string name
        string notes
    }

    IntegrityInventory {
        string inventoryId PK
        string userId FK
        datetime timestamp
        object responses
    }

    DevotionalEntry {
        string entryId PK
        string userId FK
        datetime timestamp
        string devotionalId
        string reflection
    }

    Assessment {
        string assessmentId PK
        string userId FK
        datetime timestamp
        string type
        object responses
        int score
    }

    Milestone {
        string milestoneId PK
        string userId FK
        string addictionId FK
        string type
        int days
        datetime achievedAt
        boolean celebrated
    }

    SupportContact {
        string contactId PK
        string userId FK
        string contactUserId
        string role
        string email
        string status
        datetime invitedAt
        datetime acceptedAt
    }

    Permission {
        string permissionId PK
        string userId FK
        string contactId FK
        string dataCategory
        string accessLevel
        datetime grantedAt
    }

    Message {
        string messageId PK
        string senderId FK
        string recipientId FK
        datetime timestamp
        string content
        boolean isRead
    }

    Notification {
        string notificationId PK
        string userId FK
        datetime timestamp
        string type
        string content
        boolean isRead
        datetime snoozedUntil
    }

    BackupRecord {
        string backupId PK
        string userId FK
        datetime createdAt
        string storageProvider
        string fileUri
        int sizeBytes
    }

    RecoveryHealthScore {
        string scoreId PK
        string userId FK
        datetime timestamp
        int score
        object components
    }

    ExerciseLog {
        string exerciseId PK
        string userId FK
        datetime timestamp
        string type
        int durationMinutes
        int calories
    }

    NutritionLog {
        string nutritionId PK
        string userId FK
        datetime timestamp
        string mealType
        string description
    }

    EmotionalJournalEntry {
        string entryId PK
        string userId FK
        datetime timestamp
        string emotion
        string reason
        int intensity
    }

    PostMortemAnalysis {
        string analysisId PK
        string userId FK
        datetime timestamp
        string relapseId FK
        object sections
        string[] triggers
        string[] actionItems
    }

    FANOSEntry {
        string entryId PK
        string userId FK
        datetime timestamp
        object feelings
        string appreciation
        string needs
        string ownership
        string success
    }

    ThreeCircles {
        string userId PK
        object innerCircle
        object middleCircle
        object outerCircle
        datetime modifiedAt
    }

    RelapsePrevention {
        string userId PK
        string[] triggers
        string[] actionSteps
        string[] supportContacts
        datetime modifiedAt
    }

    Vision {
        string userId PK
        string content
        datetime modifiedAt
    }

    ArousalTemplate {
        string userId PK
        object template
        datetime modifiedAt
    }

    AffirmationPack {
        string packId PK
        string name
        string tier
        decimal price
        int affirmationCount
    }

    Affirmation {
        string affirmationId PK
        string packId FK
        string statement
        string scriptureReference
        string category
    }

    CustomAffirmation {
        string affirmationId PK
        string userId FK
        string statement
        string scriptureReference
        string category
        string schedule
    }

    ContentItem {
        string contentId PK
        string tenantId FK
        string type
        string title
        string content
        string tier
        datetime createdAt
    }

    Tenant {
        string tenantId PK
        string name
        string domain
        string brandingConfig
        datetime createdAt
    }

    Session {
        string sessionId PK
        string userId FK
        string deviceId
        datetime createdAt
        datetime expiresAt
        string ipAddress
        string userAgent
    }
```

---

## 3. DynamoDB Single-Table Design Access Patterns

Regal Recovery uses a single-table design in DynamoDB for optimal performance and cost efficiency. The table leverages composite keys and GSIs to support all required access patterns.

### Primary Table Schema

| Attribute | Type | Description |
|-----------|------|-------------|
| `PK` | String | Partition Key |
| `SK` | String | Sort Key |
| `GSI1PK` | String | Global Secondary Index 1 Partition Key |
| `GSI1SK` | String | Global Secondary Index 1 Sort Key |
| `GSI2PK` | String | Global Secondary Index 2 Partition Key |
| `GSI2SK` | String | Global Secondary Index 2 Sort Key |
| `EntityType` | String | Entity type discriminator |
| `TenantId` | String | Tenant isolation key |
| `Data` | Map | Entity-specific attributes |
| `CreatedAt` | String | ISO 8601 timestamp |
| `ModifiedAt` | String | ISO 8601 timestamp |
| `TTL` | Number | Unix timestamp for automatic deletion (ephemeral data) |

### Access Patterns

| Access Pattern | PK | SK | GSI | Notes |
|----------------|----|----|-----|-------|
| **User lookup by ID** | `USER#<userId>` | `PROFILE` | - | Single-item read |
| **User profile** | `USER#<userId>` | `PROFILE` | - | Profile attributes |
| **User settings** | `USER#<userId>` | `SETTINGS` | - | Settings attributes |
| **Addictions by user** | `USER#<userId>` | `ADDICTION#<addictionId>` | - | Query on PK |
| **Sobriety streak by user** | `USER#<userId>` | `STREAK#<addictionId>` | - | Query on PK |
| **Check-ins by user (recent)** | `USER#<userId>` | `CHECKIN#<timestamp>` | - | Query on PK, descending SK |
| **Check-ins by date range** | `USER#<userId>` | `CHECKIN#<timestamp>` | - | Query on PK with SK between |
| **Urge logs by user** | `USER#<userId>` | `URGE#<timestamp>` | - | Query on PK, descending SK |
| **Journal entries by user** | `USER#<userId>` | `JOURNAL#<timestamp>` | - | Query on PK, descending SK |
| **Commitments by user** | `USER#<userId>` | `COMMITMENT#<commitmentId>` | - | Query on PK |
| **Milestones by user** | `USER#<userId>` | `MILESTONE#<addictionId>#<days>` | - | Query on PK |
| **Support network by user** | `USER#<userId>` | `CONTACT#<contactId>` | - | Query on PK |
| **Permissions by user** | `USER#<userId>` | `PERMISSION#<contactId>#<category>` | - | Query on PK |
| **Messages by conversation** | `CONVERSATION#<conversationId>` | `MESSAGE#<timestamp>` | - | Query on PK, descending SK |
| **Messages for user (inbox)** | - | - | GSI1PK: `USER#<userId>`, GSI1SK: `MESSAGE#<timestamp>` | Query on GSI1 |
| **Notifications by user** | `USER#<userId>` | `NOTIFICATION#<timestamp>` | - | Query on PK, descending SK |
| **Backups by user** | `USER#<userId>` | `BACKUP#<timestamp>` | - | Query on PK, descending SK |
| **Recovery Health Scores by user** | `USER#<userId>` | `RHS#<timestamp>` | - | Query on PK, descending SK |
| **FASTER Scale entries by user** | `USER#<userId>` | `FASTER#<timestamp>` | - | Query on PK, descending SK |
| **PCI entries by user** | `USER#<userId>` | `PCI#<timestamp>` | - | Query on PK, descending SK |
| **Meetings by user** | `USER#<userId>` | `MEETING#<timestamp>` | - | Query on PK, descending SK |
| **Affirmation packs owned by user** | `USER#<userId>` | `PACK#<packId>` | - | Query on PK |
| **Affirmations in pack** | `PACK#<packId>` | `AFFIRMATION#<affirmationId>` | - | Query on PK |
| **Custom affirmations by user** | `USER#<userId>` | `AFFIRMATION#CUSTOM#<affirmationId>` | - | Query on PK |
| **Support contact lookup (reverse)** | - | - | GSI1PK: `CONTACT#<contactUserId>`, GSI1SK: `USER#<userId>` | Find all users who added contactUserId |
| **Calendar activities by user+date** | `USER#<userId>` | `ACTIVITY#<YYYY-MM-DD>#<activityType>#<timestamp>` | - | Query on PK with SK begins_with date |
| **Tenant users** | - | - | GSI2PK: `TENANT#<tenantId>`, GSI2SK: `USER#<userId>` | Query on GSI2 |
| **Tenant content** | `TENANT#<tenantId>` | `CONTENT#<contentType>#<contentId>` | - | Query on PK |
| **Sessions by user** | `USER#<userId>` | `SESSION#<sessionId>` | - | Query on PK |
| **Session lookup by ID** | `SESSION#<sessionId>` | `META` | - | Single-item read |
| **Ephemeral data cleanup** | - | - | TTL attribute | DynamoDB auto-deletes expired items |

### Key Patterns Explained

#### User-Centric Data
Most recovery data is partitioned by `USER#<userId>` to enable efficient single-user queries. Sort keys use entity type prefixes (`CHECKIN#`, `URGE#`, `JOURNAL#`) followed by timestamps for chronological ordering.

#### Composite Sort Keys
For calendar views, the SK pattern `ACTIVITY#<YYYY-MM-DD>#<activityType>#<timestamp>` enables efficient date-based queries while preserving chronological order within each day.

#### Conversations & Messages
Messages use `CONVERSATION#<conversationId>` as PK to group all messages in a thread. A GSI projects messages into a user inbox view.

#### Tenant Isolation
Multi-tenancy is enforced via a `TenantId` attribute and GSI2 to list users/content per tenant. IAM policies further restrict cross-tenant access.

#### Ephemeral Data
Items with `TTL` set are automatically deleted by DynamoDB when the TTL timestamp is reached, supporting the ephemeral mode feature.

---

## 4. API Security Diagram

All API requests pass through multiple security layers before reaching application logic and data storage.

```mermaid
flowchart TD
    Client[Client - Mobile/Web] -->|HTTPS Request| TLS[TLS 1.3 Termination + Certificate Pinning]
    TLS --> Gateway[AWS API Gateway]
    Gateway --> RateLimit{Rate Limiter - 100 req/min per user}
    RateLimit -->|Exceeded| Error429[429 Too Many Requests]
    RateLimit -->|Within Limit| Cognito[AWS Cognito JWT Validation]
    Cognito -->|Invalid Token| Error401[401 Unauthorized]
    Cognito -->|Valid Token| Authorizer[Lambda Authorizer - RBAC Check]
    Authorizer -->|Forbidden Role| Error403[403 Forbidden]
    Authorizer -->|Authorized| TenantCheck{Tenant Context Validation}
    TenantCheck -->|Tenant Mismatch| Error403B[403 Forbidden]
    TenantCheck -->|Valid Tenant| PermCheck{Data Sharing Permission Check}
    PermCheck -->|No Permission| Error404[404 Not Found - Data Hiding]
    PermCheck -->|Has Permission| DataAccess[Lambda Function - Business Logic]
    DataAccess --> DynamoDB[DynamoDB - AES-256 at Rest]
    DynamoDB --> Audit[Audit Log - Data Access Event]
    Audit --> Response[Response with X-Correlation-Id]
    Response --> Client

    style Client fill:#4A90E2,color:#fff
    style TLS fill:#7ED321,color:#fff
    style Gateway fill:#7ED321,color:#fff
    style Cognito fill:#F5A623,color:#fff
    style Authorizer fill:#F5A623,color:#fff
    style DataAccess fill:#4A90E2,color:#fff
    style DynamoDB fill:#BD10E0,color:#fff
    style Response fill:#7ED321,color:#fff
    style Error401 fill:#D0021B,color:#fff
    style Error403 fill:#D0021B,color:#fff
    style Error403B fill:#D0021B,color:#fff
    style Error404 fill:#D0021B,color:#fff
    style Error429 fill:#D0021B,color:#fff
```

### Security Layer Responsibilities

#### Layer 1: Transport Security
- **TLS 1.3** encryption for all data in transit
- **Certificate pinning** in mobile clients to prevent MITM attacks
- All requests MUST use HTTPS; HTTP requests rejected at CloudFront/ALB

#### Layer 2: API Gateway
- Request validation (headers, query parameters, body schemas)
- **Rate limiting**: 100 requests/minute per user, 50,000 requests/minute global
- **Request throttling** with exponential backoff hints in `Retry-After` header
- CORS enforcement for web clients
- Request/response logging to CloudWatch

#### Layer 3: Authentication
- **AWS Cognito** validates JWT access tokens
- Tokens expire after 15 minutes; refresh tokens rotate every use
- OAuth 2.0 flows: Authorization Code + PKCE (clients), Client Credentials (service-to-service)
- Passkey support via WebAuthn for passwordless auth
- MFA optional but recommended

#### Layer 4: Authorization (RBAC)
- **Lambda Authorizer** enforces role-based access control
- Roles: User, Spouse, Sponsor, Coach, Counselor, Admin
- Each endpoint mapped to required scopes:
  - `recovery:read` - Read own recovery data
  - `recovery:write` - Write own recovery data
  - `recovery:admin` - Admin operations
  - `support:read` - Read shared data as support contact
  - `support:write` - Write feedback as support contact
  - `tenant:admin` - Tenant-level admin operations
- JWT contains `sub` (userId), `role`, and `scopes`

#### Layer 5: Tenant Isolation
- Multi-tenant architecture with strict isolation
- Every request includes `TenantId` extracted from JWT or inferred from userId
- DynamoDB queries scoped to tenant partition keys
- IAM policies enforce tenant-level access boundaries
- Cross-tenant data leakage prevented at infrastructure level

#### Layer 6: Data Sharing Permissions
- Granular permission model: user explicitly grants access per person, per data category
- **Default deny**: No one can view user data unless explicitly granted
- Permission check occurs before every data access
- If user lacks read access to requested resource (e.g., write-only role), return **404 Not Found** (not 403) to hide existence
- Spouse can view shared data categories only with opt-in
- Sponsor/Counselor/Coach permissions managed per activity category

#### Layer 7: Business Logic & Data Access
- **Lambda functions** (Go) execute domain logic
- All database queries scoped to authenticated user
- User-derived encryption keys planned for future field-level encryption
- Sensitive operations (account deletion, data export) require re-authentication
- **Correlation ID** (`X-Correlation-Id`) propagated through all service calls for tracing

#### Layer 8: Data Storage
- **DynamoDB** with server-side AES-256 encryption at rest
- Point-in-time recovery enabled (24-hour window)
- Automated daily backups retained for 90 days
- Ephemeral data auto-deleted via TTL

#### Layer 9: Audit Trail
- Every data access by support contacts logged
- Audit events include: who accessed, what data category, timestamp
- Audit log queryable via `/v1/users/me/audit` endpoint
- Optional push notifications for data access events

#### Layer 10: Response
- Structured error responses following Siemens guidelines [304, 305]
- `X-Correlation-Id` header in every response for debugging
- `Api-Version` header indicates semantic version
- `Cache-Control` and `ETag` headers for cacheable resources
- Rate limit headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`

---

## 5. API Design Principles

### Siemens Guidelines Compliance

Regal Recovery API is designed according to **Siemens REST API Guidelines v2.5.1** and **Common API Guidelines v2.2.1** [101-999].

#### Document Structure [101.2]

All responses use the Siemens top-level JSON object structure:

```json
{
  "data": { ... },
  "links": {
    "self": "https://api.regalrecovery.com/v1/users/me"
  },
  "meta": {
    "createdAt": "2026-03-28T10:00:00Z",
    "modifiedAt": "2026-03-28T14:30:00Z",
    "version": "1.0.0"
  }
}
```

- **`data`** — primary data (single object, array, or `null`/`[]`) [101.3]
- **`errors`** — array of error objects (MUST NOT coexist with `data`) [101.2]
- **`meta`** — additional meta-information [101.7]
- **`links`** — hypermedia links [101.5]

#### Naming Conventions [101.8, 101.9]

- **JSON properties**: `camelCase` starting with lowercase — `sobrietyStartDate`, `checkInScore`
- **URL resources**: `kebab-case` pluralized — `/work-orders`, `/urge-logs`, `/check-ins`
- **Schema names**: `PascalCase` — `UserProfile`, `CheckInResponse`, `UrgeLogEntry`

#### Media Types [100]

- `application/json` — standard JSON for all API responses
- `application/vnd.siemens.api+json` — Siemens-compliant responses
- `application/vnd.siemens.bulk+json` — bulk operations (future)

#### Versioning [200]

- URI path versioning: `https://api.regalrecovery.com/v1/users/me`
- Response header: `Api-Version: 1.0.0` (full semantic version) [201]
- Breaking changes require major version increment
- Support max two major versions concurrently
- Deprecation phase before retirement with `Deprecation-Version` header

#### HTTP Methods [800-804]

| Method | Usage | Idempotent | Success Codes | Siemens Rule |
|--------|-------|------------|---------------|--------------|
| GET | Fetch resource(s) | Yes | 200 | [800] |
| POST | Create / trigger action | No | 201, 202, 204 | [801] |
| PATCH | Partial update (JSON Merge Patch RFC 7396) | No* | 200, 202, 204 | [802] |
| PUT | Full replace | Yes | 200, 202, 204 | [803] |
| DELETE | Remove resource | Yes | 200, 202, 204 | [804] |

- POST creation returns `201 Created` with `Location` header [801.4]
- PATCH uses JSON Merge Patch; missing fields MUST NOT be altered [802.4]
- PATCH on non-existing resource returns 404 [802.2]

#### Error Responses [300-305]

All errors follow the Siemens error object structure [304, 305]:

```json
{
  "errors": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "code": "rr:0x00000001",
      "status": 400,
      "title": "Invalid Sobriety Date",
      "detail": "Sobriety date cannot be in the future. The date you provided is 2027-05-01, which is beyond today's date.",
      "correlationId": "fe8793b2-1bf0-4d29-bf10-adcf72640ec5",
      "source": { "pointer": "/data/sobrietyStartDate" },
      "links": { "about": "https://docs.regalrecovery.com/errors/sobriety-date" }
    }
  ]
}
```

**Client Error 4xx:**
- `400 Bad Request` — Malformed request syntax
- `401 Unauthorized` — Missing/invalid auth; includes `WWW-Authenticate` header
- `403 Forbidden` — Insufficient permissions; only if user has read access, else 404
- `404 Not Found` — Resource does not exist or existence not disclosed
- `409 Conflict` — Concurrent or duplicate conflict
- `412 Precondition Failed` — `If-Match` / optimistic locking failure
- `415 Unsupported Media Type` — Unsupported `Content-Type`
- `429 Too Many Requests` — Rate limit exceeded; includes `Retry-After` header

**Server Error 5xx:**
- `500 Internal Server Error` — Unexpected server failure
- `503 Service Unavailable` — Temporary overload; includes `Retry-After` header

Error `code` prefixed with `rr:` (Regal Recovery) [305.1]. All error codes documented in API reference [305.2].

#### Pagination [600-601]

Cursor-based pagination (recommended) [601.1]:

```
GET /v1/activities/check-ins?cursor=cXdlcnR5&limit=50
```

```json
{
  "data": [...],
  "links": {
    "self": "https://api.regalrecovery.com/v1/activities/check-ins?cursor=cXdlcnR5&limit=50",
    "next": "https://api.regalrecovery.com/v1/activities/check-ins?cursor=bmV4dEN1cnNvcg&limit=50"
  },
  "meta": {
    "page": {
      "nextCursor": "bmV4dEN1cnNvcg",
      "limit": 50
    }
  }
}
```

Pagination links appear in top-level `links` using keys: `first`, `last`, `prev`, `next` [600].

#### Filtering [400-401]

Use `filter` query parameter with OData-inspired syntax [401.1]:

```
GET /v1/activities/urges?filter=intensity gt 5 and timestamp ge '2026-03-01T00:00:00Z'
```

**Operators:** `eq`, `ne`, `gt`, `lt`, `ge`, `le`, `and`, `or`, `not`, `()`

For single-member queries, direct query parameters MAY be used [401.1.1]:

```
GET /v1/activities/check-ins?date=2026-03-28
```

#### Sorting [700]

Use `sort` query parameter [700.1]. Prefix `-` descending, `+` ascending (default) [700.2.2]:

```
GET /v1/activities/check-ins?sort=-timestamp
GET /v1/tracking/milestones?sort=-achievedAt,days
```

#### Sparse Fieldsets [500]

Use `fields` query parameter [500.1]:

```
GET /v1/users/me?fields=displayName,email,primaryAddiction(type,sobrietyStartDate)
```

#### HATEOAS [101.5-101.6]

Include hypermedia links in resource responses:

```json
{
  "data": {
    "userId": "u_12345",
    "displayName": "John",
    "links": {
      "self": "https://api.regalrecovery.com/v1/users/me",
      "profile": "https://api.regalrecovery.com/v1/users/me/profile",
      "streaks": "https://api.regalrecovery.com/v1/tracking/streaks"
    }
  }
}
```

Link objects MUST contain `href` and MAY contain `rel`, `title`, `type` [101.6.1].

---

## 6. Endpoint Examples

### Authentication Endpoints

#### POST /v1/auth/register

Create a new user account.

**Request:**
```json
POST /v1/auth/register
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "SecurePassword123!",
  "displayName": "John",
  "primaryAddiction": "sex-addiction",
  "sobrietyStartDate": "2026-03-28",
  "preferredLanguage": "en"
}
```

**Response:**
```json
HTTP/1.1 201 Created
Location: https://api.regalrecovery.com/v1/users/u_12345
Api-Version: 1.0.0
X-Correlation-Id: fe8793b2-1bf0-4d29-bf10-adcf72640ec5

{
  "data": {
    "userId": "u_12345",
    "email": "john@example.com",
    "displayName": "John",
    "emailVerified": false,
    "links": {
      "self": "https://api.regalrecovery.com/v1/users/u_12345"
    }
  },
  "meta": {
    "createdAt": "2026-03-28T10:00:00Z"
  }
}
```

---

#### POST /v1/auth/login

Authenticate user and return access token.

**Request:**
```json
POST /v1/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "SecurePassword123!"
}
```

**Response:**
```json
HTTP/1.1 200 OK
Api-Version: 1.0.0

{
  "data": {
    "accessToken": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": 900,
    "tokenType": "Bearer"
  }
}
```

---

### User Endpoints

#### GET /v1/users/me

Retrieve authenticated user profile.

**Request:**
```
GET /v1/users/me
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response:**
```json
HTTP/1.1 200 OK
Api-Version: 1.0.0
ETag: "33a64df551425fcc55e4d42a148795d9f25f89d4"

{
  "data": {
    "userId": "u_12345",
    "email": "john@example.com",
    "displayName": "John",
    "role": "User",
    "primaryAddictionId": "a_67890",
    "preferredLanguage": "en",
    "preferredBibleVersion": "NIV",
    "emailVerified": true,
    "biometricEnabled": true,
    "links": {
      "self": "https://api.regalrecovery.com/v1/users/me",
      "profile": "https://api.regalrecovery.com/v1/users/me/profile",
      "settings": "https://api.regalrecovery.com/v1/users/me/settings"
    }
  },
  "meta": {
    "createdAt": "2026-03-28T10:00:00Z",
    "modifiedAt": "2026-03-28T14:30:00Z"
  }
}
```

---

#### PATCH /v1/users/me/profile

Update user profile (partial update with JSON Merge Patch).

**Request:**
```json
PATCH /v1/users/me/profile
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json
If-Match: "33a64df551425fcc55e4d42a148795d9f25f89d4"

{
  "displayName": "Jonathan",
  "gender": "male",
  "birthYear": 1985
}
```

**Response:**
```json
HTTP/1.1 200 OK
Api-Version: 1.0.0
ETag: "8f4e3bc7a2d1c6e8b9a0f5d3e2c1b4a6"

{
  "data": {
    "userId": "u_12345",
    "displayName": "Jonathan",
    "gender": "male",
    "birthYear": 1985,
    "maritalStatus": "married",
    "timeZone": "America/New_York"
  },
  "meta": {
    "modifiedAt": "2026-03-28T15:00:00Z"
  }
}
```

---

### Tracking Endpoints

#### GET /v1/tracking/streaks

Retrieve all sobriety streaks for authenticated user.

**Request:**
```
GET /v1/tracking/streaks
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response:**
```json
HTTP/1.1 200 OK
Api-Version: 1.0.0

{
  "data": [
    {
      "streakId": "s_11111",
      "addictionId": "a_67890",
      "addictionType": "sex-addiction",
      "currentStreakDays": 47,
      "longestStreakDays": 120,
      "sobrietyStartDate": "2026-02-09",
      "lastRelapseDate": null,
      "nextMilestone": {
        "days": 60,
        "daysRemaining": 13
      },
      "links": {
        "self": "https://api.regalrecovery.com/v1/tracking/streaks/a_67890",
        "milestones": "https://api.regalrecovery.com/v1/tracking/milestones?addictionId=a_67890"
      }
    }
  ],
  "meta": {
    "totalAddictions": 1,
    "totalSoberDays": 2847
  }
}
```

---

#### POST /v1/tracking/relapses

Log a relapse event.

**Request:**
```json
POST /v1/tracking/relapses
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "addictionId": "a_67890",
  "timestamp": "2026-03-28T22:15:00Z",
  "notes": "Detailed notes about the event"
}
```

**Response:**
```json
HTTP/1.1 201 Created
Location: https://api.regalrecovery.com/v1/tracking/relapses/r_98765
Api-Version: 1.0.0
X-Correlation-Id: 8d3e9f1a-4c2b-4a5e-b8c7-d9e0f1a2b3c4

{
  "data": {
    "relapseId": "r_98765",
    "addictionId": "a_67890",
    "timestamp": "2026-03-28T22:15:00Z",
    "previousStreakDays": 47,
    "notes": "Detailed notes about the event",
    "postMortemPrompted": true,
    "links": {
      "self": "https://api.regalrecovery.com/v1/tracking/relapses/r_98765",
      "postMortem": "https://api.regalrecovery.com/v1/activities/post-mortem?relapseId=r_98765"
    }
  },
  "meta": {
    "createdAt": "2026-03-28T22:16:00Z",
    "message": "Your 47-day streak has been preserved in your history. You were sober 247 out of the last 250 days — that matters."
  }
}
```

---

### Activities Endpoints

#### POST /v1/activities/check-ins

Submit a daily check-in.

**Request:**
```json
POST /v1/activities/check-ins
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "type": "daily",
  "responses": {
    "sobrietyStatus": "yes",
    "urgeCount": 2,
    "meetingAttended": true,
    "spiritualPractices": true,
    "emotionalState": 7,
    "supportNetworkContact": true,
    "overallRecoveryHealth": 8
  }
}
```

**Response:**
```json
HTTP/1.1 201 Created
Location: https://api.regalrecovery.com/v1/activities/check-ins/c_55555
Api-Version: 1.0.0

{
  "data": {
    "checkInId": "c_55555",
    "timestamp": "2026-03-28T21:00:00Z",
    "type": "daily",
    "responses": {
      "sobrietyStatus": "yes",
      "urgeCount": 2,
      "meetingAttended": true,
      "spiritualPractices": true,
      "emotionalState": 7,
      "supportNetworkContact": true,
      "overallRecoveryHealth": 8
    },
    "score": 85,
    "colorCode": "green",
    "links": {
      "self": "https://api.regalrecovery.com/v1/activities/check-ins/c_55555",
      "trends": "https://api.regalrecovery.com/v1/analytics/trends?category=checkIns"
    }
  },
  "meta": {
    "createdAt": "2026-03-28T21:00:00Z",
    "consecutiveDays": 18
  }
}
```

---

#### POST /v1/activities/urges

Log an urge with triggers and context.

**Request:**
```json
POST /v1/activities/urges
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "addictionId": "a_67890",
  "intensity": 8,
  "triggers": ["emotional", "digital", "relational"],
  "notes": "Feeling lonely after a difficult conversation",
  "sobrietyMaintained": true,
  "durationMinutes": 15
}
```

**Response:**
```json
HTTP/1.1 201 Created
Location: https://api.regalrecovery.com/v1/activities/urges/u_77777
Api-Version: 1.0.0

{
  "data": {
    "urgeId": "u_77777",
    "addictionId": "a_67890",
    "timestamp": "2026-03-28T16:45:00Z",
    "intensity": 8,
    "triggers": ["emotional", "digital", "relational"],
    "notes": "Feeling lonely after a difficult conversation",
    "sobrietyMaintained": true,
    "durationMinutes": 15,
    "links": {
      "self": "https://api.regalrecovery.com/v1/activities/urges/u_77777",
      "patterns": "https://api.regalrecovery.com/v1/analytics/correlations?category=urges"
    }
  },
  "meta": {
    "createdAt": "2026-03-28T16:45:00Z",
    "followUpScheduled": "2026-03-28T17:00:00Z"
  }
}
```

---

### Error Example

#### 403 Forbidden - Insufficient Permissions

**Request:**
```
GET /v1/users/u_99999/profile
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response:**
```json
HTTP/1.1 403 Forbidden
Api-Version: 1.0.0
X-Correlation-Id: 3f8e9a2b-1c4d-5e6f-a7b8-c9d0e1f2a3b4

{
  "errors": [
    {
      "id": "8a7b6c5d-4e3f-2a1b-0c9d-8e7f6a5b4c3d",
      "code": "rr:0x00000403",
      "status": 403,
      "title": "Forbidden",
      "detail": "You do not have permission to access this user's profile. If you believe you should have access, ask them to grant you permissions in their support network settings.",
      "correlationId": "3f8e9a2b-1c4d-5e6f-a7b8-c9d0e1f2a3b4",
      "links": {
        "about": "https://docs.regalrecovery.com/errors/forbidden"
      }
    }
  ]
}
```

---

## 7. Implementation Notes

### Backend Technology Stack
- **Language:** Go (fast Lambda cold starts, strong concurrency, single language for all services)
- **API Framework:** AWS Lambda + API Gateway (serverless, auto-scaling)
- **Database:** DynamoDB (serverless NoSQL, single-digit ms latency, on-demand billing)
- **Cache:** Valkey (Redis-compatible) for hot data (streaks, dashboards, session state)
- **Authentication:** AWS Cognito (OAuth 2.0, JWT, social sign-in, 50K MAU free tier)
- **Authorization:** Lambda Authorizer for RBAC
- **Async Messaging:** SQS + SNS (event-driven architecture)
- **Storage:** S3 for media, backups, static assets
- **CDN:** CloudFront for edge caching
- **Monitoring:** CloudWatch + X-Ray for logs, metrics, tracing

### Contract-First Development
1. **Design** — Write OpenAPI 3.1 spec collaboratively with front-end team
2. **Review** — Verify against Siemens guidelines before implementation
3. **Mock** — Generate mock server so mobile clients can integrate early
4. **Generate** — Produce Go server stubs from spec using `oapi-codegen`
5. **Implement** — Fill in business logic within generated handlers
6. **Validate** — Run contract tests ensuring implementation matches spec
7. **Document** — Generate interactive docs (Redoc) from spec

### OpenAPI Specification
All endpoints defined in `/docs/openapi.yaml` (to be created). Specification includes:
- Complete request/response schemas with examples
- All error status codes and error response schemas
- Security schemes (OAuth 2.0 Bearer Token)
- Required scopes per endpoint
- Query parameter validation rules
- Deprecation annotations for lifecycle management

### Code Generation
```bash
# Generate Go server stubs
oapi-codegen -package api -generate types,server openapi.yaml > internal/api/types.go

# Generate TypeScript client SDK for mobile
openapi-generator-cli generate -i openapi.yaml -g typescript-fetch -o sdk/typescript

# Generate API documentation
npx @redocly/cli build-docs openapi.yaml -o docs/api/index.html
```

### Testing Strategy
- **Unit tests** for business logic (Go `testing` package)
- **Contract tests** with Pact or OpenAPI validation middleware
- **Integration tests** against LocalStack (DynamoDB, S3, SQS, SNS)
- **Load tests** with k6 (target: 10,000 writes/second, 50,000 API requests/minute)
- **Security tests** with OWASP ZAP and AWS Inspector

### Observability
- **Correlation IDs** (`X-Correlation-Id`) propagated through all service calls
- **Structured logging** with JSON format to CloudWatch
- **Distributed tracing** with AWS X-Ray
- **Metrics** for latency (p50, p99), error rates, throughput
- **Alarms** for elevated error rates, high latency, DynamoDB throttling

### Offline-First Mobile Sync
- Mobile clients queue writes when offline
- Upon reconnection, client replays chronological write queue
- Server applies domain-specific conflict resolution:
  - **Relapse/urge logs:** Union merge (preserve all)
  - **Sobriety date:** Most conservative (earliest relapse) wins
  - **Streak calculations:** Server recalculates authoritatively
  - **Journal entries:** Preserve all with timestamps
  - **Profile changes:** Most recent write wins
- Client notified of conflicts requiring manual review

### Data Residency & GDPR Compliance
- User data stored in AWS region closest to user's jurisdiction
- EU users: data stored in `eu-west-1` (Ireland)
- B2B tenants can specify required data residency region
- Data never transferred across jurisdictional boundaries without explicit consent
- Right to data portability: `/v1/users/me/export` generates machine-readable JSON
- Right to erasure: `/v1/users/me` DELETE triggers full data purge within 30 days

---

## 8. Future Enhancements

### Zero-Knowledge Architecture (Future)
- Field-level encryption with user-derived keys
- Per-user KMS Customer Master Keys (CMKs)
- Client-side encryption before upload (journals, urge logs, messages)
- Server cannot read encrypted user content
- Cryptographic erasure for instant, verifiable deletion
- E2E encrypted messaging with Signal Protocol

### Bulk Operations [900]
- Bulk import for historical data migration
- Bulk export for data portability
- Atomic bulk create/update/delete with `application/vnd.siemens.bulk+json`

### GraphQL API (Future)
- For complex data requirements and mobile BFF (Backend for Frontend)
- Schema-first with SDL
- DataLoader to prevent N+1 queries
- Field-level authorization
- Query depth and complexity limits
- Persisted queries in production

### Webhooks
- Event notifications for B2B integrations
- POST delivery with `X-Webhook-Signature` (HMAC-SHA256)
- Retry with exponential backoff (1s, 2s, 4s, 8s, 16s)
- Management API: register, list, update, delete, test
- Event types: `user.relapse`, `user.milestone`, `check-in.completed`, `urge.logged`

### Advanced Analytics
- Machine learning insights (trigger prediction, relapse risk scoring)
- Pattern recognition across recovery data
- Personalized content recommendations
- Correlation analysis between activities and outcomes

---

## Related Documents

- [Strategic PRD](../01-strategic-prd.md)
- [Feature Specifications](../02-feature-specifications.md)
- [Technical Architecture](../03-technical-architecture.md)
- [Content Strategy](../04-content-strategy.md)

---

**Document Status:** Draft
**Next Steps:**
1. Create OpenAPI 3.1 specification in `/docs/openapi.yaml`
2. Generate Go server stubs with `oapi-codegen`
3. Implement Lambda authorizer with RBAC logic
4. Create DynamoDB single-table schema with GSIs
5. Set up CI/CD pipeline with contract testing
6. Deploy to staging environment for integration testing
