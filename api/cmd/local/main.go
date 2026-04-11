// cmd/local/main.go
package main

import (
	"context"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	appconfig "github.com/regalrecovery/api/internal/config"
	"github.com/regalrecovery/api/internal/middleware"
	"github.com/regalrecovery/api/internal/repository"
)

func main() {
	// Initialize structured logger (human-readable for local dev)
	logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelDebug,
	}))
	slog.SetDefault(logger)

	ctx := context.Background()

	// Load configuration from environment
	cfg := appconfig.Load()
	slog.Info("Configuration loaded",
		slog.String("environment", cfg.Environment),
		slog.String("mongodb_uri", cfg.MongoURI),
		slog.String("mongodb_database", cfg.MongoDatabase),
		slog.String("valkey_addr", cfg.ValkeyAddr),
	)

	// Create MongoDB client
	mongoClient, err := repository.NewMongoClient(ctx, cfg.MongoURI, cfg.MongoDatabase)
	if err != nil {
		slog.Error("failed to connect to MongoDB", "error", err)
		os.Exit(1)
	}
	defer mongoClient.Disconnect(ctx)

	// Create indexes
	if err := mongoClient.EnsureIndexes(ctx); err != nil {
		slog.Error("failed to create indexes", "error", err)
		os.Exit(1)
	}
	slog.Info("MongoDB indexes ensured")

	// Create main router
	mux := http.NewServeMux()

	// ========================================================================
	// Auth Routes (/v1/auth/*)
	// ========================================================================
	mux.HandleFunc("POST /v1/auth/register", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotImplemented)
		w.Write([]byte(`{"errors":[{"status":501,"title":"Not Implemented","detail":"Auth service not yet implemented"}]}`))
	})
	mux.HandleFunc("GET /v1/auth/session", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotImplemented)
		w.Write([]byte(`{"errors":[{"status":501,"title":"Not Implemented","detail":"Auth service not yet implemented"}]}`))
	})

	// ========================================================================
	// Tracking Routes (/v1/tracking/*)
	// ========================================================================
	mux.HandleFunc("GET /v1/tracking/streak", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotImplemented)
		w.Write([]byte(`{"errors":[{"status":501,"title":"Not Implemented","detail":"Tracking service not yet implemented"}]}`))
	})
	mux.HandleFunc("POST /v1/tracking/relapse", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotImplemented)
		w.Write([]byte(`{"errors":[{"status":501,"title":"Not Implemented","detail":"Tracking service not yet implemented"}]}`))
	})
	mux.HandleFunc("GET /v1/tracking/milestones", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotImplemented)
		w.Write([]byte(`{"errors":[{"status":501,"title":"Not Implemented","detail":"Tracking service not yet implemented"}]}`))
	})
	mux.HandleFunc("GET /v1/tracking/calendar", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotImplemented)
		w.Write([]byte(`{"errors":[{"status":501,"title":"Not Implemented","detail":"Tracking service not yet implemented"}]}`))
	})

	// ========================================================================
	// Activities Routes (/v1/activities/*)
	// ========================================================================
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

	// ========================================================================
	// Content Routes (/v1/content/*)
	// ========================================================================
	mux.HandleFunc("GET /v1/content/affirmations", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotImplemented)
		w.Write([]byte(`{"errors":[{"status":501,"title":"Not Implemented","detail":"Content service not yet implemented"}]}`))
	})
	mux.HandleFunc("GET /v1/content/affirmations/{packId}", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotImplemented)
		w.Write([]byte(`{"errors":[{"status":501,"title":"Not Implemented","detail":"Content service not yet implemented"}]}`))
	})
	mux.HandleFunc("GET /v1/content/devotional/{day}", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotImplemented)
		w.Write([]byte(`{"errors":[{"status":501,"title":"Not Implemented","detail":"Content service not yet implemented"}]}`))
	})

	// ========================================================================
	// Health Check Routes (for local debugging)
	// ========================================================================
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status":"ok","service":"regal-recovery-api","environment":"local"}`))
	})

	// Wrap with middleware chain: recovery -> correlation -> logging
	// Skip auth/tenant middleware for local development to simplify testing
	handler := middleware.Chain(
		mux,
		middleware.RecoveryMiddleware,
		middleware.CorrelationMiddleware,
		middleware.LoggingMiddleware,
	)

	// Suppress "declared but not used" errors during development
	_ = mongoClient

	// Determine port from environment variable or default to 8080
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Create HTTP server
	server := &http.Server{
		Addr:         ":" + port,
		Handler:      handler,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start server in a goroutine
	serverErrors := make(chan error, 1)
	go func() {
		slog.Info("Starting local API server",
			slog.String("port", port),
			slog.String("environment", cfg.Environment),
		)
		slog.Info("Available route prefixes",
			slog.String("auth", "/v1/auth/*"),
			slog.String("tracking", "/v1/tracking/*"),
			slog.String("activities", "/v1/activities/*"),
			slog.String("content", "/v1/content/*"),
			slog.String("health", "/healthz"),
		)
		slog.Info("Local API server listening", slog.String("address", "http://localhost:"+port))

		serverErrors <- server.ListenAndServe()
	}()

	// Setup graceful shutdown
	shutdown := make(chan os.Signal, 1)
	signal.Notify(shutdown, os.Interrupt, syscall.SIGTERM)

	// Block until shutdown signal or server error
	select {
	case err := <-serverErrors:
		if err != nil && err != http.ErrServerClosed {
			slog.Error("Server error", "error", err)
			os.Exit(1)
		}
	case sig := <-shutdown:
		slog.Info("Shutdown signal received", slog.String("signal", sig.String()))

		// Give outstanding requests 10 seconds to complete
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()

		if err := server.Shutdown(ctx); err != nil {
			slog.Error("Failed to shutdown gracefully", "error", err)
			if err := server.Close(); err != nil {
				slog.Error("Failed to close server", "error", err)
			}
			os.Exit(1)
		}

		slog.Info("Server stopped gracefully")
	}
}
