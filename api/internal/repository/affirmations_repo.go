// internal/repository/affirmations_repo.go
package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// AffirmationsRepo implements AffirmationsRepository using MongoDB.
type AffirmationsRepo struct {
	library    *mongo.Collection
	sessions   *mongo.Collection
	settings   *mongo.Collection
	progress   *mongo.Collection
	favorites  *mongo.Collection
	hidden     *mongo.Collection
	custom     *mongo.Collection
	audio      *mongo.Collection
	activities *mongo.Collection
}

// NewAffirmationsRepo creates a new AffirmationsRepo.
func NewAffirmationsRepo(client *MongoClient) *AffirmationsRepo {
	return &AffirmationsRepo{
		library:    client.Collection("affirmationsLibrary"),
		sessions:   client.Collection("affirmationSessions"),
		settings:   client.Collection("affirmationSettings"),
		progress:   client.Collection("affirmationProgress"),
		favorites:  client.Collection("affirmationFavorites"),
		hidden:     client.Collection("affirmationHidden"),
		custom:     client.Collection("affirmationCustom"),
		audio:      client.Collection("affirmationAudioRecordings"),
		activities: client.Collection("activities"),
	}
}

// --- Library affirmations ---

// GetLibraryAffirmations retrieves library affirmations by level, category, track, and active status.
// AP-AFF-01: Get library affirmations by level + category + track
func (r *AffirmationsRepo) GetLibraryAffirmations(ctx context.Context, level int, category, track string, active bool, limit int) ([]AffirmationLibraryDoc, error) {
	filter := bson.M{
		"active": active,
	}
	if level > 0 {
		filter["level"] = level
	}
	if category != "" {
		filter["category"] = category
	}
	if track != "" {
		filter["track"] = track
	}

	opts := options.Find().SetLimit(int64(limit))
	cursor, err := r.library.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("querying library affirmations: %w", err)
	}

	var docs []AffirmationLibraryDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding library affirmations: %w", err)
	}
	return docs, nil
}

// GetLibraryAffirmationByID retrieves a single library affirmation by ID.
func (r *AffirmationsRepo) GetLibraryAffirmationByID(ctx context.Context, affirmationID string) (*AffirmationLibraryDoc, error) {
	var doc AffirmationLibraryDoc
	err := r.library.FindOne(ctx, bson.M{"affirmationId": affirmationID}).Decode(&doc)
	if err != nil {
		return nil, fmt.Errorf("getting library affirmation %s: %w", affirmationID, err)
	}
	return &doc, nil
}

// SearchLibraryAffirmations performs a full-text search on library affirmations.
// AP-AFF-02: Search library by keyword
func (r *AffirmationsRepo) SearchLibraryAffirmations(ctx context.Context, keyword string, active bool, limit int) ([]AffirmationLibraryDoc, error) {
	filter := bson.M{
		"$text":  bson.M{"$search": keyword},
		"active": active,
	}

	opts := options.Find().SetLimit(int64(limit))
	cursor, err := r.library.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("searching library affirmations: %w", err)
	}

	var docs []AffirmationLibraryDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding search results: %w", err)
	}
	return docs, nil
}

// WriteCalendarActivity writes a calendar activity entry for affirmation sessions.
// AP-AFF-21: Calendar activity dual-write
func (r *AffirmationsRepo) WriteCalendarActivity(ctx context.Context, activity *Activity) error {
	SetBaseDocumentDefaults(&activity.BaseDocument)

	if _, err := r.activities.InsertOne(ctx, activity); err != nil {
		return fmt.Errorf("writing calendar activity: %w", err)
	}
	return nil
}
