// internal/repository/nutrition_calendar.go
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

// NutritionCalendarRepository implements nutrition.CalendarRepository using MongoDB.
type NutritionCalendarRepository struct {
	collection *mongo.Collection
}

// NewNutritionCalendarRepository creates a new NutritionCalendarRepository.
func NewNutritionCalendarRepository(db *mongo.Database) *NutritionCalendarRepository {
	return &NutritionCalendarRepository{
		collection: db.Collection("calendarActivities"),
	}
}

// CreateCalendarActivity writes a calendar activity entry for a meal.
func (r *NutritionCalendarRepository) CreateCalendarActivity(ctx context.Context, activity *nutrition.CalendarActivity) error {
	doc := bson.M{
		"PK":           fmt.Sprintf("USER#%s", activity.UserID),
		"SK":           fmt.Sprintf("ACTIVITY#%s#NUTRITION#%s", activity.Date, activity.SourceKey),
		"EntityType":   "CALENDAR_ACTIVITY",
		"activityType": activity.ActivityType,
		"summary": bson.M{
			"mealType":       activity.Summary.MealType,
			"mealId":         activity.Summary.MealID,
			"hasDescription": activity.Summary.HasDescription,
		},
		"sourceKey": activity.SourceKey,
		"CreatedAt": time.Now().UTC(),
	}

	_, err := r.collection.InsertOne(ctx, doc)
	return err
}

// DeleteCalendarActivity removes a calendar activity entry.
func (r *NutritionCalendarRepository) DeleteCalendarActivity(ctx context.Context, userID, sourceKey string) error {
	filter := bson.M{
		"PK":        fmt.Sprintf("USER#%s", userID),
		"sourceKey": sourceKey,
	}

	_, err := r.collection.DeleteOne(ctx, filter)
	return err
}

// GetCalendarActivities retrieves calendar activities for a month.
func (r *NutritionCalendarRepository) GetCalendarActivities(ctx context.Context, userID string, year, month int) ([]nutrition.CalendarActivity, error) {
	startDate := fmt.Sprintf("%04d-%02d-01", year, month)
	lastDay := time.Date(year, time.Month(month)+1, 0, 0, 0, 0, 0, time.UTC).Day()
	endDate := fmt.Sprintf("%04d-%02d-%02d", year, month, lastDay)

	filter := bson.M{
		"PK": fmt.Sprintf("USER#%s", userID),
		"SK": bson.M{
			"$gte": fmt.Sprintf("ACTIVITY#%s#NUTRITION", startDate),
			"$lte": fmt.Sprintf("ACTIVITY#%s#NUTRITION~", endDate),
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

	activities := make([]nutrition.CalendarActivity, 0, len(results))
	for _, doc := range results {
		ca := nutrition.CalendarActivity{}
		ca.UserID = userID
		if v, ok := doc["activityType"].(string); ok {
			ca.ActivityType = v
		}
		if v, ok := doc["sourceKey"].(string); ok {
			ca.SourceKey = v
		}
		if summary, ok := doc["summary"].(bson.M); ok {
			if v, ok := summary["mealType"].(string); ok {
				ca.Summary.MealType = nutrition.MealType(v)
			}
			if v, ok := summary["mealId"].(string); ok {
				ca.Summary.MealID = v
			}
			if v, ok := summary["hasDescription"].(bool); ok {
				ca.Summary.HasDescription = v
			}
		}
		activities = append(activities, ca)
	}

	return activities, nil
}
