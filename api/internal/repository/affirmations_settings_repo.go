// internal/repository/affirmations_settings_repo.go
package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// GetSettings retrieves affirmation settings for a user.
// AP-AFF-14: Get settings for user
func (r *AffirmationsRepo) GetSettings(ctx context.Context, userID string) (*AffirmationSettingsDoc, error) {
	var settings AffirmationSettingsDoc
	err := r.settings.FindOne(ctx, bson.M{"userId": userID}).Decode(&settings)
	if err != nil {
		return nil, fmt.Errorf("getting settings for user %s: %w", userID, err)
	}
	return &settings, nil
}

// UpsertSettings creates or updates affirmation settings for a user.
func (r *AffirmationsRepo) UpsertSettings(ctx context.Context, settings *AffirmationSettingsDoc) error {
	settings.UpdatedAt = NowUTC()
	if settings.TenantID == "" {
		settings.TenantID = "DEFAULT"
	}

	filter := bson.M{"userId": settings.UserID}
	update := bson.M{"$set": settings}
	opts := options.UpdateOne().SetUpsert(true)

	if _, err := r.settings.UpdateOne(ctx, filter, update, opts); err != nil {
		return fmt.Errorf("upserting settings for user %s: %w", settings.UserID, err)
	}
	return nil
}
