// internal/repository/exercise_favorite_repo.go
package repository

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/regalrecovery/api/internal/domain/exercise"
	"go.mongodb.org/mongo-driver/v2/bson"
)

const exerciseFavoriteCollection = "exerciseFavorites"

// ExerciseFavoriteDoc is the MongoDB document for an exercise favorite.
type ExerciseFavoriteDoc struct {
	BaseDocument `bson:",inline"`

	FavoriteID             string  `bson:"favoriteId"`
	UserID                 string  `bson:"userId"`
	EntityType             string  `bson:"entityType"`
	ActivityType           string  `bson:"activityType"`
	CustomTypeLabel        *string `bson:"customTypeLabel,omitempty"`
	DefaultDurationMinutes int     `bson:"defaultDurationMinutes"`
	DefaultIntensity       *string `bson:"defaultIntensity,omitempty"`
	Label                  string  `bson:"label"`
	SortOrder              int     `bson:"sortOrder"`
}

// ExerciseFavoriteRepo implements exercise.FavoriteRepository using MongoDB.
type ExerciseFavoriteRepo struct {
	client *MongoClient
}

// NewExerciseFavoriteRepo creates a new ExerciseFavoriteRepo.
func NewExerciseFavoriteRepo(client *MongoClient) *ExerciseFavoriteRepo {
	return &ExerciseFavoriteRepo{client: client}
}

func (r *ExerciseFavoriteRepo) collection() string {
	return exerciseFavoriteCollection
}

// Create stores a new exercise favorite.
func (r *ExerciseFavoriteRepo) Create(ctx context.Context, fav exercise.ExerciseFavorite) error {
	doc := ExerciseFavoriteDoc{
		BaseDocument: BaseDocument{
			CreatedAt:  fav.CreatedAt,
			ModifiedAt: fav.ModifiedAt,
			TenantID:   fav.TenantID,
		},
		FavoriteID:             fav.FavoriteID,
		UserID:                 fav.UserID,
		EntityType:             "EXERCISE_FAVORITE",
		ActivityType:           fav.ActivityType,
		CustomTypeLabel:        fav.CustomTypeLabel,
		DefaultDurationMinutes: fav.DefaultDurationMinutes,
		DefaultIntensity:       fav.DefaultIntensity,
		Label:                  fav.Label,
		SortOrder:              fav.SortOrder,
	}

	coll := r.client.database.Collection(r.collection())
	_, err := coll.InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("inserting exercise favorite: %w", err)
	}
	return nil
}

// List retrieves all favorites for a user.
func (r *ExerciseFavoriteRepo) List(ctx context.Context, userID string) ([]exercise.ExerciseFavorite, error) {
	coll := r.client.database.Collection(r.collection())

	filter := bson.M{
		"userId":     userID,
		"entityType": "EXERCISE_FAVORITE",
	}

	cursor, err := coll.Find(ctx, filter, nil)
	if err != nil {
		return nil, fmt.Errorf("finding exercise favorites: %w", err)
	}
	defer cursor.Close(ctx)

	var docs []ExerciseFavoriteDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding exercise favorites: %w", err)
	}

	favs := make([]exercise.ExerciseFavorite, len(docs))
	for i, doc := range docs {
		favs[i] = docToExerciseFavorite(doc)
	}
	return favs, nil
}

// Update replaces a favorite.
func (r *ExerciseFavoriteRepo) Update(ctx context.Context, userID, favoriteID string, fav exercise.ExerciseFavorite) error {
	coll := r.client.database.Collection(r.collection())

	filter := bson.M{
		"userId":     userID,
		"favoriteId": favoriteID,
		"entityType": "EXERCISE_FAVORITE",
	}

	update := bson.M{"$set": bson.M{
		"activityType":           fav.ActivityType,
		"customTypeLabel":        fav.CustomTypeLabel,
		"defaultDurationMinutes": fav.DefaultDurationMinutes,
		"defaultIntensity":       fav.DefaultIntensity,
		"label":                  fav.Label,
		"modifiedAt":             time.Now().UTC(),
	}}

	result, err := coll.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("updating exercise favorite: %w", err)
	}
	if result.MatchedCount == 0 {
		return exercise.ErrFavoriteNotFound
	}
	return nil
}

// Delete removes a favorite.
func (r *ExerciseFavoriteRepo) Delete(ctx context.Context, userID, favoriteID string) error {
	coll := r.client.database.Collection(r.collection())

	filter := bson.M{
		"userId":     userID,
		"favoriteId": favoriteID,
		"entityType": "EXERCISE_FAVORITE",
	}

	result, err := coll.DeleteOne(ctx, filter)
	if err != nil {
		return fmt.Errorf("deleting exercise favorite: %w", err)
	}
	if result.DeletedCount == 0 {
		return exercise.ErrFavoriteNotFound
	}
	return nil
}

// Count returns the number of favorites for a user.
func (r *ExerciseFavoriteRepo) Count(ctx context.Context, userID string) (int, error) {
	coll := r.client.database.Collection(r.collection())

	filter := bson.M{
		"userId":     userID,
		"entityType": "EXERCISE_FAVORITE",
	}

	count, err := coll.CountDocuments(ctx, filter)
	if err != nil {
		if strings.Contains(err.Error(), "no documents") {
			return 0, nil
		}
		return 0, fmt.Errorf("counting exercise favorites: %w", err)
	}
	return int(count), nil
}

func docToExerciseFavorite(doc ExerciseFavoriteDoc) exercise.ExerciseFavorite {
	return exercise.ExerciseFavorite{
		FavoriteID:             doc.FavoriteID,
		UserID:                 doc.UserID,
		TenantID:               doc.TenantID,
		ActivityType:           doc.ActivityType,
		CustomTypeLabel:        doc.CustomTypeLabel,
		DefaultDurationMinutes: doc.DefaultDurationMinutes,
		DefaultIntensity:       doc.DefaultIntensity,
		Label:                  doc.Label,
		SortOrder:              doc.SortOrder,
		CreatedAt:              doc.CreatedAt,
		ModifiedAt:             doc.ModifiedAt,
	}
}
