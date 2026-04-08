// internal/repository/library_prayer_repo.go
package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"

	"github.com/regalrecovery/api/internal/domain/prayer"
)

// LibraryPrayerDoc is the MongoDB document for a library prayer content item.
type LibraryPrayerDoc struct {
	BaseDocument `bson:",inline"`

	PK                  string   `bson:"PK"`
	SK                  string   `bson:"SK"`
	EntityType          string   `bson:"entityType"`
	PrayerID            string   `bson:"prayerId"`
	Title               string   `bson:"title"`
	Body                string   `bson:"body"`
	TopicTags           []string `bson:"topicTags,omitempty"`
	SourceAttribution   string   `bson:"sourceAttribution"`
	ScriptureConnection *string  `bson:"scriptureConnection,omitempty"`
	StepNumber          *int     `bson:"stepNumber,omitempty"`
	Tier                string   `bson:"tier"`
	Language            string   `bson:"language"`
}

// MongoLibraryPrayerRepo implements LibraryPrayerRepository using MongoDB.
type MongoLibraryPrayerRepo struct {
	collection *mongo.Collection
}

// NewMongoLibraryPrayerRepo creates a new MongoLibraryPrayerRepo.
func NewMongoLibraryPrayerRepo(db *mongo.Database) *MongoLibraryPrayerRepo {
	return &MongoLibraryPrayerRepo{
		collection: db.Collection("main"),
	}
}

// List lists library prayers with filtering and cursor-based pagination.
func (r *MongoLibraryPrayerRepo) List(ctx context.Context, packID, topic *string, step *int, search *string, tier *string, cursor string, limit int) ([]prayer.LibraryPrayer, string, error) {
	filter := bson.M{
		"entityType": "PRAYER_CONTENT",
	}

	// Filter by pack (PR-AC2.3).
	if packID != nil {
		filter["PK"] = "PACK#" + *packID
	}

	// Filter by topic (PR-AC2.2).
	if topic != nil {
		filter["topicTags"] = *topic
	}

	// Filter by step (PR-AC2.4).
	if step != nil {
		filter["stepNumber"] = *step
	}

	// Filter by tier.
	if tier != nil && *tier != "all" {
		filter["tier"] = *tier
	}

	// Full-text search (PR-AC2.5) -- uses Atlas Search if available.
	if search != nil && *search != "" {
		filter["$or"] = bson.A{
			bson.M{"title": bson.M{"$regex": *search, "$options": "i"}},
			bson.M{"body": bson.M{"$regex": *search, "$options": "i"}},
		}
	}

	if cursor != "" {
		filter["SK"] = bson.M{"$gt": cursor}
	}

	opts := options.Find().
		SetSort(bson.D{{Key: "PK", Value: 1}, {Key: "SK", Value: 1}}).
		SetLimit(int64(limit + 1))

	cur, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, "", fmt.Errorf("listing library prayers: %w", err)
	}
	defer cur.Close(ctx)

	var docs []LibraryPrayerDoc
	if err := cur.All(ctx, &docs); err != nil {
		return nil, "", fmt.Errorf("decoding library prayers: %w", err)
	}

	var prayers []prayer.LibraryPrayer
	var nextCursor string
	for i, doc := range docs {
		if i >= limit {
			nextCursor = doc.SK
			break
		}
		lp := docToLibraryPrayer(&doc)
		// Pack name derived from PK (strip "PACK#" prefix).
		if len(doc.PK) > 5 {
			lp.PackID = doc.PK[5:]
		}
		prayers = append(prayers, *lp)
	}

	return prayers, nextCursor, nil
}

// Get retrieves a single library prayer by ID.
func (r *MongoLibraryPrayerRepo) Get(ctx context.Context, prayerID string) (*prayer.LibraryPrayer, error) {
	filter := bson.M{
		"entityType": "PRAYER_CONTENT",
		"prayerId":   prayerID,
	}

	var doc LibraryPrayerDoc
	err := r.collection.FindOne(ctx, filter).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, fmt.Errorf("finding library prayer: %w", err)
	}

	lp := docToLibraryPrayer(&doc)
	if len(doc.PK) > 5 {
		lp.PackID = doc.PK[5:]
	}
	return lp, nil
}

// GetTodayPrayer returns today's featured prayer (PR-AC2.7).
// Rotates based on day of year, drawn from owned packs.
func (r *MongoLibraryPrayerRepo) GetTodayPrayer(ctx context.Context, ownedPackIDs []string, dayOfYear int) (*prayer.LibraryPrayer, error) {
	if len(ownedPackIDs) == 0 {
		// Fall back to free packs.
		ownedPackIDs = []string{"pack_core", "pack_step_prayers"}
	}

	// Build pack PK filter.
	packPKs := make(bson.A, len(ownedPackIDs))
	for i, id := range ownedPackIDs {
		packPKs[i] = "PACK#" + id
	}

	filter := bson.M{
		"entityType": "PRAYER_CONTENT",
		"PK":         bson.M{"$in": packPKs},
	}

	opts := options.Find().SetSort(bson.D{{Key: "PK", Value: 1}, {Key: "SK", Value: 1}})

	cur, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("getting today's prayer candidates: %w", err)
	}
	defer cur.Close(ctx)

	var docs []LibraryPrayerDoc
	if err := cur.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding today's prayer candidates: %w", err)
	}

	if len(docs) == 0 {
		return nil, nil
	}

	// Select based on day of year modulo count for deterministic daily rotation.
	idx := dayOfYear % len(docs)
	doc := docs[idx]
	lp := docToLibraryPrayer(&doc)
	if len(doc.PK) > 5 {
		lp.PackID = doc.PK[5:]
	}
	return lp, nil
}

func docToLibraryPrayer(doc *LibraryPrayerDoc) *prayer.LibraryPrayer {
	return &prayer.LibraryPrayer{
		ID:                  doc.PrayerID,
		Title:               doc.Title,
		Body:                doc.Body,
		TopicTags:           doc.TopicTags,
		SourceAttribution:   doc.SourceAttribution,
		ScriptureConnection: doc.ScriptureConnection,
		StepNumber:          doc.StepNumber,
		Tier:                doc.Tier,
		Language:            doc.Language,
	}
}
