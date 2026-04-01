// internal/repository/commitment_repo.go
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

// CommitmentRepo implements CommitmentRepository using DynamoDB.
type CommitmentRepo struct {
	client *DynamoClient
}

// NewCommitmentRepo creates a new CommitmentRepo.
func NewCommitmentRepo(client *DynamoClient) *CommitmentRepo {
	return &CommitmentRepo{client: client}
}

// ListCommitments lists all commitments for a user.
// PK: USER#{userID}, SK begins_with COMMITMENT#
func (r *CommitmentRepo) ListCommitments(ctx context.Context, userID string) ([]Commitment, error) {
	result, err := r.client.Query(ctx, &dynamodb.QueryInput{
		KeyConditionExpression: aws.String("PK = :pk AND begins_with(SK, :sk)"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":pk": &types.AttributeValueMemberS{Value: fmt.Sprintf("USER#%s", userID)},
			":sk": &types.AttributeValueMemberS{Value: "COMMITMENT#"},
		},
	})
	if err != nil {
		return nil, fmt.Errorf("listing commitments for user %s: %w", userID, err)
	}

	var commitments []Commitment
	if err := attributevalue.UnmarshalListOfMaps(result.Items, &commitments); err != nil {
		return nil, fmt.Errorf("unmarshaling commitments: %w", err)
	}

	return commitments, nil
}

// GetCommitment retrieves a specific commitment by ID.
// PK: USER#{userID}, SK: COMMITMENT#{commitmentID}
func (r *CommitmentRepo) GetCommitment(ctx context.Context, userID, commitmentID string) (*Commitment, error) {
	var commitment Commitment
	err := r.client.GetItem(ctx, fmt.Sprintf("USER#%s", userID), fmt.Sprintf("COMMITMENT#%s", commitmentID), &commitment)
	if err != nil {
		return nil, fmt.Errorf("getting commitment %s for user %s: %w", commitmentID, userID, err)
	}
	return &commitment, nil
}

// CreateCommitment creates a new commitment.
func (r *CommitmentRepo) CreateCommitment(ctx context.Context, commitment *Commitment) error {
	now := time.Now().UTC().Format(time.RFC3339)
	commitment.CreatedAt = now
	commitment.ModifiedAt = now
	commitment.EntityType = "COMMITMENT"

	if err := r.client.PutItem(ctx, commitment); err != nil {
		return fmt.Errorf("creating commitment: %w", err)
	}

	return nil
}

// UpdateCommitment updates an existing commitment.
func (r *CommitmentRepo) UpdateCommitment(ctx context.Context, commitment *Commitment) error {
	commitment.ModifiedAt = time.Now().UTC().Format(time.RFC3339)

	if err := r.client.PutItem(ctx, commitment); err != nil {
		return fmt.Errorf("updating commitment: %w", err)
	}

	return nil
}
