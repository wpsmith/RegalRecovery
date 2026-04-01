# Regal Recovery — OpenAPI Specifications

**Version:** 1.0.0
**Date:** 2026-03-28
**Status:** Active

---

## Overview

This directory contains the complete OpenAPI 3.1 specifications for the Regal Recovery REST API. All API endpoints are designed following **Siemens REST API Guidelines v2.5.1** and **Common API Guidelines v2.2.1**, with strict adherence to contract-first development principles.

---

## Contract-First Development Workflow

Regal Recovery follows a **spec-driven, test-first** development workflow where the OpenAPI specification is the source of truth for all API contracts.

### Development Cycle

```
┌─────────────┐
│   1. Spec   │  Write OpenAPI spec collaboratively with front-end team
└──────┬──────┘
       │
┌──────▼──────┐
│ 2. Generate │  oapi-codegen creates Go server interfaces; hand-written mobile clients
└──────┬──────┘
       │
┌──────▼──────┐
│  3. Test    │  Write acceptance tests against the spec (RED)
└──────┬──────┘
       │
┌──────▼──────┐
│4. Implement │  Fill in business logic to satisfy interface contracts
└──────┬──────┘
       │
┌──────▼──────┐
│  5. Test    │  Run tests against implementation (GREEN)
└──────┬──────┘
       │
┌──────▼──────┐
│ 6. Refactor │  Improve implementation without changing the spec
└──────┬──────┘
       │
       └─────────► Deploy to staging → Contract validation → Production
```

### Why Contract-First?

1. **Parallel Development** — Front-end teams can integrate against mock servers while back-end implements business logic
2. **Clear Contracts** — No ambiguity between teams; the spec is the single source of truth
3. **Automated Validation** — Generated types prevent drift between spec and implementation
4. **Documentation** — Interactive API docs are generated directly from the spec, always accurate
5. **Testing** — Contract tests validate that implementation matches the spec exactly
6. **Client SDKs** — TypeScript client libraries generated from spec; Kotlin (Android) and Swift (iOS) clients hand-written to match spec

---

## Specification Files

Each API domain has its own OpenAPI specification file, organized by bounded context:

| File | Domain | Description |
|------|--------|-------------|
| `auth.yaml` | Authentication | Registration, login, passkeys, session management |
| `users.yaml` | User Profile | Profile, settings, privacy, addiction tracking |
| `tracking.yaml` | Sobriety Tracking | Streaks, milestones, calendar, relapse logging |
| `activities.yaml` | Recovery Activities | Commitments, check-ins, journals, assessments, self-care |
| `content.yaml` | Content Library | Affirmations, devotionals, prayers, resources, packs |
| `community.yaml` | Support Network | Contacts, permissions, messaging, broadcasts |
| `analytics.yaml` | Analytics | Dashboard, health score, trends, insights, correlations |
| `tools.yaml` | Recovery Tools | 3 Circles, relapse prevention plan, vision, arousal template |
| `assessments.yaml` | Clinical Assessments | SAST-R, denial, severity, relationship health |
| `notifications.yaml` | Notifications | Preferences, history, snooze, delivery |
| `integrations.yaml` | Third-Party Integrations | Health sync, calendar, meetings, Spotify |
| `backup.yaml` | Data Backup & DSR | Backup creation/restore, data export, account deletion |
| `agent.yaml` | Recovery Agent | AI chatbot conversations, tool execution, context management |

---

## Siemens Guidelines Compliance

All API specifications conform to **Siemens REST API Guidelines v2.5.1** [rules 100-999].

### Document Structure [101.2]

Every response uses the Siemens top-level JSON object structure:

```json
{
  "data": { ... },
  "links": { "self": "..." },
  "meta": { "createdAt": "...", "modifiedAt": "..." }
}
```

- `data` — primary data (object, array, or null) [101.3]
- `errors` — error object array (MUST NOT coexist with `data`) [101.2]
- `meta` — additional metadata [101.7]
- `links` — hypermedia links [101.5]

### Naming Conventions [101.8, 101.9]

- **JSON properties:** `camelCase` starting lowercase — `sobrietyStartDate`, `currentStreakDays`
- **URL resources:** `kebab-case` pluralized — `/check-ins`, `/urge-logs`, `/three-circles`
- **Schema names:** `PascalCase` — `UserProfile`, `CheckInResponse`, `StreakData`

### HTTP Methods [800-804]

| Method | Usage | Idempotent | Success Codes | Rule |
|--------|-------|------------|---------------|------|
| GET | Fetch resource(s) | Yes | 200 | [800] |
| POST | Create resource or trigger action | No | 201, 202, 204 | [801] |
| PATCH | Partial update (JSON Merge Patch RFC 7396) | No | 200, 202, 204 | [802] |
| PUT | Full replace | Yes | 200, 202, 204 | [803] |
| DELETE | Remove resource | Yes | 200, 202, 204 | [804] |

