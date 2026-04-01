// internal/domain/auth/repository.go
package auth

import "context"

// UserRepository defines the interface for user data persistence.
// Implementations are provided by the repository layer and should not be defined here.
type UserRepository interface {
	// CreateUser creates a new user in the data store.
	CreateUser(ctx context.Context, user *User, passwordHash string) error

	// GetUserByID retrieves a user by their ID.
	GetUserByID(ctx context.Context, userID string) (*User, error)

	// GetUserByEmail retrieves a user by their email address.
	GetUserByEmail(ctx context.Context, email string) (*User, error)

	// EmailExists checks if an email is already registered.
	EmailExists(ctx context.Context, email string) (bool, error)

	// UpdateUser updates user information.
	UpdateUser(ctx context.Context, user *User) error
}

// SessionRepository defines the interface for session data persistence.
type SessionRepository interface {
	// CreateSession creates a new session.
	CreateSession(ctx context.Context, session *Session) error

	// GetSession retrieves a session by session ID.
	GetSession(ctx context.Context, sessionID string) (*Session, error)

	// GetUserSessions retrieves all active sessions for a user.
	GetUserSessions(ctx context.Context, userID string) ([]*Session, error)

	// UpdateSession updates session last activity.
	UpdateSession(ctx context.Context, session *Session) error

	// DeleteSession removes a session.
	DeleteSession(ctx context.Context, sessionID string) error

	// DeleteUserSessions removes all sessions for a user.
	DeleteUserSessions(ctx context.Context, userID string) error
}

// TokenService defines the interface for JWT token operations.
type TokenService interface {
	// GenerateAccessToken generates a new access token.
	GenerateAccessToken(ctx context.Context, userID string, email string) (string, int, error)

	// GenerateRefreshToken generates a new refresh token.
	GenerateRefreshToken(ctx context.Context, userID string) (string, error)

	// ValidateAccessToken validates and parses an access token.
	ValidateAccessToken(ctx context.Context, token string) (userID string, email string, err error)

	// ValidateRefreshToken validates and parses a refresh token.
	ValidateRefreshToken(ctx context.Context, token string) (userID string, err error)

	// RevokeRefreshToken invalidates a refresh token.
	RevokeRefreshToken(ctx context.Context, token string) error
}
