// internal/repository/threecircles_share_repo.go
package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// --- Share link operations ---
// AP-TC-17: Get share by code (public)
// AP-TC-18: List active shares for a set
// AP-TC-19: List comments by share code
// AP-TC-20: Get unread comments for set
// AP-TC-21: Mark comments as read

// CreateCircleShare creates a new share link for sponsor review.
func (r *ThreeCirclesRepo) CreateCircleShare(ctx context.Context, share *CircleShareDoc) error {
	SetBaseDocumentDefaults(&share.BaseDocument)

	if _, err := r.shares.InsertOne(ctx, share); err != nil {
		return fmt.Errorf("creating circle share: %w", err)
	}
	return nil
}

// GetCircleShareByCode retrieves a share by its public share code.
// AP-TC-17: Get share by code (public)
func (r *ThreeCirclesRepo) GetCircleShareByCode(ctx context.Context, shareCode string) (*CircleShareDoc, error) {
	var doc CircleShareDoc
	filter := bson.M{
		"shareCode": shareCode,
		"active":    true,
	}

	err := r.shares.FindOne(ctx, filter).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("share code %s: not found or inactive", shareCode)
		}
		return nil, fmt.Errorf("getting share by code: %w", err)
	}
	return &doc, nil
}

// ListActiveSharesForSet retrieves all active shares for a given circle set.
// AP-TC-18: List active shares for a set
func (r *ThreeCirclesRepo) ListActiveSharesForSet(ctx context.Context, setID string) ([]CircleShareDoc, error) {
	filter := bson.M{
		"setId":  setID,
		"active": true,
	}

	opts := options.Find().SetSort(bson.D{{Key: "createdAt", Value: -1}})
	cursor, err := r.shares.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("listing active shares for set %s: %w", setID, err)
	}

	var docs []CircleShareDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding shares: %w", err)
	}
	return docs, nil
}

// UpdateCircleShare updates an existing share (e.g., revoke by setting active=false).
func (r *ThreeCirclesRepo) UpdateCircleShare(ctx context.Context, share *CircleShareDoc) error {
	UpdateModified(&share.BaseDocument)

	filter := bson.M{"shareId": share.ShareID}
	update := bson.M{"$set": share}

	result, err := r.shares.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("updating share %s: %w", share.ShareID, err)
	}

	if result.MatchedCount == 0 {
		return fmt.Errorf("share %s: not found", share.ShareID)
	}

	return nil
}

// DeleteCircleShare deletes a share link.
func (r *ThreeCirclesRepo) DeleteCircleShare(ctx context.Context, shareID string) error {
	result, err := r.shares.DeleteOne(ctx, bson.M{"shareId": shareID})
	if err != nil {
		return fmt.Errorf("deleting share %s: %w", shareID, err)
	}

	if result.DeletedCount == 0 {
		return fmt.Errorf("share %s: not found", shareID)
	}

	return nil
}

// --- Sponsor comment operations ---

// CreateSponsorComment creates a new sponsor comment on a circle item (public write).
func (r *ThreeCirclesRepo) CreateSponsorComment(ctx context.Context, comment *CircleSponsorCommentDoc) error {
	SetBaseDocumentDefaults(&comment.BaseDocument)

	if _, err := r.comments.InsertOne(ctx, comment); err != nil {
		return fmt.Errorf("creating sponsor comment: %w", err)
	}

	// Increment comment count on the share document.
	shareFilter := bson.M{"shareId": comment.ShareID}
	shareUpdate := bson.M{"$inc": bson.M{"commentCount": 1}}
	if _, err := r.shares.UpdateOne(ctx, shareFilter, shareUpdate); err != nil {
		// Log but don't fail; count can drift slightly.
		fmt.Printf("failed to increment share comment count: %v\n", err)
	}

	return nil
}

// ListCommentsByShareCode retrieves all comments for a given share code.
// AP-TC-19: List comments by share code
func (r *ThreeCirclesRepo) ListCommentsByShareCode(ctx context.Context, shareCode string) ([]CircleSponsorCommentDoc, error) {
	filter := bson.M{"shareCode": shareCode}
	opts := options.Find().SetSort(bson.D{{Key: "createdAt", Value: -1}})

	cursor, err := r.comments.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("listing comments by share code: %w", err)
	}

	var docs []CircleSponsorCommentDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding comments: %w", err)
	}
	return docs, nil
}

// GetUnreadCommentsForSet retrieves unread comments for a specific circle set.
// AP-TC-20: Get unread comments for set
func (r *ThreeCirclesRepo) GetUnreadCommentsForSet(ctx context.Context, userID string, setID string) ([]CircleSponsorCommentDoc, error) {
	filter := bson.M{
		"userId": userID,
		"setId":  setID,
		"read":   false,
	}

	opts := options.Find().SetSort(bson.D{{Key: "createdAt", Value: -1}})
	cursor, err := r.comments.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("getting unread comments: %w", err)
	}

	var docs []CircleSponsorCommentDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding unread comments: %w", err)
	}
	return docs, nil
}

// CountUnreadCommentsForSet counts unread comments for a set.
func (r *ThreeCirclesRepo) CountUnreadCommentsForSet(ctx context.Context, userID string, setID string) (int64, error) {
	filter := bson.M{
		"userId": userID,
		"setId":  setID,
		"read":   false,
	}

	count, err := r.comments.CountDocuments(ctx, filter)
	if err != nil {
		return 0, fmt.Errorf("counting unread comments: %w", err)
	}
	return count, nil
}

// MarkCommentsAsRead marks all comments for a set as read.
// AP-TC-21: Mark comments as read
func (r *ThreeCirclesRepo) MarkCommentsAsRead(ctx context.Context, userID string, setID string) error {
	filter := bson.M{
		"userId": userID,
		"setId":  setID,
		"read":   false,
	}
	update := bson.M{"$set": bson.M{"read": true}}

	_, err := r.comments.UpdateMany(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("marking comments as read: %w", err)
	}
	return nil
}
