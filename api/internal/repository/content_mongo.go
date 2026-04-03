// internal/repository/content_mongo.go
package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// ContentClient wraps the MongoDB content database connection.
type ContentClient struct {
	database *mongo.Database
}

// NewContentClient creates a new ContentClient for the content database.
func NewContentClient(client *mongo.Client, dbName string) *ContentClient {
	return &ContentClient{
		database: client.Database(dbName),
	}
}

// Collection returns a handle to the named collection in the content database.
func (c *ContentClient) Collection(name string) *mongo.Collection {
	return c.database.Collection(name)
}

// EnsureContentIndexes creates all indexes for the content database.
func (c *ContentClient) EnsureContentIndexes(ctx context.Context) error {
	indexes := map[string][]mongo.IndexModel{
		"feature_abouts": {
			{Keys: bson.D{{Key: "slug", Value: 1}}, Options: options.Index().SetUnique(true)},
			{Keys: bson.D{{Key: "category", Value: 1}, {Key: "sortOrder", Value: 1}}},
			{Keys: bson.D{{Key: "status", Value: 1}}},
		},
		"affirmation_packs": {
			{Keys: bson.D{{Key: "packId", Value: 1}}, Options: options.Index().SetUnique(true)},
			{Keys: bson.D{{Key: "tier", Value: 1}, {Key: "sortOrder", Value: 1}}},
			{Keys: bson.D{{Key: "category", Value: 1}, {Key: "sortOrder", Value: 1}}},
			{Keys: bson.D{{Key: "status", Value: 1}}},
		},
		"affirmations": {
			{Keys: bson.D{{Key: "affirmationId", Value: 1}}, Options: options.Index().SetUnique(true)},
			{Keys: bson.D{{Key: "packId", Value: 1}, {Key: "sortOrder", Value: 1}}},
			{Keys: bson.D{{Key: "status", Value: 1}}},
		},
		"devotional_packs": {
			{Keys: bson.D{{Key: "packId", Value: 1}}, Options: options.Index().SetUnique(true)},
			{Keys: bson.D{{Key: "tier", Value: 1}, {Key: "sortOrder", Value: 1}}},
			{Keys: bson.D{{Key: "category", Value: 1}, {Key: "sortOrder", Value: 1}}},
			{Keys: bson.D{{Key: "status", Value: 1}}},
		},
		"devotionals": {
			{Keys: bson.D{{Key: "devotionalId", Value: 1}}, Options: options.Index().SetUnique(true)},
			{Keys: bson.D{{Key: "packId", Value: 1}, {Key: "day", Value: 1}}},
			{Keys: bson.D{{Key: "status", Value: 1}}},
		},
		"journal_prompts": {
			{Keys: bson.D{{Key: "promptId", Value: 1}}, Options: options.Index().SetUnique(true)},
			{Keys: bson.D{{Key: "category", Value: 1}, {Key: "sortOrder", Value: 1}}},
			{Keys: bson.D{{Key: "tags", Value: 1}}},
			{Keys: bson.D{{Key: "status", Value: 1}}},
		},
		"glossary": {
			{Keys: bson.D{{Key: "termId", Value: 1}}, Options: options.Index().SetUnique(true)},
			{Keys: bson.D{{Key: "term", Value: 1}}},
			{Keys: bson.D{{Key: "sortOrder", Value: 1}}},
			{Keys: bson.D{{Key: "status", Value: 1}}},
		},
		"evening_review_questions": {
			{Keys: bson.D{{Key: "questionId", Value: 1}}, Options: options.Index().SetUnique(true)},
			{Keys: bson.D{{Key: "dimension", Value: 1}, {Key: "sortOrder", Value: 1}}},
			{Keys: bson.D{{Key: "status", Value: 1}}},
		},
		"acting_in_behaviors": {
			{Keys: bson.D{{Key: "behaviorId", Value: 1}}, Options: options.Index().SetUnique(true)},
			{Keys: bson.D{{Key: "sortOrder", Value: 1}}},
			{Keys: bson.D{{Key: "status", Value: 1}}},
		},
		"needs": {
			{Keys: bson.D{{Key: "needId", Value: 1}}, Options: options.Index().SetUnique(true)},
			{Keys: bson.D{{Key: "sortOrder", Value: 1}}},
			{Keys: bson.D{{Key: "status", Value: 1}}},
		},
		"sobriety_reset_messages": {
			{Keys: bson.D{{Key: "messageId", Value: 1}}, Options: options.Index().SetUnique(true)},
			{Keys: bson.D{{Key: "sortOrder", Value: 1}}},
			{Keys: bson.D{{Key: "status", Value: 1}}},
		},
		"themes": {
			{Keys: bson.D{{Key: "themeId", Value: 1}}, Options: options.Index().SetUnique(true)},
			{Keys: bson.D{{Key: "tier", Value: 1}, {Key: "sortOrder", Value: 1}}},
			{Keys: bson.D{{Key: "sortOrder", Value: 1}}},
			{Keys: bson.D{{Key: "status", Value: 1}}},
		},
	}

	for collName, collIndexes := range indexes {
		_, err := c.Collection(collName).Indexes().CreateMany(ctx, collIndexes)
		if err != nil {
			return fmt.Errorf("creating indexes for %s: %w", collName, err)
		}
	}

	return nil
}
