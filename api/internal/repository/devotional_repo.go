// internal/repository/devotional_repo.go
package repository

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"

	"github.com/regalrecovery/api/internal/domain/devotionals"
)

// DevotionalContentRepo implements DevotionalContentRepository using MongoDB.
type DevotionalContentRepo struct {
	client *MongoClient
}

// NewDevotionalContentRepo creates a new DevotionalContentRepo.
func NewDevotionalContentRepo(client *MongoClient) *DevotionalContentRepo {
	return &DevotionalContentRepo{client: client}
}

func (r *DevotionalContentRepo) collection() *mongo.Collection {
	return r.client.Collection("devotionals_content")
}

// GetByID retrieves a devotional by its ID.
func (r *DevotionalContentRepo) GetByID(ctx context.Context, devotionalID string) (*devotionals.DevotionalContent, error) {
	var doc devotionals.DevotionalContent
	err := r.collection().FindOne(ctx, bson.M{"devotionalId": devotionalID, "isPublished": true}).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, fmt.Errorf("getting devotional %s: %w", devotionalID, err)
	}
	return &doc, nil
}

// GetByFreemiumDay retrieves the devotional for a given day in the 30-day free rotation.
func (r *DevotionalContentRepo) GetByFreemiumDay(ctx context.Context, day int) (*devotionals.DevotionalContent, error) {
	var doc devotionals.DevotionalContent
	err := r.collection().FindOne(ctx, bson.M{
		"tier":               "free",
		"freemiumRotationDay": day,
		"isPublished":        true,
	}).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, fmt.Errorf("getting freemium devotional for day %d: %w", day, err)
	}
	return &doc, nil
}

// GetBySeriesAndDay retrieves a devotional for a specific series and day.
func (r *DevotionalContentRepo) GetBySeriesAndDay(ctx context.Context, seriesID string, day int) (*devotionals.DevotionalContent, error) {
	var doc devotionals.DevotionalContent
	err := r.collection().FindOne(ctx, bson.M{
		"seriesId":    seriesID,
		"seriesDay":   day,
		"isPublished": true,
	}).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, fmt.Errorf("getting series %s day %d: %w", seriesID, day, err)
	}
	return &doc, nil
}

// List retrieves paginated devotionals with optional filters.
func (r *DevotionalContentRepo) List(ctx context.Context, params devotionals.ListDevotionalsParams) ([]devotionals.DevotionalContent, string, error) {
	filter := bson.M{"isPublished": true}
	if params.Topic != nil {
		filter["topic"] = string(*params.Topic)
	}
	if params.Author != nil {
		filter["authorName"] = *params.Author
	}
	if params.SeriesID != nil {
		filter["seriesId"] = *params.SeriesID
	}
	if params.Tier != nil {
		filter["tier"] = string(*params.Tier)
	}

	if params.Search != nil && *params.Search != "" {
		filter["$text"] = bson.M{"$search": *params.Search}
	}

	limit := params.Limit
	if limit <= 0 {
		limit = 20
	}

	opts := options.Find().SetLimit(int64(limit + 1)).SetSort(bson.D{{Key: "createdAt", Value: -1}})

	cursor, err := r.collection().Find(ctx, filter, opts)
	if err != nil {
		return nil, "", fmt.Errorf("listing devotionals: %w", err)
	}

	var docs []devotionals.DevotionalContent
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, "", fmt.Errorf("decoding devotionals: %w", err)
	}

	var nextCursor string
	if len(docs) > limit {
		docs = docs[:limit]
		nextCursor = docs[limit-1].DevotionalID
	}

	return docs, nextCursor, nil
}

// Search performs full-text search across devotional content.
func (r *DevotionalContentRepo) Search(ctx context.Context, query string, limit int) ([]devotionals.DevotionalContent, error) {
	filter := bson.M{
		"$text":       bson.M{"$search": query},
		"isPublished": true,
	}
	opts := options.Find().SetLimit(int64(limit))

	cursor, err := r.collection().Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("searching devotionals: %w", err)
	}

	var docs []devotionals.DevotionalContent
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding search results: %w", err)
	}
	return docs, nil
}

// --- Completion Repository ---

// DevotionalCompletionRepo implements DevotionalCompletionRepository.
type DevotionalCompletionRepo struct {
	client *MongoClient
}

// NewDevotionalCompletionRepo creates a new DevotionalCompletionRepo.
func NewDevotionalCompletionRepo(client *MongoClient) *DevotionalCompletionRepo {
	return &DevotionalCompletionRepo{client: client}
}

func (r *DevotionalCompletionRepo) userCollection() *mongo.Collection {
	return r.client.Collection("user_entities")
}

func (r *DevotionalCompletionRepo) activityCollection() *mongo.Collection {
	return r.client.Collection("activities")
}

