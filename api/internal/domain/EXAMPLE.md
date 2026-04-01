# Domain Service Usage Examples

This document shows how to use the domain services in your application.

## Service Initialization

Domain services accept repository interfaces as constructor parameters. The actual implementations (e.g., DynamoDB adapters) are provided by the infrastructure layer.

```go
package main

import (
    "github.com/regalrecovery/api/internal/domain/auth"
    "github.com/regalrecovery/api/internal/domain/flags"
    "github.com/regalrecovery/api/internal/domain/tracking"
    "github.com/regalrecovery/api/internal/domain/activities"
    "github.com/regalrecovery/api/internal/domain/content"

    // Your repository implementations
    "github.com/regalrecovery/api/internal/repository/dynamodb"
    "github.com/regalrecovery/api/internal/cache/valkey"
)

func main() {
    // Initialize repositories (DynamoDB adapters)
    userRepo := dynamodb.NewUserRepository(dynamoClient)
    sessionRepo := dynamodb.NewSessionRepository(dynamoClient)
    tokenSvc := auth.NewCognitoTokenService(cognitoClient)

    // Initialize caches (Valkey adapters)
    streakCache := valkey.NewStreakCache(valkeyClient)
    flagCache := valkey.NewFlagCache(valkeyClient)
    contentCache := valkey.NewContentCache(valkeyClient)

    // Initialize domain services
    authService := auth.NewAuthService(userRepo, sessionRepo, tokenSvc)
    flagService := flags.NewFlagService(flagRepo, flagCache)
    trackingService := tracking.NewTrackingService(
        streakRepo,
        milestoneRepo,
        relapseRepo,
        calendarRepo,
        streakCache,
        eventPublisher,
    )
    activityService := activities.NewActivityService(activityRepo)
    contentService := content.NewContentService(contentRepo, contentCache)
}
```

## Auth Service Examples

### User Registration

```go
func handleRegister(ctx context.Context, authSvc *auth.AuthService) error {
    req := auth.RegisterRequest{
        Email:             "john@example.com",
        Password:          "SecurePassword123!",
        DisplayName:       "John",
        PrimaryAddiction:  "sex-addiction",
        SobrietyStartDate: "2026-03-28",
        PreferredLanguage: "en",
        TimeZone:          "America/New_York",
    }

    user, accessToken, refreshToken, expiresIn, err := authSvc.Register(ctx, req)
    if err != nil {
        if errors.Is(err, auth.ErrEmailAlreadyExists) {
            // Handle duplicate email
        }
        if errors.Is(err, auth.ErrInvalidInput) {
            // Handle validation error
        }
        return err
    }

    // Format into Siemens response envelope
    response := auth.RegisterResponse{
        Data: auth.RegisterData{
            UserID:        user.ID,
            Email:         user.Email,
            DisplayName:   user.DisplayName,
            EmailVerified: user.EmailVerified,
            AccessToken:   accessToken,
            RefreshToken:  refreshToken,
            ExpiresIn:     expiresIn,
            TokenType:     "Bearer",
        },
        Links: map[string]string{
            "self":    fmt.Sprintf("https://api.regalrecovery.com/v1/users/%s", user.ID),
            "profile": "https://api.regalrecovery.com/v1/users/me/profile",
            "streaks": "https://api.regalrecovery.com/v1/tracking/streaks",
        },
        Meta: map[string]interface{}{
            "createdAt": user.CreatedAt,
        },
    }

    return nil
}
```

### Get Session

```go
func handleGetSession(ctx context.Context, authSvc *auth.AuthService) error {
    // Session extracted from JWT token by middleware and stored in context
    session, err := authSvc.GetSession(ctx)
    if err != nil {
        if errors.Is(err, auth.ErrSessionNotFound) {
            // Handle missing session
        }
        if errors.Is(err, auth.ErrSessionExpired) {
            // Handle expired session
        }
        return err
    }

    // Format response
    response := auth.SessionResponse{
        Data: auth.SessionData{
            UserID:     session.UserID,
            TenantID:   session.TenantID,
            SessionID:  session.SessionID,
            DeviceID:   session.DeviceID,
            DeviceName: session.DeviceName,
            ExpiresAt:  session.ExpiresAt,
        },
        Links: map[string]string{
            "self": fmt.Sprintf("https://api.regalrecovery.com/v1/auth/sessions/%s", session.SessionID),
        },
    }

    return nil
}
```

## Flags Service Examples

