// cmd/lambda/devotionals/main.go
package main

import (
	"context"
	"log/slog"
	"net/http"
	"os"

	"github.com/aws/aws-lambda-go/lambda"

	appconfig "github.com/regalrecovery/api/internal/config"
	"github.com/regalrecovery/api/internal/domain/devotionals"
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

	// Wire Devotionals dependency chain
	contentRepo := repository.NewDevotionalContentRepo(mongoClient)
	completionRepo := repository.NewDevotionalCompletionRepo(mongoClient)
	favoriteRepo := repository.NewDevotionalFavoriteRepo(mongoClient)
	seriesProgressRepo := repository.NewSeriesProgressRepo(mongoClient)
	seriesRepo := repository.NewDevotionalSeriesRepo(mongoClient)
	streakRepo := repository.NewDevotionalStreakRepo(mongoClient)

	// Domain services
	selector := devotionals.NewDevotionalSelector(contentRepo, seriesProgressRepo)
	streakCalc := devotionals.NewStreakCalculator(streakRepo)
	completionSvc := devotionals.NewCompletionService(completionRepo, contentRepo, streakCalc)
	favoritesSvc := devotionals.NewFavoritesService(favoriteRepo, contentRepo)
	seriesSvc := devotionals.NewSeriesProgressionService(seriesProgressRepo, seriesRepo)
	shareSvc := devotionals.NewShareService(contentRepo)
	accessChecker := devotionals.NewAccessChecker()

	// Feature flag check -- reads from flags collection
	// TODO: Wire to actual flag service; for now default to disabled (fail closed)
	flagEnabled := func() bool {
		return false
	}

	handler := devotionals.NewHandler(
		selector, completionSvc, favoritesSvc, seriesSvc,
		shareSvc, streakCalc, accessChecker, flagEnabled,
	)

	// Create HTTP router
	mux := http.NewServeMux()
	handler.RegisterRoutes(mux)

	// Wrap with middleware chain: recovery -> correlation -> logging -> auth -> tenant
	wrapped := middleware.Chain(
		mux,
		middleware.RecoveryMiddleware,
		middleware.CorrelationMiddleware,
		middleware.LoggingMiddleware,
		middleware.AuthMiddleware,
		middleware.TenantMiddleware,
	)

	// Create Lambda adapter and start
	adapter := lambdahttp.NewAdapter(wrapped)
	lambda.Start(adapter.Handle)
}