// Save persists a new devotional completion and writes the calendar activity entry (dual-write).
func (r *DevotionalCompletionRepo) Save(ctx context.Context, userID string, completion *devotionals.CompletionDoc) error {
	if _, err := r.userCollection().InsertOne(ctx, completion); err != nil {
		return fmt.Errorf("inserting completion: %w", err)
	}

	// Calendar dual-write (AC-DEV-INTEG-02)
	activityDoc := bson.M{
		"userId":       userID,
		"date":         completion.CreatedAt.Format("2006-01-02"),
		"activityType": "DEVOTIONAL",
		"timestamp":    completion.CreatedAt,
		"tenantId":     completion.TenantID,
		"createdAt":    time.Now().UTC(),
		"modifiedAt":   time.Now().UTC(),
		"summary": bson.M{
			"devotionalTitle":    completion.DevotionalTitle,
			"scriptureReference": completion.ScriptureReference,
			"hasReflection":      completion.Reflection != nil,
			"moodTag":            completion.MoodTag,
		},
		"sourceKey": completion.SK,
	}
	if _, err := r.activityCollection().InsertOne(ctx, activityDoc); err != nil {
		return fmt.Errorf("inserting calendar activity: %w", err)
	}

	return nil
}

// GetByID retrieves a completion by its ID.
func (r *DevotionalCompletionRepo) GetByID(ctx context.Context, userID, completionID string) (*devotionals.CompletionDoc, error) {
	var doc devotionals.CompletionDoc
	err := r.userCollection().FindOne(ctx, bson.M{
		"PK":           fmt.Sprintf("USER#%s", userID),
		"EntityType":   "DEVOTIONAL",
		"completionId": completionID,
	}).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, fmt.Errorf("getting completion %s: %w", completionID, err)
	}
	return &doc, nil
}

// Update updates the mutable fields of a completion.
func (r *DevotionalCompletionRepo) Update(ctx context.Context, userID string, completion *devotionals.CompletionDoc) error {
	_, err := r.userCollection().UpdateOne(ctx,
		bson.M{
			"PK":           completion.PK,
			"SK":           completion.SK,
			"completionId": completion.CompletionID,
		},
		bson.M{
			"$set": bson.M{
				"reflection": completion.Reflection,
				"moodTag":    completion.MoodTag,
				"ModifiedAt": completion.ModifiedAt,
			},
		},
	)
	if err != nil {
		return fmt.Errorf("updating completion: %w", err)
	}
	return nil
}

// GetByDevotionalAndDate checks if a completion exists for a devotional on a given date.
func (r *DevotionalCompletionRepo) GetByDevotionalAndDate(ctx context.Context, userID, devotionalID, date string) (*devotionals.CompletionDoc, error) {
	var doc devotionals.CompletionDoc
	err := r.userCollection().FindOne(ctx, bson.M{
		"PK":           fmt.Sprintf("USER#%s", userID),
		"EntityType":   "DEVOTIONAL",
		"devotionalId": devotionalID,
		"SK":           bson.M{"$regex": fmt.Sprintf("^DEVOTIONAL#%s", date)},
	}).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, fmt.Errorf("checking duplicate completion: %w", err)
	}
	return &doc, nil
}

// ListByDateRange retrieves completions within a date range.
func (r *DevotionalCompletionRepo) ListByDateRange(ctx context.Context, userID string, params devotionals.ListHistoryParams) ([]devotionals.CompletionDoc, string, error) {
	filter := bson.M{
		"PK":         fmt.Sprintf("USER#%s", userID),
		"EntityType": "DEVOTIONAL",
	}

	if params.StartDate != nil || params.EndDate != nil {
		skFilter := bson.M{}
		if params.StartDate != nil {
			skFilter["$gte"] = fmt.Sprintf("DEVOTIONAL#%sT00:00:00Z", *params.StartDate)
		}
		if params.EndDate != nil {
			skFilter["$lte"] = fmt.Sprintf("DEVOTIONAL#%sT23:59:59Z", *params.EndDate)
		}
		filter["SK"] = skFilter
	}

	if params.Topic != nil {
		filter["topic"] = string(*params.Topic)
	}
	if params.SearchReflections != nil {
		filter["reflection"] = bson.M{"$regex": *params.SearchReflections, "$options": "i"}
	}

	sortDir := -1
	if params.Sort == "+timestamp" {
		sortDir = 1
	}

	limit := params.Limit
	if limit <= 0 {
		limit = 20
	}

	opts := options.Find().SetLimit(int64(limit + 1)).SetSort(bson.D{{Key: "SK", Value: sortDir}})

	cursor, err := r.userCollection().Find(ctx, filter, opts)
	if err != nil {
		return nil, "", fmt.Errorf("listing history: %w", err)
	}

	var docs []devotionals.CompletionDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, "", fmt.Errorf("decoding history: %w", err)
	}

	var nextCursor string
	if len(docs) > limit {
		docs = docs[:limit]
		nextCursor = docs[limit-1].CompletionID
	}

	return docs, nextCursor, nil
}

