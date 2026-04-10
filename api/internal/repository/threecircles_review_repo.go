// internal/repository/threecircles_review_repo.go
package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// --- Quarterly review operations ---
// AP-TC-30: List reviews for a set
// AP-TC-31: Find incomplete review
// AP-TC-32: Complete review + schedule next

// CreateCircleReview creates a new quarterly review session.
func (r *ThreeCirclesRepo) CreateCircleReview(ctx context.Context, review *CircleReviewDoc) error {
	SetBaseDocumentDefaults(&review.BaseDocument)

	if _, err := r.reviews.InsertOne(ctx, review); err != nil {
		return fmt.Errorf("creating circle review: %w", err)
	}
	return nil
}

// GetCircleReviewByID retrieves a review by reviewId.
func (r *ThreeCirclesRepo) GetCircleReviewByID(ctx context.Context, reviewID string) (*CircleReviewDoc, error) {
	var doc CircleReviewDoc
	err := r.reviews.FindOne(ctx, bson.M{"reviewId": reviewID}).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("circle review %s: not found", reviewID)
		}
		return nil, fmt.Errorf("getting circle review %s: %w", reviewID, err)
	}
	return &doc, nil
}

// ListReviewsForSet retrieves all reviews for a given circle set.
// AP-TC-30: List reviews for a set
func (r *ThreeCirclesRepo) ListReviewsForSet(ctx context.Context, userID string, setID string) ([]CircleReviewDoc, error) {
	filter := bson.M{
		"userId": userID,
		"setId":  setID,
	}

	opts := options.Find().SetSort(bson.D{{Key: "startedAt", Value: -1}})
	cursor, err := r.reviews.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("listing reviews for set %s: %w", setID, err)
	}

	var docs []CircleReviewDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding reviews: %w", err)
	}
	return docs, nil
}

// GetIncompleteReviewForSet retrieves the incomplete review for a set (if any).
// AP-TC-31: Find incomplete review
func (r *ThreeCirclesRepo) GetIncompleteReviewForSet(ctx context.Context, userID string, setID string) (*CircleReviewDoc, error) {
	var doc CircleReviewDoc
	filter := bson.M{
		"userId":    userID,
		"setId":     setID,
		"completed": false,
	}

	err := r.reviews.FindOne(ctx, filter).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil // No incomplete review
		}
		return nil, fmt.Errorf("getting incomplete review: %w", err)
	}
	return &doc, nil
}

// UpdateCircleReview updates an existing review (save progress or mark complete).
// AP-TC-32: Complete review + schedule next
func (r *ThreeCirclesRepo) UpdateCircleReview(ctx context.Context, review *CircleReviewDoc) error {
	UpdateModified(&review.BaseDocument)

	filter := bson.M{"reviewId": review.ReviewID}
	update := bson.M{"$set": review}

	result, err := r.reviews.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("updating circle review %s: %w", review.ReviewID, err)
	}

	if result.MatchedCount == 0 {
		return fmt.Errorf("circle review %s: not found", review.ReviewID)
	}

	return nil
}

// DeleteCircleReview deletes a review (cleanup if review is abandoned).
func (r *ThreeCirclesRepo) DeleteCircleReview(ctx context.Context, reviewID string) error {
	result, err := r.reviews.DeleteOne(ctx, bson.M{"reviewId": reviewID})
	if err != nil {
		return fmt.Errorf("deleting circle review %s: %w", reviewID, err)
	}

	if result.DeletedCount == 0 {
		return fmt.Errorf("circle review %s: not found", reviewID)
	}

	return nil
}
