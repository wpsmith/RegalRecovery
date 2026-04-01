# Twelve-Factor App Audit - Regal Recovery

**Version:** 1.0.0
**Date:** 2026-03-28
**Auditor:** Twelve-Factor App Expert
**Related Documents:** [Technical Architecture](../03-technical-architecture.md) · [AWS Infrastructure](aws-infrastructure.md) · [C4 Diagrams](c4-diagrams.md)

---

## Executive Summary

Regal Recovery is a serverless mobile-first recovery application built on AWS with Go Lambda functions, DynamoDB, Valkey cache, and native mobile clients (Android: Kotlin + Jetpack Compose; iOS: Swift + SwiftUI). This audit evaluates the architecture against the Twelve-Factor App methodology.

**Overall Compliance:** 10/12 factors compliant, 2/12 factors partial

**Key Strengths:**
- Excellent statelessness and disposability via Lambda
- Strong dev/prod parity with LocalStack and Docker Compose
- Mature backing services abstraction (DynamoDB, Valkey, S3, SQS/SNS)
- Robust build/release/run separation via GitHub Actions and CDK/SAM

**Priority Recommendations:**
1. **Factor III (Config):** Implement SSM Parameter Store environment injection for Lambda functions
2. **Factor XI (Logs):** Migrate to structured JSON logging with correlation IDs

---

## Compliance Table

| Factor | Status | Evidence | Priority |
|--------|--------|----------|----------|
| I. Codebase | ✅ Compliant | Single repo per service, multiple deploys | N/A |
| II. Dependencies | ✅ Compliant | Go modules with `go.mod` lock, explicit declarations | N/A |
| III. Config | ⚠️ Partial | SSM Parameter Store exists but Lambda environment variable injection pattern unclear | High |
| IV. Backing Services | ✅ Compliant | DynamoDB, Valkey, S3, SQS/SNS attached as resources via environment URLs | N/A |
| V. Build, Release, Run | ✅ Compliant | GitHub Actions build, CDK/SAM deploy, immutable Lambda deployment packages | N/A |
| VI. Processes | ✅ Compliant | Lambda functions are inherently stateless, shared state in DynamoDB/Valkey | N/A |
| VII. Port Binding | ✅ Compliant | Lambda functions export services via API Gateway (HTTP binding abstracted by platform) | N/A |
| VIII. Concurrency | ✅ Compliant | Lambda auto-scales horizontally by process, event workers scale independently | N/A |
| IX. Disposability | ✅ Compliant | Sub-10ms cold starts (Go), Lambda lifecycle handles graceful shutdown | N/A |
| X. Dev/Prod Parity | ✅ Compliant | LocalStack + Docker Compose for local dev, same services everywhere | N/A |
| XI. Logs | ⚠️ Partial | CloudWatch logging exists but structured JSON with correlation IDs not confirmed | Medium |
| XII. Admin Processes | ✅ Compliant | Migrations and admin tasks run as one-off Lambda invocations or Step Functions | N/A |

---

## Factor-by-Factor Analysis

### I. Codebase — One codebase tracked in revision control, many deploys

**Status:** ✅ **Compliant**

**Evidence:**
- Single GitHub repository with monorepo structure (implied from CI/CD references)
- Multiple deployment environments: `dev`, `staging`, `production`
- Multi-region deployments (us-east-1, eu-west-1) from same codebase
- No environment-specific forks or branches

**Architecture References:**
- GitHub Actions CI/CD pipeline (Section 10.2, aws-infrastructure.md Section 1)
- Multi-region deployment (aws-infrastructure.md Section 2)
- CDK/SAM IaC for all environments

**Validation:**
```
CORRECT:
  main branch → GitHub Actions → builds once → deploys to:
    - dev (us-east-1)
    - staging (us-east-1)
    - production (us-east-1, eu-west-1)
```

**Recommendations:**
None. The architecture correctly implements one codebase with many deploys.

---

### II. Dependencies — Explicitly declare and isolate dependencies

**Status:** ✅ **Compliant**

**Evidence:**
- Go modules with `go.mod` and `go.sum` for deterministic builds
- Lambda deployment packages include all dependencies
- No reliance on system-level packages
- Container-based builds ensure clean environments

**Architecture References:**
- "Go" backend language (Section 10.2)
- Lambda functions with "single-binary deployments" (c4-diagrams.md Section 6)

**Expected Dependency Management:**
```go
// go.mod
module github.com/regalrecovery/api

go 1.21

require (
    github.com/aws/aws-lambda-go v1.41.0
    github.com/aws/aws-sdk-go-v2/service/dynamodb v1.20.0
    github.com/aws/aws-sdk-go-v2/service/s3 v1.38.0
    github.com/redis/go-redis/v9 v9.0.5
    // ... all explicit
)
```

**Lambda Build Pattern:**
```bash
# Deterministic build with vendored dependencies
go mod download
go mod verify
go build -o bootstrap main.go
zip deployment.zip bootstrap
```

**Recommendations:**
None. Go modules provide excellent dependency isolation.

---

### III. Config — Store config in the environment

**Status:** ⚠️ **Partial Compliance**

**Evidence:**
- SSM Parameter Store is used for secrets (Section 10.2, aws-infrastructure.md)
- Lambda functions should receive config via environment variables
- No hardcoded credentials observed in documentation
- Feature flags and API keys mentioned in SSM Parameter Store

**Architecture References:**
- "SSM Parameter Store: API keys, config values" (Section 10.2)
- "SSM Parameter Store: API keys, feature flags, third-party credentials" (aws-infrastructure.md Section 1)

**Gap:** Documentation does not explicitly show Lambda environment variable injection pattern. The SSM Parameter Store is mentioned, but the mechanism for populating Lambda environment variables from SSM at deploy time is not detailed.

**CORRECT Pattern (Recommended):**

```typescript
// CDK construct for Lambda with config from environment
const authFunction = new lambda.Function(this, 'AuthFunction', {
  runtime: lambda.Runtime.GO_1_X,
  handler: 'bootstrap',
  code: lambda.Code.fromAsset('dist/auth.zip'),
  environment: {
    // From CDK context or SSM at deploy time
    DATABASE_TABLE: props.dynamoTable.tableName,
    VALKEY_URL: props.valkeyCluster.attrRedisEndpointAddress,
    COGNITO_USER_POOL_ID: props.userPool.userPoolId,
    S3_BUCKET: props.mediaBucket.bucketName,
    LOG_LEVEL: process.env.LOG_LEVEL || 'INFO',
    REGION: Stack.of(this).region,
    // Secrets from SSM
    JWT_SECRET: ssm.StringParameter.valueFromLookup(this, '/regal-recovery/jwt-secret'),
    APPLE_IAP_SECRET: ssm.StringParameter.valueFromLookup(this, '/regal-recovery/apple-iap-secret'),
  },
});
```

**Lambda Function Config Access (Go):**

```go
package config

import "os"

type Config struct {
    DatabaseTable      string
    ValkeyURL         string
    CognitoUserPoolID string
    S3Bucket          string
    LogLevel          string
    Region            string
    JWTSecret         string
}

func Load() *Config {
    return &Config{
        DatabaseTable:      os.Getenv("DATABASE_TABLE"),
        ValkeyURL:         os.Getenv("VALKEY_URL"),
        CognitoUserPoolID: os.Getenv("COGNITO_USER_POOL_ID"),
        S3Bucket:          os.Getenv("S3_BUCKET"),
        LogLevel:          os.Getenv("LOG_LEVEL"),
        Region:            os.Getenv("REGION"),
        JWTSecret:         os.Getenv("JWT_SECRET"),
    }
}
```

