// internal/repository/threecircles_set_repo.go
package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// --- Circle Set CRUD operations ---
// AP-TC-01: List user's circle sets
// AP-TC-02: Get circle set by setId
// AP-TC-03: List sets by recovery area
// AP-TC-04: Find sets due for review
// AP-TC-05: Update circle set status

// CreateCircleSet creates a new circle set in the database.
func (r *ThreeCirclesRepo) CreateCircleSet(ctx context.Context, set *CircleSetDoc) error {
	SetBaseDocumentDefaults(&set.BaseDocument)

	if _, err := r.sets.InsertOne(ctx, set); err != nil {
		return fmt.Errorf("creating circle set: %w", err)
	}
	return nil
}

// GetCircleSetByID retrieves a circle set by setId.
// AP-TC-02: Get circle set by setId
func (r *ThreeCirclesRepo) GetCircleSetByID(ctx context.Context, setID string) (*CircleSetDoc, error) {
	var doc CircleSetDoc
	err := r.sets.FindOne(ctx, bson.M{"setId": setID}).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("circle set %s: not found", setID)
		}
		return nil, fmt.Errorf("getting circle set %s: %w", setID, err)
	}
	return &doc, nil
}

// ListCircleSetsByUser retrieves all circle sets for a user, optionally filtered by status.
// AP-TC-01: List user's circle sets
func (r *ThreeCirclesRepo) ListCircleSetsByUser(ctx context.Context, userID string, status *string) ([]CircleSetDoc, error) {
	filter := bson.M{"userId": userID}
	if status != nil {
		filter["status"] = *status
	}

	opts := options.Find().SetSort(bson.D{{Key: "modifiedAt", Value: -1}})
	cursor, err := r.sets.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("listing circle sets for user %s: %w", userID, err)
	}

	var docs []CircleSetDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding circle sets: %w", err)
	}
	return docs, nil
}

// ListCircleSetsByRecoveryArea retrieves circle sets filtered by recovery area.
// AP-TC-03: List sets by recovery area
func (r *ThreeCirclesRepo) ListCircleSetsByRecoveryArea(ctx context.Context, userID string, recoveryArea string) ([]CircleSetDoc, error) {
	filter := bson.M{
		"userId":       userID,
		"recoveryArea": recoveryArea,
	}

	opts := options.Find().SetSort(bson.D{{Key: "modifiedAt", Value: -1}})
	cursor, err := r.sets.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("listing circle sets by recovery area: %w", err)
	}

	var docs []CircleSetDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding circle sets: %w", err)
	}
	return docs, nil
}

// ListCircleSetsDueForReview finds circle sets with nextReviewDue <= now.
// AP-TC-04: Find sets due for review
func (r *ThreeCirclesRepo) ListCircleSetsDueForReview(ctx context.Context, userID string, nowISO string) ([]CircleSetDoc, error) {
	filter := bson.M{
		"userId":        userID,
		"nextReviewDue": bson.M{"$lte": nowISO, "$ne": nil},
	}

	opts := options.Find().SetSort(bson.D{{Key: "nextReviewDue", Value: 1}})
	cursor, err := r.sets.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("listing circle sets due for review: %w", err)
	}

	var docs []CircleSetDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding circle sets: %w", err)
	}
	return docs, nil
}

// UpdateCircleSet updates an existing circle set document.
// AP-TC-05: Update circle set status
func (r *ThreeCirclesRepo) UpdateCircleSet(ctx context.Context, set *CircleSetDoc) error {
	UpdateModified(&set.BaseDocument)

	filter := bson.M{"setId": set.SetID}
	update := bson.M{"$set": set}

	result, err := r.sets.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("updating circle set %s: %w", set.SetID, err)
	}

	if result.MatchedCount == 0 {
		return fmt.Errorf("circle set %s: not found", set.SetID)
	}

	return nil
}

// DeleteCircleSet deletes a circle set by ID (soft-delete via archive is preferred).
func (r *ThreeCirclesRepo) DeleteCircleSet(ctx context.Context, setID string) error {
	result, err := r.sets.DeleteOne(ctx, bson.M{"setId": setID})
	if err != nil {
		return fmt.Errorf("deleting circle set %s: %w", setID, err)
	}

	if result.DeletedCount == 0 {
		return fmt.Errorf("circle set %s: not found", setID)
	}

	return nil
}
