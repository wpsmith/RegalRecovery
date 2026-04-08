// internal/repository/mongo.go
package repository

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// MongoClient wraps the MongoDB client with database reference.
type MongoClient struct {
	client   *mongo.Client
	database *mongo.Database
}

// NewMongoClient creates a new MongoDB client and connects to the database.
func NewMongoClient(ctx context.Context, uri, dbName string) (*MongoClient, error) {
	client, err := mongo.Connect(options.Client().ApplyURI(uri))
	if err != nil {
		return nil, fmt.Errorf("connecting to MongoDB: %w", err)
	}

	// Verify connection
	ctx2, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()
	if err := client.Ping(ctx2, nil); err != nil {
		return nil, fmt.Errorf("pinging MongoDB: %w", err)
	}

	return &MongoClient{
		client:   client,
		database: client.Database(dbName),
	}, nil
}

// Collection returns a handle to the named collection.
func (m *MongoClient) Collection(name string) *mongo.Collection {
	return m.database.Collection(name)
}

// Disconnect closes the MongoDB connection.
func (m *MongoClient) Disconnect(ctx context.Context) error {
	return m.client.Disconnect(ctx)
}

// EnsureIndexes creates all indexes for the application.
func (m *MongoClient) EnsureIndexes(ctx context.Context) error {
	indexes := map[string][]mongo.IndexModel{
		"users": {
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "tenantId", Value: 1}}, Options: options.Index().SetUnique(true)},
			{Keys: bson.D{{Key: "email", Value: 1}}, Options: options.Index().SetUnique(true)},
		},
		"user_settings": {
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "tenantId", Value: 1}}, Options: options.Index().SetUnique(true)},
		},
		"addictions": {
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "tenantId", Value: 1}}},
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "addictionId", Value: 1}}, Options: options.Index().SetUnique(true)},
		},
		"streaks": {
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "addictionId", Value: 1}}, Options: options.Index().SetUnique(true)},
		},
		"milestones": {
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "addictionId", Value: 1}}},
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "addictionId", Value: 1}, {Key: "days", Value: 1}}, Options: options.Index().SetUnique(true)},
		},
		"relapses": {
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "createdAt", Value: -1}}},
		},
		"check_ins": {
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "createdAt", Value: -1}}},
		},
		"urges": {
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "createdAt", Value: -1}}},
		},
		"journals": {
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "createdAt", Value: -1}}},
			{Keys: bson.D{{Key: "expiresAt", Value: 1}}, Options: options.Index().SetExpireAfterSeconds(0)},
		},
		"meetings": {
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "createdAt", Value: -1}}},
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "timestamp", Value: -1}}},
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "meetingId", Value: 1}}, Options: options.Index().SetUnique(true)},
		},
		"savedMeetings": {
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "savedMeetingId", Value: 1}}, Options: options.Index().SetUnique(true)},
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "isActive", Value: 1}, {Key: "name", Value: 1}}},
		},
		"prayers": {
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "createdAt", Value: -1}}},
			{Keys: bson.D{{Key: "expiresAt", Value: 1}}, Options: options.Index().SetExpireAfterSeconds(0)},
		},
		"exercises": {
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "createdAt", Value: -1}}},
		},
		"activities": {
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "date", Value: 1}}},
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "date", Value: 1}, {Key: "activityType", Value: 1}}},
		},
		"support_contacts": {
			{Keys: bson.D{{Key: "userId", Value: 1}}},
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "contactId", Value: 1}}, Options: options.Index().SetUnique(true)},
		},
		"permissions": {
			{Keys: bson.D{{Key: "userId", Value: 1}}},
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "contactId", Value: 1}}},
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "contactId", Value: 1}, {Key: "dataCategory", Value: 1}}, Options: options.Index().SetUnique(true)},
		},
		"flags": {
			{Keys: bson.D{{Key: "flagKey", Value: 1}}, Options: options.Index().SetUnique(true)},
		},
		"affirmation_packs": {
			{Keys: bson.D{{Key: "packId", Value: 1}}, Options: options.Index().SetUnique(true)},
		},
		"affirmations": {
			{Keys: bson.D{{Key: "packId", Value: 1}}},
		},
		"devotionals": {
			{Keys: bson.D{{Key: "day", Value: 1}}, Options: options.Index().SetUnique(true)},
		},
		"prompts": {
			{Keys: bson.D{{Key: "category", Value: 1}}},
		},
		"commitments": {
			{Keys: bson.D{{Key: "userId", Value: 1}}},
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "commitmentId", Value: 1}}, Options: options.Index().SetUnique(true)},
		},
		"goals": {
			{Keys: bson.D{{Key: "userId", Value: 1}}},
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "goalId", Value: 1}}, Options: options.Index().SetUnique(true)},
		},
		"sessions": {
			{Keys: bson.D{{Key: "sessionId", Value: 1}}, Options: options.Index().SetUnique(true)},
			{Keys: bson.D{{Key: "userId", Value: 1}}},
			{Keys: bson.D{{Key: "expiresAt", Value: 1}}, Options: options.Index().SetExpireAfterSeconds(0)},
		},
		"timeJournalEntries": {
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "date", Value: 1}}},
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "date", Value: 1}, {Key: "slotStart", Value: 1}}, Options: options.Index().SetUnique(true)},
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "createdAt", Value: -1}}},
			{Keys: bson.D{{Key: "tenantId", Value: 1}, {Key: "userId", Value: 1}}},
		},
		"timeJournalDays": {
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "date", Value: -1}}, Options: options.Index().SetUnique(true)},
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "status", Value: 1}, {Key: "date", Value: -1}}},
			{Keys: bson.D{{Key: "userId", Value: 1}, {Key: "streakEligible", Value: 1}, {Key: "date", Value: -1}}},
			{Keys: bson.D{{Key: "tenantId", Value: 1}, {Key: "userId", Value: 1}}},
		},
	}

	for collName, collIndexes := range indexes {
		_, err := m.Collection(collName).Indexes().CreateMany(ctx, collIndexes)
		if err != nil {
			return fmt.Errorf("creating indexes for %s: %w", collName, err)
		}
	}

	return nil
}