// --- Favorite Repository ---

// DevotionalFavoriteRepo implements DevotionalFavoriteRepository.
type DevotionalFavoriteRepo struct {
	client *MongoClient
}

// NewDevotionalFavoriteRepo creates a new DevotionalFavoriteRepo.
func NewDevotionalFavoriteRepo(client *MongoClient) *DevotionalFavoriteRepo {
	return &DevotionalFavoriteRepo{client: client}
}

func (r *DevotionalFavoriteRepo) collection() *mongo.Collection {
	return r.client.Collection("user_entities")
}

// Add adds a devotional to favorites. Idempotent via upsert.
func (r *DevotionalFavoriteRepo) Add(ctx context.Context, userID string, favorite *devotionals.FavoriteDoc) error {
	opts := options.Replace().SetUpsert(true)
	_, err := r.collection().ReplaceOne(ctx,
		bson.M{"PK": favorite.PK, "SK": favorite.SK},
		favorite,
		opts,
	)
	if err != nil {
		return fmt.Errorf("adding favorite: %w", err)
	}
	return nil
}

// Remove removes a devotional from favorites.
func (r *DevotionalFavoriteRepo) Remove(ctx context.Context, userID, devotionalID string) error {
	_, err := r.collection().DeleteOne(ctx, bson.M{
		"PK": fmt.Sprintf("USER#%s", userID),
		"SK": fmt.Sprintf("DEVFAV#%s", devotionalID),
	})
	if err != nil {
		return fmt.Errorf("removing favorite: %w", err)
	}
	return nil
}

// List retrieves the user's favorite devotionals.
func (r *DevotionalFavoriteRepo) List(ctx context.Context, userID, cursor string, limit int) ([]devotionals.FavoriteDoc, string, error) {
	filter := bson.M{
		"PK":         fmt.Sprintf("USER#%s", userID),
		"EntityType": "DEVOTIONAL_FAVORITE",
	}

	opts := options.Find().SetLimit(int64(limit + 1)).SetSort(bson.D{{Key: "CreatedAt", Value: -1}})

	cur, err := r.collection().Find(ctx, filter, opts)
	if err != nil {
		return nil, "", fmt.Errorf("listing favorites: %w", err)
	}

	var docs []devotionals.FavoriteDoc
	if err := cur.All(ctx, &docs); err != nil {
		return nil, "", fmt.Errorf("decoding favorites: %w", err)
	}

	var nextCursor string
	if len(docs) > limit {
		docs = docs[:limit]
		nextCursor = docs[limit-1].DevotionalID
	}

	return docs, nextCursor, nil
}

// IsFavorite checks if a devotional is in the user's favorites.
func (r *DevotionalFavoriteRepo) IsFavorite(ctx context.Context, userID, devotionalID string) (bool, error) {
	count, err := r.collection().CountDocuments(ctx, bson.M{
		"PK": fmt.Sprintf("USER#%s", userID),
		"SK": fmt.Sprintf("DEVFAV#%s", devotionalID),
	})
	if err != nil {
		return false, fmt.Errorf("checking favorite: %w", err)
	}
	return count > 0, nil
}

// --- Series Progress Repository ---

// SeriesProgressRepo implements SeriesProgressRepository.
type SeriesProgressRepo struct {
	client *MongoClient
}

// NewSeriesProgressRepo creates a new SeriesProgressRepo.
func NewSeriesProgressRepo(client *MongoClient) *SeriesProgressRepo {
	return &SeriesProgressRepo{client: client}
}

func (r *SeriesProgressRepo) collection() *mongo.Collection {
	return r.client.Collection("user_entities")
}

// Get retrieves the user's progress for a specific series.
func (r *SeriesProgressRepo) Get(ctx context.Context, userID, seriesID string) (*devotionals.SeriesProgressDoc, error) {
	var doc devotionals.SeriesProgressDoc
	err := r.collection().FindOne(ctx, bson.M{
		"PK": fmt.Sprintf("USER#%s", userID),
		"SK": fmt.Sprintf("DEVSERIES#%s", seriesID),
	}).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, fmt.Errorf("getting series progress: %w", err)
	}
	return &doc, nil
}

// GetActive retrieves the user's currently active series progress.
func (r *SeriesProgressRepo) GetActive(ctx context.Context, userID string) (*devotionals.SeriesProgressDoc, error) {
	var doc devotionals.SeriesProgressDoc
	err := r.collection().FindOne(ctx, bson.M{
		"PK":         fmt.Sprintf("USER#%s", userID),
		"EntityType": "DEVOTIONAL_SERIES_PROGRESS",
		"status":     "active",
	}).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, fmt.Errorf("getting active series: %w", err)
	}
	return &doc, nil
}

