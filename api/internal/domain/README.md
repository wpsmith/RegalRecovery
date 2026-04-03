# Regal Recovery Domain Services

This directory contains the domain service layer for the Regal Recovery backend. Domain services implement business logic and have NO knowledge of HTTP, Lambda, or MongoDB. They accept and return domain types and depend on repository interfaces defined locally.

## Architecture Principles

1. **Domain-Driven Design**: Each domain is self-contained with its own types, service logic, and repository interfaces.
2. **Dependency Injection**: Services accept repository interfaces as constructor parameters.
3. **Clean Architecture**: Domain services have no infrastructure dependencies.
4. **Idiomatic Go**: Standard library first, clear error handling, context propagation throughout.

## Domains

### 1. Auth Domain (`internal/domain/auth/`)

**Purpose**: User authentication, registration, and session management.

**Files**:
- `types.go` - User, Session, RegisterRequest, RegisterResponse, SessionResponse
- `repository.go` - UserRepository, SessionRepository, TokenService interfaces
- `service.go` - AuthService with registration and session management logic

**Key Methods**:
- `Register(ctx, RegisterRequest)` - Creates new user, validates input, returns tokens
- `GetSession(ctx)` - Retrieves current session from context
- `GetUserByID(ctx, userID)` - Retrieves user by ID
- `CreateSession(ctx, userID, deviceID, ...)` - Creates new user session
- `RevokeSession(ctx, sessionID)` - Revokes a session

**Dependencies**: UserRepository, SessionRepository, TokenService

---

### 2. Flags Domain (`internal/domain/flags/`)

**Purpose**: Feature flag evaluation with gradual rollout, tier gating, and platform filtering.

**Files**:
- `types.go` - Flag, EvaluatedFlag, UserContext, response envelopes
- `repository.go` - FlagRepository, FlagCache interfaces
- `service.go` - FlagService with evaluation logic and consistent hashing

**Key Methods**:
- `EvaluateFlag(ctx, flagKey, UserContext)` - Evaluates flag for user based on tier, platform, version, rollout %
- `EvaluateAllFlags(ctx, UserContext)` - Evaluates all flags for user
- `GetAllFlags(ctx)` - Admin: retrieves all flag configurations
- `SetFlag(ctx, Flag)` - Admin: creates/updates flag

**Flag Evaluation Logic**:
1. Master kill switch (enabled/disabled)
2. Tier restrictions (free-trial, premium, premium-plus)
3. Tenant restrictions
4. Platform restrictions (iOS, Android)
5. Minimum app version (semver comparison)
6. Rollout percentage (deterministic SHA256 hash on userID)

**Dependencies**: FlagRepository, FlagCache

---

### 3. Tracking Domain (`internal/domain/tracking/`)

**Purpose**: Sobriety streak tracking, milestone management, relapse recording, calendar views.

**Files**:
- `types.go` - StreakData, Milestone, Relapse, CalendarEntry, response envelopes
- `repository.go` - StreakRepository, MilestoneRepository, RelapseRepository, CalendarRepository, StreakCache, EventPublisher interfaces
- `service.go` - TrackingService with streak management and compassionate messaging
- `calculator.go` - Pure functions for streak calculation, milestone logic, scriptures

**Key Methods**:
- `GetStreak(ctx, addictionID)` - Retrieves current streak with cache-aside pattern
- `RecordRelapse(ctx, userID, addictionID, timestamp, notes)` - Records relapse, resets streak, returns compassionate message
- `GetMilestones(ctx, addictionID)` - Retrieves earned and upcoming milestones
- `CheckAndAwardMilestone(ctx, addictionID, streak)` - Awards milestone if threshold reached
- `GetCalendar(ctx, userID, month)` - Retrieves calendar view for month
- `GetCalendarDay(ctx, userID, date)` - Retrieves detailed day view

**Milestone Thresholds**: 1, 3, 7, 14, 21, 30, 60, 90, 120, 180, 270, 365, 540, 730, 1095, 1460, 1825, 2555, 3650 days

**Compassionate Messaging**: After relapse, returns message like "Your 47-day streak has been preserved in your history. You were sober 247 out of the last 250 days — that matters."

**Dependencies**: StreakRepository, MilestoneRepository, RelapseRepository, CalendarRepository, StreakCache, EventPublisher

---