### Error Responses [304, 305]

All errors follow the Siemens error object structure:

```json
{
  "errors": [{
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "code": "rr:0x00000001",
    "status": 400,
    "title": "Invalid Sobriety Date",
    "detail": "Sobriety date cannot be in the future",
    "correlationId": "fe8793b2-1bf0-4d29-bf10-adcf72640ec5",
    "source": { "pointer": "/data/sobrietyStartDate" },
    "links": { "about": "https://docs.regalrecovery.com/errors/sobriety-date" }
  }]
}
```

**Client Errors (4xx):**
- `400 Bad Request` — Malformed syntax
- `401 Unauthorized` — Missing/invalid auth (includes `WWW-Authenticate` header)
- `403 Forbidden` — Insufficient permissions (only if user has read access; otherwise 404)
- `404 Not Found` — Resource does not exist or existence not disclosed
- `409 Conflict` — Duplicate or concurrent modification conflict
- `412 Precondition Failed` — `If-Match` optimistic locking failure
- `422 Unprocessable Entity` — Validation failure (well-formed but semantically invalid)
- `429 Too Many Requests` — Rate limit exceeded (includes `Retry-After` header)

**Server Errors (5xx):**
- `500 Internal Server Error` — Unexpected server failure
- `503 Service Unavailable` — Temporary overload (includes `Retry-After` header)

### Pagination [600-601]

**Cursor-based (recommended)** [601.1]:

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

### Filtering [400-401]

OData-inspired syntax [401.1]:

```
GET /v1/activities/urges?filter=intensity gt 5 and timestamp ge '2026-03-01T00:00:00Z'
```

**Operators:** `eq`, `ne`, `gt`, `lt`, `ge`, `le`, `and`, `or`, `not`, `()`

### Sorting [700]

Use `sort` query parameter with `-` (descending) or `+` (ascending):

```
GET /v1/activities/check-ins?sort=-timestamp
GET /v1/tracking/milestones?sort=-achievedAt,days
```

### Versioning [200]

- **URI path versioning:** `https://api.regalrecovery.com/v1/users/me`
- **Response header:** `Api-Version: 1.0.0` (full semantic version) [201]
- Breaking changes require major version increment
- Support max two major versions concurrently
- Deprecation phase before retirement with `Deprecation-Version` header

### Security

All endpoints require OAuth 2.0 Bearer Token (Cognito JWT) over TLS 1.3:

```yaml
components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: AWS Cognito JWT access token
```

**Scopes:**
- `recovery:read` — Read own recovery data
- `recovery:write` — Write own recovery data
- `recovery:admin` — Admin operations
- `support:read` — Read shared data as support contact
- `support:write` — Write feedback as support contact
- `tenant:admin` — Tenant-level admin operations

---

## Code Generation

### Go Server Stubs (oapi-codegen)

Generate Go types and server interfaces from OpenAPI specs:

```bash
# Install oapi-codegen
go install github.com/deepmap/oapi-codegen/v2/cmd/oapi-codegen@latest

# Generate types and server interfaces for all domains
make generate-server

# Or generate individually
oapi-codegen -package api -generate types,chi-server \
  -o internal/api/auth/types.go \
  specs/openapi/auth.yaml
```

**Generated artifacts:**
- `types.go` — Request/response structs with validation tags
- `server.go` — Server interface with method signatures matching spec
- Business logic implements the generated interface

### Native Mobile Clients

Mobile API clients are hand-written for each platform to conform to the OpenAPI spec. Contract tests validate correctness.

**Android (Kotlin):** Hand-written API client classes with Retrofit/OkHttp in `androidApp/.../data/api/`. Validated by contract tests.

**iOS (Swift):** Hand-written API client structs with URLSession in `iosApp/.../Data/API/`. Validated by contract tests.

### TypeScript Client (for Web/React Native)

```bash
# Generate TypeScript Fetch client
openapi-generator-cli generate \
  -i specs/openapi/auth.yaml \
  -g typescript-fetch \
  -o clients/typescript
```

### API Documentation

Generate interactive API documentation with Redoc:

```bash
# Install Redocly CLI
npm install -g @redocly/cli

# Generate HTML documentation
redocly build-docs specs/openapi/auth.yaml \
  -o docs/api/auth.html

# Or serve live preview
redocly preview-docs specs/openapi/auth.yaml
```

---

## Validation and Linting

### Validate Specs

```bash
# Validate OpenAPI spec
redocly lint specs/openapi/auth.yaml

# Validate all specs
redocly lint 'specs/openapi/*.yaml'
```

