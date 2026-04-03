// internal/repository/session_repo.go
package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
)

// SessionRepo implements SessionRepository using MongoDB.
type SessionRepo struct {
	client *MongoClient
}

// NewSessionRepo creates a new SessionRepo.
func NewSessionRepo(client *MongoClient) *SessionRepo {
	return &SessionRepo{client: client}
}

// CreateSession creates a new session.
func (r *SessionRepo) CreateSession(ctx context.Context, session *Session) error {
	SetBaseDocumentDefaults(&session.BaseDocument)

	if _, err := r.client.Collection("sessions").InsertOne(ctx, session); err != nil {
		return fmt.Errorf("creating session: %w", err)
	}
	return nil
}

// GetSessionByID retrieves a session by session ID.
func (r *SessionRepo) GetSessionByID(ctx context.Context, sessionID string) (*Session, error) {
	var session Session
	err := r.client.Collection("sessions").FindOne(ctx, bson.M{"sessionId": sessionID}).Decode(&session)
	if err != nil {
		return nil, fmt.Errorf("getting session %s: %w", sessionID, err)
	}
	return &session, nil
}

// ListUserSessions lists all sessions for a user.
func (r *SessionRepo) ListUserSessions(ctx context.Context, userID string) ([]Session, error) {
	cursor, err := r.client.Collection("sessions").Find(ctx, bson.M{"userId": userID})
	if err != nil {
		return nil, fmt.Errorf("listing sessions for user %s: %w", userID, err)
	}

	var sessions []Session
	if err := cursor.All(ctx, &sessions); err != nil {
		return nil, fmt.Errorf("decoding sessions: %w", err)
	}
	return sessions, nil
}

// DeleteSession deletes a session.
func (r *SessionRepo) DeleteSession(ctx context.Context, userID, sessionID string) error {
	if _, err := r.client.Collection("sessions").DeleteOne(ctx, bson.M{"userId": userID, "sessionId": sessionID}); err != nil {
		return fmt.Errorf("deleting session %s for user %s: %w", sessionID, userID, err)
	}
	return nil
}
