// internal/repository/content_repo.go
package repository

import (
	"context"
	"fmt"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
)

// ContentRepo implements ContentRepository using DynamoDB.
type ContentRepo struct {
	client *DynamoClient
}

// NewContentRepo creates a new ContentRepo.
func NewContentRepo(client *DynamoClient) *ContentRepo {
	return &ContentRepo{client: client}
}

// GetAffirmationPack retrieves an affirmation pack by ID.
// PK: PACK#{packID}, SK: META
func (r *ContentRepo) GetAffirmationPack(ctx context.Context, packID string) (*AffirmationPack, error) {
	var pack AffirmationPack
	err := r.client.GetItem(ctx, fmt.Sprintf("PACK#%s", packID), "META", &pack)
	if err != nil {
		return nil, fmt.Errorf("getting affirmation pack %s: %w", packID, err)
	}
	return &pack, nil
}

// GetAffirmationPacks retrieves all affirmation packs (pack metadata only).
// This requires a scan with filter for EntityType=AFFIRMATION_PACK and SK=META.
// For production, consider maintaining a catalog index or separate item for listing.
func (r *ContentRepo) GetAffirmationPacks(ctx context.Context) ([]AffirmationPack, error) {
	result, err := r.client.Scan(ctx, &dynamodb.ScanInput{
		FilterExpression: aws.String("EntityType = :type AND SK = :sk"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":type": &types.AttributeValueMemberS{Value: "AFFIRMATION_PACK"},
			":sk":   &types.AttributeValueMemberS{Value: "META"},
		},
	})
	if err != nil {
		return nil, fmt.Errorf("listing affirmation packs: %w", err)
	}

	var packs []AffirmationPack
	if err := attributevalue.UnmarshalListOfMaps(result.Items, &packs); err != nil {
		return nil, fmt.Errorf("unmarshaling affirmation packs: %w", err)
	}

	return packs, nil
}

// GetAffirmationsInPack retrieves all affirmations within a pack.
// PK: PACK#{packID}, SK begins_with AFFIRMATION#
func (r *ContentRepo) GetAffirmationsInPack(ctx context.Context, packID string) ([]Affirmation, error) {
	result, err := r.client.Query(ctx, &dynamodb.QueryInput{
		KeyConditionExpression: aws.String("PK = :pk AND begins_with(SK, :sk)"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":pk": &types.AttributeValueMemberS{Value: fmt.Sprintf("PACK#%s", packID)},
			":sk": &types.AttributeValueMemberS{Value: "AFFIRMATION#"},
		},
	})
	if err != nil {
		return nil, fmt.Errorf("listing affirmations for pack %s: %w", packID, err)
	}

	var affirmations []Affirmation
	if err := attributevalue.UnmarshalListOfMaps(result.Items, &affirmations); err != nil {
		return nil, fmt.Errorf("unmarshaling affirmations: %w", err)
	}

	return affirmations, nil
}

// GetDevotional retrieves a devotional by day number.
// PK: CONTENT#devotional, SK: DAY#{day}
func (r *ContentRepo) GetDevotional(ctx context.Context, day int) (*DevotionalDay, error) {
	var devotional DevotionalDay
	err := r.client.GetItem(ctx, "CONTENT#devotional", fmt.Sprintf("DAY#%d", day), &devotional)
	if err != nil {
		return nil, fmt.Errorf("getting devotional day %d: %w", day, err)
	}
	return &devotional, nil
}

// GetPrompts retrieves all prompts, optionally filtered by category.
// PK: CONTENT#prompts, SK begins_with PROMPT# (or PROMPT#{category}# if filtered)
func (r *ContentRepo) GetPrompts(ctx context.Context, category string) ([]Prompt, error) {
	skPrefix := "PROMPT#"
	if category != "" {
		skPrefix = fmt.Sprintf("PROMPT#%s#", category)
	}

	result, err := r.client.Query(ctx, &dynamodb.QueryInput{
		KeyConditionExpression: aws.String("PK = :pk AND begins_with(SK, :sk)"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":pk": &types.AttributeValueMemberS{Value: "CONTENT#prompts"},
			":sk": &types.AttributeValueMemberS{Value: skPrefix},
		},
	})
	if err != nil {
		return nil, fmt.Errorf("listing prompts: %w", err)
	}

	var prompts []Prompt
	if err := attributevalue.UnmarshalListOfMaps(result.Items, &prompts); err != nil {
		return nil, fmt.Errorf("unmarshaling prompts: %w", err)
	}
	return prompts, nil
}

// GetPrompt retrieves a specific prompt by ID.
// PK: CONTENT#prompts, SK: PROMPT#{promptID}
func (r *ContentRepo) GetPrompt(ctx context.Context, promptID string) (*Prompt, error) {
	var prompt Prompt
	err := r.client.GetItem(ctx, "CONTENT#prompts", fmt.Sprintf("PROMPT#%s", promptID), &prompt)
	if err != nil {
		return nil, fmt.Errorf("getting prompt %s: %w", promptID, err)
	}
	return &prompt, nil
}

// GetRandomPrompt retrieves a random prompt, optionally filtered by category.
// Fetches all matching prompts and picks one randomly.
func (r *ContentRepo) GetRandomPrompt(ctx context.Context, category string) (*Prompt, error) {
	prompts, err := r.GetPrompts(ctx, category)
	if err != nil {
		return nil, err
	}
	if len(prompts) == 0 {
		return nil, nil
	}
	// Use a simple time-based selection for randomness.
	index := int(NowISO8601()[17]-'0') % len(prompts)
	return &prompts[index], nil
}