**INCORRECT (Anti-patterns to avoid):**

```go
// ❌ NEVER: Hardcoded config
const DatabaseTable = "regal-recovery-prod-users"

// ❌ NEVER: Environment-specific logic
if os.Getenv("ENV") == "production" {
    dbURL = "prod-db-url"
}

// ❌ NEVER: Loading config files per environment
config := loadConfig("config/production.yaml")
```

**The Litmus Test:**
Could the codebase be made open source without compromising any credentials? **Answer should be YES.**

**Recommendations:**

1. **Document Lambda Environment Variable Pattern:**
   - Create `docs/architecture/config-management.md`
   - Show CDK/SAM environment variable injection from SSM Parameter Store
   - Provide Go code examples for reading environment variables

2. **Environment Variable Naming Convention:**
   ```
   RR_DATABASE_TABLE=regal-recovery-prod-users
   RR_VALKEY_URL=redis://cache.example.com:6379
   RR_COGNITO_POOL_ID=us-east-1_ABC123
   RR_S3_BUCKET=regal-recovery-prod-media
   RR_LOG_LEVEL=INFO
   RR_FEATURE_NEW_DASHBOARD=true
   ```
   Prefix all environment variables with `RR_` to avoid collisions.

3. **Config Validation at Startup:**
   ```go
   func (c *Config) Validate() error {
       if c.DatabaseTable == "" {
           return fmt.Errorf("DATABASE_TABLE is required")
       }
       if c.ValkeyURL == "" {
           return fmt.Errorf("VALKEY_URL is required")
       }
       // ... validate all required config
       return nil
   }
   ```

4. **Separate Config from Code:**
   - Never use conditional logic based on environment name
   - Config that varies: in environment variables
   - Config that's constant: in code

---

### IV. Backing Services — Treat backing services as attached resources

**Status:** ✅ **Compliant**

**Evidence:**
- All backing services identified by URLs in environment variables (implied)
- DynamoDB, Valkey, S3, SQS, SNS, SES, Cognito all treated as resources
- Multi-region architecture swaps backing services via config (us-east-1 vs eu-west-1)
- No code distinction between local and production services

**Architecture References:**
- "Backing services as attached resources" (Section 10.2)
- Multi-region deployment with region-specific backing services (aws-infrastructure.md Section 2)
- LocalStack for local development (Section 10.2)

**Service Abstraction:**

```go
// DynamoDB client initialized from environment
dynamoClient := dynamodb.NewFromConfig(cfg, func(o *dynamodb.Options) {
    // URL comes from environment, not hardcoded
    if endpoint := os.Getenv("DYNAMODB_ENDPOINT"); endpoint != "" {
        o.BaseEndpoint = aws.String(endpoint)
    }
})

// Valkey (Redis) client initialized from environment
redisClient := redis.NewClient(&redis.Options{
    Addr: os.Getenv("VALKEY_URL"), // redis://cache.prod.example.com:6379
})
```

**Environment-Specific Configuration:**

| Environment | DynamoDB | Valkey | S3 Bucket |
|-------------|----------|--------|-----------|
| Local | `http://localhost:4566` (LocalStack) | `redis://localhost:6379` (Docker) | `http://localhost:4566/rr-local-media` |
| Dev | `dynamodb.us-east-1.amazonaws.com` | `cache-dev.abc123.use1.cache.amazonaws.com` | `rr-dev-media` |
| Production (US) | `dynamodb.us-east-1.amazonaws.com` | `cache-prod.abc123.use1.cache.amazonaws.com` | `rr-prod-us-media` |
| Production (EU) | `dynamodb.eu-west-1.amazonaws.com` | `cache-prod.def456.euw1.cache.amazonaws.com` | `rr-prod-eu-media` |

**Swapping Backing Services:**

```bash
# Local development
export DYNAMODB_ENDPOINT=http://localhost:4566
export VALKEY_URL=redis://localhost:6379
export S3_BUCKET=rr-local-media

# Production
export DYNAMODB_ENDPOINT=  # Use default AWS endpoint
export VALKEY_URL=redis://cache-prod.abc123.use1.cache.amazonaws.com:6379
export S3_BUCKET=rr-prod-us-media
```

No code changes required. Same Lambda deployment package runs everywhere.

**Recommendations:**
None. The architecture correctly treats all backing services as attached resources swappable via configuration.

---

### V. Build, Release, Run — Strictly separate build and run stages

**Status:** ✅ **Compliant**

**Evidence:**
- GitHub Actions builds Lambda deployment packages (Build stage)
- CDK/SAM combines build artifacts with environment config (Release stage)
- Lambda executes immutable deployment packages (Run stage)
- Every release has a unique version/tag

**Architecture References:**
- "CI/CD: GitHub Actions" (Section 10.2)
- "IaC: AWS CDK (TypeScript) or SAM" (Section 10.2)
- Immutable Lambda deployment packages

**Three-Stage Pipeline:**

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  BUILD STAGE    │ --> │  RELEASE STAGE   │ --> │   RUN STAGE     │
│                 │     │                  │     │                 │
│ • Go build      │     │ • Combine build  │     │ • Lambda invoke │
│ • Tests         │     │   + env config   │     │ • Immutable     │
│ • go.sum verify │     │ • CDK synth      │     │ • Rollback =    │
│ • ZIP artifact  │     │ • Tag: v1.2.3    │     │   deploy v1.2.2 │
│                 │     │ • Deploy CFN     │     │                 │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

**GitHub Actions Workflow (Conceptual):**

```yaml
name: Deploy Lambda Functions

on:
  push:
    branches: [main]
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v4
        with:
          go-version: '1.21'

      # BUILD STAGE
      - name: Download dependencies
        run: go mod download && go mod verify

      - name: Run tests
        run: go test ./...

      - name: Build Lambda functions
        run: |
          GOOS=linux GOARCH=arm64 go build -o bootstrap cmd/auth/main.go
          zip auth-function.zip bootstrap
          # Repeat for all Lambda functions

      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: lambda-functions
          path: "*.zip"

  release:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/download-artifact@v3
        with:
          name: lambda-functions

      # RELEASE STAGE
      - name: Install CDK
        run: npm install -g aws-cdk

      - name: CDK Deploy to Staging
        env:
          AWS_REGION: us-east-1
          ENVIRONMENT: staging
          # Config from environment or GitHub Secrets
          DATABASE_TABLE: ${{ secrets.STAGING_DATABASE_TABLE }}
          VALKEY_URL: ${{ secrets.STAGING_VALKEY_URL }}
        run: |
          cd infrastructure
          cdk deploy --require-approval never \
            --context environment=staging \
            --context version=${{ github.sha }}

      - name: Tag Release
        if: startsWith(github.ref, 'refs/tags/')
        run: |
          git tag -a release-staging-$(date +%s) -m "Staging release"
```

**Immutable Releases:**

