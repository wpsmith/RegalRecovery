// internal/repository/content_repo.go
package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
)

// ContentRepo implements ContentRepository using MongoDB.
type ContentRepo struct {
	client *MongoClient
}

// NewContentRepo creates a new ContentRepo.
func NewContentRepo(client *MongoClient) *ContentRepo {
	return &ContentRepo{client: client}
}

// GetAffirmationPack retrieves an affirmation pack by ID.
func (r *ContentRepo) GetAffirmationPack(ctx context.Context, packID string) (*AffirmationPack, error) {
	var pack AffirmationPack
	err := r.client.Collection("affirmation_packs").FindOne(ctx, bson.M{"packId": packID}).Decode(&pack)
	if err != nil {
		return nil, fmt.Errorf("getting affirmation pack %s: %w", packID, err)
	}
	return &pack, nil
}

// GetAffirmationPacks retrieves all affirmation packs.
func (r *ContentRepo) GetAffirmationPacks(ctx context.Context) ([]AffirmationPack, error) {
	cursor, err := r.client.Collection("affirmation_packs").Find(ctx, bson.M{})
	if err != nil {
		return nil, fmt.Errorf("listing affirmation packs: %w", err)
	}

	var packs []AffirmationPack
	if err := cursor.All(ctx, &packs); err != nil {
		return nil, fmt.Errorf("decoding affirmation packs: %w", err)
	}
	return packs, nil
}

// GetAffirmationsInPack retrieves all affirmations within a pack.
func (r *ContentRepo) GetAffirmationsInPack(ctx context.Context, packID string) ([]Affirmation, error) {
	cursor, err := r.client.Collection("affirmations").Find(ctx, bson.M{"packId": packID})
	if err != nil {
		return nil, fmt.Errorf("listing affirmations for pack %s: %w", packID, err)
	}

	var affirmations []Affirmation
	if err := cursor.All(ctx, &affirmations); err != nil {
		return nil, fmt.Errorf("decoding affirmations: %w", err)
	}
	return affirmations, nil
}

// GetDevotional retrieves a devotional by day number.
func (r *ContentRepo) GetDevotional(ctx context.Context, day int) (*DevotionalDay, error) {
	var devotional DevotionalDay
	err := r.client.Collection("devotionals").FindOne(ctx, bson.M{"day": day}).Decode(&devotional)
	if err != nil {
		return nil, fmt.Errorf("getting devotional day %d: %w", day, err)
	}
	return &devotional, nil
}

// GetPrompts retrieves all prompts, optionally filtered by category.
func (r *ContentRepo) GetPrompts(ctx context.Context, category string) ([]Prompt, error) {
	filter := bson.M{}
	if category != "" {
		filter["category"] = category
	}

	cursor, err := r.client.Collection("prompts").Find(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("listing prompts: %w", err)
	}

	var prompts []Prompt
	if err := cursor.All(ctx, &prompts); err != nil {
		return nil, fmt.Errorf("decoding prompts: %w", err)
	}
	return prompts, nil
}

// GetPrompt retrieves a specific prompt by ID.
func (r *ContentRepo) GetPrompt(ctx context.Context, promptID string) (*Prompt, error) {
	var prompt Prompt
	err := r.client.Collection("prompts").FindOne(ctx, bson.M{"promptId": promptID}).Decode(&prompt)
	if err != nil {
		return nil, fmt.Errorf("getting prompt %s: %w", promptID, err)
	}
	return &prompt, nil
}

// GetRandomPrompt retrieves a random prompt, optionally filtered by category.
// Fetches all matching prompts and picks one using a simple time-based selection.
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
