// internal/repository/mongodb/mood_repository.go
package mongodb

import (
	"context"
	"fmt"
	"time"

	"github.com/regalrecovery/api/internal/domain/mood"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

const (
	moodRatingsCollection     = "moodRatings"
	calendarActivitiesCollection = "calendarActivities"
)

// moodDocument is the MongoDB document representation of a MoodEntry.
type moodDocument struct {
	ID             bson.ObjectID `bson:"_id,omitempty"`
	UserID         string        `bson:"userId"`
	TenantID       string        `bson:"tenantId"`
	EntityType     string        `bson:"entityType"`
	MoodID         string        `bson:"moodId"`
	Rating         int           `bson:"rating"`
	EmotionLabels  []string      `bson:"emotionLabels"`
	ContextNote    string        `bson:"contextNote,omitempty"`
	Source         string        `bson:"source"`
	DatePartition  string        `bson:"datePartition"`
	CreatedAt      time.Time     `bson:"createdAt"`
	ModifiedAt     time.Time     `bson:"modifiedAt"`
}

// calendarActivityDocument is the dual-write document.
type calendarActivityDocument struct {
	ID           bson.ObjectID          `bson:"_id,omitempty"`
	UserID       string                 `bson:"userId"`
	TenantID     string                 `bson:"tenantId"`
	EntityType   string                 `bson:"entityType"`
	ActivityType string                 `bson:"activityType"`
	Date         string                 `bson:"date"`
	Timestamp    time.Time              `bson:"timestamp"`
	Summary      map[string]interface{} `bson:"summary"`
	SourceID     string                 `bson:"sourceId"`
}

// MoodMongoRepository implements mood.MoodRepository using MongoDB.
type MoodMongoRepository struct {
	db *mongo.Database
}

// NewMoodMongoRepository creates a new MoodMongoRepository.
func NewMoodMongoRepository(db *mongo.Database) *MoodMongoRepository {
	return &MoodMongoRepository{db: db}
}

// EnsureMoodIndexes creates the required indexes for the moodRatings collection.
func (r *MoodMongoRepository) EnsureMoodIndexes(ctx context.Context) error {
	coll := r.db.Collection(moodRatingsCollection)
	indexes := []mongo.IndexModel{
		{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "createdAt", Value: -1}}},
		{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "rating", Value: 1}, {Key: "createdAt", Value: -1}}},
		{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "emotionLabels", Value: 1}, {Key: "createdAt", Value: -1}}},
		{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "datePartition", Value: 1}}},
		{Keys: bson.D{{Key: "tenantId", Value: 1}}},
		{Keys: bson.D{{Key: "moodId", Value: 1}}, Options: options.Index().SetUnique(true)},
	}

	_, err := coll.Indexes().CreateMany(ctx, indexes)
	return err
}

// Create persists a new mood entry and writes the calendar activity dual-write.
func (r *MoodMongoRepository) Create(ctx context.Context, entry *mood.MoodEntry) error {
	doc := toMoodDocument(entry)
	_, err := r.db.Collection(moodRatingsCollection).InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("inserting mood entry: %w", err)
	}

	// Dual-write to calendarActivities (best-effort).
	calDoc := calendarActivityDocument{
		UserID:       entry.UserID,
		TenantID:     entry.TenantID,
		EntityType:   "CALENDAR_ACTIVITY",
		ActivityType: "MOOD",
		Date:         entry.DatePartition,
		Timestamp:    entry.Timestamp,
		Summary: map[string]interface{}{
			"rating":        entry.Rating,
			"emotionLabels": entry.EmotionLabels,
		},
		SourceID: entry.MoodID,
	}
	_, _ = r.db.Collection(calendarActivitiesCollection).InsertOne(ctx, calDoc)

	return nil
}

