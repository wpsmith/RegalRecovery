# Regal Recovery API - Core Packages Summary

**Created:** 2026-03-31
**Module:** `github.com/regalrecovery/api`
**Go Version:** 1.26.1

This document summarizes the middleware, cache, and events packages created for the Regal Recovery Go backend.

---

## Package Overview

### 1. Middleware (`internal/middleware/`)

Production-ready HTTP middleware chain with 6 components:

| File | Purpose | Key Exports |
|------|---------|-------------|
| `auth.go` | JWT validation, claims extraction | `AuthMiddleware`, `GetUserID`, `GetTenantID`, `GetEmail` |
| `tenant.go` | Tenant isolation enforcement | `TenantMiddleware` |
| `logging.go` | Structured JSON logging via `log/slog` | `LoggingMiddleware` |
| `correlation.go` | Correlation ID generation/propagation | `CorrelationMiddleware`, `GetCorrelationID` |
| `recovery.go` | Panic recovery with stack trace logging | `RecoveryMiddleware` |
| `chain.go` | Middleware composition helper | `Chain` |

**Recommended Chain:**
```go
handler := middleware.Chain(
    yourHandler,
    middleware.RecoveryMiddleware,    // Outermost
    middleware.CorrelationMiddleware,
    middleware.LoggingMiddleware,
    middleware.AuthMiddleware,
    middleware.TenantMiddleware,      // Innermost
)
```

**Local Dev:**
- Use token `dev-token` to bypass JWT validation
- Injects dev user: `u_alex`, tenant: `DEFAULT`, email: `alex@dev.local`

---

### 2. Cache (`internal/cache/`)

Valkey (Redis-compatible) caching layer with cache-aside pattern:

| File | Purpose | Key Exports |
|------|---------|-------------|
| `valkey.go` | Valkey client wrapper | `ValkeyClient`, `NewValkeyClient`, `Get`, `Set`, `Delete`, `Close` |
| `streak_cache.go` | Streak cache-aside implementation | `StreakCache`, `NewStreakCache`, `GetStreak`, `SetStreak`, `InvalidateStreak` |

**Streak Structure:**
```go
type Streak struct {
    UserID        string    `json:"userId"`
    CurrentDays   int       `json:"currentDays"`
    SobrietyDate  time.Time `json:"sobrietyDate"`
    LongestStreak int       `json:"longestStreak"`
    TotalRelapses int       `json:"totalRelapses"`
}
```

**TTL Configuration:**
- Streak: 5 minutes
- Key format: `streak:{userID}`

**Cache-Aside Pattern:**
1. Try cache first (`GetStreak`)
2. On miss (returns `nil`), fetch from DB
3. Populate cache with `SetStreak`
4. On write, invalidate with `InvalidateStreak`

---

### 3. Events (`internal/events/`)

Domain event publishing via AWS SNS:

| File | Purpose | Key Exports |
|------|---------|-------------|
| `types.go` | Event type definitions | `EventType`, `Event` |
| `publisher.go` | Publisher interface | `Publisher` interface |
| `sns.go` | SNS publisher implementation | `SNSPublisher`, `NewSNSPublisher` |

**Event Types:**
- `milestone.achieved` - User reaches a milestone (30 days, 90 days, etc.)
- `relapse.recorded` - User records a relapse
- `streak.updated` - Streak data changes
- `checkin.completed` - User completes a check-in
- `activity.logged` - User logs an activity

**Event Structure:**
```go
type Event struct {
    Type          EventType              // Event type identifier
    UserID        string                 // User who triggered the event
    TenantID      string                 // Tenant isolation
    Timestamp     time.Time              // Event timestamp
    CorrelationID string                 // Distributed tracing
    Data          map[string]interface{} // Event-specific payload
}
```

**Local Dev Mode:**
- Pass empty `topicARN` to `NewSNSPublisher`
- Events are logged via `log/slog` instead of published

**SNS Message Attributes:**
- `event_type` - Event type string
- `tenant_id` - Tenant ID for filtering
- `user_id` - User ID for filtering

---

## Dependencies

