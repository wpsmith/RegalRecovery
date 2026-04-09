// internal/repository/affirmations_favorites_repo.go
package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// AddFavorite adds an affirmation to the user's favorites.
// AP-AFF-03: Get user favorites list
func (r *AffirmationsRepo) AddFavorite(ctx context.Context, userID, affirmationID string, tenantID string) error {
	if tenantID == "" {
		tenantID = "DEFAULT"
	}

	favorite := AffirmationFavoriteDoc{
		UserID:        userID,
		TenantID:      tenantID,
		AffirmationID: affirmationID,
		AddedAt:       NowUTC(),
	}

	if _, err := r.favorites.InsertOne(ctx, favorite); err != nil {
		return fmt.Errorf("adding favorite for user %s: %w", userID, err)
	}
	return nil
}

// RemoveFavorite removes an affirmation from the user's favorites.
func (r *AffirmationsRepo) RemoveFavorite(ctx context.Context, userID, affirmationID string) error {
	filter := bson.M{
		"userId":        userID,
		"affirmationId": affirmationID,
	}

	result, err := r.favorites.DeleteOne(ctx, filter)
	if err != nil {
		return fmt.Errorf("removing favorite for user %s: %w", userID, err)
	}

	if result.DeletedCount == 0 {
		return mongo.ErrNoDocuments
	}
	return nil
}

// ListFavorites retrieves all favorited affirmations for a user.
// AP-AFF-03: Get user favorites list
func (r *AffirmationsRepo) ListFavorites(ctx context.Context, userID string) ([]AffirmationFavoriteDoc, error) {
	opts := options.Find().SetSort(bson.D{{Key: "addedAt", Value: -1}})
	cursor, err := r.favorites.Find(ctx, bson.M{"userId": userID}, opts)
	if err != nil {
		return nil, fmt.Errorf("listing favorites for user %s: %w", userID, err)
	}

	var favorites []AffirmationFavoriteDoc
	if err := cursor.All(ctx, &favorites); err != nil {
		return nil, fmt.Errorf("decoding favorites: %w", err)
	}
	return favorites, nil
}

// IsFavorite checks if an affirmation is favorited by a user.
// AP-AFF-04: Check if affirmation is favorited
func (r *AffirmationsRepo) IsFavorite(ctx context.Context, userID, affirmationID string) (bool, error) {
	filter := bson.M{
		"userId":        userID,
		"affirmationId": affirmationID,
	}

	count, err := r.favorites.CountDocuments(ctx, filter)
	if err != nil {
		return false, fmt.Errorf("checking favorite for user %s: %w", userID, err)
	}
	return count > 0, nil
}
