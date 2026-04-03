// internal/repository/user_repo.go
package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// UserRepo implements UserRepository using MongoDB.
type UserRepo struct {
	client *MongoClient
}

// NewUserRepo creates a new UserRepo.
func NewUserRepo(client *MongoClient) *UserRepo {
	return &UserRepo{client: client}
}

// GetUser retrieves a user profile by user ID.
func (r *UserRepo) GetUser(ctx context.Context, userID string) (*User, error) {
	var user User
	err := r.client.Collection("users").FindOne(ctx, bson.M{"userId": userID}).Decode(&user)
	if err != nil {
		return nil, fmt.Errorf("getting user %s: %w", userID, err)
	}
	return &user, nil
}

// GetUserByEmail retrieves a user profile by email address.
func (r *UserRepo) GetUserByEmail(ctx context.Context, email string) (*User, error) {
	var user User
	err := r.client.Collection("users").FindOne(ctx, bson.M{"email": email}).Decode(&user)
	if err != nil {
		return nil, fmt.Errorf("getting user by email %s: %w", email, err)
	}
	return &user, nil
}

// CreateUser creates a new user profile.
func (r *UserRepo) CreateUser(ctx context.Context, user *User) error {
	SetBaseDocumentDefaults(&user.BaseDocument)

	if _, err := r.client.Collection("users").InsertOne(ctx, user); err != nil {
		return fmt.Errorf("creating user: %w", err)
	}
	return nil
}

// UpdateUser updates an existing user profile.
func (r *UserRepo) UpdateUser(ctx context.Context, user *User) error {
	UpdateModified(&user.BaseDocument)

	if _, err := r.client.Collection("users").ReplaceOne(ctx, bson.M{"userId": user.UserID}, user); err != nil {
		return fmt.Errorf("updating user: %w", err)
	}
	return nil
}

// DeleteUser deletes a user profile.
func (r *UserRepo) DeleteUser(ctx context.Context, userID string) error {
	if _, err := r.client.Collection("users").DeleteOne(ctx, bson.M{"userId": userID}); err != nil {
		return fmt.Errorf("deleting user %s: %w", userID, err)
	}
	return nil
}

// GetUserSettings retrieves user settings.
func (r *UserRepo) GetUserSettings(ctx context.Context, userID string) (*UserSettings, error) {
	var settings UserSettings
	err := r.client.Collection("user_settings").FindOne(ctx, bson.M{"userId": userID}).Decode(&settings)
	if err != nil {
		return nil, fmt.Errorf("getting user settings for %s: %w", userID, err)
	}
	return &settings, nil
}

// UpdateUserSettings updates user settings, creating them if they don't exist.
func (r *UserRepo) UpdateUserSettings(ctx context.Context, settings *UserSettings) error {
	UpdateModified(&settings.BaseDocument)

	opts := options.Replace().SetUpsert(true)
	if _, err := r.client.Collection("user_settings").ReplaceOne(ctx, bson.M{"userId": settings.UserID}, settings, opts); err != nil {
		return fmt.Errorf("updating user settings: %w", err)
	}
	return nil
}

// ListAddictions lists all addictions for a user.
func (r *UserRepo) ListAddictions(ctx context.Context, userID string) ([]Addiction, error) {
	cursor, err := r.client.Collection("addictions").Find(ctx, bson.M{"userId": userID})
	if err != nil {
		return nil, fmt.Errorf("listing addictions for user %s: %w", userID, err)
	}

	var addictions []Addiction
	if err := cursor.All(ctx, &addictions); err != nil {
		return nil, fmt.Errorf("decoding addictions: %w", err)
	}
	return addictions, nil
}

// GetAddiction retrieves a specific addiction by ID.
func (r *UserRepo) GetAddiction(ctx context.Context, userID, addictionID string) (*Addiction, error) {
	var addiction Addiction
	err := r.client.Collection("addictions").FindOne(ctx, bson.M{"userId": userID, "addictionId": addictionID}).Decode(&addiction)
	if err != nil {
		return nil, fmt.Errorf("getting addiction %s for user %s: %w", addictionID, userID, err)
	}
	return &addiction, nil
}

// CreateAddiction creates a new addiction record.
func (r *UserRepo) CreateAddiction(ctx context.Context, addiction *Addiction) error {
	SetBaseDocumentDefaults(&addiction.BaseDocument)

	if _, err := r.client.Collection("addictions").InsertOne(ctx, addiction); err != nil {
		return fmt.Errorf("creating addiction: %w", err)
	}
	return nil
}

// UpdateAddiction updates an existing addiction record.
func (r *UserRepo) UpdateAddiction(ctx context.Context, addiction *Addiction) error {
	UpdateModified(&addiction.BaseDocument)

	if _, err := r.client.Collection("addictions").ReplaceOne(ctx, bson.M{"userId": addiction.UserID, "addictionId": addiction.AddictionID}, addiction); err != nil {
		return fmt.Errorf("updating addiction: %w", err)
	}
	return nil
}