All required dependencies already present in `go.mod`:
- `github.com/golang-jwt/jwt/v5` v5.3.1 - JWT parsing
- `github.com/google/uuid` v1.6.0 - UUID generation
- `github.com/valkey-io/valkey-go` v1.0.73 - Valkey client
- `github.com/aws/aws-sdk-go-v2/service/sns` v1.39.15 - SNS publishing
- `log/slog` - Standard library (Go 1.21+)

---

## Code Quality

All packages:
- Pass `gofmt` formatting
- Pass `go vet` static analysis
- Compile successfully with Go 1.26.1
- Follow Go idiomatic patterns (accept interfaces, return structs)
- Use structured logging with `log/slog`
- Implement proper error wrapping with `%w`
- Use typed context keys to avoid collisions
- Handle goroutine lifecycle (no fire-and-forget)

---

## Local Development Setup

1. **Start LocalStack + Valkey:**
   ```bash
   make local-up
   ```

2. **Valkey available at:** `localhost:6379`

3. **Test with dev token:**
   ```bash
   curl -H "Authorization: Bearer dev-token" http://localhost:8080/api/streaks
   ```

---

## Production Considerations

### Middleware
1. **JWT Signature Verification**: Fetch Cognito JWKS and verify signatures in production
2. **Structured Logging**: Configure JSON handler for CloudWatch
3. **Error Responses**: Follow Siemens API conventions

### Cache
1. **Connection Pooling**: Handled by valkey-go automatically
2. **Error Handling**: Cache errors should not fail requests (log and fall back to DB)
3. **TTL Tuning**: Monitor cache hit rates and adjust TTLs
4. **Memory Management**: Configure `maxmemory` and eviction policy (LRU recommended)

### Events
1. **SNS Topic ARN**: Load from environment or SSM Parameter Store
2. **At-Least-Once Delivery**: Consumers must be idempotent
3. **Error Handling**: Retry failed publishes, use DLQ for poison messages
4. **Event Schema Versioning**: Include `version` field in `Data` if schema evolves
5. **Monitoring**: Track publish failures and latency in CloudWatch

---

## Testing Strategy

### Unit Tests
- Mock `Publisher` interface for domain logic tests
- Mock Valkey client for cache tests
- Use `httptest` for middleware tests

### Integration Tests
- Use LocalStack for SNS integration tests
- Use Valkey (via docker-compose) for cache integration tests
- Test middleware chain with real HTTP requests

### E2E Tests
- Test full request path: API Gateway -> Lambda -> handler -> repository -> cache/events

---

## Next Steps

1. **Implement domain packages** (`internal/domain/tracking`, `internal/domain/activities`, etc.)
2. **Create repository interfaces** (`internal/repository/interfaces.go`)
3. **Write unit tests** for each middleware component
4. **Write integration tests** for cache and events
5. **Wire middleware chain** in Lambda entrypoints (`cmd/lambda/*/main.go`)
6. **Add JWKS verification** to AuthMiddleware for production
7. **Configure structured logging** with JSON handler
8. **Add rate limiting middleware** (backed by Valkey)

---

## File Locations

```
/Users/travis.smith/Projects/personal/RR/api/internal/
├── middleware/
│   ├── auth.go            # JWT validation
│   ├── tenant.go          # Tenant isolation
│   ├── logging.go         # Structured logging
│   ├── correlation.go     # Correlation ID
│   ├── recovery.go        # Panic recovery
│   ├── chain.go           # Middleware composition
│   └── README.md          # Middleware documentation
├── cache/
│   ├── valkey.go          # Valkey client wrapper
│   ├── streak_cache.go    # Streak cache-aside
│   └── README.md          # Cache documentation
└── events/
    ├── types.go           # Event type definitions
    ├── publisher.go       # Publisher interface
    ├── sns.go             # SNS publisher implementation
    └── README.md          # Events documentation
```

---

## References

- [Development Workflow](/Users/travis.smith/Projects/personal/RR/docs/specs/development-workflow.md)
- [Siemens API Conventions](~/.claude/skills/api-conventions)
- Go 1.26.1 Documentation: https://go.dev/doc/
- Valkey Documentation: https://valkey.io/
- AWS SNS Developer Guide: https://docs.aws.amazon.com/sns/
