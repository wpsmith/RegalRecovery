# Repository Layer

This package implements the data access layer for Regal Recovery using DynamoDB single-table design.

## Architecture

### Single-Table Design

All entities share one DynamoDB table (`regal-recovery`) with composite primary keys and Global Secondary Indexes (GSIs) to support the full set of access patterns defined in `/docs/specs/dynamodb/table-design.md`.

### Key Components

- **`dynamo.go`**: DynamoDB client wrapper with helper methods for common operations
- **`models.go`**: Data models with `dynamodbav` struct tags mapping to DynamoDB items
- **`interfaces.go`**: Repository interfaces defining contracts for each domain
- **`*_repo.go`**: Repository implementations for each domain (user, tracking, activity, flags, content, support, commitment, goal, session)
- **`helpers.go`**: Utility functions for key formatting, timestamp handling, and item defaults

## Usage

### Initialize DynamoDB Client

```go
import (
    "context"
    "github.com/aws/aws-sdk-go-v2/config"
    "github.com/regalrecovery/api/internal/repository"
)

// Load AWS config
cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion("us-east-1"))
if err != nil {
    log.Fatal(err)
}

// Create DynamoDB client (production)
dynamoClient := repository.NewDynamoClient(cfg, "regal-recovery", "")

// Create DynamoDB client (LocalStack for local development)
dynamoClient := repository.NewDynamoClient(cfg, "regal-recovery", "http://localhost:4566")
```

### Initialize Repositories

```go
userRepo := repository.NewUserRepo(dynamoClient)
trackingRepo := repository.NewTrackingRepo(dynamoClient)
activityRepo := repository.NewActivityRepo(dynamoClient)
flagRepo := repository.NewFlagRepo(dynamoClient)
contentRepo := repository.NewContentRepo(dynamoClient)
supportRepo := repository.NewSupportRepo(dynamoClient)
commitmentRepo := repository.NewCommitmentRepo(dynamoClient)
goalRepo := repository.NewGoalRepo(dynamoClient)
sessionRepo := repository.NewSessionRepo(dynamoClient)
```

### Example: Create User

```go
user := &repository.User{
    BaseItem: repository.BaseItem{
        PK:       "USER#u_12345",
        SK:       "PROFILE",
        TenantID: "DEFAULT",
    },
    OptionalGSI: repository.OptionalGSI{
        GSI1PK: aws.String("EMAIL#john@example.com"),
        GSI1SK: aws.String("USER#u_12345"),
        GSI2PK: aws.String("TENANT#DEFAULT"),
        GSI2SK: aws.String("USER#u_12345"),
    },
    Email:                 "john@example.com",
    DisplayName:           "John",
    Role:                  "User",
    PreferredLanguage:     "en",
    PreferredBibleVersion: "NIV",
    TimeZone:              "America/New_York",
    EmailVerified:         true,
    BiometricEnabled:      false,
    RegionID:              "us-east-1",
    SubscriptionTier:      "free",
}

err := userRepo.CreateUser(ctx, user)
```

### Example: Query User by Email (GSI1)

```go
user, err := userRepo.GetUserByEmail(ctx, "john@example.com")
if err != nil {
    log.Fatal(err)
}
fmt.Printf("Found user: %s\n", user.DisplayName)
```

### Example: Create Check-In

```go
checkIn := &repository.CheckIn{
    BaseItem: repository.BaseItem{
        PK:       "USER#u_12345",
        SK:       "CHECKIN#2026-03-28T21:00:00Z",
        TenantID: "DEFAULT",
    },
    CheckInID: "c_55555",
    Type:      "daily",
    Responses: map[string]interface{}{
        "sobrietyStatus":         "yes",
        "urgeCount":              2,
        "meetingAttended":        true,
        "spiritualPractices":     true,
        "emotionalState":         7,
        "supportNetworkContact":  true,
        "overallRecoveryHealth":  8,
    },
    Score:     85,
    ColorCode: "green",
}

err := activityRepo.CreateCheckIn(ctx, "u_12345", checkIn)
```

