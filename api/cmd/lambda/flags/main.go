// cmd/lambda/flags/main.go
package main

import (
	"context"
	"log/slog"
	"net/http"
	"os"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/config"

	"github.com/regalrecovery/api/internal/cache"
	appconfig "github.com/regalrecovery/api/internal/config"
	"github.com/regalrecovery/api/internal/middleware"
	"github.com/regalrecovery/api/pkg/lambdahttp"
)

func main() {
	// Initialize structured logger
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))
	slog.SetDefault(logger)

	ctx := context.Background()

	// Load configuration from environment
	cfg := appconfig.Load()

	// Create AWS SDK config
	awsCfg, err := config.LoadDefaultConfig(ctx,
		config.WithRegion(cfg.AWSRegion),
	)
	if err != nil {
		slog.Error("failed to load AWS config", "error", err)
		os.Exit(1)
	}

	// Note: Repository, cache, and service layers not yet fully implemented.
	// For now, create a simple HTTP handler that returns 501 Not Implemented.
	// TODO: Wire up full dependency chain when implementation is complete.

	// Create HTTP router
	mux := http.NewServeMux()
	mux.HandleFunc("GET /v1/flags", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotImplemented)
		w.Write([]byte(`{"errors":[{"status":501,"title":"Not Implemented","detail":"Flag service not yet implemented"}]}`))
	})
	mux.HandleFunc("GET /v1/flags/{key}", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotImplemented)
		w.Write([]byte(`{"errors":[{"status":501,"title":"Not Implemented","detail":"Flag service not yet implemented"}]}`))
	})
	mux.HandleFunc("PUT /v1/flags/{key}", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotImplemented)
		w.Write([]byte(`{"errors":[{"status":501,"title":"Not Implemented","detail":"Flag service not yet implemented"}]}`))
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
	_ = awsCfg
	_ = cfg
	_ = cache.ValkeyClient{}

	// Create Lambda adapter and start
	adapter := lambdahttp.NewAdapter(handler)
	lambda.Start(adapter.Handle)
}
