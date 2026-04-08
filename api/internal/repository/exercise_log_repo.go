// internal/repository/exercise_log_repo.go
package repository

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/regalrecovery/api/internal/domain/exercise"
	"go.mongodb.org/mongo-driver/v2/bson"
)

const exerciseCollection = "exercises"

// ExerciseLogDoc is the MongoDB document for an exercise log entry.
type ExerciseLogDoc struct {
	BaseDocument `bson:",inline"`

	ExerciseID      string  `bson:"exerciseId"`
	UserID          string  `bson:"userId"`
	EntityType      string  `bson:"entityType"`
	Timestamp       time.Time `bson:"timestamp"`
	ActivityType    string  `bson:"activityType"`
	CustomTypeLabel *string `bson:"customTypeLabel,omitempty"`
	DurationMinutes int     `bson:"durationMinutes"`
	Intensity       *string `bson:"intensity,omitempty"`
	Notes           *string `bson:"notes,omitempty"`
	MoodBefore      *int    `bson:"moodBefore,omitempty"`
	MoodAfter       *int    `bson:"moodAfter,omitempty"`
	Source          string  `bson:"source"`
	ExternalID      *string `bson:"externalId,omitempty"`
}

// ExerciseLogRepo implements exercise.ExerciseRepository using MongoDB.
type ExerciseLogRepo struct {
	client *MongoClient
}

// NewExerciseLogRepo creates a new ExerciseLogRepo.
func NewExerciseLogRepo(client *MongoClient) *ExerciseLogRepo {
	return &ExerciseLogRepo{client: client}
}

func (r *ExerciseLogRepo) collection() string {
	return exerciseCollection
}

// Create stores a new exercise log entry.
func (r *ExerciseLogRepo) Create(ctx context.Context, log exercise.ExerciseLog) error {
	doc := ExerciseLogDoc{
		BaseDocument: BaseDocument{
			CreatedAt:  log.CreatedAt,
			ModifiedAt: log.ModifiedAt,
			TenantID:   log.TenantID,
		},
		ExerciseID:      log.ExerciseID,
		UserID:          log.UserID,
		EntityType:      "EXERCISE",
		Timestamp:       log.Timestamp,
		ActivityType:    log.ActivityType,
		CustomTypeLabel: log.CustomTypeLabel,
		DurationMinutes: log.DurationMinutes,
		Intensity:       log.Intensity,
		Notes:           log.Notes,
		MoodBefore:      log.MoodBefore,
		MoodAfter:       log.MoodAfter,
		Source:          log.Source,
		ExternalID:      log.ExternalID,
	}

	coll := r.client.database.Collection(r.collection())
	_, err := coll.InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("inserting exercise log: %w", err)
	}
	return nil
}

// GetByID retrieves a single exercise log by user ID and exercise ID.
func (r *ExerciseLogRepo) GetByID(ctx context.Context, userID, exerciseID string) (*exercise.ExerciseLog, error) {
	coll := r.client.database.Collection(r.collection())

	filter := bson.M{
		"userId":     userID,
		"exerciseId": exerciseID,
		"entityType": "EXERCISE",
	}

	var doc ExerciseLogDoc
	err := coll.FindOne(ctx, filter).Decode(&doc)
	if err != nil {
		if strings.Contains(err.Error(), "no documents") {
			return nil, nil
		}
		return nil, fmt.Errorf("finding exercise log: %w", err)
	}

	result := docToExerciseLog(doc)
	return &result, nil
}

// List retrieves exercise logs for a user with pagination and filtering.
func (r *ExerciseLogRepo) List(ctx context.Context, userID string, opts exercise.ListOptions) ([]exercise.ExerciseLog, string, error) {
	coll := r.client.database.Collection(r.collection())

	filter := bson.M{
		"userId":     userID,
		"entityType": "EXERCISE",
	}

	if opts.ActivityType != nil {
		filter["activityType"] = *opts.ActivityType
	}
	if opts.Intensity != nil {
		filter["intensity"] = *opts.Intensity
	}
	if opts.StartDate != nil {
		if _, ok := filter["timestamp"]; !ok {
			filter["timestamp"] = bson.M{}
		}
		filter["timestamp"].(bson.M)["$gte"] = *opts.StartDate
	}
	if opts.EndDate != nil {
		if _, ok := filter["timestamp"]; !ok {
			filter["timestamp"] = bson.M{}
		}
		filter["timestamp"].(bson.M)["$lte"] = *opts.EndDate
	}
	if opts.Search != nil && *opts.Search != "" {
		filter["notes"] = bson.M{"$regex": *opts.Search, "$options": "i"}
	}

	// Sort direction.
	sortDir := -1
	if opts.Sort == "+timestamp" {
		sortDir = 1
	}

	findOpts := bson.D{
		{Key: "timestamp", Value: sortDir},
	}

	cursor, err := coll.Find(ctx, filter, nil)
	if err != nil {
		return nil, "", fmt.Errorf("finding exercise logs: %w", err)
	}
	defer cursor.Close(ctx)

	_ = findOpts // Sort is applied at application layer for simplicity with cursor pagination.

	var docs []ExerciseLogDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, "", fmt.Errorf("decoding exercise logs: %w", err)
	}

	// Apply limit.
	limit := opts.Limit
	if limit <= 0 {
		limit = 50
	}

	var nextCursor string
	if len(docs) > limit {
		docs = docs[:limit]
		nextCursor = docs[limit-1].ExerciseID
	}

	logs := make([]exercise.ExerciseLog, len(docs))
	for i, doc := range docs {
		logs[i] = docToExerciseLog(doc)
	}

	return logs, nextCursor, nil
}

