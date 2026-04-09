// internal/repository/affirmations_hidden_repo.go
package repository

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

// HideAffirmation hides an affirmation from a user's rotation.
// AP-AFF-05: Get user hidden list
// AP-AFF-06: Check if affirmation is hidden
func (r *AffirmationsRepo) HideAffirmation(ctx context.Context, userID, affirmationID string, tenantID string, sessionHideCount int) error {
	if tenantID == "" {
		tenantID = "DEFAULT"
	}

	hidden := AffirmationHiddenDoc{
		UserID:           userID,
		TenantID:         tenantID,
		AffirmationID:    affirmationID,
		HiddenAt:         NowUTC(),
		SessionHideCount: sessionHideCount,
	}

	if _, err := r.hidden.InsertOne(ctx, hidden); err != nil {
		return fmt.Errorf("hiding affirmation for user %s: %w", userID, err)
	}
	return nil
}

// UnhideAffirmation removes an affirmation from the hidden list.
func (r *AffirmationsRepo) UnhideAffirmation(ctx context.Context, userID, affirmationID string) error {
	filter := bson.M{
		"userId":        userID,
		"affirmationId": affirmationID,
	}

	result, err := r.hidden.DeleteOne(ctx, filter)
	if err != nil {
		return fmt.Errorf("unhiding affirmation for user %s: %w", userID, err)
	}

	if result.DeletedCount == 0 {
		return mongo.ErrNoDocuments
	}
	return nil
}

// ListHidden retrieves all hidden affirmations for a user.
// AP-AFF-05: Get user hidden list
func (r *AffirmationsRepo) ListHidden(ctx context.Context, userID string) ([]AffirmationHiddenDoc, error) {
	cursor, err := r.hidden.Find(ctx, bson.M{"userId": userID})
	if err != nil {
		return nil, fmt.Errorf("listing hidden affirmations for user %s: %w", userID, err)
	}

	var hiddenList []AffirmationHiddenDoc
	if err := cursor.All(ctx, &hiddenList); err != nil {
		return nil, fmt.Errorf("decoding hidden affirmations: %w", err)
	}
	return hiddenList, nil
}

// IsHidden checks if an affirmation is hidden by a user.
// AP-AFF-06: Check if affirmation is hidden
func (r *AffirmationsRepo) IsHidden(ctx context.Context, userID, affirmationID string) (bool, error) {
	filter := bson.M{
		"userId":        userID,
		"affirmationId": affirmationID,
	}

	count, err := r.hidden.CountDocuments(ctx, filter)
	if err != nil {
		return false, fmt.Errorf("checking hidden for user %s: %w", userID, err)
	}
	return count > 0, nil
}

// CountHiddenInSession counts how many affirmations were hidden since a given session start time.
// AP-AFF-18: Count hides in current session
func (r *AffirmationsRepo) CountHiddenInSession(ctx context.Context, userID string, sessionStartTime time.Time) (int64, error) {
	filter := bson.M{
		"userId": userID,
		"hiddenAt": bson.M{
			"$gte": sessionStartTime,
		},
	}

	count, err := r.hidden.CountDocuments(ctx, filter)
	if err != nil {
		return 0, fmt.Errorf("counting hidden in session for user %s: %w", userID, err)
	}
	return count, nil
}