// GetByID retrieves a single mood entry by its moodId.
func (r *MoodMongoRepository) GetByID(ctx context.Context, moodID string) (*mood.MoodEntry, error) {
	var doc moodDocument
	err := r.db.Collection(moodRatingsCollection).FindOne(ctx, bson.M{"moodId": moodID}).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, mood.ErrEntryNotFound
		}
		return nil, fmt.Errorf("finding mood entry: %w", err)
	}
	entry := fromMoodDocument(&doc)
	return entry, nil
}

// ListByDateRange retrieves mood entries within a date range with cursor-based pagination.
func (r *MoodMongoRepository) ListByDateRange(ctx context.Context, userID string, start, end time.Time, cursor string, limit int) ([]mood.MoodEntry, string, error) {
	filter := bson.M{
		"userId":    userID,
		"createdAt": bson.M{"$gte": start, "$lte": end},
	}

	if cursor != "" {
		cursorTime, err := time.Parse(time.RFC3339Nano, cursor)
		if err == nil {
			filter["createdAt"] = bson.M{"$gte": start, "$lt": cursorTime}
		}
	}

	opts := options.Find().
		SetSort(bson.D{{Key: "createdAt", Value: -1}}).
		SetLimit(int64(limit + 1))

	cur, err := r.db.Collection(moodRatingsCollection).Find(ctx, filter, opts)
	if err != nil {
		return nil, "", fmt.Errorf("listing mood entries: %w", err)
	}
	defer cur.Close(ctx)

	var docs []moodDocument
	if err := cur.All(ctx, &docs); err != nil {
		return nil, "", fmt.Errorf("decoding mood entries: %w", err)
	}

	hasMore := len(docs) > limit
	if hasMore {
		docs = docs[:limit]
	}

	entries := make([]mood.MoodEntry, len(docs))
	for i, doc := range docs {
		entries[i] = *fromMoodDocument(&doc)
	}

	var nextCursor string
	if hasMore && len(docs) > 0 {
		nextCursor = docs[len(docs)-1].CreatedAt.Format(time.RFC3339Nano)
	}

	return entries, nextCursor, nil
}

// ListByFilters retrieves mood entries matching the given filters.
func (r *MoodMongoRepository) ListByFilters(ctx context.Context, userID string, filters mood.MoodFilters, cursor string, limit int) ([]mood.MoodEntry, string, error) {
	filter := bson.M{"userId": userID}

	if len(filters.Ratings) > 0 {
		filter["rating"] = bson.M{"$in": filters.Ratings}
	}
	if filters.EmotionLabel != "" {
		filter["emotionLabels"] = filters.EmotionLabel
	}
	if filters.Search != "" {
		filter["contextNote"] = bson.M{"$regex": filters.Search, "$options": "i"}
	}
	if filters.StartDate != nil {
		if _, ok := filter["createdAt"]; !ok {
			filter["createdAt"] = bson.M{}
		}
		filter["createdAt"].(bson.M)["$gte"] = *filters.StartDate
	}
	if filters.EndDate != nil {
		if _, ok := filter["createdAt"]; !ok {
			filter["createdAt"] = bson.M{}
		}
		filter["createdAt"].(bson.M)["$lte"] = *filters.EndDate
	}

	if cursor != "" {
		cursorTime, err := time.Parse(time.RFC3339Nano, cursor)
		if err == nil {
			if _, ok := filter["createdAt"]; !ok {
				filter["createdAt"] = bson.M{}
			}
			filter["createdAt"].(bson.M)["$lt"] = cursorTime
		}
	}

	opts := options.Find().
		SetSort(bson.D{{Key: "createdAt", Value: -1}}).
		SetLimit(int64(limit + 1))

	cur, err := r.db.Collection(moodRatingsCollection).Find(ctx, filter, opts)
	if err != nil {
		return nil, "", fmt.Errorf("listing mood entries: %w", err)
	}
	defer cur.Close(ctx)

	var docs []moodDocument
	if err := cur.All(ctx, &docs); err != nil {
		return nil, "", fmt.Errorf("decoding mood entries: %w", err)
	}

	hasMore := len(docs) > limit
	if hasMore {
		docs = docs[:limit]
	}

	entries := make([]mood.MoodEntry, len(docs))
	for i, doc := range docs {
		entries[i] = *fromMoodDocument(&doc)
	}

	var nextCursor string
	if hasMore && len(docs) > 0 {
		nextCursor = docs[len(docs)-1].CreatedAt.Format(time.RFC3339Nano)
	}

	return entries, nextCursor, nil
}