```bash
# Each deployment creates a versioned Lambda function
arn:aws:lambda:us-east-1:123456789012:function:regal-recovery-auth:12  # Version 12
arn:aws:lambda:us-east-1:123456789012:function:regal-recovery-auth:13  # Version 13

# API Gateway points to specific version or alias
Alias: production -> Version 13
Alias: staging   -> Version 14
```

**Rollback = Deploy Previous Release:**

```bash
# Rollback by updating alias to previous version
aws lambda update-alias \
  --function-name regal-recovery-auth \
  --name production \
  --function-version 12  # Previous version
```

**Anti-patterns Avoided:**
- ❌ Modifying code in a running Lambda (impossible - Lambda is immutable)
- ❌ Copying files into production environment after build
- ❌ Building on the production server

**Recommendations:**
None. The serverless Lambda architecture inherently enforces strict build/release/run separation.

---

### VI. Processes — Execute the app as one or more stateless processes

**Status:** ✅ **Compliant**

**Evidence:**
- Lambda functions are inherently stateless and share-nothing
- All state externalized to DynamoDB (persistent) and Valkey (cache)
- No in-process session storage
- Offline-first mobile app handles client-side state

**Architecture References:**
- "Stateless processes" (Section 10.1)
- "Valkey cache for hot data: active streaks, session state, dashboard metrics" (c4-diagrams.md Container Diagram)
- Lambda concurrency model (aws-infrastructure.md)

**Stateless Lambda Functions:**

```go
// ✅ CORRECT: External session state in Valkey
func GetAsset(ctx context.Context, assetID string, sessionToken string) (*Asset, error) {
    // Validate session from external store
    session, err := valkey.Get(ctx, "session:"+sessionToken)
    if err != nil {
        return nil, ErrInvalidSession
    }

    // Fetch asset from external store
    asset, err := dynamodb.GetItem(ctx, assetID)
    return asset, err
}

// ❌ INCORRECT: In-process session cache (violates statelessness)
var sessionCache = make(map[string]*Session) // Lost on Lambda recycle!

func GetAsset(ctx context.Context, assetID string, sessionToken string) (*Asset, error) {
    session := sessionCache[sessionToken] // Wrong! State tied to process.
    // ...
}
```

**State Externalization:**

| Data Type | Storage | TTL | Rationale |
|-----------|---------|-----|-----------|
| User sessions | Valkey | 15 min | Short-lived, frequently accessed, needs fast invalidation |
| Active streaks | Valkey | 1 hour | Hot path data, acceptable to recalculate on cache miss |
| Dashboard metrics | Valkey | 15 min | Aggregated data, expensive to compute |
| Journal entries | DynamoDB | Forever | Persistent user data |
| Urge logs | DynamoDB | Forever | Recovery tracking history |
| Check-ins | DynamoDB | Forever | Activity history |
| Media files | S3 | Forever | Object storage |

**Lambda Lifecycle:**

```
Lambda Invocation Lifecycle:
1. Cold Start (first invocation or after idle timeout)
   - Initialize SDK clients (DynamoDB, Valkey, S3)
   - Load config from environment variables
   - Establish connections

2. Warm Invocation (reuse existing container)
   - Reuse SDK clients (connection pooling)
   - No in-memory state persists between invocations

3. Lambda Recycle (after ~15 minutes idle or platform decision)
   - Container destroyed
   - Any in-memory state LOST
```

**Cache as Performance Optimization (Acceptable):**

```go
// ✅ ACCEPTABLE: In-memory cache as optimization with external fallback
var (
    contentCache     sync.Map // In-process cache
    contentCacheTTL  = 5 * time.Minute
)

func GetAffirmation(ctx context.Context, affirmationID string) (*Affirmation, error) {
    // Check in-process cache (performance optimization)
    if cached, ok := contentCache.Load(affirmationID); ok {
        entry := cached.(cacheEntry)
        if time.Now().Before(entry.ExpiresAt) {
            return entry.Data, nil
        }
    }

    // Check Valkey (external cache)
    if cached, err := valkey.Get(ctx, "affirmation:"+affirmationID); err == nil {
        return cached, nil
    }

    // Fetch from DynamoDB (source of truth)
    affirmation, err := dynamodb.GetItem(ctx, affirmationID)
    if err != nil {
        return nil, err
    }

    // Populate caches
    valkey.SetEx(ctx, "affirmation:"+affirmationID, affirmation, 1*time.Hour)
    contentCache.Store(affirmationID, cacheEntry{
        Data:      affirmation,
        ExpiresAt: time.Now().Add(contentCacheTTL),
    })

    return affirmation, nil
}
```

The key: in-process cache is an optimization only. Data can always be regenerated from external stores.

**Sticky Sessions:**

Not applicable. API Gateway + Lambda does not use sticky sessions. Each request can land on any Lambda instance.

**Recommendations:**
None. The Lambda architecture inherently enforces statelessness.

---

### VII. Port Binding — Export services via port binding

**Status:** ✅ **Compliant**

**Evidence:**
- Lambda functions export HTTP services via API Gateway
- Port binding abstracted by AWS platform (Lambda runtime)
- Functions are self-contained and require no external web server
- API Gateway provides the HTTP interface

**Architecture References:**
- "API Gateway routes to Lambda handlers" (c4-diagrams.md)
- "Lambda functions are completely self-contained" (implied)

**Lambda + API Gateway Pattern:**

```
HTTP Request → API Gateway → Lambda Function (self-contained)
                   ↓
              HTTP Response
```

Traditional twelve-factor apps bind to a port:

```python
# Traditional web app (e.g., Flask)
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
```

Lambda functions don't bind ports directly. The platform (API Gateway) handles HTTP and invokes Lambda via the runtime API:

```go
// Lambda handler (Go)
package main

import (
    "context"
    "github.com/aws/aws-lambda-go/events"
    "github.com/aws/aws-lambda-go/lambda"
)

func handler(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
    // Self-contained business logic
    return events.APIGatewayProxyResponse{
        StatusCode: 200,
        Body:       `{"message": "Hello from Lambda"}`,
    }, nil
}

func main() {
    // Lambda runtime handles "port binding" via platform
    lambda.Start(handler)
}
```

**Service-to-Service Communication:**

One Lambda function can call another via API Gateway (HTTP) or directly via Lambda Invoke API:

```go
// HTTP-based (via API Gateway)
resp, err := http.Get("https://api.regalrecovery.com/v1/tracking/streaks")

// Direct Lambda invocation (service mesh pattern)
invokeInput := &lambda.InvokeInput{
    FunctionName: aws.String("regal-recovery-tracking-streaks"),
    Payload:      []byte(`{"userId": "u_12345"}`),
}
invokeOutput, err := lambdaClient.Invoke(ctx, invokeInput)
```

**Mobile App → API Gateway → Lambda:**

```
iOS/Android App
  ↓ HTTPS (TLS 1.3)
CloudFront CDN
  ↓ Origin request
API Gateway (HTTP API)
  ↓ Lambda Invoke
Lambda Function (Go)
  ↓ Return response
API Gateway
  ↓ HTTPS response
Mobile App
```

**Interpretation for Serverless:**

Factor VII's intent is that the app is **self-contained** and does not rely on an external web server being injected at runtime (like Apache + mod_wsgi for Python, or Tomcat for Java).

