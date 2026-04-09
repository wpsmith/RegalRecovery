// internal/repository/affirmations_session_repo.go
package repository

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// CreateSession creates a new affirmation session.
func (r *AffirmationsRepo) CreateSession(ctx context.Context, session *AffirmationSessionDoc) error {
	SetBaseDocumentDefaults(&session.BaseDocument)

	if _, err := r.sessions.InsertOne(ctx, session); err != nil {
		return fmt.Errorf("creating affirmation session: %w", err)
	}
	return nil
}

// GetSession retrieves an affirmation session by session ID.
func (r *AffirmationsRepo) GetSession(ctx context.Context, sessionID string) (*AffirmationSessionDoc, error) {
	var session AffirmationSessionDoc
	err := r.sessions.FindOne(ctx, bson.M{"sessionId": sessionID}).Decode(&session)
	if err != nil {
		return nil, fmt.Errorf("getting affirmation session %s: %w", sessionID, err)
	}
	return &session, nil
}

// ListSessions retrieves all sessions for a user, sorted newest first.
// AP-AFF-15: Session history reverse-chronological
func (r *AffirmationsRepo) ListSessions(ctx context.Context, userID string, limit int) ([]AffirmationSessionDoc, error) {
	opts := options.Find().
		SetSort(bson.D{{Key: "createdAt", Value: -1}}).
		SetLimit(int64(limit))

	cursor, err := r.sessions.Find(ctx, bson.M{"userId": userID}, opts)
	if err != nil {
		return nil, fmt.Errorf("listing sessions for user %s: %w", userID, err)
	}

	var sessions []AffirmationSessionDoc
	if err := cursor.All(ctx, &sessions); err != nil {
		return nil, fmt.Errorf("decoding sessions: %w", err)
	}
	return sessions, nil
}

// ListSessionsByTypeAndDateRange retrieves sessions filtered by type and date range.
// AP-AFF-11: Get session history by type and date range
func (r *AffirmationsRepo) ListSessionsByTypeAndDateRange(ctx context.Context, userID, sessionType string, startDate, endDate time.Time, limit int) ([]AffirmationSessionDoc, error) {
	filter := bson.M{
		"userId":      userID,
		"sessionType": sessionType,
		"completedAt": bson.M{
			"$gte": startDate,
			"$lte": endDate,
		},
	}

	opts := options.Find().
		SetSort(bson.D{{Key: "completedAt", Value: -1}}).
		SetLimit(int64(limit))

	cursor, err := r.sessions.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("listing sessions for user %s type %s: %w", userID, sessionType, err)
	}

	var sessions []AffirmationSessionDoc
	if err := cursor.All(ctx, &sessions); err != nil {
		return nil, fmt.Errorf("decoding sessions: %w", err)
	}
	return sessions, nil
}

// CountSessionsInDateRange counts sessions within a date range.
// AP-AFF-15: Count sessions in date range
func (r *AffirmationsRepo) CountSessionsInDateRange(ctx context.Context, userID string, startDate, endDate time.Time) (int64, error) {
	filter := bson.M{
		"userId": userID,
		"createdAt": bson.M{
			"$gte": startDate,
			"$lte": endDate,
		},
	}

	count, err := r.sessions.CountDocuments(ctx, filter)
	if err != nil {
		return 0, fmt.Errorf("counting sessions for user %s: %w", userID, err)
	}
	return count, nil
}

// GetRecentSessionAffirmationIDs retrieves affirmation IDs from sessions in the last N days.
// AP-AFF-12: Get recent session affirmation IDs (7-day no-repeat window)
func (r *AffirmationsRepo) GetRecentSessionAffirmationIDs(ctx context.Context, userID string, days int) ([]string, error) {
	cutoffTime := time.Now().UTC().AddDate(0, 0, -days)
	filter := bson.M{
		"userId": userID,
		"createdAt": bson.M{
			"$gte": cutoffTime,
		},
	}

	cursor, err := r.sessions.Find(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("getting recent sessions for user %s: %w", userID, err)
	}

	var sessions []AffirmationSessionDoc
	if err := cursor.All(ctx, &sessions); err != nil {
		return nil, fmt.Errorf("decoding sessions: %w", err)
	}

	// Collect all affirmation IDs from sessions
	idSet := make(map[string]bool)
	for _, session := range sessions {
		for _, id := range session.AffirmationIDs {
			idSet[id] = true
		}
	}

	ids := make([]string, 0, len(idSet))
	for id := range idSet {
		ids = append(ids, id)
	}
	return ids, nil
}

// GetEveningSessionsByDateRange retrieves evening sessions with day ratings within a date range.
// AP-AFF-24: Get daily mood ratings from evening sessions
func (r *AffirmationsRepo) GetEveningSessionsByDateRange(ctx context.Context, userID string, startDate, endDate time.Time) ([]AffirmationSessionDoc, error) {
	filter := bson.M{
		"userId":      userID,
		"sessionType": "evening",
		"dayRating":   bson.M{"$ne": nil},
		"completedAt": bson.M{
			"$gte": startDate,
			"$lte": endDate,
		},
	}

	opts := options.Find().SetSort(bson.D{{Key: "completedAt", Value: 1}})
	cursor, err := r.sessions.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("getting evening sessions for user %s: %w", userID, err)
	}

	var sessions []AffirmationSessionDoc
	if err := cursor.All(ctx, &sessions); err != nil {
		return nil, fmt.Errorf("decoding evening sessions: %w", err)
	}
	return sessions, nil
}

// GetMorningSessionForDate retrieves the morning session for a specific date.
// AP-AFF-22: Get morning intention for today (for evening session)
func (r *AffirmationsRepo) GetMorningSessionForDate(ctx context.Context, userID, date string) (*AffirmationSessionDoc, error) {
	// Parse date as start of day
	startOfDay, err := time.Parse("2006-01-02", date)
	if err != nil {
		return nil, fmt.Errorf("parsing date %s: %w", date, err)
	}
	endOfDay := startOfDay.Add(24 * time.Hour)

	filter := bson.M{
		"userId":      userID,
		"sessionType": "morning",
		"completedAt": bson.M{
			"$gte": startOfDay,
			"$lt":  endOfDay,
		},
	}

	var session AffirmationSessionDoc
	err = r.sessions.FindOne(ctx, filter).Decode(&session)
	if err != nil {
		return nil, fmt.Errorf("getting morning session for date %s: %w", date, err)
	}
	return &session, nil
}