// Update updates a mood entry (must be within 24h of creation).
func (r *MoodMongoRepository) Update(ctx context.Context, moodID string, req mood.UpdateMoodEntryRequest) (*mood.MoodEntry, error) {
	entry, err := r.GetByID(ctx, moodID)
	if err != nil {
		return nil, err
	}

	now := time.Now().UTC()
	if err := entry.ApplyUpdate(req, now); err != nil {
		return nil, err
	}

	updateFields := bson.M{"modifiedAt": now}
	if req.Rating != nil {
		updateFields["rating"] = entry.Rating
	}
	if req.EmotionLabels != nil {
		updateFields["emotionLabels"] = entry.EmotionLabels
	}
	if req.ContextNote != nil {
		updateFields["contextNote"] = entry.ContextNote
	}

	filter := bson.M{
		"moodId":    moodID,
		"createdAt": bson.M{"$gt": now.Add(-24 * time.Hour)},
	}
	update := bson.M{"$set": updateFields}

	result, err := r.db.Collection(moodRatingsCollection).UpdateOne(ctx, filter, update)
	if err != nil {
		return nil, fmt.Errorf("updating mood entry: %w", err)
	}
	if result.MatchedCount == 0 {
		return nil, mood.ErrEntryLocked
	}

	return entry, nil
}

// Delete removes a mood entry (must be within 24h of creation).
func (r *MoodMongoRepository) Delete(ctx context.Context, moodID string) error {
	entry, err := r.GetByID(ctx, moodID)
	if err != nil {
		return err
	}

	now := time.Now().UTC()
	if err := entry.CanDelete(now); err != nil {
		return err
	}

	filter := bson.M{
		"moodId":    moodID,
		"createdAt": bson.M{"$gt": now.Add(-24 * time.Hour)},
	}
	result, err := r.db.Collection(moodRatingsCollection).DeleteOne(ctx, filter)
	if err != nil {
		return fmt.Errorf("deleting mood entry: %w", err)
	}
	if result.DeletedCount == 0 {
		return mood.ErrEntryPermanent
	}

	// Remove calendar activity dual-write (best-effort).
	_, _ = r.db.Collection(calendarActivitiesCollection).DeleteOne(ctx, bson.M{"sourceId": moodID})

	return nil
}

// GetDailySummaries retrieves aggregated daily summaries for a date range.
func (r *MoodMongoRepository) GetDailySummaries(ctx context.Context, userID string, start, end string) ([]mood.DailySummary, error) {
	pipeline := mongo.Pipeline{
		{{Key: "$match", Value: bson.M{
			"userId":        userID,
			"datePartition": bson.M{"$gte": start, "$lte": end},
		}}},
		{{Key: "$group", Value: bson.M{
			"_id":     "$datePartition",
			"avg":     bson.M{"$avg": "$rating"},
			"count":   bson.M{"$sum": 1},
			"highest": bson.M{"$max": "$rating"},
			"lowest":  bson.M{"$min": "$rating"},
		}}},
		{{Key: "$sort", Value: bson.M{"_id": -1}}},
	}

	cur, err := r.db.Collection(moodRatingsCollection).Aggregate(ctx, pipeline)
	if err != nil {
		return nil, fmt.Errorf("aggregating daily summaries: %w", err)
	}
	defer cur.Close(ctx)

	var results []struct {
		Date    string  `bson:"_id"`
		Avg     float64 `bson:"avg"`
		Count   int     `bson:"count"`
		Highest int     `bson:"highest"`
		Lowest  int     `bson:"lowest"`
	}
	if err := cur.All(ctx, &results); err != nil {
		return nil, fmt.Errorf("decoding daily summaries: %w", err)
	}

	summaries := make([]mood.DailySummary, len(results))
	for i, r := range results {
		summaries[i] = mood.DailySummary{
			Date:          r.Date,
			AverageRating: r.Avg,
			ColorCode:     mood.ColorCode(r.Avg),
			EntryCount:    r.Count,
			HighestRating: r.Highest,
			LowestRating:  r.Lowest,
		}
	}

	return summaries, nil
}

