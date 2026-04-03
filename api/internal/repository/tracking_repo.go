// internal/repository/tracking_repo.go
package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// TrackingRepo implements TrackingRepository using MongoDB.
type TrackingRepo struct {
	client *MongoClient
}

// NewTrackingRepo creates a new TrackingRepo.
func NewTrackingRepo(client *MongoClient) *TrackingRepo {
	return &TrackingRepo{client: client}
}

// GetStreak retrieves the current streak for an addiction.
func (r *TrackingRepo) GetStreak(ctx context.Context, userID, addictionID string) (*Streak, error) {
	var streak Streak
	err := r.client.Collection("streaks").FindOne(ctx, bson.M{"userId": userID, "addictionId": addictionID}).Decode(&streak)
	if err != nil {
		return nil, fmt.Errorf("getting streak for user %s addiction %s: %w", userID, addictionID, err)
	}
	return &streak, nil
}

// UpdateStreak updates the streak record, creating it if it doesn't exist.
func (r *TrackingRepo) UpdateStreak(ctx context.Context, streak *Streak) error {
	UpdateModified(&streak.BaseDocument)

	opts := options.Replace().SetUpsert(true)
	if _, err := r.client.Collection("streaks").ReplaceOne(ctx, bson.M{"userId": streak.UserID, "addictionId": streak.AddictionID}, streak, opts); err != nil {
		return fmt.Errorf("updating streak: %w", err)
	}
	return nil
}

// RecordRelapse records a relapse event.
func (r *TrackingRepo) RecordRelapse(ctx context.Context, userID string, relapse *Relapse) error {
	relapse.UserID = userID
	SetBaseDocumentDefaults(&relapse.BaseDocument)

	if _, err := r.client.Collection("relapses").InsertOne(ctx, relapse); err != nil {
		return fmt.Errorf("recording relapse: %w", err)
	}
	return nil
}

// GetMilestones retrieves all milestones for a user.
func (r *TrackingRepo) GetMilestones(ctx context.Context, userID string) ([]Milestone, error) {
	cursor, err := r.client.Collection("milestones").Find(ctx, bson.M{"userId": userID})
	if err != nil {
		return nil, fmt.Errorf("listing milestones for user %s: %w", userID, err)
	}

	var milestones []Milestone
	if err := cursor.All(ctx, &milestones); err != nil {
		return nil, fmt.Errorf("decoding milestones: %w", err)
	}
	return milestones, nil
}

// GetMilestonesForAddiction retrieves milestones for a specific addiction.
func (r *TrackingRepo) GetMilestonesForAddiction(ctx context.Context, userID, addictionID string) ([]Milestone, error) {
	cursor, err := r.client.Collection("milestones").Find(ctx, bson.M{"userId": userID, "addictionId": addictionID})
	if err != nil {
		return nil, fmt.Errorf("listing milestones for user %s addiction %s: %w", userID, addictionID, err)
	}

	var milestones []Milestone
	if err := cursor.All(ctx, &milestones); err != nil {
		return nil, fmt.Errorf("decoding milestones: %w", err)
	}
	return milestones, nil
}

// CreateMilestone creates a new milestone record.
func (r *TrackingRepo) CreateMilestone(ctx context.Context, userID string, milestone *Milestone) error {
	milestone.UserID = userID
	SetBaseDocumentDefaults(&milestone.BaseDocument)

	if _, err := r.client.Collection("milestones").InsertOne(ctx, milestone); err != nil {
		return fmt.Errorf("creating milestone: %w", err)
	}
	return nil
}

// GetRelapseHistory retrieves relapse history for a user, sorted newest first.
func (r *TrackingRepo) GetRelapseHistory(ctx context.Context, userID string, limit int) ([]Relapse, error) {
	opts := options.Find().SetSort(bson.D{{Key: "createdAt", Value: -1}}).SetLimit(int64(limit))
	cursor, err := r.client.Collection("relapses").Find(ctx, bson.M{"userId": userID}, opts)
	if err != nil {
		return nil, fmt.Errorf("listing relapse history for user %s: %w", userID, err)
	}

	var relapses []Relapse
	if err := cursor.All(ctx, &relapses); err != nil {
		return nil, fmt.Errorf("decoding relapses: %w", err)
	}
	return relapses, nil
}
