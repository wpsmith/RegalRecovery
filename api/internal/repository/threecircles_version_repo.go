// internal/repository/threecircles_version_repo.go
package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// --- Version History operations ---
// AP-TC-06: List versions for a set
// AP-TC-07: Get specific version
// AP-TC-08: Get latest version

// CreateCircleSetVersion creates a new version snapshot (append-only, immutable).
func (r *ThreeCirclesRepo) CreateCircleSetVersion(ctx context.Context, version *CircleSetVersionDoc) error {
	SetBaseDocumentDefaults(&version.BaseDocument)

	if _, err := r.versions.InsertOne(ctx, version); err != nil {
		return fmt.Errorf("creating circle set version: %w", err)
	}
	return nil
}

// ListVersionsForSet retrieves all versions for a given set, sorted by version number descending.
// AP-TC-06: List versions for a set
func (r *ThreeCirclesRepo) ListVersionsForSet(ctx context.Context, setID string) ([]CircleSetVersionDoc, error) {
	filter := bson.M{"setId": setID}
	opts := options.Find().SetSort(bson.D{{Key: "versionNumber", Value: -1}})

	cursor, err := r.versions.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("listing versions for set %s: %w", setID, err)
	}

	var docs []CircleSetVersionDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding versions: %w", err)
	}
	return docs, nil
}

// GetCircleSetVersion retrieves a specific version by setId and versionNumber.
// AP-TC-07: Get specific version
func (r *ThreeCirclesRepo) GetCircleSetVersion(ctx context.Context, setID string, versionNumber int) (*CircleSetVersionDoc, error) {
	var doc CircleSetVersionDoc
	filter := bson.M{
		"setId":         setID,
		"versionNumber": versionNumber,
	}

	err := r.versions.FindOne(ctx, filter).Decode(&doc)
	if err != nil {
		return nil, fmt.Errorf("getting version %d for set %s: %w", versionNumber, setID, err)
	}
	return &doc, nil
}

// GetLatestCircleSetVersion retrieves the most recent version for a set.
// AP-TC-08: Get latest version
func (r *ThreeCirclesRepo) GetLatestCircleSetVersion(ctx context.Context, setID string) (*CircleSetVersionDoc, error) {
	var doc CircleSetVersionDoc
	filter := bson.M{"setId": setID}
	opts := options.FindOne().SetSort(bson.D{{Key: "versionNumber", Value: -1}})

	err := r.versions.FindOne(ctx, filter, opts).Decode(&doc)
	if err != nil {
		return nil, fmt.Errorf("getting latest version for set %s: %w", setID, err)
	}
	return &doc, nil
}
