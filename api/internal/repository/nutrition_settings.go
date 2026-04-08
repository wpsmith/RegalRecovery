// internal/repository/nutrition_settings.go
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

// NutritionSettingsRepository implements nutrition.SettingsRepository using MongoDB.
type NutritionSettingsRepository struct {
	collection *mongo.Collection
}

// NewNutritionSettingsRepository creates a new NutritionSettingsRepository.
func NewNutritionSettingsRepository(db *mongo.Database) *NutritionSettingsRepository {
	return &NutritionSettingsRepository{
		collection: db.Collection("nutritionSettings"),
	}
}

// GetSettings retrieves nutrition settings for a user.
func (r *NutritionSettingsRepository) GetSettings(ctx context.Context, userID string) (*nutrition.NutritionSettings, error) {
	filter := bson.M{
		"PK": fmt.Sprintf("USER#%s", userID),
		"SK": "NUTRITION_SETTINGS",
	}

	var doc bson.M
	err := r.collection.FindOne(ctx, filter).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, err
	}

	return decodeNutritionSettings(doc, userID), nil
}

// UpsertSettings creates or updates nutrition settings.
func (r *NutritionSettingsRepository) UpsertSettings(ctx context.Context, settings *nutrition.NutritionSettings) error {
	filter := bson.M{
		"PK": fmt.Sprintf("USER#%s", settings.UserID),
		"SK": "NUTRITION_SETTINGS",
	}

	doc := bson.M{
		"$set": bson.M{
			"EntityType": "NUTRITION_SETTINGS",
			"TenantId":   settings.TenantID,
			"ModifiedAt": settings.ModifiedAt,
			"hydration": bson.M{
				"servingSizeOz":       settings.Hydration.ServingSizeOz,
				"dailyTargetServings": settings.Hydration.DailyTargetServings,
			},
			"mealReminders": bson.M{
				"breakfast": bson.M{"enabled": settings.MealReminders.Breakfast.Enabled, "time": settings.MealReminders.Breakfast.Time},
				"lunch":     bson.M{"enabled": settings.MealReminders.Lunch.Enabled, "time": settings.MealReminders.Lunch.Time},
				"dinner":    bson.M{"enabled": settings.MealReminders.Dinner.Enabled, "time": settings.MealReminders.Dinner.Time},
			},
			"hydrationReminders": bson.M{
				"enabled":       settings.HydrationReminders.Enabled,
				"intervalHours": settings.HydrationReminders.IntervalHours,
			},
			"missedMealNudge": bson.M{
				"enabled":   settings.MissedMealNudge.Enabled,
				"nudgeTime": settings.MissedMealNudge.NudgeTime,
			},
			"insightPreferences": bson.M{
				"mealConsistencyEnabled": settings.InsightPreferences.MealConsistencyEnabled,
				"emotionalEatingEnabled": settings.InsightPreferences.EmotionalEatingEnabled,
				"mindfulnessEnabled":     settings.InsightPreferences.MindfulnessEnabled,
				"crossDomainEnabled":     settings.InsightPreferences.CrossDomainEnabled,
			},
		},
		"$setOnInsert": bson.M{
			"CreatedAt": settings.CreatedAt,
		},
	}

	opts := options.UpdateOne().SetUpsert(true)
	_, err := r.collection.UpdateOne(ctx, filter, doc, opts)
	return err
}

func decodeNutritionSettings(doc bson.M, userID string) *nutrition.NutritionSettings {
	settings := nutrition.DefaultNutritionSettings(userID)

	if v, ok := doc["CreatedAt"].(time.Time); ok {
		settings.CreatedAt = v
	}
	if v, ok := doc["ModifiedAt"].(time.Time); ok {
		settings.ModifiedAt = v
	}

	if hydration, ok := doc["hydration"].(bson.M); ok {
		if v, ok := hydration["servingSizeOz"].(float64); ok {
			settings.Hydration.ServingSizeOz = v
		}
		if v, ok := hydration["dailyTargetServings"].(int32); ok {
			settings.Hydration.DailyTargetServings = int(v)
		}
	}

	if reminders, ok := doc["mealReminders"].(bson.M); ok {
		if bk, ok := reminders["breakfast"].(bson.M); ok {
			if v, ok := bk["enabled"].(bool); ok {
				settings.MealReminders.Breakfast.Enabled = v
			}
			if v, ok := bk["time"].(string); ok {
				settings.MealReminders.Breakfast.Time = v
			}
		}
		if ln, ok := reminders["lunch"].(bson.M); ok {
			if v, ok := ln["enabled"].(bool); ok {
				settings.MealReminders.Lunch.Enabled = v
			}
			if v, ok := ln["time"].(string); ok {
				settings.MealReminders.Lunch.Time = v
			}
		}
		if dn, ok := reminders["dinner"].(bson.M); ok {
			if v, ok := dn["enabled"].(bool); ok {
				settings.MealReminders.Dinner.Enabled = v
			}
			if v, ok := dn["time"].(string); ok {
				settings.MealReminders.Dinner.Time = v
			}
		}
	}

	if prefs, ok := doc["insightPreferences"].(bson.M); ok {
		if v, ok := prefs["mealConsistencyEnabled"].(bool); ok {
			settings.InsightPreferences.MealConsistencyEnabled = v
		}
		if v, ok := prefs["emotionalEatingEnabled"].(bool); ok {
			settings.InsightPreferences.EmotionalEatingEnabled = v
		}
		if v, ok := prefs["mindfulnessEnabled"].(bool); ok {
			settings.InsightPreferences.MindfulnessEnabled = v
		}
		if v, ok := prefs["crossDomainEnabled"].(bool); ok {
			settings.InsightPreferences.CrossDomainEnabled = v
		}
	}

	return settings
}
