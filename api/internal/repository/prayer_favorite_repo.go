// internal/repository/prayer_favorite_repo.go
package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"

	"github.com/regalrecovery/api/internal/domain/prayer"
)

// PrayerFavoriteDoc is the MongoDB document for a prayer favorite.
type PrayerFavoriteDoc struct {
	BaseDocument `bson:",inline"`

	PK           string  `bson:"PK"`
	SK           string  `bson:"SK"`
	EntityType   string  `bson:"entityType"`
	PrayerID     string  `bson:"prayerId"`
	PrayerSource string  `bson:"prayerSource"` // "library" or "personal"
	Title        string  `bson:"title"`
	PackID       *string `bson:"packId,omitempty"`
}

// MongoPrayerFavoriteRepo implements FavoriteRepository using MongoDB.
type MongoPrayerFavoriteRepo struct {
	collection *mongo.Collection
}

// NewMongoPrayerFavoriteRepo creates a new MongoPrayerFavoriteRepo.
func NewMongoPrayerFavoriteRepo(db *mongo.Database) *MongoPrayerFavoriteRepo {
	return &MongoPrayerFavoriteRepo{
		collection: db.Collection("main"),
	}
}

// Add adds a prayer to favorites.
func (r *MongoPrayerFavoriteRepo) Add(ctx context.Context, fav *prayer.PrayerFavorite) error {
	doc := PrayerFavoriteDoc{
		BaseDocument: BaseDocument{
			CreatedAt:  fav.CreatedAt,
			ModifiedAt: fav.CreatedAt,
			TenantID:   "DEFAULT",
		},
		PK:           "USER#" + fav.UserID,
		SK:           "PRAYER_FAV#" + fav.PrayerID,
		EntityType:   "PRAYER_FAVORITE",
		PrayerID:     fav.PrayerID,
		PrayerSource: fav.PrayerSource,
		Title:        fav.Title,
		PackID:       fav.PackID,
	}

	_, err := r.collection.InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("inserting prayer favorite: %w", err)
	}
	return nil
}

// Remove removes a prayer from favorites.
func (r *MongoPrayerFavoriteRepo) Remove(ctx context.Context, userID, prayerID string) error {
	filter := bson.M{
		"PK": "USER#" + userID,
		"SK": "PRAYER_FAV#" + prayerID,
	}

	_, err := r.collection.DeleteOne(ctx, filter)
	if err != nil {
		return fmt.Errorf("removing prayer favorite: %w", err)
	}
	return nil
}

// List lists favorite prayers with cursor-based pagination.
func (r *MongoPrayerFavoriteRepo) List(ctx context.Context, userID string, cursor string, limit int) ([]prayer.PrayerFavorite, string, error) {
	filter := bson.M{
		"PK":         "USER#" + userID,
		"entityType": "PRAYER_FAVORITE",
	}

	if cursor != "" {
		filter["SK"] = bson.M{"$gt": cursor}
	}

	opts := options.Find().
		SetSort(bson.D{{Key: "createdAt", Value: -1}}).
		SetLimit(int64(limit + 1))

	cur, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, "", fmt.Errorf("listing prayer favorites: %w", err)
	}
	defer cur.Close(ctx)

	var docs []PrayerFavoriteDoc
	if err := cur.All(ctx, &docs); err != nil {
		return nil, "", fmt.Errorf("decoding prayer favorites: %w", err)
	}

	var favorites []prayer.PrayerFavorite
	var nextCursor string
	for i, doc := range docs {
		if i >= limit {
			nextCursor = doc.SK
			break
		}
		favorites = append(favorites, prayer.PrayerFavorite{
			UserID:       doc.PK[5:], // Strip "USER#" prefix.
			PrayerID:     doc.PrayerID,
			PrayerSource: doc.PrayerSource,
			Title:        doc.Title,
			PackID:       doc.PackID,
			CreatedAt:    doc.CreatedAt,
		})
	}

	return favorites, nextCursor, nil
}

// Exists checks if a prayer is already favorited.
func (r *MongoPrayerFavoriteRepo) Exists(ctx context.Context, userID, prayerID string) (bool, error) {
	filter := bson.M{
		"PK": "USER#" + userID,
		"SK": "PRAYER_FAV#" + prayerID,
	}

	count, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return false, fmt.Errorf("checking prayer favorite existence: %w", err)
	}
	return count > 0, nil
}
