// internal/repository/example_test.go
package repository_test

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/regalrecovery/api/internal/repository"
)

// ExampleNewMongoClient demonstrates how to initialize the MongoDB client.
func ExampleNewMongoClient() {
	ctx := context.Background()

	// Create MongoDB client for local development
	client, err := repository.NewMongoClient(ctx, "mongodb://localhost:27017", "regal-recovery")
	if err != nil {
		log.Fatal(err)
	}
	defer client.Disconnect(ctx)

	fmt.Printf("MongoDB client initialized: %v\n", client != nil)
	// Output: MongoDB client initialized: true
}

// ExampleUserRepo_CreateUser demonstrates how to create a user.
func ExampleUserRepo_CreateUser() {
	ctx := context.Background()
	client, _ := repository.NewMongoClient(ctx, "mongodb://localhost:27017", "regal-recovery")
	defer client.Disconnect(ctx)
	userRepo := repository.NewUserRepo(client)

	user := &repository.User{
		BaseDocument: repository.BaseDocument{
			TenantID: "DEFAULT",
		},
		UserID:                "u_12345",
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
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("User created successfully")
}

// ExampleUserRepo_GetUserByEmail demonstrates how to look up a user by email.
func ExampleUserRepo_GetUserByEmail() {
	ctx := context.Background()
	client, _ := repository.NewMongoClient(ctx, "mongodb://localhost:27017", "regal-recovery")
	defer client.Disconnect(ctx)
	userRepo := repository.NewUserRepo(client)

	user, err := userRepo.GetUserByEmail(ctx, "john@example.com")
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("Found user: %s\n", user.DisplayName)
}

// ExampleActivityRepo_CreateCheckIn demonstrates how to create a check-in.
func ExampleActivityRepo_CreateCheckIn() {
	ctx := context.Background()
	client, _ := repository.NewMongoClient(ctx, "mongodb://localhost:27017", "regal-recovery")
	defer client.Disconnect(ctx)
	activityRepo := repository.NewActivityRepo(client)

	checkIn := &repository.CheckIn{
		BaseDocument: repository.BaseDocument{
			TenantID: "DEFAULT",
		},
		CheckInID: "c_55555",
		Type:      "daily",
		Responses: map[string]interface{}{
			"sobrietyStatus":        "yes",
			"urgeCount":             2,
			"meetingAttended":       true,
			"spiritualPractices":    true,
			"emotionalState":        7,
			"supportNetworkContact": true,
			"overallRecoveryHealth": 8,
		},
		Score:     85,
		ColorCode: "green",
	}

	err := activityRepo.CreateCheckIn(ctx, "u_12345", checkIn)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Check-in created successfully")
}

// ExampleTrackingRepo_GetStreak demonstrates how to retrieve a sobriety streak.
func ExampleTrackingRepo_GetStreak() {
	ctx := context.Background()
	client, _ := repository.NewMongoClient(ctx, "mongodb://localhost:27017", "regal-recovery")
	defer client.Disconnect(ctx)
	trackingRepo := repository.NewTrackingRepo(client)

	streak, err := trackingRepo.GetStreak(ctx, "u_12345", "a_67890")
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("Current streak: %d days\n", streak.CurrentStreakDays)
}

// ExampleFlagRepo_GetAllFlags demonstrates how to retrieve all feature flags.
func ExampleFlagRepo_GetAllFlags() {
	ctx := context.Background()
	client, _ := repository.NewMongoClient(ctx, "mongodb://localhost:27017", "regal-recovery")
	defer client.Disconnect(ctx)
	flagRepo := repository.NewFlagRepo(client)

	flags, err := flagRepo.GetAllFlags(ctx)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("Retrieved %d feature flags\n", len(flags))
}

// ExampleContentRepo_GetDevotional demonstrates how to retrieve a devotional.
func ExampleContentRepo_GetDevotional() {
	ctx := context.Background()
	client, _ := repository.NewMongoClient(ctx, "mongodb://localhost:27017", "regal-recovery")
	defer client.Disconnect(ctx)
	contentClient := repository.NewContentClient(client.Client(), "regal-recovery-content")
	contentRepo := repository.NewContentRepo(contentClient)

	devotional, err := contentRepo.GetDevotional(ctx, "dpack_foundations", 1)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("Devotional day %d: %s\n", devotional.Day, devotional.Title)
}

// ExampleSupportRepo_GrantPermission demonstrates how to grant a permission.
func ExampleSupportRepo_GrantPermission() {
	ctx := context.Background()
	client, _ := repository.NewMongoClient(ctx, "mongodb://localhost:27017", "regal-recovery")
	defer client.Disconnect(ctx)
	supportRepo := repository.NewSupportRepo(client)

	permission := &repository.Permission{
		BaseDocument: repository.BaseDocument{
			TenantID: "DEFAULT",
		},
		UserID:        "u_12345",
		PermissionID:  "p_11111",
		ContactID:     "c_99999",
		ContactUserID: "u_54321",
		DataCategory:  "streaks",
		AccessLevel:   "read",
		GrantedAt:     time.Now().UTC(),
	}

	err := supportRepo.GrantPermission(ctx, permission)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Permission granted successfully")
}

// ExampleActivityRepo_GetActivitiesByDate demonstrates calendar day view.
func ExampleActivityRepo_GetActivitiesByDate() {
	ctx := context.Background()
	client, _ := repository.NewMongoClient(ctx, "mongodb://localhost:27017", "regal-recovery")
	defer client.Disconnect(ctx)
	activityRepo := repository.NewActivityRepo(client)

	activities, err := activityRepo.GetActivitiesByDate(ctx, "u_12345", "2026-03-28")
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("Found %d activities for 2026-03-28\n", len(activities))
}

// ExampleActivityRepo_GetActivitiesByDateRange demonstrates calendar month view.
func ExampleActivityRepo_GetActivitiesByDateRange() {
	ctx := context.Background()
	client, _ := repository.NewMongoClient(ctx, "mongodb://localhost:27017", "regal-recovery")
	defer client.Disconnect(ctx)
	activityRepo := repository.NewActivityRepo(client)

	activities, err := activityRepo.GetActivitiesByDateRange(ctx, "u_12345", "2026-03-01", "2026-03-31")
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("Found %d activities for March 2026\n", len(activities))
}