// GetHourlyHeatmap retrieves average mood by hour.
func (r *MoodMongoRepository) GetHourlyHeatmap(ctx context.Context, userID string, start, end time.Time) ([]mood.HourBucket, error) {
	pipeline := mongo.Pipeline{
		{{Key: "$match", Value: bson.M{
			"userId":    userID,
			"createdAt": bson.M{"$gte": start, "$lte": end},
		}}},
		{{Key: "$group", Value: bson.M{
			"_id":   bson.M{"$hour": "$createdAt"},
			"avg":   bson.M{"$avg": "$rating"},
			"count": bson.M{"$sum": 1},
		}}},
		{{Key: "$sort", Value: bson.M{"_id": 1}}},
	}

	cur, err := r.db.Collection(moodRatingsCollection).Aggregate(ctx, pipeline)
	if err != nil {
		return nil, fmt.Errorf("aggregating hourly heatmap: %w", err)
	}
	defer cur.Close(ctx)

	var results []struct {
		Hour  int     `bson:"_id"`
		Avg   float64 `bson:"avg"`
		Count int     `bson:"count"`
	}
	if err := cur.All(ctx, &results); err != nil {
		return nil, fmt.Errorf("decoding hourly heatmap: %w", err)
	}

	buckets := make([]mood.HourBucket, len(results))
	for i, r := range results {
		buckets[i] = mood.HourBucket{
			Hour:          r.Hour,
			AverageRating: r.Avg,
			EntryCount:    r.Count,
		}
	}

	return buckets, nil
}

// GetDayOfWeekAverages retrieves average mood by day of week.
func (r *MoodMongoRepository) GetDayOfWeekAverages(ctx context.Context, userID string, start, end time.Time) ([]mood.DayBucket, error) {
	pipeline := mongo.Pipeline{
		{{Key: "$match", Value: bson.M{
			"userId":    userID,
			"createdAt": bson.M{"$gte": start, "$lte": end},
		}}},
		{{Key: "$group", Value: bson.M{
			"_id": bson.M{"$dayOfWeek": "$createdAt"},
			"avg": bson.M{"$avg": "$rating"},
		}}},
		{{Key: "$sort", Value: bson.M{"_id": 1}}},
	}

	cur, err := r.db.Collection(moodRatingsCollection).Aggregate(ctx, pipeline)
	if err != nil {
		return nil, fmt.Errorf("aggregating day-of-week averages: %w", err)
	}
	defer cur.Close(ctx)

	var results []struct {
		DayOfWeek int     `bson:"_id"`
		Avg       float64 `bson:"avg"`
	}
	if err := cur.All(ctx, &results); err != nil {
		return nil, fmt.Errorf("decoding day-of-week averages: %w", err)
	}

	buckets := make([]mood.DayBucket, len(results))
	for i, r := range results {
		// MongoDB $dayOfWeek: 1=Sunday, 7=Saturday. Convert to 0=Sunday, 6=Saturday.
		dow := r.DayOfWeek - 1
		buckets[i] = mood.DayBucket{
			DayOfWeek:     dow,
			DayName:       mood.DayOfWeekName(dow),
			AverageRating: r.Avg,
		}
	}

	return buckets, nil
}