### Example: Get Calendar Activities by Date

```go
// Get all activities for a specific day
activities, err := activityRepo.GetActivitiesByDate(ctx, "u_12345", "2026-03-28")

// Get all activities for a month (date range query)
activities, err := activityRepo.GetActivitiesByDateRange(ctx, "u_12345", "2026-03-01", "2026-03-31")
```

### Example: Feature Flags

```go
// Get all flags
flags, err := flagRepo.GetAllFlags(ctx)

// Get specific flag
flag, err := flagRepo.GetFlag(ctx, "feature.recovery-agent")

// Update flag
flag.Enabled = true
flag.RolloutPercentage = 50
err := flagRepo.SetFlag(ctx, flag)
```

### Example: Support Network Permissions

```go
// Grant permission
permission := &repository.Permission{
    BaseItem: repository.BaseItem{
        PK:       "USER#u_12345",
        SK:       "PERMISSION#c_99999#streaks",
        TenantID: "DEFAULT",
    },
    PermissionID:  "p_11111",
    ContactID:     "c_99999",
    ContactUserID: "u_54321",
    DataCategory:  "streaks",
    AccessLevel:   "read",
    GrantedAt:     repository.NowISO8601(),
}

err := supportRepo.GrantPermission(ctx, permission)

// Check permission
permission, err := supportRepo.CheckPermission(ctx, "u_12345", "c_99999", "streaks")

// Revoke permission
err := supportRepo.RevokePermission(ctx, "u_12345", "c_99999", "streaks")
```

## Key Patterns

### Partition Key (PK) Patterns

- `USER#{userID}` — User-centric data (profile, settings, addictions, streaks, check-ins, urges, journals, etc.)
- `PACK#{packID}` — Affirmation pack and affirmations within pack
- `CONTENT#devotional` — Devotional content
- `CONVERSATION#{conversationId}` — Messages in a conversation
- `FLAGS` — All feature flags
- `TENANT#{tenantId}` — Tenant metadata and content
- `AGENT#{conversationId}` — Agent conversation messages
- `FLAG_AUDIT#{flagKey}` — Feature flag audit trail
- `SESSION#{sessionId}` — Session lookup via GSI1

### Sort Key (SK) Patterns

- `PROFILE` — User profile
- `SETTINGS` — User settings
- `ADDICTION#{addictionId}` — Addiction record
- `STREAK#{addictionId}` — Sobriety streak
- `CHECKIN#{timestamp}` — Check-in entry
- `URGE#{timestamp}` — Urge log
- `JOURNAL#{timestamp}` — Journal entry
- `MILESTONE#{addictionId}#{days}` — Milestone achievement
- `RELAPSE#{timestamp}` — Relapse event
- `MEETING#{timestamp}` — Meeting attendance
- `PRAYER#{timestamp}` — Prayer log
- `EXERCISE#{timestamp}` — Exercise log
- `ACTIVITY#{date}#{type}#{timestamp}` — Calendar activity (composite SK)
- `CONTACT#{contactId}` — Support contact
- `PERMISSION#{contactId}#{dataCategory}` — Permission
- `COMMITMENT#{commitmentId}` — Commitment
- `GOAL#{goalId}` — Goal
- `SESSION#{sessionId}` — Session
- `{flagKey}` — Feature flag (under PK: FLAGS)
- `META` — Affirmation pack metadata, tenant metadata

### GSI Patterns

**GSI1** (reverse lookups):
- `GSI1PK: EMAIL#{email}` — User by email
- `GSI1PK: CONTACT#{contactUserId}, GSI1SK: USER#{userId}` — Reverse contact lookup (who added me)
- `GSI1PK: SESSION#{sessionId}, GSI1SK: META` — Session by ID
- `GSI1PK: USER#{recipientId}, GSI1SK: MESSAGE#{timestamp}` — User inbox

