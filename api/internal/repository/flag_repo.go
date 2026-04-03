// internal/repository/flag_repo.go
package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// FlagRepo implements FlagRepository using MongoDB.
type FlagRepo struct {
	client *MongoClient
}

// NewFlagRepo creates a new FlagRepo.
func NewFlagRepo(client *MongoClient) *FlagRepo {
	return &FlagRepo{client: client}
}

// GetFlag retrieves a single feature flag by key.
func (r *FlagRepo) GetFlag(ctx context.Context, flagKey string) (*Flag, error) {
	var flag Flag
	err := r.client.Collection("flags").FindOne(ctx, bson.M{"flagKey": flagKey}).Decode(&flag)
	if err != nil {
		return nil, fmt.Errorf("getting flag %s: %w", flagKey, err)
	}
	return &flag, nil
}

// GetAllFlags retrieves all feature flags.
func (r *FlagRepo) GetAllFlags(ctx context.Context) ([]Flag, error) {
	cursor, err := r.client.Collection("flags").Find(ctx, bson.M{})
	if err != nil {
		return nil, fmt.Errorf("listing all flags: %w", err)
	}

	var flags []Flag
	if err := cursor.All(ctx, &flags); err != nil {
		return nil, fmt.Errorf("decoding flags: %w", err)
	}
	return flags, nil
}

// SetFlag creates or updates a feature flag using upsert.
func (r *FlagRepo) SetFlag(ctx context.Context, flag *Flag) error {
	now := NowUTC()
	if flag.CreatedAt.IsZero() {
		flag.CreatedAt = now
	}
	flag.ModifiedAt = now
	flag.UpdatedAt = now

	_, err := r.client.Collection("flags").ReplaceOne(ctx,
		bson.M{"flagKey": flag.FlagKey},
		flag,
		options.Replace().SetUpsert(true),
	)
	if err != nil {
		return fmt.Errorf("setting flag: %w", err)
	}
	return nil
}