// GetEmotionLabelFrequency retrieves emotion label frequency counts.
func (r *MoodMongoRepository) GetEmotionLabelFrequency(ctx context.Context, userID string, start, end time.Time) ([]mood.LabelCount, error) {
	pipeline := mongo.Pipeline{
		{{Key: "$match", Value: bson.M{
			"userId":    userID,
			"createdAt": bson.M{"$gte": start, "$lte": end},
		}}},
		{{Key: "$unwind", Value: "$emotionLabels"}},
		{{Key: "$group", Value: bson.M{
			"_id":   "$emotionLabels",
			"count": bson.M{"$sum": 1},
		}}},
		{{Key: "$sort", Value: bson.M{"count": -1}}},
	}

	cur, err := r.db.Collection(moodRatingsCollection).Aggregate(ctx, pipeline)
	if err != nil {
		return nil, fmt.Errorf("aggregating emotion label frequency: %w", err)
	}
	defer cur.Close(ctx)

	var results []struct {
		Label string `bson:"_id"`
		Count int    `bson:"count"`
	}
	if err := cur.All(ctx, &results); err != nil {
		return nil, fmt.Errorf("decoding emotion label frequency: %w", err)
	}

	labels := make([]mood.LabelCount, len(results))
	for i, r := range results {
		labels[i] = mood.LabelCount{
			Label: r.Label,
			Count: r.Count,
		}
	}

	return labels, nil
}

// GetTodayEntries retrieves all mood entries for a given date partition.
func (r *MoodMongoRepository) GetTodayEntries(ctx context.Context, userID string, datePartition string) ([]mood.MoodEntry, error) {
	filter := bson.M{
		"userId":        userID,
		"datePartition": datePartition,
	}
	opts := options.Find().SetSort(bson.D{{Key: "createdAt", Value: 1}})

	cur, err := r.db.Collection(moodRatingsCollection).Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("getting today's entries: %w", err)
	}
	defer cur.Close(ctx)

	var docs []moodDocument
	if err := cur.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding today's entries: %w", err)
	}

	entries := make([]mood.MoodEntry, len(docs))
	for i, doc := range docs {
		entries[i] = *fromMoodDocument(&doc)
	}

	return entries, nil
}

// SearchByKeyword searches mood entries by keyword in context notes.
func (r *MoodMongoRepository) SearchByKeyword(ctx context.Context, userID string, keyword string, cursor string, limit int) ([]mood.MoodEntry, string, error) {
	filter := bson.M{
		"userId":      userID,
		"contextNote": bson.M{"$regex": keyword, "$options": "i"},
	}

	if cursor != "" {
		cursorTime, err := time.Parse(time.RFC3339Nano, cursor)
		if err == nil {
			filter["createdAt"] = bson.M{"$lt": cursorTime}
		}
	}

	opts := options.Find().
		SetSort(bson.D{{Key: "createdAt", Value: -1}}).
		SetLimit(int64(limit + 1))

	cur, err := r.db.Collection(moodRatingsCollection).Find(ctx, filter, opts)
	if err != nil {
		return nil, "", fmt.Errorf("searching mood entries: %w", err)
	}
	defer cur.Close(ctx)

	var docs []moodDocument
	if err := cur.All(ctx, &docs); err != nil {
		return nil, "", fmt.Errorf("decoding searched entries: %w", err)
	}

	hasMore := len(docs) > limit
	if hasMore {
		docs = docs[:limit]
	}

	entries := make([]mood.MoodEntry, len(docs))
	for i, doc := range docs {
		entries[i] = *fromMoodDocument(&doc)
	}

	var nextCursor string
	if hasMore && len(docs) > 0 {
		nextCursor = docs[len(docs)-1].CreatedAt.Format(time.RFC3339Nano)
	}

	return entries, nextCursor, nil
}

