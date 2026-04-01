# Usage Examples - Middleware, Cache, and Events

Quick reference for using the middleware, cache, and events packages in the Regal Recovery Go backend.

---

## Example 1: Lambda Handler with Full Middleware Chain

```go
// cmd/lambda/tracking/main.go
package main

import (
	"context"
	"log"
	"net/http"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/regalrecovery/api/internal/middleware"
	appevents "github.com/regalrecovery/api/internal/events"
	"github.com/regalrecovery/api/internal/cache"
)

func main() {
	// Load AWS config
	cfg, err := config.LoadDefaultConfig(context.Background())
	if err != nil {
		log.Fatal(err)
	}

	// Initialize cache client
	valkeyClient, err := cache.NewValkeyClient("localhost:6379")
	if err != nil {
		log.Fatal(err)
	}
	defer valkeyClient.Close()

	streakCache := cache.NewStreakCache(valkeyClient)

	// Initialize event publisher
	publisher := appevents.NewSNSPublisher(cfg, "") // Empty for local dev

	// Create handler
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Extract user context
		userID := middleware.GetUserID(r.Context())
		tenantID := middleware.GetTenantID(r.Context())
		correlationID := middleware.GetCorrelationID(r.Context())

		// Try cache first
		streak, err := streakCache.GetStreak(r.Context(), userID)
		if err != nil {
			http.Error(w, "Cache error", http.StatusInternalServerError)
			return
		}

		if streak == nil {
			// Cache miss: fetch from DB
			// streak = repository.GetStreak(r.Context(), userID, tenantID)
			// streakCache.SetStreak(r.Context(), userID, streak)
		}

		// Publish event
		publisher.Publish(r.Context(), appevents.Event{
			Type:          appevents.EventStreakUpdated,
			UserID:        userID,
			TenantID:      tenantID,
			CorrelationID: correlationID,
			Data: map[string]interface{}{
				"currentDays": streak.CurrentDays,
			},
		})

		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"data":{"streak":` + fmt.Sprint(streak.CurrentDays) + `}}`))
	})

	// Apply middleware chain
	handler = middleware.Chain(
		handler,
		middleware.RecoveryMiddleware,
		middleware.CorrelationMiddleware,
		middleware.LoggingMiddleware,
		middleware.AuthMiddleware,
		middleware.TenantMiddleware,
	)

	// Wrap for Lambda
	lambda.Start(func(ctx context.Context, event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
		// Convert to http.Request and handle
		// (Use a library like awslambda-go-http or implement conversion)
		return events.APIGatewayProxyResponse{StatusCode: 200}, nil
	})
}
```

---

## Example 2: Cache-Aside Pattern

```go
package tracking

import (
	"context"
	"github.com/regalrecovery/api/internal/cache"
)

type Service struct {
	cache      *cache.StreakCache
	repository StreakRepository
}

func (s *Service) GetStreak(ctx context.Context, userID string) (*cache.Streak, error) {
	// 1. Try cache first
	streak, err := s.cache.GetStreak(ctx, userID)
	if err != nil {
		return nil, err
	}

	// 2. Cache hit - return immediately
	if streak != nil {
		return streak, nil
	}

	// 3. Cache miss - fetch from database
	streak, err = s.repository.GetStreak(ctx, userID)
	if err != nil {
		return nil, err
	}

	// 4. Populate cache for next request
	if err := s.cache.SetStreak(ctx, userID, streak); err != nil {
		// Log cache error but don't fail the request
		log.Printf("Failed to cache streak for user %s: %v", userID, err)
	}

	return streak, nil
}

func (s *Service) UpdateStreak(ctx context.Context, userID string, streak *cache.Streak) error {
	// 1. Update database
	if err := s.repository.UpdateStreak(ctx, userID, streak); err != nil {
		return err
	}

	// 2. Invalidate cache (write-through pattern)
	if err := s.cache.InvalidateStreak(ctx, userID); err != nil {
		// Log cache error but don't fail the request
		log.Printf("Failed to invalidate streak cache for user %s: %v", userID, err)
	}

	return nil
}
```

---

## Example 3: Event Publishing After Business Logic

```go
package tracking

import (
	"context"
	"time"
	"github.com/regalrecovery/api/internal/events"
	"github.com/regalrecovery/api/internal/middleware"
)

type MilestoneService struct {
	publisher events.Publisher
}

func (s *MilestoneService) RecordRelapse(ctx context.Context, userID, tenantID string, previousStreak int, triggers []string) error {
	// 1. Execute business logic
	// ... update streak, reset counter, etc.

	// 2. Publish domain event
	err := s.publisher.Publish(ctx, events.Event{
		Type:          events.EventRelapseRecorded,
		UserID:        userID,
		TenantID:      tenantID,
		Timestamp:     time.Now(),
		CorrelationID: middleware.GetCorrelationID(ctx),
		Data: map[string]interface{}{
			"previousStreak": previousStreak,
			"triggers":       triggers,
			"recordedAt":     time.Now(),
		},
	})

	if err != nil {
		// Log error but don't fail the request
		log.Printf("Failed to publish relapse event for user %s: %v", userID, err)
	}

	return nil
}