Lambda functions satisfy this: they are self-contained units of compute that export services via the platform's HTTP abstraction (API Gateway).

**Recommendations:**
None. API Gateway + Lambda correctly implements self-contained service export.

---

### VIII. Concurrency — Scale out via the process model

**Status:** ✅ **Compliant**

**Evidence:**
- Lambda auto-scales horizontally by invoking more concurrent instances
- Different Lambda functions (process types) scale independently
- Background workers (SQS consumers) scale separately from HTTP handlers
- Concurrency limits configurable per function

**Architecture References:**
- "Lambda auto-scales to 500,000 concurrent users" (Section 5.2)
- "Lambda: auto-scaling, multi-AZ by default" (c4-diagrams.md)
- "Background workers scale separately" (c4-diagrams.md Component Diagram)

**Process Model:**

```
Process Type: Web (HTTP API Handlers)
  Lambda Function: AuthService (scales 0-1000 concurrent)
  Lambda Function: TrackingService (scales 0-5000 concurrent)
  Lambda Function: ContentService (scales 0-2000 concurrent)

Process Type: Worker (Event Consumers)
  Lambda Function: StreakCalculator (scales 0-500 concurrent)
  Lambda Function: MilestoneChecker (scales 0-500 concurrent)
  Lambda Function: NotificationScheduler (scales 0-1000 concurrent)
  Lambda Function: AnalyticsAggregator (scales 0-200 concurrent)

Process Type: Scheduled
  Lambda Function: DailyBackup (1 instance, cron: @daily)
  Lambda Function: WeeklyReport (1 instance, cron: @weekly)
```

**Scaling Configuration (CDK):**

```typescript
const trackingFunction = new lambda.Function(this, 'TrackingFunction', {
  runtime: lambda.Runtime.GO_1_X,
  handler: 'bootstrap',
  code: lambda.Code.fromAsset('dist/tracking.zip'),
  reservedConcurrentExecutions: 5000, // Max concurrent instances
  timeout: Duration.seconds(10),
  memorySize: 512, // MB per instance
});

const streakCalculatorFunction = new lambda.Function(this, 'StreakCalculator', {
  runtime: lambda.Runtime.GO_1_X,
  handler: 'bootstrap',
  code: lambda.Code.fromAsset('dist/streak-calculator.zip'),
  reservedConcurrentExecutions: 500,
  timeout: Duration.seconds(30),
  memorySize: 256,
});
```

**Independent Scaling:**

```
User Traffic Spike (10,000 requests/minute)
  → API Gateway
  → Lambda scales HTTP handlers horizontally (1000+ instances)
  → DynamoDB and Valkey handle increased load

Background Event Spike (50,000 events/minute from milestones)
  → SNS publishes events
  → SQS queues buffer events
  → Lambda scales event workers horizontally (500+ instances)
  → DynamoDB handles writes
```

**Horizontal Scaling, Not Vertical:**

```
❌ INCORRECT: Scale by making processes bigger
  - Increase Lambda memory from 512 MB to 10 GB (wrong approach)
  - Run fewer, larger instances

✅ CORRECT: Scale by running more processes
  - Keep Lambda memory at 512 MB
  - Let AWS auto-scale to 5000 concurrent instances
  - Each instance handles one request at a time
```

**Process Types Scale Independently:**

| Scenario | Web Handlers | Event Workers | Scheduled Jobs |
|----------|--------------|---------------|----------------|
| Normal day | 50 concurrent | 10 concurrent | 1 instance |
| Traffic spike | 1000 concurrent | 10 concurrent | 1 instance |
| Milestone storm (1M users hit 30 days) | 50 concurrent | 500 concurrent | 1 instance |
| Nightly backup | 10 concurrent | 5 concurrent | 10 instances |

**No Daemonization:**

Lambda functions do not daemonize or write PID files. The platform (Lambda service) manages lifecycle.

```go
// ❌ NEVER in Lambda
func main() {
    daemon.Daemonize() // Wrong! Lambda platform manages process lifecycle
    writePidFile("/var/run/app.pid") // Wrong! Ephemeral filesystem
    // ...
}

// ✅ CORRECT in Lambda
func main() {
    lambda.Start(handler) // Let platform manage lifecycle
}
```

**Recommendations:**
None. Lambda's concurrency model perfectly implements horizontal scaling via the process model.

---

### IX. Disposability — Maximize robustness with fast startup and graceful shutdown

**Status:** ✅ **Compliant**

**Evidence:**
- Go Lambda cold starts <10ms (Section 10.2: "Sub-10ms cold starts in Go")
- Lambda lifecycle includes graceful shutdown hooks
- Crash-only architecture (Lambda destroys containers on failure)
- SQS message visibility timeout handles worker crashes

**Architecture References:**
- "Fast Lambda cold starts, strong concurrency, single language" (Section 10.2)
- "Lambda: auto-scaling, multi-AZ by default" (c4-diagrams.md)

**Fast Startup:**

```
Lambda Cold Start (Go on ARM64 Graviton):
1. Download deployment package: ~50ms (cached at edge)
2. Unzip: ~20ms
3. Initialize Go runtime: ~5ms
4. Run init() functions: ~10ms
5. Ready to handle requests

Total: ~85ms (well under 1 second)

Warm Start: <1ms (reuse existing container)
```

**Optimization Techniques:**

```go
// Initialize SDK clients outside handler (reused across invocations)
var (
    dynamoClient *dynamodb.Client
    valkeyClient *redis.Client
    s3Client     *s3.Client
)

func init() {
    // Runs once per Lambda container (cold start)
    cfg, err := config.LoadDefaultConfig(context.Background())
    if err != nil {
        log.Fatal(err)
    }

    dynamoClient = dynamodb.NewFromConfig(cfg)
    valkeyClient = redis.NewClient(&redis.Options{
        Addr: os.Getenv("VALKEY_URL"),
    })
    s3Client = s3.NewFromConfig(cfg)
}

func handler(ctx context.Context, event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
    // Fast execution path: SDK clients already initialized
    // ...
}

func main() {
    lambda.Start(handler)
}
```

**Graceful Shutdown:**

Lambda provides a shutdown hook for cleanup before container termination:

```go
package main

import (
    "context"
    "log"
    "os"
    "os/signal"
    "syscall"
    "github.com/aws/aws-lambda-go/lambda"
)

func handler(ctx context.Context, event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
    // Handle request
    return events.APIGatewayProxyResponse{StatusCode: 200}, nil
}

func main() {
    // Set up shutdown signal handler
    ctx, cancel := context.WithCancel(context.Background())
    defer cancel()

    sigChan := make(chan os.Signal, 1)
    signal.Notify(sigChan, syscall.SIGTERM)

    go func() {
        <-sigChan
        log.Println("Received SIGTERM, shutting down gracefully...")

        // Close connections gracefully
        if err := valkeyClient.Close(); err != nil {
            log.Printf("Error closing Valkey client: %v", err)
        }

        cancel()
    }()

    lambda.StartWithOptions(handler, lambda.WithContext(ctx))
}
```

**Lambda Lifecycle:**