// CountConsecutiveLowDays counts recent consecutive days with avg <= 2.0.
func (r *MoodMongoRepository) CountConsecutiveLowDays(ctx context.Context, userID string) (int, error) {
	// Get daily averages for last 30 days.
	end := time.Now().UTC().Format("2006-01-02")
	start := time.Now().UTC().AddDate(0, 0, -30).Format("2006-01-02")

	summaries, err := r.GetDailySummaries(ctx, userID, start, end)
	if err != nil {
		return 0, err
	}

	// Summaries are sorted most recent first.
	avgs := make([]float64, len(summaries))
	for i, s := range summaries {
		avgs[i] = s.AverageRating
	}

	count, _ := mood.EvaluateSustainedLowMood(avgs)
	return count, nil
}

// GetDistinctEntryDates returns distinct datePartition values for a user.
func (r *MoodMongoRepository) GetDistinctEntryDates(ctx context.Context, userID string) ([]string, error) {
	pipeline := mongo.Pipeline{
		{{Key: "$match", Value: bson.M{"userId": userID}}},
		{{Key: "$group", Value: bson.M{"_id": "$datePartition"}}},
		{{Key: "$sort", Value: bson.M{"_id": 1}}},
	}

	cur, err := r.db.Collection(moodRatingsCollection).Aggregate(ctx, pipeline)
	if err != nil {
		return nil, fmt.Errorf("getting distinct entry dates: %w", err)
	}
	defer cur.Close(ctx)

	var results []struct {
		Date string `bson:"_id"`
	}
	if err := cur.All(ctx, &results); err != nil {
		return nil, fmt.Errorf("decoding distinct entry dates: %w", err)
	}

	dates := make([]string, len(results))
	for i, r := range results {
		dates[i] = r.Date
	}

	return dates, nil
}

// GetLastCrisisEntry retrieves the most recent crisis-level entry.
func (r *MoodMongoRepository) GetLastCrisisEntry(ctx context.Context, userID string) (*mood.MoodEntry, error) {
	filter := bson.M{
		"userId": userID,
		"rating": 1,
	}
	opts := options.FindOne().SetSort(bson.D{{Key: "createdAt", Value: -1}})

	var doc moodDocument
	err := r.db.Collection(moodRatingsCollection).FindOne(ctx, filter, opts).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, fmt.Errorf("finding last crisis entry: %w", err)
	}

	return fromMoodDocument(&doc), nil
}

// toMoodDocument converts a domain MoodEntry to a MongoDB document.
func toMoodDocument(entry *mood.MoodEntry) moodDocument {
	return moodDocument{
		UserID:        entry.UserID,
		TenantID:      entry.TenantID,
		EntityType:    "MOOD",
		MoodID:        entry.MoodID,
		Rating:        entry.Rating,
		EmotionLabels: entry.EmotionLabels,
		ContextNote:   entry.ContextNote,
		Source:        entry.Source,
		DatePartition: entry.DatePartition,
		CreatedAt:     entry.CreatedAt,
		ModifiedAt:    entry.ModifiedAt,
	}
}

// fromMoodDocument converts a MongoDB document to a domain MoodEntry.
func fromMoodDocument(doc *moodDocument) *mood.MoodEntry {
	return &mood.MoodEntry{
		MoodID:         doc.MoodID,
		UserID:         doc.UserID,
		TenantID:       doc.TenantID,
		Rating:         doc.Rating,
		RatingLabel:    mood.LabelForRating(doc.Rating),
		EmotionLabels:  doc.EmotionLabels,
		ContextNote:    doc.ContextNote,
		Source:         doc.Source,
		DatePartition:  doc.DatePartition,
		CrisisPrompted: doc.Rating == 1,
		Timestamp:      doc.CreatedAt,
		CreatedAt:      doc.CreatedAt,
		ModifiedAt:     doc.ModifiedAt,
	}
}
