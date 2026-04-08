# Affirmations Contract Tests

Contract tests validating the Affirmations API endpoints against the OpenAPI specification.

## Coverage

All 27 API endpoints are covered with 40 test cases:

### Sessions (5 endpoints)
- `GET /activities/affirmations/session/morning` - Get morning session
- `POST /activities/affirmations/session/morning` - Complete morning session
- `GET /activities/affirmations/session/evening` - Get evening session
- `POST /activities/affirmations/session/evening` - Complete evening session
- `POST /activities/affirmations/sos` - Start SOS session

### SOS Completion (1 endpoint)
- `POST /activities/affirmations/sos/{sosId}/complete` - Complete SOS session

### Library (3 endpoints)
- `GET /activities/affirmations/library` - Browse library (paginated)
- `GET /activities/affirmations/library/{id}` - Get single affirmation
- `GET /activities/affirmations/library` (with filters) - Search library

### Favorites (3 endpoints)
- `POST /activities/affirmations/favorites` - Add favorite
- `DELETE /activities/affirmations/favorites/{id}` - Remove favorite
- `GET /activities/affirmations/favorites` - List favorites

### Hidden (3 endpoints)
- `POST /activities/affirmations/hidden` - Hide affirmation
- `DELETE /activities/affirmations/hidden/{id}` - Un-hide affirmation
- `GET /activities/affirmations/hidden` - List hidden

### Custom Affirmations (5 endpoints)
- `POST /activities/affirmations/custom` - Create custom affirmation
- `GET /activities/affirmations/custom` - List custom affirmations
- `GET /activities/affirmations/custom/{id}` - Get custom affirmation by ID
- `PATCH /activities/affirmations/custom/{id}` - Update custom affirmation
- `DELETE /activities/affirmations/custom/{id}` - Delete custom affirmation

### Audio Recordings (3 endpoints)
- `POST /activities/affirmations/{id}/audio` - Upload audio recording
- `GET /activities/affirmations/{id}/audio` - Get audio metadata
- `DELETE /activities/affirmations/{id}/audio` - Delete audio recording

### Progress & Settings (4 endpoints)
- `GET /activities/affirmations/progress` - Get progress metrics
- `GET /activities/affirmations/settings` - Get settings
- `PATCH /activities/affirmations/settings` - Update settings
- `GET /activities/affirmations/level` - Get current level info

### Level Override (1 endpoint)
- `POST /activities/affirmations/level/override` - Request level change

### Sharing (1 endpoint)
- `GET /activities/affirmations/sharing/summary` - Get sharing summary

## Test Approach

These tests validate:
1. **JSON Schema Compliance**: All types marshal/unmarshal correctly
2. **Required Fields**: Required fields are present in responses
3. **Response Envelopes**: `{data, meta, links}` structure matches spec
4. **Error Format**: `{errors: [{code, status, title, detail, correlationId}]}`
5. **Error Codes**: Domain-specific codes in `rr:0x000Axxxx` format

## Error Codes Validated

- `rr:0x000A0001` - Feature flag disabled
- `rr:0x000A0002` - Affirmation not found
- `rr:0x000A0003` - SOS session not found
- `rr:0x000A0004` - Custom affirmation not found
- `rr:0x000A0005` - Audio recording not found
- `rr:0x000A0010` - Day 14 gate not met
- `rr:0x000A0011` - 24-hour edit window expired
- `rr:0x000A0012` - 30-day minimum at level not met
- `rr:0x000A0013` - Healthy Sexuality requires 60+ days
- `rr:0x000A0020` - Invalid audio format
- `rr:0x000A0030` - Invalid day rating
- `rr:0x000A0031` - Already favorited
- `rr:0x000A0032` - Already hidden
- `rr:0x000A00FF` - Internal error

## Running Tests

```bash
# Run all contract tests
go test -v ./test/contract/affirmations/

# Run with coverage
go test -cover ./test/contract/affirmations/

# Run specific test
go test -v -run TestAffirmations_Contract_GET_MorningSession_200 ./test/contract/affirmations/
```

## Next Steps

These tests currently validate schema correctness. When HTTP handlers are implemented:
1. Extend tests to make actual HTTP requests to `httptest` server
2. Validate status codes and headers
3. Validate authentication and authorization
4. Validate feature flag behavior (404 when disabled)
5. Validate business rules (gates, edit windows, level requirements)

## Files

- `types.go` - Go types matching OpenAPI schemas (camelCase JSON, all enums, error codes)
- `contract_test.go` - 40 contract test cases covering all 27 endpoints