// Upsert creates or updates series progress.
func (r *SeriesProgressRepo) Upsert(ctx context.Context, userID string, progress *devotionals.SeriesProgressDoc) error {
	opts := options.Replace().SetUpsert(true)
	_, err := r.collection().ReplaceOne(ctx,
		bson.M{"PK": progress.PK, "SK": progress.SK},
		progress,
		opts,
	)
	if err != nil {
		return fmt.Errorf("upserting series progress: %w", err)
	}
	return nil
}

// ListAll retrieves all series progress for a user.
func (r *SeriesProgressRepo) ListAll(ctx context.Context, userID string) ([]devotionals.SeriesProgressDoc, error) {
	cursor, err := r.collection().Find(ctx, bson.M{
		"PK":         fmt.Sprintf("USER#%s", userID),
		"EntityType": "DEVOTIONAL_SERIES_PROGRESS",
	})
	if err != nil {
		return nil, fmt.Errorf("listing series progress: %w", err)
	}

	var docs []devotionals.SeriesProgressDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding series progress: %w", err)
	}
	return docs, nil
}

// --- Series Metadata Repository ---

// DevotionalSeriesRepo implements DevotionalSeriesRepository.
type DevotionalSeriesRepo struct {
	client *MongoClient
}

// NewDevotionalSeriesRepo creates a new DevotionalSeriesRepo.
func NewDevotionalSeriesRepo(client *MongoClient) *DevotionalSeriesRepo {
	return &DevotionalSeriesRepo{client: client}
}

func (r *DevotionalSeriesRepo) collection() *mongo.Collection {
	return r.client.Collection("devotional_series")
}

// GetByID retrieves a series by its ID.
func (r *DevotionalSeriesRepo) GetByID(ctx context.Context, seriesID string) (*devotionals.SeriesContent, error) {
	var doc devotionals.SeriesContent
	err := r.collection().FindOne(ctx, bson.M{"seriesId": seriesID, "isPublished": true}).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, fmt.Errorf("getting series %s: %w", seriesID, err)
	}
	return &doc, nil
}

// List retrieves available series with optional tier filter.
func (r *DevotionalSeriesRepo) List(ctx context.Context, tier *devotionals.ContentTier, cursor string, limit int) ([]devotionals.SeriesContent, string, error) {
	filter := bson.M{"isPublished": true}
	if tier != nil {
		filter["tier"] = string(*tier)
	}

	opts := options.Find().SetLimit(int64(limit + 1)).SetSort(bson.D{{Key: "createdAt", Value: -1}})

	cur, err := r.collection().Find(ctx, filter, opts)
	if err != nil {
		return nil, "", fmt.Errorf("listing series: %w", err)
	}

	var docs []devotionals.SeriesContent
	if err := cur.All(ctx, &docs); err != nil {
		return nil, "", fmt.Errorf("decoding series: %w", err)
	}

	var nextCursor string
	if len(docs) > limit {
		docs = docs[:limit]
		nextCursor = docs[limit-1].SeriesID
	}

	return docs, nextCursor, nil
}

// --- Streak Repository ---

// DevotionalStreakRepo implements DevotionalStreakRepository.
type DevotionalStreakRepo struct {
	client *MongoClient
}

// NewDevotionalStreakRepo creates a new DevotionalStreakRepo.
func NewDevotionalStreakRepo(client *MongoClient) *DevotionalStreakRepo {
	return &DevotionalStreakRepo{client: client}
}

func (r *DevotionalStreakRepo) collection() *mongo.Collection {
	return r.client.Collection("user_entities")
}

// Get retrieves the user's devotional streak.
func (r *DevotionalStreakRepo) Get(ctx context.Context, userID string) (*devotionals.StreakDoc, error) {
	var doc devotionals.StreakDoc
	err := r.collection().FindOne(ctx, bson.M{
		"PK": fmt.Sprintf("USER#%s", userID),
		"SK": "DEVSTREAK",
	}).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("streak not found")
		}
		return nil, fmt.Errorf("getting streak: %w", err)
	}
	return &doc, nil
}

// Upsert creates or updates the streak record.
func (r *DevotionalStreakRepo) Upsert(ctx context.Context, userID string, streak *devotionals.StreakDoc) error {
	opts := options.Replace().SetUpsert(true)
	_, err := r.collection().ReplaceOne(ctx,
		bson.M{"PK": streak.PK, "SK": streak.SK},
		streak,
		opts,
	)
	if err != nil {
		return fmt.Errorf("upserting streak: %w", err)
	}
	return nil
}
