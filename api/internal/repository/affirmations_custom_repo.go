// internal/repository/affirmations_custom_repo.go
package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// CreateCustom creates a new custom affirmation.
// AP-AFF-07: Get custom affirmations for user
func (r *AffirmationsRepo) CreateCustom(ctx context.Context, custom *AffirmationCustomDoc) error {
	SetBaseDocumentDefaults(&custom.BaseDocument)
	custom.UpdatedAt = custom.CreatedAt

	if _, err := r.custom.InsertOne(ctx, custom); err != nil {
		return fmt.Errorf("creating custom affirmation: %w", err)
	}
	return nil
}

// GetCustom retrieves a custom affirmation by ID.
func (r *AffirmationsRepo) GetCustom(ctx context.Context, customID string) (*AffirmationCustomDoc, error) {
	var custom AffirmationCustomDoc
	err := r.custom.FindOne(ctx, bson.M{"customId": customID}).Decode(&custom)
	if err != nil {
		return nil, fmt.Errorf("getting custom affirmation %s: %w", customID, err)
	}
	return &custom, nil
}

// ListCustom retrieves all custom affirmations for a user, sorted newest first.
// AP-AFF-07: Get custom affirmations for user
func (r *AffirmationsRepo) ListCustom(ctx context.Context, userID string) ([]AffirmationCustomDoc, error) {
	opts := options.Find().SetSort(bson.D{{Key: "createdAt", Value: -1}})
	cursor, err := r.custom.Find(ctx, bson.M{"userId": userID}, opts)
	if err != nil {
		return nil, fmt.Errorf("listing custom affirmations for user %s: %w", userID, err)
	}

	var customs []AffirmationCustomDoc
	if err := cursor.All(ctx, &customs); err != nil {
		return nil, fmt.Errorf("decoding custom affirmations: %w", err)
	}
	return customs, nil
}

// UpdateCustom updates an existing custom affirmation.
func (r *AffirmationsRepo) UpdateCustom(ctx context.Context, custom *AffirmationCustomDoc) error {
	custom.UpdatedAt = NowUTC()
	UpdateModified(&custom.BaseDocument)

	filter := bson.M{"customId": custom.CustomID}
	update := bson.M{"$set": custom}

	result, err := r.custom.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("updating custom affirmation %s: %w", custom.CustomID, err)
	}

	if result.MatchedCount == 0 {
		return mongo.ErrNoDocuments
	}
	return nil
}

// DeleteCustom deletes a custom affirmation by ID.
func (r *AffirmationsRepo) DeleteCustom(ctx context.Context, customID string) error {
	result, err := r.custom.DeleteOne(ctx, bson.M{"customId": customID})
	if err != nil {
		return fmt.Errorf("deleting custom affirmation %s: %w", customID, err)
	}

	if result.DeletedCount == 0 {
		return mongo.ErrNoDocuments
	}
	return nil
}

// ToggleRotation toggles whether a custom affirmation is included in daily rotation.
func (r *AffirmationsRepo) ToggleRotation(ctx context.Context, customID string, includeInRotation bool) error {
	filter := bson.M{"customId": customID}
	update := bson.M{
		"$set": bson.M{
			"includeInRotation": includeInRotation,
			"updatedAt":         NowUTC(),
			"modifiedAt":        NowUTC(),
		},
	}

	result, err := r.custom.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("toggling rotation for custom affirmation %s: %w", customID, err)
	}

	if result.MatchedCount == 0 {
		return mongo.ErrNoDocuments
	}
	return nil
}
