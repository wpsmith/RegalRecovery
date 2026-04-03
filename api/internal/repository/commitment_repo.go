// internal/repository/commitment_repo.go
package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
)

// CommitmentRepo implements CommitmentRepository using MongoDB.
type CommitmentRepo struct {
	client *MongoClient
}

// NewCommitmentRepo creates a new CommitmentRepo.
func NewCommitmentRepo(client *MongoClient) *CommitmentRepo {
	return &CommitmentRepo{client: client}
}

// ListCommitments lists all commitments for a user.
func (r *CommitmentRepo) ListCommitments(ctx context.Context, userID string) ([]Commitment, error) {
	cursor, err := r.client.Collection("commitments").Find(ctx, bson.M{"userId": userID})
	if err != nil {
		return nil, fmt.Errorf("listing commitments for user %s: %w", userID, err)
	}

	var commitments []Commitment
	if err := cursor.All(ctx, &commitments); err != nil {
		return nil, fmt.Errorf("decoding commitments for user %s: %w", userID, err)
	}

	return commitments, nil
}

// GetCommitment retrieves a specific commitment by ID.
func (r *CommitmentRepo) GetCommitment(ctx context.Context, userID, commitmentID string) (*Commitment, error) {
	var commitment Commitment
	err := r.client.Collection("commitments").FindOne(ctx, bson.M{
		"userId":       userID,
		"commitmentId": commitmentID,
	}).Decode(&commitment)
	if err != nil {
		return nil, fmt.Errorf("getting commitment %s for user %s: %w", commitmentID, userID, err)
	}
	return &commitment, nil
}

// CreateCommitment creates a new commitment.
func (r *CommitmentRepo) CreateCommitment(ctx context.Context, commitment *Commitment) error {
	SetBaseDocumentDefaults(&commitment.BaseDocument)

	if _, err := r.client.Collection("commitments").InsertOne(ctx, commitment); err != nil {
		return fmt.Errorf("creating commitment: %w", err)
	}

	return nil
}

// UpdateCommitment updates an existing commitment.
func (r *CommitmentRepo) UpdateCommitment(ctx context.Context, commitment *Commitment) error {
	UpdateModified(&commitment.BaseDocument)

	if _, err := r.client.Collection("commitments").ReplaceOne(ctx, bson.M{
		"userId":       commitment.UserID,
		"commitmentId": commitment.CommitmentID,
	}, commitment); err != nil {
		return fmt.Errorf("updating commitment: %w", err)
	}

	return nil
}