func (s *MilestoneService) AchieveMilestone(ctx context.Context, userID, tenantID, milestone string, currentStreak int) error {
	// 1. Execute business logic
	// ... unlock badge, update analytics, etc.

	// 2. Publish domain event
	err := s.publisher.Publish(ctx, events.Event{
		Type:          events.EventMilestoneAchieved,
		UserID:        userID,
		TenantID:      tenantID,
		Timestamp:     time.Now(),
		CorrelationID: middleware.GetCorrelationID(ctx),
		Data: map[string]interface{}{
			"milestone":     milestone,
			"currentStreak": currentStreak,
			"achievedAt":    time.Now(),
		},
	})

	if err != nil {
		log.Printf("Failed to publish milestone event for user %s: %v", userID, err)
	}

	return nil
}
```

---

## Example 4: Unit Testing with Mocks

```go
package tracking_test

import (
	"context"
	"testing"
	"github.com/regalrecovery/api/internal/events"
)

// Mock Publisher
type MockPublisher struct {
	PublishedEvents []events.Event
}

func (m *MockPublisher) Publish(ctx context.Context, event events.Event) error {
	m.PublishedEvents = append(m.PublishedEvents, event)
	return nil
}

// Test
func TestMilestoneService_AchieveMilestone(t *testing.T) {
	mockPublisher := &MockPublisher{}
	service := &MilestoneService{publisher: mockPublisher}

	err := service.AchieveMilestone(context.Background(), "u_alex", "DEFAULT", "30_days", 30)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if len(mockPublisher.PublishedEvents) != 1 {
		t.Fatalf("expected 1 event, got %d", len(mockPublisher.PublishedEvents))
	}

	event := mockPublisher.PublishedEvents[0]
	if event.Type != events.EventMilestoneAchieved {
		t.Errorf("expected event type %s, got %s", events.EventMilestoneAchieved, event.Type)
	}
	if event.UserID != "u_alex" {
		t.Errorf("expected user ID u_alex, got %s", event.UserID)
	}
}
```

---

## Example 5: Middleware Testing

```go
package middleware_test

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"github.com/regalrecovery/api/internal/middleware"
)

func TestAuthMiddleware_DevToken(t *testing.T) {
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		userID := middleware.GetUserID(r.Context())
		if userID != "u_alex" {
			t.Errorf("expected userID u_alex, got %s", userID)
		}

		tenantID := middleware.GetTenantID(r.Context())
		if tenantID != "DEFAULT" {
			t.Errorf("expected tenantID DEFAULT, got %s", tenantID)
		}

		w.WriteHeader(http.StatusOK)
	})

	wrapped := middleware.AuthMiddleware(handler)

	req := httptest.NewRequest("GET", "/api/test", nil)
	req.Header.Set("Authorization", "Bearer dev-token")
	w := httptest.NewRecorder()

	wrapped.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", w.Code)
	}
}

func TestCorrelationMiddleware_GeneratesID(t *testing.T) {
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		correlationID := middleware.GetCorrelationID(r.Context())
		if correlationID == "" {
			t.Error("expected correlation ID, got empty string")
		}
		w.WriteHeader(http.StatusOK)
	})

	wrapped := middleware.CorrelationMiddleware(handler)

	req := httptest.NewRequest("GET", "/api/test", nil)
	w := httptest.NewRecorder()

	wrapped.ServeHTTP(w, req)

	if w.Header().Get("X-Correlation-Id") == "" {
		t.Error("expected X-Correlation-Id header, got empty")
	}
}
```

---

## Example 6: Integration Test with LocalStack SNS

```go
package events_test

import (
	"context"
	"testing"
	"time"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/regalrecovery/api/internal/events"
)

func TestSNSPublisher_Publish(t *testing.T) {
	// Assumes LocalStack is running at localhost:4566
	cfg, err := config.LoadDefaultConfig(context.Background(),
		config.WithEndpointResolver(aws.EndpointResolverFunc(
			func(service, region string) (aws.Endpoint, error) {
				return aws.Endpoint{URL: "http://localhost:4566"}, nil
			},
		)),
	)
	if err != nil {
		t.Fatalf("failed to load config: %v", err)
	}

	// Create SNS topic in LocalStack
	topicARN := "arn:aws:sns:us-east-1:000000000000:test-events"

	publisher := events.NewSNSPublisher(cfg, topicARN)

	err = publisher.Publish(context.Background(), events.Event{
		Type:          events.EventMilestoneAchieved,
		UserID:        "u_test",
		TenantID:      "DEFAULT",
		Timestamp:     time.Now(),
		CorrelationID: "test-correlation-id",
		Data: map[string]interface{}{
			"milestone": "30_days",
		},
	})

	if err != nil {
		t.Errorf("expected no error, got %v", err)
	}
}
```

---

## Example 7: Structured Logging Configuration

```go
package main

import (
	"log/slog"
	"os"
)

func main() {
	// Development: text output
	if os.Getenv("ENV") == "dev" {
		logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
			Level: slog.LevelDebug,
		}))
		slog.SetDefault(logger)
	} else {
		// Production: JSON output for CloudWatch
		logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
			Level: slog.LevelInfo,
		}))
		slog.SetDefault(logger)
	}

	// All middleware will now use the configured logger
	// ...
}
```

---

## References

- [Middleware README](/Users/travis.smith/Projects/personal/RR/api/internal/middleware/README.md)
- [Cache README](/Users/travis.smith/Projects/personal/RR/api/internal/cache/README.md)
- [Events README](/Users/travis.smith/Projects/personal/RR/api/internal/events/README.md)
- [Packages Summary](/Users/travis.smith/Projects/personal/RR/api/internal/PACKAGES_SUMMARY.md)
