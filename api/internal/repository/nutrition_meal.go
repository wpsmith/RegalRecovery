// internal/repository/nutrition_meal.go
package repository

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/regalrecovery/api/internal/domain/nutrition"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// NutritionMealRepository implements nutrition.MealRepository using MongoDB.
type NutritionMealRepository struct {
	collection *mongo.Collection
}

// NewNutritionMealRepository creates a new NutritionMealRepository.
func NewNutritionMealRepository(db *mongo.Database) *NutritionMealRepository {
	return &NutritionMealRepository{
		collection: db.Collection("mealLogs"),
	}
}

// CreateMealLog inserts a new meal log document.
func (r *NutritionMealRepository) CreateMealLog(ctx context.Context, meal *nutrition.MealLog) error {
	doc := bson.M{
		"PK":               fmt.Sprintf("USER#%s", meal.UserID),
		"SK":               fmt.Sprintf("MEAL#%s", meal.Timestamp.Format(time.RFC3339)),
		"EntityType":       "MEAL",
		"TenantId":         meal.TenantID,
		"CreatedAt":        meal.CreatedAt,
		"ModifiedAt":       meal.ModifiedAt,
		"mealId":           meal.MealID,
		"mealType":         meal.MealType,
		"customMealLabel":  meal.CustomMealLabel,
		"description":      meal.Description,
		"eatingContext":     meal.EatingContext,
		"moodBefore":       meal.MoodBefore,
		"moodAfter":        meal.MoodAfter,
		"mindfulnessCheck": meal.MindfulnessCheck,
		"notes":            meal.Notes,
		"isQuickLog":       meal.IsQuickLog,
	}

	_, err := r.collection.InsertOne(ctx, doc)
	return err
}

// GetMealLog retrieves a meal log by user ID and meal ID.
func (r *NutritionMealRepository) GetMealLog(ctx context.Context, userID, mealID string) (*nutrition.MealLog, error) {
	filter := bson.M{
		"PK":     fmt.Sprintf("USER#%s", userID),
		"mealId": mealID,
	}

	var doc bson.M
	err := r.collection.FindOne(ctx, filter).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, err
	}

	return decodeMealLog(doc), nil
}

// ListMealLogs retrieves meal logs with filtering and cursor-based pagination.
func (r *NutritionMealRepository) ListMealLogs(ctx context.Context, userID string, filter nutrition.MealListFilter) ([]nutrition.MealLog, string, error) {
	mongoFilter := bson.M{
		"PK": fmt.Sprintf("USER#%s", userID),
	}

	if filter.MealType != nil {
		types := strings.Split(*filter.MealType, ",")
		mongoFilter["mealType"] = bson.M{"$in": types}
	}
	if filter.EatingContext != nil {
		mongoFilter["eatingContext"] = *filter.EatingContext
	}
	if filter.MoodBefore != nil {
		vals := parseMoodValues(*filter.MoodBefore)
		if len(vals) > 0 {
			mongoFilter["moodBefore"] = bson.M{"$in": vals}
		}
	}
	if filter.MoodAfter != nil {
		vals := parseMoodValues(*filter.MoodAfter)
		if len(vals) > 0 {
			mongoFilter["moodAfter"] = bson.M{"$in": vals}
		}
	}
	if filter.MindfulnessCheck != nil {
		mongoFilter["mindfulnessCheck"] = *filter.MindfulnessCheck
	}
	if filter.StartDate != nil && filter.EndDate != nil {
		mongoFilter["SK"] = bson.M{
			"$gte": fmt.Sprintf("MEAL#%sT00:00:00Z", *filter.StartDate),
			"$lte": fmt.Sprintf("MEAL#%sT23:59:59Z", *filter.EndDate),
		}
	}
	if filter.Search != nil && *filter.Search != "" {
		mongoFilter["$text"] = bson.M{"$search": *filter.Search}
	}
	if filter.Cursor != "" {
		mongoFilter["SK"] = bson.M{"$lt": filter.Cursor}
	}

	sortDir := -1
	if filter.Sort == "timestamp" {
		sortDir = 1
	}

	opts := options.Find().
		SetSort(bson.M{"SK": sortDir}).
		SetLimit(int64(filter.Limit + 1))

	cursor, err := r.collection.Find(ctx, mongoFilter, opts)
	if err != nil {
		return nil, "", err
	}
	defer cursor.Close(ctx)

	var results []bson.M
	if err := cursor.All(ctx, &results); err != nil {
		return nil, "", err
	}

	meals := make([]nutrition.MealLog, 0, len(results))
	for _, doc := range results {
		meals = append(meals, *decodeMealLog(doc))
	}

	var nextCursor string
	if len(meals) > filter.Limit {
		meals = meals[:filter.Limit]
		lastSK, ok := results[filter.Limit-1]["SK"].(string)
		if ok {
			nextCursor = lastSK
		}
	}

	return meals, nextCursor, nil
}