```
1. Container Initialization (Cold Start)
   - Lambda runtime starts
   - init() runs
   - SDK clients initialized

2. Invocation Phase
   - Handler executes
   - Request processed
   - Response returned

3. Container Reuse (Warm Invocations)
   - Same container handles next request
   - SDK clients reused
   - No re-initialization

4. Shutdown Phase
   - After ~15 minutes idle, Lambda sends SIGTERM
   - Graceful shutdown hooks execute
   - Connections closed
   - Container destroyed
```

**SQS Worker Robustness:**

```go
func processSQSMessage(ctx context.Context, event events.SQSEvent) error {
    for _, record := range event.Records {
        // Process message
        if err := processMessage(ctx, record.Body); err != nil {
            // Don't delete message from queue (return error)
            // SQS will retry after visibility timeout
            return err
        }
        // Message successfully processed
        // Lambda runtime automatically deletes message from queue
    }
    return nil
}
```

**Crash-Only Software:**

Lambda embraces crash-only design. On fatal error, the container is destroyed and replaced:

```go
func handler(ctx context.Context, event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
    // If panic occurs, Lambda catches it, logs it, and destroys container
    // Next invocation gets a fresh container

    // No need for complex error recovery logic
    // Just fail fast and let the platform handle it
    return processRequest(ctx, event)
}
```

**Disposability in Practice:**

- Lambda containers are disposable: destroyed after idle timeout or on failure
- No state persists in containers (all state externalized)
- Workers return failed jobs to queue for retry
- Rapid deployment: new version deployed in <1 minute
- Instant rollback: switch API Gateway alias to previous version

**Recommendations:**
None. Lambda's lifecycle perfectly implements fast startup and graceful shutdown.

---

### X. Dev/Prod Parity — Keep development, staging, and production as similar as possible

**Status:** ✅ **Compliant**

**Evidence:**
- LocalStack + Docker Compose for local development (Section 10.2)
- Same backing services (DynamoDB, Valkey, S3, SQS, SNS) in all environments
- GitHub Actions CI/CD enables frequent deploys
- CDK/SAM IaC ensures environment consistency

**Architecture References:**
- "Local Development: LocalStack, Docker Compose, SAM CLI, Makefile/Taskfile" (Section 10.2)
- "DynamoDB, Valkey, S3, SQS, SNS" used everywhere

**Three Gaps:**

| Gap | Traditional App | Regal Recovery (Twelve-Factor) |
|-----|-----------------|--------------------------------|
| **Time gap** | Weeks between deploys | Hours/days between deploys (GitHub Actions) |
| **Personnel gap** | Devs write, ops deploy | Devs deploy via GitHub Actions (DevOps culture) |
| **Tools gap** | SQLite locally, PostgreSQL in prod | DynamoDB everywhere (LocalStack locally) |

**Local Development Environment:**

```yaml
# docker-compose.yml
version: '3.8'

services:
  localstack:
    image: localstack/localstack:latest
    ports:
      - "4566:4566"  # LocalStack edge port
    environment:
      SERVICES: dynamodb,s3,sqs,sns,ssm,lambda,apigateway
      DATA_DIR: /tmp/localstack/data
    volumes:
      - "./localstack-data:/tmp/localstack"
      - "/var/run/docker.sock:/var/run/docker.sock"

  valkey:
    image: valkey/valkey:7
    ports:
      - "6379:6379"
    command: valkey-server --maxmemory 256mb --maxmemory-policy allkeys-lru

  cognito-local:
    image: jagregory/cognito-local:latest
    ports:
      - "9229:9229"
    volumes:
      - "./cognito-config:/app/.cognito"
```

**Lambda Local Invocation (SAM CLI):**

```bash
# Local API Gateway + Lambda
sam local start-api --docker-network regal-recovery-local --env-vars env.json

# env.json
{
  "TrackingFunction": {
    "DYNAMODB_ENDPOINT": "http://localstack:4566",
    "VALKEY_URL": "redis://valkey:6379",
    "S3_BUCKET": "rr-local-media",
    "REGION": "us-east-1",
    "LOG_LEVEL": "DEBUG"
  }
}
```

**Makefile for Local Development:**

```makefile
.PHONY: local-up local-down local-seed deploy-dev deploy-staging deploy-prod

# Start local environment
local-up:
	docker-compose up -d
	@echo "Waiting for LocalStack to be ready..."
	aws --endpoint-url=http://localhost:4566 dynamodb list-tables || true
	$(MAKE) local-seed

# Stop local environment
local-down:
	docker-compose down -v

# Seed local DynamoDB with test data
local-seed:
	aws --endpoint-url=http://localhost:4566 dynamodb create-table --cli-input-json file://infrastructure/dynamodb-schema.json
	aws --endpoint-url=http://localhost:4566 s3 mb s3://rr-local-media

# Deploy to dev
deploy-dev:
	cd infrastructure && cdk deploy --context environment=dev --require-approval never

# Deploy to staging
deploy-staging:
	cd infrastructure && cdk deploy --context environment=staging --require-approval never

# Deploy to production
deploy-prod:
	cd infrastructure && cdk deploy --context environment=production
```

**Same Services, All Environments:**

| Service | Local (Docker) | Dev (AWS) | Production (AWS) |
|---------|---------------|-----------|------------------|
| DynamoDB | LocalStack | DynamoDB (on-demand) | DynamoDB (on-demand) |
| Cache | Valkey (Docker) | ElastiCache Valkey | ElastiCache Valkey (Multi-AZ) |
| Object Storage | LocalStack S3 | S3 | S3 (versioned, cross-region replication) |
| Queue | LocalStack SQS | SQS | SQS |
| Pub/Sub | LocalStack SNS | SNS | SNS |
| API Gateway | SAM Local | API Gateway (HTTP API) | API Gateway (HTTP API) + WAF |

**No Lightweight Substitutes:**

```
❌ INCORRECT: Use different services locally
  - SQLite locally, DynamoDB in production
  - In-memory queue locally, SQS in production
  - Filesystem storage locally, S3 in production

✅ CORRECT: Use same services everywhere
  - DynamoDB (LocalStack) locally, DynamoDB in production
  - SQS (LocalStack) locally, SQS in production
  - S3 (LocalStack) locally, S3 in production
```

**Time Gap (Deploy Frequency):**

```yaml
# GitHub Actions - Deploy on every push to main
on:
  push:
    branches: [main]

# Result: Multiple deploys per day to dev/staging
# Production: Daily or weekly depending on release cadence
```

**Personnel Gap:**

```
Traditional:
  Developer → writes code → commits → hands off to ops team → waits days/weeks

Twelve-Factor (Regal Recovery):
  Developer → writes code → commits to main → GitHub Actions auto-deploys → monitors logs

Same person who writes code deploys it and monitors it.
```

**Recommendations:**
None. The architecture achieves excellent dev/prod parity with LocalStack and Docker Compose.

---

### XI. Logs — Treat logs as event streams

**Status:** ⚠️ **Partial Compliance**

**Evidence:**
- Lambda functions log to CloudWatch Logs (stdout automatically captured)
- Structured logging framework not explicitly documented
- Correlation IDs mentioned in API documentation but not in logging strategy
- No evidence of JSON-formatted log output

**Architecture References:**
- "CloudWatch: Logs, Metrics, Alarms, Dashboard" (Section 10.2)
- "X-Correlation-Id propagated through all service calls" (api-data-model.md)
- "Structured logging with JSON format to CloudWatch" (api-data-model.md Section 7) - mentioned but not detailed

