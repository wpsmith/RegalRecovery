// internal/repository/personal_prayer_repo.go
package repository

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"

	"github.com/regalrecovery/api/internal/domain/prayer"
)

// PersonalPrayerDoc is the MongoDB document for a personal prayer.
type PersonalPrayerDoc struct {
	BaseDocument `bson:",inline"`

	PK                 string   `bson:"PK"`
	SK                 string   `bson:"SK"`
	EntityType         string   `bson:"entityType"`
	PersonalPrayerID   string   `bson:"personalPrayerId"`
	UserID             string   `bson:"userId"`
	Title              string   `bson:"title"`
	Body               string   `bson:"body"`
	TopicTags          []string `bson:"topicTags,omitempty"`
	ScriptureReference *string  `bson:"scriptureReference,omitempty"`
	SortOrder          int      `bson:"sortOrder"`
	IsFavorite         bool     `bson:"isFavorite"`
}

// MongoPersonalPrayerRepo implements PersonalPrayerRepository using MongoDB.
type MongoPersonalPrayerRepo struct {
	collection *mongo.Collection
}

// NewMongoPersonalPrayerRepo creates a new MongoPersonalPrayerRepo.
func NewMongoPersonalPrayerRepo(db *mongo.Database) *MongoPersonalPrayerRepo {
	return &MongoPersonalPrayerRepo{
		collection: db.Collection("main"),
	}
}

// Create creates a personal prayer document.
func (r *MongoPersonalPrayerRepo) Create(ctx context.Context, pp *prayer.PersonalPrayer) error {
	doc := PersonalPrayerDoc{
		BaseDocument: BaseDocument{
			CreatedAt:  pp.CreatedAt,
			ModifiedAt: pp.ModifiedAt,
			TenantID:   "DEFAULT",
		},
		PK:                 "USER#" + pp.UserID,
		SK:                 "PERSONAL_PRAYER#" + pp.ID,
		EntityType:         "PERSONAL_PRAYER",
		PersonalPrayerID:   pp.ID,
		UserID:             pp.UserID,
		Title:              pp.Title,
		Body:               pp.Body,
		TopicTags:          pp.TopicTags,
		ScriptureReference: pp.ScriptureReference,
		SortOrder:          pp.SortOrder,
		IsFavorite:         pp.IsFavorite,
	}

	_, err := r.collection.InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("inserting personal prayer: %w", err)
	}
	return nil
}

// Get retrieves a personal prayer by user ID and prayer ID.
func (r *MongoPersonalPrayerRepo) Get(ctx context.Context, userID, prayerID string) (*prayer.PersonalPrayer, error) {
	filter := bson.M{
		"entityType":       "PERSONAL_PRAYER",
		"personalPrayerId": prayerID,
	}
	// If userID is provided, scope to user.
	if userID != "" {
		filter["PK"] = "USER#" + userID
	}

	var doc PersonalPrayerDoc
	err := r.collection.FindOne(ctx, filter).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, fmt.Errorf("finding personal prayer: %w", err)
	}

	return docToPersonalPrayer(&doc), nil
}

// List lists personal prayers for a user with cursor-based pagination.
func (r *MongoPersonalPrayerRepo) List(ctx context.Context, userID string, cursor string, limit int) ([]prayer.PersonalPrayer, string, error) {
	filter := bson.M{
		"PK":         "USER#" + userID,
		"entityType": "PERSONAL_PRAYER",
	}

	if cursor != "" {
		filter["SK"] = bson.M{"$gt": cursor}
	}

	opts := options.Find().
		SetSort(bson.D{{Key: "sortOrder", Value: 1}, {Key: "createdAt", Value: -1}}).
		SetLimit(int64(limit + 1))

	cur, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, "", fmt.Errorf("listing personal prayers: %w", err)
	}
	defer cur.Close(ctx)

	var docs []PersonalPrayerDoc
	if err := cur.All(ctx, &docs); err != nil {
		return nil, "", fmt.Errorf("decoding personal prayers: %w", err)
	}

	var prayers []prayer.PersonalPrayer
	var nextCursor string
	for i, doc := range docs {
		if i >= limit {
			nextCursor = doc.SK
			break
		}
		prayers = append(prayers, *docToPersonalPrayer(&doc))
	}

	return prayers, nextCursor, nil
}

// Update updates a personal prayer document.
func (r *MongoPersonalPrayerRepo) Update(ctx context.Context, pp *prayer.PersonalPrayer) error {
	filter := bson.M{
		"PK":               "USER#" + pp.UserID,
		"personalPrayerId": pp.ID,
	}

	update := bson.M{
		"$set": bson.M{
			"title":              pp.Title,
			"body":               pp.Body,
			"topicTags":          pp.TopicTags,
			"scriptureReference": pp.ScriptureReference,
			"modifiedAt":         pp.ModifiedAt,
		},
	}

	_, err := r.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("updating personal prayer: %w", err)
	}
	return nil
}

// Delete deletes a personal prayer document.
func (r *MongoPersonalPrayerRepo) Delete(ctx context.Context, userID, prayerID string) error {
	filter := bson.M{
		"PK":               "USER#" + userID,
		"personalPrayerId": prayerID,
	}

	_, err := r.collection.DeleteOne(ctx, filter)
	if err != nil {
		return fmt.Errorf("deleting personal prayer: %w", err)
	}

	// PR-AC3.5: Update linked prayer sessions to show "[Deleted Prayer]".
	_, _ = r.collection.UpdateMany(ctx,
		bson.M{
			"PK":             "USER#" + userID,
			"entityType":     "PRAYER_SESSION",
			"linkedPrayerId": prayerID,
		},
		bson.M{
			"$set": bson.M{
				"linkedPrayerTitle": prayer.DeletedPrayerTitle,
				"modifiedAt":        time.Now().UTC(),
			},
		},
	)

	return nil
}

// Reorder updates the sort order of personal prayers (PR-AC3.6).
func (r *MongoPersonalPrayerRepo) Reorder(ctx context.Context, userID string, prayerIDs []string) error {
	for i, id := range prayerIDs {
		filter := bson.M{
			"PK":               "USER#" + userID,
			"personalPrayerId": id,
		}
		update := bson.M{
			"$set": bson.M{
				"sortOrder":  i + 1,
				"modifiedAt": time.Now().UTC(),
			},
		}
		_, err := r.collection.UpdateOne(ctx, filter, update)
		if err != nil {
			return fmt.Errorf("reordering personal prayer %s: %w", id, err)
		}
	}
	return nil
}

// Count returns the number of personal prayers for a user.
func (r *MongoPersonalPrayerRepo) Count(ctx context.Context, userID string) (int, error) {
	filter := bson.M{
		"PK":         "USER#" + userID,
		"entityType": "PERSONAL_PRAYER",
	}

	count, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return 0, fmt.Errorf("counting personal prayers: %w", err)
	}
	return int(count), nil
}

func docToPersonalPrayer(doc *PersonalPrayerDoc) *prayer.PersonalPrayer {
	return &prayer.PersonalPrayer{
		ID:                 doc.PersonalPrayerID,
		UserID:             doc.UserID,
		Title:              doc.Title,
		Body:               doc.Body,
		TopicTags:          doc.TopicTags,
		ScriptureReference: doc.ScriptureReference,
		IsFavorite:         doc.IsFavorite,
		SortOrder:          doc.SortOrder,
		CreatedAt:          doc.CreatedAt,
		ModifiedAt:         doc.ModifiedAt,
	}
}
