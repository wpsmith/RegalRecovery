// internal/repository/tracking_repo.go
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

// TrackingRepo implements TrackingRepository using DynamoDB.
type TrackingRepo struct {
	client *DynamoClient
}

// NewTrackingRepo creates a new TrackingRepo.
func NewTrackingRepo(client *DynamoClient) *TrackingRepo {
	return &TrackingRepo{client: client}
}

// GetStreak retrieves the current streak for an addiction.
// PK: USER#{userID}, SK: STREAK#{addictionID}
func (r *TrackingRepo) GetStreak(ctx context.Context, userID, addictionID string) (*Streak, error) {
	var streak Streak
	err := r.client.GetItem(ctx, fmt.Sprintf("USER#%s", userID), fmt.Sprintf("STREAK#%s", addictionID), &streak)
	if err != nil {
		return nil, fmt.Errorf("getting streak for user %s addiction %s: %w", userID, addictionID, err)
	}
	return &streak, nil
}

// UpdateStreak updates the streak record.
func (r *TrackingRepo) UpdateStreak(ctx context.Context, streak *Streak) error {
	streak.ModifiedAt = time.Now().UTC().Format(time.RFC3339)

	if err := r.client.PutItem(ctx, streak); err != nil {
		return fmt.Errorf("updating streak: %w", err)
	}

	return nil
}

// RecordRelapse records a relapse event.
// PK: USER#{userID}, SK: RELAPSE#{timestamp}
func (r *TrackingRepo) RecordRelapse(ctx context.Context, userID string, relapse *Relapse) error {
	now := time.Now().UTC().Format(time.RFC3339)
	relapse.CreatedAt = now
	relapse.ModifiedAt = now
	relapse.EntityType = "RELAPSE"

	if err := r.client.PutItem(ctx, relapse); err != nil {
		return fmt.Errorf("recording relapse: %w", err)
	}

	return nil
}

// GetMilestones retrieves all milestones for a user.
// PK: USER#{userID}, SK begins_with MILESTONE#
func (r *TrackingRepo) GetMilestones(ctx context.Context, userID string) ([]Milestone, error) {
	result, err := r.client.Query(ctx, &dynamodb.QueryInput{
		KeyConditionExpression: aws.String("PK = :pk AND begins_with(SK, :sk)"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":pk": &types.AttributeValueMemberS{Value: fmt.Sprintf("USER#%s", userID)},
			":sk": &types.AttributeValueMemberS{Value: "MILESTONE#"},
		},
	})
	if err != nil {
		return nil, fmt.Errorf("listing milestones for user %s: %w", userID, err)
	}

	var milestones []Milestone
	if err := attributevalue.UnmarshalListOfMaps(result.Items, &milestones); err != nil {
		return nil, fmt.Errorf("unmarshaling milestones: %w", err)
	}

	return milestones, nil
}

// GetMilestonesForAddiction retrieves milestones for a specific addiction.
// PK: USER#{userID}, SK begins_with MILESTONE#{addictionID}#
func (r *TrackingRepo) GetMilestonesForAddiction(ctx context.Context, userID, addictionID string) ([]Milestone, error) {
	result, err := r.client.Query(ctx, &dynamodb.QueryInput{
		KeyConditionExpression: aws.String("PK = :pk AND begins_with(SK, :sk)"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":pk": &types.AttributeValueMemberS{Value: fmt.Sprintf("USER#%s", userID)},
			":sk": &types.AttributeValueMemberS{Value: fmt.Sprintf("MILESTONE#%s#", addictionID)},
		},
	})
	if err != nil {
		return nil, fmt.Errorf("listing milestones for user %s addiction %s: %w", userID, addictionID, err)
	}

	var milestones []Milestone
	if err := attributevalue.UnmarshalListOfMaps(result.Items, &milestones); err != nil {
		return nil, fmt.Errorf("unmarshaling milestones: %w", err)
	}

	return milestones, nil
}

// CreateMilestone creates a new milestone record.
// PK: USER#{userID}, SK: MILESTONE#{addictionID}#{days}
func (r *TrackingRepo) CreateMilestone(ctx context.Context, userID string, milestone *Milestone) error {
	now := time.Now().UTC().Format(time.RFC3339)
	milestone.CreatedAt = now
	milestone.ModifiedAt = now
	milestone.EntityType = "MILESTONE"

	if err := r.client.PutItem(ctx, milestone); err != nil {
		return fmt.Errorf("creating milestone: %w", err)
	}

	return nil
}

// GetRelapseHistory retrieves relapse history for a user.
// PK: USER#{userID}, SK begins_with RELAPSE#, descending order
func (r *TrackingRepo) GetRelapseHistory(ctx context.Context, userID string, limit int) ([]Relapse, error) {
	result, err := r.client.Query(ctx, &dynamodb.QueryInput{
		KeyConditionExpression: aws.String("PK = :pk AND begins_with(SK, :sk)"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":pk": &types.AttributeValueMemberS{Value: fmt.Sprintf("USER#%s", userID)},
			":sk": &types.AttributeValueMemberS{Value: "RELAPSE#"},
		},
		ScanIndexForward: aws.Bool(false), // Descending order (newest first)
		Limit:            aws.Int32(int32(limit)),
	})
	if err != nil {
		return nil, fmt.Errorf("listing relapse history for user %s: %w", userID, err)
	}

	var relapses []Relapse
	if err := attributevalue.UnmarshalListOfMaps(result.Items, &relapses); err != nil {
		return nil, fmt.Errorf("unmarshaling relapses: %w", err)
	}

	return relapses, nil
}