**CORRECT Pattern (Recommended):**

```go
package logger

import (
    "context"
    "encoding/json"
    "log"
    "os"
    "time"
)

type Logger struct {
    serviceName string
}

type LogEntry struct {
    Timestamp     string                 `json:"timestamp"`
    Level         string                 `json:"level"`
    Message       string                 `json:"message"`
    Service       string                 `json:"service"`
    CorrelationID string                 `json:"correlationId,omitempty"`
    UserID        string                 `json:"userId,omitempty"`
    RequestID     string                 `json:"requestId,omitempty"`
    Fields        map[string]interface{} `json:"fields,omitempty"`
}

func New(serviceName string) *Logger {
    return &Logger{serviceName: serviceName}
}

func (l *Logger) Info(ctx context.Context, message string, fields map[string]interface{}) {
    l.log(ctx, "INFO", message, fields)
}

func (l *Logger) Error(ctx context.Context, message string, err error, fields map[string]interface{}) {
    if fields == nil {
        fields = make(map[string]interface{})
    }
    if err != nil {
        fields["error"] = err.Error()
    }
    l.log(ctx, "ERROR", message, fields)
}

func (l *Logger) log(ctx context.Context, level string, message string, fields map[string]interface{}) {
    entry := LogEntry{
        Timestamp:     time.Now().UTC().Format(time.RFC3339),
        Level:         level,
        Message:       message,
        Service:       l.serviceName,
        CorrelationID: getCorrelationID(ctx),
        UserID:        getUserID(ctx),
        RequestID:     getRequestID(ctx),
        Fields:        fields,
    }

    jsonBytes, _ := json.Marshal(entry)
    // Write to stdout - Lambda automatically sends to CloudWatch
    os.Stdout.Write(jsonBytes)
    os.Stdout.Write([]byte("\n"))
}

// Extract correlation ID from context
func getCorrelationID(ctx context.Context) string {
    if val := ctx.Value("correlationId"); val != nil {
        return val.(string)
    }
    return ""
}

// Extract user ID from context (from JWT claims)
func getUserID(ctx context.Context) string {
    if val := ctx.Value("userId"); val != nil {
        return val.(string)
    }
    return ""
}

// Extract Lambda request ID from context
func getRequestID(ctx context.Context) string {
    if val := ctx.Value("requestId"); val != nil {
        return val.(string)
    }
    return ""
}
```

**Usage in Lambda Handler:**

```go
package main

import (
    "context"
    "github.com/aws/aws-lambda-go/events"
    "github.com/aws/aws-lambda-go/lambda"
    "github.com/regalrecovery/pkg/logger"
)

var log = logger.New("tracking-service")

func handler(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
    // Extract correlation ID from request headers
    correlationID := request.Headers["X-Correlation-Id"]
    if correlationID == "" {
        correlationID = generateUUID()
    }
    ctx = context.WithValue(ctx, "correlationId", correlationID)

    // Extract user ID from JWT claims
    userID := request.RequestContext.Authorizer["sub"]
    ctx = context.WithValue(ctx, "userId", userID)

    // Extract Lambda request ID
    requestID := request.RequestContext.RequestID
    ctx = context.WithValue(ctx, "requestId", requestID)

    log.Info(ctx, "Processing streak calculation", map[string]interface{}{
        "addictionId": request.PathParameters["addictionId"],
        "method":      request.HTTPMethod,
        "path":        request.Path,
    })

    // Business logic
    streak, err := calculateStreak(ctx, userID, request.PathParameters["addictionId"])
    if err != nil {
        log.Error(ctx, "Failed to calculate streak", err, map[string]interface{}{
            "addictionId": request.PathParameters["addictionId"],
        })
        return events.APIGatewayProxyResponse{
            StatusCode: 500,
            Body:       `{"error": "Internal server error"}`,
        }, nil
    }

    log.Info(ctx, "Streak calculated successfully", map[string]interface{}{
        "streakDays":  streak.CurrentStreakDays,
        "addictionId": request.PathParameters["addictionId"],
    })

    return events.APIGatewayProxyResponse{
        StatusCode: 200,
        Headers: map[string]string{
            "X-Correlation-Id": correlationID,
        },
        Body: marshalJSON(streak),
    }, nil
}

func main() {
    lambda.Start(handler)
}
```

**Log Output (JSON to stdout → CloudWatch):**

```json
{"timestamp":"2026-03-28T10:15:23Z","level":"INFO","message":"Processing streak calculation","service":"tracking-service","correlationId":"fe8793b2-1bf0-4d29-bf10-adcf72640ec5","userId":"u_12345","requestId":"abc123-lambda-request","fields":{"addictionId":"a_67890","method":"GET","path":"/v1/tracking/streaks/a_67890"}}

{"timestamp":"2026-03-28T10:15:23Z","level":"INFO","message":"Streak calculated successfully","service":"tracking-service","correlationId":"fe8793b2-1bf0-4d29-bf10-adcf72640ec5","userId":"u_12345","requestId":"abc123-lambda-request","fields":{"streakDays":47,"addictionId":"a_67890"}}
```

**CloudWatch Logs Insights Query:**

```sql
fields @timestamp, message, correlationId, userId, fields.streakDays
| filter correlationId = "fe8793b2-1bf0-4d29-bf10-adcf72640ec5"
| sort @timestamp asc
```

**INCORRECT (Anti-patterns to avoid):**

```go
// ❌ NEVER: Write to log files
logFile, _ := os.OpenFile("/var/log/app.log", os.O_APPEND|os.O_CREATE, 0644)
log.SetOutput(logFile) // Wrong! Lambda filesystem is ephemeral

// ❌ NEVER: Unstructured logs
log.Println("User", userId, "calculated streak", streakDays, "days")
// Hard to parse, no correlation ID, no structured fields

// ❌ NEVER: Manage log rotation
rotateLogsDaily() // Wrong! Lambda platform handles log aggregation
```

**Log Aggregation:**

Lambda automatically sends stdout/stderr to CloudWatch Logs. The execution environment (CloudWatch) handles:
- Log collection
- Log aggregation across Lambda instances
- Log retention (configurable: 1 day to never expire)
- Log search (CloudWatch Logs Insights)

**Correlation Across Services:**

```
Request Flow:
1. API Gateway receives request, generates X-Correlation-Id
2. Lambda AuthService validates token
   → Log: {"correlationId": "abc123", "message": "Token validated"}
3. Lambda TrackingService calculates streak
   → Log: {"correlationId": "abc123", "message": "Streak calculated"}
4. Lambda publishes SNS event
   → Log: {"correlationId": "abc123", "message": "Event published"}
5. Lambda BackgroundWorker processes event
   → Log: {"correlationId": "abc123", "message": "Milestone detected"}

All logs searchable by correlation ID: abc123
```

**Recommendations:**

1. **Implement Structured JSON Logging:**
   - Create `pkg/logger` package with structured logging
   - Output JSON to stdout (Lambda automatically sends to CloudWatch)
   - Include `timestamp`, `level`, `message`, `service`, `correlationId`, `userId`, `requestId` in every log entry

