// internal/repository/flag_repo.go
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

// FlagRepo implements FlagRepository using DynamoDB.
type FlagRepo struct {
	client *DynamoClient
}

// NewFlagRepo creates a new FlagRepo.
func NewFlagRepo(client *DynamoClient) *FlagRepo {
	return &FlagRepo{client: client}
}

// GetFlag retrieves a single feature flag by key.
// PK: FLAGS, SK: {flagKey}
func (r *FlagRepo) GetFlag(ctx context.Context, flagKey string) (*Flag, error) {
	var flag Flag
	err := r.client.GetItem(ctx, "FLAGS", flagKey, &flag)
	if err != nil {
		return nil, fmt.Errorf("getting flag %s: %w", flagKey, err)
	}
	return &flag, nil
}

// GetAllFlags retrieves all feature flags.
// PK: FLAGS
func (r *FlagRepo) GetAllFlags(ctx context.Context) ([]Flag, error) {
	result, err := r.client.Query(ctx, &dynamodb.QueryInput{
		KeyConditionExpression: aws.String("PK = :pk"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":pk": &types.AttributeValueMemberS{Value: "FLAGS"},
		},
	})
	if err != nil {
		return nil, fmt.Errorf("listing all flags: %w", err)
	}

	var flags []Flag
	if err := attributevalue.UnmarshalListOfMaps(result.Items, &flags); err != nil {
		return nil, fmt.Errorf("unmarshaling flags: %w", err)
	}

	return flags, nil
}

// SetFlag creates or updates a feature flag.
func (r *FlagRepo) SetFlag(ctx context.Context, flag *Flag) error {
	now := time.Now().UTC().Format(time.RFC3339)
	if flag.CreatedAt == "" {
		flag.CreatedAt = now
	}
	flag.ModifiedAt = now
	flag.UpdatedAt = now
	flag.EntityType = "FEATURE_FLAG"

	if err := r.client.PutItem(ctx, flag); err != nil {
		return fmt.Errorf("setting flag: %w", err)
	}

	return nil
}