// UpdateMealLog updates an existing meal log document.
func (r *NutritionMealRepository) UpdateMealLog(ctx context.Context, meal *nutrition.MealLog) error {
	filter := bson.M{
		"PK":     fmt.Sprintf("USER#%s", meal.UserID),
		"mealId": meal.MealID,
	}

	update := bson.M{
		"$set": bson.M{
			"ModifiedAt":       meal.ModifiedAt,
			"description":      meal.Description,
			"eatingContext":     meal.EatingContext,
			"moodBefore":       meal.MoodBefore,
			"moodAfter":        meal.MoodAfter,
			"mindfulnessCheck": meal.MindfulnessCheck,
			"notes":            meal.Notes,
		},
	}

	_, err := r.collection.UpdateOne(ctx, filter, update)
	return err
}

// DeleteMealLog deletes a meal log document.
func (r *NutritionMealRepository) DeleteMealLog(ctx context.Context, userID, mealID string) error {
	filter := bson.M{
		"PK":     fmt.Sprintf("USER#%s", userID),
		"mealId": mealID,
	}

	_, err := r.collection.DeleteOne(ctx, filter)
	return err
}

// CountMealsForDate returns the number of meals logged for a specific date.
func (r *NutritionMealRepository) CountMealsForDate(ctx context.Context, userID, date string) (int, error) {
	filter := bson.M{
		"PK": fmt.Sprintf("USER#%s", userID),
		"SK": bson.M{
			"$gte": fmt.Sprintf("MEAL#%sT00:00:00Z", date),
			"$lte": fmt.Sprintf("MEAL#%sT23:59:59Z", date),
		},
	}

	count, err := r.collection.CountDocuments(ctx, filter)
	return int(count), err
}

// GetMealsInDateRange retrieves all meals within a date range.
func (r *NutritionMealRepository) GetMealsInDateRange(ctx context.Context, userID, startDate, endDate string) ([]nutrition.MealLog, error) {
	filter := bson.M{
		"PK": fmt.Sprintf("USER#%s", userID),
		"SK": bson.M{
			"$gte": fmt.Sprintf("MEAL#%sT00:00:00Z", startDate),
			"$lte": fmt.Sprintf("MEAL#%sT23:59:59Z", endDate),
		},
	}

	opts := options.Find().SetSort(bson.M{"SK": -1})
	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var results []bson.M
	if err := cursor.All(ctx, &results); err != nil {
		return nil, err
	}

	meals := make([]nutrition.MealLog, 0, len(results))
	for _, doc := range results {
		meals = append(meals, *decodeMealLog(doc))
	}

	return meals, nil
}

func decodeMealLog(doc bson.M) *nutrition.MealLog {
	meal := &nutrition.MealLog{}

	if v, ok := doc["mealId"].(string); ok {
		meal.MealID = v
	}
	if v, ok := doc["mealType"].(string); ok {
		meal.MealType = nutrition.MealType(v)
	}
	if v, ok := doc["customMealLabel"].(*string); ok {
		meal.CustomMealLabel = v
	}
	if v, ok := doc["description"].(*string); ok {
		meal.Description = v
	} else if v, ok := doc["description"].(string); ok {
		meal.Description = &v
	}
	if v, ok := doc["isQuickLog"].(bool); ok {
		meal.IsQuickLog = v
	}
	if v, ok := doc["CreatedAt"].(time.Time); ok {
		meal.CreatedAt = v
	}
	if v, ok := doc["ModifiedAt"].(time.Time); ok {
		meal.ModifiedAt = v
	}

	// Decode timestamp from SK.
	if sk, ok := doc["SK"].(string); ok {
		if ts, err := time.Parse(time.RFC3339, strings.TrimPrefix(sk, "MEAL#")); err == nil {
			meal.Timestamp = ts
		}
	}

	return meal
}

func parseMoodValues(s string) []int {
	parts := strings.Split(s, ",")
	vals := make([]int, 0, len(parts))
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if p == "" {
			continue
		}
		var v int
		if _, err := fmt.Sscanf(p, "%d", &v); err == nil {
			vals = append(vals, v)
		}
	}
	return vals
}
