// internal/repository/session_repo.go
package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
)

// SessionRepo implements SessionRepository using DynamoDB.
type SessionRepo struct {
	client *DynamoClient
}

// NewSessionRepo creates a new SessionRepo.
func NewSessionRepo(client *DynamoClient) *SessionRepo {
	return &SessionRepo{client: client}
}

// CreateSession creates a new session.
// PK: USER#{userID}, SK: SESSION#{sessionID}
// GSI1PK: SESSION#{sessionID}, GSI1SK: META
func (r *SessionRepo) CreateSession(ctx context.Context, session *Session) error {
	now := time.Now().UTC().Format(time.RFC3339)
	session.CreatedAt = now
	session.ModifiedAt = now
	session.EntityType = "SESSION"

	if err := r.client.PutItem(ctx, session); err != nil {
		return fmt.Errorf("creating session: %w", err)
	}

	return nil
}

// GetSessionByID retrieves a session by session ID using GSI1.
// GSI1PK: SESSION#{sessionID}, GSI1SK: META
func (r *SessionRepo) GetSessionByID(ctx context.Context, sessionID string) (*Session, error) {
	result, err := r.client.QueryGSI(ctx, "GSI1", &dynamodb.QueryInput{
		KeyConditionExpression: aws.String("GSI1PK = :sessionPK"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":sessionPK": &types.AttributeValueMemberS{Value: fmt.Sprintf("SESSION#%s", sessionID)},
		},
		Limit: aws.Int32(1),
	})
	if err != nil {
		return nil, fmt.Errorf("querying session by ID %s: %w", sessionID, err)
	}

	if len(result.Items) == 0 {
		return nil, fmt.Errorf("session not found: %s", sessionID)
	}

	var session Session
	if err := attributevalue.UnmarshalMap(result.Items[0], &session); err != nil {
		return nil, fmt.Errorf("unmarshaling session: %w", err)
	}

	return &session, nil
}

// ListUserSessions lists all active sessions for a user.
// PK: USER#{userID}, SK begins_with SESSION#
func (r *SessionRepo) ListUserSessions(ctx context.Context, userID string) ([]Session, error) {
	result, err := r.client.Query(ctx, &dynamodb.QueryInput{
		KeyConditionExpression: aws.String("PK = :pk AND begins_with(SK, :sk)"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":pk": &types.AttributeValueMemberS{Value: fmt.Sprintf("USER#%s", userID)},
			":sk": &types.AttributeValueMemberS{Value: "SESSION#"},
		},
	})
	if err != nil {
		return nil, fmt.Errorf("listing sessions for user %s: %w", userID, err)
	}

	var sessions []Session
	if err := attributevalue.UnmarshalListOfMaps(result.Items, &sessions); err != nil {
		return nil, fmt.Errorf("unmarshaling sessions: %w", err)
	}

	return sessions, nil
}

// DeleteSession deletes a session.
// PK: USER#{userID}, SK: SESSION#{sessionID}
func (r *SessionRepo) DeleteSession(ctx context.Context, userID, sessionID string) error {
	if err := r.client.DeleteItem(ctx, fmt.Sprintf("USER#%s", userID), fmt.Sprintf("SESSION#%s", sessionID)); err != nil {
		return fmt.Errorf("deleting session %s for user %s: %w", sessionID, userID, err)
	}

	return nil
}
