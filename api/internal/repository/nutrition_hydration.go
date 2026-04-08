// internal/repository/nutrition_hydration.go
package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/regalrecovery/api/internal/domain/nutrition"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// NutritionHydrationRepository implements nutrition.HydrationRepository using MongoDB.
type NutritionHydrationRepository struct {
	collection *mongo.Collection
}

// NewNutritionHydrationRepository creates a new NutritionHydrationRepository.
func NewNutritionHydrationRepository(db *mongo.Database) *NutritionHydrationRepository {
	return &NutritionHydrationRepository{
		collection: db.Collection("hydrationLogs"),
	}
}

// GetHydrationLog retrieves the hydration log for a user on a specific date.
func (r *NutritionHydrationRepository) GetHydrationLog(ctx context.Context, userID, date string) (*nutrition.HydrationLog, error) {
	filter := bson.M{
		"PK": fmt.Sprintf("USER#%s", userID),
		"SK": fmt.Sprintf("HYDRATION#%s", date),
	}

	var doc bson.M
	err := r.collection.FindOne(ctx, filter).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, err
	}

	return decodeHydrationLog(doc), nil
}

// UpsertHydrationLog creates or updates a daily hydration log.
func (r *NutritionHydrationRepository) UpsertHydrationLog(ctx context.Context, log *nutrition.HydrationLog) error {
	filter := bson.M{
		"PK": fmt.Sprintf("USER#%s", log.UserID),
		"SK": fmt.Sprintf("HYDRATION#%s", log.Date),
	}

	// Convert entries to BSON array.
	entries := make([]bson.M, 0, len(log.Entries))
	for _, e := range log.Entries {
		entries = append(entries, bson.M{
			"timestamp": e.Timestamp,
			"servings":  e.Servings,
			"action":    string(e.Action),
		})
	}

	update := bson.M{
		"$set": bson.M{
			"EntityType":          "HYDRATION",
			"TenantId":            log.TenantID,
			"ModifiedAt":          log.ModifiedAt,
			"date":                log.Date,
			"servingsLogged":      log.ServingsLogged,
			"servingSizeOz":       log.ServingSizeOz,
			"totalOunces":         log.TotalOunces,
			"dailyTargetServings": log.DailyTargetServings,
			"goalMet":             log.GoalMet,
			"goalProgressPercent": log.GoalProgressPercent,
			"entries":             entries,
		},
		"$setOnInsert": bson.M{
			"CreatedAt": log.CreatedAt,
		},
	}

	opts := options.UpdateOne().SetUpsert(true)
	_, err := r.collection.UpdateOne(ctx, filter, update, opts)
	return err
}

// GetHydrationHistory retrieves daily hydration data for a date range.
func (r *NutritionHydrationRepository) GetHydrationHistory(ctx context.Context, userID, startDate, endDate string) ([]nutrition.HydrationLog, error) {
	filter := bson.M{
		"PK": fmt.Sprintf("USER#%s", userID),
		"SK": bson.M{
			"$gte": fmt.Sprintf("HYDRATION#%s", startDate),
			"$lte": fmt.Sprintf("HYDRATION#%s", endDate),
		},
	}

	opts := options.Find().SetSort(bson.M{"SK": 1})
	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var results []bson.M
	if err := cursor.All(ctx, &results); err != nil {
		return nil, err
	}

	logs := make([]nutrition.HydrationLog, 0, len(results))
	for _, doc := range results {
		logs = append(logs, *decodeHydrationLog(doc))
	}

	return logs, nil
}

func decodeHydrationLog(doc bson.M) *nutrition.HydrationLog {
	log := &nutrition.HydrationLog{}

	if v, ok := doc["date"].(string); ok {
		log.Date = v
	}
	if v, ok := doc["servingsLogged"].(int32); ok {
		log.ServingsLogged = int(v)
	}
	if v, ok := doc["servingSizeOz"].(float64); ok {
		log.ServingSizeOz = v
	}
	if v, ok := doc["totalOunces"].(float64); ok {
		log.TotalOunces = v
	}
	if v, ok := doc["dailyTargetServings"].(int32); ok {
		log.DailyTargetServings = int(v)
	}
	if v, ok := doc["goalMet"].(bool); ok {
		log.GoalMet = v
	}
	if v, ok := doc["goalProgressPercent"].(int32); ok {
		log.GoalProgressPercent = int(v)
	}
	if v, ok := doc["CreatedAt"].(time.Time); ok {
		log.CreatedAt = v
	}
	if v, ok := doc["ModifiedAt"].(time.Time); ok {
		log.ModifiedAt = v
	}

	return log
}
