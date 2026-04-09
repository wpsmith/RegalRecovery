// internal/repository/affirmations_audio_repo.go
package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

// SaveAudioMetadata saves metadata for an audio recording.
// AP-AFF-20: Get audio recording metadata
func (r *AffirmationsRepo) SaveAudioMetadata(ctx context.Context, audio *AffirmationAudioDoc) error {
	SetBaseDocumentDefaults(&audio.BaseDocument)

	if _, err := r.audio.InsertOne(ctx, audio); err != nil {
		return fmt.Errorf("saving audio metadata: %w", err)
	}
	return nil
}

// GetAudioMetadata retrieves audio metadata for a specific user and affirmation.
// AP-AFF-20: Get audio recording metadata
func (r *AffirmationsRepo) GetAudioMetadata(ctx context.Context, userID, affirmationID string) (*AffirmationAudioDoc, error) {
	var audio AffirmationAudioDoc
	err := r.audio.FindOne(ctx, bson.M{
		"userId":        userID,
		"affirmationId": affirmationID,
	}).Decode(&audio)
	if err != nil {
		return nil, fmt.Errorf("getting audio metadata for user %s affirmation %s: %w", userID, affirmationID, err)
	}
	return &audio, nil
}

// DeleteAudioMetadata deletes audio metadata by recording ID.
func (r *AffirmationsRepo) DeleteAudioMetadata(ctx context.Context, recordingID string) error {
	result, err := r.audio.DeleteOne(ctx, bson.M{"recordingId": recordingID})
	if err != nil {
		return fmt.Errorf("deleting audio metadata %s: %w", recordingID, err)
	}

	if result.DeletedCount == 0 {
		return mongo.ErrNoDocuments
	}
	return nil
}

// ListAudioByUser retrieves all audio recordings for a user.
func (r *AffirmationsRepo) ListAudioByUser(ctx context.Context, userID string) ([]AffirmationAudioDoc, error) {
	cursor, err := r.audio.Find(ctx, bson.M{"userId": userID})
	if err != nil {
		return nil, fmt.Errorf("listing audio for user %s: %w", userID, err)
	}

	var audios []AffirmationAudioDoc
	if err := cursor.All(ctx, &audios); err != nil {
		return nil, fmt.Errorf("decoding audio metadata: %w", err)
	}
	return audios, nil
}
