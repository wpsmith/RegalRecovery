// internal/repository/user_repo.go
package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
)

// UserRepo implements UserRepository using DynamoDB.
type UserRepo struct {
	client *DynamoClient
}

// NewUserRepo creates a new UserRepo.
func NewUserRepo(client *DynamoClient) *UserRepo {
	return &UserRepo{client: client}
}

// GetUser retrieves a user profile by user ID.
// PK: USER#{userID}, SK: PROFILE
func (r *UserRepo) GetUser(ctx context.Context, userID string) (*User, error) {
	var user User
	err := r.client.GetItem(ctx, fmt.Sprintf("USER#%s", userID), "PROFILE", &user)
	if err != nil {
		return nil, fmt.Errorf("getting user %s: %w", userID, err)
	}
	return &user, nil
}

// GetUserByEmail retrieves a user profile by email address using GSI1.
// GSI1PK: EMAIL#{email}, GSI1SK: USER#{userID}
func (r *UserRepo) GetUserByEmail(ctx context.Context, email string) (*User, error) {
	result, err := r.client.QueryGSI(ctx, "GSI1", &dynamodb.QueryInput{
		KeyConditionExpression: aws.String("GSI1PK = :email"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":email": &types.AttributeValueMemberS{Value: fmt.Sprintf("EMAIL#%s", email)},
		},
		Limit: aws.Int32(1),
	})
	if err != nil {
		return nil, fmt.Errorf("querying user by email %s: %w", email, err)
	}

	if len(result.Items) == 0 {
		return nil, fmt.Errorf("user not found with email: %s", email)
	}

	var user User
	if err := attributevalue.UnmarshalMap(result.Items[0], &user); err != nil {
		return nil, fmt.Errorf("unmarshaling user: %w", err)
	}

	return &user, nil
}

// CreateUser creates a new user profile.
func (r *UserRepo) CreateUser(ctx context.Context, user *User) error {
	now := time.Now().UTC().Format(time.RFC3339)
	user.CreatedAt = now
	user.ModifiedAt = now
	user.EntityType = "USER"

	if err := r.client.PutItem(ctx, user); err != nil {
		return fmt.Errorf("creating user: %w", err)
	}

	return nil
}

// UpdateUser updates an existing user profile.
func (r *UserRepo) UpdateUser(ctx context.Context, user *User) error {
	user.ModifiedAt = time.Now().UTC().Format(time.RFC3339)

	if err := r.client.PutItem(ctx, user); err != nil {
		return fmt.Errorf("updating user: %w", err)
	}

	return nil
}

// DeleteUser deletes a user profile.
func (r *UserRepo) DeleteUser(ctx context.Context, userID string) error {
	if err := r.client.DeleteItem(ctx, fmt.Sprintf("USER#%s", userID), "PROFILE"); err != nil {
		return fmt.Errorf("deleting user %s: %w", userID, err)
	}

	return nil
}

// GetUserSettings retrieves user settings.
// PK: USER#{userID}, SK: SETTINGS
func (r *UserRepo) GetUserSettings(ctx context.Context, userID string) (*UserSettings, error) {
	var settings UserSettings
	err := r.client.GetItem(ctx, fmt.Sprintf("USER#%s", userID), "SETTINGS", &settings)
	if err != nil {
		return nil, fmt.Errorf("getting user settings for %s: %w", userID, err)
	}
	return &settings, nil
}

// UpdateUserSettings updates user settings.
func (r *UserRepo) UpdateUserSettings(ctx context.Context, settings *UserSettings) error {
	settings.ModifiedAt = time.Now().UTC().Format(time.RFC3339)

	if err := r.client.PutItem(ctx, settings); err != nil {
		return fmt.Errorf("updating user settings: %w", err)
	}

	return nil
}

// ListAddictions lists all addictions for a user.
// PK: USER#{userID}, SK begins_with ADDICTION#
func (r *UserRepo) ListAddictions(ctx context.Context, userID string) ([]Addiction, error) {
	result, err := r.client.Query(ctx, &dynamodb.QueryInput{
		KeyConditionExpression: aws.String("PK = :pk AND begins_with(SK, :sk)"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":pk": &types.AttributeValueMemberS{Value: fmt.Sprintf("USER#%s", userID)},
			":sk": &types.AttributeValueMemberS{Value: "ADDICTION#"},
		},
	})
	if err != nil {
		return nil, fmt.Errorf("listing addictions for user %s: %w", userID, err)
	}

	var addictions []Addiction
	if err := attributevalue.UnmarshalListOfMaps(result.Items, &addictions); err != nil {
		return nil, fmt.Errorf("unmarshaling addictions: %w", err)
	}

	return addictions, nil
}

// GetAddiction retrieves a specific addiction by ID.
// PK: USER#{userID}, SK: ADDICTION#{addictionID}
func (r *UserRepo) GetAddiction(ctx context.Context, userID, addictionID string) (*Addiction, error) {
	var addiction Addiction
	err := r.client.GetItem(ctx, fmt.Sprintf("USER#%s", userID), fmt.Sprintf("ADDICTION#%s", addictionID), &addiction)
	if err != nil {
		return nil, fmt.Errorf("getting addiction %s for user %s: %w", addictionID, userID, err)
	}
	return &addiction, nil
}

// CreateAddiction creates a new addiction record.
func (r *UserRepo) CreateAddiction(ctx context.Context, addiction *Addiction) error {
	now := time.Now().UTC().Format(time.RFC3339)
	addiction.CreatedAt = now
	addiction.ModifiedAt = now
	addiction.EntityType = "ADDICTION"

	if err := r.client.PutItem(ctx, addiction); err != nil {
		return fmt.Errorf("creating addiction: %w", err)
	}

	return nil
}

// UpdateAddiction updates an existing addiction record.
func (r *UserRepo) UpdateAddiction(ctx context.Context, addiction *Addiction) error {
	addiction.ModifiedAt = time.Now().UTC().Format(time.RFC3339)

	if err := r.client.PutItem(ctx, addiction); err != nil {
		return fmt.Errorf("updating addiction: %w", err)
	}

	return nil
}