**GSI2** (tenant queries):
- `GSI2PK: TENANT#{tenantId}, GSI2SK: USER#{userId}` — Users by tenant
- `GSI2PK: USER#{userId}#CHECKIN, GSI2SK: {YYYY-MM-DD}` — Check-ins by date

## Design Principles

1. **User-Centric Partitioning**: Most data is partitioned by `USER#{userID}` for efficient single-partition queries.
2. **Immutable Timestamps**: `CreatedAt` is set once and never updated. `ModifiedAt` tracks metadata changes only.
3. **Composite Sort Keys**: Calendar activities use `ACTIVITY#{date}#{type}#{timestamp}` for efficient day/month queries.
4. **TTL for Ephemeral Data**: Items with `expiresAt` attribute are auto-deleted by DynamoDB within 48 hours.
5. **Tenant Isolation**: Every item carries a `TenantId` attribute for multi-tenant support.

## Testing

### Local Development with LocalStack

```bash
# Start LocalStack
docker run --rm -d -p 4566:4566 localstack/localstack

# Create table
aws dynamodb create-table \
  --table-name regal-recovery \
  --attribute-definitions AttributeName=PK,AttributeType=S AttributeName=SK,AttributeType=S AttributeName=GSI1PK,AttributeType=S AttributeName=GSI1SK,AttributeType=S AttributeName=GSI2PK,AttributeType=S AttributeName=GSI2SK,AttributeType=S \
  --key-schema AttributeName=PK,KeyType=HASH AttributeName=SK,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST \
  --global-secondary-indexes \
    "IndexName=GSI1,KeySchema=[{AttributeName=GSI1PK,KeyType=HASH},{AttributeName=GSI1SK,KeyType=RANGE}],Projection={ProjectionType=ALL}" \
    "IndexName=GSI2,KeySchema=[{AttributeName=GSI2PK,KeyType=HASH},{AttributeName=GSI2SK,KeyType=RANGE}],Projection={ProjectionType=ALL}" \
  --endpoint-url http://localhost:4566
```

### Unit Tests

Repository tests should use `enttest` package with in-memory SQLite for fast, isolated testing. For DynamoDB-specific tests, mock the DynamoDB client or use LocalStack.

## Error Handling

All repository methods return wrapped errors with context. Use `errors.Is()` and `errors.As()` for error checking:

```go
user, err := userRepo.GetUser(ctx, "u_12345")
if err != nil {
    if strings.Contains(err.Error(), "item not found") {
        // Handle not found
    } else {
        // Handle other errors
    }
}
```

For production, consider defining sentinel errors:

```go
var ErrNotFound = errors.New("item not found")
var ErrConditionalCheckFailed = errors.New("conditional check failed")
```

## Performance Considerations

- **Pre-allocate slices**: Use `make([]T, 0, capacity)` when the size is known.
- **Batch operations**: Use `BatchGetItem` and `BatchWriteItem` for multiple items.
- **Transactions**: Use `TransactWriteItems` for atomic multi-item writes.
- **Consistent reads**: Use `ConsistentRead: true` only when strong consistency is required (adds cost).
- **Caching**: Cache frequently accessed data (e.g., feature flags, streaks) in Valkey with appropriate TTLs.
- **Pagination**: Use `LastEvaluatedKey` for cursor-based pagination on large result sets.

## Migration and Versioning

When key patterns need to change:

1. Add new key patterns alongside existing ones (additive change).
2. Dual-write to both old and new patterns during migration.
3. Backfill historical data to new patterns.
4. Switch reads to new patterns.
5. Stop writing to old patterns.
6. Clean up old items.

This expand-and-contract approach avoids downtime.

## Related Documentation

- [DynamoDB Single-Table Design Specification](/docs/specs/dynamodb/table-design.md)
- [API Data Model](/docs/architecture/api-data-model.md)
- [AWS Infrastructure](/docs/architecture/aws-infrastructure.md)
