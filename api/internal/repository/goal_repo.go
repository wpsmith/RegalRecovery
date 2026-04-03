// internal/repository/goal_repo.go
package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
)

// GoalRepo implements GoalRepository using MongoDB.
type GoalRepo struct {
	client *MongoClient
}

// NewGoalRepo creates a new GoalRepo.
func NewGoalRepo(client *MongoClient) *GoalRepo {
	return &GoalRepo{client: client}
}

// ListGoals lists all goals for a user.
func (r *GoalRepo) ListGoals(ctx context.Context, userID string) ([]Goal, error) {
	cursor, err := r.client.Collection("goals").Find(ctx, bson.M{"userId": userID})
	if err != nil {
		return nil, fmt.Errorf("listing goals for user %s: %w", userID, err)
	}

	var goals []Goal
	if err := cursor.All(ctx, &goals); err != nil {
		return nil, fmt.Errorf("decoding goals for user %s: %w", userID, err)
	}

	return goals, nil
}

// GetGoal retrieves a specific goal by ID.
func (r *GoalRepo) GetGoal(ctx context.Context, userID, goalID string) (*Goal, error) {
	var goal Goal
	err := r.client.Collection("goals").FindOne(ctx, bson.M{
		"userId": userID,
		"goalId": goalID,
	}).Decode(&goal)
	if err != nil {
		return nil, fmt.Errorf("getting goal %s for user %s: %w", goalID, userID, err)
	}
	return &goal, nil
}

// CreateGoal creates a new goal.
func (r *GoalRepo) CreateGoal(ctx context.Context, goal *Goal) error {
	SetBaseDocumentDefaults(&goal.BaseDocument)

	if _, err := r.client.Collection("goals").InsertOne(ctx, goal); err != nil {
		return fmt.Errorf("creating goal: %w", err)
	}

	return nil
}

// UpdateGoal updates an existing goal.
func (r *GoalRepo) UpdateGoal(ctx context.Context, goal *Goal) error {
	UpdateModified(&goal.BaseDocument)

	if _, err := r.client.Collection("goals").ReplaceOne(ctx, bson.M{
		"userId": goal.UserID,
		"goalId": goal.GoalID,
	}, goal); err != nil {
		return fmt.Errorf("updating goal: %w", err)
	}

	return nil
}
