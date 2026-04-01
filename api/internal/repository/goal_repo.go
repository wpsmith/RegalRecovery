// internal/repository/goal_repo.go
package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
)

// GoalRepo implements GoalRepository using DynamoDB.
type GoalRepo struct {
	client *DynamoClient
}

// NewGoalRepo creates a new GoalRepo.
func NewGoalRepo(client *DynamoClient) *GoalRepo {
	return &GoalRepo{client: client}
}

// ListGoals lists all goals for a user.
// PK: USER#{userID}, SK begins_with GOAL#
func (r *GoalRepo) ListGoals(ctx context.Context, userID string) ([]Goal, error) {
	result, err := r.client.Query(ctx, &dynamodb.QueryInput{
		KeyConditionExpression: aws.String("PK = :pk AND begins_with(SK, :sk)"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":pk": &types.AttributeValueMemberS{Value: fmt.Sprintf("USER#%s", userID)},
			":sk": &types.AttributeValueMemberS{Value: "GOAL#"},
		},
	})
	if err != nil {
		return nil, fmt.Errorf("listing goals for user %s: %w", userID, err)
	}

	var goals []Goal
	if err := attributevalue.UnmarshalListOfMaps(result.Items, &goals); err != nil {
		return nil, fmt.Errorf("unmarshaling goals: %w", err)
	}

	return goals, nil
}

// GetGoal retrieves a specific goal by ID.
// PK: USER#{userID}, SK: GOAL#{goalID}
func (r *GoalRepo) GetGoal(ctx context.Context, userID, goalID string) (*Goal, error) {
	var goal Goal
	err := r.client.GetItem(ctx, fmt.Sprintf("USER#%s", userID), fmt.Sprintf("GOAL#%s", goalID), &goal)
	if err != nil {
		return nil, fmt.Errorf("getting goal %s for user %s: %w", goalID, userID, err)
	}
	return &goal, nil
}

// CreateGoal creates a new goal.
func (r *GoalRepo) CreateGoal(ctx context.Context, goal *Goal) error {
	now := time.Now().UTC().Format(time.RFC3339)
	goal.CreatedAt = now
	goal.ModifiedAt = now
	goal.EntityType = "GOAL"

	if err := r.client.PutItem(ctx, goal); err != nil {
		return fmt.Errorf("creating goal: %w", err)
	}

	return nil
}

// UpdateGoal updates an existing goal.
func (r *GoalRepo) UpdateGoal(ctx context.Context, goal *Goal) error {
	goal.ModifiedAt = time.Now().UTC().Format(time.RFC3339)

	if err := r.client.PutItem(ctx, goal); err != nil {
		return fmt.Errorf("updating goal: %w", err)
	}

	return nil
}
