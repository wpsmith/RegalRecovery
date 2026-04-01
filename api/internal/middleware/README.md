# Middleware Package

Production-ready HTTP middleware for the Regal Recovery Go backend.

## Overview

This package provides a complete middleware chain for AWS Lambda + API Gateway environments with local development support.

## Components

### Auth Middleware (`auth.go`)

JWT validation and claims extraction:
- Validates Bearer token from Authorization header
- Parses and extracts JWT claims (sub, email, custom:tenantId)
- Stores claims in context for downstream use
- **Local dev bypass**: token `dev-token` injects hardcoded user `u_alex` with tenant `DEFAULT`

**Usage:**
```go
handler := middleware.AuthMiddleware(yourHandler)

// In your handler:
userID := middleware.GetUserID(r.Context())
tenantID := middleware.GetTenantID(r.Context())
email := middleware.GetEmail(r.Context())
```

### Tenant Middleware (`tenant.go`)

Enforces tenant isolation:
- Verifies tenantId exists in context (set by AuthMiddleware)
- Returns 403 if tenant ID is missing
- All downstream repository calls can use `GetTenantID(ctx)` for isolation

**Usage:**
```go
// Must run after AuthMiddleware
handler := middleware.TenantMiddleware(yourHandler)
```

### Logging Middleware (`logging.go`)

Structured JSON logging via `log/slog`:
- Logs method, path, status code, duration, correlation ID, user agent
- Captures response status codes correctly
- Production-ready JSON output

**Usage:**
```go
handler := middleware.LoggingMiddleware(yourHandler)
```

### Correlation Middleware (`correlation.go`)

Correlation ID generation and propagation:
- Reads `X-Correlation-Id` header or generates UUID if missing
- Injects correlation ID into context and response headers
- Enables distributed tracing across services

**Usage:**
```go
handler := middleware.CorrelationMiddleware(yourHandler)

// In your handler:
correlationID := middleware.GetCorrelationID(r.Context())
```

### Recovery Middleware (`recovery.go`)

Panic recovery:
- Catches panics in handlers
- Logs full stack trace with correlation ID
- Returns 500 error response
- Prevents Lambda crashes

**Usage:**
```go
handler := middleware.RecoveryMiddleware(yourHandler)
```

### Chain Helper (`chain.go`)

Middleware composition utility:
- Applies middlewares in order (last middleware wraps innermost)
- Clean, readable middleware chaining

**Usage:**
```go
handler := middleware.Chain(
    yourHandler,
    middleware.CorrelationMiddleware,  // executed 3rd
    middleware.AuthMiddleware,         // executed 2nd
    middleware.TenantMiddleware,       // executed 1st (before handler)
)
```

## Recommended Middleware Order

```go
handler := middleware.Chain(
    yourHandler,
    middleware.RecoveryMiddleware,    // Outermost: catch all panics
    middleware.CorrelationMiddleware, // Generate correlation ID early
    middleware.LoggingMiddleware,     // Log with correlation ID
    middleware.AuthMiddleware,        // Validate JWT, extract claims
    middleware.TenantMiddleware,      // Enforce tenant isolation
)
```

Execution flow: `RecoveryMiddleware -> CorrelationMiddleware -> LoggingMiddleware -> AuthMiddleware -> TenantMiddleware -> yourHandler`

## Local Development

Set token to `dev-token` to bypass JWT validation:
```bash
curl -H "Authorization: Bearer dev-token" http://localhost:8080/api/streaks
```

This injects:
- UserID: `u_alex`
- TenantID: `DEFAULT`
- Email: `alex@dev.local`

## Production Considerations

1. **JWT Signature Verification**: AuthMiddleware currently skips signature validation. In production, fetch Cognito JWKS endpoint and verify token signatures.
2. **Structured Logging**: Configure `log/slog` JSON handler in production for CloudWatch compatibility.
3. **Error Responses**: All error responses follow Siemens API conventions with structured error format.
4. **Context Propagation**: All middlewares use typed context keys to avoid collisions.
