// internal/repository/exercise_goal_repo.go
package repository

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/regalrecovery/api/internal/domain/exercise"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

const exerciseGoalCollection = "exerciseGoals"

// ExerciseGoalDoc is the MongoDB document for a weekly exercise goal.
type ExerciseGoalDoc struct {
	BaseDocument `bson:",inline"`

	UserID              string `bson:"userId"`
	EntityType          string `bson:"entityType"`
	TargetActiveMinutes *int   `bson:"targetActiveMinutes,omitempty"`
	TargetSessions      *int   `bson:"targetSessions,omitempty"`
}

// ExerciseGoalRepo implements exercise.GoalRepository using MongoDB.
type ExerciseGoalRepo struct {
	client *MongoClient
}

// NewExerciseGoalRepo creates a new ExerciseGoalRepo.
func NewExerciseGoalRepo(client *MongoClient) *ExerciseGoalRepo {
	return &ExerciseGoalRepo{client: client}
}

func (r *ExerciseGoalRepo) collection() string {
	return exerciseGoalCollection
}

// Get retrieves the weekly goal for a user.
func (r *ExerciseGoalRepo) Get(ctx context.Context, userID string) (*exercise.ExerciseGoal, error) {
	coll := r.client.database.Collection(r.collection())

	filter := bson.M{
		"userId":     userID,
		"entityType": "EXERCISE_GOAL",
	}

	var doc ExerciseGoalDoc
	err := coll.FindOne(ctx, filter).Decode(&doc)
	if err != nil {
		if strings.Contains(err.Error(), "no documents") {
			return nil, nil
		}
		return nil, fmt.Errorf("finding exercise goal: %w", err)
	}

	result := docToExerciseGoal(doc)
	return &result, nil
}

// Upsert creates or replaces the weekly goal for a user.
func (r *ExerciseGoalRepo) Upsert(ctx context.Context, userID string, goal exercise.ExerciseGoal) error {
	coll := r.client.database.Collection(r.collection())

	filter := bson.M{
		"userId":     userID,
		"entityType": "EXERCISE_GOAL",
	}

	now := time.Now().UTC()
	update := bson.M{
		"$set": bson.M{
			"targetActiveMinutes": goal.TargetActiveMinutes,
			"targetSessions":      goal.TargetSessions,
			"modifiedAt":          now,
			"tenantId":            goal.TenantID,
		},
		"$setOnInsert": bson.M{
			"userId":     userID,
			"entityType": "EXERCISE_GOAL",
			"createdAt":  now,
		},
	}

	opts := options.UpdateOne().SetUpsert(true)
	_, err := coll.UpdateOne(ctx, filter, update, opts)
	if err != nil {
		return fmt.Errorf("upserting exercise goal: %w", err)
	}
	return nil
}

// Delete removes the weekly goal for a user.
func (r *ExerciseGoalRepo) Delete(ctx context.Context, userID string) error {
	coll := r.client.database.Collection(r.collection())

	filter := bson.M{
		"userId":     userID,
		"entityType": "EXERCISE_GOAL",
	}

	_, err := coll.DeleteOne(ctx, filter)
	if err != nil {
		return fmt.Errorf("deleting exercise goal: %w", err)
	}
	return nil
}

func docToExerciseGoal(doc ExerciseGoalDoc) exercise.ExerciseGoal {
	return exercise.ExerciseGoal{
		UserID:              doc.UserID,
		TenantID:            doc.TenantID,
		TargetActiveMinutes: doc.TargetActiveMinutes,
		TargetSessions:      doc.TargetSessions,
		CreatedAt:           doc.CreatedAt,
		ModifiedAt:          doc.ModifiedAt,
	}
}
