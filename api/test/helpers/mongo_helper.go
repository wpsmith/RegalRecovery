// test/helpers/mongo_helper.go
package helpers

import (
	"context"
	"testing"

	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// SetupLocalMongo creates a MongoDB client connected to localhost:27017.
func SetupLocalMongo(t *testing.T) *mongo.Client {
	t.Helper()

	client, err := mongo.Connect(options.Client().ApplyURI("mongodb://localhost:27017"))
	if err != nil {
		t.Fatalf("failed to connect to MongoDB: %v", err)
	}

	ctx := context.Background()
	if err := client.Ping(ctx, nil); err != nil {
		t.Fatalf("failed to ping MongoDB: %v", err)
	}

	return client
}

// SetupTestDatabase creates a test database with a unique name for test isolation.
func SetupTestDatabase(t *testing.T, client *mongo.Client) *mongo.Database {
	t.Helper()

	dbName := "regal-recovery-test"
	return client.Database(dbName)
}

// CleanupDatabase drops all collections in the database.
func CleanupDatabase(t *testing.T, db *mongo.Database) {
	t.Helper()

	ctx := context.Background()

	collections, err := db.ListCollectionNames(ctx, map[string]interface{}{})
	if err != nil {
		t.Fatalf("failed to list collections: %v", err)
	}

	for _, coll := range collections {
		if err := db.Collection(coll).Drop(ctx); err != nil {
			t.Fatalf("failed to drop collection %s: %v", coll, err)
		}
	}
}