### Evaluate Flag for User

```go
func handleEvaluateFlag(ctx context.Context, flagSvc *flags.FlagService) error {
    userCtx := flags.UserContext{
        UserID:     "u_1a2b3c4d",
        TenantID:   "default",
        Tier:       "premium",
        Platform:   "ios",
        AppVersion: "1.3.0",
    }

    enabled, err := flagSvc.EvaluateFlag(ctx, "feature.recovery-agent", userCtx)
    if err != nil {
        if errors.Is(err, flags.ErrFlagNotFound) {
            // Handle missing flag - default to false
            enabled = false
        } else {
            return err
        }
    }

    // Use flag result
    if enabled {
        // Enable recovery agent feature
    }

    return nil
}
```

### Evaluate All Flags

```go
func handleGetAllFlags(ctx context.Context, flagSvc *flags.FlagService) error {
    userCtx := flags.UserContext{
        UserID:     "u_1a2b3c4d",
        TenantID:   "default",
        Tier:       "premium",
        Platform:   "ios",
        AppVersion: "1.3.0",
    }

    evaluatedFlags, err := flagSvc.EvaluateAllFlags(ctx, userCtx)
    if err != nil {
        return err
    }

    // Format response
    response := flags.EvaluatedFlagsResponse{
        Data: evaluatedFlags,
        Meta: map[string]interface{}{
            "evaluatedAt": time.Now(),
        },
    }

    return nil
}
```

## Tracking Service Examples

### Get Current Streak

```go
func handleGetStreak(ctx context.Context, trackingSvc *tracking.TrackingService) error {
    streak, err := trackingSvc.GetStreak(ctx, "a_67890")
    if err != nil {
        if errors.Is(err, tracking.ErrStreakNotFound) {
            // Handle missing streak
        }
        return err
    }

    // Format response
    response := tracking.StreakResponse{
        Data: *streak,
        Links: map[string]string{
            "self":       fmt.Sprintf("https://api.regalrecovery.com/v1/tracking/streaks/%s", streak.AddictionID),
            "milestones": fmt.Sprintf("https://api.regalrecovery.com/v1/tracking/milestones?addictionId=%s", streak.AddictionID),
        },
    }

    return nil
}
```

### Record Relapse with Compassionate Messaging

```go
func handleRecordRelapse(ctx context.Context, trackingSvc *tracking.TrackingService) error {
    updatedStreak, message, err := trackingSvc.RecordRelapse(
        ctx,
        "u_1a2b3c4d",    // userID
        "a_67890",       // addictionID
        time.Now(),      // timestamp
        "Detailed context about the event", // notes
    )
    if err != nil {
        return err
    }

    // Format response with compassionate message
    response := map[string]interface{}{
        "data": map[string]interface{}{
            "relapseId":           updatedStreak.StreakID, // Would be actual relapse ID
            "addictionId":         updatedStreak.AddictionID,
            "previousStreakDays":  47,
            "postMortemPrompted":  true,
        },
        "links": map[string]string{
            "self":       "https://api.regalrecovery.com/v1/tracking/relapses/r_98765",
            "postMortem": "https://api.regalrecovery.com/v1/activities/post-mortem?relapseId=r_98765",
            "newStreak":  fmt.Sprintf("https://api.regalrecovery.com/v1/tracking/streaks/%s", updatedStreak.AddictionID),
        },
        "meta": map[string]interface{}{
            "createdAt": time.Now(),
            "message":   message, // "Your 47-day streak has been preserved..."
        },
    }

    return nil
}
```

## Activities Service Examples

### Log Activity

```go
func handleLogActivity(ctx context.Context, activitySvc *activities.ActivityService) error {
    data := map[string]interface{}{
        "content":  "Feeling grateful for my accountability partner.",
        "promptId": "daily-gratitude",
        "mood":     "positive",
    }

    activity, err := activitySvc.LogActivity(
        ctx,
        "u_1a2b3c4d",             // userID
        activities.ActivityTypeJournal, // activityType
        data,                     // activity-specific data
        false,                    // ephemeral
    )
    if err != nil {
        return err
    }

    // Format response
    response := activities.ActivityResponse{
        Data: *activity,
        Links: map[string]string{
            "self": fmt.Sprintf("https://api.regalrecovery.com/v1/activities/%s", activity.ActivityID),
        },
        Meta: map[string]interface{}{
            "createdAt": activity.CreatedAt,
        },
    }

    return nil
}
```

