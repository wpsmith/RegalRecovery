// cmd/lambda/activities/main.go
package main

import (
	"context"
	"log/slog"
	"net/http"
	"os"

	"github.com/aws/aws-lambda-go/lambda"

	appconfig "github.com/regalrecovery/api/internal/config"
	"github.com/regalrecovery/api/internal/domain/activities"
	"github.com/regalrecovery/api/internal/domain/affirmations"
	"github.com/regalrecovery/api/internal/domain/timejournal"
	"github.com/regalrecovery/api/internal/middleware"
	"github.com/regalrecovery/api/internal/repository"
	"github.com/regalrecovery/api/pkg/lambdahttp"
)

// mongoClient is declared at package level for connection reuse across Lambda invocations.
var mongoClient *repository.MongoClient

func init() {
	ctx := context.Background()
	cfg := appconfig.Load()

	var err error
	mongoClient, err = repository.NewMongoClient(ctx, cfg.MongoURI, cfg.MongoDatabase)
	if err != nil {
		slog.Error("failed to connect to MongoDB", "error", err)
		os.Exit(1)
	}
}

func main() {
	// Initialize structured logger
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))
	slog.SetDefault(logger)

	// Wire Time Journal dependency chain:
	// MongoClient -> TimeJournalRepo -> TimeJournalService -> Handler
	tjRepo := repository.NewTimeJournalRepo(mongoClient)
	tjService := timejournal.NewTimeJournalService(tjRepo)
	tjHandler := timejournal.NewHandler(tjService)

	// Create HTTP router
	mux := http.NewServeMux()

	// Register Time Journal routes
	tjHandler.RegisterRoutes(mux)

	// Wire Affirmations dependency chain:
	// MongoClient -> AffirmationsRepo -> Handler
	affRepo := repository.NewAffirmationsRepo(mongoClient)
	affHandler := affirmations.NewHandler(affRepo, nil, nil)
	affHandler.RegisterRoutes(mux)

	// Generic activity routes (stub — not yet implemented)
	mux.HandleFunc("POST /v1/activities/{type}", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotImplemented)
		w.Write([]byte(`{"errors":[{"status":501,"title":"Not Implemented","detail":"Activity handler not yet implemented"}]}`))
	})
	mux.HandleFunc("GET /v1/activities/{type}", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotImplemented)
		w.Write([]byte(`{"errors":[{"status":501,"title":"Not Implemented","detail":"Activity handler not yet implemented"}]}`))
	})
	mux.HandleFunc("GET /v1/activities", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotImplemented)
		w.Write([]byte(`{"errors":[{"status":501,"title":"Not Implemented","detail":"Activity handler not yet implemented"}]}`))
	})

	// Wrap with middleware chain: recovery -> correlation -> logging -> auth -> tenant
	handler := middleware.Chain(
		mux,
		middleware.RecoveryMiddleware,
		middleware.CorrelationMiddleware,
		middleware.LoggingMiddleware,
		middleware.AuthMiddleware,
		middleware.TenantMiddleware,
	)

	// Suppress "declared but not used" errors during development
	_ = activities.ActivityTypeCheckIn

	// Create Lambda adapter and start
	adapter := lambdahttp.NewAdapter(handler)
	lambda.Start(adapter.Handle)
}