### Custom Linting Rules

The `.redocly.yaml` configuration enforces:
- Siemens naming conventions (camelCase properties, kebab-case URLs)
- Required `description` fields on all schemas and properties
- Required `example` values for all request/response schemas
- Consistent error response structures [304, 305]
- Security schemes on all endpoints
- Pagination on list endpoints returning unbounded results

---

## Testing Strategy

### Contract Testing

Validate that implementation matches the spec:

```bash
# Using Schemathesis (Python)
schemathesis run specs/openapi/auth.yaml \
  --base-url http://localhost:8080/v1 \
  --checks all \
  --hypothesis-max-examples=100

# Using Dredd (Node.js)
dredd specs/openapi/auth.yaml \
  http://localhost:8080/v1 \
  --hookfiles=test/hooks/*.js
```

### Acceptance Tests (Go)

Write acceptance tests against the generated types:

```go
func TestAuthLogin_Success(t *testing.T) {
    // Arrange
    req := api.LoginRequest{
        Email:    "test@example.com",
        Password: "SecurePassword123!",
    }

    // Act
    resp, err := client.Login(context.Background(), req)

    // Assert
    require.NoError(t, err)
    assert.NotEmpty(t, resp.Data.AccessToken)
    assert.Equal(t, "Bearer", resp.Data.TokenType)
    assert.Equal(t, 900, resp.Data.ExpiresIn)
}
```

### Mock Server

Generate a mock server for front-end integration before back-end is ready:

```bash
# Using Prism
npm install -g @stoplight/prism-cli

# Start mock server
prism mock specs/openapi/auth.yaml \
  --port 8080 \
  --dynamic
```

---

## Specification Best Practices

### 1. Complete Schemas

Every request and response schema must include:
- `description` — explains the purpose
- `type` and `format` — with validation constraints
- `required` — lists mandatory fields
- `example` — provides realistic sample data
- `enum` — for fixed value sets

### 2. Realistic Examples

Examples should be production-realistic:

```yaml
example:
  userId: "u_1a2b3c4d"
  email: "john@example.com"
  displayName: "John"
  sobrietyStartDate: "2026-01-15"
  currentStreakDays: 73
```

### 3. Comprehensive Error Responses

Document all possible error status codes with error response examples:

```yaml
responses:
  '400':
    description: Bad Request - Malformed request syntax
    content:
      application/json:
        schema:
          $ref: '#/components/schemas/ErrorResponse'
        example:
          errors:
            - id: "550e8400-e29b-41d4-a716-446655440000"
              code: "rr:0x00000001"
              status: 400
              title: "Invalid Sobriety Date"
              detail: "Sobriety date cannot be in the future"
```

### 4. Reusable Components

Define common schemas in `components` to avoid duplication:

```yaml
components:
  schemas:
    ErrorResponse:
      type: object
      properties:
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ErrorObject'

    ErrorObject:
      type: object
      required: [status, title]
      properties:
        id:
          type: string
          format: uuid
        code:
          type: string
          pattern: '^rr:0x[0-9A-F]{8}$'
        status:
          type: integer
        title:
          type: string
        detail:
          type: string
        correlationId:
          type: string
          format: uuid
        source:
          type: object
        links:
          type: object
```

### 5. Hypermedia Links

Include HATEOAS links in resource responses:

```yaml
UserProfile:
  type: object
  properties:
    userId:
      type: string
    displayName:
      type: string
    links:
      type: object
      properties:
        self:
          type: string
          format: uri
        profile:
          type: string
          format: uri
        streaks:
          type: string
          format: uri
```

---

## Changelog

### Version 1.0.0 (2026-03-28)

- Initial OpenAPI 3.1 specifications for all 13 API domains
- Siemens REST API Guidelines v2.5.1 compliance
- OAuth 2.0 Bearer Token authentication with Cognito JWT
- Cursor-based pagination for list endpoints
- Comprehensive error response schemas following [304, 305]
- HATEOAS links for resource discoverability
- Complete request/response examples for all endpoints

---

## Related Documentation

- [API Data Model](../../docs/architecture/api-data-model.md)
- [Feature Specifications](../../docs/02-feature-specifications.md)
- [Technical Architecture](../../docs/03-technical-architecture.md)
- [Siemens REST API Guidelines v2.5.1](https://developer.internal.siemens.com/guidelines/api-guidelines/)

---

## Support

For questions or issues with the API specifications:
- Review the [API Data Model](../../docs/architecture/api-data-model.md)
- Check the [Feature Specifications](../../docs/02-feature-specifications.md)
- Validate your spec with `redocly lint`
- Run contract tests before submitting PRs