### Get Activities with Pagination

```go
func handleGetActivities(ctx context.Context, activitySvc *activities.ActivityService) error {
    activities, nextCursor, err := activitySvc.GetActivities(
        ctx,
        "u_1a2b3c4d",               // userID
        activities.ActivityTypeJournal, // filter by type (optional)
        "",                         // cursor (empty for first page)
        50,                         // limit
    )
    if err != nil {
        return err
    }

    // Format response with pagination
    response := activities.ActivitiesListResponse{
        Data: convertToActivitySlice(activities),
        Links: map[string]string{
            "self": "https://api.regalrecovery.com/v1/activities/journal",
        },
        Meta: map[string]interface{}{
            "page": map[string]interface{}{
                "nextCursor": nextCursor,
                "limit":      50,
            },
        },
    }

    // Add next link if there's a next cursor
    if nextCursor != "" {
        response.Links["next"] = fmt.Sprintf(
            "https://api.regalrecovery.com/v1/activities/journal?cursor=%s&limit=50",
            nextCursor,
        )
    }

    return nil
}
```

## Content Service Examples

### Get Devotional

```go
func handleGetDevotional(ctx context.Context, contentSvc *content.ContentService) error {
    devotional, err := contentSvc.GetDevotional(ctx, 47)
    if err != nil {
        if errors.Is(err, content.ErrContentNotFound) {
            // Handle missing devotional
        }
        return err
    }

    // Format response
    response := content.DevotionalResponse{
        Data: *devotional,
        Links: map[string]string{
            "self": fmt.Sprintf("https://api.regalrecovery.com/v1/content/devotional/%d", devotional.Day),
        },
        Meta: map[string]interface{}{
            "createdAt":  devotional.CreatedAt,
            "modifiedAt": devotional.ModifiedAt,
        },
    }

    return nil
}
```

### Get Today's Affirmation

```go
func handleGetTodaysAffirmation(ctx context.Context, contentSvc *content.ContentService) error {
    affirmation, err := contentSvc.GetTodaysAffirmation(ctx, "u_1a2b3c4d", "pack_001")
    if err != nil {
        return err
    }

    // Format response
    response := content.TodaysAffirmationResponse{
        Data: *affirmation,
        Links: map[string]string{
            "self": fmt.Sprintf("https://api.regalrecovery.com/v1/content/affirmations/today"),
            "pack": fmt.Sprintf("https://api.regalrecovery.com/v1/content/affirmations/%s", "pack_001"),
        },
        Meta: map[string]interface{}{
            "selectedAt": time.Now(),
        },
    }

    return nil
}
```

## Error Handling Pattern

All domain services return wrapped errors with context. Extract sentinel errors for specific handling:

```go
func handleServiceCall(ctx context.Context) error {
    result, err := service.DoSomething(ctx, params)
    if err != nil {
        // Check for specific errors
        if errors.Is(err, domain.ErrNotFound) {
            return formatError(404, "Not Found", err.Error())
        }
        if errors.Is(err, domain.ErrInvalidInput) {
            return formatError(400, "Bad Request", err.Error())
        }

        // Generic error
        return formatError(500, "Internal Server Error", "An unexpected error occurred")
    }

    return formatSuccess(result)
}
```

## Testing Domain Services

Domain services are easy to test by mocking repository interfaces:

```go
type MockUserRepository struct {
    users map[string]*auth.User
}

func (m *MockUserRepository) CreateUser(ctx context.Context, user *auth.User, password string) error {
    m.users[user.ID] = user
    return nil
}

func TestRegister(t *testing.T) {
    mockRepo := &MockUserRepository{users: make(map[string]*auth.User)}
    mockSessionRepo := &MockSessionRepository{}
    mockTokenSvc := &MockTokenService{}

    authSvc := auth.NewAuthService(mockRepo, mockSessionRepo, mockTokenSvc)

    req := auth.RegisterRequest{
        Email:             "test@example.com",
        Password:          "SecurePassword123!",
        DisplayName:       "Test User",
        PrimaryAddiction:  "sex-addiction",
        SobrietyStartDate: "2026-03-28",
    }

    user, accessToken, refreshToken, expiresIn, err := authSvc.Register(context.Background(), req)
    if err != nil {
        t.Fatalf("Register failed: %v", err)
    }

    if user.Email != req.Email {
        t.Errorf("Expected email %s, got %s", req.Email, user.Email)
    }
}
```
