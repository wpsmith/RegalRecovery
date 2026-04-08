// cmd/lambda/activities/main.go
package main

import (
	"context"
	"log/slog"
	"net/http"
	"os"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"

	appconfig "github.com/regalrecovery/api/internal/config"
	"github.com/regalrecovery/api/internal/cache"
	"github.com/regalrecovery/api/internal/domain/activities"
	"github.com/regalrecovery/api/internal/domain/exercise"
	meetingsDomain "github.com/regalrecovery/api/internal/domain/meetings"
	"github.com/regalrecovery/api/internal/domain/phonecalls"
	"github.com/regalrecovery/api/internal/domain/timejournal"
	"github.com/regalrecovery/api/internal/events"
	meetingsEvents "github.com/regalrecovery/api/internal/events/meetings"
	meetingsHandler "github.com/regalrecovery/api/internal/handler/meetings"
	"github.com/regalrecovery/api/internal/middleware"
	"github.com/regalrecovery/api/internal/repository"
	meetingsRepo "github.com/regalrecovery/api/internal/repository/meetings"
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

	// Wire Meetings dependency chain:
	// MongoClient -> Repos -> Services -> Handlers
	meetingRepo := meetingsRepo.NewMongoMeetingRepository(mongoClient)
	savedMeetingRepo := meetingsRepo.NewMongoSavedMeetingRepository(mongoClient)

	// Event publisher (local dev mode: empty topic ARN logs events instead of publishing).
	meetingPublisher := meetingsEvents.NewMeetingEventPublisher(
		events.NewSNSPublisher(aws.Config{Region: appconfig.Load().AWSRegion}, appconfig.Load().SNSTopicARN),
	)

	meetingLogSvc := meetingsDomain.NewMeetingLogService(meetingRepo, savedMeetingRepo, meetingPublisher)
	savedMeetingSvc := meetingsDomain.NewSavedMeetingService(savedMeetingRepo)
	summarySvc := meetingsDomain.NewSummaryService(meetingRepo)

	// Feature flag checker: always enabled for now (will be wired to flag service).
	meetingsHdlr := meetingsHandler.NewHandler(meetingLogSvc, savedMeetingSvc, summarySvc, nil)

	// Wire Phone Calls dependency chain:
	// MongoClient -> Repos -> Cache -> Service -> Handler
	pcCallRepo := repository.NewPhoneCallRepo(mongoClient)
	pcContactRepo := repository.NewSavedContactRepo(mongoClient)
	pcStreakCache := cache.NewValkeyPhoneCallStreakCache(nil) // Valkey client wired at infra layer
	pcService := phonecalls.NewPhoneCallService(pcCallRepo, pcContactRepo, pcStreakCache)
	pcHandler := phonecalls.NewHandler(pcService)

	// Wire Exercise dependency chain:
	// MongoClient -> Repos -> ExerciseService -> Handler
	exRepo := repository.NewExerciseLogRepo(mongoClient)
	exFavRepo := repository.NewExerciseFavoriteRepo(mongoClient)
	exGoalRepo := repository.NewExerciseGoalRepo(mongoClient)
	exService := exercise.NewExerciseService(exRepo, exFavRepo, exGoalRepo)
	exHandler := exercise.NewHandler(exService)

	// Create HTTP router
	mux := http.NewServeMux()

	// Register Time Journal routes
	tjHandler.RegisterRoutes(mux)

	// Register Meeting routes
	meetingsHdlr.RegisterRoutes(mux)

	// Register Phone Calls routes
	pcHandler.RegisterRoutes(mux)

	// Register Exercise routes
	exHandler.RegisterRoutes(mux)

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