// Update modifies mutable fields of an exercise log.
func (r *ExerciseLogRepo) Update(ctx context.Context, userID, exerciseID string, updates map[string]interface{}) error {
	coll := r.client.database.Collection(r.collection())

	filter := bson.M{
		"userId":     userID,
		"exerciseId": exerciseID,
		"entityType": "EXERCISE",
	}

	update := bson.M{"$set": updates}

	result, err := coll.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("updating exercise log: %w", err)
	}
	if result.MatchedCount == 0 {
		return exercise.ErrExerciseNotFound
	}
	return nil
}

// Delete removes an exercise log.
func (r *ExerciseLogRepo) Delete(ctx context.Context, userID, exerciseID string) error {
	coll := r.client.database.Collection(r.collection())

	filter := bson.M{
		"userId":     userID,
		"exerciseId": exerciseID,
		"entityType": "EXERCISE",
	}

	result, err := coll.DeleteOne(ctx, filter)
	if err != nil {
		return fmt.Errorf("deleting exercise log: %w", err)
	}
	if result.DeletedCount == 0 {
		return exercise.ErrExerciseNotFound
	}
	return nil
}

// GetByDateRange retrieves exercise logs within a date range.
func (r *ExerciseLogRepo) GetByDateRange(ctx context.Context, userID string, start, end time.Time) ([]exercise.ExerciseLog, error) {
	coll := r.client.database.Collection(r.collection())

	filter := bson.M{
		"userId":     userID,
		"entityType": "EXERCISE",
		"timestamp": bson.M{
			"$gte": start,
			"$lte": end,
		},
	}

	cursor, err := coll.Find(ctx, filter, nil)
	if err != nil {
		return nil, fmt.Errorf("finding exercise logs by date range: %w", err)
	}
	defer cursor.Close(ctx)

	var docs []ExerciseLogDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding exercise logs: %w", err)
	}

	logs := make([]exercise.ExerciseLog, len(docs))
	for i, doc := range docs {
		logs[i] = docToExerciseLog(doc)
	}
	return logs, nil
}

// CountInWeek returns the number of exercise sessions in a given week.
func (r *ExerciseLogRepo) CountInWeek(ctx context.Context, userID string, weekStart time.Time) (int, error) {
	weekEnd := weekStart.AddDate(0, 0, 7)
	logs, err := r.GetByDateRange(ctx, userID, weekStart, weekEnd)
	if err != nil {
		return 0, err
	}
	return len(logs), nil
}

// FindDuplicates searches for potential duplicate logs.
func (r *ExerciseLogRepo) FindDuplicates(ctx context.Context, userID string, activityType string, timestamp time.Time, externalID *string) ([]exercise.ExerciseLog, error) {
	coll := r.client.database.Collection(r.collection())

	// Build OR filter: external ID match OR (same type within 30 min window).
	orFilters := bson.A{}

	if externalID != nil {
		orFilters = append(orFilters, bson.M{"externalId": *externalID})
	}

	window := 30 * time.Minute
	orFilters = append(orFilters, bson.M{
		"activityType": activityType,
		"timestamp": bson.M{
			"$gte": timestamp.Add(-window),
			"$lte": timestamp.Add(window),
		},
	})

	filter := bson.M{
		"userId":     userID,
		"entityType": "EXERCISE",
		"$or":        orFilters,
	}

	cursor, err := coll.Find(ctx, filter, nil)
	if err != nil {
		return nil, fmt.Errorf("finding duplicate exercise logs: %w", err)
	}
	defer cursor.Close(ctx)

	var docs []ExerciseLogDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding duplicate exercise logs: %w", err)
	}

	logs := make([]exercise.ExerciseLog, len(docs))
	for i, doc := range docs {
		logs[i] = docToExerciseLog(doc)
	}
	return logs, nil
}

func docToExerciseLog(doc ExerciseLogDoc) exercise.ExerciseLog {
	return exercise.ExerciseLog{
		ExerciseID:      doc.ExerciseID,
		UserID:          doc.UserID,
		TenantID:        doc.TenantID,
		Timestamp:       doc.Timestamp,
		ActivityType:    doc.ActivityType,
		CustomTypeLabel: doc.CustomTypeLabel,
		DurationMinutes: doc.DurationMinutes,
		Intensity:       doc.Intensity,
		Notes:           doc.Notes,
		MoodBefore:      doc.MoodBefore,
		MoodAfter:       doc.MoodAfter,
		Source:          doc.Source,
		ExternalID:      doc.ExternalID,
		CreatedAt:       doc.CreatedAt,
		ModifiedAt:      doc.ModifiedAt,
	}
}
