// internal/repository/example_test.go
package repository_test

import (
	"context"
	"fmt"
	"log"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/regalrecovery/api/internal/repository"
)

// ExampleNewDynamoClient demonstrates how to initialize the DynamoDB client.
func ExampleNewDynamoClient() {
	ctx := context.Background()

	// Load AWS config
	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion("us-east-1"))
	if err != nil {
		log.Fatal(err)
	}

	// Create DynamoDB client for production
	client := repository.NewDynamoClient(cfg, "regal-recovery", "")

	// Or for local development with LocalStack
	_ = repository.NewDynamoClient(cfg, "regal-recovery", "http://localhost:4566")

	fmt.Printf("DynamoDB client initialized: %v\n", client != nil)
	// Output: DynamoDB client initialized: true
}

// ExampleUserRepo_CreateUser demonstrates how to create a user.
func ExampleUserRepo_CreateUser() {
	ctx := context.Background()
	cfg, _ := config.LoadDefaultConfig(ctx)
	client := repository.NewDynamoClient(cfg, "regal-recovery", "")
	userRepo := repository.NewUserRepo(client)

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
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("User created successfully")
}

// ExampleUserRepo_GetUserByEmail demonstrates how to look up a user by email.
func ExampleUserRepo_GetUserByEmail() {
	ctx := context.Background()
	cfg, _ := config.LoadDefaultConfig(ctx)
	client := repository.NewDynamoClient(cfg, "regal-recovery", "")
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
	cfg, _ := config.LoadDefaultConfig(ctx)
	client := repository.NewDynamoClient(cfg, "regal-recovery", "")
	activityRepo := repository.NewActivityRepo(client)

	checkIn := &repository.CheckIn{
		BaseItem: repository.BaseItem{
			PK:       "USER#u_12345",
			SK:       "CHECKIN#2026-03-28T21:00:00Z",
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
	cfg, _ := config.LoadDefaultConfig(ctx)
	client := repository.NewDynamoClient(cfg, "regal-recovery", "")
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
	cfg, _ := config.LoadDefaultConfig(ctx)
	client := repository.NewDynamoClient(cfg, "regal-recovery", "")
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
	cfg, _ := config.LoadDefaultConfig(ctx)
	client := repository.NewDynamoClient(cfg, "regal-recovery", "")
	contentRepo := repository.NewContentRepo(client)

	devotional, err := contentRepo.GetDevotional(ctx, 1)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("Devotional day %d: %s\n", devotional.Day, devotional.Title)
}

// ExampleSupportRepo_GrantPermission demonstrates how to grant a permission.
func ExampleSupportRepo_GrantPermission() {
	ctx := context.Background()
	cfg, _ := config.LoadDefaultConfig(ctx)
	client := repository.NewDynamoClient(cfg, "regal-recovery", "")
	supportRepo := repository.NewSupportRepo(client)

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
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Permission granted successfully")
}

// ExampleActivityRepo_GetActivitiesByDate demonstrates calendar day view.
func ExampleActivityRepo_GetActivitiesByDate() {
	ctx := context.Background()
	cfg, _ := config.LoadDefaultConfig(ctx)
	client := repository.NewDynamoClient(cfg, "regal-recovery", "")
	activityRepo := repository.NewActivityRepo(client)

	// Get all activities for a specific day
	activities, err := activityRepo.GetActivitiesByDate(ctx, "u_12345", "2026-03-28")
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("Found %d activities for 2026-03-28\n", len(activities))
}

// ExampleActivityRepo_GetActivitiesByDateRange demonstrates calendar month view.
func ExampleActivityRepo_GetActivitiesByDateRange() {
	ctx := context.Background()
	cfg, _ := config.LoadDefaultConfig(ctx)
	client := repository.NewDynamoClient(cfg, "regal-recovery", "")
	activityRepo := repository.NewActivityRepo(client)

	// Get all activities for a month
	activities, err := activityRepo.GetActivitiesByDateRange(ctx, "u_12345", "2026-03-01", "2026-03-31")
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("Found %d activities for March 2026\n", len(activities))
}

// ExampleFormatPK demonstrates helper function usage.
func ExampleFormatPK() {
	pk := repository.FormatPK("USER", "u_12345")
	fmt.Println(pk)
	// Output: USER#u_12345
}

// ExampleBuildActivitySK demonstrates building a composite sort key.
func ExampleBuildActivitySK() {
	sk := repository.BuildActivitySK("2026-03-28", "CHECKIN", "2026-03-28T21:00:00Z")
	fmt.Println(sk)
	// Output: ACTIVITY#2026-03-28#CHECKIN#2026-03-28T21:00:00Z
}
