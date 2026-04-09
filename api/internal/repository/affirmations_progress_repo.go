// internal/repository/affirmations_progress_repo.go
package repository

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// GetProgress retrieves affirmation progress metrics for a user.
// AP-AFF-12: Get progress metrics for user
// AP-AFF-13: Get level info and history
func (r *AffirmationsRepo) GetProgress(ctx context.Context, userID string) (*AffirmationProgressDoc, error) {
	var progress AffirmationProgressDoc
	err := r.progress.FindOne(ctx, bson.M{"userId": userID}).Decode(&progress)
	if err != nil {
		return nil, fmt.Errorf("getting progress for user %s: %w", userID, err)
	}
	return &progress, nil
}

// UpsertProgress creates or updates affirmation progress for a user.
func (r *AffirmationsRepo) UpsertProgress(ctx context.Context, progress *AffirmationProgressDoc) error {
	progress.UpdatedAt = NowUTC()
	if progress.TenantID == "" {
		progress.TenantID = "DEFAULT"
	}

	filter := bson.M{"userId": progress.UserID}
	update := bson.M{"$set": progress}
	opts := options.UpdateOne().SetUpsert(true)

	if _, err := r.progress.UpdateOne(ctx, filter, update, opts); err != nil {
		return fmt.Errorf("upserting progress for user %s: %w", progress.UserID, err)
	}
	return nil
}

// IncrementSessionCount increments the session count for a user.
func (r *AffirmationsRepo) IncrementSessionCount(ctx context.Context, userID string, sessionType string) error {
	filter := bson.M{"userId": userID}

	incFields := bson.M{
		"totalSessions": 1,
	}

	// Also increment SOS session counter if applicable
	if sessionType == "sos" {
		incFields["totalSOSSessions"] = 1
	}

	update := bson.M{
		"$inc": incFields,
		"$set": bson.M{
			"lastSessionAt": NowUTC(),
			"updatedAt":     NowUTC(),
		},
	}

	opts := options.UpdateOne().SetUpsert(true)
	if _, err := r.progress.UpdateOne(ctx, filter, update, opts); err != nil {
		return fmt.Errorf("incrementing session count for user %s: %w", userID, err)
	}
	return nil
}

// IncrementAffirmationCount increments the total affirmations practiced count.
func (r *AffirmationsRepo) IncrementAffirmationCount(ctx context.Context, userID string, count int) error {
	filter := bson.M{"userId": userID}
	update := bson.M{
		"$inc": bson.M{
			"totalAffirmationsPracticed": count,
		},
		"$set": bson.M{
			"updatedAt": NowUTC(),
		},
	}

	opts := options.UpdateOne().SetUpsert(true)
	if _, err := r.progress.UpdateOne(ctx, filter, update, opts); err != nil {
		return fmt.Errorf("incrementing affirmation count for user %s: %w", userID, err)
	}
	return nil
}

// RecordMilestone records a milestone achievement for a user.
// AP-AFF-22: Get milestone achievements
func (r *AffirmationsRepo) RecordMilestone(ctx context.Context, userID string, milestoneType string, achievedAt time.Time) error {
	filter := bson.M{"userId": userID}
	update := bson.M{
		"$addToSet": bson.M{
			"milestones": MilestoneDoc{
				Type:       milestoneType,
				AchievedAt: achievedAt,
			},
		},
		"$set": bson.M{
			"updatedAt": NowUTC(),
		},
	}

	opts := options.UpdateOne().SetUpsert(true)
	if _, err := r.progress.UpdateOne(ctx, filter, update, opts); err != nil {
		return fmt.Errorf("recording milestone %s for user %s: %w", milestoneType, userID, err)
	}
	return nil
}

// UpdateLastServedAffirmations updates the 7-day no-repeat window of served affirmation IDs.
// AP-AFF-19: Get last 7 days served affirmations
func (r *AffirmationsRepo) UpdateLastServedAffirmations(ctx context.Context, userID string, affirmationIDs []string, timestamp time.Time) error {
	// Get current progress to build the new list
	progress, err := r.GetProgress(ctx, userID)
	if err != nil {
		// If progress doesn't exist yet, create it
		progress = &AffirmationProgressDoc{
			UserID:                   userID,
			TenantID:                 "DEFAULT",
			LastServedAffirmationIds: []string{},
		}
	}

	// Append new IDs to the list
	updatedIDs := append(progress.LastServedAffirmationIds, affirmationIDs...)

	// Remove duplicates
	idSet := make(map[string]bool)
	uniqueIDs := make([]string, 0)
	for _, id := range updatedIDs {
		if !idSet[id] {
			idSet[id] = true
			uniqueIDs = append(uniqueIDs, id)
		}
	}

	filter := bson.M{"userId": userID}
	update := bson.M{
		"$set": bson.M{
			"lastServedAffirmationIds": uniqueIDs,
			"lastSessionAt":            timestamp,
			"updatedAt":                NowUTC(),
		},
	}

	opts := options.UpdateOne().SetUpsert(true)
	if _, err := r.progress.UpdateOne(ctx, filter, update, opts); err != nil {
		return fmt.Errorf("updating last served affirmations for user %s: %w", userID, err)
	}
	return nil
}

// RecordLevelChange records a level transition in the level history.
func (r *AffirmationsRepo) RecordLevelChange(ctx context.Context, userID string, newLevel int, timestamp time.Time) error {
	// First, close out the current level (set endedAt on the latest entry)
	progress, err := r.GetProgress(ctx, userID)
	if err != nil {
		// If progress doesn't exist yet, create it
		progress = &AffirmationProgressDoc{
			UserID:       userID,
			TenantID:     "DEFAULT",
			LevelHistory: []LevelHistoryEntryDoc{},
		}
	}

	// Close current level
	if len(progress.LevelHistory) > 0 {
		progress.LevelHistory[len(progress.LevelHistory)-1].EndedAt = &timestamp
	}

	// Add new level entry
	progress.LevelHistory = append(progress.LevelHistory, LevelHistoryEntryDoc{
		Level:     newLevel,
		StartedAt: timestamp,
		EndedAt:   nil,
	})

	filter := bson.M{"userId": userID}
	update := bson.M{
		"$set": bson.M{
			"currentLevel":       newLevel,
			"daysAtCurrentLevel": 0,
			"levelHistory":       progress.LevelHistory,
			"updatedAt":          NowUTC(),
		},
	}

	opts := options.UpdateOne().SetUpsert(true)
	if _, err := r.progress.UpdateOne(ctx, filter, update, opts); err != nil {
		return fmt.Errorf("recording level change for user %s: %w", userID, err)
	}
	return nil
}