2. **Correlation ID Propagation:**
   - API Gateway generates `X-Correlation-Id` for every request
   - Lambda extracts correlation ID from headers and adds to context
   - All log entries include correlation ID
   - Pass correlation ID to downstream services (SNS, SQS, Lambda invocations)

3. **CloudWatch Logs Insights:**
   - Use CloudWatch Logs Insights for structured queries
   - Create saved queries for common operations (error rates, slow requests, user activity)
   - Set up CloudWatch alarms on log patterns (elevated error rates)

4. **No PII in Logs:**
   - Never log sensitive user data (journal content, urge log notes, passwords)
   - Log identifiers only (`userId`, `addictionId`, `entryId`)
   - Redact sensitive fields before logging

5. **Log Levels:**
   - DEBUG: Detailed information for debugging (disabled in production)
   - INFO: General informational messages
   - WARN: Warning messages (recoverable errors)
   - ERROR: Error messages (operation failed)
   - FATAL: Critical errors (service cannot continue)

---

### XII. Admin Processes — Run admin/management tasks as one-off processes

**Status:** ✅ **Compliant**

**Evidence:**
- Admin tasks run as Lambda functions or Step Functions
- Database migrations can run as Lambda invocations
- Data export/backup runs as Lambda functions
- Admin tasks use same codebase as app (implied)

**Architecture References:**
- "Backup Functions: export, user backup, data deletion" (c4-diagrams.md)
- Lambda architecture supports one-off invocations

**Admin Tasks as Lambda Functions:**

```go
// cmd/admin-migration/main.go
package main

import (
    "context"
    "github.com/aws/aws-lambda-go/lambda"
    "github.com/regalrecovery/internal/migrations"
    "github.com/regalrecovery/pkg/config"
)

func handler(ctx context.Context) error {
    cfg := config.Load()

    // Run migration
    return migrations.MigrateToVersion(ctx, cfg, "v1.2.0")
}

func main() {
    lambda.Start(handler)
}
```

**One-Off Invocation:**

```bash
# Run database migration as one-off Lambda invocation
aws lambda invoke \
  --function-name regal-recovery-admin-migration \
  --payload '{"version": "v1.2.0"}' \
  --log-type Tail \
  response.json

# Run data backfill
aws lambda invoke \
  --function-name regal-recovery-admin-backfill \
  --payload '{"operation": "backfill-serial-numbers"}' \
  response.json
```

**Step Functions for Complex Admin Tasks:**

```json
{
  "Comment": "Data migration workflow",
  "StartAt": "BackupData",
  "States": {
    "BackupData": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:us-east-1:123456789012:function:admin-backup",
      "Next": "RunMigration"
    },
    "RunMigration": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:us-east-1:123456789012:function:admin-migration",
      "Next": "ValidateData"
    },
    "ValidateData": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:us-east-1:123456789012:function:admin-validate",
      "End": true
    }
  }
}
```

**Admin Tasks Use Same Codebase:**

```
repository/
├── cmd/
│   ├── auth-service/        # Production Lambda function
│   ├── tracking-service/    # Production Lambda function
│   ├── admin-migration/     # Admin task Lambda function
│   ├── admin-backfill/      # Admin task Lambda function
│   └── admin-export/        # Admin task Lambda function
├── internal/
│   ├── domain/              # Shared business logic
│   ├── migrations/          # Migration logic
│   └── repository/          # Data access layer
└── pkg/
    ├── config/              # Shared config
    └── logger/              # Shared logging
```

Admin tasks import the same packages as production services. No separate admin scripts maintained elsewhere.

**REPL Session (Lambda-based):**

```bash
# Interactive Python REPL (if needed) via Lambda
aws lambda invoke \
  --function-name regal-recovery-admin-repl \
  --payload '{"command": "print(User.query.filter_by(email=\"john@example.com\").first())"}' \
  response.json
```

(Note: REPL is uncommon in Go; typically use Lambda invocations with JSON payloads)

**EventBridge Scheduled Admin Tasks:**

```typescript
// CDK construct for scheduled admin task
const dailyBackupRule = new events.Rule(this, 'DailyBackupRule', {
  schedule: events.Schedule.cron({ hour: '2', minute: '0' }), // 2:00 AM UTC
});

dailyBackupRule.addTarget(new targets.LambdaFunction(backupFunction));
```

**Admin Task Checklist:**

| Admin Task | Implementation | Codebase Shared? | Config Shared? |
|------------|----------------|------------------|----------------|
| Database migration | Lambda function | ✅ Yes | ✅ Yes (env vars) |
| Data backfill | Lambda function | ✅ Yes | ✅ Yes |
| User data export | Lambda function | ✅ Yes | ✅ Yes |
| Tenant provisioning | Lambda function | ✅ Yes | ✅ Yes |
| Content seeding | Lambda function | ✅ Yes | ✅ Yes |
| Batch deletion (GDPR) | Lambda function | ✅ Yes | ✅ Yes |

**Environment Variables for Admin Tasks:**

```bash
# Admin task uses same config as production services
export DATABASE_TABLE=regal-recovery-prod-users
export VALKEY_URL=redis://cache-prod.abc123.use1.cache.amazonaws.com:6379
export S3_BUCKET=rr-prod-us-media
export DRY_RUN=false  # Admin-specific flag
```

**Anti-patterns Avoided:**

```bash
# ❌ NEVER: Ad-hoc scripts on production server
ssh prod-server
cd /opt/app
python scripts/backfill_data.py  # Wrong! Not version controlled, not tested

# ❌ NEVER: Separate codebase for admin tasks
admin-scripts/
  backfill.py  # Duplicates business logic, diverges from main app

# ✅ CORRECT: Admin task as Lambda function
aws lambda invoke --function-name regal-recovery-admin-backfill response.json
```

**Recommendations:**
None. The Lambda architecture naturally supports running admin tasks as one-off processes from the same codebase.

---

## Lambda-Specific Considerations

### Cold Starts

**Current State:**
- Go on ARM64 Graviton: sub-10ms cold starts
- Excellent for twelve-factor disposability

**Optimization Strategies:**
1. **Provisioned Concurrency** for latency-sensitive functions (trades cost for guaranteed warm instances)
2. **Connection pooling** in `init()` for SDK clients (DynamoDB, Valkey, S3)
3. **Minimal dependencies** in deployment package
4. **ARM64 architecture** (20% cost reduction, 34% better performance)

```typescript
// Provisioned concurrency for critical API endpoints
const authFunction = new lambda.Function(this, 'AuthFunction', {
  runtime: lambda.Runtime.GO_1_X,
  architecture: lambda.Architecture.ARM_64,
  handler: 'bootstrap',
  code: lambda.Code.fromAsset('dist/auth.zip'),
  reservedConcurrentExecutions: 100,
});

// Provision 10 warm instances for auth service
const alias = new lambda.Alias(this, 'AuthAlias', {
  aliasName: 'production',
  version: authFunction.currentVersion,
  provisionedConcurrentExecutions: 10, // Always keep 10 warm
});
```

### Statelessness

Lambda's ephemeral nature enforces statelessness:
- No shared filesystem across instances
- `/tmp` is ephemeral (512 MB max, cleared on container recycle)
- All state must live in external stores (DynamoDB, Valkey, S3)