### 4. Activities Domain (`internal/domain/activities/`)

**Purpose**: Recovery activity tracking with 25+ activity types (commitments, journals, check-ins, FASTER, PCI, urges, etc.).

**Files**:
- `types.go` - Activity, activity type constants, specialized data types for each activity
- `repository.go` - ActivityRepository interface
- `service.go` - ActivityService with activity logging and retrieval

**Activity Types**:
- Commitments (morning/evening)
- Journals (bullet, free-form, emotional, time-based)
- Check-ins (daily, person-specific)
- FASTER Scale assessments
- Personal Craziness Index (PCI)
- Urge logs
- Mood ratings
- Gratitude entries
- Phone calls
- Prayer logs
- Meeting attendance
- Exercise and nutrition
- Devotionals
- Integrity inventory
- Acting-in behaviors
- Post-mortem analysis
- Financial tracking
- Step work
- Goals
- Spouse check-in prep (FANOS/FITNAP)

**Key Methods**:
- `LogActivity(ctx, userID, activityType, data, ephemeral)` - Creates activity log with immutable timestamp
- `GetActivities(ctx, userID, activityType, cursor, limit)` - Retrieves activities with cursor pagination
- `GetActivitiesByDate(ctx, userID, date)` - Retrieves all activities for a specific date
- `GetActivitiesInRange(ctx, userID, startDate, endDate, activityType)` - Retrieves activities in date range

**Dependencies**: ActivityRepository

---

### 5. Content Domain (`internal/domain/content/`)

**Purpose**: Devotional and affirmation content retrieval with caching.

**Files**:
- `types.go` - AffirmationPack, Affirmation, Devotional, response envelopes
- `repository.go` - ContentRepository, ContentCache interfaces
- `service.go` - ContentService with cache-aside pattern

**Key Methods**:
- `GetAffirmationPacks(ctx)` - Retrieves all affirmation packs (1-hour cache TTL)
- `GetAffirmationPack(ctx, packID)` - Retrieves specific pack
- `GetDevotional(ctx, day)` - Retrieves devotional by day number (1-hour cache TTL)
- `GetTodaysAffirmation(ctx, userID, packID)` - Returns deterministic daily affirmation for user

**Dependencies**: ContentRepository, ContentCache

---

## Response Patterns (Siemens API Conventions)

All domain services return data that handlers format into Siemens-compliant envelopes:

### Success Response:
```json
{
  "data": { ... },
  "links": {
    "self": "https://api.regalrecovery.com/v1/resource/id"
  },
  "meta": {
    "createdAt": "2026-03-28T10:00:00Z",
    "modifiedAt": "2026-03-28T14:30:00Z"
  }
}
```

### Error Response:
```json
{
  "errors": [{
    "id": "uuid",
    "code": "rr:0x00000001",
    "status": 400,
    "title": "Human-readable summary",
    "detail": "Occurrence-specific description",
    "correlationId": "uuid",
    "source": { "pointer": "/fieldName" },
    "links": { "about": "https://docs.regalrecovery.com/errors/..." }
  }]
}
```

### Pagination:
```json
{
  "data": [...],
  "links": {
    "self": "...",
    "next": "...?cursor=xyz&limit=50",
    "prev": "..."
  },
  "meta": {
    "page": {
      "nextCursor": "xyz",
      "limit": 50
    }
  }
}
```

## Error Handling

All domain services return wrapped errors with context:

```go
if err != nil {
    return nil, fmt.Errorf("operation failed: %w", err)
}
```

Sentinel errors are defined at package level:
- `ErrInvalidInput`
- `ErrNotFound`
- `ErrAlreadyExists`
- `ErrUnauthorized`

## Testing

Domain services are highly testable:
1. Mock repository interfaces
2. Test business logic in isolation
3. No infrastructure dependencies
4. Pure functions in calculator.go

## Next Steps

To implement HTTP handlers or Lambda handlers:
1. Import domain service packages
2. Implement repository interfaces (MongoDB adapters)
3. Wire dependencies via constructors
4. Format domain responses into Siemens envelopes
5. Add correlation IDs, API versioning headers

## Dependencies

- Standard library (`context`, `time`, `errors`, `fmt`, `crypto/sha256`)
- `github.com/hashicorp/go-version` (semver comparison for flags)

No HTTP, Lambda, or MongoDB dependencies in domain layer.