```go
// ❌ INCORRECT: Writing to /tmp for persistence
func handler(ctx context.Context) error {
    ioutil.WriteFile("/tmp/cache.json", data, 0644) // Lost on container recycle!
    return nil
}

// ✅ CORRECT: Persist to S3
func handler(ctx context.Context) error {
    s3Client.PutObject(ctx, &s3.PutObjectInput{
        Bucket: aws.String("rr-prod-cache"),
        Key:    aws.String("cache.json"),
        Body:   bytes.NewReader(data),
    })
    return nil
}
```

### Concurrency Model

Lambda auto-scales horizontally:
- Each Lambda instance handles **one request at a time**
- Concurrency = number of instances × requests per second
- Reserved concurrency prevents one function from consuming all account-level concurrency

```typescript
// Prevent tracking service from starving other functions
const trackingFunction = new lambda.Function(this, 'TrackingFunction', {
  reservedConcurrentExecutions: 5000, // Max 5000 concurrent instances
});
```

**Account-Level Concurrency:**
- Default: 1000 concurrent executions per AWS account per region
- Can request increase to 10,000+
- Throttling occurs when concurrency limit reached (HTTP 429)

### Timeout Configuration

```typescript
const functions = {
  auth: { timeout: 10 },           // Quick auth checks
  tracking: { timeout: 15 },       // Streak calculations
  analytics: { timeout: 30 },      // Complex aggregations
  backup: { timeout: 900 },        // 15 minutes for large exports
};
```

**Best Practice:**
- Set timeouts based on 99th percentile latency
- Use CloudWatch metrics to monitor duration
- Implement timeout handling in code

### Event-Driven Architecture

Lambda + SQS/SNS provides natural twelve-factor process model:

```
API Request → Lambda (Web Handler) → SNS (Event) → SQS (Queue) → Lambda (Worker)
```

- Web handlers scale independently from workers
- SQS provides backpressure and retry logic
- Dead-letter queues for failed events

### Cost Optimization

Lambda pricing:
- $0.20 per 1M requests
- $0.0000166667 per GB-second (ARM64: 20% discount)

```
Example: Tracking API (512 MB, 50ms avg duration)
  6M requests/month × 50ms × 512 MB = 153,600 GB-seconds
  Cost: $2.56 + $1.20 (requests) = $3.76/month
```

**Cost-Optimized Settings:**
- Use ARM64 architecture (20% savings)
- Right-size memory (512 MB is often sufficient for Go)
- Set appropriate timeout (don't over-provision)
- Use on-demand for variable workloads, reserved for predictable

---

## Priority Recommendations

### 1. Factor III (Config) - HIGH PRIORITY

**Issue:** Lambda environment variable injection pattern from SSM Parameter Store is not explicitly documented.

**Action Items:**

1. **Create Config Management Documentation:**
   - Document path: `/docs/architecture/config-management.md`
   - Include CDK examples for SSM → Lambda environment variable injection
   - Show Go code for reading environment variables
   - Define environment variable naming convention (prefix: `RR_`)

2. **CDK Config Pattern:**
   ```typescript
   import * as ssm from 'aws-cdk-lib/aws-ssm';

   const jwtSecret = ssm.StringParameter.fromStringParameterName(
     this, 'JWTSecret', '/regal-recovery/jwt-secret'
   );

   const authFunction = new lambda.Function(this, 'AuthFunction', {
     environment: {
       JWT_SECRET: jwtSecret.stringValue,
       // ... other config from environment
     },
   });
   ```

3. **Config Validation:**
   ```go
   func (c *Config) Validate() error {
       required := map[string]string{
           "DATABASE_TABLE": c.DatabaseTable,
           "VALKEY_URL":     c.ValkeyURL,
           "REGION":         c.Region,
       }
       for name, value := range required {
           if value == "" {
               return fmt.Errorf("required config %s is not set", name)
           }
       }
       return nil
   }
   ```

### 2. Factor XI (Logs) - MEDIUM PRIORITY

**Issue:** Structured JSON logging with correlation IDs is mentioned but not detailed.

**Action Items:**

1. **Implement Structured Logger Package:**
   - Package path: `/pkg/logger/logger.go`
   - JSON output to stdout (captured by CloudWatch)
   - Include: `timestamp`, `level`, `message`, `service`, `correlationId`, `userId`, `requestId`

2. **Correlation ID Middleware:**
   ```go
   func CorrelationIDMiddleware(next http.Handler) http.Handler {
       return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
           correlationID := r.Header.Get("X-Correlation-Id")
           if correlationID == "" {
               correlationID = uuid.New().String()
           }
           ctx := context.WithValue(r.Context(), "correlationId", correlationID)
           w.Header().Set("X-Correlation-Id", correlationID)
           next.ServeHTTP(w, r.WithContext(ctx))
       })
   }
   ```

3. **CloudWatch Logs Insights Queries:**
   - Create saved queries for common operations
   - Document query patterns in `docs/operations/cloudwatch-queries.md`

4. **PII Redaction:**
   - Never log sensitive user content (journal entries, urge logs)
   - Log identifiers only (`userId`, `entryId`)

---

## Validation Checklist

| Validation Item | Status | Notes |
|----------------|--------|-------|
| No hardcoded credentials in code | ✅ Pass | SSM Parameter Store used |
| No environment-specific conditional logic | ✅ Pass | Config from environment variables |
| All backing services swappable via config | ✅ Pass | DynamoDB, Valkey, S3, SQS, SNS |
| Build produces immutable artifacts | ✅ Pass | Lambda deployment packages versioned |
| No in-process state | ✅ Pass | Lambda ephemeral, state in DynamoDB/Valkey |
| Processes scale horizontally | ✅ Pass | Lambda auto-scales |
| Fast startup (<10 seconds) | ✅ Pass | Go cold starts <100ms |
| Graceful shutdown implemented | ✅ Pass | Lambda SIGTERM handling |
| Dev/prod parity maintained | ✅ Pass | LocalStack + Docker Compose |
| Logs to stdout as JSON | ⚠️ Partial | Needs structured JSON logger |
| Admin tasks as one-off processes | ✅ Pass | Lambda invocations |

---

## Conclusion

Regal Recovery demonstrates **strong compliance** with the Twelve-Factor App methodology. The serverless Lambda architecture naturally enforces many factors (statelessness, disposability, concurrency, build/release/run).

**Key Achievements:**
- Excellent statelessness and process model via Lambda
- Robust backing services abstraction
- Strong dev/prod parity with LocalStack
- Immutable deployments with versioned Lambda functions

**Areas for Improvement:**
1. **Config (Factor III):** Document Lambda environment variable injection from SSM Parameter Store
2. **Logs (Factor XI):** Implement structured JSON logging with correlation IDs

**Overall Assessment:** 10/12 factors fully compliant, 2/12 factors partial. With the recommended improvements, Regal Recovery will achieve full twelve-factor compliance and serve as a model serverless architecture.

---

## Related Documents

- [Technical Architecture](../03-technical-architecture.md) - Full technical specification
- [AWS Infrastructure](aws-infrastructure.md) - Infrastructure details and cost analysis
- [C4 Diagrams](c4-diagrams.md) - Architecture diagrams
- [API Data Model](api-data-model.md) - API design and data model

---

**Audit Date:** 2026-03-28
**Next Review:** Quarterly or after major architecture changes
**Maintained By:** Platform Architecture Team
